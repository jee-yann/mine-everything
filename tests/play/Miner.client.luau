local rep = game:GetService("ReplicatedStorage")
local p = game.Players.LocalPlayer
local r = rep:WaitForChild("MiningTestReport")
local function waitFor(check, seconds, msg)
	local start = os.clock()
	repeat
		local result = check()
		if result then
			return result
		end
		task.wait(0.08)
	until os.clock() - start > seconds
	error(msg)
end
local function equippedKit()
	return p.Character and p.Character:FindFirstChild("Prospector kit", true)
end
local function expectGuideArrow(button)
	local marker = waitFor(function()
		local mark = button:FindFirstChild("Guide highlight")
		return mark and mark.Visible and mark:FindFirstChild("Guide arrow") and mark
	end, 3, "onboarding arrow on " .. button.Name)
	assert(button.Interactable and not marker.Active, "onboarding blocked its own action")
end
-- The art on an ore block's open faces, one item per face: its drawn faces (each also carries a
-- raised-pieces model), or relief models when drawings are unavailable.
local function faceArt(block)
	local drawn, relief = {}, {}
	for _, child in block:GetChildren() do
		if child:IsA("Decal") and child.Name == block.Name .. " face" then
			table.insert(drawn, child)
		elseif child:IsA("Model") and child.Name ~= block.Name .. " raised" then
			table.insert(relief, child)
		end
	end
	return if #drawn > 0 then drawn else relief
end
local function checkOreFaces()
	local folder = Instance.new("Folder")
	folder:AddTag(require(rep.Shared.GameConfig).MineBlockTag)
	folder.Parent = workspace
	local blocks = {}
	local view = workspace.CurrentCamera.CFrame
	for i = 0, 63 do
		local block = Instance.new("Part")
		block.Name, block.Anchored, block.Size = "Iron", true, Vector3.one * 6
		block.CanCollide, block.CanTouch, block.CanQuery = false, false, false
		block.Position = view * Vector3.new((i % 8 - 3.5) * 6, (math.floor(i / 8) % 4 - 1.5) * 6, if i < 32 then -28 else -90)
		block:SetAttribute("OpenFaces", 1)
		block.Parent = folder
		table.insert(blocks, block)
	end
	waitFor(function()
		for _, block in blocks do
			if #faceArt(block) == 0 then return false end
		end
		return true
	end, 3, "nearby and distant ore faces all have their texture in a crowded cave")
	local block = blocks[1]
	local first = faceArt(block)[1]
	block:SetAttribute("OpenFaces", 3)
	waitFor(function() return #faceArt(block) == 2 end, 2, "newly exposed ore face receives art")
	assert(first.Parent == block)
	block:SetAttribute("OpenFaces", 2)
	waitFor(function() return not first.Parent and #faceArt(block) == 1 end, 2, "sealed face loses its art")
	block.Parent = nil
	waitFor(function() return #block:GetChildren() == 0 end, 2, "streamed-out block releases its art")
	block.Parent = folder
	waitFor(function() return #faceArt(block) > 0 end, 2, "restreamed ore receives art")
	folder:Destroy()
end
local function test()
	assert(not p.PlayerGui:FindFirstChild("MiningLoading"), "custom loading screen removed")
	local n = rep:WaitForChild("EndlessMiningNet", 25)
	assert(n, "server bootstrap")
	waitFor(function()
		return n:GetAttribute("Ready")
			and p:GetAttribute("ProfileReady")
			and p.Character
			and p.Character:FindFirstChild("Head")
	end, 30, "profile/world readiness")
	local gui = p.PlayerGui:WaitForChild("MiningHUD", 10)
	assert(gui and gui.SafeArea:FindFirstChild("ShopOverlay"), "HUD did not mount")
	waitFor(function()
		return workspace:FindFirstChild("MiningSelection")
	end, 8, "aim controller did not start")
	assert(p:GetAttribute("SaveStatus") == "Practice session", "local data scope")
	waitFor(function()
		return p.Character:FindFirstChild("Harbor pick")
	end, 8, "equipped pickaxe")
	local kit = waitFor(equippedKit, 8, "starter equipment")
	assert(kit and kit["Miner title"].TextLabel.Text:find("Noob Miner", 1, true), "starter backpack and title")
	local packSize = kit["Field pack"].Size
	local harbor = game.SoundService:WaitForChild("Harbor audio", 8)
	local song = harbor:WaitForChild("Prima Bossa Nova", 5)
	assert(not song.IsPlaying and song.Volume < 0.1, "test music must stay muted")
	waitFor(function()
		return gui:GetAttribute("ControllerReady") and not p.PlayerGui:FindFirstChild("MiningLoading")
	end, 18, "controller starts without a loading screen")
	assert(not p.Character.HumanoidRootPart.Anchored, "free to move at spawn")
	do
		local returning = not r:GetAttribute("CheckSwing") and p.UserId % 2 == 0
		assert(p:GetAttribute("IntroSeen") == returning, "the join loaded the expected viewing history")
		local opening = p.PlayerGui:WaitForChild("Mine origins", 6)
		local top = opening:WaitForChild("Top matte", 2)
		local bottom = opening:WaitForChild("Bottom matte", 2)
		assert(top.Size == bottom.Size and top.Size.Y.Scale >= 0.04 and top.Size.Y.Scale <= 0.09)
		assert(top.BackgroundColor3 == Color3.new() and bottom.AnchorPoint.Y == 1 and bottom.Position.Y.Scale == 1)
		local titles = p.PlayerGui:WaitForChild("Mine subtitles", 2)
		assert(opening and titles and titles.Skip and not gui.SafeArea.Visible, "automatic skippable film on join")
		local camera = workspace.CurrentCamera
		local stage = camera:WaitForChild("Mine origins set", 4)
		local resonance = opening:WaitForChild("Star harmonics", 4)
		local acousticRig = camera:WaitForChild("Cinematic sound sources", 4)
		assert(stage and camera.CameraType == Enum.CameraType.Scriptable)
		assert(
			resonance.SoundGroup == song.SoundGroup
				and resonance.SoundId == "rbxasset://sounds/volume_slider.ogg"
		)
		assert(not song.IsPlaying and resonance:FindFirstChildOfClass("ReverbSoundEffect"))
		local effects = game.SoundService["Starfall effects"]
		local gameplayEffects = game.SoundService["Harbor effects"]
		assert(gameplayEffects.Volume == 0 and math.abs(effects.Volume - p:GetAttribute("SfxVolume") / 100) < 0.001,
			"only film effects should be audible at the viewer's effects level")
		assert(opening["Residual ringing"].SoundGroup == effects and opening.Eruption.SoundGroup == effects)
		assert(acousticRig.outbound["Ablation flypast"].SoundGroup == effects)
		assert(acousticRig.inbound["Shale through the air"].SoundGroup == effects)
		assert(acousticRig.inbound["Debris at the lens"].SoundGroup == effects)
		assert(acousticRig.left["Resonance in the crystal"].SoundGroup == effects)
		assert(opening["Iron pick at the working mine"].SoundGroup == effects)
		if r:GetAttribute("CheckSwing") then
			local mix = song.SoundGroup.Volume
			song.SoundGroup.Volume = 0
			rep:SetAttribute("MuteTestMusic", false)
			local harborStarts = 0
			local trackStarts = song.Played:Connect(function() harborStarts += 1 end)
			local firstCharacter = p.Character
			r:FireServer("respawnOpening")
			waitFor(function()
				return not opening.Parent and not stage.Parent and not acousticRig.Parent and p.Character and p.Character ~= firstCharacter
			end, 14, "respawn releases the interrupted film")
			opening = p.PlayerGui:WaitForChild("Mine origins", 12)
			titles = p.PlayerGui:WaitForChild("Mine subtitles", 3)
			camera = workspace.CurrentCamera
			stage = camera:WaitForChild("Mine origins set", 4)
			assert(opening and opening:WaitForChild("Landfall", 4) and titles.Skip and not p:GetAttribute("IntroSeen"))
			kit = waitFor(equippedKit, 8, "replacement miner equipment")
			assert(harborStarts == 0 and not song.IsPlaying, "harbor music interrupted the replacement screening")
			-- During a respawn the Scriptable camera can retain the retired Humanoid.
			local retired = Instance.new("Model")
			local subject = Instance.new("Humanoid")
			retired.Parent, subject.Parent = workspace, retired
			camera.CameraSubject = subject
			retired.Parent = nil
			assert(camera.CameraSubject == subject, "retired camera subject fixture")
			local input = game.UserInputService:CreateVirtualInput()
			input:SendKey(true, Enum.KeyCode.Return)
			task.wait(0.08)
			input:SendKey(false, Enum.KeyCode.Return)
			waitFor(function()
				return not opening.Parent
			end, 2, "skip immediately")
			assert(camera.CameraSubject == p.Character.Humanoid, "skip restored the playable avatar as camera subject")
			retired:Destroy()
			waitFor(function()
				return song.IsPlaying and song.Volume > 0.06
			end, 3, "music fades up after skip")
			assert(harborStarts == 1 and song.SoundGroup.Volume == 0, "Skip handed music over exactly once")
			trackStarts:Disconnect()
			rep:SetAttribute("MuteTestMusic", true)
			song:Stop()
			song.SoundGroup.Volume = mix
		elseif returning then
			-- The returning miner skips while the first-time miner keeps watching.
			local peer
			waitFor(function()
				for _, miner in game.Players:GetPlayers() do
					if miner ~= p then peer = miner end
				end
				return peer and peer:GetAttribute("ProfileReady")
			end, 20, "the other first-time miner joined")
			local peerHead = waitFor(function()
				local head = peer.Character and peer.Character:FindFirstChild("Head")
				return head and head.LocalTransparencyModifier == 1 and head
			end, 4, "the other miner is hidden from the first scene")
			local badge = Instance.new("BillboardGui")
			badge.Parent = peerHead
			waitFor(function() return not badge.Enabled end, 2, "a late-streamed badge stays out of the film")
			local input = game.UserInputService:CreateVirtualInput()
			input:SendKey(true, Enum.KeyCode.Return)
			task.wait(0.08)
			input:SendKey(false, Enum.KeyCode.Return)
			waitFor(function()
				return not opening.Parent and not stage.Parent and p:GetAttribute("IntroSeen") and gui.SafeArea.Visible
			end, 4, "one viewer can return to play independently")
			assert(not peer:GetAttribute("IntroSeen"), "skipping marked the other miner as finished")
			assert(peerHead.LocalTransparencyModifier < 1 and badge.Enabled, "Skip restores the other miner and their gear")
			badge:Destroy()
			local previousCharacter = p.Character
			local reopened = false
			local watch = p.PlayerGui.ChildAdded:Connect(function(child)
				if child.Name == "Mine origins" then reopened = true end
			end)
			r:FireServer("respawnAfterOpening")
			waitFor(function()
				return p.Character and p.Character ~= previousCharacter and p.Character:GetAttribute("MiningViewReady")
			end, 14, "completed viewer respawned with the gameplay camera ready")
			kit = waitFor(equippedKit, 8, "replacement miner equipment")
			task.wait(1)
			watch:Disconnect()
			assert(not reopened and gui.SafeArea.Visible and workspace.CurrentCamera.CameraType == Enum.CameraType.Custom,
				"a normal respawn after Skip should stay in gameplay")
			waitFor(function() return peer:GetAttribute("IntroSeen") end, 83, "the other miner finishes their film")
		else
			local spawnAt = p.Character.HumanoidRootPart.Position
			local orchestraStarts, fallbackNotes = 0, 0
			opening["Rising Hope underscore"].Played:Connect(function() orchestraStarts += 1 end)
			for _, voice in opening:GetChildren() do
				if voice.Name == "Expedition horns" or voice.Name == "Ostinato bass" then
					voice.Played:Connect(function() fallbackNotes += 1 end)
				end
			end
			local landed, eruption, breaker, fire, rock, collapse, bow, debris
			local seamHeard, modernPick
			acousticRig.left["Resonance in the crystal"].Played:Once(function() seamHeard = os.clock() end)
			opening["Iron pick at the working mine"].Played:Once(function() modernPick = os.clock() end)
			opening.Landfall.Played:Once(function() landed = os.clock() end)
			opening["Collapsing crater wall"].Played:Once(function() collapse = os.clock() end)
			opening.Eruption.Played:Once(function() eruption = os.clock() end)
			acousticRig.inbound["Shockwave arrival"].Played:Once(function() breaker = os.clock() end)
			acousticRig.inbound["Shockwave bow"].Played:Once(function() bow = os.clock() end)
			acousticRig.inbound["Debris at the lens"].Played:Once(function() debris = os.clock() end)
			acousticRig.right["Fire in the fissure"].Played:Once(function() fire = os.clock() end)
			acousticRig.left["Slumping basalt"].Played:Once(function() rock = os.clock() end)
			waitFor(function()
				return opening["Atmospheric entry"].IsPlaying or landed or eruption or breaker
			end, 30, "the film clock starts after native scene construction")
			waitFor(function() return landed end, 13, "Landfall attack on frame 240")
			waitFor(function() return eruption end, 2, "Eruption attack on frame 243")
			waitFor(function() return collapse end, 2, "crater wall collapses after ignition")
			waitFor(function() return breaker end, 5, "shockwave arrives on frame 324")
			waitFor(function() return bow end, 1, "directional bow plays with the shockwave")
			assert(collapse >= landed and collapse - landed < 0.45 and opening["Collapsing crater wall"].IsPlaying, "crumbling rock carries the blast to the coast")
			assert(eruption - landed > 0.045 and eruption - landed < 0.23, "ignition follows contact by three film frames")
			waitFor(function() return debris end, 1, "debris lands after the passing wave")
			assert(math.abs(debris - bow - 3 / 24) < 0.13 and math.abs(bow - breaker - 0.14) < 0.14,
				"the quieter debris report follows the wave edge")
			assert(bow - landed > 3.2 and bow - landed < 3.8, "the front reaches the fixed lens 84 film frames after impact")
			waitFor(function() return fire and rock end, 7, "fire and settling debris sustain the burned basin")
			assert(rock > breaker and fire > breaker, "the close aftermath follows the pressure wave")
			waitFor(function()
				return titles.Caption.Text:find("the star took root", 1, true)
			end, 10, "the crane finds the star")
			waitFor(function()
				return titles.Caption.Text == "Millions of years later"
			end, 7, "the island today")
			waitFor(function() return stage:FindFirstChild("Cinematic miner") end, 16, "the dressed performer")
			local actor
			waitFor(function()
				for _, model in stage:GetChildren() do
					if model.Name == "Cinematic miner" and model:FindFirstChild("Harbor pick") then actor = model end
				end
				return actor
			end, 22, "the player walks in with their own pick")
			assert(actor.Head.Anchored and p.Character.Head.Transparency == 1)
			assert(not actor:FindFirstChildWhichIsA("Animator", true), "gameplay animation entered the shot")
			for _, body in actor:GetDescendants() do
				if body:IsA("BasePart") then assert(not body.CanCollide, "the performance rig can push the real miner") end
			end
			local strike = titles:WaitForChild("Strike sample", 2)
			waitFor(function() return strike.Visible end, 16, "strike control opens")
			local struck
			opening["Body of the break"].Played:Connect(function() struck = struck or os.clock() end)
			struck = nil
			local tappedAt = os.clock()
			local input = game.UserInputService:CreateVirtualInput()
			input:SendKey(true, Enum.KeyCode.Space)
			task.wait(0.06)
			input:SendKey(false, Enum.KeyCode.Space)
			waitFor(function() return strike.Visible and not strike.Interactable end, 0.4, "control shows the accepted press")
			waitFor(function() return struck end, 1.9, "input causes the break")
			assert(struck - tappedAt < 1.35, "the swing waited for the automatic beat")
			local card = titles:WaitForChild("Player introduction", 2)
			waitFor(function() return card.Visible and stage:FindFirstChild("Glass stage") end, 5, "the glass reveal")
			local named = false
			for _, label in card:GetDescendants() do
				named = named or (label:IsA("TextLabel") and label.Text == p.DisplayName)
			end
			assert(named, "the reveal carries the player's own name")
			waitFor(function() return titles["Closing line"].Visible end, 8, "the goal")
			assert((orchestraStarts == 1 and fallbackNotes == 0) or (orchestraStarts == 0 and fallbackNotes > 0),
				"the screening keeps one score")
			local sheet = require(p.PlayerScripts.Client.Starfall.ExposureSheet)
			local ironAfterLandfall = (sheet.frames.firstHit - sheet.frames.contact) / sheet.fps
			assert(seamHeard and modernPick and seamHeard < modernPick
				and math.abs(modernPick - landed - ironAfterLandfall) < 0.24,
				string.format("first blow: resonance %s, iron %s, expected %.3fs after impact",
					tostring(seamHeard and seamHeard - landed), tostring(modernPick and modernPick - landed), ironAfterLandfall))
			for _, miner in game.Players:GetPlayers() do
				if miner ~= p then
					local head = miner.Character and miner.Character:FindFirstChild("Head")
					assert(head and head.LocalTransparencyModifier == 1, "a respawned miner is still hidden at the live mine")
				end
			end
			assert((p.Character.HumanoidRootPart.Position - spawnAt).Magnitude < 8, "the private film moved the miner")
			assert((spawnAt - n:GetAttribute("Landing")).Magnitude < 22)
		end
		waitFor(function()
			return not opening.Parent
				and not stage.Parent
				and not titles.Parent
				and p:GetAttribute("IntroSeen")
				and gui.SafeArea.Visible
				and workspace.CurrentCamera.CameraType ~= Enum.CameraType.Scriptable
				and not camera:FindFirstChild("Specimen focus")
				and not camera:FindFirstChild("Light through ash")
				and not camera:FindFirstChild("Cinematic sound sources")
		end, 16, "opening returns camera and HUD")
		waitFor(function() return math.abs(gameplayEffects.Volume - effects.Volume) < 0.001 end, 2, "gameplay sound restored after film")
	end
	local ownerVision
	do
		local marker = workspace.Terrain:WaitForChild("First expedition waypoint", 4)
		waitFor(function() return marker.Destination.Enabled end, 4, "mine waypoint after the opening")
		assert(p:GetAttribute("ExpeditionStep") == "Dig" and marker.Destination.TextLabel.Text:find("Mine"))
		assert((marker.WorldPosition - n:GetAttribute("Entrance")).Magnitude < 6)
		if r:GetAttribute("CheckSwing") then
			local guide = require(p.PlayerScripts.Client.FirstExpedition).new(p, n)
			checkOreFaces()
			local eye = p.Character.Head
			local _, touch = guide:objective(eye, true, 0, true, false, "Dig")
			local _, mouse = guide:objective(eye, true, 0, false, false, "Dig")
			assert(touch:find("hold Mine") and mouse:find("mouse button"))
			local sellEye = { Position = n:GetAttribute("SellPosition") + Vector3.yAxis * 4 }
			local _, touchSale = guide:objective(sellEye, false, 0, true, true, "Ore")
			assert(touchSale:find("Tap the prompt") and guide.label.Text:find("Sell"))
			assert(guide.waypoint.glow.Adornee:HasTag("MiningInteractionPad"), "draw attention to the actual Sell pad")
			guide:objective({Position = n:GetAttribute("Entrance")}, false, 0, false, false, "Dig")
			assert(guide.label.Text == "Dig floor", "carry the player through the doorway")
			local floorEye = {Position = n:GetAttribute("DigFloor") + Vector3.yAxis * 5}
			guide:objective(floorEye, true, 0, true, false, "Dig")
			local first = guide.waypoint.glow.Adornee
			assert(first and first.Name == "Dirt" and first.Parent == workspace.CitrineCove.MineBlocks, "guide selects a real diggable floor block")
			local probe = { Position = Vector3.new(3000, 1800, 3000) }
			local coal = Instance.new("Part")
			coal.Name, coal.Anchored, coal.Size = "Coal", true, Vector3.one * 6
			coal.Position, coal.Parent = probe.Position - Vector3.zAxis * 16, workspace.CitrineCove.MineBlocks
			local cover = coal:Clone()
			cover.Name, cover.Position, cover.Parent = "Stone", probe.Position - Vector3.zAxis * 8, coal.Parent
			assert(not guide:visibleOre(probe), "no guidance through a solid stone wall")
			cover:Destroy()
			guide.nextSearch = 0
			assert(guide:visibleOre(probe) == coal, "mark the exposed coal")
			coal:Destroy()
			guide:hide()
			assert(not guide.pin.Enabled and not guide.waypoint.glow.Enabled)
			guide.anchor:Destroy()
		end
	end
	if p.UserId == 45241447 then
		ownerVision = p.PlayerGui:WaitForChild("OwnerOreVision", 3)
		assert(ownerVision and not ownerVision.ResetOnSpawn, "Pixelii receives ore vision")
	else
		assert(not p.PlayerGui:FindFirstChild("OwnerOreVision"), "ore vision granted to another player")
		assert(not gui.SafeArea.Location:FindFirstChild("X-ray controls") and not n:FindFirstChild("Scan", true))
	end
	waitFor(function()
		local mount = p.Character.HumanoidRootPart:FindFirstChild("Lamp mount")
		return mount and mount:FindFirstChildOfClass("PointLight") and p.Character:GetAttribute("MiningViewReady")
	end, 10, "spawn camera and character light")
	local audio = require(p.PlayerScripts.Client.HarborAudio)
	for _, voice in harbor:GetChildren() do
		if voice == song then
			continue
		end
		waitFor(function()
			return voice.IsLoaded
		end, 8, voice.Name .. " failed to load")
	end
	if r:GetAttribute("CheckSwing") then
		local seenIds, digSignatures = {}, {}
		local emitter = Instance.new("Attachment")
		emitter.Parent = workspace.Terrain
		for _, ore in require(rep.Shared.Ores).list do
			audio.dig(ore.name, emitter)
			local signature = ""
			for _, layer in emitter:GetChildren() do
				waitFor(function() return layer.IsLoaded end, 3, ore.name .. " dig sample")
				assert(layer.SoundGroup == harbor["Coal break"].SoundGroup and layer.PlaybackRegion.Min < layer.TimeLength)
				signature ..= layer.SoundId .. tostring(layer.PlaybackRegion)
			end
			assert(emitter:FindFirstChild("Pick impact") and not digSignatures[signature], ore.name .. " dig sound")
			digSignatures[signature] = true
			emitter:ClearAllChildren()
			local voice = harbor[ore.name .. " break"]
			assert(not seenIds[voice.SoundId .. voice.PlaybackSpeed], "duplicate ore sound")
			seenIds[voice.SoundId .. voice.PlaybackSpeed] = true
			local played, notes = false, 0
			local strike = voice.Played:Connect(function()
				played = true
			end)
			local flourishes = {}
			for i = 1, 5 do
				table.insert(
					flourishes,
					harbor["Discovery note " .. i].Played:Connect(function()
						notes += 1
					end)
				)
			end
			audio.ore({ [ore.name] = 1 })
			-- One rising note for a Rare find, one more per rarity step, five for Starfall.
			local Ores = require(rep.Shared.Ores)
			local expected = math.clamp(Ores.rarityRank[ore.rarity] - Ores.rarityRank.Rare + 1, 0, 5)
			waitFor(function()
				return played and notes == expected
			end, 2, ore.name .. " break and reward notes")
			strike:Disconnect()
			for _, signal in flourishes do
				signal:Disconnect()
			end
			-- Let this flourish finish so a lower-ranked ore next in the list is not held back by it.
			task.wait(0.15)
		end
		emitter:Destroy()
	end
	local car = workspace.CitrineCove["Citrine Highlands"]["Moving cabins"]["Ore carrier 1"]
	local start = car:GetPivot().Position
	-- A bucket can be loading at the terminal when this client arrives.
	waitFor(function()
		return (car:GetPivot().Position - start).Magnitude > 0.12
	end, 9, "tram leaves its loading stop")
	local overlay = gui.SafeArea.ShopOverlay
	local menu = overlay["Harbor menu"]
	local map = workspace.CitrineCove
	local counters = {
		Sell = map["Shore market"].Sell["Service mat"],
		Gear = map["Shore market"].Upgrades["Service mat"],
		Store = map["Harbor Plaza"].Store.Counter,
		Book = map["Harbor Plaza"].Book.Counter,
		Samples = map["Field sample bench"]["Catalogue plate"],
		Supplies = map["Harbor Plaza"].Supplies.Counter,
	}
	local function visit(key, activate)
		local pad = counters[key]
		r:FireServer("station", key)
		waitFor(function()
			return (p.Character.HumanoidRootPart.Position - pad.Position).Magnitude < 7
		end, 5, "walk to " .. key)
		if activate then
			task.wait(0.25)
			local service = assert(pad:FindFirstChildOfClass("ProximityPrompt"))
			service:InputHoldBegin()
			task.wait(service.HoldDuration + 0.15)
			service:InputHoldEnd()
		end
	end
	visit("Samples", true)
	waitFor(function() return overlay.Visible and menu.Listings:FindFirstChild("Iron Shelf") end, 5, "consult samples at the physical bench")
	r:FireServer("closePage")
	waitFor(function() return not overlay.Visible end, 5, "leave the sample bench")
	local roster = gui.SafeArea["Server leaderboard"]
	assert(not game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList))
	if game.UserInputService.PreferredInput == Enum.PreferredInput.Touch then
		assert(not roster.Visible and not roster.Miners.Visible, "phone roster starts in Menu")
	else
		local size = gui.SafeArea.AbsoluteSize
		local touchLayout = game.UserInputService.TouchEnabled and math.min(size.X, size.Y) < 640
		assert(roster.Visible == (not touchLayout) and roster.Miners.Visible == (not touchLayout)
			and roster.Columns.Visible == (not touchLayout), string.format("desktop roster initial layout: size %s, touch %s, overlay %s, visible %s/%s/%s", tostring(size), tostring(touchLayout), tostring(overlay.Visible), tostring(roster.Visible), tostring(roster.Miners.Visible), tostring(roster.Columns.Visible)))
	end
	local me = roster.Miners:WaitForChild(tostring(p.UserId), 3)
	assert(me and me.Level.Text == "1" and me.Gold.Text == "0" and me.Title.Text == "Noob Miner")
	local wallet = gui.SafeArea.Wallet
	local controls = gui.SafeArea["Equipment and level"]
	local ring = controls["Level progress"]
	assert(ring:IsA("GuiButton") and ring:FindFirstChild("XP segment"), "interactive XP ring")
	assert(wallet.BackgroundTransparency == 1 and gui.SafeArea.Location.BackgroundTransparency == 1)
	for _, key in { "Power", "Speed", "Capacity" } do
		assert(controls.Equipment[key]:FindFirstChild(key .. " icon"), "equipment icon " .. key)
	end
	assert(gui.SafeArea["Action dock"]:FindFirstChild("Achievements"))
	local safe = gui.SafeArea
	assert(
		safe.Mine.BackgroundTransparency == 1 and not safe:FindFirstChild("Auto mine"),
		"single clear mining control"
	)
	assert(safe.Mine["Mining mode"].Text == "Hold to mine" and safe.Mine["Gesture hint"].Text == "Double-tap for auto")
	local jobButton = safe["Current job"].OpenJob
	assert(jobButton:IsA("GuiButton") and jobButton.BackgroundTransparency == 0, "solid jobs button")
	for _, b in gui:GetDescendants() do
		if b:IsA("TextButton") and b.Text == "×" then
			assert(b.BackgroundColor3.R > b.BackgroundColor3.G * 2, "red close button")
			local gleam = b["Enamel highlight"]
			assert(
				not b.AutoButtonColor and gleam.Size.X.Scale <= 0.4 and gleam.Size.X.Offset == 0,
				"short close highlight"
			)
		end
	end
	local originalSize = safe.Size
	assert(game.StarterGui.ScreenOrientation == Enum.ScreenOrientation.LandscapeSensor
		and p.PlayerGui.ScreenOrientation == Enum.ScreenOrientation.LandscapeSensor, "mobile play stays in landscape")
	local sizes = { Vector2.new(760, 323), Vector2.new(615, 320), Vector2.new(568, 250) }
	if game.UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then
		table.insert(sizes, Vector2.new(320, 615))
	end
	for _, size in sizes do
		safe.Size = UDim2.fromOffset(size.X, size.Y)
		game:GetService("RunService").PreRender:Wait()
		waitFor(function()
			return safe.AbsoluteSize == size and safe["Edge shortcuts"].Visible
		end, 3, "compact HUD")
		assert(not safe.Haul.Visible and not safe["Current job"].Visible and not safe["Action dock"].Visible)
		local pack = safe["Edge shortcuts"].Pack
		local menuButton = safe["Edge shortcuts"].Menu
		assert(pack.AbsoluteSize.Y >= 44 and menuButton.AbsoluteSize.Y >= 44, "edge tap targets")
		local right = menuButton.AbsolutePosition.X + menuButton.AbsoluteSize.X
		local equipment = controls.Equipment
		assert(math.abs(equipment.AbsolutePosition.X + equipment.AbsoluteSize.X - right) <= 1, "stats align with Menu")
		assert(ring.AbsolutePosition.Y >= equipment.AbsolutePosition.Y + equipment.AbsoluteSize.Y, "separate level row")
		waitFor(function()
			local a, b = wallet.AbsolutePosition, safe.Location.AbsolutePosition
			local aEnd, bEnd = a + wallet.AbsoluteSize, b + safe.Location.AbsoluteSize
			return aEnd.X <= b.X + 1 or bEnd.X <= a.X + 1 or aEnd.Y <= b.Y + 1 or bEnd.Y <= a.Y + 1
		end, 2, "corner stats overlap at " .. tostring(size))
	end
	safe.Size = originalSize
	assert(not menu["Inventory tabs"]:FindFirstChild("Achievements"))
	assert(menu["Inventory tabs"]:FindFirstChild("Passes") and not menu["Inventory tabs"]:FindFirstChild("Skills"))
	local tabViewport = menu["Inventory pages"]
	local pager = tabViewport.UIPageLayout
	assert(
		tabViewport.ClipsDescendants and pager.FillDirection == Enum.FillDirection.Horizontal,
		"horizontal tab viewport"
	)
	for _, page in
		{
			"Menu",
			"Pack",
			"Settings",
			"Inventory",
			"Passes",
			"Pets",
			"Skills",
			"Achievements",
			"Gear",
			"Jobs",
			"Book",
			"Store",
			"Supplies",
		}
	do
		if counters[page] then
			visit(page, true)
		else
			r:FireServer("openPage", page)
		end
		local listing = ({
			Menu = "Miners",
			Settings = "Music volume",
			Inventory = "Prismatic Excavator",
			Pets = "Pocket Rock",
			Passes = "Prism Trail",
			Achievements = "Once Is Luck, Twice Is Skill",
			Gear = "Speed",
			Jobs = "First strike",
			Book = "Stone",
			Pack = "Stone",
			Store = "Double Gold",
			Supplies = "Survey flare",
		})[page]
		waitFor(function()
			if page == "Skills" then
				local map = overlay:FindFirstChild("Skill map")
				return map and map.Visible and not menu.Visible
			end
			local tab = tabViewport:FindFirstChild(page)
			if tab then
				return tabViewport.Visible and pager.CurrentPage == tab and tab:FindFirstChild(listing)
			end
			return overlay.Visible and menu.Listings:FindFirstChild(listing)
		end, 5, "open " .. page)
		local close = if page == "Skills" then overlay["Skill map"]["Map header"].Close else menu.Marquee.Close
		assert(close.Visible and close.Modal, page .. " must release the first-person pointer")
		if page == "Gear" and r:GetAttribute("CheckSwing") then
			for key, price in { Speed = 30, Power = 110, Capacity = 8 } do
				local row = menu.Listings[key]
				waitFor(function()
					return row.Requirements.ContentText == "× " .. price .. " G" and row.Requirements.TextFits
						and row.Action.Text == "Need " .. price .. " G" and not row.Action.Interactable
				end, 2, "gold cost of " .. key .. " for a new miner")
			end
			local benefit = menu.Listings.Power.Benefit
			assert(benefit.Text:sub(1, 12) == "Mines Copper" and benefit.TextFits, benefit.Text)
			assert(benefit.AbsolutePosition.Y + benefit.AbsoluteSize.Y <= menu.Listings.Power.Action.AbsolutePosition.Y)
		end
		if page == "Pets" or page == "Passes" then
			assert(pager.Animated and menu.Position == UDim2.fromScale(0.5, 0.5), "only tab content should swipe")
		end
		if page == "Achievements" then
			assert(not menu["Inventory tabs"].Visible)
			assert(menu.Listings:FindFirstChild("Practicing My Scales"))
		end
		if page == "Pets" then
			n.Action:FireServer("Pet", "Rock")
			waitFor(function()
				return workspace["Rock companions"]:FindFirstChild("Pocket rock")
			end, 4, "equipped follower")
			n.Action:FireServer("PetName", "Flint")
			waitFor(function()
				return p:GetAttribute("PetName") == "Flint"
			end, 3, "renamed rock")
			n.Action:FireServer("Pet", "")
		elseif page == "Inventory" then
			n.Action:FireServer("Title", 6)
			task.wait(0.2)
			assert(p:GetAttribute("EquippedTitle") == 1)
		end
		if page == "Book" then
			assert(menu.Listings["Iron Shelf"].Depth.Text == "27–59 blocks", "index depth in blocks")
			assert(menu.Listings:FindFirstChild("Rock hardness"), "index depth and Power guide")
		end
		task.wait(0.26)
		local left, top = menu.AbsolutePosition.X, menu.AbsolutePosition.Y
		local safe = gui.SafeArea
		assert(left >= safe.AbsolutePosition.X - 1 and top >= safe.AbsolutePosition.Y - 1, "menu origin")
		assert(
			menu.AbsoluteSize.X <= safe.AbsoluteSize.X + 1 and menu.AbsoluteSize.Y <= safe.AbsoluteSize.Y + 1,
			"menu bounds"
		)
	end
	r:FireServer("closePage")
	waitFor(function()
		return not overlay.Visible
	end, 5, "close")
	if not r:GetAttribute("CheckSwing") then
		r:FireServer("depthSample")
		local location = gui.SafeArea.Location
		waitFor(function()
			return location.Depth.Text == "Mine entrance"
				and location.Region.Text == "SUNSTONE HOLLOW"
				and p.leaderstats.Depth.Value == 0
		end, 8, "block coordinates and region on the hut floor")
		assert(not location:FindFirstChild("Coordinates") and location.Depth.TextFits, "location readout clipped")
	end
	if r:GetAttribute("CheckSwing") then
		assert(p.CameraMaxZoomDistance <= 28)
		r:FireServer("gateApproach")
		local origin = n:GetAttribute("Origin")
		waitFor(function()
			return (p.Character.HumanoidRootPart.Position - origin - Vector3.new(0, 3, 2)).Magnitude < 5
		end, 5, "approach")
		p.Character.Humanoid:MoveTo(origin + Vector3.new(0, 0, -12))
		waitFor(function()
			local at = p.Character.HumanoidRootPart.Position - origin
			return at.Z < -8 and at.Y > 0 and at.Y < 5
		end, 5, "walk through the narrow gate")
	end
	r:FireServer("position")
	local origin = n:GetAttribute("Origin")
	waitFor(function()
		local pos = p.Character.Head.Position - origin
		return pos.Z < 0 and math.abs(pos.Y - 4) < 3
	end, 8, "placement at starter seam")
	waitFor(function()
		local gallery = workspace.CitrineCove["Citrine Mine"]:FindFirstChild("Gallery glow")
		local center = workspace.CitrineCove:FindFirstChild("Working gallery")
		local lamp = center and center:FindFirstChild("Center lantern")
		local light = lamp and lamp:FindFirstChildOfClass("SurfaceLight")
		return gallery
			and gallery:FindFirstChildOfClass("PointLight")
			and light
			and light.Enabled
			and light.Face == Enum.NormalId.Bottom
			and light.Brightness >= 0.94
	end, 8, "streamed mine lighting")
	local first = os.clock()
	local discovered
	n.Feedback.OnClientEvent:Connect(function(kind, title, name)
		if kind == "milestone" then
			if title == "ORE DISCOVERED" then
				discovered = name
			end
		end
	end)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.CitrineCove:WaitForChild("MineBlocks") }
	local head = p.Character.Head
	local config = require(rep.Shared.GameConfig)
	local pattern = require(rep.Shared.BlockPattern)
	local ores = require(rep.Shared.Ores)
	if r:GetAttribute("CheckSwing") then
		local camera = workspace.CurrentCamera
		local input = game:GetService("UserInputService"):CreateVirtualInput()
		assert(input, "Studio virtual input unavailable")
		local function tapKey(code)
			input:SendKey(true, code)
			task.wait()
			input:SendKey(false, code)
		end
		tapKey(Enum.KeyCode.Tab)
		waitFor(function() return not roster.Miners.Visible end, 2, "fold default roster")
		tapKey(Enum.KeyCode.Tab)
		waitFor(function() return roster.Miners.Visible end, 2, "reopen roster")
		do
			assert(not safe["Action dock"]:FindFirstChild("Keybind", true), "letter badges removed")
			tapKey(Enum.KeyCode.O)
			game:GetService("RunService").Heartbeat:Wait()
			assert(not overlay.Visible, "O is reserved for the camera")
			for _, slot in {
				{ "Inventory", Enum.KeyCode.B }, { "Skills", Enum.KeyCode.K }, { "Achievements", Enum.KeyCode.H },
				{ "Book", Enum.KeyCode.J }, { "Settings", Enum.KeyCode.P },
			} do
				local page, code = slot[1], slot[2]
				tapKey(code)
				waitFor(function()
					if not overlay.Visible then
						return false
					elseif page == "Skills" then
						return overlay["Skill map"].Visible
					elseif page == "Inventory" then
						return tabViewport.Visible and pager.CurrentPage.Name == page
					end
					local row = ({ Achievements = "Practicing My Scales", Book = "Stone", Settings = "Music volume" })[page]
					return menu.Visible and menu.Listings:FindFirstChild(row)
				end, 3, page .. " shortcut")
			end
			tapKey(Enum.KeyCode.P)
			waitFor(function() return not overlay.Visible end, 2, "toggle Settings closed")
			r:FireServer("openPage", "Pets")
			waitFor(function() return overlay.Visible and pager.CurrentPage.Name == "Pets" end, 3, "pets tab")
			local name = tabViewport.Pets.Rename:FindFirstChildOfClass("TextBox")
			name:CaptureFocus()
			waitFor(function() return name:IsFocused() end, 2, "typing pet name")
			tapKey(Enum.KeyCode.B)
			task.wait(0.2)
			assert(overlay.Visible and name:IsFocused() and pager.CurrentPage.Name == "Pets", "B while typing")
			name:ReleaseFocus()
			waitFor(function() return not game.UserInputService:GetFocusedTextBox() end, 2, "pet name focus released")
			game:GetService("RunService").Heartbeat:Wait()
			tapKey(Enum.KeyCode.B)
			waitFor(function() return not overlay.Visible end, 2, "B closes inventory from Pets")
		end
		tapKey(Enum.KeyCode.P)
		waitFor(function()
			return overlay.Visible and menu.Listings:FindFirstChild("Music volume")
		end, 4, "settings")
		task.wait(0.3)
		local function clickAt(xy)
			input:SendMousePosition(xy)
			task.wait(0.07)
			input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
			task.wait(0.07)
			input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
			task.wait(0.07)
		end
		local function adjust(row, value, key, group)
			local track = menu.Listings[row].Slider.Track
			local xy = track.AbsolutePosition
				+ track.AbsoluteSize * Vector2.new(value / 100, 0.5)
				+ game:GetService("GuiService"):GetGuiInset()
			clickAt(xy)
			waitFor(function()
				return p:GetAttribute(key) == value and math.abs(group.Volume - value / 100) < 0.011
			end, 2, row .. " slider")
		end
		adjust("Music volume", 0, "MusicVolume", song.SoundGroup)
		assert(harbor["Coal break"].SoundGroup.Volume > 0.5, "music muted effects")
		adjust("Sound effects", 23, "SfxVolume", harbor["Coal break"].SoundGroup)
		assert(song.SoundGroup.Volume == 0, "effects changed music")
		adjust("Music volume", 55, "MusicVolume", song.SoundGroup)
		adjust("Sound effects", 80, "SfxVolume", harbor["Coal break"].SoundGroup)
		local function clickButton(button)
			clickAt(button.AbsolutePosition + button.AbsoluteSize * 0.5 + game.GuiService:GetGuiInset())
		end
		for _, channel in {
			{ "Music volume", "MusicMuted", "MusicVolume", song.SoundGroup },
			{ "Sound effects", "SfxMuted", "SfxVolume", harbor["Coal break"].SoundGroup },
		} do
			local row = menu.Listings[channel[1]]
			local button, track = row.Mute, row.Slider.Track
			local volume, tint = p:GetAttribute(channel[3]), track.Fill.BackgroundColor3
			clickButton(button)
			waitFor(function()
				return p:GetAttribute(channel[2]) and button["Mute slash"].Visible and not button.Waves.Visible
					and not row.Slider.Interactable and channel[4].Volume == 0
			end, 3, "mute " .. channel[1])
			assert(track.Fill.BackgroundColor3 ~= tint and not row.Slider.Selectable)
			clickButton(track)
			assert(p:GetAttribute(channel[3]) == volume and math.abs(track.Fill.Size.X.Scale - volume / 100) < 0.001)
			clickButton(button)
			waitFor(function()
				return not p:GetAttribute(channel[2]) and math.abs(channel[4].Volume - volume / 100) < 0.001
					and row.Slider.Interactable and button.Waves.Visible and not button["Mute slash"].Visible
					and track.Fill.BackgroundColor3 == tint
			end, 3, "restore volume")
		end
		r:FireServer("closePage")
		waitFor(function()
			return not overlay.Visible
		end, 2, "animated close")
		local ringPoint = ring.AbsolutePosition + ring.AbsoluteSize * 0.5 + game.GuiService:GetGuiInset()
		input:SendMousePosition(ringPoint)
		waitFor(function()
			return ring["Interaction scale"].Scale > 1.02
		end, 2, "hover feedback")
		input:SendMouseButton(ringPoint, Enum.UserInputType.MouseButton1, true)
		waitFor(function()
			return ring["Interaction scale"].Scale < 0.98
		end, 2, "press feedback")
		input:SendMouseButton(ringPoint, Enum.UserInputType.MouseButton1, false)
		waitFor(function()
			return overlay.Visible
				and overlay["Skill map"].Visible
				and overlay["Skill map"]["Map header"].Summary.Text:find("0 / 20 XP", 1, true)
		end, 3, "tap the level ring for exact XP")
		local map = overlay["Skill map"]
		local viewport = map["Map viewport"]
		local canvas = viewport.Branches
		assert(map["Map header"]["Skill point balance"].Count.Text == "0")
		assert(canvas.Reach["Skill state"].Symbol.Text == "1" and canvas.Focus["Skill state"].Padlock.Visible)
		assert(not ring["Skill points"].Visible and #canvas["Unlock lights"]:GetChildren() == 0)
		assert(canvas:FindFirstChild("Reach to Focus") and canvas:FindFirstChild("Lamp to Focus"))
		assert(canvas:FindFirstChild("Constellation") and canvas:FindFirstChild("HotSteel"))
		local before = canvas.AbsolutePosition
		local dragStart = viewport.AbsolutePosition
			+ viewport.AbsoluteSize * Vector2.new(0.55, 0.24)
			+ game.GuiService:GetGuiInset()
		input:SendMousePosition(dragStart)
		input:SendMouseButton(dragStart, Enum.UserInputType.MouseButton1, true)
		task.wait(0.08)
		input:SendMousePosition(dragStart + Vector2.new(70, 28))
		task.wait(0.12)
		input:SendMouseButton(dragStart + Vector2.new(70, 28), Enum.UserInputType.MouseButton1, false)
		waitFor(function()
			return (canvas.AbsolutePosition - before).Magnitude > 50
		end, 2, "drag skill tree")
		task.wait(0.15)
		local node = canvas.Reach
		clickAt(node.AbsolutePosition + node.AbsoluteSize * 0.5 + game.GuiService:GetGuiInset())
		waitFor(function()
			return map["Skill details"].Learn.Visible and map["Skill details"].Learn.Text == "Need 1 point"
		end, 2, "inspect skill")
		r:FireServer("closePage")
		waitFor(function()
			return not overlay.Visible
		end, 3, "leave skill tree")
		local hand = p.Character:FindFirstChild("RightHand") or p.Character:FindFirstChild("Right Arm")
		-- Inspect six surfaces, including an isolated block that can be viewed from every side.
		local painter = require(p.PlayerScripts.Client.Effects).new()
		local face = head.Position + Vector3.xAxis * 6
		local warm = Color3.fromRGB(255, 225, 169)
		painter:aim({ face })
		assert(not painter.faceLamp and not painter.preview:FindFirstChildWhichIsA("Light", true), "hover lit a block")
		local rim = painter.preview["Selected block"]:FindFirstChildOfClass("Beam")
		local idleBrightness = rim.Brightness
		painter:setMiningLight(face, 9, warm)
		assert(rim.Brightness < idleBrightness, "the working lamp takes visual priority over the mint outline")
		local source = painter.faceLamp
		assert(
			source.Enabled
				and source.Shadows
				and source.Range == 9
				and source.Color == warm
				and (painter.faceMount.WorldPosition - face).Magnitude < 0.01
		)
		painter:aim(nil)
		assert(source.Enabled and source.Color == warm, "outline changed the mining light")
		painter:setMiningLight(face + Vector3.one, 15, ores.byName.Emerald.color)
		assert(source == painter.faceLamp and source.Range == 15 and source.Color == ores.byName.Emerald.color)
		painter:setMiningLight(nil)
		assert(rim.Brightness == idleBrightness, "hover must restore the outline")
		assert(not source.Enabled)
		for i = 1, 6 do
			painter:oreLight(face + Vector3.xAxis * i, false)
		end
		assert(#painter.oreLights == 4)
		painter:clearOreLights()
		assert(#painter.oreLights == 0)
		local cube = Instance.new("Part")
		cube.Anchored, cube.Size, cube.Position, cube.Parent =
			true, Vector3.one * config.Cell, head.Position + Vector3.yAxis * 48, workspace
		cube:SetAttribute("OpenFaces", 63)
		painter:damage(cube, 0.15)
		local overlays = cube.Fractures:GetChildren()
		assert(#overlays == 6)
		for _, surface in overlays do
			local growing = 0
			for _, line in surface:GetChildren() do
				if line.Visible and line.Name == "Vein" then
					growing += 1
				end
			end
			assert(
				growing == 3 and not surface.AlwaysOnTop and surface.ZOffset == 0 and surface.Adornee == cube,
				"early cracks did not radiate together"
			)
		end
		painter:damage(cube, 1)
		for _, surface in overlays do
			local visible = 0
			for _, line in surface:GetChildren() do
				if line.Visible then
					visible += 1
				end
			end
			assert(visible >= 48)
		end
		cube:Destroy()
		for _, surface in overlays do
			assert(not surface.Parent, "orphan crack")
		end
		painter:clearDamage()
		painter.faceMount:Destroy()
		painter.preview:Destroy()
		painter.sparkOrigin:Destroy()
		local function visibleOre(name)
			for _, part in workspace.CitrineCove.MineBlocks:GetChildren() do
				if part.Name ~= name or (part.Position - head.Position).Magnitude > 36 then
					continue
				end
				for _, normal in { Vector3.zAxis, Vector3.yAxis, Vector3.xAxis, -Vector3.xAxis, -Vector3.zAxis } do
					local half = part.Size * 0.5
					local at = config.blockCenter(origin, part.Position + normal * half, normal)
					if pattern.visiblePart(head.Position, at, normal, params) == part then
						return at, normal
					end
				end
			end
		end
		local visionBadge
		local function pressX()
			input:SendKey(true, Enum.KeyCode.X)
			input:SendKey(false, Enum.KeyCode.X)
		end
		if ownerVision then
			visionBadge = gui.SafeArea.Location:WaitForChild("Ore vision status", 3)
			assert(visionBadge and not visionBadge.Visible, "ore vision starts off")
			local reply = table.pack(ownerVision.Scan:InvokeServer(nil))
			assert(reply.n == 3 and typeof(reply[3]) == "buffer", "owner scan returns only its local snapshot")
			pressX()
			waitFor(function()
				return visionBadge.Visible
			end, 2, "X enables ore vision")
			waitFor(function() return ownerVision:FindFirstChild("Coal") end, 3, "nearby ores shown by default")
			assert(not ownerVision:FindFirstChild("Ore waypoints") and not ownerVision:FindFirstChild("Starfall"))
			local filters = gui.SafeArea["X-ray ore filters"]
			clickButton(gui.SafeArea.Location["X-ray controls"].Filters)
			waitFor(function() return filters.Visible end, 2, "ore filters open")
			clickButton(filters.None)
			waitFor(function() return not ownerVision:FindFirstChildWhichIsA("BoxHandleAdornment") end, 2, "empty filter clears highlights")
			clickButton(filters.Starfall)
			waitFor(function() return visionBadge.Text:find("0 nearby", 1, true) end, 3, "Starfall filter respects the local range")
			assert(not ownerVision:FindFirstChildWhichIsA("BoxHandleAdornment"))
			clickButton(filters.Starfall)
			clickButton(filters.Copper)
			waitFor(function() return ownerVision:FindFirstChild("Copper") end, 3, "show nearby copper alone")
			assert(not ownerVision:FindFirstChild("Coal"))
			input:SendKey(true, Enum.KeyCode.LeftShift)
			pressX()
			input:SendKey(false, Enum.KeyCode.LeftShift)
			waitFor(function() return not filters.Visible and visionBadge.Visible end, 2, "Shift-X closes filters while tracking")
			clickButton(gui.SafeArea.Location["X-ray controls"].Filters)
			clickButton(filters.All)
			clickButton(filters.Close)
			waitFor(function() return ownerVision:FindFirstChildWhichIsA("BoxHandleAdornment") end, 3, "buried ore visible before the first cut")
			local top = origin + Vector3.yAxis * config.FloorY
			local playerCell = ((p.Character.HumanoidRootPart.Position - top) / config.Cell):Floor()
			local spawned = {}
			for _, part in workspace.CitrineCove.MineBlocks:GetChildren() do spawned[part.Position] = true end
			for _, box in ownerVision:GetChildren() do
				if not box:IsA("BoxHandleAdornment") then continue end
				local at = (box.Adornee.CFrame * box.CFrame).Position
				local cell = ((at - top) / config.Cell):Floor()
				assert((cell - playerCell).Magnitude <= 10 and not spawned[at] and not ores.byName[box.Name].host)
			end
			local old = ownerVision:FindFirstChildWhichIsA("BoxHandleAdornment")
			r:FireServer("moveOreVision")
			waitFor(function()
				local box = ownerVision:FindFirstChildWhichIsA("BoxHandleAdornment")
				if old.Parent or not box then return false end
				local at = (box.Adornee.CFrame * box.CFrame).Position
				local cell = ((at - top) / config.Cell):Floor()
				return (cell - playerCell - Vector3.xAxis * 24).Magnitude <= 10
			end, 4, "moving across chunks replaces out-of-range markers")
			r:FireServer("position")
			waitFor(function()
				return ((p.Character.HumanoidRootPart.Position - top) / config.Cell):Floor() == playerCell
			end, 3, "returned to the shaft")
		end
		-- Drill the two starter shafts through the real cut protocol before aiming at ore.
		for _, x in { -0.5, 0.5, -1.5, 1.5 } do
			for _, y in (if math.abs(x) == 0.5 then { -0.5, -1.5 } else { -0.5 }) do
				local at = origin + Vector3.new(x, y, -2.5) * config.Cell
				local used = p:GetAttribute("Used")
				local floor = workspace.CitrineCove.MineBlocks:GetChildren()
				local material
				for _, block in floor do
					if block:IsA("BasePart") and (block.Position - at).Magnitude < 0.02 then material = ores.byName[block.Name]; break end
				end
				assert(material, "visible block to drill in the starter shafts")
				n.Swing:FireServer(true, at, Vector3.yAxis)
				task.wait(ores.cutTime(0.8, material) + 0.18)
				n.Mine:FireServer(at, Vector3.yAxis, 1, 1)
				waitFor(function()
					return p:GetAttribute("Used") == used + 1
				end, 3, "shaft block awarded")
			end
		end
		local startingHaul = p:GetAttribute("Used")
		local aim, aimNormal = visibleOre("Coal")
		assert(aim, "expected visible coal in the test field")
		local coalMarker
		if ownerVision then
			waitFor(function()
				for _, box in ownerVision:GetChildren() do
					if
						box:IsA("BoxHandleAdornment")
						and box.Adornee
						and (box.Adornee.CFrame * box.CFrame).Position == aim
						and box.AlwaysOnTop
					then
						coalMarker = box
						return true
					end
				end
				return false
			end, 3, "newly exposed coal marked through walls")
		end
		camera.CameraType = Enum.CameraType.Scriptable
		local root = p.Character.HumanoidRootPart
		local eye = root.Position + Vector3.yAxis * math.min(1.3, root.Size.Y * 0.6)
		local face = aim + aimNormal * (config.Cell / 2)
		local intoWall = CFrame.lookAt(face - aimNormal * 1.5, eye)
		local render = game:GetService("RunService")
		local attempted = false
		render:BindToRenderStep("Test wall camera", Enum.RenderPriority.Camera.Value + 1, function()
			camera.CFrame = intoWall
			attempted = true
		end)
		waitFor(function()
			return attempted and (camera.CFrame.Position - face):Dot(aimNormal) > 0.15
		end, 3, "camera clipped through an exposed face")
		render:UnbindFromRenderStep("Test wall camera")
		camera.CFrame = CFrame.lookAt(head.Position, aim + aimNormal * (config.Cell / 2))
		local xy = camera.ViewportSize * 0.5
		input:SendMousePosition(xy)
		local meter = gui.SafeArea.Feedback["Mining progress"]
		local function outlined()
			local marker = workspace.MiningSelection:FindFirstChild("Selected block")
			return marker and (marker.Position - aim).Magnitude <= 0.02
		end
		p:SetAttribute("SkillFocus", true)
		waitFor(outlined, 4, "depth-tested borders on the selected cell")
		assert(not workspace.Terrain:FindFirstChild("Face lantern"), "hover activated Face Lantern")
		local selection = workspace.MiningSelection["Selected block"]
		assert(not selection:FindFirstChildWhichIsA("Light", true))
		assert(selection.Transparency == 1 and not selection.CanQuery and not selection.CanCollide)
		local corners, edges = 0, 0
		local neighbors = {}
		for _, item in selection:GetChildren() do
			if item:IsA("Attachment") then
				corners += 1
			else
				assert(item:IsA("Beam") and item.LightInfluence == 0 and item.LightEmission > 0 and item.ZOffset == 0)
				local a, b = item.Attachment0, item.Attachment1
				assert(a.Parent == selection and b.Parent == selection)
				neighbors[a], neighbors[b] = neighbors[a] or {}, neighbors[b] or {}
				assert(not table.find(neighbors[a], b), "duplicate visible edge")
				table.insert(neighbors[a], b)
				table.insert(neighbors[b], a)
				edges += 1
			end
		end
		assert(corners == 8 and edges == 12, "a single glowing outline")
		for _, adjacent in neighbors do
			assert(#adjacent == 3, "disconnected corner")
		end
		local cursor = p.PlayerGui.MiningAim["Mining cursor"]
		assert(cursor.Visible and not cursor["No entry"].Visible, "mineable cursor")
		p:SetAttribute("Used", p:GetAttribute("PackSlots"))
		waitFor(function() return cursor.Visible and cursor["No entry"].Visible end, 2, "full bag uses blocked cursor")
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
		task.wait(0.2)
		assert(not meter.Visible and not workspace.Terrain:FindFirstChild("Face lantern"))
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
		p:SetAttribute("Used", startingHaul)
		waitFor(function() return cursor.Visible and not cursor["No entry"].Visible end, 2, "bag with room restores pick cursor")
		assert(game:GetService("StarterPlayer").LoadCharacterAppearance, "account appearance disabled")
		assert(
			not p.PlayerGui:FindFirstChild("Inside rock") and p.Character:FindFirstChild("Head clearance", true),
			"head collision guard"
		)
		local pick = p.Character["Harbor pick"]
		local palm = hand:FindFirstChild("RightGripAttachment")
		local function gripError()
			local expected = if palm
				then palm.WorldPosition
				else hand.CFrame:PointToWorldSpace(Vector3.new(0, -hand.Size.Y * 0.4, 0))
			return (pick["Grip tape"].Position - expected).Magnitude
		end
		-- Measure the arm's arc relative to the torso across avatar sizes and idle poses.
		local arm = p.Character:FindFirstChild("RightUpperArm") or hand
		local torso = p.Character:FindFirstChild("UpperTorso") or p.Character.Torso
		local function armPose()
			return torso.CFrame:ToObjectSpace(arm.CFrame).Rotation
		end
		local idlePose = armPose()
		local function swingAngle()
			local _, angle = idlePose:ToObjectSpace(armPose()):ToAxisAngle()
			return math.deg(angle)
		end
		assert(gripError() < 0.035, "idle hand grip")
		r:FireServer("renewalNotice")
		waitFor(function()
			for _, label in meter.Parent:GetChildren() do
				if label:IsA("TextLabel") and label.Text == "Mine renews in 30 seconds" then
					return true
				end
			end
			return false
		end, 3, "mining notice")
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
		waitFor(function()
			return meter.Visible and meter.Charge.Size.X.Scale > 0.1 and swingAngle() > 60
		end, 3, "raised pick and progress")
		local barGap = meter.AbsolutePosition.Y - (cursor.AbsolutePosition.Y + cursor.AbsoluteSize.Y)
		assert(barGap >= 4 and barGap <= 16, "expected the progress bar just below the animated pick, gap " .. barGap)
		local mount = workspace.Terrain:FindFirstChild("Face lantern")
		local lamp = mount and mount:FindFirstChildOfClass("PointLight")
		assert(lamp and lamp.Enabled and lamp.Color == warm and lamp.Range == 9, "active cut is missing its warm light")
		local firstContact = mount.WorldPosition
		input:SendMousePosition(xy + Vector2.new(6, 0))
		waitFor(function()
			return lamp.Enabled and (mount.WorldPosition - firstContact).Magnitude > 0.015
		end, 2, "lantern follows the pick across the face")
		local mouse = game.UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
		local contact = workspace:Raycast(ray.Origin, ray.Direction * 64, params)
		assert(
			contact and (mount.WorldPosition - contact.Position - contact.Normal * 0.45).Magnitude < 0.1,
			"lamp missed the struck face"
		)
		assert(workspace.CitrineCove.MineBlocks:FindFirstChild("Fractures", true) ~= nil, "visible impact cracks")
		local impact = root:WaitForChild("Pick impact", 2)
		assert(impact and impact.SoundId == harbor["Coal break"].SoundId)
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
		waitFor(function()
			return not meter.Visible and swingAngle() < 20
		end, 3, "cancelled swing")
		assert(not lamp.Enabled and outlined(), "release must extinguish the lamp while keeping the border")
		assert(p:GetAttribute("Used") == startingHaul, "early release spent a block")
		p:SetAttribute("SkillFocusII", true)
		p:SetAttribute("SkillLongbeam", true)
		p:SetAttribute("FoundCoal", true)
		local hitCount = 0
		local hits = impact.Played:Connect(function() hitCount += 1 end)
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
		local coalTint = ores.byName.Coal.color:Lerp(Color3.new(1, 1, 1), 0.35)
		waitFor(function()
			return lamp.Enabled and lamp.Color == coalTint and lamp.Range == 15
		end, 2, "Prism Lens ore tint and Wide Beam range during a cut")
		local peaks, high, maxGap, replicated = 0, false, 0, false
		local deadline = os.clock() + 3
		repeat
			game:GetService("RunService").PostSimulation:Wait()
			maxGap = math.max(maxGap, gripError())
			replicated = replicated
				or (p.Character:GetAttribute("MiningSwing") ~= nil and p.Character:GetAttribute("MiningOre") == "Coal")
			local angle = swingAngle()
			if not high and angle > 85 then
				high = true
				peaks += 1
			elseif high and angle < 55 then
				high = false
			end
		until p:GetAttribute("Used") > startingHaul or os.clock() > deadline
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
		assert(p:GetAttribute("Used") == startingHaul + 1, "completed cut")
		hits:Disconnect()
		assert(hitCount >= 2, "expected repeated digging sounds during the cut")
		assert(not lamp.Enabled, "completed cut left its lamp on")
		assert(not workspace.CitrineCove.MineBlocks:FindFirstChild("Fractures", true), "completed cracks lingered")
		assert(peaks >= 2, "expected repeated swings during the first cut, saw " .. peaks)
		assert(maxGap < 0.035, "grip drift: " .. maxGap)
		assert(replicated, "swing start was not replicated")
		waitFor(function()
			return not p.Character:GetAttribute("MiningSwing")
		end, 3, "replicated swing release")
		local popup
		waitFor(function()
			popup = workspace.Terrain:FindFirstChild("Ore find")
			return popup and popup:FindFirstChild("Ore popup") and popup["Ore popup"]:FindFirstChild("Purity")
		end, 2, "world ore popup")
		assert(
			(popup.WorldPosition - (aim + aimNormal * (config.Cell / 2))).Magnitude < 0.02
				and popup["Ore popup"].TextLabel.Text == "+1 Coal"
				and popup["Ore popup"].Purity.Text:find("%d+%% pure"),
			"popup location and label"
		)
		if ownerVision then
			waitFor(function()
				return not coalMarker.Parent
			end, 2, "mined ore marker clears")
			pressX()
			waitFor(function()
				return not visionBadge.Visible and not ownerVision:FindFirstChildWhichIsA("BoxHandleAdornment")
			end, 2, "X removes remaining ore markers")
			pressX()
			waitFor(function()
				return ownerVision:FindFirstChild("Copper") ~= nil
			end, 2, "X restores nearby ore markers")
			pressX()
		end
		waitFor(function()
			return not popup.Parent
		end, 2, "popup fades out")
		local copper, copperNormal = visibleOre("Copper")
		assert(copper, "visible locked copper")
		camera.CFrame = CFrame.lookAt(head.Position, copper + copperNormal * (config.Cell / 2))
		waitFor(function()
			return cursor.Visible and cursor["No entry"].Visible
		end, 5, "locked copper cursor")
		local collected = p:GetAttribute("Used")
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
		task.wait(0.85)
		assert(not lamp.Enabled, "locked ore lit up while holding mine")
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
		assert(
			p:GetAttribute("Used") == collected
				and not meter.Visible
				and not workspace.CitrineCove.MineBlocks:FindFirstChild("Fractures", true),
			"locked ore started a cut"
		)
		local at = aim - Vector3.zAxis * config.Cell
		r:FireServer("walk")
		waitFor(function()
			return not root.Anchored
		end, 3, "walking enabled")
		p.Character.Humanoid:MoveTo(aim)
		waitFor(function()
			return (root.Position - aim).Magnitude < 1.8
		end, 6, "enter the shaft mined from above")
		local hit = workspace:Raycast(head.Position, at - head.Position, params)
		assert(hit and hit.Instance.Position == at and hit.Instance.Name == "Stone", "underground workface")
		local target = hit.Instance
		n.Swing:FireServer(true, at, Vector3.zAxis)
		task.wait(ores.cutTime(0.8, ores.byName[target.Name]) + 0.15)
		n.Mine:FireServer(at, Vector3.zAxis, 1, 1)
		waitFor(function()
			return not target.Parent
		end, 3, "single block doorway")
		p.Character.Humanoid:MoveTo(at)
		waitFor(function()
			return (root.Position - at).Magnitude < 1.8
		end, 5, "avatar fits one six-stud cut")
		visit("Sell", false)
		r:FireServer("openPage", "Sell")
		waitFor(function() return overlay.Visible and menu.Listings:FindFirstChild("Stone") end, 3, "sell controls")
		task.wait(0.3)
		do
			local row = menu.Listings.Dirt
			assert(p:GetAttribute("HeldDirt") == 4, "four dirt from the starter shafts")
			local worth = p:GetAttribute("BagValue")
			local gold = p:GetAttribute("Gold")
			waitFor(function() return row["Sell quantity"].Text == "Sell 1 Dirt\n+1 gold" and row.More.Interactable end, 2, "default sell one")
			clickButton(row["Select stack"])
			assert(row["Sell quantity"].Text == "Sell 4 Dirt\n+4 gold" and row["Unit price"].ContentText:find("0 left after sale"))
			assert(p:GetAttribute("HeldDirt") == 4 and p:GetAttribute("Gold") == gold, "selection must only preview")
			local track = row.Slider.Track
			local start = track.AbsolutePosition + Vector2.new(0, track.AbsoluteSize.Y / 2) + game.GuiService:GetGuiInset()
			local target = start + Vector2.new(track.AbsoluteSize.X * 2 / 3, 0)
			input:SendMousePosition(start)
			input:SendMouseButton(start, Enum.UserInputType.MouseButton1, true)
			task.wait(0.07)
			input:SendMousePosition(target)
			task.wait(0.07)
			input:SendMouseButton(target, Enum.UserInputType.MouseButton1, false)
			waitFor(function() return row["Sell quantity"].Text == "Sell 3 Dirt\n+3 gold" and row["Unit price"].ContentText:find("1 left after sale") end, 2, "quantity drag preview")
			clickButton(row.Fewer)
			assert(row["Sell quantity"].Text == "Sell 2 Dirt\n+2 gold" and p:GetAttribute("Gold") == gold)
			clickButton(row["Sell quantity"])
			waitFor(function()
				return p:GetAttribute("HeldDirt") == 2 and p:GetAttribute("Gold") == gold + 2 and row["Sell quantity"].Text == "Sell 1 Dirt\n+1 gold"
			end, 3, "sell two and reset quantity")
			assert(menu.Status["Sell all"].Text == string.format("Sell entire pack\n%d blocks · +%d G", p:GetAttribute("Used"), worth - 2))
			task.wait(0.25)
			clickButton(menu.Status["Sell all"])
			waitFor(function()
				return p:GetAttribute("Used") == 0 and p:GetAttribute("Gold") == gold + worth and not menu.Status["Sell all"].Interactable
			end, 3, "sell entire pack from menu")
		end
		do
			r:FireServer("openPage", "Settings")
			waitFor(function() return menu.Listings:FindFirstChild("Reset progress") end, 3, "reset option")
			task.wait(0.3)
			local guide = menu.Listings["First expedition"].Action
			menu.Listings.CanvasPosition = Vector2.new(0, menu.Listings.AbsoluteCanvasSize.Y)
			task.wait(.18)
			clickButton(guide)
			waitFor(function() return p:GetAttribute("ExpeditionStep") == "Skipped" and not guide.Interactable end, 3, "skip expedition")
			menu.Listings.CanvasPosition = Vector2.zero
			task.wait(.18)
			local row = menu.Listings["Reset progress"]
			local gold = p:GetAttribute("Gold")
			assert(gold > 0 and not row.Erase.Visible)
			clickButton(row.Review)
			assert(row.Erase.Visible and row.Review.Text == "Cancel" and p:GetAttribute("Gold") == gold)
			clickButton(row.Review)
			assert(not row.Erase.Visible and p:GetAttribute("Gold") == gold, "cancel kept the miner")
			clickButton(menu.Listings["Sound effects"].Mute)
			clickButton(row.Review)
			clickButton(row.Erase)
			waitFor(function()
				return p:GetAttribute("Gold") == 0 and p:GetAttribute("Mined") == 0 and p:GetAttribute("ProgressResets") == 1
					and (root.Position - n:GetAttribute("Landing")).Magnitude < 8
			end, 5, "confirmed reset returns a fresh miner to spawn")
			assert(p:GetAttribute("MiningXP") == 0 and not p:GetAttribute("FoundCoal") and p:GetAttribute("Level") == 1)
			assert(p:GetAttribute("ExpeditionStep") == "Dig" and p:GetAttribute("IntroSeen"))
			assert(p:GetAttribute("SfxMuted") and p:GetAttribute("SfxVolume") == 80 and not row.Erase.Visible)
			assert(menu.Listings["Sound effects"].Mute["Mute slash"].Visible)
			local replay = menu.Listings["Where the Stars Took Root"].Action
			menu.Listings.CanvasPosition = Vector2.new(0,menu.Listings.AbsoluteCanvasSize.Y)
			task.wait(.2)
			clickButton(replay)
			local subs = p.PlayerGui:WaitForChild("Mine subtitles",3)
			assert(subs and not gui.SafeArea.Visible and p:GetAttribute("IntroSeen"), "returning miner can replay")
			clickButton(subs.Skip)
			waitFor(function() return not subs.Parent and gui.SafeArea.Visible end,2,"on-screen skip restores play")
			assert(p:GetAttribute("ExpeditionStep")=="Dig" and p:GetAttribute("ProgressResets")==1)
		end
		return string.format(
			"reset controls, mute icons, %d swings in one cut, grip error %.4f studs, early release",
			peaks,
			maxGap
		)
	end
	local gameRay = RaycastParams.new()
	gameRay.FilterDescendantsInstances = { p.Character }
	local normals = { Vector3.yAxis, Vector3.zAxis, Vector3.xAxis, -Vector3.xAxis, -Vector3.zAxis, -Vector3.yAxis }
	local function dig(count)
		-- Two miners deplete the same gallery. Re-aim at an exposed face each cut,
		-- including the sides and the floor that open up behind the original wall.
		local eye = head.Position
		local best, side, material, score = nil, nil, nil, math.huge
		for _, brick in workspace.CitrineCove.MineBlocks:GetChildren() do
			local ore = ores.byName[brick.Name]
			if not ore or ore.hardness > 1 then
				continue
			end
			local half = brick.Size * 0.5
			local near = (eye - brick.Position):Max(-half + Vector3.one * 0.01):Min(half - Vector3.one * 0.01)
			for _, normal in normals do
				local face = brick.Position + near * (Vector3.one - normal:Abs()) + half * normal
				local center = config.blockCenter(origin, face, normal)
				local distance = (eye - center).Magnitude
				local priority = distance - (if not discovered and not ore.host then 35 else 0)
				if
					distance <= config.Reach + 2
					and priority < score
					and pattern.visiblePart(eye, center, normal, gameRay) == brick
				then
					best, side, material, score = center, normal, ore, priority
				end
			end
		end
		if not best then
			return
		end
		n.Swing:FireServer(true, best, side)
		task.wait(ores.cutTime(0.8, material) + 0.05)
		n.Mine:FireServer(best, side, count, 2 ^ count - 1)
		n.Swing:FireServer(false)
	end
	local starterSlots = p:GetAttribute("PackSlots")
	assert(starterSlots == 8, "the first pack introduces a short trip")
	for i = 1, 650 do
		dig(1)
		if p:GetAttribute("Used") == starterSlots then
			break
		end
		task.wait(0.12)
	end
	assert(p:GetAttribute("Used") == starterSlots, "starter pack incomplete: " .. tostring(p:GetAttribute("Used")))
	assert(p:GetAttribute("ExpeditionStep") == "Sell", "a full starter pack must always lead to sale")
	local spotlight = waitFor(function()
		local layer = safe:FindFirstChild("Surface spotlight")
		return layer and layer.Visible and layer
	end, 3, "focus Surface when the starter pack fills")
	for _, side in { "Top", "Bottom", "Left", "Right" } do
		assert(not spotlight[side].Active, "the shade must leave Surface usable")
	end
	assert(spotlight["Return arrow"].Visible and safe.Location.Surface.Interactable)
	local value = p:GetAttribute("BagValue")
	assert(value >= starterSlots, "material valuation")
	local purity = require(rep.Shared.OrePurity)
	local quantity, total, earnedXP = 0, 0, 0
	for _, ore in ores.list do
		local held = p:GetAttribute("Held" .. ore.name)
		if held > 0 then
			assert(
				gui.SafeArea.Haul[ore.name].Visible and gui.SafeArea.Haul[ore.name].Quantity.Text == "×" .. held,
				"live haul row"
			)
		end
		quantity += held
		total += purity.quote(ore, held, purity.decode(p:GetAttribute("Grades" .. ore.name)), held, p:GetAttribute("SkillBroker"))
		earnedXP += held * ore.xp
	end
	assert(quantity == starterSlots and total == value, "pack quantities and value")
	assert(p:GetAttribute("MiningXP") == earnedXP, "XP from each material in the first haul")
	local level = require(rep.Shared.Expeditions).level(earnedXP)
	assert(p:GetAttribute("Level") == level and controls.Equipment.Power.Visible, "level and equipment HUD")
	n.Action:FireServer("Sell")
	task.wait(0.4)
	assert(p:GetAttribute("Used") == starterSlots and p:GetAttribute("Gold") == 0, "exchange must require a visit")
	visit("Sell", false)
	waitFor(function() return not spotlight.Visible end, 3, "release the Surface spotlight at the exchange")
	local sellPrompt = counters.Sell.Service
	task.wait(0.25)
	sellPrompt:InputHoldBegin()
	task.wait(0.08)
	sellPrompt:InputHoldEnd()
	waitFor(function()
		return overlay.Visible and menu.Status["Sell all"].Interactable and not sellPrompt.Enabled
	end, 4, "tap opens sell menu")
	assert(p:GetAttribute("Used") == starterSlots and p:GetAttribute("Gold") == 0, "a tap must not sell the pack")
	expectGuideArrow(menu.Status["Sell all"])
	local selected
	for _, ore in ores.list do
		if ore.host and p:GetAttribute("Held" .. ore.name) > 1 then
			selected = ore
			break
		end
	end
	local row = menu.Listings[selected.name]
	local initial = p:GetAttribute("Held" .. selected.name)
	assert(row.Visible and row["Sell quantity"].Interactable and row["Select stack"].Interactable)
	assert(row.Stock.RichText and row.Stock.Text:find("×" .. initial .. "</font>", 1, true))
	assert(row["Unit price"].Text:lower():find('<font color="#ffd14c">' .. selected.value .. " g each</font>", 1, true))
	assert(not row["Unit price"].ContentText:find("needs", 1, true), "sell counter reserves ore for gear")
	local portion = math.min(initial - 1, 3)
	n.Action:FireServer("Sell", selected.name, portion)
	waitFor(function()
		return p:GetAttribute("Used") == starterSlots - portion and p:GetAttribute("Gold") == selected.value * portion
	end, 3, "sell chosen quantity")
	task.wait(0.22)
	n.Action:FireServer("Sell", selected.name, "Stack")
	waitFor(function()
		return p:GetAttribute("Used") == starterSlots - initial and not row["Select stack"].Interactable
	end, 3, "sell one material")
	assert(p:GetAttribute("Gold") == selected.value * initial and overlay.Visible)
	local saleGold = value
	task.wait(0.25)
	n.Action:FireServer("Sell")
	waitFor(function()
		return p:GetAttribute("Used") == 0 and p:GetAttribute("Gold") == saleGold
	end, 3, "sell the entire remaining haul")
	assert(p:GetAttribute("ExpeditionStep") == "Upgrade", "sale advanced the expedition")
	expectGuideArrow(menu.Marquee.Close)
	r:FireServer("closePage")
	waitFor(function() return not overlay.Visible and sellPrompt.Enabled end, 3, "return to sell prompt")
	n.Action:FireServer("Buy", "Capacity")
	task.wait(0.4)
	assert(p:GetAttribute("Capacity") == 1 and p:GetAttribute("Gold") == saleGold, "workshop must require a visit")
	visit("Supplies", true)
	waitFor(function() return menu.Listings:FindFirstChild("Survey flare") end, 3, "Field Supplies")
	assert(not menu.Listings:FindFirstChild("Coal") and not menu.Listings:FindFirstChild("Copper"))
	n.Action:FireServer("Supply", "Coal")
	task.wait(0.3)
	assert(p:GetAttribute("HeldCoal") == 0 and p:GetAttribute("Gold") == saleGold)
	visit("Gear", true)
	for key, price in { Speed = 30, Power = 110, Capacity = 8 } do
		waitFor(function()
			local gear = menu.Listings:FindFirstChild(key)
			local affordable = saleGold >= price
			return gear and gear.Requirements.ContentText == (if affordable then "✓ " else "× ") .. price .. " G"
				and gear.Action.Interactable == affordable
		end, 3, "correct cost of " .. key .. " after selling")
	end
	do
		local upgrades = require(rep.Shared.Upgrades)
		for gold, key in { [0] = "Capacity", [7] = "Capacity", [8] = "Capacity", [29] = "Capacity", [30] = "Speed" } do
			local suggested, price = upgrades.onboardingPick(gold)
			assert(suggested == key and price == upgrades.price(key, 1))
		end
		local pick = upgrades.onboardingPick(saleGold)
		expectGuideArrow(menu.Listings[pick].Action)
		assert(not menu.Listings.Power.Action:FindFirstChild("Guide highlight"), "only one upgrade cue at a time")
	end
	n.Action:FireServer("Buy", "Capacity")
	waitFor(function()
		return p:GetAttribute("Capacity") == 2 and p:GetAttribute("PackSlots") == 16 and p:GetAttribute("Gold") == saleGold - 8
	end, 5, "buy backpack with sale gold alone")
	assert(p:GetAttribute("Used") == 0)
	assert(kit["Field pack"].Size.Magnitude > packSize.Magnitude, "pack grew after capacity upgrade")
	assert(p:GetAttribute("ExpeditionStep") == "Return", "any workshop upgrade counts")
	expectGuideArrow(menu.Marquee.Close)
	r:FireServer("position")
	waitFor(function()
		return (p.Character.Head.Position - origin).Z < 0 and not overlay.Visible
	end, 5, "leave workshop")
	for i = 1, 6 do
		dig(2)
		task.wait(0.12)
	end
	assert(p:GetAttribute("Used") == 0, "multi-block request was accepted")
	local upgradeSlots = p:GetAttribute("PackSlots")
	local secondSale = 0
	for i = 1, 100 do
		if p:GetAttribute("Mined") == 40 then break end
		if p:GetAttribute("Used") == upgradeSlots then
			secondSale = p:GetAttribute("BagValue")
			visit("Sell", true)
			waitFor(function() return p:GetAttribute("Used") == 0 end, 5, "sell the full upgraded pack")
			r:FireServer("position")
			waitFor(function() return (p.Character.Head.Position - origin).Z < 0 and not overlay.Visible end, 5, "back to mine")
		end
		dig(1)
		task.wait(0.14)
	end
	assert(secondSale > 0 and p:GetAttribute("Used") == 40 - starterSlots - upgradeSlots, "second and third mining trips")
	assert(p:GetAttribute("ExpeditionStep") == "Done", "new gear tested in the field")
	assert(discovered and p:GetAttribute("Found" .. discovered) and p:GetAttribute("Mined") == 40, "ore discovery and lifetime blocks")
	n.Action:FireServer("Job", 2)
	n.Action:FireServer("Job", 1)
	waitFor(function()
		return p:GetAttribute("Jobs") == 2 and p:GetAttribute("ClaimedJobs") == 3
	end, 5, "two eligible jobs claimed back to back in reverse order")
	r:FireServer("openPage", "Book")
	waitFor(function()
		return p:GetAttribute("SeenBookDirt") and menu.Listings.Dirt:FindFirstChildOfClass("UIStroke").Enabled
	end, 5, "reading a discovered ore")
	r:FireServer("openPage", "Book")
	waitFor(function()
		local stroke = menu.Listings.Dirt:FindFirstChildOfClass("UIStroke")
		return stroke and not stroke.Enabled
	end, 4, "seen ore stays read on return")
	r:FireServer("openPage", "Achievements")
	waitFor(function()
		return menu.Visible and menu.Listings:FindFirstChild("Pet Rock, Proper Noun")
	end, 4, "achievement list")
	task.wait(0.55)
	assert(not p:GetAttribute("SeenAchievementsPetName"), "offscreen achievement incorrectly marked read")
	local petAward = menu.Listings["Pet Rock, Proper Noun"]
	menu.Listings.CanvasPosition = Vector2.new(
		0,
		petAward.AbsolutePosition.Y - menu.Listings.AbsolutePosition.Y - menu.Listings.AbsoluteWindowSize.Y * 0.4
	)
	waitFor(function()
		return p:GetAttribute("SeenAchievementsPetName")
	end, 5, "scroll reads new achievement")
	local afterJob = p:GetAttribute("Gold")
	assert(afterJob == saleGold - 8 + secondSale + 80 + 25)
	task.wait(0.25)
	n.Action:FireServer("Job", 2)
	task.wait(0.3)
	assert(p:GetAttribute("Gold") == afterJob, "repeat claim")
	visit("Store", true)
	n.Action:FireServer("PreviewPass", "DoubleGold")
	waitFor(function()
		return p:GetAttribute("DoubleGold")
	end, 5, "studio pass preview")
	local double = p:GetAttribute("BagValue") * 2
	visit("Sell", true)
	waitFor(function()
		return p:GetAttribute("Gold") == afterJob + double and gui.SafeArea:FindFirstChild("Sale receipt")
	end, 5, "double sale")
	assert(p:GetAttribute("Used") == 0 and not overlay.Visible, "hold quick-sell empties the pack")
	visit("Store", true)
	n.Action:FireServer("PreviewPass", "PrismTrail")
	waitFor(function()
		return p.Character.HumanoidRootPart:FindFirstChild("Prism Ribbon")
	end, 5, "equipped trail")
	for _, enabled in { false, true } do
		n.Action:FireServer("Preference", "TrailEnabled", enabled)
		waitFor(function()
			return p.Character.HumanoidRootPart["Prism Ribbon"].Enabled == enabled
		end, 3, "toggle owned trail")
	end
	local coastalAir = assert(game.Lighting:FindFirstChildOfClass("Atmosphere"))
	local outdoorDistance = game.Lighting.FogEnd
	r:FireServer("minedShaft")
	waitFor(function()
		local blocks = p:GetAttribute("TestShaftDepth")
		return blocks
			and blocks >= 1
			and gui.SafeArea.Location.Depth.Text
				== (if blocks == 1 then "1 block deep" else blocks .. " blocks deep")
	end, 4, "return starts inside the mined shaft")
	waitFor(function()
		return coastalAir.Parent ~= game.Lighting and game.Lighting.FogEnd < outdoorDistance
	end, 3, "entering the actual shaft limits distant visibility")
	n.Action:FireServer("Surface")
	local passage = p.PlayerGui.SurfaceReturn
	waitFor(function()
		return passage.Enabled
	end, 2, "surface fade begins")
	local departed = os.clock()
	local landing = n:GetAttribute("Entrance")
	waitFor(function()
		return (p.Character.HumanoidRootPart.Position - landing).Magnitude < 8
	end, 5, "surface recall")
	waitFor(function()
		return not passage.Enabled
	end, 6, "surface fade completed")
	assert(coastalAir.Parent == game.Lighting and game.Lighting.FogEnd == outdoorDistance, "return restores the original sky")
	assert(os.clock() - departed > 0.6 and not song.IsPlaying, "depth travel and test mute")
	do
		local other
		r:FireServer("readyForPracticeReset")
		waitFor(function()
			for _, miner in game.Players:GetPlayers() do
				if miner ~= p then other = miner end
			end
			return other and other:GetAttribute("ReadyForPracticeReset")
		end, 35, "both practice miners are ready")
		if p.UserId < other.UserId then
			n.Action:FireServer("ResetProgress", 0)
			waitFor(function()
				return p:GetAttribute("ProgressResets") == 1 and p:GetAttribute("Capacity") == 1
					and p.leaderstats.Depth.Value == 0 and p:GetAttribute("Jobs") == 0
					and not p:GetAttribute("SeenBookDirt") and p:GetAttribute("AwardPetName") == 0
			end, 4, "reset clears gear, depth, jobs, achievements and read markers")
			assert(p:GetAttribute("PetName") == "Pebble" and p:GetAttribute("Pet") == "")
			assert(p:GetAttribute("PrismTrail") and p:GetAttribute("DoubleGold"), "passes survive reset")
			n.Action:FireServer("Pet", "Rock")
			n.Action:FireServer("ResetProgress", 0)
			waitFor(function() return p:GetAttribute("Pet") == "Rock" end, 2, "fresh miner can equip a pet")
			task.wait(0.3)
			assert(p:GetAttribute("Pet") == "Rock" and p:GetAttribute("ProgressResets") == 1, "stale confirmation")
		else
			waitFor(function() return other:GetAttribute("ProgressResets") == 1 end, 5, "peer reset")
			assert(p:GetAttribute("Gold") == afterJob + double and p:GetAttribute("Capacity") == 2 and p:GetAttribute("Jobs") == 2)
		end
	end
	return string.format(
		"40 blocks, %d gold sale, larger pack, physical ore index, settings, entrance return (%.1fs)",
		saleGold,
		os.clock() - first
	)
end
local ok, result = pcall(test)
r:FireServer(if ok then "passed" else "failed", tostring(result))
