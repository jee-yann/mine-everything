-- Original two-colour geological engraving. All numbered points are in the
-- drawing's 960 x 540 paper coordinates. Native lines remain sharp on phones.
local Print = {}
Print.__index = Print
local V = Vector2.new
local ink, sea, mint = Color3.fromHex("092C38"), Color3.fromHex("226466"), Color3.fromHex("73BBAB")
local ochre, gold, cream = Color3.fromHex("BF7C47"), Color3.fromHex("EFB675"), Color3.fromHex("F1D3A0")

local function shape(parent, name, color, x, y, w, h, rotation, transparency)
	local glyph = Instance.new("Frame")
	glyph.Name, glyph.BorderSizePixel = name, 0
	glyph.AnchorPoint, glyph.Position = V(0.5, 0.5), UDim2.fromOffset(x, y)
	-- UDim offsets quantize to integers before the viewport scale. Preserve a
	-- single etched line on paper so fine contours survive a portrait device.
	glyph.Size = UDim2.fromOffset(math.max(1, math.round(w)), math.max(1, math.round(h)))
	glyph.Rotation = rotation or 0
	glyph.BackgroundColor3, glyph.BackgroundTransparency = color, transparency or 0
	glyph.ZIndex, glyph.Parent = 3, parent
	return glyph
end

local function stroke(parent, name, a, b, width, pigment, transparency)
	local v, m = b - a, (a + b) * 0.5
	return shape(
		parent,
		name,
		pigment,
		m.X,
		m.Y,
		v.Magnitude + 0.65,
		width,
		math.deg(math.atan2(v.Y, v.X)),
		transparency
	)
end

local function vein(parent, name, pts, width, color, fade)
	for i = 2, #pts do
		stroke(parent, name, pts[i - 1], pts[i], width, color, fade)
	end
end

local function disc(parent, x, y, diameter, color)
	local field = shape(parent, "Copper relief", color, x, y, diameter, diameter)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0.5, 0), field
	return field
end

local function copperplate(parent)
	-- A broad circular copper impression, interrupted by fine turning-tool
	-- marks. The warm paper silhouettes dark clothing, tools and loose hair.
	local cx, cy, radius = 603, 215, 147
	local sun = disc(parent, cx, cy, radius * 2, gold)
	local tone = Instance.new("UIGradient")
	tone.Rotation = 52
	tone.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("FFF5CF")),
		ColorSequenceKeypoint.new(0.55, Color3.fromHex("F9DBAD")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("CC886A")),
	})
	tone.Parent = sun
	for j = -6, 7 do
		local y = j * 18
		local reach = math.sqrt(radius * radius - y * y)
		stroke(parent, "Etched copper", V(cx - reach + 4, cy + y), V(cx - reach * 0.2, cy + y), 0.75, ochre, 0.40)
		if j % 2 == 0 then
			stroke(
				parent,
				"Dry edge",
				V(cx + reach * 0.58, cy + y + 3),
				V(cx + reach - 4, cy + y + 3),
				1.1,
				ochre,
				0.35
			)
		end
	end
	for i = 0, 33 do
		local a = math.rad(-156 + i * 8.6)
		local n = V(math.cos(a), math.sin(a))
		local origin = V(cx, cy)
		stroke(
			parent,
			"Graduation",
			origin + n * 153,
			origin + n * (if i % 4 == 0 then 165 else 158),
			if i % 4 == 0 then 1.8 else 1,
			cream,
			0.26
		)
	end
end

local function engravedTerrain(parent)
	-- Ridges in the upper left and at lower right open toward the portrait.
	local rng = Random.new(9047)
	for family = 1, 2 do
		for line = 1, 10 do
			local pts = {}
			for j = 0, 17 do
				local x = j * 30 - 100
				local y = 79 - x * 0.38 + 36 * math.sin(x / 82) + 15 * math.sin(x / 35 + line * 0.05)
				local spread = line * (5.2 + 2 * math.sin(x / 56))
				local p = V(x + line * 3.5, y + spread)
				pts[j + 1] = if family == 1 then p else V(1002 - p.X, 467 - p.Y * 0.68)
			end
			for j = 2, #pts do
				if j ~= 5 or line % 3 == 0 then
					stroke(
						parent,
						"Contour",
						pts[j - 1],
						pts[j],
						if line % 4 == 0 then 1.45 else 0.85,
						if family == 1 then mint else gold,
						if family == 1 then 0.46 else 0.57
					)
				end
			end
		end
	end
	local fracture = { V(771, -36), V(758, 25), V(785, 48), V(744, 87), V(751, 108), V(711, 141) }
	vein(parent, "Mineral fracture", fracture, 2.7, cream, 0.28)
	vein(parent, "Bifurcation", { fracture[3], V(814, 67), V(846, 69), V(867, 88) }, 1.1, gold, 0.36)
	local footwall = { V(-54, 340), V(58, 307), V(121, 313), V(186, 282), V(235, 285), V(328, 234), V(373, 228) }
	vein(parent, "Exposed bedding", footwall, 2.4, mint, 0.37)
	for i = 2, #footwall do
		local a, b = footwall[i - 1], footwall[i]
		for k = 1, 7 do
			local point = a:Lerp(b, k / 8) + V(0, 5)
			local len = rng:NextNumber(4, 18)
			stroke(parent, "Cut hatching", point, point + V(-len, len * 0.79), 1, mint, 0.58)
		end
	end
	-- Stipple in two small printed patches, leaving the caption margin clear.
	for i = 0, 14 do
		for j = 0, 5 do
			if (i - 6) ^ 2 / 102 + (j - 2) ^ 2 / 12 < 1 then
				local cell = 1.25 + (5 - j) * 0.40
				shape(
					parent,
					"Stipple",
					mint,
					329 + i * 6.5 + (j % 2) * 3,
					113 + j * 5 - i * 1.7,
					cell,
					cell,
					45,
					0.43 + j * 0.055
				)
			end
		end
	end
end

function Print.new(parent)
	local page = Instance.new("Frame")
	page.Name, page.BorderSizePixel, page.BackgroundColor3 = "Petrographic print", 0, Color3.new(1, 1, 1)
	page.Size, page.ZIndex, page.Parent = UDim2.fromScale(1, 1), 3, parent
	local inkWash = Instance.new("UIGradient")
	inkWash.Rotation = -18
	inkWash.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("0B2432")),
		ColorSequenceKeypoint.new(0.42, ink),
		ColorSequenceKeypoint.new(0.82, sea),
		ColorSequenceKeypoint.new(1, Color3.fromHex("386B69")),
	})
	inkWash.Parent = page
	local drawing = Instance.new("Frame")
	drawing.Name, drawing.BackgroundTransparency, drawing.BorderSizePixel = "Engraved atlas", 1, 0
	drawing.Size, drawing.ZIndex, drawing.Parent = UDim2.fromOffset(960, 540), 3, page
	local scale = Instance.new("UIScale")
	scale.Parent = drawing
	copperplate(drawing)
	engravedTerrain(drawing)
	local dust = {}
	for i, p in
		{
			V(445, 261),
			V(737, 294),
			V(681, 82),
			V(386, 337),
			V(760, 163),
			V(487, 117),
			V(712, 357),
			V(567, 40),
			V(315, 214),
		}
	do
		local speck = shape(
			drawing,
			"Mica glint",
			if i % 3 == 0 then cream else mint,
			p.X,
			p.Y,
			if i % 3 == 1 then 3.6 else 2,
			if i % 3 == 1 then 8 else 3.4,
			34
		)
		dust[i] = { speck, p }
	end
	return setmetatable({ drawing = drawing, scale = scale, dust = dust }, Print)
end

function Print:draw(size, face, age, motion)
	if size.X < 2 or size.Y < 2 then
		return
	end
	-- The plate is pinned behind the actual face. Clamp the pinhole on tall
	-- displays so some engraved copper still frames a broad or tall accessory.
	local k = math.min(size.X / 640, size.Y / 540)
	local cx, cy = math.clamp(face.X, 0.35 * size.X, 0.76 * size.X), math.clamp(face.Y, 0.27 * size.Y, 0.54 * size.Y)
	local settle = if motion then (1 - math.clamp(age / 13, 0, 1)) ^ 2 else 0
	self.drawing.Position = UDim2.fromOffset(cx - (603 - 15 * settle) * k, cy - (215 + 5 * settle) * k)
	self.scale.Scale = k
	for i, item in self.dust do
		local glint, start = item[1], item[2]
		local p = if motion then (age * (0.009 + (i % 3) * 0.0018) + i * 0.28) % 1 else 0.32 + (i % 4) * 0.10
		if motion then
			glint.Position = UDim2.fromOffset(start.X + 11 * p, start.Y - 20 * p)
		else
			glint.Position = UDim2.fromOffset(start.X, start.Y)
		end
		glint.BackgroundTransparency = 0.9 - math.sin(p * math.pi) ^ 3 * 0.72
	end
end

return Print
