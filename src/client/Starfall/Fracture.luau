-- The piece of the working face the player breaks. Real slabs fill a real hole.
-- Behind them is a pocket of the star's crystal that was there all along.
--
-- Local space: origin on the face where the steel lands, +Z out of the rock.
local S = require(script.Parent.Scenery)
local Deposit = require(script.Parent.StarDeposit)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local M = Enum.Material
local Fracture = {}
Fracture.__index = Fracture

local stone = { "5B5F6C", "656977", "6E7281", "555A67", "61606F" }
local inner = { "2A2436", "342A44", "241F30", "3A2E4C" }
local rind = 0.62

-- Angles in degrees. Corners of the wall panel are included so the skin closes.
local function outline(low, high)
	local rng = Random.new(914)
	local rim = {}
	local count = 14
	for i = 1, count do
		local a = (i - 1) / count * math.pi * 2 + rng:NextNumber(-0.10, 0.10)
		local r = rng:NextNumber(1.95, 2.45)
		rim[i] = V(math.cos(a) * r * 1.02, math.sin(a) * r, 0)
	end
	-- Where a ray from the middle leaves the panel.
	local edge = {}
	for i, p in rim do
		local d = p.Unit
		local t = math.huge
		if d.X > 0.001 then t = math.min(t, high.X / d.X) elseif d.X < -0.001 then t = math.min(t, low.X / d.X) end
		if d.Y > 0.001 then t = math.min(t, high.Y / d.Y) elseif d.Y < -0.001 then t = math.min(t, low.Y / d.Y) end
		edge[i] = d * t
	end
	return rim, edge
end

function Fracture.new(low, high)
	local wall, pocket = S.group("Face round the pocket"), S.group("Star pocket")
	local rim, edge = outline(low, high)
	local n = #rim
	local corners = { V(high.X, high.Y, 0), V(low.X, high.Y, 0), V(low.X, low.Y, 0), V(high.X, low.Y, 0) }
	for i = 1, n do
		local j = i % n + 1
		local tone = "62656F"
		S.facet(wall, "Face", rim[i], rim[j], edge[i], tone)
		S.facet(wall, "Face", rim[j], edge[j], edge[i], tone)
		-- A panel corner that falls between two rays.
		for _, c in corners do
			local a0, a1, a = math.atan2(edge[i].Y, edge[i].X), math.atan2(edge[j].Y, edge[j].X), math.atan2(c.Y, c.X)
			local function between(x) local span = (a1 - a0) % (2 * math.pi) return (x - a0) % (2 * math.pi) < span end
			if between(a) and (c - edge[i]).Magnitude > 0.02 and (c - edge[j]).Magnitude > 0.02 then
				S.facet(wall, "Face", edge[i], edge[j], c, tone)
			end
		end
	end
	for _, p in wall:GetDescendants() do
		if p:IsA("BasePart") then p.CastShadow = false end
	end
	-- Pocket walls: the broken rind, a belly, then a closed back.
	local function ring(k, z, jitter)
		local r = {}
		for i, p in rim do
			r[i] = V(p.X * k, p.Y * k, z) + V(0, 0, jitter * math.sin(i * 2.3))
		end
		return r
	end
	local rings = { ring(1, 0, 0), ring(1.02, -rind, 0.05), ring(1.28, -1.6, 0.18), ring(1.12, -3.1, 0.25), ring(0.55, -4.3, 0.2) }
	for k = 2, #rings do
		for i = 1, n do
			local j = i % n + 1
			local tone = if k == 2 then stone[(i + k) % #stone + 1] else inner[(i * 2 + k) % #inner + 1]
			S.facet(pocket, "Pocket wall", rings[k - 1][i], rings[k - 1][j], rings[k][i], tone)
			S.facet(pocket, "Pocket wall", rings[k - 1][j], rings[k][j], rings[k][i], tone)
		end
	end
	local back = V(0, 0, -4.6)
	for i = 1, n do
		S.facet(pocket, "Pocket wall", rings[#rings][i], rings[#rings][i % n + 1], back, inner[i % #inner + 1])
	end
	-- Crystals line it and point at whoever opens it.
	local rng = Random.new(77)
	for i = 1, 26 do
		local a = i * 2.39996
		local z = -rng:NextNumber(0.9, 3.6)
		local k = if z > -1.8 then 1.22 elseif z > -3.1 then 1.12 else 0.7
		local p = V(math.cos(a) * 2.2 * k, math.sin(a) * 2.2 * k, z)
		-- Near the mouth they lean out with the opening and stay out of the sightline.
		local near = z > -2.5
		local inward = if near then (V(p.X * 0.55, p.Y * 0.55, z + 2.6) - p).Unit else (V(0, 0, z + 0.9) - p).Unit
		local at = CFrame.lookAt(p, p + inward) * A(-math.pi / 2, 0, 0)
		Deposit.crystal(pocket, at, if near then rng:NextNumber(0.35, 0.6) else rng:NextNumber(0.5, 1.1), rng:NextNumber(0.14, 0.28), 0.4, true)
	end
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local r = if i == 7 then 0 else 0.75
		Deposit.crystal(pocket, CF(math.cos(a) * r, math.sin(a) * r, -4.4) * A(math.pi / 2 + 0.25 * math.sin(a), 0, 0.25 * math.cos(a)),
			rng:NextNumber(1.0, 1.9), rng:NextNumber(0.24, 0.42), 0.3, true)
	end
	local pin = S.part(pocket, "Pocket light", CF(0, 0.1, -1.6), Vector3.one * 0.05, "FFFFFF")
	pin.Transparency = 1

	-- The slabs. An inner ring of wedges and an outer ring of blocks, each one
	-- an extruded piece with its own broken sides.
	local slabs, mid = {}, {}
	for i = 1, n do
		mid[i] = rim[i] * (0.46 + 0.10 * math.sin(i * 1.9))
	end
	local heart = V(0.10, -0.08, 0)
	local function slab(points, layer, index)
		local model = S.group("Slab")
		local c = Vector3.zero
		for _, p in points do c += p end
		c /= #points
		local front, rear = {}, {}
		for k, p in points do
			front[k], rear[k] = p, c + (p - c) * 0.93 + V(0, 0, -rind)
		end
		local tone = "62656F"
		for k = 2, #points - 1 do
			S.facet(model, "Slab face", front[1], front[k], front[k + 1], tone, M.SmoothPlastic)
			S.facet(model, "Slab back", rear[1], rear[k], rear[k + 1], "3A3146")
		end
		for k = 1, #points do
			local q = k % #points + 1
			S.facet(model, "Slab side", front[k], front[q], rear[k], "494655")
			S.facet(model, "Slab side", front[q], rear[q], rear[k], "403C4C")
		end
		-- Violet clings to the back of each piece.
		S.strut(model, "Violet rind", rear[1]:Lerp(rear[2], 0.2) + V(0, 0, -0.02), rear[math.min(3, #rear)]:Lerp(rear[2], 0.3) + V(0, 0, -0.02), 0.12, 0.05, "8E5FE0", M.Neon)
		local core = S.part(model, "Datum", CF(c), Vector3.one * 0.02, "FFFFFF")
		core.Transparency, model.PrimaryPart = 1, core
		local seed = Random.new(index * 37 + layer * 11)
		table.insert(slabs, {
			model = model, rest = c, layer = layer,
			delay = if layer == 1 then 12 + (index % 3) else 14 + (index * 5) % 9,
			velocity = V(c.X * 1.1 + seed:NextNumber(-0.8, 0.8), seed:NextNumber(0.6, 2.4) + c.Y * 0.5, seed:NextNumber(3.6, 6.6)),
			spin = V(seed:NextNumber(-4, 4), seed:NextNumber(-4, 4), seed:NextNumber(-2.6, 2.6)),
			nudge = seed:NextNumber(0.05, 0.14), clings = false,
		})
	end
	for i = 1, n, 2 do
		local j, k = i % n + 1, (i + 1) % n + 1
		slab({ heart, mid[i], mid[j], mid[k] }, 1, i)
	end
	for i = 1, n do
		local j = i % n + 1
		slab({ mid[i], rim[i], rim[j], mid[j] }, 2, i)
	end
	-- Light in the cracks, ahead of the break.
	local cracks = {}
	local function crack(a, b, at)
		local p = S.strut(pocket, "Crack", a + V(0, 0, 0.15), b + V(0, 0, 0.15), 0.075, 0.03, "E6D4FF", M.Neon)
		p.CastShadow, p.Transparency = false, 1
		table.insert(cracks, { part = p, at = at })
	end
	for i = 1, n do
		local j = i % n + 1
		if i % 2 == 1 then crack(heart, mid[i], 1 + (i % 4) * 0.5) end
		crack(mid[i], rim[i], 4 + (i * 3) % 5)
		crack(mid[i], mid[j], 3 + (i * 5) % 4)
		crack(rim[i], rim[j], 8 + (i * 2) % 5)
	end
	-- Shafts of light through the broken face.
	local shafts = {}
	for i = 1, 12 do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = pin, pin
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1, beam.FaceCamera, beam.Segments = a0, a1, true, 1
		beam.LightEmission, beam.LightInfluence, beam.Width0, beam.Width1 = 1, 0, 0.25, 1.9
		beam.Color = ColorSequence.new(Color3.fromHex("EADDFF"), Color3.fromHex("7C4FE0"))
		beam.Enabled, beam.Parent = false, pin
		local a = i * 2.39996
		table.insert(shafts, { beam = beam, far = a1, dir = V(math.cos(a) * 0.62, math.sin(a) * 0.5, 1).Unit, seed = i })
	end
	return setmetatable({
		wall = wall, pocket = pocket, slabs = slabs, cracks = cracks, shafts = shafts,
		light = S.light(pin, "A673FF", 26, 0), pin = pin,
	}, Fracture)
end

function Fracture:place(at)
	self.at = at
	self.wall:PivotTo(at)
	self.pocket:PivotTo(at)
	for _, s in self.slabs do
		s.model:PivotTo(at * CF(s.rest))
	end
end

-- Age is in exposures since the steel landed. Negative is the unbroken face.
function Fracture:draw(parent, age, floorY, motion, hush)
	self.wall.Parent = parent
	self.pocket.Parent = parent
	local open = S.ease(age, 10, 24)
	for _, s in self.slabs do
		local t = math.max(0, age - s.delay) / 24
		local gone = not s.clings and t > 1.1
		s.model.Parent = if parent and not gone then parent else nil
		if parent and not gone then
			local lift = if age <= 0 then 0 else s.nudge * S.ease(age, 2 + s.layer * 2, 9 + s.layer * 2)
			local shake = if motion and age > 0 and age < s.delay then 0.025 * math.sin(age * 3.1 + s.rest.X * 5) else 0
			local pose
			if s.clings then
				pose = CF(s.rest + V(0, 0, lift + 0.10 * open)) * A(0.16 * open, -0.12 * open, 0)
			else
				local p = s.rest + V(shake, shake * 0.6, lift) + s.velocity * t - V(0, 13 * t * t, 0)
				pose = CF(p) * A(s.spin.X * t, s.spin.Y * t, s.spin.Z * t)
			end
			local world = self.at * pose
			if floorY and world.Y < floorY + 0.35 then
				world = CF(world.X, floorY + 0.35, world.Z) * world.Rotation
			end
			if s.pose ~= world then
				s.model:PivotTo(world)
				s.pose = world
			end
		end
	end
	if not parent then
		return
	end
	for _, c in self.cracks do
		local on = age >= c.at and age < 16
		c.part.Transparency = if on then S.ease(age, 11, 16) else 1
	end
	local leak = if age < 0 then 0 else 0.35 * S.ease(age, 2, 10) + 0.65 * open
	self.light.Brightness = 1.5 * leak
	for _, s in self.shafts do
		s.beam.Enabled = motion and leak > 0.02 and not hush
		if s.beam.Enabled then
			local reach = 2 + 8 * leak
			s.far.Position = s.dir * reach
			s.beam.Transparency = NumberSequence.new(math.clamp(1 - leak * (0.20 + 0.07 * math.sin(age / 5 + s.seed * 1.9)), 0, 1), 1)
		end
	end
end

function Fracture:Destroy()
	self.wall:Destroy()
	self.pocket:Destroy()
	for _, s in self.slabs do
		s.model:Destroy()
	end
end

return Fracture
