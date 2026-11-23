-- The flying shot and the later historical miniature use the same survey.
-- The inner disk belongs to Crater so the ground can actually deform on impact.
local P = require(script.Parent.Props)
local Land = require(script.Parent.HistoryLandform)
local Mantle = require(script.Parent.HistoryMantle)
local Atlas = require(script.Parent.HistoryAtlas)
local V, CF, rgb = Vector3.new, CFrame.new, Color3.fromHex
local Coast = {}

function Coast.new(root)
	local coast = P.model(root, "Ancient mine headland")
	local rim = {}
	for i = 1, Land.slices do
		local a = i * math.pi * 2 / Land.slices
		rim[i] = V(33.4 * math.cos(a), 0.78 + 0.67 * math.sin(3 * a), 28.6 * math.sin(a))
	end
	-- Continue out from the moving basin to the sampled modern cliff footings.
	local shades = { "7E716B", "80776F", "74756C", "737768", "697365", "626A69", "7B756C" }
	for r = 4, Land.rings do
		local outer = {}
		for i = 1, Land.slices do
			outer[i] = Land.vertex(r, i) - Land.crater
		end
		for i, a in rim do
			local j = i % #rim + 1
			local c = rgb(shades[r - 3]):Lerp(rgb("958987"), 0.10 * (0.5 + 0.5 * math.sin(i * 1.9 + r)))
			P.face(coast, a, outer[i], outer[j], c)
			P.face(coast, a, outer[j], rim[j], c)
		end
		rim = outer
	end
	local stone = { "796C73", "9B8179", "B49A83", "A6907A", "898089", "B79B84", "756A78" }
	for _, face in Mantle.faces do
		local ia, ib, ic, tone = table.unpack(face)
		P.face(
			coast,
			Mantle.points[ia][1] - Land.crater,
			Mantle.points[ib][1] - Land.crater,
			Mantle.points[ic][1] - Land.crater,
			rgb(stone[tone])
		)
	end
	local rotations = {}
	for i, matrix in Atlas.orientations do
		rotations[i] = CF(0, 0, 0, table.unpack(matrix))
	end
	for _, shot in Atlas.exposures do
		if shot[1] ~= 0 then
			break
		end
		for _, row in shot[3] do
			local style = Atlas.finishes[row[1]]
			local shape = style[1]
			local ink = rgb(style[2])
			local exposed = if ink.G > ink.R then rgb("817F72") else rgb("83767D")
			local at = V(row[2], row[3], row[4]) - Land.crater
			local face = P.part(
				coast,
				shot[2],
				V(row[5], row[6], row[7]),
				CF(at) * (rotations[row[8]] or CFrame.identity),
				exposed:Lerp(ink, 0.20),
				if shape == 3 then "WedgePart" else "Part"
			)
			if shape == 0 or shape == 2 then
				face.Shape = if shape == 0 then Enum.PartType.Ball else Enum.PartType.Cylinder
			end
			face.Material = Enum.Material.Slate
		end
	end
	for x = -2, 2 do
		for z = -2, 2 do
			if x ~= 0 or z ~= 0 then
				local ocean = P.box(coast, "Dawn strait", V(x * 1960, -3.95, z * 1960), V(1960, 0.8, 1960), "568F9F")
				ocean.Reflectance, ocean.CastShadow = 0.05, false
			end
		end
	end
	-- Ocean remains at the visible shoreline elevation. The crater interior
	-- is below that elevation; keep the water plane outside the basin.
	for _, item in { { -510, 0, 940, 1960 }, { 510, 0, 940, 1960 }, { 0, -510, 80, 940 }, { 0, 510, 80, 940 } } do
		local ocean =
			P.box(coast, "Strait around the headland", V(item[1], -3.95, item[2]), V(item[3], 0.8, item[4]), "568F9F")
		ocean.Reflectance, ocean.CastShadow = 0.05, false
	end
	local rng = Random.new(813)
	for i = 1, 34 do
		local a = i * 2.4
		local radius = Land.shoreAt(a) + rng:NextNumber(2.5, 45)
		local crest = P.sphere(
			coast,
			"Tidal comb",
			V(math.cos(a) * radius, -3.47, math.sin(a) * radius),
			V(rng:NextNumber(3, 11), 0.09, 0.22),
			"85A6AC"
		)
		crest.CastShadow = false
		crest.CFrame *= CFrame.Angles(0, -a + 0.8, 0)
	end
	return coast
end

return Coast
