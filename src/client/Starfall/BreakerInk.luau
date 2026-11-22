-- The two surviving surf drawings from the earlier offshore shot. Transparent
-- space above the torn lip lets the live fire and shoreline register through it.
local Assets = game:GetService("AssetService")
local Encoding = game:GetService("EncodingService")
local Http = game:GetService("HttpService")
local Input = game:GetService("UserInputService")

local Roller = {}
Roller.__index = Roller
local art = Http:JSONDecode(script.Parent.BreakerDrawings.Value)
local pigments, swatches = {}, {}
for i, hex in art.palette do
	local color = Color3.fromHex(hex)
	local swatch = buffer.create(art.width * 4)
	local rgba = math.round(color.R * 255)
		+ 256 * math.round(color.G * 255)
		+ 65536 * math.round(color.B * 255)
		+ 0xFF000000
	for x = 0, art.width - 1 do
		buffer.writeu32(swatch, x * 4, rgba)
	end
	pigments[i - 1], swatches[i - 1] = color, swatch
end

local function scan(tape, visit)
	local off = 0
	while off < buffer.len(tape) do
		local y, x, count = buffer.readu16(tape, off), buffer.readu16(tape, off + 2), buffer.readu8(tape, off + 4)
		visit(x, y, count, off + 5)
		off += 5 + 3 * count
	end
end

local function imageCel(tape, layer, editable)
	local pixels = buffer.create(art.width * art.height * 4)
	scan(tape, function(x, y, count, off)
		local dest = (art.width * y + x) * 4
		for _ = 1, count do
			local bytes = buffer.readu16(tape, off) * 4
			buffer.copy(pixels, dest, swatches[buffer.readu8(tape, off + 2)], 0, bytes)
			dest += bytes
			off += 3
		end
	end)
	editable:WritePixelsBuffer(Vector2.zero, editable.Size, pixels)
	local image = Instance.new("ImageLabel")
	local ok = pcall(function()
		image.ImageContent = Content.fromObject(editable)
	end)
	if not ok then
		image:Destroy()
		return false
	end
	image.Name, image.BackgroundTransparency, image.ZIndex = "Foam and shadow", 1, 6
	image.Size, image.Parent = UDim2.fromScale(1, 1), layer
	return true
end

-- The same colored runs also paint natively when editable image allocation
-- is unavailable. Build them during setup so neither exposure can hitch.
local function brushCel(tape, layer)
	local step = if Input.TouchEnabled and not Input.KeyboardEnabled then 4 else 3
	scan(tape, function(x, y, count, off)
		if y % step ~= 0 then
			return
		end
		local width, colors, ends = 0, {}, {}
		for k = 1, count do
			width += buffer.readu16(tape, off)
			colors[k], ends[k] = pigments[buffer.readu8(tape, off + 2)], width
			off += 3
		end
		local line = Instance.new("Frame")
		line.Name, line.BorderSizePixel, line.ZIndex = "Brush mark", 0, 6
		line.Position, line.Size =
			UDim2.fromScale(x / art.width, y / art.height),
			UDim2.fromScale(width / art.width, (step + 0.09) / art.height)
		line.BackgroundColor3 = if count == 1 then colors[1] else Color3.new(1, 1, 1)
		if count > 1 then
			local stops = { ColorSequenceKeypoint.new(0, colors[1]) }
			for k = 1, count - 1 do
				table.insert(stops, ColorSequenceKeypoint.new((ends[k] - 0.32) / width, colors[k]))
				table.insert(stops, ColorSequenceKeypoint.new((ends[k] + 0.32) / width, colors[k + 1]))
			end
			table.insert(stops, ColorSequenceKeypoint.new(1, colors[count]))
			local grad = Instance.new("UIGradient")
			grad.Color, grad.Parent = ColorSequence.new(stops), line
		end
		line.Parent = layer
	end)
end

function Roller.new(screen)
	local group = Instance.new("Frame")
	group.Name, group.BackgroundTransparency, group.AnchorPoint = "Breaking pressure front", 1, Vector2.new(0.5, 1)
	group.Position, group.ZIndex, group.Visible, group.Parent = UDim2.fromScale(0.5, 1), 6, false, screen
	local layers, images = {}, {}
	for i, source in art.cels do
		local tape = Encoding:Base64Decode(buffer.fromstring(source))
		local layer = Instance.new("Frame")
		layer.Name, layer.Size = if i == 1 then "Rolling whitecap" else "Trailing brush", UDim2.fromScale(1, 1)
		layer.BackgroundTransparency, layer.ZIndex, layer.Visible, layer.Parent = 1, 6, false, group
		local ok, editable = pcall(Assets.CreateEditableImage, Assets, { Size = Vector2.new(art.width, art.height) })
		local painted, assigned = false, false
		if ok and editable then
			painted, assigned = pcall(imageCel, tape, layer, editable)
			if painted and assigned then
				table.insert(images, editable)
			else
				editable:Destroy()
			end
		end
		if not (painted and assigned) then
			brushCel(tape, layer)
		end
		layers[i] = layer
	end
	return setmetatable({ group = group, layers = layers, images = images }, Roller)
end

function Roller:draw(index, viewport)
	self.group.Visible = index ~= nil
	if not index then
		return
	end
	local aspect = viewport.X / math.max(1, viewport.Y)
	local portrait = math.clamp((1.45 - aspect) / 0.85, 0, 1)
	-- Keep both curling shoulders inside a phone's narrow width. The white
	-- lip overtakes the lower quarter while the rising plume owns the upper field.
	self.group.Size = UDim2.fromScale(math.clamp(2 / math.max(aspect, 0.1), 1, 1.14), 1 - 0.25 * portrait)
	self.layers[1].Visible, self.layers[2].Visible = index == 1, index == 2
end

function Roller:Destroy()
	self.group:Destroy()
	for _, editable in self.images do
		editable:Destroy()
	end
end

return Roller
