local Materials = require(game.ReplicatedStorage.Shared.Materials)
local W = require(script.Parent.Widgets)
local Page = {}

function Page.extraKit(menu)
	local p = menu.player
	for i, key in { "Haste", "Chips", "Pulse", "Compass", "Aura" } do
		local item = Materials.supplies[key]
		local _, detail, b = menu:row(i + 2, if item then item.name else "First Light", if key == "Compass" then "Pets" else "Power", W.aqua)
		if key == "Pulse" then
			b.Activated:Connect(function() menu.net.Action:FireServer("Pulse") end)
		elseif key == "Aura" then
			b.Activated:Connect(function() menu.net.Action:FireServer("Aura", not p:GetAttribute("FirstLight")) end)
		end
		table.insert(menu.updates, function()
			local enabled = false
			if key == "Aura" then
				enabled = p:GetAttribute("AuraUnlocked") == true
				detail.Text = if enabled then "A gold-and-blue trail on your pick" else "Unlock with your first gear upgrade"
				b.Text = if not enabled then "Locked" elseif p:GetAttribute("FirstLight") then "Unequip" else "Equip"
			elseif key == "Compass" then
				detail.Text = "Equip a pet to spot ore you can see"
				b.Text = if p:GetAttribute("OreCompass") then "Equipped" else "Craft in town"
			elseif key == "Pulse" then
				local count = p:GetAttribute("CavePulses") or 0
				detail.Text = count .. " packed · clears stone without loot"
				b.Text, enabled = if count > 0 then "Use in mine" else "Empty", count > 0
			else
				local count = p:GetAttribute(item.stock) or 0
				detail.Text = item.detail
				b.Text = count .. " cuts left"
			end
			b.Interactable, b.AutoButtonColor = enabled, enabled
			b.BackgroundColor3 = if enabled then W.green else W.muted
		end)
	end
	return 7
end

return Page
