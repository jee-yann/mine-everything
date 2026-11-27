-- Studio RunScript: the crate and its odds, the guarantee, duplicates, cosmetics, boosts, luck,
-- purchases and saves. Nothing here talks to MarketplaceService: receipts go through Store.receipt with
-- a stand-in player and a stand-in save, so no Robux is ever involved.
local Shared = game.ReplicatedStorage.Shared
local Server = game.ServerScriptService.Server
local C, Geodes, S = require(Shared.Collectibles), require(Shared.Geodes), require(Shared.StoreConfig)
local B, Earnings = require(Shared.Bonuses), require(Shared.Earnings)
local Config = require(Shared.GameConfig)
local Col, Store = require(Server.Collection), require(Server.Store)
local Profile, Data = require(Server.Profile), require(Server.DataService)
local Mining = require(Server.MiningService)

local function near(a, b, tolerance)
	return math.abs(a - b) <= (tolerance or 1e-9)
end

-- One crate tier, plus the Welcome Crate. Every pool adds up to exactly 100% and names real rewards.
assert(#Geodes.list == 2 and Geodes.main == Geodes.byId.Starfall, "one crate to buy")
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
-- The mix by rarity is as advertised and adds up to 100.
local mix = {}
for _, row in Geodes.breakdown(Geodes.main) do mix[row[1]] = row[2] end
assert(near(mix.Common, 40) and near(mix.Uncommon, 28) and near(mix.Rare, 18) and near(mix.Epic, 9.5)
	and near(mix.Legendary, 4) and near(mix.Mythic, 0.5), "rarity mix")
assert(Geodes.percentText(22) == "22%" and Geodes.percentText(1.5) == "1.5%" and Geodes.percentText(0.5) == "0.5%")
assert(Geodes.percentText(12.5) == "12.5%" and Geodes.percentText(0.25) == "0.25%")
print("PASS crate odds add up to 100%, rarity mix 40/28/18/9.5/4/0.5")

-- The rolls follow the published odds.
do
	local rng, counts, n = Random.new(7), {}, 200000
	for _ = 1, n do
		local reward = Geodes.roll(Geodes.main, rng, 0)
		counts[reward.id] = (counts[reward.id] or 0) + 1
	end
	for _, row in Geodes.odds(Geodes.main, 0) do
		local seen = (counts[row.reward.id] or 0) / n * 100
		assert(math.abs(seen - row.percent) < 0.3, row.reward.id .. " rolled " .. seen .. "% for " .. row.percent .. "%")
	end
end
print("PASS 200,000 rolls match the published odds")

-- The guarantee: after 9 crates without a Legendary, the 10th is Legendary or better.
do
	local p = Profile.new()
	p.col.items.StarfallGeode = 400
	local streak = 0
	local rng = Random.new(3)
	for _ = 1, 400 do
		local reward = Col.open(p, "Starfall", rng)
		if Geodes.rank(reward) >= Geodes.main.pity.rank then
			assert(p.col.pity.Starfall == 0)
			streak = 0
		else
			streak += 1
			assert(p.col.pity.Starfall == streak and streak <= 9, "no guarantee after " .. streak)
		end
	end
	for _, row in Geodes.odds(Geodes.main, 9) do
		assert(Geodes.rank(row.reward) >= 5)
	end
	assert(not p.col.items.StarfallGeode and select(2, Col.open(p, "Starfall", rng)) == "You have no Starfall Crate")
end
print("PASS guarantee every 10th crate, counter resets on a Legendary")

-- The Welcome Crate: one Epic Comet Trail, for certain.
do
	local p = Profile.new()
	p.col.items.WelcomeGeode = 1
	local reward, result = Col.open(p, "Welcome", Random.new())
	assert(reward.kind == "trail" and reward.id == "Comet" and result.new and p.col.cos.Comet)
	assert(C.trailById.Comet.rarity == "Epic", "the starter trail is Epic")
	assert(Col.wear(p.col, "trail", "Comet") and p.col.trail == "Comet")
	-- Unowned effects can't be worn, unless every effect is open for playtesting.
	local testing = Config.AllFxForTesting
	Config.AllFxForTesting = false
	assert(not Col.wear(p.col, "trail", "Rift") and not Col.wear(p.col, "aura", "Comet"))
	Config.AllFxForTesting = true
	assert(Col.wear(p.col, "trail", "Rift") and p.col.trail == "Rift" and not p.col.cos.Rift, "playtesters can wear anything")
	assert(not Col.wear(p.col, "aura", "Comet"), "never something that doesn't exist")
	assert(B.decode(Col.encode(p.col, 0)).allFx and p.col.allFx == nil, "the client is told, the save isn't changed")
	Config.AllFxForTesting = testing
end
print("PASS Welcome Crate gives the Epic Comet Trail")

-- Duplicates pay gold (more for rarer ones); gold rewards pay minutes of earnings.
do
	local p = Profile.new()
	local perHour = Earnings.perHour(p)
	assert(Col.grant(p, { kind = "trail", id = "Ember" }).new)
	local result = Col.grant(p, { kind = "trail", id = "Ember" })
	assert(result.duplicate and result.gold == Earnings.minutes(p, C.rarities.Common.gold) and p.gold == result.gold)
	local before = p.gold
	local pouch = Col.grant(p, { kind = "item", id = "GoldPouch" })
	assert(pouch.gold == Earnings.tidy(perHour, 10) and p.gold == before + pouch.gold and not p.col.items.GoldPouch)
	assert(Col.grant(p, { kind = "item", id = "GoldTonic", count = 3 }).count == 3 and p.col.items.GoldTonic == 3)
	assert(C.rarities.Mythic.gold > C.rarities.Epic.gold and C.rarities.Epic.gold > C.rarities.Common.gold)
end
print("PASS duplicates and gold rewards pay earnings")

-- Cosmetics: Mining FX has its slot, and Player FX (a trail or an aura) is one slot; ids never collide.
do
	local col = Col.new()
	col.cos.Mint, col.cos.Sparks, col.cos.Ember = true, true, true
	assert(Col.wear(col, "ribbon", "Mint") and Col.wear(col, "trail", "Ember") and col.ribbon == "Mint")
	assert(Col.wear(col, "aura", "Sparks") and col.aura == "Sparks" and col.ribbon == nil, "an aura takes the trail off")
	assert(Col.wear(col, "ribbon", "Mint") and col.aura == nil and col.trail == "Ember", "and a trail the aura")
	-- Every effect speeds you up by rarity; the fastest worn counts.
	-- Player FX give movement speed; Mining FX give a smaller mining speed instead.
	assert(C.wornSpeed(col) == C.speed("ribbon", "Mint") and C.speed("aura", "Nebula") == 16 and C.speed("trail", "Ember") == 0)
	assert(C.mineSpeed("trail", "Ember") == 1 and C.mineSpeed("trail", "Galaxy") == 10 and C.mineSpeed("ribbon", "Mint") == 0)
	assert(C.speed("item", "GoldTonic") == 0 and C.mineSpeed("item", "GoldTonic") == 0)
	local plain = B.make({}, {}, 0, 0, 0)
	local galaxy = B.make({}, { trail = "Galaxy" }, 0, 0, 0)
	assert(B.speed(galaxy) == B.speed(plain) + 0.1 and B.cut(galaxy, 1.1) < B.cut(plain, 1.1), "Mining FX cut faster")
	local old = Col.new()
	old.cos.Mint, old.cos.Sparks, old.ribbon, old.aura = true, true, "Mint", "Sparks"
	Col.migrate(old)
	assert(old.ribbon == "Mint" and old.aura == nil, "an old save keeps one Player FX")
	assert(not Col.wear(col, "trail", "Mint") and not Col.wear(col, "style", "Sparks") and not Col.wear(col, "petAura", "Sparks"))
	local seen = {}
	for _, kind in C.cosmeticKinds do
		for _, entry in C.lists[kind] do
			assert(not seen[entry.id], entry.id .. " is used twice")
			seen[entry.id] = true
		end
	end
	assert(#C.pets == 0 and not C.find("pet", "Rock"), "pets are gone")
end
print("PASS cosmetic slots, no pets")

-- Older saves: pets, pet styles, pet food, other crates and retired boosts are cleaned up.
do
	local old = Profile.new()
	old.col.pets.Rock, old.col.pets.Drake = { l = 3, x = 1, s = 0 }, { l = 1, x = 0, s = 1 }
	old.col.eq = { "Drake" }
	old.col.items.Snack, old.col.items.PebbleGeode, old.col.items.CrystalGeode = 4, 2, 1
	old.col.boosts.luck3, old.col.boosts.compass = 99999999999, 99999999999
	old.col.petAura, old.col.style = "Sparks", "Wings"
	local loaded = assert(Data.claim({ profile = old }, "old-collection", 5)).profile
	assert(not next(loaded.col.pets) and #loaded.col.eq == 0 and loaded.col.petAura == nil and loaded.col.style == nil)
	assert(not loaded.col.items.Snack and not loaded.col.items.PebbleGeode and loaded.col.items.StarfallGeode == 3, "old crates become Starfall Crates")
	assert(not loaded.col.boosts.luck3 and not loaded.col.boosts.compass)
	local legacy = Profile.new()
	legacy.col, legacy.store = nil, nil
	legacy.levels.Speed = 2
	local upgraded = assert(Data.claim({ profile = legacy }, "legacy", 5)).profile
	assert(upgraded.col.cos.Comet and upgraded.col.trail == "Comet" and upgraded.col.intro, "First Light became the Comet Trail")
	local petSave = Profile.new()
	petSave.earned.PetName = true
	assert(Data.claim({ profile = petSave }, "pet-name", 5), "the retired pet achievement still loads")
end
print("PASS older collections migrate")

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
	for _, luck in { 1, 2, 4, 12 } do
		local shown, sum = B.lucky(chances, luck), 0
		for _, percent in shown do sum += percent end
		assert(near(sum, 100, 1e-6))
		local rare, common = {}, 0
		for name, percent in chances do
			if percent < B.rareBelow then rare[name] = percent else common += percent end
		end
		for _, entry in B.upgrades(chances, luck) do
			local name, upgrade = entry[1], entry[2]
			assert(near(rare[name] + common * upgrade, rare[name] * luck, 1e-9), name .. " at luck " .. luck)
			assert(near(shown[name], rare[name] * luck, 1e-9))
		end
	end
	assert(B.luck(B.make({}, {}, 0, 0, 100)) == 1)
	assert(B.luck(B.make({ Lucky = true }, {}, 0, 0, 100)) == 2)
	assert(B.luck(B.make({ Lucky = true }, { boosts = { luck2 = 200 } }, 0, 500, 100)) == 4, "timed luck doesn't stack")
	assert(B.luck(B.make({}, { boosts = {} }, 0, 500, 100)) == 2, "server luck")
	assert(B.luck(B.make({}, { boosts = { luck2 = 50 } }, 0, 0, 100)) == 1, "expired")
end
print("PASS luck math and stacking rules")

-- Gold: Double Gold, rebirths, VIP/tonic and 2× Gold multiply as documented, and sales are whole gold.
do
	local rebirth = require(Shared.Rebirth).goldMultiplier(2)
	local state = B.make({ DoubleGold = true, VIP = true }, { boosts = { goldTonic = 200, gold2 = 200 } }, 2, 0, 100)
	assert(near(B.gold(state), 2 * rebirth * 1.7 * 2))
	assert(near(B.speed(B.make({ FastPick = true }, { boosts = { speedTonic = 200 } }, 0, 0, 100)), 0.5))
	assert(B.xp(B.make({ VIP = true }, {}, 0, 0, 100)) == 1.2 and B.xp(B.make({}, {}, 0, 0, 100)) == 1, "VIP XP")
	local miner = Profile.new()
	miner.bag.Coal = 3
	local sold = Profile.sell(miner, 1.1)
	assert(sold % 1 == 0 and miner.gold % 1 == 0, "no fractions of gold: " .. sold)
end
print("PASS gold and speed stacking")

-- Store configuration: everything costs Robux, prices are as set, struck-through prices are real,
-- and no purchase ID is set until it is configured on the Creator Dashboard.
do
	assert(not S.passByKey.AutoSell, "Auto-Sell is no longer sold")
	local prices = { BiggerPack = 79, DoubleGold = 249, FastPick = 229, VIP = 449, Lucky = 349, StarfallCompass = 449, Everything = 1199 }
	assert(S.compassRadius == 3 and S.compassEvery == 120 and table.find(S.passByKey.Everything.grants, "StarfallCompass"), "the compass and the bundle")
	assert(S.passByKey.Everything.name == "All Passes Bundle")
	for key, price in prices do assert(S.passByKey[key].price == price, key) end
	assert(not S.passByKey.StarfallDrake and not S.passByKey.CelestialMiner)
	-- Prism Trail is retired: owners keep it and the Everything Pass includes it, but it isn't sold.
	assert(S.passByKey.PrismTrail.retired and table.find(S.passByKey.Everything.grants, "PrismTrail"))
	local everything = S.passByKey.Everything
	local sum = 0
	for _, pass in S.passes do
		if not pass.bundle then
			if not pass.retired then sum += pass.price end
			for _, benefit in pass.grants do assert(table.find(everything.grants, benefit), benefit) end
		end
	end
	assert(everything.was == sum and S.off(everything) > 0)
	local products = { StarterPack = 49, FounderHalo = 249, Crate1 = 25, Crate3 = 65, Crate10 = 199, Gold2x15 = 39, Gold2x60 = 99,
		ServerLuck = 79, Instamine10 = 99, AutoSell30 = 59, ResetSkills = 15, GoldPouch = 15, GoldBag = 35, GoldChest = 99, GoldVault = 349 }
	for key, price in products do assert(S.productByKey[key].price == price, key) end
	for _, gone in { "GemPouch", "GemBag", "GemChest", "GemVault", "GemHoard", "GemMountain", "Luck3x30", "StarCompass", "GoldCrate", "Luck2x15", "Luck2x60", "SellAnywhere" } do
		assert(not S.productByKey[gone], gone .. " should be gone")
	end
	-- Bundles are cheaper than their parts bought the expensive way.
	assert(S.productByKey.Crate3.was == 3 * S.productByKey.Crate1.price and S.productByKey.Crate10.was == 10 * S.productByKey.Crate1.price)
	local pouch = S.productByKey.GoldPouch
	for _, key in { "GoldBag", "GoldChest", "GoldVault" } do
		local pack = S.productByKey[key]
		assert(pack.was == pack.minutes * pouch.price / pouch.minutes, key .. " was")
		assert(pack.price / pack.minutes < pouch.price / pouch.minutes, key .. " is better value than the pouch")
	end
	for _, item in S.products do
		if item.was then assert(item.was > item.price and S.off(item) > 0, item.key) end
		if item.crates then assert(item.random, item.key .. " is a paid random item") end
	end
	local unset = {}
	for _, item in S.passes do if item.id == 0 then table.insert(unset, item.key) end end
	for _, item in S.products do if item.id == 0 then table.insert(unset, item.key) end end
	print("IDs still to configure: " .. table.concat(unset, ", "))
end
print("PASS store prices and struck-through prices")

-- Receipts: a PurchaseId is granted once, only after the save succeeds, and retried safely.
do
	local fake = { DisplayName = "Tester", UserId = 77 }
	local session = { profile = Profile.new() }
	local sessions = { [fake] = session }
	local saveWorks, opened, reset = false, 0, 0
	local said
	local context = {
		sessions = sessions,
		sync = function() end,
		feedback = function(_, _, text) said = text end,
		sellAll = function() end,
		announce = function() end,
		openCrate = function() opened += 1 end,
		resetSkills = function() reset += 1 end,
	}
	local function save() return saveWorks end
	local oldFind = Store.playerFor
	Store.playerFor = function(id) return if id == 77 then fake else nil end
	local ids = {}
	for i, item in S.products do
		ids[item.key] = item.id
		item.id = 990000 + i
	end
	local p = session.profile
	local function buy(key, purchase)
		return Store.receipt({ PlayerId = 77, ProductId = S.productByKey[key].id, PurchaseId = purchase }, sessions, context, save)
	end
	-- Crates: the crates arrive in the inventory, unopened.
	assert(buy("Crate3", "c1") == Enum.ProductPurchaseDecision.NotProcessedYet, "the save failed")
	assert(p.col.items.StarfallGeode == 3 and opened == 0)
	saveWorks = true
	assert(buy("Crate3", "c1") == Enum.ProductPurchaseDecision.PurchaseGranted)
	assert(buy("Crate3", "c1") == Enum.ProductPurchaseDecision.PurchaseGranted)
	assert(p.col.items.StarfallGeode == 3 and opened == 0, "a retried receipt never pays twice")
	-- Instamine and Auto Sell are timed boosts.
	assert(buy("Instamine10", "i1") == Enum.ProductPurchaseDecision.PurchaseGranted and p.col.boosts.instamine)
	assert(buy("AutoSell30", "a1") == Enum.ProductPurchaseDecision.PurchaseGranted and p.col.boosts.autosell)
	local now = os.time()
	local state = B.make({}, p.col, 0, 0, now)
	assert(B.instant(state) and B.autoSell(state) and B.cut(state, 5) == B.instantSeconds and B.cut(state, math.huge) == math.huge)
	-- Gold packs pay the buyer's own earnings.
	local before = p.gold
	assert(buy("GoldChest", "g1") == Enum.ProductPurchaseDecision.PurchaseGranted)
	assert(p.gold == before + Earnings.minutes(p, 240))
	-- Skill reset.
	p.skills.Reach = true
	assert(buy("ResetSkills", "r1") == Enum.ProductPurchaseDecision.PurchaseGranted and not next(p.skills) and reset == 1)
	-- Starter Pack: two crates, 2× gold and a Haste Tonic, once.
	assert(buy("StarterPack", "s1") == Enum.ProductPurchaseDecision.PurchaseGranted)
	assert(p.store.starter and p.col.items.StarfallGeode == 5 and p.col.boosts.gold2 and p.col.items.HasteTonic == 1)
	-- The limited aura: given once, counted toward the 100, worn, and refused once sold out.
	assert(S.productByKey.FounderHalo.limited == 100)
	p.col.cos.Mint, p.col.ribbon = true, "Mint"
	local limited = S.productByKey.FounderHalo
	local left = Store.left(limited)
	assert(buy("FounderHalo", "l1") == Enum.ProductPurchaseDecision.PurchaseGranted)
	assert(p.col.cos.FounderHalo and p.col.aura == "FounderHalo" and p.col.ribbon == nil and p.store.limited.FounderHalo)
	assert(Store.left(limited) == left - 1 and game.ReplicatedStorage:GetAttribute("LimitedFounderHalo") == left - 1)
	Store.prompt(fake, session, "product", "FounderHalo", context)
	assert(said == "You already have the Founder's Halo")
	Store.sold.FounderHalo, p.store.limited = limited.limited, nil
	Store.prompt(fake, session, "product", "FounderHalo", context)
	assert(said == "Founder's Halo has sold out")
	Store.sold.FounderHalo = nil
	-- Unknown players and products wait.
	assert(Store.receipt({ PlayerId = 78, ProductId = limited.id, PurchaseId = "x" }, sessions, context, save) == Enum.ProductPurchaseDecision.NotProcessedYet)
	assert(Store.receipt({ PlayerId = 77, ProductId = 5, PurchaseId = "y" }, sessions, context, save) == Enum.ProductPurchaseDecision.NotProcessedYet)
	-- The receipt record survives a save round trip.
	local loaded = Data.claim({ profile = Data.snapshot(p) }, "receipts", 10).profile
	assert(loaded.store.receipts.c1 and loaded.col.cos.FounderHalo)
	for _, item in S.products do item.id = ids[item.key] end
	Store.playerFor = oldFind
end
print("PASS receipts: crates, gold, reset, starter, limited, granted once after a good save")

-- Gold scales with progress.
do
	local p = Profile.new()
	local fresh = Earnings.perHour(p)
	p.levels.Speed, p.levels.Power, p.bestDepth = 6, 6, 200 * 5
	local veteran = Earnings.perHour(p)
	assert(fresh >= Earnings.minimum and veteran > fresh, fresh .. " " .. veteran)
	print(string.format("Gold per hour: new miner %d, veteran %d", fresh, veteran))
	-- Gold gifts and packs are valued at what the pick can mine, not the deepest spot ever stood on:
	-- a Power 1 miner who dropped down someone else's shaft (or just reborn) earns like a new miner.
	local rider = Profile.new()
	rider.bestDepth = 600 * 5
	assert(Earnings.perHour(rider) == fresh, "a deep visit alone pays nothing extra: " .. Earnings.perHour(rider))
	assert(Earnings.reach(1) == 26 and Earnings.reach(5) == 184 and Earnings.reach(14) == math.huge)
	-- A strong pick that has not been deep yet is still valued where it has been.
	local strong = Profile.new()
	strong.levels.Power = 9
	assert(Earnings.perHour(strong) < veteran)
end
print("PASS earnings scale with progress")

-- Free crates for progress.
do
	local col = Col.new()
	assert(#Mining.progressGeodes(col, 1, 4, "Coal") == 0)
	local given = Mining.progressGeodes(col, 4, 26, "Starfall")
	assert(#given == 7 and col.items.StarfallGeode == 7, "levels 5-20 give one each, 25 gives two, and a Starfall gives one")
end
print("PASS free crates for levels and Starfall finds")

-- Restricted regions: crates and luck are refused until Roblox says they're allowed.
do
	local function fake(restricted)
		return { GetAttribute = function(_, key) if key == "PaidRandomRestricted" then return restricted end return nil end }
	end
	local crate, luck, gold = S.productByKey.Crate1, S.productByKey.ServerLuck, S.productByKey.GoldBag
	assert(not Store.allowed(fake(true), crate) and not Store.allowed(fake(nil), crate), "restricted or unknown")
	assert(not Store.allowed(fake(true), luck) and not Store.allowed(fake(true), S.productByKey.StarterPack))
	assert(Store.allowed(fake(false), crate) and Store.allowed(fake(true), gold) and Store.allowed(fake(true), S.passByKey.DoubleGold))
end
print("PASS restricted regions can't buy crates or luck; other items stay available")

print("SHOP_TESTS_PASSED")
