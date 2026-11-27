-- The ore compass (a Field Supplies craft): while the miner is underground, a small marker over their
-- head names the nearest exposed ore they can see, and its arrow turns toward it. Only they see it.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Compass = require(script.Parent.PetCompass)

return function(hud, origin)
	local player = Players.LocalPlayer
	local tag = Instance.new("BillboardGui")
	tag.Name, tag.Size, tag.StudsOffsetWorldSpace, tag.AlwaysOnTop = "Ore compass", UDim2.fromOffset(170, 26), Vector3.yAxis * 3.6, true
	tag.Enabled, tag.MaxDistance = false, 60
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency, label.Size, label.TextSize, label.Font = 1, UDim2.fromScale(1, 1), 15, Enum.Font.FredokaOne
	label.TextStrokeTransparency, label.Parent = 0.2, tag
	tag.Parent = player:WaitForChild("PlayerGui")
	local nextScan, seam = 0, nil
	Run.RenderStepped:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local on = root and not hud.inOpening and player:GetAttribute("OreCompass") and Config.inMine(root.Position - origin)
		if not on then
			tag.Enabled, seam = false, nil
			return
		end
		local now = os.clock()
		if now >= nextScan then
			nextScan = now + 0.7
			local head = char:FindFirstChild("Head")
			seam = Compass.nearest(if head then head.Position else root.Position, { char })
		end
		local ore = if seam and seam.Parent then Ores.byName[seam.Name] else nil
		tag.Adornee = root
		tag.Enabled = ore ~= nil
		if ore then
			local secret = ore.secret and not player:GetAttribute("Found" .. ore.name)
			-- An arrow that turns with the ore's direction relative to the camera.
			local camera = workspace.CurrentCamera
			local flat = camera.CFrame:VectorToObjectSpace(seam.Position - root.Position)
			local arrows = { "↑", "↗", "→", "↘", "↓", "↙", "←", "↖" }
			local angle = math.atan2(flat.X, -flat.Z)
			local arrow = arrows[(math.floor((angle / (2 * math.pi)) * 8 + 0.5) % 8) + 1]
			label.Text = arrow .. "  " .. (if secret then "Ore nearby" else ore.name .. " nearby")
			label.TextColor3 = if secret then Color3.fromRGB(231, 210, 255) else ore.color:Lerp(Color3.new(1, 1, 1), 0.55)
		end
	end)
end
