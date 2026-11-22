local rgb = Color3.fromRGB
local upgrades = {
	Speed = {
		values = { 0.80, 0.64, 0.51, 0.40, 0.32, 0.25, 0.20 },
		base = 30,
		growth = 2.4,
		icon = "»",
		color = rgb(255, 200, 80),
	},
	Power = {
		values = { 1, 2, 3, 4, 5, 6 },
		base = 36,
		growth = 3.6,
		icon = "◆",
		color = rgb(255, 147, 100),
	},
	Capacity = {
		values = { 8, 16, 24, 32, 40, 48, 56, 64 },
		firstPrice = 8,
		base = 24,
		growth = 2.5,
		icon = "▣",
		color = rgb(137, 231, 142),
	},
}
local api = {
	pickNames = { "Field Pick", "Copper Pick", "Iron Pick", "Gilded Pick", "Starfrost Pick", "Prismheart Pick" },
	items = upgrades,
	order = { "Speed", "Power", "Capacity" },
}
function api.price(key, level)
	local item = upgrades[key]
	if level >= #item.values then
		return nil
	end
	if level == 1 and item.firstPrice then
		return item.firstPrice
	end
	return math.floor(item.base * item.growth ^ (level - 1) + 0.5)
end

function api.onboardingPick(gold)
	local speedPrice = api.price("Speed", 1)
	if gold >= speedPrice then
		return "Speed", speedPrice
	end
	return "Capacity", api.price("Capacity", 1)
end

function api.describe(key, level)
	local v = upgrades[key].values[level]
	if key == "Speed" then
		return string.format("%.2fs / stone", v)
	end
	if key == "Capacity" then
		return v .. " ore"
	end
	return ({ "Coal", "Copper", "Iron", "Gold", "Diamond", "Emerald" })[level]
end
return api
