--!strict
-- Rebirth: start a new run with permanent bonuses. The server decides everything (see
-- Profile.rebirth); this module holds the shared rules so the client can show them.
--
-- A rebirth resets the run: gold, the pack and its purities, workshop levels (Power, Speed,
-- Backpack) and field supplies. Everything earned for the miner stays: XP level and skills, gems,
-- the Index, achievements and titles, pets, quests and deepest descent.
--
-- Rewards are data: add an entry to `perks` for a bonus that grows every rebirth, or to
-- `milestones` for a one-off unlock at a given rebirth count.
local Rebirth = {}

-- What the current run must achieve before the miner can rebirth.
Rebirth.requirement = { ore = "Starfall", count = 1 }

-- The Starfall's trail. The star came down in the crater, but its shards scattered up through the
-- mine, and a newer miner meets the trail shallower: the first rebirth's runs through Saltglass Sinks
-- (Power 5, about an hour in), and from the sixth on it is the crater itself. Once a run has cut
-- `blocks` blocks at or below the trail's depth without a Starfall, the next block cut there holds one.
-- Luck never moves this count, so paid luck can't buy a rebirth; a Starfall found by chance (in the
-- crater, where they occur naturally) still counts.
Rebirth.trails = {
	{ depth = 140, blocks = 150, region = "Saltglass Sinks" },
	{ depth = 225, blocks = 250, region = "Glowcap Hollows" },
	{ depth = 260, blocks = 350, region = "Midnight Fault" },
	{ depth = 340, blocks = 450, region = "Frostglass Reach" },
	{ depth = 400, blocks = 550, region = "Cinderheart Forge" },
	{ depth = 550, blocks = 700, region = "Starfall Crater" },
}
Rebirth.trailGrowth = 100 -- more blocks for each rebirth past the last row
Rebirth.trailMost = 2000

-- The trail for a miner with `n` rebirths: { depth, blocks, region }.
function Rebirth.trail(n: number): { depth: number, blocks: number, region: string }
	local row = Rebirth.trails[math.min(n + 1, #Rebirth.trails)]
	local past = math.max(0, n + 1 - #Rebirth.trails)
	return { depth = row.depth, blocks = math.min(Rebirth.trailMost, row.blocks + past * Rebirth.trailGrowth), region = row.region }
end

Rebirth.cutCap = 0.25 -- the most cutting speed rebirths can add

function Rebirth.goldMultiplier(n: number): number
	return 1 + n
end

function Rebirth.xpMultiplier(n: number): number
	return 1 + 0.25 * n
end

-- Multiplies the base cut time (so 0.95 is 5% faster).
function Rebirth.cutMultiplier(n: number): number
	return 1 - math.min(Rebirth.cutCap, 0.05 * n)
end

-- Bonuses that grow with every rebirth. `text(n)` describes the bonus after n rebirths.
Rebirth.perks = {
	{
		id = "Gold",
		name = "Gold from ore",
		text = function(n: number): string
			return string.format("×%d sale price", Rebirth.goldMultiplier(n))
		end,
	},
	{
		id = "XP",
		name = "Mining XP",
		text = function(n: number): string
			return string.format("+%d%% XP", math.round((Rebirth.xpMultiplier(n) - 1) * 100))
		end,
	},
	{
		id = "Cut",
		name = "Cutting speed",
		text = function(n: number): string
			return string.format("%d%% faster", math.round((1 - Rebirth.cutMultiplier(n)) * 100))
		end,
	},
}

-- One-off unlocks at a rebirth count. Later content (pets, titles, trails) goes here.
Rebirth.milestones = {
	{ at = 1, name = "Reborn", detail = "Your rebirth count shows beside your name on the Server miners board" },
}

function Rebirth.ready(found: number): boolean
	return found >= Rebirth.requirement.count
end

-- The badge beside a miner's name: one star in the colour of their tier, with the count on it, so
-- Rebirth 9 is as short as Rebirth 1. Violet to 4, gold to 9, cyan to 24, then pink.
local tiers = {
	{ from = 1, color = Color3.fromRGB(190, 150, 255) },
	{ from = 5, color = Color3.fromRGB(255, 206, 74) },
	{ from = 10, color = Color3.fromRGB(110, 232, 255) },
	{ from = 25, color = Color3.fromRGB(255, 128, 191) },
}
function Rebirth.tierColor(n: number): Color3
	local color = tiers[1].color
	for _, tier in tiers do
		if n >= tier.from then color = tier.color end
	end
	return color
end
function Rebirth.badge(n: number): string
	return if n > 0 then "★" .. n else ""
end
-- The badge as rich text, with a space before it, or "" without rebirths.
function Rebirth.richBadge(n: number): string
	if n <= 0 then return "" end
	return string.format(' <font color="#%s">%s</font>', Rebirth.tierColor(n):ToHex(), Rebirth.badge(n))
end

-- Sale price multiplier for a player: passes, rebirths, pets and boosts (see Shared.Bonuses).
function Rebirth.saleMultiplier(player: Player): number
	local Bonuses = require(script.Parent.Bonuses) :: any
	return Bonuses.gold(Bonuses.state(player))
end

return Rebirth
