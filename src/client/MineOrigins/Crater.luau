-- Animate the bedrock surface itself. The same shared vertices begin as a
-- rocky plain, lift when the pressure front reaches them and settle as a bowl.
local P = require(script.Parent.Props)
local V = Vector3.new
local ease, rgb = P.ease, Color3.fromHex
local Bed = {}
Bed.__index = Bed
Bed.coverHeight = 35.5
local bands = { 0, 0.18, 0.37, 0.61, 0.82, 1, 1.62 }
local depths = { -4.2, -4.1, -3, -0.9, 2.55, 0, 0 }
local tones = { "5C5157", "705F61", "766361", "856D64", "756562", "82716D" }

function Bed.ground(r, a)
	local jitter = 1 + 0.065 * math.sin(a * 3) + 0.027 * math.cos(a * 7)
	local taper = 1 + (jitter - 1) * (1 - ease(r, 0.78, 1))
	return V(math.cos(a) * r * 34 * taper, 0.15 + 0.67 * math.sin(3 * a) * r + r * r, math.sin(a) * r * 29 * taper)
end

local function face(parent, a, b, c, ink)
	local v = { a, b, c }
	local ab, ac, bc = (a.at - b.at).Magnitude, (a.at - c.at).Magnitude, (b.at - c.at).Magnitude
	if ab > ac and ab > bc then
		v = { c, b, a }
	elseif ac > bc then
		v = { b, a, c }
	end
	local pieces = {}
	for i = 1, 2 do
		pieces[i] = P.part(parent, "Moving basalt plate", Vector3.one, CFrame.identity, rgb("786968"), "WedgePart")
	end
	return { a = v[1], b = v[2], c = v[3], pieces = pieces, tint = ink }
end

function Bed.new(parent)
	local self = setmetatable({ root = P.model(parent, "Excavated impact basin"), knots = {}, faces = {} }, Bed)
	self.inner = P.model(self.root, "Intact bedrock over the fault")
	self.edge = {}
	local rim = {}
	for i = 0, 31 do
		local angle = i * math.pi / 16
		local radial = {}
		for j, r in bands do
			local at = Bed.ground(r, angle)
			local heave = if j == #bands then 0 else 0.9 + 2.3 * r
			local h = if j == #bands then 0 else depths[j] + 0.45 * math.sin(5 * angle + j) * r
			local cover = Bed.coverHeight * (1 - ease(r, 0.22, 1.62))
			local node = {
				at = at,
				cover = cover,
				off = h,
				wave = heave,
				start = 0.23 * r + 0.016 * math.sin(angle * 3) * r,
				point = at,
			}
			table.insert(self.knots, node)
			radial[j] = node
		end
		rim[i + 1] = radial
		self.edge[i + 1] = radial[4].at + V(0, radial[4].off, 0)
	end
	for i, one in rim do
		local next = rim[i % #rim + 1]
		for j = 1, #bands - 1 do
			local ink = rgb(tones[j])
			table.insert(
				self.faces,
				face(if j <= 3 then self.inner else self.root, one[j], one[j + 1], next[j + 1], ink)
			)
			if j > 1 then
				table.insert(
					self.faces,
					face(if j <= 3 then self.inner else self.root, one[j], next[j + 1], next[j], ink)
				)
			end
		end
	end
	return self
end

-- Read the exact final triangle at a point so both lips meet the basin.
function Bed:heightAt(x, z)
	for _, tri in self.faces do
		local a, b, c = tri.a, tri.b, tri.c
		local u, v = b.at - a.at, c.at - a.at
		local det = u.X * v.Z - u.Z * v.X
		if math.abs(det) > 0.0001 then
			local px, pz = x - a.at.X, z - a.at.Z
			local i, j = (px * v.Z - pz * v.X) / det, (u.X * pz - u.Z * px) / det
			if i >= -0.0002 and j >= -0.0002 and i + j <= 1.0002 then
				return (1 - i - j) * (a.at.Y + a.off) + i * (b.at.Y + b.off) + j * (c.at.Y + c.off)
			end
		end
	end
	return -3.9
end

-- The upright cap shears, catches on a lower shelf, then gives way.
-- The light source uses the same falling contact height as the rock.
function Bed.collapse(t)
	return 0.39 * ease(t, 0.085, 0.18) + 0.46 * ease(t, 0.225, 0.33) + 0.15 * ease(t, 0.365, 0.49)
end

function Bed.contactHeight(t)
	return -3.8 + (Bed.coverHeight + 3.8) * (1 - Bed.collapse(t))
end

function Bed:draw(age, base)
	local time = math.clamp(age, -0.1, 1.0)
	if time == self.last then
		return
	end
	self.last = time
	for _, node in self.knots do
		local t = time - node.start
		local u = Bed.collapse(t)
		local peak = math.sin(math.pi * ease(t, 0, 0.37))
		node.point = node.at + V(0, node.cover * (1 - u) + node.wave * peak + node.off * u, 0)
	end
	for _, tri in self.faces do
		local a, b, c = tri.a.point, tri.b.point, tri.c.point
		local ab, ac, bc = b - a, c - a, c - b
		local right, back = ac:Cross(ab).Unit, bc.Unit
		local up = back:Cross(right)
		local height = math.abs(ab:Dot(up))
		local u = ease(time, tri.a.start, tri.a.start + 0.55)
		local tint = rgb("A6937C"):Lerp(tri.tint, u)
		for j, point in { b, c } do
			local sign = if j == 1 then 1 else -1
			local part = tri.pieces[j]
			local span = math.abs((point - a):Dot(back))
			part.Size = V(0.028, height, math.max(0.025, span))
			part.CFrame = base * CFrame.fromMatrix((a + point) * 0.5, right * sign, up, back * sign)
			part.Color = tint
		end
	end
end

return Bed
