-- Studio-only cooker for the matched capstones and their exposed bedrock.
local data = game:GetService("HttpService"):JSONDecode(FAULT_SOURCE)
local geom = game:GetService("GeometryService")
local options = {
	SplitApart = false,
	CollisionFidelity = Enum.CollisionFidelity.Box,
	RenderFidelity = Enum.RenderFidelity.Performance,
}
local V, CF = Vector3.new, CFrame.new
local temporary = Instance.new("Folder", workspace)
local archive = Instance.new("Folder")
archive.Name = "FaultRocks"
local function prepare(p)
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	return p
end
local function triangle(list, a, b, c)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal, back = ac:Cross(ab).Unit, bc.Unit
	local up = back:Cross(normal)
	for i, v in { b, c } do
		local width = math.abs((v - a):Dot(back))
		if width > 0.016 then
			local p = prepare(Instance.new("WedgePart"))
			local sign = if i == 1 then 1 else -1
			p.Size = V(0.080, math.abs(ab:Dot(up)), width)
			p.CFrame = CFrame.fromMatrix((v + a) / 2, normal * sign, up, back * sign)
			p.Parent = temporary
			table.insert(list, p)
		end
	end
end
local pigments = { Foot = "65565D", Cleavage = "59505B", Shale = "8D767D", Quartz = "C4AE90", Cap = "869377" }
for variant, chunks in data do
	local formation = Instance.new("Folder", archive)
	formation.Name = variant
	for key, spec in chunks do
		local model = Instance.new("Model", formation)
		model.Name = key
		local root = prepare(Instance.new("Part"))
		root.Name, root.Size, root.CFrame, root.Transparency, root.CastShadow =
			"Pivot", Vector3.one * 0.05, CF(table.unpack(spec.center)), 1, false
		root.Parent, model.PrimaryPart = model, root
		for role, facets in spec.shapes do
			local wedges = {}
			for _, f in facets do
				triangle(wedges, V(f[1], f[2], f[3]), V(f[4], f[5], f[6]), V(f[7], f[8], f[9]))
			end
			local p = table.remove(wedges, 1)
			local solid = geom:UnionAsync(p, wedges, options)[1]
			solid.Name, solid.UsePartColor, solid.Color = role, true, Color3.fromHex(pigments[role])
			solid.SmoothingAngle = 0
			solid.Material = if role == "Quartz"
				then Enum.Material.Marble
				elseif role == "Cap" then Enum.Material.Limestone
				else Enum.Material.Slate
			prepare(solid)
			solid.Parent = model
			temporary:ClearAllChildren()
		end
	end
end
local bytes = buffer.tostring(
	game:GetService("EncodingService")
		:Base64Encode(game:GetService("SerializationService"):SerializeInstancesAsync({ archive }))
)
for i = 1, #bytes, 2000 do
	print("FAULT_BYTES", bytes:sub(i, i + 1999))
end
print("FAULT_COMPLETE")
