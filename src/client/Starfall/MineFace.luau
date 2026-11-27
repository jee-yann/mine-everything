-- The working face, deep in the present-day mine. The miner's clip is solved
-- first and the rock is built around the point where the steel really lands.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local Acting = require(script.Parent.Acting)
local Avatar = require(script.Parent.CinematicAvatar)
local Debris = require(script.Parent.Debris)
local Fracture = require(script.Parent.Fracture)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local M = Enum.Material
local Face = {}
Face.__index = Face

-- Key poses around a blow. Hips start the turn, then torso, arm and wrist.
local function blow(c, heavy)
	local k = if heavy then 1 else 0.86
	return {
		{ c - 17, {
			Body = { 0, -0.10, 0.12 }, Turn = { 0, -10, 0 }, Waist = { -5, -8, 0 }, Neck = { -3, 14, 0 },
			RightShoulder = { 46, 0, 12 }, RightElbow = { 42 }, RightWrist = { 0 },
			LeftShoulder = { 30, 0, -14 }, LeftElbow = { 44 },
			LeftFoot = { -0.10, 0, -0.18 }, LeftFootTurn = { 0, 8 },
			RightFoot = { 0.16, 0, 0.42 }, RightFootTurn = { 0, -26 },
		} },
		{ c - 7, {
			Body = { 0.12, -0.02, 0.36 }, Turn = { 2, -24 * k, 0 }, Waist = { 11, -30 * k, -3 }, Neck = { 2, 44 * k, 0 },
			RightShoulder = { 162 * k, 8, 16 }, RightElbow = { 66 }, RightWrist = { 22 },
			LeftShoulder = { 66, 0, -6 }, LeftElbow = { 22 },
			LeftFoot = { -0.10, 0.10, -0.30 }, LeftFootTurn = { -8, 8 },
		}, "settle" },
		{ c - 5, {
			Body = { 0.10, -0.04, 0.26 }, Turn = { 0, -18 * k, 0 }, Waist = { 10, -32 * k, -3 },
			RightShoulder = { 168 * k, 8, 16 }, RightElbow = { 74 }, RightWrist = { 28 },
			LeftShoulder = { 60, 0, -6 }, LeftFoot = { -0.10, 0.04, -0.62 }, LeftFootTurn = { 6, 8 },
		} },
		{ c, {
			Body = { -0.04, -0.26 * k, -0.44 * k }, Turn = { -4, 9, 0 }, Waist = { -17 * k, 20, 4 }, Neck = { 9, -20, 0 },
			RightShoulder = { 78, -4, 4 }, RightElbow = { 10 }, RightWrist = { -4 },
			LeftShoulder = { -34, 0, -20 }, LeftElbow = { 52 },
			LeftFoot = { -0.12, 0, -0.72 }, LeftFootTurn = { 0, 8 },
		}, "hit" },
		{ c + 2, {
			Body = { -0.05, -0.31 * k, -0.46 * k }, Waist = { -19 * k, 22, 5 }, RightShoulder = { 74, -4, 4 },
			RightElbow = { 13 }, LeftShoulder = { -38, 0, -20 }, Neck = { 10, -21, 0 },
		}, "settle" },
		{ c + 6, {
			Body = { -0.02, -0.22, -0.34 }, Turn = { -2, 4, 0 }, Waist = { -11, 13, 2 }, RightShoulder = { 82, 0, 8 },
			RightElbow = { 28 }, RightWrist = { 4 }, LeftShoulder = { -10, 0, -16 }, Neck = { 4, -10, 0 },
		} },
	}
end

local keys = {
	{ F.outside - 1, {
		Body = { 0.06, -0.10, 0.50 }, Turn = { -3, -6, 0 }, Waist = { -7, -4, 0 }, Neck = { 5, 8, 3 },
		RightShoulder = { 13, 0, 9 }, RightElbow = { 18 }, RightWrist = { 0 },
		LeftShoulder = { 30, 0, -12 }, LeftElbow = { 44 }, LeftFoot = { -0.1, 0, 0.5 }, RightFoot = { 0.2, 0, 1.15 },
	} },
}
for _, key in blow(F.firstHit, false) do table.insert(keys, key) end
for _, key in blow(F.secondHit, true) do table.insert(keys, key) end
-- The rock answers. A flinch, one step back, the free hand up against the light,
-- and then the arm comes down because it is beautiful.
for _, key in {
	{ F.secondHit + 11, {
		Body = { 0.05, -0.12, 0.05 }, Turn = { 4, -10, 0 }, Waist = { 8, -8, 0 }, Neck = { 6, 6, -4 },
		RightShoulder = { 40, 0, 16 }, RightElbow = { 40 }, LeftShoulder = { -14, 0, -26 }, LeftElbow = { 40 },
		LeftFoot = { -0.10, 0.10, -0.3 }, RightFoot = { 0.16, 0, 0.42 },
	}, "settle" },
	{ F.reaction + 2, {
		Body = { 0.08, -0.06, 0.72 }, Turn = { 5, -8, 0 }, Waist = { 9, -10, 0 }, Neck = { 2, 12, -5 },
		RightShoulder = { 22, 0, 12 }, RightElbow = { 28 }, LeftShoulder = { 96, 0, -34 }, LeftElbow = { 104 },
		LeftFoot = { -0.10, 0, 0.5 }, RightFoot = { 0.2, 0, 1.15 },
	}, "settle" },
	{ F.reaction + 13, {
		Body = { 0.08, -0.05, 0.75 }, Turn = { 4, -8, 0 }, Waist = { 8, -10, 0 }, Neck = { 0, 12, -5 },
		LeftShoulder = { 93, 0, -34 }, LeftElbow = { 100 },
	} },
	{ F.reaction + 27, {
		Body = { 0.06, -0.10, 0.56 }, Turn = { -2, -6, 0 }, Waist = { -6, -4, 0 }, Neck = { 4, 8, 3 },
		RightShoulder = { 14, 0, 9 }, RightElbow = { 18 }, LeftShoulder = { 34, 0, -10 }, LeftElbow = { 46 },
	} },
} do table.insert(keys, key) end
-- Overlap: the body leads, the hand and the head finish a little later.
local clip = Acting.clip(keys, { RightWrist = 1, LeftElbow = 1, LeftWrist = 2 })

-- The vein repeats the fork that survived the impact.
local vein = {
	{ { 0, 0 }, { 0.34, 0.42 }, { 0.22, 0.86 }, { 0.72, 1.38 }, { 0.62, 1.83 }, { 1.18, 2.44 }, { 1.12, 2.92 }, { 1.62, 3.6 } },
	{ { 0, 0 }, { -0.42, 0.30 }, { -0.66, 0.82 }, { -1.28, 1.06 }, { -1.50, 1.60 }, { -2.22, 1.94 }, { -2.5, 2.5 } },
	{ { 0, 0 }, { -0.12, -0.52 }, { 0.22, -0.96 }, { 0.04, -1.52 }, { 0.36, -2.1 }, { 0.22, -2.7 } },
	{ { 0.22, 0.86 }, { -0.1, 1.25 }, { -0.02, 1.72 }, { -0.36, 2.2 } },
	{ { 0.62, 1.83 }, { 1.2, 1.72 }, { 1.62, 1.98 } },
	{ { -1.28, 1.06 }, { -1.72, 0.72 }, { -2.3, 0.78 } },
	{ { 0.22, -0.96 }, { 0.82, -1.12 }, { 1.12, -1.6 } },
}

local function ribbon(root, at, path, delay, list)
	local total = #path
	for i = 2, total do
		local a, b = path[i - 1], path[i]
		local wa = 0.055 * (1 - (i - 2) / total) + 0.018
		local wb = 0.055 * (1 - (i - 1) / total) + 0.008
		local dir = Vector2.new(b[1] - a[1], b[2] - a[2]).Unit
		local n = Vector2.new(-dir.Y, dir.X)
		local function p(q, w, z) return at * V(q[1] + n.X * w, q[2] + n.Y * w, z) end
		for layer, k in { 1.9, 1 } do
			local z = 0.03 + layer * 0.022
			local tint = if layer == 1 then "4A22A8" else "B08BE6"
			local before = #root:GetChildren()
			S.facet(root, "Vein", p(a, wa * k, z), p(a, -wa * k, z), p(b, wb * k, z), tint, M.Neon)
			S.facet(root, "Vein", p(a, -wa * k, z), p(b, -wb * k, z), p(b, wb * k, z), tint, M.Neon)
			local children = root:GetChildren()
			for j = before + 1, #children do
				table.insert(list, { part = children[j], at = delay + i, tint = Color3.fromHex(tint) })
			end
		end
	end
end

-- The island's look down here too: studded plastic blocks in lighter stone, earth underfoot.
local stone = { "8A8F9C", "949AA8", "7F8593", "9AA0AC", "868B97" }
local earth = { "9C6B4E", "8E6047", "A57452", "875A42" }
local function studs(p)
	p.Material = M.Plastic
	p.TopSurface, p.BottomSurface, p.FrontSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Studs, Enum.SurfaceType.Studs
	p.BackSurface, p.LeftSurface, p.RightSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Studs, Enum.SurfaceType.Studs
	return p
end

local function set(root)
	local rng = Random.new(5531)
	local function block(x, y, z, depth, palette)
		local p = studs(S.part(root, "Mine block", CF(x, y, z), V(5.94, 5.94, depth), palette[rng:NextInteger(1, #palette)]))
		p.CastShadow = false
		return p
	end
	-- The face is a wall of the same six-stud cells the player digs.
	for ix = -3, 3 do
		for iy = 0, 2 do
			local out = if ix == 0 and iy < 2 then 0 elseif math.abs(ix) == 1 then rng:NextNumber(0.02, 0.5) else rng:NextNumber(-1.2, 0.7)
			
			if ix ~= 0 or iy == 2 then
				block(ix * 6, iy * 6 + 3, -3 + out, 6, stone).CastShadow = true
			end
		end
	end
	-- Ore in the surrounding cells says this is a mine worth working.
	for _, o in { { -8.9, 2.2, 0.35, "D98A4B" }, { -9.4, 1.0, 0.4, "E29A58" }, { 6.6, 4.6, 0.3, "2B2D36" }, { 7.9, 3.4, 0.35, "33343F" },
		{ -7.8, 8.4, 0.3, "E5C04F" }, { 5.2, 8.9, 0.2, "D98A4B" }, { 4.8, 1.1, 0.35, "2B2D36" } } do
		for j = 1, 3 do
			local size = rng:NextNumber(0.35, 0.7)
			S.part(root, "Ore piece", CF(o[1] + rng:NextNumber(-0.6, 0.6), o[2] + rng:NextNumber(-0.5, 0.5), o[3])
				* A(rng:NextNumber(0, 1), rng:NextNumber(0, 1), rng:NextNumber(0, 3)), V(size, size, size * 0.9), o[4])
		end
	end
	for ix = -3, 3 do
		for iz = 0, 4 do
			local p = studs(S.part(root, "Dig floor", CF(ix * 6, -3 + rng:NextNumber(-0.05, 0.05), iz * 6 + 3), V(5.94, 6, 5.94), earth[rng:NextInteger(1, #earth)]))
			p.CastShadow = false
		end
	end
	for iz = 0, 4 do
		for iy = 0, 2 do
			for _, side in { -1, 1 } do
				local p = studs(S.part(root, "Gallery wall", CF(side * 19.5 + side * rng:NextNumber(-1.2, 0.6), iy * 6 + 3, iz * 6 + 3),
					V(6, 5.94, 5.94), stone[rng:NextInteger(1, #stone)]))
				p.CastShadow = false
			end
		end
	end
	for ix = -3, 3 do
		for iy = 0, 2 do
			block(ix * 6, iy * 6 + 3, 31, 6, stone)
		end
	end
	-- The roof closes the gallery. There is no sky down here.
	studs(S.part(root, "Roof rock", CF(0, 15.6, 14), V(48, 4, 42), "5A5E6C")).CastShadow = false
	local oak, dark = "8B6545", "6B4C35"
	for _, z in { 1.6, 10.5 } do
		for _, x in { -9.6, 9.6 } do
			S.part(root, "Pit prop", CF(x, 6, z), V(0.95, 12, 0.95), oak, M.Wood)
			S.strut(root, "Knee brace", V(x, 9.2, z), V(x - math.sign(x) * 2.4, 11.7, z), 0.55, 0.55, dark, M.Wood)
			S.part(root, "Iron shoe", CF(x, 0.35, z), V(1.2, 0.7, 1.2), "3A424A", M.Metal)
		end
		S.part(root, "Cap beam", CF(0, 12.2, z), V(22, 1.05, 1.15), oak, M.Wood)
	end
	for _, x in { -6.2, 0.4, 6.8 } do
		S.part(root, "Lagging", CF(x, 12.9, 6), V(2.1, 0.35, 13), dark, M.Wood).CastShadow = false
	end
	-- Lanterns on the props, a loaded tub and a crate give the space scale.
	local lamps = {}
	for _, at in { V(-9.6, 7.2, 2.35), V(9.6, 7.2, 2.35), V(-9.6, 7.2, 11.2) } do
		S.part(root, "Lamp bracket", CF(at + V(0, 0.75, -0.1)), V(0.14, 0.14, 0.9), "3A424A", M.Metal)
		S.part(root, "Lamp cap", CF(at + V(0, 0.48, 0.25)), V(0.62, 0.16, 0.62), "3A424A", M.Metal)
		local glass = S.part(root, "Lamp glass", CF(at + V(0, 0.05, 0.25)), V(0.46, 0.7, 0.46), "FFDC96", M.Neon)
		S.part(root, "Lamp base", CF(at + V(0, -0.36, 0.25)), V(0.6, 0.14, 0.6), "3A424A", M.Metal)
		table.insert(lamps, S.light(glass, "FFC27A", 11, 0.55))
	end
	local tub = CF(6.6, 0, 6.2) * A(0, math.rad(24), 0)
	S.part(root, "Ore tub", tub * CF(0, 1.5, 0), V(3.1, 1.7, 4.2), "4F5C66", M.Metal)
	S.part(root, "Tub rim", tub * CF(0, 2.36, 0), V(3.4, 0.2, 4.5), "6A7780", M.Metal)
	for _, x in { -1.4, 1.4 } do
		for _, z in { -1.35, 1.35 } do
			local wheel = S.part(root, "Wheel", tub * CF(x, 0.5, z), V(0.25, 1, 1), "2C343B", M.Metal)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	for _ = 1, 12 do
		local s = rng:NextNumber(0.6, 1.05)
		S.part(root, "Loaded ore", tub * CF(rng:NextNumber(-1.1, 1.1), 2.45 + rng:NextNumber(0, 0.35), rng:NextNumber(-1.6, 1.6))
			* A(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0), V(s, s, s), stone[rng:NextInteger(1, #stone)])
	end
	for i = 0, 1 do
		S.part(root, "Rail", CF(5.2 + i * 2.6, 0.12, 14), V(0.2, 0.24, 22), "5C666D", M.Metal)
	end
	for _ = 1, 16 do
		local s = rng:NextNumber(0.25, 0.8)
		S.part(root, "Spoil", CF(rng:NextNumber(-6, 5), s * 0.3, rng:NextNumber(0.4, 1.8)) * A(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0),
			V(s, s * 0.8, s), stone[rng:NextInteger(1, #stone)])
	end
	-- A little cold fill from the shaft behind. The key is the shaft itself: see
	-- `Daylight:scene`.
	local rig = S.part(root, "Shaft light", CFrame.lookAt(V(-7, 13, 21), V(1, 2, 1)), Vector3.one * 0.2, "FFFFFF")
	rig.Transparency = 1
	local key = Instance.new("SpotLight")
	key.Face, key.Angle, key.Range, key.Brightness, key.Shadows = Enum.NormalId.Front, 60, 44, 0.35, false
	key.Color, key.Parent = Color3.fromHex("7FA6E8"), rig
	return lamps, key
end

function Face.tipOf(rig, handle, toward)
	local index = rig.indices[handle]
	local best, score
	for _, item in handle:GetChildren() do
		if item:IsA("Attachment") and math.abs(item.Position.X) > 0.2 then
			local at = rig.world[index] * item.Position
			local s = at:Dot(toward)
			if not score or s > score then best, score = item.Position, s end
		end
	end
	return best or V(-0.91, 0.76, 0)
end

function Face.new(stage, place, sun)
	-- The low sun is the key light. Turn the whole set to face it, over the
	-- miner's left shoulder and onto the rock.
	local want = V(-0.80, 0, 0.60)
	local yaw = math.atan2(sun.X, sun.Z) - math.atan2(want.X, want.Z)
	local at = CF(place) * A(0, yaw, 0)
	local root = S.group("Working face")
	local lamps, key = set(root)
	root:PivotTo(at)
	local source = script.Parent.CoveCast.Miner
	local rig = Avatar.new(source)
	local self = setmetatable({
		stage = stage, root = root, at = at, rig = rig, lamps = lamps, key = key,
		handle = rig.model["Pick handle"], unit = 1,
	}, Face)
	self.stand = at * CF(0, rig.stand, 3)
	local base = Acting.perform(rig, clip, F.secondHit, self.stand, 1)
	rig:place(base)
	self.tip = Face.tipOf(rig, self.handle, at.LookVector)
	local hit = at:PointToObjectSpace(self:tipAt())
	-- Walk the mark up to the rock so the steel stops on the surface.
	self.stand = at * CF(-hit.X, rig.stand, 3 + (0.02 - hit.Z))
	base = Acting.perform(rig, clip, F.secondHit, self.stand, 1)
	rig:place(base)
	self.point = at:PointToObjectSpace(self:tipAt())
	self.contact = at * CF(self.point.X, self.point.Y, 0)
	local glow = S.group("Star vein")
	self.veins = {}
	for i, path in vein do
		ribbon(glow, self.contact, path, if i <= 3 then 0 else 5, self.veins)
	end
	self.glow = glow
	local lit = S.part(glow, "Vein light", self.contact * CF(0, 0.1, 0.25), Vector3.one * 0.05, "FFFFFF")
	lit.Transparency = 1
	self.light = S.light(lit, "A86BFF", 15, 0)
	-- A bite in the rock on the first blow, so the second one means something.
	self.scar = S.group("Pick scar")
	local c = self.contact
	for i = 0, 5 do
		local a, b = i * 1.047 + 0.3, (i + 1) * 1.047 + 0.3
		local ra, rb = 0.16 + 0.08 * math.sin(i * 2.3), 0.16 + 0.08 * math.sin((i + 1) * 2.3)
		S.facet(self.scar, "Scar", c * V(0, 0, 0.012), c * V(math.cos(a) * ra, math.sin(a) * ra, 0.02),
			c * V(math.cos(b) * rb, math.sin(b) * rb, 0.02), if i % 2 == 0 then "3B3F4B" else "464A57")
	end
	self.rays = {}
	for i = 1, 9 do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = lit, lit
		local ray = Instance.new("Beam")
		ray.Attachment0, ray.Attachment1, ray.FaceCamera = a0, a1, true
		ray.LightEmission, ray.LightInfluence, ray.Segments = 1, 0, 1
		ray.Color = ColorSequence.new(Color3.fromHex("D9B8FF"), Color3.fromHex("7C3FE0"))
		ray.Width0, ray.Width1, ray.Enabled, ray.Parent = 0.15, 1.5, false, lit
		local angle = i * 2.399
		table.insert(self.rays, { ray = ray, far = a1, dir = V(math.cos(angle) * 0.75, math.sin(angle) * 0.6 + 0.1, 1).Unit, seed = i })
	end
	self.chipsA = Debris.new(13, { "8C909C", "70747F", "5B5F6C" }, 41)
	self.chipsB = Debris.new(22, { "8C909C", "70747F", "5B5F6C" }, 42, "C79BFF")
	-- The headlamp lights whatever the miner looks at. This place renders local
	-- lights without shadow maps and on a coarse grid, which loses a spotlight
	-- this close to a wall, so the pool it throws is its own light on the rock.
	local bulb = rig.model:FindFirstChild("Headlamp")
	local face = rig.model.Head.CFrame
	local lens = Instance.new("Attachment")
	lens.CFrame = bulb.CFrame:ToObjectSpace(CFrame.lookAt(bulb.Position, bulb.Position + (face * A(math.rad(-9), 0, 0)).LookVector) * CF(0, 0, -0.2))
	lens.Parent = bulb
	local pool = S.part(nil, "Headlamp pool", at, Vector3.one * 0.05, "FFFFFF")
	pool.Transparency = 1
	local far = Instance.new("Attachment")
	far.Parent = pool
	self.lens, self.pool, self.poolLight = lens, pool, S.light(pool, "FFD894", 8, 0)
	self.haze = Instance.new("Beam")
	self.haze.Attachment0, self.haze.Attachment1, self.haze.FaceCamera, self.haze.Segments = lens, far, true, 1
	self.haze.LightEmission, self.haze.LightInfluence, self.haze.Width0, self.haze.Width1 = 1, 0, 0.3, 2.2
	self.haze.Color, self.haze.Transparency = ColorSequence.new(Color3.fromHex("FFE7B4")), NumberSequence.new(0.88, 1)
	self.haze.Parent = pool
	self.fracture = Fracture.new(V(-3 - self.point.X, -self.point.Y, 0), V(3 - self.point.X, 12 - self.point.Y, 0))
	self.fracture:place(self.contact)
	self.aside = at * CF(-5.0, rig.stand, 4.9) * A(0, math.rad(-38), 0)
	return self
end

function Face:tipAt()
	return self.rig.world[self.rig.indices[self.handle]] * self.tip
end

function Face:ready(active)
	self.root.Parent = if active then self.stage else nil
end

-- How much of the star's light is in the gallery on this exposure. A trace for
-- the miner. Once the player is here it is the brightest thing in the room.
function Face.shine(frame)
	local age = frame - F.secondHit
	if age < 0 then return 0 end
	local burst = S.ease(age, 0, 2) * (1 - 0.62 * S.ease(age, 4, 18))
	local breath = 0.07 * math.sin(age / 5.2) * S.ease(age, 10, 20)
	if frame < F.enter then
		return math.clamp(burst + breath + 0.18 * S.ease(age, 12, 40), 0, 1)
	end
	local opened = S.ease(frame, F.contact2 + 8, F.contact2 + 24)
	return math.clamp(0.50 + breath + 0.5 * opened, 0, 1)
end

-- Later, beside the player: a step back, a hand toward the rock, and eyes on it.
local guide = Acting.clip({
	{ F.enter - 6, {
		Body = { 0, -0.04, 0 }, Turn = { 0, 6, 0 }, Waist = { -2, 4, 0 }, Neck = { 2, -34, 2 },
		RightShoulder = { 14, 0, 10 }, RightElbow = { 22 }, LeftShoulder = { 8, 0, -8 }, LeftElbow = { 20 },
		LeftFoot = { -0.08, 0, 0 }, RightFoot = { 0.1, 0, 0.1 },
	} },
	{ F.enter + 12, { Body = { 0, -0.04, 0.02 }, Waist = { -2, -6, 0 }, Neck = { 3, -40, 2 }, LeftShoulder = { 18, 0, -18 }, LeftElbow = { 60 } } },
	{ F.enter + 22, { Body = { 0.04, -0.05, -0.04 }, Waist = { -4, -14, 0 }, Neck = { 2, -16, 0 }, LeftShoulder = { 78, 0, 26 }, LeftElbow = { 10 } }, "settle" },
	{ F.enter + 36, { Waist = { -4, -13, 0 }, Neck = { 2, -30, 2 }, LeftShoulder = { 74, 0, 25 }, LeftElbow = { 14 } } },
	{ F.strike + 12, { Body = { 0, -0.05, 0.3 }, Waist = { 0, -8, 0 }, Neck = { 0, -24, 0 }, LeftShoulder = { 16, 0, -10 }, LeftElbow = { 30 }, LeftFoot = { -0.08, 0, 0.2 }, RightFoot = { 0.1, 0, 0.42 } } },
	{ F.contact2 - 4, { Body = { 0, -0.06, 0.32 }, Waist = { 0, -8, 0 }, Neck = { 0, -24, 0 }, LeftShoulder = { 18, 0, -10 }, LeftElbow = { 34 } } },
	{ F.contact2 + 12, { Body = { 0.06, -0.14, 0.62 }, Turn = { 6, 8, 0 }, Waist = { 8, 4, 0 }, Neck = { -4, -20, -4 }, LeftShoulder = { 84, 0, -24 }, LeftElbow = { 98 }, RightFoot = { 0.14, 0, 0.8 } }, "settle" },
	{ F.reveal, { Body = { 0.04, -0.08, 0.5 }, Turn = { 2, 6, 0 }, Waist = { 2, 0, 0 }, Neck = { 2, -24, 0 }, LeftShoulder = { 40, 0, -20 }, LeftElbow = { 60 } } },
}, { LeftElbow = 1, Neck = -1 })

function Face:draw(frame, motion)
	local early = frame >= F.dig - 8 and frame < F.outside
	local late = frame >= F.enter and frame < F.reveal
	local active = early or late
	self:ready(active or (frame >= F.dig - 34 and frame < F.dig) or (frame >= F.witness + 12 and frame < F.enter))
	if not active then
		self.rig.model.Parent, self.glow.Parent, self.scar.Parent, self.pool.Parent = nil, nil, nil, nil
		for _, lamp in self.lamps do
			lamp.Brightness = if frame < F.dig then 0.55 else 0
		end
		self.light.Brightness, self.poolLight.Brightness = 0, 0
		self.chipsA:draw(nil, CF(), -1, 1)
		self.chipsB:draw(nil, CF(), -1, 1)
		self.fracture:draw(if self.root.Parent then self.stage else nil, -1, nil, motion)
		return
	end
	local f = if motion then frame elseif early then (if frame < F.secondHit then F.firstHit else F.reaction + 12) else F.strike + 12
	if early then
		self.rig:place(Acting.perform(self.rig, clip, f, self.stand, 1))
	else
		self.rig:place(Acting.perform(self.rig, guide, f, self.aside, 1))
	end
	self.rig:show(self.stage)
	self.scar.Parent = if frame >= F.firstHit and frame - F.contact2 < 8 then self.stage else nil
	local age = frame - F.secondHit
	local blow = frame - F.contact2
	self.glow.Parent = if age >= 0 and blow < 12 then self.stage else nil
	local shine = Face.shine(frame)
	if age >= 0 then
		for _, v in self.veins do
			v.part.Transparency = if age * 1.5 + 1 >= v.at then 0 else 1
			v.part.Color = v.tint:Lerp(Color3.new(1, 1, 1), 0.4 * (1 - S.ease(age, 0, 7)))
		end
	end
	-- A cut to this place gets its lamps a few exposures late. The second visit
	-- brings them up as the player walks in, so there is no step to see.
	local up = if late and motion then S.ease(frame, F.enter + 1, F.enter + 18) else 1
	for _, lamp in self.lamps do
		lamp.Brightness = 0.55 * up
	end
	self.light.Brightness = 1.15 * shine * up * (1 - S.ease(blow, 6, 14))
	-- The beam gutters when the rock jumps, then steadies on what it found.
	local from = self.at:PointToObjectSpace(self.lens.WorldPosition)
	local toward = self.at:VectorToObjectSpace(self.lens.WorldCFrame.LookVector)
	local reach = if toward.Z < -0.05 then math.min(13, (from.Z - 0.25) / -toward.Z) else 13
	self.pool.CFrame = self.at * CF(from + toward * math.max(0.5, reach - 0.9))
	self.pool.Parent, self.haze.Enabled = self.stage, frame < F.crack
	self.poolLight.Brightness = 1.5 * up * (1 - 0.5 * S.ease(age, 0, 2) * (1 - S.ease(age, 5, 16)))
	for _, r in self.rays do
		r.ray.Enabled = age >= 1 and motion and frame < F.outside
		if r.ray.Enabled then
			local length = 6.5 * (1 - math.exp(-age / 6)) * (0.8 + 0.2 * math.sin(age / 7 + r.seed))
			r.far.WorldPosition = self.contact.Position + self.contact:VectorToWorldSpace(r.dir) * length
			r.ray.Transparency = NumberSequence.new(0.74 + 0.2 * S.ease(age, 6, 26), 1)
		end
	end
	local floor = self.at.Position.Y
	self.chipsA:draw(self.stage, self.contact, frame - F.firstHit, 1, floor)
	self.chipsB:draw(self.stage, self.contact, if late then blow else age, if late then 1.3 else 1.1, floor)
	self.fracture:draw(self.stage, if late then blow else -1, floor, motion, frame >= F.inside)
end

local function mix(a, b, u)
	return a + (b - a) * u
end

-- Camera in the set's space. Moving on the first exposure and on the last.
local function glide(frame, a, b, lean)
	local u = math.clamp((frame - a) / (b - a), 0, 1)
	return u + (lean or -0.25) * math.sin(2 * math.pi * u) / (2 * math.pi)
end

function Face:camera(frame, motion)
	local p = self.point
	local head = self.at:PointToObjectSpace(self.rig.model.Head.Position)
	if frame < F.crack then
		-- The same forward line that came through the arch, still travelling.
		local u = if motion then glide(frame, F.dig - 8, F.crack, 0.25) else 0.6
		local jolt = if motion then math.max(0, 1 - math.abs(frame - F.firstHit - 1) / 3) else 0
		return V(mix(-11.6, -8.0, u), mix(2.7, 2.95, u) + 0.05 * jolt, mix(7.2, 5.2, u)), V(mix(0.5, 0.35, u), mix(3.1, 3.38, u), mix(1.7, 1.5, u)), 38, 0
	elseif frame < F.reaction then
		local age = frame - F.secondHit
		local u = if motion then glide(frame, F.crack, F.reaction) else 0.5
		local jolt = if motion and age >= 0 then math.exp(-age / 2.6) * math.cos(age * 2.0) else 0
		return V(p.X - 4.6 + 0.6 * u, p.Y - 0.15 - 0.10 * jolt, 4.1 - 0.5 * u + 0.12 * jolt), V(p.X + 0.45 - 0.2 * u, p.Y + 0.2 + 0.25 * u, 0.5), 40 + 1.0 * jolt, 0.9 * jolt
	end
	local u = if motion then glide(frame, F.reaction, F.outside) else 0.5
	local eye = V(p.X + 1.9 - 0.3 * u, head.Y - 0.30, 0.55 + 0.15 * u)
	return eye, V(head.X - 0.1, head.Y - 0.12, head.Z), 42, 0
end

function Face:Destroy()
	self.rig:destroy()
	self.fracture:Destroy()
	self.root:Destroy()
	self.glow:Destroy()
	self.pool:Destroy()
	self.scar:Destroy()
	self.chipsA:Destroy()
	self.chipsB:Destroy()
end

return Face
