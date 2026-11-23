-- Dresses every open mine block face in the Ink & Facet look. Each face shows its Storybook Ink
-- drawing (DrawnFaces), and on gems the drawing's ore pieces stand a little out of the face.
-- Without drawings, faces fall back to an ink frame plus 3D relief, gem crystals and decor.
-- Calcite marks cave ceilings either way.
-- The nearest 3D reliefs and crystals (shown without drawings) get ink outlines. Ores from Gold
-- up (OreLooks `shine`) glow from their ore pieces: Gold barely, Starfall the most.
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

-- Which 3D art an open face wants: "raised", "crown", "relief", "calcite", "decor" or nil.
-- A drawn face already shows the ore or the rock, so it only adds raised gem pieces and calcite.
local function wanted(block, face, mask, calcite, drawn)
	local name = block.Name
	if Art.isMineral(name) then
		if drawn then
			return if Art.hasCrown(name) then "raised" else nil
		end
		return if Art.hasCrown(name) and crownFace(mask) == face then "crown" else "relief"
	elseif bit32.btest(calcite, 2 ^ face.Value) then
		return "calcite"
	elseif not drawn and Art.decorates(name, (block.Position / Config.Cell):Floor(), face.Value) then
		return "decor"
	end
	return nil
end

-- A gem's ore pieces raised off one face: thin clear layers just above the face, each showing
-- the pieces (DrawnFaces), darker underneath, so from an angle they read as standing out.
-- The layers keep the block's orientation so their pieces line up with the face's drawing.
local function raise(block, face)
	local pieces = Drawn.pieces(block.Name)
	if not pieces then
		return nil
	end
	local settings = Looks.raised
	local normal = Vector3.FromNormalId(face)
	local across = Vector3.new(math.abs(normal.X), math.abs(normal.Y), math.abs(normal.Z))
	local half = (block.Size * across).Magnitude * 0.5
	local model = Instance.new("Model")
	model.Name = block.Name .. " raised"
	for i = 1, settings.layers do
		local top = i == settings.layers
		local part = Instance.new("Part")
		part.Name, part.Anchored, part.Transparency = if top then "Top" else "Layer", true, 1
		part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
		part.Size = block.Size * (Vector3.one - across) + across * 0.02
		-- The lowest layer sits right on the face, dark, covering the drawing's flat pieces.
		local lift = half + 0.01 + (settings.height - 0.01) * (i - 1) / (settings.layers - 1)
		part.CFrame = block.CFrame + block.CFrame:VectorToWorldSpace(normal * lift)
		local decal = Instance.new("Decal")
		decal.Name, decal.Face = "Ore pieces", face
		if not pcall(function()
			decal.ColorMapContent = pieces
		end) then
			model:Destroy()
			return nil
		end
		local shade = settings.shade
		local k = if top then 1 else shade[1] + (shade[2] - shade[1]) * (i - 1) / (settings.layers - 2)
		decal.Color3 = Color3.new(k, k, k)
		decal.Parent = part
		part.Parent = model
	end
	return model
end

local function build(block, face, kind)
	local cf = faceCFrame(block, face)
	if kind == "relief" or kind == "crown" then
		return Art.face(block.Name, cf, nil, kind == "crown"), cf
	elseif kind == "raised" then
		return raise(block, face), cf
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

	-- A small pool for the nearest glowing ores. Each slot owns a spotlight held a little off the
	-- ore's face and aimed outward, so it lights the tunnel but not the ore's own rock or the wall
	-- around it, and a self-lit overlay per face that shows the ore's glow image over its drawing.
	local glow = Looks.glow
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player and player:WaitForChild("PlayerGui")
	local sources = Instance.new("Folder")
	sources.Name = "Ore glow"
	sources.Parent = workspace
	local slots = table.create(glow.ores)
	for i = 1, glow.ores do
		local source = Instance.new("Part")
		source.Name, source.Anchored, source.Transparency, source.Size = "Ore glow", true, 1, Vector3.one * 0.2
		source.CanCollide, source.CanQuery, source.CanTouch, source.CastShadow = false, false, false, false
		local light = Instance.new("SpotLight")
		light.Face, light.Angle, light.Shadows, light.Enabled = Enum.NormalId.Front, glow.light.angle, false, false
		light.Parent = source
		source.Parent = sources
		local overlays = {}
		for _, face in normals do
			local gui = Instance.new("SurfaceGui")
			gui.Name, gui.Face, gui.Enabled, gui.ResetOnSpawn = "Ore glow", face, false, false
			gui.LightInfluence, gui.ZOffset = 0, 0.02
			gui.SizingMode, gui.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(256, 256)
			local image = Instance.new("ImageLabel")
			image.Name, image.Size, image.BackgroundTransparency = "Glow", UDim2.fromScale(1, 1), 1
			-- On top and bottom faces a SurfaceGui sits a quarter turn from a Decal; turn it back.
			local flat = face == Enum.NormalId.Top or face == Enum.NormalId.Bottom
			image.Rotation = if flat then 270 else 0
			image.Parent = gui
			gui.Parent = playerGui
			overlays[face] = gui
		end
		slots[i] = { source = source, light = light, overlays = overlays, phase = 0, speed = 1, light0 = 0, piece0 = 1 }
	end
	local function lerp(pair, t)
		return pair[1] + (pair[2] - pair[1]) * t
	end
	local function unlight(slot)
		slot.block, slot.dressed, slot.light.Enabled = nil, nil, false
		for _, gui in slot.overlays do
			gui.Enabled, gui.Adornee = false, nil
		end
	end
	local function release(block)
		for _, slot in slots do
			if slot.block == block then
				unlight(slot)
			end
		end
	end
	-- Moves a slot's light onto the ore's face and shows its glow image on every drawn open face.
	local function dress(slot, block, g)
		local normal = Vector3.FromNormalId(g.face)
		local at = block.Position + normal * (block.Size.Y * 0.5 + glow.light.offset)
		local up = if math.abs(normal.Y) > 0.9 then Vector3.zAxis else Vector3.yAxis
		slot.source.CFrame = CFrame.lookAt(at, at + normal, up)
		local image = Drawn.glow(block.Name)
		for face, gui in slot.overlays do
			local on = image ~= nil and g.faces[face] == true
			if on then
				local label = gui:FindFirstChild("Glow") :: ImageLabel
				label.ImageContent = image
				label.ImageTransparency = lerp(glow.pieces.transparency, g.shine)
				gui.Adornee, gui.Brightness = g.tops[face] or block, slot.piece0
			else
				gui.Adornee = nil
			end
			gui.Enabled = on
		end
		slot.dressed = g
	end
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for _, slot in slots do
			if slot.block then
				local k = 1 + glow.pulse * math.sin(t * slot.speed + slot.phase)
				slot.light.Brightness = slot.light0 * k
				for _, gui in slot.overlays do
					if gui.Enabled then
						gui.Brightness = slot.piece0 * k
					end
				end
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
						if model then
							model.Parent = block
							arts[face] = { model = model, kind = kind }
							if kind == "relief" or kind == "crown" then
								reliefs[model] = cf.Position
							end
						end
					end
				end
				if color and shine then
					-- Light shines out of one open face: the top if it is open, then a side, then the bottom.
					local face = crownFace(mask)
					if face then
						-- The glow shows on each drawn face, or on its raised pieces when a gem has them.
						local drawn, tops = {}, {}
						for f, skin in skins do
							drawn[f] = skin.drawn
							local raised = arts[f]
							tops[f] = raised and raised.kind == "raised" and raised.model:FindFirstChild("Top") or nil
						end
						glowing[block] = {
							position = block.Position + Vector3.FromNormalId(face) * block.Size.Y * 0.5,
							face = face,
							faces = drawn,
							tops = tops,
							color = color,
							shine = shine,
							phase = phase,
						}
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
				if slot.dressed ~= g then
					dress(slot, slot.block, g)
				end
			else
				unlight(slot)
				table.insert(spare, slot)
			end
		end
		for block in want do
			local slot = table.remove(spare)
			if not slot then
				break
			end
			local g = glowing[block]
			slot.block, slot.phase, slot.speed = block, g.phase, 1.1 + g.shine * 0.9
			slot.light0, slot.piece0 = lerp(glow.light.brightness, g.shine), lerp(glow.pieces.brightness, g.shine)
			slot.light.Color, slot.light.Range = g.color, lerp(glow.light.reach, g.shine)
			slot.light.Brightness, slot.light.Enabled = slot.light0, true
			dress(slot, block, g)
		end
	end
end
