--!strict
return function (Context: "Server"|"Client"?) : boolean|string
	local RunService = game:GetService("RunService")
	local RunContext = RunService:IsClient() and "Client" or "Server"
	if Context then
		if RunContext == Context then
			return true
		else
			return false
		end
	else
		return RunContext
	end
end