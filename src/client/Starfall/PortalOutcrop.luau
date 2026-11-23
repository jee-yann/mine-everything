-- A cross-section of the impact breccia, left in the east pier when the gallery was cut.
-- Every coordinate is in the editable island's frame. The same mineral paths and
-- broken contour are photographed in both eras.
local S = require(script.Parent.Scenery)
local V, CF = Vector3.new, CFrame.new
local Outcrop = { fork = V(10.55, 32.0, 9.68) }

local outline = {
	{ -2.42, -7.45 }, { 2.97, -7.45 }, { 2.64, -4.07 }, { 2.81, -1.64 },
	{ 2.42, -0.80 }, { 2.56, 1.05 }, { 1.49, 2.25 }, { 0.77, 2.20 },
	{ 0.36, 1.79 }, { -0.39, 2.45 }, { -1.16, 2.48 }, { -2.36, 1.32 },
	{ -2.12, -0.11 }, { -2.49, -0.57 }, { -2.13, -3.61 },
}
local matrix = { "453D50", "554B5A", "534754", "695A67", "635462" }
local weathered = { "716774", "796F7C", "726975", "847786", "807482" }
local function front(x, y, depth)
	return Outcrop.fork + V(x, y, (depth or 0) - 0.061 * x - 0.008 * y)
end

-- Each station records the two jagged boundaries of the same vein. Narrow
-- quartz selvages remain legible around its wider amethyst core in daylight.
local stem = {
	{ 0.35, -5.55, 0.05 }, { 0.34, -4.89, 0.14 }, { 0.06, -4.21, 0.15 },
	{ 0.28, -3.58, 0.22 }, { 0.10, -3.25, 0.14 }, { 0.29, -2.56, 0.20 },
	{ -0.27, -1.84, 0.29 }, { -0.26, -1.16, 0.21 }, { 0.13, -0.73, 0.34 },
	{ 0, 0, 0.30 }, { -0.53, 0.46, 0.25 }, { -0.64, 0.95, 0.17 },
	{ -1.14, 1.43, 0.12 }, { -1.33, 1.78, 0.025 },
}
local fork = {
	{ 0, 0, 0.28 }, { 0.51, 0.08, 0.29 }, { 0.80, 0.53, 0.19 },
	{ 1.20, 0.71, 0.13 }, { 1.37, 0.96, 0.09 }, { 1.57, 1.05, 0.025 },
}
local offshoot = {
	{ -0.26, -1.84, 0.12 }, { -0.60, -1.81, 0.09 }, { -0.89, -1.51, 0.07 }, { -1.10, -1.42, 0.008 },
}
local function ribbon(root, stations, name, multiplier, lift, ink, material, core)
	local previousA, previousB
	for i, row in stations do
		local prev = stations[math.max(1, i - 1)]
		local following = stations[math.min(#stations, i + 1)]
		local normal = Vector2.new(following[2] - prev[2], prev[1] - following[1]).Unit
		-- The brittle host breaks away unevenly. Each mineral tapers against
		-- a different edge, even where the veins share an optical center.
		local left = row[3] * multiplier * (0.67 + 0.33 * math.sin(i * 1.73))
		local right = row[3] * multiplier * (0.76 + 0.24 * math.sin(i * 2.64))
		local offset = if core then row[3] * 0.29 * math.sin(i * 0.88) else 0
		local a = front(row[1] + normal.X * (offset - left), row[2] + normal.Y * (offset - left), lift)
		local b = front(row[1] + normal.X * (offset + right), row[2] + normal.Y * (offset + right), lift)
		if previousA and (not core or i % 5 ~= 1) then
			S.facet(root, name, previousA, previousB, a, ink[(i - 1) % #ink + 1], material)
			S.facet(root, name, previousB, b, a, ink[i % #ink + 1], material)
		end
		previousA, previousB = a, b
	end
end

-- A seam laid open where several planes meet. The pocket has an uneven
-- feldspar rim, shaded amethyst walls and two flat crystal tables at its lip.
local function pocket(root, modern)
	local ring = {
		{ -0.32,-0.08 }, { -0.21,-0.34 }, { 0.08,-0.49 }, { 0.35,-0.25 },
		{ 0.37,-0.02 }, { 0.47,0.13 }, { 0.19,0.37 }, { -0.04,0.32 },
		{ -0.29,0.39 }, { -0.40,0.18 },
	}
	local walls = if modern then { "9777AF", "B698C4", "735E8D", "8B70A1", "9A82B7" }
		else { "7853AB", "AC7FD2", "624790", "8860AD", "A786C8" }
	for i, q in ring do
		local r = ring[i % #ring + 1]
		local from, to = front(q[1], q[2], 0.08), front(r[1], r[2], 0.08)
		local a, b = front(q[1] * 0.58 + 0.045, q[2] * 0.58 - 0.02, 0.042),
			front(r[1] * 0.58 + 0.045, r[2] * 0.58 - 0.02, 0.042)
		local tone = walls[i % #walls + 1]
		S.facet(root, "Broken amethyst wall", from, to, a, tone)
		S.facet(root, "Quartz pocket", to, a, b, walls[(i + 1) % #walls + 1])
		S.facet(root, "Amethyst table", a, b, front(0.07, -0.07, 0.048), tone,
			if modern or i % 3 == 0 then Enum.Material.SmoothPlastic else Enum.Material.Neon)
	end
	for _, row in { { -0.35,0.08,0.09,0.12 }, { 0.20,-0.29,0.13,0.08 } } do
		local x, y, w, h = table.unpack(row)
		S.facet(root, "Fresh cleavage", front(x,y,0.10), front(x+w,y+h,0.11), front(x+w*1.36,y+h*0.58,0.11),
			if modern then "C9B4CF" else "D9B9EA", if modern then Enum.Material.SmoothPlastic else Enum.Material.Neon)
	end
end

-- The slab dips into the same broken rim that runs back to the impact basin.
-- The irregular toe and overlapping beds replace the free-standing silhouette
-- with a cross-section of the slope. Quarrying removes this mass on the live pier.
local function talus(root)
	local across = { -12.6, -9.2, -7.4, -4.8, -2.1, 0.2, 2.6, 4.3, 6.2, 9.0, 12.9 }
	local rows = {}
	for band, section in {
		{ 3.1, 25.45 }, { 1.1, 26.62 }, { -1.1, 28.65 }, { -3.8, 30.05 },
		{ -6.2, 31.20 }, { -9.9, 32.5 }, { -14.3, 33.3 },
	} do
		local row = {}
		for i, x in across do
			local taper = math.clamp(1 - math.abs(x - 0.3) / 15, 0, 1)
			local y = 25.10 + (section[2] - 25.10) * (0.22 + 0.78 * taper)
			local z = section[1] + 0.73 * math.sin(i * 1.61 + band * 0.59)
			row[i] = V(10.55 + x + math.sin(i * 1.07 + band) * 0.31, y + math.sin(i * 1.41 + band * 0.61) * 0.42, 9.68 + z)
		end
		rows[band] = row
		if band == 1 then continue end
		for i = 1, #row - 1 do
			local prev, next = rows[band - 1], i + 1
			local bed = { "504653", "62525C", "614E56", "554953", "6D5A61", "5D5058" }
			local tone = bed[(i + band) % #bed + 1]
			S.facet(root, "Uplifted bedding", prev[i], prev[next], row[i], tone)
			S.facet(root, "Uplifted bedding", prev[next], row[i], row[next], bed[(i + band + 1) % #bed + 1])
			if band >= 3 and (i + band) % 3 == 0 then
				local a = row[i]:Lerp(row[next], 0.14)
				local b = row[i]:Lerp(row[next], 0.72)
				S.facet(root, "Exposed lamination", a + V(0,0.023,0), b + V(0,0.023,0), a:Lerp(prev[i],0.08) + V(0,0.023,0), "84727A")
			end
		end
	end
	for i, q in {
		{ -3.7,27.30,-0.8,1.7 }, { 3.8,27.55,-0.8,2.0 }, { -6.3,26.72,0,1.45 },
		{ -2.8,26.60,0.8,0.9 }, { 5.5,26.8,0.45,1.21 }, { 1.95,26.3,1.50,0.69 },
		{ -5.1,28.31,-3.0,1.72 }, { 3.2,28.53,-2.4,1.6 }, { 1.1,26.05,1.9,0.64 },
	} do
		local x, y, z, r = table.unpack(q)
		local at = V(10.55+x,y,9.68+z)
		local a, b = at + V(-r,-0.32*r,0.76*r), at + V(0.87*r,-0.35*r,0.55*r)
		local c, d = at + V(-0.54*r,0.14*r,-0.69*r), at + V(0.78*r,0.07*r,-0.69*r)
		local e = at + V(0.15*r,0.65*r,0)
		local stone = if i % 2 == 0 then "68565C" else "73616B"
		S.facet(root,"Spalled rock",a,b,e,"4D4450")
		S.facet(root,"Spalled rock",a,c,e,stone)
		S.facet(root,"Spalled rock",c,d,e,"77616D")
		S.facet(root,"Spalled rock",d,b,e,stone)
	end
end

function Outcrop.new(modern)
	local root = S.group(if modern then "Weathered fork in the gallery pier" else "Exposed impact vein")
	local rocks = if modern then weathered else matrix
	local center = front(0.5, -1.5, -0.12)
	for i, q in outline do
		local next = outline[i % #outline + 1]
		local a, b = front(q[1], q[2], -0.11), front(next[1], next[2], -0.11)
		local shoulderA = front(q[1] * 1.13 + 0.25, q[2] + 0.28, -0.72)
		local shoulderB = front(next[1] * 1.13 + 0.25, next[2] + 0.28, -0.72)
		local rearA = front(q[1] * 1.26 + 0.38, q[2] - 0.14, -2.60)
		local rearB = front(next[1] * 1.26 + 0.38, next[2] - 0.14, -2.60)
		S.facet(root, "Fracture plane", center, a, b, rocks[(i - 1) % #rocks + 1], Enum.Material.Slate)
		S.facet(root, "Chipped lip", a, b, shoulderA, rocks[i % #rocks + 1])
		S.facet(root, "Chipped lip", b, shoulderA, shoulderB, rocks[(i + 2) % #rocks + 1])
		S.facet(root, "Buried edge", shoulderA, shoulderB, rearA, rocks[(i + 1) % #rocks + 1])
		S.facet(root, "Buried edge", shoulderB, rearA, rearB, rocks[(i + 1) % #rocks + 1])
	end
	-- Pale angular inclusions and split bedding stay attached to the stone.
	-- Their variable grain is visible in the hand-sized matches at the join.
	local chips = {
		{ -0.87, 1.82, 0.22, 0.27 }, { -1.03, 1.08, 0.12, 0.28 },
		{ -1.57, 0.82, -0.21, 0.16 }, { -0.15, 0.78, 0.16, 0.24 },
		{ 0.71, 0.87, 0.18, 0.14 }, { 1.56, 0.59, 0.30, 0.10 },
		{ 1.11, 0.12, 0.13, 0.16 }, { -0.63, -0.62, -0.16, 0.18 },
		{ 0.46, -1.50, 0.22, 0.12 }, { -0.79, -2.16, 0.14, 0.25 },
		{ 0.47, -2.61, 0.22, 0.11 }, { 0.24, -3.56, 0.14, 0.14 },
	}
	for i, chip in chips do
		local x, y, w, h = table.unpack(chip)
		local a, b = front(x, y, -0.067), front(x + w, y + h, -0.067)
		local c = front(x + w * 0.63, y + h * 1.21, -0.067)
		local d = front(x - w * 0.47, y + h * 0.32, -0.067)
		local tint = if modern then (if i % 3 == 0 then "867888" else "A093A2")
			else (if i % 3 == 0 then "927C98" else "6F5A76")
		S.facet(root, "Angular mineral grain", a, b, c, tint)
		S.facet(root, "Angular mineral grain", a, c, d, tint)
	end
	local cool = if modern then { "AE8FC4", "A88BC3", "9074B5" } else { "815BAF", "986CC5", "8B63C0" }
	local glint = if modern then { "D7C6D9", "CDB7DA" } else { "DEB9F2", "C8A4EC" }
	local marl = if modern then { "A39A9F", "908891" } else { "745E82", "807187" }
	for _, path in { stem, fork, offshoot } do
		ribbon(root, path, "Pale host quartz", 1.45, -0.055, marl, Enum.Material.SmoothPlastic)
		ribbon(root, path, "Violet mineral", 1.00, -0.02, cool, if modern then Enum.Material.Marble else Enum.Material.Neon)
		ribbon(root, path, "Quartz cleavage", 0.36, 0.008, glint, if modern then Enum.Material.SmoothPlastic else Enum.Material.Neon, true)
	end
	pocket(root, modern)
	-- Breccia tongues interrupt the colored fill in three places. The host
	-- rock is built in front of the vein here, with a raised, lit break edge.
	for _, q in {
		{ -0.68,0.65, -0.23,0.54, -0.63,0.40 }, { 0.29,-0.79, -0.02,-0.69, 0.18,-0.53 },
		{ 0.49,0.05, 0.69,0.23, 0.65,-0.07 }, { -0.30,-2.01, -0.05,-2.08, -0.29,-2.19 },
	} do
		local a, b, c = front(q[1],q[2],0.052),front(q[3],q[4],0.09),front(q[5],q[6],0.06)
		S.facet(root, "Overlapping shale", a, b, c, if modern then "776C79" else "5D4F60")
		S.facet(root, "Chipped shale edge", a, b, b - V(0,0.015,0.046), if modern then "AA9CA4" else "917A92")
	end
	if modern then
		local strap = S.part(root, "Forged survey strap", CF(front(0.13, -4.22, 0.08)) * CFrame.Angles(0, 0.06, 0.12),
			V(3.40, 0.27, 0.18), "566168", Enum.Material.Metal)
		for _, x in { -1.37, 1.37 } do
			S.part(root, "Brass survey rivet", strap.CFrame * CF(x, 0, 0.12), V(0.15, 0.15, 0.10), "C8A777", Enum.Material.Metal)
		end
	else
		talus(root)
		local pin = S.part(root, "Heat in the opened fault", CF(Outcrop.fork), V(0.02, 0.02, 0.02), "FFFFFF")
		pin.Transparency = 1
		S.light(pin, "BB92E9", 7, 0.65)
	end
	return root
end

return Outcrop
