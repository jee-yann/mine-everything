local Roller = require(script.Parent.BreakerInk)
local edit = require(script.Parent.ImpactEdit)
local S = require(script.Parent.Scenery)
local Lens = {}
Lens.__index = Lens
local neutral = Color3.new(1, 1, 1)
local ultraviolet = Color3.fromRGB(170, 147, 249)
local ember = Color3.fromRGB(255, 155, 115)
local seaLight = Color3.fromRGB(255, 180, 148)
local V = Vector3.new
local lensKick = {
	crown = 0.105,
	rake = -0.12,
	crosscut = 0.095,
	fan = -0.064,
	scythe = -0.092,
	skimming = 0.107,
	splinters = -0.056,
	downwind = -0.124,
}

function Lens.new(screen)
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name, grade.Enabled = "Live impact threshold", false
	local blur = Instance.new("BlurEffect")
	blur.Name, blur.Enabled = "Sight returning after the blast", false
	return setmetatable({ grade = grade, blur = blur, roller = Roller.new(screen) }, Lens)
end

function Lens:draw(camera, frame)
	local grade, blur = self.grade, self.blur
	grade.Parent, blur.Parent = camera, camera
	local exposure = edit.at(frame)
	self.exposure = exposure
	grade.Enabled = exposure ~= nil
	if exposure then
		grade.TintColor = if exposure.mode == "ultraviolet"
			then ultraviolet
			elseif exposure.mode == "ember" then ember
			elseif edit.roller(frame) then seaLight
			else neutral
		grade.Saturation = exposure.saturation
		grade.Contrast, grade.Brightness = exposure.contrast, exposure.bias
	end
	local softness = 0
	if frame >= 253 and frame < 273 then
		softness = 30 * (1 - S.ease(frame, 254, 273))
	elseif frame >= 329 and frame < 352 then
		softness = 40 * (1 - S.ease(frame, 331, 352))
	end
	blur.Size, blur.Enabled = softness, softness > 0.02
	local kick = if exposure then lensKick[exposure.pose] or 0 else 0
	if softness > 0.02 or kick ~= 0 then
		local n = softness / 40
		local shear = n * (0.077 * math.sin(frame * 0.41) - 0.042) + kick
		camera.CFrame *= CFrame.fromMatrix(
			Vector3.zero,
			V(1 + n * 0.072 + kick * 0.42, 0, 0),
			V(shear, 1 - n * 0.063 - kick * 0.34, 0),
			Vector3.zAxis
		)
	end
	self.roller:draw(edit.roller(frame), camera.ViewportSize)
end

function Lens:Destroy()
	self.grade:Destroy()
	self.blur:Destroy()
	self.roller:Destroy()
end

return Lens
