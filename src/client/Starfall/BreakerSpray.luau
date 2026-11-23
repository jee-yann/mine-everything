-- Spray is struck into the air by the travelling crest at this specific place
-- on the offshore strait. Pieces cross the camera plane and continue behind it.
local S = require(script.Parent.Scenery)
local Sprite = require(script.Parent.WorldSprite)
local clock = require(script.Parent.Timeline)
local Breaker = {}
Breaker.__index = Breaker
local V, CF = Vector3.new, CFrame.new
-- Heading, distance in front of the observer, fan, and exposure length.
-- All marks are fragments carried within the actual airborne front.
local shears = {
	forewash = { 8, 46, 38, 12 },
	skimming = { -19, 38, 21, 21 },
	splinters = { -36, 18, 24, 29 },
	downwind = { 21, 25, 16, 18 },
}

function Breaker.new()
	local root = S.group("Crest thrown past the offshore camera")
	local marks, curtains = {}, {}
	local eye = clock.breakerEye
	local centre = V(0, 26, -32)
	local direction = (eye - centre).Unit
	local rng = Random.new(1776)
	local line = V(eye.X, 0, eye.Z + 32).Unit
	local across = line:Cross(Vector3.yAxis)
	for i = 1, 34 do
		local side = rng:NextNumber(-15, 15)
		-- Leave a window at the wave centre so the mine still reads behind it.
		if math.abs(side) < 1.75 then
			side += if side < 0 then -1.15 else 1.15
		end
		local start = eye - direction * rng:NextNumber(7, 23) + across * side + V(0, rng:NextNumber(-9, 7), 0)
		local velocity = direction * rng:NextNumber(58, 91)
			+ across * rng:NextNumber(-12, 12)
			+ V(0, rng:NextNumber(-1, 18), 0)
		local stone = i % 4 == 0
		local width = if stone then rng:NextNumber(0.31, 0.68) else rng:NextNumber(0.06, 0.25)
		local length = if stone then width * 1.8 else rng:NextNumber(1.2, 3.7)
		local body = S.part(
			root,
			if stone then "Airborne basalt" else "Entrained dust shear",
			CF(),
			V(width, width * 0.7, length),
			if stone then "4D3D45" elseif i % 3 == 0 then "E8D1AD" else "DDD8C9",
			if stone then Enum.Material.Slate else Enum.Material.SmoothPlastic,
			"WedgePart"
		)
		body.CastShadow = false
		table.insert(marks, {
			part = body,
			origin = start,
			velocity = velocity,
			delay = rng:NextNumber(-0.19, 0.18),
			stone = stone,
			spin = rng:NextNumber(-9, 9),
			angle = rng:NextNumber(-math.pi, math.pi),
		})
	end
	local axis = S.part(root, "Pressure centre", CF(), Vector3.one * 0.1, "FFFFFF")
	axis.Transparency = 1
	axis.CastShadow = false
	local heading = math.atan2(line.Z, line.X)
	for i = 1, 27 do
		local left, right = Instance.new("Attachment"), Instance.new("Attachment")
		left.Parent = axis
		right.Parent = axis
		local beam = Instance.new("Beam")
		beam.Attachment0 = left
		beam.Attachment1 = right
		beam.FaceCamera = true
		beam.Segments = 8
		beam.Texture = "rbxasset://textures/particles/smoke_main.dds"
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = 16 + rng:NextNumber(0, 14)
		beam.TextureSpeed = 0
		beam.LightEmission = 0.24
		beam.LightInfluence = 0.42
		beam.Color =
			ColorSequence.new(Color3.fromHex(if i % 3 == 0 then "C0D8D4" else "E9D8B3"), Color3.fromHex("B0ABB2"))
		local band = if i <= 14 then 1 elseif i <= 22 then 2 else 3
		local height = (eye.Y - centre.Y) * ({ 0.18, 0.52, 1 })[band] + rng:NextNumber(-7, 7)
		local angle = if i == 25 then heading - 0.13 else heading + rng:NextNumber(-2.48, 2.48)
		beam.Name = "Torn condensation sheet"
		beam.Parent = axis
		local alpha = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.99),
			NumberSequenceKeypoint.new(0.17, 0.45),
			NumberSequenceKeypoint.new(0.57, if band == 3 then 0.33 else 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.Transparency = alpha
		curtains[i] = {
			b = beam,
			a = left,
			c = right,
			angle = angle,
			height = height,
			span = rng:NextNumber(0.11, 0.38),
			rise = rng:NextNumber(-7, 10),
			band = band,
			age = rng:NextNumber(-0.08, 0.09),
		}
	end
	local radial = eye - centre
	local tangent = (-direction):Cross(Vector3.yAxis).Unit
	local sky = tangent:Cross(-direction).Unit
	-- An optical aftershock catches the sea, ash and rock at separate depths.
	-- These caustics travel with the returning front, under the colored print.
	local caustics = {}
	for i, offset in { V(60, 15, 62), V(109, 3, 102), V(160, -13, 89), V(206, -14, 103) } do
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Parent, b.Parent = axis, axis
		local trace = Instance.new("Beam")
		trace.Name, trace.FaceCamera, trace.Segments = "Spectral edge across the coast", true, 8
		trace.Attachment0, trace.Attachment1 = a, b
		trace.Width0, trace.Width1 = 0.90 + i * 0.25, 0.05
		trace.Transparency, trace.LightInfluence, trace.LightEmission = NumberSequence.new(0.19, 0.87), 0, 0.20
		trace.Enabled, trace.Parent = false, axis
		local lamp = S.light(a, "8B67FF", 56, 5.6)
		lamp.Enabled = false
		caustics[i] = { start = a, finish = b, trace = trace, lamp = lamp, offset = offset }
	end
	local flecks = {}
	for i = 1, if game:GetService("UserInputService").TouchEnabled then 14 else 22 do
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Parent, b.Parent = axis, axis
		local stroke = Instance.new("Beam")
		stroke.Name, stroke.Attachment0, stroke.Attachment1 = "Ablated grit in the pressure front", a, b
		stroke.FaceCamera, stroke.Segments, stroke.LightInfluence = true, 3, 0
		stroke.LightEmission = if i % 3 == 0 then 0.35 else 0
		stroke.Color = ColorSequence.new(Color3.fromHex(if i % 3 == 0 then "FFC595" else "17191D"))
		stroke.Transparency, stroke.Enabled, stroke.Parent = NumberSequence.new(0.12, 0.68), false, axis
		flecks[i] = {
			a = a,
			b = b,
			stroke = stroke,
			angle = rng:NextNumber(0, math.pi * 2),
			distance = rng:NextNumber(0.56, 1.20),
			skew = rng:NextNumber(-1, 1),
			depth = rng:NextNumber(-3, 4),
		}
	end
	local fog = {}
	for i = -1, 1 do
		local origin = eye - centre - direction * 12 + across * (i * 11) + V(0, if i == 0 then -6 else 2, 0)
		for j = 1, 4 do
			local drift = direction * (5.8 + 1.3 * j)
				+ across * (0.69 * j - 1.4) * ((i % 2) * 2 - 1)
				+ V(0, 2.6 + 0.72 * j, 0)
			table.insert(fog, {
				sprite = Sprite.new(axis, "Lofted ash at the camera", Sprite.smoke, 0.38),
				origin = origin + across * (j - 2.5) * 1.3 + V(0, (j % 3 - 1) * 1.73, 0),
				drift = drift,
				birth = (j - 1) * 0.032 + 0.015 * (i + 1),
				life = 0.37 + 0.052 * ((j + i) % 4),
				angle = i * 37 + j * 64,
			})
		end
	end
	return setmetatable({
		root = root,
		marks = marks,
		curtains = curtains,
		flecks = flecks,
		caustics = caustics,
		tangent = tangent,
		sky = sky,
		observer = radial,
		direction = direction,
		fog = fog,
		axis = axis,
		centre = centre,
		radius = (eye - centre) * V(1, 0, 1),
	}, Breaker)
end

function Breaker:draw(t, stage, base, camera, exposure, frame)
	if t < clock.waveLaunch or t > 8.68 then
		self.root.Parent = nil
		return
	end
	self.root.Parent = stage
	local name = if exposure then exposure.pose else nil
	self.axis.CFrame = base * CF(self.centre)
	local ion = exposure and exposure.mode == "ultraviolet"
	local ember = exposure and exposure.mode == "ember"
	for i, c in self.caustics do
		c.trace.Enabled, c.lamp.Enabled = ion == true or ember == true, ion == true or ember == true
		if c.trace.Enabled then
			local phase = (frame - 324) * (1.1 + 0.64 * i)
			local w = 11 + 4 * i
			c.start.Position = c.offset + self.tangent * (phase - w)
			c.finish.Position = c.offset + self.tangent * (phase + w) + V(0, 1 + i % 3, -2)
			c.start.Axis, c.finish.Axis = (self.tangent + V(0, 0.24, 0)).Unit, (self.tangent - V(0, 0.18, 0)).Unit
			c.trace.CurveSize0, c.trace.CurveSize1 = 0.75 * w, 0.62 * w
			c.lamp.Color = if ion
				then Color3.fromHex(if i % 2 == 0 then "39B9FD" else "8F4FF7")
				else Color3.fromHex(if i % 2 == 0 then "F95778" else "FF9737")
			c.trace.Color = ColorSequence.new(c.lamp.Color, Color3.fromHex(if ion then "BFE4FF" else "FFD58D"))
		end
	end
	local lens = self.axis.CFrame:PointToObjectSpace(camera.CFrame.Position)
	for _, p in self.fog do
		local u = (t - clock.breaker + 0.025 - p.birth) / p.life
		if u > 0 and u < 1 then
			local w = 8 + 11 * u
			Sprite.draw(
				p.sprite,
				p.origin + p.drift * (u * p.life),
				w,
				w * (0.80 + 0.10 * u),
				p.angle + u * 19,
				Color3.fromHex("B8A99E"):Lerp(Color3.fromHex("928A91"), u),
				1 - 0.43 * math.sin(math.pi * u) ^ 0.76
			)
		else
			p.sprite.card.Enabled = false
		end
	end
	local r = self.radius.Magnitude * (t - clock.waveLaunch) / (clock.breaker - clock.waveLaunch)
	local textureOffset = ((t - clock.waveLaunch) * 0.32) % 1
	local strength = S.ease(r, 9, 60) * (1 - S.ease(r, self.radius.Magnitude + 32, self.radius.Magnitude + 117))
	for _, v in self.curtains do
		v.b:SetTextureOffset(textureOffset)
		local phase = r * 0.019 + v.angle * 2
		local r0 = math.max(0.2, r + 3.0 * math.sin(phase) + v.age * 36)
		local k = r0 / self.radius.Magnitude
		local start = v.angle
		local finish = start + v.span
		local y = v.height * k + 2.5 * math.sin(phase)
		v.a.Position = V(r0 * math.cos(start), y, r0 * math.sin(start))
		v.c.Position = V(r0 * math.cos(finish), y + v.rise * k, r0 * math.sin(finish))
		v.a.Axis = V(-math.sin(start), 0.05, math.cos(start)).Unit
		v.c.Axis = V(-math.sin(finish), -0.06, math.cos(finish)).Unit
		local chord = v.c.Position - v.a.Position
		local nearest = v.a.Position
			+ chord * math.clamp((lens - v.a.Position):Dot(chord) / math.max(0.01, chord:Dot(chord)), 0, 1)
		local clearance = (nearest - lens).Magnitude
		v.b.Enabled = clearance > 18 and k < 0.95
		local localStrength = strength * S.ease(clearance, 18, 40)
		local d = r0 * v.span / 3
		v.b.CurveSize0, v.b.CurveSize1 = d, d
		v.b.Width0, v.b.Width1 = (2.3 + 7.5 * k) * localStrength, (0.4 + 5.1 * k) * localStrength
	end
	local shear = if name then shears[name] else nil
	for i, fleck in self.flecks do
		fleck.stroke.Enabled = shear ~= nil
		if shear then
			local angle = fleck.angle + math.rad(shear[1])
			local outward = self.tangent * math.cos(angle) + self.sky * math.sin(angle) * 0.79
			local run = if name == "splinters"
				then outward
				else self.tangent * math.cos(math.rad(shear[1])) + self.sky * math.sin(math.rad(shear[1]))
			local centre = self.observer
				- self.direction * (shear[2] + fleck.depth)
				+ outward * (shear[3] * fleck.distance)
			local drift = run * shear[4] * (0.71 + fleck.distance * 0.5)
			local curvature = self.sky * (fleck.skew * 1.9) + self.tangent * math.sin(frame * 1.4 + i) * 0.65
			fleck.a.Position, fleck.b.Position = centre - drift * 0.32, centre + drift + curvature
			fleck.a.Axis, fleck.b.Axis = run.Unit, (run + curvature * 0.18).Unit
			fleck.stroke.CurveSize0, fleck.stroke.CurveSize1 = shear[4] / 3, shear[4] / 4
			fleck.stroke.Width0, fleck.stroke.Width1 = 0.12 + 0.19 * fleck.distance, 0.012
		end
	end
	for _, v in self.marks do
		local age = t - clock.breaker + 0.13 - v.delay
		local vel = v.velocity - V(0, 43 * age, 0)
		local pos = v.origin + v.velocity * age - V(0, 21.5 * age ^ 2, 0)
		if age < 0 or age > 1.05 or pos.Y < 20.4 then
			v.part.Transparency = 1
			continue
		end
		local cf = if v.stone
			then CF(pos) * CFrame.Angles(v.angle + v.spin * age, age * 5, age * 7)
			else CFrame.lookAt(pos, pos + vel) * CFrame.Angles(0, 0, v.angle + age)
		v.part.CFrame = base * cf
		v.part.Transparency = if v.stone then 0.01 else 0.10 + 0.52 * S.ease(age, 0.57, 1.17)
	end
end
return Breaker
