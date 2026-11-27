-- "Try on": shows a cosmetic on the player's own miner for a few seconds, before they
-- own it or before they wear it. Everything is made on this client only; nobody else sees it.
-- A mining trail is shown as a spark circling the miner, trailing the trail's colours.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Looks = require(Shared.Collectibles), require(Shared.CosmeticLooks)
local W = require(script.Parent.Widgets)
local TryOn = { seconds = 8 }
local current

local function stop()
	if current then
		for _, item in current.items do item:Destroy() end
		if current.connection then current.connection:Disconnect() end
		current = nil
	end
end

local function orbit(root, entry, items)
	local spark = Instance.new("Part")
	spark.Name, spark.Shape, spark.Size = "Try-on spark", Enum.PartType.Ball, Vector3.one * 0.45
	spark.Material, spark.Color = Enum.Material.Neon, C.colors(entry)[1]
	spark.Anchored, spark.CanCollide, spark.CanQuery, spark.CanTouch = true, false, false, false
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Position, b.Position = Vector3.new(0, 0.35, 0), Vector3.new(0, -0.35, 0)
	a.Parent, b.Parent = spark, spark
	Looks.streak(entry, a, b, function() end, { lifetime = 0.45 + 0.05 * Looks.rank(entry), scale = 0.8 })
	spark.Parent = workspace
	table.insert(items, spark)
	local start = os.clock()
	return Run.RenderStepped:Connect(function()
		if not root.Parent then return end
		local t = (os.clock() - start) * 3.2
		spark.Position = root.Position + Vector3.new(math.cos(t) * 2.8, 0.6 + math.sin(t * 2) * 0.6, math.sin(t) * 2.8)
	end)
end

-- Tries `kind`/`id` on for a few seconds. Returns false (and why) when it can't be shown.
function TryOn.start(hud, kind, id)
	local entry = C.find(kind, id)
	local player = Players.LocalPlayer
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not entry or not root then return false end
	stop()
	local items = {}
	current = { items = items }
	if kind == "ribbon" then
		Looks.ribbon(root, id, function(item) table.insert(items, item) end)
	elseif kind == "aura" then
		local holder, look = Looks.aura(char, id)
		if holder then
			holder.CFrame = root.CFrame * Looks.auraOffset(look)
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = root, holder, holder
			table.insert(items, holder)
		end
	elseif kind == "trail" then
		current.connection = orbit(root, entry, items)
	end
	hud.menu:close()
	hud:notice("Trying on " .. entry.name, C.kindNames[kind] .. " · only you can see this", C.rarities[entry.rarity].color)
	local mine = current
	task.delay(TryOn.seconds, function()
		if current == mine then stop() end
	end)
	return true
end

return TryOn
