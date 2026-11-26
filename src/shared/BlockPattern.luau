local Config = require(script.Parent.GameConfig)
local Pattern = {}
function Pattern.axes(normal)
	if normal.Y ~= 0 then
		return Vector3.xAxis, -normal.Y * Vector3.zAxis
	end
	return Vector3.yAxis:Cross(normal), Vector3.yAxis
end
-- Both ends trace to the centre of each face, including obstructions and reach.
function Pattern.visiblePart(eye, center, normal, params, reach)
	local face = center + normal * (Config.Cell / 2)
	local delta = face - eye
	if delta.Magnitude < 0.05 or delta.Magnitude > (reach or Config.Reach) or delta:Dot(normal) >= 0 then
		return nil
	end
	local hit = workspace:Raycast(eye, delta.Unit * (delta.Magnitude + 0.16), params)
	if hit and hit.Normal:Dot(normal) > 0.999 and (hit.Position - face).Magnitude < 0.12 then
		return hit.Instance
	end
	return nil
end

-- A third-person camera can see the top while the miner is beside the brick.
-- Accept a reachable side of that same brick when its top is actually exposed.
function Pattern.reachablePart(eye, center, normal, params, reach)
	local direct = Pattern.visiblePart(eye, center, normal, params, reach)
	if direct or normal ~= Vector3.yAxis then
		return direct
	end
	for _, side in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis, -Vector3.yAxis } do
		local part = Pattern.visiblePart(eye, center, side, params, reach)
		if
			part
			and (part.Position - center).Magnitude < 0.03
			and bit32.btest(part:GetAttribute("OpenFaces") or 0, 2 ^ Enum.NormalId.Top.Value)
		then
			return part
		end
	end
	return nil
end

-- `practice` marks a Studio test block that any pick can mine.
function Pattern.select(origin, center, ore, power, space, practice)
	if space < 1 or not ore or center.Y >= origin.Y + Config.FloorY then
		return {}, nil
	end
	local required = if practice then 1 else math.max(ore.hardness, Config.strength(center.Y - origin.Y))
	if required > power then
		return {}, ore, required
	end
	return { center }, nil
end
return Pattern
