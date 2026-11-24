local Actions = game:GetService("ContextActionService")
local Gui = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Prompts = game:GetService("ProximityPromptService")
local Run = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Audio = require(script.Parent.HarborAudio)
local Film = require(script.Film)
local IntroTitles = require(script.IntroTitles)
local BeaconPrompt = require(script.BeaconPrompt)
local sheet = require(script.ExposureSheet)
local W = require(script.Parent.Widgets)
local Opening = {}
local hideOtherMiners = require(script.HideOtherMiners)

local function layer(owner, name, order, insets)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.DisplayOrder, gui.ScreenInsets = name, order, insets
	gui.ResetOnSpawn, gui.SafeAreaCompatibility = false, Enum.SafeAreaCompatibility.None
	gui.Parent = owner
	return gui
end
local function compose(screen, safe)
	local ink = Color3.fromHex("101724")
	local top = Instance.new("Frame")
	top.Name, top.BackgroundColor3, top.BorderSizePixel = "Top matte", Color3.new(), 0
	top.ZIndex, top.Parent = 50, screen
	local bottom = top:Clone()
	bottom.Name, bottom.AnchorPoint = "Bottom matte", Vector2.new(0, 1)
	bottom.Position, bottom.Parent = UDim2.fromScale(0, 1), screen
	local function fitMatte(frame)
		local size = screen.AbsoluteSize
		local aspect = size.X / math.max(1, size.Y)
		local height = if aspect < 1 then 0.06 else math.clamp((1 - aspect / 2.16) / 2, 0.045, 0.085)
		local release = math.clamp((frame - sheet.frames.handoff) / (sheet.frames.endBlend - sheet.frames.handoff), 0, 1)
		local bar = UDim2.fromScale(1, height * (1 - release * release * (3 - 2 * release)))
		top.Size, bottom.Size = bar, bar
		-- Both ScreenGuis use Roblox UI coordinates. Intersect the actual
		-- camera aperture with the CoreUI/notch-safe screen for this device.
		local offset = screen.AbsolutePosition.Y - safe.AbsolutePosition.Y
		local bars = size.Y * bar.Y.Scale
		return math.max(0, offset + bars), math.min(safe.AbsoluteSize.Y, offset + size.Y - bars)
	end
	fitMatte(0)
	local fade = W.frame(screen, "Dissolve", 0, 0, 1, 1, ink)
	fade.Size, fade.BackgroundTransparency, fade.ZIndex = UDim2.fromScale(1, 1), 0, 20
	local shade = W.frame(screen, "Caption shade", 0, 0, 1, 1, ink)
	shade.Position, shade.Size, shade.ZIndex = UDim2.fromScale(0, 0.74), UDim2.fromScale(1, 0.26), 6
	local grad = Instance.new("UIGradient")
	grad.Rotation, grad.Transparency, grad.Parent = 90, NumberSequence.new(1, 0.18), shade
	local caption = W.text(safe, "", 0, 0, 1, 1, 26, Color3.fromHex("FFF5DF"))
	caption.Name, caption.Font, caption.TextScaled, caption.TextWrapped =
		"Caption", Enum.Font.BuilderSansMedium, true, true
	caption.AnchorPoint, caption.Position, caption.Size =
		Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0.92), UDim2.fromScale(0.88, 0.095)
	caption.TextStrokeColor3 = ink
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize, limit.Parent = 13, 39, caption
	local skip = Instance.new("TextButton")
	skip.Name, skip.Text, skip.Font, skip.TextSize = "Skip", "Skip  ›", Enum.Font.BuilderSansMedium, 16
	skip.AnchorPoint, skip.Position, skip.Size = Vector2.new(1, 0), UDim2.new(1, -12, 0, 6), UDim2.fromOffset(84, 44)
	skip.BackgroundColor3, skip.BackgroundTransparency, skip.TextColor3 = ink, 0.28, Color3.fromHex("FFF5DF")
	skip.BorderSizePixel, skip.Parent = 0, safe
	W.round(skip, 7)
	skip.ZIndex = 12
	local strike, drawPrompt = BeaconPrompt(safe)
	local heldInput, releaseFrame
	local function drawStrike(frame, motion, contact, topEdge, bottomEdge)
		if heldInput and (heldInput.UserInputState == Enum.UserInputState.End or heldInput.UserInputState == Enum.UserInputState.Cancel) then
			heldInput, releaseFrame = nil, frame
		end
		drawPrompt(frame, motion, contact, topEdge, bottomEdge, if heldInput then math.huge else releaseFrame)
	end
	local title = IntroTitles.new(safe, screen)
	return skip,
		function(t, black, picture, motion, contact)
			local frame = picture or 0
			local pictureTop, pictureBottom = fitMatte(frame)
			local pictureHeight = math.max(1, pictureBottom - pictureTop)
			caption.Position = UDim2.new(0.5, 0, 0, pictureBottom - math.max(8, pictureHeight * 0.047))
			caption.Size = UDim2.new(0.86, 0, 0, math.clamp(pictureHeight * 0.068, 27, 63))
			drawStrike(frame, motion, contact, pictureTop, pictureBottom)
			local text, opacity = Film.caption(t)
			caption.Text, caption.TextTransparency, caption.TextStrokeTransparency =
				text, 1 - opacity, 1 - 0.62 * opacity
			shade.BackgroundTransparency = 1 - 0.78 * opacity
			fade.BackgroundTransparency = 1 - black
			-- Second-half fades are true black, continuous with the mattes.
			fade.BackgroundColor3 = if frame >= sheet.frames.aftermath then Color3.new() else ink
			title(frame, motion, pictureTop, pictureBottom)
		end,
		fade,
		strike,
		function(frame, motion, contact, input)
			heldInput, releaseFrame = input, nil
			drawStrike(frame, motion, contact, fitMatte(frame))
		end
end

local function liveCove()
	local island = workspace:FindFirstChild("CitrineCove")
	local gate = island and island:FindFirstChild("Citrine Mine")
	local court = island and island:FindFirstChild("Sand path and bridge")
	local market = island and island:FindFirstChild("Shore market")
	return gate and gate:FindFirstChild("Mine sign") and court and court:FindFirstChild("Landing") and market
end

function Opening.play(player, net, hud)
	local camera, char = workspace.CurrentCamera, player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local landing = net:GetAttribute("Landing")
	if hud.inOpening or not camera or not root or not landing then
		return
	end
	local h = {
		root = root,
		origin = net:GetAttribute("Origin"),
		landing = landing,
		entrance = net:GetAttribute("Entrance"),
		view = camera.CFrame,
		focus = camera.Focus,
		fov = camera.FieldOfView,
	}
	local mode = camera.FieldOfViewMode
	local lensProperty = if mode == Enum.FieldOfViewMode.Diagonal
		then "DiagonalFieldOfView"
		elseif mode == Enum.FieldOfViewMode.MaxAxis then "MaxAxisFieldOfView"
		else "FieldOfView"
	local originalLens = camera[lensProperty]
	local oldType = camera.CameraType
	local reticle = hud.reticle.Parent
	local hudVisible, aimEnabled, promptEnabled = hud.root.Visible, reticle.Enabled, Prompts.Enabled
	local screen = layer(player.PlayerGui, "Mine origins", 24, Enum.ScreenInsets.None)
	local safe = layer(player.PlayerGui, "Mine subtitles", 25, Enum.ScreenInsets.CoreUISafeInsets)
	local stage = Instance.new("Folder")
	stage.Name, stage.Parent = "Mine origins set", camera
	local controls, restoreControls, chat, film, fade, showOtherMiners
	local skipped, finished = false, false
	hud.inOpening, hud.root.Visible, reticle.Enabled, Prompts.Enabled = true, false, false, false
	local function run()
		showOtherMiners = hideOtherMiners(player)
		local motion = player:GetAttribute("MenuMotion") ~= false and not Gui.ReducedMotionEnabled
		local skip, titles, curtain, strike, confirmStrike = compose(screen, safe)
		local advanced = 0
		local function tap(input)
			local ahead = film and film.arrival and film.pictureFrame and film.arrival:requestStrike(film.pictureFrame)
			if ahead then
				-- The swing starts on the press. The clock skips the wait.
				advanced += ahead
				confirmStrike(sheet.frames.autoStrike, motion, film.arrival.pressed, input)
				return true
			end
			return false
		end
		strike.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				tap(input)
			end
		end)
		strike.Activated:Connect(tap)
		Actions:BindActionAtPriority("Light expedition route", function(_, state, input)
			if state == Enum.UserInputState.Begin and tap(input) then
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, 3110, Enum.KeyCode.Space, Enum.KeyCode.ButtonX)
		fade = curtain
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
			restoreControls = controls.controlsEnabled ~= false
			controls:Disable()
		end
		chat = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
		if chat then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		end
		camera.CameraType = Enum.CameraType.Scriptable
		if workspace.StreamingEnabled then
			task.spawn(function()
				pcall(player.RequestStreamAroundAsync, player, net:GetAttribute("Entrance") or landing, 4)
			end)
		end
		local mix = Audio.origins(screen)
		local sound = mix
		local function continueSetup()
			Run.PreRender:Wait()
			return not skipped and player.Character == char and root.Parent and camera == workspace.CurrentCamera
		end
		local nightLook
		local previewFrame = if Run:IsStudio() then workspace:GetAttribute("StarfallPreviewFrame") else nil
		if typeof(previewFrame) == "number" and previewFrame >= 0 then
			nightLook = require(script.StudioPreview)(previewFrame, continueSetup, function(picture, look)
				if film then
					film:Destroy()
					film = nil
				end
				film = Film.new(stage, screen, camera, h, motion, nil, look)
				local black = film:expose(picture, liveCove() ~= nil)
				titles(film.sceneTime, black, picture, motion, film.arrival.pressed)
			end)
			if film then
				film:Destroy()
				film = nil
			end
		end
		film = Film.new(stage, screen, camera, h, motion, continueSetup, nightLook)
		if film.impact then
			film:expose(0, false)
			titles(0, 0)
		end
		Run.PreRender:Wait()
		-- Give PlayerModule its own previous view before its camera step. Read
		-- back the view it actually chose, including avatar height and zoom,
		-- then redisplay the current exposure until the next picture frame.
		local function resumeCamera()
			-- Restore the invariant lens axis, including if the phone rotated
			-- while the cinematic was fitting its shots to vertical FOV.
			camera.CFrame, camera.Focus = h.view, h.focus
			camera[lensProperty] = originalLens
			local playable = { view = h.view, focus = h.focus, fov = camera.FieldOfView }
			h.playable = playable
			camera.CameraType = oldType
			Run:BindToRenderStep("Starfall prepare gameplay camera", Enum.RenderPriority.Camera.Value - 1, function()
				if camera == workspace.CurrentCamera and player.Character == char then
					camera.CFrame, camera.Focus, camera.FieldOfView = playable.view, playable.focus, playable.fov
				end
			end)
			Run:BindToRenderStep("Starfall compose final shot", Enum.RenderPriority.Camera.Value + 3, function()
				if camera == workspace.CurrentCamera and player.Character == char and root.Parent then
					playable.view, playable.focus, playable.fov = camera.CFrame, camera.Focus, camera.FieldOfView
					film:holdCamera()
				end
			end)
		end
		local start = os.clock()
		while
			film.impact
			and not skipped
			and player.Character == char
			and root.Parent
			and camera == workspace.CurrentCamera
		do
			local t = os.clock() - start + advanced / sheet.fps
			local pictureFrame = sheet.frameAt(t)
			if
				pictureFrame >= sheet.frames.handoff
				and not h.playable
				and oldType == Enum.CameraType.Custom
				and not film.arrival.remote
			then
				resumeCamera()
			end
			if film.pictureFrame ~= pictureFrame then
				local black = film:expose(pictureFrame, liveCove() ~= nil)
				titles(film.sceneTime, black, pictureFrame, motion, film.arrival.pressed)
			end
			sound(t)
			if t >= Film.duration then
				finished = true
				break
			end
			Run.PreRender:Wait()
		end
		if (finished or skipped) and not player:GetAttribute("IntroSeen") then
			net.Action:FireServer("IntroSeen")
		end
	end
	local ok, reason = xpcall(run, debug.traceback)
	if h.playable then
		Run:UnbindFromRenderStep("Starfall prepare gameplay camera")
		Run:UnbindFromRenderStep("Starfall compose final shot")
	end
	Actions:UnbindAction("Light expedition route")
	Actions:UnbindAction("Watch mine origins")
	Actions:UnbindAction("Skip mine origins")
	local remote = finished and film ~= nil and film.arrival ~= nil and film.arrival.remote == true
	if film then
		film:Destroy()
	end
	stage:Destroy()
	if workspace.CurrentCamera == camera then
		if player.Character == char and h.playable and finished and not remote then
			camera.CFrame, camera.Focus = h.playable.view, h.playable.focus
		elseif player.Character == char and (not finished or remote) then
			camera.CFrame, camera.Focus = h.view, h.focus
		end
		local subject = camera.CameraSubject
		if oldType == Enum.CameraType.Custom and (not subject or not subject:IsDescendantOf(workspace)) then
			local current = player.Character
			local human = current and current:FindFirstChildOfClass("Humanoid")
			if human then
				camera.CameraSubject = human
			end
		end
		if finished and h.playable and not remote then
			camera.FieldOfView = h.playable.fov
		else
			camera[lensProperty] = originalLens
		end
		camera.CameraType = oldType
	end
	if controls and restoreControls then
		controls:Enable()
	end
	if chat then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	end
	hud.root.Visible, reticle.Enabled, Prompts.Enabled = hudVisible, aimEnabled, promptEnabled
	safe:Destroy()
	if remote and fade then
		W.tween(fade, 0.20, { BackgroundTransparency = 1 }).Completed:Wait()
	end
	screen:Destroy()
	if showOtherMiners then
		showOtherMiners()
	end
	hud.inOpening = false
	if not ok then
		warn("Starfall opening:", reason)
	end
end
return Opening
