--!strict
--!optimize 2
local Bridge = {}
Bridge.Events = {}
Bridge.EventToID = {} :: {[string]: number}
Bridge.IDToEvent = {} :: {[number]: string}
Bridge.NextID = 1
Bridge.NextRequestID = 0
Bridge.OnPackageSent = nil :: ((eventName: string, bytes: number) -> ())? -- Callback para rastreamento
Bridge.OutQueue = {
	RemoteEvent = {},
	RemoteFunction = {},
	UnreliableEvent = {},
	LocalEvent = {},
	LocalFuncton = {},
} :: {[types.EventName]: {{ID: number, Schema: {types.byteCodes}, Args: {any}, Size: number, Target: types.PackageTarget?}}}

local bytes = script.Parent
local types = require(bytes.Parent.Types)

-- Serializador para cálculo de tamanho (mesma lógica do Book)
local function serializeValue(value: any): any
	local valueType = typeof(value)
	
	if valueType == "CFrame" then
		return {
			__type = "CFrame",
			data = {value:GetComponents()}
		}
	elseif valueType == "Vector3" then
		return {
			__type = "Vector3",
			data = {value.X, value.Y, value.Z}
		}
	elseif valueType == "Vector2" then
		return {
			__type = "Vector2",
			data = {value.X, value.Y}
		}
	elseif valueType == "UDim2" then
		return {
			__type = "UDim2",
			data = {value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset}
		}
	elseif valueType == "table" then
		local serialized = {}
		for k, v in pairs(value) do
			serialized[k] = serializeValue(v)
		end
		return serialized
	else
		return value
	end
end

Bridge.EventType = {
	RemoteEvent = 0,
	RemoteFunction = 1,
	UnrealiableEvent = 0,
	LocalEvent = 0,
	LocalFunction = 1,
} -- 1 (two-way) | 0 (one-way)

Bridge.TypeToByte = {
	["u8"] = 1, ["u16"] = 2, ["u32"] = 3,
	["i8"] = 4, ["i16"] = 5, ["i32"] = 6,
	["f32"] = 7, ["string"] = 8, ["v3"] = 9,
	["v2"] = 10, ["cf"] = 11, ["ud2"] = 12,
	["bool"] = 13, ["table"] = 14
}

Bridge.ByteToSize = {
	[1] = 1, [2] = 2, [3] = 4, -- Naturals
	[4] = 1, [5] = 2, [6] = 4, -- Integers
	[7] = 4,                   -- Float
	[9] = 12,                  -- Vector3 (3x f32)
	[10] = 8,                  -- Vector2 (2x f32)
	[11] = 24,                 -- CFrame (6x f32)
	[12] = 16,                 -- CFrame (4x f32)
	[13] = 1                   -- Boolean
}
local function hashEventName(name: string): number
	local hash = 0
	for i = 1, #name do
		hash = (hash * 31 + string.byte(name, i)) % 255
	end
	return hash == 0 and 1 or hash
end

function Bridge.CalculateSize(schema: {string}, args: {any}): number
	local size = 0
	if #schema == 0 then
		return 4 -- Header mínimo: ID (1) + tipo marcador vazio (1) + size (2)
	end
	
	for i, typeName in ipairs(schema) do
		size += 4 -- HEADER: ID+TYPE+LENGTH
		local bytes = Bridge.TypeToByte[typeName]
		if not bytes then
			warn(`[SimpleNetwork - Bridge] What is this format? {typeName}`)
		end
		local fixedSize = Bridge.ByteToSize[bytes]
		if fixedSize then
			size += fixedSize
		elseif typeName == "string" then
			size += #tostring(args[i] or "")
		elseif typeName == "table" then
			local HttpService = game:GetService("HttpService")
			local serialized = serializeValue(args[i] or {})
			local json = HttpService:JSONEncode(serialized)
			size += #json
		end
	end
	return size
end

function Bridge.RegisterEvent(Name: string, Schema: {string})
	local ID = hashEventName(Name)
	if Bridge.EventToID[Name] and Bridge.EventToID[Name] ~= ID then
		warn(`[SimpleNetwork - Bridge] Hash collision for event '{Name}'! This should be very rare.`)
	end
	Bridge.Events[Name] = Schema
	Bridge.EventToID[Name] = ID
	Bridge.IDToEvent[ID] = Name
end

function Bridge.ProcessPackage(EventType: types.EventName, EventName: string, Schema: {string}?, Target: types.PackageTarget?, ...)
	local args = {...}
	
	if not Schema or type(Schema) ~= "table" or #Schema == 0 then
		Schema = {}
		local argCount = select("#", ...)
		for i = 1, argCount do
			local param = select(i, ...)
			if typeof(param) == "number" then
				if param % 1 ~= 0 then Schema[i] = "f32"
				else
					if param >= 0 and param <= 255 then
						Schema[i] = "u8"
					elseif param <= 65535 then
						Schema[i] = "u16"
					elseif param <= 4294967295 then
						Schema[i] = "u32"
					end
				end
			end
			if typeof(param) == "string" then
				Schema[i] = "string"
			end
			if typeof(param) == "Vector3" then
				Schema[i] = "v3"
			end
			if typeof(param) == "Vector2" then
				Schema[i] = "v2"
			end
			if typeof(param) == "CFrame" then
				Schema[i] = "cf"
			end
			if typeof(param) == "UDim2" then
				Schema[i] = "ud2"
			end
			if typeof(param) == "boolean" then
				Schema[i] = "bool"
			end
			if typeof(param) == "table" then
				Schema[i] = "table"
			end
		end
		Bridge.RegisterEvent(EventName, Schema)
	end
	
	local id = Bridge.EventToID[EventName]
	if not id then 
		error(`[SimpleNetwork - Bridge] Event {EventName} not registered!`) 
	end
	
	local isFunction = Bridge.EventType[EventName] == 1
	local args = table.pack(...)
	
	if isFunction then
		Bridge.NextRequestID += 1
		if Bridge.NextRequestID >= 4294967296 then
			Bridge.NextRequestID = 1
		end
		table.insert(args,1, Bridge.NextRequestID)
		table.insert(Schema :: {any}, 1, "u32")
	end
	
	local size = Bridge.CalculateSize(Schema :: {string}, args)
	
	-- Rastrear para monitoring
	if Bridge.OnPackageSent then
		Bridge.OnPackageSent(EventName, size)
	end
	
	if not Bridge.OutQueue[EventType] then
		Bridge.OutQueue[EventType] = {}
	end
	local event = {
		ID = id :: number,
		Schema = Schema :: {types.byteCodes}, 
		Args = args :: {any},
		Size = size :: number,
		Target = Target :: types.PackageTarget?}
	table.insert(Bridge.OutQueue[EventType],event :: any)
end

return Bridge