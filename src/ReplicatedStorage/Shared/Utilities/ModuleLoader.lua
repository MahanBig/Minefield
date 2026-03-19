local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dataservice = require(ReplicatedStorage.Packages.dataservice).client

local IsServer = RunService:IsServer()

local RootDirectory = if IsServer then ServerScriptService.Server else ReplicatedStorage.Shared
local ModuleDirectory = if IsServer then RootDirectory.Services else RootDirectory:WaitForChild("Controllers")

local function RunLifecycleHook(module: ModuleScript, hookName: string, successWord: string, failWord: string)
	local import = require(module)
	local moduleName = module.Name
	local hook = import[hookName]
	if not hook then
		return true
	end

	local success, err = pcall(hook)
	if not success then
		print(`[❌] {moduleName} Failed to {failWord}!`)
		warn(err)
		return false
	end

	print(`[✅] {moduleName} {successWord}!`)
	return true
end

local function RequireModule(module: ModuleScript)
	task.spawn(function()
		if not module:IsA("ModuleScript") then
			return
		end
		if not RunLifecycleHook(module, "onInit", "Initialized", "initialize") then
			return
		end
		if not RunLifecycleHook(module, "onStart", "Started", "start") then
			return
		end
	end)
end

function init()
	if not IsServer and Workspace:GetAttribute("ServerInitialized") ~= true then
		dataservice:waitForData()
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

return init
