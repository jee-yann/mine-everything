-- Opening a crate: it shakes harder and harder, bursts open in a flash of its reward's rarity colour
-- and shows what was inside: new, or Crate Dust for a duplicate. A tap (or Skip) jumps straight to
-- the reward, and with menu motion off there is no animation at all. From the reward the miner can
-- equip it or open another of the same crate.
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Geodes = require(Shared.Collectibles), require(Shared.Geodes)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local Burst = require(script.Parent.Burst)
local Models = require(script.Parent.PetModels)
local Reveal = {}
Reveal.__index = Reveal
local rgb = Color3.fromRGB
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
local slate = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local gold = ColorSequence.new(rgb(255, 226, 120), rgb(240, 150, 30))

-- The icon each kind of reward is shown with.
local kindIcons = { pet = "Pets", trail = "Power", ribbon = "Trail", aura = "Gems", style = "Pets" }
function Reveal.icon(kind, id)
	if kindIcons[kind] then return kindIcons[kind] end
	local item = C.itemById[id]
	return if item and item.kind == "geode" then "Geode" else "Boosts"
end

-- What a result means, in words.
function Reveal.outcome(kind, id, count, result)
	local entry = C.find(kind, id)
	if result.dust then
		return "Already yours · +" .. result.dust .. " Crate Dust"
	elseif kind == "item" then
		return (if count > 1 then "×" .. count .. "  ·  " else "") .. (entry.detail or "")
	end
	return "NEW " .. string.upper(C.kindNames[kind])
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
	-- The geode itself.
	local rock = W.frame(stage, "Geode", 170, 110, 220, 220, W.ink)
	rock.BackgroundTransparency = 1
	self.rockScale = W.scale(rock)
	Icons.draw(rock, "Geode", 0, 0, 220)
	self.rock = rock
	-- The reward card.
	local card = W.frame(stage, "Reward", 80, 96, 400, 360, W.white, 22)
	self.cardPaint = W.enamelPanel(card, rgb(72, 68, 124), rgb(46, 43, 86), 22)
	card.Visible = false
	self.card, self.cardScale = card, W.scale(card)
	self.rays = W.frame(card, "Rays holder", 0, 0, 400, 360, W.ink)
	self.rays.BackgroundTransparency, self.rays.ClipsDescendants = 1, true
	self.rarity = W.title(card, "", 0, 12, 400, 32, 26, W.white)
	W.navyText(self.rarity, 2.8)
	self.preview = Instance.new("ViewportFrame")
	self.preview.Name, self.preview.BackgroundTransparency = "Pet preview", 1
	self.preview.Position, self.preview.Size, self.preview.ZIndex = UDim2.fromOffset(110, 46), UDim2.fromOffset(180, 160), 3
	self.preview.Parent = card
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
	self.stageScale.Scale = math.clamp(math.min(area.X / 600, area.Y / 600), 0.5, 1.4)
end

function Reveal:busy()
	return self.gui.Enabled
end

-- Shows the opening of `geodeId` holding `kind`/`id`; `paid` says it was bought with gems.
function Reveal:play(geodeId, kind, id, count, result, chime)
	local geode = Geodes.byId[geodeId]
	local entry = C.find(kind, id)
	if not geode or not entry then return end
	self.current = { geode = geode, kind = kind, id = id, count = count, result = result, entry = entry }
	self.chime = chime
	self.token = (self.token or 0) + 1
	local token = self.token
	self.shown = false
	self.gui.Enabled = true
	self:layout(workspace.CurrentCamera.ViewportSize)
	self.caption.Text = string.upper(geode.name)
	self.subcaption.Text = if geodeId == "Welcome" then "Guaranteed: Comet Trail (Legendary)" else "Tap to skip"
	self.card.Visible, self.rock.Visible, self.skipButton.Visible = false, true, true
	self.rock.Rotation, self.rockScale.Scale = 0, 1
	if self.player:GetAttribute("MenuMotion") == false then
		self:show()
		return
	end
	task.spawn(function()
		for beat = 1, 6 do
			if self.token ~= token or self.shown then return end
			local swing = 4 + beat * 3
			W.tween(self.rock, 0.07, { Rotation = swing })
			task.wait(0.08)
			W.tween(self.rock, 0.07, { Rotation = -swing })
			self.rockScale.Scale = 1 + beat * 0.03
			if chime then chime(0.7 + beat * 0.08) end
			task.wait(0.08 + (6 - beat) * 0.03)
		end
		if self.token == token and not self.shown then self:show() end
	end)
end

function Reveal:skip()
	if self.current and not self.shown then self:show() end
end

function Reveal:show()
	local now = self.current
	self.shown = true
	local rarity = C.rarities[now.entry.rarity]
	self.rock.Visible, self.skipButton.Visible = false, false
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
	if now.kind == "pet" then
		self.preview.Visible = true
		Models.preview(self.preview, now.id)
	else
		self.preview.Visible = false
		Icons.draw(self.iconHolder, Reveal.icon(now.kind, now.id), 0, 0, 150)
		if now.entry.colors or now.entry.color then
			local colors = C.colors(now.entry)
			local swatch = W.frame(self.iconHolder, "Colour", 25, 150, 100, 10, W.white, 5)
			W.gradient(swatch, colors[1], colors[2], 0)
		end
	end
	local wearable = now.kind == "pet" or C.isCosmetic(now.kind)
	self.equip.Visible = wearable
	self.equipLabel.Text = if now.kind == "pet" then "Equip" else "Wear"
	local geode = now.geode
	local gems = self.player:GetAttribute("Gems") or 0
	local freeLeft = self:freeCount(geode.id)
	local canAgain = freeLeft > 0 or (geode.price and gems >= geode.price and self.player:GetAttribute("PaidRandomRestricted") == false)
	self.again.Visible = canAgain == true
	self.againLabel.Text = if freeLeft > 0 then "Open (" .. freeLeft .. ")" else "Again · " .. (geode.price or 0) .. " gems"
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
	if now.kind == "pet" then
		self.net.Action:FireServer("EquipPet", now.id, true)
	else
		self.net.Action:FireServer("Wear", now.kind, now.id)
	end
	self.equip.Visible = false
	self.result.Text = if now.kind == "pet" then "Following you!" else "Equipped!"
end

function Reveal:openAgain()
	local now = self.current
	if not now then return end
	local free = self:freeCount(now.geode.id) > 0
	self.net.Action:FireServer("OpenGeode", now.geode.id, not free)
	self.again.Visible = false
end

function Reveal:close()
	self.token = (self.token or 0) + 1
	self.gui.Enabled, self.current, self.shown = false, nil, false
end

-- A new result arrives while the reveal is open (Again): start over with it.
function Reveal:result(...)
	self.shown = false
	self:play(...)
end

return Reveal
