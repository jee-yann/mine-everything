-- Someone in the plaza, filming the light. The phone is welded into the right
-- fist and the arm is solved to wherever that phone has to be.
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

local function label(parent, str, x, y, w, h)
	local t = Instance.new("TextLabel")
	t.Text, t.TextScaled, t.BackgroundTransparency = str, true, 1
	t.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
	t.TextColor3, t.Position, t.Size, t.Parent = Color3.new(1, 1, 1), UDim2.fromScale(x, y), UDim2.fromScale(w, h), parent
	t.TextXAlignment = Enum.TextXAlignment.Left
end

local function frame(parent, x, y, w, h, color, alpha)
	local f = Instance.new("Frame")
	f.BorderSizePixel, f.BackgroundColor3, f.BackgroundTransparency = 0, Color3.fromHex(color), alpha or 0
	f.Position, f.Size, f.Parent = UDim2.fromScale(x, y), UDim2.fromScale(w, h), parent
	return f
end

function Witness.new(stage)
	local rig = Avatar.new(script.Parent.CoveCast.Witness)
	local glass = rig.model.Phone
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face = "Viewfinder", Enum.NormalId.Back
	gui.SizingMode, gui.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, 260
	gui.LightInfluence, gui.Parent = 0, glass
	local dot = frame(gui, 0.07, 0.066, 0.075, 0.045, "FF3B4E")
	local round = Instance.new("UICorner")
	round.CornerRadius, round.Parent = UDim.new(1, 0), dot
	label(gui, "LIVE", 0.17, 0.052, 0.3, 0.075)
	label(gui, "Citrine Cove", 0.07, 0.60, 0.62, 0.065)
	for _, c in { { 0.03, 0.04, 1, 1 }, { 0.97, 0.04, -1, 1 }, { 0.03, 0.72, 1, -1 }, { 0.97, 0.72, -1, -1 } } do
		frame(gui, c[1] - (if c[3] < 0 then 0.06 else 0), c[2], 0.06, 0.012, "FFFFFF", 0.25)
		frame(gui, c[1], c[2] - (if c[4] < 0 then 0.1 else 0), 0.006, 0.1, "FFFFFF", 0.25)
	end
	local behind = {}
	for _, part in rig.model:GetChildren() do
		if part.Name == "Phone back" or part.Name == "Phone lens" or part.Name == "Finger" then
			table.insert(behind, part)
		end
	end
	return setmetatable({
		stage = stage, rig = rig, glass = glass, dot = dot, behind = behind,
		-- Hand seen from the phone, fixed by the weld that was baked in.
		seat = glass.CFrame:ToObjectSpace(rig.model.RightHand.CFrame),
	}, Witness)
end

function Witness:place(at)
	self.stand = at * CF(0, self.rig.stand, 0)
end

function Witness:draw(f, motion)
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
	local sway = if motion then math.sin(f / 17) * 0.015 else 0
	local phone = CF((head * CF(0, -0.28, 0)).Position) * self.stand.Rotation
		* CF(1.22 + hx + sway, 0.36 + hy, -1.72) * A(math.rad(-3), math.rad(7), sway)
	local pole = base:VectorToWorldSpace(V(0.35, -1, 0.1))
	rig:carry("RightShoulder", "RightElbow", "RightWrist", phone * seat, pole, base)
	rig:place(base)
	rig:show(self.stage)
	for _, part in self.behind do
		part.Transparency = 1
	end
	self.dot.BackgroundTransparency = if f % 24 < 14 then 0 else 0.6
end

function Witness:Destroy()
	self.rig:destroy()
end

return Witness
