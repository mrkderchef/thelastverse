extends SceneTree
## Two games in one process, each with its own multiplayer branch, connected over localhost:
## the host runs the tale, the companion joins, acts through the host, sees the host's changes,
## respects the single carried piece, walks through a transition, and returns to its own save.

var host: Node
var guest: Node
var checks: int = 0
var failures: int = 0
var saves: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	host = _game("HostSide")
	guest = _game("GuestSide")
	await _frames(5)
	_expect(host.net.host() == OK, "The host opens the game")
	host._show_host()
	_expect(guest.net.join("127.0.0.1") == OK, "The companion knocks at the host's address")
	_expect(await _until(func() -> bool: return host.net.together() and guest.net.together(), 600), "Both are connected")
	_expect(_has_button(host, "COOP_BEGIN"), "The host is offered to begin together")
	host._begin()
	_expect(await _until(func() -> bool: return guest.has_run and guest.room is StudyRoom, 300), "The companion follows into the study")
	host._explore()
	guest._explore()
	await _frames(10)
	_expect(guest.room.follower and not host.room.follower, "The companion's world follows the host")

	# The companion turns a lock wheel: the host's run changes, and the change comes back.
	var wheel: StudyInteractable = guest.room.find_interactable("lock_wheel", 0)
	guest._interact(wheel, false)
	_expect(await _until(func() -> bool: return host.state.lock[0] == 1 and guest.state.lock[0] == 1, 300), "A companion's interaction is performed by the host and synced back")
	_expect(guest.store.load_run() == null, "The companion's own save is not touched")

	# The host takes a piece; the companion cannot use the team's piece while the host holds it.
	var host_socket: StudyInteractable = host.room.find_interactable("ages_socket", 0)
	host._interact(host_socket, false)
	await _until(func() -> bool: return guest.state.held_station == "ages", 300)
	_expect(host.net.holder == 1 and guest.net.holder == 1, "The host carries the piece")
	_expect(not guest.room.hand_owned and host.room.hand_owned, "Only the carrier sees the piece in their hand")
	var before: Array[int] = host.state.ages.duplicate()
	guest._interact(guest.room.find_interactable("ages_socket", 3), false)
	await _frames(30)
	_expect(host.state.ages == before and host.state.held_station == "ages", "The companion cannot place the host's piece")
	host._interact(host_socket, false)
	await _until(func() -> bool: return guest.state.held_station.is_empty(), 300)
	_expect(host.net.holder == 0, "Setting the piece down frees it for either player")

	# Reading happens on the companion's own screen, but the host learns of the clue.
	guest._interact(guest.room.find_interactable("read", -1, "note"), false)
	_expect(guest.screen == guest.Screen.NOTE, "The companion reads the page on their own screen")
	_expect(await _until(func() -> bool: return "note" in host.state.clues, 300), "The host's run records the companion's discovery")
	guest._explore()

	# Each sees the other.
	guest.room.player.reset_at(Vector3(1.2, 0.05, 0.4), 0, 0)
	_expect(await _until(func() -> bool: return host.room.companion != null and host.room.companion.global_position.distance_to(Vector3(1.2, 0.05, 0.4)) < 0.3, 300), "The host sees the companion where they stand")
	_expect(await _until(func() -> bool: return guest.room.companion != null, 300), "The companion sees the host")

	# A transition taken by the host carries the companion along.
	host.state.door_open = true
	host._interact(host.room.find_interactable("painting"), false)
	_expect(await _until(func() -> bool: return host.room is LondonStreet and guest.room is LondonStreet and not guest.bridge_falling, 900), "Stepping into the painting takes both players to London")

	# When the host leaves, the companion returns to their own journey.
	host.net.close()
	_expect(await _until(func() -> bool: return guest.net.mode == "solo" and guest.screen == guest.Screen.MENU and not guest.room.follower, 600), "The companion returns to the title and their own tale when the host leaves")

	paused = false
	host.queue_free()
	guest.queue_free()
	await _frames(3)
	for path: String in saves:
		for suffix: String in ["", ".bak", ".tmp", ".settings"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)
	print("Co-op: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _game(side: String) -> Node:
	var branch := Node.new()
	branch.name = side
	root.add_child(branch)
	set_multiplayer(MultiplayerAPI.create_default_interface(), branch.get_path())
	var game: Node = load("res://app/main.tscn").instantiate()
	var save: String = "user://coop_%s_%s.json" % [side, Time.get_ticks_usec()]
	saves.append(save)
	game.store = SaveStore.new(save)
	game.settings.path = save + ".settings"
	branch.add_child(game)
	return game


func _has_button(game: Node, key: String) -> bool:
	for node: Node in game.overlay.find_children("*", "Button", true, false):
		if (node as Button).text == TranslationServer.translate(key):
			return true
	return false


func _until(condition: Callable, frames: int) -> bool:
	for index: int in range(frames):
		if condition.call():
			return true
		await process_frame
	return condition.call()


func _frames(count: int) -> void:
	for index: int in range(count):
		await process_frame


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
