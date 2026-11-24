local rgb = Color3.fromRGB
local Ores = require(script.Parent.Ores)
local Config = require(script.Parent.GameConfig)
-- Power level N mines stone grade N (GameConfig.StoneGrades) and any ore with hardness N or less.
-- Power prices are listed one by one: each was tuned so a normal player spends a set time in
-- each region (minutes near the top, an hour or two at the bottom). Speed and Capacity grow
-- geometrically from `base` by `growth`.
local upgrades = {
	Speed = {
		values = { 0.80, 0.64, 0.51, 0.40, 0.32, 0.25, 0.20, 0.16, 0.13, 0.11 },
		base = 30,
		growth = 2.75,
		icon = "»",
		color = rgb(255, 200, 80),
	},
	Power = {
		values = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 },
		prices = { 110, 400, 1900, 8000, 21000, 60000, 130000, 220000, 350000, 1000000, 1900000, 2700000, 6800000 },
		icon = "◆",
		color = rgb(255, 147, 100),
	},
	Capacity = {
		values = { 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128 },
		firstPrice = 8,
		base = 24,
		growth = 2.5,
		icon = "▣",
		color = rgb(137, 231, 142),
	},
}
local api = {
	pickNames = {
		"Field Pick",
		"Copper Pick",
		"Iron Pick",
		"Gilded Pick",
		"Starfrost Pick",
		"Prismheart Pick",
		"Platinum Pick",
		"Obsidian Edge",
		"Rubyfang Pick",
		"Rimecrest Pick",
		"Cinderforged Pick",
		"Moonsilver Pick",
		"Adamant Pick",
		"Starcaller Pick",
	},
	items = upgrades,
	order = { "Speed", "Power", "Capacity" },
}
assert(
	#api.pickNames == #upgrades.Power.values and #upgrades.Power.values == #Config.StoneGrades,
	"one pick per stone grade"
)
assert(#upgrades.Power.prices == #upgrades.Power.values - 1, "one price per Power upgrade")

function api.price(key, level)
	local item = upgrades[key]
	if level >= #item.values then
		return nil
	end
	if item.prices then
		return item.prices[level]
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

-- What a Power level opens up: its stone grade and the ores that first need it. Mystery ores
-- are counted, not named.
function api.unlocks(level)
	local names, secrets = {}, 0
	for _, ore in Ores.list do
		if not ore.host and ore.hardness == level then
			if ore.secret then
				secrets += 1
			else
				table.insert(names, ore.name)
			end
		end
	end
	if secrets > 0 then
		table.insert(names, if secrets == 1 then "a mystery ore" else secrets .. " mystery ores")
	end
	return Config.StoneGrades[level].name, names
end

-- Ways to say what a Power level opens up, longest first, so a narrow label can use the first
-- that fits: "Ruby, Mithril, Sapphire · Faultsteel Rock", then the ores alone, then "Ruby, Mithril +1".
function api.unlockTexts(level)
	local grade, names = api.unlocks(level)
	if #names == 0 then
		return { grade }
	end
	local texts = { table.concat(names, ", ") .. " · " .. grade, table.concat(names, ", ") }
	for keep = #names - 1, 1, -1 do
		table.insert(texts, table.concat(names, ", ", 1, keep) .. " +" .. #names - keep)
	end
	return texts
end

function api.describe(key, level)
	local v = upgrades[key].values[level]
	if key == "Speed" then
		return string.format("%.2fs / stone", v)
	end
	if key == "Capacity" then
		return v .. " ore"
	end
	return api.unlockTexts(level)[1]
end
return api
