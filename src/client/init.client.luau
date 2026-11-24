local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local net = Rep:WaitForChild("EndlessMiningNet")
local shared = Rep:WaitForChild("Shared")
for _, name in { "Mine", "Action", "Feedback", "Dust", "Swing" } do
	net:WaitForChild(name)
end
for _, name in
	{
		"BlockPattern",
		"GameConfig",
		"Materials",
		"Ores",
		"Upgrades",
		"Expeditions",
		"OrePurity",
		"FieldRewards",
		"PassCatalog",
		"Skills",
		"FieldGuide",
	}
do
	shared:WaitForChild(name)
end
local Config, Ores, Upgrades = require(shared.GameConfig), require(shared.Ores), require(shared.Upgrades)
local Skills = require(shared.Skills)
local owned = Skills.read(player)
player.AttributeChanged:Connect(function(key)
	local id = key:match("^Skill(.+)$")
	if id and Skills.byId[id] then
		owned[id] = player:GetAttribute(key) == true
	end
end)
local Pattern = require(shared.BlockPattern)
local Hud, Effects, W = require(script.Hud), require(script.Effects), require(script.Widgets)
local mobile = UIS.PreferredInput == Enum.PreferredInput.Touch
local hud = Hud.new(player, net, mobile)
local minerFocus = require(script.MinerFocus).new()
local Audio = require(script.HarborAudio)
local fx = Effects.new()
require(script.PadAura).start(player, hud)
local Swing = require(script.PickSwing)
local held, rig
local lastMineTap
local doubleTapWindow = 0.38
local target, targetSide, strokeStart
local finishedCell, retryAt
local aimPoint, aimSide, aimOre, aimPart, aimFacePoint
local swinging = false
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local origin = net:GetAttribute("Origin")
local landing = net:GetAttribute("Landing")
local entrance = net:GetAttribute("Entrance")
local passage = require(script.Passage).new(player, net)
local expedition = require(script.FirstExpedition).new(player, net, hud)
local joinOpeningPending = true
local previousStep = player:GetAttribute("ExpeditionStep")
player:GetAttributeChangedSignal("ExpeditionStep"):Connect(function()
	local step = player:GetAttribute("ExpeditionStep")
	if previousStep and previousStep ~= "Skipped" and step == "Done" then
		local nextGoal = if (player:GetAttribute("Power") or 1) == 1 then "Next goal: a Copper Pick to mine copper"
			else "Find your next ore in the Ore Index"
		hud:notice("First expedition complete!", nextGoal, W.gold)
	end
	previousStep = step
end)
local receipt = require(script.SaleReceipt).new(hud)
task.spawn(require(script.Tramway).run, origin)
local restoreSurfaceLight = require(script.MineView).start(player, origin, hud)
task.spawn(require(script.OreFaces))
local function cancelStroke()
	if rig then
		rig:stop()
	end
	if swinging then
		net.Swing:FireServer(false)
		swinging = false
	end
	target, targetSide, strokeStart = nil, nil, nil
	hud.meter.Visible = false
	fx:setMiningLight(nil)
	fx:clearDamage()
end
local function stopMining()
	if (held or hud.touchActions.enabled) and not swinging then
		net.Swing:FireServer(false)
	end
	held = nil
	if hud.touchActions.enabled then
		hud.touchActions:setAuto(false)
	end
	cancelStroke()
end
local function clearMineTap()
	lastMineTap = nil
end
local function release()
	clearMineTap()
	stopMining()
end
net:GetAttributeChangedSignal("Ready"):Connect(function()
	if not net:GetAttribute("Ready") then
		aimPoint = nil
		release()
		fx:aim(nil)
		fx:clearOreLights()
	end
end)
local function gotCharacter(character)
	release()
	if rig then
		rig:destroy()
	end
	rig, aimPoint = nil, nil
	params.FilterDescendantsInstances = { character }
	-- Face the mine approach when spawning in an empty place file.
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		for _ = 1, 100 do
			if (root.Position - landing).Magnitude < 18 then
				break
			end
			task.wait(0.05)
		end
		while player.Character == character and not workspace.CurrentCamera do
			RunService.PreRender:Wait()
		end
		if player.Character == character then
			workspace.CurrentCamera.CFrame =
				CFrame.lookAt(root.Position + Vector3.new(0, 7, 16), root.Position + Vector3.new(0, 4, -22))
			character:SetAttribute("MiningViewReady", true)
		end
	end
end
player.CharacterAdded:Connect(gotCharacter)
player.CharacterRemoving:Connect(release)
if player.Character then
	task.spawn(gotCharacter, player.Character)
end

UIS.InputBegan:Connect(function(input, processed)
	if processed or hud.inOpening or passage.active or GuiService.MenuIsOpen or UIS:GetFocusedTextBox()
		or (hud.chatInput and hud.chatInput.IsFocused)
	then
		return
	end
	local page = hud.hotbarPages[input.KeyCode]
	if page and input.UserInputType == Enum.UserInputType.Keyboard then
		if input:IsModifierKeyDown(Enum.ModifierKey.Ctrl)
			or input:IsModifierKeyDown(Enum.ModifierKey.Alt)
			or input:IsModifierKeyDown(Enum.ModifierKey.Meta)
		then
			return
		end
		hud:toggleHotbarPage(page)
		return
	end
	if input.KeyCode == Enum.KeyCode.Tab then
		if not hud.overlay.Visible then
			hud.roster:toggle()
		end
		return
	end
	if hud.overlay.Visible then
		return
	end
	if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY or input.KeyCode == Enum.KeyCode.DPadUp then
		local navigating = input.KeyCode ~= Enum.KeyCode.R and GuiService.SelectedObject
		local modified = input.KeyCode == Enum.KeyCode.R and (input:IsModifierKeyDown(Enum.ModifierKey.Ctrl)
			or input:IsModifierKeyDown(Enum.ModifierKey.Alt) or input:IsModifierKeyDown(Enum.ModifierKey.Meta))
		if hud.surface.Visible and hud.surface.Parent.Visible and not navigating and not modified then
			net.Action:FireServer("Surface")
		end
		return
	end
	if (not mobile and input.UserInputType == Enum.UserInputType.MouseButton1) or input.KeyCode == Enum.KeyCode.ButtonR2 then
		held = input
	end
end)
hud.mine.InputBegan:Connect(function(input)
	if
		hud.mine.Visible
		and not held
		and not passage.active
		and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1)
	then
		held = input
	end
end)
-- Roblox recognizes taps on this button separately from holds and camera drags.
-- Ending a manual hold must leave the first tap available for the second.
hud.mine.TouchLongPress:Connect(clearMineTap)
hud.mine.TouchPan:Connect(clearMineTap)
hud.mine.TouchTap:Connect(function(positions)
	if
		#positions ~= 1
		or not mobile
		or not hud.mine.Visible
		or passage.active
		or not player:GetAttribute("ProfileReady")
	then
		clearMineTap()
		return
	end
	local now = os.clock()
	if not lastMineTap or now - lastMineTap > doubleTapWindow then
		lastMineTap = now
		return
	end
	clearMineTap()
	if hud.touchActions.enabled then
		stopMining()
	elseif
		(player:GetAttribute("Used") or 0) < (player:GetAttribute("PackSlots") or Upgrades.items.Capacity.values[1])
	then
		hud.touchActions:setAuto(true)
	else
		return
	end
	Audio.preview()
end)
UIS.InputEnded:Connect(function(input)
	if
		held == input
		or (
			held
			and input.UserInputType == held.UserInputType
			and (held.UserInputType == Enum.UserInputType.MouseButton1
				or (held.KeyCode == Enum.KeyCode.ButtonR2 and input.KeyCode == held.KeyCode))
		)
	then
		if hud.touchActions.enabled then
			held = nil
		else
			stopMining()
		end
	end
end)
UIS.WindowFocusReleased:Connect(release)
UIS.TextBoxFocused:Connect(release)
GuiService.MenuOpened:Connect(release)
hud.overlay:GetPropertyChangedSignal("Visible"):Connect(release)
hud.mine:GetPropertyChangedSignal("Visible"):Connect(function()
	if not hud.mine.Visible and not (held and held.KeyCode == Enum.KeyCode.ButtonR2) then
		release()
	end
end)
UIS:GetPropertyChangedSignal("PreferredInput"):Connect(function()
	-- The first trigger press can itself switch a hybrid device to gamepad.
	local trigger = if UIS.PreferredInput == Enum.PreferredInput.Gamepad and held and held.KeyCode == Enum.KeyCode.ButtonR2 then held else nil
	mobile = UIS.PreferredInput == Enum.PreferredInput.Touch
	hud:placePanels(mobile)
	release()
	held = trigger
end)

net.Feedback.OnClientEvent:Connect(function(kind, a, point, spread, finds, normal)
	if kind == "achievement" or kind == "titleUnlocked" or kind == "aura" then
		hud.unlocks:show(kind, a)
	elseif kind == "skillLearned" then
		fx:chime(1.32)
		if hud.menu.map then
			hud.menu.map:showPurchase(a)
		end
	elseif kind == "pulse" then
		if player:GetAttribute("MenuMotion") ~= false then fx:pulse(a, point) end
		fx:chime(0.78)
	elseif kind == "loot" then
		expedition.lastCut = point
		local best = Ores.byName.Dirt
		for name in a do
			local ore = Ores.byName[name]
			hud:pickup(ore, a[name], point)
			if ore.value > best.value then
				best = ore
			end
		end
		Audio.ore(a)
		if owned.LightTrail and not best.host then
			fx:oreLight(point, owned.Constellation)
		end
		fx:burst(point, spread, best)
		fx:labels(finds, a, normal)
	elseif kind == "assay" then
		fx:assay(a, point, spread, finds)
	elseif kind == "caveCache" then
		fx:chime(1.65)
		hud:notice(
			if point then "Cave drake hatched! Equip it in Pets" else "Survey cache found",
			"+" .. a .. " G   ·   +1 survey flare",
			W.gold
		)
	elseif kind == "milestone" then
		if a == "ORE DISCOVERED" then hud.unlocks:show("discovery", point) else hud:milestone(a, point, spread) end
	elseif kind == "starfall" then
		-- a = finder's name, point = their lifetime Starfall count, spread = this player found it
		fx:chime(1.9)
		hud:notice(
			if spread then "★ You unearthed Starfall!" else "★ " .. a .. " unearthed Starfall!",
			if point > 1 then "Their Starfall number " .. point .. ". The rarest ore in the mine." else "The rarest ore in the mine, found only in the crater.",
			Ores.byName.Starfall.color
		)
	elseif kind == "depart" then
		release()
		passage:depart(a, point)
	elseif kind == "arrive" then
		passage:arrive(a)
	elseif kind == "sale" then
		if a > 0 then
			fx:chime(1.45)
			receipt:show(a, point, spread, finds)
			if hud.overlay.Visible and hud.menu.page == "Sell" then
				hud.menu.status.Text = string.format("Sold %s %s   ·   +%s G", W.goldAmount(point), finds or (if point == 1 then "block" else "blocks"), W.goldAmount(a))
			end
		elseif finds and hud.overlay.Visible and hud.menu.page == "Sell" then
			hud.menu.status.Text = "That quantity of " .. finds .. " is no longer in your pack."
		else
			hud:notice("Your pack is empty", "Mine a block to start a haul", W.gold)
		end
	elseif kind == "away" then
		hud:setShop(false)
		hud:notice(
			"Visit the counter",
			if a == "Sell"
				then "Sell under the amber sign"
				elseif a == "Shop" then "Upgrades under the cyan sign"
				elseif a == "Supplies" then "Visit Field Supplies beside the market"
				elseif a == "Jobs" then "Deliver materials at the Jobs board"
				else "Outfitters at the pink stall",
			W.gold
		)
	elseif kind == "shop" then
		hud:setShop(true)
	elseif kind == "page" then
		hud:openPage(a)
	elseif kind == "close" then
		hud:setShop(false)
	elseif kind == "job" then
		fx:chime(1.65)
		hud:notice("+" .. W.number(point) .. " gold", a .. " completed", W.gold)
	elseif kind == "resetSoon" then
		hud:milestone("MINE RENEWAL", "New ore in " .. a .. " seconds", W.aqua)
		hud:notice("Mine renews in " .. a .. " seconds", "Your haul returns to the entrance with you", W.aqua)
	elseif kind == "progressReset" then
		hud.menu.preferences.resetPending = false
		if a then
			release()
			fx:clearOreLights()
		end
		if hud.overlay.Visible and hud.menu.page == "Settings" then
			hud.menu.status.Text = point
			hud.menu:refresh()
		else
			hud:notice(point, "", if a then W.green else W.gold)
		end
	elseif kind == "upgrade" then
		fx:chime(1.55)
		hud:workshop(point, spread)
		hud:notice(a, Upgrades.describe(point, spread), W.green)
	else
		hud:notice(a, "", W.gold)
	end
end)
net.Dust.OnClientEvent:Connect(function(point, spread, ore, finds, normal, loot)
	if hud.inOpening then return end
	fx:labels(finds, loot, normal, true)
	fx:burst(point, spread, Ores.byName[ore], true)
end)

require(script.Podiums).start(player, hud)

Players.PlayerAdded:Connect(Swing.observe)
for _, other in Players:GetPlayers() do
	if other ~= player then
		Swing.observe(other)
	end
end

require(script.RockCompanions)(hud, origin)
local lastDepth, lastRegion
local function targetName(ore, center)
	if ore.secret and not player:GetAttribute("Found" .. ore.name) then
		return "???"
	end
	if ore.name == "Stone" then
		return Config.StoneGrades[Config.strength(center.Y - origin.Y)].name
	end
	return ore.name
end
local function sampleAim()
	aimPoint, aimPart = nil, nil
	if hud.inOpening then
		expedition:hide()
		hud:aimAt(nil)
		minerFocus:update(false)
		return
	end
	local camera = workspace.CurrentCamera
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not head or not root or not camera or not humanoid or humanoid.Health <= 0 then
		minerFocus:update(false)
		expedition:hide()
		hud:aimAt(nil)
		release()
		fx:aim(nil)
		return
	end
	local localPos = root.Position - origin
	local inMine = Config.inMine(localPos)
	local depth = math.max(0, -Config.blockCoordinates(localPos).Y)
	local region = if inMine then Config.layer(Config.FloorY - localPos.Y).name else Config.SurfaceName
	if lastRegion ~= region or lastDepth ~= depth then
		lastRegion, lastDepth = region, depth
		hud.depth.Text = if not inMine
			then "Surface"
			elseif depth == 0 then "Mine entrance"
			elseif depth == 1 then "1 block deep"
			else depth .. " blocks deep"
		hud.layer.Text = string.upper(region)
	end
	hud.surface.Visible = not passage.active and Config.inMine(localPos) and (root.Position - entrance).Magnitude > 7
	if hud.overlay.Visible or passage.active then
		minerFocus:update(inMine, nil, camera.CFrame.Position, params)
		expedition:hide()
		hud:aimAt(nil)
		local station = if hud.menu.page == "Gear"
			then "Shop"
			elseif hud.menu.page == "Sell" or hud.menu.page == "Store" or hud.menu.page == "Supplies" then hud.menu.page
			else nil
		if station then
			local pos = net:GetAttribute(station .. "Position")
			if not pos or (root.Position - pos).Magnitude > net:GetAttribute(station .. "Range") then
				hud:setShop(false)
			end
		end
		fx:aim(nil)
		return
	end
	local ready = net:GetAttribute("Ready") and player:GetAttribute("ProfileReady")
	local centerAim = mobile or UIS.PreferredInput == Enum.PreferredInput.Gamepad
	local screen = if centerAim then camera.ViewportSize * 0.5 else UIS:GetMouseLocation()
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local reach = char:GetAttribute("PickReach") or Config.Reach
	local hit = workspace:Raycast(ray.Origin, ray.Direction * (if inMine then math.max(reach + 48, minerFocus.range) else reach + 48), params)
	local onControl = GuiService.MenuIsOpen or UIS:GetFocusedTextBox() or (hud.chatInput and hud.chatInput.IsFocused)
		or (not centerAim and hit ~= nil and hud:pointerOnControl(screen))
	if onControl then hit = nil end
	minerFocus:update(inMine, hit, ray.Origin, params)
	local cap = (player:GetAttribute("PackSlots") or Upgrades.items.Capacity.values[1])
	local space = cap - (player:GetAttribute("Used") or 0)
	if hud.touchActions.enabled and (space <= 0 or not ready) then
		release()
	end
	local power = Upgrades.items.Power.values[player:GetAttribute("Power") or 1]
	local center, normal, cells, locked, required
	if ready and hit and hit.Instance.Parent and hit.Instance.Parent:HasTag(Config.MineBlockTag) then
		normal = hit.Normal
		center = Config.blockCenter(origin, hit.Position, normal)
		local anchorPart = Pattern.reachablePart(head.Position, center, normal, params, reach)
		if anchorPart and anchorPart.Parent:HasTag(Config.MineBlockTag) then
			local ore = Ores.byName[anchorPart.Name]
			cells, locked, required = Pattern.select(origin, center, ore, power, space)
		end
	end
	fx:aim(cells)
	local valid = cells ~= nil and #cells == 1
	hud:aimAt(screen, valid, locked ~= nil or (cells ~= nil and space <= 0))
	hud.reticle.Visible = centerAim and not hud.cursor.Visible
	if centerAim then
		hud.reticle.BackgroundColor3 = if valid then W.aqua else W.white
	end
	local objective, instruction
	if ready and not joinOpeningPending and player:GetAttribute("IntroSeen") then
		objective, instruction = expedition:update(head, inMine, depth, mobile, space <= 0, if valid then hit.Instance else nil)
	else
		expedition:hide()
	end
	if not ready then
		hud:guide("Opening the mine…", "Preparing your pack and the mine", true)
	elseif objective then
		hud:guide(objective, instruction, not expedition.spotlight.layer.Visible)
	elseif space <= 0 then
		hud:guide(
			"Backpack full",
			instruction or (if inMine then "Use ↑ Surface, then visit Sell" else "Visit the amber Sell counter"),
			true
		)
	elseif not valid and locked then
		hud:guide(targetName(locked, center) .. " needs Power " .. required, "Upgrade Power at the workshop", true)
	elseif valid then
		local ore = Ores.byName[hit.Instance.Name]
		local worth = if ore.secret and not player:GetAttribute("Found" .. ore.name)
			then "???"
			else W.possiblePrice(ore, player)
		local stats = "Hardness " .. Config.strength(center.Y - origin.Y) .. "  ·  " .. worth
		hud:guide("Mine " .. string.lower(targetName(ore, center)), instruction or (if mobile then stats else "Hold to mine  ·  " .. stats), true)
	else
		hud:guide("", "", false)
	end
	if valid then
		aimPoint, aimSide, aimOre = center, normal, Ores.byName[hit.Instance.Name]
		aimPart = hit.Instance
		aimFacePoint = hit.Position + normal * 0.45
	end
end

UIS.TouchTapInWorld:Connect(function(screen, processed)
	if processed or not mobile or hud.inOpening or hud.overlay.Visible or passage.active or not minerFocus.underground then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * minerFocus.range, params)
	if hit then minerFocus:tap(hit.Instance) end
end)

local elapsed = 1
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	local sampled = elapsed >= 1 / 30
	if sampled then
		elapsed %= 1 / 30
		sampleAim()
	end
	expedition:draw()
	if
		(not held and not hud.touchActions.enabled)
		or not aimPoint
		or not aimPart.Parent
		or hud.overlay.Visible
		or passage.active
	then
		if strokeStart or (rig and rig.playing) then
			cancelStroke()
		end
		return
	end
	local now = os.clock()
	if finishedCell == aimPoint and now < retryAt then
		if swinging then
			cancelStroke()
		end
		return
	end
	local starting = not swinging or aimPoint ~= target
	if starting then
		if strokeStart and target ~= aimPoint then
			fx:clearDamage()
		end
		target, targetSide, strokeStart = aimPoint, aimSide, now
		net.Swing:FireServer(true, target, targetSide)
		swinging = true
	end
	if starting or sampled then
		if owned.Focus then
			local tint = if owned.Longbeam and not aimOre.host and player:GetAttribute("Found" .. aimOre.name)
				then aimOre.color:Lerp(Color3.new(1, 1, 1), 0.35)
				else Color3.fromRGB(255, 225, 169)
			fx:setMiningLight(aimFacePoint, Skills.bonus(owned, "focus"), tint)
		else
			fx:setMiningLight(nil)
		end
	end
	local duration = Skills.cutTime(
		Upgrades.items.Speed.values[player:GetAttribute("Speed") or 1],
		aimOre,
		Config.strength(target.Y - origin.Y),
		player:GetAttribute("TemperCharges"),
		owned,
		player:GetAttribute("HasteCuts"),
		player:GetAttribute("StoneChips"),
		Upgrades.items.Power.values[player:GetAttribute("Power") or 1]
	)
	if rig and not rig.shoulder:IsDescendantOf(workspace) then
		rig:destroy()
		rig = nil
	end
	rig = rig or Swing.new(player.Character)
	if rig then
		rig.target, rig.ore = aimPoint, aimOre.name
	end
	if rig and (not rig.playing or rig.duration ~= duration) then
		rig:play(duration)
	end
	local progress = math.clamp((now - strokeStart) / duration, 0, 1)
	hud.speech.Visible, hud.meter.Visible = true, true
	hud.swingFill.Size = UDim2.fromScale(progress, 1)
	hud.cursorPick.Rotation = -14 + 23 * math.sin(progress * math.pi * 6)
	hud.cursorEdge.Color = W.gold
	fx:damage(aimPart, progress)
	if progress == 1 then
		if rig then
			rig:stop()
		end
		net.Mine:FireServer(target, aimSide, 1, 1)
		finishedCell, retryAt = target, now + 0.5
		fx:setMiningLight(nil)
		hud.meter.Visible = false
		swinging = false
		strokeStart = nil
	end
end)

hud.root.Parent:SetAttribute("ControllerReady", true)
local Opening = require(script.Starfall)
local function playOpening()
	if hud.inOpening or passage.active then return end
	release()
	fx:aim(nil)
	hud:aimAt(nil)
	hud:setShop(false)
	restoreSurfaceLight()
	Opening.play(player, net, hud)
	return true
end
hud.menu.replayOpening = function()
	if playOpening() then Audio.startHarborMusic() end
end
task.spawn(function()
	repeat
		repeat task.wait(.1) until player:GetAttribute("ProfileReady") and net:GetAttribute("Ready")
			and player.Character and player.Character:GetAttribute("MiningViewReady")
		local character = player.Character
		playOpening()
		if player.Character == character and character:IsDescendantOf(workspace) then
			joinOpeningPending = false
			Audio.startHarborMusic()
			return
		end
	until not player.Parent
end)
