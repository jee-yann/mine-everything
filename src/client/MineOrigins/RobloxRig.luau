local P = require(script.Parent.Props)
local Rig = {}
Rig.__index = Rig
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local id = CFrame.identity

-- Parent first: both Motor6D avatars and the newer attachment-based avatars
-- can be posed from the same anatomical pivots without playing an uploaded clip.
local r6 = {
	{ "RootJoint", "HumanoidRootPart", "Torso" },
	{ "Neck", "Torso", "Head" },
	{ "Left Shoulder", "Torso", "Left Arm" },
	{ "Right Shoulder", "Torso", "Right Arm" },
	{ "Left Hip", "Torso", "Left Leg" },
	{ "Right Hip", "Torso", "Right Leg" },
}
local r15 = {
	{ "Root", "HumanoidRootPart", "LowerTorso" },
	{ "Waist", "LowerTorso", "UpperTorso" },
	{ "Neck", "UpperTorso", "Head" },
	{ "LeftShoulder", "UpperTorso", "LeftUpperArm" },
	{ "LeftElbow", "LeftUpperArm", "LeftLowerArm" },
	{ "LeftWrist", "LeftLowerArm", "LeftHand" },
	{ "RightShoulder", "UpperTorso", "RightUpperArm" },
	{ "RightElbow", "RightUpperArm", "RightLowerArm" },
	{ "RightWrist", "RightLowerArm", "RightHand" },
	{ "LeftHip", "LowerTorso", "LeftUpperLeg" },
	{ "LeftKnee", "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftAnkle", "LeftLowerLeg", "LeftFoot" },
	{ "RightHip", "LowerTorso", "RightUpperLeg" },
	{ "RightKnee", "RightUpperLeg", "RightLowerLeg" },
	{ "RightAnkle", "RightLowerLeg", "RightFoot" },
}

local function classic(name, playerStandIn, workwear)
	local model = P.model(nil, name)
	local coat = if workwear then workwear.shirt elseif playerStandIn then "2188A2" else "FF7740"
	local skin = if workwear then workwear.skin elseif playerStandIn then "EDB87D" else "FABE61"
	local root = P.box(model, "HumanoidRootPart", Vector3.zero, V(2, 2, 1), coat)
	root.Transparency = 1
	local torso = P.box(model, "Torso", Vector3.zero, V(2, 2, 1), coat)
	local head = P.box(model, "Head", V(0, 1.5, 0), V(2, 1, 1), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Scale, mesh.Parent = Enum.MeshType.Head, V(1.25, 1.25, 1.25), head
	local smile = Instance.new("Decal")
	smile.Name, smile.Face, smile.Texture, smile.Parent =
		"face", Enum.NormalId.Front, "rbxasset://textures/face.png", head
	for _, side in { "Left", "Right" } do
		local s = if side == "Left" then -1 else 1
		P.box(model, side .. " Arm", V(1.5 * s, 0, 0), V(1, 2, 1), skin)
		P.box(model, side .. " Leg", V(0.5 * s, -2, 0), V(1, 2, 1), "29445D")
	end
	-- The six standard R6 joints have their pivots at the neck, shoulders and hips.
	local pivots = { Vector3.zero, V(0, 1, 0), V(-1.5, 0.7, 0), V(1.5, 0.7, 0), V(-0.5, -1, 0), V(0.5, -1, 0) }
	for i, link in r6 do
		local parent, child = model[link[2]], model[link[3]]
		local joint = Instance.new("Motor6D")
		joint.Name, joint.Part0, joint.Part1 = link[1], parent, child
		joint.C0, joint.C1 = CF(pivots[i] - parent.Position), CF(pivots[i] - child.Position)
		joint.Parent = parent
	end
	local function trim(body, part)
		local weld = Instance.new("Weld")
		weld.Name, weld.Part0, weld.Part1, weld.C0, weld.Parent =
			"Wardrobe weld", body, part, body.CFrame:ToObjectSpace(part.CFrame), part
		return part
	end
	trim(torso, P.box(model, "Utility vest", V(0, 0, -0.02), V(2.05, 1.88, 1.04), coat))
	for _, s in { -1, 1 } do
		if not workwear then
			trim(torso, P.box(model, "Reflective strap", V(s * 0.55, 0.12, -0.56), V(0.19, 1.51, 0.055), "F9E7AC"))
		end
		trim(torso, P.box(model, "Vest pocket", V(s * 0.54, -0.50, -0.58), V(0.48, 0.41, 0.13), "334955"))
		trim(
			model[if s == -1 then "Left Arm" else "Right Arm"],
			P.box(model, "Short sleeve", V(s * 1.50, 0.61, 0), V(1.025, 0.78, 1.025), coat)
		)
		trim(
			model[if s == -1 then "Left Leg" else "Right Leg"],
			P.box(model, "Work boot", V(s * 0.5, -2.75, -0.10), V(1.035, 0.50, 1.2), "253343")
		)
	end
	local hat = if workwear then workwear.cap elseif playerStandIn then "57DDD0" else "FFD151"
	trim(head, P.sphere(model, if workwear then "Cap crown" else "Hard hat shell", V(0, 2, 0), V(1.63, 0.85, 1.33), hat))
	trim(head, P.box(model, if workwear then "Cap brim" else "Hard hat brim", V(0, 1.85, -0.075), V(1.80, 0.11, 1.52), hat))
	if workwear then
		trim(torso, P.box(model, "Canvas belt", V(0, -0.76, 0), V(2.09, 0.17, 1.08), "674E40"))
		trim(torso, P.box(model, "Neckerchief", V(0, 0.89, -0.06), V(1.05, 0.28, 1.04), hat))
	else
		trim(torso, P.box(model, "Reflective belt", V(0, -0.13, -0.02), V(2.10, 0.14, 1.09), "EACD79"))
	end
	if not workwear or workwear.lamp then
		trim(head, P.box(model, "Lamp housing", V(0, 2.02, -0.61), V(0.48, 0.32, 0.20), "233949"))
		local lens = trim(head, P.box(model, "Headlamp", V(0, 2.03, -0.73), V(0.32, 0.22, 0.07), "FFF1B4", nil, Enum.Material.Neon))
		if not workwear then P.light(lens, "FFDA9A", 5, 0.42) end
	end
	local human = Instance.new("Humanoid")
	human.RigType = Enum.HumanoidRigType.R6
	human.RequiresNeck, human.EvaluateStateMachine, human.DisplayDistanceType =
		false, false, Enum.HumanoidDisplayDistanceType.None
	human.Parent = model
	model.PrimaryPart = root
	return model
end

local function duplicate(character)
	if not character or not character:FindFirstChild("Head") then
		return nil
	end
	local archivable = character.Archivable
	character.Archivable = true
	local ok, copy = pcall(character.Clone, character)
	character.Archivable = archivable
	if not ok or not copy then
		return nil
	end
	for _, p in copy:GetDescendants() do
		if
			p:IsA("LuaSourceContainer")
			or p:IsA("Animator")
			or p:IsA("Tool")
			or p:IsA("LayerCollector")
			or p:IsA("Sound")
			or p:IsA("Light")
			or p:IsA("ParticleEmitter")
			or p:IsA("Beam")
			or p:IsA("Trail")
			or p:IsA("Highlight")
			or p:IsA("ForceField")
			or p:IsA("BodyMover")
			or p.Name == "Harbor pick"
			or p.Name == "Prospector kit"
			or p.Name == "Head clearance"
		then
			p:Destroy()
		elseif p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
			p.LocalTransparencyModifier = 0
		end
	end
	local human = copy:FindFirstChildOfClass("Humanoid")
	if
		not human
		or not copy:FindFirstChild("HumanoidRootPart")
		or not (copy:FindFirstChild("Torso") or copy:FindFirstChild("UpperTorso"))
	then
		copy:Destroy()
		return nil
	end
	human.RequiresNeck, human.EvaluateStateMachine, human.DisplayDistanceType =
		false, false, Enum.HumanoidDisplayDistanceType.None
	return copy
end

local function wardrobe(model, body)
	local mounts, binding, pieces = {}, {}, {}
	for bone in body do
		for _, a in bone:GetChildren() do
			if a:IsA("Attachment") then
				mounts[a.Name] = a
			end
		end
	end
	-- A copied accessory's world transform can be a frame behind its joint,
	-- particularly while the local avatar is loading. Use its actual mount.
	for _, joint in model:GetDescendants() do
		local a, b, c0, c1
		if joint:IsA("JointInstance") or joint:IsA("WeldConstraint") then
			a, b = joint.Part0, joint.Part1
			if joint:IsA("JointInstance") then
				c0, c1 = joint.C0, joint.C1
			end
		elseif joint:IsA("RigidConstraint") then
			local aa, bb = joint.Attachment0, joint.Attachment1
			if aa and bb then
				a, b, c0, c1 = aa.Parent, bb.Parent, aa.CFrame, bb.CFrame
			end
		end
		if a and b and not body[a] and body[b] then
			a, b, c0, c1 = b, a, c1, c0
		end
		if a and b and body[a] and not body[b] then
			binding[b] =
				{ part = b, bone = a, offset = if c0 then c0 * c1:Inverse() else a.CFrame:ToObjectSpace(b.CFrame) }
		end
		if joint:IsA("Constraint") or joint:IsA("WeldConstraint") or joint:IsA("JointInstance") then
			joint.Enabled = false
		end
	end
	for _, item in model:GetChildren() do
		if not item:IsA("Accoutrement") then
			continue
		end
		local handle = item:FindFirstChild("Handle")
		if not handle or not handle:IsA("BasePart") then
			continue
		end
		for _, a in handle:GetChildren() do
			local mount = mounts[a.Name]
			if a:IsA("Attachment") and mount then
				binding[handle] = { part = handle, bone = mount.Parent, offset = mount.CFrame * a.CFrame:Inverse() }
				break
			end
		end
		if not binding[handle] then
			local crown = model.Head:FindFirstChild("HatAttachment")
			local hat = if crown then crown.CFrame else CF(0, model.Head.Size.Y / 2, 0)
			binding[handle] = { part = handle, bone = model.Head, offset = hat * item.AttachmentPoint:Inverse() }
		end
		for _, p in item:GetDescendants() do
			if p:IsA("BasePart") and p ~= handle and not binding[p] then
				table.insert(pieces, { part = p, bone = handle, offset = handle.CFrame:ToObjectSpace(p.CFrame) })
			end
		end
	end
	local dress = {}
	for _, d in binding do
		table.insert(dress, d)
	end
	for _, d in pieces do
		table.insert(dress, d)
	end
	return dress
end

function Rig.new(parent, name, character, playerStandIn, workwear)
	local model = duplicate(character) or classic(name, playerStandIn, workwear)
	model.Name = name
	local root = model.HumanoidRootPart
	model.PrimaryPart = root
	local modern = model:FindFirstChild("UpperTorso") ~= nil
	local self = setmetatable({ model = model, root = root, links = {}, byName = {}, dress = {}, height = 3 }, Rig)
	local body = { [root] = true }
	for _, d in (if modern then r15 else r6) do
		local a, b = model:FindFirstChild(d[2]), model:FindFirstChild(d[3])
		if not a or not b then
			continue
		end
		local motor = model:FindFirstChild(d[1], true)
		local c0, c1
		if motor and motor:IsA("Motor6D") then
			c0, c1 = motor.C0, motor.C1
			motor.Enabled = false
		else
			local joint = d[1] .. "RigAttachment"
			local left, right = a:FindFirstChild(joint), b:FindFirstChild(joint)
			if left and right then
				c0, c1 = left.CFrame, right.CFrame
			else
				c0, c1 = a.CFrame:ToObjectSpace(b.CFrame), id
			end
			if motor and motor:IsA("AnimationConstraint") then
				motor.Enabled = false
			end
		end
		local nameKey = d[1]:gsub(" ", "")
		local link = { name = nameKey, a = a, b = b, c0 = c0, c1 = c1 }
		body[b], self.byName[nameKey] = true, link
		table.insert(self.links, link)
	end
	self.dress = wardrobe(model, body)
	self.head = model.Head
	self.hand = {
		Left = model:FindFirstChild("LeftHand") or model:FindFirstChild("Left Arm"),
		Right = model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm"),
	}
	self.modern = modern
	self:pose(id, {})
	local minY = math.huge
	for _, n in (if modern then { "LeftFoot", "RightFoot" } else { "Left Leg", "Right Leg" }) do
		local foot = model:FindFirstChild(n)
		if foot then
			minY = math.min(minY, foot.Position.Y - foot.Size.Y / 2)
		end
	end
	if minY < math.huge then
		self.height = math.max(1, self.height - minY)
		local height = self.head.Position.Y + self.head.Size.Y / 2 - minY
		local span = 0
		for p in body do
			span = math.max(span, math.abs(p.Position.X) * 2 + p.Size.X)
		end
		local k = math.min(math.clamp(height, 4.45, 5.80) / math.max(0.1, height), 5.1 / math.max(0.1, span))
		if math.abs(k - 1) > 0.01 then
			model:ScaleTo(model:GetScale() * k)
			for _, link in self.links do
				link.c0 = link.c0.Rotation + link.c0.Position * k
				link.c1 = link.c1.Rotation + link.c1.Position * k
			end
			for _, item in self.dress do
				item.offset = item.offset.Rotation + item.offset.Position * k
			end
			self.height *= k
		end
	end
	self:pose(id, {})
	local crown = self.head.Position.Y + self.head.Size.Y * 0.5
	local high = crown
	for _, d in self.dress do
		if d.bone == self.head then
			local p = d.part
			local cf, size = p.CFrame, p.Size
			local radius = (
				math.abs(cf.RightVector.Y) * size.X
				+ math.abs(cf.UpVector.Y) * size.Y
				+ math.abs(cf.LookVector.Y) * size.Z
			) * 0.5
			high = math.max(high, cf.Y + radius)
		end
	end
	self.headroom = math.clamp(high - crown, 0, 2.4)
	model.Parent = parent
	return self
end

local function align(link, target)
	local at = link.a.CFrame * link.c0
	local delta = target - at.Position
	if delta.Magnitude < 0.001 then
		return
	end
	local down = (at * link.c1:Inverse()).UpVector * -1
	local rotation = CFrame.fromRotationBetweenVectors(down, delta.Unit)
	link.b.CFrame = CF(at.Position) * rotation * at.Rotation * link.c1:Inverse()
end

function Rig:pose(floor, pose)
	self.root.CFrame = floor * CF(0, self.height + (pose.bob or 0), 0)
	for _, link in self.links do
		local a, c0 = link.a.CFrame, link.c0
		local angle = pose[link.name] or id
		link.b.CFrame = a * CF(c0.Position) * angle * c0.Rotation * link.c1:Inverse()
		for _, side in { "Left", "Right" } do
			local target = pose[side .. "Target"]
			if target and link.name == side .. "Shoulder" then
				local elbow = self.byName[side .. "Elbow"]
				if elbow then
					local start = (a * c0).Position
					local dir = target - start
					if dir.Magnitude > 0.01 then
						local upper = (link.c1.Position - elbow.c0.Position).Magnitude
						local wrist = self.byName[side .. "Wrist"]
						local lower = if wrist
							then (elbow.c1.Position - wrist.c0.Position).Magnitude + self.hand[side].Size.Y * 0.45
							else upper
						local length = math.clamp(dir.Magnitude, 0.02, math.max(0.02, upper + lower - 0.001))
						local along =
							math.clamp((upper * upper - lower * lower + length * length) / (2 * length), -upper, upper)
						local bend = floor:VectorToWorldSpace(V(if side == "Left" then -0.85 else 0.85, -0.50, 0.44))
						local out = bend - dir.Unit * bend:Dot(dir.Unit)
						local mid = start
							+ dir.Unit * along
							+ out
								* math.sqrt(math.max(0, upper * upper - along * along))
								/ math.max(0.001, out.Magnitude)
						align(link, mid)
					end
				else
					align(link, target)
				end
			elseif target and (link.name == side .. "Elbow" or link.name == side .. "Wrist") then
				align(link, target)
			end
		end
	end
	for _, d in self.dress do
		d.part.CFrame = d.bone.CFrame * d.offset
	end
end

function Rig:palm(side)
	local hand = self.hand[side]
	if not hand then
		return self.root.Position
	end
	return (hand.CFrame * CF(0, -hand.Size.Y * (if self.modern then 0.2 else 0.40), 0)).Position
end
return Rig
