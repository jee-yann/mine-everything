-- Boosts and bonuses, grouped by what they do: one icon each for Mining speed, Movement speed,
-- Backpack, Gold and Luck, shown only while something feeds that group, with the combined total under
-- it. A tap lists every source in the message at the bottom middle, which fades after a few seconds:
-- passes, timed boosts (with the time left), Server Luck (and who bought it), the worn effects,
-- rebirths and skills. Desktop keeps them in the bottom right
-- corner, clear of the reward buttons; touch screens put them in the very bottom right corner, beside
-- the jump and Mine buttons (Hud.bonusCorner).
local Rep = game:GetService("ReplicatedStorage")
local C, Bonuses = require(Rep.Shared.Collectibles), require(Rep.Shared.Bonuses)
local Rebirth, Skills = require(Rep.Shared.Rebirth), require(Rep.Shared.Skills)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local rgb = Color3.fromRGB

local groups = {
	{ id = "mining", icon = "Power", tint = rgb(255, 180, 90), title = "Mining speed" },
	{ id = "move", icon = "Speed", tint = rgb(150, 255, 120), title = "Movement speed" },
	{ id = "pack", icon = "Pack", tint = rgb(140, 230, 255), title = "Backpack" },
	{ id = "gold", icon = "Coins", tint = rgb(255, 214, 90), title = "Gold" },
	{ id = "luck", icon = "Crystal", tint = rgb(140, 255, 200), title = "Luck" },
}
-- Timed boosts (Collectibles.boosts keys, and Server Luck) by group.
local timedGroup = {
	speedTonic = "mining", instamine = "mining",
	goldTonic = "gold", gold2 = "gold",
	luck2 = "luck", server = "luck",
	autosell = "pack",
}
-- Passes that last: their group and what they add.
local passes = {
	{ "FastPick", "mining", "Fast Pick pass: +30% mining speed" },
	{ "BiggerPack", "pack", "Bigger Pack pass: +50% backpack space" },
	{ "DoubleGold", "gold", "Double Gold pass: 2× gold on every sale" },
	{ "VIP", "gold", "VIP pass: +20% gold" },
	{ "Lucky", "luck", "2× Lucky pass: rare ore turns up twice as often" },
	{ "StarfallCompass", "luck", "Starfall Compass: finds nearby Starfall" },
}
-- Skill effects (Skills.luau) by group, plus the few skills with a special rule.
local skillGroup = {
	cut = "mining", stone = "mining", deep = "mining", crater = "mining", crowdCut = "mining",
	streakStep = "mining", streakCap = "mining",
	walk = "move",
	pack = "pack", slots = "pack",
	gold = "gold", crowdGold = "gold",
	luck = "luck", rare = "luck",
}
local specialSkills = { PackMule = "move", Rockhound = "move", RebornTrader = "gold" }

local function times(x)
	local rounded = math.floor(x * 10 + 0.5) / 10
	return "×" .. (if rounded == math.floor(rounded) then string.format("%d", rounded) else string.format("%.1f", rounded))
end

return function(hud)
	local player = hud.player
	local row = W.frame(hud.hudFrame, "Bonus groups", 0, 0, 240, 40, W.ink)
	row.BackgroundTransparency, row.Visible = 1, false
	-- Desktop grows the row with the screen (touch screens scale the whole HUD layer instead).
	local rowScale = W.scale(row)
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection, rowLayout.HorizontalAlignment = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	rowLayout.Padding, rowLayout.SortOrder = UDim.new(0, 5), Enum.SortOrder.LayoutOrder
	rowLayout.Parent = row

	local entries = {}
	local function tell(entry)
		local group = entry.group
		local lines = table.clone(entry.lines)
		-- Five lines at most; the rest are summed up.
		if #lines > 5 then
			local more = #lines - 4
			lines = { lines[1], lines[2], lines[3], lines[4], "and " .. more .. " more" }
		end
		hud:notice(group.title .. (if entry.total.Text ~= "" then "  " .. entry.total.Text else ""), table.concat(lines, "\n"), group.tint, 4)
	end
	for i, group in groups do
		local b = W.clearButton(row, group.title, 0, 0, 40, 40, "Select")
		b.LayoutOrder, b.Visible = i, false
		local disc = W.frame(b, "Disc", 2, 0, 36, 36, W.white, 18)
		W.enamelPanel(disc, rgb(110, 100, 190), rgb(52, 46, 110), 18)
		local edge = disc:FindFirstChildOfClass("UIStroke")
		edge.Thickness = 2.5
		Icons.draw(disc, group.icon, 6, 5, 24, group.tint)
		local total = W.title(b, "", -8, 34, 56, 16, 13, group.tint)
		total.Name = "Total"
		W.navyText(total, 1.8)
		local count = W.title(b, "", 24, -5, 18, 16, 12, W.white)
		count.ZIndex = 6
		W.navyText(count, 1.6)
		local entry = { group = group, button = b, total = total, count = count, edge = edge, lines = {} }
		b.Activated:Connect(function()
			tell(entries[group.id])
		end)
		entries[group.id] = entry
	end

	-- Tells a group's sources as a tap does (tests and photos use it).
	hud.openBonus = function(id)
		if entries[id] then tell(entries[id]) end
	end
	task.spawn(function()
		while row.Parent do
			local state = Bonuses.state(player)
			local owned = state.skills or {}
			local lines = { mining = {}, move = {}, pack = {}, gold = {}, luck = {} }
			local timed = {}
			local function add(group, text)
				table.insert(lines[group], text)
			end
			-- Timed boosts first, with the time left.
			for key, boost in C.boosts do
				local left = Bonuses.left(state, key)
				local group = timedGroup[key]
				if left > 0 and group then
					add(group, boost.name .. " · " .. W.clock(left) .. " left")
					timed[group] = true
				end
			end
			local serverLeft = state.serverLuckUntil - state.now
			if serverLeft > 0 then
				local by = Rep:GetAttribute("ServerLuckBy")
				add("luck", "Server Luck 2× · " .. W.clock(serverLeft) .. " left" .. (if by and by ~= "" then " · from " .. by else ""))
				timed.luck = true
			end
			for _, pass in passes do
				if state.passes[pass[1]] then add(pass[2], pass[3]) end
			end
			-- What you wear, and rebirths.
			local col = Bonuses.decode(player:GetAttribute("Collection")) or {}
			local worn = C.wornSpeed(col)
			if worn > 0 then add("move", "Your Player FX: +" .. worn .. "% movement speed") end
			local fx = C.mineSpeed("trail", col.trail)
			if fx > 0 then add("mining", "Your Mining FX: +" .. fx .. "% mining speed") end
			local reborn = player:GetAttribute("Rebirths") or 0
			local cut = Rebirth.cutMultiplier(reborn)
			if reborn > 0 then
				add("gold", string.format("Rebirth %d: ×%d gold", reborn, Rebirth.goldMultiplier(reborn)))
				local faster = math.round((1 - cut) * 100)
				if faster > 0 then add("mining", string.format("Rebirth %d: cuts %d%% faster", reborn, faster)) end
			end
			-- Skills, by name.
			local skillNames = { mining = {}, move = {}, pack = {}, gold = {}, luck = {} }
			for _, node in Skills.nodes do
				if owned[node.id] then
					local group = specialSkills[node.id] or (node.effect and skillGroup[node.effect])
					if group then table.insert(skillNames[group], node.name) end
				end
			end
			for group, names in skillNames do
				if #names > 0 then add(group, "Skills: " .. table.concat(names, ", ")) end
			end
			-- Totals under the icons.
			local totals = {}
			totals.gold = times(Bonuses.gold(state))
			totals.luck = times(Bonuses.luck(state))
			local mining = (1 + Bonuses.speed(state)) / math.max(cut, 0.01) - 1
			totals.mining = if Bonuses.instant(state) then "MAX" elseif mining > 0.005 then "+" .. math.round(mining * 100) .. "%" else ""
			local walk = (16 + Skills.bonus(owned, "walk")) / 16 * (1 + worn / 100) - 1
			totals.move = if walk > 0.005 then "+" .. math.round(walk * 100) .. "%" else ""
			local pack = (if state.passes.BiggerPack then 50 else 0) + Skills.bonus(owned, "pack")
			totals.pack = if pack > 0 then "+" .. pack .. "%" elseif Bonuses.autoSell(state) then "AUTO" else ""

			-- Touch screens: smaller, no totals (a tap tells them), in the very bottom right corner.
			local touch = hud.railsOnEdge == true
			local shown = 0
			for id, entry in entries do
				local list = lines[id]
				local on = #list > 0
				entry.button.Visible = on
				entry.lines = list
				if on then shown += 1 end
				entry.count.Text = if #list > 1 then tostring(#list) else ""
				entry.total.Text = totals[id] or ""
				entry.total.Visible = not touch
				entry.button.Size = UDim2.fromOffset(40, if touch then 38 else 52)
				-- A timed boost running in the group: the rim turns green.
				entry.edge.Color = if timed[id] then W.green else W.navy
			end
			local playing = hud.layer.Parent.Visible
			row.Visible = shown > 0 and playing
			row.Size = UDim2.fromOffset(shown * 45, if touch then 38 else 52)
			if hud.bonusCount ~= shown then
				hud.bonusCount = shown
				if hud.layout then hud.layout() end
			end
			local size = hud:layerSize()
			if touch then
				rowScale.Scale = 1
				local corner = hud.bonusCorner or Vector2.new(size.X - 2, size.Y - 2)
				W.anchor(row, 1, 1, UDim2.fromOffset(corner.X, corner.Y))
			else
				-- Desktop: the bottom right corner, or left of the reward buttons if they reach down there.
				rowScale.Scale = (hud.deskScale or 1) * 1.3
				local right, bottom = size.X - 14, size.Y - 14
				local rail = hud.rewardRail
				if rail and rail.Visible then
					local k = hud.hudScale
					local top = (rail.AbsolutePosition.Y - hud.root.AbsolutePosition.Y) / k
					local railBottom = top + rail.AbsoluteSize.Y / k
					local railLeft = (rail.AbsolutePosition.X - hud.root.AbsolutePosition.X) / k
					if bottom - 52 * rowScale.Scale < railBottom and bottom > top and right > railLeft then
						right = railLeft - 10
					end
				end
				W.anchor(row, 1, 1, UDim2.fromOffset(right, bottom))
			end
			task.wait(0.5)
		end
	end)
	return row
end
