local S = require(script.Parent.Scenery)
local clock = require(script.Parent.Timeline)
local V, CF = Vector3.new, CFrame.new
local Tide = {}
Tide.__index = Tide

-- Look past the near vertical face of the eastern mesa to the offshore ridge.
local eye = V(267.7, 25.8, 18.6)
local north = V(-0.338, 0, -0.941).Unit
local across = north:Cross(Vector3.yAxis)
local function plane(x, y, distance)
	return eye + across * x + Vector3.yAxis * y + north * distance
end
function Tide.camera(t, motion)
	local drift = if motion then S.ease(t, 0, clock.entry) else 0
	return eye + across * (0.6 * drift), plane(0, 1.2 + 0.8 * drift, 50), 46
end
local function stroke(root, a, b, wa, wb, color, alpha)
	local part = S.part(root, "Painted light", CF(a), Vector3.one * 0.1, color)
	part.Transparency, part.CastShadow = 1, false
	local first, last = Instance.new("Attachment"), Instance.new("Attachment")
	first.Parent, last.Position, last.Parent = part, b - a, part
	local brush = Instance.new("Beam")
	brush.FaceCamera, brush.Attachment0, brush.Attachment1 = true, first, last
	brush.Color, brush.Transparency = ColorSequence.new(Color3.fromHex(color)), NumberSequence.new(alpha or 0)
	brush.Width0, brush.Width1, brush.LightEmission, brush.Parent = wa, wb, 0.75, part
	return brush
end
local function sky(root, nightLook)
	local anchor = S.part(root, "Painted dawn", CF(plane(0, 205, 900)), Vector3.one, "FFFFFF")
	anchor.Transparency, anchor.CastShadow = 1, false
	local board = Instance.new("BillboardGui")
	board.LightInfluence, board.Size, board.Parent = 0, UDim2.fromScale(1950, 1020), anchor
	local bg = Instance.new("Frame")
	bg.BackgroundColor3, bg.BorderSizePixel, bg.Size, bg.Parent = Color3.new(1, 1, 1), 0, UDim2.fromScale(1, 1), board
	local grade = Instance.new("UIGradient")
	grade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new():Lerp(nightLook.SkyColor, 0.42)),
		ColorSequenceKeypoint.new(0.6, nightLook.SkyColor),
		ColorSequenceKeypoint.new(1, Color3.new():Lerp(nightLook.SkyColor, 0.84)),
	})
	grade.Rotation, grade.Parent = 90, bg
	local rng = Random.new(767)
	for i = 1, 97 do
		local x, y = rng:NextNumber(0.17, 0.83), rng:NextNumber(0.20, 0.623)
		local w = rng:NextNumber(0.00032, 0.00099)
		local star = Instance.new("Frame")
		star.Name, star.Position, star.Size = "Star", UDim2.fromScale(x, y), UDim2.fromScale(w, w * 1.9)
		star.BackgroundColor3 = if i % 5 == 0 then Color3.fromHex("FFDFC4") else Color3.fromHex("DDE2FB")
		star.BackgroundTransparency, star.BorderSizePixel, star.Rotation, star.Parent =
			rng:NextNumber(0.17, 0.56), 0, 45, bg
	end
	-- Three low cirrus banks, painted with asymmetric tapered strokes.
	for _, cloud in
		{
			{ -169, 43, 118, 4.6, "AA91A5" },
			{ -120, 51, 73, 2.4, "D9B1B4" },
			{ 54, 41, 99, 4.8, "AE91A0" },
			{ 101, 44, 52, 1.9, "DDACAB" },
			{ -215, 87, 92, 1.4, "89758F" },
		}
	do
		local x, y, w, h, col = table.unpack(cloud)
		local a, b, c = plane(x, y, 460), plane(x + w * 0.39, y + 0.7, 460), plane(x + w, y + 4.5, 460)
		stroke(root, a, b, 0, h, col, 0.84)
		stroke(root, b, c, h, 0, col, 0.84)
	end
end
local function flight(t)
	local u = t / clock.entry
	return plane(-48 + 73 * u + 55 * u * u, 97 - 12 * u - 11 * u * u, 316 - 18 * u)
end

local function combustion(u, motion)
	-- Two broader burns sit over smaller irregular fluctuations in the flame.
	local burn = 0.78 + 0.23 * math.clamp(u, 0, 1)
	if motion then
		burn += 0.085 * math.sin(30 * u + 0.4) + 0.042 * math.sin(52 * u - 0.85) + 0.26 * math.exp(
			-((u - 0.31) / 0.078) ^ 2
		) + 0.22 * math.exp(-((u - 0.78) / 0.065) ^ 2)
	end
	return burn
end

local function ellipse(model, name, at, tint, alpha)
	local p = S.part(model, name, CF(at), Vector3.one, tint, Enum.Material.Neon)
	p.Shape, p.Transparency, p.CastShadow = Enum.PartType.Ball, alpha, false
	return p
end

local function traveller(root)
	local head = S.group("Distant traveller")
	head.Parent = root
	local shoulder, heel = {}, {}
	for i = 1, 5 do
		local a = i * math.pi * 0.4 + 0.23
		shoulder[i] = V(0.37 + 0.22 * math.sin(i * 2.6), 1.12 * math.cos(a), 0.91 * math.sin(a))
		heel[i] = V(-1.42 - 0.24 * math.cos(i * 2.9), 0.78 * math.cos(a + 0.28), 0.85 * math.sin(a + 0.28))
	end
	local mineral = { "C4AAE2", "FFB486", "B0CBFA", "FABDB5", "FDE9CB" }
	for i, a in shoulder do
		local j = i % #shoulder + 1
		S.facet(head, "Incandescent leading face", a, shoulder[j], V(1.72, -0.08, 0.12), "FFF0D6", Enum.Material.Neon)
		S.facet(head, "Turning mineral", a, shoulder[j], heel[i], mineral[i], Enum.Material.Neon)
		S.facet(head, "Turning mineral", heel[i], heel[j], shoulder[j], mineral[(i + 1) % 5 + 1], Enum.Material.Neon)
		S.facet(head, "Ablating heel", heel[i], heel[j], V(-2.83, 0.14, -0.18), mineral[i], Enum.Material.Neon)
	end
	local core = ellipse(head, "First glint", V(0.83, 0, 0.09), "FFF6DF", 0.02)
	local veil = ellipse(head, "Heated air at the bow", V(0.49, 0, 0), "FFCE9B", 0.78)
	local fringe = ellipse(head, "Thin blue shock layer", V(-0.08, 0, 0), "AFBCFF", 0.92)
	return head, core, veil, fringe
end

local ages = { 0, 0.040, 0.100, 0.178, 0.287, 0.425, 0.589 }
local function train(root)
	local anchor = S.part(root, "Ion train datum", CF(), Vector3.one * 0.1, "FFFFFF")
	anchor.Transparency, anchor.CastShadow = 1, false
	local strands = {}
	for k, ink in { "B89EDC", "FFE3B2", "B3D8FF" } do
		local strand = {}
		strands[k] = strand
		for i = 1, #ages do
			local point = Instance.new("Attachment", anchor)
			local brush
			if i > 1 then
				brush = Instance.new("Beam")
				brush.Name = if k == 1
					then "Cooling violet vapour"
					elseif k == 2 then "Luminous train"
					else "Ion filament"
				brush.Attachment0, brush.Attachment1 = strand[i - 1].at, point
				brush.LightInfluence, brush.LightEmission, brush.FaceCamera, brush.Segments = 0, 1, true, 1
				brush.Color = ColorSequence.new(Color3.fromHex(ink))
				local density = if k == 1 then 0.45 elseif k == 2 then 0.93 else 0.66
				local a = 1 - density * (1 - (i - 2) / (#ages - 1)) ^ 1.6
				local b = 1 - density * (1 - (i - 1) / (#ages - 1)) ^ 1.6
				brush.Transparency = NumberSequence.new(a, b)
				brush.Parent = anchor
			end
			strand[i] = { at = point, beam = brush }
		end
	end
	return strands
end

function Tide.new(stage, base, nightLook, motion)
	local root = S.group("First light on the tide")
	sky(root, nightLook or require(script.Parent.NightLook))
	local glint, core, veil, fringe = traveller(root)
	local strands = train(root)
	local flakes = {}
	for i = 1, 4 do
		flakes[i] = ellipse(root, "Separated hot grain", Vector3.zero, if i % 2 == 1 then "FFD4A0" else "C1D2FF", 1)
	end
	local rng = Random.new(910)
	local ripples = {}
	for i = 1, 62 do
		local d = 11 + 89 * (i / 62) ^ 1.57
		local side = rng:NextNumber(-1, 1)
		local width = rng:NextNumber(0.16, 0.63) * (1.3 + 0.014 * d)
		local x = d * 0.037 + side * (0.54 + d * 0.012)
		local origin = plane(x, 20.55 - eye.Y, d)
		local tone = ({ "BB99B9", "D9BB96", "EDCFAA", "917E9F", "BAA0BC" })[1 + i % 5]
		local height = rng:NextNumber(0.022, 0.058)
		local a, b, c = origin - across * width, origin, origin + across * width * 0.85 + north * 0.075
		local mark = stroke(root, a, b, 0.003, height, tone, rng:NextNumber(0.18, 0.51))
		local tip = stroke(root, b, c, height, 0.004, tone, mark.Transparency.Keypoints[1].Value)
		ripples[i] = { left = mark, right = tip, a = a, b = b, distance = d, height = height, i = i }
	end
	root:PivotTo(base)
	return setmetatable(
		{
			stage = stage,
			root = root,
			ripples = ripples,
			glint = glint,
			core = core,
			veil = veil,
			fringe = fringe,
			strands = strands,
			flakes = flakes,
			base = base,
			motion = motion ~= false,
		},
		Tide
	)
end
function Tide:draw(t)
	self.root.Parent = if t < clock.entry then self.stage else nil
	if t >= clock.entry then
		return
	end
	local u, head = t / clock.entry, flight(t)
	local power = combustion(u, self.motion)
	local forward = (head - flight(t - 0.017)).Unit
	local side = forward:Cross(Vector3.yAxis).Unit
	local up = side:Cross(forward).Unit
	local turn = if self.motion then 0.37 + 5.7 * u + 0.22 * math.sin(9.6 * u) else 0.37 + 1.1 * u
	self.glint:PivotTo(
		self.base * CFrame.fromMatrix(head, forward, up, side) * CFrame.Angles(turn, 0, 0.11 * math.sin(turn))
	)
	self.core.Size = V(2.37, 1.52, 1.39) * power
	self.veil.Size = V(4.72, 2.91, 2.74) * power
	self.fringe.Size = V(6.62, 4.12, 3.88) * power
	self.veil.Transparency = 0.86 - 0.15 * power
	for k, strand in self.strands do
		local lastWidth
		for i, node in strand do
			local lag = ages[i] * (if k == 2 then 0.75 elseif k == 3 then 0.89 else 1)
			local history = t - lag
			local spread = lag * (4.4 + 3.0 * lag)
			local spin = if self.motion then history * 7.8 + k * 1.95 else k * 1.95
			node.at.Position = flight(history)
				+ up * (spread * math.sin(spin))
				+ side * (spread * 0.67 * math.cos(spin))
			local width = (if k == 1 then 3.0 elseif k == 2 then 1.02 else 0.68)
				* combustion(history / clock.entry, self.motion)
				* (1 - (i - 1) / (#ages - 1)) ^ 0.80
			if node.beam then
				node.beam.Width0, node.beam.Width1 = lastWidth, width
			end
			lastWidth = width
		end
	end
	for i, grain in self.flakes do
		local birth = 0.10 + (i - 1) * 0.207
		local a = math.clamp((u - birth) / 0.237, 0, 1)
		grain.Transparency = if self.motion then 1 - math.sin(a * math.pi) * 0.89 else 1
		if grain.Transparency < 0.995 then
			local drift = up * ((if i % 2 == 0 then 1 else -1) * (0.45 + 3.35 * a)) + side * a
			grain.CFrame = self.base * CFrame.fromMatrix(flight(t - (0.028 + 0.22 * a)) + drift, forward, up, side)
			grain.Size = V(1.20, 0.50, 0.45) * (1 - 0.46 * a)
		end
	end
	local offset = (head - eye):Dot(across) / (head - eye):Dot(north)
	for _, r in self.ripples do
		local v = math.sin((if self.motion then 3.3 * t else 0) + r.i * 0.74)
		local shift = across * (v * 0.25 + offset * r.distance) + north * (0.19 * v)
		r.left.Parent.Position = self.base * (r.a + shift)
		r.right.Parent.Position = self.base * (r.b + shift)
		local swell = r.height * power * (0.91 + 0.16 * v)
		r.left.Width1, r.right.Width0 = swell, swell
	end
end
function Tide:Destroy()
	self.root:Destroy()
end
return Tide
