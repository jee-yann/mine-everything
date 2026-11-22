-- All three carriers follow the same sag as the four straight cable sections.
local function run(origin)
	local period = 42
	while task.wait(0.08) do
		local camera = workspace.CurrentCamera
		if not camera then
			continue
		end
		local offset = camera.CFrame.Position - origin
		if offset.Y < -48 or offset.Magnitude > 300 then
			task.wait(0.9)
			continue
		end
		local island = workspace:FindFirstChild("CitrineCove")
		local highlands = island and island:FindFirstChild("Citrine Highlands")
		local cabins = highlands and highlands:FindFirstChild("Moving cabins")
		if not cabins then
			continue
		end
		local phase = workspace:GetServerTimeNow() * (math.pi * 2 / period)
		for lane = 1, 3 do
			local car = cabins:FindFirstChild("Ore carrier " .. lane)
			local west = car and car:FindFirstChild("West terminal")
			local east = car and car:FindFirstChild("East terminal")
			if car and car.PrimaryPart and west and east then
				-- Reverse with clearance for the full width of the hanging bucket and tower legs.
				local t = 0.5 - 0.37 * math.cos(phase + lane * 2.1)
				local segment = math.floor(t * 4) / 4
				local nextT = segment + 0.25
				local fraction = (t - segment) * 4
				local sag = 13.6 * (segment * (1 - segment) * (1 - fraction) + nextT * (1 - nextT) * fraction)
				car:PivotTo(CFrame.new(origin + west.Value:Lerp(east.Value, t) - Vector3.yAxis * sag))
			end
		end
	end
end
return run
