-- Surf strikes the clefts in the near reef and breaks again offshore. Each
-- crest peels laterally, carrying its spray forward into falling droplets.
local S = require(script.Parent.Scenery)
local clock = require(script.Parent.Timeline)
local Surf = {}
Surf.__index = Surf
local V, CF = Vector3.new, CFrame.new
local aqua, light = Color3.fromHex("7ACBCB"), Color3.fromHex("D2F1DA")
local opacity = {}
for j = 0, 20 do
	opacity[j] = NumberSequence.new(j / 20)
end

local function jet(root, salt)
	local lo, hi = Instance.new("Attachment"), Instance.new("Attachment")
	lo.Parent, hi.Parent = root, root
	local stream = Instance.new("Beam")
	stream.Name = "Curl of thrown water"
	stream.Attachment0, stream.Attachment1, stream.FaceCamera, stream.Segments = lo, hi, true, 6
	stream.Color, stream.LightInfluence = ColorSequence.new(aqua, light), 0.55
	stream.Texture, stream.TextureMode, stream.TextureSpeed =
		"rbxasset://textures/particles/smoke_main.dds", Enum.TextureMode.Stretch, 0
	stream.Enabled, stream.Parent = false, root
	local spray =
		S.part(root, "Glittering spray", CF(), Vector3.one, "DBECDD", Enum.Material.SmoothPlastic, "WedgePart")
	spray.CastShadow, spray.Transparency = false, 1
	return { lo = lo, hi = hi, ribbon = stream, spray = spray, salt = salt }
end

function Surf.new(stage, base, sections, arrival, compact)
	local root = S.part(nil, "Coastline breakers", base, Vector3.one, "FFFFFF")
	root.Transparency, root.CastShadow = 1, false
	local fans = {}
	local rng = Random.new(51509)
	local function fan(index, radius, delay, size, near)
		local theta = (index - 1) / #sections * math.pi * 2
		local dir = V(math.cos(theta), 0, math.sin(theta))
		local side = V(-dir.Z, 0, dir.X)
		local fan = {
			center = V(0, 20.48, -32) + dir * radius,
			dir = dir,
			across = side,
			date = 5.10 + arrival(radius) + delay,
			scale = size,
			stems = {},
			near = near,
			active = false,
		}
		local socket = Instance.new("Attachment", root)
		local mist = Instance.new("BillboardGui", socket)
		mist.Name, mist.LightInfluence, mist.Enabled = "Sea spindrift", 0.66, false
		local fleck = Instance.new("ImageLabel")
		fleck.Size, fleck.BackgroundTransparency, fleck.Image =
			UDim2.fromScale(1, 1), 1, "rbxasset://textures/particles/smoke_main.dds"
		fleck.ImageColor3, fleck.Rotation, fleck.Parent = Color3.fromHex("BFDFD8"), index * 43 % 360, mist
		fan.socket, fan.mist, fan.fleck = socket, mist, fleck
		for j = 1, if compact then 3 else 5 do
			local stem = jet(root, j)
			stem.lateral = (j - (if compact then 2 else 3)) * 1.65 * size
			stem.delay = (j - 1) * 0.038 + rng:NextNumber(0, 0.08)
			stem.height = rng:NextNumber(6.2, 13.2) * size
			stem.travel = rng:NextNumber(11, 23) * size
			stem.life = rng:NextNumber(0.62, 1.02)
			stem.roll = rng:NextNumber(-0.7, 0.7)
			fan.stems[j] = stem
		end
		fans[#fans + 1] = fan
	end
	for i, row in sections do
		if i % 3 == 0 or i >= 2 and i <= 9 then
			fan(i, row[10][1] + rng:NextNumber(2, 8), rng:NextNumber(-0.08, 0.07), rng:NextNumber(0.60, 1.14), false)
		end
	end
	-- The observer sits high above the water. Spray remains
	-- physically rooted beneath the lens, while the pressure passes above it.
	local horizontal = (clock.breakerEye - V(0, 26, -32)) * V(1, 0, 1)
	local radial = horizontal.Magnitude
	local bearing = 1 + math.atan2(horizontal.Z, horizontal.X) * #sections / (2 * math.pi)
	for _, m in
		{
			{ 2.58, -7, 0.96 },
			{ 3.32, 6, 1.20 },
			{ 4.48, 0, 1.48 },
			{ 5.19, -2, 1.28 },
			{ 6.22, 11, 1.04 },
			{
				7.15,
				2,
				0.90,
			},
		}
	do
		fan(bearing + m[1] - 4.48, radial + m[2], -0.09, m[3], true)
	end
	return setmetatable({ root = root, stage = stage, base = base, fans = fans, compact = compact }, Surf)
end

function Surf:draw(t)
	local visible = t >= 5.30 and t < 9.02
	if visible ~= (self.root.Parent ~= nil) then
		self.root.Parent = if visible then self.stage else nil
	end
	if not visible then
		return
	end
	local tick = math.floor(t * (if self.compact then 30 else 48))
	if tick == self.tick then
		return
	end
	self.tick = tick
	for _, f in self.fans do
		local age = t - f.date
		local active = age >= 0 and age < 1.4
		if active or f.active then
			f.mist.Enabled = active
			if active then
				local u = math.clamp(age / 1.4, 0, 1)
				local s = f.scale * (0.30 + 0.70 * S.ease(u, 0, 0.21)) * (1 + 0.76 * u)
				f.socket.Position = f.center
					+ f.dir * (f.scale * 15 * u)
					+ V(0, f.scale * (3.0 + 3.1 * math.sin(math.pi * u)), 0)
				f.mist.Size = UDim2.fromScale(18.0 * s, 11.5 * s)
				f.fleck.ImageTransparency = 0.29 + 0.71 * S.ease(u, 0.29, 1)
			end
			for _, s in f.stems do
				local u = (age - s.delay) / s.life
				local draw = u > 0 and u < 1
				s.ribbon.Enabled = draw and u < 0.86
				if draw then
					local born = f.center + f.across * s.lateral
					local foot = born + f.dir * (s.travel * 0.39 * u) + f.across * (s.roll * u)
					local peak = born
						+ f.dir * (s.travel * u)
						+ f.across * (s.lateral * 0.67 * u)
						+ V(0, 4 * s.height * u * (1 - u), 0)
					s.lo.Position, s.hi.Position = foot, peak
					s.lo.Axis = (Vector3.yAxis + f.dir * 0.10).Unit
					s.hi.Axis = (f.dir + V(0, -0.16 - 0.70 * u, 0)).Unit
					s.ribbon.CurveSize0, s.ribbon.CurveSize1 = s.height * (0.4 + 0.7 * u), s.travel * (0.12 + 0.15 * u)
					s.ribbon.Width0, s.ribbon.Width1 =
						f.scale * (2.4 + 1.32 * u) * (1 - 0.47 * u), (0.32 + 0.76 * (1 - u)) * f.scale
					s.ribbon.Transparency = opacity[math.clamp(math.floor((0.12 + 0.84 * u * u) * 20 + 0.5), 0, 20)]
					local speed = f.dir * s.travel + V(0, 4 * s.height * (1 - 2 * u), 0) + f.across * s.lateral * 0.67
					s.spray.Size = V(0.18, 0.16, 1.7 + 1.88 * (1 - u)) * f.scale
					s.spray.CFrame = self.base * CFrame.lookAt(peak, peak + speed) * CFrame.Angles(0, 0, s.roll)
					s.spray.Transparency = 0.11 + 0.65 * u * u
				else
					s.spray.Transparency = 1
				end
			end
		end
		f.active = active
	end
end
function Surf:Destroy()
	self.root:Destroy()
end
return Surf
