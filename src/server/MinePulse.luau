local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Pulse = {}

-- Use nearby exposed blocks. Keep the footing under every player and leave
-- mineral deposits in the wall for the person who wants to mine them.
function Pulse.clear(world, character, power, owner)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local human = character and character:FindFirstChildOfClass("Humanoid")
	if not world.ready or not root or not human or human.Health <= 0 or not Config.inMine(root.Position - world.origin) then
		return 0
	end
	local params = OverlapParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { world.grid.folder }
	local radius = Config.Cell * (if owner then 3.25 else 2.25)
	local candidates = workspace:GetPartBoundsInRadius(root.Position, radius, params)
	local kept = { root.Position }
	for _, player in Players:GetPlayers() do
		local rig = player.Character
		local head = rig and rig:FindFirstChild("HumanoidRootPart")
		if head and head ~= root and (head.Position - root.Position).Magnitude < radius + Config.Cell * 2 then
			table.insert(kept, head.Position)
		end
	end
	local points = {}
	for _, block in candidates do
		if block.Parent ~= world.grid.folder or block.Name ~= "Stone" then continue end
		local position = block.Position
		if (position - root.Position).Magnitude > radius then continue end
		if not owner and Config.strength(position.Y - world.origin.Y) > power then continue end
		local floor = false
		for _, pos in kept do
			local delta = pos - position
			if delta.Y > 0 and delta.Y < Config.Cell * 1.7 and math.max(math.abs(delta.X), math.abs(delta.Z)) < Config.Cell * 0.74 then
				floor = true
				break
			end
		end
		if not floor then table.insert(points, position) end
	end
	table.sort(points, function(a, b) return (a - root.Position).Magnitude < (b - root.Position).Magnitude end)
	local limit = if owner then 40 else 12
	while #points > limit do table.remove(points) end
	local loot = world:excavate(points)
	return loot.Stone or 0
end

return Pulse
