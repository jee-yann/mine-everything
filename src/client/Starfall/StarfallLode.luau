local S = require(script.Parent.Scenery)
local cut = require(script.Parent.ExposureSheet).frames
local V, CF = Vector3.new, CFrame.new
local Lode = {}
Lode.__index = Lode

local shale = { "303247", "414053", "46465D", "364254", "51485B", "383B50", "4E4E60" }
local facets = { "474084", "6754AF", "8774BB", "4A477F", "585296", "352C60" }
local terminations = { "9582D8", "E5CEFA", "B7E4FF", "8296CA", "6B69B0", "695798" }

-- This mouth is seen first among the timber and lamps of the working mine.
-- Its chipped lip passes the lens before the camera opens onto the crystal.
local function adit(model)
	local stone = { "525361", "605D64", "424656", "646067", "4D4C5D", "676569" }
	local rings = {
		{ 15.4, 6.3, 26.7, 0.45, 0.02 },
		{ 8.3, 4.8, 29.4, 0.65, -0.03 },
		{ 3.4, 2.3, 29.6, 0.82, 0.07 },
		{ 2.3, 1.5, 26.3, 0.30, -0.04 },
		{ 3.8, 2.7, 19.8, 0.77, 0.12 },
		{ 5.2, 3.6, 15.4, 0.83, 0.06 },
		{ 7.2, 4.5, 9.7, 0.58, 0.02 },
	}
	local previous
	for row, section in rings do
		local ring = {}
		for i = 1, 12 do
			local theta = i * math.pi / 6 + section[5]
			local n = 0.91 + 0.11 * math.sin(i * 2.7 + row * 0.55)
			ring[i] = V(-0.65 + section[1] * math.cos(theta) * n, 1.54 + section[2] * math.sin(theta) * n,
				section[3] + section[4] * math.cos(2.1 * theta + row * 0.7))
		end
		if previous then
			local palette = if row <= 3 then stone else shale
			for i, p in ring do
				local j = i % #ring + 1
				S.facet(model, "Rift wall", previous[i], previous[j], p, palette[1 + (row + i * 3) % #palette])
				S.facet(model, "Rift wall", previous[j], ring[j], p, palette[1 + (row * 3 + i) % #palette])
				if (row == 3 or row == 4) and (i == 2 or i == 7 or i == 9) then
					local a = p:Lerp(previous[i], 0.12)
					local b = p:Lerp(previous[j], 0.61)
					S.facet(model, "Calcite at the gallery face", a + V(0, 0, 0.035), b + V(0, 0, 0.035),
						b:Lerp(previous[j], 0.07) + V(0, 0, 0.035), "ABA1AF")
				end
			end
		end
		previous = ring
	end
end

-- Photograph this sealed pocket from inside the rock. Each band of strata
-- changes its radius and twist independently as it recedes into the fissure.
local function chamber(model)
	local previous
	for row, depth in { 13, 8, 4, 0, -4.6, -8.8, -12.2 } do
		local ring = {}
		for i = 1, 12 do
			local a = i * math.pi / 6 + 0.13 * math.sin(row * 1.7 + i * 2.2)
			local r = 1 + 0.15 * math.sin(i * 4.4 - row * 1.6)
			ring[i] = V(8.3 * r * math.cos(a), 2.5 + 4.8 * r * math.sin(a), depth + 0.82 * math.cos(a * 2 + row))
		end
		if previous then
			for i, point in ring do
				local nextIndex = i % #ring + 1
				S.facet(
					model,
					"Fracture bedding",
					point,
					previous[i],
					ring[nextIndex],
					shale[(i + row * 2) % #shale + 1]
				)
				S.facet(
					model,
					"Fracture bedding",
					ring[nextIndex],
					previous[i],
					previous[nextIndex],
					shale[(i * 3 + row) % #shale + 1]
				)
			end
		end
		previous = ring
	end
	S.part(model, "End of the fissure", CF(0, 2, -14), V(32, 22, 2), "171424", Enum.Material.Slate)
	S.part(model, "Bedrock over the pocket", CF(0, 9, 0), V(38, 2, 42), "1F2432", Enum.Material.Slate)
end

local function crystal(model, base, height, radius)
	local foot, collar = {}, {}
	local tip = base * V(0.12 * radius, height, -0.13 * radius)
	for i = 1, 6 do
		local a = 2 * math.pi * (i - 1) / 6 + 0.17
		local x, z = math.cos(a) * radius, math.sin(a) * radius
		foot[i] = base * V(x * 0.74, 0, z * 0.74)
		collar[i] = base * V(x, height * (0.67 + 0.046 * math.sin(i * 2.3)), z)
	end
	for i, point in foot do
		local j = i % 6 + 1
		S.facet(model, "Violet prism", point, foot[j], collar[i], facets[i])
		S.facet(model, "Violet prism", foot[j], collar[j], collar[i], facets[i])
		S.facet(
			model,
			"Cleavage plane",
			collar[i],
			collar[j],
			tip,
			terminations[i],
			if i == 3 then Enum.Material.Neon else nil
		)
	end
	-- A fault inside the three front planes catches light independently of
	-- the darker body. It tapers at both ends like the seam under the crater.
	for _, i in { 1, 2, 3 } do
		local j = i % 6 + 1
		local low = foot[i]:Lerp(foot[j], 0.30)
		local edge = collar[i]:Lerp(collar[j], 0.43)
		local bias = base:VectorToWorldSpace(V(0.005, 0, 0.012))
		S.facet(
			model,
			"Buried fire",
			low:Lerp(edge, 0.29) + bias,
			edge + bias,
			collar[i]:Lerp(collar[j], 0.51) + bias,
			"C79CFF",
			Enum.Material.Neon
		)
	end
	return collar[2], tip
end

local function opticalStar(parent, position)
	local pin = S.part(parent, "Star caught in a crystal face", CF(position), V(0.1, 0.1, 0.1), "FFFFFF")
	pin.Transparency = 1
	local source = Instance.new("Attachment", pin)
	local arms = {}
	for _, offset in { V(1.0, 0.25, 0.20), V(-1.08, -0.27, -0.22), V(-0.27, 0.74, 0.15), V(0.21, -0.60, -0.12) } do
		local endPoint = Instance.new("Attachment", pin)
		endPoint.Position = offset * 1.48
		local arm = Instance.new("Beam")
		arm.Attachment0, arm.Attachment1 = source, endPoint
		arm.FaceCamera, arm.LightEmission, arm.Segments = true, 1, 1
		arm.ZOffset = 0.24
		arm.Color = ColorSequence.new(Color3.fromHex("FFF1FF"), Color3.fromHex("B3DCFF"))
		arm.Transparency = NumberSequence.new(0.05, 0.93)
		arm.Width1, arm.Parent = 0, pin
		table.insert(arms, arm)
	end
	return arms
end

function Lode.new(stage, at)
	local model = S.group("Unreached Starfall lode")
	chamber(model)
	adit(model)
	local base = CF(0.56, -2.05, -1.5)
	local bed = V(0.46, -1.19, -1.48)
	local ledge = {
		V(-2.8, -1.95, 0.90),
		V(-1.22, -1.67, 1.85),
		V(0.95, -1.39, 1.63),
		V(2.92, -1.63, 0.47),
		V(3.3, -1.80, -2.15),
		V(2.65, -1.36, -4.48),
		V(-0.34, -1.51, -4.8),
		V(-2.31, -1.84, -3.77),
	}
	for i, p in ledge do
		local q = ledge[i % #ledge + 1]
		S.facet(model, "Vein host", p, bed, q, shale[i % #shale + 1])
		local lower = V(0.42, -3.6, -1.5)
		S.facet(model, "Split ledge", p, q, lower, shale[(i + 2) % #shale + 1])
		if i == 1 or i == 3 or i == 6 then
			local endOfVein = p:Lerp(q, 0.38) + V(0, 0.008, 0)
			local middle = bed:Lerp(endOfVein, 0.72)
			S.facet(model, "Quartz in the bedding", bed + V(0, 0.012, 0), endOfVein, middle + (q - p) * 0.045, "9F97C4")
		end
	end
	local edge, tip = crystal(model, base * CFrame.Angles(-0.06, 0.13, -0.16), 5.28, 0.91)
	crystal(model, base * CF(-0.51, 0.03, 0.10) * CFrame.Angles(0.17, -0.8, 0.57), 3.15, 0.54)
	crystal(model, base * CF(0.49, 0.09, -0.07) * CFrame.Angles(-0.19, 0.58, -0.79), 3.48, 0.56)
	crystal(model, base * CF(0.26, 0.12, 0.31) * CFrame.Angles(0.62, -0.26, -0.41), 1.67, 0.32)
	-- The arms of the stellar twin grow out of the main prism. Catch their
	-- crossing on a real facet at the end of the dive into the gallery.
	local twin = CF(1.01, 0.64, -1.12)
	crystal(model, twin * CFrame.Angles(0.23, -0.12, 1.11), 2.05, 0.31)
	crystal(model, twin * CFrame.Angles(0.16, -0.35, -0.92), 1.81, 0.30)
	local rays = opticalStar(model, edge:Lerp(tip, 0.15) + V(0, 0.01, 0.23))
	for _, light in
		{
			{ V(-2.7, 3.4, 2), "B7C9FF", 15, 2.05 },
			{ V(2.8, 0.25, -3.4), "CF84FF", 11, 2.2 },
			{ V(-2.8, -0.55, -6.7), "688CF9", 11, 1.65 },
		}
	do
		local anchor = S.part(model, "Light in the quartz", CF(light[1]), V(0.1, 0.1, 0.1), light[2])
		anchor.Transparency = 1
		S.light(anchor, light[2], light[3], light[4])
	end
	model:PivotTo(at)
	return setmetatable({ model = model, stage = stage, at = at, arms = rays }, Lode)
end

function Lode:expose(frame, motion, actor)
	local visible = frame >= cut.beacon and frame < cut.challenge
	local parent = if visible then self.stage else nil
	if visible then
		local inMine = frame < cut.lode
		if self.inMine ~= inMine then
			local placement = self.at
			if inMine then
				local route = actor.mineBearing
				local delta = if actor.handoff.entrance then actor.handoff.entrance - actor.handoff.landing
					else route.LookVector * 72
				placement = (route + delta) * CF(0, 0.90, -47)
			end
			self.model:PivotTo(placement)
			self.inMine = inMine
		end
	else
		self.inMine = nil
	end
	if self.model.Parent ~= parent then
		self.model.Parent = parent
	end
	if visible then
		local age = frame - cut.lode
		local light = if motion then 0.14 + 0.86 * S.ease(age, 17, 32) * (1 - S.ease(age, 32, 67)) else 0.45
		for _, arm in self.arms do
			arm.Width0, arm.Enabled = 0.17 * light, light > 0.02
		end
	end
end

function Lode:camera(frame, motion, portrait)
	local t = if motion then (frame - cut.lode) / (cut.challenge - cut.lode) else 0.6
	-- Carry the incoming push for four exposures, then let the chamber
	-- open up into a steady lateral move and hold its best-lit facet.
	local age = frame - cut.lode
	local tail = if motion then math.exp(-0.40 * age) else 0
	-- At age zero the position, tilt and focal length exactly continue the
	-- entrance shot. Both spaces contain the very same rock at the same scale.
	local eye = V(-2.30 + 1.72 * t + 1.60 * tail, 0.38 + 0.58 * t + 1.20 * tail, 8.1 - 1.72 * t + 14.6 * tail)
	local look = V(if portrait then 0.46 else -0.38, 0.85 + 0.32 * t, -1.35):Lerp(V(0, 0.9, 1.56), tail)
	return eye, look, 42 + 15 * tail, math.rad(-3.7 + 1.35 * t + 5.5 * tail)
end

function Lode:Destroy()
	self.model:Destroy()
end
return Lode
