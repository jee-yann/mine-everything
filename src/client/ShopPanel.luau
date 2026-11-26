-- The Shop: Featured offers, Geodes (bought with gems, with their exact odds one tap away), game
-- passes, boosts and gem packs. Everything is decided by the server: buttons only ask. Paid geodes and
-- luck boosts are switched off where Roblox restricts paid random items for the player.
local Market = game:GetService("MarketplaceService")
local Run = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Geodes, S = require(Shared.Collectibles), require(Shared.Geodes), require(Shared.StoreConfig)
local Bonuses = require(Shared.Bonuses)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local Reveal = require(script.Parent.GeodeReveal)
local Panel = {}
Panel.__index = Panel
local rgb = Color3.fromRGB
local pink = { rgb(255, 159, 200), rgb(227, 69, 138) }
local tints = {
	Featured = pink,
	Geodes = { rgb(207, 174, 255), rgb(129, 80, 230) },
	Passes = { rgb(255, 230, 128), rgb(243, 165, 26) },
	Boosts = { rgb(166, 245, 154), rgb(52, 178, 74) },
	Gems = { rgb(134, 214, 255), rgb(47, 130, 230) },
}
local tabIcons = { Featured = "Shop", Geodes = "Geode", Passes = "Passes", Boosts = "Boosts", Gems = "Gems" }
local order = { "Featured", "Geodes", "Passes", "Boosts", "Gems" }
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
local grey = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local goldPaint = ColorSequence.new(rgb(255, 226, 120), rgb(240, 150, 30))
local violet = ColorSequence.new(rgb(207, 174, 255), rgb(129, 80, 230))
local practice = Run:IsStudio() and game.GameId == 0

local function box(parent, name, x, y, w, h, tint)
	local frame = W.frame(parent, name, x, y, w, h, W.white, 16)
	return frame, W.enamelPanel(frame, tint[1], tint[2], 16)
end
local function words(parent, value, x, y, w, h, size, color, left)
	local label = W.title(parent, value, x, y, w, h, size, color or W.white, left)
	label.ZIndex = 3
	W.navyText(label, math.max(2, size / 9))
	return label
end
local function press(parent, name, x, y, w, h, size)
	local button = W.clearButton(parent, name, x, y, w, h, "Select")
	W.round(button, 12)
	local paint = W.enamelPanel(button, rgb(150, 154, 176), rgb(98, 102, 128), 12)
	local label = words(button, "", 0, 0, w, h - 2, size)
	W.largest(label, size, 12)
	return button, paint, label
end
local function set(button, paint, label, text, color, enabled)
	label.Text, paint.Color = text, color
	button.Interactable, button.AutoButtonColor = enabled, enabled
end

function Panel.new(menu)
	local self = setmetatable({ menu = menu, player = menu.player, updates = {}, prices = {}, pages = {}, tabs = {} }, Panel)
	local card = Card.new(menu, "Shop", "Shop", "Shop", pink)
	self.card = card
	card:useTabs()
	for i, key in order do
		local b = W.clearButton(card.modal, key .. " tab", 14 + (i - 1) * 154, 88, 148, 46, "Select")
		W.round(b, 14)
		local paint = W.enamelPanel(b, Card.slate[1], Card.slate[2], 14)
		Icons.draw(b, tabIcons[key], 8, 7, 32)
		local label = W.title(b, key, 42, 0, 100, 44, 21, W.white, true)
		W.navyText(label, 2.4)
		W.largest(label, 21, 13)
		b.Activated:Connect(function() menu:open(if key == "Featured" then "Shop" else "Shop" .. key) end)
		self.tabs[key] = paint
		local page = W.frame(card.body, key, 7, 7, 764, 358, W.panel)
		page.BackgroundTransparency, page.Visible = 1, false
		self.pages[key] = page
	end
	self:buildFeatured()
	self:buildGeodes()
	self:buildPasses()
	self:buildBoosts()
	self:buildGems()
	self:buildOdds()
	return self
end

-- Robux price shown on a button: the live price once loaded, the configured one before.
function Panel:price(kind, item)
	if item.id > 0 and self.prices[item.key] == nil then
		self.prices[item.key] = false
		task.spawn(function()
			local ok, info = pcall(Market.GetProductInfoAsync, Market, item.id,
				if kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
			if ok and type(info.PriceInRobux) == "number" then
				self.prices[item.key] = info.PriceInRobux
				self:refresh()
			end
		end)
	end
	return "R$ " .. (if type(self.prices[item.key]) == "number" then self.prices[item.key] else item.price)
end

-- Whether a paid-random or luck item can be bought here: nil while Roblox's answer is pending.
function Panel:allowed()
	local restricted = self.player:GetAttribute("PaidRandomRestricted")
	if restricted == nil then return nil end
	return not restricted
end

function Panel:ownsPass(key)
	local owned = "," .. (self.player:GetAttribute("OwnedPasses") or "") .. ","
	local benefits = "," .. (self.player:GetAttribute("Passes") or "") .. ","
	return owned:find("," .. key .. ",", 1, true) ~= nil, benefits:find("," .. key .. ",", 1, true) ~= nil
end

-- A buy button for a pass or product, with its state kept current.
function Panel:buyButton(parent, kind, item, x, y, w, h)
	local button, paint, label = press(parent, item.key, x, y, w, h, 22)
	button.Activated:Connect(function()
		self.menu.net.Action:FireServer(if kind == "pass" then "BuyPass" else "BuyProduct", item.key)
	end)
	table.insert(self.updates, function()
		local unset = item.id <= 0
		if kind == "pass" then
			local owned, included = self:ownsPass(item.key)
			if owned or included then
				set(button, paint, label, if owned then "Owned ✓" else "Included ✓", green, false)
				return
			end
		elseif item.once and self.player:GetAttribute("StarterBought") then
			set(button, paint, label, "Claimed ✓", green, false)
			return
		end
		if item.luck and self:allowed() ~= true then
			set(button, paint, label, if self:allowed() == nil then "Checking…" else "Unavailable", grey, false)
			return
		end
		if unset and not practice then
			set(button, paint, label, "Coming soon", grey, false)
			return
		end
		set(button, paint, label, if unset then "Try free (Studio)" else self:price(kind, item), goldPaint, true)
	end)
	return button
end

-- A product or pass tile: icon, name, detail and its buy button.
function Panel:offer(parent, kind, item, x, y, w, h, tint, icon)
	local tile = box(parent, item.name, x, y, w, h, tint)
	local well = W.frame(tile, "Icon well", 10, 10, 64, 64, W.white, 14)
	well.BackgroundTransparency = 0.72
	Icons.draw(well, icon or item.icon or "Gems", 4, 4, 56)
	local title = words(tile, item.name, 84, 8, w - 94, 30, 23, nil, true)
	W.largest(title, 23, 14)
	local detail = words(tile, item.detail or "", 84, 38, w - 94, h - 96, 16, rgb(255, 250, 215), true)
	detail.TextWrapped, detail.TextYAlignment = true, Enum.TextYAlignment.Top
	W.largest(detail, 16, 11)
	self:buyButton(tile, kind, item, 12, h - 52, w - 24, 42)
	return tile, detail
end

function Panel:buildFeatured()
	local page = self.pages.Featured
	local starter = S.productByKey.StarterPack
	local hero, heroPaint = box(page, "Starter Pack", 0, 0, 470, 190, pink)
	self.starterHero = hero
	Card.rays(hero, 70, 80, 200, 8)
	Icons.draw(hero, "Gems", 16, 22, 100)
	words(hero, "Starter Pack", 128, 10, 330, 40, 34, nil, true)
	words(hero, "One time only", 130, 48, 200, 24, 18, rgb(255, 244, 170), true)
	local contents = words(hero, "60 gems  ·  3 survey flares\n30 min of 2× gold", 130, 74, 330, 56, 20, nil, true)
	contents.TextWrapped = true
	self:buyButton(hero, "product", starter, 130, 136, 210, 44)
	self.starterThanks = words(page, "", 0, 0, 470, 190, 26)
	self.starterThanks.TextWrapped = true
	local _ = heroPaint
	-- VIP chest, or the VIP offer.
	local vip, vipPaint = box(page, "VIP", 480, 0, 284, 190, { rgb(255, 230, 128), rgb(243, 165, 26) })
	Icons.draw(vip, "Achievements", 14, 14, 60)
	words(vip, "VIP", 84, 10, 190, 34, 30, nil, true)
	self.vipText = words(vip, "", 84, 46, 190, 70, 16, rgb(255, 250, 215), true)
	self.vipText.TextWrapped, self.vipText.TextYAlignment = true, Enum.TextYAlignment.Top
	local chest, chestPaint, chestLabel = press(vip, "VIP chest", 14, 136, 256, 44, 21)
	chest.Activated:Connect(function()
		local _, vipOwned = self:ownsPass("VIP")
		if vipOwned then
			self.menu.net.Action:FireServer("VipChest")
		else
			self.menu.net.Action:FireServer("BuyPass", "VIP")
		end
	end)
	local _2 = vipPaint
	table.insert(self.updates, function()
		local _, vipOwned = self:ownsPass("VIP")
		if vipOwned then
			local wait = (self.player:GetAttribute("VipChestAt") or 0) + S.vipChest.cooldown - workspace:GetServerTimeNow()
			self.vipText.Text = "Gold tag · +10% gold\nA free gem chest every 20 hours"
			if wait > 0 then
				set(chest, chestPaint, chestLabel, "Next chest " .. W.clock(wait), grey, false)
			else
				set(chest, chestPaint, chestLabel, "Open chest · +" .. S.vipChest.gems .. " gems", green, true)
			end
		else
			self.vipText.Text = S.passByKey.VIP.detail
			local item = S.passByKey.VIP
			set(chest, chestPaint, chestLabel, if item.id > 0 then self:price("pass", item) elseif practice then "Try free (Studio)" else "Coming soon", goldPaint, item.id > 0 or practice)
		end
	end)
	-- Three highlights.
	local picks = {
		{ "pass", S.passByKey.CelestialMiner, "Passes" },
		{ "pass", S.passByKey.StarfallDrake, "Pets" },
		{ "product", S.productByKey.ServerLuck, "Boosts" },
	}
	for i, pick in picks do
		self:offer(page, pick[1], pick[2], (i - 1) * 258, 200, 248, 158, tints[if i == 1 then "Passes" elseif i == 2 then "Geodes" else "Boosts"], pick[3])
	end
	table.insert(self.updates, function()
		local bought = self.player:GetAttribute("StarterBought") == true
		hero.Visible = not bought
		self.starterThanks.Text = if bought then "Thanks for supporting the cove!\nYour Starter Pack is claimed." else ""
	end)
end

function Panel:buildGeodes()
	local page = self.pages.Geodes
	self.geodeNote = words(page, "", 0, 0, 764, 26, 17, rgb(255, 244, 170))
	self.geodeNote.TextWrapped = true
	local shown = {}
	for _, geode in Geodes.list do
		if geode.price then table.insert(shown, geode) end
	end
	for i, geode in shown do
		local tint = { geode.color:Lerp(W.white, 0.25), geode.color:Lerp(rgb(40, 30, 70), 0.35) }
		local tile = box(page, geode.name, (i - 1) * 258, 30, 248, 328, tint)
		Card.rays(tile, 124, 76, 160, 7)
		Icons.draw(tile, "Geode", 69, 12, 110)
		words(tile, geode.name, 8, 124, 232, 32, 26)
		local blurb = words(tile, geode.blurb, 12, 156, 224, 40, 15, rgb(255, 250, 215))
		blurb.TextWrapped = true
		local extra = words(tile, "", 12, 196, 224, 22, 15, rgb(190, 255, 150))
		local open, openPaint, openLabel = press(tile, "Open", 12, 222, 224, 46, 22)
		open.Activated:Connect(function()
			local free = self:freeGeodes(geode.id) > 0
			self.menu.net.Action:FireServer("OpenGeode", geode.id, not free)
		end)
		local odds, oddsPaint, oddsLabel = press(tile, "Odds", 12, 274, 224, 42, 20)
		oddsPaint.Color, oddsLabel.Text = violet, "Odds & details"
		odds.Activated:Connect(function() self:showOdds(geode) end)
		table.insert(self.updates, function()
			local free = self:freeGeodes(geode.id)
			local gems = self.player:GetAttribute("Gems") or 0
			local allowed = self:allowed()
			if free > 0 then
				set(open, openPaint, openLabel, "Open free (" .. free .. ")", green, true)
			elseif allowed == nil then
				set(open, openPaint, openLabel, "Checking…", grey, false)
			elseif not allowed then
				set(open, openPaint, openLabel, "Unavailable here", grey, false)
			else
				set(open, openPaint, openLabel, "Open · " .. geode.price .. " gems", if gems >= geode.price then goldPaint else grey, gems >= geode.price)
			end
			if geode.pity then
				local count = self:pity(geode.id)
				extra.Text = if count >= geode.pity.after
					then "Next one is Legendary or better!"
					else string.format("Legendary+ guaranteed in %d", geode.pity.after + 1 - count)
			else
				extra.Text = ""
			end
		end)
	end
	table.insert(self.updates, function()
		local welcome = self:freeGeodes("Welcome")
		local allowed = self:allowed()
		self.geodeNote.Text = if welcome > 0 then "You have a Welcome Geode! Open it from Pets → Items."
			elseif allowed == false then "Buying geodes isn't available in your region. Free geodes still open, and the Forge crafts any reward."
			else string.format("You have %s gems. Earn more by mining, levelling up and daily rewards.", W.goldAmount(self.player:GetAttribute("Gems") or 0))
	end)
end

function Panel:collection()
	return Bonuses.decode(self.player:GetAttribute("Collection")) or {}
end
function Panel:freeGeodes(id)
	return (self:collection().items or {})[id .. "Geode"] or 0
end
function Panel:pity(id)
	return (self:collection().pity or {})[id] or 0
end

function Panel:buildPasses()
	local list = Card.scroller(self.pages.Passes, "Passes", 0, 0, 764, 358)
	for i, item in S.passes do
		local x, y = (i - 1) % 3 * 254, math.floor((i - 1) / 3) * 176
		self:offer(list, "pass", item, x, y, 246, 168, tints.Passes)
	end
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(#S.passes / 3) * 176)
end

function Panel:buildBoosts()
	local page = self.pages.Boosts
	self.boostNote = words(page, "", 0, 0, 764, 26, 17, rgb(190, 255, 150))
	self.boostNote.TextWrapped = true
	local list = Card.scroller(page, "Boosts", 0, 30, 764, 328)
	local i = 0
	for _, item in S.products do
		if item.group == "Boosts" then
			i += 1
			local x, y = (i - 1) % 3 * 254, math.floor((i - 1) / 3) * 166
			local _, detail = self:offer(list, "product", item, x, y, 246, 158, tints.Boosts, if item.boost == "compass" then "Rebirth" elseif item.key == "GoldCrate" or item.key == "SellAnywhere" then "Coins" else "Boosts")
			if item.boost or item.key == "ServerLuck" then
				table.insert(self.updates, function()
					local state = Bonuses.state(self.player)
					local left = if item.key == "ServerLuck" then math.max(0, state.serverLuckUntil - state.now) else Bonuses.left(state, item.boost)
					detail.Text = item.detail .. (if left > 0 then "\nActive · " .. W.clock(left) .. " left" else "")
				end)
			end
		end
	end
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(i / 3) * 166)
	table.insert(self.updates, function()
		local state = Bonuses.state(self.player)
		self.boostNote.Text = string.format("Luck now: %s×   ·   Gold: %s×   ·   Boosts stack up to 4 hours. Luck boosts use the strongest one.",
			string.format("%.2g", Bonuses.luck(state)), string.format("%.3g", Bonuses.gold(state)))
		if self:allowed() == false then
			self.boostNote.Text = "Luck boosts aren't available in your region. Gold boosts and Sell Anywhere are."
		end
	end)
end

function Panel:buildGems()
	local list = Card.scroller(self.pages.Gems, "Gems", 0, 0, 764, 358)
	local i = 0
	for _, item in S.products do
		if item.group == "Gems" then
			i += 1
			local x, y = (i - 1) % 3 * 254, math.floor((i - 1) / 3) * 176
			local tile = box(list, item.name, x, y, 246, 168, tints.Gems)
			Icons.draw(tile, "Gems", 12, 12, 70)
			words(tile, item.name, 90, 8, 146, 30, 22, nil, true)
			words(tile, W.goldAmount(item.gems) .. " gems", 90, 38, 146, 32, 28, rgb(190, 245, 255), true)
			local bonus = S.gemBonus(item)
			if bonus > 0 then
				local ribbon = W.frame(tile, "Bonus", 150, -10, 92, 30, rgb(255, 80, 120), 10)
				W.stroke(ribbon, W.navy, 3)
				words(ribbon, "+" .. bonus .. "% more", 0, 0, 92, 28, 17)
			end
			words(tile, string.format("%.2f gems per R$", item.gems / item.price), 90, 72, 146, 24, 14, rgb(255, 250, 215), true)
			self:buyButton(tile, "product", item, 12, 116, 222, 42)
		end
	end
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(i / 3) * 176)
end

-- The odds list: every reward, its rarity and its exact chance, the guarantee and the rules for
-- duplicates. Opened with "Odds & details" before buying.
function Panel:buildOdds()
	local sheet = W.frame(self.card.modal, "Odds sheet", 40, 80, 720, 420, W.white, 18)
	W.enamelPanel(sheet, rgb(72, 68, 124), rgb(38, 36, 74), 18)
	sheet.ZIndex, sheet.Visible = 20, false
	self.oddsSheet = sheet
	self.oddsTitle = words(sheet, "", 18, 8, 600, 40, 30, nil, true)
	local close = W.closeButton(sheet, 660, 8, 48)
	close.Activated:Connect(function() sheet.Visible = false end)
	self.oddsList = Card.scroller(sheet, "Rewards", 16, 54, 688, 206)
	self.oddsRules = words(sheet, "", 18, 268, 684, 146, 15, rgb(255, 250, 215), true)
	self.oddsRules.TextWrapped, self.oddsRules.TextYAlignment = true, Enum.TextYAlignment.Top
	for _, child in sheet:GetDescendants() do
		if child:IsA("GuiObject") then child.ZIndex += 20 end
	end
end

function Panel:showOdds(geode)
	local sheet, list = self.oddsSheet, self.oddsList
	sheet.Visible = true
	-- Fit inside the card, which is shorter on a phone held sideways; the reward list gives up room first.
	local height = math.clamp(self.card.modal.Size.Y.Offset - 90, 280, 420)
	sheet.Size = UDim2.fromOffset(720, height)
	list.Size = UDim2.fromOffset(688, height - 54 - 160)
	self.oddsRules.Position, self.oddsRules.Size = UDim2.fromOffset(18, height - 152), UDim2.fromOffset(684, 146)
	self.oddsGeode = geode
	list:ClearAllChildren()
	local pity = self:pity(geode.id)
	self.oddsPity = pity
	local rows = Geodes.odds(geode, pity)
	table.sort(rows, function(a, b) return a.percent > b.percent end)
	for i, row in rows do
		local entry = Geodes.entry(row.reward)
		local rarity = C.rarities[entry.rarity]
		local line = W.frame(list, entry.name, 0, (i - 1) * 34, 670, 30, if i % 2 == 0 then rgb(52, 49, 96) else W.navy, 8)
		local chip = W.frame(line, "Rarity", 8, 7, 16, 16, rarity.color, 8)
		W.stroke(chip, W.ink, 1.5)
		local kind = if row.reward.kind == "item" then "Item" elseif row.reward.kind == "pet" then "Pet" elseif row.reward.kind == "trail" then "Trail" else "Aura"
		words(line, entry.name .. (if (row.reward.count or 1) > 1 then " ×" .. row.reward.count else ""), 32, 0, 300, 30, 18, nil, true)
		words(line, kind .. " · " .. entry.rarity, 330, 0, 200, 30, 16, rarity.color:Lerp(W.white, 0.3), true)
		local percent = words(line, Geodes.percentText(row.percent), 540, 0, 120, 30, 19, W.gold)
		percent.TextXAlignment = Enum.TextXAlignment.Right
		for _, child in line:GetDescendants() do
			if child:IsA("GuiObject") then child.ZIndex = 23 end
		end
		line.ZIndex = 22
	end
	list.CanvasSize = UDim2.fromOffset(0, #rows * 34)
	local due = geode.pity and pity >= geode.pity.after
	self.oddsTitle.Text = geode.name .. (if due then " · guarantee active" else " · odds")
	local rules = {
		"These are the exact chances for your next " .. geode.name .. ". They add up to 100% (rounded to show).",
		"Duplicates: a pet you own gains a star (up to ★3, +20% bonus each), then becomes Geode Dust. A trail or aura you own becomes Geode Dust. Dust crafts rewards at the Forge.",
		"Luck boosts change ore in the mine, not geodes.",
	}
	if geode.pity then
		table.insert(rules, 2, string.format(
			"Guarantee: after %d %ss in a row with nothing Legendary or better, the next one is Legendary or better (the list above shows it when it's due). Yours: %d of %d.",
			geode.pity.after, geode.name, math.min(pity, geode.pity.after), geode.pity.after))
	end
	self.oddsRules.Text = table.concat(rules, "\n")
end

function Panel:open(key)
	local tab = key:match("^Shop(%a+)$") or "Featured"
	if not self.pages[tab] then tab = "Featured" end
	self.page = key
	self.tab = tab
	self.oddsSheet.Visible = false
	for name, page in self.pages do
		page.Visible = name == tab
		self.tabs[name].Color = if name == tab then ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
			else ColorSequence.new(Card.slate[1], Card.slate[2])
	end
	local card = self.card
	card:setIcon(tabIcons[tab])
	local tint = tints[tab]
	card.headerPaint.Color = ColorSequence.new(tint[1], tint[2])
	card.heading.Text = if tab == "Featured" then "Shop" else "Shop · " .. tab
	self:refresh()
end

function Panel:refresh()
	local gems = self.player:GetAttribute("Gems") or 0
	self.card.sub.Text = W.goldAmount(gems) .. " gems   ·   Geode Dust " .. W.goldAmount(self.player:GetAttribute("GeodeDust") or 0)
	for _, update in self.updates do
		update()
	end
	-- The odds change when the guarantee comes due: show them again then.
	local geode = self.oddsGeode
	if self.oddsSheet.Visible and geode and geode.pity and self:pity(geode.id) ~= self.oddsPity then self:showOdds(geode) end
end

-- Keeps timers moving while the card is open.
function Panel:tick()
	if self.card.modal.Visible then self:refresh() end
end

Panel.Reveal = Reveal
return Panel
