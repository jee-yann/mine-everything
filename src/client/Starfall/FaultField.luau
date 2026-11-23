-- The moving slabs are the same fitted solids the viewer sees before the
-- shock. Their shell vertices determine where they strike the receiving slope.
local S = require(script.Parent.Scenery)
local Tide = require(script.Parent.TideFront)
local survey = require(script.Parent.FaultSurvey)
local profiles = require(script.Parent.FaultProfiles)
local stacks = require(script.Parent.SeaStacks)
local kit = script.Parent.FaultRocks
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local clamp, sin, pi = math.clamp, math.sin, math.pi
local Fault = {}
Fault.__index = Fault
local formations = { "Shelf", "Dyke", "Tor" }
local stone = { Color3.fromHex("817B95"), Color3.fromHex("AB817A"), Color3.fromHex("897E91") }
local crowns = { Color3.fromHex("8FCB6A"), Color3.fromHex("97C86F"), Color3.fromHex("78B872") }
local ash, glow, hot = Color3.fromHex("594C52"), Color3.fromHex("E89251"), Color3.fromHex("F8C880")
local quartz, peat = Color3.fromHex("C2B49C"), Color3.fromHex("45404B")

local function dustPlume(stage, index)
	local root = S.group("Rolling ground dust")
	local solid = S.part(root, "Fold of dust", CF(), Vector3.one, "AC9184", Enum.Material.SmoothPlastic)
	solid.CastShadow, solid.Shape = false, Enum.PartType.Ball
	local billow = Instance.new("BillboardGui")
	billow.Name, billow.AlwaysOnTop, billow.LightInfluence, billow.Parent = "Feathered edge", false, 0.76, solid
	local grains = Instance.new("ImageLabel")
	grains.Size, grains.BackgroundTransparency, grains.Image =
		UDim2.fromScale(1, 1), 1, "rbxasset://textures/particles/smoke_main.dds"
	grains.ImageColor3 = if index % 2 == 0 then Color3.fromHex("D4B794") else Color3.fromHex("B59183")
	grains.Rotation, grains.Parent = index * 61 % 360, billow
	return { model = root, body = solid, card = billow, grain = grains, stage = stage }
end

local function dust(packet, base, origin, heading, tangent, age, salt, size, duration)
	if age <= 0 or age >= duration then
		if packet.model.Parent then
			packet.model.Parent = nil
		end
		return
	end
	local u = age / duration
	local scale = (0.24 + 0.76 * S.ease(u, 0, 0.30)) * (1 + 0.48 * u) * size
	local pos = origin
		+ heading * ((3 + 19 * u + 4 * u * u) * size)
		+ tangent * (sin(salt + 5 * u) * 1.55 * size)
		+ V(0, (1.4 + 3.4 * u + 0.9 * sin(pi * u)) * size, 0)
	packet.body.Size = V(11.4 * scale, 5.5 * scale, 7.9 * scale)
	packet.body.CFrame = base * CF(pos) * A(0, salt + 0.27 * u, 0.14 * sin(salt + 3 * u))
	local fade = S.ease(u, 0.27, 1)
	packet.body.Transparency = 0.58 + 0.42 * fade
	packet.card.Size = UDim2.fromScale(21.5 * scale, 13.2 * scale)
	packet.grain.ImageTransparency = 0.20 + 0.8 * fade
	packet.grain.Rotation = salt * 37 + 33 * u
	packet.model.Parent = packet.stage
end

local function compactDetail()
	local input = game:GetService("UserInputService")
	local quality = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	return (input.TouchEnabled and not input.KeyboardEnabled) or (quality >= 1 and quality <= 3)
end

local function makeSite(root, base, row, index, compact)
	local x, y, z, scale, yaw, sx, sz, targets, fissure = table.unpack(row)
	local variant = formations[(index - 1) % #formations + 1]
	local form = kit[variant]
	local origin = V(x, y, z)
	local heading = V(x, 0, z + 32).Unit
	local groundNormal = V(-sx, 1, -sz).Unit
	local right = V(1, sx, 0).Unit
	local localFrame = CFrame.fromMatrix(origin - V(0, 0.32, 0) * scale, right, groundNormal, right:Cross(groundNormal))
		* A(0, yaw, 0)
	local bed = form.Bed:Clone()
	bed:ScaleTo(scale)
	bed:PivotTo(base * localFrame)
	bed.Parent = root
	local site = {
		origin = origin,
		heading = heading,
		tangent = heading:Cross(Vector3.yAxis),
		scale = scale,
		pieces = {},
		dust = {},
		cracks = {},
		bed = bed,
		cut = 5.1 + Tide.arrival(V(x, 0, z + 32).Magnitude),
		salt = index * 1.354,
		stone = stone[(index - 1) % 3 + 1],
		crown = crowns[index % 3 + 1],
		band = -1,
	}
	for j, mark in targets do
		local m = form["Leaf" .. j]:Clone()
		local offset = m:GetPivot().Position * scale
		m:ScaleTo(scale)
		local rest = localFrame * CF(offset)
		m:PivotTo(base * rest)
		m.Shale.Color, m.Cap.Color = site.stone, site.crown
		m.Parent = root
		local xx, gy, zz, flight, arc, gx, gz = table.unpack(mark)
		local turn = A(
			(index % 2 * 2 - 1) * (0.90 + 0.22 * j),
			(j - 2) * 1.07 + 0.32,
			((index + j) % 2 * 2 - 1) * (1.3 + 0.38 * j)
		)
		local terminal = rest.Rotation * turn
		local depth = -math.huge
		for _, v in profiles[variant][j] do
			local vert = terminal * (v * scale)
			depth = math.max(depth, gx * vert.X + gz * vert.Z - vert.Y)
		end
		local sink = gy < 20.56
		-- A hillside yields under these heavy slabs. Cap the support from the
		-- tangent plane at the one end that strikes first and embed its heel.
		local embedded = math.clamp(depth, 0, 2.65 * scale) - 0.40 * scale
		local strike = V(xx, gy + embedded - (if sink then scale * 2.55 else 0), zz)
		site.pieces[j] = {
			shell = m,
			rest = rest,
			target = strike,
			ground = V(xx, gy, zz),
			air = flight,
			arc = arc,
			spin = turn,
			terminal = terminal,
			wet = sink,
			delay = 0.055 + (j - 1) * 0.077 + (index % 4) * 0.015,
			where = "rest",
		}
	end
	for j = 1, #fissure - 1 do
		local a, b = V(table.unpack(fissure[j])), V(table.unpack(fissure[j + 1]))
		local p = S.strut(root, "Shear fracture", a, b, (1.65 - 0.28 * j) * scale, 0.10, "DB9867", Enum.Material.Neon)
		p.Transparency, p.CastShadow = 1, false
		site.cracks[j] = p
	end
	local layers = if compact then (if index % 3 == 0 then 2 else 1) else (if index % 2 == 0 then 3 else 2)
	for j = 1, layers do
		site.dust[j] = dustPlume(root, j + index)
	end
	return site
end

local function drawSlab(v, age, base, direction, scale)
	local elapsed = age - v.delay
	local location
	if elapsed < -0.12 then
		if v.where == "rest" then
			return
		end
		location = v.rest
		v.where = "rest"
	elseif elapsed < 0 then
		local u = S.ease(elapsed, -0.12, 0)
		location = v.rest + direction * u * 0.63 * scale + V(0, u * 0.35 * scale, 0)
		v.where = "cracked"
	elseif elapsed <= v.air then
		local u = elapsed / v.air
		local p = (v.rest.Position + direction * 0.63 * scale):Lerp(v.target, u)
			+ V(0, 4 * v.arc * u * (1 - u) + 0.35 * scale * (1 - u), 0)
		location = CF(p) * v.rest.Rotation * CFrame.identity:Lerp(v.spin, u)
		v.where = "in flight"
	elseif elapsed < v.air + 0.39 then
		local u = (elapsed - v.air) / 0.39
		local bounce = sin(u * pi) * (1 - u) * (if v.wet then 0.29 else 1.27) * scale
		location = CF(v.target + V(0, bounce, 0)) * v.terminal * A(0, 0, bounce * 0.065)
		v.where = "landing"
	else
		if v.where == "landed" then
			return
		end
		location = CF(v.target) * v.terminal
		v.where = "landed"
	end
	v.shell:PivotTo(base * location)
end

function Fault.new(stage, base)
	local root = S.group("Fracturing island")
	local compact = compactDetail()
	local self = setmetatable(
		{
			root = root,
			base = base,
			stage = stage,
			sites = {},
			compact = compact,
			coast = {},
			branches = {},
		},
		Fault
	)
	for i, row in survey do
		self.sites[i] = makeSite(root, base, row, i, compact)
	end
	for i, spec in stacks do
		local n, x, z, phi, scale, loose = table.unpack(spec)
		local origin = V(x, 19.92, z)
		local frame = CF(origin) * A(0, -phi, 0)
		local foot, top = kit.Stacks["Base" .. n]:Clone(), kit.Stacks["Lid" .. n]:Clone()
		local center = top:GetPivot().Position * scale
		local rest = frame * CF(center)
		foot:ScaleTo(scale)
		top:ScaleTo(scale)
		foot:PivotTo(base * frame)
		top:PivotTo(base * rest)
		top.Quartz.Color = if i % 3 == 0 then Color3.fromHex("A39376") else Color3.fromHex("A39981")
		top.Cap.Color = crowns[i % 3 + 1]
		foot.Parent, top.Parent = root, root
		if loose then
			local heading = V(x, 0, z + 32).Unit
			local spin = A(1.74, 0.78, 1.58)
			local target = origin + heading * (19.0 * scale) + V(0, -3.6 * scale, 0)
			table.insert(self.coast, {
				shell = top,
				rest = rest,
				target = target,
				ground = V(target.X, 20.3, target.Z),
				air = 1.22,
				arc = 9.6 * scale,
				spin = spin,
				terminal = rest.Rotation * spin,
				wet = true,
				delay = 0.12,
				where = "rest",
				scale = scale,
				dir = heading,
				date = 5.1 + Tide.arrival(V(x, 0, z + 32).Magnitude),
			})
		end
	end
	return self
end

function Fault:addCanopy(tree, index)
	local crown = tree.model:FindFirstChild("Sea-grape crown") or tree.model:FindFirstChild("Salt-pruned crown")
	if not crown then
		return
	end
	local trunk = tree.rest
	local offset = trunk:PointToObjectSpace(crown.Position)
	local out = self.base:VectorToObjectSpace(tree.axis):Cross(Vector3.yAxis).Unit
	local p = self.base:PointToObjectSpace(trunk.Position)
	local release = p + out * (offset.Magnitude * 0.73) + V(0, math.max(1.5, offset.Y * 0.39), 0)
	local model = S.group("Broken crown and salt leaves")
	local size = math.clamp(offset.Magnitude * 0.55, 2.1, 5.8)
	local sticks = {}
	sticks[1] = S.strut(
		model,
		"Splintered bough",
		V(-size * 0.48, -0.39, 0),
		V(size * 0.55, 0.53, 0.28),
		0.34,
		0.40,
		"6F5F50",
		Enum.Material.Wood
	)
	for i = 2, 4 do
		local leaf = S.part(
			model,
			"Leaf cluster",
			CF((i - 3) * 0.31 * size, 0.4, (i % 2 - 0.5) * 0.47 * size) * A(0.2, -0.44 * i, 0.29),
			V(0.35 * size, 0.21 * size, 0.75 * size),
			"67B96A",
			Enum.Material.SmoothPlastic
		)
		leaf.CastShadow = false
		sticks[i] = leaf
	end
	table.insert(
		self.branches,
		{
			model = model,
			sticks = sticks,
			origin = release,
			dir = out,
			size = size,
			roll = index * 0.84,
			date = 5.10 + tree.arrival + 0.48,
		}
	)
end

function Fault:draw(t, active)
	if active ~= (self.root.Parent ~= nil) then
		self.root.Parent = if active then self.stage else nil
	end
	if not active then
		return
	end
	local still = if t < 4.87 then 1 elseif t >= 11.4 then 2 else 0
	if still ~= 0 and self.still == still then
		return
	end
	self.still = still
	local frame = math.floor(t * (if self.compact then 30 else 48))
	if frame == self.last then
		return
	end
	self.last = frame
	for _, v in self.coast do
		drawSlab(v, t - v.date, self.base, v.dir, v.scale)
	end
	for _, b in self.branches do
		local age = t - b.date
		if age >= 0 and age < 1.35 then
			local u = age / 1.35
			local pos = b.origin + b.dir * (u * (14.6 + b.size * 1.6)) + V(0, b.size * (4.7 * u - 5.6 * u * u), 0)
			b.model:PivotTo(self.base * CF(pos) * A(2.5 * age + b.roll, 3.8 * age, -2.1 * age))
			for _, leaf in b.sticks do
				leaf.Transparency = S.ease(u, 0.62, 1)
			end
			if b.model.Parent ~= self.root then
				b.model.Parent = self.root
			end
		elseif b.model.Parent then
			b.model.Parent = nil
		end
	end
	for _, v in self.sites do
		local age = t - v.cut
		local temp = if age < -0.15 then 0 elseif age < 0.08 then 1 elseif age < 0.70 then 2 else 3
		if temp ~= v.band then
			v.band = temp
			for j, p in v.pieces do
				p.shell.Quartz.Color = if temp == 1
					then quartz:Lerp(glow, 0.44)
					elseif temp == 2 then v.stone:Lerp(glow, 0.30)
					elseif temp == 3 then ash:Lerp(quartz, 0.22)
					else quartz
				p.shell.Quartz.Material = Enum.Material.Marble
				p.shell.Shale.Color = if temp == 2
					then v.stone:Lerp(Color3.fromHex("A58C7E"), 0.48)
					elseif temp == 3 then v.stone:Lerp(ash, (j + 1) * 0.09)
					else v.stone
				p.shell.Cap.Color = if temp == 3 then ash elseif temp == 2 then v.crown:Lerp(ash, 0.44) else v.crown
			end
			v.bed.Cleavage.Color = if temp == 2 then glow elseif temp == 3 then peat else ash
			for j, p in v.cracks do
				p.Color = if temp == 1 then hot:Lerp(ash, 0.28) elseif temp == 2 then glow:Lerp(ash, 0.50) else peat
				p.Material = if temp == 1 and j <= 2 then Enum.Material.Neon else Enum.Material.Slate
				p.Transparency = if temp == 0
					then 1
					elseif temp == 1 then 0.29 + j * 0.07
					else 0.20
			end
		end
		for _, slab in v.pieces do
			drawSlab(slab, age, self.base, v.heading, v.scale)
		end
		for j, packet in v.dust do
			local roll = j < 3
			local origin = if roll then v.origin + v.tangent * ((j - 1.45) * 4.4 * v.scale) else v.pieces[2].ground
			local delay = if roll then 0.13 + j * 0.09 else v.pieces[2].air + v.pieces[2].delay
			dust(
				packet,
				self.base,
				origin,
				v.heading,
				v.tangent,
				age - delay,
				v.salt + j,
				v.scale * (if j == 1 then 1.22 else 0.83),
				if roll then 2.15 + j * 0.19 else 1.18
			)
		end
	end
end
function Fault:Destroy()
	for _, site in self.sites do
		for _, packet in site.dust do
			packet.model:Destroy()
		end
	end
	for _, b in self.branches do
		b.model:Destroy()
	end
	self.root:Destroy()
end
return Fault
