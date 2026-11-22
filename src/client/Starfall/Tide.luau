local S = require(script.Parent.Scenery)
local Sprite = require(script.Parent.WorldSprite)
local clock = require(script.Parent.Timeline)
local V, CF = Vector3.new, CFrame.new
local Tide = {}
Tide.__index = Tide

-- Look past the eastern headland. The star and the full start of its tail
-- clear the high terraces before passing above the offshore ridge.
local eye = V(238.9, 25.8, 30.1)
local north = V(-0.37, 0, -0.929).Unit
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
local function sky(root)
	local anchor = S.part(root, "Painted dawn", CF(plane(0, 205, 900)), Vector3.one, "FFFFFF")
	anchor.Transparency, anchor.CastShadow = 1, false
	local board = Instance.new("BillboardGui")
	board.LightInfluence, board.Size, board.Parent = 0, UDim2.fromScale(1950, 1020), anchor
	local bg = Instance.new("Frame")
	bg.BackgroundColor3, bg.BorderSizePixel, bg.Size, bg.Parent = Color3.new(1, 1, 1), 0, UDim2.fromScale(1, 1), board
	local grade = Instance.new("UIGradient")
	grade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("10182F")),
		ColorSequenceKeypoint.new(0.43, Color3.fromHex("293553")),
		ColorSequenceKeypoint.new(0.60, Color3.fromHex("454663")),
		ColorSequenceKeypoint.new(0.67, Color3.fromHex("8C829A")),
		ColorSequenceKeypoint.new(0.72, Color3.fromHex("536B89")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("384C6B")),
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
		stroke(root, a, b, 0, h, col, 0.40)
		stroke(root, b, c, h, 0, col, 0.40)
	end
end
function Tide.new(stage, base)
	local root = S.group("First light on the tide")
	sky(root)
	local glint = S.group("Distant traveller")
	glint.Parent = root
	local star = Vector3.zero
	local core = S.part(glint, "First glint", CF(), Vector3.one * 1.25, "FFF0CE", Enum.Material.Neon)
	core.Shape, core.CastShadow = Enum.PartType.Ball, false
	local halo = Sprite.new(core, "Gold through the outer corona", "rbxasset://textures/glow.png", 0)
	halo.card.Brightness = 3
	Sprite.draw(halo, star, 40, 38, -12, Color3.fromHex("FFD6AD"), 0.12)
	for _, d in { { 11, 1.3, 1.5 }, { -12, -1.4, 1.7 }, { -1.2, 10, 1.3 }, { 1.4, -10, 1.3 } } do
		stroke(glint, star, star + across * d[1] + Vector3.yAxis * d[2], d[3], 0.01, "FFF0D3", 0.03)
	end
	local wake = stroke(root, star, star, 0.02, 3.4, "C59AE6", 0.13)
	local hot = stroke(root, star, star, 0.02, 1.40, "FFF0C4", 0.03)
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
		ripples[i] = { left = mark, right = tip, a = a, b = b, distance = d, i = i }
	end
	root:PivotTo(base)
	return setmetatable(
		{ stage = stage, root = root, ripples = ripples, glint = glint, wake = wake, hot = hot, base = base },
		Tide
	)
end
local function flight(t)
	local u = t / clock.entry
	return plane(-24 + 62 * u + 45 * u * u, 107 - 12 * u - 10 * u * u, 300)
end
function Tide:draw(t)
	self.root.Parent = if t < clock.entry then self.stage else nil
	if t >= clock.entry then
		return
	end
	local head = flight(t)
	self.glint:PivotTo(self.base * CF(head))
	for i, brush in { self.wake, self.hot } do
		local tail = flight(t - (if i == 1 then 0.65 else 0.32))
		brush.Parent.CFrame = self.base * CF(tail)
		brush.Attachment1.Position = head - tail
	end
	local offset = (head - eye):Dot(across) / 300
	for _, r in self.ripples do
		local v = math.sin(3.3 * t + r.i * 0.74)
		local shift = across * (v * 0.25 + offset * r.distance) + north * (0.19 * v)
		r.left.Parent.Position = self.base * (r.a + shift)
		r.right.Parent.Position = self.base * (r.b + shift)
	end
end
function Tide:Destroy()
	self.root:Destroy()
end
return Tide
