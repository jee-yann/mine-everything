local Ores = require(script.Parent.Ores)
local Skills = { nodes = {}, byId = {} }
local byEffect = {}

local function branch(name, icon)
	return function(id, title, detail, x, y, requires, effect, amount, emblem)
		local node = {
			id = id,
			name = title,
			detail = detail,
			x = x,
			y = y,
			requires = requires,
			branch = name,
			icon = emblem or icon,
		}
		table.insert(Skills.nodes, node)
		Skills.byId[id] = node
		if effect then
			byEffect[effect] = byEffect[effect] or {}
			byEffect[effect][id] = amount
		end
	end
end

local pickwork = branch("Pickwork", "Power")
pickwork("Reach", "Long Arm I", "+5 studs of pick reach.", -180, -84, {}, "reach", 5, "Hook")
pickwork("ReachII", "Long Arm II", "+5 more studs of pick reach.", -365, -180, { "Reach" }, "reach", 5, "Hook")
pickwork("ReachIII", "Long Arm III", "+5 more studs of pick reach.", -550, -300, { "ReachII" }, "reach", 5, "Hook")
pickwork(
	"Tempo",
	"Steady Hands I",
	"Subtract 10% of base cut time on every block.",
	-460,
	-55,
	{ "ReachII" },
	"cut",
	10,
	"Tempo"
)
pickwork(
	"TempoII",
	"Steady Hands II",
	"Subtract another 10% of base cut time.",
	-645,
	-55,
	{ "Tempo" },
	"cut",
	10,
	"Tempo"
)
pickwork(
	"TempoIII",
	"Steady Hands III",
	"Subtract another 10% of base cut time (30% total).",
	-835,
	-55,
	{ "TempoII" },
	"cut",
	10,
	"Tempo"
)
pickwork("StoneSplit", "Fault Splitter", "Spend 15% less time cutting any grade of stone.", -730, -195, { "TempoII" })
pickwork(
	"GemCutter",
	"Facet Cutter",
	"Cut diamond and rarer gems in 20% less time.",
	-760,
	-340,
	{ "ReachIII", "StoneSplit" },
	nil,
	nil,
	"Crystal"
)

local lamplight = branch("Lamplight", "Lamp")
lamplight("Lamp", "Lantern Wick I", "+8 studs of personal lamp radius.", 180, -84, {}, "lamp", 8)
lamplight(
	"Lantern",
	"Lantern Wick II",
	"+8 more studs of personal lamp radius.",
	365,
	-180,
	{ "Lamp" },
	"lamp",
	8,
	"Beacon"
)
lamplight(
	"LanternIII",
	"Lantern Wick III",
	"+8 more studs of personal lamp radius.",
	550,
	-300,
	{ "Lantern" },
	"lamp",
	8,
	"Beacon"
)
lamplight("LongBurn", "Slow Burn I", "Survey flares burn 15 seconds longer.", 455, -55, { "Lantern" }, "burn", 15)
lamplight(
	"LongBurnII",
	"Slow Burn II",
	"Add 15 more seconds to each flare (60 seconds total).",
	640,
	-55,
	{ "LongBurn" },
	"burn",
	15
)
lamplight("FlareThrow", "Long Toss", "Throw survey flares up to 16 studs ahead.", 820, -55, { "LongBurnII" })
lamplight(
	"CaveEcho",
	"Cave Listener",
	"Flares sense natural caves within 15 blocks.",
	760,
	-220,
	{ "LongBurnII", "LanternIII" },
	nil,
	nil,
	"Beacon"
)

local survey = branch("Survey optics", "Beacon")
survey(
	"Focus",
	"Face Lantern",
	"Light the face you strike while you mine the block.",
	0,
	-210,
	{ "Reach", "Lamp" },
	"focus",
	9
)
survey("FocusII", "Wide Beam", "Widen your mining light from 9 to 15 studs.", 0, -380, { "Focus" }, "focus", 6)
survey(
	"Longbeam",
	"Prism Lens",
	"Gain 5 studs of reach. Known ores tint your light as you mine them.",
	-215,
	-415,
	{ "FocusII", "ReachII" },
	"reach",
	5
)
survey(
	"LightTrail",
	"Miner’s Fireflies",
	"Mined ore leaves a light for 15s. Keep up to four lit.",
	215,
	-415,
	{ "FocusII", "Lantern" }
)
survey(
	"Constellation",
	"Constellation",
	"Your ore lights last 30s and you can keep eight lit.",
	0,
	-565,
	{ "Longbeam", "LightTrail" }
)

local footwork = branch("Footwork", "Boot")
footwork("Stride", "Quick Feet I", "+3 walking speed.", 0, 155, {}, "walk", 3)
footwork("StrideII", "Quick Feet II", "+2 walking speed.", 150, 300, { "Stride" }, "walk", 2)
footwork("StrideIII", "Quick Feet III", "+2 more walking speed.", 145, 480, { "StrideII" }, "walk", 2)
footwork("Spring", "Spring Step I", "+25% jump height.", -65, 305, { "Stride" }, "jump", 25, "Spring")
footwork("Scout", "Trail Runner", "+3 walking speed.", -65, 455, { "Spring" }, "walk", 3)
footwork("SpringII", "Spring Step II", "+15% jump height (40% total).", -65, 610, { "Scout" }, "jump", 15, "Spring")
footwork(
	"Summit",
	"Summit Boots",
	"+10% jump height and +2 walking speed.",
	130,
	635,
	{ "StrideIII", "SpringII" },
	"walk",
	2,
	"Spring"
)

local hauling = branch("Hauling", "Inventory")
hauling("Pack", "Pack Stitch I", "+10% of your workshop bag’s base capacity.", -185, 85, {}, "pack", 10)
hauling("PackII", "Pack Stitch II", "Add another 10% of base bag capacity.", -365, 175, { "Pack" }, "pack", 10)
hauling(
	"PackIII",
	"Pack Stitch III",
	"Add another 10% of base capacity (30% total).",
	-550,
	265,
	{ "PackII" },
	"pack",
	10
)
hauling(
	"TemperKit",
	"Field Forge I",
	"Each fresh temper lasts 10 more hard cuts.",
	-470,
	65,
	{ "PackII" },
	"charges",
	10,
	"Power"
)
hauling(
	"TemperKitII",
	"Field Forge II",
	"Add 10 more temper charges (45 total).",
	-650,
	85,
	{ "TemperKit" },
	"charges",
	10,
	"Power"
)
hauling(
	"HotSteel",
	"Hot Steel",
	"Tempering now cuts hard-block mining time by 30%.",
	-850,
	95,
	{ "TemperKitII", "TempoIII" },
	nil,
	nil,
	"Power"
)
hauling(
	"PackMule",
	"Second Wind",
	"+3 walking speed while your pack is at least 75% full.",
	-235,
	318,
	{ "PackII", "Stride" },
	nil,
	nil,
	"Boot"
)
hauling(
	"DeepPockets",
	"Hidden Pockets",
	"Gain 24 extra slots after bag percentage bonuses.",
	-395,
	447,
	{ "PackIII", "PackMule" },
	"slots",
	24
)
hauling(
	"SupplyRunner",
	"Supply Runner",
	"Earn a second survey flare on each daily delivery.",
	-605,
	460,
	{ "DeepPockets" },
	nil,
	nil,
	"Jobs"
)

local geology = branch("Geology", "Crystal")
geology("Notes", "Field Notes I", "Earn +1 XP from every ore you mine.", 185, 85, {}, "oreXP", 1)
geology("NotesII", "Field Notes II", "Earn another +1 XP from every ore.", 365, 175, { "Notes" }, "oreXP", 1)
geology(
	"NotesIII",
	"Field Notes III",
	"Earn another +1 XP from every ore (+3 total).",
	550,
	280,
	{ "NotesII" },
	"oreXP",
	1
)
geology(
	"FirstFind",
	"First Edition I",
	"Earn +10 XP the first time you mine each ore.",
	470,
	65,
	{ "NotesII" },
	"discoveryXP",
	10,
	"Jobs"
)
geology(
	"FirstFindII",
	"First Edition II",
	"Add 15 more first-discovery XP (+25 total).",
	655,
	90,
	{ "FirstFind" },
	"discoveryXP",
	15,
	"Jobs"
)
geology("DeepStudy", "Deep Survey", "Ore mined at 185+ blocks earns +3 XP.", 825, 205, { "FirstFindII", "NotesIII" })
geology("RareStudy", "Gem Journal", "Diamond and rarer gems earn +4 XP.", 765, 375, { "NotesIII" })
geology(
	"Rockhound",
	"Rockhound",
	"+3 walking speed while carrying diamond or a rarer gem.",
	370,
	425,
	{ "NotesII", "StrideII" },
	nil,
	nil,
	"Boot"
)

function Skills.ready(node, owned)
	for _, id in node.requires do
		if not owned[id] then
			return false
		end
	end
	return true
end

function Skills.read(player)
	local owned = {}
	for _, node in Skills.nodes do
		if player:GetAttribute("Skill" .. node.id) then
			owned[node.id] = true
		end
	end
	return owned
end

function Skills.bonus(owned, effect)
	local total = 0
	if owned then
		for id, amount in byEffect[effect] do
			if owned[id] then
				total += amount
			end
		end
	end
	return total
end

function Skills.capacity(base, owned)
	-- A 10% Pack Stitch grants at least one usable slot on the starter bag.
	local stitchSlots = math.floor(math.max(base, 10) * Skills.bonus(owned, "pack") / 100)
	return base + stitchSlots + Skills.bonus(owned, "slots")
end

function Skills.isGem(ore)
	return ore.hardness >= 5
end

function Skills.walkSpeed(owned, bag, used, capacity)
	local speed = 16 + Skills.bonus(owned, "walk")
	if owned.PackMule and used * 4 >= capacity * 3 then
		speed += 3
	end
	if owned.Rockhound then
		for name, count in bag do
			if count > 0 and Skills.isGem(Ores.byName[name]) then
				return speed + 3
			end
		end
	end
	return speed
end

function Skills.oreXP(ore, owned, first, depth)
	if ore.host then
		return 0
	end
	local xp = ore.xp + Skills.bonus(owned, "oreXP")
	if first then
		xp += Skills.bonus(owned, "discoveryXP")
	end
	if owned.DeepStudy and depth >= 185 then
		xp += 3
	end
	return xp + (if owned.RareStudy and Skills.isGem(ore) then 4 else 0)
end

function Skills.cutTime(base, ore, strength, charges, owned)
	local duration, tempered = Ores.cutTime(base, ore, strength, charges, if owned.HotSteel then 0.7 else nil)
	duration *= (100 - Skills.bonus(owned, "cut")) / 100
	if owned.StoneSplit and ore.name == "Stone" then
		duration *= 0.85
	elseif owned.GemCutter and Skills.isGem(ore) then
		duration *= 0.8
	end
	return duration, tempered
end

return Skills
