local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local W = require(script.Parent.Widgets)

local GuideButton = {}
GuideButton.__index = GuideButton

function GuideButton.new()
	return setmetatable({}, GuideButton)
end

-- The marker lives on the real control, so it follows menu scaling, scrolling and hover.
-- All its visible pieces are passive. The button keeps its own hitbox and activation.
function GuideButton:point(button, motion, side)
	side = side or "Left"
	motion = button ~= nil and motion ~= false and not GuiService.ReducedMotionEnabled
	if self.button == button and self.motion == motion and self.side == side then return end
	if self.pulse then
		self.pulse:Cancel()
		self.pulse = nil
	end
	if self.ring then
		self.ring:Destroy()
		self.ring = nil
	end
	self.button, self.motion, self.side = button, motion, side
	if not button then return end

	local ring = W.frame(button, "Guide highlight", 1, 1, 0, 0, W.gold)
	ring.Size, ring.BackgroundTransparency, ring.ZIndex = UDim2.new(1, -2, 1, -2), 1, button.ZIndex + 3
	if side == "Spotlight" then
		-- Around the shortcut on the corner too.
		local low, high = require(script.Parent.SurfaceSpotlight).bounds(button)
		local scale = math.max(0.01, button.AbsoluteSize.X / math.max(1, button.Size.X.Offset))
		local before, after = (button.AbsolutePosition - low) / scale, (high - button.AbsolutePosition - button.AbsoluteSize) / scale
		ring.Position = UDim2.fromOffset(-before.X - 4, -before.Y - 4)
		ring.Size = UDim2.new(1, before.X + after.X + 8, 1, before.Y + after.Y + 8)
	end
	local corner = button:FindFirstChildOfClass("UICorner")
	if corner then corner:Clone().Parent = ring else W.round(ring, 12) end
	W.stroke(ring, W.gold, 3)
	self.ring = ring

	local fromRight = side == "Right"
	local arrow = W.title(ring, if fromRight then "◀" else "▶", 0, 0, 22, 24, 21, W.gold)
	arrow.Name, arrow.ZIndex = "Guide arrow", ring.ZIndex + 1
	-- The Surface spotlight draws its arrow above the shade, beside its instruction.
	arrow.Visible = side ~= "Spotlight"
	arrow.AnchorPoint = Vector2.new(if fromRight then 0 else 1, 0.5)
	local edge, sign = if fromRight then 1 else 0, if fromRight then 1 else -1
	arrow.Position = UDim2.new(edge, 2 * sign, 0.5, 0)
	W.outlineText(arrow, 2)
	if motion and arrow.Visible then
		self.pulse = TweenService:Create(arrow, TweenInfo.new(0.46, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = UDim2.new(edge, 14 * sign, 0.5, 0) })
		self.pulse:Play()
	end
end

return GuideButton
