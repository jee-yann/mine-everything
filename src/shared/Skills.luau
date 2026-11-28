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
			effect = effect,
			amount = amount,
		}
		table.insert(Skills.nodes, node)
		Skills.byId[id] = node
		if effect then
			byEffect[effect] = byEffect[effect] or {}
			byEffect[effect][id] = amount
		end
	end
end

-- The tree is drawn as wedges round the Prospector, one family each, with its later skills further
-- out in the same wedge: Pickwork (upper left) leads on to Momentum, Survey optics (top) to Showmanship,
-- Geology (right) to Scholar and Assaying, Hauling (lower left) to Trade. Positions come from
-- art/skills/tree_layout.py; requirements only cross into a neighbouring wedge.
-- Pickwork: reach and cutting.
local pickwork = branch("Pickwork", "Power")
pickwork("Reach", "Long Arm I", "+5 studs of pick reach.", -155, -110, {}, "reach", 5, "Hook")
pickwork("Tempo", "Steady Hands I", "Subtract 10% of base cut time on every block.", -340, -140, { "Reach" }, "cut", 10, "Tempo")
pickwork("ReachII", "Long Arm II", "+5 more studs of pick reach.", -235, -280, { "Reach" }, "reach", 5, "Hook")
pickwork("TempoII", "Steady Hands II", "Subtract another 10% of base cut time.", -505, -195, { "Tempo" }, "cut", 10, "Tempo")
pickwork("ReachIII", "Long Arm III", "+5 more studs of pick reach.", -340, -420, { "ReachII" }, "reach", 5, "Hook")
pickwork("TempoIII", "Steady Hands III", "Subtract another 10% of base cut time (30% total).", -680, -235, { "TempoII" }, "cut", 10, "Tempo")
pickwork("StoneSplit", "Fault Splitter", "Spend 15% less time cutting any grade of stone.", -590, -410, { "TempoII" })
pickwork("ReachIV", "Long Arm IV", "+5 more studs of pick reach.", -390, -605, { "ReachIII" }, "reach", 5, "Hook")
pickwork("GemCutter", "Facet Cutter", "Cut diamond and rarer gems in 20% less time.", -630, -635, { "ReachIII", "StoneSplit" }, nil, nil, "Crystal")

-- Lamplight: your lamp and survey flares.
local lamplight = branch("Lamplight", "Lamp")
lamplight("Lamp", "Lantern Wick I", "+8 studs of personal lamp radius.", 140, -125, {}, "lamp", 8)
lamplight("Lantern", "Lantern Wick II", "+8 more studs of personal lamp radius.", 270, -245, { "Lamp" }, "lamp", 8, "Beacon")
lamplight("LanternIII", "Lantern Wick III", "+8 more studs of personal lamp radius.", 325, -435, { "Lantern" }, "lamp", 8, "Beacon")
lamplight("LongBurn", "Slow Burn I", "Survey flares burn 15 seconds longer.", 465, -275, { "Lantern" }, "burn", 15)
lamplight("LanternIV", "Lantern Wick IV", "+8 more studs of personal lamp radius.", 400, -595, { "LanternIII" }, "lamp", 8)
lamplight("LongBurnII", "Slow Burn II", "Add 15 more seconds to each flare (60 seconds total).", 635, -335, { "LongBurn" }, "burn", 15)
lamplight("CaveEcho", "Cave Listener", "Flares sense natural caves within 15 blocks.", 665, -600, { "LongBurnII", "LanternIII" }, nil, nil, "Beacon")
lamplight("FlareThrow", "Long Toss", "Throw survey flares up to 16 studs ahead.", 805, -390, { "LongBurnII" })
lamplight("LongBurnIII", "Slow Burn III", "Survey flares burn another 15 seconds.", 940, -515, { "FlareThrow" }, "burn", 15, "Beacon")

-- Survey optics: the mining light.
local survey = branch("Survey optics", "Beacon")
survey("Focus", "Face Lantern", "Light the face you strike while you mine the block.", 0, -365, { "Reach", "Lamp" }, "focus", 9)
survey("FocusII", "Wide Beam", "Widen your mining light from 9 to 15 studs.", 0, -540, { "Focus" }, "focus", 6)
survey("Longbeam", "Prism Lens", "Gain 5 studs of reach. Known ores tint your light as you mine them.", -105, -710, { "FocusII" }, "reach", 5)
survey("LightTrail", "Miner’s Fireflies", "Mined ore leaves a light for 15s. Keep up to four lit.", 105, -710, { "FocusII" })
survey("Constellation", "Constellation", "Your ore lights last 30s and you can keep eight lit.", 0, -895, { "Longbeam", "LightTrail" })

-- Footwork: walking and jumping.
local footwork = branch("Footwork", "Boot")
footwork("Stride", "Quick Feet I", "+3 walking speed.", 20, 190, {}, "walk", 3)
footwork("Spring", "Spring Step I", "+25% jump height.", -50, 360, { "Stride" }, "jump", 25, "Spring")
footwork("StrideII", "Quick Feet II", "+2 walking speed.", 125, 345, { "Stride" }, "walk", 2)
footwork("Scout", "Trail Runner", "+3 walking speed.", -30, 540, { "Spring" }, "walk", 3)
footwork("StrideIII", "Quick Feet III", "+2 more walking speed.", 145, 525, { "StrideII" }, "walk", 2)
footwork("SpringII", "Spring Step II", "+15% jump height (40% total).", -15, 720, { "Scout" }, "jump", 15, "Spring")
footwork("ScoutII", "Trail Runner II", "+2 more walking speed.", -65, 890, { "SpringII" }, "walk", 2)
footwork("Summit", "Summit Boots", "+10% jump height and +2 walking speed.", 130, 885, { "StrideIII", "SpringII" }, "walk", 2, "Spring")
footwork("SpringIII", "Spring Step III", "+10% jump height (50% in all).", -50, 1070, { "ScoutII" }, "jump", 10, "Spring")
footwork("StrideIV", "Quick Feet IV", "+2 more walking speed.", 200, 1050, { "Summit" }, "walk", 2)

-- Hauling: the pack, tempering and supplies.
local hauling = branch("Hauling", "Inventory")
hauling("Pack", "Pack Stitch I", "+10% of your workshop bag’s base block limit.", -165, 100, {}, "pack", 10)
hauling("PackII", "Pack Stitch II", "Add another 10% of the base block limit.", -315, 190, { "Pack" }, "pack", 10)
hauling("TemperKit", "Field Forge I", "Each fresh temper lasts 10 more hard cuts.", -530, 115, { "PackII" }, "charges", 10, "Power")
hauling("PackIII", "Pack Stitch III", "Add another 10% of the base block limit (30% total).", -465, 280, { "PackII" }, "pack", 10)
hauling("PackMule", "Second Wind", "+3 walking speed while your pack is at least 75% full.", -350, 415, { "PackII", "Stride" }, nil, nil, "Boot")
hauling("TemperKitII", "Field Forge II", "Add 10 more temper charges (45 total).", -710, 120, { "TemperKit" }, "charges", 10, "Power")
hauling("Broker", "Fair Trade", "Earn 10% more on each piece of ore you sell, rounded to the nearest gold.", -655, 290, { "PackIII" }, nil, nil, "Coins")
hauling("PackIV", "Pack Stitch IV", "Add another 10% of the base block limit.", -565, 445, { "PackIII" }, "pack", 10)
hauling("DeepPockets", "Hidden Pockets", "Your pack holds 24 more blocks after percentage bonuses.", -440, 570, { "PackIII", "PackMule" }, "slots", 24)
hauling("HotSteel", "Hot Steel", "Tempering now cuts hard-block mining time by 30%.", -895, 20, { "TemperKitII", "TempoIII" }, nil, nil, "Power")
hauling("TemperKitIII", "Field Forge III", "Add 10 more temper charges.", -870, 195, { "TemperKitII" }, "charges", 10, "Power")
hauling("PackV", "Pack Stitch V", "Add another 10% of the base block limit (50% in all).", -725, 520, { "PackIV" }, "pack", 10)
hauling("DeepPocketsII", "Hidden Pockets II", "Your pack holds 24 more blocks.", -610, 655, { "PackIV" }, "slots", 24)
hauling("SupplyRunner", "Supply Runner", "Earn a second survey flare on each daily delivery.", -470, 760, { "DeepPockets" }, nil, nil, "Jobs")

-- Geology: XP from ore, and Fortune.
-- Fresh Find (once First Edition, which only paid for each ore's first find and then went dead):
-- XP for an ore you aren't carrying any of, which keeps paying for good.
local geology = branch("Geology", "Crystal")
geology("Notes", "Field Notes I", "Earn +1 XP from every ore you mine.", 180, 60, {}, "oreXP", 1)
geology("NotesII", "Field Notes II", "Earn another +1 XP from every ore.", 345, 120, { "Notes" }, "oreXP", 1)
geology("Rockhound", "Rockhound", "+3 walking speed while carrying diamond or a rarer gem.", 430, 330, { "NotesII", "StrideII" }, nil, nil, "Boot")
geology("NotesIII", "Field Notes III", "Earn another +1 XP from every ore (+3 total).", 510, 175, { "NotesII" }, "oreXP", 1)
geology("FirstFind", "Fresh Find I", "Earn +10 XP from an ore you aren't carrying any of.", 540, 0, { "NotesII" }, "freshXP", 10, "Jobs")
geology("RareStudy", "Gem Journal", "Diamond and rarer gems earn +4 XP.", 645, 315, { "NotesIII" })
geology("DeepStudy", "Deep Survey", "Ore mined at 185+ blocks earns +3 XP.", 705, 150, { "NotesIII" })
geology("FirstFindII", "Fresh Find II", "Earn another +15 XP from an ore you aren't carrying (+25 total).", 715, -30, { "FirstFind" }, "freshXP", 15, "Jobs")
geology("Fortune", "Fortune", "One cut in ten gives you two pieces of ore if your pack has room.", 735, 510, { "RareStudy" })

-- Each family below has one rule in Skills.cutTime, Skills.oreXP, Bonuses or Profile, so a skill
-- is never just a number on a card.
-- Momentum: speed from mining well.
local momentum = branch("Momentum", "Flame")
momentum("StoneBreaker", "Stone Breaker I", "Cut plain stone 8% faster.", -860, -240, { "TempoIII" }, "stone", 8, "Power")
momentum("HotStreak", "Hot Streak I", "Each ore mined in a row cuts 4% faster, up to 5 in a row. Stone breaks the streak.", -780, -435, { "TempoIII" }, "streakStep", 4)
momentum("StoneBreakerII", "Stone Breaker II", "Cut plain stone another 8% faster.", -1015, -345, { "StoneBreaker" }, "stone", 8, "Power")
momentum("HotStreakII", "Hot Streak II", "Your streak builds up to 8 in a row.", -905, -570, { "HotStreak" }, "streakCap", 3)
momentum("FacetCutterII", "Facet Cutter II", "Cut diamond and rarer gems another 10% faster.", -725, -790, { "GemCutter" }, "gem", 10, "Crystal")
momentum("Deepcutter", "Deepcutter", "Cut 8% faster 300 or more blocks down.", -1160, -450, { "StoneBreakerII" }, "deep", 8, "Power")
momentum("StreakKeeper", "Streak Keeper", "One stone block in a row doesn't break your streak.", -1085, -615, { "HotStreakII" })
momentum("HotStreakIII", "Hot Streak III", "Each ore in your streak cuts 6% faster.", -985, -760, { "HotStreakII" }, "streakStep", 2)
momentum("RareTouch", "Rare Touch", "Cut Epic and rarer ores 10% faster.", -870, -895, { "FacetCutterII" }, "rare", 10, "Crystal")
momentum("CraterVeteran", "Crater Veteran", "Cut 10% faster in the Starfall Crater.", -1310, -560, { "Deepcutter" }, "crater", 10)

-- Showmanship: mining near other miners.
local showmanship = branch("Showmanship", "Showoff")
showmanship("ShowOff", "Show Off I", "Cut 5% faster with another miner within 30 studs.", 0, -1070, { "Constellation" }, "crowdCut", 5)
showmanship("ShowOffII", "Show Off II", "Cut another 5% faster near another miner.", -175, -1235, { "ShowOff" }, "crowdCut", 5)
showmanship("CashOut", "Cash Out Crew I", "+4% gold from sales with another miner within 30 studs.", 0, -1245, { "ShowOff" }, "crowdGold", 4, "Coins")
showmanship("CrowdPleaser", "Crowd Pleaser I", "+5% XP with another miner within 30 studs.", 175, -1235, { "ShowOff" }, "crowdXP", 5, "Friends")
showmanship("ShowOffIII", "Show Off III", "Cut another 5% faster near another miner (15% in all).", -180, -1410, { "ShowOffII" }, "crowdCut", 5)
showmanship("CashOutII", "Cash Out Crew II", "Another +4% gold near another miner.", 0, -1420, { "CashOut" }, "crowdGold", 4, "Coins")
showmanship("CrowdPleaserII", "Crowd Pleaser II", "Another +5% XP near another miner.", 180, -1410, { "CrowdPleaser" }, "crowdXP", 5, "Friends")
showmanship("CashOutIII", "Cash Out Crew III", "Another +4% gold near another miner (12% in all).", 0, -1600, { "CashOutII" }, "crowdGold", 4, "Coins")

-- Scholar: experience.
local scholar = branch("Scholar", "Book")
scholar("GemJournalII", "Gem Journal II", "Diamond and rarer gems earn another +4 XP.", 825, 340, { "RareStudy" }, "gemXP", 4, "Crystal")
scholar("AbyssScholar", "Abyss Scholar", "Ore mined 340 or more blocks down earns +5 XP.", 880, 155, { "DeepStudy" }, "deepXP", 5, "Crystal")
scholar("Scholar", "Scholar I", "+3% XP from everything you mine.", 890, -60, { "FirstFindII" }, "xpPercent", 3)
scholar("CleanCut", "Clean Cut", "Pieces of 90% purity or better earn +5 XP.", 1000, 380, { "GemJournalII" }, "pureXP", 5, "Assay")
scholar("CraterScholar", "Crater Scholar", "Ore mined in the Starfall Crater earns +8 XP.", 1055, 175, { "AbyssScholar" }, "craterXP", 8, "Flame")
scholar("ScholarII", "Scholar II", "Another +3% XP.", 1070, -35, { "Scholar" }, "xpPercent", 3)
scholar("ScholarIII", "Scholar III", "Another +3% XP.", 1245, 20, { "ScholarII" }, "xpPercent", 3)
scholar("ScholarIV", "Scholar IV", "Another +3% XP.", 1420, 80, { "ScholarIII" }, "xpPercent", 3)
scholar("ScholarV", "Scholar V", "Another +3% XP (15% in all).", 1590, 140, { "ScholarIV" }, "xpPercent", 3)

-- Assaying: purity and luck.
local assaying = branch("Assaying", "Assay")
assaying("LuckyStrike", "Lucky Strike I", "+5% luck: ores rarer than 1% turn up a little more.", 695, 815, { "Fortune" }, "luck", 5, "Clover")
assaying("FortuneII", "Fortune II", "One ore cut in seven gives two pieces, not one in ten.", 820, 685, { "Fortune" }, nil, nil, "Crystal")
assaying("Assayer", "Assayer I", "10% of your finds roll purity twice and keep the better.", 925, 540, { "Fortune" }, "assay", 10)
assaying("LuckyStrikeII", "Lucky Strike II", "Another +5% luck.", 880, 885, { "LuckyStrike" }, "luck", 5, "Clover")
assaying("AssayerII", "Assayer II", "20% of your finds roll purity twice.", 1090, 600, { "Assayer" }, "assay", 10)
assaying("LuckyStrikeIII", "Lucky Strike III", "Another +5% luck (15% in all).", 1060, 950, { "LuckyStrikeII" }, "luck", 5, "Clover")
assaying("Polish", "Polish", "Nothing you mine is under 55% purity.", 1215, 735, { "AssayerII" })
assaying("AssayerIII", "Assayer III", "30% of your finds roll purity twice.", 1300, 580, { "AssayerII" }, "assay", 10)

-- Trade: gold and tonics.
local trade = branch("Trade", "Coins")
trade("Haggler", "Haggler I", "+3% gold from every sale.", -815, 365, { "Broker" }, "gold", 3)
trade("HagglerII", "Haggler II", "Another +3% gold.", -1010, 360, { "Haggler" }, "gold", 3)
trade("BulkSeller", "Bulk Seller", "+5% gold when you sell 50 or more blocks at once.", -935, 520, { "Haggler" }, nil, nil, "Inventory")
trade("EarlyBird", "Early Bird", "Gold from the daily card is 25% bigger.", -630, 865, { "SupplyRunner" }, nil, nil, "Daily")
trade("HagglerIII", "Haggler III", "Another +3% gold.", -1160, 450, { "HagglerII" }, "gold", 3)
trade("RebornTrader", "Reborn Trader", "+1% gold per rebirth, up to +10%.", -1085, 610, { "BulkSeller" }, nil, nil, "Rebirth")
trade("Brewmaster", "Brewmaster I", "Tonics last 25% longer.", -790, 965, { "EarlyBird" }, "brew", 25, "Boosts")
trade("HagglerIV", "Haggler IV", "Another +3% gold.", -1315, 540, { "HagglerIII" }, "gold", 3)
trade("DoubleDose", "Double Dose", "One tonic in ten isn't used up.", -1010, 1000, { "Brewmaster" }, nil, nil, "Boosts")
trade("BrewmasterII", "Brewmaster II", "Tonics last another 25% longer.", -880, 1115, { "Brewmaster" }, "brew", 25, "Boosts")
trade("HagglerV", "Haggler V", "Another +3% gold (15% in all).", -1465, 635, { "HagglerIV" }, "gold", 3)

function Skills.ready(node, owned)
	for _, id in node.requires do
		if not owned[id] then
			return false
		end
	end
	return true
end

-- After an update moves or removes skills, some a miner owns may no longer connect (they need a
-- skill the miner doesn't have, or no longer exist). Drop those, and anything that hung off them,
-- so their points come back to spend again: a partial reset of just the bits that broke. Points
-- are level minus skills owned, so removing a skill is the refund. Returns the names refunded.
function Skills.prune(owned)
	local refunded = {}
	repeat
		local changed = false
		for id in owned do
			local node = Skills.byId[id]
			if not node or not Skills.ready(node, owned) then
				owned[id] = nil
				table.insert(refunded, if node then node.name else id)
				changed = true
			end
		end
	until not changed
	return refunded
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
