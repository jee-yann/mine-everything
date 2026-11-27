-- A live preview of an effect, drawn in the UI with the same VFX-pack textures and colours the effect
-- uses in the world (particles can't be shown inside a ViewportFrame, so this redraws the idea):
--   Mining FX   the pickaxe's swing as it really looks: a small pick chopping fast, every stroke from
--               a different direction and angle (like the real swing seen in 3D), its head sweeping
--               a wide band (the trail runs between the two ends of the head, so it's a surface,
--               not a line), the strokes overlapping as they fade, white-hot core for Epic and up
--   Player FX   a trail: a straight ribbon flowing from a glowing point, as from a miner moving in a
--               straight line, tapering and fading, with glints travelling along it
--               an aura: a pulsing glow, a turning ring of light and stars circling it
-- The trails are drawn as a band of short rounded segments along the recent path, with the same
-- lifetime, taper and fade the world's Trail uses (CosmeticLooks).
-- Rarer effects get their themed bits (embers rise, frost falls, petals drift, sparks flicker, stars
-- twinkle), a brighter head, a glow and, for Mythic and up, a turning swirl, just like in the world.
-- Previews only animate while they're on screen. `live = false` draws a still frame (the crate reel).
local Shared = game:GetService("ReplicatedStorage").Shared
local Run = game:GetService("RunService")
local C, Looks = require(Shared.Collectibles), require(Shared.CosmeticLooks)
local Preview = {}
local white = Color3.new(1, 1, 1)
local rgb = Color3.fromRGB
local live = {}

-- Only textures with a transparent background: UI images can't blend additively the way particles
-- do, so the pack's black-background ones (the soft sparkle, the light rays) would show as squares.
local textures = {
	dot = Looks.textures.glow,
	star = Looks.textures.star,
	sparkle = Looks.textures.star,
	ring = Looks.textures.ring,
	swirl = Looks.textures.vortex,
	ember = Looks.textures.embers,
	shard = Looks.textures.shards,
	glint = Looks.textures.glint,
}
local themeBits = { fire = "ember", frost = "shard", leaf = "dot", bolt = "glint", star = "sparkle" }

local function image(parent, name, texture, size, color, z)
	local i = Instance.new("ImageLabel")
	i.Name, i.BackgroundTransparency, i.Image = name, 1, texture
	i.AnchorPoint, i.Size, i.ImageColor3, i.ZIndex = Vector2.new(0.5, 0.5), UDim2.fromOffset(size, size), color or white, z or 4
	i.Parent = parent
	return i
end

-- A colour from the palette at `t` (0 to 1).
local function sample(palette, t)
	if #palette == 1 then return palette[1] end
	local x = math.clamp(t, 0, 1) * (#palette - 1)
	local i = math.floor(x)
	if i >= #palette - 1 then return palette[#palette] end
	return palette[i + 1]:Lerp(palette[i + 2], x - i)
end

-- Is this preview on screen? (its own Visible, every ancestor's, and its ScreenGui enabled)
local function shown(frame)
	local at = frame
	while at do
		if at:IsA("LayerCollector") then return at.Enabled end
		if at:IsA("GuiObject") and not at.Visible then return false end
		at = at.Parent
	end
	return false
end

-- Draws `kind`/`id` into a new square frame of `size` at x, y. Returns the frame.
function Preview.new(parent, kind, id, x, y, size, animate)
	local entry = C.find(kind, id)
	local frame = Instance.new("Frame")
	frame.Name, frame.BackgroundTransparency = "Preview", 1
	frame.Position, frame.Size, frame.ZIndex = UDim2.fromOffset(x, y), UDim2.fromOffset(size, size), 3
	frame.Parent = parent
	if not entry then return frame end
	local palette = Looks.palette(entry)
	local rank = Looks.rank(entry)
	local theme = Looks.theme(entry)
	local s = size / 100
	-- Each preview its own place in the swing and a slightly different tempo, so they never move in step.
	local parts = { frame = frame, kind = kind, palette = palette, rank = rank, size = size, s = s,
		seed = math.random() * 100, tempo = 0.9 + 0.2 * math.random() }
	if rank >= 6 then
		parts.swirl = image(frame, "Swirl", textures.swirl, 96 * s, palette[#palette], 2)
		parts.swirl.Position, parts.swirl.ImageTransparency = UDim2.fromScale(0.5, 0.5), 0.35
	end
	if rank >= 5 then
		parts.glow = image(frame, "Glow", textures.dot, 110 * s, palette[1], 2)
		parts.glow.Position, parts.glow.ImageTransparency = UDim2.fromScale(0.5, 0.5), 0.55
	end
	if kind == "aura" then
		parts.core = image(frame, "Core", textures.dot, 70 * s, palette[1], 3)
		parts.core.Position = UDim2.fromScale(0.5, 0.5)
		parts.ring = image(frame, "Ring", textures.ring, 92 * s, white, 3)
		parts.ring.Position = UDim2.fromScale(0.5, 0.5)
		local band = Instance.new("UIGradient")
		band.Color, band.Parent = Looks.sequence(entry), parts.ring
		parts.band = band
		parts.orbit = {}
		for i = 1, 4 + rank do
			parts.orbit[i] = image(frame, "Star", textures.star, (10 + rank) * s, sample(palette, i / (4 + rank)), 5)
		end
		-- The showpiece auras' signatures, as in the world (CosmeticLooks): halos raise a shaft of light,
		-- the Founder's Halo adds its rose ring and wings, Sunburst a turning sun, Nebula drifting clouds.
		local function bar(name, w, h, color, z)
			local f = Instance.new("Frame")
			f.Name, f.BorderSizePixel, f.BackgroundColor3, f.ZIndex = name, 0, color, z
			f.Size = UDim2.fromOffset(w, h)
			local round = Instance.new("UICorner")
			round.CornerRadius, round.Parent = UDim.new(0.5, 0), f
			f.Parent = frame
			return f
		end
		if entry.id == "Halo" or entry.id == "FounderHalo" then
			parts.shaft = bar("Shaft", 16 * s, 58 * s, white:Lerp(palette[1], 0.4), 2)
			parts.shaft.AnchorPoint, parts.shaft.Position = Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0.5)
			local fade = Instance.new("UIGradient")
			fade.Rotation, fade.Parent = 90, parts.shaft
			fade.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0.55),
				NumberSequenceKeypoint.new(1, 0.35) })
		end
		if entry.id == "FounderHalo" then
			parts.outer = image(frame, "Outer ring", textures.ring, 108 * s, palette[3]:Lerp(Color3.new(0, 0, 0), 0.15), 3)
			parts.outer.Position = UDim2.fromScale(0.5, 0.5)
			parts.wings = {}
			for _, side in { -1, 1 } do
				for k = 1, 4 do
					-- A UI element turns about its own centre, so each feather hangs off a pivot at the wing root.
					local pivot = Instance.new("Frame")
					pivot.Name, pivot.BackgroundTransparency, pivot.ZIndex = "Wing pivot", 1, 2
					pivot.Position, pivot.Size, pivot.Parent = UDim2.fromScale(0.5 + side * 0.04, 0.6), UDim2.fromOffset(0, 0), frame
					local feather = bar("Wing", (58 - 7 * k) * s, 8 * s, white, 2)
					feather.Parent, feather.Position = pivot, UDim2.fromOffset(0, 0)
					feather.AnchorPoint = Vector2.new(if side == 1 then 0 else 1, 0.5)
					-- Pale gold fading to rose, solid enough to stand out on the offer's orange card.
					local paint = Instance.new("UIGradient")
					paint.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, white), ColorSequenceKeypoint.new(0.5, white:Lerp(palette[1], 0.6)),
						ColorSequenceKeypoint.new(1, palette[3]) })
					paint.Transparency = NumberSequence.new(0, 0.3)
					paint.Rotation, paint.Parent = if side == 1 then 0 else 180, feather
					table.insert(parts.wings, { frame = pivot, side = side, k = k })
				end
			end
		elseif entry.id == "Sunburst" then
			local sun = Instance.new("Frame")
			sun.Name, sun.BackgroundTransparency, sun.AnchorPoint = "Sun", 1, Vector2.new(0.5, 0.5)
			sun.Position, sun.Size, sun.ZIndex, sun.Parent = UDim2.fromScale(0.5, 0.46), UDim2.fromOffset(0, 0), 1, frame
			-- Rays through the centre, bright in the middle and fading out at both ends.
			for i = 1, 8 do
				local ray = bar("Ray", 100 * s, 5 * s, palette[1], 1)
				ray.Parent, ray.AnchorPoint, ray.Position = sun, Vector2.new(0.5, 0.5), UDim2.fromOffset(0, 0)
				ray.Rotation = i * 180 / 8
				local taper = Instance.new("UIGradient")
				taper.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.45),
					NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(0.7, 0.45), NumberSequenceKeypoint.new(1, 1) })
				taper.Parent = ray
			end
			parts.sun = sun
		elseif entry.id == "Nebula" then
			parts.clouds = {}
			for i = 1, 3 do
				local cloud = image(frame, "Cloud", textures.dot, 64 * s, palette[i], 1)
				cloud.ImageTransparency = 0.35
				parts.clouds[i] = cloud
			end
		end
	else
		-- The band: segments along the recent path. A core rides down the middle for Epic and up.
		local ribbon = kind == "ribbon"
		-- Common and Uncommon Mining FX are plain in the game (CosmeticLooks.streak), so here too: no
		-- bright core, no sparkles, a small dot at the tip.
		local plainTrail = not ribbon and rank <= 2
		local count = if ribbon then 24 else 20
		parts.lifetime = if ribbon then 0.5 + 0.06 * rank else 0.16 + 0.025 * rank
		parts.band, parts.core = {}, {}
		local function segment(name, z)
			local seg = Instance.new("Frame")
			seg.Name, seg.BorderSizePixel, seg.AnchorPoint, seg.ZIndex = name, 0, Vector2.new(0.5, 0.5), z
			local round = Instance.new("UICorner")
			round.CornerRadius, round.Parent = UDim.new(0.5, 0), seg
			seg.Parent = frame
			return seg
		end
		for i = 1, count do
			local fade = (i - 1) / (count - 1)
			local seg = segment("Band", 3)
			seg.BackgroundColor3 = sample(palette, fade)
			parts.band[i] = seg
			if (rank >= 4 or not ribbon) and not plainTrail then
				local core = segment("Core", 4)
				core.BackgroundColor3 = white:Lerp(palette[1], 0.15 + 0.6 * fade)
				parts.core[i] = core
			end
		end
		-- The tip: a bright star for Mining FX, the miner's glow for Player FX.
		parts.head = image(frame, "Head", if ribbon or plainTrail then textures.dot else textures.star,
			(if ribbon then 30 elseif plainTrail then 9 else 12 + 2 * rank) * s, if plainTrail then palette[1] else white, 6)
		if ribbon then
			-- Glints travelling along the ribbon, so it reads as flowing.
			parts.flow = {}
			for i = 1, 3 do
				parts.flow[i] = image(frame, "Flow", textures.star, 12 * s, white:Lerp(palette[math.min(#palette, i)], 0.3), 5)
			end
		else
			-- The pick: a handle from the hand to the head, and the head across it.
			parts.handle = segment("Handle", 5)
			parts.handle.BackgroundColor3 = rgb(150, 92, 50)
			parts.pickHead = segment("Pick head", 6)
			parts.pickHead.BackgroundColor3 = rgb(205, 212, 228)
			parts.pickHead:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.4, 0)
		end
	end
	-- Themed bits for Rare and up (Uncommon gets a couple of plain sparkles).
	if rank >= (if kind == "trail" then 3 else 2) then
		parts.bits = {}
		local n = if rank >= 3 then 3 + rank else 2
		local texture = textures[if rank >= 3 then themeBits[theme] else "star"]
		for i = 1, n do
			parts.bits[i] = image(frame, "Bit", texture, (if theme == "leaf" then 9 else 13) * s, sample(palette, i / n), 5)
		end
	end
	parts.theme = theme
	Preview.draw(parts, if animate == false then 0.5 else os.clock())
	if animate ~= false then
		table.insert(live, parts)
		frame.Destroying:Once(function()
			local at = table.find(live, parts)
			if at then table.remove(live, at) end
		end)
	end
	return frame
end

local function place(item, x, y)
	item.Position = UDim2.fromScale(x, y)
end

-- The same "random" number for the same stroke and salt, every frame.
local function random(n, salt)
	return (math.sin(n * 12.9898 + salt * 78.233) * 43758.5453) % 1
end

-- The pick swung in 3D, seen in perspective from a little in front, to the side and above, the way the
-- game's own swing looks (PickSwing): lifted slowly back over the shoulder, then snapped down and
-- forward through the strike, and settled. Each stroke turns the swing a little left or right and
-- rolls it a little, so strokes differ. `parts.seed` puts every preview at its own place in its own
-- rhythm, so a grid of them never swings in step. Returns the head's place as fractions of the frame,
-- the stroke number and how near it is (1 at the pivot's distance; nearer is bigger).
local camYaw, camPitch, distance, lens = math.rad(32), math.rad(14), 3.2, 1.25
local function path(parts, t)
	local seed = parts.seed or 0
	local rate = 1.55 * (parts.tempo or 1)
	local clock = t * rate + seed
	local n = math.floor(clock)
	local cycle = clock - n
	-- 0 is the strike (down and forward), 1 the top of the lift (up and back over the shoulder).
	local up
	if cycle < 0.62 then
		local u = cycle / 0.62
		up = u * u * (3 - 2 * u) -- the slow lift
	elseif cycle < 0.8 then
		local u = (cycle - 0.62) / 0.18
		up = 1 - u ^ 2.2 -- the snap
	else
		up = 0.06 * math.sin((cycle - 0.8) / 0.2 * math.pi) -- the settle after contact
	end
	local a = math.rad(-35 + 175 * up)
	-- In the swing's own plane: forward is +Z, up is +Y.
	local px, py, pz = 0, math.sin(a), math.cos(a)
	-- This stroke's turn (left or right) and roll.
	local yaw = math.rad(-48 + 96 * random(n + seed * 7, 1))
	local roll = math.rad(-18 + 36 * random(n + seed * 7, 2))
	px, py = px * math.cos(roll) - py * math.sin(roll), px * math.sin(roll) + py * math.cos(roll)
	px, pz = px * math.cos(yaw) + pz * math.sin(yaw), -px * math.sin(yaw) + pz * math.cos(yaw)
	-- The camera's view: turned to the side and looking down a little.
	local vx = px * math.cos(camYaw) - pz * math.sin(camYaw)
	local vz = px * math.sin(camYaw) + pz * math.cos(camYaw)
	local vy = py * math.cos(camPitch) - vz * math.sin(camPitch)
	vz = py * math.sin(camPitch) + vz * math.cos(camPitch)
	local depth = distance - vz
	local scale = distance / depth
	return 0.5 + lens * vx / depth * 0.32, 0.56 - lens * vy / depth * 0.32, n, scale
end

-- Lays one segment between two points (fractions of the frame), `width` pixels thick.
local function lay(seg, size, a, b, width, transparency)
	local pa, pb = a * size, b * size
	local mid, delta = (pa + pb) / 2, pb - pa
	seg.Position = UDim2.fromOffset(mid.X, mid.Y)
	seg.Size = UDim2.fromOffset(delta.Magnitude + width * 0.9, width)
	seg.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	seg.BackgroundTransparency = transparency
end

function Preview.draw(parts, t)
	local palette = parts.palette
	if parts.swirl then parts.swirl.Rotation = (t * 80) % 360 end
	if parts.glow then parts.glow.ImageTransparency = 0.55 + 0.12 * math.sin(t * 3) end
	if parts.kind == "aura" then
		local pulse = 1 + 0.08 * math.sin(t * 3)
		parts.core.Size = UDim2.fromOffset(70 * parts.s * pulse, 70 * parts.s * pulse)
		parts.core.ImageTransparency = 0.3 + 0.1 * math.sin(t * 3)
		parts.ring.Rotation = (t * 40) % 360
		parts.band.Rotation = (t * 90) % 360
		for i, star in parts.orbit do
			local a = t * 1.4 + i * math.pi * 2 / #parts.orbit
			place(star, 0.5 + 0.36 * math.cos(a), 0.5 + 0.22 * math.sin(a) - 0.06 * math.sin(t * 2 + i))
			star.Rotation = (t * 120 + i * 30) % 360
		end
		if parts.shaft then parts.shaft.BackgroundTransparency = 0.25 + 0.15 * math.sin(t * 2.2) end
		if parts.outer then parts.outer.Rotation = -(t * 60) % 360 end
		if parts.wings then
			-- Fanned from up and out to down and out, beating slowly.
			local beat = 5 * math.sin(t * 2.2)
			for _, wing in parts.wings do
				local angle = -64 + (wing.k - 1) * 25 - beat
				wing.frame.Rotation = if wing.side == 1 then angle else -angle
			end
		end
		if parts.sun then parts.sun.Rotation = (t * 25) % 360 end
		if parts.clouds then
			for i, cloud in parts.clouds do
				place(cloud, 0.5 + 0.13 * math.cos(t * 0.6 + i * 2.1), 0.5 + 0.1 * math.sin(t * 0.5 + i * 2.1))
			end
		end
	else
		local ribbon = parts.kind == "ribbon"
		local count = #parts.band
		local size, s = parts.size, parts.s
		-- A ribbon: straight out from its source, as from a miner moving in a straight line, with a soft
		-- shimmer running along it.
		local function along(u)
			return Vector2.new(0.14 + 0.8 * u, 0.5)
		end
		-- A pick: its head's path over the last moments of its strokes.
		local step = parts.lifetime / count
		local x0, y0, stroke = path(parts, t)
		local previous = if ribbon then along(0) else Vector2.new(x0, y0)
		local depthScale = 1
		for i = 1, count do
			local fade = (i - 1) / (count - 1)
			local at, gap = nil, false
			if ribbon then
				at = along(i / count)
			else
				local x, y, n, near = path(parts, t - i * step)
				-- A new stroke starts somewhere else: no band across the jump.
				at, gap, stroke = Vector2.new(x, y), n ~= stroke, n
				depthScale = near
			end
			-- The world's trail: nearly solid at the start, fading out by the end, tapering.
			local clear = if fade < 0.55 then 0.02 + 0.6 * fade else 0.35 + 0.65 * (fade - 0.55) / 0.45
			if ribbon then clear += 0.1 * (0.5 + 0.5 * math.sin(t * 7 - fade * 9)) end
			-- Nearer parts of the swing are wider, as in perspective.
			local width = if ribbon then (30 - 20 * fade) * s else (26 - 12 * fade) * s * depthScale
			lay(parts.band[i], size, previous, at, width, if gap then 1 else math.min(1, clear + (if ribbon then 0.04 else 0.1)))
			local core = parts.core[i]
			if core then
				local coreFade = math.min(1, fade / 0.55)
				lay(core, size, previous, at, width * (if ribbon then 0.3 else 0.28), if gap then 1 else math.min(1, 0.05 + coreFade))
			end
			previous = at
		end
		if ribbon then
			place(parts.head, 0.14, 0.5)
			parts.head.ImageColor3, parts.head.ImageTransparency = white:Lerp(palette[1], 0.4), 0.2
			parts.headAt = Vector2.new(0.14, 0.5)
			for k, glint in parts.flow do
				local u = (t * 0.9 + k / #parts.flow) % 1
				place(glint, 0.14 + 0.8 * u, 0.5 + 0.06 * math.sin(k * 2.1) * u)
				glint.ImageTransparency = 0.15 + 0.85 * u
				glint.Rotation = (t * 160 + k * 40) % 360
			end
		else
			local x, y, _, near = path(parts, t)
			local tip, hand = Vector2.new(x, y), Vector2.new(0.5, 0.56)
			lay(parts.handle, size, hand, tip, 4.5 * s, 0)
			local across = (tip - hand).Unit
			local side = Vector2.new(-across.Y, across.X) * 0.12
			lay(parts.pickHead, size, tip - side * near, tip + side * near, 7 * s * near, 0)
			place(parts.head, x, y)
			parts.head.Rotation = (t * 200) % 360
			parts.head.ImageColor3 = white:Lerp(palette[1], 0.2)
			parts.headAt = tip
		end
	end
	if parts.bits then
		local n = #parts.bits
		for i, bit in parts.bits do
			local seed = (i * 0.618) % 1
			local phase = (t * 0.6 + i / n) % 1
			local x, y
			if parts.theme == "fire" then
				x, y = 0.2 + 0.6 * seed + 0.05 * math.sin(t * 4 + i), 0.9 - 0.75 * phase
			elseif parts.theme == "frost" or parts.theme == "leaf" then
				x, y = 0.15 + 0.7 * seed + 0.08 * math.sin(t * 2 + i), 0.1 + 0.8 * phase
				bit.Rotation = (t * 160 + i * 47) % 360
			elseif parts.theme == "bolt" then
				local at = parts.headAt or Vector2.new(0.5, 0.5)
				local flick = math.floor(t * 12 + i) % 7
				x, y = at.X + (flick - 3) * 0.04, at.Y + ((flick * 3) % 7 - 3) * 0.04
			else
				x, y = 0.12 + 0.76 * seed, 0.12 + 0.76 * ((i * 0.37) % 1)
			end
			place(bit, x, y)
			bit.ImageTransparency = if parts.theme == "star" or parts.theme == "bolt" then 0.5 + 0.5 * math.sin(t * 5 + i * 1.7) else 0.1 + 0.7 * phase
		end
	end
end

Run.RenderStepped:Connect(function()
	if #live == 0 then return end
	local t = os.clock()
	for _, parts in live do
		if parts.frame.Parent and shown(parts.frame) then Preview.draw(parts, t) end
	end
end)

return Preview
