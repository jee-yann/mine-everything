local cell = 6
local Config = {
	LandscapeSeed = 73129,
	ResetAfter = 2400,
	ResetSeconds = 3600,
	ResetWarning = 20,
	-- The gallery begins one cell behind the entrance and spans ten cells on each axis.
	Cell = cell,
	Chunk = 8,
	OreVisionRadius = 10, -- In mine cells, measured from the owner's cell.
	FloorY = 0,
	DirtLayers = 1,
	HallHalfWidth = 5 * cell,
	HallFront = -cell,
	HallBack = -11 * cell,
	MineBlockTag = "EndlessMiningBlockFolder",
	SiteMin = Vector3.new(-96, -112, -168),
	SiteMax = Vector3.new(96, 40, 0),
	SurfaceMin = Vector3.new(-144, -12, -92),
	SurfaceMax = Vector3.new(144, 92, 156),
	-- Fallback origin when the mine is built without an authored surface.
	Origin = Vector3.new(0, 24, 4),
	SurfaceName = "Citrine Cove",
	Reach = 34,
	StoreName = "EndlessMining_v1",
	AllowProgressReset = true, -- Prototype Settings option. Set false to retire it for release.
	LeaseSeconds = 180,
	AutosaveSeconds = 45,
	-- Maximum pattern faces checked per second across all players.
	CellBudget = 2400,
	BurstCells = 100,
}
Config.Layers = {
	{
		depthBlocks = 0,
		name = "Sunstone Hollow",
		oreChances = { Coal = 13, Copper = 5 },
		material = Enum.Material.Concrete,
		color = Color3.fromRGB(151, 153, 158),
	},
	{
		depthBlocks = 27,
		name = "Iron Shelf",
		oreChances = { Coal = 6, Copper = 7, Iron = 8, Gold = 1 },
		material = Enum.Material.Rock,
		color = Color3.fromRGB(132, 136, 143),
	},
	{
		depthBlocks = 90,
		name = "Prism Grotto",
		oreChances = { Coal = 3, Copper = 5, Iron = 9, Gold = 6, Diamond = 2 },
		material = Enum.Material.Slate,
		color = Color3.fromRGB(115, 119, 127),
	},
	{
		depthBlocks = 185,
		name = "Emerald Deep",
		oreChances = { Coal = 2, Copper = 3, Iron = 7, Gold = 8, Diamond = 5, Emerald = 2, Emberglass = 0.12 },
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(96, 100, 108),
	},
	{
		depthBlocks = 260,
		name = "Midnight Fault",
		oreChances = {
			Coal = 2,
			Copper = 3,
			Iron = 5,
			Gold = 6,
			Diamond = 6,
			Emerald = 3,
			Emberglass = 0.22,
			Starfall = 0.025,
		},
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(89, 84, 105),
	},
	{
		depthBlocks = 340,
		name = "Frostglass Reach",
		oreChances = {
			Coal = 1,
			Copper = 2,
			Iron = 5,
			Gold = 5,
			Diamond = 7,
			Emerald = 4,
			Amethyst = 0.8,
			Sapphire = 0.35,
			Emberglass = 0.22,
			Starfall = 0.025,
		},
		material = Enum.Material.Ice,
		color = Color3.fromRGB(134, 171, 190),
	},
}
function Config.depthInBlocks(depthStuds)
	return math.floor(depthStuds / Config.Cell)
end
function Config.blockCoordinates(localPos)
	-- Count rows down from the dig floor so Y = -27 exactly where Iron Shelf begins.
	local y = -Config.depthInBlocks(Config.FloorY - localPos.Y)
	if Config.inHall(localPos) and Config.inMine(localPos) then
		y = math.min(y, 0)
	end
	return Vector3.new(math.floor(localPos.X / Config.Cell), y, math.floor(localPos.Z / Config.Cell))
end
function Config.layer(depthStuds)
	local depthBlocks = Config.depthInBlocks(depthStuds)
	for i = #Config.Layers, 1, -1 do
		if depthBlocks >= Config.Layers[i].depthBlocks then
			return Config.Layers[i]
		end
	end
	return Config.Layers[1]
end
function Config.blockCenter(origin, position, normal)
	-- Step just inside the struck brick, including bricks that span several cells.
	local point = position - origin - normal * (Config.Cell * 0.01)
	return origin + ((point / Config.Cell):Floor() + Vector3.one * 0.5) * Config.Cell
end
-- Hardness increases for all materials, including ordinary stone.
Config.StoneGrades = {
	{ depth = 0, name = "Stone", material = Enum.Material.Plastic, color = Color3.fromRGB(160, 162, 169) },
	{ depth = 27, name = "Hard Stone", material = Enum.Material.Slate, color = Color3.fromRGB(119, 139, 151) },
	{ depth = 60, name = "Dense Stone", material = Enum.Material.Basalt, color = Color3.fromRGB(100, 107, 125) },
	{ depth = 90, name = "Rift Stone", material = Enum.Material.Sandstone, color = Color3.fromRGB(123, 109, 140) },
	{ depth = 140, name = "Tempered Stone", material = Enum.Material.Granite, color = Color3.fromRGB(87, 99, 111) },
	{ depth = 185, name = "Midnight Stone", material = Enum.Material.Marble, color = Color3.fromRGB(69, 65, 91) },
}
function Config.strength(localY)
	local depth = Config.depthInBlocks(Config.FloorY - localY)
	for tier = #Config.StoneGrades, 2, -1 do
		if depth >= Config.StoneGrades[tier].depth then
			return tier
		end
	end
	return 1
end
function Config.inHall(p)
	return math.abs(p.X) < Config.HallHalfWidth and p.Z >= Config.HallBack and p.Z < Config.HallFront
end
function Config.inMine(p)
	return p.Y < Config.FloorY - Config.Cell * Config.DirtLayers or (Config.inHall(p) and p.Y < Config.FloorY + 12)
end
return Config
