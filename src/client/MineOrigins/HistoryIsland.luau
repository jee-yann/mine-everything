-- Continuous terrain for the private history set. Every facet shares vertices
-- with its neighbours. As the island weathers and the workers cut terraces,
-- the skin meets exactly along those edges.
local P, Land = require(script.Parent.Props), require(script.Parent.HistoryLandform)
local Mantle = require(script.Parent.HistoryMantle)
local Island = {}
local V, CF, A, rgb = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex
local TAU = 2 * math.pi

local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function water(shelf, register, spent)
	local sea = P.model(shelf, "Citrine strait")
	for x = -2, 2 do
		for z = -2, 2 do
			local p = P.box(sea, "Open water", V(x * 1984, -5.1, z * 1984), V(1984, 0.2, 1984), "447F97")
			p.CastShadow = false
		end
	end
	local last = {}
	for k, spec in
		{
			{ 0.60, "52B5BB" },
			{ 1.14, "52B5BB" },
			{ 1.31, "50ADB6" },
			{ 1.55, "4DA5B3" },
			{ 1.88, "499DAE" },
			{ 2.25, "4797A9" },
			{ 2.73, "4692A5" },
			{ 3.43, "458CA1" },
			{ 4.58, "44859C" },
		}
	do
		local loop = {}
		for i = 1, Land.slices / 2 do
			local p = Land.vertex(Land.rings, i * 2)
			loop[i] = V(p.X * spec[1], -4.62 - k * 0.035, (p.Z - 25) * spec[1] + 25)
		end
		local band = P.model(sea, "Water above the tidal shelf")
		for i, p in loop do
			local j = i % #loop + 1
			if k == 1 then
				P.face(band, V(0, p.Y, 25), p, loop[j], rgb(spec[2]))
			else
				P.face(band, last[i], p, loop[j], rgb(spec[2]))
				P.face(band, last[i], loop[j], last[j], rgb(spec[2]))
			end
			spent(2)
		end
		for _, part in band:GetChildren() do
			part.CastShadow = false
		end
		last = loop
	end
	register(sea, 0, nil, true)
end

local function node(r, i)
	local p = if r == 0 then Land.crater - V(0, 4.17, 0) else Land.vertex(r, i)
	local grade = 6.68 + 4.0 * math.clamp(0.45 + p.X / 318 - p.Z / 390, 0, 1)
	if r <= 4 then
		grade = 7.55 + 0.36 * r + 0.13 * math.sin(i * 0.39)
	end
	local sediment = p.Y
	if r <= 2 then
		sediment = 1.02 + (p.Y + 3.5) * 0.18
	end
	if r == 3 then
		sediment = p.Y * 0.62
	end
	local top = if r >= 5 then p.Y else sediment
	local erosion = 0.65 + r * 0.12 + 0.37 * math.sin(i * 0.76) ^ 2
	return { point = p, old = p.Y, top = top, erosion = erosion, grade = grade, finish = grade + 1.12, pos = p }
end

-- Two right-prism halves of a triangle. Size and basis are recomputed only
-- while a shared corner is moving. The rest of the island stays in the renderer.
local function reshape(tri, base, parts, transforms)
	local a, b, c = tri[1].pos, tri[2].pos, tri[3].pos
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal, along = ac:Cross(ab).Unit, bc.Unit
	local up = along:Cross(normal)
	local h = math.max(0.02, math.abs(ab:Dot(up)))
	local left, right = tri[4], tri[5]
	left.Size = V(0.031, h, math.max(0.02, math.abs((b - a):Dot(along))))
	right.Size = V(0.031, h, math.max(0.02, math.abs((c - a):Dot(along))))
	local leftCF = base * CFrame.fromMatrix((a + b) * 0.5, normal, up, along)
	local rightCF = base * CFrame.fromMatrix((a + c) * 0.5, -normal, up, -along)
	if parts then
		table.insert(parts, left)
		table.insert(parts, right)
		table.insert(transforms, leftCF)
		table.insert(transforms, rightCF)
	else
		left.CFrame, right.CFrame = leftCF, rightCF
	end
end

local function facet(group, a, b, c, tint)
	local m = Enum.Material.SmoothPlastic
	local p = P.part(group, "Rock skin", V(1, 1, 1), CFrame.identity, tint, "WedgePart")
	local q = p:Clone()
	q.Parent = group
	p.Material, q.Material = m, m
	local tri = { a, b, c, p, q }
	reshape(tri, CFrame.identity)
	return tri
end

local function naturalTone(r, p, i)
	if r <= 2 then
		return rgb("494458"), rgb("A99C80")
	end
	if r == 3 then
		return rgb("685967"), rgb("969674")
	end
	if r == 4 then
		return rgb("98776E"), rgb("8B986C")
	end
	local sand = r == Land.rings
	local native = if sand then rgb("B79A76") elseif p.Y > 24 then rgb("957A75") else rgb("AB8873")
	local heath = if sand then rgb("BEA785") elseif p.Y > 24 then rgb("718462") else rgb("82A46A")
	local light = 0.07 + 0.06 * math.sin(i * 0.56 + r * 0.87)
	return native:Lerp(rgb("DBCBA4"), light), heath:Lerp(rgb("D7C983"), light)
end

local function surface(shelf, register, spent)
	local nodes, rows = {}, {}
	local center = node(0, 0)
	table.insert(nodes, center)
	for r = 1, Land.rings do
		rows[r] = {}
		for i = 1, Land.slices do
			local n = node(r, i)
			table.insert(nodes, n)
			rows[r][i] = n
		end
	end
	local patches = {}
	for r = 1, Land.rings do
		for i = 1, Land.slices do
			local j = i % Land.slices + 1
			local a = if r == 1 then center else rows[r - 1][i]
			local b, c = rows[r][i], rows[r][j]
			local d = if r > 1 then rows[r - 1][j] else nil
			local at = (a.point + b.point + c.point) / 3
			local first, heath = naturalTone(r, at, i)
			local group = P.model(shelf, if r <= 3 then "Sealed impact basin" else "Uncut headland")
			local tris = { facet(group, a, b, c, first) }
			if d then
				table.insert(tris, facet(group, a, c, d, first))
			end
			local done = math.max(a.finish, b.finish, c.finish, if d then d.finish else 0)
			table.insert(patches, {
				a = a,
				b = b,
				c = c,
				d = d,
				r = r,
				i = i,
				center = at,
				tris = tris,
				model = group,
				old = first,
				new = heath,
				step = 0,
				greening = 1.52 + 0.22 * r + 0.36 * math.sin(i * 0.51) ^ 2,
				done = done,
			})
			register(group, 0, done + 0.08, true)
			spent(#tris * 2)
		end
	end
	local rock = {}
	for i, sample in Mantle.points do
		local p, cut = sample[1], sample[2]
		local n = { point = p, old = p.Y, top = p.Y, erosion = 0, grade = cut, finish = cut + 1.68, pos = p }
		rock[i] = n
		table.insert(nodes, n)
	end
	local colors = {
		{ "796C73", "76806A" },
		{ "9B8179", "8E946D" },
		{ "B49A83", "949B70" },
		{ "A6907A", "95966F" },
		{ "898089", "878A7C" },
		{ "B79B84", "ACA18D" },
		{ "756A78", "757780" },
	}
	-- Keep neighboring pieces together in the renderer. At the end of a cut
	-- the whole parcel is already under the native formations it revealed.
	for start = 1, #Mantle.faces, 12 do
		local group = P.model(shelf, "Weathered bedding of the cove")
		local parcelEnd = 0
		for k = start, math.min(start + 11, #Mantle.faces) do
			local face = Mantle.faces[k]
			local a, b, c = rock[face[1]], rock[face[2]], rock[face[3]]
			local tint = colors[face[4]]
			local mix = 0.04 + 0.055 * math.sin((a.point.X + c.point.Z) * 0.05) ^ 2
			local old, new = rgb(tint[1]):Lerp(rgb("B4A693"), mix), rgb(tint[2])
			local endAt = math.max(a.finish, b.finish, c.finish)
			local sample = facet(group, a, b, c, old)
			table.insert(patches, {
				a = a,
				b = b,
				c = c,
				tris = { sample },
				model = group,
				old = old,
				new = new,
				step = 0,
				r = 0,
				center = a.point,
				greening = 2.8 + (a.point.X + 150) / 220,
				done = endAt,
			})
			parcelEnd = math.max(parcelEnd, endAt)
			spent(2)
		end
		register(group, 0, parcelEnd + 0.11, true)
	end
	return nodes, patches
end

local function trees(land, shelf, register, spent)
	local seed = Random.new(31591)
	local trees = {}
	for id, bed in land.patches do
		local ridgeTree = bed.r == 0 and bed.center.Y > 17 and bed.center.Z < 0 and id % 19 == 3
		if not ridgeTree and (bed.r < 5 or bed.r > 8 or bed.center.Z < 6 or (bed.i + bed.r * 7) % 4 == 0) then
			continue
		end
		local p = bed.a.point:Lerp(bed.b.point, 0.22):Lerp(bed.c.point, 0.32)
		local first = 2.63 + 0.019 * math.max(0, p.Z) + 0.45 * seed:NextNumber()
		local fell = math.min(bed.a.grade, bed.b.grade, bed.c.grade) - 0.15
		local trunk = P.model(shelf, "Coastal hardwood")
		local height = seed:NextNumber(8, 15)
		P.box(
			trunk,
			"Forked bole",
			V(0, height * 0.29, 0),
			V(height * 0.11, height * 0.58, height * 0.11),
			"795843",
			A(0, 0, 0.04),
			Enum.Material.Wood
		)
		if id % 3 == 1 or ridgeTree then
			local spin = seed:NextNumber(0, TAU)
			for tier = 1, 2 do
				local y = height * (if tier == 1 then 0.36 else 0.56)
				local tip = V(0, height * (if tier == 1 then 0.82 else 1.08), 0)
				local radius = height * (if tier == 1 then 0.31 else 0.24)
				for side = 0, 2 do
					local a, b = spin + side * TAU / 3, spin + (side + 1) * TAU / 3
					P.face(
						trunk,
						V(radius * math.cos(a), y, radius * math.sin(a)),
						V(radius * math.cos(b), y, radius * math.sin(b)),
						tip,
						rgb(if side == 2 then "577D59" elseif tier == 2 then "6B9161" else "466F57")
					)
				end
			end
		else
			for k = 1, 3 do
				local a = k * TAU / 3 + seed:NextNumber() * 0.7
				local y = height * (0.45 + 0.133 * k)
				local crown = P.sphere(
					trunk,
					"Wind-pruned crown",
					V(math.cos(a) * height * 0.16, y, math.sin(a) * height * 0.16),
					V(height * 0.66, height * (0.41 + 0.035 * k), height * 0.59),
					if k == 3 then "86A96A" elseif k == 2 then "6A965F" else "507B5A"
				)
				crown.CFrame *= A(0.14 * math.cos(a), a, 0.15 * math.sin(a))
			end
		end
		trunk.WorldPivot = CFrame.identity
		register(trunk, first, fell, false)
		table.insert(trees, { m = trunk, bed = bed, rot = seed:NextNumber(0, TAU) })
		spent(5)
	end
	land.trees = trees
end

-- A trail follows the actual (moving) ground from landfall into the future
-- court. Its slipway remains above water as the two banks are cut down.
local function trail(land, shelf, register, spent)
	local function sample(x, z)
		for _, p in land.patches do
			for _, tr in p.tris do
				local a, b, c = tr[1].point, tr[2].point, tr[3].point
				local u, v = b - a, c - a
				local det = u.X * v.Z - u.Z * v.X
				if math.abs(det) < 0.001 then
					continue
				end
				local f = ((x - a.X) * v.Z - (z - a.Z) * v.X) / det
				local g = (u.X * (z - a.Z) - u.Z * (x - a.X)) / det
				if f >= -0.001 and g >= -0.001 and f + g <= 1.001 then
					return Vector3.new(x, a.Y + f * u.Y + g * v.Y, z), math.min(tr[1].grade, tr[2].grade, tr[3].grade)
				end
			end
		end
		return V(x, -3.2, z), 8
	end
	local dock = land.dock
	local points = {
		dock,
		V(dock.X * 0.66, 0, dock.Z * 0.92),
		V(dock.X * 0.8, 0, dock.Z * 0.70),
		V(-19, 0, 64),
		V(-31, 0, 43),
		V(-6, 0, 25),
	}

	for k = 2, #points do
		local a, b = points[k - 1], points[k]
		local segments = math.max(1, math.ceil((a - b).Magnitude / 6))
		for j = 1, segments do
			local sa, sb = a:Lerp(b, (j - 1) / segments), a:Lerp(b, j / segments)
			local fa, ends = sample(sa.X, sa.Z)
			local fb = sample(sb.X, sb.Z)
			fa, fb = fa + V(0, 0.38, 0), fb + V(0, 0.38, 0)
			local m = P.model(shelf, "Footpath worn by the surveyors")
			local p = P.box(m, "Survey trail", V(0, 0, 0), V(2.1, 0.15, (fa - fb).Magnitude), "CDB282")
			local cf = CFrame.lookAt((fa + fb) / 2, fb)
			p.CFrame = cf
			local t = 6.12 + (k - 2 + (j - 1) / segments) * 0.22
			if t < ends then
				register(m, t, ends, true)
			else
				m:Destroy()
			end
			spent(1)
		end
	end
end

-- Restrict the per-render survey to the parcels actually exposed by this
-- cut. Entries extend one quarter-second beyond their curve to apply the
-- exact resting position on slow clients. Seeking computes a full pose.
local function schedule(nodes, patches, spent)
	local nodeBins, rockBins, colorBins = {}, {}, {}
	local function put(bins, record, a, b)
		for slot = math.floor(a * 4), math.ceil(b * 4) + 1 do
			if not bins[slot] then
				bins[slot] = {}
			end
			table.insert(bins[slot], record)
		end
	end
	for _, n in nodes do
		if n.old ~= n.top then
			put(nodeBins, n, n.erosion, n.erosion + 1.55)
		end
		put(nodeBins, n, n.grade, n.finish)
	end
	for _, p in patches do
		local first, last, erosion, aged = math.huge, 0, math.huge, 0
		for _, n in { p.a, p.b, p.c, p.d } do
			first, last = math.min(first, n.grade), math.max(last, n.finish)
			if n.old ~= n.top then
				erosion, aged = math.min(erosion, n.erosion), math.max(aged, n.erosion + 1.55)
			end
		end
		if aged > 0 then
			put(rockBins, p, erosion, aged)
		end
		put(rockBins, p, first, last)
		put(colorBins, p, p.greening, p.greening + 1)
		spent(0.1)
	end
	return nodeBins, rockBins, colorBins
end
function Island.build(shelf, register, spent)
	water(shelf, register, spent)
	local nodes, patches = surface(shelf, register, spent)
	local a = math.rad(151)
	local reach = Land.shoreAt(a) + 15
	local camp, best = nil, math.huge
	for _, bed in patches do
		if bed.r >= 5 and bed.r < 9 then
			local dist = (bed.center - V(-67, 12, 43)).Magnitude
			if dist < best then
				camp, best = bed, dist
			end
		end
	end
	local nodeBins, rockBins, colorBins = schedule(nodes, patches, spent)
	return {
		nodeBins = nodeBins,
		rockBins = rockBins,
		colorBins = colorBins,
		camp = camp,
		nodes = nodes,
		patches = patches,
		parts = {},
		frames = {},
		dock = Land.crater + V(reach * math.cos(a), -3.4, reach * math.sin(a)),
	}
end
function Island.plant(land, shelf, register, spent)
	trees(land, shelf, register, spent)
	trail(land, shelf, register, spent)
end

function Island.expose(land, t, base, root)
	if t == land.age then
		return
	end
	local oldAge = land.age
	land.age = t
	local full = not oldAge or t < oldAge or t - oldAge > 0.20
	local slot = math.floor(t * 4)
	local empty = land.empty or {}
	land.empty = empty
	for _, n in if full then land.nodes else land.nodeBins[slot] or empty do
		local erosion = smooth((t - n.erosion) / 1.55)
		local grade = smooth((t - n.grade) / (n.finish - n.grade))
		local y = n.old + (n.top - n.old) * erosion
		y += (-6.95 - y) * grade
		if math.abs(y - n.pos.Y) > 0.002 then
			n.changed = t
			n.pos = V(n.point.X, y, n.point.Z)
		end
	end
	local hueFrame = math.floor(t * 14)
	local recolor = hueFrame ~= land.hueFrame
	land.hueFrame = hueFrame
	local parts, cf = land.parts, land.frames
	table.clear(parts)
	table.clear(cf)
	local bulk = root:IsDescendantOf(workspace)
	if t <= 12 or oldAge == nil or oldAge < 12 then
		for _, p in if full then land.patches else land.rockBins[slot] or empty do
			if t > p.done + 0.04 or p.model.Parent ~= root then
				continue
			end
			for _, tri in p.tris do
				if tri[1].changed == t or tri[2].changed == t or tri[3].changed == t then
					reshape(tri, base, if bulk then parts else nil, cf)
				end
			end
		end
		if recolor then
			for _, p in if full then land.patches else land.colorBins[slot] or empty do
				local step = math.clamp(math.floor((t - p.greening) * 12), 0, 12)
				if step ~= p.step then
					p.step = step
					local tone = p.old:Lerp(p.new, step / 12)
					for _, tri in p.tris do
						tri[4].Color, tri[5].Color = tone, tone
					end
				end
			end
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cf, Enum.BulkMoveMode.FireCFrameChanged)
	end
	for _, tree in land.trees or {} do
		if tree.m.Parent == root then
			local bed = tree.bed
			local point = bed.a.pos:Lerp(bed.b.pos, 0.22):Lerp(bed.c.pos, 0.32)
			tree.m:PivotTo(base * CF(point) * A(0, tree.rot, 0))
		end
	end
end
return Island
