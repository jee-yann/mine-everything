-- Storybook Ink face drawings. Every open block face shows one, decoded once from the
-- run-length data in OreDrawings (drawn by art/ore-looks/draw_faces.py, using the same
-- tape layout as the Starfall opening's BreakerDrawings). Stone's drawing is light and
-- neutral and takes the colour of its stone grade. Every ore also has a pieces image in OrePieces
-- (just its ore pieces on a clear background), and ores that glow have a glow image in OreGlow
-- (the same pieces with a neon filling and a soft halo).
local Assets = game:GetService("AssetService")
local Encoding = game:GetService("EncodingService")
local Http = game:GetService("HttpService")
local Looks = require(game:GetService("ReplicatedStorage").Shared.OreLooks)

local Drawn = {}
local folder = script.Parent:FindFirstChild("OreDrawings")
local piecesFolder = script.Parent:FindFirstChild("OrePieces")
local glowFolder = script.Parent:FindFirstChild("OreGlow")
local variants = {} -- block name -> number of variants, or 0 for a single drawing named after the block
local images = {} -- source StringValue -> Content, or the os.clock() of the last failed attempt
local RETRY = 4 -- seconds before a drawing that couldn't be decoded is tried again

if folder then
	for _, value in folder:GetChildren() do
		local name, n = string.match(value.Name, "^(.-)%-(%d+)$")
		if name then
			variants[name] = math.max(variants[name] or 0, tonumber(n))
		else
			variants[value.Name] = variants[value.Name] or 0
		end
	end
end

-- Per row: u16 y, u16 x, u8 count, then count runs of (u16 length, u8 palette index).
-- Palette entries are RRGGBB, or RRGGBBAA for images with clear parts.
local function decode(source)
	local art = Http:JSONDecode(source)
	local width, height = art.width, art.height
	local swatches = {}
	for i, hex in art.palette do
		local c = Color3.fromHex(string.sub(hex, 1, 6))
		local alpha = if #hex == 8 then tonumber(string.sub(hex, 7, 8), 16) :: number else 255
		local rgba = math.round(c.R * 255)
			+ 256 * math.round(c.G * 255)
			+ 65536 * math.round(c.B * 255)
			+ 16777216 * alpha
		local swatch = buffer.create(width * 4)
		for x = 0, width - 1 do
			buffer.writeu32(swatch, x * 4, rgba)
		end
		swatches[i - 1] = swatch
	end
	local tape = Encoding:Base64Decode(buffer.fromstring(art.tape))
	local pixels = buffer.create(width * height * 4)
	local off = 0
	while off < buffer.len(tape) do
		local y, x, count = buffer.readu16(tape, off), buffer.readu16(tape, off + 2), buffer.readu8(tape, off + 4)
		off += 5
		local dest = (width * y + x) * 4
		for _ = 1, count do
			local bytes = buffer.readu16(tape, off) * 4
			buffer.copy(pixels, dest, swatches[buffer.readu8(tape, off + 2)], 0, bytes)
			dest += bytes
			off += 3
		end
	end
	local image = Assets:CreateEditableImage({ Size = Vector2.new(width, height) })
	image:WritePixelsBuffer(Vector2.zero, image.Size, pixels)
	return Content.fromObject(image)
end

local function content(from, key)
	local value = from and from:FindFirstChild(key)
	if not value then
		return nil
	end
	local cached = images[value]
	-- EditableImage allocation can fail for a moment (the device's image memory budget is
	-- briefly full, for example while a reset rebuilds the mine). Retry later instead of
	-- leaving that ore undrawn for the rest of the session.
	if cached == nil or (type(cached) == "number" and os.clock() - cached >= RETRY) then
		local ok, image = pcall(decode, value.Value)
		images[value] = if ok then image else os.clock()
	end
	cached = images[value]
	return if type(cached) == "number" then nil else cached
end

-- The drawing for `face` (a NormalId value) of a block at cell `p`, or nil if the block has none.
function Drawn.key(name, p, face)
	local n = if Looks.drawn.enabled then variants[name] else nil
	if n == nil then
		return nil
	elseif n == 0 then
		return name
	end
	return name .. "-" .. 1 + (p.X * 7 + p.Y * 3 + p.Z * 5 + face * 11) % n
end

-- Puts drawing `key` on `face` of `part`. Returns the Decal, or nil when it can't be shown.
function Drawn.apply(part, face, key)
	local decal = Instance.new("Decal")
	decal.Name, decal.Face = part.Name .. " face", face
	local uploaded = Looks.drawn.uploaded[key]
	if uploaded then
		decal.Texture = uploaded
	else
		local image = content(folder, key)
		if not image or not pcall(function()
			decal.ColorMapContent = image
		end) then
			decal:Destroy()
			return nil
		end
	end
	local rock = Looks.rock[part.Name]
	if rock and rock.tint then
		-- The tint multiplies the drawing, so the darkest grades (Shadowslate, Abyssal Basalt,
		-- Voidglass, Starbound Rock) would turn it nearly black and no lamp could show it. Dark
		-- tints keep their hue but are drawn at 0.54 to 0.56 brightness; grades from 0.45 up are
		-- unchanged. The region's ambient palette still makes the deep mine feel dark.
		local h, s, v = part.Color:ToHSV()
		decal.Color3 = if v < 0.45 then Color3.fromHSV(h, s * 0.85, 0.54 + 0.1 * (v - 0.25)) else part.Color
	end
	decal.Parent = part
	return decal
end

-- The glow image for ore `name` (its ore pieces with a neon filling and a soft halo), or nil if
-- it has none or images can't be shown. An uploaded id under `name .. " glow"` is used instead.
function Drawn.glow(name)
	if not Looks.drawn.enabled then
		return nil
	end
	local uploaded = Looks.drawn.uploaded[name .. " glow"]
	if uploaded then
		return Content.fromUri(uploaded)
	end
	return content(glowFolder, name)
end

-- Just the ore pieces of ore `name` on a clear background, or nil. Ores raise these a little off
-- their faces. An uploaded id under `name .. " pieces"` is used instead if set.
function Drawn.pieces(name)
	if not Looks.drawn.enabled then
		return nil
	end
	local uploaded = Looks.drawn.uploaded[name .. " pieces"]
	if uploaded then
		return Content.fromUri(uploaded)
	end
	return content(piecesFolder, name)
end

local glintSpots = {} -- ore name -> its glint spots
-- Spots on ore `name`'s pieces that can catch a glint, as Vector2s in 0..1 image space
-- (x right, y down), or an empty list.
function Drawn.glints(name)
	if glintSpots[name] == nil then
		local spots = {}
		local value = piecesFolder and piecesFolder:FindFirstChild(name)
		local ok, art = false, nil
		if value then
			ok, art = pcall(Http.JSONDecode, Http, value.Value)
		end
		if ok and art.glints then
			for _, p in art.glints do
				table.insert(spots, Vector2.new(p[1], p[2]))
			end
		end
		glintSpots[name] = spots
	end
	return glintSpots[name]
end

return Drawn
