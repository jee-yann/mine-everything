-- Small screen effects shared by rewards, unlocks and upgrades: confetti, light rays, a shine and a
-- springy entrance. All of them stay still when menu motion is off.
local Gui = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Run = game:GetService("RunService")
local W = require(script.Parent.Widgets)
local Burst = {}
local rgb = Color3.fromRGB
local rng = Random.new()
Burst.party = { rgb(255, 209, 76), rgb(88, 224, 252), rgb(255, 128, 191), rgb(110, 236, 150), rgb(186, 149, 255) }

function Burst.allowed(player)
	return player:GetAttribute("MenuMotion") ~= false and not Gui.ReducedMotionEnabled
end

-- Paper flung up from (x, y) of `parent`, falling as it fades.
function Burst.confetti(parent, x, y, count, colors, power)
	colors, power = colors or Burst.party, power or 1
	local pieces = {}
	for i = 1, count do
		local size = rng:NextInteger(7, 12)
		local piece = W.frame(parent, "Confetti", x, y, size, if i % 3 == 0 then size else size * 0.55, colors[(i - 1) % #colors + 1], if i % 3 == 0 then size else 2)
		piece.AnchorPoint, piece.ZIndex, piece.Rotation = Vector2.one * 0.5, 60, rng:NextInteger(0, 180)
		local angle = math.rad(rng:NextNumber(-160, -20))
		local speed = rng:NextNumber(220, 470) * power
		pieces[i] = { piece = piece, vx = math.cos(angle) * speed, vy = math.sin(angle) * speed, spin = rng:NextNumber(-420, 420) }
	end
	local start = os.clock()
	local link
	link = Run.RenderStepped:Connect(function(dt)
		local age = os.clock() - start
		if age > 1.25 or not parent.Parent then
			link:Disconnect()
			for _, item in pieces do item.piece:Destroy() end
			return
		end
		for _, item in pieces do
			item.vy += 760 * power * dt
			item.vx *= 1 - 1.4 * dt
			item.piece.Position += UDim2.fromOffset(item.vx * dt, item.vy * dt)
			item.piece.Rotation += item.spin * dt
			item.piece.BackgroundTransparency = math.clamp((age - 0.75) / 0.5, 0, 1)
		end
	end)
end

-- Rays that turn slowly behind whatever is drawn after them. Clipped to `parent`.
function Burst.rays(parent, x, y, length, count, color, transparency)
	-- Inset, so no ray pokes past the parent's rounded corners.
	local edge = 9
	local clip = W.frame(parent, "Rays", edge, edge, 0, 0, W.white)
	clip.Size, clip.BackgroundTransparency, clip.ClipsDescendants = UDim2.new(1, -2 * edge, 1, -2 * edge), 1, true
	local hub = W.frame(clip, "Hub", x - edge, y - edge, 0, 0, W.white)
	hub.BackgroundTransparency = 1
	for i = 1, count do
		local ray = W.frame(hub, "Ray", 0, 0, length * 2, length * 0.15, color or W.white)
		W.anchor(ray, 0.5, 0.5, UDim2.fromOffset(0, 0))
		ray.Rotation, ray.BackgroundTransparency = (i - 1) * 180 / count, transparency or 0.84
	end
	local turn = TweenService:Create(hub, TweenInfo.new(16, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
	turn:Play()
	clip.Destroying:Once(function() turn:Cancel() end)
	return clip, hub
end

-- A band of light across a panel.
function Burst.shine(panel, radius)
	local clip = W.frame(panel, "Shine", 0, 0, 0, 0, W.white, radius)
	clip.Size, clip.BackgroundTransparency, clip.ClipsDescendants, clip.ZIndex = UDim2.fromScale(1, 1), 1, true, 20
	local band = W.frame(clip, "Band", 0, 0, 34, 0, W.white)
	band.Size, band.Position, band.Rotation = UDim2.new(0, 34, 1.8, 0), UDim2.new(-0.3, 0, -0.4, 0), 20
	band.BackgroundTransparency = 0.5
	W.tween(band, 0.6, { Position = UDim2.new(1.2, 0, -0.4, 0) }).Completed:Once(function() clip:Destroy() end)
end

local function step(obj, seconds, style, goal)
	local tween = TweenService:Create(obj, TweenInfo.new(seconds, style, Enum.EasingDirection.Out), goal)
	tween:Play()
	return tween
end

-- Drops in from above, overshoots, comes back up and settles.
function Burst.drop(obj, rest)
	obj.Position = UDim2.new(rest.X.Scale, rest.X.Offset, -0.7, 0)
	task.spawn(function()
		for _, move in { { 0.34, 34, Enum.EasingStyle.Quad }, { 0.17, -18, Enum.EasingStyle.Sine }, { 0.14, 8, Enum.EasingStyle.Sine }, { 0.11, 0, Enum.EasingStyle.Sine } } do
			if not obj.Parent then return end
			step(obj, move[1], move[3], { Position = rest + UDim2.fromOffset(0, move[2]) }).Completed:Wait()
		end
	end)
end

-- A quick swell that settles.
function Burst.pop(scale, rest, size)
	scale.Scale = rest * (size or 1.2)
	step(scale, 0.42, Enum.EasingStyle.Back, { Scale = rest })
end

return Burst
