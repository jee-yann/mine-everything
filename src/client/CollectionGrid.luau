-- A collection page: a grid of tiles on the left (owned ones in their rarity's colour, the rest dark
-- with where they come from) and a detail pane on the right with a live preview, wear or equip, and
-- "Try on" for cosmetics. Used by the Inventory (trails and auras) and the Pets card (pets, styles).
local Run = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Geodes, Recipes, S = require(Shared.Collectibles), require(Shared.Geodes), require(Shared.Recipes), require(Shared.StoreConfig)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local Models = require(script.Parent.PetModels)
local TryOn = require(script.Parent.TryOn)
local Grid = {}
Grid.__index = Grid
local rgb = Color3.fromRGB
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
local grey = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local redPaint = ColorSequence.new(rgb(255, 150, 150), rgb(214, 52, 78))
local violetPaint = ColorSequence.new(rgb(207, 174, 255), rgb(129, 80, 230))
local goldPaint = ColorSequence.new(rgb(255, 226, 120), rgb(240, 150, 30))
Grid.icons = { pet = "Pets", trail = "Power", ribbon = "Trail", aura = "Gems", style = "Pets", item = "Boosts" }

function Grid.words(parent, value, x, y, w, h, size, color, left)
	local label = W.title(parent, value, x, y, w, h, size, color or W.white, left)
	label.ZIndex = 3
	W.navyText(label, math.max(2, size / 9))
	return label
end
local words = Grid.words
function Grid.press(parent, name, x, y, w, h, size)
	local button = W.clearButton(parent, name, x, y, w, h, "Select")
	W.round(button, 12)
	local paint = W.enamelPanel(button, rgb(150, 154, 176), rgb(98, 102, 128), 12)
	local label = words(button, "", 0, 0, w, h - 2, size)
	W.largest(label, size, 11)
	return button, paint, label
end
function Grid.set(button, paint, label, text, color, enabled)
	label.Text, paint.Color = text, color
	button.Interactable, button.AutoButtonColor = enabled, enabled
end
local press, set = Grid.press, Grid.set
function Grid.tint(rarity, owned)
	local color = C.rarities[rarity].color
	if not owned then return { rgb(110, 108, 140), rgb(70, 68, 100) } end
	return { color:Lerp(W.white, 0.2), color:Lerp(rgb(40, 30, 70), 0.45) }
end

-- Where something comes from: crates, the Forge, a pass, a limited offer or the first pet.
function Grid.sources(kind, id)
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
		if recipe.give.kind == kind and recipe.give.id == id then table.insert(out, "the Forge") end
	end
	local entry = C.find(kind, id)
	if entry.pass and S.passByKey[entry.pass] then table.insert(out, "the " .. S.passByKey[entry.pass].name .. " pass") end
	if entry.product and S.productByKey[entry.product] then table.insert(out, "the limited Shop offer") end
	if entry.starter then table.insert(out, "every miner's first pet") end
	if kind == "pet" and id == "Drake" then table.insert(out, "drake eggs deep in the mine") end
	return if #out == 0 then "—" else table.concat(out, ", ")
end

-- A cosmetic's picture: its kind's icon over a band of its colours.
function Grid.look(parent, kind, entry, x, y, size)
	local holder = W.frame(parent, "Look", x, y, size, size, W.ink)
	holder.BackgroundTransparency = 1
	Icons.draw(holder, Grid.icons[kind], size * 0.1, 0, size * 0.8)
	local colors = C.colors(entry)
	local swatch = W.frame(holder, "Colour", size * 0.1, size * 0.86, size * 0.8, math.max(6, size * 0.1), W.white, 4)
	W.gradient(swatch, colors[1], colors[2], 0)
	return holder
end

-- `owner` gives: player, net, hud, col() (the decoded collection). `kinds` is one kind, or a list of
-- kinds whose entries share the page (player trails and auras).
function Grid.new(owner, page, kinds, entries)
	if type(kinds) == "string" then kinds = { kinds } end
	local self = setmetatable({ owner = owner, kind = kinds[1], entries = {}, kindOf = {}, tiles = {} }, Grid)
	entries = entries or {}
	if #entries == 0 then
		for _, kind in kinds do
			for _, entry in C.lists[kind] do table.insert(entries, entry) end
		end
	end
	for _, entry in entries do
		for _, kind in kinds do
			if C.find(kind, entry.id) == entry then self.kindOf[entry.id] = kind end
		end
	end
	self.entries = entries
	local kind = kinds[1]
	local list = Card.scroller(page, "Grid", 0, 0, 456, 358)
	for i, entry in entries do
		local x, y = (i - 1) % 4 * 112, math.floor((i - 1) / 4) * 112
		local b = W.clearButton(list, entry.id, x, y, 106, 106, "Select")
		W.round(b, 14)
		local paint = W.enamelPanel(b, rgb(110, 108, 140), rgb(70, 68, 100), 14)
		local holder
		local kind = self.kindOf[entry.id]
		if kind == "pet" then
			holder = Instance.new("ViewportFrame")
			holder.Name, holder.BackgroundTransparency = "Look", 1
			holder.Position, holder.Size, holder.ZIndex = UDim2.fromOffset(13, 4), UDim2.fromOffset(80, 74), 3
			holder.Parent = b
			Models.preview(holder, entry.id)
		else
			holder = Grid.look(b, kind, entry, 18, 6, 70)
		end
		local name = words(b, entry.name, 4, 76, 98, 26, 15)
		W.largest(name, 15, 9)
		local mark = words(b, "", 70, 2, 34, 24, 16, rgb(190, 255, 150))
		local scale = W.scale(b)
		b.Activated:Connect(function()
			self.selected = entry.id
			scale.Scale = 0.9
			W.tween(scale, 0.18, { Scale = 1 })
			owner:refresh()
		end)
		self.tiles[entry.id] = { paint = paint, mark = mark, holder = holder }
	end
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(#entries / 4) * 112)
	local pane, panePaint = W.frame(page, "Detail", 466, 0, 298, 358, W.white, 16), nil
	panePaint = W.enamelPanel(pane, rgb(207, 174, 255), rgb(129, 80, 230), 16)
	self.pane, self.panePaint = pane, panePaint
	Card.rays(pane, 149, 70, 200, 7)
	local view = Instance.new("ViewportFrame")
	view.Name, view.BackgroundTransparency = "Preview", 1
	view.Position, view.Size, view.ZIndex = UDim2.fromOffset(64, 6), UDim2.fromOffset(170, 128), 3
	view.Parent = pane
	self.view = view
	self.lookHolder = W.frame(pane, "Look", 99, 12, 100, 112, W.ink)
	self.lookHolder.BackgroundTransparency = 1
	self.name = words(pane, "", 8, 132, 282, 30, 25)
	W.largest(self.name, 25, 14)
	self.rarity = words(pane, "", 8, 160, 282, 20, 16)
	self.about = words(pane, "", 12, 182, 274, 52, 15, rgb(255, 250, 215))
	self.about.TextWrapped = true
	self.primary = { press(pane, "Use", 12, 240, 274, 44, 21) }
	self.primary[1].Activated:Connect(function() self:act() end)
	self.try = { press(pane, "Try on", 12, 290, 274, 38, 18) }
	self.try[1].Activated:Connect(function()
		if self.selected then TryOn.start(owner.hud, self.kindOf[self.selected], self.selected) end
	end)
	set(self.try[1], self.try[2], self.try[3], "Try on (8 s)", violetPaint, true)
	self.try[1].Visible = kind ~= "pet"
	local _ = self.kind
	-- The preview turns slowly while it shows.
	Run.RenderStepped:Connect(function()
		local model = self.model
		if model and model.Parent and pane.Visible and page.Visible and pane:IsDescendantOf(game) then
			model:PivotTo(CFrame.Angles(0, os.clock() * 0.8, 0) * CFrame.new(0, 0.08 * math.sin(os.clock() * 2), 0))
		end
		local holder = self.lookHolder
		if holder.Visible then holder.Position = UDim2.fromOffset(99, 12 + 5 * math.sin(os.clock() * 2.4)) end
	end)
	return self
end

-- Equip/wear or put away the selected entry.
function Grid:act()
	local id, col = self.selected, self.owner:col()
	if not id then return end
	local net = self.owner.net
	local kind = self.kindOf[id]
	if kind == "pet" then
		if not (col.pets or {})[id] then return end
		net.Action:FireServer("EquipPet", id, (col.eq or {})[1] ~= id)
	else
		if not (col.cos or {})[id] then return end
		net.Action:FireServer("Wear", kind, if col[kind] == id then nil else id)
	end
end

function Grid:refresh()
	local col = self.owner:col()
	local owned = function(id)
		if self.kindOf[id] == "pet" then return (col.pets or {})[id] ~= nil end
		return (col.cos or {})[id] == true
	end
	local function worn(kind)
		return if kind == "pet" then (col.eq or {})[1] else col[kind]
	end
	self.selected = self.selected or worn(self.kind) or self.entries[1].id
	for _, entry in self.entries do
		local tile = self.tiles[entry.id]
		local tint = Grid.tint(entry.rarity, owned(entry.id))
		tile.paint.Color = ColorSequence.new(tint[1], tint[2])
		tile.mark.Text = if worn(self.kindOf[entry.id]) == entry.id then "✓" else ""
		if self.kindOf[entry.id] == "pet" then
			tile.holder.ImageColor3 = if owned(entry.id) then W.white else rgb(40, 40, 60)
		end
	end
	local id = self.selected
	local kind = self.kindOf[id]
	local wearing = worn(kind)
	local entry = C.find(kind, id)
	local has = owned(id)
	local tint = Grid.tint(entry.rarity, true)
	self.panePaint.Color = ColorSequence.new(tint[1], tint[2])
	-- The preview: the pet itself, a pet style on the miner's pet, or the cosmetic's picture.
	local key = id .. "|" .. tostring((col.eq or {})[1]) .. "|" .. tostring(col.style)
	if kind == "pet" or kind == "style" then
		self.view.Visible, self.lookHolder.Visible = true, false
		if self.shown ~= key then
			self.shown = key
			if kind == "pet" then
				self.model = Models.preview(self.view, id, if (col.eq or {})[1] == id then col.style else nil)
			else
				self.model = Models.preview(self.view, (col.eq or {})[1] or "Rock", id)
			end
		end
		self.view.ImageColor3 = if has or kind == "style" then W.white else rgb(40, 40, 60)
	else
		self.view.Visible, self.lookHolder.Visible = false, true
		if self.shown ~= key then
			self.shown = key
			self.lookHolder:ClearAllChildren()
			Grid.look(self.lookHolder, kind, entry, 0, 0, 100)
		end
	end
	self.name.Text = entry.name
	self.rarity.Text, self.rarity.TextColor3 = entry.rarity .. "  ·  " .. C.kindNames[kind], C.rarities[entry.rarity].color:Lerp(W.white, 0.35)
	local about = ({
		pet = "Follows you around. Pets are just for looks.",
		trail = "Colours your pickaxe's swing and its sparks as you mine.",
		ribbon = "A ribbon that follows you as you walk.",
		aura = "Glows around you.",
		style = "Worn by your pet.",
	})[kind]
	self.about.Text = about .. (if has then "" else "\nFound in: " .. Grid.sources(kind, id))
	local p = self.primary
	if not has then
		set(p[1], p[2], p[3], "Not found yet", grey, false)
	elseif wearing == id then
		set(p[1], p[2], p[3], if kind == "pet" then "Put away" else "Take off", redPaint, true)
	else
		set(p[1], p[2], p[3], if kind == "pet" then "Equip" else "Wear", green, true)
	end
	local _ = goldPaint
end

return Grid
