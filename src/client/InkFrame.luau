-- The Ink & Facet frame on every open block face: one small image, drawn once and shared.
-- The client draws it with EditableImage. If the experience doesn't allow that, it falls back
-- to OreLooks.frame.image (an uploaded asset id) when one is set, and draws no frames otherwise.
local Assets = game:GetService("AssetService")
local Looks = require(game:GetService("ReplicatedStorage").Shared.OreLooks)

local InkFrame = {}
local SIZE = 64
local content, drawn = nil, false

local function draw()
	local ok, image = pcall(function()
		return Assets:CreateEditableImage({ Size = Vector2.new(SIZE, SIZE) })
	end)
	if not ok or not image then
		return nil
	end
	local ink = Color3.fromHex(Looks.ink)
	local r, g, b = math.round(ink.R * 255), math.round(ink.G * 255), math.round(ink.B * 255)
	local pixels = buffer.create(SIZE * SIZE * 4)
	for y = 0, SIZE - 1 do
		for x = 0, SIZE - 1 do
			local edge = math.min(x, y, SIZE - 1 - x, SIZE - 1 - y)
			local alpha = if edge < 2 then 235 elseif edge < 3 then 110 else 0
			-- A few hatch strokes in the lower-left corner.
			if alpha == 0 and x + (SIZE - 1 - y) < 15 and (x - y) % 4 == 0 then
				alpha = 75
			end
			if alpha > 0 then
				local at = (y * SIZE + x) * 4
				buffer.writeu8(pixels, at, r)
				buffer.writeu8(pixels, at + 1, g)
				buffer.writeu8(pixels, at + 2, b)
				buffer.writeu8(pixels, at + 3, alpha)
			end
		end
	end
	local written = pcall(function()
		image:WritePixelsBuffer(Vector2.zero, image.Size, pixels)
	end)
	return if written then Content.fromObject(image) else nil
end

-- Adds a frame to `face` of `part` and returns the Decal, or nil when frames are unavailable.
function InkFrame.apply(part, face)
	if not drawn then
		drawn, content = true, draw()
	end
	local decal = Instance.new("Decal")
	decal.Name, decal.Face, decal.Transparency = "Ink frame", face, Looks.frame.transparency
	if content and not pcall(function()
		decal.ColorMapContent = content
	end) then
		content = nil
	end
	if not content then
		if not Looks.frame.image then
			decal:Destroy()
			return nil
		end
		decal.Texture = Looks.frame.image
	end
	decal.Parent = part
	return decal
end

return InkFrame
