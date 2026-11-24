-- The light of the star in the ground. It leaves the mine, finds the player,
-- and after their strike it races home to show the way in.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local V, CF = Vector3.new, CFrame.new
local M = Enum.Material
local Path = {}
Path.__index = Path
local count = 46

local function smoke(parent, at, size, color)
	local anchor = S.part(parent, "Glow", CF(at), Vector3.one * 0.05, "FFFFFF")
	anchor.Transparency, anchor.CastShadow = 1, false
	local board = Instance.new("BillboardGui")
	board.LightInfluence, board.Size, board.Parent = 0, UDim2.fromScale(size, size), anchor
	local image = Instance.new("ImageLabel")
	image.Image, image.BackgroundTransparency = "rbxasset://textures/particles/smoke_main.dds", 1
	image.Size, image.ImageColor3, image.ImageTransparency, image.Parent = UDim2.fromScale(1, 1), Color3.fromHex(color), 1, board
	return { anchor = anchor, image = image }
end

function Path.new(stage)
	return setmetatable({ stage = stage, model = S.group("Light in the ground") }, Path)
end

function Path:place(foot, entrance, site, unit)
	self.model:ClearAllChildren()
	self.unit = unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = if site then { site } else {}
	local points = {}
	for i = 0, count do
		local u = i / count
		local p = foot:Lerp(entrance, u)
		-- A slow wander. Roots do not grow in straight lines.
		p += V(math.sin(u * 9.4) * 0.9 * math.sin(u * math.pi), 0, 0)
		local y = foot.Y + (entrance.Y - 3.4 - foot.Y) * u
		local hit = site and workspace:Raycast(V(p.X, foot.Y + 5, p.Z), V(0, -11, 0), params)
		if hit and hit.Normal.Y > 0.8 and math.abs(hit.Position.Y - y) < 2.2 then
			y = hit.Position.Y
		end
		points[i] = V(p.X, y + 0.05, p.Z)
	end
	self.points, self.strips = points, {}
	for i = 1, count do
		local a, b = points[i - 1], points[i]
		for layer, w in { 0.62, 0.22 } do
			local strip = S.part(self.model, "Lit root", CFrame.lookAt((a + b) / 2, b) * CF(0, layer * 0.012, 0),
				V(w * unit, 0.03, (a - b).Magnitude + 0.1), if layer == 1 then "8A4DF0" else "F1E4FF", M.Neon)
			strip.CastShadow, strip.Transparency = false, 1
			table.insert(self.strips, { part = strip, u = (i - 0.5) / count, layer = layer })
		end
	end
	self.head = smoke(self.model, points[0], 5, "C9A1FF")
	self.core = S.part(self.model, "Light head", CF(points[0]), Vector3.one * 0.7 * unit, "F6ECFF", M.Neon)
	self.core.Shape, self.core.CastShadow = Enum.PartType.Ball, false
	self.lamp = S.light(self.core, "B07CFF", 20, 0)
	-- The mouth of the mine, lit from inside.
	local mouth = entrance + V(0, 1.2, -8)
	self.mouth = { smoke(self.model, mouth, 13, "B77BFF"), smoke(self.model, mouth + V(0, 0, -3), 21, "8E4DF5") }
	self.mouthLight = S.light(self.mouth[1].anchor, "A566FF", 40, 0)
	self.rays = {}
	for i = 1, 8 do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = self.mouth[1].anchor, self.mouth[1].anchor
		local angle = (i - 0.5) / 8 * math.pi
		a1.Position = V(math.cos(angle) * 15, math.sin(angle) * 11 - 2.5, 9)
		local ray = Instance.new("Beam")
		ray.Attachment0, ray.Attachment1, ray.FaceCamera, ray.Segments = a0, a1, true, 1
		ray.LightEmission, ray.LightInfluence, ray.Width0, ray.Width1 = 1, 0, 0.6, 3.2
		ray.Color = ColorSequence.new(Color3.fromHex("E2CBFF"), Color3.fromHex("7C3FE0"))
		ray.Parent = self.mouth[1].anchor
		table.insert(self.rays, ray)
	end
	-- The compass star answers. Copies of its own inlay sit a hair above it.
	self.needles = {}
	local center, list = Vector3.zero, {}
	if site then
		for _, item in site:GetDescendants() do
			if item.Name == "Compass needle" and item:IsA("BasePart") then
				table.insert(list, item)
				center += item.Position
			end
		end
	end
	if #list > 0 then
		center /= #list
		for _, item in list do
			local copy = item:Clone()
			copy:ClearAllChildren()
			copy.Anchored, copy.CanCollide, copy.CanQuery, copy.CanTouch, copy.CastShadow = true, false, false, false, false
			copy.Material, copy.Color, copy.Transparency = M.Neon, Color3.fromHex("C79BFF"), 1
			copy.CFrame += V(0, 0.035, 0)
			copy.Parent = self.model
			table.insert(self.needles, { part = copy, far = (item.Position - center).Magnitude })
		end
	end
end

function Path:at(u)
	local x = math.clamp(u, 0, 1) * count
	local i = math.min(count - 1, math.floor(x))
	return self.points[i]:Lerp(self.points[i + 1], x - i)
end

-- Position of the travelling head, 0 at the player and 1 at the mine.
function Path.travel(frame)
	if frame < F.answer - 2 then
		local u = math.clamp((frame - (F.arrive - 16)) / 38, 0, 1)
		return 1 - u * u * (2.2 - 1.2 * u), frame >= F.arrive - 16 and u < 1, false
	end
	local u = math.clamp((frame - F.answer - 1) / 34, 0, 1)
	return 1 - (1 - u) ^ 1.6, u > 0 and u < 1, true
end

function Path:draw(frame, motion)
	local active = frame >= F.witness and frame < F.endBlend and self.points ~= nil
	self.model.Parent = if active then self.stage else nil
	if not active then
		return
	end
	local u, moving, home = Path.travel(frame)
	local fade = 1 - S.ease(frame, F.handoff + 4, F.endBlend - 8)
	for _, s in self.strips do
		local lit
		if home then
			lit = if s.u <= u then math.max(0.30, 1 - (u - s.u) * 2.4) else 0
		else
			lit = if s.u >= u then math.max(0.16, 1 - (s.u - u) * 2.2) else 0
			lit *= 1 - 0.6 * S.ease(frame, F.sprout, F.strike)
		end
		if frame < F.arrive - 16 then
			lit = 0
		end
		s.part.Transparency = 1 - lit * fade * (if s.layer == 1 then 0.75 else 1)
	end
	local p = self:at(u)
	self.core.Position = p + V(0, 0.25, 0)
	self.core.Transparency = if moving then 0 else 1
	self.head.anchor.Position = p + V(0, 0.4, 0)
	self.head.image.ImageTransparency = if moving then 0.25 else 1
	self.lamp.Brightness = if moving then 2.6 else 0
	local breath = if motion then math.sin(frame / 6) else 0
	local mouth = (0.75 + 0.15 * breath) * fade * (if home then 0.55 + 0.6 * S.ease(u, 0.8, 1) else 1)
	for i, g in self.mouth do
		g.image.ImageTransparency = 1 - math.clamp(mouth * (if i == 1 then 0.75 else 0.5), 0, 1)
		g.image.Rotation = if motion then frame * (if i == 1 then 0.5 else -0.35) else 0
	end
	self.mouthLight.Brightness = 2.4 * mouth
	for i, ray in self.rays do
		local flicker = 0.14 * math.sin(frame / 7 + i * 1.8)
		ray.Transparency = NumberSequence.new(math.clamp(1 - mouth * (0.40 + flicker), 0, 1), 1)
	end
	local arrived = frame - (F.arrive + 20)
	for _, n in self.needles do
		local on = S.ease(arrived - n.far * 1.1, 0, 5)
		if frame >= F.contact2 then
			on = math.max(0, 1 - (frame - F.answer) / 20)
		end
		n.part.Transparency = 1 - math.clamp(on * fade * (0.8 + 0.2 * breath), 0, 1)
	end
end

function Path:hide()
	self.model.Parent = nil
end

function Path:Destroy()
	self.model:Destroy()
end

return Path
