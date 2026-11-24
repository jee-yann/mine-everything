-- A photographable copy of the equipped character. Each exposure solves the
-- rig from its joint sockets. Animation, physics and the camera never write
-- to the same rendered limb between exposures.
local Avatar = {}
Avatar.__index = Avatar
local identity = CFrame.identity

local function pairChildren(source, copy, live, visibleAlpha)
	local matches = {}
	for _, child in source:GetChildren() do
		if child.Archivable then
			local key = child.ClassName .. ":" .. child.Name
			matches[key] = matches[key] or {}
			table.insert(matches[key], child)
		end
	end
	for _, child in copy:GetChildren() do
		local list = matches[child.ClassName .. ":" .. child.Name]
		local original = list and table.remove(list, 1)
		if original then
			if child:IsA("BasePart") then
				live[child] = original
			end
			if visibleAlpha and (child:IsA("BasePart") or child:IsA("Decal")) then
				child.Transparency = visibleAlpha(original)
			end
			pairChildren(original, child, live, visibleAlpha)
		end
	end
end

local function bind(graph, a, b, c0, c1, name)
	if not graph[a] or not graph[b] or a == b then
		return
	end
	local link = { a = a, b = b, c0 = c0, c1 = c1, name = name }
	table.insert(graph[a], link)
	table.insert(graph[b], link)
end

local function sockets(item, graph)
	if item:IsA("JointInstance") then
		bind(graph, item.Part0, item.Part1, item.C0, item.C1, if item:IsA("Motor6D") then item.Name else nil)
		item.Enabled = false
	elseif item:IsA("AnimationConstraint") or item:IsA("RigidConstraint") then
		local a, b = item.Attachment0, item.Attachment1
		if a and b then
			local p, q = a:FindFirstAncestorWhichIsA("BasePart"), b:FindFirstAncestorWhichIsA("BasePart")
			if p and q then
				bind(
					graph,
					p,
					q,
					p.CFrame:ToObjectSpace(a.WorldCFrame),
					q.CFrame:ToObjectSpace(b.WorldCFrame),
					if item:IsA("AnimationConstraint") then item.Name else nil
				)
			end
		end
		item.Enabled = false
	elseif item:IsA("WeldConstraint") then
		local a, b = item.Part0, item.Part1
		if a and b then
			bind(graph, a, b, a.CFrame:ToObjectSpace(b.CFrame), identity)
		end
		item.Enabled = false
	elseif item:IsA("Constraint") then
		item.Enabled = false
	end
end

function Avatar.new(character, visibleAlpha)
	local old = character.Archivable
	character.Archivable = true
	local model = character:Clone()
	character.Archivable = old
	assert(model, "Could not copy the equipped miner")
	local live = {}
	pairChildren(character, model, live, visibleAlpha)
	model.Name = "Cinematic miner"
	local root = assert(model:FindFirstChild("HumanoidRootPart"))
	local human = model:FindFirstChildOfClass("Humanoid")
	if human then
		human.RequiresNeck, human.BreakJointsOnDeath = false, false
		human.AutoRotate, human.EvaluateStateMachine, human.AutomaticScalingEnabled = false, false, false
		human.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	for _, obj in model:GetDescendants() do
		if
			obj:IsA("LuaSourceContainer")
			or obj:IsA("Animator")
			or obj:IsA("IKControl")
			or obj:IsA("Sound")
			or obj:IsA("AudioPlayer")
			or obj:IsA("BillboardGui")
			or obj:IsA("ForceField")
		then
			obj:Destroy()
		elseif obj:IsA("BasePart") then
			obj.Anchored, obj.CanQuery, obj.CanCollide, obj.CanTouch = true, false, false, false
			obj.LocalTransparencyModifier = 0
			-- Humanoid initializes its torso collision volumes on insertion.
			-- A photographic rig must never push the live player off their mark.
			obj:GetPropertyChangedSignal("CanCollide"):Connect(function()
				if obj.CanCollide then
					obj.CanCollide = false
				end
			end)
		elseif obj:IsA("Decal") then
			obj.LocalTransparencyModifier = 0
		elseif
			obj:IsA("ParticleEmitter")
			or obj:IsA("Beam")
			or obj:IsA("Trail")
			or obj:IsA("Light")
			or obj:IsA("Fire")
			or obj:IsA("Smoke")
			or obj:IsA("Sparkles")
			or obj:IsA("Highlight")
		then
			obj.Enabled = false
		end
	end
	local scale = character:GetAttribute("SurfaceScale")
	if typeof(scale) == "number" and scale > 0 then
		model:ScaleTo(scale)
	end
	local graph, items = {}, model:GetDescendants()
	for _, item in items do
		if item:IsA("BasePart") then
			graph[item] = {}
		end
	end
	for _, item in items do
		sockets(item, graph)
	end

	local parts, bones, indices, channels = { root }, {}, { [root] = 1 }, {}
	local function attach(child, at, c0, c1, name, reverse)
		local bone = { parent = at, c0 = c0, inverse = c1:Inverse(), pose = identity, reverse = reverse }
		local index = #parts + 1
		bone.index, bone.part = index, child
		indices[child], parts[index], bones[index] = index, child, bone
		if name then
			channels[name:gsub(" ", "")] = bone
		end
	end
	local index = 1
	while index <= #parts do
		local part = parts[index]
		for _, edge in graph[part] do
			if not indices[edge.b] then
				attach(edge.b, index, edge.c0, edge.c1, edge.name, false)
			elseif not indices[edge.a] then
				attach(edge.a, index, edge.c1, edge.c0, edge.name, true)
			end
		end
		index += 1
	end
	-- Some local equipment has decorative anchored parts with no joint.
	-- Carry those along with their handle, or the nearest dressed body part.
	for part in graph do
		if not indices[part] then
			local accessory = part:FindFirstAncestorWhichIsA("Accessory") or part:FindFirstAncestorWhichIsA("Tool")
			local parent = accessory and accessory:FindFirstChild("Handle")
			if not parent or not indices[parent] then
				local best = math.huge
				parent = root
				for _, body in model:GetChildren() do
					if body:IsA("BasePart") and indices[body] then
						local distance = (part.Position - body.Position).Magnitude
						if distance < best then
							best, parent = distance, body
						end
					end
				end
			end
			attach(part, indices[parent], parent.CFrame:ToObjectSpace(part.CFrame), identity)
		end
	end
	local self = setmetatable({
		model = model,
		root = root,
		parts = parts,
		bones = bones,
		live = live,
		channels = channels,
		indices = indices,
		world = table.create(#parts),
		source = character,
	}, Avatar)
	self:place(root.CFrame)
	-- The neutral stance, relative to the root. Feet plant against it.
	self.rest = {}
	for i, part in parts do
		self.rest[part] = root.CFrame:ToObjectSpace(self.world[i])
	end
	self.modern = model:FindFirstChild("UpperTorso") ~= nil
	local sole = math.huge
	for _, name in { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" } do
		local foot = model:FindFirstChild(name)
		if foot and self.rest[foot] then
			sole = math.min(sole, self.rest[foot].Y - foot.Size.Y * 0.5)
		end
	end
	self.stand = if sole < math.huge then -sole else 3
	return self
end

function Avatar:turn(name, x, y, z)
	local bone = self.channels[name]
	if bone then
		local axes = bone.c0.Rotation
		bone.pose = axes:Inverse() * CFrame.Angles(math.rad(x), math.rad(y), math.rad(z)) * axes
	end
end

function Avatar:reset()
	for _, bone in self.channels do
		bone.pose = identity
	end
end

-- Two-bone solve. The end socket lands on the goal, or straightens toward it.
-- Every limb starts from its neutral twist, so joints keep their natural hinge.
function Avatar:limb(upper, lower, tip, goal, pole, base)
	local a, b, c = self.channels[upper], self.channels[lower], self.channels[tip]
	if not a or not b or not c then
		return false
	end
	a.pose, b.pose = identity, identity
	local start = self:jointFrame(upper, base).Position
	local elbow, wrist = b.c0.Position, c.c0.Position
	local first = (elbow - a.inverse:Inverse().Position).Magnitude
	local second = (wrist - b.inverse:Inverse().Position).Magnitude
	local toward = goal - start
	if toward.Magnitude < 0.001 then
		return false
	end
	local reach = math.clamp(toward.Magnitude, math.abs(first - second) + 0.01, first + second - 0.005)
	local dir = toward.Unit
	local along = (first * first - second * second + reach * reach) / (2 * reach)
	local out = pole - dir * pole:Dot(dir)
	out = if out.Magnitude > 0.001 then out.Unit else Vector3.zero
	local bend = start + dir * along + out * math.sqrt(math.max(0, first * first - along * along))
	self:aim(upper, a.part, elbow, bend, base, 1)
	self:aim(lower, b.part, wrist, start + dir * reach, base, 1)
	return true
end

-- Face a hand or foot in a world direction without moving its socket.
function Avatar:orient(name, rotation, base)
	local bone = self.channels[name]
	if not bone then
		return
	end
	local socket = self:jointFrame(name, base).Rotation
	local pose = socket:Inverse() * rotation.Rotation * bone.inverse:Inverse().Rotation
	bone.pose = if bone.reverse then pose:Inverse() else pose
end

-- Carry a limb's last part to a whole CFrame. Used for planted feet and for
-- hands that must meet a held object.
function Avatar:carry(upper, lower, tip, frame, pole, base)
	local bone = self.channels[tip]
	if bone and self:limb(upper, lower, tip, frame * bone.inverse:Inverse().Position, pole, base) then
		self:orient(tip, frame, base)
		return true
	end
	return false
end

local function relativePose(bone)
	return bone.c0 * (if bone.reverse then bone.pose:Inverse() else bone.pose) * bone.inverse
end

-- Evaluate just one chain before the whole character is photographed.
-- This lets the real welded tool and hand sockets drive a contact pose.
local function frameOf(rig, index, base)
	if index == 1 then
		return base
	end
	local bone = rig.bones[index]
	return frameOf(rig, bone.parent, base) * relativePose(bone)
end

function Avatar:partFrame(part, base)
	local index = self.indices[part]
	return if index then frameOf(self, index, base) else nil
end

function Avatar:jointFrame(name, base)
	local bone = self.channels[name]
	return if bone then frameOf(self, bone.parent, base) * bone.c0 else nil
end

function Avatar:aim(name, part, point, goal, base, amount, roll)
	local bone = self.channels[name]
	local socket = self:jointFrame(name, base)
	local held = self:partFrame(part, base)
	if not socket or not held or amount <= 0 then
		return
	end
	local current = socket:PointToObjectSpace(held * point)
	local target = socket:PointToObjectSpace(goal)
	if current.Magnitude < 0.001 or target.Magnitude < 0.001 then
		return
	end
	local delta = CFrame.fromRotationBetweenVectors(current.Unit, target.Unit)
	if roll and roll ~= 0 then
		-- Turn the hand about its reach, keeping its point of contact fixed.
		delta = CFrame.fromAxisAngle(target.Unit, roll) * delta
	end
	local correction = if amount >= 1 then delta else identity:Lerp(delta, amount)
	bone.pose = if bone.reverse then bone.pose * correction:Inverse() else correction * bone.pose
end

function Avatar:place(base, toLive, offset)
	local positions = self.world
	positions[1] = base
	for i = 2, #self.parts do
		local bone = self.bones[i]
		positions[i] = positions[bone.parent] * relativePose(bone)
	end
	if toLive and toLive > 0 then
		for i, part in self.parts do
			local original = self.live[part]
			if original and original:IsDescendantOf(self.source) then
				positions[i] = positions[i]:Lerp(original.CFrame + offset, toLive)
			end
		end
	end
	if self.model:IsDescendantOf(workspace) then
		workspace:BulkMoveTo(self.parts, positions, Enum.BulkMoveMode.FireCFrameChanged)
	else
		for i, part in self.parts do
			part.CFrame = positions[i]
		end
	end
end

function Avatar:destroy()
	self.model:Destroy()
end

function Avatar:show(stage)
	if self.model.Parent == stage then
		return
	end
	self.model.Parent = stage
	local human = self.model:FindFirstChildOfClass("Humanoid")
	if human then
		human:ChangeState(Enum.HumanoidStateType.Physics)
	end
	for _, part in self.parts do
		part.CanCollide = false
	end
end

-- Hide only on this client. Raw transparency is independent of the local
-- transparency modifier that PlayerModule and the underground camera own.
function Avatar.mask(character)
	local hidden = {}
	local alpha = {}
	local transparent = NumberSequence.new(1)
	local function added(item)
		if hidden[item] then
			return
		end
		local key, value
		if item:IsA("BasePart") or item:IsA("Decal") then
			key, value = "Transparency", 1
		elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
			key, value = "Transparency", transparent
		elseif
			item:IsA("LayerCollector")
			or item:IsA("Light")
			or item:IsA("Highlight")
			or item:IsA("Fire")
			or item:IsA("Smoke")
			or item:IsA("Sparkles")
		then
			key, value = "Enabled", false
		elseif item:IsA("Humanoid") then
			key, value = "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None
		elseif item:IsA("ForceField") or item:IsA("HandleAdornment") then
			key, value = "Visible", false
		else
			return
		end
		local before = item[key]
		if key == "Transparency" and typeof(before) == "number" then
			alpha[item] = before
		end
		item[key] = value
		local connection = item:GetPropertyChangedSignal(key):Connect(function()
			if item[key] ~= value then
				before = item[key]
				if alpha[item] ~= nil then
					alpha[item] = before
				end
				item[key] = value
			end
		end)
		hidden[item] = function()
			connection:Disconnect()
			if item[key] == value then
				item[key] = before
			end
		end
	end
	local function removed(item)
		if hidden[item] then
			hidden[item]()
			hidden[item] = nil
		end
		alpha[item] = nil
	end
	local adding = character.DescendantAdded:Connect(added)
	local removing = character.DescendantRemoving:Connect(removed)
	for _, item in character:GetDescendants() do
		added(item)
	end
	return function()
		adding:Disconnect()
		removing:Disconnect()
		for _, restore in hidden do
			restore()
		end
	end, function(item)
		return alpha[item] or item.Transparency
	end
end
return Avatar
