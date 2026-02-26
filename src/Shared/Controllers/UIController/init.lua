local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("Main")

local Shared = {}

Shared.Guis = {
	DebugUI = MainGui:WaitForChild("DebugUI"),
}

return Shared
