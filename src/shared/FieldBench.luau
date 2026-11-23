-- The shore's field station doubles as the playable Ore Index and the film set.
local Bench = {}
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local wood, iron, slate = Enum.Material.Wood, Enum.Material.Metal, Enum.Material.Slate
local function block(parent, name, cf, size, ink, material, class)
	local p = Instance.new(class or "Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Color, p.Material = Color3.fromHex(ink), material or Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function facet(parent, name, a, b, c, tint, mat)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal = ac:Cross(ab)
	if normal.Magnitude < 0.00001 then
		return
	end
	local right, back = normal.Unit, bc.Unit
	local up = back:Cross(right)
	for i, v in { b, c } do
		local depth = math.abs((v - a):Dot(back))
		if depth > 0.002 then
			local sign = if i == 1 then 1 else -1
			block(
				parent,
				name,
				CFrame.fromMatrix((a + v) * 0.5, right * sign, up, back * sign),
				V(0.006, math.abs(ab:Dot(up)), depth),
				tint,
				mat or slate,
				"WedgePart"
			)
		end
	end
end

function Bench.location(landing)
	return CF(landing + V(-14.8, -1.44, 0.55))
end
function Bench.closed(top)
	return top * CF(0, 0.27, 0) * A(0.12, -0.20, math.rad(152))
end
function Bench.seat(top)
	return top * CF(-0.78, 0.14, 0.48)
end

-- Two pieces of one bedded rock. The same irregular outline bounds both
-- fracture surfaces. The inclusion is only bright when its cut face is exposed.
local edge = {
	V(-0.57, 0, -0.14),
	V(-0.33, 0, -0.40),
	V(0.20, 0, -0.36),
	V(0.55, 0, -0.12),
	V(0.44, 0, 0.26),
	V(0.10, 0, 0.35),
	V(-0.40, 0, 0.28),
}
local wall = { "625D69", "554F5D", "6B6370", "716773", "655B6B", "514E5C", "615969" }
local function fragment(parent, chip)
	local model = Instance.new("Model")
	model.Name = if chip then "Cleaved sample" else "Basalt parent rock"
	model.WorldPivot = CFrame.identity
	for i, a in edge do
		local b = edge[i % #edge + 1]
		local crown = if chip then V(-0.09, -0.19, 0.03) else V(-0.20, 0.32, -0.03)
		local shoulder = if chip then V(0.86, 1, 0.87) else V(1.24, 1, 1.19)
		local step = if chip then -0.095 else 0.16
		local innerA, innerB = a * shoulder + V(0, step, 0), b * shoulder + V(0, step, 0)
		facet(model, "Rock rind", a, b, innerB, wall[i])
		facet(model, "Rock rind", a, innerB, innerA, wall[i % 7 + 1])
		facet(model, "Cleavage", innerA, innerB, crown, wall[(i + 2) % 7 + 1])
		facet(model, "Split face", a, b, V(0, 0, 0), if chip then "82748C" else "665973")
	end
	local y = if chip then 0.011 else -0.011
	local path = { V(-0.44, y, 0.24), V(-0.23, y, 0.095), V(-0.04, y, 0.085), V(0.085, y, -0.08), V(0.40, y, -0.21) }
	local function vein(points, width, ink)
		for i = 2, #points do
			local a, b = points[i - 1], points[i]
			local side = (b - a).Unit:Cross(Vector3.yAxis) * width
			facet(model, "Violet lamina", a - side, b - side, b + side, ink, Enum.Material.Glass)
			facet(model, "Violet lamina", a - side, b + side, a + side, ink, Enum.Material.Glass)
		end
	end
	vein(path, 0.045, "B68CDB")
	vein({ path[3], V(-0.13, y, -0.14), V(-0.28, y, -0.31) }, 0.021, "A886CB")
	if chip then
		-- The inclusion goes through the rock. Its exposed lenses also follow
		-- the sloped underside, so turning the sample in the palm catches light.
		local center = V(-0.09, -0.19, 0.03)
		for i, a in edge do
			local b = edge[i % #edge + 1]
			local x = a * V(0.86, 1, 0.87) - V(0, 0.098, 0)
			local z = b * V(0.86, 1, 0.87) - V(0, 0.098, 0)
			local middle = center - V(0, 0.006, 0)
			local left = x:Lerp(middle, 0.29 + 0.12 * math.sin(i))
			local right = z:Lerp(middle, 0.51 + 0.16 * math.sin(i + 1))
			local facetTip = middle:Lerp(x:Lerp(z, 0.43), 0.38)
			local purple = ({ "8D65AA", "AA85CA", "B098BB", "A075B6" })[i % 4 + 1]
			facet(model, "Violet lamina", left, right, facetTip, purple, Enum.Material.Glass)
			if i % 2 == 0 then
				facet(model, "Violet lamina", left, left:Lerp(x, 0.47), facetTip, "B799D4", Enum.Material.Glass)
			end
		end
	end
	local pin = block(model, "Specimen origin", CFrame.identity, Vector3.one * 0.03, "FFFFFF")
	pin.Transparency, pin.CastShadow, model.PrimaryPart = 1, false, pin
	model.Parent = parent
	return model
end

local function label(p, face, words, color, font)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face, gui.CanvasSize = "Enamel lettering", face, Vector2.new(440, 86)
	gui.LightInfluence, gui.Parent = 0.45, p
	local t = Instance.new("TextLabel")
	t.Size, t.BackgroundTransparency, t.Text = UDim2.fromScale(1, 1), 1, words
	t.Font, t.TextColor3, t.TextScaled = font or Enum.Font.GothamBold, Color3.fromHex(color), true
	t.Parent = gui
end
function Bench.build(top)
	local m = Instance.new("Model")
	m.Name, m.ModelStreamingMode = "Field sample bench", Enum.ModelStreamingMode.Atomic
	local pivot = block(m, "Assay datum", CFrame.identity, Vector3.one * 0.05, "FFFFFF")
	pivot.Transparency, pivot.CastShadow, m.PrimaryPart = 1, false, pivot
	local topBoard = block(m, "Beech work surface", CF(0, -0.20, -0.28), V(5.8, 0.27, 2.32), "AE8559", wood)
	topBoard.CanCollide, topBoard.CanQuery = true, true
	for _, x in { -2.38, 2.38 } do
		for _, z in { -1.16, 0.53 } do
			block(
				m,
				"Carpenter's trestle",
				CF(x, -1.63, z) * A(0, 0, -math.sign(x) * 0.04),
				V(0.32, 2.71, 0.33),
				"4C706D",
				wood
			)
			block(m, "Iron foot", CF(x + math.sign(x) * 0.045, -2.84, z), V(0.41, 0.22, 0.43), "485358", iron)
		end
	end
	block(m, "Lower shelf", CF(0, -1.99, -0.28), V(5.09, 0.16, 1.85), "80654F", wood)
	block(m, "Front apron", CF(0, -0.54, 0.64), V(5.32, 0.54, 0.16), "416F70", wood)
	local plate = block(m, "Catalogue plate", CF(0, -0.55, 0.74), V(2.66, 0.32, 0.04), "264547", iron)
	label(plate, Enum.NormalId.Back, "FIELD SAMPLES", "F4DBAB")
	block(m, "Work leather", CF(-0.12, -0.023, 0), V(2.91, 0.055, 1.54), "6C655D", Enum.Material.Leather)
	for _, x in { -2.32, -1.88, -1.44 } do
		local box = block(m, "Core tray", CF(x, 0.025, -0.48), V(0.42, 0.22, 1.29), "8B6746", wood)
		for j = 1, 3 do
			local core = block(
				m,
				"Survey core",
				box.CFrame * CF(0, 0.17, (j - 2) * 0.37) * A(0, math.pi / 2, 0),
				V(0.335, 0.255, 0.255),
				({ "6B655E", "AB7458", "8B9294" })[j],
				slate
			)
			core.Shape = Enum.PartType.Cylinder
		end
	end
	for i = 1, 3 do
		local tray = block(m, "Archive drawer", CF((i - 2) * 1.47, -1.67, -0.44), V(1.32, 0.49, 1.10), "54716C", wood)
		block(m, "Drawer pull", tray.CFrame * CF(0, 0.05, 0.59), V(0.32, 0.08, 0.08), "DAB778", iron)
	end
	local folio = CF(1.94, 0.03, -0.14) * A(0, -0.19, 0)
	block(m, "Field notebook", folio, V(1.47, 0.15, 1.18), "644F46", wood)
	block(m, "Map sheet", folio * CF(0, 0.093, 0), V(1.36, 0.034, 1.07), "E3CE9F")
	-- A hand-drawn coast and three strata on the open survey folio.
	for i = 1, 5 do
		local z = -0.22 + 0.12 * i
		block(
			m,
			"Stratigraphic sketch",
			folio * CF(0.30, 0.12, z) * A(0, 0.11 * math.sin(i), 0),
			V(0.46 - i * 0.032, 0.01, 0.023),
			"977153"
		)
	end
	for i = 1, 7 do
		local a, b = 2 * math.pi * i / 7, 2 * math.pi * (i + 1) / 7
		local p = Vector3.new(-0.34 + 0.18 * math.cos(a), 0.121, 0.27 * math.sin(a))
		local q = Vector3.new(-0.34 + 0.21 * math.cos(b), 0.121, 0.27 * math.sin(b))
		block(m, "Coast survey", folio * CFrame.lookAt((p + q) / 2, q), V(0.024, 0.012, (p - q).Magnitude), "54716C")
	end
	local host, chip = fragment(m, false), fragment(m, true)
	host:PivotTo(Bench.closed(CFrame.identity))
	chip:PivotTo(Bench.seat(CFrame.identity))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name, prompt.ActionText, prompt.ObjectText = "Consult samples", "Open Ore Index", "Field samples"
	prompt.MaxActivationDistance, prompt.RequiresLineOfSight, prompt.Parent = 6.5, false, plate
	m:PivotTo(top)
	return m
end
return Bench
