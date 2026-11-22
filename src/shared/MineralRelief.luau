-- Shallow hand-cut silhouettes. All coordinates are in the plane of one six-stud face.
local Art = {}
local V, rgb = Vector3.new, Color3.fromHex
local rock, metal, glass, glow =
	Enum.Material.Slate, Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Neon
Art.matrix = {
	Coal = "555661",
	Copper = "806D61",
	Iron = "757C85",
	Gold = "8D7955",
	Diamond = "567A87",
	Emerald = "506E60",
	Amethyst = "6F597F",
	Sapphire = "455C86",
	Emberglass = "70505D",
	Starfall = "584E75",
}
local function piece(model, class, size, cf, color, material)
	local p = Instance.new(class)
	p.Name, p.Size, p.CFrame, p.Color, p.Material = "Facet", size, cf, rgb(color), material
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Parent = model
	return p
end

-- Split a scalene facet at the altitude of its longest edge. Native wedges catch the actual mine lighting.
local function triangle(m, a, b, c, tint, material)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right, back = ac:Cross(ab).Unit, bc.Unit
	local up = bc:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	local function half(mid, normal, axis, length)
		if length > 0.05 then
			piece(m, "WedgePart", V(0.045, height, length), CFrame.fromMatrix(mid, normal, up, axis), tint, material)
		end
	end
	half((a + b) / 2, right, back, math.abs(ab:Dot(back)))
	half((a + c) / 2, -right, -back, math.abs(ac:Dot(back)))
end

local function crystal(m, x, y, w, h, degrees, sides, palette, mat, lift, base)
	local cf = CFrame.new(x, y, base or 0.075) * CFrame.Angles(0, 0, math.rad(degrees))
	local peak = cf * V(-0.15 * w, h * 0.15, lift)
	local function rim(i)
		local angle = 2 * math.pi * i / sides
		return cf * V(w * math.cos(angle), h * math.sin(angle), 0)
	end
	for i = 1, sides do
		triangle(m, rim(i - 1), rim(i), peak, palette[(i - 1) % #palette + 1], mat)
	end
end
local function band(m, x, y, x2, y2, width, color, mat, z)
	local delta = Vector2.new(x2 - x, y2 - y)
	return piece(
		m,
		"Part",
		V(delta.Magnitude + 0.06, width, 0.105),
		CFrame.new((x + x2) / 2, (y + y2) / 2, z or 0.12) * CFrame.Angles(0, 0, math.atan2(delta.Y, delta.X)),
		color,
		mat
	)
end
local function pebble(m, x, y, w, h, angle, color, mat)
	local p = piece(m, "Part", V(w, h, 0.45), CFrame.new(x, y, 0.12) * CFrame.Angles(0, 0, math.rad(angle)), color, mat)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Sphere, p
end

local forms = {}
function forms.Coal(m)
	local charcoal = { "262732", "414551", "1E2028", "575860", "32343C" }
	crystal(m, -0.7, 0.15, 1.45, 1.12, 16, 5, charcoal, rock, 0.35)
	crystal(m, 0.91, 0.61, 1.0, 0.88, -20, 5, charcoal, rock, 0.28)
	crystal(m, 1.16, -0.96, 0.76, 0.57, 5, 5, charcoal, rock, 0.26)
	crystal(m, -1.73, -1.25, 0.42, 0.32, 24, 4, charcoal, rock, 0.2)
end
function forms.Copper(m)
	for _, s in
		{
			{ -1.95, -1.45, -0.95, -0.85 },
			{ -0.95, -0.85, -0.4, 0.48 },
			{ -0.4, 0.48, 0.96, 0.75 },
			{ 0.96, 0.75, 1.65, 1.7 },
			{ -0.57, 0.18, -1.55, 1.02 },
			{ 0.52, 0.64, 1.41, -0.37 },
			{ -0.95, -0.85, 0.16, -1.45 },
		}
	do
		band(m, s[1], s[2], s[3], s[4], 0.32, "D68958", metal)
	end
	pebble(m, -0.48, 0.37, 0.91, 0.61, 35, "EBA875", metal)
	pebble(m, 1.04, 0.84, 0.75, 0.47, -14, "F1B480", metal)
	pebble(m, -1.4, 1.08, 0.54, 0.32, 18, "5EAF9D", rock)
	pebble(m, 0.24, -1.53, 0.52, 0.39, 22, "71A994", rock)
end
function forms.Iron(m)
	for i, s in
		{ { -1.12, -0.42, 1.65, 0.7 }, { 0.02, 0.17, 1.96, 0.84 }, { 0.99, 0.9, 1.43, 0.74 }, { 1.14, -0.95, 0.88, 0.53 } }
	do
		local cf = CFrame.new(s[1], s[2], 0.1 + i * 0.035) * CFrame.Angles(0.08, -0.07, 0.43)
		piece(m, "Part", V(s[3], s[4], 0.23), cf, ({ "83909D", "B4C2CB", "93A0AD", "D5D9D6" })[i], metal)
		piece(m, "Part", V(s[3] * 0.83, 0.12, 0.08), cf * CFrame.new(0, s[4] * 0.24, 0.12), "DAE1DC", glass)
	end
end
function forms.Gold(m)
	for i, s in
		{ { -0.99, -0.35, 1.62, 1.17 }, { 0.38, 0.42, 1.35, 1.12 }, { 1.61, 1.1, 0.8, 0.67 }, { 0.98, -1.26, 0.74, 0.61 }, {
			-1.8,
			0.93,
			0.48,
			0.41,
		} }
	do
		pebble(m, s[1], s[2], s[3], s[4], i * 21, "E8AE38", metal)
		pebble(m, s[1] - 0.09, s[2] + 0.12, s[3] * 0.5, s[4] * 0.38, i * 21, "FFE195", metal)
	end
end
function forms.Diamond(m)
	local ice = { "E6FFFF", "8DE2F2", "59ADC8", "B5FDFF" }
	crystal(m, -0.35, 0.2, 1.45, 1.8, -13, 4, ice, glass, 0.43)
	crystal(m, 1.42, -1.02, 0.57, 0.81, 14, 4, ice, glass, 0.27)
end
function forms.Emerald(m)
	local jade = { "9DF995", "4CCE72", "278958", "19704D", "3DB55F", "80E87B" }
	crystal(m, -0.58, 0.05, 0.99, 1.92, -18, 6, jade, glass, 0.44)
	crystal(m, 1.02, -0.34, 0.61, 1.15, 22, 6, jade, glass, 0.3)
end
function forms.Amethyst(m)
	pebble(m, 0, 0, 4.25, 3.65, -18, "483955", rock)
	for i, s in
		{
			{ -1.22, -0.27, 0.55, 1, 32 },
			{ -0.64, 0.52, 0.59, 1.2, 13 },
			{ 0.17, 0.62, 0.55, 1.32, -8 },
			{ 0.98, 0.07, 0.61, 1.09, -28 },
			{ 0.06, -0.7, 0.64, 0.68, -14 },
		}
	do
		crystal(m, s[1], s[2], s[3], s[4], s[5], 4, { "EDC8FF", "AE73E4", "7943B4", "CE92F4" }, glass, 0.30 + i * 0.016)
	end
end
function forms.Sapphire(m)
	for i = 1, 3 do
		local r = 1.9 - i * 0.32
		crystal(
			m,
			-0.2,
			0.1,
			r,
			r * 0.84,
			30,
			6,
			{ "679CFF", "4270D9", "3455B2", "8EB7FF", "567CE8", "7791F1" },
			glass,
			0.13,
			0.07 + (i - 1) * 0.14
		)
	end
	crystal(m, 1.65, -1.13, 0.47, 0.46, 22, 6, { "557AF1", "9AB5FF", "3957AE" }, glass, 0.22)
end
function forms.Emberglass(m)
	for _, s in
		{ { -1.9, -1.6, -0.82, -0.15 }, { -0.82, -0.15, 0.32, -0.22 }, { 0.32, -0.22, 1.53, 1.7 }, { 0.32, -0.22, 1.92, -0.88 }, {
			-0.82,
			-0.15,
			-1.53,
			1.24,
		} }
	do
		band(m, s[1], s[2], s[3], s[4], 0.38, "A84357", rock, 0.1)
		band(m, s[1], s[2], s[3], s[4], 0.13, "FF9973", glow, 0.19)
	end
	crystal(m, -0.5, 0.91, 0.48, 0.89, 29, 3, { "492F47", "BD5266", "753547" }, glass, 0.29)
end
function forms.Starfall(m)
	crystal(m, -0.32, 0.12, 0.49, 2.06, -18, 4, { "FFF2CE", "D9AAFF", "9577D4", "F8D8FF" }, glow, 0.32)
	crystal(m, -0.32, 0.12, 1.57, 0.38, -18, 4, { "FEDBA7", "BB9CF7", "C791FF", "FFF6EA" }, glow, 0.36)
	for _, s in { { 1.1, 1.6, 1.83, 0.97 }, { 1.83, 0.97, 1.62, 0.03 }, { -1.7, -0.84, -1.28, -1.64 } } do
		band(m, s[1], s[2], s[3], s[4], 0.065, "A994DA", glass)
		pebble(m, s[1], s[2], 0.24, 0.24, 0, "FFEAD0", glow)
	end
end
function forms.Calcite(m)
	-- A small chalky pocket with a broken edge, set into the host rock.
	pebble(m, -0.16, 0.06, 1.55, 0.84, -14, "71777C", rock)
	local chalk = { "AAA99F", "D0CDBB", "918E83", "BAB8AE" }
	crystal(m, -0.34, 0.08, 0.51, 0.38, -16, 5, chalk, rock, 0.22, 0.23)
	crystal(m, 0.36, -0.11, 0.29, 0.39, 37, 4, chalk, rock, 0.17, 0.22)
	pebble(m, 0.72, -0.39, 0.28, 0.16, -36, "B3B0A3", rock)
end

local templates = {}
function Art.face(name, cf, scale)
	if not templates[name] then
		local model = Instance.new("Model")
		model.Name = name .. " relief"
		forms[name](model)
		model.WorldPivot = CFrame.identity
		templates[name] = model
	end
	local model = templates[name]:Clone()
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:PivotTo(cf)
	return model
end
return Art
