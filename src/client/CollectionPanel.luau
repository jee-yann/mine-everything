-- Pets & Collection: every pet, trail and aura (owned ones in colour, the rest showing where they come
-- from), the item bag, and the Forge, where ore, Geode Dust and gems craft a chosen reward for sure.
-- Up to three pets follow at once; their bonuses add up within the caps shown.
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Geodes, Recipes = require(Shared.Collectibles), require(Shared.Geodes), require(Shared.Recipes)
local Bonuses, Ores, Guide = require(Shared.Bonuses), require(Shared.Ores), require(Shared.FieldGuide)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local Models = require(script.Parent.PetModels)
local Reveal = require(script.Parent.GeodeReveal)
local Panel = {}
Panel.__index = Panel
local rgb = Color3.fromRGB
local violet = { rgb(207, 174, 255), rgb(129, 80, 230) }
local order = { "Pets", "Trails", "Auras", "Items", "Forge" }
local tabIcons = { Pets = "Pets", Trails = "Trail", Auras = "Gems", Items = "Boosts", Forge = "Forge" }
local tints = {
	Pets = violet,
	Trails = { rgb(255, 230, 128), rgb(243, 165, 26) },
	Auras = { rgb(134, 214, 255), rgb(47, 130, 230) },
	Items = { rgb(166, 245, 154), rgb(52, 178, 74) },
	Forge = { rgb(255, 208, 138), rgb(240, 138, 58) },
}
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
local grey = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local goldPaint = ColorSequence.new(rgb(255, 226, 120), rgb(240, 150, 30))
local redPaint = ColorSequence.new(rgb(255, 150, 150), rgb(214, 52, 78))
local unmet = rgb(255, 141, 137)

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
	W.largest(label, size, 11)
	return button, paint, label
end
local function set(button, paint, label, text, color, enabled)
	label.Text, paint.Color = text, color
	button.Interactable, button.AutoButtonColor = enabled, enabled
end
local function rarityTint(rarity, owned)
	local color = C.rarities[rarity].color
	if not owned then return { rgb(110, 108, 140), rgb(70, 68, 100) } end
	return { color:Lerp(W.white, 0.2), color:Lerp(rgb(40, 30, 70), 0.45) }
end

-- Where something can be found: geodes, the Forge, a pass or the starter gift.
local function sources(kind, id)
	local out = {}
	for _, geode in Geodes.list do
		for _, reward in geode.pool do
			if reward.kind == kind and reward.id == id then
				table.insert(out, geode.name)
				break
			end
		end
	end
	for _, recipe in Recipes.list do
		if recipe.give.kind == kind and recipe.give.id == id then table.insert(out, "Forge") end
	end
	local entry = C.find(kind, id)
	if entry.pass then table.insert(out, "the " .. entry.pass:gsub("(%l)(%u)", "%1 %2") .. " pass") end
	if entry.starter then table.insert(out, "every miner's first pet") end
	if kind == "pet" and id == "Drake" then table.insert(out, "drake eggs deep in the mine") end
	return if #out == 0 then "—" else table.concat(out, ", ")
end

function Panel.new(menu)
	local self = setmetatable({ menu = menu, player = menu.player, net = menu.net, updates = {}, pages = {}, tabs = {}, selected = {} }, Panel)
	local card = Card.new(menu, "Collection", "Pets", "Pets", violet)
	self.card = card
	card:useTabs()
	for i, key in order do
		local b = W.clearButton(card.modal, key .. " tab", 14 + (i - 1) * 154, 88, 148, 46, "Select")
		W.round(b, 14)
		local paint = W.enamelPanel(b, Card.slate[1], Card.slate[2], 14)
		Icons.draw(b, tabIcons[key], 8, 7, 32)
		local label = W.title(b, key, 42, 0, 100, 44, 21, W.white, true)
		W.navyText(label, 2.4)
		self.tabs[key] = paint
		b.Activated:Connect(function() menu:open(if key == "Pets" then "Pets" else key) end)
		local page = W.frame(card.body, key, 7, 7, 764, 358, W.panel)
		page.BackgroundTransparency, page.Visible = 1, false
		self.pages[key] = page
	end
	self:buildPets()
	self:buildCosmetics("Trails", "trail", C.trails)
	self:buildCosmetics("Auras", "aura", C.auras)
	self:buildItems()
	self:buildForge()
	return self
end

function Panel:col()
	return Bonuses.decode(self.player:GetAttribute("Collection")) or {}
end

-- A grid of tiles on the left of a page and a detail pane on the right.
function Panel:grid(page, entries, kind, onPick)
	local list = Card.scroller(page, "Grid", 0, 0, 456, 358)
	local tiles = {}
	for i, entry in entries do
		local x, y = (i - 1) % 4 * 112, math.floor((i - 1) / 4) * 112
		local b = W.clearButton(list, entry.id, x, y, 106, 106, "Select")
		W.round(b, 14)
		local paint = W.enamelPanel(b, rgb(110, 108, 140), rgb(70, 68, 100), 14)
		local holder = W.frame(b, "Look", 13, 4, 80, 74, W.ink)
		holder.BackgroundTransparency = 1
		if kind == "pet" then
			local view = Instance.new("ViewportFrame")
			view.BackgroundTransparency, view.Size, view.ZIndex = 1, UDim2.fromScale(1, 1), 3
			view.Parent = holder
			Models.preview(view, entry.id)
		else
			Icons.draw(holder, if kind == "trail" then "Trail" else "Gems", 6, 2, 68)
			local swatch = W.frame(holder, "Colour", 6, 66, 68, 8, W.white, 4)
			local colors = entry.colors or { entry.color, entry.color:Lerp(W.white, 0.5) }
			W.gradient(swatch, colors[1], colors[2], 0)
		end
		local name = words(b, entry.name, 4, 76, 98, 26, 15)
		W.largest(name, 15, 9)
		local mark = words(b, "", 70, 2, 34, 24, 16, rgb(190, 255, 150))
		b.Activated:Connect(function() onPick(entry) end)
		tiles[entry.id] = { paint = paint, mark = mark, button = b, holder = holder }
	end
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(#entries / 4) * 112)
	local pane, panePaint = box(page, "Detail", 466, 0, 298, 358, violet)
	return tiles, pane, panePaint
end

function Panel:buildPets()
	local page = self.pages.Pets
	local tiles, pane, panePaint
	tiles, pane, panePaint = self:grid(page, C.pets, "pet", function(entry)
		self.selected.Pets = entry.id
		self:refresh()
	end)
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency, view.Position, view.Size, view.ZIndex = 1, UDim2.fromOffset(74, 6), UDim2.fromOffset(150, 110), 3
	view.Parent = pane
	local name = words(pane, "", 8, 112, 282, 30, 25)
	W.largest(name, 25, 14)
	local rarity = words(pane, "", 8, 140, 282, 20, 16)
	local stats = words(pane, "", 12, 162, 274, 44, 16, rgb(255, 250, 215))
	stats.TextWrapped = true
	local track = W.frame(pane, "XP", 18, 208, 262, 16, W.navy, 8)
	W.stroke(track, W.navy, 3)
	local fill = W.frame(track, "Fill", 0, 0, 0, 16, W.white, 8)
	W.gradient(fill, rgb(190, 255, 150), rgb(62, 178, 52), 90)
	local xp = words(track, "", 0, 0, 262, 16, 13)
	local equip, equipPaint, equipLabel = press(pane, "Equip", 12, 232, 274, 42, 21)
	local snack, snackPaint, snackLabel = press(pane, "Snack", 12, 280, 134, 36, 16)
	local feast, feastPaint, feastLabel = press(pane, "Feast", 152, 280, 134, 36, 16)
	local nameBox = Instance.new("TextBox")
	nameBox.Name, nameBox.Position, nameBox.Size = "Pet name", UDim2.fromOffset(12, 320), UDim2.fromOffset(200, 32)
	nameBox.BackgroundColor3, nameBox.TextColor3, nameBox.Font, nameBox.TextSize = W.navy, W.white, Enum.Font.FredokaOne, 16
	nameBox.PlaceholderText, nameBox.ClearTextOnFocus, nameBox.ZIndex = "Name your lead pet", false, 4
	W.round(nameBox, 8)
	nameBox.Parent = pane
	local rename, renamePaint, renameLabel = press(pane, "Rename", 218, 320, 68, 32, 15)
	renamePaint.Color, renameLabel.Text = goldPaint, "Save"
	rename.Activated:Connect(function() self.net.Action:FireServer("PetName", nameBox.Text) end)
	local shownPreview
	equip.Activated:Connect(function()
		local id = self.selected.Pets
		local col = self:col()
		if id and (col.pets or {})[id] then
			self.net.Action:FireServer("EquipPet", id, not table.find(col.eq or {}, id))
		end
	end)
	snack.Activated:Connect(function() self.net.Action:FireServer("UseItem", "Snack") end)
	feast.Activated:Connect(function() self.net.Action:FireServer("UseItem", "Feast") end)
	table.insert(self.updates, function()
		local col = self:col()
		local pets, eq = col.pets or {}, col.eq or {}
		self.selected.Pets = self.selected.Pets or eq[1] or "Rock"
		for _, entry in C.pets do
			local tile = tiles[entry.id]
			local owned = pets[entry.id]
			local tint = rarityTint(entry.rarity, owned)
			tile.paint.Color = ColorSequence.new(tint[1], tint[2])
			tile.mark.Text = if table.find(eq, entry.id) then "✓" elseif owned and owned.s > 0 then string.rep("★", owned.s) else ""
			tile.holder.Visible = true
			for _, child in tile.holder:GetDescendants() do
				if child:IsA("ViewportFrame") then child.ImageColor3 = if owned then W.white else rgb(40, 40, 60) end
			end
		end
		local id = self.selected.Pets
		local entry, owned = C.petById[id], pets[id]
		if shownPreview ~= id then
			shownPreview = id
			Models.preview(view, id)
		end
		view.ImageColor3 = if owned then W.white else rgb(40, 40, 60)
		local tint = rarityTint(entry.rarity, true)
		panePaint.Color = ColorSequence.new(tint[1], tint[2])
		name.Text = entry.name
		rarity.Text = entry.rarity .. (if owned and owned.s > 0 then "  " .. string.rep("★", owned.s) else "")
		local level, stars = if owned then owned.l else 1, if owned then owned.s else 0
		local bonus = C.petBonus(entry, level, stars)
		stats.Text = string.format("+%s%% %s  ·  Level %d / %d", string.format("%.1f", bonus * 100):gsub("%.0$", ""), C.bonusText[entry.bonus], level, C.maxPetLevel)
		if not owned then stats.Text ..= "\nFound in: " .. sources("pet", id) end
		track.Visible = owned ~= nil
		if owned then
			local need = C.petXpFor(owned.l)
			local share = if owned.l >= C.maxPetLevel then 1 else math.clamp(owned.x / need, 0, 1)
			fill.Size = UDim2.new(share, 0, 1, 0)
			xp.Text = if owned.l >= C.maxPetLevel then "Max level" else W.number(owned.x) .. " / " .. W.number(need) .. " XP"
		end
		local equipped = table.find(eq, id) ~= nil
		if not owned then
			set(equip, equipPaint, equipLabel, "Not found yet", grey, false)
		elseif equipped then
			set(equip, equipPaint, equipLabel, "Put away", redPaint, true)
		elseif #eq >= C.petSlots then
			set(equip, equipPaint, equipLabel, "3 pets out · put one away", grey, false)
		else
			set(equip, equipPaint, equipLabel, "Equip", green, true)
		end
		local items = col.items or {}
		set(snack, snackPaint, snackLabel, "Snack ×" .. (items.Snack or 0), if (items.Snack or 0) > 0 and #eq > 0 then goldPaint else grey, (items.Snack or 0) > 0 and #eq > 0)
		set(feast, feastPaint, feastLabel, "Feast ×" .. (items.Feast or 0), if (items.Feast or 0) > 0 and #eq > 0 then goldPaint else grey, (items.Feast or 0) > 0 and #eq > 0)
		local lead = eq[1] == id
		nameBox.Visible, rename.Visible = lead, lead
		if lead and not nameBox:IsFocused() then nameBox.Text = self.player:GetAttribute("PetName") or "Pebble" end
	end)
end

function Panel:buildCosmetics(key, kind, entries)
	local page = self.pages[key]
	local tiles, pane, panePaint
	tiles, pane, panePaint = self:grid(page, entries, kind, function(entry)
		self.selected[key] = entry.id
		self:refresh()
	end)
	local holder = W.frame(pane, "Look", 99, 10, 100, 100, W.ink)
	holder.BackgroundTransparency = 1
	Icons.draw(holder, if kind == "trail" then "Trail" else "Gems", 0, 0, 100)
	local swatch = W.frame(pane, "Colour", 74, 114, 150, 12, W.white, 6)
	local swatchPaint = W.gradient(swatch, W.white, W.white, 0)
	local name = words(pane, "", 8, 130, 282, 30, 25)
	W.largest(name, 25, 14)
	local rarity = words(pane, "", 8, 160, 282, 20, 16)
	local about = words(pane, "", 12, 184, 274, 60, 15, rgb(255, 250, 215))
	about.TextWrapped = true
	local slots = if kind == "trail" then { "trail" } else { "aura", "petAura" }
	local buttons = {}
	for i, slot in slots do
		local b, paint, label = press(pane, slot, 12, 252 + (i - 1) * 50, 274, 44, 19)
		b.Activated:Connect(function()
			local col = self:col()
			local id = self.selected[key]
			if not (col.cos or {})[id] then return end
			self.net.Action:FireServer("Wear", slot, if col[slot] == id then nil else id)
		end)
		buttons[slot] = { b, paint, label }
	end
	table.insert(self.updates, function()
		local col = self:col()
		local cos = col.cos or {}
		self.selected[key] = self.selected[key] or (if kind == "trail" then col.trail else col.aura) or entries[1].id
		for _, entry in entries do
			local tile = tiles[entry.id]
			local tint = rarityTint(entry.rarity, cos[entry.id])
			tile.paint.Color = ColorSequence.new(tint[1], tint[2])
			tile.mark.Text = if col.trail == entry.id or col.aura == entry.id or col.petAura == entry.id then "✓" else ""
		end
		local id = self.selected[key]
		local entry = C.find(kind, id)
		local owned = cos[id] == true
		local colors = entry.colors or { entry.color, entry.color:Lerp(W.white, 0.5) }
		swatchPaint.Color = ColorSequence.new(colors[1], colors[2])
		local tint = rarityTint(entry.rarity, true)
		panePaint.Color = ColorSequence.new(tint[1], tint[2])
		name.Text, rarity.Text = entry.name, entry.rarity
		about.Text = (if kind == "trail" then "Colours your pick's swing and sparks" .. (if C.rarities[entry.rarity].rank >= C.rarities.Legendary.rank then ", and leaves a ribbon as you walk." else ".")
			else "Glows around you, or around each of your pets.")
			.. (if owned then "" else "\nFound in: " .. sources(kind, id))
		for slot, b in buttons do
			local wearing = col[slot] == id
			local caption = if slot == "petAura" then "on my pets" elseif slot == "aura" then "on me" else ""
			if not owned then
				set(b[1], b[2], b[3], "Not found yet", grey, false)
			else
				set(b[1], b[2], b[3], (if wearing then "Take off " else "Wear ") .. caption, if wearing then redPaint else green, true)
			end
			b[1].Visible = owned or slot == slots[1]
		end
	end)
end

function Panel:buildItems()
	local page = self.pages.Items
	self.itemsEmpty = words(page, "No items yet. Geodes, rewards and the Forge fill this bag.", 0, 120, 764, 40, 20)
	local list = Card.scroller(page, "Items", 0, 0, 764, 358)
	local rows = {}
	for i, item in C.items do
		local row = box(list, item.name, 0, 0, 750, 72, rarityTint(item.rarity, true))
		local well = W.frame(row, "Icon well", 10, 8, 56, 56, W.white, 12)
		well.BackgroundTransparency = 0.72
		Icons.draw(well, Reveal.icon("item", item.id), 4, 4, 48)
		local title = words(row, item.name, 76, 6, 360, 30, 22, nil, true)
		local detail = words(row, item.detail, 78, 36, 420, 26, 16, rgb(255, 250, 215), true)
		W.largest(detail, 16, 11)
		local count = words(row, "", 450, 6, 110, 60, 28)
		local use, paint, label = press(row, "Use", 572, 14, 166, 44, 20)
		use.Activated:Connect(function()
			if item.kind == "geode" then
				self.net.Action:FireServer("OpenGeode", item.geode, false)
			else
				self.net.Action:FireServer("UseItem", item.id)
			end
		end)
		rows[i] = { row = row, item = item, count = count, use = { use, paint, label }, title = title }
	end
	table.insert(self.updates, function()
		local col = self:col()
		local items, y = col.items or {}, 0
		local state = Bonuses.state(self.player)
		for _, entry in rows do
			local n = items[entry.item.id] or 0
			entry.row.Visible = n > 0
			if n > 0 then
				entry.row.Position = UDim2.fromOffset(0, y)
				y += 80
				entry.count.Text = "×" .. n
				local caption = if entry.item.kind == "geode" then "Open"
					elseif entry.item.kind == "food" then "Feed pets"
					else "Drink"
				local left = if entry.item.boost then Bonuses.left(state, entry.item.boost) else 0
				if left > 0 then caption ..= " (+" .. entry.item.minutes .. "m)" end
				local ready = entry.item.kind ~= "food" or #(col.eq or {}) > 0
				set(entry.use[1], entry.use[2], entry.use[3], caption, if ready then green else grey, ready)
			end
		end
		list.CanvasSize = UDim2.fromOffset(0, y)
		self.itemsEmpty.Visible = y == 0
	end)
end

function Panel:buildForge()
	local page = self.pages.Forge
	local note = words(page, "Craft exactly what you want: ore from your pack, Geode Dust from duplicates, and gems.", 0, 0, 764, 24, 16, rgb(255, 244, 170))
	note.TextWrapped = true
	local list = Card.scroller(page, "Recipes", 0, 28, 764, 330)
	local y = 0
	for _, group in Recipes.groups do
		local heading = words(list, group, 4, y, 300, 28, 20, rgb(255, 230, 160), true)
		heading.Name = group
		y += 30
		for _, recipe in Recipes.list do
			if recipe.group ~= group then continue end
			local entry = C.find(recipe.give.kind, recipe.give.id)
			local row = box(list, recipe.id, 0, y, 750, 74, rarityTint(entry.rarity, true))
			local well = W.frame(row, "Icon well", 10, 9, 56, 56, W.white, 12)
			well.BackgroundTransparency = 0.72
			Icons.draw(well, Reveal.icon(recipe.give.kind, recipe.give.id), 4, 4, 48)
			words(row, entry.name .. (if (recipe.give.count or 1) > 1 then " ×" .. recipe.give.count else ""), 76, 4, 400, 30, 21, nil, true)
			local cost = words(row, "", 78, 34, 480, 34, 15, nil, true)
			cost.RichText, cost.TextWrapped = true, true
			local craft, paint, label = press(row, "Craft", 572, 15, 166, 44, 20)
			craft.Activated:Connect(function() self.net.Action:FireServer("Craft", recipe.id) end)
			table.insert(self.updates, function()
				local col = self:col()
				local parts, ok = {}, true
				for _, ore in Ores.list do
					local need = (recipe.ores or {})[ore.name]
					if need then
						local have = self.player:GetAttribute("Held" .. ore.name) or 0
						local met = have >= need
						ok = ok and met
						table.insert(parts, W.colored(string.format("%s %d/%d", if self.player:GetAttribute("Found" .. ore.name) or not ore.secret then ore.name else "???", have, need), if met then W.green else unmet))
					end
				end
				if recipe.dust then
					local met = (col.dust or 0) >= recipe.dust
					ok = ok and met
					table.insert(parts, W.colored(string.format("Dust %s/%s", W.number(col.dust or 0), W.number(recipe.dust)), if met then W.green else unmet))
				end
				if recipe.gems then
					local have = self.player:GetAttribute("Gems") or 0
					ok = ok and have >= recipe.gems
					table.insert(parts, W.colored(string.format("Gems %d/%d", have, recipe.gems), if have >= recipe.gems then W.green else unmet))
				end
				cost.Text = table.concat(parts, "   ")
				local kind = recipe.give.kind
				local done = ((kind == "trail" or kind == "aura") and (col.cos or {})[recipe.give.id])
					or (kind == "pet" and (col.pets or {})[recipe.give.id] and col.pets[recipe.give.id].s >= C.maxStars)
				if done then
					set(craft, paint, label, "Owned ✓", grey, false)
				else
					local caption = if kind == "pet" and (col.pets or {})[recipe.give.id] then "Craft ★" else "Craft"
					set(craft, paint, label, caption, if ok then goldPaint else grey, ok)
				end
			end)
			y += 82
		end
	end
	list.CanvasSize = UDim2.fromOffset(0, y)
end

function Panel:open(key)
	local tab = if self.pages[key] then key else "Pets"
	self.page, self.tab = key, tab
	for name, page in self.pages do
		page.Visible = name == tab
		self.tabs[name].Color = if name == tab then ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
			else ColorSequence.new(Card.slate[1], Card.slate[2])
	end
	local card = self.card
	card:setIcon(tabIcons[tab])
	local tint = tints[tab]
	card.headerPaint.Color = ColorSequence.new(tint[1], tint[2])
	card.heading.Text = if tab == "Pets" then "Pets & Collection" else tab
	self:refresh()
end

function Panel:refresh()
	local state = Bonuses.state(self.player)
	local sums, parts = Bonuses.pets(state), {}
	for _, kind in { "gold", "speed", "luck", "xp", "gems" } do
		if sums[kind] > 0 then
			table.insert(parts, string.format("+%d%% %s", math.floor(sums[kind] * 100 + 0.5), C.bonusText[kind]))
		end
	end
	self.card.sub.Text = string.format("%d/%d pets out%s   ·   Dust %s", #state.equipped, C.petSlots,
		if #parts > 0 then "   ·   " .. table.concat(parts, "  ") else "", W.goldAmount(self.player:GetAttribute("GeodeDust") or 0))
	for _, update in self.updates do
		update()
	end
end

local _ = Guide
return Panel
