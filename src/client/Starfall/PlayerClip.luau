-- The player's performance, keyed in their own character units. Their equipped
-- pick stays on its gameplay weld for every exposure of it.
local F = require(script.Parent.ExposureSheet).frames
local Acting = require(script.Parent.Acting)

local ground, offsets = {}, { RightWrist = 1, LeftElbow = 1, RightElbow = 0.5 }
local function key(frame, pose, arrive)
	table.insert(ground, { frame, pose, arrive })
end

-- The walk in. Seven planted steps, each foot still while the body passes it.
local first, steps, stride, beat = F.witness - 4, 8, 1.42, 10
local sides = { "Left", "Right" }
local planted = { Left = { 2.6, 10.6 }, Right = { 2.6, 10.6 } }
local startZ = 10.6
key(first, {
	Body = { 2.6, 0, startZ }, Turn = { -2, 13, 0 }, Waist = { -2, 0, 0 }, Neck = { 3, 4, 0 },
	LeftFoot = { 2.6, 0, startZ }, RightFoot = { 2.6, 0, startZ }, LeftFootTurn = { 0, 13 }, RightFootTurn = { 0, 13 },
	LeftShoulder = { 0, 0, -4 }, RightShoulder = { 10, 0, 6 }, LeftElbow = { 14 }, RightElbow = { 22 },
})
for i = 1, steps do
	local side = sides[i % 2 + 1]
	local other = if side == "Left" then "Right" else "Left"
	local f0 = first + (i - 1) * beat
	local last = i == steps
	local z = if last then 0.02 else math.max(0, startZ - i * stride)
	local x = 2.6 * (z / startZ)
	local from = planted[side]
	local bodyZ = if last then 0 else z + stride * 0.45
	local bodyX = 2.6 * (bodyZ / startZ)
	local sign = if side == "Left" then 1 else -1
	local amount = if last then 0.2 elseif i == steps - 1 then 0.7 else 1
	local yaw = if last then 0 else 13
	key(f0 + 1, { [side .. "Foot"] = { from[1], 0.02, from[2] }, [side .. "FootTurn"] = { 0, yaw } })
	key(f0 + beat * 0.55, {
		[side .. "Foot"] = { (from[1] + x) / 2, 0.26, (from[2] + z) / 2 - 0.1 },
		[side .. "FootTurn"] = { -20 * amount, yaw },
		Body = { (planted[other][1] + bodyX) / 2, 0.02, (bodyZ + (if i == 1 then startZ else startZ - (i - 1) * stride + stride * 0.45)) / 2 },
	})
	key(f0 + beat - 1, { [side .. "Foot"] = { x, 0.05, z }, [side .. "FootTurn"] = { 12 * amount, yaw } })
	key(f0 + beat, {
		[side .. "Foot"] = { x, 0, z }, [side .. "FootTurn"] = { 0, yaw },
		Body = { bodyX, -0.10 * amount - 0.02, bodyZ },
		Turn = { -3 * amount, yaw + 5 * sign * amount, 0 }, Waist = { -2, -9 * sign * amount, 0 },
		Neck = { 4, 5 * sign * amount + (if last then 0 else 5), 0 },
		LeftShoulder = { -26 * sign * amount, 0, -5 }, LeftElbow = { 16 + 10 * math.max(0, -sign) * amount },
		RightShoulder = { 12 + 16 * sign * amount, 0, 7 }, RightElbow = { 22 + 8 * math.max(0, sign) * amount },
	})
	planted[side] = { x, z }
end
local stop = first + steps * beat

-- The light comes up the path and under the boots. Eyes first, then weight.
key(stop + 5, {
	Body = { 0, -0.03, 0.02 }, Turn = { 0, 0, 0 }, Waist = { 0, 0, 0 }, Neck = { 2, 0, 0 },
	LeftShoulder = { 2, 0, -6 }, LeftElbow = { 14 }, RightShoulder = { 12, 0, 8 }, RightElbow = { 24 },
	LeftFoot = { -0.06, 0, 0 }, RightFoot = { 0.08, 0, 0.04 }, LeftFootTurn = { 0, 8 }, RightFootTurn = { 0, -10 },
})
key(F.arrive + 24, { Neck = { -16, 8, 0 }, Waist = { -3, 2, 0 } })
key(F.arrive + 30, {
	Body = { 0, -0.06, 0.04 }, Neck = { -27, 4, 3 }, Waist = { -8, 3, 0 },
	LeftShoulder = { 10, 0, -22 }, LeftElbow = { 26 }, RightShoulder = { 16, 0, 18 }, RightElbow = { 30 },
}, "settle")
key(F.arrive + 42, { Body = { 0, -0.07, 0.05 }, Neck = { -27, -6, 2 }, Waist = { -8, -3, 0 } })
key(F.sprout + 3, { Body = { 0, -0.10, 0.06 }, Neck = { -24, -8, 2 }, Waist = { -8, -4, 0 }, LeftShoulder = { 12, 0, -22 } })
-- The floor breaks. A jolt back onto the rear foot, the free arm out for balance.
key(F.sprout + 9, {
	Body = { 0.04, -0.12, 0.46 }, Turn = { 8, 0, 0 }, Waist = { 9, 4, 0 }, Neck = { -22, -4, 0 },
	LeftShoulder = { 52, 0, -46 }, LeftElbow = { 40 }, RightShoulder = { 24, 0, 34 }, RightElbow = { 46 },
	RightFoot = { 0.14, 0.14, 0.36 }, LeftFoot = { -0.08, 0, 0.02 },
}, "settle")
key(F.sprout + 13, { RightFoot = { 0.18, 0, 0.62 }, RightFootTurn = { 0, -24 } })
key(F.sprout + 24, {
	Body = { 0.02, -0.10, 0.34 }, Turn = { 2, 0, 0 }, Waist = { 0, 2, 0 }, Neck = { -20, -2, 0 },
	LeftShoulder = { 30, 0, -24 }, LeftElbow = { 38 }, RightShoulder = { 24, 0, 18 }, RightElbow = { 46 },
})
-- Ready. The grip tightens and the pick comes up across the body.
key(F.strike + 4, {
	Body = { 0, -0.14, 0.22 }, Turn = { -2, -8, 0 }, Waist = { -7, -8, 0 }, Neck = { -12, 14, 0 },
	LeftShoulder = { 36, 0, -16 }, LeftElbow = { 52 }, RightShoulder = { 4, 0, 12 }, RightElbow = { 34 }, RightWrist = { 0 },
	LeftFoot = { -0.1, 0, -0.28 }, RightFoot = { 0.18, 0, 0.62 }, LeftFootTurn = { 0, 6 },
})
for i, f in { F.strike + 18, F.strike + 32, F.strike + 46, F.autoStrike } do
	local n = if i % 2 == 1 then 1 else -1
	key(f, {
		Body = { 0, -0.14 - 0.02 * n, 0.22 }, Waist = { -7 - 1.2 * n, -8, 0 }, Neck = { -12 + n, 14, 0 },
		RightShoulder = { 4 + 2 * n, 0, 12 }, RightElbow = { 34 + 2 * n }, LeftShoulder = { 36, 0, -16 },
		Turn = { -2, -8, 0 }, LeftElbow = { 52 }, RightWrist = { 0 }, LeftFoot = { -0.1, 0, -0.28 }, RightFoot = { 0.18, 0, 0.62 },
	})
end
-- One committed swing. Hips, torso, arm, steel.
local c = F.contact2
key(c - 5, {
	Body = { 0.12, 0.02, 0.42 }, Turn = { 4, -24, 0 }, Waist = { 14, -26, -3 }, Neck = { -18, 38, 0 },
	RightShoulder = { 158, 6, 14 }, RightElbow = { 62 }, RightWrist = { 18 }, LeftShoulder = { 72, 0, -8 }, LeftElbow = { 24 },
	LeftFoot = { -0.1, 0.16, -0.46 }, LeftFootTurn = { -8, 6 },
}, "settle")
key(c - 3, {
	Body = { 0.10, -0.02, 0.30 }, Turn = { 3, -18, 0 }, Waist = { 14, -30, -3 }, Neck = { -18, 34, 0 },
	RightShoulder = { 166, 6, 14 }, RightElbow = { 70 }, RightWrist = { 26 }, LeftShoulder = { 64, 0, -10 },
	LeftFoot = { -0.12, 0.05, -0.86 }, LeftFootTurn = { 8, 6 },
})
local struck = {
	Body = { -0.04, -0.46, -0.40 }, Turn = { -8, 8, 0 }, Waist = { -24, 18, 4 }, Neck = { 0, -16, 0 },
	RightShoulder = { 60, -4, 2 }, RightElbow = { 8 }, RightWrist = { -10 }, LeftShoulder = { -36, 0, -24 }, LeftElbow = { 50 },
	LeftFoot = { -0.14, 0, -0.96 }, LeftFootTurn = { 0, 6 }, RightFoot = { 0.18, 0, 0.62 }, RightFootTurn = { 0, -24 },
}
key(c, struck, "hit")
key(F.reveal + 3, {
	Body = { -0.05, -0.52, -0.42 }, Waist = { -27, 20, 5 }, RightShoulder = { 56, -4, 2 }, LeftShoulder = { -40, 0, -24 },
	Turn = { -8, 8, 0 }, Neck = { 0, -16, 0 }, RightElbow = { 10 }, RightWrist = { -10 }, LeftElbow = { 50 },
}, "settle")
-- After the reveal: upright, pick lowering, eyes following the light home.
key(F.answer - 4, {
	Body = { 0, -0.04, 0.1 }, Turn = { -2, 6, 0 }, Waist = { -4, 6, 0 }, Neck = { -6, 4, 0 },
	RightShoulder = { 26, 0, 10 }, RightElbow = { 34 }, RightWrist = { 0 }, LeftShoulder = { 8, 0, -10 }, LeftElbow = { 20 },
	LeftFoot = { -0.08, 0, -0.3 }, RightFoot = { 0.12, 0, 0.3 }, LeftFootTurn = { 0, 6 }, RightFootTurn = { 0, -16 },
})
key(F.answer + 14, {
	Body = { 0, -0.02, 0.04 }, Turn = { 0, 2, 0 }, Waist = { -2, 2, 0 }, Neck = { 2, 0, 0 },
	RightShoulder = { 16, 0, 8 }, RightElbow = { 24 }, LeftShoulder = { 2, 0, -8 }, LeftElbow = { 16 },
	LeftFoot = { -0.06, 0.1, -0.12 }, RightFoot = { 0.1, 0, 0.16 },
})
key(F.answer + 34, {
	Body = { 0, 0, 0 }, Turn = { 0, 0, 0 }, Waist = { 2, 0, 0 }, Neck = { 6, 0, 0 },
	RightShoulder = { 12, 0, 6 }, RightElbow = { 22 }, LeftShoulder = { 0, 0, -6 }, LeftElbow = { 12 },
	LeftFoot = { -0.04, 0, 0 }, RightFoot = { 0.06, 0, 0.04 }, LeftFootTurn = { 0, 5 }, RightFootTurn = { 0, -6 },
})
key(F.handoff, { Body = { 0, 0, 0 }, Waist = { 0, 0, 0 }, Neck = { 2, 0, 0 } })

-- The reveal is its own take, on the glass stage.
local r = F.reveal
local hero = {
	{ r - 2, {
		Body = { 0, -0.42, 0.2 }, Turn = { -10, 34, 0 }, Waist = { -22, 24, 0 }, Neck = { -8, -10, 0 },
		RightShoulder = { 60, 0, 20 }, RightElbow = { 30 }, RightWrist = { 0 }, LeftShoulder = { -20, 0, -30 }, LeftElbow = { 60 },
		LeftWrist = { 0 }, LeftFoot = { -0.34, 0, -0.5 }, RightFoot = { 0.4, 0, 0.5 }, LeftFootTurn = { 0, 22 }, RightFootTurn = { 0, -30 },
	} },
	{ r + 5, {
		Body = { 0.02, -0.02, 0 }, Turn = { 4, 8, 0 }, Waist = { 6, -8, 2 }, Neck = { 2, 6, 3 },
		RightShoulder = { 64, 0, 56 }, RightElbow = { 70 }, RightWrist = { 6 }, LeftShoulder = { 50, 0, -22 }, LeftElbow = { 20 },
	} },
	{ r + 12, {
		Body = { 0, -0.14, -0.02 }, Turn = { -2, 14, 0 }, Waist = { -4, 4, -2 }, Neck = { 2, -14, -4 },
		RightShoulder = { 36, 0, 44 }, RightElbow = { 52 }, RightWrist = { 0 }, LeftShoulder = { 44, 0, -30 }, LeftElbow = { 62 }, LeftWrist = { -14 },
	}, "settle" },
	{ r + 34, {
		Body = { 0, -0.12, -0.04 }, Turn = { -2, 12, 0 }, Waist = { -5, 4, -2 }, Neck = { 3, -13, -4 },
		RightShoulder = { 37, 0, 45 }, RightElbow = { 53 }, LeftShoulder = { 46, 0, -30 }, LeftElbow = { 62 },
	} },
	-- A lift of the chin and the palm as the light is let go.
	{ r + 50, {
		Body = { 0, -0.10, -0.04 }, Turn = { -2, 10, 0 }, Waist = { -2, 3, -2 }, Neck = { 7, -11, -5 },
		RightShoulder = { 40, 0, 46 }, RightElbow = { 54 }, LeftShoulder = { 53, 0, -30 }, LeftElbow = { 60 }, LeftWrist = { -18 },
	} },
	{ F.answer, {
		Body = { 0, -0.10, -0.05 }, Turn = { -2, 9, 0 }, Waist = { -2, 2, -2 }, Neck = { 8, -10, -5 },
		RightShoulder = { 42, 0, 46 }, RightElbow = { 55 }, LeftShoulder = { 60, 0, -30 }, LeftElbow = { 56 },
	} },
}
for _, k in hero do
	k[2].LeftFoot, k[2].RightFoot = { -0.34, 0, -0.5 }, { 0.4, 0, 0.5 }
	k[2].LeftFootTurn, k[2].RightFootTurn = { 0, 22 }, { 0, -30 }
end

return {
	ground = Acting.clip(ground, offsets),
	hero = Acting.clip(hero, { RightWrist = 1, LeftWrist = 2, Neck = 1 }),
}
