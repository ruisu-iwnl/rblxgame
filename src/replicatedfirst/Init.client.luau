-- ReplicatedFirst script
-- Runs FIRST on the client before all other scripts
-- Perfect for loading screens, critical initialization, etc.

print("ReplicatedFirst: Initializing client...")

-- Example: Hide loading screen after everything loads
task.wait(1) -- Wait for other scripts to initialize
print("ReplicatedFirst: Client initialization complete!")

