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

local function createHandler(handlers: {Types.Handler})
	local Handler = require(script.Utils.Handler)
	return Handler(handlers)
end

local function callEventHandler(Handler: string, Player:Player?, ...)
	local callEvent = require(script.Call.CallEvent)
	callEvent(SimpleNetwork,Handler, Player,...)
end

local function callFunctionHandler(Handler: string, Player:Player?, ...) : any?
	local callFunction = require(script.Call.CallFunction)
	return callFunction(SimpleNetwork, Handler, Player, ...)
end

local function ProcessEvents()
	local context = validateContext()
	if context == "Client" then
		RemoteEvent.OnClientEvent:Connect(function(Handler:string, ...)
			callEventHandler(Handler,...)
		end)
		
		UnreliableEvent.OnClientEvent:Connect(function(Handler:string, ...)
			callEventHandler(Handler,...)
		end)
		
		RemoteFunction.OnClientInvoke = function(Handler:string, ...)
			return callFunctionHandler(Handler,...)
		end
		
	elseif context == "Server" then
		RemoteEvent.OnServerEvent:Connect(function(Player, Handler:string, ...)
			callEventHandler(Handler, Player,...)
		end)
		
		UnreliableEvent.OnServerEvent:Connect(function(Player, Handler:string, ...)
			callEventHandler(Handler, Player,...)
		end)

		RemoteFunction.OnServerInvoke = function(Player, Handler:string, ...)
			return callFunctionHandler(Handler, Player,...)
		end
	end
end

local function getSchema(Handler: string)
	return Bridge.Events[Handler] or nil
end

-- ======================================================
--					UNRELIABLE EVENTS
-- ======================================================
function SimpleNetwork.FastFireClient(Handler: string,...)
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("UnreliableEvent", schema,...)
end

function SimpleNetwork.FastFireServer(Handler: string,...)
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("UnreliableEvent", schema,...)
end

-- ======================================================
--					REMOTE EVENTS
-- ======================================================
function SimpleNetwork.FireServer(Handler: string,...)
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("RemoteEvent", schema,...)
end

function SimpleNetwork.FireClient(Handler: string, Player: Player, ...)
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("RemoteEvent", schema,...)
end

function SimpleNetwork.FireGroup(Handler: string, Player: Player, ...)
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("RemoteEvent", schema,...)
end

function SimpleNetwork.FireExcept(Handler: string, Player: Player, ...)
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("RemoteEvent", schema,...)
end

-- ======================================================
--					BINDABLE FUNCTIONS
-- ======================================================
function SimpleNetwork.FireLocal(Handler: string, ...)
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("LocalEvent", schema,...)
end

function SimpleNetwork.RequestLocal(Handler: string, ...) : any
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("LocalFunction", schema,...)
end

-- ======================================================
--					REMOTE FUNCTIONS
-- ======================================================
function SimpleNetwork.RequestServer(Handler: string, ...) : any
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("RemoteFunction", schema,...)
end

function SimpleNetwork.RequestClient(Handler: string,Player:Player, ...) : any
	local schema = getSchema(Handler)
	Bridge.ProcessPackage("RemoteFunction", schema,...)
end

-- ======================================================
--						HANDLERS
-- ======================================================
function SimpleNetwork.OnServer(Handler: string)
	local handlers = SimpleNetwork._serverHandlers[Handler]
	return createHandler(handlers)
end

--[[
Handles the event on clientside (works for RemoteEvent, RemoteFunction and Unreliable)
@param EventName: String, bufferHandler: Array
@return Connection

sheet:
u8 = 0-255
u16 = 0-65535
032 = 4.294.967.295
]]
function SimpleNetwork.OnClient(Handler: string, bufferHandler: Types.bufferHandler?)
	local handlers = SimpleNetwork._clientHandlers[Handler]
	return createHandler(handlers)
end

function SimpleNetwork.OnLocal(Handler: string)
	local handlers = SimpleNetwork._localHandlers[Handler]
	return createHandler(handlers)
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
	RemoteFunction.OnServerInvoke = function(player, format)
		if format == "SP_ServerLoaded" then
			return SimpleNetwork._serverLoaded
		end
		return
	end
	
end

function SimpleNetwork.StartClient()
	ProcessEvents()
	RemoteFunction.OnClientInvoke = function(format)
		if format == "SP_ClientLoaded" then
			return SimpleNetwork._clientLoaded
		end
		return
	end
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
