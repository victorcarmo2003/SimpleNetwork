--!strict
local Types = require(script.Types)
local SimpleNetwork = {}
SimpleNetwork._serverHandlers = {} :: {[string]: {Types.Handler}}
SimpleNetwork._clientHandlers = {} :: {[string]:{Types.Handler}}
SimpleNetwork._localHandlers = {} :: {[string]:{Types.Handler}}
SimpleNetwork._serverLoaded = false
SimpleNetwork._clientLoaded = false
SimpleNetwork._topConsumers = {}
SimpleNetwork._consumers = {}

SimpleNetwork._settings = {
	bandwithAlert = true,
	bandwithLimit = 1000,
	rateLimit = 60,
	menuEnabled = true,
	showMenuBind = Enum.KeyCode.F8,
	showMenuCommand = "/network"
}

local RemoteEvent: RemoteEvent
local RemoteFunction: RemoteFunction
local UnreliableEvent: UnreliableRemoteEvent
local BindableEvent: BindableEvent

--> SERVICES
local HttpService = game:GetService("HttpService")
local Bridge = require(script.Bytes.Bridge)
local types = require(script.Types)
local Batch = require(script.Bytes.Batch)
SimpleNetwork.RegisterEvent = Bridge.RegisterEvent

--> AUXILIAR FUNCTIONS
local function validateContext(Context: "Server"|"Client"?) : boolean|string
	local getContext = require(script.Utils.Context)
	return getContext(Context)
end

local function instanceEvents()
	local events = require(script.Utils.Events)()
	RemoteEvent = events.RemoteEvent
	RemoteFunction = events.RemoteFunction
	UnreliableEvent = events.UnreliableEvent
end

local function checkServerLoaded()
	if not validateContext("Client") then
		return warn(`[SimpleNetwork] This must be called from the client-side`)
	end
	return RemoteFunction:InvokeServer("SP_ServerLoaded")
end

local function createHandler(handlers: {Types.Handler}, Handler)
	local Handler = require(script.Utils.Handler)
	return Handler(handlers, Handler)
end

local function loadEvents()
	if not validateContext("Client") then
		return
	end
	local folder = script:FindFirstChild("SP_EVENTS") :: Folder
	RemoteEvent = folder:WaitForChild("SP_RemoteEvent") :: RemoteEvent
	RemoteFunction = folder:WaitForChild("SP_RemoteFunction") :: RemoteFunction
	UnreliableEvent = folder:WaitForChild("SP_UnrealiableEvent") :: UnreliableRemoteEvent
end

local function ProcessEvents()
	local decode = require(script.Bytes.Decode)
	local context = validateContext()
	if context == "Client" then
		RemoteEvent.OnClientEvent:Connect(function(payload:buffer)
			decode.Process(SimpleNetwork._clientHandlers, payload, false)
		end)
		
		UnreliableEvent.OnClientEvent:Connect(function(payload:buffer)
			decode.Process(SimpleNetwork._clientHandlers, payload, false)
		end)
		
		RemoteFunction.OnClientInvoke = function(payload:buffer)
			warn(payload)
			return decode.Process(SimpleNetwork._clientHandlers, payload, false)
		end
		
	elseif context == "Server" then
		RemoteEvent.OnServerEvent:Connect(function(Player, payload:buffer)
			decode.Process(SimpleNetwork._serverHandlers, payload, false, Player)
		end)
		
		UnreliableEvent.OnServerEvent:Connect(function(Player, payload:buffer)
			warn(payload)
			decode.Process(SimpleNetwork._serverHandlers, payload, false, Player)
		end)

		RemoteFunction.OnServerInvoke = function(Player, payload:buffer)
			warn(payload)
			return decode.Process(SimpleNetwork._serverHandlers, payload, false, Player)
		end
	end
end

local function getSchema(Handler: string)
	return Bridge.Events[Handler] or nil
end

-- ======================================================
--					UNRELIABLE EVENTS
-- ======================================================

function SimpleNetwork.FastFireClient(Player: Player, Handler: string,...)
	if not validateContext("Server") then
		error(`[SimpleNetwork] - FastFireClient must be called from server-side`)
	end
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("UnreliableEvent", schema,...)
end

function SimpleNetwork.FastFireServer(Handler: string,...)
	if not validateContext("Client") then
		error(`[SimpleNetwork] - FastFireClient must be called from client-side`)
	end
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("UnreliableEvent", schema,...)
end

-- ======================================================
--					REMOTE EVENTS
-- ======================================================

function SimpleNetwork.FireServer(Handler: string,...)
	if not validateContext("Client") then
		error(`[SimpleNetwork] - FireServer must be called from client-side`)
	end
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("RemoteEvent", Handler, schema, nil, ...)
end

function SimpleNetwork.FireClient(Player: Player, Handler: string, ...)
	if not validateContext("Server") then
		error(`[SimpleNetwork] - FireClient must be called from server-side`)
	end
	local schema = getSchema(Handler)
	local target: Types.PackageTarget = {
		Type = "Client",
		Player = Player
	}
	Bridge.ProcessPackage("RemoteEvent", Handler, schema, target, ...)
end

function SimpleNetwork.FireAllClients(Handler: string, ...)
	if not validateContext("Server") then
		error(`[SimpleNetwork] - FireAllClients must be called from server-side`)
	end
	local schema = getSchema(Handler)
	local target: Types.PackageTarget = {
		Type = "All"
	}
	Bridge.ProcessPackage("RemoteEvent", Handler, schema, target, ...)
end

function SimpleNetwork.FireGroup(Handler: string, Players: {Player}, ...)
	if not validateContext("Server") then
		error(`[SimpleNetwork] - FireGroup must be called from server-side`)
	end
	local schema = getSchema(Handler)
	local target: Types.PackageTarget = {
		Type = "Group",
		Players = Players
	}
	Bridge.ProcessPackage("RemoteEvent", Handler, schema, target, ...)
end

function SimpleNetwork.FireExcept(Handler: string, Player: Player, ...)
	if not validateContext("Server") then
		error(`[SimpleNetwork] - FireExcept must be called from server-side`)
	end
	local schema = getSchema(Handler)
	local target: Types.PackageTarget = {
		Type = "Except",
		Player = Player
	}
	Bridge.ProcessPackage("RemoteEvent", Handler, schema, target, ...)
end

-- ======================================================
--					BINDABLE FUNCTIONS
-- ======================================================

function SimpleNetwork.FireLocal(Handler: string, ...)
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("LocalEvent",Handler ,schema,...)
end

function SimpleNetwork.RequestLocal(Handler: string, ...) : any
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("LocalFunction",Handler ,schema,...)
	return
end

-- ======================================================
--					REMOTE FUNCTIONS
-- ======================================================
function SimpleNetwork.RequestServer(Handler: string, ...) : any
	if not validateContext("Client") then
		error(`[SimpleNetwork] - RequestServer must be called from client-side`)
	end
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("RemoteFunction",Handler ,schema,...)
	return
end

function SimpleNetwork.RequestClient(Player: Player, Handler: string, ...) : any
	if not validateContext("Server") then
		error(`[SimpleNetwork] - RequestClient must be called from server-side`)
	end
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("RemoteFunction",Handler ,schema,...)
	return
end

-- ======================================================
--						HANDLERS
-- ======================================================
function SimpleNetwork.OnServer(Handler: string)
	if not validateContext("Server") then
		error(`[SimpleNetwork] - OnServer must be called from server-side`)
	end
	
	-- Registrar o evento automaticamente para garantir que o ID esteja mapeado
	if not Bridge.EventToID[Handler] then
		Bridge.RegisterEvent(Handler, {}) -- Schema vazio, será atualizado quando receber dados
	end
	
	if not SimpleNetwork._serverHandlers[Handler] then
		SimpleNetwork._serverHandlers[Handler] = {}
	end
	local handlers = SimpleNetwork._serverHandlers[Handler]
	return createHandler(handlers, Handler)
end

function SimpleNetwork.OnClient(Handler: string, bufferHandler: Types.bufferHandler?)
	if not validateContext("Client") then
		error(`[SimpleNetwork] - OnClient must be called from client-side`)
	end
	
	-- Registrar o evento automaticamente para garantir que o ID esteja mapeado
	if not Bridge.EventToID[Handler] then
		Bridge.RegisterEvent(Handler, {}) -- Schema vazio, será atualizado quando receber dados
	end
	
	if not SimpleNetwork._clientHandlers[Handler] then
		SimpleNetwork._clientHandlers[Handler] = {}
	end
	local handlers = SimpleNetwork._clientHandlers[Handler]
	return createHandler(handlers, Handler)
end

function SimpleNetwork.OnLocal(Handler: string)
	-- Registrar o evento automaticamente para garantir que o ID esteja mapeado
	if not Bridge.EventToID[Handler] then
		Bridge.RegisterEvent(Handler, {}) -- Schema vazio, será atualizado quando receber dados
	end
	
	if not SimpleNetwork._localHandlers[Handler] then
		SimpleNetwork._localHandlers[Handler] = {}
	end
	local handlers = SimpleNetwork._localHandlers[Handler]
	return createHandler(handlers, Handler)
end

-- ======================================================
--					MONITOR METHODS
-- ======================================================
function SimpleNetwork:SetBandwithLimit(kbps: number)
	SimpleNetwork._settings.bandwithLimit = kbps
end

-- ======================================================
--					START METHODS
-- ======================================================

function SimpleNetwork.StartServer()
	instanceEvents()
	ProcessEvents()
end

function SimpleNetwork.StartClient()
	loadEvents()
	ProcessEvents()
end

--> AUTO-START BY REQUIRE
do
	if validateContext("Client") then
		SimpleNetwork.StartClient()
	else
		SimpleNetwork.StartServer()
	end
end

return SimpleNetwork