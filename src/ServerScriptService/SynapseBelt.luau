-- The Synapse Belt: brainrots ride the loop from the Meme Lobe chute, facing into the loop. E buys one,
-- and the buyer carries it home (CarryService). Rarer tiers and mutations are rare rolls.
local RunService = game:GetService("RunService")
local RS = game.ReplicatedStorage
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Catalog = require(RS.BrainrotCatalog)
local Kit = require(RS.BrainrotModelKit)
local MutationConfig = require(RS.MutationConfig)
local NumberFormat = require(RS.NumberFormat)

local SynapseBelt = {}
local TIER_WEIGHTS = { 46, 26, 14, 7.5, 3.8, 1.8, 0.7, 0.2 }
local LOOP_CENTER = Vector3.new(0, 0, -25)
local rng = Random.new()
local items = {}
local folder
local path = WorldBuilder.BELT_PATH
local lengths, total = {}, 0
for i = 1, #path - 1 do
	lengths[i] = (path[i + 1] - path[i]).Magnitude
	total += lengths[i]
end

SynapseBelt.speed = 7
SynapseBelt.spawnEvery = 2.2
SynapseBelt.mutationChance = 0.18
SynapseBelt.paused = false
SynapseBelt.onBuy = nil -- set by CarryService: function(player, item, model) -> true if carried

local function pointAt(distance)
	for i, len in ipairs(lengths) do
		if distance <= len then return path[i]:Lerp(path[i + 1], distance / len) end
		distance -= len
	end
	return path[#path]
end

function SynapseBelt.rollTier(luck)
	local weights, sum = {}, 0
	for tier, w in ipairs(TIER_WEIGHTS) do
		weights[tier] = w * (tier > 2 and (luck or 1) or 1)
		sum += weights[tier]
	end
	local pick = rng:NextNumber(0, sum)
	for tier, w in ipairs(weights) do
		pick -= w
		if pick <= 0 then return tier end
	end
	return 1
end

local function remove(belt)
	local index = table.find(items, belt)
	if index then table.remove(items, index) end
	if belt.model then belt.model:Destroy() end
end

function SynapseBelt.spawn(id, mut)
	if not id then
		local pool = Catalog.ofTier(SynapseBelt.rollTier(SynapseBelt.luck))
		id = pool[rng:NextInteger(1, #pool)].id
		mut = rng:NextNumber() < SynapseBelt.mutationChance and MutationConfig.roll(rng) or nil
	end
	local entry = Catalog.list[id]
	local price = entry.price * MutationConfig.multiplierOf(mut)
	local model = Kit.build(entry, mut, 1)
	local belt = { id = id, mut = mut, price = price, distance = 0, model = model }
	local income = entry.income * MutationConfig.multiplierOf(mut)
	model:PivotTo(CFrame.new(pointAt(0)))
	local tag = Kit.attachNameTag(model, entry, mut, 1, income)
	tag:FindFirstChild("Income", true).Text = "BUY " .. NumberFormat.cells(price) .. "  ·  +" .. NumberFormat.short(income) .. "/s"
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy " .. NumberFormat.cells(price)
	prompt.ObjectText = entry.name
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if not table.find(items, belt) then return end
		local d = PlayerData.get(player)
		if not d then return end
		if d.cells < price then
			PlayerData.alert(player, "NOT ENOUGH BRAIN CELLS (" .. NumberFormat.cells(price) .. ")", nil, 1.8)
			return
		end
		if SynapseBelt.onBuy and SynapseBelt.onBuy(player, { id = id, mut = mut }, model) then
			d.cells -= price
			belt.model = nil
			remove(belt)
			if entry.tier >= 5 or mut then
				PlayerData.feed("🛒 " .. player.DisplayName .. " bought " .. (mut and (mut .. " ") or "") .. entry.name .. "!", entry.tier >= 5 and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(200, 255, 200))
			end
			PlayerData.push(player)
		end
	end)
	model.Parent = folder
	table.insert(items, belt)
	return belt
end

function SynapseBelt.init()
	folder = Instance.new("Folder")
	folder.Name = "BeltBrainrots"
	folder.Parent = workspace
	local sinceSpawn = SynapseBelt.spawnEvery
	for d = 0, total, SynapseBelt.speed * SynapseBelt.spawnEvery * 1.6 do
		local belt = SynapseBelt.spawn()
		belt.distance = d
	end
	RunService.Heartbeat:Connect(function(dt)
		if SynapseBelt.paused then return end
		sinceSpawn += dt
		if sinceSpawn >= SynapseBelt.spawnEvery then
			sinceSpawn = 0
			SynapseBelt.spawn()
		end
		local parts, cframes = {}, {}
		for i = #items, 1, -1 do
			local belt = items[i]
			belt.distance += SynapseBelt.speed * dt
			if belt.distance >= total then
				remove(belt)
			else
				local pos = pointAt(belt.distance)
				local cf = CFrame.lookAt(pos, Vector3.new(LOOP_CENTER.X, pos.Y, LOOP_CENTER.Z)) * belt.model.PrimaryPart.PivotOffset:Inverse()
				table.insert(parts, belt.model.PrimaryPart)
				table.insert(cframes, cf)
			end
		end
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

return SynapseBelt
