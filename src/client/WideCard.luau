-- A large menu card with a bright header, optional tabs and a body. The rewards and the
-- ore index are built on it.
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local Burst = require(script.Parent.Burst)
local Card = {}
Card.__index = Card
local rgb = Color3.fromRGB
Card.width, Card.height = 800, 520
Card.slate = { rgb(72, 68, 124), rgb(46, 43, 86) }

function Card.new(menu, name, icon, title, tint, height)
	local self = setmetatable({ menu = menu, tabs = {}, order = {} }, Card)
	local width
	width, height = Card.width, height or Card.height
	self.size = Vector2.new(width, height)
	local modal = W.frame(menu.overlay, name, 0, 0, width, height, W.panel, 20)
	modal.Active, modal.Visible = true, false
	W.anchor(modal, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	W.enamelPanel(modal, rgb(58, 54, 104), rgb(34, 32, 66), 20)
	self.modal, self.scale = modal, W.scale(modal)
	local header = W.frame(modal, "Marquee", 0, 0, width, 76, W.white, 20)
	self.headerPaint = W.enamelPanel(header, tint[1], tint[2], 20)
	local gloss = W.frame(header, "Gloss", 560, 0, 40, 76, W.white)
	gloss.BackgroundTransparency = 1
	self.header = header
	self.badge = W.frame(header, "Icon", 16, 8, 60, 60, W.white)
	self.badge.BackgroundTransparency = 1
	self:setIcon(icon)
	self.heading = W.title(header, title, 86, 5, 470, 44, 38, W.white, true)
	W.navyText(self.heading, 3.4)
	self.sub = W.title(header, "", 88, 46, 470, 24, 18, W.white, true)
	W.navyText(self.sub, 2.2)
	local close = W.closeButton(header, width - 66, 10, 56)
	close.TextSize = 48
	close.Activated:Connect(menu.closeMap)
	self.close = close
	self.body = Card.scroller(modal, "Body", 18, 92, width - 36, height - 108)
	self.body.ScrollBarThickness = 0
	return self
end

function Card:setIcon(key)
	self.badge:ClearAllChildren()
	Icons.draw(self.badge, key, 0, 0, 60)
end

-- Adds a tab under the header. `keys` are the pages it opens.
function Card:tab(key, caption, icon, onPress)
	local index = #self.order + 1
	local b = W.clearButton(self.modal, key .. " tab", 0, 88, 180, 46, "Select")
	W.round(b, 14)
	local paint = W.enamelPanel(b, Card.slate[1], Card.slate[2], 14)
	Icons.draw(b, icon, 14, 8, 30)
	local label = W.title(b, caption, 50, 0, 122, 44, 22, W.white, true)
	W.navyText(label, 2.4)
	local dot = W.dot(b, -12, -3)
	b.Activated:Connect(onPress)
	self.order[index] = key
	self.tabs[key] = { button = b, paint = paint, dot = dot }
	for i, name in self.order do
		self.tabs[name].button.Position = UDim2.fromOffset(self.size.X / 2 - #self.order * 95 + (i - 1) * 190 + 5, 88)
	end
end
-- A row of tabs that share the card's width: `tabs` is a list of { key, caption, icon }. Returns the
-- paint of each tab by key, for Card.paintTabs.
function Card:tabRow(tabs, onPress)
	self:useTabs()
	local paints = {}
	local width = math.min(190, math.floor((self.size.X - 28) / #tabs) - 6)
	for i, tab in tabs do
		local key = tab[1]
		local b = W.clearButton(self.modal, key .. " tab", 14 + (i - 1) * (width + 6), 88, width, 46, "Select")
		W.round(b, 14)
		local paint = W.enamelPanel(b, Card.slate[1], Card.slate[2], 14)
		Icons.draw(b, tab[3], 8, 7, 32)
		local label = W.title(b, tab[2], 42, 0, width - 48, 44, 21, W.white, true)
		W.navyText(label, 2.4)
		W.largest(label, 21, 12)
		b.Activated:Connect(function() onPress(key) end)
		paints[key] = paint
		self.tabs[key] = { button = b, paint = paint, dot = W.dot(b, -12, -3) }
	end
	return paints
end
function Card.paintTabs(paints, selected)
	for key, paint in paints do
		paint.Color = if key == selected then ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
			else ColorSequence.new(Card.slate[1], Card.slate[2])
	end
end

function Card:useTabs()
	self.order = {}
	self.body.Position, self.body.Size = UDim2.fromOffset(11, 139), UDim2.fromOffset(self.size.X - 22, self.size.Y - 150)
	self.body.CanvasSize = UDim2.fromOffset(0, self.size.Y - 150)
end
function Card:select(key)
	for name, tab in self.tabs do
		tab.paint.Color = if name == key
			then ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
			else ColorSequence.new(Card.slate[1], Card.slate[2])
	end
end

-- `room` is set on phones held sideways (see Menu:layout). The card then stays inside the safe area,
-- clear of Roblox's top bar and chat, centred, and scaled so the whole of it fits: nothing scrolls out
-- of sight.
function Card:layout(area, touch, room)
	local short = area.X > area.Y and (touch or area.Y < 470)
	if short and room and self.scrolls then
		-- A card whose page scrolls (the Shop): as wide as the screen, for the largest text, and as
		-- tall as fits under Roblox's top bar; the page scrolls inside it.
		local scale = math.clamp((area.X - 8) / self.size.X, 0.3, 1.45)
		local height = math.min(self.size.Y, math.floor((area.Y - 6) / scale))
		self.scale.Scale = scale
		self.modal.Size = UDim2.fromOffset(self.size.X, height)
		local top = self.body.Position.Y.Offset
		self.body.Size = UDim2.fromOffset(self.size.X - 22, height - top - 11)
		self.center = UDim2.fromScale(0.5, 0.5)
		if self.modal.Visible then self.modal.Position = self.center end
		return
	end
	if short and room then
		local scale = math.clamp(math.min((area.X - 16) / self.size.X, (area.Y - 8) / self.size.Y), 0.3, 1.45)
		self.scale.Scale = scale
		self.modal.Size = UDim2.fromOffset(self.size.X, self.size.Y)
		local top = self.body.Position.Y.Offset
		self.body.Size = UDim2.fromOffset(self.size.X - 22, self.size.Y - top - 11)
		self.body.ScrollingEnabled, self.body.ScrollBarThickness = false, 0
		self.body.CanvasPosition = Vector2.zero
		self.center = UDim2.fromScale(0.5, 0.5)
		if self.modal.Visible then self.modal.Position = self.center end
		return
	end
	self.center = nil
	local margin = if short then 8 else 34
	-- On a phone held sideways the card keeps readable type and its body scrolls.
	local least = if short then 470 else self.size.Y
	local scale = math.clamp(math.min((area.X - margin) / self.size.X, (area.Y - margin) / least), 0.3, 1.45)
	local height = math.min(self.size.Y, math.floor((area.Y - margin) / scale))
	self.scale.Scale = scale
	self.modal.Size = UDim2.fromOffset(self.size.X, height)
	local top = self.body.Position.Y.Offset
	self.body.Size = UDim2.fromOffset(self.size.X - 22, height - top - 11)
	self.body.ScrollingEnabled = height < self.size.Y
	self.body.ScrollBarThickness = if height < self.size.Y then 8 else 0
end
function Card:enter(animate, arriving)
	local center = self.center or UDim2.fromScale(0.5, 0.5)
	self.modal.Visible = true
	if animate and arriving then
		Burst.drop(self.modal, center)
	elseif animate then
		self.modal.Position = center + UDim2.fromOffset(0, 60)
		W.tween(self.modal, 0.22, { Position = center })
	else
		self.modal.Position = center
	end
end

-- Pale rays behind an icon, turning slowly with the card's own light.
function Card.rays(parent, x, y, length, count)
	local edge = 7
	local clip = W.frame(parent, "Rays", edge, edge, 0, 0, W.white)
	clip.Size, clip.BackgroundTransparency, clip.ClipsDescendants = UDim2.new(1, -2 * edge, 1, -2 * edge), 1, true
	for i = 1, count or 6 do
		local ray = W.frame(clip, "Ray", 0, 0, length * 2, length * 0.17, W.white)
		W.anchor(ray, 0.5, 0.5, UDim2.fromOffset(x - edge, y - edge))
		ray.Rotation, ray.BackgroundTransparency = (i - 1) * 180 / (count or 6) + 15, 0.87
	end
	return clip
end

-- A list that scrolls, filling `x, y, w, h` of `parent`.
function Card.scroller(parent, name, x, y, w, h)
	local list = Instance.new("ScrollingFrame")
	list.Name, list.Position, list.Size = name, UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
	list.BackgroundTransparency, list.BorderSizePixel, list.ScrollBarThickness = 1, 0, 8
	list.ScrollBarImageColor3, list.ScrollingDirection = W.white, Enum.ScrollingDirection.Y
	list.ScrollBarImageTransparency, list.Parent = 0.35, parent
	return list
end

return Card
