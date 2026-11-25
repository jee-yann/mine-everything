local Shared = game:GetService("ReplicatedStorage").Shared
local Collection = game:GetService("CollectionService")
local Gui = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Config, Upgrades, Ores = require(Shared.GameConfig), require(Shared.Upgrades), require(Shared.Ores)
local Pattern = require(Shared.BlockPattern)
local W = require(script.Parent.Widgets)
local Waypoint, GuideButton = require(script.Parent.ExpeditionWaypoint), require(script.Parent.GuideButton)
local Spotlight = require(script.Parent.SurfaceSpotlight)

local Guide = {}
Guide.__index = Guide
local steps = { Dig = 1, Ore = 2, Sell = 3, Upgrade = 4, Return = 5 }
local normals = { Vector3.yAxis, Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis, -Vector3.yAxis }

function Guide.new(player, net, hud)
	local waypoint = Waypoint.new(hud and hud.root)
	local nearby = OverlapParams.new()
	nearby.FilterType = Enum.RaycastFilterType.Include
	return setmetatable({
		player = player, net = net, hud = hud, waypoint = waypoint, button = GuideButton.new(),
		anchor = waypoint.anchor, pin = waypoint.pin, label = waypoint.label,
		spotlight = if hud then Spotlight.new(hud.root) else nil,
		nearby = nearby, sight = RaycastParams.new(), nextSearch = 0,
	}, Guide)
end

function Guide:hide()
	self.waypoint:clear()
	self.button:point(nil)
	if self.spotlight then self.spotlight:show(nil) end
	self.nextUpdate, self.searchKind, self.latestBlock = nil, nil, nil
end

function Guide:mark(position, text, tint, goal, part)
	self.marked = true
	self.waypoint:show(position, text, tint, goal, part)
end

-- Rank exposed, mineable blocks only. Prefer a real ore, then the next dirt layer
-- or a stone face. Following the same cut gives a new miner a way through the dirt cap.
function Guide:pickBlock(head, kind)
	local now = os.clock()
	if self.searchKind == kind and now < self.nextSearch and (head.Position - self.lastSearchPosition).Magnitude < 2
		and (not self.latestBlock or self.latestBlock.Parent) then
		return self.latestBlock, self.face
	end
	local previous = if self.searchKind == kind then self.latestBlock else nil
	self.searchKind, self.nextSearch, self.lastSearchPosition = kind, now + 0.42, head.Position
	self.latestBlock, self.face = nil, nil
	local island = workspace:FindFirstChild("CitrineCove")
	local grid = island and island:FindFirstChild("MineBlocks")
	local char = self.player.Character
	if not grid or not char then return end
	self.nearby.FilterDescendantsInstances = { grid }
	self.sight.FilterDescendantsInstances = { char }
	local power = Upgrades.items.Power.values[self.player:GetAttribute("Power") or 1]
	local reach = char:GetAttribute("PickReach") or Config.Reach
	local origin = self.net:GetAttribute("Origin")
	local camera = workspace.CurrentCamera
	local preferred = self.lastCut
	if preferred and (preferred - head.Position).Magnitude > reach then preferred = nil end
	local candidates = {}
	for _, block in workspace:GetPartBoundsInRadius(head.Position, reach + Config.Cell, self.nearby) do
		local ore = Ores.byName[block.Name]
		if block.Parent ~= grid or not ore or math.max(ore.hardness, Config.strength(block.Position.Y - origin.Y)) > power then continue end
		if kind == "OreOnly" and ore.host then continue end
		local delta = block.Position - head.Position
		local score = delta.Magnitude
		if camera then
			local look = camera.CFrame.LookVector
			local forwards = Vector3.new(look.X, 0, look.Z)
			if forwards.Magnitude > 0.1 then
				-- An initial target a step ahead is easier to see than the brick under the miner's boots.
				score = (delta - forwards.Unit * Config.Cell).Magnitude
			end
		end
		-- Stay on one block until it breaks. Looking around must not send the arrow elsewhere,
		-- though a real ore still beats the dirt or stone already marked.
		if block == previous then score -= 30 end
		if kind == "Ore" or kind == "Sell" or kind == "OreOnly" then
			if not ore.host then
				score -= 110
			elseif block.Name == "Stone" then
				score -= 45
			else
				score -= math.clamp(origin.Y - block.Position.Y, 0, Config.DirtLayers * Config.Cell) * 2
			end
			if preferred then
				local offset = block.Position - preferred
				score += math.min(16, Vector2.new(offset.X, offset.Z).Magnitude)
			end
		elseif kind == "Dig" and block.Name == "Dirt" then
			score -= 25
		end
		table.insert(candidates, { part = block, score = score })
	end
	table.sort(candidates, function(a, b) return a.score < b.score end)
	for _, candidate in candidates do
		local block = candidate.part
		local delta = block.Position - head.Position
		local hit = workspace:Raycast(head.Position, delta, self.sight)
		if not hit or hit.Instance ~= block then continue end
		-- Match the face-centre reach and line of sight used by the mining action.
		local normal = hit.Normal
		if Pattern.visiblePart(head.Position, block.Position, normal, self.sight, reach) ~= block then
			normal = nil
			for _, side in normals do
				if Pattern.visiblePart(head.Position, block.Position, side, self.sight, reach) == block then
					normal = side
					break
				end
			end
		end
		if normal then
			self.latestBlock = block
			self.face = block.Position + normal * (Config.Cell / 2 + 0.18)
			break
		end
	end
	return self.latestBlock, self.face
end

function Guide:visibleOre(head)
	return self:pickBlock(head, "OreOnly")
end

function Guide:station(name, label, color, head, inMine, mobile)
	local pos = self.net:GetAttribute(name .. "Position")
	if inMine and self.hud and self.hud.surface.Visible then
		self.control = self.hud.surface
		self.surfaceSale = name == "Sell"
		return if self.surfaceSale then "Return to the harbor to sell" else "Use Surface to reach the workshop"
	end
	if pos then
		local pad
		for _, part in Collection:GetTagged("MiningInteractionPad") do
			if (part.Position - pos).Magnitude < 0.5 then pad = part break end
		end
		self:mark(pos + Vector3.yAxis * 4.5, label, color, pos, pad)
		if (head.Position - pos).Magnitude > (self.net:GetAttribute(name .. "Range") or 10) + 2 then
			return "Follow the arrow to " .. label
		end
	end
	if mobile then return "Tap the prompt on the " .. label .. " pad" end
	if Input.PreferredInput == Enum.PreferredInput.Gamepad then return "Use the prompt at " .. label end
	return "Press E at the " .. label .. " pad"
end

function Guide:objective(head, inMine, depth, mobile, full, step)
	local p = self.player
	local gold = p:GetAttribute("Gold") or 0
	local haul = (p:GetAttribute("BagValue") or 0) * (if p:GetAttribute("DoubleGold") then 2 else 1)
	local used, slots = p:GetAttribute("Used") or 0, p:GetAttribute("PackSlots") or Upgrades.items.Capacity.values[1]
	local key, price = Upgrades.onboardingPick(gold)
	local upgrade = if key == "Speed" then "Speed" else "Backpack"
	local gathering = step == "Sell" or (step == "Upgrade" and gold < price)
	if full or (gathering and haul > 0 and (not inMine or (step == "Upgrade" and gold + haul >= price))) then
		local title = if inMine and full then "Backpack full!" else "Sell your rocks · " .. W.goldAmount(haul) .. " G"
		return title, self:station("Sell", "Sell", W.gold, head, inMine, mobile)
	elseif step == "Upgrade" and gold >= price then
		return "Buy " .. upgrade .. " · " .. price .. " G", self:station("Shop", "Upgrades", W.aqua, head, inMine, mobile)
	end

	local action = if mobile then "Aim and hold Mine" elseif Input.PreferredInput == Enum.PreferredInput.Gamepad then "Hold the right trigger" else "Hold the left mouse button"
	local title = if step == "Sell" or step == "Ore" then string.format("Fill your pack · %d/%d", used, slots)
		elseif gathering then string.format("Mine for your upgrade · %d/%d G", gold + haul, price)
		elseif step == "Return" then "Try your upgraded gear"
		else "Break your first block"
	if not inMine then
		local entrance, floor = self.net:GetAttribute("Entrance"), self.net:GetAttribute("DigFloor")
		if entrance and floor then
			-- The marker moves into the doorway before a player reaches the portal paving.
			local nearPortal = (head.Position - entrance).Magnitude < 13 or
				(head.Position.Z < entrance.Z and math.abs(head.Position.X - entrance.X) < Config.HallHalfWidth)
			self:mark(if nearPortal then floor + Vector3.yAxis * 3 else entrance + Vector3.yAxis * 4,
				if nearPortal then "Dig floor" else "Mine", W.gold, if nearPortal then floor else entrance)
		end
		return title, if step == "Dig" then "Cross the bridge and enter the mine" else "Follow the arrow into the mine"
	end

	local kind = if gathering then "Sell" else step
	local block, face = self:pickBlock(head, kind)
	if block then
		local ore = Ores.byName[block.Name]
		local name = if ore.secret and not p:GetAttribute("Found" .. ore.name) then "Ore" else ore.name
		self:mark(face + Vector3.yAxis * 1.35, name, if ore.host then W.gold else W.aqua, face, block)
		self.mineTarget = block
		return title, action .. " on the marked " .. string.lower(name)
	end
	if depth > Config.DirtLayers and self.hud and self.hud.surface.Visible then
		self.control = self.hud.surface
		return title, "Use ↑ Surface to find softer rock"
	end
	local floor = self.net:GetAttribute("DigFloor")
	if floor then self:mark(floor + Vector3.yAxis * 2, "Dig floor", W.gold, floor) end
	return title, "Walk closer, then " .. action:sub(1, 1):lower() .. action:sub(2)
end

function Guide:update(head, inMine, depth, mobile, full, aimed)
	local step = self.player:GetAttribute("ExpeditionStep")
	if not steps[step] then
		if self.nextUpdate then self:hide() end
		return
	end
	local now = os.clock()
	if step ~= self.lastStep or self.wasFull ~= full or self.wasMobile ~= mobile or not self.nextUpdate
		or now >= self.nextUpdate or (self.mineTarget and not self.mineTarget.Parent) then
		self.lastStep, self.wasFull, self.wasMobile, self.nextUpdate = step, full, mobile, now + 0.16
		self.control, self.mineTarget, self.surfaceSale = nil, nil, false
		self.marked = false
		self.title, self.help = self:objective(head, inMine, depth, mobile, full, step)
		self.title = string.format("%d/5 · %s", steps[step], self.title)
		if not self.marked then self.waypoint:clear() end
	end
	local motion = self.player:GetAttribute("MenuMotion") ~= false and not Gui.ReducedMotionEnabled
	self.head, self.underground, self.motion, self.aimed = head, inMine, motion, aimed
	local control = self.control
	local spotlight = self.surfaceSale and self.hud and control and control.Visible and control.Parent.Visible
		and not Gui.MenuIsOpen and not Input:GetFocusedTextBox() and not (self.hud.chatInput and self.hud.chatInput.IsFocused)
	if self.spotlight then
		if spotlight then
			local used = self.player:GetAttribute("Used") or 0
			local capacity = self.player:GetAttribute("PackSlots") or Upgrades.items.Capacity.values[1]
			local worth = (self.player:GetAttribute("BagValue") or 0) * (if self.player:GetAttribute("DoubleGold") then 2 else 1)
			local headline = if full then string.format("Backpack full · %d/%d", used, capacity) else "Your rocks are ready to sell"
			local action = if mobile then "Tap Surface" else "Press R or click Surface"
			if Input.PreferredInput == Enum.PreferredInput.Gamepad then
				local label = Input:GetStringForKeyCode(Enum.KeyCode.ButtonY):gsub("^Button", "")
				action = "Press " .. (if label == "" then "Y" else label)
			end
			self.spotlight:show(control, headline, action .. " to go up.\nSell your rocks for " .. W.goldAmount(worth) .. " gold.", motion)
		else
			self.spotlight:show(nil)
		end
	end
	if not control and self.hud and mobile and aimed and self.mineTarget == aimed and self.hud.mine.Visible then
		control = self.hud.mine
	end
	self.button:point(control, motion, if spotlight then "Spotlight" elseif self.hud and control == self.hud.surface then "Right" else "Left")
	return self.title, self.help
end

function Guide:draw(dt)
	self.waypoint:draw(workspace.CurrentCamera, self.motion, self.aimed, self.head, self.underground, dt)
end

return Guide
