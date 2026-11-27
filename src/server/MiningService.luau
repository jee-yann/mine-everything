local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Pattern = require(Shared.BlockPattern)
local Profile = require(script.Parent.Profile)
local Expeditions = require(Shared.Expeditions)
local Skills = require(Shared.Skills)
local Rebirth = require(Shared.Rebirth)
local FriendBonus = require(Shared.FriendBonus)
local Bonuses = require(Shared.Bonuses)
local Mining = {}
local luckRandom = Random.new()

-- Free crates for progress: a Starfall Crate every 5th level (two every 25th), and one for every Starfall
-- mined. Returns the crate items given, in order.
function Mining.progressGeodes(col, oldLevel, level, ore)
	local given = {}
	local function give(n)
		for _ = 1, n do
			col.items.StarfallGeode = (col.items.StarfallGeode or 0) + 1
			table.insert(given, "StarfallGeode")
		end
	end
	for reached = oldLevel + 1, level do
		if reached % 25 == 0 then
			give(2)
		elseif reached % 5 == 0 then
			give(1)
		end
	end
	if ore == "Starfall" then give(1) end
	return given
end

-- A region's odds in percent, Stone included, for luck.
function Mining.regionChances(layer)
	local chances, total = {}, 0
	for name, percent in layer.oreChances do
		chances[name] = percent
		total += percent
	end
	chances.Stone = math.max(0, 100 - total)
	return chances
end

-- Luck: a cut that came up common (Stone or an ore at 1% or more) may turn out to hold one of the
-- region's rare ores instead, so each rare ore turns up exactly `luck` times as often. Returns the
-- rare ore's name, or nil.
function Mining.luckyFind(layer, name, luck, rng)
	if luck <= 1 then return nil end
	local chances = Mining.regionChances(layer)
	if (chances[name] or 0) < Bonuses.rareBelow then return nil end
	local roll = rng:NextNumber()
	for _, entry in Bonuses.upgrades(chances, luck) do
		roll -= entry[2]
		if roll < 0 then return entry[1] end
	end
	return nil
end

function Mining.validPoint(v)
	return typeof(v) == "Vector3" and v.Magnitude < 1e6
end

function Mining.target(world, character, point, normal)
	if not Mining.validPoint(point) or typeof(normal) ~= "Vector3" or not character then
		return nil
	end
	if normal:Abs() ~= Vector3.xAxis and normal:Abs() ~= Vector3.yAxis and normal:Abs() ~= Vector3.zAxis then
		return nil
	end
	local head, human = character:FindFirstChild("Head"), character:FindFirstChildOfClass("Humanoid")
	if not head or not human or human.Health <= 0 then
		return nil
	end
	local anchor = world.origin + (((point - world.origin) / Config.Cell):Floor() + Vector3.one * 0.5) * Config.Cell
	if (anchor - point).Magnitude > 0.03 or anchor.Y >= world.origin.Y + Config.FloorY then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	local part = Pattern.reachablePart(head.Position, anchor, normal, params, character:GetAttribute("PickReach"))
	if not part or part.Parent ~= world.grid.folder then
		return nil
	end
	return anchor
end

function Mining.selection(world, character, point, normal, power, space)
	local center = Mining.target(world, character, point, normal)
	if not center then
		return {}
	end
	return Pattern.select(world.origin, center, world:oreAt(center), power, space, world.grid:practice(world.grid:cellAt(center)))
end

function Mining.start(world, net, sessions, sync, hooks)
	hooks = hooks or {}
	local function state(player, p)
		return if hooks.bonuses then hooks.bonuses(player, p) else Bonuses.make({}, p.col, p.rebirths, 0, os.time())
	end
	local strokes, pending, nextInput, stagedSwing, nextSwing, lastHint, queue = {}, {}, {}, {}, {}, {}, {}
	local credit = Config.BurstCells
	local function hint(player, message, now)
		if now >= (lastHint[player] or 0) then
			lastHint[player] = now + 1.4
			net.Feedback:FireClient(player, "hint", message)
		end
	end

	local function beginStroke(player, character, point, normal, now)
		nextSwing[player] = now + 0.035
		local session = sessions[player]
		if not session or session.resetting or not world.ready then
			return
		end
		local p = session.profile
		local selected = Mining.selection(
			world,
			character,
			point,
			normal,
			Profile.stat(p, "Power"),
			Profile.stat(p, "Capacity") - Profile.used(p)
		)
		if #selected ~= 1 then
			strokes[player] = nil
			return
		end
		local ore = world:oreAt(point)
		-- Where and how they mine, for the depth, crowd and streak skills (the client reads the same).
		local ctx = {
			row = Config.depthInBlocks(Config.FloorY + world.origin.Y - point.Y),
			crowd = player:GetAttribute("NearMiner") == true,
			streak = player:GetAttribute("OreStreak") or 0,
		}
		local duration, tempered = Skills.cutTime(
			Profile.stat(p, "Speed") * Rebirth.cutMultiplier(p.rebirths),
			ore,
			Config.strength(point.Y - world.origin.Y),
			p.temper,
			p.skills,
			p.hasteCuts,
			p.stoneChips,
			Profile.stat(p, "Power"),
			ctx
		)
		duration = Bonuses.cut(state(player, p), duration)
		strokes[player] = {
			profile = p,
			point = point,
			normal = normal,
			due = now + duration,
			tempered = tempered,
			speedSupply = if ore.name == "Stone" and (p.stoneChips or 0) > 0 then "stoneChips"
				elseif (p.hasteCuts or 0) > 0 then "hasteCuts" else nil,
			character = character,
			generation = world.generation,
		}
		character:SetAttribute("MiningTarget", point)
		character:SetAttribute("MiningOre", ore.name)
		character:SetAttribute("MiningSwing", duration)
	end
	net.Swing.OnServerEvent:Connect(function(player, active, point, normal)
		local character = player.Character
		if not character or type(active) ~= "boolean" then
			return
		end
		strokes[player], stagedSwing[player] = nil, nil
		if not active then
			character:SetAttribute("MiningSwing", nil)
			return
		end
		local now = os.clock()
		if now < (nextSwing[player] or 0) then
			-- A quick change of aim keeps the most recent face for the next check.
			stagedSwing[player] = { character = character, point = point, normal = normal }
		else
			beginStroke(player, character, point, normal, now)
		end
	end)
	net.Mine.OnServerEvent:Connect(function(player, point, normal, count, mask)
		local now = os.clock()
		if now < (nextInput[player] or 0) then
			return
		end
		nextInput[player] = now + 0.05
		local cut = strokes[player]
		if
			not cut
			or not world.ready
			or count ~= 1
			or mask ~= 1
			or pending[player]
			or cut.character ~= player.Character
			or cut.generation ~= world.generation
			or point ~= cut.point
			or typeof(normal) ~= "Vector3"
			or now + 0.18 < cut.due
		then
			return
		end
		strokes[player] = nil
		cut.character:SetAttribute("MiningSwing", nil)
		cut.time, cut.normal = now, normal
		pending[player] = cut
		table.insert(queue, player)
	end)

	local function pulse(player, profile, request, now)
		local space = Profile.stat(profile, "Capacity") - Profile.used(profile)
		if space <= 0 then
			hint(player, "Pack full • sell your blocks", now)
			return
		end
		local selected = Mining.selection(
			world,
			player.Character,
			request.point,
			request.normal,
			Profile.stat(profile, "Power"),
			space
		)
		if #selected ~= 1 then
			return
		end
		local loot, finds = world:excavate(selected)
		local name = next(loot)
		if not name then
			return
		end
		local center = selected[1]
		local spread = Config.Cell
		local bonus = state(player, profile)
		local luck = Bonuses.luck(bonus)
		local depthBlocks = Config.depthInBlocks(Config.FloorY + world.origin.Y - center.Y)
		local lucky
		if depthBlocks >= Config.DirtLayers and not world.grid:practice(world.grid:cellAt(center)) then
			lucky = Mining.luckyFind(Config.layer(depthBlocks * Config.Cell + Config.Cell / 2), name, luck, luckRandom)
			-- Luck never hands over an ore the pick couldn't cut (Starfall needs the top pick).
			if lucky and Ores.byName[lucky].hardness > Profile.stat(profile, "Power") then lucky = nil end
		end
		if lucky then
			-- The block opens to show a rare ore inside.
			loot = { [lucky] = 1 }
			finds = { [lucky] = center }
			net.Feedback:FireClient(player, "lucky", name, lucky, luck)
			name = lucky
		end
		local ore = Ores.byName[name]
		-- Hot Streak: ores mined in a row. Stone breaks it (Streak Keeper forgives one stone).
		local streak = player:GetAttribute("OreStreak") or 0
		if not ore.host and name ~= "Stone" then
			streak += 1
			player:SetAttribute("StreakSpared", nil)
		elseif profile.skills.StreakKeeper and streak > 0 and not player:GetAttribute("StreakSpared") then
			player:SetAttribute("StreakSpared", true)
		else
			streak = 0
		end
		if streak ~= (player:GetAttribute("OreStreak") or 0) then player:SetAttribute("OreStreak", streak) end
		local discovery = not ore.host and not profile.discoveries[name]
		local oldLevel = Expeditions.level(profile.xp)
		local awards, purity, units, record = Profile.recordCut(profile, name, depthBlocks, nil,
			FriendBonus.multiplier(player:GetAttribute("FriendsHere")) * Bonuses.xp(bonus))
		local freeGeodes = Mining.progressGeodes(profile.col, oldLevel, Expeditions.level(profile.xp), name)
		loot[name] = units
		if request.speedSupply then
			profile[request.speedSupply] = math.max(0, profile[request.speedSupply] - 1)
		end
		if request.tempered then
			profile.temper = math.max(0, profile.temper - 1)
		end
		sync(player, profile)
		for _, award in awards do
			net.Feedback:FireClient(player, "achievement", award)
		end
		local level = Expeditions.level(profile.xp)
		if level > oldLevel then
			net.Feedback:FireClient(player, "levelUp", level)
		end
		for _, rank in Expeditions.ranks do
			if oldLevel < rank.level and level >= rank.level then
				net.Feedback:FireClient(player, "titleUnlocked", rank.name)
			end
		end
		net.Feedback:FireClient(player, "loot", loot, center, spread, finds, request.normal)
		if purity then net.Feedback:FireClient(player, "assay", name, purity, units, record) end
		if discovery then
			net.Feedback:FireClient(player, "milestone", "ORE DISCOVERED", ore.name, ore.color)
		end
		if Profile.used(profile) >= Profile.stat(profile, "Capacity") and hooks.autoSell then
			hooks.autoSell(player)
		end
		-- Starfall, the rarest ore in the mine, is announced to the whole server.
		for _, id in freeGeodes do
			net.Feedback:FireClient(player, "freeGeode", id)
		end
		if name == "Starfall" then
			player:SetAttribute("StarfallAt", nil) -- the compass's find, if it was this one
			for _, other in Players:GetPlayers() do
				net.Feedback:FireClient(other, "starfall", player.DisplayName, profile.counts.Starfall or 1, other == player)
			end
		end
		for _, other in Players:GetPlayers() do
			local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			if other ~= player and root and (root.Position - center).Magnitude < 72 then
				net.Dust:FireClient(other, center, spread, ore.name, finds, request.normal, loot)
			end
		end
	end

	RunService.Heartbeat:Connect(function(dt)
		local tickTime = os.clock()
		for player, swing in stagedSwing do
			if tickTime >= nextSwing[player] then
				stagedSwing[player] = nil
				if swing.character == player.Character then
					beginStroke(player, swing.character, swing.point, swing.normal, tickTime)
				end
			end
		end
		credit = math.min(Config.BurstCells, credit + Config.CellBudget * dt)
		for _ = 1, math.min(2, #queue) do
			local player = queue[1]
			if not player then
				break
			end
			local session, request = sessions[player], pending[player]
			local now = os.clock()
			if request and now < request.due then
				-- Allow a slightly early packet to wait for the same server cooldown.
				table.remove(queue, 1)
				table.insert(queue, player)
				continue
			end
			if
				world.ready
				and session
				and not session.resetting
				and request
				and request.profile == session.profile
				and request.generation == world.generation
				and request.character == player.Character
				and now - request.time < 1
			then
				local p = session.profile
				if credit < 1 then
					break
				end
				credit -= 1

				pulse(player, p, request, now)
			end
			pending[player] = nil
			table.remove(queue, 1)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		stagedSwing[player] = nil
		pending[player], strokes[player], nextInput[player], nextSwing[player], lastHint[player] =
			nil, nil, nil, nil, nil
	end)
end
return Mining
