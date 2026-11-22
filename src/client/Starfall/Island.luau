local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local TideFront = require(script.Parent.TideFront)
local FaultField = require(script.Parent.FaultField)
local FirstCrews = require(script.Parent.FirstCrews)
local S = require(script.Parent.Scenery)
local sheet = require(script.Parent.ExposureSheet)
local Island = {}
Island.__index = Island
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles

local function scheduleEntry(entries, model, opens, closes)
	table.insert(entries, { instance = model, opens = opens, closes = closes })
end

local function wake(model)
	local anchor = Instance.new("Part")
	anchor.Name = "Cutter wash"
	anchor.Size, anchor.Transparency = Vector3.one, 1
	anchor.Anchored, anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = true, false, false, false
	anchor.CFrame = model:GetPivot()
	anchor.Parent = model
	local shots = {}
	for _, side in { -1, 1 } do
		for j = 1, 3 do
			local a, b = Instance.new("Attachment"), Instance.new("Attachment")
			a.Position, b.Position =
				V(side * (1.54 + j * 0.39), -0.17, 4 + j * 0.66), V(side * (4 + j * 1.6), -0.17, 12 + j * 3.3)
			a.Axis, b.Axis = V(side * 0.31, 0, 0.95), V(side * 0.45, 0, 0.89)
			a.Parent, b.Parent = anchor, anchor
			local brush = Instance.new("Beam")
			brush.Attachment0, brush.Attachment1 = a, b
			brush.Width0, brush.Width1 = 0.14 + j * 0.06, 0.60 + j * 0.23
			brush.CurveSize0, brush.CurveSize1 = 4.2, 5.3
			brush.LightInfluence, brush.FaceCamera, brush.Segments = 0.54, true, 8
			brush.Color = ColorSequence.new(Color3.fromHex("D5E9DB"), Color3.fromHex("AFD9D2"))
			brush.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.76),
				NumberSequenceKeypoint.new(0.30, 0.12),
				NumberSequenceKeypoint.new(0.61, 0.28),
				NumberSequenceKeypoint.new(1, 1),
			})
			brush.Parent = anchor
			table.insert(shots, brush)
		end
	end
	return shots
end

-- Rig the wheel and skip already built into the historical headframe.
local function oreHoist(set, base)
	local rig = set["2137_2582_Head sheave and hauling cable"]
	-- The steam-era portal occupies the original adit while this earlier rig
	-- is still in service. Its foundations sit on the level eastern mine pad.
	local site = base * CF(29, 0.36, 16)
	for _, parcel in set:GetChildren() do
		if parcel == rig or parcel.Name:match("_Ore winding tower$") then
			parcel:PivotTo(site * base:ToObjectSpace(parcel:GetPivot()))
		end
	end
	local wheel = S.group("Working head sheave")
	wheel.WorldPivot = site * CF(-1, 49, 2)
	for _, p in rig:GetChildren() do
		if p.Name == "Sheave rim" or p.Name == "Spoke" then
			p.Parent = wheel
		end
	end
	wheel.Parent = rig
	S.strut(
		rig,
		"Through axle",
		site * V(-1, 49, -6.3),
		site * V(-1, 49, 7.25),
		0.53,
		0.53,
		"6B6664",
		Enum.Material.Metal
	)
	for _, z in { -5.95, 6.7 } do
		S.strut(rig, "Sheave bearing", site * V(-1, 46.25, z), site * V(-1, 49, z), 0.86, 0.82, "926B4F")
	end
	local drum = S.part(rig, "Winding drum", site * CF(-11.4, 26.5, 7.2), V(3, 3.1, 3.1), "59565C", Enum.Material.Metal)
	drum.Shape = Enum.PartType.Cylinder
	for _, x in { -13.2, -9.6 } do
		S.part(rig, "Drum bearing block", site * CF(x, 25.35, 7.2), V(0.65, 2.65, 2.05), "8F6D50", Enum.Material.Wood)
	end
	local lead = rig["Cable to winch"]
	local exit, winding = site * V(-4.92, 50.85, 2), site * V(-11.4, 27.72, 7.2)
	lead.Size, lead.CFrame = V(0.20, 0.20, (exit - winding).Magnitude), CFrame.lookAt((exit + winding) * 0.5, winding)
	local body = rig["Lift bucket"]
	local load = S.group("First load of splinters")
	local at = body.CFrame
	for i, tint in { "9C7959", "8B6E55", "A48365", "92745B" } do
		S.part(load, "Oak stave", CF((i - 2.5) * 0.79, 0, 1.61), V(0.74, 1.87, 0.07), tint, Enum.Material.Wood)
	end
	for _, y in { -0.72, 0.65 } do
		S.part(load, "Iron binding", CF(0, y, 0), V(3.28, 0.16, 3.28), "50545E", Enum.Material.Metal)
	end
	for _, x in { -1.47, 1.47 } do
		S.strut(load, "Bail", V(x, 0.79, 0), V(0, 2.72, 0), 0.14, 0.14, "A3A1A0", Enum.Material.Metal)
	end
	for i = 1, 8 do
		local a = i * 2.4
		local point = V(0.98 * math.cos(a), 1.16 + 0.20 * math.sin(i), 0.94 * math.sin(a))
		local rock = S.part(
			load,
			"Shale from the cut",
			CF(point) * A(0.16 * i, a, 0.13 * i),
			V(1.15, 0.85, 0.98),
			if i % 3 == 0 then "98849D" elseif i % 2 == 0 then "75647B" else "655D68",
			Enum.Material.Slate,
			"WedgePart"
		)
		if i == 2 or i == 6 then
			S.strut(
				load,
				"Violet fracture",
				rock.CFrame * V(-0.40, 0.26, 0.25),
				rock.CFrame * V(0.22, 0.30, 0.19),
				0.076,
				0.076,
				"CF97FB",
				Enum.Material.Neon
			)
		end
	end
	load:PivotTo(at)
	body.Parent = load
	load.Parent = rig
	local chips = {}
	for i = 1, 2 do
		local stone = S.part(
			rig,
			"Shale slipping free",
			at,
			V(0.43, 0.36, 0.55),
			if i == 1 then "8C7387" else "B198A9",
			Enum.Material.Slate,
			"WedgePart"
		)
		stone.Transparency = 1
		table.insert(chips, stone)
	end
	return {
		rig = rig,
		wheel = wheel,
		wheelRest = wheel:GetPivot(),
		load = load,
		rest = at,
		cable = rig["Bucket cable"],
		chips = chips,
	}
end
local function liftBucket(hoist, frame)
	if not hoist.rig.Parent then
		return
	end
	local f = math.clamp(frame, 780, 853)
	if f == hoist.frame then
		return
	end
	hoist.frame = f
	local up = S.ease(f, 789, 838)
	local brake = S.ease(f, 830, 838) * (1 - S.ease(f, 838, 846))
	local rise = 12.4 * up + 0.18 * brake
	local swing = math.sin(up * math.pi * 2.8) * math.sin(up * math.pi) + 0.21 * brake
	local at = hoist.rest * CF(0.22 * swing, rise, 0) * A(0, 0.07 * swing, -0.055 * swing)
	hoist.load:PivotTo(at)
	hoist.wheel:PivotTo(hoist.wheelRest * A(0, 0, rise / 4.4))
	local top = hoist.rest * V(0, 21.7, 0)
	local bail = at * V(0, 2.72, 0)
	hoist.cable.Size = V(0.19, 0.19, (top - bail).Magnitude)
	hoist.cable.CFrame = CFrame.lookAt((top + bail) * 0.5, bail)
	for i, p in hoist.chips do
		local birth = if i == 1 then 829 else 836
		local age = (f - birth) / 24
		p.Transparency = if age >= 0 and f < 853 then 0 else 1
		if p.Transparency == 0 then
			local height = 12.4 * S.ease(birth, 789, 838)
			p.CFrame = hoist.rest
				* CF(1.15 + 4.1 * age, height + 1 + 1.2 * age - 20 * age * age, 0.48 * i + 0.85 * age)
				* A(age * 7, age * 5, 0)
		end
	end
end

-- Clone the baked models in one engine call before the clock starts. Shots
-- expose whole parcels; the live island and other players are never touched.
function Island.new(stage, base)
	local set = script.Parent.CoveChronicle:Clone()
	set.Name = "Citrine Cove through the ages"
	set:PivotTo(base)
	local vault = Instance.new("Folder")
	vault.Name = "Unexposed parcels"
	local hoist = oreHoist(set, base)
	local deposits = {}
	local infill = set["Basin infill"]
	for _, bed in infill:GetChildren() do
		local first, last = bed.Name:match("^([%d%.]+)_([%d%.]+)$")
		table.insert(deposits, { bed = bed, top = bed:GetPivot(), first = tonumber(first), last = tonumber(last) })
	end
	infill.Parent = vault
	local grove = set["Wind trees"]
	local entries, trees = {}, {}
	local vessel = set.Cutter
	vessel.WorldPivot = base
	local wash = wake(vessel)
	vessel.Parent = vault
	for _, tree in grove:GetChildren() do
		local opens, closes = tree.Name:match("^([%d%.]+)_([%d%.]+)$")
		local origin = tree:GetPivot()
		local point = base:PointToObjectSpace(origin.Position)
		local radial = V(point.X, 0, point.Z + 32)
		table.insert(trees, {
			model = tree,
			rest = origin,
			arrival = TideFront.arrival(radial.Magnitude),
			axis = base:VectorToWorldSpace(Vector3.yAxis:Cross(radial.Unit)),
			breaks = tonumber(closes) < 12,
			moving = false,
		})
		scheduleEntry(entries, tree, tonumber(opens), tonumber(closes))
		tree.Parent = vault
	end
	grove:Destroy()
	for _, parcel in set:GetChildren() do
		if parcel:IsA("Model") then
			local a, b = parcel.Name:match("^(%d+)_(%d+)_")
			assert(a and b, "Missing exposure time for " .. parcel.Name)
			scheduleEntry(entries, parcel, tonumber(a) / 100, tonumber(b) / 100)
			parcel.Parent = vault
		end
	end
	-- Keep the exact wave-cut ledges under both the unmined and inhabited rim.
	local coast = Shared:FindFirstChild("TideCoast")
	if coast then
		local ledges = coast:Clone()
		ledges:PivotTo(base * coast:GetPivot())
		ledges.Parent = set
	end
	local changes = {}
	for _, entry in entries do
		table.insert(changes, { at = entry.opens, entry = entry, show = true })
		table.insert(changes, { at = entry.closes, entry = entry, show = false })
	end
	table.sort(changes, function(a, b)
		return a.at < b.at
	end)
	local self = setmetatable({
		set = set,
		vault = vault,
		hoist = hoist,
		infill = infill,
		deposits = deposits,
		entries = entries,
		changes = changes,
		trees = trees,
		stage = stage,
		vessel = vessel,
		wash = wash,
		base = base,
		tide = TideFront.new(stage, base),
		faults = FaultField.new(stage, base),
		crew = FirstCrews.new(stage, base),
		index = 1,
		last = -1,
	}, Island)
	local felled = 0
	for i, tree in trees do
		if tree.breaks then
			felled += 1
			if felled % 3 == 1 then
				self.faults:addCanopy(tree, i)
			end
		end
	end
	self:draw(0)
	return self
end

local function boat(t)
	local p = math.clamp((t - 16.70) / 1.83, 0, 1)
	local s = 1 - (1 - p) ^ 1.37
	local a, b, c = V(-184, 20.72, 155), V(-178, 20.72, 101), V(-151, 20.72, 104)
	local first, second = a:Lerp(b, s), b:Lerp(c, s)
	local at = first:Lerp(second, s) + V(0, 0.14 * math.sin(t * 4.8), 0)
	local bow = CFrame.lookAt(at, at + second - first)
	return bow * A(0.020 * math.sin(4 * t), 0, 0.033 * math.cos(t * 3.7))
end

function Island:draw(t)
	local showing = t < 28.25 and t >= 0
	self.set.Parent = if showing then self.stage else nil
	if t < self.last then
		-- A test seek or replay can cross any number of photographic exposures.
		for _, e in self.entries do
			e.instance.Parent = self.vault
		end
		self.index = 1
	end
	local changes = self.changes
	while self.index <= #changes and changes[self.index].at <= t do
		local v = changes[self.index]
		v.entry.instance.Parent = if v.show then self.set else self.vault
		self.index += 1
	end
	-- Accumulate the sediments that bury the seam on the geological clock.
	-- Each bank has its full map footprint; only its visible thickness grows.
	-- Once the surveyors land, these formations stay fixed through the match.
	local buried = t >= 12.68
	if buried then
		for _, layer in self.deposits do
			local u = math.clamp((t - layer.first) / (layer.last - layer.first), 0, 1)
			if layer.u ~= u then
				local thickness = u * u * (3 - 2 * u)
				layer.bed:PivotTo(layer.top - self.base.UpVector * (38 * (1 - thickness)))
				layer.u = u
			end
		end
	end
	self.infill.Parent = if buried then self.set else self.vault
	self.tide:draw(t - 5.10)
	self.faults:draw(t)
	if (t >= 5.1 and t <= 9.0) or (self.last >= 5.1 and self.last <= 9) then
		for _, tree in self.trees do
			local age = t - 5.1 - tree.arrival
			if age >= 0 and age < 1.18 and tree.model.Parent == self.set then
				local tilt = if age < 0.21
					then 0.39 * math.sin(age / 0.21 * math.pi * 0.5)
					else 0.39 * math.exp(-4.8 * (age - 0.21)) * math.cos((age - 0.21) * 8.1)
				if tree.breaks then
					tilt = 1.24 * math.clamp(age / 0.50, 0, 1) ^ 1.4
				end
				tree.model:PivotTo(CF(tree.rest.Position) * CFrame.fromAxisAngle(tree.axis, tilt) * tree.rest.Rotation)
				tree.moving = true
			elseif tree.moving then
				tree.model:PivotTo(tree.rest)
				tree.moving = false
			end
		end
	end
	local boatCF = self.base * boat(t)
	self.vessel.Parent = if t >= 16.70 and t < 20.30 then self.set else self.vault
	if self.vessel.Parent == self.set then
		self.vessel:PivotTo(boatCF)
		local speed = math.clamp((18.70 - t) / 0.54, 0, 1)
		for i, brush in self.wash do
			brush.Enabled = speed > 0.03
			brush.Width1 = (0.43 + 0.35 * (i % 3)) * speed
		end
	end
	liftBucket(self.hoist, math.round(sheet.frameForScene(t)))
	self.crew:draw(t, boatCF)
	self.last = t
end

function Island:Destroy()
	self.tide:Destroy()
	self.faults:Destroy()
	self.crew:Destroy()
	self.set:Destroy()
	self.vault:Destroy()
end
return Island
