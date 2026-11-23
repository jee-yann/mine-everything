local Shared = game:GetService("ReplicatedStorage").Shared
local Ores = require(Shared.Ores)
local GuiService = game:GetService("GuiService")
local LevelRing = require(script.Parent.LevelRing)
local StarterGui = game:GetService("StarterGui")
local Upgrades, Expeditions = require(Shared.Upgrades), require(Shared.Expeditions)
local W, Icons, Menu = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.HarborMenu)
local Audio = require(script.Parent.HarborAudio)
local Roster = require(script.Parent.MinerRoster)
local TouchActions = require(script.Parent.TouchActions)
local Celebration = require(script.Parent.UnlockCelebration)
local Hud = {}
Hud.__index = Hud
local Input = game:GetService("UserInputService")
local fullRed = Color3.fromRGB(255, 113, 109)
local hotbar = {
	{ page = "Inventory", code = Enum.KeyCode.B },
	{ page = "Skills", code = Enum.KeyCode.K },
	{ page = "Achievements", code = Enum.KeyCode.H },
	{ page = "Book", code = Enum.KeyCode.J },
	{ page = "Settings", code = Enum.KeyCode.P },
}
local function card(parent, name, x, y, w, h, top, bottom)
	local f = W.frame(parent, name, x, y, w, h, W.panel, 13)
	W.stroke(f, W.ink, 2)
	W.enamel(f, top or W.ocean, bottom or W.panel)
	local shine = W.frame(f, "Enamel highlight", 11, 2, w - 22, 2, W.white, 1)
	shine.BackgroundTransparency = 0.68
	return f
end
local function clearFrame(parent, name, x, y, width, height)
	local frame = W.frame(parent, name, x, y, width, height, W.ink)
	frame.BackgroundTransparency = 1
	return frame
end
function Hud.new(player, net, mobile)
	local self = setmetatable({ player = player, net = net, mobile = mobile, sawTouch = mobile }, Hud)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.ScreenInsets, gui.ZIndexBehavior =
		"MiningHUD", false, Enum.ScreenInsets.CoreUISafeInsets, Enum.ZIndexBehavior.Sibling
	-- The menus stay inside the core safe area. Individual HUD items also use the free top strip and outer corners.
	gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	gui.ClipToDeviceSafeArea = false
	gui.Parent = player:WaitForChild("PlayerGui")
	gui.DisplayOrder = 2
	local backdrop = Instance.new("ScreenGui")
	backdrop.Name, backdrop.ScreenInsets, backdrop.ResetOnSpawn, backdrop.DisplayOrder =
		"HarborShade", Enum.ScreenInsets.None, false, 1
	backdrop.Enabled, backdrop.Parent = false, gui.Parent
	local dim = W.frame(backdrop, "Dim", 0, 0, 1, 1, W.ink)
	dim.Size, dim.BackgroundTransparency, dim.Active = UDim2.fromScale(1, 1), 0.23, true
	local root = W.frame(gui, "SafeArea", 0, 0, 1, 1, W.ink)
	root.Size, root.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	self.root = root
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	local wallet = clearFrame(root, "Wallet", 0, 0, 220, 52)
	self.wallet = wallet
	Icons.draw(wallet, "Coins", 0, 1, 47)
	self.gold = W.title(wallet, "0", 50, -1, 170, 52, 52, W.gold, true)
	self.gold.Size = UDim2.new(1, -50, 0, 52)
	self.gold.TextScaled = true
	local goldSize = Instance.new("UITextSizeConstraint")
	goldSize.MinTextSize, goldSize.MaxTextSize, goldSize.Parent = 17, 52, self.gold
	W.outlineText(self.gold, 3)
	local tools = clearFrame(root, "Equipment and level", 0, 0, 200, 46)
	self.levelRing = LevelRing.new(tools, function()
		self:openPage("Skills")
	end)
	self.status = W.text(wallet, "", 0, 52, 210, 17, 13, W.gold, true)
	W.outlineText(self.status, 1.5)
	local haul = clearFrame(root, "Haul", 0, 0, 215, 79)
	self.haul, self.rows = haul, {}
	self.haulTitle = W.title(haul, "Your haul", 10, 4, 99, 24, 20, W.white, true)
	self.pack = W.title(haul, "", 100, 4, 105, 24, 17, W.white)
	local track = W.frame(haul, "Capacity", 10, 30, 195, 5, W.ink, 3)
	self.fill = W.frame(track, "Ore", 0, 0, 0, 5, W.green, 3)
	self.haulPulse = W.scale(self.haulTitle)
	self.haulValue = W.text(haul, "", 10, 58, 195, 18, 13, W.gold, true)
	for _, ore in Ores.list do
		local row = W.frame(haul, ore.name, 10, 38, 195, 20, W.panel)
		row.BackgroundTransparency = 1
		local sample = W.frame(row, "Ore sample", 1, 3, 14, 14, ore.color, 2)
		sample.Rotation = 15
		W.stroke(sample, W.ink, 1.5)
		W.text(row, ore.name, 21, 0, 120, 20, 16, W.white, true)
		local quantity = W.title(row, "", 137, 0, 58, 20, 17, W.white)
		quantity.Name, quantity.TextXAlignment = "Quantity", Enum.TextXAlignment.Right
		quantity.TextColor3 = ore.color:Lerp(W.white, 0.5)
		self.rows[ore.name] = row
	end
	local details = Instance.new("TextButton")
	details.Name, details.Text, details.BackgroundTransparency = "Haul details", "", 1
	details.Size, details.ZIndex, details.Parent = UDim2.fromScale(1, 1), 2, haul
	Audio.bind(details, "Select")
	details.Activated:Connect(function()
		self:openPage("Pack")
	end)
	local taskCard = clearFrame(root, "Current job", 0, 0, 215, 51)
	local jobTap = W.button(taskCard, "OpenJob", 0, 0, 215, 51, W.card, "", "Job")
	Icons.draw(jobTap, "Jobs", 7, 9, 33)
	self.job = W.title(jobTap, "", 46, 3, 141, 24, 18, W.white, true)
	self.jobCount = W.text(jobTap, "", 46, 26, 143, 20, 14, W.gold, true)
	W.title(jobTap, "›", 188, 4, 21, 42, 30, W.gold)
	self.ribbon = clearFrame(taskCard, "Discovery", 0, 54, 215, 52)
	self.ribbon.Visible = false
	self.ribbonType = W.text(self.ribbon, "", 12, 4, 192, 17, 12, W.aqua, true)
	self.ribbonName = W.title(self.ribbon, "", 12, 22, 192, 25, 20, W.white, true)
	jobTap.Activated:Connect(function()
		self:openPage("Jobs")
	end)
	local loc = clearFrame(root, "Location", 0, 0, 244, 55)
	self.layer = W.title(loc, "CITRINE COVE", 0, 0, 244, 39, 32, W.gold)
	self.layer.Name, self.layer.TextScaled = "Region", true
	local regionFont = Instance.new("UITextSizeConstraint")
	regionFont.MinTextSize, regionFont.MaxTextSize, regionFont.Parent = 16, 33, self.layer
	W.outlineText(self.layer, 2.6)
	self.depth = W.text(loc, "Surface", 0, 37, 244, 21, 15, W.white)
	self.depth.Name = "Depth"
	W.outlineText(self.depth, 1.8)
	self.surface = W.button(loc, "Surface", 0, 0, 112, 44, W.gold, "↑ Surface", "Select")
	W.anchor(self.surface, 0.5, 0, UDim2.new(0.5, 0, 1, 3))
	self.surface.Activated:Connect(function()
		net.Action:FireServer("Surface")
	end)
	local gear = clearFrame(tools, "Equipment", 0, 0, 150, 46)
	self.gearChips = {}
	for i, key in { "Power", "Speed", "Capacity" } do
		local chip = W.clearButton(gear, key, (i - 1) * 50, 0, 49, 46, "Select")
		local tint = Upgrades.items[key].color
		Icons.draw(chip, key, 0, 9, 28, tint)
		local value = W.title(chip, "1", 28, 5, 21, 34, 21, W.white, true)
		W.outlineText(value, 2)
		self.gearChips[key] = value
		chip.Activated:Connect(function()
			local level = player:GetAttribute(key) or 1
			self:notice(
				(if key == "Capacity" then "Pack" else key) .. " · Lv " .. level,
				Upgrades.describe(key, level),
				tint
			)
		end)
	end
	local dockWidth = 476
	local dock = clearFrame(root, "Action dock", 0, 0, dockWidth, 82)
	self.hotbarPages = {}
	self.navDots = {}
	self.jobDot = W.dot(jobTap, -12, 1)
	self.levelDot = W.pointBadge(self.levelRing.button, 0, -9)
	local navX = 0
	for _, slot in hotbar do
		local key = slot.page
		self.hotbarPages[slot.code] = key
		local tint = Menu.pages[key].color
		local width = if key == "Achievements" then 116 else 84
		local b = W.clearButton(dock, key, navX, 0, width, 82, "Open")
		navX += width + 6
		Icons.draw(b, if key == "Inventory" then "Pack" else key, (width - 58) / 2, 0, 58, tint)
		local caption = W.title(b, if key == "Book" then "Index" else key, 0, 55, width, 25, 17, W.white)
		W.outlineText(caption, 2.2)
		if key == "Skills" then
			self.navDots[key] = W.pointBadge(b, -4, 1)
		elseif key == "Achievements" or key == "Book" then
			self.navDots[key] = W.dot(b, -19, 3)
		end
		b.Activated:Connect(function()
			self:openPage(key)
		end)
	end
	local shortcuts = W.frame(root, "Edge shortcuts", 0, 0, 76, 100, W.ink)
	shortcuts.BackgroundTransparency = 1
	local function shortcut(key, tint, caption)
		local button = W.clearButton(shortcuts, key, 0, 0, 84, 48, "Select")
		Icons.draw(button, key, 0, 6, 36, tint)
		W.outlineText(W.title(button, caption, 36, if key == "Menu" then 11 else 3, 48, 24, 16, tint, true), 1.8)
		button.Activated:Connect(function()
			self:openPage(key)
		end)
		return button
	end
	local packButton = shortcut("Pack", W.gold, "Pack")
	self.edgeCount = W.text(packButton, "", 36, 25, 48, 17, 13, W.white, true)
	W.outlineText(self.edgeCount, 1.4)
	self.edgeCount.TextScaled = true
	self.edgeCountPulse = W.scale(self.edgeCount)
	local countSize = Instance.new("UITextSizeConstraint")
	countSize.MinTextSize, countSize.MaxTextSize, countSize.Parent = 9, 12, self.edgeCount
	local menuButton = shortcut("Menu", W.aqua, "Menu")
	self.edgeAlert = W.dot(menuButton, -13, 2)
	self.touchActions = TouchActions.new(root)
	self.mine = self.touchActions.hold
	local speech = clearFrame(root, "Feedback", 0, 0, 320, 47)
	self.message = W.title(speech, "", 5, 1, 310, 25, 18, W.white)
	self.detail = W.text(speech, "", 5, 25, 310, 18, 13, W.muted)
	for _, panel in { haul, taskCard, speech } do
		for _, label in panel:GetDescendants() do
			if label:IsA("TextLabel") then
				W.outlineText(label, if label.TextSize >= 18 then 2 else 1.4)
			end
		end
	end
	self.speech = speech
	for _, label in { self.message, self.detail } do
		local size = Instance.new("UITextSizeConstraint")
		size.MinTextSize, size.MaxTextSize, size.Parent = 10, label.TextSize, label
		label.TextScaled = true
	end
	local meter = W.frame(speech, "Mining progress", 10, -14, 300, 10, W.ink, 5)
	W.stroke(meter, W.ink, 2)
	self.swingFill = W.frame(meter, "Charge", 0, 0, 0, 10, W.aqua, 5)
	W.gradient(self.swingFill, W.white, W.gold, 0)
	meter.Visible = false
	self.meter = meter
	local aimGui = Instance.new("ScreenGui")
	aimGui.Name, aimGui.ResetOnSpawn, aimGui.ScreenInsets = "MiningAim", false, Enum.ScreenInsets.None
	aimGui.Parent = gui.Parent
	self.reticle = W.frame(aimGui, "Aim", 0, 0, 8, 8, W.white, 4)
	W.anchor(self.reticle, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	W.stroke(self.reticle, W.ink, 1.6)
	self.reticle.Visible = false
	local badge = W.frame(aimGui, "Mining cursor", 0, 0, 28, 28, W.ink, 14)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	self.cursor, self.cursorEdge = badge, W.stroke(badge, W.aqua, 2.3)
	self.cursorPick = Icons.draw(badge, "Power", 2, 2, 24, W.gold)
	self.denied = W.frame(badge, "No entry", 4, 12, 20, 4, Color3.fromRGB(255, 100, 108), 2)
	badge.Visible = false
	self.menu = Menu.new(root, player, net, function()
		self:setShop(false)
	end)
	self.unlocks = Celebration.new(self)
	self.roster = Roster.new(root, function()
		if self.layout then
			self.layout()
		end
	end)
	self.menu.showMiners = function()
		self.roster.override = true
		self.menu:close()
		self.layout()
	end
	local restoreChat
	self.menu.mapVisibilityChanged = function(open)
		dim.BackgroundTransparency = if open then 0 else 0.23
		if open then
			restoreChat = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
			if restoreChat then
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
			end
		elseif restoreChat then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
			restoreChat = nil
		end
	end
	self.overlay = self.menu.overlay
	self.overlay:GetPropertyChangedSignal("Visible"):Connect(function()
		backdrop.Enabled = self.overlay.Visible
		if self.overlay.Visible then self:aimAt(nil) end
		self.speech.Visible = false
		if self.layout then
			self.layout()
		end
	end)
	local walletScale, taskScale, haulScale = W.scale(wallet), W.scale(taskCard), W.scale(haul)
	local locScale, dockScale, speechScale = W.scale(loc), W.scale(dock), W.scale(speech)
	local toolScale = W.scale(tools)
	local legacyChat
	local chatWindow = game:GetService("TextChatService"):FindFirstChildOfClass("ChatWindowConfiguration")
	local chatInput = game:GetService("TextChatService"):FindFirstChildOfClass("ChatInputBarConfiguration")
	self.chatInput = chatInput
	self.layout = function()
		local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
		if width < 90 or height < 90 then
			return
		end
		-- A keyboard connected to a phone changes its controls, not its HUD footprint.
		local rosterOnDemand = self.sawTouch or Input.TouchEnabled
		local touchLayout = self.mobile or (rosterOnDemand and math.min(width, height) < 640)
		local edge = touchLayout or width < 850 or height < 470
		self.edgeMode = edge
		local playing = not self.overlay.Visible
		local typing = chatInput and chatInput.IsFocused
		local s = if edge then 1 else math.clamp(math.min(width / 1150, height / 750), 0.90, 1.32)
		local margin = if edge then 4 else 10
		self.menu:layout(width, height, touchLayout)
		walletScale.Scale, taskScale.Scale, haulScale.Scale, speechScale.Scale = s, s, s, s
		toolScale.Scale = s
		locScale.Scale = s
		local navScale = math.clamp(math.min(width / 1120, height / 655), 0.98, 1.65)
		dockScale.Scale = navScale
		local full = GuiService:GetInsetArea(Enum.ScreenInsets.None)
		self.viewportOffset = full.Min
		local core = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
		local device = GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
		local bar = GuiService:GetInsetArea(Enum.ScreenInsets.TopbarSafeInsets)
		-- These rectangles all use the core-safe origin, including negative top/left offsets.
		local leftEdge = math.max(margin, device.Min.X + 3)
		local outerRight = math.max(width - margin, width + full.Max.X - core.Max.X - 12)
		local narrow = width < 515
		local minimumWallet = 96
		-- The native bar can start at X=0 while chat pushes both corners onto
		-- the same row. Reserve the wallet's minimum width in that case.
		local freeLeft = math.max(math.max(0, bar.Min.X) + 5, if narrow then leftEdge + minimumWallet + 6 else 0)
		local freeRight = if bar.Max.X >= core.Max.X - 1 then outerRight else width + bar.Max.X - core.Max.X - 5
		local top = math.max(full.Min.Y + 11, device.Min.Y + 8)
		local pairWidth = 172
		local topActions = edge and width >= height and freeRight - freeLeft >= pairWidth + 189
		local titleRight = freeRight - (if topActions then pairWidth + 8 else 0)
		local inTopbar = titleRight - freeLeft >= 148
		local locWidth = if inTopbar then math.min(290, (titleRight - freeLeft) / s) else math.min(205, width * 0.58)
		local titleHalf = locWidth * s / 2
		local titleX = if inTopbar
			then math.max(freeLeft + titleHalf, math.min(width / 2, titleRight - titleHalf))
			else width - locWidth * s / 2 - margin
		loc.Size = UDim2.fromOffset(locWidth, 58)
		self.layer.Size = UDim2.fromOffset(locWidth, 39)
		self.depth.Size = UDim2.fromOffset(locWidth, 21)
		W.anchor(loc, 0.5, 0, UDim2.fromOffset(titleX, if inTopbar then top else 7))
		-- Leave a left column for the wallet when the region and shortcuts
		-- share its row on a compact screen. The gold amount scales to fit.
		local walletWidth = if narrow then math.clamp(math.min(titleX - titleHalf,
			width - margin - pairWidth) - leftEdge - 6, minimumWallet, 220) else 220
		wallet.Size = UDim2.fromOffset(walletWidth, 52)
		local rosterRoom = if edge then height * 0.45 else height - 18 - self.haul.Size.Y.Offset * s
		local rosterHeight, browsing = self.roster:layout(s, margin, edge, rosterRoom, rosterOnDemand)
		self.roster.panel.Visible = playing and (not rosterOnDemand or browsing)
		shortcuts.Visible = playing and edge and not typing and not (browsing and narrow)
		dock.Visible = playing and not edge
		taskCard.Visible = playing and not edge and not browsing
		haul.Visible = playing and not edge and not browsing
		wallet.Visible = playing and not (edge and (typing or (browsing and narrow)))
		loc.Visible = playing and not (edge and browsing)
		tools.Visible = wallet.Visible
		local toolsBottom = 0
		if edge then
			local chatRects = {}
			local function addBounds(chat)
				if chat.AbsoluteSize.X > 0 and chat.AbsoluteSize.Y > 0 then
					local pos = chat.AbsolutePosition - root.AbsolutePosition
					table.insert(chatRects, Rect.new(pos, pos + chat.AbsoluteSize))
				end
			end
			for _, chat in { chatWindow, chatInput } do
				if chat.Enabled then
					addBounds(chat)
				end
			end
			if legacyChat and legacyChat.Parent and legacyChat.Parent.Enabled and legacyChat.Visible then
				addBounds(legacyChat)
			end
			table.sort(chatRects, function(a, b)
				return a.Min.Y < b.Min.Y
			end)
			local function belowChat(x, y, w, h)
				for _, rect in chatRects do
					if x < rect.Max.X and x + w > rect.Min.X and y < rect.Max.Y and y + h > rect.Min.Y then
						y = rect.Max.Y + 6
					end
				end
				return y
			end
			local locationY = belowChat(titleX - titleHalf, loc.Position.Y.Offset, locWidth, 39)
			loc.Position = UDim2.fromOffset(titleX, locationY)
			local depthY = belowChat(titleX - 58, locationY + 37, 116, 21)
			self.depth.Position = UDim2.fromOffset(0, depthY - locationY)
			local surfaceY = belowChat(titleX - 56, depthY + 24, 112, 44)
			self.surface.Position = UDim2.new(0.5, 0, 0, surfaceY - locationY)
			local right = if topActions then freeRight else width - margin
			local rowY = if topActions then top elseif inTopbar then 4 else math.max(73, depthY + 26)
			rowY = belowChat(right - pairWidth, rowY, pairWidth, 48)
			if right > titleX - titleHalf and right - pairWidth < titleX + titleHalf
				and rowY + 48 > locationY and rowY < depthY + 21 then
				rowY = depthY + 26
			end
			if
				self.surface.Visible
				and titleX + 56 > right - pairWidth
				and titleX - 56 < right
				and rowY + 48 > surfaceY
				and rowY < surfaceY + 44
			then
				rowY = surfaceY + 46
			end
			rowY = belowChat(right - pairWidth, rowY, pairWidth, 48)
			local gearY = belowChat(right - 150, rowY + 51, 150, 46)
			local levelY = belowChat(right - 46, gearY + 48, 46, 46)
			toolsBottom = levelY + 46
			tools.Size = UDim2.fromOffset(150, toolsBottom - gearY)
			self.levelRing.button.Position = UDim2.fromOffset(104, levelY - gearY)
			local walletTop = belowChat(leftEdge, math.floor(height * (if width > height then 0.36 else 0.42)), walletWidth, 52)
			if narrow and leftEdge + walletWidth > right - 150 and walletTop < gearY + 46 and walletTop + 52 > rowY then
				walletTop = gearY + 50
			end
			if narrow and leftEdge + walletWidth > right - 46 and walletTop < toolsBottom and walletTop + 52 > levelY then
				walletTop = toolsBottom + 4
			end
			if not rosterOnDemand then
				-- Small keyboard windows have room for the roster in the thumbstick corner.
				W.anchor(self.roster.panel, 0, 1, UDim2.new(0, leftEdge, 1, -margin))
				local walletHeight = if self.status.Text == "" then 52 else 70
				walletTop = math.min(walletTop, height - margin - rosterHeight - walletHeight - 6)
			end
			local walletLeft = if walletTop + 52 > height - 100 then leftEdge + 92 else leftEdge
			if narrow and walletLeft < titleX + titleHalf and walletLeft + walletWidth > titleX - titleHalf then
				local regionBottom = math.max(locationY + loc.Size.Y.Offset, depthY + 21)
				if self.surface.Visible then regionBottom = math.max(regionBottom, surfaceY + 44) end
				if walletTop < regionBottom + 4 and walletTop + 52 > locationY then
					walletTop = belowChat(walletLeft, regionBottom + 4, walletWidth, 52)
				end
			end
			W.anchor(wallet, 0, 0, UDim2.fromOffset(walletLeft, math.min(walletTop, height - 56)))
			shortcuts.Size = UDim2.fromOffset(pairWidth, 48)
			shortcuts.Position = UDim2.fromOffset(right - pairWidth, rowY)
			menuButton.Position = UDim2.fromOffset(88, 0)
			W.anchor(tools, 1, 0, UDim2.fromOffset(right, gearY))
		else
			tools.Size = UDim2.fromOffset(200, 46)
			self.levelRing.button.Position = UDim2.fromOffset(154, 0)
			self.depth.Position = UDim2.fromOffset(0, 37)
			self.surface.Position = UDim2.new(0.5, 0, 1, 3)
			local bottom = margin
			W.anchor(tools, 0, 1, UDim2.new(0, margin, 1, -bottom))
			W.anchor(
				wallet,
				0,
				1,
				UDim2.new(0, margin, 1, -bottom - 46 * s - (if self.status.Text == "" then 0 else 18 * s))
			)
			W.anchor(dock, 0.5, 1, UDim2.new(0.5, 0, 1, -margin))
			local rightY = margin + rosterHeight + 4
			W.anchor(taskCard, 1, 0, UDim2.new(1, -margin, 0, rightY))
			W.anchor(haul, 1, 0, UDim2.new(1, -margin, 0, rightY + 55 * s))
		end
		local touchGui = gui.Parent:FindFirstChild("TouchGui")
		local jump = touchGui and touchGui:FindFirstChild("JumpButton", true)
		local validJump = jump and jump:IsA("ImageButton") and jump.Visible and jump.AbsoluteSize.Y > 0
		local touchBounds = self.touchActions:layout(
			root,
			if validJump then jump else nil,
			self.mobile and playing and not browsing and not typing,
			toolsBottom
		)
		local speechWidth = if edge then math.clamp(width - 175, 144, 248) else 320
		speechScale.Scale = s
		speech.Size = UDim2.fromOffset(speechWidth, if edge then 41 else 47)
		self.message.Size = UDim2.fromOffset(speechWidth - 10, if edge then 21 else 25)
		self.detail.Position = UDim2.fromOffset(5, if edge then 21 else 25)
		self.detail.Size = UDim2.fromOffset(speechWidth - 10, 18)
		meter.Size = UDim2.new(1, -20, 0, 7)
		self.meterHeadroom = -meter.Position.Y.Offset * speechScale.Scale
		local footer = if touchLayout and width < height then 136 else margin
		local speechBottom = if edge then footer else margin + 82 * navScale + 8
		local speechSize = Vector2.new(speechWidth, speech.Size.Y.Offset)
		W.anchor(
			speech,
			0.5,
			1,
			TouchActions.feedbackPosition(root.AbsoluteSize, speechSize, speechBottom, touchBounds)
		)
		self.speechHome = speech.Position
	end
	local function watchControl(button)
		local layer = button.Parent
		if
			button.Name == "Frame"
			and button:IsA("Frame")
			and layer
			and layer:IsA("ScreenGui")
			and layer.Name == "Chat"
		then
			legacyChat = button
			button:GetPropertyChangedSignal("Visible"):Connect(self.layout)
			layer:GetPropertyChangedSignal("Enabled"):Connect(self.layout)
		elseif button.Name == "JumpButton" and button:IsA("ImageButton") and button:FindFirstAncestor("TouchGui") then
			TouchActions.skinJump(button)
			button:GetPropertyChangedSignal("Visible"):Connect(self.layout)
		else
			return
		end
		button:GetPropertyChangedSignal("AbsolutePosition"):Connect(self.layout)
		button:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.layout)
		task.defer(self.layout)
	end
	gui.Parent.DescendantAdded:Connect(watchControl)
	local chatLayer = gui.Parent:FindFirstChild("Chat")
	if chatLayer and chatLayer:FindFirstChild("Frame") then
		watchControl(chatLayer.Frame)
	end
	local touch = gui.Parent:FindFirstChild("TouchGui")
	if touch then
		local jump = touch:FindFirstChild("JumpButton", true)
		if jump then
			watchControl(jump)
		end
	end
	for _, chat in { chatWindow, chatInput } do
		chat:GetPropertyChangedSignal("AbsolutePosition"):Connect(self.layout)
		chat:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.layout)
	end
	if chatInput then
		chatInput:GetPropertyChangedSignal("IsFocused"):Connect(self.layout)
	end
	self.surface:GetPropertyChangedSignal("Visible"):Connect(self.layout)
	self.status:GetPropertyChangedSignal("Text"):Connect(self.layout)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(self.layout)
	root:GetPropertyChangedSignal("AbsolutePosition"):Connect(self.layout)
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.layout)
	self.layout()
	local refreshPending = false
	player.AttributeChanged:Connect(function()
		if not refreshPending then
			refreshPending = true
			task.defer(function()
				refreshPending = false
				self:refresh()
			end)
		end
	end)
	net:GetAttributeChangedSignal("OrderDay"):Connect(function()
		self:refresh()
	end)
	self:refresh()
	return self
end
function Hud:placePanels(touch)
	self.mobile = touch
	self.sawTouch = self.sawTouch or touch
	self.layout()
	self:refresh()
end
function Hud:openPage(key)
	self.menu:open(key)
	self.reticle.Visible = false
end
function Hud:toggleHotbarPage(key)
	local menu = self.menu
	local samePage = menu.page == key or (key == "Inventory" and menu.tabLists[menu.page] ~= nil)
	if self.overlay.Visible and samePage and not menu.closing then
		Audio.menu(false)
		menu:close()
	else
		Audio.menu(true)
		self:openPage(key)
	end
end
function Hud:setShop(open)
	if open then
		self:openPage("Gear")
	else
		self.menu:close()
	end
end
function Hud:refresh()
	local p = self.player
	local function level(key)
		return p:GetAttribute(key) or 1
	end
	local used, cap = p:GetAttribute("Used") or 0, (p:GetAttribute("PackSlots") or Upgrades.items.Capacity.values[1])
	if not self.countingGold then
		self.gold.Text = W.goldAmount(p:GetAttribute("Gold") or 0)
	end
	self.pack.Text = W.number(used) .. " / " .. W.number(cap)
	self.edgeCount.Text = W.number(used) .. "/" .. W.number(cap)
	local full = used >= cap
	self.haulTitle.Text = if full then "Bag full!" else "Your haul"
	self.haulTitle.TextColor3 = if full then fullRed else W.white
	self.pack.TextColor3 = if full then fullRed else W.white
	self.edgeCount.TextColor3 = if full then fullRed else W.white
	self.fill.BackgroundColor3 = if full then fullRed else W.green
	local control = Input.PreferredInput
	local shortcut = if self.mobile then "↑" elseif control == Enum.PreferredInput.Gamepad then Input:GetStringForKeyCode(Enum.KeyCode.ButtonY) else "R"
	shortcut = shortcut:gsub("^Button", "")
	self.surface.Text = shortcut .. " · Surface" .. (if full then "\nBag full!" else "")
	if used >= cap and (self.lastUsed or 0) < cap and self.player:GetAttribute("MenuMotion") ~= false
		and not GuiService.ReducedMotionEnabled then
		for _, pulse in { self.haulPulse, self.edgeCountPulse } do
			pulse.Scale = 1.15
			W.tween(pulse, 0.38, { Scale = 1 })
		end
		self.surface.BackgroundColor3 = W.white
		W.tween(self.surface, 0.7, { BackgroundColor3 = W.gold })
	end
	if used ~= self.lastUsed or cap ~= self.lastCap then
		self.lastUsed, self.lastCap = used, cap
		W.tween(self.fill, 0.15, { Size = UDim2.fromScale(math.clamp(used / cap, 0, 1), 1) })
	end
	local held = Ores.carried(p)
	for _, row in self.rows do
		row.Visible = false
	end
	for i, entry in held do
		local ore = entry.ore
		local row = self.rows[ore.name]
		row.Quantity.Text = "×" .. entry.amount
		row.Position, row.Visible = UDim2.fromOffset(10, 38 + (i - 1) * 20), true
	end
	local visible = #held
	self.haulValue.Visible = visible > 0
	local footerY = 39 + visible * 20
	self.haulValue.Position = UDim2.fromOffset(10, footerY)
	self.haulValue.Text = "Sell value   "
		.. W.number((p:GetAttribute("BagValue") or 0) * (if p:GetAttribute("DoubleGold") then 2 else 1))
		.. " G"
	local haulHeight = footerY + (if visible > 0 then 22 else 0)
	if self.haul.Size.Y.Offset ~= haulHeight then
		self.haul.Size = UDim2.fromOffset(215, haulHeight)
		self.layout()
	end
	local status = p:GetAttribute("SaveStatus")
	self.status.Text = if status == "Saving enabled" or status == "Practice session" then "" else status or ""
	local mined = p:GetAttribute("Mined") or 0
	local xp = p:GetAttribute("MiningXP") or 0
	self.levelRing:update(xp, p:GetAttribute("ProfileReady") == true)
	local job
	for i, candidate in Expeditions.jobs do
		if not Expeditions.jobClaimed(p:GetAttribute("ClaimedJobs") or 0, i) then
			job = candidate
			break
		end
	end
	local dailyDone = (p:GetAttribute("DailyClaim") or 0) >= (self.net:GetAttribute("OrderDay") or 0)
	local claimable = job and mined >= job.goal
	self.job.Text = if claimable
		then "Claim " .. W.number(job.reward) .. " G"
		elseif job then job.title
		else "Daily supply order"
	self.job.TextColor3 = if claimable then W.gold else W.white
	if claimable and self.claimShown ~= job and self.player:GetAttribute("MenuMotion") ~= false then
		self.job.Parent.BackgroundColor3 = W.gold
		W.tween(self.job.Parent, 0.65, { BackgroundColor3 = W.card })
	end
	self.claimShown = if claimable then job else nil
	self.jobCount.Text = if claimable
		then job.title
		elseif job then string.format("%d / %d  ·  %s G", mined, job.goal, W.number(job.reward))
		elseif dailyDone then "Delivered today"
		else "View today's delivery"
	self.jobCount.TextColor3 = if job and mined >= job.goal then W.green else W.gold
	local any = self.menu:attention("Jobs")
	self.jobDot.Visible = any
	for key, dot in self.navDots do
		dot.Visible = self.menu:attention(key)
		any = any or dot.Visible
	end
	self.edgeAlert.Visible = any
	local pointCount = tostring(p:GetAttribute("SkillPoints") or 0)
	self.levelDot.Text, self.navDots.Skills.Text = pointCount, pointCount
	self.levelDot.Visible = self.navDots.Skills.Visible
	for _, key in Upgrades.order do
		self.gearChips[key].Text = tostring(level(key))
	end
	self.menu:refresh()
end
function Hud:pickup(ore, amount, point)
	if self.overlay.Visible or (not self.haul.Visible and not self.edgeMode) then
		return
	end
	local quantity = if self.haul.Visible then self.rows[ore.name].Quantity else self.edgeCount
	local function pulse()
		quantity.TextColor3 = W.gold
		W.tween(
			quantity,
			0.32,
			{ TextColor3 = if self.edgeMode and self.lastUsed >= self.lastCap then fullRed else W.white }
		)
	end
	local camera = workspace.CurrentCamera
	if not camera or self.player:GetAttribute("MenuMotion") == false or GuiService.ReducedMotionEnabled then
		return
	end
	if ore.host then
		pulse()
		return
	end
	local projected, visible = camera:WorldToViewportPoint(point)
	if not visible then
		pulse()
		return
	end
	-- Let replicated quantities settle before reading the sorted row's position.
	task.defer(function()
		local destination = quantity.AbsolutePosition + quantity.AbsoluteSize * 0.5 - self.root.AbsolutePosition
		local start = Vector2.new(projected.X, projected.Y) + self.viewportOffset
		local size = 19
		local crumb = W.frame(self.root, "Collected " .. ore.name, start.X, start.Y, size, size, ore.color, 3)
		crumb.AnchorPoint, crumb.ZIndex, crumb.Rotation = Vector2.new(0.5, 0.5), 12, -16
		W.stroke(crumb, W.ink, 1.5)
		local count = W.title(crumb, "+" .. amount, size + 1, -3, 30, size + 6, size, W.white, true)
		W.outlineText(count, 1.5)
		W.tween(crumb, 0.46, {
			Position = UDim2.fromOffset(destination.X, destination.Y),
			Rotation = 12,
		}).Completed
			:Once(function()
				crumb:Destroy()
				pulse()
			end)
	end)
end
function Hud:pointerOnControl(screen)
	if GuiService.MenuIsOpen or Input:GetFocusedTextBox() or (self.chatInput and self.chatInput.IsFocused) then return true end
	for _, item in self.player.PlayerGui:GetGuiObjectsAtPosition(screen.X, screen.Y) do
		if item:IsA("GuiButton") or item:IsA("TextBox") then return true end
	end
	return false
end

function Hud:aimAt(screen, valid, blocked)
	if not screen then self.reticle.Visible = false end
	if self.speechHome then
		local showingNotice = os.clock() < (self.untilTime or 0)
		if screen and (valid or blocked) and (self.meter.Visible or not showingNotice) then
			local at = screen + self.viewportOffset
			local bounds, size = self.root.AbsoluteSize, self.speech.AbsoluteSize
			local x = math.clamp(at.X, size.X / 2, math.max(size.X / 2, bounds.X - size.X / 2))
			local cursorBottom = at.Y + self.cursor.AbsoluteSize.Y / 2
			local bottom = cursorBottom + 8 + self.meterHeadroom + size.Y
			self.speech.Position =
				UDim2.fromOffset(x, if bottom <= bounds.Y then bottom else math.max(size.Y + self.meterHeadroom, at.Y - 20))
		else
			self.speech.Position = self.speechHome
		end
	end
	self.cursor.Visible = screen ~= nil and (valid or blocked) and not self.overlay.Visible
	local replaceMouse = self.cursor.Visible and Input.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
	if replaceMouse then
		if self.originalMouseIcon == nil then self.originalMouseIcon = Input.MouseIconEnabled end
		Input.MouseIconEnabled = false
	elseif self.originalMouseIcon ~= nil then
		Input.MouseIconEnabled, self.originalMouseIcon = self.originalMouseIcon, nil
	end
	if not self.cursor.Visible then
		return
	end
	self.cursor.Position = UDim2.fromOffset(screen.X, screen.Y)
	self.cursorPick.Visible, self.denied.Visible = valid, not valid
	self.cursorEdge.Color = if valid then W.aqua else self.denied.BackgroundColor3
	if not self.meter.Visible then
		self.cursorPick.Rotation = 0
	end
end
function Hud:milestone(kind, name, color)
	if self.edgeMode then
		self:notice(name, kind, color)
		return
	end
	local serial = (self.ribbonSerial or 0) + 1
	self.ribbonSerial = serial
	self.ribbonType.Text, self.ribbonType.TextColor3, self.ribbonName.Text = kind, color:Lerp(W.white, 0.36), name
	self.ribbon.Visible = true
	local y = 60 + self.haul.Size.Y.Offset
	self.ribbon.Position = UDim2.fromOffset(18, y)
	W.tween(self.ribbon, 0.2, { Position = UDim2.fromOffset(0, y) })
	task.delay(3.4, function()
		if self.ribbonSerial == serial then
			self.ribbon.Visible = false
		end
	end)
end
function Hud:workshop(key, level)
	local tint = Upgrades.items[key].color
	if self.workshopCard then
		self.workshopCard:Destroy()
	end
	local panel = card(self.root, "Upgrade fitted", 0, 0, 278, 68, tint:Lerp(W.ink, 0.32), W.panel)
	panel.ZIndex = 30
	W.anchor(panel, 0.5, 0, UDim2.new(0.5, 0, 0, 9))
	local headline = if key == "Power"
		then Upgrades.pickNames[level]
		elseif key == "Capacity" then "Field pack expanded"
		else "Faster pick swing"
	W.title(panel, headline, 8, 7, 262, 29, 22, W.white)
	W.text(panel, key .. "  Lv " .. level .. "   ·   " .. Upgrades.describe(key, level), 8, 37, 262, 22, 15, W.gold)
	self.workshopCard = panel
	if self.player:GetAttribute("MenuMotion") ~= false then
		local scale = W.scale(panel)
		scale.Scale = 0.78
		W.tween(scale, 0.21, { Scale = 1 })
	end
	task.delay(2.4, function()
		if self.workshopCard == panel then
			panel:Destroy()
			self.workshopCard = nil
		end
	end)
end
function Hud:notice(title, detail, color)
	self.untilTime = os.clock() + 2.1
	self.message.Text, self.message.TextColor3, self.detail.Text = title, color or W.white, detail or ""
	if self.overlay.Visible then
		self.menu.status.Text = title
	end
	self.speech.Visible = not self.overlay.Visible
	self.message.TextTransparency = 0.35
	W.tween(self.message, 0.16, { TextTransparency = 0 })
end
function Hud:guide(title, detail, visible)
	if os.clock() < (self.untilTime or 0) then
		return
	end
	self.speech.Visible = visible
	self.message.Text, self.message.TextColor3, self.detail.Text = title, W.white, detail
end
return Hud
