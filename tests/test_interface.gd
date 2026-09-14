extends SceneTree
var game: Node
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	game = load("res://app/main.tscn").instantiate()
	game.store = SaveStore.new("user://interface_qa_%s.json" % Time.get_ticks_usec())
	game.settings.path = "user://interface_qa.settings"
	root.add_child(game)
	await create_timer(1.0).timeout
	await snap("interface_title")
	game._show_chapters()
	await snap("interface_chapter")
	assert(game.overlay.find_child("ManuscriptChapter", true, false) != null)
	var right := InputEventKey.new()
	right.keycode = KEY_RIGHT
	right.physical_keycode = KEY_RIGHT
	right.pressed = true
	Input.parse_input_event(right)
	await process_frame
	assert(game.launcher_index == 1, "Right arrow must switch the chapter")
	await snap("interface_poster")
	assert(game.overlay.find_child("PosterChapter", true, false) != null)
	game._browse(1)
	await snap("interface_future")
	game._browse(-1)
	game._browse(-1)
	game._show_settings(game.Screen.MENU)
	await snap("interface_settings")
	var apply: Button
	for child: Node in game.overlay.get_children():
		if child is Button and child.text == tr("SAVE_SETTINGS"):
			apply = child
	assert(apply != null and Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(apply.get_global_rect()))
	game._begin()
	await snap("interface_book")
	game._show_note("BOOKLET_TITLE", "BOOKLET_BODY", "scroll")
	await snap("interface_scroll")
	game._explore()
	await create_timer(8.0).timeout
	game._on_focus(game.room.find_interactable("read", -1, "booklet"))
	await snap("interface_hud")
	game._show_pause()
	await snap("interface_pause")
	root.size = Vector2i(1152, 648)
	game._show_menu()
	await snap("interface_title_small")
	game._show_chapters()
	await snap("interface_chapter_small")
	game._show_note("BOOKLET_TITLE", "BOOKLET_BODY", "scroll")
	await snap("interface_scroll_small")
	game._request_quit()
func snap(label: String) -> void:
	await create_timer(0.5).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/qa/" + label + ".png")
	print(label, " OK")
