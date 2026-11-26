-- The leaderboards behind spawn as lists that scroll, up to the top 100. The server leaves the rankings
-- on each board; everyone scrolls their own copy.
local Http = game:GetService("HttpService")
local W = require(script.Parent.Widgets)
local Boards = {}
local rgb = Color3.fromRGB
local width, height, rowHeight = 980, 468, 46
local medals = { W.gold, rgb(214, 224, 240), rgb(232, 158, 96) }

local function scoreText(kind, score)
	return if kind == "Rebirths" then "★" .. score else "Lv " .. score
end

function Boards.build(player, key)
	local self = { rows = {}, kind = if key == "Global" then "Rebirths" else "Level" }
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.ResetOnSpawn, gui.Face = key .. " standings", false, Enum.NormalId.Front
	gui.SizingMode, gui.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(width, height)
	gui.LightInfluence, gui.MaxDistance, gui.ClipsDescendants, gui.Enabled = 0, 110, true, false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player.PlayerGui
	local back = W.frame(gui, "Board", 0, 0, width, height, W.white)
	W.enamelPanel(back, rgb(70, 66, 122), rgb(38, 36, 74), 22)
	local bar = W.frame(back, "Header", 0, 0, width, 78, W.white, 22)
	W.enamelPanel(bar, rgb(255, 230, 128), rgb(243, 165, 26), 22)
	local title = W.title(bar, if key == "Global" then "Global Miners" else "Server Miners", 28, 0, 520, 76, 50, W.white, true)
	W.navyText(title, 4)
	local tabs = {}
	if key == "Global" then
		for i, kind in { "Rebirths", "Level" } do
			local b = W.clearButton(bar, kind, 572 + (i - 1) * 198, 12, 188, 52, "Select")
			W.round(b, 14)
			local paint = W.enamelPanel(b, rgb(72, 68, 124), rgb(46, 43, 86), 14)
			local label = W.title(b, if kind == "Rebirths" then "Rebirths" else "Level", 0, 0, 188, 50, 30, W.white)
			label.ZIndex = 3
			W.navyText(label, 3)
			tabs[kind] = paint
			b.Activated:Connect(function()
				self.kind = kind
				self.list.CanvasPosition = Vector2.zero
				self.refresh(true)
			end)
		end
	end
	local list = Instance.new("ScrollingFrame")
	list.Name, list.Position, list.Size = "Rows", UDim2.fromOffset(18, 88), UDim2.fromOffset(width - 118, height - 100)
	list.BackgroundTransparency, list.BorderSizePixel, list.ScrollBarThickness = 1, 0, 12
	list.ScrollBarImageColor3, list.ScrollingDirection, list.Parent = W.white, Enum.ScrollingDirection.Y, back
	self.list = list
	-- Buttons too: a wheel over a board in the world can also move the camera.
	for i, glyph in { "▲", "▼" } do
		local b = W.clearButton(back, if i == 1 then "Up" else "Down", width - 88, 100 + (i - 1) * 184, 70, 170, "Select")
		W.round(b, 16)
		W.enamelPanel(b, rgb(134, 214, 255), rgb(47, 130, 230), 16)
		local label = W.title(b, glyph, 0, 0, 70, 168, 44, W.white)
		label.ZIndex = 3
		W.navyText(label, 3)
		b.Activated:Connect(function()
			local by = (if i == 1 then -1 else 1) * rowHeight * 5
			local most = math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y)
			W.tween(list, 0.2, { CanvasPosition = Vector2.new(0, math.clamp(list.CanvasPosition.Y + by, 0, most)) })
		end)
	end
	local empty = W.title(list, "", 0, 0, width - 130, 80, 34, W.muted)
	local shown
	local function row(i)
		local entry = self.rows[i]
		if not entry then
			local frame = W.frame(list, "Row " .. i, 0, (i - 1) * rowHeight, width - 134, rowHeight - 5, W.navy, 10)
			entry = {
				frame = frame,
				rank = W.title(frame, "", 8, 0, 76, rowHeight - 5, 29, W.white),
				name = W.title(frame, "", 92, 0, 480, rowHeight - 5, 28, W.white, true),
				score = W.title(frame, "", 580, 0, width - 134 - 596, rowHeight - 5, 28, W.gold),
			}
			entry.score.TextXAlignment = Enum.TextXAlignment.Right
			entry.name.TextTruncate = Enum.TextTruncate.AtEnd
			self.rows[i] = entry
		end
		return entry
	end
	function self.refresh(force)
		local board = self.board
		local source = board and board:GetAttribute("Ranks" .. self.kind)
		for kind, paint in tabs do
			paint.Color = if kind == self.kind
				then ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
				else ColorSequence.new(rgb(72, 68, 124), rgb(46, 43, 86))
		end
		if source == shown and not force then return end
		shown = source
		local ok, ranks = pcall(Http.JSONDecode, Http, source or "[]")
		if not ok then ranks = {} end
		for i, rank in ranks do
			local entry = row(i)
			local mine = rank.id == player.UserId
			entry.frame.Visible = true
			entry.frame.BackgroundColor3 = if mine then rgb(62, 178, 52) elseif i % 2 == 0 then rgb(52, 49, 96) else W.navy
			entry.rank.Text, entry.rank.TextColor3 = "#" .. i, medals[i] or W.white
			entry.name.Text, entry.name.TextColor3 = rank.name, medals[i] or W.white
			entry.score.Text = scoreText(self.kind, rank.score)
		end
		for i = #ranks + 1, #self.rows do
			self.rows[i].frame.Visible = false
		end
		empty.Text = if #ranks == 0 then board and board:GetAttribute("Notice") or "No records yet" else ""
		list.CanvasSize = UDim2.fromOffset(0, #ranks * rowHeight)
	end
	self.gui = gui
	return self
end

function Boards.start(player, hud)
	local boards = { Server = Boards.build(player, "Server"), Global = Boards.build(player, "Global") }
	task.spawn(function()
		while true do
			local island = workspace:FindFirstChild("CitrineCove")
			local court = island and island:FindFirstChild("Miners Court", true)
			for key, board in boards do
				local standings = court and court:FindFirstChild(key) and court[key]:FindFirstChild("Standings")
				board.board = court and court:FindFirstChild(key)
				board.gui.Adornee = standings
				board.gui.Enabled = standings ~= nil and not hud.inOpening
				if standings and standings:FindFirstChild("Lettering") then
					standings.Lettering.Enabled = hud.inOpening == true
				end
				if standings then board.refresh() end
			end
			task.wait(0.5)
		end
	end)
	return boards
end

return Boards
