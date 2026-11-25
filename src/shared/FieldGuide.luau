local E = require(script.Parent.Expeditions)
local Ores = require(script.Parent.Ores)
local Guide = {}
local Skills = require(script.Parent.Skills)
Guide.skills, Guide.byId = Skills.nodes, Skills.byId
Guide.petNames = { Pebble = true, Chips = true, Granite = true, Chip = true, Pip = true, Flint = true }
Guide.achievements = {
	{ id = "PocketChange", name = "Pocket Change", ore = "Coal", goal = 10 },
	{ id = "CleanSale", name = "All Pay, No Gravel", goal = 1, detail = "Sell a haul made entirely of ore." },
	{ id = "PickUpgrade", name = "Pick Me Up", goal = 1, detail = "Upgrade your pickaxe’s Power at the workshop." },
	{
		id = "Scales",
		name = "Practicing My Scales",
		sequence = { "Dirt", "Stone", "Coal", "Copper", "Iron", "Gold", "Diamond" },
	},
	{
		id = "Ascent",
		name = "Taking the Scenic Route",
		goal = 1,
		detail = "Reach the surface on foot from 101+ blocks deep in one life.",
	},
	{
		id = "LuckAndSkill",
		name = "Once Is Luck, Twice Is Skill",
		ore = "Starfall",
		goal = 2,
		detail = "Mine Starfall twice across any number of shifts.",
	},
	{ id = "PetName", name = "Pet Rock, Proper Noun", goal = 1, detail = "Give your rock companion a new name." },
	{
		id = "Branch",
		name = "Branch Manager",
		goal = 3,
		detail = "Learn three linked skills along a single path.",
	},
	{ id = "Shifts", name = "Timecard Complete", goal = #E.jobs, detail = "Collect the reward for every shift job." },
	{ id = "PayDirt", name = "Certified Dirt Person", ore = "Dirt", goal = 1000 },
	{ id = "RockSolid", name = "Rock Solid", ore = "Stone", goal = 500 },
	{ id = "CopperCollector", name = "Copper Collector", ore = "Copper", goal = 50 },
	{ id = "GoldenTouch", name = "Midas Touch", ore = "Gold", goal = 25 },
	{ id = "Ice", name = "Ice in My Pockets", ore = "Diamond", goal = 10 },
	{ id = "Envy", name = "Green With Envy", ore = "Emerald", goal = 5 },
}
-- First finds are recorded in the Ore Index, not as achievements, so every ore award here asks
-- for a real haul. Earlier "First <ore>" badges were retired with the 30-ore expansion.
Guide.awardsById = {}
-- Keep previously awarded, retired badges readable in existing saves.
Guide.storedAwards = { Sandwich = true, Pressure = true, Penny = true, Traffic = true, Variety = true }
for _, award in Guide.achievements do
	Guide.awardsById[award.id] = award
	if award.sequence then
		award.goal = #award.sequence
	end
	if not award.ore then
		Guide.storedAwards[award.id] = true
	end
end
Guide.cutWindow = #Guide.awardsById.Scales.sequence

function Guide.awardText(award, player)
	local detail = award.detail
		or (
			if award.sequence
				then table.concat(award.sequence, " → ")
				else string.format("Mine %d %s.", award.goal, award.ore)
		)
	local function mask(word)
		if Ores.byName[word] and Ores.byName[word].secret and not player:GetAttribute("Found" .. word) then
			return "???"
		end
		return word
	end
	local title = string.gsub(award.name, "%a+", mask)
	local requirement = string.gsub(detail, "%a+", mask)
	return title, requirement
end

function Guide.progress(p, award)
	if award.ore then
		return math.min(p.counts[award.ore] or 0, award.goal)
	end
	if p.earned[award.id] then
		return award.goal
	end
	if award.id == "PickUpgrade" then
		return math.min(1, p.levels.Power - 1)
	elseif award.id == "Shifts" then
		return p.jobs
	elseif award.id == "Branch" then
		local lengths, best = {}, 0
		for _, node in Guide.skills do
			if p.skills[node.id] then
				local length = 1
				for _, parent in node.requires do
					length = math.max(length, (lengths[parent] or 0) + 1)
				end
				lengths[node.id] = length
				best = math.max(best, length)
				if best >= award.goal then
					return award.goal
				end
			end
		end
		return best
	end
	if not award.sequence then
		return 0
	end
	local cuts = p.recentCuts
	for length = math.min(#cuts, award.goal), 1, -1 do
		local matches = true
		for i = 1, length do
			if cuts[#cuts - length + i] ~= award.sequence[i] then
				matches = false
				break
			end
		end
		if matches then
			return length
		end
	end
	return 0
end
function Guide.points(xp, skills)
	local spent = 0
	for _ in skills do
		spent += 1
	end
	return math.max(0, E.level(xp) - 1 - spent)
end
function Guide.selectedTitle(p)
	return p.title or E.rank(E.level(p.xp))
end
return Guide
