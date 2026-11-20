-- Per-player progress and its DataStore save. Lobe slots live in LobeService while the player is in game;
-- PlayerData only keeps the saved copy and the numbers the HUD shows.
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Remotes = require(game.ReplicatedStorage.Remotes)

local PlayerData = {}
local data = {}
local store
pcall(function() store = DataStoreService:GetDataStore("RottingBrain_v1") end)

local function default()
	return {
		cells = 60, rot = 0, rebirths = 0, lobeLevel = 1, stored = 0,
		slots = {}, found = {}, income = 0, fullyRottedUntil = 0,
		mindBlockUntil = 0, mindBlockReady = 0, slapReady = 0, lobe = 0,
	}
end

function PlayerData.load(player)
	local d = default()
	if store and not RunService:IsStudio() then
		local ok, saved = pcall(store.GetAsync, store, "p" .. player.UserId)
		if ok and type(saved) == "table" then
			for _, key in ipairs({ "cells", "rebirths", "lobeLevel", "stored", "slots" }) do
				if saved[key] ~= nil then d[key] = saved[key] end
			end
			for _, id in ipairs(saved.found or {}) do d.found[id] = true end
		end
	end
	data[player] = d
	return d
end

function PlayerData.save(player, slots)
	local d = data[player]
	if not d or not store or RunService:IsStudio() then return end
	local found = {}
	for id in pairs(d.found) do table.insert(found, id) end
	local saved = { cells = d.cells, rebirths = d.rebirths, lobeLevel = d.lobeLevel, stored = d.stored, slots = slots or d.slots, found = found }
	pcall(store.SetAsync, store, "p" .. player.UserId, saved)
end

function PlayerData.get(player)
	return data[player]
end

function PlayerData.remove(player)
	data[player] = nil
end

function PlayerData.all()
	return data
end

function PlayerData.push(player, extra)
	local d = data[player]
	if not d then return end
	local now = os.clock()
	local found = {}
	for id in pairs(d.found) do table.insert(found, id) end
	local snapshot = {
		cells = d.cells, rot = d.rot, rebirths = d.rebirths, lobeLevel = d.lobeLevel, stored = d.stored,
		income = d.income, lobe = d.lobe, found = found,
		fullyRotted = math.max(0, d.fullyRottedUntil - now),
		mindBlock = math.max(0, d.mindBlockUntil - now), mindBlockCooldown = math.max(0, d.mindBlockReady - now),
		slapCooldown = math.max(0, d.slapReady - now),
	}
	if extra then for k, v in pairs(extra) do snapshot[k] = v end end
	Remotes.State:FireClient(player, snapshot)
end

function PlayerData.alert(player, text, color, seconds)
	Remotes.Alert:FireClient(player, text, color or Color3.fromRGB(255, 60, 60), seconds or 2.5)
end

function PlayerData.feed(text, color)
	Remotes.Feed:FireAllClients(text, color or Color3.new(1, 1, 1))
end

return PlayerData
