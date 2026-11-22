-- The bevels, colored enamel and glass are authored at 32x so fine seams
-- survive the offline union. The live scene instantiates five solids per arrow.
local S = require(game.ReplicatedStorage.Scenery)
local V, CF = Vector3.new, CFrame.new
local metal = Enum.Material.Metal

local function anchor(parent, name, position)
	local point = Instance.new("Attachment")
	point.Name, point.Position, point.Parent = name, position, parent
	return point
end

-- Bronze tramplaques with a black chamfer, inset glass vanes and a cut lens.
-- The construction survives a low grazing camera and daylight on white sand.
local function waymark(parent, transform, unit, number)
	local lamp = S.group("Descent vane " .. number)
	local glass, eyes = {}, {}
	local plan = {
		V(-0.72, 0, 0.59),
		V(-0.80, 0, 0.39),
		V(-0.64, 0, -0.06),
		V(0, 0, -0.87),
		V(0.64, 0, -0.06),
		V(0.80, 0, 0.39),
		V(0.72, 0, 0.59),
		V(0, 0, 0.31),
	}
	local function world(p)
		return transform * (p * unit)
	end
	local function face(group, name, a, b, c, tone, mat)
		local first = if group then #lamp:GetChildren() else 0
		S.facet(lamp, name, world(a), world(b), world(c), tone, mat)
		if not group then
			return
		end
		local children = lamp:GetChildren()
		for j = first + 1, #children do
			table.insert(group, children[j])
		end
	end
	-- Each half is convex and shares the central nose/ridge with its mate.
	for i = 1, #plan do
		local a, b = plan[i], plan[i % #plan + 1]
		local mid = V(if i <= 3 or i == 8 then -0.30 else 0.30, 0.077, -0.01)
		local topA, topB = a * 0.90 + V(0, 0.089, 0), b * 0.90 + V(0, 0.089, 0)
		face(nil, "Cast brass edge", a, b, topA, if i % 3 == 0 then "BB9459" else "937748", metal)
		face(nil, "Cast brass edge", b, topB, topA, if i % 2 == 0 then "AE8854" else "8E744D", metal)
		face(nil, "Blue-black enamel", topA, topB, mid, if i % 2 == 0 then "213745" else "2D414A")
	end
	local nose, notch = plan[4] * 0.90 + V(0, 0.089, 0), plan[8] * 0.90 + V(0, 0.089, 0)
	for _, side in { -1, 1 } do
		face(nil, "Blue-black enamel", nose, notch, V(side * 0.30, 0.077, -0.01), "273D49")
	end
	for _, side in { -1, 1 } do
		local start = world(V(side * 0.57, 0.12, 0.35))
		local finish = world(V(0, 0.12, -0.415))
		S.strut(lamp, "Bevelled vane mount", start, finish, 0.265 * unit, 0.080 * unit, "B0925F", metal)
		local lift = Vector3.yAxis * 0.057 * unit
		table.insert(
			glass,
			S.strut(lamp, "Violet inset", start + lift, finish + lift, 0.156 * unit, 0.053 * unit, "49395D")
		)
		local fine = Vector3.yAxis * 0.034 * unit
		table.insert(
			eyes,
			S.strut(
				lamp,
				"Traveling reflection",
				start + lift + fine,
				finish + lift + fine,
				0.055 * unit,
				0.026 * unit,
				"595869"
			)
		)
		S.part(
			lamp,
			"Brass keeper",
			transform * CF(V(side * 0.58, 0.125, 0.44) * unit),
			V(0.075, 0.028, 0.07) * unit,
			"DEC08C",
			metal
		)
	end
	local socket = V(0, 0.118, -0.565)
	local foot = { V(-0.154, 0, 0), V(0, 0, -0.18), V(0.154, 0, 0), V(0, 0, 0.13) }
	for i, v in foot do
		local n = foot[i % 4 + 1]
		face(
			i % 2 == 0 and glass or eyes,
			"Cut signal lens",
			socket + v,
			socket + n,
			socket + V(0, 0.21, -0.016),
			if i % 2 == 0 then "594F8E" else "668480",
			Enum.Material.Glass
		)
	end
	local lead = S.part(lamp, "Lens station", transform, V(0.04, 0.04, 0.04) * unit, "FFFFFF")
	lead.Transparency, lead.CastShadow = 1, false
	local point = anchor(lead, "Route waypoint " .. number, socket * unit)
	local light = S.light(point, "8F83FF", 3.0 * unit, 0)
	light.Enabled, light.Shadows = false, false
	local surfaces = {}
	for _, part in lamp:GetChildren() do
		if part:IsA("BasePart") and part ~= lead then
			table.insert(surfaces, part)
		end
	end
	lamp.Parent = parent
	return { at = point, strokes = glass, eyes = eyes, surfaces = surfaces, light = light }
end

local scale = 32
local source = waymark(workspace, CFrame.identity, scale, 1)
local original = source.at.Parent.Parent
local model = Instance.new("Model")
model.Name = "ExpeditionVane"
local datum = source.at.Parent
datum.Name = "Lens station"
source.at.Name = "Route waypoint"
source.light.Name = "Route light"
datum.Parent, model.PrimaryPart = model, datum
local groups = { Bronze = {}, Enamel = {}, Violet = {}, Silver = {} }
for _, part in original:GetChildren() do
	local group = if table.find(source.strokes, part)
		then groups.Violet
		elseif table.find(source.eyes, part) then groups.Silver
		elseif part.Material == metal then groups.Bronze
		else groups.Enamel
	table.insert(group, part)
end
local options =
	{ SplitApart = false, CollisionFidelity = Enum.CollisionFidelity.Box, RenderFidelity = Enum.RenderFidelity.Precise }
for name, parts in groups do
	local first = table.remove(parts, 1)
	local solid = game:GetService("GeometryService"):UnionAsync(first, parts, options)[1]
	solid.Name, solid.SmoothingAngle, solid.CastShadow = name, 0, false
	solid.UsePartColor = name == "Violet" or name == "Silver"
	solid.Material = if name == "Bronze" then metal else Enum.Material.SmoothPlastic
	solid.Anchored, solid.CanCollide, solid.CanTouch, solid.CanQuery = true, false, false, false
	solid.Parent = model
end
model:ScaleTo(1 / scale)
local archive = Instance.new("Model")
archive.Name = model.Name
for _, obj in model:GetChildren() do
	obj.Parent = archive
end
archive.PrimaryPart = datum
local packed = game:GetService("SerializationService"):SerializeInstancesAsync({ archive })
local bytes = buffer.tostring(game:GetService("EncodingService"):Base64Encode(packed))
for i = 1, #bytes, 2000 do
	print("VANE_DATA", bytes:sub(i, i + 1999))
end
print("VANE_READY")
