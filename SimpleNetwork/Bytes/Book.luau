--!strict
--!optimize 2
local cursor = require(script.Parent.Cursor)
local Book = {}

export type cursor = cursor.Cursor

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
}

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
}

function Book.Start(Amount: number?)
	cursor.new(Amount or 5)
end

return Book
