-- Thought Bubbles: buy one at the plaza shop (the old GEAR kiosk), it floats on one of 2 pads in front of
-- your Lobe, counts down, then pops and a random brainrot lands in your Lobe.
local TweenService = game:GetService("TweenService")
local RS = game.ReplicatedStorage
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerData = require(script.Parent.PlayerData)
local LobeService = require(script.Parent.LobeService)
local Catalog = require(RS.BrainrotCatalog)
local MutationConfig = require(RS.MutationConfig)
local RarityConfig = require(RS.RarityConfig)
local NumberFormat = require(RS.NumberFormat)

local ThoughtBubbles = {}
ThoughtBubbles.KINDS = {
	{ name = "Basic", price = 2000, seconds = 30, color = Color3.fromRGB(140, 220, 255), tiers = { 60, 30, 10 }, mutation = 0.15 },
	{ name = "Gold", price = 60000, seconds = 120, color = Color3.fromRGB(255, 205, 50), tiers = { 0, 0, 50, 35, 15 }, mutation = 0.3 },
	{ name = "Galaxy", price = 2000000, seconds = 300, color = Color3.fromRGB(150, 80, 255), tiers = { 0, 0, 0, 0, 50, 35, 15 }, mutation = 0.5 },
}
ThoughtBubbles.speed = 1 -- test hook: >1 makes timers run faster
local PAD_LOCAL = { CFrame.new(-14, 0, -19), CFrame.new(14, 0, -19) }
local rng = Random.new()
local active = {} -- [player] = { [pad] = bubble model }

local function part(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.Anchored, p.CanCollide, p.TopSurface, p.BottomSurface = true, false, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(parent, size, offset, text, color)
	local a = Instance.new("Attachment")
	a.Position = offset
	a.Parent = parent
	local g = Instance.new("BillboardGui")
	g.Size, g.AlwaysOnTop, g.LightInfluence, g.MaxDistance = size, false, 0, 250
	g.Parent = a
	local t = Instance.new("TextLabel")
	t.Size, t.BackgroundTransparency, t.Font, t.TextScaled = UDim2.fromScale(1, 1), 1, Enum.Font.LuckiestGuy, true
	t.TextColor3, t.Text = color, text
	t.Parent = g
	local s = Instance.new("UIStroke")
	s.Thickness, s.Color = 3, Color3.fromRGB(30, 10, 40)
	s.Parent = t
	return t
end

local function bubbleModel(kind, cf, diameter)
	local model = Instance.new("Model")
	model.Name = kind.name .. "ThoughtBubble"
	local ball = part(model, "Bubble", Vector3.one * diameter, cf, kind.color, Enum.Material.Glass, Enum.PartType.Ball)
	ball.Transparency = 0.35
	part(model, "Core", Vector3.one * diameter * 0.45, cf, kind.color, Enum.Material.Neon, Enum.PartType.Ball)
	for i, s in ipairs({ 0.22, 0.14 }) do
		part(model, "Puff" .. i, Vector3.one * diameter * s, cf * CFrame.new(diameter * (0.35 + i * 0.12), -diameter * (0.5 + i * 0.18), 0), kind.color, Enum.Material.Glass, Enum.PartType.Ball).Transparency = 0.3
	end
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = kind.color, diameter * 2, 1
	light.Parent = ball
	model.PrimaryPart = ball
	return model
end

local function buildShop()
	local plaza = workspace:FindFirstChild("BrainWorld") and workspace.BrainWorld:FindFirstChild("BrainStemPlaza")
	local sign = plaza and plaza:FindFirstChild("GearKioskSign")
	local text = sign and sign:FindFirstChildWhichIsA("TextLabel", true)
	if text then text.Text = "💭 BUBBLES" end
	local base = WorldBuilder.PLAZA_CENTER + Vector3.new(-53, 0, -6)
	local model = Instance.new("Model")
	model.Name = "ThoughtBubbleShop"
	for i, kind in ipairs(ThoughtBubbles.KINDS) do
		local pos = base + Vector3.new(0, 0, (i - 2) * 5.5)
		local stand = part(model, kind.name .. "Stand", Vector3.new(3, 3, 3), CFrame.new(pos + Vector3.new(0, 1.5, 0)), Color3.new(1, 1, 1))
		stand.CanCollide = true
		part(model, kind.name .. "Rim", Vector3.new(3.4, 0.4, 3.4), CFrame.new(pos + Vector3.new(0, 3.1, 0)), kind.color, Enum.Material.Neon)
		local sample = bubbleModel(kind, CFrame.new(pos + Vector3.new(0, 5.6, 0)), 3.2)
		sample.Parent = model
		label(stand, UDim2.fromScale(6, 2.2), Vector3.new(0, 7.6, 0), kind.name:upper() .. "\n" .. NumberFormat.cells(kind.price), kind.color)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Buy " .. kind.name .. " Bubble"
		prompt.ObjectText = NumberFormat.cells(kind.price) .. " · pops in " .. (kind.seconds >= 60 and (kind.seconds // 60 .. " min") or (kind.seconds .. " s"))
		prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0.5, 8, false
		prompt.Parent = stand
		prompt.Triggered:Connect(function(player) ThoughtBubbles.buy(player, i) end)
	end
	model.Parent = workspace
end

local function rollTier(kind)
	local total = 0
	for _, w in ipairs(kind.tiers) do total += w end
	local r = rng:NextNumber() * total
	for tier, w in ipairs(kind.tiers) do
		r -= w
		if r <= 0 and w > 0 then return tier end
	end
	return #kind.tiers
end

local function pop(player, kind, bubble, countdown)
	local pool = Catalog.ofTier(rollTier(kind))
	local entry = pool[rng:NextInteger(1, #pool)]
	local item = { id = entry.id, mut = rng:NextNumber() < kind.mutation and MutationConfig.roll(rng) or nil }
	while player.Parent and not LobeService.add(player, item) do
		countdown.Text = "LOBE FULL!"
		task.wait(2)
	end
	local burst = Instance.new("ParticleEmitter")
	burst.Color, burst.LightEmission, burst.Speed = ColorSequence.new(kind.color), 0.6, NumberRange.new(10, 18)
	burst.Size, burst.Lifetime, burst.SpreadAngle = NumberSequence.new(1.2, 0), NumberRange.new(0.6, 1), Vector2.new(180, 180)
	burst.Parent = bubble.PrimaryPart
	burst:Emit(40)
	for _, d in ipairs(bubble:GetDescendants()) do
		if d:IsA("BasePart") then TweenService:Create(d, TweenInfo.new(0.4), { Transparency = 1, Size = d.Size * 1.6 }):Play() end
	end
	task.delay(1.2, function() bubble:Destroy() end)
	if not player.Parent then return end
	local tier = Catalog.list[entry.id].tier
	local name = (item.mut and (string.upper(item.mut) .. " ") or "") .. string.upper(entry.name)
	PlayerData.alert(player, "💭 POP! " .. name .. "!", RarityConfig.list[tier].color, 3)
	PlayerData.feed("💭 " .. player.DisplayName .. "'s " .. kind.name .. " Bubble popped: " .. entry.name .. "!", kind.color)
	PlayerData.push(player)
end

local function run(player, index, pad, cf)
	local kind = ThoughtBubbles.KINDS[index]
	local bubble = bubbleModel(kind, cf * CFrame.new(0, 7, 0), 6)
	part(bubble, "Pad", Vector3.new(0.4, 7, 7), cf * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2), kind.color, Enum.Material.Neon, Enum.PartType.Cylinder)
	local countdown = label(bubble.PrimaryPart, UDim2.fromScale(9, 3), Vector3.new(0, 5.2, 0), "", Color3.new(1, 1, 1))
	bubble.Parent = workspace
	active[player][pad] = bubble
	local left = kind.seconds
	while left > 0 and player.Parent do
		countdown.Text = "💭 " .. kind.name:upper() .. "\n" .. string.format("%d:%02d", left // 60, left % 60)
		task.wait(1 / ThoughtBubbles.speed)
		left -= 1
	end
	pop(player, kind, bubble, countdown)
	if active[player] then active[player][pad] = nil end
end

function ThoughtBubbles.buy(player, index)
	local kind = ThoughtBubbles.KINDS[index]
	local d = PlayerData.get(player)
	local lobe = LobeService.lobeOf(player)
	if not (kind and d and lobe) then return end
	active[player] = active[player] or {}
	local pad = not active[player][1] and 1 or not active[player][2] and 2 or nil
	if not pad then return PlayerData.alert(player, "BOTH BUBBLE PADS ARE BUSY!", kind.color, 1.8) end
	if d.cells < kind.price then return PlayerData.alert(player, "NEED " .. NumberFormat.cells(kind.price), nil, 1.5) end
	d.cells -= kind.price
	PlayerData.alert(player, "💭 " .. kind.name:upper() .. " BUBBLE ON YOUR LOBE!", kind.color, 2)
	PlayerData.push(player)
	task.spawn(run, player, index, pad, WorldBuilder.lobeCFrame(lobe.index) * PAD_LOCAL[pad])
	return pad
end

function ThoughtBubbles.init()
	buildShop()
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		for _, bubble in pairs(active[player] or {}) do bubble:Destroy() end
		active[player] = nil
	end)
end

return ThoughtBubbles
