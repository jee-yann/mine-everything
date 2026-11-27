-- Opening a crate: a reel of rewards scrolls past a marker, fast at first and slowing until it settles
-- on what the server already rolled, then the reward card bursts open in its rarity's colour. The
-- tiles scrolling past are drawn from the crate's own pool by its real weights, so the reel looks like
-- the odds. A tap (or Skip) jumps straight to the reward, and with menu motion off there is no reel.
-- From the reward the miner can wear it or open another crate.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Geodes = require(Shared.Collectibles), require(Shared.Geodes)
local Looks = require(Shared.CosmeticLooks)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local Burst = require(script.Parent.Burst)
local FxPreview = require(script.Parent.FxPreview)
local Reveal = {}
Reveal.__index = Reveal
local rgb = Color3.fromRGB
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
-- Dismiss buttons (Done, Close, Skip) in a friendly blue rather than grey.
local slate = ColorSequence.new(rgb(130, 205, 255), rgb(48, 118, 222))
local gold = ColorSequence.new(rgb(255, 226, 120), rgb(240, 150, 30))

-- The reel: tiles this wide (plus a gap), this many in all, the winner this far along.
local tileW, gap, tileH = 104, 8, 136
local step = tileW + gap
local reelW = 720
local count, winnerAt = 46, 40
local spinSeconds = 4.4

-- The icon each kind of reward is shown with.
local kindIcons = { trail = "Power", ribbon = "Trail", aura = "Gems" }
function Reveal.icon(kind, id)
	if kindIcons[kind] then return kindIcons[kind] end
	local item = C.itemById[id]
	return if item and item.kind == "geode" then "Geode" elseif item and item.kind == "gold" then "Coins" else "Boosts"
end

-- What a result means, in words.
function Reveal.outcome(kind, id, count, result)
	local entry = C.find(kind, id)
	if result.gold then
		return (if result.duplicate then "Already yours · " else "") .. "+" .. W.goldAmount(result.gold) .. " gold"
	elseif kind == "item" then
		return (if count > 1 then "×" .. count .. "  ·  " else "") .. (entry.detail or "")
	end
	local fast = C.speedText(kind, id)
	return "NEW " .. string.upper(C.kindNames[kind]) .. (if fast then "  ·  " .. fast else "")
end

local function button(parent, name, x, y, w, h, paint, text)
	local b = W.clearButton(parent, name, x, y, w, h, "Select")
	W.round(b, 14)
	local fill = W.enamelPanel(b, rgb(1, 1, 1), rgb(1, 1, 1), 14)
	fill.Color = paint
	local label = W.title(b, text, 0, 0, w, h - 2, 24, W.white)
	label.ZIndex = 3
	W.navyText(label, 2.6)
	W.largest(label, 24, 14)
	return b, label, fill
end

-- A palette strip: every colour of a look, left to right.
local function swatch(parent, entry, x, y, w, h)
	local strip = W.frame(parent, "Colour", x, y, w, h, W.white, math.floor(h / 2))
	local fill = Instance.new("UIGradient")
	fill.Color, fill.Parent = Looks.sequence(entry), strip
	return strip
end

-- One tile of the reel.
local function tile(parent, kind, id, x)
	local entry = C.find(kind, id)
	local rarity = C.rarities[entry.rarity]
	local frame = W.frame(parent, "Tile", x, 0, tileW, tileH, W.white, 14)
	W.enamelPanel(frame, rarity.color:Lerp(rgb(60, 56, 110), 0.55), rgb(34, 32, 66), 14)
	local glow = W.frame(frame, "Glow", 6, 6, tileW - 12, 70, rarity.color, 12)
	glow.BackgroundTransparency = 0.72
	if C.isCosmetic(kind) then
		FxPreview.new(frame, kind, id, 17, 2, 70, false)
	else
		Icons.draw(frame, Reveal.icon(kind, id), 20, 8, 64)
	end
	local name = W.title(frame, entry.name, 4, 84, tileW - 8, 28, 15, W.white)
	name.TextWrapped = true
	W.navyText(name, 1.6)
	W.largest(name, 15, 9)
	local band = W.frame(frame, "Rarity", 0, tileH - 18, tileW, 18, rarity.color, 9)
	local label = W.title(band, string.upper(entry.rarity), 0, 0, tileW, 18, 12, W.white)
	W.navyText(label, 1.4)
	return frame
end

function Reveal.new(hud, net)
	local self = setmetatable({ hud = hud, net = net, player = Players.LocalPlayer }, Reveal)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "GeodeReveal", false, 30, true
	gui.ZIndexBehavior, gui.Enabled = Enum.ZIndexBehavior.Sibling, false
	gui.Parent = self.player:WaitForChild("PlayerGui")
	self.gui = gui
	local shade = Instance.new("TextButton")
	shade.Name, shade.Text, shade.AutoButtonColor = "Shade", "", false
	shade.Size, shade.BackgroundColor3, shade.BackgroundTransparency = UDim2.fromScale(1, 1), W.ink, 0.25
	shade.Parent = gui
	shade.Activated:Connect(function() self:skip() end)
	local stage = W.frame(gui, "Stage", 0, 0, 560, 560, W.ink)
	stage.BackgroundTransparency = 1
	W.anchor(stage, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	self.stageScale = W.scale(stage)
	self.stage = stage
	self.caption = W.title(stage, "", 0, 0, 560, 44, 34, W.white)
	self.caption.Name = "Caption"
	W.navyText(self.caption, 3.4)
	self.caption.RichText = true
	self.subcaption = W.title(stage, "", 0, 44, 560, 30, 20, rgb(255, 244, 170))
	W.navyText(self.subcaption, 2.2)
	-- The reel: a window the tiles scroll through, with a marker down the middle.
	local window = W.frame(stage, "Reel", (560 - reelW) / 2, 150, reelW, tileH + 24, W.white, 20)
	W.enamelPanel(window, rgb(58, 54, 104), rgb(26, 24, 52), 20)
	self.window = window
	local clip = W.frame(window, "Clip", 8, 12, reelW - 16, tileH, W.ink)
	clip.BackgroundTransparency, clip.ClipsDescendants = 1, true
	self.strip = W.frame(clip, "Strip", 0, 0, count * step, tileH, W.ink)
	self.strip.BackgroundTransparency = 1
	self.clipWidth = reelW - 16
	for _, side in { 0, 1 } do
		local fade = W.frame(clip, "Fade", if side == 0 then 0 else reelW - 16 - 70, 0, 70, tileH, rgb(26, 24, 52))
		fade.ZIndex = 5
		local g = Instance.new("UIGradient")
		g.Transparency = if side == 0 then NumberSequence.new(0, 1) else NumberSequence.new(1, 0)
		g.Parent = fade
	end
	local marker = W.frame(window, "Marker", reelW / 2 - 3, 2, 6, tileH + 20, W.gold, 3)
	marker.ZIndex = 8
	W.stroke(marker, W.navy, 2)
	for _, y in { -6, tileH + 18 } do
		local tip = W.frame(window, "Marker tip", reelW / 2 - 9, y, 18, 18, W.gold, 4)
		tip.Rotation, tip.ZIndex = 45, 8
		W.stroke(tip, W.navy, 2)
	end
	-- The reward card.
	local card = W.frame(stage, "Reward", 80, 96, 400, 360, W.white, 22)
	self.cardPaint = W.enamelPanel(card, rgb(72, 68, 124), rgb(46, 43, 86), 22)
	card.Visible = false
	self.card, self.cardScale = card, W.scale(card)
	self.rays = W.frame(card, "Rays holder", 0, 0, 400, 360, W.ink)
	self.rays.BackgroundTransparency, self.rays.ClipsDescendants = 1, true
	self.rarity = W.title(card, "", 0, 12, 400, 32, 26, W.white)
	W.navyText(self.rarity, 2.8)
	self.iconHolder = W.frame(card, "Icon", 125, 54, 150, 150, W.ink)
	self.iconHolder.BackgroundTransparency, self.iconHolder.ZIndex = 1, 3
	self.name = W.title(card, "", 10, 210, 380, 42, 34, W.white)
	self.name.Name = "Reward name"
	W.navyText(self.name, 3.2)
	W.largest(self.name, 34, 18)
	self.result = W.title(card, "", 14, 252, 372, 30, 20, rgb(190, 255, 150))
	W.navyText(self.result, 2.2)
	W.largest(self.result, 20, 12)
	self.equip, self.equipLabel = button(card, "Equip", 16, 294, 116, 52, green, "Equip")
	self.again, self.againLabel = button(card, "Open another", 142, 294, 140, 52, gold, "Again")
	self.done = button(card, "Done", 292, 294, 92, 52, slate, "Done")
	self.equip.Activated:Connect(function() self:wear() end)
	self.again.Activated:Connect(function() self:openAgain() end)
	self.done.Activated:Connect(function() self:close() end)
	self.skipButton = button(stage, "Skip", 220, 470, 120, 48, slate, "Skip ▸▸")
	self.skipButton.Activated:Connect(function() self:skip() end)
	return self
end

function Reveal:layout(area)
	self.stageScale.Scale = math.clamp(math.min(area.X / (reelW + 40), area.Y / 600), 0.4, 1.4)
end

function Reveal:busy()
	return self.gui.Enabled
end

-- Fills the reel: fillers drawn from the crate's pool by weight, and the real reward at `winnerAt`.
-- A guaranteed crate (one reward) borrows the main crate's pool for its fillers, so the reel still
-- shows the kinds of things crates hold.
function Reveal:fill(geode, kind, id)
	self.strip:ClearAllChildren()
	local pool = if #geode.pool > 1 then geode.pool else Geodes.main.pool
	local total = 0
	for _, reward in pool do total += reward.weight end
	local rng = Random.new()
	for i = 1, count do
		local pickKind, pickId = kind, id
		if i ~= winnerAt then
			local pick = rng:NextInteger(1, total)
			for _, reward in pool do
				pick -= reward.weight
				if pick <= 0 then
					pickKind, pickId = reward.kind, reward.id
					break
				end
			end
		end
		local made = tile(self.strip, pickKind, pickId, (i - 1) * step)
		if i == winnerAt then self.winnerTile = made end
	end
	self.strip.Position = UDim2.fromOffset(0, 0)
end

-- Shows the opening of `geodeId` holding `kind`/`id`.
function Reveal:play(geodeId, kind, id, count_, result, chime)
	local geode = Geodes.byId[geodeId]
	local entry = C.find(kind, id)
	if not geode or not entry then return end
	self.current = { geode = geode, kind = kind, id = id, count = count_, result = result, entry = entry }
	self.chime = chime
	self.token = (self.token or 0) + 1
	local token = self.token
	self.shown = false
	self.gui.Enabled = true
	self:layout(workspace.CurrentCamera.ViewportSize)
	self.caption.Text = W.rich(string.upper(geode.name))
	self.subcaption.Text = if geodeId == "Welcome" then "A gift to welcome you" else "Tap to skip"
	self.card.Visible, self.window.Visible, self.skipButton.Visible = false, true, true
	if self.ticker then self.ticker:Disconnect() end
	if self.player:GetAttribute("MenuMotion") == false then
		self:show()
		return
	end
	self:fill(geode, kind, id)
	-- Land somewhere inside the winner's tile, not always dead centre, like a real reel.
	local land = (winnerAt - 1) * step + tileW / 2 + Random.new():NextNumber(-0.36, 0.36) * tileW
	local goal = -(land - self.clipWidth / 2)
	local tween = game:GetService("TweenService"):Create(self.strip,
		TweenInfo.new(spinSeconds, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(goal, 0) })
	self.spin = tween
	tween:Play()
	-- A tick each time a tile passes the marker.
	local last, lastTick = -1, 0
	self.ticker = Run.RenderStepped:Connect(function()
		local under = math.floor((self.clipWidth / 2 - self.strip.Position.X.Offset) / step)
		if under ~= last then
			last = under
			if chime and os.clock() - lastTick > 0.045 then
				lastTick = os.clock()
				chime(1.1 + math.min(under, winnerAt) / winnerAt * 0.4)
			end
		end
	end)
	tween.Completed:Once(function(state)
		if self.ticker then self.ticker:Disconnect() self.ticker = nil end
		if state ~= Enum.PlaybackState.Completed or self.token ~= token or self.shown then return end
		-- The winning tile lifts and glows before the card opens.
		local won = self.winnerTile
		if won then
			local scale = W.scale(won)
			W.tween(scale, 0.18, { Scale = 1.12 })
			won.ZIndex = 4
		end
		task.wait(0.5)
		if self.token == token and not self.shown then self:show() end
	end)
end

function Reveal:skip()
	if self.current and not self.shown then
		if self.spin then self.spin:Cancel() end
		if self.ticker then self.ticker:Disconnect() self.ticker = nil end
		self:show()
	end
end

function Reveal:show()
	local now = self.current
	self.shown = true
	local rarity = C.rarities[now.entry.rarity]
	self.window.Visible, self.skipButton.Visible = false, false
	self.card.Visible = true
	-- The crate bursts open in a flash of the reward's colour.
	if self.player:GetAttribute("MenuMotion") ~= false then
		local flash = Instance.new("Frame")
		flash.Name, flash.Size, flash.BorderSizePixel, flash.ZIndex = "Burst", UDim2.fromScale(1, 1), 0, 20
		flash.BackgroundColor3, flash.BackgroundTransparency = rarity.color:Lerp(W.white, 0.6), 0.15
		flash.Parent = self.gui
		W.tween(flash, 0.45, { BackgroundTransparency = 1 }).Completed:Once(function() flash:Destroy() end)
	end
	self.cardPaint.Color = ColorSequence.new(rarity.color:Lerp(rgb(72, 68, 124), 0.45), rgb(46, 43, 86))
	self.rays:ClearAllChildren()
	Burst.rays(self.rays, 200, 130, 300, 10, rarity.color, 0.7)
	self.rarity.Text, self.rarity.TextColor3 = string.upper(now.entry.rarity), rarity.color:Lerp(W.white, 0.2)
	self.name.Text = now.entry.name
	self.result.Text = Reveal.outcome(now.kind, now.id, now.count, now.result)
	self.iconHolder:ClearAllChildren()
	if C.isCosmetic(now.kind) then
		FxPreview.new(self.iconHolder, now.kind, now.id, 0, 0, 150)
	else
		Icons.draw(self.iconHolder, Reveal.icon(now.kind, now.id), 0, 0, 150)
	end
	local wearable = C.isCosmetic(now.kind) and not now.result.duplicate
	self.equip.Visible = wearable
	self.equipLabel.Text = "Wear"
	-- Open another: a crate still in the inventory, or buy one more.
	local geode = now.geode
	local freeLeft = self:freeCount(geode.id)
	local canBuy = geode.id == "Starfall" and self.player:GetAttribute("PaidRandomRestricted") == false
	self.again.Visible = freeLeft > 0 or canBuy
	self.againLabel.Text = if freeLeft > 0 then "Open (" .. freeLeft .. ")" else "Buy another"
	if self.chime then self.chime(1.5 + rarity.rank * 0.08) end
	self.cardScale.Scale = 0.6
	W.tween(self.cardScale, 0.25, { Scale = 1 })
	if rarity.rank >= C.rarities.Epic.rank and Burst.allowed(self.player) then
		local at = self.card.AbsolutePosition + self.card.AbsoluteSize / 2
		Burst.confetti(self.gui, at.X, at.Y, 18 + rarity.rank * 4, { rarity.color, W.white, W.gold }, 1)
	end
end

function Reveal:freeCount(geodeId)
	local col = require(Shared.Bonuses).decode(self.player:GetAttribute("Collection")) or {}
	return (col.items or {})[geodeId .. "Geode"] or 0
end

function Reveal:wear()
	local now = self.current
	if not now then return end
	self.net.Action:FireServer("Wear", now.kind, now.id)
	self.equip.Visible = false
	self.result.Text = "Equipped!"
end

function Reveal:openAgain()
	local now = self.current
	if not now then return end
	if self:freeCount(now.geode.id) > 0 then
		self.net.Action:FireServer("OpenGeode", now.geode.id)
	else
		self.hud.checkout:buy("product", require(Shared.StoreConfig).productByKey.Crate1)
	end
	self.again.Visible = false
end

function Reveal:close()
	self.token = (self.token or 0) + 1
	if self.spin then self.spin:Cancel() end
	if self.ticker then self.ticker:Disconnect() self.ticker = nil end
	self.gui.Enabled, self.current, self.shown = false, nil, false
end

-- A new result arrives while the reveal is open (Again): start over with it.
function Reveal:result(...)
	self.shown = false
	self:play(...)
end

return Reveal
