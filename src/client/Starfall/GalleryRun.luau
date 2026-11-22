local cut = require(script.Parent.ExposureSheet).frames
local V = Vector3.new
local Run = {}

-- Coordinates relative to the playable mine's grid origin. This is the centre of
-- cell (-2, -1, -7), between the two pairs of lamps on the gallery dig floor.
Run.mouth = V(-9, 0, -39)
Run.depth = 22
Run.shaft = CFrame.new(Run.mouth - V(0, Run.depth, 0)) * CFrame.Angles(-math.pi / 2, 0, 0)

function Run.origin(actor)
	local h = actor.handoff
	local origin = h.origin or (h.landing - V(0, 4.96, 89))
	return origin + ((actor.replayLanding or h.landing) - h.landing)
end

-- Each tangent is in studs per picture so changing the interval cannot put
-- a hitch in the lens. The side slip bends around the first suspended lamp.
local function hermite(a, b, u, span)
	local u2, u3 = u * u, u * u * u
	return a[1] * (2 * u3 - 3 * u2 + 1)
		+ a[2] * (span * (u3 - 2 * u2 + u))
		+ b[1] * (-2 * u3 + 3 * u2)
		+ b[2] * (span * (u3 - u2))
end

local function sample(keys, f)
	local a = keys[1]
	for i = 2, #keys do
		local b = keys[i]
		if f <= b[3] then
			local span = b[3] - a[3]
			return hermite(a, b, math.clamp((f - a[3]) / span, 0, 1), span)
		end
		a = b
	end
	return a[1]
end

-- At the match the shaft's local Y points towards the gallery back wall and
-- its local -Z points straight down. Both views photograph one lens trajectory.
local matchEye, velocity = V(-0.20, 0.05, 21.25), V(0.045, 0.045, -1.05)
local matchLook = V(-0.20, 0.91, 14.85)
local eyeRail = {
	{ V(-2.1, 3.65, 31.5), V(0.04, 0.02, -1.50), cut.mineRun - 12 },
	{ V(-2.05, 4.12, 12.0), V(-0.077, 0.045, -1.72), cut.mineRun },
	{ V(-6.5, 5.05, -19.3), V(-0.40, 0.008, -1.79), cut.mineRun + 18 },
	{ V(-9.46, 4.68, -32.5), V(-0.17, -0.16, -1.28), cut.lode - 10 },
	{ V(-9.53, 2.92, -38.35), V(0.088, -0.64, -0.45), cut.lode - 4 },
	{ Run.shaft * matchEye, Run.shaft:VectorToWorldSpace(velocity), cut.lode },
}
local lookRail = {
	{ V(-0.5, 6.65, -1.7), V(-0.01, 0.04, -0.75), cut.mineRun - 12 },
	{ V(-2.5, 5.60, -15), V(-0.29, -0.11, -1.23), cut.mineRun },
	{ V(-9.35, 1.64, -39.2), V(-0.15, -0.15, -0.61), cut.mineRun + 18 },
	{ V(-9.4, -0.60, -39.62), V(0.018, -0.40, 0.015), cut.lode - 10 },
	{ Run.shaft * matchLook, Run.shaft:VectorToWorldSpace(V(0.045, 0, -0.62)), cut.lode },
}
local deepEye = {
	{ matchEye, velocity, cut.lode },
	{ V(-0.40, 0.93, 10.35), V(-0.09, 0.059, -0.56), cut.lode + 14 },
	{ V(-1.58, 0.72, 7.28), V(0.016, 0.009, -0.031), cut.lode + 32 },
	{ V(-0.58, 0.96, 6.40), V(0, 0, -0.006), cut.challenge - 1 },
}
local deepLook = {
	{ matchLook, V(0.045, 0, -0.62), cut.lode },
	{ V(0.28, 0.95, 2.5), V(-0.01, 0, -0.54), cut.lode + 15 },
	{ V(-0.38, 0.96, -1.35), V(0, 0.003, 0), cut.lode + 32 },
	{ V(-0.38, 1.17, -1.35), Vector3.zero, cut.challenge - 1 },
}

function Run.waymarks(actor, n)
	local route, u = actor.mineBearing, actor.unit
	local exit = actor.marker.exit.WorldPosition
	local start = V(route.X, exit.Y, route.Z)
	local line = start:Lerp(exit, 0.08 + 0.65 * n)
	local aim = line + route.LookVector * (4.6 * u) + V(0, (0.25 + 0.82 * n) * u, 0)
	local eye = line + route:VectorToWorldSpace(V(-2.3 + 1.05 * n, 2.12 - 0.63 * n, 2.8) * u)
	return eye, aim
end

local function approach(a, b, t, span)
	if span <= 32 then
		return hermite(a, b, t, span)
	end
	-- A player can ring the beacon three seconds early. Preserve both end
	-- velocities in short ramps and distribute the extra time over the bridge.
	-- Scaling a single cubic's handles across this interval can reverse a dolly.
	local ramp, elapsed = 5, t * span
	local coast = (b[1] - a[1] - (a[2] + b[2]) * (ramp / 2)) / (span - ramp)
	if elapsed < ramp then
		return a[1] + a[2] * elapsed + (coast - a[2]) * (elapsed ^ 2 / (2 * ramp))
	elseif elapsed > span - ramp then
		local remaining = span - elapsed
		return b[1] - b[2] * remaining + (b[2] - coast) * (remaining ^ 2 / (2 * ramp))
	end
	return a[1] + (a[2] + coast) * (ramp / 2) + coast * (elapsed - ramp)
end

function Run.gallery(actor, frame, first, motion)
	local origin = Run.origin(actor)
	if not motion then
		local f = if frame < cut.mineRun then cut.mineRun - 12 else cut.mineRun + 18
		return origin + sample(eyeRail, f), origin + sample(lookRail, f), 54, 0
	end
	if frame < eyeRail[1][3] then
		local e0, a0 = Run.waymarks(actor, 1)
		local previousEye, previousAim = Run.waymarks(actor, 0.95)
		local span = eyeRail[1][3] - first
		local t = math.clamp((frame - first) / span, 0, 1)
		return origin + approach({ e0 - origin, e0 - previousEye }, eyeRail[1], t, span),
			origin + approach({ a0 - origin, a0 - previousAim }, lookRail[1], t, span),
			49 + t * 5,
			-1.1 * (1 - t)
	end
	return origin + sample(eyeRail, frame), origin + sample(lookRail, frame), 54, 0
end

function Run.chamber(frame, motion, portrait)
	local f = if motion then frame else cut.lode + 37
	local t = math.clamp((f - cut.lode) / 32, 0, 1)
	local blend = t * t * (3 - 2 * t)
	local eye, aim = sample(deepEye, f), sample(deepLook, f)
	if portrait then
		aim += V(0.84 * blend, 0, 0)
	end
	return eye, aim, 54 - 12 * blend, math.rad(-2.6 * blend)
end

return Run
