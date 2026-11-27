-- The Shop: one scrolling page of sections (Featured, the Starfall Crate, passes, boosts and gold),
-- with tabs along the top that jump to each. Everything costs Robux and every price is a green button
-- with the Robux icon; a real reference price (`was`) is shown struck through where there is one.
-- The server decides everything: buttons only ask. Crates and luck boosts are switched off where
-- Roblox restricts paid random items for the player.
local Market = game:GetService("MarketplaceService")
local Run = game:GetService("RunService")
local Rep = game:GetService("ReplicatedStorage")
local Shared = Rep.Shared
local C, Geodes, S = require(Shared.Collectibles), require(Shared.Geodes), require(Shared.StoreConfig)
local Bonuses, Earnings = require(Shared.Bonuses), require(Shared.Earnings)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local Burst = require(script.Parent.Burst)
local Grid = require(script.Parent.CollectionGrid)
local FxPreview = require(script.Parent.FxPreview)
local Panel = {}
Panel.__index = Panel
local rgb = Color3.fromRGB
local pink = { rgb(255, 159, 200), rgb(227, 69, 138) }
local sections = {
	{ "Featured", "Featured", "Shop", pink },
	{ "Crates", "Crate", "Geode", { rgb(207, 174, 255), rgb(129, 80, 230) } },
	{ "Passes", "Passes", "Passes", { rgb(255, 230, 128), rgb(243, 165, 26) } },
	{ "Boosts", "Boosts", "Boosts", { rgb(166, 245, 154), rgb(52, 178, 74) } },
	{ "Gold", "Gold", "Coins", { rgb(255, 214, 120), rgb(214, 140, 40) } },
}
-- The page keys other code opens, and the section each lands on.
local keyFor = { Featured = "Shop", Crates = "ShopCrates", Passes = "ShopPasses", Boosts = "ShopBoosts", Gold = "ShopGold" }
local sectionFor = { Shop = "Featured", ShopCrates = "Crates", ShopGeodes = "Crates", ShopPasses = "Passes", ShopBoosts = "Boosts", ShopGold = "Gold", ShopGems = "Gold" }
local buyTop, buyBottom = rgb(110, 214, 88), rgb(38, 150, 62)
local buyGreen = ColorSequence.new(buyTop, buyBottom)
local grey = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local ownedPaint = ColorSequence.new(rgb(134, 214, 255), rgb(47, 130, 230))
local violet = ColorSequence.new(rgb(207, 174, 255), rgb(129, 80, 230))
local goldText = rgb(255, 222, 90)
local speedGreen = rgb(150, 255, 120)
-- The picture for an item (effects get a live preview instead).
local itemIcons = { GoldPouch = "GoldPouch", GoldSack = "GoldBag", GoldChest = "GoldChest", GoldTonic = "Boosts",
	HasteTonic = "Speed", LuckyBrew = "Crystal", StarfallGeode = "Geode", WelcomeGeode = "Geode" }
local function itemIcon(id) return itemIcons[id] or "Boosts" end
local words, press, set = Grid.words, Grid.press, Grid.set
local practice = Run:IsStudio() and game.GameId == 0
local width = 764
-- The cards are laid out 764 wide and drawn a little smaller, inset from the left, so corner tags and
-- the scrollbar never cut them off.
local inset, fit = 12, 0.975
local headerHeight = 48 -- a section header, before its cards

local function box(parent, name, x, y, w, h, tint)
	local frame = W.frame(parent, name, x, y, w, h, W.white, 18)
	return frame, W.enamelPanel(frame, tint[1], tint[2], 18)
end
-- A tilted tag pinned over a card's top corner ("BEST VALUE", "POPULAR"), half on the card and half
-- off it, so it never covers the card's own text.
local function tag(parent, text, corner, color)
	local w = 24 + #text * 11
	local x = if corner == "right" then parent.Size.X.Offset - w + 6 else -12
	local label = W.frame(parent, "Tag", x, -16, w, 30, color, 10)
	label.Rotation, label.ZIndex = if corner == "right" then 6 else -7, 8
	label:SetAttribute("Tilt", label.Rotation)
	W.stroke(label, W.navy, 3)
	local t = words(label, text, 0, 0, w, 28, 17)
	t.ZIndex = 9
	return label
end
local tagColors = { ["BEST VALUE"] = rgb(255, 150, 60), POPULAR = rgb(255, 80, 120), STATUS = rgb(150, 100, 255), ["RARE ORE"] = rgb(60, 190, 255), ["FOR EVERYONE"] = rgb(60, 200, 120), NEW = rgb(60, 190, 255) }

function Panel.new(menu)
	local self = setmetatable({ menu = menu, player = menu.player, net = menu.net, hud = menu.hud, updates = {}, prices = {},
		anchors = {}, tiles = {}, bobbers = {}, spinners = {}, shines = {}, pulses = {}, tags = {} }, Panel)
	local card = Card.new(menu, "Shop", "Shop", "Shop", pink)
	self.card = card
	local tabs = {}
	for _, section in sections do table.insert(tabs, { section[1], section[2], section[3] }) end
	self.paints = card:tabRow(tabs, function(key) self:jump(key, true) end)
	-- The page scrolls on its own; the card's body stays put (also on phones).
	local layout = card.layout
	-- On a phone the Shop is sized for reading (WideCard: scrolls), not to show the whole card.
	card.scrolls = true
	card.layout = function(c, area, touch, room)
		layout(c, area, touch, room)
		c.body.ScrollingEnabled, c.body.CanvasSize, c.body.CanvasPosition = false, UDim2.new(), Vector2.zero
	end
	local scroller = Card.scroller(card.body, "Shop page", 0, 4, 778, 358)
	scroller.Size = UDim2.new(1, 0, 1, -6)
	scroller.ScrollBarThickness = 8
	local page = W.frame(scroller, "Content", inset, 0, width, 10, W.ink)
	page.BackgroundTransparency = 1
	W.scale(page).Scale = fit
	self.scroller, self.page = scroller, page
	local y = 4
	for _, section in sections do
		y = self:header(section, y)
		y = self["build" .. section[1]](self, y) + 26
	end
	self.bottom = y
	page.Size = UDim2.fromOffset(width, y)
	scroller.CanvasSize = UDim2.fromOffset(0, math.ceil(y * fit) + 8)
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function() self:follow() end)
	self:buildOdds()
	-- Idle motion: art bobs, rays turn, shines sweep, tags wobble and buy buttons breathe.
	Run.RenderStepped:Connect(function()
		if not card.modal.Visible or self.player:GetAttribute("MenuMotion") == false then return end
		local t = os.clock()
		for i, bob in self.bobbers do
			bob.Position = UDim2.fromOffset(bob:GetAttribute("BaseX"), bob:GetAttribute("BaseY") + 5 * math.sin(t * 2.2 + i))
		end
		for i, spin in self.spinners do spin.Rotation = (t * 8 + i * 30) % 360 end
		for i, shine in self.shines do
			shine.Position = UDim2.new(((t * 0.4 + i * 0.37) % 1.7) - 0.35, 0, 0, -30)
		end
		for i, label in self.tags do label.Rotation = label:GetAttribute("Tilt") + 2 * math.sin(t * 2 + i) end
		local beat = 1 + 0.035 * math.sin(t * 4)
		for _, scale in self.pulses do scale.Scale = beat end
	end)
	return self
end

-- A section header like a shelf label: icon, title pill and a line.
function Panel:header(section, y)
	local holder = W.frame(self.page, section[1] .. " header", 0, y, width, headerHeight - 6, W.ink)
	holder.BackgroundTransparency = 1
	local pill = W.frame(holder, "Pill", 28, 5, 170, 32, W.white, 16)
	W.enamelPanel(pill, section[4][1], section[4][2], 16)
	words(pill, string.upper(section[2]), 22, 0, 144, 30, 21)
	Icons.draw(holder, section[3], 0, 0, 42)
	local line = W.frame(holder, "Line", 210, 19, width - 218, 5, section[4][2], 3)
	line.BackgroundTransparency = 0.4
	self.anchors[section[1]] = y
	return y + headerHeight
end

function Panel:collection()
	return Bonuses.decode(self.player:GetAttribute("Collection")) or {}
end
function Panel:crates()
	return (self:collection().items or {}).StarfallGeode or 0
end
function Panel:pity()
	return (self:collection().pity or {}).Starfall or 0
end

-- Robux price: the live price once loaded, the configured one before.
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

-- A green Robux button for a pass or product, kept current: owned, sold out or unavailable states
-- replace the price. The struck-through `was` price sits above it when there is one.
function Panel:buyButton(parent, kind, item, x, y, w, h)
	local holder = W.frame(parent, item.key .. " button", x, y, w, h, W.ink)
	holder.BackgroundTransparency = 1
	local shadow = W.frame(holder, "Shadow", 0, 5, w, h, rgb(30, 120, 50), 14)
	shadow.ZIndex = 1
	local button = W.clearButton(holder, item.key, 0, 0, w, h, "Select")
	button.ZIndex = 2
	W.round(button, 14)
	local paint = W.enamelPanel(button, buyTop, buyBottom, 14)
	paint.Color = buyGreen
	local size = math.floor(h * 0.55)
	local price, amount = W.robux(button, item.price, size)
	local status = words(button, "", 0, 0, w, h - 2, math.floor(h * 0.45))
	local scale = W.scale(holder)
	table.insert(self.pulses, scale)
	local was
	if item.was then
		local holder = W.frame(parent, "Was", x, y - 24, w, 22, W.ink)
		holder.BackgroundTransparency = 1
		-- What it costs bought the expensive way, as a value, not a struck-through former price.
		local row, label = W.robux(holder, W.goldAmount(item.was), 17, rgb(255, 205, 215))
		local worth = label:Clone()
		worth.Name, worth.LayoutOrder, worth.Text = "Worth", 0, "Worth"
		worth.Parent = row
		local off = S.off(item)
		if off then label.Text ..= '  <font color="#8CFF6E">-' .. off .. "%</font>" end
		was = holder
	end
	button.Activated:Connect(function()
		self.hud.checkout:buy(kind, item)
	end)
	table.insert(self.updates, function()
		local text
		if kind == "pass" then
			local owned, included = self:ownsPass(item.key)
			if owned or included then text = if owned then "Owned ✓" else "Included ✓" end
		elseif item.cosmetic and (self:collection().cos or {})[item.cosmetic.id] then
			text = "Owned ✓"
		elseif item.once and not item.cosmetic and self.player:GetAttribute("StarterBought") then
			text = "Claimed ✓"
		elseif item.limited and (Rep:GetAttribute("Limited" .. item.key) or item.limited) <= 0 then
			text = "Sold out"
		elseif (item.luck or item.random) and self:allowed() ~= true then
			text = if self:allowed() == nil then "Checking…" else "Not in your region"
		elseif item.id <= 0 and not (practice or require(Rep.Shared.GameConfig).FreeUnconfiguredItems) then
			text = "Coming soon"
		end
		price.Visible, status.Text = text == nil, text or ""
		paint.Color = if text == nil then buyGreen elseif text:find("✓") then ownedPaint else grey
		button.Interactable, button.AutoButtonColor = text == nil, text == nil
		if was then was.Visible = text == nil end
		amount.Text = tostring(self:price(kind, item))
	end)
	return holder
end

-- Art that bobs: a FieldKit icon in its own frame.
function Panel:art(parent, key, x, y, size)
	local holder = W.frame(parent, key .. " art", x, y, size, size, W.ink)
	holder.BackgroundTransparency = 1
	holder:SetAttribute("BaseX", x)
	holder:SetAttribute("BaseY", y)
	Icons.draw(holder, key, 0, 0, size)
	table.insert(self.bobbers, holder)
	return holder
end
-- Turning rays and a sweeping shine for the best cards.
-- `calm`: faint rays and no sweeping shine, so the card's own art is what you look at.
function Panel:shimmer(tile, x, y, length, calm)
	local clip = W.frame(tile, "Glow", 4, 4, 0, 0, W.white)
	clip.Size, clip.BackgroundTransparency, clip.ClipsDescendants = UDim2.new(1, -8, 1, -8), 1, true
	local spin = W.frame(clip, "Spin", x - 4, y - 4, 0, 0, W.white)
	spin.BackgroundTransparency = 1
	Burst.rays(spin, 0, 0, length, 10, W.white, if calm then 0.94 else 0.84)
	if calm then return end
	table.insert(self.spinners, spin)
	local shine = W.frame(clip, "Shine", 0, -30, 54, 600, W.white)
	shine.Rotation, shine.BackgroundTransparency, shine.ZIndex = 18, 0.8, 7
	table.insert(self.shines, shine)
end

function Panel:buildFeatured(y)
	local page = self.page
	-- Limited: an aura only the first 100 buyers get.
	local limited = S.productByKey.FounderHalo
	local hero = box(page, "Limited", 0, y + 12, 372, 236, { rgb(255, 200, 120), rgb(214, 96, 40) })
	self:shimmer(hero, 80, 110, 230, true)
	table.insert(self.tags, tag(hero, "LIMITED", "left", rgb(255, 70, 90)))
	FxPreview.new(hero, "aura", "FounderHalo", 10, 44, 140)
	words(hero, limited.name, 152, 14, 210, 34, 27, nil, true)
	local detail = words(hero, W.rich("A Limited aura, " .. W.colored("+16% movement speed", speedGreen) .. ". On sale until 100 are sold."), 154, 50, 206, 60, 15, rgb(255, 250, 215), true)
	detail.TextWrapped = true
	W.largest(detail, 15, 10)
	local track = W.frame(hero, "Stock", 154, 132, 206, 24, W.navy, 12)
	W.stroke(track, W.navy, 3)
	local fill = W.frame(track, "Fill", 0, 0, 0, 24, W.white, 12)
	W.gradient(fill, rgb(255, 230, 120), rgb(255, 120, 60), 0)
	local stock = words(track, "", 0, 0, 206, 24, 14)
	stock.ZIndex = 5
	self:buyButton(hero, "product", limited, 154, 178, 206, 46)
	table.insert(self.updates, function()
		local left = Rep:GetAttribute("Limited" .. limited.key) or limited.limited
		fill.Size = UDim2.new(math.clamp(left / limited.limited, 0, 1), 0, 1, 0)
		stock.Text = W.goldAmount(left) .. " / " .. W.goldAmount(limited.limited) .. " left"
	end)
	-- Starter Pack, once.
	local starter = S.productByKey.StarterPack
	local pack = box(page, "Starter Pack", 384, y + 12, 380, 112, pink)
	self:shimmer(pack, 50, 56, 140)
	table.insert(self.tags, tag(pack, "ONE TIME", "right", rgb(255, 70, 90)))
	self:art(pack, "Geode", 14, 10, 72)
	words(pack, "Starter Pack", 96, 8, 180, 30, 24, nil, true)
	local contents = words(pack, W.rich("2 Starfall Crates\n30 min of 2× Gold\nA Haste Tonic"), 98, 38, 128, 66, 15, rgb(255, 250, 215), true)
	contents.TextWrapped, contents.TextYAlignment = true, Enum.TextYAlignment.Top
	W.largest(contents, 15, 9)
	self:buyButton(pack, "product", starter, 230, 64, 140, 40)
	-- It holds crates, so its odds are one tap away before buying: a small link under the art, clear
	-- of the price and its "Worth" line.
	local odds = W.clearButton(pack, "Crate odds", 4, 88, 92, 22, "Select")
	local oddsText = words(odds, "Odds ▸", 0, 0, 92, 22, 16, rgb(255, 244, 170))
	oddsText.ZIndex = 3
	odds.Activated:Connect(function() self:showOdds(Geodes.main) end)
	-- In the Starter Pack's place once it's bought: Instamine.
	local instamine = S.productByKey.Instamine10
	local swap = box(page, "Instamine offer", 384, y + 12, 380, 112, { rgb(166, 245, 154), rgb(40, 150, 70) })
	table.insert(self.tags, tag(swap, "POPULAR", "right", tagColors.POPULAR))
	self:art(swap, "Power", 10, 16, 80)
	words(swap, instamine.name, 96, 8, 270, 30, 24, nil, true)
	local swapText = words(swap, W.rich(instamine.detail), 98, 38, 128, 66, 14, rgb(255, 250, 215), true)
	swapText.TextWrapped, swapText.TextYAlignment = true, Enum.TextYAlignment.Top
	W.largest(swapText, 14, 9)
	self:buyButton(swap, "product", instamine, 230, 64, 140, 40)
	swap.Visible = false
	-- VIP: the daily crate when owned, the pass otherwise.
	local vip = box(page, "VIP", 384, y + 136, 380, 112, { rgb(255, 230, 128), rgb(243, 165, 26) })
	local popular = tag(vip, "POPULAR", "right", tagColors.POPULAR)
	table.insert(self.tags, popular)
	self:art(vip, "Achievements", 10, 16, 80)
	words(vip, "VIP", 96, 8, 180, 30, 26, nil, true)
	local vipText = words(vip, "", 98, 36, 272, 26, 15, rgb(255, 250, 215), true)
	vipText.TextWrapped = true
	W.largest(vipText, 15, 10)
	local chest, chestPaint, chestLabel = press(vip, "VIP crate", 98, 64, 272, 40, 19)
	local vipBuy = self:buyButton(vip, "pass", S.passByKey.VIP, 230, 64, 140, 40)
	chest.Activated:Connect(function() self.net.Action:FireServer("VipChest") end)
	table.insert(self.updates, function()
		local _, owned = self:ownsPass("VIP")
		chest.Visible, vipBuy.Visible, popular.Visible = owned, not owned, not owned
		if owned then
			local wait = (self.player:GetAttribute("VipChestAt") or 0) + S.vipCrateHours * 3600 - workspace:GetServerTimeNow()
			vipText.Text = W.rich("+20% gold · +20% XP · a free Starfall Crate daily")
			if wait > 0 then
				set(chest, chestPaint, chestLabel, "Next VIP crate in " .. W.clock(wait), grey, false)
			else
				set(chest, chestPaint, chestLabel, "Claim your free crate!", buyGreen, true)
			end
		else
			vipText.Text = W.rich("+20% gold, +20% XP and a free Starfall Crate daily")
		end
		-- Once the Starter Pack is bought, Instamine takes its place.
		pack.Visible = not self.player:GetAttribute("StarterBought")
		swap.Visible = not pack.Visible
	end)
	return y + 250
end

function Panel:buildCrates(y)
	local page = self.page
	local geode = Geodes.main
	local tile = box(page, "Starfall Crate", 0, y + 4, width, 292, { rgb(207, 174, 255), rgb(90, 50, 190) })
	self:shimmer(tile, 120, 140, 260)
	self:art(tile, "Geode", 30, 40, 180)
	local name = words(tile, W.rich("Starfall Crate"), 236, 10, 300, 40, 34, nil, true)
	name.TextXAlignment = Enum.TextXAlignment.Left
	local blurb = words(tile, W.rich("Mining FX, Player FX, tonics and gold. A duplicate turns into gold."), 238, 50, 300, 40, 15, rgb(255, 250, 215), true)
	blurb.TextWrapped = true
	W.largest(blurb, 15, 10)
	-- The mix by rarity, as a bar and as numbers: one rounded strip inside a rounded track, coloured in
	-- hard bands by a gradient. Rarer bands get a minimum width so a 0.5% sliver still shows.
	local bar = W.frame(tile, "Rarity mix", 238, 98, 300, 22, W.navy, 11)
	W.stroke(bar, W.navy, 3)
	local strip = W.frame(bar, "Bands", 2, 2, 296, 18, W.white, 9)
	local rows, lines = Geodes.breakdown(geode), {}
	local shares, total = {}, 0
	for i, row in rows do
		shares[i] = math.max(3.5, row[2])
		total += shares[i]
	end
	local keys, at = {}, 0
	for i, row in rows do
		local color = C.rarities[row[1]].color
		local from, to = at, if i == #rows then 1 else at + shares[i] / total
		table.insert(keys, ColorSequenceKeypoint.new(if i == 1 then 0 else from + 0.0005, color))
		table.insert(keys, ColorSequenceKeypoint.new(to, color))
		at = to
		table.insert(lines, W.colored(row[1] .. " " .. Geodes.percentText(row[2]), color))
	end
	local bands = Instance.new("UIGradient")
	bands.Color, bands.Parent = ColorSequence.new(keys), strip
	local mix = words(tile, table.concat(lines, "   "), 238, 124, 300, 44, 15, nil, true)
	mix.TextWrapped = true
	local pity = words(tile, "", 238, 170, 300, 22, 15, rgb(190, 255, 150), true)
	local odds, oddsPaint, oddsLabel = press(tile, "Odds", 238, 196, 300, 38, 18)
	oddsPaint.Color, oddsLabel.Text = violet, "Odds & preview of every item"
	odds.Activated:Connect(function() self:showOdds(geode) end)
	local free, freePaint, freeLabel = press(tile, "Open free", 238, 240, 300, 40, 19)
	free.Activated:Connect(function() self.net.Action:FireServer("OpenGeode", "Starfall") end)
	-- Buy 1, 3 or 10.
	for i, key in { "Crate1", "Crate3", "Crate10" } do
		local item = S.productByKey[key]
		local by = 38 + (i - 1) * 86
		words(tile, item.crates .. "×", 552, by, 60, 40, 30, goldText)
		self:buyButton(tile, "product", item, 612, by, 138, 44)
	end
	table.insert(self.updates, function()
		local n = self:pity()
		pity.Text = if n >= geode.pity.after then W.rich("Your next crate is Legendary or better!")
			else W.rich(string.format("Legendary or better guaranteed within %d crates", geode.pity.after + 1 - n))
		local have = self:crates()
		free.Visible = have > 0
		set(free, freePaint, freeLabel, "Open your crates (" .. have .. ")", buyGreen, true)
	end)
	table.insert(self.tiles, tile)
	return y + 300
end

-- A compact deal card: art, name, what it does and its price. Two rows of these fit on screen.
local cardW, cardH, cardStep = 248, 146, 156
function Panel:dealCard(kind, item, x, y, tint)
	local tile = box(self.page, item.name, x, y, cardW, cardH, tint)
	if item.tag then table.insert(self.tags, tag(tile, item.tag, "left", tagColors[item.tag] or rgb(255, 80, 120))) end
	self:art(tile, item.icon or "Boosts", 10, 16, 62)
	local title = words(tile, item.name, 80, 8, 160, 30, 19, nil, true)
	title.TextWrapped = true
	W.largest(title, 19, 11)
	local detail = words(tile, W.rich(item.detail or ""), 80, 38, 160, 52, 13, rgb(255, 250, 215), true)
	detail.TextWrapped, detail.TextYAlignment = true, Enum.TextYAlignment.Top
	W.largest(detail, 13, 9)
	self:buyButton(tile, kind, item, 10, cardH - 46, cardW - 20, 38)
	table.insert(self.tiles, tile)
	return tile, detail
end

function Panel:buildPasses(y)
	local page = self.page
	-- The All Passes Bundle: one row like a shelf, every other pass in it.
	local all = S.passByKey.Everything
	local row = box(page, "Everything", 0, y + 12, width, 118, { rgb(255, 140, 200), rgb(160, 40, 110) })
	self:shimmer(row, 70, 60, 180)
	table.insert(self.tags, tag(row, "BEST VALUE", "left", tagColors["BEST VALUE"]))
	self:art(row, "Passes", 22, 14, 90)
	local count = 0
	for _, pass in S.passes do
		if not pass.bundle and not pass.retired then count += 1 end
	end
	local facts = {
		"All " .. count .. " passes, yours forever",
		"Worth " .. W.goldAmount(all.was) .. " Robux one by one",
		W.rich("Plus the Celestial title and two Exclusive effects"),
	}
	for i, fact in facts do
		local fy = 8 + (i - 1) * 34
		Icons.draw(row, "Achievements", 130, fy + 2, 26)
		local line = words(row, fact, 162, fy, 360, 30, 18, nil, true)
		W.largest(line, 18, 11)
	end
	self:buyButton(row, "pass", all, 540, 46, 210, 60)
	-- The passes one by one, three to a row.
	local i = 0
	local top = y + 12 + 118 + 22
	for _, item in S.passes do
		if item.bundle or item.retired then continue end
		i += 1
		self:dealCard("pass", item, (i - 1) % 3 * 258, top + math.floor((i - 1) / 3) * cardStep, { rgb(255, 230, 150), rgb(214, 150, 50) })
	end
	return top + math.ceil(i / 3) * cardStep - 10
end

function Panel:buildBoosts(y)
	local i = 0
	for _, item in S.products do
		if item.group ~= "Boosts" then continue end
		i += 1
		local _, detail = self:dealCard("product", item, (i - 1) % 3 * 258, y + 12 + math.floor((i - 1) / 3) * cardStep,
			{ rgb(166, 245, 154), rgb(40, 150, 70) })
		table.insert(self.updates, function()
			local state = Bonuses.state(self.player)
			local left = if item.key == "ServerLuck" then math.max(0, state.serverLuckUntil - state.now)
				elseif item.boost then Bonuses.left(state, item.boost) else 0
			detail.Text = W.rich(item.detail .. (if left > 0 then "\nActive · " .. W.clock(left) .. " left" else ""))
		end)
	end
	return y + 12 + math.ceil(i / 3) * cardStep - 10
end

-- Gold, from a pouch to a vault: the pouch and the bag top left, the chest under them, and the vault
-- large on the right. Every pack pays the buyer's own earnings, so the amounts grow with them.
function Panel:buildGold(y)
	local page = self.page
	local packs = {}
	for _, item in S.products do
		if item.group == "Gold" then packs[item.art] = item end
	end
	local arts = { vault = "GoldVault", chest = "GoldChest", pouch = "GoldPouch", bag = "GoldBag" }
	local function amountFor(item, label, about)
		table.insert(self.updates, function()
			local perHour = self.player:GetAttribute("GoldBundle") or Earnings.minimum
			label.Text = "+" .. W.goldAmount(Earnings.tidy(perHour, item.minutes)) .. " gold"
			about.Text = (S.duration(item.minutes):gsub("^%l", string.upper)) .. " of your earnings"
		end)
	end
	local green = { rgb(150, 230, 170), rgb(30, 120, 80) }
	-- Pouch and bag: art on the left, the amount beside it, the button along the bottom.
	for i, art in { "pouch", "bag" } do
		local item = packs[art]
		local tile = box(page, item.name, (i - 1) * 196, y + 12, 184, 150, green)
		self:art(tile, arts[art], 6, 10, 50)
		local amount = words(tile, "", 58, 8, 120, 28, 20, goldText, true)
		W.largest(amount, 20, 12)
		local about = words(tile, "", 58, 36, 120, 30, 12, rgb(255, 250, 215), true)
		about.TextWrapped = true
		W.largest(about, 12, 9)
		self:buyButton(tile, "product", item, 10, 104, 164, 38)
		amountFor(item, amount, about)
		table.insert(self.tiles, tile)
	end
	-- Chest under them: wide, art on the left.
	local chestItem = packs.chest
	local chest = box(page, chestItem.name, 0, y + 174, 380, 146, green)
	table.insert(self.tags, tag(chest, "POPULAR", "left", tagColors.POPULAR))
	self:art(chest, arts.chest, 16, 26, 96)
	local chestAmount = words(chest, "", 130, 12, 240, 34, 28, goldText, true)
	W.largest(chestAmount, 28, 14)
	local chestAbout = words(chest, "", 130, 46, 240, 20, 14, rgb(255, 250, 215), true)
	self:buyButton(chest, "product", chestItem, 172, 96, 196, 40)
	amountFor(chestItem, chestAmount, chestAbout)
	table.insert(self.tiles, chest)
	-- The vault, large on the right.
	local vaultItem = packs.vault
	local vault = box(page, vaultItem.name, 392, y + 12, 372, 308, { rgb(255, 226, 140), rgb(200, 130, 40) })
	self:shimmer(vault, 186, 90, 220)
	table.insert(self.tags, tag(vault, "BEST VALUE", "left", tagColors["BEST VALUE"]))
	self:art(vault, arts.vault, 121, 18, 130)
	local vaultAmount = words(vault, "", 6, 154, 360, 42, 38, goldText)
	W.largest(vaultAmount, 38, 18)
	local vaultAbout = words(vault, "", 6, 196, 360, 20, 16, rgb(255, 250, 215))
	self:buyButton(vault, "product", vaultItem, 12, 244, 348, 54)
	amountFor(vaultItem, vaultAmount, vaultAbout)
	table.insert(self.tiles, vault)
	return y + 330
end

-- The odds list: every reward with a live preview, its kind, rarity and exact chance; then the mix by
-- rarity, the guarantee and what duplicates give.
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
	W.largest(self.oddsRules, 15, 10)
end

function Panel:showOdds(geode)
	local sheet, list = self.oddsSheet, self.oddsList
	sheet.Visible = true
	local height = math.clamp(self.card.modal.Size.Y.Offset - 90, 280, 420)
	sheet.Size = UDim2.fromOffset(720, height)
	list.Size = UDim2.fromOffset(688, height - 54 - 130)
	self.oddsRules.Position, self.oddsRules.Size = UDim2.fromOffset(18, height - 122), UDim2.fromOffset(684, 116)
	self.oddsGeode = geode
	list:ClearAllChildren()
	local pity = self:pity()
	self.oddsPity = pity
	local rows = Geodes.odds(geode, pity)
	table.sort(rows, function(a, b) return a.percent > b.percent end)
	local col = self:collection()
	local rowH = 40
	for i, row in rows do
		local reward = row.reward
		local entry = Geodes.entry(reward)
		local line = W.frame(list, entry.name, 0, (i - 1) * rowH, 670, rowH - 4, if i % 2 == 0 then rgb(52, 49, 96) else W.navy, 8)
		if C.isCosmetic(reward.kind) then
			FxPreview.new(line, reward.kind, reward.id, 4, 0, rowH - 4)
		else
			Icons.draw(line, itemIcon(reward.id), 6, 2, rowH - 8)
		end
		local owned = C.isCosmetic(reward.kind) and (col.cos or {})[reward.id] == true
		local title = words(line, entry.name .. (if owned then "  ✓" else ""), 48, 0, 250, rowH - 4, 18, nil, true)
		W.largest(title, 18, 11)
		words(line, C.kindNames[reward.kind] .. " · " .. W.rich(entry.rarity), 310, 0, 220, rowH - 4, 15, rgb(220, 220, 240), true)
		local percent = words(line, Geodes.percentText(row.percent), 540, 0, 116, rowH - 4, 20, W.gold)
		percent.TextXAlignment = Enum.TextXAlignment.Right
	end
	list.CanvasSize = UDim2.fromOffset(0, #rows * rowH)
	local due = geode.pity and pity >= geode.pity.after
	self.oddsTitle.Text = W.rich(geode.name .. (if due then " · guarantee active" else " · odds"))
	local mix = {}
	for _, row in Geodes.breakdown(geode, pity) do
		table.insert(mix, row[1] .. " " .. Geodes.percentText(row[2]))
	end
	local rules = {
		"By rarity: " .. table.concat(mix, " · ") .. ". Every item's exact chance is above; together they add up to 100%.",
		"An effect you already own turns into gold instead (more for rarer ones).",
		"Luck boosts change ore in the mine, not crates.",
	}
	if geode.pity then
		table.insert(rules, 2, string.format(
			"Guarantee: after %d crates in a row with nothing Legendary or better, the next one is Legendary or better. Yours: %d of %d.",
			geode.pity.after, math.min(pity, geode.pity.after), geode.pity.after))
	end
	self.oddsRules.Text = W.rich(table.concat(rules, "\n"))
end

-- Scroll positions are on-screen pixels, and every scale between the screen and the page (the card's,
-- the HUD's, the content's own) applies. This is how many on-screen pixels one layout unit of the
-- content takes, measured, so it holds on any screen.
function Panel:pixels()
	local canvas = self.scroller.CanvasSize.Y.Offset
	local shown = self.scroller.AbsoluteCanvasSize.Y
	if canvas <= 0 or shown <= 0 then return nil end
	return shown / canvas * fit
end

-- Where a section starts and ends, in content units.
function Panel:span(section)
	local top, bottom = self.anchors[section] or 0, self.bottom
	for i, row in sections do
		if row[1] == section and sections[i + 1] then bottom = self.anchors[sections[i + 1][1]] - 26 end
	end
	return top, bottom
end

-- Scrolls to a section, smoothly when `animate`. The section's header sits at the top. When the whole
-- section doesn't fit but its cards do without the header, the page scrolls on until every card is in
-- view instead.
function Panel:jump(section, animate)
	local scroller = self.scroller
	local px = self:pixels()
	if not px then
		task.defer(function() if self.card.modal.Visible then self:jump(section, false) end end)
		return
	end
	local window = scroller.AbsoluteWindowSize.Y / px
	local top, bottom = self:span(section)
	local cards = top + headerHeight - 20
	local y = top - 4
	if bottom - top > window and bottom - cards <= window then y = bottom - window + 6 end
	local most = math.max(0, scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y)
	local goal = Vector2.new(0, math.clamp(math.floor(y * px + 0.5), 0, most))
	self.section, self.jumping = section, section
	Card.paintTabs(self.paints, section)
	if animate and self.player:GetAttribute("MenuMotion") ~= false then
		local tween = W.tween(scroller, 0.35, { CanvasPosition = goal })
		tween.Completed:Once(function()
			if self.jumping == section then self.jumping = nil end
		end)
	else
		scroller.CanvasPosition = goal
		task.defer(function()
			if self.jumping == section then self.jumping = nil end
		end)
	end
end

-- The tab of the section in view lights up as the page scrolls. At the very bottom, that's the last
-- section, even when its header can't reach the top.
function Panel:follow()
	if self.jumping then return end
	local px = self:pixels()
	if not px then return end
	local scroller = self.scroller
	local y = scroller.CanvasPosition.Y / px + 60
	local current = sections[1][1]
	for _, section in sections do
		if (self.anchors[section[1]] or 0) <= y then current = section[1] end
	end
	if scroller.CanvasPosition.Y >= scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y - 2 then
		current = sections[#sections][1]
	end
	if current ~= self.section then
		self.section = current
		Card.paintTabs(self.paints, current)
	end
end

-- Tiles drop in, one after another, when the Shop opens.
function Panel:arrive()
	if self.player:GetAttribute("MenuMotion") == false then return end
	for i, tile in self.tiles do
		local scale = tile:FindFirstChild("Pop") or W.scale(tile)
		scale.Name = "Pop"
		scale.Scale = 0.85
		task.delay(math.min(i, 10) * 0.035, function() W.tween(scale, 0.28, { Scale = 1 }) end)
	end
end

function Panel:open(key)
	local section = sectionFor[key] or "Featured"
	local fresh = not self.card.modal.Visible
	self.key = key
	self.oddsSheet.Visible = false
	self.card:setIcon("Shop")
	self.card.headerPaint.Color = ColorSequence.new(pink[1], pink[2])
	self.card.heading.Text = "Shop"
	if fresh then self:arrive() end
	self:refresh()
	task.defer(function() self:jump(section, not fresh) end)
end

function Panel:refresh()
	local crates = self:crates()
	self.card.sub.Text = if crates > 0 then W.rich(crates .. " Starfall Crate" .. (if crates == 1 then "" else "s") .. " waiting in your inventory")
		else W.rich("Trails, auras, crates, passes and gold")
	self.card.sub.RichText = true
	for _, update in self.updates do
		update()
	end
	local geode = self.oddsGeode
	if self.oddsSheet.Visible and geode and self:pity() ~= self.oddsPity then self:showOdds(geode) end
end

-- Older callers that point at a pack. Gold is the only currency now.
function Panel:needGems()
	self:jump("Gold", true)
end
local _ = keyFor
return Panel
