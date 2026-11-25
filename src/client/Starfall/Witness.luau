-- Someone in the plaza, filming the player on a phone. It is welded into the
-- right fist, its lens follows the player, and the arm is solved to wherever
-- that phone has to be.
local F = require(script.Parent.ExposureSheet).frames
local Acting = require(script.Parent.Acting)
local Avatar = require(script.Parent.CinematicAvatar)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local Witness = {}
Witness.__index = Witness

local clip = Acting.clip({
	{ F.witness - 6, {
		Body = { 0, -0.04, 0 }, Turn = { 0, 0, 0 }, Waist = { -2, -3, 0 }, Neck = { -1, -20, 2 }, LeftShoulder = { 6, 0, -8 }, LeftElbow = { 18 }, Hold = { 0, 0, 0 },
		LeftFoot = { -0.14, 0, -0.2 }, RightFoot = { 0.14, 0, 0.16 }, LeftFootTurn = { 0, 10 }, RightFootTurn = { 0, -14 },
	} },
	{ F.witness + 22, { Body = { 0.03, -0.04, -0.02 }, Waist = { -3, -1, 0 }, Neck = { -2, -21, 2 }, LeftShoulder = { 8, 0, -9 }, LeftElbow = { 22 }, Hold = { 0.02, 0.02, 0 } } },
	-- The player goes by. A glance over the top of the phone, then back to it.
	{ F.witness + 36, { Body = { 0.02, -0.05, 0 }, Waist = { 0, 5, 0 }, Neck = { -4, 4, -3 }, LeftShoulder = { 6, 0, -9 }, LeftElbow = { 20 }, Hold = { -0.03, -0.14, 0 } } },
	{ F.witness + 48, { Body = { 0, -0.06, -0.03 }, Waist = { -2, 3, 0 }, Neck = { -2, -14, -1 }, Hold = { -0.02, -0.10, 0 } } },
	{ F.enter - 6, { Body = { 0, -0.02, 0.04 }, Waist = { 4, 2, 0 }, Neck = { 4, 2, 0 }, Hold = { 0, -0.02, 0 } } },
})

local family = "rbxasset://fonts/families/Montserrat.json"
local function label(parent, str, x, y, w, h, align)
	local t = Instance.new("TextLabel")
	t.Text, t.TextScaled, t.BackgroundTransparency, t.ZIndex = str, true, 1, 6
	t.FontFace = Font.new(family, Enum.FontWeight.Bold)
	t.TextColor3, t.Position, t.Size, t.Parent = Color3.new(1, 1, 1), UDim2.fromScale(x, y), UDim2.fromScale(w, h), parent
	t.TextXAlignment = align or Enum.TextXAlignment.Left
	return t
end

local function frame(parent, x, y, w, h, color, alpha, corner)
	local f = Instance.new("Frame")
	f.BorderSizePixel, f.BackgroundColor3, f.BackgroundTransparency, f.ZIndex = 0, Color3.fromHex(color), alpha or 0, 5
	f.Position, f.Size, f.Parent = UDim2.fromScale(x, y), UDim2.fromScale(w, h), parent
	if corner then
		local round = Instance.new("UICorner")
		round.CornerRadius, round.Parent = UDim.new(corner, 0), f
	end
	return f
end

-- A camera app, live. The picture is the street itself, through the glass.
local function viewfinder(glass)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face = "Viewfinder", Enum.NormalId.Back
	gui.SizingMode, gui.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, 340
	gui.LightInfluence, gui.Parent = 0, glass
	local W, H = glass.Size.X, glass.Size.Y
	-- The panel is brighter than the street behind it.
	frame(gui, 0, 0, 1, 1, "EADFFF", 0.91).ZIndex = 1
	local sheen = frame(gui, 0, 0, 1, 1, "FFFFFF")
	sheen.ZIndex = 2
	local sweep = Instance.new("UIGradient")
	sweep.Rotation, sweep.Parent = 62, sheen
	sweep.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.84), NumberSequenceKeypoint.new(0.24, 0.93), NumberSequenceKeypoint.new(0.25, 1), NumberSequenceKeypoint.new(1, 1),
	})
	-- Black face with rounded corners.
	local bezel = frame(gui, 0.5, 0.5, 1, 1, "000000", 1, 0.11)
	bezel.AnchorPoint = Vector2.new(0.5, 0.5)
	local rim = Instance.new("UIStroke")
	rim.Thickness, rim.Color, rim.Parent = 26, Color3.fromHex("08090D"), bezel
	bezel.Size = UDim2.new(1, -30, 1, -30)
	frame(gui, 0.36, 0.028, 0.28, 0.040, "1B1E26", 0, 0.5)
	-- Shutter, last picture, flip.
	local ratio = W / H
	local ring = frame(gui, 0.5, 0.885, 0.27, 0.27 * ratio, "FFFFFF", 0, 0.5)
	local hole = frame(gui, 0.5, 0.885, 0.225, 0.225 * ratio, "08090D", 0, 0.5)
	local stop = frame(gui, 0.5, 0.885, 0.105, 0.105 * ratio, "FF3B4E", 0, 0.22)
	local last = frame(gui, 0.2, 0.885, 0.14, 0.14 * ratio, "8E4DF5", 0, 0.24)
	local flip = frame(gui, 0.8, 0.885, 0.14, 0.14 * ratio, "2B2E38", 0, 0.5)
	for _, f in { ring, hole, stop, last, flip } do f.AnchorPoint = Vector2.new(0.5, 0.5) end
	hole.ZIndex, stop.ZIndex = 6, 7
	local pill = frame(gui, 0.07, 0.132, 0.36, 0.062, "E5283E", 0, 0.28)
	local dot = frame(pill, 0.13, 0.5, 0.17, 0.5, "FFFFFF", 0, 0.5)
	dot.AnchorPoint, dot.ZIndex = Vector2.new(0.5, 0.5), 7
	label(pill, "LIVE", 0.30, 0.14, 0.62, 0.72)
	local count = label(gui, "1.2K", 0.62, 0.136, 0.30, 0.054, Enum.TextXAlignment.Right)
	-- Two comments, the way a live stream has them.
	for k, str in { "is that the mine??", "GO GO GO" } do
		local chip = frame(gui, 0.07, 0.635 + 0.075 * (k - 1), if k == 1 then 0.66 else 0.42, 0.06, "0B0D14", 0.45, 0.4)
		label(chip, str, 0.08, 0.16, 0.86, 0.68)
	end
	-- Focus marks on whoever it is following.
	for _, c in { { 0.24, 0.27, 1, 1 }, { 0.76, 0.27, -1, 1 }, { 0.24, 0.60, 1, -1 }, { 0.76, 0.60, -1, -1 } } do
		frame(gui, c[1] - (if c[3] < 0 then 0.10 else 0), c[2], 0.10, 0.007, "FFE27A")
		frame(gui, c[1], c[2] - (if c[4] < 0 then 0.10 * ratio - 0.007 else 0), 0.014, 0.10 * ratio, "FFE27A")
	end
	return dot, count
end

function Witness.new(stage)
	local rig = Avatar.new(script.Parent.CoveCast.Witness)
	local glass = rig.model.Phone
	local dot, count = viewfinder(glass)
	local behind = {}
	for _, part in rig.model:GetChildren() do
		-- The picture is seen through the phone, so nothing solid may sit behind it.
		if table.find({ "Phone back", "Camera block", "Phone lens", "Phone lamp", "Finger" }, part.Name) then
			table.insert(behind, part)
		end
	end
	return setmetatable({
		stage = stage, rig = rig, glass = glass, dot = dot, count = count, behind = behind,
		-- Hand seen from the phone, fixed by the weld that was baked in.
		seat = glass.CFrame:ToObjectSpace(rig.model.RightHand.CFrame),
	}, Witness)
end

function Witness:place(at)
	self.stand = at * CF(0, self.rig.stand, 0)
end

function Witness:draw(f, motion, target)
	-- Dressed and posed while the interiors play, so nothing loads on the cut.
	if not self.stand or f < F.dig or f >= F.enter then
		self.rig.model.Parent = nil
		return
	end
	local rig, seat = self.rig, self.seat
	local at = if motion then f else F.witness + 30
	local base = Acting.perform(rig, clip, at, self.stand, 1)
	local hx, hy = Acting.read(clip, "Hold", at)
	-- Aim the phone first. The right hand is wherever its weld says it must be.
	local head = rig:partFrame(rig.model.Head, base)
	local sway = if motion then math.sin(f / 17) * 0.012 else 0
	local at0 = CF(head.Position) * self.stand.Rotation * V(1.02 + hx + sway, 0.10 + hy, -1.62)
	local ahead = self.stand * V(0, 1.3, -14)
	local aim = if target then Vector3.new(target.X, at0.Y + (target.Y - at0.Y) * 0.6, target.Z) else ahead
	local phone = CFrame.lookAt(at0, aim) * A(0, 0, sway * 1.5)
	self.phone = phone
	local pole = base:VectorToWorldSpace(V(0.35, -1, 0.1))
	rig:carry("RightShoulder", "RightElbow", "RightWrist", phone * seat, pole, base)
	rig:place(base)
	rig:show(self.stage)
	for _, part in self.behind do
		part.Transparency = 1
	end
	self.count.Text = string.format("%.1fK", 1.2 + 0.1 * math.floor(math.max(0, f - F.witness) / 8))
	self.dot.BackgroundTransparency = if f % 24 < 14 then 0 else 0.6
end

function Witness:Destroy()
	self.rig:destroy()
end

return Witness
