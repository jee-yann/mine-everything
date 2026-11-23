-- The center of the settled basin opens like two sides of one sheared rock
-- bed. Both shelves share every boundary vertex with the surrounding crater.
local P = require(script.Parent.Props)
local V, CF, A, rgb, ease = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex, P.ease
local Fault = {}
Fault.__index = Fault
local function vertex(at)
	return { at = at, point = at }
end
local function add(self, a, b, c, color)
	-- Endpoint fans meet at a single point.
	if (b.at - a.at):Cross(c.at - a.at).Magnitude < 0.001 then
		return
	end
	local ink = rgb(color)
	local pieces = {}
	for i = 1, 2 do
		pieces[i] = P.part(self.root, "Broken bedrock", Vector3.one, CFrame.identity, ink, "WedgePart")
	end
	table.insert(self.faces, { a, b, c, pieces })
end
local function fit(face, base)
	local a, b, c = face[1].point, face[2].point, face[3].point
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > math.max(ac.Magnitude, bc.Magnitude) then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal, along = ac:Cross(ab).Unit, bc.Unit
	local up = along:Cross(normal)
	for i, v in { b, c } do
		local sign = if i == 1 then 1 else -1
		local p = face[4][i]
		p.Size = V(0.025, math.max(0.025, math.abs(ab:Dot(up))), math.max(0.025, math.abs((v - a):Dot(along))))
		p.CFrame = base * CFrame.fromMatrix((a + v) * 0.5, normal * sign, up, along * sign)
	end
end
local function grounded(bed, x, z)
	return V(x, bed:heightAt(x, z), z)
end
function Fault.new(parent, bed)
	local self = setmetatable(
		{ root = P.model(parent, "Sealed impact fault"), faces = {}, banks = {}, lightPaths = {}, chips = {} },
		Fault
	)
	local previous
	for i = 0, 16 do
		local outerA = bed.edge[i + 1]
		local outerB = bed.edge[(32 - i) % 32 + 1]
		local taper = math.sin(i * math.pi / 16)
		local x = (outerA.X + outerB.X) * 0.5
		local z = (x * 0.26 + 0.87 * math.sin(i * 2.27) + 0.41 * math.cos(i * 1.29)) * taper
		local center = if i == 0 or i == 16 then outerA else grounded(bed, x, z)
		local row = { center = center, sides = {}, floor = center - V(0, 0.76 + 0.25 * taper, 0) }
		for n, edge in { outerA, outerB } do
			local side = if n == 1 then 1 else -1
			local lip = vertex(center)
			local wall = vertex(center - V(0, 1.56 + 0.64 * taper, 0))
			local mid = center:Lerp(edge, 0.49)
			local seam = {
				inner = lip,
				low = wall,
				mid = vertex(grounded(bed, mid.X, mid.Z)),
				outer = vertex(edge),
				side = side,
				dist = math.abs(x - 1.6),
				run = (i - 1) / 15,
				span = taper * (1.06 + 0.18 * math.cos(i * 2.3)),
				last = -1,
			}
			row.sides[n] = seam
			table.insert(self.banks, seam)
			if previous then
				local last = previous.sides[n]
				local middle = if n == 1 then "685B5E" else "66595E"
				add(self, last.inner, seam.inner, seam.mid, middle)
				add(self, last.inner, seam.mid, last.mid, middle)
				add(self, last.mid, seam.mid, seam.outer, "736367")
				add(self, last.mid, seam.outer, last.outer, "736367")
				add(self, last.inner, seam.inner, seam.low, "3F3549")
				add(self, last.inner, seam.low, last.low, "4A3A4C")
			end
		end
		if previous then
			local a, b = previous.floor, row.floor
			local under = rgb("292335")
			P.face(self.root, a - V(0, 0.16, 2), b - V(0, 0.16, 2), b + V(0, -0.16, 2), under)
			P.face(self.root, a - V(0, 0.16, 2), b + V(0, -0.16, 2), a + V(0, -0.16, 2), under)
			local vein = P.rod(self.root, "Light below the lip", a, b, 0.16 + 0.12 * taper, rgb("BD7EFF"))
			local hair =
				P.rod(self.root, "Hot center of fault", a + V(0, 0.08, 0), b + V(0, 0.08, 0), 0.078, rgb("FFE1F3"))
			vein.Material, hair.Material = Enum.Material.Neon, Enum.Material.Neon
			vein.CastShadow, hair.CastShadow = false, false
			table.insert(
				self.lightPaths,
				{ violet = vein, hair = hair, dist = math.abs((a.X + b.X) * 0.5 - 1.6), taper = taper, run = i / 16 }
			)
		end
		previous = row
	end
	local lamp = P.box(self.root, "Light rising through the fault", V(0.8, -3.12, 0.32), Vector3.one * 0.1, "FFFFFF")
	lamp.Transparency, lamp.CastShadow = 1, false
	self.lamp = P.light(lamp, "D6A6F5", 19, 0)
	local rng = Random.new(48009)
	for i = 1, 24 do
		local x = rng:NextNumber(-12.4, 12.1)
		local side = if i % 2 == 0 then 1 else -1
		local z = 0.25 * x + side * rng:NextNumber(2.3, 6.5)
		local s = rng:NextNumber(0.15, 0.55)
		local at = grounded(bed, x, z) + V(0, s * 0.13, 0)
		local p = P.part(self.root, "Scoria fragment", V(s * 1.5, s * 0.63, s), CF(at), rgb("635359"), "WedgePart")
		table.insert(
			self.chips,
			{ part = p, at = at, side = side, off = rng:NextNumber(0, 0.38), rot = rng:NextNumber(-1.4, 1.4) }
		)
	end
	return self
end

function Fault:draw(t, base)
	local reflection = 0
	for _, p in self.lightPaths do
		-- A single tear runs across the rock face. It sits open long enough
		-- to read, then both lit ends are pulled toward one deep pocket.
		local head = 8.76 + 0.24 * p.run
		local flare = ease(t, head, head + 0.033)
		local rest = if t < head + 0.12 then 0.94 elseif t < 9.71 then 0.48 else 0.24
		local retreat = 10.39 - 0.026 * p.dist
		local last = ease(t, retreat - 0.12, retreat - 0.04) * (1 - ease(t, retreat, retreat + 0.048))
		local glow = flare * math.max(rest * (1 - ease(t, retreat, retreat + 0.035)), last) * p.taper ^ 0.6
		p.violet.Transparency, p.hair.Transparency = 1 - glow, 1 - glow * 0.85
		reflection = math.max(reflection, glow)
	end
	self.lamp.Brightness = reflection * 1.78
	local dirty = false
	for _, b in self.banks do
		local arrival = 8.76 + 0.24 * b.run
		local tap = t - arrival
		local open = if tap < 0 then 0 elseif tap < 0.043 then 0.39 elseif tap < 0.108 then 1.12 else 1
		local slip = t - 0.004 * b.dist - (if b.side == 1 then 0.04 else 0)
		if slip >= 11.08 then
			open = 0
		elseif slip >= 10.69 then
			open *= 0.39
		elseif slip >= 10.63 then
			open *= 0.28
		end
		if b.last ~= open then
			b.last = open
			local move = V(0.12 * b.side, 0.40 + 0.08 * b.side, b.side * 1.08) * b.span * open
			b.inner.point = b.inner.at + move
			b.low.point = b.low.at + V(move.X * 0.38, move.Y * 0.38, move.Z * 0.48)
			b.mid.point = b.mid.at + move * 0.14
			dirty = true
		end
	end
	if dirty then
		for _, f in self.faces do
			fit(f, base)
		end
	end
	for _, c in self.chips do
		local first = math.clamp((t - 10.61 - c.off * 0.33) / 0.23, 0, 1)
		local second = math.clamp((t - 11.07 - c.off * 0.26) / 0.22, 0, 1)
		local settle = 0.62 * first + 0.38 * second
		local hop = first * (1 - first) * 1.28 + second * (1 - second) * 0.66
		c.part.CFrame = base
			* CF(c.at + V(0.21 * settle, hop - 0.12 * settle, -c.side * 0.73 * settle))
			* A(0.15 + c.rot * 0.24, c.rot + settle * 0.9, -0.08)
	end
end
return Fault
