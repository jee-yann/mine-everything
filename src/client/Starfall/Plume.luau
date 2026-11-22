-- Offline solid sculptures, staged around the mine in three dimensions.
-- Each boiling packet has its own Blender action and independently cooling lip.
local Http = game:GetService("HttpService")
local S = require(script.Parent.Scenery)
local Vapour = require(script.Parent.Vapour)
local Sprite = require(script.Parent.WorldSprite)
local CraterAir = require(script.Parent.CraterAir)
local stock = script.Parent.PressureBloom
local tracks
local Plume = {}
Plume.__index = Plume
local V, CF, clamp = Vector3.new, CFrame.new, math.clamp
local contact = V(0, 26, -32)
local palette = {
	Mantle = { "AC422C", "834040", "565363", "8E8894" },
	Fold = { "B73C20", "A83E25", "766474", "A19AA5" },
	Lip = { "E46028", "CF5324", "A77771", "B2ACB5" },
	Flame = { "FFA73C", "F88831", "BF927D", "C4BCC3" },
}
for _, tones in palette do
	for i, hex in tones do
		tones[i] = Color3.fromHex(hex)
	end
end

local function sculpt(variant)
	local model = stock[variant]:Clone()
	local skins = {}
	for _, part in model:GetChildren() do
		if palette[part.Name] then
			skins[part.Name] = part
		end
	end
	return { model = model, skins = skins, variant = variant }
end

local function pose(packet, parent, cf, scale)
	if scale < 0.015 then
		packet.model.Parent = nil
		return
	end
	if math.abs((packet.scale or 0) - scale) > math.max(0.035, scale * 0.024) then
		packet.model:ScaleTo(scale)
		packet.scale = scale
	end
	packet.model:PivotTo(cf)
	if packet.model.Parent ~= parent then
		packet.model.Parent = parent
	end
end

local reflectedFire = Color3.fromRGB(255, 193, 105)
local function paint(packet, heat, alpha, crest)
	-- Temperature moves down through orange magma, purple-brown ash and hazy
	-- slate. Emission clings longest to the narrow, carved underside.
	local step = math.floor(heat * 60 + 0.5)
	local fade = math.floor(clamp(alpha, 0, 1) * 70 + 0.5)
	if step == packet.step and fade == packet.fade and crest == packet.crest then
		return
	end
	packet.step, packet.fade, packet.crest = step, fade, crest
	for role, part in packet.skins do
		local p = palette[role]
		part.Color = if heat < 0.33
			then p[1]:Lerp(p[2], heat / 0.33)
			elseif heat < 0.70 then p[2]:Lerp(p[3], (heat - 0.33) / 0.37)
			else p[3]:Lerp(p[4], clamp((heat - 0.70) / 0.30, 0, 1))
		if crest and role ~= "Mantle" then
			-- The whitecap briefly reflects incandescent light onto the hot
			-- faces. Cold ash stays dark behind the orange fold.
			part.Color = part.Color:Lerp(reflectedFire, 0.44 * (1 - S.ease(heat, 0.48, 0.83)))
		end
		part.Material = if (role == "Flame" and heat < 0.66)
				or (role == "Lip" and heat < 0.59)
				or (role == "Fold" and heat < 0.40)
			then Enum.Material.Neon
			elseif heat < 0.56 then Enum.Material.Fabric
			else Enum.Material.Sand
		part.Transparency = fade / 70
	end
end

local fires = {
	{ V(-44, 38.34, -14), 1.15, 1.08, 32 },
	{ V(38, 31.66, -19), 0.84, 1.34, 115 },
	{ V(55, 38.32, 12), 1.58, 1.03, 208 },
	{ V(-65, 48.09, 35), 1.92, 0.89, 101 },
	{ V(-32, 36.25, 54), 1.31, 1.18, 48 },
	{ V(65, 48.91, 80), 2.27, 0.86, 303 },
	{ V(3.4, 26.35, -27), 1.36, 0.86, 68 },
	{ V(-10.5, 26.9, -39.8), 1.68, 0.68, 153 },
}
local lances = {
	{ 0, -0.49, -0.23, 21, 3.55 },
	{ 0.015, 0.10, -0.39, 12, 5.04 },
	{ 0.045, 0.75, 0.26, 37, 3.29 },
	{ 0.08, -0.67, 0.55, 48, 3.21 },
	{ 0.09, 0.86, -0.24, 56, 3.52 },
	{ 0.13, -0.1, 0.7, 22, 4.14 },
	{ 0.25, -0.91, -0.44, 64, 2.76 },
	{ 0.78, 0.79, 0.14, 28, 2.84 },
	{ 0.91, -0.50, 0.7, 32, 2.85 },
}

local function site(root, base, definition, i)
	local point, delay, size, yaw = table.unpack(definition)
	local group = S.group("Scorched ground " .. i)
	local body = sculpt("Jet")
	local coal = S.part(
		group,
		"Landed molten stone",
		CF(),
		V(3.6, 2.55, 3.06) * size,
		"714B48",
		Enum.Material.Slate,
		"WedgePart"
	)
	local lip = S.part(
		group,
		"Melt beneath the stone",
		CF(),
		V(3.36, 0.36, 2.65) * size,
		"DB7742",
		Enum.Material.Neon,
		"WedgePart"
	)
	local crust = S.part(
		group,
		"Split basalt jacket",
		CF(),
		V(2.4, 1.9, 2.6) * size,
		"463848",
		Enum.Material.Slate,
		"CornerWedgePart"
	)
	local scar = S.part(
		group,
		"Red skin between flakes",
		CF(),
		V(0.18 * 0.95, 1.1, 1.75) * size,
		"DF6338",
		Enum.Material.Neon,
		"WedgePart"
	)
	local embers = {}
	for j = 1, 7 do
		embers[j] = Sprite.new(coal, "FireSpecs1 ash spark", Sprite.sparks, 0.06)
	end
	local flames = {}
	for j = 1, 3 do
		flames[j] = Sprite.new(coal, "Flame against the fractured crust", Sprite.flame, 0.06)
	end
	local light = S.light(coal, "FF9440", 16 * size, 1.8)
	local smoke = {}
	for j = 1, 4 do
		smoke[j] = sculpt(if j == 1 then "Curl" else "Roll")
		Vapour.add(smoke[j], i * 4 + j, true)
	end
	return {
		point = point,
		delay = delay,
		size = size,
		yaw = math.rad(yaw),
		group = group,
		coal = coal,
		crust = crust,
		scar = scar,
		lip = lip,
		fire = body,
		smoke = smoke,
		embers = embers,
		flames = flames,
		light = light,
		index = i,
	}
end

local sparkGold, coalRed = Color3.fromHex("FFD393"), Color3.fromHex("E45A39")
local flameGold = Color3.fromHex("FFC475")
local function combustion(site, age, cooling, base)
	if age < 0 or cooling >= 0.90 then
		for _, p in site.embers do
			p.card.Enabled = false
		end
		for _, p in site.flames do
			p.card.Enabled = false
		end
		return
	end
	local heat = (1 - cooling) * S.ease(age, 0, 0.16)
	local orientation = site.coal.CFrame.Rotation:Inverse() * base.Rotation
	for j, p in site.embers do
		local life = 0.64 + 0.09 * ((j + site.index) % 5)
		local u = (age / life + (j * 0.618 + site.index * 0.23)) % 1
		local a = j * 2.40 + site.yaw + u * 0.48
		local offset = orientation
			* V(
				(math.cos(a) * u * 1.15 + 1.36 * u * u) * site.size,
				(0.28 + u * 4.3 + u * u * 1.24) * site.size,
				math.sin(a) * u * 1.32 * site.size
			)
		local w = (0.22 + 0.075 * (j % 3)) * site.size * (1 - 0.45 * u)
		Sprite.draw(
			p,
			offset,
			w,
			w * 1.28,
			math.deg(a) + u * 31,
			sparkGold:Lerp(coalRed, u),
			1 - heat * math.sin(math.pi * u) ^ 0.64
		)
	end
	for j, p in site.flames do
		local u = (age / (0.41 + 0.06 * j) + j / 3 + site.index * 0.21) % 1
		local h = site.size * (if site.index == 7 then 0.96 elseif site.index == 8 then 2.28 else 3.10)
		local a = site.yaw + j * 2.25
		local pos = orientation * V((math.cos(a) * 0.39 + 0.21 * u) * h, (0.23 + 0.55 * u) * h, math.sin(a) * h * 0.28)
		local w = h * (0.79 + 0.34 * u)
		Sprite.draw(
			p,
			pos,
			w,
			w * (1.14 + 0.32 * u),
			9 * math.sin(a + 2 * u),
			flameGold:Lerp(coalRed, 0.43 * u),
			1 - 0.72 * heat * math.sin(math.pi * u) ^ 0.69
		)
	end
end

function Plume.new(root, base, motion)
	tracks = tracks or Http:JSONDecode(script.Parent.BloomPoses.Value)
	local self = setmetatable({ root = root, base = base, packets = {}, jets = {}, sites = {} }, Plume)
	self.craterAir = CraterAir.new(root, base, motion)
	for i, track in tracks do
		self.packets[i] = sculpt(track[1])
		Vapour.add(self.packets[i], i, false)
	end
	for i in lances do
		self.jets[i] = sculpt("Jet")
	end
	for i, definition in fires do
		self.sites[i] = site(root, base, definition, i)
	end
	return self
end

function Plume:draw(age, crest)
	self.craterAir:draw(age)
	if age < 0 or age > 13.3 then
		if not self.hidden then
			for _, p in self.packets do
				p.model.Parent = nil
			end
			for _, p in self.jets do
				p.model.Parent = nil
			end
			for _, v in self.sites do
				v.group.Parent, v.fire.model.Parent = nil, nil
				for _, p in v.smoke do
					p.model.Parent = nil
				end
			end
			self.hidden = true
		end
		return
	end
	if not self.hidden and self.drawing == age and self.crest == crest then
		return
	end
	self.hidden, self.drawing, self.crest = false, age, crest
	local base, root = self.base, self.root
	for i, track in tracks do
		local p = self.packets[i]
		local t = age - track[2]
		if t < 0 or t >= track[3] then
			p.model.Parent = nil
			continue
		end
		local u = t / track[3]
		local index = math.min(#track[4], 1 + math.floor(t * 24))
		local k = track[4][index]
		local at = contact + V(k[1], k[2], k[3])
		pose(p, root, base * CF(at) * CFrame.Angles(k[5], k[6], k[7]), k[4])
		local rear = if k[3] < -4 then 0.37 else -0.065
		local heat = clamp((t - 0.12) / (if rear > 0 then 2.8 else 4.1) + rear + 0.065 * math.sin(i * 2.1), 0, 1)
		local fade = S.ease(u, 0.70, 1)
		paint(p, heat, math.max(0.23 + 0.38 * heat, fade), crest)
		Vapour.draw(p, k[4], heat, fade, t)
	end
	for i, key in lances do
		local jet = self.jets[i]
		local t = age - key[1]
		if t <= 0 or t > 1.84 then
			jet.model.Parent = nil
			continue
		end
		local reach = (1 - math.exp(-7 * t)) * (1 - 0.82 * S.ease(t, 0.63, 1.84))
		local direction = V(key[2], 1.0, key[3]).Unit
		local angle = math.rad(key[4])
		direction = V(
			math.sin(angle) * V(direction.X, 0, direction.Z).Unit.X,
			math.cos(angle),
			math.sin(angle) * V(direction.X, 0, direction.Z).Unit.Z
		)
		local orient = CFrame.fromMatrix(Vector3.zero, direction:Cross(Vector3.zAxis).Unit, direction)
		local feet = direction * (key[5] * 4.3 * reach) + V(0, 1.4, 0)
		pose(jet, root, base * CF(contact + feet) * orient * CFrame.Angles(0, i * 0.95, 0), key[5] * reach * 0.68)
		paint(jet, clamp(0.18 + t * 0.32, 0, 0.70), S.ease(t, 1.08, 1.84))
	end
	for _, v in self.sites do
		-- Each hot shard follows a complete arc from the vent to a measured
		-- terrain point. Its ground fire starts on contact and dwindles in rain.
		local lift = 0.13 + 0.025 * v.index
		local flight = clamp((age - lift) / (v.delay - lift), 0, 1)
		local above = (25 + 5.2 * v.index) * 4 * flight * (1 - flight)
		local pos = contact:Lerp(v.point, flight) + V(0, above + v.size * 0.72, 0)
		local seated = age >= v.delay
		local cool = S.ease(age, 7.45 + 0.1 * v.index, 9.55 + 0.10 * v.index)
		v.group.Parent = if age >= lift and age < 13.2 then root else nil
		v.coal.CFrame = base * CF(pos) * CFrame.Angles(1.7 * flight, v.yaw + 4.7 * flight, 2.0 * flight)
		v.lip.CFrame = v.coal.CFrame * CF(0, -1.0 * v.size, 0)
		v.lip.Transparency = cool
		v.crust.CFrame = v.coal.CFrame
			* CF(-0.56 * v.size, 0.31 * v.size, 0.39 * v.size)
			* CFrame.Angles(0.19, -0.37, 0.34)
		v.scar.CFrame = v.coal.CFrame
			* CF(0.39 * v.size, 0.46 * v.size, 0.37 * v.size)
			* CFrame.Angles(0.15, 0.18, -0.46)
		v.scar.Transparency = 0.17 + 0.83 * cool
		v.light.Brightness = (1 - cool) * (1.3 + 0.18 * math.sin(age * 4.2 + v.index))
		local fireTime = age - v.delay
		combustion(v, fireTime, cool, base)
		if seated and cool < 0.995 then
			local flick = math.floor(fireTime * 12) / 12
			local amplitude = (0.5 + 0.13 * math.sin(6 * flick + v.index) + 0.09 * math.sin(10 * flick + v.index))
				* v.size
				* (1 - cool)
				* S.ease(fireTime, 0, 0.24)
			local cf = base
				* CF(v.point + V(0.35, 2.9 * amplitude, 0))
				* CFrame.Angles(0, v.yaw + 0.18 * math.sin(flick * 4), -0.09)
			pose(v.fire, root, cf, amplitude * (if v.index == 7 then 0.12 elseif v.index == 8 then 0.45 else 0.65))
			paint(v.fire, 0.31 + 0.06 * math.sin(flick * 5), 0.3)
		else
			v.fire.model.Parent = nil
		end
		for j, puff in v.smoke do
			local start = (j - 1) * 0.81 + 0.12
			local a = fireTime - start
			if a < 0 then
				puff.model.Parent = nil
				continue
			end
			local life = 3.38 + 0.027 * v.index
			local tick = a % life
			local u = tick / life
			local emissionTime = age - tick
			if emissionTime > 8.80 + 0.11 * v.index or age > 11.85 then
				puff.model.Parent = nil
				continue
			end
			local near = v.index >= 7
			local wind = V(
				(if near then -2.2 else 7.0) * u + (if near then -5.4 else 14.0) * u * u,
				(if near then 1.8 else 4.3) + u * (if near then 9 else 34 + 2 * v.index),
				-3.1 * u - 4.2 * u * u
			)
			local scale = v.size * (0.22 + 0.84 * u) * (0.84 + 0.12 * math.sin(j * 2)) + u * 0.21
			local cf = base
				* CF(v.point + wind)
				* CFrame.Angles(0.22 * u, v.yaw + j * 1.33 + 0.75 * u, 0.17 * math.sin(j + u))
			pose(puff, root, cf, scale * (if v.index >= 7 then 0.46 else 1.24))
			local fade = math.max(1 - S.ease(u, 0, 0.16), S.ease(u, 0.47, 1), S.ease(age, 9.55, 11.72))
			paint(puff, 0.76 + 0.22 * u, math.max(if near then 0.88 else 0.79 + 0.12 * u, fade))
			Vapour.draw(puff, scale * (if near then 0.53 else 1.40), 0.78 + 0.20 * u, fade, tick)
		end
	end
end

function Plume:Destroy()
	self.craterAir.anchor:Destroy()
	for _, p in self.packets do
		p.model:Destroy()
	end
	for _, p in self.jets do
		p.model:Destroy()
	end
	for _, v in self.sites do
		v.group:Destroy()
		v.fire.model:Destroy()
		for _, p in v.smoke do
			p.model:Destroy()
		end
	end
end
return Plume
