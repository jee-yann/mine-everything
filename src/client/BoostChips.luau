-- Small chips under the region name for every boost that is running: tonics, timed gold and luck,
-- the Star Compass and Server Luck (with the name of whoever bought it). Each counts down, and a tap
-- opens the Shop's boosts.
local Rep = game:GetService("ReplicatedStorage")
local C, Bonuses = require(Rep.Shared.Collectibles), require(Rep.Shared.Bonuses)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local rgb = Color3.fromRGB
local looks = {
	goldTonic = { "Coins", rgb(255, 214, 90) },
	gold2 = { "Coins", rgb(255, 214, 90) },
	speedTonic = { "Speed", rgb(150, 230, 255) },
	luck2 = { "Boosts", rgb(150, 255, 140) },
	luck3 = { "Boosts", rgb(150, 255, 140) },
	compass = { "Rebirth", rgb(255, 236, 150) },
	server = { "Friends", rgb(190, 255, 150) },
}

return function(hud)
	local player = hud.player
	local holder = W.frame(hud.root, "Boosts", 0, 0, 600, 34, W.ink)
	holder.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout")
	layout.FillDirection, layout.HorizontalAlignment = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center
	layout.Padding, layout.SortOrder = UDim.new(0, 6), Enum.SortOrder.LayoutOrder
	layout.Parent = holder
	local chips = {}
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
		b.Activated:Connect(function() hud:openPage("ShopBoosts") end)
		entry = { button = b, label = label }
		chips[key] = entry
		return entry
	end
	task.spawn(function()
		while holder.Parent do
			local state = Bonuses.state(player)
			local seen = {}
			local order = 0
			for key, boost in C.boosts do
				local left = Bonuses.left(state, key)
				if left > 0 then
					order += 1
					seen[key] = true
					local entry = chip(key, order)
					entry.label.Text = boost.name .. " " .. W.clock(left)
					local width = math.clamp(#entry.label.Text * 8 + 40, 110, 190)
					entry.button.Size = UDim2.fromOffset(width, 32)
					entry.label.Size = UDim2.fromOffset(width - 36, 30)
				end
			end
			local serverLeft = state.serverLuckUntil - state.now
			if serverLeft > 0 then
				seen.server = true
				local entry = chip("server", 0)
				entry.label.Text = "Server Luck 2× " .. W.clock(serverLeft) .. " · " .. (Rep:GetAttribute("ServerLuckBy") or "")
				local width = math.clamp(#entry.label.Text * 7.5 + 40, 150, 300)
				entry.button.Size = UDim2.fromOffset(width, 32)
				entry.label.Size = UDim2.fromOffset(width - 36, 30)
			end
			for key, entry in chips do
				if not seen[key] then
					entry.button:Destroy()
					chips[key] = nil
				end
			end
			-- Under the region name, and under the Surface button when it shows.
			local loc = hud.layer.Parent
			local bottom = loc.AbsolutePosition.Y + loc.AbsoluteSize.Y - hud.root.AbsolutePosition.Y
			if hud.surface.Visible then bottom += hud.surface.AbsoluteSize.Y + 6 end
			W.anchor(holder, 0.5, 0, UDim2.fromOffset(loc.AbsolutePosition.X - hud.root.AbsolutePosition.X + loc.AbsoluteSize.X / 2, bottom + 4))
			holder.Visible = loc.Visible and next(seen) ~= nil
			task.wait(0.5)
		end
	end)
	return holder
end
