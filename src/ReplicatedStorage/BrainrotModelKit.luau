-- Builds any of the 60 brainrots from its catalog row: a round body by body type, the shared face, feet and
-- pink brain cap, then the row's features and prop, the mutation look, the rarity extras and the name tag.
-- Every model faces -Z and pivots at the bottom center, so PivotTo on a podium top places it.
local RarityConfig = require(script.Parent.RarityConfig)
local MutationConfig = require(script.Parent.MutationConfig)
local NumberFormat = require(script.Parent.NumberFormat)

local BrainrotModelKit = {}

local BRAIN_CAP = Color3.fromHex("FF9EC7")
local BRAIN_FOLD = Color3.fromHex("C2407A")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.fromRGB(20, 15, 20)
local GOLD = Color3.fromRGB(255, 205, 40)
local NEON = Enum.Material.Neon
local RAINBOW = { Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 160, 40), Color3.fromRGB(255, 230, 50), Color3.fromRGB(80, 220, 90), Color3.fromRGB(60, 150, 255), Color3.fromRGB(170, 80, 255) }

local BODY_TYPES = {
	Blob = Vector3.new(3, 3, 3), Tall = Vector3.new(2.6, 3.8, 2.6), Wide = Vector3.new(3.8, 2.4, 3.2),
	Block = Vector3.new(3.2, 2.8, 2.4), Wedge = Vector3.new(3.4, 2.8, 2.6), Long = Vector3.new(2.6, 2.4, 4.4),
}

-- One part, welded to the body. kind: "ball" (stretched sphere), "block", "cyl" (axis X) or "wedge".
local function makeAdder(model, body, ctx)
	return function(kind, name, size, offset, color, material, transparency)
		local p = kind == "wedge" and Instance.new("WedgePart") or Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Transparency = transparency or 0
		p.CanCollide, p.CanTouch, p.Massless, p.Anchored = false, false, true, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if kind == "cyl" then p.Shape = Enum.PartType.Cylinder end
		if kind == "ball" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		end
		local cf = typeof(offset) == "CFrame" and offset or CFrame.new(offset)
		p.CFrame = body.CFrame * cf
		if color == ctx.bodyColor or color == ctx.bellyColor then p:SetAttribute("Skin", true) end
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = body, p
		weld.Parent = p
		p.Parent = model
		return p
	end
end

local function floatText(body, text, color, height, size)
	local attachment = Instance.new("Attachment")
	attachment.Name = "PropTextAnchor"
	attachment.Position = Vector3.new(0, height, 0)
	attachment.Parent = body
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(size or 2.4, 0, size or 2.4, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 90
	gui.Parent = attachment
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return label
end

local function sparkle(part, color)
	local s = Instance.new("Sparkles")
	s.SparkleColor = color
	s.Parent = part
	return s
end

-- Features: c is the build context (add, w, h, d, bx, by, bz, front(xFraction, yFraction), colors).
local FEATURES = {}
FEATURES.earsRound = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "Ear", Vector3.new(1, 1, 0.5), Vector3.new(s * c.w * 0.32, c.by * 0.9, 0), c.bodyColor) end end
FEATURES.earsBlack = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "Ear", Vector3.new(1, 1, 0.5), Vector3.new(s * c.w * 0.32, c.by * 0.9, 0), BLACK) end end
FEATURES.earsCat = function(c) for _, s in ipairs({ -1, 1 }) do c.add("wedge", "Ear", Vector3.new(0.3, 1.1, 0.9), CFrame.new(s * c.w * 0.28, c.by * 0.95, 0) * CFrame.Angles(0, math.pi / 2, s * 0.25), c.bodyColor) end end
FEATURES.earsPointed = FEATURES.earsCat
FEATURES.earsFloppy = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "Ear", Vector3.new(0.5, 1.6, 0.9), CFrame.new(s * (c.bx + 0.05), c.by * 0.35, -0.1) * CFrame.Angles(0, 0, s * 0.3), c.bodyColor:Lerp(BLACK, 0.25)) end end
FEATURES.earsLong = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "Ear", Vector3.new(0.6, 2.4, 0.7), CFrame.new(s * c.w * 0.18, c.by + 0.9, 0) * CFrame.Angles(0, 0, s * -0.15), c.bodyColor) end end
FEATURES.earsBig = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "Ear", Vector3.new(0.3, 2, 1.8), Vector3.new(s * (c.bx + 0.1), c.by * 0.35, 0.1), c.bodyColor:Lerp(WHITE, 0.15)) end end
FEATURES.tailThin = function(c) c.add("cyl", "Tail", Vector3.new(2.2, 0.25, 0.25), CFrame.new(0, -c.by * 0.3, c.bz + 0.7) * CFrame.Angles(0, math.pi / 2, 0.6), c.bodyColor) end
FEATURES.tailTip = function(c)
	c.add("ball", "Tail", Vector3.new(0.9, 0.9, 2), Vector3.new(0, -c.by * 0.3, c.bz + 0.6), c.bodyColor)
	c.add("ball", "TailTip", Vector3.new(0.7, 0.7, 0.8), Vector3.new(0, -c.by * 0.3, c.bz + 1.5), WHITE)
end
FEATURES.whaleTail = function(c) c.add("ball", "Tail", Vector3.new(2.6, 0.3, 1.2), Vector3.new(0, 0, c.bz + 0.5), c.bodyColor) end
FEATURES.eyeBumps = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "EyeBump", Vector3.new(1.2, 1.1, 1.2), Vector3.new(s * c.w * 0.22, c.by * 0.75, -c.bz * 0.45), c.bodyColor) end end
FEATURES.brainShell = function(c)
	c.add("ball", "BrainShell", Vector3.new(c.w * 0.9, c.h * 1.2, c.d * 0.55), Vector3.new(0, c.by * 0.55, c.bz * 0.35), BRAIN_CAP)
	for i = -1, 1 do c.add("ball", "ShellFold", Vector3.new(0.15, c.h * 0.9, c.d * 0.5), Vector3.new(i * c.w * 0.18, c.by * 0.6, c.bz * 0.35), BRAIN_FOLD) end
end
FEATURES.spots = function(c) for i = 1, 5 do c.add("ball", "Spot", Vector3.new(0.5, 0.5, 0.15), Vector3.new((i - 3) * c.w * 0.16, c.by * (i % 2 == 0 and -0.45 or 0.55), c.front(0.15, 0.4)), c.bodyColor:Lerp(BLACK, 0.4)) end end
FEATURES.chips = FEATURES.spots
FEATURES.holes = function(c) for i = 1, 4 do c.add("cyl", "Hole", Vector3.new(0.1, 0.6, 0.6), CFrame.new((i - 2.5) * c.w * 0.2, c.by * (i % 2 == 0 and -0.5 or 0.45), -c.bz - 0.02) * CFrame.Angles(0, math.pi / 2, 0), c.bodyColor:Lerp(BLACK, 0.3)) end end
FEATURES.dotHoles = FEATURES.holes
FEATURES.beak = function(c) c.add("ball", "Beak", Vector3.new(0.8, 0.45, 0.9), Vector3.new(0, -c.by * 0.05, c.front(0, 0) - 0.3), Color3.fromRGB(255, 150, 40)) end
FEATURES.hornsSmall = function(c) for _, s in ipairs({ -1, 1 }) do c.add("cyl", "Horn", Vector3.new(1.1, 0.35, 0.35), CFrame.new(s * c.w * 0.25, c.by + 0.2, 0.3) * CFrame.Angles(0, 0, math.pi / 2 - s * 0.4), Color3.fromRGB(230, 210, 170)) end end
FEATURES.horns = function(c) for _, s in ipairs({ -1, 1 }) do c.add("wedge", "Horn", Vector3.new(0.4, 1.2, 0.6), CFrame.new(s * c.w * 0.3, c.by + 0.3, 0.2), Color3.fromRGB(255, 230, 160)) end end
FEATURES.beard = function(c) c.add("ball", "Beard", Vector3.new(0.7, 1, 0.5), Vector3.new(0, -c.by * 0.55, c.front(0, -0.55) - 0.15), WHITE) end
FEATURES.mushroomCap = function(c)
	c.add("ball", "MushroomCap", Vector3.new(c.w * 1.6, c.h * 0.5, c.d * 1.6), Vector3.new(0, c.by * 0.9, 0), Color3.fromRGB(220, 40, 40))
	for i = 1, 4 do c.add("ball", "CapDot", Vector3.new(0.6, 0.3, 0.6), Vector3.new(math.cos(i * 1.6) * c.w * 0.55, c.by * 0.95 + 0.4, math.sin(i * 1.6) * c.d * 0.55), WHITE) end
	c.capLift += c.h * 0.22
end
FEATURES.leafTop = function(c) c.add("ball", "Leaf", Vector3.new(1.2, 0.25, 0.6), CFrame.new(0.6, c.by + 0.1, 0.4) * CFrame.Angles(0, 0.5, 0.3), Color3.fromRGB(60, 180, 60)) end
FEATURES.stem = function(c) c.add("cyl", "Stem", Vector3.new(1, 0.4, 0.4), CFrame.new(0.5, c.by + 0.4, 0.5) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(60, 160, 50)) end
FEATURES.cheeks = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "Cheek", Vector3.new(1, 1, 1), Vector3.new(s * c.bx * 0.85, -c.by * 0.2, -c.bz * 0.35), c.bodyColor) end end
FEATURES.fanTail = function(c) for i, color in ipairs(RAINBOW) do c.add("ball", "TailFeather", Vector3.new(0.5, 2.4, 0.3), CFrame.new(0, c.by * 0.3, c.bz + 0.2) * CFrame.Angles(0, 0, (i - 3.5) * 0.35) * CFrame.new(0, 1, 0), color) end end
FEATURES.spikes = function(c) for i = 1, 7 do c.add("wedge", "Spike", Vector3.new(0.3, 0.9, 0.6), CFrame.new((i - 4) * c.w * 0.12, c.by * 0.55, c.bz * 0.55) * CFrame.Angles(-0.6, math.pi, 0), c.bodyColor:Lerp(BLACK, 0.35)) end end
FEATURES.pepperoni = function(c) for i = 1, 3 do c.add("cyl", "Pepperoni", Vector3.new(0.1, 0.7, 0.7), CFrame.new((i - 2) * 0.9, -c.by * 0.45 + (i % 2) * 0.4, -c.bz - 0.03) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(190, 40, 30)) end end
FEATURES.layerStripes = function(c) for _, y in ipairs({ -0.4, 0.15 }) do c.add("block", "Layer", Vector3.new(c.w + 0.1, 0.3, c.d + 0.1), Vector3.new(0, c.by * y, 0), Color3.fromRGB(255, 220, 90)) end end
FEATURES.spaghettiHair = function(c) for i = 1, 7 do c.add("cyl", "Noodle", Vector3.new(1.6, 0.18, 0.18), CFrame.new((i - 4) * 0.35, c.by * 0.75, -c.bz * 0.3 + (i % 2) * 0.8) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 225, 120)) end end
FEATURES.ghost = function(c)
	c.body.Transparency = 0.4
	c.noFeet = true
	for i = 1, 3 do c.add("ball", "GhostTail", Vector3.new(0.9, 0.9, 0.9), Vector3.new((i - 2) * 0.8, -c.by - 0.2 - (i % 2) * 0.3, 0), c.bodyColor, nil, 0.4) end
end
FEATURES.cone = function(c)
	c.noFeet = true
	c.add("ball", "Cone", Vector3.new(c.w * 0.75, c.h * 1.1, c.d * 0.75), Vector3.new(0, -c.by * 1.05, 0), c.bellyColor)
	c.skipBelly = true
end
FEATURES.eyeBags = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "EyeBag", Vector3.new(0.8, 0.25, 0.2), Vector3.new(s * c.w * 0.2, c.by * 0.0, c.front(0.4, 0) - 0.05), Color3.fromRGB(110, 70, 120)) end end
FEATURES.ring = function(c) c.add("cyl", "RingBand", Vector3.new(0.6, c.w * 1.05, c.d * 1.05), CFrame.new(0, -c.by * 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), c.bodyColor:Lerp(WHITE, 0.3)) end
FEATURES.claws = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "Claw", Vector3.new(1.3, 1, 0.9), Vector3.new(s * (c.bx + 0.6), 0, -c.bz * 0.4), c.bodyColor) end end
FEATURES.backFin = function(c) c.add("wedge", "BackFin", Vector3.new(0.3, 1.6, 1.4), CFrame.new(0, c.by + 0.4, c.bz * 0.2), c.bodyColor) end
FEATURES.teeth = function(c) for i = -2, 2 do c.add("wedge", "Tooth", Vector3.new(0.25, 0.3, 0.1), CFrame.new(i * 0.28, -c.by * 0.28, c.front(0, -0.3) - 0.05) * CFrame.Angles(math.pi, 0, 0), WHITE) end end
local function tentacles(c, count)
	c.noFeet = true
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		c.add("cyl", "Tentacle", Vector3.new(1.8, 0.5, 0.5), CFrame.new(math.cos(a) * c.bx * 0.7, -c.by * 0.95, math.sin(a) * c.bz * 0.7) * CFrame.Angles(0, -a, -0.6), c.bodyColor)
	end
end
FEATURES.tentacles6 = function(c) tentacles(c, 6) end
FEATURES.tentacles8 = function(c) tentacles(c, 8) end
FEATURES.longArms = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "Arm", Vector3.new(0.6, 2.6, 0.6), CFrame.new(s * (c.bx + 0.1), -c.by * 0.2, -c.bz * 0.3) * CFrame.Angles(0, 0, s * 0.2), c.bodyColor) end end
FEATURES.longLegs = function(c)
	c.noFeet = true
	for _, s in ipairs({ -1, 1 }) do c.add("cyl", "Leg", Vector3.new(2.6, 0.25, 0.25), CFrame.new(s * 0.45, -c.by - 1.2, 0) * CFrame.Angles(0, 0, math.pi / 2), c.bodyColor:Lerp(BLACK, 0.2)) end
end
FEATURES.longNeck = function(c)
	c.add("ball", "Neck", Vector3.new(1, 2.2, 1), Vector3.new(0, c.by + 0.7, -c.bz * 0.3), c.bodyColor)
	c.capLift += 1.2
end
FEATURES.fluff = function(c) c.add("ball", "Fluff", Vector3.new(c.w * 0.7, 0.9, c.d * 0.7), Vector3.new(0, c.by + 0.2, 0), WHITE) end
FEATURES.fur = function(c) for i = 1, 8 do c.add("ball", "Fur", Vector3.new(1, 1.2, 1), Vector3.new(math.cos(i) * c.bx * 0.9, -c.by * 0.5, math.sin(i) * c.bz * 0.9), c.bodyColor:Lerp(BLACK, 0.2)) end end
FEATURES.eyePatches = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "EyePatch", Vector3.new(1.2, 1.4, 0.4), Vector3.new(s * c.w * 0.2, c.by * 0.1, c.front(0.4, 0.15) + 0.05), BLACK) end end
FEATURES.crimp = function(c) c.add("block", "Crimp", Vector3.new(c.w + 0.5, c.h + 0.5, 0.4), Vector3.new(0, 0, 0), c.bodyColor:Lerp(WHITE, 0.25)) end
FEATURES.feetOrange = function(c) c.footColor = Color3.fromRGB(255, 150, 40) end
FEATURES.mane = function(c) c.add("ball", "Mane", Vector3.new(c.w * 1.55, c.h * 1.35, 0.9), Vector3.new(0, c.by * 0.25, c.bz * 0.25), Color3.fromRGB(190, 110, 30)) end
FEATURES.stripes = function(c) for i = -1, 1 do c.add("block", "Stripe", Vector3.new(0.25, c.h * 0.5, c.d * 0.95), Vector3.new(i * c.w * 0.3, c.by * 0.35, 0.05), BLACK) end end
FEATURES.wings = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "Wing", Vector3.new(0.3, 1.8, 2.4), CFrame.new(s * (c.bx + 0.2), c.by * 0.2, 0.3) * CFrame.Angles(0.4, 0, s * 0.5), c.bodyColor:Lerp(BLACK, 0.15)) end end
FEATURES.angelWings = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "AngelWing", Vector3.new(0.3, 2.6, 3.2), CFrame.new(s * (c.bx + 0.4), c.by * 0.3, 0.4) * CFrame.Angles(0.4, 0, s * 0.6), WHITE, NEON) end end
FEATURES.flameWings = function(c)
	for _, s in ipairs({ -1, 1 }) do
		local wing = c.add("ball", "FlameWing", Vector3.new(0.3, 2.2, 2.8), CFrame.new(s * (c.bx + 0.3), c.by * 0.3, 0.3) * CFrame.Angles(0.4, 0, s * 0.6), Color3.fromRGB(255, 120, 30), NEON)
		Instance.new("Fire", wing).Size = 3
	end
end
FEATURES.spout = function(c) for i = -1, 1 do c.add("cyl", "Spout", Vector3.new(1.6, 0.25, 0.25), CFrame.new(i * 0.4, c.by + 1.2, 0.3) * CFrame.Angles(0, 0, math.pi / 2 + i * 0.4), Color3.fromRGB(140, 210, 255), NEON, 0.3) end end
FEATURES.snout = function(c)
	c.add("ball", "Snout", Vector3.new(c.w * 0.6, c.h * 0.4, 2), Vector3.new(0, -c.by * 0.15, c.front(0, -0.15) - 0.6), c.bodyColor)
	c.mouthForward = 1.4
end
FEATURES.trunk = function(c) c.add("cyl", "Trunk", Vector3.new(2, 0.6, 0.6), CFrame.new(0, -c.by * 0.35, c.front(0, -0.3) - 0.2) * CFrame.Angles(0, 0, math.pi / 2 - 0.25), c.bodyColor) end
FEATURES.tusks = function(c) for _, s in ipairs({ -1, 1 }) do c.add("cyl", "Tusk", Vector3.new(1.6, 0.3, 0.3), CFrame.new(s * 0.6, -c.by * 0.45, c.front(0.2, -0.4) - 0.5) * CFrame.Angles(0, math.pi / 2, -0.5), WHITE) end end
FEATURES.unicornHorn = function(c)
	local horn = c.add("cyl", "UnicornHorn", Vector3.new(1.8, 0.35, 0.35), CFrame.new(0, c.by * 0.75, c.front(0, 0.7) - 0.4) * CFrame.Angles(0, math.pi / 2, math.pi / 2 - 0.4), GOLD, NEON)
	sparkle(horn, GOLD)
end
FEATURES.rainbowMane = function(c) for i, color in ipairs(RAINBOW) do c.add("ball", "Mane", Vector3.new(0.6, 0.9, 0.6), Vector3.new(0, c.by * (0.9 - i * 0.22), c.bz * (0.55 + i * 0.06)), color) end end
FEATURES.bigBrain = function(c) c.capScale = 1.6 end
FEATURES.brainBody = function(c) for i = -2, 2 do c.add("ball", "BodyFold", Vector3.new(0.2, c.h * 0.8, c.d * 0.95), CFrame.new(i * c.w * 0.18, 0, 0) * CFrame.Angles(0, 0, i * 0.15), BRAIN_FOLD) end end
FEATURES.grassHair = function(c) for i = 1, 10 do c.add("wedge", "GrassBlade", Vector3.new(0.2, 1.4, 0.4), CFrame.new(math.cos(i * 0.63) * c.bx * 0.6, c.by + 0.3, math.sin(i * 0.63) * c.bz * 0.6) * CFrame.Angles(0, i, 0.2), Color3.fromRGB(70, 200, 50)) end end
FEATURES.sharpJaw = function(c) c.add("wedge", "Jaw", Vector3.new(c.w * 0.7, 0.8, 0.8), CFrame.new(0, -c.by * 0.6, c.front(0, -0.6) - 0.1) * CFrame.Angles(math.pi, 0, 0), c.bodyColor) end
FEATURES.slickHair = function(c) c.add("ball", "SlickHair", Vector3.new(c.w * 0.9, 0.6, c.d * 0.8), Vector3.new(0, c.by * 0.85, 0.3), BLACK) end
FEATURES.riceDots = function(c) for i = 1, 8 do c.add("ball", "Rice", Vector3.new(0.3, 0.2, 0.2), Vector3.new(math.cos(i) * c.bx * 0.5, c.by * 0.75, math.sin(i) * c.bz * 0.5), WHITE) end end
FEATURES.bowl = function(c)
	c.noFeet = true
	c.add("ball", "Bowl", Vector3.new(c.w * 1.2, c.h * 0.8, c.d * 1.2), Vector3.new(0, -c.by * 0.6, 0), Color3.fromRGB(240, 240, 255))
end
FEATURES.comb = function(c) for i = -1, 1 do c.add("ball", "Comb", Vector3.new(0.4, 0.8, 0.5), Vector3.new(i * 0.35, c.by + 0.1, -c.bz * 0.45), Color3.fromRGB(230, 40, 40)) end end
FEATURES.gooDrips = function(c) for i = 1, 5 do c.add("ball", "GooDrip", Vector3.new(0.4, 1.2, 0.4), Vector3.new((i - 3) * c.w * 0.2, -c.by * 0.3, c.front((i - 3) * 0.2, -0.3) + 0.1), Color3.fromRGB(110, 255, 60), NEON) end end
FEATURES.sleepyEyes = function(c) c.eyeStyle = "sleepy" end
FEATURES.calmEyes = FEATURES.sleepyEyes
FEATURES.wideEyes = function(c) c.eyeStyle = "wide" end
FEATURES.scared = function(c) c.eyeStyle = "wide"; c.mouthStyle = "open" end
FEATURES.oneEye = function(c) c.eyeStyle = "one" end
FEATURES.manyEyes = function(c) c.eyeStyle = "many" end

-- Props: one object from the name, placed on or around the body.
local PROPS = {}
PROPS.thoughtBubble = function(c) for i, s in ipairs({ 0.4, 0.7, 1.6 }) do c.add("ball", "ThoughtBubble", Vector3.new(s, s * 0.8, s), Vector3.new(0.6 + i * 0.4, c.top + i * 0.6, 0), WHITE) end end
PROPS.mirror = function(c)
	c.add("cyl", "Mirror", Vector3.new(0.15, 1.3, 1.3), CFrame.new(c.bx + 0.6, 0.3, -0.6) * CFrame.Angles(0, 0.8, 0), Color3.fromRGB(200, 240, 255), Enum.Material.Glass)
	c.add("block", "MirrorHandle", Vector3.new(0.2, 1, 0.2), Vector3.new(c.bx + 0.6, -0.6, -0.6), Color3.fromRGB(255, 120, 200))
end
PROPS.loadingSign = function(c) floatText(c.body, "LOADING...", WHITE, c.top + 0.8, 2) end
PROPS.pillow = function(c) c.add("ball", "Pillow", Vector3.new(2.4, 0.7, 1.6), Vector3.new(c.bx + 0.6, -c.by + 0.3, 0.6), Color3.fromRGB(200, 220, 255)) end
PROPS.questionMark = function(c) floatText(c.body, "?", Color3.fromRGB(255, 230, 60), c.top + 1.2) end
PROPS.tripleQuestion = function(c) floatText(c.body, "???", Color3.fromRGB(255, 230, 60), c.top + 1.2, 3) end
PROPS.bufferRing = function(c) c.add("cyl", "BufferRing", Vector3.new(0.2, 1.6, 1.6), CFrame.new(0, c.top + 1.2, 0) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(80, 220, 255), NEON, 0.2) end
PROPS.steam = function(c) for i = 1, 3 do c.add("ball", "Steam", Vector3.new(0.7, 0.7, 0.7), Vector3.new((i - 2) * 0.7, c.top + 0.4 + i * 0.35, 0), WHITE, nil, 0.4) end end
PROPS.nightCap = function(c)
	c.add("wedge", "NightCap", Vector3.new(1.2, 1.6, 1.2), CFrame.new(-0.5, c.top + 0.5, 0) * CFrame.Angles(0, 0, 0.5), Color3.fromRGB(70, 90, 200))
	c.add("ball", "CapPom", Vector3.new(0.5, 0.5, 0.5), Vector3.new(-1.3, c.top + 0.8, 0), WHITE)
	floatText(c.body, "Zzz", Color3.fromRGB(200, 220, 255), c.top + 1.8)
end
PROPS.fogCloud = function(c) for i = 1, 4 do c.add("ball", "FogPuff", Vector3.new(2, 1.2, 1.6), Vector3.new(math.cos(i * 1.6) * (c.bx + 0.4), -c.by * 0.5 + i * 0.3, math.sin(i * 1.6) * (c.bz + 0.4)), Color3.fromRGB(200, 200, 215), nil, 0.35) end end
PROPS.bandage = function(c) c.add("block", "Bandage", Vector3.new(1.4, 0.4, 0.15), CFrame.new(c.bx * 0.4, c.by * 0.55, c.front(0.3, 0.55) - 0.05) * CFrame.Angles(0, 0, 0.6), Color3.fromRGB(255, 225, 190)) end
PROPS.bandageQuestion = function(c) PROPS.bandage(c); PROPS.questionMark(c) end
PROPS.sweat = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "SweatDrop", Vector3.new(0.3, 0.5, 0.3), Vector3.new(s * (c.bx * 0.8), c.by * 0.5, -c.bz * 0.5), Color3.fromRGB(120, 200, 255), NEON) end end
PROPS.phone = function(c)
	c.add("block", "Phone", Vector3.new(0.8, 1.3, 0.15), CFrame.new(0, -c.by * 0.25, c.front(0, -0.25) - 0.5) * CFrame.Angles(-0.4, 0, 0), BLACK)
	c.add("block", "PhoneScreen", Vector3.new(0.65, 1.1, 0.05), CFrame.new(0, -c.by * 0.25, c.front(0, -0.25) - 0.6) * CFrame.Angles(-0.4, 0, 0), Color3.fromRGB(120, 200, 255), NEON)
end
PROPS.paperBag = function(c) c.add("block", "PaperBag", Vector3.new(1.4, 1.2, 1.4), CFrame.new(c.bx * 0.6, c.top, 0) * CFrame.Angles(0, 0.3, -0.5), Color3.fromRGB(200, 160, 110)) end
PROPS.sunglasses = function(c)
	for _, s in ipairs({ -1, 1 }) do c.add("block", "Lens", Vector3.new(0.9, 0.55, 0.1), Vector3.new(s * c.w * 0.2, c.by * 0.15, c.front(0.4, 0.15) - 0.55), BLACK) end
	c.add("block", "Bridge", Vector3.new(c.w * 0.6, 0.12, 0.1), Vector3.new(0, c.by * 0.25, c.front(0, 0.25) - 0.55), BLACK)
end
PROPS.stickyNote = function(c) c.add("block", "StickyNote", Vector3.new(0.9, 0.9, 0.05), CFrame.new(-c.bx * 0.5, c.by * 0.55, c.front(-0.4, 0.5) - 0.05) * CFrame.Angles(0, 0, 0.2), Color3.fromRGB(255, 240, 80), NEON) end
PROPS.coffee = function(c)
	c.add("cyl", "Cup", Vector3.new(1, 0.7, 0.7), CFrame.new(c.bx + 0.4, -0.2, -0.6) * CFrame.Angles(0, 0, math.pi / 2), WHITE)
	c.add("cyl", "Coffee", Vector3.new(0.05, 0.6, 0.6), CFrame.new(c.bx + 0.4, 0.31, -0.6) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(90, 50, 20))
end
PROPS.coffeeSweat = function(c) PROPS.coffee(c); PROPS.sweat(c) end
PROPS.lightBulbOff = function(c)
	c.add("ball", "Bulb", Vector3.new(1, 1.2, 1), Vector3.new(0, c.top + 1.2, 0), Color3.fromRGB(170, 170, 170), Enum.Material.Glass, 0.2)
	c.add("cyl", "BulbBase", Vector3.new(0.4, 0.5, 0.5), CFrame.new(0, c.top + 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(120, 120, 120))
end
PROPS.loadingBar = function(c)
	c.add("block", "LoadingFrame", Vector3.new(2.4, 0.5, 0.15), Vector3.new(0, c.top + 0.9, 0), BLACK)
	c.add("block", "LoadingFill", Vector3.new(0.8, 0.35, 0.2), Vector3.new(-0.7, c.top + 0.9, 0), Color3.fromRGB(80, 255, 80), NEON)
end
PROPS.floppyDisk = function(c)
	c.add("block", "FloppyDisk", Vector3.new(1.2, 1.2, 0.15), CFrame.new(c.bx + 0.3, 0, -0.6) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(40, 80, 200))
	c.add("block", "FloppyMetal", Vector3.new(0.6, 0.4, 0.2), CFrame.new(c.bx + 0.3, 0.35, -0.6) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(200, 200, 210))
end
PROPS.fork = function(c) c.add("cyl", "Fork", Vector3.new(2.2, 0.18, 0.18), CFrame.new(c.bx + 0.5, 0.2, -0.4) * CFrame.Angles(0, 0, math.pi / 2 - 0.3), Color3.fromRGB(200, 200, 210), Enum.Material.Metal) end
PROPS.headphones = function(c)
	c.add("cyl", "Headband", Vector3.new(0.3, c.w + 0.4, c.w + 0.4), CFrame.new(0, c.by * 0.3, 0) * CFrame.Angles(0, math.pi / 2, 0), BLACK)
	for _, s in ipairs({ -1, 1 }) do c.add("cyl", "EarCup", Vector3.new(0.5, 1.1, 1.1), Vector3.new(s * (c.bx + 0.1), c.by * 0.1, 0), Color3.fromRGB(255, 60, 120)) end
end
PROPS.headset = function(c)
	PROPS.headphones(c)
	c.add("cyl", "Mic", Vector3.new(1.4, 0.15, 0.15), CFrame.new(c.bx * 0.7, -c.by * 0.2, -c.bz * 0.7) * CFrame.Angles(0, 0.8, 0), BLACK)
end
PROPS.ghostWisp = function(c) for i = 1, 3 do c.add("ball", "Wisp", Vector3.new(0.5, 0.5, 0.5), Vector3.new(math.cos(i * 2) * (c.bx + 0.8), c.by * 0.3 * i, math.sin(i * 2) * (c.bz + 0.8)), Color3.fromRGB(180, 255, 200), NEON, 0.3) end end
PROPS.sprinkles = function(c) for i = 1, 10 do c.add("block", "Sprinkle", Vector3.new(0.12, 0.12, 0.35), CFrame.new(math.cos(i) * c.bx * 0.5, c.by * 0.8, math.sin(i) * c.bz * 0.5) * CFrame.Angles(0, i, 0), RAINBOW[i % 6 + 1]) end end
PROPS.clock = function(c)
	c.add("cyl", "Clock", Vector3.new(0.2, 1.4, 1.4), CFrame.new(c.bx + 0.5, 0.2, -0.5) * CFrame.Angles(0, math.pi / 2 + 0.5, 0), WHITE)
	floatText(c.body, "TIC TAC", Color3.fromRGB(255, 230, 60), c.top + 0.9, 2)
end
PROPS.orange = function(c) c.add("ball", "Orange", Vector3.new(1, 1, 1), Vector3.new(0, c.top + 0.3, 0), Color3.fromRGB(255, 140, 20)) end
PROPS.clawsUp = function(c) for _, s in ipairs({ -1, 1 }) do c.add("ball", "RaisedClaw", Vector3.new(0.9, 1.4, 0.8), Vector3.new(s * (c.bx + 0.5), c.by + 0.4, -0.3), c.bodyColor) end end
PROPS.sparks = function(c) for i = 1, 4 do sparkle(c.add("block", "Spark", Vector3.new(0.2, 0.8, 0.2), CFrame.new(math.cos(i * 1.6) * (c.bx + 0.4), c.by * 0.6, math.sin(i * 1.6) * (c.bz + 0.4)) * CFrame.Angles(0, 0, 0.7), Color3.fromRGB(255, 240, 60), NEON), Color3.fromRGB(255, 240, 60)) end end
PROPS.lightning = function(c) for i = 1, 3 do c.add("block", "Bolt", Vector3.new(0.3, 1.2, 0.2), CFrame.new(c.bx * 0.4 * (i - 2), c.top + 0.6 + (i % 2) * 0.5, 0) * CFrame.Angles(0, 0, 0.6 * ((i % 2) * 2 - 1)), Color3.fromRGB(255, 240, 60), NEON) end end
PROPS.monocle = function(c) c.add("cyl", "Monocle", Vector3.new(0.12, 1.1, 1.1), CFrame.new(c.w * 0.2, c.by * 0.15, c.front(0.4, 0.15) - 0.6) * CFrame.Angles(0, math.pi / 2, 0), GOLD, NEON) end
PROPS.camera = function(c)
	c.add("block", "Camera", Vector3.new(1.4, 0.9, 0.7), Vector3.new(0, -c.by * 0.35, c.front(0, -0.35) - 0.5), BLACK)
	c.add("cyl", "Lens", Vector3.new(0.4, 0.6, 0.6), CFrame.new(0, -c.by * 0.35, c.front(0, -0.35) - 0.95) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(80, 140, 255), NEON)
end
PROPS.screw = function(c) c.add("cyl", "Screw", Vector3.new(1.6, 0.35, 0.35), CFrame.new(0.3, c.top + 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2 - 0.3), Color3.fromRGB(190, 190, 200), Enum.Material.Metal) end
PROPS.tinfoil = function(c) c.add("wedge", "TinfoilHat", Vector3.new(1.6, 1.4, 1.6), Vector3.new(0, c.top + 0.4, 0), Color3.fromRGB(220, 220, 230), Enum.Material.Foil) end
PROPS.goldChain = function(c)
	PROPS.sunglasses(c)
	c.add("cyl", "GoldChain", Vector3.new(0.2, c.w * 0.9, c.d * 0.9), CFrame.new(0, -c.by * 0.35, -0.2) * CFrame.Angles(0.5, 0, math.pi / 2), GOLD, Enum.Material.Foil)
end
PROPS.scarf = function(c) c.add("cyl", "Scarf", Vector3.new(0.6, c.w * 0.98, c.d * 0.98), CFrame.new(0, -c.by * 0.15, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(40, 240, 255), NEON) end
local function crown(c, y)
	c.add("cyl", "Crown", Vector3.new(0.6, 1.4, 1.4), CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), GOLD, Enum.Material.Foil)
	for i = 1, 5 do c.add("wedge", "CrownPoint", Vector3.new(0.2, 0.5, 0.3), CFrame.new(math.cos(i * 1.26) * 0.6, y + 0.5, math.sin(i * 1.26) * 0.6) * CFrame.Angles(0, -i * 1.26, 0), GOLD, Enum.Material.Foil) end
end
PROPS.crown = function(c) crown(c, c.top + 0.3) end
PROPS.siren = function(c)
	local siren = c.add("ball", "Siren", Vector3.new(1, 0.9, 1), Vector3.new(0, c.top + 0.4, 0), Color3.fromRGB(255, 40, 40), NEON)
	local light = Instance.new("PointLight", siren)
	light.Color, light.Range, light.Brightness = Color3.fromRGB(255, 40, 40), 8, 1
end
PROPS.partyHat = function(c) c.add("wedge", "PartyHat", Vector3.new(1, 1.8, 1), CFrame.new(0.4, c.top + 0.7, 0) * CFrame.Angles(0, 0, -0.2), Color3.fromRGB(255, 80, 200)) end
PROPS.seahorse = function(c) c.add("ball", "Seahorse", Vector3.new(0.4, 0.9, 0.4), Vector3.new(0, -c.by * 0.1, c.front(0, -0.1) - 1.5), Color3.fromRGB(255, 160, 60)) end
PROPS.zipper = function(c) c.add("block", "Zipper", Vector3.new(0.25, 0.3, c.d * 0.6), Vector3.new(0, c.top - 0.1, 0), Color3.fromRGB(200, 200, 210), Enum.Material.Metal) end
PROPS.heartBreath = function(c) for i = 1, 3 do c.add("ball", "Heart", Vector3.new(0.5, 0.5, 0.2), Vector3.new((i - 2) * 0.4, -c.by * 0.1 + i * 0.3, c.front(0, 0) - 0.6 - i * 0.5), Color3.fromRGB(255, 80, 160), NEON) end end
PROPS.rainbowTrail = function(c) for i, color in ipairs(RAINBOW) do c.add("block", "RainbowTrail", Vector3.new(0.4, 0.3, 1.2), Vector3.new(0, -c.by * 0.3 + i * 0.3, c.bz + 0.8), color, NEON) end end
PROPS.captainHat = function(c)
	c.add("cyl", "CaptainHat", Vector3.new(0.7, 1.8, 1.8), CFrame.new(0, c.top + 0.35, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(30, 40, 90))
	c.add("cyl", "HatBand", Vector3.new(0.2, 1.85, 1.85), CFrame.new(0, c.top + 0.15, 0) * CFrame.Angles(0, 0, math.pi / 2), WHITE)
end
PROPS.fire = function(c) Instance.new("Fire", c.body).Size = 4 end
PROPS.iceBlock = function(c) c.add("block", "IceBlock", Vector3.new(1.4, 1.4, 1.4), Vector3.new(c.bx + 1, -c.by + 0.7, 0), Color3.fromRGB(170, 230, 255), Enum.Material.Ice, 0.3) end
PROPS.royal = function(c)
	crown(c, c.top + 0.3)
	c.add("ball", "Cape", Vector3.new(c.w * 1.1, c.h * 1.1, 0.4), Vector3.new(0, -c.by * 0.1, c.bz + 0.1), Color3.fromRGB(180, 20, 40))
	c.add("cyl", "Scepter", Vector3.new(2.6, 0.2, 0.2), CFrame.new(c.bx + 0.5, 0, -0.5) * CFrame.Angles(0, 0, math.pi / 2), GOLD, Enum.Material.Foil)
	c.add("ball", "ScepterGem", Vector3.new(0.6, 0.6, 0.6), Vector3.new(c.bx + 0.5, 1.4, -0.5), Color3.fromRGB(255, 60, 160), NEON)
end
PROPS.lawn = function(c)
	c.add("block", "LawnPatch", Vector3.new(2, 0.3, 2), Vector3.new(c.bx + 1.4, -c.by, -0.4), Color3.fromRGB(60, 200, 50))
	floatText(c.body, "NO.", Color3.fromRGB(255, 80, 80), c.top + 1, 2)
end
PROPS.briefcase = function(c)
	PROPS.sunglasses(c)
	c.add("block", "Briefcase", Vector3.new(1.4, 1, 0.4), Vector3.new(c.bx + 0.5, -c.by * 0.5, -0.3), Color3.fromRGB(90, 50, 25))
end
PROPS.laurel = function(c)
	c.add("cyl", "Laurel", Vector3.new(0.3, c.w * 0.7, c.d * 0.7), CFrame.new(0, c.top - 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(80, 170, 60))
	c.add("block", "Toga", Vector3.new(0.5, c.h * 0.9, c.d * 1.02), CFrame.new(c.bx * 0.2, -c.by * 0.1, 0) * CFrame.Angles(0, 0, 0.5), WHITE)
end
local function halo(c, y)
	local ring = c.add("cyl", "Halo", Vector3.new(0.25, 2.2, 2.2), CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), GOLD, NEON)
	return ring
end
PROPS.infiniteAura = function(c)
	halo(c, c.top + 1.1)
	c.add("ball", "RainbowAura", Vector3.new(c.w * 2.2, c.h * 1.8, c.d * 2.2), Vector3.new(0, 0, 0), Color3.fromRGB(255, 120, 255), NEON, 0.85)
	floatText(c.body, "+∞ AURA", GOLD, c.top + 2.2, 2.6)
end
PROPS.flies = function(c)
	c.add("cyl", "GooPuddle", Vector3.new(0.2, c.w * 1.8, c.w * 1.8), CFrame.new(0, -c.by - 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(110, 255, 60), NEON)
	for i = 1, 5 do c.add("ball", "Fly", Vector3.new(0.25, 0.25, 0.25), Vector3.new(math.cos(i * 1.3) * (c.bx + 0.8), c.top - 0.5 + (i % 3) * 0.5, math.sin(i * 1.3) * (c.bz + 0.8)), BLACK) end
end
PROPS.floatingEyes = function(c)
	for i = 1, 4 do
		local pos = Vector3.new(math.cos(i * 1.57) * (c.bx + 1), c.by * 0.5 + (i % 2) * 0.8, math.sin(i * 1.57) * (c.bz + 1))
		c.add("ball", "FloatingEye", Vector3.new(0.8, 0.8, 0.8), pos, WHITE)
		c.add("ball", "FloatingPupil", Vector3.new(0.4, 0.4, 0.4), pos + Vector3.new(0, 0, -0.3), BLACK)
	end
end
PROPS.haloHearts = function(c)
	halo(c, c.top + 1.1)
	for i = 1, 4 do c.add("ball", "FallingHeart", Vector3.new(0.5, 0.5, 0.2), Vector3.new(math.cos(i * 1.57) * (c.bx + 0.9), c.by * 0.2 * i, math.sin(i * 1.57) * (c.bz + 0.9)), Color3.fromRGB(255, 80, 160), NEON) end
end

local function buildEye(c, x, y, scale)
	local z = c.front(x / c.bx * 0.9, y / c.by * 0.9)
	c.add("ball", "Eye", Vector3.new(0.95, 1.05, 0.6) * scale, Vector3.new(x, y, z - 0.05), WHITE)
	c.add("ball", "Pupil", Vector3.new(0.55, 0.65, 0.3) * scale, Vector3.new(x, y - 0.05, z - 0.3 * scale), BLACK)
	c.add("ball", "Highlight", Vector3.new(0.2, 0.2, 0.1) * scale, Vector3.new(x + 0.12 * scale, y + 0.15 * scale, z - 0.45 * scale), WHITE, NEON)
	if c.eyeStyle == "sleepy" then
		c.add("ball", "Eyelid", Vector3.new(1.05, 0.6, 0.65) * scale, Vector3.new(x, y + 0.25 * scale, z - 0.1), c.bodyColor)
	end
end

local function buildFace(c)
	local eyeY = c.by * 0.18
	if c.eyeStyle == "one" then
		buildEye(c, 0, eyeY, 1.7)
	elseif c.eyeStyle == "many" then
		for i, p in ipairs({ { -0.5, 0.3 }, { 0.5, 0.3 }, { 0, 0.55 }, { -0.25, 0 }, { 0.3, -0.05 } }) do buildEye(c, p[1] * c.bx, p[2] * c.by, i == 3 and 0.9 or 0.7) end
	else
		local scale = c.eyeStyle == "wide" and 1.25 or 1
		for _, s in ipairs({ -1, 1 }) do buildEye(c, s * c.w * 0.19, eyeY, scale) end
	end
	for _, s in ipairs({ -1, 1 }) do
		c.add("ball", "Blush", Vector3.new(0.6, 0.3, 0.1), Vector3.new(s * c.w * 0.33, -c.by * 0.05, c.front(0.66, -0.05) - 0.02), Color3.fromRGB(255, 130, 170))
	end
	local mouthZ = c.front(0, -0.25) - 0.02 - (c.mouthForward or 0)
	if c.mouthStyle == "open" then
		c.add("ball", "Mouth", Vector3.new(0.5, 0.6, 0.12), Vector3.new(0, -c.by * 0.28, mouthZ), BLACK)
	else
		c.add("block", "Mouth", Vector3.new(0.55, 0.12, 0.1), Vector3.new(0, -c.by * 0.25, mouthZ), Color3.fromRGB(90, 20, 40))
	end
end

local function buildBrainCap(c)
	local scale = c.capScale or 1
	local y = c.by * 0.86 + c.capLift
	local size = Vector3.new(c.w * 0.62, c.h * 0.3, c.d * 0.55) * scale
	c.add("ball", "BrainCap", size, Vector3.new(0, y, 0.05), BRAIN_CAP)
	c.add("block", "BrainSplit", Vector3.new(0.12, size.Y * 0.5, size.Z * 0.9), Vector3.new(0, y + size.Y * 0.28, 0.05), BRAIN_FOLD)
	for _, s in ipairs({ -1, 1 }) do
		c.add("ball", "BrainFold", Vector3.new(0.14, size.Y * 0.55, size.Z * 0.7), CFrame.new(s * size.X * 0.24, y + size.Y * 0.22, 0.05) * CFrame.Angles(0.3 * s, 0, s * 0.35), BRAIN_FOLD)
	end
	c.top = y + size.Y / 2
end

local function applyRarityExtras(model, c, rarity)
	local tier = rarity.tier
	if tier >= 3 then
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness = rarity.color, 4 + tier, 0.6
		light.Parent = c.body
	end
	if tier >= 4 then sparkle(c.body, rarity.color) end
	if tier >= 5 then c.add("cyl", "AuraRing", Vector3.new(0.15, c.w * 1.5, c.w * 1.5), CFrame.new(0, -c.by - 0.35, 0) * CFrame.Angles(0, 0, math.pi / 2), rarity.color, NEON, 0.55) end
	if tier >= 6 then c.add("cyl", "LightBeam", Vector3.new(14, 0.6, 0.6), CFrame.new(0, c.top + 8, c.bz + 0.5) * CFrame.Angles(0, 0, math.pi / 2), rarity.color, NEON, 0.6) end
	if tier == 7 then halo(c, c.top + 0.6) end
	if tier == 8 then FEATURES.gooDrips(c) end
end

local function recolorSkin(model, fn)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("Skin") then fn(p) end
	end
end

local MUTATION_LOOKS = {
	["Rotten"] = function(model, c) recolorSkin(model, function(p) p.Color = p.Color:Lerp(Color3.fromRGB(110, 200, 60), 0.45) end); FEATURES.gooDrips(c) end,
	["Golden"] = function(model) recolorSkin(model, function(p) p.Color = GOLD; p.Material = Enum.Material.Foil end) end,
	["Rizzed"] = function(model, c) PROPS.sunglasses(c); sparkle(c.body, Color3.fromRGB(255, 110, 200)) end,
	["Galaxy Brain"] = function(model, c)
		recolorSkin(model, function(p) p.Color = p.Color:Lerp(Color3.fromRGB(70, 30, 140), 0.6) end)
		for _, p in ipairs(model:GetChildren()) do if p.Name == "BrainCap" then p.Color = Color3.fromRGB(150, 90, 255); p.Material = NEON end end
		sparkle(c.body, Color3.fromRGB(200, 180, 255))
	end,
	["Brain Freeze"] = function(model) recolorSkin(model, function(p) p.Color = Color3.fromRGB(170, 230, 255); p.Material = Enum.Material.Ice end) end,
	["Sigma"] = function(model, c) recolorSkin(model, function(p) p.Color = Color3.fromRGB(25, 25, 30) end); FEATURES.sharpJaw(c); c.add("cyl", "SigmaChain", Vector3.new(0.2, c.w * 0.9, c.d * 0.9), CFrame.new(0, -c.by * 0.35, -0.2) * CFrame.Angles(0.5, 0, math.pi / 2), GOLD, Enum.Material.Foil) end,
	["Ohio"] = function(model) model:SetAttribute("Jitter", true); recolorSkin(model, function(p) p.Color = Color3.new(1 - p.Color.R, 1 - p.Color.G, 1 - p.Color.B) end) end,
	["Max Aura"] = function(model, c)
		c.add("ball", "MaxAura", Vector3.new(c.w * 2.4, c.h * 2, c.d * 2.4), Vector3.new(0, 0, 0), Color3.fromRGB(255, 160, 255), NEON, 0.82)
		floatText(c.body, "+∞ AURA", GOLD, c.top + 2.4, 2.4)
	end,
}

function BrainrotModelKit.build(entry, mutationName, level)
	local rarity = RarityConfig.list[entry.tier]
	local dims = BODY_TYPES[entry.bodyType] or BODY_TYPES.Blob
	local model = Instance.new("Model")
	model.Name = entry.name
	model:SetAttribute("BrainrotId", entry.id)
	model:SetAttribute("Mutation", mutationName or "")
	model:SetAttribute("Level", level or 1)
	local feetHeight = 0.5
	local origin = CFrame.new(0, dims.Y / 2 + feetHeight, 0)
	local body = Instance.new(entry.bodyType == "Wedge" and "WedgePart" or "Part")
	body.Name = "Body"
	body.Size = dims
	body.CFrame = origin
	body.Color = entry.body
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored, body.CanCollide, body.CanTouch = true, false, false
	body:SetAttribute("Skin", true)
	if entry.bodyType ~= "Block" and entry.bodyType ~= "Wedge" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = body
	end
	body.Parent = model
	model.PrimaryPart = body

	local isRound = entry.bodyType ~= "Block" and entry.bodyType ~= "Wedge"
	local c = {
		body = body, w = dims.X, h = dims.Y, d = dims.Z, bx = dims.X / 2, by = dims.Y / 2, bz = dims.Z / 2,
		bodyColor = entry.body, bellyColor = entry.belly, capLift = 0, top = dims.Y / 2,
		footColor = entry.body,
	}
	c.front = function(xf, yf)
		if not isRound then return -c.bz end
		return -c.bz * math.sqrt(math.max(0.08, 1 - xf * xf - yf * yf))
	end
	c.add = makeAdder(model, body, c)

	for _, feature in ipairs(entry.features) do
		local build = FEATURES[feature]
		if build then build(c) else warn("BrainrotModelKit: no feature " .. feature) end
	end
	if not c.skipBelly and entry.belly ~= entry.body then
		c.add("ball", "Belly", Vector3.new(c.w * 0.62, c.h * 0.5, 0.5), Vector3.new(0, -c.by * 0.35, c.front(0, -0.35) + 0.12), entry.belly)
	end
	buildFace(c)
	if not c.noFeet then
		for _, s in ipairs({ -1, 1 }) do c.add("ball", "Foot", Vector3.new(c.w * 0.3, feetHeight * 1.4, c.d * 0.36), Vector3.new(s * c.w * 0.22, -c.by - feetHeight * 0.3, -c.bz * 0.3), c.footColor) end
	end
	buildBrainCap(c)
	local prop = PROPS[entry.prop]
	if prop then prop(c) else warn("BrainrotModelKit: no prop " .. tostring(entry.prop)) end
	local bboxCf, bboxSize = model:GetBoundingBox()
	applyRarityExtras(model, c, rarity)
	local look = mutationName and MUTATION_LOOKS[mutationName]
	if look then look(model, c) end

	body.PivotOffset = CFrame.new(0, bboxCf.Position.Y - bboxSize.Y / 2 - body.Position.Y, 0)
	model:ScaleTo(rarity.scale)
	model:SetAttribute("TopHeight", bboxSize.Y * rarity.scale)
	return model
end

-- incomePerSecond is already multiplied by mutation and level; the tag only shows it.
function BrainrotModelKit.attachNameTag(model, entry, mutationName, level, incomePerSecond)
	local old = model:FindFirstChild("NameTagAnchor", true)
	if old then old:Destroy() end
	local rarity = RarityConfig.list[entry.tier]
	local anchor = Instance.new("Attachment")
	anchor.Name = "NameTagAnchor"
	anchor.Parent = model.PrimaryPart
	anchor.WorldPosition = model:GetPivot().Position + Vector3.new(0, (model:GetAttribute("TopHeight") or 4) + 2.2 * math.sqrt(rarity.scale) + 1, 0)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.new(9 * math.sqrt(rarity.scale), 0, 3.6 * math.sqrt(rarity.scale), 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 140
	gui.Parent = anchor
	local backing = Instance.new("Frame")
	backing.Size = UDim2.fromScale(1, 1)
	backing.BackgroundColor3 = Color3.fromRGB(15, 5, 20)
	backing.BackgroundTransparency = 0.35
	backing.Parent = gui
	Instance.new("UICorner", backing).CornerRadius = UDim.new(0.15, 0)
	local stroke = Instance.new("UIStroke", backing)
	stroke.Color, stroke.Thickness = rarity.color, 2
	local mutation = mutationName and MutationConfig.byName[mutationName]
	local lines = {
		{ "Rarity", string.upper(rarity.name) .. (mutation and ("  ·  " .. string.upper(mutation.name)) or ""), mutation and mutation.color or rarity.color, 0.0, 0.26 },
		{ "Title", entry.name, Color3.new(1, 1, 1), 0.25, 0.4 },
		{ "Income", NumberFormat.cells(incomePerSecond) .. "/s  ·  Lv " .. (level or 1), Color3.fromRGB(120, 255, 90), 0.66, 0.32 },
	}
	for _, line in ipairs(lines) do
		local label = Instance.new("TextLabel")
		label.Name = line[1]
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0.04, line[4] + 0.02)
		label.Size = UDim2.fromScale(0.92, line[5])
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = line[2]
		label.TextColor3 = line[3]
		label.TextStrokeTransparency = 0.2
		label.Parent = backing
	end
	return gui
end

return BrainrotModelKit
