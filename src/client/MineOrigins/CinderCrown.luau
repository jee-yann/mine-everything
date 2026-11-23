-- Each exposure redraws the hot gas in its own pose. The tongues sit at
-- different depths, and their painted banks bend toward the edge of the
-- volume. Rock, pressure vapor and turbulent ash pass through the drawing.
local P = require(script.Parent.Props)
local Plume = require(script.Parent.Plume)
local Cloud = require(script.Parent.FireCloud)
local Art = require(script.Parent.CinderDrawings)
local Crater = require(script.Parent.Crater)

local V, CF, A, rgb, ease = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex, P.ease
local Crown = {}
Crown.__index = Crown

local function triangle(wedges, a, b, c, hue, material)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > math.max(ac.Magnitude, bc.Magnitude) then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal = ac:Cross(ab)
	if normal.Magnitude < 0.001 then
		return
	end
	normal = normal.Unit
	local axis = bc.Unit
	local up = axis:Cross(normal)
	local height = math.abs(ab:Dot(up))
	for i, endPoint in { b, c } do
		local width = math.abs((endPoint - a):Dot(axis))
		if width > 0.035 and height > 0.025 then
			local sign = if i == 1 then 1 else -1
			table.insert(wedges, {
				frame = CFrame.fromMatrix((a + endPoint) * 0.5, normal * sign, up, axis * sign),
				size = V(0.027, height, width),
				hue = hue,
				material = material,
			})
		end
	end
end

-- Triangulate the key paintings once. The hot face on each tongue bellies
-- forward. Its dark outer face returns toward the root, giving the inside
-- of a curl a different parallax from its leading tip.
local function compileDrawing(cast)
	local wedges = {}
	for _, tongue in cast do
		local form, palette, x, y, z, width, height, angle = table.unpack(tongue)
		local turn = A(0, 0, math.rad(angle))
		for layer, contour in Art.forms[form] do
			local vertices, indices = contour[1], contour[2]
			local points = {}
			local color = rgb(Art.colors[palette][layer])
			for i = 1, #vertices, 2 do
				local px, py = vertices[i], vertices[i + 1]
				local curl = 1.35 * math.sin(0.11 * py + 0.062 * px) + 2.50 * math.cos(0.055 * px) - 0.13 * math.abs(px)
				local depth = z + curl * math.abs(width) + (layer - 1) * 0.93
				points[#points + 1] = turn:VectorToWorldSpace(V(px * width, py * height, 0)) + V(x, y, depth)
			end
			local lit = (palette == "white" and layer >= 2)
				or (palette == "torch" and layer >= 3)
				or (palette == "red" and layer == 4)
			local material = if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
			for i = 1, #indices, 3 do
				triangle(wedges, points[indices[i]], points[indices[i + 1]], points[indices[i + 2]], color, material)
			end
		end
	end
	return wedges
end

local drawings = {}
local function prepareDrawings(lastPose)
	local capacity = 0
	for i = 1, lastPose do
		if not drawings[i] then
			drawings[i] = compileDrawing(Art.poses[i][2])
		end
		capacity = math.max(capacity, #drawings[i])
	end
	return capacity
end

local function pressureArc(parent, first, life, tilt, offset, width, cold)
	local root = P.box(parent, "Shock front", Vector3.zero, Vector3.one, "FFFFFF")
	root.Transparency, root.CastShadow = 1, false
	local knots, curves = {}, {}
	for i = 0, 5 do
		local angle = (-1.10 + 0.38 * i) + offset
		local knot = Instance.new("Attachment")
		knot.Axis, knot.Parent = V(-math.sin(angle), 0.02, math.cos(angle)).Unit, root
		table.insert(knots, { at = knot, angle = angle })
		if i > 0 then
			local beam = Instance.new("Beam")
			beam.Name = "Compression along the rock"
			beam.Attachment0, beam.Attachment1 = knots[i].at, knot
			beam.Enabled, beam.FaceCamera, beam.Segments = false, true, 7
			beam.LightEmission, beam.LightInfluence = 0.58, 0
			beam.Color =
				ColorSequence.new(rgb(if cold then "BCA4FF" else "FFF0AF"), rgb(if cold then "8E8DF4" else "FFB26B"))
			beam.Width0 = width * math.sin((i - 1) * math.pi / 5)
			beam.Width1 = width * math.sin(i * math.pi / 5)
			beam.Parent = root
			table.insert(curves, beam)
		end
	end
	return { root = root, knots = knots, curves = curves, first = first, life = life, tilt = tilt }
end

-- A mineral-blue edge rides the near bank of the pressure wave. The long
-- turquoise cheek and its short violet tail wrap at different depths.
local function spectrum(parent)
	local root = P.box(parent, "Split-spectrum pressure lip", Vector3.zero, Vector3.one, "FFFFFF")
	root.Transparency, root.CastShadow = 1, false
	local positions = { V(-38, 19, 6), V(-27, 10, 17), V(-14, 6.6, 22), V(-2, 6.2, 24), V(6, 8.2, 20) }
	local widths = { 0.04, 1.65, 2.88, 1.33, 0.025 }
	local hues = { "8B73F7", "6A94FF", "39DEEF", "9DFFFF", "D0FFFF" }
	local joints, beams = {}, {}
	for i, point in positions do
		local knot = Instance.new("Attachment")
		local tangent = positions[math.min(#positions, i + 1)] - positions[math.max(1, i - 1)]
		knot.Position, knot.Axis, knot.Parent = point, tangent.Unit, root
		joints[i] = knot
		if i > 1 then
			local b = Instance.new("Beam")
			b.Name = "Ionized edge"
			b.Enabled, b.FaceCamera, b.Segments = false, true, 7
			b.Attachment0, b.Attachment1 = joints[i - 1], knot
			b.CurveSize0, b.CurveSize1 = tangent.Magnitude * 0.14, tangent.Magnitude * 0.14
			b.Width0, b.Width1 = widths[i - 1], widths[i]
			b.Color = ColorSequence.new(rgb(hues[i - 1]), rgb(hues[i]))
			b.LightInfluence, b.LightEmission, b.Parent = 0, 0.69, root
			table.insert(beams, b)
		end
	end
	return { root = root, beams = beams }
end

function Crown:reserve(count)
	for i = #self.planes + 1, count do
		local facet = P.part(self.parked, "Painted gas", Vector3.one, CFrame.identity, Color3.new(), "WedgePart")
		facet.CastShadow = false
		self.planes[i] = facet
	end
end

function Crown:prepare(t)
	self:reserve(math.ceil(math.clamp(t / 5, 0, 1) * self.capacity))
end

function Crown.new(parent, parked)
	local self = setmetatable({ root = P.model(parent, "Fire and pressure"), parked = parked }, Crown)
	self.paint = P.model(self.root, "Cut fire")
	self.planes, self.moving, self.frames = {}, {}, {}
	self.rolls = {}
	self.cloud = Cloud.new(self.root)
	self.capacity = prepareDrawings(if self.cloud then 5 else #Art.poses)
	-- Distant cinders cut in front of the back bank, then soft ash carries
	-- through the last held drawing into the reverse shot on the fissure.
	for i, spec in
		{
			{ 0.14, 1.15, V(-3, 4, -8), V(-15, 15, -9), 24, "melt" },
			{ 0.19, 1.10, V(3, 3, -9), V(13, 26, -6), 26, "melt" },
			{ 0.32, 1.18, V(-6, 1, 4), V(-27, 3, 11), 26, "ash" },
			{ 0.38, 1.53, V(8, 1, 4), V(34, 4, 8), 32, "ash" },
			{ 0.53, 2.10, V(5, 17, -9), V(27, 32, -9), 37, "ash" },
			{ 0.63, 2.13, V(-8, 11, -10), V(-10, 26, -6), 32, "ash" },
			{ 0.83, 2.11, V(15, 8, -8), V(36, 26, -4), 31, "ash" },
			{ 0.94, 2.07, V(1, 1, 4), V(-31, 6, 11), 37, "ash" },
			{ 1.01, 2.05, V(7, 1, 1), V(39, 7, 6), 31, "ash" },
			{ 0.29, 1.05, V(-5, 3, 9), V(-13, 12, 14), 14, "melt" },
			{ 0.56, 1.30, V(7, 4, 12), V(18, 13, 17), 17, "melt" },
			{ 0.86, 1.92, V(6, 9, 7), V(22, 23, 7), 24, "ash" },
		}
	do
		local part = P.box(self.root, "Suspended volcanic grit", Vector3.zero, Vector3.one, "FFFFFF")
		part.Transparency, part.CastShadow = 1, false
		local gui, cloud = Plume.mount(part, spec[6])
		table.insert(
			self.rolls,
			{ source = part, gui = gui, cloud = cloud, spec = spec, spin = (-1) ^ i * (18 + 3 * i) }
		)
	end
	self.fronts = {
		pressureArc(self.root, 0.12, 0.54, -0.08, 0.9, 1.43, false),
		pressureArc(self.root, 0.23, 0.70, 0.16, 3.9, 1.10, false),
		pressureArc(self.root, 0.66, 0.43, -0.12, 2.1, 0.85, true),
	}
	self.spectrum = spectrum(self.root)
	return self
end

function Crown:pose(age, base)
	local index = 0
	if age < (if self.cloud then 0.49 else 1.29) then
		index = 1
		for i, pose in Art.poses do
			if age < pose[1] then
				break
			end
			index = i
		end
	end
	if index == self.index then
		if index > 0 then
			local elapsed = math.max(0, age - Art.poses[index][1])
			self.paint:PivotTo(base * CF(4 * elapsed, 9 * elapsed, 0) * A(0, 0, -0.12 * elapsed))
		end
		return
	end
	self.paint.WorldPivot = base
	self.index = index
	local drawing = drawings[index] or {}
	-- Draw the same pose at every render rate. Both the ash-bank heading
	-- and its height are set on the exposure sheet at the instant it opens.
	local at = if index > 0 then Crater.contactHeight(Art.poses[index][1]) else 0
	local pose = base * CF(0, at, 0) * A(0, -0.28, 0)
	self:reserve(#drawing)
	local moving, frames = self.moving, self.frames
	table.clear(moving)
	table.clear(frames)
	for i, glyph in drawing do
		local plane = self.planes[i]
		plane.Size, plane.Color, plane.Material = glyph.size, glyph.hue, glyph.material
		if plane.Parent ~= self.paint then
			plane.Parent = self.paint
		end
		moving[i], frames[i] = plane, pose * glyph.frame
	end
	if #moving > 0 then
		workspace:BulkMoveTo(moving, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	for i = #drawing + 1, self.visible or 0 do
		self.planes[i].Parent = self.parked
	end
	self.visible = #drawing
end

function Crown:draw(age, datum, base, motion)
	self:pose(age, datum)
	Cloud.draw(self.cloud, age, datum)
	local split = self.spectrum
	local visible = age >= 0.345 and age < 0.90
	for _, beam in split.beams do
		beam.Enabled = visible
		if visible then
			beam.Transparency = NumberSequence.new(0.035 + 0.965 * ease(age, 0.76, 0.90))
		end
	end
	if visible then
		local peel = ease(age, 0.43, 0.89)
		split.root.CFrame = base
			* A(0, -0.28, 0)
			* CF(-7 * peel, 9.1 + 1.8 * peel, 5 * peel)
			* A(0.03, -0.12 * peel, 0.06 * peel)
	end
	for i, roll in self.rolls do
		local first, last, from, to, diameter, kind = table.unpack(roll.spec)
		-- On the brush fallback, the three upper ash banks carry the far
		-- silhouette after the colour drawings burn out.
		local highAsh = not self.cloud and i >= 5 and i <= 7
		if highAsh then
			last = 2.9
			to += V(8, 39, -4)
			diameter *= 1.55
		end
		local s = age - first
		local u = math.clamp(s / (last - first), 0, 1)
		local swell = 1 - (1 - u) ^ 3
		local at = from:Lerp(to, swell) + V(u * u * 4, u * 3, 0)
		roll.source.Position = datum * (at + V(0, 0.62 * Crater.coverHeight * (1 - u) + 3 * u, 0))
		local span = diameter * (0.20 + swell * 0.82 + 0.10 * u)
		roll.gui.Size =
			UDim2.fromScale(span * 1.17, span * (if i == 3 or i == 4 or i == 8 or i == 9 then 0.50 else 1.08))
		local fade = ease(u, 0, 0.12) * (1 - ease(u, 0.57, 1))
		local density = if kind == "melt" then 0.52 else 0.55 + 0.39 * ease(age, 0.70, 1.28)
		Plume.show(roll.gui, roll.cloud, i * 43 + u * roll.spin, fade * density)
	end
	for _, front in self.fronts do
		local u = (age - front.first) / front.life
		local active = u >= 0 and u < 1
		for _, beam in front.curves do
			beam.Enabled = active
		end
		if active then
			local radius = 4 + 75 * (1 - (1 - u) ^ 1.7)
			front.root.CFrame = base * CF(0, 2.6 + 3 * u, 0) * A(0, 0, front.tilt)
			for _, k in front.knots do
				k.at.Position = V(radius * math.cos(k.angle), 0.5, radius * math.sin(k.angle) * 0.68)
			end
			for _, beam in front.curves do
				beam.CurveSize0, beam.CurveSize1 = radius * 0.14, radius * 0.14
				beam.Transparency = NumberSequence.new(
					(if motion then 0.08 else 0.43) + (if motion then 0.92 else 0.57) * ease(u, 0.38, 1)
				)
			end
		end
	end
end

return Crown
