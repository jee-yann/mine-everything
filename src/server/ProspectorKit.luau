local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
local E = require(game.ReplicatedStorage.Shared.Expeditions)
local function equip(player, char)
	local human = char:WaitForChild("Humanoid", 8)
	if not human then
		return
	end
	local torso = char:WaitForChild(if human.RigType == Enum.HumanoidRigType.R15 then "UpperTorso" else "Torso", 8)
	if not torso or player.Character ~= char then
		return
	end
	local head = char:WaitForChild("Head", 8)
	if not head then
		return
	end
	if not head:FindFirstChild("Head clearance") then
		local guard = Instance.new("Part")
		guard.Name, guard.Shape, guard.Transparency = "Head clearance", Enum.PartType.Ball, 1
		guard.CollisionGroup = "MinerHead"
		guard.CanTouch, guard.CanQuery, guard.Massless = false, false, true
		local function fitGuard()
			guard.Size = Vector3.one * math.clamp(head.Size.Y + 0.14, 0.85, 2.4)
		end
		fitGuard()
		guard.CFrame = head.CFrame
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = head, guard, guard
		guard.Parent = head
		head:GetPropertyChangedSignal("Size"):Connect(fitGuard)
	end
	if torso:FindFirstChild("Prospector kit") then
		return
	end
	local kit = Instance.new("Model")
	kit.Name = "Prospector kit"
	kit.Parent = torso
	local fabric = Color3.fromRGB(63, 97, 111)
	local leather = Color3.fromRGB(125, 78, 48)
	local gold = Color3.fromRGB(242, 189, 95)
	local function piece(name, tint)
		local p = Instance.new("Part")
		p.Name, p.Color, p.Massless = name, tint, true
		p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
		p.Material = Enum.Material.SmoothPlastic
		local joint = Instance.new("Weld")
		joint.Part0, joint.Part1, joint.Parent = torso, p, p
		p.Parent = kit
		return p, joint
	end
	local bag, binding = piece("Field pack", fabric)
	local flap, seam = piece("Leather flap", leather)
	local buckle, clasp = piece("Brass clasp", gold)
	local nameplate = Instance.new("BillboardGui")
	nameplate.Name, nameplate.Adornee, nameplate.Size = "Miner title", torso, UDim2.new(2.4, 48, 0.55, 14)
	nameplate.MaxDistance, nameplate.LightInfluence, nameplate.Parent = 95, 0, kit
	nameplate.AlwaysOnTop = true
	human.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local title = Instance.new("TextLabel")
	title.Size, title.BackgroundTransparency, title.Font = UDim2.fromScale(1, 1), 1, Enum.Font.FredokaOne
	title.TextScaled, title.TextColor3, title.TextStrokeColor3, title.TextStrokeTransparency =
		true, gold, Color3.fromRGB(32, 27, 45), 0.12
	title.TextWrapped, title.RichText = true, true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize, limit.Parent = 5, 14, title
	title.Parent = nameplate
	local function fit()
		local level = player:GetAttribute("Capacity") or 1
		local scale = 0.70 + 0.085 * level
		local z = torso.Size.Z / 2 + 0.36 * scale
		bag.Size = Vector3.new(1.58, 1.62, 0.75) * scale
		flap.Size = Vector3.new(1.62, 0.54, 0.80) * scale
		buckle.Size = Vector3.new(0.35, 0.31, 0.11) * scale
		binding.C0 = CFrame.new(0, -0.14, z)
		seam.C0 = binding.C0 * CFrame.new(0, 0.59 * scale, 0.02 * scale)
		clasp.C0 = binding.C0 * CFrame.new(0, 0.36 * scale, 0.442 * scale)
		nameplate.StudsOffsetWorldSpace = Vector3.new(0, torso.Size.Y / 2 + 1.85, 0)
		local tier, rank = E.rank(E.level(player:GetAttribute("MiningXP") or 0))
		-- VIP owners get a gold tag; Celestial Miner owners wear its title in place of their rank.
		local passes = "," .. (player:GetAttribute("Passes") or "") .. ","
		local vip = if passes:find(",VIP,", 1, true) then '<font color="#FFD25A">VIP</font> ' else ""
		local rankName = (E.ranks[player:GetAttribute("EquippedTitle") or tier] or rank).name
		if passes:find(",Everything,", 1, true) then
			rankName = '<font color="#7FF2E6">✦ Celestial Miner ✦</font>'
		end
		title.Text = vip .. player.DisplayName .. Rebirth.richBadge(player:GetAttribute("Rebirths") or 0) .. "\n" .. rankName
		bag.Color = ({
			fabric,
			Color3.fromRGB(64, 126, 119),
			Color3.fromRGB(68, 104, 156),
			Color3.fromRGB(109, 72, 147),
			Color3.fromRGB(51, 147, 134),
			Color3.fromRGB(152, 108, 189),
			Color3.fromRGB(70, 150, 200),
			Color3.fromRGB(200, 150, 60),
			Color3.fromRGB(190, 70, 70),
			Color3.fromRGB(230, 190, 90),
		})[tier] or fabric
	end
	fit()
	local signals = { torso:GetPropertyChangedSignal("Size"):Connect(fit) }
	for _, key in { "Capacity", "MiningXP", "EquippedTitle", "Rebirths", "Passes" } do
		table.insert(signals, player:GetAttributeChangedSignal(key):Connect(fit))
	end
	kit.Destroying:Once(function()
		for _, signal in signals do
			signal:Disconnect()
		end
	end)
end
return equip
