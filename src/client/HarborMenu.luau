local Shared = game:GetService("ReplicatedStorage").Shared
local Gui = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Upgrades, Expeditions, Ores = require(Shared.Upgrades), require(Shared.Expeditions), require(Shared.Ores)
local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
local Settings = require(script.Parent.Settings)
local SellCounter = require(script.Parent.SellCounter)
local GuideButton = require(script.Parent.GuideButton)
local Materials = require(Shared.Materials)
local StoreConfig, Bonuses = require(Shared.StoreConfig), require(Shared.Bonuses)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local FieldPages = require(script.Parent.FieldPages)
local Field = require(Shared.FieldRewards)
local RewardsPanel, IndexPanel = require(script.Parent.RewardsPanel), require(script.Parent.IndexPanel)
local RebirthPanel, ProfilePanel = require(script.Parent.RebirthPanel), require(script.Parent.ProfilePanel)
local ShopPanel, InventoryPanel = require(script.Parent.ShopPanel), require(script.Parent.InventoryPanel)
local Guide = require(Shared.FieldGuide)
local Purity = require(Shared.OrePurity)
local Skills = require(Shared.Skills)
local SkillMap = require(script.Parent.SkillMap)
local Burst = require(script.Parent.Burst)
local Menu = {}
Menu.__index = Menu
local rgb = Color3.fromRGB
local themes = {
	[W.aqua] = ColorSequence.new(rgb(134, 214, 255), rgb(47, 130, 230)),
	[W.gold] = ColorSequence.new(rgb(255, 226, 120), rgb(240, 150, 30)),
	[W.violet] = ColorSequence.new(rgb(207, 174, 255), rgb(129, 80, 230)),
	[W.green] = ColorSequence.new(rgb(166, 245, 154), rgb(52, 178, 74)),
	[W.orange] = ColorSequence.new(rgb(255, 208, 138), rgb(240, 138, 58)),
	[W.pink] = ColorSequence.new(rgb(255, 159, 200), rgb(227, 69, 138)),
}
local jobTabs = { "All", "Daily", "Quests", "Collected" }
local inventoryTabs = {}
Menu.pages = {
	Menu = { name = "Menu", color = W.aqua },
	Inventory = { name = "Inventory", color = W.gold },
	Items = { name = "Inventory", color = W.orange },
	MiningTrails = { name = "Mining FX", color = W.orange },
	PlayerFX = { name = "Player Effects", color = W.orange },
	Shop = { name = "Shop", color = W.pink },
	ShopGeodes = { name = "Crates", color = W.orange },
	ShopCrates = { name = "Crates", color = W.orange },
	ShopPasses = { name = "Game passes", color = W.gold },
	ShopBoosts = { name = "Boosts", color = W.green },
	ShopGold = { name = "Gold", color = W.gold },
	ShopPasses2 = { name = "Game passes", color = W.gold },
	ShopFeatured = { name = "Shop", color = W.pink },
	Kit = { name = "Supplies", color = W.aqua },
	Supplies = { name = "Field Supplies", color = W.gold },
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
	Pack = { name = "My backpack", color = W.gold },
	Rebirth = { name = "Rebirth", color = W.rebirth },
	Profile = { name = "Profile", color = W.aqua },
	Friends = { name = "Friends", color = W.green },
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
	W.enamelPanel(modal, rgb(58, 54, 104), rgb(34, 32, 66), 18)
	W.anchor(modal, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	self.scale = W.scale(modal)
	self.modal = modal
	local header = W.frame(modal, "Marquee", 7, 7, 466, 73, W.aqua, 12)
	self.header = header
	self.headerGradient = W.enamelPanel(header, W.white, W.aqua, 12)
	for i = 1, 3 do
		local stripe = W.frame(header, "Sunburst", 323 + i * 17, 10, 10, 52, W.white, 4)
		stripe.Rotation, stripe.BackgroundTransparency = 22, 0.76
	end
	self.iconWell = W.frame(header, "Badge", 12, 11, 50, 50, W.white, 12)
	W.stroke(self.iconWell, W.navy, 3)
	self.heading = W.title(header, "", 74, 2, 316, 42, 33, W.white, true)
	W.navyText(self.heading, 3)
	self.sub = W.text(header, "", 76, 42, 313, 24, 17, W.white, true)
	self.sub.Name = "Summary"
	W.navyText(self.sub, 1.8)
	W.largest(self.sub, 20, 13)
	-- What the miner can spend, wherever gold is spent or earned.
	local purse = W.frame(header, "Purse", 218, 11, 178, 51, W.navy, 25)
	purse.BackgroundTransparency, purse.Visible = 0.2, false
	self.purseCoin = Icons.draw(purse, "Coins", 10, 5, 40)
	self.purseScale = self.purseCoin:FindFirstChildOfClass("UIScale")
	self.purseScale:SetAttribute("Rest", self.purseScale.Scale)
	self.gold = W.title(purse, "0", 56, 1, 114, 49, 36, W.gold, true)
	W.navyText(self.gold, 3)
	self.purse = purse
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
	local footer = W.frame(modal, "Status", 11, 371, 458, 28, W.navy, 8)
	self.footer = footer
	self.status = W.text(footer, "", 8, 0, 442, 28, 15, W.white)
	W.largest(self.status, 21, 13)
	self.sellAll = W.button(footer, "Sell all", 242, 3, 210, 44, W.gold, "Sell entire pack", "Select")
	W.largest(self.sellAll, 19, 12)
	self.sellAll.Visible = false
	self.sellAll.Activated:Connect(function()
		if self.page == "Sell" and self.overlay.Visible and self.sellAll.Interactable then
			self.net.Action:FireServer("Sell")
		end
	end)
	local tabs = W.frame(modal, "Inventory tabs", 11, 85, 458, 32, W.navy, 8)
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
		local b = W.button(tabs, key, tabX, 2, width, 28, rgb(92, 86, 152), caption, "Select")
		tabX += width + 4
		self.tabButtons[key] = b
		b.Activated:Connect(function()
			self:open(key)
		end)
	end
	-- Shift jobs have their own tabs and one button that collects everything that is done.
	local kinds = W.frame(modal, "Job tabs", 11, 85, 458, 32, W.navy, 8)
	kinds.Visible = false
	self.jobBar, self.jobButtons, self.jobKind = kinds, {}, "All"
	for i, kind in jobTabs do
		local b = W.button(kinds, kind, 4 + (i - 1) * 114, 2, 110, 28, rgb(92, 86, 152), kind, "Select")
		self.jobButtons[kind] = b
		b.Activated:Connect(function()
			self.jobKind = kind
			self:arrangeJobs()
		end)
	end
	self.claimJobs = W.button(footer, "Claim all", 242, 3, 210, 44, W.gold, "Claim all", "Job")
	W.largest(self.claimJobs, 21, 12)
	self.claimJobs.Visible = false
	self.claimJobs.Activated:Connect(function()
		if self.page == "Jobs" and self.overlay.Visible and self.claimJobs.Interactable then
			self.net.Action:FireServer("JobAll")
		end
	end)
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
	local jobs = self.page == "Jobs"
	local selling = self.page == "Sell" or jobs
	local footerHeight = if selling then 50 else 34
	self.mainList.Position = UDim2.fromOffset(11, if jobs then 124 else 89)
	self.mainList.Size = UDim2.fromOffset(458, height - (if self.page == "Menu" then 99 elseif jobs then 142 + footerHeight else 107 + footerHeight))
	self.tabViewport.Size = UDim2.fromOffset(458, height - 170)
	self.footer.Size, self.footer.Position = UDim2.fromOffset(458, footerHeight), UDim2.fromOffset(11, height - footerHeight - 9)
	self.status.Size = UDim2.fromOffset(if selling then 226 else 442, footerHeight)
	self.sellAll.Visible, self.claimJobs.Visible, self.jobBar.Visible = selling and not jobs, jobs, jobs
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
	-- A phone held sideways: the big cards fit whole in the safe area, and the skill tree's map reaches
	-- every edge of the screen (behind Roblox's buttons and the notch) while its controls stay inside.
	-- `room` holds how far the full screen reaches past the safe area on each side.
	local room = nil
	if touch and width > height and height < 470 then
		local Gui = game:GetService("GuiService")
		local full = Gui:GetInsetArea(Enum.ScreenInsets.None)
		local core = Gui:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
		local bar = Gui:GetInsetArea(Enum.ScreenInsets.TopbarSafeInsets)
		-- `bar`: where the top bar's free space starts (after Roblox's menu and chat buttons), from the
		-- screen's left edge.
		room = { raise = math.max(0, core.Min.Y - full.Min.Y), left = math.max(0, core.Min.X - full.Min.X),
			right = math.max(0, full.Max.X - core.Max.X), bottom = math.max(0, full.Max.Y - core.Max.Y),
			bar = math.max(0, bar.Min.X - full.Min.X) }
	end
	self.room = room
	for _, panel in { self.rewards, self.index, self.rebirth, self.profile, self.shop, self.inventory } do
		panel.card:layout(Vector2.new(width, height), touch, room)
	end
	if self.map then self.map:fit(room) end
	-- A phone held sideways (or a short window). A tablet is tall enough for the full window.
	local shortLandscape = width > height and ((touch and height < 560) or height < 470)
	local maxScale = if shortLandscape then 1.1 else 1.76
	local minHeight = if shortLandscape then 340 else 408
	local scale = math.clamp(math.min((width - 18) / 480, (height - 18) / minHeight), 0.3, maxScale)
	if touch and not shortLandscape then
		-- A tablet: about the same share of the screen as the big cards (WideCard), never all of it.
		scale = math.clamp(math.min((width - 18) / 480, height * 0.72 / 408), 0.3, 1.35)
	end
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
	W.rowPanel(row, color)
	local plate = W.frame(row, "Badge", 9, 8, 46, 46, W.white, 10)
	W.gradient(plate, W.white, color, 90)
	W.stroke(plate, W.navy, 3)
	if icon then Icons.draw(plate, icon, 5, 5, 36, color) end
	local title = W.title(row, name, 67, 3, 249, 27, 21, W.white, true)
	W.navyText(title, 2.4)
	local detail = W.text(row, "", 67, 28, 249, 33, 18, W.white, true)
	if self.page ~= "Gear" then W.largest(detail, 19, 12) end
	W.outlineText(detail, 1)
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
	detail.Position, detail.Size = UDim2.fromOffset(67, 26), UDim2.fromOffset(251, 35)
end
function Menu:gear()
	local owned = Skills.read(self.player)
	self.gearButtons = {}
	local function describe(key, level)
		if key == "Capacity" then
			return W.number(Skills.capacity(Upgrades.items.Capacity.values[level], owned)) .. " block"
		elseif key == "Speed" then
			-- The pick's own speed, the same for everyone (passes, skills and rebirths come on top).
			return Upgrades.describe("Speed", level)
		end
		return Upgrades.describe(key, level)
	end
	for i, key in Upgrades.order do
		local item = Upgrades.items[key]
		local title, detail, b = self:row(i, item.label or key, key, item.color)
		self.gearButtons[key] = b
		detail.Name, detail.RichText = "Requirements", true
		detail:FindFirstChildOfClass("UIStroke"):Destroy()
		W.navyText(detail, 2.2)
		local row = title.Parent
		row.Position, row.Size = UDim2.fromOffset(1, 1 + (i - 1) * 91), UDim2.fromOffset(447, 85)
	row.Badge.Position = UDim2.fromOffset(10, 19)
		title.Size, title.TextSize = UDim2.fromOffset(250, 29), 23
		local benefit = W.text(row, "", 67, 30, 250, 20, 17, W.white, true)
		benefit.Name = "Benefit"
		W.largest(benefit, 17, 11)
		W.outlineText(benefit, 1)
		-- The price. Until there is enough gold, how much of it the miner has too.
		detail.Position, detail.Size, detail.Font = UDim2.fromOffset(67, 50), UDim2.fromOffset(250, 32), Enum.Font.FredokaOne
		detail.TextSize = 26
		b.Position, b.Size = UDim2.fromOffset(322, 19), UDim2.fromOffset(113, 48)
		b.TextWrapped = true
		b.TextSize = 19
		local short = false
		b.Activated:Connect(function()
			-- Short of gold: go and get some (the Shop's gold packs) instead.
			if short then
				self.hud:openPage("ShopGold")
				return
			end
			self.net.Action:FireServer("Buy", key)
		end)
		table.insert(self.updates, function()
			short = false
			local level = self.player:GetAttribute(key) or 1
			local price = Upgrades.price(key, level)
			local nextLevel = if price then level + 1 else level
			title.Text = if key == "Power" and price then Upgrades.pickNames[nextLevel]
				elseif key == "Capacity" and price then "Backpack  ·  Lv " .. nextLevel
				else (item.label or key) .. "  ·  Lv " .. level
			if key == "Power" then
				W.fitText(benefit, Upgrades.unlockTexts(nextLevel), "Mines ")
			else
				-- What the next level adds: Speed as how much faster, the Backpack as how many more slots.
				benefit.RichText = true
				if key == "Capacity" then
					local now, after = Skills.capacity(Upgrades.items.Capacity.values[level], owned), Skills.capacity(Upgrades.items.Capacity.values[nextLevel], owned)
					benefit.Text = if price then W.number(now) .. " → " .. W.number(after) .. " blocks  " .. W.colored("+" .. W.number(after - now), W.green)
						else W.number(after) .. " blocks"
				elseif key == "Speed" and price then
					-- Stone and, as a benchmark, a Starfall in the crater.
					local values = Upgrades.items.Speed.values
					benefit.Text = string.format("%.2f→%.2fs stone · %.0f→%.0fs Starfall  ", values[level], values[nextLevel],
						Upgrades.starfallSeconds(level), Upgrades.starfallSeconds(nextLevel))
						.. W.colored("+" .. Upgrades.speedGain(nextLevel) .. "%", W.green)
				else
					benefit.Text = describe(key, nextLevel)
				end
			end
			if not price then
				detail.Text = ""
				setButton(b, "Max level", W.muted, false)
				return
			end
			local gold = self.player:GetAttribute("Gold") or 0
			local ready = gold >= price
			detail.Text = if ready then W.colored(W.goldAmount(price) .. " G", W.green)
				else W.colored(W.goldAmount(gold), unmet) .. " / " .. W.colored(W.goldAmount(price) .. " G", W.gold)
			short = not ready
			-- Short of gold: how much is missing, on red. A tap still goes to the Shop's gold.
			setButton(b, if ready then "Upgrade" else "Need " .. W.goldAmount(price - gold) .. " G",
				if ready then W.green else Color3.fromRGB(225, 70, 80), true)
		end)
	end
	return #Upgrades.order
end
function Menu:jobs()
	self.jobRows, self.jobKind = {}, "All"
	local title, summary, deliver = self:row(1, "Daily supply order", "Jobs", W.aqua)
	self.jobRows[1] = { row = title.Parent, kind = "Daily" }
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
			.. (if self.player:GetAttribute("SkillSupplyRunner") then " G + 2 Gold Tonics" else " G + 1 Gold Tonic")
		setButton(deliver, if done then "Delivered" else "Deliver", if ready then W.green else W.muted, ready)
		self.jobRows[1].done, self.jobRows[1].ready = done, ready
	end)
	for i, job in Expeditions.jobs do
		local jobTitle, detail, b = self:row(i + 1, job.title, "Jobs", W.gold)
		local entry = { row = jobTitle.Parent, kind = "Quests" }
		local glow = W.stroke(entry.row, W.gold, 3)
		glow.Enabled = false
		self.jobRows[i + 1] = entry
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
			entry.done, entry.ready, entry.gold = claimed, ready, if ready then job.reward else 0
			glow.Enabled = ready
		end)
	end
	table.insert(self.updates, function()
		local count, total, changed = 0, 0, false
		for i, entry in self.jobRows do
			if entry.ready and entry.gold then
				count += 1
				total += entry.gold
			end
			-- Something was finished while the page is open.
			if entry.ready and not entry.wasReady then changed = true end
			entry.wasReady = entry.ready
		end
		local button = self.claimJobs
		button.RichText = true
		button.Text = if count > 0 then "Claim all  " .. W.colored("+" .. W.goldAmount(total) .. " G", W.gold) else "Claim all"
		button.TextSize = 19
		button.Interactable, button.BackgroundColor3 = count > 0, if count > 0 then W.green else W.muted
		self:arrangeJobs(changed)
	end)
	return #Expeditions.jobs + 1
end
-- Shows the jobs of the chosen tab. `toReady` scrolls to the first one that can be collected.
function Menu:arrangeJobs(toReady)
	if self.page ~= "Jobs" then return end
	for kind, b in self.jobButtons do
		b.BackgroundColor3 = if kind == self.jobKind then rgb(110, 214, 82) else rgb(92, 86, 152)
	end
	local y, first = 1, nil
	for _, entry in self.jobRows do
		local shown = if self.jobKind == "All" then true
			elseif self.jobKind == "Collected" then entry.done == true
			else entry.kind == self.jobKind and not entry.done
		entry.row.Visible = shown
		if shown then
			entry.row.Position = UDim2.fromOffset(1, y)
			y += 69
			if entry.ready and not first then first = entry.row end
		end
	end
	local canvas = UDim2.fromOffset(0, y)
	if self.mainList.CanvasSize ~= canvas then self.mainList.CanvasSize = canvas end
	local empty = self.mainList:FindFirstChild("No jobs")
	if not empty then
		empty = W.title(self.mainList, "", 0, 24, 447, 60, 22, W.white)
		empty.Name = "No jobs"
		W.navyText(empty, 2.4)
	end
	empty.Visible = y == 1
	empty.Text = if self.jobKind == "Collected" then "Nothing collected yet" else "All done here!"
	if toReady and first then
		local list = self.mainList
		local goal = Vector2.new(0, math.max(0, first.Position.Y.Offset - math.max(0, (list.Size.Y.Offset - 62) / 2)))
		-- After the page has its full length, so the scroll is not cut short.
		task.defer(function()
			if self.page ~= "Jobs" or not first.Parent then return end
			if self.preferences.values.MenuMotion then
				W.tween(list, 0.35, { CanvasPosition = goal })
			else
				list.CanvasPosition = goal
			end
		end)
	end
end
function Menu:supplies()
	for i, key in Materials.supplyOrder do
		local item = Materials.supplies[key]
		local _, detail, button = self:row(i, item.name, if key == "Flare" then "Crystal" else "Power", W.aqua)
		twoLines(detail)
		detail.RichText = true
		button.TextSize = 15
		button.Activated:Connect(function()
			self.net.Action:FireServer("Supply", key)
		end)
		table.insert(self.updates, function()
			local bag = held(self.player, item.recipe)
			local missing, count = Materials.missing(item.recipe, bag)
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
			local ready = not active and not missing
			setButton(
				button,
				if active then (if key == "Temper" then "Tempered" elseif key == "Compass" then "Owned" else "In use")
					elseif missing then string.format("Need %d %s", count, missing) else "Craft",
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
			local multiplier = Rebirth.saleMultiplier(self.player)
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
			and Field.dailyState(p:GetAttribute("StampCount"), p:GetAttribute("StampAt"), workspace:GetServerTimeNow()) ~= nil
	elseif key == "Playtime" then
		return Field.giftState(p, workspace:GetServerTimeNow()) > 0
	elseif key == "Book" then
		for _, ore in Ores.list do
			if p:GetAttribute("Found" .. ore.name) and not p:GetAttribute("SeenBook" .. ore.name) then
				return true
			end
		end
	elseif key == "Rebirth" then
		return Rebirth.ready(p:GetAttribute("RunStarfalls") or 0, p:GetAttribute("Rebirths") or 0)
	elseif key == "Shop" then
		-- VIP's chest is ready.
		local benefits = "," .. (p:GetAttribute("Passes") or "") .. ","
		return benefits:find(",VIP,", 1, true) ~= nil
			and (p:GetAttribute("VipChestAt") or 0) + StoreConfig.vipCrateHours * 3600 <= workspace:GetServerTimeNow()
	elseif key == "Inventory" then
		-- A crate waiting to be opened.
		local col = Bonuses.decode(p:GetAttribute("Collection")) or {}
		for id, n in col.items or {} do
			if id:match("Geode$") and n > 0 then return true end
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
-- A new unlock gets a red dot, like the Index. It counts as read once on screen for a moment, and
-- its dot stays until the page is opened again.
function Menu:watchRow(frame, id, unlocked)
	local dot = W.dot(frame, -16, 4)
	dot.Size, dot.Position = UDim2.fromOffset(14, 14), UDim2.new(1, -18, 0, 4)
	table.insert(self.seenRows, { frame = frame, id = id, unlocked = unlocked, dot = dot })
end
-- Opens a page scrolled to its first new unlock, if it has one.
function Menu:scrollToNew()
	for _, entry in self.seenRows do
		if entry.unlocked() and not self.player:GetAttribute("Seen" .. self.page .. entry.id) then
			local list = self.list
			-- Absolute sizes are on screen (scaled); the canvas position is in the list's own units.
			local scale = math.max(self.scale.Scale, 0.01)
			local y = (entry.frame.AbsolutePosition.Y - list.AbsolutePosition.Y) / scale + list.CanvasPosition.Y
			local most = math.max(0, (list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y) / scale)
			local goal = Vector2.new(0, math.clamp(y - 8, 0, most))
			if self.preferences.values.MenuMotion then
				W.tween(list, 0.35, { CanvasPosition = goal })
			else
				list.CanvasPosition = goal
			end
			return
		end
	end
end
function Menu:observeRows(now)
	local top = self.list.AbsolutePosition.Y
	local bottom = top + self.list.AbsoluteWindowSize.Y
	for _, entry in self.seenRows do
		if entry.sent or self.player:GetAttribute("Seen" .. self.page .. entry.id) or not entry.unlocked() then
			continue
		end
		entry.dot.Visible = true
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

local function shortcuts(self)
	local destinations = { "Shop", "Daily", "Playtime", "Inventory", "Skills", "Achievements", "Book", "Jobs", "Rebirth", "Profile", "Friends", "Settings", "Miners" }
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
		local caption = W.title(button, if page then page.name else "Server miners", 51, 0, 158, 68, 19, W.white, true)
		W.navyText(caption, 2.4)
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
	Kit = Menu.kit,
	Supplies = Menu.supplies,
	Achievements = FieldPages.achievements,
	Settings = function(self)
		return self.preferences:build(self)
	end,
	Jobs = Menu.jobs,
	Pack = Menu.pack,
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
	-- Older names for the pages the Shop and the Collection replaced.
	if key == "Kit" then
		key = "Items"
	elseif key == "Store" then
		key = "Shop"
	elseif key == "Passes" then
		key = "ShopPasses"
	elseif key == "Collection" then
		key = "Inventory"
	elseif key == "Trails" then
		key = "MiningTrails"
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
		self.map:fit(self.room)
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
	elseif key == "Rebirth" then
		self.rebirth = self.rebirth or RebirthPanel.new(self)
		wide = self.rebirth
	elseif key == "Profile" or key == "Friends" then
		self.profile = self.profile or ProfilePanel.new(self)
		wide = self.profile
	elseif key:match("^Shop") then
		self.shop = self.shop or ShopPanel.new(self)
		wide = self.shop
		-- For the Shop funnel (server/Analytics): a visit starts when the Shop opens, not on a tab change.
		if not (self.overlay.Visible and not self.closing and type(self.page) == "string" and self.page:match("^Shop")) then self.net.Action:FireServer("ShopOpened") end
	elseif key == "Inventory" or key == "Items" or key == "MiningTrails" or key == "PlayerFX" or key == "Titles" then
		self.inventory = self.inventory or InventoryPanel.new(self)
		wide = self.inventory
	end
	for _, panel in { self.rewards, self.index, self.rebirth, self.profile, self.shop, self.inventory } do
		if panel ~= wide then panel.card.modal.Visible = false end
	end
	self.modal.Visible = key ~= "Skills" and not wide
	self.overlay.Visible = true
	if key == "Skills" then
		self.page = key
		self.map.selected = nil
		-- The zoom and place stay as they were left, for this visit to the game only.
		if self.mapSeen then self.map:position() else self.map:home() end
		self.mapSeen = true
		self.map:refresh()
		return
	end
	if wide then
		local fresh = self.wide ~= wide
		self.page, self.wide = key, wide
		wide:open(key)
		wide.card:layout(self.overlay.AbsoluteSize, self.touchLayout, self.room)
		wide.card:enter(fresh and self.preferences.values.MenuMotion, self.arrival)
		if self.arrival and wide.welcome then wide:welcome() end
		self.arrival = nil
		self:refresh()
		return
	end
	self.wide = nil
	self.tabs.Visible, self.tabViewport.Visible, self.mainList.Visible = isTab, isTab, not isTab
	for k, b in self.tabButtons do
		b.BackgroundColor3 = if key == k then rgb(110, 214, 82) else rgb(92, 86, 152)
	end
	self.mainList:ClearAllChildren()
	if self.icon then
		self.icon:Destroy()
	end
	self.page, self.heading.Text = key, page.name
	self.headerGradient.Color = themes[page.color] or themes[W.aqua]
	self:sizeListings()
	self.icon =
		Icons.draw(self.iconWell, if key == "Kit" or key == "Supplies" then "Pack" else key, 5, 5, 40, page.color)
	self.status.Text = if key == "Menu" then ""
		elseif key == "Inventory" then "Select an unlocked title to wear it."
		elseif key == "Kit" then "Restock at Field Supplies beside the market."
		elseif key == "Supplies" then "Bring mined materials to craft your supplies."
		elseif key == "Gear" then "Spend gold to upgrade your equipment."
		elseif key == "Sell" then "Sell one ore, or everything."
		elseif key == "Achievements" then "Mine, explore and try new things. ??? reveals when you find the ore."
		elseif key == "Pack" then "Take your haul to the amber Sell counter."
		elseif key == "Jobs" then "Deliver today's order from here. A new one comes at midnight UTC."
		elseif key == "Settings" then "Changes take effect immediately."
		else "Upgrades stay equipped between visits."
	if isTab then
		self:showInventoryTab(key, switchingTabs and self.preferences.values.MenuMotion)
	else
		self.list = self.mainList
		local rows = builders[key](self)
		self.list.CanvasSize, self.list.CanvasPosition =
			UDim2.fromOffset(0, rows * (if key == "Menu" then 77 elseif key == "Gear" then 91 else 69)), Vector2.zero
		if #self.seenRows > 0 then
			task.delay(0.05, function()
				if self.page == key and self.overlay.Visible then self:scrollToNew() end
			end)
		end
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
-- A bought upgrade: its row flashes, its badge swells and paper flies from it.
function Menu:upgraded(key)
	local row = self.page == "Gear" and self.overlay.Visible and self.mainList:FindFirstChild(key)
	if not row or not Burst.allowed(self.player) then return end
	local flash = W.frame(row, "Flash", 0, 0, 0, 0, W.white, 10)
	flash.Size, flash.BackgroundTransparency, flash.ZIndex = UDim2.fromScale(1, 1), 0.15, 8
	W.tween(flash, 0.5, { BackgroundTransparency = 1 }).Completed:Once(function() flash:Destroy() end)
	local scale = row.Badge:FindFirstChildOfClass("UIScale") or W.scale(row.Badge)
	Burst.pop(scale, 1, 1.5)
	local at = row.Badge.AbsolutePosition + row.Badge.AbsoluteSize / 2 - self.overlay.AbsolutePosition
	Burst.confetti(self.overlay, at.X, at.Y, 16, { Upgrades.items[key].color, W.white, W.gold }, 0.7)
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
			local value = (self.player:GetAttribute("BagValue") or 0) * Rebirth.saleMultiplier(self.player)
			hint = "Sell all for " .. W.goldAmount(value) .. " G"
		elseif step == "Upgrade" or step == "Sell" then
			target = self.closeButton
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
	if hint and self.page == "Gear" then self.status.Text = hint end
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
	self.sub.Size = UDim2.fromOffset(if self.purse.Visible then 140 else 313, 26)
	self.heading.Position = UDim2.fromOffset(74, if self.page == "Gear" then 15 else 2)
	if self.page == "Menu" then
		self.sub.Text = ""
	elseif self.page == "Inventory" and not self.wide then
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
	elseif self.page == "Kit" or self.page == "Supplies" then
		self.sub.Text = string.format(
			"%d flares  ·  %d temper charges",
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
		local value = (p:GetAttribute("BagValue") or 0) * Rebirth.saleMultiplier(p)
		self.sub.Text = string.format("%d / %d blocks   ·   %s G", p:GetAttribute("Used") or 0, cap, W.number(value))
	elseif self.page == "Gear" then
		self.sub.Text = ""
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
