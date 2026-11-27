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
-- A live server says out loud when playtest switches are still on or purchases have no IDs yet, so
-- it can't be missed before release (see the PR's "Before release" list).
if not game:GetService("RunService"):IsStudio() then
	local on = {}
	for _, flag in { "AllFxForTesting", "FreeUnconfiguredItems", "AllowProgressReset" } do
		if Config[flag] then table.insert(on, flag) end
	end
	local Shop, missing = require(Rep.Shared.StoreConfig), 0
	for _, list in { Shop.passes, Shop.products } do
		for _, item in list do
			if item.id == 0 and not item.retired then missing += 1 end
		end
	end
	if #on > 0 or missing > 0 then
		warn(string.format("Mine EVERYTHING! playtest build: %s on, %d purchase%s without an ID", if #on > 0 then table.concat(on, ", ") else "no flags",
			missing, if missing == 1 then "" else "s"))
	end
end
local Preferences = require(Rep.Shared.Preferences)
local Store, Collection, Cosmetics = require(script.Store), require(script.Collection), require(script.Cosmetics)
local Bonuses, C = require(Rep.Shared.Bonuses), require(Rep.Shared.Collectibles)
local Geodes, StoreConfig = require(Rep.Shared.Geodes), require(Rep.Shared.StoreConfig)
local equipKit = require(script.ProspectorKit)
local Pickaxe = require(script.Pickaxe)
local Rebirth = require(Rep.Shared.Rebirth)
local FriendsHere = require(script.FriendsHere)
local Data, Profile, Mining = require(script.DataService), require(script.Profile), require(script.MiningService)
local PIXELII_USER_ID = 45241447

local surface = workspace:WaitForChild("CitrineCove")
local seeds = Random.new()
local studioSeed = if game:GetService("RunService"):IsStudio() then script:GetAttribute("StudioMineSeed") else nil
local world = World.new(studioSeed or seeds:NextInteger(1, 2147483646), surface)
-- In Studio a Starfall waits in the first layer, so the find and the rebirth can be tried. Set the
-- StudioStarfall attribute on this script to false to turn it off. Tests and live servers never get it.
local function studioStarfall()
	if not game:GetService("RunService"):IsStudio() then return false end
	if Rep:GetAttribute("StudioStarfall") == true then return true end
	return script:GetAttribute("StudioStarfall") ~= false and not Rep:GetAttribute("MiningTestMode")
end
world.practiceStarfall = studioStarfall()
Rep:GetAttributeChangedSignal("StudioStarfall"):Connect(function()
	world.practiceStarfall = studioStarfall()
	if world.practiceStarfall and world.ready then world:plantStarfall() end
end)
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
local geodeRandom = Random.new()
-- What a miner's passes and boosts add up to right now (see Shared.Bonuses).
local function bonusState(player, p)
	return Bonuses.make(Store.benefits(player), p.col, p.rebirths, nil, os.time())
end
-- GiftClock is the moment today's play time counted from. It only moves when the clock is capped or reset.
local function updateGifts(player, session, now)
	Field.trackGifts(session, now)
	local p = session.profile
	local clock, shown = now - p.giftSeconds, player:GetAttribute("GiftClock")
	if p.giftSeconds >= Field.maxGiftTime and shown and shown <= clock then clock = shown end
	if not shown or math.abs(shown - clock) > 1 then player:SetAttribute("GiftClock", clock) end
	if player:GetAttribute("GiftClaims") ~= p.giftClaims then player:SetAttribute("GiftClaims", p.giftClaims) end
	if player:GetAttribute("GiftReset") ~= p.giftStart + Field.cooldown then player:SetAttribute("GiftReset", p.giftStart + Field.cooldown) end
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
	-- Worn trails add movement speed (Collectibles.speeds), on top of skills.
	human.WalkSpeed = Skills.walkSpeed(owned, p.bag, Profile.used(p), Profile.stat(p, "Capacity")) * (1 + C.wornSpeed(p.col) / 100)
	local jump = 1 + (Skills.bonus(owned, "jump") + (if owned.Summit then 10 else 0)) / 100
	human.JumpHeight = game.StarterPlayer.CharacterJumpHeight * jump
	human.JumpPower = game.StarterPlayer.CharacterJumpPower * math.sqrt(jump)
	local lamp = char:FindFirstChild("Mining lamp", true)
	if lamp then
		lamp.Range = 25 + Skills.bonus(owned, "lamp")
	end
end
-- Writes an attribute only when its value changed. sync runs after every cut and touches about 150
-- attributes, nearly all unchanged, so this keeps the per-cut replication small.
local function put(player, key, value)
	if player:GetAttribute(key) ~= value then player:SetAttribute(key, value) end
end
local function sync(player, p, awardName)
	put(player, "Level", E.level(p.xp))
	put(player, "EquippedTitle", Guide.selectedTitle(p))
	local encoded = Collection.encode(p.col, os.time())
	if player:GetAttribute("Collection") ~= encoded then
		put(player, "Collection", encoded)
	end
	put(player, "Trail", p.col.trail or "")
	put(player, "Ribbon", p.col.ribbon or "")
	put(player, "Aura", p.col.aura or "")
	-- What a Gold Bundle would pay right now, for the Shop to show.
	put(player, "GoldBundle", Store.goldCrate(p))
	put(player, "StarterBought", p.store.starter == true)
	put(player, "VipChestAt", p.store.vipAt or 0)
	p.bigPack = Store.benefits(player).BiggerPack == true
	put(player, "SkillPoints", Guide.points(p.xp, p.skills))
	put(player, "Rebirths", p.rebirths)
	put(player, "RunStarfalls", p.runStarfalls)
	put(player, "RunTrail", p.runTrail)
	player.leaderstats.Level.Value = E.level(p.xp)
	put(player, "Gold", p.gold)
	put(player, "StampDay", p.stampDay)
	put(player, "StampAt", p.stampAt)
	put(player, "StampCount", p.stampCount)
	put(player, "HasteCuts", p.hasteCuts)
	put(player, "StoneChips", p.stoneChips)
	put(player, "CavePulses", p.pulses)
	put(player, "OreCompass", p.oreCompass == true)
	put(player, "Used", Profile.used(p))
	put(player, "PackSlots", Profile.stat(p, "Capacity"))
	local trailSpeed = C.wornSpeed(p.col)
	if p.skills.PackMule or p.skills.Rockhound or player:GetAttribute("TrailSpeed") ~= trailSpeed then
		put(player, "TrailSpeed", trailSpeed)
		applySkills(player, p)
	end
	put(player, "BagValue", Profile.value(p.bag, p.grades, p.skills.Broker))
	put(player, "Flares", p.flares)
	put(player, "TemperCharges", p.temper)
	put(player, "DailyClaim", p.dailyClaim)
	put(player, "Mined", p.mined)
	put(player, "ExpeditionStep", Profile.expeditionStep(p))
	put(player, "MiningXP", p.xp)
	put(player, "Jobs", p.jobs)
	put(player, "ClaimedJobs", p.claimedJobs)
	for _, award in Guide.achievements do
		put(player, "Award" .. award.id, Guide.progress(p, award))
	end
	for _, ore in Ores.list do
		put(player, "Lifetime" .. ore.name, p.counts[ore.name] or 0)
		put(player, "Held" .. ore.name, p.bag[ore.name] or 0)
		if not ore.host then
			put(player, "Grades" .. ore.name, Purity.encode(p.grades[ore.name]))
			put(player, "BestPurity" .. ore.name, p.bestPurity[ore.name] or 0)
		end
		put(player, "Found" .. ore.name, p.discoveries[ore.name] == true)
	end
	for _, key in Upgrades.order do
		put(player, key, p.levels[key])
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
		-- No shadows from the server copy: each client turns on shadows for its own lamp only.
		lamp.Shadows = false
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
	Store.join(player)
	Cosmetics.join(player)
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
	Collection.passRewards(session.profile.col, Store.benefits(player), session.profile.preferences.TrailEnabled)
	updateGifts(player, session, os.time())
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
	-- A drake egg deep in the mine holds a Starfall Crate.
	local egg = kind == "Egg"
	if egg then
		s.profile.col.items.StarfallGeode = (s.profile.col.items.StarfallGeode or 0) + 1
	end
	sync(player, s.profile)
	net.Feedback:FireClient(player, "caveCache", gold, egg)
	return true
end
local function leave(player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player], closing[player], nextAction[player] = nil, true, nil
	Store.leave(player)
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

local counterFor = { Sell = "Sell", Buy = "Shop", Supply = "Supplies" }

-- Sells the whole pack wherever the miner is (Sell Anywhere, Auto-Sell). Returns the gold.
local function sellAll(player)
	local s = sessions[player]
	if not s or s.resetting then return 0 end
	local p = s.profile
	local gold, award, quantity = Profile.sell(p, Bonuses.gold(bonusState(player, p)))
	if gold and quantity > 0 then
		sync(player, p, award)
		net.Feedback:FireClient(player, "sale", gold, quantity, p.gold, nil, "anywhere")
	end
	return gold or 0
end

-- Everyone hears about Server Luck, with the buyer's name and how long it lasts.
local function announceServerLuck(buyer)
	local left = math.max(0, (Rep:GetAttribute("ServerLuckUntil") or 0) - os.time())
	for _, other in Players:GetPlayers() do
		net.Feedback:FireClient(other, "serverLuck", buyer.DisplayName, math.ceil(left / 60), other == buyer)
	end
end

-- Opens one of the miner's crates and shows them what was inside. Legendary and better is announced.
local function openCrate(player, geodeId)
	local s = sessions[player]
	if not s or s.resetting then return false end
	local p = s.profile
	local reward, result = Collection.open(p, geodeId or "Starfall", geodeRandom)
	if not reward then
		net.Feedback:FireClient(player, "hint", result)
		return false
	end
	local award = Profile.unlock(p, "FirstCrate")
	sync(player, p, award)
	net.Feedback:FireClient(player, "geode", geodeId or "Starfall", reward.kind, reward.id, reward.count or 1, result)
	local entry = Geodes.entry(reward)
	if C.rarities[entry.rarity].rank >= C.rarities.Legendary.rank then
		for _, other in Players:GetPlayers() do
			net.Feedback:FireClient(other, "geodeAnnounce", player.DisplayName, entry.name, entry.rarity)
		end
	end
	return true
end

-- After a skill reset: every skill is unlearned and its points are back to spend.
local function resetSkills(player)
	local s = sessions[player]
	if not s then return end
	for _, node in Skills.nodes do
		player:SetAttribute("Skill" .. node.id, false)
	end
	applySkills(player, s.profile)
end

local storeContext = {
	openCrate = openCrate,
	resetSkills = resetSkills,
	sessions = sessions,
	saveNow = Data.saveNow,
	sellAll = sellAll,
	announce = announceServerLuck,
	sync = function(player, p) sync(player, p) end,
	feedback = function(player, ...) net.Feedback:FireClient(player, ...) end,
}
Store.onChange = function(player)
	local s = sessions[player]
	if s then
		Collection.passRewards(s.profile.col, Store.benefits(player), s.profile.preferences.TrailEnabled)
		sync(player, s.profile)
	end
end
Store.start(storeContext)
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
			-- Bought pass rewards come back with the fresh collection.
			Collection.passRewards(s.profile.col, Store.benefits(player), s.profile.preferences.TrailEnabled)
			updateGifts(player, s, os.time())
			sync(player, s.profile)
			applySkills(player, s.profile)
		end
		net.Feedback:FireClient(player, "progressReset", ok, message)
		return
	end
	if key == "Rebirth" then
		-- `option` is the rebirth count the client saw, so a repeated request can't rebirth twice.
		if s.resetting or shuttingDown or s.travel or option ~= s.profile.rebirths then
			return
		end
		local count = Profile.rebirth(s.profile)
		if not count then
			net.Feedback:FireClient(player, "rebirth", false, "Mine a Starfall this run to rebirth.")
			return
		end
		local char = player.Character
		if char then
			char:SetAttribute("MiningSwing", nil)
			mineFit(char, false)
			moveCharacter(char, CFrame.new(landing))
			task.spawn(Pickaxe.equip, player, char)
		end
		s.climb, s.lavaUntil = nil, nil
		sync(player, s.profile)
		applySkills(player, s.profile)
		task.spawn(Data.save, player, s)
		net.Feedback:FireClient(player, "rebirth", true, count)
		for _, other in Players:GetPlayers() do
			if other ~= player then
				net.Feedback:FireClient(other, "rebirthAnnounce", player.DisplayName, count)
			end
		end
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
		and key ~= "JobAll"
		and key ~= "JoinFriend"
		and key ~= "Supply"
		and key ~= "Flare"
		and key ~= "Deliver"
		and key ~= "Stamp"
		and key ~= "Gift"
		and key ~= "Pulse"
		and key ~= "OwnerClear"
		and key ~= "Title"
		and key ~= "Skill"
		and key ~= "OpenGeode"
		and key ~= "Wear"
		and key ~= "UseItem"
		and key ~= "BuyPass"
		and key ~= "BuyProduct"
		and key ~= "VipChest"
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
		-- A purchase asked for again too soon gets an answer, so the checkout screen never waits on it.
		if key == "BuyPass" or key == "BuyProduct" then net.Feedback:FireClient(player, "hint", "One moment…") end
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
		local perHour = Store.goldCrate(p)
		local ctx = { perHour = perHour, power = p.levels.Power, intro = p.col.intro }
		local day, reward = Field.claim(p, os.time(), perHour)
		if day then
			sync(player, p)
			net.Feedback:FireClient(player, "reward", "Daily", day, reward.name, Field.describe(reward, ctx))
		end
	elseif key == "Gift" then
		local at = os.time()
		local perHour = Store.goldCrate(p)
		local ctx = { perHour = perHour, power = p.levels.Power, intro = p.col.intro }
		local given = Field.claimGift(s, at, option, perHour)
		updateGifts(player, s, at)
		if given then
			sync(player, p)
			local last = given[#given]
			net.Feedback:FireClient(player, "reward", "Playtime", option,
				if #given > 1 then #given .. " gifts" else last.name, if #given > 1 then "All collected" else Field.describe(last, ctx))
		end
	elseif key == "OpenGeode" and type(option) == "string" and Geodes.byId[option] then
		-- Crates open from the inventory; they are bought with Robux in the Shop.
		if openCrate(player, option) then times[actionKey] = now + 0.6 end
	elseif key == "Wear" and type(option) == "string" then
		if Collection.wear(p.col, option, if type(value) == "string" then value else nil) then
			sync(player, p)
		end
	elseif key == "UseItem" and type(option) == "string" then
		local item, why = Collection.use(p.col, option, os.time())
		if not item then
			net.Feedback:FireClient(player, "hint", why)
			return
		end
		sync(player, p)
		net.Feedback:FireClient(player, "itemUsed", option)
	elseif (key == "BuyPass" or key == "BuyProduct") and type(option) == "string" then
		times[actionKey] = now + 1
		Store.prompt(player, s, if key == "BuyPass" then "pass" else "product", option, storeContext)
	elseif key == "VipChest" then
		local given, why = Store.vipChest(player, s)
		if given then
			sync(player, p)
			net.Feedback:FireClient(player, "reward", "VIP", 0, "Starfall Crate", "Your VIP crate is in your inventory")
		else
			net.Feedback:FireClient(player, "hint", why)
		end
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
				order.name .. (if p.skills.SupplyRunner then " (+2 Gold Tonics)" else " (+1 Gold Tonic)"),
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
		local gold, award, quantity = Profile.sell(p, Bonuses.gold(bonusState(player, p)), option, value)
		if gold == nil then
			return
		end
		if quantity > 0 then
			sync(player, p, award)
		end
		net.Feedback:FireClient(player, "sale", gold, quantity, p.gold, option)
	elseif key == "Buy" and type(option) == "string" and Upgrades.items[option] then
		local ok, msg, award = Profile.buy(p, option)
		sync(player, p, award)
		net.Feedback:FireClient(player, if ok then "upgrade" else "hint", msg, option, p.levels[option])
	elseif key == "Job" then
		local job, award = Profile.claimJob(p, option)
		if job then
			sync(player, p, award)
			net.Feedback:FireClient(player, "job", job.title, job.reward)
		end
	elseif key == "JobAll" then
		local count, gold, award = Profile.claimJobs(p)
		if count > 0 then
			sync(player, p, award)
			net.Feedback:FireClient(player, "job", count .. (if count == 1 then " job" else " jobs"), gold)
		end
	elseif key == "JoinFriend" then
		times[actionKey] = now + 4
		local problem = FriendsHere.join(player, option)
		if problem then net.Feedback:FireClient(player, "friend", problem) end
	end
end
net.Action.OnServerEvent:Connect(action)
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
-- Auto Sell (the timed boost) also empties a pack that was already full when it started, or that
-- filled some other way: once a second, anyone with Auto Sell running and a full pack sells.
task.spawn(function()
	while true do
		task.wait(1)
		for player, s in sessions do
			local p = s.profile
			if p and not s.resetting and Profile.used(p) >= Profile.stat(p, "Capacity")
				and Bonuses.autoSell(Bonuses.state(player)) then
				task.spawn(sellAll, player)
			end
		end
	end
end)
Mining.start(world, net, sessions, sync, {
	bonuses = bonusState,
	autoSell = function(player)
		-- The Auto Sell boost (and the old Auto-Sell benefit, if anyone still has it).
		if Store.benefits(player).AutoSell or Bonuses.autoSell(Bonuses.state(player)) then
			return sellAll(player) > 0
		end
		return false
	end,
})
FriendsHere.start()
require(script.Standings).start(site.court)
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(leave)
for _, player in Players:GetPlayers() do
	task.spawn(join, player)
end

-- Miners who were deep when the mine renewed, and the cell each one stood in.
local returns = {}
local function sendBack()
	for player, spot in returns do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if player.Parent == Players and char == spot.character and root and not Config.inMine(root.Position - world.origin) then
			-- A pocket where they stood, and a step of floor if the new rock there is a cave.
			world.grid:hollow(spot.cell)
			mineFit(char, true)
			moveCharacter(char, CFrame.new(world.grid:center(spot.cell)) * spot.facing)
			net.Feedback:FireClient(player, "hint", string.format("Back at your spot · %d blocks down", spot.depth))
		end
	end
	table.clear(returns)
end
task.spawn(function()
	while true do
		world:generate()
		sendBack()
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
		until os.clock() >= renewAt
		net.Feedback:FireAllClients("resetSoon", Config.ResetWarning)
		task.wait(Config.ResetWarning)
		world.ready = false
		net:SetAttribute("Ready", false)
		for _, player in Players:GetPlayers() do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and Config.inMine(root.Position - world.origin) then
				local depth = Config.depthInBlocks(world.origin.Y + Config.FloorY - root.Position.Y)
				if depth >= Config.ReturnDepth then
					returns[player] = { character = char, cell = world.grid:cellAt(root.Position), depth = depth,
						facing = root.CFrame.Rotation }
				end
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
			updateGifts(player, s, at)
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
