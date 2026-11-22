local Shared = game.ReplicatedStorage.Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Tags = game:GetService("CollectionService")
local Compass = {}

-- A pet can point out a visible seam in the room, even behind its owner's camera.
function Compass.nearest(origin, ignore)
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = Tags:GetTagged(Config.MineBlockTag)
	local ray = RaycastParams.new()
	ray.FilterDescendantsInstances, ray.RespectCanCollide = ignore, true
	local radius = Config.Cell * 5
	local nearest, distance = nil, radius
	for _, part in workspace:GetPartBoundsInRadius(origin, radius, overlap) do
		local ore = Ores.byName[part.Name]
		if ore and not ore.host and part.Parent:HasTag(Config.MineBlockTag) and (part:GetAttribute("OpenFaces") or 0) ~= 0 then
			local delta = part.Position - origin
			if delta.Magnitude < distance then
				local hit = workspace:Raycast(origin, delta, ray)
				if hit and hit.Instance == part then
					nearest, distance = part, delta.Magnitude
				end
			end
		end
	end
	return nearest
end

return Compass
