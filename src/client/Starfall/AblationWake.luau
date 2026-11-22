local UserInputService = game:GetService("UserInputService")
local S = require(script.Parent.Scenery)
local sheet = require(script.Parent.ExposureSheet)

local Wake = {}
Wake.__index = Wake
local V = Vector3.new
local across = V(0, -0.85, 0.53)
local deep = V(0, 0.53, 0.85)
local uphill = V(-1, 0, 0)
local stations = { 0, 28, 66, 109, 156, 215, 275, 344, 421 }

-- Distances run back from the crater along the baked terminal velocity.
-- Each outside edge is the same hue and side as its approaching ion sheath.
local layers = {
	{
		name = "Amber halo",
		side = 0,
		width = 12.5,
		color = "FFA75B",
		cool = "D9867A",
		alpha = 0.32,
		emission = 0.32,
		life = 27,
	},
	{
		name = "Fusion line",
		side = 0,
		width = 3.9,
		color = "FFF1AB",
		cool = "FCAB7F",
		alpha = 0.96,
		emission = 0.75,
		life = 26,
	},
	{
		name = "Violet ion edge",
		side = -1,
		width = 5.3,
		color = "D929A2",
		cool = "B676CF",
		alpha = 0.91,
		emission = 0.08,
		life = 40,
	},
	{
		name = "Blue ion edge",
		side = 1,
		width = 4.8,
		color = "39BFD8",
		cool = "85BAC9",
		alpha = 0.88,
		emission = 0.08,
		life = 37,
	},
	{
		name = "Detached orange thread",
		side = -0.42,
		width = 1.85,
		color = "FF9166",
		cool = "F3ABBB",
		alpha = 0.86,
		emission = 0.25,
		life = 32,
	},
}

local function socket(part)
	local a = Instance.new("Attachment")
	a.Parent = part
	return a
end

local function ribbon(part, a, b, name, hot, cool, emission, steps)
	local beam = Instance.new("Beam")
	beam.Name, beam.Attachment0, beam.Attachment1 = name, a, b
	beam.FaceCamera, beam.Segments, beam.LightInfluence, beam.LightEmission = true, steps, 0, emission
	beam.Color = ColorSequence.new(Color3.fromHex(hot), Color3.fromHex(cool))
	beam.Parent = part
	return beam
end

function Wake.new(base, contact, direction, motion)
	local pose = base * CFrame.lookAt(contact, contact + direction) * CFrame.Angles(0, math.pi / 2, 0)
	local root = S.part(nil, "Cooling atmospheric entry channel", pose, Vector3.one * 0.05, "FFFFFF")
	root.Transparency, root.CastShadow = 1, false
	local touch = UserInputService.TouchEnabled
	local strands = {}
	for _, layer in layers do
		local nodes, spans = {}, {}
		for i in stations do
			nodes[i] = socket(root)
			if i > 1 then
				spans[i - 1] = ribbon(
					root,
					nodes[i - 1],
					nodes[i],
					layer.name,
					layer.color,
					layer.cool,
					layer.emission,
					if touch then 5 else 10
				)
			end
		end
		table.insert(strands, { layer = layer, nodes = nodes, spans = spans })
	end
	local flecks = {}
	for i = 1, if touch then 7 else 12 do
		local a, b = socket(root), socket(root)
		local beam =
			ribbon(root, a, b, "Hot ablation fragment", if i % 3 == 0 then "99DEED" else "FFD19A", "D98B9E", 0.6, 4)
		flecks[i] = { head = a, tail = b, beam = beam }
	end
	return setmetatable({ root = root, motion = motion, strands = strands, flecks = flecks }, Wake)
end

local function channel(distance, side, age, motion)
	local u = distance / 421
	local edge = (2 + 17 * (1 - math.exp(-distance / 82))) * side
	local unwind = if motion then S.ease(age, 1, 34) else 0
	local ripple = math.sin(8.4 * u - 0.058 * age + side * 0.54)
	local swell = math.sin(17 * u + 0.043 * age + side * 0.90)
	local lift = unwind * (4 + 23 * u) * (0.62 + 0.38 * ripple)
	return uphill * distance
		+ across * (edge + unwind * (15 * ripple + side * 11 * swell))
		+ deep * (2.5 * side + unwind * (10 * swell - lift))
		+ V(0, lift, 0)
end

function Wake:draw(frame, parent)
	local age = frame - sheet.frames.contact
	local live = age >= 0 and age < 43
	self.root.Parent = if live then parent else nil
	if not live then
		return
	end
	for _, strand in self.strands do
		local layer = strand.layer
		for i, distance in stations do
			local node = strand.nodes[i]
			node.Position = channel(distance, layer.side, age, self.motion)
			node.Axis = (channel(distance + 1, layer.side, age, self.motion) - node.Position).Unit
		end
		for i, beam in strand.spans do
			local near, far = stations[i], stations[i + 1]
			-- The hot ground end burns away first. Differences in lifetime
			-- leave detached lengths of colour above the mushrooming ejecta.
			local breakup = if self.motion then 3.2 * math.sin(i * 2.43 + layer.side) else 0
			local finish = layer.life - 10 * (1 - near / 421) + breakup
			local residual = if self.motion and age == 1 then 0.39 elseif self.motion and age == 2 then 0.23 else 1
			local alpha = residual * layer.alpha * (1 - S.ease(age, finish * 0.32, finish))
			beam.Enabled = alpha > 0.012
			if beam.Enabled then
				local thinning = 1 - S.ease(age, 5, finish) * 0.64
				beam.Width0 = layer.width * thinning * (0.44 + 0.66 * math.sin(0.38 + near / 475 * math.pi))
				beam.Width1 = layer.width * thinning * (0.44 + 0.66 * math.sin(0.38 + far / 475 * math.pi))
				beam.CurveSize0, beam.CurveSize1 = (far - near) / 3, (far - near) / 3
				local split = if self.motion then S.ease(age, 7 + i % 3, 27 + i % 4) else 0
				beam.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1 - alpha * (1 - split * 0.81)),
					NumberSequenceKeypoint.new(0.22, 1 - alpha),
					NumberSequenceKeypoint.new(0.73, 1 - alpha),
					NumberSequenceKeypoint.new(1, 1 - alpha * (1 - split * 0.88)),
				})
			end
		end
	end
	for i, fleck in self.flecks do
		local released = age - 3 - (i * 7 % 13)
		local active = self.motion and released > 0 and released < 13 + i % 6
		fleck.beam.Enabled = active
		if active then
			local side = if i % 2 == 0 then -1 else 1
			local phase = released / (13 + i % 6)
			local origin = channel(20 + i * 20, side, age, true)
			local offset = across * (side * (3 + i % 4)) + deep * math.sin(i * 2.39) * 2.8
			fleck.head.Position = origin + offset * released * 0.75 - V(0, 17 * phase * phase, 0)
			fleck.tail.Position = fleck.head.Position + uphill * (4 + 8 * phase) - offset * 1.7
			local width = 0.6 + 1.4 * math.sin(math.pi * phase)
			fleck.beam.Width0, fleck.beam.Width1 = width, 0.05
			fleck.beam.Transparency = NumberSequence.new(0.09 + 0.84 * phase, 0.91)
		end
	end
end

return Wake
