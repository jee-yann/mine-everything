local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local PrecisionCut = {}
PrecisionCut.__index = PrecisionCut

local function locator(origin, name, pos)
	local mark = Instance.new("Attachment")
	mark.Name, mark.Position, mark.Parent = name, pos, origin
	return mark
end

local function bench(parent)
	local wood, iron = Enum.Material.Wood, Enum.Material.Metal
	for i = 1, 4 do
		S.part(
			parent,
			"Oiled driftwood",
			CF(0, -1.058, -0.81 + (i - 1) * 0.54),
			V(4.65, 0.26, 0.52),
			({ "8D674E", "9D7657", "876248", "997151" })[i],
			wood
		)
	end
	for _, x in { -1.67, 1.67 } do
		S.part(parent, "Iron trestle shoe", CF(x, -1.235, 0), V(0.27, 0.18, 2.13), "48525A", iron)
		for _, z in { -0.65, 0.65 } do
			local foot = V(x + math.sign(x) * 0.18, -2.67, z * 1.22)
			S.strut(parent, "Splayed trestle", foot, V(x, -1.18, z), 0.28, 0.28, "6F5948", wood)
			S.part(parent, "Steel toe", CF(foot), V(0.33, 0.11, 0.35), "566061", iron)
		end
		S.strut(parent, "Trestle brace", V(x, -2.23, -0.77), V(x, -2.23, 0.77), 0.16, 0.18, "816348", wood)
	end
	S.strut(parent, "Stretcher", V(-1.7, -2.10, 0), V(1.7, -2.10, 0), 0.20, 0.22, "785D4B", wood)
	-- The gauge is flush to the front board, below the sightline to the gem.
	S.part(parent, "Brass gauge", CF(0.03, -0.91, 1.002), V(3.79, 0.032, 0.085), "A98D58", iron)
	for i = -7, 7 do
		local tall = i % 2 == 0
		S.part(
			parent,
			"Scribed division",
			CF(i * 0.239, -0.891, 1.005),
			V(0.014, 0.006, if tall then 0.057 else 0.031),
			"544742"
		)
	end
end

function PrecisionCut.new()
	local model = script.Parent.ProspectorProof:Clone()
	model.Name = "Prospector's precision cut"
	local root = model.PrimaryPart
	local phase = math.pi * 4 / 14
	local seam = V(
		0.073 * math.sin(3 * phase + 0.4) + 0.031 * math.cos(5 * phase),
		math.sin(phase) * (0.87 + 0.06 * math.sin(3 * phase + 0.4)) - 0.04,
		math.cos(phase) * (0.89 + 0.09 * math.cos(2 * phase - 0.2)) + 0.08 * math.sin(2 * phase)
	)
	local crystal = locator(root, "Emerald body", V(-0.042, 0.025, 0.070))
	local tip = locator(root, "Emerald crown", V(-0.085, 0.427, 0.125))
	local light = S.light(tip, "A1FFB8", 2.3, 0)
	light.Enabled, light.Shadows = false, false
	bench(model)
	local halves = {}
	for _, side in { -1, 1 } do
		local rock = if side < 0 then model.Left else model.Right
		local sole = {}
		for name, v in rock:GetAttributes() do
			if string.sub(name, 1, 7) == "Contact" then
				table.insert(sole, v)
			end
		end
		table.insert(
			halves,
			{ rock = rock, side = side, rest = model:GetPivot():ToObjectSpace(rock.CFrame), sole = sole }
		)
	end
	return setmetatable({
		model = model,
		left = model.Left,
		right = model.Right,
		halves = halves,
		gem = crystal,
		gemTip = tip,
		seam = locator(root, "Reading notch", seam),
		face = locator(root, "Bench sightline", seam),
		light = light,
	}, PrecisionCut)
end

function PrecisionCut:place(actor)
	local u = actor.unit
	self.unit = u
	self.model:ScaleTo(u)
	self.site = actor.mineBearing * CF(1.85 * u, -0.40 * u, -3.08 * u) * A(0, math.rad(43), 0) * CF(-self.seam.Position)
	self.model:PivotTo(self.site)
end

function PrecisionCut:draw(stage, frame)
	self.model.Parent = if frame >= F.present and frame < F.commission then stage else nil
	if self.model.Parent == nil then
		return
	end
	local age = frame - F.proofStrike
	for _, half in self.halves do
		local side = half.side
		local start = if side == -1 then 0 else 1
		local spread = S.ease(age, start, start + 17)
		local rockback = S.ease(age, 13, 17) * (1 - S.ease(age, 17, 24))
		local hinge = V(side * 0.91, -0.85, -0.08) * self.unit
		local transform = CF(V(side * (0.65 * spread + 0.025 * rockback), 0.012 * rockback, -0.08 * spread) * self.unit)
			* CF(hinge)
			* A(0.025 * spread, side * (0.53 * spread + 0.02 * rockback), -side * (0.48 * spread + 0.055 * rockback))
			* CF(-hinge)
		if spread > 0 then
			local bottom = math.huge
			for _, v in half.sole do
				bottom = math.min(bottom, (transform * (v * self.unit)).Y)
			end
			if bottom < math.huge then
				transform += Vector3.yAxis * (-0.931 * self.unit - bottom) * spread
			end
		end
		local r = half.rest
		half.rock.CFrame = self.site * transform * CF(r.Position * self.unit) * r.Rotation
	end
	local gemPulse = S.ease(age, 17, 26) * (1 - S.ease(age, 27, 40))
	local breath = S.ease(age, 44, 49) * (1 - S.ease(age, 49, 59))
	local strength = math.max(gemPulse, breath * 0.42)
	self.light.Enabled = strength > 0.01
	self.light.Brightness = 0.46 * strength
end

function PrecisionCut:hide()
	self.model.Parent = nil
end
function PrecisionCut:Destroy()
	self.model:Destroy()
end
return PrecisionCut
