-- The 8 mutations: income multiplier, tag color and roll weight on the Synapse Belt.
local MutationConfig = {}

MutationConfig.list = {
	{ name = "Rotten", multiplier = 2, color = Color3.fromRGB(120, 255, 40), weight = 30 },
	{ name = "Golden", multiplier = 3, color = Color3.fromRGB(255, 205, 40), weight = 22 },
	{ name = "Rizzed", multiplier = 4, color = Color3.fromRGB(255, 110, 200), weight = 16 },
	{ name = "Galaxy Brain", multiplier = 5, color = Color3.fromRGB(150, 90, 255), weight = 11 },
	{ name = "Brain Freeze", multiplier = 6, color = Color3.fromRGB(140, 230, 255), weight = 8 },
	{ name = "Sigma", multiplier = 7, color = Color3.fromRGB(240, 200, 90), weight = 6 },
	{ name = "Ohio", multiplier = 8, color = Color3.fromRGB(255, 80, 60), weight = 4 },
	{ name = "Max Aura", multiplier = 10, color = Color3.fromRGB(255, 255, 255), weight = 3 },
}

MutationConfig.byName = {}
local totalWeight = 0
for index, mutation in ipairs(MutationConfig.list) do
	mutation.index = index
	MutationConfig.byName[mutation.name] = mutation
	totalWeight += mutation.weight
end

function MutationConfig.roll(rng)
	local pick = rng:NextNumber(0, totalWeight)
	for _, mutation in ipairs(MutationConfig.list) do
		pick -= mutation.weight
		if pick <= 0 then return mutation.name end
	end
	return MutationConfig.list[1].name
end

function MutationConfig.multiplierOf(name)
	local mutation = name and MutationConfig.byName[name]
	return mutation and mutation.multiplier or 1
end

return MutationConfig
