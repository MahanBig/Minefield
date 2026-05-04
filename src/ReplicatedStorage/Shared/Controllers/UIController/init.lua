local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = nil
local MainGui = nil

local Shared = {}

function Shared:onInit()
	PlayerGui = Player:WaitForChild("PlayerGui")
	MainGui = PlayerGui:WaitForChild("MainGui")
	
	Shared.Guis = {
		DebugUI = MainGui:WaitForChild("DebugUI"),
	}
end



return Shared