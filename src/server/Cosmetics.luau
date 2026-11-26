-- What other miners see of a miner's cosmetics: the walking ribbon of a Legendary or better trail, and
-- the aura around them. The pickaxe's own swing trail is in Pickaxe; pet auras are drawn by each client
-- with the pets. Everything follows the Trail and Aura attributes the server sets from the collection.
local C = require(game:GetService("ReplicatedStorage").Shared.Collectibles)
local Cosmetics = {}

local function colors(trail)
	local a, b = trail.colors[1], trail.colors[2]
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, a),
		ColorSequenceKeypoint.new(0.5, a:Lerp(b, 0.5)),
		ColorSequenceKeypoint.new(1, b),
	})
end

local function clear(root, name)
	for _, child in root:GetChildren() do
		if child:GetAttribute("Cosmetic") == name then child:Destroy() end
	end
end

local function tag(instance, name, parent)
	instance:SetAttribute("Cosmetic", name)
	instance.Parent = parent
	return instance
end

-- A ribbon behind the miner while they walk, for trails Legendary and up.
local function ribbon(root, id)
	clear(root, "Ribbon")
	local trail = C.trailById[id]
	if not trail or C.rarities[trail.rarity].rank < C.rarities.Legendary.rank then return end
	local a = tag(Instance.new("Attachment"), "Ribbon", root)
	local b = tag(Instance.new("Attachment"), "Ribbon", root)
	a.Position, b.Position = Vector3.new(-0.62, 0.45, 0.65), Vector3.new(0.62, -0.35, 0.65)
	local line = Instance.new("Trail")
	line.Name, line.Attachment0, line.Attachment1 = "Trail ribbon", a, b
	line.Color, line.Transparency = colors(trail), NumberSequence.new(0.15, 1)
	line.Lifetime, line.LightEmission, line.FaceCamera = 0.55, 0.8, true
	line.MinLength = 0.2
	tag(line, "Ribbon", root)
	if trail.stars or trail.sparkle then
		local glints = Instance.new("ParticleEmitter")
		glints.Name, glints.Texture = "Trail glints", "rbxasset://textures/particles/sparkles_main.dds"
		glints.Color = colors(trail)
		glints.Size = NumberSequence.new(0.28, 0)
		glints.Lifetime, glints.Rate, glints.Speed = NumberRange.new(0.5, 0.9), 6, NumberRange.new(0.2, 0.6)
		glints.LightEmission, glints.SpreadAngle = 1, Vector2.new(180, 180)
		tag(glints, "Ribbon", a)
	end
end

-- An aura: a few particles around the miner. `look` comes from the catalogue.
function Cosmetics.aura(parent, id, scale)
	local aura = C.auraById[id]
	if not aura then return end
	scale = scale or 1
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Aura"
	emitter.Color = ColorSequence.new(aura.color, aura.color:Lerp(Color3.new(1, 1, 1), 0.5))
	emitter.LightEmission, emitter.LockedToPart = 1, true
	if aura.look == "ring" then
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Shape, emitter.ShapeStyle = Enum.ParticleEmitterShape.Cylinder, Enum.ParticleEmitterShapeStyle.Surface
		emitter.Size = NumberSequence.new(0.35 * scale, 0)
		emitter.Rate, emitter.Lifetime, emitter.Speed = 10, NumberRange.new(0.8, 1.2), NumberRange.new(0.1)
		emitter.RotSpeed = NumberRange.new(-90, 90)
	elseif aura.look == "embers" then
		emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5 * scale), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency = NumberSequence.new(0.3, 1)
		emitter.Rate, emitter.Lifetime, emitter.Speed = 8, NumberRange.new(0.8, 1.4), NumberRange.new(1, 2)
		emitter.Acceleration, emitter.SpreadAngle = Vector3.new(0, 2, 0), Vector2.new(20, 20)
		emitter.EmissionDirection = Enum.NormalId.Top
	elseif aura.look == "halo" then
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Size = NumberSequence.new(0.22 * scale, 0)
		emitter.Rate, emitter.Lifetime, emitter.Speed = 14, NumberRange.new(0.6, 1), NumberRange.new(0)
		emitter.Shape, emitter.ShapeStyle = Enum.ParticleEmitterShape.Cylinder, Enum.ParticleEmitterShapeStyle.Surface
	else
		emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4 * scale), NumberSequenceKeypoint.new(0.5, 1.2 * scale), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency = NumberSequence.new(0.55, 1)
		emitter.Rate, emitter.Lifetime, emitter.Speed = 5, NumberRange.new(1.5, 2.2), NumberRange.new(0.3, 0.6)
		emitter.RotSpeed, emitter.SpreadAngle = NumberRange.new(-40, 40), Vector2.new(180, 180)
	end
	local holder = Instance.new("Part")
	holder.Name, holder.Transparency, holder.Massless = "Aura " .. aura.id, 1, true
	holder.CanCollide, holder.CanTouch, holder.CanQuery = false, false, false
	holder.Size = if aura.look == "halo" then Vector3.new(1.4, 0.05, 1.4) * scale
		elseif aura.look == "ring" then Vector3.new(3.2, 0.2, 3.2) * scale
		else Vector3.new(2.2, 3, 2.2) * scale
	emitter.Parent = holder
	holder.Parent = parent
	return holder
end

local function wearAura(player, char, root)
	clear(root, "Aura")
	local old = char:FindFirstChild("Miner aura")
	if old then old:Destroy() end
	local id = player:GetAttribute("Aura")
	local holder = id and id ~= "" and Cosmetics.aura(char, id)
	if not holder then return end
	holder.Name = "Miner aura"
	local look = C.auraById[id].look
	local offset = if look == "halo" then CFrame.new(0, 2.7, 0)
		elseif look == "ring" then CFrame.new(0, -2.6, 0)
		else CFrame.new(0, 0, 0)
	holder.CFrame = root.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = root, holder, holder
end

local function dress(player, char)
	local root = char:WaitForChild("HumanoidRootPart", 8)
	if not root or player.Character ~= char then return end
	ribbon(root, player:GetAttribute("Trail"))
	wearAura(player, char, root)
end

function Cosmetics.join(player)
	local function update()
		if player.Character then task.spawn(dress, player, player.Character) end
	end
	player:GetAttributeChangedSignal("Trail"):Connect(update)
	player:GetAttributeChangedSignal("Aura"):Connect(update)
	player.CharacterAdded:Connect(function(char)
		task.spawn(dress, player, char)
	end)
	update()
end

return Cosmetics
