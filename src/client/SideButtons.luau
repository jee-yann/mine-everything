-- The side buttons: square enamel tiles holding a FieldKit sticker icon, a caption, the keyboard
-- shortcut's letter and an optional red badge. Menus sit in a rail on the left and rewards on
-- the right (Hud lays them out). The art is drawn in art/hud/field_kit.html.
local W = require(script.Parent.Widgets)
local FieldKit = require(script.Parent.FieldKit)

local SideButtons = {}
local rgb = Color3.fromRGB
local NAVY = W.navy
local SIZE, RADIUS = 84, 15
SideButtons.size, SideButtons.navy = SIZE, NAVY
SideButtons.ready = rgb(125, 255, 122)

-- Each tile matches the colour of the menu it opens.
local tints = {
	Inventory = { rgb(255, 208, 138), rgb(240, 138, 58) },
	Skills = { rgb(166, 245, 154), rgb(52, 178, 74) },
	Achievements = { rgb(255, 230, 128), rgb(243, 165, 26) },
	Book = { rgb(134, 214, 255), rgb(47, 130, 230) },
	Settings = { rgb(214, 223, 235), rgb(125, 144, 170) },
	Daily = { rgb(255, 159, 200), rgb(227, 69, 138) },
	Playtime = { rgb(207, 174, 255), rgb(129, 80, 230) },
}

local function outline(label, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness = Enum.ApplyStrokeMode.Contextual, NAVY, thickness
	stroke.Parent = label
end

-- The shortcut as plain text, [B], sitting on the lower right corner, half on the button and half off.
function SideButtons.letter(parent, key, x, y, size)
	local cap = W.title(parent, "[" .. key .. "]", 0, 0, 44, 28, size or 23, W.white)
	W.anchor(cap, 0.5, 0.5, UDim2.fromOffset(x, y))
	cap.Name, cap.ZIndex = "Key", 7
	outline(cap, 2.8)
	return cap
end

-- A tile button for `key` (a FieldKit icon), captioned `caption`, with keyboard shortcut `shortcut`.
-- Returns a record with the button, its caption, keycap and icon holder.
function SideButtons.tile(parent, key, caption, shortcut)
	local tint = tints[key]
	local button = W.clearButton(parent, key, 0, 0, SIZE, SIZE + 6, "Open")
	local shadow = W.frame(button, "Shadow", 0, 6, SIZE, SIZE, NAVY, RADIUS)
	shadow.ZIndex = 1
	local face = W.frame(button, "Face", 0, 0, SIZE, SIZE, W.white, RADIUS)
	face.ZIndex = 2
	W.stroke(face, NAVY, 4)
	W.gradient(face, tint[1], tint[2], 90)
	local rim = W.frame(face, "Rim", 3, 3, SIZE - 6, SIZE - 6, W.white, RADIUS - 3)
	rim.BackgroundTransparency, rim.ZIndex = 1, 2
	W.stroke(rim, W.white, 2.5).Transparency = 0.55
	local icon = W.frame(face, "Icon", 12, 1, SIZE - 24, SIZE - 24, W.white)
	icon.BackgroundTransparency, icon.ZIndex = 1, 3
	FieldKit.draw(icon, key)
	local label = W.title(face, caption, -8, SIZE - 31, SIZE + 16, 24, 17, W.white)
	label.Name, label.ZIndex = "Caption", 4
	outline(label, 2.6)
	local cap = SideButtons.letter(face, shortcut, SIZE - 5, SIZE + 1)
	-- A small lean on hover, on top of the shared press-and-hover scale.
	button.MouseEnter:Connect(function()
		W.tween(face, 0.12, { Rotation = -3 })
	end)
	button.MouseLeave:Connect(function()
		W.tween(face, 0.12, { Rotation = 0 })
	end)
	return { button = button, face = face, icon = icon, caption = label, key = cap, text = caption }
end

-- A round Settings-style button: just the icon on a small enamel disc.
function SideButtons.round(parent, key, shortcut)
	local tint = tints[key]
	local button = W.clearButton(parent, key, 0, 0, 54, 58, "Open")
	local shadow = W.frame(button, "Shadow", 0, 4, 54, 54, NAVY, 27)
	shadow.ZIndex = 1
	local face = W.frame(button, "Face", 0, 0, 54, 54, W.white, 27)
	face.ZIndex = 2
	W.stroke(face, NAVY, 4)
	W.gradient(face, tint[1], tint[2], 90)
	local icon = W.frame(face, "Icon", 6, 5, 42, 42, W.white)
	icon.BackgroundTransparency, icon.ZIndex = 1, 3
	FieldKit.draw(icon, key)
	local cap = SideButtons.letter(face, shortcut, 48, 49)
	button.MouseEnter:Connect(function()
		W.tween(icon, 0.25, { Rotation = 60 })
	end)
	button.MouseLeave:Connect(function()
		W.tween(icon, 0.25, { Rotation = 0 })
	end)
	return { button = button, face = face, icon = icon, key = cap }
end

-- A red badge on the tile's top-right corner: a count, "!" or "NEW". Hidden until shown.
function SideButtons.badge(tile, text)
	local badge = W.title(tile.button, text or "!", 0, 0, 18, 28, 16, W.white)
	badge.Name, badge.ZIndex, badge.Visible = "Badge", 6, false
	W.anchor(badge, 0.5, 0.5, UDim2.new(1, -5, 0, 5))
	badge.BackgroundTransparency, badge.BackgroundColor3 = 0, rgb(255, 59, 85)
	badge.AutomaticSize = Enum.AutomaticSize.X
	W.round(badge, 14)
	W.stroke(badge, NAVY, 3)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight, pad.Parent = UDim.new(0, 5), UDim.new(0, 5), badge
	local size = Instance.new("UISizeConstraint")
	size.MinSize, size.Parent = Vector2.new(28, 28), badge
	return badge
end

-- Ready state for a reward tile: the icon wiggles every so often and the caption turns green.
function SideButtons.setReady(tile, ready, caption)
	tile.caption.Text = caption or (if ready then "Ready!" else tile.text)
	tile.caption.TextColor3 = if ready then SideButtons.ready else W.white
	if tile.readyLoop == ready then
		return
	end
	tile.readyLoop = ready
	tile.icon.Rotation = 0
	if not ready then
		return
	end
	task.spawn(function()
		local icon = tile.icon
		while tile.readyLoop and icon.Parent do
			for _, step in { { -10, 0.08 }, { 9, 0.1 }, { -5, 0.08 }, { 2, 0.07 }, { 0, 0.07 } } do
				W.tween(icon, step[2], { Rotation = step[1] })
				task.wait(step[2])
			end
			task.wait(1.2)
		end
		icon.Rotation = 0
	end)
end

return SideButtons
