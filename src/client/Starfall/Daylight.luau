local edit = require(script.Parent.ImpactEdit)
local Lighting = game:GetService("Lighting")
local S = require(script.Parent.Scenery)
local clock = require(script.Parent.Timeline)
local sheet = require(script.Parent.ExposureSheet)
local terminal = require(script.Parent.TerminalLight)
local Moonlight = require(script.Parent.Moonlight)
local V, CF, hex = Vector3.new, CFrame.new, Color3.fromHex
local Daylight = {}
Daylight.__index = Daylight

-- A broken marine layer sits hundreds of studs beyond the headland. Each
-- bank has a soft shadow body and sunlit rim at separate depths and heights.
local function cloudbanks(root)
	local cloud = S.group("Weather beyond the strait")
	cloud.Parent = root
	local rng, flecks = Random.new(18249), {}
	for k, centre in { V(-550, 110, -77), V(-380, 124, -296), V(-145, 86, -540), V(250, 111, -540), V(-505, 84, 284) } do
		for j = 1, 5 do
			local p = centre + V((j - 3) * 35 + rng:NextNumber(-8, 8), rng:NextNumber(-4, 5), rng:NextNumber(-26, 26))
			local width = rng:NextNumber(78, 145)
			local height = rng:NextNumber(13, 24)
			for edge = 0, 1 do
				local anchor = S.part(cloud, "Marine cloud", CF(), Vector3.one, "FFFFFF")
				anchor.Transparency, anchor.CastShadow = 1, false
				local board = Instance.new("BillboardGui")
				board.LightInfluence, board.Enabled, board.Parent = 0, false, anchor
				board.Size = UDim2.fromScale(width * (1 - 0.21 * edge), height * (1 - 0.54 * edge))
				local texture = Instance.new("ImageLabel")
				texture.Image = "rbxasset://textures/particles/smoke_main.dds"
				texture.Size, texture.BackgroundTransparency, texture.Parent = UDim2.fromScale(1, 1), 1, board
				table.insert(flecks, {
					anchor = anchor,
					board = board,
					texture = texture,
					point = p + V(-4, 4.3, 3) * edge,
					edge = edge,
					opacity = rng:NextNumber(0.27, 0.47),
					wind = 0.33 + k * 0.081,
				})
			end
		end
	end
	return flecks
end

local function disc(root, name, color, texture)
	local anchor = S.part(root, name, CF(), Vector3.one, color)
	anchor.Transparency, anchor.CastShadow = 1, false
	local board = Instance.new("BillboardGui")
	board.LightInfluence, board.Size, board.Parent = 0, UDim2.fromScale(32, 32), anchor
	if texture then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency, image.Image, image.Size, image.Parent = 1, texture, UDim2.fromScale(1, 1), board
		-- The bundled lunar albedo is a square photograph with a black edge.
		-- Keep its illuminated face inside a circular crop against the twilight.
		local mask = Instance.new("UICorner")
		mask.CornerRadius, mask.Parent = UDim.new(1, 0), image
		image.ImageRectOffset, image.ImageRectSize = Vector2.new(11, 10), Vector2.new(105, 105)
	else
		local sun = Instance.new("Frame")
		sun.BackgroundColor3, sun.BorderSizePixel, sun.Size, sun.Parent = hex(color), 0, UDim2.fromScale(1, 1), board
		local edge = Instance.new("UICorner")
		edge.CornerRadius, edge.Parent = UDim.new(1, 0), sun
	end
	return { part = anchor, board = board }
end

function Daylight.new(stage)
	local root = S.group("Sky over the cove")
	root.Parent = stage
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name, grade.Enabled, grade.Parent = "Light through ash", false, stage.Parent
	local air = Lighting:FindFirstChildOfClass("Atmosphere")
	local ownAir = not air
	if not air then
		air = Instance.new("Atmosphere")
		air.Parent = Lighting
	end
	local function optical(class, name)
		local fx = Instance.new(class)
		fx.Name, fx.Enabled, fx.Parent = name, false, stage.Parent
		return fx
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	local own = not sky
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end
	local self = setmetatable({
		root = root,
		grade = grade,
		sky = sky,
		own = own,
		bodies = sky.CelestialBodiesShown,
		air = air,
		ownAir = ownAir,
		glare = air.Glare,
		offset = air.Offset,
		bloom = optical("BloomEffect", "Halation off the plasma"),
		rays = optical("SunRaysEffect", "Light scattered by ash"),
		blur = optical("BlurEffect", "Pressure on the lens"),
		depth = optical("DepthOfFieldEffect", "Focus on the fault"),
		airColor = air and air.Color,
		airDecay = air and air.Decay,
		density = air and air.Density,
		haze = air and air.Haze,
		hour = Lighting.ClockTime,
		latitude = Lighting.GeographicLatitude,
		exposure = Lighting.ExposureCompensation,
		ambient = Lighting.Ambient,
		outdoor = Lighting.OutdoorAmbient,
		top = Lighting.ColorShift_Top,
		bottom = Lighting.ColorShift_Bottom,
		softness = Lighting.ShadowSoftness,
		diffuse = Lighting.EnvironmentDiffuseScale,
		specular = Lighting.EnvironmentSpecularScale,
		brightness = Lighting.Brightness,
		weather = cloudbanks(root),
		lunar = Moonlight.new(stage),
		sun = disc(root, "Sun", "FFE9B5"),
		moon = disc(root, "Moon", "D4E0FF", "rbxasset://sky/moon.jpg"),
	}, Daylight)
	sky.CelestialBodiesShown = false
	return self
end

local solar = {
	{ clock.recovery, 4.78 },
	{ 14.7, 15.2 },
	{ 16.70, 32.6 },
	{ 19.30, 37.4 },
	{ 20.12, 40.3 },
	{ 20.77, 53.1 },
	{ 21.90, 60.8 },
	{ 22.47, 64.55 },
	{ 22.98, 77.3 },
	{ 23.25, 80.55 },
	{ 24.50, 84.4 },
	{ 26.80, 85.0 },
	{ clock.match, 88.0 },
}
local function hourAt(t, motion, finish)
	if t < clock.recovery then
		return 4.78
	end
	if not motion then
		return 4.78 + (finish - 4.78) * S.ease(t, clock.recovery, clock.match)
	end
	for i = 2, #solar do
		local a, b = solar[i - 1], solar[i]
		if t < b[1] then
			local h = if i == #solar then 72 + finish else b[2]
			return a[2] + (h - a[2]) * (t - a[1]) / (b[1] - a[1])
		end
	end
	return finish
end

function Daylight:draw(t, motion, base, masterFrame)
	local frame = masterFrame or math.floor(sheet.frameForScene(t) + 0.5)
	local approach, arrivalColor = terminal(frame)
	local basin = S.ease(t, 7.94, 8.63) * (1 - S.ease(t, 11.63, 13.56))
	local hour = hourAt(t, motion, self.hour) % 24
	local phase = (hour - 6) * math.pi / 12
	local night = 1 - S.ease(math.sin(phase), -0.38, 0.20)
	local dawn = 1 - S.ease(math.abs(math.sin(phase)), 0.015, 0.56)
	local history = 1 - S.ease(t, 26.80, clock.match)
	local look = 1 - S.ease(frame, sheet.frames.handoff, sheet.frames.endBlend)
	local ancient = 1 - S.ease(t, clock.recovery, 13.76)
	local ash = S.ease(t, clock.contact + 0.17, 6.35) * (1 - S.ease(t, clock.recovery + 0.30, 15.83))
	local heat
	if frame < sheet.frames.contact then
		heat = approach * 0.52
	elseif frame < sheet.frames.ignition then
		heat = if frame == sheet.frames.contact then 0.22 else 0.02
	else
		heat = (1 - S.ease(t, sheet.sceneTime(sheet.frames.ignition), 5.58)) ^ 2
	end
	local hot = heat * (if motion then 1 else 0.52)
	local veil = S.ease(t, 7.46, 7.62) * (1 - S.ease(t, 7.77, 8.59))
	local hero = S.ease(frame, sheet.frames.entry - 2, sheet.frames.entry + 7)
		* (1 - S.ease(frame, sheet.frames.coast - 3, sheet.frames.coast))
	self.grade.Enabled = look > 0.001 and not (motion and edit.at(frame))
	if self.grade.Enabled then
		local stock = hex("FFF0D9"):Lerp(hex("C6D7FF"), night):Lerp(hex("A2C8FF"), ancient)
		self.grade.TintColor = Color3.new(1, 1, 1)
			:Lerp(stock:Lerp(hex("F9CEBF"), ash * 0.50):Lerp(arrivalColor, hot * 0.69), look)
		self.grade.Contrast = (0.07 + 0.035 * ancient - 0.055 * ash - 0.06 * veil) * look
		self.grade.Saturation = (-0.055 - 0.30 * ancient + 0.10 * ash) * look
	end
	-- Photograph night using a cool grazing key. The strong directional
	-- source gives even the wide shot a single, coherent cast shadow.
	local moonKey = frame < 570
	Lighting.ClockTime = if moonKey then 16.78 - 0.8 * (1 - ancient) else hour
	Lighting.GeographicLatitude = self.latitude + (34 - self.latitude) * history
	local top = hex("FFD2A5"):Lerp(hex("8DAEDF"), night):Lerp(hex("82ADF1"), ancient)
	Lighting.ColorShift_Top = self.top:Lerp(top:Lerp(hex("D99F8C"), ash * 0.40):Lerp(arrivalColor, hot), look)
	Lighting.ColorShift_Bottom = self.bottom:Lerp(hex("3D394D"):Lerp(hex("252F48"), night), look * 0.70)
	Lighting.ShadowSoftness = self.softness + (0.09 + 0.18 * ash - self.softness) * look
	Lighting.EnvironmentDiffuseScale = self.diffuse + (0.30 + 0.14 * (1 - ancient) - self.diffuse) * look
	Lighting.EnvironmentSpecularScale = self.specular + (0.83 - 0.60 * ancient - self.specular) * look
	Lighting.ExposureCompensation = self.exposure
		+ (0.06 - 0.35 * ancient + 0.32 * basin - 0.04 * ash) * look
		+ hot * 1.83
	Lighting.Brightness = self.brightness + (2.25 - ancient * 0.55 + night * 0.15 - self.brightness) * look + hot * 2.45
	local skyFill = hex("716B78"):Lerp(hex("414F72"), night):Lerp(hex("405573"), ancient)
	Lighting.OutdoorAmbient =
		self.outdoor:Lerp(skyFill:Lerp(hex("615169"), ash * 0.63):Lerp(arrivalColor, hot * 0.65), look)
	local shadow = hex("493B47"):Lerp(hex("172136"), night):Lerp(hex("151D32"), ancient)
	Lighting.Ambient = self.ambient:Lerp(shadow:Lerp(hex("50333B"), ash * 0.56):Lerp(arrivalColor, hot * 0.50), look)
	local moonDirection = if moonKey then Lighting:GetSunDirection() else Lighting:GetMoonDirection()
	self.lunar:draw(
		base,
		moonDirection,
		clock.breakerEye,
		frame,
		ancient * (1 - 0.88 * hot) * (1 - 0.71 * ash),
		moonKey
	)
	if self.air then
		self.air.Color = self.airColor:Lerp(
			hex("A7C9F2")
				:Lerp(hex("718CAF"), ancient)
				:Lerp(hex("D1BBCB"), dawn * (1 - ancient))
				:Lerp(arrivalColor, hot)
				:Lerp(hex("CE917D"), ash)
				:Lerp(hex("929DBC"), 0.80 * basin),
			history
		)
		self.air.Decay = self.airDecay:Lerp(
			hex("8288B5")
				:Lerp(hex("353C62"), ancient)
				:Lerp(hex("C69C88"), dawn * (1 - ancient))
				:Lerp(hex("D88B65"), hot)
				:Lerp(hex("875D66"), ash)
				:Lerp(hex("485374"), 0.76 * basin),
			history
		)
		self.air.Density = self.density
			+ (0.255 - self.density) * history
			+ 0.105 * ash
			+ 0.025 * hot
			+ 0.067 * veil
			+ 0.04 * basin
			- 0.075 * ancient
		self.air.Haze = self.haze + 1.38 * ash + 1.02 * hot + 1.67 * veil + 1.15 * basin
		self.air.Glare = self.glare + 0.60 * hot + 0.18 * ash
		self.air.Offset = self.offset - 0.085 * ash
	end
	self.bloom.Enabled = t >= clock.entry and t < 15.8
	self.bloom.Intensity, self.bloom.Size, self.bloom.Threshold =
		0.56 * hero + 0.58 * hot + 0.17 * ash, 17 + 23 * hot + 15 * hero, 1.55 - 0.53 * hot - 0.74 * hero
	-- At a sea horizon the engine's screen-space rays can cut visibly along
	-- the water plane. Use the ash-filled, inland reverse for this lens effect.
	self.rays.Enabled = t >= clock.aftermath and t < 10.02
	self.rays.Intensity, self.rays.Spread = 0.016 * ash, 0.64
	local whip = S.ease(t, 3.29, 3.40) * (1 - S.ease(t, 3.44, 3.56))
	self.blur.Enabled = motion and (veil > 0.005 or whip > 0.005)
	self.blur.Size = 3.8 * whip + 5.6 * veil
	self.sky.CelestialBodiesShown = if t >= clock.match then self.bodies else false
	local clouds = t >= 3.20 and t < 16.45
	if clouds ~= self.cloudsOn or (clouds and self.cloudTime ~= t) then
		self.cloudsOn, self.cloudTime = clouds, t
		local density = 1 - S.ease(t, 14.9, 16.45)
		local shade = hex("596579"):Lerp(hex("DBB4A4"), hot):Lerp(hex("866B71"), ash)
		local edge = hex("A9B9D8"):Lerp(hex("FFF0CF"), hot):Lerp(hex("B58D81"), ash)
		for _, c in self.weather do
			c.board.Enabled = clouds
			if clouds then
				c.anchor.Position = base * (c.point + V(c.wind, 0.07, -0.16) * (t - 3.55))
				c.texture.ImageTransparency = 1 - density * c.opacity * (0.75 + 0.52 * ancient + 0.24 * hot)
				c.texture.ImageColor3 = if c.edge == 1 then edge else shade
			end
		end
	end
	for i, body in { self.sun, self.moon } do
		local angle = phase + (i - 1) * math.pi
		local h = math.sin(angle)
		body.board.Enabled = (i == 2 and t >= clock.entry or t >= clock.recovery) and t < 26.8 and h > -0.05
		if body.board.Enabled then
			local skyPosition = V(-160 + 370 * math.cos(angle), 66 + 166 * h, -415)
			if i == 2 then
				skyPosition = skyPosition:Lerp(V(0, 21, 0) + moonDirection * 515, ancient)
				local face = body.board:FindFirstChildOfClass("ImageLabel")
				face.ImageTransparency = 0.07 + 0.74 * ash + 0.15 * hot
				face.ImageColor3 = hex("D2E1FF")
			end
			body.part.Position = base * skyPosition
			if i == 1 then
				local discFace = body.board:FindFirstChildOfClass("Frame")
				discFace.BackgroundColor3 = hex("FFEBBB"):Lerp(hex("DE9979"), ash)
				discFace.BackgroundTransparency = ash * 0.26
			end
		end
	end
end
-- Focus through the ash onto the near bank, then allow the violet fissure to
-- resolve. Optical distances follow the actual camera, including a phone's framing.
function Daylight:focus(camera, base, t, motion)
	local depth = self.depth
	depth.Enabled = t >= clock.aftermath and t < 12.56
	if not depth.Enabled then
		return
	end
	local toSeam = base * V(0, 26.7, -32) - camera.CFrame.Position
	local distance = math.max(1, toSeam:Dot(camera.CFrame.LookVector))
	local rack = S.ease(t, 8.95, 9.73)
	local close = t >= 10.02
	local melt = (1 - S.ease(t, clock.recovery, 12.56)) * (if motion then 1 else 0.62)
	depth.FocusDistance = if close
		then distance - 0.9 * (1 - S.ease(t, 10.02, 10.65))
		else distance * (0.51 + 0.47 * rack)
	depth.InFocusRadius = if close then 3.7 else 7.8 + 3 * rack
	depth.FarIntensity = (if close then 0.39 else 0.32) * melt
	depth.NearIntensity = (if close then 0.54 else 0.48) * melt
end
function Daylight:Destroy()
	Lighting.ClockTime, Lighting.GeographicLatitude = self.hour, self.latitude
	Lighting.ExposureCompensation, Lighting.Brightness, Lighting.ColorShift_Top =
		self.exposure, self.brightness, self.top
	Lighting.Ambient, Lighting.OutdoorAmbient = self.ambient, self.outdoor
	Lighting.ColorShift_Bottom, Lighting.ShadowSoftness = self.bottom, self.softness
	Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = self.diffuse, self.specular
	if self.air then
		self.air.Color, self.air.Decay, self.air.Density, self.air.Haze =
			self.airColor, self.airDecay, self.density, self.haze
		self.air.Glare, self.air.Offset = self.glare, self.offset
		if self.ownAir then
			self.air:Destroy()
		end
	end
	if self.own then
		self.sky:Destroy()
	else
		self.sky.CelestialBodiesShown = self.bodies
	end
	self.lunar:Destroy()
	self.root:Destroy()
	for _, fx in { self.grade, self.bloom, self.rays, self.blur, self.depth } do
		fx:Destroy()
	end
end
return Daylight
