local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIController = require(script.Parent)

local DebugController = {}

local UPDATE_INTERVAL_FPS = 0.3

local function formatValue(value): string
	return `<b>{value}</b>`
end

function DebugController.onStart()
	local localPlayer = Players.LocalPlayer
	local debugUi = UIController.Guis.DebugUI

	local fpsLabel = debugUi:WaitForChild("FPS") :: TextLabel
	local pingLabel = debugUi:WaitForChild("Ping") :: TextLabel
	local physicsLabel = debugUi:WaitForChild("Physics") :: TextLabel
	local locationLabel = debugUi:WaitForChild("Location") :: TextLabel

	local timeElapsedFps = 0

	RunService.Heartbeat:Connect(function(deltaTime: number)
		timeElapsedFps += deltaTime

		if timeElapsedFps >= UPDATE_INTERVAL_FPS then
			local fps = math.round(1 / deltaTime)
			local ping = math.floor(localPlayer:GetNetworkPing() * 1000)
			local physicsFps = math.floor(workspace:GetRealPhysicsFPS())
			local location =
				`{ReplicatedStorage:GetAttribute("ServerRegion")}, {ReplicatedStorage:GetAttribute("ServerCountry")}`

			fpsLabel.Text = "FPS: " .. formatValue(fps)
			pingLabel.Text = "Ping: " .. formatValue(ping .. "ms")
			locationLabel.Text = "Location: " .. formatValue(location)
			physicsLabel.Text = "Physics: " .. formatValue(physicsFps)

			timeElapsedFps = 0
		end
	end)
end

return DebugController
