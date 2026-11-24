local edit = require(script.Parent.ImpactEdit)
local Lighting = game:GetService("Lighting")
local S = require(script.Parent.Scenery)
local clock = require(script.Parent.Timeline)
local sheet = require(script.Parent.ExposureSheet)
local terminal = require(script.Parent.TerminalLight)
local Moonlight = require(script.Parent.Moonlight)
local MineFace = require(script.Parent.MineFace)
local V, CF, hex = Vector3.new, CFrame.new, Color3.fromHex
local ancientHour = 2.65
-- This low sun shares the surveyed moon's bearing to within 0.1 degree.
-- Night stock and the stage sky supply its colour. Roblox's solar shadow
-- pass retains enough direct light to separate the silhouettes at this angle.
local lunarShadowHour = 17.15
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

function Daylight.new(stage, nightLook)
	nightLook = nightLook or require(script.Parent.NightLook)
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
		moonSize = sky.MoonAngularSize,
		nightLook = nightLook,
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
		lunar = Moonlight.new(stage, nightLook),
	}, Daylight)
	sky.CelestialBodiesShown = false
	sky.MoonAngularSize = 0
	return self
end

function Daylight:draw(t, motion, base, masterFrame)
	-- Stage every value and write it once. Setting a light twice in one exposure
	-- restarts the engine's own settling and the key never arrives.
	local want = {}
	self.want = want
	local frame = masterFrame or math.floor(sheet.frameForScene(t) + 0.5)
	local approach, arrivalColor = terminal(frame)
	local basin = S.ease(t, 7.94, 8.63) * (1 - S.ease(t, 11.63, 13.56))
	local historical = frame < sheet.frames.match
	local hour = if historical then ancientHour else self.hour
	local phase = (hour - 6) * math.pi / 12
	local night = 1 - S.ease(math.sin(phase), -0.38, 0.20)
	local dawn = 1 - S.ease(math.abs(math.sin(phase)), 0.015, 0.56)
	local history = if historical then 1 else 0
	local look = 1 - S.ease(frame, sheet.frames.handoff, sheet.frames.endBlend)
	local ancient = history
	local ash = history * S.ease(t, clock.contact + 0.17, 6.35)
	local heat
	if frame < sheet.frames.contact then
		-- The streak illuminates the cove locally. A smaller exposure lift
		-- keeps the sky dark through all three frames of its arrival.
		heat = approach * 0.19
	elseif frame < sheet.frames.ignition then
		heat = if frame == sheet.frames.contact then 0.22 else 0.02
	else
		heat = (1 - S.ease(t, sheet.sceneTime(sheet.frames.ignition), 5.58)) ^ 2
	end
	local hot = heat * (if motion then 1 else 0.52)
	local quiet = 1 - S.ease(frame, sheet.frames.contact, sheet.frames.ignition + 9)
	local offshore = if frame < sheet.frames.aftermath then 1 else 0
	local veil = S.ease(t, 7.46, 7.62) * (1 - S.ease(t, 7.77, 8.59))
	local hero = S.ease(frame, sheet.frames.entry - 2, sheet.frames.entry + 7)
		* (1 - S.ease(frame, sheet.frames.coast - 3, sheet.frames.coast))
	self.grade.Enabled = look > 0.001 and not (motion and edit.at(frame))
	if self.grade.Enabled then
		local stock = hex("FFF0D9"):Lerp(hex("C6D7FF"), night):Lerp(hex("B7CFFF"), ancient)
		self.grade.TintColor = Color3.new(1, 1, 1)
			:Lerp(stock:Lerp(hex("F9CEBF"), ash * 0.50):Lerp(arrivalColor, hot * 0.69), look)
		self.grade.Contrast = (0.07 + 0.035 * ancient - 0.04 * quiet - (0.055 - 0.025 * offshore) * ash - 0.06 * veil) * look
		self.grade.Saturation = (-0.055 - 0.17 * ancient + 0.10 * ash + 0.13 * hero) * look
	end
	local moonKey = historical
	local shadowKey = frame >= sheet.frames.coast and frame < sheet.frames.aftermath
	Lighting.ClockTime = if shadowKey then lunarShadowHour else hour
	Lighting.GeographicLatitude = if shadowKey then 33.9 else self.latitude + (34 - self.latitude) * history
	local top = hex("FFD2A5"):Lerp(hex("8DAEDF"), night):Lerp(hex("82ADF1"), ancient)
	want.ColorShift_Top = self.top:Lerp(top:Lerp(hex("D99F8C"), ash * 0.40):Lerp(arrivalColor, hot * 0.34), look)
	want.ColorShift_Bottom = self.bottom:Lerp(hex("3D394D"):Lerp(hex("252F48"), night), look * 0.70)
	want.ShadowSoftness = self.softness + (0.09 - 0.025 * offshore + (0.18 - 0.04 * offshore) * ash - self.softness) * look
	want.EnvironmentDiffuseScale = self.diffuse + (0.30 - 0.21 * offshore + 0.14 * (1 - ancient) - self.diffuse) * look
	want.EnvironmentSpecularScale = self.specular + (0.83 - 0.60 * ancient - self.specular) * look
	want.ExposureCompensation = self.exposure
		+ (0.06 - 0.13 * ancient + 0.32 * basin - 0.04 * ash) * look
		+ hot * (if frame < sheet.frames.contact then 1.83 else 0.46)
		+ self.nightLook.Exposure * quiet * (1 - 0.7 * hero)
	-- The native shadow source shares the bearing of the baked silhouettes.
	-- During ignition leave those occluded planes cool. Actual crater lights
	-- supply the orange illumination on the faces that can see the fire.
	want.Brightness = self.brightness + (2.25 - ancient * 0.55 + 1.38 * offshore + night * 0.15 - self.brightness) * look
	local skyFill = hex("716B78"):Lerp(hex("414F72"), night):Lerp(hex("788BB0"), ancient):Lerp(self.nightLook.ShadowFill, offshore)
	want.OutdoorAmbient =
		self.outdoor:Lerp(skyFill:Lerp(hex("615169"), ash * (0.63 - 0.42 * offshore)):Lerp(arrivalColor, hot * 0.09), look)
	local shadow = hex("493B47"):Lerp(hex("273048"), night):Lerp(hex("27364D"), ancient)
		:Lerp(Color3.new():Lerp(self.nightLook.ShadowFill, 0.23), offshore)
	want.Ambient = self.ambient:Lerp(shadow:Lerp(hex("50333B"), ash * (0.56 - 0.42 * offshore)), look)
	-- The offshore source is inferred from the cliff edges and cast shadows.
	local moonDirection = if moonKey then Moonlight.direction else Lighting:GetMoonDirection()
	self.lunar:draw(
		base,
		moonDirection,
		clock.breakerEye,
		frame,
		ancient * (1 - 0.88 * hot) * (1 - 0.71 * ash),
		moonKey,
		hot,
		ash
	)
	if self.air then
		self.air.Color = self.airColor:Lerp(
			hex("A7C9F2")
				:Lerp(hex("718CAF"), ancient)
				:Lerp(self.nightLook.SkyColor:Lerp(hex("596075"), 0.55), quiet)
				:Lerp(hex("D1BBCB"), dawn * (1 - ancient))
				:Lerp(arrivalColor, hot * 0.38)
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
		local density = self.density
			+ (0.255 - self.density) * history
			+ 0.105 * ash
			+ 0.025 * hot
			+ 0.067 * veil
			+ 0.04 * basin
			- 0.075 * ancient
		local haze = self.haze + (1.38 - 0.60 * offshore) * ash + 0.28 * hot + 1.67 * veil + 1.15 * basin
		-- Open air has haze. A room does not.
		local indoors = frame >= sheet.frames.dig - 11 and frame < sheet.frames.witness
		self.air.Density, self.air.Haze = if indoors then 0 else density, if indoors then 0 else haze
		self.air.Glare = self.glare + 0.24 * hot + 0.18 * ash
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
	self.sky.CelestialBodiesShown = not historical and self.bodies
	self.sky.MoonAngularSize = if historical then 0 else self.moonSize
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
	self:scene(frame, want)
	for key, value in want do
		if Lighting[key] ~= value then
			Lighting[key] = value
		end
	end
end

-- Each present-day scene has one key idea. The cove keeps its afternoon sun,
-- the gallery is lamplit until the vein opens, the living room is dim so the
-- screen can light it, and the glass stage is clean and cool.
function Daylight:scene(frame, want)
	local F = sheet.frames
	if frame < F.match or frame >= F.endBlend then
		return
	end
	local function light(brightness, ambient, outdoor, top, exposure, tint, contrast, saturation)
		want.Brightness, want.ExposureCompensation = brightness, exposure
		want.Ambient, want.OutdoorAmbient, want.ColorShift_Top = ambient, outdoor, top
		self.grade.Enabled, self.grade.TintColor = true, tint
		self.grade.Contrast, self.grade.Saturation = contrast, saturation
	end
	local white = Color3.new(1, 1, 1)
	if frame < F.dig - 11 then
		return
	elseif frame < F.living then
		local shine = MineFace.shine(frame)
		local dim = hex("3E3C48"):Lerp(hex("6C52AE"), 0.55 * shine)
		light(0, dim, dim, hex("FFFFFF"), 0.12 - 0.1 * shine, white:Lerp(hex("F3E9FF"), shine), 0.10, 0.0)
	elseif frame < F.witness then
		light(1.15, hex("605C66"), hex("605C66"), hex("FFDDB4"), -0.16, hex("FFF8F0"), 0.06, -0.02)
	elseif frame >= F.reveal and frame < F.answer then
		light(1.5, hex("AEB8C8"), hex("AEB8C8"), hex("F4FAFF"), -0.02, white, 0.06, 0.0)
	elseif frame >= F.arrive and frame < F.reveal then
		local glow = S.ease(frame, F.arrive + 18, F.arrive + 30)
		self.grade.TintColor = self.grade.TintColor:Lerp(hex("F0E6FF"), 0.6 * glow)
		-- The player faces away from the low sun. Open the shade on their face.
		want.OutdoorAmbient = hex("B3AEBC")
		want.Ambient = hex("9A95A6")
		want.ExposureCompensation += 0.2
	end
end

function Daylight:focus(camera, base, frame, motion)
	self.lunar:focus(camera, base)
	local depth = self.depth
	depth.Enabled = frame >= sheet.frames.aftermath and frame < sheet.frames.match
	if not depth.Enabled then return end
	local close = frame >= sheet.frames.seam
	local distance = (camera.Focus.Position - camera.CFrame.Position).Magnitude
	depth.FocusDistance = distance
	depth.InFocusRadius = if close then 2.7 else 26
	depth.FarIntensity = if close then 0.38 else 0.18
	depth.NearIntensity = if close then 0.25 else 0.2
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
		self.sky.MoonAngularSize = self.moonSize
	end
	self.lunar:Destroy()
	self.root:Destroy()
	for _, fx in { self.grade, self.bloom, self.rays, self.blur, self.depth } do
		fx:Destroy()
	end
end
return Daylight
