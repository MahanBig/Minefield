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
		return 
	end

	local success, err = pcall(hook)
	if not success then
		print(`[❌] {moduleName} Failed to {failWord}!`)
		warn(err)
		return 
	end

	print(`[✅] {moduleName} {successWord}!`)
end

local function RequireModule(module: ModuleScript, initialize: boolean)
	task.spawn(function()
		if not module:IsA("ModuleScript") then
			return
		end
		
		if initialize then
			RunLifecycleHook(module, "onInit", "Initialized", "initialize")
			else
			RunLifecycleHook(module, "onStart", "Started", "start")
		end

	end)
end

function init()
	if not IsServer and Workspace:GetAttribute("ServerInitialized") ~= true then
		dataservice:waitForData()
		Workspace:GetAttributeChangedSignal("ServerInitialized"):Wait()
	end
	for _, descendant: ModuleScript in ModuleDirectory:GetDescendants() do
		RequireModule(descendant, true)
	end
	for _, descendant: ModuleScript in ModuleDirectory:GetDescendants() do
		RequireModule(descendant, false)
	end
	if IsServer then
		Workspace:SetAttribute("ServerInitialized", true)
	end
	if not IsServer then
		ModuleDirectory.DescendantAdded:Connect(function(descendant: ModuleScript)
			RequireModule(descendant, true)
			RequireModule(descendant, false)
		end)
	end
end

return init
