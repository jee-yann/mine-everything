-- The Fling troll product (StoreConfig "Fling", 3 Robux): a prompt over every other miner within a
-- few studs. Press E, or tap it on a phone, to buy a fling for that miner; when the purchase goes
-- through, the server tells them, and their own client throws them (Fling.throw), as only it can
-- move its character.
local Players = game:GetService("Players")
local S = require(game.ReplicatedStorage.Shared.StoreConfig)

local Fling = {}

-- Sends this player's own character flying `away` (a flat direction), spinning, for a moment.
function Fling.throw(away)
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local human = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not human then return end
	human:ChangeState(Enum.HumanoidStateType.FallingDown)
	root.AssemblyLinearVelocity = away * 70 + Vector3.yAxis * 85
	root.AssemblyAngularVelocity = Vector3.new(math.random(-12, 12), math.random(-12, 12), math.random(-12, 12))
	task.delay(1.6, function()
		if human.Parent then human:ChangeState(Enum.HumanoidStateType.GettingUp) end
	end)
end

function Fling.start(hud, net)
	local me = Players.LocalPlayer
	local item = S.productByKey.Fling
	local function watch(other)
		if other == me then return end
		local function dress(char)
			local root = char:WaitForChild("HumanoidRootPart", 20)
			if not root or root:FindFirstChild("Fling prompt") then return end
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name, prompt.ActionText, prompt.ObjectText = "Fling prompt", "Fling", other.DisplayName .. " · R$" .. item.price
			prompt.KeyboardKeyCode, prompt.HoldDuration, prompt.MaxActivationDistance = Enum.KeyCode.E, 0, 10
			prompt.RequiresLineOfSight, prompt.Exclusivity = false, Enum.ProximityPromptExclusivity.OneGlobally
			prompt.Parent = root
			prompt.Triggered:Connect(function()
				if hud.inOpening or not hud.checkout then return end
				net.Action:FireServer("FlingTarget", other.UserId)
				hud.checkout:buy("product", item)
			end)
		end
		if other.Character then task.spawn(dress, other.Character) end
		other.CharacterAdded:Connect(dress)
	end
	for _, other in Players:GetPlayers() do watch(other) end
	Players.PlayerAdded:Connect(watch)
end

return Fling
