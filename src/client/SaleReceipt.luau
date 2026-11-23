local RunService = game:GetService("RunService")
local W = require(script.Parent.Widgets)
local Upgrades = require(game.ReplicatedStorage.Shared.Upgrades)
local function nextUpgrade(player, gold)
	local key, price
	local step = player:GetAttribute("ExpeditionStep")
	if (step == "Sell" or step == "Upgrade") and (player:GetAttribute("Capacity") or 1) == 1 and (player:GetAttribute("Speed") or 1) == 1 then
		key, price = Upgrades.onboardingPick(gold)
	else
		for _, candidate in Upgrades.order do
			local cost = Upgrades.price(candidate, player:GetAttribute(candidate) or 1)
			if cost and (not price or cost < price) then key, price = candidate, cost end
		end
	end
	if not key then return "" end
	local name = if key == "Power" then Upgrades.pickNames[(player:GetAttribute("Power") or 1) + 1]
		elseif key == "Capacity" then "Backpack" else "Speed"
	return if gold >= price then name .. " upgrade ready" else W.goldAmount(price - gold) .. " G to " .. name
end
local Receipt = {}
Receipt.__index = Receipt

function Receipt.new(hud)
	return setmetatable({ hud = hud, serial = 0 }, Receipt)
end

function Receipt:show(amount, quantity, balance, ore)
	self.serial += 1
	local serial = self.serial
	local hud = self.hud
	if self.panel then
		self.panel:Destroy()
	end
	local panel = W.frame(hud.root, "Sale receipt", 0, 0, 308, 104, W.panel)
	panel.BackgroundTransparency, panel.ZIndex = 1, 7
	self.panel = panel
	local position = if hud.unlocks.playing then UDim2.new(0.5, 0, 0.41, 114) else UDim2.fromScale(0.5, 0.35)
	if hud.overlay.Visible and hud.menu.modal.Visible then
		local top = hud.menu.modal.AbsolutePosition.Y - hud.root.AbsolutePosition.Y
		position = UDim2.new(0.5, 0, 0, math.max(47, top - 51))
	end
	W.anchor(panel, 0.5, 0.5, position)
	local group = W.fadeGroup(panel, "Receipt face", 308, 104)
	local sold = W.text(group,
		string.format("Sold %s %s", W.goldAmount(quantity), ore or (if quantity == 1 then "block" else "blocks")),
		3, 5, 302, 24, 19, W.white)
	W.outlineText(sold, 2)
	local payout = W.title(group, "+" .. W.goldAmount(amount) .. " gold", 2, 26, 304, 56, 46, W.gold)
	payout.TextScaled = true
	local font = Instance.new("UITextSizeConstraint")
	font.MinTextSize, font.MaxTextSize, font.Parent = 18, 46, payout
	W.outlineText(payout, 3)
	local goal = W.text(group, nextUpgrade(hud.player, balance), 5, 79, 298, 22, 16, W.white)
	W.outlineText(goal, 1.5)
	local motion = hud.player:GetAttribute("MenuMotion") ~= false and not game:GetService("GuiService").ReducedMotionEnabled
	if motion then
		hud.countingGold = true
		local before = balance - amount
		local scale = W.scale(panel)
		scale.Scale = 0.86
		W.tween(scale, 0.20, { Scale = 1 })
		for i = 1, (if hud.wallet.Visible then 5 else 0) do
			local coin = W.frame(panel, "Sale coin", 0, 0, 12, 12, W.gold, 8)
			coin.ZIndex = 2
			W.stroke(coin, W.orange, 2)
			coin.AnchorPoint = Vector2.new(0.5, 0.5)
			coin.Position = UDim2.fromScale((i - 0.5) / 5, 0.8)
			task.delay(0.22 + 0.045 * i, function()
				if self.serial == serial and coin.Parent then
					local dest = hud.gold.AbsolutePosition
						+ Vector2.new(12, hud.gold.AbsoluteSize.Y / 2)
						- panel.AbsolutePosition
					W.tween(coin, 0.4, { Position = UDim2.fromOffset(dest.X, dest.Y), BackgroundTransparency = 0.2 })
					task.delay(0.4, function()
						coin:Destroy()
					end)
				end
			end)
		end
		task.spawn(function()
			local start = os.clock()
			repeat
				local t = math.min((os.clock() - start) / 0.8, 1)
				hud.gold.Text = W.goldAmount(before + math.round(amount * (1 - (1 - t) ^ 2)))
				RunService.RenderStepped:Wait()
			until self.serial ~= serial or os.clock() - start >= 0.8
			if self.serial == serial then
				hud.countingGold = false
				if hud.wallet.Visible then
					local pulse = hud.gold:FindFirstChildOfClass("UIScale") or W.scale(hud.gold)
					pulse.Scale = 1.14
					W.tween(pulse, 0.3, { Scale = 1 })
				end
				hud:refresh()
			end
		end)
	else
		hud.countingGold = false
		hud:refresh()
	end
	task.delay(1.4, function()
		if self.serial ~= serial then
			return
		end
		if motion then
			W.tween(panel, 0.38, { Position = panel.Position - UDim2.fromOffset(0, 16) })
		end
		W.tween(group, 0.38, { GroupTransparency = 1 }).Completed:Once(function()
			if self.serial == serial then
				panel:Destroy()
				self.panel = nil
			end
		end)
	end)
end
return Receipt
