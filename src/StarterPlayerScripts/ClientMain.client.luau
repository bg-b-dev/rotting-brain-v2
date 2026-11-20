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

-- Title banner
local title = panel(root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0.56, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(255, 70, 170), BackgroundTransparency = 0.1 })
stroke(title, Color3.fromRGB(255, 230, 80), 3)
label(title, { Size = UDim2.new(1, -16, 1, -6), Position = UDim2.fromOffset(8, 3), Text = "🧠 ROTTING BRAIN 🧠 · 60 BRAINROTS · 8 MUTATIONS · STEAL · DEFENSE · REBIRTH" })

-- Event banner (server sets workspace attributes Event, EventColor, EventEnd)
local eventBanner = panel(root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 46), Size = UDim2.new(0.42, 0, 0, 46), Visible = false, BackgroundTransparency = 0.05 })
stroke(eventBanner, WHITE, 3)
local eventText = label(eventBanner, { Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4) })

-- Stats panel
local stats = panel(root, { Position = UDim2.new(0, 10, 0, 60), Size = UDim2.new(0.2, 0, 0, 118) })
stroke(stats, Color3.fromRGB(255, 70, 170), 2)
local cellsText = label(stats, { Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 44), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 160, 220), Text = "🧠0" })
local incomeText = label(stats, { Position = UDim2.new(0, 10, 0, 50), Size = UDim2.new(1, -20, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(120, 255, 120), Text = "+0/s" })
local levelText = label(stats, { Position = UDim2.new(0, 10, 0, 80), Size = UDim2.new(1, -20, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 220, 60), Text = "LOBE LV 1" })

-- Rot meter
local rotPanel = panel(root, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 60), Size = UDim2.new(0.22, 0, 0, 74) })
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
Remotes.Alert.OnClientEvent:Connect(function(text, color, seconds)
	alertToken += 1
	local token = alertToken
	alert.Text, alert.TextColor3, alert.Visible = text, color or Color3.fromRGB(255, 60, 60), true
	alertScale.Scale = 1.4
	TweenService:Create(alertScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(seconds or 2.5, function()
		if token == alertToken and not workspace:GetAttribute("HoldBanners") then alert.Visible = false end
	end)
end)

-- Feed
local feed = panel(root, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -110), Size = UDim2.new(0.26, 0, 0, 150), BackgroundTransparency = 0.35 })
new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, feed)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6), PaddingTop = UDim.new(0, 6) }, feed)
local feedOrder = 0
Remotes.Feed.OnClientEvent:Connect(function(text, color)
	feedOrder += 1
	label(feed, { Size = UDim2.new(1, 0, 0, 22), Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = feedOrder })
	local lines = {}
	for _, child in ipairs(feed:GetChildren()) do if child:IsA("TextLabel") then table.insert(lines, child) end end
	table.sort(lines, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	for i = 1, #lines - 6 do lines[i]:Destroy() end
end)

-- Brainpedia
local pedia = panel(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.9, 0.7), Visible = false, BackgroundTransparency = 0.08, ZIndex = 5 })
stroke(pedia, Color3.fromRGB(255, 220, 60), 3)
local pediaTitle = label(pedia, { Position = UDim2.new(0, 0, 0, 6), Size = UDim2.new(1, 0, 0.09, 0), Text = "📖 BRAINPEDIA · FOUND 0/60", TextColor3 = Color3.fromRGB(255, 220, 60), ZIndex = 6 })
local grid = new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.11, 0), Size = UDim2.new(1, -20, 0.88, -6), ZIndex = 6 }, pedia)
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
	local vp = modelView(tile, entry, nil, { Size = UDim2.fromScale(1, 0.72), ZIndex = 7 })
	local name = label(tile, { Position = UDim2.fromScale(0.03, 0.72), Size = UDim2.fromScale(0.94, 0.26), ZIndex = 8 })
	local mark = label(tile, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 2), Size = UDim2.fromScale(0.3, 0.22), ZIndex = 8 })
	tiles[entry.id] = { tile = tile, vp = vp, name = name, mark = mark, color = rarity.color, entry = entry }
end

local foundSet, foundCount = {}, 0
local function refreshPedia()
	if not next(tiles) then for _, entry in ipairs(Catalog.list) do buildTile(entry) end end
	for id, t in pairs(tiles) do
		local owned = foundSet[id]
		t.tile.BackgroundColor3 = owned and t.color or Color3.fromRGB(60, 60, 66)
		t.vp.ImageColor3 = owned and WHITE or Color3.fromRGB(25, 25, 30)
		t.name.Text = owned and t.entry.name or "🔒 NOT FOUND"
		t.name.TextColor3 = owned and WHITE or Color3.fromRGB(170, 170, 175)
		t.mark.Text = owned and "✅" or ""
	end
	pediaTitle.Text = ("📖 BRAINPEDIA · FOUND %d/60"):format(foundCount)
end

-- Catch card: the first time a brainrot lands in the Lobe (server sends snapshot.caught).
local card = panel(root, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 10), Size = UDim2.new(0.2, 0, 0.42, 0), Visible = false, BackgroundTransparency = 0.05, ZIndex = 3 })
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
local state = { cells = 0, income = 0, rot = 0, lobeLevel = 1, rebirths = 0, upgradeCost = 150, brainWashCost = 250000 }
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
actionButton(1, "E", "Buy/Steal", Color3.fromRGB(40, 170, 90))
actionButton(2, "F", "Focus Slap", Color3.fromRGB(230, 120, 30), function() send("slap") end)
actionButton(3, "L", "Mind Block", Color3.fromRGB(230, 60, 160), function() send("mindBlock") end)
actionButton(4, "U", "Upgrade", Color3.fromRGB(220, 180, 30), function() send("upgrade") end)
actionButton(5, "R", "Brain Wash", Color3.fromRGB(40, 150, 230), function() send("brainWash") end)
actionButton(6, "B", "Brainpedia", Color3.fromRGB(140, 70, 230), togglePedia)
buttons.E.status.Text = "HOLD NEAR"

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

	local event = workspace:GetAttribute("Event")
	eventBanner.Visible = event ~= nil and event ~= ""
	if eventBanner.Visible then
		local left = math.max(0, (workspace:GetAttribute("EventEnd") or 0) - workspace:GetServerTimeNow())
		eventText.Text = event .. ("  ·  %ds"):format(math.ceil(left))
		eventColor = workspace:GetAttribute("EventColor") or eventColor
		eventBanner.BackgroundColor3 = eventColor
	end
end)

-- Hide the Steal prompt on the local player's own brainrots.
local prompts = {}
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
