local S = require(script.Parent.Scenery)
local GalleryRun = require(script.Parent.GalleryRun)
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
	elseif age < -2 then
		local n = phase(cut.beacon, cut.autoStrike + 8)
		aim = face:Lerp(surface, 0.57)
		eye = aim
			+ route:VectorToWorldSpace(V(4.83 - 0.35 * n, 0.95 + 0.1 * n, 4.97 - 0.45 * n) * u * actor.portraitDistance)
		lens, roll = 47, 1.2 - 1.0 * n
		if frame < cut.beacon + 8 then
			-- Start tight enough to read the dispatch. Pull back past the seal
			-- to reveal the named miner working beside that same board.
			local read = phase(cut.commission, cut.beacon)
			local reveal = if motion then S.ease(frame, cut.beacon - 24, cut.beacon + 8)
				elseif frame < cut.beacon then 0 else 1
			local paper = marker.invitation.WorldCFrame
			local closeAim = paper * V(0, 0.03 * u, 0)
			local closeEye = paper * (V(-0.42 + 0.63 * read, 0.13, if portrait then 4.5 else 3.88 - 0.25 * read) * u)
			eye, aim = closeEye:Lerp(eye, reveal), closeAim:Lerp(aim, reveal)
			lens = 35.5 + (lens - 35.5) * reveal
			local letterRoll = -2.8 + 1.5 * read
			roll = letterRoll + (roll - letterRoll) * reveal
		elseif motion and age >= -8 then
			-- The player picks the onset. Tighten with the lift, keeping the
			-- point of contact registered as the close-up takes over.
			local lift = S.ease(age, -8, -2)
			eye = eye:Lerp(surface + route:VectorToWorldSpace(V(3.36, 0.92, 0.86) * u), 0.24 * lift)
			aim = aim:Lerp(surface, 0.48 * lift)
			lens -= 2.8 * lift
			roll -= 2.1 * lift
		end
	elseif age < 18 then
		-- Hold on the steel for contact. Descend on the open side of the
		-- station with the discharge, then follow the lit metal across sand.
		local n = phase(contact, contact + 18)
		local follow = if motion then S.ease(age, 2, 17) elseif age < 6 then 0 else 1
		local kick = if motion then S.ease(age, 0, 1) * (1 - S.ease(age, 1, 6)) else 0
		local closeEye = surface + route:VectorToWorldSpace(V(3.36 + 0.19 * kick, 0.92, 0.86) * u)
		local closeAim = surface + route.RightVector * 0.08 * u
		local lowEye, lowAim = GalleryRun.gallery(actor, frame, contact + 4, motion)
		eye, aim = closeEye:Lerp(lowEye, follow), closeAim:Lerp(lowAim, follow)
		lens = 40 + kick + (14 - kick) * follow
		roll = (-5.2 + 3.5 * kick) * (1 - follow) + -2.6 * (1 - n) * follow
	elseif frame < cut.lode then
		eye, aim, lens, roll = GalleryRun.gallery(actor, frame, contact + 4, motion)
	else
		-- Replace the tip of the lode with the miner's silhouette at the
		-- same screen position. Keep retreating into the playable camera.
		local reveal = if motion then 1 - math.exp(-math.max(0, frame - cut.challenge) / 21) else 0.7
		eye = route * (V(-1.92 - 1.16 * reveal, 1.53 + 0.47 * reveal, 5.58 + 1.72 * reveal) * u)
		aim = route * (V(0.20 + 0.12 * reveal, 1.39 - 0.12 * reveal, -13 - 6.9 * reveal) * u)
		lens, roll = 48.5 + 2.5 * reveal, -1.8 * (1 - reveal)
	end
	actor.lens.FocusDistance = (aim - eye).Magnitude
	return eye, aim, lens, if motion then math.rad(roll) else 0
end

return Camera
