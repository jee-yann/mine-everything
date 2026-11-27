-- A specimen's purity sets its price when it is dug. Purity is an exact percentage with three
-- decimals, from 50.000 to 100.000. The roll keeps the original six bands and their odds; inside
-- a band the exact value is uniform. Price bonuses run smoothly between the bands' anchors, so a
-- 64.999% piece is worth a hair less than a 65.000% one, and a perfect 100.000% doubles the price.
-- Existing ungraded stock keeps its original value and comes out of a mixed stack first. Saves
-- key each stack by its purity text ("65.432"); old whole-number keys ("65") stay valid.
local Purity = {}
local bands = {
	{ low = 50, high = 64.999, cutoff = 30 },
	{ low = 65, high = 79.999, cutoff = 62 },
	{ low = 80, high = 89.999, cutoff = 85 },
	{ low = 90, high = 97.999, cutoff = 95 },
	{ low = 98, high = 99.999, cutoff = 99 },
	{ low = 100, high = 100, cutoff = 100 },
}
-- Price bonus (percent) at each purity; values in between are interpolated.
local anchors = { { 50, 0 }, { 65, 10 }, { 80, 20 }, { 90, 35 }, { 98, 50 }, { 99.999, 60 }, { 100, 100 } }
Purity.floor, Purity.ceiling = 50, 100

local function round3(x)
	return math.floor(x * 1000 + 0.5) / 1000
end

-- The bonus a purity adds to the base price, in percent (0 to 100).
function Purity.bonus(percent)
	if not percent then
		return 0
	end
	if percent <= anchors[1][1] then
		return anchors[1][2]
	end
	for i = 2, #anchors do
		local a, b = anchors[i - 1], anchors[i]
		if percent <= b[1] then
			return a[2] + (b[2] - a[2]) * (percent - a[1]) / (b[1] - a[1])
		end
	end
	return anchors[#anchors][2]
end

-- Purity text for players, to one decimal and rounded down so only a perfect piece reads "100%":
-- 65.432 reads "65.4%", 99.999 reads "99.9%". Prices still use the exact value.
function Purity.text(percent)
	if percent >= 100 then
		return "100%"
	end
	return string.format("%.1f%%", math.floor(percent * 10) / 10)
end

-- The sale multiplier a purity gives, as text: "×1.10".
function Purity.multiplierText(percent)
	return string.format("×%.2f", 1 + Purity.bonus(percent) / 100)
end

function Purity.roll(random)
	local roll = random:NextInteger(1, 100)
	for _, band in bands do
		if roll <= band.cutoff then
			if band.low == band.high then
				return band.low
			end
			local steps = math.round((band.high - band.low) * 1000)
			return round3(band.low + random:NextInteger(0, steps) / 1000)
		end
	end
end

-- Whether `value` (a number or its text) is a purity a save may hold.
function Purity.valid(value)
	local percent = tonumber(value)
	return percent ~= nil
		and percent >= Purity.floor
		and percent <= Purity.ceiling
		and round3(percent) == percent
end

function Purity.validGrade(key)
	return type(key) == "string" and Purity.valid(key) and tostring(tonumber(key)) == key
end

function Purity.key(percent)
	return tostring(round3(percent))
end

-- The purities in a stack, lowest first.
local function sortedKeys(stock)
	local keys = {}
	if stock then
		for key in stock do
			table.insert(keys, key)
		end
	end
	table.sort(keys, function(a, b)
		return tonumber(a) < tonumber(b)
	end)
	return keys
end

function Purity.range(stock)
	local keys = sortedKeys(stock)
	if #keys == 0 then
		return nil, nil
	end
	return tonumber(keys[1]), tonumber(keys[#keys])
end

-- The network form lists "purity:count" pairs, lowest purity first.
function Purity.encode(stock)
	if not stock or not next(stock) then
		return nil
	end
	local parts = {}
	for _, key in sortedKeys(stock) do
		table.insert(parts, key .. ":" .. tostring(stock[key]))
	end
	return table.concat(parts, ",")
end

function Purity.decode(encoded)
	if not encoded then
		return nil
	end
	local stock = {}
	for _, pair in string.split(encoded, ",") do
		local key, value = string.match(pair, "^([%d%.]+):(%d+)$")
		local count = tonumber(value)
		if key and Purity.validGrade(key) and count and count > 0 then
			stock[key] = count
		end
	end
	return stock
end

local function unitPrice(ore, percent, broker)
	local scale = 100 + Purity.bonus(percent)
	local buyer = if broker and not ore.host then 110 else 100
	return math.round(ore.value * scale * buyer / 10000)
end
Purity.unitPrice = unitPrice

function Purity.priceRange(ore, broker)
	local low = unitPrice(ore, nil, broker)
	return low, if ore.host then low else unitPrice(ore, Purity.ceiling, broker)
end

local function priceStack(ore, count, stock, quantity, broker, take)
	local remain = math.clamp(quantity, 0, count)
	local ungraded = count
	if stock then
		for _, n in stock do
			ungraded -= n
		end
	end
	local basic = math.min(math.max(ungraded, 0), remain)
	local value = basic * unitPrice(ore, nil, broker)
	remain -= basic
	for _, key in sortedKeys(stock) do
		if remain <= 0 then
			break
		end
		local have = stock[key]
		local removed = math.min(have, remain)
		if removed > 0 then
			value += removed * unitPrice(ore, tonumber(key), broker)
			remain -= removed
			if take then
				stock[key] = if have > removed then have - removed else nil
			end
		end
	end
	return value
end

function Purity.quote(ore, count, stock, quantity, broker)
	return priceStack(ore, count, stock, quantity, broker, false)
end

function Purity.remove(ore, count, stock, quantity, broker)
	return priceStack(ore, count, stock, quantity, broker, true)
end

return Purity
