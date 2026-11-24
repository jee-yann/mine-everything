local Ores = require(game:GetService("ReplicatedStorage").Shared.Ores)
local client = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local W = require(client:WaitForChild("Widgets"))
local Display = {}
Display.__index = Display

function Display.new(location, onToggle, onFilter, onClear)
	local self = setmetatable({ options = {} }, Display)
	local safe = location.Parent
	local surface, depth = location:WaitForChild("Surface"), location:WaitForChild("Depth")
	local controls = W.frame(location, "X-ray controls", 0, 0, 172, 30, W.ink)
	controls.BackgroundTransparency = 1
	controls.AnchorPoint = Vector2.new(0.5, 0)
	local toggle = W.button(controls, "Toggle", 0, 0, 82, 30, W.aqua, "X-ray off", "Select")
	local filters = W.button(controls, "Filters", 88, 0, 84, 30, W.muted, "Ore filters", "Select")
	toggle.TextSize, filters.TextSize = 13, 13
	local badge = W.text(location, "", 0, 0, 208, 21, 13, W.white)
	badge.Name, badge.AnchorPoint = "Ore vision status", Vector2.new(0.5, 0)
	W.outlineText(badge, 1.4)
	local function place()
		local row = if surface.Visible then surface else depth
		local bottom = row.Position.Y + row.Size.Y
		controls.Position = UDim2.new(0.5, 0, bottom.Scale, bottom.Offset + 4)
		badge.Position = controls.Position + UDim2.fromOffset(0, 32)
	end
	for _, row in { surface, depth } do
		row:GetPropertyChangedSignal("Position"):Connect(place)
	end
	surface:GetPropertyChangedSignal("Visible"):Connect(place)
	place()
	-- Four columns of ore buttons; the panel grows with the catalog and stays short enough for phones.
	local columns, minerals = 4, 0
	for _, ore in Ores.list do
		if not ore.host then
			minerals += 1
		end
	end
	local rows = math.ceil(minerals / columns)
	local width, height = 20 + columns * 114 - 6, 84 + rows * 34 + 42
	local panel = W.frame(safe, "X-ray ore filters", 0, 0, width, height, W.panel, 12)
	panel.AnchorPoint, panel.Position, panel.ZIndex = Vector2.one * 0.5, UDim2.fromScale(0.5, 0.5), 20
	panel.Visible, panel.Active = false, true
	W.stroke(panel, W.line, 2)
	W.title(panel, "X-ray ores", 12, 5, 150, 32, 19, W.white, true)
	local close = W.closeButton(panel, width - 39, 6, 30)
	close.Modal = true
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	W.button(panel, "All", 10, 45, (width - 26) / 2, 30, W.aqua, "Select all", "Select").Activated:Connect(function()
		onFilter(Ores.visionMask)
	end)
	W.button(panel, "None", 16 + (width - 26) / 2, 45, (width - 26) / 2, 30, W.muted, "Clear all", "Select").Activated:Connect(function()
		onFilter(0)
	end)
	local index = 0
	for i = #Ores.list, 1, -1 do
		local ore = Ores.list[i]
		if ore.host then
			continue
		end
		local button = W.button(
			panel,
			ore.name,
			10 + (index % columns) * 114,
			84 + math.floor(index / columns) * 34,
			108,
			30,
			W.card,
			ore.name,
			"Select"
		)
		button.TextSize = 13
		button.Activated:Connect(function()
			onFilter(bit32.bxor(self.mask, ore.visionBit))
		end)
		self.options[ore] = button
		index += 1
	end
	W.button(panel, "Clear stone", 10, height - 40, width - 20, 32, W.orange, "Clear nearby stone  [Shift+C]", "Select").Activated:Connect(onClear)
	toggle.Activated:Connect(onToggle)
	filters.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
	self.panel, self.toggle, self.badge = panel, toggle, badge
	return self
end

function Display:selection(mask)
	self.mask = mask
	for ore, button in self.options do
		local on = bit32.btest(mask, ore.visionBit)
		button.Text = if on then "✓ " .. ore.name else ore.name
		button.TextColor3 = if on then ore.color:Lerp(W.white, 0.65) else W.muted
	end
end

function Display:enable(on)
	self.badge.Visible = on
	self.toggle.Text = if on then "X-ray on" else "X-ray off"
	if not on then self.panel.Visible = false end
end
return Display
