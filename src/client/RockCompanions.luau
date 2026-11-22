local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local companion = require(script.Parent.CompanionModel)
local Compass = require(script.Parent.PetCompass)
local Shared = game.ReplicatedStorage.Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
return function(hud, origin)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Rock companions", workspace
	local pets = {}
	local ray = RaycastParams.new()
	ray.RespectCanCollide = true
	local function clear(p)
		if pets[p] then
			pets[p].model:Destroy()
			pets[p] = nil
		end
	end
	Players.PlayerRemoving:Connect(clear)
	Run.RenderStepped:Connect(function(dt)
		if hud.inOpening then
			for p in pets do clear(p) end
			return
		end
		local eye = workspace.CurrentCamera
		if not eye then
			return
		end
		local now = os.clock()
		for _, p in Players:GetPlayers() do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			local species = p:GetAttribute("Pet")
			if pets[p] and pets[p].species ~= species then
				clear(p)
			end
			if
				(species ~= "Rock" and species ~= "Drake")
				or not root
				or (root.Position - eye.CFrame.Position).Magnitude > 125
			then
				clear(p)
				continue
			end
			local pet = pets[p]
			if not pet then
				local model, label = companion(folder, species == "Drake")
				pet = { species = species, model = model, label = label, at = root.CFrame, nextProbe = 0 }
				pets[p] = pet
			end
			local compassOn = p == Players.LocalPlayer and p:GetAttribute("OreCompass") and Config.inMine(root.Position - origin)
			if not compassOn then
				pet.seam = nil
			elseif now >= (pet.nextScan or 0) then
				pet.nextScan = now + 0.7
				local head = p.Character:FindFirstChild("Head")
				pet.seam = Compass.nearest(if head then head.Position else root.Position, { p.Character, folder })
			end
			local seam = pet.seam
			local ore = if seam and seam.Parent then Ores.byName[seam.Name] else nil
			if ore then
				local secret = ore.secret and not p:GetAttribute("Found" .. ore.name)
				pet.label.Text = if secret then "◆  Ore nearby" else "◆  " .. ore.name .. " nearby"
				pet.label.TextColor3 = if secret then Color3.fromRGB(231, 210, 255) else ore.color:Lerp(Color3.new(1, 1, 1), 0.62)
			else
				pet.label.Text = p:GetAttribute("PetName") or "Pebble"
				pet.label.TextColor3 = Color3.fromRGB(255, 231, 188)
			end
			if now >= pet.nextProbe then
				pet.nextProbe = now + 0.1
				ray.FilterDescendantsInstances = { p.Character, folder }
				local from = root.Position - Vector3.yAxis * 0.35
				local delta = root.CFrame:VectorToWorldSpace(Vector3.new(1.9, 0, 2.6))
				local wall = workspace:Spherecast(from, 0.72, delta, ray)
				local at = from + delta.Unit * (if wall then math.max(0, wall.Distance - 0.12) else delta.Magnitude)
				local ground = workspace:Raycast(at + Vector3.yAxis * 0.25, -Vector3.yAxis * 4, ray)
				pet.goal = Vector3.new(at.X, if ground then ground.Position.Y + 0.70 else at.Y - 0.6, at.Z)
			end
			local t = now * 5 + p.UserId % 11
			local goal = pet.goal
				+ Vector3.yAxis
					* (if species == "Drake" then 1.35 + 0.24 * math.sin(t) else 0.08 + 0.10 * math.sin(t))
			local gaze = if ore then (seam.Position - goal) * Vector3.new(1, 0, 1) else Vector3.zero
			local facing = if gaze.Magnitude > 0.1 then CFrame.lookAlong(goal, gaze) else CFrame.new(goal) * root.CFrame.Rotation
			local target = facing * CFrame.Angles(0, 0, 0.055 * math.sin(t))
			local distance = (pet.at.Position - goal).Magnitude
			if distance > 16 then
				pet.at = target
			else
				pet.at = pet.at:Lerp(target, 1 - math.exp(-dt * 9))
			end
			pet.model:PivotTo(pet.at)
		end
	end)
end
