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
		"StoreConfig",
		"Collectibles",
		"Geodes",
		"Bonuses",
		"Skills",
		"FieldGuide",
	}
do
	shared:WaitForChild(name)
end
local Config, Ores, Upgrades = require(shared.GameConfig), require(shared.Ores), require(shared.Upgrades)
local Skills = require(shared.Skills)
local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
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

local reveal = require(script.GeodeReveal).new(hud, net)
hud.checkout = require(script.Checkout).new(hud, net, reveal)
require(script.ShopSign)(hud)
hud.reveal = reveal
local Collectibles = require(shared.Collectibles)
local function chime(pitch) fx:chime(pitch) end
net.Feedback.OnClientEvent:Connect(function(kind, a, point, spread, finds, normal)
	-- A refusal right after asking to buy ends the checkout's waiting screen.
	if kind == "hint" then hud.checkout:refused() end
	if kind == "achievement" or kind == "titleUnlocked" or kind == "levelUp" then
		hud.unlocks:show(kind, a)
	elseif kind == "skillLearned" then
		fx:chime(1.32)
		if hud.menu.map then
			hud.menu.map:showPurchase(a)
		end
		local skill = Skills.byId[a]
		if skill then hud.unlocks:show("skill", skill.name, skill.detail, skill.icon) end
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
		-- The XP attribute can land just after the loot.
		task.delay(0.06, function()
			hud:showXP(point)
		end)
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
			if point then "Drake egg cracked: a Starfall Crate!" else "Survey cache found",
			"+" .. a .. " G" .. (if point then "   ·   open the crate from your Inventory" else ""),
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
		hud:announceStarfall(a)
	elseif kind == "depart" then
		release()
		passage:depart(a, point)
	elseif kind == "arrive" then
		passage:arrive(a)
	elseif kind == "sale" then
		if a > 0 then
			fx:chime(1.45)
			receipt:show(a, point, spread, finds)
			hud.soldAt = os.clock()
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
	elseif kind == "reward" then
		fx:chime(1.8)
		if hud.overlay.Visible and hud.menu.rewards then
			hud.menu.rewards:claimed(a, point)
		end
		if not hud.overlay.Visible then hud:notice(spread, finds, W.gold) end
	elseif kind == "job" then
		fx:chime(1.65)
		hud.unlocks:show("job", a, "+" .. W.number(point) .. " gold", nil, point)
	elseif kind == "resetSoon" then
		hud:milestone("MINE RENEWAL", "New ore in " .. a .. " seconds", W.aqua)
		hud:notice("Mine renews in " .. a .. " seconds", "Deep miners go straight back to their spot", W.aqua)
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
	elseif kind == "rebirth" then
		hud.menu.rebirthPending = nil
		if a then
			release()
			fx:clearOreLights()
			fx:chime(1.8)
			hud:setShop(false)
			task.spawn(function()
				-- The scene shows the new bonuses. Without it (motion off), the plaque does.
				if not require(script.RebirthCutscene).play(player, hud, point) then
					hud.unlocks:show("rebirth", "Rebirth " .. point, Rebirth.perks[1].text(point) .. "  ·  " .. Rebirth.perks[2].text(point))
				end
				hud:notice("A new run begins!", "Your bonuses are permanent", W.rebirth)
			end)
		elseif hud.overlay.Visible and hud.menu.page == "Rebirth" then
			hud.menu.rebirth:message(point)
		else
			hud:notice(point, "", W.gold)
		end
	elseif kind == "friend" then
		if hud.overlay.Visible and hud.menu.page == "Friends" then
			hud.menu.profile:say(a)
		else
			hud:notice(a, "", W.gold)
		end
	elseif kind == "rebirthAnnounce" then
		hud:milestone("REBIRTH " .. point, a .. " was reborn!", W.rebirth)
	elseif kind == "geode" then
		-- a = geode, point = reward kind, spread = reward id, finds = count, normal = what happened
		reveal:play(a, point, spread, finds, normal, chime)
		hud.menu:refresh()
	elseif kind == "goldPack" then
		-- a = gold, point = the pack's name. A pack bought from the Shop shows its gold in the thank-you.
		fx:chime(1.8)
		if hud.checkout:expecting() then
			hud.checkout:gold(a)
		else
			hud.unlocks:show("upgrade", point, "+" .. W.goldAmount(a) .. " gold")
		end
	elseif kind == "itemUsed" then
		fx:chime(1.4)
		local item = Collectibles.itemById[a]
		if item then hud:notice(item.name .. " used", item.detail, W.green) end
	elseif kind == "purchase" then
		-- a = name, point = "pass" or "product", spread = its key
		fx:chime(1.8)
		hud.checkout:purchased(a, point, spread)
	elseif kind == "lucky" then
		-- a = what the block looked like, point = the rare ore inside, spread = luck
		fx:chime(1.85)
		local ore = Ores.byName[point]
		hud:notice("Lucky find! " .. point .. " inside the " .. a, string.format("%g× luck", math.floor(spread * 100 + 0.5) / 100), ore and ore.color or W.green)
	elseif kind == "trailEnd" then
		-- a = what the block looked like: the end of the Starfall's trail (Rebirth.trail).
		fx:chime(1.85)
		hud:notice("The trail ends here! A Starfall inside the " .. a, "You can rebirth now", Ores.byName.Starfall.color)
	elseif kind == "freeGeode" then
		local item = Collectibles.itemById[a]
		fx:chime(1.75)
		hud:notice("Free " .. (if item then item.name else "crate") .. "!", "Open it from your Inventory", W.violet)
	elseif kind == "serverLuck" then
		fx:chime(1.9)
		hud:milestone("SERVER LUCK", a .. " gave everyone 2× luck!", W.green)
		hud:chatLine("🍀 " .. a .. " turned on Server Luck!", "Everyone here has 2× luck for " .. point .. " minutes.", W.green)
	elseif kind == "geodeAnnounce" then
		local rarity = Collectibles.rarities[spread]
		hud:chatLine("◆ " .. a .. " opened a " .. spread .. " " .. point .. "!", "", rarity and rarity.color or W.gold)
	elseif kind == "upgrade" then
		fx:chime(1.55)
		hud:workshop(point, spread)
		if hud.overlay.Visible then hud.menu.status.Text = a end
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
require(script.CourtBoards).start(player, hud)
hud.friendMarkers = require(script.FriendMarkers)(player, hud)

Players.PlayerAdded:Connect(Swing.observe)
for _, other in Players:GetPlayers() do
	if other ~= player then
		Swing.observe(other)
	end
end

require(script.OreCompass)(hud, origin)
require(script.FirstPersonPick)(player)
require(script.BoostChips)(hud)
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
	local screen, ray
	if centerAim then
		-- Aim exactly through the aim dot: the middle of its full-screen layer, in that layer's own
		-- coordinates (where the dot, the mining cursor and its label are drawn) and on screen for the
		-- ray. Using the camera's viewport centre instead could sit off the dot on screens with insets.
		local layer = hud.reticle.Parent
		screen = layer.AbsoluteSize * 0.5
		local at = layer.AbsolutePosition + screen
		ray = camera:ScreenPointToRay(at.X, at.Y)
	else
		screen = UIS:GetMouseLocation()
		ray = camera:ViewportPointToRay(screen.X, screen.Y)
	end
	local reach = char:GetAttribute("PickReach") or Config.Reach
	local hit = workspace:Raycast(ray.Origin, ray.Direction * (if inMine then math.max(reach + 48, minerFocus.range) else reach + 48), params)
	local onControl = GuiService.MenuIsOpen or UIS:GetFocusedTextBox() or (hud.chatInput and hud.chatInput.IsFocused)
		or (not centerAim and hit ~= nil and hud:pointerOnControl(screen))
	if onControl then hit = nil end
	minerFocus:update(inMine, hit, ray.Origin, params)
	local cap = (player:GetAttribute("PackSlots") or Upgrades.items.Capacity.values[1])
	local space = cap - (player:GetAttribute("Used") or 0)
	if hud.touchActions.enabled and (space <= 0 or not ready) then
		if held and space <= 0 and ready then
			hud:cantMine(true)
		end
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
			cells, locked, required = Pattern.select(origin, center, ore, power, space, anchorPart:GetAttribute("Practice") == true)
		end
	end
	fx:aim(cells)
	local valid = cells ~= nil and #cells == 1
	hud:aimAt(screen, valid, locked ~= nil or (cells ~= nil and space <= 0))
	local packed = cells ~= nil and space <= 0
	local tooHard = not valid and not packed and locked ~= nil
	if held and (packed or tooHard) then
		hud:cantMine(packed)
	end
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
		local status = player:GetAttribute("SaveStatus")
		hud:guide("Opening the mine…", if type(status) == "string" and status:find("^Waiting") then status .. " (up to 3 minutes)"
			else "Preparing your pack and the mine", true)
	elseif packed then
		hud:guide("Backpack full!", if mobile then "Tap ↑ Surface, then sell your haul" else "Press R to surface, then sell your haul", true, true)
	elseif tooHard then
		hud:guide("Needs Power " .. required .. "!", targetName(locked, center) .. " is too hard. Upgrade at the workshop", true, true)
	elseif objective then
		hud:guide(objective, instruction, not expedition.spotlight.layer.Visible)
	elseif space <= 0 then
		hud:guide("Backpack full!", if inMine then "Use ↑ Surface, then visit Sell" else "Visit the amber Sell counter", true)
	elseif valid then
		local ore = Ores.byName[hit.Instance.Name]
		local worth = if ore.secret and not player:GetAttribute("Found" .. ore.name)
			then "???"
			else W.colored(W.possiblePrice(ore, player), W.gold)
		hud:guide("Mine " .. string.lower(targetName(ore, center)), instruction or (if mobile then worth else "Hold to mine  ·  " .. worth), true)
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

require(script.AutoRewards).start(player, hud, function(kind)
	if joinOpeningPending or hud.inOpening then return true end
	return kind ~= "opening" and (passage.active or held ~= nil or hud.touchActions.enabled)
end, function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and Config.inMine(root.Position - origin)
end)

local function busy()
	return joinOpeningPending or hud.inOpening or passage.active or held ~= nil or hud.touchActions.enabled
end
require(script.SkillGuide).start(player, hud, busy)
require(script.RebirthGuide).start(player, hud, busy)
require(script.InviteHint).start(player, hud, function()
	return swinging
end)
game:GetService("TeleportService").TeleportInitFailed:Connect(function(who)
	if who ~= player then return end
	if hud.overlay.Visible and hud.menu.page == "Friends" then
		hud.menu.profile:say("Your friend's server could not be joined.")
	else
		hud:notice("Your friend's server could not be joined", "It may be full", W.gold)
	end
end)

local elapsed = 1
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	local sampled = elapsed >= 1 / 30
	if sampled then
		elapsed %= 1 / 30
		sampleAim()
	end
	expedition:draw(dt)
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
		Upgrades.items.Speed.values[player:GetAttribute("Speed") or 1]
			* Rebirth.cutMultiplier(player:GetAttribute("Rebirths") or 0),
		aimOre,
		Config.strength(target.Y - origin.Y),
		player:GetAttribute("TemperCharges"),
		owned,
		player:GetAttribute("HasteCuts"),
		player:GetAttribute("StoneChips"),
		Upgrades.items.Power.values[player:GetAttribute("Power") or 1]
	)
	-- Fast Pick and Haste Tonic: the same speed the server uses.
	duration = require(shared.Bonuses).cut(require(shared.Bonuses).state(player), duration)
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

-- Only your own mining lamp casts shadows. The server sends every lamp without them, so a busy
-- server doesn't ask a low-end device for a shadow-casting light per miner.
local function ownLamp(character)
	local root = character:WaitForChild("HumanoidRootPart", 30)
	local mount = root and root:WaitForChild("Lamp mount", 30)
	local lamp = mount and mount:WaitForChild("Mining lamp", 30)
	if lamp then lamp.Shadows = true end
end
player.CharacterAdded:Connect(function(character) task.spawn(ownLamp, character) end)
if player.Character then task.spawn(ownLamp, player.Character) end
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
		-- The film plays on a miner's first visit only. Settings can replay it any time.
		if player:GetAttribute("IntroSeen") then
			joinOpeningPending = false
			Audio.startHarborMusic()
			return
		end
		playOpening()
		if player.Character == character and character:IsDescendantOf(workspace) then
			joinOpeningPending = false
			Audio.startHarborMusic()
			return
		end
	until not player.Parent
end)
