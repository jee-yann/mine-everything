-- How cosmetics look, shared by the server (what everyone sees) and the client (previews):
-- player auras, player-trail ribbons and the spark a mining trail throws.
local C = require(script.Parent.Collectibles)
local Looks = {}

function Looks.sequence(entry)
	local colors = C.colors(entry)
	local a, b = colors[1], colors[2]
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, a),
		ColorSequenceKeypoint.new(0.5, a:Lerp(b, 0.5)),
		ColorSequenceKeypoint.new(1, b),
	})
end

-- A player aura: a few particles in an invisible holder part. `look` comes from the catalogue.
function Looks.aura(parent, id, scale)
	local aura = C.auraById[id]
	if not aura then return nil end
	scale = scale or 1
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Aura"
	emitter.Color = ColorSequence.new(aura.color, aura.color:Lerp(Color3.new(1, 1, 1), 0.5))
	emitter.LightEmission, emitter.LockedToPart = 1, true
	if aura.look == "ring" then
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
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
	return holder, aura.look
end

-- Where an aura sits on a miner, from the root.
function Looks.auraOffset(look)
	return if look == "halo" then CFrame.new(0, 2.7, 0) elseif look == "ring" then CFrame.new(0, -2.6, 0) else CFrame.identity
end

-- A player trail on `root`: two attachments and a ribbon between them, plus glints for the best ones.
-- Every instance made is passed to `mark` (to tag it, or to clean it up later).
function Looks.ribbon(root, id, mark)
	local entry = C.ribbonById[id or ""]
	if not entry then return nil end
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Position, b.Position = Vector3.new(-0.62, 0.45, 0.65), Vector3.new(0.62, -0.35, 0.65)
	mark(a)
	mark(b)
	a.Parent, b.Parent = root, root
	local line = Instance.new("Trail")
	line.Name, line.Attachment0, line.Attachment1 = "Trail ribbon", a, b
	line.Color, line.Transparency = Looks.sequence(entry), NumberSequence.new(0.15, 1)
	line.Lifetime, line.LightEmission, line.FaceCamera, line.MinLength = 0.55, 0.8, true, 0.2
	mark(line)
	line.Parent = root
	if entry.glints then
		local glints = Instance.new("ParticleEmitter")
		glints.Name, glints.Texture = "Trail glints", "rbxasset://textures/particles/sparkles_main.dds"
		glints.Color = Looks.sequence(entry)
		glints.Size = NumberSequence.new(0.28, 0)
		glints.Lifetime, glints.Rate, glints.Speed = NumberRange.new(0.5, 0.9), 6, NumberRange.new(0.2, 0.6)
		glints.LightEmission, glints.SpreadAngle = 1, Vector2.new(180, 180)
		mark(glints)
		glints.Parent = a
	end
	return line
end

return Looks
