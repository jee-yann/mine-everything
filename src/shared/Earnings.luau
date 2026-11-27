-- About how much gold a miner earns in an hour of steady mining, without passes or boosts: the
-- average sale value per block of the deepest region they have reached AND their pick can mine
-- (so a low-Power miner who rode down someone else's shaft, or one fresh from a rebirth, is valued at
-- what they can actually dig, not at where they once stood), times the blocks an hour at their Speed, Power and
-- skills at a relaxed pace (half the time spent cutting, and a 30-second trip to sell each full
-- pack), times their rebirth bonus. Gold packs, gold rewards and duplicate crate rewards pay minutes
-- of this, so they stay worth having at every stage.
local Shared = script.Parent
local Config, Ores, Upgrades = require(Shared.GameConfig), require(Shared.Ores), require(Shared.Upgrades)
local Skills, Purity, Rebirth = require(Shared.Skills), require(Shared.OrePurity), require(Shared.Rebirth)
local Earnings = {}
Earnings.minimum = 250

-- `p` needs bestDepth, levels, skills and rebirths (a profile, or a copy of one).
-- The deepest block row a pick of Power `power` can cut: every stone grade up to its Power.
function Earnings.reach(power)
	local grades = Config.StoneGrades
	return if power < #grades then grades[power + 1].depth - 1 else math.huge
end

function Earnings.perHour(p)
	local reached = math.floor((p.bestDepth or 0) / 5)
	local depth = math.max(Config.DirtLayers + 1, math.min(reached, Earnings.reach(Upgrades.items.Power.values[p.levels.Power or 1])))
	local layer = Config.layer(depth * Config.Cell)
	local strength = Config.strength(-depth * Config.Cell)
	local stone, value = 100, 0
	for name, percent in layer.oreChances do
		local found = Ores.byName[name]
		if found and not found.secret then
			value += percent / 100 * Purity.unitPrice(found, nil, p.skills.Broker) * 1.25
			stone -= percent
		end
	end
	value += math.max(0, stone) / 100 * Purity.unitPrice(Ores.byName.Stone, nil, p.skills.Broker)
	local base = Upgrades.items.Speed.values[p.levels.Speed] * Rebirth.cutMultiplier(p.rebirths or 0)
	local cut = Skills.cutTime(base, Ores.byName.Stone, strength, 0, p.skills, 0, 0, Upgrades.items.Power.values[p.levels.Power])
	local capacity = Skills.capacity(Upgrades.items.Capacity.values[p.levels.Capacity], p.skills)
	local blocks = 3600 / (cut + 0.6 + 30 / capacity) * 0.5
	return math.max(Earnings.minimum, math.floor(blocks * value * Rebirth.goldMultiplier(p.rebirths or 0) + 0.5))
end

-- Gold for `minutes` of an hourly rate, rounded to a tidy amount. The client uses this with the rate
-- the server publishes (the GoldBundle attribute), so the Shop shows exactly what a pack pays.
function Earnings.tidy(perHour, minutes)
	local raw = perHour * minutes / 60
	local step = if raw >= 10000 then 100 elseif raw >= 1000 then 10 else 5
	return math.max(step, math.floor(raw / step + 0.5) * step)
end

-- Gold for `minutes` of this miner's earnings.
function Earnings.minutes(p, minutes)
	return Earnings.tidy(Earnings.perHour(p), minutes)
end

return Earnings
