-- Run against the built place with Studio --task RunScript.
local source = game.StarterPlayer.StarterPlayerScripts.Client.Starfall
local Film = require(source.Film)
local clock = require(source.Timeline)
local sheet = require(source.ExposureSheet)
local edit = require(source.ImpactEdit)
local nightLook = require(source.NightLook)
local lighting = game.Lighting
local landing = workspace.CitrineCove["Sand path and bridge"].Landing.Position + Vector3.yAxis * 4
local mapSize = #workspace.CitrineCove:GetDescendants()
-- Underground replays can use the private copy of today's harbor while the live map streams.
for _, name in {"Spring run", "Canal step", "Roof strut", "Loading bin", "Wagon unload platform", "Wharf step", "Planked rail crossing"} do
	local live = assert(workspace.CitrineCove:FindFirstChild(name, true), name)
	local found = false
	for _, part in source.CoveReplay:GetDescendants() do
		if part:IsA("BasePart") and part.Name == name and (part.Position - live.Position).Magnitude < 0.02 then
			found = true
			break
		end
	end
	assert(found, "the replay harbor differs from the playable map at " .. name)
end
local hour, exposure, color, haze =
	lighting.ClockTime, lighting.ExposureCompensation, lighting.SeaAir.Color, lighting.SeaAir.Haze
local saved = {}
local originalSky = lighting:FindFirstChildOfClass("Sky")
local bodies = originalSky and originalSky.CelestialBodiesShown
local moonSize = originalSky and originalSky.MoonAngularSize
for _, obj in { lighting, lighting.SeaAir } do
	local properties = if obj == lighting
		then {
			"Ambient",
			"OutdoorAmbient",
			"Brightness",
			"ColorShift_Top",
			"ColorShift_Bottom",
			"GeographicLatitude",
			"ShadowSoftness",
			"EnvironmentDiffuseScale",
			"EnvironmentSpecularScale",
		}
		else { "Offset", "Density", "Decay", "Glare" }
	for _, name in properties do
		table.insert(saved, { obj, name, obj[name] })
	end
end

for picture = 0, sheet.frames.duration do
	local seconds = picture / sheet.fps
	assert(sheet.frameAt(seconds) == picture and sheet.frameAt(seconds + 0.95 / sheet.fps) == picture)
	assert(math.abs(sheet.frameForScene(sheet.sceneTime(picture)) - picture) < 1e-6, "picture/scene registration")
end
assert(sheet.fps == 24 and sheet.frames.breaker - sheet.frames.contact == 84)
for _, hz in { 24, 30, 60, 144 } do
	local last = -1
	for refresh = 0, math.ceil(Film.duration * hz) do
		local frame = sheet.frameAt(refresh / hz)
		assert(frame == last or frame == last + 1, "missed exposure at " .. hz .. " Hz")
		last = frame
	end
	assert(last == sheet.frames.duration)
end

local function fixture(remote)
	local char = Instance.new("Model")
	char.Name = "Local player"
	local function body(name, delta, size)
		local p = Instance.new("Part")
		p.Name, p.Anchored, p.Size = name, true, size
		p.Position = landing + delta - (if remote then Vector3.yAxis * 94 else Vector3.zero)
		p.Parent = char
		return p
	end
	local root = body("HumanoidRootPart", Vector3.zero, Vector3.new(2, 2, 1))
	body("Head", Vector3.yAxis * 1.55, Vector3.new(2, 1, 1))
	body(if remote then "Left Arm" else "LeftHand", Vector3.new(-1.3, -0.5, -0.2), Vector3.one)
	local accessory = Instance.new("Accessory")
	accessory.Name, accessory.Parent = "Player's own hat", char
	local sparkles = Instance.new("Sparkles")
	sparkles.Name, sparkles.Parent = "Hat glints", root
	local ribbon = Instance.new("Trail")
	ribbon.Name, ribbon.Parent = "Prism Ribbon", root
	char.PrimaryPart, char.Parent = root, workspace
	return char, root
end

local function check(motion, live, remote)
	local cam, screen, stage = Instance.new("Camera"), Instance.new("ScreenGui"), Instance.new("Folder")
	cam.Parent, stage.Parent = workspace, cam
	local char, root = fixture(remote)
	local start = root.CFrame
	local focus = CFrame.new(root.Position + Vector3.yAxis * 1.5)
	local view = CFrame.lookAt(root.Position + Vector3.new(4, 6, 14), focus.Position)
	local h = { landing = landing, root = root, view = view, focus = focus, fov = 69 }
	local film = Film.new(stage, screen, cam, h, motion)
	film:draw(0, false)
	local star = film.tide.glint:GetPivot().Position
	film:draw(1.4, false)
	assert((film.tide.glint:GetPivot().Position - star).Magnitude > 60, "shooting star must travel")
	assert(film.tide.root.Parent == stage and film.island.set.Parent == stage)
	assert(not film.tide.glint:FindFirstChildWhichIsA("LayerCollector", true)
		and not film.tide.glint:FindFirstChildWhichIsA("Decal", true), "distant meteor must have a volumetric head")
	local previousWidth, dipped, sawChip = nil, false, false
	local firstPose, lastPose
	for _, picture in { 0, 5, 12, 18, 27, 38, 45, 53 } do
		film:expose(picture, false)
		local tide = film.tide
		local pose = tide.glint:GetPivot()
		firstPose, lastPose = firstPose or pose, pose
		local nodes = tide.strands[1]
		assert((nodes[1].at.WorldPosition - pose.Position).Magnitude < 0.02
			and (pose.Position - nodes[#nodes].at.WorldPosition):Dot(pose.RightVector) > 12,
			"the bright train must stay attached to the falling body and trail its direction of travel")
		local width = tide.core.Size.Y
		dipped = dipped or (previousWidth ~= nil and width < previousWidth - 0.015)
		previousWidth = width
		for _, chip in tide.flakes do sawChip = sawChip or chip.Transparency < 0.9 end
	end
	assert(dipped == motion and sawChip == motion, "reduced motion must keep a steady approach without flicker or shedding")
	assert(firstPose.UpVector:Dot(lastPose.UpVector) < 0.92, "the mineral must rotate through the approach")
	film:draw(2.39, false)
	assert(not film.tide.root.Parent)
	local track = film.impact.position
	local direction = (track(clock.contact) - track(clock.entry)).Unit
	local last = track(clock.entry)
	for picture = sheet.frames.entry + 1, sheet.frames.contact do
		local p = track(sheet.sceneTime(picture), picture)
		local leg = p - last
		assert(leg.Magnitude > 1.3 and leg.Unit:Dot(direction) > 0.999, "meteor stalled or left its fall line")
		last = p
	end
	if motion then
		local lastView
		for picture = sheet.frames.crystal, sheet.frames.coast - 1 do
			local t = sheet.sceneTime(picture)
			local eye, aim, _, roll = film.impact:camera(t, picture)
			local view = CFrame.lookAt(eye, aim) * CFrame.Angles(0, 0, roll)
			if lastView then
				assert(lastView.LookVector:Dot(view.LookVector) > 0.95, "cut inside the turn behind the meteor")
			end
			lastView = view
		end
		local t = sheet.sceneTime(sheet.frames.coast - 1)
		local lastStar = track(t)
		assert((lastStar - lastView.Position):Dot(direction) > 20, "the chase must clear the tail")
		assert(
			lastView.LookVector:Dot((track(clock.contact) - lastView.Position).Unit) > 0.89,
			"the island must be ahead of the chase camera"
		)
	end
	film:expose(sheet.frames.coast - 1, false)
	assert(film.daylight.lunar.chaseHorizon.Parent == stage, "missing far water in the aerial chase")
	assert(lighting:GetSunDirection().Y < 0, "the visible sky in the flight must remain night on low graphics")
	for picture = sheet.frames.coast, sheet.frames.terminal - 1 do
		film:expose(picture, false)
		assert(
			not film.impact.shell.Parent and not film.impact.entry.root.Parent and not film.illumination.root.Parent,
			"meteor, wake or approach light appeared early in the wide"
		)
	end
	local cold = lighting.ExposureCompensation
	assert(
		not film.daylight.root:FindFirstChild("Moon", true) and film.daylight.sky.MoonAngularSize == 0,
		"the offshore light must remain outside the picture"
	)
	assert(film.daylight.lunar.root.Parent == stage and not film.daylight.sky.CelestialBodiesShown, "midnight coast")
	assert(lighting.Ambient.B > lighting.Ambient.R and lighting.ShadowSoftness < 0.25)
	assert(film.daylight.lunar.beams[1].light.Shadows and lighting.Ambient.R < 0.2, "crisp shadows in the wide")
	local lunar = film.daylight.lunar
	local sunward = lunar.relief:FindFirstChild("LunarGrass")
	local shade = lunar.relief:FindFirstChild("Umbra")
	assert(
		lunar.relief.Parent == stage and lunar.aprons.Parent == stage and not lunar.chaseHorizon.Parent,
		"offshore lens lost the moonlit land or the matched horizon"
	)
	assert(sunward and shade and math.abs(sunward.Transparency - (1 - 0.70 * nightLook.RimStrength)) < 0.01,
		"ledge edges must follow the artist's rim strength")
	assert(shade.Transparency < 0.65 and math.abs(lighting.OutdoorAmbient.R - nightLook.ShadowFill.R) < 0.01,
		"the shadowed ground must take its open-sky fill from NightLook")
	local shadowSource = lighting:GetSunDirection()
	assert(shadowSource.Y > 0.1 and shadowSource.Y < 0.35, "the native key should graze the terraces")
	assert((-lunar.beams[1].mount.CFrame.LookVector):Dot(shadowSource) > 0.995,
		"the native and local keys must cast the tree shadows in the same direction")
	assert(lunar.beams[1].light.Brightness > 0 and lunar.beams[1].light.Brightness < 6,
		"the shelf spots should support the native key")
	assert(lunar.mistImages[1].image.ImageTransparency < 1, "missing moonlight in the mist")
	local fall = film.island.set:FindFirstChild("Falling water", true)
	assert(fall and fall.Color.B - fall.Color.R < 0.22, "the moonlit cascade should not glow cyan")
	local moonlitStone = lunar.tint[1]
	assert(moonlitStone and moonlitStone.part.Color ~= moonlitStone.day, "missing private night palette")
	local offshoreColor = moonlitStone.part.Color
	local previousHeat = cold
	local phone = { camera = { ViewportSize = Vector2.new(390, 844) }, motion = motion }
	function film:frame(...)
		Film.frame(self, ...)
		Film.frame(phone, ...)
	end
	for picture = sheet.frames.terminal, sheet.frames.contact - 1 do
		film:expose(picture, false)
		assert(film.impact.shell.Parent and film.impact.entry.root.Parent, "missing terminal streak")
		assert(lighting.ExposureCompensation > previousHeat + 0.02, "missing terminal light progression")
		previousHeat = lighting.ExposureCompensation
		local p = track(film.sceneTime, picture)
		local point = phone.camera.CFrame:PointToObjectSpace(film.base * p)
		local halfHeight = -point.Z * math.tan(math.rad(phone.camera.FieldOfView / 2))
		assert(
			math.abs(point.X) < 0.96 * halfHeight * 390 / 844 and math.abs(point.Y) < halfHeight,
			"terminal meteor cropped out of the portrait coast shot"
		)
		local nextPoint = track(sheet.sceneTime(picture + 1), picture + 1)
		assert((nextPoint - p).Magnitude > 75, "meteor too slow during its three wide exposures")
	end
	film.frame = nil
	assert(film.illumination.key.Brightness > 5 and film.illumination.root.Parent == stage, "projected light")
	assert(film.daylight.bloom.Enabled, "terminal bloom")
	local reflected = 0
	for _, w in film.illumination.waves do
		if w.part.Transparency < 0.9 then
			reflected += 1
		end
	end
	assert(reflected > 7, "missing reflection during descent")
	local water = film.illumination.receivers[1]
	assert(water and water.part.Color ~= water.base, "the surrounding sea must catch the trail")
	film:expose(sheet.frames.contact, false)
	assert(not film.impact.shell.Parent and not film.impact.entry.root.Parent, "meteor survived contact")
	assert(moonlitStone.part.Color == offshoreColor and lunar.aprons.Parent == stage,
		"terrain outside the flash must hold its night palette during contact")
	local sites = film.island.faults.sites
	local near, far = sites[1], sites[1]
	for _, v in sites do
		if v.cut < near.cut then
			near = v
		end
		if v.cut > far.cut then
			far = v
		end
	end
	assert(far.cut - near.cut > 0.7, "fracture sites need distinct arrivals")
	local innerSlab, outerSlab = near.pieces[1], far.pieces[1]
	film:draw(near.cut + innerSlab.delay + 0.30, false)
	assert(innerSlab.where == "in flight" and outerSlab.where == "rest", "ground lifted ahead of the travelling wave")
	film:draw(far.cut + outerSlab.delay + 0.30, false)
	assert(outerSlab.where == "in flight" and far.bed.Parent, "outer ledge must separate from its footing")
	film:expose(sheet.frames.match - 1, false)
	assert(water.part.Color == water.night, "water must return to moonlight when the fire reflection passes")
	assert(not lunar.relief.Parent and not lunar.aprons.Parent, "offshore lighting survived the cut to the crater")
	assert(moonlitStone.part.Color == moonlitStone.day and lunar.mistImages[1].image.ImageTransparency == 1,
		"the close fissure shot must release the offshore lighting")
	assert(
		outerSlab.where == "landed" and (outerSlab.rest.Position - outerSlab.target).Magnitude > 12,
		"missing lasting displacement"
	)
	-- The lens photographs the actual island. The two open color exposures
	-- precede ignition and the arrival of the pressure front respectively.
	local previousPose, previousMode, previousTip
	local wavePrints = 0
	local flash = film.impact.ignition
	for picture = 237, 354 do
		film:expose(picture, false)
		local transfer = edit.at(picture)
		local printed = (picture >= 240 and picture <= 252 and picture ~= 241)
			or picture == 321
			or picture == 322
			or (picture >= 324 and picture <= 328)
		assert((transfer ~= nil) == printed, "impact on wrong exposure " .. picture)
		local roller = edit.roller(picture)
		assert(roller == (if picture == 324 then 1 elseif picture == 325 then 2 else nil))
		if picture >= 321 and (printed or roller) then
			wavePrints += 1
		end
		if picture >= 240 and picture < sheet.frames.ignition then
			assert(
				film.impact.plume.hidden and not flash.light.Enabled and flash.ball.Transparency == 1,
				"plume before ignition"
			)
			assert(flash.glint.Transparency < 1, "missing contact spark before ignition")
		elseif picture == sheet.frames.ignition then
			assert(
				not film.impact.plume.hidden and flash.light.Enabled and flash.ball.Transparency < 1,
				"ignition missed its report"
			)
		end
		if picture == 253 or picture == sheet.frames.eruption or picture == 276 then
			local illumination = film.illumination
			local sourcePosition = illumination.lamp.Position
			assert(illumination.key.Shadows and illumination.key.Brightness > 1, "missing shadow source at the vent")
			local litBanks = 0
			for _, pool in illumination.pools do
				if pool.light.Enabled then
					litBanks += 1
					local bank = film.base * pool.shore
					local horizontal = Vector3.new(1, 0, 1)
					local fromFire = ((bank - sourcePosition) * horizontal).Unit
					local lightRay = (pool.mount.CFrame.LookVector * horizontal).Unit
					assert(pool.light.Shadows and fromFire:Dot(lightRay) > 0.98, "bank shadow points toward the vent")
				end
			end
			assert(litBanks == 2, "the blast should rake the two crater banks")
			for _, tile in illumination.receivers do
				if tile.part.Name == "Deep water" then
					assert(tile.part.Color.R - tile.night.R < 0.09, "the whole sea lit up with the fire reflection")
				end
			end
		end
		if motion then
			local lens = film.impact.lens
			assert(
				(flash.root.Parent ~= nil and flash.corona[1].beam.Enabled) == (picture == 246),
				"broken corona belongs to ignition"
			)
			assert(lens.exposure == transfer and lens.grade.Enabled == printed)
			if transfer then
				assert(lens.grade.Parent == cam and not film.daylight.grade.Enabled)
				assert(math.abs(lens.grade.Saturation - transfer.saturation) < 0.0001)
				assert(math.abs(lens.grade.Contrast - transfer.contrast) < 0.0001)
				assert(math.abs(lens.grade.Brightness - transfer.bias) < 0.0001)
				assert(
					transfer.pose ~= previousPose and transfer.mode ~= previousMode,
					"same picture action or optical mode on adjacent exposures"
				)
				if transfer.mode == "black" or transfer.mode == "white" then
					assert(math.abs(transfer.bias) == 1)
				elseif roller then
					assert(
						transfer.saturation > 0 and transfer.contrast < 1,
						"roller must preserve the fire and sea hues"
					)
				elseif transfer.mode == "ultraviolet" or transfer.mode == "ember" then
					assert(transfer.saturation > -0.35, "missing spectral separation on colored exposure")
					assert(transfer.contrast > 0.75, "colored action lost its printing contrast")
					if picture < sheet.frames.breaker - 3 then
						assert(flash.bounce[1].Enabled, "colored ignition did not reach the crater")
					else
						assert(film.impact.breaker.caustics[1].lamp.Enabled, "colored wave did not reach the coast")
					end
				elseif transfer.mode ~= "positive" and transfer.mode ~= "negative" then
					assert(transfer.saturation > -1 and transfer.saturation < -0.5)
				else
					assert(transfer.saturation == -1 and math.abs(transfer.contrast) >= 20)
				end
			end
			previousPose = if transfer then transfer.pose else nil
			previousMode = if transfer then transfer.mode else nil
			if picture >= sheet.frames.ignition and picture <= 252 then
				local tip = flash.rays[1].b.Position
				assert(not previousTip or (tip - previousTip).Magnitude > 3, "starburst ray repeated its world pose")
				previousTip = tip
				if picture == 246 then
					assert(
						flash.hatches[1].slash.Enabled and flash.corona[1].beam.Enabled,
						"broken contact corona did not print"
					)
				end
			end
			if picture >= 321 and picture <= 330 then
				assert(lens.roller.group.Visible == (roller ~= nil), "pressure drawing on the wrong exposure")
				if roller then
					assert(lens.roller.layers[roller].Visible and not lens.roller.layers[3 - roller].Visible)
					assert(
						lens.grade.Enabled and lens.grade.Saturation > 0 and not lens.blur.Enabled,
						"roller must reveal the full-color eruption"
					)
					assert(lens.roller.group.BackgroundTransparency == 1 and not film.impact.plume.hidden)
				end
				if picture == 323 then
					assert(
						not lens.blur.Enabled and not film.impact.breaker.flecks[1].stroke.Enabled,
						"filtered the clean offshore exposure"
					)
				end
			end
		else
			assert(not film.impact.lens and #flash.rays == 0 and #flash.hatches == 0)
		end
	end
	assert(wavePrints == 7, "the offshore front must use exactly seven printed exposures")
	film:expose(sheet.frames.ignition, false)
	local small = flash.ball.Size.X
	film:expose(252, false)
	assert(flash.root.Parent and flash.ball.Size.X > 4 * small, "the ignition must expand in world space")
	for _, picture in { 239, 240, 254, 269, 283 } do
		film:expose(picture, false)
		local wakeVisible = film.impact.wake.root.Parent == film.impact.root
		assert(wakeVisible == (picture >= 240 and picture < 283), "afterimage in the wrong exposure")
	end
	if motion then
		for _, picture in { 253, 329 } do
			film:expose(picture, false)
			local lens = film.impact.lens
			assert(
				not lens.grade.Enabled and lens.blur.Enabled and lens.blur.Size >= 16,
				"vision must soften on the return to color"
			)
		end
		film:expose(352, false)
		assert(not film.impact.lens.blur.Enabled, "blur survived the wave")
	end
	local r = film.impact.rocks[1]
	local apex = sheet.sceneTime(sheet.frames.ignition) + r.delay + r.velocity.Y / 64
	film:draw(apex, false)
	local peak = r.part:GetPivot().Position
	film:draw(apex + 0.18, false)
	assert(r.part:GetPivot().Y < peak.Y and (peak - r.part:GetPivot().Position).Magnitude > 0.85, "ejecta arc")
	local witness = film.base * clock.breakerEye
	for _, picture in { sheet.frames.coast, 229, 239, 240, 267, 302, 324, 340, 381 } do
		film:expose(picture, false)
		assert((cam.CFrame.Position - witness).Magnitude < 1.5, "changed observer around the collision")
	end
	film:expose(242, false)
	assert((cam.CFrame.Position - witness).Magnitude < 2, "camera jumped before ignition")
	film:expose(sheet.frames.ignition + 1, false)
	assert(((cam.CFrame.Position - witness).Magnitude > 4.5) == motion, "missing ignition recoil")
	film:expose(324, false)
	local before = cam.CFrame
	film:expose(327, false)
	assert(
		((before.Position - cam.CFrame.Position).Magnitude > 6) == motion,
		"directional recoil or reduced-motion hold"
	)
	local hit = cam.CFrame
	film:expose(327, false)
	assert(cam.CFrame == hit, "camera moved inside an exposure")
	film:expose(359, false)
	local aftershock = cam.CFrame
	film:expose(360, false)
	assert((not cam.CFrame:FuzzyEq(aftershock, 0.001)) == motion, "aftershock or reduced-motion hold")
	film:expose(383, false)
	assert((cam.CFrame.Position - witness).Magnitude < 0.01, "shore camera must settle before cutting inland")
	local era = sheet.frames
	film:expose(era.seam + 2, false)
	local rock = film.island.witnessPoint
	film:expose(era.match - 2, false)
	local previous = film.base:ToObjectSpace(cam.CFrame)
	film:expose(era.match - 1, false)
	local ancient = film.base:ToObjectSpace(cam.CFrame)
	local ancientRay = ancient:PointToObjectSpace(rock)
	local ash = lighting.SeaAir.Haze
	local navigation = workspace.CitrineCove["Shore market"]:FindFirstChild("Station name", true)
	local signageWasEnabled = navigation.Enabled
	assert(film.daylight.depth.Enabled and -ancientRay.Z > 4 and film.island.set.Parent == stage)
	assert(not film.island.set:FindFirstChild("Mine sign", true), "the modern portal appeared before the time cut")
	local modernBase = if live then film.live else film.base
	assert(film:expose(era.match, live) == 0, "the time jump must preserve the visible fork")
	assert(navigation.Enabled == (not live and signageWasEnabled), "live station labels obscure the architectural match")
	local modern = modernBase:ToObjectSpace(cam.CFrame)
	local step = modern.Position - ancient.Position
	assert((step - (ancient.Position - previous.Position)).Magnitude < 0.003 and (step.Magnitude > 0.02) == motion,
		"the camera must carry its lateral movement across both eras")
	assert((modern:PointToObjectSpace(rock) - ancientRay).Magnitude < 0.12 and ancient.UpVector:Dot(modern.UpVector) > 0.999,
		"the fork moved on the time cut")
	assert(ash > lighting.SeaAir.Haze + 0.8 and math.abs(lighting.ClockTime - hour) < 0.001,
		"cut from the ash-filled night to the playable world's daylight in one frame")
	assert(water.part.Color == water.base and water.part.Material == water.material, "the sea must release its impact lighting")
	film:expose(era.establish, not live)
	assert(film.matchLive == live)
	local boulevard = cam.CFrame
	film:expose(era.present - 1, live)
	assert(cam.CFrame == boulevard and (cam.Focus.Position - modernBase * Vector3.new(0, 39.3, 9.5)).Magnitude < 9,
		"hold the completed portal in its geography")
	assert(not film.illumination.root.Parent and not film.daylight.bloom.Enabled and not film.daylight.depth.Enabled
		and not film.daylight.rays.Enabled and not film.daylight.blur.Enabled, "ancient optics survived the wide")
	film:expose(era.present, live)
	assert(navigation.Enabled == signageWasEnabled, "station labels must return to their previous setting after the wide")
	local playerView = cam.CFrame
	assert(not film.broadcast.room and film.arrival.proof.model.Parent == stage, "introduce the miner in person first")
	film:expose(era.broadcast - 1, live)
	assert(cam.CFrame:FuzzyEq(playerView, 0.002), "hold the portrait while the miner moves into position")
	if remote then
		assert(film.arrival.copy and film.arrival.copy:FindFirstChild("Player's own hat"))
		local replayAt = if live then landing else landing + film.base.Position - film.live.Position
		assert((film.arrival.root.Position - replayAt).Magnitude < 0.02)
	else
		assert(film.arrival.copy:FindFirstChild("Player's own hat") and film.arrival.root ~= root and root.Transparency == 1, "the single dressed performer masks the live body")
	end
	assert(not film.arrival.root["Hat glints"].Enabled and not film.arrival.root["Prism Ribbon"].Enabled)
	local station = film.arrival.marker
	local cuts = sheet.frames
	local proof = film.arrival.proof
	local tool = film.arrival.assay
	film:expose(cuts.measure, live)
	assert(not station.invitation:IsDescendantOf(stage), "the commission must follow the trial")
	local tv = film.broadcast
	for _, cue in { { cuts.broadcast, "Bedroom", 1 }, { cuts.livingRoom, "Living room", 1 }, { cuts.computer, "Computer room", 3 } } do
		film:expose(cue[1] + 10, live)
		assert(tv.view.Visible and tv.shot == cue[2] and #tv.room.fans >= cue[3], "missing audience in " .. cue[2])
		assert(proof.model.Parent == stage, "the workbench must stay live in each receiver")
		for _, fan in tv.room.fans do
			assert(fan.rig.model:FindFirstChildOfClass("Humanoid") and fan.rig.head, "audience member lost its Roblox rig")
		end
		local lens, head = tv.camera.CFrame, tv.room.fans[1].rig.head.CFrame
		film:expose(cue[1] + 32, live)
		assert((tv.camera.CFrame ~= lens) == motion and (tv.room.fans[1].rig.head.CFrame ~= head) == motion,
			"the room camera and audience poses should respect reduced motion in " .. cue[2])
	end
	film:expose(cuts.measure, live)
	assert(not tv.view.Visible and not tv.bug.Visible, "clear the TV before the pick swing")
	local gem = proof.gem.WorldPosition
	local shut = proof.left.CFrame
	for picture = cuts.proofStrike - 4, cuts.proofStrike do film:expose(picture, live) end
	local glint = tool.tool:FindFirstChild("Steel afterimage", true)
	assert(glint and glint.Enabled == motion, "only the moving pick draws an arc")
	assert(((tool.tool:GetPivot() * tool.tip) - proof.seam.WorldPosition).Magnitude < 0.04, "pick missed the natural seam")
	film:expose(cuts.revealGem + 6, live)
	assert(not glint.Enabled, "steel afterimage still covering the emerald")
	assert((proof.left.Position - shut.Position).Magnitude > 0.35, "the fracture must open")
	assert((proof.gem.WorldPosition - gem).Magnitude < 0.001, "extract the crystal intact")
	film:expose(cuts.portrait + 12, live)
	assert(not station.invitation:IsDescendantOf(stage), "award was visible on the portrait")
	assert(film.portrait.root.Visible and film.portrait.subject.world:FindFirstChild(film.arrival.root.Parent.Name),
		"identity card must show this miner")
	assert(film.portrait.subject.world:FindFirstChild(tool.tool.Name), "portrait lost the shouldered pick")
	if motion then
		local function checkTracking(picture, label)
			film:expose(picture - 1, live)
			local before = cam.CFrame
			film:expose(picture, live)
			local at = cam.CFrame
			film:expose(picture + 1, live)
			local after = cam.CFrame
			local incoming, outgoing = at.Position - before.Position, after.Position - at.Position
			assert(incoming:Dot(outgoing) > 0, label .. " must keep moving through the edit")
			assert(math.max(incoming.Magnitude, outgoing.Magnitude) < 0.8 * film.arrival.unit,
				label .. " jumped between adjacent exposures")
			assert(before.LookVector:Dot(at.LookVector) > 0.94 and at.LookVector:Dot(after.LookVector) > 0.94,
				label .. " lost its sightline")
		end
		checkTracking(cuts.beacon, "dispatch pullback")
		checkTracking(cuts.autoStrike + 8 + 6, "camera following the beacon discharge")
	end
	film:expose(cuts.commission, live)
	assert(not proof.model.Parent and not film.portrait.root.Visible and station.invitation:IsDescendantOf(stage))
	local dispatch = station.model["Signed field dispatch"]["Guild commission"]
	assert(dispatch:FindFirstChild(char.Name) and dispatch:FindFirstChild("TO FIND STARFALL"), "the miners chose the player")
	assert(not film.arrival:requestStrike(cuts.prompt - 1))
	local offered = cuts.prompt + 14
	film:expose(offered, live)
	assert(not station.signalPosition and not station.signal.root.Parent and station.route.Parent == stage,
		"the vanes must be physically present and cold until the pick lands")
	assert(film.arrival:requestStrike(offered) and not film.arrival:requestStrike(offered + 1), "one strike per expedition")
	film:expose(offered + 8, live)
	assert(film.arrival.contactFrame == offered + 8 and tool.chips.Parent == stage)
	assert(((tool.tool:GetPivot() * tool.tip) - station.core.WorldPosition).Magnitude < 0.035, "pick must hit the route seal")
	assert((station.signalPosition - station.core.WorldPosition).Magnitude < 0.035, "the live contact must start the signal at the struck facet")
	assert(station.signal.sparks[1].ray.Enabled == motion, "reduced motion must suppress flying strike sparks")
	-- The same distance of ground lights up on every exposure for either an
	-- early tap or the automatic one. Sparse decorations along the route must
	-- never act as evenly timed stops for the signal.
	local signal = station.signal
	local contact = film.arrival.contactFrame
	for _, hit in { cuts.prompt + 8, contact, cuts.autoStrike + 8 } do
		local pace = signal:distance(hit + 1, hit)
		for f = hit + 2, math.floor(signal:time(signal.sill, hit)) do
			local step = (signal:sample(f, hit) - signal:sample(f - 1, hit)).Magnitude
			assert(step > pace * 0.76 and step < pace * 1.035, "the light must carry its speed through each bend")
		end
		assert(signal:time(signal.lip, hit) == cuts.lode - 12, "the guide must dive before the lens")
	end
	local lastVane = #station.runnels + 2
	local vaneFrame = signal:time(lastVane, contact)
	film:expose(math.ceil(vaneFrame), live)
	assert(station.runnels[6].strokes[1].Material == Enum.Material.Neon, "the signal lights the far vane as it passes")
	assert((signal.world * signal:sample(vaneFrame, contact) - station.runnels[6].at.WorldPosition).Magnitude < 0.34,
		"the wake must cross the sixth copper inlay")
	assert(station.signal.trail[2].wire.Enabled == motion, "reduced motion must retain only the calm ground trace")
	local bearer = require(source.GalleryRun).origin(film.arrival)
	local sillFrame = signal:time(signal.sill, contact)
	assert((signal.world * signal:sample(sillFrame, contact) - bearer - Vector3.new(0.14, 1.29, -0.42)).Magnitude < 0.035,
		"the energy head must cross the actual mine sill on the approach")
	local run = require(source.GalleryRun)
	local origin = run.origin(film.arrival)
	local mouth = origin + run.mouth
	if motion then
		local tall = {
			handoff = { landing = origin + Vector3.new(0, 4.96, 89), origin = origin },
			mineBearing = CFrame.new(origin + Vector3.new(0, 4.96, 89)), unit = 1.85,
			marker = require(source.ExpeditionMarker).new("Tall miner"), stage = stage,
		}
		tall.marker.signal.crystalContact = film.lode.contactPoint
		tall.marker:place(tall)
		local first, lastZ = cuts.prompt + 8 + 4, math.huge
		for frame = first, cuts.mineRun do
			local eye = run.gallery(tall, frame, first, true)
			assert(eye.Z < lastZ, "earliest strike must keep travelling towards the arch with a tall avatar")
			lastZ = eye.Z
		end
		tall.marker:Destroy()
		for _, hit in { cuts.prompt + 8, contact, cuts.autoStrike + 8 } do
			local gate = signal:time(signal.sill, hit)
			local eyeAtGate = run.gallery(film.arrival, gate, hit + 4, true) - origin
			local before = run.gallery(film.arrival, gate - 12, hit + 4, true)
			local after = run.gallery(film.arrival, gate + 1, hit + 4, true)
			assert(eyeAtGate.Z > 7 and (after - origin - eyeAtGate).Magnitude < (origin + eyeAtGate - before).Magnitude / 12,
				"camera must coast outside the arch while the light goes through first")
			for f = hit + 6, run.gemFrame do
				local eye, aim, head
				if f < cuts.lode then
					eye, aim = run.gallery(film.arrival, f, hit + 4, true)
					head = origin + signal:sample(f, hit)
				else
					eye, aim = run.chamber(f, true, false)
					local position = signal:sample(f, hit)
					head = run.shaft:PointToObjectSpace(position)
				end
				local travel = head - eye
				local target = if f < cuts.lode then origin + run.shaft * film.lode.contactPoint else film.lode.contactPoint
				assert((head - target).Magnitude < (eye - target).Magnitude,
					string.format("camera passed the guide en route to Starfall at %d", f))
				assert(travel.Magnitude > 1 and travel.Unit:Dot((aim - eye).Unit) > 0.92,
					string.format("guide left the sightline at frame %d, strike %d", f, hit))
				if f < gate then
					assert(head.Z <= eye.Z + 0.05, "camera passed the guide on the bridge")
				end
			end
		end
	end
	film:expose(cuts.mineRun + 18, live)
	local inHall = cam.CFrame.Position - origin
	assert(math.abs(inHall.X) < 25 and inHall.Y > 1 and inHall.Y < 10 and inHall.Z < -6 and inHall.Z > -60,
		"lens must enter the actual working gallery above its playable dig floor")
	local photographed = {}
	for item, original in film.lode.hidden do
		assert(item.LocalTransparencyModifier == 1, "excavation must clear the photographed column")
		photographed[item] = original
	end
	assert(next(photographed), "the photographed shaft did not open in the live or replica floor")
	film:expose(cuts.lode - 2, live)
	local prev = cam.CFrame.Position
	film:expose(cuts.lode - 1, live)
	local endRun = (cam.CFrame.Position - prev).Magnitude
	if motion then
		assert((cam.CFrame.Position - mouth).Magnitude < 1.5 and cam.CFrame.LookVector.Y < -0.97,
			"the dive must pass through the floor opening")
	else
		assert(endRun < 0.001, "reduced motion must hold the gallery view")
	end
	local lip = film.lode.model:GetPivot()
	local approach = lip:ToObjectSpace(cam.CFrame)
	film:expose(cuts.lode, live)
	local chamber = film.lode.model:GetPivot():ToObjectSpace(cam.CFrame)
	local deepSignal = film.lode.at:PointToObjectSpace(station.signalPosition)
	assert((deepSignal - Vector3.new(0.30, 1.02, 16.11)).Magnitude < 0.035, "the guide must stay in sight down the shaft")
	for item, original in photographed do
		assert(item.LocalTransparencyModifier == original, "transition must restore each floor brick")
	end
	if motion then
		local stride = (chamber.Position - approach.Position).Magnitude
		assert(math.abs(stride - endRun) < 0.14, "lens lost its velocity in the throat")
		assert(approach.LookVector:Dot(chamber.LookVector) > 0.99, "gallery and crystal must share the sightline")
		assert(approach.UpVector:Dot(chamber.UpVector) > 0.99, "the horizon rolled at the shaft match")
	end
	film:expose(run.gemFrame - 1, live)
	assert(not film.lode.spill.Enabled and not film.lode.arms[1].Enabled, "gem lit before the guide arrived")
	film:expose(run.gemFrame, live)
	assert((station.signalPosition - film.lode.at * film.lode.contactPoint).Magnitude < 0.035 and film.lode.spill.Enabled,
		"the guide must light the actual crystal face on contact")
	film:expose(cuts.lode + 32, live)
	assert(film.lode.model.Parent == stage and film.lode.arms[1].Enabled, "the underground lode catches light")
	local oldEye = cam.CFrame
	film:expose(cuts.challenge - 1, live)
	assert(not motion or (oldEye.Position - cam.CFrame.Position).Magnitude > 0.4, "the underground camera stalled")
	film:expose(cuts.challenge, live)
	assert(not film.lode.model.Parent)
	local black = film:draw(clock.duration, live)
	if remote then
		assert(black > 0.99)
	else
		assert(
			cam.CFrame:FuzzyEq(view, 0.0002)
				and cam.Focus:FuzzyEq(focus, 0.0002)
				and math.abs(cam.FieldOfView - 69) < 0.0002
		)
		h.playable = { view = view * CFrame.new(0, -1.3, -2.1), focus = focus + Vector3.yAxis, fov = 64 }
		film:landingFrame(clock.duration)
		assert(
			cam.CFrame:FuzzyEq(h.playable.view, 0.0002)
				and cam.Focus:FuzzyEq(h.playable.focus, 0.0002)
				and math.abs(cam.FieldOfView - 64) < 0.0002
		)
	end
	assert(root.CFrame == start and #workspace.CitrineCove:GetDescendants() == mapSize)
	-- Repeat the release with sky, local lamps and optics actively changed.
	if not live then
		film:draw(if motion then 4.56 else 7.62, false)
	else
		film:expose(cuts.mineRun + 18, true)
		assert(next(film.lode.hidden), "skip fixture must start above an open shaft")
	end
	film:Destroy()
	if live then
		for item, original in photographed do
			assert(item.LocalTransparencyModifier == original, "skipping must restore the original dig cell")
		end
	end
	assert(root["Hat glints"].TimeScale == 1 and root["Prism Ribbon"].Enabled, "avatar cosmetics must resume")
	assert(#stage:GetChildren() == 0 and #screen:GetChildren() == 0, "private assets survived release")
	for _, item in saved do
		assert(item[1][item[2]] == item[3], "lighting release: " .. item[2])
	end
	assert(
		not cam:FindFirstChildWhichIsA("PostEffect") and lighting:FindFirstChildOfClass("Sky") == originalSky,
		"unreleased private optics or sky"
	)
	if originalSky then
		assert(originalSky.CelestialBodiesShown == bodies)
		assert(originalSky.MoonAngularSize == moonSize, "native moon was not restored on exit")
	end
	assert(
		math.abs(lighting.ClockTime - hour) < 0.001
			and lighting.ExposureCompensation == exposure
			and lighting.SeaAir.Color == color
			and lighting.SeaAir.Haze == haze
	)
	char:Destroy()
	screen:Destroy()
	cam:Destroy()
end
-- Exercise Roblox's own skeletons with two attached items, including a
-- tall headpiece and a scaled miner photographed at their surface size.
local function nativeAvatar(kind, size)
	local avatar = require(source.CinematicAvatar)
	local model = game:GetObjects("rbxasset://models/Thumbnails/Mannequins/" .. kind .. ".rbxm")[1]
	assert(model and model:FindFirstChild("Head") and model:FindFirstChild("HumanoidRootPart"), kind)
	local root, head = model.HumanoidRootPart, model.Head
	for i = 1, 2 do
		local accessory = Instance.new("Accessory")
		accessory.Name = "Equipped " .. i
		local handle = Instance.new("Part")
		handle.Name, handle.Size = "Handle", Vector3.new(1, 2, 1)
		handle.CFrame = head.CFrame * CFrame.new(i * 0.2, i, 0)
		local joint = Instance.new("Weld")
		joint.Part0, joint.Part1 = head, handle
		joint.C0 = head.CFrame:ToObjectSpace(handle.CFrame)
		joint.Parent, handle.Parent, accessory.Parent = handle, accessory, model
	end
	local wearer = {Character = model}
	function wearer:GetAttribute(name) return model:GetAttribute(name) end
	function wearer:GetAttributeChangedSignal(name) return model:GetAttributeChangedSignal(name) end
	require(game.ServerScriptService.Server.Pickaxe).equip(wearer,model)
	model:ScaleTo(size * 0.65)
	model:SetAttribute("SurfaceScale", size)
	model.Parent = workspace
	local before = root.CFrame
	local rig = avatar.new(model)
	assert(math.abs(rig.model:GetScale() - size) < 0.001 and rig.channels.Neck and rig.channels.LeftShoulder, kind .. " sockets")
	rig:show(workspace)
	local rest = CFrame.new(40, 85, 30)
	rig:place(rest)
	local copyHead = rig.model.Head
	local baseHead = copyHead.CFrame
	local hat = rig.model["Equipped 2"].Handle
	local grip = baseHead:ToObjectSpace(hat.CFrame)
	rig:turn("Neck", -12, 29, 3)
	rig:turn("LeftShoulder", 17, -4, 12)
	rig:place(rest)
	assert(baseHead.LookVector:Dot(copyHead.CFrame.LookVector) < 0.95, kind .. " expressive head")
	assert(grip:FuzzyEq(copyHead.CFrame:ToObjectSpace(hat.CFrame), 0.0002), kind .. " accessory moved off socket")
	for _, part in rig.parts do assert(part.Anchored and not part.CanCollide) end
	assert(root.CFrame == before and math.abs(model:GetScale() - size * 0.65) < 0.001)
	local reveal = avatar.mask(model)
	local late = Instance.new("Part")
	late.Transparency = 0.35
	late.Parent = model
	task.wait()
	assert(late.Transparency == 1 and head.Transparency == 1)
	reveal()
	assert(math.abs(late.Transparency - 0.35) < 0.001 and head.Transparency < 1)
	rig:destroy()
	local cam = Instance.new("Camera")
	local stage = Instance.new("Folder")
	cam.Parent, stage.Parent = workspace, cam
	local site = root.Position + Vector3.new(0, 100, 0)
	local arrival = require(source.Arrival).new(stage, {root = root, landing = site, entrance = site - Vector3.zAxis * 85})
	local gripRelation
	local F = sheet.frames
	for _, frame in {F.present, F.proofStrike - 1, F.proofStrike, F.portrait, F.prompt, F.prompt + 8, F.challenge} do
		if frame == F.prompt then assert(arrival:requestStrike(frame)) end
		arrival:draw(sheet.sceneTime(frame), frame)
		assert(arrival.remote and arrival.copy["Equipped 2"].Handle and root.CFrame == before, kind .. " underground appearance")
		local pick = arrival.copy["Harbor pick"]
		local grip = pick:FindFirstChild("Grip", true)
		local hand = grip.Part0
		assert((pick["Grip tape"].Position - hand.RightGripAttachment.WorldPosition).Magnitude < 0.001,
			kind .. " wrapped handle missed the palm")
		if kind == "R6" then
			-- The complete steel crosspiece must clear the front of the
			-- rectangular forearm, including in the raised and contact poses.
			local steel = pick.Steel
			local steelCenter = hand.CFrame:PointToObjectSpace(steel.Position)
			assert(steelCenter.Z + steel.Size.Magnitude * 0.5 < -hand.Size.Z * 0.5,
				"R6 pick head buried in the forearm")
		end
		local relation = grip.Part0.CFrame:ToObjectSpace(grip.Part1.CFrame)
		gripRelation = gripRelation or relation
		assert(relation:FuzzyEq(gripRelation,0.0003),kind .. " pick moved in hand")
		if frame == F.proofStrike or frame == F.prompt + 8 then
			local goal = if frame == F.proofStrike then arrival.proof.seam else arrival.marker.core
			local tip = arrival.assay.tool:GetPivot() * arrival.assay.tip
			assert((tip - goal.WorldPosition).Magnitude < 0.04, kind .. " missed the pictured contact")
		end
	end
	arrival:Destroy()
	cam:Destroy()
	model:Destroy()
end
nativeAvatar("R6", 0.85)
nativeAvatar("R15", 1.35)
check(true, true, false)
check(false, false, false)
check(true, false, true)
print("MINING_ORIGINS_TESTS_PASSED")
