-- What other miners see of a miner's cosmetics: their player trail (a ribbon as they walk) and their
-- player aura. The mining trail on the pickaxe is in Pickaxe; pet styles are drawn by each client with
-- the pets. Everything follows the Ribbon and Aura attributes the server sets from the collection.
local Looks = require(game:GetService("ReplicatedStorage").Shared.CosmeticLooks)
local Cosmetics = {}

local function clear(root, name)
	for _, child in root:GetDescendants() do
		if child:GetAttribute("Cosmetic") == name then child:Destroy() end
	end
end

local function dress(player, char)
	local root = char:WaitForChild("HumanoidRootPart", 8)
	if not root or player.Character ~= char then return end
	clear(root, "Ribbon")
	Looks.ribbon(root, player:GetAttribute("Ribbon"), function(item) item:SetAttribute("Cosmetic", "Ribbon") end)
	local old = char:FindFirstChild("Miner aura")
	if old then old:Destroy() end
	local id = player:GetAttribute("Aura")
	local holder, look = Looks.aura(char, id or "")
	if not holder then return end
	holder.Name = "Miner aura"
	holder.CFrame = root.CFrame * Looks.auraOffset(look)
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = root, holder, holder
end

function Cosmetics.join(player)
	local function update()
		if player.Character then task.spawn(dress, player, player.Character) end
	end
	player:GetAttributeChangedSignal("Ribbon"):Connect(update)
	player:GetAttributeChangedSignal("Aura"):Connect(update)
	player.CharacterAdded:Connect(function(char)
		task.spawn(dress, player, char)
	end)
	update()
end

return Cosmetics
