-- Ink & Facet: how every mine block looks. This module is data only.
--
-- MineBlocks paints each block's rock from it, and MineralRelief builds the low-poly
-- pieces on each open face from the `relief` and `crown` recipes in ReliefKit.
--
-- To add an ore later:
--   1. Add it to Ores.list before Starfall. Starfall stays the last and most valuable ore
--      (tests/Mine.spec.luau checks this).
--   2. Add an entry to Looks.ores below. Pick a relief recipe from ReliefKit.recipes and a
--      palette that runs dark to light. Give gems a `crown` so they break out of the block.
--   3. Only if no recipe fits, add one to ReliefKit.recipes.
--   4. Draw its face in art/ore-looks/draw_faces.py and run it to refresh src/client/OreDrawings.
-- Nothing else needs to change: the client finds the look by the ore's name.

export type Look = {
	relief: string, -- a ReliefKit.recipes entry, drawn flush on every open face
	palette: { string }, -- four colours, dark to light
	accent: { string }?, -- a second material, such as copper's malachite
	crown: string?, -- a ReliefKit.crowns entry: 3D crystals, used when drawings can't be shown
	glow: string?, -- light colour for ores that glow (Gold and up)
	shine: number?, -- how strongly it glows, 0 to 1: Gold barely, Starfall the most
	sparkle: boolean?, -- white glints on the relief
}

export type Rock = {
	color: string?, -- fixed rock colour. Without one the block uses its stone grade.
	decor: string, -- a ReliefKit.recipes entry, drawn on some open faces
	palette: { string },
	every: number?, -- decorate about one open face in `every`
	tint: boolean?, -- the drawn face takes the block's colour (Stone: its stone grade)
}

local Looks = {}

Looks.ink = "1A141F"

-- Drawn faces: every open face shows a Storybook Ink drawing from src/client/OreDrawings.
-- `uploaded` maps a drawing's name (such as "Coal" or "Stone-2") to an uploaded image id that
-- is used instead of decoding the drawing; the PNGs are in art/ore-looks/faces. Without either,
-- faces fall back to the ink frame and the 3D relief below.
Looks.drawn = { enabled = true, uploaded = {} :: { [string]: string } }

-- Ores with a `shine` glow from their ore pieces, not the rock around them. On the nearest few
-- glowing ores, each raised face shows its glow image (DrawnFaces: the pieces with a neon
-- filling and a soft halo) self-lit over the pieces, and a spotlight just off one face throws
-- light onto the tunnel (never back onto the ore's own rock). Both slowly breathe. Each pair
-- runs from shine 0 to shine 1.
Looks.glow = {
	ores = 8, -- how many of the nearest glowing ores light up at once
	range = 80, -- studs from the camera
	pulse = 0.12,
	pieces = { brightness = { 1.25, 2.3 }, transparency = { 0.45, 0 } }, -- the self-lit neon pieces
	light = { brightness = { 0.35, 1.4 }, reach = { 6, 14 }, angle = 80, offset = 0.6 }, -- light thrown outward
}

-- Glints: tiny sparkles on the raised pieces of the nearest ores. Each spot (picked from the
-- drawing's highlights) is tilted a little differently and lights up only when it faces the
-- camera, where the miner's lamp is, so glints wink on and off as you move. `window` is how
-- close (degrees) the view must line up, `tilt` how far spots lean, `twinkle` a rare faint
-- flash while standing still, and `size` a fraction of the face.
Looks.glints = { faces = 16, range = 40, size = 0.09, window = 10, tilt = 0.9, twinkle = 0.45, brightness = 2 }

-- Every ore shows its ore pieces raised a little off each drawn face: its pieces image
-- (DrawnFaces), stacked in thin layers, darker underneath, so from an angle they read as standing
-- out of the rock. `height` is in studs, `layers` is at least 3, and `shade` darkens the lower
-- layers (the lowest sits on the face and hides the flat drawn pieces). Without drawings, ores
-- show a 3D relief instead, and gems grow 3D crystals from their `crown`.
Looks.raised = { height = 0.3, layers = 6, shade = { 0.1, 0.32 } }

-- Every open face gets an ink frame. The client draws the image itself when the
-- experience allows EditableImage. Otherwise it uses `image` (an uploaded asset id)
-- if one is set, and draws no frames if not.
Looks.frame = { image = nil :: string?, transparency = 0.1 }

-- Ink outlines around the relief on the nearest ore faces. Roblox renders at most
-- 31 Highlights at once, so keep `count` well below that.
Looks.outlines = { count = 12, range = 60 }

-- How far an ore block's rock leans toward the ore's own colour. Ores sit in the
-- same stone as their neighbours, so the relief does the talking.
Looks.hostTint = 0.12

Looks.rock = {
	Dirt = {
		color = "8A5B3C",
		decor = "specks",
		palette = { "4A2E1C", "6A4129", "8A5B3C", "A87552" },
		every = 3,
	},
	Stone = { decor = "cracks", palette = { "6E7079", "999BA4", "C4C6CC", "EEEFF2" }, every = 4, tint = true },
	-- Cave ceilings the server marks with CalciteFaces.
	Calcite = { decor = "calcite", palette = { "71777C", "AAA99F", "D0CDBB", "EDEBE2" } },
} :: { [string]: Rock }

Looks.ores = {
	Coal = { relief = "lumps", palette = { "1A1C22", "363841", "5C5F6A", "B6BAC6" } },
	Copper = {
		relief = "malachite",
		palette = { "5A1E10", "B5502E", "EA8862", "FFDCCB" },
		accent = { "0B4A33", "1F7A52", "3FAE74", "8FE3AE" },
	},
	Iron = {
		relief = "chunks",
		palette = { "343C47", "667487", "AAB8C8", "F2F6FA" },
	},
	Gold = {
		relief = "nugget",
		palette = { "7A3F02", "D08A16", "FFD050", "FFF7D6" },
		sparkle = true,
		glow = "FFD27A",
		shine = 0.15,
	},
	Diamond = {
		relief = "octahedra",
		crown = "octahedron",
		palette = { "3A86A6", "8DE2F2", "D6FCFF", "FFFFFF" },
		glow = "9FF3FF",
		shine = 0.35,
		sparkle = true,
	},
	Emerald = {
		relief = "hexes",
		crown = "prisms",
		palette = { "0D5434", "238553", "4CCE72", "C0FFB8" },
		glow = "7DFF95",
		shine = 0.45,
		sparkle = true,
	},
	Amethyst = {
		relief = "geode",
		crown = "cluster",
		palette = { "43206F", "7943B4", "B37BE8", "F4DDFF" },
		glow = "C98CFF",
		shine = 0.55,
		sparkle = true,
	},
	Sapphire = {
		relief = "barrels",
		crown = "spires",
		palette = { "16287A", "3050B0", "6A9DFF", "D6E5FF" },
		glow = "7FA8FF",
		shine = 0.62,
		sparkle = true,
	},
	Emberglass = {
		relief = "shards",
		crown = "blades",
		palette = { "140B10", "3A2434", "8A3A52", "FFB59A" },
		glow = "FF6F5E",
		shine = 0.72,
	},
	-- Ores added in the region expansion. Only the exceptional ones glow.
	Pyrite = { relief = "chunks", palette = { "5E4A1A", "A88A3A", "DCC06A", "FFF3C2" } },
	Quartz = { relief = "shards", palette = { "9AA3B0", "C9D0D9", "EEF2F6", "FFFFFF" } },
	Sunstone = {
		relief = "nugget",
		palette = { "7A2E0A", "D2601E", "FF9A48", "FFE2B0" },
		glow = "FFB066",
		shine = 0.3,
		sparkle = true,
	},
	Garnet = { relief = "hexes", palette = { "4A0A16", "8E1A2C", "D23A4E", "FFB0B8" } },
	Silver = { relief = "chunks", palette = { "4A525E", "8E98A6", "CDD5DF", "FFFFFF" } },
	Opal = { relief = "lumps", palette = { "5E7C86", "A6D6D8", "E2F6F2", "FFFFFF" }, glow = "B8FFF4", shine = 0.25 },
	Selenite = { relief = "shards", palette = { "8E8676", "C9C2AE", "EEE9D8", "FFFFFF" } },
	Jade = { relief = "lumps", palette = { "1E5A3A", "3A8A5C", "7CC08E", "D8F2DC" } },
	Platinum = { relief = "chunks", palette = { "5A6170", "9EA6B4", "D8DEE8", "FFFFFF" } },
	Lumenite = { relief = "geode", palette = { "0E6A54", "22B08C", "7DFFD6", "E0FFF6" }, glow = "7DFFD6", shine = 0.6 },
	Obsidian = { relief = "shards", palette = { "0C0812", "241C30", "4C4060", "C8C0E0" } },
	Ruby = { relief = "hexes", palette = { "5A0618", "A8102E", "F0405E", "FFC0CC" }, glow = "FF5C7A", shine = 0.5 },
	Mithril = { relief = "chunks", palette = { "3E5A72", "7AA6C6", "C6E4F6", "FFFFFF" } },
	Brimstone = { relief = "lumps", palette = { "8A6A08", "D0A818", "FFE04A", "FFF8C2" } },
	Aquamarine = {
		relief = "hexes",
		palette = { "1E6A80", "4CB0CC", "9CEAF8", "EAFDFF" },
		glow = "8FEFFF",
		shine = 0.55,
		sparkle = true,
	},
	Meteorite = { relief = "nugget", palette = { "2E2A2E", "5E5862", "9E98A2", "E6E2E8" } },
	Moonstone = {
		relief = "nugget",
		palette = { "7A8AB0", "B8C6E8", "E6EEFF", "FFFFFF" },
		glow = "DDE8FF",
		shine = 0.6,
	},
	Adamantite = { relief = "hexes", palette = { "0A3A36", "1E7A70", "4CC6B4", "C8FFF4" } },
	Resonite = { relief = "geode", palette = { "2A4A8A", "5A8ACE", "A6CCFF", "EAF4FF" }, glow = "9CCBFF", shine = 0.78 },
	Voidshard = {
		relief = "shards",
		palette = { "0A0614", "2A1650", "6A3CC4", "D6C2FF" },
		glow = "B07CFF",
		shine = 0.88,
	},
	-- The last ore. Future ores go above this entry.
	Starfall = {
		relief = "star",
		crown = "cluster",
		palette = { "5A3FA0", "9577D4", "DDB4FF", "FFF7EC" },
		glow = "EBCBFF",
		shine = 1,
		sparkle = true,
	},
} :: { [string]: Look }

return Looks
