local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IsServer = RunService:IsServer()

local RootDirectory = if IsServer then ServerScriptService else ReplicatedStorage.Shared
local ModuleDirectory = if IsServer then RootDirectory.Services else RootDirectory:WaitForChild("Controllers")

local function RequireModule(module: ModuleScript)
	task.spawn(function()
		if not module:IsA("ModuleScript") then
			return
		end

		local import = require(module)

		local onStart = import.onStart
		if onStart then
			local success, err = pcall(onStart)
			if not success then
				print("[❌] " .. module.Name .. " Failed to start")
				warn(err)
				return
			end
			print("[✅] " .. module.Name .. " Started!")
		end
	end)
end

return function()
	if not IsServer and Workspace:GetAttribute("ServerInitialized") ~= true then
		Workspace:GetAttributeChangedSignal("ServerInitialized"):Wait()
	end
	for _, descendant: ModuleScript in ModuleDirectory:GetDescendants() do
		RequireModule(descendant)
	end
	if IsServer then
		Workspace:SetAttribute("ServerInitialized", true)
	end
	if not IsServer then
		ModuleDirectory.DescendantAdded:Connect(function(descendant: ModuleScript)
			RequireModule(descendant)
		end)
	end
end
