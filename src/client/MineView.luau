local Run = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local TunnelVisibility = require(script.Parent.TunnelVisibility)
local View = {}
local galleryBounce = Color3.fromRGB(100, 88, 73)
local palettes = {
	["Sunstone Hollow"] = {Color3.fromHex("261F1C"), Color3.fromHex("FFF3DF")},
	["Iron Shelf"] = {Color3.fromHex("1C222A"), Color3.fromHex("E6F0FF")},
	["Prism Grotto"] = {Color3.fromHex("222035"), Color3.fromHex("EAEBFF")},
	["Emerald Deep"] = {Color3.fromHex("152921"), Color3.fromHex("DBF9ED")},
	["Midnight Fault"] = {Color3.fromHex("20192B"), Color3.fromHex("F2E4FF")},
	["Frostglass Reach"] = {Color3.fromHex("152631"), Color3.fromHex("DEFAFF")},
}
function View.start(player, origin, hud)
	local daylight = Lighting.Ambient
	local outdoor = Lighting.OutdoorAmbient
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name, grade.Parent = "Underground light", Lighting
	local overlap = OverlapParams.new()
	overlap.FilterType, overlap.MaxParts = Enum.RaycastFilterType.Include, 1
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	local grid, shade, lastTarget, lastRegion, lastBounce = nil, 0, 0, nil, nil
	local blendTime = 0
	local previousEye, previousChar
	local tunnel, headlamp = TunnelVisibility.new(), nil
	local faded, bodyParts, nextScan = {}, {}, 0
	-- Give Roblox its own first-person transparency back before its camera update.
	Run:BindToRenderStep("Restore miner opacity", Enum.RenderPriority.Camera.Value - 1, function()
		for part, state in faded do
			if part.Parent and part.LocalTransparencyModifier == state.applied then
				part.LocalTransparencyModifier = state.base
			end
		end
		table.clear(faded)
	end)
	local function clearance(eye, radius)
		local block = workspace:GetPartBoundsInBox(CFrame.new(eye), Vector3.one * (2 * radius), overlap)[1]
		if not block then
			return eye
		end
		if
			previousEye
			and (eye - previousEye).Magnitude < 5
			and #workspace:GetPartBoundsInBox(CFrame.new(previousEye), Vector3.one * (2 * radius), overlap) == 0
		then
			return previousEye
		end
		local best, distance = nil, math.huge
		for _, face in Enum.NormalId:GetEnumItems() do
			if bit32.btest(block:GetAttribute("OpenFaces") or 0, bit32.lshift(1, face.Value)) then
				local n = Vector3.FromNormalId(face)
				local half = block.Size / 2
				local at = (eye - block.Position):Max(-half + Vector3.one * radius):Min(half - Vector3.one * radius)
				local candidate = block.Position
					+ at * (Vector3.one - n:Abs())
					+ n * (half + Vector3.one * (radius + 0.03))
				local d = (candidate - eye).Magnitude
				if
					d < distance
					and #workspace:GetPartBoundsInBox(CFrame.new(candidate), Vector3.one * (2 * radius), overlap)
						== 0
				then
					best, distance = candidate, d
				end
			end
		end
		return best or previousEye or eye
	end
	Run:BindToRenderStep("Mine enclosure", Enum.RenderPriority.Camera.Value + 2, function(dt)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		if hud.inOpening then
			-- The film lights its own set on each exposure. Its camera can
			-- cross the gameplay mine bounds during a cut or a replay.
			if grade.Enabled then
				grade.Enabled = false
				previousEye, lastTarget = nil, nil
			end
			return
		end
		if not grade.Enabled then
			grade.Enabled = true
		end
		local pos = if root then root.Position - origin else Vector3.zero
		local inside = root ~= nil and Config.inMine(pos)
		local target = if inside then math.clamp(.55 + math.max(0,-pos.Y)/85,.55,1)
			elseif root and pos.Z >= Config.HallFront and math.abs(pos.X)<10 and pos.Y < 12
			then .55*math.clamp((10-pos.Z)/16,0,1) else 0
		local region = Config.layer(Config.FloorY-pos.Y).name
		-- Reflected light from the work lamps fades over the entry floor.
		local bounce = if inside and Config.inHall(pos)
			then math.clamp(1 + (pos.Y - Config.FloorY) / (Config.Cell * Config.DirtLayers), 0, 1) else 0
		if target ~= lastTarget or region ~= lastRegion or bounce ~= lastBounce then
			blendTime, lastTarget, lastRegion, lastBounce = 1.6, target, region, bounce
		end
		if blendTime > 0 then
			blendTime -= dt
			local alpha = if blendTime <= 0 then 1 else 1-math.exp(-dt*5)
			shade += (target-shade)*alpha
			local palette = palettes[region] or palettes["Sunstone Hollow"]
			local ambient = daylight:Lerp(palette[1], target):Lerp(galleryBounce, bounce * 0.64)
			Lighting.Ambient = Lighting.Ambient:Lerp(ambient, alpha)
			-- The lamp and flare supply the foreground light. Keep distant unlit faces in shadow.
			Lighting.OutdoorAmbient = outdoor:Lerp(Color3.fromHex("242A33"), shade)
			grade.Brightness = -0.012 * shade * (1 - bounce)
			grade.Contrast += ((0.095 - 0.065 * bounce) * shade - grade.Contrast) * alpha
			grade.TintColor = grade.TintColor:Lerp(Color3.new(1,1,1):Lerp(palette[2],target*.66),alpha)
		end
		if char ~= previousChar then
			previousEye, previousChar = nil, char
			headlamp = nil
			bodyParts, nextScan = {}, 0
		end
		local head = char and char:FindFirstChild("Head")
		local depth = if inside and head and camera then origin.Y + Config.FloorY - head.Position.Y else 0
		if depth > 0 and (not headlamp or not headlamp.Parent) then
			local mount = root:FindFirstChild("Lamp mount")
			headlamp = mount and mount:FindFirstChildOfClass("PointLight")
		end
		if depth <= 0 then tunnel:restore() end
		if not root or not camera or not inside then
			previousEye = nil
			return
		end
		if not grid or not grid.Parent then
			local island = workspace:FindFirstChild("CitrineCove")
			grid = island and island:FindFirstChild("MineBlocks")
			if not grid then return end
			ray.FilterDescendantsInstances = { grid }
			overlap.FilterDescendantsInstances = { grid }
		end
		-- Keep the near clipping plane on the player's side of a solid wall.
		if not head then
			return
		end
		local near = math.abs(camera.NearPlaneZ)
		local radius = math.clamp(
			near
				* (
					1
					+ math.tan(math.rad(camera.FieldOfView / 2))
						* camera.ViewportSize.X
						/ math.max(1, camera.ViewportSize.Y)
				),
			0.4,
			1.1
		)
		local eye = clearance(head.Position, radius)
		previousEye = eye
		local view = camera.CFrame
		local delta = view.Position - eye
		local hit = if delta.Magnitude > 0.015 then workspace:Spherecast(eye, radius, delta, ray) else nil
		local point = if hit
			then eye + delta.Unit * math.max(0, hit.Distance - 0.06)
			else clearance(view.Position, radius)
		if (point - view.Position).Magnitude > 0.005 then
			camera.CFrame = view.Rotation + point
		end
		if depth > 0 then
			tunnel:update(depth, (point - head.Position).Magnitude, if headlamp then headlamp.Range else 25,
				char:GetAttribute("PickReach") or Config.Reach)
		end
		local opacity = math.clamp((4.4 - (point - head.Position).Magnitude) / 2.8, 0, 1)
		if opacity > 0 then
			if os.clock() >= nextScan then
				table.clear(bodyParts)
				for _, part in char:GetDescendants() do
					if part:IsA("BasePart") or part:IsA("Decal") then
						table.insert(bodyParts, part)
					end
				end
				nextScan = os.clock() + 0.5
			end
			for _, part in bodyParts do
				if part.Parent and part.LocalTransparencyModifier < opacity then
					local base = part.LocalTransparencyModifier
					part.LocalTransparencyModifier = opacity
					faded[part] = { base = base, applied = part.LocalTransparencyModifier }
				end
			end
		end
	end)
	-- A replay can start mid-tunnel. Hand the surface lighting back to the
	-- film before it captures its initial atmosphere and lighting properties.
	return function()
		tunnel:restore()
		Lighting.Ambient, Lighting.OutdoorAmbient = daylight, outdoor
		grade.Enabled = false
		previousEye, lastTarget, shade = nil, nil, 0
	end
end
return View
