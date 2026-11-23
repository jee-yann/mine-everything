-- A drawing remains on screen until the next entry's approach window. Short
-- approaches are drawn in real time; a zero-length window is a cut to a pose.
local Acting = {}
local V = Vector3.new
local beats = require(script.Parent.Beats)

function Acting.read(sheet, t)
	local previous = sheet[1][2]
	for i = 2, #sheet do
		local entry = sheet[i]
		local at, drawing, approach = entry[1], entry[2], entry[3]
		if t < at then
			if approach == 0 or t <= at - approach then
				return previous
			end
			local u = (t - (at - approach)) / approach
			local result = {}
			for name, value in previous do
				local goal = drawing[name]
				result[name] = if typeof(value) == "Vector3" then value:Lerp(goal, u) else value + (goal - value) * u
			end
			return result
		end
		previous = drawing
	end
	return previous
end

-- Positions are on the gallery floor plan. The hand holds the pick on the
-- actor's outside shoulder. The beak vector draws its arc beyond the head.
-- Torso and gaze angles are in degrees; foot.Y is the height of the stance.
local function miner(foot, yaw, grip, beak, freeHand, torso, gaze, bite)
	return {
		foot = foot,
		yaw = yaw,
		grip = grip,
		beak = beak,
		freeHand = freeHand,
		torso = torso,
		gaze = gaze,
		bite = bite or 0,
	}
end
local waiting = miner(
	V(2.16, 0, 6.36),
	50,
	V(3.14, 2.8, 5.82),
	V(1.30, 1.48, -0.10),
	V(1.38, 2.4, 6.52),
	V(0, -3, 2),
	V(-4, -16, 2)
)
local hears = miner(
	V(2.16, -0.03, 6.36),
	50,
	V(3.06, 2.76, 5.81),
	V(1.30, 1.48, -0.10),
	V(1.46, 2.6, 6.36),
	V(1, -3, 2),
	V(-12, -33, -5)
)
local offer = miner(
	V(2.12, 0.02, 6.32),
	54,
	V(3.20, 2.91, 5.95),
	V(1.20, 1.48, 0.14),
	V(1.80, 3.82, 5.51),
	V(2, -12, -5),
	V(4, -23, -6)
)
local set = miner(
	V(2.17, -0.22, 6.33),
	57,
	V(3.27, 3.00, 5.82),
	V(1.58, 0.63, -0.65),
	V(1.30, 2.63, 5.64),
	V(-8, -12, -7),
	V(-10, 16, 6)
)
local drive = miner(
	V(2.21, -0.02, 6.38),
	68,
	V(3.52, 4.03, 6.04),
	V(1.63, 0.85, 0.10),
	V(1.10, 2.91, 5.64),
	V(0, -18, -11),
	V(-5, 18, 8)
)
local high = miner(
	V(2.24, 0.09, 6.46),
	83,
	V(3.39, 5.10, 6.73),
	V(0.93, 1.82, 0.90),
	V(0.84, 3.05, 5.49),
	V(10, -21, -12),
	V(4, 21, 5)
)
local loaded = miner(
	V(2.26, 0.08, 6.49),
	87,
	V(3.37, 5.26, 6.91),
	V(1.12, 1.45, 1.34),
	V(0.76, 2.97, 5.49),
	V(11, -23, -12),
	V(2, 21, 5)
)
local coil = miner(
	V(2.15, -0.03, 6.41),
	81,
	V(3.15, 5.20, 6.96),
	V(0.18, 1.13, 1.72),
	V(0.71, 3.13, 5.42),
	V(4, -25, -10),
	V(-12, 18, 6)
)
local cross = miner(
	V(1.92, -0.12, 6.21),
	69,
	V(2.36, 4.65, 5.84),
	V(-1.29, 1.99, -0.25),
	V(0.52, 2.91, 5.91),
	V(-5, -2, -7),
	V(-15, 9, 2)
)
local slash = miner(
	V(1.62, -0.27, 6.02),
	63,
	V(1.85, 3.61, 5.43),
	V(-1.8, 0.31, -0.6),
	V(0.62, 2.44, 6.20),
	V(-18, 17, -4),
	V(-14, 4, 0)
)
local buried = miner(
	V(1.48, -0.39, 5.88),
	61,
	V(1.53, 2.90, 5.43),
	V(-1.33, -1.09, -0.61),
	V(0.72, 2.12, 6.34),
	V(-24, 24, 4),
	V(-11, 0, -4),
	1
)
local catch = miner(
	V(1.60, -0.25, 5.94),
	60,
	V(1.82, 3.00, 5.47),
	V(-1.30, -0.81, -0.71),
	V(0.77, 2.88, 6.15),
	V(-15, 15, 6),
	V(-20, -4, 4)
)
local listening = miner(
	V(1.64, -0.36, 5.96),
	60,
	V(1.78, 2.70, 5.54),
	V(-1.57, -0.70, -0.24),
	V(0.61, 2.39, 5.72),
	V(-19, 12, 8),
	V(-22, -10, 13)
)
local startle = miner(
	V(1.87, -0.13, 6.18),
	55,
	V(2.64, 3.10, 5.76),
	V(-0.52, 1.64, -0.71),
	V(0.36, 3.68, 6.08),
	V(12, -9, -7),
	V(-9, 25, -12)
)
local turn = miner(
	V(1.69, 0, 6.10),
	26,
	V(2.78, 2.84, 5.70),
	V(0.55, 1.78, 0.54),
	V(0.48, 3.25, 5.58),
	V(-5, -8, 3),
	V(2, 18, -3)
)

local hit, echo = beats.pick, beats.answer
Acting.miner = {
	{ 0, waiting, 0 },
	{ beats.returned[1] + 0.13, hears, 0.06 },
	{ 39.46, offer, 0.15 },
	{ 39.96, set, 0.18 },
	{ 40.28, drive, 0.12 },
	{ 40.58, high, 0.21 },
	{ 40.85, loaded, 0.09 },
	{ hit - 0.24, coil, 0.085 },
	{ hit - 0.115, cross, 0.04 },
	{ hit - 0.053, slash, 0.026 },
	{ hit, buried, 0.028 },
	{ hit + 0.24, catch, 0.058 },
	{ hit + 0.70, listening, 0.19 },
	{ echo + 0.13, startle, 0.065 },
	{ 44.30, turn, 0.19 },
}

-- The meter stays to one side of the face. The free hand goes to the
-- aerial first, is arrested in midair, then points back down the gallery.
local function lead(meter, tilt, hand, gaze, body, stance)
	return { meter = meter, tilt = tilt, hand = hand, gaze = gaze, body = body, stance = stance }
end
local ready = lead(V(-3.0, 3.04, 6.70), V(-10, 3, -5), V(-5.02, 2.53, 5.83), V(-4, -13, 2), V(-4, -2, 0), V(0, 0, 32))
local listens =
	lead(V(-2.94, 3.66, 6.68), V(-9, 4, -4), V(-5.14, 3.95, 6.18), V(-17, -24, -6), V(-3, -3, 5), V(0, 0, 30))
local catchBreath =
	lead(V(-2.97, 3.72, 6.70), V(-5, 4, 1), V(-5.26, 4.16, 6.20), V(-15, -29, -12), V(1, -2, 8), V(-0.035, 0.02, 30))
local count =
	lead(V(-2.93, 3.61, 6.70), V(-9, 7, -2), V(-4.81, 4.12, 6.20), V(-13, -24, -4), V(-1, 0, 5), V(0, -0.02, 26))
local looksUp =
	lead(V(-2.99, 3.40, 6.62), V(-16, 8, -6), V(-4.78, 4.09, 6.15), V(1, 33, 5), V(-2, 12, -2), V(0.025, 0, 13))
local explains =
	lead(V(-3.12, 2.98, 6.55), V(-18, 14, -6), V(-2.78, 2.55, 4.86), V(0, 26, 9), V(-4, 13, -5), V(0.045, -0.05, -9))
local shields =
	lead(V(-3.26, 3.17, 6.47), V(-7, 15, -11), V(-4.68, 3.95, 6.38), V(-4, 16, -13), V(13, -8, 8), V(-0.12, -0.23, -3))
local after =
	lead(V(-3.05, 2.84, 6.56), V(-19, 11, -8), V(-3.12, 2.86, 5.00), V(-9, 15, -1), V(-6, 12, -4), V(0, -0.06, -8))
local gazeBack =
	lead(V(-3.22, 3.01, 6.37), V(-14, 18, -8), V(-3.11, 3.35, 4.96), V(3, -29, 2), V(1, -8, -1), V(-0.08, 0, -24))
local replies = beats.returned
Acting.lead = {
	{ 0, ready, 0 },
	{ 34.78, listens, 0.25 },
	{ replies[1] + 0.10, catchBreath, 0.045 },
	{ replies[2] + 0.12, count, 0.08 },
	{ replies[3] + 0.15, looksUp, 0.09 },
	{ 37.72, explains, 0.18 },
	{ hit + 0.08, shields, 0.11 },
	{ 42.43, after, 0.14 },
	{ echo + 0.28, gazeBack, 0.12 },
}

return Acting
