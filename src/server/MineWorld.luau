local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.GameConfig)
local Blocks = require(script.Parent.MineBlocks)
local World = {}
World.__index = World
local terrain = workspace.Terrain
local cell = Config.Cell
local chunk = Config.Chunk * cell

local function emptyRegion(bottom, top, surface)
	local overlap = OverlapParams.new()
	overlap.MaxParts = 1
	if surface then
		overlap.FilterDescendantsInstances = { surface }
	end
	if #workspace:GetPartBoundsInBox(CFrame.new((bottom + top) / 2), top - bottom, overlap) > 0 then
		return false
	end
	for y = bottom.Y, top.Y - 1, chunk do
		local region =
			Region3.new(Vector3.new(bottom.X, y, bottom.Z), Vector3.new(top.X, math.min(y + chunk, top.Y), top.Z))
		local _, occupancy = terrain:ReadVoxels(region:ExpandToGrid(4), 4)
		-- ReadVoxels includes a named Size field alongside its indexed X planes.
		for _, plane in ipairs(occupancy) do
			for _, row in plane do
				for _, v in row do
					if v > 0 then
						return false
					end
				end
			end
		end
	end
	return true
end

function World.new(seed, surface)
	local origin = if surface then surface:GetPivot().Position else Config.Origin
	for _ = 1, 32 do
		if
			emptyRegion(origin + Config.SiteMin, origin + Config.SiteMax, surface)
			and emptyRegion(origin + Config.SurfaceMin, origin + Config.SurfaceMax, surface)
		then
			local flares = Instance.new("Folder")
			flares.Name, flares.Parent = "Survey flares", surface or workspace
			return setmetatable({
				flares = flares,
				origin = origin,
				seed = seed,
				ready = false,
				grid = Blocks.new(origin, surface or workspace),
				preview = surface and surface:FindFirstChild("EditFace"),
			}, World)
		end
		origin += Vector3.new(512, 0, 0)
	end
	error("Endless Mining needs an empty mine site. Move CitrineCove to an unused area.")
end

function World:generate()
	self.ready = false
	self.flares:ClearAllChildren()
	self.removed = 0
	self.generation = (self.generation or 0) + 1
	self.grid:reset(self.seed)
	if self.practiceStarfall then self:plantStarfall() end
	self.grid:openHall()
	if self.preview then
		self.preview:Destroy()
		self.preview = nil
	end
	self.ready = true
end
-- Studio only: a Starfall in the first layer, under the front of the dig floor, that any pick can take.
World.starfallCell = Vector3.new(1, -1, -3)
function World:plantStarfall()
	self.grid:plant(World.starfallCell, require(Shared.Ores).byName.Starfall, true)
end
function World:oreAt(point)
	return self.grid:oreAt(self.grid:cellAt(point))
end
function World:excavate(selected)
	local loot, finds = {}, {}
	for _, point in selected do
		local ore = self.grid:take(self.grid:cellAt(point))
		if ore then
			loot[ore.name] = (loot[ore.name] or 0) + 1
			if not ore.host then
				finds[ore.name] = point
			end
			self.removed += 1
		end
	end
	return loot, finds
end
return World
