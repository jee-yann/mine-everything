-- How cosmetics look, shared by the server (what everyone sees) and the client (previews):
-- player auras, player-trail ribbons and the streak a mining trail leaves on the pickaxe's swing.
--
-- Every look is built from particle textures out of the VFX pack (public image assets, so nothing
-- needs uploading; see `textures`), plus Roblox's own fire and smoke. Rarer looks get more layers:
--   all         a coloured streak in the look's full palette, tapering as it fades
--   Uncommon+   sparkles shed along it
--   Rare+       a themed layer (embers, frost, petals, sparks or star twinkles)
--   Epic+       a bright core down the middle of the streak
--   Legendary+  a soft glow that follows it
--   Mythic+     a turning vortex and the odd shockwave ring
-- Colours stay saturated (low LightEmission) so they read against a bright sky instead of washing out
-- to white; only the core and the glow are additive.
local C = require(script.Parent.Collectibles)
local Looks = {}
local rgb = Color3.fromRGB
local white = Color3.new(1, 1, 1)

-- From the VFX pack (Workspace of build/Shop-Pets-VFX.rbxlx). Those on a black background are drawn
-- additively (LightEmission 1), so the black disappears.
local textures = {
	star = "rbxassetid://4963436775", -- a clean four-point star
	glint = "rbxassetid://10598374841", -- a thin cross glint
	sparkle = "rbxassetid://1084970835", -- a big soft four-point sparkle (black background)
	glow = "rbxassetid://4509687978", -- a soft round glow
	flare = "rbxassetid://14684195806", -- a horizontal lens streak
	rays = "rbxassetid://1084975295", -- a burst of light rays (black background)
	vortex = "rbxassetid://6700005265", -- a swirl
	ring = "rbxassetid://8271495905", -- a soft ring of light
	boltRing = "rbxassetid://7150933366", -- a crackling ring
	shards = "rbxassetid://10439119562", -- an ice shard
	embers = "rbxassetid://11187840108", -- a hot spark
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	square = "rbxasset://textures/particles/SquareParticle.png",
}
Looks.textures = textures

-- Full palettes for looks with more than two colours. The catalogue's two `colors` are the fallback.
Looks.palettes = {
	Verdant = { rgb(200, 255, 150), rgb(60, 210, 110), rgb(20, 140, 100) },
	Sakura = { rgb(255, 240, 246), rgb(255, 170, 205), rgb(255, 100, 160) },
	Aurora = { rgb(110, 255, 200), rgb(80, 200, 255), rgb(150, 110, 255), rgb(235, 120, 255) },
	Comet = { rgb(255, 255, 240), rgb(255, 228, 130), rgb(255, 160, 60), rgb(110, 160, 255) },
	Thunder = { rgb(255, 255, 210), rgb(255, 238, 80), rgb(140, 180, 255), rgb(90, 100, 255) },
	Solar = { rgb(255, 250, 190), rgb(255, 200, 50), rgb(255, 120, 30), rgb(225, 40, 40) },
	Inferno = { rgb(255, 230, 110), rgb(255, 130, 30), rgb(225, 40, 25), rgb(110, 15, 45) },
	Rift = { rgb(245, 235, 255), rgb(190, 140, 255), rgb(120, 60, 255), rgb(255, 100, 220) },
	Galaxy = { rgb(120, 225, 255), rgb(90, 120, 255), rgb(170, 80, 255), rgb(255, 90, 215), rgb(255, 205, 240) },
	Celestial = { rgb(255, 245, 190), rgb(255, 210, 110), rgb(130, 250, 225), rgb(100, 180, 255) },
	Sunset = { rgb(255, 222, 110), rgb(255, 145, 80), rgb(255, 80, 135) },
	Candy = { rgb(255, 170, 225), rgb(255, 245, 250), rgb(130, 215, 255) },
	EmberRibbon = { rgb(255, 222, 100), rgb(255, 130, 35), rgb(220, 35, 30) },
	Starlight = { rgb(255, 252, 225), rgb(190, 215, 255), rgb(110, 160, 255), rgb(200, 150, 255) },
	AuroraRibbon = { rgb(110, 255, 205), rgb(90, 200, 255), rgb(185, 115, 255), rgb(255, 135, 225) },
	Void = { rgb(215, 160, 255), rgb(130, 60, 235), rgb(60, 25, 130), rgb(255, 90, 200) },
	Prism = { rgb(255, 70, 90), rgb(255, 165, 40), rgb(255, 238, 60), rgb(70, 225, 110), rgb(50, 195, 255), rgb(130, 95, 255), rgb(255, 85, 200) },
	Halo = { rgb(255, 250, 220), rgb(255, 222, 140), rgb(255, 190, 90) },
	Sunburst = { rgb(255, 240, 150), rgb(255, 185, 50), rgb(255, 110, 40) },
	Nebula = { rgb(205, 140, 255), rgb(110, 90, 255), rgb(255, 115, 220) },
	FounderHalo = { rgb(255, 225, 140), rgb(255, 150, 60), rgb(255, 85, 95) },
}
-- The themed layer each look throws. Everything not listed twinkles with stars.
local themes = {
	Copper = "fire", Ember = "fire", Solar = "fire", Inferno = "fire", EmberRibbon = "fire", Embers = "fire", Sunburst = "fire",
	Frost = "frost", Mist = "frost", Starlight = "frost",
	Moss = "leaf", Verdant = "leaf", Sakura = "leaf", Leaves = "leaf", Candy = "leaf",
	Thunder = "bolt", Sparks = "bolt",
}

local function nums(...)
	local points = {}
	for i, pair in { ... } do points[i] = NumberSequenceKeypoint.new(pair[1], pair[2]) end
	return NumberSequence.new(points)
end

function Looks.palette(entry)
	return Looks.palettes[entry.id] or C.colors(entry)
end
function Looks.rank(entry)
	return math.min(C.rarities[entry.rarity].rank, 7)
end
function Looks.theme(entry)
	return themes[entry.id] or "star"
end

-- The whole palette as one colour sequence, end to end.
function Looks.sequence(entry)
	local colors = Looks.palette(entry)
	if #colors == 1 then return ColorSequence.new(colors[1]) end
	if #colors == 2 then
		local a, b = colors[1], colors[2]
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, a),
			ColorSequenceKeypoint.new(0.5, a:Lerp(b, 0.5)),
			ColorSequenceKeypoint.new(1, b),
		})
	end
	local points = {}
	for i, color in colors do
		points[i] = ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color)
	end
	return ColorSequence.new(points)
end

local function emitter(name, texture, color, parent, mark, made)
	local e = Instance.new("ParticleEmitter")
	e.Name, e.Texture, e.Color = name, texture, color
	e.LightEmission, e.LightInfluence = 1, 0
	mark(e)
	table.insert(made, e)
	e.Parent = parent
	return e
end

-- The themed layer, Rare and up.
local function themed(entry, at, scale, mark, made)
	local theme, seq, r = Looks.theme(entry), Looks.sequence(entry), Looks.rank(entry)
	local e
	if theme == "fire" then
		e = emitter("Streak embers", textures.embers, seq, at, mark, made)
		e.Size = nums({ 0, 0.35 * scale }, { 1, 0 })
		e.Lifetime, e.Speed, e.Rate = NumberRange.new(0.4, 0.8), NumberRange.new(1, 3), 4 + 3 * r
		e.Acceleration, e.SpreadAngle, e.Drag = Vector3.new(0, 6, 0), Vector2.new(60, 60), 1
	elseif theme == "frost" then
		e = emitter("Streak frost", textures.shards, ColorSequence.new(white, Looks.palette(entry)[2] or white), at, mark, made)
		e.Size = nums({ 0, 0.4 * scale }, { 1, 0.05 })
		e.Lifetime, e.Speed, e.Rate = NumberRange.new(0.6, 1.1), NumberRange.new(0.2, 0.8), 3 + 3 * r
		e.Acceleration, e.SpreadAngle, e.Drag = Vector3.new(0, -2, 0), Vector2.new(180, 180), 2
		e.RotSpeed = NumberRange.new(-120, 120)
	elseif theme == "leaf" then
		e = emitter("Streak petals", textures.square, seq, at, mark, made)
		e.LightEmission = 0.2
		e.Size = nums({ 0, 0.16 * scale }, { 1, 0.1 * scale })
		e.Lifetime, e.Speed, e.Rate = NumberRange.new(0.8, 1.4), NumberRange.new(0.5, 1.5), 2 + 2 * r
		e.Acceleration, e.SpreadAngle, e.Drag = Vector3.new(0, -3, 0), Vector2.new(180, 180), 1.5
		e.Rotation, e.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-260, 260)
	elseif theme == "bolt" then
		e = emitter("Streak bolts", textures.glint, seq, at, mark, made)
		e.Size = nums({ 0, 0.5 * scale }, { 0.2, 0.25 * scale }, { 1, 0 })
		e.Lifetime, e.Speed, e.Rate = NumberRange.new(0.08, 0.18), NumberRange.new(4, 9), 8 + 4 * r
		e.SpreadAngle = Vector2.new(180, 180)
	else
		e = emitter("Streak stars", textures.sparkle, seq, at, mark, made)
		e.Size = nums({ 0, 0 }, { 0.3, 0.6 * scale }, { 1, 0 })
		e.Lifetime, e.Speed, e.Rate = NumberRange.new(0.5, 0.9), NumberRange.new(0.1, 0.6), 2 + 2 * r
		e.SpreadAngle, e.RotSpeed = Vector2.new(180, 180), NumberRange.new(-180, 180)
	end
	return e
end

-- The streak a look leaves behind a moving pair of attachments `a` and `b` (the swing of a pickaxe, a
-- walking miner, a try-on spark). `options`: name (of the main trail), lifetime, scale. Returns
-- everything made, each also passed to `mark`.
function Looks.streak(entry, a, b, mark, options)
	options = options or {}
	local scale = options.scale or 1
	local r = Looks.rank(entry)
	local palette = Looks.palette(entry)
	local seq = Looks.sequence(entry)
	local made = {}
	local lifetime = options.lifetime or (0.4 + 0.05 * r)
	local body = Instance.new("Trail")
	body.Name, body.Attachment0, body.Attachment1 = options.name or "Streak", a, b
	body.Color, body.FaceCamera, body.MinLength = seq, true, 0.1
	body.LightEmission, body.LightInfluence = 0.15 + 0.04 * r, 0
	body.Brightness = 1.3 + 0.25 * r
	body.Transparency = nums({ 0, 0.02 }, { 0.55, 0.35 }, { 1, 1 })
	body.WidthScale = nums({ 0, 1 }, { 1, 0.3 })
	body.Lifetime = lifetime
	mark(body)
	table.insert(made, body)
	body.Parent = a.Parent
	if r >= 4 then
		local core = Instance.new("Trail")
		core.Name, core.Attachment0, core.Attachment1 = "Streak core", a, b
		core.Color = ColorSequence.new(white, palette[1]:Lerp(white, 0.3))
		core.FaceCamera, core.LightEmission, core.LightInfluence = true, 1, 0
		core.Brightness = 2 + 0.3 * r
		core.Transparency = nums({ 0, 0.15 }, { 1, 1 })
		core.WidthScale = nums({ 0, 0.32 }, { 1, 0.04 })
		core.Lifetime = lifetime * 0.55
		mark(core)
		table.insert(made, core)
		core.Parent = a.Parent
	end
	if r >= 2 then
		local sparks = emitter("Streak sparks", textures.star, seq, a, mark, made)
		sparks.Size = nums({ 0, (0.2 + 0.04 * r) * scale }, { 1, 0 })
		sparks.RotSpeed = NumberRange.new(-120, 120)
		sparks.Lifetime, sparks.Speed, sparks.Rate = NumberRange.new(0.3, 0.7), NumberRange.new(0.3, 1.6), 3 + 3 * r
		sparks.SpreadAngle, sparks.Drag = Vector2.new(180, 180), 2
	end
	if r >= 3 then themed(entry, b, scale, mark, made) end
	if r >= 5 then
		local glow = emitter("Streak glow", textures.glow, seq, a, mark, made)
		glow.Size = nums({ 0, 0.9 * scale }, { 1, 0.5 * scale })
		glow.Transparency = nums({ 0, 0.55 }, { 1, 1 })
		glow.Lifetime, glow.Speed, glow.Rate = NumberRange.new(0.25, 0.4), NumberRange.new(0), 14
		glow.LockedToPart = false
		local flare = emitter("Streak flare", textures.flare, seq, a, mark, made)
		flare.Size = nums({ 0, 1.6 * scale }, { 1, 0.4 * scale })
		flare.Transparency = nums({ 0, 0.2 }, { 1, 1 })
		flare.Lifetime, flare.Speed, flare.Rate = NumberRange.new(0.15, 0.25), NumberRange.new(0), 6
		flare.Rotation = NumberRange.new(-25, 25)
	end
	if r >= 6 then
		local vortex = emitter("Streak vortex", textures.vortex, ColorSequence.new(palette[#palette], palette[1]), b, mark, made)
		vortex.Size = nums({ 0, 0.4 * scale }, { 1, 1.4 * scale })
		vortex.Transparency = nums({ 0, 0.35 }, { 1, 1 })
		vortex.Lifetime, vortex.Speed, vortex.Rate = NumberRange.new(0.45, 0.6), NumberRange.new(0), 5
		vortex.RotSpeed, vortex.Rotation = NumberRange.new(260, 360), NumberRange.new(0, 360)
		local ring = emitter("Streak ring", if Looks.theme(entry) == "bolt" then textures.boltRing else textures.ring, seq, a, mark, made)
		ring.Size = nums({ 0, 0.2 * scale }, { 1, 2.2 * scale })
		ring.Transparency = nums({ 0, 0.3 }, { 1, 1 })
		ring.Lifetime, ring.Speed, ring.Rate = NumberRange.new(0.45), NumberRange.new(0), 1.2
	end
	return made
end

-- A player aura: layers of particles in an invisible holder part. `look` comes from the catalogue.
function Looks.aura(parent, id, scale)
	local aura = C.auraById[id]
	if not aura then return nil end
	scale = scale or 1
	local holder = Instance.new("Part")
	holder.Name, holder.Transparency, holder.Massless = "Aura " .. aura.id, 1, true
	holder.CanCollide, holder.CanTouch, holder.CanQuery = false, false, false
	holder.Size = if aura.look == "halo" then Vector3.new(1.4, 0.05, 1.4) * scale
		elseif aura.look == "ring" then Vector3.new(3.2, 0.2, 3.2) * scale
		else Vector3.new(2.2, 3, 2.2) * scale
	local made = {}
	local function keep() end
	local seq = Looks.sequence(aura)
	local emitterMain = emitter("Aura", textures.star, seq, holder, keep, made)
	emitterMain.RotSpeed = NumberRange.new(-90, 90)
	emitterMain.LockedToPart = true
	if aura.look == "ring" then
		emitterMain.Size = nums({ 0, 0.55 * scale }, { 1, 0 })
		emitterMain.Rate, emitterMain.Lifetime, emitterMain.Speed = 22, NumberRange.new(0.8, 1.2), NumberRange.new(0.1)
		emitterMain.RotSpeed = NumberRange.new(-90, 90)
	elseif aura.look == "embers" then
		emitterMain.Texture = textures.fire
		emitterMain.LightEmission = 0.35
		emitterMain.Size = nums({ 0, 0.95 * scale }, { 1, 0.1 * scale })
		emitterMain.Transparency = nums({ 0, 0.1 }, { 1, 1 })
		emitterMain.Rate, emitterMain.Lifetime, emitterMain.Speed = 24, NumberRange.new(0.8, 1.4), NumberRange.new(1, 2)
		emitterMain.Acceleration, emitterMain.SpreadAngle = Vector3.new(0, 2, 0), Vector2.new(20, 20)
		emitterMain.EmissionDirection = Enum.NormalId.Top
	elseif aura.look == "halo" then
		emitterMain.Size = nums({ 0, 0.36 * scale }, { 1, 0 })
		emitterMain.Rate, emitterMain.Lifetime, emitterMain.Speed = 30, NumberRange.new(0.6, 1), NumberRange.new(0)
	else
		emitterMain.Texture = textures.smoke
		emitterMain.LightEmission = 0.25
		emitterMain.Size = nums({ 0, 0.6 * scale }, { 0.5, 1.8 * scale }, { 1, 0 })
		emitterMain.Transparency = nums({ 0, 0.3 }, { 0.6, 0.45 }, { 1, 1 })
		emitterMain.Rate, emitterMain.Lifetime, emitterMain.Speed = 12, NumberRange.new(1.5, 2.2), NumberRange.new(0.3, 0.6)
		emitterMain.RotSpeed, emitterMain.SpreadAngle = NumberRange.new(-40, 40), Vector2.new(180, 180)
	end
	local r = Looks.rank(aura)
	if r >= 3 then
		local motes = emitter("Aura motes", textures.sparkle, seq, holder, keep, made)
		motes.RotSpeed = NumberRange.new(-60, 60)
		motes.Size = nums({ 0, 0 }, { 0.4, 0.45 * scale }, { 1, 0 })
		motes.Lifetime, motes.Speed, motes.Rate = NumberRange.new(0.8, 1.4), NumberRange.new(0.2, 0.6), 4 + 3 * r
		motes.SpreadAngle, motes.Acceleration = Vector2.new(180, 180), Vector3.new(0, 1, 0)
	end
	if r >= 5 then
		local glow = emitter("Aura glow", textures.glow, seq, holder, keep, made)
		glow.LockedToPart = true
		glow.Size = nums({ 0, (if aura.look == "halo" then 1.6 else 2.4) * scale }, { 1, (if aura.look == "halo" then 2 else 3) * scale })
		glow.Transparency = nums({ 0, 0.85 }, { 0.5, 0.72 }, { 1, 1 })
		glow.Lifetime, glow.Speed, glow.Rate = NumberRange.new(1, 1.3), NumberRange.new(0), 2.5
	end
	if r >= 6 then
		local palette = Looks.palette(aura)
		local vortex = emitter("Aura vortex", textures.vortex, ColorSequence.new(palette[1], palette[#palette]), holder, keep, made)
		vortex.LockedToPart = true
		vortex.Size = nums({ 0, 2 * scale }, { 1, 2.8 * scale })
		vortex.Transparency = nums({ 0, 0.5 }, { 1, 1 })
		vortex.Lifetime, vortex.Speed, vortex.Rate = NumberRange.new(1.2), NumberRange.new(0), 2.4
		vortex.RotSpeed, vortex.Rotation = NumberRange.new(60, 120), NumberRange.new(0, 360)
		local rays = emitter("Aura rays", textures.rays, seq, holder, keep, made)
		rays.LockedToPart = true
		rays.Size = nums({ 0, (if aura.look == "halo" then 1.8 else 2.6) * scale }, { 1, (if aura.look == "halo" then 2.2 else 3) * scale })
		rays.Transparency = nums({ 0, 0.9 }, { 0.5, 0.78 }, { 1, 1 })
		rays.Lifetime, rays.Speed, rays.Rate = NumberRange.new(1.4), NumberRange.new(0), 1.2
		rays.RotSpeed, rays.Rotation = NumberRange.new(-30, 30), NumberRange.new(0, 360)
	end
	-- A halo or ring lies flat: a soft ring of light turns slowly around it.
	if aura.look == "halo" or aura.look == "ring" then
		local band = emitter("Aura band", textures.ring, seq, holder, keep, made)
		band.LockedToPart = true
		band.Orientation, band.EmissionDirection = Enum.ParticleOrientation.VelocityPerpendicular, Enum.NormalId.Top
		band.Size = nums({ 0, (if aura.look == "halo" then 1.1 else 2.2) * scale }, { 1, (if aura.look == "halo" then 1.3 else 2.8) * scale })
		band.Transparency = nums({ 0, 0.85 }, { 0.5, 0.45 }, { 1, 1 })
		band.Lifetime, band.Speed, band.Rate = NumberRange.new(1.2), NumberRange.new(0.01), 2
	end
	holder.Parent = parent
	return holder, aura.look
end

-- Where an aura sits on a miner, from the root.
function Looks.auraOffset(look)
	return if look == "halo" then CFrame.new(0, 2.7, 0) elseif look == "ring" then CFrame.new(0, -2.6, 0) else CFrame.identity
end

-- A player trail on `root`: two attachments and the look's streak between them. Every instance made is
-- passed to `mark` (to tag it, or to clean it up later). The main trail is named "Trail ribbon".
function Looks.ribbon(root, id, mark)
	local entry = C.ribbonById[id or ""]
	if not entry then return nil end
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Name, b.Name = "Ribbon top", "Ribbon bottom"
	a.Position, b.Position = Vector3.new(-0.8, 0.9, 0.6), Vector3.new(0.8, -0.9, 0.6)
	mark(a)
	mark(b)
	a.Parent, b.Parent = root, root
	local made = Looks.streak(entry, a, b, mark, { name = "Trail ribbon", lifetime = 0.5 + 0.06 * Looks.rank(entry) })
	return made[1]
end

return Looks
