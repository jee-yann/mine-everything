-- The Shop: Featured offers (a limited pet, the Starter Pack, VIP), Crates (bought with gems, with
-- their exact odds one tap away), game passes, boosts and gem packs. Everything is decided by the
-- server: buttons only ask. Paid crates and luck boosts are switched off where Roblox restricts paid
-- random items for the player. When a crate costs more gems than the miner has, the Shop takes them
-- to the gem pack that covers it.
local Market = game:GetService("MarketplaceService")
local Run = game:GetService("RunService")
local Rep = game:GetService("ReplicatedStorage")
local Shared = Rep.Shared
local C, Geodes, S = require(Shared.Collectibles), require(Shared.Geodes), require(Shared.StoreConfig)
local Bonuses = require(Shared.Bonuses)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local Burst = require(script.Parent.Burst)
local Grid = require(script.Parent.CollectionGrid)
local Models = require(script.Parent.PetModels)
local TryOn = require(script.Parent.TryOn)
local Panel = {}
Panel.__index = Panel
local rgb = Color3.fromRGB
local pink = { rgb(255, 159, 200), rgb(227, 69, 138) }
local tints = {
	Featured = pink,
	Crates = { rgb(255, 214, 140), rgb(214, 128, 52) },
	Passes = { rgb(255, 230, 128), rgb(243, 165, 26) },
	Boosts = { rgb(166, 245, 154), rgb(52, 178, 74) },
	Gems = { rgb(134, 214, 255), rgb(47, 130, 230) },
}
local tabs = {
	{ "Featured", "Featured", "Shop" }, { "Crates", "Crates", "Geode" }, { "Passes", "Passes", "Passes" },
	{ "Boosts", "Boosts", "Boosts" }, { "Gems", "Gems", "Gems" },
}
local keys = { Featured = "Shop", Crates = "ShopCrates", Passes = "ShopPasses", Boosts = "ShopBoosts", Gems = "ShopGems" }
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
local grey = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local goldPaint = ColorSequence.new(rgb(255, 226, 120), rgb(240, 150, 30))
local violet = ColorSequence.new(rgb(207, 174, 255), rgb(129, 80, 230))
local aquaPaint = ColorSequence.new(rgb(134, 214, 255), rgb(47, 130, 230))
local words, press, set = Grid.words, Grid.press, Grid.set
local practice = Run:IsStudio() and game.GameId == 0

local function box(parent, name, x, y, w, h, tint)
	local frame = W.frame(parent, name, x, y, w, h, W.white, 16)
	return frame, W.enamelPanel(frame, tint[1], tint[2], 16)
end
-- A small tag in a tile's corner ("+21% more", "Best value").
local function ribbon(parent, text, x, y, w, color)
	local tag = W.frame(parent, "Ribbon", x, y, w, 28, color, 9)
	tag.ZIndex = 6
	W.stroke(tag, W.navy, 3)
	local label = words(tag, text, 0, 0, w, 26, 16)
	label.ZIndex = 7
	return tag
end

function Panel.new(menu)
	local self = setmetatable({ menu = menu, player = menu.player, net = menu.net, hud = menu.hud, updates = {}, prices = {}, pages = {}, tiles = {}, bobbers = {} }, Panel)
	local card = Card.new(menu, "Shop", "Shop", "Shop", pink)
	self.card = card
	self.paints = card:tabRow(tabs, function(key) menu:open(keys[key]) end)
	-- The gem purse: what the miner has, and a + that opens the gem packs.
	local purse = W.clearButton(card.header, "Gem purse", 540, 14, 180, 48, "Select")
	W.round(purse, 24)
	local purseFace = W.frame(purse, "Face", 0, 0, 180, 48, W.navy, 24)
	purseFace.BackgroundTransparency = 0.25
	Icons.draw(purse, "Gems", 6, 4, 40)
	self.gemLabel = words(purse, "0", 48, 0, 92, 46, 28, rgb(190, 245, 255), true)
	W.largest(self.gemLabel, 28, 14)
	local plus = W.frame(purse, "Plus", 140, 7, 34, 34, W.white, 17)
	W.enamelPanel(plus, rgb(166, 245, 110), rgb(62, 178, 52), 17)
	words(plus, "+", 0, -2, 34, 34, 28)
	purse.Activated:Connect(function() menu:open("ShopGems") end)
	card.heading.Size = UDim2.fromOffset(440, 44)
	card.sub.Size = UDim2.fromOffset(440, 24)
	for _, tab in tabs do
		local page = W.frame(card.body, tab[1], 7, 7, 764, 358, W.panel)
		page.BackgroundTransparency, page.Visible = 1, false
		self.pages[tab[1]] = page
		self.tiles[tab[1]] = {}
	end
	self:buildFeatured()
	self:buildCrates()
	self:buildPasses()
	self:buildBoosts()
	self:buildGems()
	self:buildOdds()
	-- Idle motion: crates and gems bob, the limited card's shine sweeps, its rays turn.
	Run.RenderStepped:Connect(function()
		if not card.modal.Visible then return end
		local t = os.clock()
		for i, bob in self.bobbers do
			if bob.Parent then bob.Position = UDim2.new(bob.Position.X, UDim.new(0, bob:GetAttribute("BaseY") + 5 * math.sin(t * 2.2 + i))) end
		end
		if self.shine and self.shine.Parent then
			local phase = (t * 0.45) % 1.6
			self.shine.Position = UDim2.new(phase - 0.3, 0, 0, -20)
		end
		if self.raysHolder then self.raysHolder.Rotation = (t * 6) % 360 end
		if self.griffin and self.griffin.Parent then
			self.griffin:PivotTo(CFrame.Angles(0, math.rad(-28) + 0.5 * math.sin(t * 0.7), 0) * CFrame.new(0, 0.12 * math.sin(t * 2), 0))
		end
	end)
	return self
end

function Panel:collection()
	return Bonuses.decode(self.player:GetAttribute("Collection")) or {}
end
function Panel:freeCrates(id)
	return (self:collection().items or {})[id .. "Geode"] or 0
end
function Panel:pity(id)
	return (self:collection().pity or {})[id] or 0
end
function Panel:gems()
	return self.player:GetAttribute("Gems") or 0
end

-- Robux price for a button: the live price once loaded, the configured one before.
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
	return if type(self.prices[item.key]) == "number" then self.prices[item.key] else item.price
end

-- Whether paid random items and luck can be bought here: nil while Roblox's answer is pending.
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

-- A buy button for a pass or product, showing its Robux price and kept current.
function Panel:buyButton(parent, kind, item, x, y, w, h)
	local button, paint, label = press(parent, item.key, x, y, w, h, 22)
	button.Activated:Connect(function()
		self.net.Action:FireServer(if kind == "pass" then "BuyPass" else "BuyProduct", item.key)
	end)
	table.insert(self.updates, function()
		if kind == "pass" then
			local owned, included = self:ownsPass(item.key)
			if owned or included then
				set(button, paint, label, if owned then "Owned ✓" else "Included ✓", green, false)
				return
			end
		elseif item.limited and ((self:collection().pets or {})[item.pet] ~= nil) then
			set(button, paint, label, "Owned ✓", green, false)
			return
		elseif item.once and not item.limited and self.player:GetAttribute("StarterBought") then
			set(button, paint, label, "Claimed ✓", green, false)
			return
		end
		if item.limited and (Rep:GetAttribute("Limited" .. item.key) or item.limited) <= 0 then
			set(button, paint, label, "Sold out", grey, false)
			return
		end
		if item.luck and self:allowed() ~= true then
			set(button, paint, label, if self:allowed() == nil then "Checking…" else "Unavailable", grey, false)
			return
		end
		local canBuy = item.id > 0 or practice
		set(button, paint, label, "R$ " .. W.goldAmount(self:price(kind, item)), if canBuy then goldPaint else grey, canBuy)
	end)
	return button
end

-- A product or pass tile: icon, name, detail and its buy button.
function Panel:offer(parent, tab, kind, item, x, y, w, h, tint, icon)
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
	table.insert(self.tiles[tab], tile)
	return tile, detail
end

function Panel:buildFeatured()
	local page = self.pages.Featured
	-- Limited: a pet only the first 1,000 buyers get.
	local limited = S.productByKey.FounderGriffin
	local hero = box(page, "Limited", 0, 0, 372, 222, { rgb(255, 200, 120), rgb(214, 96, 40) })
	hero.ClipsDescendants = true
	table.insert(self.tiles.Featured, hero)
	local rays = W.frame(hero, "Spin", 76, 86, 0, 0, W.white)
	rays.BackgroundTransparency = 1
	Burst.rays(rays, 0, 0, 220, 10, W.white, 0.82)
	self.raysHolder = rays
	local view = Instance.new("ViewportFrame")
	view.Name, view.BackgroundTransparency, view.ZIndex = "Griffin", 1, 3
	view.Position, view.Size = UDim2.fromOffset(4, 30), UDim2.fromOffset(150, 130)
	view.Parent = hero
	self.griffin = Models.preview(view, "Griffin")
	ribbon(hero, "LIMITED", 12, 10, 104, rgb(255, 70, 90))
	words(hero, limited.name, 152, 12, 210, 34, 27, nil, true)
	local detail = words(hero, "Only 1,000 will ever exist. When they're gone, they're gone.", 154, 48, 206, 48, 15, rgb(255, 250, 215), true)
	detail.TextWrapped = true
	local track = W.frame(hero, "Stock", 154, 104, 206, 20, W.navy, 10)
	W.stroke(track, W.navy, 3)
	local fill = W.frame(track, "Fill", 0, 0, 0, 20, W.white, 10)
	W.gradient(fill, rgb(255, 230, 120), rgb(255, 120, 60), 0)
	local stock = words(track, "", 0, 0, 206, 20, 13)
	stock.ZIndex = 5
	self:buyButton(hero, "product", limited, 154, 168, 206, 44)
	local shine = W.frame(hero, "Shine", 0, -20, 60, 280, W.white)
	shine.Rotation, shine.BackgroundTransparency, shine.ZIndex = 20, 0.78, 8
	self.shine = shine
	table.insert(self.updates, function()
		local left = Rep:GetAttribute("Limited" .. limited.key) or limited.limited
		fill.Size = UDim2.new(math.clamp(left / limited.limited, 0, 1), 0, 1, 0)
		stock.Text = W.goldAmount(left) .. " / " .. W.goldAmount(limited.limited) .. " left"
	end)
	-- Starter Pack, once.
	local starter = S.productByKey.StarterPack
	local pack = box(page, "Starter Pack", 382, 0, 382, 106, pink)
	table.insert(self.tiles.Featured, pack)
	Icons.draw(pack, "Gems", 10, 14, 76)
	words(pack, "Starter Pack", 92, 6, 180, 30, 24, nil, true)
	ribbon(pack, "ONCE", 290, 8, 80, rgb(255, 70, 90))
	local contents = words(pack, "60 gems · 3 flares · 30 min 2× gold", 94, 36, 280, 22, 15, rgb(255, 250, 215), true)
	W.largest(contents, 15, 11)
	self:buyButton(pack, "product", starter, 94, 60, 276, 38)
	-- VIP: the daily chest when owned, the pass otherwise.
	local vip = box(page, "VIP", 382, 116, 382, 106, tints.Passes)
	table.insert(self.tiles.Featured, vip)
	Icons.draw(vip, "Achievements", 10, 14, 76)
	words(vip, "VIP", 92, 6, 180, 30, 26, nil, true)
	self.vipText = words(vip, "", 94, 36, 280, 22, 15, rgb(255, 250, 215), true)
	W.largest(self.vipText, 15, 11)
	local chest, chestPaint, chestLabel = press(vip, "VIP chest", 94, 60, 276, 38, 20)
	chest.Activated:Connect(function()
		local _, owned = self:ownsPass("VIP")
		if owned then
			self.net.Action:FireServer("VipChest")
		else
			self.net.Action:FireServer("BuyPass", "VIP")
		end
	end)
	table.insert(self.updates, function()
		local _, owned = self:ownsPass("VIP")
		if owned then
			local wait = (self.player:GetAttribute("VipChestAt") or 0) + S.vipChest.cooldown - workspace:GetServerTimeNow()
			self.vipText.Text = "Gold tag · +10% gold · a gem chest every 20 hours"
			if wait > 0 then
				set(chest, chestPaint, chestLabel, "Next chest in " .. W.clock(wait), grey, false)
			else
				set(chest, chestPaint, chestLabel, "Open chest · +" .. S.vipChest.gems .. " gems", green, true)
			end
		else
			self.vipText.Text = "Gold tag, +10% gold and a free gem chest daily"
			set(chest, chestPaint, chestLabel, "R$ " .. self:price("pass", S.passByKey.VIP), goldPaint, S.passByKey.VIP.id > 0 or practice)
		end
		pack.Visible = not self.player:GetAttribute("StarterBought")
		local rest = UDim2.fromOffset(382, if pack.Visible then 116 else 0)
		vip:SetAttribute("Rest", rest)
		vip.Position = rest
	end)
	-- Three highlights.
	local picks = {
		{ "pass", S.passByKey.CelestialMiner, "Passes", tints.Passes },
		{ "pass", S.passByKey.StarfallDrake, "Pets", { rgb(207, 174, 255), rgb(129, 80, 230) } },
		{ "product", S.productByKey.ServerLuck, "Friends", tints.Boosts },
	}
	for i, pick in picks do
		self:offer(page, "Featured", pick[1], pick[2], (i - 1) * 258, 230, 248, 128, pick[4], pick[3])
	end
end

-- Shows the gem packs with the one that covers `need` more gems glowing.
function Panel:needGems(need, what)
	self.menu:open("ShopGems")
	local best
	for _, item in S.products do
		if item.group == "Gems" and item.gems >= need and (not best or item.gems < best.gems) then best = item end
	end
	self.gemNote.Text = string.format("You need %s more gems for %s. This pack covers it:", W.goldAmount(need), what)
	self.gemNote.TextColor3 = rgb(255, 230, 140)
	for key, glow in self.gemGlows do
		glow.Enabled = best ~= nil and key == best.key
	end
end

function Panel:buildCrates()
	local page = self.pages.Crates
	self.crateNote = words(page, "", 0, 0, 764, 26, 17, rgb(255, 244, 170))
	self.crateNote.TextWrapped = true
	local shown = {}
	for _, geode in Geodes.list do
		if geode.price then table.insert(shown, geode) end
	end
	for i, geode in shown do
		local tint = { geode.color:Lerp(W.white, 0.3), geode.color:Lerp(rgb(40, 30, 70), 0.35) }
		local tile = box(page, geode.name, (i - 1) * 258, 30, 248, 328, tint)
		table.insert(self.tiles.Crates, tile)
		Card.rays(tile, 124, 76, 160, 7)
		local art = W.frame(tile, "Crate", 69, 12, 110, 110, W.ink)
		art.BackgroundTransparency = 1
		art:SetAttribute("BaseY", 12)
		Icons.draw(art, "Geode", 0, 0, 110)
		table.insert(self.bobbers, art)
		words(tile, geode.name, 8, 124, 232, 32, 26)
		local blurb = words(tile, geode.blurb, 12, 156, 224, 40, 15, rgb(255, 250, 215))
		blurb.TextWrapped = true
		local extra = words(tile, "", 12, 196, 224, 22, 15, rgb(190, 255, 150))
		local open, openPaint, openLabel = press(tile, "Open", 12, 222, 224, 46, 22)
		open.Activated:Connect(function()
			if self:freeCrates(geode.id) > 0 then
				self.net.Action:FireServer("OpenGeode", geode.id, false)
			elseif self:gems() < geode.price then
				self:needGems(geode.price - self:gems(), "a " .. geode.name)
			else
				self.net.Action:FireServer("OpenGeode", geode.id, true)
			end
		end)
		local odds, oddsPaint, oddsLabel = press(tile, "Odds", 12, 274, 224, 42, 20)
		oddsPaint.Color, oddsLabel.Text = violet, "Odds & preview"
		odds.Activated:Connect(function() self:showOdds(geode) end)
		table.insert(self.updates, function()
			local free = self:freeCrates(geode.id)
			local gems = self:gems()
			local allowed = self:allowed()
			if free > 0 then
				set(open, openPaint, openLabel, "Open free (" .. free .. ")", green, true)
			elseif allowed == nil then
				set(open, openPaint, openLabel, "Checking…", grey, false)
			elseif not allowed then
				set(open, openPaint, openLabel, "Unavailable here", grey, false)
			elseif gems >= geode.price then
				set(open, openPaint, openLabel, "Open · " .. geode.price .. " gems", goldPaint, true)
			else
				set(open, openPaint, openLabel, "Get " .. (geode.price - gems) .. " more gems", aquaPaint, true)
			end
			if geode.pity then
				local count = self:pity(geode.id)
				extra.Text = if count >= geode.pity.after then "Next one is Legendary or better!"
					else string.format("Legendary+ guaranteed in %d", geode.pity.after + 1 - count)
			else
				extra.Text = ""
			end
		end)
	end
	table.insert(self.updates, function()
		local allowed = self:allowed()
		self.crateNote.Text = if self:freeCrates("Welcome") > 0 then "You have a Welcome Crate! Open it from your Inventory."
			elseif allowed == false then "Buying crates isn't available in your region. Free crates still open, and the Forge crafts any reward."
			else "Pets and cosmetics are just for looks. Duplicates turn into Crate Dust for the Forge."
	end)
end

function Panel:buildPasses()
	local list = Card.scroller(self.pages.Passes, "Passes", 0, 0, 764, 358)
	for i, item in S.passes do
		local x, y = (i - 1) % 3 * 254, math.floor((i - 1) / 3) * 176
		self:offer(list, "Passes", "pass", item, x, y, 246, 168, tints.Passes)
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
			local icon = if item.key == "GoldCrate" or item.key == "SellAnywhere" then "Coins" elseif item.key == "ServerLuck" then "Friends" else "Boosts"
			local _, detail = self:offer(list, "Boosts", "product", item, x, y, 246, 158, tints.Boosts, icon)
			table.insert(self.updates, function()
				local state = Bonuses.state(self.player)
				if item.key == "GoldCrate" then
					-- The amount follows the miner's own progress: their depth, gear and rebirths.
					detail.Text = string.format("%s gold right now. It grows as you dig deeper and upgrade.",
						W.goldAmount(self.player:GetAttribute("GoldBundle") or 0))
					return
				end
				local left = if item.key == "ServerLuck" then math.max(0, state.serverLuckUntil - state.now)
					elseif item.boost then Bonuses.left(state, item.boost) else 0
				detail.Text = item.detail .. (if left > 0 then "\nActive · " .. W.clock(left) .. " left" else "")
			end)
		end
	end
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(i / 3) * 166)
	table.insert(self.updates, function()
		local state = Bonuses.state(self.player)
		self.boostNote.Text = string.format("Your luck: %g×   ·   Gold: %g×   ·   Boosts add up to 4 hours.",
			math.floor(Bonuses.luck(state) * 100 + 0.5) / 100, math.floor(Bonuses.gold(state) * 100 + 0.5) / 100)
		if self:allowed() == false then
			self.boostNote.Text = "Luck boosts aren't available in your region. Gold boosts and Sell Anywhere are."
		end
	end)
end

function Panel:buildGems()
	local page = self.pages.Gems
	self.gemNote = words(page, "Gems open crates, craft at the Forge and buy supplies.", 0, 0, 764, 26, 17, rgb(190, 245, 255))
	local list = Card.scroller(page, "Gems", 0, 30, 764, 328)
	self.gemGlows = {}
	local i = 0
	for _, item in S.products do
		if item.group ~= "Gems" then continue end
		i += 1
		local x, y = (i - 1) % 3 * 254, 14 + math.floor((i - 1) / 3) * 160
		local tile = box(list, item.name, x, y, 246, 146, tints.Gems)
		table.insert(self.tiles.Gems, tile)
		local glow = W.stroke(tile, rgb(255, 240, 120), 6)
		glow.Enabled = false
		self.gemGlows[item.key] = glow
		local art = W.frame(tile, "Gems art", 10, 16, 76, 76, W.ink)
		art.BackgroundTransparency = 1
		art:SetAttribute("BaseY", 16)
		Icons.draw(art, "Gems", 0, 0, 76)
		table.insert(self.bobbers, art)
		words(tile, item.name, 92, 12, 146, 28, 21, nil, true)
		words(tile, W.goldAmount(item.gems) .. " gems", 92, 38, 146, 34, 30, rgb(190, 245, 255), true)
		local bonus = S.gemBonus(item)
		if bonus > 0 then
			-- What the same gems would cost at the Gem Pouch's rate, struck through.
			local was = words(tile, "<s>R$ " .. W.goldAmount(S.basePrice(item)) .. "</s>", 92, 70, 146, 22, 17, rgb(255, 205, 215), true)
			was.RichText = true
			ribbon(tile, "+" .. bonus .. "% more", 8, -12, 104, rgb(255, 80, 120))
		end
		if item.key == S.mostPopular then
			ribbon(tile, "MOST POPULAR", 114, -12, 126, rgb(120, 90, 255))
		elseif item.key == S.bestValue then
			ribbon(tile, "BEST VALUE", 128, -12, 112, rgb(40, 190, 90))
		end
		self:buyButton(tile, "product", item, 12, 96, 222, 42)
	end
	list.CanvasSize = UDim2.fromOffset(0, 14 + math.ceil(i / 3) * 160)
end

-- The odds list: every reward, its kind, rarity and exact chance, a Try on for cosmetics and a View for
-- pets, the guarantee and the duplicate rules. Opened with "Odds & preview" before buying.
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
	local col = self:collection()
	for i, row in rows do
		local reward = row.reward
		local entry = Geodes.entry(reward)
		local rarity = C.rarities[entry.rarity]
		local line = W.frame(list, entry.name, 0, (i - 1) * 34, 670, 30, if i % 2 == 0 then rgb(52, 49, 96) else W.navy, 8)
		local chip = W.frame(line, "Rarity", 8, 7, 16, 16, rarity.color, 8)
		W.stroke(chip, W.ink, 1.5)
		local owned = if reward.kind == "pet" then (col.pets or {})[reward.id] ~= nil
			elseif C.isCosmetic(reward.kind) then (col.cos or {})[reward.id] == true else false
		words(line, entry.name .. (if (reward.count or 1) > 1 then " ×" .. reward.count else "") .. (if owned then "  ✓" else ""), 32, 0, 250, 30, 18, nil, true)
		words(line, C.kindNames[reward.kind] .. " · " .. entry.rarity, 284, 0, 200, 30, 15, rarity.color:Lerp(W.white, 0.3), true)
		local percent = words(line, Geodes.percentText(row.percent), 480, 0, 96, 30, 19, W.gold)
		percent.TextXAlignment = Enum.TextXAlignment.Right
		if C.isCosmetic(reward.kind) then
			local try = W.button(line, "Try", 590, 2, 72, 26, rgb(150, 110, 255), "Try on", "Select")
			try.TextSize = 14
			try.Activated:Connect(function() TryOn.start(self.hud, reward.kind, reward.id) end)
		elseif reward.kind == "pet" then
			local view = W.button(line, "View", 590, 2, 72, 26, rgb(110, 160, 255), "View", "Select")
			view.TextSize = 14
			view.Activated:Connect(function()
				self.menu:open("Pets")
				local pets = self.menu.pets
				if pets then
					pets.grids.Pets.selected = reward.id
					pets:refresh()
				end
			end)
		end
	end
	list.CanvasSize = UDim2.fromOffset(0, #rows * 34)
	local due = geode.pity and pity >= geode.pity.after
	self.oddsTitle.Text = geode.name .. (if due then " · guarantee active" else " · odds")
	local rules = {
		"These are the exact chances for your next " .. geode.name .. ". They add up to 100% (rounded to show).",
		"Duplicates: a pet or cosmetic you already own becomes Crate Dust, which crafts rewards at the Forge.",
		"Luck boosts change ore in the mine, not crates. Pets and cosmetics are just for looks.",
	}
	if geode.pity then
		table.insert(rules, 2, string.format(
			"Guarantee: after %d %ss in a row with nothing Legendary or better, the next one is Legendary or better (the list above shows it when it's due). Yours: %d of %d.",
			geode.pity.after, geode.name, math.min(pity, geode.pity.after), geode.pity.after))
	end
	self.oddsRules.Text = table.concat(rules, "\n")
end

-- Tiles drop in, one after another, when a tab opens.
function Panel:animateTab(tab)
	if self.player:GetAttribute("MenuMotion") == false then return end
	for i, tile in self.tiles[tab] do
		local rest = tile:GetAttribute("Rest") or tile.Position
		tile:SetAttribute("Rest", rest)
		tile.Position = rest + UDim2.fromOffset(0, 26)
		local scale = tile:FindFirstChild("Pop") or W.scale(tile)
		scale.Name = "Pop"
		scale.Scale = 0.86
		task.delay((i - 1) * 0.045, function()
			W.tween(tile, 0.26, { Position = tile:GetAttribute("Rest") })
			W.tween(scale, 0.26, { Scale = 1 })
		end)
	end
end

function Panel:open(key)
	local tab = "Featured"
	for name, value in keys do
		if value == key then tab = name end
	end
	if key == "ShopGeodes" then tab = "Crates" end
	local fresh = self.tab ~= tab or not self.card.modal.Visible
	self.page, self.tab = key, tab
	self.oddsSheet.Visible = false
	if tab ~= "Gems" then
		for _, glow in self.gemGlows do glow.Enabled = false end
		self.gemNote.Text = "Gems open crates, craft at the Forge and buy supplies."
		self.gemNote.TextColor3 = rgb(190, 245, 255)
	end
	for name, page in self.pages do
		page.Visible = name == tab
	end
	Card.paintTabs(self.paints, tab)
	local card = self.card
	card:setIcon(({ Featured = "Shop", Crates = "Geode", Passes = "Passes", Boosts = "Boosts", Gems = "Gems" })[tab])
	local tint = tints[tab]
	card.headerPaint.Color = ColorSequence.new(tint[1], tint[2])
	card.heading.Text = if tab == "Featured" then "Shop" else "Shop · " .. tab
	if fresh then self:animateTab(tab) end
	self:refresh()
end

function Panel:refresh()
	self.gemLabel.Text = W.goldAmount(self:gems())
	self.card.sub.Text = "Crate Dust " .. W.goldAmount(self:collection().dust or 0)
	for _, update in self.updates do
		update()
	end
	-- The odds change when the guarantee comes due: show them again then.
	local geode = self.oddsGeode
	if self.oddsSheet.Visible and geode and geode.pity and self:pity(geode.id) ~= self.oddsPity then self:showOdds(geode) end
end

return Panel
