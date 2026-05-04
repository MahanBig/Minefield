local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local anti_anthro = require(ReplicatedStorage.Packages["anti-anthro"])
local ModuleScript = {}

function ModuleScript.onStart()
    anti_anthro.HookToGame()

    Players.PlayerAdded:Connect(function(player:Player)
        player.CharacterAdded:Connect(function(character)
            print("loaded character for player:", player.Name)
        end)    
        task.wait(7)
        player:LoadCharacterAsync()
    end)
end


return ModuleScript