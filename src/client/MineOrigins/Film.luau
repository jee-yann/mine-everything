local Arrival = require(script.Parent.Arrival)
local IslandSky = require(script.Parent.IslandSky)
local Overlook = require(script.Parent.Overlook)
local History = require(script.Parent.History)
local Beats = require(script.Parent.Beats)
local Lighting = game:GetService("Lighting")
local P, Strike, Survey, Crew =
	require(script.Parent.Props),
	require(script.Parent.Strike),
	require(script.Parent.Survey),
	require(script.Parent.Crew)
local V, CF, A, ease = Vector3.new, CFrame.new, CFrame.Angles, P.ease
local Film = {}
Film.__index = Film
Film.duration = Beats.duration

local eras = {
	{ 0.65, 3.40, "8 MILLION YEARS AGO" },
	{ 15.06, 18.50, "OVER MILLIONS OF YEARS" },
	{ 19.70, 21.82, "THE FIRST SURVEY" },
	{ 29.80, 31.70, "CITRINE COVE  /  TODAY" },
}
local function envelope(t, a, b, edge)
	return ease(t, a, a + edge) * (1 - ease(t, b - edge, b))
end
function Film.caption(t)
	for _, cue in Beats.dialogue do
		if t >= cue[1] and t < cue[2] then
			return cue[3], cue[4], envelope(t, cue[1], cue[2], 0.15)
		end
	end
	return "", "", 0
end
function Film.era(t)
	for _, cue in eras do
		if t >= cue[1] and t < cue[2] then
			return cue[3], envelope(t, cue[1], cue[2], 0.24)
		end
	end
	return "", 0
end

function Film.card(t)
	return "IT KNOCKED BACK", envelope(t, 45.95, 48.65, 0.46)
end

function Film.new(shelf, stage, camera, site, gate, motion, clock, character, handoff)
	-- Separate sets let the island submit its geometry over several frames
	-- while the first camera is still looking across the impact site.
	local base = CF(site + V(0, 3200, -15000))
	local ancientStorage = Instance.new("Folder")
	ancientStorage.Parent = shelf
	local historyBase = CF(gate + V(0, 3196.5, 0))
	local strike = Strike.new(ancientStorage)
	strike.root:PivotTo(base)
	strike.root.Parent = stage
	return setmetatable({
		stage = stage,
		shelf = shelf,
		camera = camera,
		base = base,
		impactPoint = base * Strike.position(Beats.impact),
		gateBase = CF(gate - V(0, 3.5, 0)),
		motion = motion,
		clock = clock,
		character = character,
		historyBase = historyBase,
		history = History.new(stage, historyBase),
		handoff = handoff,
		strike = strike,
	}, Film)
end

local function verticalFov(viewport, fov)
	local aspect = viewport.X / math.max(1, viewport.Y)
	return math.min(
		97,
		math.deg(2 * math.atan(math.tan(math.rad(fov / 2)) * math.max(1, 1.28 / math.max(0.35, aspect))))
	)
end

function Film:frame(base, eye, look, fov, roll)
	local cam = self.camera
	cam.CFrame = base * CFrame.lookAt(eye, look) * A(0, 0, if self.motion then roll or 0 else 0)
	cam.Focus = base * CF(look)
	cam.FieldOfView = verticalFov(cam.ViewportSize, fov)
end

function Film:mountPresent(live)
	local frame = if live then self.gateBase else self.historyBase
	if not self.crew then
		self.crew = Crew.new(self.shelf, self.character)
		self.survey = Survey.new(self.shelf)
	end
	if self.modernBase ~= frame then
		if live then
			if self.history then
				self.history:Destroy()
				self.history = nil
			end
		else
			self.history:draw(17)
		end
		self.crew.root:PivotTo(frame)
		self.survey.root:PivotTo(frame)
		self.crew.root.Parent, self.survey.root.Parent = self.stage, self.stage
		self.modernBase, self.localPresent = frame, not live
	end
end

local presentCuts = { 31.66, 33.34, 35.13, 37.26, 39.21, 41.86, 44.32 }
local bridgeEye, bridgeLook = V(5.4, 5.55, 15.8), V(-1.15, 3.1, -2)

local function strikeKick(t, at)
	local age = t - at
	if age < 0 or age >= 0.15 then
		return 0
	end
	return if age < 0.045 then 1 elseif age < 0.09 then -0.28 else 0.12
end

function Film:present(t, shot)
	local base = self.modernBase
	local rock = base:PointToObjectSpace(self.crew.seamAim)
	if shot == 1 then
		-- The constructed gate and the working gate have the same silhouette.
		self:frame(base, V(-32, 29, 66), V(5, 8, 1), 57, -0.035)
	elseif shot == 2 then
		-- Read the first two strokes as a performance. Cut closer on the
		-- longer wind-up for the third, keeping the lever on the same side.
		local insert = t >= 32.65
		local eye = if insert then V(-2.9, 2.23, 4.62) else V(-4.45, 3.09, 7.72)
		local look = if insert then V(-0.47, 2.21, 0.15) else V(-0.85, 2.25, 0)
		local kick = 0
		if self.motion then
			for _, beat in Beats.outbound do
				kick += strikeKick(t, beat)
			end
		end
		self:frame(
			base,
			Survey.pad + eye + V(0, 0.09 * kick, 0.16 * kick),
			Survey.pad + look,
			if insert then 44 else 48,
			-0.025 + 0.011 * kick
		)
	elseif shot == 3 then
		-- A single fast move follows the sound along the cable. The empty
		-- mouth holds perfectly still while we wait for anything to answer.
		local u = if self.motion then math.clamp((t - 33.42) / 0.49, 0, 1) else 1
		local eye = V(0.05, 1.05, 24.8):Lerp(V(-1.85, 1.85, 12.4), u)
		self:frame(base, eye, V(-2.2, 2.98, 6.8), 60, -0.032 * (1 - u))
	elseif shot == 4 then
		-- The meter, listening hand and eyes share one frame. It only
		-- becomes an instrument close-up when its third lamp registers.
		if t < Beats.returned[3] or not self.motion then
			self:frame(base, V(-3.44, 4.28, 11.42), V(-3.75, 3.85, 5.93), 39)
		else
			self:frame(base, V(-2.16, 4.10, 9.38), V(-3.18, 3.57, 6.15), 42, -0.03)
		end
	elseif shot == 5 then
		self:frame(base, V(-2.1, 4.10, 13.5), V(-0.90, 3.35, 5.5), 47)
	elseif shot == 6 then
		-- Face the outside shoulder. Both the free hand and the steel tip
		-- must clear the avatar's hair during the long overhead anticipation.
		local kick = if self.motion then strikeKick(t, Beats.pick) else 0
		local size = self.camera.ViewportSize
		local tight = math.clamp((1.10 - size.X / math.max(1, size.Y)) / 0.64, 0, 1)
		local eye = V(-3.4, 3.12, 9.6):Lerp(V(-4.73, 2.98, 10.54), tight)
		local look = V(1.72, 3.65, 5.99):Lerp(V(1.98, 3.65, 6.08), tight)
		self:frame(base, eye + V(0, 0.10 * kick, 0.14 * kick), look, 65, 0.012 * kick)
	elseif shot == 7 then
		-- A graphic match to the ancient vein. The answering note motivates
		-- the cut into the stone, after a full beat of looking at inert rock.
		local answered = t >= Beats.answer and self.motion
		local eye = if answered then V(-0.70, 2.93, -1.34) else V(-1.22, 3.48, -2.65)
		self:frame(base, rock + eye, rock, if answered then 40 else 48, if answered then 0.071 else 0)
	else
		local u = if self.motion then ease(t, 44.65, Beats.arrival) else 1
		self:frame(base, V(6.9, 5.8, 12.8):Lerp(bridgeEye, u), V(-0.85, 1.92, 3.3):Lerp(bridgeLook, u), 54)
	end
end

-- Dolly back along the actual route from the mine sill to the landing compass.
-- Both the last rendered transform and the focus match the camera the player will own.
function Film:arrive(t)
	local handoff = self.handoff
	local gate = self.gateBase
	local u = ease(t, Beats.arrival, Beats.duration - 0.22)
	local landing = if handoff then handoff.landing else gate:PointToWorldSpace(V(0, 4, 87.75))
	if not self.arrival then
		self.arrival = Arrival.new(self.stage, gate, landing - V(0, 3.5, 0))
	end
	self.arrival:draw(t)

	local root = handoff and handoff.root
	local nearSpawn = root ~= nil and (root.Position - landing).Magnitude < 38
	local anchor = if nearSpawn then root.Position else landing
	local goal = if nearSpawn
		then handoff.view + (anchor - handoff.start)
		else CFrame.lookAt(anchor + V(0, 5, 13), anchor + V(0, 2, -5))
	local focus = if nearSpawn then handoff.focus + (anchor - handoff.start) else CF(anchor + V(0, 2, 0))
	local firstEye = gate:PointToWorldSpace(bridgeEye)
	local firstLook = gate:PointToWorldSpace(bridgeLook)
	local arc = math.sin(u * math.pi)
	local eye = firstEye:Lerp(goal.Position, u) + V(-4.3, 8.6, 0) * arc
	local look = firstLook:Lerp(focus.Position, u) + V(-1.2, 1.4, -5) * arc
	local endView = ease(t, 47.4, Beats.duration - 0.22)
	local rotation = CFrame.lookAt(eye, look).Rotation:Lerp(goal.Rotation, endView)
	if not self.motion or self.localPresent then
		-- A stationary landing shot lets the wave arrive without a long tracking move.
		eye, rotation, look = goal.Position, goal.Rotation, focus.Position
	end
	self.camera.CFrame = rotation + eye
	self.camera.Focus = CF(look):Lerp(focus, endView)
	local fov = if handoff then handoff.fov else 70
	self.camera.FieldOfView = 54 + (fov - 54) * (if self.motion and not self.localPresent then u else 1)
	-- A replay started underground returns to its original view during a short fade.
	return if nearSpawn or not handoff then 0 else ease(t, 48.54, 48.99)
end

function Film:draw(t, liveReady)
	if t < Beats.surface then
		Lighting.ClockTime = 7.34 + 1.86 * ease(t, 0.7, Beats.impact)
		local frameTime = t - (self.previousFlightFrame or t)
		self.history:prepare(math.clamp(math.ceil(650 * frameTime), 12, 68), t >= 10.10)
		self.previousFlightFrame = t
		self.strike:draw(t, self.base, self.motion)
		self:frame(self.base, Strike.frame(t, self.motion))
		return 1 - ease(t, 0.025, 0.22)
	end
	if self.strike then
		self.strike.root:Destroy()
		self.strike.shelf:Destroy()
		self.strike = nil
	end
	if t < Beats.present then
		local age = math.max(0, t - Beats.history)
		self.history:draw(age)
		local size = self.camera.ViewportSize
		local eye, look, fov, roll = Overlook.frame(age, size.X / math.max(1, size.Y), self.motion)
		if t < Beats.history then
			eye, look, fov, roll = Strike.surfaceFrame(t, self.motion, eye, look, fov, roll)
		end
		self:frame(self.historyBase, eye, look, fov, roll)
		if not self.sky then
			self.sky = IslandSky.new(self.stage, self.clock)
		end
		local refEye, refLook, refFov = Overlook.frame(0, size.X / math.max(1, size.Y), self.motion)
		self.sky:draw(
			t - Beats.history,
			self.camera,
			self.motion,
			self.historyBase * CFrame.lookAt(refEye, refLook),
			verticalFov(size, refFov)
		)
		return 0
	end
	if self.sky then
		self.sky:Destroy()
		self.sky = nil
	end
	Lighting.ClockTime = self.clock
	local shot = #presentCuts + 1
	for i, cut in presentCuts do
		if t < cut then
			shot = i
			break
		end
	end
	if self.modernShot ~= shot and t < Beats.arrival then
		self:mountPresent(liveReady or (self.modernBase ~= nil and not self.localPresent))
		self.modernShot = shot
	end
	if self.crew and t < 46.55 then
		self.crew:draw(t, self.modernBase, self.motion)
		self.survey:draw(t, self.modernBase)
	elseif self.crew then
		self.crew.root:Destroy()
		self.survey.root:Destroy()
		if self.history then
			self.history:Destroy()
			self.history = nil
		end
		self.crew, self.survey = nil, nil
	end
	if t >= Beats.arrival then
		return self:arrive(t)
	end
	self:present(t, shot)
	return 0
end

function Film:Destroy()
	if self.sky then
		self.sky:Destroy()
	end
	if self.arrival then
		self.arrival:Destroy()
	end
	if self.history then
		self.history:Destroy()
		self.history = nil
	end
end

return Film
