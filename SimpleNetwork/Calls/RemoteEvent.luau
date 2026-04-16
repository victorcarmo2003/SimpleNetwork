local calls = script.Parent
local utils = calls.Parent.Utils
local Context = require(utils.Context)
local types = require(calls.Parent.Types)

return function(buffer: buffer, target: types.PackageTarget?)
	local e = require(script.Parent.Parent.Utils.Events)()
	
	if Context("Client") then
		-- Cliente sempre envia para o servidor
		e.RemoteEvent:FireServer(buffer)
	else
		-- Servidor decide baseado no target
		if not target or target.Type == "All" then
			e.RemoteEvent:FireAllClients(buffer)
		elseif target.Type == "Client" and target.Player then
			e.RemoteEvent:FireClient(target.Player, buffer)
		elseif target.Type == "Group" and target.Players then
			for _, player in target.Players do
				e.RemoteEvent:FireClient(player, buffer)
			end
		elseif target.Type == "Except" and target.Player then
			for _, player in game.Players:GetPlayers() do
				if player ~= target.Player then
					e.RemoteEvent:FireClient(player, buffer)
				end
			end
		end
	end
end