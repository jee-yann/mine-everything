local Ores = require(game.ReplicatedStorage.Shared.Ores)
local Pickaxe = {}
local socketOres = { "Coal", "Copper", "Iron", "Gold", "Diamond", "Emerald" }
-- RightGripAttachment points along the hand's tool axis. Match it at the wrapped
-- part of the shaft, with the steel head reaching forward from the palm at rest.
local tapeY = -0.54
local handleGrip = CFrame.new(0, tapeY, 0) * CFrame.Angles(0, math.rad(90), 0)
local function component(model, root, name, size, offset, color)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Color, part.Material = name, size, color, Enum.Material.Plastic
	part.Massless, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.CFrame = root.CFrame * offset
	part.Parent = model
	local joint = Instance.new("WeldConstraint")
	joint.Part0, joint.Part1, joint.Parent = root, part, part
	return part
end
function Pickaxe.equip(player, char)
	local humanoid = char:WaitForChild("Humanoid", 8)
	if not humanoid then
		return
	end
	local hand = char:WaitForChild(if humanoid.RigType == Enum.HumanoidRigType.R15 then "RightHand" else "Right Arm", 8)
	if not hand or player.Character ~= char then
		return
	end
	local existing = char:FindFirstChild("Harbor pick")
	if existing then
		local oldGrip = existing:FindFirstChild("Grip", true)
		if oldGrip and oldGrip.Part0 == hand then
			return
		end
		existing:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Harbor pick"
	local handle = Instance.new("Part")
	handle.Name, handle.Size, handle.Color = "Handle", Vector3.new(0.19, 1.9, 0.21), Color3.fromRGB(176, 106, 56)
	handle.Massless, handle.CanCollide, handle.CanTouch, handle.CanQuery = true, false, false, false
	local palm = hand:FindFirstChild("RightGripAttachment")
	local function palmOffset()
		return if palm then palm.CFrame else CFrame.new(0, -hand.Size.Y * 0.4, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
	end
	handle.CFrame = hand.CFrame * palmOffset() * handleGrip:Inverse()
	handle.Parent = model
	local pale = Color3.fromRGB(211, 234, 241)
	component(model, handle, "Steel", Vector3.new(1.05, 0.25, 0.28), CFrame.new(0, 0.95, 0), pale)
	for _, side in { -1, 1 } do
		component(
			model,
			handle,
			"Beak",
			Vector3.new(0.54, 0.19, 0.22),
			CFrame.new(side * 0.67, 0.85, 0) * CFrame.Angles(0, 0, math.rad(-side * 25)),
			pale
		)
	end
	local socket = component(
		model,
		handle,
		"Socket",
		Vector3.new(0.34, 0.42, 0.36),
		CFrame.new(0, 0.90, 0),
		Color3.fromRGB(255, 201, 72)
	)
	local tape = component(
		model,
		handle,
		"Grip tape",
		Vector3.new(0.215, 0.48, 0.23),
		CFrame.new(0, tapeY, 0),
		Color3.fromRGB(42, 67, 80)
	)
	local grip = Instance.new("Weld")
	grip.Name, grip.Part0, grip.Part1 = "Grip", hand, tape
	grip.C0, grip.C1, grip.Parent = palmOffset(), handleGrip.Rotation, handle
	local scaleChanged
	local function bindPalm()
		palm = hand:FindFirstChild("RightGripAttachment")
		if scaleChanged then
			scaleChanged:Disconnect()
		end
		grip.C0 = palmOffset()
		local changed = if palm then palm:GetPropertyChangedSignal("CFrame") else hand:GetPropertyChangedSignal("Size")
		scaleChanged = changed:Connect(function()
			grip.C0 = palmOffset()
		end)
	end
	local function attachmentChanged(child)
		if child.Name == "RightGripAttachment" then
			bindPalm()
		end
	end
	bindPalm()
	local added = hand.ChildAdded:Connect(attachmentChanged)
	local removed = hand.ChildRemoved:Connect(attachmentChanged)
	model.PrimaryPart = handle
	local tipA, tipB = Instance.new("Attachment"), Instance.new("Attachment")
	tipA.Position, tipB.Position = Vector3.new(-0.91, 0.76, 0), Vector3.new(0.91, 0.76, 0)
	tipA.Parent, tipB.Parent = handle, handle
	local trail = Instance.new("Trail")
	trail.Name, trail.Attachment0, trail.Attachment1 = "Pick arc", tipA, tipB
	trail.Lifetime, trail.LightEmission, trail.Transparency = 0.12, 0.65, NumberSequence.new(0.48, 1)
	trail.Parent = handle
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name, sparks.Texture = "First Light", "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 225, 140), Color3.fromRGB(147, 222, 255))
	sparks.LightEmission, sparks.Rate, sparks.Enabled = 0.75, 8, false
	sparks.Lifetime, sparks.Speed = NumberRange.new(0.16, 0.35), NumberRange.new(0.5, 1.8)
	sparks.Size = NumberSequence.new(0.16, 0)
	sparks.SpreadAngle, sparks.Parent = Vector2.new(65, 65), tipA
	local crystals = {}
	for _, side in { -1, 1 } do
		for i = 1, 2 do
			local facet = component(
				model,
				handle,
				"Crystal tine",
				Vector3.new(0.17, 0.7 - i * 0.08, 0.22),
				CFrame.new(side * (0.26 + i * 0.24), 1.13, 0) * CFrame.Angles(0, 0, -side * (0.25 + i * 0.18)),
				pale
			)
			facet.Material, facet.Transparency = Enum.Material.Neon, 1
			table.insert(crystals, facet)
		end
	end
	local function update()
		local level = player:GetAttribute("Power") or 1
		local tint = if level == 1 then pale else Ores.byName[socketOres[level]].color
		socket.Color = if level == 1 then Color3.fromRGB(237, 181, 82) else tint
		for i, facet in crystals do
			facet.Transparency = if level >= 5 and (level == 6 or i % 2 == 1) then 0 else 1
			facet.Color = if level == 6 and i % 2 == 0 then Color3.fromRGB(201, 156, 255) else tint:Lerp(pale, 0.38)
		end
		for _, blade in model:GetChildren() do
			if blade.Name == "Steel" or blade.Name == "Beak" then
				blade.Color = tint
				blade.Material = if level >= 5 then Enum.Material.Neon else Enum.Material.Metal
			end
		end
		trail.Color = ColorSequence.new(tint, tint:Lerp(Color3.new(1, 1, 1), 0.75))
		trail.Lifetime = 0.09 + level * 0.017
		local radiant = player:GetAttribute("FirstLight") == true
		local swinging = char:GetAttribute("MiningSwing") ~= nil
		if radiant then
			trail.Color = sparks.Color
			trail.Lifetime = 0.17
		end
		sparks.Enabled = radiant and swinging
		trail.Enabled = (radiant or level >= 3) and swinging
	end
	update()
	model.Parent = char
	local changed = player:GetAttributeChangedSignal("Power"):Connect(update)
	local swing = char:GetAttributeChangedSignal("MiningSwing"):Connect(update)
	local aura = player:GetAttributeChangedSignal("FirstLight"):Connect(update)
	model.Destroying:Once(function()
		changed:Disconnect()
		swing:Disconnect()
		aura:Disconnect()
		scaleChanged:Disconnect()
		added:Disconnect()
		removed:Disconnect()
	end)
end
return Pickaxe
