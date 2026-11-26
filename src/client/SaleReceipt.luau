-- What a haul sold for. It counts up, stays long enough to read, and only then does the gold move.
local RunService = game:GetService("RunService")
local W = require(script.Parent.Widgets)
local Burst = require(script.Parent.Burst)
local Flow = require(script.Parent.GoldFlow)
local Receipt = {}
Receipt.__index = Receipt
Receipt.wait = 1.35

function Receipt.new(hud)
	return setmetatable({ hud = hud, serial = 0 }, Receipt)
end

function Receipt:show(amount, quantity, _, ore)
	self.serial += 1
	local serial = self.serial
	local hud = self.hud
	if self.panel then
		self.panel:Destroy()
	end
	local panel = W.frame(hud.root, "Sale receipt", 0, 0, 360, 112, W.panel)
	panel.BackgroundTransparency, panel.ZIndex = 1, 7
	self.panel = panel
	local position = if hud.unlocks.playing then UDim2.new(0.5, 0, 0.41, 124) else UDim2.fromScale(0.5, 0.35)
	if hud.overlay.Visible and hud.menu.modal.Visible then
		local top = hud.menu.modal.AbsolutePosition.Y - hud.root.AbsolutePosition.Y
		position = UDim2.new(0.5, 0, 0, math.max(56, top - 46))
	end
	W.anchor(panel, 0.5, 0.5, position)
	local group = W.fadeGroup(panel, "Receipt face", 360, 112)
	local sold = W.title(group,
		string.format("Sold %s %s", W.goldAmount(quantity), ore or (if quantity == 1 then "block" else "blocks")),
		3, 4, 354, 30, 24, W.white)
	W.navyText(sold, 2.6)
	local payout = W.title(group, "+" .. W.goldAmount(amount) .. " gold", 2, 34, 356, 70, 56, W.gold)
	payout.TextScaled = true
	local font = Instance.new("UITextSizeConstraint")
	font.MinTextSize, font.MaxTextSize, font.Parent = 18, 56, payout
	W.navyText(payout, 3.6)
	local motion = Burst.allowed(hud.player)
	hud.goldFlow:hold(Receipt.wait, payout)
	local seconds = Flow.plan(amount)
	if motion then
		local scale = W.scale(panel)
		Burst.pop(scale, 1, 0.6)
		local payoutScale = W.scale(payout)
		task.spawn(function()
			local start, length = os.clock(), 0.75
			repeat
				local t = math.min((os.clock() - start) / length, 1)
				payout.Text = "+" .. W.goldAmount(math.round(amount * (1 - (1 - t) ^ 3))) .. " gold"
				RunService.RenderStepped:Wait()
			until t >= 1 or self.serial ~= serial or not payout.Parent
			if self.serial == serial and payout.Parent then Burst.pop(payoutScale, 1, 1.18) end
		end)
	end
	-- The receipt stays while its coins are leaving.
	task.delay(Receipt.wait + (if motion then math.max(0.6, seconds * 0.75) else 0.6), function()
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
