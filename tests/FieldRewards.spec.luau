-- Studio RunScript. All save, character and gallery fixtures are local to this place.
local Shared = game.ReplicatedStorage.Shared
local Server = game.ServerScriptService.Server
local Client = game.StarterPlayer.StarterPlayerScripts.Client
local Field, Materials = require(Shared.FieldRewards), require(Shared.Materials)
local Profile, Data = require(Server.Profile), require(Server.DataService)
local Compass, Podiums = require(Client.PetCompass), require(Client.Podiums)
local Pulse = require(Server.MinePulse)
local Config = require(Shared.GameConfig)

local legacy = Profile.new()
for _, key in { "gems", "stampDay", "stampCount", "shiftDay", "shiftSeconds", "shiftClaims", "giftDay", "giftSeconds", "giftClaims", "hasteCuts", "stoneChips", "pulses" } do legacy[key] = nil end
local p = assert(Data.claim({profile = legacy}, "new session", 1000)).profile
assert(p.gems == 0 and p.hasteCuts == 0 and not Profile.hasUpgrade(p))
assert(#Field.daily == 7, "a week of daily rewards")
for day, reward in Field.daily do
	local today = (20000 + 3 * day) * 86400
	local before = { gold = p.gold, gems = p.gems, flares = p.flares, pulses = p.pulses }
	local ready, done = Field.dailyState(p.stampCount, p.stampAt, today)
	assert(ready == day and done == day - 1)
	local number, given = Field.claim(p, today)
	assert(number == day and given == reward and Field.describe(reward) ~= "")
	for key, amount in before do
		assert(p[key] == amount + (reward[key] or 0), key .. " on day " .. day)
	end
	assert(not Field.claim(p, today) and not Field.claim(p, today - 1) and not Field.claim(p, today + Field.cooldown - 1))
	assert(not Field.dailyState(p.stampCount, p.stampAt, today))
end
assert(Field.claim(p, 20100 * 86400) == 1, "the card starts again after day 7")
-- 18 hours after a claim, not the next UTC day: an earlier visit the next day still gets its reward.
local evening = 20200 * 86400 + 22 * 3600
assert(Field.claim(p, evening) == 2)
local _, _, wait = Field.dailyState(p.stampCount, p.stampAt, evening + 3600)
assert(wait == Field.cooldown - 3600 and not Field.claim(p, 20201 * 86400 + 3600 * 15))
assert(Field.claim(p, evening + Field.cooldown) == 3, "the next morning")
p.gold, p.gems, p.flares, p.pulses = 0, 37, 0, 0
assert(not Profile.buySupply(p, "Haste") and p.gems == 37)
p.bag = { Stone = 2, Coal = 3, Iron = 3, Copper = 5 }
assert(Profile.buySupply(p, "Haste") and p.hasteCuts == 12 and not Profile.buySupply(p, "Haste"))
assert(Profile.buySupply(p, "Compass") and p.oreCompass and not Profile.buySupply(p, "Compass"))
p.gems = 2
assert(not Profile.buySupply(p, "Pulse") and p.bag.Copper == 2 and p.gems == 2)
p.gems = 11
assert(Profile.buySupply(p, "Chips") and p.stoneChips == 6 and p.gems == 3)
assert(Profile.buySupply(p, "Pulse") and p.pulses == 1 and p.gems == 0 and not next(p.bag))
p.gold = 8
assert(Profile.buy(p, "Capacity") and Profile.hasUpgrade(p))
p.auraOff = true
local day = 20101
p.bag = table.clone(Materials.daily(day).recipe)
assert(Profile.deliver(p, day, day) and p.gems == 2 and not Profile.deliver(p, day, day))
local snapshot = Data.snapshot(p)
local restored = assert(Data.claim({ profile = snapshot }, "later", 2000)).profile
for _, key in { "gems", "stampCount", "stampDay", "stampAt", "oreCompass", "pulses", "hasteCuts", "stoneChips", "auraOff" } do
	assert(p[key] == restored[key], key)
end
assert(Profile.hasUpgrade(restored))
snapshot.stampCount = 8
assert(not Profile.valid(snapshot))
print("PASS gem card rollover, missed days, duplicate claims, recipes, saved charges, first-upgrade aura")

-- Gifts at 5 and 10 minutes, then every 10 minutes, the last at an hour.
assert(Field.gifts[1].minutes == 5 and Field.gifts[2].minutes == 10)
for i = 3, #Field.gifts do assert(Field.gifts[i].minutes == Field.gifts[i - 1].minutes + 10) end
assert(Field.gifts[#Field.gifts].minutes == 60 and Field.maxGiftTime == 3600)
local visit = { profile = p }
local start = 20101 * 86400
Field.trackGifts(visit, start)
Field.trackGifts(visit, start + 299)
Field.trackGifts(visit, start + 299)
assert(p.giftSeconds == 299 and not Field.claimGift(visit, start + 299, 1))
local saved = Data.snapshot(p)
local returnVisit = { profile = assert(Data.claim({ profile = saved }, "return", start + 2000)).profile }
local resumed = returnVisit.profile
Field.trackGifts(returnVisit, start + 2000)
assert(resumed.giftSeconds == 299 and not Field.claimGift(returnVisit, start + 2000, 1), "time away does not count")
assert(not Field.claimGift(returnVisit, start + 2001, 2) and not Field.claimGift(returnVisit, start + 2001, 0) and not Field.claimGift(returnVisit, start + 2001, "1"))
local gold = resumed.gold
local given = Field.claimGift(returnVisit, start + 2001, 1)
assert(given and #given == 1 and resumed.gold == gold + Field.gifts[1].reward.gold)
assert(not Field.claimGift(returnVisit, start + 2001, 1), "a gift was given twice")
-- Claiming a later gift collects the ones before it.
local all = Field.claimGift(returnVisit, start + 12000, #Field.gifts)
assert(all and #all == #Field.gifts - 1 and resumed.giftClaims == #Field.gifts)
assert(resumed.giftSeconds == Field.maxGiftTime and not Field.claimGift(returnVisit, start + 12000, #Field.gifts) and not Field.claimGift(returnVisit, start + 12000, #Field.gifts + 1))
local sameDay = { profile = assert(Data.claim({ profile = Data.snapshot(resumed) }, "third", start + 22000)).profile }
assert(not Field.claimGift(sameDay, start + 22000, 1))
Field.trackGifts(sameDay, start + 86400 + 9)
assert(sameDay.profile.giftClaims == 0 and sameDay.profile.giftSeconds == 0 and sameDay.profile.giftStart == start + 86400 + 9)
assert(not Field.claimGift(sameDay, start + 86400 + 9, 1))
local followingDay = { profile = sameDay.profile }
Field.trackGifts(followingDay, start + 3 * 86400 + 16000)
assert(sameDay.profile.giftSeconds == 0 and sameDay.profile.giftClaims == 0)
-- A round of gifts lasts 18 hours from when it began.
local round = { profile = sameDay.profile }
local begun = sameDay.profile.giftStart
Field.trackGifts(round, begun)
Field.trackGifts(round, begun + 600)
assert(round.profile.giftSeconds == 600 and Field.claimGift(round, begun + 600, 2))
Field.trackGifts(round, begun + Field.cooldown - 1)
assert(round.profile.giftClaims == 2, "a round ended early")
Field.trackGifts(round, begun + Field.cooldown)
assert(round.profile.giftClaims == 0 and round.profile.giftStart == begun + Field.cooldown)
-- Saves from UTC days wait from that day's midnight.
local dated = Data.snapshot(round.profile)
dated.stampAt, dated.giftStart, dated.stampDay, dated.giftDay = nil, nil, 20300, 20301
local moved = assert(Data.claim({ profile = dated }, "dated", start)).profile
assert(moved.stampAt == 20300 * 86400 and moved.giftStart == 20301 * 86400)
-- A save from the old timed rewards still loads.
local older = Data.snapshot(sameDay.profile)
older.shiftClaims, older.shiftSeconds, older.giftDay, older.giftSeconds, older.giftClaims = 3, 3600, nil, nil, nil
assert(Profile.valid(older) and assert(Data.claim({ profile = older }, "older", start)).profile.giftClaims == 0)
older.giftClaims = -1
assert(not Profile.valid(older))
-- What the client shows from the two attributes.
local miner = { GetAttribute = function(_, key) return ({ GiftClock = 1000, GiftClaims = 1 })[key] end }
local ready, left = Field.giftState(miner, 1000 + 630)
assert(ready == 1 and left == 570 and Field.played(miner, 1000 + 630) == 630)
ready, left = Field.giftState(miner, 1000 + 99999)
assert(ready == #Field.gifts - 1 and left == nil)
-- The card opens by itself only at a calm moment, and once.
local auto = require(Client.AutoRewards)
local function state(change)
	local s = { onboarded = true, sinceReady = 9, quietFor = 3, dailyReady = true, giftsReady = 0, giftsClaimed = 0, underground = false }
	for key, value in change do s[key] = value end
	return s
end
assert(auto.choose(state({})) == "Daily")
for _, change in { { onboarded = false }, { sinceReady = 1 }, { quietFor = 0 }, { dailyShown = true }, { underground = true }, { dailyReady = false } } do
	assert(auto.choose(state(change)) == nil)
end
assert(auto.choose(state({ dailyReady = false, giftsReady = 1 })) == "Playtime")
-- On a first visit it waits for the sale after the first expedition, then two seconds.
assert(auto.choose(state({ firstVisit = true })) == nil)
assert(auto.choose(state({ firstVisit = true, sinceSale = 1.9 })) == nil)
assert(auto.choose(state({ firstVisit = true, sinceSale = 2, quietFor = 0 })) == nil, "it waits for the gold to land")
assert(auto.choose(state({ firstVisit = true, sinceSale = 2.1, quietFor = 0.25, sinceReady = 2 })) == "Daily")
assert(auto.choose(state({ firstVisit = true, dailyReady = false, giftsReady = 1 })) == "Playtime")
assert(auto.choose(state({ dailyReady = false, giftsReady = 1, giftsClaimed = 1 })) == nil, "only the first gift opens the card")
assert(auto.choose(state({ dailyReady = false, giftsReady = 1, giftShown = true })) == nil)
-- The skill guide starts at level 3 and only for someone who has never spent a point.
local wanted = require(Client.SkillGuide).wanted
assert(wanted({ onboarded = true, level = 3, points = 2, owned = 0 }))
for _, s in { { onboarded = false, level = 3, points = 2, owned = 0 }, { onboarded = true, level = 2, points = 1, owned = 0 },
	{ onboarded = true, level = 9, points = 0, owned = 0 }, { onboarded = true, level = 9, points = 4, owned = 1 } } do
	assert(not wanted(s))
end
-- The invite reminder waits for a while of mining, prefers a level, and stops.
local due = require(Client.InviteHint).due
local function hint(change)
	local s = { friends = 0, onboarded = true, shown = 0, mined = 300, sinceLevel = 3, busy = false }
	for key, value in change do s[key] = value end
	return due(s)
end
assert(hint({}) and hint({ mined = 400, sinceLevel = 900 }))
for _, change in { { friends = 1 }, { invited = true }, { onboarded = false }, { shown = 3 }, { mined = 100 }, { sinceLevel = 900 }, { busy = true }, { shown = 1 } } do
	assert(not hint(change))
end
-- Bigger payouts count for longer, within reason.
local plan = require(Client.GoldFlow).plan
local short, long, huge = plan(5), plan(5000), plan(5e9)
assert(short >= 0.7 and long > short and huge <= 4)
print("PASS daily card, playtime gifts, no offline or duplicate credit, claim-through, midnight, reconnect and old saves")

local folder = Instance.new("Folder")
folder.Parent = workspace
local mine = Instance.new("Folder")
mine.Parent = folder
mine:AddTag(Config.MineBlockTag)
local rig = Instance.new("Model")
rig.Parent = folder
local location = Vector3.new(4000, -60, 4000)
local function block(parent, name, position, size)
	local part = Instance.new("Part")
	part.Name, part.Anchored, part.Size, part.Position, part.Parent = name, true, size or Vector3.one * Config.Cell, position, parent
	return part
end
local root = block(rig, "HumanoidRootPart", location, Vector3.one)
local human = Instance.new("Humanoid")
human.RequiresNeck, human.Parent = false, rig
local ore = block(mine, "Copper", location + Vector3.xAxis * 12)
ore:SetAttribute("OpenFaces", 1)
assert(Compass.nearest(location, {rig}) == ore)
local wall = block(mine, "Stone", location + Vector3.xAxis * 6)
assert(not Compass.nearest(location, {rig}))
wall:Destroy()
ore:SetAttribute("OpenFaces", 0)
assert(not Compass.nearest(location, {rig}))

local floor = block(mine, "Stone", location - Vector3.yAxis * 5)
local stone = block(mine, "Stone", location + Vector3.zAxis * 6)
local world = { ready = true, origin = Vector3.zero, grid = { folder = mine } }
function world:excavate(points)
	local count = 0
	for _, position in points do
		assert(position ~= ore.Position and position ~= floor.Position)
		for _, part in mine:GetChildren() do
			if part.Position == position then part:Destroy() count += 1 end
		end
	end
	return {Stone = count}
end
assert(Pulse.clear(world, rig, 1, false) == 1 and not stone.Parent and floor.Parent)
assert(Pulse.clear(world, rig, 1, false) == 0 and Pulse.clear(world, nil, 6, true) == 0)
world.origin = Vector3.new(0, 1750, 0)
stone = block(mine, "Stone", location + Vector3.zAxis * 6)
assert(Pulse.clear(world, rig, 1, false) == 0 and stone.Parent)
assert(Pulse.clear(world, rig, 1, true) == 1 and not stone.Parent)
print("PASS compass line of sight, secret interior, cave pulse footing and power, mineral preservation")

local statue = Instance.new("Model")
statue.Parent = folder
block(statue, "LeftFoot", Vector3.new(0, 12, 0), Vector3.one)
local right = block(statue, "RightFoot", Vector3.new(0, 9, 0), Vector3.new(4, 1, 1))
right.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
local accessory = Instance.new("Accessory")
accessory.Parent = statue
block(accessory, "Handle", Vector3.new(0, 4, 0), Vector3.one * 2)
assert(math.abs(Podiums.soleY(statue) - 7) < 0.001)
statue.LeftFoot.Transparency, right.Transparency = 1, 1
assert(math.abs(Podiums.soleY(statue) - 3) < 0.001)
folder:Destroy()
print("FIELD_REWARDS_TESTS_PASSED")
