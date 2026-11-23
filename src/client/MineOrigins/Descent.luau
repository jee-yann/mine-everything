-- The flight is continuous in world space. A locked intercept, a passing lens
-- and two tracking mounts give that single path very different screen speeds.
local V = Vector3.new
local Shot = {}
local cover = require(script.Parent.Crater).coverHeight
local vent = V(0, -0.205, -37.25)
local finishEye, finishLook = V(-28, 31, 41), V(0, -2, 0)

function Shot.frame(t, motion, path)
	local at = path(t)
	if not motion and t < 6.50 then
		-- Retain the entry direction, with longer lenses and a much smaller
		-- pan for players who turned camera motion down.
		if t < 2.22 then
			return path(-1.1) + V(-14, 38, 62), path(1.55), 66, 0
		elseif t < 4.28 then
			local eye = at + V(-19, 12, 46)
			return eye, at + V(1, -2, 0), 57, 0
		elseif t < 5.60 then
			return V(-72, 61, 62), path(5.05), 59, 0
		end
		return V(-15, cover + 7, 34), V(-1.6, cover + 4, 0), 59, 0
	end
	local side = V(-0.51, 0, 0.86)
	if t < 1.36 then
		-- Sight down the incoming diagonal. The cove gives the eye a fixed
		-- destination as the camera closes the gap to the incandescent tail.
		local drift = if motion then t / 1.36 else 0.45
		local eye = path(-1.52) + side * (43 - 16 * drift) + V(0, 33 - 9 * drift, 0)
		return eye, at:Lerp(path(5.9), 0.16), 49 - 3 * drift, -0.04
	elseif t < 2.22 then
		-- The body overtakes a slower parallel camera, crossing the frame.
		local u = (t - 1.36) / 0.86
		local mount = path(1.36 + 0.68 * u)
		local eye = mount + side * (15 - 4 * u) + V(1, 6, 3)
		return eye, at:Lerp(mount, 0.25), 62 - 9 * u, -0.16 + 0.11 * u
	elseif t < 2.77 then
		-- A low lens waits on the inside of the line. Its pan starts late,
		-- then overshoots into the wake after the iron has cleared the lens.
		local cross = path(2.46)
		local chase = if motion then math.clamp((t - 2.41) / 0.34, 0, 1) else 0.4
		return cross + side * 7 - V(0, 4, 0), path(2.35 + 0.41 * chase), 74, 0.11 - chase * 0.18
	elseif t < 4.28 then
		local lead = (path(t + 0.04) - at).Unit
		local u = (t - 2.77) / 1.51
		local eye = at - lead * (17 + 14 * u) + side * (8 - 13 * u) + V(0, 8 + 7 * u, 0)
		return eye, at + lead * (26 + 17 * u), 68 + 6 * u, 0.12 - 0.19 * u
	elseif t < 5.60 then
		local u = (t - 4.28) / 1.32
		local eye = V(-68 + 13 * u, 60 - 7 * u, 55)
		return eye, path(4.62 + 0.65 * u), 50 - 4 * u, -0.08
	elseif t < 6.23 then
		local u = (t - 5.60) / 0.63
		return V(3.5 - 0.9 * u, cover + 1.79, 5.8 - u), V(0.1, cover + 1.1, 0), 48, -0.05
	elseif t < 6.50 then
		return V(-9, cover + 3.2, 24), V(-1.6, cover + 5.2, -0.8), 57, -0.075
	elseif t < 7.15 then
		local age = t - 6.50
		local kick = if motion then math.sin(age * 23) * math.exp(-age * 8) else 0
		return V(-17 - 17 * age, 44 + 16 * age + 2.6 * kick, 61 + 27 * age),
			V(0, 33 + 5 * age, 0),
			59 + 6 * age,
			-0.045 + 0.075 * kick
	elseif t < 9.40 then
		-- Hold both coasts inside the aperture. Track gently against the
		-- approaching whitewater until the crest runs underneath this lens.
		local u = (t - 7.15) / 2.25
		local drift = if motion then u else 0.5
		return V(-168 + 41 * drift, 302 + 18 * drift, 327 + 17 * drift),
			V(0, 8 + 3 * drift, 51),
			51 + 2 * drift,
			-0.012 + 0.012 * drift
	elseif t < 9.96 then
		local drift = if motion then (t - 9.4) * 1.6 else 0
		return V(-7.5 + drift, 8.8, 10.5 - drift), V(0.3, -3.4, 0.3), 43, -0.08
	elseif t < 10.59 then
		-- Straight across the two rock lips: catch only the light slipping
		-- between them. The player's strike repeats this insert in the present.
		return V(3.5, 11.8, 5.6), V(1.32, -3.9, 0.27), 38, 0.068
	elseif t < 11.49 then
		local knock = motion and ((t >= 10.68 and t < 10.76) or (t >= 11.12 and t < 11.19))
		return V(-16, 18.5, 21.7) + (if knock then V(-0.52, 0.65, 0) else Vector3.zero),
			V(0.7, -3.4, 0),
			49,
			if knock then -0.032 else 0
	end
	return finishEye, finishLook, 52, 0
end

function Shot.surface(t, motion, eye, look, fov, roll)
	-- Cut out a full lens size on the sealed crater. Its surrounding cliffs
	-- register the location across the cut to the weathered geological set.
	if t < 13.04 then
		return vent + V(-62, 72, 102), vent + V(0, 7, 6), 54, 0
	end
	return eye, look, fov, roll
end

return Shot
