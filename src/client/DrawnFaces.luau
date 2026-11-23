-- Storybook Ink face drawings. Every open block face shows one, decoded once from the
-- run-length data in OreDrawings (drawn by art/ore-looks/draw_faces.py, using the same
-- tape layout as the Starfall opening's BreakerDrawings). Stone's drawing is light and
-- neutral and takes the colour of its stone grade. Ores that glow also have a glow image in
-- OreGlow: just their ore pieces and a soft halo on a clear background.
local Assets = game:GetService("AssetService")
local Encoding = game:GetService("EncodingService")
local Http = game:GetService("HttpService")
local Looks = require(game:GetService("ReplicatedStorage").Shared.OreLooks)

local Drawn = {}
local folder = script.Parent:FindFirstChild("OreDrawings")
local glowFolder = script.Parent:FindFirstChild("OreGlow")
local variants = {} -- block name -> number of variants, or 0 for a single drawing named after the block
local images = {} -- source StringValue -> Content, or false when it can't be shown
local solids = {} -- the same for glow images with their soft halo left out

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
-- Palette entries are RRGGBB, or RRGGBBAA for images with clear parts. `solid` drops every
-- partly clear colour, which leaves a glow image's ore pieces without their halo.
local function decode(source, solid)
	local art = Http:JSONDecode(source)
	local width, height = art.width, art.height
	local swatches = {}
	for i, hex in art.palette do
		local c = Color3.fromHex(string.sub(hex, 1, 6))
		local alpha = if #hex == 8 then tonumber(string.sub(hex, 7, 8), 16) :: number else 255
		if solid and alpha < 240 then
			alpha = 0
		end
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

local function content(from, key, solid)
	local value = from and from:FindFirstChild(key)
	if not value then
		return nil
	end
	local cache = if solid then solids else images
	if cache[value] == nil then
		local ok, image = pcall(decode, value.Value, solid)
		cache[value] = ok and image or false
	end
	return cache[value] or nil
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
		decal.Color3 = part.Color
	end
	decal.Parent = part
	return decal
end

-- The glow image for ore `name` (its ore pieces and a soft halo), or nil if it has none or
-- images can't be shown. An uploaded id under `name .. " glow"` is used instead if set.
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

-- Just the ore pieces of ore `name`, on a clear background (its glow image without the halo),
-- or nil. Gems raise these a little off their faces.
function Drawn.pieces(name)
	if not Looks.drawn.enabled then
		return nil
	end
	return content(glowFolder, name, true)
end

return Drawn
