local CollectibleRemoteEvents = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("CollectibleRemoteEvents")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "CollectibleRemoteEvents"
	folder.Parent = ReplicatedStorage
end

local collectItem = folder:FindFirstChild("CollectItem")
if not collectItem then
	collectItem = Instance.new("RemoteEvent")
	collectItem.Name = "CollectItem"
	collectItem.Parent = folder
end

local itemCollected = folder:FindFirstChild("ItemCollected")
if not itemCollected then
	itemCollected = Instance.new("RemoteEvent")
	itemCollected.Name = "ItemCollected"
	itemCollected.Parent = folder
end

local keyUsed = folder:FindFirstChild("KeyUsed")
if not keyUsed then
	keyUsed = Instance.new("RemoteEvent")
	keyUsed.Name = "KeyUsed"
	keyUsed.Parent = folder
end

CollectibleRemoteEvents.CollectItem = collectItem
CollectibleRemoteEvents.ItemCollected = itemCollected
CollectibleRemoteEvents.KeyUsed = keyUsed

return CollectibleRemoteEvents

