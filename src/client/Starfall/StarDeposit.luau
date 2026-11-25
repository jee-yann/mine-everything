-- What the meteor left. Crystals fused into the fracture at the bottom of the
-- impact bowl, held by slabs of the rock it broke, still cooling at the edges.
local S = require(script.Parent.Scenery)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local M = Enum.Material
local Deposit = { center = V(0, 26.2, -32) }
Deposit.__index = Deposit

local skin = { "5A36A8", "7448C9", "8A5CE0", "6640B8", "7C50D2", "9468E6" }
local tipTone = { "D8C6FA", "BFA2F4", "EDE4FF", "CBB3F6", "E2D6FC", "B090EE" }

function Deposit.crystal(parent, at, height, radius, buried, lit)
	local sides, shoulder = 6, height * 0.68
	local top = at * V(radius * 0.18, height, -radius * 0.1)
	local low, high = {}, {}
	for i = 1, sides do
		local a = (i + 0.3) / sides * math.pi * 2
		local r = radius * (0.86 + 0.18 * math.sin(i * 2.7 + height))
		low[i] = at * V(math.cos(a) * r * 0.80, -buried, math.sin(a) * r * 0.80)
		high[i] = at * V(math.cos(a) * r, shoulder + radius * 0.35 * math.sin(i * 1.9), math.sin(a) * r)
	end
	local made = {}
	local function keep(before)
		local list = parent:GetChildren()
		for k = before + 1, #list do
			table.insert(made, list[k])
		end
	end
	for i = 1, sides do
		local j = i % sides + 1
		local before = #parent:GetChildren()
		local tone = skin[(i - 1) % #skin + 1]
		local glow = lit and i % 2 == 0
		S.facet(parent, "Crystal face", low[i], low[j], high[i], tone, if glow then M.Neon else nil)
		S.facet(parent, "Crystal face", low[j], high[j], high[i], tone, if glow then M.Neon else nil)
		S.facet(parent, "Crystal tip", high[i], high[j], top, tipTone[(i - 1) % #tipTone + 1], if lit and i % 2 == 0 then M.Neon else nil)
		keep(before)
	end
	return made
end

local rock = { "2E2A38", "38323F", "262431", "413844", "332D3B" }

function Deposit.new()
	local root = S.group("Star deposit")
	local rng = Random.new(6127)
	local c = Deposit.center
	-- Broken beds tilt away from the point of impact. The crystals come up
	-- through the gap between them.
	for i = 1, 15 do
		local a = i / 15 * math.pi * 2 + rng:NextNumber(-0.12, 0.12)
		local r = rng:NextNumber(3.0, 4.6)
		local out = CF(c) * A(0, a, 0) * CF(0, 0, -r) * A(math.rad(rng:NextNumber(26, 48)), rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.15, 0.15))
		local w, h, d = rng:NextNumber(1.5, 2.7), rng:NextNumber(0.7, 1.3), rng:NextNumber(2.0, 3.4)
		S.part(root, "Fused bed", out, V(w, h, d), rock[rng:NextInteger(1, #rock)], M.Slate)
		S.part(root, "Broken edge", out * CF(0, h * 0.35, d * 0.46) * A(0.4, 0, 0), V(w * 0.94, h * 0.5, d * 0.24), rock[rng:NextInteger(1, #rock)], M.Slate)
		if i % 2 == 0 then
			-- The underside is the last thing to cool.
			S.part(root, "Residual heat", out * CF(0, -h * 0.2, d * 0.5), V(w * 0.86, 0.10, 0.12), "C2451C", M.Neon).CastShadow = false
		end
	end
	for i = 1, 22 do
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(4.4, 8.6)
		local s = rng:NextNumber(0.3, 1.0)
		S.part(root, "Ejecta", CF(c + V(math.cos(a) * r, 0.35 + r * 0.03, math.sin(a) * r * 0.85)) * A(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0),
			V(s, s * 0.7, s * 1.2), rock[rng:NextInteger(1, #rock)], M.Slate)
	end
	-- x, z, height, radius, lean away from the centre
	for _, q in {
		{ 0.1, 0.0, 5.0, 0.95, 5 }, { -1.5, 0.6, 3.5, 0.72, 24 }, { 1.6, 0.3, 3.9, 0.70, 21 }, { 0.5, 1.6, 2.9, 0.58, 31 },
		{ -0.8, -1.5, 3.2, 0.62, 26 }, { 1.3, -1.3, 2.4, 0.5, 34 }, { -2.2, -0.6, 2.1, 0.46, 42 }, { 2.4, 1.1, 2.0, 0.44, 44 },
		{ -1.2, 1.9, 1.9, 0.42, 43 },
	} do
		local lean = A(0, math.atan2(q[1], q[2]), 0) * A(math.rad(q[5]), 0, 0)
		Deposit.crystal(root, CF(c + V(q[1], -0.2, q[2])) * lean, q[3], q[4], 0.8, true)
	end
	-- Veins of it run out under the floor of the bowl.
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2 + 0.4
		local p = c + V(math.cos(a) * 2.6, 0.5, math.sin(a) * 2.4)
		for k = 1, 5 do
			local turn = a + 0.28 * math.sin(i * 3.1 + k * 1.7)
			local q = p + V(math.cos(turn) * 1.5, 0.10, math.sin(turn) * 1.3)
			S.strut(root, "Violet seam", p, q, 0.34 * (1 - k / 6.5), 0.12, if k < 3 then "9A6BEA" else "6B3FC0", M.Neon).CastShadow = false
			p = q
		end
	end
	local lamps = {}
	for _, q in { { V(0, 3.4, 1.8), 20, 1.5 }, { V(-2.4, 1.4, -0.6), 11, 0.9 }, { V(2.6, 1.6, 0.8), 11, 0.9 } } do
		local pin = S.part(root, "Star light", CF(c + q[1]), Vector3.one * 0.05, "FFFFFF")
		pin.Transparency = 1
		table.insert(lamps, { light = S.light(pin, "9B66F0", q[2], q[3]), power = q[3] })
	end
	local glow = {}
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and part.Material == M.Neon then
			table.insert(glow, { part = part, color = part.Color, heat = part.Name == "Residual heat" })
		end
	end
	return setmetatable({ root = root, lamps = lamps, glow = glow, level = -1 }, Deposit)
end

function Deposit:place(at)
	self.root:PivotTo(at)
end

-- `life` runs from 1, newly fallen, to 0, gone dark under the rock.
function Deposit:burn(life)
	if life == self.level then
		return
	end
	self.level = life
	for _, g in self.glow do
		local k = if g.heat then math.clamp(life * 1.6 - 0.6, 0, 1) else life
		g.part.Color = g.color:Lerp(Color3.fromHex("0C0812"), 1 - k)
	end
	for _, l in self.lamps do
		l.light.Brightness = l.power * life
	end
end

function Deposit:Destroy()
	self.root:Destroy()
end

return Deposit
