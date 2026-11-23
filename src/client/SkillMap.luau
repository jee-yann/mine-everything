local Input = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage").Shared
local Skills, Expeditions = require(Shared.Skills), require(Shared.Expeditions)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local Map = {}
Map.__index = Map

local colors = {
	Pickwork = W.orange,
	Lamplight = W.gold,
	["Survey optics"] = W.aqua,
	Footwork = W.green,
	Hauling = W.pink,
	Geology = W.violet,
}
local states = {
	owned = { label = "Owned", symbol = "✓", tint = W.green },
	available = { label = "Available", symbol = "+", tint = W.gold },
	unfunded = { label = "Need 1 point", symbol = "1", tint = W.muted },
	locked = { label = "Locked", tint = Color3.fromRGB(148, 159, 181) },
}
local function clear(parent, name, x, y, w, h)
	local f = W.frame(parent, name, x, y, w, h, W.ink)
	f.BackgroundTransparency = 1
	return f
end
local function diamond(parent, name, x, y, size, color)
	local f = W.frame(parent, name, x, y, size, size, color, 5)
	W.anchor(f, 0.5, 0.5, UDim2.fromOffset(x, y))
	f.Rotation = 45
	return f
end

local function stateBadge(parent, x, y)
	local badge = W.frame(parent, "Skill state", x, y, 22, 22, W.muted, 11)
	W.stroke(badge, W.ink, 2)
	local glyph = W.title(badge, "", 0, -1, 22, 23, 17, W.ink)
	glyph.Name = "Symbol"
	local lock = clear(badge, "Padlock", 4, 3, 14, 16)
	local shackle = W.frame(lock, "Shackle", 4, 1, 7, 9, W.ink, 3)
	shackle.BackgroundTransparency = 1
	W.stroke(shackle, W.ink, 1.8)
	W.frame(lock, "Body", 1, 7, 13, 9, W.ink, 2)
	W.frame(lock, "Keyhole", 7, 9, 2, 4, W.muted, 1)
	return function(state)
		badge.BackgroundColor3 = state.tint
		glyph.Text, lock.Visible = state.symbol or "", state == states.locked
	end
end

function Map.new(parent, player, net, close)
	local self = setmetatable({ player = player, net = net, nodes = {}, pan = Vector2.zero, zoom = 1 }, Map)
	local screen = W.frame(parent, "Skill map", 0, 0, 1, 1, Color3.fromRGB(19, 27, 43))
	screen.Size, screen.Visible, screen.Active = UDim2.fromScale(1, 1), false, true
	W.gradient(screen, Color3.fromRGB(255, 255, 255), Color3.fromRGB(122, 146, 178), 55)
	self.screen = screen
	local view = clear(screen, "Map viewport", 0, 65, 1, 1)
	view.Size, view.ClipsDescendants, view.Active = UDim2.new(1, 0, 1, -65), true, true
	self.view = view
	local canvas = clear(view, "Branches", 0, 0, 1, 1)
	self.canvas, self.scale = canvas, W.scale(canvas)
	self.extent = Vector2.zero
	for _, node in Skills.nodes do
		self.extent = Vector2.new(math.max(self.extent.X, math.abs(node.x)), math.max(self.extent.Y, math.abs(node.y)))
	end
	-- Survey grid moves with the branches so dragging keeps a visible frame of reference.
	local grid = clear(canvas, "Survey grid", 0, 0, 1, 1)
	local spanX, spanY = self.extent.X + 1100, self.extent.Y + 800
	for x = -math.floor(spanX / 80), math.floor(spanX / 80) do
		W.frame(grid, "Easting", x * 80, -spanY, 1, spanY * 2, W.line).BackgroundTransparency = 0.83
	end
	for y = -math.floor(spanY / 80), math.floor(spanY / 80) do
		W.frame(grid, "Northing", -spanX, y * 80, spanX * 2, 1, W.line).BackgroundTransparency = 0.83
	end
	for _, node in Skills.nodes do
		local lines = {}
		for _, parentId in if #node.requires == 0 then { "Origin" } else node.requires do
			local upstream = Skills.byId[parentId]
			local a = if upstream then Vector2.new(upstream.x, upstream.y) else Vector2.zero
			local b = Vector2.new(node.x, node.y)
			local delta, mid = b - a, (a + b) / 2
			local line = W.frame(canvas, parentId .. " to " .. node.id, 0, 0, delta.Magnitude, 4, W.line, 2)
			W.anchor(line, 0.5, 0.5, UDim2.fromOffset(mid.X, mid.Y))
			line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			lines[parentId] = line
		end
		self.nodes[node.id] = { node = node, lines = lines }
	end
	local origin = diamond(canvas, "Prospector", 0, 0, 69, W.gold)
	W.stroke(origin, W.ink, 4)
	local center = diamond(canvas, "Keystone", 0, 0, 59, W.ocean)
	W.enamel(center, W.ocean, W.ink)
	Icons.draw(canvas, "Power", -22, -22, 44)
	W.outlineText(W.title(canvas, "Prospector", -70, 52, 140, 23, 17, W.gold), 2)
	for _, node in Skills.nodes do
		local item = self.nodes[node.id]
		local b = W.clearButton(canvas, node.id, node.x - 42, node.y - 42, 84, 84, "Select")
		item.button = b
		local base = diamond(b, "Gem setting", 42, 44, 54, W.ink)
		W.stroke(base, W.ink, 3)
		item.rim = W.stroke(diamond(b, "Bezel", 42, 41, 54, W.panel), W.line, 2)
		item.face = diamond(b, "Enamel", 42, 41, 44, W.card)
		W.gradient(item.face, W.white, Color3.fromRGB(158, 153, 192), 66)
		Icons.draw(b, node.icon, 25, 23, 34, colors[node.branch])
		item.shade = diamond(b, "Unlearned enamel", 42, 41, 46, W.ink)
		local selection = diamond(b, "Selection", 42, 41, 63, W.white)
		selection.BackgroundTransparency, selection.Visible = 1, false
		W.stroke(selection, W.white, 2)
		item.selection = selection
		item.title = W.title(b, node.name, -25, 79, 134, 23, 16, W.white)
		W.outlineText(item.title, 1.8)
		if #node.requires == 0 then
			W.outlineText(W.text(b, node.branch, -25, 100, 134, 17, 13, colors[node.branch]), 1.5)
		end
		item.setBadge = stateBadge(b, 57, 48)
		b.Activated:Connect(function()
			if os.clock() >= (self.suppressClickUntil or 0) then
				self:select(node.id)
			end
		end)
		b.SelectionGained:Connect(function()
			if Input.PreferredInput == Enum.PreferredInput.Gamepad then
				self.pan = -Vector2.new(node.x, node.y) * self.scale.Scale
				self:position()
				self:select(node.id)
			end
		end)
	end
	self.pulses = clear(canvas, "Unlock lights", 0, 0, 1, 1)
	self.pulses.ZIndex = 3
	local header = W.frame(screen, "Map header", 0, 0, 1, 65, W.panel)
	self.header = header
	header.Size = UDim2.new(1, 0, 0, 65)
	W.enamel(header, W.panel, W.ink)
	local seam = W.frame(header, "Seam", 0, 0, 1, 2, W.aqua)
	seam.Size, seam.Position = UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -2)
	local balance = W.frame(header, "Skill point balance", 8, 6, 155, 46, W.gold, 10)
	W.stroke(balance, W.ink, 2)
	W.gradient(balance, W.white, Color3.fromRGB(240, 197, 145), 65)
	self.points = W.title(balance, "0", 2, 0, 52, 46, 33, W.ink)
	self.points.Name, self.points.TextScaled = "Count", true
	local pointFont = Instance.new("UITextSizeConstraint")
	pointFont.MinTextSize, pointFont.MaxTextSize, pointFont.Parent = 12, 33, self.points
	self.pointsLabel = W.text(balance, "SKILL POINTS\nTO SPEND", 54, 0, 97, 46, 13, W.ink, true)
	self.balance = balance
	self.legend = clear(header, "Skill key", 0, 0, 253, 24)
	local function legendEntry(x, state, width)
		local setBadge = stateBadge(self.legend, x, 1)
		setBadge(state)
		local label = W.text(self.legend, state.label, x + 26, 0, width, 24, 14, W.white, true)
		return setBadge, label
	end
	legendEntry(0, states.owned, 46)
	self.setLegendBadge, self.legendAction = legendEntry(78, states.available, 80)
	legendEntry(189, states.locked, 55)
	self.heading = W.title(header, "Skill tree", 16, 1, 160, 34, 28, W.white, true)
	self.summary = W.text(header, "", 17, 35, 350, 21, 15, W.aqua, true)
	self.summary.Name = "Summary"
	self.summary.TextScaled = true
	local font = Instance.new("UITextSizeConstraint")
	font.MinTextSize, font.MaxTextSize, font.Parent = 10, 17, self.summary
	local home = W.button(header, "Recenter", 0, 10, 56, 44, W.aqua, "Center", "Select")
	home.Position = UDim2.new(1, -114, 0, 10)
	home.TextSize = 14
	home.Activated:Connect(function()
		self:home()
	end)
	for i, factor in { 1 / 1.25, 1.25 } do
		local button = W.button(
			header,
			if i == 1 then "Zoom out" else "Zoom in",
			0,
			10,
			44,
			44,
			W.muted,
			if i == 1 then "−" else "+",
			"Select"
		)
		button.Position = UDim2.new(1, -214 + (i - 1) * 50, 0, 10)
		button.Activated:Connect(function()
			self:zoomBy(factor)
		end)
	end
	local exit = W.closeButton(header, 0, 10, 44)
	exit.Position = UDim2.new(1, -52, 0, 10)
	exit.Activated:Connect(close)
	local footer = W.frame(screen, "Skill details", 0, 0, 500, 86, W.panel, 10)
	W.anchor(footer, 0.5, 1, UDim2.new(0.5, 0, 1, -6))
	W.stroke(footer, W.line, 1.5)
	self.footer = footer
	self.footerScale = W.scale(footer)
	self.title = W.title(footer, "", 12, 3, 250, 25, 19, W.gold, true)
	self.detail = W.text(footer, "", 12, 27, 250, 32, 14, W.white, true)
	self.detail.TextWrapped = true
	self.path = W.text(footer, "", 12, 60, 470, 23, 13, W.muted, true)
	self.path.TextWrapped = true
	self.learn = W.button(footer, "Learn", 0, 9, 106, 44, W.green, "", "Select")
	self.learn.Position = UDim2.new(1, -114, 0, 9)
	self.learn.Activated:Connect(function()
		if self.selected then
			net.Action:FireServer("Skill", self.selected)
		end
	end)
	local drag, start, initial
	local function inside(pos, box)
		local origin = game:GetService("GuiService"):GetInsetArea(Enum.ScreenInsets.None).Min
		local d = Vector2.new(pos.X, pos.Y) + origin - box.AbsolutePosition
		return d.X >= 0 and d.Y >= 0 and d.X < box.AbsoluteSize.X and d.Y < box.AbsoluteSize.Y
	end
	Input.InputBegan:Connect(function(input)
		if not screen.Visible or drag or not inside(input.Position, view) or inside(input.Position, footer) then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			drag, start, initial = input, Vector2.new(input.Position.X, input.Position.Y), self.pan
		end
	end)
	Input.InputChanged:Connect(function(input)
		if not screen.Visible then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel and inside(input.Position, view) then
			self:zoomBy(if input.Position.Z > 0 then 1.12 else 1 / 1.12)
		elseif
			drag
			and (
				drag == input
				or (
					drag.UserInputType == Enum.UserInputType.MouseButton1
					and input.UserInputType == Enum.UserInputType.MouseMovement
				)
			)
		then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - start
			if delta.Magnitude > 6 then
				self.pan = initial + delta
				self.suppressClickUntil = math.huge
				self:position()
			end
		end
	end)
	Input.InputEnded:Connect(function(input)
		if
			input == drag
			or (
				drag
				and drag.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == drag.UserInputType
			)
		then
			drag = nil
			if self.suppressClickUntil == math.huge then
				self.suppressClickUntil = os.clock() + 0.12
			end
		end
	end)
	screen:GetPropertyChangedSignal("Visible"):Connect(function()
		drag = nil
		self.suppressClickUntil = 0
		if not screen.Visible then
			self.pulses:ClearAllChildren()
		end
	end)
	view:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if screen.Visible then
			self:position()
		end
	end)
	return self
end

function Map:position()
	local size = self.view.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return
	end
	local scale = math.clamp(math.min(size.X / 690, (size.Y - 95) / 474), 0.86, 1.94) * self.zoom
	self.scale.Scale = scale
	local bounds = self.extent * scale + Vector2.new(75, 95)
	self.pan = Vector2.new(math.clamp(self.pan.X, -bounds.X, bounds.X), math.clamp(self.pan.Y, -bounds.Y, bounds.Y))
	self.canvas.Position = UDim2.new(0.5, self.pan.X, 0.5, self.pan.Y - 44)
	if self.layoutSize == size then
		return
	end
	self.layoutSize = size
	self.footerScale.Scale = math.clamp(size.X / 1080, 1, 1.24)
	local width = math.clamp((size.X - 12) / self.footerScale.Scale, 190, 510)
	self.footer.Size = UDim2.fromOffset(width, 86)
	self.title.Size, self.detail.Size = UDim2.fromOffset(width - 130, 25), UDim2.fromOffset(width - 130, 32)
	self.path.Size = UDim2.fromOffset(width - 24, 23)
	local wide, narrow = size.X >= 950, size.X < 550
	local headerHeight = if wide then 65 elseif narrow then 99 else 78
	self.header.Size = UDim2.new(1, 0, 0, headerHeight)
	self.view.Position, self.view.Size = UDim2.fromOffset(0, headerHeight), UDim2.new(1, 0, 1, -headerHeight)
	local cardWidth = math.clamp(size.X - 230, 82, 163)
	local numberWidth = math.floor(cardWidth * 0.36)
	self.balance.Size, self.balance.Position =
		UDim2.fromOffset(cardWidth, 44), UDim2.fromOffset(8, if wide then 10 else 4)
	self.points.Size = UDim2.fromOffset(numberWidth, 44)
	self.pointsLabel.Position = UDim2.fromOffset(numberWidth + 4, 0)
	self.pointsLabel.Size, self.pointsLabel.TextSize =
		UDim2.fromOffset(cardWidth - numberWidth - 6, 44), if cardWidth < 123 then 10 else 13
	self.heading.Visible = not narrow
	self.heading.Position = UDim2.fromOffset(183, if wide then 2 else 7)
	self.heading.Size = UDim2.fromOffset(139, 34)
	if wide then
		self.legend.Position = UDim2.new(1, -501, 0, 20)
		self.summary.Position, self.summary.Size = UDim2.fromOffset(184, 34), UDim2.new(1, -696, 0, 22)
	else
		self.legend.Position = UDim2.fromOffset(12, 50)
		local x = if narrow then 12 else 302
		self.summary.Position, self.summary.Size =
			UDim2.fromOffset(x, if narrow then 76 else 50), UDim2.new(1, -x - 12, 0, if narrow then 18 else 24)
	end
	for _, button in self.heading.Parent:GetChildren() do
		if button:IsA("GuiButton") then
			button.Position = UDim2.new(1, button.Position.X.Offset, 0, if wide then 10 else 4)
		end
	end
end
function Map:zoomBy(factor)
	local before = self.zoom
	self.zoom = math.clamp(before * factor, 0.5, 1.8)
	self.pan *= self.zoom / before
	self:position()
end
function Map:home()
	self.zoom, self.pan = 1, Vector2.zero
	self:position()
end
function Map:select(id)
	self.selected = id
	self:refresh()
end

function Map:showPurchase(id)
	local item = self.nodes[id]
	if not item or not self.screen.Visible or self.player:GetAttribute("MenuMotion") == false then
		return
	end
	local node = item.node
	local burst = clear(self.pulses, "Learned " .. id, node.x, node.y, 1, 1)
	local ring = diamond(burst, "Strike ring", 0, 0, 46, W.gold)
	ring.BackgroundTransparency = 1
	local rim = W.stroke(ring, W.gold, 5)
	W.tween(ring, 0.48, { Size = UDim2.fromOffset(103, 103) })
	W.tween(rim, 0.48, { Transparency = 1, Thickness = 1 })
	for i = 1, 6 do
		local angle = i * math.pi / 3
		local x, y = math.cos(angle), math.sin(angle)
		local chip = diamond(burst, "Spark", x * 20, y * 20, 7, if i % 2 == 0 then W.green else W.gold)
		W.tween(
			chip,
			0.42,
			{ Position = UDim2.fromOffset(x * 66, y * 66), BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 2) }
		)
	end
	-- Feedback and replicated attributes can arrive in either order.
	local owned = Skills.read(self.player)
	owned[id] = true
	for _, child in Skills.nodes do
		if not owned[child.id] and table.find(child.requires, id) and Skills.ready(child, owned) then
			local delta = Vector2.new(child.x - node.x, child.y - node.y)
			local endPoint = delta - delta.Unit * 37
			local start = delta.Unit * 34
			local streak = W.frame(burst, "Path spark", 0, 0, 22, 5, W.gold, 3)
			W.anchor(streak, 0.5, 0.5, UDim2.fromOffset(start.X, start.Y))
			streak.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			W.tween(streak, 0.57, { Position = UDim2.fromOffset(endPoint.X, endPoint.Y), BackgroundTransparency = 1 })
		end
	end
	Debris:AddItem(burst, 0.65)
end
function Map:refresh()
	local p = self.player
	local points, xp = p:GetAttribute("SkillPoints") or 0, p:GetAttribute("MiningXP") or 0
	local level = Expeditions.level(xp)
	local start = Expeditions.levelXP(level)
	local owned = Skills.read(p)
	local count = 0
	for _ in owned do
		count += 1
	end
	self.points.Text = tostring(points)
	self.pointsLabel.Text = if count == #Skills.nodes then "UNSPENT\nPOINTS" else "POINTS\nTO SPEND"
	self.balance.BackgroundColor3 = if points > 0 and count < #Skills.nodes then W.gold else W.muted
	local nextState = if points > 0 then states.available else states.unfunded
	self.setLegendBadge(nextState)
	self.legendAction.Text = nextState.label
	self.summary.Text = string.format(
		"Lv %d   ·   %d / %d XP   ·   %d/%d owned",
		level,
		xp - start,
		Expeditions.levelXP(level + 1) - start,
		count,
		#Skills.nodes
	)
	for id, item in self.nodes do
		local learned = owned[id]
		local ready = Skills.ready(item.node, owned)
		local color = colors[item.node.branch]
		local state = if learned then states.owned elseif ready then nextState else states.locked
		if item.state ~= state then
			item.state = state
			item.setBadge(state)
			item.face.BackgroundColor3 = if learned then color elseif state == states.available then W.gold else W.card
			item.shade.BackgroundTransparency = if state == states.locked
				then 0.42
				elseif state == states.unfunded then 0.75
				else 1
			item.title.TextColor3 = if state == states.locked
				then states.locked.tint
				elseif state == states.available then W.gold
				else W.white
			item.rim.Color = if state == states.locked then W.line else state.tint
			item.rim.Thickness = if learned or state == states.available then 4 else 2
		end
		item.selection.Visible = self.selected == id
		for parentId, line in item.lines do
			local connected = parentId == "Origin" or owned[parentId]
			line.BackgroundColor3 = if learned
				then W.green
				elseif ready then nextState.tint
				elseif connected then color
				else W.line
			line.BackgroundTransparency = if learned or ready and points > 0 then 0 elseif connected then 0.38 else 0.6
		end
		if self.selected == id then
			self.title.Text, self.title.TextColor3 = item.node.name, color
			self.detail.Text = item.node.detail
			self.learn.Visible = true
			self.learn.Interactable = not learned and ready and points > 0
			self.learn.Text = if learned
				then "✓ Owned"
				elseif not ready then "Locked"
				elseif points == 0 then "Need 1 point"
				else "Spend 1 point"
			self.learn.BackgroundColor3 = state.tint
			local missing = {}
			for _, parentId in item.node.requires do
				if not owned[parentId] then
					table.insert(missing, Skills.byId[parentId].name)
				end
			end
			self.path.Text = item.node.branch
				.. (
					if #missing > 0
						then "  ·  Needs " .. table.concat(missing, " + ")
						elseif #item.node.requires > 1 then "  ·  Both paths connected"
						else ""
				)
		end
	end
	if not self.selected then
		self.title.Text, self.title.TextColor3 =
			if count == #Skills.nodes then "Skill tree complete" else "Choose a skill", W.gold
		self.detail.Text, self.learn.Visible = "Drag to explore. Select a skill to see its effect.", false
		self.path.Text = "Earn 1 point each time you level up. Each skill costs 1 point."
	end
end
return Map
