-- First person: Roblox hides your own character when the camera is in your head, and your real arm
-- doesn't follow the camera up and down. So, only while you're zoomed all the way in, a copy of your
-- pickaxe is held in front of the camera (bottom right, wherever you look), swings in time with your
-- mining and carries your Mining FX, the same streak everyone else sees on your real pick. Only you see
-- the copy; it's rebuilt when your pick or Mining FX changes.
local Run = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Looks = require(Shared.Collectibles), require(Shared.CosmeticLooks)

-- Where the hand holds the pick, from the camera, and the swing's angles (radians, about the camera's
-- side-to-side axis; positive tips the head back towards you): resting, lifted back, struck forward.
-- Close to the camera but low and to the right, so it frames the view instead of blocking it.
local hold = CFrame.new(1.3, -1.25, -1.9)
local rest, lifted, struck = 0.15, 0.75, -1.0
-- The copy is drawn smaller than the real pick, so it sits in the corner of the view.
local size = 0.55
-- The swing aims in towards the middle of the view (so the pick is seen from the side, in profile)
-- and the handle leans in a little.
local tilt = CFrame.Angles(0, math.rad(38), math.rad(16))
-- The head lies in the swing so its point leads: it chops point first, not with its flat side.
local twist = CFrame.Angles(0, math.rad(90), 0)

return function(player)
	local camera = workspace.CurrentCamera
	local view, key, streak, phase, weight = nil, nil, {}, 0, 0

	local function clear()
		if view then view:Destroy() end
		view, key, streak = nil, nil, {}
	end

	-- A copy of the real pick, cut loose from the hand, with its own streak.
	local function build(char)
		clear()
		local pick = char:FindFirstChild("Harbor pick")
		local handle = pick and pick:FindFirstChild("Handle")
		if not handle then return end
		local copy = pick:Clone()
		copy.Name = "First person pick"
		for _, item in copy:GetDescendants() do
			if item:IsA("JointInstance") or item:IsA("WeldConstraint") then
				local a, b = item.Part0, item.Part1
				if not (a and b and a:IsDescendantOf(copy) and b:IsDescendantOf(copy)) then item:Destroy() end
			elseif item:IsA("Trail") or item:IsA("ParticleEmitter") or item:IsA("Beam") then
				item:Destroy()
			elseif item:IsA("BasePart") then
				item.CanCollide, item.CanQuery, item.CanTouch, item.CastShadow = false, false, false, false
				item.Anchored = false
			end
		end
		local grip = copy:FindFirstChild("Handle")
		grip.Anchored = true
		copy.PrimaryPart = grip
		copy:ScaleTo(size)
		-- The tips the Mining FX streak runs between, as on the real pick.
		local tips = {}
		for _, attachment in grip:GetChildren() do
			if attachment:IsA("Attachment") and math.abs(attachment.Position.Y - 0.76 * size) < 0.01 then table.insert(tips, attachment) end
		end
		table.sort(tips, function(a, b) return a.Position.X < b.Position.X end)
		local look = C.trailById[player:GetAttribute("Trail") or ""]
		if look and #tips >= 2 then
			streak = Looks.streak(look, tips[1], tips[2], function() end,
				{ name = "Mining trail", lifetime = 0.16 + 0.025 * Looks.rank(look), scale = 0.5 })
		end
		copy.Parent = camera
		view = copy
		key = (player:GetAttribute("Trail") or "") .. "/" .. tostring(player:GetAttribute("Power")) .. "/" .. tostring(char)
	end

	-- Blocks (and only blocks) can come between the camera and the pick when you mine at your feet.
	local blocks = RaycastParams.new()
	blocks.FilterType = Enum.RaycastFilterType.Exclude
	local nameplate
	Run:BindToRenderStep("First person pickaxe", Enum.RenderPriority.Camera.Value + 3, function(dt)
		local char = player.Character
		local head = char and char:FindFirstChild("Head")
		-- Zoomed in: the camera is in (or right at) your head, which Roblox's camera and the mine's own
		-- view both mark by hiding the head. Mining in a shaft nudges the camera, so don't rely on the
		-- distance alone.
		local first = head ~= nil and ((camera.CFrame.Position - head.Position).Magnitude < 1.6
			or (head.LocalTransparencyModifier >= 0.95 and (camera.CFrame.Position - head.Position).Magnitude < 3))
		-- Your own name and title would float in front of you: hide them while zoomed in.
		if char and (not nameplate or not nameplate:IsDescendantOf(char)) then
			nameplate = char:FindFirstChild("Miner title", true)
		end
		if nameplate and nameplate:IsA("BillboardGui") then nameplate.Enabled = not first end
		if not first then
			if view then clear() end
			return
		end
		local want = (player:GetAttribute("Trail") or "") .. "/" .. tostring(player:GetAttribute("Power")) .. "/" .. tostring(char)
		if not view or key ~= want or not view.Parent then build(char) end
		if not view then return end
		-- Swing while the server says this miner is cutting, in short taps like the real arm.
		local swinging = char:GetAttribute("MiningSwing") ~= nil
		weight = math.clamp(weight + (if swinging then 10 else -8) * dt, 0, 1)
		phase = (phase + dt / 0.24) % 1
		local lift = if phase < 0.55 then (1 - math.cos(phase / 0.55 * math.pi)) / 2
			elseif phase < 0.82 then 1 - (phase - 0.55) / 0.27
			else 0
		local swingAngle = struck + (lifted - struck) * lift
		local angle = rest + (swingAngle - rest) * weight
		local bob = if swinging then 0 else 0.03 * math.sin(os.clock() * 2)
		-- Mining straight down, the block you're cutting can sit between the camera and where the pick
		-- is held: bring the pick in closer so it stays in view.
		local grip = hold
		blocks.FilterDescendantsInstances = { char, view }
		local reach = (hold.Position + Vector3.new(0, 0.9, -0.6)) * 1.15
		local hit = workspace:Raycast(camera.CFrame.Position, camera.CFrame:VectorToWorldSpace(reach), blocks)
		if hit then
			local k = math.clamp((hit.Distance - 0.15) / reach.Magnitude, 0.4, 1)
			grip = CFrame.new(hold.Position * k)
		end
		view:PivotTo(camera.CFrame * grip * tilt * CFrame.new(0, bob, 0) * CFrame.Angles(angle, 0, 0) * CFrame.new(0, 0.95 * size, 0) * twist)
		for _, item in streak do
			item.Enabled = swinging
		end
	end)
end
