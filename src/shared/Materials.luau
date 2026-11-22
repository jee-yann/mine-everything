local Ores = require(script.Parent.Ores)
local Materials = {}

Materials.supplies = {
	Flare = { name = "Survey flare", recipe = { Copper = 2, Coal = 3 } },
	Temper = { name = "Pickaxe temper", recipe = { Coal = 4 } },
}
Materials.temperCharges = 25
local orders = {
	{ name = "Lantern refills", recipe = { Coal = 5, Stone = 3 }, gold = 52 },
	{ name = "Signal wire", recipe = { Copper = 3, Coal = 2 }, gold = 74 },
	{ name = "Brace the shaft", recipe = { Stone = 8, Copper = 2 }, gold = 64 },
	{ name = "Kiln crew", recipe = { Dirt = 8, Coal = 4 }, gold = 48 },
	{ name = "Spare fittings", recipe = { Iron = 2, Copper = 2 }, gold = 108 },
}
function Materials.daily(day)
	return orders[day % #orders + 1]
end
function Materials.missing(recipe, bag)
	for _, ore in Ores.list do
		local need = recipe[ore.name]
		if need and (bag[ore.name] or 0) < need then
			return ore.name, need - (bag[ore.name] or 0)
		end
	end
end
function Materials.consume(recipe, bag)
	for name, need in recipe do
		local remaining = (bag[name] or 0) - need
		bag[name] = if remaining > 0 then remaining else nil
	end
end
return Materials
