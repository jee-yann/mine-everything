-- Mining XP pops out of the block as a few glowing orbs that fly into the level ring. Never more than
-- five at a time, with one soft note each.
local Run = game:GetService("RunService")
local W = require(script.Parent.Widgets)
local Audio = require(script.Parent.HarborAudio)
local Burst = require(script.Parent.Burst)
local Orbs = {}
local rgb = Color3.fromRGB
local rng = Random.new()
local green, pale = rgb(120, 255, 140), rgb(235, 255, 190)

local function gain(hud, amount)
	local ring = hud.levelRing.button
	if not ring.Parent or not hud.tools.Visible then return end
	local label = hud.xpLabel
	if not label then
		label = W.title(hud.root, "", 0, 0, 120, 34, 28, green)
		label.AnchorPoint, label.ZIndex, label.TextXAlignment = Vector2.new(0, 0.5), 46, Enum.TextXAlignment.Left
		W.navyText(label, 3)
		hud.xpLabel, hud.xpScale = label, W.scale(label)
	end
	local now = os.clock()
	hud.xpTotal = if now < (hud.xpUntil or 0) then hud.xpTotal + amount else amount
	hud.xpUntil = now + 1.5
	local at = ring.AbsolutePosition + Vector2.new(ring.AbsoluteSize.X + 10, ring.AbsoluteSize.Y / 2) - hud.root.AbsolutePosition
	if at.X + 130 > hud.root.AbsoluteSize.X then at -= Vector2.new(ring.AbsoluteSize.X + 150, 0) end
	label.Text, label.Position = "+" .. W.number(hud.xpTotal) .. " XP", UDim2.fromOffset(at.X, at.Y)
	label.TextTransparency, label.Visible = 0, true
	label.UIStroke.Transparency = 0
	Burst.pop(hud.xpScale, 1, 1.3)
	task.delay(1.5, function()
		if os.clock() >= hud.xpUntil then
			W.tween(label, 0.3, { TextTransparency = 1, Position = UDim2.fromOffset(at.X, at.Y - 14) })
			W.tween(label.UIStroke, 0.3, { Transparency = 1 })
		end
	end)
end

function Orbs.show(hud, amount, point)
	if amount <= 0 or hud.inOpening then return end
	local camera = workspace.CurrentCamera
	local ring = hud.levelRing.button
	local projected, seen
	if camera then projected, seen = camera:WorldToViewportPoint(point) end
	if not seen or hud.overlay.Visible or not hud.tools.Visible or not Burst.allowed(hud.player) then
		gain(hud, amount)
		return
	end
	local count = math.clamp(math.ceil(math.sqrt(amount)), 1, 5)
	local start = Vector2.new(projected.X, projected.Y) + hud.viewportOffset
	local scale = hud.levelRing.scale
	for i = 1, count do
		local size = rng:NextInteger(15, 20)
		local orb = W.frame(hud.root, "XP orb", start.X, start.Y, size, size, green, size)
		orb.AnchorPoint, orb.ZIndex = Vector2.one * 0.5, 44
		W.stroke(orb, rgb(20, 110, 52), 2.5)
		local core = W.frame(orb, "Core", size * 0.24, size * 0.2, size * 0.42, size * 0.42, pale, size)
		core.BackgroundTransparency = 0.05
		local angle = math.rad(-90 + (i - (count + 1) / 2) * 42 + rng:NextNumber(-12, 12))
		local out = start + Vector2.new(math.cos(angle), math.sin(angle)) * rng:NextNumber(48, 74)
		local began = os.clock()
		local leave, flight = 0.28 + i * 0.07, 0.46
		local link
		link = Run.RenderStepped:Connect(function()
			local age = os.clock() - began
			local finish = ring.AbsolutePosition + ring.AbsoluteSize / 2 - hud.root.AbsolutePosition
			if age < leave then
				-- Pop out of the rock and hang for a moment.
				local t = 1 - (1 - math.min(1, age / 0.2)) ^ 3
				local at = start:Lerp(out, t)
				orb.Position = UDim2.fromOffset(at.X, at.Y + math.sin(age * 9 + i) * 2)
				return
			end
			local t = math.min(1, (age - leave) / flight)
			local bend = out:Lerp(finish, 0.3) + Vector2.new(0, 70)
			local a, b = out:Lerp(bend, t * t), bend:Lerp(finish, t * t)
			local at = a:Lerp(b, t * t)
			orb.Position = UDim2.fromOffset(at.X, at.Y)
			if t >= 1 then
				link:Disconnect()
				orb:Destroy()
				Audio.orb(i)
				if scale then Burst.pop(scale, 1, 1.16) end
				if i == count then gain(hud, amount) end
			end
		end)
	end
end

return Orbs
