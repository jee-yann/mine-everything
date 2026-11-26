-- The miner's own rebirth: they rise into the sky, a ball of light swallows them, it pulses with turning
-- rings, then bursts and they float back down while the new bonuses come up. About eight seconds, and it
-- can be skipped. A copy of the miner acts it, so the real character never leaves the ground.
local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Prompts = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
local W = require(script.Parent.Widgets)
local Audio = require(script.Parent.HarborAudio)
local Burst = require(script.Parent.Burst)
local Avatar = require(script.Parent.Starfall.CinematicAvatar)
local Scene = { length = 8.4 }
local rgb = Color3.fromRGB
local violet, pale, gold = rgb(181, 133, 255), rgb(240, 230, 255), rgb(255, 214, 90)
local rise, height = { 0.5, 2.6 }, 30
local swallow, burst, land = 2.6, 5.3, 6.6

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
local function tween(obj, seconds, goal, style, direction)
	local t = TweenService:Create(obj, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
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
		bar.Size, bar.AnchorPoint, bar.Position = UDim2.fromScale(1, 0), Vector2.new(0, i - 1), UDim2.fromScale(0, i - 1)
		bars[i] = bar
	end
	local flash = W.frame(gui, "Flash", 0, 0, 0, 0, pale)
	flash.Size, flash.BackgroundTransparency, flash.ZIndex = UDim2.fromScale(1, 1), 1, 5
	local card = W.frame(gui, "Words", 0, 0, 760, 330, W.white)
	card.BackgroundTransparency, card.AnchorPoint, card.Position = 1, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.3)
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
	shine.Color, shine.Rotation, shine.Parent = ColorSequence.new(rgb(255, 250, 225), violet), 90, title
	local badge = W.title(card, Rebirth.badge(count), 0, 146, 760, 46, 40, Rebirth.tierColor(count))
	W.navyText(badge, 3.6)
	local lines = {}
	for i, perk in Rebirth.perks do
		local line = W.title(card, perk.name .. "   " .. perk.text(count), 0, 196 + (i - 1) * 44, 760, 40, 31, gold)
		W.navyText(line, 3.4)
		lines[i] = line
	end
	for _, label in { kicker, title, badge, table.unpack(lines) } do
		label.TextTransparency, label.UIStroke.Transparency = 1, 1
	end
	local skip = W.title(gui, "Skip  ▸", 0, 0, 160, 44, 26, W.white)
	skip.AnchorPoint, skip.Position, skip.TextTransparency = Vector2.new(1, 1), UDim2.new(1, -24, 1, -18), 1
	W.navyText(skip, 2.6).Transparency = 1
	local skipButton = Instance.new("TextButton")
	skipButton.Name, skipButton.Text, skipButton.BackgroundTransparency = "Skip", "", 1
	skipButton.Size, skipButton.Parent = UDim2.fromScale(1, 1), skip
	return gui, bars, flash, card, kicker, title, badge, lines, skip, skipButton
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
	local unmask, rig
	local okRig = pcall(function()
		local hide, alpha = Avatar.mask(char)
		unmask = hide
		rig = Avatar.new(char, alpha)
	end)
	if not okRig or not rig then
		if unmask then unmask() end
		return false
	end
	hud.inOpening = true
	local hudVisible, promptsOn = hud.root.Visible, Prompts.Enabled
	hud.root.Visible, Prompts.Enabled = false, false
	local controls
	local module = player.PlayerScripts:FindFirstChild("PlayerModule")
	if module then
		local ok, found = pcall(function() return require(module):GetControls() end)
		if ok and found then
			controls = found
			controls:Disable()
		end
	end
	local oldType, oldSubject, oldFov = camera.CameraType, camera.CameraSubject, camera.FieldOfView
	local gui, bars, flash, card, kicker, title, badge, lines, skip, skipButton = compose(player, count)
	local set = Instance.new("Folder")
	set.Name, set.Parent = "Rebirth set", workspace
	rig:show(set)
	local base = root.CFrame
	local ground = base.Position - Vector3.yAxis * 3
	local sky = base + Vector3.yAxis * height
	local ended = false
	skipButton.Activated:Connect(function() ended = true end)
	local keys = Input.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
			ended = true
		end
	end)
	camera.CameraType = Enum.CameraType.Scriptable
	for _, bar in bars do
		tween(bar, 0.45, { Size = UDim2.fromScale(1, 0.1) })
	end
	tween(skip, 0.4, { TextTransparency = 0.15 })
	tween(skip.UIStroke, 0.4, { Transparency = 0.15 })
	-- Arms open as they lift off.
	rig:turn("LeftShoulder", 0, 0, -115)
	rig:turn("RightShoulder", 0, 0, 115)

	local beam = glow(set, "Lift beam", Enum.PartType.Cylinder, Vector3.new(height + 6, 0.5, 0.5), violet,
		CFrame.new(ground + Vector3.yAxis * (height + 6) / 2) * CFrame.Angles(0, 0, math.rad(90)), 0.55)
	tween(beam, 0.5, { Size = Vector3.new(height + 6, 5, 5) })
	local aura = Instance.new("PointLight")
	aura.Color, aura.Range, aura.Brightness = violet, 18, 2.2
	local orb, core, light
	local rings, trail, sparks, shown = {}, {}, {}, {}
	local nextSpark = 0
	local view0 = camera.CFrame
	local start = os.clock()
	local function at(t)
		if t < rise[1] then return base end
		if t < swallow then
			local k = ease((t - rise[1]) / (rise[2] - rise[1]))
			return base:Lerp(sky, k) * CFrame.Angles(0, math.rad(360 * k), 0)
		end
		if t < burst then return sky end
		-- Down again, slow at the end.
		local k = 1 - (1 - math.clamp((t - burst - 0.25) / (land - burst - 0.25), 0, 1)) ^ 3
		return sky:Lerp(base, k)
	end
	while not ended and os.clock() - start < Scene.length do
		local t = os.clock() - start
		local body = at(t)
		local center = body.Position
		-- The copy of the miner: seen rising, gone inside the ball, back after the burst.
		if t > swallow + 0.45 and t < burst + 0.25 then
			rig.model.Parent = nil
		else
			rig:show(set)
			rig:place(body)
		end
		if not aura.Parent and rig.model:FindFirstChild("HumanoidRootPart") then
			aura.Parent = rig.model.HumanoidRootPart
		end
		-- Camera: low and close for the lift, out wide around the ball, then back behind the miner.
		local cf
		if t < swallow then
			local k = ease(t / swallow)
			local eye = base.Position + base.LookVector * 15 + base.RightVector * 6 + Vector3.new(0, 3 + 8 * k, 0)
			cf = view0:Lerp(CFrame.lookAt(eye, center + Vector3.yAxis * 1.5), ease(t / 0.5))
		elseif t < burst + 0.2 then
			local k = (t - swallow) / (burst + 0.2 - swallow)
			local angle = math.rad(30 + 90 * k)
			local reach = 30 - 4 * k
			cf = CFrame.lookAt(sky.Position + Vector3.new(math.sin(angle) * reach, -6 + 3 * k, math.cos(angle) * reach), sky.Position)
		elseif t < land then
			-- Close beside the miner as they float down.
			local k = ease((t - burst - 0.2) / (land - burst - 0.2))
			local angle = math.rad(120 + 30 * k)
			local reach = 26 - 12 * k
			local wide = CFrame.lookAt(sky.Position + Vector3.new(math.sin(math.rad(120)) * 26, -3, math.cos(math.rad(120)) * 26), sky.Position)
			local near = CFrame.lookAt(center + Vector3.new(math.sin(angle) * reach, 2 + 2 * (1 - k), math.cos(angle) * reach), center + Vector3.yAxis * 1.5)
			cf = wide:Lerp(near, ease((t - burst - 0.2) / 0.5))
		else
			local k = ease((t - land) / (Scene.length - land))
			local behind = CFrame.lookAt(base.Position - base.LookVector * 13 + Vector3.new(0, 6, 0), base.Position + Vector3.new(0, 2, 0))
			local angle = math.rad(150)
			local last = CFrame.lookAt(base.Position + Vector3.new(math.sin(angle) * 14, 2, math.cos(angle) * 14), base.Position + Vector3.yAxis * 1.5)
			cf = last:Lerp(behind, k)
		end
		camera.CFrame = cf
		-- Sparks drop away under the rising miner.
		if t > rise[1] and t < swallow + 0.3 and t >= nextSpark then
			nextSpark = t + 0.05
			local offset = Vector3.new(math.random() * 2 - 1, 0, math.random() * 2 - 1) * 1.6
			local spark = glow(set, "Lift spark", Enum.PartType.Block, Vector3.one * 0.55, if math.random() < 0.3 then gold else pale,
				CFrame.new(center + offset - Vector3.yAxis * 2) * CFrame.Angles(math.random() * 6, math.random() * 6, 0))
			table.insert(trail, { part = spark, born = t })
		end
		for i = #trail, 1, -1 do
			local spark = trail[i]
			local age = t - spark.born
			spark.part.Position -= Vector3.yAxis * 0.06
			spark.part.Transparency = math.clamp(age / 0.9, 0, 1)
			if age > 0.9 then
				spark.part:Destroy()
				table.remove(trail, i)
			end
		end
		-- The ball of light takes them.
		if t > swallow and not orb then
			orb = glow(set, "Light ball", Enum.PartType.Ball, Vector3.one * 0.5, rgb(200, 160, 255), CFrame.new(sky.Position), 0.3)
			core = glow(set, "Light core", Enum.PartType.Ball, Vector3.one * 0.3, rgb(255, 255, 255), CFrame.new(sky.Position), 0)
			light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness, light.Parent = violet, 0, 3, core
			tween(orb, 0.7, { Size = Vector3.one * 12 }, Enum.EasingStyle.Back)
			tween(core, 0.7, { Size = Vector3.one * 7 }, Enum.EasingStyle.Back)
			tween(light, 0.7, { Range = 60 })
			tween(beam, 0.6, { Transparency = 1 })
			Audio.unlock(false)
			for i = 1, 3 do
				local ring = glow(set, "Orbit ring", Enum.PartType.Cylinder, Vector3.new(0.3, 0.4, 0.4), if i == 2 then gold else violet, CFrame.new(sky.Position), 0.25)
				rings[i] = ring
				tween(ring, 0.8, { Size = Vector3.new(0.3, 18 + i * 3, 18 + i * 3) })
			end
		end
		if orb and t < burst then
			local beat = math.sin((t - swallow) * 7)
			orb.Size = orb.Size:Lerp(Vector3.one * (12 + beat * 0.9), 0.3)
			for i, ring in rings do
				ring.CFrame = CFrame.new(sky.Position) * CFrame.Angles(t * (0.9 + i * 0.4), t * (1.3 - i * 0.3), math.rad(90 + 35 * i))
			end
		end
		-- The burst.
		if t > burst and not shown.burst then
			shown.burst = true
			tween(orb, 0.14, { Size = Vector3.one * 3 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Once(function()
				orb.Transparency, core.Transparency = 1, 1
			end)
			task.delay(0.14, function()
				if not set.Parent then return end
				flash.BackgroundTransparency = 0.05
				tween(flash, 0.8, { BackgroundTransparency = 1 })
				Audio.unlock(true)
				local wave = glow(set, "Burst wave", Enum.PartType.Ball, Vector3.one * 4, pale, CFrame.new(sky.Position), 0.3)
				tween(wave, 0.9, { Size = Vector3.one * 80, Transparency = 1 })
				for _, ring in rings do
					tween(ring, 0.6, { Size = Vector3.new(0.3, 70, 70), Transparency = 1 })
				end
				tween(light, 1.2, { Range = 0 })
				for i = 1, 40 do
					local direction = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1).Unit
					local spark = glow(set, "Burst spark", Enum.PartType.Block, Vector3.one * (0.5 + math.random()), if i % 3 == 0 then gold else pale,
						CFrame.new(sky.Position))
					table.insert(sparks, { part = spark, velocity = direction * (24 + math.random() * 26), born = os.clock() - start })
				end
			end)
		end
		for _, spark in sparks do
			local age = t - spark.born
			spark.velocity = spark.velocity * 0.94 - Vector3.yAxis * 0.4
			spark.part.CFrame = CFrame.new(spark.part.Position + spark.velocity / 60) * CFrame.Angles(age * 4, age * 3, 0)
			spark.part.Transparency = math.clamp((age - 0.8) / 1.2, 0, 1)
		end
		-- The words.
		if t > swallow + 0.7 and not shown.title then
			shown.title = true
			show(kicker, 0.35)
			show(title, 0.3)
			Burst.pop(W.scale(title), 1, 1.5)
			Audio.reward(1.25)
		end
		if t > burst + 0.2 and not shown.badge then
			shown.badge = true
			show(badge, 0.3)
			Burst.pop(W.scale(badge), 1, 1.6)
			local view = gui.AbsoluteSize
			for _, side in { 0.25, 0.75 } do
				Burst.confetti(gui, view.X * side, view.Y * 0.3, 26, { violet, pale, gold, W.pink }, 1.1)
			end
		end
		for i, line in lines do
			if t > burst + 0.6 + (i - 1) * 0.4 and not shown[i] then
				shown[i] = true
				show(line, 0.3)
				Burst.pop(W.scale(line), 1, 1.3)
			end
		end
		Run.RenderStepped:Wait()
	end
	keys:Disconnect()
	-- Back to play.
	for _, bar in bars do
		tween(bar, 0.35, { Size = UDim2.fromScale(1, 0) })
	end
	tween(card, 0.35, { Position = UDim2.fromScale(0.5, 0.26) })
	for _, label in { kicker, title, badge, skip, table.unpack(lines) } do
		tween(label, 0.35, { TextTransparency = 1 })
		tween(label.UIStroke, 0.35, { Transparency = 1 })
	end
	rig:destroy()
	set:Destroy()
	unmask()
	camera.CameraType, camera.FieldOfView = oldType, oldFov
	local human = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	camera.CameraSubject = if oldSubject and oldSubject:IsDescendantOf(workspace) then oldSubject else human
	if controls then controls:Enable() end
	hud.root.Visible, Prompts.Enabled = hudVisible, promptsOn
	hud.inOpening = false
	task.delay(0.4, function() gui:Destroy() end)
	return true
end

return Scene
