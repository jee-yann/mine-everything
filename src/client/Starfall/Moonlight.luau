-- The lunar key is at grazing incidence. Sample its parallel rays at the
-- terraces so the distant offshore camera can read individual cliff faces.
local S = require(script.Parent.Scenery)
local frames = require(script.Parent.ExposureSheet).frames
local V, CF, hex = Vector3.new, CFrame.new, Color3.fromHex
local Moonlight = {}
Moonlight.__index = Moonlight
-- Survey bearing used to bake the cove's projected silhouettes.
Moonlight.direction = V(-0.959, 0.218, 0.181).Unit

-- Moonlit stone and foliage retain separate local values under a saturated
-- blue key. Only the prehistoric models are exposed to this stock.
local pigments = {
	["Sandstone shoulder"] = "778AA3",
	["Weathered sandstone"] = "9CA6B7",
	["Mesa face"] = "898D9C",
	["Coastal escarpment"] = "71819C",
	["Turf lip"] = "668B89",
	["Meadow cap"] = "668982",
	["Ridgeline turf"] = "7D9890",
	["Turf on the rim"] = "6D928A",
	["Headland turf"] = "75958B",
	["Grass shelf"] = "698D85",
	["Sea-grape crown"] = "6B9090",
	["Salt-pruned crown"] = "789698",
	["Fir boughs"] = "67898D",
	["Mountain flank"] = "77889D",
	["Far slope"] = "7C8AA2",
	["Summit facet"] = "98A8BC",
	["Weathered beds"] = "638786",
	["Mineral bedding"] = "7F8193",
	["Fractured stone"] = "808899",
	["Split face"] = "8591A5",
}

local cascade = { ["Falls crest"] = true, ["Falling water"] = true, ["Whitewater"] = true, ["Current"] = true }
-- A little sea mist hangs in the two gaps below the western canopy. Stretch
-- the soft particles along the incident light. Terrain occludes each ribbon.
local function lightThroughMist(look)
	local group = S.group("Moonlight through sea mist")
	local images = {}
	local axis = -Moonlight.direction
	local eye = require(script.Parent.Timeline).breakerEye
	for _, gap in {
		{ V(-58, 45, 32), 77, 9, 0.21 },
		{ V(-62, 48, 37), 56, 4.5, 0.16 },
		{ V(-8, 61, -61), 68, 11, 0.15 },
	} do
		local center, length, width, density = table.unpack(gap)
		local up = (eye - center):Cross(axis).Unit
		local plane = CFrame.fromMatrix(center, axis, up)
		local mist = S.part(group, "Mist in a canopy gap", plane, V(length, width, 0.05), "FFFFFF")
		mist.Transparency, mist.CastShadow = 1, false
		local surface = Instance.new("SurfaceGui")
		surface.Face = Enum.NormalId.Back
		surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		surface.CanvasSize = Vector2.new(384, 64)
		surface.LightInfluence, surface.Brightness, surface.Parent = 0, 1, mist
		local image = Instance.new("ImageLabel")
		image.Size, image.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		image.Image = "rbxasset://textures/particles/smoke_main.dds"
		image.ImageColor3, image.ImageTransparency, image.Parent = look.RimColor, 1, surface
		local feather = Instance.new("UIGradient")
		feather.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 0.10),
			NumberSequenceKeypoint.new(0.58, 0.06), NumberSequenceKeypoint.new(1, 1),
		})
		feather.Parent = image
		table.insert(images, { image = image, density = density })
	end
	return group, images
end

local shelves = {
	V(-69, 62, -77),
	V(-16, 65, -87),
	V(49, 56, -76),
	V(-70, 42, 32),
	V(-41, 28, -13),
	V(9, 30, -29),
	V(62, 44, 75),
	V(58, 39, 12),
	V(-88, 31, 86),
}

-- A fixed night cyclorama lets the terrain use the engine's directional
-- shadow maps. Bands follow the real horizon even when the camera rolls.
local function nightSky(skyColor)
	local model = S.group("Night across the strait")
	-- Enclose the outermost flight camera (-600, 440, 370), the cloud
	-- banks, and the island within a much shorter native draw distance.
	local sides, radius, high, low = 16, 1250, 820, -200
	local width = 2 * radius * math.tan(math.pi / sides) + 2
	local cap = 2 * radius / 3 + 2
	local random = Random.new(1775)
	for i = 1, sides + 9 do
		local roof = i > sides
		local angle = 2 * math.pi * i / sides
		local tile = i - sides - 1
		local pos = if roof
			then V((tile % 3 - 1) * (cap - 2), high, (math.floor(tile / 3) - 1) * (cap - 2))
			else V(math.cos(angle) * radius, (high + low) / 2, math.sin(angle) * radius)
		local surface = if roof then CF(pos) * CFrame.Angles(-math.pi / 2, 0, 0) else CFrame.lookAt(pos, V(0, pos.Y, 0))
		local size = if roof then V(cap, cap, 0.05) else V(width, high - low, 0.05)
		local panel = S.part(model, "Sky panel", surface, size, "FFFFFF")
		panel.Transparency, panel.CastShadow = 1, false
		local gui = Instance.new("SurfaceGui")
		gui.Face, gui.LightInfluence, gui.Brightness, gui.MaxDistance = Enum.NormalId.Front, 0, 1, 3600
		gui.SizingMode, gui.CanvasSize, gui.Parent = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(640, 960), panel
		local face = Instance.new("Frame")
		face.Size, face.BorderSizePixel, face.BackgroundColor3, face.Parent =
			UDim2.fromScale(1, 1), 0, if roof then Color3.new():Lerp(skyColor, 0.54) else Color3.new(1, 1, 1), gui
		if not roof then
			local gradient = Instance.new("UIGradient")
			gradient.Rotation = 90
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new():Lerp(skyColor, 0.54)),
				ColorSequenceKeypoint.new(0.77, skyColor),
				ColorSequenceKeypoint.new(1, Color3.new():Lerp(skyColor, 0.84)),
			})
			gradient.Parent = face
			for _ = 1, 17 do
				local star = Instance.new("Frame")
				local y = random:NextNumber(0.26, 0.81)
				star.Position, star.Size =
					UDim2.fromScale(random:NextNumber(0.004, 0.996), y), UDim2.fromOffset(random:NextInteger(1, 2), 1)
				star.BackgroundColor3, star.BackgroundTransparency = hex("CED7F2"), random:NextNumber(0.45, 0.78)
				star.BorderSizePixel, star.Parent = 0, face
			end
		end
	end
	return model
end

function Moonlight.new(stage, nightLook)
	nightLook = nightLook or require(script.Parent.NightLook)
	local root = S.group("Moonlight on Citrine Cove")
	local mist, mistImages = lightThroughMist(nightLook)
	mist.Parent = root
	local beams = {}
	for i, target in shelves do
		local mount = S.part(root, "Lunar key", CF(), Vector3.one * 0.1, "FFFFFF")
		mount.Transparency, mount.CastShadow = 1, false
		local key = Instance.new("SpotLight")
		key.Name, key.Face, key.Angle, key.Range = "Light along the ledge", Enum.NormalId.Front, 103, 60
		key.Color = nightLook.RimColor
		key.Shadows = true
		key.Parent = mount
		table.insert(beams, { mount = mount, light = key, target = target })
	end
	-- The offshore camera sees a broken silver reflection. Its long axis lies
	-- between the observer and the reflection of the moon in the water plane.
	local rand, ripples = Random.new(6118), {}
	for i = 1, 64 do
		local n = (i - 0.5) / 64
		local part = S.part(
			root,
			"Light along a swell",
			CF(),
			V(rand:NextNumber(2.0, 12) * (0.6 + n), 0.035, rand:NextNumber(0.27, 0.81)),
			"B5D0EE",
			Enum.Material.Neon
		)
		part.CastShadow = false
		table.insert(ripples, { part = part, n = n, side = rand:NextNumber(-1, 1), phase = rand:NextNumber(0, 6.28) })
	end
	local relief = script.Parent.MoonlitShelves:Clone()
	local ink = relief:GetChildren()
	for _, facet in ink do
		if facet.Name == "Umbra" then
			facet.Color = Color3.new():Lerp(nightLook.ShadowFill, 0.19)
		else
			facet.Material = Enum.Material.Neon
			facet.Color = Color3.new():Lerp(nightLook.RimColor, if facet.Name == "LunarGrass" then 0.75 else 0.86)
		end
	end
	-- Paint atmospheric perspective beyond the island but inside the
	-- low-quality far clip. The lower edge dissolves over the offshore water.
	local aprons = S.group("Distant nocturnal strait")
	local horizon = V(-223, 87, -90)
	local haze = S.part(
		aprons,
		"Marine horizon",
		CFrame.lookAt(horizon, horizon + V(0.88, 0, 0.46)),
		V(1500, 1000, 0.06),
		"FFFFFF"
	)
	haze.Transparency, haze.CastShadow = 1, false
	local board = Instance.new("SurfaceGui")
	board.Face, board.LightInfluence, board.Brightness, board.MaxDistance = Enum.NormalId.Front, 0, 1, 3600
	board.SizingMode, board.CanvasSize, board.Parent = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(40, 512), haze
	local wash = Instance.new("Frame")
	wash.Size, wash.BorderSizePixel, wash.BackgroundColor3, wash.Parent =
		UDim2.fromScale(1, 1), 0, Color3.new(1, 1, 1), board
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new():Lerp(nightLook.SkyColor, 0.44)),
		ColorSequenceKeypoint.new(0.46, nightLook.SkyColor),
		ColorSequenceKeypoint.new(0.54, Color3.new():Lerp(nightLook.SkyColor, 0.88)),
		ColorSequenceKeypoint.new(0.61, Color3.new():Lerp(nightLook.SkyColor, 0.60)),
		ColorSequenceKeypoint.new(1, Color3.new():Lerp(nightLook.SkyColor, 0.60)),
	})
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.53, 0),
		NumberSequenceKeypoint.new(0.60, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = wash
	local chaseHorizon = haze:Clone()
	chaseHorizon.Name = "Aerial sea haze"
	chaseHorizon.Size = V(1350, 1000, 0.06)
	return setmetatable({
		stage = stage,
		root = root,
		mist = mist,
		mistImages = mistImages,
		sky = nightSky(nightLook.SkyColor),
		nightLook = nightLook,
		beams = beams,
		ripples = ripples,
		relief = relief,
		ink = ink,
		aprons = aprons,
		hazeSurface = board,
		hazeWash = wash,
		chaseHorizon = chaseHorizon,
		tint = {},
	}, Moonlight)
end

function Moonlight:relight(base, frame)
	local strength = 1 - S.ease(frame, frames.ignition, frames.waveLaunch + 12)
	-- Keep the unburnt parcels in their night palette as the advancing wave
	-- lights them. Restore the authored materials on the cut into the fissure.
	local tinted = frame < frames.seam
	if self.strength == strength and self.tinted == tinted and self.island then
		return
	end
	local island = self.stage:FindFirstChild("Ancient Citrine Cove")
	if island and not self.island and tinted then
		for _, piece in island:GetDescendants() do
			local swatch = pigments[piece.Name]
			if (swatch or cascade[piece.Name]) and piece:IsA("BasePart") then
				local moon = if swatch then piece.Color:Lerp(hex(swatch):Lerp(self.nightLook.ShadowFill, 0.46), 0.72)
					else self.nightLook.ShadowFill:Lerp(self.nightLook.RimColor, if piece.Name == "Whitewater" then 0.38 else 0.15)
				if piece:IsA("WedgePart") and piece.Size.X < 0.20 then
					local n = piece.CFrame.RightVector
					if n.Y < 0 then
						n = -n
					end
					local incidence = n:Dot(base:VectorToWorldSpace(Moonlight.direction))
					moon = self.nightLook.ShadowFill:Lerp(moon:Lerp(self.nightLook.RimColor, 0.35), math.clamp(0.40 + incidence * 0.80, 0, 1))
				end
				if piece.Name == "Mountain flank" or piece.Name == "Far slope" or piece.Name == "Summit facet" then
					-- Sea air softens the pale, offshore spurs behind the headland.
					local depth = -base:PointToObjectSpace(piece.Position).Z
					moon = moon:Lerp(self.nightLook.SkyColor, 0.67 * S.ease(depth, 118, 190))
				end
				table.insert(self.tint, { part = piece, day = piece.Color, moon = moon })
			end
		end
		self.island = island
	end
	self.relief.Parent = if strength > 0 then self.stage else nil
	if not self.placed then
		self.mist:PivotTo(base)
		self.relief:PivotTo(base)
		self.aprons:PivotTo(base)
		self.placed = true
	end
	for _, facet in self.ink do
		local amount = if facet.Name == "Umbra" then 0.63 elseif facet.Name == "Canopy"
			then 0.50 * self.nightLook.RimStrength else 0.70 * self.nightLook.RimStrength
		facet.Transparency = 1 - strength * amount
	end
	if self.island and self.tinted ~= tinted then
		for _, swatch in self.tint do
			swatch.part.Color = if tinted then swatch.moon else swatch.day
		end
		self.tinted = tinted
	end
	self.strength = strength
end

function Moonlight:draw(base, direction, observer, frame, level, night, heat, ash)
	self.frame = frame
	self:relight(base, frame)
	local mistAmount = if frame >= frames.flyby and frame < frames.ignition
		then level * self.nightLook.RimStrength * (1 - S.ease(frame, frames.terminal, frames.ignition)) else 0
	if mistAmount ~= self.mistAmount then
		for _, fog in self.mistImages do
			fog.image.ImageTransparency = 1 - fog.density * mistAmount
		end
		self.mistAmount = mistAmount
	end
	self.aprons.Parent = if frame >= frames.coast and frame < frames.aftermath then self.stage else nil
	if self.aprons.Parent then
		self.hazeWash.BackgroundColor3 =
			Color3.new(1, 1, 1):Lerp(hex("F2D5BF"), 0.60 * ash):Lerp(hex("FFD3AC"), 0.65 * heat)
		self.hazeSurface.Brightness = 1 + 0.20 * ash + 0.48 * heat
	end
	self.sky.Parent = if night then self.stage else nil
	if night and self.sky:GetPivot() ~= base then
		self.sky:PivotTo(base)
	end
	self.root.Parent = if level > 0.005 then self.stage else nil
	if not self.root.Parent then
		return
	end
	-- Before dawn the source moves imperceptibly. Keep the local shadow maps
	-- stable while the camera photographs light moving through the trees.
	if self.lastDirection ~= direction or self.base ~= base then
		for _, v in self.beams do
			v.mount.CFrame = base * CFrame.lookAt(v.target + direction * 42, v.target)
		end
		self.lastDirection, self.base = direction, base
	end
	for _, v in self.beams do
		v.light.Brightness = 4.6 * self.nightLook.RimStrength * level
	end
	local axis = V(direction.X, 0, direction.Z).Unit
	local across = axis:Cross(Vector3.yAxis)
	local sea = 20.3
	local glint = V(observer.X, sea + 0.39, observer.Z) + axis * ((observer.Y - sea) / math.max(0.14, direction.Y))
	for _, r in self.ripples do
		local scatter = 1 - math.abs(2 * r.n - 1)
		local pt = glint + axis * ((r.n - 0.5) * 225) + across * (r.side * (5 + 18 * scatter))
		local shimmer = 0.73 + 0.27 * math.sin(frame * 0.094 + r.phase)
		r.part.Transparency = 1 - 0.30 * self.nightLook.RimStrength * level * (0.23 + 0.61 * scatter) * (1 - 0.67 * math.abs(r.side)) * shimmer
		r.part.CFrame = base * CFrame.lookAt(pt, pt + axis)
	end
end

-- The orbit sweeps through nearly a half turn above the finite ocean. Keep
-- the aerial haze on the true level horizon as the photographic roll changes.
function Moonlight:focus(camera, base)
	local bank = self.chaseHorizon
	if self.frame < frames.flyby - 5 or self.frame >= frames.coast then
		bank.Parent = nil
		return
	end
	local eye = base:PointToObjectSpace(camera.CFrame.Position)
	local view = base:VectorToObjectSpace(camera.CFrame.LookVector)
	local bearing = V(view.X, 0, view.Z)
	if bearing.Magnitude < 0.001 then
		bank.Parent = nil
		return
	end
	bearing = bearing.Unit
	local centre = V(eye.X, eye.Y - (eye.Y - 20.3) * 0.36, eye.Z) + bearing * 410
	bank.CFrame = base * CFrame.lookAt(centre, centre - bearing)
	bank.Parent = self.stage
end

function Moonlight:Destroy()
	self.chaseHorizon:Destroy()
	self.relief:Destroy()
	self.aprons:Destroy()
	self.sky:Destroy()
	self.root:Destroy()
end

return Moonlight
