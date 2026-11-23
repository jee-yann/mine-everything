-- Low-poly building blocks for the Ink & Facet look, plus the recipes OreLooks names.
-- Everything is drawn in the plane of one six-stud face: x right, y up, z out of the face.
-- Keep each ore face under 50 parts (tests/Mine.spec.luau checks the budget).
local Kit = {}

local V = Vector3.new
local LIGHT = Vector2.new(-0.55, 0.83).Unit -- upper left, matching the mine's key light
local plastic, neon = Enum.Material.SmoothPlastic, Enum.Material.Neon

export type Palette = { Color3 }
export type Look = {
	palette: Palette,
	accent: Palette?,
	glow: Color3?,
	sparkle: boolean?,
	ink: Color3,
	host: Color3?,
}

function Kit.shade(palette: Palette, t: number): Color3
	t = math.clamp(t, 0, 1) * (#palette - 1)
	local i = math.min(math.floor(t), #palette - 2)
	return palette[i + 1]:Lerp(palette[i + 2], t - i)
end
local shade = Kit.shade

function Kit.piece(
	model: Model,
	class: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): BasePart
	local p = Instance.new(class) :: BasePart
	p.Name, p.Size, p.CFrame, p.Color, p.Material = "Facet", size, cf, color, material or plastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Parent = model
	return p
end
local piece = Kit.piece

-- Split a scalene facet at the altitude of its longest edge. Two native wedges catch the mine lighting.
function Kit.triangle(m: Model, a: Vector3, b: Vector3, c: Vector3, color: Color3, material: Enum.Material?)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right, back = ac:Cross(ab).Unit, bc.Unit
	local up = bc:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	local function half(mid: Vector3, normal: Vector3, axis: Vector3, length: number)
		if length > 0.05 then
			piece(m, "WedgePart", V(0.045, height, length), CFrame.fromMatrix(mid, normal, up, axis), color, material)
		end
	end
	half((a + b) / 2, right, back, math.abs(ab:Dot(back)))
	half((a + c) / 2, -right, -back, math.abs(ac:Dot(back)))
end
local triangle = Kit.triangle

-- A faceted dome: a fan of triangles rising to an apex nudged toward the light.
function Kit.dome(
	m: Model,
	x: number,
	y: number,
	r: number,
	sides: number,
	lift: number,
	palette: Palette,
	rng: Random,
	opts: { [string]: any }?
)
	local o = opts or {}
	local base, jitter, squash = o.base or 0.06, o.jitter or 0.15, o.squash or 1
	local turn = o.turn or rng:NextNumber(0, 2 * math.pi)
	local rim = table.create(sides)
	for i = 1, sides do
		local a = turn + (i - 1) / sides * 2 * math.pi
		local rr = r * (1 + rng:NextNumber(-jitter, jitter))
		rim[i] = V(x + rr * math.cos(a), y + rr * math.sin(a) * squash, base)
	end
	local apex = V(x + LIGHT.X * r * 0.3, y + LIGHT.Y * r * 0.3, base + lift)
	for i = 1, sides do
		local a, b = rim[i], rim[i % sides + 1]
		local out = Vector2.new((a.X + b.X) / 2 - apex.X, (a.Y + b.Y) / 2 - apex.Y).Unit
		triangle(m, a, b, apex, shade(palette, 0.08 + 0.88 * (0.5 + 0.5 * out:Dot(LIGHT))), o.material)
	end
	return rim
end

-- A thin flat disc lying on the face at height z.
function Kit.disc(m: Model, x: number, y: number, r: number, z: number, color: Color3)
	local p = piece(m, "Part", V(0.04, r * 2, r * 2), CFrame.new(x, y, z) * CFrame.Angles(0, math.pi / 2, 0), color)
	p.Shape = Enum.PartType.Cylinder
	p.Size = V(0.04, r * 2, r * 2)
end

-- A thin ink disc under a piece, so round shapes read as outlined at any distance.
function Kit.rim(m: Model, x: number, y: number, r: number, ink: Color3)
	Kit.disc(m, x, y, r, 0.035, ink)
end

-- A flattened ellipsoid: pebbles, patina, rust and highlights.
function Kit.blob(
	m: Model,
	x: number,
	y: number,
	w: number,
	h: number,
	degrees: number,
	z: number,
	color: Color3,
	material: Enum.Material?
)
	local p =
		piece(m, "Part", V(w, h, 0.3), CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(degrees)), color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Sphere, p
end

-- A straight flat bar between two points in the face plane: veins, cracks and ink lines.
function Kit.bar(m: Model, a: Vector2, b: Vector2, width: number, z: number, color: Color3, material: Enum.Material?)
	local d = b - a
	piece(
		m,
		"Part",
		V(d.Magnitude + width * 0.6, width, 0.08),
		CFrame.new((a.X + b.X) / 2, (a.Y + b.Y) / 2, z) * CFrame.Angles(0, 0, math.atan2(d.Y, d.X)),
		color,
		material
	)
end

-- A white four-point glint.
function Kit.sparkle(m: Model, x: number, y: number, size: number, z: number)
	for _, turn in { 0, math.pi / 2 } do
		piece(
			m,
			"Part",
			V(size, size * 0.12, 0.05),
			CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 4 + turn),
			Color3.new(1, 1, 1),
			neon
		)
	end
end

-- A crystal that breaks out of the face along (lean.X, lean.Y, 1). Square body turned 45° so a
-- corner faces the viewer, topped with a ridge tip (two wedges) or a flat cap.
function Kit.spike(
	m: Model,
	x: number,
	y: number,
	height: number,
	width: number,
	lean: Vector2,
	palette: Palette,
	tipMaterial: Enum.Material?,
	flat: boolean?
)
	local axis = V(lean.X, lean.Y, 1).Unit
	local right = axis:Cross(Vector3.zAxis)
	right = if right.Magnitude < 1e-3 then Vector3.xAxis else right.Unit
	local back = right:Cross(axis).Unit
	local tipLength = if flat then 0 else width * 0.85
	local bodyLength = height - tipLength
	local foot = V(x, y, -0.25)
	local frame = CFrame.fromMatrix(foot + axis * (bodyLength / 2), right, axis, back)
		* CFrame.Angles(0, math.rad(45), 0)
	piece(m, "Part", V(width, bodyLength, width), frame, shade(palette, 0.5))
	if flat then
		piece(
			m,
			"Part",
			V(width * 0.96, 0.08, width * 0.96),
			frame * CFrame.new(0, bodyLength / 2 + 0.03, 0),
			shade(palette, 0.95),
			tipMaterial
		)
	else
		local top = frame * CFrame.new(0, (bodyLength + tipLength) / 2, 0)
		local size = V(width, tipLength, width / 2)
		piece(
			m,
			"WedgePart",
			size,
			top * CFrame.new(0, 0, width / 4) * CFrame.Angles(0, math.pi, 0),
			shade(palette, 0.9),
			tipMaterial
		)
		piece(m, "WedgePart", size, top * CFrame.new(0, 0, -width / 4), shade(palette, 0.72), tipMaterial)
	end
end

-- A hexagonal crystal standing out of the face along (lean.X, lean.Y, 1). Three boxes turned 60°
-- apart make the six sides (each box's long faces sit on the hexagon's edges), and a smaller,
-- lighter hexagon caps the flat top, like a real emerald.
function Kit.hexPrism(m: Model, x: number, y: number, height: number, radius: number, lean: Vector2, palette: Palette)
	local axis = V(lean.X, lean.Y, 1).Unit
	local right = axis:Cross(Vector3.zAxis)
	right = if right.Magnitude < 1e-3 then Vector3.xAxis else right.Unit
	local back = right:Cross(axis).Unit
	local frame = CFrame.fromMatrix(V(x, y, -0.25) + axis * (height / 2), right, axis, back)
	local size = V(radius, height, radius * math.sqrt(3))
	for k = 0, 2 do
		piece(m, "Part", size, frame * CFrame.Angles(0, k * math.pi / 3, 0), shade(palette, 0.4 + 0.12 * k))
	end
	local cap = frame * CFrame.new(0, height / 2 + 0.03, 0)
	for k = 0, 2 do
		piece(
			m,
			"Part",
			V(size.X * 0.8, 0.08, size.Z * 0.8),
			cap * CFrame.Angles(0, k * math.pi / 3, 0),
			shade(palette, 0.95)
		)
	end
end

-- An octahedron standing out of the face.
function Kit.octahedron(
	m: Model,
	x: number,
	y: number,
	w: number,
	h: number,
	palette: Palette,
	material: Enum.Material?
)
	local waist = h * 0.45
	local top, foot = V(x - 0.06 * w, y + 0.05 * w, h), V(x, y, -0.15)
	local ring = table.create(4)
	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2 + math.pi / 4
		ring[i] = V(x + w / 2 * math.cos(a), y + w / 2 * math.sin(a), waist)
	end
	for i = 1, 4 do
		local a, b = ring[i], ring[i % 4 + 1]
		local t = 0.5 + 0.5 * Vector2.new((a.X + b.X) / 2 - x, (a.Y + b.Y) / 2 - y).Unit:Dot(LIGHT)
		triangle(m, a, b, top, shade(palette, 0.35 + 0.65 * t), material)
		triangle(m, a, b, foot, shade(palette, 0.1 + 0.45 * t), material)
	end
end

-- ---------- flush recipes (OreLooks `relief` and Rock `decor`) ----------
local recipes: { [string]: (Model, Look, Random) -> () } = {}
Kit.recipes = recipes

function recipes.lumps(m: Model, look: Look, rng: Random)
	local p = look.palette
	for _, s in { { -0.9, 0.35, 1.3, 7, 0.5 }, { 1.2, 1.0, 0.8, 5, 0.32 }, { 1.05, -1.15, 0.9, 5, 0.36 } } do
		Kit.rim(m, s[1], s[2], s[3] * 1.12, look.ink)
		Kit.dome(m, s[1], s[2], s[3], s[4], s[5], p, rng)
	end
	Kit.blob(m, -1.25, 0.85, 0.32, 0.2, 30, 0.42, p[4])
end

-- Copper nuggets sitting in cradles of banded green malachite (copper).
function recipes.malachite(m: Model, look: Look, rng: Random)
	local p, green = look.palette, look.accent or look.palette
	for i, s in { { -0.42, 0.3, 1.2, 7 }, { 1.56, -1.44, 0.66, 5 }, { 1.5, 1.5, 0.52, 5 } } do
		local x, y, r = s[1], s[2], s[3]
		-- the cradle sits a little toward the shadow side, so it shows as a crescent
		local cx, cy = x - LIGHT.X * r * 0.28, y - LIGHT.Y * r * 0.28
		Kit.rim(m, cx, cy, r * 1.42, look.ink)
		Kit.disc(m, cx, cy, r * 1.32, 0.055, shade(green, 0.15))
		if i == 1 then
			Kit.disc(m, cx, cy, r * 1.18, 0.075, shade(green, 0.55))
		end
		Kit.disc(m, cx, cy, r * 1.06, 0.095, shade(green, 0.8))
		Kit.rim(m, x, y, r * 1.08, look.ink)
		Kit.dome(m, x, y, r, s[4], r * 0.45, p, rng, { base = 0.14 })
	end
end

-- Angular metal chunks (iron). An `accent` palette adds stains, such as rust.
function recipes.chunks(m: Model, look: Look, rng: Random)
	local p, stain = look.palette, look.accent
	for i, s in { { -0.5, 0.3, 1.65, 6 }, { 1.7, -1.45, 0.72, 5 }, { 1.62, 1.55, 0.6, 5 } } do
		Kit.rim(m, s[1], s[2], s[3] * 1.1, look.ink)
		Kit.dome(m, s[1], s[2], s[3], s[4], s[3] * 0.32, p, rng, { jitter = 0.1 })
		for k = 1, if stain == nil then 0 elseif i == 1 then 3 else 1 do
			local a = rng:NextNumber(-0.6, 0.6) - math.pi / 3
			local d = s[3] * rng:NextNumber(0.25, 0.55)
			local size = s[3] * rng:NextNumber(0.42, 0.6)
			Kit.blob(
				m,
				s[1] + d * math.cos(a),
				s[2] + d * math.sin(a),
				size,
				size * 0.7,
				rng:NextNumber(0, 180),
				0.12 + s[3] * 0.16,
				shade(stain :: Palette, (k - 1) / 2)
			)
		end
	end
end

-- One big shiny nugget with two satellites (gold).
function recipes.nugget(m: Model, look: Look, rng: Random)
	local p = look.palette
	for _, s in { { -0.4, 0.3, 1.6, 8, 0.62 }, { 1.75, -1.35, 0.62, 5, 0.3 }, { 1.62, 1.55, 0.48, 5, 0.26 } } do
		Kit.rim(m, s[1], s[2], s[3] * 1.1, look.ink)
		Kit.dome(m, s[1], s[2], s[3], s[4], s[5], p, rng, { jitter = 0.13 })
	end
	Kit.blob(m, -0.95, 0.85, 0.62, 0.36, 25, 0.5, p[4])
	Kit.sparkle(m, -1.25, 1.45, 0.9, 0.62)
	Kit.sparkle(m, 2.1, -0.75, 0.5, 0.35)
end

-- Flush octahedra seen from above (diamond).
function recipes.octahedra(m: Model, look: Look, _rng: Random)
	local p = look.palette
	for _, s in { { -0.75, 0.45, 1.35, 1.65 }, { 1.45, -1.2, 0.75, 0.95 } } do
		local x, y, w, h = s[1], s[2], s[3], s[4]
		local apex = V(x - 0.1 * w, y + 0.1 * w, 0.5 * w)
		local top, right, bottom, left = V(x, y + h, 0.05), V(x + w, y, 0.05), V(x, y - h, 0.05), V(x - w, y, 0.05)
		triangle(m, left, top, apex, shade(p, 1))
		triangle(m, top, right, apex, shade(p, 0.68))
		triangle(m, bottom, left, apex, shade(p, 0.5))
		triangle(m, right, bottom, apex, shade(p, 0.22))
	end
	Kit.sparkle(m, -1.3, 1.5, 0.8, 0.6)
end

-- Hexagonal crystal ends (emerald).
function recipes.hexes(m: Model, look: Look, rng: Random)
	local p = look.palette
	Kit.dome(m, -0.6, 0.35, 1.25, 6, 0.3, p, rng, { jitter = 0.03, turn = 0.1 })
	Kit.dome(m, 1.45, -1.25, 0.78, 6, 0.22, p, rng, { jitter = 0.03, turn = 0.4 })
	Kit.sparkle(m, -1.2, 1.2, 0.7, 0.45)
end

-- An agate-rimmed geode with crystal points (amethyst).
function recipes.geode(m: Model, look: Look, rng: Random)
	local p = look.palette
	local host = look.host or Color3.fromRGB(70, 66, 90)
	for i, s in { { 2.45, host:Lerp(Color3.new(), 0.35) }, { 2.05, Color3.fromRGB(214, 206, 226) }, { 1.78, p[1] } } do
		local disc = piece(
			m,
			"Part",
			V(0.05, s[1] * 2, s[1] * 2),
			CFrame.new(0, 0, 0.02 + i * 0.03) * CFrame.Angles(0, math.pi / 2, 0),
			s[2]
		)
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = V(0.05, s[1] * 2, s[1] * 2)
	end
	local k = 9
	for i = 1, k do
		local a = (i - 1) / k * 2 * math.pi + rng:NextNumber(-0.08, 0.08)
		local w = math.pi / k
		local tip = rng:NextNumber(0.45, 0.85)
		local facing = 0.5 - 0.5 * Vector2.new(math.cos(a), math.sin(a)):Dot(LIGHT)
		triangle(
			m,
			V(1.72 * math.cos(a - w), 1.72 * math.sin(a - w), 0.12),
			V(1.72 * math.cos(a + w), 1.72 * math.sin(a + w), 0.12),
			V(tip * math.cos(a), tip * math.sin(a), 0.4),
			shade(p, 0.3 + 0.65 * facing)
		)
	end
	Kit.sparkle(m, -0.6, 0.7, 0.6, 0.45)
end

-- Hexagonal barrels lying on the face (sapphire).
function recipes.barrels(m: Model, look: Look, _rng: Random)
	local p = look.palette
	for _, s in { { -0.5, 0.3, 1.8, -20 }, { 1.55, -1.1, 1.0, 25 } } do
		local x, y, r = s[1], s[2], s[3]
		local w = 0.45 * r
		local c, sn = math.cos(math.rad(s[4])), math.sin(math.rad(s[4]))
		local function at(px: number, py: number, z: number): Vector3
			return V(x + px * c - py * sn, y + px * sn + py * c, z)
		end
		local rim = {
			at(0, r, 0.06),
			at(w, 0.42 * r, 0.06),
			at(w, -0.42 * r, 0.06),
			at(0, -r, 0.06),
			at(-w, -0.42 * r, 0.06),
			at(-w, 0.42 * r, 0.06),
		}
		local ridge = at(-0.15 * w, 0, 0.45 * w)
		for i = 1, 6 do
			local a, b = rim[i], rim[i % 6 + 1]
			local t = 0.5 + 0.5 * Vector2.new((a.X + b.X) / 2 - ridge.X, (a.Y + b.Y) / 2 - ridge.Y).Unit:Dot(LIGHT)
			triangle(m, a, b, ridge, shade(p, 0.12 + 0.85 * t))
		end
	end
	Kit.sparkle(m, -1.1, 1.55, 0.7, 0.5)
end

-- Dark glass shards split by glowing cracks (emberglass).
function recipes.shards(m: Model, look: Look, rng: Random)
	local p, glow = look.palette, look.glow or Color3.new(1, 0.5, 0.4)
	for _, s in { { -0.6, 0.45, 1.6, -0.5 }, { 1.1, -0.85, 1.2, 0.6 }, { -1.3, -1.45, 0.8, 1.9 } } do
		local x, y, r, a = s[1], s[2], s[3], s[4]
		local function at(px: number, py: number, z: number): Vector3
			return V(x + px * math.cos(a) - py * math.sin(a), y + px * math.sin(a) + py * math.cos(a), z)
		end
		local tip, right, foot, left =
			at(0, r, 0.3), at(0.4 * r, -0.25 * r, 0.06), at(-0.1 * r, -0.6 * r, 0.06), at(-0.42 * r, -0.1 * r, 0.06)
		triangle(m, tip, left, foot, shade(p, 0.65))
		triangle(m, tip, foot, right, shade(p, 0.25))
	end
	for _ = 1, 3 do
		local at = Vector2.new(rng:NextNumber(-1.5, 1.5), rng:NextNumber(-1.5, 1.5))
		local heading = rng:NextNumber(0, 2 * math.pi)
		for _ = 1, 3 do
			heading += rng:NextNumber(-0.7, 0.7)
			local nextAt = at + Vector2.new(math.cos(heading), math.sin(heading)) * 0.65
			Kit.bar(m, at, nextAt, 0.09, 0.14, glow, neon)
			at = nextAt
		end
	end
end

-- An eight-point star with a glowing core (Starfall).
function recipes.star(m: Model, look: Look, _rng: Random)
	local p, glow = look.palette, look.glow or Color3.new(1, 1, 1)
	local apex = V(-0.1, 0.12, 0.45)
	local rim = table.create(8)
	for i = 1, 8 do
		local a = (i - 1) * math.pi / 4 + math.pi / 2 + 0.12
		local r = if i % 2 == 1 then 2.15 else 0.8
		rim[i] = V(r * math.cos(a), r * math.sin(a), 0.06)
	end
	for i = 1, 8 do
		local a, b = rim[i], rim[i % 8 + 1]
		local t = 0.5 + 0.5 * Vector2.new((a.X + b.X) / 2, (a.Y + b.Y) / 2).Unit:Dot(LIGHT)
		triangle(m, a, b, apex, shade(p, 0.15 + 0.82 * t))
	end
	Kit.blob(m, -0.1, 0.12, 0.6, 0.6, 0, 0.42, glow, neon)
	Kit.sparkle(m, -1.9, 1.75, 0.6, 0.2)
	Kit.sparkle(m, 1.85, -1.8, 0.5, 0.2)
end

-- Rock decor: little dark specks of soil (dirt).
function recipes.specks(m: Model, look: Look, rng: Random)
	local p = look.palette
	for _ = 1, 9 do
		local r = rng:NextNumber(0.05, 0.11)
		Kit.disc(m, rng:NextNumber(-2.6, 2.6), rng:NextNumber(-2.6, 2.6), r, 0.04, shade(p, rng:NextNumber(0, 0.3)))
	end
end

-- Rock decor: an ink crack and two chips (stone).
function recipes.cracks(m: Model, look: Look, rng: Random)
	local at = Vector2.new(rng:NextNumber(0.4, 1.6), 2.9)
	local heading = -math.pi / 2 - 0.4
	local points = { at }
	for _ = 1, 4 do
		heading += rng:NextNumber(-0.6, 0.6)
		at += Vector2.new(math.cos(heading), math.sin(heading)) * 0.65
		table.insert(points, at)
	end
	for i = 1, #points - 1 do
		Kit.bar(m, points[i], points[i + 1], 0.08, 0.04, look.ink)
	end
	Kit.bar(m, points[3], points[3] + Vector2.new(0.55, -0.15), 0.06, 0.04, look.ink)
	Kit.blob(m, -1.5, 1.2, 0.5, 0.36, rng:NextNumber(0, 90), 0.06, shade(look.palette, 0.7))
	Kit.blob(m, -1.2, -1.4, 0.36, 0.26, rng:NextNumber(0, 90), 0.06, shade(look.palette, 0.55))
end

-- Rock decor: small calcite points on cave ceilings.
-- A small chalky pocket with a broken edge, set into the host rock (cave ceilings).
function recipes.calcite(m: Model, look: Look, rng: Random)
	local p = look.palette
	local turn = rng:NextNumber(-12, 12)
	Kit.blob(m, -0.16, 0.06, 1.55, 0.84, -14 + turn, 0.04, shade(p, 0))
	Kit.spike(m, -0.34, 0.08, 0.62, 0.38, Vector2.new(-0.15, 0.1), p)
	Kit.spike(m, 0.36, -0.11, 0.5, 0.29, Vector2.new(0.2, -0.05), p)
	Kit.blob(m, 0.72, -0.39, 0.28, 0.16, -36 + turn, 0.06, shade(p, 0.55))
end

-- ---------- crowns: crystals that break out of the face ----------
local crowns: { [string]: (Model, Look) -> () } = {}
Kit.crowns = crowns

local function tipMaterial(look: Look): Enum.Material?
	return if look.glow then neon else nil
end

function crowns.octahedron(m: Model, look: Look)
	Kit.octahedron(m, -0.3, 0.3, 1.5, 2.3, look.palette)
	Kit.sparkle(m, -0.4, 0.45, 0.9, 2.45)
end

function crowns.prisms(m: Model, look: Look)
	for _, s in
		{
			{ 0, 0.2, 2.3, 0.52, -0.05, 0.05 },
			{ 1.0, -0.5, 1.55, 0.4, 0.25, -0.15 },
			{ -0.9, -0.7, 1.2, 0.34, -0.3, -0.2 },
		}
	do
		Kit.hexPrism(m, s[1], s[2], s[3], s[4], Vector2.new(s[5], s[6]), look.palette)
	end
	Kit.sparkle(m, -0.15, 0.45, 0.8, 2.45)
end

function crowns.cluster(m: Model, look: Look)
	for _, s in
		{
			{ 0, 0.15, 2.7, 0.55, -0.04, 0.05 },
			{ 0.85, -0.45, 1.8, 0.42, 0.3, -0.12 },
			{ -0.85, -0.3, 1.7, 0.42, -0.32, -0.06 },
			{ 0.2, -1.0, 1.2, 0.34, 0.12, -0.35 },
		}
	do
		Kit.spike(m, s[1], s[2], s[3], s[4], Vector2.new(s[5], s[6]), look.palette, tipMaterial(look))
	end
end

function crowns.spires(m: Model, look: Look)
	for _, s in
		{
			{ -0.1, 0.1, 2.2, 0.62, -0.08, 0.06 },
			{ 1.0, -0.5, 1.5, 0.48, 0.3, -0.12 },
			{ -0.95, -0.6, 1.2, 0.42, -0.3, -0.2 },
		}
	do
		Kit.spike(m, s[1], s[2], s[3], s[4], Vector2.new(s[5], s[6]), look.palette, nil)
	end
end

function crowns.blades(m: Model, look: Look)
	for _, s in
		{
			{ -0.1, 0.2, 2.1, 0.5, -0.25, 0.1 },
			{ 0.9, -0.4, 1.6, 0.42, 0.32, -0.08 },
			{ -0.8, -0.7, 1.2, 0.38, -0.35, -0.25 },
		}
	do
		Kit.spike(m, s[1], s[2], s[3], s[4], Vector2.new(s[5], s[6]), look.palette, tipMaterial(look))
	end
end

return Kit
