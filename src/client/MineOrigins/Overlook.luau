local ease = require(script.Parent.Props).ease
local V = Vector3.new
local Overlook = {}

function Overlook.frame(age, aspect, motion)
	local narrow = math.clamp((1.16 - aspect) / 0.70, 0, 1)
	local t = math.clamp(age / 15.1, 0, 1)
	local orbit = if motion then t else 0.32
	local angle = math.rad(-30 + 32 * orbit)
	local distance = (353 - 34 * orbit) * (1 + 0.10 * narrow)
	local look = V(-4 + orbit * 7, 40 - orbit * 5, 18)
	local eye = look + V(distance * math.sin(angle), 106 + narrow * 8, distance * math.cos(angle))
	if age >= 5.33 and age < 7.82 then
		-- Watch the survey boat make landfall against the same western cliff.
		local u = if motion then (age - 5.33) / 2.49 else 0.5
		return V(-205 + 28 * u, 51 + 5 * u, 130 + 12 * u), V(-123 + 35 * u, 5, 40), 52 + 3 * narrow, -0.019
	elseif age >= 9.05 and age < 10.91 then
		local u = if motion then (age - 9.05) / 1.86 else 0.5
		return V(18 - 7 * u, 13 + 2 * u, 62 - 5 * u), V(-2, 3, 34 - 6 * u), 49, 0
	elseif age >= 11.4 and age < 13.75 then
		local u = if motion then (age - 11.4) / 2.35 else 0.5
		return V(-42 + 15 * u, 32 - 7 * u, 72 - 13 * u), V(1, 11, 0), 55, -0.017
	elseif age < 15.10 then
		return eye, look, 48 - 2 * orbit, 0
	elseif age < 16.28 then
		local u = if motion then (age - 15.10) / 1.18 else 0.5
		return V(-68 + 8 * u, 51 - 6 * u, 116 - 11 * u), V(1.7, 13.5, 9), 52, -0.023
	end
	return V(-32, 29, 66), V(5, 8, 1), 57, -0.035
end

return Overlook
