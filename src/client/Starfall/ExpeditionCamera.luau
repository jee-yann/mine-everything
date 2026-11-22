local S = require(script.Parent.Scenery)
local cut = require(script.Parent.ExposureSheet).frames
local V = Vector3.new
local Camera = {}

function Camera.frame(actor, _, motion)
	local frame, u = actor.frame, actor.unit
	local pickSide = actor.facing
	local route = actor.mineBearing
	local marker = actor.marker
	local surface = marker.core.WorldPosition
	local face = if actor.head then actor.head.Position else pickSide * V(0, 1.55 * u, 0)
	local portrait = actor.stage.Parent.ViewportSize.X < actor.stage.Parent.ViewportSize.Y
	local contact = actor.contactFrame or cut.autoStrike + 8
	local age = frame - contact
	local function phase(first, last)
		return if motion then math.clamp((frame - first) / (last - first), 0, 1) else 0.55
	end
	local eye, aim, lens, roll
	if frame < cut.measure then
		-- Looking across the scarred side puts the fissure in the foreground.
		-- The prospector's free hand and eyeline indicate where to look next.
		local n = phase(cut.present, cut.measure)
		local p = actor.proof
		local plane = p.face.WorldCFrame
		local stone = p.seam.WorldPosition
		aim = stone:Lerp(face, if portrait then 0.41 else 0.33)
		eye = aim + plane:VectorToWorldSpace(V(3.0 - 1.28 * n, 1.65 - 0.36 * n, 7.1 - 0.54 * n) * u)
		lens, roll = 47, 1.2 - 0.9 * n
	elseif frame < cut.revealGem then
		local n = phase(cut.measure, cut.revealGem)
		local plane = actor.proof.face.WorldCFrame
		local stone = actor.proof.seam.WorldPosition
		local ageOfStrike = frame - cut.proofStrike
		local recoil = if motion and ageOfStrike >= 0 then math.exp(-0.30 * ageOfStrike) * math.cos(0.63 * ageOfStrike) else 0
		aim = stone:Lerp(face, 0.21)
		eye = aim + plane:VectorToWorldSpace(V(2.0 - 0.52 * n, 0.92, 5.45 - 0.72 * n + 0.16 * recoil) * u)
		lens, roll = 45 + 1.9 * recoil, -2.6 + 1.05 * n - recoil
	elseif frame < cut.portrait then
		local n = phase(cut.revealGem, cut.portrait)
		local plane = actor.proof.face.WorldCFrame
		aim = actor.proof.gem.WorldPosition
		eye = aim + plane:VectorToWorldSpace(V(0.53 - 0.68 * n, 0.50 + 0.12 * n, 3.7 - 0.40 * n) * u)
		lens, roll = 42, -1.9 + 0.9 * n
	elseif frame < cut.commission then
		-- The pick leads for five frames. Let the face and name stay registered
		-- as the photographic field takes the place of the harbor behind them.
		local n = phase(cut.portrait, cut.commission)
		local sweep = if motion then math.exp(-0.29 * (frame - cut.portrait)) else 0
		aim = face + V(0, actor.headroom * 0.62 - 0.22 * u, 0)
			+ pickSide.RightVector * ((if portrait then 0.25 else 0.91) * u)
		local roomForPick = if portrait then 1.22 else 1.08
		eye = face + pickSide:VectorToWorldSpace(
			V(1.48 - 0.46 * n + sweep, -0.74 + 0.19 * n - 0.50 * sweep, -5.35 + 0.22 * n)
				* u * actor.portraitDistance * roomForPick)
		lens, roll = 42 + 3 * sweep, -4.2 + 1.1 * n - 2 * sweep
	elseif frame < cut.beacon then
		local n = phase(cut.commission, cut.beacon)
		local paper = marker.invitation.WorldCFrame
		aim = paper * V(0, 0.03 * u, 0)
		eye = paper * (V(-0.42 + 0.63 * n, 0.13, if portrait then 4.5 else 3.88 - 0.25 * n) * u)
		lens, roll = 35.5, -2.8 + 1.5 * n
	elseif age < -2 then
		-- Both the character and the target remain visible whilst the viewer
		-- chooses when to swing. The camera never tracks the jitter of a hand.
		local n = phase(cut.beacon, cut.autoStrike + 8)
		aim = face:Lerp(surface, 0.57)
		eye = aim
			+ route:VectorToWorldSpace(V(4.83 - 0.35 * n, 0.95 + 0.1 * n, 4.97 - 0.45 * n) * u * actor.portraitDistance)
		lens, roll = 47, 1.2 - 1.0 * n
	elseif age < 6 then
		local kick = if motion then S.ease(age, 0, 1) * (1 - S.ease(age, 1, 6)) else 0
		aim = surface + route.RightVector * 0.08 * u
		eye = surface + route:VectorToWorldSpace(V(3.36 + 0.19 * kick, 0.92, 0.86) * u)
		lens, roll = 40 + kick, -5.2 + 3.5 * kick
	elseif age < 26 then
		-- The inlays run out under the lens. Follow their bearing low enough
		-- for the next arrow to silhouette against the yellow sand.
		local n = phase(contact + 6, contact + 26)
		local exit = marker.exit.WorldPosition
		local start = V(route.X, exit.Y, route.Z)
		local line = start:Lerp(exit, 0.08 + 0.65 * n)
		aim = line + route.LookVector * (4.6 * u) + V(0, (0.25 + 0.82 * n) * u, 0)
		eye = line + route:VectorToWorldSpace(V(-2.3 + 1.05 * n, 2.12 - 0.63 * n, 2.8) * u)
		lens, roll = 49, -4.8 + 3.7 * n
	elseif frame < cut.lode then
		local gate = route.Position
			+ (actor.handoff.entrance or (actor.handoff.landing + route.LookVector * 72))
			- actor.handoff.landing
		local forward = route.LookVector
		local right = route.RightVector
		local low = V(0, 1.8, 0)
		local ready = phase(contact + 26, cut.mineRun)
		local run = if frame >= cut.mineRun and motion then phase(cut.mineRun, cut.lode) else 0
		-- Pass between the real basalt piers at full speed. The gentle
		-- approach has a nonzero tangent straight into the quintic dive.
		local travel = 6 * run + 50 * run ^ 5
		eye = gate + right * (-6.0 + 2.8 * ready + 2.5 * run)
			+ low + V(0, 0.40 * ready + 0.28 * run, 0)
			- forward * (35.8 - 4.1 * ready - travel)
		aim = gate + forward * (4 + travel * 0.74) + V(0, 4.6 - 2.8 * run, 0)
		lens, roll = 50 + 7 * run ^ 3, -1.6 + 0.6 * ready + 2.8 * run ^ 3
	else
		local n = phase(cut.challenge, cut.endBlend)
		eye = route * (V(-3.62 + 0.63 * n, 1.67 + 0.35 * n, 6.65 + 0.54 * n) * u)
		aim = route * V(0.32 * u, 1.27 * u, -18 - 1.9 * n)
		lens, roll = 51, -1.3 * (1 - n)
	end
	actor.lens.FocusDistance = (aim - eye).Magnitude
	return eye, aim, lens, if motion then math.rad(roll) else 0
end

return Camera
