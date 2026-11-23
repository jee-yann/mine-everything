-- The land and the water have different responses to the same pressure front.
-- Soundings taken on the private ancient set include its cliffs and sea stacks.
local P = require(script.Parent.Props)
local Land = require(script.Parent.HistoryLandform)
local V, CF, rgb, ease = Vector3.new, CFrame.new, Color3.fromHex, P.ease
local Wave = {}
Wave.__index = Wave
local count, spacing = 48, 9
local dust, foam = rgb("EBB888"), rgb("DFFFF6")

local function edge(root, a, b, name, width)
	local beam = Instance.new("Beam")
	beam.Name, beam.Attachment0, beam.Attachment1 = name, a, b
	beam.FaceCamera, beam.Segments = true, 3
	beam.LightInfluence, beam.LightEmission = 0.12, 0.45
	beam.Width0, beam.Width1, beam.Enabled = width, width, false
	beam.Parent = root
	return beam
end

local function height(ray, radius)
	local index = math.max(0, radius / spacing)
	local i = math.floor(index) + 1
	local a, b = ray.heights[i] or -3.55, ray.heights[i + 1] or -3.55
	return a + (b - a) * (index % 1)
end

local function scrub(parent, ray, reach, index)
	local tree = P.model(parent, "Windward scrub")
	local tall = 7 + index % 4
	local fork = V(0.7, tall * 0.65, 0)
	P.rod(tree, "Stem", Vector3.zero, fork, 0.86, rgb("705A4F"))
	for i = 1, 5 do
		local a = i * 2.4 + index
		local side = V(math.cos(a), 0, math.sin(a))
		local tip = fork + side * (2.6 + i % 3) + V(0, 1 + i % 2, 0)
		local crown = P.sphere(tree, "Saltbush", tip, V(5.3, 3.1, 4.1), if i % 2 == 0 then "70805C" else "526956")
		crown.CFrame *= CFrame.Angles(0, a, 0.24)
	end
	tree.WorldPivot = CFrame.identity
	ray.tree, ray.reach = tree, reach
end

function Wave.new(root, coast)
	local model = P.model(root, "Passing pressure")
	local anchor = P.box(model, "Wave origin", Vector3.zero, Vector3.one, "FFFFFF")
	anchor.Transparency = 1
	local rays = {}
	for i = 1, count do
		local a = i * math.pi * 2 / count
		local dir = V(math.cos(a), 0, math.sin(a))
		local shore = Land.shoreAt(a)
		local ray =
			{ dir = dir, shore = shore, heights = {}, phase = math.sin(a * 3 + 0.8) * 3.5 + math.cos(a * 7) * 1.8 }
		for _, key in { "lip", "wake", "trough", "backwash" } do
			ray[key] = Instance.new("Attachment", anchor)
			ray[key].Axis = V(-dir.Z, 0, dir.X)
		end
		if i % 3 == 0 and shore > 90 then
			ray.reach = math.max(69, shore * (0.56 + 0.20 * math.sin(i) ^ 2))
		end
		local plume = P.box(model, "Displaced surface", Vector3.zero, Vector3.one, "FFFFFF")
		plume.Transparency = 1
		local gui = Instance.new("BillboardGui")
		gui.LightInfluence, gui.Enabled, gui.Parent = 0.18, false, plume
		local brush = Instance.new("ImageLabel")
		brush.BackgroundTransparency, brush.Size = 1, UDim2.fromScale(1, 1)
		brush.Image = "rbxasset://textures/particles/smoke_main.dds"
		brush.Rotation, brush.Parent = i * 31, gui
		ray.plume, ray.gui, ray.brush = plume, gui, brush
		rays[i] = ray
	end
	for i, ray in rays do
		local nextRay = rays[i % count + 1]
		ray.front = edge(anchor, ray.lip, nextRay.lip, "Condensation edge", 3.8)
		ray.comb = edge(anchor, ray.wake, nextRay.wake, "Broken wash", 3)
		-- A ribbon lying on the sea joins the dark trough to the aerated wake.
		-- Its width grows with the arc length represented by this sounding.
		ray.water = edge(anchor, ray.backwash, ray.trough, "Aerated seawater", 1)
		ray.water.FaceCamera, ray.water.LightEmission = false, 0.23
		ray.water.Color = ColorSequence.new(rgb("76ACA5"), rgb("96DEDF"))
		ray.water.Transparency = NumberSequence.new(0.99, 0.24)
		ray.spindrift = edge(anchor, ray.lip, nextRay.lip, "Pressure vapor", 14)
		ray.spindrift.Texture = "rbxasset://textures/particles/smoke_main.dds"
		ray.spindrift.TextureMode = Enum.TextureMode.Stretch
		ray.comb.Color = ColorSequence.new(rgb("A0CCD1"), rgb("EFF5DC"))
		ray.comb.Transparency = NumberSequence.new(0.25, 0.93)
	end
	local probe = RaycastParams.new()
	probe.FilterType, probe.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { coast }
	local soundings = {}
	for _, part in coast:GetDescendants() do
		if part:IsA("BasePart") and not part.CanQuery then
			part.CanQuery = true
			table.insert(soundings, part)
		end
	end
	return setmetatable({ rays = rays, anchor = anchor, probe = probe, soundings = soundings, nextRay = 1 }, Wave)
end

function Wave:prepare(base, finish)
	if self.nextRay > count then
		return
	end
	self.anchor.CFrame = base
	for i = self.nextRay, if finish then count else math.min(count, self.nextRay + 2) do
		local ray = self.rays[i]
		for j = 0, math.ceil((ray.shore + 52) / spacing) do
			local at = ray.dir * j * spacing
			local hit = workspace:Raycast(base * (at + V(0, 230, 0)), V(0, -250, 0), self.probe)
			ray.heights[j + 1] = if hit then base:PointToObjectSpace(hit.Position).Y else -3.55
		end
		if ray.reach then
			-- Probe the actual footing. Interpolating two cliff heights can
			-- put vegetation halfway up a vertical face or inside the crater.
			local point = ray.dir * ray.reach
			local ground = workspace:Raycast(base * (point + V(0, 230, 0)), V(0, -250, 0), self.probe)
			if ground and ground.Normal.Y > 0.72 and ground.Position.Y > base.Position.Y then
				scrub(self.anchor.Parent, ray, ray.reach, i)
				ray.foot = CF(ground.Position)
				ray.tree:PivotTo(ray.foot)
			end
		end
		self.nextRay = i + 1
	end
	if self.nextRay > count then
		for _, part in self.soundings do
			part.CanQuery = false
		end
		table.clear(self.soundings)
	end
end

function Wave:draw(age, base)
	self:prepare(base, age >= 0)
	if age < 0.32 or self.finished then
		return
	end
	local radius = 8 + 142 * (age - 0.32)
	self.radius = radius
	for i, ray in self.rays do
		local r = radius + ray.phase
		local water = ease(r, ray.shore - 2, ray.shore + 15)
		local y = height(ray, r) + (1 - water) * 5 + 2.8
		local dir = ray.dir
		local wake = r - 9 - math.sin(i * 0.65) ^ 2 * 12
		ray.lip.Position = dir * r + V(0, y, 0)
		ray.wake.Position = dir * wake + V(0, height(ray, wake) + 1.8, 0)
		local fade = ease(age, 2.64, 2.89)
		local fadeIn = ease(age, 0.32, 0.52)
		local energy = fadeIn * (1 - fade)
		local tangent = V(-dir.Z, 0, dir.X)
		local outside = math.max(ray.shore + 5, r - 5)
		local inside = math.max(ray.shore + 4, r - 48 - 12 * math.cos(i))
		local wash = ray.water
		wash.Enabled = energy > 0 and outside > inside + 1
		if wash.Enabled then
			ray.trough.CFrame = CFrame.fromMatrix(dir * outside + V(0, -3.23, 0), dir, tangent)
			ray.backwash.CFrame = CFrame.fromMatrix(dir * inside + V(0, -3.25, 0), dir, tangent)
			wash.Width0, wash.Width1 = inside * 0.129, outside * 0.135
			wash.Transparency = NumberSequence.new(1, 1 - 0.65 * energy)
		end
		local gallop = 0.5 + 0.5 * math.sin(i * 2.12 + r * 0.047)
		ray.front.Enabled = energy > 0 and (water > 0.05 or i % 4 ~= 0)
		ray.front.Color = ColorSequence.new(dust:Lerp(foam, water))
		local strength = energy * (0.22 + 0.57 * water) * (0.72 + 0.28 * gallop)
		ray.front.Transparency = NumberSequence.new(1 - strength, 1 - strength * 0.65)
		ray.front.Width0, ray.front.Width1 = 1.4 + 2.4 * water + gallop, 0.5 + 1.3 * water
		ray.front.CurveSize0, ray.front.CurveSize1 = r * 0.044, r * 0.044
		local mist = ray.spindrift
		mist.Enabled = energy > 0
		mist.Width0, mist.Width1 = 12 + 17 * gallop, 19 + 12 * water
		mist.Color = ColorSequence.new(dust:Lerp(foam, water))
		mist.Transparency = NumberSequence.new(1 - energy * 0.74, 1 - energy * 0.48)
		ray.comb.Enabled = water > 0.3 and i % 5 ~= 0 and fade < 1
		ray.comb.Width0, ray.comb.Width1 = 4 * (1 - fade), 0.35
		local beach = i % 3 ~= 1
		local source = if beach then ray.shore + 3 else ray.shore * 0.65
		local passed = (r - source) / 140
		ray.gui.Enabled = passed >= 0 and passed < 1.33
		if ray.gui.Enabled then
			local u = passed / 1.33
			local swell = 1 - (1 - u) ^ 2
			ray.plume.Position = base
				* (dir * (source + 34 * swell) + V(0, height(ray, source) + 3 + 17 * math.sin(u * math.pi * 0.8), 0))
			local span = 10 + 29 * swell
			ray.gui.Size = UDim2.fromScale(span * (1 + u), span * (if beach then 1.15 else 0.72))
			ray.brush.ImageColor3 = if beach then foam else dust
			ray.brush.ImageTransparency = 1 - 0.92 * ease(u, 0, 0.10) * (1 - ease(u, 0.35, 1))
		end
		if ray.tree then
			local s = (r - ray.reach) / 130
			if s > 0 and s < 1.5 then
				local bend = (1 - math.exp(-22 * s)) * (0.67 + 0.40 * math.sin(10 * s) * math.exp(-3 * s))
				ray.tree:PivotTo(ray.foot * CFrame.fromAxisAngle(V(dir.Z, 0, -dir.X), bend))
			end
		end
	end
	self.finished = age >= 2.9
end

return Wave
