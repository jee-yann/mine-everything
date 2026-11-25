-- The light that reaches the surface. It has one source, down in the mine, and
-- it comes out of the same doorway the player uses. The broadcast shows this
-- very model at its own scale, so the two can never disagree.
--
-- Local space: the origin is the mine's `Entrance`, +Z faces out of the mine.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local V, CF = Vector3.new, CFrame.new
local soft = "rbxasset://textures/particles/smoke_main.dds"
local hex = Color3.fromHex
local Mouth = {}
Mouth.__index = Mouth

local core = V(0, 1.4, -10)
local floorY = -3.44

-- Set `scale` for a model of the doorway. `lamps` adds light on real surfaces.
function Mouth.new(stage, scale, lamps)
	local k = scale or 1
	local model = S.group("Light in the mine mouth")
	local origin = S.part(model, "Mouth", CF(), Vector3.one * 0.05, "FFFFFF")
	origin.Transparency, origin.CastShadow, model.PrimaryPart = 1, false, origin
	local self = setmetatable({ stage = stage, model = model, origin = origin, k = k }, Mouth)

	local function image(parent, color)
		local label = Instance.new("ImageLabel")
		label.Image, label.BackgroundTransparency, label.Size = soft, 1, UDim2.fromScale(1, 1)
		label.AnchorPoint, label.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
		label.ImageColor3, label.ImageTransparency, label.Parent = hex(color), 1, parent
		return label
	end
	local function puff(size, color)
		local at = Instance.new("Attachment")
		at.Parent = origin
		local board = Instance.new("BillboardGui")
		board.LightInfluence, board.Adornee, board.Size, board.Parent = 0, at, UDim2.fromScale(size * k, size * k), origin
		return { at = at, image = image(board, color) }
	end
	local function glare(a, b, wide, inner, outer)
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position, a0.Parent, a1.Parent = a * k, b * k, origin, origin
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1, beam.FaceCamera, beam.Segments = a0, a1, true, 1
		beam.Texture, beam.TextureMode, beam.TextureLength, beam.TextureSpeed = soft, Enum.TextureMode.Stretch, 1, 0
		beam.LightEmission, beam.LightInfluence, beam.Brightness = 1, 0, 2
		beam.Width0, beam.Width1 = wide[1] * k, wide[2] * k
		beam.Color, beam.Transparency, beam.Parent = ColorSequence.new(hex(inner), hex(outer)), NumberSequence.new(1), origin
		return beam
	end
	-- The source and its bloom, added to whatever is behind them.
	self.heart = {}
	for i, q in { { 2.2, "FBEFFF", 0.85 }, { 5, "BE82FF", 0.70 }, { 9, "8A3DFF", 0.75 }, { 14, "5F22D8", 0.6 } } do
		for turn = 0, 1 do
			local arm = if turn == 0 then V(q[1], 0, 0) else V(0, q[1], 0)
			local at = core + V(0, 0, -0.8 * i)
			table.insert(self.heart, { beam = glare(at - arm, at + arm, { q[1] * 2, q[1] * 2 }, q[2], q[2]), power = q[3] })
		end
	end
	-- Light lying on the paving in front of the doorway.
	local ground = S.part(model, "Light on the paving", CF(), V(34, 0.04, 22) * k, "FFFFFF")
	ground.Transparency, ground.CastShadow, self.ground = 1, false, ground
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.LightInfluence, gui.SizingMode, gui.PixelsPerStud = Enum.NormalId.Top, 0, Enum.SurfaceGuiSizingMode.PixelsPerStud, 20 / k
	gui.ClipsDescendants, gui.Parent = true, ground
	self.spill = { image(gui, "8A4BEE"), image(gui, "C79BFF") }
	self.spill[1].Size, self.spill[1].Position = UDim2.fromScale(1.1, 1.5), UDim2.fromScale(0.5, 0.18)
	self.spill[2].Size, self.spill[2].Position = UDim2.fromScale(0.62, 1.25), UDim2.fromScale(0.5, 0.08)
	-- Shafts through the dust. The texture feathers them, so they have no edges.
	self.shafts = {}
	for i = 1, 9 do
		local fan = (i - 5) / 4
		local far = V(fan * 17, 2.5 + 8.5 * (1 - math.abs(fan)) + 1.6 * math.sin(i * 2.4), 13 + 2 * math.cos(i * 1.7))
		local beam = glare(core + V(fan * 1.6, 0.2 * math.cos(i * 2.1), 0), far, { 2.0, 5.5 }, "E9D6FF", "7A35F0")
		table.insert(self.shafts, { beam = beam, seed = i })
	end
	-- Haze rolling out along the ground, and dust carried by it.
	self.haze, self.motes = {}, {}
	for i = 1, 8 do
		local p = puff(7 + 1.4 * (i % 3), if i % 2 == 0 then "A86BFF" else "7E46DC")
		p.lane, p.phase, p.spin = ((i * 0.618) % 1 - 0.5) * 13, i / 8, if i % 2 == 0 then 1 else -1
		table.insert(self.haze, p)
	end
	for i = 1, 30 do
		local p = puff(0.30 + 0.22 * (i % 3), if i % 4 == 0 then "FFFFFF" else "D9B8FF")
		p.lane, p.phase, p.height = ((i * 0.618) % 1 - 0.5) * 14, (i * 0.377) % 1, 0.6 + 7.5 * ((i * 0.271) % 1)
		table.insert(self.motes, p)
	end
	self.lamps = {}
	if lamps then
		for _, q in { { V(0, -0.6, -13), 34, 4.5 }, { V(0, 2.4, -2), 22, 2.6 }, { V(0, -0.4, 8.5), 18, 0.9 } } do
			local holder = Instance.new("Attachment")
			holder.Position, holder.Parent = q[1], origin
			table.insert(self.lamps, { light = S.light(holder, "7A30FF", q[2], 0), power = q[3] })
		end
	end
	return self
end

-- `at` is the entrance with its back to the mine.
function Mouth:place(at)
	self.at = at
	self.model:PivotTo(at)
	self.ground.CFrame = at * CF(V(0, floorY + 0.03, 12.6) * self.k)
end

-- The moment it is first seen outside, the steady light it settles to, and a
-- single low pulse when the player has come out.
function Mouth.level(frame)
	if frame < F.living then
		local age = frame - F.outside
		return 0.05 + 0.66 * S.ease(age, 5, 24) + 0.46 * S.ease(age, 17, 24) * (1 - S.ease(age, 25, 38)) + 0.05 * math.sin(frame / 6)
	elseif frame < F.witness then
		-- The report. It swells again as the two of them watch.
		local age = frame - F.living
		return 0.66 + 0.07 * math.sin(frame / 6) + 0.30 * S.ease(age, 16, 24) * (1 - 0.7 * S.ease(age, 27, 44))
	elseif frame < F.enter then
		return 0.74 + 0.10 * math.sin(frame / 6)
	end
	local age = frame - F.turn
	return 0.26 + 0.74 * S.ease(age, -2, 7) * (1 - 0.75 * S.ease(age, 10, 40))
end

-- Draw the same exposure anywhere. `shown` is how much of it is in the picture.
function Mouth:expose(frame, motion, shown)
	local level = (if motion then Mouth.level(frame) else 0.7) * (shown or 1)
	local t = if motion then frame else 100
	local k = self.k
	for _, h in self.heart do
		h.beam.Transparency = NumberSequence.new(math.clamp(1 - h.power * level, 0, 1))
	end
	self.spill[1].ImageTransparency = math.clamp(1 - 0.72 * level, 0, 1)
	self.spill[2].ImageTransparency = math.clamp(1 - 0.60 * level, 0, 1)
	for _, s in self.shafts do
		local flicker = 0.12 * math.sin(t / 7 + s.seed * 1.8)
		s.beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, math.clamp(1 - (0.72 + flicker) * level, 0, 1)),
			NumberSequenceKeypoint.new(0.5, math.clamp(1 - (0.40 + flicker) * level, 0, 1)),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
	for i, p in self.haze do
		local u = (p.phase + t * 0.0085) % 1
		p.at.Position = V(p.lane * (0.6 + 0.9 * u), floorY + 1.3 + 1.1 * u, -6 + 21 * u) * k
		p.image.ImageTransparency = math.clamp(1 - 0.34 * level * math.sin(u * math.pi), 0, 1)
		p.image.Rotation = t * 0.25 * p.spin + i * 47
	end
	for i, p in self.motes do
		local u = (p.phase + t * 0.0062) % 1
		p.at.Position = V(p.lane * (0.5 + 0.8 * u) + 0.5 * math.sin(t / 11 + i), floorY + p.height + 1.2 * u, -7 + 22 * u) * k
		p.image.ImageTransparency = math.clamp(1 - 1.1 * level * math.sin(u * math.pi), 0, 1)
	end
	-- A lamp is late on a cut, so after one it always comes up from nothing.
	local up = if not motion then 1 elseif frame >= F.answer then S.ease(frame, F.answer + 4, F.answer + 30)
		elseif frame >= F.living then S.ease(frame, F.witness + 2, F.witness + 34) else 1
	for _, l in self.lamps do
		l.light.Brightness = l.power * level * up
	end
end

function Mouth:draw(frame, motion)
	-- It stays in place through the rooms, so its lamps are never late on a cut.
	local active = self.at and ((frame >= F.outside and frame < F.enter) or (frame >= F.answer and frame < F.endBlend))
	self.model.Parent = if active then self.stage else nil
	if active then
		self:expose(frame, motion, 1 - S.ease(frame, F.handoff, F.endBlend - 6))
	end
end

function Mouth:hide()
	self.model.Parent = nil
end

function Mouth:Destroy()
	self.model:Destroy()
end

return Mouth
