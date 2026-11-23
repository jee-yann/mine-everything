local Actions = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Prompts = game:GetService("ProximityPromptService")
local Run = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Film = require(script.Film)
local Exposure = require(script.Exposure)
local ease = require(script.Props).ease
local Beats = require(script.Beats)
local Audio = require(script.Parent.HarborAudio)
local W = require(script.Parent.Widgets)
local rgb = Color3.fromHex
local Opening = {}

-- Keep gameplay labels and the live avatar out of its double's shot. Streamed-in
-- signs and accessories use the same restoration path as existing instances.
local function clearSightlines(root, isCharacter)
	local hidden, connections = {}, {}
	local function hidePart(p)
		if p:IsA("BasePart") and hidden[p] == nil then
			hidden[p] = p.LocalTransparencyModifier
			p.LocalTransparencyModifier = 1
		elseif p:IsA("BillboardGui") and p.Enabled then
			hidden[p] = true
			p.Enabled = false
		end
	end
	local function hideSign(p)
		if p:IsA("BillboardGui") and p.Enabled then
			hidden[p] = true
			p.Enabled = false
		end
	end
	local function watch(root, hide)
		if not root then
			return
		end
		table.insert(connections, root.DescendantAdded:Connect(hide))
		for _, p in root:GetDescendants() do
			hide(p)
		end
	end
	watch(root, if isCharacter then hidePart else hideSign)
	return function()
		for _, c in connections do
			c:Disconnect()
		end
		for p, old in hidden do
			if p.Parent then
				if p:IsA("BillboardGui") then
					p.Enabled = old
				elseif p.LocalTransparencyModifier == 1 then
					p.LocalTransparencyModifier = old
				end
			end
		end
	end
end

local function layer(player, name, order, insets)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.DisplayOrder, gui.ScreenInsets = name, order, insets
	gui.ResetOnSpawn, gui.ZIndexBehavior = false, Enum.ZIndexBehavior.Sibling
	gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	gui.Parent = player.PlayerGui
	return gui
end
local function textLimit(label, font, maxSize)
	label.Font, label.TextScaled, label.TextWrapped = font, true, true
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize, constraint.MaxTextSize, constraint.Parent = 10, maxSize, label
	return constraint
end
local function compose(screen, safe)
	local bars = W.frame(screen, "Letterbox", 0, 0, 1, 1, rgb("10131D"))
	bars.Size, bars.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	local upper = W.frame(bars, "Upper", 0, 0, 1, 1, rgb("10131D"))
	local lower = W.frame(bars, "Lower", 0, 0, 1, 1, rgb("10131D"))
	bars.ZIndex = 6
	upper.BackgroundColor3, lower.BackgroundColor3 = rgb("06080D"), rgb("06080D")
	lower.AnchorPoint, lower.Position = Vector2.new(0, 1), UDim2.fromScale(0, 1)
	local scrim = W.frame(screen, "Subtitle shade", 0, 0, 1, 1, rgb("0D1018"))
	scrim.AnchorPoint, scrim.Position, scrim.Size = Vector2.new(0, 1), UDim2.fromScale(0, 1), UDim2.fromScale(1, 0.31)
	local ramp = Instance.new("UIGradient")
	ramp.Rotation, ramp.Transparency, ramp.Parent = 90, NumberSequence.new(1, 0.06), scrim
	local fade = W.frame(screen, "Dissolve", 0, 0, 1, 1, rgb("040509"))
	fade.Size, fade.ZIndex = UDim2.fromScale(1, 1), 8
	local caption = W.text(safe, "", 0, 0, 1, 1, 24, rgb("FFF3DF"))
	caption.Name, caption.AnchorPoint = "Caption", Vector2.new(0.5, 0.5)
	caption.TextStrokeColor3 = rgb("12111A")
	textLimit(caption, Enum.Font.BuilderSansMedium, 38)
	local era = W.text(safe, "", 0, 0, 1, 1, 14, rgb("FFE0AE"))
	era.Name, era.AnchorPoint = "Era", Vector2.new(0.5, 1)
	textLimit(era, Enum.Font.BuilderSansBold, 18)
	-- Dates stay on the landscape. The shoulder shot at spawn carries the title.
	local dateline = W.text(safe, "", 0, 0, 1, 1, 17, rgb("FFEDC8"))
	dateline.Name, dateline.AnchorPoint = "Date", Vector2.new(0, 0)
	dateline.Position, dateline.Size = UDim2.fromScale(0.05, 0.105), UDim2.fromScale(0.66, 0.075)
	dateline.TextXAlignment, dateline.TextStrokeColor3 = Enum.TextXAlignment.Left, rgb("17202A")
	textLimit(dateline, Enum.Font.BuilderSansBold, 22)
	local card = W.text(safe, "", 0, 0, 1, 1, 43, rgb("FFF2D3"))
	card.Name, card.AnchorPoint = "Intertitle", Vector2.new(0, 1)
	card.Position, card.Size = UDim2.fromScale(0.055, 0.89), UDim2.fromScale(0.80, 0.10)
	card.TextXAlignment, card.TextStrokeColor3 = Enum.TextXAlignment.Left, rgb("151622")
	textLimit(card, Enum.Font.BuilderSansExtraBold, 78)
	local skip = Instance.new("TextButton")
	skip.Name, skip.Text, skip.Font, skip.TextSize = "Skip", "Skip  â€º", Enum.Font.BuilderSansMedium, 16
	skip.AnchorPoint, skip.Position, skip.Size = Vector2.new(1, 0), UDim2.new(1, -12, 0, 6), UDim2.fromOffset(84, 44)
	skip.TextColor3, skip.BackgroundColor3, skip.BackgroundTransparency = rgb("FFF3DF"), rgb("151622"), 0.32
	skip.BorderSizePixel, skip.Parent = 0, safe
	W.round(skip, 7)
	local lastHeight
	local function aperture(t, motion)
		local size = bars.AbsoluteSize
		local portrait = size.X < size.Y
		local action = if t < 6.63 then 1 elseif t < 6.76 then 0.52 elseif t >= 8.56 and t < 12.12 then 0.43 else 0
		local listen = ease(t, 30.54, 31.42) * (1 - ease(t, 44.98, 48.81))
		local base = if portrait then 0.026 else 0.036
		local opening = if portrait then 0.036 else 0.068
		local extra = if motion then opening * (action + 0.53 * listen) else opening * 0.43
		local height = math.floor(size.Y * (base + extra) * (1 - ease(t, 47.1, 48.86)) + 0.5)
		if lastHeight ~= height then
			lastHeight = height
			upper.Size, lower.Size = UDim2.new(1, 0, 0, height), UDim2.new(1, 0, 0, height)
		end
	end
	local function resize()
		local size = bars.AbsoluteSize
		local narrow = size.X < size.Y
		caption.Size =
			UDim2.new(if narrow then 0.90 else 0.84, 0, 0, if narrow then 85 else math.clamp(size.Y * 0.105, 38, 76))
		caption.Position = UDim2.fromScale(0.5, if narrow then 0.82 else 0.87)
		era.Size = UDim2.new(0.85, 0, 0, 18)
		era.Position = caption.Position - UDim2.fromOffset(0, caption.Size.Y.Offset / 2 + 3)
		card.Size = UDim2.fromScale(if narrow then 0.90 else 0.60, if narrow then 0.09 else 0.115)
		card.Position = UDim2.fromScale(0.055, if narrow then 0.88 else 0.90)
	end
	bars:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	return caption, era, skip, fade, card, dateline, scrim, aperture
end

function Opening.play(player, net, hud)
	local camera, char = workspace.CurrentCamera, player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local site, gate = net:GetAttribute("DigFloor"), net:GetAttribute("Entrance")
	if hud.inOpening or not camera or not root or not site or not gate then
		return
	end
	local oldView, oldFocus, oldFov, oldType = camera.CFrame, camera.Focus, camera.FieldOfView, camera.CameraType
	local oldHud, oldPrompts = hud.root.Visible, Prompts.Enabled
	local aimGui = hud.reticle.Parent
	local oldAim = aimGui.Enabled
	local screen = layer(player, "Mine origins", 24, Enum.ScreenInsets.None)
	local safe = layer(player, "Mine subtitles", 25, Enum.ScreenInsets.CoreUISafeInsets)
	local stage = Instance.new("Folder")
	stage.Name, stage.Parent = "Mine origins set", camera
	-- A parked BillboardGui can still draw under PlayerGui. Keep inactive props
	-- out of both the world and the GUI until their shot starts.
	local shelf = Instance.new("Folder")
	shelf.Name = "Offstage"
	local oldClock = Lighting.ClockTime
	local controls, chatEnabled, skipped, finished, revealAvatar, revealSigns, film, exposure
	local remoteReplay = false
	local lens = Instance.new("DepthOfFieldEffect")
	lens.Name, lens.Enabled, lens.Parent = "Mine origins focus", false, camera
	hud.inOpening, hud.root.Visible, Prompts.Enabled = true, false, false
	aimGui.Enabled = false
	local function run()
		local caption, era, skip, fade, card, dateline, scrim, aperture = compose(screen, safe)
		exposure = Exposure.new(screen, camera)
		skip.Activated:Connect(function()
			skipped = true
		end)
		Actions:BindActionAtPriority("Skip mine origins", function(_, state)
			if state == Enum.UserInputState.Begin then
				skipped = true
			end
			return Enum.ContextActionResult.Sink
		end, false, 3100, Enum.KeyCode.Return, Enum.KeyCode.ButtonB)
		Actions:BindActionAtPriority("Watch mine origins", function()
			return Enum.ContextActionResult.Sink
		end, false, 3050, table.unpack(Enum.PlayerActions:GetEnumItems()))
		local module = player.PlayerScripts:FindFirstChild("PlayerModule")
		if module then
			controls = require(module):GetControls()
			controls:Disable()
		end
		chatEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
		if chatEnabled then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		end
		camera.CameraType = Enum.CameraType.Scriptable
		revealAvatar = clearSightlines(char, true)
		revealSigns = clearSightlines(workspace:FindFirstChild("CitrineCove"), false)
		if workspace.StreamingEnabled then
			task.spawn(function()
				pcall(player.RequestStreamAroundAsync, player, site, 4)
			end)
		end
		local motion = player:GetAttribute("MenuMotion") ~= false
		aperture(0, motion)
		local landing = net:GetAttribute("Landing") or root.Position
		local handoff =
			{ root = root, start = root.Position, landing = landing, view = oldView, focus = oldFocus, fov = oldFov }
		film = Film.new(shelf, stage, camera, site, gate, motion, oldClock, char, handoff)
		local sound = Audio.origins(screen)
		-- Submit the first view under black before starting the score and camera clock.
		film:draw(0, false)
		Run.PreRender:Wait()
		Run.PreRender:Wait()
		local contactDelay, previous = 0, 0
		local start = os.clock()
		while not skipped and player.Character == char and root.Parent and workspace.CurrentCamera == camera do
			local t = os.clock() - start
			t -= contactDelay
			if previous < Beats.impact and t >= Beats.impact then
				-- Start the contact drawing and its untrimmed transient on the same
				-- render callback even if a hitch consumes the expected timestamp.
				contactDelay = t - Beats.impact
				t = Beats.impact
			end
			previous = t
			local island = workspace:FindFirstChild("CitrineCove")
			local gallery = island and island:FindFirstChild("Working gallery")
			local gateModel = island and island:FindFirstChild("Citrine Mine")
			local live = gallery
				and gallery:FindFirstChild("Entrance sill")
				and gateModel
				and gateModel:FindFirstChild("Mine sign")
			local black = film:draw(t, live ~= nil)
			aperture(t, motion)
			exposure:draw(t, film)
			if t >= Beats.arrival and revealAvatar then
				revealAvatar()
				revealAvatar = nil
			end
			lens.Enabled = (t >= 31.66 and t < 33.34) or (t >= 35.13 and t < 37.26) or (t >= 41.86 and t < 44.32)
			if lens.Enabled then
				lens.FocusDistance = (camera.Focus.Position - camera.CFrame.Position).Magnitude
				lens.InFocusRadius, lens.FarIntensity, lens.NearIntensity = 2.2, 0.34, 0.08
			end
			local date, line, opacity = Film.caption(t)
			caption.Text, era.Text = line, date
			caption.TextTransparency, era.TextTransparency = 1 - opacity, 1 - opacity
			caption.TextStrokeTransparency = 1 - 0.56 * opacity
			local title, titleOpacity = Film.card(t)
			card.Text, card.TextTransparency = if titleOpacity > 0 then title else "", 1 - titleOpacity
			card.TextStrokeTransparency = 1 - 0.65 * titleOpacity
			local period, strength = Film.era(t)
			dateline.Position = if t >= Beats.history and t < Beats.present
				then UDim2.fromScale(0.05, 0.845)
				else UDim2.fromScale(0.05, 0.135)
			dateline.Text, dateline.TextTransparency = period, 1 - strength
			dateline.TextStrokeTransparency = 1 - 0.70 * strength
			scrim.BackgroundTransparency = 1 - 0.87 * opacity
			fade.BackgroundTransparency = 1 - black
			sound(t)
			if t >= Film.duration then
				remoteReplay = (root.Position - landing).Magnitude >= 38
				finished = true
				break
			end
			Run.PreRender:Wait()
		end
		if (skipped or finished) and not player:GetAttribute("IntroSeen") then
			net.Action:FireServer("IntroSeen")
		end
		return fade
	end
	local ok, result = xpcall(run, debug.traceback)
	Actions:UnbindAction("Watch mine origins")
	Actions:UnbindAction("Skip mine origins")
	if film then
		film:Destroy()
	end
	if exposure then
		exposure:Destroy()
	end
	stage:Destroy()
	shelf:Destroy()
	lens:Destroy()
	if revealAvatar then
		revealAvatar()
	end
	if revealSigns then
		revealSigns()
	end
	Lighting.ClockTime = oldClock
	if workspace.CurrentCamera == camera then
		if player.Character == char and (not finished or remoteReplay) then
			camera.CFrame, camera.Focus = oldView, oldFocus
		end
		-- A respawn during a Scriptable shot can leave the default camera tracking
		-- the removed Humanoid, even after the new character is ready to play.
		local subject = camera.CameraSubject
		if oldType == Enum.CameraType.Custom and (not subject or not subject:IsDescendantOf(workspace)) then
			local current = player.Character
			local humanoid = current and current:FindFirstChildOfClass("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end
		camera.FieldOfView, camera.CameraType = oldFov, oldType
	end
	if controls then
		controls:Enable()
	end
	if chatEnabled then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	end
	hud.root.Visible, Prompts.Enabled = oldHud, oldPrompts
	aimGui.Enabled = oldAim
	safe:Destroy()
	if ok and finished and remoteReplay then
		result.Parent.Letterbox.Visible = false
		result.Parent["Subtitle shade"].Visible = false
		W.tween(result, 0.35, { BackgroundTransparency = 1 }).Completed:Wait()
	end
	screen:Destroy()
	hud.inOpening = false
	if not ok then
		warn("Mine origins:", result)
	end
end
return Opening
