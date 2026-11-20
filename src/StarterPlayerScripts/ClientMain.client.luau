-- The HUD: title, cells, rot meter, banners, feed, action bar and the Brainpedia. Keys send Action names.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local Remotes = require(RS:WaitForChild("Remotes"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local Catalog = require(RS:WaitForChild("BrainrotCatalog"))
local RarityConfig = require(RS:WaitForChild("RarityConfig"))
local Kit = require(RS:WaitForChild("BrainrotModelKit"))
local MutationConfig = require(RS:WaitForChild("MutationConfig"))

local player = Players.LocalPlayer
local FONT = Enum.Font.FredokaOne
local WHITE = Color3.new(1, 1, 1)

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui

-- Lesson 17: Studio captures are about 4:3, so this lays the HUD in a centered 16:9 band for cropping.
if RunService:IsStudio() then
	local band = Instance.new("UIAspectRatioConstraint")
	band.AspectRatio = 16 / 9
	local function apply() band.Parent = workspace:GetAttribute("HudBand16x9") and root or nil end
	workspace:GetAttributeChangedSignal("HudBand16x9"):Connect(apply)
	apply()
end

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function corner(parent, r) new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, parent) end
local function stroke(parent, color, t) new("UIStroke", { Color = color or Color3.new(0, 0, 0), Thickness = t or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent) end

local function label(parent, props)
	local l = new("TextLabel", { BackgroundTransparency = 1, Font = FONT, TextColor3 = WHITE, TextScaled = true, TextStrokeTransparency = 0.2 }, parent)
	for k, v in pairs(props) do l[k] = v end
	return l
end

local function panel(parent, props)
	local f = new("Frame", { BackgroundColor3 = Color3.fromRGB(20, 8, 30), BackgroundTransparency = 0.25, BorderSizePixel = 0 }, parent)
	for k, v in pairs(props) do f[k] = v end
	corner(f, 12)
	return f
end

-- Title card and feature chips. Starts at x 140 to clear Roblox's top-left menu.
local title = panel(root, { Position = UDim2.new(0, 140, 0, 4), Size = UDim2.new(0.17, 0, 0, 52), BackgroundColor3 = Color3.fromRGB(255, 70, 170), BackgroundTransparency = 0.05 })
stroke(title, Color3.fromRGB(255, 230, 80), 3)
label(title, { Size = UDim2.new(1, -12, 1, -8), Position = UDim2.fromOffset(6, 4), Text = "🧠 ROTTING BRAIN 🧠", TextColor3 = Color3.fromRGB(255, 240, 90) })

local CHIP_ROWS = {
	{
		{ "60 BRAINROTS × 8 MUTATIONS = 480 VARIANTS", Color3.fromRGB(255, 70, 170) }, { "8 RARITIES", Color3.fromRGB(255, 140, 30) },
		{ "8 MUTATIONS", Color3.fromRGB(150, 70, 230) }, { "STEAL", Color3.fromRGB(230, 40, 50) }, { "MIND BLOCK", Color3.fromRGB(240, 90, 130) },
	},
	{
		{ "BRAIN WASH", Color3.fromRGB(210, 40, 200) }, { "QUESTS", Color3.fromRGB(20, 170, 160) }, { "5 EVENTS", Color3.fromRGB(40, 110, 240) },
		{ "MEME BLENDER", Color3.fromRGB(130, 80, 240) }, { "BUBBLES", Color3.fromRGB(20, 180, 230) }, { "PIXIE RAID", Color3.fromRGB(230, 190, 20) },
		{ "MOST ROTTED", Color3.fromRGB(215, 160, 20) }, { "FULLY ROTTED x3", Color3.fromRGB(90, 200, 30) },
	},
}
local chips = new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.17, 148, 0, 4), Size = UDim2.new(0.83, -158, 0, 52) }, root)
for r, row in ipairs(CHIP_ROWS) do
	local units = 0
	for _, chip in ipairs(row) do units += #chip[1] + 3 end
	local line = new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, (r - 1) * 0.5, 0), Size = UDim2.new(1, 0, 0.5, -2) }, chips)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, line)
	for i, chip in ipairs(row) do
		local f = panel(line, { LayoutOrder = i, Size = UDim2.new((#chip[1] + 3) / units, -4, 1, 0), BackgroundColor3 = chip[2], BackgroundTransparency = 0 })
		stroke(f, Color3.fromRGB(30, 10, 40), 1.5)
		label(f, { Size = UDim2.new(1, -8, 1, -6), Position = UDim2.fromOffset(4, 3), Text = chip[1], TextStrokeTransparency = 0.1 })
	end
end

-- Event line: the next event and its countdown when idle, the live event when running.
-- The server sets workspace attributes Event, EventColor, EventEnd, NextEvent and NextEventAt.
local eventBanner = panel(root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 62), Size = UDim2.new(0.42, 0, 0, 42), BackgroundTransparency = 0.05 })
stroke(eventBanner, WHITE, 3)
local eventText = label(eventBanner, { Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4) })

-- Stats panel
local stats = panel(root, { Position = UDim2.new(0, 10, 0, 62), Size = UDim2.new(0.24, 0, 0, 118), BackgroundTransparency = 0.1 })
stroke(stats, Color3.fromRGB(255, 70, 170), 2)
local cellsText = label(stats, { Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 44), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 160, 220), Text = "🧠0" })
local incomeText = label(stats, { Position = UDim2.new(0, 10, 0, 50), Size = UDim2.new(1, -20, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(120, 255, 120), Text = "+0/s" })
local levelText = label(stats, { Position = UDim2.new(0, 10, 0, 80), Size = UDim2.new(1, -20, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 220, 60), Text = "LOBE LV 1" })

-- Rot meter
local rotPanel = panel(root, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 62), Size = UDim2.new(0.2, 0, 0, 74), BackgroundTransparency = 0.1 })
stroke(rotPanel, Color3.fromRGB(120, 255, 40), 2)
local rotTitle = label(rotPanel, { Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 0, 28), Text = "🦠 BRAIN ROT 0%", TextColor3 = Color3.fromRGB(170, 255, 90) })
local rotBack = new("Frame", { Position = UDim2.new(0, 10, 0, 38), Size = UDim2.new(1, -20, 0, 26), BackgroundColor3 = Color3.fromRGB(40, 20, 40), BorderSizePixel = 0 }, rotPanel)
corner(rotBack, 8)
local rotFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(120, 255, 40), BorderSizePixel = 0 }, rotBack)
corner(rotFill, 8)
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(120, 255, 40), Color3.fromRGB(255, 70, 170)) }, rotFill)

-- Alert banner
local alert = label(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.62, 0.11), Visible = false, TextStrokeTransparency = 0 })
new("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, alert)
local alertScale = new("UIScale", {}, alert)
local alertToken = 0
local function showAlert(text, color, seconds)
	alertToken += 1
	local token = alertToken
	alert.Text, alert.TextColor3, alert.Visible = text, color or Color3.fromRGB(255, 60, 60), true
	alertScale.Scale = 1.4
	TweenService:Create(alertScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(seconds or 2.5, function()
		if token == alertToken and not workspace:GetAttribute("HoldBanners") then alert.Visible = false end
	end)
end
Remotes.Alert.OnClientEvent:Connect(showAlert)

-- Feed
-- Quests (server sends snapshot.quests = { {text, n, goal, reward} })
local quests = panel(root, { Position = UDim2.new(0, 10, 0, 188), Size = UDim2.new(0.24, 0, 0, 128), BackgroundTransparency = 0.1 })
stroke(quests, Color3.fromRGB(255, 220, 60), 2)
label(quests, { Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 0, 26), Text = "📜 QUESTS", TextColor3 = Color3.fromRGB(255, 220, 60), TextXAlignment = Enum.TextXAlignment.Left })
local questLines = {}
for i = 1, 3 do
	questLines[i] = label(quests, { Position = UDim2.new(0, 10, 0, 4 + i * 30), Size = UDim2.new(1, -20, 0, 26), Text = "", TextXAlignment = Enum.TextXAlignment.Left })
end
local function renderQuests(list)
	for i, line in ipairs(questLines) do
		local q = list[i]
		if q then
			local done = q.n >= q.goal
			line.Text = (done and "✅ " or "• ") .. q.text .. ("  %d/%d"):format(q.n, q.goal) .. (done and "" or ("  +🧠" .. NumberFormat.short(q.reward)))
			line.TextColor3 = done and Color3.fromRGB(120, 255, 120) or WHITE
		end
	end
end

-- Feed: 4 lines on the left under the quests, each on its own backing.
local feed = new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 324), Size = UDim2.new(0.3, 0, 0, 124) }, root)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, feed)
local feedOrder = 0
Remotes.Feed.OnClientEvent:Connect(function(text, color)
	feedOrder += 1
	local back = panel(feed, { Size = UDim2.new(1, 0, 0, 27), BackgroundTransparency = 0.15, LayoutOrder = feedOrder })
	label(back, { Position = UDim2.fromOffset(8, 2), Size = UDim2.new(1, -16, 1, -4), Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Left })
	local lines = {}
	for _, child in ipairs(feed:GetChildren()) do if child:IsA("Frame") then table.insert(lines, child) end end
	table.sort(lines, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	for i = 1, #lines - 4 do lines[i]:Destroy() end
end)

-- Brainpedia
local state = { cells = 0, income = 0, rot = 0, lobeLevel = 1, rebirths = 0, upgradeCost = 150, brainWashCost = 250000 }
local pedia = panel(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.9, 0.74), Visible = false, BackgroundTransparency = 0.08, ZIndex = 5 })
stroke(pedia, Color3.fromRGB(255, 220, 60), 3)
local function pediaCard(x, w, color, text)
	local f = panel(pedia, { Position = UDim2.new(x, 0, 0.012, 0), Size = UDim2.new(w, -8, 0.085, 0), BackgroundColor3 = color, BackgroundTransparency = 0, ZIndex = 6 })
	stroke(f, Color3.fromRGB(30, 10, 40), 2)
	return label(f, { Size = UDim2.new(1, -12, 1, -6), Position = UDim2.fromOffset(6, 3), Text = text, ZIndex = 7 })
end
pediaCard(0.01, 0.3, Color3.fromRGB(40, 16, 60), "📖 BRAINPEDIA").TextColor3 = Color3.fromRGB(255, 220, 60)
local pediaFound = pediaCard(0.32, 0.22, Color3.fromRGB(230, 170, 20), "FOUND 0/60")
local pediaLobe = pediaCard(0.55, 0.36, Color3.fromRGB(40, 170, 70), "MY LOBE 0/20")
local pediaClose = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.99, 0, 0.012, 0), Size = UDim2.new(0.07, 0, 0.085, 0), BackgroundColor3 = Color3.fromRGB(220, 40, 50), Font = FONT, Text = "X", TextColor3 = WHITE, TextScaled = true, ZIndex = 7 }, pedia)
corner(pediaClose, 8)
stroke(pediaClose, Color3.fromRGB(30, 10, 40), 2)
local grid = new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.11, 0), Size = UDim2.new(1, -20, 0.77, -4), ZIndex = 6 }, pedia)

local footer = new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.89, 0), Size = UDim2.new(1, -20, 0.1, -4), ZIndex = 6 }, pedia)
local rarityRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.56, 1), ZIndex = 6 }, footer)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, rarityRow)
for i, rarity in ipairs(RarityConfig.list) do
	local f = panel(rarityRow, { LayoutOrder = i, Size = UDim2.new(1 / 8, -4, 0.7, 0), BackgroundColor3 = rarity.color, BackgroundTransparency = 0, ZIndex = 6 })
	stroke(f, Color3.fromRGB(30, 10, 40), 1.5)
	label(f, { Size = UDim2.new(1, -6, 1, -4), Position = UDim2.fromOffset(3, 2), Text = rarity.name:upper(), ZIndex = 7 })
end
local mutParts = {}
for i, m in ipairs(MutationConfig.list) do
	local c = m.color
	mutParts[i] = ('<font color="#%02X%02X%02X">%s x%d</font>'):format(math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255), m.name:upper(), m.multiplier)
end
for line = 1, 2 do
	label(footer, {
		Position = UDim2.new(0.57, 0, (line - 1) * 0.5, 0), Size = UDim2.new(0.43, 0, 0.5, -1), RichText = true, ZIndex = 7, TextXAlignment = Enum.TextXAlignment.Right,
		Text = table.concat({ mutParts[line * 4 - 3], mutParts[line * 4 - 2], mutParts[line * 4 - 1], mutParts[line * 4] }, " · "),
	})
end
new("UIGridLayout", { CellSize = UDim2.new(1 / 12, -5, 1 / 5, -5), CellPadding = UDim2.fromOffset(5, 5), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
local tiles = {}

local function modelView(parent, entry, mut, props)
	local vp = new("ViewportFrame", { BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 200), LightColor = WHITE }, parent)
	for k, v in pairs(props) do vp[k] = v end
	local ok, model = pcall(Kit.build, entry, mut, 1)
	if ok and model then
		model.Parent = vp
		local top = model:GetAttribute("TopHeight") or 4
		local pivot = model:GetPivot()
		local center = pivot.Position + Vector3.new(0, top * 0.5, 0)
		local cam = new("Camera", { FieldOfView = 40 }, vp)
		cam.CFrame = CFrame.lookAt(center + pivot.LookVector * top * 2.2 + Vector3.new(0, top * 0.35, 0), center)
		vp.CurrentCamera = cam
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Beam") then d:Destroy() end
		end
	end
	return vp
end

local function buildTile(entry)
	local rarity = RarityConfig.byName[entry.rarity]
	local tile = new("Frame", { BackgroundColor3 = rarity.color, BorderSizePixel = 0, LayoutOrder = entry.id, ZIndex = 6 }, grid)
	corner(tile, 8)
	local vp = modelView(tile, entry, nil, { Size = UDim2.fromScale(1, 0.64), ZIndex = 7 })
	local name = label(tile, { Position = UDim2.fromScale(0.03, 0.62), Size = UDim2.fromScale(0.94, 0.2), Text = entry.name, ZIndex = 8 })
	local strip = new("Frame", { Position = UDim2.fromScale(0, 0.82), Size = UDim2.fromScale(1, 0.18), BackgroundColor3 = Color3.fromRGB(20, 8, 30), BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 8 }, tile)
	corner(strip, 6)
	label(strip, { Position = UDim2.fromScale(0.04, 0.05), Size = UDim2.fromScale(0.5, 0.9), Text = rarity.name:upper(), TextColor3 = rarity.color, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9 })
	label(strip, { Position = UDim2.fromScale(0.54, 0.05), Size = UDim2.fromScale(0.42, 0.9), Text = "+🧠" .. NumberFormat.short(entry.income) .. "/s", TextColor3 = Color3.fromRGB(120, 255, 120), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 9 })
	local mark = label(tile, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 2), Size = UDim2.fromScale(0.3, 0.22), ZIndex = 8 })
	local badge = panel(tile, { Position = UDim2.fromOffset(2, 2), Size = UDim2.fromScale(0.5, 0.16), BackgroundColor3 = Color3.fromRGB(40, 190, 70), BackgroundTransparency = 0, Visible = false, ZIndex = 8 })
	label(badge, { Size = UDim2.new(1, -4, 1, -2), Position = UDim2.fromOffset(2, 1), Text = "ON LOBE", ZIndex = 9 })
	tiles[entry.id] = { tile = tile, vp = vp, name = name, mark = mark, badge = badge, color = rarity.color, entry = entry }
end

local foundSet, foundCount = {}, 0
local prompts = {}
local function refreshPedia()
	if not next(tiles) then for _, entry in ipairs(Catalog.list) do buildTile(entry) end end
	local onLobe, lobeCount = {}, 0
	for prompt in pairs(prompts) do
		local model = prompt.Parent and prompt:FindFirstAncestorOfClass("Model")
		if model and model:GetAttribute("OwnerId") == player.UserId then
			onLobe[model:GetAttribute("BrainrotId")] = true
			lobeCount += 1
		end
	end
	for id, t in pairs(tiles) do
		t.badge.Visible = onLobe[id] == true
		local owned = foundSet[id]
		t.tile.BackgroundColor3 = owned and t.color or Color3.fromRGB(95, 95, 104)
		t.vp.ImageColor3 = owned and WHITE or Color3.fromRGB(150, 150, 160)
		t.vp.ImageTransparency = owned and 0 or 0.35
		t.name.TextColor3 = owned and WHITE or Color3.fromRGB(200, 200, 208)
		t.mark.Text = owned and "✅" or "🔒"
	end
	pediaFound.Text = ("FOUND %d/60"):format(foundCount)
	pediaLobe.Text = ("MY LOBE %d/20  +🧠%s/s"):format(lobeCount, NumberFormat.short(state.income or 0))
end

-- Catch card: the first time a brainrot lands in the Lobe (server sends snapshot.caught).
local card = panel(root, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.84, -16, 0.5, 10), Size = UDim2.new(0.2, 0, 0.42, 0), Visible = false, BackgroundTransparency = 0.05, ZIndex = 3 })
local cardStroke = new("UIStroke", { Thickness = 4, Color = WHITE }, card)
local cardScale = new("UIScale", {}, card)
local cardToken = 0
local function showCard(caught)
	local entry = Catalog.list[caught.id]
	if not entry then return end
	local rarity = RarityConfig.byName[entry.rarity]
	local mutation = caught.mut and MutationConfig.byName[caught.mut]
	for _, child in ipairs(card:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
	cardStroke.Color = rarity.color
	label(card, { Position = UDim2.fromScale(0.04, 0.02), Size = UDim2.fromScale(0.92, 0.12), Text = "✨ NEW BRAINROT! ✨", TextColor3 = Color3.fromRGB(255, 230, 80), ZIndex = 4 })
	local glow = new("Frame", { Position = UDim2.fromScale(0.06, 0.15), Size = UDim2.fromScale(0.88, 0.45), BackgroundColor3 = rarity.color, BackgroundTransparency = 0.55, ZIndex = 4 }, card)
	corner(glow, 10)
	modelView(glow, entry, caught.mut, { Size = UDim2.fromScale(1, 1), ZIndex = 5 })
	label(card, { Position = UDim2.fromScale(0.04, 0.61), Size = UDim2.fromScale(0.92, 0.1), Text = entry.name, ZIndex = 4 })
	label(card, { Position = UDim2.fromScale(0.04, 0.71), Size = UDim2.fromScale(0.92, 0.08), Text = string.upper(entry.rarity) .. (mutation and (" · " .. string.upper(mutation.name)) or ""), TextColor3 = mutation and mutation.color or rarity.color, ZIndex = 4 })
	label(card, { Position = UDim2.fromScale(0.04, 0.79), Size = UDim2.fromScale(0.92, 0.08), Text = "+" .. NumberFormat.short(caught.income or entry.income) .. "/s", TextColor3 = Color3.fromRGB(120, 255, 120), ZIndex = 4 })
	label(card, { Position = UDim2.fromScale(0.06, 0.88), Size = UDim2.fromScale(0.88, 0.1), Text = "\"" .. entry.caption .. "\"", TextColor3 = Color3.fromRGB(230, 210, 255), TextWrapped = true, TextStrokeTransparency = 0.6, ZIndex = 4 })
	card.Visible = true
	cardScale.Scale = 0.3
	TweenService:Create(cardScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	cardToken += 1
	local token = cardToken
	task.delay(4.5, function()
		if token == cardToken and not workspace:GetAttribute("HoldBanners") then card.Visible = false end
	end)
end

-- Action bar
local timers = { slapCooldown = 0, mindBlock = 0, mindBlockCooldown = 0, fullyRotted = 0 }
local bar = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(0.78, 0, 0, 78) }, root)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, bar)

local buttons = {}
local function actionButton(order, key, text, color, action)
	local b = new("TextButton", { Size = UDim2.new(1 / 6, -7, 1, 0), BackgroundColor3 = color, AutoButtonColor = true, Text = "", LayoutOrder = order }, bar)
	corner(b, 12)
	stroke(b, WHITE, 2)
	local keyBox = new("Frame", { Position = UDim2.fromOffset(6, 6), Size = UDim2.new(0, 28, 0, 28), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3 }, b)
	corner(keyBox, 6)
	label(keyBox, { Size = UDim2.fromScale(1, 1), Text = key })
	label(b, { Position = UDim2.new(0, 38, 0, 6), Size = UDim2.new(1, -44, 0, 28), Text = text, TextXAlignment = Enum.TextXAlignment.Left })
	local status = label(b, { Position = UDim2.new(0, 6, 0, 40), Size = UDim2.new(1, -12, 0, 30), Text = "", TextColor3 = Color3.fromRGB(255, 255, 200) })
	if action then b.Activated:Connect(action) end
	buttons[key] = { button = b, status = status, color = color }
	return b
end

local function send(name) Remotes.Action:FireServer(name) end
local function togglePedia()
	pedia.Visible = not pedia.Visible
	if pedia.Visible then refreshPedia() end
end
pediaClose.Activated:Connect(togglePedia)
actionButton(1, "E", "Buy/Steal", Color3.fromRGB(40, 170, 90))
actionButton(2, "F", "Focus Slap", Color3.fromRGB(230, 120, 30), function() send("slap") end)
actionButton(3, "L", "Mind Block", Color3.fromRGB(230, 60, 160), function() send("mindBlock") end)
actionButton(4, "U", "Upgrade", Color3.fromRGB(220, 180, 30), function() send("upgrade") end)
actionButton(5, "R", "Brain Wash", Color3.fromRGB(40, 150, 230), function() send("brainWash") end)
actionButton(6, "B", "Brainpedia", Color3.fromRGB(140, 70, 230), togglePedia)
buttons.E.status.Text = "HOLD NEAR"

-- Systems menu on the right edge: each button is the bar action or a hint to the place in the plaza.
local menu = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 144), Size = UDim2.new(0.15, 0, 0, 276) }, root)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, menu)
local function hint(text) return function() showAlert(text, Color3.fromRGB(255, 230, 80), 2.5) end end
local menuLabels = {}
for i, m in ipairs({
	{ "🛒 SHOP", Color3.fromRGB(40, 170, 90), hint("🛒 BUY BRAINROTS ON THE SYNAPSE BELT") },
	{ "⬆ UPGRADES", Color3.fromRGB(220, 160, 20), function() send("upgrade") end },
	{ "📖 BRAINPEDIA", Color3.fromRGB(140, 70, 230), togglePedia },
	{ "🌀 BLENDER", Color3.fromRGB(230, 60, 160), hint("🌀 MEME BLENDER: PLAZA, RIGHT SIDE") },
	{ "💭 BUBBLES", Color3.fromRGB(60, 170, 230), hint("💭 THOUGHT BUBBLES: PLAZA, LEFT SIDE") },
	{ "🧼 BRAIN WASH", Color3.fromRGB(40, 120, 220), function() send("brainWash") end },
	{ "🏆 MOST ROTTED", Color3.fromRGB(240, 120, 30), hint("🏆 MOST ROTTED BOARD: PLAZA, BACK") },
}) do
	local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = m[2], AutoButtonColor = true, Text = "", LayoutOrder = i }, menu)
	corner(b, 12)
	stroke(b, WHITE, 2.5)
	menuLabels[i] = label(b, { Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 1, -8), Text = m[1], TextStrokeTransparency = 0 })
	b.Activated:Connect(m[3])
end

local KEYS = { [Enum.KeyCode.F] = "slap", [Enum.KeyCode.L] = "mindBlock", [Enum.KeyCode.U] = "upgrade", [Enum.KeyCode.R] = "brainWash" }
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if KEYS[input.KeyCode] then send(KEYS[input.KeyCode]) end
	if input.KeyCode == Enum.KeyCode.B then togglePedia() end
end)

local function setReady(key, ready, text)
	local b = buttons[key]
	b.status.Text = text
	b.button.BackgroundColor3 = ready and b.color or b.color:Lerp(Color3.fromRGB(40, 40, 45), 0.6)
end

Remotes.State.OnClientEvent:Connect(function(snapshot)
	for k, v in pairs(snapshot) do
		if k == "caught" then continue end
		if timers[k] ~= nil then timers[k] = v else state[k] = v end
	end
	if snapshot.caught then showCard(snapshot.caught) end
	if snapshot.quests then renderQuests(snapshot.quests) end
	if snapshot.found then
		foundSet, foundCount = {}, #snapshot.found
		for _, id in ipairs(snapshot.found) do foundSet[id] = true end
		if pedia.Visible then refreshPedia() end
	end
end)

local eventColor = Color3.fromRGB(255, 70, 170)
RunService.Heartbeat:Connect(function(dt)
	for k, v in pairs(timers) do timers[k] = math.max(0, v - dt) end
	cellsText.Text = NumberFormat.cells(state.cells)
	incomeText.Text = "+" .. NumberFormat.short(state.income) .. "/s" .. (timers.fullyRotted > 0 and "  x3!" or "")
	levelText.Text = "LOBE LV " .. state.lobeLevel .. (state.rebirths > 0 and ("  ·  🧼" .. state.rebirths) or "")
	if timers.fullyRotted > 0 then
		rotTitle.Text = ("☣️ FULLY ROTTED x3 · %ds"):format(math.ceil(timers.fullyRotted))
		rotFill.Size = UDim2.fromScale(1, 1)
	else
		rotTitle.Text = ("🦠 BRAIN ROT %d%%"):format(math.floor(state.rot))
		rotFill.Size = UDim2.fromScale(math.clamp(state.rot / 100, 0, 1), 1)
	end
	setReady("F", timers.slapCooldown <= 0, timers.slapCooldown > 0 and ("%.1fs"):format(timers.slapCooldown) or "READY")
	if timers.mindBlock > 0 then
		setReady("L", true, ("ON %ds"):format(math.ceil(timers.mindBlock)))
	else
		setReady("L", timers.mindBlockCooldown <= 0, timers.mindBlockCooldown > 0 and ("%ds"):format(math.ceil(timers.mindBlockCooldown)) or "READY")
	end
	setReady("U", state.cells >= state.upgradeCost, NumberFormat.cells(state.upgradeCost))
	setReady("R", state.cells >= state.brainWashCost, NumberFormat.cells(state.brainWashCost))
	buttons.B.status.Text = foundCount .. "/60"
	menuLabels[3].Text = "📖 BRAINPEDIA " .. foundCount .. "/60"

	local event = workspace:GetAttribute("Event")
	if event ~= nil and event ~= "" then
		local left = math.max(0, (workspace:GetAttribute("EventEnd") or 0) - workspace:GetServerTimeNow())
		eventText.Text = event .. ("  ·  %ds"):format(math.ceil(left))
		eventColor = workspace:GetAttribute("EventColor") or eventColor
		eventBanner.BackgroundColor3 = eventColor
	else
		local secs = math.ceil(math.max(0, (workspace:GetAttribute("NextEventAt") or 0) - workspace:GetServerTimeNow()))
		eventText.Text = ("NEXT EVENT: %s · %d:%02d"):format(workspace:GetAttribute("NextEvent") or "SOON", secs // 60, secs % 60)
		eventBanner.BackgroundColor3 = Color3.fromRGB(20, 8, 30)
	end
end)

-- Hide the Steal prompt on the local player's own brainrots.
local function track(d)
	if d:IsA("ProximityPrompt") and d.Name == "StealPrompt" then prompts[d] = true end
end
for _, d in ipairs(workspace:GetDescendants()) do track(d) end
workspace.DescendantAdded:Connect(track)
task.spawn(function()
	while true do
		for prompt in pairs(prompts) do
			if not prompt.Parent then
				prompts[prompt] = nil
			else
				local model = prompt:FindFirstAncestorOfClass("Model")
				prompt.Enabled = not (model and model:GetAttribute("OwnerId") == player.UserId)
			end
		end
		task.wait(0.5)
	end
end)

local memeLayer = workspace:WaitForChild("BrainWorld"):WaitForChild("MemeLayer", 10)
if memeLayer then
	local floaters = {}
	for _, part in ipairs(memeLayer:GetChildren()) do
		if part:GetAttribute("Bob") then floaters[part] = part.CFrame end
	end
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for part, base in pairs(floaters) do
			local phase = part:GetAttribute("Bob")
			part.CFrame = base * CFrame.new(0, math.sin(t * 1.2 + phase) * 1.5, 0) * CFrame.Angles(0, math.sin(t * 0.5 + phase) * 0.12, 0)
		end
	end)
end
