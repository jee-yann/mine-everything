local Field = require(game.ReplicatedStorage.Shared.FieldRewards)
local Materials = require(game.ReplicatedStorage.Shared.Materials)
local W = require(script.Parent.Widgets)
local Page = {}

function Page.attendance(menu)
	local _, detail, claim = menu:row(1, "Seven-day gem card", "Crystal", W.violet)
	local stamps = {}
	detail.Text = ""
	-- Each day is a small enamel tile in the menu's style: bold numbers, today's tile breathing in
	-- gold, and a pop with a check when it is claimed.
	for i, amount in Field.stamps do
		local cell = W.frame(detail, "Day " .. i, (i - 1) * 35, 2, 32, 29, W.ink, 7)
		local stroke = W.stroke(cell, W.line, 1.5)
		local label = W.title(cell, "+" .. amount, 0, 1, 32, 27, 17, W.white)
		label.TextXAlignment = Enum.TextXAlignment.Center
		W.outlineText(label, 1)
		stamps[i] = { cell = cell, label = label, stroke = stroke, scale = W.scale(cell) }
	end
	claim.Activated:Connect(function()
		menu.net.Action:FireServer("Stamp")
	end)
	local shownCount, pulseDay
	local function motion()
		return menu.player:GetAttribute("MenuMotion") ~= false and not game:GetService("GuiService").ReducedMotionEnabled
	end
	table.insert(menu.updates, function()
		local today = menu.net:GetAttribute("OrderDay")
		local last = menu.player:GetAttribute("StampDay") or 0
		local count = menu.player:GetAttribute("StampCount") or 0
		local ready = today ~= nil and last < today
		local day = if ready then count % #Field.stamps + 1 else math.max(1, count)
		for i, stamp in stamps do
			local collected = if ready then i < day else i <= count
			local isToday = ready and i == day
			stamp.cell.BackgroundColor3 = if collected then W.green elseif isToday then W.violet else W.ink
			stamp.stroke.Color = if isToday then W.gold elseif collected then W.green:Lerp(W.white, 0.4) else W.line
			stamp.stroke.Thickness = if isToday then 2.5 else 1.5
			stamp.label.Text = if collected then "✓" else "+" .. Field.stamps[i]
			stamp.label.TextColor3 = if collected then W.ink elseif i == #stamps then W.gold else W.white
		end
		-- A claim just landed: pop the stamped tile.
		if shownCount and count > shownCount and motion() then
			local stamp = stamps[(count - 1) % #stamps + 1]
			stamp.scale.Scale = 1.45
			W.tween(stamp.scale, 0.35, { Scale = 1 })
		end
		shownCount = count
		pulseDay = if ready then day else nil
		claim.Text = if ready then "Claim +" .. Field.stamps[day] else "Claimed"
		claim.BackgroundColor3 = if ready then W.violet else W.muted
		claim.Interactable, claim.AutoButtonColor = ready, ready
	end)
	task.defer(function()
		local t = 0
		while detail.Parent and menu.overlay.Visible do
			t += task.wait(1 / 20)
			for i, stamp in stamps do
				if i == pulseDay and motion() then
					stamp.scale.Scale = 1 + 0.07 * (0.5 + 0.5 * math.sin(t * 4))
				elseif stamp.scale.Scale ~= 1 and i ~= pulseDay then
					stamp.scale.Scale = 1
				end
			end
		end
	end)
	local _, description, collect = menu:row(2, "Time in the cove", "Jobs", W.aqua)
	local shown
	local function showTime()
		shown = menu.player:GetAttribute("ShiftPrize")
		local prize = shown and Field.shiftRewards[shown]
		local due = menu.player:GetAttribute("ShiftReadyAt")
		local ready = prize ~= nil and due == 0
		if prize then
			description.Text = string.format("Play %d minutes today for %d %s", prize.seconds / 60, prize.gems,
				if prize.gems == 1 then "gem" else "gems")
			local left = math.max(0, math.ceil((due or 0) - workspace:GetServerTimeNow()))
			collect.Text = if ready then "Claim +" .. prize.gems else string.format("%d:%02d", math.floor(left / 60), left % 60)
		else
			description.Text = if shown then "All three rewards claimed today" else "Play 10, 20 and 60 minutes for gems"
			collect.Text = if shown then "Complete" else "Loading"
		end
		collect.BackgroundColor3 = if ready then W.green else W.muted
		collect.Interactable, collect.AutoButtonColor = ready, ready
	end
	collect.Activated:Connect(function() menu.net.Action:FireServer("ShiftPrize", shown) end)
	table.insert(menu.updates, showTime)
	task.defer(function()
		while collect.Parent and menu.overlay.Visible and menu.page == "Jobs" do
			showTime()
			task.wait(1)
		end
	end)
	return 2
end

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
