-- The surveyed island and its construction schedule, private to one viewer.
local P, Atlas = require(script.Parent.Props), require(script.Parent.HistoryAtlas)
local Island, Worksite = require(script.Parent.HistoryIsland), require(script.Parent.HistoryWorksite)
local V, CF = Vector3.new, CFrame.new
local History = {}
History.__index = History
History.rate, History.duration = Atlas.rate, 17

local materials, surfaces, finishes, rotations = {}, {}, {}, {}
for _, v in Enum.Material:GetEnumItems() do
	materials[v.Value] = v
end
for _, v in Enum.SurfaceType:GetEnumItems() do
	surfaces[v.Value] = v
end
for i, style in Atlas.finishes do
	finishes[i] = {
		shape = style[1],
		tint = Color3.fromHex(style[2]),
		material = materials[style[3]],
		top = surfaces[style[4]],
		bottom = surfaces[style[5]],
		transparency = style[6],
	}
end
for i, angles in Atlas.orientations do
	rotations[i] = CF(0, 0, 0, table.unpack(angles))
end

local function lettering(part)
	local face = Instance.new("SurfaceGui")
	face.Name, face.Face, face.CanvasSize, face.LightInfluence =
		"Lettering", Enum.NormalId.Back, Vector2.new(256, 70), 0
	face.Parent = part
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.TextScaled, label.Font = "MINE", true, Enum.Font.FredokaOne
	label.TextColor3, label.Parent = Color3.fromHex("FFF9DB"), face
end

local function piece(model, row, base)
	local style = finishes[row[1]]
	local p = Instance.new(if style.shape == 3 then "WedgePart" else "Part")
	if style.shape == 0 then
		p.Shape = Enum.PartType.Ball
	elseif style.shape == 2 then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Color, p.Material, p.Transparency = style.tint, style.material, style.transparency
	p.TopSurface, p.BottomSurface = style.top, style.bottom
	p.Size = V(row[5], row[6], row[7])
	p.CFrame = base * CF(row[2], row[3], row[4]) * (rotations[row[8]] or CFrame.identity)
	if row[9] then
		lettering(p)
	end
	p.Parent = model
	return p
end

function History.new(stage, base)
	local parked = Instance.new("Folder")
	local self = setmetatable({
		base = base,
		stage = stage,
		shelf = parked,
		root = P.model(parked, "Citrine through time"),
		starts = {},
		containers = {},
		ends = {},
		scene = {},
		frame = -1,
		surfaceCursor = 1,
		readyThrough = -1,
		skyline = {},
		reclaimed = {},
		weathering = 0,
	}, History)
	self.loader = coroutine.create(function()
		local function spent(n)
			self.budget -= n
			if self.budget <= 0 then
				coroutine.yield()
			end
		end
		local function register(model, first, last, authoredLocal, container)
			if authoredLocal then
				model:PivotTo(base)
			end
			local a = math.max(0, math.floor(first * History.rate + 0.5))
			local b = if last then math.floor(last * History.rate + 0.5) else 10000
			table.insert(self.scene, { model, a, b })
			self.starts[a] = self.starts[a] or {}
			table.insert(self.starts[a], model)
			if last then
				self.ends[b] = self.ends[b] or {}
				table.insert(self.ends[b], model)
			end
			self.containers[model] = container
			if self.frame >= a and self.frame < b then
				model.Parent = container or self.root
			end
		end
		local function buildShot(shot)
			local group = P.model(parked, shot[2])
			local weathered = shot[2] == "Bluffs above the mine"
				or shot[2] == "Basalt capes around the harbor"
				or shot[2] == "Cascade banks"
				or shot[2] == "Outlying sandbanks"
			for _, shape in shot[3] do
				local p = piece(group, shape, base)
				if shot[1] == 0 then
					local key = shape[1]
					local pigment = self.skyline[key]
					if not pigment then
						local color = p.Color
						local old = if color.G > color.R and color.G > color.B
							then color:Lerp(Color3.fromHex("92896C"), 0.70)
							else color:Lerp(Color3.fromHex("977C77"), 0.36)
						pigment = { old = old, new = color, parts = {} }
						self.skyline[key] = pigment
					end
					p.Color = pigment.old
					table.insert(pigment.parts, p)
				elseif
					weathered or (shot[2] == "Terraced shore fill" and p.Color.G > p.Color.R and p.Color.G > p.Color.B)
				then
					local key = shot[1] * 1000 + shape[1]
					local soil = self.reclaimed[key]
					if not soil then
						soil = {
							start = if weathered then 8.5 + (shot[1] % 17) / 24 else 9.65 + (shot[1] % 23) / 24,
							old = if not weathered
								then Color3.fromHex("AE916A")
								elseif p.Color.G > p.Color.R and p.Color.G > p.Color.B then Color3.fromHex(
									"839166"
								)
								elseif shot[2] == "Basalt capes around the harbor" then p.Color:Lerp(
									Color3.fromHex("948879"),
									0.84
								)
								else p.Color:Lerp(Color3.fromHex("B0987D"), 0.85),
							new = p.Color,
							parts = {},
						}
						self.reclaimed[key] = soil
					end
					p.Color = soil.old
					table.insert(soil.parts, p)
				end
				spent(1)
			end
			register(group, shot[1] / History.rate, nil, false)
		end
		for _, shot in Atlas.exposures do
			if shot[1] == 0 then
				buildShot(shot)
			end
		end
		local coast = game:GetService("ReplicatedStorage").Shared:FindFirstChild("TideCoast")
		if coast then
			local copy = coast:Clone()
			copy.Parent = parked
			copy:PivotTo(base)
			register(copy, 0, nil, false)
		end
		self.island = Island.build(parked, register, spent)
		self.readyThrough = 1.25
		coroutine.yield()
		for _, shot in Atlas.exposures do
			if shot[1] > 0 and shot[1] < 3.25 * History.rate then
				self.readyThrough = (shot[1] - 1) / History.rate
				buildShot(shot)
			end
		end
		self.readyThrough = 3.14
		self.work = Worksite.build(parked, register, spent, self.island.dock, self.island.camp)
		Island.plant(self.island, parked, register, spent)
		for _, shot in Atlas.exposures do
			if shot[1] >= 3.25 * History.rate then
				self.readyThrough = (shot[1] - 1) / History.rate
				buildShot(shot)
			end
		end
		self.readyThrough = math.huge
	end)
	return self
end

function History:prepare(budget, mountSurface)
	-- The wide-shot set occupies a separate site from the strike. Submit
	-- its parcels over several frames before the camera reaches the coast.
	if mountSurface and self.frame < 0 then
		local queue = self.starts[0] or {}
		local allowance = 6 * budget
		self.root.Parent = self.stage
		while self.surfaceCursor <= #queue and allowance > 0 do
			local group = queue[self.surfaceCursor]
			allowance -= 1 + #group:GetDescendants()
			group.Parent = self.root
			self.surfaceCursor += 1
		end
	end
	if not self.loader then
		return
	end
	self.budget = budget
	local ok, err = coroutine.resume(self.loader)
	if not ok then
		error(err, 2)
	end
	if coroutine.status(self.loader) == "dead" then
		self.loader = nil
	end
end

function History:draw(t)
	t = math.clamp(t, 0, History.duration)
	if self.loader then
		local elapsed = math.clamp(t - (self.previousAge or t), 1 / 60, 0.13)
		self:prepare(math.ceil(620 * elapsed))
		while self.loader and self.readyThrough < t do
			self:prepare(64)
		end
		self.previousAge = t
	end
	if self.root.Parent ~= self.stage then
		self.root.Parent = self.stage
	end
	-- Group the original survey parcels into photographic exposures. During
	-- one exposure the tide, light and camera can travel across a still camp.
	local tick = math.floor(t * History.rate + 0.00001)
	local remainder = tick % History.rate
	local shutter = if remainder >= 18 then 18 elseif remainder >= 11 then 11 elseif remainder >= 7 then 7 else 0
	local frame = tick - remainder + shutter
	if self.frame == frame then
		return
	end
	local age = frame / History.rate
	if frame < self.frame then
		for _, shot in self.scene do
			shot[1].Parent = if frame >= shot[2] and frame < shot[3]
				then self.containers[shot[1]] or self.root
				else self.shelf
		end
	else
		for i = self.frame + 1, frame do
			for _, m in self.ends[i] or {} do
				m.Parent = self.shelf
			end
			for _, m in self.starts[i] or {} do
				local destination = self.containers[m] or self.root
				if m.Parent ~= destination then
					m.Parent = destination
				end
			end
		end
	end
	Island.expose(self.island, age, self.base, self.root)
	if self.work then
		Worksite.expose(self.work, age, self.base)
	end
	self.frame = frame
	local weathering = math.clamp(math.floor((age - 1.75) * 2.5), 0, 8)
	if weathering ~= self.weathering then
		for _, band in self.skyline do
			local color = band.old:Lerp(band.new, weathering / 8)
			for _, p in band.parts do
				p.Color = color
			end
		end
		self.weathering = weathering
	end
	if age >= 8 and age <= 14 or self.soilAge == nil or self.soilAge <= 14 or age < self.soilAge then
		for _, bed in self.reclaimed do
			local step = math.clamp(math.floor((age - bed.start - 0.23) * 3), 0, 7)
			if bed.step ~= step then
				bed.step = step
				local tint = bed.old:Lerp(bed.new, step / 7)
				for _, p in bed.parts do
					p.Color = tint
				end
			end
		end
	end
	self.soilAge = age
end

function History:Destroy()
	if not self.shelf then
		return
	end
	if self.loader then
		coroutine.close(self.loader)
		self.loader = nil
	end
	self.root:Destroy()
	self.shelf:Destroy()
	self.shelf = nil
end

return History
