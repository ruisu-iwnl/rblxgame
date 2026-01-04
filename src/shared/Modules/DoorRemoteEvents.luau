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

DoorRemoteEvents.DoorOpen = doorOpen
DoorRemoteEvents.DoorProximity = doorProximity

return DoorRemoteEvents

