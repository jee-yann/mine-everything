local S = require(script.Parent.Scenery)
local Run = require(script.Parent.GalleryRun)
local Sprite = require(script.Parent.WorldSprite)
local F = require(script.Parent.ExposureSheet).frames
local V, CF = Vector3.new, CFrame.new
local Signal = {}
Signal.__index = Signal
local ageOfWake = { 0, 0.7, 1.7, 3.2, 5.3, 8.0, 11.5, 16, 22, 31 }
local full = NumberSequence.new(0)
local half = NumberSequence.new(0.47)
local function pin(part)
	local a = Instance.new("Attachment")
	a.Parent = part
	return a
end

local function stroke(a, b, name, ink, width, transparency)
	local beam = Instance.new("Beam")
	beam.Name, beam.Attachment0, beam.Attachment1 = name, a, b
	beam.Color, beam.Transparency = ColorSequence.new(Color3.fromHex(ink)), transparency
	beam.Width0, beam.Width1 = width, width
	beam.LightEmission, beam.LightInfluence, beam.Segments, beam.FaceCamera = 0.65, 0, 1, true
	beam.Enabled, beam.Parent = false, a.Parent
	return beam
end

local function orb(parent, name, color)
	local part = S.part(parent, name, CF(), Vector3.one, color, Enum.Material.Neon)
	part.Shape, part.CastShadow = Enum.PartType.Ball, false
	return part
end

local function glowTexture()
	local assets = game:GetService("AssetService")
	local width = 48
	local ok, image = pcall(assets.CreateEditableImage, assets, { Size = Vector2.new(width, width) })
	if not ok or not image then
		return nil
	end
	local pixels = buffer.create(width * width * 4)
	buffer.fill(pixels, 0, 255)
	for y = 0, width - 1 do
		for x = 0, width - 1 do
			local r = ((x + 0.5) * 2 / width - 1) ^ 2 + ((y + 0.5) * 2 / width - 1) ^ 2
			buffer.writeu8(
				pixels,
				(y * width + x) * 4 + 3,
				math.floor(255 * math.exp(-3.7 * r) * (1 - math.min(1, r)) ^ 2)
			)
		end
	end
	image:WritePixelsBuffer(Vector2.zero, image.Size, pixels)
	return image
end

function Signal.new()
	local root = S.group("Starfall beacon signal")
	local base = S.part(root, "Survey line datum", CF(), Vector3.one * 0.04, "FFFFFF")
	base.Transparency, base.CastShadow = 1, false
	local compact = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	local input = game:GetService("UserInputService")
	compact = (compact >= 1 and compact <= 3) or (input.TouchEnabled and not input.KeyboardEnabled)
	local self = setmetatable({
		root = root,
		base = base,
		compact = compact,
		waypoints = {},
		lines = {},
		trail = {},
		sparks = {},
	}, Signal)
	-- The lasting ground trace follows each sampled bend across the real bridge
	-- and the mine floor. Separate narrow white streamers ride its leading edge.
	for i = 1, 22 do
		local a = pin(base)
		self.waypoints[i] = a
		if i > 1 then
			local b = self.waypoints[i - 1]
			self.lines[i] = stroke(b, a, "Light held in the seam", "7853BF", 0.17, half)
		end
	end
	local last, lastStrand
	for i, lag in ageOfWake do
		local a = pin(base)
		local sample = { at = a, lag = lag }
		if last then
			sample.outer = stroke(last, a, "Amethyst wake", "8C52F3", 0.65, half)
			sample.outer.Texture = "rbxasset://textures/particles/smoke_main.dds"
			sample.outer.TextureSpeed, sample.outer.TextureMode = 0, Enum.TextureMode.Stretch
			sample.wire = stroke(last, a, "Ionized thread", if i <= 4 then "EBFFFF" else "9DABFF", 0.18, full)
			sample.wire.ZOffset = 0.018
		end
		if not compact and i <= 7 then
			sample.strand = pin(base)
			if lastStrand then
				sample.hair = stroke(lastStrand, sample.strand, "Forked electric filament", "B5A2FF", 0.044, full)
			end
			lastStrand = sample.strand
		end
		self.trail[i] = sample
		last = a
	end
	self.heart = orb(root, "White-hot mineral seed", "E1FFFF")
	self.heartLight = S.light(self.heart, "9BB5FF", 9, 2.2)
	self.heartLight.Shadows = false
	self.mantle = orb(root, "Violet sheath", "AA70FF")
	self.mantle.Transparency = 0.53
	local stock = "rbxasset://textures/particles/sparkles_main.dds"
	self.aura = Sprite.new(base, "Mineral fluorescence", stock, 0)
	self.struck = Sprite.new(base, "Bloom over the struck facet", stock, 0)
	self.texture = if compact then nil else glowTexture()
	if self.texture then
		local content = Content.fromObject(self.texture)
		self.aura.image.ImageContent, self.struck.image.ImageContent = content, content
	end
	for i = 1, if compact then 8 else 12 do
		local a, b = pin(base), pin(base)
		local theta = 2 * math.pi * (i - 1) / (if compact then 8 else 12) + 0.17 * math.sin(i * 4.1)
		self.sparks[i] = {
			a = a,
			b = b,
			dir = V(math.cos(theta), math.sin(theta), 0.08 + 0.23 * (i % 3)),
			ray = stroke(
				a,
				b,
				"Splitting crystal light",
				if i % 3 == 0 then "D4ABFF" elseif i % 2 == 0 then "FFDBAA" else "E2FCFF",
				0.05,
				full
			),
		}
	end
	return self
end

function Signal:place(marker, actor)
	local origin = Run.origin(actor)
	self.world, self.unit = CF(origin), actor.unit
	self.face = marker.site.Rotation
	local u = actor.unit
	local points, times = {}, {}
	local function add(f, p)
		table.insert(times, f)
		table.insert(points, p)
	end
	add(0, marker.core.WorldPosition - origin)
	add(2, marker.site * V(-0.24 * u, -1.69 * u, 0.43 * u) - origin)
	for i, vane in marker.runnels do
		add(4 + 3 * (i - 1), vane.at.WorldPosition - origin + V(0, 0.13 * u, 0))
	end
	-- Fixed-picture landmarks begin after the final vane. Heights are the
	-- native bridge planks, threshold, dig floor and exposed wall of the shaft.
	self.relative = #points
	add(F.mineRun - 15, V(0.44, 1.55, 25.9))
	add(F.mineRun - 8, V(-0.37, 1.87, 12.9))
	add(F.mineRun, V(0.14, 1.29, -0.42))
	add(F.mineRun + 5, V(-0.88, 1.12, -11.8))
	add(F.mineRun + 12, V(-3.60, 1.15, -22.76))
	add(F.mineRun + 18, V(-5.77, 0.82, -32.38))
	-- Round the corner of the collar and follow the far cut face. It is
	-- visible down the lens in both landscape and a tall portrait crop.
	add(F.lode - 14, Run.shaft * V(2.98, 0.04, 22.41))
	add(F.lode - 12, Run.shaft * V(1.72, 2.85, 22.47))
	add(F.lode - 9, Run.shaft * V(0.83, 2.82, 22.51))
	add(F.lode - 5, Run.shaft * V(0.25, 2.46, 20.05))
	self.lip = #points
	add(F.lode, Run.shaft * V(0.30, 2.88, 16.11))
	add(F.lode + 5, Run.shaft * V(0.77, 3.96, 10.72))
	add(F.lode + 10, Run.shaft * V(1.21, 2.73, 3.15))
	add(F.lode + 16, Run.shaft * V(0.96, 0.55, -0.97))
	self.points, self.times = points, times
	for i, v in points do
		self.waypoints[i].Position = v
	end
end

function Signal:time(i, contact)
	return self.times[i] + (if i <= self.relative then contact else 0)
end

function Signal:sample(f, contact)
	local p = self.points
	if f <= contact then
		return p[1]
	end
	for i = 2, #p do
		local right = self:time(i, contact)
		if f <= right then
			local left = self:time(i - 1, contact)
			local t = math.clamp((f - left) / (right - left), 0, 1)
			return p[i - 1]:Lerp(p[i], t)
		end
	end
	return p[#p]
end

function Signal:basis(frame)
	return if frame >= F.lode and self.chamber then self.chamber * Run.shaft:Inverse() else self.world
end

function Signal:draw(stage, frame, contact, motion)
	local age = frame - contact
	if age < 0 or frame >= F.lode + 22 then
		self:hide()
		return nil
	end
	local basis, u = self:basis(frame), self.unit
	self.base.CFrame = basis
	self.root.Parent = stage
	local ageAtLip = frame - (F.lode - 5)
	local atLip = ageAtLip >= 0
	local finish = 1 - S.ease(frame, F.lode + 13, F.lode + 22)
	local point = self:sample(frame, contact)
	local hit = if atLip then ageAtLip else age
	local strike = if motion then (1 - S.ease(hit, 1, 8)) else 0
	local direction = point - self:sample(frame - 0.45, contact)
	if direction.Magnitude < 0.015 then
		direction = if age < 3 then self.face.ZVector else V(0, -1, 0)
	end
	direction = direction.Unit
	local up = if math.abs(direction.Y) > 0.9 then Vector3.zAxis else Vector3.yAxis
	local head = basis * CFrame.lookAt(point, point + direction, up)
	local radius = if age <= 3 then 0.25 * u elseif atLip then 0.22 else 0.37
	local wide = (radius + strike * 0.18) * (if motion then 1 else 0.72) * finish
	self.heart.CFrame, self.mantle.CFrame = head, head
	self.heart.Size = V(0.74, 0.79, 2.05) * math.max(0.015, wide)
	self.mantle.Size = V(1.71, 1.53, 2.87) * math.max(0.015, wide)
	self.heart.Transparency = if motion then 1 - finish else 1
	self.mantle.Transparency = if motion then 0.53 + 0.47 * (1 - finish) else 1
	self.heartLight.Enabled = motion and not self.compact and finish > 0.01
	self.heartLight.Brightness = (1.8 + 2.9 * strike) * finish
	local diameter = if atLip then 2.4 else 3.1
	Sprite.draw(
		self.aura,
		point,
		diameter * finish,
		diameter * finish,
		0,
		Color3.fromHex("A882FF"),
		if motion then 0.39 + 0.43 * (1 - finish) else 1
	)
	local contactHeat = (1 - S.ease(age, 2, if motion then 15 else 21)) * (if motion then 1 else S.ease(age, 0, 5))
	local contactSize = (1.63 + 0.43 * (1 - contactHeat)) * u
	Sprite.draw(
		self.struck,
		self.points[1] + self.face.ZVector * 0.09 * u,
		contactSize,
		contactSize,
		0,
		Color3.fromHex("CAA5FF"),
		1 - 0.73 * contactHeat
	)
	for i = 2, #self.points do
		local wire = self.lines[i]
		local entered = self:time(i, contact)
		local life = S.ease(frame, entered - 1, entered + 4) * (1 - S.ease(frame - entered, 24, 47)) * finish
		wire.Enabled = life > 0.015
		if wire.Enabled then
			wire.Width0, wire.Width1 = 0.17 * life, 0.16 * life
			wire.Transparency = if motion then half else full
		end
	end
	for i, tail in self.trail do
		tail.at.Position = self:sample(frame - tail.lag, contact)
		if tail.strand then
			local phase = frame * 0.51 - tail.lag * 0.87
			local amp = 0.36 * S.ease(tail.lag, 0, 3) * (1 - S.ease(tail.lag, 7, 15))
			tail.strand.Position = tail.at.Position
				+ V(math.sin(phase), 0.30 + 0.66 * math.cos(phase), 0.23 * math.cos(phase)) * amp
		end
		if tail.outer then
			local strength = (1 - (i - 1) / #self.trail) * finish
			local active = motion and age > self.trail[i - 1].lag and strength > 0.005
			tail.outer.Enabled, tail.wire.Enabled = active, active
			if tail.hair then
				tail.hair.Enabled = active
			end
			if active then
				local width = (if ageAtLip > -1 then 0.59 else 0.93) * strength
				tail.outer.Width0, tail.outer.Width1 = width, width * 0.86
				tail.wire.Width0, tail.wire.Width1 = width * 0.19, width * 0.14
				if tail.hair then
					tail.hair.Width0, tail.hair.Width1 = width * 0.10, width * 0.054
				end
			end
		end
	end
	local center = if atLip then self.points[self.lip] else self.points[1]
	local orientation = if atLip then Run.shaft.Rotation * CFrame.Angles(math.rad(67), 0, 0) else self.face
	for i, spark in self.sparks do
		local active = motion and hit >= 0 and hit < 8
		spark.ray.Enabled = active
		if active then
			local dir = orientation:VectorToWorldSpace(spark.dir)
			local length = (if i % 3 == 1 then 0.94 else 0.52 + (i % 4) * 0.08) * u
			local inner = (0.12 + 0.10 * hit) * u
			spark.a.Position = center + dir * inner
			spark.b.Position = center + dir * (inner + length * strike)
			spark.ray.Width0, spark.ray.Width1 = (if i % 3 == 1 then 0.096 else 0.061) * strike * u, 0
		end
	end
	return head.Position
end

function Signal:hide()
	self.root.Parent = nil
end

function Signal:Destroy()
	self.root:Destroy()
	if self.texture then
		self.texture:Destroy()
	end
end

return Signal
