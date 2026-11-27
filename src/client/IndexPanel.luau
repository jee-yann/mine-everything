-- The ore index: a Collection of everything this miner has found, with their own records, and the Odds
-- of finding each ore by depth.
local Shared = game:GetService("ReplicatedStorage").Shared
local Ores, Config, Purity = require(Shared.Ores), require(Shared.GameConfig), require(Shared.OrePurity)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local Drawn = require(script.Parent.DrawnFaces)
local Bonuses = require(Shared.Bonuses)
local Panel = {}
Panel.__index = Panel
local rgb = Color3.fromRGB
local blue = { rgb(134, 214, 255), rgb(47, 130, 230) }
local rarities = {
	Common = rgb(214, 220, 235), Uncommon = rgb(120, 230, 120), Rare = rgb(90, 190, 255), Epic = rgb(200, 130, 255),
	Legendary = rgb(255, 196, 60), Mythic = rgb(255, 96, 130), Celestial = rgb(120, 255, 240),
}
local function readable(color)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, math.min(s, 0.7), math.max(v, 0.8))
end
local function fit(label, max)
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize, limit.Parent = 10, max, label
	return label
end
-- The shallowest region an ore turns up in, for "Found in".
local homes = {}
for _, layer in Config.Layers do
	for name in layer.oreChances do
		homes[name] = homes[name] or layer.name
	end
end
homes.Stone, homes.Dirt = "Every region", "The first layer"

-- The ore's drawn pieces on rock of its colour, or a cut crystal when pictures can't be shown.
local function picture(parent, ore, size)
	local well = W.frame(parent, "Ore", 0, 0, size, size, W.white)
	well.BackgroundTransparency = 1
	W.anchor(well, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	local image = Drawn.picture(ore.name)
	local label
	if image then
		label = Instance.new("ImageLabel")
		label.Name, label.Size, label.BackgroundTransparency = "Picture", UDim2.fromScale(1, 1), 1
		if pcall(function() label.ImageContent = image end) then
			if ore.host then
				W.round(label, size // 6)
				if ore.name == "Stone" then label.ImageColor3 = ore.color:Lerp(W.white, 0.25) end
			end
			label.Parent = well
		else
			label = nil
		end
	end
	if not label then
		Icons.draw(well, "Crystal", 0, 0, size, ore.color)
	end
	return well, label
end

function Panel.new(menu)
	local self = setmetatable({ menu = menu, cards = {} }, Panel)
	local card = Card.new(menu, "Ore index", "Book", "Ore Index", blue)
	self.card = card
	card:useTabs()
	card:tab("Collection", "Collection", "Book", function() self:show("Collection") end)
	card:tab("Odds", "Odds", "Crystal", function() self:show("Odds") end)
	self:buildCollection()
	self:buildOdds()
	self:show("Collection")
	task.spawn(function()
		while card.modal.Parent do
			task.wait(0.12)
			self:observe(os.clock())
		end
	end)
	return self
end

function Panel:buildCollection()
	local page = W.frame(self.card.body, "Collection", 7, 7, 764, 358, W.panel)
	page.BackgroundTransparency = 1
	self.collection = page
	-- The chosen ore, with this miner's own records.
	local side = W.frame(page, "Chosen ore", 2, 2, 232, 318, W.white, 16)
	self.sidePaint = W.enamelPanel(side, rgb(207, 174, 255), rgb(129, 80, 230), 16)
	local stage = W.frame(side, "Stage", 11, 11, 210, 122, W.white, 12)
	stage.ClipsDescendants = true
	self.stagePaint = W.enamelPanel(stage, rgb(255, 214, 150), rgb(236, 140, 66), 12)
	Card.rays(stage, 105, 61, 150, 8)
	self.stage = stage
	self.oreName = fit(W.title(side, "", 8, 138, 216, 34, 30, W.white), 30)
	W.navyText(self.oreName, 3)
	local pill = W.frame(side, "Rarity", 46, 173, 140, 25, W.navy, 12)
	self.rarity = W.title(pill, "", 0, 0, 140, 24, 18, W.white)
	self.stats = {}
	for i, key in { "Mined", "Best purity", "Worth", "Found in" } do
		local row = W.frame(side, key, 10, 203 + (i - 1) * 27, 212, 25, W.navy, 8)
		row.BackgroundTransparency = 0.45
		W.text(row, key, 8, 0, 90, 25, 15, W.white, true)
		local value = fit(W.title(row, "", 92, 1, 113, 23, 17, W.gold), 17)
		value.TextXAlignment = Enum.TextXAlignment.Right
		self.stats[key] = value
	end
	self.list = Card.scroller(page, "Ores", 246, 0, 518, 322)
	for i, ore in Ores.list do
		local x, y = (i - 1) % 5 * 101 + 3, math.floor((i - 1) / 5) * 112 + 3
		local button = W.clearButton(self.list, ore.name, x, y, 93, 104, "Select")
		W.round(button, 13)
		local paint = W.enamelPanel(button, Card.slate[1], Card.slate[2], 13)
		local well = W.frame(button, "Picture", 14, 8, 65, 65, W.white)
		well.BackgroundTransparency = 1
		local number = W.frame(button, "Number", -3, -3, 30, 24, rarities[ore.rarity], 8)
		W.stroke(number, W.navy, 2.5)
		W.title(number, tostring(i), 0, 0, 30, 24, 15, W.navy)
		local name = fit(W.title(button, "", 4, 75, 85, 24, 17, W.white), 17)
		W.navyText(name, 2.2)
		local chosen = W.frame(button, "Selected", -2, -2, 97, 108, W.white, 14)
		chosen.BackgroundTransparency, chosen.Visible = 1, false
		W.stroke(chosen, W.white, 4)
		local fresh = W.dot(button, -12, -4)
		self.cards[ore.name] = { ore = ore, button = button, paint = paint, well = well, name = name, chosen = chosen, fresh = fresh }
		button.Activated:Connect(function()
			self:choose(ore)
		end)
	end
	self.list.CanvasSize = UDim2.fromOffset(0, math.ceil(#Ores.list / 5) * 112 + 4)
	local bar = W.frame(page, "Progress", 6, 330, 752, 24, rgb(24, 22, 48), 12)
	W.stroke(bar, rgb(255, 246, 214), 3)
	self.barFill = W.frame(bar, "Found", 0, 0, 0, 24, W.white, 12)
	W.gradient(self.barFill, rgb(255, 230, 128), rgb(243, 165, 26), 90)
	self.barLabel = W.title(bar, "", 0, 0, 752, 23, 18, W.white)
	self.barLabel.ZIndex = 3
	W.navyText(self.barLabel, 2.4)
end

function Panel:buildOdds()
	local list = Card.scroller(self.card.body, "Odds", 7, 7, 764, 358)
	self.oddsList, self.layerCards = list, {}
	local y = 3
	for i, layer in Config.Layers do
		local entries, total = { { ore = Ores.byName.Stone } }, 0
		for _, ore in Ores.list do
			local chance = layer.oreChances[ore.name]
			if chance then
				total += chance
				table.insert(entries, { ore = ore, chance = chance })
			end
		end
		entries[1].chance = math.floor((100 - total) * 10 + 0.5) / 10
		local rows = math.ceil(#entries / 5)
		-- Starfall's listed chance is for the crater's first row; it rises from there.
		local deeper = layer.oreChances.Starfall
		local height = 70 + rows * 46 + (if deeper then 30 else 0)
		local panel = W.frame(list, layer.name, 3, y, 744, height, W.white, 15)
		local base = layer.color or rgb(120, 120, 160)
		W.enamelPanel(panel, base:Lerp(rgb(120, 112, 190), 0.55), base:Lerp(rgb(58, 54, 104), 0.72), 15)
		W.navyText(W.title(panel, layer.name, 16, 7, 420, 32, 27, W.white, true), 2.6)
		local following = Config.Layers[i + 1]
		local start = math.max(Config.DirtLayers, layer.depthBlocks)
		local depth = W.title(panel, if following then string.format("%d–%d blocks", start, following.depthBlocks - 1)
			else string.format("%d+ blocks", start), 430, 8, 298, 30, 22, rgb(255, 240, 150))
		depth.Name, depth.TextXAlignment = "Depth", Enum.TextXAlignment.Right
		W.navyText(depth, 2.4)
		if layer.theme then
			local theme = W.text(panel, layer.theme, 17, 38, 710, 22, 16, W.white, true)
			theme.Name = "Theme"
		end
		local chips = {}
		for k, entry in entries do
			local chip = W.frame(panel, entry.ore.name, 14 + (k - 1) % 5 * 144, 66 + math.floor((k - 1) / 5) * 46, 138, 40, W.navy, 10)
			chip.BackgroundTransparency = 0.35
			local swatch = W.frame(chip, "Swatch", 8, 9, 22, 22, entry.ore.color, 6)
			W.stroke(swatch, W.navy, 2)
			local name = fit(W.title(chip, "", 36, 1, 98, 20, 16, W.white, true), 16)
			local odds = W.title(chip, string.format("%g%%", entry.chance), 36, 19, 98, 19, 16, W.gold, true)
			odds.Name, odds.TextScaled = "Chance", true
			local oddsFont = Instance.new("UITextSizeConstraint")
			oddsFont.MinTextSize, oddsFont.MaxTextSize, oddsFont.Parent = 9, 16, odds
			table.insert(chips, { ore = entry.ore, name = name, swatch = swatch, odds = odds, chance = entry.chance })
		end
		if deeper then
			local note = W.text(panel, string.format(
				"★ Starfall odds rise the deeper you go: +%g%% every 100 blocks past %d",
				Config.StarfallDeeper * 100 * 100, start), 17, 64 + rows * 46, 710, 26, 18, rgb(232, 214, 255), true)
			note.Name, note.TextScaled = "Deeper", true
			local size = Instance.new("UITextSizeConstraint")
			size.MinTextSize, size.MaxTextSize, size.Parent = 10, 18, note
		end
		local chances = { Stone = math.max(0, 100 - total) }
		for name, chance in layer.oreChances do chances[name] = chance end
		self.layerChances = self.layerChances or {}
		table.insert(self.layerCards, chips)
		self.layerChances[#self.layerCards] = chances
		y += height + 10
	end
	local grades = W.frame(list, "Rock hardness", 3, y, 744, 60 + math.ceil(#Config.StoneGrades / 3) * 40, W.white, 15)
	W.enamelPanel(grades, rgb(150, 154, 176), rgb(72, 70, 110), 15)
	W.navyText(W.title(grades, "Stone grades", 16, 7, 420, 32, 27, W.white, true), 2.6)
	for power, grade in Config.StoneGrades do
		local x, gy = 14 + (power - 1) % 3 * 240, 48 + math.floor((power - 1) / 3) * 40
		local chip = W.frame(grades, grade.name, x, gy, 234, 34, W.navy, 10)
		chip.BackgroundTransparency = 0.35
		W.stroke(W.frame(chip, "Swatch", 8, 7, 20, 20, grade.color, 5), W.navy, 2)
		W.title(chip, grade.name, 36, 0, 126, 34, 16, W.white, true)
		W.text(chip, "P" .. power .. " · " .. grade.depth .. "+", 158, 0, 70, 34, 15, W.gold)
	end
	y += grades.Size.Y.Offset + 6
	list.CanvasSize = UDim2.fromOffset(0, y)
end

function Panel:show(tab)
	self.tab = tab
	self.collection.Visible, self.oddsList.Visible = tab == "Collection", tab == "Odds"
	self.card:select(tab)
	self:refresh()
end
-- A new ore counts as read once its card has been on screen for a moment. Its mark stays until the
-- index is opened again.
function Panel:observe(now)
	if not self.card.modal.Visible or self.tab ~= "Collection" then return end
	local player = self.menu.player
	local top = self.list.AbsolutePosition.Y
	local bottom = top + self.list.AbsoluteWindowSize.Y
	for name, entry in self.cards do
		if entry.sent or not player:GetAttribute("Found" .. name) or player:GetAttribute("SeenBook" .. name) then
			continue
		end
		local mid = entry.button.AbsolutePosition.Y + entry.button.AbsoluteSize.Y / 2
		if mid < top or mid > bottom then
			entry.since = nil
			continue
		end
		entry.since = entry.since or now
		if now - entry.since >= 0.35 then
			entry.sent = true
			self.menu.net.Action:FireServer("Viewed", "Book", name)
		end
	end
end
function Panel:open()
	for _, entry in self.cards do
		entry.sent, entry.since, entry.clicked = nil, nil, nil
	end
	if not self.chosen then
		-- Start on the rarest ore this miner has found.
		local best
		for _, ore in Ores.list do
			if self.menu.player:GetAttribute("Found" .. ore.name) and (not best or Ores.rarityRank[ore.rarity] >= Ores.rarityRank[best.rarity]) then
				best = ore
			end
		end
		self:choose(best or Ores.list[1])
	end
	-- Pictures are decoded a few at a time, so the menu opens at once.
	if not self.painting then
		self.painting = true
		task.spawn(function()
			for _, ore in Ores.list do
				local entry = self.cards[ore.name]
				entry.picture, entry.image = picture(entry.well, ore, 60)
				self:paintCard(entry)
				task.wait()
			end
		end)
	end
end

function Panel:paintCard(entry)
	local found = self.menu.player:GetAttribute("Found" .. entry.ore.name) == true
	entry.name.Text = if found then entry.ore.name else "???"
	local tint = readable(entry.ore.color)
	entry.paint.Color = if found
		then ColorSequence.new(tint:Lerp(W.white, 0.25), tint:Lerp(W.navy, 0.35))
		else ColorSequence.new(Card.slate[1], Card.slate[2])
	if entry.image then
		entry.image.ImageColor3 = if not found then rgb(14, 12, 30)
			elseif entry.ore.name == "Stone" then entry.ore.color:Lerp(W.white, 0.25) else W.white
	elseif entry.picture then
		entry.picture.Visible = found
	end
	entry.fresh.Visible = found and not entry.clicked
		and (entry.sent or not self.menu.player:GetAttribute("SeenBook" .. entry.ore.name)) == true
end

function Panel:choose(ore)
	self.chosen = ore
	-- Opening an ore's card reads it: its red dot goes at once.
	local picked = self.cards[ore.name]
	if picked then
		picked.clicked = true
		picked.fresh.Visible = false
		if not picked.sent and self.menu.player:GetAttribute("Found" .. ore.name) and not self.menu.player:GetAttribute("SeenBook" .. ore.name) then
			picked.sent = true
			self.menu.net.Action:FireServer("Viewed", "Book", ore.name)
		end
	end
	for name, entry in self.cards do
		entry.chosen.Visible = name == ore.name
	end
	for _, child in self.stage:GetChildren() do
		if child.Name == "Ore" then child:Destroy() end
	end
	local _, image = picture(self.stage, ore, 108)
	self.stageImage = image
	self:refresh()
end

function Panel:refresh()
	local player = self.menu.player
	local found, total = 0, #Ores.list
	for _, ore in Ores.list do
		if player:GetAttribute("Found" .. ore.name) then found += 1 end
	end
	self.card.sub.Text = player.DisplayName .. "'s collection  ·  " .. found .. " / " .. total .. " found"
	if self.tab == "Odds" then
		-- Odds with this miner's luck: ores rarer than 1% are multiplied, the rest share what's left.
		local luck = Bonuses.luck(Bonuses.state(player))
		if luck > 1 then
			self.card.sub.Text = string.format("Your luck: %g×  ·  ores rarer than 1%% are shown with it", math.floor(luck * 100 + 0.5) / 100)
		end
		for i, chips in self.layerCards do
			local shown = Bonuses.lucky(self.layerChances[i], luck)
			for _, chip in chips do
				local value = shown[chip.ore.name] or chip.chance
				local boosted = luck > 1 and chip.chance < Bonuses.rareBelow
				-- A boosted chance shows the usual one struck through beside it: "0.05% → 0.1%".
				chip.odds.RichText = true
				chip.odds.Text = if boosted then string.format('<font color="#C8C8DC"><s>%g%%</s></font> %.3g%%', chip.chance, value)
					elseif luck > 1 then string.format("%.3g%%", value)
					else string.format("%g%%", chip.chance)
				chip.odds.TextColor3 = if boosted then W.green else W.gold
				local hidden = chip.ore.secret and not player:GetAttribute("Found" .. chip.ore.name)
				chip.name.Text = if hidden then "???" else chip.ore.name
				chip.name.TextColor3 = if hidden then W.white else readable(chip.ore.color)
				chip.swatch.BackgroundColor3 = if hidden then W.navy else chip.ore.color
			end
		end
		return
	end
	self.barFill.Size, self.barLabel.Text = UDim2.fromScale(found / total, 1), found .. " / " .. total .. " ores found"
	for _, entry in self.cards do
		self:paintCard(entry)
	end
	local ore = self.chosen
	if not ore then return end
	local known = player:GetAttribute("Found" .. ore.name) == true
	local tint = readable(ore.color)
	self.oreName.Text = if known or not ore.secret then ore.name else "???"
	self.rarity.Text, self.rarity.TextColor3 = ore.rarity, rarities[ore.rarity]
	self.stagePaint.Color = if known then ColorSequence.new(tint:Lerp(W.white, 0.4), tint:Lerp(W.navy, 0.2)) else ColorSequence.new(Card.slate[1], Card.slate[2])
	if self.stageImage then
		self.stageImage.ImageColor3 = if not known then rgb(14, 12, 30)
			elseif ore.name == "Stone" then ore.color:Lerp(W.white, 0.25) else W.white
	end
	local best = player:GetAttribute("BestPurity" .. ore.name) or 0
	self.stats.Mined.Text = if known then "×" .. W.goldAmount(player:GetAttribute("Lifetime" .. ore.name) or 0) else "Not yet"
	self.stats["Best purity"].Text = if ore.host then "–" elseif best > 0 then Purity.text(best) else "–"
	self.stats.Worth.Text = if known or not ore.secret then W.possiblePrice(ore, player) else "???"
	self.stats["Found in"].Text = if known or not ore.secret then homes[ore.name] or "Deep" else ore.hint or "???"
end

return Panel
