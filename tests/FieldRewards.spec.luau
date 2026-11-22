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
for _, key in { "gems", "stampDay", "stampCount", "hasteCuts", "stoneChips", "pulses" } do legacy[key] = nil end
local p = assert(Data.claim({profile = legacy}, "new session", 1000)).profile
assert(p.gems == 0 and p.hasteCuts == 0 and not Profile.hasUpgrade(p))
for day, payout in Field.stamps do
	local today = 20000 + 3 * day
	local number, amount = Field.claim(p, today)
	assert(number == day and amount == payout)
	assert(not Field.claim(p, today) and not Field.claim(p, today - 1))
end
assert(p.gems == 36 and Field.claim(p, 20100) == 1 and p.gems == 37)
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
for _, key in { "gems", "stampCount", "stampDay", "oreCompass", "pulses", "hasteCuts", "stoneChips", "auraOff" } do
	assert(p[key] == restored[key], key)
end
assert(Profile.hasUpgrade(restored))
snapshot.stampCount = 8
assert(not Profile.valid(snapshot))
print("PASS gem card rollover, missed days, duplicate claims, recipes, saved charges, first-upgrade aura")

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
