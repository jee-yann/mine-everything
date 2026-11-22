local S = require(script.Parent.Scenery)
local frames = require(script.Parent.ExposureSheet).frames
local Edit = require(script.Parent.ImpactEdit)
local observer = require(script.Parent.Timeline).breakerEye
local touch = game:GetService("UserInputService").TouchEnabled
local V = Vector3.new
local Ignition = {}
Ignition.__index = Ignition

-- Axes and fan widths are in degrees as seen from the witness. Depth and
-- occlusion remain physical: each ray leaves the mine at its own inclination.
local function pose(axes, spread, reach, girth, gap, hatching)
	return { axes = axes, spread = spread, reach = reach, girth = girth, gap = gap, hatching = hatching }
end
local poses = {
	puncture = pose({ 143, -37 }, 1.2, 0.26, 0.55, 0, 0),
	pin = pose({ 5, 176 }, 8, 0.15, 0.46, 0.48, 0),
	needle = pose({ 22, 84, 154, 202, 264 }, 2.5, 0.93, 1.55, 0, 0),
	crown = pose({ 17, 57, 88, 116, 149, 206, 312 }, 11, 1.13, 1.32, 0.04, 1),
	rake = pose({ 34, 48, 61, 197, 210 }, 5, 0.87, 1.86, 0.17, 2),
	crosscut = pose({ 34, 134, 215, 311 }, 4.5, 1.19, 0.87, 0, 3),
	corona = pose({ 5, 47, 96, 137, 185, 222, 274, 320 }, 13, 1.17, 1.6, 0, 0),
	iris = pose({ 5, 42, 91, 137, 175, 215, 269, 314 }, 8, 1.25, 1.85, 0.02, 1),
	fan = pose({ 9, 24, 32, 161, 180, 253 }, 13, 1.08, 2.3, 0.08, 3),
	scythe = pose({ 53, 69, 102, 145, 226, 295 }, 4, 0.98, 1.55, 0.20, 2),
	splinter = pose({ 21, 83, 149, 188, 242, 337 }, 5, 1.26, 1.2, 0.25, 4),
	cinders = pose({ 40, 72, 96, 146, 183, 217 }, 11, 0.82, 1.05, 0.34, 1),
}

local function attachment(p)
	local a = Instance.new("Attachment")
	a.Parent = p
	return a
end

-- A volume of light and torn silhouettes viewed from offshore. Every
-- filament has a heading, depth and free end in the world around the crater.
local function filament(post, rand, long, dark, side)
	local a, mid, b = attachment(post), attachment(post), attachment(post)
	local pigment = if dark then Color3.fromHex("08090B") else Color3.fromHex("FFFBEF")
	local function stroke(start, finish)
		local beam = Instance.new("Beam")
		beam.Name = if dark then "Sheared silhouette" else "Cutting light"
		beam.FaceCamera, beam.LightInfluence, beam.LightEmission = true, 0, if dark then 0 else 0.78
		beam.Segments, beam.Transparency = 3, NumberSequence.new(0)
		beam.Color = ColorSequence.new(pigment)
		beam.Attachment0, beam.Attachment1, beam.Parent = start, finish, post
		return beam
	end
	return {
		a = a,
		m = mid,
		b = b,
		head = stroke(a, mid),
		tip = stroke(mid, b),
		depth = rand:NextNumber(-0.42, 0.82),
		length = long,
		phase = rand:NextNumber(0, 8),
		start = rand:NextNumber(3, 24) + side,
		width = rand:NextNumber(0.75, 2.2) * (if side > 30 then 0.62 else 1),
		girth = rand:NextNumber(1.1, 3.2),
		dart = rand:NextNumber(-0.012, 0.012),
	}
end

local function brokenCorona(axis, tangent, sky)
	local rim, rng = {}, Random.new(678)
	for i = 1, 13 do
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Parent, b.Parent = axis, axis
		local beam = Instance.new("Beam")
		beam.Name, beam.FaceCamera, beam.Segments = "Broken pressure silhouette", true, 7
		beam.Attachment0, beam.Attachment1 = a, b
		beam.Color = ColorSequence.new(Color3.fromHex("D6F4F0"), Color3.fromHex("A7BBBC"))
		beam.LightInfluence, beam.LightEmission = 0, 0.14
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.18, 0.08),
			NumberSequenceKeypoint.new(0.7, 0.12),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.Enabled, beam.Parent = false, axis
		local angle = math.pi * 2 * (i - 1) / 13 + rng:NextNumber(-0.055, 0.055)
		local finish = angle + rng:NextNumber(0.27, 0.52)
		local unitA = tangent * math.cos(angle) + sky * math.sin(angle) * 0.76
		local unitB = tangent * math.cos(finish) + sky * math.sin(finish) * 0.76
		a.Axis = (-tangent * math.sin(angle) + sky * math.cos(angle) * 0.76).Unit
		b.Axis = (-tangent * math.sin(finish) + sky * math.cos(finish) * 0.76).Unit
		-- The dust on the back of the condensation has its own thickness.
		-- In negative it outlines the pale band where it crosses the sky.
		local tailA, tailB = a:Clone(), b:Clone()
		tailA.Parent, tailB.Parent = axis, axis
		local lee = beam:Clone()
		lee.Name = "Reversed outer ink edge"
		lee.Attachment0, lee.Attachment1 = tailA, tailB
		lee.LightEmission, lee.Color = 0, ColorSequence.new(Color3.fromHex("07090C"))
		lee.Parent = axis
		local near = rng:NextNumber(-0.65, 0.65)
		table.insert(rim, {
			a = a,
			b = b,
			beam = beam,
			tailA = tailA,
			tailB = tailB,
			lee = lee,
			origin = near,
			start = unitA,
			finish = unitB,
			spread = (finish - angle) / 3,
			offset = rng:NextNumber(-0.7, 0.7),
		})
	end
	return rim
end

function Ignition.new(base, contact, motion)
	local root = S.group("Ignition above the strike")
	local post = S.part(root, "Origin of cutting light", base * CFrame.new(contact), Vector3.one * 0.05, "FFFFFF")
	post.Transparency, post.CastShadow = 1, false
	local ball = S.part(
		root,
		"Expanding incandescent air",
		base * CFrame.new(contact),
		Vector3.one,
		"FFDF9D",
		Enum.Material.Neon
	)
	ball.Shape, ball.CastShadow = Enum.PartType.Ball, false
	local light = S.light(ball, "FFBD84", 15, 3)
	light.Shadows = true
	local bounce = {}
	for i, where in { V(-29, 11, 19), V(28, 16, 48), V(44, 20, -10) } do
		local socket = attachment(post)
		socket.Position = where
		bounce[i] = S.light(socket, "9F62FF", 58, 5.5)
		bounce[i].Enabled = false
	end
	local glint = S.part(
		root,
		"Embedded fusion spark",
		base * CFrame.new(contact + V(0, 1.4, 0)),
		V(1, 1, 1),
		"FFCA93",
		Enum.Material.Neon
	)
	glint.Shape, glint.CastShadow = Enum.PartType.Ball, false
	local sight = (observer - contact).Unit
	local right = (-sight):Cross(Vector3.yAxis).Unit
	local up = right:Cross(-sight).Unit
	local rays, hatches = {}, {}
	local rand = Random.new(11252)
	if motion then
		-- Pairs and triplets share a fracture axis. Open pockets between
		-- clusters keep the coastline legible inside the flash.
		for i = 1, 21 do
			local direction = math.pi * 2 * (i - 1) / 21 + rand:NextNumber(-0.07, 0.07)
			local length = rand:NextNumber(145, 340) * (if i % 4 == 0 then 1.28 else 1)
			local count = if touch then 3 else 4 + i % 3
			for j = 1, count do
				local angle = direction + (j - 1) * rand:NextNumber(0.011, 0.038)
				local start = if j >= 4 then rand:NextNumber(42, 126) else 0
				local dark = (i + j) % 3 == 0
				local ray = filament(post, rand, length * rand:NextNumber(0.67, 1.28), dark, start)
				ray.family, ray.ordinal = i, j
				ray.lane = math.sin(angle * 8.7 + i * 11.71 + j * 2.34)
				ray.last = if not dark and j <= 2 then 17 + (i * 3 + j) % 7 else 9
				ray.hot = ray.head.Color
				ray.ion = ColorSequence.new(
					Color3.fromHex(if i % 2 == 0 then "D9CDFF" else "94EDFF"),
					Color3.fromHex(if j % 2 == 0 then "8843FD" else "1EBCCB")
				)
				ray.flare = ColorSequence.new(
					Color3.fromHex(if i % 2 == 0 then "FFD984" else "FE8C9F"),
					Color3.fromHex(if j % 2 == 0 then "F43A2F" else "E43F91")
				)
				ray.cool = ColorSequence.new(
					Color3.fromHex("FFE8AD"),
					Color3.fromHex(if i % 4 == 0 then "D99ECB" elseif i % 3 == 0 then "FF8C4E" else "F4A04C")
				)
				table.insert(rays, ray)
			end
		end
		for i = 1, if touch then 17 else 29 do
			local a, b = attachment(post), attachment(post)
			local slash = Instance.new("Beam")
			slash.Name, slash.Attachment0, slash.Attachment1 = "Crossed ejecta trace", a, b
			slash.FaceCamera, slash.Segments, slash.LightInfluence = true, 4, 0
			slash.LightEmission = if i % 4 == 0 then 0.52 else 0
			slash.Color = ColorSequence.new(Color3.fromHex(if i % 4 == 0 then "FFDBA2" else "0C0C11"))
			slash.Transparency, slash.Parent = NumberSequence.new(0.02, 0.30), post
			hatches[i] = {
				a = a,
				b = b,
				slash = slash,
				lane = rand:NextNumber(-1, 1),
				span = rand:NextNumber(20, 80),
				depth = rand:NextNumber(-18, 26),
			}
		end
	end
	return setmetatable({
		root = root,
		base = base,
		contact = contact,
		post = post,
		corona = if motion then brokenCorona(post, right, up) else {},
		ball = ball,
		glint = glint,
		light = light,
		bounce = bounce,
		rays = rays,
		hatches = hatches,
		right = right,
		up = up,
		sight = sight,
		motion = motion,
	}, Ignition)
end

local diameters =
	{ 2.8, 5.2, 8.0, 12.5, 17.8, 24.4, 33.5, 42.0, 51.0, 57.0, 61.0, 62.8, 65.0, 67.0, 69.0, 70.0, 71.0, 71.5 }

function Ignition:draw(frame, parent, camera)
	local age = frame - frames.ignition
	local size = if age >= 18 and age <= 25 then 72 + 0.7 * (age - 18) else diameters[age + 1]
	local contact = frame >= frames.contact and age < 0
	self.root.Parent = if size or contact then parent else nil
	if not self.root.Parent then
		return
	end
	self.glint.Transparency = if contact then 0.05 + 0.24 * (age + 3) else 1
	self.glint.Size = Vector3.one * (if age == -3 then 6.2 elseif age == -2 then 2.4 else 1.1)
	size = size or 0
	if not self.motion then
		size *= 0.62
	end
	local rise = 1.5 + math.clamp(age, 0, 14) * 0.86
	self.ball.Size = Vector3.one * math.max(0.05, size)
	self.ball.CFrame = self.base * CFrame.new(self.contact + V(0, rise, 0))
	self.ball.Transparency = if contact then 1 else 0.08 + 0.92 * S.ease(age, 7, 25)
	self.ball.Color = Color3.fromHex("FFE7B5"):Lerp(Color3.fromHex("FFA354"), S.ease(age, 9, 22))
	-- The fireball lights the vent floor. The climbing shadow source in
	-- MeteorLight owns the much larger pool on the surrounding terraces.
	self.light.Range = math.min(24, 15 + size * 0.24)
	self.light.Enabled = not contact
	self.light.Brightness = if contact then 0 else (if self.motion then 3 else 1.0) * (1 - S.ease(age, 8, 23))
	local growth = 0.43 + 0.57 * S.ease(age, 0, 5)
	local transfer = Edit.at(frame)
	local ion = self.motion and transfer and transfer.mode == "ultraviolet"
	local ember = self.motion and transfer and transfer.mode == "ember"
	for i, lamp in self.bounce do
		lamp.Enabled = ion == true or ember == true
		lamp.Color = if ion
			then Color3.fromHex(if i == 2 then "2ACBFF" else "8E41FF")
			else Color3.fromHex(if i == 2 then "FF9A25" else "FF2F6A")
	end
	-- Bring the fractured corona forward along the sightline. It prints over
	-- the actual strike in the same screen position on wide and narrow lenses.
	local crossed = transfer ~= nil and transfer.pose == "crosscut"
	for _, edge in self.corona do
		edge.beam.Enabled, edge.lee.Enabled = crossed, crossed
		if crossed then
			local eye = self.post.CFrame:PointToObjectSpace(camera.CFrame.Position)
			local distance = 27 + edge.origin
			local halfHeight = distance * math.tan(math.rad(camera.FieldOfView * 0.5))
			local ratio = camera.ViewportSize.X / math.max(1, camera.ViewportSize.Y)
			local radius = halfHeight * math.min(1.24, 0.86 * ratio) * (1 + 0.032 * edge.offset)
			local centre = eye - eye.Unit * distance + self.up * (halfHeight * 0.035)
			edge.a.Position, edge.b.Position = centre + edge.start * radius, centre + edge.finish * radius
			edge.tailA.Position = edge.a.Position - edge.start * (radius * 0.023) - self.sight * 0.03
			edge.tailB.Position = edge.b.Position - edge.finish * (radius * 0.031) - self.sight * 0.03
			edge.beam.CurveSize0, edge.beam.CurveSize1 = edge.spread * radius, edge.spread * radius
			edge.lee.CurveSize0, edge.lee.CurveSize1 = edge.beam.CurveSize0, edge.beam.CurveSize1
			edge.beam.Width0, edge.beam.Width1 = radius * 0.039, radius * 0.047
			edge.lee.Width0, edge.lee.Width1 = radius * 0.043, radius * 0.034
		end
	end
	local style = if transfer then poses[transfer.pose] elseif contact then nil else poses.cinders
	for _, ray in self.rays do
		local live = style ~= nil and age <= ray.last and (not contact or ray.ordinal == 1 and ray.family % 3 == 0)
		ray.head.Enabled, ray.tip.Enabled = live, live
		if live then
			-- Each exposure changes the taper, length and heading. A tiny
			-- lateral kick at the joint kinks the light inside the hot air.
			local heat = if age <= 9 then 1 else 1 - S.ease(age, 10, ray.last)
			local chatter = math.sin(age * 2.6 + ray.phase * 3.7) * heat
			local axis = style.axes[(ray.family - 1) % #style.axes + 1]
			local angle = math.rad(axis + style.spread * ray.lane) + (0.014 + 0.012 * growth) * chatter
			local tangent = self.right * -math.sin(angle) + self.up * math.cos(angle)
			local flat = self.right * math.cos(angle) + self.up * math.sin(angle)
			local depth = math.max(ray.depth, (0.012 - flat.Y) / self.sight.Y)
			local heading = (flat + self.sight * depth).Unit
			local length = ray.length * style.reach * growth * (0.93 + 0.16 * math.sin(age * 1.97 + ray.phase))
			local start = math.min(
				length * 0.83,
				ray.start + 0.14 * size + 2.4 * chatter + (1 - heat + style.gap) * length * 0.67
			)
			local middle = start + (length - start) * (0.28 + 0.13 * math.sin(ray.phase + age * 0.87))
			local core = V(0, rise, 0)
			ray.a.Position = core + heading * start
			ray.m.Position = core + heading * middle + tangent * (ray.dart * middle + 1.4 * chatter)
			ray.b.Position = core + heading * length + tangent * (2.3 * chatter)
			local width = ray.width * style.girth * (0.92 + 0.38 * chatter)
			local pigment = if ion and ray.ordinal % 3 ~= 0
				then ray.ion
				elseif ember and ray.ordinal % 3 ~= 0 then ray.flare
				elseif age > 9 then ray.cool
				else ray.hot
			ray.head.Color, ray.tip.Color = pigment, pigment
			local transparency = NumberSequence.new(1 - heat)
			ray.head.Transparency, ray.tip.Transparency = transparency, transparency
			ray.head.Width0, ray.head.Width1 = width * 0.18, width * ray.girth
			ray.tip.Width0, ray.tip.Width1 = ray.head.Width1, 0.045
		end
	end
	for i, mark in self.hatches do
		local pattern = if style and transfer then style.hatching else 0
		mark.slash.Enabled = pattern > 0
		if pattern > 0 then
			local bank = if i % 2 == 0 then -1 else 1
			local theta = math.rad(({ 32, 53, -37, 77 })[pattern] + (if pattern == 3 and i % 3 == 0 then 69 else 0))
			local line = self.right * math.cos(theta) + self.up * math.sin(theta)
			local across = -self.right * math.sin(theta) + self.up * math.cos(theta)
			local centre = self.right * (bank * (24 + 17 * pattern))
				+ V(0, 27 + 16 * pattern + mark.lane * 12, 0)
				+ self.sight * mark.depth
			local start = centre + across * (mark.lane * 40 + math.sin(frame + i)) - line * mark.span * 0.28
			mark.a.Position, mark.b.Position = start, start + line * mark.span
			mark.a.Axis, mark.b.Axis = line, (line + across * (0.18 * bank)).Unit
			mark.slash.CurveSize0, mark.slash.CurveSize1 = mark.span * 0.18, mark.span * 0.31
			mark.slash.Width0, mark.slash.Width1 = if i % 3 == 0 then 1.45 else 0.63, 0.05
		end
	end
end

return Ignition
