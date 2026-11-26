-- Pets: every pet (one follows at a time) and the styles a pet can wear. Owned ones show in their
-- rarity's colour; the rest show where they come from. Pets are just for looks.
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Bonuses = require(Shared.Collectibles), require(Shared.Bonuses)
local W, Card = require(script.Parent.Widgets), require(script.Parent.WideCard)
local Grid = require(script.Parent.CollectionGrid)
local Panel = {}
Panel.__index = Panel
local rgb = Color3.fromRGB
local violet = { rgb(207, 174, 255), rgb(129, 80, 230) }
local tabs = { { "Pets", "Pets", "Pets" }, { "PetStyles", "Pet Styles", "Trail" } }

function Panel.new(menu)
	local self = setmetatable({ menu = menu, player = menu.player, net = menu.net, hud = menu.hud, pages = {}, grids = {} }, Panel)
	local card = Card.new(menu, "Pets", "Pets", "Pets", violet)
	self.card = card
	self.paints = card:tabRow(tabs, function(key) menu:open(key) end)
	for _, tab in tabs do
		local page = W.frame(card.body, tab[1], 7, 7, 764, 358, W.panel)
		page.BackgroundTransparency, page.Visible = 1, false
		self.pages[tab[1]] = page
	end
	self.grids.Pets = Grid.new(self, self.pages.Pets, "pet", C.pets)
	self.grids.PetStyles = Grid.new(self, self.pages.PetStyles, "style", C.styles)
	-- The equipped pet's name.
	local pane = self.grids.Pets.pane
	local box = Instance.new("TextBox")
	box.Name, box.Position, box.Size = "Pet name", UDim2.fromOffset(12, 292), UDim2.fromOffset(196, 36)
	box.BackgroundColor3, box.TextColor3, box.Font, box.TextSize = W.navy, W.white, Enum.Font.FredokaOne, 16
	box.PlaceholderText, box.ClearTextOnFocus, box.ZIndex = "Name your pet", false, 4
	W.round(box, 8)
	box.Parent = pane
	local save, savePaint, saveLabel = Grid.press(pane, "Rename", 214, 292, 72, 36, 15)
	Grid.set(save, savePaint, saveLabel, "Save", ColorSequence.new(rgb(255, 226, 120), rgb(240, 150, 30)), true)
	save.Activated:Connect(function() self.net.Action:FireServer("PetName", box.Text) end)
	self.nameBox, self.saveName = box, save
	return self
end

function Panel:col()
	return Bonuses.decode(self.player:GetAttribute("Collection")) or {}
end

function Panel:open(key)
	local tab = if self.pages[key] then key else "Pets"
	self.page, self.tab = key, tab
	for name, page in self.pages do page.Visible = name == tab end
	Card.paintTabs(self.paints, tab)
	local card = self.card
	card:setIcon(if tab == "Pets" then "Pets" else "Trail")
	card.headerPaint.Color = ColorSequence.new(violet[1], violet[2])
	card.heading.Text = if tab == "Pets" then "Pets" else "Pet Styles"
	self:refresh()
end

function Panel:refresh()
	local col = self:col()
	local owned = 0
	for _ in col.pets or {} do owned += 1 end
	local pet = C.petById[(col.eq or {})[1] or ""]
	local style = C.styleById[col.style or ""]
	self.card.sub.Text = string.format("%d / %d pets   ·   Following: %s   ·   Style: %s", owned, #C.pets,
		if pet then pet.name else "none", if style then style.name else "none")
	for _, grid in self.grids do grid:refresh() end
	local grid = self.grids.Pets
	local lead = (col.eq or {})[1]
	local showName = lead ~= nil and grid.selected == lead
	self.nameBox.Visible, self.saveName.Visible = showName, showName
	if showName and not self.nameBox:IsFocused() then self.nameBox.Text = self.player:GetAttribute("PetName") or "Pebble" end
end

return Panel
