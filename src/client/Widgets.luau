local TweenService = game:GetService("TweenService")
local Audio = require(script.Parent.HarborAudio)
local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
local Purity = require(game:GetService("ReplicatedStorage").Shared.OrePurity)
local W = {}
local rgb = Color3.fromRGB
W.ink, W.panel, W.card, W.line = rgb(18, 24, 44), rgb(30, 41, 65), rgb(48, 61, 89), rgb(77, 95, 127)
W.white, W.muted, W.gold, W.aqua, W.green =
	rgb(255, 253, 245), rgb(206, 220, 234), rgb(255, 209, 76), rgb(88, 224, 252), rgb(110, 236, 150)
W.pink, W.violet, W.orange = rgb(255, 128, 191), rgb(186, 149, 255), rgb(255, 165, 90)
W.rebirth = rgb(255, 128, 140)
W.ruby, W.ocean, W.grape = rgb(183, 63, 48), rgb(9, 115, 150), rgb(121, 66, 177)
local off = UDim2.fromOffset
function W.round(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius, c.Parent = UDim.new(0, r), obj
end
function W.stroke(obj, color, width)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode, s.Color, s.Thickness, s.Parent = Enum.ApplyStrokeMode.Border, color, width, obj
	return s
end
function W.gradient(obj, top, bottom, angle)
	local g = Instance.new("UIGradient")
	g.Color, g.Rotation, g.Parent = ColorSequence.new(top, bottom), angle or 90, obj
	return g
end
function W.frame(parent, name, x, y, w, h, color, r)
	local f = Instance.new("Frame")
	f.Name, f.Position, f.Size, f.BackgroundColor3, f.BorderSizePixel = name, off(x, y), off(w, h), color, 0
	if r then
		W.round(f, r)
	end
	f.Parent = parent
	return f
end
function W.fadeGroup(parent, name, width, height)
	local group = Instance.new("CanvasGroup")
	group.Name, group.Size = name, off(width, height)
	group.BackgroundTransparency, group.BorderSizePixel, group.Parent = 1, 0, parent
	return group
end
function W.text(parent, value, x, y, w, h, size, color, left)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency, l.Text, l.TextSize, l.Font, l.TextColor3 =
		1, value, size, Enum.Font.BuilderSansBold, color
	l.TextXAlignment = if left then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
	l.Position, l.Size, l.Parent = off(x, y), off(w, h), parent
	return l
end
-- The largest size from `most` down to `least` at which the text fits its box. Text scaling in a
-- scaled menu comes out far smaller than its limit, so the size is worked out here instead.
function W.largest(label, most, least)
	local Text = game:GetService("TextService")
	label.TextScaled, label.TextWrapped = false, true
	local function fit()
		local box = label.Size
		local bare = string.gsub(label.Text, "<[^>]->", "")
		for size = most, least, -1 do
			label.TextSize = size
			local need = Text:GetTextSize(bare, size, label.Font, Vector2.new(box.X.Offset - 8, 10000))
			if need.Y + 2 <= box.Y.Offset then break end
		end
	end
	label:GetPropertyChangedSignal("Text"):Connect(fit)
	label:GetPropertyChangedSignal("Size"):Connect(fit)
	label:GetPropertyChangedSignal("Font"):Connect(fit)
	fit()
end
-- Shows the first of `options` (after `prefix`) that fits on one line of `label`, else the last.
function W.fitText(label, options, prefix)
	prefix = prefix or ""
	local bounds = Vector2.new(10000, label.Size.Y.Offset)
	for _, option in options do
		local text = prefix .. option
		local size = game:GetService("TextService"):GetTextSize(text, label.TextSize, label.Font, bounds)
		if size.X <= label.Size.X.Offset then
			label.Text = text
			return text
		end
	end
	label.Text = prefix .. options[#options]
	return label.Text
end
function W.title(parent, value, x, y, w, h, size, color, left)
	local l = W.text(parent, value, x, y, w, h, size, color, left)
	l.Font = Enum.Font.FredokaOne
	return l
end
function W.enamel(obj, top, bottom)
	obj.BackgroundColor3 = Color3.new(1, 1, 1)
	return W.gradient(obj, top, bottom, 34)
end
W.navy = rgb(41, 38, 74)
-- A tile face: thick navy edge, gradient and a pale inner rim.
function W.enamelPanel(obj, top, bottom, radius)
	obj.BackgroundColor3, obj.BackgroundTransparency = Color3.new(1, 1, 1), 0
	if not obj:FindFirstChildOfClass("UICorner") then W.round(obj, radius) end
	local edge = W.stroke(obj, W.navy, 4)
	local paint = W.gradient(obj, top, bottom, 90)
	local rim = W.frame(obj, "Rim", 3, 3, 0, 0, W.white, math.max(1, radius - 3))
	rim.Size, rim.BackgroundTransparency = UDim2.new(1, -6, 1, -6), 1
	W.stroke(rim, W.white, 2).Transparency = 0.66
	return paint, edge
end
-- A listing in a menu card: the card's slate, lit by the listing's colour.
function W.rowPanel(obj, color)
	obj.BackgroundColor3 = Color3.new(1, 1, 1)
	local h, s = color:ToHSV()
	s = if s < 0.08 then s else math.clamp(s * 1.15, 0.5, 0.8)
	local paint = W.gradient(obj, Color3.fromHSV(h, s, 0.68), Color3.fromHSV(h, s, 0.46), 90)
	local rim = W.frame(obj, "Rim", 2, 2, 0, 0, W.white, 9)
	rim.Size, rim.BackgroundTransparency = UDim2.new(1, -4, 1, -4), 1
	W.stroke(rim, color:Lerp(W.white, 0.4), 2).Transparency = 0.6
	return paint
end
function W.navyText(label, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness = Enum.ApplyStrokeMode.Contextual, W.navy, thickness
	stroke.LineJoinMode, stroke.Parent = Enum.LineJoinMode.Round, label
	return stroke
end
function W.outlineText(label, thickness)
	if thickness then
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness = Enum.ApplyStrokeMode.Contextual, W.ink, thickness
		stroke.Parent = label
	else
		label.TextStrokeColor3, label.TextStrokeTransparency = W.ink, 0.15
	end
end
local function animateButton(button)
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "Interaction scale", button
	local isClose = button.Name == "Close"
	local restingColor = button.BackgroundColor3
	local over, pressed, focused, tween = false, false, false, nil
	local function update()
		local enabled = button.Interactable and game.Players.LocalPlayer:GetAttribute("MenuMotion") ~= false
		local highlighted = over or focused
		if isClose then
			button.BackgroundColor3 = if highlighted
					and button.Interactable
					and not pressed
				then restingColor:Lerp(W.white, 0.08)
				else restingColor
		end
		local target = if not enabled then 1 elseif pressed then 0.94 elseif highlighted and not isClose then 1.045 else 1
		if tween then
			tween:Cancel()
		end
		tween = W.tween(scale, if pressed then 0.07 else 0.13, { Scale = target })
	end
	button.MouseEnter:Connect(function()
		over = true
		update()
	end)
	button.MouseLeave:Connect(function()
		over, pressed = false, false
		update()
	end)
	button.SelectionGained:Connect(function()
		focused = true
		update()
	end)
	button.SelectionLost:Connect(function()
		focused, pressed = false, false
		update()
	end)
	button.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			pressed = true
			update()
		end
	end)
	button.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			pressed = false
			update()
		end
	end)
	button:GetPropertyChangedSignal("Interactable"):Connect(update)
end

function W.dot(parent, x, y)
	local dot = W.frame(parent, "Notification", 0, 0, 12, 12, Color3.fromRGB(255, 68, 82), 6)
	dot.Position, dot.ZIndex = UDim2.new(1, x, 0, y), 3
	W.stroke(dot, W.ink, 1.6)
	dot.Visible = false
	return dot
end
function W.pointBadge(parent, x, y)
	local count = W.title(parent, "", 0, 0, 26, 19, 14, W.ink)
	count.Name, count.ZIndex, count.Visible = "Skill points", 3, false
	W.anchor(count, 1, 0, UDim2.new(1, x, 0, y))
	count.BackgroundTransparency, count.BackgroundColor3, count.TextScaled = 0, W.gold, true
	W.round(count, 9)
	W.stroke(count, W.ink, 1.8)
	local font = Instance.new("UITextSizeConstraint")
	font.MinTextSize, font.MaxTextSize, font.Parent = 8, 14, count
	return count
end
function W.clearButton(parent, name, x, y, w, h, cue)
	local b = Instance.new("TextButton")
	b.Name, b.Text, b.BackgroundTransparency = name, "", 1
	b.Position, b.Size, b.Parent = off(x, y), off(w, h), parent
	animateButton(b)
	Audio.bind(b, cue)
	return b
end
function W.button(parent, name, x, y, w, h, tint, label, cue)
	local b = Instance.new("TextButton")
	b.Name, b.Position, b.Size, b.BackgroundColor3, b.BorderSizePixel = name, off(x, y), off(w, h), tint, 0
	b.Text, b.TextColor3, b.TextSize, b.Font = label, W.white, 17, Enum.Font.FredokaOne
	W.round(b, 10)
	W.stroke(b, W.navy, 3)
	W.navyText(b, 2.2)
	W.gradient(b, Color3.new(1, 1, 1), rgb(196, 188, 214), 90)
	local gleam = W.frame(b, "Enamel highlight", 8, 2, w - 16, 2, W.white, 1)
	gleam.BackgroundTransparency = 0.48
	b.Parent = parent
	animateButton(b)
	Audio.bind(b, cue)
	return b
end
function W.closeButton(parent, x, y, size)
	local button = W.button(parent, "Close", x, y, size, size, rgb(225, 64, 76), "×", "Close")
	-- Roblox releases first-person mouse capture while a modal button is visible.
	-- The normal camera takes the pointer back when the panel is hidden.
	button.Modal = true
	button.AutoButtonColor = false
	button.TextColor3, button.TextSize = W.white, 40
	local gleam = button["Enamel highlight"]
	gleam.AnchorPoint, gleam.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 4)
	gleam.Size, gleam.BackgroundTransparency = UDim2.new(0.32, 0, 0, 2), 0.68
	return button
end
function W.scale(obj)
	local s = Instance.new("UIScale")
	s.Parent = obj
	return s
end
function W.anchor(obj, x, y, pos)
	obj.AnchorPoint, obj.Position = Vector2.new(x, y), pos
end
function W.tween(obj, d, props)
	local t = TweenService:Create(obj, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end
function W.goldAmount(n)
	local grouped = string.format("%.0f", n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return grouped
end
-- A short whole number: 950, 12.4k, 1.2M. Gold never shows decimals.
function W.number(n)
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	end
	if n >= 10000 then
		return string.format("%.1fk", n / 1000)
	end
	return tostring(math.floor(n + 0.5))
end
-- A countdown: 4:05, or 1:02:09 from an hour.
function W.clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local h, m, s = seconds // 3600, seconds // 60 % 60, seconds % 60
	return if h > 0 then string.format("%d:%02d:%02d", h, m, s) else string.format("%d:%02d", m, s)
end
function W.colored(text, color)
	return string.format('<font color="#%s">%s</font>', color:ToHex(), text)
end
function W.unitPrice(value)
	return W.colored(W.number(value) .. " G each", W.gold)
end
function W.possiblePrice(ore, player)
	local low, high = Purity.priceRange(ore, player:GetAttribute("SkillBroker"))
	local multiplier = Rebirth.saleMultiplier(player)
	local amount = W.number(low * multiplier)
	if low ~= high then amount ..= "–" .. W.number(high * multiplier) end
	return amount .. " G"
end
return W
