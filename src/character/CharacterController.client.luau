-- StarterCharacterScripts script
-- Runs on each character instance
-- Use for character-specific logic, animations, controllers, etc.

print("Character script: Initializing character...")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Example: Character-specific setup
humanoid.Died:Connect(function()
	print("Character died!")
end)

humanoid.HealthChanged:Connect(function(health)
	if health <= 0 then
		print("Character health reached 0")
	end
end)

print("Character script: Character initialized!")

