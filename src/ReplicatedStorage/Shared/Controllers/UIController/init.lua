local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local UIAssets = Assets:WaitForChild("UI")

local MainGui = PlayerGui:FindFirstChild("Main")

if not MainGui then
	local mainGuiTemplate = UIAssets:WaitForChild("Main")

	MainGui = mainGuiTemplate:Clone()
	MainGui.ResetOnSpawn = false
	MainGui.Parent = PlayerGui
end

local Shared = {}

Shared.Guis = {
	DebugUI = MainGui:WaitForChild("DebugUI"),
}

return Shared
