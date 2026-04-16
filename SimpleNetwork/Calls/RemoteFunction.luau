local calls = script.Parent
local utils = calls.Parent.Utils
local Context = require(utils.Context)

return function(buffer: buffer)
	warn(buffer)
	local e = require(script.Parent.Parent.Utils.Events)()
	if Context("Client") then
		e.RemoteEvent:FireServer(buffer)
	else
		e.RemoteEvent:FireAllClients(buffer)
	end
end