--!strict
-- The Forge: sure-thing crafting with mined ore, Crate Dust (from duplicate rewards) and gems. Every
-- pet and cosmetic here can also come from a crate; crafting is the way to the one you want.
local R = {}

R.list = {
	-- Tonics
	{ id = "GoldTonic", group = "Tonics", give = { kind = "item", id = "GoldTonic" }, ores = { Gold = 2, Coal = 4 }, gems = 4 },
	{ id = "HasteTonic", group = "Tonics", give = { kind = "item", id = "HasteTonic" }, ores = { Copper = 4, Quartz = 1 }, gems = 4 },
	{ id = "LuckyBrew", group = "Tonics", give = { kind = "item", id = "LuckyBrew" }, ores = { Garnet = 2, Quartz = 2 }, gems = 12 },
	-- Pets
	{ id = "Crab", group = "Pets", give = { kind = "pet", id = "Crab" }, ores = { Copper = 20 }, dust = 40 },
	{ id = "Golem", group = "Pets", give = { kind = "pet", id = "Golem" }, ores = { Iron = 20, Quartz = 6 }, dust = 120 },
	{ id = "Fox", group = "Pets", give = { kind = "pet", id = "Fox" }, ores = { Quartz = 16, Diamond = 3 }, dust = 350, gems = 40 },
	{ id = "Owl", group = "Pets", give = { kind = "pet", id = "Owl" }, ores = { Opal = 6, Diamond = 6 }, dust = 1100, gems = 120 },
	-- Mining trails
	{ id = "Frost", group = "Mining trails", give = { kind = "trail", id = "Frost" }, ores = { Quartz = 4 }, dust = 30 },
	{ id = "Aurora", group = "Mining trails", give = { kind = "trail", id = "Aurora" }, ores = { Opal = 3, Emerald = 1 }, dust = 450, gems = 60 },
	-- Player effects
	{ id = "Sunset", group = "Player effects", give = { kind = "ribbon", id = "Sunset" }, ores = { Garnet = 3, Gold = 3 }, dust = 120 },
	{ id = "Halo", group = "Player effects", give = { kind = "aura", id = "Halo" }, ores = { Platinum = 4, Diamond = 4 }, dust = 1300, gems = 150 },
	-- Pet styles
	{ id = "Wings", group = "Pet styles", give = { kind = "style", id = "Wings" }, ores = { Quartz = 6, Silver = 3 }, dust = 120 },
	{ id = "Crown", group = "Pet styles", give = { kind = "style", id = "Crown" }, ores = { Gold = 12, Diamond = 2 }, dust = 900, gems = 100 },
}
R.groups = { "Tonics", "Pets", "Mining trails", "Player effects", "Pet styles" }
R.byId = {}
for _, recipe in R.list do
	R.byId[recipe.id] = recipe
end

return R
