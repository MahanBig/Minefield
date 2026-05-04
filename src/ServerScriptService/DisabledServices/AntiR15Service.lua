local ReplicatedStorage = game:GetService("ReplicatedStorage")
local anti_anthro = require(ReplicatedStorage.Packages["anti-anthro"])
local ModuleScript = {}

function ModuleScript.onStart()
    anti_anthro.HookToGame()
    print("Ran AntiR15")
end

return ModuleScript