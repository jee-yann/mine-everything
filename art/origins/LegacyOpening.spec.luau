-- Studio RunScript check for camera continuity, slow streaming and private scenery.
local source = game.StarterPlayer.StarterPlayerScripts.Client.MineOrigins
local Beats, Film = require(source.Beats), require(source.Film)
local Exposure = require(source.Exposure)
local config = require(game.ReplicatedStorage.Shared.GameConfig)
local map = workspace.CitrineCove
local paths = map["Sand path and bridge"]
local portal = paths["Portal paving"]
local gate = portal.Position + Vector3.yAxis * (portal.Size.Y / 2 + 3.5)
local site = map:GetPivot().Position + Vector3.new(0, config.FloorY, (config.HallFront + config.HallBack) / 2)
local landing = paths.Landing.Position + Vector3.yAxis * 4
local initialClock = game.Lighting.ClockTime
local air = game.Lighting:FindFirstChildOfClass("Atmosphere")
local originalAir = air and { air.Color, air.Decay, air.Haze }
local initialMapSize = #map:GetDescendants()

local function check(motion, replay)
	local stage, shelf = Instance.new("Folder"), Instance.new("Folder")
	local camera = Instance.new("Camera")
	camera.Parent, stage.Parent = workspace, camera
	local root = Instance.new("Part")
	root.Anchored = true
	root.Position = if replay then site - Vector3.yAxis * 80 else landing
	local start = root.Position
	local focus = CFrame.new(start + Vector3.yAxis * 2)
	local view = CFrame.lookAt(start + Vector3.new(4, 7, 14), focus.Position)
	local film = Film.new(shelf, stage, camera, site, gate, motion, initialClock, nil, {
		root = root,
		start = start,
		landing = landing,
		view = view,
		focus = focus,
		fov = 67,
	})
	assert(film:draw(0, false) == 1)
	local screen = Instance.new("ScreenGui")
	local exposure = Exposure.new(screen, camera)
	film:draw(2.43, false)
	exposure:draw(2.43, film)
	assert(exposure.slip.Visible == motion and not exposure.plate.Visible)
	local core = film.strike.meteor:FindFirstChild("Starfall core")
	assert(core and core:IsA("Model"))
	local path = require(source.Strike).position
	local slow = (path(0.2) - path(0.1)).Magnitude
	local pass = (path(2.50) - path(2.40)).Magnitude
	assert(pass > 3 * slow and (path(Beats.impact) - path(6.26)).Magnitude > 5 * slow)
	film:draw(Beats.impact, false)
	-- Count submitted frames across a normal crossing and an overshoot. The
	-- final pre-contact interval establishes the display cadence for both cels.
	for _, rate in { 20, 30, 60, 144 } do
		local dt = 1 / rate
		exposure:draw(Beats.impact - 1.5 * dt, film)
		exposure:draw(Beats.impact - 0.5 * dt, film)
		local drawings = {}
		for i = 1, 6 do
			exposure:draw(Beats.impact + (i - 0.5) * dt, film)
			if exposure.plate.Visible then
				table.insert(drawings, exposure.lens.CFrame)
			end
		end
		local held = if rate > 90 then 2 else 1
		assert(#drawings == (if motion then 2 * held else 0), "unexpected number of displayed ink frames")
		if motion then
			assert(drawings[1] ~= drawings[held + 1], "compression and release must be distinct")
		end
	end
	assert(core:IsDescendantOf(film.strike.shelf) and film.strike.crown.Parent == film.strike.root)
	local clod = film.strike.ejecta[4].rock
	film:draw(6.87, false)
	local rising = clod:GetPivot().Position
	film:draw(7.25, false)
	local arc = clod:GetPivot().Position
	assert(arc.Y > rising.Y and (arc - rising).Magnitude > 10, "heavy slab lost launch velocity")
	local wave = film.strike.wave
	local first = wave.radius
	assert((camera.CFrame.Position - film.impactPoint).Magnitude > 300, "missing offshore master")
	film:draw(8.13, false)
	local falling = clod:GetPivot().Position
	assert(falling.Y < arc.Y and (falling - arc).Magnitude > 15, "slab stalled near the apex")
	film:draw(9.32, false)
	for _, ray in wave.rays do
		assert(wave.radius > ray.shore + 50, "wave stopped at the coastline")
	end
	assert(first < wave.rays[1].shore and clod.Parent == film.strike.shelf)
	film:draw(9.48, false)
	assert((camera.CFrame.Position - film.impactPoint).Magnitude < 45, "missing cut back to the fault")
	local fault = film.strike.fissure
	film:draw(9.60, false)
	assert(fault.lamp.Brightness > 0.1 and not core:IsDescendantOf(stage), "light escapes the buried fault")
	film:draw(11.75, false)
	for _, path in fault.lightPaths do
		assert(path.violet.Transparency > 0.98, "fissure must seal")
	end
	assert((film.historyBase.Position - film.base.Position).Magnitude > 7000, "separate the two surface sets")
	film:draw(Beats.surface, false)
	assert(not core.Parent and not film.history.root:FindFirstChild("Starfall core", true), "closed impact site")
	film:draw(Beats.history - 0.001, false)
	local crater = camera.CFrame
	assert(film:draw(Beats.history, false) == 0)
	assert((crater.Position - camera.CFrame.Position).Magnitude < 0.15, "cut drifted off the crater")
	assert(film.history.root.Parent == stage)
	local sky = film.sky
	local changes, previous = 0, -1
	local sawSun, sawMoon = false, false
	for n = 0, 126 do
		local age = n / 8
		film:draw(Beats.history + age, false)
		local count = #film.history.root:GetChildren()
		if count ~= previous then
			changes += 1
		end
		previous = count
		sawSun = sawSun or sky.sun.Transparency < 0.1
		sawMoon = sawMoon or sky.face.ImageTransparency < 0.1
		if n == 46 then
			local boat = film.history.work.hull
			local firstPose = boat:GetPivot()
			film:draw(Beats.history + age + 0.02, false)
			assert(boat:GetPivot():FuzzyEq(firstPose, 0.001), "boat drifted during a construction exposure")
			film:draw(Beats.history + age + 0.26, false)
			assert(not boat:GetPivot():FuzzyEq(firstPose, 0.001), "boat failed to jump to its next position")
		end
	end
	assert(changes >= 36 and sawSun and (not motion or sawMoon), "construction exposures and orbital light")
	film:draw(Beats.present - 0.001, false)
	local historicalView = camera.CFrame
	film:draw(Beats.present, false)
	assert(film.localPresent and film.history.root.Parent == stage, "missing finished local cove")
	assert((historicalView.Position - camera.CFrame.Position).Magnitude < 0.15, "jump at settlement match")
	film:draw(Beats.present + 0.5, true)
	assert(film.localPresent, "entrance changed halfway through a shot")
	film:draw(31.71, true)
	assert(not film.localPresent and not film.history, "ready entrance missed the next cut")
	for _, t in { 33.4, 35.7, 37.4, 39.3 } do
		assert(film:draw(t, true) == 0)
	end
	film:draw(40.90, true)
	local raised = film.crew.pickTip
	film:draw(41.30, true)
	assert((film.crew.pickTip - raised).Magnitude < 0.001, "pick holds at the top of the swing")
	film:draw(Beats.pick, true)
	local contact = film.modernBase * Vector3.new(0.17, 1.81, 4.79)
	assert((film.crew.pickTip - contact).Magnitude < 0.001, "pick hits the exposed stone on the strike")
	for _, t in { Beats.answer, 44.4, Beats.arrival, 47.7 } do
		assert(film:draw(t, true) == 0)
	end
	if replay then
		assert(film:draw(Beats.duration, true) == 1, "distant replay must cover the camera restore")
	else
		for _, t in { Beats.duration - 0.2, Beats.duration } do
			assert(film:draw(t, true) == 0)
			assert(camera.CFrame:FuzzyEq(view, 0.0002), "last frame differs from the playable camera")
			assert(camera.Focus:FuzzyEq(focus, 0.0002) and math.abs(camera.FieldOfView - 67) < 0.0002)
		end
	end
	assert(root.Position == start and #map:GetDescendants() == initialMapSize)
	if originalAir then
		assert(air.Color == originalAir[1] and air.Decay == originalAir[2] and air.Haze == originalAir[3])
	end
	film:Destroy()
	exposure:Destroy()
	assert(not camera:FindFirstChild("Starfall exposure"))
	screen:Destroy()
	camera:Destroy()
	shelf:Destroy()
	root:Destroy()
end

check(true, false)
check(false, false)
check(true, true)
game.Lighting.ClockTime = initialClock
print("MINING_ORIGINS_TESTS_PASSED")
