export type byteCodes = "u8" | "u16" | "u32" | "i8" | "i16" | "i32" | "f32" | "string" | "bool" | "v3" | "v2" | "cf" | "ud2" | "table"

export type bufferHandler = {
	[number]: byteCodes
}

export type EventName = "RemoteEvent" | "RemoteFunction" | "UnreliableEvent" | "LocalEvent" | "LocalFunction"

export type TargetType = "All" | "Client" | "Group" | "Except"

export type PackageTarget = {
	Type: TargetType,
	Player: Player?,
	Players: {Player}?
}

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