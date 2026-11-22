-- Storybook Ink face drawings. Every open block face shows one, decoded once from the
-- run-length data in OreDrawings (drawn by art/ore-looks/draw_faces.py, using the same
-- tape layout as the Starfall opening's BreakerDrawings). Stone's drawing is light and
-- neutral and takes the colour of its stone grade.
local Assets = game:GetService("AssetService")
local Encoding = game:GetService("EncodingService")
local Http = game:GetService("HttpService")
local Looks = require(game:GetService("ReplicatedStorage").Shared.OreLooks)

local Drawn = {}
local folder = script.Parent:FindFirstChild("OreDrawings")
local variants = {} -- block name -> number of variants, or 0 for a single drawing named after the block
local images = {} -- drawing name -> Content, or false when it can't be shown

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
local function decode(source)
	local art = Http:JSONDecode(source)
	local width, height = art.width, art.height
	local swatches = {}
	for i, hex in art.palette do
		local c = Color3.fromHex(hex)
		local rgba = math.round(c.R * 255) + 256 * math.round(c.G * 255) + 65536 * math.round(c.B * 255) + 0xFF000000
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

local function content(key)
	if images[key] == nil then
		local value = folder and folder:FindFirstChild(key)
		local ok, image = false, nil
		if value then
			ok, image = pcall(decode, value.Value)
		end
		images[key] = ok and image or false
	end
	return images[key] or nil
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
		local image = content(key)
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

return Drawn
