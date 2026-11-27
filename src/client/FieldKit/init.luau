local Assets = game:GetService("AssetService")
local Encoding = game:GetService("EncodingService")
local ContentProvider = game:GetService("ContentProvider")

-- Tile order matches art/hud/FieldKit.png (drawn in art/hud/field_kit.html). The bundled copy uses
-- 128px tiles. Set the ImageId attribute only to an upload of the current FieldKit.png; without it the
-- bundled pixels are used.
local tileSize, atlasWidth, atlasHeight = 128, 512, 1152
local tiles = {
	Inventory = Vector2.new(0, 0),
	Skills = Vector2.new(1, 0),
	Achievements = Vector2.new(2, 0),
	Daily = Vector2.new(3, 0),
	Book = Vector2.new(0, 1),
	Settings = Vector2.new(1, 1),
	Playtime = Vector2.new(2, 1),
	Rebirth = Vector2.new(3, 1),
	Power = Vector2.new(0, 2),
	Speed = Vector2.new(1, 2),
	Profile = Vector2.new(2, 2),
	Friends = Vector2.new(3, 2),
	Shop = Vector2.new(0, 3),
	Pets = Vector2.new(1, 3),
	Geode = Vector2.new(2, 3),
	Gems = Vector2.new(3, 3),
	Forge = Vector2.new(0, 4),
	Boosts = Vector2.new(1, 4),
	Passes = Vector2.new(2, 4),
	Trail = Vector2.new(3, 4),
	GoldPouch = Vector2.new(0, 5),
	GoldBag = Vector2.new(1, 5),
	GoldChest = Vector2.new(2, 5),
	GoldVault = Vector2.new(3, 5),
	-- Skill icons, drawn to the same rules as the rest of the kit.
	Hook = Vector2.new(0, 6),
	Tempo = Vector2.new(1, 6),
	Lamp = Vector2.new(2, 6),
	Beacon = Vector2.new(3, 6),
	Boot = Vector2.new(0, 7),
	Spring = Vector2.new(1, 7),
	Jobs = Vector2.new(2, 7),
	Coins = Vector2.new(3, 7),
	Flame = Vector2.new(0, 8),
	Clover = Vector2.new(1, 8),
	Assay = Vector2.new(2, 8),
	Showoff = Vector2.new(3, 8),
}
tiles.Pack, tiles.Capacity, tiles.Titles = tiles.Inventory, tiles.Inventory, tiles.Achievements
tiles.Gear, tiles.Crew = tiles.Power, tiles.Friends
tiles.Crystal = tiles.Gems

local pixels, atlasLabel
local nativeTemplates = {}

local function loadAtlas()
	pixels = Encoding:DecompressBuffer(
		Encoding:Base64Decode(buffer.fromstring(script:WaitForChild("Pixels").Value)),
		Enum.CompressionAlgorithm.Zstd
	)
	local size = Vector2.new(atlasWidth, atlasHeight)
	local image
	-- Live clients can return an image and deny the first write. Keep the pixels
	-- for the GUI-strip renderer until a label has actually bound the texture.
	local ok, label = pcall(function()
		image = Assets:CreateEditableImage({ Size = size })
		if not image then
			return nil
		end
		image:WritePixelsBuffer(Vector2.zero, size, pixels)
		local template = Instance.new("ImageLabel")
		template.ImageContent = Content.fromObject(image)
		return template
	end)
	if ok and label then
		atlasLabel = label
		pixels = nil
	elseif image then
		pcall(function()
			image:Destroy()
		end)
	end
end

-- A published place can disable editable images, and a phone can exhaust its
-- image budget. In either case draw the same artwork with ordinary GUI strips.
local function nativeIcon(tile)
	if nativeTemplates[tile] then
		return nativeTemplates[tile]:Clone()
	end
	local icon = Instance.new("Frame")
	icon.BackgroundTransparency, icon.Size = 1, UDim2.fromScale(1, 1)
	local resolution = tileSize
	local function pixel(x, y)
		local sx = tile.X * tileSize + x
		local sy = tile.Y * tileSize + y
		return buffer.readu32(pixels, (sy * atlasWidth + sx) * 4)
	end
	for y = 0, resolution - 1 do
		-- ColorSequence and NumberSequence allow at most 20 stops.
		for col = 0, resolution - 1, 20 do
			local first, last = col, math.min(resolution - 1, col + 19)
			while first <= last and pixel(first, y) < 0x01000000 do
				first += 1
			end
			while last >= first and pixel(last, y) < 0x01000000 do
				last -= 1
			end
			if last < first then
				continue
			end
			local strip = Instance.new("Frame")
			strip.BorderSizePixel = 0
			strip.Position = UDim2.fromScale(first / resolution, y / resolution)
			strip.Size = UDim2.fromScale((last - first + 1) / resolution, 1 / resolution)
			local colors, alphas = {}, {}
			for x = first, last do
				local rgba = pixel(x, y)
				if x > first and x < last and rgba == pixel(x - 1, y) and rgba == pixel(x + 1, y) then
					continue
				end
				local t = (x - first) / math.max(1, last - first)
				local color =
					Color3.fromRGB(bit32.extract(rgba, 0, 8), bit32.extract(rgba, 8, 8), bit32.extract(rgba, 16, 8))
				table.insert(colors, ColorSequenceKeypoint.new(t, color))
				table.insert(alphas, NumberSequenceKeypoint.new(t, 1 - bit32.extract(rgba, 24, 8) / 255))
			end
			if
				#colors == 1
				or (#colors == 2 and colors[1].Value == colors[2].Value and alphas[1].Value == alphas[2].Value)
			then
				strip.BackgroundColor3, strip.BackgroundTransparency = colors[1].Value, alphas[1].Value
			else
				strip.BackgroundColor3 = Color3.new(1, 1, 1)
				local gradient = Instance.new("UIGradient")
				gradient.Color, gradient.Transparency, gradient.Parent =
					ColorSequence.new(colors), NumberSequence.new(alphas), strip
			end
			strip.Parent = icon
		end
	end
	nativeTemplates[tile] = icon
	return icon:Clone()
end

local function bundledIcon(tile)
	if not pixels and not atlasLabel then
		loadAtlas()
	end
	if not atlasLabel then
		return nativeIcon(tile)
	end
	local icon = atlasLabel:Clone()
	icon.ImageRectOffset, icon.ImageRectSize = tile * tileSize, Vector2.one * tileSize
	icon.BackgroundTransparency, icon.Size = 1, UDim2.fromScale(1, 1)
	return icon
end

local imageId = script:GetAttribute("ImageId")
local checked, available = false, nil
local waiting = setmetatable({}, { __mode = "k" })
local function checkImage(url)
	local loaded = false
	local ok = pcall(function()
		ContentProvider:PreloadAsync({ url }, function(_, status)
			loaded = status == Enum.AssetFetchStatus.Success
		end)
	end)
	available = ok and loaded
	if not available then
		for label, tile in waiting do
			if label.Parent then
				local replacement = bundledIcon(tile)
				replacement.Name, replacement.Parent = label.Name, label.Parent
				label:Destroy()
			end
		end
	end
	table.clear(waiting)
end
local FieldKit = {}
function FieldKit.draw(parent, key)
	local tile = tiles[key]
	if not tile then
		return false
	end
	local icon
	if imageId and available ~= false then
		icon = Instance.new("ImageLabel")
		icon.Image = "rbxassetid://" .. imageId
		icon.BackgroundTransparency, icon.Size = 1, UDim2.fromScale(1, 1)
		icon.ImageRectOffset, icon.ImageRectSize = tile * 256, Vector2.one * 256
		if available == nil then
			waiting[icon] = tile
		end
		if not checked then
			checked = true
			task.defer(checkImage, icon.Image)
		end
	else
		icon = bundledIcon(tile)
	end
	icon.Name, icon.Parent = "Field Kit", parent
	return true
end
return FieldKit
