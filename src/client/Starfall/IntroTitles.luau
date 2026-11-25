-- The player's name plate and the closing line. The plate is cut glass: a
-- translucent panel with a lit edge, one sweep of light and no outlines.
local F = require(script.Parent.ExposureSheet).frames
local Titles = {}
local hex = Color3.fromHex
local family = "rbxasset://fonts/families/Montserrat.json"
local heavy = Font.new(family, Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local medium = Font.new(family, Enum.FontWeight.SemiBold)

local function text(parent, font, color, size)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency, t.FontFace, t.TextColor3, t.TextSize = 1, font, color, size
	t.TextXAlignment, t.TextYAlignment, t.ZIndex, t.Parent = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 9, parent
	return t
end

local function smooth(u)
	u = math.clamp(u, 0, 1)
	return 1 - (1 - u) ^ 3
end

function Titles.new(safe, screen)
	local viewer = game:GetService("Players").LocalPlayer
	local name = if viewer then viewer.DisplayName else "Miner"

	local group = Instance.new("CanvasGroup")
	group.Name, group.BackgroundTransparency, group.BorderSizePixel = "Player introduction", 1, 0
	group.AnchorPoint, group.Size, group.Visible, group.ZIndex, group.Parent = Vector2.new(0, 1), UDim2.fromOffset(620, 190), false, 8, safe
	local scale = Instance.new("UIScale")
	scale.Parent = group
	local plate = Instance.new("Frame")
	plate.Name, plate.BorderSizePixel, plate.BackgroundColor3, plate.BackgroundTransparency = "Glass plate", 0, Color3.new(1, 1, 1), 0
	plate.Position, plate.Size, plate.ZIndex, plate.Parent = UDim2.fromOffset(6, 46), UDim2.fromOffset(600, 112), 8, group
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 5), plate
	local fill = Instance.new("UIGradient")
	fill.Color = ColorSequence.new(hex("260A6B"), hex("9A52FF"))
	fill.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.20), NumberSequenceKeypoint.new(0.55, 0.42), NumberSequenceKeypoint.new(1, 0.92),
	})
	fill.Parent = plate
	local stroke = Instance.new("UIStroke")
	stroke.Thickness, stroke.Color, stroke.Parent = 1.5, Color3.new(1, 1, 1), plate
	local edge = Instance.new("UIGradient")
	edge.Color = ColorSequence.new(hex("FFFFFF"), hex("CFA0FF"))
	edge.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1),
	})
	edge.Rotation, edge.Parent = 18, stroke
	local gleam = Instance.new("Frame")
	gleam.BorderSizePixel, gleam.BackgroundColor3, gleam.Size, gleam.ZIndex = 0, Color3.new(1, 1, 1), UDim2.fromScale(1, 1), 8
	gleam.Parent = plate
	corner:Clone().Parent = gleam
	local sweep = Instance.new("UIGradient")
	sweep.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.46, 1), NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.54, 1), NumberSequenceKeypoint.new(1, 1),
	})
	sweep.Rotation, sweep.Parent = 22, gleam
	local bar = Instance.new("Frame")
	bar.BorderSizePixel, bar.BackgroundColor3, bar.ZIndex, bar.Parent = 0, Color3.new(1, 1, 1), 9, plate
	local barTint = Instance.new("UIGradient")
	barTint.Color, barTint.Rotation, barTint.Parent = ColorSequence.new(hex("FFFFFF"), hex("B77BFF")), 90, bar
	local lead = text(group, medium, hex("F1E6FF"), 23)
	lead.Text, lead.Position, lead.Size = "C I T R I N E   C O V E   M I N E R", UDim2.fromOffset(34, 8), UDim2.fromOffset(560, 32)
	local title = text(group, heavy, Color3.new(1, 1, 1), 76)
	title.Position, title.Size = UDim2.fromOffset(34, 46), UDim2.fromOffset(556, 112)
	title.Text = name
	local width = game:GetService("TextService"):GetTextSize(name, 76, Enum.Font.GothamBlack, Vector2.new(5000, 200)).X * 1.12
	title.TextSize = math.clamp(math.floor(76 * 540 / math.max(540, width)), 26, 76)

	local closing = Instance.new("Frame")
	closing.Name, closing.BackgroundTransparency, closing.Visible, closing.ZIndex = "Closing line", 1, false, 8
	closing.AnchorPoint, closing.Size, closing.Parent = Vector2.new(0, 1), UDim2.fromOffset(760, 120), safe
	local fit = Instance.new("UIScale")
	fit.Parent = closing
	-- A fall of shade along the foot of the picture, with no edge to see.
	local shade = Instance.new("Frame")
	shade.Name, shade.BorderSizePixel, shade.BackgroundColor3 = "Closing shade", 0, hex("0E0A24")
	shade.AnchorPoint, shade.Visible, shade.ZIndex, shade.Parent = Vector2.new(0.5, 1), false, 1, screen
	local fall = Instance.new("UIGradient")
	fall.Rotation, fall.Transparency, fall.Parent = 90, NumberSequence.new(1, 0.2), shade
	local small = text(closing, medium, hex("FFFFFF"), 25)
	small.Text, small.Size, small.TextXAlignment = "THE STAR ITSELF IS STILL BELOW", UDim2.fromOffset(760, 34), Enum.TextXAlignment.Left
	local large = text(closing, heavy, hex("FFFFFF"), 66)
	large.Text, large.Position, large.Size = "FIND STARFALL", UDim2.fromOffset(0, 36), UDim2.fromOffset(760, 80)
	large.TextXAlignment = Enum.TextXAlignment.Left
	local hue = Instance.new("UIGradient")
	hue.Color, hue.Rotation, hue.Parent = ColorSequence.new(hex("FFFFFF"), hex("D7B8FF")), 90, large
	for _, t in { small, large } do
		t.TextStrokeColor3, t.TextStrokeTransparency = hex("171130"), 0.2
	end

	return function(frame, motion, top, bottom)
		local size = safe.AbsoluteSize
		top, bottom = top or 0, bottom or size.Y
		local picture = math.max(1, bottom - top)
		local tall = size.X < size.Y
		local age, left = frame - (F.reveal + 8), F.answer - 4 - frame
		group.Visible = age >= 0 and left >= 0
		if group.Visible then
			local k = math.min(size.X * (if tall then 0.84 else 0.40) / 620, picture * 0.26 / 190)
			scale.Scale = math.max(0.01, k)
			local inn = if motion then smooth(age / 9) else 1
			local out = if motion then smooth((7 - left) / 7) else 0
			group.GroupTransparency = math.clamp(1 - inn + out, 0, 1)
			group.Position = UDim2.new(0.055, (-70 * (1 - inn) + 46 * out) * k, 0, bottom - picture * 0.07)
			local late = if motion then smooth((age - 3) / 8) else 1
			title.Position = UDim2.fromOffset(34 - 44 * (1 - late), 46)
			title.TextTransparency = 1 - late
			lead.Position = UDim2.fromOffset(34 + 26 * (1 - late), 8)
			lead.TextTransparency = 1 - (if motion then smooth((age - 6) / 8) else 1)
			bar.Position, bar.Size = UDim2.new(0, 0, 0.5 - 0.5 * late, 0), UDim2.new(0, 6, late, 0)
			sweep.Offset = Vector2.new(if motion then math.clamp((age - 8) / 16, 0, 1) * 2.4 - 1.2 else -1.2, 0)
		end
		local a, b = frame - (F.turn + 16), F.handoff + 22 - frame
		closing.Visible = a >= 0 and b >= 0
		shade.Visible = closing.Visible
		if closing.Visible then
			fit.Scale = math.max(0.01, math.min(size.X * (if tall then 0.9 else 0.46) / 760, picture * 0.17 / 120))
			local alpha = (if motion then smooth(a / 10) else 1) * math.clamp(b / 12, 0, 1)
			closing.Position = UDim2.new(0.06, 0, 0, bottom - picture * 0.075 + (if motion then 10 * (1 - smooth(a / 10)) else 0))
			shade.Size, shade.Position = UDim2.new(1, 0, 0, picture * 0.36), UDim2.new(0.5, 0, 0, safe.AbsolutePosition.Y - screen.AbsolutePosition.Y + bottom)
			shade.BackgroundTransparency = 1 - 0.75 * alpha
			for _, t in { small, large } do
				t.TextTransparency, t.TextStrokeTransparency = 1 - alpha, 1 - 0.8 * alpha
			end
		end
	end
end

return Titles
