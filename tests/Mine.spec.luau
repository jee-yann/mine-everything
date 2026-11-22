-- Studio CLI RunScript test. Run in the local build. All changes are in memory.
local Server = game:GetService("ServerScriptService").Server
local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Geology, World = require(Server.Geology), require(Server.MineWorld)
local Pattern = require(Shared.BlockPattern)
local Profile = require(Server.Profile)
assert(Profile.valid(Profile.new()))
local Data = require(Server.DataService)
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
	assert(starter.gold == 0 and Upgrades.price("Capacity", 2) == 60 and Profile.expeditionStep(starter) == "Return")
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
		assert(Upgrades.items.Capacity.values[level] == level * 8)
		assert(Profile.stat(loaded, "Capacity") == skills.capacity(level * 8, veteran.skills))
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
	assert(Profile.stat(miner, "Speed") == 0.20 and Profile.stat(miner, "Power") == 6 and Profile.stat(miner, "Capacity") == 64)
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
haul.gold = 36
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
assert(hiddenTitle == "??? Collector" and hiddenDetail == "Mine 50 ???.")
reader:SetAttribute("FoundDirt", true)
local _, sequenceText = Guide.awardText(scales, reader)
assert(sequenceText == "Dirt → ??? → ??? → ??? → ??? → ??? → ???")
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
for row = 1, 2 do
	for x = -5, 4 do
		for z = -11, -2 do
			assert(top:material(Vector3.new(x, -row, z)) == Ores.byName.Dirt.material)
		end
	end
	assert(not Ores.byMaterial[top:material(Vector3.new(5, -row, -3))])
end
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
print("PASS two dirt layers, independent regional odds, repeatable fields and saved title levels")
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
	head:Destroy()
	guide.anchor:Destroy()
end
local world = World.new(Config.LandscapeSeed, surface)
local mapCopy = surface:Clone()
local coast = mapCopy.TideCoast
local datum = mapCopy["Sand path and bridge"]["Portal paving"]
assert((coast:GetPivot().Position - (datum.Position + Vector3.yAxis * datum.Size.Y / 2)).Magnitude < 0.02)
assert(#coast:GetDescendants() == #Shared.TideCoast:GetDescendants())
assert(mapCopy["Offshore water"].ModelStreamingMode == Enum.ModelStreamingMode.Persistent)
for _, scenery in { coast, mapCopy["Offshore water"] } do
	for _, part in scenery:GetDescendants() do
		if part:IsA("BasePart") then
			assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,
				"offshore scenery interferes with mining or movement")
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
	local drawings = game:GetService("StarterPlayer").StarterPlayerScripts.Client.OreDrawings
	local http, encoding = game:GetService("HttpService"), game:GetService("EncodingService")
	for _, value in drawings:GetChildren() do
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
		local support = workspace:Raycast(cap.Position, -Vector3.yAxis * 1.3, stoneRay)
		assert(support, "Unsupported sandstone cap at " .. tostring(point))
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
for _, name in { "Exchange lights", "Workshop lights" } do
	local lamps = highlands[name]
	assert(
		lamps:FindFirstChildWhichIsA("PointLight", true) and lamps:FindFirstChildWhichIsA("SurfaceLight", true),
		name
	)
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
for _, ore in Ores.list do
	if ore.secret then
		continue
	end
	assert(exhibit:FindFirstChild(ore.name .. " sample") and exhibit:FindFirstChild(ore.name .. " label"))
end
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
	for _, part in { prompt.Parent, prompt.Parent.Parent.Deck } do
		local half = part.Size / 2
		for _, x in { -1, 1 } do
			for _, z in { -1, 1 } do
				local corner = part.CFrame:PointToWorldSpace(Vector3.new(x * (half.X + 1.25), 3, z * (half.Z + 1.25)))
				assert(workspace:Raycast(corner, -Vector3.yAxis * 6, onPaving), name .. " on paving edge")
			end
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
local crossings = highlands["Outer meadows"]
for _, key in { "Supplies", "Book" } do
	local mat = site.stations[key].Parent
	local counter = if key == "Supplies" then mat.Parent["Merch top"] else mat.Parent["Display plinth"]
	assert(math.abs(mat.Position.X - counter.Position.X) < 0.01)
	assert(mat.Position.Z - mat.Size.Z / 2 > counter.Position.Z + counter.Size.Z / 2, key .. " pad behind counter")
	local foundBridge = false
	for _, bridge in crossings:GetDescendants() do
		if bridge.Name ~= "Timber deck" or math.abs(bridge.Position.X - mat.Position.X) > 10 then
			continue
		end
		foundBridge = true
		local endZ = bridge.Position.Z - bridge.Size.Z / 2
		assert(endZ - (mat.Position.Z + mat.Size.Z / 2) >= 1.5, key .. " pad crowds bridge")
		for _, dx in { -2.8, 0, 2.8 } do
			local joint = Vector3.new(bridge.Position.X + dx, bridge.Position.Y, endZ)
			assert(groundBelow(joint - Vector3.zAxis * 0.1).Instance.Name == "Wharf deck")
			assert(groundBelow(joint + Vector3.zAxis * 0.1).Instance == bridge)
		end
	end
	assert(foundBridge, key .. " has no bridge landing")
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
for _, pair in { { "Sell", "Exchange lights" }, { "Shop", "Workshop lights" } } do
	local group = site.stations[pair[1]].Parent.Parent
	assert(group["Name tag"]:FindFirstChildOfClass("BillboardGui"))
	assert(highlands[pair[2]]:FindFirstChildWhichIsA("PointLight", true).Brightness < 0.5)
end
for _, key in { "Jobs", "Store", "Book", "Supplies" } do
	local stall = site.stations[key].Parent.Parent
	assert(stall:FindFirstChildWhichIsA("BillboardGui", true) and stall:FindFirstChildWhichIsA("PointLight", true))
end
local back = highlands["Cableway trail"]
local obstructions = { mapCopy["Honey bluffs"], highlands["Ridge tramway"] }
for _, piece in back:GetChildren() do
	if piece.Name == "Tower footing" then
		table.insert(obstructions, piece)
	end
end
local terraceCheck = OverlapParams.new()
terraceCheck.FilterType, terraceCheck.FilterDescendantsInstances = Enum.RaycastFilterType.Include, obstructions
for _, piece in highlands["Turquoise cascade"]:GetChildren() do
	if piece.Name == "Meadow cap" then
		assert(piece.Color == Color3.fromRGB(116, 212, 79), "Waterfall turf palette")
	end
	if piece.Name == "Meadow cap" or piece.Name == "Mesa face" then
		assert(#workspace:GetPartsInPart(piece, terraceCheck) == 0, "Waterfall intersects a hill or tower")
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
		assert(cut(x, -2, z) == "Dirt" and world:oreAt(center(x, -3, z)).name ~= "Dirt")
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
print("MINING_TESTS_PASSED")
