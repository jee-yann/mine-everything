-- An aligned pair of limestone fracture surfaces cut from one weathered cobble.
-- Generate at toolmaker scale so very small detail survives CSG quantization.
local S = require(game.ReplicatedStorage.Scenery)
local V, CF = Vector3.new, CFrame.new
local scale = 36
local art = Instance.new("Model", workspace)
art.Name = "ProspectorProof"
local origin = S.part(art, "Datum", CF(), V(0.1, 0.1, 0.1), "FFFFFF")
origin.Transparency, origin.CastShadow, art.PrimaryPart = 1, false, origin
local stock = Instance.new("Folder", workspace)
local function triangle(parent, name, a, b, c, col)
	S.facet(parent, name, a * scale, b * scale, c * scale, col)
end
local function bake(name, tint)
	local items = stock:GetChildren()
	local first = table.remove(items, 1)
	local solid = game:GetService("GeometryService"):UnionAsync(first, items, {
		SplitApart = false,
		CollisionFidelity = Enum.CollisionFidelity.Box,
		RenderFidelity = Enum.RenderFidelity.Precise,
	})[1]
	solid.Name, solid.SmoothingAngle = name, 0
	solid.UsePartColor = tint ~= nil
	solid.CastShadow = true
	if tint then
		solid.Color = Color3.fromHex(tint)
	end
	solid.Material = Enum.Material.SmoothPlastic
	solid.Anchored, solid.CanTouch, solid.CanCollide, solid.CanQuery = true, false, false, false
	solid.Parent = art
	stock:ClearAllChildren()
	return solid
end
local shell = { "85816E", "9C9280", "B4AB8D", "B2A590", "8A877D", "A49A83", "AFAC9B", "8E908D", "AAA28F" }
local rind = { "B99E77", "B6AE94", "D9C99C", "B4A884", "9C957E", "CABC9D" }
local chalk = { "DDD7B0", "CCC6B3", "BDC2B0", "D6CAB3", "E5DAB8", "D0C8A9" }
local pocket = { "415A53", "52615A", "687366", "445951", "84917F", "657065" }
local n = 14
local shared = {}
for k = 1, n do
	local t = (k - 1) * math.pi * 2 / n
	-- y/z cross-section runs from the front lip, across crown and rear.
	local y = math.sin(t) * (0.87 + 0.06 * math.sin(3 * t + 0.4)) - 0.04
	local z = math.cos(t) * (0.89 + 0.09 * math.cos(2 * t - 0.2)) + 0.08 * math.sin(2 * t)
	shared[k] = V(0.073 * math.sin(3 * t + 0.4) + 0.031 * math.cos(5 * t), y, z)
end
local function ring(a, b, palette, shift)
	for k, p in a do
		local j = k % #a + 1
		triangle(stock, "Facet", p, a[j], b[k], palette[1 + (k + shift) % #palette])
		triangle(stock, "Facet", a[j], b[j], b[k], palette[1 + (k + shift + 2) % #palette])
	end
end
for _, side in { -1, 1 } do
	local previous = shared
	local sole = {}
	for _, v in shared do
		if v.Y < -0.39 then
			table.insert(sole, v)
		end
	end
	for layer, profile in { { 0.23, 1.07 }, { 0.68, 0.97 }, { 1.10, 0.71 }, { 1.35, 0.34 } } do
		local points = {}
		for k, edge in shared do
			local wave = math.sin((k + side * 0.7) * 1.84 + layer) * 0.065
			local x = side * (profile[1] + wave) + 0.06 * math.cos(k + layer)
			points[k] = V(
				x,
				edge.Y * profile[2] + 0.07 * math.sin(k * 1.27 + layer),
				edge.Z * profile[2] + 0.065 * math.cos(k * 0.9 + side)
			)
		end
		for _, v in points do
			if v.Y < -0.39 then
				table.insert(sole, v)
			end
		end
		ring(previous, points, if layer == 1 then rind else shell, layer + 2)
		previous = points
	end
	local tip = V(side * 1.42, 0.03, side * -0.12)
	for k, p in previous do
		triangle(stock, "Rind", p, previous[k % n + 1], tip, shell[k % #shell + 1])
	end
	-- A narrow line of mineralized weathering follows the true continuing
	-- fracture across both matching shelves; the front half of the split
	-- also carries three pale, hand-cut tool marks.
	for k = 1, 6 do
		local a, b = shared[k], shared[k + 1]
		local outward = V(0, a.Y + 0.04, a.Z).Unit * 0.012
		local v = a + outward
		local w = b + outward
		triangle(
			stock,
			"Scored lip",
			v,
			w,
			v + V(side * (0.025 + 0.006 * (k % 2)), 0, 0),
			if k % 2 == 0 then "5F645D" else "B9AD88"
		)
	end
	local interior, throat, cavity = {}, {}, {}
	for k, v in shared do
		local var = 0.038 * math.cos(k * 2 + side)
		interior[k] = V(v.X + side * 0.047, v.Y * 0.86, v.Z * 0.86)
		throat[k] = V(v.X * 0.37 + side * (0.19 + var), v.Y * 0.64 - 0.03, v.Z * 0.59)
		cavity[k] = V(side * (0.43 + var), v.Y * 0.46 - 0.13, v.Z * 0.39)
	end
	ring(shared, interior, rind, 1)
	ring(interior, throat, chalk, 3)
	ring(throat, cavity, pocket, 1)
	-- A patch of dark chlorite traverses the back of the split pocket.
	-- Build broad, staggered chips instead of radial triangles meeting at a pinwheel.
	local middle = {}
	for k, p in cavity do
		middle[k] =
			V(side * (0.49 + 0.017 * math.sin(k * 1.77)), p.Y * 0.43 - 0.02 + 0.022 * math.cos(k), p.Z * 0.47 + 0.025)
	end
	local chlorite = { "596B61", "58695C", "66766A", "53645C", "677469" }
	ring(cavity, middle, chlorite, 1)
	for k, v in middle do
		triangle(stock, "Chlorite", v, middle[k % n + 1], V(side * 0.52, -0.095, 0.07), "617165")
	end
	for i = 1, 9 do
		local a = i * 2.39 + side * 0.7
		local rr = 0.11 + 0.18 * math.sqrt(i / 9)
		local c = V(side * (0.462 - 0.045 * (i % 3)), -0.12 + rr * math.sin(a), rr * math.cos(a))
		local dx = V(0, 0.025 + 0.007 * (i % 3), 0.037)
		triangle(stock, "Calcite inclusion", c - dx, c + dx, c + V(-side * 0.057, 0.027, -0.019), "9EAC99")
		triangle(
			stock,
			"Calcite inclusion",
			c + dx,
			c + V(-side * 0.057, 0.027, -0.019),
			c + V(0, -0.014, 0.055),
			"839988"
		)
	end
	-- Calcite teeth form a natural band above the darker emerald-bearing pocket.
	for k = 1, 12 do
		local a = (k - 0.4) * math.pi * 2 / 12
		local mid = V(side * 0.175, 0.565 * math.sin(a) - 0.06, 0.545 * math.cos(a))
		local along = V(0, math.cos(a), -math.sin(a))
		local peak = mid + V(-side * 0.074, -0.088 * math.sin(a), -0.092 * math.cos(a))
		local v, w = mid - along * 0.044, mid + along * 0.044
		triangle(stock, "Calcite", v, w, peak, "D7D2B3")
		triangle(stock, "Calcite", v, peak, mid + V(side * 0.10, -0.04, 0), "A6B4A5")
	end
	local block = bake(if side == -1 then "Left" else "Right")
	for i, v in sole do
		block:SetAttribute("Contact" .. i, v)
	end
end
-- A nonmoving mineral matrix emerges between the parted rocks. The main
-- emerald is a six-sided beryl prism with a broad natural terminus, not a
-- jewellery-cut diamond. Unequal companions record its original growth.
local bed, waist, foot = {}, {}, {}
for i = 1, 10 do
	local a = (i - 0.7) * math.pi * 2 / 10
	local x, z = math.cos(a) * (0.54 + 0.04 * math.sin(3 * a)), math.sin(a) * 0.45
	bed[i] = V(x, -0.57 + 0.049 * math.sin(i * 1.9), z)
	waist[i] = V(x * 1.045 - 0.043, -0.757 + 0.034 * math.sin(i * 2.3), z * 0.98 + 0.015)
	foot[i] = V(x * 0.91 - 0.029, -0.93, z * 0.85 + 0.018)
end
ring(foot, waist, shell, 3)
ring(waist, bed, rind, 1)
for i, p in bed do
	local j = i % #bed + 1
	triangle(stock, "Matrix", p, bed[j], V(-0.075, -0.385, 0.04), pocket[i % #pocket + 1])
	triangle(stock, "Underside", foot[i], foot[j], V(-0.03, -0.93, 0.016), "877D69")
end
bake("Matrix")
local deep = { "075C43", "153E36", "096C51", "0C624A", "12894F", "0A4D40" }
local green = { "03985B", "18864D", "148E6A", "15A76B", "168447", "20B05B" }
local bands = { "45BC75", "61C195", "35B891", "73D49D", "24A673", "57C581" }
local crown = { "5ED79B", "8DECC7", "45C994", "57BE85", "A2E9AF", "70CCA1" }
local crystals = {
	{ V(0, -0.46, 0.015), 0.235, 0.87, V(-0.085, 0, 0.11), 0.33 },
	{ V(0.21, -0.48, -0.09), 0.135, 0.51, V(0.12, 0, -0.03), 0.71 },
	{ V(-0.24, -0.47, 0.04), 0.103, 0.34, V(-0.14, 0, 0.085), 0.40 },
}
for _, c in crystals do
	local base, r, h, bend, twist = table.unpack(c)
	local rings = {}
	for j, layer in
		{ { 0, 0.80 }, { 0.28, 1 }, { 0.59, 0.97 }, { 0.633, 0.979 }, { 0.83, 0.95 }, { 0.96, 0.73 }, { 1, 0.49 } }
	do
		local pts = {}
		for k = 1, 6 do
			local a = (k - 1) * math.pi / 3 + twist
			local yy = h * layer[1] + (if j >= 5 then 0.023 * math.cos(a + 1.2) else 0)
			pts[k] = base + V(math.cos(a) * r * layer[2], yy, math.sin(a) * r * layer[2] * 0.90) + bend * layer[1]
		end
		rings[j] = pts
	end
	for i = 2, #rings do
		ring(rings[i - 1], rings[i], ({ deep, green, bands, green, crown, bands })[i - 1], 0)
	end
	local top = base + bend + V(0, h + 0.015, 0)
	for k, p in rings[7] do
		triangle(stock, "Emerald table", p, rings[7][k % 6 + 1], top, crown[k])
	end
end
local emerald = bake("Emerald")
emerald.Reflectance = 0.045
-- Five edges selectively transmit cool light, leaving deep green faces between them.
local central = crystals[1]
for j, edge in { 1, 2, 4, 5 } do
	local base, r, h, bend, twist = table.unpack(central)
	local a = (edge - 1) * math.pi / 3 + twist
	local p = base + V(math.cos(a) * r * 1.006, 0.31 * h, math.sin(a) * r * 0.91) + bend * 0.31
	local q = p + V(-math.sin(a) * 0.014, 0, math.cos(a) * 0.014)
	local tip = base + bend * 0.84 + V(math.cos(a) * r * 0.957, h * 0.84, math.sin(a) * r * 0.87)
	triangle(stock, "Transmitted edge", p, q, tip, if j % 2 == 0 then "57D596" else "99EFBA")
end
local edge = bake("Edge")
edge.Material = Enum.Material.Neon
art:ScaleTo(1 / scale)
local archive = Instance.new("Model")
archive.Name = art.Name
for _, p in art:GetChildren() do
	p.Parent = archive
end
archive.PrimaryPart = origin
local bin = game:GetService("SerializationService"):SerializeInstancesAsync({ archive })
local bytes = buffer.tostring(game:GetService("EncodingService"):Base64Encode(bin))
for i = 1, #bytes, 2000 do
	print("PROOF_DATA", bytes:sub(i, i + 1999))
end
print("PROOF_READY")
