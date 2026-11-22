-- The last three exposures of atmosphere before the rock reaches the basin.
local sheet = require(script.Parent.ExposureSheet)
local heat = { 0.24, 0.56, 0.87 }
local color = { Color3.fromHex("BBA9FE"), Color3.fromHex("FFCA89"), Color3.fromHex("D2F6FF") }

return function(frame)
	local i = frame - sheet.frames.terminal + 1
	return heat[i] or 0, color[i] or Color3.fromHex("FFE4B7")
end
