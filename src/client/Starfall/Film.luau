local Island = require(script.Parent.Island)
local Impact = require(script.Parent.Impact)
local Arrival = require(script.Parent.Arrival)
local LivingRoom = require(script.Parent.LivingRoom)
local MineFace = require(script.Parent.MineFace)
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
	{ frames.seam + 4, frames.dark - 4, "Deep in the rock, the star took root." },
	{ frames.dark + 2, frames.match + 40, "Millions of years later" },
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
	local sun = game:GetService("Lighting"):GetSunDirection()
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
		-- Interior sets wait above and behind the cameras that cut to them. The
		-- engine lights the region around the lens, so a set this close is
		-- already lit on its first exposure. A distant one opens in the dark.
		self.mine = MineFace.new(stage, (live * CF(-70, 96, 60)).Position, sun)
		self.room = LivingRoom.new(stage, (live * CF(20, 96, 70)).Position, sun, screen.Parent)
		self.embers = {}
		for _, part in self.island.hot:GetDescendants() do
			if part:IsA("BasePart") and part.Material == Enum.Material.Neon then
				table.insert(self.embers, { part = part, color = part.Color })
			elseif part:IsA("PointLight") then
				self.emberLight, self.emberPower = part, part.Brightness
			end
		end
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

function Film:landingFrame(frame)
	local h = self.handoff
	local target = h.playable or h
	self:frame(CFrame.identity, self.arrival:camera(frame, self.motion))
	if self.arrival.remote then
		-- The live character is elsewhere. Fade, then return to them.
		return ease(frame, frames.handoff + 8, frames.endBlend)
	end
	local finish = ease(frame, frames.handoff, frames.endBlend)
	if finish >= 1 then
		self.camera.CFrame, self.camera.Focus, self.camera.FieldOfView = target.view, target.focus, target.fov
	else
		self.camera.CFrame = self.camera.CFrame:Lerp(target.view, finish)
		self.camera.Focus = self.camera.Focus:Lerp(target.focus, finish)
		self.camera.FieldOfView += (target.fov - self.camera.FieldOfView) * finish
	end
	return 0
end

local function mix(a, b, u)
	return a + (b - a) * u
end

-- The star in the rock burns down until only the dark is left.
function Film:burnDown(frame)
	local low = if frame < frames.seam then 0 else ease(frame, frames.seam + 20, frames.dark - 4)
	if low == self.emberLevel then
		return
	end
	self.emberLevel = low
	for _, e in self.embers do
		e.part.Color = e.color:Lerp(Color3.fromHex("120A1E"), low)
	end
	if self.emberLight then
		self.emberLight.Brightness = self.emberPower * (1 - low)
	end
end

-- One descending crane from above the bowl to the fork at its lip.
local function craterCrane(frame, move)
	local u = if move then ease(frame, frames.aftermath - 6, frames.seam + 16) else 0.35
	local eye = V(44, 86, 88):Lerp(V(27, 44, 70), u) + V(5, -5, 2) * math.sin(u * math.pi)
	return eye, V(3, 29, -8):Lerp(V(9.4, 32.6, 6), u), mix(41, 24, u), 0
end

local function craterFork(frame, move)
	local u = if move then ease(frame, frames.seam - 10, frames.dark + 10) else 0.5
	return V(mix(4.2, 8.0, u), mix(27.4, 27.9, u), mix(22.6, 21.0, u)), V(mix(10.0, 10.9, u), 31.9, 8), 34, 0
end

-- The same mark at sea the impact was watched from. Hold a breath so the
-- match registers, then crane down and in toward the settled cove.
local function islandToday(frame, move)
	local u = if move then ease(frame, frames.match + 8, frames.boulevard + 14) else 0
	local eye = clock.breakerEye:Lerp(V(84, 52, 124), u) + V(-6, -12, 18) * math.sin(u * math.pi)
	return eye, V(-7, 34, -21):Lerp(V(1, 42, 2), u), mix(50, 40, u), 0
end

local function boulevard(frame, move)
	local u = if move then math.clamp((frame - frames.boulevard) / (frames.dig - 11 - frames.boulevard), 0, 1) else 0.3
	local run = 0.35 * u + 0.65 * u * u
	return V(mix(3.4, 0, ease(u, 0, 0.8)), mix(32.4, 29.6, run), mix(60, 5, run)), V(mix(0.5, 0, u), mix(36.5, 29.8, ease(u, 0, 0.75)), -24), 46, 0
end

function Film:draw(t, liveReady, frame)
	frame = frame or math.round(sheet.frameForScene(t))
	local move = self.motion
	local modern = frame >= frames.match
	if not liveReady and frame >= frames.aftermath and not modern then
		self.island:prepareReplica()
	end
	if modern and self.matchLive == nil then self.matchLive = liveReady end
	local far = (self.handoff.root.Position - self.handoff.landing).Magnitude >= 38
	-- A player deep underground keeps the prepared copy for the whole film.
	-- Everyone else moves to the real cove before their own scenes.
	local replica = modern and not self.matchLive and (frame < frames.dig or far)
	if replica and far then
		self.arrival.replayLanding = self.handoff.landing + self.base.Position - self.live.Position
		self.arrival.replica = self.island.replaySite
	end
	self.island:draw(t, modern, replica, modern and frame < frames.handoff)
	self.tide:draw(t)
	self.arrival:draw(frame)
	self.mine:draw(frame, move)
	self.room:draw(frame, move)
	self.daylight:draw(t, move, self.base, frame)
	self:burnDown(frame)
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
		self:frame(base, craterCrane(frame, move))
	elseif frame < frames.match then
		self:frame(base, craterFork(frame, move))
		black = if frame >= frames.dark then 1 else ease(frame, frames.dark - 14, frames.dark)
	elseif frame < frames.boulevard then
		self:frame(if replica then base else self.live, islandToday(frame, move))
		black = 1 - ease(frame, frames.match, frames.match + 7)
	elseif frame < frames.dig then
		-- Daylight gives out inside the arch. The lens is already in the gallery
		-- during the dark beat, so its lamps are steady when we see it.
		if frame < frames.dig - 11 then
			self:frame(if replica then base else self.live, boulevard(frame, move))
		else
			self:frame(self.mine.at, self.mine:camera(frames.dig, move))
		end
		black = ease(frame, frames.dig - 20, frames.dig - 12)
	elseif frame < frames.living then
		self:frame(self.mine.at, self.mine:camera(frame, move))
		black = 1 - ease(frame, frames.dig, frames.dig + 8)
	elseif frame < frames.witness then
		self:frame(self.room.at, self.room:camera(frame, move))
	elseif frame < frames.handoff then
		self:frame(CFrame.identity, self.arrival:camera(frame, move))
	else
		black = self:landingFrame(frame)
	end
	if move and frame >= frames.entry and frame < frames.aftermath then
		self.camera.CFrame *= vibration(frame)
	end
	self.impact:draw(t, self.camera, frame)
	self.illumination:draw(t, Impact.position(t, frame), self.camera, move, frame)
	self.daylight:focus(self.camera, base, frame, move)
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
	for _, name in { "room", "mine", "daylight", "illumination", "impact", "arrival", "tide", "island" } do
		if self[name] then
			self[name]:Destroy()
		end
	end
end
return Film
