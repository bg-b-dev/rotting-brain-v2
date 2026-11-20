-- Builds the inside of the rotting brain from the layout tables below. Run once in Edit mode and saved
-- with the place; at runtime ensureWorld() only builds it again if workspace.BrainWorld is missing.
local WorldBuilder = {}

local PINK = Color3.fromHex("C24F82")
local FOLD = Color3.fromHex("8A2A5A")
local BRAIN_PINK = Color3.fromHex("FF9EC7")
local GOO = Color3.fromRGB(110, 255, 60)
local NERVE = Color3.fromRGB(40, 240, 255)
local BONE = Color3.fromHex("EDE4D3")
local BELT_PURPLE = Color3.fromRGB(45, 20, 70)
local FLOOR_PURPLE = Color3.fromRGB(40, 10, 60)
local VEIN_LIME = Color3.fromRGB(130, 255, 80)
local LOBE_DARK = Color3.fromRGB(35, 15, 50)
local WALL_DARK = Color3.fromRGB(22, 8, 32)
WorldBuilder.LOBE_ACCENTS = {
	Color3.fromRGB(0, 230, 255), Color3.fromRGB(130, 255, 60), Color3.fromRGB(255, 230, 40), Color3.fromRGB(255, 140, 30),
	Color3.fromRGB(255, 60, 180), Color3.fromRGB(60, 120, 255), Color3.fromRGB(170, 70, 255), Color3.fromRGB(255, 50, 60),
}

WorldBuilder.FLOOR_SIZE = 400
WorldBuilder.SKULL_RADIUS = 205
WorldBuilder.MEME_LOBE_CENTER = Vector3.new(0, 30, -150)
WorldBuilder.BELT_HALF_WIDTH = 4
WorldBuilder.BELT_PATH = {
	Vector3.new(0, 1, -105), Vector3.new(-38, 1, -105), Vector3.new(-38, 1, 55),
	Vector3.new(38, 1, 55), Vector3.new(38, 1, -105), Vector3.new(0, 1, -105),
}
WorldBuilder.LOBE_SIZE = Vector3.new(48, 1, 30)
WorldBuilder.LOBE_CENTERS = {
	Vector3.new(-120, 0, -45), Vector3.new(-68, 0, -45), Vector3.new(-120, 0, 15), Vector3.new(-68, 0, 15),
	Vector3.new(68, 0, -45), Vector3.new(120, 0, -45), Vector3.new(68, 0, 15), Vector3.new(120, 0, 15),
}
WorldBuilder.FLOOR2_HEIGHT = 18
WorldBuilder.PLAZA_CENTER = Vector3.new(0, 0, 112)

-- Podium slots in a Lobe's own frame (-Z faces the belt): 10 on floor 1, 10 on floor 2.
local PODIUM_COLUMNS = { -20, -10, 0, 10, 20 }
local PODIUM_ROWS = {
	{ z = -10, y = 0 }, { z = -2, y = 0 },
	{ z = 4.5, y = WorldBuilder.FLOOR2_HEIGHT }, { z = 11.5, y = WorldBuilder.FLOOR2_HEIGHT },
}

local KIOSKS = {
	{ name = "GearKiosk", label = "GEAR", color = Color3.fromRGB(255, 120, 200), offset = Vector3.new(-62, 0, -6) },
	{ name = "UpgradeKiosk", label = "UPGRADES [U]", color = Color3.fromRGB(255, 220, 60), offset = Vector3.new(-62, 0, 10) },
	{ name = "BrainWashKiosk", label = "BRAIN WASH [R]", color = Color3.fromRGB(60, 230, 255), offset = Vector3.new(-62, 0, 26) },
}

local function makePart(parent, name, size, cframe, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
WorldBuilder.makePart = makePart

local function folder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function addLight(part, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = part
	return light
end

local function addSurfaceText(part, face, text, textColor, strokeColor, pixelsPerStud)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 20
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = textColor
	label.TextStrokeColor3 = strokeColor or Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return label
end
WorldBuilder.addSurfaceText = addSurfaceText

local function insideReservedArea(x, z)
	if math.abs(x) < 50 and z > -125 and z < 70 then return true end
	if math.abs(x) > 40 and math.abs(x) < 150 and z > -70 and z < 40 then return true end
	if math.abs(x) < 70 and z > 75 and z < 160 then return true end
	return (Vector2.new(x, z + 150)).Magnitude < 40
end

local function buildBrainFloor(world)
	local f = folder(world, "BrainFloor")
	local size = WorldBuilder.FLOOR_SIZE
	makePart(f, "Floor", Vector3.new(size, 4, size), CFrame.new(0, -2, 0), FLOOR_PURPLE)
	local rng = Random.new(307)
	local placed = 0
	while placed < 70 do
		local x, z = rng:NextNumber(-190, 190), rng:NextNumber(-190, 190)
		if Vector2.new(x, z).Magnitude < 195 and not insideReservedArea(x, z) then
			placed += 1
			local heading = rng:NextNumber(0, math.pi)
			local bend = rng:NextNumber(-0.35, 0.35)
			local cf = CFrame.new(x, 0.4, z) * CFrame.Angles(0, heading, 0)
			for segment = 1, 4 do
				local len = rng:NextNumber(7, 11)
				local piece = makePart(f, "FoldRidge", Vector3.new(len, 1.6, 1.6), cf * CFrame.new(len / 2, 0, 0), VEIN_LIME, nil, Enum.PartType.Cylinder)
				piece.CanCollide = false
				cf = cf * CFrame.new(len - 0.5, 0, 0) * CFrame.Angles(0, bend, 0)
			end
		end
	end
	local goo = 0
	while goo < 22 do
		local x, z = rng:NextNumber(-180, 180), rng:NextNumber(-180, 180)
		if Vector2.new(x, z).Magnitude < 190 and not insideReservedArea(x, z) then
			goo += 1
			local d = rng:NextNumber(6, 14)
			local puddle = makePart(f, "GooPuddle", Vector3.new(0.3, d, d * rng:NextNumber(0.6, 1)), CFrame.new(x, 0.1, z) * CFrame.Angles(0, rng:NextNumber(0, 6), math.pi / 2), GOO, Enum.Material.Neon, Enum.PartType.Cylinder)
			puddle.CanCollide = false
			puddle:SetAttribute("RemGlow", true)
		end
	end
end

local function buildSkullWall(world)
	local f = folder(world, "SkullWall")
	local r, segments = WorldBuilder.SKULL_RADIUS, 32
	local width = 2 * math.pi * r / segments + 1
	for i = 1, segments do
		local a = (i - 0.5) / segments * math.pi * 2
		local pos = Vector3.new(math.sin(a) * r, 40, math.cos(a) * r)
		makePart(f, "SkullSegment", Vector3.new(width, 80, 6), CFrame.lookAt(pos, Vector3.new(0, 40, 0)), Color3.fromRGB(60, 48, 78))
	end
	for _, side in ipairs({ -1, 1 }) do
		local pos = Vector3.new(side * 45, 52, -r + 2)
		makePart(f, "EyeSocket", Vector3.new(1, 34, 44), CFrame.new(pos) * CFrame.Angles(0, -math.pi / 2, 0), Color3.fromRGB(15, 10, 25), nil, Enum.PartType.Cylinder)
		local glow = makePart(f, "PhoneGlow", Vector3.new(14, 22, 0.5), CFrame.new(pos + Vector3.new(0, 0, 1)), Color3.fromRGB(120, 200, 255), Enum.Material.Neon)
		addLight(glow, Color3.fromRGB(120, 200, 255), 22, 1)
		addSurfaceText(glow, Enum.NormalId.Back, "3:07 AM", Color3.fromRGB(255, 255, 255), Color3.fromRGB(20, 60, 140), 10)
	end
end

local function brainBall(parent, name, center, diameter, color, foldColor, foldCount)
	local model = Instance.new("Model")
	model.Name = name
	local ball = makePart(model, "Brain", Vector3.new(diameter, diameter * 0.85, diameter), CFrame.new(center), color, nil, Enum.PartType.Ball)
	local split = makePart(model, "Split", Vector3.new(diameter * 0.02, diameter * 0.86, diameter * 1.01), CFrame.new(center), foldColor)
	split.CanCollide = false
	local rng = Random.new(#name * 31)
	for i = 1, foldCount do
		local offset = rng:NextNumber(-0.42, 0.42) * diameter
		local chord = 2 * math.sqrt((diameter / 2) ^ 2 - offset ^ 2) * 0.86
		local axis = CFrame.Angles(rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi), 0)
		local ring = makePart(model, "Fold", Vector3.new(diameter * 0.015, chord + 0.4, chord + 0.4), CFrame.new(center) * axis * CFrame.new(offset, 0, 0), foldColor, nil, Enum.PartType.Cylinder)
		ring.CanCollide = false
	end
	model.PrimaryPart = ball
	model.Parent = parent
	return model
end
WorldBuilder.brainBall = brainBall

local function buildMemeLobe(world)
	local center = WorldBuilder.MEME_LOBE_CENTER
	local lobe = brainBall(world, "MemeLobe", center, 60, BRAIN_PINK, FOLD, 14)
	local rng = Random.new(60)
	for i = 1, 16 do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.2, 1), rng:NextNumber(-1, 1)).Unit
		local neuron = makePart(lobe, "Neuron", Vector3.new(2.4, 2.4, 2.4), CFrame.new(center + dir * Vector3.new(30, 25.5, 30)), NERVE, Enum.Material.Neon, Enum.PartType.Ball)
		neuron.CanCollide = false
		neuron:SetAttribute("NeuronFlash", i)
		addLight(neuron, NERVE, 10, 1)
	end
	local mouth = makePart(lobe, "MemeMouth", Vector3.new(16, 10, 2), CFrame.new(center + Vector3.new(0, -20, 28)), Color3.fromRGB(40, 0, 30), Enum.Material.Neon)
	mouth.CanCollide = false
	local sign = makePart(lobe, "MemeLobeSign", Vector3.new(36, 7, 1), CFrame.new(center + Vector3.new(0, 34, 18)) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(30, 0, 40))
	addSurfaceText(sign, Enum.NormalId.Back, "MEME LOBE", BRAIN_PINK, Color3.fromRGB(80, 0, 60))
end

local function buildSynapseBelt(world)
	local f = folder(world, "SynapseBelt")
	local path = WorldBuilder.BELT_PATH
	for i = 1, #path - 1 do
		local a, b = path[i], path[i + 1]
		local len = (b - a).Magnitude + WorldBuilder.BELT_HALF_WIDTH * 2
		local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -0.6, 0)
		makePart(f, "BeltSegment", Vector3.new(WorldBuilder.BELT_HALF_WIDTH * 2, 1.2, len), cf, BELT_PURPLE)
		for _, side in ipairs({ -1, 1 }) do
			local rail = makePart(f, "NerveLine", Vector3.new(0.6, 0.6, len), cf * CFrame.new(side * WorldBuilder.BELT_HALF_WIDTH, 0.7, 0), NERVE, Enum.Material.Neon)
			rail.CanCollide = false
			rail:SetAttribute("RemGlow", true)
		end
	end
	local chute = makePart(f, "MemeChute", Vector3.new(10, 1, 26), CFrame.new(0, 3, -116) * CFrame.Angles(math.rad(-10), 0, 0), BELT_PURPLE)
	chute.CanCollide = false
end

function WorldBuilder.podiumLocalCFrames()
	local list = {}
	for _, row in ipairs(PODIUM_ROWS) do
		for _, x in ipairs(PODIUM_COLUMNS) do
			table.insert(list, CFrame.new(x, row.y, row.z))
		end
	end
	return list
end

function WorldBuilder.lobeCFrame(index)
	local c = WorldBuilder.LOBE_CENTERS[index]
	return CFrame.lookAt(c, Vector3.new(0, 0, c.Z))
end

local function buildLobe(parent, index)
	local lobe = Instance.new("Model")
	lobe.Name = "Lobe" .. index
	lobe:SetAttribute("LobeIndex", index)
	local base = WorldBuilder.lobeCFrame(index)
	local size = WorldBuilder.LOBE_SIZE
	local h2 = WorldBuilder.FLOOR2_HEIGHT
	local accent = WorldBuilder.LOBE_ACCENTS[index]
	local half = size.X / 2
	lobe.PrimaryPart = makePart(lobe, "Floor1", Vector3.new(size.X, 1, size.Z), base * CFrame.new(0, 0.5, 0), LOBE_DARK)
	makePart(lobe, "GooEdge", Vector3.new(size.X + 1, 0.6, 1.2), base * CFrame.new(0, 0.4, -size.Z / 2), accent, Enum.Material.Neon)
	makePart(lobe, "Floor2", Vector3.new(size.X, 1, 15), base * CFrame.new(0, h2, 8), LOBE_DARK)
	makePart(lobe, "Floor2Edge", Vector3.new(size.X, 0.6, 0.8), base * CFrame.new(0, h2 + 0.6, 0.6), accent, Enum.Material.Neon)
	for _, x in ipairs({ -half + 1, half - 1 }) do
		makePart(lobe, "Pillar", Vector3.new(2, h2, 2), base * CFrame.new(x, h2 / 2, 1.5), accent)
		makePart(lobe, "SideRail", Vector3.new(0.6, 0.6, size.Z), base * CFrame.new(x, 1.3, 0), accent, Enum.Material.Neon).CanCollide = false
	end
	makePart(lobe, "BackWall", Vector3.new(size.X, h2 + 8, 1), base * CFrame.new(0, (h2 + 8) / 2, 15.5), WALL_DARK)
	local ramp = Instance.new("WedgePart")
	ramp.Name = "Ramp"
	ramp.Anchored = true
	ramp.Size = Vector3.new(6, h2, 22)
	ramp.CFrame = base * CFrame.new(half + 3, h2 / 2, 4) * CFrame.Angles(0, math.pi, 0)
	ramp.Color = accent
	ramp.Material = Enum.Material.SmoothPlastic
	ramp.Parent = lobe
	makePart(lobe, "RampLanding", Vector3.new(4, 1, 15), base * CFrame.new(half + 1, h2, 8), LOBE_DARK)
	local podiums = folder(lobe, "Podiums")
	for slot, local_cf in ipairs(WorldBuilder.podiumLocalCFrames()) do
		local cf = base * local_cf
		local podium = makePart(podiums, "Podium" .. slot, Vector3.new(1.6, 7, 7), cf * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.pi / 2), accent, nil, Enum.PartType.Cylinder)
		podium:SetAttribute("Slot", slot)
		local top = makePart(podiums, "PodiumTop" .. slot, Vector3.new(0.4, 7.2, 7.2), cf * CFrame.new(0, 2.75, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(235, 235, 255), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		top.CanCollide = false
		makePart(podiums, "PodiumRim" .. slot, Vector3.new(0.3, 7.8, 7.8), cf * CFrame.new(0, 2.65, 0) * CFrame.Angles(0, 0, math.pi / 2), accent, Enum.Material.Neon, Enum.PartType.Cylinder).CanCollide = false
	end
	local sign = makePart(lobe, "LobeSign", Vector3.new(24, 5, 0.6), base * CFrame.new(0, h2 + 5, 15), Color3.fromRGB(30, 0, 40))
	local label = addSurfaceText(sign, Enum.NormalId.Front, "LOBE " .. index .. " · EMPTY", accent, Color3.new(0, 0, 0))
	label.Name = "SignText"
	local collect = makePart(lobe, "CollectPad", Vector3.new(6, 0.4, 4), base * CFrame.new(-12, 1.1, -13), GOO, Enum.Material.Neon)
	collect.CanCollide = false
	addSurfaceText(collect, Enum.NormalId.Top, "COLLECT", Color3.fromRGB(20, 60, 0), Color3.fromRGB(255, 255, 255))
	local field = makePart(lobe, "MindBlockField", Vector3.new(size.X + 2, h2 + 10, 0.6), base * CFrame.new(0, (h2 + 10) / 2, -size.Z / 2 - 0.5), Color3.fromRGB(255, 80, 200), Enum.Material.Neon)
	field.Transparency = 1
	field.CanCollide = false
	local home = makePart(lobe, "HomeZone", Vector3.new(size.X, 30, size.Z), base * CFrame.new(0, 15, 0), Color3.new(1, 1, 1))
	home.Transparency = 1
	home.CanCollide = false
	home.CanQuery = false
	lobe.Parent = parent
	return lobe
end

local function buildLobes(world)
	local f = folder(world, "Lobes")
	for i = 1, #WorldBuilder.LOBE_CENTERS do buildLobe(f, i) end
end

local function buildPlaza(world)
	local f = folder(world, "BrainStemPlaza")
	local c = WorldBuilder.PLAZA_CENTER
	makePart(f, "PlazaDisc", Vector3.new(1, 80, 80), CFrame.new(c + Vector3.new(0, 0.3, 10)) * CFrame.Angles(0, 0, math.pi / 2), FOLD, nil, Enum.PartType.Cylinder)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BrainSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(c + Vector3.new(0, 1, -10))
	spawn.Color = GOO
	spawn.Material = Enum.Material.Neon
	spawn.Duration = 0
	spawn.Parent = f
	local fountainBase = makePart(f, "GooFountain", Vector3.new(4, 14, 14), CFrame.new(c + Vector3.new(0, 2, 12)) * CFrame.Angles(0, 0, math.pi / 2), FOLD, nil, Enum.PartType.Cylinder)
	local gooTop = makePart(f, "FountainGoo", Vector3.new(0.6, 12, 12), CFrame.new(c + Vector3.new(0, 4.1, 12)) * CFrame.Angles(0, 0, math.pi / 2), GOO, Enum.Material.Neon, Enum.PartType.Cylinder)
	gooTop:SetAttribute("RemGlow", true)
	addLight(fountainBase, GOO, 18, 1.5)
	local frame = makePart(f, "NeonSignFrame", Vector3.new(54, 14, 2), CFrame.new(c + Vector3.new(0, 26, 40)) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(25, 0, 35))
	for _, x in ipairs({ -22, 22 }) do makePart(f, "SignPost", Vector3.new(2, 20, 2), CFrame.new(c + Vector3.new(x, 10, 40)), FOLD) end
	local signText = addSurfaceText(frame, Enum.NormalId.Front, "ROTTING BRAIN", Color3.fromRGB(255, 110, 200), GOO, 14)
	signText.Name = "NeonSignText"
	frame:SetAttribute("NeonSign", true)
	addLight(frame, Color3.fromRGB(255, 110, 200), 40, 2)
	for _, k in ipairs(KIOSKS) do
		local pos = c + k.offset
		makePart(f, k.name, Vector3.new(10, 4, 6), CFrame.lookAt(pos + Vector3.new(0, 2, 0), c + Vector3.new(0, 2, k.offset.Z)), k.color)
		makePart(f, k.name .. "Roof", Vector3.new(12, 1, 8), CFrame.new(pos + Vector3.new(0, 11, 0)), k.color, Enum.Material.Neon)
		for _, dz in ipairs({ -3.5, 3.5 }) do makePart(f, "KioskPost", Vector3.new(0.8, 7, 0.8), CFrame.new(pos + Vector3.new(0, 7.5, dz)), Color3.new(1, 1, 1)) end
		local board = makePart(f, k.name .. "Sign", Vector3.new(0.5, 3, 11), CFrame.new(pos + Vector3.new(0, 13, 0)), Color3.fromRGB(25, 0, 35))
		addSurfaceText(board, Enum.NormalId.Right, k.label, k.color)
	end
end

local function buildProductivityHQ(world)
	local f = folder(world, "ProductivityHQ")
	local c = Vector3.new(120, 0, -150)
	local wood = Color3.fromRGB(120, 75, 40)
	makePart(f, "HomeworkDesk", Vector3.new(50, 3, 28), CFrame.new(c + Vector3.new(0, 18, 0)), wood)
	for _, x in ipairs({ -22, 22 }) do for _, z in ipairs({ -11, 11 }) do makePart(f, "DeskLeg", Vector3.new(3, 17, 3), CFrame.new(c + Vector3.new(x, 8.5, z)), wood) end end
	for i, x in ipairs({ -30, -27, 28 }) do
		local h = 26 + i * 6
		makePart(f, "PencilTower", Vector3.new(h, 4, 4), CFrame.new(c + Vector3.new(x, h / 2, 6 - i * 4)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 205, 40), nil, Enum.PartType.Cylinder)
	end
	for i = 1, 5 do
		makePart(f, "HomeworkSheet", Vector3.new(8, 0.2, 10), CFrame.new(c + Vector3.new(-14 + i * 5, 19.6 + i * 0.2, 0)) * CFrame.Angles(0, i * 0.4, 0), Color3.new(1, 1, 1))
	end
	local alarm = makePart(f, "AlarmLight", Vector3.new(3, 3, 3), CFrame.new(c + Vector3.new(0, 21.5, 8)), Color3.fromRGB(255, 40, 40), Enum.Material.Neon, Enum.PartType.Ball)
	addLight(alarm, Color3.fromRGB(255, 40, 40), 30, 0).Name = "RaidLight"
	local sign = makePart(f, "HQSign", Vector3.new(30, 5, 1), CFrame.new(c + Vector3.new(0, 26, 14)) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(240, 240, 255))
	addSurfaceText(sign, Enum.NormalId.Back, "PRODUCTIVITY HQ", Color3.fromRGB(40, 80, 200), Color3.new(1, 1, 1))
end

local function buildSubconsciousGate(world)
	local f = folder(world, "DeepSubconscious")
	local c = Vector3.new(-120, 0, -150)
	local purple = Color3.fromRGB(120, 40, 200)
	for _, x in ipairs({ -10, 10 }) do makePart(f, "GatePost", Vector3.new(3, 20, 3), CFrame.new(c + Vector3.new(x, 10, 0)), purple) end
	local field = makePart(f, "DreamField", Vector3.new(17, 18, 0.5), CFrame.new(c + Vector3.new(0, 9, 0)), Color3.fromRGB(170, 90, 255), Enum.Material.Neon)
	field.Transparency = 0.5
	local sign = makePart(f, "GateSign", Vector3.new(24, 4, 1), CFrame.new(c + Vector3.new(0, 22, 0)) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(30, 0, 50))
	addSurfaceText(sign, Enum.NormalId.Back, "DEEP SUBCONSCIOUS · WASH 5", Color3.fromRGB(220, 180, 255))
	local rng = Random.new(5)
	for i = 1, 6 do
		local cloud = makePart(f, "DreamCloud", Vector3.new(10, 6, 8), CFrame.new(c + Vector3.new(rng:NextNumber(-30, 30), rng:NextNumber(4, 26), rng:NextNumber(-30, -6))), Color3.fromRGB(110, 60, 170), nil, Enum.PartType.Ball)
		cloud.CanCollide = false
	end
end

local MEME_SIGNS = {
	{ "SKIBIDI ZONE", Vector3.new(0, 18, -78) }, { "SIGMA GRINDSET", Vector3.new(0, 16, 0) },
	{ "OHIO", Vector3.new(-94, 42, -15) }, { "+1000 AURA", Vector3.new(94, 42, -15) },
	{ "RIZZ", Vector3.new(-62, 30, 62) }, { "NO CAP", Vector3.new(62, 30, 62) },
	{ "BRAIN ROT 100%", Vector3.new(-150, 50, -95) }, { "67", Vector3.new(150, 50, -95) },
	{ "GYATT-FREE ZONE", Vector3.new(-140, 40, 80) }, { "TUNG TUNG TUNG", Vector3.new(140, 40, 80) },
	{ "BOMBARDIRO", Vector3.new(-55, 52, -128) }, { "CERTIFIED BRAINROT", Vector3.new(55, 52, -128) },
}
local MEME_COLORS = {
	Color3.fromRGB(255, 230, 40), Color3.fromRGB(0, 230, 255), Color3.fromRGB(130, 255, 60), Color3.fromRGB(255, 80, 190),
	Color3.fromRGB(255, 140, 30), Color3.fromRGB(255, 255, 255),
}
local MEME_EMOJI = {
	{ "💀", Vector3.new(-26, 26, -92) }, { "🧠", Vector3.new(26, 30, -40) }, { "🗿", Vector3.new(-24, 24, 30) },
	{ "🔥", Vector3.new(28, 22, 40) }, { "😭", Vector3.new(-94, 30, 52) }, { "🤯", Vector3.new(94, 30, 52) },
	{ "💀", Vector3.new(120, 34, -80) }, { "🗿", Vector3.new(-120, 34, -80) },
}

-- Floating meme signs and emoji face the plaza camera side; parts with a Bob attribute float on the client.
local function buildMemeLayer(world)
	local f = folder(world, "MemeLayer")
	local facing = Vector3.new(0, 20, 150)
	for i, sign in ipairs(MEME_SIGNS) do
		local text, pos = sign[1], sign[2]
		local part = makePart(f, "MemeSign", Vector3.new(6 + #text * 3.4, 10, 0.2), CFrame.lookAt(pos, facing) * CFrame.Angles(0, 0, (i % 2 == 0 and 1 or -1) * 0.1), Color3.new(0, 0, 0))
		part.Transparency, part.CanCollide, part.CanQuery = 1, false, false
		part:SetAttribute("Bob", i)
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local label = addSurfaceText(part, face, text, MEME_COLORS[i % #MEME_COLORS + 1], Color3.new(0, 0, 0), 20)
			label.Font = Enum.Font.LuckiestGuy
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 6
			stroke.Parent = label
		end
	end
	for i, e in ipairs(MEME_EMOJI) do
		local anchor = makePart(f, "MemeEmoji", Vector3.new(1, 1, 1), CFrame.new(e[2]), Color3.new(0, 0, 0))
		anchor.Transparency, anchor.CanCollide, anchor.CanQuery = 1, false, false
		anchor:SetAttribute("Bob", i * 1.7)
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromScale(12, 12)
		gui.LightInfluence = 0
		gui.Parent = anchor
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Text = e[1]
		label.Parent = gui
	end
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -45, 15 }) do
			for k, x in ipairs({ 44.5, 49 }) do
				for _, arm in ipairs({ -1, 1 }) do
					local cf = CFrame.new(side * x, 0.2, z) * CFrame.Angles(0, side * arm * math.pi / 4, 0) * CFrame.new(0, 0, -arm * 1.6)
					makePart(f, "Chevron", Vector3.new(1.2, 0.2, 4.4), cf, k == 1 and Color3.fromRGB(255, 230, 40) or VEIN_LIME, Enum.Material.Neon).CanCollide = false
				end
			end
		end
	end
	local rng = Random.new(67)
	for i = 1, 10 do
		local pos = Vector3.new(rng:NextNumber(-28, 28), 0.1, rng:NextNumber(-95, 45))
		local d = rng:NextNumber(5, 10)
		makePart(f, "GooPuddle", Vector3.new(0.3, d, d * 0.8), CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6), math.pi / 2), GOO, Enum.Material.Neon, Enum.PartType.Cylinder).CanCollide = false
	end
	for i = 1, 8 do
		local pos = Vector3.new(rng:NextNumber(-30, 30), 0, rng:NextNumber(-95, 45))
		local h = rng:NextNumber(4, 8)
		makePart(f, "SparkStalk", Vector3.new(0.4, h, 0.4), CFrame.new(pos + Vector3.new(0, h / 2, 0)), NERVE).CanCollide = false
		local spark = makePart(f, "NeuronSpark", Vector3.new(1.8, 1.8, 1.8), CFrame.new(pos + Vector3.new(0, h + 0.6, 0)), NERVE, Enum.Material.Neon, Enum.PartType.Ball)
		spark.CanCollide = false
		local s = Instance.new("Sparkles")
		s.SparkleColor = Color3.fromRGB(200, 255, 255)
		s.Parent = spark
		if i <= 3 then addLight(spark, NERVE, 14, 0.8) end
	end
end

function WorldBuilder.applyLighting()
	local Lighting = game:GetService("Lighting")
	for _, c in ipairs(Lighting:GetChildren()) do c:Destroy() end
	Lighting.Ambient = Color3.fromRGB(60, 40, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(95, 80, 130)
	Lighting.Brightness = 2
	Lighting.ClockTime = 3 + 7 / 60
	Lighting.GlobalShadows = true
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Color = Color3.fromRGB(90, 30, 140)
	atmosphere.Decay = Color3.fromRGB(40, 15, 70)
	atmosphere.Haze = 0
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity, bloom.Size, bloom.Threshold = 0.5, 24, 2.2
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation, grade.Contrast = 0.45, 0.12
	grade.Parent = Lighting
end

function WorldBuilder.build()
	local old = workspace:FindFirstChild("BrainWorld")
	if old then old:Destroy() end
	local world = Instance.new("Folder")
	world.Name = "BrainWorld"
	for _, step in ipairs({ buildBrainFloor, buildSkullWall, buildMemeLobe, buildSynapseBelt, buildLobes, buildPlaza, buildProductivityHQ, buildSubconsciousGate, buildMemeLayer }) do
		step(world)
		task.wait()
	end
	world.Parent = workspace
	WorldBuilder.applyLighting()
	return world
end

function WorldBuilder.ensureWorld()
	return workspace:FindFirstChild("BrainWorld") or WorldBuilder.build()
end

return WorldBuilder
