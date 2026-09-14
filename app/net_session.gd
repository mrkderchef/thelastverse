class_name NetSession
extends Node
## Two-player co-op over ENet. The host owns the run: it saves, applies every puzzle action and
## sends the whole state to its companion after each change. The companion walks its own camera
## through the same act, asks the host to perform its interactions, and sees the results.
## Both see each other as a traveller figure. Only one puzzle piece is carried at a time, by
## whichever player picked it up.

signal companion_joined
signal companion_left
signal connected_to_host
signal connection_failed

const PORT := 24613
const SEND_RATE := 1.0 / 20.0

## "solo", "host" or "client".
var mode: String = "solo"
var companion: int = 0
## Peer id of the player carrying the team's puzzle piece, or 0.
var holder: int = 0
var game: Node
var send_clock: float = 0.0


func is_host() -> bool:
	return mode == "host"


func is_client() -> bool:
	return mode == "client"


func together() -> bool:
	return mode != "solo" and companion != 0


func local_id() -> int:
	return multiplayer.get_unique_id() if mode != "solo" else 1


## Whether this player is the one carrying the shared puzzle piece.
func holds_locally() -> bool:
	return mode == "solo" or holder == 0 or holder == local_id()


func host() -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT, 1)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	mode = "host"
	_connect_signals()
	return OK


func join(address: String) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address.strip_edges() if not address.strip_edges().is_empty() else "127.0.0.1", PORT)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	mode = "client"
	_connect_signals()
	return OK


func close() -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	for pair: Array in [[multiplayer.peer_connected, _on_peer_connected], [multiplayer.peer_disconnected, _on_peer_disconnected], [multiplayer.connected_to_server, _on_connected], [multiplayer.connection_failed, _on_failed], [multiplayer.server_disconnected, _on_server_gone]]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])
	mode = "solo"
	companion = 0
	holder = 0


## The machine's LAN addresses, to tell the companion where to connect.
static func addresses() -> Array[String]:
	var found: Array[String] = []
	for address: String in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254."):
			found.append(address)
	return found


func _connect_signals() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)


func _on_peer_connected(id: int) -> void:
	if is_host():
		companion = id
		companion_joined.emit()
	elif id == 1:
		companion = 1


func _on_peer_disconnected(id: int) -> void:
	if id != companion:
		return
	if is_client():
		_close_then.call_deferred(companion_left)
		return
	companion = 0
	if holder == id:
		holder = 0
	companion_left.emit.call_deferred()


func _on_connected() -> void:
	companion = 1
	connected_to_host.emit()


# Closing the peer inside its own signal would free it mid-poll, so these wait a frame.
func _on_failed() -> void:
	_close_then.call_deferred(connection_failed)


func _on_server_gone() -> void:
	_close_then.call_deferred(companion_left)


func _close_then(event: Signal) -> void:
	if mode == "solo" and event == companion_left:
		return
	close()
	event.emit()


func _process(delta: float) -> void:
	if not together() or game == null:
		return
	send_clock += delta
	if send_clock < SEND_RATE:
		return
	send_clock = 0.0
	var room: ActScene = game.room
	if room == null or room.player == null:
		return
	pose.rpc(game.state.act(), room.player.global_position, room.player.rotation.y, room.player.camera.rotation.x)
	if is_host() and room is RipperStreet:
		var street := room as RipperStreet
		shadow_pose.rpc(street.shadow.position, street.shadow.rotation, street.shadow.visible, street.patrol_clock, street.patrol_step)


# --- Messages -------------------------------------------------------------------------------

## Host → companion: the whole run, after every change.
func send_state() -> void:
	if is_host() and together():
		state.rpc_id(companion, game.state.to_data(), holder)


@rpc("authority", "call_remote", "reliable")
func state(data: Dictionary, carrying: int) -> void:
	holder = carrying
	game.call("_follow_state", data)


## Companion → host: perform an interaction on the host's copy of the world.
func request_interact(interaction: String, index: int, argument: String, at: Vector3, alternate: bool) -> void:
	act_on.rpc_id(1, interaction, index, argument, at, alternate)


@rpc("any_peer", "call_remote", "reliable")
func act_on(interaction: String, index: int, argument: String, at: Vector3, alternate: bool) -> void:
	if is_host():
		game.call("_remote_interact", multiplayer.get_remote_sender_id(), interaction, index, argument, at, alternate)


## Companion → host: a scene-level action such as a witnessed stop or a walked floor plate.
func request(action: String, arguments: Array) -> void:
	perform.rpc_id(1, action, arguments)


@rpc("any_peer", "call_remote", "reliable")
func perform(action: String, arguments: Array) -> void:
	if is_host():
		game.call("_remote_action", multiplayer.get_remote_sender_id(), action, arguments)


## Host → one player: feedback that belongs only to the one who acted.
func tell(peer: int, kind: String, arguments: Array) -> void:
	if peer == local_id():
		game.call("_feedback", kind, arguments)
	else:
		feedback.rpc_id(peer, kind, arguments)


@rpc("authority", "call_remote", "reliable")
func feedback(kind: String, arguments: Array) -> void:
	game.call("_feedback", kind, arguments)


## Host → everyone: a cinematic both players live through (the bridge, a transition).
func broadcast_cinematic(kind: String) -> void:
	if is_host() and together():
		cinematic.rpc_id(companion, kind)


@rpc("authority", "call_remote", "reliable")
func cinematic(kind: String) -> void:
	game.call("_follow_cinematic", kind)


## Host → companion: start playing (or return to the title).
func send_begin(fresh: bool) -> void:
	if is_host() and together():
		begin.rpc_id(companion, game.state.to_data(), fresh)


@rpc("authority", "call_remote", "reliable")
func begin(data: Dictionary, fresh: bool) -> void:
	game.call("_follow_begin", data, fresh)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func pose(act: String, at: Vector3, yaw: float, pitch: float) -> void:
	game.call("_companion_pose", act, at, yaw, pitch)


@rpc("authority", "call_remote", "unreliable_ordered")
func shadow_pose(at: Vector3, rotation_euler: Vector3, shown: bool, clock: float, step: int) -> void:
	if game.room is RipperStreet:
		(game.room as RipperStreet).follow_shadow(at, rotation_euler, shown, clock, step)
