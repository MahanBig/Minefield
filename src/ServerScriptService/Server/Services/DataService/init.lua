local ServerScriptService = game:GetService("ServerScriptService")
local dataservice = require(ServerScriptService.Packages.dataservice).server
local Template = require(script.Template)

local module = {}

function module.onStart()
	dataservice:init({
		Template,
	})
end

return module
