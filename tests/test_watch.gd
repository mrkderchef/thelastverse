extends SceneTree
## The Whitechapel watch: the Shadow freezes in bright gaslight, walks while it fails,
## and a stop is only recorded when the player can truly see him there.
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var room := RipperStreet.new()
	root.add_child(room)
	var state := StudyState.new()
	state.climbed_out = true
	room.restore(state)
	room.player.enabled = true
	room.player.camera.current = true
	var success: bool = true
	# In bright gaslight he is not there at all, so nothing can be witnessed.
	room.patrol_step = 0
	room.patrol_clock = 0.0
	room.shadow.position = RipperStreet.STOPS[1]
	room.player.reset_at(room.shadow.position + Vector3(0, 0.05, 2.5), 0, 0)
	room.player.camera.look_at(room.shadow.position + Vector3(0, 1.6, 0))
	for frame: int in range(6): await physics_frame
	print("Invisible in bright light: ", not room.shadow.visible and state.watch_seen.is_empty())
	success = success and not room.shadow.visible and state.watch_seen.is_empty()
	for i: int in range(StudyState.WATCH_ROUTE.size()):
		room.patrol_clock = RipperStreet.BRIGHT + RipperStreet.GUTTER + 1.0
		room.patrol_step = i
		room.waiting = 0
		room.shadow.position = RipperStreet.STOPS[i + 1]
		room.player.reset_at(room.shadow.position + Vector3(0, 0.05, 2.5), 0, 0)
		room.player.camera.look_at(room.shadow.position + Vector3(0, 1.6, 0))
		for frame: int in range(6): await physics_frame
		print("Stop ", i, " ", StudyState.WATCH_ROUTE[i], " seen: ", StudyState.WATCH_ROUTE[i] in state.watch_seen)
		success = success and StudyState.WATCH_ROUTE[i] in state.watch_seen
	state.watch_seen.clear()
	# Tenement masonry hides him: stand in the parallel street and look through the block.
	room.patrol_step = 0
	room.waiting = 0
	room.patrol_clock = RipperStreet.BRIGHT + RipperStreet.GUTTER + 1.0
	room.shadow.position = RipperStreet.STOPS[1]
	room.player.reset_at(Vector3(-10, 0.05, -32), 0, 0)
	room.player.camera.look_at(room.shadow.position + Vector3(0, 1.6, 0))
	for frame: int in range(6): await physics_frame
	print("Masonry prevents sightings: ", state.watch_seen.is_empty())
	success = success and state.watch_seen.is_empty()
	# Looking away never counts.
	room.player.reset_at(RipperStreet.STOPS[1] + Vector3(0, 0.05, 3), PI, 0)
	for frame: int in range(6): await physics_frame
	print("Looking away prevents sightings: ", state.watch_seen.is_empty())
	success = success and state.watch_seen.is_empty()
	room.player.reset_at(Vector3(0, 0.05, -4), 0, 0)
	room.patrol_step = 0
	room.patrol_clock = 0.0
	room.shadow.position = RipperStreet.STOPS[0]
	var before: Vector3 = room.shadow.position
	for frame: int in range(10): await physics_frame
	print("Frozen in bright light: ", before == room.shadow.position)
	success = success and before == room.shadow.position
	room.patrol_clock = RipperStreet.BRIGHT + 2.0
	for frame: int in range(10): await physics_frame
	print("Walks while the lamps fail: ", before != room.shadow.position)
	success = success and before != room.shadow.position
	print("Visibility and light-gated patrol checks: ", "PASS" if success else "FAIL")
	room.queue_free()
	await process_frame
	quit(0 if success else 1)
