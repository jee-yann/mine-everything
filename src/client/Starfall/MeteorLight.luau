local Input = game:GetService("UserInputService")
local S = require(script.Parent.Scenery)
local clock = require(script.Parent.Timeline)
local sheet = require(script.Parent.ExposureSheet)
local terminal = require(script.Parent.TerminalLight)
local V, CF, hex = Vector3.new, CFrame.new, Color3.fromHex
local MeteorLight = {}
MeteorLight.__index = MeteorLight

local sea = 20.30
local rim = {
	V(-54, 45, -26),
	V(-8, 31, -36),
	V(39, 37, 16),
	V(79, 32, 64),
	V(0, 31, 95),
	V(-83, 35, 49),
	V(-24, 34, 39),
}
local amber, tungsten, coal = hex("FF9D56"), hex("FFF1D1"), hex("EF794B")

-- These receivers belong to the private reconstruction. The distant water
-- reflects cool sky while the shallow shelf takes more of the orange airlight.
local waterTint = {
	["Deep water"] = { hex("A58787"), 0.32 },
	["Shelf water"] = { hex("E3A27F"), 0.54 },
	["Tidal flats"] = { hex("F0B698"), 0.51 },
	["Wind lane"] = { hex("FFE4B1"), 0.78 },
}
-- Moonlit water has a matte blue body. Its narrow specular ridges are
-- photographed separately, avoiding tile-wide highlights on the flat ocean.
local nightWater = {
	["Deep water"] = hex("122C44"),
	["Shelf water"] = hex("19374A"),
	["Tidal flats"] = hex("204650"),
	["Wind lane"] = hex("36596C"),
}
local function waterReceivers(island)
	local list = {}
	for _, parcel in island:GetChildren() do
		if not parcel.Name:match("_Open sea$") then
			continue
		end
		for _, tile in parcel:GetChildren() do
			local tint = waterTint[tile.Name]
			if tint then
				table.insert(list, {
					part = tile,
					base = tile.Color,
					night = nightWater[tile.Name],
					tint = tint,
					material = tile.Material,
					reflectance = tile.Reflectance,
				})
			end
		end
	end
	return list
end

-- Sun glitter is broken into short, curved ridges by cross-waves. Paint the
-- reflection once, then project it onto the water below the world geometry.
local function rippleImage()
	local asset = game:GetService("AssetService")
	local w, h = 128, 256
	local ok, img = pcall(asset.CreateEditableImage, asset, { Size = Vector2.new(w, h) })
	if not ok or not img then
		return nil
	end
	local pixels = buffer.create(w * h * 4)
	for y = 0, h - 1 do
		local v = (y + 0.5) / h
		local taper = math.sin(v * math.pi) ^ 0.73
		for x = 0, w - 1 do
			local u = 2 * (x + 0.5) / w - 1
			local centre = 0.11 * math.sin(23 * v) + 0.034 * math.sin(79 * v)
			local edge = math.exp(-4.6 * ((u - centre) / (0.58 + 0.42 * taper)) ^ 2)
			local chop = math.clamp(0.34 + 2.3 * math.noise(7 * u, 43 * v, 0.74), 0, 1)
			local ripple = math.sin(296 * v + 2.8 * math.sin(9 * u + 8 * v) + 2.1 * math.sin(41 * v - 5 * u))
			local ridge = math.max(0, ripple) ^ 3
			local shine = math.clamp(edge * taper * (0.13 + 0.87 * ridge * chop), 0, 1)
			local at = 4 * (y * w + x)
			buffer.writeu8(pixels, at, 255)
			buffer.writeu8(pixels, at + 1, 138 + math.floor(108 * ridge))
			buffer.writeu8(pixels, at + 2, 65 + math.floor(122 * ridge))
			buffer.writeu8(pixels, at + 3, math.floor(250 * shine))
		end
	end
	local painted = pcall(img.WritePixelsBuffer, img, Vector2.zero, Vector2.new(w, h), pixels)
	if not painted then
		img:Destroy()
		return nil
	end
	return img
end

local function anchor(parent, name)
	local part = S.part(parent, name, CF(), Vector3.one * 0.1, "FFFFFF")
	part.Transparency, part.CastShadow = 1, false
	return part
end

function MeteorLight.new(stage, base, island)
	local low = Input.TouchEnabled and not Input.KeyboardEnabled
	local ok, quality = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	low = low or (ok and quality > 0 and quality < 5)
	local root = S.group("Light falling across the headland")
	local footprint = anchor(root, "Reflected sky on the strait")
	local surface = Instance.new("SurfaceGui")
	surface.Face, surface.LightInfluence, surface.Brightness = Enum.NormalId.Front, 0, 1.55
	surface.SizingMode, surface.CanvasSize, surface.Parent =
		Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(256, 512), footprint
	local wash = Instance.new("ImageLabel")
	wash.BackgroundTransparency, wash.Size, wash.Parent = 1, UDim2.fromScale(1, 1), surface
	local painted = rippleImage()
	local assigned = painted and pcall(function()
		wash.ImageContent = Content.fromObject(painted)
	end)
	if not assigned then
		if painted then
			painted:Destroy()
			painted = nil
		end
		wash.Image = "rbxasset://textures/particles/smoke_main.dds"
		wash.ImageColor3 = hex("FFB879")
	end
	local lamp = anchor(root, "Luminous body")
	local key = S.light(lamp, "FFE7BD", 60, 0)
	key.Shadows = true
	local pools = {}
	for i, shore in rim do
		if not low or i <= 4 then
			local mount = anchor(root, "Raking light")
			local spot = Instance.new("SpotLight")
			spot.Face, spot.Angle, spot.Range = Enum.NormalId.Front, 122, 60
			spot.Shadows, spot.Brightness, spot.Parent = i <= (if low then 1 else 3), 0, mount
			table.insert(pools, { shore = shore, mount = mount, light = spot })
		end
	end
	local rng, waves = Random.new(41422), {}
	for i = 1, (if low then 32 else 66) do
		local drift = rng:NextNumber(-1, 1)
		local streak = S.part(root, "Light on a wave face", CF(), Vector3.one, "FFCD83", Enum.Material.Neon)
		streak.CastShadow, streak.Transparency = false, 1
		streak.Shape = Enum.PartType.Ball
		waves[i] = {
			part = streak,
			reach = rng:NextNumber(0.01, 0.98),
			offset = drift * math.abs(drift),
			length = rng:NextNumber(2, 15),
			width = rng:NextNumber(0.15, 0.88),
			phase = rng:NextNumber(0, 6.28),
		}
	end
	return setmetatable({
		stage = stage,
		base = base,
		root = root,
		lamp = lamp,
		key = key,
		pools = pools,
		waves = waves,
		footprint = footprint,
		wash = wash,
		image = painted,
		receivers = waterReceivers(island),
		waterLevel = 0,
	}, MeteorLight)
end

-- A distant source would exceed the range of one Roblox light. Project its
-- angle onto the surveyed terraces so the light grazes their actual surfaces.
function MeteorLight:draw(t, star, camera, motion, masterFrame)
	local frame = masterFrame or math.floor(sheet.frameForScene(t) + 0.5)
	local nightSea = frame < 570
	if nightSea ~= self.nightSea then
		self.nightSea = nightSea
		for _, water in self.receivers do
			water.part.Material = if nightSea then Enum.Material.Neon else water.material
			water.part.Reflectance = if nightSea then 0 else water.reflectance
			water.part.Color = if nightSea then water.night else water.base
		end
	end
	local before = frame < sheet.frames.contact
	local approach, arrivalColor = terminal(frame)
	local active = frame >= sheet.frames.terminal and t < 12.86
	self.root.Parent = if active then self.stage else nil
	local contact = if frame == sheet.frames.contact then 0.22 elseif frame < sheet.frames.ignition then 0.035 else 1
	local sky = (if before then approach * 0.16 else contact * (1 - S.ease(t, 4.77, 6.23)))
		* (if motion then 1 else 0.56)
	local level = math.floor(sky * 40 + 0.5)
	if self.waterLevel ~= level or (before and approach > 0) then
		self.waterLevel = level
		for _, w in self.receivers do
			w.part.Color = (if nightSea then w.night else w.base):Lerp(
				if before then arrivalColor else w.tint[1],
				level / 40 * w.tint[2]
			)
		end
	end
	if not active then
		return
	end
	local descent = if before then approach else contact
	local burning = 1 - S.ease(t, clock.contact, 7.95)
	local glow = descent * (0.19 + 0.81 * burning) * (1 - S.ease(t, 9.14, 12.86))
	local source = star
	if t >= clock.contact then
		source += V(-5, 8 + 62 * S.ease(t, clock.contact, 5.65), -3)
	end
	local adapted = if motion then 1 else 0.55
	local skyKey = 1 - S.ease(t, clock.contact, clock.contact + 0.68)
	local lightColor = if before then arrivalColor else tungsten:Lerp(coal, 1 - skyKey)
	self.lamp.Position = self.base * source
	self.key.Color, self.key.Brightness = lightColor, glow * adapted * 13
	for _, p in self.pools do
		local receiver = p.shore
		local incident = source - receiver
		local distance = incident.Magnitude
		local ray = V(incident.X, math.max(13, incident.Y), incident.Z).Unit
		p.mount.CFrame = self.base * CFrame.lookAt(receiver + ray * 33, receiver)
		p.light.Color = lightColor
		p.light.Brightness = glow * (0.55 + 8.7 / (1 + (distance / 73) ^ 2)) * (0.042 + 0.958 * skyKey) * adapted
	end

	-- Find the reflected image of the moving source, then sample rough facets
	-- from that point toward the observer. Opaque land masks the inland samples.
	local eye = self.base:PointToObjectSpace(camera.CFrame.Position)
	local flatEye, flatStar = V(eye.X, sea, eye.Z), V(source.X, sea, source.Z)
	local toStar = flatStar - flatEye
	if toStar.Magnitude < 0.1 then
		return
	end
	local axis = toStar.Unit
	local across = axis:Cross(Vector3.yAxis)
	local ratio = math.clamp((eye.Y - sea) / math.max(1, eye.Y + source.Y - 2 * sea), 0, 1)
	local mirror = flatEye:Lerp(flatStar, ratio)
	local towardViewer = (flatEye - mirror).Magnitude
	local viewerIsAbove = S.ease(eye.Y, sea + 2, sea + 8)
	local centre = mirror:Lerp(flatEye, 0.23) + V(0, 0.115, 0)
	self.footprint.Size = V(115 + 130 * glow, math.max(180, towardViewer * 1.56), 0.035)
	self.footprint.CFrame = self.base * CFrame.fromMatrix(centre, across, -axis, -Vector3.yAxis)
	self.wash.ImageTransparency = 1 - (if self.image then 0.84 else 0.38) * glow * viewerIsAbove * adapted
	self.wash.ImageColor3 = if before then arrivalColor else Color3.new(1, 0.93, 0.86)
	for _, w in self.waves do
		local age = t * 2.85 + w.phase
		local bright = 0.53 + 0.47 * math.sin(age + w.reach * 9)
		local offset = w.offset * (6 + 28 * w.reach) + math.sin(age) * 0.74
		local p = mirror - axis * ((w.reach - 0.12) * towardViewer * 0.94) + across * offset
		p += V(0, 0.24 + 0.06 * bright, 0)
		local pearl = (1 - math.abs(w.offset)) * (0.42 + 0.58 * bright)
		w.part.Color = if before then arrivalColor:Lerp(tungsten, pearl * 0.30) else amber:Lerp(tungsten, pearl)
		w.part.Size = V(w.length * (0.5 + pearl), 0.045, w.width * (0.5 + 0.65 * bright))
		w.part.CFrame = self.base * CFrame.lookAt(p, p + axis)
		w.part.Transparency = 1 - math.min(0.90, (0.19 + 0.80 * pearl) * glow * viewerIsAbove * adapted)
	end
end

function MeteorLight:Destroy()
	self.root:Destroy()
	if self.image then
		self.image:Destroy()
	end
end
return MeteorLight
