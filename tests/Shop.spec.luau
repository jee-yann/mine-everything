-- Studio RunScript: geodes, odds, guarantees, duplicates, crafting, pets, boosts, luck, purchases.
-- Nothing here talks to MarketplaceService: receipts go through Store.receipt with a stand-in player
-- and a stand-in save, so no Robux is ever involved.
local Shared = game.ReplicatedStorage.Shared
local Server = game.ServerScriptService.Server
local C, Geodes, Recipes = require(Shared.Collectibles), require(Shared.Geodes), require(Shared.Recipes)
local S, B = require(Shared.StoreConfig), require(Shared.Bonuses)
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Col, Store = require(Server.Collection), require(Server.Store)
local Profile, Data = require(Server.Profile), require(Server.DataService)
local Mining = require(Server.MiningService)

local function near(a, b, tolerance)
	return math.abs(a - b) <= (tolerance or 1e-9)
end

-- Every pool's odds add up to exactly 100%, with and without the Starfall guarantee, and every entry
-- is a real catalogue item.
for _, geode in Geodes.list do
	local weight = 0
	for _, reward in geode.pool do
		assert(Geodes.entry(reward), geode.id .. " has an unknown reward " .. reward.id)
		assert(reward.weight > 0 and reward.weight % 1 == 0)
		weight += reward.weight
	end
	assert(weight == 10000, geode.id .. " weights must add up to 100.00%: " .. weight)
	for _, pity in { 0, 9 } do
		local sum = 0
		for _, row in Geodes.odds(geode, pity) do sum += row.percent end
		assert(near(sum, 100, 1e-6), geode.id .. " odds add to " .. sum)
	end
end
assert(Geodes.percentText(22) == "22%" and Geodes.percentText(1.5) == "1.5%" and Geodes.percentText(0.5) == "0.5%")
assert(Geodes.percentText(12.5) == "12.5%" and Geodes.percentText(0.25) == "0.25%")
print("PASS geode odds add up to 100% and name real rewards")

-- The rolls follow the published odds.
do
	local rng, counts, n = Random.new(7), {}, 200000
	local geode = Geodes.byId.Pebble
	for _ = 1, n do
		local reward = Geodes.roll(geode, rng, 0)
		counts[reward.id] = (counts[reward.id] or 0) + 1
	end
	for _, row in Geodes.odds(geode, 0) do
		local seen = (counts[row.reward.id] or 0) / n * 100
		assert(math.abs(seen - row.percent) < 0.35, row.reward.id .. " rolled " .. seen .. "% for " .. row.percent .. "%")
	end
end
print("PASS 200,000 Pebble rolls match the published odds")

-- The Starfall guarantee: after 9 geodes without a Legendary, the 10th is Legendary or better.
do
	local p = Profile.new()
	p.gems = 1e6
	local streak = 0
	local rng = Random.new(3)
	for _ = 1, 400 do
		local reward = Col.open(p, "Starfall", true, rng)
		local rank = Geodes.rank(reward)
		if rank >= Geodes.byId.Starfall.pity.rank then
			assert(p.col.pity.Starfall == 0)
			streak = 0
		else
			streak += 1
			assert(p.col.pity.Starfall == streak and streak <= 9, "no guarantee after " .. streak)
		end
	end
	for _, row in Geodes.odds(Geodes.byId.Starfall, 9) do
		assert(Geodes.rank(row.reward) >= 5)
	end
	assert(p.gems == 1e6 - 400 * Geodes.byId.Starfall.price)
end
print("PASS Starfall guarantee every 10th geode, counter resets on a Legendary")

-- The Welcome Geode: given once, holds the Comet Trail for certain, and can't be bought.
do
	local p = Profile.new()
	assert(Col.welcome(p.col) and not Col.welcome(p.col) and p.col.items.WelcomeGeode == 1)
	assert(select(2, Col.open(p, "Welcome", true, Random.new())) == "Welcome Geode can't be bought")
	local reward, result = Col.open(p, "Welcome", false, Random.new())
	assert(reward.kind == "trail" and reward.id == "Comet" and result.new and p.col.cos.Comet)
	assert(not p.col.items.WelcomeGeode and not Col.open(p, "Welcome", false, Random.new()))
	assert(#Geodes.odds(Geodes.byId.Welcome) == 1 and Geodes.odds(Geodes.byId.Welcome)[1].percent == 100)
	assert(Col.wear(p.col, "trail", "Comet") and p.col.trail == "Comet")
	assert(not Col.wear(p.col, "trail", "Rift") and not Col.wear(p.col, "aura", "Comet"))
	-- After that, a Pebble rolls normally (no Comet in its pool).
	p.gems = 25
	local next = Col.open(p, "Pebble", true, Random.new(1))
	assert(next.id ~= "Comet" and p.gems == 0)
	assert(select(2, Col.open(p, "Pebble", true, Random.new(1))) == "Not enough gems")
end
print("PASS Welcome Geode once, guaranteed Comet Trail, normal odds after")

-- Duplicates: pets gain stars up to three, then turn to Geode Dust; cosmetics turn to dust at once.
do
	local col = Col.new()
	assert(Col.grant(col, { kind = "pet", id = "Bat" }).new and col.pets.Bat.s == 0)
	for star = 1, 3 do
		assert(Col.grant(col, { kind = "pet", id = "Bat" }).star == star)
	end
	assert(Col.grant(col, { kind = "pet", id = "Bat" }).dust == C.rarities.Common.dust and col.dust == 3)
	assert(Col.grant(col, { kind = "trail", id = "Ember" }).new)
	assert(Col.grant(col, { kind = "trail", id = "Ember" }).dust == 3 and col.dust == 6)
	assert(Col.grant(col, { kind = "item", id = "Snack", count = 3 }).count == 3 and col.items.Snack == 3)
end
print("PASS duplicates become stars, then Geode Dust")

-- Pets: three slots, levels from food, bonuses capped.
do
	local col = Col.new()
	for _, id in { "Bat", "Crab", "Owl", "Wisp" } do Col.grant(col, { kind = "pet", id = id }) end
	assert(#col.eq == 3 and col.eq[1] == "Bat" and col.eq[3] == "Owl", "new pets fill free slots")
	assert(not Col.equipPet(col, "Wisp", true) and Col.equipPet(col, "Bat", false) and Col.equipPet(col, "Wisp", true))
	assert(not Col.equipPet(col, "Fox", true), "only owned pets")
	col.items.Feast = 1
	assert(Col.use(col, "Feast", 0) and not col.items.Feast)
	assert(col.pets.Wisp.l > 1, "a feast levels a new pet")
	assert(select(2, Col.use(col, "Feast", 0)) == "You have none")
	local state = B.make({}, { pets = { Wisp = { l = 30, s = 3 }, Owl = { l = 30, s = 3 }, Drake = { l = 30, s = 3 } }, eq = { "Wisp", "Owl", "Drake" } }, 0, 0, 0)
	assert(B.pets(state).luck == C.bonusCaps.luck, "pet luck is capped")
	for _ = 1, 100 do Col.petXp(col, 1e6) end
	for _, id in col.eq do assert(col.pets[id].l == C.maxPetLevel and col.pets[id].x == 0) end
end
print("PASS pet slots, feeding, levels and bonus caps")

-- Crafting checks every cost and never grants a cosmetic twice.
do
	local p = Profile.new()
	assert(select(2, Col.craft(p, "Crab")):find("Copper"))
	p.bag.Copper = 20
	assert(select(2, Col.craft(p, "Crab")):find("Geode Dust"))
	p.col.dust = 40
	local recipe = assert(Col.craft(p, "Crab"))
	Profile.consume(p, Col.recipeOres(recipe))
	p.col.dust -= recipe.dust
	Col.grant(p.col, recipe.give)
	assert(p.col.pets.Crab and not p.bag.Copper and p.col.dust == 0)
	p.col.cos.Frost = true
	p.bag.Quartz, p.col.dust = 4, 30
	assert(select(2, Col.craft(p, "Frost")) == "You already own this")
	for _, r in Recipes.list do
		assert(C.find(r.give.kind, r.give.id), r.id)
		for name in r.ores or {} do assert(Ores.byName[name], r.id .. " uses " .. name) end
	end
end
print("PASS crafting costs and ownership checks")

-- Boosts: stack by adding time, capped at four hours, and drop out once expired.
do
	local col = Col.new()
	Col.boost(col, "luck2", 15, 1000)
	Col.boost(col, "luck2", 15, 1000)
	assert(col.boosts.luck2 == 1000 + 30 * 60)
	for _ = 1, 30 do Col.boost(col, "gold2", 15, 1000) end
	assert(col.boosts.gold2 == 1000 + C.maxBoostMinutes * 60)
	Col.encode(col, 1000 + 31 * 60)
	assert(not col.boosts.luck2 and col.boosts.gold2)
end
print("PASS boosts add up, cap at four hours and expire")

-- Luck: each ore under 1% turns up exactly `luck` times as often; the odds list still adds to 100.
do
	local crater = Config.Layers[#Config.Layers]
	local chances = Mining.regionChances(crater)
	for _, luck in { 1, 2, 3, 6, 12 } do
		local shown, sum = B.lucky(chances, luck), 0
		for _, percent in shown do sum += percent end
		assert(near(sum, 100, 1e-6))
		local rare, common = {}, 0
		for name, percent in chances do
			if percent < B.rareBelow then rare[name] = percent else common += percent end
		end
		for _, entry in B.upgrades(chances, luck) do
			local name, upgrade = entry[1], entry[2]
			local overall = rare[name] + common * upgrade
			assert(near(overall, rare[name] * luck, 1e-9), name .. " at luck " .. luck)
			assert(near(shown[name], rare[name] * luck, 1e-9))
		end
	end
	assert(chances.Starfall == 0.0025 and Mining.luckyFind(crater, "Voidshard", 2, Random.new()) == nil, "rare cuts are never upgraded")
	-- Stacking: pets add, 2× Lucky doubles, timed luck takes the strongest, all capped at 12×.
	local base = B.make({}, {}, 0, 0, 100)
	assert(B.luck(base) == 1)
	assert(B.luck(B.make({ Lucky = true }, {}, 0, 0, 100)) == 2)
	assert(B.luck(B.make({ Lucky = true }, { boosts = { luck3 = 200, luck2 = 200 } }, 0, 500, 100)) == 6)
	assert(B.luck(B.make({}, { boosts = {} }, 0, 500, 100)) == 2, "server luck")
	assert(B.luck(B.make({}, { boosts = { luck3 = 50 } }, 0, 0, 100)) == 1, "expired")
	local stacked = B.make({ Lucky = true }, { pets = { Wisp = { l = 30, s = 3 }, Owl = { l = 30, s = 3 } }, eq = { "Wisp", "Owl" }, boosts = { luck3 = 200 } }, 0, 0, 100)
	assert(B.luck(stacked) == math.min(12, 1.6 * 2 * 3))
end
print("PASS luck math, odds display and stacking rules")

-- Gold: Double Gold, rebirths, pets/VIP/tonic and 2× Gold multiply as documented.
do
	local rebirth = require(Shared.Rebirth).goldMultiplier(2)
	local state = B.make({ DoubleGold = true, VIP = true }, { boosts = { goldTonic = 200, gold2 = 200 } }, 2, 0, 100)
	assert(near(B.gold(state), 2 * rebirth * 1.6 * 2))
	assert(B.gold(B.make({}, {}, 0, 0, 100)) == 1)
	assert(near(B.speed(B.make({ FastPick = true }, { boosts = { speedTonic = 200 } }, 0, 0, 100)), 0.35))
end
print("PASS gold and speed stacking")

-- Store configuration: every price matches the brief, gem pack bonuses are what the labels say, and no
-- purchase ID is set until it is configured on the Creator Dashboard.
do
	local prices = { BiggerPack = 49, PrismTrail = 99, AutoSell = 149, DoubleGold = 199, FastPick = 199, VIP = 249, Lucky = 299, StarfallDrake = 799, CelestialMiner = 999 }
	for key, price in prices do assert(S.passByKey[key].price == price, key) end
	local products = { SellAnywhere = 15, GemPouch = 25, StarterPack = 49, Gold2x15 = 39, Luck2x15 = 59, GemBag = 99, StarCompass = 99, GoldCrate = 149, GemChest = 199, Luck3x30 = 199, ServerLuck = 349, GemVault = 499, GemHoard = 999, GemMountain = 1999 }
	for key, price in products do assert(S.productByKey[key].price == price, key) end
	local bonus = { GemBag = 21, GemChest = 51, GemVault = 80, GemHoard = 100, GemMountain = 125 }
	for key, percent in bonus do assert(S.gemBonus(S.productByKey[key]) == percent, key .. " " .. S.gemBonus(S.productByKey[key])) end
	local unset = {}
	for _, item in S.passes do if item.id == 0 then table.insert(unset, item.key) end end
	for _, item in S.products do if item.id == 0 then table.insert(unset, item.key) end end
	print("IDs still to configure: " .. table.concat(unset, ", "))
end
print("PASS store prices and gem pack bonus labels")

-- Receipts: a PurchaseId is granted once, only after the save succeeds, and retried safely.
do
	local product = S.productByKey.GemBag
	local oldId = product.id
	product.id = 990001
	local fake = { DisplayName = "Tester", UserId = 77 }
	local session = { profile = Profile.new() }
	local sessions = { [fake] = session }
	local saves, saveWorks = 0, false
	local context = {
		sessions = sessions,
		sync = function() end,
		feedback = function() end,
		sellAll = function() end,
		announce = function() end,
	}
	local function save()
		saves += 1
		return saveWorks
	end
	local oldFind = Store.playerFor
	Store.playerFor = function(id) return if id == 77 then fake else nil end
	local info = { PlayerId = 77, ProductId = 990001, PurchaseId = "receipt-1" }
	assert(Store.receipt(info, sessions, context, save) == Enum.ProductPurchaseDecision.NotProcessedYet)
	assert(session.profile.gems == 120, "granted once in the session")
	saveWorks = true
	assert(Store.receipt(info, sessions, context, save) == Enum.ProductPurchaseDecision.PurchaseGranted)
	assert(Store.receipt(info, sessions, context, save) == Enum.ProductPurchaseDecision.PurchaseGranted)
	assert(session.profile.gems == 120, "a retried receipt never pays twice")
	assert(Store.receipt({ PlayerId = 77, ProductId = 990001, PurchaseId = "receipt-2" }, sessions, context, save) == Enum.ProductPurchaseDecision.PurchaseGranted)
	assert(session.profile.gems == 240)
	assert(Store.receipt({ PlayerId = 78, ProductId = 990001, PurchaseId = "x" }, sessions, context, save) == Enum.ProductPurchaseDecision.NotProcessedYet, "player gone")
	assert(Store.receipt({ PlayerId = 77, ProductId = 5, PurchaseId = "y" }, sessions, context, save) == Enum.ProductPurchaseDecision.NotProcessedYet, "unknown product")
	-- The receipt record survives a save round trip and a reset.
	local loaded = Data.claim({ profile = Data.snapshot(session.profile) }, "receipts", 10).profile
	assert(loaded.store.receipts["receipt-1"] and #loaded.store.order == 2)
	-- Starter Pack: once only.
	local starter = S.productByKey.StarterPack
	starter.id = 990002
	assert(Store.receipt({ PlayerId = 77, ProductId = 990002, PurchaseId = "s1" }, sessions, context, save) == Enum.ProductPurchaseDecision.PurchaseGranted)
	assert(session.profile.store.starter and session.profile.flares == 3 and session.profile.col.boosts.gold2)
	starter.id, product.id = 0, oldId
	Store.playerFor = oldFind
end
print("PASS receipts granted once, after a successful save")

-- Gold Crate pays about an hour of the miner's own earnings, without boosts.
do
	local p = Profile.new()
	local fresh = Store.goldCrate(p)
	p.levels.Speed, p.levels.Power, p.bestDepth = 6, 6, 200 * 5
	local veteran = Store.goldCrate(p)
	assert(fresh >= 250 and veteran > fresh, fresh .. " " .. veteran)
	print("Gold Crate: new miner " .. fresh .. ", veteran " .. veteran)
end
print("PASS Gold Crate scales with progress")

-- Saves: a new profile, a legacy one and the collection all round trip.
do
	local legacy = Profile.new()
	legacy.col, legacy.store = nil, nil
	legacy.drake, legacy.pet = true, "Drake"
	legacy.levels.Speed = 2
	local loaded = assert(Data.claim({ profile = legacy }, "legacy", 5)).profile
	assert(loaded.col.pets.Drake and loaded.col.eq[1] == "Drake" and loaded.col.cos.Comet and loaded.col.trail == "Comet")
	assert(loaded.col.intro, "players who had First Light don't get a second gift")
	local fresh = assert(Data.claim({ profile = Profile.new() }, "fresh", 5)).profile
	assert(fresh.col.pets.Rock and not fresh.col.intro and not fresh.col.trail)
	local bad = Profile.new()
	bad.col.pets.Unicorn = { l = 1, x = 0, s = 0 }
	assert(not Data.claim({ profile = bad }, "bad", 5))
	bad = Profile.new()
	bad.store.receipts.x = "yes"
	assert(not Data.claim({ profile = bad }, "bad", 5))
	bad = Profile.new()
	bad.col.eq = { "Rock", "Rock", "Rock", "Rock" }
	assert(not Data.claim({ profile = bad }, "bad", 5))
	assert(Col.passRewards(fresh.col, { StarfallDrake = true, PrismTrail = true }, true))
	assert(fresh.col.pets.StarDrake and fresh.col.cos.Prism and fresh.col.trail == "Prism")
	assert(not Col.passRewards(fresh.col, { StarfallDrake = true, PrismTrail = true }, true))
	local again = assert(Data.claim({ profile = Data.snapshot(fresh) }, "again", 6)).profile
	assert(again.col.pets.StarDrake and again.col.trail == "Prism")
end
print("PASS collection saves, legacy upgrade and validation")

-- Free geodes for progress.
do
	local col = Col.new()
	assert(#Mining.progressGeodes(col, 1, 4, "Coal") == 0)
	local given = Mining.progressGeodes(col, 4, 26, "Starfall")
	assert(#given == 6 and col.items.PebbleGeode == 4 and col.items.CrystalGeode == 1 and col.items.StarfallGeode == 1,
		"levels 5, 10, 15, 20 give Pebbles, 25 a Crystal, and a Starfall a Starfall Geode")
	local p = Profile.new()
	p.col = col
	local reward = Col.open(p, "Crystal", false, Random.new(4))
	assert(reward and not p.col.items.CrystalGeode and p.gems == 0, "a free geode opens without gems")
end
print("PASS free geodes for levels and Starfall finds")

-- Restricted regions: luck products and paid geodes are refused until Roblox says they're allowed.
do
	local function fake(restricted)
		return { GetAttribute = function(_, key) if key == "PaidRandomRestricted" then return restricted end return nil end }
	end
	local luck, gold = S.productByKey.Luck3x30, S.productByKey.Gold2x15
	assert(not Store.allowed(fake(true), luck) and not Store.allowed(fake(nil), luck), "restricted or unknown")
	assert(Store.allowed(fake(false), luck) and Store.allowed(fake(true), gold))
	assert(not Store.allowed(fake(true), S.passByKey.Lucky) and Store.allowed(fake(true), S.passByKey.DoubleGold))
end
print("PASS restricted regions can't buy luck; other items stay available")

print("SHOP_TESTS_PASSED")
