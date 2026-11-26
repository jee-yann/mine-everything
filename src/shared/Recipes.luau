--!strict
-- The Forge: sure-thing crafting with mined ore, Geode Dust (from duplicate rewards) and gems. Every
-- pet and cosmetic here can also come from a geode; crafting is the way to the one you want.
local R = {}

R.list = {
	-- Pet food
	{ id = "Snack", group = "Pet food", give = { kind = "item", id = "Snack", count = 2 }, ores = { Coal = 6, Copper = 2 } },
	{ id = "Feast", group = "Pet food", give = { kind = "item", id = "Feast" }, ores = { Iron = 4, Quartz = 2 }, gems = 6 },
	-- Tonics
	{ id = "GoldTonic", group = "Tonics", give = { kind = "item", id = "GoldTonic" }, ores = { Gold = 2, Coal = 4 }, gems = 4 },
	{ id = "HasteTonic", group = "Tonics", give = { kind = "item", id = "HasteTonic" }, ores = { Copper = 4, Quartz = 1 }, gems = 4 },
	{ id = "LuckyBrew", group = "Tonics", give = { kind = "item", id = "LuckyBrew" }, ores = { Garnet = 2, Quartz = 2 }, gems = 12 },
	-- Pets
	{ id = "Crab", group = "Pets", give = { kind = "pet", id = "Crab" }, ores = { Copper = 20 }, dust = 40 },
	{ id = "Fox", group = "Pets", give = { kind = "pet", id = "Fox" }, ores = { Quartz = 16, Diamond = 3 }, dust = 350, gems = 40 },
	{ id = "Owl", group = "Pets", give = { kind = "pet", id = "Owl" }, ores = { Opal = 6, Diamond = 6 }, dust = 1100, gems = 120 },
	-- Cosmetics
	{ id = "Frost", group = "Cosmetics", give = { kind = "trail", id = "Frost" }, ores = { Quartz = 4 }, dust = 30 },
	{ id = "Aurora", group = "Cosmetics", give = { kind = "trail", id = "Aurora" }, ores = { Opal = 3, Emerald = 1 }, dust = 450, gems = 60 },
	{ id = "Halo", group = "Cosmetics", give = { kind = "aura", id = "Halo" }, ores = { Platinum = 4, Diamond = 4 }, dust = 1300, gems = 150 },
}
R.groups = { "Pet food", "Tonics", "Pets", "Cosmetics" }
R.byId = {}
for _, recipe in R.list do
	R.byId[recipe.id] = recipe
end

return R
