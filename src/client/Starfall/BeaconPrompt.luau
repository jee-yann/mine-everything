-- The one thing the player does. A cut keycap of the same crystal, with a face,
-- a skirt and a seat for it to sink into. The face answers the press on the same
-- rendered frame. Only its afterimages are late.
--
-- Everything is a function of the frame, which may be fractional, so the prompt
-- moves at the display's rate while the film keeps to twenty-four.
local Input = game:GetService("UserInputService")
local frames = require(script.Parent.ExposureSheet).frames
local hex, white = Color3.fromHex, Color3.new(1, 1, 1)
local family = "rbxasset://fonts/families/Montserrat.json"
local soft = "rbxasset://textures/particles/smoke_main.dds"
local trail, shards = 4, 8
-- How long the press and the unanswered prompt take to leave, in frames. The
-- steel lands ten frames after the press.
local resolve, leave = 11, 6

local function smooth(u)
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

-- Share of full travel. Down at once, held through the windup, then let go.
local function travel(age)
	if age < 0 then
		return 0
	end
	return (1 - math.exp(-(age + 0.55) / 0.62)) * (1 - 0.75 * smooth((age - 4.5) / 3.5))
end

-- The cap comes up from below its seat, passes it and settles.
local function arrival(waiting)
	local u = math.clamp((waiting + 1) / 11, 0, 1)
	local over = 1 + 1.9 * (u - 1) ^ 3 + 0.9 * (u - 1) ^ 2
	return over, smooth((waiting + 1) / 6)
end

local function create(class, parent, props)
	local item = Instance.new(class)
	for key, value in props do
		item[key] = value
	end
	item.Parent = parent
	return item
end

return function(safe)
	local button = create("TextButton", safe, {
		Name = "Strike sample", Text = "", Visible = false, Selectable = false, AutoButtonColor = false,
		BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 11,
	})
	local root = create("Frame", safe, {
		Name = "Strike prompt", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 6,
	})
	-- Every fading surface, with how solid it is when the prompt is fully there.
	local surfaces = {}
	local function fades(item, key, rest)
		table.insert(surfaces, { item = item, key = key, rest = rest or 0 })
		return item
	end
	local function panel(name, z, color, rest, corner)
		local f = create("Frame", root, { Name = name, BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z })
		fades(f, "BackgroundTransparency", rest)
		local round = create("UICorner", f, { CornerRadius = UDim.new(corner or 0.18, 0) })
		return f, round
	end
	local function ramp(item, colors, rotation)
		local keys = {}
		for i, c in colors do
			table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), hex(c)))
		end
		return create("UIGradient", item, { Color = ColorSequence.new(keys), Rotation = rotation or 90 })
	end
	local function edge(item, color, thickness, rest)
		return fades(create("UIStroke", item, { Color = hex(color), Thickness = thickness }), "Transparency", rest)
	end

	local glow = create("ImageLabel", root, {
		Name = "Strike glow", Image = soft, BackgroundTransparency = 1, ImageColor3 = hex("9B5CFF"), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 6,
	})
	local echoes = {}
	for i = 1, trail do
		local f = create("Frame", safe, {
			Name = "Strike outline " .. i, BorderSizePixel = 0, BackgroundColor3 = white, AnchorPoint = Vector2.new(0.5, 0.5),
			Visible = false, Active = false, Selectable = false, ZIndex = 7 - math.min(i, 2),
		})
		create("UICorner", f, { CornerRadius = UDim.new(0.18, 0) })
		local fill = ramp(f, { "DCC4FF", "8A4BEE" })
		echoes[i] = { frame = f, fill = fill, edge = create("UIStroke", f, { Color = hex("E8D7FF"), Thickness = 1.5 }) }
	end
	local ring = create("Frame", safe, {
		Name = "Strike ring", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Active = false, ZIndex = 7,
	})
	create("UICorner", ring, { CornerRadius = UDim.new(0.24, 0) })
	local ringEdge = create("UIStroke", ring, { Color = hex("F3E8FF"), Thickness = 3 })

	local seat = panel("Strike socket", 7, hex("160B2E"), 0.12, 0.26)
	ramp(seat, { "FFFFFF", "8E7BC0" })
	edge(seat, "6B3FD1", 1.5, 0.15)
	local skirt = panel("Strike skirt", 8, white, 0)
	ramp(skirt, { "8A4BEE", "4B22A8", "241054" })
	local face = panel("Strike face", 9, white, 0)
	ramp(face, { "F6EEFF", "CDACFF", "8D4FEA" })
	edge(face, "FFFFFF", 1.5, 0.25)
	local dish = panel("Strike dish", 10, white, 0.06)
	ramp(dish, { "A873F7", "BC92FF", "DCC6FF" })
	-- Two cut facets, caught by the light that crosses the cap now and then.
	local facet = panel("Strike facet", 11, white, 0)
	local facetFade = create("UIGradient", facet, { Rotation = 24 })
	facetFade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.62), NumberSequenceKeypoint.new(0.22, 0.80), NumberSequenceKeypoint.new(0.23, 1),
		NumberSequenceKeypoint.new(0.83, 1), NumberSequenceKeypoint.new(0.84, 0.86), NumberSequenceKeypoint.new(1, 0.78),
	})
	local gleam = panel("Strike gleam", 12, white, 0)
	local sweep = create("UIGradient", gleam, { Rotation = 24 })
	sweep.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.44, 1), NumberSequenceKeypoint.new(0.5, 0.25),
		NumberSequenceKeypoint.new(0.56, 1), NumberSequenceKeypoint.new(1, 1),
	})
	local flash = create("Frame", root, { Name = "Strike flash", BackgroundColor3 = white, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 13 })
	create("UICorner", flash, { CornerRadius = UDim.new(0.18, 0) })
	local key = fades(create("TextLabel", root, {
		Name = "Input key", BackgroundTransparency = 1, TextScaled = true, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 14,
		FontFace = Font.new(family, Enum.FontWeight.Heavy), TextColor3 = hex("2A1060"),
	}), "TextTransparency")
	local bracket = {}
	for i = 1, 3 do
		bracket[i] = fades(create("Frame", root, { Name = "Space mark", BorderSizePixel = 0, BackgroundColor3 = hex("2A1060"), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 14 }), "BackgroundTransparency", 0.1)
	end
	local action = fades(create("TextLabel", root, {
		Name = "Action", Text = "Break it open", BackgroundTransparency = 1, TextScaled = true, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 12,
		FontFace = Font.new(family, Enum.FontWeight.Heavy, Enum.FontStyle.Italic), TextColor3 = white,
	}), "TextTransparency")
	ramp(action, { "FFFFFF", "DFC8FF" })
	local ink = fades(create("UIStroke", action, { Color = hex("1C0D3D"), Thickness = 2.5 }), "Transparency", 0.1)
	local marks = {}
	for i = 1, 2 do
		local m = panel("Strike mark", 12, hex("CDA9FF"), 0, 0)
		m.Rotation = 45
		marks[i] = m
	end
	local splinters = {}
	for i = 1, shards do
		splinters[i] = create("Frame", safe, {
			Name = "Strike splinter", BorderSizePixel = 0, BackgroundColor3 = hex(if i % 2 == 0 then "FFFFFF" else "B98BFF"),
			AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Active = false, ZIndex = 10,
		})
	end

	local lastDevice, shape = nil, 3.5
	return button, function(frame, motion, press, top, bottom)
		local age = if press then frame - press else -1
		local pressed = press ~= nil and age >= 0
		local offered = not press and frame >= frames.prompt and frame < frames.autoStrike
		local leaving = not press and frame >= frames.autoStrike and frame < frames.autoStrike + leave
		local visible = offered or leaving or (pressed and age < resolve)
		button.Visible, button.Interactable = offered, offered
		root.Visible = visible
		if not visible then
			ring.Visible = false
			for _, e in echoes do e.frame.Visible = false end
			for _, s in splinters do s.Visible = false end
			return
		end
		local device = Input.PreferredInput
		if device ~= lastDevice then
			lastDevice = device
			local pad = if device == Enum.PreferredInput.Gamepad then Input:GetStringForKeyCode(Enum.KeyCode.ButtonX) else ""
			key.Text = if device == Enum.PreferredInput.Touch then "TAP"
				elseif device == Enum.PreferredInput.Gamepad then (if pad == "" then "X" else (pad:gsub("^Button", "")))
				else "SPACE"
			shape = if device == Enum.PreferredInput.Touch then 2.4 elseif device == Enum.PreferredInput.Gamepad then 1.2 else 3.5
		end

		-- Beside the rock, clear of the player and the vein. A narrow picture has
		-- no room there, so it goes to the foot of the frame.
		local picture, wide = math.max(1, bottom - top), safe.AbsoluteSize.X
		local h = math.clamp(picture * 0.115, 46, 92)
		local aside = wide / picture > 1.85
		h = math.min(h, (if aside then wide * 0.26 else wide * 0.62) / 4.1)
		local w = h * shape
		local x = if aside then wide * 0.835 else wide * 0.5
		local seatY = if aside then top + picture * 0.70 else bottom - h * 1.15
		local depth = h * 0.24
		local corner = h * 0.18

		-- Where the face is at any moment, so a late copy can be put there.
		local function poseAt(at)
			local waiting = at - frames.prompt
			local rise, there = 1, 1
			if motion then
				rise, there = arrival(waiting)
			end
			local down = if press and at >= press then travel(at - press) else 0
			if not motion and down > 0 then
				down = 1
			end
			local idle = if motion and not press then math.sin(waiting / 7.5) * 0.02 * h else 0
			local squash = 1 - 0.035 * down
			return seatY + (1 - rise) * h * 0.9 + idle * rise + depth * down, w * squash * (0.9 + 0.1 * rise), h * squash * (0.9 + 0.1 * rise), down, there
		end
		local y, fw, fh, down, there = poseAt(frame)
		local settled = select(1, poseAt(if press then press - 0.01 else frame))
		local out = if pressed then smooth((age - 4) / (resolve - 4.5)) elseif leaving then smooth((frame - frames.autoStrike) / leave) else 0
		local alpha = there * (1 - out)
		for _, s in surfaces do
			s.item[s.key] = 1 - (1 - s.rest) * alpha
		end

		root.Position, root.Size = UDim2.fromOffset(x, 0), UDim2.fromOffset(0, 0)
		local function put(item, dx, at, iw, ih)
			item.Position, item.Size = UDim2.fromOffset(dx, at), UDim2.fromOffset(iw, ih)
		end
		local pulse = if motion then 0.5 + 0.5 * math.sin((frame - frames.prompt) / 8) else 0.5
		local foot = settled + depth + h * 0.06
		-- Inside the picture. It must not spill over the mattes.
		put(glow, 0, settled, w * 2.1 + h, math.min(h * 4.2, 2 * math.max(h, bottom - settled)))
		glow.ImageTransparency = 1 - alpha * (0.42 + 0.16 * pulse + (if pressed then 0.4 * math.exp(-age / 2.5) else 0))
		put(seat, 0, foot + h * 0.16, w * 1.07, h * 0.86)
		-- The skirt is what is left between the face and the seat.
		local gap = math.max(0, settled + depth - y)
		put(skirt, 0, y + gap / 2, fw, fh + gap)
		put(face, 0, y, fw, fh)
		put(dish, 0, y - h * 0.01, fw - h * 0.22, fh * 0.76)
		put(facet, 0, y, fw, fh)
		put(gleam, 0, y, fw, fh)
		put(flash, 0, y, fw, fh)
		flash.BackgroundTransparency = if pressed then 1 - 0.85 * math.exp(-age / 1.6) * (1 - out) else 1
		local cycle = (frame - frames.prompt - 14) % 44
		sweep.Offset = Vector2.new(if motion and offered and frame > frames.prompt + 14 then math.clamp(cycle / 16, 0, 1) * 2.4 - 1.2 else -1.2, 0)
		local letters = key.Text == "SPACE"
		put(key, 0, y - (if letters then h * 0.09 else 0), fw * 0.7, fh * (if letters then 0.42 else 0.5))
		-- The mark on the key itself.
		local mw, mh, mt = fw * 0.24, h * 0.11, math.max(2, h * 0.035)
		for i, b in bracket do
			b.Visible = letters
			if i == 1 then put(b, 0, y + h * 0.27, mw, mt) else put(b, (i * 2 - 5) * (mw - mt) / 2, y + h * 0.27 - mh / 2 + mt / 2, mt, mh) end
		end
		-- The words lead the cap in and are the first thing to go.
		local words = if pressed then 1 - smooth(age / 4) else 1
		action.TextTransparency, ink.Transparency = 1 - alpha * words, 1 - 0.9 * alpha * words
		local line = math.min(h * 4.3, wide * 0.9)
		local lift = settled - h * 1.02 - (if pressed and motion then smooth(age / 5) * h * 0.16 else 0)
		put(action, 0, lift, line, h * 0.56)
		for i, m in marks do
			local s = h * 0.13
			put(m, (i * 2 - 3) * (line * 0.5 + h * 0.12), lift, s, s)
			m.BackgroundTransparency = 1 - alpha * words
		end
		button.Position, button.Size = UDim2.fromOffset(x, settled - h * 0.2), UDim2.fromOffset(math.max(line, w * 1.2), math.max(h * 2.3, 88))

		-- Afterimages. Each is the face as it was a little earlier, then it lets go
		-- of it: up, out and away.
		for i, e in echoes do
			local entering = motion and not press and frame - frames.prompt < 16
			local show = motion and ((pressed and age < resolve) or entering)
			if show then
				local ey, ew, eh = poseAt(frame - i * (if pressed then 0.85 else 1.3))
				local drift = if pressed then 1 - math.exp(-age / 3.2) else 0
				local grow = 1 + drift * 0.085 * i
				e.frame.Position = UDim2.fromOffset(x, ey - drift * h * 0.15 * i)
				e.frame.Size = UDim2.fromOffset(ew * grow, eh * grow)
				local rest = if pressed then 0.26 + 0.14 * i else 0.56 + 0.10 * i
				local fade = if pressed then smooth((age - 0.8 * i) / 6.5) else smooth((frame - frames.prompt - 5) / 8)
				e.frame.BackgroundTransparency = 1 - (1 - rest) * (1 - fade) * there * 0.9
				e.edge.Transparency = 1 - (1 - rest * 0.7) * (1 - fade) * there
			end
			e.frame.Visible = show and e.edge.Transparency < 0.99
		end
		ring.Visible = motion and pressed and age < 9
		if ring.Visible then
			local open = 1 - math.exp(-age / 3)
			ring.Position = UDim2.fromOffset(x, settled)
			ring.Size = UDim2.fromOffset(w + h * 1.5 * open, h + h * 1.1 * open)
			ringEdge.Transparency, ringEdge.Thickness = math.clamp(0.1 + age / 9, 0, 1), math.max(0.5, h * 0.06 * (1 - open))
		end
		for i, s in splinters do
			s.Visible = motion and pressed and age < 9
			if s.Visible then
				local a = (i - 0.5) / shards * math.pi * 2 + 0.3
				local go = 1 - math.exp(-age / 2.6)
				local size = h * (0.10 + 0.05 * (i % 3)) * (1 - age / 9)
				s.Position = UDim2.fromOffset(x + math.cos(a) * (w * 0.5 + h * 0.7 * go), settled + math.sin(a) * (h * 0.4 + h * 0.75 * go))
				s.Size, s.Rotation = UDim2.fromOffset(size * 0.38, size * 1.7), math.deg(a) + 90
				s.BackgroundTransparency = math.clamp(age / 9, 0, 1)
			end
		end
		-- Round corners follow the cap's height, not its width.
		for _, item in { face, skirt, gleam, facet, flash } do
			item.UICorner.CornerRadius = UDim.new(0, corner)
		end
		dish.UICorner.CornerRadius, seat.UICorner.CornerRadius = UDim.new(0, corner * 0.75), UDim.new(0, corner * 1.3)
		for _, e in echoes do
			e.frame.UICorner.CornerRadius = UDim.new(0, corner)
		end
		ring.UICorner.CornerRadius = UDim.new(0, corner * 1.5)
	end
end
