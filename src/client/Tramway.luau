local RunService = game:GetService("RunService")
local Tramway = {}

local function ease(value)
	local a = math.clamp(value, 0, 1)
	return a*a*(3 - 2*a)
end

-- Each span receives ore from the next tower east, then tips it into the
-- receiving hopper to the west. Pauses leave time to see each transfer.
function Tramway.sample(west, east, phase)
	local t = 0.87 - 0.74 * ease((phase - 0.12)/0.36) + 0.74 * ease((phase - 0.60)/0.36)
	local a = math.floor(t * 4)/4
	local b, f = a + 0.25, (t - a)*4
	local sag = 13.6 * (a*(1 - a)*(1 - f) + b*(1 - b)*f)
	local tip = ease((phase - 0.48)/0.055) - ease((phase - 0.55)/0.05)
	local drop = ease((phase - 0.505)/0.05)
	local fill = ease((phase - 0.015)/0.072)
	return west:Lerp(east, t) - Vector3.yAxis*sag, math.rad(48)*tip,
		Vector3.new(-1.5*drop, 1.4*(1 - fill) - 3.8*drop*drop, 0), phase >= 0.015 and phase < 0.555
end

local function rig(car)
	local west, east = car:FindFirstChild("West terminal"), car:FindFirstChild("East terminal")
	if not car.PrimaryPart or not west or not east then return nil end
	local body, load = {}, {}
	local pivot = car:GetPivot()
	for _, part in car:GetChildren() do
		if not part:IsA("BasePart") then continue end
		local cargo = part.Name == "Fractured stone" or part.Name == "Split face"
		if cargo or part.Name == "Ore bucket" or part.Name == "Bucket lip" then
			table.insert(if cargo then load else body, { part, pivot:ToObjectSpace(part.CFrame) })
		end
	end
	return { model = car, west = west.Value, east = east.Value, body = body, load = load }
end

function Tramway.run(origin)
	local cars, nextSurvey = {}, 0
	while true do
		RunService.Heartbeat:Wait()
		local camera = workspace.CurrentCamera
		local offset = camera and camera.CFrame.Position - origin
		if not offset or offset.Y < -48 or offset.Magnitude > 300 then
			task.wait(0.5)
			continue
		end
		local time = workspace:GetServerTimeNow()
		if time >= nextSurvey then
			nextSurvey = time + 1
			local island = workspace:FindFirstChild("CitrineCove")
			local highlands = island and island:FindFirstChild("Citrine Highlands")
			local cabins = highlands and highlands:FindFirstChild("Moving cabins")
			for lane = 1, 3 do
				local car = cabins and cabins:FindFirstChild("Ore carrier " .. lane)
				if car ~= (cars[lane] and cars[lane].model) then cars[lane] = car and rig(car) end
			end
		end
		for lane, car in cars do
			if not car.model.Parent then continue end
			local phase = (time/42 + (lane - 1)*0.5) % 1
			local hook, angle, fall, loaded = Tramway.sample(car.west, car.east, phase)
			local mount = CFrame.new(origin + hook)
			car.model:PivotTo(mount)
			local pivot = mount * CFrame.new(0, -3.25, 0) * CFrame.Angles(0, 0, angle) * CFrame.new(0, 3.25, 0)
			for _, item in car.body do item[1].CFrame = pivot * item[2] end
			for _, item in car.load do
				item[1].Transparency = if loaded then 0 else 1
				item[1].CFrame = (pivot * item[2]) + fall
			end
		end
	end
end

return Tramway
