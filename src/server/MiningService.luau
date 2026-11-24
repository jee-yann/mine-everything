local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Pattern = require(Shared.BlockPattern)
local Profile = require(script.Parent.Profile)
local Expeditions = require(Shared.Expeditions)
local Skills = require(Shared.Skills)
local Mining = {}

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
	return Pattern.select(world.origin, center, world:oreAt(center), power, space)
end

function Mining.start(world, net, sessions, sync)
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
		local duration, tempered = Skills.cutTime(
			Profile.stat(p, "Speed"),
			ore,
			Config.strength(point.Y - world.origin.Y),
			p.temper,
			p.skills,
			p.hasteCuts,
			p.stoneChips,
			Profile.stat(p, "Power")
		)
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
			hint(player, "Pack full • sell your ore", now)
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
		local ore = Ores.byName[name]
		local discovery = not ore.host and not profile.discoveries[name]
		local oldLevel = Expeditions.level(profile.xp)
		local awards, purity, units, record = Profile.recordCut(profile, name, Config.depthInBlocks(Config.FloorY + world.origin.Y - center.Y))
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
		-- Starfall, the rarest ore in the mine, is announced to the whole server.
		if name == "Starfall" then
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
