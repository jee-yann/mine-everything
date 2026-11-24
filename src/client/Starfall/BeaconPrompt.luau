local Input = game:GetService("UserInputService")
local W = require(script.Parent.Parent.Widgets)
local frames = require(script.Parent.ExposureSheet).frames

-- Sample this same lift at earlier exposures to leave crisp, evenly spaced
-- silhouettes even when the renderer skips a picture.
local function lift(age)
	return math.clamp((age + 1) / 6, 0, 1)
end

-- Spring travel in button heights. The cap clears the socket, reaches its
-- apex, touches down a second time and settles on the original rest pose.
local releasePoses = {
	{ 0, 0.20, 1.035, 0.78 }, { 2, -0.32, 0.985, 1.06 },
	{ 4, -0.86, 0.97, 1.10 }, { 6, -0.69, 0.985, 1.05 },
	{ 9, 0.075, 1.015, 0.94 }, { 11, -0.05, 0.998, 1.015 }, { 13, 0, 1, 1 },
}
local function pressPose(age, releaseAt)
	if age < releaseAt then
		local p = math.clamp((age + 1) / 2, 0, 1)
		return 0.20 * p, 1 + 0.035 * p, 1 - 0.22 * p
	end
	local t = age - releaseAt
	for i = 2, #releasePoses do
		local a, b = releasePoses[i - 1], releasePoses[i]
		if t < b[1] then
			local p = (t - a[1]) / (b[1] - a[1])
			p = p * p * (3 - 2 * p)
			return a[2] + (b[2] - a[2]) * p, a[3] + (b[3] - a[3]) * p, a[4] + (b[4] - a[4]) * p
		end
	end
	return 0, 1, 1
end

return function(safe)
	local button = Instance.new("TextButton")
	button.Name, button.Text, button.Visible, button.Selectable = "Strike sample", "", false, false
	button.BackgroundColor3, button.BorderSizePixel = Color3.fromHex("222238"), 0
	button.AutoButtonColor = false
	button.AnchorPoint, button.ZIndex, button.Parent = Vector2.new(0.5, 1), 11, safe
	W.round(button, 9)
	W.gradient(button, Color3.fromHex("3A3860"), Color3.fromHex("141B2E"))
	local rim = W.stroke(button, Color3.fromHex("8FE9FF"), 2)
	local socket = W.frame(safe, "Strike socket", 0, 0, 1, 1, Color3.fromHex("FFFFFF"))
	socket.AnchorPoint, socket.ZIndex, socket.Visible, socket.Active = button.AnchorPoint, 7, false, false
	W.round(socket, 10)
	W.stroke(socket, Color3.fromHex("171C2B"), 2)
	W.gradient(socket, Color3.fromHex("696082"), Color3.fromHex("242538"))
	local echoes = {}
	for i = 1, 3 do
		local echo = Instance.new("Frame")
		echo.Name, echo.BackgroundTransparency = "Strike outline " .. i, 1
		echo.AnchorPoint, echo.ZIndex, echo.Visible = button.AnchorPoint, button.ZIndex - i, false
		echo.Active, echo.Selectable, echo.Parent = false, false, safe
		W.round(echo, 9)
		local edge = W.stroke(echo, Color3.fromHex("D7FFEF"), 2)
		echoes[i] = { frame = echo, edge = edge }
	end
	local key = W.title(button, "", 0, 0, 1, 1, 22, Color3.fromHex("27243A"))
	key.Name, key.TextScaled, key.ZIndex = "Input key", true, 12
	key.AnchorPoint, key.Position, key.Size = Vector2.new(0, 0.5), UDim2.fromScale(0.045, 0.48), UDim2.fromScale(0.27, 0.62)
	key.BackgroundColor3, key.BackgroundTransparency = Color3.fromHex("D9F7FF"), 0
	W.round(key, 5)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.08, 0), UDim.new(0.08, 0)
	pad.PaddingTop, pad.PaddingBottom, pad.Parent = UDim.new(0.08, 0), UDim.new(0.08, 0), key
	local action = W.title(button, "Break it open", 0, 0, 1, 1, 26, Color3.fromHex("FFF8E5"))
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
	return button, function(frame, motion, contact, top, bottom, releaseFrame)
		local press = contact
		local age = if press then frame - press else -1
		local releaseAt = if press and releaseFrame then math.clamp(releaseFrame - press, 3, 7) else 3
		local confirming = press ~= nil and age >= 0 and age < releaseAt + 14
		local offered = not contact and frame >= frames.prompt and frame < frames.autoStrike
		button.Interactable, button.Visible = offered, offered or confirming
		socket.Visible = button.Visible
		for _, echo in echoes do
			echo.frame.Visible = false
		end
		if not button.Visible then return end
		local device = Input.PreferredInput
		if device ~= lastDevice then
			local gamepadKey = if device == Enum.PreferredInput.Gamepad then Input:GetStringForKeyCode(Enum.KeyCode.ButtonX) else ""
			key.Text = if device == Enum.PreferredInput.Touch then "TAP"
				elseif device == Enum.PreferredInput.Gamepad then (if gamepadKey == "" then "X" else gamepadKey:gsub("^Button", ""))
				else "SPACE"
			lastDevice = device
		end
		local pictureHeight = math.max(1, bottom - top)
		local height = math.clamp(pictureHeight * 0.092, 44, 72)
		local waiting = frame - frames.prompt
		local width = math.min(height * 4.55, safe.AbsoluteSize.X * 0.82)
		local entrance = height * 0.74
		local depth = height * 0.22
		local base = bottom - math.max(entrance + depth + 4, pictureHeight * 0.052)
		local function entryY(picture)
			return base + (if motion then entrance * (1 - lift(picture - frames.prompt)) else 0)
		end
		local function poseAt(picture)
			if confirming and picture >= press then
				if not motion then return base, width, height end
				local offset, w, h = pressPose(picture - press, releaseAt)
				return entryY(press) + height * offset, width * w, height * h
			end
			return entryY(picture), width, height
		end
		local leadY, leadWidth, leadHeight = poseAt(frame)
		socket.Size = UDim2.fromOffset(width * 1.045, height * 0.47)
		socket.Position = UDim2.new(0.5, 0, 0, entryY(if confirming then press else frame) + depth)
		button.Size = UDim2.fromOffset(leadWidth, leadHeight)
		button.Position = UDim2.new(0.5, 0, 0, leadY)
		key.BackgroundColor3 = if confirming then Color3.fromHex("B6F0CC") else Color3.fromHex("D9F7FF")
		action.Text = if not confirming then "Break it open" else "Break it!"
		rim.Color = if confirming then Color3.fromHex("C4FFE2") else Color3.fromHex("8FE9FF")
		glint.Offset = Vector2.new(if motion then math.clamp((waiting % 36) / 21, 0, 1) * 2 - 1 else 0, 0)
		if motion and (confirming or waiting < 12) then
			for i, echo in echoes do
				local previous, w, h = poseAt(frame - i * 1.5)
				if math.abs(previous - leadY) > 2 then
					echo.frame.Position = UDim2.new(0.5, 0, 0, previous)
					echo.frame.Size = UDim2.fromOffset(w, h)
					local initial = if confirming then 0.10 else 0.26
					local trailAge = if confirming then age else waiting
					echo.edge.Transparency = math.min(1, initial + 0.16 * i + 0.30 * math.clamp((trailAge - 9) / 6, 0, 1))
					echo.frame.Visible = true
				end
			end
		end
	end
end
