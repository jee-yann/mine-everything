-- Temporary survey and quarry work seen between the natural shoreline and the harbor.
local P = require(script.Parent.Props)
local Rig = require(script.Parent.RobloxRig)
local Worksite = {}
local V, CF, A, rgb = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex
local function timber(m, name, from, to, width, tint)
	local d = to - from
	local mid = (from + to) * 0.5
	local up = if math.abs(d.Unit.Y) > 0.98 then Vector3.zAxis else Vector3.yAxis
	local p = P.part(m, name, V(width, width, d.Magnitude), CFrame.lookAt(mid, to, up), rgb(tint or "956F4B"))
	p.Material = Enum.Material.Wood
	return p
end

local function buildSkiff(shelf)
	local hull = P.model(shelf, "Survey cutter")
	local rim =
		{ { 0, -9.4 }, { 2.7, -6.4 }, { 3.15, 1.85 }, { 2.12, 7.1 }, { -2.12, 7.1 }, { -3.15, 1.85 }, { -2.7, -6.4 } }
	for i, v in rim do
		local w = rim[i % #rim + 1]
		local a, b = V(v[1], 1.9, v[2]), V(w[1], 1.9, w[2])
		local c, d = V(v[1] * 0.48, -0.43, v[2] * 0.82), V(w[1] * 0.48, -0.43, w[2] * 0.82)
		P.face(hull, a, b, d, rgb("AB6842"))
		P.face(hull, a, d, c, rgb("946044"))
		P.face(hull, a, b, V(0, 1.83, 0), rgb("CCAA76"))
		timber(hull, "Painted gunwale", a, b, 0.26, "E6B368")
	end
	for _, z in { -3.2, 0.5, 4.4 } do
		P.box(hull, "Thwart", V(0, 2.05, z), V(4.8, 0.32, 0.90), "785B45")
	end
	timber(hull, "Cutter mast", V(0, 1.8, -1), V(0, 14.8, -1), 0.38)
	timber(hull, "Gaff", V(0, 13.9, -1), V(1.3, 12.1, 5.1), 0.22)
	local tack, peak, clew, leech = V(0, 3.8, -1.1), V(0, 13.75, -1.1), V(1.5, 4.3, 5.3), V(1.3, 12.08, 5.1)
	local billow = V(2.63, 8.35, 2.0)
	for _, edge in
		{ { tack, peak, "FFE9C5" }, { peak, leech, "FBE3B5" }, { leech, clew, "D8754D" }, { clew, tack, "CC6847" } }
	do
		P.face(hull, edge[1], edge[2], billow, rgb(edge[3]))
	end
	-- A triangular jib at the bow gives the approaching cutter a readable
	-- silhouette and repeats the russet canvas of the future harbor stalls.
	local luff, foot, sheet = V(0, 13.8, -1.3), V(0, 2.9, -8.7), V(1.4, 3.6, -2.8)
	local seam = luff:Lerp(foot, 0.63)
	P.face(hull, luff, seam, sheet, rgb("FCE5BB"))
	P.face(hull, seam, foot, sheet, rgb("D26748"))
	timber(hull, "Flying jibstay", luff, foot, 0.09, "745B4C")
	P.face(hull, V(0, 14.75, -1), V(0.24, 14.0, 2.1), V(0, 13.75, -1), rgb("F39448"))
	return hull
end

local function wake(shelf, register)
	local m = P.model(shelf, "Wake of the first cutter")
	local keel = P.box(m, "Wave path", Vector3.zero, Vector3.one, "FFFFFF")
	keel.Transparency, keel.CastShadow = 1, false
	local jets = {}
	for _, side in { -1, 1 } do
		for band = 1, 2 do
			local a, b = Instance.new("Attachment"), Instance.new("Attachment")
			a.Position, b.Position =
				V(side * (1.15 + band * 0.65), 0, 4.4), V(side * (4.2 + band * 4.35), 0, 12 + band * 8.5)
			a.Axis, b.Axis = V(side * 0.28, 0, 0.96), V(side * 0.51, 0, 0.86)
			a.Parent, b.Parent = keel, keel
			local beam = Instance.new("Beam")
			beam.Name, beam.Attachment0, beam.Attachment1 = "Fold of wake", a, b
			beam.FaceCamera, beam.Segments, beam.LightInfluence = true, 12, 0.32
			beam.CurveSize0, beam.CurveSize1 = 5.2, 9.3
			beam.Color = ColorSequence.new(rgb("E9F1CA"), rgb("9BDCCD"))
			beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.32),
				NumberSequenceKeypoint.new(0.39, 0.13),
				NumberSequenceKeypoint.new(1, 1),
			})
			beam.Parent = keel
			table.insert(jets, beam)
		end
	end
	register(m, 5.0, 8.34, false)
	return m, jets
end

-- The first returning seabirds cross the empty gallery on the way to the
-- headland. Long white underwings give the high camera a moving scale cue.
local function gannets(shelf, register)
	local flock = {}
	for i = 1, 7 do
		local bird = P.model(shelf, "Gannet riding the headland wind")
		local body = P.sphere(bird, "Body", Vector3.zero, V(0.68, 0.59, 2.22), "F4E8CC")
		local wings = {}
		for _, side in { -1, 1 } do
			local wing = P.model(bird, "Tapered flight feathers")
			local root, elbow, tip = V(0, 0.1, 0), V(1.66 * side, 0.25, 0.32), V(3.44 * side, 0.03, 1.06)
			local trailing = V(1.54 * side, 0.15, 0.99)
			P.face(wing, root, elbow, trailing, rgb("F8EBCB"))
			P.face(wing, elbow, tip, trailing, rgb("4D5767"))
			table.insert(wings, { model = wing, side = side })
		end
		register(bird, 2.08, 6.0, false)
		table.insert(flock, { body = body, wings = wings })
	end
	return flock
end

local function surveyJetty(shelf, register, dockCF)
	local function section(name, start, finish, build)
		local m = P.model(shelf, name)
		build(m)
		m:PivotTo(dockCF)
		m.WorldPivot = CFrame.identity
		register(m, start, finish, true)
	end
	for j = 0, 4 do
		section("First landing piles", 6.10 + j * 0.125, 9.5 + j * 0.125, function(m)
			for _, side in { -1, 1 } do
				timber(m, "Driven pile", V(side * 3.05, -7.2, j * 3.02), V(side * 3.05, 1.53, j * 3.02), 0.60)
			end
		end)
		section("Survey jetty boards", 6.38 + j * 0.125, 9.40 + j * 0.125, function(m)
			for k = 0, 2 do
				P.box(
					m,
					"Sawn board",
					V(0, 1.45, j * 3.02 + k * 0.91),
					V(6.92, 0.46, 0.86),
					"B4956E",
					nil,
					Enum.Material.Wood
				)
			end
		end)
	end
	section("Landing pennant", 6.98, 9.55, function(m)
		timber(m, "Survey flagstaff", V(2.95, 1.51, 11.31), V(2.95, 12.4, 11.31), 0.27)
		P.face(m, V(2.95, 12.29, 11.31), V(2.95, 9.35, 11.31), V(7.8, 10.95, 12.01), rgb("FFAC49"))
	end)
	section("Field survey shelter", 7.12, 9.35, function(m)
		local a, b = V(0, 6.65, 2), V(0, 6.65, 7.8)
		timber(m, "Ridgepole", a, b, 0.2)
		for _, p in { a, b } do
			for _, side in { -1, 1 } do
				timber(m, "Tripod", V(side * 2.88, 1.69, p.Z), p, 0.22)
			end
		end
		for _, side in { -1, 1 } do
			local lowA, lowB = V(side * 3.04, 1.75, 1.71), V(side * 3.04, 1.75, 8.05)
			P.face(m, a, lowA, b, rgb("BF764F"))
			P.face(m, b, lowA, lowB, rgb("D18B55"))
		end
	end)
end

-- A single wall is quarried in joined courses: pilot opening, enlargement,
-- dressing of the sides, then the voussoirs that exist in the playable mine.
local function quarry(shelf, register, spent)
	local cols = { -13.65, -8.25, -2.98, 2.97, 8.14, 13.74 }
	local heights = { -0.81, 4.55, 9.43, 15.24 }
	local function corner(c, r)
		local offset = if c == 1 or c == #cols then 0 else 0.44 * math.sin(c * 4.15 + r * 0.89)
		local top = if r == #heights then 0.87 * math.cos(c * 2.43) else 0.27 * math.sin(c * 2 + r * 1.93)
		return V(cols[c] + offset, heights[r] + top, 3.72 + 0.55 * math.sin(c * 3.7 + r * 1.27))
	end
	for c = 1, 5 do
		for r = 1, 3 do
			local block = P.model(shelf, "Basalt at the heading")
			local a, b, d, e = corner(c, r), corner(c + 1, r), corner(c, r + 1), corner(c + 1, r + 1)
			local tint = rgb("796860"):Lerp(rgb("9C8273"), 0.10 * r + 0.045 * ((c + r) % 3))
			P.face(block, a, b, e, tint)
			P.face(block, a, e, d, tint)
			for _, edge in { { a, d }, { d, e }, { e, b }, { b, a } } do
				local x, y = edge[1], edge[2]
				local w, v = x - V(0, 0, 7.7), y - V(0, 0, 7.7)
				P.face(block, x, y, w, rgb("5B5355"))
				P.face(block, y, v, w, rgb("665A59"))
			end
			register(block, 3.35, 11.98 + 0.27 * math.abs(3 - c) + 0.15 * math.abs(2 - r) + (0.12 * (c % 2)), true)
			spent(20)
		end
	end
	local works = P.model(shelf, "Temporary timber headframe")
	local crown = V(4.1, 19.82, 7.15)
	for _, at in { V(7.3, 0, 8.2), V(6.6, 0, 3.5), V(1.6, 0, 8.3) } do
		timber(works, "Shear leg", at, crown, 0.51)
	end
	timber(works, "Crossarm", crown, V(-3.8, 19.17, 6.12), 0.58)
	timber(works, "Backstay", crown, V(11.15, 0.20, 2.77), 0.16, "65564B")
	timber(works, "Hoist rope", V(0, 19.21, 6.5), V(0, 7.24, 6.5), 0.12, "65564B")
	register(works, 11.38, 14.81, true)
	for i = 1, 4 do
		local m = P.model(shelf, "Barrow of newly cut rock")
		for j = 1, 4 do
			local p = P.sphere(
				m,
				"Basalt spoil",
				V(
					-9.5 - i * 0.9 + math.cos(j * 2.1) * 1.56,
					0.65 + 0.32 * (j % 3),
					6 + i * 1.45 + math.sin(j * 2) * 1.6
				),
				V(2.9, 1.9, 3.3),
				"8F786D",
				Enum.Material.Slate
			)
			p.CFrame *= A(j * 0.13, 0.67 * j + i * 0.29, 0.18)
		end
		register(m, 11.88 + i * 0.23, 13.52 + i * 0.22, true)
	end
	-- Keep a shadowed throat behind the native jambs even without streamed rock.
	local throat = P.model(shelf, "Footwall and depth of the gallery")
	P.box(throat, "Depth behind the gallery", V(0, 5.58, -66.7), V(61, 11.55, 0.22), "49434B", nil, Enum.Material.Slate)
	P.box(throat, "Portal subgrade", V(0, -0.56, -4.2), V(61, 0.68, 8.6), "967A62", nil, Enum.Material.Slate)
	for _, side in { -1, 1 } do
		P.box(
			throat,
			"Inner jamb",
			V(side * 10.42, 5.51, -0.42),
			V(2.25, 11.6, 7.52),
			"675C59",
			nil,
			Enum.Material.Slate
		)
	end
	register(throat, 3.45, nil, true)
end

-- The sailcloth that comes ashore becomes a field station. Both panels
-- pivot around the ridgepole before the guy ropes pull them taut.
local function fieldStation(shelf, register, bed)
	local frame = P.model(shelf, "First camp over the future siding")
	timber(frame, "Ridgepole", V(0, 7.4, -5.3), V(0, 7.4, 5.3), 0.35, "BC9369")
	for _, z in { -5.1, 5.1 } do
		for _, side in { -1, 1 } do
			timber(frame, "Cedar split pole", V(side * 4, 0, z), V(0, 7.4, z), 0.28, "C59B70")
		end
	end
	timber(frame, "Harbor pennant", V(-4.8, -0.1, -4.3), V(-4.8, 11.3, -4.3), 0.30, "AD865E")
	P.face(frame, V(-4.8, 11.3, -4.3), V(-4.8, 8.9, -4.3), V(-10.3, 10.6, -3.4), rgb("F89B55"))
	register(frame, 6.74, 9.79, false)
	local wings = {}
	for _, s in { -1, 1 } do
		local leaf = P.model(shelf, "Sailcloth on the ridgepole")
		local x = s * 6.2
		for j = 0, 2 do
			local z = -5.6 + j * 3.73
			local a, b, c, d = V(0, 0, z), V(0, 0, z + 3.73), V(x, -6.85, z + 3.73), V(x, -6.85, z)
			local color = rgb(if j == 1 then "FFF0C3" else "C97142")
			P.face(leaf, a, b, c, color)
			P.face(leaf, a, c, d, color)
		end
		register(leaf, 6.86, 9.72, false)
		table.insert(wings, { m = leaf, side = s })
	end
	return { m = frame, bed = bed, wings = wings }
end

function Worksite.build(shelf, register, spent, dock, camp)
	local outward = V(dock.X, 0, dock.Z - 14).Unit
	local launch = V(dock.X, -4.03, dock.Z)
	local dockCF = CFrame.lookAt(launch, launch - outward)
	surveyJetty(shelf, register, dockCF)
	local hull = buildSkiff(shelf)
	hull:ScaleTo(1.50)
	register(hull, 5.0, 8.34, false)
	local whiteWater, jets = wake(shelf, register)
	quarry(shelf, register, spent)
	local foreman = Rig.new(shelf, "Quarry foreman")
	local mate = Rig.new(shelf, "Bridge carpenter")
	local surveyor = Rig.new(shelf, "First surveyor ashore")
	local mallet = P.model(mate.model, "Decking mallet")
	timber(mallet, "Ash haft", Vector3.zero, V(0, 1.5, 0), 0.17, "E1B97C")
	P.box(mallet, "Hardwood head", V(0, 1.46, 0), V(0.96, 0.48, 0.55), "996744")
	local flag = P.model(foreman.model, "Hoist signal")
	timber(flag, "Hickory staff", Vector3.zero, V(0, 3.62, 0), 0.13, "EAC89C")
	P.face(flag, V(0, 3.61, 0), V(0, 2.26, 0), V(2.55, 2.76, 0.22), rgb("F29C49"))
	P.face(flag, V(0, 3.61, 0), V(1.09, 3.24, 0.08), V(0, 3.19, 0), rgb("FFF0C1"))
	register(surveyor.model, 5.0, 7.93, false)
	register(foreman.model, 11.47, 14.75, false)
	register(mate.model, 9.1, 10.82, false)
	return {
		hull = hull,
		mallet = mallet,
		flag = flag,
		dock = dockCF,
		foreman = foreman,
		mate = mate,
		surveyor = surveyor,
		station = fieldStation(shelf, register, camp),
		wake = whiteWater,
		jets = jets,
		birds = gannets(shelf, register),
	}
end

local deckNails = { 9.10, 9.46, 9.82, 10.71 }
local function hammerLoad(t)
	local lift = 0
	for _, contact in deckNails do
		local gather = P.ease(t, contact - 0.25, contact - 0.17)
		local strike = math.clamp((t - (contact - 0.09)) / 0.09, 0, 1)
		lift = math.max(lift, gather * (1 - strike * strike))
	end
	return lift
end

function Worksite.expose(work, t, base)
	if t >= 6.70 and t < 9.84 then
		local camp = work.station
		local bed = camp.bed
		local at = (bed.a.pos + bed.b.pos + bed.c.pos) / 3
		local start = math.clamp((t - 6.74) / 0.38, 0, 1)
		local leave = math.clamp((t - 9.42) / 0.31, 0, 1)
		local floor = base * CF(at.X, math.max(-0.08, at.Y) + 0.12, at.Z) * A(0, 0.52, 0)
		camp.m:PivotTo(floor * CF(0, -(1 - start) * 2.6, 0))
		for _, w in camp.wings do
			-- One side catches the breeze before the second sheet is hauled
			-- across. Both continue to pivot on the actual ridgepole.
			local pull = t - 6.86 - (if w.side < 0 then 0.105 else 0)
			local span = (
				0.35 * P.ease(pull, 0.00, 0.065)
				+ 0.78 * P.ease(pull, 0.18, 0.29)
				- 0.13 * P.ease(pull, 0.32, 0.40)
			) * (1 - leave)
			w.m:PivotTo(floor * CF(0, 7.4, 0) * A(0, 0, -w.side * 0.706 * (1 - span)))
		end
	end
	if t >= 2.04 and t < 6.04 then
		local passage = math.clamp((t - 2.08) / 3.92, 0, 1)
		for i, b in work.birds do
			local lane = (if i % 2 == 1 then -1 else 1) * math.floor(i / 2)
			local at = V(
				251 - 530 * passage + lane * 4.8,
				27 + lane * 1.4 + 11 * math.sin(passage * math.pi) + 1.3 * math.sin(t * 2.8 + i),
				80 - 69 * passage + math.abs(lane) * 7.3 + 4 * math.sin(t * 1.1 + i * 0.19)
			)
			local flight = base * CFrame.lookAt(at, at + V(-1, 0.035 * math.cos(passage * math.pi), -0.14))
			b.body.CFrame = flight
			local flap = 0.08 + 0.49 * math.sin(7.1 * t + i * 1.13) * (0.35 + 0.65 * math.sin(t * 0.82 + i * 0.54) ^ 2)
			for _, w in b.wings do
				w.model:PivotTo(flight * A(0, 0, w.side * flap))
			end
		end
	end
	if t >= 4.97 and t < 8.39 then
		local landing = math.clamp((t - 5) / 1.48, 0, 1)
		local leave = math.clamp((t - 7.53) / 0.81, 0, 1)
		local off = (1 - landing) ^ 1.43
		local planar = base
			* work.dock
			* CF(-8 - off * 37 - 28 * leave ^ 1.4, 0, 10.6 + off * 88 + leave ^ 1.8 * 55)
			* A(0, 0.16 + 0.34 * off - 1.0 * leave, 0)
		local afloat = planar
			* CF(0, 0.13 * math.sin(t * 5.1), 0)
			* A(0.018 * math.cos(t * 4.12), 0, 0.024 * math.sin(t * 5.4))
		work.hull:PivotTo(afloat)
		work.wake:PivotTo(planar * CF(0, -0.34, 0))
		local speed = math.max(1 - landing, leave, 0.03)
		for _, jet in work.jets do
			jet.Width0, jet.Width1 = 0.86 * speed, 3.55 * speed
		end
		if t < 7.98 then
			local rider = afloat * CF(0, 2.75, 3.7)
			local landingSpot = base * work.dock * CF(-2.1, 1.7, 8.6 - 5.6 * math.clamp((t - 6.77) / 0.82, 0, 1))
			local u = math.clamp((t - 6.44) / 0.35, 0, 1)
			local walk = math.sin(t * 19) * u
			work.surveyor:pose(rider:Lerp(landingSpot, u) + V(0, math.sin(u * math.pi) * 1.75, 0), {
				RightShoulder = A(0.4 + walk * 0.46, 0, 0.18),
				LeftShoulder = A(-walk * 0.42, 0, -0.13),
				RightHip = A(-walk * 0.59, 0, 0),
				LeftHip = A(walk * 0.59, 0, 0),
				Neck = A(0, -0.48 + 0.4 * u, 0),
			})
		end
	end
	if t >= 9.1 and t < 10.82 then
		local u = math.clamp((t - 9.1) / 1.64, 0, 1)
		local lift = hammerLoad(t)
		local foot = base * CF(-2.8, 0.08, 39.5 - 13.5 * u) * A(0, -0.23, 0)
		work.mate:pose(foot, {
			bob = -0.51 + 0.46 * lift,
			RootJoint = A(-0.59 + 0.54 * lift, 0.18 - 0.38 * lift, -0.05),
			RightTarget = foot * V(1.20, 1.42 + 2.72 * lift, -0.75 + 0.19 * lift),
			LeftTarget = foot * V(-0.83, 1.82, -0.94),
			RightHip = A(-0.24, 0, 0),
			LeftHip = A(0.28, 0, 0),
		})
		local hand = work.mate:palm("Right")
		work.mallet:PivotTo(CF(hand) * foot.Rotation * A(2.65 - 2.98 * lift, 0, -0.27))
	end
	if t >= 11.47 and t < 14.75 then
		local side = math.clamp((t - 12.15) / 1.62, 0, 1)
		local signal = P.ease(t, 12.25, 12.41)
			- P.ease(t, 12.90, 12.98)
			+ P.ease(t, 13.17, 13.27)
			- P.ease(t, 13.63, 13.70)
		local foot = base * CF(-3.2 + side * 6.1, 0.06, 8.35) * A(0, -0.18, 0)
		work.foreman:pose(foot, {
			bob = -0.10 + 0.19 * signal,
			RootJoint = A(-0.12 + 0.25 * signal, -0.14, 0.07 * signal),
			RightTarget = foot * V(1.34 + 0.34 * signal, 2.63 + 1.76 * signal, -0.44),
			LeftShoulder = A(0.46, 0, -0.27),
			Neck = A(0.19 * signal, -0.18, 0),
		})
		local hand = work.foreman:palm("Right")
		work.flag:PivotTo(CF(hand) * foot.Rotation * A(0.09, -0.10, -1.33 + 1.22 * signal))
	end
end

return Worksite
