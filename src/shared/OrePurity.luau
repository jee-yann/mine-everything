-- A specimen's grade sets its price when it is dug. Existing ungraded stock
-- keeps its original value and comes out of a mixed stack first.
local Purity = {}
local grades = {
	{ percent = 50, bonus = 0, cutoff = 30 },
	{ percent = 65, bonus = 10, cutoff = 62 },
	{ percent = 80, bonus = 20, cutoff = 85 },
	{ percent = 90, bonus = 35, cutoff = 95 },
	{ percent = 98, bonus = 50, cutoff = 99 },
	{ percent = 100, bonus = 100, cutoff = 100 },
}
local byPercent = {}
for _, grade in grades do
	grade.key = tostring(grade.percent)
	byPercent[grade.key] = grade
end

function Purity.roll(random)
	local roll = random:NextInteger(1, 100)
	for _, grade in grades do
		if roll <= grade.cutoff then return grade.percent end
	end
end

function Purity.range(stock)
	local low, high
	for _, grade in grades do
		if stock and stock[grade.key] then
			low, high = low or grade.percent, grade.percent
		end
	end
	return low, high
end

function Purity.validGrade(key)
	return byPercent[key] ~= nil
end

-- The network form is six counts in grade order. Saves use grade keys so a
-- future price tier can be added without changing the meaning of old finds.
function Purity.encode(stock)
	if not stock or not next(stock) then return nil end
	local counts = {}
	for _, grade in grades do table.insert(counts, tostring(stock[grade.key] or 0)) end
	return table.concat(counts, ",")
end

function Purity.decode(encoded)
	if not encoded then return nil end
	local stock = {}
	for i, value in string.split(encoded, ",") do
		local count = tonumber(value)
		if grades[i] and count and count > 0 then stock[grades[i].key] = count end
	end
	return stock
end

local function unitPrice(ore, grade, broker)
	local percent = 100 + (if grade then grade.bonus else 0)
	local buyer = if broker and not ore.host then 110 else 100
	return math.round(ore.value * percent * buyer / 10000)
end

function Purity.priceRange(ore, broker)
	local low = unitPrice(ore, nil, broker)
	return low, if ore.host then low else unitPrice(ore, grades[#grades], broker)
end

local function priceStack(ore, count, stock, quantity, broker, take)
	local remain = math.clamp(quantity, 0, count)
	local ungraded = count
	if stock then
		for _, n in stock do ungraded -= n end
	end
	local basic = math.min(math.max(ungraded, 0), remain)
	local value = basic * unitPrice(ore, nil, broker)
	remain -= basic
	if stock then
		for _, grade in grades do
			if remain <= 0 then break end
			local have = stock[grade.key] or 0
			local removed = math.min(have, remain)
			if removed > 0 then
				value += removed * unitPrice(ore, grade, broker)
				remain -= removed
				if take then stock[grade.key] = if have > removed then have - removed else nil end
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
