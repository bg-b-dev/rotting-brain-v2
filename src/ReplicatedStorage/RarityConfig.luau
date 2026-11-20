-- The 8 rarities: tag color, model scale, price multiplier and income range per second.
local RarityConfig = {}

RarityConfig.list = {
	{ name = "Common", color = Color3.fromRGB(190, 190, 200), scale = 1.0, priceMultiplier = 5, incomeMin = 1, incomeMax = 12, extra = "none" },
	{ name = "Uncommon", color = Color3.fromRGB(80, 230, 90), scale = 1.1, priceMultiplier = 7, incomeMin = 15, incomeMax = 90, extra = "none" },
	{ name = "Rare", color = Color3.fromRGB(60, 150, 255), scale = 1.2, priceMultiplier = 9, incomeMin = 120, incomeMax = 800, extra = "glow" },
	{ name = "Epic", color = Color3.fromRGB(180, 80, 255), scale = 1.35, priceMultiplier = 12, incomeMin = 1e3, incomeMax = 6e3, extra = "sparkles" },
	{ name = "Legendary", color = Color3.fromRGB(255, 150, 30), scale = 1.5, priceMultiplier = 15, incomeMin = 1e4, incomeMax = 6e4, extra = "auraRing" },
	{ name = "Mythic", color = Color3.fromRGB(255, 70, 170), scale = 1.7, priceMultiplier = 19, incomeMin = 1e5, incomeMax = 5e5, extra = "beam" },
	{ name = "Brainrot God", color = Color3.fromRGB(255, 215, 40), scale = 2.0, priceMultiplier = 24, incomeMin = 1e6, incomeMax = 4e6, extra = "halo" },
	{ name = "Fully Rotted", color = Color3.fromRGB(120, 255, 40), scale = 2.4, priceMultiplier = 30, incomeMin = 1e7, incomeMax = 2.5e7, extra = "goo" },
}

RarityConfig.byName = {}
for tier, rarity in ipairs(RarityConfig.list) do
	rarity.tier = tier
	RarityConfig.byName[rarity.name] = rarity
end

return RarityConfig
