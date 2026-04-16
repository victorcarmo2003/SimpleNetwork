--!strict
--!optimize 2
local cursor = require(script.Parent.Cursor)
local bytes = script.Parent
local Types = require(bytes.Parent.Types)
local HttpService = game:GetService("HttpService")
local Book = {}

export type cursor = cursor.Cursor

-- Serializador customizado para tipos do Roblox
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

-- Deserializador customizado
local function deserializeValue(value: any): any
	if type(value) == "table" then
		if value.__type == "CFrame" then
			return CFrame.new(unpack(value.data))
		elseif value.__type == "Vector3" then
			return Vector3.new(unpack(value.data))
		elseif value.__type == "Vector2" then
			return Vector2.new(unpack(value.data))
		elseif value.__type == "UDim2" then
			return UDim2.new(unpack(value.data))
		else
			local deserialized = {}
			for k, v in pairs(value) do
				deserialized[k] = deserializeValue(v)
			end
			return deserialized
		end
	else
		return value
	end
end

Book.Writers = {
	-- NATURAL
	["u8"] = function(obj:cursor, v: number)
		obj:writeU8(v)
	end,
	["u16"] = function(obj:cursor, v: number)
		obj:writeU16(v)
	end,
	["u32"] = function(obj:cursor, v: number)
		obj:writeU32(v)
	end,

	-- INTEGER
	["i8"] = function(obj:cursor, v: number)
		obj:writeI8(v)
	end,
	["i16"] = function(obj:cursor, v: number)
		obj:writeI16(v)
	end,
	["i32"] = function(obj:cursor, v: number)
		obj:writeI32(v)
	end,

	-- FLOAT
	["f32"] = function(obj:cursor, v: number)
		obj:writeF32(v)
	end,

	-- STRINGS
	["string"] = function(obj:cursor, v: string)
		obj:writeString(v)
	end,

	-- BOOLEAN
	["bool"] = function(obj:cursor, v: boolean)
		obj:writeU8(v and 1 or 0)
	end,

	-- VECTORS
	["v3"] = function(obj:cursor, v: Vector3)
		obj:writeF32(v.X)
		obj:writeF32(v.Y)
		obj:writeF32(v.Z)
	end,

	["v2"] = function(obj:cursor, v: Vector2)
		obj:writeF32(v.X)
		obj:writeF32(v.Y)
	end,

	-- CFRAME
	["cf"] = function(obj:cursor, v: CFrame)
		obj:writeF32(v.Position.X)
		obj:writeF32(v.Position.Y)
		obj:writeF32(v.Position.Z)
		obj:writeF32(v.LookVector.X)
		obj:writeF32(v.LookVector.Y)
		obj:writeF32(v.LookVector.Z)
	end,

	-- UDIM
	["ud2"] = function(obj:cursor, v: UDim2)
		obj:writeF32(v.X.Scale)
		obj:writeF32(v.X.Offset)
		obj:writeF32(v.Y.Scale)
		obj:writeF32(v.Y.Offset)
	end,
	
	-- TABLE (serialized as JSON with Roblox types support)
	["table"] = function(obj:cursor, v: any)
		local serialized = serializeValue(v)
		local json = HttpService:JSONEncode(serialized)
		obj:writeString(json)
	end,
} :: {[Types.byteCodes]: (obj: cursor, v: any?) -> ()}

Book.Readers = {
	-- NATURAL
	["u8"] = function(obj:cursor)
		return obj:readU8()
	end,
	["u16"] = function(obj:cursor)
		return obj:readU16()
	end,
	["u32"] = function(obj:cursor)
		return obj:readU32()
	end,

	-- INTEGER
	["i8"] = function(obj:cursor)
		return obj:readI8()
	end,
	["i16"] = function(obj:cursor)
		return obj:readI16()
	end,
	["i32"] = function(obj:cursor)
		return obj:readI32()
	end,

	-- FLOAT
	["f32"] = function(obj:cursor)
		return obj:readF32()
	end,

	-- STRINGS
	["string"] = function(obj:cursor)
		return obj:readString() 
	end,

	-- BOOLEAN
	["bool"] = function(obj:cursor)
		return obj:readU8() == 1
	end,

	-- VECTORS
	["v3"] = function(obj:cursor)
		return Vector3.new(obj:readF32(), obj:readF32(), obj:readF32())
	end,

	["v2"] = function(obj:cursor)
		return Vector2.new(obj:readF32(), obj:readF32())
	end,

	-- CFRAME
	["cf"] = function(obj:cursor)
		local pos = Vector3.new(obj:readF32(), obj:readF32(), obj:readF32())
		local lv = Vector3.new(obj:readF32(), obj:readF32(), obj:readF32())
		return CFrame.lookAt(pos, pos + lv)
	end,

	-- UDIM
	["ud2"] = function(obj:cursor)
		return UDim2.new(obj:readF32(), obj:readF32(), obj:readF32(), obj:readF32())
	end,
	
	-- TABLE (deserialized from JSON with Roblox types support)
	["table"] = function(obj:cursor)
		local json = obj:readString()
		local decoded = HttpService:JSONDecode(json)
		return deserializeValue(decoded)
	end,
} :: {[Types.byteCodes]: (obj: cursor) -> (any)}

function Book.Start(Amount: number?)
	cursor.new(Amount or 5)
end

return Book
