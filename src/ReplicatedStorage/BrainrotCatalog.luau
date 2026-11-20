-- All 60 brainrots as data rows. BrainrotModelKit turns a row into a model; income and price come from
-- the rarity's range, spread evenly (on a log scale) over the rows of that rarity.
local RarityConfig = require(script.Parent.RarityConfig)

local BrainrotCatalog = {}

local function row(name, base, bodyType, body, belly, features, prop, caption)
	return { name = name, base = base, bodyType = bodyType, body = Color3.fromHex(body), belly = Color3.fromHex(belly), features = features, prop = prop, caption = caption }
end

local GROUPS = {
	{ "Common", {
		row("Topolino Pensierino", "Mouse", "Blob", "9A9AA6", "FFD0DC", { "earsRound", "tailThin" }, "thoughtBubble", "Had one thought in 2021. Still thinking it."),
		row("Ranocchia Riflessina", "Frog", "Wide", "4CB848", "BFF0A8", { "eyeBumps" }, "mirror", "Stares at its reflection. Reflection stares back."),
		row("Lumachino Lentino", "Snail", "Long", "C9A878", "F5E6C8", { "brainShell" }, "loadingSign", "Loading... loading... loading..."),
		row("Patatino Pigrino", "Potato", "Blob", "A0703C", "D6AE7B", { "spots", "sleepyEyes" }, "pillow", "Couch potato. Literally."),
		row("Pulcino Distratto", "Chick", "Blob", "FFE14D", "FFF4B0", { "beak" }, "questionMark", "Forgot what it was doing. Twice."),
		row("Biscottino Bufferino", "Cookie", "Wide", "D8A060", "D8A060", { "chips" }, "bufferRing", "Crumbles at 1% battery."),
		row("Formaggino Fumino", "Cheese", "Wedge", "FFD23C", "FFE680", { "holes" }, "steam", "Smells like overthinking."),
		row("Polpetta Pisolina", "Meatball", "Blob", "6B3A22", "8C5634", { "sleepyEyes" }, "nightCap", "Naps between naps."),
		row("Capretta Confusetta", "Goat", "Blob", "F4F4F0", "FFF6E0", { "hornsSmall", "beard" }, "tripleQuestion", "Has no idea. Never had one."),
		row("Funghetto Foggetto", "Mushroom", "Tall", "F5ECD7", "FFFFFF", { "mushroomCap" }, "fogCloud", "Lives in brain fog. Rent free."),
		row("Cracker Crampino", "Cracker", "Block", "E8C890", "D6B070", { "dotHoles" }, "bandage", "Cracked under pressure."),
		row("Pomodorino Panichino", "Tomato", "Blob", "E8352E", "FF8070", { "leafTop", "wideEyes" }, "sweat", "Panics in 4K."),
	} },
	{ "Uncommon", {
		row("Cagnolino Scrollino", "Puppy", "Blob", "9C6A3C", "F2DDB8", { "earsFloppy" }, "phone", "Has not seen the sun since 2019."),
		row("Anatra Amnesia", "Duck", "Tall", "FFFFFF", "F4F4F4", { "beak" }, "bandageQuestion", "Who? What? Quack?"),
		row("Criceto Cringeto", "Hamster", "Blob", "F0A040", "FFF0D8", { "cheeks", "earsRound" }, "paperBag", "Posted cringe. Hides forever."),
		row("Tacchino Trendino", "Turkey", "Blob", "8A5A30", "D8B080", { "fanTail" }, "sunglasses", "Follows every trend. Late."),
		row("Riccio Ricordino", "Hedgehog", "Blob", "7A5030", "E8D0B0", { "spikes" }, "stickyNote", "Remembers nothing. Has 400 sticky notes."),
		row("Coniglio Caffeinato", "Bunny", "Tall", "FFFFFF", "FFC8DC", { "earsLong", "wideEyes" }, "coffee", "Seventh espresso. Sees sounds."),
		row("Pizzetta Pensierosa", "Pizza slice", "Wedge", "FFD060", "E04030", { "pepperoni" }, "lightBulbOff", "Had an idea. It was pineapple."),
		row("Lasagnetta Lagghetta", "Lasagna", "Block", "F08A30", "FFD050", { "layerStripes" }, "loadingBar", "Ping: 9000 ms."),
		row("Mozzarella Memoria", "Mozzarella", "Blob", "FFFFFF", "F8F8F0", { "leafTop" }, "floppyDisk", "Stores 1.44 MB of memories."),
		row("Asinello Assonnato", "Donkey", "Blob", "8C8C96", "C8C8D0", { "earsLong", "sleepyEyes" }, "nightCap", "Yawns in Italian."),
	} },
	{ "Rare", {
		row("Cervellino Spaghettino", "Brain + pasta", "Blob", "F0A050", "FFF0D0", { "spaghettiHair" }, "fork", "Brain made of pasta. Al dente."),
		row("Volpe Vibrina", "Fox", "Blob", "F07828", "FFFFFF", { "earsPointed", "tailTip" }, "headphones", "Only vibes. No thoughts."),
		row("Koala Cortexino", "Koala", "Blob", "9A9AA6", "FFFFFF", { "earsBig", "bigBrain" }, "leaf", "Big brain. Sleeps 22 hours."),
		row("Fagiolino Fantasmino", "Bean ghost", "Tall", "A8F0A0", "FFFFFF", { "ghost" }, "ghostWisp", "Ghosted everyone. Even itself."),
		row("Gelato Ganglio", "Ice cream", "Tall", "FF9EC7", "D8A868", { "cone" }, "sprinkles", "Brain freeze on purpose."),
		row("Orsetto Ossessivo", "Bear cub", "Blob", "8A5A30", "D8B080", { "earsRound", "eyeBags" }, "phone", "Checks the phone 900 times a day."),
		row("Tortellino Tic-Tac", "Tortellini", "Wide", "FFD870", "FFE8A0", { "ring" }, "clock", "Always 5 minutes late. To everything."),
		row("Capibara Cerebrale", "Capybara", "Wide", "9C6A3C", "C89A68", { "calmEyes" }, "orange", "Too chill to rot."),
		row("Granchio Grigio", "Crab", "Wide", "B06060", "D8D0D0", { "claws" }, "clawsUp", "Pinches thoughts before they escape."),
	} },
	{ "Epic", {
		row("Neurone Pepperone", "Pepper", "Blob", "E02828", "FF7070", { "stem" }, "sparks", "Spicy synapses."),
		row("Squalo Sinaptico", "Shark", "Long", "3C78D8", "FFFFFF", { "backFin", "teeth" }, "lightning", "Bites through brain fog."),
		row("Polpo Pensatore", "Octopus", "Blob", "9050C8", "D8B8F0", { "tentacles6" }, "monocle", "Eight arms. Zero plans."),
		row("Bradipo Brainfoggo", "Sloth", "Long", "8A6A48", "D0B890", { "longArms", "sleepyEyes" }, "fogCloud", "Downloading a thought. ETA: Tuesday."),
		row("Fenicottero Flashbacko", "Flamingo", "Tall", "FF80B0", "FFC8DC", { "longLegs", "beak" }, "camera", "Relives cringe from 2014 nightly."),
		row("Lama Lobotomama", "Llama", "Tall", "F5ECD7", "FFFFFF", { "longNeck", "fluff" }, "screw", "A screw loose. On purpose."),
		row("Panda Paranoico", "Panda", "Blob", "FFFFFF", "FFFFFF", { "earsBlack", "eyePatches" }, "tinfoil", "The birds are watching."),
		row("Raviolo Rizzolo", "Ravioli", "Block", "FFD060", "FFE080", { "crimp" }, "goldChain", "Unspoken rizz. Stuffed with it."),
	} },
	{ "Legendary", {
		row("Pinguino Sinapsino", "Penguin", "Tall", "1E2A50", "FFFFFF", { "beak", "feetOrange" }, "scarf", "Cool head. Glowing nerves."),
		row("Leone Limbicone", "Lion", "Blob", "E8B040", "FFF0C8", { "mane" }, "crown", "King of feelings."),
		row("Tigre Talamina", "Tiger", "Blob", "F08020", "FFFFFF", { "stripes", "earsRound" }, "headset", "Ranked. Rotted. Undefeated."),
		row("Aquila Amigdala", "Eagle", "Tall", "7A4A28", "FFFFFF", { "wings", "beak" }, "siren", "Panics at 300 km/h."),
		row("Balena Babbeona", "Whale", "Wide", "3C78D8", "A8D0FF", { "spout", "whaleTail" }, "partyHat", "Too big to think small."),
		row("Coccodrillo Cortisolo", "Crocodile", "Long", "3C9A40", "F0E070", { "snout", "teeth" }, "coffeeSweat", "Stress level: crocodile."),
		row("Elefante Ippocampone", "Elephant", "Blob", "9A9AA6", "C8C8D0", { "trunk", "earsBig" }, "seahorse", "Never forgets. Wishes it could."),
	} },
	{ "Mythic", {
		row("Gattino Lobotomino", "Kitten", "Blob", "60C860", "C8F0B8", { "earsCat", "tailThin" }, "zipper", "Unzipped. Thoughts escaped."),
		row("Drago Dopaminico", "Dragon", "Blob", "D82828", "F0C040", { "wings", "horns", "tailThin" }, "heartBreath", "Breathes pure dopamine."),
		row("Unicorno Neuronico", "Unicorn", "Blob", "FFFFFF", "FFC8DC", { "unicornHorn", "rainbowMane" }, "rainbowTrail", "Rainbow neurons only."),
		row("Kraken Cervellone", "Kraken", "Blob", "8040B0", "FF9EC7", { "tentacles8", "bigBrain" }, "captainHat", "Captain of the brain sea."),
		row("Fenice Frontalina", "Phoenix", "Tall", "F08020", "FFE060", { "flameWings", "beak" }, "fire", "Burns out. Comes back. Repeat."),
		row("Mammut Midollone", "Mammoth", "Blob", "7A4A28", "C89A68", { "fur", "tusks", "trunk" }, "iceBlock", "Frozen since the last good idea."),
	} },
	{ "Brainrot God", {
		row("Cervellone Supremo", "Giant brain", "Blob", "FF9EC7", "FFD0E4", { "brainBody" }, "royal", "All brain. No thoughts. Supreme."),
		row("Toccaerba Tremendo", "Grass monster", "Blob", "40B030", "A8E890", { "grassHair", "scared" }, "lawn", "It touched grass once. Never again."),
		row("Sigma Spaghettone", "Spaghetti man", "Tall", "F0D060", "202020", { "sharpJaw", "slickHair" }, "briefcase", "Sigma grindset. Al dente."),
		row("Rizzotto Imperatore", "Risotto bowl", "Wide", "F8F0D8", "FFFFFF", { "riceDots", "bowl" }, "laurel", "Emperor of rizz. Creamy."),
		row("Gallina Aura Infinita", "Chicken", "Blob", "FFFFFF", "FFF6E0", { "comb", "beak" }, "infiniteAura", "+∞ AURA. Lays golden takes."),
	} },
	{ "Fully Rotted", {
		row("Il Cervello Marcio", "Rotten brain", "Blob", "9AC870", "6AB040", { "oneEye", "gooDrips" }, "flies", "Fully rotted. Fully happy."),
		row("Ohio Omnicervello", "Glitch brain", "Blob", "FF40FF", "101010", { "manyEyes" }, "floatingEyes", "Only in Ohio. Only in your head."),
		row("Dopamina Divina", "Angel brain", "Blob", "FFD040", "FFFFFF", { "angelWings" }, "haloHearts", "Infinite scroll. Infinite bliss."),
	} },
}

BrainrotCatalog.list = {}
BrainrotCatalog.byName = {}

local function roundToTwoDigits(n)
	local magnitude = 10 ^ math.max(0, math.floor(math.log10(n)) - 1)
	return math.floor(n / magnitude + 0.5) * magnitude
end

for _, group in ipairs(GROUPS) do
	local rarity = RarityConfig.byName[group[1]]
	local rows = group[2]
	for i, entry in ipairs(rows) do
		local t = #rows > 1 and (i - 1) / (#rows - 1) or 0
		entry.rarity = rarity.name
		entry.tier = rarity.tier
		entry.income = roundToTwoDigits(rarity.incomeMin * (rarity.incomeMax / rarity.incomeMin) ^ t)
		entry.price = entry.income * rarity.priceMultiplier
		table.insert(BrainrotCatalog.list, entry)
		entry.id = #BrainrotCatalog.list
		BrainrotCatalog.byName[entry.name] = entry
	end
end

function BrainrotCatalog.ofTier(tier)
	local result = {}
	for _, entry in ipairs(BrainrotCatalog.list) do
		if entry.tier == tier then table.insert(result, entry) end
	end
	return result
end

return BrainrotCatalog
