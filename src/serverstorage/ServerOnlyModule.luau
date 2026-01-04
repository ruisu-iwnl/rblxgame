-- Server-only module
-- This module is NOT replicated to clients
-- Use for sensitive server-side logic, data, etc.

local ServerOnlyModule = {}

function ServerOnlyModule:GetSecretData()
	-- This data is only accessible on the server
	return {
		secretKey = "server-only-value",
		adminOnly = true
	}
end

return ServerOnlyModule

