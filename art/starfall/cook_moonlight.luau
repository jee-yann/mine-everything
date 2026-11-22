-- Embed the surveyed tree shadows and narrow, moon-facing shelf lips.
local data = game:GetService("HttpService"):JSONDecode(RELIEF_FACETS)
local geom = game:GetService("GeometryService")
local options = {
	SplitApart = false,
	CollisionFidelity = Enum.CollisionFidelity.Box,
	RenderFidelity = Enum.RenderFidelity.Performance,
}
local V, CF = Vector3.new, CFrame.new
local temporary = Instance.new("Folder", workspace)
local archive = Instance.new("Model")
archive.Name = "MoonlitShelves"
archive.WorldPivot = CFrame.identity
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
			p.Size = V(0.034, math.abs(ab:Dot(up)), width)
			p.CFrame = CFrame.fromMatrix((v + a) / 2, normal * sign, up, back * sign)
			p.Parent = temporary
			table.insert(list, p)
		end
	end
end

-- CSG is cooked offline; all clients get the same native mesh at any quality.
local colors = { Umbra = "152035", LunarGrass = "87B7D3", LunarShingle = "A0B6CF", Canopy = "758392" }
for _, region in data do
	local role, facets = region[1], region[2]
	for start = 1, #facets, 65 do
		local wedges = {}
		for i = start, math.min(start + 64, #facets) do
			local f = facets[i]
			triangle(wedges, V(table.unpack(f[1])), V(table.unpack(f[2])), V(table.unpack(f[3])))
		end
		if #wedges == 0 then
			continue
		end
		local first = table.remove(wedges, 1)
		local p = if #wedges > 0 then geom:UnionAsync(first, wedges, options)[1] else first:Clone()
		if p:IsA("PartOperation") then
			p.UsePartColor = true
			p.SmoothingAngle = 0
		end
		p.Name, p.Material, p.Color, p.CastShadow =
			role, Enum.Material.SmoothPlastic, Color3.fromHex(colors[role]), false
		prepare(p)
		p.Parent = archive
		temporary:ClearAllChildren()
	end
end
local bytes = buffer.tostring(
	game:GetService("EncodingService")
		:Base64Encode(game:GetService("SerializationService"):SerializeInstancesAsync({ archive }))
)
for i = 1, #bytes, 2000 do
	print("LUNAR_BYTES", bytes:sub(i, i + 1999))
end
print("LUNAR_COMPLETE")
