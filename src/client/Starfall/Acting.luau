-- Keyed performances. A clip is a list of { frame, pose, arrive } keys, where
-- a pose holds Euler degrees per joint. Curves pass through every key without
-- overshooting it, so a limb never reverses between two drawings. `arrive`
-- shapes the approach to one key: "hit" accelerates into it, "settle" eases out.
local Acting = {}
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local rad = math.rad

local function tangents(keys)
	-- Monotone cubic (Fritsch-Carlson) tangents per component.
	local n = #keys
	local slopes = {}
	for i = 1, n do
		slopes[i] = { 0, 0, 0 }
	end
	for k = 1, 3 do
		for i = 2, n - 1 do
			local h0, h1 = keys[i].f - keys[i - 1].f, keys[i + 1].f - keys[i].f
			local d0 = (keys[i].v[k] - keys[i - 1].v[k]) / h0
			local d1 = (keys[i + 1].v[k] - keys[i].v[k]) / h1
			if d0 * d1 > 0 then
				local w1, w2 = 2 * h1 + h0, h1 + 2 * h0
				slopes[i][k] = (w1 + w2) / (w1 / d0 + w2 / d1)
			end
		end
	end
	return slopes
end

function Acting.clip(keys, offsets)
	local tracks = {}
	for _, key in keys do
		for joint, value in key[2] do
			tracks[joint] = tracks[joint] or {}
			table.insert(tracks[joint], {
				f = key[1] + (offsets and offsets[joint] or 0),
				v = { value[1] or 0, value[2] or 0, value[3] or 0 },
				arrive = key[3],
			})
		end
	end
	for _, track in tracks do
		table.sort(track, function(a, b) return a.f < b.f end)
		for i = #track, 2, -1 do
			if track[i].f - track[i - 1].f < 0.01 then
				table.remove(track, i - 1)
			end
		end
		track.slopes = tangents(track)
	end
	return tracks
end

local function sample(track, f)
	local n = #track
	if f <= track[1].f then
		return track[1].v
	elseif f >= track[n].f then
		return track[n].v
	end
	local i = 2
	while track[i].f < f do
		i += 1
	end
	local a, b = track[i - 1], track[i]
	local span = b.f - a.f
	local u = (f - a.f) / span
	local out = { 0, 0, 0 }
	if b.arrive == "hit" or b.arrive == "settle" then
		local w = if b.arrive == "hit" then u ^ 2.3 else 1 - (1 - u) ^ 2.6
		for k = 1, 3 do
			out[k] = a.v[k] + (b.v[k] - a.v[k]) * w
		end
		return out
	end
	local u2, u3 = u * u, u * u * u
	for k = 1, 3 do
		out[k] = a.v[k] * (2 * u3 - 3 * u2 + 1) + track.slopes[i - 1][k] * span * (u3 - 2 * u2 + u)
			+ b.v[k] * (-2 * u3 + 3 * u2) + track.slopes[i][k] * span * (u3 - u2)
	end
	return out
end

function Acting.read(clip, joint, frame)
	local track = clip[joint]
	if not track then
		return 0, 0, 0
	end
	local v = sample(track, frame)
	return v[1], v[2], v[3]
end

local joints = {
	"Waist", "Neck", "LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow", "RightWrist",
	"LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle",
}

-- Pose a performer from a clip. `stand` is the performer's neutral root CFrame.
-- Body = { right, rise, back } in character units, Turn = { pitch, yaw, roll }.
-- Feet stay where their tracks put them while the body moves above them.
function Acting.perform(rig, clip, frame, stand, unit)
	rig:reset()
	local x, y, z = Acting.read(clip, "Body", frame)
	local pitch, yaw, roll = Acting.read(clip, "Turn", frame)
	local wx, wy, wz = Acting.read(clip, "Waist", frame)
	local offset = V(x, y, z) * unit
	if not rig.modern then
		-- A one-piece torso takes part of the lean at its root. It cannot
		-- crouch, so its hips travel only as far as straight legs allow.
		pitch, yaw, roll = pitch + wx * 0.55, yaw + wy * 0.6, roll + wz * 0.6
		offset = V(offset.X, math.max(offset.Y, -0.02 * unit), offset.Z)
	end
	local base = stand * CF(offset) * A(0, rad(yaw), 0) * A(rad(pitch), 0, rad(roll))
	for _, name in joints do
		if clip[name] and (rig.modern or name ~= "Waist") then
			rig:turn(name, Acting.read(clip, name, frame))
		end
	end
	if rig.modern then
		for _, side in { "Left", "Right" } do
			local foot = rig.model:FindFirstChild(side .. "Foot")
			if foot and rig.rest[foot] then
				local fx, fy, fz = Acting.read(clip, side .. "Foot", frame)
				local fp, fw = Acting.read(clip, side .. "FootTurn", frame)
				local goal = stand * CF(V(fx, fy, fz) * unit) * rig.rest[foot] * A(rad(fp), rad(fw), 0)
				local pole = base:VectorToWorldSpace(V(if side == "Left" then -0.18 else 0.18, 0, -1))
				rig:carry(side .. "Hip", side .. "Knee", side .. "Ankle", goal, pole, base)
			end
		end
	else
		-- Straight legs swing to their marks and counter the body's lean.
		local elbow = Acting.read(clip, "RightElbow", frame)
		local sx, sy, sz = Acting.read(clip, "RightShoulder", frame)
		rig:turn("RightShoulder", sx + elbow * 0.45, sy, sz)
		for _, side in { "Left", "Right" } do
			local _, _, fz = Acting.read(clip, side .. "Foot", frame)
			local swing = math.deg(math.atan2((z - fz) * math.cos(rad(yaw)), 2))
			rig:turn(side .. "Hip", math.clamp(swing, -42, 42) - pitch * 0.85, 0, 0)
		end
	end
	return base
end

return Acting
