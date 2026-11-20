-- The Most Rotted board on the Brain Stem Plaza: every Lobe owner ranked by Brain Cells and by Brainpedia count.
-- NPC kids get made-up stats that grow over time, so the board is never empty in a one-player server.
local RS = game.ReplicatedStorage
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerData = require(script.Parent.PlayerData)
local LobeService = require(script.Parent.LobeService)
local NumberFormat = require(RS.NumberFormat)

local MostRotted = {}
local ROWS = 8
local GOLD, LIME, PINK = Color3.fromRGB(255, 215, 60), Color3.fromRGB(130, 255, 80), Color3.fromRGB(255, 110, 200)
local NPC_CELLS = { 4200, 18000, 950, 52000, 7600, 31000, 2400, 12500 }
local NPC_FOUND = { 9, 17, 5, 22, 11, 19, 7, 14 }
local columns = {}

local function label(parent, text, color, pos, size, align)
	local l = Instance.new("TextLabel")
	l.Position, l.Size, l.BackgroundTransparency = pos, size, 1
	l.Font, l.TextScaled, l.Text, l.TextColor3 = Enum.Font.FredokaOne, true, text, color
	l.TextStrokeTransparency, l.TextXAlignment = 0, align or Enum.TextXAlignment.Center
	l.Parent = parent
	return l
end

local function buildModel()
	local c = WorldBuilder.PLAZA_CENTER + Vector3.new(34, 0, 30)
	local model = Instance.new("Model")
	model.Name = "MostRottedBoard"
	local face = CFrame.lookAt(c + Vector3.new(0, 14, 0), WorldBuilder.PLAZA_CENTER + Vector3.new(0, 14, -20))
	local board = Instance.new("Part")
	board.Name, board.Size, board.CFrame, board.Anchored = "Board", Vector3.new(26, 18, 1), face, true
	board.Color, board.Material = Color3.fromRGB(25, 0, 35), Enum.Material.SmoothPlastic
	board.Parent = model
	for _, x in ipairs({ -11, 11 }) do
		local post = board:Clone()
		post.Name, post.Size, post.CFrame, post.Color = "Post", Vector3.new(1.5, 6, 1.5), face * CFrame.new(x, -12, 0), PINK
		post.Material = Enum.Material.Neon
		post.Parent = model
	end
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = PINK, 20, 1.2
	light.Parent = board

	local sg = Instance.new("SurfaceGui")
	sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 30, 0
	sg.Parent = board
	label(sg, "🏆 MOST ROTTED 🏆", PINK, UDim2.fromScale(0, 0.01), UDim2.fromScale(1, 0.14))
	for i, title in ipairs({ "🧠 BRAIN CELLS", "📖 BRAINPEDIA" }) do
		local x = (i - 1) * 0.5
		label(sg, title, i == 1 and GOLD or LIME, UDim2.fromScale(x + 0.02, 0.16), UDim2.fromScale(0.46, 0.09))
		local rows = {}
		for r = 1, ROWS do
			rows[r] = label(sg, "", Color3.new(1, 1, 1), UDim2.fromScale(x + 0.03, 0.26 + (r - 1) * 0.092), UDim2.fromScale(0.44, 0.085), Enum.TextXAlignment.Left)
		end
		columns[i] = rows
	end
	model.Parent = workspace
end

local function entries()
	local list, t = {}, time() / 60
	for index, lobe in pairs(LobeService.lobes) do
		local d = lobe.owner and PlayerData.get(lobe.owner)
		if d then
			local found = 0
			for _ in pairs(d.found) do found += 1 end
			table.insert(list, { name = lobe.owner.DisplayName, cells = d.cells, found = found, player = true })
		elseif lobe.npcName then
			table.insert(list, { name = "🧒 " .. lobe.npcName, cells = NPC_CELLS[index] * (1 + t * 0.3), found = math.min(60, NPC_FOUND[index] + math.floor(t / 3)) })
		end
	end
	return list
end

function MostRotted.refresh()
	local list = entries()
	for i, key in ipairs({ "cells", "found" }) do
		table.sort(list, function(a, b) return a[key] > b[key] end)
		for r, row in ipairs(columns[i]) do
			local e = list[r]
			if e then
				local value = key == "cells" and NumberFormat.cells(e[key]) or (e[key] .. "/60")
				row.Text = (r == 1 and "👑 " or r .. ". ") .. e.name .. "  ·  " .. value
				row.TextColor3 = e.player and GOLD or Color3.new(1, 1, 1)
			else
				row.Text = ""
			end
		end
	end
end

function MostRotted.init()
	local old = workspace:FindFirstChild("MostRottedBoard")
	if old then old:Destroy() end
	buildModel()
	task.spawn(function()
		while true do
			MostRotted.refresh()
			task.wait(2)
		end
	end)
end

return MostRotted
