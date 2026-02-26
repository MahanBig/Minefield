local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CustomPCall = require(ReplicatedStorage.Shared.Utilities.CustomPCall)
local HttpService = game:GetService("HttpService")

local RegionService = {}

function RegionService.onStart()
	ReplicatedStorage:SetAttribute("ServerRegion", "N/A")
	ReplicatedStorage:SetAttribute("ServerCountry", "N/A")

	local success, result = CustomPCall(fetchRegion, 5)
	if success then
		ReplicatedStorage:SetAttribute("ServerRegion", result.region)
		ReplicatedStorage:SetAttribute("ServerCountry", result.country)
	end
end

function fetchRegion()
	local region = HttpService:GetAsync("https://ipinfo.io/json")
	region = HttpService:JSONDecode(region)
	return region
end

return RegionService
