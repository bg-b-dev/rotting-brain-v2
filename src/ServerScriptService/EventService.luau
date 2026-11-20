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
local Kit = require(game.ReplicatedStorage.BrainrotModelKit)

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
	model.PrimaryPart = part("Wall", Vector3.new(10, 34, 400), Vector3.zero, Color3.fromRGB(110, 255, 90), Enum.Material.SmoothPlastic)
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
	for _, player in ipairs(Players:GetPlayers()) do
		if not hit[player] then PlayerData.quest(player, 3) end
	end
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

local PIXIE_BLUE = Color3.fromRGB(120, 200, 255)

local function pixieModel()
	local model = Instance.new("Model")
	model.Name = "ProductivityPixie"
	local function part(name, size, offset, color, shape, material)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Color, p.Material = name, size, color, material or Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanQuery, p.CastShadow = true, false, false, false
		if shape then p.Shape = shape end
		p.CFrame = CFrame.new(offset)
		p.Parent = model
		return p
	end
	model.PrimaryPart = part("Body", Vector3.new(3, 3.6, 3), Vector3.zero, PIXIE_BLUE, Enum.PartType.Ball)
	part("Head", Vector3.new(2.8, 2.8, 2.8), Vector3.new(0, 2.8, 0), Color3.fromRGB(255, 215, 180), Enum.PartType.Ball)
	part("Bun", Vector3.new(1.4, 1.4, 1.4), Vector3.new(0, 4.4, 0.4), Color3.fromRGB(90, 60, 40), Enum.PartType.Ball)
	for _, x in ipairs({ -0.6, 0.6 }) do
		part("Lens", Vector3.new(0.2, 0.9, 0.9), Vector3.new(x, 3, -1.35), Color3.fromRGB(30, 30, 40), Enum.PartType.Cylinder).CFrame = CFrame.new(x, 3, -1.35) * CFrame.Angles(0, math.rad(90), 0)
		local wing = part("Wing", Vector3.new(0.2, 3.4, 2.4), Vector3.new(x * 3, 1, 1.2), Color3.new(1, 1, 1), nil, Enum.Material.Neon)
		wing.Transparency = 0.45
		wing:SetAttribute("Side", x > 0 and 1 or -1)
	end
	part("Clipboard", Vector3.new(2.2, 2.8, 0.2), Vector3.new(0, 0, -1.8), Color3.fromRGB(150, 100, 60))
	part("Sheet", Vector3.new(1.9, 2.3, 0.05), Vector3.new(0, -0.15, -1.92), Color3.new(1, 1, 1))
	model:ScaleTo(2)
	local rel = {}
	for _, p in ipairs(model:GetChildren()) do rel[p] = model.PrimaryPart.CFrame:ToObjectSpace(p.CFrame) end
	local papers = Instance.new("ParticleEmitter")
	papers.Rate, papers.Lifetime, papers.Speed = 6, NumberRange.new(1.5, 2.5), NumberRange.new(2, 4)
	papers.Size, papers.Rotation, papers.RotSpeed = NumberSequence.new(0.7), NumberRange.new(0, 360), NumberRange.new(-120, 120)
	papers.Texture, papers.Acceleration = "rbxasset://textures/particles/sparkles_main.dds", Vector3.new(0, -6, 0)
	papers.Parent = model.PrimaryPart
	local anchor = Instance.new("Attachment")
	anchor.Position = Vector3.new(0, 6.5, 0)
	anchor.Parent = model.PrimaryPart
	local gui = Instance.new("BillboardGui")
	gui.Size, gui.LightInfluence = UDim2.new(11, 0, 2, 0), 0
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency, label.TextScaled, label.Font = UDim2.fromScale(1, 1), 1, true, Enum.Font.LuckiestGuy
	label.Text, label.TextColor3, label.TextStrokeTransparency = "📋 PRODUCTIVITY PIXIE · [F] SLAP", Color3.new(1, 1, 1), 0
	label.TextStrokeColor3 = Color3.fromRGB(20, 60, 120)
	label.Parent = gui
	-- Parts are anchored, so the raid loop places each one from this table instead of welds.
	return model, rel
end

local PIXIE_COUNT, RAID_SECONDS, PIXIE_SPEED, FLEE_SPEED = 6, 30, 30, 9
local pixies = {}

local function raidTargets()
	local mine, npc = {}, {}
	for _, lobe in pairs(LobeService.lobes) do
		local d = lobe.owner and PlayerData.get(lobe.owner)
		if not (d and d.mindBlockUntil > os.clock()) then
			for slot, item in pairs(lobe.slots) do
				if not item.stolenBy and lobe.models[slot] then table.insert(lobe.owner and mine or npc, { lobe = lobe, slot = slot }) end
			end
		end
	end
	return #mine > 0 and mine or npc
end

function EventService.slapPixie(player, root)
	local best, bestDist
	for _, px in ipairs(pixies) do
		local p = px.model.PrimaryPart.Position
		local dist = ((p - root.Position) * Vector3.new(1, 0, 1)).Magnitude
		if not px.done and dist <= 14 and p.Y - root.Position.Y < 26 and (not bestDist or dist < bestDist) then best, bestDist = px, dist end
	end
	if not best then return false end
	best.done = true
	local bounty = 150
	if best.carry then
		bounty = math.max(150, math.floor(LobeService.itemIncome(best.carry.item) * 5))
		LobeService.cancelSteal(best.carry.lobe, best.carry.slot)
		best.carry.model:Destroy()
		best.carry = nil
	end
	local d = PlayerData.get(player)
	if d then d.cells += bounty end
	PlayerData.alert(player, "👋 PIXIE SLAPPED! +🧠" .. bounty, Color3.fromRGB(255, 230, 60), 2)
	PlayerData.feed("👋 " .. player.DisplayName .. " slapped a Productivity Pixie!", PIXIE_BLUE)
	PlayerData.push(player)
	return true
end

EVENTS.homeworkRaid = function()
	announce("📋 HOMEWORK RAID · SLAP THE PIXIES [F]", Color3.fromRGB(255, 70, 70), RAID_SECONDS)
	local fx = tint(Color3.fromRGB(255, 225, 225), 0)
	local start, spawned, taken = os.clock(), 0, {}
	local last = start
	while os.clock() - start < RAID_SECONDS and (#pixies > 0 or spawned < PIXIE_COUNT) do
		task.wait(0.05)
		local now = os.clock()
		local dt = now - last
		last = now
		if spawned < PIXIE_COUNT and now - start >= spawned * 4 then
			spawned += 1
			local list = {}
			for _, t in ipairs(raidTargets()) do
				if not taken[t.lobe.models[t.slot]] then table.insert(list, t) end
			end
			if #list > 0 then
				local target = list[rng:NextInteger(1, #list)]
				taken[target.lobe.models[target.slot]] = true
				local model, rel = pixieModel()
				local a = rng:NextNumber(0, math.pi * 2)
				model.Parent = workspace
				table.insert(pixies, { model = model, rel = rel, pos = Vector3.new(math.cos(a) * 60, 70, -25 + math.sin(a) * 60), target = target, phase = rng:NextNumber(0, 6) })
			end
		end
		for i = #pixies, 1, -1 do
			local px = pixies[i]
			local goal
			if px.done then
				goal = nil
			elseif px.flee then
				goal = px.flee
			else
				local m = px.target.lobe.models[px.target.slot]
				goal = m and m:GetPivot().Position + Vector3.new(0, 9, 0)
				if not goal then px.flee = px.pos + Vector3.new(0, 40, 0) end
			end
			if goal then
				local delta = goal - px.pos
				local step = (px.flee and FLEE_SPEED or PIXIE_SPEED) * dt
				if delta.Magnitude <= step then
					px.pos = goal
					if px.flee then
						if px.carry then
							local c = px.carry
							local entry = Catalog.list[c.item.id]
							LobeService.finishSteal(c.lobe, c.slot)
							if c.lobe.owner then
								PlayerData.alert(c.lobe.owner, "📋 A PIXIE TOOK YOUR " .. string.upper(entry.name) .. " TO HOMEWORK!", Color3.fromRGB(255, 70, 70), 3)
								PlayerData.push(c.lobe.owner)
							end
							PlayerData.feed("📋 A Productivity Pixie stole " .. entry.name .. "!", PIXIE_BLUE)
							c.model:Destroy()
							px.carry = nil
						end
						px.done = true
					else
						local t = px.target
						local item = LobeService.beginSteal(t.lobe, t.slot, "pixie")
						if item then
							local entry = Catalog.list[item.id]
							local carried = Kit.build(entry, item.mut, 1)
							for _, d in ipairs(carried:GetDescendants()) do if d:IsA("ProximityPrompt") then d:Destroy() end end
							carried.Parent = workspace
							px.carry = { lobe = t.lobe, slot = t.slot, item = item, model = carried, drop = 5 + carried:GetExtentsSize().Y }
							if t.lobe.owner then PlayerData.alert(t.lobe.owner, "🚨 PIXIE GRABBED YOUR " .. string.upper(entry.name) .. "! [F] SLAP IT!", Color3.fromRGB(255, 70, 70), 3) end
						end
						local out = (px.pos * Vector3.new(1, 0, 1)).Unit
						px.flee = px.pos + out * 120 + Vector3.new(0, 4, 0)
					end
				else
					px.pos += delta.Unit * step
				end
			end
			local face = goal and (goal - px.pos) * Vector3.new(1, 0, 1)
			local look = face and face.Magnitude > 0.5 and CFrame.lookAt(px.pos, px.pos + face) or CFrame.new(px.pos)
			local cf = look * CFrame.new(0, math.sin(now * 4 + px.phase) * 0.6, 0)
			local flap = math.sin(now * 30) * 0.6
			for p, offset in pairs(px.rel) do
				local side = p:GetAttribute("Side")
				p.CFrame = cf * offset * (side and CFrame.Angles(0, 0, side * flap) or CFrame.identity)
			end
			if px.carry then px.carry.model:PivotTo(cf * CFrame.new(0, -px.carry.drop, 0) * CFrame.Angles(0, math.pi, 0)) end
			if px.done and not px.carry then
				px.model:Destroy()
				table.remove(pixies, i)
			end
		end
	end
	for _, px in ipairs(pixies) do
		if px.carry then
			LobeService.cancelSteal(px.carry.lobe, px.carry.slot)
			px.carry.model:Destroy()
		end
		px.model:Destroy()
	end
	table.clear(pixies)
	fx:Destroy()
end

local ORDER = { "touchGrass", "brainFreeze", "dopamineRush", "brainLag", "homeworkRaid" }
local NEXT_LABEL = {
	touchGrass = "🌱 TOUCH GRASS WAVE", brainFreeze = "🧊 BRAIN FREEZE", dopamineRush = "🌈 DOPAMINE RUSH",
	brainLag = "⏳ BRAIN LAG", homeworkRaid = "📋 HOMEWORK RAID",
}

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
	CarryService.onSlap = EventService.slapPixie
	task.spawn(function()
		local last, wait = nil, 45
		while true do
			local name
			repeat name = ORDER[rng:NextInteger(1, #ORDER)] until name ~= last
			workspace:SetAttribute("NextEvent", NEXT_LABEL[name])
			workspace:SetAttribute("NextEventAt", workspace:GetServerTimeNow() + wait)
			task.wait(wait)
			if not workspace:GetAttribute("EventsPaused") and EventService.start(name) then last = name end
			wait = rng:NextInteger(70, 95)
		end
	end)
end

return EventService
