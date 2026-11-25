-- Daily rewards and playtime gifts, on one card with two tabs. What each day and gift holds comes from
-- Shared.FieldRewards.
local Gui = game:GetService("GuiService")
local Field = require(game:GetService("ReplicatedStorage").Shared.FieldRewards)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local Panel = {}
Panel.__index = Panel
local rgb = Color3.fromRGB
local daily = { rgb(255, 159, 200), rgb(227, 69, 138) }
local playtime = { rgb(207, 174, 255), rgb(129, 80, 230) }
-- Each day has its own colour. The seventh is the big one.
local tints = {
	{ rgb(134, 214, 255), rgb(47, 130, 230) }, { rgb(166, 245, 154), rgb(52, 178, 74) },
	{ rgb(140, 240, 220), rgb(24, 160, 150) }, { rgb(207, 174, 255), rgb(129, 80, 230) },
	{ rgb(255, 208, 138), rgb(240, 138, 58) }, { rgb(134, 214, 255), rgb(47, 130, 230) },
	{ rgb(255, 159, 200), rgb(227, 69, 138) },
}
local grey = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
local blue = ColorSequence.new(rgb(134, 214, 255), rgb(47, 130, 230))

local function box(parent, name, x, y, w, h, tint)
	local frame = W.frame(parent, name, x, y, w, h, W.white, 16)
	W.enamelPanel(frame, tint[1], tint[2], 16)
	return frame
end
local function plate(parent, x, y, w, h, size)
	local frame = W.frame(parent, "State", x, y, w, h, W.white, 11)
	local paint = W.enamelPanel(frame, rgb(150, 154, 176), rgb(98, 102, 128), 11)
	local label = W.title(frame, "", 0, 0, w, h - 2, size, W.white)
	label.ZIndex = 3
	W.navyText(label, 2.4)
	return frame, paint, label
end
local function motion(menu)
	return menu.preferences.values.MenuMotion and not Gui.ReducedMotionEnabled
end

function Panel.new(menu)
	local self = setmetatable({ menu = menu }, Panel)
	local card = Card.new(menu, "Rewards", "Daily", "Daily Rewards", daily)
	self.card = card
	card:useTabs()
	card:tab("Daily", "Daily", "Daily", function() menu:open("Daily") end)
	card:tab("Playtime", "Playtime", "Playtime", function() menu:open("Playtime") end)
	self:buildDaily()
	self:buildPlaytime()
	task.spawn(function()
		while card.modal.Parent do
			task.wait(0.5)
			if card.modal.Visible then self:refresh() end
		end
	end)
	return self
end

function Panel:buildDaily()
	local page = W.frame(self.card.body, "Daily", 7, 7, 764, 358, W.panel)
	page.BackgroundTransparency = 1
	self.dailyPage, self.days = page, {}
	for i, reward in Field.daily do
		local big = i == #Field.daily
		local w, h = 170, 160
		local x, y = (i - 1) % 3 * 180, math.floor((i - 1) / 3) * 170
		if big then w, h, x, y = 224, 330, 540, 0 end
		local tile = box(page, "Day " .. i, x, y, w, h, tints[i])
		local scale = W.scale(tile)
		Card.rays(tile, w / 2, h * 0.46, w * 0.9, if big then 8 else 6).ZIndex = 1
		W.navyText(W.title(tile, "Day " .. i, 0, if big then 10 else 5, w, if big then 40 else 28, if big then 36 else 24, W.white), 2.8)
		local size = if big then 128 else 56
		Icons.draw(tile, reward.icon, (w - size) / 2, if big then 66 else 33, size, rgb(120, 225, 255))
		local name = W.title(tile, if big then reward.name else Field.describe(reward), 4, if big then 206 else 89, w - 8, if big then 30 else 24, if big then 26 else 19, W.white)
		W.navyText(name, 2.3)
		if big then
			local list = W.title(tile, Field.describe(reward), 6, 236, w - 12, 24, 17, rgb(255, 240, 150))
			W.navyText(list, 2.2)
		end
		local button = W.clearButton(tile, "Claim", 10, h - (if big then 62 else 43), w - 20, if big then 50 else 34, "Buy")
		W.round(button, 11)
		local paint = W.enamelPanel(button, rgb(150, 154, 176), rgb(98, 102, 128), 11)
		local label = W.title(button, "", 0, 0, w - 20, if big then 48 else 32, if big then 27 else 19, W.white)
		label.ZIndex = 3
		W.navyText(label, 2.4)
		button.Activated:Connect(function()
			self.menu.net.Action:FireServer("Stamp")
		end)
		local done = W.frame(tile, "Collected", 0, 0, 0, 0, W.navy, 16)
		done.Size, done.BackgroundTransparency, done.ZIndex = UDim2.fromScale(1, 1), 0.5, 4
		local tick = W.title(done, "✓", 0, 0, w, h - 34, if big then 110 else 66, rgb(140, 255, 120))
		tick.ZIndex = 5
		W.navyText(tick, 4)
		local glow = W.frame(tile, "Today", 0, 0, 0, 0, W.white, 18)
		glow.Size, glow.Position, glow.BackgroundTransparency = UDim2.new(1, 8, 1, 8), UDim2.fromOffset(-4, -4), 1
		local rim = W.stroke(glow, W.gold, 5)
		self.days[i] = { tile = tile, scale = scale, button = button, paint = paint, label = label, done = done, rim = rim }
	end
	self.dailyNext = W.title(page, "", 0, 334, 764, 26, 21, W.white)
	W.navyText(self.dailyNext, 2.4)
end

function Panel:buildPlaytime()
	local page = W.frame(self.card.body, "Playtime", 7, 7, 764, 358, W.panel)
	page.BackgroundTransparency = 1
	self.playtimePage, self.gifts = page, {}
	local n = #Field.gifts
	-- The line of steps above the gifts fills with play time.
	local step = 764 / n
	local track = W.frame(page, "Progress", step / 2, 10, 764 - step, 12, W.navy, 6)
	W.stroke(track, W.navy, 3)
	self.trackFill = W.frame(track, "Time", 0, 0, 0, 12, W.gold, 6)
	W.gradient(self.trackFill, W.white, rgb(255, 190, 70), 90)
	for i, gift in Field.gifts do
		local last = i == n
		local x = (i - 1) * step + 4
		local w = step - 8
		local knob = W.frame(page, "Step", x + w / 2 - 12, 4, 24, 24, W.navy, 7)
		knob.ZIndex = 3
		W.stroke(knob, W.navy, 3)
		local tile = box(page, "Gift " .. i, x, 40, w, 252, if last then tints[7] elseif i % 2 == 0 then tints[4] else tints[1])
		local scale = W.scale(tile)
		local well = W.frame(tile, "Picture", 7, 8, w - 14, 84, W.navy, 11)
		well.BackgroundTransparency, well.ClipsDescendants = 0.72, true
		Card.rays(well, (w - 14) / 2, 42, 80, 6)
		Icons.draw(well, gift.reward.icon, (w - 14) / 2 - 29, 13, 58, rgb(120, 225, 255))
		W.navyText(W.title(tile, gift.minutes .. " min", 0, 96, w, 26, 21, W.white), 2.4)
		local line = 124
		for part in string.gmatch(Field.describe(gift.reward), "%+[^+]+") do
			local words = W.title(tile, part, 0, line, w, 21, 16, rgb(255, 240, 150))
			words.TextScaled = true
			local limit = Instance.new("UITextSizeConstraint")
			limit.MaxTextSize, limit.Parent = 16, words
			W.navyText(words, 2)
			line += 22
		end
		local button = W.clearButton(tile, "Claim", 7, 206, w - 14, 38, "Buy")
		W.round(button, 10)
		local paint = W.enamelPanel(button, rgb(150, 154, 176), rgb(98, 102, 128), 10)
		local label = W.title(button, "", 0, 0, w - 14, 36, 19, W.white)
		label.ZIndex = 3
		W.navyText(label, 2.2)
		button.Activated:Connect(function()
			self.menu.net.Action:FireServer("Gift", i)
		end)
		local done = W.frame(tile, "Collected", 0, 0, 0, 0, W.navy, 16)
		done.Size, done.BackgroundTransparency, done.ZIndex = UDim2.fromScale(1, 1), 0.5, 4
		local tick = W.title(done, "✓", 0, 10, w, 120, 56, rgb(140, 255, 120))
		tick.ZIndex = 5
		W.navyText(tick, 4)
		self.gifts[i] = { tile = tile, scale = scale, knob = knob, button = button, paint = paint, label = label, done = done }
	end
	self.playedLabel = W.title(page, "", 4, 308, 250, 34, 24, W.white, true)
	W.navyText(self.playedLabel, 2.6)
	self.resetLabel = W.title(page, "", 510, 308, 250, 34, 20, W.white)
	self.resetLabel.TextXAlignment = Enum.TextXAlignment.Right
	W.navyText(self.resetLabel, 2.4)
	local all = W.clearButton(page, "Claim all", 272, 302, 220, 48, "Buy")
	W.round(all, 13)
	self.allPaint = W.enamelPanel(all, rgb(150, 154, 176), rgb(98, 102, 128), 13)
	self.allLabel = W.title(all, "Claim all", 0, 0, 220, 46, 25, W.white)
	self.allLabel.ZIndex = 3
	W.navyText(self.allLabel, 2.6)
	all.Activated:Connect(function()
		local ready = Field.giftState(self.menu.player, workspace:GetServerTimeNow())
		if ready > 0 then
			self.menu.net.Action:FireServer("Gift", (self.menu.player:GetAttribute("GiftClaims") or 0) + ready)
		end
	end)
	self.all = all
end

function Panel:open(key)
	self.page = key
	self.dailyPage.Visible, self.playtimePage.Visible = key == "Daily", key == "Playtime"
	local card = self.card
	card:select(key)
	card:setIcon(key)
	local tint = if key == "Daily" then daily else playtime
	card.headerPaint.Color = ColorSequence.new(tint[1], tint[2])
	card.heading.Text = if key == "Daily" then "Daily Rewards" else "Playtime Gifts"
	card.sub.Text = if key == "Daily" then "Come back every day. Miss one and you keep your place." else "Keep playing to unlock gifts. They reset every day."
end

-- Pops the tile that was just collected.
function Panel:claimed(kind, index)
	local entry = if kind == "Daily" then self.days[index] else self.gifts[index]
	if not entry or not motion(self.menu) then return end
	entry.scale.Scale = 1.16
	W.tween(entry.scale, 0.4, { Scale = 1 })
end

function Panel:refresh()
	local player, net = self.menu.player, self.menu.net
	local tabs = self.card.tabs
	tabs.Daily.dot.Visible, tabs.Playtime.dot.Visible = self.menu:attention("Daily"), self.menu:attention("Playtime")
	local now = workspace:GetServerTimeNow()
	local untilMidnight = 86400 - now % 86400
	local clock = string.format("%02d:%02d:%02d", untilMidnight // 3600, untilMidnight // 60 % 60, untilMidnight % 60)
	if self.page == "Daily" then
		local today = net:GetAttribute("OrderDay")
		local ready, done = Field.dailyState(player:GetAttribute("StampCount"), player:GetAttribute("StampDay"), today)
		for i, entry in self.days do
			local claim, collected = i == ready, i <= done
			entry.done.Visible, entry.rim.Enabled = collected, claim
			entry.label.Text = if claim then "Claim!" elseif collected then "Claimed" elseif not ready and i == done % #Field.daily + 1 then "Tomorrow" else "Locked"
			entry.paint.Color = if claim then green elseif entry.label.Text == "Tomorrow" then blue else grey
			entry.button.Interactable = claim
		end
		self.dailyNext.Text = if ready then "Day " .. ready .. " is ready to claim!" else "Next reward in " .. clock
	else
		local played, claims = Field.played(player, now), player:GetAttribute("GiftClaims") or 0
		local waiting = Field.giftState(player, now)
		-- Steps are evenly spaced, so the line moves by how far it is between them.
		local at, n = 0, #Field.gifts
		for i, entry in self.gifts do
			local gift, before = Field.gifts[i], Field.gifts[i - 1]
			local start = if before then before.seconds else 0
			local share = math.clamp((played - start) / (gift.seconds - start), 0, 1)
			if i > 1 then at += share end
			local open, collected = played >= gift.seconds, i <= claims
			entry.knob.BackgroundColor3 = if open then W.gold else W.navy:Lerp(W.white, 0.2)
			entry.done.Visible = collected
			entry.label.Text = if collected then "Claimed" elseif open then "Claim!" else W.clock(gift.seconds - played)
			entry.paint.Color = if open and not collected then green else grey
			entry.button.Interactable = open and not collected
		end
		self.trackFill.Size = UDim2.new(at / math.max(1, n - 1), 0, 1, 0)
		self.playedLabel.Text = W.clock(math.floor(played)) .. (if played >= Field.maxGiftTime then "+ played" else " played")
		self.resetLabel.Text = "Resets in " .. clock
		self.allLabel.Text = if waiting > 1 then "Claim all (" .. waiting .. ")" elseif waiting == 1 then "Claim gift" else "Keep playing"
		self.allPaint.Color, self.all.Interactable = if waiting > 0 then green else grey, waiting > 0
	end
end

return Panel
