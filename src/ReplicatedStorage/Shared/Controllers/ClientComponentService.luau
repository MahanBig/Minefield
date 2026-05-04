local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComponentLoader = require(ReplicatedStorage.Shared.Utilities.ComponentLoader)

local ClientComponentService = {}

function ClientComponentService:onStart()
	ComponentLoader.load(script.Parent.ClientComponents)
end

return ClientComponentService
