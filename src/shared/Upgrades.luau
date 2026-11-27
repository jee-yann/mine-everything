local rgb = Color3.fromRGB
local Ores = require(script.Parent.Ores)
local Config = require(script.Parent.GameConfig)
-- Power level N mines stone grade N (GameConfig.StoneGrades) and any ore with hardness N or less.
-- Power prices are listed one by one: each was tuned so a normal player spends a set time in
-- each region (minutes near the top, an hour or two at the bottom).
-- Speed and Capacity have long curves so the workshop keeps paying out for months: early levels
-- are cheap and frequent, mid levels slow down, and the last levels are a long grind. Prices grow
-- geometrically from `base` by `growth`.
-- Speed: 30 levels, each one you can feel: every level cuts about 5% faster than the last, from 0.90 s
-- per plain stone at level 1 to 0.20 s at level 30 (4.5x in all). The start is slower than it was
-- (the old level 1 was 0.80 s) so the first upgrades matter.
local speedValues = {}
local speedLevels, slowest, fastest = 30, 0.9, 0.2
for level = 1, speedLevels do
	speedValues[level] = math.round(1000 * slowest * (fastest / slowest) ^ ((level - 1) / (speedLevels - 1))) / 1000
end
-- Capacity: quadratic growth, 8 + 6(L-1) + 2(L-1)^2 slots (8, 16, 28, 44, 64 ... 3,284 at 40).
-- Capacity: 8 + 8(L-1) + 0.35(L-1)^2 slots, rounded: 8, 16, 25, 35, 46 ... 108 at 10, 286 at 20,
-- 852 at 40. Packs used to reach 3,284, so big that trips stopped mattering.
local capacityValues = {}
for level = 1, 40 do
	capacityValues[level] = math.round(8 + 8 * (level - 1) + 0.35 * (level - 1) ^ 2)
end
local upgrades = {
	Speed = {
		values = speedValues,
		base = 30,
		growth = 1.45,
		icon = "»",
		color = rgb(255, 200, 80),
	},
	Power = {
		values = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 },
		-- Tuned with the crater's Starfall odds so a focused free player reaches the Starcaller Pick in
		-- about an hour and a half and finds their first Starfall in about two (a casual one in about
		-- three). The top pick was 6.8M before Starfall moved to the crater.
		prices = { 110, 400, 450, 750, 1150, 1950, 3300, 5700, 9000, 25500, 48000, 69000, 168000 },
		icon = "◆",
		color = rgb(255, 147, 100),
	},
	Capacity = {
		values = capacityValues,
		firstPrice = 8,
		base = 24,
		growth = 1.5,
		icon = "▣",
		color = rgb(137, 231, 142),
	},
}
-- Saves from before the long curves (progression 1) stored levels on the old, shorter tables.
-- They are moved to the first new level that is at least as good.
local legacy = {
	Speed = { 0.80, 0.64, 0.51, 0.40, 0.32, 0.25, 0.20, 0.16, 0.13, 0.11 },
	Capacity = { 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128 },
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

-- Saves from before the 30-level Speed curve (progression 2) held a level on the old 100-level one,
-- 0.8 * level^-0.301 seconds. They move to the first new level at least as fast.
function api.migrateSpeed(level)
	local old = 0.8 * math.clamp(level, 1, 100) ^ (-math.log(4) / math.log(100))
	for newLevel, value in speedValues do
		if value <= old + 1e-9 then return newLevel end
	end
	return #speedValues
end

-- The 100-level Speed curve and the bigger Capacity curve that progression 2 and 3 saves were on.
local oldSpeed, oldCapacity = {}, {}
for level = 1, 100 do
	oldSpeed[level] = 0.8 * level ^ (-math.log(4) / math.log(100))
end
for level = 1, 40 do
	oldCapacity[level] = 8 + 6 * (level - 1) + 2 * (level - 1) ^ 2
end

-- A save's Capacity level on the old curve moves to the first new level at least as roomy, or the top.
function api.migrateCapacity(level)
	local old = oldCapacity[math.clamp(level, 1, 40)]
	for newLevel, value in capacityValues do
		if value >= old then return newLevel end
	end
	return #capacityValues
end

function api.migrateLevel(key, level)
	local old = legacy[key] and legacy[key][level]
	if not old then
		return level
	end
	-- They moved onto the old long curves then (migrateSpeed and migrateCapacity take them on to today's).
	local values = if key == "Speed" then oldSpeed else oldCapacity
	for newLevel, value in values do
		if (key == "Speed" and value <= old) or (key == "Capacity" and value >= old) then
			return newLevel
		end
	end
	return #values
end

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

-- A benchmark for Speed: seconds to cut a Starfall in the crater (its first row) with the top pick,
-- at this Speed level and nothing else, the same for every miner.
function api.starfallSeconds(level)
	local crater = Config.Layers[#Config.Layers].depthBlocks
	local strength = Config.strength(Config.FloorY - crater * Config.Cell - Config.Cell / 2)
	return Ores.cutTime(speedValues[level], Ores.byName.Starfall, strength, 0, nil, #upgrades.Power.values)
end

-- How much faster Speed level `level` cuts than the level before it, in percent (0 at level 1).
function api.speedGain(level)
	if level <= 1 then return 0 end
	return math.round((speedValues[level - 1] / speedValues[level] - 1) * 100)
end

function api.describe(key, level)
	local v = upgrades[key].values[level]
	if key == "Speed" then
		return string.format("%.2fs / stone", v)
	end
	if key == "Capacity" then
		return v .. " block limit"
	end
	return api.unlockTexts(level)[1]
end
return api
