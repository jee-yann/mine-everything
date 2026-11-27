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
	local parts = { frame = frame, kind = kind, palette = palette, rank = rank, size = size, s = s }
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
	else
		-- The band: segments along the recent path. A core rides down the middle for Epic and up.
		local ribbon = kind == "ribbon"
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
			if rank >= 4 or not ribbon then
				local core = segment("Core", 4)
				core.BackgroundColor3 = white:Lerp(palette[1], 0.15 + 0.6 * fade)
				parts.core[i] = core
			end
		end
		-- The tip: a bright star for Mining FX, the miner's glow for Player FX.
		parts.head = image(frame, "Head", if ribbon then textures.dot else textures.star, (if ribbon then 30 else 12 + 2 * rank) * s, white, 6)
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
	if rank >= 2 then
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

-- Where the pick's head is at time `t`, as fractions of the frame, and which stroke it's on. About
-- three strokes a second, each a fast chop round an arc and a quick lift back. Every stroke turns the
-- arc to a new angle on screen and tilts it towards or away from you (squashing the circle), and some
-- swing the other way round, the way a real swing looks from a moving camera.
local function path(_kind, t)
	local n = math.floor(t * 3)
	local cycle = t * 3 - n
	local swing = if cycle < 0.55 then 1 - (1 - cycle / 0.55) ^ 2 else 1 - (cycle - 0.55) / 0.45
	local turn = math.rad(-75 + 150 * random(n, 1))
	local squash = 0.3 + 0.7 * random(n, 2)
	local way = if random(n, 3) < 0.5 then 1 else -1
	local a = math.rad(-120 + 210 * swing) * way
	local x, y = 0.36 * math.cos(a), 0.36 * squash * math.sin(a)
	return 0.5 + x * math.cos(turn) - y * math.sin(turn), 0.55 + x * math.sin(turn) + y * math.cos(turn), n
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
		local x0, y0, stroke = path(parts.kind, t)
		local previous = if ribbon then along(0) else Vector2.new(x0, y0)
		for i = 1, count do
			local fade = (i - 1) / (count - 1)
			local at, gap = nil, false
			if ribbon then
				at = along(i / count)
			else
				local x, y, n = path(parts.kind, t - i * step)
				-- A new stroke starts somewhere else: no band across the jump.
				at, gap, stroke = Vector2.new(x, y), n ~= stroke, n
			end
			-- The world's trail: nearly solid at the start, fading out by the end, tapering.
			local clear = if fade < 0.55 then 0.02 + 0.6 * fade else 0.35 + 0.65 * (fade - 0.55) / 0.45
			if ribbon then clear += 0.1 * (0.5 + 0.5 * math.sin(t * 7 - fade * 9)) end
			local width = if ribbon then (30 - 20 * fade) * s else (26 - 12 * fade) * s
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
			local x, y = path(parts.kind, t)
			local tip, hand = Vector2.new(x, y), Vector2.new(0.5, 0.55)
			lay(parts.handle, size, hand, tip, 4.5 * s, 0)
			local across = (tip - hand).Unit
			local side = Vector2.new(-across.Y, across.X) * 0.12
			lay(parts.pickHead, size, tip - side, tip + side, 7 * s, 0)
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
