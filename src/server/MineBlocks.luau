local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Art = require(Shared.MineralRelief)
local Physics = game:GetService("PhysicsService")
local Geology = require(script.Parent.Geology)
local Details = require(script.Parent.CaveDetails)
local Blocks = {}
Blocks.__index = Blocks
local edge, cell = Config.Chunk, Config.Cell
-- Order matches Enum.NormalId so the client can paint only uncovered faces.
local directions = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis, -Vector3.xAxis, -Vector3.yAxis, -Vector3.zAxis }
local air = Enum.Material.Air
for _, name in { "MineRock", "MinerHead" } do
	if not Physics:IsCollisionGroupRegistered(name) then
		Physics:RegisterCollisionGroup(name)
	end
end
for _, group in Physics:GetRegisteredCollisionGroups() do
	Physics:CollisionGroupSetCollidable("MinerHead", group.name, group.name == "MineRock")
end
function Blocks.new(origin, parent)
	local folder = Instance.new("Folder")
	folder.Name = "MineBlocks"
	folder:AddTag(Config.MineBlockTag)
	folder.Parent = parent
	return setmetatable({ folder = folder, top = origin + Vector3.yAxis * Config.FloorY, chunks = {} }, Blocks)
end
function Blocks:reset(seed)
	self.folder:ClearAllChildren()
	self.chunks = {}
	self.starterCuts = {}
	self.geology = Geology.new(seed)
end
function Blocks:cellAt(point)
	return ((point - self.top) / cell):Floor()
end
function Blocks:center(p)
	return self.top + (p + Vector3.one * 0.5) * cell
end
-- Each chunk stores just explored air (false) and exposed solids (Parts).
-- Buried and distant cells cost no instances or per-cell storage.
function Blocks:slot(p, create)
	local key = (p / edge):Floor()
	local chunk = self.chunks[key]
	if not chunk and create then
		chunk = {}
		self.chunks[key] = chunk
	end
	local i = p - key * edge
	return chunk, 1 + i.X + edge * (i.Z + edge * i.Y)
end
function Blocks:oreAt(p)
	local chunk, index = self:slot(p, false)
	local value = chunk and chunk[index]
	if value == false or p.Y >= 0 then
		return nil
	end
	if value then
		return Ores.byName[value.Name]
	end
	return Ores.byMaterial[self.geology:material(p)]
end

local oreIds = {}
for index, ore in Ores.list do
	if not ore.host then oreIds[ore] = index end
end

-- One four-byte record per ore: signed offsets in cells, followed by its Ores.list index.
function Blocks:scanOres(center)
	local radius = Config.OreVisionRadius
	if center.Y >= radius then return buffer.create(0) end
	local hits = buffer.create((2 * radius + 1) ^ 3 * 4)
	local length = 0
	for y = -radius, math.min(radius, -1 - center.Y) do
		local slice = radius ^ 2 - y ^ 2
		local zLimit = math.floor(math.sqrt(slice))
		for z = -zLimit, zLimit do
			local xLimit = math.floor(math.sqrt(slice - z ^ 2))
			for x = -xLimit, xLimit do
				local id = oreIds[self:oreAt(center + Vector3.new(x, y, z))]
				if id then
					buffer.writei8(hits, length, x)
					buffer.writei8(hits, length + 1, y)
					buffer.writei8(hits, length + 2, z)
					buffer.writeu8(hits, length + 3, id)
					length += 4
				end
			end
		end
	end
	local result = buffer.create(length)
	buffer.copy(result, 0, hits, 0, length)
	return result
end

local function brick(self, p, material)
	local ore = Ores.byMaterial[material]
	local part = Instance.new("Part")
	part.Name = if ore then ore.name else "Packed earth"
	local strength = Config.strength(Config.FloorY + (p.Y + 0.5) * cell)
	-- Ink & Facet (OreLooks): flat rock in the stone grade's colour. Ores sit in that same rock.
	local tint = if ore then Art.rockColor(ore.name, Config.StoneGrades[strength].color) else Color3.fromRGB(111, 77, 59)
	if material == Enum.Material.Ice then
		tint = Config.layer((-p.Y - 0.5) * cell).color
	end
	local grain = (p.X * 7 + p.Y * 3 + p.Z * 11) % 5
	part.Color = tint:Lerp(if grain < 2 then Color3.new(0, 0, 0) else Color3.new(1, 1, 1), math.abs(grain - 2) * 0.016)
	part.Material = Enum.Material.SmoothPlastic
	local face = Enum.SurfaceType.Smooth
	part.TopSurface, part.BottomSurface, part.LeftSurface, part.RightSurface, part.FrontSurface, part.BackSurface =
		face, face, face, face, face, face
	part.Anchored, part.CanTouch, part.CastShadow = true, false, true
	part.CollisionGroup = "MineRock"
	part.Size, part.Position = Vector3.one * cell, self:center(p)
	if ore then
		part:SetAttribute("Hardness", strength)
	end
	return part
end
function Blocks:expose(p, face, open)
	if p.Y >= 0 then
		return
	end
	local chunk, i = self:slot(p, true)
	local part = chunk[i]
	if part == false then
		return
	end
	if not part then
		local material = self.geology:material(p)
		if material == air then
			chunk[i] = false
			table.insert(open, p)
			return
		end
		part = brick(self, p, material)
		chunk[i] = part
	end
	local old = part:GetAttribute("OpenFaces") or 0
	local mask = bit32.bor(old, bit32.lshift(1, face))
	if old == mask then
		return
	end
	part:SetAttribute("OpenFaces", mask)
	local ceiling = face == Enum.NormalId.Bottom.Value
		and (p.X + p.Z) % 3 == 0
		and self.geology:isCave(p - Vector3.yAxis)
	if ceiling and part.Name == "Stone" then
		part:SetAttribute("CalciteFaces", bit32.bor(part:GetAttribute("CalciteFaces") or 0, 2^face))
	end
	if face == Enum.NormalId.Top.Value and p.Y < -3 then
		local feature = self.geology:feature(p + Vector3.yAxis)
		if feature then
			Details.place(self, part, feature)
		end
	end
	if not part.Parent then
		part.Parent = self.folder
	end
end
function Blocks:openNeighbours(open)
	local n = 1
	while n <= #open do
		local p = open[n]
		for j, delta in directions do
			self:expose(p + delta, (j + 2) % 6, open)
		end
		n += 1
	end
end
function Blocks:openHall()
	local open = {}
	for x = -Config.HallHalfWidth / cell, Config.HallHalfWidth / cell - 1 do
		for z = Config.HallBack / cell, Config.HallFront / cell - 1 do
			self:expose(Vector3.new(x, -1, z), Enum.NormalId.Top.Value, open)
		end
	end
end
function Blocks:take(p)
	local chunk, i = self:slot(p, false)
	local part = chunk and chunk[i]
	local ore = if part then Ores.byName[part.Name] else nil
	if not ore then
		return nil
	end
	chunk[i] = false
	if p.Y == -1 and p.X >= -5 and p.X <= -3 and p.Z >= -3 and p.Z <= -2 then
		self.starterCuts[p] = os.clock() + 75
	end
	part:Destroy()
	self:openNeighbours({ p })
	return ore
end
-- Only refill a shaft mouth above an occupied tunnel if there is still another
-- connected exit to the hall. Unexplored cells are solid, including outside the island.
function Blocks:otherExit(start, closing)
	local queue, seen = { start }, { [start] = true, [closing] = true }
	local cursor = 1
	while cursor <= #queue and cursor <= 1024 do
		local p = queue[cursor]
		if p.Y == -1 and Config.inHall((p + Vector3.one * 0.5) * cell) then
			return true
		end
		for _, delta in directions do
			local q = p + delta
			if q.Y < 0 and not seen[q] then
				seen[q] = true
				local chunk, index = self:slot(q, false)
				if chunk and chunk[index] == false then
					table.insert(queue, q)
				end
			end
		end
		cursor += 1
	end
	return false
end
function Blocks:refreshStarter(now, miners)
	for p, due in self.starterCuts do
		if now < due then
			continue
		end
		local center = self:center(p)
		local below, bi = self:slot(p - Vector3.yAxis, false)
		local clear, underground = true, false
		for _, position in miners do
			local offset = position - center
			underground = underground or position.Y < self.top.Y
			if offset.Magnitude < cell * 2 then
				clear = false
				break
			end
		end
		if not clear or (underground and below and below[bi] == false and not self:otherExit(p - Vector3.yAxis, p)) then
			self.starterCuts[p] = now + 5
			continue
		end
		local chunk, i = self:slot(p, false)
		chunk[i] = nil
		self:expose(p, Enum.NormalId.Top.Value, {})
		for j, delta in directions do
			local neighbor, index = self:slot(p + delta, false)
			local solid = neighbor and neighbor[index]
			if solid == false then
				self:expose(p, j - 1, {})
			elseif solid then
				local opposite = (j + 2) % 6
				solid:SetAttribute("OpenFaces", bit32.band(solid:GetAttribute("OpenFaces"), bit32.bnot(2 ^ opposite)))
			end
		end
		self.starterCuts[p] = nil
	end
end
return Blocks
