--!strict
local Types = require(script.Parent.Types)

return function(handlers: {Types.Handler})
	return {
	Connect = function(self, Callback: (any) -> ())
		local connection = {
			Connected = true,
			Callback = Callback
		}

		table.insert(handlers, connection)
		return {
			Disconnect = function(self)
				connection.Connected = false
			end
		}
	end,
	Once = function(self,Callback: (any) -> ())
		local connection: Types.Handler = {
			Connected = true,
			Callback = function() end
		}

		local Disconnect = function(self)
			connection.Connected = false
		end

		local wrapper = function(...)
			Disconnect()
			Callback(...)
		end

		table.insert(handlers, connection)
		return {Disconnect = Disconnect}
	end}
end