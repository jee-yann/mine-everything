local P = require(script.Parent.Props)
local Beats = require(script.Parent.Beats)
local Acting = require(script.Parent.CrewActing)
local Rig = require(script.Parent.RobloxRig)
local Crew = {}
Crew.__index = Crew
local V, CF, A, rgb, ease = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex, P.ease
local hot, violet, teal = rgb("FFF0AA"), rgb("C885FF"), rgb("52F5D8")
local neon = Enum.Material.Neon
local stoneAt = V(0.05, 0.96, 4.65)
local breaksAt, answersAt = Beats.pick, Beats.answer

-- Small head and shoulder accents land on the two voiced syllables of each line.
local function speechAccent(t, speaker)
	for _, line in Beats.dialogue do
		local age = t - line[1] - 0.06
		if speaker == line[3] and age >= 0 and age < 0.44 then
			if age < 0.15 then
				return math.sin(math.pi * age / 0.15)
			end
			return 0.66 * math.sin(math.pi * math.clamp((age - 0.205) / 0.21, 0, 1))
		end
	end
	return 0
end

local function receiver(parent)
	local root = P.model(parent, "Echo receiver")
	P.box(root, "Rubber case", V(0, 0, 0), V(1.27, 0.92, 0.35), "24374B")
	P.box(root, "Amber shell", V(0, 0.015, 0.046), V(1.16, 0.84, 0.31), "F3A64C")
	P.box(root, "Screen bezel", V(-0.08, 0.064, 0.21), V(0.91, 0.54, 0.085), "273849")
	P.box(root, "Phosphor glass", V(-0.08, 0.062, 0.26), V(0.82, 0.445, 0.028), "132E3B")
	P.box(root, "Zero line", V(-0.08, 0.059, 0.281), V(0.79, 0.012, 0.012), "29606A")
	for i = 1, 3 do
		P.box(root, "Scale division", V(-0.49 + i * 0.2, 0.062, 0.279), V(0.008, 0.42, 0.013), "294F5B")
	end
	local trace = {}
	for i = 1, 12 do
		trace[i] = P.box(root, "Signal trace", Vector3.zero, V(0.022, 0.022, 0.085), "74F8D6", nil, neon)
	end
	local pips = {}
	for i = 1, 3 do
		pips[i] = P.box(root, "Echo " .. i, V(-0.33 + (i - 1) * 0.24, -0.285, 0.217), V(0.15, 0.063, 0.043), "483B53")
	end
	for i = 1, 2 do
		P.box(root, "Rocker", V(0.47, 0.20 - (i - 1) * 0.29, 0.20), V(0.125, 0.18, 0.09), "516477")
	end
	P.rod(root, "Whip aerial", V(0.43, 0.38, 0), V(0.52, 1.14, 0), 0.057, rgb("536575"))
	P.sphere(root, "Aerial tip", V(0.52, 1.14, 0), V(0.10, 0.11, 0.10), "FFA84F")
	P.box(root, "Carry grip", V(0, -0.52, -0.03), V(0.48, 0.29, 0.22), "34475A")
	return root, trace, pips
end

local function pickaxe(parent)
	local root = P.model(parent, "Harbor pick")
	P.rod(root, "Hickory shaft", V(0, -0.52, 0), V(0, 1.94, 0), 0.21, rgb("DA9A5D"))
	P.box(root, "Wrapped grip", V(0, 0.02, 0), V(0.23, 0.66, 0.22), "35485B")
	for i = 1, 3 do
		P.box(root, "Grip band", V(0, -0.30 + i * 0.15, 0), V(0.24, 0.04, 0.23), "657B80")
	end
	P.box(root, "Brass socket", V(0, 1.84, 0), V(0.39, 0.45, 0.40), "F2B950")
	for _, s in { -1, 1 } do
		-- A dark forged spine and a bright bevel leave a readable cutting
		-- silhouette against the sky and the lantern-lit canvas stalls.
		local heel = V(s * 0.12, 2.06, 0)
		local shoulder = V(s * 0.61, 2.12, 0)
		local edge = V(s * 0.66, 1.78, 0)
		local heelLow = V(s * 0.12, 1.73, 0)
		local point = V(s * 1.02, 1.57, 0)
		for _, side in { -1, 1 } do
			local ridge = V(s * 0.55, 1.99, side * 0.185)
			local cheek = V(s * 0.12, 1.96, side * 0.18)
			P.face(root, heel, shoulder, ridge, rgb("425E6D"))
			P.face(root, heel, ridge, cheek, rgb("567382"))
			P.face(root, cheek, ridge, heelLow, rgb("718E9C"))
			P.face(root, ridge, edge, heelLow, rgb("E2F2ED"))
			P.face(root, shoulder, point, ridge, rgb("536E7D"))
			P.face(root, point, edge, ridge, rgb("E2F2ED"))
		end
	end
	return root
end
local bit = V(-1.02, 1.57, 0)

local function nodule(parent)
	local root = P.model(parent, "Signal stone")
	local halves = {}
	for i, s in { -1, 1 } do
		local half = P.model(root, "Fracture half")
		-- The two banks share the same fracture face until the player strikes.
		local ring, shoulder = {}, {}
		for j = 1, 9 do
			local a = (j - 1) * 2 * math.pi / 9
			local y = math.max(-0.96, math.cos(a) * 1.08)
			ring[j] = V(0.08 * math.sin(a * 3), y, math.sin(a) * 0.91)
			shoulder[j] = V(
				s * (0.70 + 0.13 * math.sin(j * 3 + i)),
				math.max(-0.95, y * (0.70 + 0.12 * math.cos(j + i)) - 0.13),
				ring[j].Z * (0.82 + 0.14 * math.sin(j))
			)
		end
		local outside = V(s * 1.19, -0.20 + 0.12 * i, -0.16 + 0.12 * i)
		local skin = { "303638", "44484A", "292E32", "535758" }
		for j = 1, #ring do
			local nextJ = j % #ring + 1
			local a, b, c, d = ring[j], ring[nextJ], shoulder[j], shoulder[nextJ]
			local shade = rgb(skin[(i + j) % #skin + 1])
			P.face(half, a, b, c, shade)
			P.face(half, b, c, d, if j == 2 + i then rgb("8F948A") else shade)
			P.face(half, c, d, outside, rgb(skin[(2 * i + j) % #skin + 1]))
			P.face(half, a, b, V(s * 0.05, 0, 0), rgb(if j % 4 == 0 then "A5A59B" else "5D6462"))
		end
		for _, p in half:GetChildren() do
			p.Material = Enum.Material.Slate
		end
		halves[i] = half
	end
	-- A pressure wave crosses the bedding from the gallery. Its light briefly
	-- picks out hairline veins in the exposed rock, then travels beyond the pick.
	local bed = P.model(root, "Listening seam")
	local outline = { V(-0.70, 0.04, -0.74), V(-0.12, 0.02, -1.02), V(0.57, 0.04, -0.75),
		V(0.68, 0.04, 0.41), V(0.08, 0.03, 0.91), V(-0.59, 0.04, 0.62) }
	for j, a in outline do
		P.face(bed, a, outline[j % #outline + 1], V(0, 0.17, 0), rgb(if j % 2 == 0 then "514A50" else "47434A"))
	end
	local channel = {
		V(0.08, 0.07, -0.93), V(-0.16, 0.12, -0.55), V(-0.07, 0.17, -0.25),
		V(0.13, 0.19, 0.03), V(0.03, 0.15, 0.37), V(0.18, 0.10, 0.71),
	}
	local veins = {}
	for j = 2, #channel do
		veins[#veins + 1] = P.rod(bed, "Fracture trace", channel[j - 1], channel[j], 0.058, rgb("5B4D63"))
	end
	veins[#veins + 1] = P.rod(bed, "Branch", channel[4], V(0.44, 0.12, 0.22), 0.039, rgb("5B4D63"))
	veins[#veins + 1] = P.rod(bed, "Branch", channel[3], V(-0.43, 0.12, -0.12), 0.047, rgb("5B4D63"))
	local light = P.light(veins[3], "B78BFA", 6, 0)
	local crumbs = {}
	for i = 1, 10 do
		local shard = P.sphere(
			root,
			"Basalt chip",
			Vector3.zero,
			V(0.13 + (i % 3) * 0.05, 0.13, 0.18),
			"515657",
			Enum.Material.Slate
		)
		table.insert(crumbs, shard)
	end
	local wave = P.model(parent, "Returned signal")
	local arcs = {}
	for i = 1, 24 do
		arcs[i] = P.box(wave, "Ripple in the grit", Vector3.zero, V(0.10, 0.045, 0.18), "BEA493", nil, Enum.Material.Sand)
	end
	return halves, bed, veins, light, crumbs, arcs
end

function Crew.new(shelf, character)
	local self = setmetatable({}, Crew)
	self.root = P.model(shelf, "The knocking crew")
	self.operator = Rig.new(self.root, "Survey operator")
	self.player = Rig.new(self.root, "Expedition miner", character, true)
	self.receiver, self.trace, self.pips = receiver(self.root)
	self.pick = pickaxe(self.root)
	self.halves, self.bed, self.veins, self.light, self.crumbs, self.arcs = nodule(self.root)
	return self
end

-- Three different needle excursions travel across the receiver. Its line
-- sits on zero in the quiet before the reply.
local traces = {
	{ 0, -0.18, 0.94, -0.72, 0.18, 0 },
	{ 0, 0.24, -0.56, 1.00, -0.88, 0.32, 0 },
	{ 0, -0.29, 1.00, -0.68, 0.60, -0.38, 0.19, 0 },
}
local function needle(x, age, signal)
	if not signal or age < 0 or age >= 0.40 then
		return 0
	end
	local advance = math.min(math.floor(age * 20) / 20, 0.27)
	local u = (x - (0.50 + advance * 1.40)) / 0.78 + 0.5
	if u <= 0 or u >= 1 then
		return 0
	end
	local at = u * (#signal - 1)
	local index = math.floor(at) + 1
	return (signal[index] + (signal[index + 1] - signal[index]) * (at % 1))
		* 0.20 * (1 - ease(age, 0.16, 0.40))
end

local function stick(part, start, finish, width)
	local length = (finish - start).Magnitude
	part.CFrame = CFrame.lookAt((start + finish) * 0.5, finish)
	part.Size = V(width, width, length)
end

function Crew:scan(t, base, motion)
	local pulse = 0
	local answerCount = 0
	for _, beat in Beats.returned do
		if t >= beat then
			answerCount += 1
			pulse = math.max(pulse, math.exp(-(t - beat) * 5.7))
		end
	end
	local speaking = speechAccent(t, "SURVEY LEAD")
	local pose = Acting.read(Acting.lead, t)
	local contact = if motion and pulse > 0.45 then math.rad(2.3) * pulse else 0
	local degree = math.pi / 180
	local meterTurn = pose.tilt * degree
	local device = base * CF(pose.meter) * A(meterTurn.X, meterTurn.Y, meterTurn.Z + contact)
	self.receiver:PivotTo(device)
	local palm = (device * CF(-0.04, -0.40, -0.13)).Position
	local body, eyes = pose.body * degree, pose.gaze * degree
	local stance = pose.stance
	self.operator:pose(base * CF(-3.90 + stance.X, 0, 5.40) * A(0, math.pi + math.rad(stance.Z), 0), {
		bob = stance.Y,
		RootJoint = A(body.X, body.Y, body.Z),
		Neck = A(eyes.X + 0.059 * speaking, eyes.Y, eyes.Z),
		LeftTarget = palm,
		RightTarget = base * (pose.hand + V(0, 0.075 * speaking, -0.035 * speaking)),
		LeftHip = A(-0.055, 0, 0.07),
		RightHip = A(0.055, 0, -0.07),
	})
	local previous
	local signal = traces[answerCount]
	local age = if signal then t - Beats.returned[answerCount] else 0
	for i = 0, #self.trace do
		local x = i / #self.trace
		local high = needle(x, age, signal)
		local at = (device * CF(-0.478 + 0.797 * x, 0.060 + high, 0.292)).Position
		if previous then
			local mark = self.trace[i]
			stick(mark, previous, at, 0.019)
			mark.Color = teal:Lerp(violet, pulse)
		end
		previous = at
	end
	for i, pip in self.pips do
		pip.Material = if i <= answerCount then neon else Enum.Material.SmoothPlastic
		pip.Color = if i <= answerCount then hot:Lerp(violet, 0.6) else rgb("483B53")
	end
	self.receiverAim = (device * CF(-0.05, 0.12, 0.26)).Position
end

local function pickFrame(grip, aim, facing)
	local up = (aim - grip).Unit
	local side = up:Cross(facing)
	if side.Magnitude < 0.02 then
		side = up:Cross(Vector3.xAxis)
	end
	side = side.Unit
	-- Map the actual curved steel tip onto the animated swing direction.
	local plane = CFrame.fromMatrix(grip, side, up, side:Cross(up))
	return plane * A(0, 0, -math.atan2(-bit.X, bit.Y))
end

function Crew:mine(t, base)
	local drawing = Acting.read(Acting.miner, t)
	local speaking = speechAccent(t, "YOU")
	local degree = math.pi / 180
	local stride = ease(t, 44.55, 45.12)
	local run = ease(t, 44.55, 49.30)
	local gait = math.sin((t - 44.6) * 10.5) * stride
	local stance = drawing.foot
	local foot = base * CF(stance.X - 1.68 * run, 0, stance.Z - 12.2 * run)
		* A(0, math.rad(drawing.yaw) * (1 - stride) + 0.08 * stride, 0)
	local back, eyes = drawing.torso * degree, drawing.gaze * degree
	local toRun = 1 - stride
	self.player:pose(foot, {
		bob = stance.Y * toRun + 0.145 * math.abs(gait),
		RootJoint = A(back.X * toRun, back.Y * toRun, back.Z * toRun),
		Root = A(back.X * 0.58 * toRun, back.Y * 0.52 * toRun, back.Z * 0.63 * toRun),
		Waist = A(back.X * 0.42 * toRun, back.Y * 0.48 * toRun, back.Z * 0.37 * toRun),
		Neck = A(eyes.X * toRun + 0.077 * speaking, eyes.Y * toRun, eyes.Z * toRun),
		LeftHip = A(0.58 * gait - 0.18 * drawing.bite, 0, -0.04),
		RightHip = A(-0.58 * gait + 0.15 * drawing.bite, 0, 0.05),
		LeftKnee = A(-0.60 * math.max(gait, 0) - 0.25 * drawing.bite, 0, 0),
		RightKnee = A(-0.60 * math.max(-gait, 0), 0, 0),
		RightTarget = (base * drawing.grip):Lerp(foot * V(0.98, 2.81 - 0.32 * gait, -0.35 + 0.66 * gait), stride),
		LeftTarget = (base * drawing.freeHand):Lerp(foot * V(-1.13, 2.83 + 0.20 * gait, -0.42 - 0.76 * gait), stride),
	})
	local palm = self.player:palm("Right")
	local tip = base * V(0.17, 1.81, 4.79)
	local direction = base:VectorToWorldSpace(drawing.beak):Lerp(foot:VectorToWorldSpace(V(0.38, 1.8, 0.35 + 0.25 * gait)), stride)
	local aim = (palm + direction):Lerp(tip, drawing.bite)
	local tool = pickFrame(palm, aim, foot.LookVector)
	-- Different avatar proportions change the natural spot on the wrap where
	-- the fingers close. Slide the haft through the hand to seat its steel tip.
	tool += (tip - tool * bit) * drawing.bite
	self.pick:PivotTo(tool)
	self.playerAim = self.player.head.Position + Vector3.yAxis * (self.player.headroom * 0.30)
	self.pickTip = (tool * CF(bit)).Position
end

function Crew:fracture(t, base)
	local age = math.max(0, t - breaksAt)
	local answerAge = t - answersAt
	local echo = if answerAge >= 0 then math.exp(-answerAge * 4.25) else 0
	for i, half in self.halves do
		local side = if i == 1 then -1 else 1
		-- The first half breaks at the tip. The second catches on its
		-- neighbor, slips free a little later, and rocks once on its heel.
		local slip = if i == 1 then 0 else 0.13
		local open = 0.72 * ease(age, slip, slip + 0.055) + 0.28 * ease(age, slip + 0.14, slip + 0.23)
		local heel = ease(age, slip, slip + 0.06) * (1 - ease(age, slip + 0.12, slip + 0.21))
		local at = stoneAt + V(side * (0.54 + 0.10 * i) * open, 0.16 * heel - 0.16 * open, (i - 0.9) * 0.19 * open)
		half:PivotTo(base * CF(at) * A(0.12 * open, side * 0.26 * open, -side * (0.31 * open + 0.13 * heel)))
	end
	local footing = base * CF(stoneAt.X, 0.105, stoneAt.Z)
	self.bed:PivotTo(footing)
	self.light.Brightness = 2.1 * echo
	for i, edge in self.veins do
		local since = answerAge - (i - 1) * 0.035
		local strength = if since >= 0 then math.exp(-3.5 * since) else 0
		edge.Color = rgb("64566A"):Lerp(rgb("D1A1EF"), strength)
		edge.Material = if strength > 0.11 then neon else Enum.Material.Slate
	end
	self.seamAim = footing * V(0.03, 0.26, -0.06)
	for i, shard in self.crumbs do
		local az = i * 2.399
		local r = (0.52 + i * 0.12) * math.min(1, age * 1.45)
		local height = math.max(0, 0.48 + age * (3.2 + i * 0.22) - 12 * age * age)
		shard.CFrame = base
			* CF(stoneAt + V(math.sin(az) * r, height - 0.75, math.cos(az) * r))
			* A(az, age * 4, az + age)
		shard.Transparency = if age > 0 then ease(t, 42.15, 42.83) else 1
	end
	local radius = 0.42 + math.max(0, answerAge) * 8
	for i, p in self.arcs do
		if answerAge >= 0 and answerAge <= 0.85 then
			local a = (i - 1) * math.pi * 2 / #self.arcs
			local at = V(stoneAt.X + math.cos(a) * radius, 0.065, stoneAt.Z + math.sin(a) * radius)
			p.CFrame = base * CF(at) * A(0, -a, 0)
			p.Size = V(0.058, 0.045, radius * (0.105 + 0.045 * math.sin(i * 2.7)))
			p.Transparency = 0.53 + 0.47 * ease(t, answersAt + 0.12, answersAt + 0.66)
		else
			p.Transparency = 1
		end
	end
end

function Crew:draw(t, base, motion)
	self:scan(t, base, motion)
	self:mine(t, base)
	self:fracture(t, base)
end
return Crew
