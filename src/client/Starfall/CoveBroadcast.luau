-- The workbench is the live picture through the set's open TV bezel. Keeping
-- the actual camera feed preserves the miner's outfit, tools and performance.
local S = require(script.Parent.Scenery)
local cuts = require(script.Parent.ExposureSheet).frames
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local Broadcast = {}
Broadcast.__index = Broadcast

local glassY, glassW, glassH = 4.55, 8.0, 4.5
local roomLens = 47
local roomTangent = math.tan(math.rad(roomLens / 2))

local function watcher(world, foot, scale, clothes, skin, cap, side)
	local person = S.group("Fan at the TV")
	local torso, arm = S.group("Coat and cap"), S.group("Raised sleeve")
	torso.Parent, arm.Parent = person, person
	for _, x in { -0.34, 0.34 } do
		S.part(person, "Boot", CF(x, 0.19, -0.14), V(0.62, 0.36, 0.90), "343942")
		S.part(person, "Denim", CF(x, 0.79, 0), V(0.57, 1.03, 0.62), "354A57")
	end
	S.part(torso, "Work coat", CF(0, 0.71, 0), V(1.49, 1.45, 0.83), clothes)
	S.part(torso, "Collar", CF(0, 1.37, 0), V(1.03, 0.20, 0.88), cap)
	local head = S.part(torso, "Head", CF(0, 1.94, 0), V(1.08, 1.05, 0.96), skin)
	local shape = Instance.new("SpecialMesh")
	shape.MeshType, shape.Parent = Enum.MeshType.Head, head
	S.part(torso, "Hair at nape", CF(0, 2.08, 0.34), V(1.04, 0.51, 0.37), "483F43")
	local brim = S.part(torso, "Cap brim", CF(0, 2.39, -0.10), V(1.38, 0.14, 1.48), cap)
	local crown = S.part(torso, "Cap crown", brim.CFrame * CF(0, 0.17, 0.08), V(1.22, 0.55, 1.10), cap)
	crown.Shape = Enum.PartType.Ball
	S.part(torso, "Miner's cap band", CF(0, 2.44, 0.05), V(1.18, 0.08, 1.11), "E2B879")
	S.part(torso, "Resting sleeve", CF(-side * 0.85, 0.79, -0.06) * A(0.22, 0, -side * 0.12), V(0.50, 0.99, 0.58), clothes)
	S.part(torso, "Resting hand", CF(-side * 0.94, 0.24, -0.17), V(0.42, 0.42, 0.48), skin)
	S.part(arm, "Sleeve", CF(0, -0.38, 0), V(0.48, 0.80, 0.56), clothes)
	S.part(arm, "Fist", CF(0, -0.88, -0.04), V(0.44, 0.41, 0.48), skin)
	if side < 0 then
		local flag = S.part(arm, "Gold pennant", CF(-0.27, -1.57, -0.02) * A(0, math.pi / 2, math.pi), V(0.08, 0.45, 0.62), "F4C256", nil, "WedgePart")
		flag.CastShadow = false
		S.part(arm, "Pennant stick", CF(0, -1.34, 0), V(0.07, 0.94, 0.07), "B78152")
	end
	person.Parent = world
	person:ScaleTo(scale)
	person:PivotTo(foot)
	return { torso = torso, arm = arm, foot = foot, scale = scale, side = side }
end

local function room(world)
	local function box(name, x, y, z, w, h, d, color)
		return S.part(world, name, CF(x, y, z), V(w, h, d), color)
	end
	local top, bottom = glassY + glassH / 2, glassY - glassH / 2
	-- Four boards close the wall everywhere except the live picture.
	box("Upper wall", 0, top + 16, -0.29, 100, 32, 0.42, "405A60")
	box("Lower wall", 0, bottom - 16, -0.29, 100, 32, 0.42, "4E6261")
	for _, side in { -1, 1 } do
		box("Wall beside receiver", side * (glassW / 2 + 25), glassY, -0.29, 50, glassH + 0.06, 0.42, "496568")
		box("Copper upright", side * 8, 4, 0.02, 0.24, 12, 0.30, "A78055")
		box("Cabinet stile", side * 4.23, glassY, 0, 0.46, glassH + 0.84, 0.46, "845C46")
		box("Graphite bezel", side * 4.06, glassY, 0.15, 0.13, glassH + 0.19, 0.19, "152635")
	end
	for _, y in { bottom - 0.2, top + 0.2 } do
		box("Walnut cabinet", 0, y, -0.01, 8.76, 0.40, 0.46, "A8744D")
	end
	for _, y in { bottom - 0.05, top + 0.05 } do
		box("Bezel lip", 0, y, 0.15, glassW, 0.1, 0.19, "172C37")
	end
	box("Receiver shelf", 0, bottom - 0.54, 0.26, 9.85, 0.20, 1.43, "CA9362")
	box("Radio cabinet", 0, 0.76, -0.01, 8.40, 1.43, 1.01, "654F46")
	for i = -10, 10 do
		box("Speaker slat", i * 0.35, 0.80, 0.56, 0.21, 0.96, 0.09, "99755B")
	end
	local floor = box("Floor", 0, -0.14, 4, 100, 0.27, 60, "80654D")
	for i = 1, 7 do
		box("Floorboard seam", 0, 0.009, i * 1.37, floor.Size.X, 0.015, 0.034, "654F42")
	end
	-- Oak pegs with the tools off duty beside their owners.
	for _, x in { -5.95, 6.18 } do
		local tool = CF(x, 4.7, 0.17) * A(0, 0, math.rad(if x < 0 then -27 else 28))
		S.part(world, "Worn pick handle", tool, V(0.21, 2.51, 0.19), "CB9A67")
		S.part(world, "Mounted pick head", tool * CF(0, 0.91, 0), V(1.47, 0.26, 0.31), "9EAAA7")
	end
end

local function label(parent, text, color, background, x, width)
	local t = Instance.new("TextLabel")
	t.Name, t.Text, t.Font = text, text, Enum.Font.GothamBold
	t.TextColor3, t.BackgroundColor3 = Color3.fromHex(color), Color3.fromHex(background)
	t.BorderSizePixel, t.TextScaled, t.ZIndex = 0, true, 3
	t.Position, t.Size, t.Parent = UDim2.fromScale(x, 0), UDim2.fromScale(width, 1), parent
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.10, 0), UDim.new(0.10, 0)
	pad.Parent = t
end

function Broadcast.new(screen)
	local view = Instance.new("ViewportFrame")
	view.Name, view.Size = "Miners watching Cove TV", UDim2.fromScale(1, 1)
	view.BackgroundTransparency, view.BorderSizePixel, view.Visible, view.ZIndex = 1, 0, false, 2
	view.Ambient, view.LightColor = Color3.fromHex("89818D"), Color3.fromHex("FFE6BC")
	view.LightDirection, view.Parent = V(-0.65, -0.59, -0.46), screen
	local cam = Instance.new("Camera")
	cam.FieldOfView, cam.Parent, view.CurrentCamera = roomLens, view, cam
	local bug = Instance.new("Frame")
	bug.Name, bug.BackgroundTransparency, bug.ZIndex, bug.Visible, bug.Parent = "Cove TV station ID", 1, 3, false, screen
	label(bug, "LIVE", "FFFFFF", "AE3542", 0, 0.36)
	label(bug, "COVE TV", "FEF3DB", "203749", 0.36, 0.64)
	return setmetatable({ view = view, camera = cam, bug = bug }, Broadcast)
end

function Broadcast:draw(camera, frame, motion)
	if frame < cuts.present - 8 or frame >= cuts.measure then
		self.view.Visible, self.bug.Visible = false, false
		return
	end
	if not self.fans then
		local world = Instance.new("WorldModel")
		world.Parent = self.view
		room(world)
		self.fans = {
			watcher(world, CF(-3.55, 0, 4.1) * A(0, -0.38, 0), 1.19, "9B5E46", "BD8765", "F0B55E", 1),
			watcher(world, CF(3.00, 0.43, 4.9) * A(0, 0.43, 0), 0.93, "3B8391", "C88965", "D97656", -1),
		}
		S.part(world, "Child's footstool", CF(3, 0.23, 4.95), V(1.88, 0.46, 1.43), "B68355")
	end
	if frame < cuts.present then
		self.view.Visible, self.bug.Visible = false, false
		return
	end
	local age = frame - cuts.present
	-- Start at shoulder height with the viewers. Pass the glass by the next cut.
	local push = if motion then S.ease(age, 16, cuts.measure - cuts.present - 1) else 0
	local z = 11.55 - 9.68 * push
	local height = glassH / (2 * z * roomTangent)
	local viewport = camera.ViewportSize
	local width = height * (glassW / glassH) * viewport.Y / math.max(1, viewport.X)
	self.camera.CFrame = CF(0, glassY, z)
	self.view.Visible = height < 1.03 or width < 1.03
	self.bug.Visible = self.view.Visible and push < 0.66
	self.bug.Position = UDim2.fromScale(0.5 - width * 0.463, 0.5 - height * 0.443)
	self.bug.Size = UDim2.fromScale(width * 0.29, height * 0.135)
	camera.FieldOfView = math.min(115, math.deg(2 * math.atan(math.tan(math.rad(camera.FieldOfView / 2)) / math.min(1, height))))
	for i, fan in self.fans do
		local beat = if motion then S.ease(age, 2 + i * 3, 13 + i * 3) - 0.47 * S.ease(age, 20 + i, 35 + i) else 0.68
		local scale, side = fan.scale, fan.side
		local body = fan.foot * CF(0, (1.18 + 0.09 * beat) * scale, 0) * A(-0.12 * beat, side * 0.06 * beat, 0)
		fan.torso:PivotTo(body)
		fan.arm:PivotTo(body * CF(side * 0.91 * scale, 1.24 * scale, 0)
			* A(0.52 + 1.87 * beat, 0, side * (0.12 + 0.20 * beat)))
	end
end

function Broadcast:Destroy()
	self.view:Destroy()
	self.bug:Destroy()
end

return Broadcast
