local S = require(script.Parent.Scenery)
local Sprite = require(script.Parent.WorldSprite)
local sheet = require(script.Parent.ExposureSheet)
local Entry = {}
Entry.__index = Entry
local V, CF = Vector3.new, CFrame.new
local function attachment(part, pos)
	local a = Instance.new("Attachment")
	a.Position, a.Parent = pos or Vector3.zero, part
	return a
end
local function ribbon(a, b, lo, hi, width, tip, emission)
	local beam = Instance.new("Beam")
	beam.Name = "Ablation filament"
	beam.Attachment0, beam.Attachment1, beam.FaceCamera = a, b, true
	beam.Segments = 10
	beam.Color = ColorSequence.new(Color3.fromHex(lo), Color3.fromHex(hi))
	beam.Transparency = NumberSequence.new(0.035, 0.63)
	beam.LightEmission, beam.LightInfluence = emission, 0.1
	beam.Width0, beam.Width1, beam.Parent = width, tip, a.Parent
	return beam
end
local function polar(x, r, a)
	return V(x, r * math.sin(a), r * math.cos(a))
end

function Entry.new(face)
	local root = S.group("Ionised entry envelope")
	local axis = S.part(root, "Wake axis", CF(), Vector3.one * 0.05, "FFFFFF")
	axis.Transparency, axis.CastShadow = 1, false
	S.light(axis, "FFBC87", 35, 3.8)
	-- A single optically hot leading edge remains visible without the
	-- fullscreen Bloom effect. It rolls behind the actual stone on the chase.
	local nose = Sprite.new(axis, "Bow shock flare", "rbxasset://textures/glow.png", 0)
	nose.card.Brightness = 2.75
	Sprite.draw(nose, V(4.15, 0.3, 1.0), 7.0, 6.5, -14, Color3.fromHex("FFDAA5"), 0.20)
	-- Optically thin bow: the same pointed surface reads against both a dark
	-- sky and the cliff. The hollow flank leaves the fractured stone visible.
	local rings = { { 8.42, 0.18 }, { 7.35, 1.14 }, { 5.1, 2.7 }, { 0.75, 4.72 }, { -4.5, 5.65 } }
	for i = 1, 14 do
		local a = math.pi * 2 * i / 14
		local gap = 0.0
		for j = 2, #rings do
			local x, r = table.unpack(rings[j - 1])
			local x2, r2 = table.unpack(rings[j])
			local b = a + math.pi * 2 / 14 - gap
			local u, v = polar(x, r, a), polar(x, r, b)
			local w, z = polar(x2, r2, a + 0.025 * j), polar(x2, r2, b + 0.025 * j)
			local ps = {}
			local tint = if j == 2 then "FFF5C2" elseif j == 3 then "FFD17C" elseif i % 3 == 0 then "FF9D65" else "AE85C9"
			face(root, u, v, w, tint, Enum.Material.SmoothPlastic, ps)
			face(root, w, v, z, tint, Enum.Material.SmoothPlastic, ps)
			for _, p in ps do
				p.Transparency = if j == 2 then 0.79 elseif j == 3 then 0.927 else 0.962
			end
		end
	end
	-- The envelope is a transparent refracting sheath; a few curled filaments
	-- catch the light on its leading edge while the dark belly remains open.
	for _, a in { 0.49, 2.8, 4.83 } do
		local point = attachment(axis, polar(8.5, 0.18, a))
		local lip = attachment(axis, polar(3.6, 3.4, a))
		local m = ribbon(point, lip, "FFDF9A", "EF985A", 0.045, 0.24, 0.42)
		point.Axis, lip.Axis = V(-1, 0, 0), V(-1, 0.20 * math.sin(a), 0.20 * math.cos(a)).Unit
		m.CurveSize0, m.CurveSize1 = 2.3, 1.9
		m.Transparency = NumberSequence.new(0.32, 0.71)
	end
	local streams = {}
	local colors = {
		{ "FFE4A5", "F99657", "974F70" },
		{ "F4D8FF", "C475EB", "955ACE" },
		{ "FFD086", "C95545", "85485F" },
		{ "C8F5FF", "76C4E0", "6579CB" },
		{ "FFDF9C", "F69960", "AB7882" },
	}
	for i, tones in colors do
		local a, b, c = attachment(axis), attachment(axis), attachment(axis)
		local outer = ribbon(a, b, tones[1], tones[2], 2.6 + (i % 2), 2.5, 0.57)
		local far = ribbon(b, c, tones[2], tones[3], 2.5, 0.06, 0.42)
		local core = ribbon(a, b, "FFF6BE", tones[2], 0.78, 0.45, 0.74)
		outer.Transparency, far.Transparency =
			NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.68),
				NumberSequenceKeypoint.new(0.14, 0.15),
				NumberSequenceKeypoint.new(1, 0.40),
			}), NumberSequence.new(0.37, 0.97)
		table.insert(streams, { a = a, b = b, c = c, outer = outer, far = far, core = core, i = i })
	end
	local ringsOfAir = {}
	for i = 1, 4 do
		local arcs = {}
		for j = 1, 4 do
			local a, b = attachment(axis), attachment(axis)
			local beam = ribbon(a, b, if i % 2 == 0 then "F8E4BA" else "E0C6F5", "BBAFD2", 0.2, 0.09, 0.5)
			beam.Segments = 7
			table.insert(arcs, { a = a, b = b, beam = beam })
		end
		ringsOfAir[i] = arcs
	end
	-- Chromatic shear is confined to the hot wake. Offset filaments
	-- break across one another as a heat-haze cue around the exposed core.
	local shears, smears = {}, {}
	local ionColors = {
		{ "CD2689", "AD1CB9", "6722B4" },
		{ "AA297D", "881D87", "641C9D" },
		{ "EA5478", "BC379C", "822390" },
		{ "FFA749", "EE8640", "D37A49" },
		{ "28C5CD", "23A9C9", "327ABC" },
		{ "218EB7", "1A8CB5", "2E65AA" },
		{ "5FC0C6", "448FA7", "5865AB" },
	}
	for i = 1, 7 do
		local a, b = attachment(axis), attachment(axis)
		local strip = ribbon(a, b, if i % 2 == 0 then "A294E8" else "F7B575", "AD869D", 0.44, 0.07, 0.36)
		strip.Name = "Shear at the air boundary"
		strip.Transparency = NumberSequence.new(0.56, 0.96)
		shears[i] = { a = a, b = b, strip = strip }
		local g, h, k = attachment(axis), attachment(axis), attachment(axis)
		local color = ionColors[i]
		local shoulder = ribbon(g, h, color[1], color[2], 2.0, 7.4, 0.025)
		local streamer = ribbon(h, k, color[2], color[3], 7.4, 0.12, 0.08)
		shoulder.Name, streamer.Name = "Terminal ion sheath", "Detached ion streamer"
		shoulder.Enabled, streamer.Enabled = false, false
		shoulder.LightInfluence, streamer.LightInfluence = 0, 0
		shoulder.Transparency, streamer.Transparency = NumberSequence.new(0.09, 0.11), NumberSequence.new(0.11, 0.90)
		smears[i] = { a = g, b = h, c = k, shoulder = shoulder, streamer = streamer }
	end
	local motes = {}
	for i = 1, 9 do
		motes[i] = Sprite.new(axis, "Ablated mineral dust", Sprite.sparks, 0.08)
	end
	for i, pos in { V(-2, 0, 0), V(-11, 1, 1), V(-19, 0, -2), V(-32, -1, 1) } do
		local glow = Sprite.new(
			axis,
			"Bloom suspended in the ionised wake",
			"rbxasset://textures/particles/explosion01_implosion_main.dds",
			0
		)
		glow.card.Brightness = 2.4
		Sprite.draw(
			glow,
			pos,
			18 + i * 5,
			19 + 2.8 * i,
			0,
			Color3.fromHex(if i % 2 == 0 then "FFB680" else "B175F8"),
			0.32 + 0.08 * i
		)
	end
	local scraps = {}
	for i = 1, 11 do
		local p = S.part(
			root,
			"Flaking fusion crust",
			CF(),
			V(0.34 + 0.16 * (i % 3), 0.38 + (i % 2) * 0.26, 0.6 + 0.3 * (i % 4)),
			if i % 3 == 0 then "E19C6A" else "816577",
			if i % 3 == 0 then Enum.Material.Neon else Enum.Material.Slate,
			"WedgePart"
		)
		local a, b = attachment(axis), attachment(axis)
		local tail = ribbon(a, b, "F2B079", "AD7191", 0.32, 0.02, 0.38)
		scraps[i] = { rock = p, a = a, b = b, tail = tail }
	end
	return setmetatable({
		root = root,
		motes = motes,
		streams = streams,
		rings = ringsOfAir,
		scraps = scraps,
		shears = shears,
		smears = smears,
	}, Entry)
end

local gold, violet = Color3.fromHex("F6CF8C"), Color3.fromHex("B77BB0")
local function dustMotes(motes, t)
	for i, p in motes do
		local u = (t / (0.23 + 0.033 * (i % 5)) + i * 0.61803) % 1
		local a = i * 2.4 + u * 0.51
		local r = 1.65 + u * (2.3 + i % 3 * 0.94)
		local pos = polar(-3.3 - u * (9.2 + 2.4 * i), r, a)
		local w = (0.20 + 0.061 * (i % 4)) * (1 - 0.33 * u)
		Sprite.draw(p, pos, w, w * 1.44, a * 59 - 29 * u, gold:Lerp(violet, u), 1 - 0.90 * math.sin(math.pi * u) ^ 0.65)
	end
end

function Entry:draw(t, pose, parent, motion, masterFrame)
	self.root:PivotTo(pose)
	self.root.Parent = parent
	dustMotes(self.motes, t)
	local f = masterFrame or math.floor(sheet.frameForScene(t) + 1e-6)
	local terminal = f >= sheet.frames.terminal and f < sheet.frames.contact
	local time = f / sheet.fps
	for i, v in self.shears do
		local theta = i * 2.399 + 0.35 * math.sin(t * 4 + i)
		local bend = math.sin(t * 9 + i * 1.66)
		v.a.Position = polar(2.2 - i * 0.65, 3.0 + 0.26 * i, theta)
		v.b.Position = polar(-9 - i * 3.8, 4.0 + 1.5 * bend, theta + 0.32 * bend)
		v.a.Axis, v.b.Axis = V(-1, 0.16 * bend, 0).Unit, V(-1, -0.12 * bend, 0.07).Unit
		v.strip.CurveSize0, v.strip.CurveSize1 = 5.6, 8.9
		local mark = self.smears[i]
		mark.shoulder.Enabled, mark.streamer.Enabled = terminal, terminal
		if terminal then
			-- Short shutter on a supersonic descent. Cooler ion strands
			-- peel off the outer wake while the molten centre stays gold.
			local side = V(0, -0.85, 0.53) * (i - 4)
			local forward = V(-1, 0, 0)
			local flutter = if motion then math.sin(f * 0.74 + i) else 0
			mark.a.Position = V(-1.5 - i * 0.70, 0, 0) + side * 1.25
			mark.b.Position = V(-49 - i % 3 * 8, 0, 0) + side * (6.1 + 0.51 * flutter)
			mark.c.Position = V(-154 - i % 4 * 19, 0, 0) + side * (7.9 + 0.65 * flutter)
			mark.a.Axis, mark.b.Axis, mark.c.Axis = (forward + side * 0.13).Unit, (forward + side * 0.04).Unit, forward
			mark.shoulder.CurveSize0, mark.shoulder.CurveSize1 = 15, 20
			mark.streamer.CurveSize0, mark.streamer.CurveSize1 = 28, 34
		end
	end
	for i, s in self.streams do
		local spin = i * math.pi * 2 / #self.streams
		local boil = math.sin(7.8 * time + i * 1.31)
		s.a.Position = polar(1.0, 1.55, spin)
		local length = if terminal then 1.64 else 1
		local breadth = if terminal then 1.48 else 1
		s.b.Position =
			polar((-24 - i * 3.55 + 3.3 * boil) * length, (5.2 + 1.15 * boil) * breadth, spin + 0.32 + 0.12 * boil)
		s.c.Position =
			polar((-83 - 8 * i + 6.9 * boil) * length, (6.0 + 2.1 * math.sin(5 * time + i)) * breadth, spin + 0.92)
		s.a.Axis = V(-1, 0.11 * math.sin(spin), 0.14 * math.cos(spin)).Unit
		s.b.Axis = V(-1, 0.30 * math.sin(spin + time * 2), 0.16 * math.cos(spin)).Unit
		s.c.Axis = V(-1, 0.13 * math.cos(time + i), -0.16 * math.sin(time + i)).Unit
		s.outer.CurveSize0, s.outer.CurveSize1 = 8.0 * length, (9 + 2.2 * boil) * length
		s.core.CurveSize0, s.core.CurveSize1 = s.outer.CurveSize0, s.outer.CurveSize1
		s.far.CurveSize0, s.far.CurveSize1 = 22 * length, (12 + 2.0 * boil) * length
		s.outer.Width0, s.outer.Width1 = (1.30 + 0.21 * boil) * breadth, (2.6 + 0.68 * boil) * breadth
		s.far.Width0 = s.outer.Width1
	end
	for i, arcs in self.rings do
		local u = (t * 1.55 + i * 0.25) % 1
		local x = 4.0 - 56 * u ^ 1.43
		local radius = 2.85 + 12.9 * u
		for j, arc in arcs do
			local a = (j + i * 0.27) * math.pi / 2 + 0.24 * u
			local b = a + (1.30 - u * (0.77 + 0.08 * (j % 2)))
			arc.a.Position, arc.b.Position = polar(x, radius, a), polar(x - 0.44 * u, radius, b)
			arc.a.Axis, arc.b.Axis = V(0, math.cos(a), -math.sin(a)), V(0, math.cos(b), -math.sin(b))
			local bend = 4 / 3 * math.tan((b - a) / 4) * radius
			arc.beam.CurveSize0, arc.beam.CurveSize1 = bend, bend
			arc.beam.Width0, arc.beam.Width1 = 0.10 + 0.36 * u, 0.05 + 0.10 * u
			arc.beam.Transparency = NumberSequence.new(0.33 + 0.60 * u, 0.51 + 0.48 * u)
		end
	end
	for i, s in self.scraps do
		local u = (t * (0.61 + 0.04 * (i % 3)) + i * 0.0931) % 1
		local spin = i * 2.399
		local pos = polar(-1.5 - 67 * u ^ 1.5, 3 + 11 * u + 1.1 * math.sin(u * 5 + i), spin + u * 0.18)
		s.rock.CFrame = pose * CF(pos) * CFrame.Angles(i + 6 * u, -5 * u, 8 * u + i)
		s.rock.Transparency = math.max(0, (u - 0.83) / 0.17)
		s.a.Position, s.b.Position = pos, pos + V(-3 - 4.5 * u, 0, 0)
		s.tail.Transparency = NumberSequence.new(0.21 + 0.70 * u, 0.94)
	end
end
return Entry
