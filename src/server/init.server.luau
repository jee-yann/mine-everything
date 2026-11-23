local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Config, Upgrades = require(Rep.Shared.GameConfig), require(Rep.Shared.Upgrades)
local World, MineSite = require(script.MineWorld), require(script.MineSite)
local E, Guide = require(Rep.Shared.Expeditions), require(Rep.Shared.FieldGuide)
local Ores = require(Rep.Shared.Ores)
local Purity = require(Rep.Shared.OrePurity)
local Materials = require(Rep.Shared.Materials)
local Field = require(Rep.Shared.FieldRewards)
local Pulse = require(script.MinePulse)
local Skills = require(Rep.Shared.Skills)
local Flare = require(script.SurveyFlare)
local Preferences = require(Rep.Shared.Preferences)
local Passes = require(script.Passes)
local equipKit = require(script.ProspectorKit)
local Pickaxe = require(script.Pickaxe)
local Data, Profile, Mining = require(script.DataService), require(script.Profile), require(script.MiningService)
local PIXELII_USER_ID = 45241447

local surface = workspace:WaitForChild("CitrineCove")
local seeds = Random.new()
local studioSeed = if game:GetService("RunService"):IsStudio() then script:GetAttribute("StudioMineSeed") else nil
local world = World.new(studioSeed or seeds:NextInteger(1, 2147483646), surface)
local site = MineSite.bind(surface, world)
local landing = site.spawn.Position + Vector3.yAxis * 4
local minePath = surface["Sand path and bridge"]["Portal paving"]
local entrance = minePath.Position + Vector3.yAxis * (minePath.Size.Y / 2 + 3.5)
local net = Instance.new("Folder")
net.Name = "EndlessMiningNet"
net:SetAttribute("Origin", world.origin)
net:SetAttribute("Landing", landing)
net:SetAttribute("Entrance", entrance)
net:SetAttribute("DigFloor", world.origin + Vector3.new(0, Config.FloorY, (Config.HallFront + Config.HallBack) / 2))
net:SetAttribute("DigFloorSize", Vector3.new(2 * Config.HallHalfWidth, Config.Cell, Config.HallFront - Config.HallBack))
net:SetAttribute("Ready", false)
net:SetAttribute("OrderDay", math.floor(os.time() / 86400))
for _, name in { "Mine", "Action", "Feedback", "Dust", "Swing" } do
	local event = Instance.new(if name == "Dust" then "UnreliableRemoteEvent" else "RemoteEvent")
	event.Name, event.Parent = name, net
end
net.Parent = Rep

local sessions, loading, closing, nextAction = {}, {}, {}, {}
local shuttingDown = false
local function updateShift(player, session, now)
	Field.trackShift(session, now)
	local p = session.profile
	local index = p.shiftClaims + 1
	local prize = Field.shiftRewards[index]
	local due = if not prize then nil elseif p.shiftSeconds >= prize.seconds then 0 else now + prize.seconds - p.shiftSeconds
	if player:GetAttribute("ShiftPrize") ~= index then player:SetAttribute("ShiftPrize", index) end
	if player:GetAttribute("ShiftReadyAt") ~= due then player:SetAttribute("ShiftReadyAt", due) end
end
local function applySkills(player, p)
	local char = player.Character
	if not char then
		return
	end
	local human = char:FindFirstChildOfClass("Humanoid")
	if not human then
		return
	end
	local owned = p.skills
	char:SetAttribute("PickReach", Config.Reach + Skills.bonus(owned, "reach"))
	human.WalkSpeed = Skills.walkSpeed(owned, p.bag, Profile.used(p), Profile.stat(p, "Capacity"))
	local jump = 1 + (Skills.bonus(owned, "jump") + (if owned.Summit then 10 else 0)) / 100
	human.JumpHeight = game.StarterPlayer.CharacterJumpHeight * jump
	human.JumpPower = game.StarterPlayer.CharacterJumpPower * math.sqrt(jump)
	local lamp = char:FindFirstChild("Mining lamp", true)
	if lamp then
		lamp.Range = 25 + Skills.bonus(owned, "lamp")
	end
end
local function sync(player, p, awardName)
	player:SetAttribute("Level", E.level(p.xp))
	player:SetAttribute("EquippedTitle", Guide.selectedTitle(p))
	player:SetAttribute("Pet", p.pet)
	player:SetAttribute("DrakeUnlocked", p.drake == true)
	player:SetAttribute("PetName", p.petName)
	player:SetAttribute("SkillPoints", Guide.points(p.xp, p.skills))
	player.leaderstats.Level.Value = E.level(p.xp)
	player:SetAttribute("Gold", p.gold)
	player:SetAttribute("Gems", p.gems)
	player:SetAttribute("StampDay", p.stampDay)
	player:SetAttribute("StampCount", p.stampCount)
	player:SetAttribute("HasteCuts", p.hasteCuts)
	player:SetAttribute("StoneChips", p.stoneChips)
	player:SetAttribute("CavePulses", p.pulses)
	player:SetAttribute("OreCompass", p.oreCompass == true)
	player:SetAttribute("AuraUnlocked", Profile.hasUpgrade(p))
	player:SetAttribute("FirstLight", Profile.hasUpgrade(p) and not p.auraOff)
	player:SetAttribute("Used", Profile.used(p))
	player:SetAttribute("PackSlots", Profile.stat(p, "Capacity"))
	if p.skills.PackMule or p.skills.Rockhound then
		applySkills(player, p)
	end
	player:SetAttribute("BagValue", Profile.value(p.bag, p.grades, p.skills.Broker))
	player:SetAttribute("Flares", p.flares)
	player:SetAttribute("TemperCharges", p.temper)
	player:SetAttribute("DailyClaim", p.dailyClaim)
	player:SetAttribute("Mined", p.mined)
	player:SetAttribute("ExpeditionStep", Profile.expeditionStep(p))
	player:SetAttribute("MiningXP", p.xp)
	player:SetAttribute("Jobs", p.jobs)
	player:SetAttribute("ClaimedJobs", p.claimedJobs)
	for _, award in Guide.achievements do
		player:SetAttribute("Award" .. award.id, Guide.progress(p, award))
	end
	for _, ore in Ores.list do
		player:SetAttribute("Lifetime" .. ore.name, p.counts[ore.name] or 0)
		player:SetAttribute("Held" .. ore.name, p.bag[ore.name] or 0)
		if not ore.host then
			player:SetAttribute("Grades" .. ore.name, Purity.encode(p.grades[ore.name]))
			player:SetAttribute("BestPurity" .. ore.name, p.bestPurity[ore.name] or 0)
		end
		player:SetAttribute("Found" .. ore.name, p.discoveries[ore.name] == true)
	end
	for _, key in Upgrades.order do
		player:SetAttribute(key, p.levels[key])
	end
	player.leaderstats.Gold.Value = p.gold
	player.leaderstats.Depth.Value = Profile.depthRecord(p)
	if awardName then
		net.Feedback:FireClient(player, "achievement", awardName)
	end
end
local Ascent = require(script.Ascent)
local function moveCharacter(character, destination)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local owner = Players:GetPlayerFromCharacter(character)
		local session = owner and sessions[owner]
		if session then
			session.climb = nil
		end
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		character:PivotTo(destination)
	end
end
local function mineFit(char, inside)
	local base = char:GetAttribute("SurfaceScale")
	if inside and not base then
		base = char:GetScale()
		local head = char:FindFirstChild("Head")
		local foot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg")
		if head and foot then
			local height = head.Position.Y + head.Size.Y / 2 - foot.Position.Y + foot.Size.Y / 2
			char:SetAttribute("SurfaceScale", base)
			local clearance = Config.Cell - 0.5
			char:ScaleTo(base * math.min(1, clearance / math.max(height, clearance)))
		end
	elseif not inside and base then
		char:ScaleTo(base)
		char:SetAttribute("SurfaceScale", nil)
	end
end
local function onCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or player.Character ~= character then
		return
	end
	moveCharacter(character, CFrame.new(landing))
	-- Avatar appearance can replace the head after spawn. Keep the light on the rig.
	if not root:FindFirstChild("Lamp mount") then
		local mount = Instance.new("Attachment")
		local head = character:FindFirstChild("Head")
		mount.Name = "Lamp mount"
		mount.Position = if head then root.CFrame:PointToObjectSpace(head.Position) else Vector3.new(0, 1.5, 0)
		local lamp = Instance.new("PointLight")
		lamp.Name, lamp.Color, lamp.Range, lamp.Brightness = "Mining lamp", Color3.fromRGB(255, 236, 213), 25, 0.8
		lamp.Shadows = true
		lamp.Parent, mount.Parent = mount, root
	end
	if sessions[player] then
		applySkills(player, sessions[player].profile)
	end
	task.spawn(equipKit, player, character)
	task.spawn(Pickaxe.equip, player, character)
end
local function join(player)
	if loading[player] or sessions[player] or shuttingDown then
		return
	end
	loading[player] = true
	Passes.join(player)
	player.RespawnLocation = site.spawn
	player.CharacterAppearanceLoaded:Connect(function(char)
		task.spawn(equipKit, player, char)
		Pickaxe.equip(player, char)
	end)
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
	local session = Data.open(player)
	if player.Parent ~= Players or shuttingDown then
		Data.save(player, session, true)
		loading[player] = nil
		return
	end
	local board = Instance.new("Folder")
	board.Name = "leaderstats"
	for _, name in { "Level", "Gold", "Depth" } do
		local stat = Instance.new("IntValue")
		stat.Name, stat.Parent = name, board
	end
	board.Parent = player
	sessions[player], loading[player] = session, nil
	updateShift(player, session, os.time())
	for key, value in session.profile.preferences do
		player:SetAttribute(key, value)
	end
	for entry in session.profile.viewed do
		player:SetAttribute("Seen" .. entry, true)
	end
	for _, node in Skills.nodes do
		player:SetAttribute("Skill" .. node.id, session.profile.skills[node.id] == true)
	end
	sync(player, session.profile)
	applySkills(player, session.profile)
	player:SetAttribute("IntroSeen", session.profile.introSeen)
	player:SetAttribute("ProfileReady", true)
	if player.UserId == PIXELII_USER_ID then
		local gui = Instance.new("ScreenGui")
		gui.Name, gui.ResetOnSpawn = "OwnerOreVision", false
		require(script.OreVision)(gui, player, world)
		script.OwnerOreVision:Clone().Parent = gui
		gui.Parent = player:WaitForChild("PlayerGui")
	end
end
world.grid.onFeature = function(player, kind, item)
	local s, char = sessions[player], player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local human = char and char:FindFirstChildOfClass("Humanoid")
	if
		not s
		or s.resetting
		or s.travel
		or not world.ready
		or not human
		or human.Health <= 0
		or not root
		or not item:IsDescendantOf(world.grid.folder)
	then
		return false
	end
	local delta = root.Position - item.Position
	if kind == "Lava" then
		if
			math.abs(delta.X) > item.Size.X / 2 + 1.55
			or math.abs(delta.Z) > item.Size.Z / 2 + 1.55
			or math.abs(delta.Y) > 5
			or os.clock() < (s.lavaUntil or 0)
		then
			return false
		end
		s.lavaUntil = os.clock() + 2
		local lost = Profile.spill(s.profile)
		moveCharacter(char, CFrame.lookAt(entrance, entrance - Vector3.zAxis))
		sync(player, s.profile)
		net.Feedback:FireClient(
			player,
			"hint",
			if lost == 0
				then "Lava rescue · Your pack is safe"
				else string.format("Lava rescue · Lost %d carried block%s", lost, if lost == 1 then "" else "s")
		)
		return true
	end
	if delta.Magnitude > 10 then
		return false
	end
	local depth = Config.depthInBlocks(world.origin.Y - item.Position.Y)
	local gold = 25 + 5 * math.floor(depth / 10)
	s.profile.gold += gold
	s.profile.flares += 1
	local hatched = kind == "Egg" and not s.profile.drake
	if hatched then
		s.profile.drake = true
	end
	sync(player, s.profile)
	net.Feedback:FireClient(player, "caveCache", gold, hatched)
	return true
end
local function leave(player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player], closing[player], nextAction[player] = nil, true, nil
	Data.save(player, session, true)
	closing[player] = nil
end

local function atCounter(player, prompt)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	return root
		and humanoid
		and humanoid.Health > 0
		and (root.Position - prompt.Parent.Position).Magnitude <= prompt.MaxActivationDistance + 1
end

local counterFor =
	{ Sell = "Sell", Buy = "Shop", PreviewPass = "Store", Pass = "Store", Supply = "Supplies", Deliver = "Jobs" }
local function action(player, key, option, value)
	local s = sessions[player]
	if not s or type(key) ~= "string" then
		return
	end
	if key == "ResetProgress" then
		if not Config.AllowProgressReset or s.resetting then
			return
		end
		if option ~= (s.resetCount or 0) or shuttingDown or s.travel then
			net.Feedback:FireClient(player, "progressReset", false, "Reopen Settings and try again.")
			return
		end
		local previous = s.profile
		local ok, message = Data.resetProgress(player, s)
		if sessions[player] ~= s or player.Parent ~= Players then
			return
		end
		if ok then
			s.resetCount = (s.resetCount or 0) + 1
			player:SetAttribute("ProgressResets", s.resetCount)
			for entry in previous.viewed do
				player:SetAttribute("Seen" .. entry, nil)
			end
			for id in previous.skills do
				player:SetAttribute("Skill" .. id, false)
			end
			local char = player.Character
			if char then
				char:SetAttribute("MiningSwing", nil)
				mineFit(char, false)
				moveCharacter(char, CFrame.new(landing))
			end
			s.climb, s.lavaUntil = nil, nil
			updateShift(player, s, os.time())
			sync(player, s.profile)
			applySkills(player, s.profile)
		end
		net.Feedback:FireClient(player, "progressReset", ok, message)
		return
	end
	if s.resetting then
		return
	end
	if key == "IntroSeen" then
		s.profile.introSeen = true
		player:SetAttribute("IntroSeen", true)
		return
	end
	if key == "SkipExpedition" then
		if Profile.expeditionStep(s.profile) ~= "Done" then
			s.profile.firstTrip.skipped = true
			player:SetAttribute("ExpeditionStep", "Skipped")
		end
		return
	end
	if key == "ReturnReady" then
		local travel = s.travel
		if travel and travel.id == option then
			s.travel = nil
			if player.Character == travel.character then
				mineFit(travel.character, false)
				applySkills(player, s.profile)
				moveCharacter(travel.character, CFrame.lookAt(entrance, entrance + Vector3.zAxis))
			end
			net.Feedback:FireClient(player, "arrive", option)
		end
		return
	end
	if key == "Viewed" then
		if Profile.markViewed(s.profile, option, value) then
			player:SetAttribute("Seen" .. option .. value, true)
		end
		return
	end
	if key == "Preference" then
		if option == "TrailEnabled" and not player:GetAttribute("PrismTrail") then
			return
		end
		if Preferences.valid(option, value) and s.profile.preferences[option] ~= value then
			s.profile.preferences[option] = value
			player:SetAttribute(option, value)
		end
		return
	end
	local now = os.clock()
	if
		key ~= "Surface"
		and key ~= "Sell"
		and key ~= "Buy"
		and key ~= "Job"
		and key ~= "Supply"
		and key ~= "Flare"
		and key ~= "Deliver"
		and key ~= "Stamp"
		and key ~= "ShiftPrize"
		and key ~= "Aura"
		and key ~= "Pulse"
		and key ~= "OwnerClear"
		and key ~= "PreviewPass"
		and key ~= "Title"
		and key ~= "Skill"
		and key ~= "Pet"
		and key ~= "PetName"
		and key ~= "Pass"
	then
		return
	end
	local times = nextAction[player]
	if not times then
		times = {}
		nextAction[player] = times
	end
	local actionKey = key
	if key == "Job" then
		if type(option) ~= "number" or option % 1 ~= 0 or not E.jobs[option] then
			return
		end
		actionKey = "Job" .. option
	end
	if now < (times[actionKey] or 0) then
		return
	end
	times[actionKey] = now + 0.18
	local station = counterFor[key]
	if station and not atCounter(player, site.stations[station]) then
		net.Feedback:FireClient(player, "away", station)
		return
	end
	local p = s.profile
	if key == "Stamp" then
		local day, gems = Field.claim(p, math.floor(os.time() / 86400))
		if day then
			sync(player, p)
			net.Feedback:FireClient(player, "hint", string.format("Day %d stamped! +%d gems", day, gems))
		end
	elseif key == "ShiftPrize" then
		local at = os.time()
		local gems = Field.claimShift(s, at, option)
		updateShift(player, s, at)
		if gems then
			sync(player, p)
			net.Feedback:FireClient(player, "hint", string.format("Shift reward! +%d %s", gems, if gems == 1 then "gem" else "gems"))
		end
	elseif key == "Aura" and type(option) == "boolean" and Profile.hasUpgrade(p) then
		p.auraOff = not option
		sync(player, p)
	elseif key == "OwnerClear" or key == "Pulse" then
		local owner = key == "OwnerClear"
		if s.travel or (owner and player.UserId ~= PIXELII_USER_ID) or (not owner and p.pulses < 1) then return end
		times[actionKey] = now + 2
		local count = Pulse.clear(world, player.Character, Profile.stat(p, "Power"), owner)
		if count > 0 then
			if not owner then p.pulses -= 1 end
			sync(player, p)
			net.Feedback:FireClient(player, "close")
			net.Feedback:FireClient(player, "pulse", player.Character.HumanoidRootPart.Position, Config.Cell * (if owner then 3.25 else 2.25))
			net.Feedback:FireClient(player, "hint", string.format("Cleared %d stone. The ore is yours to mine!", count))
		else
			net.Feedback:FireClient(player, "hint", "Stand near exposed stone underground.")
		end
	elseif key == "Supply" and type(option) == "string" then
		local ok, message = Profile.buySupply(p, option)
		if ok then
			sync(player, p)
		end
		net.Feedback:FireClient(player, "hint", message)
	elseif key == "Deliver" then
		local day = math.floor(os.time() / 86400)
		if Profile.deliver(p, day, option) then
			sync(player, p)
			local order = Materials.daily(day)
			net.Feedback:FireClient(
				player,
				"job",
				order.name .. (if p.skills.SupplyRunner then " (+2 gems, 2 flares)" else " (+2 gems, 1 flare)"),
				order.gold
			)
		end
	elseif key == "Flare" and p.flares > 0 and not s.travel then
		local ok, message = Flare.place(world, player.Character, p.skills)
		if ok then
			times.Flare = now + 2
			p.flares -= 1
			sync(player, p)
			net.Feedback:FireClient(player, "close")
		end
		net.Feedback:FireClient(player, "hint", message)
	elseif key == "Title" then
		if Profile.equipTitle(p, option) then
			sync(player, p)
		end
	elseif key == "Skill" then
		if type(option) == "string" then
			local learned, award = Profile.learn(p, option)
			if learned then
				player:SetAttribute("Skill" .. option, true)
				sync(player, p, award)
				applySkills(player, p)
				net.Feedback:FireClient(player, "skillLearned", option)
			end
		end
	elseif key == "Pet" then
		if option == "Rock" or option == "" or (option == "Drake" and p.drake) then
			p.pet = option
			sync(player, p)
		end
	elseif key == "PetName" then
		if type(option) ~= "string" or #option > 80 then
			return
		end
		local name = option:match("^%s*(.-)%s*$")
		local length = utf8.len(name)
		if not length or length < 1 or length > 20 then
			net.Feedback:FireClient(player, "hint", "Choose a name with 1–20 characters")
			return
		end
		if s.filteringPetName then
			return
		end
		if not Guide.petNames[name] then
			s.filteringPetName = true
			local ok, filtered = pcall(function()
				local result = game:GetService("TextService"):FilterStringAsync(name, player.UserId)
				return result:GetNonChatStringForBroadcastAsync()
			end)
			s.filteringPetName = nil
			if sessions[player] ~= s or s.profile ~= p or s.resetting then
				return
			end
			if not ok or not filtered or filtered == "" or filtered:find("#", 1, true) then
				net.Feedback:FireClient(player, "hint", "Try another name, or choose a suggested name")
				return
			end
			name = filtered
		end
		p.petName = name
		sync(player, p, if name ~= "Pebble" then Profile.unlock(p, "PetName") else nil)
	elseif key == "Surface" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if s.travel or not root then
			return
		end
		s.tripId = (s.tripId or 0) + 1
		local travel = { id = s.tripId, character = character }
		s.climb = nil
		s.travel = travel
		local depth = math.max(0, Config.depthInBlocks(world.origin.Y + Config.FloorY - root.Position.Y))
		net.Feedback:FireClient(player, "depart", travel.id, depth)
		task.delay(10, function()
			if s.travel == travel then
				s.travel = nil
				if player.Parent == Players then
					net.Feedback:FireClient(player, "arrive", travel.id)
				end
			end
		end)
	elseif key == "Sell" then
		local gold, award, quantity = Profile.sell(p, if player:GetAttribute("DoubleGold") then 2 else 1, option, value)
		if gold == nil then
			return
		end
		if quantity > 0 then
			sync(player, p, award)
		end
		net.Feedback:FireClient(player, "sale", gold, quantity, p.gold, option)
	elseif key == "Buy" and type(option) == "string" and Upgrades.items[option] then
		local hadAura = Profile.hasUpgrade(p)
		local ok, msg, award = Profile.buy(p, option)
		sync(player, p, award)
		net.Feedback:FireClient(player, if ok then "upgrade" else "hint", msg, option, p.levels[option])
		if ok and not hadAura then net.Feedback:FireClient(player, "aura", "First Light") end
	elseif key == "Job" then
		local job, award = Profile.claimJob(p, option)
		if job then
			sync(player, p, award)
			net.Feedback:FireClient(player, "job", job.title, job.reward)
		end
	elseif key == "PreviewPass" then
		Passes.preview(player, option)
	elseif key == "Pass" then
		Passes.prompt(player, option)
	end
end
net.Action.OnServerEvent:Connect(action)
site.samples.Triggered:Connect(function(player)
	if atCounter(player, site.samples) then net.Feedback:FireClient(player, "page", "Book") end
end)
for name, prompt in site.stations do
	if name == "Sell" or name == "Shop" or name == "Store" or name == "Supplies" then
		net:SetAttribute(name .. "Position", prompt.Parent.Position)
		net:SetAttribute(name .. "Range", prompt.MaxActivationDistance + 1)
	end
	prompt.Triggered:Connect(function(player)
		if not atCounter(player, prompt) then
			return
		end
		if name == "Sell" then
			action(player, "Sell")
		elseif name == "Shop" then
			net.Feedback:FireClient(player, "shop")
		else
			net.Feedback:FireClient(player, "page", name)
		end
	end)
end
Mining.start(world, net, sessions, sync)
require(script.Standings).start(site.court)
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(leave)
for _, player in Players:GetPlayers() do
	task.spawn(join, player)
end

task.spawn(function()
	while true do
		world:generate()
		local renewAt = os.clock() + Config.ResetSeconds
		net:SetAttribute("Ready", true)
		repeat
			task.wait(1)
			if next(world.grid.starterCuts) then
				local miners = {}
				for _, player in Players:GetPlayers() do
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if root then
						table.insert(miners, root.Position)
					end
				end
				world.grid:refreshStarter(os.clock(), miners)
			end
		until world.removed >= Config.ResetAfter or os.clock() >= renewAt
		net.Feedback:FireAllClients("resetSoon", Config.ResetWarning)
		task.wait(Config.ResetWarning)
		world.ready = false
		net:SetAttribute("Ready", false)
		for _, player in Players:GetPlayers() do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and Config.inMine(root.Position - world.origin) then
				mineFit(char, false)
				moveCharacter(char, CFrame.lookAt(entrance, entrance - Vector3.zAxis))
			end
		end
		local oldSeed = world.seed
		repeat
			world.seed = seeds:NextInteger(1, 2147483646)
		until world.seed ~= oldSeed
	end
end)
task.spawn(function()
	while task.wait(0.5) do
		local at = os.time()
		local day = math.floor(at / 86400)
		if net:GetAttribute("OrderDay") ~= day then
			net:SetAttribute("OrderDay", day)
		end
		for player, s in sessions do
			if s.resetting then
				continue
			end
			updateShift(player, s, at)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root then
				s.climb = nil
				continue
			end
			local localPos = root.Position - world.origin
			local mining = Config.inMine(localPos)
			if mining and localPos.Y < Config.FloorY then
				local cell = world.grid:cellAt(root.Position)
				local chunk, index = world.grid:slot(cell, false)
				mining = chunk ~= nil and chunk[index] ~= nil
			end
			local char = player.Character
			local human = char:FindFirstChildOfClass("Humanoid")
			if s.travel or not world.ready or not human or human.Health <= 0 or s.profile.earned.Ascent then
				s.climb = nil
			elseif Ascent.sample(s, char, localPos, mining, os.clock()) then
				sync(player, s.profile, Profile.unlock(s.profile, "Ascent"))
			end
			if mining ~= (char:GetAttribute("SurfaceScale") ~= nil) then
				mineFit(char, mining)
				applySkills(player, s.profile)
			end
			if mining then
				local blocks = Config.depthInBlocks(Config.FloorY - localPos.Y)
				if Profile.recordDepth(s.profile, blocks) then
					player.leaderstats.Depth.Value = blocks
				end
			elseif
				localPos.Y < -35
				or math.abs(localPos.X) > Config.SurfaceMax.X + 12
				or localPos.Z > Config.SurfaceMax.Z + 12
				or localPos.Z < Config.SiteMin.Z - 25
			then
				mineFit(player.Character, false)
				applySkills(player, s.profile)
				moveCharacter(player.Character, CFrame.new(landing))
			end
		end
	end
end)
task.spawn(function()
	while task.wait(Config.AutosaveSeconds) do
		for player, s in sessions do
			task.spawn(Data.save, player, s, false)
		end
	end
end)
game:BindToClose(function()
	shuttingDown = true
	for player in sessions do
		task.spawn(leave, player)
	end
	while next(sessions) or next(loading) or next(closing) do
		task.wait()
	end
end)
