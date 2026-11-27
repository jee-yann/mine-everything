-- Featured offers on the HUD: animated tiles beside the reward rail (for now the Founder's Halo and the
-- Starter Pack), each opening its own offer card with the art, what's inside, the real price struck
-- through and a green Robux button. A tile goes away once its offer is bought or sold out. To feature
-- something else, add it to `offers` below.
--   The Founder's Halo card is the special one: a live preview of the aura, a stock bar and its lines,
--   with a calm background so the aura is what you look at.
--   The Starter Pack card has a header band with its name, then the art, what's inside and the price.
local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Shared = Rep.Shared
local S = require(Shared.StoreConfig)
local Bonuses = require(Shared.Bonuses)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local Burst = require(script.Parent.Burst)
local FxPreview = require(script.Parent.FxPreview)
local Offers = {}
Offers.__index = Offers
local rgb = Color3.fromRGB
local speedGreen = rgb(150, 255, 120)

-- Each offer: the product, its art, the tile's pill and colours, and what its card shows.
local offers = {
	{
		key = "FounderHalo", ribbon = "LIMITED", title = "LIMITED OFFER", caption = "Halo",
		tint = { rgb(255, 200, 120), rgb(214, 96, 40) }, ribbonColor = rgb(255, 70, 90),
		preview = { "aura", "FounderHalo" },
		lines = {
			{ "Gems", "Founder's Halo: a Limited aura" },
			{ "Speed", W.colored("+16% movement speed", speedGreen) .. " while worn" },
			{ "Achievements", "On sale until 100 are sold" },
		},
	},
	{
		key = "StarterPack", art = "Geode", ribbon = "-62%", title = "STARTER PACK", caption = "Starter",
		tint = { rgb(255, 159, 200), rgb(227, 69, 138) }, ribbonColor = rgb(60, 190, 90),
		header = "For new miners · one time only",
		lines = {
			{ "Geode", "2 Starfall Crates" },
			{ "Coins", "30 min of 2× Gold" },
			{ "Speed", "A Haste Tonic" },
		},
	},
}

function Offers.new(hud, net, parent, size)
	local self = setmetatable({ hud = hud, net = net, player = Players.LocalPlayer, tiles = {}, bobbers = {}, spinners = {} }, Offers)
	for _, offer in offers do
		offer.item = S.productByKey[offer.key]
		self.tiles[offer.key] = self:tile(parent, offer, size)
	end
	self:buildCard()
	local function update() self:refresh() end
	self.player:GetAttributeChangedSignal("StarterBought"):Connect(update)
	self.player:GetAttributeChangedSignal("Collection"):Connect(update)
	Rep:GetAttributeChangedSignal("LimitedFounderHalo"):Connect(update)
	self:refresh()
	Run.RenderStepped:Connect(function()
		if self.player:GetAttribute("MenuMotion") == false then return end
		local t = os.clock()
		for i, bob in self.bobbers do
			if bob.Parent then
				bob.Position = UDim2.fromOffset(bob:GetAttribute("BaseX"), bob:GetAttribute("BaseY") + 4 * math.sin(t * 2.6 + i * 1.7))
			end
		end
		for i, spin in self.spinners do spin.Rotation = (t * 25 + i * 40) % 360 end
		for _, tile in self.tiles do
			tile.pulse.Scale = 1 + 0.04 * math.sin(t * 3.2)
		end
	end)
	return self
end

local function bobber(self, parent, key, x, y, size)
	local holder = W.frame(parent, key .. " art", x, y, size, size, W.ink)
	holder.BackgroundTransparency = 1
	holder:SetAttribute("BaseX", x)
	holder:SetAttribute("BaseY", y)
	Icons.draw(holder, key, 0, 0, size)
	table.insert(self.bobbers, holder)
	return holder
end

-- A HUD tile: turning rays behind the offer's art, its name, and a pill under the tile (never over it).
function Offers:tile(parent, offer, size)
	local button = W.clearButton(parent, offer.key, 0, 0, size, size + 28, "Open")
	local pulse = W.scale(button)
	local shadow = W.frame(button, "Shadow", 0, 6, size, size, W.navy, 15)
	shadow.ZIndex = 1
	local face = W.frame(button, "Face", 0, 0, size, size, W.white, 15)
	face.ZIndex, face.ClipsDescendants = 2, true
	W.stroke(face, W.navy, 4)
	W.gradient(face, offer.tint[1], offer.tint[2], 90)
	local spin = W.frame(face, "Rays", size / 2, size / 2 - 4, 0, 0, W.white)
	spin.BackgroundTransparency, spin.ZIndex = 1, 2
	Burst.rays(spin, 0, 0, size, 8, W.white, 0.72)
	table.insert(self.spinners, spin)
	if offer.preview then
		local look = FxPreview.new(face, offer.preview[1], offer.preview[2], 8, 0, size - 16)
		look.ZIndex = 3
	else
		local art = bobber(self, face, offer.art, 14, 4, size - 28)
		art.ZIndex = 3
	end
	local caption = W.title(face, offer.caption, -6, size - 28, size + 12, 24, 17, W.white)
	caption.ZIndex = 4
	W.navyText(caption, 2.6)
	local ribbon = W.frame(button, "Pill", 4, size + 6, size - 8, 22, offer.ribbonColor, 11)
	ribbon.ZIndex = 6
	W.stroke(ribbon, W.navy, 2.5)
	local text = W.title(ribbon, offer.ribbon, 0, 0, size - 8, 21, 15, W.white)
	text.ZIndex = 7
	W.navyText(text, 1.8)
	button.Activated:Connect(function() self:open(offer) end)
	return { button = button, pulse = pulse, pill = text, offer = offer }
end

-- The offer card.
function Offers:buildCard()
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "Featured offer", false, 32, true
	gui.ZIndexBehavior, gui.Enabled = Enum.ZIndexBehavior.Sibling, false
	gui.Parent = self.player:WaitForChild("PlayerGui")
	self.gui = gui
	local shade = Instance.new("TextButton")
	shade.Name, shade.Text, shade.AutoButtonColor = "Shade", "", false
	shade.Size, shade.BackgroundColor3, shade.BackgroundTransparency = UDim2.fromScale(1, 1), W.ink, 0.35
	shade.Parent = gui
	shade.Activated:Connect(function() self:close() end)
	local card = W.frame(gui, "Offer", 0, 0, 560, 380, W.white, 24)
	W.anchor(card, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	self.paint = W.enamelPanel(card, rgb(255, 200, 120), rgb(214, 96, 40), 24)
	self.scale = W.scale(card)
	self.card = card
	local clip = W.frame(card, "Glow", 4, 4, 552, 372, W.white, 20)
	self.clip = clip
	clip.BackgroundTransparency, clip.ClipsDescendants = 1, true
	local spin = W.frame(clip, "Rays", 140, 190, 0, 0, W.white)
	spin.BackgroundTransparency = 1
	local _, hub = Burst.rays(spin, 0, 0, 380, 12, W.white, 0.8)
	self.rayLines = hub:GetChildren()
	self.rays = spin
	local shine = W.frame(clip, "Shine", -80, -40, 60, 520, W.white)
	shine.Rotation, shine.BackgroundTransparency = 18, 0.82
	self.shine = shine
	-- A header band (the Starter Pack's): its name and a line under it.
	local band = W.frame(card, "Header", 0, 0, 560, 84, W.white, 24)
	self.bandPaint = W.enamelPanel(band, rgb(255, 120, 180), rgb(200, 50, 120), 24)
	self.bandName = W.title(band, "", 26, 8, 440, 44, 36, W.white, true)
	W.navyText(self.bandName, 3.4)
	self.bandSub = W.title(band, "", 28, 50, 440, 26, 18, rgb(255, 244, 170), true)
	W.navyText(self.bandSub, 2)
	self.band = band
	self.title = W.title(card, "", 0, -22, 560, 44, 34, rgb(255, 244, 170))
	W.navyText(self.title, 3.6)
	local close = W.closeButton(card, 500, 12, 46)
	close.ZIndex = 8
	close.Activated:Connect(function() self:close() end)
	-- The special layout (art on the left, lines on the right).
	local special = W.frame(card, "Special", 0, 0, 560, 380, W.ink)
	special.BackgroundTransparency = 1
	self.special = special
	self.artHolder = W.frame(special, "Art holder", 24, 60, 220, 220, W.ink)
	self.artHolder.BackgroundTransparency = 1
	self.name = W.title(special, "", 264, 40, 240, 44, 32, W.white, true)
	W.navyText(self.name, 3.2)
	W.largest(self.name, 32, 18)
	self.lineHolder = W.frame(special, "Lines", 264, 92, 284, 130, W.ink)
	self.lineHolder.BackgroundTransparency = 1
	local track = W.frame(special, "Stock", 264, 226, 276, 24, W.navy, 12)
	W.stroke(track, W.navy, 3)
	self.stockFill = W.frame(track, "Fill", 0, 0, 0, 24, W.white, 12)
	W.gradient(self.stockFill, rgb(255, 230, 120), rgb(255, 120, 60), 0)
	self.stockText = W.title(track, "", 0, 0, 276, 24, 15, W.white)
	self.stockText.ZIndex = 5
	W.navyText(self.stockText, 1.8)
	self.stock = track
	-- The price: struck-through reference, percent off and a big green Robux button.
	self.was = W.title(card, "", 264, 256, 276, 26, 19, rgb(255, 225, 230))
	self.was.RichText = true
	W.navyText(self.was, 2)
	local buy = W.clearButton(card, "Buy", 264, 290, 276, 66, "Select")
	self.buy = buy
	W.round(buy, 16)
	local paint = W.enamelPanel(buy, rgb(110, 214, 88), rgb(38, 150, 62), 16)
	paint.Color = ColorSequence.new(rgb(110, 214, 88), rgb(38, 150, 62))
	local _, amount = W.robux(buy, 0, 38)
	self.amount = amount
	self.buyPulse = W.scale(buy)
	buy.Activated:Connect(function()
		local offer = self.offer
		if not offer then return end
		self:close()
		self.hud.checkout:buy("product", offer.item)
	end)
	-- Offers with crates in them link to the crate's odds, before anyone pays.
	local odds = W.clearButton(card, "Crate odds", 264, 362, 276, 28, "Select")
	local oddsText = W.title(odds, "See the crate odds ▸", 0, 0, 276, 28, 18, rgb(255, 244, 170))
	W.navyText(oddsText, 2)
	odds.Activated:Connect(function()
		self:close()
		self.hud:openPage("Shop")
		task.defer(function()
			local shop = self.hud.menu.shop
			if shop then shop:showOdds(require(Shared.Geodes).main) end
		end)
	end)
	self.odds = odds
	Run.RenderStepped:Connect(function()
		if not gui.Enabled then return end
		local t = os.clock()
		-- The Founder's Halo card turns its rays slowly and has no sweeping shine.
		local calm = self.offer and self.offer.preview ~= nil
		spin.Rotation = (t * (if calm then 5 else 25)) % 360
		shine.Visible = not calm
		shine.Position = UDim2.fromOffset(((t * 260) % 1100) - 160, -40)
		self.buyPulse.Scale = 1 + 0.035 * math.sin(t * 4)
	end)
end

function Offers:available(offer)
	local item = offer.item
	if offer.key == "StarterPack" then return not self.player:GetAttribute("StarterBought") end
	if item.cosmetic then
		local col = Bonuses.decode(self.player:GetAttribute("Collection")) or {}
		if (col.cos or {})[item.cosmetic.id] then return false end
	end
	if item.limited and (Rep:GetAttribute("Limited" .. item.key) or item.limited) <= 0 then return false end
	return true
end

-- A column (beside the right-hand rail), or on phones a row running left from the Shop button.
function Offers:refresh()
	local y, x = 0, 0
	for _, offer in offers do
		local tile = self.tiles[offer.key]
		local shown = self:available(offer)
		tile.button.Visible = shown
		if shown then
			if self.horizontal then
				x -= tile.button.Size.X.Offset + 14
				tile.button.Position = UDim2.fromOffset(x, 0)
			else
				tile.button.Position = UDim2.fromOffset(0, y)
				y += tile.button.Size.Y.Offset + 14
			end
		end
		local item = offer.item
		tile.pill.Text = if item.limited then W.goldAmount(Rep:GetAttribute("Limited" .. item.key) or item.limited) .. " LEFT" else offer.ribbon
	end
	if self.offer and self.gui.Enabled then self:fill(self.offer) end
end

function Offers:fill(offer)
	local item = offer.item
	-- Forget art from the last time the card was filled.
	local kept = {}
	for _, bob in self.bobbers do
		if bob.Parent then table.insert(kept, bob) end
	end
	self.bobbers = kept
	self.paint.Color = ColorSequence.new(offer.tint[1], offer.tint[2])
	-- The Founder's Halo: faint rays, so the aura stands out.
	local calm = offer.preview ~= nil
	for _, ray in self.rayLines or {} do
		ray.BackgroundTransparency = if calm then 0.94 else 0.86
	end
	-- With a header band, the name sits in it and everything else moves down to give it room.
	local header = offer.header ~= nil
	local top = if header then 96 else 0
	self.band.Visible = header
	self.title.Visible = not header
	self.title.Text = offer.title
	self.bandName.Text, self.bandSub.Text = item.name, offer.header or ""
	local extra = if item.random then 34 else 0
	self.card.Size = UDim2.fromOffset(560, (if header then 420 else 380) + extra)
	self.clip.Size = UDim2.fromOffset(552, (if header then 412 else 372) + extra)
	self.odds.Visible = item.random == true
	self.odds.Position = UDim2.fromOffset(264, if header then 390 else 360)
	self.name.Visible = not header
	self.name.Text = item.name
	self.rays.Position = UDim2.fromOffset(140, 190 + top / 2)
	self.artHolder.Position = UDim2.fromOffset(24, if header then 110 else 60)
	self.artHolder.Size = UDim2.fromOffset(if header then 200 else 220, if header then 200 else 220)
	self.lineHolder.Position = UDim2.fromOffset(264, if header then 112 else 92)
	self.stock.Position = UDim2.fromOffset(264, 226)
	self.was.Position = UDim2.fromOffset(264, if header then 284 else 256)
	self.buy.Position = UDim2.fromOffset(264, if header then 318 else 290)
	self.artHolder:ClearAllChildren()
	if offer.preview then
		FxPreview.new(self.artHolder, offer.preview[1], offer.preview[2], 0, 0, 220)
	else
		bobber(self, self.artHolder, offer.art, 10, 10, 180)
	end
	self.lineHolder:ClearAllChildren()
	local step = if header then 52 else 42
	for i, line in offer.lines or {} do
		local y = (i - 1) * step
		Icons.draw(self.lineHolder, line[1], 0, y, if header then 42 else 36)
		local text = W.title(self.lineHolder, W.rich(line[2]), 50, y, 234, if header then 42 else 36, if header then 22 else 19, W.white, true)
		text.RichText = true
		W.navyText(text, 2)
		W.largest(text, if header then 22 else 19, 12)
	end
	self.lineHolder.Size = UDim2.fromOffset(284, step * 3)
	local left = if item.limited then Rep:GetAttribute("Limited" .. item.key) or item.limited else nil
	self.stock.Visible = left ~= nil
	if left then
		self.stockFill.Size = UDim2.new(math.clamp(left / item.limited, 0, 1), 0, 1, 0)
		self.stockText.Text = W.goldAmount(left) .. " / " .. W.goldAmount(item.limited) .. " left"
	end
	local off = S.off(item)
	self.was.Text = if item.was then "Worth " .. W.goldAmount(item.was) .. " Robux  " .. W.colored("-" .. off .. "%", speedGreen) else ""
	self.amount.Text = tostring(item.price)
end

function Offers:open(offer)
	self.offer = offer
	self:fill(offer)
	local area = workspace.CurrentCamera.ViewportSize
	self.scale.Scale = math.clamp(math.min(area.X / 640, area.Y / 470), 0.5, 1.3)
	self.gui.Enabled = true
	if Burst.allowed(self.player) then
		local rest = self.scale.Scale
		self.scale.Scale = rest * 0.7
		W.tween(self.scale, 0.22, { Scale = rest })
	end
end

function Offers:close()
	self.gui.Enabled = false
end

return Offers
