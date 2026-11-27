-- Every miner's pet following them: each species moves its own way, wears its pet style and its name
-- (and, with the ore compass, points at nearby ore). Pets far from the camera aren't drawn. With
-- Reduce effects on, other miners' pets show without styles. All parts move in one BulkMoveTo a frame.
-- `hud.previewStyle` ({ id, untilTime }) tries a pet style on the player's own pet for a moment.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local C, Bonuses = require(Shared.Collectibles), require(Shared.Bonuses)
local Models = require(script.Parent.PetModels)
local Compass = require(script.Parent.PetCompass)

local slots = { Vector3.new(1.9, 0, 2.6), Vector3.new(-1.9, 0, 2.6), Vector3.new(0, 0, 3.9) }
local heights = { fly = 1.35, float = 1.6, hop = 0.05, bounce = 0.1, scuttle = 0, trot = 0.15, crawl = -0.1 }
local mine = Players.LocalPlayer

return function(hud, origin)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Pet followers", workspace
	local owners = {}
	local ray = RaycastParams.new()
	ray.RespectCanCollide = true

	local function clearPet(pet)
		pet.model:Destroy()
	end
	local function clear(p)
		local entry = owners[p]
		if entry then
			for _, pet in entry.pets do clearPet(pet) end
			owners[p] = nil
		end
	end
	Players.PlayerRemoving:Connect(clear)

	-- The pets a miner should show, and the key that says when they change.
	local decoded = setmetatable({}, { __mode = "k" })
	local function wanted(p)
		local text = p:GetAttribute("Collection")
		local cached = decoded[p]
		if not cached or cached.text ~= text then
			cached = { text = text, value = Bonuses.decode(text) or {} }
			decoded[p] = cached
		end
		local col = cached.value
		local list = {}
		for i, id in col.eq or {} do
			if C.petById[id] and i <= C.petSlots then table.insert(list, id) end
		end
		local style = p:GetAttribute("PetStyle") or ""
		if p ~= mine and mine:GetAttribute("ReduceEffects") == true then style = "" end
		local preview = hud.previewStyle
		if p == mine and preview and os.clock() < preview.untilTime then style = preview.id end
		return list, table.concat(list, ",") .. "|" .. style, style
	end

	local function build(p, root, list, style)
		local entry = { pets = {} }
		for i, id in list do
			local model, parts = Models.build(id, style)
			model.Parent = folder
			local pet = { id = id, model = model, parts = parts, at = root.CFrame, nextProbe = 0, slot = i, motion = C.petById[id].motion }
			pet.goal = root.Position
			if i == 1 then
				local tag = Instance.new("BillboardGui")
				tag.Name, tag.Size, tag.StudsOffsetWorldSpace, tag.MaxDistance = "Pet name", UDim2.fromOffset(110, 15), Vector3.yAxis * 1.1, 22
				tag.Adornee, tag.Parent = model.PrimaryPart, model
				local label = Instance.new("TextLabel")
				label.BackgroundTransparency, label.Size, label.TextSize, label.Font = 1, UDim2.fromScale(1, 1), 12, Enum.Font.FredokaOne
				label.TextColor3, label.TextStrokeTransparency, label.Parent = Color3.fromRGB(255, 231, 188), 0.25, tag
				pet.label = label
			end
			table.insert(entry.pets, pet)
		end
		return entry
	end

	-- Reduce effects also hides other miners' auras and trail ribbons, here only.
	task.spawn(function()
		while true do
			local quiet = mine:GetAttribute("ReduceEffects") == true
			for _, p in Players:GetPlayers() do
				if p ~= mine and p.Character then
					for _, item in p.Character:GetDescendants() do
						if item:IsA("ParticleEmitter") or item:IsA("Trail") then
							local cosmetic = item:GetAttribute("Cosmetic") or (item.Parent and item.Parent.Name == "Miner aura" and "Aura")
							if cosmetic then item.Enabled = not quiet end
						end
					end
				end
			end
			task.wait(1)
		end
	end)
	Run.RenderStepped:Connect(function(dt)
		if hud.inOpening then
			for p in owners do clear(p) end
			return
		end
		local eye = workspace.CurrentCamera
		if not eye then return end
		local now = os.clock()
		local moveParts, moveFrames = {}, {}
		for _, p in Players:GetPlayers() do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not root or (root.Position - eye.CFrame.Position).Magnitude > 125 then
				clear(p)
				continue
			end
			local list, key, style = wanted(p)
			local entry = owners[p]
			if entry and entry.key ~= key then
				clear(p)
				entry = nil
			end
			if not entry then
				entry = build(p, root, list, style)
				entry.key = key
				owners[p] = entry
			end
			for _, pet in entry.pets do
				local lead = pet.slot == 1
				local compassOn = lead and p == mine and p:GetAttribute("OreCompass") and Config.inMine(root.Position - origin)
				if not compassOn then
					pet.seam = nil
				elseif now >= (pet.nextScan or 0) then
					pet.nextScan = now + 0.7
					local head = p.Character:FindFirstChild("Head")
					pet.seam = Compass.nearest(if head then head.Position else root.Position, { p.Character, folder })
				end
				local seam = pet.seam
				local ore = if seam and seam.Parent then Ores.byName[seam.Name] else nil
				if pet.label then
					if ore then
						local secret = ore.secret and not p:GetAttribute("Found" .. ore.name)
						pet.label.Text = if secret then "◆  Ore nearby" else "◆  " .. ore.name .. " nearby"
						pet.label.TextColor3 = if secret then Color3.fromRGB(231, 210, 255) else ore.color:Lerp(Color3.new(1, 1, 1), 0.62)
					else
						pet.label.Text = p:GetAttribute("PetName") or "Pebble"
						pet.label.TextColor3 = Color3.fromRGB(255, 231, 188)
					end
				end
				if now >= pet.nextProbe then
					pet.nextProbe = now + 0.1
					ray.FilterDescendantsInstances = { p.Character, folder }
					local from = root.Position - Vector3.yAxis * 0.35
					local delta = root.CFrame:VectorToWorldSpace(slots[pet.slot])
					local wall = workspace:Spherecast(from, 0.72, delta, ray)
					local at = from + delta.Unit * (if wall then math.max(0, wall.Distance - 0.12) else delta.Magnitude)
					local ground = workspace:Raycast(at + Vector3.yAxis * 0.25, -Vector3.yAxis * 4, ray)
					pet.goal = Vector3.new(at.X, if ground then ground.Position.Y + 0.7 else at.Y - 0.6, at.Z)
				end
				local t = now * 5 + p.UserId % 11 + pet.slot * 1.7
				local motion = pet.motion
				local lift = heights[motion] or 0
				if motion == "fly" or motion == "float" then
					lift += 0.24 * math.sin(t * (if motion == "float" then 0.5 else 1))
				elseif motion == "hop" then
					lift += 0.35 * math.abs(math.sin(t * 0.9))
				elseif motion == "bounce" then
					lift += 0.5 * math.abs(math.sin(t * 0.7))
				else
					lift += 0.06 * math.sin(t * 2)
				end
				local goal = pet.goal + Vector3.yAxis * lift
				local gaze = if ore then (seam.Position - goal) * Vector3.new(1, 0, 1) else Vector3.zero
				local facing = if gaze.Magnitude > 0.1 then CFrame.lookAlong(goal, gaze) else CFrame.new(goal) * root.CFrame.Rotation
				local sway = if motion == "scuttle" then CFrame.new(0.12 * math.sin(t * 3), 0, 0)
					elseif motion == "crawl" then CFrame.Angles(0, 0.12 * math.sin(t * 2.5), 0)
					elseif motion == "float" then CFrame.Angles(0, t * 0.4, 0)
					else CFrame.Angles(0, 0, 0.055 * math.sin(t))
				local target = facing * sway
				if (pet.at.Position - goal).Magnitude > 16 then
					pet.at = target
				else
					pet.at = pet.at:Lerp(target, 1 - math.exp(-dt * (9 - pet.slot)))
				end
				-- Wings beat on fliers, and on any pet wearing wings.
				local flap = if motion == "fly" then 0.55 * math.sin(t * 3.2) else 0.35 * math.sin(t * 2.6)
				Models.place(pet.parts, pet.at, flap, moveParts, moveFrames)
			end
		end
		if #moveParts > 0 then
			workspace:BulkMoveTo(moveParts, moveFrames, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end)
end
