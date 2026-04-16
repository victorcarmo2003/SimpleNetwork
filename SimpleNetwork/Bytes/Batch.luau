--!strict
local Batch = {}
Batch.pendingBuffers = {
	RemoteEvent = {},
	RemoteFunction = {},
	UnreliableEvent = {},
	LocalEvent = {},
	LocalFuncton = {},
} :: {[types.EventName]: {{buffer: buffer, target: types.PackageTarget?}}}
local RunService = game:GetService("RunService")
local Bridge = require(script.Parent.Bridge)
local Book = require(script.Parent.Book)
local Cursor = require(script.Parent.Cursor)

local Bytes = script.Parent
local Call = Bytes.Parent.Calls
local types = require(Bytes.Parent.Types)

function Batch.FireEvents()
	local events = {
		RemoteEvent = require(Call.RemoteEvent),
		RemoteFunction = require(Call.RemoteFunction),
		UnreliableEvent = require(Call.UnreliableEvent),
		LocalEvent = require(Call.LocalFunction),
		LocalFunction = require(Call.LocalEvent),
	} :: {[types.EventName]: (any, any) -> (any)}
	
	for name, bufferTable in Batch.pendingBuffers do
		for i, pendingData in bufferTable do
			if events[name] then
				events[name](pendingData.buffer, pendingData.target)
			end
		end
		Batch.pendingBuffers[name] = {}
	end
end

function Batch.CreateBuffer(Handler: types.EventName, Size: number, Target: types.PackageTarget?)
	local newBuffer = buffer.create(Size)
	if not Batch.pendingBuffers[Handler] then
		Batch.pendingBuffers[Handler] = {}
	end
	table.insert(Batch.pendingBuffers[Handler], {buffer = newBuffer, target = Target})
	return Cursor.Get(newBuffer)
end

function Batch.StartQueue()
	local allPayloads = Bridge.OutQueue
	for eventName, queue in allPayloads do
		if #queue == 0 then continue end
		local groupedByTarget = {}
		for _, payload in queue do
			local targetKey = "default"
			if payload.Target then
				if payload.Target.Type == "Client" and payload.Target.Player then
					targetKey = `Client_{payload.Target.Player.UserId}`
				elseif payload.Target.Type == "Group" and payload.Target.Players then
					local playerIds = {}
					for _, p in payload.Target.Players do
						table.insert(playerIds, p.UserId)
					end
					table.sort(playerIds)
					targetKey = `Group_{table.concat(playerIds, "_")}`
				elseif payload.Target.Type == "Except" and payload.Target.Player then
					targetKey = `Except_{payload.Target.Player.UserId}`
				else
					targetKey = payload.Target.Type
				end
			else
			end
			
			if not groupedByTarget[targetKey] then
				groupedByTarget[targetKey] = {payloads = {}, target = payload.Target}
			end
			table.insert(groupedByTarget[targetKey].payloads, payload)
		end
		for targetKey, group in groupedByTarget do
			local totalSize = 0
			for _, payload in group.payloads do
				totalSize += payload.Size
			end
			local newCursor = Batch.CreateBuffer(eventName, totalSize, group.target)
			for _, payload in group.payloads do
				if #payload.Schema == 0 then
					newCursor:writeU8(payload.ID)  -- [ID EVENT]
					newCursor:writeU8(0)           -- [TIPO 0 = evento vazio]
					newCursor:writeU16(0)          -- [SIZE 0]
				else
					for i, typeName in payload.Schema do
						local value = payload.Args[i]
						local writer = Book.Writers[typeName]
						local byteType = Bridge.TypeToByte[typeName]
						local dataSize = Bridge.ByteToSize[byteType]
						newCursor:writeU8(payload.ID) -- [ID EVENT]
						newCursor:writeU8(byteType)   -- [ID BYTE TYPE]
						if dataSize then -- Not a string
							newCursor:writeU16(dataSize)       -- [DATA SIZE]
						end
						
						if writer then
							writer(newCursor, value)  -- [DATA]
						else
							warn(`[SimpleNetwork - Batch] No writer for type {typeName}`)
						end
					end
				end
			end
			newCursor:Release()
		end
		Bridge.OutQueue[eventName] = {}
	end
end

do
	RunService.Heartbeat:Connect(function()
		Batch.StartQueue()
		Batch.FireEvents()
	end)
end

return Batch
