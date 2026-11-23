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
	crown: string?, -- a ReliefKit.crowns entry: crystals that break out of the face
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

-- Ores with a `shine` give off a soft light just in front of one open face. It brightens the
-- ore's own face and tints the rock around it, and it slowly breathes. Only the nearest few
-- glowing ores near the camera light up at once. `brightness` and `reach` (light range in studs)
-- run from shine 0 to shine 1.
Looks.glow = {
	lights = 8,
	range = 80,
	offset = 1.2,
	brightness = { 0.22, 1.0 },
	reach = { 5, 11 },
	pulse = 0.12,
}

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
