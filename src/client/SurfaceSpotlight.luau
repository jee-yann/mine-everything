local Gui = game:GetService("GuiService")
local W = require(script.Parent.Widgets)

-- The box around a button and the shortcut drawn on its corner, if it has one, in screen pixels.
local function bounds(button)
	local low, high = button.AbsolutePosition, button.AbsolutePosition + button.AbsoluteSize
	local key = button:FindFirstChild("Key", true)
	if key and key:IsA("TextLabel") and key.Visible and key.Text ~= "" then
		local middle, half = key.AbsolutePosition + key.AbsoluteSize / 2, key.TextBounds / 2 + Vector2.one * 3
		low, high = low:Min(middle - half), high:Max(middle + half)
	end
	return low, high
end

local Spotlight = {}
Spotlight.bounds = bounds
Spotlight.__index = Spotlight

function Spotlight.new(root)
	local layer = W.frame(root, "Surface spotlight", 0, 0, 0, 0, W.ink)
	layer.BackgroundTransparency, layer.Visible, layer.ZIndex = 1, false, 4
	layer.Active, layer.Interactable, layer.Selectable = false, false, false
	local shades = {}
	for _, side in { "Top", "Bottom", "Left", "Right" } do
		local shade = W.frame(layer, side, 0, 0, 0, 0, Color3.fromRGB(10, 16, 29))
		shade.BackgroundTransparency = 0.34
		shades[side] = shade
	end
	-- A backing for words that lie over other things.
	local plate = W.frame(layer, "Plate", 0, 0, 0, 0, W.navy, 14)
	plate.BackgroundTransparency, plate.Visible = 0.08, false
	local arrow = W.title(layer, "", 0, 0, 25, 25, 21, W.gold)
	arrow.Name, arrow.AnchorPoint, arrow.ZIndex = "Return arrow", Vector2.new(0.5, 0.5), 2
	W.outlineText(arrow, 2)
	local title = W.title(layer, "", 0, 0, 0, 34, 27, W.gold)
	local help = W.text(layer, "", 0, 0, 0, 50, 20, W.white)
	for _, text in { title, help } do
		text.ZIndex, text.AnchorPoint = 2, Vector2.new(0.5, 0)
		W.largest(text, text.TextSize, 11)
		W.outlineText(text, 2)
	end
	return setmetatable({ layer = layer, shades = shades, plate = plate, arrow = arrow, title = title, help = help }, Spotlight)
end

local function place(rect, x, y, width, height)
	rect.Position, rect.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
end

-- The opening is empty space between four passive panels. The real button
-- keeps its hitbox, and players can still move, open Settings or walk out.
-- `above` puts the words in the middle at that height on the screen, and `dim` sets how dark the rest is.
function Spotlight:show(button, title, help, motion, above, dim)
	local layer = self.layer
	if not button then
		layer.Visible = false
		return
	end
	local viewport = Gui:GetInsetArea(Enum.ScreenInsets.None)
	local origin = layer.Parent.AbsolutePosition + viewport.Min
	local size = viewport.Max - viewport.Min
	local low, high = bounds(button)
	low, high = low - origin, high - origin
	if size.X < 1 or size.Y < 1 then return end
	local left = math.clamp(math.floor(low.X - 9), 0, size.X)
	local top = math.clamp(math.floor(low.Y - 9), 0, size.Y)
	local right = math.clamp(math.ceil(high.X + 9), left, size.X)
	local bottom = math.clamp(math.ceil(high.Y + 9), top, size.Y)
	place(layer, viewport.Min.X, viewport.Min.Y, size.X, size.Y)
	local shade = self.shades
	for _, side in shade do
		side.BackgroundTransparency = dim or 0.34
	end
	place(shade.Top, 0, 0, size.X, top)
	place(shade.Left, 0, top, left, bottom - top)
	place(shade.Right, right, top, size.X - right, bottom - top)
	place(shade.Bottom, 0, bottom, size.X, size.Y - bottom)

	-- Point into the side of Surface. The utility buttons occupy the strip
	-- immediately below it, including the owner's optional ore filters.
	local rightRoom = size.X - right
	local fromRight = rightRoom >= 316 or rightRoom >= left
	local sideRoom = if fromRight then rightRoom else left
	local side, sign = if fromRight then right else left, if fromRight then 1 else -1
	local midY = (top + bottom) / 2
	local bob = if motion then (1 - math.cos(os.clock() * 5)) * 3 else 2
	self.arrow.Text = if fromRight then "◀" else "▶"
	self.arrow.Position = UDim2.fromOffset(side + (12 + bob) * sign, midY)
	local width, textX, y, align
	if above then
		width = math.min(390, math.max(1, size.X - 20))
		textX = math.clamp((left + right) / 2, width / 2, size.X - width / 2)
		y, align = above - origin.Y + 14, Enum.TextXAlignment.Center
		self.arrow.Text = ""
	elseif sideRoom >= 184 then
		width = math.min(380, sideRoom - 47)
		textX, y = side + sign * (36 + width / 2), math.max(6, midY - 42)
		align = if fromRight then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
	else
		width = math.min(380, math.max(1, size.X - 20))
		textX = math.clamp((left + right) / 2, width / 2, size.X - width / 2)
		y = if bottom + 170 <= size.Y then bottom + 80 else math.max(5, top - 98)
		align = Enum.TextXAlignment.Center
	end
	self.plate.Visible = above ~= nil
	if above then
		-- A short screen keeps only the first line, so the choices stay in view.
		local short = size.Y < 470
		if short then help, y = "", above - origin.Y + 4 end
		place(self.plate, textX - 200, y - 6, 400, if short then 44 else 98)
	end
	self.title.TextXAlignment, self.help.TextXAlignment = align, align
	self.title.Size, self.help.Size = UDim2.fromOffset(width, 34), UDim2.fromOffset(width, 50)
	self.title.Position, self.help.Position = UDim2.fromOffset(textX, y), UDim2.fromOffset(textX, y + 34)
	self.title.Text, self.help.Text, layer.Visible = title, help, true
end

return Spotlight
