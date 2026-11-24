-- A home across the island. Two siblings see the light in the mine on the news.
-- A real room with real light: the television is an object in the space, and
-- its violet glow is what reaches the two faces on the reverse.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local Acting = require(script.Parent.Acting)
local Avatar = require(script.Parent.CinematicAvatar)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local M = Enum.Material
local Room = {}
Room.__index = Room

local O, R = F.living, F.livingReverse

-- The kid is already half off the footstool. They point, then look round to
-- make sure it is not just them.
local kidClip = Acting.clip({
	{ O - 4, {
		Body = { 0, -1.02, 0 }, Turn = { -6, 0, 0 }, Waist = { -14, 0, 0 }, Neck = { 14, 0, 4 },
		LeftShoulder = { 52, 0, -4 }, LeftElbow = { 30 }, RightShoulder = { 50, 0, 4 }, RightElbow = { 32 },
		LeftFoot = { -0.12, 0, -0.95 }, RightFoot = { 0.14, 0, -0.78 }, LeftFootTurn = { 0, 10 }, RightFootTurn = { 0, -12 },
	} },
	{ O + 12, { Body = { 0, -1.00, -0.05 }, Waist = { -18, 2, 0 }, Neck = { 18, -2, 3 }, RightShoulder = { 46, 0, 4 }, RightElbow = { 40 } } },
	{ O + 20, { Body = { 0, -0.92, -0.14 }, Waist = { -10, 12, 0 }, Neck = { 12, -10, 0 }, RightShoulder = { 58, -4, 8 }, RightElbow = { 78 } } },
	{ O + 26, {
		Body = { 0, -0.86, -0.2 }, Waist = { -12, 14, 0 }, Neck = { 12, -12, -3 },
		RightShoulder = { 96, 4, 6 }, RightElbow = { 6 }, RightWrist = { -6 }, LeftShoulder = { 34, 0, -14 },
	}, "settle" },
	{ O + 40, { RightShoulder = { 93, 4, 7 }, RightElbow = { 9 }, Neck = { 12, -10, -3 }, Body = { 0, -0.86, -0.2 }, Waist = { -12, 13, 0 } } },
	{ R + 3, { Body = { 0, -0.84, -0.2 }, Waist = { -8, 10, 0 }, Neck = { 10, -6, 0 }, RightShoulder = { 90, 4, 8 }, RightElbow = { 10 } } },
	{ R + 12, { Waist = { -2, -18, 0 }, Neck = { 2, -44, 4 }, RightShoulder = { 86, 10, 10 }, RightElbow = { 16 }, LeftShoulder = { 40, 0, -20 } } },
	{ R + 22, { Waist = { -2, -18, 0 }, Neck = { -2, -46, 4 }, RightShoulder = { 88, 12, 12 }, RightElbow = { 12 } } },
	{ R + 33, { Body = { 0, -0.84, -0.22 }, Waist = { -10, 6, 0 }, Neck = { 12, -4, -3 }, RightShoulder = { 60, 0, 12 }, RightElbow = { 34 } } },
}, { RightElbow = 1, RightWrist = 2, Neck = -1 })

-- The older one starts sunk into the sofa and ends on the edge of it.
local sibClip = Acting.clip({
	{ O - 4, {
		Body = { 0, -1.00, 0 }, Turn = { 14, 0, 0 }, Waist = { 8, 0, 0 }, Neck = { -18, 0, -3 },
		LeftShoulder = { 18, 0, -10 }, LeftElbow = { 46 }, RightShoulder = { 16, 0, 16 }, RightElbow = { 40 },
		LeftFoot = { -0.1, 0, -1.12 }, RightFoot = { 0.1, 0, -1.2 }, LeftFootTurn = { 0, 6 }, RightFootTurn = { 0, -8 },
	} },
	{ O + 24, { Body = { 0, -1.00, 0 }, Turn = { 13, 0, 0 }, Waist = { 8, 0, 0 }, Neck = { -18, 0, -3 } } },
	{ O + 36, {
		Body = { 0, -0.98, -0.30 }, Turn = { -4, 0, 0 }, Waist = { -8, 0, 0 }, Neck = { 6, 6, 0 },
		LeftShoulder = { 40, 0, -4 }, LeftElbow = { 50 }, RightShoulder = { 42, 0, 6 }, RightElbow = { 46 },
	}, "settle" },
	{ R + 2, { Body = { 0, -0.98, -0.34 }, Turn = { -6, 0, 0 }, Waist = { -10, 0, 0 }, Neck = { 8, 4, 0 } } },
	{ R + 10, { Body = { 0, -0.98, -0.34 }, Waist = { -10, 0, 0 }, Neck = { 8, 2, 0 }, RightShoulder = { 42, 0, 6 }, RightElbow = { 46 } } },
	{ R + 20, { Body = { 0, -0.97, -0.38 }, Waist = { -14, 4, 0 }, Neck = { 12, 20, 5 }, RightShoulder = { 74, 14, 2 }, RightElbow = { 112 } }, "settle" },
	{ R + 33, { Body = { 0, -0.97, -0.38 }, Waist = { -14, 2, 0 }, Neck = { 13, 8, 4 }, RightShoulder = { 72, 14, 2 }, RightElbow = { 114 } } },
}, { Neck = 1, RightElbow = 1 })

local function television(root, at, host)
	S.part(root, "TV surround", at, V(6.9, 4.0, 0.28), "171C22")
	S.part(root, "TV foot", at * CF(0, -2.15, 0), V(1.8, 0.35, 0.7), "171C22")
	local panel = S.part(root, "TV panel", at * CF(0, 0, 0.16), V(6.56, 3.69, 0.04), "05070C")
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.PixelsPerStud = Enum.NormalId.Back, Enum.SurfaceGuiSizingMode.PixelsPerStud, 110
	gui.LightInfluence, gui.Brightness = 0, 1.15
	-- A live viewport on a surface only renders for the player it belongs to.
	gui.Name, gui.ResetOnSpawn, gui.Adornee, gui.Parent = "Cove TV", false, panel, host
	local view = Instance.new("ViewportFrame")
	view.Size, view.BackgroundColor3, view.BorderSizePixel = UDim2.fromScale(1, 1), Color3.fromHex("5FB4C8"), 0
	view.Ambient, view.LightColor, view.LightDirection = Color3.fromHex("9A93B4"), Color3.fromHex("FFE9C9"), V(-0.5, -0.7, -0.5)
	view.ImageColor3, view.Parent = Color3.fromHex("E8E2FF"), gui
	local eye = Instance.new("Camera")
	eye.FieldOfView, eye.Parent, view.CurrentCamera = 34, view, eye
	-- The news camera is across the boulevard from the mine you can walk into.
	local world = Instance.new("WorldModel")
	world.Parent = view
	local cove = script.Parent.CoveReplay["Present-day cove"]
	for _, part in cove:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 0.9 then
			local p, reach = part.Position, part.Size.Magnitude
			if math.abs(p.X) < 34 and p.Z > -34 and p.Z < 34 and p.Y > 14 and p.Y < 72 and reach < 70 then
				local copy = part:Clone()
				copy:ClearAllChildren()
				copy.Parent = world
			end
		end
	end
	local function glow(size, alpha)
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency, image.Image = 1, "rbxasset://textures/particles/smoke_main.dds"
		image.ImageColor3, image.ImageTransparency = Color3.fromHex("B77BFF"), alpha
		image.AnchorPoint, image.Position, image.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.56), UDim2.fromScale(size, size * 1.6)
		image.ZIndex, image.Parent = 3, gui
		return image
	end
	local glows = { glow(0.34, 0.1), glow(0.62, 0.45), glow(1.0, 0.7) }
	local function text(str, x, y, w, h, color, back, font)
		local label = Instance.new("TextLabel")
		label.Text, label.TextScaled, label.BorderSizePixel = str, true, 0
		label.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", font or Enum.FontWeight.Bold)
		label.Position, label.Size = UDim2.fromScale(x, y), UDim2.fromScale(w, h)
		label.TextColor3, label.BackgroundColor3, label.ZIndex, label.Parent = Color3.fromHex(color), Color3.fromHex(back), 6, gui
		local pad = Instance.new("UIPadding")
		pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight =
			UDim.new(0.16, 0), UDim.new(0.16, 0), UDim.new(0.04, 0), UDim.new(0.04, 0)
		pad.Parent = label
		return label
	end
	local live = text("LIVE", 0.045, 0.07, 0.12, 0.1, "FFFFFF", "D2303E")
	text("COVE TV", 0.165, 0.07, 0.2, 0.1, "FFFFFF", "17243A")
	local low = text("STRANGE LIGHT IN CITRINE COVE MINE", 0.045, 0.79, 0.80, 0.125, "17243A", "F7F3E6", Enum.FontWeight.ExtraBold)
	low.TextXAlignment = Enum.TextXAlignment.Left
	local spill = S.part(root, "TV light", at * CF(0, 0, 1.6), Vector3.one * 0.05, "FFFFFF")
	spill.Transparency = 1
	return { gui = gui, eye = eye, glows = glows, live = live, light = S.light(spill, "B48CFF", 15, 1.4) }
end

local function set(root)
	local wall, trim, oak, walnut = "5E8C87", "EFE6D2", "B98656", "7C553B"
	local shell = {
		S.part(root, "Floor", CF(0, -0.25, 6), V(26, 0.5, 22), "A97B52", M.WoodPlanks),
		S.part(root, "TV wall", CF(0, 6, -0.4), V(26, 13, 0.6), wall),
		S.part(root, "Left wall", CF(-11, 6, 6), V(0.6, 13, 22), "679690"),
		S.part(root, "Right wall", CF(11, 6, 6), V(0.6, 13, 22), "679690"),
		S.part(root, "Back wall", CF(0, 6, 15.4), V(26, 13, 0.6), "C9A983"),
	}
	for _, p in shell do p.CastShadow = false end
	S.part(root, "Skirting", CF(0, 0.35, 0), V(22, 0.7, 0.3), trim)
	S.part(root, "Picture rail", CF(0, 8.2, 0), V(22, 0.22, 0.25), trim)
	S.part(root, "Rug", CF(0, 0.04, 5.6), V(11, 0.08, 7), "C65B4E", M.Fabric)
	S.part(root, "Rug border", CF(0, 0.05, 5.6), V(10.2, 0.08, 6.2), "E6C98F", M.Fabric)
	S.part(root, "Rug field", CF(0, 0.06, 5.6), V(9.6, 0.08, 5.6), "B44C48", M.Fabric)
	-- Media bench
	S.part(root, "Bench", CF(0, 1.0, 0.95), V(9.2, 1.5, 1.7), walnut, M.Wood)
	S.part(root, "Bench top", CF(0, 1.8, 0.95), V(9.6, 0.18, 1.9), oak, M.Wood)
	for _, x in { -3, 0, 3 } do
		S.part(root, "Door", CF(x, 1.0, 1.83), V(2.8, 1.15, 0.08), "8C6143", M.Wood)
		S.part(root, "Knob", CF(x + 1.05, 1.0, 1.9), V(0.14, 0.14, 0.14), "D8B46A", M.Metal)
	end
	S.part(root, "Speaker", CF(4.3, 2.5, 0.95), V(0.9, 1.25, 0.8), "2B333B")
	local cone = S.part(root, "Cone", CF(4.3, 2.4, 1.37), V(0.06, 0.6, 0.6), "566069")
	cone.Shape, cone.CFrame = Enum.PartType.Cylinder, cone.CFrame * A(0, math.pi / 2, 0)
	for i, c in { "D96B4C", "E8C05A", "4F9A92" } do
		S.part(root, "Book", CF(-4.6 + i * 0.22, 2.25, 0.9), V(0.18, 0.75 - 0.06 * i, 0.6), c)
	end
	-- Pictures, shelf, plant, lamp
	for i, p in { { -6.4, 5.5, 2.2, 2.9, "E9C06A" }, { -8.6, 5.0, 1.5, 1.9, "D8745C" }, { 6.6, 5.6, 2.6, 1.9, "7FB7C9" } } do
		S.part(root, "Frame", CF(p[1], p[2], 0), V(p[3], p[4], 0.16), walnut, M.Wood)
		S.part(root, "Print", CF(p[1], p[2], 0.1), V(p[3] - 0.3, p[4] - 0.3, 0.04), "F4EBD8")
		S.part(root, "Motif", CF(p[1], p[2] - 0.1, 0.13) * A(0, 0, math.rad(if i == 3 then 0 else 45)), V(p[3] * 0.38, p[3] * 0.38, 0.04), p[5])
	end
	S.part(root, "Plant pot", CF(7.9, 0.75, 1.4), V(1.3, 1.5, 1.3), "D98E5C")
	for i = 0, 8 do
		local a = i * 2.4
		S.strut(root, "Leaf", V(7.9, 1.4, 1.4), V(7.9 + math.cos(a) * 1.15, 3.1 + 0.25 * (i % 4), 1.4 + math.sin(a) * 0.9), 0.36, 0.1, if i % 2 == 0 then "4E8B57" else "66A465")
	end
	S.part(root, "Lamp stem", CF(-8.2, 2.3, 1.8), V(0.16, 4.6, 0.16), "3B3F45", M.Metal)
	S.part(root, "Lamp foot", CF(-8.2, 0.1, 1.8), V(1.3, 0.2, 1.3), "3B3F45", M.Metal)
	local shade = S.part(root, "Lamp shade", CF(-8.2, 4.9, 1.8), V(1.7, 1.3, 1.7), "FFE3AE", M.Neon)
	S.light(shade, "FFCB86", 16, 0.8)
	-- Sofa and footstool
	local sofa, deep = "D8A83F", "BE8F2E"
	S.part(root, "Sofa base", CF(1.1, 0.62, 9.6), V(7.6, 0.75, 3.0), deep)
	S.part(root, "Sofa back", CF(1.1, 2.15, 11.0), V(7.6, 2.5, 0.9), sofa)
	for _, x in { -1, 1 } do
		S.part(root, "Sofa arm", CF(1.1 + x * 3.6, 1.35, 9.6), V(0.8, 1.7, 3.1), sofa)
		S.part(root, "Cushion", CF(1.1 + x * 1.62, 1.14, 9.35), V(3.1, 0.5, 2.5), sofa)
	end
	S.part(root, "Throw pillow", CF(-1.0, 1.9, 10.2) * A(math.rad(-18), math.rad(20), 0), V(1.3, 1.2, 0.45), "4F8F8A")
	S.part(root, "Footstool", CF(-2.1, 0.55, 6.45), V(1.9, 0.9, 1.7), "4F8F8A")
	S.part(root, "Footstool feet", CF(-2.1, 0.08, 6.45), V(1.6, 0.16, 1.4), walnut, M.Wood)
	S.part(root, "Back print", CF(-5.4, 5.6, 15.05), V(2.6, 3.2, 0.14), "F0E6D0")
	S.part(root, "Back motif", CF(-5.4, 5.6, 14.96) * A(0, 0, math.rad(45)), V(1.1, 1.1, 0.06), "7C63C7")
	S.part(root, "Bookcase", CF(6.6, 4, 14.6), V(4.2, 8, 1.1), walnut, M.Wood)
	for row = 0, 3 do
		S.part(root, "Shelf", CF(6.6, 1.1 + row * 1.9, 14.15), V(3.8, 1.5, 0.4), "4B3527")
		for i = 0, 8 do
			local c = ({ "C65B4E", "E6C05A", "4F9A92", "E9DDBF", "52679B" })[(i * 3 + row) % 5 + 1]
			S.part(root, "Book", CF(5.0 + i * 0.4, 0.95 + row * 1.9 + 0.04 * (i % 3), 14.0), V(0.3, 1.1 + 0.1 * (i % 3), 0.3), c)
		end
	end
end

function Room.new(stage, place, sun, host)
	local want = V(-0.72, 0, 0.69)
	local yaw = math.atan2(sun.X, sun.Z) - math.atan2(want.X, want.Z)
	local at = CF(place) * A(0, yaw, 0)
	local root = S.group("Living room")
	set(root)
	local tv = television(root, CF(0, 4.15, 0.55), host)
	root:PivotTo(at)
	return setmetatable({ stage = stage, root = root, at = at, tv = tv }, Room)
end

local function grounded(rig, at)
	return at * CF(0, rig.stand, 0)
end

function Room:seat()
	if self.kid then return end
	local function performer(name)
		local rig = Avatar.new(script.Parent.CoveCast[name])
		return rig, math.clamp(rig.stand / 3, 0.7, 1.15)
	end
	self.kid, self.kidUnit = performer("Kid")
	self.sib, self.sibUnit = performer("Sibling")
	self.kidAt = grounded(self.kid, self.at * CF(-2.1, 0, 6.5))
	self.sibAt = grounded(self.sib, self.at * CF(2.9, 0, 9.3) * A(0, math.rad(9), 0))
end

function Room:draw(frame, motion)
	local active = frame >= F.living and frame < F.witness
	local warm = frame >= F.living - 34 and frame < F.living
	self.root.Parent = if active or warm then self.stage else nil
	self.tv.gui.Enabled = active or warm
	if not active and not warm then
		if self.kid then self.kid.model.Parent, self.sib.model.Parent = nil, nil end
		return
	end
	self:seat()
	local f = if motion then frame else math.max(frame, if frame < F.livingReverse then F.living + 30 else F.livingReverse + 20)
	self.kid:place(Acting.perform(self.kid, kidClip, f, self.kidAt, self.kidUnit))
	self.sib:place(Acting.perform(self.sib, sibClip, f, self.sibAt, self.sibUnit))
	self.kid:show(self.stage)
	self.sib:show(self.stage)
	local age = if motion then frame - F.living else 30
	local tv = self.tv
	tv.eye.CFrame = CFrame.lookAt(V(-7 + 0.045 * age, 34.5, 52 - 0.09 * age), V(0, 37, 4))
	local pulse = 0.5 + 0.5 * math.sin(age / 6)
	for i, g in tv.glows do
		g.ImageTransparency = ({ 0.05, 0.35, 0.62 })[i] + 0.16 * pulse
		g.Rotation = age * (0.7 - 0.5 * i)
	end
	tv.light.Brightness = 1.5 + 0.5 * pulse
	tv.live.BackgroundTransparency = if age % 24 < 16 then 0 else 0.35
end

function Room:camera(frame, motion)
	if frame < F.livingReverse then
		local u = if motion then S.ease(frame, F.living - 6, F.livingReverse + 14) else 0.5
		-- Over both shoulders, across the sofa, easing toward the glass.
		local eye = V(0.75 - 0.35 * u, 4.5 - 0.15 * u, 14.6 - 1.9 * u)
		return eye, V(0.25, 3.35 + 0.15 * u, 2.4), 36, 0
	end
	local u = if motion then S.ease(frame, F.livingReverse - 4, F.witness + 6) else 0.5
	return V(0.9 - 0.35 * u, 2.75 + 0.05 * u, 0.95 + 0.3 * u), V(0.35 - 0.1 * u, 2.45, 7.6), 56, 0
end

function Room:Destroy()
	if self.kid then
		self.kid:destroy()
		self.sib:destroy()
	end
	self.tv.gui:Destroy()
	self.root:Destroy()
end

return Room
