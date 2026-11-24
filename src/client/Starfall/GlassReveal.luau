-- The player's introduction. Cut glass with real thickness, in real depth. It
-- leaves the rim of the pocket they opened, forms around them, and sweeps on.
--
-- Every piece has one trajectory for the whole scene. Its entrance decays into
-- a steady drift, and the exit is that same drift gathering speed. Nothing
-- stops, so nothing has to start again.
--
-- Local space: the origin is the avatar's face, -Z points at the camera.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local M = Enum.Material
local hex = Color3.fromHex
local Glass = {}
Glass.__index = Glass

local first, last = F.reveal, F.answer
local depth = 24
local focus = V(0.5, 0.35, 0)
-- Screen left, a little up, a little toward the lens.
local sweep = V(1, 0.10, -0.22).Unit
local gather = 20

local function tri(parent, a, b, c, tint, material)
	local before = #parent:GetChildren()
	S.facet(parent, "Glass", a, b, c, tint, material)
	local made, children = {}, parent:GetChildren()
	for i = before + 1, #children do
		children[i].CastShadow = false
		table.insert(made, children[i])
	end
	return made
end

-- Behind everything, a tunnel of wide facets. Each runs toward the lens as it
-- leaves the centre, at its own pitch, so light separates them.
local rings = {
	{ 0.0, 2.6, "FAFEFF" }, { 2.6, 5.4, "D3F1FB" }, { 5.4, 9.0, "96DDF4" }, { 9.0, 13.5, "63C8EE" },
	{ 13.5, 20, "43A9E2" }, { 20, 29, "3088D0" }, { 29, 54, "2266B2" },
}
local function field(parent)
	local rng = Random.new(9102)
	local blades, angle, index = {}, 0, 0
	while angle < math.pi * 2 - 0.02 do
		index += 1
		local width = math.min(rng:NextNumber(0.20, 0.46), math.pi * 2 - angle)
		local jitter, pitch = rng:NextNumber(0.80, 1.24), rng:NextNumber(0.12, 0.46)
		local tilt = rng:NextNumber(-2.2, 2.2)
		local model = S.group("Facet")
		model.Parent = parent
		local a0, a1 = angle, angle + width
		local function at(r, a)
			local side = (a - (a0 + a1) / 2) / width
			return V(focus.X + math.cos(a) * r, focus.Y + math.sin(a) * r, depth - r * pitch + side * tilt * math.min(1, r / 9))
		end
		for i, ring in rings do
			local r0 = ring[1] * (if i == 1 then 1 else jitter)
			local r1 = ring[2] * (if i == #rings then 1.2 else jitter)
			tri(model, at(r0, a0), at(r1, a0), at(r1, a1), ring[3])
			if r0 > 0 then
				tri(model, at(r0, a0), at(r1, a1), at(r0, a1), ring[3])
			end
		end
		table.insert(blades, { model = model, delay = rng:NextNumber(0, 2), turn = rng:NextNumber(0.0004, 0.0011) })
		angle += width
	end
	return blades
end

local outlines = {
	{ { -0.5, -1 }, { 0.62, -0.72 }, { 0.28, 1.1 } },
	{ { -0.7, -0.6 }, { 0.5, -0.9 }, { 0.8, 0.5 }, { -0.2, 0.95 } },
	{ { -0.9, -0.42 }, { 0.95, -0.60 }, { 0.75, 0.36 }, { -0.75, 0.55 } },
	{ { -0.45, -0.85 }, { 0.45, -0.85 }, { 0.85, 0 }, { 0.4, 0.85 }, { -0.4, 0.85 }, { -0.85, 0 } },
}

-- A slab of glass: a clear face, a clear back, and a bevel all the way round
-- whose facets brighten as they turn to the light. No drawn edges.
local light = V(-0.55, 0.75, -0.36).Unit
local function slab(shape, w, h, thick, tint, clear)
	local model = S.group("Glass slab")
	local core = S.part(model, "Datum", CF(), Vector3.one * 0.02, "FFFFFF")
	core.Transparency, model.PrimaryPart = 1, core
	local outer, front, rear = {}, {}, {}
	for i, q in outlines[shape] do
		local p = V(q[1] * w, q[2] * h, 0)
		local inset = p.Unit * math.min(0.30 * math.min(w, h), p.Magnitude * 0.3)
		outer[i], front[i], rear[i] = p, p - inset + V(0, 0, -thick), p - inset + V(0, 0, thick)
	end
	local n = #outer
	for i = 2, n - 1 do
		for _, p in tri(model, front[1], front[i], front[i + 1], tint, M.Glass) do
			p.Transparency, p.Reflectance = clear, 0.24
		end
		for _, p in tri(model, rear[1], rear[i], rear[i + 1], tint, M.Glass) do
			p.Transparency, p.Reflectance = math.min(0.9, clear + 0.22), 0.05
		end
	end
	for i = 1, n do
		local j = i % n + 1
		local normal = (outer[j] - outer[i]):Cross(front[i] - outer[i])
		normal = if normal.Magnitude > 0 then normal.Unit else V(0, 0, -1)
		if normal.Z > 0 then normal = -normal end
		local lit = math.clamp(normal:Dot(light), 0, 1)
		local tone = hex("2E86C8"):Lerp(hex("F4FCFF"), lit ^ 1.4)
		for _, p in tri(model, outer[i], outer[j], front[i], tone:ToHex(), M.SmoothPlastic) do
			p.Transparency, p.Reflectance = 0.66 - 0.60 * lit ^ 1.5, 0.1 * lit
		end
		for _, p in tri(model, outer[j], front[j], front[i], tone:ToHex(), M.SmoothPlastic) do
			p.Transparency, p.Reflectance = 0.66 - 0.60 * lit ^ 1.5, 0.1 * lit
		end
	end
	return model
end

function Glass.new(stage)
	return setmetatable({ stage = stage }, Glass)
end

local tints = { "BFE9F8", "8FD3F0", "A9DDF4", "7FC4EA", "D3F1FB" }

function Glass:build()
	if self.root then
		return
	end
	local rng = Random.new(4471)
	self.root = S.group("Glass stage")
	local anchor = S.part(self.root, "Origin", CF(), Vector3.one * 0.05, "FFFFFF")
	anchor.Transparency, self.root.PrimaryPart = 1, anchor
	self.anchor = anchor
	self.blades = field(self.root)
	S.part(self.root, "Deep field", CF(0, 0, depth + 5), V(240, 240, 0.2), "2C78C4").CastShadow = false
	self.panels = {}
	local function add(angle, radius, z, size, shape, stretch)
		local model = slab(shape, size * stretch, size, 0.05 + 0.045 * size, tints[#self.panels % #tints + 1], rng:NextNumber(0.28, 0.48))
		model.Parent = self.root
		local x, y = math.cos(angle) * radius * 1.4, math.sin(angle) * radius
		table.insert(self.panels, {
			model = model, z = z,
			rest = CF(focus.X + x, focus.Y + y, z) * A(0, 0, angle - math.pi / 2 + rng:NextNumber(-0.3, 0.3))
				* A(rng:NextNumber(-0.30, 0.30), rng:NextNumber(-0.34, 0.34), 0),
			-- Where it was when the rock opened: round the rim, close to the lens.
			from = V(math.cos(angle) * 1.5, math.sin(angle) * 1.05, -4.0 - rng:NextNumber(0, 0.7)),
			delay = rng:NextNumber(0, 2.5) + math.max(0, z) * 0.12,
			spin = V(rng:NextNumber(-0.010, 0.010), rng:NextNumber(-0.016, 0.016), rng:NextNumber(-0.005, 0.005)),
			tumble = V(rng:NextNumber(-0.004, 0.004), rng:NextNumber(0.003, 0.007), rng:NextNumber(-0.002, 0.002)),
			-- Nearer glass crosses the frame faster.
			pace = 1.25 - z / 26,
		})
	end
	-- Three sizes with clear air round the head: a few heroes, a middle ground,
	-- and a quiet far field.
	for i, q in { { 2.6, 3.9, 4.5, 2.7, 2, 0.8 }, { 0.45, 4.3, 3.8, 2.4, 1, 0.8 }, { 3.75, 4.6, 5.6, 2.9, 4, 1 }, { 5.75, 4.4, 4.6, 2.5, 3, 1.1 }, { 1.45, 4.1, 7, 2.2, 4, 1 }, { 4.8, 4.6, 8, 2.7, 2, 0.8 } } do
		add(q[1], q[2], q[3], q[4], q[5], q[6])
	end
	for i = 1, 11 do
		add(i * 2.39996 + 0.4, rng:NextNumber(4.2, 7.8), rng:NextNumber(9, 15), rng:NextNumber(1.6, 2.8), (i - 1) % #outlines + 1, rng:NextNumber(0.6, 1))
	end
	-- In front of the lens, at the corners only.
	for _, q in { { 3.62, 2.05, -2.7, 0.95, 2 }, { 0.50, 2.15, -2.4, 0.9, 1 }, { 5.72, 2.1, -2.9, 0.85, 4 }, { 2.55, 2.2, -2.3, 0.75, 3 } } do
		add(q[1], q[2], q[3], q[4], q[5], 0.75)
	end
	self.streaks = {}
	for i = 1, 38 do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = anchor, anchor
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1, beam.FaceCamera, beam.Segments = a0, a1, true, 1
		beam.LightEmission, beam.LightInfluence = 0.85, 0
		local broad = i > 26
		beam.Color = ColorSequence.new(hex(if i % 4 == 0 then "FFFFFF" else "9BEBFF"), hex("2F9BFF"))
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, if broad then 0.80 else 0.55), NumberSequenceKeypoint.new(1, 1),
		})
		beam.Parent = anchor
		table.insert(self.streaks, {
			beam = beam, a0 = a0, a1 = a1, angle = i * 2.39996, z = rng:NextNumber(5, 20), phase = rng:NextNumber(0, 1),
			speed = rng:NextNumber(0.010, 0.022), width = if broad then rng:NextNumber(0.9, 1.9) else rng:NextNumber(0.03, 0.14),
			length = if broad then rng:NextNumber(8, 13) else rng:NextNumber(3, 7),
		})
	end
	-- The piece they broke free, over the open palm.
	self.star = S.group("Held star")
	local core = S.part(self.star, "Datum", CF(), Vector3.one * 0.02, "FFFFFF")
	core.Transparency, self.star.PrimaryPart = 1, core
	local ring = {}
	for k = 1, 5 do
		local a = k / 5 * math.pi * 2
		ring[k] = V(math.cos(a) * 0.27, 0.03 * math.sin(k * 2.1), math.sin(a) * 0.27)
	end
	for k = 1, 5 do
		local j = k % 5 + 1
		tri(self.star, ring[k], ring[j], V(0.02, 0.64, 0), if k % 2 == 0 then "E9DDFF" else "B99AF0")
		tri(self.star, ring[k], ring[j], V(-0.02, -0.46, 0), if k % 2 == 0 then "8A62DA" else "6F9BEA")
	end
	-- Slabs that cross the lens itself, camera space, and carry us out.
	self.wipe = {}
	for i = 1, 9 do
		local big = i == 5
		local w = if big then 2.0 else rng:NextNumber(0.5, 1.0)
		local model = slab(if big then 3 else (i % #outlines) + 1, w, if big then 2.1 else rng:NextNumber(0.7, 1.3), 0.06, tints[i % #tints + 1], if big then 0.12 else 0.42)
		if big then
			for _, p in model:GetChildren() do
				if p:IsA("BasePart") and p.Material == M.Glass then
					p.Transparency = 1
				end
			end
			-- One broad pane carries its own light, so it reads as glass in both
			-- places. Its gradient is what covers the cut.
			local pane = S.part(model, "Pane", CF(), V(w * 1.74, 2.5, 0.02), "FFFFFF")
			pane.Transparency, pane.CastShadow = 1, false
			local gui = Instance.new("SurfaceGui")
			gui.Face, gui.LightInfluence, gui.SizingMode, gui.PixelsPerStud = Enum.NormalId.Back, 0, Enum.SurfaceGuiSizingMode.PixelsPerStud, 60
			gui.Parent = pane
			local sheet = Instance.new("Frame")
			sheet.Size, sheet.BorderSizePixel, sheet.BackgroundColor3, sheet.Parent = UDim2.fromScale(1, 1), 0, Color3.new(1, 1, 1), gui
			local blend = Instance.new("UIGradient")
			blend.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, hex("1668C4")), ColorSequenceKeypoint.new(0.28, hex("3FB2EC")), ColorSequenceKeypoint.new(0.44, hex("CFF3FF")),
				ColorSequenceKeypoint.new(0.52, hex("74CDF4")), ColorSequenceKeypoint.new(0.8, hex("2E93DC")), ColorSequenceKeypoint.new(1, hex("1A6CC6")),
			})
			blend.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.10, 0), NumberSequenceKeypoint.new(0.90, 0), NumberSequenceKeypoint.new(1, 0.55),
			})
			blend.Rotation, blend.Parent = 18, sheet
		end
		table.insert(self.wipe, {
			model = model, at = (i - 5) * 1.15 + (if big then 0 else rng:NextNumber(-0.3, 0.3)),
			y = if big then 0 else rng:NextNumber(-0.7, 0.7), z = if big then -1.95 else -rng:NextNumber(1.8, 3.4),
			roll = rng:NextNumber(-0.4, 0.4) * (if big then 0.3 else 1), spin = rng:NextNumber(0.015, 0.04) * (if big then 0.4 else 1),
		})
	end
end

function Glass:place(at, unit, reach)
	self:build()
	self.at, self.unit, self.reach = at, unit, reach
	self.root:PivotTo(at)
end

function Glass:draw(frame, motion, palm, camera)
	if not self.root or not self.at then
		return
	end
	local active = frame >= first and frame < last
	self.root.Parent = if active then self.stage else nil
	self.star.Parent = if active and palm then self.stage else nil
	-- One crossing of the lens, centred on the cut.
	for _, p in self.wipe do
		local t = frame - last
		local x = p.at - 0.62 * t
		local on = motion and camera ~= nil and t > -12 and t < 14 and math.abs(x) < 5.4
		p.model.Parent = if on then self.stage else nil
		if on then
			p.model:PivotTo(camera * CF(x, p.y + 0.02 * t, p.z) * A(0, p.spin * (t + 6), p.roll))
		end
	end
	if not active then
		return
	end
	local age = if motion then frame - first else 30
	local at = self.at
	local span = last - first
	local rush = if motion then math.max(0, age - (span - gather)) else 0
	-- Distance along the sweep: a drift, and the drift gathering.
	local along = 0.010 * age + 0.026 * rush * rush
	for _, b in self.blades do
		local t = age + 3 - b.delay
		local open = if t <= 0 then 0 else 1 - math.exp(-t / 3.4)
		b.model:PivotTo(at * CF(focus.X, focus.Y, 0) * A(0, 0, (1 - open) * 0.35 + age * b.turn + rush * rush * 0.00035) * CF(-focus.X, -focus.Y, (1 - open) * 7))
	end
	for _, p in self.panels do
		local t = math.max(0, age + 1 - p.delay)
		local away = math.exp(-t / 5.2) * (1 + t / 9)
		local rest = p.rest.Position * self.reach
		local pos = rest + (p.from * self.reach - rest) * math.min(1, away) + sweep * along * p.pace * self.reach
		local turn = age + rush * rush * 0.10
		p.model:PivotTo(at * CF(pos) * p.rest.Rotation
			* A(p.spin.X * turn + away * 1.1 + p.tumble.X * rush * rush, p.spin.Y * turn + away * 1.4 + p.tumble.Y * rush * rush, p.spin.Z * turn + p.tumble.Z * rush * rush))
	end
	for _, s in self.streaks do
		local travel = (s.phase + (if motion then age * s.speed + 0.10 * (1 - math.exp(-age / 6)) else 0)) % 1
		local r0 = 1.8 + travel * 15 * (0.4 + s.z / 22)
		local dir = V(math.cos(s.angle) * 1.2, math.sin(s.angle), 0)
		local slide = sweep * along * 0.5
		s.a0.Position = V(focus.X, focus.Y, s.z) + dir * r0 + slide
		s.a1.Position = V(focus.X, focus.Y, s.z) + dir * (r0 + s.length * (0.5 + travel)) + slide
		local k = math.sin(travel * math.pi) * (1 - math.clamp(rush / gather, 0, 1))
		s.beam.Width0, s.beam.Width1 = s.width * 0.25 * k, s.width * k * (1 + s.z / 18)
	end
	if palm then
		local bob = if motion then math.sin(age / 7) * 0.05 else 0
		local rise = 1 - math.exp(-math.max(0, age - 6) / 4)
		self.star:PivotTo(CF(palm + V(0, (0.35 + 0.45 * rise + bob) * self.unit, 0)) * at.Rotation * A(0.2, age * 0.085, 0.15))
	end
end

function Glass:hide()
	if self.root then
		self.root.Parent, self.star.Parent = nil, nil
		for _, p in self.wipe do
			p.model.Parent = nil
		end
	end
end

function Glass:Destroy()
	if self.root then
		self.root:Destroy()
		self.star:Destroy()
		for _, p in self.wipe do
			p.model:Destroy()
		end
	end
end

return Glass
