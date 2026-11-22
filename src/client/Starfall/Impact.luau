local S = require(script.Parent.Scenery)
local edit = require(script.Parent.ImpactEdit)
local Ignition = require(script.Parent.Ignition)
local ImpactLens = require(script.Parent.ImpactLens)
local Plume = require(script.Parent.Plume)
local Entry = require(script.Parent.Entry)
local Sprite = require(script.Parent.WorldSprite)
local AblationWake = require(script.Parent.AblationWake)
local Breaker = require(script.Parent.BreakerSpray)
local Track = require(script.Parent.FlightTrack)
local clock = require(script.Parent.Timeline)
local sheet = require(script.Parent.ExposureSheet)
local frames = sheet.frames
local Sculpture = require(script.Parent.StarSculpture)
local V, CF = Vector3.new, CFrame.new
local smooth, neon = Enum.Material.SmoothPlastic, Enum.Material.Neon
local Impact = {}
Impact.__index = Impact

local contact = V(0, 26, -32)
local collision = clock.contact
local ignitionDelay = sheet.sceneTime(frames.ignition) - collision
local function coords(row, i)
	return V(row[i], row[i + 1], row[i + 2])
end

local function exposureFrame(t, masterFrame)
	return math.floor((masterFrame or sheet.frameForScene(t)) + 1e-6)
end

function Impact.position(t, masterFrame)
	local frame = math.clamp(exposureFrame(t, masterFrame), frames.entry, frames.contact)
	return coords(Track.bodies[frame - frames.entry + 1], 1)
end
local direction = (contact - coords(Track.bodies[1], 1)).Unit

-- Bake Blender's colored mesh into anchored facets. The geometry and shading
-- share vertex coordinates on every face, including the interior of the geode.
local function face(parent, a, b, c, tint, material, collector, castsShadow)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local cross = ac:Cross(ab)
	if cross.Magnitude < 0.0005 then
		return
	end
	local normal, along = cross.Unit, bc.Unit
	local up = along:Cross(normal)
	local height = math.abs(up:Dot(ab))
	for i, vertex in { b, c } do
		local depth = math.abs((vertex - a):Dot(along))
		if depth > 0.007 and height > 0.007 then
			local sign = if i == 1 then 1 else -1
			local p = S.part(
				parent,
				"Face",
				CFrame.fromMatrix((a + vertex) / 2, normal * sign, up, along * sign),
				V(0.018, height, depth),
				tint,
				material,
				"WedgePart"
			)
			p.CastShadow = castsShadow == true
			if collector then
				table.insert(collector, p)
			end
		end
	end
end

local function meteor()
	local basalt = {}
	local shell = S.group("Aureole · Blender shell")
	local geode = {
		[15] = "AB70CF",
		[17] = "8541AC",
		[19] = "613982",
		[21] = "9251BE",
		[22] = "703E97",
		[23] = "C184E3",
		[24] = "905CA8",
	}
	for _, f in Sculpture.faces do
		local original = Sculpture.palette[f[1]]
		local tint = geode[f[1]] or (if original == "FBB773" then "EB9A59" else original)
		local marks = if f[1] <= 14 and original ~= "FBB773" then {} else nil
		face(
			shell,
			V(f[2], f[3], f[4]),
			V(f[5], f[6], f[7]),
			V(f[8], f[9], f[10]),
			tint,
			if f[1] == 15 or f[1] == 21 or f[1] == 23 or original == "FBB773" then neon else smooth,
			marks
		)
		if marks and #marks > 0 then
			local cold = Color3.fromHex(original)
			-- The thin lithic plates retain painted bounce when low-quality
			-- lighting drops their point source. Their direction gives every
			-- bevel a different value across the camera-facing portion.
			local a, b, c = V(f[2], f[3], f[4]), V(f[5], f[6], f[7]), V(f[8], f[9], f[10])
			local n = (b - a):Cross(c - a).Unit
			local incidence = math.clamp(0.31 + 0.53 * n:Dot(V(-0.21, 0.71, 0.67).Unit), 0, 1)
			local value = math.clamp(incidence + 0.88 * (cold.R - 0.30), 0, 1)
			local warm = Color3.fromHex("6D484C"):Lerp(Color3.fromHex("B58368"), value)
			for _, part in marks do
				table.insert(basalt, { part, cold, warm })
			end
		end
	end
	-- A broad bounce from the luminous wake picks out the basalt's plate edges
	-- on the dark side of the approach, including during the undercranked insert.
	local fill = S.part(shell, "Bounce off the exposed glass", CF(-1.5, 4, 7.6), Vector3.one * 0.06, "DBBDF4")
	fill.Transparency, fill.CastShadow = 1, false
	S.light(fill, "E7B9FF", 23, 2.7)
	-- Three different depths around the exposed bed. Rock plates can travel
	-- in front of the pinlights and the broad lavender bloom as it rolls.
	for i, socket in { V(-1.2, 0.0, 3.02), V(1.92, 0.4, 3.31), V(3.91, 0.86, 3.55) } do
		local glint =
			Sprite.new(fill, "Glint on the exposed amethyst", "rbxasset://textures/particles/sparkles_main.dds", 0)
		glint.card.Brightness = 1.75
		Sprite.draw(
			glint,
			socket - fill.Position,
			0.58 + 0.16 * i,
			0.51 + 0.14 * i,
			19 * i,
			Color3.fromHex("E3B4FF"),
			0.28
		)
	end
	return shell, basalt
end

local function plates()
	local bowl = S.group("Fracture bed")
	local rim = { "57475B", "745765", "895F68", "60485A", "433B51", "956D6A" }
	local count = 16
	local rng = Random.new(98775)
	-- Each slab has a distinct broken front and two lithological layers.
	for i = 1, count do
		local angle = (i - 0.55) * math.pi * 2 / count
		local nextA = angle + (0.73 + rng:NextNumber() * 0.23) * math.pi * 2 / count
		local r0, r1 = rng:NextNumber(7.2, 11.6), rng:NextNumber(12.1, 15.8)
		local y0 = rng:NextNumber(0.44, 1.05)
		local y1 = 1.2 + rng:NextNumber(0, 1.7)
		local function vertex(a, r, y)
			return V(math.cos(a) * r, y, math.sin(a) * r * 0.83)
		end
		local a, b = vertex(angle, r0, y0), vertex(nextA, r0 - 0.4, y0 + 0.36)
		local c, d = vertex(nextA, r1, y1), vertex(angle, r1 + 0.8, y1 + 0.38)
		local m = vertex((angle + nextA) * 0.5, (r0 + r1) * 0.5, y1 + 0.55)
		face(bowl, a, b, m, rim[(i + 2) % #rim + 1], smooth, nil, i % 2 == 0)
		face(bowl, b, c, m, rim[i % #rim + 1], smooth, nil, i % 2 == 0)
		face(bowl, c, d, m, rim[(i + 4) % #rim + 1], smooth)
		face(bowl, d, a, m, rim[(i + 3) % #rim + 1], smooth)
		local aa, bb = a - V(0, 0.62, 0), b - V(0, 0.66, 0)
		face(bowl, aa, bb, b, "3C3347", smooth)
		face(bowl, aa, b, a, if i % 3 == 1 then "AD777E" else "614C61", smooth)
	end
	local paths = {
		{
			{ -8.8, 5.1 },
			{ -5.4, 4.1 },
			{ -4, 2.4 },
			{ -2.6, 2.55 },
			{ -0.65, 0.6 },
			{ 0.65, 0.9 },
			{ 2.1, -0.6 },
			{
				2.8,
				-2.1,
			},
			{
				5.5,
				-3.0,
			},
			{
				7.7,
				-5.9,
			},
		},
		{ { 0.65, 0.9 }, { 3.6, 1.9 }, { 4.6, 1.8 }, { 6.3, 3.2 }, { 9.4, 3.85 } },
		{ { -4, 2.4 }, { -4.7, -0.55 }, { -6.25, -1.1 }, { -6.9, -2.7 } },
		{ { 5.5, -3.0 }, { 7.2, -2.4 }, { 9.9, -3.5 } },
	}
	local seams = {}
	for h, path in paths do
		for i = 2, #path do
			local function here(q)
				return V(q[1], 0.45 + math.sqrt(q[1] ^ 2 + q[2] ^ 2) * 0.014, q[2])
			end
			local a, b = here(path[i - 1]), here(path[i])
			local across = (b - a).Unit:Cross(Vector3.yAxis)
			local extent = (i - 1) / (#path - 1)
			local w = if h == 1 then 0.36 + 1.04 * math.sin(extent * math.pi) ^ 0.7 else 0.69 * (1 - extent * 0.84)
			local aa, ab = a - across * w, a + across * w
			local ba, bb = b - across * w * 0.78, b + across * w * 0.78
			face(bowl, aa, ab, bb, "3C2849", smooth)
			face(bowl, aa, bb, ba, "372441", smooth)
			-- Torn lips sit at different heights over the purple mineral glass.
			-- Ochre bedding is exposed on one bank and cold basalt on the other.
			for side = -1, 1, 2 do
				local corr = 0.10 + 0.07 * math.sin(2.31 * i + side)
				local topA = a + side * across * w * (0.89 + corr) + V(0, 0.18 + 2 * corr, 0)
				local topB = b + side * across * w * 0.81 + V(0, 0.16 + corr, 0)
				local inA = a + side * across * w * 0.37
				local inB = b + side * across * w * 0.28
				local shade = if side == 1 then "9B7685" else "624A6B"
				face(bowl, topA, topB, inA, shade, smooth)
				face(bowl, inA, topB, inB, if side == 1 then "705569" else "51405E", smooth)
				local bank = (topA + topB) * 0.5 + side * across * w * (0.75 + 0.27 * (i % 3)) - V(0, 0.12, 0)
				face(bowl, topA, bank, topB, if side == 1 then rim[(i + 2) % #rim + 1] else "635064", smooth)
			end
			local marks = {}
			aa, ab = a - across * w * 0.34 + V(0, 0.037, 0), a + across * w * 0.34 + V(0, 0.037, 0)
			ba, bb = b - across * w * 0.18 + V(0, 0.037, 0), b + across * w * 0.15 + V(0, 0.037, 0)
			face(bowl, aa, ab, bb, "743EC2", neon, marks)
			face(bowl, aa, bb, ba, "A760D8", neon, marks)
			local fillet = S.strut(
				bowl,
				"Hot cleavage",
				a + V(0, 0.061, 0),
				b + V(0, 0.061, 0),
				math.max(0.025, w * 0.08),
				0.026,
				"CC98F1",
				neon
			)
			fillet.CastShadow = false
			table.insert(marks, fillet)
			table.insert(seams, { faces = marks, d = (a.Magnitude + b.Magnitude) / 2, branch = h })
		end
	end
	local light = S.part(bowl, "Trapped light", CF(0, 1.15, 0), Vector3.one * 0.1, "DCAFFF")
	light.Transparency, light.CastShadow = 1, false
	return bowl, seams, S.light(light, "BB85FF", 18, 1.5)
end

local function debris(root)
	local list = {}
	local rng = Random.new(2571)
	for i = 1, 21 do
		local heading = rng:NextNumber(0, 2 * math.pi)
		local major = i % 4 == 0
		local speed = if major then rng:NextNumber(32, 69) else rng:NextNumber(14, 62)
		local shard = S.group("Ejected country rock")
		local s = if major then rng:NextNumber(3.3, 5.9) else rng:NextNumber(0.65, 2.45)
		local a, b, c, d =
			V(-1, 0, -0.44) * s, V(0.67, 0.25, -0.47) * s, V(0.46, 0.3, 0.59) * s, V(-0.81, -0.18, 0.38) * s
		local top, lo = V(-0.08, 0.82, -0.04) * s, V(0.13, -0.59, 0) * s
		for j, q in { { a, b }, { b, c }, { c, d }, { d, a } } do
			face(shard, q[1], q[2], top, if j % 2 == 0 then "705865" else "60485A", smooth)
			face(shard, q[2], q[1], lo, if j == 1 then "FFD596" else "AC7779", smooth)
		end
		local tail
		if major then
			local axis = S.part(shard, "Core heat", CF(), V(0.08, 0.08, 0.08), "DE6B39")
			axis.Transparency, axis.CastShadow = 1, false
			local head, last = Instance.new("Attachment"), Instance.new("Attachment")
			head.Parent, last.Parent = axis, axis
			local beam = Instance.new("Beam")
			beam.Name = "Wake of the ejected rock"
			beam.Attachment0, beam.Attachment1 = head, last
			beam.FaceCamera, beam.Segments, beam.LightEmission = true, 5, 0.22
			beam.Width0, beam.Width1 = 0.55 * s, 0.03
			beam.Transparency = NumberSequence.new(0.22, 1)
			beam.Color = ColorSequence.new(Color3.fromHex("DE946D"), Color3.fromHex("886175"))
			beam.Parent = axis
			tail = { head = head, last = last, beam = beam }
		end
		list[i] = {
			part = shard,
			tail = tail,
			delay = rng:NextNumber(0.025, 0.39),
			velocity = V(
				math.cos(heading) * speed,
				(if major then rng:NextNumber(68, 101) else rng:NextNumber(35, 77)),
				math.sin(heading) * speed
			),
			spin = V(rng:NextNumber(-5, 5), rng:NextNumber(-4, 4), rng:NextNumber(-4, 4)),
		}
	end
	return list
end

function Impact.new(stage, screen, base, motion)
	local root = S.group("Starfall pressure front")
	root.Parent = stage
	local shell, basalt = meteor()
	local cast = S.part(root, "Plasma bounce on facing plates", CF(), Vector3.one * 0.07, "E8BBA1")
	cast.Transparency, cast.CastShadow = 1, false
	local keyLight = S.light(cast, "FFD09F", 34, 7.1)
	local bed, seams, light = plates()
	bed:PivotTo(base * CF(contact))
	return setmetatable({
		root = root,
		stage = stage,
		base = base,
		motion = motion,
		shell = shell,
		basalt = basalt,
		cast = cast,
		keyLight = keyLight,
		entry = Entry.new(face),
		wake = AblationWake.new(base, contact, direction, motion),
		plume = Plume.new(root, base, motion),
		breaker = Breaker.new(),
		bed = bed,
		seams = seams,
		light = light,
		ignition = Ignition.new(base, contact, motion),
		lens = if motion then ImpactLens.new(screen) else nil,
		rocks = debris(root),
	}, Impact)
end

function Impact:camera(t, masterFrame)
	local frame = math.clamp(exposureFrame(t, masterFrame), frames.entry, frames.contact)
	local shot = Track.shots[1]
	for i = 2, #Track.shots do
		if frame < Track.shots[i][1] then
			break
		end
		shot = Track.shots[i]
	end
	local samples = shot[2]
	local index = math.min(#samples, 1 + math.floor(frame - shot[1]))
	local a = samples[index]
	local eye, focus = coords(a, 1), coords(a, 4)
	if not self.motion and shot == Track.shots[2] then
		eye = focus + (eye - focus) * 1.20
	end
	return eye, focus, a[7], if self.motion then a[8] else 0
end

function Impact:draw(t, camera, masterFrame)
	local frame = exposureFrame(t, masterFrame)
	local age = t - collision
	local blastAge = age - ignitionDelay * (1 - S.ease(age, 1.3, 2.5))
	local flying = frame >= frames.entry
		and (frame < frames.coast or frame >= frames.terminal and frame < frames.contact)
	self.shell.Parent = if flying then self.root else nil
	if flying then
		local p = Impact.position(t, frame)
		local hero = frame >= frames.crystal and frame < frames.coast
		if self.hero ~= hero then
			for _, swatch in self.basalt do
				swatch[1].Color = if hero then swatch[3] else swatch[2]
				swatch[1].Material = if hero then neon else smooth
			end
			self.hero = hero
		end
		self.cast.Parent = self.root
		local pose = self.base * CFrame.lookAt(p, p + direction) * CFrame.Angles(0, math.pi / 2, 0)
		self.cast.CFrame = pose * CF(5.50, -9.76, 6.64)
		self.keyLight.Brightness = if hero then 8.6 else 2.4
		local row = Track.bodies[math.clamp(frame - frames.entry + 1, 1, #Track.bodies)]
		self.shell:PivotTo(pose * CF(0, 0, 0, table.unpack(row, 4, 12)))
		self.entry:draw(t, pose, self.root, self.motion, frame)
	else
		self.entry.root.Parent = nil
		self.cast.Parent = nil
	end
	self.wake:draw(frame, self.root)
	self.ignition:draw(frame, self.root, camera)
	if self.lens then
		self.lens:draw(camera, frame)
	end
	self.plume:draw(blastAge, self.motion and edit.roller(frame) ~= nil)
	self.breaker:draw(t, self.root, self.base, camera, self.motion and edit.at(frame), frame)
	for _, r in self.rocks do
		local a = blastAge - r.delay
		local pos = r.velocity * a - V(0, 32 * a * a, 0)
		local airborne = a > 0 and pos.Y > 0
		r.part.Parent = if airborne then self.root else nil
		if airborne then
			local spin = r.spin * a
			r.part:PivotTo(self.base * CF(contact + V(0, 1.3, 0) + pos) * CFrame.Angles(spin.X, spin.Y, spin.Z))
			if r.tail then
				local prev = math.max(0, a - 0.20)
				local behind = r.velocity * prev - V(0, 32 * prev * prev, 0)
				r.tail.last.WorldPosition = self.base * (contact + V(0, 1.3, 0) + behind)
				local nowVel = V(0, 64 * a, 0) - r.velocity
				local thenVel = V(0, 64 * prev, 0) - r.velocity
				r.tail.head.WorldAxis = self.base:VectorToWorldSpace(nowVel.Unit)
				r.tail.last.WorldAxis = self.base:VectorToWorldSpace(thenVel.Unit)
				r.tail.beam.CurveSize0, r.tail.beam.CurveSize1 =
					nowVel.Magnitude * (a - prev) / 3, thenVel.Magnitude * (a - prev) / 3
			end
		end
	end
	local reveal = age >= 0 and t < 16.72
	self.bed.Parent = if reveal then self.root else nil
	if reveal then
		local deposits = math.floor(12 * S.ease(t, 12.74, 15.35))
		if deposits ~= self.deposits then
			self.bed:PivotTo(self.base * CF(contact - V(0, deposits * 0.21, 0)))
			self.deposits = deposits
		end
		local pulse = S.ease(t, 8.68, 9.38) * (1 - S.ease(t, 10.65, 12.18))
		local bounce = if self.motion and blastAge >= -0.00001 then 1 - S.ease(blastAge, 0.04, 0.39) else 0
		self.light.Brightness = 0.12 + 0.64 * pulse + 3.6 * bounce
		self.light.Range = 13 + 44 * bounce
		self.light.Color = Color3.fromHex("BB85FF"):Lerp(Color3.fromHex("FFAA63"), bounce)
		for _, s in self.seams do
			local travel = S.ease(t, 8.54 + 0.052 * s.d, 8.89 + 0.052 * s.d)
			local bank = 1 - S.ease(t, 10.84 + 0.033 * s.d, 11.93 + 0.037 * s.d)
			local opacity = math.min(1, pulse * travel * bank + 0.13 * (1 - S.ease(t, 10.9, 12.28)))
			for _, p in s.faces do
				p.Transparency = 1 - opacity
			end
		end
	end
end

function Impact:Destroy()
	if self.lens then
		self.lens:Destroy()
	end
	self.ignition.root:Destroy()
	self.plume:Destroy()
	self.entry.root:Destroy()
	self.wake.root:Destroy()
	self.breaker.root:Destroy()
	for _, entry in self.rocks do
		entry.part:Destroy()
	end
	self.shell:Destroy()
	self.cast:Destroy()
	self.bed:Destroy()
	self.root:Destroy()
end

return Impact
