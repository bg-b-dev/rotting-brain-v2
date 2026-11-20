-- The server makes the RemoteEvents folder on first require; clients wait for it.
-- Action: client -> server (name, ...). State: server -> one client (snapshot). Feed: server -> all (text, color).
-- Alert: server -> one client (big banner text, color, seconds).
local RunService = game:GetService("RunService")

local NAMES = { "Action", "State", "Feed", "Alert" }
local folder = script.Parent:FindFirstChild("RemoteEvents")
if not folder and RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	for _, name in ipairs(NAMES) do
		Instance.new("RemoteEvent", folder).Name = name
	end
	folder.Parent = script.Parent
end
folder = folder or script.Parent:WaitForChild("RemoteEvents")

local Remotes = {}
for _, name in ipairs(NAMES) do
	Remotes[name] = folder:WaitForChild(name)
end
return Remotes
