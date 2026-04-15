--!strict
return function ()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local folder = ReplicatedStorage:FindFirstChild("SP_EVENTS")
	
	local RemoteEvent
	local RemoteFunction
	local UnreliableEvent
	local BindableEvent
	
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SP_EVENTS"

		RemoteEvent = Instance.new("RemoteEvent")
		RemoteFunction = Instance.new("RemoteFunction")
		UnreliableEvent = Instance.new("UnreliableRemoteEvent")

		RemoteEvent.Name = "SP_RemoteEvent"
		RemoteFunction.Name = "SP_RemoteFunction"
		UnreliableEvent.Name = "SP_UnrealiableEvent"
	else
		RemoteEvent = folder:FindFirstChildWhichIsA("RemoteEvent") or Instance.new("RemoteEvent")
		RemoteFunction = folder:FindFirstChildWhichIsA("RemoteFunction") or Instance.new("RemoteFunction")
		UnreliableEvent = folder:FindFirstChildWhichIsA("UnreliableRemoteEvent") or Instance.new("UnreliableRemoteEvent")
	end
	
	return {
		RemoteEvent = RemoteEvent,
		RemoteFunction = RemoteFunction,
		UnreliableEvent = UnreliableEvent,
	}
end