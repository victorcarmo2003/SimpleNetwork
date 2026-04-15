--!strict
return function (Player:Player?, payload: buffer)
	local context = validateContext()
	local handlers
	if context == "Client" then
		handlers = SimpleNetwork._clientHandlers[Handler]
	else
		handlers = SimpleNetwork._serverHandlers[Handler]
	end
	if not handlers then
		warn(`[SimpleNetwork] Handler not registered: {Handler}`)
		return
	end
	for _, listener in handlers:: {[string]: any} do
		if listener.Connected then
			local success, msg
			if Player and Player:IsA("Player") then
				success, msg = pcall(listener.Callback,Player, ...)
			else
				success, msg = pcall(listener.Callback, ...)
			end
			if not success then
				warn(msg)
			end
		end
	end
end