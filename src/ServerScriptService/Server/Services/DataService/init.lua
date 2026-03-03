local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dataservice = require(ReplicatedStorage.Packages.dataservice).server
local Template = require(script.Template)

local module = {}

function module.onStart()
	dataservice:init({
		Template,
	})
end

return module
