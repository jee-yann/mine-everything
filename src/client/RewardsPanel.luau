-- Daily rewards and playtime gifts, on one card with two tabs. What each day and gift holds comes from
-- Shared.FieldRewards.
local Gui = game:GetService("GuiService")
local Field = require(game:GetService("ReplicatedStorage").Shared.FieldRewards)
local Burst, Audio = require(script.Parent.Burst), require(script.Parent.HarborAudio)
local Run = game:GetService("RunService")
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
	Run.RenderStepped:Connect(function()
		if card.modal.Visible then self:animate(os.clock()) end
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
		-- Bright turning rays, only on the day that can be claimed.
		local sun = Burst.rays(tile, w / 2, h * 0.42, w, 9, rgb(255, 250, 190), 0.55)
		sun.Visible = false
		W.navyText(W.title(tile, "Day " .. i, 0, if big then 10 else 5, w, if big then 40 else 28, if big then 36 else 24, W.white), 2.8)
		local size = if big then 128 else 56
		local picture = Icons.draw(tile, reward.icon, (w - size) / 2, if big then 66 else 33, size, rgb(120, 225, 255))
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
		local glow = W.frame(tile, "Today", 0, 0, 0, 0, W.white, 16)
		glow.Size, glow.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		local rim = W.stroke(glow, W.gold, 5)
		local shade = W.frame(tile, "Later", 0, 0, 0, 0, W.navy, 16)
		shade.Size, shade.BackgroundTransparency, shade.ZIndex, shade.Visible = UDim2.fromScale(1, 1), 0.62, 4, false
		self.days[i] = { tile = tile, scale = scale, button = button, paint = paint, label = label, done = done, rim = rim,
			sun = sun, shade = shade, picture = picture, pictureScale = picture:FindFirstChildOfClass("UIScale"),
			pictureRest = picture:FindFirstChildOfClass("UIScale").Scale, buttonScale = button["Interaction scale"], w = w }
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
	-- The last gift is the big one and takes the whole right side.
	local grand = 178
	local step = (764 - grand - 12) / (n - 1)
	local centers = {}
	for i = 1, n do
		centers[i] = if i == n then 764 - grand / 2 else (i - 0.5) * step
	end
	self.giftCenters = centers
	local track = W.frame(page, "Progress", centers[1], 10, centers[n] - centers[1], 12, W.navy, 6)
	W.stroke(track, W.navy, 3)
	self.trackFill = W.frame(track, "Time", 0, 0, 0, 12, W.gold, 6)
	W.gradient(self.trackFill, W.white, rgb(255, 190, 70), 90)
	for i, gift in Field.gifts do
		local last = i == n
		local x = if last then 764 - grand else (i - 1) * step + 4
		local w = if last then grand else step - 8
		local knob = W.frame(page, "Step", x + w / 2 - 12, 4, 24, 24, W.navy, 7)
		knob.ZIndex = 3
		W.stroke(knob, W.navy, 3)
		local h = if last then 318 else 252
		local tile = box(page, "Gift " .. i, x, if last then 36 else 40, w, h, if last then { rgb(255, 226, 120), rgb(240, 120, 40) } elseif i % 2 == 0 then tints[4] else tints[1])
		local scale = W.scale(tile)
		local well = W.frame(tile, "Picture", 7, if last then 40 else 8, w - 14, if last then 112 else 84, W.navy, 11)
		well.BackgroundTransparency, well.ClipsDescendants = 0.72, true
		Card.rays(well, (w - 14) / 2, if last then 56 else 42, if last then 130 else 80, 6)
		local sun = Burst.rays(well, (w - 14) / 2, if last then 56 else 42, if last then 150 else 90, 8, rgb(255, 250, 190), if last then 0.62 else 0.5)
		sun.Visible = last
		local picture = Icons.draw(well, gift.reward.icon, (w - 14) / 2 - (if last then 46 else 29), if last then 10 else 13, if last then 92 else 58, rgb(120, 225, 255))
		local glow = W.frame(tile, "Ready", 0, 0, 0, 0, W.white, 16)
		glow.Size, glow.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		local rim = W.stroke(glow, W.gold, 5)
		rim.Enabled = last
		if last then
			rim.Color = rgb(255, 250, 200)
			local banner = W.title(tile, "GRAND GIFT!", 0, 6, w, 32, 27, rgb(255, 250, 190))
			W.navyText(banner, 3.2)
			for k = 1, 5 do
				local spark = W.title(tile, "★", ({ 12, 150, 22, 146, 84 })[k] - 14, ({ 48, 54, 122, 128, 36 })[k], 28, 28, ({ 22, 26, 20, 24, 18 })[k], rgb(255, 250, 190))
				spark.ZIndex = 4
				W.navyText(spark, 2)
				self.sparks = self.sparks or {}
				table.insert(self.sparks, { label = spark, scale = W.scale(spark), phase = k * 1.3 })
			end
		end
		W.navyText(W.title(tile, gift.minutes .. " min", 0, if last then 155 else 96, w, if last then 32 else 26, if last then 28 else 21, W.white), if last then 3 else 2.4)
		local line = if last then 189 else 124
		for part in string.gmatch(Field.describe(gift.reward), "%+[^+]+") do
			local words = W.title(tile, part, 0, line, w, if last then 26 else 21, if last then 22 else 16, rgb(255, 250, 190))
			W.largest(words, if last then 22 else 16, 10)
			W.navyText(words, 2.2)
			line += if last then 26 else 22
		end
		local button = W.clearButton(tile, "Claim", if last then 10 else 7, h - (if last then 58 else 46), w - (if last then 20 else 14), if last then 48 else 38, "Buy")
		W.round(button, 10)
		local paint = W.enamelPanel(button, rgb(150, 154, 176), rgb(98, 102, 128), 10)
		local label = W.title(button, "", 0, 0, w - (if last then 20 else 14), if last then 46 else 36, if last then 26 else 19, W.white)
		label.ZIndex = 3
		W.navyText(label, 2.2)
		button.Activated:Connect(function()
			self.menu.net.Action:FireServer("Gift", i)
		end)
		local done = W.frame(tile, "Collected", 0, 0, 0, 0, W.navy, 16)
		done.Size, done.BackgroundTransparency, done.ZIndex = UDim2.fromScale(1, 1), 0.5, 4
		local tick = W.title(done, "✓", 0, if last then 46 else 10, w, 120, if last then 96 else 56, rgb(140, 255, 120))
		tick.ZIndex = 5
		W.navyText(tick, 4)
		self.gifts[i] = { tile = tile, scale = scale, knob = knob, button = button, paint = paint, label = label, done = done,
			grand = last, sun = sun, rim = rim, picture = picture, pictureScale = picture:FindFirstChildOfClass("UIScale"),
			pictureRest = picture:FindFirstChildOfClass("UIScale").Scale, buttonScale = button["Interaction scale"], w = w }
	end
	self.playedLabel = W.title(page, "", 4, 308, 182, 34, 22, W.white, true)
	W.navyText(self.playedLabel, 2.6)
	self.resetLabel = W.title(page, "", 398, 308, 176, 34, 17, W.white)
	self.resetLabel.TextXAlignment = Enum.TextXAlignment.Right
	W.navyText(self.resetLabel, 2.4)
	local all = W.clearButton(page, "Claim all", 190, 300, 200, 52, "Buy")
	W.round(all, 13)
	self.allPaint = W.enamelPanel(all, rgb(150, 154, 176), rgb(98, 102, 128), 13)
	self.allLabel = W.title(all, "Claim all", 0, 0, 200, 50, 27, W.white)
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
	card.sub.Text = if key == "Daily" then "A new reward every 18 hours. Miss one and you keep your place." else "Keep playing to unlock gifts. They start again 18 hours later."
end

-- The tile that was just collected: it swells, paper flies, and what was won rises out of it.
function Panel:claimed(kind, index)
	local entry = if kind == "Daily" then self.days[index] else self.gifts[index]
	local reward = if kind == "Daily" then Field.daily[index] else Field.gifts[index] and Field.gifts[index].reward
	if not entry or not reward then return end
	Audio.unlock(true)
	if not motion(self.menu) then return end
	Burst.pop(entry.scale, 1, 1.22)
	Burst.shine(entry.tile, 16)
	local overlay = self.menu.overlay
	local at = entry.tile.AbsolutePosition + entry.tile.AbsoluteSize * 0.45 - overlay.AbsolutePosition
	Burst.confetti(overlay, at.X, at.Y, if kind == "Daily" and index == #Field.daily then 46 else 28)
	local won = W.title(overlay, Field.describe(reward), at.X, at.Y, 420, 60, 44, rgb(255, 244, 120))
	won.AnchorPoint, won.ZIndex = Vector2.one * 0.5, 70
	local stroke = W.navyText(won, 4)
	local scale = W.scale(won)
	Burst.pop(scale, self.card.scale.Scale, 0.4)
	W.tween(won, 1.1, { Position = UDim2.fromOffset(at.X, at.Y - 96 * self.card.scale.Scale) }).Completed:Once(function()
		W.tween(stroke, 0.3, { Transparency = 1 })
		W.tween(won, 0.3, { TextTransparency = 1 }).Completed:Once(function() won:Destroy() end)
	end)
	-- Gold goes to the wallet once the card is closed. The total on screen keeps counting either way.
	if reward.gold then self.menu.holdGold(0.8, entry.tile) end
end

-- A welcome when the card opens by itself: paper once it has landed.
function Panel:welcome()
	if not motion(self.menu) then return end
	task.delay(0.42, function()
		if not self.card.modal.Visible then return end
		Audio.reward(1.7)
		local overlay, modal = self.menu.overlay, self.card.modal
		for _, side in { 0.14, 0.86 } do
			local at = modal.AbsolutePosition + modal.AbsoluteSize * Vector2.new(side, 0.25) - overlay.AbsolutePosition
			Burst.confetti(overlay, at.X, at.Y, 22, nil, 1.1)
		end
	end)
end

-- What can be claimed keeps moving: its picture breathes and its button swells.
function Panel:animate(now)
	local list = if self.page == "Daily" then self.days else self.gifts
	local moving = motion(self.menu)
	if moving and self.page == "Playtime" then
		for _, spark in self.sparks do
			local wave = (1 + math.sin(now * 3 + spark.phase)) / 2
			spark.scale.Scale, spark.label.TextTransparency = 0.6 + 0.6 * wave, 0.7 * (1 - wave)
			spark.label.Rotation = math.sin(now * 1.6 + spark.phase) * 18
		end
	end
	for _, entry in list do
		local live = entry.live == true
		entry.sun.Visible = live or (entry.grand == true and not entry.done.Visible)
		if live and moving then
			local beat = (1 - math.cos(now * 5.2)) / 2
			entry.pictureScale.Scale = entry.pictureRest * (1 + 0.16 * beat)
			entry.picture.Rotation = math.sin(now * 5.2) * 5
			entry.buttonScale.Scale = 1 + 0.07 * beat
			entry.rim.Thickness = 4.5 + 2 * beat
		elseif entry.grand and moving and not entry.done.Visible then
			-- The big gift keeps swaying while it waits.
			local sway = (1 - math.cos(now * 2.2)) / 2
			entry.pictureScale.Scale = entry.pictureRest * (1 + 0.07 * sway)
			entry.picture.Rotation = math.sin(now * 2.2) * 4
			entry.rim.Thickness = 3 + 2.5 * sway
		elseif entry.wasLive and not live then
			entry.pictureScale.Scale, entry.picture.Rotation, entry.buttonScale.Scale = entry.pictureRest, 0, 1
		end
		entry.wasLive = live
	end
end

function Panel:refresh()
	local player, net = self.menu.player, self.menu.net
	local tabs = self.card.tabs
	tabs.Daily.dot.Visible, tabs.Playtime.dot.Visible = self.menu:attention("Daily"), self.menu:attention("Playtime")
	local now = workspace:GetServerTimeNow()
	local function clock(seconds)
		seconds = math.max(0, math.ceil(seconds))
		return string.format("%02d:%02d:%02d", seconds // 3600, seconds // 60 % 60, seconds % 60)
	end
	if self.page == "Daily" then
		local ready, done, wait = Field.dailyState(player:GetAttribute("StampCount"), player:GetAttribute("StampAt"), now)
		for i, entry in self.days do
			local claim, collected = i == ready, i <= done
			entry.done.Visible, entry.rim.Enabled = collected, claim
			entry.label.Text = if claim then "Claim!" elseif collected then "Claimed" elseif not ready and i == done % #Field.daily + 1 then "Tomorrow" else "Locked"
			entry.paint.Color = if claim then green elseif entry.label.Text == "Tomorrow" then blue else grey
			entry.button.Interactable, entry.live = claim, claim
			entry.shade.Visible = ready ~= nil and not claim and not collected
		end
		self.dailyNext.Text = if ready then "Your day " .. ready .. " reward: " .. Field.describe(Field.daily[ready]) else "Next reward in " .. clock(wait)
	else
		local played, claims = Field.played(player, now), player:GetAttribute("GiftClaims") or 0
		local waiting = Field.giftState(player, now)
		-- Steps are evenly spaced, so the line moves by how far it is between them.
		local at, n = self.giftCenters[1], #Field.gifts
		for i, entry in self.gifts do
			local gift, before = Field.gifts[i], Field.gifts[i - 1]
			local start = if before then before.seconds else 0
			local share = math.clamp((played - start) / (gift.seconds - start), 0, 1)
			if i > 1 then at += share * (self.giftCenters[i] - self.giftCenters[i - 1]) end
			local open, collected = played >= gift.seconds, i <= claims
			entry.knob.BackgroundColor3 = if open then W.gold else W.navy:Lerp(W.white, 0.2)
			entry.done.Visible = collected
			entry.label.Text = if collected then "Claimed" elseif open then "Claim!" else W.clock(gift.seconds - played)
			entry.paint.Color = if open and not collected then green else grey
			entry.button.Interactable, entry.live = open and not collected, open and not collected
			entry.rim.Enabled = entry.live or (entry.grand == true and not collected)
		end
		self.trackFill.Size = UDim2.new((at - self.giftCenters[1]) / (self.giftCenters[n] - self.giftCenters[1]), 0, 1, 0)
		self.playedLabel.Text = W.clock(math.floor(played)) .. (if played >= Field.maxGiftTime then "+ played" else " played")
		self.resetLabel.Text = "Resets in " .. clock((player:GetAttribute("GiftReset") or now) - now)
		self.allLabel.Text = "Claim all"
		self.allPaint.Color, self.all.Interactable = if waiting > 0 then green else grey, waiting > 0
	end
end

return Panel
