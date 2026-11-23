local Island = require(script.Parent.Island)
local Impact = require(script.Parent.Impact)
local Arrival = require(script.Parent.Arrival)
local StarfallLode = require(script.Parent.StarfallLode)
local CoveBroadcast = require(script.Parent.CoveBroadcast)
local ProspectorPortrait = require(script.Parent.ProspectorPortrait)
local Daylight = require(script.Parent.Daylight)
local MeteorLight = require(script.Parent.MeteorLight)
local Tide = require(script.Parent.Tide)
local clock = require(script.Parent.Timeline)
local sheet = require(script.Parent.ExposureSheet)
local frames = sheet.frames
local ease = require(script.Parent.Scenery).ease
local V, CF = Vector3.new, CFrame.new
local Film = {}
Film.__index = Film
Film.duration = frames.duration / sheet.fps

local captions = {
	{ 1, 52, "Millions of years ago" },
	{ frames.aftermath + 7, frames.match - 7, "Deep in the rock, the star still glowed." },
	{ frames.establish + 1, frames.present - 1, "Millions of years later" },
	{ frames.measure - 36, frames.measure + 24, "One hit. Keep the gem whole." },
}
function Film.caption(t)
	local picture = sheet.frameForScene(t)
	for _, cue in captions do
		if picture >= cue[1] and picture < cue[2] then
			return cue[3], ease(picture, cue[1], cue[1] + 4) * (1 - ease(picture, cue[2] - 4, cue[2]))
		end
	end
	return "", 0
end

function Film.new(stage, screen, camera, handoff, motion, continueSetup, nightLook)
	local live = CF(handoff.landing - V(0, 28.96, 93))
	local base = live + V(0, 1850, -1250)

	local self = setmetatable({
		camera = camera,
		stage = stage,
		live = live,
		base = base,
		handoff = handoff,
		motion = motion,
	}, Film)
	-- Cleanup also covers a failed import during construction.
	local ok, reason = xpcall(function()
		self.tide = Tide.new(stage, base, nightLook, motion)
		self.daylight = Daylight.new(stage, nightLook)
		self:frame(base, Tide.camera(0, motion))
		self.tide:draw(0)
		self.daylight:draw(0, motion, base, 0)
		if continueSetup and not continueSetup() then
			return
		end
		self.island = Island.new(stage, base, live)
		self.daylight.lunar:relight(base, 0)
		self.illumination = MeteorLight.new(stage, base, self.island.set)
		if continueSetup and not continueSetup() then
			return
		end
		self.arrival = Arrival.new(stage, handoff)
		self.arrival.motion = motion
		self.lode = StarfallLode.new(stage, base * CF(0, 94, -480), self.island.set)
		self.arrival.marker.signal.chamber = self.lode.at
		self.arrival.marker.signal.crystalContact = self.lode.contactPoint
		self.broadcast = CoveBroadcast.new(screen)
		self.portrait = ProspectorPortrait.new(stage, screen)
		self.impact = Impact.new(stage, screen, base, motion)
	end, debug.traceback)
	if not ok then
		self:Destroy()
		error(reason, 0)
	end
	return self
end

-- Local translation away from the pressure front, lift, roll and lens kick.
local recoil = {
	{ 0, 0, 0, 0, 0 },
	{ 1, 7.8, 2.9, -5.3, 4.2 },
	{ 3, 9.6, 2.1, -3.5, 3.3 },
	{ 6, 3.9, -0.92, 2.25, 1.3 },
	{ 9, 1.10, 0.57, -1.54, 0.32 },
	{ 14, 0.48, -0.23, 0.72, 0.06 },
	{ 20, 0, 0, 0, 0 },
}
-- The lens registers the touch, hangs over the seam, then takes the blast.
local collisionRecoil = {
	{ 0, 0, 0, 0, 0 },
	{ 1, 0.8, 0.20, 0.5, 0.5 },
	{ 2, 0.35, 0.05, 0.1, 0.2 },
	{ 3, 3.3, 1.2, 2.4, 2.0 },
	{ 4, 6.2, 2.1, 3.5, 4.5 },
	{ 7, 2.7, -0.65, -2.3, 1.0 },
	{ 10, 0.8, 0.40, 1.0, 0.3 },
	{ 12, 0.3, 0.06, -0.16, 0 },
	{ 14, 3.1, 0.86, -1.6, 2.2 },
	{ 19, 0.72, -0.22, 0.58, 0.35 },
	{ 25, 0, 0, 0, 0 },
}
local function cameraImpulse(keys, age)
	if age <= 0 or age >= keys[#keys][1] then
		return 0, 0, 0, 0
	end
	for i = 2, #keys do
		local a, b = keys[i - 1], keys[i]
		if age <= b[1] then
			local n = ease(age, a[1], b[1])
			return a[2] + (b[2] - a[2]) * n,
				a[3] + (b[3] - a[3]) * n,
				a[4] + (b[4] - a[4]) * n,
				a[5] + (b[5] - a[5]) * n
		end
	end
	return 0, 0, 0, 0
end

local function pulse(frame, first, last, attack)
	return ease(frame, first, first + attack) * (1 - ease(frame, first + attack, last))
end

-- The ground carries vibration before the pressure front strikes the
-- observer. Wider, slower oscillations follow it into the burning crater.
local function vibration(frame)
	if frame < frames.entry or frame >= frames.seam then
		return CFrame.identity
	end
	local t = frame / sheet.fps
	local pressure
	if frame < frames.coast then
		pressure = 0.34 * pulse(frame, 55, 170, 39) + 0.57 * pulse(frame, 157, 208, 21)
	elseif frame < frames.contact then
		pressure = 0.12 + 0.50 * pulse(frame, 213, 231, 5) + 1.05 * ease(frame, 233, 239)
	else
		pressure = (if frame < frames.ignition then 0.22 else 1.42 * (1 - ease(frame, frames.ignition, 264)))
			+ 0.24 * (1 - ease(frame, 331, 354))
			+ 0.95 * pulse(frame, 300, 336, 24)
			+ 2.35 * pulse(frame, 324, 366, 3)
			+ 1.18 * pulse(frame, 353, 382, 3)
			+ 0.24 * ease(frame, 325, 352) * (1 - ease(frame, 355, frames.seam))
	end
	local lift = math.sin(2 * math.pi * 3.1 * t + 0.35) + 0.31 * math.sin(2 * math.pi * 6.7 * t)
	local sway = math.sin(2 * math.pi * 1.7 * t) + 0.23 * math.sin(2 * math.pi * 4.3 * t + 0.8)
	local travel = pressure * (1 - ease(frame, 373, 382))
	return CF(travel * 0.11 * sway, travel * 0.13 * lift, 0)
		* CFrame.Angles(
			math.rad(0.61 * pressure * lift),
			math.rad(0.28 * pressure * sway),
			math.rad(0.48 * pressure * sway)
		)
end

function Film:frame(base, eye, look, fov, roll, framing)
	local cam = self.camera
	local aspect = cam.ViewportSize.X / math.max(1, cam.ViewportSize.Y)
	-- On a phone, widen the offshore lens enough to catch all three streaks.
	-- Keep its eye fixed where the pressure front actually hits the camera.
	local width = if framing == "landscape" then 1.66 elseif framing == "offshore" then 1.21 else 1.05
	local fit = math.max(1, width / math.max(0.38, aspect))
	local limit = if framing == "offshore" then 106 else 86
	local lens = math.min(limit, math.deg(2 * math.atan(math.tan(math.rad(fov) / 2) * fit)))
	if framing == "landscape" then
		local residual = math.tan(math.rad(fov) / 2) * fit / math.tan(math.rad(lens) / 2)
		eye = look + (eye - look) * math.max(1, residual)
	end
	cam.CFrame = base * CFrame.lookAt(eye, look) * CFrame.Angles(0, 0, if self.motion then roll or 0 else 0)
	cam.Focus, cam.FieldOfView = base * CF(look), lens
end

function Film:landingFrame(t)
	local h = self.handoff
	local target = h.playable or h
	self:frame(CFrame.identity, self.arrival:camera(t, self.motion))
	local finish = ease(t, clock.handoff, clock.endBlend)
	if (h.root.Position - h.landing).Magnitude >= 38 then
		return ease(t, clock.duration - 0.38, clock.duration)
	end
	if finish >= 1 then
		self.camera.CFrame, self.camera.Focus, self.camera.FieldOfView = target.view, target.focus, target.fov
	else
		self.camera.CFrame = self.camera.CFrame:Lerp(target.view, finish)
		self.camera.Focus = self.camera.Focus:Lerp(target.focus, finish)
		self.camera.FieldOfView += (target.fov - self.camera.FieldOfView) * finish
	end
	return 0
end

function Film:draw(t, liveReady, frame)
	frame = frame or math.round(sheet.frameForScene(t))
	local move = self.motion
	local modern = frame >= frames.match
	if not liveReady and frame >= frames.aftermath and not modern then
		self.island:prepareReplica()
	end
	if modern and self.matchLive == nil then self.matchLive = liveReady end
	local remote = (self.handoff.root.Position - self.handoff.landing).Magnitude >= 38
	local replica = modern and not self.matchLive and (frame < frames.present or remote)
	if replica and remote then
		self.arrival.replayLanding = self.handoff.landing + self.base.Position - self.live.Position
	end
	self.island:draw(t, modern, replica, frame < frames.present)
	self.tide:draw(t)
	self.daylight:draw(t, move, self.base, frame)
	self.arrival:draw(t, frame)
	self.lode:expose(frame, move, self.arrival)
	local base = self.base
	local black = 0
	if t < clock.entry then
		self:frame(base, Tide.camera(t, move))
	elseif frame < frames.coast then
		self:frame(base, self.impact:camera(t, frame))
	elseif frame < frames.aftermath then
		local first = frame < frames.breaker
		local start = if first then frames.contact else frames.breaker
		local back, lift, roll, open =
			cameraImpulse(if first then collisionRecoil else recoil, if move then frame - start else 0)
		local eye = clock.breakerEye + V(0.90 * back, lift, 0.44 * back)
		local look = V(-7, 34, -21) + V(-3.3, 8.4, 0.5) * (lift / 2.9)
		self:frame(base, eye, look, 54 + open, math.rad(roll), "offshore")
	elseif frame < frames.seam then
		-- Hold the rim while the airborne earth settles. The next shot
		-- picks out one piece of the fractured rock in this landscape.
		self:frame(base, V(51, 51, 63), V(-2, 32, -23), 37, 0, "landscape")
	elseif frame < frames.establish then
		-- The very same fork fills the frame before and after the cut.
		-- Keep the marks, focal length and the operator's sideways step
		-- continuous. Only the rock finish and the world around it change.
		local fork = self.island.witnessPoint
		local offset = if move then (frame - frames.match) * 0.052 else 0
		local eye = fork + V(-2.70 + offset, 1.80, 11.8)
		local aim = fork + V(0.42 + 0.34 * offset, 0.90, 0)
		self:frame(if modern and not replica then self.live else base, eye, aim, 23)
	elseif frame < frames.present then
		-- Widen on a cut from the mineral to the masonry that holds it.
		-- From the spawn boulevard, the sign, arch and worked shore read
		-- together. Let the audience look around this fixed composition.
		local site = if replica then base else self.live
		local mark = site:PointToObjectSpace(self.arrival.mineBearing.Position)
		if (mark - V(0, 28.96, 93)).Magnitude < 14 then
			local distance = self.arrival.unit * self.arrival.portraitDistance
			local eye = mark + V(3.1, 2.4, 13.4) * distance
			self:frame(site, eye, V(0.3, 34.5, 8), 34, 0, "landscape")
		else
			-- A replay can open from a shop counter or a partially streamed
			-- shore. Keep that establishing lens clear of nearby kiosks.
			self:frame(site, V(2, 43, 76), V(0, 35, 7), 36, 0, "landscape")
		end
	elseif frame >= frames.lode and frame < frames.challenge then
		local portrait = self.camera.ViewportSize.X < self.camera.ViewportSize.Y
		local eye, look, lens, roll = self.lode:camera(frame, move, portrait)
		self:frame(self.lode.at, eye, look, lens, roll)
		self.arrival.lens.Enabled = true
		self.arrival.lens.FocusDistance = (look - eye).Magnitude
		self.arrival.lens.InFocusRadius = 2.1
	elseif t < clock.handoff then
		self:frame(CFrame.identity, self.arrival:camera(t, move))
	else
		black = self:landingFrame(t)
	end
	if move and frame >= frames.entry and frame < frames.seam then
		self.camera.CFrame *= vibration(frame)
	end
	self.impact:draw(t, self.camera, frame)
	self.illumination:draw(t, Impact.position(t, frame), self.camera, move, frame)
	self.daylight:focus(self.camera, base, frame, move)
	self.broadcast:draw(self.camera, frame, move)
	self.portrait:draw(self.arrival, self.camera, frame, move)
	return black
end

-- Keep the photographic result until the next exposure, including the final
-- blend while the player's regular camera controller works behind this shot.
function Film:expose(frame, liveReady)
	if frame ~= self.pictureFrame then
		local t = sheet.sceneTime(frame)
		self.black = self:draw(t, liveReady, frame)
		self.pictureFrame, self.sceneTime = frame, t
		self.view, self.focus, self.lens = self.camera.CFrame, self.camera.Focus, self.camera.FieldOfView
	end
	return self.black
end

function Film:holdCamera()
	self.camera.CFrame, self.camera.Focus, self.camera.FieldOfView = self.view, self.focus, self.lens
end

function Film:Destroy()
	for _, name in { "broadcast", "portrait", "daylight", "illumination", "impact", "arrival", "lode", "tide", "island" } do
		if self[name] then
			self[name]:Destroy()
		end
	end
end
return Film
