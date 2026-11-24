-- The player on screen. One local copy of their dressed character gives the
-- whole performance, with the pick on its gameplay weld. The live character
-- keeps its own place and state and takes over again at the handoff.
local Avatar = require(script.Parent.CinematicAvatar)
local Acting = require(script.Parent.Acting)
local S = require(script.Parent.Scenery)
local Clip = require(script.Parent.PlayerClip)
local Glass = require(script.Parent.GlassReveal)
local MineFace = require(script.Parent.MineFace)
local MouthGlow = require(script.Parent.MouthGlow)
local Witness = require(script.Parent.Witness)
local Camera = require(script.Parent.PlayerCamera)
local sheet = require(script.Parent.ExposureSheet)
local F = sheet.frames
local V, CF = Vector3.new, CFrame.new
local Arrival = {}
Arrival.__index = Arrival
-- Beyond this the live character is somewhere else, so the film ends on a fade.
Arrival.nearby = 12

function Arrival.new(stage, h)
	return setmetatable({
		stage = stage, handoff = h,
		mouth = MouthGlow.new(stage), glass = Glass.new(stage), witness = Witness.new(stage),
	}, Arrival)
end

-- Leave room in close shots for the hat this player is actually wearing.
local function portraitFraming(character, head, u)
	if not character or not head then
		return 0, 1
	end
	local crown = head.Size.Y / 2
	for _, item in character:GetChildren() do
		local handle = item:IsA("Accessory") and item:FindFirstChild("Handle")
		local weld = handle and handle:FindFirstChild("AccessoryWeld")
		if handle and handle:IsA("BasePart") and weld and weld:IsA("Weld") and weld.Part1 == head then
			local cf, half = handle.CFrame, handle.Size * 0.5
			crown = math.max(crown, handle.Position.Y - head.Position.Y
				+ math.abs(cf.RightVector.Y) * half.X + math.abs(cf.UpVector.Y) * half.Y + math.abs(cf.LookVector.Y) * half.Z)
		end
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
			if item:IsA("BasePart") or item:IsA("Accoutrement") or item:IsA("Clothing") or item:IsA("CharacterMesh")
				or item:IsA("BodyColors") or item:IsA("SurfaceAppearance") or item:IsA("Decal") then
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
	self.copy, self.root, self.head = fresh.model, fresh.root, fresh.model:FindFirstChild("Head")
	local pick = self.copy:FindFirstChild("Harbor pick")
	self.handle = pick and pick:FindFirstChild("Handle")
	if self.handle and not fresh.indices[self.handle] then
		self.handle = nil
	end
end

function Arrival:site()
	return self.replica or workspace:FindFirstChild("CitrineCove")
end

local function floorAt(site, point)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = if site then { site } else {}
	local hit = site and workspace:Raycast(point + V(0, 4, 0), V(0, -10, 0), params)
	return if hit then hit.Position.Y else nil
end

function Arrival:start()
	self:prepare()
	local h, rig = self.handoff, self.rig
	local root = rig.root
	local away = (h.root.Position - h.landing) * V(1, 0, 1)
	self.remote = away.Magnitude >= Arrival.nearby or math.abs(h.root.Position.Y - h.landing.Y) > 8
	local headHeight = if self.head then rig.rest[self.head].Y else 1.5
	self.unit = math.clamp(math.max(headHeight / 1.55, root.Size.X / 2), 0.65, 1.85)
	self.headroom, self.portraitDistance = portraitFraming(self.copy, self.head, self.unit)
	local position = if self.remote then h.landing else h.root.Position
	if self.remote then
		local court = workspace:FindFirstChild("CitrineCove") and workspace.CitrineCove:FindFirstChild("Sand path and bridge")
		local pad = court and court:FindFirstChild("Landing")
		position += Vector3.yAxis * (rig.stand - 4 + (if pad then pad.Size.Y * 0.5 else 0.11))
	end
	if self.replayLanding then
		position += self.replayLanding - h.landing
	end
	local shift = if self.replayLanding then self.replayLanding - h.landing else Vector3.zero
	local entrance = (h.entrance or h.landing - Vector3.zAxis * 85) + shift
	local direction = (entrance - position) * V(1, 0, 1)
	self.mineBearing = CFrame.lookAt(position, position + (if direction.Magnitude > 0.01 then direction.Unit else -Vector3.zAxis))
	self.mark = CF(position) * (if self.remote then self.mineBearing.Rotation else h.root.CFrame.Rotation)
	self.floor = position.Y - rig.stand
	self.entrance = entrance
	self.roadStand = self.mineBearing * CFrame.Angles(0, math.pi, 0)
	self:block()
	local site = self:site()
	local post = self.mineBearing * CF(-2.6, -rig.stand, 11.8)
	local y = floorAt(site, post.Position) or self.floor
	self.witness:place(CF(post.X, y, post.Z) * self.mineBearing.Rotation * CFrame.Angles(0, math.rad(-22), 0))
	self.mouth:place(entrance)
	self.lens = Instance.new("DepthOfFieldEffect")
	self.lens.Name, self.lens.NearIntensity, self.lens.FarIntensity = "Expedition focus", 0, 0.4
	self.lens.Parent = self.stage.Parent
end

-- Play the blow once, offstage, and stand the player where the steel stops on
-- the rock. Long arms and short arms all land on the same spot.
function Arrival:block()
	local rig, u, mine = self.rig, self.unit, self.mine
	local at = mine.at
	self.faceAt, self.hole = at, mine.contact
	local stand = at * CF(mine.point.X, rig.stand, 3)
	rig:place(Acting.perform(rig, Clip.gallery, F.contact2, stand, u))
	self.tip = if self.handle then MineFace.tipOf(rig, self.handle, at.LookVector) else nil
	local hit = at:PointToObjectSpace(self:tipAt())
	self.galleryStand = at * CF(2 * mine.point.X - hit.X, rig.stand, 3 + (0.02 - hit.Z))
	rig:place(Acting.perform(rig, Clip.gallery, F.contact2, self.galleryStand, u))
	self.strikePoint = self:tipAt()
end

function Arrival:tipAt()
	local rig = self.rig
	if self.handle then
		return rig.world[rig.indices[self.handle]] * self.tip
	end
	local hand = self.copy:FindFirstChild("RightHand") or self.copy:FindFirstChild("Right Arm") or rig.root
	return (rig.world[rig.indices[hand]] * CF(0, -hand.Size.Y * 0.5, -0.6 * self.unit)).Position
end

function Arrival:palmAt()
	local rig = self.rig
	local hand = self.copy:FindFirstChild("LeftHand") or self.copy:FindFirstChild("Left Arm")
	return hand and (rig.world[rig.indices[hand]] * CF(0, -hand.Size.Y * 0.5, 0)).Position
end

function Arrival:pose(frame)
	local rig, u = self.rig, self.unit
	local clip, stand = Clip.road, self.roadStand
	if frame < F.enter then
		clip, stand = Clip.plaza, self.mineBearing
	elseif frame < F.answer then
		clip, stand = Clip.gallery, self.galleryStand
	end
	local f = frame
	if not self.motion then
		-- Reduced motion holds one clear drawing for each beat of the story.
		f = if frame < F.enter then F.witness + 40 elseif frame < F.strike then F.strike - 2 elseif frame < F.autoStrike then F.strike + 18
			elseif frame < F.inside then frame elseif frame < F.reveal then F.reveal - 4 elseif frame < F.answer then F.reveal + 30
			elseif frame < F.turn + 20 then F.turn else F.turn + 44
	end
	local base = Acting.perform(rig, clip, f, stand, u)
	local blend = if self.remote then 0 else S.ease(frame, F.handoff - 4, F.endBlend - 2)
	rig:place(base, blend, Vector3.zero)
end

-- One strike per screening. The clock then jumps straight to the wind-up.
function Arrival:requestStrike(frame)
	if frame < F.prompt or frame >= F.autoStrike or self.pressed then
		return nil
	end
	self.pressed = F.autoStrike
	return F.autoStrike - frame
end

function Arrival:draw(frame)
	self.frame = frame
	if frame < F.prompt then
		self.pressed = nil
	end
	local away = (self.handoff.root.Position - self.handoff.landing).Magnitude >= 38
	if frame < F.match then
		if self.rig or self.unmask then
			self:release()
		end
		return
	end
	-- The player is not on the compass yet. They walk into the story later.
	if not away and frame < F.endBlend and not self.unmask then
		self.unmask, self.visibleAlpha = Avatar.mask(self.handoff.root.Parent)
	end
	-- One-time construction happens in the two dark beats.
	if frame >= F.dark + 3 and frame < F.reveal then
		self.glass:build()
	end
	if frame < F.dig - 7 then
		if self.rig then
			self:dismiss()
		end
		return
	end
	if not self.rig then
		self:start()
	elseif self.appearanceChanged then
		self:prepare()
		self:block()
	end
	self:pose(frame)
	if frame >= F.dig and (self.remote or frame < F.endBlend) then
		self.rig:show(self.stage)
	else
		self.copy.Parent = nil
	end
	if not self.remote and frame >= F.endBlend and self.unmask then
		self.unmask()
		self.unmask, self.visibleAlpha = nil, nil
	end
	self.witness:draw(frame, self.motion)
	self.mouth:draw(frame, self.motion)
	if frame >= F.prompt and not self.glass.at then
		self.glass:place(Camera.glassFrame(self), self.unit, self.unit * self.portraitDistance)
	end
	local eye, aim = Camera.frame(self, math.max(frame, F.witness), self.motion)
	self.glass:draw(frame, self.motion, if frame >= F.reveal and frame < F.answer then self:palmAt() else nil, CFrame.lookAt(eye, aim))
	self.lens.Enabled = frame >= F.witness and frame < F.handoff
end

function Arrival:camera(frame, motion)
	return Camera.frame(self, frame, motion)
end

function Arrival:dismiss()
	self.witness.rig.model.Parent = nil
	self.mouth:hide()
	self.glass:hide()
	self.glass.at = nil
	if self.added then
		self.added:Disconnect()
		self.removed:Disconnect()
	end
	if self.rig then
		self.rig:destroy()
	end
	if self.lens then
		self.lens:Destroy()
	end
	self.rig, self.lens, self.copy, self.handle = nil, nil, nil, nil
	self.added, self.removed, self.appearanceChanged = nil, nil, nil
	self.head, self.root, self.mineBearing = nil, nil, nil
end

function Arrival:release()
	self:dismiss()
	if self.unmask then
		self.unmask()
	end
	self.unmask, self.visibleAlpha, self.pressed = nil, nil, nil
end

function Arrival:Destroy()
	self:release()
	self.witness:Destroy()
	self.mouth:Destroy()
	self.glass:Destroy()
end

return Arrival
