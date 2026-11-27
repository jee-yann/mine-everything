local E = {}

E.jobs = {
	{ title = "First strike", goal = 8, reward = 25 },
	{ title = "Break the bank", goal = 36, reward = 80 },
	{ title = "Foundry shift", goal = 80, reward = 160 },
	{ title = "Prism express", goal = 150, reward = 350 },
	{ title = "Deep pockets", goal = 260, reward = 650 },
	{ title = "Vault breaker", goal = 420, reward = 1200 },
	{ title = "Cove legend", goal = 750, reward = 2400 },
}
function E.jobClaimed(mask, i)
	return bit32.btest(mask, bit32.lshift(1, i - 1))
end
E.ranks = {
	{ name = "Noob Miner", level = 1 },
	{ name = "Novice Miner", level = 2 },
	{ name = "Tunnel Miner", level = 5 },
	{ name = "Expert Miner", level = 10 },
	{ name = "Crystal Prospector", level = 18 },
	{ name = "Ore Whisperer", level = 28 },
	{ name = "Deep Delver", level = 40 },
	{ name = "Gem Baron", level = 55 },
	{ name = "Magma Walker", level = 75 },
	{ name = "Starfall Seeker", level = 100 },
}
function E.level(xp)
	return math.floor((1 + math.sqrt(1 + 0.4 * xp)) / 2)
end
function E.levelXP(level)
	return 10 * (level - 1) * level
end
function E.rank(level)
	for i = #E.ranks, 2, -1 do
		if level >= E.ranks[i].level then
			return i, E.ranks[i]
		end
	end
	return 1, E.ranks[1]
end
return E
