local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Geology = {}
Geology.__index = Geology
-- Each region's ores as cumulative limits on a roll of STEPS * FINE values. The coarse part is the
-- original 0.001% roll (hash % 100000); 16 finer bits from a second hash keep even Starfall's
-- 0.0004% exact. Ores from before the expansion take the first bands in their original order, so
-- a region whose original odds are unchanged keeps the same blocks for a given seed and the new
-- ores only replace what was plain stone.
local STEPS, FINE = 100000, 65536
local SCALE = STEPS * FINE
local LEGACY =
	{ "Coal", "Copper", "Iron", "Gold", "Diamond", "Emerald", "Amethyst", "Sapphire", "Emberglass", "Starfall" }
local order = {}
for _, name in LEGACY do
	table.insert(order, Ores.byName[name])
end
for _, ore in Ores.list do
	if not table.find(LEGACY, ore.name) then
		table.insert(order, ore)
	end
end
local thresholds = {}
for _, layer in Config.Layers do
	local list, total = {}, 0
	for _, ore in order do
		local chance = layer.oreChances[ore.name]
		if chance then
			assert(type(chance) == "number" and chance > 0, layer.name .. ": bad chance for " .. ore.name)
			total += chance
			table.insert(
				list,
				{ limit = math.floor(total / 100 * SCALE + 0.5), material = ore.material, name = ore.name }
			)
		end
	end
	for name in layer.oreChances do
		assert(Ores.byName[name] and not Ores.byName[name].host, layer.name .. " lists an unknown ore " .. name)
	end
	assert(total < 100, layer.name .. " ore chances must leave room for plain stone")
	thresholds[layer] = list
end
Geology.thresholds = thresholds
Geology.scale = SCALE
local function hash(seed, x, y, z)
	local n = bit32.bxor(seed, x * 73856093, y * 19349663, z * 83492791)
	n = bit32.bxor(n, bit32.rshift(n, 16))
	n = bit32.band(n * 1664525, 0xffffffff)
	n = bit32.bxor(n, bit32.rshift(n, 15))
	n = bit32.band(n * 1597333, 0xffffffff)
	return bit32.bxor(n, bit32.rshift(n, 16))
end
function Geology.new(seed)
	return setmetatable({ seed = seed }, Geology)
end
-- Finite winding passages turn through their own rock tile. Their closed ends
-- keep opening one cave from instantiating a whole underground network.
local hollow
local function passage(along, across, row, length, middle, phase)
	if along < 0 or along > length then
		return false
	end
	local t = along / length
	local bend = 3.2 * math.sin(t * 7 + phase) + 1.6 * math.sin(t * 12 + phase)
	local floor = middle + 1.2 * math.sin(t * 5 + phase)
	local width = 1.7 + 1.05 * math.sin(t * 8 + phase) ^ 2
	local taper = math.min(1, (along + 0.6) / 2, (length - along + 0.6) / 2)
	return ((across - bend) / width) ^ 2 + ((row - floor) / 1.85) ^ 2 < taper
end
-- One tile in five holds a different kind of cave instead of a winding passage: a domed chamber,
-- a tall drop through the whole band, or a shape found only in its region (a wide frozen hall in
-- Frostglass Reach, a straight lava tube in Cinderheart Forge, a cluster of small grottos in
-- Glowcap Hollows). Every shape stays inside its tile and band, so caves still never cross a
-- stone-grade boundary or reach the hall.
local function ellipsoid(dx, dy, dz, rx, ry, rz)
	return (dx / rx) ^ 2 + (dy / ry) ^ 2 + (dz / rz) ^ 2 < 1
end
function hollow(h, x, z, row)
	local band = row % 16
	if row < 8 or band < 2 or band > 14 then
		return false
	end
	local cx, cz = 12 + bit32.extract(h, 15, 4), 12 + bit32.extract(h, 19, 4)
	local kind = bit32.extract(h, 13, 2)
	local region = Config.layer((row + 0.5) * Config.Cell).name
	if kind == 3 and region == "Frostglass Reach" then
		-- A wide, low hall with a flat floor.
		return band >= 7 and ellipsoid(x - cx, band - 8, z - cz, 11, 3, 7)
	elseif kind == 3 and region == "Cinderheart Forge" then
		-- A round lava tube running straight across the tile.
		return x >= 3 and x <= 36 and ellipsoid(0, band - 8, z - cz, 1, 2.3, 2.3)
	elseif kind == 3 and region == "Glowcap Hollows" then
		-- Three small grottos joined at their edges.
		for i = 0, 2 do
			local gx, gz = cx + (i - 1) * 5, cz + (if i == 1 then 3 else -1)
			if band >= 6 and ellipsoid(x - gx, band - 8, z - gz, 3.9, 2.6, 3.9) then
				return true
			end
		end
		return false
	elseif kind == 2 then
		-- A long vertical drop with a landing at the bottom.
		local r = 1.6 + bit32.extract(h, 25, 1) * 0.7
		return ellipsoid(x - cx, 0, z - cz, r, 1, r) or (band >= 11 and ellipsoid(x - cx, band - 12.5, z - cz, 4, 1.8, 4))
	end
	-- A domed chamber with a level floor.
	local rx, rz = 5 + bit32.extract(h, 25, 2), 5 + bit32.extract(h, 27, 2)
	local cy = 7 + bit32.extract(h, 23, 2)
	return band >= cy - 2 and ellipsoid(x - cx, band - cy, z - cz, rx, 3.4, rz)
end

function Geology:isCave(p)
	local row = -1 - p.Y
	if row < 3 then
		return false
	end
	local y = Config.FloorY - (row + 0.5) * Config.Cell
	if Config.strength(y + Config.Cell) ~= Config.strength(y - Config.Cell) then
		return false
	end
	if row < 12 and math.abs(p.X) < 12 and p.Z >= -41 and p.Z <= 2 then
		return passage(-p.Z - 7, p.X, row, 30, 4.8, 0)
	end
	local tx, tz, ty = math.floor(p.X / 40), math.floor(p.Z / 40), math.floor(row / 16)
	local h = hash(self.seed, tx, ty, tz)
	if h % 5 == 0 then
		return hollow(h, p.X % 40, p.Z % 40, row)
	end
	local x, z = p.X % 40, p.Z % 40
	if bit32.btest(h, 8) then
		x, z = z, x
	end
	return passage(z - 3, x - 18, row % 16, 32, 7 + bit32.extract(h, 4, 2), bit32.extract(h, 8, 5) * 0.2)
end
function Geology:material(p)
	if p.Y >= 0 then
		return Enum.Material.Cobblestone
	end
	if -p.Y <= Config.DirtLayers then
		-- The island foundation encloses the shallow dirt. Below it, headings
		-- can run under any part of the island without opening its surface.
		return if Config.inHall((p + Vector3.one * 0.5) * Config.Cell)
			then Ores.byName.Dirt.material
			else Enum.Material.Cobblestone
	end
	if self:isCave(p) then
		return Enum.Material.Air
	end
	local layer = Config.layer((-p.Y - 0.5) * Config.Cell)
	local roll = Geology.roll(self.seed, p.X, p.Y, p.Z)
	for _, entry in thresholds[layer] do
		if roll < entry.limit then
			return entry.material
		end
	end
	return layer.material
end
-- Sample one centreline cell near the end of a natural passage. The small
-- lava channel in some deep passages leaves the other side safe to walk.
function Geology:feature(p)
	if not self:isCave(p) or self:isCave(p - Vector3.yAxis) then
		return nil
	end
	local row = -1 - p.Y
	local along, across, phase, length, h
	if row < 12 and math.abs(p.X) < 12 and p.Z >= -41 and p.Z <= 2 then
		along, across, phase, length, h = -p.Z - 7, p.X, 0, 30, 0
	else
		h = hash(self.seed, math.floor(p.X / 40), math.floor(row / 16), math.floor(p.Z / 40))
		if h % 5 == 0 then
			-- Chambers, drops and regional caves carry no crates, eggs or lava.
			return nil
		end
		local x, z = p.X % 40, p.Z % 40
		if bit32.btest(h, 8) then
			x, z = z, x
		end
		along, across, phase, length = z - 3, x - 18, bit32.extract(h, 8, 5) * 0.2, 32
	end
	local t = along / length
	local middle = math.round(3.2 * math.sin(t * 7 + phase) + 1.6 * math.sin(t * 12 + phase))
	if along == length - 3 and across == middle and h % 3 ~= 1 then
		return if row >= 185 and h % 7 == 0 then "Egg" else "Cache"
	elseif
		((row >= 90 and row < 340) or (row >= 400 and row < 470))
		and h % 3 == 0
		and along >= 12
		and along <= 16
		and across == middle - 1
	then
		return "Lava"
	end
	return nil
end
Geology.hash = hash
-- A cell's ore roll, 0 to SCALE - 1: the original coarse roll, then the fine bits.
function Geology.roll(seed, x, y, z)
	local fine = bit32.rshift(hash(bit32.bxor(seed, 0x2545F491), x, y, z), 16)
	return hash(seed, x, y, z) % STEPS * FINE + fine
end
-- Coordinates are relative to the entrance in studs, as in a Studio map probe.
function Geology:sample(x, y, z)
	return self:material((Vector3.new(x, y - Config.FloorY, z) / Config.Cell):Floor())
end
return Geology
