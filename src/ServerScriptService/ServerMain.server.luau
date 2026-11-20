-- Starts every service in its own pcall, wires players and client actions, and runs the ticks.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SSS = game:GetService("ServerScriptService")
local Remotes = require(game.ReplicatedStorage.Remotes)
local NumberFormat = require(game.ReplicatedStorage.NumberFormat)

local function load(name)
	local ok, result = pcall(require, SSS:FindFirstChild(name))
	if not ok then warn("ServerMain: require " .. name .. " failed: " .. tostring(result)) end
	return ok and result or nil
end

local PlayerData = load("PlayerData")
local LobeService = load("LobeService")
local SynapseBelt = load("SynapseBelt")
local CarryService = load("CarryService")
local EventService = load("EventService")
local MemeBlender = load("MemeBlender")

for name, service in pairs({ LobeService = LobeService, SynapseBelt = SynapseBelt, CarryService = CarryService, EventService = EventService, MemeBlender = MemeBlender }) do
	local ok, err = pcall(service.init)
	if not ok then warn("ServerMain: init " .. name .. " failed: " .. tostring(err)) end
end

local function upgradeCost(d) return math.floor(150 * 3.2 ^ (d.lobeLevel - 1)) end
local function brainWashCost(d) return 250000 * 6 ^ d.rebirths end

local function onPlayer(player)
	local d = PlayerData.load(player)
	LobeService.assign(player)
	player.CharacterAdded:Connect(function(character)
		task.wait()
		local lobe = LobeService.lobeOf(player)
		if lobe then character:PivotTo(lobe.model.CollectPad.CFrame * CFrame.new(0, 4, 0)) end
	end)
	PlayerData.feed("🧠 " .. player.DisplayName .. " joined the brain", Color3.fromRGB(150, 220, 255))
	PlayerData.push(player, { upgradeCost = upgradeCost(d), brainWashCost = brainWashCost(d) })
end

local ACTIONS = {}
ACTIONS.slap = function(player) CarryService.slap(player) end
ACTIONS.mindBlock = function(player) CarryService.mindBlock(player) end
ACTIONS.upgrade = function(player, d)
	local cost = upgradeCost(d)
	if d.cells < cost then return PlayerData.alert(player, "NEED " .. NumberFormat.cells(cost), nil, 1.5) end
	d.cells -= cost
	d.lobeLevel += 1
	PlayerData.alert(player, "LOBE LV " .. d.lobeLevel .. "! INCOME +25%", Color3.fromRGB(255, 220, 60), 2)
	LobeService.refresh(LobeService.lobeOf(player))
end
ACTIONS.brainWash = function(player, d)
	local cost = brainWashCost(d)
	if d.cells < cost then return PlayerData.alert(player, "BRAIN WASH NEEDS " .. NumberFormat.cells(cost), nil, 1.8) end
	CarryService.drop(player)
	d.cells, d.stored, d.lobeLevel, d.rot = 60, 0, 1, 0
	d.rebirths += 1
	LobeService.clear(player)
	PlayerData.alert(player, "🧼 BRAIN WASHED! x" .. (1 + 0.5 * d.rebirths) .. " INCOME FOREVER", Color3.fromRGB(60, 230, 255), 3)
	PlayerData.feed("🧼 " .. player.DisplayName .. " Brain Washed (rebirth " .. d.rebirths .. ")!", Color3.fromRGB(60, 230, 255))
end
ACTIONS.collect = function(player) LobeService.collect(player) end

Remotes.Action.OnServerEvent:Connect(function(player, name)
	local d = PlayerData.get(player)
	local action = type(name) == "string" and ACTIONS[name]
	if not d or not action then return end
	local ok, err = pcall(action, player, d)
	if not ok then warn("ServerMain: action " .. name .. ": " .. tostring(err)) end
	PlayerData.push(player, { upgradeCost = upgradeCost(d), brainWashCost = brainWashCost(d) })
end)

Players.PlayerAdded:Connect(onPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, player) end
Players.PlayerRemoving:Connect(function(player)
	CarryService.drop(player)
	PlayerData.save(player, LobeService.release(player))
	PlayerData.remove(player)
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do PlayerData.save(player, LobeService.savedSlots(LobeService.lobeOf(player))) end
end)

task.spawn(function()
	local saveTimer = 0
	while true do
		task.wait(1)
		pcall(LobeService.tick)
		saveTimer += 1
		if saveTimer >= 90 then
			saveTimer = 0
			for player in pairs(PlayerData.all()) do
				local lobe = LobeService.lobeOf(player)
				if lobe then task.spawn(PlayerData.save, player, LobeService.savedSlots(lobe)) end
			end
		end
	end
end)
task.spawn(function()
	while true do
		task.wait(0.2)
		local ok, err = pcall(CarryService.tick)
		if not ok then warn("CarryService.tick: " .. tostring(err)) end
	end
end)

-- Studio-only test hook (lesson 11): execute_luau drives live services through this, never through require.
if RunService:IsStudio() then
	local hook = Instance.new("BindableFunction")
	hook.Name = "PlaytestControls"
	local services = { PlayerData = PlayerData, LobeService = LobeService, SynapseBelt = SynapseBelt, CarryService = CarryService, EventService = EventService, MemeBlender = MemeBlender }
	hook.OnInvoke = function(service, key, ...)
		local value = services[service] and services[service][key]
		if type(value) == "function" then return value(...) end
		if select("#", ...) > 0 then services[service][key] = ... end
		return value
	end
	hook.Parent = game.ServerStorage
end
