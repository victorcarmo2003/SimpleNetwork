local Decode = {}

local bytes = script.Parent
local cursor = require(bytes.Cursor)
local bridge = require(bytes.Bridge)
local book = require(bytes.Book)
local types = require(bytes.Parent.Types)
local argumentsByEvents = {} -- { [id] = {val1, val2, ...} }

local function getTypeName(typeByte) : types.byteCodes
	for byteType, id in bridge.TypeToByte do
		if id == typeByte then
			return byteType :: types.byteCodes
		end
	end
	error(`[SimpleNetwork - Decode] ByteType not founded for id {typeByte}`)
end

local function getEventName(id: number): string
	-- Primeiro tenta buscar direto no mapeamento ID->Nome
	if bridge.IDToEvent[id] then
		return bridge.IDToEvent[id]
	end
	
	-- Fallback: busca reversa (compatibilidade)
	for name, ID in bridge.EventToID do
		if id == ID then
			return name
		end
	end
	error(`[SimpleNetwork - Decode] Event not registered for id: {id}`)
end

function Decode.Process(handlers: any, payload: buffer, isFunction: boolean, extraArg: Player?)
	local c = cursor.Get(payload)
	local argsByID = {} :: {[number]: {any}}

	while c.readerOffset < buffer.len(payload) do
		local id = c:readU8()
		local typeByte = c:readU8()
		
		-- typeByte = 0 significa evento vazio (sem argumentos)
		if typeByte == 0 then
			c:readU16() -- Pular o size (sempre 0 para eventos vazios)
			if not argsByID[id] then argsByID[id] = {} end
			-- Não adiciona nenhum argumento, a tabela fica vazia
		else
			local typeName = getTypeName(typeByte)
			if bridge.ByteToSize[typeByte] then
				c:readU16()
			end
			local value = book.Readers[typeName](c)
			if not argsByID[id] then argsByID[id] = {} end
			table.insert(argsByID[id], value)
		end
	end

	local results = {}
	for id, args in argsByID do
		local name = getEventName(id)
		local handlerList = handlers[name]
		
		if not handlerList then
			warn(`[SimpleNetwork - Decode] No handlers registered for event: {name}`)
			continue
		end
		
		local callArgs = table.clone(args)
		if extraArg then table.insert(callArgs, 1, extraArg) end

		if isFunction then
			local reqID = table.remove(callArgs, 1)
			if handlerList[1] and handlerList[1].Handler then
				results[reqID] = handlerList[1].Handler.Callback(table.unpack(callArgs))
			end
		else
			for _, handlerWrapper in handlerList do
				if handlerWrapper.Handler and handlerWrapper.Handler.Connected then
					handlerWrapper.Handler.Callback(table.unpack(callArgs))
				end
			end
		end
	end

	c:Release()
	return isFunction and results or nil
end

return Decode

