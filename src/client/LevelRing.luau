local W = require(script.Parent.Widgets)
local Expeditions = require(game:GetService("ReplicatedStorage").Shared.Expeditions)
local LevelRing = {}
LevelRing.__index = LevelRing
local steps = 20

function LevelRing.new(parent, openSkills)
	local button = W.clearButton(parent, "Level progress", 154, 0, 46, 46, "Select")
	button.Activated:Connect(openSkills)
	local ticks = {}
	for index = 1, steps do
		local angle = (index - 1) * 2 * math.pi / steps
		local tick = W.frame(button, "XP segment", 0, 0, 5, 4, W.line, 2)
		W.anchor(tick, 0.5, 0.5, UDim2.fromOffset(23 + math.sin(angle) * 20, 23 - math.cos(angle) * 20))
		tick.Rotation = math.deg(angle)
		W.stroke(tick, W.ink, 1)
		ticks[index] = tick
	end
	local caption = W.title(button, "LV", 5, 6, 36, 12, 10, W.aqua)
	local value = W.title(button, "", 3, 16, 40, 22, 19, W.white)
	value.TextScaled = true
	local font = Instance.new("UITextSizeConstraint")
	font.MinTextSize, font.MaxTextSize, font.Parent = 10, 19, value
	W.outlineText(caption, 1.4)
	W.outlineText(value, 2)
	return setmetatable({ scale = W.scale(button), button = button, ticks = ticks, caption = caption, value = value }, LevelRing)
end

function LevelRing:update(xp, showGain)
	if self.xp == xp then
		return
	end
	local previous = self.xp
	self.xp = xp
	local level = Expeditions.level(xp)
	local start = Expeditions.levelXP(level)
	local filled = steps * (xp - start) / (Expeditions.levelXP(level + 1) - start)
	for i, tick in self.ticks do
		tick.BackgroundColor3 = W.line:Lerp(W.aqua, math.clamp(filled - i + 1, 0, 1))
	end
	self.caption.Text, self.value.Text = "LV", tostring(level)
	if previous and xp > previous and showGain then
		self.gained = (self.gained or 0) + xp - previous
		self.caption.Text = "XP"
		self.value.Text = "+" .. W.number(xp - previous)
		task.delay(1.15, function()
			if self.xp == xp and self.value.Parent then
				self.caption.Text, self.value.Text = "LV", tostring(level)
			end
		end)
	end
end
return LevelRing
