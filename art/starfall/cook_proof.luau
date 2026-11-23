-- The filmed sample is a square mine cell. Every visible facet is a native
-- part so a cold client can show it on the first frame of the broadcast.
local S = require(game.ReplicatedStorage.Scenery)
local minerals = require(game.ReplicatedStorage.MineralRelief)
local V, CF = Vector3.new, CFrame.new
local art = S.group("ProspectorProof")
local root = S.part(art, "Datum", CF(), V(0.05, 0.05, 0.05), "FFFFFF")
root.Transparency, root.CastShadow, art.PrimaryPart = 1, false, root

local function ring(parent, a, b, colors)
	for i, p in a do
		local j = i % #a + 1
		local tone = colors[(i - 1) % #colors + 1]
		S.facet(parent, "Cut plane", p, a[j], b[i], tone)
		S.facet(parent, "Cut plane", a[j], b[j], b[i], tone)
	end
end

local function fill(parent, points, center, tone)
	for i, p in points do
		S.facet(parent, "Flat face", p, points[i % #points + 1], center, tone)
	end
end

-- Emerald-cut girdle seen face-on. Each corner is clipped to leave eight
-- straight sides and a broad, level table facing the reveal camera.
local octagon = {
	Vector2.new(-0.62, 1), Vector2.new(0.62, 1), Vector2.new(1, 0.72), Vector2.new(1, -0.72),
	Vector2.new(0.62, -1), Vector2.new(-0.62, -1), Vector2.new(-1, -0.72), Vector2.new(-1, 0.72),
}
local function outline(pose, w, h, z)
	local p = {}
	for i, q in octagon do p[i] = pose * V(q.X * w, q.Y * h, z) end
	return p
end
local matrix = { minerals.matrix.Emerald, "5B7769", "587267", "516E61", "5E786A", "587366", "567267", "5F7A6D" }
local stratum = { "849888", "9CAC95", "A2B39B", "859C88", "748C7C", "849889", "92A58F", "B4BEAA" }
local bedrock = { "5D7468", "6E8272", "738671", "627768", "556E60", "5E786C", "728577", "8B9A86" }

local function inclusion(parent, pose, scale)
	local bed = outline(pose, 0.23 * scale, 0.29 * scale, 0.004)
	local face = outline(pose, 0.18 * scale, 0.225 * scale, 0.035)
	ring(parent, bed, face, { "5FC985", "92DFA2", "54B782", "1B7856", "257856", "38A96D", "65C28B", "79D997" })
	fill(parent, face, pose * V(0, 0, 0.035), "42AD75")
end

for _, side in { -1, 1 } do
	local rock = S.group(if side == -1 then "Left" else "Right")
	rock.Parent = art
	local datum = S.part(rock, "Fracture datum", CF(side * 0.74, 0, 0), V(0.05, 0.05, 0.05), "FFFFFF")
	datum.Transparency, datum.CastShadow, rock.PrimaryPart = 1, false, datum

	-- A continuous shell goes from the outside to the shallow mineral
	-- pocket. There are no overlapping center walls along the exposed cut.
	local endCap, shoulder, cut, lip, cove, back = {}, {}, {}, {}, {}, {}
	for i = 1, 16 do
		local a = (i - 1) * math.pi / 8
		local dy, dz = math.sin(a), math.cos(a)
		local square = math.max(math.abs(dy), math.abs(dz))
		local y, z = dy / square, dz / square
		local seam = 0.035 * math.sin(i * 1.73)
		endCap[i], shoulder[i] = V(side * 0.96, y * 0.88 - 0.005, z * 0.89), V(side * 0.915, y * 0.925 - 0.005, z * 0.93)
		cut[i] = V(seam, y * 0.925 - 0.005, z * 0.93)
		local bevel = math.max(math.abs(dy), math.abs(dz), (math.abs(dy) + math.abs(dz)) / 1.66)
		local h, w = dy / bevel, dz / bevel
		lip[i] = V(seam + 0.04 * side, h * 0.75 - 0.035, w * 0.75)
		cove[i] = V(side * 0.22, h * 0.63 - 0.04, w * 0.63)
		back[i] = V(side * 0.43, h * 0.50 - 0.04, w * 0.50)
	end
	root:SetAttribute("ReadingNotch", cut[4])
	fill(rock, endCap, V(side * 0.96, -0.005, 0), matrix[1])
	ring(rock, endCap, shoulder, matrix)
	ring(rock, shoulder, cut, matrix)
	ring(rock, cut, lip, stratum)
	ring(rock, lip, cove, bedrock)
	ring(rock, cove, back, { "5E7467", "677C6E", "6C8172", "586F62" })
	fill(rock, back, V(side * 0.43, -0.04, 0), "526A60")
	inclusion(rock, CFrame.fromMatrix(V(side * 0.96, -0.02, 0.07), -side * Vector3.zAxis, Vector3.yAxis)
		* CFrame.Angles(0, 0, math.rad(17)), 1.34)
	inclusion(rock, CF(side * 0.49, -0.13 * side, 0.93) * CFrame.Angles(0, 0, math.rad(side * 19)), 0.90)
	inclusion(rock, CFrame.fromMatrix(V(side * 0.46, 0.92, -side * 0.18), Vector3.xAxis, -Vector3.zAxis), 0.72)
	for i, x in { 0, side * 0.96 } do
		for j, z in { -0.93, 0.93 } do rock:SetAttribute("Contact" .. i .. j, V(x, -0.93, z)) end
	end
end

local foot, waist, bed = {}, {}, {}
for i = 1, 8 do
	local a = (i - 0.7) * math.pi / 4
	local x, z = math.cos(a) * 0.43, math.sin(a) * 0.34
	foot[i], waist[i] = V(x * 0.93, -0.93, z), V(x * 1.04, -0.78, z * 1.02)
	bed[i] = V(x * 0.80, -0.46 + 0.030 * math.sin(i * 1.9), z * 0.81)
end
ring(art, foot, waist, bedrock)
ring(art, waist, bed, bedrock)
fill(art, bed, V(-0.035, -0.40, 0.04), "738D78")

local emerald = S.group("Step-cut emerald")
emerald.Parent = art
local pose = CF(-0.025, -0.02, 0.06) * CFrame.Angles(math.rad(-17), math.rad(-8), math.rad(-7))
root:SetAttribute("EmeraldTable", pose * V(0, 0, 0.177))
root:SetAttribute("EmeraldCrown", pose * V(0, 0.32, 0.177))
local dark = { "1C8859", "378B5C", "126946", "16744D", "1C875A", "18754F", "136647", "369A69" }
local jade = { "8DDEA4", "5BCC95", "20A168", "21835F", "38B079", "259C64", "247E5C", "66D898" }
local light = { "BAF3C7", "6DDDA2", "36BC83", "57C78A", "93E0A2", "49B684", "57CC93", "97E7B9" }
local tiers = {
	{ 0.49, 0.52, -0.175, dark }, { 0.90, 0.90, -0.095, dark }, { 1.00, 1.00, 0.015, jade },
	{ 1.00, 1.00, 0.045, dark }, { 0.88, 0.90, 0.100, light }, { 0.76, 0.79, 0.145, jade },
	{ 0.63, 0.69, 0.177, light },
}
local last
for _, tier in tiers do
	local loop = outline(pose, 0.38 * tier[1], 0.49 * tier[2], tier[3])
	if last then ring(emerald, last, loop, tier[4]) end
	last = loop
end
fill(emerald, last, pose * V(0, 0, 0.177), "47C692")
-- A window reflection across the flat table distinguishes polished beryl
-- from a matte green tile. Both ends terminate at the clipped table edge.
local reflection = {}
for i, v in { Vector2.new(-1, 0.02), Vector2.new(-1, 0.40), Vector2.new(0.36, 1),
	Vector2.new(0.62, 1), Vector2.new(0.85, 0.83) } do
	reflection[i] = pose * V(v.X * 0.38 * 0.63, v.Y * 0.49 * 0.69, 0.185)
end
for i = 2, #reflection - 1 do
	S.facet(emerald, "Window reflection", reflection[1], reflection[i], reflection[i + 1], "7BE1AA")
end
-- Only the upper and left table edges catch the bench light.
for _, i in { 1, 7, 8 } do
	local j = i % #last + 1
	S.strut(emerald, "Table highlight", last[i], last[j], 0.009, 0.009, "75CFA4", Enum.Material.Neon)
end

local bin = game:GetService("SerializationService"):SerializeInstancesAsync({ art })
local bytes = buffer.tostring(game:GetService("EncodingService"):Base64Encode(bin))
for i = 1, #bytes, 2000 do print("PROOF_DATA", bytes:sub(i, i + 1999)) end
print("PROOF_READY")
