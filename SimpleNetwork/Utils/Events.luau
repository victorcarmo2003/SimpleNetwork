--!strict
return function ()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local utils = script.Parent
	local simpleNetwork = utils.Parent
	local folder = simpleNetwork:FindFirstChild("SP_EVENTS") :: Folder

	local RemoteEvent
	local RemoteFunction
	local UnreliableEvent
	local BindableEvent
	
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SP_EVENTS"
		folder.Parent = simpleNetwork

		RemoteEvent = Instance.new("RemoteEvent")
		RemoteFunction = Instance.new("RemoteFunction")
		UnreliableEvent = Instance.new("UnreliableRemoteEvent")

		RemoteEvent.Name = "SP_RemoteEvent"
		RemoteEvent.Parent = folder
		RemoteFunction.Name = "SP_RemoteFunction"
		RemoteFunction.Parent = folder
		UnreliableEvent.Name = "SP_UnrealiableEvent"
		UnreliableEvent.Parent = folder
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