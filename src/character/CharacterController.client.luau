print("Character script: Initializing character...")

local character = script.Parent
local humanoid = character:FindFirstChild("Humanoid")

if humanoid then
	humanoid.Died:Connect(function()
		print("Character died!")
	end)

	humanoid.HealthChanged:Connect(function(health)
		if health <= 0 then
			print("Character health reached 0")
		end
	end)

	print("Character script: Character initialized!")
else
	warn("Character script: Humanoid not found in character")
end
