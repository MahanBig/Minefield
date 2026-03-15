local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dataservice = require(ReplicatedStorage.Packages.dataservice).client
local promise = require(ReplicatedStorage.Packages.promise)

local IsServer = RunService:IsServer()
local RootDirectory = if IsServer then ServerScriptService.Server else ReplicatedStorage.Shared
local ModuleDirectory = if IsServer then RootDirectory.Services else RootDirectory:WaitForChild("Controllers")

local loadedModules = {}
local modulePromises = {}
local moduleStats = {}

local function isPromise(value)
	return type(value) == "table" and type(value.andThen) == "function"
end

local function trackModule(module)
	local moduleName = module.Name
	moduleStats[moduleName] = moduleStats[moduleName]
		or {
			module = module,
			onInit = 0,
			onStart = 0,
			onReady = 0,
			total = 0,
			skipped = false,
			error = nil,
		}
	moduleStats[moduleName].startedAt = os.clock()
	return moduleStats[moduleName]
end

local function RunLifecycleHook(module: ModuleScript, hookName: string, successWord: string, failWord: string)
	local moduleName = module.Name
	local stats = moduleStats[moduleName] or trackModule(module)

	return promise
		.try(function()
			local import = require(module)
			if type(import) ~= "table" then
				return true
			end

			local hook = import[hookName]
			if type(hook) ~= "function" then
				return true
			end

			local hookStart = os.clock()
			local hookResult = hook()
			local hookDuration = os.clock() - hookStart
			stats[hookName] = hookDuration

			local function logDone()
				print(("[✅] %s %s (%.4fs)"):format(moduleName, successWord, hookDuration))
				return true
			end

			if isPromise(hookResult) then
				return hookResult:andThen(logDone)
			end

			return logDone()
		end)
		:catch(function(err)
			local fallbackDuration = os.clock() - (stats.startedAt or os.clock())
			stats[hookName] = fallbackDuration
			stats.error = err
			warn(("[❌] %s Failed to %s (%.4fs)"):format(moduleName, failWord, fallbackDuration))
			warn(err)
			return promise.reject(err)
		end)
end

local function RequireModule(module: ModuleScript)
	if not module or not module:IsA("ModuleScript") then
		return promise.resolve()
	end

	if modulePromises[module] then
		return modulePromises[module]
	end

	local moduleName = module.Name
	local stats = trackModule(module)

	if module:GetAttribute("Enabled") == false then
		stats.skipped = true
		print(("[⏭] %s skipped (Enabled=false)"):format(moduleName))
		modulePromises[module] = promise.resolve({ name = moduleName, skipped = true })
		loadedModules[module] = true
		return modulePromises[module]
	end

	modulePromises[module] = RunLifecycleHook(module, "onInit", "Initialized", "initialize")
		:andThen(function()
			return RunLifecycleHook(module, "onStart", "Started", "start")
		end)
		:andThen(function()
			return RunLifecycleHook(module, "onReady", "Ready", "ready")
		end)
		:andThen(function()
			stats.total = os.clock() - (stats.startedAt or os.clock())
			loadedModules[module] = true
			print(("[⏱] %s loaded in %.4fs"):format(moduleName, stats.total))
			return { name = moduleName, stats = stats }
		end)
		:catch(function(err)
			stats.error = err
			warn(("[❌] %s failed during lifecycle: %s"):format(moduleName, tostring(err)))
			return promise.reject(err)
		end)

	return modulePromises[module]
end

local function getModuleStats()
	return moduleStats
end

local function init()
	local initStart = os.clock()
	if not IsServer and Workspace:GetAttribute("ServerInitialized") ~= true then
		dataservice:waitForData()
		Workspace:GetAttributeChangedSignal("ServerInitialized"):Wait()
	end

	local modulePromiseList = {}
	for _, descendant in ModuleDirectory:GetDescendants() do
		if descendant:IsA("ModuleScript") then
			table.insert(modulePromiseList, RequireModule(descendant))
		end
	end

	if IsServer then
		Workspace:SetAttribute("ServerInitialized", true)
	end

	if not IsServer then
		ModuleDirectory.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("ModuleScript") then
				RequireModule(descendant):catch(function(err)
					warn(("Dynamic module %s failed: %s"):format(descendant.Name, tostring(err)))
				end)
			end
		end)
	end

	return promise.all(modulePromiseList):andThen(function(results)
		local initTime = os.clock() - initStart
		print(("[✅] ModuleLoader init completed (modules: %d, elapsed: %.4fs)"):format(#modulePromiseList, initTime))
		return { results = results, stats = moduleStats }
	end)
end

local ModuleLoader = {
	init = init,
	getModuleStats = getModuleStats,
	requireModule = RequireModule,
}

setmetatable(ModuleLoader, {
	__call = function(_, ...)
		return init(...)
	end,
})

return ModuleLoader
