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
for _, name in {"Spring run", "Canal step", "Roof strut", "Adit lintel", "Headframe deck", "Lookout deck", "Shop sign", "Beacon gallery", "Mine sign"} do
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
	-- Second half. One crane over the rim finds the star where it landed, its
	-- light goes, and the present opens already moving on the offshore line.
	local F = sheet.frames
	assert(F.aftermath == 384, "the approved opening ends on frame 383")
	film:expose(383, live)
	assert(film.deposit.root.Parent == nil and film.island.hot.Parent ~= nil, "the opening keeps its own outcrop")
	film:expose(F.aftermath, live)
	assert(film.deposit.root.Parent and film.island.hot.Parent == nil)
	local bowl = film.base * Vector3.new(0, 26, -32)
	for _, part in film.deposit.root:GetChildren() do
		assert(((part.Position - bowl) * Vector3.new(1, 0, 1)).Magnitude < 12, "the deposit belongs to the point of impact")
	end
	local craneStart = cam.CFrame.Position
	film:expose(F.seam - 1, live)
	assert((craneStart.Y - cam.CFrame.Position.Y > 25) == motion, "the crane descends into the crater")
	local lit = film.deposit.lamps[1].light.Brightness
	film:expose(F.dark - 2, live)
	assert(lit > 1 and film.deposit.lamps[1].light.Brightness < 0.1, "the star's light goes before the cut")
	assert(film:expose(F.dark + 3, live) == 1, "time passes in the dark")
	local navigation = workspace.CitrineCove["Shore market"]:FindFirstChild("Station name", true)
	local signageWasEnabled = navigation.Enabled
	-- Every travelling shot is travelling on its first and last exposures.
	local function underWay(a, b, label)
		for _, frame in { a, b - 2 } do
			film:expose(frame, live)
			local from = cam.CFrame.Position
			film:expose(frame + 1, live)
			local step = (cam.CFrame.Position - from).Magnitude
			assert((step > 0.004) == motion, label .. " is not moving at " .. frame .. " " .. step)
		end
	end
	underWay(F.aftermath, F.seam, "crater crane")
	underWay(F.seam, F.dark, "crater floor")
	underWay(F.match, F.boulevard, "the island today")
	underWay(F.boulevard, F.dig, "the mine entrance")
	underWay(F.dig, F.crack, "the working face")
	underWay(F.outside, F.living, "the doorway")
	underWay(F.living, F.livingReverse, "the living room")
	underWay(F.livingReverse, F.witness, "the two faces")
	underWay(F.witness, F.enter, "the plaza")
	underWay(F.enter, F.strike, "the gallery")
	film:expose(F.match, live)
	local site = if live then film.live else film.base
	assert((site:PointToObjectSpace(cam.CFrame.Position) - clock.breakerEye).Magnitude < 45, "the present opens on the offshore line")
	assert(film.matchLive == live and math.abs(lighting.ClockTime - hour) < 0.001)
	assert(navigation.Enabled == (not live and signageWasEnabled), "station labels stay out of the wide")
	assert(water.part.Color == water.base and water.part.Material == water.material, "the sea must release its impact lighting")
	if not remote then
		assert(root.Transparency == 1 and not film.arrival.copy, "the player is not standing on the compass yet")
	end

	-- The miner. The visible pick is the one welded into their glove.
	local mine = film.mine
	local hand, handle = mine.rig.model.RightHand, mine.handle
	local seat
	for picture = F.dig, F.outside - 1, 3 do
		film:expose(picture, live)
		local relation = hand.CFrame:ToObjectSpace(handle.CFrame)
		seat = seat or relation
		assert(relation:FuzzyEq(seat, 0.0005), "the miner's pick left the hand at " .. picture)
	end
	for _, picture in { F.firstHit, F.secondHit } do
		film:expose(picture, live)
		local tip = mine.at:PointToObjectSpace(mine:tipAt())
		assert(not motion or math.abs(tip.Z) < 0.35, "the steel stops on the rock at " .. picture)
	end
	film:expose(F.secondHit - 1, live)
	assert(mine.glow.Parent == nil and mine.light.Brightness == 0)
	film:expose(F.secondHit + 3, live)
	assert(mine.glow.Parent == stage and mine.light.Brightness > 0.3, "the vein opens on the contact frame")
	assert(mine.poolLight.Brightness > 0.3 and lighting.ColorShift_Top.B > lighting.ColorShift_Top.R, "the gallery is night blue and lamplit")

	-- The light is seen at the mine itself before anyone reports it.
	local room, mouth = film.room, film.arrival.mouth
	film:expose(F.outside + 1, live)
	local doorway = CFrame.new(film.arrival.entrance)
	assert(mouth.model.Parent == stage and mine.root.Parent == nil and not room.tv.gui.Enabled, "the doorway follows the discovery")
	assert((doorway:PointToObjectSpace(cam.CFrame.Position)).Z > 10 and cam.CFrame.LookVector.Z < -0.5, "the lens faces the entrance")
	local glowing = mouth.lamps[1].light.Brightness
	film:expose(F.outside + 24, live)
	assert(not motion or mouth.lamps[1].light.Brightness > glowing * 3 + 1, "the light builds inside the mine and comes out")

	-- A local light is applied a few exposures after a cut. Nothing in the room
	-- may depend on one, or the first picture of it is dark.
	for _, set in { room.root, room.reverse } do
		assert(not set:FindFirstChildWhichIsA("Light", true), "the room must not wait for a local light")
	end
	film:expose(F.living - 2, live)
	assert(room.root.Parent == stage and room.reverse.Parent == stage, "both angles of the room stand before the cut")
	film:expose(F.living, live)
	local first = { lighting.Brightness, lighting.Ambient, lighting.ColorShift_Top, lighting.ExposureCompensation, film.daylight.grade.TintColor }
	film:expose(F.livingReverse - 1, live)
	for k, value in { lighting.Brightness, lighting.Ambient, lighting.ColorShift_Top, lighting.ExposureCompensation, film.daylight.grade.TintColor } do
		assert(value == first[k], "the room changed its light after it was on screen")
	end
	film:expose(F.living + 10, live)
	assert(room.tv.gui.Enabled and mine.root.Parent == nil)
	-- The broadcast is a model of the cove in front of a real opening.
	local shown = room.root["Cove on the news"]
	for _, name in { "Mine sign", "Arch voussoir", "Crystal facet", "Amber sconce", "Cave jamb", "Market square" } do
		assert(shown:FindFirstChild(name), "the broadcast is missing " .. name)
	end
	for _, part in shown:GetChildren() do
		local p = room.wide:ToObjectSpace(part.CFrame)
		local reach = math.abs(p.XVector.Z) * part.Size.X + math.abs(p.YVector.Z) * part.Size.Y + math.abs(p.ZVector.Z) * part.Size.Z
		assert(p.Position.Z + reach / 2 < -0.8, "the broadcast came through the wall: " .. part.Name)
	end
	assert(room.glow.model.Parent == room.root and #room.glow.shafts == #mouth.shafts, "the same light is on the news")
	local kidArm = room.kid.model.RightHand.CFrame
	film:expose(F.living + 30, live)
	assert((room.kid.model.RightHand.CFrame ~= kidArm) == motion, "the kid reacts, and reduced motion holds")
	if motion then
		-- They look at each other, then both finish on the screen and stay there.
		film:expose(F.livingReverse + 20, live)
		local kid, sib = room.kid.model.Head, room.sib.model.Head
		assert(kid.CFrame.LookVector:Dot((sib.Position - kid.Position).Unit) > 0.55, "the kid looks round")
		assert(sib.CFrame.LookVector:Dot((kid.Position - sib.Position).Unit) > 0.55, "and is answered")
		for picture = F.witness - 6, F.witness - 2 do
			film:expose(picture, live)
			local a, b = kid.CFrame, sib.CFrame
			film:expose(picture + 1, live)
			assert(a.LookVector:Dot(kid.CFrame.LookVector) > 0.9995 and b.LookVector:Dot(sib.CFrame.LookVector) > 0.9995, "cut inside the reaction")
		end
	end

	local witness = film.arrival.witness
	local phoneSeat
	for picture = F.witness, F.enter - 1, 4 do
		film:expose(picture, live)
		local relation = witness.rig.model.RightHand.CFrame:ToObjectSpace(witness.glass.CFrame)
		phoneSeat = phoneSeat or relation
		assert(relation:FuzzyEq(phoneSeat, 0.0005), "the phone left the hand at " .. picture)
		local face = witness.rig.model.Head.Position - witness.glass.Position
		assert((-witness.glass.CFrame.LookVector):Dot(face.Unit) > 0.5, "the screen turned away from its owner")
		local player = film.arrival.copy.Head.Position - witness.glass.Position
		assert(witness.glass.CFrame.LookVector:Dot(player.Unit) > 0.97, "the lens is not on the player at " .. picture)
	end
	assert(room.root.Parent == nil and room.reverse.Parent == nil and not room.tv.gui.Enabled)

	-- The player.
	local actor = film.arrival
	film:expose(F.enter + 8, live)
	assert(actor.copy and actor.copy:FindFirstChild("Player's own hat"), "the player's own dressed character performs")
	assert(actor.remote == remote and not stage:FindFirstChild("Star root"), "nothing grows out of spawn")
	if remote then
		local replayAt = if live then landing else landing + film.base.Position - film.live.Position
		assert(((actor.mineBearing.Position - replayAt) * Vector3.new(1, 0, 1)).Magnitude < 0.02)
	else
		assert(actor.root ~= root and root.Transparency == 1, "one performer masks the live body")
	end
	assert(not actor.root["Hat glints"].Enabled and not actor.root["Prism Ribbon"].Enabled)
	assert(not actor:requestStrike(F.prompt - 1))
	film:expose(F.prompt + 12, live)
	assert(actor:requestStrike(F.prompt + 12) == F.autoStrike - F.prompt - 12, "a press skips straight to the swing")
	assert(not actor:requestStrike(F.prompt + 13), "one strike per screening")
	local wall = mine.fracture
	film:expose(F.contact2 - 1, live)
	for _, slab in wall.slabs do
		assert((slab.model:GetPivot().Position - wall.at * slab.rest).Magnitude < 0.01, "the face is whole before the blow")
	end
	film:expose(F.contact2, live)
	local spot = mine.at:PointToObjectSpace(actor:tipAt())
	assert((actor:tipAt() - actor.strikePoint).Magnitude < 0.02 and math.abs(spot.Z) < 0.1, "the steel meets the rock")
	film:expose(F.contact2 + 6, live)
	local showing = 0
	for _, c in wall.cracks do
		if c.part.Transparency < 0.5 then showing += 1 end
	end
	assert(showing > 6, "the fracture spreads")
	film:expose(F.inside + 6, live)
	local moved = 0
	for _, slab in wall.slabs do
		if not slab.model.Parent or (slab.model:GetPivot().Position - wall.at * slab.rest).Magnitude > 1 then
			moved += 1
		end
	end
	assert(moved > #wall.slabs * 0.7 and wall.light.Brightness > 1, "the slabs fall and the pocket lights")
	local through = wall.at:PointToObjectSpace(cam.CFrame.Position)
	assert(through.Z < -1.5, "the lens is inside what the player opened")
	film:expose(F.reveal + 20, live)
	assert(actor.glass.root.Parent == stage and actor.copy.Parent == stage and mine.root.Parent == nil)
	local head = actor.copy.Head.Position
	local seen = cam.CFrame:PointToObjectSpace(head)
	assert(seen.Z < -2 and math.abs(seen.X / seen.Z) < 0.5 and math.abs(seen.Y / seen.Z) < 0.35, "the face is inside the reveal")
	-- Glass never stops between its entrance and its exit, and never turns back.
	if motion then
		local last
		for picture = F.reveal + 30, F.answer - 2 do
			film:expose(picture, live)
			local a = actor.glass.panels[1].model:GetPivot().Position
			film:expose(picture + 1, live)
			local step = actor.glass.at:VectorToObjectSpace(actor.glass.panels[1].model:GetPivot().Position - a).X
			assert(step > 0.0005, "the glass stopped at " .. picture)
			assert(not last or step > last * 0.8, "the glass lost its speed at " .. picture)
			last = step
		end
	end
	film:expose(F.answer + 2, live)
	assert(actor.glass.root.Parent == nil and actor.mouth.model.Parent == stage, "back outside")
	film:expose(F.turn - 4, live)
	assert(not motion or actor.copy.Head.CFrame.LookVector:Dot(actor.mineBearing.LookVector) < 0, "they come out of the mine")
	film:expose(F.handoff, live)
	if not remote then
		assert((actor.root.Position - root.Position).Magnitude < 1.5, "the performance ends on the live mark")
	end
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
		film:landingFrame(sheet.frames.duration)
		assert(
			cam.CFrame:FuzzyEq(h.playable.view, 0.0002)
				and cam.Focus:FuzzyEq(h.playable.focus, 0.0002)
				and math.abs(cam.FieldOfView - 64) < 0.0002
		)
	end
	assert(root.CFrame == start and #workspace.CitrineCove:GetDescendants() == mapSize)
	-- Repeat the release with sky, local lamps and optics actively changed.
	film:draw(if live then clock.handoff - 1 elseif motion then 4.56 else 7.62, live)
	film:Destroy()
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
	arrival.motion = true
	local mine = require(source.MineFace).new(stage, site + Vector3.new(-34, 43, -63), lighting:GetSunDirection())
	arrival.mine = mine
	local gripRelation, hatRelation
	local F = sheet.frames
	for frame = F.witness, F.handoff, 2 do
		arrival:draw(frame)
		assert(arrival.remote and arrival.copy["Equipped 2"].Handle and root.CFrame == before, kind .. " underground appearance")
		local pick = arrival.copy["Harbor pick"]
		assert(arrival.handle == pick.Handle and pick.Handle.Transparency < 1, kind .. " must show the welded pick")
		local grip = pick:FindFirstChild("Grip", true)
		local hand = grip.Part0
		assert((pick["Grip tape"].Position - hand.RightGripAttachment.WorldPosition).Magnitude < 0.001,
			kind .. " wrapped handle missed the palm")
		local relation = hand.CFrame:ToObjectSpace(grip.Part1.CFrame)
		gripRelation = gripRelation or relation
		assert(relation:FuzzyEq(gripRelation, 0.0003), kind .. " pick moved in hand")
		local hat = arrival.copy["Equipped 2"].Handle
		hatRelation = hatRelation or arrival.copy.Head.CFrame:ToObjectSpace(hat.CFrame)
		assert(arrival.copy.Head.CFrame:ToObjectSpace(hat.CFrame):FuzzyEq(hatRelation, 0.0003), kind .. " accessory drifted")
		if frame >= F.witness and frame < F.enter and kind == "R15" then
			for _, side in { "LeftFoot", "RightFoot" } do
				local foot = arrival.copy[side]
				assert(foot.Position.Y - foot.Size.Y / 2 > arrival.floor - 0.35, kind .. " foot sank at " .. frame)
			end
		end
		if frame == F.contact2 then
			local spot = mine.at:PointToObjectSpace(arrival:tipAt())
			assert((arrival:tipAt() - arrival.strikePoint).Magnitude < 0.02 and math.abs(spot.Z) < 0.1, kind .. " missed the rock")
			local off = mine.fracture.at:PointToObjectSpace(arrival:tipAt())
			assert(off.Magnitude < 2.2, kind .. " struck outside the slab " .. off.Magnitude)
		end
		-- A held exposure must not move anything.
		local at = arrival.copy.Head.CFrame
		arrival:draw(frame)
		assert(arrival.copy.Head.CFrame == at, kind .. " twitched inside an exposure")
	end
	arrival:Destroy()
	mine:Destroy()
	cam:Destroy()
	model:Destroy()
end
nativeAvatar("R6", 0.85)
nativeAvatar("R15", 1.35)
check(true, true, false)
check(false, false, false)
check(true, false, true)
print("MINING_ORIGINS_TESTS_PASSED")
