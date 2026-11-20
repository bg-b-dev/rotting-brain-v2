-- The 8 Lobes: the owner (a player, or an NPC kid when no player has it), the brainrot in each of the 20 slots,
-- the podium models, income per second, the collect pad and the Brain Rot meter.
local Players = game:GetService("Players")
local RS = game.ReplicatedStorage
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Catalog = require(RS.BrainrotCatalog)
local Kit = require(RS.BrainrotModelKit)
local MutationConfig = require(RS.MutationConfig)
local NumberFormat = require(RS.NumberFormat)

local LobeService = {}
local ASSIGN_ORDER = { 2, 4, 5, 7, 1, 3, 6, 8 }
local NPC_NAMES = { "Scrollo", "Lil Doomscroll", "Tung Tim", "Brainy Bea", "Zoomer Zed", "Skibidi Sam", "Rizzy Rae", "Ohio Owen" }
local SLOT_COUNT = 20
local FULLY_ROTTED_SECONDS = 20
local rng = Random.new()
local lobes = {}
LobeService.lobes = lobes
LobeService.onSteal = nil -- set by CarryService: function(player, lobe, slot)
LobeService.eventMultiplier = 1

local function ownerMultiplier(lobe)
	local d = lobe.owner and PlayerData.get(lobe.owner)
	if not d then return 1 end
	local m = (1 + 0.25 * (d.lobeLevel - 1)) * (1 + 0.5 * d.rebirths)
	if d.fullyRottedUntil > os.clock() then m *= 3 end
	return m * LobeService.eventMultiplier
end

function LobeService.itemIncome(item, lobe)
	return Catalog.list[item.id].income * MutationConfig.multiplierOf(item.mut) * (lobe and ownerMultiplier(lobe) or 1)
end

local function podiumCFrame(index, slot)
	return WorldBuilder.lobeCFrame(index) * WorldBuilder.podiumLocalCFrames()[slot] * CFrame.new(0, 2.9, 0)
end

local function ownerName(lobe)
	return lobe.owner and lobe.owner.DisplayName or lobe.npcName
end

local function render(lobe, slot)
	if lobe.models[slot] then lobe.models[slot]:Destroy() end
	lobe.models[slot] = nil
	local item = lobe.slots[slot]
	if not item or item.stolenBy then return end
	local entry = Catalog.list[item.id]
	local model = Kit.build(entry, item.mut, 1)
	model:PivotTo(podiumCFrame(lobe.index, slot))
	Kit.attachNameTag(model, entry, item.mut, 1, LobeService.itemIncome(item, lobe))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = entry.name
	prompt.HoldDuration = 0.8
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if LobeService.onSteal then LobeService.onSteal(player, lobe, slot) end
	end)
	model:SetAttribute("OwnerId", lobe.owner and lobe.owner.UserId or 0)
	model.Parent = lobe.brainrots
	lobe.models[slot] = model
end

function LobeService.refresh(lobe)
	for slot = 1, SLOT_COUNT do render(lobe, slot) end
	local sign = lobe.model:FindFirstChild("SignText", true)
	if sign then sign.Text = "LOBE " .. lobe.index .. " · " .. string.upper(ownerName(lobe) or "EMPTY") end
	lobe.model:SetAttribute("OwnerId", lobe.owner and lobe.owner.UserId or 0)
end

local function spawnKid(lobe)
	if lobe.kid then lobe.kid:Destroy() end
	local ok, kid = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		local hue = (lobe.index * 0.13) % 1
		desc.HeadColor = Color3.fromRGB(255, 205, 170)
		desc.TorsoColor = Color3.fromHSV(hue, 0.7, 1)
		desc.LeftArmColor, desc.RightArmColor = desc.HeadColor, desc.HeadColor
		desc.LeftLegColor, desc.RightLegColor = Color3.fromHSV(hue, 0.5, 0.5), Color3.fromHSV(hue, 0.5, 0.5)
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok then warn("LobeService: kid " .. tostring(kid)) return end
	kid.Name = lobe.npcName
	kid.Humanoid.DisplayName = "🧒 " .. lobe.npcName
	kid.Humanoid.WalkSpeed = 8
	kid:SetAttribute("NpcKid", lobe.index)
	kid:PivotTo(WorldBuilder.lobeCFrame(lobe.index) * CFrame.new(0, 4, -6))
	kid.Parent = lobe.model
	lobe.kid = kid
end

local function fillWithNpc(lobe)
	lobe.owner = nil
	lobe.npcName = NPC_NAMES[lobe.index]
	table.clear(lobe.slots)
	for slot = 1, rng:NextInteger(6, 9) do
		local tier = math.min(6, 1 + math.floor(rng:NextNumber() ^ 2.2 * 6))
		local pool = Catalog.ofTier(tier)
		lobe.slots[slot] = { id = pool[rng:NextInteger(1, #pool)].id, mut = rng:NextNumber() < 0.3 and MutationConfig.roll(rng) or nil }
	end
	spawnKid(lobe)
	LobeService.refresh(lobe)
end

function LobeService.init()
	local world = WorldBuilder.ensureWorld()
	for _, model in ipairs(world.Lobes:GetChildren()) do
		local index = model:GetAttribute("LobeIndex")
		local old = model:FindFirstChild("Brainrots")
		if old then old:Destroy() end
		local brainrots = Instance.new("Folder")
		brainrots.Name = "Brainrots"
		brainrots.Parent = model
		local lobe = { index = index, model = model, brainrots = brainrots, slots = {}, models = {}, zone = model.HomeZone }
		lobes[index] = lobe
		local padText = model.CollectPad:FindFirstChildWhichIsA("TextLabel", true)
		lobe.padText = padText
		model.CollectPad.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and lobe.owner == player then LobeService.collect(player) end
		end)
	end
	for _, lobe in pairs(lobes) do
		fillWithNpc(lobe)
		task.wait()
	end
end

function LobeService.assign(player)
	local d = PlayerData.get(player)
	for _, index in ipairs(ASSIGN_ORDER) do
		local lobe = lobes[index]
		if not lobe.owner then
			if lobe.kid then lobe.kid:Destroy() lobe.kid = nil end
			table.clear(lobe.slots)
			lobe.owner, lobe.npcName = player, nil
			d.lobe = index
			for _, saved in ipairs(d.slots) do
				if Catalog.list[saved.id] and saved.slot >= 1 and saved.slot <= SLOT_COUNT then
					lobe.slots[saved.slot] = { id = saved.id, mut = saved.mut }
				end
			end
			LobeService.refresh(lobe)
			return lobe
		end
	end
	return nil
end

function LobeService.savedSlots(lobe)
	local list = {}
	for slot, item in pairs(lobe.slots) do table.insert(list, { slot = slot, id = item.id, mut = item.mut }) end
	return list
end

function LobeService.release(player)
	local lobe = LobeService.lobeOf(player)
	if not lobe then return {} end
	local saved = LobeService.savedSlots(lobe)
	fillWithNpc(lobe)
	return saved
end

function LobeService.lobeOf(player)
	local d = PlayerData.get(player)
	return d and lobes[d.lobe]
end

function LobeService.isInside(lobe, position)
	local p = lobe.zone.CFrame:PointToObjectSpace(position)
	local s = lobe.zone.Size / 2
	return math.abs(p.X) <= s.X and math.abs(p.Y) <= s.Y and math.abs(p.Z) <= s.Z
end

-- Puts a brainrot on the first free podium of the player's Lobe. Returns the slot, or nil when the Lobe is full.
function LobeService.add(player, item)
	local lobe = LobeService.lobeOf(player)
	if not lobe then return nil end
	for slot = 1, SLOT_COUNT do
		if not lobe.slots[slot] then
			lobe.slots[slot] = { id = item.id, mut = item.mut }
			PlayerData.get(player).found[item.id] = true
			render(lobe, slot)
			return slot
		end
	end
	return nil
end

function LobeService.beginSteal(lobe, slot, thief)
	local item = lobe.slots[slot]
	if not item or item.stolenBy then return nil end
	item.stolenBy = thief
	render(lobe, slot)
	return { id = item.id, mut = item.mut }
end

function LobeService.finishSteal(lobe, slot)
	lobe.slots[slot] = nil
	render(lobe, slot)
	if not lobe.owner and not next(lobe.slots) then task.delay(20, function() if not lobe.owner and not next(lobe.slots) then fillWithNpc(lobe) end end) end
end

function LobeService.cancelSteal(lobe, slot)
	local item = lobe.slots[slot]
	if item then item.stolenBy = nil end
	render(lobe, slot)
end

function LobeService.clear(player)
	local lobe = LobeService.lobeOf(player)
	if not lobe then return end
	table.clear(lobe.slots)
	LobeService.refresh(lobe)
end

function LobeService.collect(player)
	local d = PlayerData.get(player)
	if not d or d.stored < 1 then return end
	d.cells += d.stored
	d.stored = 0
	PlayerData.push(player, { collected = true })
end

-- Runs once per second: income into the pad, the Brain Rot meter, and Fully Rotted x3.
function LobeService.tick()
	local now = os.clock()
	for _, lobe in pairs(lobes) do
		local player = lobe.owner
		local d = player and PlayerData.get(player)
		if d then
			local income, count = 0, 0
			for _, item in pairs(lobe.slots) do
				if not item.stolenBy then
					income += LobeService.itemIncome(item, lobe)
					count += 1
				end
			end
			d.income = income
			d.stored += income
			local wasRotted = d.fullyRottedUntil > now
			if not wasRotted then
				d.rot = math.min(100, d.rot + 0.5 + count * 0.08)
				if d.rot >= 100 then
					d.rot = 0
					d.fullyRottedUntil = now + FULLY_ROTTED_SECONDS
					PlayerData.alert(player, "🧠 FULLY ROTTED! INCOME x3 🧠", Color3.fromRGB(120, 255, 40), 3)
					PlayerData.feed("🤪 " .. player.DisplayName .. " is FULLY ROTTED (x3 income)!", Color3.fromRGB(120, 255, 40))
					LobeService.refresh(lobe)
				end
			elseif d.fullyRottedUntil - now < 1 then
				task.delay(1, LobeService.refresh, lobe)
			end
			if lobe.padText then lobe.padText.Text = "COLLECT " .. NumberFormat.cells(d.stored) end
			PlayerData.push(player)
		end
	end
end

-- Studio-only capture helper: fill a Lobe with chosen brainrots. items = { { id, mut }, ... }
function LobeService.debugFill(lobe, items)
	table.clear(lobe.slots)
	for slot, item in ipairs(items) do lobe.slots[slot] = { id = item[1], mut = item[2] } end
	LobeService.refresh(lobe)
end

return LobeService
