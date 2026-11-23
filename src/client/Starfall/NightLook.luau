-- Edit these values to tune the island before the meteor hits.
return table.freeze({
	Exposure = -0.09, -- Stops. Lower by 0.15 for a darker island.
	ShadowFill = Color3.fromRGB(64, 72, 91), -- Open-sky fill on the sheltered side of the island.
	RimColor = Color3.fromRGB(160, 184, 209), -- Silver-blue grazing light from offshore.
	RimStrength = 0.76, -- 0 removes the rim. 1 gives the ledge edges the strongest silver.
	SkyColor = Color3.fromRGB(43, 49, 61), -- Color of the clear sky above the water.
})
