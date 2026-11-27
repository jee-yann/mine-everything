-- Part-built pets in the cove's chunky enamel style, one recipe per species. Each model faces -Z with
-- its pivot at the body's centre. `parts` lists every part with its offset from the pivot, and wings
-- carry a `flap` side (-1 or 1) so followers can beat them; nothing here is anchored to a character.
-- The same models fill the Collection card's previews.
local Collectibles = require(game:GetService("ReplicatedStorage").Shared.Collectibles)
local Models = {}
local rgb = Color3.fromRGB

local function builder(name)
	local model = Instance.new("Model")
	model.Name = name
	local parts = {}
	local function piece(label, size, at, color, turn, material, shape)
		local part = Instance.new("Part")
		part.Name, part.Size, part.Color = label, size, color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.CastShadow = false
		if shape then part.Shape = shape end
		local offset = CFrame.new(at) * (turn or CFrame.identity)
		part.CFrame = offset
		part.Parent = model
		table.insert(parts, { part = part, offset = offset })
		return part, parts[#parts]
	end
	return model, parts, piece
end

local function rot(x, y, z)
	return CFrame.Angles(math.rad(x or 0), math.rad(y or 0), math.rad(z or 0))
end

local ball = Enum.PartType.Ball
local neon, glass, slate = Enum.Material.Neon, Enum.Material.Glass, Enum.Material.Slate
local eyeColor = rgb(30, 38, 54)

-- Two eyes with a glint, on the face at height y and depth z.
local function eyes(piece, spread, y, z, size, color)
	for _, side in { -1, 1 } do
		piece("Eye", Vector3.new(size, size * 1.3, 0.1), Vector3.new(side * spread, y, z), color or eyeColor)
		piece("Glint", Vector3.one * size * 0.4, Vector3.new(side * spread - size * 0.15, y + size * 0.25, z - 0.06), rgb(255, 255, 255), nil, neon)
	end
end

local recipes = {}

recipes.Rock = function(piece)
	local stone = rgb(137, 147, 163)
	piece("Body", Vector3.new(1.55, 0.92, 1.12), Vector3.zero, stone, rot(0, 0, -4), slate)
	piece("Crown", Vector3.new(1.16, 0.35, 0.84), Vector3.new(-0.09, 0.46, 0.01), rgb(159, 170, 183), rot(0, 0, -7), slate)
	piece("Sprout", Vector3.new(0.12, 0.34, 0.12), Vector3.new(0.1, 0.78, 0), rgb(90, 200, 90))
	piece("Leaf", Vector3.new(0.34, 0.08, 0.2), Vector3.new(0.24, 0.92, 0), rgb(110, 225, 100), rot(0, 0, 25))
	for _, side in { -1, 1 } do
		piece("Foot", Vector3.new(0.46, 0.22, 0.55), Vector3.new(side * 0.42, -0.46, -0.05), rgb(85, 96, 116), nil, slate)
	end
	eyes(piece, 0.35, 0.1, -0.6, 0.18)
	piece("Smile", Vector3.new(0.22, 0.075, 0.08), Vector3.new(0, -0.10, -0.59), rgb(51, 54, 66))
end

recipes.Bat = function(piece)
	local coal = rgb(58, 56, 74)
	piece("Body", Vector3.new(1, 1, 1), Vector3.zero, coal, nil, nil, ball)
	for _, side in { -1, 1 } do
		piece("Ear", Vector3.new(0.22, 0.42, 0.18), Vector3.new(side * 0.28, 0.55, 0), coal, rot(0, 0, -side * 15))
		local _, wing = piece("Wing", Vector3.new(1.1, 0.08, 0.7), Vector3.new(side * 0.95, 0.1, 0.05), rgb(96, 84, 128), rot(0, 0, side * 12))
		wing.flap = side
	end
	eyes(piece, 0.2, 0.08, -0.48, 0.17, rgb(255, 214, 90))
	piece("Fang", Vector3.new(0.07, 0.12, 0.05), Vector3.new(0.08, -0.18, -0.47), rgb(255, 255, 255))
end

recipes.Crab = function(piece)
	local copper = rgb(214, 120, 74)
	piece("Body", Vector3.new(1.5, 0.6, 1.1), Vector3.zero, copper)
	piece("Shell", Vector3.new(1.2, 0.25, 0.9), Vector3.new(0, 0.36, 0.05), rgb(236, 150, 96))
	for _, side in { -1, 1 } do
		piece("Claw", Vector3.new(0.5, 0.4, 0.45), Vector3.new(side * 0.98, 0.15, -0.55), rgb(232, 136, 82), rot(0, side * 20, 0))
		piece("Pincer", Vector3.new(0.18, 0.3, 0.3), Vector3.new(side * 1.12, 0.25, -0.86), rgb(250, 170, 110))
		piece("Stalk", Vector3.new(0.09, 0.4, 0.09), Vector3.new(side * 0.25, 0.48, -0.42), copper)
		piece("Eye", Vector3.new(0.18, 0.18, 0.18), Vector3.new(side * 0.25, 0.72, -0.44), rgb(255, 255, 255), nil, nil, ball)
		piece("Pupil", Vector3.new(0.09, 0.09, 0.04), Vector3.new(side * 0.25, 0.72, -0.54), eyeColor)
		for i = 0, 2 do
			piece("Leg", Vector3.new(0.45, 0.1, 0.1), Vector3.new(side * 0.85, -0.3, -0.2 + i * 0.3), rgb(190, 100, 60), rot(0, 0, side * -30))
		end
	end
end

recipes.Hedgehog = function(piece)
	piece("Body", Vector3.new(1.3, 1, 1.4), Vector3.zero, rgb(200, 160, 120), nil, nil, ball)
	piece("Snout", Vector3.new(0.45, 0.4, 0.4), Vector3.new(0, -0.1, -0.7), rgb(236, 200, 160), nil, nil, ball)
	piece("Nose", Vector3.new(0.15, 0.15, 0.1), Vector3.new(0, -0.05, -0.92), eyeColor)
	for i = 0, 6 do
		local a = math.rad(-60 + i * 20)
		local tilt = rot(math.deg(a) * 0.6 + 20, 0, 0)
		piece("Spike", Vector3.new(0.9, 0.25, 0.25), Vector3.new(0, 0.38 + math.cos(a) * 0.12, 0.1 + math.sin(a) * 0.45), rgb(235, 240, 255), tilt * rot(0, 0, 0), glass)
	end
	eyes(piece, 0.28, 0.12, -0.6, 0.14)
	for _, side in { -1, 1 } do
		piece("Foot", Vector3.new(0.3, 0.18, 0.4), Vector3.new(side * 0.35, -0.5, -0.1), rgb(150, 110, 80))
	end
end

recipes.Slime = function(piece)
	local body = piece("Body", Vector3.new(1.3, 1.05, 1.3), Vector3.zero, rgb(110, 230, 140), nil, glass, ball)
	body.Transparency = 0.25
	piece("Gem", Vector3.new(0.4, 0.4, 0.4), Vector3.new(0, 0, 0.1), rgb(90, 220, 255), rot(45, 45, 0), neon)
	eyes(piece, 0.25, 0.15, -0.6, 0.18)
	piece("Smile", Vector3.new(0.25, 0.07, 0.06), Vector3.new(0, -0.12, -0.62), rgb(40, 90, 60))
end

recipes.Moth = function(piece)
	piece("Body", Vector3.new(0.55, 0.55, 1.1), Vector3.zero, rgb(240, 228, 200), nil, nil, ball)
	piece("Fluff", Vector3.new(0.7, 0.5, 0.5), Vector3.new(0, 0.05, -0.3), rgb(255, 250, 230), nil, nil, ball)
	for _, side in { -1, 1 } do
		local _, wing = piece("Wing", Vector3.new(1.1, 0.06, 0.9), Vector3.new(side * 0.75, 0.15, 0), rgb(255, 230, 120), rot(0, 0, side * 10), neon)
		wing.flap = side
		piece("Antenna", Vector3.new(0.05, 0.5, 0.05), Vector3.new(side * 0.15, 0.45, -0.45), rgb(120, 100, 80), rot(-30, 0, side * 20))
	end
	eyes(piece, 0.14, 0.08, -0.52, 0.12)
end

local function drake(piece, body, wings, horn, wingMaterial)
	piece("Body", Vector3.new(1.1, 0.85, 1.5), Vector3.new(0, -0.12, 0.3), body)
	piece("Head", Vector3.new(1.1, 0.8, 0.9), Vector3.new(0, 0.2, -0.6), body)
	piece("Tail", Vector3.new(0.39, 0.37, 1.25), Vector3.new(0, -0.14, 1.5), body)
	for _, side in { -1, 1 } do
		local _, wing = piece("Wing", Vector3.new(1.32, 0.18, 0.95), Vector3.new(side * 0.98, 0.3, 0.3), wings, rot(0, 0, side * 26), wingMaterial or glass)
		wing.flap = side
		piece("Horn", Vector3.new(0.20, 0.56, 0.24), Vector3.new(side * 0.36, 0.72, -0.5), horn, rot(0, 0, -side * 18))
	end
	eyes(piece, 0.28, 0.28, -1.06, 0.16)
end
recipes.Drake = function(piece)
	drake(piece, rgb(111, 83, 179), rgb(117, 205, 222), rgb(255, 218, 142))
end
recipes.StarDrake = function(piece)
	drake(piece, rgb(54, 40, 110), rgb(255, 214, 90), rgb(120, 240, 230), neon)
	for i, at in { Vector3.new(0, 0.38, 0.1), Vector3.new(0, 0.32, 0.7), Vector3.new(0, 0.1, 1.5) } do
		piece("Star", Vector3.one * (0.22 - i * 0.03), at, rgb(255, 240, 160), rot(45, 0, 45), neon)
	end
end

recipes.Fox = function(piece)
	local fur = rgb(120, 200, 255)
	piece("Body", Vector3.new(0.9, 0.8, 1.4), Vector3.new(0, -0.1, 0.25), fur)
	piece("Head", Vector3.new(0.9, 0.75, 0.75), Vector3.new(0, 0.35, -0.55), fur)
	piece("Muzzle", Vector3.new(0.45, 0.35, 0.4), Vector3.new(0, 0.22, -1), rgb(235, 248, 255))
	piece("Nose", Vector3.new(0.14, 0.12, 0.08), Vector3.new(0, 0.32, -1.22), eyeColor)
	piece("Tail", Vector3.new(0.45, 0.45, 1.1), Vector3.new(0, 0.2, 1.2), fur, rot(30, 0, 0))
	piece("Tail tip", Vector3.new(0.4, 0.4, 0.4), Vector3.new(0, 0.5, 1.7), rgb(220, 250, 255), rot(30, 45, 0), glass)
	for _, side in { -1, 1 } do
		piece("Ear", Vector3.new(0.25, 0.45, 0.15), Vector3.new(side * 0.28, 0.85, -0.55), rgb(180, 230, 255), rot(0, 0, -side * 12), glass)
		piece("Leg", Vector3.new(0.22, 0.4, 0.22), Vector3.new(side * 0.3, -0.6, -0.15), rgb(90, 170, 230))
		piece("Leg", Vector3.new(0.22, 0.4, 0.22), Vector3.new(side * 0.3, -0.6, 0.65), rgb(90, 170, 230))
	end
	eyes(piece, 0.22, 0.42, -0.94, 0.13)
end

recipes.Salamander = function(piece)
	local skin = rgb(232, 84, 50)
	piece("Body", Vector3.new(0.8, 0.5, 1.6), Vector3.zero, skin)
	piece("Head", Vector3.new(0.85, 0.5, 0.7), Vector3.new(0, 0.05, -1.05), skin)
	piece("Tail", Vector3.new(0.45, 0.35, 1.2), Vector3.new(0, -0.05, 1.35), rgb(210, 70, 40), rot(0, 15, 0))
	for i = 0, 2 do
		piece("Stripe", Vector3.new(0.84, 0.1, 0.18), Vector3.new(0, 0.26, -0.5 + i * 0.5), rgb(255, 190, 60), nil, neon)
	end
	for _, side in { -1, 1 } do
		piece("Leg", Vector3.new(0.4, 0.15, 0.2), Vector3.new(side * 0.5, -0.2, -0.5), rgb(190, 60, 36), rot(0, 0, side * -20))
		piece("Leg", Vector3.new(0.4, 0.15, 0.2), Vector3.new(side * 0.5, -0.2, 0.5), rgb(190, 60, 36), rot(0, 0, side * -20))
	end
	eyes(piece, 0.25, 0.25, -1.4, 0.13, rgb(255, 230, 120))
end

recipes.Owl = function(piece)
	piece("Body", Vector3.new(1.1, 1.3, 1), Vector3.zero, rgb(236, 232, 255), nil, nil, ball)
	piece("Chest", Vector3.new(0.7, 0.75, 0.2), Vector3.new(0, -0.15, -0.42), rgb(190, 170, 255), nil, glass)
	for _, side in { -1, 1 } do
		local _, wing = piece("Wing", Vector3.new(0.9, 0.12, 0.7), Vector3.new(side * 0.62, 0, 0.05), rgb(170, 200, 255), rot(0, 0, side * 70))
		wing.flap = side
		piece("Tuft", Vector3.new(0.18, 0.35, 0.15), Vector3.new(side * 0.3, 0.72, -0.1), rgb(200, 190, 255), rot(0, 0, -side * 20))
		piece("Eye ring", Vector3.new(0.4, 0.4, 0.08), Vector3.new(side * 0.22, 0.25, -0.46), rgb(255, 230, 120), nil, nil, ball)
	end
	eyes(piece, 0.22, 0.25, -0.52, 0.18)
	piece("Beak", Vector3.new(0.14, 0.2, 0.15), Vector3.new(0, 0.05, -0.55), rgb(255, 190, 70), rot(20, 0, 0))
end

recipes.Wisp = function(piece)
	local core = piece("Body", Vector3.new(0.9, 0.9, 0.9), Vector3.zero, rgb(140, 240, 255), nil, neon, ball)
	local shell = piece("Glow", Vector3.new(1.4, 1.4, 1.4), Vector3.zero, rgb(200, 250, 255), nil, glass, ball)
	shell.Transparency = 0.6
	piece("Tail", Vector3.new(0.4, 0.4, 0.8), Vector3.new(0, -0.2, 0.75), rgb(160, 120, 255), rot(20, 0, 0), neon)
	eyes(piece, 0.18, 0.08, -0.72, 0.14)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = rgb(160, 240, 255), 9, 1.2, false
	light.Parent = core
end

recipes.Mole = function(piece)
	local fur = rgb(96, 78, 70)
	piece("Body", Vector3.new(1.2, 0.9, 1.3), Vector3.zero, fur, nil, nil, ball)
	piece("Snout", Vector3.new(0.4, 0.3, 0.35), Vector3.new(0, -0.05, -0.65), rgb(255, 160, 170), nil, nil, ball)
	for _, side in { -1, 1 } do
		piece("Claw", Vector3.new(0.4, 0.12, 0.32), Vector3.new(side * 0.55, -0.35, -0.4), rgb(255, 214, 190), rot(0, side * 20, 0))
		piece("Shade", Vector3.new(0.3, 0.16, 0.06), Vector3.new(side * 0.2, 0.18, -0.58), rgb(30, 30, 40))
	end
	piece("Helmet", Vector3.new(0.8, 0.22, 0.8), Vector3.new(0, 0.48, -0.05), rgb(255, 200, 60))
	piece("Lamp", Vector3.new(0.2, 0.2, 0.08), Vector3.new(0, 0.5, -0.45), rgb(255, 250, 200), nil, neon)
end

recipes.Frog = function(piece)
	local skin = rgb(110, 200, 90)
	piece("Body", Vector3.new(1.3, 0.8, 1.2), Vector3.zero, skin, nil, nil, ball)
	piece("Belly", Vector3.new(0.9, 0.5, 0.2), Vector3.new(0, -0.12, -0.52), rgb(220, 245, 170))
	for _, side in { -1, 1 } do
		piece("Eye bump", Vector3.new(0.4, 0.4, 0.4), Vector3.new(side * 0.32, 0.42, -0.25), skin, nil, nil, ball)
		piece("Eye", Vector3.new(0.22, 0.22, 0.1), Vector3.new(side * 0.32, 0.46, -0.45), eyeColor)
		piece("Leg", Vector3.new(0.4, 0.2, 0.55), Vector3.new(side * 0.55, -0.35, 0.15), rgb(80, 170, 70))
		piece("Moss", Vector3.new(0.3, 0.12, 0.3), Vector3.new(side * 0.2, 0.42, 0.25), rgb(60, 140, 60))
	end
	piece("Smile", Vector3.new(0.5, 0.06, 0.06), Vector3.new(0, 0.02, -0.6), rgb(40, 90, 40))
end

recipes.Turtle = function(piece)
	piece("Body", Vector3.new(1.2, 0.35, 1.4), Vector3.new(0, -0.25, 0), rgb(150, 200, 120))
	piece("Shell", Vector3.new(1.4, 0.75, 1.5), Vector3.new(0, 0.12, 0.05), rgb(150, 156, 170), nil, slate, ball)
	for i, at in { Vector3.new(0, 0.5, 0.05), Vector3.new(0.35, 0.38, -0.3), Vector3.new(-0.35, 0.38, 0.4) } do
		piece("Pebble", Vector3.one * (0.3 - i * 0.03), at, rgb(190, 196, 210), rot(20 * i, 30 * i, 0), slate)
	end
	piece("Head", Vector3.new(0.5, 0.45, 0.5), Vector3.new(0, -0.05, -0.9), rgb(160, 210, 130), nil, nil, ball)
	eyes(piece, 0.12, 0.02, -1.13, 0.1)
	for _, side in { -1, 1 } do
		piece("Leg", Vector3.new(0.28, 0.25, 0.28), Vector3.new(side * 0.5, -0.4, -0.45), rgb(130, 180, 110))
		piece("Leg", Vector3.new(0.28, 0.25, 0.28), Vector3.new(side * 0.5, -0.4, 0.5), rgb(130, 180, 110))
	end
end

recipes.Penguin = function(piece)
	piece("Body", Vector3.new(0.95, 1.3, 0.9), Vector3.zero, rgb(40, 50, 80), nil, nil, ball)
	piece("Belly", Vector3.new(0.7, 0.95, 0.3), Vector3.new(0, -0.1, -0.33), rgb(245, 248, 255), nil, nil, ball)
	piece("Beak", Vector3.new(0.2, 0.12, 0.2), Vector3.new(0, 0.28, -0.5), rgb(255, 170, 50))
	piece("Scarf", Vector3.new(0.95, 0.16, 0.92), Vector3.new(0, 0.1, 0), rgb(120, 210, 255))
	for _, side in { -1, 1 } do
		local _, wing = piece("Wing", Vector3.new(0.12, 0.7, 0.4), Vector3.new(side * 0.5, -0.05, 0), rgb(30, 40, 70), rot(0, 0, side * 12))
		wing.flap = side
		piece("Foot", Vector3.new(0.25, 0.08, 0.3), Vector3.new(side * 0.2, -0.65, -0.15), rgb(255, 170, 50))
	end
	eyes(piece, 0.18, 0.42, -0.42, 0.1)
end

recipes.Bunny = function(piece)
	local fur = rgb(245, 235, 255)
	piece("Body", Vector3.new(1, 0.95, 1.1), Vector3.zero, fur, nil, nil, ball)
	piece("Head", Vector3.new(0.85, 0.8, 0.8), Vector3.new(0, 0.45, -0.45), fur, nil, nil, ball)
	for _, side in { -1, 1 } do
		piece("Ear", Vector3.new(0.18, 0.7, 0.12), Vector3.new(side * 0.18, 1.05, -0.4), fur, rot(0, 0, -side * 10))
		piece("Ear gem", Vector3.new(0.1, 0.45, 0.06), Vector3.new(side * 0.18, 1.05, -0.47), rgb(255, 170, 220), rot(0, 0, -side * 10), glass)
	end
	piece("Tail", Vector3.new(0.35, 0.35, 0.35), Vector3.new(0, 0, 0.58), rgb(200, 230, 255), nil, glass, ball)
	piece("Nose", Vector3.new(0.1, 0.08, 0.05), Vector3.new(0, 0.38, -0.84), rgb(255, 140, 170))
	eyes(piece, 0.2, 0.52, -0.8, 0.13)
end

recipes.Golem = function(piece)
	local stone = rgb(120, 126, 140)
	piece("Body", Vector3.new(1.1, 0.9, 0.8), Vector3.zero, stone, nil, slate)
	piece("Head", Vector3.new(0.75, 0.6, 0.65), Vector3.new(0, 0.75, -0.05), rgb(140, 146, 160), nil, slate)
	piece("Core", Vector3.new(0.3, 0.3, 0.1), Vector3.new(0, 0.05, -0.42), rgb(90, 230, 255), rot(0, 0, 45), neon)
	for _, side in { -1, 1 } do
		piece("Arm", Vector3.new(0.35, 0.8, 0.35), Vector3.new(side * 0.75, -0.1, 0), stone, nil, slate)
		piece("Leg", Vector3.new(0.35, 0.35, 0.4), Vector3.new(side * 0.28, -0.6, 0), rgb(100, 106, 120), nil, slate)
		piece("Eye", Vector3.new(0.14, 0.1, 0.06), Vector3.new(side * 0.17, 0.8, -0.4), rgb(90, 230, 255), nil, neon)
	end
	piece("Moss", Vector3.new(0.5, 0.1, 0.4), Vector3.new(0.1, 1.08, 0), rgb(90, 180, 90))
end

recipes.Jelly = function(piece)
	local bell = piece("Body", Vector3.new(1.3, 0.9, 1.3), Vector3.zero, rgb(255, 150, 220), nil, glass, ball)
	bell.Transparency = 0.3
	piece("Glow", Vector3.new(0.6, 0.4, 0.6), Vector3.new(0, 0.05, 0), rgb(255, 210, 240), nil, neon, ball)
	for i = 0, 4 do
		local a = math.rad(i * 72)
		piece("Tendril", Vector3.new(0.1, 0.7, 0.1), Vector3.new(math.cos(a) * 0.35, -0.65, math.sin(a) * 0.35), rgb(200, 140, 255), rot(0, 0, 8 * (i - 2)), neon)
	end
	eyes(piece, 0.2, 0.05, -0.63, 0.13)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = rgb(255, 160, 230), 7, 0.9, false
	light.Parent = bell
end

recipes.Stag = function(piece)
	local fur = rgb(240, 236, 255)
	piece("Body", Vector3.new(0.9, 0.8, 1.5), Vector3.new(0, -0.05, 0.2), fur)
	piece("Neck", Vector3.new(0.45, 0.7, 0.45), Vector3.new(0, 0.45, -0.45), fur, rot(-20, 0, 0))
	piece("Head", Vector3.new(0.55, 0.5, 0.75), Vector3.new(0, 0.85, -0.75), fur)
	for _, side in { -1, 1 } do
		piece("Antler", Vector3.new(0.1, 0.7, 0.1), Vector3.new(side * 0.25, 1.35, -0.65), rgb(140, 240, 220), rot(0, 0, -side * 25), neon)
		piece("Antler tip", Vector3.new(0.08, 0.4, 0.08), Vector3.new(side * 0.42, 1.55, -0.55), rgb(200, 160, 255), rot(0, 0, -side * 55), neon)
		piece("Leg", Vector3.new(0.18, 0.55, 0.18), Vector3.new(side * 0.3, -0.65, -0.3), rgb(210, 205, 235))
		piece("Leg", Vector3.new(0.18, 0.55, 0.18), Vector3.new(side * 0.3, -0.65, 0.7), rgb(210, 205, 235))
	end
	eyes(piece, 0.18, 0.92, -1.13, 0.11)
end

recipes.Phoenix = function(piece)
	piece("Body", Vector3.new(0.8, 0.8, 1.1), Vector3.zero, rgb(255, 120, 40), nil, nil, ball)
	piece("Head", Vector3.new(0.6, 0.6, 0.6), Vector3.new(0, 0.45, -0.5), rgb(255, 170, 60), nil, nil, ball)
	piece("Beak", Vector3.new(0.14, 0.14, 0.25), Vector3.new(0, 0.42, -0.85), rgb(255, 220, 90))
	piece("Crest", Vector3.new(0.1, 0.45, 0.3), Vector3.new(0, 0.85, -0.45), rgb(255, 230, 120), rot(-20, 0, 0), neon)
	piece("Tail", Vector3.new(0.5, 0.15, 1.1), Vector3.new(0, 0.05, 0.95), rgb(255, 200, 70), rot(-15, 0, 0), neon)
	for _, side in { -1, 1 } do
		local _, wing = piece("Wing", Vector3.new(1.4, 0.12, 0.8), Vector3.new(side * 1, 0.15, 0.05), rgb(255, 90, 50), rot(0, 0, side * 20), neon)
		wing.flap = side
	end
	eyes(piece, 0.16, 0.55, -0.78, 0.11)
end

recipes.Griffin = function(piece)
	local gold = rgb(255, 200, 80)
	piece("Body", Vector3.new(0.95, 0.85, 1.5), Vector3.new(0, -0.1, 0.25), rgb(214, 160, 90))
	piece("Head", Vector3.new(0.75, 0.7, 0.7), Vector3.new(0, 0.35, -0.65), rgb(255, 250, 235))
	piece("Beak", Vector3.new(0.2, 0.2, 0.3), Vector3.new(0, 0.25, -1.1), gold)
	piece("Crown", Vector3.new(0.5, 0.15, 0.5), Vector3.new(0, 0.78, -0.65), gold, nil, Enum.Material.Metal)
	piece("Tail", Vector3.new(0.2, 0.2, 0.9), Vector3.new(0, 0.05, 1.3), rgb(214, 160, 90), rot(-20, 0, 0))
	for _, side in { -1, 1 } do
		local _, wing = piece("Wing", Vector3.new(1.4, 0.15, 0.95), Vector3.new(side * 1.05, 0.3, 0.2), rgb(255, 245, 225), rot(0, 0, side * 24))
		wing.flap = side
		piece("Wing tip", Vector3.new(0.6, 0.16, 0.5), Vector3.new(side * 1.6, 0.55, 0.3), gold, rot(0, 0, side * 24), neon)
		piece("Leg", Vector3.new(0.2, 0.45, 0.2), Vector3.new(side * 0.3, -0.65, -0.1), gold)
	end
	eyes(piece, 0.2, 0.45, -1.01, 0.12)
end

-- Pet styles: something the pet wears, built on the pet's own size.
local function bounds(parts)
	local top, back, width = 0, 0, 0
	for _, entry in parts do
		local at, size = entry.offset.Position, entry.part.Size
		top = math.max(top, at.Y + size.Y / 2)
		back = math.max(back, at.Z + size.Z / 2)
		width = math.max(width, math.abs(at.X) + size.X / 2)
	end
	return top, back, width
end

function Models.style(model, parts, styleId)
	local style = Collectibles.styleById[styleId or ""]
	if not style then return end
	local top, back, width = bounds(parts)
	local body = model.PrimaryPart
	local function piece(label, size, at, color, turn, material, shape)
		local part = Instance.new("Part")
		part.Name, part.Size, part.Color = label, size, color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
		if shape then part.Shape = shape end
		local offset = CFrame.new(at) * (turn or CFrame.identity)
		part.CFrame = model:GetPivot() * offset
		part.Parent = model
		table.insert(parts, { part = part, offset = offset })
		return part, parts[#parts]
	end
	local color = style.color
	if style.look == "wings" then
		for _, side in { -1, 1 } do
			local wing, entry = piece("Style wing", Vector3.new(1.1, 0.06, 0.7), Vector3.new(side * (width * 0.5 + 0.45), top * 0.55, 0.15),
				color, rot(0, 0, side * 25), glass)
			wing.Transparency = 0.25
			entry.flap = side
		end
	elseif style.look == "crown" then
		piece("Style crown", Vector3.new(0.55, 0.18, 0.55), Vector3.new(0, top + 0.09, -0.1), color, nil, Enum.Material.Metal)
		for i = -1, 1 do
			piece("Crown point", Vector3.new(0.1, 0.22, 0.1), Vector3.new(i * 0.2, top + 0.28, -0.1), color, rot(0, 45, 0), Enum.Material.Metal)
		end
		piece("Crown gem", Vector3.new(0.12, 0.12, 0.05), Vector3.new(0, top + 0.1, -0.38), Color3.fromRGB(255, 80, 120), rot(0, 0, 45), neon)
	elseif style.look == "halo" then
		local ring = piece("Style halo", Vector3.new(0.06, 0.7, 0.7), Vector3.new(0, top + 0.35, 0), color, rot(0, 0, 90), neon, Enum.PartType.Cylinder)
		ring.Transparency = 0.15
	else
		-- Flames, the sparkle trail and the cloak are particles on the body.
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Style " .. style.look
		emitter.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.5))
		emitter.LightEmission = 1
		if style.look == "flames" then
			emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
			emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
			emitter.Rate, emitter.Lifetime, emitter.Speed = 18, NumberRange.new(0.4, 0.7), NumberRange.new(1, 2)
			emitter.Acceleration, emitter.EmissionDirection = Vector3.new(0, 3, 0), Enum.NormalId.Top
		elseif style.look == "trail" then
			emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			emitter.Size = NumberSequence.new(0.25, 0)
			emitter.Rate, emitter.Lifetime, emitter.Speed = 12, NumberRange.new(0.8, 1.3), NumberRange.new(0)
			emitter.LockedToPart = false
		else
			emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
			emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.4) })
			emitter.Transparency = NumberSequence.new(0.5, 1)
			emitter.Rate, emitter.Lifetime, emitter.Speed = 8, NumberRange.new(0.8, 1.2), NumberRange.new(0.2, 0.5)
			emitter.SpreadAngle = Vector2.new(180, 180)
		end
		emitter.Parent = body
	end
	local _ = back
end

-- Builds `id`'s model, wearing pet style `styleId` if given. Returns the model and its parts with their
-- offsets from the pivot.
function Models.build(id, styleId)
	local pet = Collectibles.petById[id]
	local model, parts, piece = builder(if pet then pet.name else id)
	;(recipes[id] or recipes.Rock)(piece)
	model.PrimaryPart = parts[1].part
	Models.style(model, parts, styleId)
	return model, parts
end

-- Sets every part from `pivot`, with wings beating by `flap` radians. Fills `moves` for BulkMoveTo.
function Models.place(parts, pivot, flap, partsOut, framesOut)
	for _, entry in parts do
		local at = pivot * entry.offset
		if entry.flap and flap then
			at = pivot * CFrame.new(entry.offset.Position) * CFrame.Angles(0, 0, entry.flap * flap) * entry.offset.Rotation
		end
		table.insert(partsOut, entry.part)
		table.insert(framesOut, at)
	end
end

-- A still model for a ViewportFrame: the pet, a camera looking at it from the front, slightly turned.
function Models.preview(viewport, id, styleId)
	viewport:ClearAllChildren()
	local model = Models.build(id, styleId)
	model:PivotTo(CFrame.Angles(0, math.rad(-28), 0))
	model.Parent = viewport
	local camera = Instance.new("Camera")
	local _, size = model:GetBoundingBox()
	local reach = math.max(size.X, size.Y, size.Z)
	camera.FieldOfView = 34
	camera.CFrame = CFrame.lookAt(Vector3.new(0, reach * 0.35, -reach * 2.4), Vector3.zero)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.LightColor, viewport.Ambient = rgb(255, 250, 235), rgb(160, 160, 190)
	viewport.LightDirection = Vector3.new(-1, -1, 1)
	return model
end

return Models
