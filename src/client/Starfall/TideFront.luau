-- A pressure front follows surveyed elevations out of the quarry. Beyond the
-- intertidal shelf its tan dust lip separates into water, whitecap and wake.
local sections = require(script.Parent.CoastSections)
local SurfBurst = require(script.Parent.SurfBurst)
local clock = require(script.Parent.Timeline)
local Tide = {}
Tide.__index = Tide
local V, rgb, tau = Vector3.new, Color3.fromHex, math.pi * 2
local steps = #sections
local colors = {
	ColorSequence.new(rgb("D7B599"), rgb("F0D9AA")),
	ColorSequence.new(rgb("A59492"), rgb("D8B79F")),
	ColorSequence.new(rgb("DFFFF2"), rgb("A8E4DE")),
	ColorSequence.new(rgb("3799A5"), rgb("79CDC7")),
}
local alpha = {}
for i = 0, 16 do
	alpha[i] = NumberSequence.new(i / 16)
end
local seaWind = Color3.fromHex("52ADAC")
local sea = Color3.fromHex("3D808D")
local nearCamera = (clock.breakerEye - V(0, 26, -32)) * V(1, 0, 1)
local travelTime = clock.breaker - clock.waveLaunch
local speed = (nearCamera.Magnitude - 6 - 2 * travelTime ^ 2) / travelTime
local nearAngle = math.atan2(nearCamera.Z, nearCamera.X)
local function irregular(a)
	return 2.9 * math.sin(3 * a + 0.2) + 1.9 * math.sin(7 * a - 0.7)
end

local function radiusAt(age)
	return 6 + speed * age + 2.0 * age * age
end

function Tide.arrival(distance)
	return (-speed + math.sqrt(speed ^ 2 + 8 * math.max(0, distance - 6))) / 4
end

local function swell(parent, name, tint)
	local p = Instance.new("WedgePart")
	p.Name, p.Color, p.Material = name, tint, Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Transparency, p.Reflectance = 1, 0.055
	p.Parent = parent
	return p
end

local function elevation(section, r)
	for j = 2, #section do
		local p, q = section[j - 1], section[j]
		if r <= q[1] then
			return p[2] + (q[2] - p[2]) * math.clamp((r - p[1]) / (q[1] - p[1]), 0, 1)
		end
	end
	return 20.3
end

local function ribbon(parent, a, b, name)
	local beam = Instance.new("Beam")
	beam.Name = name
	beam.Attachment0, beam.Attachment1 = a, b
	beam.Segments, beam.FaceCamera, beam.LightInfluence = 4, true, 0.55
	beam.Parent = parent
	return beam
end

function Tide.new(stage, base)
	local root = Instance.new("Part")
	root.Name = "Passage of the pressure wave"
	root.Size = Vector3.one
	root.Transparency, root.Anchored, root.CanCollide, root.CanTouch, root.CanQuery = 1, true, false, false, false
	root.CFrame = base
	local self = setmetatable({ root = root, stage = stage, rays = {}, active = false }, Tide)
	local input = game:GetService("UserInputService")
	local quality = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	self.compact = (input.TouchEnabled and not input.KeyboardEnabled) or (quality >= 1 and quality <= 3)
	self.surf = SurfBurst.new(stage, base, sections, Tide.arrival, self.compact)
	for k = 1, steps do
		local a = (k - 1) * tau / steps
		local ray = {
			dir = V(math.cos(a), 0, math.sin(a)),
			tangent = V(-math.sin(a), 0, math.cos(a)),
			section = sections[k],
			lag = irregular(a) - irregular(nearAngle),
			joints = {},
			bands = {},
		}
		for lane = 1, 3 do
			local att = Instance.new("Attachment")
			att.Name = "Crest section"
			att.Axis = ray.tangent
			att.Parent = root
			ray.joints[lane] = att
		end
		self.rays[k] = ray
	end
	for k, ray in self.rays do
		local nextRay = self.rays[k % steps + 1]
		ray.water = {}
		for j = 1, 8 do
			ray.water[j] = swell(root, if j <= 4 then "Swell face" else "Backwash", if j <= 4 then seaWind else sea)
		end
		for lane, label in { "Leading fold", "Lifted shelf", "Broken wake" } do
			ray.bands[lane] = ribbon(root, ray.joints[lane], nextRay.joints[lane], label)
		end
	end
	return self
end

-- Two thin right prisms share each wave facet. Adjacent sectors use the
-- very same peak and toe, including where the curl divides on either side
-- of the water-level lens. There are no vertical sector-end walls.
local function facet(parts, index, a, b, c, alpha, base)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal = ac:Cross(ab).Unit
	local along = bc.Unit
	local up = along:Cross(normal)
	local h = math.max(0.035, math.abs(ab:Dot(up)))
	local left, right = parts[index], parts[index + 1]
	left.Size = V(0.035, h, math.max(0.035, math.abs(ab:Dot(along))))
	right.Size = V(0.035, h, math.max(0.035, math.abs(ac:Dot(along))))
	left.CFrame = base * CFrame.fromMatrix((a + b) * 0.5, normal, up, along)
	right.CFrame = base * CFrame.fromMatrix((a + c) * 0.5, -normal, up, -along)
	left.Transparency, right.Transparency = alpha, alpha
end

function Tide:draw(age)
	self.surf:draw(age + 5.10)
	local active = age >= 0 and age < 3.69
	if active ~= self.active then
		self.active = active
		self.root.Parent = if active then self.stage else nil
	end
	if not active then
		return
	end
	local sample = math.floor(age * (if self.compact then 30 else 60))
	if self.sample == sample then
		return
	end
	self.sample = sample
	local radius = radiusAt(age)
	local fade = math.clamp((age - 3.0) / 0.69, 0, 1)
	for k, ray in self.rays do
		local r0 = radius + ray.lag * math.min(age * 2, 1)
		local wet = math.clamp((r0 - ray.section[9][1]) / 17, 0, 1)
		local rough = math.sin(k * 2.22 + age * 2.6)
		local lift = (5.90 + 2.1 * math.sin(k * 0.53) + 1.55 * math.sin(k * 1.95 + age * 0.9)) * wet * (1 - fade)
		local floor = elevation(ray.section, r0) - 0.10
		local toe = 7.8 + wet * 2 + 2.2 * math.sin(k * 1.31)
		ray.tip = V(0, floor + lift, -32) + r0 * ray.dir
		ray.fore = V(0, floor, -32) + (r0 + toe) * ray.dir
		ray.aft = V(0, floor, -32) + (r0 - 12 - age * 2.4) * ray.dir
		ray.wet = wet
		for lane, att in ray.joints do
			local delay = if lane == 1 then 0 elseif lane == 2 then 0.8 + age * 0.34 else 12 + age * 2.6
			local r = math.max(1, r0 - delay)
			local wet = math.clamp((r - ray.section[9][1]) / 15, 0, 1)
			local height = elevation(ray.section, r)
			local curl = (0.55 + 0.40 * math.sin(k * 1.47 + age * 4)) * wet
			local liftAtBand = if lane == 3 then 0 else lift
			att.Position = V(0, height + 0.75 + curl * 0.45 + liftAtBand, -32) + ray.dir * r
			local beam = ray.bands[lane]
			local bend = r * math.tan(tau / steps / 4) * 4 / 3
			beam.CurveSize0, beam.CurveSize1 = bend, bend
			local water = wet > 0.48
			beam.Color = colors[if lane == 2 then (if water then 4 else 2) else (if water then 3 else 1)]
			local breadth = if lane == 1
				then 0.95 + wet * (1.8 + rough * 0.6)
				elseif lane == 2 then 2.0 + wet * (2.1 + rough * 0.65) + age * 0.29
				else 0.9 + wet * 1.4
			beam.Width0, beam.Width1 = breadth * (0.83 + 0.16 * math.sin(0.92 * k + age)), breadth
			local opacity = if lane == 1 then 0.79 elseif lane == 2 then 0.48 else 0.53
			opacity *= if water
				then 0.78 + 0.22 * math.sin(k * 0.67 + age * 2.35)
				else 0.49 + 0.38 * math.sin(k * 0.79 + age * 1.37)
			opacity *= 1 - fade
			if lane == 3 then
				opacity = (1 - fade)
					* (0.24 + 0.34 * wet)
					* math.clamp((age - 0.2) * 3, 0, 1)
					* math.clamp(0.45 + 0.8 * math.sin(k * 0.91 - age * 2), 0, 1)
			end
			beam.Transparency = alpha[math.clamp(math.round((1 - opacity) * 16), 0, 16)]
		end
	end
	for k, ray in self.rays do
		local b = self.rays[k % steps + 1]
		if math.min(ray.wet, b.wet) > 0.02 and fade < 0.99 then
			local opacity = 0.54 * (1 - fade) * math.min(ray.wet, b.wet)
			local trans = 1 - opacity
			facet(ray.water, 1, ray.tip, b.tip, ray.fore, trans, self.root.CFrame)
			facet(ray.water, 3, b.tip, b.fore, ray.fore, trans, self.root.CFrame)
			facet(ray.water, 5, ray.aft, b.aft, ray.tip, trans + 0.025 * opacity, self.root.CFrame)
			facet(ray.water, 7, b.aft, b.tip, ray.tip, trans + 0.025 * opacity, self.root.CFrame)
		else
			for _, p in ray.water do
				p.Transparency = 1
			end
		end
	end
end

function Tide:Destroy()
	self.surf:Destroy()
	self.root:Destroy()
end
return Tide
