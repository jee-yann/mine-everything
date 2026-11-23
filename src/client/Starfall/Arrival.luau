local Avatar = require(script.Parent.CinematicAvatar)
local Players = game:GetService("Players")
local S = require(script.Parent.Scenery)
local FieldAssay = require(script.Parent.FieldAssay)
local ExpeditionMarker = require(script.Parent.ExpeditionMarker)
local PrecisionCut = require(script.Parent.PrecisionCut)
local ExpeditionCamera = require(script.Parent.ExpeditionCamera)
local sheet = require(script.Parent.ExposureSheet)
local F = sheet.frames
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local Arrival = {}
Arrival.__index = Arrival

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
function Arrival:prepare()
	if self.rig and not self.appearanceChanged then
		return
	end
	local character = self.handoff.root.Parent
	if not self.added then
		local function changed(item)
			if
				item:IsA("BasePart")
				or item:IsA("Accoutrement")
				or item:IsA("Clothing")
				or item:IsA("CharacterMesh")
				or item:IsA("BodyColors")
				or item:IsA("SurfaceAppearance")
				or item:IsA("Decal")
			then
				self.appearanceChanged = true
			end
		end
		self.added = character.DescendantAdded:Connect(changed)
		self.removed = character.DescendantRemoving:Connect(changed)
	end
	local fresh = Avatar.new(character, self.visibleAlpha)
	if self.rig then
		self.rig:destroy()
	end
	self.rig, self.appearanceChanged = fresh, false
	self.copy = self.rig.model
	if self.root then
		self.root, self.head = fresh.root, self.copy:FindFirstChild("Head")
	end
end

function Arrival:start()
	self:prepare()
	local h, rig = self.handoff, self.rig
	local root = rig.root
	self.root, self.head = root, self.copy:FindFirstChild("Head")
	self.remote = (h.root.Position - h.landing).Magnitude >= 38
	local headHeight = if self.head then rig.world[rig.indices[self.head]].Y - root.Position.Y else 1.5
	self.unit = math.clamp(math.max(headHeight / 1.55, root.Size.X / 2), 0.65, 1.85)
	self.headroom, self.portraitDistance = portraitFraming(self.copy, self.head, self.unit)
	local position = if self.remote then h.landing else h.root.Position
	if self.remote then
		local floor = math.huge
		for _, name in { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" } do
			local foot = self.copy:FindFirstChild(name)
			if foot then
				floor = math.min(floor, foot.Position.Y - foot.Size.Y * 0.5)
			end
		end
		local site = workspace:FindFirstChild("CitrineCove")
		local court = site and site:FindFirstChild("Sand path and bridge")
		local pad = court and court:FindFirstChild("Landing")
		if floor < math.huge then
			position += Vector3.yAxis * (root.Position.Y - floor - 4 + (if pad then pad.Size.Y * 0.5 else 0.11))
		end
	end
	if self.replayLanding then
		position += self.replayLanding - h.landing
	end
	local direction = ((h.entrance or h.landing - Vector3.zAxis * 30) - h.landing) * V(1, 0, 1)
	self.mineBearing =
		CFrame.lookAt(position, position + (if direction.Magnitude > 0.01 then direction.Unit else -Vector3.zAxis))

	self.mark = CF(position) * (if self.remote then CFrame.identity else h.root.CFrame.Rotation)
	rig:place(self.mark)
	self.facing = self.mineBearing
	self.marker:place(self)
	self.proof:place(self)
	self.assay = FieldAssay.new(self)
	self.lens = Instance.new("DepthOfFieldEffect")
	self.lens.Name = "Expedition focus"
	self.lens.NearIntensity, self.lens.FarIntensity = 0, 0.47
	self.lens.Parent = self.stage.Parent
end

function Arrival:pose(frame)
	local rig, u = self.rig, self.unit
	local trial = frame < F.portrait
	local walk = 1 - S.ease(frame, F.present, F.present + 22)
	local step = math.sin(math.max(0, frame - F.present) * math.pi / 10) * walk
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
	local shift = V(-0.24 * walk + 0.13 * drive, 0.055 * math.abs(step) - 0.12 * drive - 0.05 * study,
		1.65 * walk - 0.19 * drive - 0.12 * study) * u
	local facing = self.mineBearing.Rotation * A(0, math.rad(-8 * walk - 7 * coil + 12 * drive), 0)
	local rootBone = rig.channels.Root or rig.channels.RootJoint
	if rootBone then
		local relative = self.mark:VectorToObjectSpace(self.mineBearing:VectorToWorldSpace(shift))
		local rotation = CFrame.identity:Lerp(self.mark.Rotation:ToObjectSpace(facing), active)
		local axes = rootBone.c0.Rotation
		rootBone.pose = axes:Inverse() * CF(relative) * rotation * axes
	end
	rig:turn("LeftHip", 24 * step - 8 * drive, -4 * drive, 1.5 * step)
	rig:turn("RightHip", -24 * step + 8 * drive, 3 * drive, -1.5 * step)
	rig:turn("LeftKnee", -14 * math.max(0, -step) - 7 * drive, 0, 0)
	rig:turn("RightKnee", -14 * math.max(0, step) - 3 * drive, 0, 0)
	rig:turn(
		"Waist",
		(-5 * lift + 8 * drive - 4 * coil + 8 * study) * active,
		(9 * lift - 18 * coil + 19 * drive - 4 * final - 14 * study) * active,
		-6 * settle + 5 * drive
	)
	rig:turn(
		"LeftShoulder",
		(-17 * step + 6 * lift + 26 * coil - 13 * drive + 32 * study) * active,
		4 * drive,
		(-7 * lift + 13 * coil - 8 * study) * active
	)
	rig:turn("LeftElbow", (11 * lift + 17 * coil + 6 * drive + 14 * study) * active, 0, 0)
	rig:turn("LeftWrist", 0, -8 * coil, 4 * drive)
	rig:turn(
		"RightShoulder",
		(13 * step + 54 * lift + 19 * settle + 47 * coil - 20 * drive - 7 * follow) * active,
		(-11 * lift + 9 * coil + 10 * drive) * active,
		(9 * lift + 7 * coil - 4 * drive) * active
	)
	rig:turn("RightElbow", (37 * lift + 15 * settle + 22 * coil - 27 * drive) * active, 0, 0)
	rig:turn(
		"RightWrist",
		(-7 * lift + 17 * settle - 15 * drive) * active,
		6 * lift * active,
		8 * lift * active
	)
	rig:turn(
		"Neck",
		(-8 * walk - 6 * lift + 13 * final - 17 * study - (if trial then 7 else 0)) * active,
		(21 * walk + 11 * lift - 28 * final - 7 * drive - 33 * study) * active,
		-4 * settle
	)

	local blend = if self.remote then 0 else S.ease(frame, F.handoff + 1, F.endBlend - 1)
	rig:place(self.mark, blend, Vector3.zero)
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
	if frame < F.establish then
		if self.root then
			self:release()
		end
		return
	end
	if not self.root then
		self:start()
	elseif self.appearanceChanged then
		self.assay:Destroy()
		self:prepare()
		self.rig:place(self.mark)
		self.assay = FieldAssay.new(self)
	end
	if frame >= F.autoStrike and not self.contactFrame then
		self.contactFrame = F.autoStrike + 8
	end
	local contact = self.contactFrame or F.autoStrike + 8
	self:pose(frame)
	if not self.remote and frame >= F.endBlend then
		self.copy.Parent = nil
		if self.unmask then
			self.unmask()
			self.unmask, self.visibleAlpha = nil, nil
		end
	else
		if not self.remote and not self.unmask then
			self.unmask, self.visibleAlpha = Avatar.mask(self.handoff.root.Parent)
		end
		self.rig:show(self.stage)
	end
	self.proof:draw(self.stage, frame)
	self.assay:draw(self, frame, contact)
	self.marker:draw(self, frame, contact)
	self.lens.Enabled = frame >= F.present and frame < F.mineRun
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
	self.proof:hide()
	self.marker:hide()
	if self.added then
		self.added:Disconnect()
		self.removed:Disconnect()
	end
	if self.rig then
		self.rig:destroy()
	end
	if self.unmask then
		self.unmask()
	end
	if self.lens then
		self.lens:Destroy()
	end
	self.rig, self.unmask, self.lens, self.copy = nil, nil, nil, nil
	self.added, self.removed, self.appearanceChanged, self.visibleAlpha = nil, nil, nil, nil
	self.head, self.root, self.frame, self.mineBearing = nil, nil, nil, nil
end
function Arrival:Destroy()
	self:release()
	self.proof:Destroy()
	self.marker:Destroy()
end
return Arrival
