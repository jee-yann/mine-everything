-- Each cut has its own two-line type lockup. Size the whole lockup in the
-- safe viewport so the measured letter sizes and leading stay together.
local Titles = {}
local cuts = require(script.Parent.ExposureSheet).frames
local cream, ochre, ink = Color3.fromHex("FFF6DD"), Color3.fromHex("FFD063"), Color3.fromHex("152121")
local condensed = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)
local cues = {
	{
		first = 906,
		last = 938,
		lead = "CITRINE COVE",
		headline = "PRESENT DAY",
		centered = true,
		accent = 4,
		x = 0.047,
		y = 0.12,
		w = 0.44,
		h = 0.31,
		phoneY = 0.12,
		angle = -4,
		leadSize = 42,
		mainSize = 118,
		width = 628,
		leading = 49,
	},
	{
		first = cuts.lode + 13,
		last = cuts.challenge - 2,
		lead = "THE RAREST ORE",
		headline = "STARFALL",
		x = 0.040,
		y = 0.62,
		w = 0.43,
		h = 0.29,
		phoneY = 0.70,
		angle = -3,
		leadSize = 60,
		mainSize = 92,
		width = 480,
		leading = 54,
	},
	{
		first = cuts.portrait + 7,
		last = cuts.commission - 2,
		player = true,
		headline = "GEM HUNTER",
		x = 0.05,
		y = 0.65,
		w = 0.43,
		h = 0.25,
		phoneY = 0.73,
		angle = -3.5,
		leadSize = 44,
		mainSize = 88,
		width = 535,
		leading = 49,
	},
	{
		first = cuts.challenge + 2,
		last = cuts.handoff + 22,
		lead = "WILL YOU FIND",
		headline = "STARFALL FIRST?",
		x = 0.043,
		y = 0.58,
		w = 0.52,
		h = 0.29,
		phoneY = 0.69,
		angle = -4,
		leadSize = 64,
		mainSize = 94,
		width = 690,
		leading = 57,
	},
}

local function lettering(group, name, color)
	local label = Instance.new("TextLabel")
	label.Name, label.BackgroundTransparency, label.BorderSizePixel = name, 1, 0
	label.FontFace, label.TextColor3 = condensed, color
	label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
	label.ZIndex, label.Parent = 9, group
	local outline = Instance.new("UIStroke")
	outline.Color, outline.Thickness, outline.Transparency = ink, 1.5, 0.12
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
		item.Size = UDim2.fromOffset(width + 12, size * 1.13)
		item.Position = UDim2.fromOffset(offset.X, top + offset.Y)
	end
end

function Titles.new(safe, screen)
	local viewer = game:GetService("Players").LocalPlayer
	local name = if viewer then viewer.DisplayName else "Miner"
	local dusk = Instance.new("Frame")
	dusk.Name, dusk.BackgroundColor3, dusk.BorderSizePixel = "Chapter exposure", Color3.fromHex("131D33"), 0
	dusk.Size, dusk.ZIndex, dusk.Visible, dusk.Parent = UDim2.fromScale(1, 1), 5, false, screen

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
	return function(frame, motion)
		local cue
		for _, item in cues do
			if frame >= item.first and frame <= item.last then
				cue = item
				break
			end
		end
		group.Visible = cue ~= nil
		dusk.Visible = cue ~= nil and cue.centered == true
		if dusk.Visible then
			local edge = math.clamp(math.min(frame - 904, 940 - frame) / 4, 0, 1)
			dusk.BackgroundTransparency = 1 - 0.60 * edge
		end
		if not cue then
			active = nil
			return
		end
		local height = cue.leading + cue.mainSize * 1.13
		if active ~= cue then
			for _, line in { lead, leadShadow, main, mainShadow } do
				line.TextXAlignment = if cue.centered then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
			end
			lead.TextColor3 = if cue.centered then ochre else cream
			main.TextColor3 = if cue.centered then cream else ochre
			local leadSize = cue.leadSize
			if cue.player then
				-- Keep a 20-character display name on one line in the printed card.
				local width = game:GetService("TextService"):GetTextSize(name, leadSize, Enum.Font.SourceSansBold, Vector2.new(4000, 200)).X
				leadSize = math.min(leadSize, math.floor(leadSize * cue.width / math.max(1, width * 1.2)))
			end
			setLine(lead, leadShadow, if cue.player then name else cue.lead, leadSize, cue.width, 0)
			setLine(main, mainShadow, cue.headline, cue.mainSize, cue.width, cue.leading)
			typeArea.Size = UDim2.fromOffset(cue.width, height)
			active = cue
		end
		local size = safe.AbsoluteSize
		local narrow = size.X < size.Y
		local fit = (if narrow then 1 else 1.24)
			* math.min(
				size.X * (if narrow then 0.85 else cue.w) / cue.width,
				size.Y * (if narrow then 0.18 else cue.h) / height
			)
		local age = frame - cue.first
		local stamp = if motion and age < 4 then (1 - age / 4) ^ 2 else 0
		local offset = if motion and age < 2 then 0.012 * (2 - age) else 0
		scale.Scale = fit * (1 + (if cue.centered then 0 else 0.08) * stamp)
		if cue.centered then
			group.AnchorPoint = Vector2.new(0.5, 0.5)
			group.Position = UDim2.fromScale(0.5, 0.47)
		else
			group.AnchorPoint = Vector2.zero
			group.Position = UDim2.fromScale(cue.x - offset, if narrow then cue.phoneY else cue.y)
		end
		group.Size = UDim2.fromOffset(cue.width * fit, height * fit)
		group.Rotation = if cue.centered then 0 else cue.angle - 2 * stamp
		main.Visible, mainShadow.Visible =
			not motion or age >= (cue.accent or 2), not motion or age >= (cue.accent or 2)
	end
end

return Titles
