--!strict
--!optimize 2
local storage: {any} = {}
local Cursor = {} :: Cursor
Cursor.__index = Cursor

type CursorInstance = {
	offset: number,
	readerOffset: number,
	_currentBuffer: buffer,
}

export type Cursor = CursorInstance & {
	__index: Cursor,
	new: (amount: number) -> (),
	Get: (b: buffer) -> Cursor,
	Release: (self: Cursor) -> (),
	writeU8: (self: Cursor, value: number) -> (),
	writeU16: (self: Cursor, value: number) -> (),
	writeU32: (self: Cursor, value: number) -> (),
	writeI8: (self: Cursor, value: number) -> (),
	writeI16: (self: Cursor, value: number) -> (),
	writeI32: (self: Cursor, value: number) -> (),
	writeF32: (self: Cursor, value: number) -> (),
	writeString: (self: Cursor, value: string) -> (),
	readU8: (self: Cursor) -> number,
	readU16: (self: Cursor) -> number,
	readU32: (self: Cursor) -> number,
	readI8: (self: Cursor) -> number,
	readI16: (self: Cursor) -> number,
	readI32: (self: Cursor) -> number,
	readF32: (self: Cursor) -> number,
	readString: (self: Cursor) -> string,
}

function Cursor.new(amount: number)
	for _ = 1, amount do
		local self = setmetatable({
			offset = 0,
			readerOffset = 0,
			_currentBuffer = (nil :: any) :: buffer,
		}, Cursor)
		table.insert(storage, self)
	end
end

function Cursor.Get(b: buffer): Cursor
	local cursorObj = table.remove(storage)

	if not cursorObj then
		cursorObj = setmetatable({
			offset = 0,
			readerOffset = 0,
			_currentBuffer = b,
		}, Cursor)
	else
		cursorObj.offset = 0
		cursorObj.readerOffset = 0
		cursorObj._currentBuffer = b
	end

	return cursorObj :: any
end

function Cursor:Release()
	self._currentBuffer = (nil :: any) :: buffer
	table.insert(storage, self)
end

--  ====================================
--			NATURAL NUMBERS
--  ====================================

function Cursor:writeU8(value: number)
	buffer.writeu8(self._currentBuffer, self.offset, value)
	self.offset += 1
end

function Cursor:writeU16(value: number)
	buffer.writeu16(self._currentBuffer, self.offset, value)
	self.offset += 2
end

function Cursor:writeU32(value: number)
	buffer.writeu32(self._currentBuffer, self.offset, value)
	self.offset += 4
end

--  ====================================
--			INTEGER NUMBERS
--  ====================================

function Cursor:writeI8(value: number)
	buffer.writei8(self._currentBuffer, self.offset, value)
	self.offset += 1
end

function Cursor:writeI16(value: number)
	buffer.writei16(self._currentBuffer, self.offset, value)
	self.offset += 2
end

function Cursor:writeI32(value: number)
	buffer.writei32(self._currentBuffer, self.offset, value)
	self.offset += 4
end

--  ====================================
--			FLOAT NUMBERS
--  ====================================

function Cursor:writeF32(value: number)
	buffer.writef32(self._currentBuffer, self.offset, value)
	self.offset += 4
end

function Cursor:readF32(): number
	local value = buffer.readf32(self._currentBuffer, self.readerOffset)
	self.readerOffset += 4
	return value
end

--  ====================================
--			STRING VALUES
--  ====================================

function Cursor:writeString(value: string)
	local safeValue = tostring(value or "")
	local stringSize = #safeValue
	self:writeU16(stringSize)
	buffer.writestring(self._currentBuffer, self.offset, value or "", stringSize)
	self.offset += stringSize
end

function Cursor:readString(): string
	local stringSize = self:readU16()
	local message = buffer.readstring(self._currentBuffer, self.readerOffset, stringSize)
	self.readerOffset += stringSize
	return message
end

--  ====================================
--			READERS U8
--  ====================================

function Cursor:readU8(): number
	local value = buffer.readu8(self._currentBuffer, self.readerOffset)
	self.readerOffset += 1
	return value
end

function Cursor:readU16(): number
	local value = buffer.readu16(self._currentBuffer, self.readerOffset)
	self.readerOffset += 2
	return value
end

function Cursor:readU32(): number
	local value = buffer.readu32(self._currentBuffer, self.readerOffset)
	self.readerOffset += 4
	return value
end

--  ====================================
--			READERS I8
--  ====================================

function Cursor:readI8(): number
	local value = buffer.readi8(self._currentBuffer, self.readerOffset)
	self.readerOffset += 1
	return value
end

function Cursor:readI16(): number
	local value = buffer.readi16(self._currentBuffer, self.readerOffset)
	self.readerOffset += 2
	return value
end

function Cursor:readI32(): number
	local value = buffer.readi32(self._currentBuffer, self.readerOffset)
	self.readerOffset += 4
	return value
end

return Cursor
