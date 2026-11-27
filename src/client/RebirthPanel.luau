-- Rebirth: what the next one needs and gives, the milestones, and what it keeps and resets. The rules
-- come from Shared.Rebirth. The button asks twice.
local Gui = game:GetService("GuiService")
local Run = game:GetService("RunService")
local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local Burst = require(script.Parent.Burst)
local Panel = {}
Panel.__index = Panel
local rgb = Color3.fromRGB
local red = { rgb(255, 150, 150), rgb(214, 52, 78) }
local gold, aqua, violet = { rgb(255, 226, 120), rgb(240, 150, 30) }, { rgb(134, 214, 255), rgb(47, 130, 230) }, { rgb(207, 174, 255), rgb(129, 80, 230) }
local leaf, slate, amber = { rgb(166, 245, 154), rgb(52, 178, 74) }, { rgb(116, 110, 168), rgb(72, 66, 122) }, { rgb(255, 208, 138), rgb(240, 138, 58) }
local looks = { Gold = { gold, "Coins" }, XP = { violet, "Skills" }, Cut = { aqua, "Tempo" } }
local grey = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
local yellow = ColorSequence.new(gold[1], gold[2])

local function tile(parent, name, x, y, w, h, tint)
	local frame = W.frame(parent, name, x, y, w, h, W.white, 16)
	W.enamelPanel(frame, tint[1], tint[2], 16)
	return frame
end
local function words(parent, value, x, y, w, h, size, color, left)
	local label = W.title(parent, value, x, y, w, h, size, color or W.white, left)
	label.ZIndex = 3
	W.navyText(label, math.max(2, size / 9))
	return label
end

function Panel.new(menu)
	local self = setmetatable({ menu = menu }, Panel)
	local card = Card.new(menu, "Rebirth", "Rebirth", "Rebirth", red)
	self.card = card
	local body = card.body
	body.Position = UDim2.fromOffset(11, 84)
	local page = W.frame(body, "Page", 7, 7, 764, 408, W.panel)
	page.BackgroundTransparency = 1

	local hero = tile(page, "Next rebirth", 0, 0, 250, 408, red)
	Card.rays(hero, 125, 120, 230, 8)
	self.sun = Burst.rays(hero, 125, 120, 230, 9, rgb(255, 250, 190), 0.6)
	self.sun.Visible = false
	self.nextName = words(hero, "", 0, 10, 250, 40, 36)
	self.picture = Icons.draw(hero, "Rebirth", 57, 52, 136)
	self.pictureScale = self.picture:FindFirstChildOfClass("UIScale")
	self.pictureRest = self.pictureScale.Scale
	self.goal = words(hero, "", 4, 204, 242, 26, 20, rgb(255, 244, 170))
	W.largest(self.goal, 20, 13)
	local track = W.frame(hero, "Progress", 22, 238, 206, 28, W.navy, 14)
	W.stroke(track, W.navy, 4)
	self.fill = W.frame(track, "Fill", 0, 0, 0, 28, W.white, 14)
	W.gradient(self.fill, rgb(255, 240, 150), rgb(255, 178, 50), 90)
	self.progress = words(track, "", 0, 0, 206, 28, 20)
	local button = W.clearButton(hero, "Rebirth", 18, 284, 214, 62, "Buy")
	W.round(button, 14)
	self.paint = W.enamelPanel(button, rgb(150, 154, 176), rgb(98, 102, 128), 14)
	self.label = words(button, "", 0, 0, 214, 58, 30)
	self.button, self.buttonScale = button, button["Interaction scale"]
	self.note = words(hero, "", 12, 352, 226, 50, 16)
	self.note.TextWrapped = true

	self.perks = {}
	local count = #Rebirth.perks
	local w = (500 - (count - 1) * 10) / count
	for i, perk in Rebirth.perks do
		local look = looks[perk.id] or { violet, "Rebirth" }
		local box = tile(page, perk.name, 264 + (i - 1) * (w + 10), 0, w, 166, look[1])
		Card.rays(box, w / 2, 60, w * 0.8, 6)
		words(box, perk.name, 0, 6, w, 26, 19)
		Icons.draw(box, look[2], w / 2 - 27, 33, 54)
		local value = W.largest
		local after = words(box, "", 5, 92, w - 10, 34, 24, rgb(255, 244, 170))
		value(after, 24, 14)
		local now = words(box, "", 5, 130, w - 10, 26, 17)
		value(now, 17, 12)
		self.perks[i] = { perk = perk, after = after, now = now }
	end

	self.milestones = {}
	local y = 180
	for i, milestone in Rebirth.milestones do
		local row = tile(page, milestone.name, 264, y, 500, 76, amber)
		Icons.draw(row, "Achievements", 12, 12, 52)
		words(row, milestone.name, 76, 6, 270, 30, 24, nil, true)
		local detail = words(row, milestone.detail, 76, 36, 284, 34, 16, nil, true)
		W.largest(detail, 17, 12)
		local badge = W.frame(row, "State", 368, 18, 118, 40, W.white, 11)
		local paint = W.enamelPanel(badge, rgb(150, 154, 176), rgb(98, 102, 128), 11)
		self.milestones[i] = { milestone = milestone, paint = paint, label = words(badge, "", 0, 0, 118, 38, 18) }
		y += 90
	end
	for i, info in {
		{ "You keep", "Level, skills, Index, achievements, titles, trails, auras, crates, quests and deepest descent.", "Book", leaf },
		{ "Resets", "Gold, your pack, Power, Speed, Backpack and field supplies.", "Pack", slate },
	} do
		local box = tile(page, info[1], 264 + (i - 1) * 255, y, 245, 138, info[4])
		Icons.draw(box, info[3], 12, 9, 34)
		words(box, info[1], 54, 10, 180, 32, 25, nil, true)
		local list = words(box, info[2], 14, 48, 217, 82, 18, nil, true)
		list.TextYAlignment = Enum.TextYAlignment.Top
		W.largest(list, 18, 13)
	end
	local height = math.max(408, y + 138)
	hero.Size = UDim2.fromOffset(250, height)
	page.Size, body.CanvasSize = UDim2.fromOffset(764, height), UDim2.fromOffset(0, height + 14)

	button.Activated:Connect(function() self:press() end)
	Run.RenderStepped:Connect(function()
		if card.modal.Visible then self:animate(os.clock()) end
	end)
	return self
end

function Panel:open()
	self.confirming, self.reply = false, nil
	self:refresh()
end

function Panel:press()
	local menu, player = self.menu, self.menu.player
	if menu.rebirthPending or not Rebirth.ready(player:GetAttribute("RunStarfalls") or 0) then return end
	self.reply = nil
	if not self.confirming then
		self.confirming = true
	else
		self.confirming = false
		local sent = os.clock()
		menu.rebirthPending = sent
		menu.net.Action:FireServer("Rebirth", player:GetAttribute("Rebirths") or 0)
		-- The server ignores a request while it travels or resets. Do not leave the button waiting.
		task.delay(6, function()
			if menu.rebirthPending == sent then
				menu.rebirthPending = nil
				self:refresh()
			end
		end)
	end
	self:refresh()
end

-- The server's answer when it could not rebirth.
function Panel:message(text)
	self.reply = text
	self:refresh()
end

function Panel:refresh()
	local player = self.menu.player
	local n, found = player:GetAttribute("Rebirths") or 0, player:GetAttribute("RunStarfalls") or 0
	local need = Rebirth.requirement.count
	local ready = Rebirth.ready(found) and player:GetAttribute("ProfileReady") == true
	if not ready then self.confirming = false end
	local pending = self.menu.rebirthPending
	self.live = ready and not pending
	self.card.sub.Text = if n > 0 then "You are on rebirth " .. n .. ". Start a new run for more." else "Start a new run with permanent bonuses."
	self.nextName.Text = "Rebirth " .. n + 1
	-- The run's Starfall: found, or how far along the trail (Rebirth.trail) this run has come.
	local trail = Rebirth.trail(n)
	local walked = math.min(trail.blocks, player:GetAttribute("RunTrail") or 0)
	local share = if found >= need then 1 else walked / trail.blocks
	self.goal.Text = if found >= need then "Starfall found this run ✓" else "Follow the Starfall's trail"
	self.fill.Size = UDim2.new(math.clamp(share, 0, 1), 0, 1, 0)
	self.fill.Visible = share > 0
	self.progress.Text = if found >= need then "Found!" else walked .. " / " .. trail.blocks .. " blocks"
	self.label.Text = if pending then "Rebirthing…" elseif self.confirming then "Confirm!" elseif ready then "Rebirth!" else "Locked"
	self.paint.Color = if not self.live then grey elseif self.confirming then yellow else green
	self.button.Interactable = self.live
	self.note.Text = self.reply or (if self.confirming then "Gold, pack, gear and supplies reset. Press again to rebirth."
		elseif ready then "Ready when you are."
		else "Cut blocks in " .. trail.region .. " or deeper. The last one holds a Starfall.")
	for _, item in self.perks do
		item.after.Text, item.now.Text = item.perk.text(n + 1), "Now " .. item.perk.text(n)
	end
	for _, item in self.milestones do
		local done = n >= item.milestone.at
		item.label.Text = if done then "Unlocked" else "Rebirth " .. item.milestone.at
		item.paint.Color = if done then green else grey
	end
end

function Panel:animate(now)
	local moving = self.menu.preferences.values.MenuMotion and not Gui.ReducedMotionEnabled
	local live = self.live == true
	self.sun.Visible = live
	if live and moving then
		local beat = (1 - math.cos(now * 5.2)) / 2
		self.pictureScale.Scale = self.pictureRest * (1 + 0.1 * beat)
		self.buttonScale.Scale = 1 + 0.05 * beat
	elseif self.wasLive and not live then
		self.pictureScale.Scale, self.buttonScale.Scale = self.pictureRest, 1
	end
	self.wasLive = live
end

return Panel
