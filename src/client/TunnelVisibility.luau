local Lighting = game:GetService("Lighting")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Tunnel = {}
Tunnel.__index = Tunnel

function Tunnel.new()
	return setmetatable({}, Tunnel)
end

function Tunnel:restore()
	local outside = self.outside
	if not outside then return end
	Lighting.FogColor, Lighting.FogEnd, Lighting.FogStart = outside.color, outside.finish, outside.start
	if outside.air and outside.air.Parent == script then outside.air.Parent = Lighting end
	self.outside = nil
end

function Tunnel:update(depth, eyeDistance, lampRange, reach)
	if depth <= 0 then
		self:restore()
		return
	end
	if not self.outside then
		local air = Lighting:FindFirstChildOfClass("Atmosphere")
		self.outside = { air = air, color = Lighting.FogColor, start = Lighting.FogStart, finish = Lighting.FogEnd }
		-- Roblox uses either Atmosphere or distance fog. Keep the same coastal
		-- atmosphere instance and restore it before the camera returns outside.
		if air then air.Parent = script end
		Lighting.FogColor = Color3.fromRGB(7, 9, 14)
	end
	-- In the entrance shaft daylight still reaches down from above. Deeper in,
	-- the illuminated face stays clear and the next few blocks fall into shadow.
	local cover = math.clamp(depth / (Config.Cell * 2.5), 0.01, 1)
	local finish = eyeDistance + math.max(lampRange + Config.Cell * 4, reach + Config.Cell * 2) / cover
	local start = eyeDistance + lampRange * 0.8 / cover
	if math.abs(Lighting.FogEnd - finish) > 0.05 then Lighting.FogEnd = finish end
	if math.abs(Lighting.FogStart - start) > 0.05 then Lighting.FogStart = start end
end

return Tunnel
