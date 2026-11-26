local Shared = game.ReplicatedStorage.Shared
local E, Guide = require(Shared.Expeditions), require(Shared.FieldGuide)
local W = require(script.Parent.Widgets)
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
	W.rowPanel(display, W.violet)
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

return Pages
