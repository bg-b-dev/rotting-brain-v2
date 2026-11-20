-- Random brain events: Touch Grass Wave, Brain Freeze, Brain Lag and Dopamine Rush. The HUD reads the
-- workspace attributes Event, EventColor and EventEnd. Studio captures set workspace "EventsPaused".
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SSS = game:GetService("ServerScriptService")
local PlayerData = require(SSS.PlayerData)
local LobeService = require(SSS.LobeService)
local SynapseBelt = require(SSS.SynapseBelt)
local CarryService = require(SSS.CarryService)
local WorldBuilder = require(SSS.WorldBuilder)
local Catalog = require(game.ReplicatedStorage.BrainrotCatalog)

local EventService = {}
EventService.current = nil

local rng = Random.new()
local GREEN = Color3.fromRGB(90, 230, 70)

local function tint(color, saturation)
	local fx = Lighting:FindFirstChild("EventTint") or Instance.new("ColorCorrectionEffect")
	fx.Name = "EventTint"
	fx.TintColor = color
	fx.Saturation = saturation or 0
	fx.Parent = Lighting
	return fx
end

local function announce(text, color, seconds)
	workspace:SetAttribute("Event", text)
	workspace:SetAttribute("EventColor", color)
	workspace:SetAttribute("EventEnd", workspace:GetServerTimeNow() + seconds)
	for _, player in ipairs(Players:GetPlayers()) do PlayerData.alert(player, text .. "!", color, 3) end
	PlayerData.feed(text .. " started!", color)
end

local function wallModel()
	local model = Instance.new("Model")
	model.Name = "TouchGrassWall"
	local function part(name, size, offset, color, material)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Color, p.Material = name, size, color, material
		p.Anchored, p.CanCollide, p.CanQuery, p.CastShadow = true, false, false, false
		p.CFrame = CFrame.new(offset)
		p.Parent = model
		return p
	end
	model.PrimaryPart = part("Wall", Vector3.new(10, 34, 400), Vector3.zero, GREEN, Enum.Material.Grass)
	part("Crest", Vector3.new(11, 2, 400), Vector3.new(0, 17, 0), Color3.fromRGB(160, 255, 90), Enum.Material.Neon)
	local flowers = { Color3.fromRGB(255, 90, 170), Color3.fromRGB(255, 230, 60), Color3.new(1, 1, 1), Color3.fromRGB(120, 200, 255) }
	for i = 1, 70 do
		local f = part("Flower", Vector3.new(2.6, 2.6, 2.6), Vector3.new(rng:NextNumber(-5.5, 5.5), rng:NextNumber(-15, 16), rng:NextNumber(-198, 198)), flowers[i % #flowers + 1], Enum.Material.SmoothPlastic)
		f.Shape = Enum.PartType.Ball
	end
	return model
end

local EVENTS = {}

EVENTS.touchGrass = function()
	local seconds = 18
	announce("🌱 TOUCH GRASS WAVE · GO UPSTAIRS", GREEN, seconds)
	local wall = wallModel()
	local half = WorldBuilder.FLOOR_SIZE / 2
	local dir = rng:NextNumber() < 0.5 and 1 or -1
	local hit = {}
	wall:PivotTo(CFrame.new(-dir * half, 17, 0))
	wall.Parent = workspace
	local start = os.clock()
	while os.clock() - start < seconds do
		local x = -dir * half + dir * 2 * half * (os.clock() - start) / seconds
		wall:PivotTo(CFrame.new(x, 17, 0))
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and not hit[player] and math.abs(root.Position.X - x) < 7 and root.Position.Y < WorldBuilder.FLOOR2_HEIGHT then
				hit[player] = true
				CarryService.drop(player)
				-- The client owns its character physics, so a server velocity is ignored; pivot and Sit replicate.
				character:PivotTo(root.CFrame + Vector3.new(dir * 14, 4, 0))
				humanoid.Sit = true
				task.delay(1.5, function() humanoid.Sit = false end)
				PlayerData.alert(player, "🌱 YOU TOUCHED GRASS!", GREEN, 2)
			end
		end
		task.wait(0.05)
	end
	wall:Destroy()
end

EVENTS.brainFreeze = function()
	announce("🧊 BRAIN FREEZE · EVERY MEME MUTATES", Color3.fromRGB(80, 190, 255), 20)
	local fx = tint(Color3.fromRGB(190, 225, 255))
	local old = SynapseBelt.mutationChance
	SynapseBelt.mutationChance = 1
	task.wait(20)
	SynapseBelt.mutationChance = old
	fx:Destroy()
end

EVENTS.brainLag = function()
	announce("⏳ BRAIN LAG · BUFFERING...", Color3.fromRGB(130, 130, 140), 15)
	local fx = tint(Color3.fromRGB(220, 220, 220), -0.7)
	SynapseBelt.paused = true
	task.wait(15)
	SynapseBelt.paused = false
	fx:Destroy()
	local pool = Catalog.ofTier(rng:NextInteger(4, 6))
	SynapseBelt.spawn(pool[rng:NextInteger(1, #pool)].id)
	PlayerData.feed("📦 Brain Lag dropped a rare meme on the belt!", Color3.fromRGB(255, 220, 60))
end

EVENTS.dopamineRush = function()
	announce("🌈 DOPAMINE RUSH · ALL LOBES x2", Color3.fromRGB(255, 120, 220), 30)
	LobeService.eventMultiplier = 2
	task.wait(30)
	LobeService.eventMultiplier = 1
end

local ORDER = { "touchGrass", "brainFreeze", "dopamineRush", "brainLag" }

function EventService.start(name)
	if EventService.current or not EVENTS[name] then return false end
	EventService.current = name
	task.spawn(function()
		local ok, err = pcall(EVENTS[name])
		if not ok then warn("EventService " .. name .. ": " .. tostring(err)) end
		workspace:SetAttribute("Event", nil)
		EventService.current = nil
	end)
	return true
end

function EventService.init()
	task.spawn(function()
		local last
		task.wait(45)
		while true do
			if not workspace:GetAttribute("EventsPaused") then
				local name
				repeat name = ORDER[rng:NextInteger(1, #ORDER)] until name ~= last
				if EventService.start(name) then last = name end
			end
			task.wait(rng:NextInteger(70, 95))
		end
	end)
end

return EventService
