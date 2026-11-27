local W = require(script.Parent.Widgets)
local Icons = require(script.Parent.Icons)

local TouchActions = {}
TouchActions.__index = TouchActions

-- The Mine button matches Roblox's classic jump button: a round, see-through dark disc with a white
-- ring and a white symbol (a pickaxe), the same size as the jump button and beside it. Its mode sits
-- in small type under the disc.
local size = 70
function TouchActions.new(root)
	local self = setmetatable({}, TouchActions)
	-- Not a button: like a shooter's fire button, a touch on it doesn't stop the touch from turning
	-- the camera. The game watches for touches that start on the disc (TouchActions:hit).
	self.hold = W.frame(root, "Mine", 0, 0, size + 40, size + 30, W.ink)
	self.hold.BackgroundTransparency, self.hold.Active = 1, false
	local disc = W.frame(self.hold, "Disc", 20, 0, size, size, Color3.new(0, 0, 0), size / 2)
	disc.BackgroundTransparency = 0.5
	local ring = Instance.new("UIStroke")
	ring.ApplyStrokeMode, ring.Color, ring.Thickness, ring.Transparency = Enum.ApplyStrokeMode.Border, Color3.new(1, 1, 1), 3, 0.1
	ring.Parent = disc
	self.disc, self.ring = disc, ring
	local icon = Icons.draw(disc, "Power", size * 0.22, size * 0.2, size * 0.56, Color3.new(1, 1, 1))
	local _ = icon
	self.label = W.title(self.hold, "", 0, size + 2, size + 40, 15, 13, W.white)
	self.hint = W.text(self.hold, "", 0, size + 16, size + 40, 13, 11, W.white)
	self.label.Name, self.hint.Name = "Mining mode", "Gesture hint"
	W.outlineText(self.label, 1.6)
	W.outlineText(self.hint, 1.2)

	self:setAuto(false)
	return self
end

-- Whether a screen point (a touch's Position) is on the Mine disc.
-- Roblox says what is under the touch, in the touch's own coordinates, so insets, notches and the
-- top bar never shift the target (adding the inset by hand put it 58 pixels off on phones). The whole
-- Mine area counts, the disc and the margin round it, as a thumb is wide.
function TouchActions:hit(point)
	if not self.hold.Visible then return false end
	local gui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not gui then return false end
	for _, object in gui:GetGuiObjectsAtPosition(point.X, point.Y) do
		if object == self.hold or object:IsDescendantOf(self.hold) then return true end
	end
	return false
end

function TouchActions:setPressed(pressed)
	self.disc.BackgroundTransparency = if pressed then 0.3 else 0.5
end

function TouchActions:setAuto(enabled)
	self.enabled = enabled
	self.label.Text = if enabled then "Auto mine ON" else "Hold to mine"
	self.label.TextColor3 = if enabled then W.green else W.white
	if self.ring then self.ring.Color = if enabled then W.green else Color3.new(1, 1, 1) end
	self.hint.Text = if enabled then "Double-tap to stop" else "Double-tap for auto"
end

-- The jump button keeps Roblox's classic look; the Mine button is drawn to match it. (An older
-- custom skin is removed if it's there.)
function TouchActions.skinJump(jump)
	local old = jump:FindFirstChild("Miner jump")
	if old then
		old:Destroy()
		jump.ImageTransparency = 0
	end
end

function TouchActions:layout(root, jump, visible, toolsBottom)
	self.hold.Visible = visible
	if not visible then
		return
	end
	local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
	local size = if jump then jump.AbsoluteSize else Vector2.new(70, 70)
	local pos = if jump then jump.AbsolutePosition - root.AbsolutePosition else Vector2.new(width - 88, height - 90)
	-- The disc matches the jump button's size and sits to its left, centres level, like Roblox's own
	-- action buttons; the mode text hangs under it.
	local disc = math.max(56, math.min(size.X, size.Y))
	self.hold.Size = UDim2.fromOffset(disc + 40, disc + 30)
	self.disc.Size, self.disc.Position = UDim2.fromOffset(disc, disc), UDim2.fromOffset(20, 0)
	self.disc:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.5, 0)
	self.label.Position, self.hint.Position = UDim2.fromOffset(0, disc + 2), UDim2.fromOffset(0, disc + 16)
	self.label.Size, self.hint.Size = UDim2.fromOffset(disc + 40, 15), UDim2.fromOffset(disc + 40, 13)
	local extent = Vector2.new(disc + 40, disc + 30)
	-- A little higher than the jump button's centre, so the mode text never meets the screen's edge.
	local x, y = pos.X - disc - 34, pos.Y + (size.Y - disc) / 2 - 14
	if x < 0 then
		x, y = pos.X + (size.X - extent.X) / 2, pos.Y - extent.Y - 8
	end
	if y < toolsBottom then
		y = math.max(toolsBottom, y)
	end
	local corner = Vector2.new(math.clamp(x, 0, math.max(0, width - extent.X)), math.clamp(y, 0, height - extent.Y - 8))
	W.anchor(self.hold, 0.5, 0.5, UDim2.fromOffset(corner.X + extent.X / 2, corner.Y + extent.Y / 2))
	local bounds = { Rect.new(pos, pos + size), Rect.new(corner, corner + extent) }
	table.sort(bounds, function(a, b)
		return a.Min.Y > b.Min.Y
	end)
	return bounds
end

function TouchActions.feedbackPosition(screen, size, footer, bounds)
	local x, y = screen.X / 2, screen.Y - footer
	if bounds then
		local left = screen.X
		for _, box in bounds do
			if box.Min.Y < y + 6 and box.Max.Y > y - size.Y - 6 then
				left = math.min(left, box.Min.X - 8)
			end
		end
		if screen.X >= screen.Y and left - size.X >= 100 then
			x = math.min(x, left - size.X / 2)
		else
			for _, box in bounds do
				if
					x + size.X / 2 > box.Min.X - 6
					and x - size.X / 2 < box.Max.X + 6
					and y > box.Min.Y - 6
					and y - size.Y < box.Max.Y + 6
				then
					y = box.Min.Y - 7
				end
			end
		end
	end
	return UDim2.new(0.5, x - screen.X / 2, 1, y - screen.Y)
end

return TouchActions
