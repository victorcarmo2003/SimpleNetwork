local Batch = {}
local RunService = game:GetService("RunService")
local Bridge = require(script.Parent.Bridge)

local Bytes = script.Parent
local Call = Bytes.Parent.Call
local types = require(Bytes.Parent.Types)

function Batch.FireEvents(EventName: types.EventName)
	local remoteEvent = require(Call.RemoteEvent)
	local remoteFunction = require(Call.RemoteFunction)
	local unreliableEvent = require(Call.UnreliableEvent)
	local localFunction = require(Call.LocalFunction)
	
	
	
end

function Batch.CreateBuffer()
	
end

function Batch.StartQueue()
	local payloads = Bridge.OutQueue
	
end

return Batch
