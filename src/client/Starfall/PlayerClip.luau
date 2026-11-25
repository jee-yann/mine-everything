-- The player's performance in three places, keyed in their own character units.
-- Their equipped pick stays on its gameplay weld in every exposure of it.
local F = require(script.Parent.ExposureSheet).frames
local Acting = require(script.Parent.Acting)
local rad = math.rad
local offsets = { RightWrist = 1, LeftElbow = 1, RightElbow = 0.5 }

local function recorder()
	local keys = {}
	return keys, function(frame, pose, arrive)
		table.insert(keys, { frame, pose, arrive })
	end
end

-- Where a planted foot goes when the body faces `yaw` degrees at x, z.
local function foot(side, x, z, yaw, lift)
	local s = if side == "Left" then -0.5 else 0.5
	local r = rad(yaw)
	return { x + s * math.cos(r) - s, lift or 0, z - s * math.sin(r) }
end

-- A walk with planted steps. Speed is constant, so it can start and end off
-- screen, or settle onto its last step when `rest` is set.
local function walk(key, w)
	local steps, beat = w.steps, w.beat
	local function at(u)
		return w.x0 + (w.x1 - w.x0) * u, w.z0 + (w.z1 - w.z0) * u
	end
	local yaw = w.yaw or 0
	local arm, swing, bend = w.arm or 12, w.swing or 17, w.bend or 23
	local planted = { Left = 0, Right = 0 }
	local bx, bz = at(0)
	key(w.first, {
		Body = { bx, 0, bz }, Turn = { -2, yaw, 0 }, Waist = { -2, 0, 0 }, Neck = { w.look or 3, 0, 0 },
		LeftFoot = foot("Left", bx, bz, yaw), RightFoot = foot("Right", bx, bz, yaw),
		LeftFootTurn = { 0, yaw }, RightFootTurn = { 0, yaw },
		LeftShoulder = { 0, 0, -5 }, RightShoulder = { arm - 2, 0, 7 }, LeftElbow = { 16 }, RightElbow = { bend + 1 },
	})
	for i = 1, steps do
		local side = if i % 2 == 1 then "Right" else "Left"
		local last = w.rest and i == steps
		local f0 = w.first + (i - 1) * beat
		local uFoot = if last then 1 else math.min(1, (i + 0.35) / steps)
		local uBody = i / steps
		local fx, fz = at(uFoot)
		local px, pz = at(planted[side])
		local x, z = at(uBody)
		local mx, mz = at(uBody - 0.45 / steps)
		local sign = if side == "Left" then 1 else -1
		local amount = if last then 0.25 elseif w.rest and i == steps - 1 then 0.75 else 1
		key(f0 + 1, { [side .. "Foot"] = foot(side, px, pz, yaw, 0.02), [side .. "FootTurn"] = { 0, yaw } })
		key(f0 + beat * 0.55, {
			[side .. "Foot"] = foot(side, (px + fx) / 2, (pz + fz) / 2, yaw, 0.28),
			[side .. "FootTurn"] = { -22 * amount, yaw }, Body = { mx, 0.03, mz },
		})
		key(f0 + beat - 1, { [side .. "Foot"] = foot(side, fx, fz, yaw, 0.05), [side .. "FootTurn"] = { 12 * amount, yaw } })
		key(f0 + beat, {
			[side .. "Foot"] = foot(side, fx, fz, yaw), [side .. "FootTurn"] = { 0, yaw },
			Body = { x, -0.11 * amount - 0.02, z },
			Turn = { -3 * amount, yaw + 5 * sign * amount, 1.5 * sign * amount }, Waist = { -2, -9 * sign * amount, 0 },
			Neck = { w.look or 3, 5 * sign * amount, 0 },
			LeftShoulder = { -27 * sign * amount, 0, -6 }, LeftElbow = { 17 + 12 * math.max(0, -sign) * amount },
			RightShoulder = { arm + swing * sign * amount, 0, 8 }, RightElbow = { bend + 9 * math.max(0, sign) * amount },
		})
		planted[side] = uFoot
	end
end

-- Plaza: past the person filming, toward the light, and on out of the shot.
local plaza, plazaKey = recorder()
walk(plazaKey, { first = F.witness - 10, steps = 7, beat = 10, x0 = 2.3, z0 = 7.4, x1 = -0.2, z1 = -4.2, yaw = 12, look = 2 })

-- Gallery: the last steps up to the face, a look at the miner, and the blow.
-- Space is the player's mark at the face. -Z is into the rock.
local gallery, g = recorder()
local e = F.enter
walk(g, { first = e - 8, steps = 4, beat = 10, x0 = 1.5, z0 = 6.1, x1 = 0, z1 = 0.55, yaw = 14, look = 4, rest = true, arm = -10, swing = 10, bend = 8 })
g(e + 38, {
	Body = { 0, -0.04, 0.5 }, Turn = { 0, 0, 0 }, Waist = { -2, 4, 0 }, Neck = { 2, 30, 2 },
	LeftShoulder = { 4, 0, -10 }, LeftElbow = { 22 }, RightShoulder = { -6, 0, 12 }, RightElbow = { 12 },
	LeftFoot = { -0.1, 0, 0.2 }, RightFoot = { 0.14, 0, 0.72 }, LeftFootTurn = { 0, 6 }, RightFootTurn = { 0, -14 },
})
-- Back to the rock, a breath, the grip changes.
g(F.strike + 6, {
	Body = { 0, -0.10, 0.32 }, Turn = { -2, -6, 0 }, Waist = { -6, -6, 0 }, Neck = { 2, 10, 0 },
	LeftShoulder = { 30, 0, -14 }, LeftElbow = { 48 }, RightShoulder = { 4, 0, 14 }, RightElbow = { 34 }, RightWrist = { 4 },
	LeftFoot = { -0.1, 0, -0.1 }, RightFoot = { 0.18, 0, 0.74 },
})
for i, f in { F.strike + 18, F.strike + 32, F.strike + 46, F.autoStrike } do
	local n = if i % 2 == 1 then 1 else -1
	g(f, {
		Body = { 0, -0.11 - 0.02 * n, 0.32 }, Turn = { -2, -6, 0 }, Waist = { -6 - 1.2 * n, -6, 0 }, Neck = { 2 + n, 10, 0 },
		LeftShoulder = { 30, 0, -14 }, LeftElbow = { 48 }, RightShoulder = { 4 + 2 * n, 0, 14 }, RightElbow = { 34 + 2 * n }, RightWrist = { 4 },
		LeftFoot = { -0.1, 0, -0.1 }, RightFoot = { 0.18, 0, 0.74 },
	})
end
local c = F.contact2
g(c - 5, {
	Body = { 0.14, 0.00, 0.62 }, Turn = { 3, -26, 0 }, Waist = { 13, -30, -3 }, Neck = { 2, 46, 0 },
	RightShoulder = { 164, 6, 16 }, RightElbow = { 64 }, RightWrist = { 20 }, LeftShoulder = { 70, 0, -8 }, LeftElbow = { 22 },
	LeftFoot = { -0.1, 0.16, -0.14 }, LeftFootTurn = { -8, 6 },
}, "settle")
g(c - 3, {
	Body = { 0.11, -0.03, 0.46 }, Turn = { 2, -18, 0 }, Waist = { 13, -33, -3 }, Neck = { 2, 42, 0 },
	RightShoulder = { 170, 6, 16 }, RightElbow = { 72 }, RightWrist = { 28 }, LeftShoulder = { 62, 0, -10 },
	LeftFoot = { -0.12, 0.05, -0.52 }, LeftFootTurn = { 8, 6 },
})
g(c, {
	Body = { -0.04, -0.30, -0.34 }, Turn = { -5, 10, 0 }, Waist = { -18, 22, 4 }, Neck = { 10, -20, 0 },
	RightShoulder = { 80, -4, 4 }, RightElbow = { 10 }, RightWrist = { -4 }, LeftShoulder = { -38, 0, -24 }, LeftElbow = { 52 },
	LeftFoot = { -0.14, 0, -0.62 }, LeftFootTurn = { 0, 6 }, RightFoot = { 0.18, 0, 0.74 }, RightFootTurn = { 0, -24 },
}, "hit")
g(c + 3, {
	Body = { -0.05, -0.36, -0.36 }, Turn = { -5, 10, 0 }, Waist = { -21, 24, 5 }, Neck = { 12, -22, 0 },
	RightShoulder = { 76, -4, 4 }, RightElbow = { 14 }, RightWrist = { -4 }, LeftShoulder = { -42, 0, -24 }, LeftElbow = { 52 },
	LeftFoot = { -0.14, 0, -0.62 }, RightFoot = { 0.18, 0, 0.74 },
}, "settle")
-- The face is moving. Pull the steel out and give it room.
g(c + 10, {
	Body = { 0.02, -0.14, 0.18 }, Turn = { 2, -2, 0 }, Waist = { 2, 2, 0 }, Neck = { 2, -2, 0 },
	RightShoulder = { 44, 0, 22 }, RightElbow = { 52 }, RightWrist = { 4 }, LeftShoulder = { 30, 0, -30 }, LeftElbow = { 60 },
	LeftFoot = { -0.14, 0.08, -0.30 }, RightFoot = { 0.18, 0, 0.74 },
})
g(c + 18, {
	Body = { 0.06, -0.16, 0.62 }, Turn = { 7, -8, 0 }, Waist = { 10, -8, 0 }, Neck = { -4, 6, -4 },
	RightShoulder = { 28, 0, 30 }, RightElbow = { 46 }, LeftShoulder = { 82, 0, -30 }, LeftElbow = { 96 },
	LeftFoot = { -0.16, 0, 0.02 }, RightFoot = { 0.22, 0, 1.0 },
}, "settle")
-- The hand comes down. They lean toward what they opened.
g(c + 31, {
	Body = { 0.02, -0.10, 0.42 }, Turn = { 2, 0, 0 }, Waist = { 0, 0, 0 }, Neck = { 2, 0, 2 },
	RightShoulder = { 20, 0, 20 }, RightElbow = { 38 }, LeftShoulder = { 46, 0, -26 }, LeftElbow = { 62 },
})
g(F.reveal - 4, {
	Body = { 0, -0.14, 0.20 }, Turn = { -5, 4, 0 }, Waist = { -10, 4, 0 }, Neck = { 6, 0, 3 },
	RightShoulder = { 26, 0, 22 }, RightElbow = { 44 }, RightWrist = { 2 }, LeftShoulder = { 34, 0, -20 }, LeftElbow = { 44 }, LeftWrist = { 0 },
	LeftFoot = { -0.18, 0, 0.0 }, RightFoot = { 0.26, 0, 1.0 }, LeftFootTurn = { 0, 14 }, RightFootTurn = { 0, -26 },
})
-- The introduction grows out of that lean: up, open, and held.
local r = F.reveal
g(r + 6, {
	Body = { 0.02, 0.0, 0.36 }, Turn = { 5, 8, 0 }, Waist = { 7, -6, 2 }, Neck = { 2, 4, 3 },
	RightShoulder = { 66, 0, 56 }, RightElbow = { 72 }, RightWrist = { 6 }, LeftShoulder = { 44, 0, -34 }, LeftElbow = { 40 },
})
g(r + 15, {
	Body = { 0, -0.14, 0.34 }, Turn = { -2, 14, 0 }, Waist = { -4, 4, -2 }, Neck = { 2, -14, -4 },
	RightShoulder = { 36, 0, 44 }, RightElbow = { 52 }, RightWrist = { 0 }, LeftShoulder = { 44, 0, -30 }, LeftElbow = { 62 }, LeftWrist = { -14 },
}, "settle")
g(r + 40, {
	Body = { 0, -0.11, 0.32 }, Turn = { -2, 11, 0 }, Waist = { -3, 3, -2 }, Neck = { 4, -12, -4 },
	RightShoulder = { 39, 0, 45 }, RightElbow = { 53 }, LeftShoulder = { 49, 0, -30 }, LeftElbow = { 61 },
})
g(F.answer + 4, {
	Body = { 0, -0.09, 0.26 }, Turn = { -3, 5, 0 }, Waist = { -3, 0, -2 }, Neck = { 5, -6, -3 },
	RightShoulder = { 30, 0, 30 }, RightElbow = { 46 }, LeftShoulder = { 30, 0, -22 }, LeftElbow = { 46 },
})

-- Boulevard: out of the mine and back to the compass. Space faces away from
-- the mine, so the last pose is turned right round.
local road, k = recorder()
local a = F.answer
walk(k, { first = a - 14, steps = 6, beat = 10, x0 = 0, z0 = 8.2, x1 = 0, z1 = 0, look = 3, rest = true })
local t = F.turn
-- It happens behind them. The head goes first.
k(t + 1, { Body = { 0, -0.03, 0 }, Turn = { -2, 0, 0 }, Waist = { -2, 0, 0 }, Neck = { 3, 0, 0 } })
k(t + 9, {
	Body = { 0.02, -0.06, 0 }, Turn = { -2, 8, 0 }, Waist = { 0, 24, 0 }, Neck = { 2, 46, 4 },
	LeftShoulder = { -6, 0, -14 }, LeftElbow = { 24 }, RightShoulder = { 20, 0, 12 }, RightElbow = { 30 },
	LeftFoot = foot("Left", 0, 0, 0), RightFoot = foot("Right", 0, 0, 0), LeftFootTurn = { 0, 0 }, RightFootTurn = { 0, 0 },
}, "settle")
k(t + 15, {
	Body = { 0.02, -0.08, 0 }, Turn = { -2, 34, 0 }, Waist = { 0, 30, 0 }, Neck = { 2, 44, 4 },
	LeftFoot = foot("Left", 0, 0, 40, 0.16), LeftFootTurn = { -6, 46 }, RightFoot = foot("Right", 0, 0, 4), RightFootTurn = { 0, 10 },
})
k(t + 21, {
	Body = { 0, -0.07, 0 }, Turn = { -2, 92, 0 }, Waist = { -1, 24, 0 }, Neck = { 2, 34, 2 },
	LeftFoot = foot("Left", 0, 0, 100), LeftFootTurn = { 0, 100 }, RightFoot = foot("Right", 0, 0, 40, 0.05), RightFootTurn = { -8, 50 },
})
k(t + 28, {
	Body = { 0, -0.05, 0 }, Turn = { -1, 150, 0 }, Waist = { -1, 14, 0 }, Neck = { 2, 18, 0 },
	LeftFoot = foot("Left", 0, 0, 118), LeftFootTurn = { 0, 120 }, RightFoot = foot("Right", 0, 0, 150, 0.14), RightFootTurn = { 0, 152 },
	LeftShoulder = { -2, 0, -10 }, LeftElbow = { 18 }, RightShoulder = { 16, 0, 9 }, RightElbow = { 26 },
})
k(t + 34, {
	Body = { 0, -0.05, 0 }, Turn = { 0, 176, 0 }, Waist = { -1, 4, 0 }, Neck = { 3, 5, 0 },
	LeftFoot = foot("Left", 0, 0, 150, 0.10), LeftFootTurn = { 0, 158 }, RightFoot = foot("Right", 0, 0, 180), RightFootTurn = { 0, 180 },
})
k(t + 40, {
	Body = { 0, -0.03, 0 }, Turn = { 0, 180, 0 }, Waist = { 0, 0, 0 }, Neck = { 4, 0, 0 },
	LeftFoot = foot("Left", 0, 0, 180), LeftFootTurn = { 0, 180 }, RightFoot = foot("Right", 0, 0, 180), RightFootTurn = { 0, 180 },
	LeftShoulder = { 0, 0, -7 }, LeftElbow = { 14 }, RightShoulder = { 12, 0, 7 }, RightElbow = { 23 },
})
k(F.handoff + 6, { Body = { 0, 0, 0 }, Waist = { 1, 0, 0 }, Neck = { 5, 0, 0 } })

return {
	plaza = Acting.clip(plaza, offsets),
	gallery = Acting.clip(gallery, { RightWrist = 1, LeftWrist = 2, LeftElbow = 1 }),
	road = Acting.clip(road, offsets),
}
