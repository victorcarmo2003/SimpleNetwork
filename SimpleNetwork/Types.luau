export type byteCodes = "u8" | "u16" | "u32"

export type bufferHandler = {
	[number]: byteCodes
}

export type EventName = "RemoteEvent" | "RemoteFunction" | "UnreliableEvent" | "LocalEvent" | "LocalFunction"

export type Handler = {
	Callback: (any) -> (),
	Connected: boolean,
}

export type Events = {
	RemoteEvent: RemoteEvent,
	RemoteFunction: RemoteFunction,
	BindableEvent: BindableEvent,
	UnreliableEvent: UnreliableRemoteEvent
}

export type settings = {
	rateLimit: number,
	bandwithLimit: number,
	bandwithAlert: boolean,
}
export type Disconnect = () -> ()

export type Connector = {
	Connect: () -> (),
	Once: () -> (),
}

return {}