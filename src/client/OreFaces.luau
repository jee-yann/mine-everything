-- Dresses every open mine block face in the Ink & Facet look. Each face shows its Storybook Ink
-- drawing (DrawnFaces) and gem blocks grow 3D crystals out of one face. Without drawings, faces
-- fall back to an ink frame plus 3D relief and decor. Calcite marks cave ceilings either way.
-- The nearest crystals and reliefs get ink outlines. Ores from Gold up (OreLooks `shine`) give off
-- a soft, slowly breathing light: Gold barely, Starfall the most.
local Tags = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Art, Looks = require(Shared.MineralRelief), require(Shared.OreLooks)
local Config = require(Shared.GameConfig)
local InkFrame = require(script.Parent.InkFrame)
local Drawn = require(script.Parent.DrawnFaces)
local normals = Enum.NormalId:GetEnumItems()

local function faceCFrame(block, face)
	local normal = Vector3.FromNormalId(face)
	local at = block.Position + normal * block.Size * 0.5
	local axis = if normal.Y ~= 0 then Vector3.zAxis else Vector3.yAxis
	local p = (block.Position / Config.Cell):Floor()
	local turn = (p.X * 7 + p.Y * 13 + p.Z * 3 + face.Value) % 4
	return CFrame.lookAt(at, at - normal, axis) * CFrame.Angles(0, 0, turn * math.pi / 2)
end

-- A block's crystals break out of one open face: the top if it is open, then a side, then the bottom.
local crownOrder = {
	Enum.NormalId.Top,
	Enum.NormalId.Front,
	Enum.NormalId.Back,
	Enum.NormalId.Right,
	Enum.NormalId.Left,
	Enum.NormalId.Bottom,
}
local function crownFace(mask)
	for _, face in crownOrder do
		if bit32.btest(mask, 2 ^ face.Value) then
			return face
		end
	end
	return nil
end

-- Which 3D art an open face wants: "crystals", "crown", "relief", "calcite", "decor" or nil.
-- A drawn face already shows the ore or the rock, so it only adds crystals and calcite.
local function wanted(block, face, mask, calcite, drawn)
	local name = block.Name
	local crowned = Art.hasCrown(name) and crownFace(mask) == face
	if Art.isMineral(name) then
		if drawn then
			return if crowned then "crystals" else nil
		end
		return if crowned then "crown" else "relief"
	elseif bit32.btest(calcite, 2 ^ face.Value) then
		return "calcite"
	elseif not drawn and Art.decorates(name, (block.Position / Config.Cell):Floor(), face.Value) then
		return "decor"
	end
	return nil
end

local function build(block, face, kind)
	local cf = faceCFrame(block, face)
	if kind == "relief" or kind == "crown" then
		return Art.face(block.Name, cf, nil, kind == "crown"), cf
	elseif kind == "crystals" then
		return Art.crown(block.Name, cf), cf
	end
	local p = (block.Position / Config.Cell):Floor()
	if kind == "calcite" then
		return Art.decor("Calcite", cf, 1 + (p.X + p.Z) % 2), cf
	end
	return Art.decor(block.Name, cf, 1 + (p.X + p.Y + p.Z + face.Value) % 3), cf
end

return function()
	local folders, glowing, reliefs = {}, {}, {}
	local ink = Color3.fromHex(Looks.ink)
	local outlineFolder = Instance.new("Folder")
	outlineFolder.Name = "Ink outlines"
	outlineFolder.Parent = workspace
	local outlines = table.create(Looks.outlines.count)
	for i = 1, Looks.outlines.count do
		local h = Instance.new("Highlight")
		h.Name, h.Enabled, h.FillTransparency = "Ink outline", false, 1
		h.OutlineColor, h.OutlineTransparency, h.DepthMode = ink, 0, Enum.HighlightDepthMode.Occluded
		h.Parent = outlineFolder
		outlines[i] = h
	end

	local function removeArt(art)
		reliefs[art.model] = nil
		art.model:Destroy()
	end

	-- A small pool of lights that follow the nearest glowing ores.
	local glow = Looks.glow
	local slots = table.create(glow.lights)
	for i = 1, glow.lights do
		local at = Instance.new("Attachment")
		at.Name = "Ore glow"
		local light = Instance.new("PointLight")
		light.Name, light.Enabled, light.Shadows = "Ore glow", false, false
		light.Parent = at
		at.Parent = workspace.Terrain
		slots[i] = { attachment = at, light = light, block = nil, base = 0, speed = 1, phase = 0 }
	end
	local function release(block)
		for _, slot in slots do
			if slot.block == block then
				slot.block, slot.light.Enabled = nil, false
			end
		end
	end
	local function lerp(pair, t)
		return pair[1] + (pair[2] - pair[1]) * t
	end
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for _, slot in slots do
			if slot.block then
				slot.light.Brightness = slot.base * (1 + glow.pulse * math.sin(t * slot.speed + slot.phase))
			end
		end
	end)

	local function watchFolder(folder)
		if folders[folder] or not folder:IsDescendantOf(workspace) then
			return
		end
		local blocks = {}
		local function watchBlock(block)
			if blocks[block] or not block:IsA("BasePart") then
				return
			end
			local arts, skins = {}, {}
			local color, shine = Art.glow(block.Name), Art.shine(block.Name)
			local cell = (block.Position / Config.Cell):Floor()
			local phase = (cell.X * 1.7 + cell.Y * 2.3 + cell.Z * 0.9) % (2 * math.pi)
			local function refresh()
				local mask = block:GetAttribute("OpenFaces") or 0
				local calcite = block:GetAttribute("CalciteFaces") or 0
				for _, face in normals do
					local open = bit32.btest(mask, 2 ^ face.Value)
					local skin = skins[face]
					if open and not skin then
						local key = Drawn.key(block.Name, cell, face.Value)
						local decal = key and Drawn.apply(block, face, key)
						skin = { decal = decal or InkFrame.apply(block, face), drawn = decal ~= nil }
						skins[face] = skin
					elseif not open and skin then
						if skin.decal then
							skin.decal:Destroy()
						end
						skins[face], skin = nil, nil
					end
					local kind = if open then wanted(block, face, mask, calcite, skin.drawn) else nil
					local art = arts[face]
					if art and art.kind ~= kind then
						removeArt(art)
						arts[face], art = nil, nil
					end
					if kind and not art then
						local model, cf = build(block, face, kind)
						model.Parent = block
						arts[face] = { model = model, kind = kind }
						if kind == "relief" or kind == "crown" or kind == "crystals" then
							reliefs[model] = cf.Position
						end
					end
				end
				if color and shine then
					-- The light sits just off the face the crystals use, so it lights the ore itself.
					local face = crownFace(mask)
					if face then
						local at = block.Position + Vector3.FromNormalId(face) * (block.Size.Y * 0.5 + glow.offset)
						glowing[block] = { position = at, color = color, shine = shine, phase = phase }
					else
						glowing[block] = nil
					end
				end
			end
			local exposed = block:GetAttributeChangedSignal("OpenFaces"):Connect(refresh)
			local marked = block:GetAttributeChangedSignal("CalciteFaces"):Connect(refresh)
			blocks[block] = function()
				exposed:Disconnect()
				marked:Disconnect()
				glowing[block] = nil
				release(block)
				for _, art in arts do
					removeArt(art)
				end
				for _, skin in skins do
					if skin.decal then
						skin.decal:Destroy()
					end
				end
			end
			refresh()
		end
		local function forgetBlock(block)
			if blocks[block] then
				blocks[block]()
				blocks[block] = nil
			end
		end
		local added = folder.ChildAdded:Connect(watchBlock)
		local removed = folder.ChildRemoved:Connect(forgetBlock)
		folders[folder] = function()
			added:Disconnect()
			removed:Disconnect()
			for block in blocks do
				forgetBlock(block)
			end
		end
		for _, block in folder:GetChildren() do
			watchBlock(block)
		end
	end

	Tags:GetInstanceAddedSignal(Config.MineBlockTag):Connect(watchFolder)
	Tags:GetInstanceRemovedSignal(Config.MineBlockTag):Connect(function(folder)
		if folders[folder] then
			folders[folder]()
			folders[folder] = nil
		end
	end)
	for _, folder in Tags:GetTagged(Config.MineBlockTag) do
		watchFolder(folder)
	end

	-- Ink outlines go to the nearest ore reliefs. Only the two closest gem faces cast light.
	local range = Looks.outlines.range
	while task.wait(0.32) do
		local camera = workspace.CurrentCamera
		if not camera then
			continue
		end
		local eye = camera.CFrame.Position
		local near = {}
		for model, position in reliefs do
			local distance = (eye - position).Magnitude
			if distance < range then
				table.insert(near, { model = model, distance = distance })
			end
		end
		table.sort(near, function(a, b)
			return a.distance < b.distance
		end)
		local keep = {}
		for i = 1, math.min(#outlines, #near) do
			keep[near[i].model] = true
		end
		local free = {}
		for _, h in outlines do
			if h.Adornee and keep[h.Adornee] then
				keep[h.Adornee] = nil
			else
				h.Adornee, h.Enabled = nil, false
				table.insert(free, h)
			end
		end
		for model in keep do
			local h = table.remove(free)
			if not h then
				break
			end
			h.Adornee, h.Enabled = model, true
		end

		-- Light the nearest glowing ores. A light keeps its ore while that ore stays among the nearest.
		local lit = {}
		for block, g in glowing do
			local distance = (eye - g.position).Magnitude
			if distance < glow.range then
				table.insert(lit, { block = block, distance = distance })
			end
		end
		table.sort(lit, function(a, b)
			return a.distance < b.distance
		end)
		local want = {}
		for i = 1, math.min(#slots, #lit) do
			want[lit[i].block] = true
		end
		local spare = {}
		for _, slot in slots do
			local g = slot.block and glowing[slot.block]
			if g and want[slot.block] then
				want[slot.block] = nil
				slot.attachment.WorldPosition = g.position
			else
				slot.block, slot.light.Enabled = nil, false
				table.insert(spare, slot)
			end
		end
		for block in want do
			local slot = table.remove(spare)
			if not slot then
				break
			end
			local g = glowing[block]
			slot.block, slot.phase = block, g.phase
			slot.base, slot.speed = lerp(glow.brightness, g.shine), 1.1 + g.shine * 0.9
			slot.attachment.WorldPosition = g.position
			slot.light.Color, slot.light.Range = g.color, lerp(glow.reach, g.shine)
			slot.light.Brightness, slot.light.Enabled = slot.base, true
		end
	end
end
