-- The inventory: items (crates, tonics and field supplies), mining trails, player effects (trails
-- that follow you and auras), the Forge and titles. Pets and their styles have their own card.
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Recipes, Bonuses = require(Shared.Collectibles), require(Shared.Recipes), require(Shared.Bonuses)
local Ores, E, Skills = require(Shared.Ores), require(Shared.Expeditions), require(Shared.Skills)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local Grid = require(script.Parent.CollectionGrid)
local Panel = {}
Panel.__index = Panel
local rgb = Color3.fromRGB
local orange = { rgb(255, 208, 138), rgb(240, 138, 58) }
local tabs = {
	{ "Items", "Items", "Inventory" },
	{ "MiningTrails", "Mining", "Power" },
	{ "PlayerFX", "Player FX", "Trail" },
	{ "Forge", "Forge", "Forge" },
	{ "Titles", "Titles", "Achievements" },
}
local headings = { Items = "Inventory", MiningTrails = "Mining Trails", PlayerFX = "Player Effects", Forge = "Forge", Titles = "Titles" }
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
local grey = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local goldPaint = ColorSequence.new(rgb(255, 226, 120), rgb(240, 150, 30))
local unmet = rgb(255, 141, 137)
local words, press, set = Grid.words, Grid.press, Grid.set

local function box(parent, name, x, y, w, h, tint)
	local frame = W.frame(parent, name, x, y, w, h, W.white, 16)
	return frame, W.enamelPanel(frame, tint[1], tint[2], 16)
end

function Panel.new(menu)
	local self = setmetatable({ menu = menu, player = menu.player, net = menu.net, hud = menu.hud, updates = {}, pages = {}, grids = {} }, Panel)
	local card = Card.new(menu, "Inventory", "Inventory", "Inventory", orange)
	self.card = card
	self.paints = card:tabRow(tabs, function(key) menu:open(key) end)
	for _, tab in tabs do
		local page = W.frame(card.body, tab[1], 7, 7, 764, 358, W.panel)
		page.BackgroundTransparency, page.Visible = 1, false
		self.pages[tab[1]] = page
	end
	self:buildItems()
	self.grids.MiningTrails = Grid.new(self, self.pages.MiningTrails, "trail")
	self.grids.PlayerFX = Grid.new(self, self.pages.PlayerFX, { "ribbon", "aura" })
	self:buildForge()
	self:buildTitles()
	return self
end

function Panel:col()
	return Bonuses.decode(self.player:GetAttribute("Collection")) or {}
end

-- One row: icon, name, detail, a count and an action button.
function Panel:row(list, name, tint, icon)
	local row = box(list, name, 0, 0, 750, 72, tint)
	local well = W.frame(row, "Icon well", 10, 8, 56, 56, W.white, 12)
	well.BackgroundTransparency = 0.72
	Icons.draw(well, icon, 4, 4, 48)
	words(row, name, 76, 6, 360, 30, 22, nil, true)
	local detail = words(row, "", 78, 36, 470, 26, 16, rgb(255, 250, 215), true)
	W.largest(detail, 16, 11)
	local count = words(row, "", 450, 6, 110, 60, 28)
	local use = { press(row, "Use", 572, 14, 166, 44, 20) }
	return { row = row, detail = detail, count = count, use = use }
end

function Panel:buildItems()
	local page = self.pages.Items
	local list = Card.scroller(page, "Items", 0, 0, 764, 358)
	local rows = {}
	-- Crates first, then tonics.
	local order = {}
	for _, item in C.items do
		if item.kind == "geode" then table.insert(order, item) end
	end
	for _, item in C.items do
		if item.kind ~= "geode" then table.insert(order, item) end
	end
	for _, item in order do
		local entry = self:row(list, item.name, Grid.tint(item.rarity, true), if item.kind == "geode" then "Geode" else "Boosts")
		entry.detail.Text = item.detail
		entry.use[1].Activated:Connect(function()
			if item.kind == "geode" then
				self.net.Action:FireServer("OpenGeode", item.geode, false)
			else
				self.net.Action:FireServer("UseItem", item.id)
			end
		end)
		entry.item = item
		table.insert(rows, entry)
	end
	-- Field supplies, from the Supplies counter.
	local supplies = {
		{ "Survey flares", "Flares", "Crystal", "Flare", function(n) return n .. " packed · lights a tunnel" end },
		{ "Cave pulses", "CavePulses", "Rebirth", "Pulse", function(n) return n .. " packed · clears nearby stone" end },
		{ "Pickaxe temper", "TemperCharges", "Power", nil, function(n) return n .. " charges · faster on hard rock" end },
		{ "Quick-cut wax", "HasteCuts", "Speed", nil, function(n) return n .. " cuts left at double speed" end },
		{ "Diamond teeth", "StoneChips", "Power", nil, function(n) return n .. " stone cuts left, almost instant" end },
	}
	local supplyRows = {}
	for _, supply in supplies do
		local entry = self:row(list, supply[1], { rgb(134, 214, 255), rgb(47, 130, 230) }, supply[3])
		if supply[4] then
			entry.use[1].Activated:Connect(function() self.net.Action:FireServer(supply[4]) end)
		end
		entry.supply = supply
		table.insert(supplyRows, entry)
	end
	local empty = words(page, "", 0, 140, 764, 60, 20)
	empty.TextWrapped = true
	table.insert(self.updates, function()
		local col = self:col()
		local items, y = col.items or {}, 0
		for _, entry in rows do
			local n = items[entry.item.id] or 0
			entry.row.Visible = n > 0
			if n > 0 then
				entry.row.Position = UDim2.fromOffset(0, y)
				y += 80
				entry.count.Text = "×" .. n
				local caption = if entry.item.kind == "geode" then "Open" else "Drink"
				set(entry.use[1], entry.use[2], entry.use[3], caption, green, true)
			end
		end
		for _, entry in supplyRows do
			local n = self.player:GetAttribute(entry.supply[2]) or 0
			entry.row.Visible = n > 0
			if n > 0 then
				entry.row.Position = UDim2.fromOffset(0, y)
				y += 80
				entry.count.Text = "×" .. n
				entry.detail.Text = entry.supply[5](n)
				local usable = entry.supply[4] ~= nil
				set(entry.use[1], entry.use[2], entry.use[3], if usable then "Use in mine" else "Active", if usable then green else grey, usable)
			end
		end
		list.CanvasSize = UDim2.fromOffset(0, y)
		empty.Text = if y == 0 then "Nothing here yet. Crates, tonics and field supplies show up here." else ""
	end)
	local _ = Skills
end

function Panel:buildForge()
	local page = self.pages.Forge
	local note = words(page, "Craft exactly what you want from ore in your pack, Crate Dust (from duplicates) and gems.", 0, 0, 764, 24, 16, rgb(255, 244, 170))
	note.TextWrapped = true
	local list = Card.scroller(page, "Recipes", 0, 28, 764, 330)
	local y = 0
	for _, group in Recipes.groups do
		local heading = words(list, group, 4, y, 300, 28, 20, rgb(255, 230, 160), true)
		heading.Name = group
		y += 30
		for _, recipe in Recipes.list do
			if recipe.group ~= group then continue end
			local give = recipe.give
			local entry = C.find(give.kind, give.id)
			local row = box(list, recipe.id, 0, y, 750, 74, Grid.tint(entry.rarity, true))
			if C.isCosmetic(give.kind) then
				Grid.look(row, give.kind, entry, 10, 9, 56)
			else
				local well = W.frame(row, "Icon well", 10, 9, 56, 56, W.white, 12)
				well.BackgroundTransparency = 0.72
				Icons.draw(well, if give.kind == "pet" then "Pets" else "Boosts", 4, 4, 48)
			end
			words(row, entry.name .. "  ·  " .. C.kindNames[give.kind], 76, 4, 480, 30, 21, nil, true)
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
						local name = if self.player:GetAttribute("Found" .. ore.name) or not ore.secret then ore.name else "???"
						table.insert(parts, W.colored(string.format("%s %d/%d", name, have, need), if met then W.green else unmet))
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
					table.insert(parts, W.colored(string.format("Gems %s/%d", W.number(have), recipe.gems), if have >= recipe.gems then W.green else unmet))
				end
				cost.Text = table.concat(parts, "   ")
				local owned = give.kind ~= "item" and (if give.kind == "pet" then (col.pets or {})[give.id] ~= nil else (col.cos or {})[give.id] == true)
				if owned then
					set(craft, paint, label, "Owned ✓", grey, false)
				else
					set(craft, paint, label, "Craft", if ok then goldPaint else grey, ok)
				end
			end)
			y += 82
		end
	end
	list.CanvasSize = UDim2.fromOffset(0, y)
end

function Panel:buildTitles()
	local list = Card.scroller(self.pages.Titles, "Titles", 0, 0, 764, 358)
	for i, title in E.ranks do
		local entry = self:row(list, title.name, { rgb(255, 230, 128), rgb(243, 165, 26) }, "Achievements")
		entry.row.Position = UDim2.fromOffset(0, (i - 1) * 80)
		entry.detail.Text = "Unlocks at level " .. title.level
		entry.use[1].Activated:Connect(function() self.net.Action:FireServer("Title", i) end)
		table.insert(self.updates, function()
			local owned = (self.player:GetAttribute("Level") or 1) >= title.level
			local equipped = (self.player:GetAttribute("EquippedTitle") or 1) == i
			entry.count.Text = ""
			set(entry.use[1], entry.use[2], entry.use[3], if equipped then "Equipped ✓" elseif owned then "Equip" else "Locked",
				if equipped then grey elseif owned then green else grey, owned and not equipped)
		end)
	end
	list.CanvasSize = UDim2.fromOffset(0, #E.ranks * 80)
end

function Panel:open(key)
	local tab = if self.pages[key] then key else "Items"
	self.page, self.tab = key, tab
	for name, page in self.pages do page.Visible = name == tab end
	Card.paintTabs(self.paints, tab)
	local card = self.card
	card:setIcon(({ Items = "Inventory", MiningTrails = "Power", PlayerFX = "Trail", Forge = "Forge", Titles = "Achievements" })[tab])
	card.headerPaint.Color = ColorSequence.new(orange[1], orange[2])
	card.heading.Text = headings[tab]
	self:refresh()
end

function Panel:refresh()
	local col = self:col()
	local worn = {}
	for _, kind in { "trail", "ribbon", "aura" } do
		local entry = C.find(kind, col[kind] or "")
		if entry then table.insert(worn, entry.name) end
	end
	self.card.sub.Text = (if #worn > 0 then "Wearing: " .. table.concat(worn, ", ") else "Nothing worn yet")
		.. "   ·   Dust " .. W.goldAmount(col.dust or 0)
	for _, update in self.updates do update() end
	for _, grid in self.grids do grid:refresh() end
end

return Panel
