-- Gold arrives instead of appearing. The total waits, then climbs tick by tick: a coin lands, the coin
-- icon swells and settles, and a coin sounds, until the whole amount is in.
local Run = game:GetService("RunService")
local W = require(script.Parent.Widgets)
local Audio = require(script.Parent.HarborAudio)
local Burst = require(script.Parent.Burst)
local Flow = {}
Flow.__index = Flow
local rng = Random.new()

-- How long a payout takes to count up, and in how many ticks.
function Flow.plan(amount)
	local seconds = math.clamp(0.7 + 0.8 * math.log10(math.max(1, amount)), 0.7, 4)
	local ticks = math.clamp(math.round(seconds * 9), 4, 36)
	return seconds, math.min(ticks, math.max(1, math.floor(amount)))
end

function Flow.new(hud)
	local self = setmetatable({ hud = hud, startAt = 0 }, Flow)
	return self
end

function Flow:paint()
	local hud = self.hud
	local text = W.goldAmount(self.shown)
	hud.gold.Text = text
	hud.menu.gold.Text, hud.menu.gold.TextSize = text .. " G", if #text > 8 then 23 elseif #text > 5 then 28 else 35
end

-- Where coins land: the purse in an open shop, otherwise the wallet.
function Flow:target()
	local hud = self.hud
	local menu = hud.menu
	if hud.overlay.Visible then
		if menu.purse.Visible and menu.modal.Visible and not menu.wide then return menu.purseCoin, menu.purseScale end
		return nil
	end
	return if hud.wallet.Visible then hud.coin else nil, hud.coinScale
end

-- Keep the total where it is for a while, so a sale can be read first. Coins will come from `from`.
function Flow:hold(seconds, from)
	self.startAt = math.max(self.startAt, os.clock() + seconds)
	self.from = from
end

function Flow:set(total)
	if not self.shown or not Burst.allowed(self.hud.player) then
		self.serial = (self.serial or 0) + 1
		self.shown, self.goal, self.running = total, total, false
		self:paint()
		return
	end
	if total == self.goal then
		self:paint()
		return
	end
	local rising = total > self.shown
	self.goal = total
	if not rising then
		-- Spending is quick and quiet.
		self.serial = (self.serial or 0) + 1
		local serial, from, start = self.serial, self.shown, os.clock()
		self.running = false
		task.spawn(function()
			repeat
				local t = math.min((os.clock() - start) / 0.35, 1)
				self.shown = math.round(from + (total - from) * (1 - (1 - t) ^ 2))
				self:paint()
				Run.RenderStepped:Wait()
			until t >= 1 or self.serial ~= serial
		end)
		return
	end
	if self.running then return end
	self.running = true
	self.serial = (self.serial or 0) + 1
	local serial = self.serial
	-- A sale tells us to wait a moment after its gold has already replicated.
	self.startAt = math.max(self.startAt, os.clock() + 0.3)
	task.spawn(function()
		while os.clock() < self.startAt do
			Run.RenderStepped:Wait()
		end
		self:run(serial)
	end)
end

function Flow:coin(from, delay)
	local hud = self.hud
	local icon = self:target()
	if not icon or not from or not from.Parent then return end
	local origin = hud.root.AbsolutePosition
	local start = from.AbsolutePosition + from.AbsoluteSize / 2 - origin + Vector2.new(rng:NextNumber(-70, 70), rng:NextNumber(-12, 22))
	local coin = W.frame(hud.root, "Sale coin", start.X, start.Y, 20, 20, W.gold, 10)
	coin.AnchorPoint, coin.ZIndex = Vector2.one * 0.5, 45
	W.stroke(coin, Color3.fromRGB(150, 88, 12), 2.5)
	W.frame(coin, "Face", 5, 5, 10, 10, Color3.fromRGB(255, 236, 150), 5)
	local finish = icon.AbsolutePosition + icon.AbsoluteSize / 2 - origin
	W.tween(coin, delay, { Position = UDim2.fromOffset(finish.X, finish.Y) }).Completed:Once(function() coin:Destroy() end)
end

-- "+340" in green beside the total: everything this payout adds, while it is counted in.
function Flow:tick(amount, fresh)
	local hud = self.hud
	local menu = hud.menu
	local icon = self:target()
	local label = self.gain
	if not icon or amount <= 0 then
		if label then label.Visible = false end
		return
	end
	if not label then
		label = W.title(hud.root, "", 0, 0, 150, 40, 32, W.green, true)
		label.Name, label.ZIndex = "Gold gain", 46
		W.navyText(label, 3.2)
		self.gain, self.gainScale = label, W.scale(label)
	end
	local origin = hud.root.AbsolutePosition
	if icon == menu.purseCoin then
		-- The purse has no room beside its total, so it hangs from the purse's lower right corner.
		local corner = menu.purse.AbsolutePosition + menu.purse.AbsoluteSize - origin
		label.AnchorPoint, label.TextXAlignment = Vector2.new(1, 0.5), Enum.TextXAlignment.Right
		label.Position = UDim2.fromOffset(corner.X - 10, corner.Y)
	else
		local total = hud.gold
		local at = total.AbsolutePosition - origin
		label.AnchorPoint, label.TextXAlignment = Vector2.new(0, 0.5), Enum.TextXAlignment.Left
		label.Position = UDim2.fromOffset(at.X + total.TextBounds.X + 12, at.Y + total.AbsoluteSize.Y / 2)
	end
	local text = "+" .. W.goldAmount(amount)
	if label.Text ~= text or fresh then
		label.Text = text
		Burst.pop(self.gainScale, 1, if fresh then 1.4 else 1.15)
	end
	for _, fade in self.fades or {} do
		fade:Cancel()
	end
	label.Visible, label.TextTransparency, label.UIStroke.Transparency = true, 0, 0
	self.gainUntil = os.clock() + 0.6
	self:settle()
end

-- Lets the green total go once nothing is being counted in. A count can be cut short (gold spent while it
-- climbs), so this watches instead of waiting for the count to say it is done.
function Flow:settle()
	local label = self.gain
	if not label then return end
	self.gainUntil = math.max(self.gainUntil or 0, os.clock() + 0.9)
	if self.watching then return end
	self.watching = true
	task.spawn(function()
		while label.Parent and (self.running or os.clock() < self.gainUntil) do
			task.wait(0.1)
		end
		self.watching = false
		if not label.Parent or not label.Visible then return end
		self.fades = { W.tween(label, 0.25, { TextTransparency = 1 }), W.tween(label.UIStroke, 0.25, { Transparency = 1 }) }
	end)
end

function Flow:run(serial)
	local from = self.from
	self.from = nil
	local base = self.shown
	local amount = self.goal - base
	local seconds, ticks = Flow.plan(amount)
	local gap = seconds / ticks
	local i = 0
	local start = os.clock()
	while self.serial == serial and i < ticks do
		i += 1
		-- The coin leaves early enough to land on its tick.
		if i == 1 or gap > 0.07 or i % 2 == 0 then self:coin(from, math.min(0.34, 0.2 + gap)) end
		while os.clock() < start + i * gap and self.serial == serial do
			Run.RenderStepped:Wait()
		end
		if self.serial ~= serial then return end
		-- More can arrive while counting. It joins the climb.
		amount = self.goal - base
		self.shown = math.round(base + amount * i / ticks)
		self:paint()
		self:tick(amount, i == 1)
		local _, scale = self:target()
		if scale then
			local rest = scale:GetAttribute("Rest")
			scale.Scale = rest * 1.34
			W.tween(scale, math.max(0.09, gap * 0.85), { Scale = rest })
		end
		Audio.coin(i / ticks)
	end
	if self.serial ~= serial then return end
	self.running = false
	self.shown = self.goal
	self:paint()
	self:tick(self.goal - base)
	self:settle()
	local icon, scale = self:target()
	if scale then Burst.pop(scale, scale:GetAttribute("Rest"), 1.5) end
	if icon and amount >= 20 then
		local at = icon.AbsolutePosition + icon.AbsoluteSize / 2 - self.hud.root.AbsolutePosition
		Burst.confetti(self.hud.root, at.X, at.Y, 8, { W.gold, Color3.fromRGB(255, 236, 150), W.orange }, 0.55)
	end
end

return Flow
