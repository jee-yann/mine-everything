-- Dresses every open mine block face in the Ink & Facet look. Each face shows its Storybook Ink
-- drawing (DrawnFaces) and gem blocks grow 3D crystals out of one face. Without drawings, faces
-- fall back to an ink frame plus 3D relief and decor. Calcite marks cave ceilings either way.
-- The nearest crystals and reliefs get ink outlines and the two nearest gems cast light.
local Tags = game:GetService("CollectionService")
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
	local folders, luminous, lights, reliefs = {}, {}, {}, {}
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
		luminous[art.model], lights[art.model], reliefs[art.model] = nil, nil, nil
		art.model:Destroy()
	end

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
			local glow = Art.glow(block.Name)
			local cell = (block.Position / Config.Cell):Floor()
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
							if glow then
								luminous[model] = { position = cf.Position, color = glow }
							end
						end
					end
				end
			end
			local exposed = block:GetAttributeChangedSignal("OpenFaces"):Connect(refresh)
			local marked = block:GetAttributeChangedSignal("CalciteFaces"):Connect(refresh)
			blocks[block] = function()
				exposed:Disconnect()
				marked:Disconnect()
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

		local first, second
		local nearest, runnerUp = 20, 20
		for model, gem in luminous do
			local distance = (eye - gem.position).Magnitude
			if distance < nearest then
				second, runnerUp, first, nearest = first, nearest, model, distance
			elseif distance < runnerUp then
				second, runnerUp = model, distance
			end
		end
		for model, light in lights do
			if model ~= first and model ~= second then
				light:Destroy()
				lights[model] = nil
			end
		end
		for _, model in { first, second } do
			if not lights[model] then
				local light = Instance.new("PointLight")
				light.Name, light.Color, light.Range, light.Brightness = "Mineral glow", luminous[model].color, 7, 0.33
				light.Parent = model:FindFirstChildWhichIsA("BasePart")
				lights[model] = light
			end
		end
	end
end
