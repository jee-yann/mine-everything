-- Deterministic rock chips and dust. Every exposure is solved from its age, so
-- a dropped frame or a seek always lands on the same drawing.
local S = require(script.Parent.Scenery)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local Debris = {}
Debris.__index = Debris

function Debris.new(count, colors, seed, glow)
	local rng = Random.new(seed)
	local model = S.group("Flying chips")
	local chips, puffs = {}, {}
	for i = 1, count do
		local size = rng:NextNumber(0.07, 0.24)
		local lit = glow and i % 3 == 0
		local part = S.part(model, "Chip", CF(), V(size, size * 0.62, size * 1.5),
			if lit then glow else colors[(i - 1) % #colors + 1],
			if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic, "WedgePart")
		local angle, spread = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0.15, 1)
		table.insert(chips, {
			part = part,
			velocity = V(math.cos(angle) * spread * 7, math.sin(angle) * spread * 5 + 4.2, rng:NextNumber(5, 12)),
			spin = V(rng:NextNumber(-11, 11), rng:NextNumber(-11, 11), rng:NextNumber(-11, 11)),
			life = rng:NextNumber(15, 24),
			size = part.Size,
		})
	end
	for _ = 1, 5 do
		local anchor = S.part(model, "Dust", CF(), Vector3.one * 0.05, "FFFFFF")
		anchor.Transparency, anchor.CastShadow = 1, false
		local board = Instance.new("BillboardGui")
		board.LightInfluence, board.Size, board.Parent = 0.7, UDim2.fromScale(1, 1), anchor
		local image = Instance.new("ImageLabel")
		image.Image, image.BackgroundTransparency = "rbxasset://textures/particles/smoke_main.dds", 1
		image.Size, image.ImageColor3 = UDim2.fromScale(1, 1), Color3.fromHex(colors[1]):Lerp(Color3.new(1, 1, 1), 0.35)
		image.Rotation, image.Parent = rng:NextNumber(0, 360), board
		table.insert(puffs, {
			anchor = anchor, board = board, image = image,
			drift = V(rng:NextNumber(-1.6, 1.6), rng:NextNumber(0.1, 1.8), rng:NextNumber(0.8, 2.6)),
			size = rng:NextNumber(1.5, 2.6),
		})
	end
	return setmetatable({ model = model, chips = chips, puffs = puffs }, Debris)
end

-- `at` faces out of the struck surface along +Z.
function Debris:draw(parent, at, age, scale, floorY)
	if age < 0 or age > 26 then
		self.model.Parent = nil
		return
	end
	self.model.Parent = parent
	local t = age / 24
	for _, chip in self.chips do
		local p = at.Position + at:VectorToWorldSpace(chip.velocity) * scale * t - Vector3.yAxis * (15 * scale * t * t)
		if floorY and p.Y < floorY + 0.06 then
			p = V(p.X, floorY + 0.06, p.Z)
		end
		chip.part.CFrame = CF(p) * A(chip.spin.X * t, chip.spin.Y * t, chip.spin.Z * t)
		chip.part.Size = chip.size * scale
		chip.part.Transparency = S.ease(age, chip.life - 5, chip.life)
	end
	for _, puff in self.puffs do
		local out = 1 - math.exp(-4.2 * t)
		puff.anchor.Position = at.Position + at:VectorToWorldSpace(puff.drift) * scale * out
		local size = puff.size * scale * (0.35 + out)
		puff.board.Size = UDim2.fromScale(size, size)
		puff.image.ImageTransparency = 0.55 + 0.45 * math.min(1, age / 22)
	end
end

function Debris:Destroy()
	self.model:Destroy()
end

return Debris
