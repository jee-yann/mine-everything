-- The working face, deep in the present-day mine. The miner's clip is solved
-- first and the rock is built around the point where the steel really lands.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local Acting = require(script.Parent.Acting)
local Avatar = require(script.Parent.CinematicAvatar)
local Debris = require(script.Parent.Debris)
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
	{ F.living - 1, {
		Body = { 0.1, 0, 0.95 }, Turn = { 0, -6, 0 }, Waist = { 3, -8, 0 }, Neck = { 2, 10, 2 },
		RightShoulder = { 18, 0, 10 }, RightElbow = { 22 }, RightWrist = { 0 },
		LeftShoulder = { 88, 0, 8 }, LeftElbow = { 78 }, LeftFoot = { -0.1, 0, 0.62 }, RightFoot = { 0.2, 0, 1.15 },
	} },
}
for _, key in blow(F.firstHit, false) do table.insert(keys, key) end
for _, key in blow(F.secondHit, true) do table.insert(keys, key) end
-- The rock answers. A flinch, one step back, the free hand up against the light,
-- and then the arm comes down because it is beautiful.
for _, key in {
	{ F.secondHit + 11, {
		Body = { 0.05, -0.12, 0.05 }, Turn = { 4, -10, 0 }, Waist = { 8, -8, 0 }, Neck = { 6, 6, -4 },
		RightShoulder = { 40, 0, 16 }, RightElbow = { 40 }, LeftShoulder = { 74, 0, -24 }, LeftElbow = { 92 },
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
		local wa = 0.10 * (1 - (i - 2) / total) + 0.025
		local wb = 0.10 * (1 - (i - 1) / total) + 0.010
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

local stone = { "5B5F6C", "656977", "6E7281", "555A67", "61606F" }
local earth = { "8A5E45", "7E553F", "946749", "775039" }

local function set(root)
	local rng = Random.new(5531)
	local function block(x, y, z, depth, palette)
		local p = S.part(root, "Mine block", CF(x, y, z), V(5.94, 5.94, depth), palette[rng:NextInteger(1, #palette)])
		p.CastShadow = false
		return p
	end
	-- The face is a wall of the same six-stud cells the player digs.
	for ix = -3, 3 do
		for iy = 0, 2 do
			local out = if ix == 0 and iy < 2 then 0 else rng:NextNumber(-1.4, 0.7)
			
			block(ix * 6, iy * 6 + 3, -3 + out, 6, stone)
		end
	end
	-- Ore in the surrounding cells says this is a mine worth working.
	for _, o in { { -6.9, 2.2, 0.35, "D98A4B" }, { -5.4, 1.0, 0.4, "E29A58" }, { 6.6, 4.6, 0.3, "2B2D36" }, { 7.9, 3.4, 0.35, "33343F" },
		{ -7.8, 8.4, 0.3, "E5C04F" }, { 5.2, 8.9, 0.2, "D98A4B" }, { 4.8, 1.1, 0.35, "2B2D36" } } do
		for j = 1, 3 do
			local size = rng:NextNumber(0.35, 0.7)
			S.part(root, "Ore piece", CF(o[1] + rng:NextNumber(-0.6, 0.6), o[2] + rng:NextNumber(-0.5, 0.5), o[3])
				* A(rng:NextNumber(0, 1), rng:NextNumber(0, 1), rng:NextNumber(0, 3)), V(size, size, size * 0.9), o[4])
		end
	end
	for ix = -3, 3 do
		for iz = 0, 4 do
			local p = S.part(root, "Dig floor", CF(ix * 6, -3 + rng:NextNumber(-0.05, 0.05), iz * 6 + 3), V(5.94, 6, 5.94), earth[rng:NextInteger(1, #earth)])
			p.CastShadow = false
		end
	end
	for iz = 0, 4 do
		for iy = 0, 2 do
			for _, side in { -1, 1 } do
				local p = S.part(root, "Gallery wall", CF(side * 19.5 + side * rng:NextNumber(-1.2, 0.6), iy * 6 + 3, iz * 6 + 3),
					V(6, 5.94, 5.94), stone[rng:NextInteger(1, #stone)])
				p.CastShadow = false
			end
		end
	end
	for ix = -3, 3 do
		for iy = 0, 2 do
			block(ix * 6, iy * 6 + 3, 31, 6, stone)
		end
	end
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
		table.insert(lamps, S.light(glass, "FFC27A", 22, 0.7))
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
			* A(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0), V(s, s, s), stone[rng:NextInteger(1, #stone)], M.Slate)
	end
	for i = 0, 1 do
		S.part(root, "Rail", CF(5.2 + i * 2.6, 0.12, 14), V(0.2, 0.24, 22), "5C666D", M.Metal)
	end
	for _ = 1, 16 do
		local s = rng:NextNumber(0.25, 0.8)
		S.part(root, "Spoil", CF(rng:NextNumber(-6, 5), s * 0.3, rng:NextNumber(0.4, 1.8)) * A(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0),
			V(s, s * 0.8, s), stone[rng:NextInteger(1, #stone)], M.Slate)
	end
	-- A work lamp out of frame is the key. Local lights are steady on the cut.
	local rig = S.part(root, "Work lamp", CFrame.lookAt(V(-8.5, 9.5, 9.5), V(0.5, 3, 1.5)), Vector3.one * 0.2, "FFFFFF")
	rig.Transparency = 1
	local key = Instance.new("SpotLight")
	key.Face, key.Angle, key.Range, key.Brightness, key.Shadows = Enum.NormalId.Front, 78, 46, 1.7, true
	key.Color, key.Parent = Color3.fromHex("FFE0B8"), rig
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
	self.light = S.light(lit, "A86BFF", 30, 0)
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
	self.headlamp = S.light(rig.model:FindFirstChild("Headlamp"), "FFEBB8", 9, 0.35)
	return self
end

function Face:tipAt()
	return self.rig.world[self.rig.indices[self.handle]] * self.tip
end

function Face:ready(active)
	self.root.Parent = if active then self.stage else nil
end

-- How much of the star's light is in the room on this exposure.
function Face.shine(frame)
	local age = frame - F.secondHit
	if age < 0 then return 0 end
	local burst = S.ease(age, 0, 2) * (1 - 0.45 * S.ease(age, 3, 14))
	local breath = 0.10 * math.sin(age / 5.2)
	return math.clamp(burst + breath * S.ease(age, 10, 20) + 0.25 * S.ease(age, 18, 40), 0, 1)
end

function Face:draw(frame, motion)
	local active = frame >= F.dig and frame < F.living
	self:ready(active or (frame >= F.dig - 34 and frame < F.dig))
	if frame >= F.dig - 11 and frame < F.dig then
		self.rig:place(Acting.perform(self.rig, clip, F.dig, self.stand, 1))
		self.rig:show(self.stage)
		return
	end
	if not active then
		self.rig.model.Parent, self.glow.Parent, self.scar.Parent = nil, nil, nil
		self.chipsA:draw(nil, CF(), -1, 1)
		self.chipsB:draw(nil, CF(), -1, 1)
		return
	end
	local base = Acting.perform(self.rig, clip, frame, self.stand, 1)
	self.rig:place(base)
	self.rig:show(self.stage)
	self.scar.Parent = if frame >= F.firstHit then self.stage else nil
	local age = frame - F.secondHit
	self.glow.Parent = if age >= 0 then self.stage else nil
	local shine = Face.shine(frame)
	if age >= 0 then
		for _, v in self.veins do
			v.part.Transparency = if age * 1.5 + 1 >= v.at then 0 else 1
			v.part.Color = v.tint:Lerp(Color3.new(1, 1, 1), 0.5 * (1 - S.ease(age, 0, 7)))
		end
	end
	self.key.Brightness = 1.7 - 0.7 * shine
	self.light.Brightness = 1.5 * shine
	for _, r in self.rays do
		r.ray.Enabled = age >= 1 and motion
		if r.ray.Enabled then
			local length = 9 * (1 - math.exp(-age / 6)) * (0.8 + 0.2 * math.sin(age / 7 + r.seed))
			r.far.WorldPosition = self.contact.Position + self.contact:VectorToWorldSpace(r.dir) * length
			r.ray.Transparency = NumberSequence.new(0.66 + 0.22 * S.ease(age, 6, 26) + 0.1 * math.sin(age / 6 + r.seed * 2), 1)
		end
	end
	self.chipsA:draw(self.stage, self.contact, frame - F.firstHit, 1, self.at.Position.Y)
	self.chipsB:draw(self.stage, self.contact, frame - F.secondHit, 1.1, self.at.Position.Y)
end

local function mix(a, b, u)
	return a + (b - a) * u
end

-- Camera in the set's space.
function Face:camera(frame, motion)
	local p = self.point
	local head = self.at:PointToObjectSpace(self.rig.model.Head.Position)
	if frame < F.crack then
		local u = if motion then S.ease(frame, F.dig - 4, F.crack + 8) else 0.6
		local jolt = if motion then math.max(0, 1 - math.abs(frame - F.firstHit - 1) / 3) else 0
		return V(mix(-9.8, -7.4, u), mix(2.7, 2.9, u) + 0.06 * jolt, mix(1.4, 2.4, u)), V(mix(-0.3, -0.1, u), mix(3.6, 3.5, u), mix(2.5, 1.9, u)), 40, 0
	elseif frame < F.reaction then
		local age = frame - F.secondHit
		local u = if motion then S.ease(frame, F.crack, F.reaction) else 0.5
		local jolt = if motion and age >= 0 then math.exp(-age / 2.6) * math.cos(age * 2.0) else 0
		return V(p.X - 5.6 + 0.7 * u, p.Y - 0.25 - 0.12 * jolt, 5.0 - 0.6 * u + 0.16 * jolt), V(p.X + 0.75 - 0.2 * u, p.Y + 0.25 + 0.3 * u, 0.9), 40 + 1.2 * jolt, 1.1 * jolt
	end
	local u = if motion then S.ease(frame, F.reaction, F.living + 6) else 0.5
	-- From beside the vein, looking back at the face it lights.
	local eye = V(p.X + 1.9 - 0.25 * u, head.Y - 0.30, 0.55 + 0.1 * u)
	return eye, V(head.X - 0.1, head.Y - 0.12, head.Z), 42, 0
end

function Face:Destroy()
	self.rig:destroy()
	self.root:Destroy()
	self.glow:Destroy()
	self.scar:Destroy()
	self.chipsA:Destroy()
	self.chipsB:Destroy()
end

return Face
