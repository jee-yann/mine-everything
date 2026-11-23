local S = require(script.Parent.Scenery)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local wood = Enum.Material.Wood
local SurveyCase = {}

-- These three attachments sit on the polished terminations of actual six-sided
-- crystals. Hand, tray and camera all use the same specimen and local axes.
local function attach(part, name, at)
	local anchor = Instance.new("Attachment")
	anchor.Name, anchor.Position, anchor.Parent = name, at, part
	return anchor
end

local function caustic(matrix, label, at, span)
	local origin = attach(matrix, label, at + V(0, 0.003, 0))
	local rays = {}
	-- Skim the top of the crystal in both axes. The near leg projects over
	-- its dark body, while the opposite ray crosses the upper silhouette.
	for i, delta in { V(0.98, 0.07, -0.24), V(-0.86, 0.12, 0.21), V(-0.14, 0.43, 0.86), V(0.15, 0.045, -0.89) } do
		local stop = attach(matrix, "Facet ray tip", at + delta * span)
		local beam = Instance.new("Beam")
		beam.Name, beam.Attachment0, beam.Attachment1 = "Mirror catch", origin, stop
		beam.Color = ColorSequence.new(Color3.fromHex("FFF8F1"), Color3.fromHex(if i <= 2 then "B99ED9" else "7BC4FF"))
		beam.Segments, beam.FaceCamera, beam.LightEmission, beam.LightInfluence = 1, true, 0.92, 0
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.01),
			NumberSequenceKeypoint.new(0.60, 0.19),
			NumberSequenceKeypoint.new(1, 0.93),
		})
		beam.Width0, beam.Width1, beam.Enabled, beam.Parent = 0, 0, false, matrix
		rays[i] = beam
	end
	return rays
end

local function specimen(tray)
	local model = script.Parent.AssayTrace:Clone()
	local matrix = model.PrimaryPart
	local focus = attach(matrix, "Polished seam intersection", V(-0.015, 0.20, 0.008))
	local axis = attach(matrix, "Face axes", focus.Position)
	local tips = { V(-0.009, 0.33, 0.022), V(0.137, 0.279, 0.002), V(-0.385, 0.122, -0.147) }
	local rays = {}
	for i, p in tips do
		rays[i] = caustic(matrix, "Polished tip " .. i, p, if i == 1 then 0.215 else 0.115)
	end
	local light = S.light(focus, "9765F0", 1.2, 0)
	light.Enabled, light.Shadows = false, false
	model.Name = "Violet trace in country rock"
	model:PivotTo(CF(-0.55, 0.183, 0.045) * A(0.02, -0.12, 0.03))
	model.Parent = tray
	return {
		model = model,
		focus = focus,
		axis = axis,
		rays = rays,
		light = light,
		thread = model["Living thread"],
		faces = { model["Flash 0"], model["Flash 2"], model["Flash 5"] },
	}
end

local amethyst, starWhite = Color3.fromHex("8055B8"), Color3.fromHex("E9F5FF")
local vein, silver = Color3.fromHex("976DBA"), Color3.fromHex("D7C1FF")
local function pass(frame, first, peak, last)
	return S.ease(frame, first, peak) * (1 - S.ease(frame, peak, last))
end

function SurveyCase.expose(ore, frame, motion, strikeAge)
	local impact = if strikeAge and strikeAge >= 0 then 1 - S.ease(strikeAge, 0, 9) else 0
	local primary = math.max(pass(frame, 1027, 1033, 1038), impact)
	local sweep = math.max(pass(frame, 1030, 1034, 1039), if strikeAge then pass(strikeAge, -1, 1, 7) else 0)
	local cross = math.max(pass(frame, 1037, 1041, 1048), if strikeAge then pass(strikeAge, 0, 2, 8) * 0.76 else 0)
	local edge = math.max(pass(frame, 1019, 1022, 1028), if strikeAge then pass(strikeAge, 1, 4, 10) * 0.54 else 0)
	local strength = math.max(primary, sweep, cross, edge)
	ore.light.Enabled, ore.light.Brightness = strength > 0.01, strength * (if motion then 0.65 else 0.27)
	ore.thread.Color = vein:Lerp(silver, strength * 0.90)
	for i, value in { primary, cross, edge } do
		ore.faces[i].Color = amethyst:Lerp(starWhite, value)
		for arm, beam in ore.rays[i] do
			local energy = if i == 1 and arm > 2 then sweep else value
			beam.Enabled = motion and energy > 0.04
			beam.Width0 = energy * (if arm <= 2 then 0.022 else 0.026)
		end
	end
end

local function lettering(plate, normal, words, color, font, width, height)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.CanvasSize, gui.LightInfluence = normal, Vector2.new(width, height), 0.13
	gui.SizingMode, gui.Parent = Enum.SurfaceGuiSizingMode.FixedSize, plate
	local label = Instance.new("TextLabel")
	label.Name, label.AnchorPoint, label.Position = "Inscription", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	label.Size, label.BackgroundTransparency, label.TextScaled = UDim2.fromScale(0.94, 0.85), 1, true
	label.Text, label.Font, label.TextColor3, label.Parent = words, font, Color3.fromHex(color), gui
	return label
end

local function claimTag(name)
	local tag = S.group("Expedition claim tag")
	S.part(tag, "Stamped brass", CF(), V(1.14, 0.65, 0.07), "D7A74F", Enum.Material.Metal)
	S.part(tag, "Patinated enamel", CF(0, -0.014, -0.042), V(1.01, 0.50, 0.027), "174843")
	local header = S.part(tag, "Issue mark", CF(0, 0.153, -0.062), V(0.94, 0.104, 0.012), "174843")
	lettering(header, Enum.NormalId.Front, "PROSPECTOR  /  CITRINE COVE", "FFDA85", Enum.Font.RobotoMono, 620, 70)
	local field = S.part(tag, "Registered finder", CF(0, -0.044, -0.064), V(0.94, 0.22, 0.012), "174843")
	lettering(field, Enum.NormalId.Front, name, "FFF1CD", Enum.Font.BuilderSansExtraBold, 768, 160)
	for _, side in { -1, 1 } do
		local pin = S.part(
			tag,
			"Brass rivet",
			CF(side * 0.506, 0.256, -0.048),
			V(0.052, 0.052, 0.02),
			"FFF0BA",
			Enum.Material.Metal
		)
		pin.Shape = Enum.PartType.Ball
	end
	S.part(tag, "Belt clip", CF(0, 0.36, 0.012), V(0.24, 0.095, 0.065), "94764A", Enum.Material.Metal)
	return tag
end

function SurveyCase.new(name)
	local tray = S.group("Field geologist's case")
	local function board(name, x, y, z, w, h, d, color, material)
		return S.part(tray, name, CF(x, y, z), V(w, h, d), color, material or wood)
	end
	board("Sample bed", 0, -0.09, 0, 2.35, 0.16, 1.39, "594236")
	board("Felt lining", 0, 0.01, 0, 2.21, 0.05, 1.25, "304642", Enum.Material.Fabric)
	for _, x in { -1.15, 1.15 } do
		board("Oak cheek", x, 0.07, 0, 0.08, 0.25, 1.43, "A4734E")
		for _, z in { -0.57, 0.57 } do
			local leg = board("Folding field stand", x * 0.8, -1.62, z, 0.13, 3.12, 0.15, "856046")
			leg.CFrame *= A(0, 0, x * 0.065)
			board("Brass corner", x, 0.09, z, 0.095, 0.20, 0.19, "B9955E", Enum.Material.Metal)
		end
	end
	for _, z in { -0.68, 0.68 } do
		board("Oak rim", 0, 0.07, z, 2.30, 0.25, 0.08, "9B6B4C")
	end
	board("Divider", 0, 0.055, 0, 0.07, 0.11, 1.25, "8F7158")
	local lid = board("Lid", 0, 0.52, 0.89, 2.35, 0.86, 0.10, "694F41")
	lid.CFrame *= A(0.39, 0, 0)
	-- Bids from two buyers share the assay-office lid. The claim tag belongs
	-- to the player; nothing fills the specimen recess until a first find.
	local function paper(name, x, y, w, h, stock, depth, skew)
		local slip = board(name, 0, 0, 0, w, h, 0.017, stock, Enum.Material.SmoothPlastic)
		slip.CFrame = lid.CFrame * CF(x, y, -depth) * A(0, 0, skew or 0)
		return slip
	end
	paper("Assay office order book", 0, 0.175, 2.19, 0.41, "E7D5AE", 0.070)
	local masthead = paper("Assay office imprint", 0, 0.303, 1.99, 0.104, "E7D5AE", 0.087)
	lettering(masthead, Enum.NormalId.Front, "CITRINE ASSAY    /    BUY ORDERS", "5B4B35", Enum.Font.RobotoMono, 750, 54)
	local notice = paper("Mineral wanted", 0, 0.121, 2.06, 0.237, "E7D5AE", 0.088)
	lettering(notice, Enum.NormalId.Front, "STARFALL WANTED", "382A32", Enum.Font.BuilderSansExtraBold, 856, 108)
	for i, order in {
		{ 0.537, "F2D29B", "693B29", "FOUNDRY", "BID FILED", -0.029 },
		{ -0.537, "C5E0DA", "1D4846", "MUSEUM", "COUNTERBID", 0.021 },
	} do
		local x, stock, ink, buyer, status, skew = table.unpack(order)
		local slip = paper(buyer .. " order", x, -0.188, 1.04, 0.333, stock, 0.079 + i * 0.003, skew)
		local function imprint(words, height, dy, font)
			local field = board(words, 0, 0, 0, 0.95, height, 0.016, stock, Enum.Material.SmoothPlastic)
			field.CFrame = slip.CFrame * CF(0, dy, -0.016)
			lettering(field, Enum.NormalId.Front, words, ink, font, 410, math.round(height * 400))
		end
		imprint(buyer, 0.138, 0.073, Enum.Font.BuilderSansExtraBold)
		imprint(status, 0.125, -0.077, Enum.Font.RobotoMono)
		local pin = board("Copper paper tack", 0, 0, 0, 0.046, 0.046, 0.032, "987443", Enum.Material.Metal)
		pin.CFrame = slip.CFrame * CF(0.461, 0.115, -0.027)
	end
	local ore = specimen(tray)

	-- A deep, vacant crystal-shaped recess with brass tips for the first find.
	local socket =
		board("Unclaimed Starfall socket", 0.55, 0.047, 0.06, 0.91, 0.024, 0.95, "173532", Enum.Material.Fabric)
	local contour = {
		V(-0.37, 0.024, 0.23),
		V(-0.29, 0.024, -0.21),
		V(0.18, 0.024, -0.41),
		V(0.34, 0.024, -0.15),
		V(0.18, 0.024, 0.29),
		V(-0.12, 0.024, 0.37),
	}
	for i, a in contour do
		local b = contour[i % #contour + 1]
		local at = socket.Position
		S.facet(tray, "Empty velvet recess", at + a, at + b, at + V(0, 0.021, 0), "142323", Enum.Material.Fabric)
		S.strut(tray, "Pressed brass rim", at + a, at + b, 0.027, 0.025, "D6AC62", Enum.Material.Metal)
	end
	for _, i in { 1, 3, 5 } do
		local endAt = socket.Position + contour[i]
		S.strut(
			tray,
			"Vacant retaining claw",
			endAt,
			endAt + V(0, 0.12, 0) - contour[i] * 0.18,
			0.044,
			0.047,
			"FFDB87",
			Enum.Material.Metal
		)
	end
	return tray, claimTag(name), socket, ore
end
return SurveyCase
