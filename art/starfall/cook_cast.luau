-- Bakes the film's supporting cast as Roblox R15 characters. Their tools are
-- welded to the hand here, so no shot can separate a prop from its grip.
local Players = game:GetService("Players")
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local hex = Color3.fromHex
local cast = Instance.new("Folder")
cast.Name = "CoveCast"

local function piece(model, bone, name, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Color = name, size, hex(color)
	part.Material, part.Shape = material or Enum.Material.SmoothPlastic, shape or Enum.PartType.Block
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, true
	part.CFrame, part.Parent = bone.CFrame * offset, model
	local weld = Instance.new("Weld")
	weld.Name, weld.Part0, weld.Part1, weld.C0, weld.Parent = "Costume weld", bone, part, offset, part
	return part
end

local function person(name, look)
	local d = Instance.new("HumanoidDescription")
	d.HeadColor, d.TorsoColor = hex(look.skin), hex(look.skin)
	d.LeftArmColor, d.RightArmColor = hex(look.skin), hex(look.skin)
	d.LeftLegColor, d.RightLegColor = hex(look.skin), hex(look.skin)
	d.Shirt, d.Pants = look.shirt, look.pants
	d.HairAccessory = look.hair or ""
	d.HatAccessory = look.hat or ""
	d.HeightScale, d.WidthScale, d.DepthScale = look.height or 1, look.width or 1, look.width or 1
	d.HeadScale, d.BodyTypeScale, d.ProportionScale = look.headSize or 1, 0, 0
	local model = Players:CreateHumanoidModelFromDescriptionAsync(d, Enum.HumanoidRigType.R15)
	model.Name = name
	for _, item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("Sound") or item:IsA("Animator") then
			item:Destroy()
		end
	end
	local human = model:FindFirstChildOfClass("Humanoid")
	human.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	model:PivotTo(CF(0, 10, 0))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then part.Anchored = true end
	end
	model.Parent = workspace
	return model
end

-- Same construction and grip as the pick every player carries.
local function pick(model)
	local hand = model.RightHand
	local palm = hand.RightGripAttachment.CFrame
	local tapeY = -0.54
	local grip = CF(0, tapeY, 0) * A(0, math.rad(90), 0)
	local handle = piece(model, hand, "Pick handle", V(0.19, 1.9, 0.21), palm * grip:Inverse(), "B06A38", Enum.Material.Wood)
	handle["Costume weld"].Name = "Palm grip"
	local function on(n, size, at, color, material)
		return piece(model, handle, n, size, at, color, material or Enum.Material.Metal)
	end
	on("Steel", V(1.05, 0.25, 0.28), CF(0, 0.95, 0), "B7C4CB")
	for _, s in { -1, 1 } do
		on("Beak", V(0.54, 0.19, 0.22), CF(s * 0.67, 0.85, 0) * A(0, 0, math.rad(-s * 25)), "B7C4CB")
		local tip = Instance.new("Attachment")
		tip.Name, tip.Position, tip.Parent = if s < 0 then "TipA" else "TipB", V(s * 0.91, 0.76, 0), handle
	end
	on("Socket", V(0.34, 0.42, 0.36), CF(0, 0.90, 0), "E0A63E")
	on("Grip tape", V(0.215, 0.48, 0.23), CF(0, tapeY, 0), "2A4350", Enum.Material.Fabric)
end

do
	local m = person("Miner", { skin = "C98F63", shirt = 398635081, pants = 398633812, height = 1.0 })
	local torso, head = m.UpperTorso, m.Head
	local tw = torso.Size
	piece(m, torso, "Work vest", V(tw.X * 1.03, tw.Y * 0.80, tw.Z * 1.06), CF(0, -0.05, 0), "E4722F")
	for _, s in { -1, 1 } do
		piece(m, torso, "Reflective strap", V(0.2, tw.Y * 0.81, tw.Z * 1.075), CF(s * tw.X * 0.29, -0.05, 0), "F3E6B5")
	end
	piece(m, torso, "Reflective band", V(tw.X * 1.035, 0.17, tw.Z * 1.07), CF(0, -0.32, 0), "F3E6B5")
	for _, side in { "Left", "Right" } do
		local hand = m[side .. "Hand"]
		piece(m, hand, "Work glove", hand.Size * 1.08, CF(), "4A3B2E")
	end
	local crown = head.Size.Y / 2
	piece(m, head, "Hard hat shell", V(1.42, 0.86, 1.42), CF(0, crown + 0.02, 0.02), "F2B632", nil, Enum.PartType.Ball)
	piece(m, head, "Hard hat band", V(1.36, 0.2, 1.36), CF(0, crown - 0.14, 0.0), "F2B632")
	piece(m, head, "Hard hat brim", V(1.1, 0.09, 0.42), CF(0, crown - 0.15, -0.79), "DBA024")
	piece(m, head, "Lamp housing", V(0.42, 0.3, 0.2), CF(0, crown + 0.09, -0.68), "2D3942", Enum.Material.Metal)
	piece(m, head, "Headlamp", V(0.3, 0.2, 0.05), CF(0, crown + 0.09, -0.79), "FFF3C4", Enum.Material.Neon)
	pick(m)
	m.Parent = cast
end

do
	local m = person("Kid", { skin = "E8B48C", shirt = 4047884939, pants = 382537806, hair = "376524487", height = 0.9, width = 0.9 })
	m.Parent = cast
	local s = person("Sibling", { skin = "E0A97F", shirt = 398634295, pants = 398633812, hair = "62724852" })
	s.Parent = cast
end

do
	local m = person("Witness", { skin = "9A6644", shirt = 382538059, pants = 144076760, hair = "62234425" })
	local right = m.RightHand
	-- A phone. Portrait, the length of a head, thin, with a bright metal edge, a
	-- dark face and a camera block on its back. With the forearm raised the hand's
	-- -Y points away from the body and -Z is up, so the foot of it stands in the
	-- fist and the whole screen is clear. Phone space: +Z is the screen, -Z is the lens.
	local body = CF(0, -0.13, -1.08) * CFrame.fromMatrix(Vector3.zero, V(1, 0, 0), V(0, 0, -1), V(0, 1, 0))
	local W, H, D = 0.80, 1.60, 0.10
	local glass = piece(m, right, "Phone", V(W - 0.06, H - 0.06, 0.02), body * CF(0, 0, 0.04), "0A0D12", Enum.Material.SmoothPlastic)
	glass["Costume weld"].Name = "Phone grip"
	glass.Transparency = 1
	local function trim(name, size, at, color, material, shape)
		return piece(m, glass, name, size, at * CF(0, 0, -0.04), color, material, shape)
	end
	local edge, r = "C9CFD8", 0.10
	local metal = Enum.Material.Metal
	trim("Phone edge", V(W - 2 * r, 0.05, D), CF(0, H / 2 - 0.025, 0), edge, metal)
	trim("Phone edge", V(W - 2 * r, 0.05, D), CF(0, -H / 2 + 0.025, 0), edge, metal)
	trim("Phone edge", V(0.05, H - 2 * r, D), CF(W / 2 - 0.025, 0, 0), edge, metal)
	trim("Phone edge", V(0.05, H - 2 * r, D), CF(-W / 2 + 0.025, 0, 0), edge, metal)
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for k = 0, 2 do
				local a = math.rad(15 + 30 * k)
				local at = CF(x * (W / 2 - r + math.cos(a) * (r - 0.025)), y * (H / 2 - r + math.sin(a) * (r - 0.025)), 0)
				trim("Phone corner", V(0.05, 0.062, D), at * A(0, 0, math.atan2(y * math.sin(a), x * math.cos(a))), edge, metal)
			end
		end
	end
	trim("Phone key", V(0.03, 0.26, 0.045), CF(W / 2 + 0.01, 0.30, 0), "9AA3AF", metal)
	trim("Phone key", V(0.03, 0.12, 0.045), CF(-W / 2 - 0.01, 0.50, 0), "9AA3AF", metal)
	trim("Phone key", V(0.03, 0.12, 0.045), CF(-W / 2 - 0.01, 0.34, 0), "9AA3AF", metal)
	-- The dark face round the picture is solid, so it is there before its app is.
	local tall = H - 0.06
	local function bezel(size, at)
		return piece(m, glass, "Phone face", size, at * CF(0, 0, -0.012), "07080C", Enum.Material.Neon)
	end
	bezel(V(W - 0.12, tall * 0.105, 0.012), CF(0, tall * 0.4475, 0))
	bezel(V(W - 0.12, tall * 0.205, 0.012), CF(0, -tall * 0.3975, 0))
	for _, x in { -1, 1 } do
		bezel(V(0.04, tall - 0.06, 0.012), CF(x * (W / 2 - 0.05), 0, 0))
	end
	trim("Phone back", V(W - 0.06, H - 0.06, 0.03), CF(0, 0, -0.035), "5B4B8A")
	trim("Camera block", V(0.40, 0.40, 0.06), CF(0.17, H / 2 - 0.28, -0.075), "40356A")
	local round = A(0, math.rad(90), 0)
	for _, p in { { 0.07, 0.09 }, { 0.07, -0.09 }, { -0.10, 0.09 } } do
		local at = CF(0.17 + p[1], H / 2 - 0.28 + p[2], -0.12)
		trim("Phone lens", V(0.06, 0.17, 0.17), at * round, "B9C0CC", metal, Enum.PartType.Cylinder)
		trim("Phone lens", V(0.07, 0.13, 0.13), at * round, "05070B", Enum.Material.Glass, Enum.PartType.Cylinder)
	end
	trim("Phone lamp", V(0.05, 0.08, 0.08), CF(0.07, H / 2 - 0.37, -0.11) * round, "FFF4D6", Enum.Material.Neon, Enum.PartType.Cylinder)
	-- Fingers round the back, the thumb along the near edge. They stop short of
	-- the picture.
	local skin = "9A6644"
	for k = 0, 2 do
		piece(m, right, "Finger", V(0.50, 0.12, 0.16), CF(0.16, -0.27, -0.38 - k * 0.19), skin)
	end
	piece(m, right, "Finger wrap", V(0.13, 0.26, 0.56), CF(0.46, -0.15, -0.56), skin)
	piece(m, right, "Thumb", V(0.14, 0.14, 0.52), CF(-0.44, -0.04, -0.46) * A(0, math.rad(8), 0), skin)
	m.Parent = cast
end

for _, model in cast:GetChildren() do
	print("CAST_MODEL", model.Name, #model:GetDescendants(), model.RightUpperArm.Size, model.RightLowerArm.Size,
		model.RightHand.Size, model.UpperTorso.Size, model.LeftUpperLeg.Size, model.LeftLowerLeg.Size,
		model.RightHand.RightGripAttachment.CFrame)
	for _, j in model:GetDescendants() do
		if j:IsA("Motor6D") or j:IsA("AnimationConstraint") then print("CAST_JOINT", model.Name, j.ClassName, j.Name) break end
	end
end
local bin = game:GetService("SerializationService"):SerializeInstancesAsync({ cast })
local bytes = buffer.tostring(game:GetService("EncodingService"):Base64Encode(bin))
for i = 1, #bytes, 2000 do print("CAST_DATA", bytes:sub(i, i + 1999)) end
print("CAST_READY")
