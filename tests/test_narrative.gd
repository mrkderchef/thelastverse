extends SceneTree
var game: Node
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	game = load("res://app/main.tscn").instantiate()
	game.store = SaveStore.new("user://narrative_qa_%s.json" % Time.get_ticks_usec())
	game.settings.path = "user://narrative_qa.settings"
	root.add_child(game)
	await create_timer(0.7).timeout
	await snap("narrative_title")
	game._begin()
	game._show_story(0)
	await create_timer(0.5).timeout
	await snap("narrative_book")
	game._show_note("BOOKLET_TITLE", "BOOKLET_BODY", "scroll")
	await create_timer(0.5).timeout
	await snap("narrative_scroll")
	game._show_police_map()
	await create_timer(0.5).timeout
	await snap("narrative_map")
	game._explore()
	game.state.completed = true
	game.state.bridge_fallen = true
	game.state.climbed_out = true
	game.state.ripper_completed = true
	game._load_act("courtyard")
	game._explore()
	game.room.player.reset_at(Vector3(0,2.45,-16),0,0)
	await create_timer(0.5).timeout
	await snap("narrative_nursery")
	game.queue_free()
	await process_frame
	quit()
func snap(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/qa/" + name + ".png")
