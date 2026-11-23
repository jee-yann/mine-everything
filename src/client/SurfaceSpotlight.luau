local Gui = game:GetService("GuiService")
local W = require(script.Parent.Widgets)

local Spotlight = {}
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
	local arrow = W.title(layer, "", 0, 0, 25, 25, 21, W.gold)
	arrow.Name, arrow.AnchorPoint, arrow.ZIndex = "Return arrow", Vector2.new(0.5, 0.5), 2
	W.outlineText(arrow, 2)
	local title = W.title(layer, "", 0, 0, 0, 26, 20, W.gold)
	local help = W.text(layer, "", 0, 0, 0, 40, 15, W.white)
	for _, text in { title, help } do
		text.ZIndex, text.AnchorPoint = 2, Vector2.new(0.5, 0)
		text.TextScaled = true
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize, limit.MaxTextSize, limit.Parent = 11, text.TextSize, text
		W.outlineText(text, 1.5)
	end
	return setmetatable({ layer = layer, shades = shades, arrow = arrow, title = title, help = help }, Spotlight)
end

local function place(rect, x, y, width, height)
	rect.Position, rect.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
end

-- The opening is empty space between four passive panels. The real button
-- keeps its hitbox, and players can still move, open Settings or walk out.
function Spotlight:show(button, title, help, motion)
	local layer = self.layer
	if not button then
		layer.Visible = false
		return
	end
	local viewport = Gui:GetInsetArea(Enum.ScreenInsets.None)
	local origin = layer.Parent.AbsolutePosition + viewport.Min
	local size, at = viewport.Max - viewport.Min, button.AbsolutePosition - origin
	if size.X < 1 or size.Y < 1 then return end
	local left = math.clamp(math.floor(at.X - 4), 0, size.X)
	local top = math.clamp(math.floor(at.Y - 4), 0, size.Y)
	local right = math.clamp(math.ceil(at.X + button.AbsoluteSize.X + 4), left, size.X)
	local bottom = math.clamp(math.ceil(at.Y + button.AbsoluteSize.Y + 4), top, size.Y)
	place(layer, viewport.Min.X, viewport.Min.Y, size.X, size.Y)
	local shade = self.shades
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
	if sideRoom >= 184 then
		width = math.min(286, sideRoom - 47)
		textX, y = side + sign * (36 + width / 2), math.max(6, midY - 32)
		align = if fromRight then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
	else
		width = math.min(286, math.max(1, size.X - 20))
		textX = math.clamp((left + right) / 2, width / 2, size.X - width / 2)
		y = if bottom + 151 <= size.Y then bottom + 80 else math.max(5, top - 78)
		align = Enum.TextXAlignment.Center
	end
	self.title.TextXAlignment, self.help.TextXAlignment = align, align
	self.title.Size, self.help.Size = UDim2.fromOffset(width, 26), UDim2.fromOffset(width, 40)
	self.title.Position, self.help.Position = UDim2.fromOffset(textX, y), UDim2.fromOffset(textX, y + 25)
	self.title.Text, self.help.Text, layer.Visible = title, help, true
end

return Spotlight
