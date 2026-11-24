-- The light that reaches the surface. It breathes in the mine's own mouth, the
-- same place the player walks in and out of.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local V, CF = Vector3.new, CFrame.new
local Mouth = {}
Mouth.__index = Mouth

local function smoke(parent, size, color)
	local anchor = S.part(parent, "Glow", CF(), Vector3.one * 0.05, "FFFFFF")
	anchor.Transparency, anchor.CastShadow = 1, false
	local board = Instance.new("BillboardGui")
	board.LightInfluence, board.Size, board.Parent = 0, UDim2.fromScale(size, size), anchor
	local image = Instance.new("ImageLabel")
	image.Image, image.BackgroundTransparency = "rbxasset://textures/particles/smoke_main.dds", 1
	image.Size, image.ImageColor3, image.ImageTransparency, image.Parent = UDim2.fromScale(1, 1), Color3.fromHex(color), 1, board
	return { anchor = anchor, image = image }
end

function Mouth.new(stage)
	local model = S.group("Light in the mine mouth")
	local near, far = smoke(model, 13, "B77BFF"), smoke(model, 21, "8E4DF5")
	local rays = {}
	for i = 1, 8 do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = near.anchor, near.anchor
		local angle = (i - 0.5) / 8 * math.pi
		a1.Position = V(math.cos(angle) * 15, math.sin(angle) * 11 - 2.5, 9)
		local ray = Instance.new("Beam")
		ray.Attachment0, ray.Attachment1, ray.FaceCamera, ray.Segments = a0, a1, true, 1
		ray.LightEmission, ray.LightInfluence, ray.Width0, ray.Width1 = 1, 0, 0.6, 3.2
		ray.Color = ColorSequence.new(Color3.fromHex("E2CBFF"), Color3.fromHex("7C3FE0"))
		ray.Parent = near.anchor
		table.insert(rays, ray)
	end
	return setmetatable({ stage = stage, model = model, near = near, far = far, rays = rays, light = S.light(near.anchor, "A566FF", 40, 0) }, Mouth)
end

function Mouth:place(entrance)
	self.near.anchor.Position = entrance + V(0, 1.2, -8)
	self.far.anchor.Position = entrance + V(0, 1.2, -11)
	self.placed = true
end

-- Strong while it is news. A single low pulse when the player has come out.
function Mouth.level(frame)
	if frame < F.enter then
		return 0.78 + 0.14 * math.sin(frame / 6)
	end
	local age = frame - F.turn
	local pulse = S.ease(age, -2, 7) * (1 - 0.75 * S.ease(age, 10, 40))
	return 0.26 + 0.74 * pulse
end

function Mouth:draw(frame, motion)
	local active = self.placed and ((frame >= F.witness and frame < F.enter) or (frame >= F.answer and frame < F.endBlend))
	self.model.Parent = if active then self.stage else nil
	if not active then
		return
	end
	local fade = 1 - S.ease(frame, F.handoff, F.endBlend - 6)
	local k = (if motion then Mouth.level(frame) else 0.6) * fade
	self.near.image.ImageTransparency = 1 - 0.75 * k
	self.far.image.ImageTransparency = 1 - 0.5 * k
	self.near.image.Rotation = if motion then frame * 0.5 else 0
	self.far.image.Rotation = if motion then frame * -0.35 else 0
	self.light.Brightness = 2.2 * k
	for i, ray in self.rays do
		local flicker = if motion then 0.12 * math.sin(frame / 7 + i * 1.8) else 0
		ray.Transparency = NumberSequence.new(math.clamp(1 - k * (0.40 + flicker), 0, 1), 1)
	end
end

function Mouth:hide()
	self.model.Parent = nil
end

function Mouth:Destroy()
	self.model:Destroy()
end

return Mouth
