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

-- Sale price multiplier for a player: the Double Gold pass and rebirths stack.
function Rebirth.saleMultiplier(player: Player): number
	local pass = if player:GetAttribute("DoubleGold") then 2 else 1
	return pass * Rebirth.goldMultiplier(player:GetAttribute("Rebirths") or 0)
end

return Rebirth
