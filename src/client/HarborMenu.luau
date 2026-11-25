local Shared = game:GetService("ReplicatedStorage").Shared
local Market = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Gui = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Upgrades, Expeditions, Ores = require(Shared.Upgrades), require(Shared.Expeditions), require(Shared.Ores)
local Settings = require(script.Parent.Settings)
local SellCounter = require(script.Parent.SellCounter)
local GuideButton = require(script.Parent.GuideButton)
local Catalog = require(Shared.PassCatalog)
local Materials = require(Shared.Materials)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local FieldPages = require(script.Parent.FieldPages)
local Field = require(Shared.FieldRewards)
local RewardsPanel, IndexPanel = require(script.Parent.RewardsPanel), require(script.Parent.IndexPanel)
local Guide = require(Shared.FieldGuide)
local Purity = require(Shared.OrePurity)
local Skills = require(Shared.Skills)
local SkillMap = require(script.Parent.SkillMap)
local Menu = {}
Menu.__index = Menu
local rgb = Color3.fromRGB
local themes = {
	[W.aqua] = ColorSequence.new(rgb(27, 83, 135), rgb(19, 129, 132)),
	[W.gold] = ColorSequence.new(rgb(144, 64, 47), rgb(175, 107, 28)),
	[W.violet] = ColorSequence.new(rgb(66, 59, 137), rgb(140, 65, 131)),
	[W.green] = ColorSequence.new(rgb(39, 91, 76), rgb(14, 119, 127)),
	[W.orange] = ColorSequence.new(rgb(135, 57, 57), rgb(176, 97, 43)),
	[W.pink] = ColorSequence.new(rgb(111, 51, 119), rgb(169, 68, 96)),
}
local inventoryTabs = { "Inventory", "Pets", "Kit", "Passes" }
Menu.pages = {
	Menu = { name = "Menu", color = W.aqua },
	Inventory = { name = "Inventory", color = W.gold },
	Pets = { name = "Pets", color = W.violet },
	Kit = { name = "Supplies", color = W.aqua },
	Supplies = { name = "Field Supplies", color = W.gold },
	Passes = { name = "Game passes", color = W.violet },
	Skills = { name = "Skill tree", color = W.green },
	Achievements = { name = "Achievements", color = W.orange },
	Titles = { name = "Miner titles", color = W.gold },
	Settings = { name = "Settings", color = Color3.fromRGB(120, 185, 255) },
	Gear = { name = "Workshop", color = W.aqua },
	Sell = { name = "Sell ore", color = W.gold },
	Jobs = { name = "Shift jobs", color = W.violet },
	Book = { name = "Ore index", color = W.green },
	Daily = { name = "Daily rewards", color = W.pink },
	Playtime = { name = "Playtime gifts", color = W.violet },
	Store = { name = "Outfitters", color = W.pink },
	Pack = { name = "My backpack", color = W.gold },
}
function Menu.new(root, player, net, close)
	local self = setmetatable({ player = player, net = net, prices = {}, updates = {} }, Menu)
	self.preferences = Settings.new(player, net)
	self.guideButton = GuideButton.new()
	local shade = Instance.new("Frame")
	shade.Name, shade.Size, shade.BackgroundColor3, shade.BackgroundTransparency =
		"ShopOverlay", UDim2.fromScale(1, 1), W.ink, 0.25
	shade.Active, shade.Visible, shade.ZIndex, shade.Parent = true, false, 5, root
	shade.BackgroundTransparency = 1
	self.overlay = shade
	local modal = W.frame(shade, "Harbor menu", 0, 0, 480, 408, W.panel, 18)
	modal.Active = true
	W.stroke(modal, W.navy, 4)
	self.trim = W.enamel(modal, W.grape, W.panel)
	W.studs(modal, 18, 26, 0.4)
	W.anchor(modal, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	self.scale = W.scale(modal)
	self.modal = modal
	local header = W.frame(modal, "Marquee", 7, 7, 466, 73, W.aqua, 12)
	self.header = header
	self.headerGradient = W.enamel(header, W.ink, W.ocean)
	W.stroke(header, W.navy, 3)
	W.studs(header, 12)
	local headerRim = W.frame(header, "Rim", 2, 2, 462, 69, W.white, 10)
	headerRim.BackgroundTransparency = 1
	W.stroke(headerRim, W.white, 2).Transparency = 0.72
	for i = 1, 3 do
		local stripe = W.frame(header, "Sunburst", 323 + i * 17, 10, 10, 52, W.white, 4)
		stripe.Rotation, stripe.BackgroundTransparency = 22, 0.76
	end
	self.iconWell = W.frame(header, "Badge", 12, 11, 50, 50, W.white, 12)
	W.stroke(self.iconWell, W.ink, 2)
	self.heading = W.title(header, "", 74, 2, 316, 42, 33, W.white, true)
	W.navyText(self.heading, 3)
	self.sub = W.text(header, "", 76, 42, 313, 24, 17, W.white, true)
	self.sub.Name = "Summary"
	W.outlineText(self.sub, 1)
	self.sub.TextScaled = true
	-- What the miner can spend, wherever gold is spent or earned.
	local purse = W.frame(header, "Purse", 254, 37, 144, 31, W.navy, 15)
	purse.BackgroundTransparency, purse.Visible = 0.25, false
	Icons.draw(purse, "Coins", 6, 2, 27)
	self.gold = W.title(purse, "0", 36, 0, 102, 30, 22, W.gold, true)
	self.gold.TextScaled = true
	local goldFont = Instance.new("UITextSizeConstraint")
	goldFont.MinTextSize, goldFont.MaxTextSize, goldFont.Parent = 12, 22, self.gold
	self.purse = purse
	local summaryFont = Instance.new("UITextSizeConstraint")
	summaryFont.MinTextSize, summaryFont.MaxTextSize, summaryFont.Parent = 12, 17, self.sub
	local closeButton = W.closeButton(header, 404, 9, 55)
	self.closeButton = closeButton
	closeButton.Activated:Connect(close)
	local list = Instance.new("ScrollingFrame")
	list.Name, list.Position, list.Size = "Listings", UDim2.fromOffset(11, 89), UDim2.fromOffset(458, 273)
	list.BackgroundTransparency, list.BorderSizePixel, list.ScrollBarThickness, list.ScrollBarImageColor3 =
		1, 0, 5, W.muted
	list.ScrollingDirection, list.Parent = Enum.ScrollingDirection.Y, modal
	self.mainList, self.list = list, list
	local viewport = W.frame(modal, "Inventory pages", 11, 124, 458, 238, W.panel)
	viewport.BackgroundTransparency, viewport.ClipsDescendants, viewport.Visible = 1, true, false
	local pager = Instance.new("UIPageLayout")
	pager.FillDirection, pager.SortOrder = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder
	pager.EasingStyle, pager.EasingDirection, pager.TweenTime = Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0.22
	pager.TouchInputEnabled, pager.ScrollWheelInputEnabled, pager.GamepadInputEnabled = false, false, false
	pager.Animated, pager.Parent = false, viewport
	self.tabViewport, self.pager, self.tabLists = viewport, pager, {}
	local footer = W.frame(modal, "Status", 11, 371, 458, 28, W.ink, 8)
	self.footer = footer
	self.status = W.text(footer, "", 8, 0, 442, 28, 15, W.white)
	self.status.TextScaled = true
	local statusFont = Instance.new("UITextSizeConstraint")
	statusFont.MinTextSize, statusFont.MaxTextSize, statusFont.Parent = 15, 19, self.status
	self.sellAll = W.button(footer, "Sell all", 242, 3, 210, 44, W.gold, "Sell entire pack", "Select")
	self.sellAll.TextScaled = true
	local sellFont = Instance.new("UITextSizeConstraint")
	sellFont.MaxTextSize, sellFont.Parent = 20, self.sellAll
	self.sellAll.Visible = false
	self.sellAll.Activated:Connect(function()
		if self.page == "Sell" and self.overlay.Visible and self.sellAll.Interactable then
			self.net.Action:FireServer("Sell")
		end
	end)
	local tabs = W.frame(modal, "Inventory tabs", 11, 85, 458, 32, W.ink, 8)
	self.tabs = tabs
	self.tabButtons = {}
	local tabX = 4
	for i, key in inventoryTabs do
		local tabList = list:Clone()
		tabList.Name, tabList.LayoutOrder, tabList.Size = key, i, UDim2.fromScale(1, 1)
		tabList.Position, tabList.Parent = UDim2.fromScale(0, 0), viewport
		self.tabLists[key] = tabList
		local caption = if key == "Inventory" then "Titles" elseif key == "Kit" then "Supplies" else key
		local width = 110
		local b = W.button(tabs, key, tabX, 2, width, 28, Menu.pages[key].color, caption, "Select")
		tabX += width + 4
		self.tabButtons[key] = b
		b.Activated:Connect(function()
			self:open(key)
		end)
	end
	self.closeMap = close
	self.seenRows = {}
	game:GetService("RunService").Heartbeat:Connect(function()
		local now = os.clock()
		if shade.Visible and not self.wide and not self.closing and #self.seenRows > 0 and now >= (self.nextRead or 0) then
			self.nextRead = now + 0.12
			self:observeRows(now)
		end
	end)
	tabs.Visible = false
	return self
end
function Menu:sizeListings()
	local height = self.designHeight or 408
	local selling = self.page == "Sell"
	local footerHeight = if selling then 50 else 34
	self.mainList.Size = UDim2.fromOffset(458, height - (if self.page == "Menu" then 99 else 107 + footerHeight))
	self.tabViewport.Size = UDim2.fromOffset(458, height - 170)
	self.footer.Size, self.footer.Position = UDim2.fromOffset(458, footerHeight), UDim2.fromOffset(11, height - footerHeight - 9)
	self.status.Size, self.status.TextWrapped = UDim2.fromOffset(if selling then 226 else 442, footerHeight), selling
	self.sellAll.Visible = selling
end
local function revealRow(list, row)
	local top = row.Position.Y.Offset
	local bottom = top + row.Size.Y.Offset
	local viewHeight = list.Size.Y.Offset
	list.CanvasPosition = Vector2.new(0, math.clamp(list.CanvasPosition.Y, math.max(0, bottom + 3 - viewHeight), top))
end
function Menu:layout(width, height, touch)
	-- Give landscape phones larger type and touch targets by scrolling the rows
	-- inside the card. Keep the header, footer and close button within safe bounds.
	self.touchLayout = touch
	for _, panel in { self.rewards, self.index } do
		panel.card:layout(Vector2.new(width, height), touch)
	end
	local shortLandscape = width > height and (touch or height < 470)
	local maxScale = if shortLandscape then 1.38 else 1.76
	local minHeight = if shortLandscape then 270 else 408
	local scale = math.clamp(math.min((width - 18) / 480, (height - 18) / minHeight), 0.3, maxScale)
	local designHeight = if shortLandscape then math.clamp(math.floor((height - 18) / scale), minHeight, 408) else 408
	local resized = self.designHeight ~= designHeight
	self.scale.Scale = scale
	self.modal.Size = UDim2.fromOffset(480, designHeight)
	local closeSize = math.clamp(math.ceil(44 / scale), 48, 72)
	self.closeButton.Size = UDim2.fromOffset(closeSize, closeSize)
	self.closeButton.Position = UDim2.fromOffset(462 - closeSize, (73 - closeSize) / 2)
	self.designHeight = designHeight
	self:sizeListings()
	local guided = self.guideButton.button
	if resized and self.page == "Gear" and guided and guided.Parent.Parent == self.mainList then
		revealRow(self.mainList, guided.Parent)
	end
end
function Menu:row(i, name, icon, color)
	local row = W.frame(self.list, name, 1, 1 + (i - 1) * 69, 447, 62, W.card, 10)
	W.enamel(row, color:Lerp(W.panel, 0.76), W.panel)
	W.frame(row, "Color tab", 0, 12, 4, 38, color, 2)
	local plate = W.frame(row, "Badge", 9, 8, 46, 46, color, 9)
	W.stroke(plate, W.ink, 2)
	if icon then Icons.draw(plate, icon, 5, 5, 36, color) end
	local title = W.title(row, name, 67, 3, 249, 27, 21, W.white, true)
	W.outlineText(title, 1.1)
	-- Row details carry prices and recipes, so they fill their space (up to 18 pt, at least 15)
	-- instead of staying small inside a big card.
	local detail = W.text(row, "", 67, 28, 249, 33, 18, W.muted, true)
	detail.TextWrapped, detail.TextScaled = true, true
	local detailFont = Instance.new("UITextSizeConstraint")
	detailFont.MinTextSize, detailFont.MaxTextSize, detailFont.Parent = 15, 18, detail
	local cues = { Gear = "Buy", Jobs = "Job", Settings = "Select", Store = "Select" }
	local button = W.button(row, "Action", 322, 12, 113, 38, color, "", cues[self.page])
	return title, detail, button
end
local function setButton(button, caption, tint, enabled)
	button.Text, button.BackgroundColor3 = caption, tint
	button.Interactable, button.AutoButtonColor = enabled, enabled
end
local function held(player, recipe)
	local bag = {}
	for name in recipe do
		bag[name] = player:GetAttribute("Held" .. name) or 0
	end
	return bag
end
local unmet = Color3.fromRGB(255, 141, 137)
local function requirement(text, met)
	local tint = if met then W.green else unmet
	return W.colored((if met then "✓ " else "× ") .. text, tint)
end
local function ingredients(recipe, bag)
	local parts = {}
	for _, ore in Ores.list do
		local need = recipe[ore.name]
		if need then
			local count = bag[ore.name]
			table.insert(parts, requirement(string.format("%s %d/%d", ore.name, count, need), count >= need))
		end
	end
	return table.concat(parts, "   ")
end
local function twoLines(detail)
	detail.Position, detail.Size, detail.TextSize = UDim2.fromOffset(67, 26), UDim2.fromOffset(251, 35), 13
	detail.TextScaled = true
	local font = Instance.new("UITextSizeConstraint")
	font.MinTextSize, font.MaxTextSize, font.Parent = 9, 13, detail
end
function Menu:gear()
	local owned = Skills.read(self.player)
	self.gearButtons = {}
	local function describe(key, level)
		if key == "Capacity" then
			return W.number(Skills.capacity(Upgrades.items.Capacity.values[level], owned)) .. " ore"
		elseif key == "Speed" then
			local seconds = Skills.cutTime(Upgrades.items.Speed.values[level], Ores.byName.Stone, 1, 0, owned)
			return string.format("%.2fs / stone", seconds)
		end
		return Upgrades.describe(key, level)
	end
	for i, key in Upgrades.order do
		local item = Upgrades.items[key]
		local title, detail, b = self:row(i, item.label or key, key, item.color)
		self.gearButtons[key] = b
		detail.Name, detail.RichText = "Requirements", true
		W.outlineText(detail, 1)
		local row = title.Parent
		row.Position, row.Size = UDim2.fromOffset(1, 1 + (i - 1) * 91), UDim2.fromOffset(447, 85)
		row["Color tab"].Size, row.Badge.Position = UDim2.fromOffset(4, 61), UDim2.fromOffset(9, 19)
		title.Size, title.TextSize = UDim2.fromOffset(250, 29), 23
		local benefit = W.text(row, "", 67, 30, 250, 20, 16, W.aqua, true)
		benefit.Name = "Benefit"
		-- What the miner has, over what it costs. Always both, in type that can be read at a glance.
		detail.Position, detail.Size, detail.Font = UDim2.fromOffset(67, 50), UDim2.fromOffset(250, 32), Enum.Font.FredokaOne
		detail:FindFirstChildOfClass("UITextSizeConstraint"):Destroy()
		detail.TextScaled, detail.TextWrapped, detail.TextSize = false, false, 26
		b.Position, b.Size = UDim2.fromOffset(322, 19), UDim2.fromOffset(113, 48)
		b.TextWrapped = true
		b.TextSize = 19
		b.Activated:Connect(function()
			self.net.Action:FireServer("Buy", key)
		end)
		table.insert(self.updates, function()
			local level = self.player:GetAttribute(key) or 1
			local price = Upgrades.price(key, level)
			local nextLevel = if price then level + 1 else level
			title.Text = if key == "Power" and price then Upgrades.pickNames[nextLevel]
				elseif key == "Capacity" and price then "Backpack  ·  Lv " .. nextLevel
				else (item.label or key) .. "  ·  Lv " .. level
			if key == "Power" then
				W.fitText(benefit, Upgrades.unlockTexts(nextLevel), "Mines ")
			else
				benefit.Text = if key == "Capacity" then describe(key, nextLevel) .. " capacity"
					elseif price then describe(key, level) .. " → " .. describe(key, nextLevel)
					else describe(key, nextLevel)
			end
			if not price then
				detail.Text = ""
				setButton(b, "Max level", W.muted, false)
				return
			end
			local gold = self.player:GetAttribute("Gold") or 0
			local ready = gold >= price
			detail.Text = W.colored(W.goldAmount(gold), if ready then W.green else unmet) .. " / " .. W.colored(W.goldAmount(price) .. " G", W.gold)
			local caption = if ready then "Upgrade" else "Need " .. W.goldAmount(price - gold) .. " G"
			setButton(b, caption, if ready then W.green else unmet, ready)
		end)
	end
	return #Upgrades.order
end
function Menu:jobs()
	local title, summary, deliver = self:row(1, "Daily supply order", "Jobs", W.aqua)
	twoLines(summary)
	summary.RichText = true
	local shownDay
	deliver.Activated:Connect(function()
		self.net.Action:FireServer("Deliver", shownDay)
	end)
	table.insert(self.updates, function()
		shownDay = self.net:GetAttribute("OrderDay") or 0
		local order = Materials.daily(shownDay)
		local bag = held(self.player, order.recipe)
		local done = (self.player:GetAttribute("DailyClaim") or 0) >= shownDay
		local ready = not done and Materials.missing(order.recipe, bag) == nil
		title.Text = "Daily order · " .. order.name
		summary.Text = ingredients(order.recipe, bag)
			.. "\n"
			.. order.gold
			.. (if self.player:GetAttribute("SkillSupplyRunner") then " G + 2 gems + 2 flares" else " G + 2 gems + 1 flare")
		setButton(deliver, if done then "Delivered" else "Deliver", if ready then W.green else W.muted, ready)
	end)
	for i, job in Expeditions.jobs do
		local _, detail, b = self:row(i + 1, job.title, "Jobs", W.gold)
		b.Activated:Connect(function()
			self.net.Action:FireServer("Job", i)
		end)
		table.insert(self.updates, function()
			local mined = self.player:GetAttribute("Mined") or 0
			local claimed = Expeditions.jobClaimed(self.player:GetAttribute("ClaimedJobs") or 0, i)
			local ready = not claimed and mined >= job.goal
			detail.Text =
				string.format("Quest · %d/%d mined · +%s G", math.min(mined, job.goal), job.goal, W.number(job.reward))
			setButton(
				b,
				if claimed then "Collected" elseif ready then "Claim gold" else "In progress",
				if ready then W.green else W.muted,
				ready
			)
		end)
	end
	return #Expeditions.jobs + 1
end
function Menu:supplies()
	for i, key in Materials.supplyOrder do
		local item = Materials.supplies[key]
		local _, detail, button = self:row(i, item.name, if key == "Flare" then "Crystal" else "Power", W.aqua)
		twoLines(detail)
		detail.RichText = true
		button.TextSize = 13
		button.Activated:Connect(function()
			self.net.Action:FireServer("Supply", key)
		end)
		table.insert(self.updates, function()
			local bag = held(self.player, item.recipe)
			local missing, count = Materials.missing(item.recipe, bag)
			local gems = self.player:GetAttribute("Gems") or 0
			local gemCost = item.gems or 0
			local active = (key == "Temper" and (self.player:GetAttribute("TemperCharges") or 0) > 0)
				or (item.stock and (self.player:GetAttribute(item.stock) or 0) > 0)
				or (key == "Compass" and self.player:GetAttribute("OreCompass"))
			detail.Text = (
				if key == "Flare"
					then string.format(
						"%ds of light + cave direction",
						30 + Skills.bonus(Skills.read(self.player), "burn")
					)
					elseif key == "Temper" then string.format(
						"%d hard cuts · %d%% less time",
						Materials.temperCharges + Skills.bonus(Skills.read(self.player), "charges"),
						if self.player:GetAttribute("SkillHotSteel") then 30 else 20
					)
					else item.detail
			)
				.. "\n"
				.. ingredients(item.recipe, bag)
			if gemCost > 0 then
				detail.Text ..= "   " .. requirement(string.format("Gems %d/%d", gems, gemCost), gems >= gemCost)
			end
			local ready = not active and not missing and gems >= gemCost
			setButton(
				button,
				if active then (if key == "Temper" then "Tempered" elseif key == "Compass" then "Owned" else "In use")
					elseif missing then string.format("Need %d %s", count, missing)
					elseif gems < gemCost then string.format("Need %d gems", gemCost - gems) else "Craft",
				if ready then W.green else W.muted,
				ready
			)
		end)
	end
	return #Materials.supplyOrder
end
function Menu:kit()
	local _, flareDetail, use = self:row(1, "Survey flares", "Crystal", W.aqua)
	local _, temperDetail, charges = self:row(2, "Pickaxe temper", "Power", W.orange)
	use.Activated:Connect(function()
		self.net.Action:FireServer("Flare")
	end)
	table.insert(self.updates, function()
		local flares = self.player:GetAttribute("Flares") or 0
		local count = self.player:GetAttribute("TemperCharges") or 0
		flareDetail.Text = string.format(
			"%d packed · lights a tunnel for %ds",
			flares,
			30 + Skills.bonus(Skills.read(self.player), "burn")
		)
		temperDetail.Text = string.format(
			"%d%% less time on hardness 2+ blocks",
			if self.player:GetAttribute("SkillHotSteel") then 30 else 20
		)
		setButton(
			use,
			if flares > 0 then "Use in mine" else "Empty",
			if flares > 0 then W.green else W.muted,
			flares > 0
		)
		setButton(charges, count .. " charges", if count > 0 then W.orange else W.muted, false)
	end)
	return require(script.Parent.FieldRewardsPage).extraKit(self)
end
function Menu:pack()
	local rows = {}
	for i, ore in Ores.list do
		local title, detail, count = self:row(i, ore.name, "Crystal", ore.color)
		detail.RichText = true
		count.Interactable = false
		rows[ore.name] = { row = title.Parent, detail = detail, count = count }
	end
	local empty = W.text(self.list, "Your pack is empty", 0, 8, 447, 45, 18, W.muted)
	table.insert(self.updates, function()
		local held = Ores.carried(self.player)
		for _, item in rows do
			item.row.Visible = false
		end
		for i, entry in held do
			local item = rows[entry.ore.name]
			local multiplier = if self.player:GetAttribute("DoubleGold") then 2 else 1
			local grades = Purity.decode(self.player:GetAttribute("Grades" .. entry.ore.name))
			local low, high = Purity.range(grades)
			local value = Purity.quote(entry.ore, entry.amount, grades, entry.amount, self.player:GetAttribute("SkillBroker")) * multiplier
			item.row.Position, item.row.Visible = UDim2.fromOffset(1, 1 + (i - 1) * 69), true
			item.count.Text = "×" .. entry.amount
			local grade = if low then (if low == high then Purity.text(low) else Purity.text(low) .. "–" .. Purity.text(high)) .. " pure"
				else W.unitPrice(value / entry.amount)
			item.detail.Text = grade .. "  ·  " .. W.goldAmount(value) .. " G in pack"
		end
		empty.Visible = #held == 0
		self.list.CanvasSize = UDim2.fromOffset(0, #held * 69)
	end)
	return 0
end
function Menu:passes()
	for i, item in Catalog do
		local _, detail, b = self:row(i, item.name, item.icon, item.color)
		if item.key == "PrismTrail" then
			b.Activated:Connect(function()
				self.net.Action:FireServer(
					"Preference",
					"TrailEnabled",
					self.player:GetAttribute("TrailEnabled") ~= true
				)
			end)
		end
		table.insert(self.updates, function()
			local owned = self.player:GetAttribute(item.key) == true
			local toggle = owned and item.key == "PrismTrail"
			local enabled = self.player:GetAttribute("TrailEnabled") ~= false
			detail.Text = if not owned
				then "Available at Outfitters"
				elseif toggle then (if enabled then "Rainbow trail equipped" else "Rainbow trail hidden")
				else item.detail
			setButton(
				b,
				if toggle then (if enabled then "Disable" else "Enable") elseif owned then "Active" else "Unowned",
				if owned then item.color else W.muted,
				toggle
			)
		end)
	end
	return #Catalog
end

function Menu:attention(key)
	local p = self.player
	if key == "Skills" then
		if (p:GetAttribute("SkillPoints") or 0) < 1 then
			return false
		end
		local owned = Skills.read(p)
		for _, node in Guide.skills do
			if not owned[node.id] and Skills.ready(node, owned) then
				return true
			end
		end
	elseif key == "Jobs" then
		local day = self.net:GetAttribute("OrderDay") or 0
		local recipe = Materials.daily(day).recipe
		if (p:GetAttribute("DailyClaim") or 0) < day and not Materials.missing(recipe, held(p, recipe)) then
			return true
		end
		for i, job in Expeditions.jobs do
			if
				(p:GetAttribute("Mined") or 0) >= job.goal
				and not Expeditions.jobClaimed(p:GetAttribute("ClaimedJobs") or 0, i)
			then
				return true
			end
		end
	elseif key == "Daily" then
		return p:GetAttribute("ProfileReady") == true
			and Field.dailyState(p:GetAttribute("StampCount"), p:GetAttribute("StampDay"), self.net:GetAttribute("OrderDay")) ~= nil
	elseif key == "Playtime" then
		return Field.giftState(p, workspace:GetServerTimeNow()) > 0
	elseif key == "Book" then
		for _, ore in Ores.list do
			if p:GetAttribute("Found" .. ore.name) and not p:GetAttribute("SeenBook" .. ore.name) then
				return true
			end
		end
	elseif key == "Achievements" then
		for _, award in Guide.achievements do
			if
				(p:GetAttribute("Award" .. award.id) or 0) >= award.goal
				and not p:GetAttribute("SeenAchievements" .. award.id)
			then
				return true
			end
		end
	end
	return false
end
function Menu:watchRow(frame, id, unlocked)
	local border = W.stroke(frame, W.gold, 2)
	border.Enabled = false
	table.insert(self.seenRows, { frame = frame, id = id, unlocked = unlocked, border = border })
end
function Menu:observeRows(now)
	local top = self.list.AbsolutePosition.Y
	local bottom = top + self.list.AbsoluteWindowSize.Y
	for _, entry in self.seenRows do
		if entry.sent or self.player:GetAttribute("Seen" .. self.page .. entry.id) or not entry.unlocked() then
			continue
		end
		entry.border.Enabled = true
		local mid = entry.frame.AbsolutePosition.Y + entry.frame.AbsoluteSize.Y / 2
		if mid >= top and mid <= bottom then
			entry.since = entry.since or now
			if now - entry.since >= 0.35 then
				entry.sent = true
				self.net.Action:FireServer("Viewed", self.page, entry.id)
			end
		else
			entry.since = nil
		end
	end
end

function Menu:store()
	for i, item in Catalog do
		local _, detail, b = self:row(i, item.name, item.icon, item.color)
		detail.Text = item.detail
		local trial = item.id == 0 and RunService:IsStudio() and (game.GameId == 0 or self.player.UserId <= 0)
		b.Activated:Connect(function()
			if self.player:GetAttribute(item.key) then
				return
			end
			if trial then
				self.net.Action:FireServer("PreviewPass", item.key)
			elseif type(self.prices[item.key]) == "number" then
				self.net.Action:FireServer("Pass", item.key)
			end
		end)
		table.insert(self.updates, function()
			local owned, price = self.player:GetAttribute(item.key), self.prices[item.key]
			local sale = type(price) == "number"
			setButton(
				b,
				if owned
					then (if trial then "Trying now" else "Owned")
					elseif trial then "Try in Studio"
					elseif sale then "R$ " .. price
					elseif price == "loading" then "Loading…"
					else "Off sale",
				if owned then W.green elseif trial or sale then item.color else W.muted,
				not owned and (trial or sale)
			)
		end)
		if item.id > 0 and type(self.prices[item.key]) ~= "number" and self.prices[item.key] ~= "loading" then
			self.prices[item.key] = "loading"
			task.spawn(function()
				local ok, info = pcall(Market.GetProductInfoAsync, Market, item.id, Enum.InfoType.GamePass)
				self.prices[item.key] = if ok
						and info.IsForSale
						and type(info.PriceInRobux) == "number"
					then info.PriceInRobux
					else false
				if self.page == "Store" then
					self:refresh()
				end
			end)
		end
	end
	return #Catalog
end
local function shortcuts(self)
	local destinations = { "Daily", "Playtime", "Inventory", "Skills", "Achievements", "Book", "Jobs", "Settings", "Pets", "Miners" }
	for i, key in destinations do
		local page = Menu.pages[key]
		local color = if page then page.color else W.aqua
		local button = W.button(
			self.list,
			key,
			4 + ((i - 1) % 2) * 224,
			3 + math.floor((i - 1) / 2) * 77,
			214,
			71,
			color,
			"",
			"Select"
		)
		local dot = if key == "Skills" then W.pointBadge(button, -5, 4) else W.dot(button, -16, 4)
		table.insert(self.updates, function()
			dot.Visible = self:attention(key)
			if key == "Skills" then
				dot.Text = tostring(self.player:GetAttribute("SkillPoints") or 0)
			end
		end)
		local icon = if key == "Miners" then "Crew" elseif key == "Inventory" then "Pack" else key
		Icons.draw(button, icon, 9, 16, 38, color)
		local caption = W.title(button, if page then page.name else "Server miners", 51, 0, 158, 71, 17, W.ink, true)
		if key == "Jobs" then
			table.insert(self.updates, function()
				caption.Text = page.name
				for index, job in Expeditions.jobs do
					if
						(self.player:GetAttribute("Mined") or 0) >= job.goal
						and not Expeditions.jobClaimed(self.player:GetAttribute("ClaimedJobs") or 0, index)
					then
						caption.Text = "Claim " .. W.number(job.reward) .. " G"
						break
					end
				end
			end)
		end
		button.Activated:Connect(function()
			if key == "Miners" then
				self.showMiners()
			else
				self:open(key)
			end
		end)
	end
	return math.ceil(#destinations / 2)
end
local builders = {
	Menu = shortcuts,
	Gear = Menu.gear,
	Sell = SellCounter.build,
	Inventory = FieldPages.titles,
	Pets = FieldPages.pets,
	Kit = Menu.kit,
	Supplies = Menu.supplies,
	Passes = Menu.passes,
	Achievements = FieldPages.achievements,
	Settings = function(self)
		return self.preferences:build(self)
	end,
	Jobs = Menu.jobs,
	Pack = Menu.pack,
	Store = Menu.store,
}
function Menu:showInventoryTab(key, animate)
	if not self.tabUpdates then
		self.tabUpdates = {}
		for _, tabKey in inventoryTabs do
			self.list, self.updates = self.tabLists[tabKey], {}
			local rows = builders[tabKey](self)
			self.list.CanvasSize = UDim2.fromOffset(0, rows * 69)
			for _, update in self.updates do
				update()
			end
			self.tabUpdates[tabKey] = self.updates
		end
	end
	self.list, self.updates = self.tabLists[key], self.tabUpdates[key]
	self.pager.Animated = animate
	self.pager:JumpTo(self.list)
end
function Menu:open(key)
	if key == "Titles" then
		key = "Inventory"
	end
	local page = Menu.pages[key]
	if not page then
		return
	end
	local isTab = self.tabLists[key] ~= nil
	local switchingTabs = isTab and self.tabLists[self.page] ~= nil and self.overlay.Visible and not self.closing
	if switchingTabs and self.page == key then
		return
	end
	self.guideButton:point(nil)
	self.gearButtons = nil
	self.updates, self.seenRows = {}, {}
	if self.motion and not switchingTabs then
		self.motion:Cancel()
	end
	self.closing = false
	if key == "Skills" and not self.map then
		self.map = SkillMap.new(self.overlay, self.player, self.net, self.closeMap)
		self.map.screen:GetPropertyChangedSignal("Visible"):Connect(function()
			self.mapVisibilityChanged(self.map.screen.Visible)
		end)
	end
	if self.map then
		self.map.screen.Visible = key == "Skills"
	end
	local wide
	if key == "Daily" or key == "Playtime" then
		self.rewards = self.rewards or RewardsPanel.new(self)
		wide = self.rewards
	elseif key == "Book" then
		self.index = self.index or IndexPanel.new(self)
		wide = self.index
	end
	for _, panel in { self.rewards, self.index } do
		if panel ~= wide then panel.card.modal.Visible = false end
	end
	self.modal.Visible = key ~= "Skills" and not wide
	self.overlay.Visible = true
	if key == "Skills" then
		self.page = key
		self.map.selected = nil
		self.map:home()
		self.map:refresh()
		return
	end
	if wide then
		local fresh = self.wide ~= wide
		self.page, self.wide = key, wide
		wide:open(key)
		wide.card:layout(self.overlay.AbsoluteSize, self.touchLayout)
		wide.card:enter(fresh and self.preferences.values.MenuMotion)
		self:refresh()
		return
	end
	self.wide = nil
	self.tabs.Visible, self.tabViewport.Visible, self.mainList.Visible = isTab, isTab, not isTab
	for k, b in self.tabButtons do
		b.BackgroundColor3 = if key == k then W.white else Menu.pages[k].color
	end
	self.mainList:ClearAllChildren()
	if self.icon then
		self.icon:Destroy()
	end
	self.page, self.heading.Text = key, page.name
	self.headerGradient.Color = themes[page.color] or ColorSequence.new(rgb(55, 72, 143), rgb(37, 109, 153))
	self:sizeListings()
	self.trim.Color = ColorSequence.new(page.color:Lerp(W.panel, 0.46), W.panel)
	self.icon =
		Icons.draw(self.iconWell, if key == "Kit" or key == "Supplies" then "Pack" else key, 5, 5, 40, page.color)
	self.status.Text = if key == "Store"
			and RunService:IsStudio()
			and game.GameId == 0
		then "Studio trials last for this session."
		elseif key == "Menu" then ""
		elseif key == "Inventory" then "Select an unlocked title to wear it."
		elseif key == "Pets" then "Equip one companion at a time."
		elseif key == "Kit" then "Restock at Field Supplies beside the market."
		elseif key == "Supplies" then "Bring mined materials to craft your supplies."
		elseif key == "Gear" then "Spend gold to upgrade your equipment."
		elseif key == "Sell" then "Sell one ore type above, or sell your whole pack →"
		elseif key == "Passes" then "Visit Outfitters for game passes."
		elseif key == "Achievements" then "Mine, explore and try new things. ??? reveals when you find the ore."
		elseif key == "Pack" then "Take your haul to the amber Sell counter."
		elseif key == "Jobs" then "Deliver daily orders at the Jobs board. New order at midnight UTC."
		elseif key == "Settings" then "Changes take effect immediately."
		elseif key == "Store" then "Permanent passes for this experience."
		else "Upgrades stay equipped between visits."
	if isTab then
		self:showInventoryTab(key, switchingTabs and self.preferences.values.MenuMotion)
	else
		self.list = self.mainList
		local rows = builders[key](self)
		self.list.CanvasSize, self.list.CanvasPosition =
			UDim2.fromOffset(0, rows * (if key == "Menu" then 77 elseif key == "Gear" then 91 else 69)), Vector2.zero
	end
	self.footer.Visible = key ~= "Menu"
	local center = UDim2.fromScale(0.5, 0.5)
	if not switchingTabs then
		if self.preferences.values.MenuMotion then
			self.modal.Position = UDim2.new(0.5, 0, 0.5, 64 * self.scale.Scale)
			self.motion = W.tween(self.modal, 0.22, { Position = center })
		else
			self.modal.Position = center
		end
	end
	self:refresh()
end
function Menu:close()
	if not self.overlay.Visible or self.closing then
		return
	end
	self.guideButton:point(nil)
	if self.motion then
		self.motion:Cancel()
	end
	if self.page == "Skills" then
		self.map.screen.Visible = false
		self.overlay.Visible = false
		return
	end
	if self.wide then
		self.wide.card.modal.Visible = false
		self.wide, self.overlay.Visible = nil, false
		return
	end
	if not self.preferences.values.MenuMotion then
		self.overlay.Visible = false
		return
	end
	self.closing = true
	self.motion = W.tween(self.modal, 0.15, { Position = UDim2.new(0.5, 0, 0.5, 52 * self.scale.Scale) })
	self.motion.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed and self.closing then
			self.overlay.Visible = false
			self.closing = false
		end
	end)
end
function Menu:guideTrade()
	local step = self.player:GetAttribute("ExpeditionStep")
	local gold = self.player:GetAttribute("Gold") or 0
	local key, price = Upgrades.onboardingPick(gold)
	local item = if key == "Capacity" then "Backpack" else "Speed"
	local target, hint
	if self.page == "Sell" then
		local used = self.player:GetAttribute("Used") or 0
		local full = used >= (self.player:GetAttribute("PackSlots") or Upgrades.items.Capacity.values[1])
		local wantsSale = step == "Ore" or step == "Sell" or (step == "Upgrade" and (full or gold < price))
			or ((step == "Dig" or step == "Return") and full)
		if wantsSale and self.sellAll.Interactable then
			target = self.sellAll
			local value = (self.player:GetAttribute("BagValue") or 0) * (if self.player:GetAttribute("DoubleGold") then 2 else 1)
			hint = "Sell all for " .. W.goldAmount(value) .. " G"
		elseif step == "Upgrade" then
			target = self.closeButton
			hint = if gold >= price then "Visit the Upgrades stall" else "Mine for " .. W.goldAmount(price - gold) .. " more G"
		elseif step == "Sell" then
			target, hint = self.closeButton, "Your pack is empty. Mine a new haul"
		elseif step == "Return" or step == "Ore" or step == "Dig" then
			target, hint = self.closeButton, "Follow the marker back to the mine"
		end
	elseif self.page == "Gear" then
		if step == "Upgrade" then
			local purchase = self.gearButtons[key]
			if gold >= price and purchase.Interactable then
				target = purchase
				hint = if key == "Capacity" then "Buy Backpack to carry more" else "Buy Speed to mine faster"
				if self.guideButton.button ~= purchase then
					-- On short landscape phones the backpack row can start below the fold.
					revealRow(self.mainList, purchase.Parent)
				end
			elseif gold < price then
				target = self.closeButton
				hint = "Earn " .. W.goldAmount(price - gold) .. " more G for " .. item
			end
		elseif step == "Return" then
			target = self.closeButton
			hint = "Gear equipped! Try it in the mine"
		elseif step == "Sell" then
			target, hint = self.closeButton, "Take your first haul to Sell"
		end
	end
	if hint then self.sub.Text = hint end
	if target and target ~= self.guideButton.button and Input.PreferredInput == Enum.PreferredInput.Gamepad then
		Gui.SelectedObject = target
	end
	self.guideButton:point(target, self.preferences.values.MenuMotion)
end
function Menu:refresh()
	if not self.overlay.Visible then
		return
	end
	local p = self.player
	self.purse.Visible = self.page == "Gear" or self.page == "Sell"
	self.gold.Text = W.goldAmount(p:GetAttribute("Gold") or 0) .. " G"
	self.sub.Size = UDim2.fromOffset(if self.purse.Visible then 172 else 313, 24)
	if self.page == "Menu" then
		self.sub.Text = ""
	elseif self.page == "Inventory" then
		local xp = p:GetAttribute("MiningXP") or 0
		local level = Expeditions.level(xp)
		self.sub.Text = string.format(
			"Level %d    ·    %s / %s XP to level %d",
			level,
			W.number(xp - Expeditions.levelXP(level)),
			W.number(Expeditions.levelXP(level + 1) - Expeditions.levelXP(level)),
			level + 1
		)
	elseif self.page == "Skills" then
		self.map:refresh()
		return
	elseif self.wide then
		self.wide:refresh()
		return
	elseif self.page == "Pets" then
		self.sub.Text = if p:GetAttribute("Pet") == "Rock" or p:GetAttribute("Pet") == "Drake"
			then "Equipped   ·   " .. (p:GetAttribute("PetName") or "Pebble")
			else "Your companions"
	elseif self.page == "Kit" or self.page == "Supplies" then
		self.sub.Text = string.format(
			"%d gems  ·  %d flares  ·  %d temper charges",
			p:GetAttribute("Gems") or 0,
			p:GetAttribute("Flares") or 0,
			p:GetAttribute("TemperCharges") or 0
		)
	elseif self.page == "Achievements" then
		local earned = 0
		for _, award in Guide.achievements do
			if (p:GetAttribute("Award" .. award.id) or 0) >= award.goal then
				earned += 1
			end
		end
		self.sub.Text = string.format("%d / %d earned", earned, #Guide.achievements)
	elseif self.page == "Sell" then
		local used = p:GetAttribute("Used") or 0
		self.sub.Text = string.format("%s %s in pack", W.goldAmount(used), if used == 1 then "block" else "blocks")
	elseif self.page == "Pack" then
		local cap = p:GetAttribute("PackSlots") or Upgrades.items.Capacity.values[1]
		local value = (p:GetAttribute("BagValue") or 0) * (if p:GetAttribute("DoubleGold") then 2 else 1)
		self.sub.Text = string.format("%d / %d slots   ·   %s G", p:GetAttribute("Used") or 0, cap, W.number(value))
	elseif self.page == "Gear" then
		self.sub.Text = "Spend gold on gear"
	elseif self.page == "Jobs" then
		self.sub.Text = string.format("%d / %d quests collected", p:GetAttribute("Jobs") or 0, #Expeditions.jobs)
	elseif self.page == "Settings" then
		self.sub.Text = p:GetAttribute("SaveStatus") or "Sound and motion"
	else
		self.sub.Text = "Game passes"
	end
	for _, update in self.updates do
		update()
	end
	if not self.closing and (self.page == "Gear" or self.page == "Sell") then
		self:guideTrade()
	end
end
return Menu
