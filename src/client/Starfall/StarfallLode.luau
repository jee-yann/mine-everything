local S = require(script.Parent.Scenery)
local Run = require(script.Parent.GalleryRun)
local cut = require(script.Parent.ExposureSheet).frames
local V, CF = Vector3.new, CFrame.new
local Lode = {}
Lode.__index = Lode

local shale = { "303247", "414053", "46465D", "364254", "51485B", "383B50", "4E4E60" }
local facets = { "474084", "6754AF", "8774BB", "4A477F", "585296", "352C60" }
local terminations = { "9582D8", "E5CEFA", "B7E4FF", "8296CA", "6B69B0", "695798" }

-- The mouth occupies one excavated floor brick. Local +Z points out of the
-- shaft. The cut timber, rungs and exposed mineral seam lead the eye down.
local function shaft(model)
	local sections = {
		{ 22.03, 2.99, 0 },
		{ 21.68, 2.62, 0 },
		{ 19.3, 2.49, 0.04 },
		{ 16.0, 2.54, 0.46 },
		{ 12.2, 3.58, 1.28 },
		{ 8.7, 6.18, 2.14 },
	}
	local previous
	for row, section in sections do
		local ring = {}
		for i = 1, 8 do
			local a = math.pi / 4 * (i - 1)
			local x, y = math.cos(a), math.sin(a)
			local r = section[2] / math.max(math.abs(x), math.abs(y))
			local fault = if row <= 2 then 1 else 0.94 + 0.07 * math.sin(i * 2.3 + row)
			ring[i] = V(x * r * fault, y * r * fault + section[3], section[1])
		end
		if previous then
			for i, point in ring do
				local j = i % #ring + 1
				local tint = if row <= 3
					then (if i % 2 == 0 then "825B47" else "6D5246")
					else shale[(i + row) % #shale + 1]
				S.facet(model, "Exposed dig face", previous[i], previous[j], point, tint)
				S.facet(model, "Exposed dig face", previous[j], ring[j], point, tint)
				if i == 2 or i == 3 then
					local a = previous[i]:Lerp(previous[j], 0.30 + row % 3 * 0.13)
					local b = point:Lerp(ring[j], 0.30 + (row + 1) % 3 * 0.13)
					local inset = V(-0.018, -0.022, 0)
					S.facet(
						model,
						"Thread of violet in the cut",
						a + inset,
						b + inset,
						b:Lerp(ring[j], 0.07) + inset,
						if row < 4 then "AB99AA" else "B29CE2",
						if row >= 4 then Enum.Material.Neon else nil
					)
				end
			end
		end
		previous = ring
	end
	for _, side in { -1, 1 } do
		S.part(model, "Collar timber", CF(side * 2.89, 0, 22.15), V(0.40, 6.28, 0.36), "76553E", Enum.Material.Wood)
		S.part(model, "Collar crosspiece", CF(0, side * 2.9, 22.17), V(5.48, 0.40, 0.40), "986C46", Enum.Material.Wood)
		S.part(model, "Ladder rail", CF(-2.34, side * 0.64, 18.53), V(0.16, 0.14, 7.2), "6C7780", Enum.Material.Metal)
		for _, y in { -2.9, 2.9 } do
			S.part(
				model,
				"Iron corner plate",
				CF(side * 2.79, y, 22.40),
				V(0.57, 0.46, 0.07),
				"4F5555",
				Enum.Material.Metal
			)
			S.part(model, "Drift bolt", CF(side * 2.79, y, 22.45), V(0.14, 0.14, 0.06), "BAA482", Enum.Material.Metal)
		end
	end
	for i = 0, 6 do
		S.part(model, "Ladder rung", CF(-2.30, 0, 21.8 - i), V(0.11, 1.35, 0.12), "B4A48C", Enum.Material.Metal)
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

function Lode.new(stage, at, island)
	local model = S.group("Unreached Starfall lode")
	chamber(model)
	shaft(model)
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
	-- Match the real shaft's orientation to the sun when the camera passes
	-- below the dig floor and moves into the isolated geological cutaway.
	at *= Run.shaft.Rotation
	model:PivotTo(at)
	return setmetatable({ model = model, stage = stage, at = at, arms = rays, island = island, hidden = {} }, Lode)
end

-- The server keeps simulating its ordinary dig cells. The one photographed
-- column is opened only on this client, including ore relief streamed mid-shot.
function Lode:closeShaft()
	if self.stream then
		self.stream:Disconnect()
		self.stream = nil
	end
	for item, original in self.hidden do
		if item.Parent and item.LocalTransparencyModifier == 1 then
			item.LocalTransparencyModifier = original
		end
	end
	table.clear(self.hidden)
end

function Lode:openShaft(actor, origin)
	local mouth = origin + Run.mouth
	local function cover(part)
		if (part:IsA("BasePart") or part:IsA("Decal")) and self.hidden[part] == nil then
			self.hidden[part] = part.LocalTransparencyModifier
			part.LocalTransparencyModifier = 1
		end
	end
	local function inspect(item)
		if not item:IsA("BasePart") and not item:IsA("Decal") then
			return
		end
		local block = item
		while block and block.Parent do
			local folder = block.Parent.Name
			if folder == "MineBlocks" or folder == "EditFace" or folder:match("_EditFace$") then
				break
			end
			if not block.Parent:IsA("Model") and not block.Parent:IsA("BasePart") then
				return
			end
			block = block.Parent
		end
		if not block or not block.Parent or not block:IsA("BasePart") then
			return
		end
		local offset = block.Position - mouth
		if math.abs(offset.X) < 0.06 and math.abs(offset.Z) < 0.06 and offset.Y < 0 and offset.Y > -36 then
			cover(item)
			if item == block then
				for _, child in block:GetDescendants() do
					cover(child)
				end
			end
		end
	end
	if actor.replayLanding and self.island then
		for _, group in self.island:GetChildren() do
			if group.Name:match("_EditFace$") then
				for _, part in group:GetChildren() do
					inspect(part)
				end
			end
		end
		return
	end
	local function watch(site)
		if self.stream then self.stream:Disconnect() end
		self.stream = site.DescendantAdded:Connect(inspect)
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { site }
		for _, part in workspace:GetPartBoundsInBox(CF(mouth - V(0, 18, 0)), V(0.2, 35.8, 0.2), params) do
			inspect(part)
		end
	end
	local site = workspace:FindFirstChild("CitrineCove")
	if site then
		watch(site)
	else
		self.stream = workspace.ChildAdded:Connect(function(child)
			if child.Name == "CitrineCove" then watch(child) end
		end)
	end
end

function Lode:expose(frame, motion, actor)
	local visible = frame >= cut.beacon and frame < cut.challenge
	local parent = if visible then self.stage else nil
	local inMine = visible and frame < cut.lode
	if self.inMine ~= inMine then
		self:closeShaft()
		self.inMine = inMine
		if inMine then
			local origin = Run.origin(actor)
			self.model:PivotTo(CF(origin) * Run.shaft)
			self:openShaft(actor, origin)
		else
			self.model:PivotTo(self.at)
		end
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
	return Run.chamber(frame, motion, portrait)
end

function Lode:Destroy()
	self:closeShaft()
	self.model:Destroy()
end
return Lode
