-- The Meme Blender in the Meme Kitchen: 3 brainrots of one rarity from your Lobe go in, and after 10 s
-- 1 brainrot of the next rarity lands in your Lobe, with a 40 % chance of a mutation.
local TweenService = game:GetService("TweenService")
local RS = game.ReplicatedStorage
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerData = require(script.Parent.PlayerData)
local LobeService = require(script.Parent.LobeService)
local Catalog = require(RS.BrainrotCatalog)
local Kit = require(RS.BrainrotModelKit)
local MutationConfig = require(RS.MutationConfig)
local RarityConfig = require(RS.RarityConfig)

local MemeBlender = {}
local BLEND_SECONDS, MUTATION_CHANCE = 10, 0.4
local MAGENTA = Color3.fromRGB(255, 60, 190)
local rng = Random.new()
local parts = {}
MemeBlender.busy = false

local function part(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function buildModel()
	local c = WorldBuilder.PLAZA_CENTER + Vector3.new(62, 0, 10)
	local model = Instance.new("Model")
	model.Name = "MemeBlender"
	local up = CFrame.Angles(0, 0, math.pi / 2)
	parts.base = part(model, "Base", Vector3.new(10, 16, 16), CFrame.new(c + Vector3.new(0, 5, 0)) * up, Color3.fromRGB(70, 10, 60), nil, Enum.PartType.Cylinder)
	part(model, "BaseRing", Vector3.new(1, 16.6, 16.6), CFrame.new(c + Vector3.new(0, 9.6, 0)) * up, MAGENTA, Enum.Material.Neon, Enum.PartType.Cylinder)
	local jar = part(model, "Jar", Vector3.new(18, 13, 13), CFrame.new(c + Vector3.new(0, 19, 0)) * up, Color3.fromRGB(200, 240, 255), Enum.Material.Glass, Enum.PartType.Cylinder)
	jar.Transparency, jar.CanCollide = 0.6, false
	part(model, "Lid", Vector3.new(2, 14, 14), CFrame.new(c + Vector3.new(0, 29, 0)) * up, MAGENTA, Enum.Material.Neon, Enum.PartType.Cylinder)
	parts.blade = Instance.new("Model")
	parts.blade.Name = "Blade"
	parts.blade.PrimaryPart = part(parts.blade, "BladeA", Vector3.new(11, 0.4, 1.6), CFrame.new(c + Vector3.new(0, 11.5, 0)), Color3.fromRGB(230, 230, 240), Enum.Material.Metal)
	part(parts.blade, "BladeB", Vector3.new(1.6, 0.4, 11), CFrame.new(c + Vector3.new(0, 11.5, 0)), Color3.fromRGB(230, 230, 240), Enum.Material.Metal)
	parts.blade.Parent = model
	parts.center = c + Vector3.new(0, 16, 0)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = MAGENTA, 22, 1.5
	light.Parent = jar

	local screen = part(model, "Screen", Vector3.new(14, 7, 0.6), CFrame.new(c + Vector3.new(-9, 8, 0)) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(25, 0, 35))
	local sg = Instance.new("SurfaceGui")
	sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, 0
	sg.Parent = screen
	local title = Instance.new("TextLabel")
	title.Size, title.BackgroundTransparency, title.Font, title.TextScaled = UDim2.fromScale(1, 0.55), 1, Enum.Font.FredokaOne, true
	title.TextColor3, title.TextStrokeTransparency, title.Text = MAGENTA, 0, "🌀 MEME BLENDER 🌀\n3 SAME RARITY → 1 HIGHER"
	title.Parent = sg
	local back = Instance.new("Frame")
	back.Position, back.Size, back.BackgroundColor3, back.BorderSizePixel = UDim2.fromScale(0.06, 0.66), UDim2.fromScale(0.88, 0.24), Color3.fromRGB(50, 20, 50), 0
	back.Parent = sg
	parts.bar = Instance.new("Frame")
	parts.bar.Size, parts.bar.BackgroundColor3, parts.bar.BorderSizePixel = UDim2.fromScale(0, 1), Color3.fromRGB(120, 255, 40), 0
	parts.bar.Parent = back

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.ObjectText = "Blend 3", "Meme Blender"
	prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 1, 14, false
	prompt.Parent = parts.base
	prompt.Triggered:Connect(function(player) MemeBlender.blend(player) end)
	model.Parent = workspace
end

-- The lowest rarity (below the top one) with 3 free brainrots in the Lobe: returns the tier and 3 slots.
local function pickTriple(lobe)
	local byTier = {}
	for slot, item in pairs(lobe.slots) do
		if not item.stolenBy then
			local tier = Catalog.list[item.id].tier
			byTier[tier] = byTier[tier] or {}
			table.insert(byTier[tier], slot)
		end
	end
	for tier = 1, #RarityConfig.list - 1 do
		local slots = byTier[tier]
		if slots and #slots >= 3 then return tier, { slots[1], slots[2], slots[3] } end
	end
	return nil
end

function MemeBlender.blend(player)
	local lobe = LobeService.lobeOf(player)
	if not lobe then return end
	if MemeBlender.busy then
		PlayerData.alert(player, "🌀 BLENDER IS BUSY!", MAGENTA, 1.5)
		return
	end
	local tier, slots = pickTriple(lobe)
	if not tier then
		PlayerData.alert(player, "NEED 3 BRAINROTS OF ONE RARITY", MAGENTA, 2)
		return
	end
	MemeBlender.busy = true
	local inJar = {}
	for i, slot in ipairs(slots) do
		local item = lobe.slots[slot]
		local model = Kit.build(Catalog.list[item.id], item.mut, 1)
		model:ScaleTo(model:GetScale() * 0.55)
		model:PivotTo(CFrame.new(parts.center + Vector3.new(math.cos(i * 2.1) * 2.5, (i - 2) * 2, math.sin(i * 2.1) * 2.5)))
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored, d.CanCollide = true, false end
		end
		model.Parent = workspace
		inJar[i] = model
		LobeService.finishSteal(lobe, slot)
	end
	local rarityName = RarityConfig.list[tier].name
	PlayerData.alert(player, "🌀 BLENDING 3 " .. string.upper(rarityName) .. "...", MAGENTA, 2)
	PlayerData.push(player)

	parts.bar.Size = UDim2.fromScale(0, 1)
	TweenService:Create(parts.bar, TweenInfo.new(BLEND_SECONDS, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) }):Play()
	local start = os.clock()
	while os.clock() - start < BLEND_SECONDS do
		local t = os.clock() - start
		parts.blade:PivotTo(parts.blade:GetPivot() * CFrame.Angles(0, 0.9, 0))
		for i, model in ipairs(inJar) do
			local a = t * 6 + i * 2.1
			model:PivotTo(CFrame.new(parts.center + Vector3.new(math.cos(a) * 2.5, math.sin(t * 4 + i) * 2, math.sin(a) * 2.5)) * CFrame.Angles(t * 3, a, 0))
		end
		task.wait(0.05)
	end
	for _, model in ipairs(inJar) do model:Destroy() end

	local pool = Catalog.ofTier(tier + 1)
	local entry = pool[rng:NextInteger(1, #pool)]
	local item = { id = entry.id, mut = rng:NextNumber() < MUTATION_CHANCE and MutationConfig.roll(rng) or nil }
	parts.bar.Size = UDim2.fromScale(0, 1)
	MemeBlender.busy = false
	if not player.Parent or not LobeService.add(player, item) then return end
	local label = (item.mut and (string.upper(item.mut) .. " ") or "") .. string.upper(entry.name)
	PlayerData.alert(player, "🌀 BLENDED: " .. label .. "!", RarityConfig.list[tier + 1].color, 3)
	PlayerData.feed("🌀 " .. player.DisplayName .. " blended 3 " .. rarityName .. " into " .. entry.name .. "!", MAGENTA)
	PlayerData.push(player)
end

function MemeBlender.init()
	buildModel()
end

return MemeBlender
