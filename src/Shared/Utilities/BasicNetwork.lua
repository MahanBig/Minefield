local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local EncodingService = game:GetService("EncodingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local bufferize = require(ReplicatedStorage.Packages.bufferize)

local isClient = RunService:IsClient()
local isStudio = RunService:IsStudio()

-- DEFAULT SETTINGS
local COMPRESSION = true
local COMPRESSION_LEVEL = 3
local OBFUSCATE_NAME = true
local OBFUSCATE_NAME_IN_STUDIO = true

local remoteFolder: Folder

if isClient then
	remoteFolder = ReplicatedStorage:WaitForChild("Remotes")
else
	remoteFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage
end

local BasicNetwork = {}
BasicNetwork.__index = BasicNetwork

-- --- Obfuscation Helper ---
local function obfuscateName(input: string)
	if not OBFUSCATE_NAME then
		return input
	end
	if not OBFUSCATE_NAME_IN_STUDIO and isStudio then
		return input
	end
	local hash = 0
	local handshake = remoteFolder:GetAttribute("Handshake")
	local constructedInput = handshake .. input
	for i = 1, #constructedInput do
		hash = (hash * 31 + string.byte(constructedInput, i)) % 2 ^ 32
	end
	return "Basic_" .. string.format("%X", hash)
end

-- --- Helper Methods ---

function BasicNetwork:_processOutgoing(...: any): buffer?
	if not self.compress then
		return ...
	end
	local bufferredArgs = bufferize.encode(...)

	return EncodingService:CompressBuffer(bufferredArgs, Enum.CompressionAlgorithm.Zstd, COMPRESSION_LEVEL)
end

function BasicNetwork:_processIncoming(data: buffer?): any
	if not self.compress then
		return data
	end
	local finalBuffer = data

	finalBuffer = EncodingService:DecompressBuffer(data, Enum.CompressionAlgorithm.Zstd)

	return bufferize.decode(finalBuffer)
end

function BasicNetwork:_findOrCreate(name: string, className: string): Instance
	local existing = remoteFolder:FindFirstChild(name)
	if existing then
		return existing
	end

	local newInstance = Instance.new(className)
	newInstance.Name = name
	newInstance.Parent = remoteFolder
	return newInstance
end

-- --- Constructor ---

function BasicNetwork.new(eventName: string, isFunction: boolean?, compress: boolean?, isUnreliable: boolean?)
	local self = setmetatable({}, BasicNetwork)
	self.compress = if compress ~= nil then compress else COMPRESSION

	if not isClient and not remoteFolder:GetAttribute("Handshake") then
		remoteFolder:SetAttribute("Handshake", HttpService:GenerateGUID(false))
	end

	local realName = obfuscateName(eventName)
	local className = if isFunction
		then "RemoteFunction"
		elseif isUnreliable then "UnreliableRemoteEvent"
		else "RemoteEvent"

	if isClient then
		self.instance = remoteFolder:WaitForChild(realName)
	else
		self.instance = self:_findOrCreate(realName, className)
	end

	return self
end

-- --- REMOTE EVENT METHODS ---

function BasicNetwork:FireServer(...)
	self.instance:FireServer(self:_processOutgoing(...))
end

function BasicNetwork:FireClient(player: Player, ...)
	self.instance:FireClient(player, self:_processOutgoing(...))
end

function BasicNetwork:FireAllClients(...)
	self.instance:FireAllClients(self:_processOutgoing(...))
end

function BasicNetwork:FireClientsExcept(players: { Player }, ...)
	if typeof(players) ~= "table" then
		players = { players }
	end
	local data = self:_processOutgoing(...)
	for _, player in Players:GetPlayers() do
		if table.find(players, player) then
			continue
		end
		self.instance:FireClient(player, data)
	end
end

function BasicNetwork:Connect(callback)
	if isClient then
		self.instance.OnClientEvent:Connect(function(data: buffer)
			callback(self:_processIncoming(data))
		end)
	else
		self.instance.OnServerEvent:Connect(function(player: Player, data: buffer)
			callback(player, self:_processIncoming(data))
		end)
	end
end

-- --- REMOTE FUNCTION METHODS ---

function BasicNetwork:InvokeServer(...)
	local resultData = self.instance:InvokeServer(self:_processOutgoing(...))
	return self:_processIncoming(resultData)
end

function BasicNetwork:OnServerInvoke(callback)
	self.instance.OnServerInvoke = function(player: Player, data: buffer)
		local args = table.pack(self:_processIncoming(data))
		local result = table.pack(callback(player, table.unpack(args)))
		return self:_processOutgoing(table.unpack(result))
	end
end

return BasicNetwork
