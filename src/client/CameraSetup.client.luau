local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function setupCamera()
	if not camera then return end
	
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

if camera then
	setupCamera()
end

player.CharacterAdded:Connect(function()
	task.wait(0.1)
	setupCamera()
end)

