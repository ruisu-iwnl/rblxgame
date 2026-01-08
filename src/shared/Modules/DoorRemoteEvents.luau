local DoorRemoteEvents = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("DoorRemoteEvents")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "DoorRemoteEvents"
	folder.Parent = ReplicatedStorage
end

local doorOpen = folder:FindFirstChild("DoorOpen")
if not doorOpen then
	doorOpen = Instance.new("RemoteEvent")
	doorOpen.Name = "DoorOpen"
	doorOpen.Parent = folder
end

local doorProximity = folder:FindFirstChild("DoorProximity")
if not doorProximity then
	doorProximity = Instance.new("RemoteEvent")
	doorProximity.Name = "DoorProximity"
	doorProximity.Parent = folder
end

local doorUnlocked = folder:FindFirstChild("DoorUnlocked")
if not doorUnlocked then
	doorUnlocked = Instance.new("RemoteEvent")
	doorUnlocked.Name = "DoorUnlocked"
	doorUnlocked.Parent = folder
end

DoorRemoteEvents.DoorOpen = doorOpen
DoorRemoteEvents.DoorProximity = doorProximity
DoorRemoteEvents.DoorUnlocked = doorUnlocked

return DoorRemoteEvents

