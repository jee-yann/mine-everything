-- Each badge is drawn on a 32-unit canvas so its silhouette survives touch HUD scaling.
local W = require(script.Parent.Widgets)
local FieldKit = require(script.Parent.FieldKit)
local Icons = {}
local rgb = Color3.fromRGB

-- Sticker icons in the style of the side buttons: one navy line around the outside and none inside.
-- Each group is a set of rounded pieces given by their centre, size, corner, colour and turn. A group's
-- outlines all go down before its colours, so only its silhouette is edged.
local skin, gold, blue = rgb(255, 214, 166), rgb(255, 204, 74), rgb(74, 150, 246)
local function pick()
	local d, side = Vector2.new(math.sin(math.rad(40)), -math.cos(math.rad(40))), Vector2.new(math.cos(math.rad(40)), math.sin(math.rad(40)))
	local mid = Vector2.new(14.5, 18.5)
	local top, grip = mid + d * 10.5, mid - d * 7
	local left, right = top - side * 6.4, top + side * 6.4
	return { {
		{ mid.X, mid.Y, 5.4, 25, 2.7, rgb(205, 128, 64), 40, true },
		{ grip.X, grip.Y, 6.2, 5.4, 2, rgb(150, 96, 238), 40 },
		{ left.X, left.Y, 14, 6.2, 3.1, rgb(176, 228, 242), 26, true },
		{ right.X, right.Y, 14, 6.2, 3.1, rgb(176, 228, 242), 54, true },
		{ top.X, top.Y, 7.4, 7.4, 2.2, gold, 40, true },
	} }
end
local function chevron(tip, color)
	return {
		{ tip - 3.9, 12.1, 12.5, 5.8, 2.9, color, 45, true },
		{ tip - 3.9, 19.9, 12.5, 5.8, 2.9, color, -45 },
	}
end
local function miner(x, y, scale, coat, helmet)
	local function s(v) return v * scale end
	local parts = {
		{ x, y + s(12.5), s(24), s(13), s(6.5), coat, 0, true },
		{ x, y + s(12), s(4), s(12), s(1.5), gold, 0 },
		{ x, y, s(13), s(13), s(6.5), skin, 0, true },
	}
	if helmet then
		table.insert(parts, { x, y - s(4.5), s(16), s(8), s(4), gold, 0, true })
		table.insert(parts, { x, y - s(1.6), s(18.5), s(3.2), s(1.6), rgb(240, 156, 40), 0 })
		table.insert(parts, { x, y - s(4.8), s(5), s(5), s(2.5), rgb(255, 250, 214), 0 })
	end
	return parts
end
local stickers = {
	Power = pick,
	Gear = pick,
	Speed = function()
		return { chevron(16, rgb(255, 226, 120)), chevron(27, gold) }
	end,
	Profile = function()
		return { miner(16, 11.5, 1, blue, true) }
	end,
	Friends = function()
		return { miner(21.5, 12.5, 0.72, rgb(255, 128, 176), false), miner(12, 15, 0.8, blue, true) }
	end,
}
stickers.Crew = stickers.Friends
local edge = 2.5
-- Drawn at twice the size, because offsets are whole pixels and thin pieces would lose their edge.
local function sticker(canvas, groups)
	local k = 2
	canvas.Size = UDim2.fromOffset(64, 64)
	local fit = canvas:FindFirstChildOfClass("UIScale")
	fit.Scale /= 2
	for g, group in groups do
		for pass = 1, 2 do
			for _, part in group do
				local cx, cy, w, h, r, color, angle, shine = table.unpack(part)
				local grow = if pass == 1 then edge else 0
				local f = W.frame(canvas, if pass == 1 then "Edge" else "Piece", k * (cx - w / 2 - grow), k * (cy - h / 2 - grow), k * (w + 2 * grow), k * (h + 2 * grow),
					if pass == 1 then W.navy else W.white, k * (r + grow))
				f.Rotation, f.ZIndex = angle, g * 2 + pass
				if pass == 2 then
					W.gradient(f, color:Lerp(W.white, 0.32), color:Lerp(W.navy, 0.1), 90)
					if shine and w > 5 and h > 5 then
						local gleam = W.frame(f, "Shine", k * w * 0.2, k * h * 0.16, k * w * 0.45, k * math.max(1.2, h * 0.2), W.white, k)
						gleam.BackgroundTransparency, gleam.ZIndex = 0.4, f.ZIndex
					end
				end
			end
		end
	end
end
Icons.stickers = stickers

function Icons.draw(parent, key, x, y, size, tint)
	local canvas = W.frame(parent, key .. " icon", x, y, 32, 32, W.ink)
	canvas.BackgroundTransparency = 1
	W.scale(canvas).Scale = size / 32
	if FieldKit.draw(canvas, key) then
		return canvas
	end
	if stickers[key] then
		sticker(canvas, stickers[key]())
		return canvas
	end
	local function shape(name, sx, sy, w, h, color, r, angle, outline)
		if outline and w >= 7 and h >= 6 then
			local side = W.frame(canvas, "Extruded edge", sx + 0.6, sy + 1.6, w, h, color:Lerp(W.ink, 0.52), r)
			side.Rotation = angle or 0
			W.stroke(side, W.ink, 1.35)
		end
		local f = W.frame(canvas, name, sx, sy, w, h, color, r)
		f.Rotation = angle or 0
		if outline then
			W.stroke(f, W.ink, 1.15)
			local finish = Instance.new("UIGradient")
			finish.Rotation = 68
			finish.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.52, Color3.fromRGB(255, 249, 229)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 153, 192)),
			})
			finish.Parent = f
			if w >= 8 and h >= 6 then
				local gleam =
					W.frame(f, "Polished edge", math.ceil(w * 0.16), 1, math.max(3, w * 0.44), 1.3, W.white, 1)
				gleam.BackgroundTransparency = 0.21
			end
		end
		return f
	end
	local light = W.white
	if key == "Coins" or key == "Sell" then
		for i = 1, 3 do
			local cx, cy = if i == 3 then 14 else 2, if i == 3 then 12 else 20 - i * 4
			shape("Gold rim", cx, cy, 16, 14, W.orange, 7, -12, true)
			shape("Gold face", cx + 2, cy, 12, 11, W.gold, 6, -12)
			shape("Mint mark", cx + 7, cy + 2, 2, 6, light, 1, 12)
		end
	elseif key == "Gear" or key == "Power" then
		shape("Handle", 13, 5, 5, 24, W.orange, 2, 38, true)
		shape("Pick head", 8, 5, 16, 6, light, 2, 20, true)
		shape("Pick tip", 21, 8, 7, 5, W.aqua, 1, 39, true)
		shape("Rear pick", 4, 6, 7, 4, W.aqua, 1, -23, true)
		shape("Leather wrap", 11, 19, 6, 2, W.grape, 1, 38)
		shape("Leather wrap", 8, 23, 6, 2, W.grape, 1, 38)
	elseif key == "Hook" then
		shape("Cable", 7, 13, 4, 16, W.gold, 2, 29, true)
		shape("Hook shank", 12, 5, 5, 17, W.aqua, 2, 29, true)
		shape("Curve", 16, 4, 11, 5, light, 2, 16, true)
		shape("Barb", 24, 7, 4, 8, W.aqua, 1, -15, true)
	elseif key == "Tempo" then
		shape("Stopwatch", 5, 7, 21, 22, W.gold, 10, 0, true)
		shape("Dial", 8, 10, 15, 15, W.panel, 8)
		shape("Stem", 12, 3, 8, 5, W.aqua, 2, 0, true)
		shape("Minute hand", 15, 11, 2, 8, light, 1, 20)
		shape("Second hand", 16, 17, 6, 2, W.gold, 1, -12)
	elseif key == "Boot" or key == "Spring" then
		shape("Boot upper", 11, 5, 11, 16, W.orange, 2, -7, true)
		shape("Boot toe", 6, 17, 18, 8, W.gold, 3, -5, true)
		shape("Tread", 5, 24, 22, 4, W.panel, 2, -5, true)
		if key == "Spring" then
			for i = 0, 2 do
				shape("Wing feather", 18 + i, 8 + i * 3, 10 - i * 2, 3, light, 1, -26, true)
			end
		else
			shape("Lace", 12, 11, 8, 2, light, 1, 8)
			shape("Lace", 12, 15, 8, 2, light, 1, 8)
		end
	elseif key == "Lamp" or key == "Beacon" then
		if key == "Beacon" then
			for _, xx in { 2, 27 } do
				shape("Beam", xx, 9, 3, 12, W.gold, 1, if xx == 2 then -18 else 18)
			end
		end
		shape("Bail", 10, 2, 12, 11, W.panel, 5, 0, true)
		shape("Glass", 7, 10, 18, 16, W.gold, 4, 0, true)
		shape("Flame", 13, 14, 6, 9, light, 3, 12)
		shape("Cap", 5, 7, 22, 5, W.aqua, 2, 0, true)
		shape("Foot", 6, 25, 20, 4, W.aqua, 2, 0, true)
	elseif key == "Menu" then
		for i, color in { W.gold, W.aqua, W.green, W.pink } do
			shape("Tile", 3 + ((i - 1) % 2) * 14, 3 + math.floor((i - 1) / 2) * 14, 12, 12, color, 3, 0, true)
		end
	elseif key == "Jobs" then
		shape("Clipboard", 6, 5, 20, 24, W.gold, 3, -6, true)
		shape("Paper", 9, 9, 14, 16, light, 1, -6)
		shape("Clip", 11, 3, 9, 6, W.orange, 2, -6, true)
		for i = 0, 2 do
			shape("Entry", 11, 12 + i * 4, 9 - i, 2, W.panel, 1, -6)
		end
	elseif key == "Passes" then
		shape("Pass", 3, 7, 26, 18, W.violet, 4, -9, true)
		shape("Prism stamp", 12, 10, 9, 10, W.gold, 2, 35, true)
	elseif key == "Store" then
		shape("Shop", 5, 10, 22, 17, light, 2, 0, true)
		shape("Window", 8, 15, 7, 8, W.aqua, 1, 0, true)
		shape("Door", 18, 16, 5, 10, W.panel, 1)
		shape("Canopy", 2, 6, 28, 8, W.pink, 2, 0, true)
		for _, xx in { 7, 17 } do
			shape("Awning stripe", xx, 6, 5, 8, light, 1)
		end
	elseif key == "Pets" then
		shape("Rock", 3, 10, 26, 17, W.muted, 6, -5, true)
		shape("Crown", 7, 6, 18, 7, light, 3, -4, true)
		for _, xx in { 9, 21 } do
			shape("Eye", xx, 14, 3, 4, W.ink, 1)
		end
		shape("Smile", 14, 20, 4, 2, W.ink, 1)
	elseif key == "Crew" then
		shape("Head", 10, 4, 12, 12, W.gold, 6, 0, true)
		shape("Coat", 5, 18, 22, 11, W.aqua, 5, 0, true)
	elseif key == "Profile" then
		shape("Head", 9, 3, 14, 14, rgb(255, 214, 160), 7, 0, true)
		shape("Helmet", 8, 2, 16, 7, W.gold, 4, 0, true)
		shape("Helmet lamp", 13, 3, 6, 5, light, 2)
		shape("Shoulders", 4, 18, 24, 12, rgb(64, 140, 240), 6, 0, true)
		shape("Strap", 14, 19, 4, 10, W.gold, 1)
	elseif key == "Friends" then
		shape("Back head", 18, 4, 10, 10, rgb(255, 224, 180), 5, 0, true)
		shape("Back coat", 16, 15, 14, 11, W.pink, 5, 0, true)
		shape("Head", 5, 6, 12, 12, rgb(255, 206, 150), 6, 0, true)
		shape("Coat", 2, 19, 18, 11, rgb(64, 140, 240), 5, 0, true)
	elseif key == "Speed" then
		for _, xx in { 8, 19 } do
			shape("Upper chevron", xx, 5, 6, 14, W.gold, 2, -40, true)
			shape("Lower chevron", xx, 14, 6, 14, W.gold, 2, 40, true)
		end
	else
		local col = tint or W.violet
		shape("Back shard", 4, 11, 11, 15, col:Lerp(W.ink, 0.22), 3, -27, true)
		shape("Crystal", 12, 4, 14, 22, col, 4, 22, true)
		shape("Facet", 16, 6, 4, 14, col:Lerp(light, 0.65), 2, 22)
	end
	return canvas
end
return Icons
