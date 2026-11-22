-- Edit these values to tune the island before the meteor hits.
return table.freeze({
	Exposure = -0.09, -- Stops. Lower by 0.15 for a darker island.
	ShadowFill = Color3.fromRGB(100, 104, 119), -- Color of the open ground between ledges.
	RimColor = Color3.fromRGB(151, 164, 183), -- Color of grazing light from offshore.
	RimStrength = 0.60, -- 0 removes the rim. 1 gives the ledge edges the strongest silver.
	SkyColor = Color3.fromRGB(43, 49, 61), -- Color of the clear sky above the water.
})
