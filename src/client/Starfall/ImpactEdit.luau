-- Each transfer photographs the live cove. Silver preserves a trace of its
-- color; the spectral prints expose colored light and raking fire on the rock.
local beats = require(script.Parent.ExposureSheet).frames
local function plate(mode, pose, contrast, bias, saturation)
	return table.freeze({ mode = mode, pose = pose, contrast = contrast, bias = bias, saturation = saturation or -1 })
end
local contact = table.freeze({
	[0] = plate("negative", "puncture", -98, -8),
	-- One untouched moonlit frame between the puncture and the tightening air.
	[2] = plate("silver", "pin", 1.15, -0.05, -0.91),
	[3] = plate("positive", "needle", 111, -39.5),
	[4] = plate("ultraviolet", "crown", 0.84, -0.42, -0.19),
	[5] = plate("ember", "rake", 1.04, -0.47, 0.11),
	[6] = plate("negative", "crosscut", -115, 35.6),
	[7] = plate("white", "corona", 0, 1),
	[8] = plate("negative", "iris", -121, 37.0),
	[9] = plate("silver negative", "fan", -8.8, 2.0, -0.975),
	[10] = plate("ember", "scythe", 0.96, -0.33, 0.08),
	[11] = plate("negative", "splinter", -109, 9),
	[12] = plate("silver", "cinders", 7.2, -1.28, -0.97),
})
local wave = table.freeze({
	[-3] = plate("positive", "forewash", 101, 22),
	[-2] = plate("ultraviolet", "skimming", 1.08, 0.16, 0.15),
	-- The observer sees the cove at normal exposure immediately before the rim.
	-- The whitecap and its trailing edge lie directly over the live plume.
	[0] = plate("color fire", "whitecap", 0.67, -0.060, 0.04),
	[1] = plate("color ash", "backwash", 0.60, -0.046, 0.08),
	[2] = plate("black", "shutter", 0, -1),
	[3] = plate("negative", "splinters", -124, -20),
	[4] = plate("ember", "downwind", 1.01, 0.11, 0.22),
})
local Edit = {}
function Edit.at(frame)
	return contact[frame - beats.contact] or wave[frame - beats.breaker]
end
function Edit.roller(frame)
	local index = frame - beats.breaker + 1
	return if index == 1 or index == 2 then index else nil
end
return table.freeze(Edit)
