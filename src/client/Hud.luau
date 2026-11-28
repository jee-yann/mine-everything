local Shared = game:GetService("ReplicatedStorage").Shared
local Ores = require(Shared.Ores)
local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
local Purity = require(Shared.OrePurity)
local GuiService = game:GetService("GuiService")
local LevelRing = require(script.Parent.LevelRing)
local StarterGui = game:GetService("StarterGui")
local Upgrades, Expeditions = require(Shared.Upgrades), require(Shared.Expeditions)
local Field = require(Shared.FieldRewards)
local W, Icons, Menu = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.HarborMenu)
local Audio = require(script.Parent.HarborAudio)
local Roster = require(script.Parent.MinerRoster)
local TouchActions = require(script.Parent.TouchActions)
local Celebration = require(script.Parent.UnlockCelebration)
local SideButtons = require(script.Parent.SideButtons)
local GoldFlow, Burst, XpOrbs = require(script.Parent.GoldFlow), require(script.Parent.Burst), require(script.Parent.XpOrbs)
local Hud = {}
Hud.__index = Hud
local Input = game:GetService("UserInputService")
local fullRed = Color3.fromRGB(255, 113, 109)
local hotbar = {
	{ page = "Inventory", code = Enum.KeyCode.B },
	{ page = "Skills", code = Enum.KeyCode.Q },
	{ page = "Achievements", code = Enum.KeyCode.H },
	{ page = "Book", code = Enum.KeyCode.C },
	{ page = "Settings", code = Enum.KeyCode.P },
	{ page = "Rebirth", code = Enum.KeyCode.U },
	{ page = "Profile", code = Enum.KeyCode.F },
	{ page = "Daily", code = Enum.KeyCode.L },
	{ page = "Playtime", code = Enum.KeyCode.G },
	{ page = "Shop", code = Enum.KeyCode.N },
}
-- Shortcut letters shown on the side buttons' keycaps.
local shortcutLetters = {}
for _, slot in hotbar do
	shortcutLetters[slot.page] = slot.code.Name
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
	-- `safe` is the screen in real pixels: menus, the Mine button and anything drawn from a screen
	-- position (thrown coins, XP orbs, friend markers, spotlights) live there. The HUD's own widgets
	-- live in `root`, a layer laid out for a phone-sized screen and scaled up on tablets (hudScale), so a
	-- tablet shows the same HUD as a phone, just bigger.
	local safe = W.frame(gui, "SafeArea", 0, 0, 1, 1, W.ink)
	safe.Size, safe.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	self.root = safe
	local root = W.frame(safe, "HUD", 0, 0, 1, 1, W.ink)
	root.Size, root.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	self.hudFrame = root
	self.hudScale = 1
	local hudScale = Instance.new("UIScale")
	hudScale.Name, hudScale.Parent = "Device scale", root
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	local wallet = clearFrame(root, "Wallet", 0, 0, 220, 52)
	self.wallet = wallet
	self.coin = Icons.draw(wallet, "Coins", 0, 1, 47)
	self.coinScale = self.coin:FindFirstChildOfClass("UIScale")
	self.coinScale:SetAttribute("Rest", self.coinScale.Scale)
	-- A + on the coin: a shortcut to the Shop's gold packs.
	local plus = W.clearButton(wallet, "Get gold", 33, 31, 18, 18, "Open")
	plus.ZIndex = 6
	local plusFace = W.frame(plus, "Face", 0, 0, 18, 18, Color3.fromRGB(80, 200, 80), 9)
	plusFace.ZIndex = 6
	W.stroke(plusFace, W.navy, 2)
	W.gradient(plusFace, Color3.fromRGB(130, 230, 100), Color3.fromRGB(40, 160, 60), 90)
	local plusText = W.title(plusFace, "+", 0, -2, 18, 20, 18, W.white)
	plusText.ZIndex = 7
	W.navyText(plusText, 2)
	plus.Activated:Connect(function()
		self:openPage("ShopGold")
	end)
	self.goldPlus = plus
	self.gold = W.title(wallet, "0", 50, -1, 170, 52, 52, W.gold, true)
	self.gold.Size = UDim2.new(1, -50, 0, 52)
	self.gold.TextScaled = true
	local goldSize = Instance.new("UITextSizeConstraint")
	goldSize.MinTextSize, goldSize.MaxTextSize, goldSize.Parent = 17, 52, self.gold
	W.outlineText(self.gold, 3)
	local tools = clearFrame(root, "Equipment and level", 0, 0, 200, 46)
	self.tools = tools
	self.levelRing = LevelRing.new(tools, function()
		self:openPage("Skills")
	end)
	self.status = W.text(wallet, "", 0, 52, 210, 17, 13, W.gold, true)
	W.outlineText(self.status, 1.5)
	local haul = clearFrame(root, "Haul", 0, 0, 250, 79)
	-- The stats row draws over the haul card, so the level ring's skill-point tag (which pokes up
	-- into the card on touch screens) stays in front.
	tools.ZIndex = haul.ZIndex + 1
	local haulFace = W.frame(haul, "Face", 0, 0, 0, 0, W.white, 15)
	haulFace.Size = UDim2.fromScale(1, 1)
	W.enamelPanel(haulFace, Color3.fromRGB(94, 88, 160), Color3.fromRGB(62, 57, 112), 15)
	self.haul, self.rows = haul, {}
	self.haulTitle = W.title(haul, "Your haul", 14, 6, 136, 24, 20, W.white, true)
	self.pack = W.title(haul, "", 148, 6, 88, 24, 18, W.white)
	self.pack.TextXAlignment = Enum.TextXAlignment.Right
	local track = W.frame(haul, "Capacity", 13, 33, 224, 8, W.navy, 4)
	self.fill = W.frame(track, "Ore", 0, 0, 0, 8, W.green, 4)
	self.haulPulse = W.scale(self.haulTitle)
	self.haulValue = W.title(haul, "", 14, 58, 222, 20, 16, W.gold, true)
	for _, ore in Ores.list do
		local row = W.frame(haul, ore.name, 12, 46, 226, 20, W.panel)
		row.BackgroundTransparency = 1
		local sample = W.frame(row, "Ore sample", 1, 3, 14, 14, ore.color, 2)
		sample.Rotation = 15
		W.stroke(sample, W.ink, 1.5)
		W.text(row, ore.name, 21, 0, 98, 20, 16, W.white, true)
		-- What this stack adds to the sale: its base price in gold, then the purity bonus in aqua.
		local worth = W.text(row, "", 108, 0, 76, 20, 13, W.gold, true)
		worth.Name, worth.RichText, worth.TextXAlignment = "Worth", true, Enum.TextXAlignment.Right
		local quantity = W.title(row, "", 186, 0, 40, 20, 17, W.white)
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
	local taskCard = clearFrame(root, "Current job", 0, 0, 250, 58)
	local jobTap = W.clearButton(taskCard, "OpenJob", 0, 0, 250, 58, "Job")
	self.jobPaint = W.enamelPanel(jobTap, Color3.fromRGB(255, 208, 110), Color3.fromRGB(240, 148, 40), 15)
	Icons.draw(jobTap, "Jobs", 9, 10, 38)
	self.job = W.title(jobTap, "", 54, 5, 166, 26, 20, W.white, true)
	self.jobCount = W.text(jobTap, "", 54, 30, 170, 21, 15, W.white, true)
	W.title(jobTap, "›", 222, 6, 21, 44, 32, W.white)
	self.ribbon = W.frame(root, "Discovery", 0, 0, 330, 66, W.white, 17)
	self.ribbon.AnchorPoint, self.ribbon.ZIndex = Vector2.new(0.5, 0), 8
	self.ribbonPaint = W.enamelPanel(self.ribbon, Color3.fromRGB(134, 214, 255), Color3.fromRGB(47, 130, 230), 17)
	self.ribbon.Visible = false
	self.ribbonType = W.title(self.ribbon, "", 12, 5, 306, 24, 19, Color3.fromRGB(255, 244, 170))
	self.ribbonName = W.title(self.ribbon, "", 12, 27, 306, 34, 26, W.white)
	W.navyText(self.ribbonType, 2.3)
	W.navyText(self.ribbonName, 2.8)
	self.ribbonName.TextScaled = true
	local ribbonFont = Instance.new("UITextSizeConstraint")
	ribbonFont.MinTextSize, ribbonFont.MaxTextSize, ribbonFont.Parent = 12, 26, self.ribbonName
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
	self.surface = W.clearButton(loc, "Surface", 0, 0, 132, 46, "Select")
	W.round(self.surface, 14)
	local surfaceShadow = W.frame(self.surface, "Shadow", 0, 4, 132, 46, W.navy, 14)
	surfaceShadow.ZIndex = 0
	self.surfaceFace = W.frame(self.surface, "Face", 0, 0, 132, 46, W.white, 14)
	self.surfacePaint = W.enamelPanel(self.surfaceFace, Color3.fromRGB(255, 230, 128), Color3.fromRGB(243, 165, 26), 14)
	local surfaceName = W.title(self.surfaceFace, "↑ Surface", 2, 0, 128, 44, 22, W.white)
	surfaceName.Name = "Caption"
	W.navyText(surfaceName, 2.6)
	self.surfaceKey = SideButtons.letter(self.surfaceFace, "R", 126, 46)
	W.anchor(self.surface, 0.5, 0, UDim2.new(0.5, 0, 1, 3))
	self.surface.Activated:Connect(function()
		net.Action:FireServer("Surface")
	end)
	local gear = clearFrame(tools, "Equipment", 0, 0, 150, 46)
	self.gearChips = {}
	local gearOrder, gearButtons = { "Power", "Speed", "Capacity" }, {}
	for i, key in gearOrder do
		local chip = W.clearButton(gear, key, (i - 1) * 50, 0, 49, 46, "Select")
		local tint = Upgrades.items[key].color
		-- The pick is drawn on the diagonal, so at the same size it reads smaller than the others.
		if key == "Power" then
			Icons.draw(chip, key, -2, 6, 33, tint)
		else
			Icons.draw(chip, key, 0, 9, 28, tint)
		end
		local value = W.title(chip, "1", 29, 5, 21, 34, 21, W.white, true)
		W.outlineText(value, 2)
		self.gearChips[key] = value
		gearButtons[key] = chip
		chip.Activated:Connect(function()
			local level = player:GetAttribute(key) or 1
			self:notice(
				(if key == "Capacity" then "Pack" else key) .. " · Lv " .. level,
				Upgrades.describe(key, level),
				tint
			)
		end)
	end
	-- Each stat is as wide as its icon and number, with an even gap: "1" doesn't leave the hole that
	-- room for "14" would.
	self.gearWidth = 150
	self.packGear = function()
		local x = 0
		for _, key in gearOrder do
			local digits = #self.gearChips[key].Text
			local w = 30 + math.max(1, digits) * 12
			gearButtons[key].Size = UDim2.fromOffset(w, 46)
			gearButtons[key].Position = UDim2.fromOffset(x, 0)
			self.gearChips[key].Size = UDim2.fromOffset(w - 29, 34)
			x += w + 7
		end
		local width = x - 7
		if width ~= self.gearWidth then
			self.gearWidth = width
			gear.Size = UDim2.fromOffset(width, 46)
			if self.layout then self.layout() end
		end
	end
	self.packGear()
	-- Side buttons (desktop): menus in a rail on the left with a round Settings button above them,
	-- rewards in a rail on the right. Touch and small screens use the Pack and Menu shortcuts instead.
	self.hotbarPages = {}
	self.navDots = {}
	self.jobDot = W.dot(jobTap, -12, 1)
	self.levelDot = W.pointBadge(self.levelRing.button, 0, -9)
	for _, slot in hotbar do
		self.hotbarPages[slot.code] = slot.page
	end
	local tileStep = SideButtons.size + 24
	local menuRail = clearFrame(root, "Menu buttons", 0, 0, 2 * tileStep, 3 * tileStep + 68)
	-- The right rail: the Shop on top, then the daily card and playtime gifts, with the featured offers
	-- in a column beside them.
	local rewardRail = clearFrame(root, "Reward buttons", 0, 0, tileStep + SideButtons.size + 18, 3 * tileStep)
	self.rewardRail = rewardRail
	self.sideKeys = {}
	local settingsButton = SideButtons.round(menuRail, "Settings", shortcutLetters.Settings)
	settingsButton.button.Activated:Connect(function()
		self:openPage("Settings")
	end)
	table.insert(self.sideKeys, settingsButton.key)
	local railTiles = {}
	for i, key in { "Inventory", "Skills", "Achievements", "Book", "Rebirth", "Profile" } do
		local caption = if key == "Book" then "Index" elseif key == "Achievements" then "Awards" else key
		local tile = SideButtons.tile(menuRail, key, caption, shortcutLetters[key])
		railTiles[i] = tile.button
		table.insert(self.sideKeys, tile.key)
		if key == "Skills" then self.skillsTile = tile.button end
		if key == "Rebirth" then self.rebirthTile = tile end
		if key ~= "Profile" then
			self.navDots[key] = SideButtons.badge(tile, if key == "Book" then "NEW" elseif key == "Inventory" then "OPEN" else "!")
		end
		tile.button.Activated:Connect(function()
			self:openPage(key)
		end)
	end
	-- Two columns, never more. A short screen makes the buttons smaller instead.
	local function arrangeRail(columns, force)
		if self.railColumns == columns and not force then return end
		self.railColumns = columns
		for i, button in railTiles do
			local column, row = (i - 1) % columns, math.floor((i - 1) / columns)
			button.Position = UDim2.fromOffset(column * tileStep, row * tileStep)
			-- A tile's tag (OPEN, a count) pokes out of its top right corner, over the tile to its right
			-- and the one above: lower rows, then left columns, draw on top so the tag is never hidden.
			button.ZIndex = 2 + row * columns + (columns - 1 - column)
		end
		local rows = math.ceil(#railTiles / columns)
		settingsButton.button.Position = UDim2.fromOffset(0, rows * tileStep)
		menuRail.Size = UDim2.fromOffset(columns * tileStep, rows * tileStep + 68)
	end
	arrangeRail(2)
	local offerColumn = clearFrame(rewardRail, "Featured offers", 0, 16, SideButtons.size, 3 * tileStep)
	self.offers = require(script.Parent.FeaturedOffers).new(self, net, offerColumn, SideButtons.size)
	local shop = SideButtons.tile(rewardRail, "Shop", "Shop", shortcutLetters.Shop)
	shop.button.Position = UDim2.fromOffset(tileStep, 6)
	shop.button.Activated:Connect(function()
		self:toggleHotbarPage("Shop")
	end)
	table.insert(self.sideKeys, shop.key)
	self.shopTile = shop
	self.navDots.Shop = SideButtons.badge(shop, "!")
	local daily = SideButtons.tile(rewardRail, "Daily", "Daily", shortcutLetters.Daily)
	daily.button.Position = UDim2.fromOffset(tileStep, 6 + tileStep)
	daily.button.Activated:Connect(function()
		self:toggleHotbarPage("Daily")
	end)
	local gift = SideButtons.tile(rewardRail, "Playtime", "Gift", shortcutLetters.Playtime)
	gift.button.Position = UDim2.fromOffset(tileStep, 6 + 2 * tileStep)
	-- On phones the reward rail is a row (Shop, Daily, Gift) with the featured offers to the left of
	-- the Shop.
	local rewardTiles = { shop.button, daily.button, gift.button }
	local function arrangeRewards(row, force)
		if self.rewardRow == row and not force then return end
		self.rewardRow = row
		offerColumn.Position = if row then UDim2.fromOffset(0, -2) else UDim2.fromOffset(0, 16)
		offerColumn.Size = UDim2.fromOffset(SideButtons.size, 3 * tileStep)
		self.offers.horizontal = row
		self.offers.gap = math.floor((tileStep - SideButtons.size) * 0.6)
		self.offers:refresh()
		for i, button in rewardTiles do
			button.Position = if row then UDim2.fromOffset((i - 1) * tileStep, 0) else UDim2.fromOffset(tileStep, 6 + (i - 1) * tileStep)
			-- Tags in front of the next tile: in a row the left one draws on top, in a column the lower one.
			button.ZIndex = if row then 2 + #rewardTiles - i else 2 + i
		end
		rewardRail.Size = if row then UDim2.fromOffset(2 * tileStep + SideButtons.size + 6, tileStep) else UDim2.fromOffset(tileStep + SideButtons.size + 18, 3 * tileStep)
	end
	self.arrangeRewards = arrangeRewards
	-- Keyboards get a letter on each button's corner, so the buttons leave room for it. Touch screens
	-- have no letters: the buttons sit closer (the gap still grows with the screen, see hudScale).
	self.arrangeTiles = function(touch)
		local gap = if touch then 15 else 24
		if tileStep == SideButtons.size + gap then return end
		tileStep = SideButtons.size + gap
		arrangeRail(self.railColumns or 2, true)
		if self.rewardRow ~= nil then arrangeRewards(self.rewardRow, true) end
	end
	gift.button.Activated:Connect(function()
		self:toggleHotbarPage("Playtime")
	end)
	self.giftTile, self.giftBadge = gift, SideButtons.badge(gift)
	self.dailyTile, self.dailyBadge = daily, SideButtons.badge(daily)
	table.insert(self.sideKeys, daily.key)
	table.insert(self.sideKeys, gift.key)
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
	self.menuShortcut = menuButton
	self.edgeAlert = W.dot(menuButton, -13, 2)
	self.touchActions = TouchActions.new(safe)
	self.mine = self.touchActions.hold
	local speech = clearFrame(root, "Feedback", 0, 0, 460, 62)
	self.message = W.title(speech, "", 5, 1, 450, 34, 27, W.white)
	self.detail = W.text(speech, "", 5, 35, 450, 24, 18, W.white)
	for _, panel in { haul, taskCard, speech } do
		for _, label in panel:GetDescendants() do
			if label:IsA("TextLabel") then
				W.navyText(label, if label.TextSize >= 18 then 2.4 else 1.8)
			end
		end
	end
	self.speech = speech
	-- Why the aimed block can't be mined: one label, so its two lines move as one.
	local blocked = W.title(root, "", 0, 0, 640, 110, 24, W.white)
	blocked.Name, blocked.RichText, blocked.Visible, blocked.ZIndex = "Blocked", true, false, 6
	blocked.AnchorPoint, blocked.TextYAlignment = Vector2.new(0.5, 0.5), Enum.TextYAlignment.Center
	W.navyText(blocked, 3)
	self.blocked, self.blockedScale = blocked, W.scale(blocked)
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
	self.menu = Menu.new(safe, player, net, function()
		self:setShop(false)
	end)
	self.menu.hud = self
	self.unlocks = Celebration.new(self)
	self.goldFlow = GoldFlow.new(self)
	self.menu.holdGold = function(seconds, from)
		self.goldFlow:hold(seconds, from)
	end
	self.roster = Roster.new(root, function()
		if self.layout then
			self.layout()
		end
	end)
	self.roster.onPick = function(miner)
		self:openProfileOf(miner)
	end
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
	local locScale, speechScale = W.scale(loc), W.scale(speech)
	self.speechBase = 1
	local menuRailScale, rewardRailScale = W.scale(menuRail), W.scale(rewardRail)
	local toolScale = W.scale(tools)
	local legacyChat
	local chatWindow = game:GetService("TextChatService"):FindFirstChildOfClass("ChatWindowConfiguration")
	local chatInput = game:GetService("TextChatService"):FindFirstChildOfClass("ChatInputBarConfiguration")
	self.chatInput = chatInput
	self.layout = function()
		local screenW, screenH = safe.AbsoluteSize.X, safe.AbsoluteSize.Y
		if screenW < 90 or screenH < 90 then
			return
		end
		-- A keyboard connected to a phone or a tablet changes its controls, not its HUD: once a screen has
		-- been played by touch, or it is a touch screen without a mouse (phones, tablets) or a small one,
		-- it keeps the touch layout and the Mine button however it was last used. A touchscreen laptop
		-- played with its mouse keeps the desktop HUD.
		local rosterOnDemand = self.sawTouch or Input.TouchEnabled
		local touchLayout = self.mobile or self.sawTouch
			or (rosterOnDemand and (math.min(screenW, screenH) < 640 or not Input.MouseEnabled))
		-- Touch screens use the phone layout. On a bigger screen (a large phone, a tablet) the whole layer
		-- grows with the screen, so buttons and the gaps between them keep their share of it. Everything
		-- below works in the layer's units: the screen divided by k.
		local k = if touchLayout then math.clamp(math.min(screenW / 740, screenH / 340), 1, 1.8) else 1
		k = math.floor(k * 20 + 0.5) / 20
		if self.hudScale ~= k then
			self.hudScale = k
			hudScale.Scale = k
			root.Size = UDim2.fromScale(1 / k, 1 / k)
		end
		local width, height = screenW / k, screenH / k
		local function toLayer(rect: Rect): Rect
			return Rect.new(rect.Min / k, rect.Max / k)
		end
		self.arrangeTiles(rosterOnDemand)
		gui:SetAttribute("TouchLayout", touchLayout)
		gui:SetAttribute("RosterOnDemand", rosterOnDemand)
		local edge = touchLayout or width < 850 or height < 470
		self.edgeMode = edge
		local playing = not self.overlay.Visible
		local typing = chatInput and chatInput.IsFocused
		local s = if edge then 1 else math.clamp(math.min(width / 1150, height / 750), 0.90, 1.32)
		local margin = if edge then 4 else 10
		-- The menus sit on the real screen, not in the scaled layer.
		self.menu:layout(screenW, screenH, touchLayout)
		-- On desktop the gold and the stats in the bottom corner sit a size up from the cards, so they read
		-- next to the side buttons.
		local corner = if edge then s else s * 1.05
		-- Touch screens: Power, Speed, Bag and the level ring a size down, so they don't crowd the
		-- haul card and the right wall (tablets scale them up with the rest of the layer).
		local statScale = if edge and rosterOnDemand then 0.8 else corner
		walletScale.Scale, taskScale.Scale, haulScale.Scale = corner, s, s
		toolScale.Scale = statScale
		self.deskScale = s
		locScale.Scale = s
		local full = GuiService:GetInsetArea(Enum.ScreenInsets.None)
		-- In real pixels: things thrown from a screen position land in `safe`, which is not scaled.
		self.viewportOffset = full.Min
		full = toLayer(full)
		local core = toLayer(GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets))
		local device = toLayer(GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets))
		local bar = toLayer(GuiService:GetInsetArea(Enum.ScreenInsets.TopbarSafeInsets))
		-- These rectangles all use the core-safe origin, including negative top/left offsets.
		local leftEdge = math.max(margin, device.Min.X + 3)
		local outerRight = math.max(width - margin, width + full.Max.X - core.Max.X - 12)
		local narrow = width < 515
		local minimumWallet = 96
		-- The native bar can start at X=0 while chat pushes both corners onto
		-- the same row. Reserve the wallet's minimum width in that case.
		local freeLeft = math.max(math.max(0, bar.Min.X) + 5, if narrow then leftEdge + minimumWallet + 6 else 0)
		local freeRight = if bar.Max.X >= core.Max.X - 1 then outerRight else width + bar.Max.X - core.Max.X - 5
		-- The top row (the depth line and ↑ Surface on touch screens, the Shop row): right at the top of
		-- the screen, level with Roblox's own buttons. Held sideways nothing sits above it (a tablet's
		-- top inset is a status bar Roblox hides), so it keeps the same small gap on every device.
		local top = if width > height then full.Min.Y + 10 / k else math.max(full.Min.Y + 11, device.Min.Y + 8)
		-- The top right row: Pack and Menu, or on touch screens Pack and the Shop / Daily / Gift row.
		-- Phones drop the Pack shortcut (the haul card shows the bag), so the row is Shop / Daily / Gift.
		local pairWidth = if edge and rosterOnDemand then 162 else 172
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
		-- Touch screens keep the side buttons (smaller); only small keyboard windows fall back to the
		-- Pack and Menu shortcuts.
		local railsOnEdge = edge and rosterOnDemand
		self.railsOnEdge = railsOnEdge
		self.arrangeRewards(railsOnEdge)
		-- Keyboard letters only where there's a keyboard.
		for _, cap in self.sideKeys do
			cap.Visible = not rosterOnDemand
		end
		menuButton.Visible = not railsOnEdge
		shortcuts.Visible = playing and edge and not typing and not (browsing and narrow)
		menuRail.Visible = playing and (not edge or (railsOnEdge and not typing))
		rewardRail.Visible = playing and (not edge or (railsOnEdge and not typing and not (browsing and narrow)))
		taskCard.Visible = playing and not edge and not browsing
		haul.Visible = playing and (not edge or railsOnEdge) and not browsing
		wallet.Visible = playing and not (edge and (typing or (browsing and narrow)))
		loc.Visible = playing and not (edge and browsing)
		tools.Visible = wallet.Visible
		local toolsBottom = 0
		if edge then
			local chatRects = {}
			local function addBounds(chat)
				if chat.AbsoluteSize.X > 0 and chat.AbsoluteSize.Y > 0 then
					local pos = (chat.AbsolutePosition - safe.AbsolutePosition) / k
					table.insert(chatRects, Rect.new(pos, pos + chat.AbsoluteSize / k))
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
			-- Touch screens keep the depth line, ↑ Surface and the rest at the top: Roblox's chat window
			-- draws over them while it's open (on a tablet it reaches across the top and pushed them down).
			if railsOnEdge then table.clear(chatRects) end
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
			-- Phones skip the big region name up top (the screen is short): the depth line (which
			-- decides how often Starfall turns up) sits at the very top, the Surface button under it.
			self.layer.Visible, self.depth.Visible = not railsOnEdge, true
			if railsOnEdge then self.depth.Position = UDim2.fromOffset(0, 0) end
			local surfaceY = belowChat(titleX - 66, if railsOnEdge then locationY + 22 else depthY + 24, 132, 46)
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
				and titleX + 66 > right - pairWidth
				and titleX - 66 < right
				and rowY + 48 > surfaceY
				and rowY < surfaceY + 50
			then
				rowY = surfaceY + 52
			end
			rowY = belowChat(right - pairWidth, rowY, pairWidth, 48)
			local gearY = belowChat(right - 150, rowY + 51, 150, 46)
			local levelY = belowChat(right - 46, gearY + 48, 46, 46)
			if railsOnEdge then
				-- Phones: the haul card under the Shop row, then Power, Speed, Bag and the level ring in
				-- one row under it.
				local haulY = rowY + 54
				gearY = haulY + math.ceil(haul.Size.Y.Offset * 0.62) + 6
				levelY = gearY
				toolsBottom = gearY + math.ceil(46 * statScale)
				tools.Size = UDim2.fromOffset(self.gearWidth + 52, 46)
				self.levelRing.button.Position = UDim2.fromOffset(self.gearWidth + 6, 0)
				gear.Position = UDim2.fromOffset(0, 0)
				self.haulY = haulY
			else
				toolsBottom = levelY + 46
				tools.Size = UDim2.fromOffset(150, toolsBottom - gearY)
				self.levelRing.button.Position = UDim2.fromOffset(104, levelY - gearY)
				-- The stats line up with the Menu button's right edge above them.
				gear.Position = UDim2.fromOffset(150 - self.gearWidth, 0)
			end
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
			-- Never under the region name: on a short window the gold can be pushed up into it.
			if walletLeft < titleX + titleHalf and walletLeft + walletWidth > titleX - titleHalf then
				local regionBottom = math.max(locationY + loc.Size.Y.Offset, depthY + 21)
				if self.surface.Visible then regionBottom = math.max(regionBottom, surfaceY + 50) end
				if walletTop < regionBottom + 4 and walletTop + 52 > locationY then
					walletTop = belowChat(walletLeft, regionBottom + 4, walletWidth, 52)
				end
			end
			W.anchor(wallet, 0, 0, UDim2.fromOffset(walletLeft, math.min(walletTop, height - 56)))
			shortcuts.Size = UDim2.fromOffset(pairWidth, 48)
			shortcuts.Position = UDim2.fromOffset(right - pairWidth, rowY)
			menuButton.Position = UDim2.fromOffset(88, 0)
			W.anchor(tools, 1, 0, UDim2.fromOffset(right, gearY))
			packButton.Visible = not railsOnEdge
			if railsOnEdge then
				-- The haul card, small, under the Shop row on the right (as on desktop, in place of the
				-- Pack shortcut).
				haulScale.Scale = 0.62
				W.anchor(haul, 1, 0, UDim2.fromOffset(right, self.haulY or rowY + 54))
				local rowScale = 150 / rewardRail.Size.X.Offset
				rewardRailScale.Scale = rowScale
				W.anchor(rewardRail, 0, 0, UDim2.fromOffset(right - pairWidth, rowY + 1))
				-- The menu buttons: a small two-column rail at the top left, under Roblox's own buttons
				-- and above where the thumbstick sits. The gold sits beside it.
				-- A clear gap under Roblox's own buttons. It stays put when the chat window opens (the
				-- window draws over it): following the chat pushed the whole rail down and shrank it.
				local railTop = top + 62
				local menuHeight = menuRail.Size.Y.Offset
				local railScale = math.clamp((height * 0.7 - railTop) / menuHeight, 0.3, 0.62)
				menuRailScale.Scale = railScale
				W.anchor(menuRail, 0, 0, UDim2.fromOffset(leftEdge + 2, railTop))
				local railRight = leftEdge + 2 + menuRail.Size.X.Offset * railScale + 8
				local room = math.max(minimumWallet, math.min(220, titleX - titleHalf - railRight - 6))
				wallet.Size = UDim2.fromOffset(room, 52)
				-- The gold sits in the bottom left corner on phones.
				wallet.Size = UDim2.fromOffset(220, 52)
				W.anchor(wallet, 0, 1, UDim2.fromOffset(leftEdge + 4, height - 4))
				local _ = railRight
			else
				packButton.Position = UDim2.fromOffset(0, 0)
			end
		else
			tools.Size = UDim2.fromOffset(self.gearWidth + 52, 46)
			self.layer.Visible, self.depth.Visible = true, true
			self.levelRing.button.Position = UDim2.fromOffset(self.gearWidth + 6, 0)
			gear.Position = UDim2.fromOffset(0, 0)
			self.depth.Position = UDim2.fromOffset(0, 37)
			self.surface.Position = UDim2.new(0.5, 0, 1, 3)
			local bottom = margin
			W.anchor(tools, 0, 1, UDim2.new(0, margin, 1, -bottom))
			W.anchor(
				wallet,
				0,
				1,
				UDim2.new(0, margin, 1, -bottom - 46 * corner - (if self.status.Text == "" then 0 else 18 * corner))
			)
			local rightY = margin + rosterHeight + 9
			W.anchor(taskCard, 1, 0, UDim2.new(1, -margin - 2, 0, rightY))
			W.anchor(haul, 1, 0, UDim2.new(1, -margin - 2, 0, rightY + 66 * s))
			-- The menu rail fills the left side between the chat window and the wallet, shrinking to fit.
			local keyboard = not rosterOnDemand
			for _, cap in self.sideKeys do
				cap.Visible = keyboard
			end
			local railScale = math.clamp(math.min(width / 1400, height / 780), 0.78, 1.15)
			local walletTop = height - margin - (46 + 52) * corner - (if self.status.Text == "" then 0 else 18 * corner)
			local topLimit = margin + 6
			if StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat) and chatWindow and chatWindow.Enabled then
				for _, chat in { chatWindow, chatInput } do
					if chat and chat.Enabled and chat.AbsoluteSize.Y > 0 then
						local pos = (chat.AbsolutePosition - safe.AbsolutePosition) / k
						topLimit = math.max(topLimit, pos.Y + chat.AbsoluteSize.Y / k + 12)
					end
				end
				-- The window reports no size until it is drawn, and while it is folded away. Keep its
				-- usual place free, so the buttons never jump or sit under it.
				local usual = math.min(275, height * 0.4) * chatWindow.HeightScale + (if chatInput and chatInput.Enabled then 56 else 0)
				topLimit = math.max(topLimit, math.min(usual + 12, height * 0.55))
			end
			local room = walletTop - 12 - topLimit
			local menuHeight = menuRail.Size.Y.Offset
			-- Directly under the chat window, or centred when chat is out of the way.
			menuRailScale.Scale = math.max(0.5, math.min(railScale, room / menuHeight))
			local slack = math.max(0, room - menuHeight * menuRailScale.Scale)
			local menuTop = topLimit + (if topLimit > margin + 6 then 0 else slack / 2)
			W.anchor(menuRail, 0, 0, UDim2.fromOffset(margin + 4, menuTop))
			-- The reward rail sits under the haul card, or beside it when the haul is long.
			local haulBottom = rightY + (66 + self.haul.Size.Y.Offset) * s + 12
			local rewardHeight = rewardRail.Size.Y.Offset
			local fitBelow = (height - margin - haulBottom) / rewardHeight
			if fitBelow >= 0.6 then
				rewardRailScale.Scale = math.min(railScale, fitBelow)
				W.anchor(rewardRail, 1, 0, UDim2.fromOffset(width - margin - 2, haulBottom))
			else
				local top = rightY + 66 * s
				rewardRailScale.Scale = math.max(0.45, math.min(railScale, (height - margin - top) / rewardHeight))
				W.anchor(rewardRail, 1, 0, UDim2.fromOffset(width - margin - 268 * s, top))
			end
		end
		local touchGui = gui.Parent:FindFirstChild("TouchGui")
		local jump = touchGui and touchGui:FindFirstChild("JumpButton", true)
		local validJump = jump and jump:IsA("ImageButton") and jump.Visible and jump.AbsoluteSize.Y > 0
		-- Touch screens: the boost groups (BoostChips) sit in the very bottom right corner of the screen.
		-- Roblox's jump button, and the Mine button beside it, move up just enough to clear them.
		-- The status line in the bottom middle stays centred on touch screens; the row shrinks (down to a
		-- size that's still easy to tap) so it fits to the right of it.
		local speechWidth = if edge then math.clamp(width - 175, 144, if touchLayout then 260 else 290) else 460
		self.bonusCorner = nil
		self.bonusPitch = 45
		local bonusCount = self.bonusCount or 0
		local rowRect
		if railsOnEdge and bonusCount > 0 then
			local right, bottom = math.max(width, device.Max.X) - 3, math.max(height, device.Max.Y) - 2
			local room = right - (width / 2 + speechWidth / 2 + 6)
			local pitch = math.clamp(math.floor(room / bonusCount), 32, 45)
			self.bonusPitch = pitch
			local rowW, rowH = bonusCount * pitch, 38 * pitch / 45
			self.bonusCorner = Vector2.new(right, bottom)
			rowRect = Rect.new(Vector2.new(right - rowW, bottom - rowH), Vector2.new(right, bottom))
		end
		-- Where Roblox put the jump button, before any lift of ours (it may move it on a resize).
		local jumpRect
		if validJump then
			local expected = self.jumpSet
			if expected == nil or jump.Position ~= expected then
				self.jumpBase = jump.Position
			end
			local base, parent = self.jumpBase, jump.Parent
			local size = jump.AbsoluteSize
			local at = parent.AbsolutePosition + Vector2.new(
				base.X.Scale * parent.AbsoluteSize.X + base.X.Offset,
				base.Y.Scale * parent.AbsoluteSize.Y + base.Y.Offset
			) - jump.AnchorPoint * size
			jumpRect = { pos = at - safe.AbsolutePosition, size = size }
		end
		-- The Mine button is on the real screen (it matches Roblox's jump button), so convert both ways.
		local mineShown = touchLayout and playing and not browsing and not typing
		local function placeTouch(lift)
			local rect = if jumpRect then { pos = jumpRect.pos - Vector2.new(0, lift * k), size = jumpRect.size } else nil
			local bounds = self.touchActions:layout(safe, rect, mineShown, toolsBottom * k, k) or {}
			for i, box in bounds do
				bounds[i] = toLayer(box)
			end
			if rect and #bounds == 0 then
				local pos = rect.pos / k
				table.insert(bounds, Rect.new(pos, pos + rect.size / k))
			end
			return bounds
		end
		local touchBounds = placeTouch(0)
		local lift = 0
		if rowRect then
			for _, box in touchBounds do
				if box.Max.X > rowRect.Min.X and box.Min.X < rowRect.Max.X then
					lift = math.max(lift, box.Max.Y - rowRect.Min.Y + 4)
				end
			end
			if lift > 0 then
				touchBounds = placeTouch(lift)
			end
			table.insert(touchBounds, rowRect)
		end
		if validJump then
			local wanted = self.jumpBase - UDim2.fromOffset(0, math.round(lift * k))
			self.jumpSet = wanted
			if jump.Position ~= wanted then
				jump.Position = wanted
			end
		end
		if touchLayout then
			-- Centred, the status line is only as wide as the space between the middle of the screen and
			-- the nearest button on the right at its height (the Mine button on a small phone).
			local half = speechWidth / 2
			for _, box in touchBounds do
				if box ~= rowRect and box.Min.X > width / 2 and box.Max.Y > height - 90 then
					half = math.min(half, box.Min.X - 8 - width / 2)
				end
			end
			speechWidth = math.max(144, math.floor(half * 2))
		end
		if #touchBounds == 0 then touchBounds = nil end
		speechScale.Scale = s
		self.blockedScale.Scale = if edge then math.min(1, width / 560) else s
		self.speechBase = self.blockedScale.Scale
		-- A notice with several lines (a boost group's sources) makes the box taller, upward.
		-- Phones read a size smaller than desktop (tablets scale it up with the layer, see hudScale).
		self.speechHeight, self.detailHeight, self.noticeLine = if edge then 40 else 62, if edge then 17 else 24, if edge then 15 else 21
		local extra = self.noticeExtra or 0
		speech.Size = UDim2.fromOffset(speechWidth, self.speechHeight + extra)
		self.message.Size = UDim2.fromOffset(speechWidth - 10, if edge then 21 else 34)
		self.detail.Position = UDim2.fromOffset(5, if edge then 22 else 35)
		self.detail.Size = UDim2.fromOffset(speechWidth - 10, self.detailHeight + extra)
		meter.Size = UDim2.new(1, -20, 0, 7)
		self.meterHeadroom = -meter.Position.Y.Offset * speechScale.Scale
		local footer = if touchLayout and width < height then 136 else margin
		-- Clear of the bottom of the screen the device keeps for itself (the iPhone's home indicator).
		local homeBar = math.max(0, height - device.Max.Y)
		local speechBottom = if edge then footer + homeBar + (if touchLayout then 6 else 0) else margin + 24
		local speechSize = Vector2.new(speechWidth, speech.Size.Y.Offset)
		W.anchor(
			speech,
			0.5,
			1,
			TouchActions.feedbackPosition(Vector2.new(width, height), speechSize, speechBottom, touchBounds, touchLayout)
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
	safe:GetPropertyChangedSignal("AbsolutePosition"):Connect(self.layout)
	safe:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.layout)
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
	require(script.Parent.MenuCursor)(self)
	game:GetService("RunService").RenderStepped:Connect(function()
		if not self.blocked.Visible or not self.aimScreen then return end
		-- Follow the mouse every frame, not only when the aim is sampled.
		self:placeBlocked(if Input.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then Input:GetMouseLocation() else self.aimScreen)
	end)
	task.spawn(function()
		while gui.Parent do
			task.wait(1)
			self:refreshRewards()
		end
	end)
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
-- Another miner's profile, from their name on the board or the icon over their head.
function Hud:openProfileOf(miner)
	Audio.menu(true)
	self:openPage("Profile")
	local panel = self.menu.profile
	if panel then panel:view(if miner == self.player then nil else miner) end
end
function Hud:toggleHotbarPage(key)
	local menu = self.menu
	local page = menu.page or ""
	local samePage = page == key or (key == "Shop" and page:match("^Shop") ~= nil)
		or (key == "Inventory" and menu.inventory ~= nil and menu.wide == menu.inventory)

	if self.overlay.Visible and samePage and not menu.closing then
		Audio.menu(false)
		menu:close()
	else
		Audio.menu(true)
		self:openPage(key)
	end
end
-- Playtime gift tile: `ready` makes it wiggle and say Ready!; otherwise `caption` (a countdown) shows.
function Hud:setGiftReady(ready, caption, count)
	SideButtons.setReady(self.giftTile, ready, caption)
	self.giftBadge.Text = tostring(count or "!")
	self.giftBadge.Visible = ready
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
	self.goldFlow:set(p:GetAttribute("Gold") or 0)
	self.pack.Text = W.number(used) .. " / " .. W.number(cap)
	self.edgeCount.Text = W.number(used) .. "/" .. W.number(cap)
	local full = used >= cap
	self.haulTitle.Text = if full then "Backpack full!" else "Your haul"
	self.haulTitle.TextColor3 = if full then fullRed else W.white
	self.pack.TextColor3 = if full then fullRed else W.white
	self.edgeCount.TextColor3 = if full then fullRed else W.white
	self.fill.BackgroundColor3 = if full then fullRed else W.green
	local control = Input.PreferredInput
	local shortcut = if self.mobile then "↑" elseif control == Enum.PreferredInput.Gamepad then Input:GetStringForKeyCode(Enum.KeyCode.ButtonY) else "R"
	shortcut = shortcut:gsub("^Button", "")
	self.surfaceKey.Text = if self.mobile then "" else "[" .. shortcut .. "]"
	self.surfacePaint.Color = if full
		then ColorSequence.new(Color3.fromRGB(255, 150, 140), Color3.fromRGB(226, 58, 70))
		else ColorSequence.new(Color3.fromRGB(255, 230, 128), Color3.fromRGB(243, 165, 26))
	if used >= cap and (self.lastUsed or 0) < cap and self.player:GetAttribute("MenuMotion") ~= false
		and not GuiService.ReducedMotionEnabled then
		for _, pulse in { self.haulPulse, self.edgeCountPulse } do
			pulse.Scale = 1.15
			W.tween(pulse, 0.38, { Scale = 1 })
		end
		self.surfaceFace.Rotation = 4
		W.tween(self.surfaceFace, 0.5, { Rotation = 0 })
	end
	if used ~= self.lastUsed or cap ~= self.lastCap then
		self.lastUsed, self.lastCap = used, cap
		W.tween(self.fill, 0.15, { Size = UDim2.fromScale(math.clamp(used / cap, 0, 1), 1) })
	end
	local held = Ores.carried(p)
	for _, row in self.rows do
		row.Visible = false
	end
	-- A phone shows the four rarest ores carried; the sell value still counts everything.
	if self.railsOnEdge and #held > 4 then
		held = table.move(held, 1, 4, 1, {})
	end
	for i, entry in held do
		local ore = entry.ore
		local row = self.rows[ore.name]
		row.Quantity.Text = "×" .. entry.amount
		local broker, double = p:GetAttribute("SkillBroker"), Rebirth.saleMultiplier(p)
		local grades = Purity.decode(p:GetAttribute("Grades" .. ore.name))
		local total = Purity.quote(ore, entry.amount, grades, entry.amount, broker) * double
		local base = Purity.unitPrice(ore, nil, broker) * entry.amount * double
		row.Worth.Text = W.number(base) .. " G" .. (if total > base then W.colored(" +" .. W.number(total - base), W.aqua) else "")
		row.Position, row.Visible = UDim2.fromOffset(12, 46 + (i - 1) * 20), true
	end
	local visible = #held
	self.haulValue.Visible = visible > 0
	local footerY = 47 + visible * 20
	self.haulValue.Position = UDim2.fromOffset(14, footerY)
	self.haulValue.Text = "Sell value   "
		.. W.number((p:GetAttribute("BagValue") or 0) * Rebirth.saleMultiplier(p))
		.. " G"
	local haulHeight = footerY + (if visible > 0 then 27 else 4)
	if self.haul.Size.Y.Offset ~= haulHeight then
		self.haul.Size = UDim2.fromOffset(250, haulHeight)
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
	self.jobPaint.Color = if claimable
		then ColorSequence.new(Color3.fromRGB(166, 245, 154), Color3.fromRGB(52, 178, 74))
		else ColorSequence.new(Color3.fromRGB(255, 208, 110), Color3.fromRGB(240, 148, 40))
	if claimable and self.claimShown ~= job and self.player:GetAttribute("MenuMotion") ~= false then
		self.job.Parent.Rotation = 3
		W.tween(self.job.Parent, 0.45, { Rotation = 0 })
	end
	self.claimShown = if claimable then job else nil
	self.jobCount.Text = if claimable
		then job.title
		elseif job then string.format("%d / %d  ·  %s G", mined, job.goal, W.number(job.reward))
		elseif dailyDone then "Delivered today"
		else "View today's delivery"
	local any = self.menu:attention("Jobs")
	self.jobDot.Visible = any
	for key, dot in self.navDots do
		dot.Visible = self.menu:attention(key)
		any = any or dot.Visible
	end
	self:refreshRewards()
	any = any or self.dailyBadge.Visible or self.giftBadge.Visible
	self.edgeAlert.Visible = any
	local pointCount = tostring(p:GetAttribute("SkillPoints") or 0)
	self.levelDot.Text, self.navDots.Skills.Text = pointCount, pointCount
	self.levelDot.Visible = self.navDots.Skills.Visible
	for _, key in Upgrades.order do
		self.gearChips[key].Text = tostring(level(key))
	end
	self.packGear()
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
-- XP gained since the last look, thrown from `point`.
-- `earned` is what the server says this block gave; without it, what the ring saw arrive.
function Hud:showXP(point, earned)
	local amount = if type(earned) == "number" then earned else self.levelRing.gained or 0
	self.levelRing.gained = 0
	XpOrbs.show(self, amount, point)
end
function Hud:pointerOnControl(screen)
	if GuiService.MenuIsOpen or Input:GetFocusedTextBox() or (self.chatInput and self.chatInput.IsFocused) then return true end
	-- The mouse is measured from the window's corner. Gui positions start below the top bar.
	local at = screen - GuiService:GetGuiInset()
	for _, item in self.player.PlayerGui:GetGuiObjectsAtPosition(at.X, at.Y) do
		if item:IsA("GuiButton") or item:IsA("TextBox") then return true end
	end
	return false
end

function Hud:aimAt(screen, valid, blocked)
	if not screen then
		self.reticle.Visible, self.blocked.Visible = false, false
	end
	self.aimScreen = screen
	if self.speechHome then
		local showingNotice = os.clock() < (self.untilTime or 0)
		if screen and (valid or blocked) and (self.meter.Visible or not showingNotice) then
			local k = self.hudScale
			local at = self:toLayer(screen)
			local bounds, size = self:layerSize(), self.speech.AbsoluteSize / k
			local x = math.clamp(at.X, size.X / 2, math.max(size.X / 2, bounds.X - size.X / 2))
			local cursorBottom = at.Y + self.cursor.AbsoluteSize.Y / k / 2
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
	self.ribbonType.Text, self.ribbonName.Text = kind, name
	self.ribbonPaint.Color = ColorSequence.new(color:Lerp(W.white, 0.3), color:Lerp(W.navy, 0.35))
	self.ribbon.Visible = true
	local rest = UDim2.new(0.5, 0, 0, 132 * self.speechBase)
	self.ribbon.Position = rest
	if Burst.allowed(self.player) then
		Burst.drop(self.ribbon, rest)
		Burst.shine(self.ribbon, 17)
	end
	task.delay(4, function()
		if self.ribbonSerial == serial then
			self.ribbon.Visible = false
		end
	end)
end
-- One card per run of the same upgrade: buying Speed eight times quickly shows "Lv 20 → Lv 28" once.
function Hud:workshop(key, level)
	self.menu:upgraded(key)
	self.unlocks:upgrade(key, level, function(from, to)
		local headline = if key == "Power"
			then Upgrades.pickNames[to]
			elseif key == "Capacity" then "Bigger Backpack"
			else "Faster Swings"
		local detail = "Lv " .. from .. " → Lv " .. to .. "  ·  "
			.. (if key == "Power" then "Mines " .. Upgrades.unlockTexts(to)[math.min(2, #Upgrades.unlockTexts(to))] else Upgrades.describe(key, to))
		return headline, detail
	end)
end
-- A line in chat when anyone in the server finds Starfall.
function Hud:announceStarfall(who)
	local tint = Ores.byName.Starfall.color:Lerp(Color3.new(1, 1, 1), 0.3)
	self:chatLine("★ " .. who .. " unearthed Starfall!", "The rarest ore in the mine.", tint)
end
-- One system line in chat, the same for everyone: a bold coloured lead and plain words after it.
function Hud:chatLine(lead, rest, tint)
	local line = lead .. " " .. rest
	local chat = game:GetService("TextChatService")
	if chat.ChatVersion == Enum.ChatVersion.TextChatService then
		local channels = chat:FindFirstChild("TextChannels")
		local general = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChild("RBXSystem"))
		if general then
			pcall(general.DisplaySystemMessage, general,
				string.format('<font color="#%s"><b>%s</b></font> %s', tint:ToHex(), lead, rest))
		end
		return
	end
	-- The older chat takes its system lines through SetCore, once it has started.
	task.spawn(function()
		for _ = 1, 10 do
			local sent = pcall(StarterGui.SetCore, StarterGui, "ChatMakeSystemMessage",
				{ Text = line, Color = tint, Font = Enum.Font.FredokaOne, TextSize = 18 })
			if sent then return end
			task.wait(0.5)
		end
	end)
end
-- A message in the bottom middle that fades back to the guide after `hold` seconds (2.1 by default).
-- `detail` may hold several lines; the box grows upward to fit them.
function Hud:notice(title, detail, color, hold)
	hold = hold or 2.1
	self.untilTime = os.clock() + hold
	local _, breaks = string.gsub(detail or "", "\n", "")
	self:sizeNotice(breaks * (self.noticeLine or 17))
	local token = {}
	self.noticeToken = token
	if breaks > 0 then
		task.delay(hold, function()
			if self.noticeToken == token then self:sizeNotice(0) end
		end)
	end
	-- Notices can carry any text. Only the guide's own lines use colour tags.
	self.detail.RichText, self.message.RichText = false, false
	self.message.Text, self.message.TextColor3, self.detail.Text = title, color or W.white, detail or ""
	if self.overlay.Visible then
		self.menu.status.Text = title
	end
	self.speech.Visible = not self.overlay.Visible
	self.message.TextTransparency = 0.35
	W.tween(self.message, 0.16, { TextTransparency = 0 })
end
function Hud:sizeNotice(extra)
	if (self.noticeExtra or 0) == extra or not self.speechHeight then
		self.noticeExtra = extra
		return
	end
	self.noticeExtra = extra
	self.speech.Size = UDim2.fromOffset(self.speech.Size.X.Offset, self.speechHeight + extra)
	self.detail.Size = UDim2.fromOffset(self.detail.Size.X.Offset, self.detailHeight + extra)
end
-- Keeps the reason beside the cursor, or beside the aim dot without a mouse.
-- The HUD layer's size, and a screen (viewport) point in the layer's units. See hudScale.
function Hud:layerSize()
	return self.root.AbsoluteSize / self.hudScale
end
function Hud:toLayer(screen)
	return (screen + self.viewportOffset) / self.hudScale
end
function Hud:placeBlocked(screen)
	local bounds = self:layerSize()
	local half = self.blocked.AbsoluteSize / self.hudScale / 2
	local at = self:toLayer(screen)
	local width = math.min(half.X, 260 * self.speechBase)
	local below = at.Y + 26 + half.Y
	if below + half.Y * 0.7 > bounds.Y then below = at.Y - 26 - half.Y end
	self.blocked.Position = UDim2.fromOffset(math.clamp(at.X, width, math.max(width, bounds.X - width)), below)
end
-- Trying to mine what can't be mined: a short buzz, and the reason at the cursor grows and wiggles
-- where it is. The no-entry cursor shakes too. Throttled so holding the button doesn't spam it.
function Hud:cantMine(full)
	local now = os.clock()
	if now < (self.cantMineAt or 0) then
		return
	end
	self.cantMineAt, self.untilTime = now + 0.9, 0
	Audio.denied()
	if self.player:GetAttribute("MenuMotion") == false or GuiService.ReducedMotionEnabled then
		return
	end
	Burst.pop(self.blockedScale, self.speechBase, 1.6)
	local function shake(gui, scale)
		if not gui then
			return
		end
		task.spawn(function()
			if scale then
				scale.Scale = 1.3
				W.tween(scale, 0.45, { Scale = 1 })
			end
			for _, angle in { -16, 13, -9, 5, 0 } do
				W.tween(gui, 0.06, { Rotation = angle })
				task.wait(0.06)
			end
		end)
	end
	local badge = self.denied.Parent
	self.deniedScale = self.deniedScale or W.scale(badge)
	shake(badge, self.deniedScale)
	shake(self.blocked)
	if full then
		shake(self.haulTitle, self.haulPulse)
		shake(self.edgeCount, self.edgeCountPulse)
	end
end
-- `blocked` marks a reason the aimed block can't be mined. It is shown larger and in red.
function Hud:guide(title, detail, visible, blocked)
	if os.clock() < (self.untilTime or 0) then
		return
	end
	local was = self.blocked.Visible
	self.blocked.Visible = blocked == true
	if blocked then
		self.speech.Visible = false
		self.blocked.Text = string.format('<font size="42" color="#%s">%s</font>\n<font size="23">%s</font>', fullRed:ToHex(), title, detail)
		if not was and Burst.allowed(self.player) then Burst.pop(self.blockedScale, self.speechBase, 1.15) end
		return
	end
	-- Guide lines colour their gold amounts and progress counts (W.highlight).
	self.speech.Visible, self.detail.RichText, self.message.RichText = visible, true, true
	self.message.Text, self.message.TextColor3, self.detail.Text = W.highlight(title), W.white, W.highlight(detail)
end
-- The two reward tiles: a badge when something can be claimed, and the time to the next gift.
function Hud:refreshRewards()
	self.dailyBadge.Visible = self.menu:attention("Daily")
	local reborn = self.navDots.Rebirth.Visible
	SideButtons.setReady(self.rebirthTile, reborn, if reborn then "Ready!" else "Rebirth")
	SideButtons.setReady(self.dailyTile, self.dailyBadge.Visible, if self.dailyBadge.Visible then "Claim!" else "Daily")
	local ready, left = Field.giftState(self.player, workspace:GetServerTimeNow())
	self:setGiftReady(ready > 0, if ready > 0 then "Claim!" elseif left then W.clock(left) else "Gift", ready)
end
return Hud
