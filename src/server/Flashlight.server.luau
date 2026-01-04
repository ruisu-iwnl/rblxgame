local Players = game:GetService("Players")

local function createFlashlight(character)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoidRootPart then return nil end
	
	local existingAttachment = humanoidRootPart:FindFirstChild("FlashlightAttachment")
	if existingAttachment then
		existingAttachment:Destroy()
	end
	
	local spotlight = Instance.new("SpotLight")
	spotlight.Name = "Flashlight"
	spotlight.Brightness = 2
	spotlight.Angle = 45
	spotlight.Face = Enum.NormalId.Front
	spotlight.Range = 50
	spotlight.Color = Color3.new(1, 0.95, 0.8)
	spotlight.Shadows = true
	
	local attachment = Instance.new("Attachment")
	attachment.Name = "FlashlightAttachment"
	attachment.Parent = humanoidRootPart
	spotlight.Parent = attachment
	
	return spotlight, attachment
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		createFlashlight(character)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		createFlashlight(player.Character)
	end
end

