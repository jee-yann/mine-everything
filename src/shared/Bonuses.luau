--!strict
-- How passes, tonics, timed boosts, rebirths and Server Luck combine. Pets and cosmetics are only for
-- looks. The server reads the same replicated state as the client (the Passes and Collection
-- attributes, and ServerLuckUntil on ReplicatedStorage), so what the menus show is what a sale or a
-- cut actually uses.
--
-- Luck multiplies the chance of every ore rarer than 1% in a region:
--   luck = (2 with 2× Lucky) × (2 while any of 2× Luck, Lucky Brew or Server Luck runs)
-- Timed luck boosts never multiply each other. The total is capped at 12×.
--
-- Gold multiplies every sale:
--   gold = (2 with Double Gold) × (1 + rebirths) × (1 + VIP 10% + Gold Tonic 50%) × (2 with 2× Gold)
-- Sales are rounded to whole gold.
local Rebirth = require(script.Parent.Rebirth)
local Http = game:GetService("HttpService")
local B = {}
B.maxLuck = 12
B.rareBelow = 1 -- percent: ores rarer than this in a region are "rare" for luck
B.gemFind = 0.03 -- chance that an ore cut also finds a gem

export type State = {
	passes: { [string]: boolean },
	pets: { [string]: any },
	equipped: { string },
	boosts: { [string]: number },
	rebirths: number,
	serverLuckUntil: number,
	now: number,
}

local cache = { text = nil :: any, value = nil :: any }
function B.decode(text: any): any
	if type(text) ~= "string" or text == "" then return nil end
	if text == cache.text then return cache.value end
	local ok, value = pcall(Http.JSONDecode, Http, text)
	cache.text, cache.value = text, if ok then value else nil
	return cache.value
end

-- A state from its parts: the benefit keys a miner's passes grant, their collection table, rebirths.
function B.make(passes: { [string]: boolean }, col: any, rebirths: number, serverLuckUntil: number?, now: number?): State
	col = col or {}
	return {
		passes = passes,
		pets = col.pets or {},
		equipped = col.eq or {},
		boosts = col.boosts or {},
		rebirths = rebirths or 0,
		serverLuckUntil = serverLuckUntil or game:GetService("ReplicatedStorage"):GetAttribute("ServerLuckUntil") or 0,
		now = now or workspace:GetServerTimeNow(),
	}
end

-- The state of a player from their replicated attributes.
function B.state(player: any): State
	local passes = {}
	for key in string.gmatch(player:GetAttribute("Passes") or "", "[^,]+") do
		passes[key] = true
	end
	return B.make(passes, B.decode(player:GetAttribute("Collection")), player:GetAttribute("Rebirths") or 0)
end

local function active(state: State, key: string): boolean
	return (state.boosts[key] or 0) > state.now
end

-- Seconds left on a timed boost (0 when off).
function B.left(state: State, key: string): number
	return math.max(0, (state.boosts[key] or 0) - state.now)
end

function B.luck(state: State): number
	local timed = if active(state, "luck2") or state.serverLuckUntil > state.now then 2 else 1
	return math.min(B.maxLuck, (if state.passes.Lucky then 2 else 1) * timed)
end

function B.gold(state: State): number
	local flat = 1 + (if state.passes.VIP then 0.1 else 0) + (if active(state, "goldTonic") then 0.5 else 0)
	return (if state.passes.DoubleGold then 2 else 1) * Rebirth.goldMultiplier(state.rebirths) * flat
		* (if active(state, "gold2") then 2 else 1)
end

-- Extra mining speed as a fraction: cut time is divided by (1 + this).
function B.speed(state: State): number
	return (if state.passes.FastPick then 0.15 else 0) + (if active(state, "speedTonic") then 0.2 else 0)
end

function B.xp(_state: State): number
	return 1
end

function B.gemChance(_state: State): number
	return B.gemFind
end

-- A region's odds with `luck` applied: every ore under 1% is multiplied, and the rest share what is left
-- in their own proportions, so the list still adds up to 100%. `chances` maps ore name to percent and
-- includes Stone.
function B.lucky(chances: { [string]: number }, luck: number): { [string]: number }
	local rare, other = 0, 0
	for _, percent in chances do
		if percent < B.rareBelow then rare += percent else other += percent end
	end
	local boostedRare = math.min(rare * luck, 100)
	local scale = if other > 0 then (100 - boostedRare) / other else 0
	local out = {}
	for name, percent in chances do
		out[name] = if percent < B.rareBelow then percent * boostedRare / math.max(rare, 1e-12) else percent * scale
	end
	return out
end

-- For a cut that came up common, the chance it is upgraded to each rare ore, so that overall each rare
-- ore turns up exactly `luck` times as often. Returns { {name, chance} } with chances as fractions.
function B.upgrades(chances: { [string]: number }, luck: number): { { any } }
	if luck <= 1 then return {} end
	local rare = 0
	for _, percent in chances do
		if percent < B.rareBelow then rare += percent end
	end
	local common = 1 - rare / 100
	if rare <= 0 or common <= 0 then return {} end
	local out = {}
	for name, percent in chances do
		if percent < B.rareBelow then
			table.insert(out, { name, (percent / 100) * (luck - 1) / common })
		end
	end
	return out
end

return B
