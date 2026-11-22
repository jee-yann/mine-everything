local Input = game:GetService("UserInputService")
local W = require(script.Parent.Parent.Widgets)
local frames = require(script.Parent.ExposureSheet).frames

return function(safe)
	local button = Instance.new("TextButton")
	button.Name, button.Text, button.Visible, button.Selectable = "Strike sample", "", false, false
	button.BackgroundColor3, button.BorderSizePixel = Color3.fromHex("222238"), 0
	button.AnchorPoint, button.ZIndex, button.Parent = Vector2.new(0.5, 1), 11, safe
	W.round(button, 9)
	W.gradient(button, Color3.fromHex("3A3860"), Color3.fromHex("141B2E"))
	local rim = W.stroke(button, Color3.fromHex("F6C979"), 2)
	local key = W.title(button, "", 0, 0, 1, 1, 22, Color3.fromHex("27243A"))
	key.Name, key.TextScaled, key.ZIndex = "Input key", true, 12
	key.AnchorPoint, key.Position, key.Size = Vector2.new(0, 0.5), UDim2.fromScale(0.045, 0.48), UDim2.fromScale(0.27, 0.62)
	key.BackgroundColor3, key.BackgroundTransparency = Color3.fromHex("FFE3A1"), 0
	W.round(key, 5)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.08, 0), UDim.new(0.08, 0)
	pad.PaddingTop, pad.PaddingBottom, pad.Parent = UDim.new(0.08, 0), UDim.new(0.08, 0), key
	local action = W.title(button, "Light the path", 0, 0, 1, 1, 26, Color3.fromHex("FFF8E5"))
	action.Name, action.TextScaled, action.ZIndex = "Action", true, 12
	action.AnchorPoint, action.Position, action.Size = Vector2.new(0, 0.5), UDim2.fromScale(0.35, 0.48), UDim2.fromScale(0.60, 0.60)
	W.outlineText(action, 1.2)

	-- A single sweep along the keyline echoes the travelling seam in the next shot.
	local rail = W.frame(button, "Beacon keyline", 0, 0, 1, 3, Color3.new(1, 1, 1))
	rail.AnchorPoint, rail.Position, rail.Size = Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.new(0.87, 0, 0, 3)
	rail.ZIndex = 13
	local glint = W.gradient(rail, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 0)
	glint.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("8277A9")), ColorSequenceKeypoint.new(0.28, Color3.fromHex("AD96E4")),
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("FFF6D8")), ColorSequenceKeypoint.new(0.71, Color3.fromHex("B99DF2")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("8277A9")),
	})
	local lastDevice
	return button, function(frame, motion, contact, top, bottom)
		button.Visible = frame >= frames.prompt and frame < frames.autoStrike and not contact
		if not button.Visible then return end
		local device = Input.PreferredInput
		if device ~= lastDevice then
			local gamepadKey = if device == Enum.PreferredInput.Gamepad then Input:GetStringForKeyCode(Enum.KeyCode.ButtonX) else ""
			key.Text = if device == Enum.PreferredInput.Touch then "TAP"
				elseif device == Enum.PreferredInput.Gamepad then (if gamepadKey == "" then "X" else gamepadKey:gsub("^Button", ""))
				else "SPACE"
			lastDevice = device
		end
		local age = frame - frames.prompt
		local pictureHeight = math.max(1, bottom - top)
		local height = math.clamp(pictureHeight * 0.092, 44, 72)
		local rise = if motion then math.max(0, 1 - age / 5) ^ 2 else 0
		local width = math.min(height * 4.55, safe.AbsoluteSize.X * 0.82)
		button.Size = UDim2.fromOffset(width, height)
		button.Position = UDim2.new(0.5, 0, 0, bottom - math.max(8, pictureHeight * 0.052) + 8 * rise)
		rim.Color = if rise > 0 then Color3.fromHex("FFF1CD") else Color3.fromHex("F6C979")
		glint.Offset = Vector2.new(if motion then math.clamp((age % 36) / 21, 0, 1) * 2 - 1 else 0, 0)
	end
end
