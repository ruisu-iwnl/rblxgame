local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SprintSystem = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("SprintSystem"))

local function ensureRemoteEvent()
	local remote = ReplicatedStorage:FindFirstChild(SprintSystem.REMOTE_EVENT_NAME)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = SprintSystem.REMOTE_EVENT_NAME
		remote.Parent = ReplicatedStorage
	end
	return remote
end
local SprintEvent = ensureRemoteEvent()

local function onSprint(player, isSprinting)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	if isSprinting then
		humanoid.WalkSpeed = SprintSystem.SPRINT_SPEED
	else
		humanoid.WalkSpeed = SprintSystem.NORMAL_SPEED
	end
end

SprintEvent.OnServerEvent:Connect(onSprint)

