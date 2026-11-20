-- Carrying a brainrot over your head: bought off the belt or stolen from a rival Lobe. Walk into your own Lobe
-- to place it. Focus Slap (F) knocks a thief and sends the stolen brainrot home; Mind Block (L) shuts your Lobe.
local Players = game:GetService("Players")
local RS = game.ReplicatedStorage
local PlayerData = require(script.Parent.PlayerData)
local LobeService = require(script.Parent.LobeService)
local SynapseBelt = require(script.Parent.SynapseBelt)
local Catalog = require(RS.BrainrotCatalog)
local Kit = require(RS.BrainrotModelKit)

local CarryService = {}
local carrying = {} -- [player] = { item, model, from = { lobe, slot }? }
CarryService.carrying = carrying
local MIND_BLOCK_SECONDS, MIND_BLOCK_COOLDOWN = 10, 35
local SLAP_RANGE, SLAP_COOLDOWN = 10, 3
local RED = Color3.fromRGB(255, 50, 50)

local function rootOf(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
end

local function popup(part, text, color)
	local anchor = Instance.new("Attachment")
	anchor.Position = Vector3.new(0, 5, 0)
	anchor.Parent = part
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(10, 0, 3, 0)
	gui.LightInfluence = 0
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Parent = gui
	task.delay(1.6, function() anchor:Destroy() end)
end

local function attach(player, item, model, from)
	local root, humanoid = rootOf(player)
	if not root or carrying[player] then return false end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ProximityPrompt") then d:Destroy() end
		if d:IsA("BasePart") then d.Massless = true; d.CanCollide = false end
	end
	local body = model.PrimaryPart
	body.Anchored = false
	model:PivotTo(root.CFrame * CFrame.new(0, 3, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = root, body
	weld.Parent = body
	model.Parent = player.Character
	carrying[player] = { item = item, model = model, from = from }
	if from then humanoid.WalkSpeed = 13 end
	return true
end

local function release(player)
	local c = carrying[player]
	carrying[player] = nil
	if c and c.model then c.model:Destroy() end
	local _, humanoid = rootOf(player)
	if humanoid then humanoid.WalkSpeed = 16 end
	return c
end

-- Drops what the player carries: a stolen brainrot goes back to its podium; a bought one goes home if it fits.
function CarryService.drop(player)
	local c = release(player)
	if not c then return end
	if c.from then
		LobeService.cancelSteal(c.from.lobe, c.from.slot)
	else
		LobeService.add(player, c.item)
	end
end

local function place(player, c)
	local slot = LobeService.add(player, c.item)
	if not slot then
		PlayerData.alert(player, "LOBE FULL! BRAIN WASH OR SELL", RED, 2)
		return
	end
	release(player)
	local entry = Catalog.list[c.item.id]
	if c.from then
		local victim = c.from.lobe.owner
		local victimName = victim and victim.DisplayName or c.from.lobe.npcName
		LobeService.finishSteal(c.from.lobe, c.from.slot)
		PlayerData.alert(player, "✅ STOLE " .. string.upper(entry.name) .. "!", Color3.fromRGB(120, 255, 90), 2.5)
		PlayerData.feed("🦹 " .. player.DisplayName .. " stole " .. entry.name .. " from " .. victimName .. "!", Color3.fromRGB(255, 120, 120))
		if victim then PlayerData.alert(victim, "😭 " .. player.DisplayName .. " STOLE YOUR " .. string.upper(entry.name), RED, 3) end
	else
		PlayerData.alert(player, "PLACED " .. string.upper(entry.name), Color3.fromRGB(120, 255, 90), 1.5)
	end
	PlayerData.push(player)
end

local function onSteal(thief, lobe, slot)
	if lobe.owner == thief or carrying[thief] then return end
	local root = rootOf(thief)
	if not root then return end
	if lobe.owner then
		local d = PlayerData.get(lobe.owner)
		if d and d.mindBlockUntil > os.clock() then
			PlayerData.alert(thief, "🛡️ MIND BLOCK IS UP!", Color3.fromRGB(255, 80, 200), 1.5)
			return
		end
	end
	local item = LobeService.beginSteal(lobe, slot, thief)
	if not item then return end
	local entry = Catalog.list[item.id]
	local model = Kit.build(entry, item.mut, 1)
	Kit.attachNameTag(model, entry, item.mut, 1, LobeService.itemIncome(item))
	if not attach(thief, item, model, { lobe = lobe, slot = slot }) then
		model:Destroy()
		LobeService.cancelSteal(lobe, slot)
		return
	end
	PlayerData.alert(thief, "STOLEN! RUN HOME!", RED, 3)
	if lobe.owner then
		PlayerData.alert(lobe.owner, "🚨 " .. string.upper(thief.DisplayName) .. " IS STEALING YOUR " .. string.upper(entry.name) .. "! [F] SLAP!", RED, 3)
	end
end

function CarryService.slap(player)
	local d = PlayerData.get(player)
	local root = rootOf(player)
	if not d or not root or d.slapReady > os.clock() then return end
	d.slapReady = os.clock() + SLAP_COOLDOWN
	local best, bestDist
	for _, other in ipairs(Players:GetPlayers()) do
		local r = other ~= player and rootOf(other)
		if r then
			local dist = (r.Position - root.Position).Magnitude
			if dist <= SLAP_RANGE and (not bestDist or dist < bestDist) then best, bestDist = other, dist end
		end
	end
	popup(root, "FOCUS SLAP!", Color3.fromRGB(255, 230, 60))
	if CarryService.onSlap and CarryService.onSlap(player, root) then
		PlayerData.push(player)
		return
	end
	if best then
		local r, humanoid = rootOf(best)
		local dir = (r.Position - root.Position) * Vector3.new(1, 0, 1)
		dir = dir.Magnitude > 0.1 and dir.Unit or root.CFrame.LookVector
		best.Character:PivotTo(r.CFrame + dir * 12 + Vector3.new(0, 3, 0))
		humanoid.Sit = true
		task.delay(1.5, function() humanoid.Sit = false end)
		popup(r, "💥 SLAPPED!", RED)
		if carrying[best] and carrying[best].from then
			CarryService.drop(best)
			PlayerData.alert(best, "SLAPPED! YOU DROPPED IT", RED, 2)
			PlayerData.feed("👋 " .. player.DisplayName .. " Focus Slapped " .. best.DisplayName .. "!", Color3.fromRGB(255, 230, 60))
		end
	end
	PlayerData.push(player)
end

function CarryService.mindBlock(player)
	local d = PlayerData.get(player)
	local lobe = LobeService.lobeOf(player)
	if not d or not lobe or d.mindBlockReady > os.clock() then return end
	d.mindBlockUntil = os.clock() + MIND_BLOCK_SECONDS
	d.mindBlockReady = os.clock() + MIND_BLOCK_COOLDOWN
	local field = lobe.model.MindBlockField
	field.Transparency = 0.68
	PlayerData.alert(player, "🛡️ MIND BLOCK ON", Color3.fromRGB(255, 80, 200), 1.5)
	task.delay(MIND_BLOCK_SECONDS, function() field.Transparency = 1 end)
	PlayerData.push(player)
end

-- 5 times a second: carriers who reach home place their brainrot; Mind Block pushes intruders out.
function CarryService.tick()
	for player, c in pairs(carrying) do
		local root = rootOf(player)
		local lobe = LobeService.lobeOf(player)
		if not root or not c.model.Parent then
			CarryService.drop(player)
		elseif lobe and LobeService.isInside(lobe, root.Position) then
			place(player, c)
		end
	end
	local now = os.clock()
	for _, lobe in pairs(LobeService.lobes) do
		local d = lobe.owner and PlayerData.get(lobe.owner)
		if d and d.mindBlockUntil > now then
			for _, other in ipairs(Players:GetPlayers()) do
				local root = other ~= lobe.owner and rootOf(other)
				if root and LobeService.isInside(lobe, root.Position) then
					if carrying[other] and carrying[other].from and carrying[other].from.lobe == lobe then CarryService.drop(other) end
					root.CFrame = lobe.model.MindBlockField.CFrame * CFrame.new(0, -8, -6)
					root.AssemblyLinearVelocity = Vector3.zero
				end
			end
		end
	end
end

function CarryService.init()
	LobeService.onSteal = onSteal
	SynapseBelt.onBuy = function(player, item, model)
		return attach(player, item, model, nil)
	end
	Players.PlayerRemoving:Connect(CarryService.drop)
end

return CarryService
