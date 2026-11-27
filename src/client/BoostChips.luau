-- The bottom right corner: chips for every boost that is running (tonics, timed gold and luck,
-- Instamine, Auto Sell and Server Luck with the name of whoever bought it), each counting down, and
-- under them a row of circles for the bonuses that last (passes, and the movement speed of the effect
-- you're wearing). Tap a chip for the Shop's boosts, a circle for what it does. On a phone they sit
-- higher, clear of the touch buttons.
local Rep = game:GetService("ReplicatedStorage")
local C, Bonuses = require(Rep.Shared.Collectibles), require(Rep.Shared.Bonuses)
local Rebirth = require(Rep.Shared.Rebirth)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local rgb = Color3.fromRGB
local looks = {
	goldTonic = { "Coins", rgb(255, 214, 90) },
	gold2 = { "Coins", rgb(255, 214, 90) },
	speedTonic = { "Speed", rgb(150, 230, 255) },
	luck2 = { "Boosts", rgb(150, 255, 140) },
	instamine = { "Power", rgb(255, 170, 120) },
	autosell = { "Coins", rgb(140, 230, 255) },
	server = { "Friends", rgb(190, 255, 150) },
}
-- Lasting bonuses, as circles: the pass (or the worn effect), its icon, a short label and what it does.
local circles = {
	{ "DoubleGold", "Coins", "2×", "Double Gold: 2× gold on every sale" },
	{ "VIP", "Achievements", "VIP", "VIP: +20% gold, +20% XP and a free Starfall Crate every day" },
	{ "Lucky", "Crystal", "2×", "2× Lucky: rare ore turns up twice as often" },
	{ "FastPick", "Speed", "+30%", "Fast Pick: +30% mining speed" },
	{ "BiggerPack", "Pack", "+50%", "Bigger Pack: +50% backpack capacity" },
	{ "StarfallCompass", "Crystal", "★", "Starfall Compass: every 2 minutes underground, points to any Starfall within 3 blocks" },
}

return function(hud)
	local player = hud.player
	local holder = W.frame(hud.root, "Boosts", 0, 0, 320, 200, W.ink)
	holder.BackgroundTransparency = 1
	local fit = W.scale(holder)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection, layout.HorizontalAlignment = Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Padding, layout.SortOrder = UDim.new(0, 6), Enum.SortOrder.LayoutOrder
	layout.Parent = holder
	local chips = {}
	-- The circles, in one row along the bottom.
	local row = W.frame(holder, "Bonuses", 0, 0, 320, 58, W.ink)
	row.BackgroundTransparency, row.LayoutOrder = 1, 1000
	local across = Instance.new("UIListLayout")
	across.FillDirection, across.HorizontalAlignment = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right
	across.VerticalAlignment, across.Padding, across.SortOrder = Enum.VerticalAlignment.Bottom, UDim.new(0, 6), Enum.SortOrder.LayoutOrder
	across.Parent = row
	local rings = {}
	local function ring(key, icon, short, about, order, tone)
		local entry = rings[key]
		if entry then return entry end
		local b = W.clearButton(row, key, 0, 0, 46, 58, "Select")
		b.LayoutOrder = order
		local disc = W.frame(b, "Disc", 3, 0, 40, 40, W.white, 20)
		W.enamelPanel(disc, rgb(110, 100, 190), rgb(52, 46, 110), 20)
		Icons.draw(disc, icon, 7, 6, 26)
		local label = W.title(b, short, -6, 38, 58, 18, 13, tone or rgb(255, 244, 170))
		label.Name = "Short"
		W.navyText(label, 1.8)
		b.Activated:Connect(function() hud:notice(about, "", W.gold) end)
		entry = { button = b, label = label }
		rings[key] = entry
		return entry
	end
	local function chip(key, order)
		local entry = chips[key]
		if entry then return entry end
		local look = looks[key]
		local b = W.clearButton(holder, key, 0, 0, 132, 32, "Select")
		b.LayoutOrder = order
		W.round(b, 16)
		W.enamelPanel(b, rgb(72, 68, 124), rgb(46, 43, 86), 16)
		Icons.draw(b, look[1], 4, 2, 26, look[2])
		local label = W.title(b, "", 32, 0, 96, 30, 15, look[2], true)
		W.navyText(label, 2)
		label.ZIndex = 3
		entry = { button = b, label = label }
		-- On a phone the chip is just its icon: a tap says what it is and how long it has left.
		b.Activated:Connect(function()
			if entry.tiny then hud:notice(entry.label.Text, "", look[2]) else hud:openPage("ShopBoosts") end
		end)
		chips[key] = entry
		return entry
	end
	task.spawn(function()
		while holder.Parent do
			local state = Bonuses.state(player)
			local tiny = hud.edgeMode == true and hud.root.AbsoluteSize.Y < 500
			local seen = {}
			local order = 0
			for key, boost in C.boosts do
				local left = Bonuses.left(state, key)
				if left > 0 then
					order += 1
					seen[key] = true
					local entry = chip(key, order)
					entry.label.Text = boost.name .. " " .. W.clock(left)
					local width = if tiny then 32 else math.clamp(#entry.label.Text * 8 + 40, 110, 190)
					entry.tiny, entry.label.Visible = tiny, not tiny
					entry.button.Size = UDim2.fromOffset(width, 32)
					entry.label.Size = UDim2.fromOffset(width - 36, 30)
				end
			end
			local serverLeft = state.serverLuckUntil - state.now
			if serverLeft > 0 then
				seen.server = true
				local entry = chip("server", 0)
				entry.label.Text = "Server Luck 2× " .. W.clock(serverLeft) .. " · " .. (Rep:GetAttribute("ServerLuckBy") or "")
				local width = if tiny then 32 else math.clamp(#entry.label.Text * 7.5 + 40, 150, 300)
				entry.tiny, entry.label.Visible = tiny, not tiny
				entry.button.Size = UDim2.fromOffset(width, 32)
				entry.label.Size = UDim2.fromOffset(width - 36, 30)
			end
			for key, entry in chips do
				if not seen[key] then
					entry.button:Destroy()
					chips[key] = nil
				end
			end
			-- Lasting bonuses.
			local kept = {}
			for i, info in circles do
				if state.passes[info[1]] then
					kept[info[1]] = true
					ring(info[1], info[2], info[3], info[4], i)
				end
			end
			local col = Bonuses.decode(player:GetAttribute("Collection")) or {}
			local speed = C.wornSpeed(col)
			if speed > 0 then
				local key = "Speed" .. speed
				kept[key] = true
				ring(key, "Speed", "+" .. speed .. "%", "Your Player FX: +" .. speed .. "% movement speed", -2, rgb(150, 255, 120))
			end
			local mine = C.mineSpeed("trail", col.trail)
			if mine > 0 then
				local key = "Mine" .. mine
				kept[key] = true
				ring(key, "Power", "+" .. mine .. "%", "Your Mining FX: +" .. mine .. "% mining speed", -1, rgb(255, 180, 90))
			end
			local reborn = player:GetAttribute("Rebirths") or 0
			if reborn > 0 then
				local key = "Rebirth" .. reborn
				kept[key] = true
				local cut = math.round((1 - Rebirth.cutMultiplier(reborn)) * 100)
				ring(key, "Rebirth", "×" .. Rebirth.goldMultiplier(reborn), string.format("Rebirth %d: ×%d gold, +%d%% XP, %d%% faster cutting",
					reborn, Rebirth.goldMultiplier(reborn), math.round((Rebirth.xpMultiplier(reborn) - 1) * 100), cut), -3, rgb(255, 160, 170))
			end
			for key, entry in rings do
				entry.label.Visible = not tiny
				if not kept[key] then
					entry.button:Destroy()
					rings[key] = nil
				end
			end
			row.Visible = next(kept) ~= nil
			if row.Visible then seen.row = true end
			-- The bottom right corner; on phones much smaller, against the right edge above the touch buttons.
			local size = hud.root.AbsoluteSize
			local phone = hud.edgeMode == true and size.Y < 500
			fit.Scale = if phone then 0.45 else 1
			local spot = if phone then hud.bonusSpot else nil
			W.anchor(holder, 1, 1, if spot then UDim2.fromOffset(spot.X, spot.Y)
				else UDim2.fromOffset(size.X - 14, if hud.edgeMode then size.Y * 0.62 else size.Y - 14))
			holder.Visible = hud.layer.Parent.Visible and next(seen) ~= nil
			task.wait(0.5)
		end
	end)
	return holder
end
