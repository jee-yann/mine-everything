-- The lunar key is at grazing incidence. Sample its parallel rays at the
-- terraces so the distant offshore camera can read individual cliff faces.
local S = require(script.Parent.Scenery)
local V, CF, hex = Vector3.new, CFrame.new, Color3.fromHex
local Moonlight = {}
Moonlight.__index = Moonlight

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
local function nightSky()
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
		gui.Face, gui.LightInfluence, gui.Brightness = Enum.NormalId.Front, 0, 1
		gui.SizingMode, gui.CanvasSize, gui.Parent = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(640, 960), panel
		local face = Instance.new("Frame")
		face.Size, face.BorderSizePixel, face.BackgroundColor3, face.Parent =
			UDim2.fromScale(1, 1), 0, hex(if roof then "141F38" else "FFFFFF"), gui
		if not roof then
			local gradient = Instance.new("UIGradient")
			gradient.Rotation = 90
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, hex("141F38")),
				ColorSequenceKeypoint.new(0.62, hex("182942")),
				ColorSequenceKeypoint.new(0.73, hex("2B3F5B")),
				ColorSequenceKeypoint.new(0.79, hex("495873")),
				ColorSequenceKeypoint.new(0.82, hex("2F4262")),
				ColorSequenceKeypoint.new(1, hex("253955")),
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

function Moonlight.new(stage)
	local root = S.group("Moonlight on Citrine Cove")
	local beams = {}
	for i, target in shelves do
		local mount = S.part(root, "Lunar key", CF(), Vector3.one * 0.1, "FFFFFF")
		mount.Transparency, mount.CastShadow = 1, false
		local key = Instance.new("SpotLight")
		key.Name, key.Face, key.Angle, key.Range = "Light along the ledge", Enum.NormalId.Front, 103, 60
		key.Color = hex(if i < 4 then "BEDAFF" else "92BDF8")
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
			"Silver water",
			CF(),
			V(rand:NextNumber(2.0, 12) * (0.6 + n), 0.035, rand:NextNumber(0.27, 0.81)),
			"B5D0EE",
			Enum.Material.Neon
		)
		part.CastShadow = false
		table.insert(ripples, { part = part, n = n, side = rand:NextNumber(-1, 1), phase = rand:NextNumber(0, 6.28) })
	end
	return setmetatable({ stage = stage, root = root, sky = nightSky(), beams = beams, ripples = ripples }, Moonlight)
end

function Moonlight:draw(base, direction, observer, frame, level, night)
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
	if self.direction ~= direction or self.base ~= base then
		for _, v in self.beams do
			v.mount.CFrame = base * CFrame.lookAt(v.target + direction * 39, v.target)
		end
		self.direction, self.base = direction, base
	end
	for _, v in self.beams do
		v.light.Brightness = 3.8 * level
	end
	local axis = V(direction.X, 0, direction.Z).Unit
	local across = axis:Cross(Vector3.yAxis)
	local sea = 20.3
	local glint = V(observer.X, sea + 0.39, observer.Z) + axis * ((observer.Y - sea) / math.max(0.14, direction.Y))
	for _, r in self.ripples do
		local scatter = 1 - math.abs(2 * r.n - 1)
		local pt = glint + axis * ((r.n - 0.5) * 225) + across * (r.side * (5 + 18 * scatter))
		local shimmer = 0.73 + 0.27 * math.sin(frame * 0.094 + r.phase)
		r.part.Transparency = 1 - level * (0.23 + 0.61 * scatter) * (1 - 0.67 * math.abs(r.side)) * shimmer
		r.part.CFrame = base * CFrame.lookAt(pt, pt + axis)
	end
end

function Moonlight:Destroy()
	self.sky:Destroy()
	self.root:Destroy()
end

return Moonlight
