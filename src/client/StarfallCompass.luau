-- The Starfall Compass pass, as its owner sees it: when the server's ping (every two minutes
-- underground) finds a Starfall within reach, a star marker hangs over that block, seen through the
-- rock, with how many blocks away it is; a short notice says so. Only the owner sees it.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local W = require(script.Parent.Widgets)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)

return function(hud)
	local player = Players.LocalPlayer
	local anchor = Instance.new("Part")
	anchor.Name, anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = "Starfall compass mark", true, false, false, false
	anchor.Transparency, anchor.Size = 1, Vector3.one
	local tag = Instance.new("BillboardGui")
	tag.Name, tag.Size, tag.AlwaysOnTop, tag.LightInfluence, tag.Adornee = "Starfall compass", UDim2.fromOffset(150, 64), true, 0, anchor
	tag.Enabled, tag.ResetOnSpawn = false, false
	local star = W.title(tag, "★", 0, 0, 150, 40, 38, Color3.fromRGB(205, 170, 255))
	W.navyText(star, 3)
	local away = W.title(tag, "", 0, 38, 150, 24, 17, W.white)
	W.navyText(away, 2)
	tag.Parent = player:WaitForChild("PlayerGui")
	local function update()
		local at = player:GetAttribute("StarfallAt")
		if typeof(at) == "Vector3" then
			anchor.Position, anchor.Parent = at, workspace
			tag.Enabled = true
		else
			anchor.Parent, tag.Enabled = nil, false
		end
	end
	player:GetAttributeChangedSignal("StarfallAt"):Connect(update)
	player:GetAttributeChangedSignal("StarfallPing"):Connect(function()
		if typeof(player:GetAttribute("StarfallAt")) == "Vector3" then
			hud:notice("Starfall Compass: a Starfall nearby!", "Follow the star through the rock", Color3.fromRGB(205, 170, 255))
		end
	end)
	update()
	Run.RenderStepped:Connect(function()
		if not tag.Enabled then return end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local blocks = math.max(1, math.floor((root.Position - anchor.Position).Magnitude / Config.Cell + 0.5))
		away.Text = "Starfall · " .. blocks .. (if blocks == 1 then " block" else " blocks")
		tag.Enabled = not hud.inOpening
	end)
end
