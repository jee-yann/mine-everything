-- A smooth rail addressed in studs. Its length table is built once, so an
-- exposure, or any point in its wake, can be sampled in either direction.
local Curve = {}
Curve.__index = Curve
local steps = 16

function Curve:position(i, t)
	local a, b = self.points[i], self.points[i + 1]
	local chord = (b - a).Magnitude
	local t2, t3 = t * t, t * t * t
	return a + (b - a) * (3 * t2 - 2 * t3)
		+ self.directions[i] * (chord * (t3 - 2 * t2 + t))
		+ self.directions[i + 1] * (chord * (t3 - t2))
end

function Curve.new(points, endDirection)
	local self = setmetatable({ points = points, directions = {}, lengths = { 0 }, stops = { 0 } }, Curve)
	for i, at in points do
		local before, after = points[i - 1], points[i + 1]
		local previous = if before then (at - before).Unit else Vector3.zero
		local nextDirection = if after then (after - at).Unit else Vector3.zero
		local tangent = previous + nextDirection
		self.directions[i] = if tangent.Magnitude > 0.001 then tangent.Unit else Vector3.zero
	end
	if endDirection then self.directions[#points] = endDirection.Unit end
	local length, previous = 0, points[1]
	for i = 1, #points - 1 do
		for j = 1, steps do
			local at = self:position(i, j / steps)
			length += (at - previous).Magnitude
			table.insert(self.lengths, length)
			previous = at
		end
		self.stops[i + 1] = length
	end
	self.length = length
	return self
end

function Curve:sample(distance)
	distance = math.clamp(distance, 0, self.length)
	local lengths = self.lengths
	local lo, hi = 2, #lengths
	while lo < hi do
		local mid = math.floor((lo + hi) / 2)
		if lengths[mid] < distance then lo = mid + 1 else hi = mid end
	end
	local left = lengths[lo - 1]
	local frac = (distance - left) / math.max(0.00001, lengths[lo] - left)
	local tick = lo - 2
	local segment = math.floor(tick / steps) + 1
	local t = (tick % steps + frac) / steps
	return self:position(segment, t), segment, t
end

return Curve
