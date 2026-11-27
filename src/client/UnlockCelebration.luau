-- The big moments, one after another: levels, skills, new ores, achievements, titles, jobs, upgrades and
-- rebirths. Each is
-- a bright tile that drops in with turning rays, a shine and confetti.
local W = require(script.Parent.Widgets)
local Icons = require(script.Parent.Icons)
local Audio = require(script.Parent.HarborAudio)
local Burst = require(script.Parent.Burst)
local Ores = require(game.ReplicatedStorage.Shared.Ores)
local Celebration = {}
Celebration.__index = Celebration
local rgb = Color3.fromRGB

local kinds = {
	discovery = { "NEW ORE DISCOVERED!", "Crystal", rgb(134, 214, 255), rgb(47, 130, 230) },
	titleUnlocked = { "TITLE UNLOCKED!", "Titles", rgb(207, 174, 255), rgb(129, 80, 230) },
	levelUp = { "LEVEL UP!", "Skills", rgb(166, 245, 154), rgb(52, 178, 74) },
	achievement = { "ACHIEVEMENT!", "Achievements", rgb(255, 230, 128), rgb(243, 165, 26) },
	job = { "JOB COMPLETE!", "Jobs", rgb(255, 208, 138), rgb(240, 138, 58) },
	skill = { "SKILL UNLOCKED!", "Skills", rgb(166, 245, 154), rgb(52, 178, 74) },
	rebirth = { "REBIRTH!", "Rebirth", rgb(255, 150, 150), rgb(214, 52, 78) },
	upgrade = { "UPGRADED!", "Power", rgb(140, 240, 220), rgb(24, 160, 150) },
}

function Celebration.new(hud)
	return setmetatable({ hud = hud, queue = {} }, Celebration)
end

function Celebration:show(kind, name, detail, icon, gold, extra)
	local item = { kind = kind, name = name, detail = detail, icon = icon, gold = gold }
	for key, value in extra or {} do item[key] = value end
	table.insert(self.queue, item)
	if self.playing then
		return
	end
	self.playing = true
	task.spawn(function()
		while #self.queue > 0 and self.hud.root.Parent do
			local item = table.remove(self.queue, 1)
			self:present(item)
		end
		self.playing = false
	end)
end

-- A workshop upgrade. Buying the same upgrade again while its card is up (or still waiting) doesn't
-- queue another card: the one card counts up, "Lv 20 → Lv 28". `describe(from, to)` gives the
-- headline and the detail.
function Celebration:upgrade(key, level, describe)
	local now = self.current
	if now and now.item.kind == "upgrade" and now.item.icon == key and now.item.from then
		now.item.to = level
		now.headline.Text, now.detail.Text = describe(now.item.from, level)
		now.untilTime = math.max(now.untilTime, os.clock() + 1.6)
		if Burst.allowed(self.hud.player) then Burst.pop(now.medalScale, 1, 1.2) end
		return
	end
	for _, item in self.queue do
		if item.kind == "upgrade" and item.icon == key and item.from then
			item.to = level
			item.name, item.detail = describe(item.from, level)
			return
		end
	end
	local name, detail = describe(level - 1, level)
	self:show("upgrade", name, detail, key, nil, { from = level - 1, to = level })
end

function Celebration:skillsLeft()
	for _, node in require(game.ReplicatedStorage.Shared.Skills).nodes do
		if not self.hud.player:GetAttribute("Skill" .. node.id) then
			return true
		end
	end
	return false
end

function Celebration:present(item)
	local root, kind, name = self.hud.root, item.kind, item.name
	local style = kinds[kind] or kinds.achievement
	local ore = if kind == "discovery" then Ores.byName[name] else nil
	local top, bottom = style[3], style[4]
	if ore then
		local h, s, v = ore.color:ToHSV()
		local bright = Color3.fromHSV(h, math.min(s, 0.75), math.max(v, 0.85))
		top, bottom = bright:Lerp(W.white, 0.35), bright:Lerp(W.navy, 0.3)
	end
	local motion = Burst.allowed(self.hud.player)
	local quick = #self.queue > 0
	local group = W.fadeGroup(root, "Unlock celebration", 470, 170)
	group.ZIndex = 35
	-- On a phone (the compact HUD) the card is small and high, so it never covers the mine.
	local phone = self.hud.edgeMode == true and root.AbsoluteSize.Y < 500
	local center = UDim2.fromScale(0.5, if phone then 0.2 else 0.3)
	W.anchor(group, 0.5, 0.5, center)
	local scale = W.scale(group)
	local fit = math.min(if phone then 0.6 else 1.1, (root.AbsoluteSize.X - 16) / 470, (root.AbsoluteSize.Y - 10) / 340)
	scale.Scale = fit
	local body = W.frame(group, "Plaque", 12, 22, 446, 124, W.white, 22)
	W.enamelPanel(body, top, bottom, 22)
	Burst.rays(body, 68, 62, 560, 9, W.white, 0.8)
	local medal = W.frame(body, "Medal", 22, 16, 92, 92, W.white, 24)
	W.enamelPanel(medal, W.white, top:Lerp(W.white, 0.45), 24)
	Icons.draw(medal, item.icon or style[2], 11, 11, 70, if ore then ore.color else nil)
	local medalScale = W.scale(medal)
	local kindText = W.title(body, style[1], 132, 10, 300, 30, 25, rgb(255, 244, 170), true)
	W.navyText(kindText, 2.8)
	local headline = W.title(body, if kind == "levelUp" then "Level " .. tostring(name) else name, 132, 38, 300, 46, 37, W.white, true)
	headline.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize, limit.Parent = 15, 37, headline
	W.navyText(headline, 3.4)
	local detail = W.title(body, item.detail
		or (if ore then "Added to your Ore Index" elseif kind == "titleUnlocked" then "Equip it in Inventory"
			elseif kind == "levelUp" then (if self:skillsLeft() then "+1 skill point to spend" else "Every skill learned!") else "Saved to your Awards"),
		132, 84, 300, 28, 21, W.white, true)
	detail.TextScaled = true
	local small = Instance.new("UITextSizeConstraint")
	small.MinTextSize, small.MaxTextSize, small.Parent = 12, 21, detail
	W.navyText(detail, 2.4)
	if item.gold then self.hud.goldFlow:hold(0.7, medal) end
	Audio.unlock(kind == "titleUnlocked" or kind == "levelUp" or kind == "rebirth")
	if motion then
		Burst.drop(group, center)
		task.delay(0.36, function()
			if not group.Parent then return end
			Burst.pop(medalScale, 1, 1.35)
			Burst.shine(body, 22)
			local at = group.AbsolutePosition + Vector2.new(group.AbsoluteSize.X / 2, group.AbsoluteSize.Y * 0.4) - root.AbsolutePosition
			Burst.confetti(root, at.X, at.Y, if kind == "rebirth" then 48 elseif kind == "levelUp" then 34 else 22, if ore then { top, bottom, W.white, W.gold } else nil)
		end)
	end
	local current = { item = item, headline = headline, detail = detail, medalScale = medalScale,
		untilTime = os.clock() + (if quick then 1.7 else 2.5) }
	self.current = current
	while os.clock() < current.untilTime and group.Parent do
		task.wait(0.1)
	end
	if self.current == current then self.current = nil end
	if group.Parent then
		local finish = { GroupTransparency = 1 }
		if motion then
			finish.Position = center - UDim2.fromOffset(0, 46)
		end
		W.tween(group, 0.28, finish).Completed:Wait()
		group:Destroy()
	end
end

return Celebration
