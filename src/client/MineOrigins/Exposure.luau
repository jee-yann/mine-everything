-- Graphic exposures are rendered from native triangles in a camera-facing
-- viewport. The drawing scales with the screen and needs no uploaded texture.
local P = require(script.Parent.Props)
local Beats = require(script.Parent.Beats)
local ease, rgb, V = P.ease, Color3.fromHex, Vector3.new
local Exposure = {}
Exposure.__index = Exposure
local black, paper, lilac = "111222", "F2ECCF", "BF99FF"

local function vertex(x, y, z)
	return V(x, y, z)
end

-- A brushstroke is a closed, tapered strip with a curved spine. The width
-- belongs to each knot so a hard edge can suddenly break into a hairline.
local function stroke(model, knots, tint, z)
	local left, right
	for i, knot in knots do
		local before, after = knots[math.max(i - 1, 1)], knots[math.min(i + 1, #knots)]
		local tangent = Vector2.new(after[1] - before[1], after[2] - before[2]).Unit
		local normal = Vector2.new(-tangent.Y, tangent.X) * knot[3]
		local a = vertex(knot[1] + normal.X, knot[2] + normal.Y, z)
		local b = vertex(knot[1] - normal.X, knot[2] - normal.Y, z)
		if left then
			if (left - right).Magnitude > 0.015 then
				P.face(model, left, right, a, rgb(tint))
			end
			if (a - b).Magnitude > 0.015 then
				P.face(model, right, b, a, rgb(tint))
			end
		end
		left, right = a, b
	end
end

-- Two different contact drawings. The first traps the light against the
-- underside of the meteor. In the second the same light tears out sideways.
local cutSpacing = 512
local function facet(model, outline, tint, z)
	local a = V(outline[1][1], outline[1][2], z)
	for i = 2, #outline - 1 do
		local b, c = outline[i], outline[i + 1]
		P.face(model, a, V(b[1], b[2], z), V(c[1], c[2], z), rgb(tint))
	end
end

-- Ink the horizon in strips so the negative spaces between the headlands
-- and the torn wedges of rock survive on very wide and portrait displays.
local function bank(model, ridge, color, z)
	for i = 2, #ridge do
		local a, b = ridge[i - 1], ridge[i]
		facet(model, { a, b, { b[1], -48 }, { a[1], -48 } }, color, z)
	end
end
local function drawContact(model)
	bank(
		model,
		{
			{ -45, -0.8 },
			{ -15, 0.25 },
			{ -9, 1.10 },
			{ -7.0, 1.04 },
			{ -4, 0.22 },
			{ 0, -0.12 },
			{ 4, 0.15 },
			{ 8, 2.30 },
			{ 10, 2.48 },
			{ 12, 1.38 },
			{ 17, 1.65 },
			{ 45, 0.38 },
		},
		black,
		0.08
	)
	-- Leave a sliver of paper between the iron and its contact shadow.
	facet(model, { { -31, 19 }, { -5.4, 5.7 }, { -2.65, 4.70 }, { -1.46, 3.43 }, { -4.6, 4.30 } }, black, 0.10)
	facet(
		model,
		{ { -4.5, 4.50 }, { -2.55, 4.53 }, { -0.62, 3.05 }, { -0.06, 1.24 }, { -0.30, 0.22 }, { -2.0, 0.67 }, {
			-3.75,
			2.02,
		} },
		black,
		0.13
	)
	stroke(model, { { -4.24, 4.17, 0 }, { -2.62, 3.66, 0.14 }, { -1.68, 2.19, 0.15 }, { -0.30, 0.55, 0 } }, paper, 0.20)
	stroke(model, { { -3.59, 2.55, 0 }, { -2.73, 2.42, 0.10 }, { -2.15, 1.73, 0.07 }, { -1.73, 1.51, 0 } }, paper, 0.20)
	facet(model, { { -24, -5.7 }, { -8, -1.24 }, { -1, -0.32 }, { -5.6, -1.53 } }, "746D74", 0.21)
	facet(model, { { 2, -0.33 }, { 20, -2.25 }, { 11, -1.76 }, { 4, -0.77 } }, "746D74", 0.21)
	stroke(
		model,
		{ { -0.1, -0.2, 0.10 }, { 0.72, -1.12, 0.1 }, { 0.08, -1.72, 0.07 }, { 1.05, -3.15, 0 } },
		paper,
		0.24
	)
	for i = 1, 10 do
		local a = math.rad(16 + i * 14.3)
		local x, y = math.cos(a), math.sin(a)
		stroke(
			model,
			{ { x * 29, y * 19, 0.36 }, { x * 12, y * 9, 0.16 }, { x * (6 + i % 3), y * (4 + i % 3), 0 } },
			black,
			0.16
		)
	end
end

local function drawRelease(model)
	bank(
		model,
		{
			{ -45, -2.9 },
			{ -15, -1.85 },
			{ -9, -1.05 },
			{ -6, -0.78 },
			{ -2, -0.33 },
			{ 0, -0.08 },
			{ 2, 0.47 },
			{ 4, 0.75 },
			{ 8, 1.62 },
			{ 11, 1.82 },
			{ 16, 1.93 },
			{ 45, 2.2 },
		},
		paper,
		0.08
	)
	-- Expose only the broken edge of the incoming shell. It occupies the
	-- first drawing's diagonal while the crust bursts across it to the right.
	stroke(
		model,
		{ { -22, 15, 0 }, { -6.0, 5.36, 0.21 }, { -3.7, 4.2, 0.25 }, { -2.6, 4.24, 0.20 }, { -0.63, 2.64, 0.14 }, {
			-0.09,
			0.2,
			0,
		} },
		paper,
		0.18
	)
	facet(model, { { -3.95, 3.94 }, { -2.65, 3.75 }, { -1.04, 1.85 }, { -2.62, 2.73 } }, paper, 0.19)
	for i, wedge in
		{
			{ { -0.31, 0.12 }, { -4.7, 3.05 }, { -2.3, 2.23 }, { 0.1, 0.59 } },
			{ { -0.10, 0.23 }, { -1.1, 5.65 }, { 0.48, 2.24 }, { 0.36, 0.55 } },
			{ { 0.15, 0.11 }, { 2.18, 5.32 }, { 1.82, 2.55 }, { 0.7, 0.3 } },
			{ { 0.42, 0.25 }, { 5.5, 4.83 }, { 3.09, 1.83 }, { 1.24, 0.48 } },
			{ { 0.7, 0.14 }, { 8.33, 3.74 }, { 5.45, 2.21 }, { 1.63, 0.37 } },
		}
	do
		facet(model, wedge, paper, 0.20 + i * 0.002)
	end
	-- Near slabs cut dark islands into the pale bank, with one light facet
	-- left on each to carry the tumble into the first colour frame.
	for _, chip in
		{ { -6, -1.65, 1.56 }, { -3.6, -0.88, 0.81 }, { 4, -0.87, 1.18 }, { 7.7, 0.1, 0.78 }, { 9.5, 0.74, 0.48 } }
	do
		local x, y, k = table.unpack(chip)
		facet(
			model,
			{ { x - k, y }, { x - 0.35 * k, y + 0.93 * k }, { x + 0.88 * k, y + 0.47 * k }, { x + 0.65 * k, y - 0.31 * k }, {
				x - 0.62 * k,
				y - 0.45 * k,
			} },
			black,
			0.25
		)
		stroke(
			model,
			{ { x - 0.49 * k, y + 0.58 * k, 0 }, { x + 0.37 * k, y + 0.26 * k, 0.05 * k }, { x + 0.61 * k, y - 0.14 * k, 0 } },
			paper,
			0.28
		)
	end
	for i = 1, 13 do
		local a = math.rad(8 + i * 12.1)
		local x, y = math.cos(a), math.sin(a)
		local d = 3.3 + (i * 7 % 8) * 0.72
		local cx, cy = x * d, y * d * 0.82
		local w = 0.11 + (i % 4) * 0.10
		facet(
			model,
			{ { cx - y * w, cy + x * w }, { cx + x * 1.45, cy + y * 1.45 }, { cx + y * w, cy - x * w }, {
				cx - x * 0.48,
				cy - y * 0.48,
			} },
			paper,
			0.23
		)
	end
	stroke(model, { { 0, 0, 0.19 }, { 0.78, -0.96, 0.19 }, { -0.04, -1.59, 0.12 }, { 1.07, -3.12, 0 } }, black, 0.29)
end

local function paint(model, draw)
	draw(model)
	for _, part in model:GetChildren() do
		part.Material, part.CastShadow = Enum.Material.SmoothPlastic, false
	end
end

local function flightLines(screen)
	local layer = Instance.new("Frame")
	layer.Name, layer.Size, layer.BackgroundTransparency = "Slipstream", UDim2.fromScale(1, 1), 1
	layer.Visible, layer.ZIndex, layer.Parent = false, 2, screen
	local rng, lines = Random.new(240), {}
	for i = 1, 16 do
		local angle = (i + rng:NextNumber(-0.40, 0.40)) * math.pi / 8
		local line = Instance.new("Frame")
		line.Name, line.AnchorPoint, line.BorderSizePixel = "Air shear", Vector2.new(0.5, 0.5), 0
		line.BackgroundColor3 = rgb(if i % 3 == 0 then lilac else paper)
		local tip = Instance.new("UIGradient")
		tip.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.54, 0.10),
			NumberSequenceKeypoint.new(1, 1),
		})
		tip.Parent, line.Parent = line, layer
		table.insert(lines, {
			part = line,
			unit = Vector2.new(math.cos(angle), math.sin(angle)),
			phase = rng:NextNumber(),
			thickness = rng:NextNumber(0.001, 0.0032),
		})
	end
	return layer, lines
end

function Exposure.new(screen, camera)
	local plate = Instance.new("ViewportFrame")
	plate.Name, plate.Size = "Contact drawing", UDim2.fromScale(1, 1)
	plate.BorderSizePixel, plate.BackgroundColor3 = 0, rgb(black)
	plate.Ambient, plate.LightColor = Color3.new(1, 1, 1), Color3.new()
	plate.Visible, plate.ZIndex, plate.Parent = false, 2, screen
	local lens = Instance.new("Camera")
	lens.FieldOfView, lens.Parent = 42, plate
	plate.CurrentCamera = lens
	paint(P.model(plate, "Compression"), drawContact)
	local release = P.model(plate, "Sheared crust")
	paint(release, drawRelease)
	release:PivotTo(CFrame.new(cutSpacing, 0, 0))
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name, grade.Parent = "Starfall exposure", camera
	local slip, lines = flightLines(screen)
	return setmetatable({ plate = plate, lens = lens, grade = grade, slip = slip, lines = lines }, Exposure)
end

function Exposure:draw(t, film)
	local motion, grade = film.motion, self.grade
	local offset = t - Beats.impact
	local interval = t - (self.previous or t)
	self.previous = t
	local passing = ease(t, 2.23, 2.43) * (1 - ease(t, 2.56, 2.76))
	local chase = ease(t, 5.98, 6.31) * (1 - ease(t, 6.46, 6.50))
	local shear = if motion then math.max(passing, 0.76 * chase) else 0
	self.slip.Visible = shear > 0.01
	if self.slip.Visible then
		local size = film.camera.ViewportSize
		local at = if passing > 0 then film.strike.meteor:GetPivot().Position else film.impactPoint
		local point = film.camera:WorldToViewportPoint(at)
		local center = Vector2.new(
			math.clamp(point.X, size.X * 0.20, size.X * 0.80),
			math.clamp(point.Y, size.Y * 0.25, size.Y * 0.75)
		)
		for _, line in self.lines do
			local dir = line.unit
			local dx = (if dir.X > 0 then size.X - center.X else -center.X) / dir.X
			local dy = (if dir.Y > 0 then size.Y - center.Y else -center.Y) / dir.Y
			local toEdge = math.min(dx, dy)
			-- Each streak is exposed on twos while the shell crosses the lens at full speed.
			local progress = (2.25 * math.floor(t * 15) / 15 + line.phase) % 1
			local distance = toEdge * (0.60 + 0.47 * progress)
			local p = center + dir * distance
			line.part.Position = UDim2.fromOffset(p.X, p.Y)
			line.part.Size = UDim2.fromOffset(toEdge * (0.22 + 0.15 * progress), math.max(1, size.Y * line.thickness))
			line.part.Rotation = math.deg(math.atan2(dir.Y, dir.X))
			line.part.BackgroundTransparency = 1 - 0.66 * shear * math.sin(progress * math.pi)
		end
	end
	local silhouette = if motion and t >= 6.19 and t < 6.50 then (if t < 6.40 then 0.43 else 1) else 0
	local release = if motion then ease(t, 6.59, 6.69) * (1 - ease(t, 6.76, 6.99)) else 0
	local quiet = ease(t, 9.39, 9.51) * (1 - ease(t, 11.45, 12.56))
	local sky = ease(t, 13.05, 14.45) * (1 - ease(t, 27.9, 30.05))
	local gradeOn = t < 30.6
	grade.Enabled = gradeOn
	if gradeOn then
		grade.Contrast = 0.045 + 0.37 * silhouette + 0.16 * release + 0.055 * quiet + 0.035 * sky
		grade.Brightness = -0.11 * silhouette + 0.085 * release
		local cinders = ease(t, 6.64, 6.77) * (1 - ease(t, 7.82, 8.50))
		grade.Saturation = 0.035 - 0.76 * silhouette - 0.14 * quiet + 0.14 * cinders + 0.09 * sky
		local cold = (1 - ease(t, 6.50, 6.67)) + 0.72 * ease(t, 7.44, 7.95) * (1 - ease(t, 11.56, 13.04))
		grade.TintColor = Color3.new(1, 1, 1)
			:Lerp(rgb("ADC8EB"), 0.36 * cold)
			:Lerp(rgb("D8CAFF"), 0.28 * quiet)
			:Lerp(rgb("FFE4BC"), 0.38 * release)
	end
	local plate = self.plate
	-- The opening calls draw once per PreRender. Give each ink drawing one
	-- submitted frame, including when a slow client crosses contact late.
	if offset < 0 then
		self.contactFrame = 0
		if interval > 0 then
			self.inkHold = if interval < 1 / 90 then 2 else 1
		end
	elseif offset < 0.48 then
		self.contactFrame = math.min(5, (self.contactFrame or 0) + 1)
	else
		self.contactFrame = 5
	end
	plate.Visible = motion and offset >= 0 and self.contactFrame <= 2 * (self.inkHold or 1)
	if plate.Visible then
		local viewport = film.camera.ViewportSize
		local hit = film.camera:WorldToViewportPoint(film.impactPoint)
		local aspect = viewport.X / math.max(1, viewport.Y)
		local h = 8.6 * math.max(1, 1.1 / math.max(0.36, aspect))
		local distance = h / math.tan(math.rad(21))
		local u = math.clamp(hit.X / math.max(1, viewport.X), 0.04, 0.96)
		local v = math.clamp(hit.Y / math.max(1, viewport.Y), 0.08, 0.92)
		local releasing = self.contactFrame > (self.inkHold or 1)
		local sheet = if releasing then cutSpacing else 0
		self.lens.CFrame = CFrame.new(sheet + (1 - 2 * u) * h * aspect, (2 * v - 1) * h, distance)
		plate.BackgroundColor3 = rgb(if releasing then black else paper)
		plate.BackgroundTransparency, plate.ImageTransparency = 0, 0
	end
end

function Exposure:Destroy()
	self.grade:Destroy()
	self.plate:Destroy()
	self.slip:Destroy()
end

return Exposure
