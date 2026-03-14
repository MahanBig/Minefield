local ComponentLoaderService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ComponentLoader = require(ReplicatedStorage.Shared.Utilities.ComponentLoader)

function ComponentLoaderService:onStart()
	ComponentLoader.load(ServerScriptService.Server.Components)
end
return ComponentLoaderService
