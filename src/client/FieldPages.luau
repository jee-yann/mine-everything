local Shared = game.ReplicatedStorage.Shared
local E, Guide = require(Shared.Expeditions), require(Shared.FieldGuide)
local W = require(script.Parent.Widgets)
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
function Pages.achievements(menu)
	for i, award in Guide.achievements do
		-- One colour for every achievement (for now).
		local tint = W.orange
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
