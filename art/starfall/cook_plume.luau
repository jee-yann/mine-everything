-- Offline Studio cooker used by bake_plume.py. No asset upload is required.
local data = game:GetService("HttpService"):JSONDecode(BRUSH_SOURCE)
local g = game:GetService("GeometryService")
local opt =
	{ SplitApart = false, CollisionFidelity = Enum.CollisionFidelity.Box, RenderFidelity = Enum.RenderFidelity.Precise }
local V, CF = Vector3.new, CFrame.new
local scratch = Instance.new("Folder", workspace)
local lib = Instance.new("Folder")
lib.Name = "PressureBloom"
local function basic(p)
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.CastShadow = false
end
local colors = { Mantle = "81404B", Fold = "D95736", Lip = "FFA73F", Flame = "FFCF60" }
local function face(list, a, b, c)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local cross = ac:Cross(ab)
	if cross.Magnitude < 0.001 then
		return
	end
	local n, f = cross.Unit, bc.Unit
	local up = f:Cross(n)
	for i, v in { b, c } do
		local w = math.abs((v - a):Dot(f))
		if w > 0.015 then
			local p = Instance.new("WedgePart")
			local sign = if i == 1 then 1 else -1
			p.CFrame = CFrame.fromMatrix((v + a) / 2, n * sign, up, f * sign)
			p.Size = V(0.05, math.abs(ab:Dot(up)), w)
			basic(p)
			p.Parent = scratch
			table.insert(list, p)
		end
	end
end
for _, name in { "Roll", "Curl" } do
	local form = Instance.new("Model")
	form.Name = name
	local pivot = Instance.new("Part")
	pivot.Name, pivot.Size, pivot.Transparency = "Root", Vector3.one * 0.05, 1
	basic(pivot)
	pivot.Parent, form.PrimaryPart = form, pivot
	for _, role in { "Mantle", "Fold", "Lip", "Flame" } do
		local pieces = {}
		for _, f in data.shapes[name][role] do
			face(pieces, V(f[1], f[2], f[3]), V(f[4], f[5], f[6]), V(f[7], f[8], f[9]))
		end
		local first = table.remove(pieces, 1)
		local solid = g:UnionAsync(first, pieces, opt)[1]
		solid.Name, solid.UsePartColor, solid.SmoothingAngle = role, true, 67
		solid.Color = Color3.fromHex(colors[role])
		basic(solid)
		solid.Parent = form
		scratch:ClearAllChildren()
	end
	form.Parent = lib
end
local jet = Instance.new("Model")
jet.Name = "Jet"
local root = Instance.new("Part")
root.Size, root.Name, root.Transparency = Vector3.one * 0.05, "Root", 1
basic(root)
root.Parent, jet.PrimaryPart = jet, root
local brushwork = { Fold = {}, Lip = {}, Flame = {} }
for _, contour in data.jets do
	local prev
	for j, v in contour do
		local ring = {}
		for k = 1, 5 do
			local angle = 2 * math.pi * (k - 1) / 5 + 0.075 * j
			ring[k] = V(v[1] + v[4] * math.cos(angle), v[2], v[3] + v[4] * math.sin(angle) * 0.81)
		end
		if prev then
			for k = 1, 5 do
				local nextK = k % 5 + 1
				local layer = brushwork[if k == 1 or k == 5 then "Flame" elseif k == 3 then "Fold" else "Lip"]
				face(layer, prev[k], prev[nextK], ring[k])
				face(layer, ring[k], prev[nextK], ring[nextK])
			end
		end
		prev = ring
	end
end
for role, pieces in brushwork do
	local p = table.remove(pieces, 1)
	local solid = g:UnionAsync(p, pieces, opt)[1]
	basic(solid)
	solid.Name, solid.UsePartColor, solid.Color = role, true, Color3.fromHex(colors[role])
	solid.Parent = jet
end
jet.Parent = lib
local archive = game:GetService("SerializationService"):SerializeInstancesAsync({ lib })
local bytes = buffer.tostring(game:GetService("EncodingService"):Base64Encode(archive))
for i = 1, #bytes, 2000 do
	print("PLUME_BYTES", bytes:sub(i, i + 1999))
end
print("PLUME_ARCHIVE_COMPLETE")
