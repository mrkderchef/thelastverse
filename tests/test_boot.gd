extends SceneTree
## Native packaged-resource boot and graceful shutdown smoke test.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = load("res://app/main.tscn").instantiate()
	game.store = SaveStore.new("user://boot_%s.json" % Time.get_ticks_usec())
	game.settings.path = game.store.path + ".settings"
	root.add_child(game)
	for frame: int in range(120):
		await process_frame
	print("Native boot: title scene loaded; requesting normal quit")
	game._request_quit()
