local S = require(script.Parent.Scenery)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local sheets = require(script.Parent.Population)
local Crew = {}
Crew.__index = Crew
local wood, iron = Enum.Material.Wood, Enum.Material.Metal

-- A contact sheet of working silhouettes: body height, inclination, gaze,
-- then the two elbows and hands relative to the shoulders. Boots stay planted.
local poses = {
	march = {
		2.02,
		-0.10,
		-0.09,
		V(-0.24, -0.63, 0.25),
		V(0.11, -1.16, -0.23),
		V(0.25, -0.53, -0.55),
		V(-0.06, -0.67, -1.10),
	},
	sight = {
		2.00,
		-0.08,
		-0.26,
		V(-0.19, -0.46, -0.55),
		V(0.24, -0.15, -1),
		V(0.16, 0.25, -0.46),
		V(-0.17, 0.61, -0.70),
	},
	haul = {
		1.70,
		-0.32,
		0.08,
		V(-0.27, -0.55, -0.36),
		V(0.12, -0.99, -1.08),
		V(0.09, -0.59, -0.34),
		V(-0.57, -0.93, -1.19),
	},
	lift = {
		1.93,
		-0.11,
		-0.18,
		V(-0.32, 0.29, -0.33),
		V(0.29, 0.70, -0.57),
		V(0.25, 0.66, -0.03),
		V(-0.34, 1.13, -0.18),
	},
	strike = {
		1.32,
		-0.58,
		0.31,
		V(-0.15, -0.44, -0.65),
		V(0.37, -1.01, -1),
		V(0.18, -0.40, -0.56),
		V(-0.39, -0.80, -1.02),
	},
	kneel = {
		1.06,
		-0.42,
		0.18,
		V(-0.22, -0.56, -0.38),
		V(0.16, -0.95, -0.84),
		V(0.12, -0.34, -0.56),
		V(-0.21, -0.74, -1.06),
	},
	reach = {
		1.87,
		-0.28,
		0.17,
		V(-0.38, -0.48, -0.34),
		V(0.20, -0.68, -1.06),
		V(0.16, 0.05, -0.73),
		V(-0.09, -0.19, -1.56),
	},
}

local function group(parent, name)
	local m = S.group(name)
	m.Parent = parent
	return m
end

local function actor(root, name, shirt, skin, cap)
	local costume = group(root, name)
	local body, head = group(costume, "Work shirt"), group(costume, "Canvas cap")
	S.part(body, "Jacket", CF(0, 0.74, 0), V(1.52, 1.48, 0.88), shirt)
	S.part(body, "Canvas belt", CF(0, 0.16, 0), V(1.56, 0.20, 0.92), "654E42")
	S.part(body, "Scarf", CF(0, 1.36, -0.06), V(0.96, 0.24, 0.92), cap)
	S.part(body, "Kerchief end", CF(0.18, 1.12, -0.46) * A(0, 0, -0.27), V(0.35, 0.59, 0.10), cap)
	S.part(body, "Satchel", CF(0.82, 0.29, 0.04) * A(0, 0, -0.09), V(0.38, 0.69, 0.68), "956645", wood)
	local face = S.part(head, "Face", CF(0, 0.36, 0), V(1.16, 1.04, 0.97), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, face
	local smile = Instance.new("Decal")
	smile.Face, smile.Texture, smile.Parent = Enum.NormalId.Front, "rbxasset://textures/face.png", face
	local brim = S.part(head, "Wide brim", CF(0, 0.77, -0.10) * A(0, 0, math.pi / 2), V(0.11, 1.58, 1.62), cap)
	brim.Shape = Enum.PartType.Cylinder
	local crown = S.part(head, "Cap crown", CF(0, 0.93, 0.03), V(1.26, 0.50, 1.13), cap)
	crown.Shape = Enum.PartType.Ball
	local limbs = {}
	for i = 1, 2 do
		limbs[i] = {}
		for j, details in
			{
				{ "Shirt sleeve", shirt },
				{ "Rolled cuff", skin },
				{ "Trousers", "445360" },
				{ "Gaiter", "6D584B" },
				{ "Laced boot", "523F3B" },
			}
		do
			limbs[i][j] = S.part(costume, details[1], CFrame.identity, Vector3.one, details[2])
		end
	end
	local hammer = group(costume, "Track hammer")
	S.part(hammer, "Hickory", CF(0, 0.35, 0), V(0.16, 2.08, 0.17), "AB8057", wood)
	S.part(hammer, "Head", CF(0, 1.38, 0), V(0.76, 0.35, 0.39), "555D67", iron)
	local load = group(costume, "Bundle of cut stock")
	for i = -1, 1 do
		S.part(
			load,
			"Dressed timber",
			CF(0.97, -0.12, i * 0.26),
			V(5.35 - math.abs(i) * 0.34, 0.28, 0.29),
			if i == 0 then "B07D49" else "D5A75F",
			wood
		)
	end
	local staff = group(costume, "Survey staff")
	S.part(staff, "Rod", CF(0, 1.12, 0), V(0.15, 5.10, 0.15), "E4BF83", wood)
	S.part(staff, "Marker flag", CF(0.62, 3.27, 0), V(1.31, 0.83, 0.075), "D96337")
	return { costume = costume, body = body, head = head, limbs = limbs, hammer = hammer, staff = staff, load = load }
end

local function segment(part, a, b, w, d)
	local size = (b - a).Magnitude
	part.Size = V(w, d, size)
	part.CFrame = CFrame.lookAt((a + b) * 0.5, b)
end

local function expose(actor, root, poseName, beat, useTool)
	local p = poses[poseName]
	local body = root * CF(0, p[1], 0) * A(p[2], 0, 0.032 * beat)
	actor.body:PivotTo(body)
	actor.head:PivotTo(body * CF(0, 1.53, -0.03) * A(p[3], beat * 0.18, 0))
	local hands = {}
	for i, limb in actor.limbs do
		local side = if i == 1 then -1 else 1
		local shoulder = V(0.89 * side, 1.20, 0)
		local a, b, c = body * shoulder, body * (shoulder + p[i * 2 + 2]), body * (shoulder + p[i * 2 + 3])
		segment(limb[1], a, b, 0.54, 0.59)
		segment(limb[2], b, c, 0.46, 0.49)
		hands[i] = c
		local hip = root * V(0.37 * side, p[1] + 0.10, 0)
		local stride = if poseName == "march" then side * beat * 0.65 else side * 0.38
		local foot = root * V(side * 0.49, 0.23, stride)
		local knee = hip:Lerp(foot, 0.50) + root:VectorToWorldSpace(V(side * 0.1, 0.04, -0.23 - (2 - p[1]) * 0.55))
		segment(limb[3], hip, knee, 0.61, 0.67)
		segment(limb[4], knee, foot, 0.52, 0.54)
		limb[5].Size, limb[5].CFrame = V(0.62, 0.42, 0.86), root * CF(side * 0.49, 0.22, stride - 0.12)
	end
	actor.hammer.Parent = if useTool then actor.costume else nil
	if useTool then
		local tilt = if poseName == "lift" then 1.03 elseif poseName == "strike" then -2.14 else -0.86
		actor.hammer:PivotTo(CF(hands[2]) * root.Rotation * A(tilt, 0.12, 0.10))
	end
	actor.load.Parent = if poseName == "haul" then actor.costume else nil
	if actor.load.Parent then
		actor.load:PivotTo(CF((hands[1] + hands[2]) * 0.5) * root.Rotation * A(0, 0.13, 0.06))
	end
	actor.staff.Parent = if poseName == "sight" then actor.costume else nil
	if actor.staff.Parent then
		actor.staff:PivotTo(CF(hands[1]) * root.Rotation * A(0.05, 0, 0.07))
	end
end

-- The first boat has three occupants. Subsequent photographic plates are
-- populated independently: selected people pose at measured terrain stations,
-- disappear between eras, and give way to crews with different kit and colors.
local trades = {
	{ "Surveyor", "457B7B", "BB845E", "E5AA60" },
	{ "Rigger", "C27653", "E2AC81", "416879" },
	{ "Survey assistant", "9EAC86", "8F5E4A", "D7B17A" },
	{ "Camp cook", "B68863", "D3AB86", "788D77" },
	{ "Sailmaker", "609588", "956C56", "E8AD6F" },
	{ "Sawyer", "AC6852", "B78160", "CCB191" },
	{ "Timber carrier", "6A90A0", "E1AD82", "9B7254" },
	{ "Joiner", "A18B68", "996D52", "799393" },
	{ "Road builder", "CC9F66", "D5A37B", "557D86" },
	{ "Quarry hand", "5F8587", "805744", "DEA26C" },
	{ "Stone mason", "9CA081", "B17E5C", "768C91" },
	{ "Foreman", "AC805F", "D2A17C", "557789" },
	{ "Track layer", "A6785F", "926750", "C9AB74" },
	{ "Carpenter", "718F8C", "C0926C", "A27958" },
	{ "Cable splicer", "A89771", "9C6F56", "668D8E" },
	{ "Winch operator", "597E8B", "D1A378", "D89B5F" },
	{ "Ore carrier", "C58263", "AF7857", "5F8A77" },
	{ "Lamp trimmer", "6A9389", "D5A780", "E3BA77" },
}
function Crew.new(stage, base)
	local root = S.group("People of the cove")
	local actors = {}
	for i, details in trades do
		local person = actor(nil, table.unpack(details))
		if i >= 9 then
			S.part(person.body, "Work apron", CF(0, 0.56, -0.456), V(1.04, 1.06, 0.10), "726354")
		end
		if i >= 13 then
			S.part(person.head, "Helmet lamp", CF(0, 0.90, -0.65), V(0.30, 0.22, 0.22), "F7D18C")
		end
		actors[i] = person
	end
	return setmetatable({ root = root, actors = actors, base = base, stage = stage, plate = -1 }, Crew)
end
function Crew:draw(t, boatCF)
	local active = t >= 16.70 and t < 27.32
	self.root.Parent = if active then self.stage else nil
	if not active then
		self.plate = -1
		return
	end
	if t < 19.30 then
		if self.plate ~= 0 then
			for i, person in self.actors do
				person.costume.Parent = if i <= 3 then self.root else nil
			end
			self.plate = 0
		end
		for i = 1, 3 do
			local at = boatCF * CF((i - 2) * 1.22, 2.55, (i - 2) * 3.68 + 1) * A(0, (i - 2) * 0.39, 0)
			local pose = if i == 1 then "sight" elseif i == 2 then "haul" else "kneel"
			if i == 3 and t >= 18.13 then
				at = boatCF * CF(-1.30, 2.56, 4.85) * A(0, 1.12, 0)
				pose = "reach"
			elseif i < 3 then
				local start = if i == 1 then 17.94 else 18.12
				local from = at
				local bow = boatCF * CF(0.30, 2.82, -8.75) * A(0, -0.42, 0)
				at = from:Lerp(bow, S.ease(t, start, start + 0.31))
				if t >= start + 0.31 then
					local step = S.ease(t, start + 0.31, start + 0.66)
					local shelf = self.base * CF(-136.7, 24.83, 114.85) * A(0, 2.87, 0)
					local target = if i == 1
						then CF(-132.1, 24.52, 123.8) * A(0, -1.54, 0)
						else CF(-138.4, 24.52, 118.5) * A(0, -2.17, 0)
					at = bow:Lerp(shelf, step):Lerp(self.base * target, S.ease(t, start + 0.66, start + 0.93))
					pose = if i == 2 then "haul" elseif t < start + 0.82 then "march" else "sight"
				end
			end
			expose(self.actors[i], at, pose, 1, false)
		end
		return
	end
	local plate = #sheets
	while plate > 1 and t < sheets[plate][1] do
		plate -= 1
	end
	if self.plate == plate then
		return
	end
	self.plate = plate
	for _, person in self.actors do
		person.costume.Parent = nil
	end
	for j, mark in sheets[plate][2] do
		local person = self.actors[mark[1]]
		person.costume.Parent = self.root
		local pose = mark[6]
		local location = self.base * CF(mark[2], mark[3], mark[4]) * A(0, mark[5], 0)
		expose(person, location, pose, if (plate + j) % 2 == 0 then -1 else 1, pose == "lift" or pose == "strike")
	end
end
function Crew:Destroy()
	for _, person in self.actors do
		person.hammer:Destroy()
		person.load:Destroy()
		person.staff:Destroy()
		person.costume:Destroy()
	end
	self.root:Destroy()
end
return Crew
