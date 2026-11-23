local P = require(script.Parent.Props)
local Plume = require(script.Parent.Plume)
local Fault = require(script.Parent.SurfaceFault)
local Crown = require(script.Parent.CinderCrown)
local Wave = require(script.Parent.Shockwave)
local Coast = require(script.Parent.LandfallCoast)
local Descent = require(script.Parent.Descent)
local Jets = require(script.Parent.EjectaJets)
local Crater = require(script.Parent.Crater)
local Strike = {}
Strike.__index = Strike

local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local rgb, ease, tau = Color3.fromHex, P.ease, math.pi * 2
local stone, neon = Enum.Material.Slate, Enum.Material.Neon
local flightTime = require(script.Parent.Beats).impact
local impact = V(0, Crater.coverHeight + 1.5, 0)
local approach = V(-407, 266, -238)
Strike.impactTime = flightTime

-- Distance along one entry line, with a slow first sighting, a near pass
-- and a last steep plunge. Tangents are fractions of the run per second.
local flight = {
	{ 0, 0, 0.048 },
	{ 1.36, 0.115, 0.16 },
	{ 2.46, 0.395, 0.31 },
	{ 3.24, 0.575, 0.15 },
	{ 4.28, 0.727, 0.16 },
	{ 5.60, 0.856, 0.052 },
	{ 6.23, 0.914, 0.18 },
	{ flightTime, 1, 0.43 },
}
function Strike.position(t)
	local s = math.min(t, 0) * flight[1][3]
	if t >= flightTime then
		s = 1
	elseif t > 0 then
		for i = 2, #flight do
			local a, b = flight[i - 1], flight[i]
			if t <= b[1] then
				local span = b[1] - a[1]
				local u = (t - a[1]) / span
				local v = 1 - u
				s = a[2] * v * v * (1 + 2 * u) + b[2] * u * u * (3 - 2 * u) + span * u * v * (a[3] * v - b[3] * u)
				break
			end
		end
	end
	return impact + approach * (1 - s) + V(-9, 23, 6) * math.sin(math.pi * s)
end

local function between(p, base, a, b, width, height)
	p.Size = V(width, height, math.max(0.06, (b - a).Magnitude))
	p.CFrame = base * CFrame.lookAt((a + b) * 0.5, b)
end

local function place(p, parent)
	if p.Parent ~= parent then
		p.Parent = parent
	end
end

local function ball(parent, name, at, size, hue, mat)
	local p = P.sphere(parent, name, at, size, hue, mat)
	p.CastShadow = mat ~= neon
	return p
end

local function ellipse(parent, name, color, mat)
	return ball(parent, name, Vector3.zero, Vector3.one, color, mat)
end

local function marker(parent, name, at)
	local anchor = P.box(parent, name, at, Vector3.one, "FFFFFF")
	anchor.Transparency, anchor.CastShadow = 1, false
	return anchor
end

local function ribbon(anchor, a, b, near, far, color, fade)
	local first, last = Instance.new("Attachment", anchor), Instance.new("Attachment", anchor)
	first.Position, last.Position = a, b
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = first, last
	beam.FaceCamera, beam.Width0, beam.Width1 = true, near, far
	beam.Color, beam.Transparency = color, fade
	beam.Texture, beam.TextureMode = "rbxasset://textures/particles/smoke_main.dds", Enum.TextureMode.Stretch
	beam.Parent = anchor
	return beam, last
end

local function sprite(parent, name, asset, brightness)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.AlwaysOnTop, gui.LightInfluence, gui.Brightness = name, false, 0, brightness
	gui.Size, gui.Parent = UDim2.fromScale(1, 1), parent
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency, image.Size = 1, UDim2.fromScale(1, 1)
	image.Image, image.Parent = "rbxasset://textures/particles/" .. asset, gui
	return gui, image
end

local sculptures = script.Parent.ImpactSculptures

local function sculpt(parent, asset, name, scale)
	local model = sculptures[asset]:Clone()
	model.Name = name
	if scale then
		model:ScaleTo(scale)
	end
	model.Parent = parent
	return model
end

local sliverOffset = CF(0.62, 0.52, 2.66) * A(-0.19, 0.21, -0.78)
-- The cleft turns toward the lens and hangs there. Only the body rolls on
-- exposed poses. The center of mass and its trailing wake keep flying.
local flightDrawings = {
	{ 0, 0.22, 0.38, -0.11 },
	{ 0.44, 0.39, 0.54, -0.17 },
	{ 0.66, 0.55, 0.72, -0.21 },
	{ 0.82, 0.70, 1.02, -0.07 },
	{ 0.94, 0.81, 1.36, 0.10 },
	{ 1.02, 0.87, 1.48, 0.19 },
	{ 1.68, 0.94, 1.81, 0.32 },
	{ 1.79, 1.10, 2.24, 0.61 },
	{ 1.88, 1.36, 2.87, 1.15 },
	{ 2.01, 1.68, 3.53, 1.57 },
	{ 2.23, 1.86, 3.80, 1.63 },
}
local function meteorPose(t)
	local key = flightDrawings[1]
	for _, drawing in flightDrawings do
		if t < drawing[1] then
			break
		end
		key = drawing
	end
	local turns = math.max(0, math.floor((t - 2.43) * 12) / 12)
	return CF(Strike.position(t)) * A(key[2] + turns * 0.74, key[3] + turns * 1.30, key[4] + turns * 0.82)
end

function Strike.frame(t, motion)
	return Descent.frame(t, motion, Strike.position)
end
Strike.surfaceFrame = Descent.surface

local function buildMeteor(root)
	local body = sculpt(root, "Fluted iron", "Starfall meteor")
	local core = P.crystal(body, Vector3.zero, 1.57)
	core.Name = "Starfall core"
	-- A violet cleft rings the same asymmetric crystal before and after breakup.
	for i, p in core:GetChildren() do
		if p.Name == "Facet" then
			p.Color = p.Color:Lerp(rgb("9859DF"), 0.30)
			if i % 8 == 1 or i % 8 == 2 then
				p.Material = neon
				p.Color = rgb("BC8AEA")
			end
		end
	end
	for i, off in { V(-0.57, -0.64, 0.05), V(0.50, -0.8, -0.11) } do
		local rind = sculpt(core, "Spall", "Fused meteoritic iron", 0.43 + 0.05 * i)
		rind:PivotTo(CF(off) * A(0.44 * i, -i, 0.28))
	end
	core:PivotTo(sliverOffset)
	P.light(body.PrimaryPart, "FFAB76", 42, 2.75)
	return body, core
end

local function knot(parent, position, tangent)
	local a = Instance.new("Attachment")
	a.Position, a.Axis = position, tangent.Unit
	a.Parent = parent
	return a
end

local function beam(parent, from, to, width, tip, color, alpha)
	local b = Instance.new("Beam")
	b.FaceCamera, b.Segments = true, 10
	b.Attachment0, b.Attachment1 = from, to
	b.Width0, b.Width1, b.Color, b.Transparency = width, tip, color, alpha
	b.Parent = parent
	return b
end

local function gradient(a, b, c, breakpoint)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(a)),
		ColorSequenceKeypoint.new(breakpoint or 0.42, rgb(b)),
		ColorSequenceKeypoint.new(1, rgb(c)),
	})
end

local function buildWake(self)
	local wake = P.model(self.root, "Plasma wake")
	self.wake = wake
	local anchor = marker(wake, "Ablation streamlines", Vector3.zero)
	self.wakeAnchor = anchor
	local flame = gradient("FFF0BD", "FFBA6A", "CC7596")
	local fading = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.4, 0.20),
		NumberSequenceKeypoint.new(1, 1),
	})
	self.streams = {}
	for i = 1, 9 do
		-- Each spline leaves the flank of the body and tears off into the slipstream.
		-- An opaque narrow streak travels inside its translucent, much broader envelope.
		local a = tau * i / 9
		local rim = V(math.cos(a), math.sin(a), 0)
		local near = knot(anchor, rim * 2.3 + V(0, 0, 0.75), (rim * 0.62 - V(0, 0, 1)).Unit)
		local tip = knot(anchor, V(0, 0, -20), -Vector3.zAxis)
		local plume = beam(anchor, near, tip, 1.9 + i % 3 * 0.48, 0.18, flame, fading)
		plume.Texture, plume.TextureMode = "", Enum.TextureMode.Stretch
		plume.CurveSize0, plume.LightEmission, plume.LightInfluence = 6.8, 0.48, 0.08
		local spine = beam(
			anchor,
			near,
			tip,
			0.10 + i % 3 * 0.075,
			0.02,
			gradient("FFF3C9", "F4BA76", "D88C9B", 0.56),
			NumberSequence.new(0.34, 1)
		)
		spine.CurveSize0, spine.LightEmission, spine.LightInfluence = plume.CurveSize0, 0.94, 0
		self.streams[i] = { theta = a, tip = tip, outer = plume, inner = spine }
	end
	local haze, tip = ribbon(
		anchor,
		V(0, 0, -1),
		V(0, 3, -48),
		7.8,
		0.8,
		gradient("F9CAA4", "C3909C", "9789A1"),
		NumberSequence.new(0.19, 1)
	)
	haze.LightEmission, haze.TextureSpeed, haze.CurveSize0, haze.CurveSize1 = 0.40, -0.18, 13, 7
	haze.Attachment0.Axis, haze.Attachment1.Axis = V(0.14, 0.08, -1).Unit, V(-0.2, 0.1, -1).Unit
	self.wakeEnd = tip

	-- A thin band of compressed air bends around the windward cheek of the stone.
	for i = 1, 7 do
		local a, b = tau * (i - 1) / 7, tau * i / 7
		local u, v = V(math.cos(a), math.sin(a), 0), V(math.cos(b), math.sin(b), 0)
		local start = knot(anchor, u * 2.72 + V(0, 0, 1.05), V(-u.Y, u.X, 0.12).Unit)
		local finish = knot(anchor, v * 2.72 + V(0, 0, 1.05), V(-v.Y, v.X, -0.08).Unit)
		local bow = beam(
			anchor,
			start,
			finish,
			0.10,
			0.045,
			gradient("FFC785", "FFBA76", "F0919B"),
			NumberSequence.new(0.08, 0.40)
		)
		bow.CurveSize0, bow.CurveSize1, bow.LightEmission = 0.46, 0.46, 0.94
	end
	self.fire = {}
	for i = 1, 6 do
		local mark = marker(wake, "Sheared copper vapor", Vector3.zero)
		local gui, density = Plume.mount(mark, "melt")
		self.fire[i] = { mark = mark, gui = gui, density = density }
	end
	self.smoke = {}
	for i = 1, 10 do
		local mark = marker(wake, "Ablated dust", Vector3.zero)
		local gui, img = sprite(mark, "Fine ash", "smoke_main.dds", 1.35)
		img.ImageColor3 = rgb(if i % 3 == 0 then "D2A39F" else "B49AA2")
		self.smoke[i] = { mark = mark, gui = gui, img = img }
	end
	self.sparks = {}
	for i = 1, 14 do
		self.sparks[i] = ellipse(wake, "Fusion spark", if i % 5 == 0 then "CBB4F3" else "FFCB83", neon)
	end
end

local function drawWake(self, t, base)
	local head = Strike.position(t)
	local reverse = (Strike.position(t - 0.04) - head).Unit
	local side = reverse:Cross(Vector3.yAxis).Unit
	local up = side:Cross(reverse).Unit
	local length = math.clamp((Strike.position(t - 0.85) - head).Magnitude * 1.51, 27, 73)
	self.wakeAnchor.CFrame = base * CFrame.lookAt(head, head + reverse)
	self.wakeEnd.Position = V(1 + 1.5 * math.cos(t * 1.5), 3.8, -length)
	for i, s in self.streams do
		local phi = s.theta + 0.49 * math.sin(t * 2.2 + i)
		local span = length * (0.34 + 0.17 * math.sin(i * 2.2) + 0.09 * math.sin(t * 3 + i))
		local radius = 1.0 + 0.88 * math.cos(i * 2 + t * 1.8)
		s.tip.Position = V(math.cos(phi) * radius, math.sin(phi) * radius + 0.7, -span)
		s.tip.Axis = V(0.3 * math.sin(phi + 0.84), 0.3 * math.cos(phi), -1).Unit
		s.inner.CurveSize1 = span * 0.24
		s.outer.CurveSize1 = span * 0.24
	end
	for i, k in self.fire do
		local u = ((i - 1) / #self.fire + t * 0.62) % 1
		local phi = i * 2.39 + t * 2.24
		local slip = (side * math.cos(phi) + up * math.sin(phi)) * (0.38 + 1.10 * u)
		k.mark.Position = base:PointToWorldSpace(head + reverse * (1.4 + u * length * 0.51) + slip + up * u * u)
		local size = 5.8 - 3.1 * u
		k.gui.Size = UDim2.fromScale(size * 1.31, size)
		Plume.show(k.gui, k.density, i * 67 + t * 24, 0.59 * ease(u, -0.055, 0.12) * (1 - ease(u, 0.56, 1)))
	end
	for i, s in self.smoke do
		local u = ((i - 1) / #self.smoke + t * 0.34) % 1
		local slip = (side * math.sin(i * 2.1 + t) + up * math.cos(i * 2.1 + t)) * (0.32 + 2.0 * u)
		s.mark.Position =
			base:PointToWorldSpace(head + reverse * (3 + length * (0.13 + 0.89 * u)) + slip + up * u * u * 4.2)
		local size = 4.1 + u * 3.6
		s.gui.Size = UDim2.fromScale(1.3 * size, size)
		s.img.ImageTransparency = 1 - 0.43 * ease(u, 0, 0.16) * (1 - ease(u, 0.44, 1))
		s.img.Rotation = i * 42 + t * (if i % 2 == 0 then 24 else -22)
	end
	for i, p in self.sparks do
		local u = (t * (0.73 + i % 3 * 0.14) + i * 0.618) % 1
		local a = i * 2.399
		local outward = (side * math.cos(a) + up * math.sin(a)) * (2.25 + u * (3 + i % 5))
		local pos = head + reverse * (1 + u * length * 0.8) + outward
		local w = 0.09 + (1 - u) * 0.18
		between(p, base, pos, pos + reverse * (1.45 + u * 3.4), w, w)
		p.Transparency = 0.07 + 0.93 * u * u
	end
end

local function craterBed(self, rng)
	self.crater = P.model(self.root, "Buried Starfall")
	self.bed = Crater.new(self.root)
	self.rimRocks = {}
	for i = 1, 17 do
		local angle = i * 2.399
		local rock = sculpt(
			self.bed.root,
			if i % 3 == 0 then "Slag blade" else "Spall",
			"Torn crater lip",
			rng:NextNumber(0.82, 1.7)
		)
		local p = Crater.ground(0.80, angle) + V(0, 2.05, 0)
		table.insert(self.rimRocks, { rock = rock, point = p, angle = angle, delay = 0.24 + 0.024 * (i % 5) })
	end
	self.fissure = Fault.new(self.crater, self.bed)
	self.levitation = P.model(self.root, "Shadow before landfall")
	self.groundGrit = {}
	for i = 1, 9 do
		local a = i * 2.39
		local r = if i == 1 then 0.14 else 0.72 + 0.19 * i
		local x, z = math.cos(a) * r, math.sin(a) * r
		local size = if i == 1 then 0.55 else 0.14 + 0.07 * (i % 4)
		local pebble = P.part(
			self.levitation,
			"Loose basalt",
			V(size * 1.62, size, size * 0.86),
			CFrame.identity,
			rgb(if i % 3 == 0 then "74625F" else "463C49"),
			"WedgePart"
		)
		pebble.Material = stone
		local shade = ball(self.levitation, "Contact shadow", Vector3.zero, Vector3.one, "4D3E47")
		shade.CastShadow = false
		table.insert(self.groundGrit, { part = pebble, shade = shade, x = x, z = z, size = size, phase = i * 0.62 })
	end
	self.penumbra = ball(self.levitation, "Moving meteor penumbra", Vector3.zero, Vector3.one, "413840")
	self.penumbra.CastShadow = false
	self.windLight = marker(self.levitation, "Incoming light", V(-4, 3, -4))
	self.warnLamp = P.light(self.windLight, "FFCB8D", 18, 0)
end

local function buildImpact(self, rng)
	craterBed(self, rng)
	local crown = P.model(self.root, "Impact crown")
	self.crown = crown
	self.flash = marker(crown, "Contact heat", Vector3.zero)
	self.impactLight = P.light(self.flash, "FFC57D", 48, 2)
	self.bounce = marker(crown, "Violet scattering", Vector3.zero)
	self.underlight = P.light(self.bounce, "A4ACC5", 34, 0)
	self.jets = Jets.new(crown)
	self.paint = Crown.new(crown, self.shelf)
	self.ejecta = {}
	for i = 1, 19 do
		local s = if i % 4 == 0 then rng:NextNumber(1.9, 3.1) else rng:NextNumber(0.63, 1.45)
		if i == 4 then
			s = 4.25
		elseif i == 12 then
			s = 3.70
		end
		local a = i * 2.399
		local v = V(
			math.cos(a) * rng:NextNumber(12, 39) + 6.2,
			rng:NextNumber(16, 38),
			math.sin(a) * rng:NextNumber(11, 29) + 4
		)
		local rock = sculpt(crown, if i % 3 == 0 then "Slag blade" else "Spall", "Spalled rock", s)
		local tail, tip = ribbon(
			rock.PrimaryPart,
			Vector3.zero,
			V(1, -3, 0),
			0.41 + s * 0.35,
			0.06,
			gradient("FFC78B", "D7A480", "A89698"),
			NumberSequence.new(0.17, 1)
		)
		tail.LightEmission, tail.LightInfluence = 0.58, 0.12
		if i == 4 then
			v = V(-37, 31, 32)
		elseif i == 12 then
			v = V(18, 40, 37)
		end
		self.ejecta[i] =
			{ rock = rock, tail = tail, tip = tip, v = v, spin = 1.5 / math.sqrt(s), delay = 0.04 + (i % 5) * 0.045 }
	end
end

function Strike.new(shelf)
	local root = P.model(shelf, "Primordial cove")
	local self = setmetatable({ root = root, shelf = shelf }, Strike)
	local rng = Random.new(58237)
	self.shore = Coast.new(root)
	self.wave = Wave.new(root, self.shore)
	self.meteor, self.shard = buildMeteor(root)
	buildWake(self)
	buildImpact(self, rng)
	return self
end

local function drawBlast(self, t, base, motion)
	local age = t - flightTime
	local ventHeight = Crater.contactHeight(age)
	local vent = base * CF(0, ventHeight, 0)
	self.flash.Position = vent:PointToWorldSpace(V(1.2, 1.45, 0.5))
	self.bounce.Position = base * V(-18, 17, 13)
	self.impactLight.Color = rgb(if age < 0.28 then "FFF1B1" elseif age < 0.68 then "FFD394" else "F9B28D")
	self.impactLight.Brightness = (if motion then 1.65 else 1.10) * (1 - ease(age, 0.63, 1.16))
	self.underlight.Brightness = 0.43 * ease(age, 0.52, 0.78) * (1 - ease(age, 1.22, 1.60))
	self.jets.origin.CFrame = base
	self.jets:draw(age)
	self.paint:draw(age, base, vent, motion)
	for i, e in self.ejecta do
		local s = age - e.delay
		local birth = Crater.contactHeight(e.delay)
		local function point(h)
			return e.v * h + V(0, birth - 21.4 * h * h, 0)
		end
		local p = point(math.max(0, s))
		local visible = s >= 0 and p.Y > -4
		place(e.rock, if visible then self.crown else self.shelf)
		if visible then
			local spin = s * e.spin
			local cf = CF(p) * A(spin * (2.3 + i % 3), i + spin * 2.8, spin * 1.6)
			e.rock:PivotTo(base * cf)
			e.tip.Position = cf:PointToObjectSpace(point(math.max(0, s - 0.17)))
			e.tail.Enabled = s < 1.4
		end
	end
end

local function groundInsert(self, t, base)
	local hold = ease(t, 5.64, 6.19)
	for _, grain in self.groundGrit do
		local beat = t - 0.018 * grain.phase
		local u = if beat < 5.75
			then 0
			elseif beat < 5.89 then 0.18
			elseif beat < 6.06 then 0.38
			elseif beat < 6.18 then 0.86
			else 1
		local up = (0.36 + 0.52 * (1 + math.cos(grain.phase))) * u
		local y = 0.18 + grain.size * 0.42
		grain.part.CFrame = base
			* CF(grain.x, y + up, grain.z)
			* A(grain.phase * 0.42 + u * 0.7, grain.phase, grain.phase * 0.62 + u * 1.12)
		grain.shade.Size = V(1.39, 0.025, 0.75) * grain.size * (1 + up * 0.75)
		grain.shade.CFrame = base * CF(grain.x - 0.14 * up, 0.20, grain.z + 0.11 * up)
		grain.shade.Transparency = 0.36 + 0.27 * u
	end
	self.penumbra.Size = V(3 + 18 * hold, 0.035, 2 + 10.2 * hold)
	self.penumbra.CFrame = base * CF(-10 + 10.5 * hold, 0.223, -5 + 4.7 * hold) * A(0, -0.43, 0)
	self.penumbra.Transparency = 0.72 - 0.35 * hold
	self.warnLamp.Brightness = 0.50 + 2.2 * hold * (1 - ease(t, 6.28, 6.49))
end

function Strike:draw(t, base, motion)
	local flying = t < flightTime
	local age = t - flightTime
	self.bed:draw(age, base)
	self.wave:draw(age, base)
	for _, v in self.rimRocks do
		local rise = ease(age, v.delay, v.delay + 0.43)
		if rise ~= v.last then
			v.last = rise
			place(v.rock, if rise > 0 then self.bed.root else self.shelf)
			if rise > 0 then
				v.rock:PivotTo(
					base
						* CF(v.point + V(0, -3.4 * (1 - rise), 0))
						* A(0.16 * math.sin(v.angle), -v.angle, 0.32 + 1.1 * (1 - rise))
				)
			end
		end
	end
	local insert = t >= 5.54 and flying
	place(self.levitation, if insert then self.root else self.shelf)
	if insert then
		groundInsert(self, t, base * CF(0, Crater.coverHeight, 0))
	end
	place(self.wake, if flying then self.root else self.shelf)
	place(self.meteor, if flying then self.root else self.shelf)
	-- The iron and its inset violet nucleus disappear together on contact.
	-- Only light can escape the broken ground after the pressure wave passes.
	if flying then
		self.paint:prepare(t)
		local posed = base * meteorPose(t)
		self.meteor:PivotTo(posed)
		self.shard:PivotTo(posed * sliverOffset)
		drawWake(self, t, base)
	end
	local flame = age >= 0 and t < 9.40
	place(self.crown, if flame then self.root else self.shelf)
	if flame then
		drawBlast(self, t, base, motion)
	end
	local exposed = t >= 8.34
	place(self.bed.inner, if exposed then self.shelf else self.bed.root)
	place(self.crater, if exposed then self.root else self.shelf)
	if exposed then
		self.fissure:draw(t, base)
	end
end

return Strike
