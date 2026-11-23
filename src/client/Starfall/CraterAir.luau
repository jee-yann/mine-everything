-- Loose dust blown over the camera track and the secondary fires which feed
-- it. Every volume is fixed in world space and rolls across other depths.
local S = require(script.Parent.Scenery)
local Sprite = require(script.Parent.WorldSprite)
local input = game:GetService("UserInputService")
local V, hex = Vector3.new, Color3.fromHex
local CraterAir = {}
CraterAir.__index = CraterAir
local seam = V(0, 26.7, -32)
local outward, across = V(0.69, 0, 0.724), V(0.724, 0, -0.69)
local smoke, moonlit, dust, ember = hex("3E465B"), hex("A5B9D5"), hex("9C817A"), hex("FFA26C")
local coreTexture = "rbxasset://textures/particles/explosion01_core_main.dds"
local gold, flame = hex("FFE2AD"), hex("F8794B")

-- Along the two camera sightlines, across the wind, height above the seam,
-- width of the bank, degree of firelight on its underside.
local banks = {
	{ 68, -8, 18, 35, 0.26 },
	{ 56, 7, 13, 30, 0.78 },
	{ 43, -15, 10, 29, 0.40 },
	{ 34, 9, 9, 25, 0.64 },
	{ 25, -2, 7.8, 18, 0.22 },
	{ -17, 2, 11, 25, 0.50 },
	{ 13, -3.8, 5.8, 8.9, 0.16 },
	{ 8, 2.2, 3.7, 7.3, 0.54 },
	{ 3.5, -2.1, 2.8, 8.4, 0.48 },
	{ -5, 1.2, 4.0, 11.6, 0.70 },
	{ -10, -7.8, 5.3, 14, 0.73 },
	{ 14.1, -2.4, 3.15, 11.2, 0.27 },
	{ 9.5, -1.3, 1.45, 11.5, 0.44 },
	{ 5.0, -2.7, 0.8, 8.4, 0.46 },
	{ 4.2, 1.6, 1.15, 7.5, 0.57 },
}
-- Surveyed ground elevations, including the lip of the fracture bed.
local origins = {
	{ V(-4.6, 27.0, -40.7), 1.7 },
	{ V(8.4, 27.2, -38.1), 1.55 },
	{ V(-14.6, 26.64, -29.6), 2.15 },
	{ V(-19, 29.56, -44), 3.65 },
	{ V(19, 28.83, -42), 3.80 },
	{ V(-28, 39.38, -50.5), 2.95 },
	{ V(12.8, 30.39, -10.5), 2.88 },
	{ V(-24.6, 40.36, -12.2), 2.52 },
}

-- A pair of curved flame tongues can cut through ash even when a bank is
-- turned edge-on. Each one rises from a known coal, with a narrow hot base.
local function lick(anchor)
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Parent, b.Parent = anchor, anchor
	local beam = Instance.new("Beam")
	beam.Name, beam.Attachment0, beam.Attachment1 = "Tongue of burning pitch", a, b
	beam.FaceCamera, beam.Segments, beam.LightEmission, beam.LightInfluence = true, 8, 0.81, 0
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, hex("FD6539")),
		ColorSequenceKeypoint.new(0.29, hex("FFE6A1")),
		ColorSequenceKeypoint.new(0.66, hex("FFB151")),
		ColorSequenceKeypoint.new(1, hex("E96745")),
	})
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.23),
		NumberSequenceKeypoint.new(0.23, 0.085),
		NumberSequenceKeypoint.new(0.63, 0.24),
		NumberSequenceKeypoint.new(1, 0.94),
	})
	beam.Parent = anchor
	return { a = a, b = b, beam = beam }
end

function CraterAir.new(parent, base, motion)
	local low = input.TouchEnabled and not input.KeyboardEnabled
	local ok, quality = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	low = low or (ok and quality > 0 and quality < 5)
	local anchor = S.part(nil, "Dust suspended over the fracture", base, Vector3.one, "FFFFFF")
	anchor.Transparency, anchor.CastShadow = 1, false
	local eddies, fires = {}, {}
	for i, bank in banks do
		local point = seam + outward * bank[1] + across * bank[2] + V(0, bank[3], 0)
		for j = 1, if low then 2 else 3 do
			local a = i * 2.39996 + j * 2.18
			local width = bank[4]
			table.insert(eddies, {
				puff = Sprite.new(anchor, "Suspended impact grit", Sprite.smoke, 0.07),
				center = point + across * (j - 2) * width * 0.21 + V(0, math.sin(a) * 0.17 * width, 0),
				width = width,
				angle = a,
				warmth = bank[5],
				near = bank[1] < 16 and bank[1] > -7,
				phase = (i * 0.447 + j * 0.32) % 1,
			})
		end
	end
	for i, def in origins do
		local f = { point = def[1], size = def[2], fire = {}, soot = {}, tongues = {} }
		for j = 1, if low then 2 else 3 do
			f.tongues[j] = lick(anchor)
		end
		for j = 1, if low then 2 else 3 do
			f.fire[j] = Sprite.new(
				anchor,
				"Flame venting from shattered rock",
				if j == 2 then Sprite.flame else coreTexture,
				0.015
			)
		end
		for j = 1, if low then 2 else 4 do
			f.soot[j] = Sprite.new(anchor, "Smoke above a burning bank", Sprite.smoke, 0.07)
		end
		if i == 3 or i == 5 or (not low and (i == 1 or i == 4)) then
			local mount = Instance.new("Attachment")
			mount.Position, mount.Parent = def[1] + Vector3.yAxis * (0.64 * def[2]), anchor
			f.light = S.light(mount, "FF9A54", 11.5 + 3.1 * def[2], 0)
			f.light.Shadows = i == 3 and not low
		end
		fires[i] = f
	end
	local rakes = {}
	for i, pair in
		{
			{ V(-30, 42, -41), V(10, 26.5, -29) },
			{ V(-5, 57, -63), V(27, 38, -45) },
		}
	do
		local mount = Instance.new("Attachment")
		mount.CFrame, mount.Parent = CFrame.lookAt(pair[1], pair[2]), anchor
		local spot = Instance.new("SpotLight")
		spot.Name, spot.Face, spot.Angle = "Blue light raking the rock", Enum.NormalId.Front, if i == 1 then 56 else 70
		spot.Range, spot.Color, spot.Shadows, spot.Brightness, spot.Parent =
			60, hex(if i == 1 then "B1C9FF" else "8FADEA"), i == 1 and not low, 0, mount
		rakes[i] = spot
	end
	return setmetatable({
		anchor = anchor,
		parent = parent,
		eddies = eddies,
		fires = fires,
		rakes = rakes,
		speed = if motion == false then 0.48 else 1,
	}, CraterAir)
end

function CraterAir:draw(age)
	if age < 1.23 or age > 9.45 then
		self.anchor.Parent = nil
		return
	end
	self.anchor.Parent = self.parent
	local smokeUp = S.ease(age, 2.73, 4.04) * (1 - S.ease(age, 7.36, 9.44))
	local time = (age - 4) * self.speed
	-- The first reverse looks straight into the dust left by the front. Air
	-- crossing the near lip opens a narrow view of the vein late in the close shot.
	local clearance = S.ease(age, 6.36, 7.23)
	for i, e in self.eddies do
		local a = e.angle
		local wind = (e.phase - 0.5) * 0.4 + time * (0.15 + 0.022 * (i % 4))
		local drift = across * (wind * e.width * 0.49 + e.width * 0.073 * math.sin(time * 0.91 + a))
		local lift = 0.10 * e.width * math.sin(time * 0.76 + a) + (if e.near then 0.19 else 0.54) * time
		local pos = e.center + drift + V(0, lift, 0)
		local w = e.width * (1 + 0.09 * math.sin(a + time * 0.54))
		local body = smoke:Lerp(moonlit, 0.23 + 0.40 * e.phase)
		if i % 3 == 1 then
			body = moonlit:Lerp(dust, 0.27 + e.warmth * 0.37)
		end
		local tint = body:Lerp(ember, e.warmth * (0.17 + 0.21 * math.sin(time * 0.9 + a) ^ 2))
		local density = smokeUp
			* (0.64 + 0.18 * math.sin(a + time * 0.58) ^ 2)
			* (if e.near then 1 - clearance * 0.69 else 1)
		Sprite.draw(
			e.puff,
			pos,
			w * 1.43,
			w * (0.65 + 0.22 * e.phase),
			math.deg(a) + time * (if i % 2 == 0 then 6 else -7),
			tint,
			1 - density
		)
	end
	for i, f in self.fires do
		local t = age - (1.29 + (i % 4) * 0.26)
		local heat = S.ease(t, 0, 0.45) * (1 - S.ease(age, 7.9 + (i % 3) * 0.20, 9.37))
		t *= self.speed
		for j, q in f.tongues do
			local a = i * 1.37 + j * 2.4
			local flick = t * 5.3 + a
			local width = (0.32 + 0.13 * j) * f.size
			local h = f.size * (1.12 + 0.28 * j + 0.29 * math.sin(flick) + 0.15 * math.sin(flick * 1.46))
			local foot = f.point + V(math.sin(a) * 0.41, -0.14, math.cos(a) * 0.37) * f.size
			q.a.Position = foot
			q.b.Position = foot + V((-0.15 + 0.36 * math.sin(flick * 0.85)) * h, h, math.cos(flick) * h * 0.19)
			q.a.Axis = V(math.sin(flick + 1.4) * 0.68, 1, math.cos(a) * 0.41).Unit
			q.b.Axis = V(-0.6 + math.sin(flick) * 0.74, 1, 0.42 * math.cos(flick - 0.7)).Unit
			q.beam.Enabled = heat > 0.002
			q.beam.Width0, q.beam.Width1 = width * heat, 0.014 * heat
			q.beam.CurveSize0, q.beam.CurveSize1 = h * 0.61, h * 0.5
		end
		for j, p in f.fire do
			local u = (t / (0.65 + 0.08 * j) + j * 0.36 + i * 0.13) % 1
			local sway = V(0.75 * u * u + math.sin(i + j * 1.8) * 0.35, 0, math.cos(i * 1.64 + j) * 0.37) * f.size
			local h = f.size * (1.75 + 1.62 * u)
			local pos = f.point + sway + V(0, f.size * (0.35 + 1.12 * u), 0)
			Sprite.draw(
				p,
				pos,
				h * (0.77 - 0.24 * u),
				h * 1.28,
				13 * math.sin(i + j * 2.19 + u),
				gold:Lerp(flame, u * 0.75),
				1 - heat * (0.50 + 0.48 * math.sin(math.pi * u)) * math.sin(math.pi * u) ^ 0.26
			)
		end
		for j, p in f.soot do
			local u = (t / (2.33 + i * 0.047) + j / #f.soot + i * 0.19) % 1
			local wind = V(-2.15 * u * u, 4.5 * u + 0.56, 1.25 * u * u) * f.size
			local diameter = (1.68 + 2.86 * u) * f.size
			local tint = ember:Lerp(smoke, S.ease(u, 0.01, 0.46)):Lerp(moonlit, 0.42 * S.ease(u, 0.47, 1))
			Sprite.draw(
				p,
				f.point + wind,
				diameter * 1.16,
				diameter,
				i * 48 + j * 31 + u * 45,
				tint,
				1 - 0.88 * heat * math.sin(math.pi * u) ^ 0.63
			)
		end
		if f.light then
			f.light.Brightness = heat
				* (2.8 + self.speed * (0.54 * math.sin(i + t * 9.7) + 0.35 * math.sin(2 * i + t * 5.6)))
		end
	end
	for i, light in self.rakes do
		light.Brightness = (if i == 1 then 6.4 else 4.4) * smokeUp
	end
end

return CraterAir
