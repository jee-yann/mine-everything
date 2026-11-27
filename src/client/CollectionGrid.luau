-- A cosmetics page: a grid of tiles on the left (owned ones in their rarity's colour, the rest dark
-- with where they come from) and a detail pane on the right with a live preview of the effect and Wear.
-- Used by the Inventory for Mining FX and Player FX. While every effect is open for playtesting
-- (GameConfig.AllFxForTesting), anything can be worn.
local Run = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Geodes, S = require(Shared.Collectibles), require(Shared.Geodes), require(Shared.StoreConfig)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local FxPreview = require(script.Parent.FxPreview)
local Grid = {}
Grid.__index = Grid
local rgb = Color3.fromRGB
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
local grey = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local redPaint = ColorSequence.new(rgb(255, 150, 150), rgb(214, 52, 78))

Grid.icons = { trail = "Power", ribbon = "Trail", aura = "Gems", item = "Boosts" }

-- A label with navy outline. Rarity names and keywords like Starfall come out in their colours.
function Grid.words(parent, value, x, y, w, h, size, color, left)
	local label = W.title(parent, value, x, y, w, h, size, color or W.white, left)
	label.ZIndex = 3
	label.RichText = true
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

-- Where something comes from: the crate, a pass or a limited offer.
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
	local entry = C.find(kind, id)
	local pass = entry.pass and S.passByKey[entry.pass]
	if pass then table.insert(out, "the " .. (if pass.retired then S.passByKey.Everything.name else pass.name)) end
	if entry.product then table.insert(out, "the Limited Shop offer") end
	return if #out == 0 then "—" else table.concat(out, ", ")
end

-- A cosmetic's picture: a live preview of the effect itself.
function Grid.look(parent, kind, entry, x, y, size)
	local holder = W.frame(parent, "Look", x, y, size, size, W.ink)
	holder.BackgroundTransparency = 1
	FxPreview.new(holder, kind, entry.id, 0, 0, size)
	return holder
end

-- `owner` gives: player, net, hud, col() (the decoded collection). `kinds` is one kind, or a list of
-- kinds whose entries share the page (player trails and auras).
function Grid.new(owner, page, kinds)
	if type(kinds) == "string" then kinds = { kinds } end
	local self = setmetatable({ owner = owner, kind = kinds[1], entries = {}, kindOf = {}, tiles = {} }, Grid)
	for _, kind in kinds do
		for _, entry in C.lists[kind] do
			table.insert(self.entries, entry)
			self.kindOf[entry.id] = kind
		end
	end
	-- Rarest last, like the catalogue; trails before auras within a rarity.
	local order = {}
	for i, entry in self.entries do order[entry.id] = i end
	table.sort(self.entries, function(a, b)
		local ra, rb = C.rarities[a.rarity].rank, C.rarities[b.rarity].rank
		if ra ~= rb then return ra < rb end
		return order[a.id] < order[b.id]
	end)
	local list = Card.scroller(page, "Grid", 0, 0, 456, 358)
	for i, entry in self.entries do
		local x, y = (i - 1) % 4 * 112, math.floor((i - 1) / 4) * 112
		local b = W.clearButton(list, entry.id, x, y, 106, 106, "Select")
		W.round(b, 14)
		local paint = W.enamelPanel(b, rgb(110, 108, 140), rgb(70, 68, 100), 14)
		local holder = Grid.look(b, self.kindOf[entry.id], entry, 18, 6, 70)
		local name = words(b, entry.name, 4, 76, 98, 26, 15)
		W.largest(name, 15, 9)
		local mark = words(b, "", 70, 2, 34, 24, 16, rgb(190, 255, 150))
		-- What the effect gives: movement speed in green (Player FX), mining speed in orange (Mining FX).
		local mine = C.mineSpeed(self.kindOf[entry.id], entry.id)
		local speed = if mine > 0 then mine else C.speed(self.kindOf[entry.id], entry.id)
		if speed > 0 then
			local badge = W.frame(b, "Speed", 4, 4, 44, 20, if mine > 0 then C.bonusColors.mine else C.bonusColors.move, 10)
			badge.ZIndex = 3
			W.stroke(badge, W.navy, 2)
			local fast = words(badge, "+" .. speed .. "%", 0, 0, 44, 20, 13)
			fast.ZIndex = 4
		end
		local scale = W.scale(b)
		b.Activated:Connect(function()
			self.selected = entry.id
			scale.Scale = 0.9
			W.tween(scale, 0.18, { Scale = 1 })
			owner:refresh()
		end)
		self.tiles[entry.id] = { paint = paint, mark = mark, holder = holder }
	end
	list.CanvasSize = UDim2.fromOffset(0, math.ceil(#self.entries / 4) * 112)
	local pane = W.frame(page, "Detail", 466, 0, 298, 358, W.white, 16)
	self.panePaint = W.enamelPanel(pane, rgb(207, 174, 255), rgb(129, 80, 230), 16)
	self.pane = pane
	Card.rays(pane, 149, 70, 200, 7)
	self.lookHolder = W.frame(pane, "Look", 93, 10, 112, 112, W.ink)
	self.lookHolder.BackgroundTransparency = 1
	self.name = words(pane, "", 8, 132, 282, 30, 25)
	W.largest(self.name, 25, 14)
	self.rarity = words(pane, "", 8, 160, 282, 20, 16)
	self.about = words(pane, "", 12, 182, 274, 52, 15, rgb(255, 250, 215))
	self.about.TextWrapped = true
	self.about.Size = UDim2.fromOffset(274, 80)
	self.primary = { press(pane, "Use", 12, 290, 274, 52, 22) }
	self.primary[1].Activated:Connect(function() self:act() end)
	return self
end

-- Wear or take off the selected cosmetic.
function Grid:act()
	local id, col = self.selected, self.owner:col()
	if not id or not ((col.cos or {})[id] or col.allFx) then return end
	local kind = self.kindOf[id]
	self.owner.net.Action:FireServer("Wear", kind, if col[kind] == id then nil else id)
end

function Grid:refresh()
	local col = self.owner:col()
	local function owned(id) return (col.cos or {})[id] == true end
	local function wearable(id) return owned(id) or col.allFx == true end
	self.selected = self.selected or col[self.kind] or self.entries[1].id
	for _, entry in self.entries do
		local tile = self.tiles[entry.id]
		local tint = Grid.tint(entry.rarity, wearable(entry.id))
		tile.paint.Color = ColorSequence.new(tint[1], tint[2])
		tile.mark.Text = if col[self.kindOf[entry.id]] == entry.id then "✓" else ""
	end
	local id = self.selected
	local kind = self.kindOf[id]
	local entry = C.find(kind, id)
	local has = wearable(id)
	local tint = Grid.tint(entry.rarity, true)
	self.panePaint.Color = ColorSequence.new(tint[1], tint[2])
	if self.shown ~= id then
		self.shown = id
		self.lookHolder:ClearAllChildren()
		Grid.look(self.lookHolder, kind, entry, 0, 0, 112)
	end
	self.name.Text = entry.name
	self.rarity.Text = W.rich(entry.rarity) .. "  ·  " .. C.kindNames[kind]
	local about = ({
		trail = "Colours your pickaxe's swing and its sparks as you mine.",
		ribbon = "A trail that follows you as you walk.",
		aura = "An aura that glows around you.",
	})[kind]
	if kind ~= "trail" then about ..= " One Player FX at a time." end
	if col.allFx and not owned(id) then about ..= "\n" .. W.colored("Unlocked for playtesting.", rgb(255, 230, 128)) end
	local fast = C.bonusText(kind, id)
	local tone = if C.mineSpeed(kind, id) > 0 then rgb(255, 180, 90) else rgb(150, 255, 120)
	self.about.Text = W.rich(about .. (if fast then " " .. W.colored(fast, tone) .. " while worn." else "")
		.. (if owned(id) then "" else "\nFound in: " .. Grid.sources(kind, id)))
	W.largest(self.about, 15, 10)
	local p = self.primary
	if not has then
		set(p[1], p[2], p[3], "Not found yet", grey, false)
	elseif col[kind] == id then
		set(p[1], p[2], p[3], "Take off", redPaint, true)
	else
		set(p[1], p[2], p[3], "Wear", green, true)
	end
end

return Grid
