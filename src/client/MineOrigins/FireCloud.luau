-- Two original cel sheets shared by replays. Native painted geometry and
-- billowing ash carry the same shot when the client's editable-image budget is full.
local Assets = game:GetService("AssetService")
local Encoding = game:GetService("EncodingService")
local P = require(script.Parent.Props)
local Cloud = {}
local sheets
local tile = Vector2.new(384, 320)

local function load()
	if sheets then
		return sheets
	end
	sheets = {}
	local allocated = {}
	for i = 1, 2 do
		local image
		local ok = pcall(function()
			local size = Vector2.new(tile.X * 2, tile.Y * 3)
			image = Assets:CreateEditableImage({ Size = size })
			if not image then
				return
			end
			local bytes = Encoding:Base64Decode(buffer.fromstring(script.Parent["FireCloud" .. i].Value))
			image:WritePixelsBuffer(
				Vector2.zero,
				size,
				Encoding:DecompressBuffer(bytes, Enum.CompressionAlgorithm.Zstd)
			)
			sheets[i] = Content.fromObject(image)
		end)
		if not ok or not image then
			if image then
				image:Destroy()
			end
			for _, page in allocated do
				page:Destroy()
			end
			table.clear(sheets)
			break
		end
		table.insert(allocated, image)
	end
	return sheets
end

function Cloud.new(root)
	local ink = load()
	if not ink[1] or not ink[2] then
		return nil
	end
	local at = P.box(root, "Boiling fire column", Vector3.zero, Vector3.one, "FFFFFF")
	at.Transparency = 1
	local gui = Instance.new("BillboardGui")
	gui.Enabled, gui.LightInfluence, gui.Brightness, gui.Parent = false, 0.03, 1.12, at
	local cel = Instance.new("ImageLabel")
	cel.Size, cel.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	cel.ImageRectSize, cel.Parent = tile, gui
	return { at = at, gui = gui, cel = cel }
end

function Cloud.draw(cloud, age, base)
	if not cloud then
		return
	end
	local u = math.clamp((age - 0.095) / 2.80, 0, 1)
	cloud.gui.Enabled = u > 0 and u < 1
	if not cloud.gui.Enabled then
		return
	end
	local cel = math.min(11, math.floor(12 * (1 - (1 - u) ^ 2.15)))
	if cloud.index ~= cel then
		cloud.index = cel
		local slot = cel % 6
		cloud.cel.ImageContent = sheets[1 + math.floor(cel / 6)]
		cloud.cel.ImageRectOffset = Vector2.new((slot % 2) * tile.X, math.floor(slot / 2) * tile.Y)
	end
	local w = 82 + 67 * (1 - (1 - u) ^ 2)
	local h = 76 + 58 * (1 - (1 - u) ^ 3)
	cloud.at.Position = base * Vector3.new(7 * u, 31 * math.max(0, 1 - age / 0.7) ^ 2 + h * 0.39 + 3 * u, -4 - 9 * u)
	cloud.gui.Size = UDim2.fromScale(w, h)
	cloud.cel.Rotation = -3.5 * u
	cloud.cel.ImageTransparency = 1 - P.ease(u, 0, 0.045) * (1 - P.ease(u, 0.68, 1))
end
return Cloud
