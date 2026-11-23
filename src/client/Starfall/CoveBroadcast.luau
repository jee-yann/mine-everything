-- Each receiver has an open screen in a ViewportFrame. The picture inside
-- is the actual player's live workbench, continuously photographed by Film.
local S = require(script.Parent.Scenery)
local cuts = require(script.Parent.ExposureSheet).frames
local Rooms = require(script.Parent.AudienceRooms)
local Cast = require(script.Parent.AudienceCast)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local Broadcast = {}
Broadcast.__index = Broadcast
local roomLens = 47
local roomTangent = math.tan(math.rad(roomLens / 2))
-- The top matte is at least 4.5% of the picture height.
local warmPosition, warmSize = UDim2.fromScale(0.46, 0.006), UDim2.fromScale(0.047, 0.034)

local function label(parent, text, color, background, x, width)
	local t = Instance.new("TextLabel")
	t.Name, t.Text, t.Font = text, text, Enum.Font.GothamBold
	t.TextColor3, t.BackgroundColor3 = Color3.fromHex(color), Color3.fromHex(background)
	t.BorderSizePixel, t.TextScaled, t.ZIndex = 0, true, 3
	t.Position, t.Size, t.Parent = UDim2.fromScale(x, 0), UDim2.fromScale(width, 1), parent
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.1, 0), UDim.new(0.1, 0)
	pad.Parent = t
end

local function viewport(screen)
	local view = Instance.new("ViewportFrame")
	view.Name, view.Size = "Cove TV audience", UDim2.fromScale(1, 1)
	view.BackgroundTransparency, view.BorderSizePixel, view.Visible, view.ZIndex = 1, 0, false, 2
	view.LightDirection, view.Parent = V(-0.53, -0.68, -0.48), screen
	local cam = Instance.new("Camera")
	cam.FieldOfView, cam.Parent, view.CurrentCamera = roomLens, view, cam
	return view
end

function Broadcast.new(screen)
	local view = viewport(screen)
	local bug = Instance.new("Frame")
	bug.Name, bug.BackgroundTransparency, bug.ZIndex, bug.Visible, bug.Parent = "Cove TV station ID", 1, 3, false, screen
	label(bug, "LIVE", "FFFFFF", "AE3542", 0, 0.36)
	label(bug, "COVE TV", "FEF3DB", "203749", 0.36, 0.64)
	return setmetatable({
		view = view, camera = view.CurrentCamera, bug = bug, cast = Cast.new(), rooms = {},
		views = { [Rooms.bedroom] = view, [Rooms.livingRoom] = viewport(screen), [Rooms.computer] = viewport(screen) },
	}, Broadcast)
end

local function act(fan, age, motion, roll)
	local place, rig = fan.place, fan.rig
	-- Each gesture has an anticipation and a landing. The friends respond
	-- to one another a few exposures apart as the camera turns to the screen.
	local t = if motion then age else 23
	local seat = place.seat
	local breath = if motion then math.sin(t / 22 + seat) else 0
	local forward = if place.seated then 1.28 else 0.03
	local pose = {
		bob = 0.018 * breath,
		LeftHip = A(forward, -0.09, -0.04),
		RightHip = A(forward + 0.07, 0.10, 0.04),
		LeftKnee = A(if place.seated then -1.24 else 0, 0, 0),
		RightKnee = A(if place.seated then -1.15 else 0, 0, 0),
	}
	local lean, turn, sway = 0, 0, 0
	local foot = fan.foot
	if seat == 1 then
		local lift = S.ease(t, 4, 23)
		local settle = S.ease(t, 26, 42)
		lean = 0.43 - 0.17 * lift + 0.045 * settle
		turn = -0.10 * lift
		pose.RightTarget = (CF(0, Rooms.bedroom.y, 0) * A(0, 0, roll or Rooms.bedroom.roll)) * V(-0.85, -0.04, 0.15)
		pose.LeftShoulder = A(0.45 + 0.26 * lift, -0.08, -0.18)
		pose.Neck = A(-0.25 + 0.15 * lift, -0.03 - 0.08 * settle, 0.035)
	elseif seat == 2 then
		local notice = S.ease(t, 2, 16)
		local point = S.ease(t, 9, 28) * (1 - S.ease(t, 36, 53))
		local smile = S.ease(t, 35, 46) * (1 - 0.4 * S.ease(t, 48, 57))
		lean = -0.20 * notice + 0.075 * smile
		turn = -0.12 + 0.15 * notice
		pose.RightShoulder = A(0.47 + 0.86 * point, -0.06, 0.16)
		pose.LeftShoulder = A(0.47 + 0.12 * notice, 0, -0.11)
		pose.RightElbow = A(0.46 - 0.33 * point, 0, 0)
		pose.LeftElbow = A(0.45, 0, 0)
		pose.Neck = A(-0.11 + 0.19 * notice + 0.11 * smile, 0.17 - 0.20 * notice, -0.09 * smile)
	elseif seat == 3 then
		local answer = S.ease(t, 12, 27) * (1 - S.ease(t, 31, 45))
		turn = -0.20 * answer
		lean = -0.07 - 0.09 * S.ease(t, 28, 45)
		pose.Neck = A(-0.06, -0.39 * answer, -0.03)
		pose.RightTarget = V(-0.96, 2.55 + 0.08 * answer, 1.39)
		pose.LeftShoulder = A(0.62 + 0.25 * answer, 0, -0.12)
	elseif seat == 4 then
		local beckon = S.ease(t, 0, 15) * (1 - S.ease(t, 21, 36))
		local point = S.ease(t, 18, 35) * (1 - 0.56 * S.ease(t, 46, 59))
		turn = 0.21 * beckon
		lean, sway = -0.15 * point, -0.07 * beckon
		pose.LeftShoulder = A(0.23 + 0.60 * beckon + 0.98 * point, -0.11, -0.17)
		pose.LeftElbow = A(0.32 + 0.58 * beckon - 0.20 * point, 0, 0)
		pose.RightShoulder = A(0.11, 0, 0.10)
		pose.Neck = A(-0.04 + 0.08 * point, 0.29 * beckon, -0.035 * point)
	else
		local step = S.ease(t, 4, 26)
		local nod = S.ease(t, 23, 30) - S.ease(t, 30, 40)
		foot += V(-0.31 * (1 - step), 0.05 * math.sin(step * math.pi), 0.10 * (1 - step))
		lean, turn = -0.10 * step, -0.11 * step
		pose.LeftShoulder = A(0.17 - 0.10 * step, 0, -0.10)
		pose.RightShoulder = A(0.24 + 0.25 * step, 0, 0.15)
		pose.Neck = A(0.13 * nod - 0.04, -0.17 * (1 - step), 0)
	end
	-- Turn about the hips for both classic and modern Roblox avatars.
	local hip = rig.height - place.scale
	foot *= CF(0, hip, 0) * A(lean, turn, sway) * CF(0, -hip, 0)
	rig:pose(foot, pose)
end

function Broadcast:prepare(shot, warm)
	if not self.rooms[shot] then
		local room = Rooms.build(shot, self.cast, warm)
		local view = self.views[shot]
		room.world.Parent = view
		view.Ambient, view.LightColor = Color3.fromHex(shot.ambient), Color3.fromHex(shot.light)
		view.CurrentCamera.CFrame = CF(0, shot.y, shot.z)
		for _, fan in room.fans do act(fan, 0, false) end
		-- Behind the upper letterbox, render the dressed characters in the
		-- same viewport that will go on air. This builds their appearance
		-- atlases before the cut, including for classic shirts and R15 heads.
		view.Position, view.Size = warmPosition, warmSize
		view.Visible = warm
		self.rooms[shot] = room
	end
	return self.rooms[shot]
end

function Broadcast:draw(camera, frame, motion)
	-- Assemble each small set just before its cut. Direct studio seeks also
	-- construct the requested room. Actors stay fixed for the whole take.
	if frame < cuts.broadcast or frame >= cuts.measure then
		for _, view in self.views do view.Visible = false end
		self.bug.Visible, self.room, self.shot = false, nil, nil
		if frame >= cuts.broadcast - 72 and frame < cuts.broadcast then
			self:prepare(Rooms.bedroom, frame < cuts.broadcast - 18)
			local warm = self.views[Rooms.bedroom]
			warm.Position, warm.Size = warmPosition, warmSize
			warm.Visible = true
		end
		return
	end
	local shot, first
	if frame < cuts.livingRoom then
		shot, first = Rooms.bedroom, cuts.broadcast
		if frame >= cuts.livingRoom - 72 then self:prepare(Rooms.livingRoom, frame < cuts.livingRoom - 18) end
	elseif frame < cuts.computer then
		shot, first = Rooms.livingRoom, cuts.livingRoom
		if frame >= cuts.computer - 72 then self:prepare(Rooms.computer, frame < cuts.computer - 18) end
	else
		shot, first = Rooms.computer, cuts.computer
	end
	local room = self:prepare(shot, false)
	if room ~= self.room then
		self.shot, self.room = shot.name, room
		self.view.Visible = false
		self.view = self.views[shot]
		self.view.Position, self.view.Size = UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)
		self.camera = self.view.CurrentCamera
	end
	local age = frame - first
	local roll = shot.roll or 0
	if shot == Rooms.bedroom then
		local t = if motion then age else 23
		roll += 0.125 * S.ease(t, 4, 23) - 0.028 * S.ease(t, 26, 42)
		room.receiver:PivotTo(CF(0, shot.y, 0) * A(0, 0, roll) * CF(0, -shot.y, 0))
	end
	for _, fan in room.fans do
		act(fan, age, motion, roll)
	end

	local viewport = camera.ViewportSize
	local aspect = math.max(0.25, viewport.X / math.max(1, viewport.Y))
	if room.reverse then
		local reverse = age >= 36
		room.reverse.Parent = if reverse then room.world else nil
		if reverse then
			-- Across the TV, a brief answer on the child's face motivates
			-- the next cut to the group reacting to the same broadcast.
			local child = room.fans[1]
			local n = if motion then S.ease(age, 36, 57) else 0.46
			local head = child.rig.head.Position
			local hat = math.min(0.72, child.rig.headroom * child.place.scale)
			local aim = head + child.foot:VectorToWorldSpace(V(0.17, -0.17 + hat * 0.24, 0))
			local eye = head + child.foot:VectorToWorldSpace(V(0.92 - 0.23 * n, 0.13 + hat * 0.25, -2.85 - hat + 0.14 * n))
				* math.clamp(1.15 / aspect, 1, 1.60)
			self.camera.CFrame = CFrame.lookAt(eye, aim)
			self.view.Visible, self.bug.Visible = true, false
			return
		end
	end
	local drift = if shot == Rooms.bedroom then 0.16 elseif shot == Rooms.livingRoom then 0.095 else 0.055
	local take = if motion then S.ease(age, 0, if shot == Rooms.livingRoom then 35 else 43) else 0.46
	local z = shot.z * (1 - drift * take)
	-- Fit the viewer(s) as the screen narrows. The last move ends inside
	-- the monitor on both a tablet and an ultrawide desktop.
	z *= math.clamp(1.60 / math.max(0.25, aspect), 1, 1.65)
	local glassH = shot.width * 9 / 16
	local inside = math.min(glassH, shot.width / math.max(aspect, 0.25)) / (2.15 * roomTangent)
	local push = if motion and shot == Rooms.computer then S.ease(frame, cuts.measure - 23, cuts.measure - 1) else 0
	z += (inside - z) * push
	local height = glassH / (2 * z * roomTangent)
	local width = height * (16 / 9) / math.max(0.25, aspect)
	local eyeX = (if shot == Rooms.bedroom then -0.57 + 0.47 * take
		elseif shot == Rooms.livingRoom then -0.30 + 0.79 * take else -0.45 + 0.51 * take) * (1 - push)
	local centerX = 0.5 - eyeX / (2 * z * roomTangent * aspect)
	self.camera.CFrame = CF(eyeX, shot.y, z)
	self.view.Visible = height < 1.02 or width < 1.02
	self.bug.Visible = self.view.Visible and push < 0.69
	-- Register both the station ID and its live feed with the handheld glass.
	local x, y = -width * 0.32, -height * 0.375
	self.bug.AnchorPoint, self.bug.Rotation = Vector2.new(0.5, 0.5), -math.deg(roll)
	self.bug.Position = UDim2.fromScale(centerX + x * math.cos(roll) + y * math.sin(roll) / aspect,
		0.5 - x * math.sin(roll) * aspect + y * math.cos(roll))
	self.bug.Size = UDim2.fromScale(width * 0.28, height * 0.13)
	local fullLens = math.tan(math.rad(camera.FieldOfView / 2)) / math.min(1, height)
	local lens = math.min(math.tan(math.rad(119 / 2)), fullLens)
	if fullLens > lens then
		-- The narrow phone screen needs more coverage than a 119-degree lens.
		-- Move the eye along the same sightline so both miner and rock still fit.
		camera.CFrame += (camera.CFrame.Position - camera.Focus.Position) * (fullLens / lens - 1)
	end
	camera.FieldOfView = math.deg(2 * math.atan(lens))
	camera.CFrame *= A(0, 0, -roll)
	-- The film camera sees through the aperture even when an observer's
	-- shoulder moves across the near foreground. Keep the live image centered.
	local depth = (camera.Focus.Position - camera.CFrame.Position):Dot(camera.CFrame.LookVector)
	camera.CFrame += camera.CFrame.RightVector * ((0.5 - centerX) * aspect * lens * 2 * depth)
end

function Broadcast:Destroy()
	self.cast:Destroy()
	for _, room in self.rooms do
		if room.reverse then room.reverse:Destroy() end
	end
	for _, view in self.views do
		view:Destroy()
	end
	self.bug:Destroy()
end

return Broadcast
