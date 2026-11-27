local cell = 6
local Config = {
	LandscapeSeed = 73129,
	-- Blocks removed server-wide before the mine renews: 2,600 for one miner (about 2,000 blocks of
	-- mining after a shaft to the crater, row 550) and 1,500 more for each other miner here, up to
	-- 9,000. It never renews sooner than ResetSoonest after the last time, however fast anyone cuts,
	-- and always after ResetSeconds. Miners at least ReturnDepth blocks down go back to their spot in
	-- the new mine, so a reset never costs anyone their climb down.
	ResetAfter = 2600,
	ResetPerMiner = 1500,
	ResetMost = 9000,
	ResetSoonest = 1200,
	ResetSeconds = 3600,
	ResetWarning = 20,
	ReturnDepth = 12,
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
	-- Playtesting: every miner can wear every Mining FX and Player FX, even in the published game.
	-- Crates still roll and grant as normal. Set false for release.
	AllFxForTesting = true,
	-- Playtesting: anything in the Shop without a Robux ID yet (StoreConfig id = 0) is given free when
	-- bought, even in the published game, so crates, boosts and passes can be tried. Items with an ID
	-- always go through Roblox's checkout. Set false for release.
	FreeUnconfiguredItems = true,
	LeaseSeconds = 180,
	AutosaveSeconds = 45,
	-- Maximum pattern faces checked per second across all players.
	CellBudget = 2400,
	BurstCells = 100,
}
-- Regions: each has its own ore table (percent of solid blocks; the rest is plain stone).
-- Some ores span many regions, some peak in one and fade below it, and some are found in only
-- one region. Starfall appears only in the crater, at the bottom of the mine.
Config.Layers = {
	{
		depthBlocks = 0,
		name = "Sunstone Hollow",
		theme = "Warm sandstone where the cove's light still reaches",
		oreChances = { Coal = 13, Copper = 5, Pyrite = 4, Sunstone = 0.05 },
		material = Enum.Material.Concrete,
		color = Color3.fromRGB(151, 153, 158),
	},
	{
		depthBlocks = 27,
		name = "Iron Shelf",
		theme = "Banded grey shelves rich in iron",
		oreChances = { Coal = 5, Copper = 6, Iron = 8, Pyrite = 3, Quartz = 4, Garnet = 0.68, Gold = 1 },
		material = Enum.Material.Rock,
		color = Color3.fromRGB(132, 136, 143),
	},
	{
		depthBlocks = 60,
		name = "Rustroot Caverns",
		theme = "Rust-red rock threaded with petrified roots",
		oreChances = {
			Coal = 1,
			Copper = 4.5,
			Iron = 9,
			Pyrite = 1.5,
			Quartz = 4,
			Garnet = 3.5,
			Silver = 1.2,
			Gold = 2.5,
		},
		material = Enum.Material.Rock,
		color = Color3.fromRGB(128, 100, 92),
	},
	{
		depthBlocks = 90,
		name = "Prism Grotto",
		theme = "Crystal-lined caves that split the lamplight",
		oreChances = {
			Coal = 1,
			Copper = 2,
			Iron = 6,
			Quartz = 7,
			Garnet = 1.5,
			Silver = 3,
			Gold = 4.5,
			Opal = 2.2,
			Diamond = 1.2,
		},
		material = Enum.Material.Slate,
		color = Color3.fromRGB(115, 119, 127),
	},
	{
		depthBlocks = 140,
		name = "Saltglass Sinks",
		theme = "Pale salt flats and satin selenite",
		oreChances = {
			Copper = 1,
			Iron = 4,
			Quartz = 3.5,
			Silver = 6,
			Gold = 6,
			Selenite = 3,
			Opal = 1,
			Jade = 0.84,
			Diamond = 2.5,
		},
		material = Enum.Material.Slate,
		color = Color3.fromRGB(150, 146, 140),
	},
	{
		depthBlocks = 185,
		name = "Emerald Deep",
		theme = "Green-veined dark where emeralds grow",
		oreChances = {
			Iron = 3,
			Quartz = 2.5,
			Silver = 4,
			Gold = 7,
			Diamond = 4.5,
			Opal = 0.5,
			Jade = 3,
			Emerald = 2.2,
			Platinum = 0.84,
		},
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(96, 100, 108),
	},
	{
		depthBlocks = 225,
		name = "Glowcap Hollows",
		theme = "Mossy caverns lit by glowing fungus",
		oreChances = {
			Iron = 3,
			Silver = 3,
			Gold = 5,
			Diamond = 5,
			Jade = 1.2,
			Emerald = 2.5,
			Platinum = 3,
			Lumenite = 0.35,
			Amethyst = 0.4,
		},
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(84, 104, 90),
	},
	{
		depthBlocks = 260,
		name = "Midnight Fault",
		theme = "A black fault of obsidian and hidden geodes",
		oreChances = {
			Iron = 2,
			Gold = 4,
			Diamond = 6,
			Emerald = 2,
			Platinum = 3,
			Obsidian = 7,
			Amethyst = 0.92,
			Ruby = 1,
			Sapphire = 0.59,
			Mithril = 0.5,
		},
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(89, 84, 105),
	},
	{
		depthBlocks = 340,
		name = "Frostglass Reach",
		theme = "Frozen caverns of blue crystal",
		oreChances = {
			Gold = 3,
			Diamond = 5,
			Platinum = 1.5,
			Obsidian = 4,
			Amethyst = 1,
			Ruby = 3,
			Sapphire = 2,
			Mithril = 1.5,
			Aquamarine = 1.2,
		},
		material = Enum.Material.Ice,
		color = Color3.fromRGB(134, 171, 190),
	},
	{
		depthBlocks = 400,
		name = "Cinderheart Forge",
		theme = "Volcanic rock, sulphur crusts and molten seams",
		oreChances = {
			Diamond = 3,
			Obsidian = 6,
			Ruby = 2,
			Sapphire = 0.68,
			Mithril = 3,
			Brimstone = 7,
			Emberglass = 0.92,
			Moonstone = 0.4,
		},
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(110, 74, 66),
	},
	{
		depthBlocks = 470,
		name = "Abyssal Hollows",
		theme = "Drowned, silent caverns far below the sea",
		oreChances = {
			Diamond = 2,
			Obsidian = 3,
			Ruby = 1,
			Mithril = 5,
			Moonstone = 3,
			Resonite = 0.2,
			Meteorite = 1,
			Adamantite = 0.35,
		},
		material = Enum.Material.Slate,
		color = Color3.fromRGB(62, 80, 98),
	},
	{
		depthBlocks = 550,
		name = "Starfall Crater",
		theme = "The impact crater where the stars came down",
		oreChances = {
			Diamond = 2,
			Obsidian = 3,
			Mithril = 3,
			Moonstone = 1.5,
			Meteorite = 6,
			Adamantite = 1.6,
			Voidshard = 0.085,
			Starfall = 0.0025,
		},
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(66, 54, 98),
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
-- Stone grades: hardness rises with depth for all materials, including ordinary stone. A grade's
-- number is the pickaxe Power it needs. `material` is how plain stone looks if drawings fail.
Config.StoneGrades = {
	{ depth = 0, name = "Stone", material = Enum.Material.Plastic, color = Color3.fromRGB(160, 162, 169) },
	{ depth = 27, name = "Hard Stone", material = Enum.Material.Slate, color = Color3.fromRGB(119, 139, 151) },
	{ depth = 60, name = "Dense Stone", material = Enum.Material.Basalt, color = Color3.fromRGB(100, 107, 125) },
	{ depth = 90, name = "Rift Stone", material = Enum.Material.Sandstone, color = Color3.fromRGB(123, 109, 140) },
	{ depth = 140, name = "Tempered Stone", material = Enum.Material.Granite, color = Color3.fromRGB(87, 99, 111) },
	{ depth = 185, name = "Midnight Stone", material = Enum.Material.Marble, color = Color3.fromRGB(69, 65, 91) },
	{ depth = 225, name = "Mossbound Stone", material = Enum.Material.Slate, color = Color3.fromRGB(78, 97, 82) },
	{ depth = 260, name = "Shadowslate", material = Enum.Material.Slate, color = Color3.fromRGB(62, 58, 76) },
	{ depth = 300, name = "Faultsteel Rock", material = Enum.Material.Basalt, color = Color3.fromRGB(74, 68, 88) },
	{ depth = 340, name = "Rimestone", material = Enum.Material.Glacier, color = Color3.fromRGB(111, 140, 158) },
	{ depth = 400, name = "Cinderstone", material = Enum.Material.Basalt, color = Color3.fromRGB(90, 58, 52) },
	{ depth = 470, name = "Abyssal Basalt", material = Enum.Material.Basalt, color = Color3.fromRGB(46, 59, 74) },
	{ depth = 550, name = "Voidglass", material = Enum.Material.Glass, color = Color3.fromRGB(43, 36, 64) },
	{ depth = 620, name = "Starbound Rock", material = Enum.Material.Slate, color = Color3.fromRGB(53, 43, 82) },
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
