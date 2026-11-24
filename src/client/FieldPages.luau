local Shared = game.ReplicatedStorage.Shared
local E, Guide, Ores, Config =
	require(Shared.Expeditions), require(Shared.FieldGuide), require(Shared.Ores), require(Shared.GameConfig)
local W = require(script.Parent.Widgets)
local Purity = require(Shared.OrePurity)
local companion = require(script.Parent.CompanionModel)
local Pages = {}
function Pages.titles(menu)
	for i, title in E.ranks do
		local _, detail, b = menu:row(i, title.name, "Titles", W.gold)
		detail.Text = "Level " .. title.level
		b.Activated:Connect(function()
			menu.net.Action:FireServer("Title", i)
		end)
		table.insert(menu.updates, function()
			local owned = (menu.player:GetAttribute("Level") or 1) >= title.level
			local equipped = (menu.player:GetAttribute("EquippedTitle") or 1) == i
			b.Text = if equipped then "Equipped" elseif owned then "Equip" else "Locked"
			b.BackgroundColor3 = if equipped then W.green elseif owned then W.gold else W.muted
			b.Interactable = owned and not equipped
		end)
	end
	return #E.ranks
end
local function petPortrait(parent, drake)
	local view = Instance.new("ViewportFrame")
	view.Name = if drake then "Cave Drake portrait" else "Pocket Rock portrait"
	view.Size, view.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	view.Ambient, view.LightColor = Color3.fromRGB(154, 153, 184), Color3.fromRGB(255, 238, 195)
	view.LightDirection = Vector3.new(-1, -1, 0.4)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 33
	local target = Vector3.new(0, 0.04, if drake then 0.65 else 0)
	camera.CFrame = CFrame.lookAt(target + (if drake then Vector3.new(2.75, 1.5, -4.15) else Vector3.new(1.45, 0.84, -2.35)), target)
	camera.Parent, view.CurrentCamera = view, camera
	companion(view, drake, true)
	view.Parent = parent
	return view
end

function Pages.pets(menu)
	local _, detail, equip = menu:row(1, "Pocket Rock", nil, W.violet)
	equip.Activated:Connect(function()
		menu.net.Action:FireServer("Pet", if menu.player:GetAttribute("Pet") == "Rock" then "" else "Rock")
	end)
	local _, drakeDetail, drake = menu:row(2, "Cave Drake", nil, W.aqua)
	drake.Activated:Connect(function()
		menu.net.Action:FireServer("Pet", if menu.player:GetAttribute("Pet") == "Drake" then "" else "Drake")
	end)
	local display = W.frame(menu.list, "Equipped companion", 1, 143, 447, 106, W.card, 12)
	W.enamel(display, W.grape:Lerp(W.panel, 0.48), W.panel)
	local portrait = W.frame(display, "Portrait", 8, 5, 127, 96, W.ink, 10)
	local rockView, drakeView = petPortrait(portrait, false), petPortrait(portrait, true)
	local caption = W.text(display, "", 148, 10, 283, 22, 15, W.aqua, true)
	local petName = W.title(display, "", 147, 32, 283, 37, 26, W.white, true)
	petName.TextTruncate = Enum.TextTruncate.AtEnd
	local species = W.text(display, "", 148, 71, 282, 34, 15, W.muted, true)
	local card = W.frame(menu.list, "Rename", 1, 256, 447, 119, W.card, 12)
	W.title(card, "Companion name", 13, 5, 300, 25, 19, W.white, true)
	local box = Instance.new("TextBox")
	box.Name, box.Position, box.Size = "Name", UDim2.fromOffset(13, 36), UDim2.fromOffset(262, 34)
	box.PlaceholderText, box.ClearTextOnFocus, box.Text = "Choose a name", false, ""
	box.TextSize, box.Font, box.TextColor3, box.BackgroundColor3 = 17, Enum.Font.BuilderSansBold, W.white, W.ink
	W.round(box, 8)
	box.Parent = card
	local rename = W.button(card, "Rename", 287, 36, 144, 34, W.gold, "Save name", "Select")
	rename.Activated:Connect(function()
		if box.Text ~= "" then
			menu.net.Action:FireServer("PetName", box.Text)
		end
	end)
	for i, name in { "Pebble", "Flint", "Chips" } do
		local b = W.button(card, name, 13 + (i - 1) * 91, 81, 83, 26, W.muted, name, "Select")
		b.Activated:Connect(function()
			box.Text = name
		end)
	end
	local previewSpecies, previousPet
	local function refresh()
		local pet = menu.player:GetAttribute("Pet") or ""
		if pet ~= previousPet then previewSpecies, previousPet = nil, pet end
		local active = pet == "Rock"
		local ownsDrake = menu.player:GetAttribute("DrakeUnlocked") == true
		local flying = pet == "Drake"
		local showDrake = if previewSpecies then previewSpecies == "Drake" else flying
		local equipped = if showDrake then flying else active
		drakeDetail.Text = if ownsDrake
			then "Flying cave companion"
			else "Hatch an egg in a natural cave below 185 blocks"
		drake.Text, drake.Interactable = if flying then "Unequip" elseif ownsDrake then "Equip" else "Locked", ownsDrake
		drake.BackgroundColor3 = if flying then W.green elseif ownsDrake then W.aqua else W.muted
		local name = menu.player:GetAttribute("PetName") or "Pebble"
		detail.Text = name .. "   ·   Pocket companion"
		caption.Text = if equipped then "EQUIPPED" else "COMPANION PREVIEW"
		petName.Text = if equipped then name elseif showDrake then "Cave Drake" else "Pocket Rock"
		species.TextWrapped = true
		species.Text = if showDrake and not ownsDrake then "Hatch a cave egg to bring this drake along."
			elseif not equipped then "Equip a pet to bring it along."
			elseif menu.player:GetAttribute("OreCompass") then "Ore compass · Spots nearby ore"
			else "Craft a compass to help find ore."
		rockView.Visible, drakeView.Visible = not showDrake, showDrake
		box.PlaceholderText = name
		equip.Text, equip.BackgroundColor3 = if active then "Unequip" else "Equip", if active then W.green else W.violet
	end
	for key, row in { Rock = detail.Parent, Drake = drakeDetail.Parent } do
		local badge = row.Badge
		badge.BackgroundColor3 = W.ink
		local view = petPortrait(badge, key == "Drake")
		view.Active = false
		local button = W.clearButton(badge, "Preview", 0, 0, 46, 46, "Select")
		button.ZIndex = view.ZIndex + 1
		button.Activated:Connect(function()
			previewSpecies = key
			refresh()
			local list = display.Parent
			local offset = display.AbsolutePosition.Y - list.AbsolutePosition.Y
			local spare = list.AbsoluteWindowSize.Y - display.AbsoluteSize.Y
			if offset < 0 or offset > spare then
				list.CanvasPosition += Vector2.new(0, offset - spare / 2)
			end
		end)
	end
	table.insert(menu.updates, refresh)
	return 6
end
function Pages.achievements(menu)
	for i, award in Guide.achievements do
		local tint = if award.ore then W.orange else W.aqua
		local title, detail, badge = menu:row(i, award.name, "Achievements", tint)
		menu:watchRow(title.Parent, award.id, function()
			return (menu.player:GetAttribute("Award" .. award.id) or 0) >= award.goal
		end)
		title.Size = UDim2.fromOffset(251, 24)
		title.TextSize = 18
		detail.Position, detail.Size = UDim2.fromOffset(67, 28), UDim2.fromOffset(247, 32)
		detail.TextWrapped = true
		badge.Interactable, badge.AutoButtonColor = false, false
		table.insert(menu.updates, function()
			title.Text, detail.Text = Guide.awardText(award, menu.player)
			local progress = menu.player:GetAttribute("Award" .. award.id) or 0
			badge.Text = if progress >= award.goal then "Earned" else string.format("%d / %d", progress, award.goal)
			badge.BackgroundColor3 = if progress >= award.goal then W.green else W.muted
		end)
	end
	return #Guide.achievements
end

-- Ore names in the odds lists take their ore's colour, lifted so dark ores stay readable on the
-- card. `colored` is false when only measuring the text.
local function readable(color)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, math.min(s, 0.75), math.max(v, 0.72))
end
local function layerOdds(chances, player, colored)
	local entries, total = {}, 0
	local function entry(label, chance, color)
		local text = string.format("%s %s%%", label, chance)
		return if colored and color then W.colored(label, readable(color)) .. string.format(" %s%%", chance) else text
	end
	for _, ore in Ores.list do
		local chance = chances[ore.name]
		if chance then
			total += chance
			local hidden = player and ore.secret and not player:GetAttribute("Found" .. ore.name)
			table.insert(entries, entry(if hidden then "???" else ore.name, string.format("%g", chance), not hidden and ore.color or nil))
		end
	end
	local stone = math.floor((100 - total) * 10 + 0.5) / 10
	table.insert(entries, 1, entry("Stone", string.format("%g", stone), Ores.byName.Stone.color))
	return table.concat(entries, "   ")
end

function Pages.index(menu)
	W.title(menu.list, "Collection", 6, 0, 208, 25, 19, W.gold, true)
	W.title(menu.list, "Depth & ore odds", 228, 0, 213, 25, 19, W.aqua, true)
	for i, ore in Ores.list do
		local card = W.frame(menu.list, ore.name, 1, 30 + (i - 1) * 68, 216, 64, W.card, 8)
		menu:watchRow(card, ore.name, function()
			return menu.player:GetAttribute("Found" .. ore.name)
		end)
		local bar = W.frame(card, "Swatch", 5, 7, 6, 38, W.muted, 3)
		local name = W.title(card, "", 17, 1, 193, 21, 16, W.white, true)
		local worth = W.text(card, "", 17, 22, 196, 21, 14, W.muted, true)
		worth.RichText, worth.TextWrapped = true, true
		worth.TextYAlignment = Enum.TextYAlignment.Top
		local record = W.text(card, "", 17, 42, 194, 18, 14, W.aqua, true)
		table.insert(menu.updates, function()
			local found = menu.player:GetAttribute("Found" .. ore.name)
			local hidden = ore.secret and not found
			local best = menu.player:GetAttribute("BestPurity" .. ore.name) or 0
			record.Text = if best > 0 and found then "Personal best  " .. Purity.text(best) .. "  ·  " .. Purity.multiplierText(best)
				elseif found then "Discovered" elseif not hidden then "Still to find" else ""
			bar.BackgroundColor3 = if hidden then W.muted else ore.color
			name.Text = if hidden then "???" else ore.name .. (if found then "   ✓" else "")
			name.TextColor3 = if hidden or ore.host then W.white else readable(ore.color)
			-- A mystery ore shows only a hint about where to look until it is first mined.
			worth.Size = UDim2.fromOffset(196, if hidden then 38 else 21)
			worth.Text = if hidden
				then (ore.hint or "Mine it to identify")
				else W.colored(W.possiblePrice(ore, menu.player), W.gold) .. "   ·   " .. ore.xp .. " base XP"
		end)
	end
	local y = 30
	local textService = game:GetService("TextService")
	for i, layer in Config.Layers do
		local bounds = textService:GetTextSize(layerOdds(layer.oreChances), 14,
			Enum.Font.BuilderSansBold, Vector2.new(199, 10000))
		local oddsHeight = math.max(36, bounds.Y + 7)
		local themeHeight = if layer.theme
			then textService:GetTextSize(layer.theme, 12, Enum.Font.BuilderSans, Vector2.new(202, 10000)).Y + 3
			else 0
		local card = W.frame(menu.list, layer.name, 225, y, 222, 47 + themeHeight + oddsHeight, W.card, 8)
		W.title(card, layer.name, 8, 4, 206, 21, 16, W.white, true)
		local following = Config.Layers[i + 1]
		local start = math.max(Config.DirtLayers, layer.depthBlocks)
		local depth = if following
			then string.format("%d–%d blocks", start, following.depthBlocks - 1)
			else string.format("%d+ blocks", start)
		local d = W.text(card, depth, 8, 25, 202, 17, 13, W.aqua, true)
		d.Name = "Depth"
		if layer.theme then
			local theme = W.text(card, layer.theme, 8, 42, 202, themeHeight, 12, W.white)
			theme.Name, theme.TextWrapped, theme.TextTransparency = "Theme", true, 0.25
			theme.TextYAlignment = Enum.TextYAlignment.Top
		end
		local odds = W.text(card, "", 8, 42 + themeHeight, 207, oddsHeight, 14, W.muted, true)
		odds.TextWrapped, odds.RichText = true, true
		odds.TextYAlignment = Enum.TextYAlignment.Top
		table.insert(menu.updates, function()
			odds.Text = layerOdds(layer.oreChances, menu.player, true)
		end)
		y += card.Size.Y.Offset + 7
	end
	local gradesHeight = 34 + #Config.StoneGrades * 22
	local card = W.frame(menu.list, "Rock hardness", 225, y, 222, gradesHeight, W.card, 8)
	W.title(card, "Stone grades", 8, 3, 203, 23, 16, W.white, true)
	for power, grade in Config.StoneGrades do
		local lineY = 28 + (power - 1) * 22
		W.frame(card, "Swatch", 8, lineY + 3, 15, 15, grade.color, 3)
		W.text(card, grade.name, 29, lineY, 115, 21, 13, W.white, true)
		W.text(card, "P" .. power .. " · " .. grade.depth .. "+", 145, lineY, 70, 21, 12, W.aqua)
	end
	return math.ceil(math.max(30 + #Ores.list * 68, y + gradesHeight + 4) / 69)
end
return Pages
