local Run = game:GetService("RunService")
local Players = game:GetService("Players")
local S = require(script.Parent.Scenery)
local FieldAssay = require(script.Parent.FieldAssay)
local ExpeditionMarker = require(script.Parent.ExpeditionMarker)
local PrecisionCut = require(script.Parent.PrecisionCut)
local ExpeditionCamera = require(script.Parent.ExpeditionCamera)
local clock = require(script.Parent.Timeline)
local sheet = require(script.Parent.ExposureSheet)
local F = sheet.frames
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local Arrival = {}
Arrival.__index = Arrival

local function joint(character, poses, name, legacy)
	local j = character:FindFirstChild(name, true) or (legacy and character:FindFirstChild(legacy, true))
	if j then
		return poses[j]
	end
end
local function restore(ch)
	if ch.applied and ch.joint.Parent and ch.joint.Transform == ch.applied then
		ch.joint.Transform = ch.rest
	end
end
local function turn(ch, x, y, z)
	if not ch then
		return
	end
	ch.applied = ch.axes:Inverse() * A(math.rad(x), math.rad(y), math.rad(z)) * ch.axes * ch.rest
end
local function double(character, landing)
	local old = character.Archivable
	character.Archivable = true
	local copy = character:Clone()
	character.Archivable = old
	if not copy then
		return
	end
	for _, item in copy:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("Sound") or item:IsA("BillboardGui") then
			item:Destroy()
		elseif item:IsA("BasePart") then
			item.CanCollide, item.CanQuery, item.CanTouch = false, false, false
			item.LocalTransparencyModifier = 0
		end
	end
	local root = copy:FindFirstChild("HumanoidRootPart")
	if not root then
		copy:Destroy()
		return
	end
	local surfaceScale = character:GetAttribute("SurfaceScale")
	if typeof(surfaceScale) == "number" and surfaceScale > 0 then
		copy:ScaleTo(surfaceScale)
	end
	root.Anchored = true
	local human = copy:FindFirstChildOfClass("Humanoid")
	if human then
		human.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		human.AutoRotate = false
		human.EvaluateStateMachine = false
	end
	local foot = copy:FindFirstChild("LeftFoot") or copy:FindFirstChild("Left Leg")
	if foot and foot:IsA("BasePart") then
		local island = workspace:FindFirstChild("CitrineCove")
		local court = island and island:FindFirstChild("Sand path and bridge")
		local pad = court and court:FindFirstChild("Landing")
		local padTop = if pad then pad.Size.Y / 2 else 0.11
		local standing = root.Position.Y - foot.Position.Y + foot.Size.Y / 2
		landing += Vector3.yAxis * (standing - 4 + padTop)
	end
	copy:PivotTo(CF(landing) * root.CFrame:ToObjectSpace(copy:GetPivot()))
	return copy
end
function Arrival.new(stage, h)
	local player = Players:GetPlayerFromCharacter(h.root.Parent) or Players.LocalPlayer
	local name = if player then player.DisplayName else h.root.Parent.Name
	return setmetatable(
		{ stage = stage, handoff = h, marker = ExpeditionMarker.new(name), proof = PrecisionCut.new() },
		Arrival
	)
end
local function portraitFraming(character, head, u)
	if not character or not head then
		return 0, 1
	end
	local crown = head.Size.Y / 2
	for _, item in character:GetChildren() do
		if not item:IsA("Accessory") then
			continue
		end
		local handle = item:FindFirstChild("Handle")
		if not handle or not handle:IsA("BasePart") then
			continue
		end
		local weld = handle:FindFirstChild("AccessoryWeld")
		if not weld or not weld:IsA("Weld") or weld.Part1 ~= head then
			continue
		end
		local cf, half = handle.CFrame, handle.Size * 0.5
		local top = handle.Position.Y
			- head.Position.Y
			+ math.abs(cf.RightVector.Y) * half.X
			+ math.abs(cf.UpVector.Y) * half.Y
			+ math.abs(cf.LookVector.Y) * half.Z
		crown = math.max(crown, top)
	end
	local extra = math.clamp(crown / u - 1.12, 0, 2.8)
	return 0.37 * extra * u, 1 + 0.29 * extra
end
function Arrival:start()
	local h = self.handoff
	local char = h.root.Parent
	if char and not char:IsA("Model") then
		char = nil
	end
	self.remote = (h.root.Position - h.landing).Magnitude >= 38
	if self.remote and char then
		self.copy = double(char, self.replayLanding or h.landing)
		if self.copy then
			self.copy.Parent = self.stage
			char = self.copy
		end
	end
	self.root = if self.copy then self.copy.HumanoidRootPart else h.root
	if char then
		self.costume = {}
		self.poses = {}
		local function register(item)
			local property, hold
			if item:IsA("BillboardGui") or item:IsA("Trail") then
				property, hold = "Enabled", false
			elseif item:IsA("ParticleEmitter") or item:IsA("Fire") or item:IsA("Smoke") or item:IsA("Sparkles") then
				property, hold = "TimeScale", 0
			elseif item:IsA("Beam") then
				property, hold = "TextureSpeed", 0
			elseif item:IsA("Motor6D") or item:IsA("AnimationConstraint") then
				self.poses[item] = { joint = item, axes = item.C0.Rotation }
			end
			if property and item[property] ~= hold then
				table.insert(self.costume, { item, property, item[property], hold })
				item[property] = hold
			end
		end
		for _, item in char:GetDescendants() do
			register(item)
		end
		self.newLabel = char.DescendantAdded:Connect(register)
		self.head = char:FindFirstChild("Head")
		self.hand = char:FindFirstChild("LeftHand")
			or char:FindFirstChild("Left Arm")
			or char:FindFirstChild("LeftLowerArm")
		self.channels = {
			root = joint(char, self.poses, "Root", "RootJoint"),
			leftHip = joint(char, self.poses, "LeftHip", "Left Hip"),
			rightHip = joint(char, self.poses, "RightHip", "Right Hip"),
			leftKnee = joint(char, self.poses, "LeftKnee"),
			rightKnee = joint(char, self.poses, "RightKnee"),
			shoulder = joint(char, self.poses, "LeftShoulder", "Left Shoulder"),
			elbow = joint(char, self.poses, "LeftElbow"),
			wrist = joint(char, self.poses, "LeftWrist"),
			waist = joint(char, self.poses, "Waist"),
			pickShoulder = joint(char, self.poses, "RightShoulder", "Right Shoulder"),
			pickElbow = joint(char, self.poses, "RightElbow"),
			pickWrist = joint(char, self.poses, "RightWrist"),
			neck = joint(char, self.poses, "Neck"),
		}
	end
	local root = self.root
	local headHeight = if self.head then (self.head.Position - root.Position):Dot(Vector3.yAxis) else 1.5
	self.unit = math.clamp(math.max(headHeight / 1.55, root.Size.X / 2), 0.65, 1.85)
	local u = self.unit
	self.headroom, self.portraitDistance = portraitFraming(char, self.head, u)
	local direction = ((h.entrance or (h.landing - Vector3.zAxis * 30)) - h.landing) * V(1, 0, 1)
	self.mineBearing = CFrame.lookAt(
		root.Position,
		root.Position + (if direction.Magnitude > 0.01 then direction.Unit else root.CFrame.LookVector)
	)
	self.facing = self.mineBearing
	self.marker:place(self)
	self.proof:place(self)
	self.assay = FieldAssay.new(self)
	self.lens = Instance.new("DepthOfFieldEffect")
	self.lens.Name = "Expedition focus"
	self.lens.NearIntensity, self.lens.FarIntensity = 0, 0.47
	self.lens.Parent = self.stage.Parent
	self.visitors = {}
	self.hidden = {}
	if self.channels then
		self.before = Run.PreAnimation:Connect(function()
			for _, ch in self.poses do
				restore(ch)
			end
		end)
		self.after = Run.PreSimulation:Connect(function()
			local frame = self.frame
			if not frame then
				return
			end
			-- Let the live Animator evaluate normally underneath the film.
			-- Only photograph a new idle and gesture on a picture exposure.
			local fresh = self.poseTime ~= frame
			for j, ch in self.poses do
				if not j.Parent then
					self.poses[j] = nil
				else
					ch.rest = j.Transform
					if fresh or not ch.applied then
						ch.applied = ch.rest
					end
				end
			end
			if fresh then
				self.poseTime = frame
				local ch = self.channels
				local trial = frame < F.portrait
				local walk = 1 - S.ease(frame, F.present, F.present + 22)
				local step = math.sin((frame - F.present) * math.pi / 10) * walk
				local age = frame - (if trial then F.proofStrike else self.contactFrame or F.autoStrike + 8)
				local study = S.ease(frame, F.present + 10, F.measure + 6) * (1 - S.ease(age, -12, -6))
				if not trial then
					study = 0
				end
				local shoulder = S.ease(frame, F.portrait - 30, F.portrait - 10)
				local lift = if trial
					then math.max(
						0.16 + 0.84 * S.ease(frame, F.measure - 8, F.measure + 12) * (1 - 0.82 * S.ease(age, 3, 24)),
						shoulder
					)
					else 1
				local settle = S.ease(frame, F.portrait - 24, F.portrait - 17)
					* (1 - S.ease(frame, F.portrait - 17, F.portrait - 6))
				local coil = S.ease(age, if trial then -14 else -8, if trial then -6 else -4)
					* (1 - S.ease(age, if trial then -6 else -4, 0))
				local drive = S.ease(age, -4, 0) * (1 - S.ease(age, 1, 12))
				local follow = S.ease(age, 1, 5) * (1 - S.ease(age, 5, 16))
				local final = S.ease(frame, F.mineRun - 12, F.mineRun + 4)
				local active = 1 - S.ease(frame, F.mineRun + 2, F.mineRun + 16)
				if ch.root then
					local relative = root.CFrame:VectorToObjectSpace(
						self.mineBearing:VectorToWorldSpace(
							V(
								-0.24 * walk + 0.13 * drive,
								0.055 * math.abs(step) - 0.12 * drive - 0.05 * study,
								1.65 * walk - 0.19 * drive - 0.12 * study
							) * u
						)
					)
					local body = root.CFrame.Rotation:ToObjectSpace(self.mineBearing.Rotation)
					local orient =
						CFrame.identity:Lerp(body * A(0, math.rad(-8 * walk - 7 * coil + 12 * drive), 0), active)
					ch.root.applied = ch.root.axes:Inverse() * CF(relative) * orient * ch.root.axes * ch.root.rest
				end
				turn(ch.leftHip, 24 * step - 8 * drive, -4 * drive, 1.5 * step)
				turn(ch.rightHip, -24 * step + 8 * drive, 3 * drive, -1.5 * step)
				turn(ch.leftKnee, -14 * math.max(0, -step) - 7 * drive, 0, 0)
				turn(ch.rightKnee, -14 * math.max(0, step) - 3 * drive, 0, 0)
				turn(
					ch.waist,
					(-5 * lift + 8 * drive - 4 * coil + 8 * study) * active,
					(9 * lift - 18 * coil + 19 * drive - 4 * final - 14 * study) * active,
					-6 * settle + 5 * drive
				)
				turn(
					ch.shoulder,
					(-17 * step + 6 * lift + 26 * coil - 13 * drive + 32 * study) * active,
					4 * drive,
					(-7 * lift + 13 * coil - 8 * study) * active
				)
				turn(ch.elbow, (11 * lift + 17 * coil + 6 * drive + 14 * study) * active, 0, 0)
				turn(ch.wrist, 0, -8 * coil, 4 * drive)
				turn(
					ch.pickShoulder,
					(13 * step + 54 * lift + 19 * settle + 47 * coil - 20 * drive - 7 * follow) * active,
					(-11 * lift + 9 * coil + 10 * drive) * active,
					(9 * lift + 7 * coil - 4 * drive) * active
				)
				turn(ch.pickElbow, (37 * lift + 15 * settle + 22 * coil - 27 * drive) * active, 0, 0)
				turn(
					ch.pickWrist,
					(-7 * lift + 17 * settle - 15 * drive) * active,
					6 * lift * active,
					8 * lift * active
				)
				turn(
					ch.neck,
					(-8 * walk - 6 * lift + 13 * final - 17 * study - (if trial then 7 else 0)) * active,
					(21 * walk + 11 * lift - 28 * final - 7 * drive - 33 * study) * active,
					-4 * settle
				)
			end
			for j, ch in self.poses do
				j.Transform = ch.applied
			end
		end)
	end
end
-- Pressing early changes when the swing and its sound land in this take.
-- Spectators who just watch get the same action on the last beat of the bar.
function Arrival:requestStrike(frame)
	if frame < F.prompt or frame >= F.autoStrike or self.contactFrame then
		return false
	end
	self.contactFrame = frame + 8
	return true
end

function Arrival:draw(t, picture)
	local frame = picture or math.round(sheet.frameForScene(t))
	self.frame = frame
	if frame < F.prompt then
		self.contactFrame = nil
	end
	if t < clock.present then
		if self.root then
			self:release()
		end
		return
	end
	if not self.root then
		self:start()
	end
	-- Each viewer has the compass to themselves for this take, including
	-- when a second player joins or respawns in the middle of the insert.
	for _, player in Players:GetPlayers() do
		local neighbor = player.Character
		if neighbor and neighbor ~= self.handoff.root.Parent and not self.visitors[neighbor] then
			local root = neighbor:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - self.root.Position).Magnitude < 28 then
				local function mask(item)
					if item:IsA("BasePart") then
						self.hidden[item] = item.LocalTransparencyModifier
						item.LocalTransparencyModifier = 1
					elseif item:IsA("BillboardGui") and item.Enabled then
						self.hidden[item] = true
						item.Enabled = false
					end
				end
				for _, item in neighbor:GetDescendants() do
					mask(item)
				end
				self.visitors[neighbor] = neighbor.DescendantAdded:Connect(mask)
			end
		end
	end
	if frame >= F.autoStrike and not self.contactFrame then
		self.contactFrame = F.autoStrike + 8
	end
	local contact = self.contactFrame or F.autoStrike + 8
	self.proof:draw(self.stage, frame)
	self.assay:draw(self, frame, contact)
	self.marker:draw(self, frame, contact)
	self.lens.Enabled = frame < F.mineRun
	self.lens.FarIntensity = if frame >= F.commission and frame < F.beacon then 0.73 else 0.45
	self.lens.InFocusRadius = (
		if frame < F.measure
			then 3.5
			elseif frame < F.portrait then 0.94
			elseif frame < F.commission then 2.2
			elseif frame < F.beacon then 0.79
			elseif frame - contact >= -2 and frame - contact < 7 then 0.62
			else 2.2
	) * self.unit
end

function Arrival:camera(t, motion)
	return ExpeditionCamera.frame(self, t, motion)
end
function Arrival:release()
	if self.assay then
		self.assay:Destroy()
		self.assay = nil
	end
	self.contactFrame = nil
	if self.newLabel then
		self.newLabel:Disconnect()
		self.newLabel = nil
	end
	for _, entry in self.costume or {} do
		local item, property = entry[1], entry[2]
		if item.Parent and item[property] == entry[4] then
			item[property] = entry[3]
		end
	end
	for _, listener in self.visitors or {} do
		listener:Disconnect()
	end
	for item, original in self.hidden or {} do
		if item.Parent then
			if item:IsA("BasePart") then
				item.LocalTransparencyModifier = original
			else
				item.Enabled = original
			end
		end
	end
	self.costume, self.visitors, self.hidden = nil, nil, nil
	if self.lens then
		self.lens:Destroy()
		self.lens = nil
	end
	if self.before then
		self.before:Disconnect()
		self.after:Disconnect()
		self.before, self.after = nil, nil
		for _, ch in self.poses do
			restore(ch)
		end
	end
	if self.copy then
		self.copy:Destroy()
	end
	self.copy, self.head, self.hand, self.root, self.channels = nil, nil, nil, nil, nil
	self.poses, self.poseTime = nil, nil
	self.frame = nil
	self.proof:hide()
	self.marker:hide()
end
function Arrival:Destroy()
	self:release()
	self.proof:Destroy()
	self.marker:Destroy()
end
return Arrival
