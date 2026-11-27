local Ores = require(script.Parent.Ores)
local FieldRewards = require(script.Parent.FieldRewards)
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
hauling("Pack", "Pack Stitch I", "+10% of your workshop bag’s base block limit.", -185, 85, {}, "pack", 10)
hauling("PackII", "Pack Stitch II", "Add another 10% of the base block limit.", -365, 175, { "Pack" }, "pack", 10)
hauling(
	"PackIII",
	"Pack Stitch III",
	"Add another 10% of the base block limit (30% total).",
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
	"Your pack holds 24 more blocks after percentage bonuses.",
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

hauling("Broker", "Fair Trade", "Earn 10% more on each piece of ore you sell, rounded to the nearest gold.", -780, 305, { "PackIII" }, nil, nil, "Coins")

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
-- Fresh Find (once First Edition, which only paid for each ore's first find and then went dead):
-- XP for an ore you aren't carrying any of, which keeps paying for good.
geology(
	"FirstFind",
	"Fresh Find I",
	"Earn +10 XP from an ore you aren't carrying any of.",
	470,
	65,
	{ "NotesII" },
	"freshXP",
	10,
	"Jobs"
)
geology(
	"FirstFindII",
	"Fresh Find II",
	"Earn another +15 XP from an ore you aren't carrying (+25 total).",
	655,
	90,
	{ "FirstFind" },
	"freshXP",
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

geology("Fortune", "Fortune", "One cut in ten gives you two pieces of ore if your pack has room.", 615, 565, { "RareStudy" }, nil, nil, "Crystal")


-- More skills (the outer ring). Each family has one rule below in Skills.cutTime, Skills.oreXP,
-- Bonuses or Profile, so a skill is never just a number on a card.
-- Momentum: speed from mining well.
local momentum = branch("Momentum", "Flame")
momentum("HotStreak", "Hot Streak I", "Each ore mined in a row cuts 4% faster, up to 5 in a row. Stone breaks the streak.", -1020, -140, { "TempoIII" }, "streakStep", 4)
momentum("HotStreakII", "Hot Streak II", "Your streak builds up to 8 in a row.", -1200, -230, { "HotStreak" }, "streakCap", 3)
momentum("HotStreakIII", "Hot Streak III", "Each ore in your streak cuts 6% faster.", -1380, -320, { "HotStreakII" }, "streakStep", 2)
momentum("StreakKeeper", "Streak Keeper", "One stone block in a row doesn't break your streak.", -1380, -140, { "HotStreakII" })
momentum("StoneBreaker", "Stone Breaker I", "Cut plain stone 8% faster.", -1020, 40, { "TempoIII" }, "stone", 8, "Power")
momentum("StoneBreakerII", "Stone Breaker II", "Cut plain stone another 8% faster.", -1200, 90, { "StoneBreaker" }, "stone", 8, "Power")
momentum("Deepcutter", "Deepcutter", "Cut 8% faster 300 or more blocks down.", -1380, 220, { "StoneBreakerII" }, "deep", 8, "Power")
momentum("CraterVeteran", "Crater Veteran", "Cut 10% faster in the Starfall Crater.", -1560, 130, { "Deepcutter" }, "crater", 10, "Flame")
momentum("FacetCutterII", "Facet Cutter II", "Cut diamond and rarer gems another 10% faster.", -940, -430, { "GemCutter" }, "gem", 10, "Crystal")
momentum("RareTouch", "Rare Touch", "Cut Epic and rarer ores 10% faster.", -1120, -500, { "FacetCutterII" }, "rare", 10, "Crystal")
momentum("ReachIV", "Long Arm IV", "+5 more studs of pick reach.", -600, -470, { "ReachIII" }, "reach", 5, "Hook")

-- Showmanship: mining near other miners.
local showmanship = branch("Showmanship", "Showoff")
showmanship("ShowOff", "Show Off I", "Cut 5% faster with another miner within 30 studs.", 0, -740, { "Constellation" }, "crowdCut", 5)
showmanship("ShowOffII", "Show Off II", "Cut another 5% faster near another miner.", -180, -830, { "ShowOff" }, "crowdCut", 5)
showmanship("ShowOffIII", "Show Off III", "Cut another 5% faster near another miner (15% in all).", -360, -920, { "ShowOffII" }, "crowdCut", 5)
showmanship("CrowdPleaser", "Crowd Pleaser I", "+5% XP with another miner within 30 studs.", 180, -830, { "ShowOff" }, "crowdXP", 5, "Friends")
showmanship("CrowdPleaserII", "Crowd Pleaser II", "Another +5% XP near another miner.", 360, -920, { "CrowdPleaser" }, "crowdXP", 5, "Friends")
showmanship("CashOut", "Cash Out Crew I", "+4% gold from sales with another miner within 30 studs.", 0, -920, { "ShowOff" }, "crowdGold", 4, "Coins")
showmanship("CashOutII", "Cash Out Crew II", "Another +4% gold near another miner.", 0, -1100, { "CashOut" }, "crowdGold", 4, "Coins")
showmanship("CashOutIII", "Cash Out Crew III", "Another +4% gold near another miner (12% in all).", 0, -1280, { "CashOutII" }, "crowdGold", 4, "Coins")

-- Scholar: experience.
local scholar = branch("Scholar", "Book")
scholar("Scholar", "Scholar I", "+3% XP from everything you mine.", 1010, 120, { "DeepStudy" }, "xpPercent", 3)
scholar("ScholarII", "Scholar II", "Another +3% XP.", 1190, 60, { "Scholar" }, "xpPercent", 3)
scholar("ScholarIII", "Scholar III", "Another +3% XP.", 1370, 0, { "ScholarII" }, "xpPercent", 3)
scholar("ScholarIV", "Scholar IV", "Another +3% XP.", 1370, 180, { "ScholarIII" }, "xpPercent", 3)
scholar("ScholarV", "Scholar V", "Another +3% XP (15% in all).", 1550, 90, { "ScholarIV" }, "xpPercent", 3)
scholar("AbyssScholar", "Abyss Scholar", "Ore mined 340 or more blocks down earns +5 XP.", 1010, 300, { "DeepStudy" }, "deepXP", 5, "Crystal")
scholar("CraterScholar", "Crater Scholar", "Ore mined in the Starfall Crater earns +8 XP.", 1190, 360, { "AbyssScholar" }, "craterXP", 8, "Flame")
scholar("GemJournalII", "Gem Journal II", "Diamond and rarer gems earn another +4 XP.", 950, 470, { "RareStudy" }, "gemXP", 4, "Crystal")
scholar("CleanCut", "Clean Cut", "Pieces of 90% purity or better earn +5 XP.", 1130, 540, { "GemJournalII" }, "pureXP", 5, "Assay")
scholar("LanternIV", "Lantern Wick IV", "+8 more studs of personal lamp radius.", 735, -420, { "LanternIII" }, "lamp", 8, "Lamp")
scholar("LongBurnIII", "Slow Burn III", "Survey flares burn another 15 seconds.", 1000, -150, { "FlareThrow" }, "burn", 15, "Beacon")

-- Assaying: purity and luck.
local assaying = branch("Assaying", "Assay")
assaying("Assayer", "Assayer I", "10% of your finds roll purity twice and keep the better.", 800, 650, { "Fortune" }, "assay", 10)
assaying("AssayerII", "Assayer II", "20% of your finds roll purity twice.", 980, 720, { "Assayer" }, "assay", 10)
assaying("AssayerIII", "Assayer III", "30% of your finds roll purity twice.", 1160, 790, { "AssayerII" }, "assay", 10)
assaying("Polish", "Polish", "Nothing you mine is under 55% purity.", 980, 900, { "AssayerII" })
assaying("FortuneII", "Fortune II", "One ore cut in seven gives two pieces, not one in ten.", 615, 760, { "Fortune" }, nil, nil, "Crystal")
assaying("LuckyStrike", "Lucky Strike I", "+5% luck: ores rarer than 1% turn up a little more.", 430, 720, { "Fortune" }, "luck", 5, "Clover")
assaying("LuckyStrikeII", "Lucky Strike II", "Another +5% luck.", 430, 900, { "LuckyStrike" }, "luck", 5, "Clover")
assaying("LuckyStrikeIII", "Lucky Strike III", "Another +5% luck (15% in all).", 615, 950, { "LuckyStrikeII" }, "luck", 5, "Clover")

-- Trade: gold, supplies and the pack.
local trade = branch("Trade", "Coins")
trade("Haggler", "Haggler I", "+3% gold from every sale.", -960, 360, { "Broker" }, "gold", 3)
trade("HagglerII", "Haggler II", "Another +3% gold.", -1140, 420, { "Haggler" }, "gold", 3)
trade("HagglerIII", "Haggler III", "Another +3% gold.", -1320, 480, { "HagglerII" }, "gold", 3)
trade("HagglerIV", "Haggler IV", "Another +3% gold.", -1320, 660, { "HagglerIII" }, "gold", 3)
trade("HagglerV", "Haggler V", "Another +3% gold (15% in all).", -1500, 570, { "HagglerIV" }, "gold", 3)
trade("BulkSeller", "Bulk Seller", "+5% gold when you sell 50 or more blocks at once.", -960, 540, { "Haggler" }, nil, nil, "Inventory")
trade("RebornTrader", "Reborn Trader", "+1% gold per rebirth, up to +10%.", -1140, 600, { "BulkSeller" }, nil, nil, "Rebirth")
trade("EarlyBird", "Early Bird", "Gold from the daily card is 25% bigger.", -605, 640, { "SupplyRunner" }, nil, nil, "Daily")
trade("Brewmaster", "Brewmaster I", "Tonics last 25% longer.", -780, 700, { "EarlyBird" }, "brew", 25, "Boosts")
trade("BrewmasterII", "Brewmaster II", "Tonics last another 25% longer.", -960, 760, { "Brewmaster" }, "brew", 25, "Boosts")
trade("DoubleDose", "Double Dose", "One tonic in ten isn't used up.", -780, 880, { "Brewmaster" }, nil, nil, "Boosts")
trade("PackIV", "Pack Stitch IV", "Add another 10% of the base block limit.", -395, 620, { "DeepPockets" }, "pack", 10, "Inventory")
trade("PackV", "Pack Stitch V", "Add another 10% of the base block limit (50% in all).", -395, 800, { "PackIV" }, "pack", 10, "Inventory")
trade("DeepPocketsII", "Hidden Pockets II", "Your pack holds 24 more blocks.", -220, 710, { "PackIV" }, "slots", 24, "Inventory")
trade("TemperKitIII", "Field Forge III", "Add 10 more temper charges.", -1030, 210, { "TemperKitII" }, "charges", 10, "Power")

-- Footwork, further out.
footwork("StrideIV", "Quick Feet IV", "+2 more walking speed.", 130, 800, { "Summit" }, "walk", 2)
footwork("ScoutII", "Trail Runner II", "+2 more walking speed.", -65, 780, { "SpringII" }, "walk", 2)
footwork("SpringIII", "Spring Step III", "+10% jump height (50% in all).", -65, 950, { "ScoutII" }, "jump", 10, "Spring")

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
	return ore.gem == true
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

-- XP for one ore. `fresh` is true when the miner carries none of it; `grade` is its purity.
function Skills.oreXP(ore, owned, fresh, depth, grade)
	if ore.host then
		return 0
	end
	local xp = ore.xp + Skills.bonus(owned, "oreXP")
	if fresh then
		xp += Skills.bonus(owned, "freshXP")
	end
	if owned.DeepStudy and depth >= 185 then
		xp += 3
	end
	if depth >= 340 then xp += Skills.bonus(owned, "deepXP") end
	if depth >= 550 then xp += Skills.bonus(owned, "craterXP") end
	if (grade or 0) >= 90 then xp += Skills.bonus(owned, "pureXP") end
	if Skills.isGem(ore) then
		xp += (if owned.RareStudy then 4 else 0) + Skills.bonus(owned, "gemXP")
	end
	return xp
end

-- Hot Streak: the run of ores mined in a row so far and the cut speed it brings (as a divisor).
function Skills.streakDivisor(owned, streak)
	local step = Skills.bonus(owned, "streakStep")
	if step <= 0 or not streak or streak <= 0 then return 1 end
	local cap = 5 + Skills.bonus(owned, "streakCap")
	return 1 + math.min(streak, cap) * step / 100
end

-- `ctx` (optional) is where and how the miner is mining: `row` (blocks down), `crowd` (another miner
-- within 30 studs) and `streak` (ores mined in a row). Server and client pass the same values.
function Skills.cutTime(base, ore, strength, charges, owned, hasteCuts, stoneChips, power, ctx)
	local duration, tempered = Ores.cutTime(base, ore, strength, charges, if owned.HotSteel then 0.7 else nil, power)
	duration *= (100 - Skills.bonus(owned, "cut")) / 100
	if ore.name == "Stone" then
		if owned.StoneSplit then duration *= 0.85 end
		duration *= (100 - Skills.bonus(owned, "stone")) / 100
	elseif Skills.isGem(ore) then
		if owned.GemCutter then duration *= 0.8 end
		duration *= (100 - Skills.bonus(owned, "gem")) / 100
	end
	if (Ores.rarityRank[ore.rarity] or 0) >= 4 then
		duration *= (100 - Skills.bonus(owned, "rare")) / 100
	end
	if ctx then
		local row = ctx.row or 0
		if row >= 300 then duration *= (100 - Skills.bonus(owned, "deep")) / 100 end
		if row >= 550 then duration *= (100 - Skills.bonus(owned, "crater")) / 100 end
		if ctx.crowd then duration *= (100 - Skills.bonus(owned, "crowdCut")) / 100 end
		duration /= Skills.streakDivisor(owned, ctx.streak)
	end
	local useChip = ore.name == "Stone" and (stoneChips or 0) > 0
	return FieldRewards.cutTime(duration, ore, hasteCuts, stoneChips), tempered and not useChip
end

return Skills
