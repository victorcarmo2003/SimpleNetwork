local Bridge = {}
Bridge.Events = {}
Bridge.OutQueue = {
	RemoteEvent = {},
	RemoteFunction = {},
	UnreliableEvent = {},
	LocalEvent = {},
	LocalFuncton = {},
}

local bytes = script.Parent
local types = require(bytes.Parent.Types)

local TypeToByte = {
	["u8"] = 1, ["u16"] = 2, ["u32"] = 3,
	["i8"] = 4, ["i16"] = 5, ["i32"] = 6,
	["f32"] = 7, ["string"] = 8, ["v3"] = 9,
	["v2"] = 10, ["cf"] = 11, ["ud2"] = 12,
	["bool"] = 13
}

local ByteToSize = {
	[1] = 1, [2] = 2, [3] = 4, -- Naturals
	[4] = 1, [5] = 2, [6] = 4, -- Integers
	[7] = 4,                   -- Float
	[9] = 12,                  -- Vector3 (3x f32)
	[10] = 8,                  -- Vector2 (2x f32)
	[11] = 24,                 -- CFrame (6x f32)
	[12] = 16,                 -- CFrame (4x f32)
	[13] = 1                   -- Boolean
}

function Bridge.CalculateSize(schema: {string}, args: {any}): number
	local size = 1 -- i8 ID
	local bytes = 0
	for i, typeName in ipairs(schema) do
		local bytes = TypeToByte[typeName]
		if not bytes then
			warn(`[SimpleNetwork - Bridge] What is this format? {typeName}`)
		end
		local fixedSize = ByteToSize[bytes]
		if fixedSize then
			size += fixedSize
		elseif typeName == "string" then
			size += 2 + #tostring(args[i])
		end
	end
	return size
end

function Bridge.RegisterEvent(Name: string, Schema: {string})
	Bridge.Events[Name] = Schema
end

function Bridge.ProcessPackage(EventName: types.EventName, Schema: {string}?, ...)
		if not Schema or type(Schema) ~= "table" then
		Schema = {}
		local argCount = select("#", ...)
		for i = 1, argCount do
			local param = select(i, ...)
			if typeof(param) == "number" then
				if param % 1 ~= 0 then
					Schema[i] = "f32"
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
		end
	end
	local size = Bridge.CalculateSize(Schema :: {string}, ...)
	table.insert(Bridge.OutQueue,{Schema = Schema, Size = size})
end

return Bridge
