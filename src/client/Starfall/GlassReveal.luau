-- The player's introduction. Real glass in real depth: a radial field behind
-- them, cut panels at several distances, streaks that run out of the focal
-- point, and large soft shards in front of the lens. The avatar stands in it.
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
-- The streaks converge a little above and beside the face.
local focus = V(0.5, 0.35, 0)

local function tri(parent, a, b, c, tint, material)
	local before = #parent:GetChildren()
	S.facet(parent, "Glass", a, b, c, tint, material)
	local made = {}
	local children = parent:GetChildren()
	for i = before + 1, #children do
		local p = children[i]
		p.CastShadow = false
		table.insert(made, p)
	end
	return made
end

-- Radial field. Narrow blades of uneven width, each a run of flat colours from
-- a white-hot centre to deep navy. Alternate blades are dimmer.
local rings = {
	{ 0.0, 2.4, "FFFFFF" }, { 2.4, 4.6, "DDF6FD" }, { 4.6, 7.2, "A6E8F8" }, { 7.2, 10.5, "6BD3F2" },
	{ 10.5, 15, "3DB2E8" }, { 15, 21, "2488D6" }, { 21, 29, "1B62B8" }, { 29, 52, "133F8C" },
}
local shadeRings = { "F4FCFE", "BDEAF7", "7FD8F2", "49BCE9", "2A97DC", "1E72C6", "174F9F", "0F3072" }

local function field(parent)
	local rng = Random.new(9102)
	local blades, angle = {}, 0
	while angle < math.pi * 2 - 0.02 do
		local width = math.min(rng:NextNumber(0.11, 0.32), math.pi * 2 - angle)
		local jitter = rng:NextNumber(0.72, 1.32)
		local dim = #blades % 2 == 1
		local model = S.group("Blade")
		model.Parent = parent
		local a0, a1 = angle, angle + width + 0.006
		local function at(r, a)
			return V(focus.X + math.cos(a) * r, focus.Y + math.sin(a) * r, depth)
		end
		for i, ring in rings do
			local k = if i == #rings then 1 else jitter
			local r0 = ring[1] * (if i == 1 then 1 else jitter)
			local r1 = ring[2] * k
			local tone = if dim then shadeRings[i] else ring[3]
			tri(model, at(r0, a0), at(r1, a0), at(r1, a1), tone)
			if r0 > 0 then
				tri(model, at(r0, a0), at(r1, a1), at(r0, a1), tone)
			end
		end
		table.insert(blades, { model = model, delay = rng:NextNumber(0, 2) })
		angle += width
	end
	return blades
end

-- A cut panel: a convex outline filled with glass, with lit bevels on the
-- edges that face the light.
local outlines = {
	{ { -0.5, -1 }, { 0.62, -0.72 }, { 0.28, 1.1 } },
	{ { -0.7, -0.6 }, { 0.5, -0.9 }, { 0.8, 0.5 }, { -0.2, 0.95 } },
	{ { -0.9, -0.35 }, { 0.95, -0.55 }, { 0.75, 0.3 }, { -0.75, 0.5 } },
	{ { -0.45, -0.85 }, { 0.45, -0.85 }, { 0.85, 0 }, { 0.4, 0.85 }, { -0.4, 0.85 }, { -0.85, 0 } },
	{ { -0.2, -1.2 }, { 0.35, -0.2 }, { 0.12, 1.2 }, { -0.4, 0.1 } },
}

local function panel(parent, shape, w, h, tint, alpha, thick)
	local model = S.group("Panel")
	local core = S.part(model, "Datum", CF(), Vector3.one * 0.02, "FFFFFF")
	core.Transparency, model.PrimaryPart = 1, core
	local pts = {}
	for i, q in outlines[shape] do
		pts[i] = V(q[1] * w, q[2] * h, 0)
	end
	local fills = {}
	-- Two kinds of cut: clear glass that bends the field behind it, and a
	-- frosted face that only lets its brightness through.
	local frosted = shape % 2 == 0
	for i = 2, #pts - 1 do
		for _, p in tri(model, pts[1], pts[i], pts[i + 1], if frosted then "E4F7FD" else tint, if frosted then M.SmoothPlastic else M.Glass) do
			p.Transparency, p.Reflectance = if frosted then 0.62 else alpha, if frosted then 0.05 else 0.16
			p.Size = V(math.max(p.Size.X, thick), p.Size.Y, p.Size.Z)
			table.insert(fills, p)
		end
	end
	local edges = {}
	for i, p in pts do
		local q = pts[i % #pts + 1]
		local facing = (q - p).Unit:Dot(V(-0.6, 0.8, 0))
		local lit = facing > 0.1
		local edge = S.strut(model, "Bevel", p, q, if lit then 0.030 else 0.012, 0.02, if lit then "E6F8FF" else "7CC8E6", if lit then M.Neon else M.SmoothPlastic)
		edge.CastShadow = false
		table.insert(edges, edge)
	end
	-- A soft diagonal reflection that slides as the panel turns.
	local glint = S.strut(model, "Reflection", V(-0.34 * w, -0.5 * h, -0.02), V(0.22 * w, 0.62 * h, -0.02), 0.09 * w, 0.01, "EAFBFF", M.Neon)
	glint.Transparency, glint.CastShadow, glint.Material = 0.75, false, M.SmoothPlastic
	model.Parent = parent
	return { model = model, fills = fills, edges = edges, glint = glint, alpha = alpha }
end

function Glass.new(stage)
	local self = setmetatable({ stage = stage }, Glass)
	return self
end

function Glass:build()
	if self.root then
		return
	end
	local rng = Random.new(4471)
	self.root = S.group("Glass stage")
	local anchor = S.part(self.root, "Origin", CF(), Vector3.one * 0.05, "FFFFFF")
	anchor.Transparency, self.root.PrimaryPart = 1, anchor
	self.anchor = anchor
	self.backdrop = S.group("Radial field")
	self.backdrop.Parent = self.root
	self.blades = field(self.backdrop)
	-- A huge navy card behind the blades keeps any aspect ratio covered.
	local card = S.part(self.root, "Deep field", CF(0, 0, depth + 1.2), V(220, 220, 0.2), "0E2E6C")
	card.CastShadow = false

	self.panels = {}
	local tints = { "BFF1FB", "8ADDF2", "6FB9EE", "DDF8FF", "5C93DA", "9BE8EA" }
	for i = 1, 34 do
		local a = i * 2.39996 + rng:NextNumber(-0.2, 0.2)
		local z = if i <= 9 then rng:NextNumber(13, 19) elseif i <= 26 then rng:NextNumber(6, 12) else rng:NextNumber(2.2, 5)
		local scale = (z + 6) / 12
		local r = (if i <= 9 then rng:NextNumber(2.6, 9) elseif i <= 26 then rng:NextNumber(3.0, 8.2) else rng:NextNumber(3.6, 6.4))
			* (if i > 26 then 0.95 else 1)
		local shape = (i - 1) % #outlines + 1
		local size = rng:NextNumber(1.1, 2.7) * scale
		local item = panel(self.root, shape, size * rng:NextNumber(0.5, 0.95), size * rng:NextNumber(1, 1.6),
			tints[(i - 1) % #tints + 1], rng:NextNumber(0.34, 0.62), 0.08)
		item.rest = CF(focus.X + math.cos(a) * r * 1.35, focus.Y + math.sin(a) * r, z)
			-- Long axis along the radius, tilted into depth so it catches light.
			* A(0, 0, a - math.pi / 2 + rng:NextNumber(-0.25, 0.25))
			* A(rng:NextNumber(-0.55, 0.55), rng:NextNumber(-0.7, 0.7), 0)
		item.out = V(math.cos(a) * 1.35, math.sin(a), 0).Unit
		item.delay = rng:NextNumber(0, 5) + (19 - z) * 0.22
		item.spin = V(rng:NextNumber(-0.16, 0.16), rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.05, 0.05))
		item.z = z
		table.insert(self.panels, item)
	end
	-- Foreground shards stay at the corners of the frame, never over the face.
	self.near = {}
	for i, q in { { -2.15, -1.12, -2.6, 2, 0.8 }, { 2.3, 1.15, -2.3, 5, 0.95 }, { 2.25, -1.25, -2.9, 1, 0.75 }, { -2.35, 1.2, -2.0, 4, 0.55 },
		{ -1.2, -1.75, -3.0, 3, 0.6 }, { 1.3, 1.75, -2.6, 3, 0.55 } } do
		local item = panel(self.root, q[4], q[5] * 0.6, q[5], tints[i % #tints + 1], 0.42, 0.04)
		item.rest = CF(q[1], q[2], q[3]) * A(0.3 * (i % 2), 0.5 - i * 0.2, i * 1.3)
		item.out = V(q[1], q[2], -0.5).Unit
		item.delay, item.spin, item.z = 2 + i * 0.8, V(0.1, -0.22, 0.06), q[3]
		table.insert(self.near, item)
	end
	-- What bursts from the crystal on the blow, before the stage is seen.
	self.eruption = {}
	for i = 1, 14 do
		local item = panel(S.group("x"), (i - 1) % #outlines + 1, rng:NextNumber(0.35, 0.8), rng:NextNumber(0.6, 1.3), tints[i % #tints + 1], 0.3, 0.05)
		local a = i * 2.39996
		item.dir = V(math.cos(a) * rng:NextNumber(0.35, 1), math.sin(a) * rng:NextNumber(0.35, 1) + 0.2, -rng:NextNumber(0.3, 1.5))
		item.speed = rng:NextNumber(1.1, 2.0)
		item.spin = V(rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.4, 0.4))
		table.insert(self.eruption, item)
	end
	self.flash = S.part(nil, "Flash", CF(), Vector3.one * 0.05, "FFFFFF")
	self.flash.Transparency, self.flash.CastShadow = 1, false
	local board = Instance.new("BillboardGui")
	board.LightInfluence, board.AlwaysOnTop, board.Parent = 0, false, self.flash
	local image = Instance.new("ImageLabel")
	image.Image, image.BackgroundTransparency, image.Size, image.Parent = "rbxasset://textures/particles/smoke_main.dds", 1, UDim2.fromScale(1, 1), board
	image.ImageColor3 = hex("E2F9FF")
	self.flashBoard, self.flashImage = board, image
	self.flashLight = S.light(self.flash, "BFF2FF", 24, 0)
	-- Streaks are unlit ribbons, additive and tapered, always facing the lens.
	self.streaks = {}
	for i = 1, 58 do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = anchor, anchor
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1, beam.FaceCamera, beam.Segments = a0, a1, true, 1
		beam.LightEmission, beam.LightInfluence = 0.9, 0
		local pale = i % 4 == 0
		beam.Color = ColorSequence.new(hex(if pale then "FFFFFF" else "7FF0FF"), hex(if pale then "BFF4FF" else "1C8CFF"))
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, if i > 46 then 0.82 elseif pale then 0.4 else 0.6), NumberSequenceKeypoint.new(1, 1),
		})
		beam.Parent = anchor
		table.insert(self.streaks, {
			beam = beam, a0 = a0, a1 = a1, angle = i * 2.39996, z = rng:NextNumber(1.5, 20), phase = rng:NextNumber(0, 1),
			speed = rng:NextNumber(0.012, 0.03), width = if i > 46 then rng:NextNumber(0.7, 1.5) else rng:NextNumber(0.03, 0.2),
			length = if i > 46 then rng:NextNumber(7, 12) else rng:NextNumber(2.5, 7),
		})
	end
	-- A hairline hex frame turns slowly behind the shoulders.
	self.halo = {}
	for i, r in { 3.1, 3.45 } do
		local model = S.group("Halo")
		local core = S.part(model, "Datum", CF(), Vector3.one * 0.02, "FFFFFF")
		core.Transparency, model.PrimaryPart = 1, core
		for k = 0, 5 do
			local p = V(math.cos(k * math.pi / 3) * r, math.sin(k * math.pi / 3) * r, 0)
			local q = V(math.cos((k + 1) * math.pi / 3) * r, math.sin((k + 1) * math.pi / 3) * r, 0)
			if i == 1 or k % 2 == 0 then
				S.strut(model, "Hairline", p, q, if i == 1 then 0.035 else 0.06, 0.02, "DFFAFF", M.Neon).CastShadow = false
			end
		end
		model.Parent = self.root
		table.insert(self.halo, model)
	end
	-- The last piece of the star, held over the open palm.
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
		tri(self.star, ring[k], ring[j], V(0.02, 0.64, 0), if k % 2 == 0 then "EAFBFF" else "9FE3F5")
		tri(self.star, ring[k], ring[j], V(-0.02, -0.46, 0), if k % 2 == 0 then "A58CE8" else "6CC4EA")
	end
	self.glow = S.light(core, "8FEFFF", 8, 0.3)
	-- Cool rim from behind, so any outfit separates from the field.
	self.rims = {}
	for _, p in { V(-3.2, 1.6, 2.6), V(3.4, 0.8, 2.4) } do
		local part = S.part(self.root, "Rim", CF(p), Vector3.one * 0.05, "FFFFFF")
		part.Transparency = 1
		table.insert(self.rims, S.light(part, "7FE4FF", 9, 0.3))
	end
end

-- `frame` places the origin at the face, looking at the camera's first mark.
function Glass:place(at, unit, reach)
	self:build()
	self.at, self.unit, self.reach = at, unit, reach
	self.root:PivotTo(at)
end

local function arrive(age)
	if age <= 0 then
		return 0
	end
	return 1 - math.exp(-age / 3.1) * math.cos(age * 0.33)
end

function Glass:erupt(frame, motion, tip, eye, unit)
	if not self.root then
		return
	end
	local age = frame - F.contact2
	local on = age >= 0 and frame < first and tip ~= nil and eye ~= nil
	self.flash.Parent = if on then self.stage else nil
	for _, p in self.eruption do
		p.model.Parent = if on and motion and age >= 1 then self.stage else nil
	end
	if not on then
		return
	end
	local view = CFrame.lookAt(tip, eye)
	local reach = (eye - tip).Magnitude
	self.flash.Position = tip
	local size = (2.2 + age * 2.6) * unit
	self.flashBoard.Size = UDim2.fromScale(size, size)
	self.flashImage.ImageTransparency = if motion then 0.05 + 0.1 * age else 0.5
	self.flashLight.Brightness = if motion then 1.6 else 0.6
	local t = age / (first - F.contact2)
	for _, p in self.eruption do
		if p.model.Parent then
			local far = t * t * 0.35 + t * 0.65
			local at = V(p.dir.X * reach * 0.42, p.dir.Y * reach * 0.36, p.dir.Z * reach * 0.62) * far * p.speed * 0.8
			p.model:PivotTo(view * CF(at) * A(p.spin.X * age * 2, p.spin.Y * age * 2, p.spin.Z * age * 2))
		end
	end
end

-- The same glass clears the lens as the world comes back.
function Glass:shed(frame, motion, eye, aim)
	local age = frame - last
	if not self.root or not motion or age < 0 or age > 10 then
		return
	end
	local view = CFrame.lookAt(eye, aim)
	for i, p in self.eruption do
		local u = age / 10
		p.model.Parent = if age < 10 then self.stage else nil
		local out = 0.85 + 3.4 * u * u + 0.7 * u
		p.model:PivotTo(view * CF(p.dir.X * 2.6 * out, p.dir.Y * 1.7 * out, -4.6 + 1.6 * u * p.speed)
			* A(p.spin.X * age * 1.6, p.spin.Y * age * 1.6, p.spin.Z * age * 1.6 + i))
	end
end

function Glass:draw(frame, motion, palm)
	if not self.root or not self.at then
		return
	end
	local active = frame >= first and frame < last
	self.root.Parent = if active then self.stage else nil
	self.star.Parent = if active and palm then self.stage else nil
	if not active then
		return
	end
	local age = if motion then frame - first else 30
	local exit = if motion then S.ease(frame, last - 7, last) else 0
	local at = self.at
	-- The field opens like an iris, blade by blade, then keeps turning a little.
	for _, blade in self.blades do
		local open = arrive(age + 4 - blade.delay * 1.4)
		blade.model:PivotTo(at * CF(focus.X, focus.Y, 0) * A(0, 0, (1 - open) * 0.5 + age * 0.0012) * CF(-focus.X, -focus.Y, (1 - math.min(open, 1)) * 5))
	end
	for group, list in { self.panels, self.near } do
		for i, p in list do
			local n = arrive(age - p.delay)
			local drift = age * 0.011 * (if group == 1 then (19 - p.z) / 19 else 1.2)
			local off = p.out * ((1 - n) * 11 + drift * 0.6 + exit * exit * 12)
			local toward = -(1 - n) * 4 - exit * exit * (p.z + 5)
			local rest = p.rest.Rotation + p.rest.Position * self.reach
			p.model:PivotTo(at * CF(off + V(0, 0, toward)) * rest
				* A(p.spin.X * age / 6 + (1 - n) * 1.4, p.spin.Y * age / 6 + (1 - n) * 1.8, p.spin.Z * age / 9 + exit * (if i % 2 == 0 then 1 else -1)))
			p.glint.Transparency = 0.68 + 0.3 * math.sin(age / 8 + i * 1.7) ^ 2
		end
	end
	for _, s in self.streaks do
		local travel = (s.phase + (if motion then age * s.speed * (1 + 2.2 * math.exp(-age / 6)) else 0)) % 1
		local r0 = 1.6 + travel * 15 * (0.4 + s.z / 22)
		local dir = V(math.cos(s.angle) * 1.2, math.sin(s.angle), 0)
		s.a0.Position = V(focus.X, focus.Y, s.z) + dir * r0
		s.a1.Position = V(focus.X, focus.Y, s.z) + dir * (r0 + s.length * (0.5 + travel) * (1 + 1.6 * math.exp(-age / 5)))
		local k = math.sin(travel * math.pi) * (1 - exit)
		s.beam.Width0, s.beam.Width1 = s.width * 0.25 * k, s.width * k * (1 + s.z / 18)
	end
	for i, ring in self.halo do
		local n = arrive(age - 3 - i * 2)
		ring:PivotTo(at * CF(focus.X * 0.5, -0.1, 4.5 + i) * A(0, 0, (if i == 1 then 1 else -1) * (age * 0.006 + (1 - n) * 1.2)) * CF(0, 0, (1 - n) * 14))
	end
	if palm then
		local n = arrive(age - 9)
		local bob = if motion then math.sin(age / 7) * 0.05 else 0
		self.star:PivotTo(CF(palm + V(0, (0.8 + bob) * self.unit, 0)) * at.Rotation * A(0.2, age * 0.09, 0.15) * CF(0, (1 - n) * 1.5, 0))
		self.glow.Brightness = 0.3 * math.clamp(n, 0, 1)
	end
	for i, rim in self.rims do
		rim.Brightness = 0.3
	end
end

function Glass:hide()
	if self.root then
		self.root.Parent, self.star.Parent, self.flash.Parent = nil, nil, nil
		for _, p in self.eruption do
			p.model.Parent = nil
		end
	end
end

function Glass:Destroy()
	if self.root then
		self.root:Destroy()
		self.star:Destroy()
		self.flash:Destroy()
		for _, p in self.eruption do
			p.model:Destroy()
		end
	end
end

return Glass
