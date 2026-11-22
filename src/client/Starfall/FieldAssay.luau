local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local FieldAssay = {}
FieldAssay.__index = FieldAssay

-- The film moves a local copy of the equipped tier from hip to shoulder, then
-- photographs the same forged beak against the surveyor's fixed route seal.
local function copyPick(character, u)
	local pick = S.group("Expedition pick")
	local equipped = character:FindFirstChild("Harbor pick")
	local handle = equipped and equipped:FindFirstChild("Handle")
	local tape = equipped and equipped:FindFirstChild("Grip tape")
	if handle and tape then
		local origin = CF(tape.Position) * handle.CFrame.Rotation
		for _, original in equipped:GetChildren() do
			if original:IsA("BasePart") then
				local part = original:Clone()
				part:ClearAllChildren()
				part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
				part.LocalTransparencyModifier = 0
				part.CFrame, part.Parent = origin:ToObjectSpace(original.CFrame), pick
			end
		end
		local tip = origin:PointToObjectSpace(handle.CFrame * V(-0.91, 0.76, 0))
		return pick, tip, equipped
	end
	-- Match the starter pick while a late avatar equip streams in.
	S.strut(pick, "Ash handle", V(0, -0.28, 0), V(0, 0.88, 0), 0.13, 0.15, "AA673A", Enum.Material.Wood)
	S.strut(pick, "Steel head", V(-0.35, 0.76, 0), V(0.34, 0.86, 0), 0.23, 0.19, "C1D6DF", Enum.Material.Metal)
	S.strut(pick, "Forged beak", V(-0.35, 0.76, 0), V(-0.54, 0.64, 0), 0.13, 0.11, "ADC3CF", Enum.Material.Metal)
	pick:ScaleTo(u)
	return pick, V(-0.54, 0.64, 0) * u, nil
end

-- Trace the moving steel from the beak's actual photographed positions. The
-- arc stays registered to the equipped tool on long arms and on dropped frames.
local function bladeStreak(tool, unit)
	local steel = tool:FindFirstChildWhichIsA("BasePart")
	local knots, strokes, history = {}, {}, {}
	for i = 1, 5 do
		local knot = Instance.new("Attachment")
		knot.Name, knot.Parent = "Beak exposure", steel
		knots[i] = knot
		if i > 1 then
			local stroke = Instance.new("Beam")
			stroke.Name, stroke.Attachment0, stroke.Attachment1 = "Steel afterimage", knots[i - 1], knot
			stroke.FaceCamera, stroke.LightEmission, stroke.LightInfluence = true, 0.82, 0
			stroke.Color = ColorSequence.new(Color3.fromRGB(138, 194, 241), Color3.fromRGB(237, 255, 255))
			stroke.Transparency = NumberSequence.new(0.22 + 0.55 * (i - 2) / 3)
			stroke.Width0, stroke.Width1 = unit * (6 - i) * 0.063, unit * (5 - i) * 0.063
			stroke.Segments, stroke.Enabled, stroke.Parent = 1, false, steel
			strokes[i - 1] = stroke
		end
	end
	return function(frame, tip)
		if tip then
			if history[1] and frame <= history[1].frame then
				table.clear(history)
			end
			table.insert(history, 1, { frame = frame, point = tip })
			while frame - history[#history].frame > 4 do
				table.remove(history)
			end
		elseif #history == 0 then
			return
		else
			table.clear(history)
		end
		for i, sample in history do
			knots[i].WorldPosition = sample.point
		end
		for i, stroke in strokes do
			stroke.Enabled = i < #history
		end
	end
end

function FieldAssay.new(arrival)
	local char = arrival.root.Parent
	local tool, tip, equipped = copyPick(char, arrival.unit)
	local chips = S.group("Splinters of country rock")
	local debris = {}
	local rng = Random.new(221)
	for i = 1, 9 do
		local size = rng:NextNumber(0.035, 0.105) * arrival.unit
		local part = S.part(
			chips,
			"Cleavage chip",
			CF(),
			V(size, size * 0.58, size * 1.8),
			if i % 3 == 0 then "ECD0FF" elseif i % 2 == 0 then "9474C4" else "474053",
			if i % 3 == 0 then Enum.Material.Neon else Enum.Material.Slate,
			"WedgePart"
		)
		table.insert(debris, {
			part = part,
			beaconTone = part.Color,
			beaconFinish = part.Material,
			velocity = V(rng:NextNumber(-4.8, 4.8), rng:NextNumber(1.8, 5), rng:NextNumber(-3.2, 0.7)) * arrival.unit,
			spin = V(rng:NextNumber(-6, 8), rng:NextNumber(-7, 6), rng:NextNumber(3, 9)),
		})
	end
	return setmetatable({
		tool = tool,
		tip = tip,
		streak = bladeStreak(tool, arrival.unit),
		alignment = CFrame.lookAt(Vector3.zero, tip, Vector3.zAxis):Inverse(),
		equipped = equipped,
		hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"),
		chips = chips,
		debris = debris,
		hidden = {},
	}, FieldAssay)
end

function FieldAssay:show(active)
	if active == self.active then
		return
	end
	self.active = active
	if active and self.equipped then
		for _, part in self.equipped:GetChildren() do
			if part:IsA("BasePart") then
				self.hidden[part] = part.LocalTransparencyModifier
				part.LocalTransparencyModifier = 1
			end
		end
	elseif not active then
		for part, was in self.hidden do
			if part.Parent and part.LocalTransparencyModifier == 1 then
				part.LocalTransparencyModifier = was
			end
		end
		table.clear(self.hidden)
	end
end

function FieldAssay:draw(a, frame, contact)
	local trial = frame < F.portrait
	local age = frame - (if trial then F.proofStrike else contact)
	local active = frame >= F.present and frame < F.mineRun + 5
	self:show(active)
	self.tool.Parent = if active then a.stage else nil
	if not active then
		self.streak(frame, nil)
		self.chips.Parent = nil
		return
	end
	local basis, hand = a.mineBearing, self.hand
	local socket = hand and hand:FindFirstChild("RightGripAttachment")
	local grip = if socket
		then socket.WorldPosition
		elseif hand then hand.CFrame * V(0, -hand.Size.Y * 0.39, 0)
		else basis * (V(1.16, -0.42, -0.55) * a.unit)
	local shoulder = S.ease(frame, F.portrait - 30, F.portrait - 10)
	local overswing = S.ease(frame, F.portrait - 24, F.portrait - 17) * (
			1 - S.ease(frame, F.portrait - 17, F.portrait - 6)
		)
	local prep = if trial then 0 else S.ease(frame, F.beacon, F.prompt)
	local pull = if trial then -14 else -8
	local apex = if trial then -6 else -4
	local lead = S.ease(age, pull, apex)
	local snap = S.ease(age, apex, 0)
	local recover = S.ease(age, 2, if trial then 13 else 15)
	local hip = V(0.62, -0.33, -0.68).Unit
	local perched = V(0.46 + 0.35 * overswing, 0.62, 0.79 - 0.24 * overswing).Unit
	local home = basis:VectorToWorldSpace(hip:Lerp(perched, shoulder).Unit)
	local core = if trial then a.proof.seam.WorldPosition else a.marker.core.WorldPosition
	local aim = core - grip
	local target = if aim.Magnitude > 0.01 then aim.Unit else basis.LookVector
	if trial then
		-- The miner sights along the steel without touching the matrix.
		-- There is a single blow, followed by a clear withdrawal from the intact gem.
		local study = S.ease(frame, F.measure - 12, F.measure + 11) * (1 - S.ease(age, pull, apex))
		local probe = core + basis:VectorToWorldSpace(V(0.045, 0.31 + 0.13 * (1 - study), 0.17) * a.unit) - grip
		if probe.Magnitude > 0.02 then
			home = home:Lerp(probe.Unit, study).Unit
		end
		if age > 0 then
			local lower = S.ease(age, 1, 17) * (1 - shoulder)
			home = home:Lerp(basis:VectorToWorldSpace(V(0.91, -0.12, 0.39)).Unit, lower).Unit
		end
	end
	local upstroke = basis:VectorToWorldSpace(V(0.42, 0.82, 0.45)).Unit
	local pitched = home:Lerp(upstroke, math.max(0.25 * prep, lead)).Unit
	local sweep = pitched:Lerp(target, snap * (1 - recover)).Unit
	if recover > 0 then
		sweep = sweep:Lerp(home, recover).Unit
	end
	local rest = V(0, 1, 0)
	if math.abs(sweep:Dot(rest)) > 0.92 then
		rest = basis.LookVector
	end
	-- The fixed post never slides to meet the blade. Seat the beak precisely
	-- on the photograph of contact even with unusually scaled arms and tools.
	local endGrip = core - sweep * self.tip.Magnitude
	local register = S.ease(age, if trial then -1 else -3, 0) * (1 - S.ease(age, 1, 7))
	grip = grip:Lerp(endGrip, register)
	local pose = CFrame.lookAt(grip, grip + sweep, rest) * self.alignment
	self.tool:PivotTo(pose)
	local tracing = a.motion and age >= apex - 1 and age <= 3
	self.streak(frame, if tracing then pose * self.tip else nil)
	if age >= 0 and age < (if trial then 28 else 17) then
		self.chips.Parent = a.stage
		local seconds = age / 24
		for i, chip in self.debris do
			if self.lastCut ~= trial then
				chip.part.Color = if trial
					then Color3.fromHex(({ "C4BB97", "A59E89", "ECE1BB" })[1 + i % 3])
					else chip.beaconTone
				chip.part.Material = if trial then Enum.Material.Slate else chip.beaconFinish
			end
			local t = if trial then math.min(seconds, 0.62 + i * 0.018) else seconds
			local position = core + basis:VectorToWorldSpace(chip.velocity) * t - Vector3.yAxis * (12 * a.unit * t * t)
			local spin = chip.spin * t
			chip.part.CFrame = CF(position) * A(spin.X, spin.Y, spin.Z)
			chip.part.Transparency = S.ease(age, if trial then 16 else 6, if trial then 27 else 16)
		end
		self.lastCut = trial
	else
		self.chips.Parent = nil
	end
end
function FieldAssay:Destroy()
	self:show(false)
	self.tool:Destroy()
	self.chips:Destroy()
end
return FieldAssay
