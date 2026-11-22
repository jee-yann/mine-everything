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
	assert(film.daylight.lunar.root.Parent == stage and not film.daylight.sun.board.Enabled, "midnight coast")
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
	film:draw(10.5, false)
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
	for _, first in { 385, 463, 572 } do
		film:expose(first, false)
		local startEye, lens = cam.CFrame.Position, cam.FieldOfView
		film:expose(first + 10, false)
		local step = cam.CFrame.Position - startEye
		film:expose(first + 20, false)
		assert((cam.CFrame.Position - startEye - step * 2).Magnitude < 0.003, "crater dolly changed speed")
		assert(cam.FieldOfView == lens and (step.Magnitude > 0.1) == motion)
	end
	film:expose(512, false)
	local endOfPush = cam.CFrame.Position
	film:expose(515, false)
	assert((cam.CFrame.Position - endOfPush).Magnitude < 0.025 or not motion, "camera reversed before slowing down")
	film:expose(520, false)
	local beforeRetreat = cam.CFrame.Position
	film:expose(525, false)
	local earlyRetreat = (cam.CFrame.Position - beforeRetreat).Magnitude
	film:expose(540, false)
	local middle = cam.CFrame.Position
	film:expose(545, false)
	assert(((cam.CFrame.Position - middle).Magnitude > earlyRetreat * 1.3) == motion, "crater pullback eases away")

	film:draw(10.5, false)
	local hot = lighting.SeaAir.Haze
	assert(film.daylight.depth.Enabled and film.daylight.depth.FocusDistance > 4, "crater focus")
	film:draw(15.9, false)
	assert(hot > lighting.SeaAir.Haze + 0.9, "ash remains after wave and dissipates through regrowth")
	local sawSun, states = false, {}
	for i = 0, 75 do
		film:draw(clock.recovery + i * 0.21, false)
		assert(film.daylight.sky.MoonAngularSize == 0 and not film.daylight.root:FindFirstChild("Moon", true),
			"the time-lapse brought the lunar disc back onscreen")
		sawSun = sawSun or film.daylight.sun.board.Enabled
		states[#film.island.set:GetChildren()] = true
	end
	local exposures = 0
	for _ in states do
		exposures += 1
	end
	assert(exposures >= 7 and sawSun, "settlement and sky exposures")
	assert(water.part.Color == water.base and water.part.Material == water.material, "daylight water not restored")
	for _, picture in { sheet.frames.settlement, 753, 754, sheet.frames.match - 1 } do
		film:expose(picture, false)
		for _, layer in film.island.deposits do
			assert(layer.u == 1 and layer.bed:GetPivot():FuzzyEq(layer.top), "hills moved during construction")
		end
	end
	film:draw(clock.match - 0.01, false)
	local composition = film.base:ToObjectSpace(cam.CFrame)
	film:draw(clock.match + 0.01, live)
	local match = (if live then film.live else film.base):ToObjectSpace(cam.CFrame)
	assert(composition:FuzzyEq(match, 0.04), "map must register through match")
	assert((film.island.set.Parent == nil) == live, "local historical set while streaming")
	film:draw(clock.match + 0.4, not live)
	assert(film.matchLive == live)
	assert(
		not film.illumination.root.Parent
			and not film.daylight.bloom.Enabled
			and not film.daylight.depth.Enabled
			and not film.daylight.rays.Enabled
			and not film.daylight.blur.Enabled,
		"optical effects survived the match"
	)
	film:draw(28.8, live)
	assert((film.island.set.Parent ~= nil) == (remote and not live) and film.arrival.proof.model.Parent == stage)
	if remote then
		assert(film.arrival.copy and film.arrival.copy:FindFirstChild("Player's own hat"))
		local replayAt = if live then landing else landing + film.base.Position - film.live.Position
		assert((film.arrival.root.Position - replayAt).Magnitude < 0.02)
	else
		assert(film.arrival.root == root and not film.arrival.copy, "spawn shot must use the player's live character")
	end
	assert(film.arrival.root["Hat glints"].TimeScale == 0 and not film.arrival.root["Prism Ribbon"].Enabled)
	local station = film.arrival.marker
	local cuts = sheet.frames
	local proof = film.arrival.proof
	local tool = film.arrival.assay
	film:expose(cuts.measure, live)
	assert(not station.invitation:IsDescendantOf(stage), "the commission must follow the trial")
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
	film:expose(offered + 27, live)
	assert(station.runnels[6].strokes[1].Material == Enum.Material.Neon, "the strike lights the far end of the route")
	assert((station.signalPosition - station.runnels[6].at.WorldPosition).Magnitude < 0.34,
		"nineteen pictures after a player-timed strike the pulse reaches the sixth vane")
	assert(station.signal.trail[2].wire.Enabled == motion, "reduced motion must retain only the calm ground trace")
	film:expose(cuts.mineRun, live)
	local bearer = require(source.GalleryRun).origin(film.arrival)
	assert((station.signalPosition - bearer - Vector3.new(0.14, 1.29, -0.42)).Magnitude < 0.035,
		"the energy head must cross the actual mine sill on the approach")
	local run = require(source.GalleryRun)
	local origin = run.origin(film.arrival)
	local mouth = origin + run.mouth
	if motion then
		local tall = {
			handoff = { landing = origin + Vector3.new(0, 4.96, 89), origin = origin },
			mineBearing = CFrame.new(origin + Vector3.new(0, 4.96, 89)), unit = 1.85,
			marker = { exit = { WorldPosition = origin + Vector3.new(0, 0, 89 - 29.88 * 1.85) } },
		}
		local first, lastZ = cuts.prompt + 8 + 26, math.huge
		for frame = first, cuts.mineRun do
			local eye = run.gallery(tall, frame, first, true)
			assert(eye.Z < lastZ, "earliest strike must keep travelling towards the arch with a tall avatar")
			lastZ = eye.Z
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
	assert((deepSignal - Vector3.new(0.30, 2.88, 16.11)).Magnitude < 0.035, "the flame must continue down the same wall of the shaft")
	for item, original in photographed do
		assert(item.LocalTransparencyModifier == original, "transition must restore each floor brick")
	end
	if motion then
		local stride = (chamber.Position - approach.Position).Magnitude
		assert(math.abs(stride - endRun) < 0.14, "lens lost its velocity in the throat")
		assert(approach.LookVector:Dot(chamber.LookVector) > 0.99, "gallery and crystal must share the sightline")
	end
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
check(true, true, false)
check(false, false, false)
check(true, false, true)
print("MINING_ORIGINS_TESTS_PASSED")
