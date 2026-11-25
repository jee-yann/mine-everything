-- Every destination on the island can be walked to from spawn without a jump.
-- Run with Studio --task RunScript against the built place.
local finder = game:GetService("PathfindingService")
local spawnAt = workspace.CitrineCove["Sand path and bridge"].Landing.Position + Vector3.new(0, 1, -3)
local goals = {
	["the mine"] = { 0, 25, -4 }, Sell = { -21.5, 25, 23 }, Upgrades = { 21.5, 25, 23 }, Jobs = { -20, 25, 66 }, Outfitters = { 20, 25, 66 },
	Supplies = { -34, 25, 86 }, ["Ore Index"] = { 34, 25, 86 }, ["the ore yard"] = { -84, 30.2, 24 }, ["the adit"] = { -92, 30.2, 2 },
	["the dock"] = { -62, 25.4, 33 }, ["the gardens"] = { 82, 30.2, 32 }, ["the lighthouse"] = { 88.6, 36.2, 24 }, ["the lookout"] = { 0, 26.4, 143 },
	["the west hill"] = { -99, 32.6, 92 }, ["the east hill"] = { 99, 32.6, 92 }, ["the boards"] = { -27, 25.6, 116 }, ["the beach"] = { 60, 25, 130 },
	["the west ridge"] = { -116, 27, -10 }, ["the east ridge"] = { 116, 27, -10 }, ["the ridge"] = { 0, 37.2, -70 }, ["the gate overlook"] = { 24, 44.6, -10 },
	["the spring"] = { 58, 25, 20 },
}
for name, p in goals do
	local path = finder:CreatePath({ AgentRadius = 1.6, AgentHeight = 5, AgentCanJump = false, AgentMaxSlope = 50 })
	path:ComputeAsync(spawnAt, Vector3.new(p[1], p[2], p[3]))
	assert(path.Status == Enum.PathStatus.Success, "cannot walk to " .. name)
	local length, last = 0, spawnAt
	for _, w in path:GetWaypoints() do
		length += (w.Position - last).Magnitude
		last = w.Position
	end
	print(string.format("WALK %s %d studs", name, length))
	assert(name ~= "the mine" or length < 110, "the mine is too far from spawn")
end
print("MAP_WALK_PASSED")
