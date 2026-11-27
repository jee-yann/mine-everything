-- A home across the island. Two siblings see the light in the mine on the news.
--
-- The engine applies local lights a few exposures after a cut, so nothing here
-- depends on one. The sun is the key in both angles. It and the fill are global
-- and land on the first exposure. In the wide it is late light through a window.
-- The reverse is the same room turned until the sun comes from the screen, in
-- the colour of the report, so the faces are lit by what they are watching.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local Acting = require(script.Parent.Acting)
local Avatar = require(script.Parent.CinematicAvatar)
local MouthGlow = require(script.Parent.MouthGlow)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local M = Enum.Material
local hex = Color3.fromHex
local Room = {}
Room.__index = Room

local O, R = F.living, F.livingReverse

-- The kid is already half off the footstool. They point, look round to make
-- sure it is not just them, get their answer, and lean back in to the screen.
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
	{ O + 38, { RightShoulder = { 92, 4, 7 }, RightElbow = { 10 }, Neck = { 12, -10, -3 }, Body = { 0, -0.86, -0.2 }, Waist = { -12, 13, 0 } } },
	{ R + 1, { Body = { 0, -0.87, -0.14 }, Turn = { -6, 0, 0 }, Waist = { -8, 10, 0 }, Neck = { 10, -6, 0 }, RightShoulder = { 74, 2, 12 }, RightElbow = { 28 } } },
	-- Is it only me?
	{ R + 10, { Body = { 0, -0.80, -0.08 }, Turn = { -2, -17, 0 }, Waist = { -2, -24, 0 }, Neck = { 4, -48, 4 }, RightShoulder = { 46, 4, 16 }, RightElbow = { 52 }, LeftShoulder = { 38, 0, -18 } } },
	{ R + 20, { Body = { 0, -0.80, -0.08 }, Turn = { -2, -18, 0 }, Waist = { -2, -25, 0 }, Neck = { 1, -50, 4 }, RightShoulder = { 44, 4, 16 }, RightElbow = { 54 } } },
	-- No. Back to it, closer than before, with both hands on the stool.
	{ R + 29, { Body = { 0, -0.90, -0.26 }, Turn = { -8, 0, 0 }, Waist = { -14, 2, 0 }, Neck = { 18, 0, 2 }, RightShoulder = { 30, 0, 10 }, RightElbow = { 40 }, LeftShoulder = { 30, 0, -12 }, LeftElbow = { 38 } }, "settle" },
	{ F.witness + 2, { Body = { 0, -0.90, -0.31 }, Turn = { -9, 0, 0 }, Waist = { -15, 1, 0 }, Neck = { 20, 0, 2 }, RightShoulder = { 30, 0, 10 }, RightElbow = { 40 }, LeftShoulder = { 30, 0, -12 } } },
}, { RightElbow = 1, RightWrist = 2, Neck = -1 })

-- The older one starts sunk into the sofa and ends on the edge of it. The look
-- they give back is the answer.
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
	{ R + 1, { Body = { 0, -0.98, -0.34 }, Turn = { -6, 0, 0 }, Waist = { -10, 0, 0 }, Neck = { 8, 4, 0 } } },
	{ R + 9, { Body = { 0, -0.98, -0.34 }, Waist = { -10, 0, 0 }, Neck = { 8, 4, 0 }, RightShoulder = { 42, 0, 6 }, RightElbow = { 46 } } },
	{ R + 17, { Body = { 0, -0.97, -0.36 }, Waist = { -12, 8, 0 }, Neck = { 10, 38, 5 }, RightShoulder = { 46, 4, 6 }, RightElbow = { 60 } }, "settle" },
	{ R + 22, { Body = { 0, -0.97, -0.36 }, Waist = { -12, 8, 0 }, Neck = { 7, 38, 5 }, RightShoulder = { 46, 4, 6 }, RightElbow = { 62 } } },
	{ R + 31, { Body = { 0, -0.96, -0.42 }, Turn = { -8, 0, 0 }, Waist = { -15, 0, 0 }, Neck = { 17, 2, 2 }, RightShoulder = { 54, 2, 2 }, RightElbow = { 34 }, LeftShoulder = { 54, -2, -2 }, LeftElbow = { 34 } }, "settle" },
	{ F.witness + 2, { Body = { 0, -0.96, -0.46 }, Turn = { -9, 0, 0 }, Waist = { -16, 0, 0 }, Neck = { 18, 1, 2 }, RightShoulder = { 54, 2, 2 }, RightElbow = { 36 }, LeftShoulder = { 54, -2, -2 } } },
}, { Neck = 1, RightElbow = 1 })

-- The set is a window in the wall. Behind its glass stands a model of today's
-- cove, built from the same parts as the place itself, in the same sun, with
-- the same light coming out of it. A viewport cannot cast a shadow. This can.
local glassAt = CF(0, 4.15, 0.62)
local screenSize = V(6.56, 3.69, 0)
local lensAt = V(0.5, 4.42, 13.4)
local subject = V(0, 37.6, 5)
local newsEye = V(-19, 40, 113)
local scale = 0.2

-- Map space to room space. The news camera's eye lands on the room's lens, so
-- the picture on the glass is the picture from the far end of the boulevard.
local function broadcast()
	local aim = glassAt.Position - lensAt
	local shot = subject - newsEye
	local turn = math.atan2(-aim.X, -aim.Z) - math.atan2(-shot.X, -shot.Z)
	return CF(lensAt) * A(0, turn, 0) * CF(-newsEye * scale)
end

-- Pull a part that reaches through the wall back to the far side of it.
local function behindWall(part, plane)
	local cf, size = part.CFrame, part.Size
	local far = cf.Position.Z
	for _, axis in { { cf.XVector, size.X }, { cf.YVector, size.Y }, { cf.ZVector, size.Z } } do
		far += math.abs(axis[1].Z) * axis[2] / 2
	end
	if far <= plane then
		return true
	end
	if not part:IsA("Part") or math.abs(cf.YVector.Y) < 0.98 then
		return false
	end
	local alongX = math.abs(cf.XVector.Z) > math.abs(cf.ZVector.Z)
	local axis = if alongX then cf.XVector else cf.ZVector
	local cut = (far - plane) / math.abs(axis.Z)
	local length = (if alongX then size.X else size.Z) - cut
	if length < 0.05 then
		return false
	end
	part.Size = if alongX then V(length, size.Y, size.Z) else V(size.X, size.Y, length)
	part.CFrame = cf - axis * math.sign(axis.Z) * cut / 2
	return true
end

local function footage(root)
	local at = broadcast()
	local cove = script.Parent.CoveReplay["Present-day cove"]
	local model = S.group("Cove on the news")
	local painted = {}
	local half = math.max(screenSize.X, screenSize.Y) * 0.5
	for _, source in cove:GetDescendants() do
		if source:IsA("BasePart") and source.Transparency < 0.9 then
			local p = at * (source.Position * scale)
			local reach = source.Size.Magnitude * scale * 0.5
			local depth = lensAt.Z - p.Z
			-- Only what the lens can see through the glass.
			local across = half * depth / (lensAt.Z - glassAt.Z) * 1.12 + reach + 0.6
			if p.Z - reach < -1.2 and depth < 64 and math.abs(p.X - lensAt.X) < across and math.abs(p.Y - lensAt.Y) < across and source.Size.Magnitude * scale > 0.05 then
				local copy = source:Clone()
				copy.Size = source.Size * scale
				copy.CFrame = at * (source.CFrame.Rotation + source.Position * scale)
				-- Studs are drawn at world size. At this scale they would be boulders.
				copy.TopSurface, copy.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
				for _, child in copy:GetChildren() do
					if child:IsA("SurfaceGui") then
						child.PixelsPerStud /= scale
					else
						child:Destroy()
					end
				end
				if behindWall(copy, -0.85) then
					copy.Parent = model
					-- Where the star's light falls, painted on, because a lamp in here
					-- would be late on the cut.
					local from = source.Position - V(0, 28, 4)
					local near = math.max(0, 1 - from.Magnitude / 24) * (if from.Z > -9 then 1 else 0.6)
					if near > 0 and source.Material ~= M.Neon and source.Size.Magnitude < 34 then
						table.insert(painted, { part = copy, base = copy.Color, amount = 0.62 * near ^ 0.7 })
					end
				else
					copy:Destroy()
				end
			end
		end
	end
	model.Parent = root
	-- Open sky behind the highlands.
	local sky = S.part(root, "Sky on the news", CF(0, 8, -60), V(90, 60, 0.2), "FFFFFF")
	sky.CastShadow = false
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.LightInfluence, gui.SizingMode, gui.PixelsPerStud, gui.Parent = Enum.NormalId.Back, 0, Enum.SurfaceGuiSizingMode.PixelsPerStud, 6, sky
	local field = Instance.new("Frame")
	field.Size, field.BorderSizePixel, field.BackgroundColor3, field.Parent = UDim2.fromScale(1, 1), 0, Color3.new(1, 1, 1), gui
	local blend = Instance.new("UIGradient")
	blend.Color, blend.Rotation, blend.Parent = ColorSequence.new(hex("3E9BD6"), hex("C4EAF4")), 90, field
	local glow = MouthGlow.new(root, scale, false)
	return glow, at * CF(V(0, 27.705, 5.25) * scale), painted
end

local function television(root, host)
	local at = glassAt
	local w, h = screenSize.X, screenSize.Y
	for _, q in { { 0, h / 2 + 0.085, w + 0.34, 0.17 }, { 0, -h / 2 - 0.085, w + 0.34, 0.17 }, { w / 2 + 0.085, 0, 0.17, h }, { -w / 2 - 0.085, 0, 0.17, h } } do
		S.part(root, "TV surround", at * CF(q[1], q[2], -0.1), V(q[3], q[4], 0.34), "12161B")
	end
	-- The dark inside of the cabinet, behind the bezel, back to the wall.
	for _, q in { { 0, h / 2 + 0.31, w + 0.9, 0.2 }, { 0, -h / 2 - 0.31, w + 0.9, 0.2 }, { w / 2 + 0.46, 0, 0.2, h + 0.6 }, { -w / 2 - 0.46, 0, 0.2, h + 0.6 } } do
		S.part(root, "TV cabinet", at * CF(q[1], q[2], -0.86), V(q[3], q[4], 1.0), "07080B", M.Neon).CastShadow = false
	end
	S.part(root, "TV foot", at * CF(0, -2.15, -0.07), V(1.8, 0.35, 0.7), "171C22")
	local panel = S.part(root, "TV panel", at, V(w, h, 0.04), "05070C")
	panel.Transparency, panel.CastShadow = 1, false
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.PixelsPerStud = Enum.NormalId.Back, Enum.SurfaceGuiSizingMode.PixelsPerStud, 110
	gui.LightInfluence, gui.Name, gui.ResetOnSpawn, gui.Adornee, gui.Parent = 0, "Cove TV", false, panel, host
	-- The panel's own light, a little reflection and the fall-off at its edges.
	local tint = Instance.new("Frame")
	tint.Size, tint.BorderSizePixel, tint.BackgroundColor3, tint.BackgroundTransparency, tint.Parent = UDim2.fromScale(1, 1), 0, hex("D9CCFF"), 0.93, gui
	local sheen = Instance.new("Frame")
	sheen.Size, sheen.BorderSizePixel, sheen.BackgroundColor3, sheen.ZIndex, sheen.Parent = UDim2.fromScale(1, 1), 0, Color3.new(1, 1, 1), 2, gui
	local sweep = Instance.new("UIGradient")
	sweep.Rotation, sweep.Parent = 24, sheen
	sweep.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.90), NumberSequenceKeypoint.new(0.30, 0.95), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(1, 1),
	})
	local function text(str, x, y, tw, th, color, back, font)
		local label = Instance.new("TextLabel")
		label.Text, label.TextScaled, label.BorderSizePixel = str, true, 0
		label.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", font or Enum.FontWeight.Bold)
		label.Position, label.Size = UDim2.fromScale(x, y), UDim2.fromScale(tw, th)
		label.TextColor3, label.BackgroundColor3, label.ZIndex, label.Parent = hex(color), hex(back), 6, gui
		local pad = Instance.new("UIPadding")
		pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = UDim.new(0.16, 0), UDim.new(0.16, 0), UDim.new(0.04, 0), UDim.new(0.04, 0)
		pad.Parent = label
		return label
	end
	local live = text("LIVE", 0.035, 0.055, 0.105, 0.09, "FFFFFF", "D2303E")
	text("COVE TV", 0.14, 0.055, 0.18, 0.09, "FFFFFF", "17243A")
	-- The lower third sits clear of the doorway.
	local strip = text("STRANGE LIGHT IN CITRINE COVE MINE", 0.035, 0.845, 0.72, 0.11, "17243A", "F7F3E6", Enum.FontWeight.ExtraBold)
	strip.TextXAlignment = Enum.TextXAlignment.Left
	local accent = Instance.new("Frame")
	accent.BorderSizePixel, accent.BackgroundColor3, accent.ZIndex = 0, hex("8E4DF5"), 7
	accent.Position, accent.Size, accent.Parent = UDim2.fromScale(0.035, 0.825), UDim2.fromScale(0.72, 0.02), gui
	return { gui = gui, live = live }
end

local function set(root, reverse)
	local wall, trim, oak, walnut = "3F6E73", "E9DFC9", "B98656", "6E4830"
	-- Just wide enough that its edge stays behind the bezel from the sofa.
	local w, h = screenSize.X + 0.72, screenSize.Y + 0.42
	local top, foot = glassAt.Y + h / 2, glassAt.Y - h / 2
	local shell = {
		S.part(root, "Floor", CF(0, -0.25, 6), V(26, 0.5, 22), "A97B52", M.WoodPlanks),
		-- The television wall has an opening the size of the glass.
		S.part(root, "TV wall", CF(-(13 + w / 2) / 2, 6, -0.4), V(13 - w / 2, 13, 0.6), wall),
		S.part(root, "TV wall", CF((13 + w / 2) / 2, 6, -0.4), V(13 - w / 2, 13, 0.6), wall),
		S.part(root, "TV wall", CF(0, (12.5 + top) / 2, -0.4), V(w, 12.5 - top, 0.6), wall),
		S.part(root, "TV wall", CF(0, (foot - 0.5) / 2, -0.4), V(w, foot + 0.5, 0.6), wall),
		S.part(root, "Left wall", CF(-11, 6, 6), V(0.6, 13, 22), "4A7F80"),
		S.part(root, "Right wall", CF(11, 6, 6), V(0.6, 13, 22), "3F6E73"),
		S.part(root, "Back wall", CF(0, 6, 15.4), V(26, 13, 0.6), "B98C63"),
	}
	for _, p in shell do p.CastShadow = false end
	-- The shadow of a window the lens never sees. It shapes the low sun into
	-- panes across the sofa and the wall, and leaves the corners in the dark.
	if not reverse then
		local sunward = V(-0.72, 0.60, 0.35).Unit
		local frame = CFrame.lookAt(V(-0.4, 3.6, 5.2) + sunward * 22, V(-0.4, 3.6, 5.2))
		local function bar(x, y, bw, bh)
			S.part(root, "Window shadow", frame * CF(x, y, 0), V(bw, bh, 0.3), "2A2430")
		end
		-- Nothing further left than this. The model on the far side of the wall
		-- takes the same sun.
		bar(-8.2, 0, 2.5, 24)
		bar(12.4, -2, 7, 22)
		bar(-0.6, -9.2, 18, 6)
		bar(-4.6, -1, 0.45, 12)
		bar(0.9, -1, 0.45, 12)
		bar(-1, 2.9, 16, 0.45)
	end
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
	local shade = S.part(root, "Lamp shade", CF(-8.2, 4.9, 1.8), V(1.7, 1.3, 1.7), "FFD28A", M.Neon)
	-- The lamp's pool on the wall behind it, there from the first exposure.
	local halo = Instance.new("BillboardGui")
	halo.LightInfluence, halo.Size, halo.Parent = 0, UDim2.fromScale(7.5, 7.5), shade
	local bloom = Instance.new("ImageLabel")
	bloom.Image, bloom.BackgroundTransparency, bloom.Size = "rbxasset://textures/particles/smoke_main.dds", 1, UDim2.fromScale(1, 1)
	bloom.ImageColor3, bloom.ImageTransparency, bloom.Parent = hex("FFC274"), 0.55, halo
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
	-- The window the sun comes from, at the edge of the reverse.
	S.part(root, "Window light", CF(-10.66, 5.6, 11), V(0.06, 5.6, 5.4), "E2B276", M.Neon)
	for _, z in { 8.2, 11, 13.8 } do
		S.part(root, "Window post", CF(-10.6, 5.6, z), V(0.2, 5.9, 0.26), trim)
	end
	for _, y in { 2.75, 5.9, 8.45 } do
		S.part(root, "Window rail", CF(-10.6, y, 11), V(0.2, 0.24, 5.8), trim)
	end
	for _, z in { 7.6, 14.4 } do
		S.part(root, "Curtain", CF(-10.5, 5.2, z), V(0.35, 7.4, 1.5), "C9785A", M.Fabric)
	end
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

local function facing(place, sun, want)
	return CF(place) * A(0, math.atan2(sun.X, sun.Z) - math.atan2(want.X, want.Z), 0)
end

function Room.new(stage, place, sun, host)
	-- The sun rakes in from the left, a little behind the sofa.
	local at = facing(place, sun, V(-0.90, 0, 0.44))
	local root = S.group("Living room")
	set(root)
	local tv = television(root, host)
	local glow, entrance, painted = footage(root)
	root:PivotTo(at)
	glow:place(at * entrance)
	glow.model.Parent = root
	-- Over the lens's shoulder, from the glass.
	local toward = facing(place + V(0, 34, 0), sun, V(0.62, 0, -0.78))
	local reverse = S.group("Living room from the screen")
	set(reverse, true)
	reverse:PivotTo(toward)
	return setmetatable({ stage = stage, root = root, reverse = reverse, wide = at, toward = toward, at = at, tv = tv, glow = glow, painted = painted }, Room)
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
	-- The kid's cast file has a shirt and no trousers, which read as bare legs: denim trousers and
	-- dark trainers, through the body colours and the leg parts themselves.
	local denim, shoe = hex("33476E"), hex("2A2A33")
	for _, item in self.kid.model:GetDescendants() do
		if item:IsA("BodyColors") then
			item.LeftLegColor3, item.RightLegColor3 = denim, denim
		elseif item:IsA("BasePart") then
			if item.Name:find("Foot") then
				item.Color = shoe
			elseif item.Name:find("Leg") then
				item.Color = denim
			end
		end
	end
end

function Room:draw(frame, motion)
	local active = frame >= F.living and frame < F.witness
	local warm = frame >= F.living - 34 and frame < F.living
	self.root.Parent = if active or warm then self.stage else nil
	self.reverse.Parent = self.root.Parent
	self.at = if frame < F.livingReverse then self.wide else self.toward
	self.tv.gui.Enabled = active or warm
	if not active and not warm then
		if self.kid then self.kid.model.Parent, self.sib.model.Parent = nil, nil end
		return
	end
	self:seat()
	local f = if motion then frame else math.max(frame, if frame < F.livingReverse then F.living + 30 else F.livingReverse + 20)
	self.kid:place(Acting.perform(self.kid, kidClip, f, grounded(self.kid, self.at * CF(-2.1, 0, 6.5)), self.kidUnit))
	self.sib:place(Acting.perform(self.sib, sibClip, f, grounded(self.sib, self.at * CF(2.9, 0, 9.3) * A(0, math.rad(9), 0)), self.sibUnit))
	self.kid:show(self.stage)
	self.sib:show(self.stage)
	local age = if motion then frame - F.living else 30
	local tv = self.tv
	local at = math.max(frame, F.living)
	self.glow:expose(at, motion)
	local level = if motion then MouthGlow.level(at) else 0.7
	for _, p in self.painted do
		p.part.Color = p.base:Lerp(hex("8C4DFF"), math.min(0.8, p.amount * level))
	end
	tv.live.BackgroundTransparency = if age % 24 < 16 then 0 else 0.35
end

function Room:camera(frame, motion)
	if frame < F.livingReverse then
		local u = if motion then S.ease(frame, F.living - 6, F.livingReverse + 14) else 0.5
		-- Over both shoulders, across the sofa, easing toward the glass.
		return V(0.75 - 0.35 * u, 4.5 - 0.15 * u, 14.3 - 1.6 * u), V(0.2, 3.45 + 0.15 * u, 2.4), 36, 0
	end
	local u = if motion then (frame - F.livingReverse + 4) / (F.witness - F.livingReverse + 8) else 0.5
	return V(0.9 - 0.3 * u, 2.85 + 0.05 * u, 0.9 + 0.5 * u), V(0.06 - 0.1 * u, 2.55, 7.6), 54, 0
end

function Room:Destroy()
	if self.kid then
		self.kid:destroy()
		self.sib:destroy()
	end
	self.tv.gui:Destroy()
	self.root:Destroy()
	self.reverse:Destroy()
end

return Room
