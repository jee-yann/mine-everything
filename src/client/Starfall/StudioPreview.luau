-- Play-mode look development. Opening only calls this on an opted-in Studio client.
local defaults = require(script.Parent.NightLook)
local frames = require(script.Parent.ExposureSheet).frames
local fieldOrder = { "Exposure", "ShadowFill", "RimStrength", "RimColor", "SkyColor" }

local function readLook(controls)
	local look = {}
	for _, key in fieldOrder do
		local value = controls:GetAttribute(key)
		if typeof(value) ~= typeof(defaults[key]) or value ~= value then
			value = defaults[key]
		elseif key == "Exposure" then
			value = math.clamp(value, -5, 5)
		elseif key == "RimStrength" then
			value = math.clamp(value, 0, 1)
		end
		look[key] = value
		if value ~= controls:GetAttribute(key) then
			controls:SetAttribute(key, value)
		end
	end
	return look
end

local function printLook(look)
	local lines = { "return table.freeze({" }
	for _, key in fieldOrder do
		local value = look[key]
		local literal
		if typeof(value) == "Color3" then
			local hex = value:ToHex():upper()
			literal = if Color3.fromHex(hex) == value then string.format('Color3.fromHex("%s")', hex)
				else string.format("Color3.new(%.9g, %.9g, %.9g)", value.R, value.G, value.B)
		else
			literal = tostring(value)
		end
		table.insert(lines, string.format("\t%s = %s,", key, literal))
	end
	table.insert(lines, "})")
	print("Starfall preview • paste into NightLook:\n" .. table.concat(lines, "\n"))
end

return function(initialFrame, nextRender, draw)
	local controls = Instance.new("Configuration")
	controls.Name = "StarfallPreview"
	controls:SetAttribute("Frame", initialFrame)
	controls:SetAttribute("PrintSettings", false)
	for _, key in fieldOrder do
		controls:SetAttribute(key, defaults[key])
	end
	controls.Parent = workspace

	local redrawAt = 0
	controls.AttributeChanged:Connect(function(key)
		if key == "Frame" then
			redrawAt = 0
		elseif defaults[key] ~= nil then
			-- Wait for a color-picker drag to settle before reconstructing the scene.
			redrawAt = os.clock() + 0.12
		end
	end)
	local ok, reason = xpcall(function()
		while controls.Parent and nextRender() do
			local frame = controls:GetAttribute("Frame")
			if typeof(frame) ~= "number" or not (frame >= 0) then
				break
			end
			if controls:GetAttribute("PrintSettings") then
				printLook(readLook(controls))
				controls:SetAttribute("PrintSettings", false)
			end
			if os.clock() >= redrawAt then
				redrawAt = math.huge
				draw(math.clamp(math.floor(frame), 0, frames.duration - 1), readLook(controls))
			end
		end
	end, debug.traceback)
	local look = readLook(controls)
	printLook(look)
	controls:Destroy()
	if not ok then
		error(reason, 0)
	end
	return look
end
