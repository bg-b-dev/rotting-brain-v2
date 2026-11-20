-- Short Brain Cell amounts for tags and the HUD: 950, 1.2K, 48K, 3.5M, 1.1B.
local NumberFormat = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa" }

function NumberFormat.short(n)
	n = math.floor(n + 0.5)
	local tier = 1
	local value = n
	while math.abs(value) >= 1000 and tier < #SUFFIXES do
		value /= 1000
		tier += 1
	end
	if tier == 1 then return tostring(n) end
	local text = value >= 100 and string.format("%d", value) or string.format("%.1f", value):gsub("%.0$", "")
	return text .. SUFFIXES[tier]
end

function NumberFormat.cells(n)
	return "🧠" .. NumberFormat.short(n)
end

return NumberFormat
