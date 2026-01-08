local KeySystem = {}

KeySystem.KEY_ID_NAME = "KeyId"

function KeySystem.hasKeyWithId(player, keyId)
	if not keyId or keyId == "" then
		return false
	end
	
	local collectionFolder = player:FindFirstChild("CollectedItems")
	if not collectionFolder then
		return false
	end

	for _, itemValue in ipairs(collectionFolder:GetChildren()) do
		if itemValue:IsA("StringValue") then
			local keyIdValue = itemValue:FindFirstChild(KeySystem.KEY_ID_NAME)
			if keyIdValue and keyIdValue:IsA("StringValue") and keyIdValue.Value == keyId then
				return true
			end
		end
	end
	
	return false
end

function KeySystem.getKeyId(object)
	local keyIdValue = object:FindFirstChild(KeySystem.KEY_ID_NAME)
	if keyIdValue and keyIdValue:IsA("StringValue") then
		return keyIdValue.Value
	end
	return nil
end

return KeySystem

