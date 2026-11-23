-- Union the faceted shells at 48x scale to preserve the tiny growth bands.
local source = game.HttpService:JSONDecode(SPECIMEN_SOURCE)
local geometry = game:GetService("GeometryService")
local options = {
	SplitApart = false,
	CollisionFidelity = Enum.CollisionFidelity.Box,
	RenderFidelity = Enum.RenderFidelity.Precise,
}
local scratch = Instance.new("Folder", workspace)
local model = Instance.new("Model")
model.Name = "AssayTrace"
local scale = 48

local function prepare(part)
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
end

local origin = Instance.new("Part")
origin.Name, origin.Size = "Matrix", Vector3.one * 0.1
origin.Transparency, origin.CastShadow = 1, false
prepare(origin)
origin.Parent, model.PrimaryPart = model, origin

local function triangle(parts, tone, a, b, c)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local cross = ac:Cross(ab)
	if cross.Magnitude < 1e-5 then
		return
	end
	local normal, back = cross.Unit, bc.Unit
	local up = back:Cross(normal)
	for i, vertex in { b, c } do
		local depth = math.abs((vertex - a):Dot(back))
		if depth > 0.002 then
			local part = Instance.new("WedgePart")
			local side = if i == 1 then 1 else -1
			part.Size = Vector3.new(0.014, math.abs(ab:Dot(up)), depth)
			part.CFrame = CFrame.fromMatrix((a + vertex) / 2, normal * side, up, back * side)
			part.Color = Color3.fromHex(tone)
			prepare(part)
			part.Parent = scratch
			table.insert(parts, part)
		end
	end
end

for name, facets in source do
	local parts = {}
	for _, face in facets do
		local a = Vector3.new(face[2], face[3], face[4]) * scale
		local b = Vector3.new(face[5], face[6], face[7]) * scale
		local c = Vector3.new(face[8], face[9], face[10]) * scale
		triangle(parts, face[1], a, b, c)
	end
	local first = table.remove(parts, 1)
	local solid = geometry:UnionAsync(first, parts, options)[1]
	solid.Name, solid.SmoothingAngle = name, 0
	solid.UsePartColor = name:match("^Flash") ~= nil or name == "Living thread"
	if solid.UsePartColor then
		solid.Color = Color3.fromHex(facets[1][1])
	end
	solid.Material = if name == "Pyrite" then Enum.Material.Metal
		elseif name == "Transmitted light" then Enum.Material.Neon
		else Enum.Material.SmoothPlastic
	solid.Reflectance = if name:find("Crystal") then 0.07 elseif name == "Growth bands" then 0.04 else 0
	prepare(solid)
	solid.Parent = model
	scratch:ClearAllChildren()
end

-- Normalize the on-disk Model scale so the live avatar can scale its whole tray.
model:ScaleTo(1 / scale)
local archive = Instance.new("Model")
archive.Name = model.Name
for _, object in model:GetChildren() do
	object.Parent = archive
end
archive.PrimaryPart = origin
local packed = game:GetService("SerializationService"):SerializeInstancesAsync({ archive })
local bytes = buffer.tostring(game:GetService("EncodingService"):Base64Encode(packed))
for i = 1, #bytes, 2000 do
	print("ASSAY_DATA", bytes:sub(i, i + 1999))
end
print("ASSAY_READY")
