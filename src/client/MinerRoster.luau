local Players = game:GetService("Players")
local E = require(game:GetService("ReplicatedStorage").Shared.Expeditions)
local W = require(script.Parent.Widgets)
local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
local Roster = {}
Roster.__index = Roster

local width, rowHeight = 250, 36

function Roster.new(root, relayout)
	local self = setmetatable({ rows = {}, count = 0, relayout = relayout }, Roster)
	local panel = W.frame(root, "Server leaderboard", 0, 0, width, 32, W.panel, 15)
	W.enamelPanel(panel, Color3.fromRGB(94, 88, 160), Color3.fromRGB(62, 57, 112), 15)
	self.panel, self.scale = panel, W.scale(panel)
	local toggle = W.clearButton(panel, "Toggle miners", 0, 0, width, 44, "Select")
	local tab = W.frame(toggle, "Header", 0, 0, width, 44, W.panel, 15)
	W.enamelPanel(tab, Color3.fromRGB(134, 214, 255), Color3.fromRGB(47, 130, 230), 15)
	local heading = W.title(toggle, "Server miners", 14, 0, 170, 44, 21, W.white, true)
	heading.ZIndex = 2
	W.navyText(heading, 2.6)
	self.caption = W.title(toggle, "", 178, 0, 58, 44, 18, W.white)
	self.caption.ZIndex = 2
	W.navyText(self.caption, 2.2)
	self.caption.TextXAlignment = Enum.TextXAlignment.Right
	toggle.Activated:Connect(function()
		self:toggle()
	end)
	local headers = W.frame(panel, "Columns", 6, 48, width - 12, 16, W.panel)
	headers.BackgroundTransparency = 1
	W.text(headers, "MINER", 6, 0, 109, 16, 12, W.white, true)
	W.text(headers, "LEVEL", 122, 0, 41, 16, 12, W.aqua)
	W.text(headers, "GOLD", 166, 0, 66, 16, 12, W.gold)
	self.headers = headers
	local list = Instance.new("ScrollingFrame")
	list.Name, list.BackgroundTransparency, list.BorderSizePixel = "Miners", 1, 0
	list.Position, list.ScrollBarThickness = UDim2.fromOffset(6, 67), 3
	list.ScrollBarImageColor3, list.ScrollingDirection, list.Parent = W.line, Enum.ScrollingDirection.Y, panel
	self.list = list

	local function add(player)
		if self.rows[player] then
			return
		end
		local frame = W.frame(list, tostring(player.UserId), 0, 0, width - 15, rowHeight - 3, W.navy, 9)
		frame.BackgroundTransparency = 0.25
		local name = W.title(frame, "", 7, 1, 113, 18, 15, W.white, true)
		local title = W.text(frame, "", 7, 17, 118, 15, 12, W.muted, true)
		name.TextTruncate, title.TextTruncate = Enum.TextTruncate.AtEnd, Enum.TextTruncate.AtEnd
		local level = W.title(frame, "", 122, 0, 41, 32, 16, W.aqua)
		local gold = W.title(frame, "", 166, 0, 64, 32, 16, W.gold)
		gold.TextScaled = true
		local size = Instance.new("UITextSizeConstraint")
		size.MinTextSize, size.MaxTextSize, size.Parent = 8, 16, gold
		level.Name, gold.Name, title.Name = "Level", "Gold", "Title"
		local row = { frame = frame, player = player, name = name, level = level, title = title, gold = gold }
		self.rows[player] = row
		row.change = player.AttributeChanged:Connect(function(key)
			if key == "Level" or key == "EquippedTitle" or key == "Gold" or key == "Rebirths" then
				self:refresh()
			end
		end)
		self:refresh()
	end
	Players.PlayerAdded:Connect(add)
	Players.PlayerRemoving:Connect(function(player)
		local row = self.rows[player]
		if row then
			row.change:Disconnect()
			row.frame:Destroy()
			self.rows[player] = nil
			self:refresh()
		end
	end)
	for _, player in Players:GetPlayers() do
		add(player)
	end
	return self
end

function Roster:refresh()
	local ordered = {}
	for _, row in self.rows do
		table.insert(ordered, row)
	end
	table.sort(ordered, function(a, b)
		local al, bl = a.player:GetAttribute("Level") or 1, b.player:GetAttribute("Level") or 1
		return al > bl or al == bl and a.player.UserId < b.player.UserId
	end)
	for i, row in ordered do
		local player = row.player
		row.frame.Position = UDim2.fromOffset(0, (i - 1) * rowHeight)
		-- Rebirth milestone 1: the rebirth badge follows the name.
		row.name.RichText = true
		row.name.Text = i .. ". " .. player.DisplayName .. Rebirth.richBadge(player:GetAttribute("Rebirths") or 0)
		row.title.Text = (E.ranks[player:GetAttribute("EquippedTitle") or 1] or E.ranks[1]).name
		row.level.Text = tostring(player:GetAttribute("Level") or 1)
		row.gold.Text = W.goldAmount(player:GetAttribute("Gold") or 0)
	end
	self.list.CanvasSize = UDim2.fromOffset(0, #ordered * rowHeight)
	if self.count ~= #ordered then
		self.count = #ordered
		self.relayout()
	end
end

function Roster:toggle()
	self.override = not self.expanded
	self.relayout()
end

function Roster:layout(scale, top, compact, availableHeight, touch)
	local roomForRows = math.floor((availableHeight / scale - 73) / rowHeight)
	local maxRows = if touch then 3 else math.clamp(roomForRows, 1, if compact then 2 else 4)
	local expanded = if self.override == nil then not touch else self.override
	self.expanded = expanded
	self.scale.Scale = scale
	local rows = math.min(self.count, maxRows)
	local height = if expanded then 73 + rows * rowHeight else 44
	self.panel.Size = UDim2.fromOffset(width, height)
	self.list.Size = UDim2.fromOffset(width - 10, rows * rowHeight)
	self.list.Visible, self.headers.Visible = expanded, expanded
	self.caption.Text = self.count .. (if expanded then "   ▲" else "   ▼")
	W.anchor(self.panel, 1, 0, UDim2.new(1, -12, 0, top))
	return height * scale, expanded and (touch or (not compact and roomForRows < 1))
end
return Roster
