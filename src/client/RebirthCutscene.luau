-- A short scene for the miner's own rebirth: a star falls on them, a pillar of light rises, the camera
-- circles while the new bonuses come up, then play goes on. About seven seconds, and it can be skipped.
local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Prompts = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
local W = require(script.Parent.Widgets)
local Audio = require(script.Parent.HarborAudio)
local Burst = require(script.Parent.Burst)
local Scene = { length = 7.2 }
local rgb = Color3.fromRGB
local violet, pale, gold = rgb(181, 133, 255), rgb(236, 222, 255), rgb(255, 214, 90)

local function ease(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end
local function glow(parent, name, shape, size, color, cf, transparency)
	local part = Instance.new("Part")
	part.Name, part.Shape, part.Size, part.Color, part.CFrame = name, shape, size, color, cf
	part.Material, part.Transparency = Enum.Material.Neon, transparency or 0
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Parent = parent
	return part
end
local function tween(obj, seconds, goal, style)
	local t = TweenService:Create(obj, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

-- The words on screen: bars, a flash, the title, the bonuses one by one, and Skip.
local function compose(player, count)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder = "Rebirth cutscene", true, false, 60
	gui.Parent = player.PlayerGui
	local bars = {}
	for i, side in { "Top", "Bottom" } do
		local bar = W.frame(gui, side .. " bar", 0, 0, 0, 0, rgb(10, 8, 24))
		bar.Size, bar.AnchorPoint = UDim2.fromScale(1, 0), Vector2.new(0, i - 1)
		bar.Position = UDim2.fromScale(0, i - 1)
		bars[i] = bar
	end
	local flash = W.frame(gui, "Flash", 0, 0, 0, 0, pale)
	flash.Size, flash.BackgroundTransparency, flash.ZIndex = UDim2.fromScale(1, 1), 1, 5
	local card = W.frame(gui, "Words", 0, 0, 760, 330, W.white)
	card.BackgroundTransparency, card.AnchorPoint = 1, Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.34)
	local fit = W.scale(card)
	local function size()
		local view = gui.AbsoluteSize
		fit.Scale = math.clamp(math.min(view.X / 900, view.Y / 620), 0.45, 1.3)
	end
	size()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(size)
	local kicker = W.title(card, "A NEW RUN BEGINS", 0, 0, 760, 40, 30, rgb(255, 244, 170))
	W.navyText(kicker, 3)
	local title = W.title(card, "REBIRTH " .. count, 0, 38, 760, 110, 96, W.white)
	W.navyText(title, 6)
	local shine = Instance.new("UIGradient")
	shine.Color = ColorSequence.new(rgb(255, 250, 225), violet)
	shine.Rotation, shine.Parent = 90, title
	local lines = {}
	for i, perk in Rebirth.perks do
		local line = W.title(card, perk.name .. "   " .. perk.text(count), 0, 150 + (i - 1) * 46, 760, 42, 32, gold)
		W.navyText(line, 3.4)
		lines[i] = line
	end
	for _, label in { kicker, title, table.unpack(lines) } do
		label.TextTransparency = 1
		label.UIStroke.Transparency = 1
	end
	local skip = W.title(gui, "Skip  ▸", 0, 0, 160, 44, 26, W.white)
	skip.AnchorPoint, skip.Position, skip.TextTransparency = Vector2.new(1, 1), UDim2.new(1, -24, 1, -18), 1
	W.navyText(skip, 2.6).Transparency = 1
	local skipButton = Instance.new("TextButton")
	skipButton.Name, skipButton.Text, skipButton.BackgroundTransparency = "Skip", "", 1
	skipButton.Size, skipButton.Parent = UDim2.fromScale(1, 1), skip
	return gui, bars, flash, card, kicker, title, lines, skip, skipButton
end

local function show(label, seconds)
	tween(label, seconds, { TextTransparency = 0 })
	tween(label.UIStroke, seconds, { Transparency = 0 })
end

-- Returns false when the scene can't play here (no character, or motion is turned off).
function Scene.play(player, hud, count)
	local camera = workspace.CurrentCamera
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if hud.inOpening or not camera or not root or not Burst.allowed(player) then
		return false
	end
	hud.inOpening = true
	local hudVisible, promptsOn = hud.root.Visible, Prompts.Enabled
	hud.root.Visible, Prompts.Enabled = false, false
	local oldType, oldSubject, oldFov = camera.CameraType, camera.CameraSubject, camera.FieldOfView
	local gui, bars, flash, card, kicker, title, lines, skip, skipButton = compose(player, count)
	local set = Instance.new("Folder")
	set.Name, set.Parent = "Rebirth set", workspace
	local center = root.Position
	local ground = center - Vector3.yAxis * 3
	local ended = false
	local function finish()
		ended = true
	end
	skipButton.Activated:Connect(finish)
	local keys = Input.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
			finish()
		end
	end)
	camera.CameraType = Enum.CameraType.Scriptable
	for _, bar in bars do
		tween(bar, 0.45, { Size = UDim2.fromScale(1, 0.1) })
	end
	tween(skip, 0.4, { TextTransparency = 0.15 })
	tween(skip.UIStroke, 0.4, { Transparency = 0.15 })

	-- The star: a bright core with a long tail, falling from high in the sky.
	local from = center + Vector3.new(46, 150, -70)
	local star = glow(set, "Falling star", Enum.PartType.Ball, Vector3.one * 6, pale, CFrame.new(from))
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Parent = violet, 40, 3, star
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position, a0.Parent, a1.Parent = Vector3.new(0, 1.6, 0), Vector3.new(0, -1.6, 0), star, star
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1, trail.Lifetime, trail.LightEmission = a0, a1, 0.55, 1
	trail.Color = ColorSequence.new(pale, violet)
	trail.Transparency = NumberSequence.new(0, 1)
	trail.WidthScale = NumberSequence.new(1, 0.1)
	trail.FaceCamera, trail.Parent = true, star
	-- Its glow on the miner stays until the end.
	local aura = Instance.new("PointLight")
	aura.Color, aura.Range, aura.Brightness, aura.Parent = violet, 0, 2.4, root

	local start = os.clock()
	local landed, titled = false, false
	local shown = {}
	local pillar, ring
	local sparks = {}
	local view0 = camera.CFrame
	while not ended and os.clock() - start < Scene.length do
		local t = os.clock() - start
		-- Camera: up high to watch the fall, then down to circle the miner, then back behind them.
		local cf
		if t < 1.5 then
			local k = ease(t / 1.5)
			local high = CFrame.lookAt(center + Vector3.new(-26, 34, 34), center:Lerp(from, 0.18 * (1 - k)))
			cf = view0:Lerp(high, ease(t / 0.6))
		elseif t < 5.9 then
			local k = (t - 1.5) / 4.4
			local angle = math.rad(-40 + 210 * ease(k))
			local radius, height = 16 - 4 * ease(k), 9 - 3.5 * ease(k)
			local eye = center + Vector3.new(math.sin(angle) * radius, height, math.cos(angle) * radius)
			cf = CFrame.lookAt(eye, center + Vector3.new(0, 1.5 + 2 * k, 0))
		else
			local k = ease((t - 5.9) / 1.3)
			local look = root.CFrame.LookVector
			local behind = CFrame.lookAt(root.Position - look * 13 + Vector3.new(0, 6, 0), root.Position + Vector3.new(0, 2, 0))
			local angle = math.rad(170)
			local last = CFrame.lookAt(center + Vector3.new(math.sin(angle) * 12, 5.5, math.cos(angle) * 12), center + Vector3.new(0, 3.5, 0))
			cf = last:Lerp(behind, k)
		end
		camera.CFrame = cf
		-- The fall.
		if t < 1.3 then
			local k = (t / 1.3) ^ 2
			star.Position = from:Lerp(center + Vector3.new(0, 2, 0), k)
		elseif not landed then
			landed = true
			star.Transparency = 1
			light.Enabled = false
			Audio.unlock(true)
			flash.BackgroundTransparency = 0.05
			tween(flash, 0.7, { BackgroundTransparency = 1 })
			ring = glow(set, "Shockwave", Enum.PartType.Cylinder, Vector3.new(0.4, 2, 2), pale, CFrame.new(ground) * CFrame.Angles(0, 0, math.rad(90)), 0.2)
			tween(ring, 0.9, { Size = Vector3.new(0.4, 70, 70), Transparency = 1 })
			pillar = glow(set, "Light pillar", Enum.PartType.Cylinder, Vector3.new(80, 1, 1), violet, CFrame.new(ground + Vector3.yAxis * 40) * CFrame.Angles(0, 0, math.rad(90)), 0.6)
			tween(pillar, 0.5, { Size = Vector3.new(80, 6.5, 6.5) })
			tween(aura, 0.5, { Range = 22 })
			for i = 1, 26 do
				local angle = i / 26 * math.pi * 2
				local spark = glow(set, "Star spark", Enum.PartType.Block, Vector3.one * 0.7, if i % 3 == 0 then gold else pale,
					CFrame.new(ground + Vector3.new(math.cos(angle) * 2, 0.5, math.sin(angle) * 2)) * CFrame.Angles(0, angle, math.rad(45)))
				table.insert(sparks, { part = spark, angle = angle, speed = 3 + (i % 5), rise = 5 + (i % 7) * 1.6, born = t })
			end
		end
		for _, spark in sparks do
			local age = t - spark.born
			local spin = spark.angle + age * 1.4
			local r = 2 + age * spark.speed
			spark.part.CFrame = CFrame.new(ground + Vector3.new(math.cos(spin) * r, 0.5 + age * spark.rise, math.sin(spin) * r)) * CFrame.Angles(age * 3, age * 2, 0)
			spark.part.Transparency = math.clamp((age - 2.2) / 1.5, 0, 1)
		end
		if pillar and t > 4.6 and not shown.pillar then
			shown.pillar = true
			tween(pillar, 1.2, { Transparency = 1, Size = Vector3.new(80, 2, 2) })
		end
		-- The words.
		if t > 1.9 and not titled then
			titled = true
			show(kicker, 0.35)
			show(title, 0.3)
			local fit = W.scale(title)
			Burst.pop(fit, 1, 1.5)
			Audio.reward(1.25)
		end
		for i, line in lines do
			if t > 2.6 + (i - 1) * 0.45 and not shown[i] then
				shown[i] = true
				show(line, 0.3)
				Burst.pop(W.scale(line), 1, 1.3)
			end
		end
		if t > 2.2 and not shown.paper then
			shown.paper = true
			local view = gui.AbsoluteSize
			for _, side in { 0.25, 0.75 } do
				Burst.confetti(gui, view.X * side, view.Y * 0.3, 26, { violet, pale, gold, W.pink }, 1.1)
			end
		end
		Run.RenderStepped:Wait()
	end
	keys:Disconnect()
	-- Back to play.
	for _, bar in bars do
		tween(bar, 0.35, { Size = UDim2.fromScale(1, 0) })
	end
	tween(card, 0.35, { Position = UDim2.fromScale(0.5, 0.3) })
	for _, label in { kicker, title, skip, table.unpack(lines) } do
		tween(label, 0.35, { TextTransparency = 1 })
		tween(label.UIStroke, 0.35, { Transparency = 1 })
	end
	tween(aura, 0.6, { Range = 0 }).Completed:Once(function() aura:Destroy() end)
	set:Destroy()
	camera.CameraType, camera.FieldOfView = oldType, oldFov
	local human = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	camera.CameraSubject = if oldSubject and oldSubject:IsDescendantOf(workspace) then oldSubject else human
	hud.root.Visible, Prompts.Enabled = hudVisible, promptsOn
	hud.inOpening = false
	task.delay(0.4, function() gui:Destroy() end)
	return true
end

return Scene
