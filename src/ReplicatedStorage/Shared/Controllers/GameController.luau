local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEvents = require(ReplicatedStorage.Shared.Utilities.GameEvents)

local UIController = require(script.Parent.UIController)

local GameController = {}

local function tweenTransparency(label: TextLabel, targetTransparency: number)
	TweenService:Create(label, TweenInfo.new(0.2), {
		TextTransparency = targetTransparency,
		TextStrokeTransparency = math.clamp(targetTransparency + 0.35, 0, 1),
	}):Play()
end

local function setRoundState(payload)
	local statusUi = UIController.Guis.StatusUI
	local progressUi = UIController.Guis.ProgressUI

	local title = statusUi:WaitForChild("Title") :: TextLabel
	local subtitle = statusUi:WaitForChild("Subtitle") :: TextLabel
	local announcement = statusUi:WaitForChild("Announcement") :: TextLabel
	local progress = progressUi:WaitForChild("Progress") :: TextLabel

	title.Text = payload.title or "Minefield"
	subtitle.Text = payload.subtitle or "Cross the field without getting blown up"
	progress.Text = payload.progress or "Reach the finish platform"

	if payload.announcement and payload.announcement ~= "" then
		announcement.Text = payload.announcement
		tweenTransparency(announcement, 0)
	else
		tweenTransparency(announcement, 1)
	end
end

function GameController.onStart()
	setRoundState({})

	GameEvents.RoundState:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end
		setRoundState(payload)
	end)

	GameEvents.Notification:Connect(function(message)
		if typeof(message) ~= "string" then
			return
		end

		local announcement = UIController.Guis.StatusUI:WaitForChild("Announcement") :: TextLabel
		announcement.Text = message
		tweenTransparency(announcement, 0)

		task.delay(2.5, function()
			if announcement.Text == message then
				tweenTransparency(announcement, 1)
			end
		end)
	end)

	GameEvents.Ragdoll:Connect(function(targetUserId, isRagdolled)
		local localPlayer = Players.LocalPlayer
		if targetUserId ~= localPlayer.UserId then
			return
		end

		local title = UIController.Guis.StatusUI:WaitForChild("Title") :: TextLabel
		if isRagdolled then
			title.Text = "Minefield - Recover"
		else
			title.Text = "Minefield"
		end
	end)
end

return GameController
