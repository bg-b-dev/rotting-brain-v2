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
	for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face, gui.SizingMode, gui.PixelsPerStud, gui.LightInfluence = face, Enum.SurfaceGuiSizingMode.PixelsPerStud, 10, 0
		local text = Instance.new("TextLabel")
		text.Size, text.BackgroundTransparency, text.TextScaled, text.Font = UDim2.fromScale(1, 1), 1, true, Enum.Font.FredokaOne
		text.Text = "🌱 TOUCH GRASS! 🌱 TOUCH GRASS! 🌱 TOUCH GRASS! 🌱"
		text.TextColor3, text.TextStrokeColor3, text.TextStrokeTransparency = Color3.new(1, 1, 1), Color3.fromRGB(20, 80, 10), 0
		text.Parent = gui
		gui.Parent = model.PrimaryPart
	end
	return model
end

local ICE = Color3.fromRGB(170, 230, 255)

local function freezeModel()
	local model = Instance.new("Model")
	model.Name = "BrainFreezeIce"
	local function ice(size, cf, shape)
		local p = Instance.new("Part")
		p.Size, p.CFrame, p.Color, p.Material, p.Transparency = size, cf, ICE, Enum.Material.Glass, 0.35
		p.Anchored, p.CanCollide, p.CanQuery, p.CastShadow = true, false, false, false
		if shape then p.Shape = shape end
		p.Parent = model
		return p
	end
	local center = WorldBuilder.MEME_LOBE_CENTER
	ice(Vector3.new(64, 55, 64), CFrame.new(center), Enum.PartType.Ball)
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		ice(Vector3.new(2.4, rng:NextNumber(8, 16), 2.4), CFrame.new(center + Vector3.new(math.cos(a) * 26, -18, math.sin(a) * 26)) * CFrame.Angles(0, a, math.rad(180)))
	end
	local path = WorldBuilder.BELT_PATH
	for i = 1, #path - 1 do
		local a, b = path[i], path[i + 1]
		for t = 0, (b - a).Magnitude, 12 do
			local h = rng:NextNumber(6, 14)
			local point = a:Lerp(b, t / (b - a).Magnitude) + Vector3.new(rng:NextNumber(-8, 8), h / 2, rng:NextNumber(-8, 8))
			ice(Vector3.new(3, h, 3), CFrame.new(point) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)))
		end
	end
	for _, p in ipairs(model:GetChildren()) do
		if p.Size.X == 3 then p.Material, p.Transparency = Enum.Material.Ice, 0.1 end
	end
	local frost = ice(Vector3.new(400, 0.2, 400), CFrame.new(0, 0.12, 0))
	frost.Material, frost.Color, frost.Transparency = Enum.Material.Ice, Color3.fromRGB(200, 235, 255), 0.45
	local sky = ice(Vector3.new(300, 1, 300), CFrame.new(0, 70, -30))
	sky.Transparency = 1
	local snow = Instance.new("ParticleEmitter")
	snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	snow.Rate, snow.Lifetime, snow.Speed = 400, NumberRange.new(5, 7), NumberRange.new(12, 16)
	snow.EmissionDirection, snow.Size = Enum.NormalId.Bottom, NumberSequence.new(0.9)
	snow.Color, snow.LightEmission = ColorSequence.new(Color3.new(1, 1, 1)), 0.6
	snow.Parent = sky
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
	local fx = tint(Color3.fromRGB(165, 210, 255), -0.15)
	local iceModel = freezeModel()
	iceModel.Parent = workspace
	local old = SynapseBelt.mutationChance
	SynapseBelt.mutationChance = 1
	task.wait(20)
	SynapseBelt.mutationChance = old
	fx:Destroy()
	iceModel:Destroy()
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
