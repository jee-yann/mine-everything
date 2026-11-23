local P = require(script.Parent.Props)
local Rig = require(script.Parent.RobloxRig)
local Beats = require(script.Parent.Beats)
local Acting = require(script.Parent.CrewActing)
local Survey = {}
Survey.__index = Survey
local V, CF, A, rgb = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex
local metal, neon = Enum.Material.Metal, Enum.Material.Neon
local pad = V(1.6, 0.34, 22.7)
Survey.pad = pad

-- The survey hammer sends its test down the cable from the footbridge to the gate.
local cablePath =
	{ pad + V(0, 0.13, 0), V(1.0, 0.47, 20.1), V(-2.3, 0.40, 17.0), V(-3.4, 0.38, 11), V(-3.05, 0.40, 7.0) }
local faultPath = {
	V(0.05, 1.2, 4.65),
	V(0.5, 0.42, 3.3),
	V(-0.85, 0.30, 0.2),
	V(0.14, 0.27, -3.6),
	V(-1.64, 0.25, -6.5),
	V(-0.48, 0.22, -11),
	V(-2.25, 0.22, -17),
	V(-1, 0.22, -22),
}
local function onPath(path, u)
	local at = math.clamp(u, 0, 1) * (#path - 1)
	local i = math.min(math.floor(at) + 1, #path - 1)
	return path[i]:Lerp(path[i + 1], at - i + 1)
end
function Survey.new(shelf)
	local root = P.model(shelf, "Footbridge survey")
	local self = setmetatable({ root = root, lamps = {}, pips = {}, fault = {} }, Survey)
	P.cylinder(root, "Footplate", pad, 0.98, 0.24, "374453", metal)
	P.cylinder(root, "Strike plate", pad + V(0, 0.15, 0), 0.59, 0.12, "CCC3A3", metal)
	for i = 1, 3 do
		local angle = i * math.pi * 2 / 3
		local s = V(math.cos(angle), 0, math.sin(angle))
		P.rod(root, "Folding leg", pad + s * 1.55, pad + s * 0.65 + V(0, 3.05, 0), 0.21, rgb("E7A836"))
		P.rod(root, "Brace", pad + s * 1.12 + V(0, 0.82, 0), pad + V(0, 0.48, 0), 0.13, rgb("44575C"))
		P.box(root, "Rubber foot", pad + s * 1.53, V(0.48, 0.25, 0.49), "343D46")
	end
	P.cylinder(root, "Drive casing", pad + V(0, 3.15, 0), 0.92, 0.76, "D69C39", metal)
	P.cylinder(root, "Cap", pad + V(0, 3.60, 0), 0.78, 0.16, "405861", metal)
	self.ram = P.model(root, "Test hammer")
	P.cylinder(self.ram, "Piston shaft", V(0, 0.99, 0), 0.2, 1.7, "9CABAA", metal)
	P.cylinder(self.ram, "Hammer head", V(0, 0.20, 0), 0.52, 0.40, "596574", metal)
	P.cylinder(self.ram, "Striker collar", V(0, 0.34, 0), 0.54, 0.10, "E2BA69", metal)
	P.cylinder(self.ram, "Guide ring", V(0, 0.78, 0), 0.22, 0.10, "D8C9A3", metal)
	-- A miner cocks the drop hammer by hand. The catch releases the ram on
	-- the downstroke; both the lever and the hands use this same hinge.
	self.tech = Rig.new(root, "Sounding crew", nil, true)
	self.handle = P.model(root, "Hammer lever")
	P.rod(self.handle, "Chrome lever", Vector3.zero, V(-1.55, 0.12, 0), 0.12, rgb("ACC4C2")).Material = metal
	P.rod(self.handle, "Gripped end", V(-1.15, 0.10, 0), V(-1.68, 0.13, 0), 0.22, rgb("344956"))
	P.box(root, "Lever hinge", pad + V(-0.46, 2.57, 0.58), V(0.39, 0.32, 0.32), "D9AE64", nil, metal)
	for i = 1, 3 do
		local p = P.box(root, "Counter lamp", pad + V((i - 2) * 0.33, 3.18, 0.86), V(0.23, 0.32, 0.09), "37454B")
		table.insert(self.lamps, p)
	end
	for i = 1, #cablePath - 1 do
		P.rod(root, "Survey cable", cablePath[i], cablePath[i + 1], 0.14, rgb("394C56"))
	end
	for i = 1, 3 do
		table.insert(self.pips, P.sphere(root, "Cable pulse", Vector3.zero, V(0.48, 0.22, 0.72), "FFD371", neon))
	end
	-- The crew's standing work light illuminates their hands on the tunnel side.
	local foot = V(-5.7, 0.27, 1.9)
	P.box(root, "Work light foot", foot, V(1.24, 0.28, 1), "405764", nil, metal)
	P.rod(root, "Light mast", foot, foot + V(0, 3.7, 0), 0.13, rgb("7B8994"))
	P.box(root, "Lamp guard", foot + V(0, 3.74, 0), V(0.82, 0.63, 0.35), "465561", A(0, -0.64, 0), metal)
	local lamp =
		P.box(root, "LED panel", foot + V(0.11, 3.74, 0.15), V(0.66, 0.43, 0.13), "FFEACB", A(0, -0.64, 0), neon)
	P.light(lamp, "FFF1D8", 19, 1.52)
	-- An unpowered plumb line makes the subterranean vibration visible in daylight.
	self.plumb = P.model(root, "Survey plumb line")
	P.rod(self.plumb, "Cord", Vector3.zero, V(0, -1.72, 0), 0.028, rgb("D5CBB5"))
	local tip, band = V(0, -2.25, 0), V(0, -1.78, 0)
	for i = 1, 6 do
		local a, b = i * math.pi / 3, (i + 1) * math.pi / 3
		local va, vb = V(math.cos(a), 0, math.sin(a)) * 0.20, V(math.cos(b), 0, math.sin(b)) * 0.20
		P.face(self.plumb, tip, band + va, band + vb, rgb(if i % 2 == 1 then "BC8746" else "E4B46B"))
		P.face(self.plumb, band + V(0, 0.12, 0), band + vb, band + va, rgb("F3C982"))
	end
	local hook = foot + V(1.45, 3.70, 0.25)
	P.rod(root, "Survey mast arm", foot + V(0, 3.58, 0), hook, 0.09, rgb("85847E"))
	self.hook = hook
	for i = 1, #faultPath - 1 do
		local p = P.rod(root, "Answer in the rock", faultPath[i], faultPath[i + 1], 0.12, rgb("DFB4FF"))
		p.Material, p.Transparency = neon, 1
		table.insert(self.fault, p)
	end
	self.front = P.sphere(root, "Echo front", Vector3.zero, V(0.63, 0.34, 1.42), "F4DCFF", neon)
	self.light = P.light(self.front, "DC9AFF", 11, 1.0)
	return self
end
-- The operator loads the latch, the ram drops under its own weight and
-- the lever follows through. Each test uses a different height and grip.
local function hammer(ram, wrist, waist, face, brace)
	return { ram = ram, wrist = wrist, waist = waist, face = face, brace = brace }
end
local rest = hammer(0, 0.14, -7, -12, 0)
local firstLift = hammer(0.72, 0.86, 4, -5, 0.18)
local firstBite = hammer(0, 0.28, -15, -18, 0.08)
local quickLift = hammer(0.58, 0.70, -2, -13, 0.13)
local quickBite = hammer(0, 0.16, -13, -17, 0.04)
local shoulders = hammer(0.96, 1.03, 9, -10, 0.24)
local hanging = hammer(1, 1.01, 10, -8, 0.26)
local thirdBite = hammer(0, 0.29, -19, -24, -0.10)
local dumped = hammer(0, -0.12, -22, -18, -0.14)
local glance = hammer(0, 0.03, -8, -3, -0.03)
local a, b, c = table.unpack(Beats.outbound)
local strokes = {
	{ 0, rest, 0 },
	{ a - 0.20, firstLift, 0.11 },
	{ a - 0.045, hammer(0.47, 0.74, 0, -6, 0.12), 0.018 },
	{ a, firstBite, 0.026 },
	{ a + 0.12, hammer(0.10, 0.10, -17, -14, 0.02), 0.04 },
	{ b - 0.14, quickLift, 0.09 },
	{ b - 0.045, hammer(0.38, 0.59, -5, -14, 0.09), 0.02 },
	{ b, quickBite, 0.028 },
	{ b + 0.12, rest, 0.035 },
	{ c - 0.30, shoulders, 0.13 },
	{ c - 0.21, hanging, 0.04 },
	{ c - 0.055, hammer(0.76, 0.92, 5, -9, 0.16), 0.025 },
	{ c, thirdBite, 0.04 },
	{ c + 0.09, dumped, 0.04 },
	{ c + 0.41, glance, 0.12 },
}

function Survey:draw(t, base)
	local stroke = Acting.read(strokes, t)
	for i, when in Beats.outbound do
		local age = t - when
		local lamp = self.lamps[i]
		lamp.Color = rgb(if age >= 0 and age < 3.1 then "FFCD54" else "37454B")
		lamp.Material = if age >= 0 and age < 3.1 then neon else metal
		local p = self.pips[i]
		p.Transparency = if age >= 0 and age <= 1.70 then 0.05 else 1
		if p.Transparency < 1 then
			p.Position = base * onPath(cablePath, age / 1.70)
		end
	end
	self.ram:PivotTo(base * CF(pad + V(0, 0.25 + stroke.ram * 1.62, 0)))
	local hinge = base * CF(pad + V(-0.46, 2.57, 0.58)) * A(0, 0, 0.33 - 0.89 * stroke.wrist)
	self.handle:PivotTo(hinge)
	local listening = P.ease(t, c + 0.29, c + 0.41)
	local techFloor = base * CF(pad + V(-2.65, -0.14, -0.68)) * A(0, -2.07, 0)
	self.tech:pose(techFloor, {
		bob = -0.11 + stroke.brace,
		RootJoint = A(math.rad(stroke.waist), -0.11 * listening, 0.055 - 0.12 * stroke.brace),
		Neck = A(math.rad(stroke.face), -0.55 * listening, 0.07 * stroke.wrist),
		RightTarget = hinge * V(-1.54, 0.10, 0),
		LeftTarget = base * (pad + V(-2.14 + 0.15 * stroke.wrist, 2.40 + 0.65 * stroke.wrist, -0.04)),
		LeftHip = A(0.14 - 0.3 * stroke.brace, 0, 0.04),
		RightHip = A(-0.16 + 0.3 * stroke.brace, 0, -0.045),
	})
	local swing = 0
	for _, knock in Beats.returned do
		local age = t - knock
		if age >= 0 then
			swing += math.sin(age * 12.0) * math.exp(-age * 3.0) * 0.16
		end
	end
	local age = t - Beats.answer
	if age >= 0 then
		swing += math.sin(age * 8.6) * math.exp(-age * 2.4) * 0.32
	end
	self.plumb:PivotTo(base * CF(self.hook) * A(0.12 * swing, 0, swing))
	local u = (t - 44.6) / 2.4
	for i, p in self.fault do
		local age = t - (44.6 + 2.4 * (i - 1) / #self.fault)
		p.Transparency = if age < 0 then 1 else 0.12 + 0.88 * P.ease(age, 0.18, 1.05)
	end
	self.front.Transparency = if u >= 0 and u <= 1 then 0.09 else 1
	self.light.Enabled = self.front.Transparency < 1
	if self.light.Enabled then
		self.front.Position = base * onPath(faultPath, u)
	end
end

return Survey
