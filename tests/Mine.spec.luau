-- Studio CLI RunScript test. Run in the local build. All changes are in memory.
local Server = game:GetService("ServerScriptService").Server
local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Geology, World = require(Server.Geology), require(Server.MineWorld)
local Pattern = require(Shared.BlockPattern)
local Profile = require(Server.Profile)
assert(Profile.valid(Profile.new()))
local Data = require(Server.DataService)
do
	local Purity = require(Shared.OrePurity)
	local function sample(roll, extra)
		return { NextInteger = function(_, _, limit) return if limit == 10 then extra or 10 elseif limit == 100 then roll else 0 end }
	end
	-- The band comes from the 1-100 roll; the exact value inside it from a second roll.
	local function exact(band, step)
		return { NextInteger = function(_, _, limit) return if limit == 100 then band else step end }
	end
	for roll, percent in { [1] = 50, [30] = 50, [31] = 65, [63] = 80, [86] = 90, [96] = 98, [100] = 100 } do
		assert(Purity.roll(exact(roll, 0)) == percent)
	end
	assert(Purity.roll(exact(31, 5432)) == 70.432 and Purity.roll(exact(1, 14999)) == 64.999)
	assert(Purity.roll(exact(100, 999)) == 100 and Purity.valid(70.432) and not Purity.valid(70.4321))
	assert(Purity.bonus(50) == 0 and Purity.bonus(65) == 10 and Purity.bonus(98) == 50 and Purity.bonus(100) == 100)
	assert(math.abs(Purity.bonus(72.5) - 15) < 1e-9 and Purity.text(70.432) == "70.432%" and Purity.text(100) == "100%")
	assert(Purity.multiplierText(65) == "×1.10" and Purity.validGrade("65") and Purity.validGrade("70.432"))
	assert(not Purity.validGrade("70.4320") and not Purity.validGrade("49.999") and not Purity.validGrade("x"))
	local mixed = Purity.decode(Purity.encode({ ["70.432"] = 2, ["65"] = 1 }))
	assert(mixed["70.432"] == 2 and mixed["65"] == 1 and select(1, Purity.range(mixed)) == 65)

	local old = Profile.new()
	old.grades, old.bestPurity, old.bag = nil, nil, { Gold = 1 }
	local miner = Data.claim({profile = old}, "assay", 1000).profile
	local awards, grade, units, record = Profile.recordCut(miner, "Gold", 30, sample(99))
	assert(#awards == 0 and grade == 98 and units == 1 and record)
	awards, grade, units, record = Profile.recordCut(miner, "Gold", 30, sample(100))
	assert(#awards == 0 and record and miner.bestPurity.Gold == 100)
	local stock = Purity.decode(Purity.encode(miner.grades.Gold))
	local low, high = Purity.range(stock)
	assert(low == 98 and high == 100 and stock["98"] == 1 and stock["100"] == 1)
	local saved = Data.snapshot(miner)
	local gold = Ores.byName.Gold
	local quote = Purity.quote(gold, 3, stock, 2, false)
	assert(quote == 200 and Profile.value(miner.bag, miner.grades) == quote + 160)
	assert(Profile.sell(miner, 2, "Gold", 2) == quote * 2 and miner.bag.Gold == 1)
	assert(not miner.grades.Gold["98"] and saved.grades.Gold["98"] == 1)
	local restored = Data.claim({profile = saved}, "rejoin-assay", 1050).profile
	assert(Profile.used(restored) == 3 and restored.bestPurity.Gold == 100)
	local brokerQuote = Purity.quote(gold, 3, stock, 3, true)
	assert(brokerQuote == 396)
	restored.skills.Broker = true
	assert(Profile.sell(restored, 2) == 2 * brokerQuote and not next(restored.grades))
	Profile.consume(miner, { Gold = 1 })
	assert(not miner.grades.Gold and not miner.bag.Gold and miner.bestPurity.Gold == 100)
	assert(not Purity.encode(miner.grades.Gold))

	miner.skills.Fortune = true
	miner.bag.Dirt = 6
	local xp, cuts, count = miner.xp, miner.mined, miner.counts.Gold
	awards, grade, units, record = Profile.recordCut(miner, "Gold", 30, sample(35, 1))
	assert(grade == 65 and units == 2 and not record and miner.grades.Gold["65"] == 2)
	assert(Profile.used(miner) == 8 and miner.counts.Gold == count + 1 and miner.mined == cuts + 1)
	assert(miner.xp == xp + gold.xp)
	Profile.consume(miner, { Gold = 1 })
	awards, grade, units = Profile.recordCut(miner, "Gold", 30, sample(35, 1))
	assert(units == 1 and Profile.used(miner) == 8)
	Profile.consume(miner, { Dirt = 6 })
	local _, hostGrade, hostUnits = Profile.recordCut(miner, "Stone", 5, sample(100, 1))
	assert(not hostGrade and hostUnits == 1 and not miner.grades.Stone)
	assert(Purity.quote(Ores.byName.Stone, 1, nil, 1, true) == Ores.byName.Stone.value)
	local copper = Ores.byName.Copper
	for _, broker in {false, true} do
		local lowPrice, highPrice = Purity.priceRange(copper, broker)
		assert(lowPrice == Purity.quote(copper, 1, {["50"] = 1}, 1, broker))
		assert(highPrice == Purity.quote(copper, 1, {["100"] = 1}, 1, broker))
		assert(highPrice > lowPrice)
	end
	local rockLow, rockHigh = Purity.priceRange(Ores.byName.Stone, true)
	assert(rockLow == rockHigh and rockLow == Ores.byName.Stone.value)

	local spill = Profile.new()
	spill.levels.Capacity = 2
	for i = 1, 10 do Profile.recordCut(spill, "Gold", 10, sample(if i == 1 then 1 else 100)) end
	assert(Profile.spill(spill) == 1 and spill.bag.Gold == 9 and spill.grades.Gold["100"] == 9)
	assert(not spill.grades.Gold["50"] and Profile.valid(spill))
	for _, badGrades in { {Gold={["101"]=1}}, {Gold={["100"]=10}}, {Gold={["100"]=0.5}}, {Stone={["100"]=1}} } do
		local damaged = Data.snapshot(spill)
		damaged.grades = badGrades
		assert(not Data.claim({profile=damaged}, "bad-assay", 1080))
	end
	local damaged = Data.snapshot(spill)
	damaged.bestPurity.Gold = 65
	assert(not Profile.valid(damaged))
	print("PASS purity rolls, legacy prices, partial sale quotes, Fortune capacity, fees, spending and save roundtrip")
end
local stored = Data.claim(nil, "first", 1000)
assert(stored.profile.introSeen == false)
do
	local old=Profile.new()
	old.introSeen=nil
	assert(Data.claim({profile=old},"returning",1000).profile.introSeen)
	local seen=Profile.new()
	seen.introSeen=true
	local saved=Data.commit({owner="intro"},"intro",Data.snapshot(seen),1000,true)
	assert(Data.claim(saved,"rejoin",1001).profile.introSeen)
end
stored.profile.gold = 137
do
	local first = Profile.new()
	assert(Profile.expeditionStep(first) == "Dig")
	Profile.recordCut(first, "Dirt")
	assert(Profile.expeditionStep(first) == "Ore")
	Profile.recordCut(first, "Coal")
	assert(Profile.expeditionStep(first) == "Sell")
	assert(Profile.sell(first, 1, "Copper", "Stack") == 0 and Profile.expeditionStep(first) == "Sell")
	Profile.sell(first, 1, "Dirt", 1)
	local checkpoint = Data.snapshot(first)
	assert(Profile.expeditionStep(Data.claim({ profile = checkpoint }, "resume", 10).profile) == "Upgrade")
	first.gold = 30
	assert(Profile.buy(first, "Speed") and Profile.expeditionStep(first) == "Return")
	Profile.recordCut(first, "Stone")
	assert(Profile.expeditionStep(first) == "Done" and not checkpoint.firstTrip.tried)
	assert(Profile.expeditionStep(Data.claim({ profile = Data.snapshot(first) }, "later", 20).profile) == "Done")
	local free = Profile.new()
	free.gold = 30
	Profile.buy(free, "Speed")
	Profile.recordCut(free, "Dirt")
	Profile.sell(free)
	Profile.recordCut(free, "Coal")
	assert(Profile.expeditionStep(free) == "Done", "earlier actions count in any order")
	free.firstTrip = nil
	assert(Profile.expeditionStep(Data.claim({ profile = free }, "veteran", 30).profile) == "Skipped")
	assert(Profile.expeditionStep(Data.claim({ profile = Data.snapshot(free) }, "again", 31).profile) == "Skipped")
end
assert(not Data.claim(stored, "second", 1001))
assert(not Data.claim({ profile = { version = 99 } }, "second", 1001))
local transferred = Data.claim(stored, "second", stored.expires + 1)
assert(transferred.profile.gold == 137)
assert(not Data.commit(transferred, "first", Profile.new(), 2000, false))
local released = Data.commit(transferred, "second", transferred.profile, 2000, true)
assert(not released.owner and Data.claim(released, "third", 2001).profile.gold == 137)
print("PASS save ownership, expired lease, incompatible record, stale writer and release")
local p = Profile.new()
assert(not Profile.buy(p, "Radius"))
p.bag = { Stone = 4, Coal = 3, Copper = 1 }
assert(Profile.used(p) == 8 and Profile.sell(p) == 35 and Profile.used(p) == 0)
assert(Profile.buy(p, "Capacity") and p.gold == 27 and Profile.stat(p, "Capacity") == 16 and Profile.used(p) == 0)
local Upgrades = require(Shared.Upgrades)
do
	local starter = Profile.new()
	assert(Profile.stat(starter, "Capacity") == 8)
	for _ = 1, 7 do
		Profile.recordCut(starter, "Dirt")
		assert(Profile.expeditionStep(starter) == "Ore")
	end
	Profile.recordCut(starter, "Dirt")
	assert(Profile.expeditionStep(starter) == "Sell" and starter.xp == 0)
	assert(Profile.sell(starter) == 8 and Profile.expeditionStep(starter) == "Upgrade")
	assert(Upgrades.onboardingPick(starter.gold) == "Capacity" and Profile.buy(starter, "Capacity"))
	assert(starter.gold == 0 and Upgrades.price("Capacity", 2) == 36 and Profile.expeditionStep(starter) == "Return")
	Profile.recordCut(starter, "Dirt")
	assert(Profile.expeditionStep(starter) == "Done")

	local old = Profile.new()
	old.bag = { Dirt = 32, Coal = 4 }
	local saved = Data.claim({ profile = old }, "old-pack", 30).profile
	assert(Profile.used(saved) == 36 and Profile.stat(saved, "Capacity") == 8)
	assert(Profile.sell(saved, 1, "Coal", "Stack") == 20)
	local resumed = Data.claim({ profile = Data.snapshot(saved) }, "resume-pack", 31).profile
	assert(Profile.used(resumed) == 32 and Profile.sell(resumed) == 32 and resumed.gold == 52)
	old.bag.Dirt = 37
	assert(not Data.claim({ profile = old }, "oversize", 32))

	for level, oldBase in { 36, 80, 170, 360, 760, 1600, 3400, 7200 } do
		local veteran = Profile.new()
		veteran.levels.Capacity = level
		veteran.skills = { Pack = true, PackII = true, PackIII = true, DeepPockets = true }
		local skills = require(Shared.Skills)
		local oldSlots = skills.capacity(oldBase, veteran.skills)
		veteran.bag = { Dirt = oldSlots - 1, Coal = 1 }
		local loaded = Data.claim({ profile = veteran }, "veteran", 50).profile
		local newSlots = 8 + 6 * (level - 1) + 2 * (level - 1) ^ 2
		assert(Upgrades.items.Capacity.values[level] == newSlots)
		assert(Profile.stat(loaded, "Capacity") == skills.capacity(newSlots, veteran.skills))
		assert(Profile.sell(loaded, 1, "Coal", "Stack") == 5)
		local rejoined = Data.claim({ profile = Data.snapshot(loaded) }, "again", 51).profile
		assert(Profile.sell(rejoined) == oldSlots - 1 and Profile.used(rejoined) == 0)
		veteran.bag.Dirt = oldSlots + 1
		assert(not Data.claim({ profile = veteran }, "too-large", 52))
	end
end
for _, bag in { {}, { Dirt = 2, Stone = 3, Coal = 1, Copper = 2, Gold = 1 } } do
	local miner = Profile.new()
	miner.bag = table.clone(bag)
	local startingLoad = Profile.used(miner)
	local function checkBag()
		assert(Profile.used(miner) == startingLoad, "workshop changed the pack's load")
		for name, count in bag do
			assert(miner.bag[name] == count, "workshop changed a stack of " .. name)
		end
	end
	for _, key in { "Speed", "Power", "Capacity" } do
		local values = Upgrades.items[key].values
		for level = 1, #values - 1 do
			local price = Upgrades.price(key, level)
			miner.gold = price - 1
			assert(not Profile.buy(miner, key) and miner.gold == price - 1 and miner.levels[key] == level)
			checkBag()
			miner.gold = price
			assert(Profile.buy(miner, key) and miner.gold == 0 and miner.levels[key] == level + 1)
			assert(Profile.stat(miner, key) == values[level + 1])
			checkBag()
		end
		miner.gold = 1e7
		assert(not Profile.buy(miner, key) and miner.gold == 1e7 and miner.levels[key] == #values)
		checkBag()
	end
	for _, key in { "Speed", "Power", "Capacity" } do
		local values = Upgrades.items[key].values
		assert(Profile.stat(miner, key) == values[#values], key .. " reaches its top level")
	end
	assert(Profile.stat(miner, "Power") == #Config.StoneGrades, "the top pick mines every grade")
	miner.bag.Stone = 7201
	assert(not Profile.valid(miner))
end
print("PASS sales, gold-only upgrades with empty and stocked packs, exact costs, insufficient funds and level caps")
local retired = Profile.new()
retired.levels.Radius = 4
assert(Data.claim({ profile = retired }, "migration", 0).profile.gold == 234)
assert(retired.levels.Radius == nil and Profile.upgradeSave(retired).gold == 234)
local legacy = Profile.new()
legacy.jobs, legacy.discoveries, legacy.bag, legacy.mined = nil, nil, { Coal = 3 }, 36
legacy.preferences, legacy.claimedJobs, legacy.recentCuts, legacy.earned = nil, nil, nil, nil
legacy.counts, legacy.viewed = nil, nil
legacy.bestDepth = 361
local upgraded = Data.claim({ profile = legacy }, "harbor", 0).profile
assert(upgraded.discoveries.Coal and upgraded.jobs == 0)
assert(Profile.claimJob(upgraded, 2).reward == 80 and not Profile.claimJob(upgraded, 2))
assert(not Profile.claimJob(upgraded, 3) and not Profile.claimJob(upgraded, -1))
assert(not Profile.claimJob(upgraded, 1.5) and not Profile.claimJob(upgraded, "1"))
assert(Profile.claimJob(upgraded, 1).reward == 25 and not Profile.claimJob(upgraded, 1))
assert(Profile.sell(upgraded, 2) == 30 and upgraded.gold == 135 and upgraded.discoveries.Coal)
assert(upgraded.preferences.MusicVolume == 55 and upgraded.preferences.SfxVolume == 80)
assert(upgraded.preferences.MusicMuted == false and upgraded.preferences.SfxMuted == false)
upgraded.preferences.SfxMuted = true
upgraded.preferences.MusicVolume, upgraded.preferences.MenuMotion = 0, false
assert(upgraded.preferences.TrailEnabled)
upgraded.preferences.TrailEnabled = false
assert(Profile.markViewed(upgraded, "Book", "Coal") and not Profile.markViewed(upgraded, "Book", "Coal"))
assert(
	not Profile.markViewed(upgraded, "Book", "Starfall")
		and not Profile.markViewed(upgraded, "Achievements", "LuckAndSkill")
)
-- Pocket Change now asks for ten coal.
assert(not Profile.markViewed(upgraded, "Achievements", "PocketChange"))
upgraded.counts.Coal = 10
assert(Profile.markViewed(upgraded, "Achievements", "PocketChange"))
local snapshot = Data.commit({ owner = "harbor" }, "harbor", upgraded, 100, true)
local loaded = Data.claim(snapshot, "again", 101).profile
assert(loaded.viewed.BookCoal and loaded.viewed.AchievementsPocketChange and loaded.preferences.TrailEnabled == false)
assert(loaded.bestDepth == 450 and Profile.depthRecord(loaded) == 90)
assert(not Profile.recordDepth(loaded, 89) and Profile.recordDepth(loaded, 91))
assert(Profile.depthRecord(Data.claim({ profile = Data.snapshot(loaded) }, "depth", 102).profile) == 91)
assert(loaded.preferences.MusicVolume == 0 and not loaded.preferences.MenuMotion)
assert(loaded.preferences.SfxMuted and loaded.preferences.SfxVolume == 80 and not loaded.preferences.MusicMuted)
assert(Profile.valid(loaded) and loaded.jobs == 2 and loaded.discoveries.Coal)
do
	local session = { profile = loaded, writable = false }
	assert(not Data.resetProgress(nil, session) and session.profile == loaded, "protect unavailable saves")
	session.practice = true
	Config.AllowProgressReset = false
	assert(not Data.resetProgress(nil, session) and session.profile == loaded, "release switch")
	Config.AllowProgressReset = true
	assert(Data.resetProgress(nil, session))
	local resetSave = Data.commit({ owner = "tester" }, "tester", Data.snapshot(session.profile), 103, true)
	local fresh = Data.claim(resetSave, "tester2", 104).profile
	assert(Profile.valid(fresh) and fresh.gold == 0 and fresh.xp == 0 and fresh.bestDepth == 0)
	assert(fresh.jobs == 0 and fresh.claimedJobs == 0 and fresh.mined == 0 and fresh.levels.Power == 1)
	assert(not next(fresh.discoveries) and not next(fresh.viewed) and not next(fresh.skills) and not next(fresh.bag))
	assert(fresh.preferences.SfxMuted and fresh.preferences.MusicVolume == 0 and not fresh.preferences.MenuMotion)
end
local ordered = Profile.new()
ordered.jobs, ordered.claimedJobs, ordered.mined = 3, nil, 260
Profile.upgradeSave(ordered)
assert(ordered.claimedJobs == 7 and not Profile.claimJob(ordered, 3))
assert(Profile.claimJob(ordered, 5) and Profile.claimJob(ordered, 4) and ordered.jobs == 5)
print("PASS old job claims, independent payouts, duplicate claims, doubled sales and reload")

local titles = require(Shared.Expeditions)
local oldMiner = Profile.new()
oldMiner.xp, oldMiner.mined = nil, 38
oldMiner.bag = { Coal = 2, Stone = 3 }
assert(Data.claim({ profile = oldMiner }, "xp", 0).profile.xp == 6)
for i, title in titles.ranks do
	local level = titles.level(titles.levelXP(title.level))
	assert(level == title.level and titles.rank(level) == i)
end
local Guide = require(Shared.FieldGuide)
local challenge = Profile.new()
local awards = {}
for _, award in Guide.achievements do
	awards[award.id] = award
end
local scales = awards.Scales
for _, name in { "Dirt", "Stone", "Stone", "Coal", "Copper", "Iron", "Gold", "Diamond" } do
	Profile.recordCut(challenge, name)
end
assert(not challenge.earned.Scales and Guide.progress(challenge, scales) == 0)
assert(not challenge.earned.CleanSale and not challenge.earned.Ascent)
for i, name in scales.sequence do
	local unlocked = Profile.recordCut(challenge, name)
	assert(Guide.progress(challenge, scales) == i)
	if i == 3 then
		local record = Data.commit({ owner = "challenge" }, "challenge", challenge, 20, true)
		challenge = Data.claim(record, "return", 21).profile
	elseif i == #scales.sequence then
		assert(table.find(unlocked, scales.name))
	end
end
for _, name in scales.sequence do
	assert(not table.find(Profile.recordCut(challenge, name), scales.name))
end
local haul = Profile.new()
local split = Profile.new()
split.bag = { Dirt = 10, Gold = 2 }
for _, amount in { -2, 0, 1.5, math.huge, 0/0, "2" } do
	assert(Profile.sell(split, 2, "Dirt", amount) == nil)
end
assert(Profile.sell(split, 2, "Dirt", 11) == 0 and split.bag.Dirt == 10 and split.gold == 0)
local partialGold, _, partialCount = Profile.sell(split, 2, "Dirt", 7)
assert(partialGold == 14 and partialCount == 7 and split.bag.Dirt == 3 and split.bag.Gold == 2)
split = Profile.new()
split.bag = { Stone = 4, Coal = 2, Copper = 3 }
local oneGold, oneAward, oneCount = Profile.sell(split, 2, "Copper", 1)
assert(oneGold == 24 and not oneAward and oneCount == 1 and split.bag.Copper == 2)
local stackGold, stackAward, stackCount = Profile.sell(split, 2, "Copper", "Stack")
assert(stackGold == 48 and not stackAward and stackCount == 2 and not split.bag.Copper)
assert(Profile.sell(split, 2, "Copper", "Stack") == 0)
assert(Profile.sell(split, 2, "Fake", 1) == nil and Profile.sell(split, 2, "Coal", -1) == nil)
assert(Profile.sell(split, 2, nil, "Stack") == nil and Profile.sell(split, 2, "Coal", nil) == nil)
assert(split.gold == 72 and split.bag.Stone == 4 and split.bag.Coal == 2)
split.gold += Upgrades.price("Power", 1) - 36
assert(Profile.buy(split, "Power") and split.gold == 36 and split.bag.Stone == 4 and split.bag.Coal == 2)
assert(Profile.sell(split, 1, "Stone", "Stack") == 8)
local lastGold, lastAward, lastCount = Profile.sell(split, 1, "Coal", "Stack")
assert(lastGold == 10 and lastAward == awards.CleanSale.name and lastCount == 2 and Profile.used(split) == 0)
for _, bag in { {}, { Stone = 2 }, { Dirt = 1, Coal = 2 }, { Gold = 0 } } do
	haul.bag = bag
	local _, award = Profile.sell(haul)
	assert(not award)
end
haul.bag = { Iron = 1, Copper = 3 }
local payout, award = Profile.sell(haul)
assert(payout == 60 and award == awards.CleanSale.name)
haul.bag = { Coal = 1 }
local _, repeatAward = Profile.sell(haul)
assert(not repeatAward and haul.earned.CleanSale and not haul.earned.Scales)
haul.gold = Upgrades.price("Power", 1)
haul.bag = { Stone = 4 }
local bought, _, workshopAward = Profile.buy(haul, "Power")
assert(bought and workshopAward == awards.PickUpgrade.name and haul.gold == 0 and haul.bag.Stone == 4)
haul.earned.Sandwich = true
assert(Profile.valid(haul) and Data.claim({ profile = haul }, "legacyAward", 32).profile.earned.Sandwich)
assert(not table.find(Profile.recordCut(haul, "Starfall"), awards.LuckAndSkill.name))
local Materials = require(Shared.Materials)
local supplies = Profile.new()
supplies.gold = 150
supplies.bag = { Coal = 2, Copper = 1 }
for _, ore in Ores.list do
	assert(not Profile.buySupply(supplies, ore.name), "Field Supplies offered " .. ore.name)
end
assert(not Profile.buySupply(supplies, "Flare", 46) and Profile.used(supplies) == 3 and supplies.gold == 150)
supplies.bag = { Copper = 3, Coal = 7 }
assert(Profile.buySupply(supplies, "Flare") and supplies.flares == 1 and supplies.bag.Copper == 1 and supplies.bag.Coal == 4)
assert(Profile.buySupply(supplies, "Temper") and supplies.temper == 25 and not supplies.bag.Coal)
assert(not Profile.buySupply(supplies, "Temper") and supplies.gold == 150)
supplies = Profile.upgradeSave(supplies)
assert(not supplies.discoveries.Copper and supplies.mined == 0 and supplies.xp == 0)
local day = 20000
local order = Materials.daily(day)
supplies.bag = table.clone(order.recipe)
assert(not Profile.deliver(supplies, day, day - 1) and supplies.gold == 150)
assert(Profile.deliver(supplies, day, day) and Profile.used(supplies) == 0)
assert(supplies.gold == 150 + order.gold and supplies.flares == 2 and not Profile.deliver(supplies, day, day))
assert(Materials.daily(day + 1) ~= order and Profile.valid(supplies))
local neutral, spent = Ores.cutTime(0.8, Ores.byName.Stone, 1, 25)
assert(not spent and neutral == Ores.cutTime(0.8, Ores.byName.Stone, 1))
local hard, tempered = Ores.cutTime(0.8, Ores.byName.Stone, 2, 25)
assert(tempered and hard == Ores.cutTime(0.8, Ores.byName.Stone, 2) * 0.8)
assert(table.find(Profile.recordCut(haul, "Starfall"), awards.LuckAndSkill.name))
assert(not table.find(Profile.recordCut(haul, "Starfall"), awards.LuckAndSkill.name))
local reader = Instance.new("Folder")
local hiddenTitle, hiddenDetail = Guide.awardText(awards.CopperCollector, reader)
assert(hiddenTitle == "Copper Collector" and hiddenDetail == "Mine 50 Copper.")
reader:SetAttribute("FoundDirt", true)
local _, sequenceText = Guide.awardText(scales, reader)
assert(sequenceText == "Dirt → Stone → Coal → Copper → Iron → Gold → Diamond")
assert(awards.FirstStarfall == nil and awards.FirstGold == nil and awards.PocketChange.goal == 10)
reader:Destroy()
do
	local Skills = require(Shared.Skills)
	local specialist = Profile.new()
	specialist.xp = titles.levelXP(#Skills.nodes + 1)
	local function points()
		return Guide.points(specialist.xp, specialist.skills)
	end
	assert(Profile.learn(specialist, "Reach") and not Profile.learn(specialist, "Focus"))
	assert(points() == #Skills.nodes - 1)
	assert(Profile.learn(specialist, "Lamp") and Profile.learn(specialist, "Focus"))
	assert(not Profile.learn(specialist, "Focus") and Skills.bonus(specialist.skills, "focus") == 9)
	local visited = {}
	for _, node in Skills.nodes do
		assert(not visited[node.id] and Skills.byId[node.id] == node)
		for _, parent in node.requires do
			assert(visited[parent], "unreachable prerequisite on " .. node.id)
		end
		visited[node.id] = true
		assert(specialist.skills[node.id] or Profile.learn(specialist, node.id))
	end
	local owned = specialist.skills
	assert(points() == 0 and specialist.earned.Branch)
	assert(
		Skills.bonus(owned, "reach") == 20 and Skills.bonus(owned, "lamp") == 24 and Skills.bonus(owned, "focus") == 15
	)
	assert(Skills.walkSpeed(owned, { Stone = 74, Diamond = 0 }, 74, 100) == 28)
	assert(Skills.walkSpeed(owned, { Stone = 74, Diamond = 1 }, 75, 100) == 34)
	assert(Skills.walkSpeed(owned, { Diamond = 1, Emerald = 1 }, 2, 100) == 31)
	local gem = Ores.byName.Diamond
	local before = specialist.xp
	Profile.recordCut(specialist, "Dirt", 200)
	Profile.recordCut(specialist, "Stone", 200)
	assert(specialist.xp == before)
	Profile.recordCut(specialist, "Diamond", 184)
	assert(specialist.xp - before == gem.xp + 3 + 4 + 25)
	before = specialist.xp
	Profile.recordCut(specialist, "Diamond", 185)
	assert(specialist.xp - before == gem.xp + 3 + 4 + 3)
	local cut, used = Skills.cutTime(1, gem, 3, 1, owned)
	assert(used and math.abs(cut - Ores.cutTime(1, gem, 3) * 0.7 * 0.8 * 0.7) < 1e-6)
	assert(
		math.abs(Skills.cutTime(1, Ores.byName.Stone, 1, 0, owned) - Ores.cutTime(1, Ores.byName.Stone, 1) * 0.7 * 0.85)
			< 1e-6
	)
	Profile.consume(specialist, table.clone(specialist.bag))
	specialist.bag = table.clone(Materials.supplies.Temper.recipe)
assert(Profile.buySupply(specialist, "Temper") and specialist.temper == 45)
	specialist.bag = table.clone(Materials.daily(day).recipe)
	assert(
		Profile.deliver(specialist, day, day) and specialist.flares == 2 and not Profile.deliver(specialist, day, day)
	)
	assert(Profile.stat(specialist, "Capacity") == 35)
	-- An old 36-slot bag could legally hold 70 with all hauling skills.
	specialist.bag = { Stone = 70 }
	local record = Data.commit({ owner = "skills" }, "skills", specialist, 100, true)
	local rejoined = Data.claim(record, "next", 101).profile
	assert(rejoined.skills.Constellation and rejoined.temper == 45 and Profile.valid(rejoined))
	rejoined.bag.Stone = 71
	assert(not Profile.valid(rejoined))
	local legacySkills = {
		Reach = true,
		ReachII = true,
		Tempo = true,
		Stride = true,
		Spring = true,
		Scout = true,
		Lamp = true,
		Lantern = true,
	}
	local veteran = Profile.new()
	veteran.xp, veteran.skills = titles.levelXP(10), legacySkills
	veteran = Data.claim({ profile = veteran }, "veteran", 101).profile
	assert(Guide.points(veteran.xp, veteran.skills) == 1 and Profile.learn(veteran, "Focus"))
	assert(Skills.walkSpeed(veteran.skills, {}, 0, 36) == 22 and Skills.bonus(veteran.skills, "cut") == 10)
	local farCave = {
		isCave = function(_, cell)
			return cell == Vector3.new(13, 0, 0)
		end,
	}
	local flares = require(Server.SurveyFlare)
	assert(
		not flares.findCave(farCave, Vector3.zero)
			and flares.findCave(farCave, Vector3.zero, 15) == Vector3.new(13, 0, 0)
	)
	print(
		"PASS skill graph, shared prerequisites, veteran saves, ranked bonuses, conditional movement, XP, temper and flares"
	)
end
local ascent = require(Server.Ascent)
local trip = {}
local function climb(y, time, character)
	return ascent.sample(trip, character or "miner", Vector3.new(0, y, -20), true, time)
end
assert(not climb(-100 * Config.Cell, 0) and not trip.climb)
assert(not climb(-101 * Config.Cell, 1) and trip.climb)
assert(not climb(1, 1.5) and not trip.climb)
climb(-102 * Config.Cell, 2)
assert(not climb(1, 3, "respawn"))
climb(-102 * Config.Cell, 4)
for i = 1, 51 do
	assert(climb((-102 + 2 * i) * Config.Cell, 4 + i * 0.5) == (i == 51))
end
assert(not climb(5, 30.5))
print("PASS consecutive cuts, masked discoveries, unique sale/upgrade awards and manual ascent")
local miner = Profile.new()
assert(not Profile.learn(miner, "Reach"))
miner.xp = titles.levelXP(3)
assert(not Profile.learn(miner, "ReachII") and Profile.learn(miner, "Reach") and not Profile.learn(miner, "Reach"))
assert(Profile.learn(miner, "ReachII") and Guide.points(miner.xp, miner.skills) == 0)
assert(Profile.equipTitle(miner, 1) and not Profile.equipTitle(miner, 6))
miner.counts.Dirt = 1000
miner.pet = "Rock"
miner.petName = "Flint"
local saved = Data.commit({ owner = "m" }, "m", miner, 1, true)
assert(
	Data.claim(saved, "n", 2).profile.counts.Dirt == 1000
		and saved.profile.title == 1
		and saved.profile.skills.ReachII
		and saved.profile.petName == "Flint"
)
assert(Ores.byName.Dirt.xp == 0 and Ores.byName.Stone.xp == 0 and Ores.byName.Starfall.xp > Ores.byName.Emerald.xp)
local top = Geology.new(11)
for x = -5, 4 do
	for z = -11, -2 do
		assert(top:material(Vector3.new(x, -1, z)) == Ores.byName.Dirt.material)
		assert(top:material(Vector3.new(x, -2, z)) ~= Ores.byName.Dirt.material)
	end
end
assert(not Ores.byMaterial[top:material(Vector3.new(5, -1, -3))])
local hashes = {}
for _, seed in { 11, 73129, 91003, 73129 } do
	local geo = Geology.new(seed)
	local hash = 0
	for _, layer in Config.Layers do
		local counts, total = {}, 0
		for x = -65, 65 do
			for z = -33, 33 do
				local mat = geo:material(Vector3.new(x, -layer.depthBlocks - 9, z))
				local ore = Ores.byMaterial[mat]
				if ore then
					assert(ore.name ~= "Dirt")
					counts[ore.name] = (counts[ore.name] or 0) + 1
					total += 1
				end
				hash = (hash * 31 + mat.Value) % 1000000007
			end
		end
		assert(counts.Stone / total > 0.70, layer.name)
		for name, chance in layer.oreChances do
			assert(math.abs((counts[name] or 0) / total - chance / 100) < 0.025, name)
		end
	end
	if hashes[seed] then
		assert(hashes[seed] == hash)
	end
	hashes[seed] = hash
end
assert(hashes[11] ~= hashes[73129] and hashes[91003] ~= hashes[73129])
assert(
	Config.blockCoordinates(Vector3.new(-0.1, Config.FloorY - 27 * Config.Cell - 0.5, -9)) == Vector3.new(-1, -27, -2)
)
print("PASS one dirt layer, independent regional odds, repeatable fields and saved title levels")
-- Expansion: regions, stone grades, the ore catalog, rare-ore precision and saves from before it.
do
	local grades, layers = Config.StoneGrades, Config.Layers
	local last = #layers
	assert(#layers >= 10 and #grades >= 12, "the mine has its full set of regions and stone grades")
	assert(#Upgrades.items.Power.values == #grades and #Upgrades.pickNames == #grades, "one pick per grade")
	for i = 2, #grades do
		assert(grades[i].depth > grades[i - 1].depth, "stone grades deepen in order")
	end
	for i = 2, last do
		assert(layers[i].depthBlocks > layers[i - 1].depthBlocks, "regions deepen in order")
	end
	-- The first six grades keep their depths, so an existing pick reaches the same rock as before.
	for i, depth in { 0, 27, 60, 90, 140, 185 } do
		assert(grades[i].depth == depth, grades[i].name .. " keeps its depth")
	end
	-- Region and grade boundaries fall exactly on their first block.
	for i, layer in layers do
		local topStuds = layer.depthBlocks * Config.Cell
		assert(Config.layer(topStuds + 0.01) == layer, layer.name .. " starts on its first block")
		if i > 1 then
			assert(Config.layer(topStuds - 0.01) == layers[i - 1], layer.name .. " starts no higher")
		end
	end
	for tier, grade in grades do
		local y = Config.FloorY - grade.depth * Config.Cell
		assert(Config.strength(y - 0.01) == tier, grade.name .. " starts on its first block")
		if tier > 1 then
			assert(Config.strength(y + 0.01) == tier - 1, grade.name .. " starts no higher")
		end
	end
	local function tierAt(depthBlocks)
		return Config.strength(Config.FloorY - depthBlocks * Config.Cell - 0.01)
	end
	-- Every region's table holds known ores at positive odds and stays mostly plain stone.
	local appears, lowest, lowestName = {}, math.huge, nil
	for i, layer in layers do
		local total = 0
		for name, chance in layer.oreChances do
			local ore = Ores.byName[name]
			assert(ore and not ore.host and chance > 0, layer.name .. ": " .. name)
			total += chance
			appears[name] = appears[name] or {}
			table.insert(appears[name], i)
			if chance < lowest then
				lowest, lowestName = chance, name
			end
		end
		assert(total < 30, layer.name .. " stays mostly plain stone")
	end
	for _, list in appears do
		table.sort(list)
	end
	assert(lowestName == "Starfall", "Starfall has the lowest chance of any ore")
	-- Every ore can be found, and mined with the region's pick or one no more than two levels on.
	for _, ore in Ores.list do
		if ore.host then
			continue
		end
		assert(appears[ore.name], ore.name .. " appears in at least one region")
		assert(ore.hardness >= 1 and ore.hardness <= #grades, ore.name .. " is mineable with some pick")
		for _, i in appears[ore.name] do
			assert(ore.hardness <= tierAt(layers[i].depthBlocks) + 2, ore.name .. " in " .. layers[i].name .. " is in reach")
		end
	end
	assert(#appears.Starfall == 1 and appears.Starfall[1] == last, "Starfall appears only in the final region")
	assert(Ores.byName.Starfall.hardness == #grades, "Starfall needs the final pick")
	assert(#appears.Sunstone == 1 and appears.Sunstone[1] == 1, "Sunstone is found only in the first stone region")
	assert(Ores.byName.Sunstone.hardness <= tierAt(layers[1].depthBlocks), "a starter pick can mine Sunstone")
	local exclusive = 0
	for _, list in appears do
		if #list == 1 then
			exclusive += 1
		end
	end
	assert(exclusive >= 4, "several ores are found in only one region")
	local earlyMystery = false
	for _, ore in Ores.list do
		if ore.secret then
			assert(type(ore.hint) == "string" and #ore.hint > 0, ore.name .. " needs a hint")
			earlyMystery = earlyMystery or appears[ore.name][1] < last - 1
		end
	end
	assert(earlyMystery, "a mystery ore exists outside the final regions")
	-- The fine roll keeps every share exact, even Starfall's one in 250,000.
	for _, layer in layers do
		local previous, total, listed = 0, 0, 0
		for _, entry in Geology.thresholds[layer] do
			local chance = layer.oreChances[entry.name]
			total += chance
			listed += 1
			assert(entry.material == Ores.byName[entry.name].material and entry.limit > previous, layer.name .. " " .. entry.name)
			assert(math.abs(entry.limit / Geology.scale - total / 100) <= 1 / Geology.scale, layer.name .. " " .. entry.name)
			previous = entry.limit
		end
		local count = 0
		for _ in layer.oreChances do
			count += 1
		end
		assert(listed == count, layer.name .. " rolls every listed ore once")
	end
	local function band(layer, name)
		local low = 0
		for _, entry in Geology.thresholds[layer] do
			if entry.name == name then
				return low, entry.limit
			end
			low = entry.limit
		end
		error(name .. " is not in " .. layer.name)
	end
	local starfallLow, starfallHigh = band(layers[last], "Starfall")
	assert(math.abs((starfallHigh - starfallLow) / Geology.scale - 0.000004) < 1e-9, "Starfall is one block in 250,000")
	-- Sampled with the real rolls across several seeds, rare ores land near their odds.
	local function hits(layer, name, seeds, cells)
		local low, high = band(layer, name)
		local count = 0
		for _, seed in seeds do
			for n = 0, cells - 1 do
				local roll = Geology.roll(seed, n % 1000 - 500, -layer.depthBlocks - 4, n // 1000)
				if roll >= low and roll < high then
					count += 1
				end
			end
		end
		return count
	end
	-- Sunstone Hollow kept its original Coal and Copper odds, so for any seed its original coal and
	-- copper blocks are unchanged; Pyrite and Sunstone only replace what was plain stone.
	do
		local hollow = Geology.new(74109)
		for n = 0, 19999 do
			local cell = Vector3.new(n % 100 - 50, -2 - (n // 100) % 20, n // 2000 - 5)
			if not hollow:isCave(cell) then
				local old = (Geology.hash(74109, cell.X, cell.Y, cell.Z) % 100000) / 1000
				local now = hollow:material(cell)
				if old < 13 then
					assert(now == Ores.byName.Coal.material, "original coal moved at " .. tostring(cell))
				elseif old < 18 then
					assert(now == Ores.byName.Copper.material, "original copper moved at " .. tostring(cell))
				else
					local ore = Ores.byMaterial[now]
					assert(not ore or ore.name == "Stone" or ore.name == "Pyrite" or ore.name == "Sunstone", tostring(cell))
				end
			end
		end
	end
	local sunstone = hits(layers[1], "Sunstone", { 3, 17, 29, 41 }, 250000) -- expect 200
	assert(sunstone > 150 and sunstone < 250, "Sunstone sampled " .. sunstone .. " times in a million blocks")
	local starfall = hits(layers[last], "Starfall", { 5, 6, 7, 8, 9 }, 1000000) -- expect 20
	assert(starfall >= 6 and starfall <= 38, "Starfall sampled " .. starfall .. " times in five million blocks")
	print("SAMPLE Sunstone", sunstone, "per million; Starfall", starfall, "per five million")
	-- A save from before the expansion still loads, with its picks, pack and discoveries.
	local oldSave = Profile.new()
	oldSave.levels = { Speed = 7, Power = 6, Capacity = 8 }
	oldSave.bag = { Coal = 10, Emerald = 2, Starfall = 1 }
	oldSave.counts = { Coal = 400, Emerald = 3, Starfall = 1, Amethyst = 2 }
	oldSave.discoveries = { Coal = true, Emerald = true, Starfall = true, Amethyst = true }
	oldSave.progression = nil
	assert(Profile.valid(oldSave), "a save from before the expansion is still valid")
	local reloaded = Data.claim({ profile = oldSave }, "oldSave-expansion", 60).profile
	assert(reloaded.levels.Power == 6 and Profile.stat(reloaded, "Power") == 6 and Upgrades.pickNames[6] == "Prismheart Pick", "old pick kept")
	-- Old Speed 7 (0.20 s) and Capacity 8 (64 slots) move to the first long-curve level as good.
	assert(reloaded.progression == 2 and reloaded.levels.Speed == 100 and reloaded.levels.Capacity == 5, "old gear migrated")
	assert(Profile.stat(reloaded, "Speed") == 0.2 and Profile.stat(reloaded, "Capacity") == 64, "old gear kept")
	assert(Upgrades.migrateLevel("Speed", 1) == 1 and Upgrades.migrateLevel("Capacity", 2) == 2, "starter levels unchanged")
	assert(Upgrades.price("Power", 6) and not Upgrades.price("Speed", 100) and Upgrades.price("Capacity", 5), "migrated gear upgrades further")
	Profile.recordCut(reloaded, "Sunstone", 5)
	Profile.recordCut(reloaded, "Voidshard", 600)
	assert(reloaded.discoveries.Sunstone and reloaded.bag.Voidshard == 1 and Profile.valid(reloaded), "new ores save")
	reloaded.bag.Fakeite = 1
	assert(not Profile.valid(reloaded), "unknown ores are still rejected")
end
assert(
	Config.ResetAfter - Config.Layers[#Config.Layers].depthBlocks >= 2000,
	"A renewal cycle should leave room to mine after a shaft to the crater"
)
print("PASS expansion regions, grade boundaries, ore reach, Starfall rarity, 32-bit precision, rare sampling and old saves")
local surface = workspace.CitrineCove
do
	local guide = require(game.StarterPlayer.StarterPlayerScripts.Client.ExpeditionWaypoint).new()
	local bridge = surface["Sand path and bridge"]["Bridge decking"]
	local head = Instance.new("Part")
	head.Anchored, head.CanCollide, head.Parent = true, false, workspace
	local top = bridge.Position + Vector3.new(0, 4, bridge.Size.Z / 2 - 2)
	guide:show(bridge.Position - Vector3.zAxis * 32, "Mine", Color3.new(1, 0.8, 0.2), true)
	for _, moving in { true, false } do
		head.Position = top
		guide:trail(head, 10, moving)
		local before, checked = {}, 0
		for _, part in guide.anchor:GetChildren() do
			if part.Name == "Trail chevron" and part.Transparency < 0.2 then before[part] = part.Position end
		end
		head.Position -= Vector3.zAxis * 0.25
		guide:trail(head, 10 + 1 / 60, moving)
		for part, at in before do
			if part.Transparency >= 0.2 then continue end
			local distance = (part.Position - at) * Vector3.new(1, 0, 1)
			assert(math.abs(distance.Magnitude - (if moving then 4.2 / 60 else 0)) < 0.01, "ground arrows drifted with the player")
			checked += 1
		end
		assert(checked >= 2, "guidance disappeared between walking frames")
	end
	-- An approach on the outer bank follows its own bridge. A miner below the
	-- crossing can see the nearest stairs and returns to their original objective on dry land.
	local dryTarget = bridge.Position + Vector3.new(41, 0, -31)
	guide:show(dryTarget, "Sell ore", Color3.new(1, 0.8, 0.2), true)
	head.Position = bridge.Position + Vector3.new(41, 4, 20)
	guide:trail(head, 15, false)
	assert(#guide.path == 3 and math.abs(guide.path[1].X - head.Position.X) < 2, "missed nearby side bridge")
	local deck
	for _, candidate in guide.decks do
		if math.abs(candidate.Position.X - head.Position.X) < 2 then deck = candidate end
	end
	local parent = assert(deck, "missing streamed deck").Parent
	deck.Parent = nil
	task.wait()
	guide:trail(head, 15.1, false)
	assert(not table.find(guide.decks, deck) and math.abs(guide.path[1].X - head.Position.X) > 20, "routed across an unloaded bridge")
	deck.Parent = parent
	task.wait()
	guide:trail(head, 15.2, false)
	assert(table.find(guide.decks, deck) and math.abs(guide.path[1].X - head.Position.X) < 2, "ignored newly streamed bridge")
	head.Position = bridge.Position + Vector3.new(14, -0.7, 0)
	guide:trail(head, 16, false)
	assert(guide.label.Text == "Climb the steps" and guide.path[1].X > bridge.Position.X, "no nearby canal exit")
	local paths = surface["Sand path and bridge"]
	local steps = {}
	for _, block in paths:GetChildren() do
		if (block.Name == "Canal step" or block.Name == "Canal landing") and math.abs(block.Position.X - guide.path[1].X) < 0.1 then
			table.insert(steps, block.Position.Y + block.Size.Y/2)
		end
	end
	table.sort(steps)
	assert(#steps == 8 and steps[#steps] > bridge.Position.Y and steps[1] < bridge.Position.Y - 3)
	for i = 2, #steps do assert(steps[i] - steps[i-1] < 0.8, "canal exit riser too high") end
	head.Position = dryTarget + Vector3.yAxis * 4
	guide:trail(head, 17, false)
	assert(guide.anchor.WorldPosition == dryTarget and guide.label.Text == "Sell ore", "dry objective was lost")
	head:Destroy()
	guide.anchor:Destroy()
end
local world = World.new(Config.LandscapeSeed, surface)
local mapCopy = surface:Clone()
-- The realistic ledges belong to the film's ancient island. The playable shore is stud-built.
assert(not mapCopy:FindFirstChild("TideCoast") and Shared:FindFirstChild("TideCoast"), "old tidal ledges around the new shore")
assert(mapCopy["Offshore water"].ModelStreamingMode == Enum.ModelStreamingMode.Persistent)
for _, part in mapCopy["Offshore water"]:GetDescendants() do
	if part:IsA("BasePart") then
		assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery, "offshore scenery interferes with mining or movement")
	end
end
do
	local allowed = { [Enum.Material.Plastic] = true, [Enum.Material.SmoothPlastic] = true, [Enum.Material.Neon] = true, [Enum.Material.Metal] = true, [Enum.Material.Wood] = true }
	for _, part in mapCopy:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 and not part:FindFirstAncestor("EditFace") and not part:FindFirstAncestor("Working gallery") then
			assert(allowed[part.Material], "off-style material " .. part.Material.Name .. " on " .. part:GetFullName())
		end
	end
end
local site = require(Server.MineSite).bind(mapCopy, world)
assert(mapCopy.PrimaryPart and mapCopy.EditFace)
assert(site.spawn:IsA("SpawnLocation") and site.spawn.Neutral)
assert(site.stations.Sell:IsA("ProximityPrompt") and site.stations.Shop:IsA("ProximityPrompt"))
mapCopy.Parent = workspace
do
	local art = require(Shared.MineralRelief)
	local looks = require(Shared.OreLooks)
	local kit = require(Shared.ReliefKit)
	local starfall = Ores.list[#Ores.list]
	assert(starfall.name == "Starfall", "Starfall stays the last ore")
	for _, ore in Ores.list do
		assert(ore == starfall or ore.value < starfall.value, "Starfall stays the most valuable ore")
		local look = looks.ores[ore.name]
		assert(ore.host or look, ore.name .. " needs an OreLooks entry")
		assert(not look or kit.recipes[look.relief], ore.name .. " uses an unknown relief recipe")
		assert(not (look and look.crown) or kit.crowns[look.crown], ore.name .. " uses an unknown crown")
	end
	-- Glow is kept for exceptional ores: Gold and the original gems glow, nothing cheaper than
	-- Gold does, every glow has a colour and a strength, and Starfall glows the most.
	local brightest = 0
	for _, ore in Ores.list do
		local shine = art.shine(ore.name)
		if shine then
			assert(shine > 0 and shine <= 1 and art.glow(ore.name), ore.name .. " needs a glow colour and strength")
			assert(ore.value >= Ores.byName.Gold.value, ore.name .. " is too cheap to glow")
			brightest = math.max(brightest, shine)
		end
	end
	for _, name in { "Gold", "Diamond", "Emerald", "Amethyst", "Sapphire", "Emberglass" } do
		assert(art.shine(name) and art.shine(name) < art.shine("Starfall"), name .. " glows less than Starfall")
	end
	assert(brightest == art.shine("Starfall"), "Starfall glows the most")
	for name, rock in looks.rock do
		for variant = 1, 3 do
			local decor = art.decor(name, CFrame.identity, variant)
			local count = #decor:GetChildren()
			assert(count >= 3 and count <= 16, name .. " decor stays light")
			decor:Destroy()
		end
		assert(kit.recipes[rock.decor], name .. " uses an unknown decor recipe")
	end
	-- Drawn faces: every block that can be mined has one, and each drawing fills its whole face.
	local client = game:GetService("StarterPlayer").StarterPlayerScripts.Client
	local drawings, pieceImages, glowImages = client.OreDrawings, client.OrePieces, client.OreGlow
	local http, encoding = game:GetService("HttpService"), game:GetService("EncodingService")
	local sources = drawings:GetChildren()
	for _, extra in { pieceImages, glowImages } do
		table.move(extra:GetChildren(), 1, #extra:GetChildren(), #sources + 1, sources)
	end
	for _, value in sources do
		local drawing = http:JSONDecode(value.Value)
		local tape = encoding:Base64Decode(buffer.fromstring(drawing.tape))
		local filled, off = 0, 0
		while off < buffer.len(tape) do
			local count = buffer.readu8(tape, off + 4)
			off += 5
			for _ = 1, count do
				filled += buffer.readu16(tape, off)
				assert(buffer.readu8(tape, off + 2) < #drawing.palette, value.Name .. " drawing uses a missing colour")
				off += 3
			end
		end
		assert(filled == drawing.width * drawing.height, value.Name .. " drawing must fill its face")
	end
	for _, ore in Ores.list do
		assert(drawings:FindFirstChild(ore.name) or drawings:FindFirstChild(ore.name .. "-1"), ore.name .. " needs a drawn face")
		assert(not art.isMineral(ore.name) or pieceImages:FindFirstChild(ore.name), ore.name .. " needs a pieces image")
		if art.isMineral(ore.name) then
			local spots = http:JSONDecode(pieceImages[ore.name].Value).glints
			assert(spots and #spots >= 1 and #spots <= 4, ore.name .. " needs one to four glint spots")
			for _, spot in spots do
				assert(spot[1] >= 0 and spot[1] <= 1 and spot[2] >= 0 and spot[2] <= 1, ore.name .. " glint spot off its face")
			end
		end
		assert(not art.shine(ore.name) or glowImages:FindFirstChild(ore.name), ore.name .. " needs a glow image")
		if art.hasCrown(ore.name) then
			local crystals = art.crown(ore.name, CFrame.identity)
			assert(#crystals:GetChildren() >= 3 and #crystals:GetChildren() <= 30, ore.name .. " crystals stay light")
			crystals:Destroy()
		end
	end
	local signatures = {}
	for _, ore in Ores.list do
		if ore.host then continue end
		local relief = art.face(ore.name, CFrame.identity)
		local signature = {}
		for _, part in relief:GetChildren() do
			assert(part.Anchored and not part.CanQuery and not part.CanTouch and not part.CanCollide)
			table.insert(signature, part.ClassName .. tostring(part.Position) .. tostring(part.Size))
		end
		local shape = table.concat(signature, "|")
		assert(#signature > 4 and #signature <= 50 and not signatures[shape], ore.name .. " requires distinct, bounded geometry")
		signatures[shape] = true
		relief:Destroy()
	end
	assert(not mapCopy:FindFirstChild("Dig floor sill"))
	assert(mapCopy["Sand path and bridge"]["Portal paving"].Size.X >= 20)
	assert(mapCopy["Citrine Mine"]:FindFirstChild("Arch voussoir"))
end
local onMap = RaycastParams.new()
onMap.FilterType = Enum.RaycastFilterType.Include
onMap.FilterDescendantsInstances = { mapCopy }
onMap.RespectCanCollide = true
local function floorAt(x, z)
	return workspace:Raycast(world.origin + Vector3.new(x, 4, z), Vector3.new(0, -7, 0), onMap)
end
for _, x in { -3, 0, 3 } do
	local lastY = world.origin.Y
	for z = (site.spawn.Position - world.origin).Z, 0, -0.5 do
		local floor = floorAt(x, z)
		assert(floor and math.abs(floor.Position.Y - lastY) < 1, "Landing-to-mine path at " .. z)
		lastY = floor.Position.Y
	end
end
-- The thin gaps beside the sandstone seams were visible from the trail above.
for _, x in { -73, -63, -56, 52, 68, 76 } do
	for _, z in { -1.5, -4, -9, -18 } do
		local at = world.origin + Vector3.new(x, 40, z)
		local hit = workspace:Raycast(at, -Vector3.yAxis * 41, onMap)
		assert(hit and hit.Position.Y >= world.origin.Y - 0.5, "Open mine flank at " .. tostring(at))
	end
end
local highlands = mapCopy["Citrine Highlands"]
do
	-- The yard's rails run out of the adit on a clear bed, and the wagons stand on them.
	local yard = highlands["Ore siding"]
	local tracks, wheels = {}, 0
	for _, part in yard:GetChildren() do
		if part.Name == "Rail" then table.insert(tracks, part) end
	end
	assert(#tracks == 2 and yard:FindFirstChild("Adit lintel") and yard:FindFirstChild("Rail stop"), "rails without a mine or an end")
	for _, part in yard:GetChildren() do
		if part.Name == "Flanged wheel" then
			wheels += 1
			local near = math.huge
			for _, track in tracks do
				if math.abs(part.Position.Z - track.Position.Z) < track.Size.Z / 2 then
					near = math.min(near, math.abs(part.Position.X - track.Position.X))
				end
			end
			assert(near < 0.1, "a wagon is off its rails")
			assert(math.abs(part.Position.Y - part.Size.Y / 2 - (tracks[1].Position.Y + tracks[1].Size.Y / 2)) < 0.55, "a wagon floats")
		end
	end
	assert(wheels >= 8)
	-- Structural blocks carry the stud, on every face wide enough to show one.
	local studded, structural = 0, 0
	for _, part in mapCopy:GetDescendants() do
		if part:IsA("Part") and part.Material == Enum.Material.Plastic and part.Transparency < 0.5 and part.Name ~= "Dirt" and math.min(part.Size.X, part.Size.Y, part.Size.Z) > 2 then
			structural += 1
			if part.TopSurface == Enum.SurfaceType.Studs and part.FrontSurface == Enum.SurfaceType.Studs and part.LeftSurface == Enum.SurfaceType.Studs then
				studded += 1
			end
		end
	end
	assert(structural > 500 and studded / structural > 0.95, string.format("studs on %d of %d", studded, structural))
	-- Broad stairs join every level. No riser needs a jump.
	local flights = {}
	for _, part in mapCopy:GetDescendants() do
		if part.Name == "Stone step" then
			local key = part.Parent.Name .. tostring(math.round(part.CFrame.LookVector.X * 10)) .. tostring(math.round(part.CFrame.LookVector.Z * 10))
			flights[key] = flights[key] or {}
			table.insert(flights[key], part.Position.Y + part.Size.Y / 2)
		end
	end
	local count = 0
	for _, tops in flights do
		table.sort(tops)
		count += 1
		for i = 2, #tops do assert(tops[i] - tops[i - 1] < 0.8 or tops[i] - tops[i - 1] > 2, "a riser is too high") end
	end
	assert(count >= 5)
end
-- The bluff caps sit above the excavated gallery. Check underneath them too:
-- a top-down floor check alone can miss a player-sized slot in the sandstone.
do
	local bluffs = mapCopy["Honey bluffs"]
	local caps, rock = {}, {}
	for _, part in bluffs:GetChildren() do
		if part.Name == "Grass shelf" then
			table.insert(caps, part)
		elseif part.Name == "Weathered sandstone" then
			table.insert(rock, part)
		end
	end
	local function include(parts)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = parts
		return params
	end
	local grassRay, stoneRay = include(caps), include(rock)
	for _, point in { Vector2.new(28, -29), Vector2.new(-31, -30), Vector2.new(33, -7), Vector2.new(-31, -6) } do
		local at = Vector3.new(point.X, 80, point.Y)
		local cap = assert(workspace:Raycast(at, -Vector3.yAxis * 55, grassRay))
		local support = workspace:Raycast(cap.Position, -Vector3.yAxis * 2, stoneRay)
		assert(support, "Unsupported sandstone cap at " .. tostring(point))
	end
	-- Check the visible roof in addition to its structural support. These were the
	-- flat, exposed canopy and the player-sized pockets behind the front shelves.
	local crest = include({ mapCopy["Working gallery"], bluffs })
	for _, point in { Vector2.new(0, -14), Vector2.new(-7, -26), Vector2.new(7, -34), Vector2.new(-60, -30), Vector2.new(40, -30) } do
		local ridge = workspace:Raycast(Vector3.new(point.X, 60, point.Y), -Vector3.yAxis * 23, crest)
		assert(ridge and ridge.Instance.Name == "Grass shelf", "Uncapped mine roof at " .. tostring(point))
	end
	local trailRay = include({ highlands["Cableway trail"], mapCopy["Working gallery"] })
	for _, x in { -19, 0, 19 } do
		for z = -66, -59.5, 0.5 do
			local hit = workspace:Raycast(Vector3.new(x, 45, z), -Vector3.yAxis * 12, trailRay)
			assert(hit and hit.Instance.Name == "Ridgeline turf", "Gallery breaks through trail at " .. x .. ", " .. z)
		end
	end
end
-- Visual-only leaves and terrain sometimes opt out of gameplay raycasts.
-- Include them on the disposable map while checking their rendered positions.
do
	local crowns = { ["Leaf crown"] = true, ["Fir boughs"] = true, ["Pine crown"] = true, Fork = true }
	local trunks = { Trunk = true, ["Fir trunk"] = true, ["Pine trunk"] = true }
	local obstacles, foliage, bases, visualOnly = {}, {}, {}, {}
	for _, part in mapCopy:GetDescendants() do
		if not part:IsA("BasePart") or part.Transparency >= 0.95 then
			continue
		end
		if trunks[part.Name] then
			assert(part.CanCollide and part.CanQuery, "Pass-through tree in " .. part.Parent.Name)
		end
		if not part.CanQuery then
			part.CanQuery = true
			table.insert(visualOnly, part)
		end
		if crowns[part.Name] then
			table.insert(foliage, part)
		elseif trunks[part.Name] then
			table.insert(bases, part)
		else
			table.insert(obstacles, part)
		end
	end
	local overlap, ray = OverlapParams.new(), RaycastParams.new()
	overlap.FilterType, overlap.FilterDescendantsInstances = Enum.RaycastFilterType.Include, obstacles
	ray.FilterType, ray.FilterDescendantsInstances = Enum.RaycastFilterType.Include, obstacles
	for _, crown in foliage do
		local clipped = workspace:GetPartsInPart(crown, overlap)
		if clipped[1] then
			error("Tree at " .. tostring(crown.Position) .. " intersects " .. clipped[1]:GetFullName())
		end
	end
	for _, trunk in bases do
		local base = trunk.Position - Vector3.yAxis * (trunk.Size.Y * 0.5)
		local hit = workspace:Raycast(base + Vector3.yAxis, -Vector3.yAxis * 2, ray)
		assert(hit and math.abs(hit.Position.Y - base.Y) < 0.25, "Ungrounded tree at " .. tostring(base))
	end
	for _, part in visualOnly do
		part.CanQuery = false
	end
end
-- The high barrier sits on the outside of the rocky rim, including its angled joints.
do
	local edges, closed = {}, RaycastParams.new()
	for _, piece in highlands["Rock rim"]:GetChildren() do
		if piece.Name == "Outer cliff boundary" then table.insert(edges, piece) end
	end
	closed.FilterType, closed.FilterDescendantsInstances = Enum.RaycastFilterType.Include, edges
	closed.RespectCanCollide = true
	for angle = 0,359 do
		local a = math.rad(angle)
		assert(workspace:Raycast(world.origin + Vector3.new(0, 70, 30), Vector3.new(math.cos(a), 0, math.sin(a)) * 200, closed), "Open cliff top at " .. angle)
	end
end
local gallery = mapCopy["Working gallery"]
for _, x in { 1 - Config.HallHalfWidth, -21, -10, 0, 10, 21, Config.HallHalfWidth - 1 } do
	for z = Config.HallBack + 1, Config.HallFront - 1, 2 do
		local roof = workspace:Raycast(world.origin + Vector3.new(x, 7, z), Vector3.yAxis * 8, onMap)
		assert(roof and roof.Instance.Parent == gallery, "Landscape breaks through the gallery ceiling")
	end
end
for z = Config.HallBack + 1, Config.HallFront - 1, 2 do
	for _, side in { -1, 1 } do
		local start = world.origin + Vector3.new(side * (Config.HallHalfWidth - 0.5), 0.025, z)
		local wall = workspace:Raycast(start, Vector3.xAxis * side, onMap)
		assert(wall and wall.Instance.Name == "Hut side wall", "Exposed seam above first dirt layer")
	end
end
for x = 1 - Config.HallHalfWidth, Config.HallHalfWidth - 1, 2 do
	local start = world.origin + Vector3.new(x, 0.025, Config.HallBack + 0.5)
	local wall = workspace:Raycast(start, -Vector3.zAxis, onMap)
	assert(wall and wall.Instance.Name == "Hut back wall", "Exposed seam beneath rear wall")
end
local rimParams = RaycastParams.new()
rimParams.FilterType = Enum.RaycastFilterType.Include
rimParams.FilterDescendantsInstances = { highlands["Rock rim"] }
rimParams.RespectCanCollide = true
for angle = 0, 359 do
	local theta = math.rad(angle)
	local hit = workspace:Raycast(
		world.origin + Vector3.new(0, 7, 52),
		Vector3.new(math.sin(theta), 0, math.cos(theta)) * 230,
		rimParams
	)
	assert(hit, "Open shoreline at " .. angle .. " degrees")
end
for _, cell in
	{ Vector2.new(0, 125), Vector2.new(-83, 76), Vector2.new(88, 96), Vector2.new(-80, 31), Vector2.new(81, 31) }
do
	assert(floorAt(cell.X, cell.Y), "Outer promenade floor at " .. tostring(cell))
end
do
	local gallery = mapCopy["Working gallery"]
	local lamps = {}
	for _, item in gallery:GetDescendants() do
		if item:IsA("PointLight") and item.Name == "Lamplight" and item.Enabled then table.insert(lamps, item) end
	end
	assert(#lamps == 4, "reuse the four gallery lamps")
	for ix = 0, 20 do
		for iz = 0, 20 do
			local x = (ix / 10 - 1) * (Config.HallHalfWidth - 0.2)
			local z = Config.HallBack + 0.2 + (Config.HallFront - Config.HallBack - 0.4) * iz / 20
			local point = world.origin + Vector3.new(x, Config.FloorY + 0.18, z)
			local covered = false
			for _, light in lamps do
				local delta = light.Parent.Position - point
				if delta.Magnitude <= light.Range * 0.68 then
					local hit = workspace:Raycast(point, delta, onMap)
					if not hit or hit.Instance == light.Parent then covered = true break end
				end
			end
			assert(covered, "Dark patch on gallery floor at " .. tostring(point))
		end
	end
	print("PASS 441 floor samples have a clear path within the useful range of a gallery lamp")
end
for _, x in { -41, 41 } do
	for z = 20, 42 do
		assert(floorAt(x, z), "Incomplete creek crossing")
	end
end
assert(not mapCopy["Harbor Plaza"]:FindFirstChild("Core samples"))
local exhibit = mapCopy["Harbor Plaza"].Book
-- The stall shows a heap of ore chunks (one per ore, in its colour); the Ore Index page lists every ore.
local heap = 0
for _, part in exhibit:GetChildren() do
	local shown = Ores.byName[part.Name:match("^(.+) chunk$") or ""]
	if shown then
		assert(not shown.secret and part.Color == shown.color, part.Name)
		heap += 1
	end
	assert(not part.Name:match(" sample$") and not part.Name:match(" label$"), "Old labelled shelf left behind")
end
assert(heap >= 15, "The ore heap should hold at least fifteen chunks")
assert(not floorAt(10, 32), "The inlet should pass completely under the bridge")
for z = 2, Config.HallBack + 1, -0.5 do
	for _, x in { -6, 0, 6 } do
		local floor = floorAt(x, z)
		assert(floor and math.abs(floor.Position.Y - world.origin.Y) < 0.30, "Gap on hut approach at " .. z)
		assert(
			not workspace:Raycast(world.origin + Vector3.new(x, 0.4, z), Vector3.yAxis * 8, onMap),
			"Blocked walk-in"
		)
	end
end
assert(not mapCopy:FindFirstChild("Mine threshold", true))
assert(Config.FloorY == 0 and Config.Cell == 6)
-- From the rear or either rear corner, solid rock must close the view into the hut.
for x = 1 - Config.HallHalfWidth, Config.HallHalfWidth - 1, 1.5 do
	for height = 0.5, 12, 1 do
		local start = world.origin + Vector3.new(x, height, Config.HallBack - 13)
		assert(workspace:Raycast(start, Vector3.zAxis * 14, onMap), "Open back wall")
	end
end
for x = -35, 35, 1.25 do
	for z = Config.HallBack - 10, -14, 1.25 do
		assert(workspace:Raycast(world.origin + Vector3.new(x, 48, z), -Vector3.yAxis * 50, onMap), "Hole around hut")
	end
end
for k, prompt in site.stations do
	local pad = prompt.Parent
	assert(pad:HasTag("MiningInteractionPad") and typeof(pad:GetAttribute("AuraColor")) == "Color3", k)
	assert(pad["Interaction pad"].Frame:FindFirstChildOfClass("TextLabel"), k)
end
for _, part in mapCopy["Island and lagoon"]:GetDescendants() do
	if part:IsA("Part") and (part.Name == "Distant grass" or part.Name == "Distant sandbar") then
		assert(part.TopSurface == Enum.SurfaceType.Studs and part.Material == Enum.Material.Plastic, part.Name)
	elseif part:IsA("WedgePart") and (part.Name == "Distant grass" or part.Name == "Distant sandbar") then
		assert(
			(if part.CFrame.RightVector.Y > 0 then part.RightSurface else part.LeftSurface) == Enum.SurfaceType.Studs,
			part.Name
		)
	end
end
local paving = {}
for _, part in mapCopy["Sand path and bridge"]:GetChildren() do
	if part.Name == "Market square" then
		table.insert(paving, part)
	end
end
local onPaving = RaycastParams.new()
onPaving.FilterType, onPaving.FilterDescendantsInstances = Enum.RaycastFilterType.Include, paving
local sellMat, shopMat = site.stations.Sell.Parent, site.stations.Shop.Parent
assert(math.abs(sellMat.Position.X + shopMat.Position.X - 2 * world.origin.X) < 0.01)
assert((sellMat.Position - shopMat.Position) * Vector3.new(0, 1, 1) == Vector3.zero)
for _, name in { "Sell", "Shop" } do
	local prompt = site.stations[name]
	local pad = prompt.Parent.Position - world.origin
	assert(floorAt(pad.X, pad.Z) and math.abs(pad.Z - 15) < prompt.MaxActivationDistance)
	local half = prompt.Parent.Size / 2
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			local corner = prompt.Parent.CFrame:PointToWorldSpace(Vector3.new(x * (half.X + 1.25), 3, z * (half.Z + 0.6)))
			assert(workspace:Raycast(corner, -Vector3.yAxis * 6, onPaving), name .. " on paving edge")
		end
	end
end
assert(not mapCopy["Harbor Plaza"]:FindFirstChild("Marquee"))
for _, name in { "Jobs", "Book", "Store", "Supplies" } do
	local pad = site.stations[name].Parent.Position - world.origin
	assert(floorAt(pad.X, pad.Z), name)
end
local function groundBelow(position)
	return workspace:Raycast(position + Vector3.yAxis * 1.5, -Vector3.yAxis * 3, onMap)
end
-- Every service stands clear: its pad is level with the ground in front, nothing hangs over
-- it at head height, and a miner can walk up to it from spawn.
for key, prompt in site.stations do
	local mat = prompt.Parent
	for _, dx in { -2.5, 0, 2.5 } do
		for _, dz in { 0, 3, 6 } do
			local at = mat.CFrame:PointToWorldSpace(Vector3.new(dx, 0, dz))
			local ground = groundBelow(at + Vector3.yAxis * 0.5)
			assert(ground and math.abs(ground.Position.Y - mat.Position.Y) < 0.8, key .. " pad is not level with its approach")
			assert(not workspace:Raycast(at + Vector3.yAxis * 0.8, Vector3.yAxis * 5, onMap), key .. " approach is blocked")
		end
	end
	local toward = (site.spawn.Position - mat.Position) * Vector3.new(1, 0, 1)
	if key ~= "Sell" and key ~= "Shop" then
		assert(mat.CFrame.ZVector:Dot(toward.Unit) > 0.75, key .. " turns its back on spawn")
		assert(toward.Magnitude < 60, key .. " is a long walk")
	end
	assert(mat.Parent:FindFirstChild("Shop sign") and mat.Parent["Shop sign"].Lettering:FindFirstChildOfClass("TextLabel"), key .. " has no sign")
end
for _, key in { "Server", "Global" } do
	local panel = site.court[key].Standings
	assert(panel.Position.Z > site.spawn.Position.Z + 20)
	assert(panel.Lettering.Row5:IsA("TextLabel"))
end
local ranks = require(Server.Standings).top({
	[8] = { name = "Later", score = 40 },
	[1] = { name = "Earlier", score = 40 },
	[3] = { name = "Deep", score = 90 },
})
assert(#ranks == 3 and ranks[1]:find("Deep") and ranks[2]:find("Earlier"))
for _, key in { "Sell", "Shop" } do
	local group = site.stations[key].Parent.Parent
	assert(group["Name tag"]:FindFirstChildOfClass("BillboardGui") and group:FindFirstChildWhichIsA("PointLight", true))
end
for _, key in { "Jobs", "Store", "Book", "Supplies" } do
	local stall = site.stations[key].Parent.Parent
	assert(stall:FindFirstChildWhichIsA("BillboardGui", true) and stall:FindFirstChildWhichIsA("PointLight", true))
end
local back = highlands["Cableway trail"]
do
	local relay = require(game.StarterPlayer.StarterPlayerScripts.Client.Tramway)
	local tram = highlands["Ridge tramway"]
	for lane = 1, 3 do
		local car = highlands["Moving cabins"]["Ore carrier " .. lane]
		assert(car.ModelStreamingMode == Enum.ModelStreamingMode.Atomic, "bucket and its cargo must stream together")
		local w, e = car["West terminal"].Value, car["East terminal"].Value
		local receive, angle, drop, loaded = relay.sample(w, e, 0.55)
		local feed, _, _, filled = relay.sample(w, e, 0.115)
		local empty, _, _, returning = relay.sample(w, e, 0.80)
		assert(loaded and filled and not returning and angle > 0.7 and drop.Y < -3.45
			and receive.X < empty.X and empty.X < feed.X, "ore must travel west, tip and return empty")
		local ready, bin = false, false
		for _, item in tram:GetChildren() do
			if item.Name == "Receiving hopper floor" then
				bin = bin or (item.Position - (world.origin + receive + Vector3.new(-1, -8.89, 0))).Magnitude < 0.02
			elseif item.Name == "Ore feed spout" then
				local endA = item.Position + item.CFrame.LookVector*item.Size.Z/2
				local endB = item.Position - item.CFrame.LookVector*item.Size.Z/2
				local fillPoint = world.origin + feed - Vector3.yAxis*1.35
				ready = ready or math.min((endA - fillPoint).Magnitude, (endB - fillPoint).Magnitude) < 0.02
			end
		end
		assert(bin and ready, "both ends of each cable need a physical transfer point")
	end
end
-- The falls land in water, and no mesa stands in the tram's way.
do
	local falls = mapCopy["Highland falls"]
	local pool = falls:FindFirstChild("Plunge pool")
	local foot = math.huge
	for _, part in falls:GetChildren() do
		if part.Name == "Falling water" then foot = math.min(foot, part.Position.Y - part.Size.Y / 2) end
	end
	assert(pool and math.abs(foot - pool.Position.Y) < 2.5, "the falls miss their pool")
	local ropes = OverlapParams.new()
	ropes.FilterType, ropes.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { mapCopy["Honey bluffs"], highlands["Northern mesas"], highlands["Ridge dressing"] }
	for lane = 1, 3 do
		local car = highlands["Moving cabins"]["Ore carrier " .. lane]
		local relay = require(game.StarterPlayer.StarterPlayerScripts.Client.Tramway)
		for phase = 0, 1, 0.02 do
			local hook = relay.sample(car["West terminal"].Value, car["East terminal"].Value, phase)
			local hit = workspace:GetPartBoundsInBox(CFrame.new(world.origin + hook - Vector3.yAxis * 4), Vector3.new(7, 10, 6), ropes)
			assert(not hit[1], "ore carrier meets " .. (hit[1] and hit[1].Name or ""))
		end
	end
end
local groundParams = RaycastParams.new()
groundParams.FilterType, groundParams.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { back }
for _, pos in { Vector2.new(-89, -57), Vector2.new(-29, -65), Vector2.new(35, -63), Vector2.new(91, -53) } do
	local foot = workspace:Raycast(world.origin + Vector3.new(pos.X, 13, pos.Y), -Vector3.yAxis * 2, groundParams)
	assert(foot and foot.Instance.Name == "Tower footing", "Unsupported tram tower")
end
for _, side in { -1, 1 } do
	local path = {
		Vector2.new(116, 7),
		Vector2.new(116, -38),
		Vector2.new(105, -50),
		Vector2.new(83, -65),
		Vector2.new(73, -73),
		Vector2.new(0, -73),
	}
	local prev
	for i = 2, #path do
		local steps = math.ceil((path[i] - path[i - 1]).Magnitude)
		for t = 0, steps do
			local at = path[i - 1]:Lerp(path[i], t / steps)
			local height = math.min(11.95, -0.05 + (9 - at.Y) * 12 / 62)
			local feet = world.origin + Vector3.new(side * at.X, height, at.Y)
			local hit = workspace:Raycast(feet + Vector3.yAxis * 2, -Vector3.yAxis * 4, onMap)
			assert(hit and (not prev or math.abs(hit.Position.Y - prev) < 0.8), "Ridge trail gap at " .. tostring(at))
			assert(
				not workspace:Raycast(feet + Vector3.yAxis * 0.9, Vector3.yAxis * 6, onMap),
				"Ridge trail clearance at " .. tostring(at)
			)
			prev = hit.Position.Y
		end
	end
end
print("PASS harbor paths, 360 rock rim rays, lit service pads, bridge crossing and edit-face removal")
local terrainCells = workspace.Terrain:CountCells()
world:generate()
assert(not surface:FindFirstChild("EditFace"))
mapCopy.EditFace:Destroy()
local grid = world.grid
local count = #grid.folder:GetChildren()
assert(count == 100, "Starting shell parts: " .. count)
do
	local before = table.clone(grid.chunks)
	local centerCell = Vector3.new(-8, -40, 8)
	local hits = grid:scanOres(centerCell)
	local found = {}
	for i = 0, buffer.len(hits) - 1, 4 do
		local offset = Vector3.new(buffer.readi8(hits, i), buffer.readi8(hits, i + 1), buffer.readi8(hits, i + 2))
		assert(offset.Magnitude <= 10 and not found[offset])
		found[offset] = Ores.list[buffer.readu8(hits, i + 3)]
	end
	local edgeOre
	for x = -10, 10 do
		for y = -10, 10 do
			for z = -10, 10 do
				local offset = Vector3.new(x, y, z)
				if offset.Magnitude <= 10 then
					local ore = grid:oreAt(centerCell + offset)
					assert(found[offset] == (if ore and not ore.host then ore else nil), "Incomplete X-ray")
					if found[offset] and offset.Magnitude == 10 then edgeOre = true end
				end
			end
		end
	end
	assert(edgeOre and buffer.len(grid:scanOres(Vector3.yAxis * 10)) == 0)
	for key, chunk in grid.chunks do assert(before[key] == chunk, "Scanning allocated a mine chunk") end
	assert(#grid.folder:GetChildren() == count and world.removed == 0, "Scanning exposed or mined rock")
	print("PASS ten-block X-ray reads buried geology across chunks without spawning blocks")
end
do
	local Blocks = require(Server.MineBlocks)
	local scanned = Blocks.new(Vector3.zero, game.ServerStorage)
	local control = Blocks.new(Vector3.zero, game.ServerStorage)
	for _, mine in {scanned, control} do
		mine:reset(74109)
		mine:openHall()
	end
	for y = -1, -12, -1 do
		local cell = Vector3.new(0, y, -3)
		scanned:scanOres(cell)
		local original = control:take(cell)
		assert(original and scanned:take(cell) == original, "Scanning changed the mined material")
	end
	local parts = scanned.folder:GetChildren()
	assert(#parts == #control.folder:GetChildren(), "Scanning changed the number of exposed blocks")
	for _, part in parts do
		local chunk, index = control:slot(control:cellAt(part.Position), false)
		local other = chunk and chunk[index]
		assert(other and other.Name == part.Name and other:GetAttribute("OpenFaces") == part:GetAttribute("OpenFaces"))
	end
	scanned.folder:Destroy()
	control.folder:Destroy()
	print("PASS scanned and unscanned mines yield identical blocks, ore and exposed faces")
end
local function center(x, y, z)
	return grid:center(Vector3.new(x, y, z))
end
local function entry(x, y, z)
	local chunk, i = grid:slot(Vector3.new(x, y, z), false)
	return chunk and chunk[i]
end
local function cut(x, y, z)
	local target = center(x, y, z)
	local original = world:oreAt(target)
	assert(original and entry(x, y, z), "Unexposed target " .. tostring(target))
	local loot = world:excavate({ target })
	assert(loot[original.name] == 1 and world:oreAt(target) == nil)
	return original.name
end
onMap.FilterDescendantsInstances = { mapCopy, grid.folder }
for x = -5, 4 do
	for z = -11, -2 do
		local at = center(x, -1, z)
		assert(
			not workspace:Raycast(at + Vector3.yAxis * (Config.Cell / 2 + 0.3), Vector3.yAxis * 8, onMap),
			"Blocked mining floor"
		)
		local hit = workspace:Raycast(at + Vector3.yAxis * 6, -Vector3.yAxis * 7, onMap)
		assert(
			hit
				and hit.Instance == entry(x, -1, z)
				and hit.Instance.Size == Vector3.one * 6
				and hit.Instance.Name == "Dirt"
				and math.abs(hit.Position.Y - world.origin.Y) < 0.01,
			"Floor cut must be reachable"
		)
	end
end
assert(not entry(0, -25, -700) and not entry(0, -6, -8))
for y = -1, -6, -1 do
	if entry(0, y, -5) then
		cut(0, y, -5)
	end
end
assert(not grid:take(Vector3.new(0, -1, -12)), "Surface foundation must remain closed")
for y = -1, -3, -1 do
	cut(1, y, -5)
end
for z = -6, -9, -1 do
	if entry(0, -6, z) then
		cut(0, -6, z)
	end
end
assert(entry(0, -6, -8) == false, "Starter tunnel remained closed")
local distantAir = 0
for z = -8, -36, -1 do
	for x = -6, 6 do
		if entry(x, -6, z) == false then
			distantAir += 1
			break
		end
	end
end
assert(distantAir >= 24, "Cave tunnel did not extend around its bends")
for z = -6, -142, -1 do
	cut(1, -3, z)
end
for x = 2, 58 do
	cut(x, -3, -142)
end
assert(not entry(1000, -3, -1300))
local target = center(58, -3, -143)
local Mining = require(Server.MiningService)
local rig = Instance.new("Model")
local human = Instance.new("Humanoid")
human.Parent = rig
local head = Instance.new("Part")
head.Name, head.Size, head.Anchored, head.Position, head.Parent =
	"Head", Vector3.one, true, center(58, -3, -142) + Vector3.zAxis, rig
rig.Parent = workspace
assert(Mining.target(world, rig, target, Vector3.zAxis))
assert(not Mining.target(world, rig, target, Vector3.yAxis), "Covered top was selectable")
-- Expose the target's top while keeping the miner in the tunnel one cell below.
grid:expose(grid:cellAt(target) + Vector3.yAxis, Enum.NormalId.Bottom.Value, {})
local overhead = grid:cellAt(target) + Vector3.yAxis
local capChunk, capIndex = grid:slot(overhead, false)
if capChunk[capIndex] then
	-- Outside the dirt opening this shallow layer is the island foundation.
	-- Stand beside an equivalent exposed ledge rather than cutting foundation.
	local cap = capChunk[capIndex]
	cap:Destroy()
	capChunk[capIndex] = false
	grid:openNeighbours({ overhead })
end
assert(Mining.target(world, rig, target, Vector3.yAxis), "Visible top from camera above a ledge, miner below")
rig:SetAttribute("PickReach", 1)
assert(not Mining.target(world, rig, target, Vector3.yAxis), "Overhead aim exceeded pick reach")
rig:SetAttribute("PickReach", nil)
assert(not Mining.target(world, rig, target, -Vector3.zAxis) and not Mining.target(world, rig, target, Vector3.one))
local post = Instance.new("Part")
post.Anchored, post.Size, post.Position, post.Parent =
	true, Vector3.one * 0.65, center(58, -3, -142) - Vector3.zAxis * 0.4, workspace
assert(not Mining.target(world, rig, target, Vector3.zAxis))
assert(not Mining.target(world, rig, target, Vector3.yAxis), "Overhead aim passed through a wall")
post:Destroy()
assert(#Mining.selection(world, rig, target, Vector3.zAxis, 1, 0) == 0)
assert(#Mining.selection(world, rig, target, Vector3.zAxis, 6, 1) == 1)
local root = head:Clone()
root.Name, root.CanCollide, root.Parent = "HumanoidRootPart", false, rig
local flare = require(Server.SurveyFlare)
assert(flare.place(world, rig), "flare casts inside a mined tunnel")
local beacon = world.flares:FindFirstChild("Survey flare")
assert(beacon and beacon:FindFirstChildOfClass("PointLight") and not beacon.CanQuery)
assert(Mining.target(world, rig, target, Vector3.zAxis), "flare must leave the workface selectable")
local expected = world:oreAt(target).name
assert(world:excavate({ target })[expected] == 1 and not next((world:excavate({ target }))))
rig:Destroy()
for _, ore in Ores.list do
	local hard = center(0, -61, 0)
	local selected, locked, required = Pattern.select(world.origin, hard, ore, 1, 1)
	assert(#selected == 0 and locked == ore and required >= 3)
	assert(Ores.cutTime(0.8, ore, 3) > Ores.cutTime(0.8, ore, 1))
end
assert(workspace.Terrain:CountCells() == terrainCells)
local old = world.generation
world.seed = 90237
world:generate()
assert(#world.flares:GetChildren() == 0, "reset clears old survey flares")
assert(#grid.folder:GetChildren() == 100, "Field reset lost part of the hut floor")
assert(world.generation == old + 1 and world.removed == 0 and world:oreAt(center(-1, -1, -5)).name == "Dirt")
assert(not entry(58, -3, -142) and not entry(2, -7, -44))
for x = -5, 4 do
	for z = -11, -2 do
		assert(cut(x, -1, z) == "Dirt")
		local top = center(x, -1, z) + Vector3.yAxis * Config.Cell
		local hit = workspace:Raycast(top, -Vector3.yAxis * (2 * Config.Cell), onMap)
		assert(hit and hit.Instance == entry(x, -2, z), "Fixed scenery obstructs the second layer")
		local second = cut(x, -2, z)
		assert(second and second ~= "Dirt" and world:oreAt(center(x, -3, z)).name ~= "Dirt")
	end
end
print(
	"PASS winding cave discovery, narrow entrance, clearance, depth gates, distant chunk cuts, shared depletion and reset"
)
local starter = Vector3.new(-5, -1, -2)
grid:refreshStarter(math.huge, { grid:center(starter) })
assert(entry(-5, -1, -2) == false, "Replenished underneath a miner")
grid:refreshStarter(math.huge, {})
assert(entry(-5, -1, -2).Name == "Dirt" and entry(4, -1, -2) == false, "Starter refill affected other tunnels")
world:generate()
local now = os.clock() + 80
local miner = { center(-5, -5, -2) }
for y = -1, -5, -1 do
	cut(-5, y, -2)
end
grid:refreshStarter(now, miner)
assert(entry(-5, -1, -2) == false, "Starter refill sealed the only exit")
cut(-5, -2, -3)
cut(-5, -2, -4)
cut(-5, -1, -4)
grid:refreshStarter(now + 6, miner)
assert(entry(-5, -1, -2).Name == "Dirt" and entry(-5, -1, -4) == false, "Connected alternate exit should allow refill")
local spill = Profile.new()
spill.bag, spill.gold = { Dirt = 8, Coal = 11, Starfall = 1 }, 99
assert(Profile.spill(spill) == 2 and spill.bag.Dirt == 6 and spill.bag.Starfall == 1 and spill.gold == 99)
spill.bag = { Starfall = 1 }
assert(Profile.spill(spill) == 0)
spill.drake, spill.pet = true, "Drake"
local savedDrake = Data.commit({ owner = "hatcher" }, "hatcher", Data.snapshot(spill), 50, true)
local returningMiner = assert(Data.claim(savedDrake, "next-server", 51)).profile
assert(returningMiner.drake and returningMiner.pet == "Drake", "Hatched and equipped drake must survive rejoining")
local landmarks = {}
local geo = Geology.new(73129)
for row = 3, 500 do
	if landmarks.Egg and landmarks.Cache and landmarks.Lava then
		break
	end
	for x = -8, 28 do
		for z = -38, 38 do
			local p = Vector3.new(x, -1 - row, z)
			local feature = geo:feature(p)
			if feature then
				landmarks[feature] = p
			end
		end
	end
end
local features = require(Server.CaveDetails)
for _, kind in { "Cache", "Lava", "Egg" } do
	local cell = assert(landmarks[kind], kind .. " must occur in a natural cave")
	assert(geo:isCave(cell) and not geo:isCave(cell - Vector3.yAxis))
	local support = Instance.new("Part")
	features.place(grid, support, kind)
	local item = support:GetChildren()[1]
	assert(item and not item.CanQuery and item:FindFirstChildOfClass("PointLight"))
	if kind == "Lava" then
		assert(item.CanTouch and cell.Y < -90, "Lava requires contact in a deep passage")
	else
		local prompt = item:FindFirstChildOfClass("ProximityPrompt")
		assert(prompt and prompt.ActionText == (if kind == "Egg" then "Hatch" else "Open"))
	end
	support:Destroy()
end
do
	local Lighting = game:GetService("Lighting")
	local Tunnel = require(game.StarterPlayer.StarterPlayerScripts.Client.TunnelVisibility)
	local air = assert(Lighting:FindFirstChildOfClass("Atmosphere"))
	local color, first, last = Lighting.FogColor, Lighting.FogStart, Lighting.FogEnd
	local visibility = Tunnel.new()
	visibility:update(30, 0, 25, 34)
	local deepEnd = Lighting.FogEnd
	assert(not Lighting:FindFirstChildOfClass("Atmosphere") and Lighting.FogStart == 20 and deepEnd == 49)
	visibility:update(2, 0, 25, 34)
	assert(Lighting.FogEnd > deepEnd * 5, "daylight reaches the mouth of the shaft")
	visibility:update(30, 12, 49, 54)
	assert(Lighting.FogEnd == 85 and Lighting.FogStart > 49, "longer lamp and third-person camera move the falloff")
	visibility:update(0, 0, 25, 34)
	assert(air.Parent == Lighting and Lighting.FogColor == color and Lighting.FogStart == first and Lighting.FogEnd == last)
	print("PASS tunnel sight follows lamp range, depth, camera offset and restores coastal atmosphere")
end
print("MINING_TESTS_PASSED")
