local W = require(script.Parent.Widgets)
local Icons = require(script.Parent.Icons)
local Audio = require(script.Parent.HarborAudio)
local Ores = require(game.ReplicatedStorage.Shared.Ores)
local Celebration = {}
Celebration.__index = Celebration

function Celebration.new(hud)
	return setmetatable({ hud = hud, queue = {} }, Celebration)
end

function Celebration:show(kind, name)
	table.insert(self.queue, { kind = kind, name = name })
	if self.playing then
		return
	end
	self.playing = true
	task.spawn(function()
		while #self.queue > 0 and self.hud.root.Parent do
			local item = table.remove(self.queue, 1)
			self:present(item.kind, item.name)
		end
		self.playing = false
	end)
end

function Celebration:skillsLeft()
	for _, node in require(game.ReplicatedStorage.Shared.Skills).nodes do
		if not self.hud.player:GetAttribute("Skill" .. node.id) then
			return true
		end
	end
	return false
end

function Celebration:present(kind, name)
	local root = self.hud.root
	local isTitle = kind == "titleUnlocked"
	local isLevel = kind == "levelUp"
	if kind == "aura" then
		require(script.Parent.FirstLightCase)(self.hud, name)
		return
	end
	local ore = if kind == "discovery" then Ores.byName[name] else nil
	local tint = if ore then ore.color:Lerp(W.white, 0.35) elseif isTitle then W.violet elseif isLevel then W.aqua else W.gold
	local motion = self.hud.player:GetAttribute("MenuMotion") ~= false and not game:GetService("GuiService").ReducedMotionEnabled
	local group = W.fadeGroup(root, "Unlock celebration", 368, 124)
	group.ZIndex = 35
	local center = UDim2.fromScale(0.5, 0.41)
	W.anchor(group, 0.5, 0.5, center)
	local scale = W.scale(group)
	local fit = math.min(1.15, (root.AbsoluteSize.X - 16) / 368)
	scale.Scale = fit
	local body = W.frame(group, "Plaque", 8, 12, 352, 98, W.panel, 16)
	W.stroke(body, tint, 2.5)
	W.enamel(body, if ore then ore.color:Lerp(W.panel, 0.48) elseif isTitle then W.grape elseif isLevel then Color3.fromRGB(24, 88, 104) else Color3.fromRGB(110, 69, 32), W.ink)
	local badge = W.frame(body, "Medal", 16, 24, 50, 50, tint, 14)
	W.stroke(badge, tint:Lerp(W.white, 0.65), 2)
	Icons.draw(badge, if ore then "Crystal" elseif isTitle then "Titles" elseif isLevel then "Skills" else "Achievements", 5, 5, 40, tint)
	W.text(body, if ore then "NEW ORE DISCOVERED" elseif isTitle then "TITLE UNLOCKED" elseif isLevel then "LEVEL UP!" else "ACHIEVEMENT UNLOCKED", 83, 8, 260, 18, 14, tint, true)
	local headline = W.title(body, if isLevel then "Level " .. tostring(name) else name, 82, 27, 262, 42, 27, W.white, true)
	headline.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize, limit.Parent = 13, 27, headline
	W.text(
		body,
		if ore then "Added to your Ore Index" elseif isTitle then "Equip in Inventory → Titles" elseif isLevel then (if self:skillsLeft() then "+1 skill point · spend it in Skills" else "Every skill learned · keep climbing") else "Saved to Achievements",
		83,
		70,
		260,
		18,
		14,
		W.muted,
		true
	)
	Audio.unlock(isTitle)
	if motion then
		group.GroupTransparency, scale.Scale = 0.7, fit * 0.78
		group.Position = center + UDim2.fromOffset(0, 14)
		W.tween(group, 0.18, { GroupTransparency = 0, Position = center })
		W.tween(scale, 0.20, { Scale = fit })
		for i = 0, if isLevel then 15 else 7 do
			local angle = i * math.pi / (if isLevel then 8 else 4)
			local dot = W.frame(body, "Medal spark", 40, 46, 5, 5, tint, 1)
			dot.Rotation = 45
			W.tween(
				dot,
				0.56,
				{
					Position = UDim2.fromOffset(40 + math.cos(angle) * 39, 46 + math.sin(angle) * 38),
					BackgroundTransparency = 1,
				}
			)
		end
	end
	task.wait(2.3)
	if group.Parent then
		local finish = { GroupTransparency = 1 }
		if motion then
			finish.Position = center - UDim2.fromOffset(0, 12)
		end
		W.tween(group, 0.28, finish).Completed:Wait()
		group:Destroy()
	end
end

return Celebration
