print("Character script: Initializing character...")

local character = script.Parent

task.spawn(function()
	local humanoid = character:WaitForChild("Humanoid", 10)
	
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
	end
end)
