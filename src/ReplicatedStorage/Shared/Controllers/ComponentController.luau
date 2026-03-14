local ComponentController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ComponentLoader = require(ReplicatedStorage.Shared.Utilities.ComponentLoader)
local componentDirectory = ReplicatedStorage.Shared.Components

function ComponentController:onStart()
	ComponentLoader.load(componentDirectory)
end

return ComponentController
