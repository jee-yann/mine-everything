local Titles = {}
local cuts = require(script.Parent.ExposureSheet).frames
local cream, ochre, ink = Color3.fromHex("FFF6DD"), Color3.fromHex("FFD063"), Color3.fromHex("152121")
local condensed = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)

-- Size the two lines as one piece of type. Each composition has a bottom
-- margin inside the exposed image, measured after the letterbox and UI insets.
local cues = {
	{ first = cuts.portrait + 7, last = cuts.commission - 2, player = true, headline = "GEM HUNTER",
		width = 505, leadSize = 42, mainSize = 89, leading = 36, widthFraction = 0.43, heightFraction = 0.25 },
	{ first = cuts.lode + 13, last = cuts.challenge - 2, lead = "THE RAREST ORE", headline = "STARFALL",
		width = 455, leadSize = 44, mainSize = 90, leading = 39, widthFraction = 0.41, heightFraction = 0.24 },
	{ first = cuts.challenge + 2, last = cuts.handoff + 22, lead = "WILL YOU FIND", headline = "STARFALL FIRST?",
		width = 665, leadSize = 49, mainSize = 88, leading = 45, widthFraction = 0.48, heightFraction = 0.25 },
}

local function lettering(group, name, color)
	local label = Instance.new("TextLabel")
	label.Name, label.BackgroundTransparency, label.BorderSizePixel = name, 1, 0
	label.FontFace, label.TextColor3 = condensed, color
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex, label.Parent = 9, group
	local outline = Instance.new("UIStroke")
	outline.Color, outline.Thickness, outline.Transparency = ink, 1.6, 0.08
	outline.Parent = label
	local shadow = label:Clone()
	shadow.Name, shadow.ZIndex, shadow.TextColor3 = name .. " shadow", 8, ink
	shadow.Parent = group
	return label, shadow
end

local function setLine(label, shadow, text, size, width, top)
	for _, item in { label, shadow } do
		local offset = if item == shadow then Vector2.new(2, 3) else Vector2.zero
		item.Text, item.TextSize = text, size
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.Size = UDim2.fromOffset(width, size * 1.18)
		item.Position = UDim2.fromOffset(offset.X, top + offset.Y)
	end
end

function Titles.new(safe)
	local viewer = game:GetService("Players").LocalPlayer
	local name = if viewer then viewer.DisplayName else "Miner"
	local group = Instance.new("Frame")
	group.Name, group.BackgroundTransparency, group.Visible = "Expedition title", 1, false
	group.ZIndex, group.Parent = 8, safe
	local typeArea = Instance.new("Frame")
	typeArea.Name, typeArea.BackgroundTransparency, typeArea.Parent = "Letterpress", 1, group
	local scale = Instance.new("UIScale")
	scale.Parent = typeArea
	local lead, leadShadow = lettering(typeArea, "Lead", cream)
	local main, mainShadow = lettering(typeArea, "Headline", ochre)
	local active
	return function(frame, motion, top, bottom)
		local cue
		for _, item in cues do
			if frame >= item.first and frame <= item.last then
				cue = item
				break
			end
		end
		group.Visible = cue ~= nil
		if not cue then
			active = nil
			return
		end
		local height = cue.leading + cue.mainSize * 1.18
		if active ~= cue then
			lead.TextColor3 = cream
			main.TextColor3 = ochre
			local leadSize = cue.leadSize
			if cue.player then
				-- Reserve the same baseline for long Roblox display names.
				local measured = game:GetService("TextService"):GetTextSize(name, leadSize, Enum.Font.SourceSansBold, Vector2.new(4000, 200)).X
				leadSize = math.min(leadSize, math.floor(leadSize * cue.width / math.max(1, measured * 1.22)))
			end
			setLine(lead, leadShadow, if cue.player then name else cue.lead, leadSize, cue.width,
				(cue.leadSize - leadSize) * 1.18)
			setLine(main, mainShadow, cue.headline, cue.mainSize, cue.width, cue.leading)
			typeArea.Size = UDim2.fromOffset(cue.width, height)
			active = cue
		end
		local size = safe.AbsoluteSize
		top, bottom = top or 0, bottom or size.Y
		local pictureHeight = math.max(1, bottom - top)
		local fraction = if size.X < pictureHeight then 0.81 else cue.widthFraction
		local fit = math.min(size.X * fraction / cue.width, pictureHeight * cue.heightFraction / height)
		local age = frame - cue.first
		local stamp = if motion then math.max(0, 1 - age / 4) ^ 2 else 0
		scale.Scale = math.max(0.01, fit * (1 + 0.035 * stamp))
		group.Size = UDim2.fromOffset(cue.width * scale.Scale, height * scale.Scale)
		group.AnchorPoint = Vector2.new(0, 1)
		group.Position = UDim2.new(0.065 - 0.008 * stamp, 0, 0, bottom - pictureHeight * 0.095)
		group.Rotation = -2 - stamp
		main.Visible, mainShadow.Visible = true, true
	end
end

return Titles
