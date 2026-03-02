local ReplicatedStorage = game:GetService("ReplicatedStorage")
local satchel = {}
function satchel.onStart()
	local _satchel = require(ReplicatedStorage.Packages.satchel)
end
return satchel
