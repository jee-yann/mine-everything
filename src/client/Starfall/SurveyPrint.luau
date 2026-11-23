-- Translucent glass slabs behind the miner refract a band of mint light.
local Glass = {}
Glass.__index = Glass
local color = Color3.fromHex
local point = ColorSequenceKeypoint.new
local opacity = NumberSequenceKeypoint.new
local V = Vector2.new

local function panel(parent, name, z)
	local p = Instance.new("Frame")
	p.Name, p.BorderSizePixel, p.BackgroundColor3, p.ZIndex = name, 0, Color3.new(1, 1, 1), z
	p.Parent = parent
	return p
end

local function gradient(parent, angle, colors)
	local g = Instance.new("UIGradient")
	g.Rotation, g.Color, g.Parent = angle, ColorSequence.new(colors), parent
	return g
end

local function pane(parent, name, x, y, w, h, angle, depth)
	local slab = panel(parent, name, depth)
	slab.AnchorPoint, slab.Position = Vector2.new(0.5, 0.5), UDim2.fromOffset(x, y)
	slab.Size, slab.Rotation = UDim2.fromOffset(w, h), angle
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 26), slab
	local reflection = gradient(slab, 37, {
		point(0, color("273E68")), point(0.27, color("305D79")), point(0.43, color("77C8CA")),
		point(0.49, color("B8E8E6")), point(0.52, color("427E86")), point(0.76, color("176665")),
		point(1, color("344F77")),
	})
	reflection.Transparency = NumberSequence.new({
		opacity(0, 0.36), opacity(0.34, 0.57), opacity(0.48, 0.19),
		opacity(0.54, 0.44), opacity(0.85, 0.62), opacity(1, 0.28),
	})
	local rim = Instance.new("UIStroke")
	rim.Thickness, rim.Color, rim.Parent = 2.3, Color3.new(1, 1, 1), slab
	gradient(rim, 44, {
		point(0, color("6FA6C7")), point(0.20, color("DAFFF0")), point(0.48, color("7095B4")),
		point(0.66, color("465F8A")), point(0.88, color("A0E7DF")), point(1, color("57779D")),
	})
	return reflection
end

local function engraving(parent, name)
	local group = panel(parent, name, 5)
	group.BackgroundTransparency, group.Size = 1, UDim2.fromOffset(1, 1)
	local scale = Instance.new("UIScale")
	scale.Parent = group
	return group, scale
end

local function ink(parent, name, a, b, tone, thickness, transparency)
	local segment = panel(parent, name, 5)
	local span = b - a
	segment.AnchorPoint = V(0.5, 0.5)
	segment.Size = UDim2.fromOffset(math.max(1, math.round(span.Magnitude)), thickness or 1)
	segment.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	segment.Rotation, segment.BackgroundColor3 = math.deg(math.atan2(span.Y, span.X)), color(tone)
	segment.BackgroundTransparency = transparency or 0
end

local function path(parent, name, vertices, tint, width, fade)
	for i = 2, #vertices do ink(parent, name, vertices[i-1], vertices[i], tint, width, fade) end
end

local function wheel(parent, x, y, r, tint)
	for i = 0, 15 do
		local angle, nextAngle = i * math.pi / 8, (i + 1) * math.pi / 8
		local hub = V(x, y)
		local rim = hub + r * V(math.cos(angle), math.sin(angle))
		ink(parent, "Winding sheave", rim, hub + r * V(math.cos(nextAngle), math.sin(nextAngle)), tint, 1)
		if i % 4 == 0 then ink(parent, "Sheave spoke", hub, rim, tint, 1, 0.16) end
	end
end

-- Surveyor's glass engraving of a winding tower, its shaft and the rock cut
-- beneath it. Trace the same horizon into deeper strata as it crosses a fault.
local function drawMine(parent)
	local ridge = { V(0,91), V(22,85), V(39,89), V(59,75), V(77,78), V(95,67), V(117,72),
		V(139,61), V(162,65), V(179,53), V(190,61), V(205,56), V(222,65), V(233,62), V(254,76), V(287,82) }
	for layer = 1, 5 do
		local profile = {}
		for i, q in ridge do
			local offset = layer * 13 + 3 * math.sin(i * 1.2 + layer)
			local slip = if q.X > 178 then layer * 1.7 else 0
			profile[i] = q + V(0, offset + slip)
		end
		path(parent, "Rock bedding", profile, if layer == 3 then "91B6A8" else "608A91", 1, 0.39 + layer * 0.055)
	end
	path(parent, "Cove profile", ridge, "9BBEBB", 2, 0.16)
	path(parent, "Far ridge", { V(13,76), V(36,72), V(71,47), V(89,54), V(103,49), V(117,57),
		V(151,28), V(167,39), V(184,31), V(210,52), V(229,49), V(262,64) }, "628B98", 1, 0.46)

	local rail, metal, cable = "92D0CE", "61A4AA", "E9BF7C"
	path(parent, "Tower bent", { V(64,93), V(82,31), V(94,31), V(104,91) }, rail, 3)
	path(parent, "Tower bracing", { V(70,74), V(97,53), V(81,45), V(91,35) }, metal, 2)
	path(parent, "Tower bracing", { V(67,88), V(98,66), V(76,59) }, metal, 2)
	ink(parent, "Wheel deck", V(76,34), V(99,34), rail, 3)
	ink(parent, "Landing deck", V(70,73), V(103,73), rail, 2)
	wheel(parent, 88, 24, 8, rail)
	path(parent, "Hoisting rope", { V(42,72), V(83,17), V(88,15), V(96,19), V(96,119) }, cable, 1, 0.10)
	path(parent, "Engine house", { V(21,87), V(21,74), V(33,66), V(49,73), V(49,87) }, metal, 2)
	ink(parent, "Engine house ridge", V(17,75), V(33,65), rail, 2)
	ink(parent, "Shaft lining", V(88,88), V(88,158), metal, 2)
	ink(parent, "Shaft lining", V(103,88), V(103,158), metal, 2)
	for n = 0, 6 do ink(parent, "Shaft rung", V(89,96 + n * 9), V(94,96 + n * 9), metal, 1) end
	path(parent, "Cage", { V(92,119), V(100,119), V(100,128), V(92,128), V(92,119) }, cable, 1)
	path(parent, "Upper drift", { V(102,129), V(145,129), V(163,124) }, rail, 2, 0.15)
	path(parent, "Lower drift", { V(103,152), V(122,152), V(139,145), V(169,145), V(190,140) }, metal, 2)
	for _, x in { 112, 124, 136 } do ink(parent, "Gallery timber", V(x,124), V(x,129), metal, 1) end
	local vein = { V(163,153), V(175,141), V(179,127), V(189,117), V(186,105), V(199,98), V(205,84) }
	path(parent, "Emerald seam", vein, "A6E3CA", 2, 0.12)
	path(parent, "Seam branch", { vein[4], V(201,113), V(215,102), V(225,101) }, "85BCAD", 1)
	for i, p in vein do
		if i % 2 == 0 then ink(parent, "Mineral glint", p - V(1,1), p + V(2,2), cable, 2) end
	end
end

-- The upper plan and lower pavilion section both use the specimen's
-- clipped corners. Brass caliper marks set them apart from the terrain.
local function drawAssay(parent)
	local contour = { V(-0.62,-1), V(0.62,-1), V(1,-0.72), V(1,0.72), V(0.62,1), V(-0.62,1), V(-1,0.72), V(-1,-0.72) }
	local previous
	for level, ratio in { 1, 0.90, 0.77, 0.63 } do
		local ring = {}
		for i, q in contour do ring[i] = V(q.X * 39 * ratio, q.Y * 51 * ratio) end
		for i, p in ring do
			local nextPoint = ring[i % #ring + 1]
			ink(parent, "Beryl plan", p, nextPoint, if level == 1 then "ACE3D6" else "77BCB5", if level == 1 then 2 else 1, level * 0.055)
			if previous then ink(parent, "Step facet", p, previous[i], "AFDACA", 1, 0.23) end
		end
		previous = ring
	end
	path(parent, "Pavilion section", { V(-38,78), V(-29,72), V(28,72), V(38,78), V(22,84), V(7,91), V(-7,91), V(-24,84), V(-38,78) }, "94C2B9", 1)
	ink(parent, "Girdle", V(-38,78), V(38,78), "8DC3BF", 1)
	for _, x in { -22, 22 } do ink(parent, "Pavilion facet", V(x,78), V(x * 0.29,91), "77A9AC", 1) end
	ink(parent, "Caliper", V(-53,-50), V(-53,51), "D5AC76", 1, 0.30)
	for j = -5, 5 do
		local size = if j == 0 or math.abs(j) == 5 then 6 else 3
		ink(parent, "Caliper mark", V(-53-size,j*10), V(-53,j*10), "D5AC76", 1, 0.30)
	end
end

function Glass.new(parent)
	local backdrop = panel(parent, "Gem Hunter glass", 3)
	backdrop.Size = UDim2.fromScale(1, 1)
	gradient(backdrop, -26, {
		point(0, color("081322")), point(0.29, color("12273E")), point(0.54, color("234659")),
		point(0.74, color("31665F")), point(1, color("303659")),
	})
	local stage = panel(backdrop, "Refracted light", 3)
	stage.BackgroundTransparency, stage.Size = 1, UDim2.fromOffset(1, 1)
	local scale = Instance.new("UIScale")
	scale.Parent = stage
	pane(stage, "Distant blue glass", 265, -105, 210, 720, 27, 3)
	pane(stage, "Sea glass", 82, 34, 266, 555, 31, 3)
	local keyLight = pane(stage, "Polished jade glass", 10, 24, 256, 362, -26, 4)
	pane(stage, "Refracted edge", 425, 20, 63, 846, 31, 4)

	-- A soft scrim leaves a quiet area for the display name at every aspect ratio.
	local scrim = panel(backdrop, "Portrait contrast", 4)
	scrim.Size, scrim.BackgroundColor3 = UDim2.fromScale(1, 1), color("071221")
	local shade = Instance.new("UIGradient")
	shade.Rotation = -13
	shade.Transparency = NumberSequence.new({
		opacity(0, 0.13), opacity(0.31, 0.35), opacity(0.59, 0.92), opacity(0.73, 1), opacity(1, 1),
	})
	shade.Parent = scrim
	local mine, mineScale = engraving(backdrop, "Etched mine section")
	local assay, assayScale = engraving(backdrop, "Emerald cutting diagram")
	drawMine(mine)
	drawAssay(assay)
	return setmetatable({ stage = stage, scale = scale, keyLight = keyLight, mine = mine, mineScale = mineScale,
		assay = assay, assayScale = assayScale }, Glass)
end

function Glass:draw(size, face, age, motion)
	if size.X < 2 or size.Y < 2 then return end
	local k = math.min(size.X / 560, size.Y / 540)
	local cx = math.clamp(face.X, 0.35 * size.X, 0.77 * size.X)
	local cy = math.clamp(face.Y, 0.27 * size.Y, 0.54 * size.Y)
	self.stage.Position, self.scale.Scale = UDim2.fromOffset(cx, cy), k
	local progress = if motion then math.clamp(age / 58, 0, 1) else 0.5
	self.keyLight.Offset = Vector2.new(-0.09 + 0.18 * progress, 0)
	local tall = size.X < size.Y
	self.mineScale.Scale = math.min(size.X * (if tall then 0.48 else 0.39) / 287, size.Y * 0.32 / 158)
	self.mine.Position = UDim2.fromScale(if tall then 0.018 else 0.055, if tall then 0.20 else 0.245)
	self.assayScale.Scale = math.min(size.X * 0.15 / 98, size.Y * 0.31 / 145)
	self.assay.Position = UDim2.fromScale(0.90, if tall then 0.24 else 0.39)
end

return Glass
