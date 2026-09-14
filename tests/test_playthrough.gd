extends SceneTree
## Exercises the actual scene: launcher, focus ray, direct object interaction, collision,
## world changes, and reloads. Run with a display for PNGs in builds/qa; --headless for checks.

var game: Node
var failures: int = 0
var checks: int = 0
var test_save: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	test_save = "user://playthrough_%s.json" % Time.get_ticks_usec()
	game = load("res://app/main.tscn").instantiate()
	game.store = SaveStore.new(test_save)
	game.settings.path = test_save + ".settings"
	root.add_child(game)
	await _frames(5)
	_expect(game.screen == game.Screen.MENU and paused and game.menu_page == "title", "Launcher suspends the room")
	_expect(_button("MENU_PLAY") != null and _button("MENU_SETTINGS") != null and _button("MENU_EXIT") != null, "The title page offers Play, Settings and Exit")
	await _frames(20)
	await _capture("01_title")
	_press("MENU_PLAY")
	await _frames(20)
	_expect(game.browsing and game.menu_page == "chapters" and game.overlay.find_children("*", "SceneSlides", true, false).size() == 1, "Play opens the chapter page over its scenes")
	await _capture("01a_chapter")
	var right := InputEventAction.new()
	right.action = "ui_right"
	right.pressed = true
	root.push_input(right)
	await _frames(3)
	_expect(game.launcher_index == 1 and _button("BEGIN") == null, "Right arrow browses to an unavailable chapter")
	await _capture("01b_locked_chapter")
	var left := InputEventAction.new()
	left.action = "ui_left"
	left.pressed = true
	root.push_input(left)
	await _frames(3)
	_expect(game.launcher_index == 0 and _button("BEGIN") != null, "Left arrow returns to London Is Falling")
	_press("BEGIN")
	await _frames(5)
	_expect(game.screen == game.Screen.NOTE and game.overlay.find_children("*", "StoryBook", true, false).size() == 1, "A new tale opens the stranger's book first")
	await _capture("01c_story_book")
	var close_book := InputEventAction.new()
	close_book.action = "interact"
	close_book.pressed = true
	root.push_input(close_book)
	await _frames(5)
	_expect(game.room.player.enabled and not paused, "Closing the book begins the study")
	_expect(game.act_card != null and is_instance_valid(game.act_card), "The act title appears on screen")
	await _frames(3)
	# The act name sits top-left and the save note bottom-right; the rest share the centre.
	for label: Label in [game.objective, game.letters, game.caption, game.prompt, game.holding]:
		_expect(label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and absf(label.get_global_rect().get_center().x - root.get_visible_rect().size.x * 0.5) < 1.5, "HUD label is centered: " + str(label.text))
	var floating: Array[String] = []
	for node: Node in game.room.find_children("*", "Label3D", true, false):
		if (node as Label3D).text.length() > 1:
			floating.append((node as Label3D).text)
	_expect(floating.is_empty(), "No floating text in the room, only letters on cards and lock wheels: " + str(floating))
	await _capture("02_study")
	await _measure_rendering("study")

	var note: StudyInteractable = game.room.find_interactable("read", -1, "note")
	_expect(await _reach(note), "The page on the desk is reachable")
	_use(note)
	await _frames(2)
	_expect(game.screen == game.Screen.NOTE and "note" in game.state.clues, "Reading adds the page to the journal")
	await _capture("03_note")
	_press("PUT_DOWN")
	await _frames(2)

	game.room.player.reset_at(Vector3(0, 0.05, -4.3), 0, 0)
	await _physics_frames(3)
	Input.action_press("move_forward")
	await _physics_frames(70)
	Input.action_release("move_forward")
	_expect(game.room.player.position.z > -5.8, "The locked door blocks walking")

	# Seven Ages: pick tokens up and swap them on the wall dial.
	var socket: StudyInteractable = game.room.find_interactable("ages_socket", 0)
	_expect(await _reach(socket), "The brass dial sockets are reachable")
	_expect(game.prompt.text.contains(TranslationServer.translate("TOKEN_SWORD")), "The prompt names the token under the crosshair")
	_use(socket)
	await _physics_frames(2)
	_expect(game.state.held_station == "ages" and game.room.hand.get_child_count() > 1, "The picked-up token appears in the hand")
	_expect(game.holding.text.contains(TranslationServer.translate("TOKEN_SWORD")), "The HUD names the token in hand")
	await _capture("04_ages_in_hand")
	_use(socket)
	await _physics_frames(2)
	_expect(game.state.held_station.is_empty() and game.state.ages == StudyState.new().ages, "Putting the token back restores the dial")
	var reader: StudyInteractable = game.room.find_interactable("read", -1, "booklet")
	_expect(await _reach(reader), "The booklet is reachable on the sideboard")
	_arrange("ages", "ages_socket", StudyState.SOLVED_AGES)
	await _physics_frames(45)
	_expect(game.state.ages_solved and game.room.ages.drawer.position.z > 0.6, "A life in order opens the dial drawer")
	_expect(game.caption.text == TranslationServer.translate("SOLVED_AGES"), "Completion is described in a caption")
	var handle: StudyInteractable = game.room.find_interactable("take", -1, "handle")
	_expect(await _reach(handle), "The Skull Handle is reachable in the open drawer")
	await _capture("05_ages_drawer")
	_use(handle)
	_expect(game.state.has_item("handle") and not handle.visible, "Taking the handle pockets it")

	# Hamlet: fit the handle, then turn the dials to match the reflection.
	var dial: StudyInteractable = game.room.find_interactable("mirror_dial", 0)
	_expect(await _reach(dial), "The mirror dials are reachable")
	_use(dial)
	_expect(game.state.mirror == StudyState.new().mirror, "Dials do not turn before the handle is fitted")
	_use(game.room.find_interactable("handle_socket"))
	await _physics_frames(2)
	_expect(game.state.handle_inserted and game.room.mirror.reflection.visible, "The handle uncovers the reflection")
	await _capture("07_mirror")
	for index: int in range(3):
		while game.state.mirror[index] != index:
			_use(game.room.find_interactable("mirror_dial", index))
	await _physics_frames(60)
	_expect(game.state.mirror_solved and game.room.mirror.door_pivot.rotation.y < -1.5, "Matching the reflection opens the cabinet")
	var moon: StudyInteractable = game.room.find_interactable("take", -1, "moon")
	_expect(await _reach(moon), "The Moon Lens is reachable in the cabinet")
	_use(moon)

	# Macbeth: carry the figures between chairs.
	var seat: StudyInteractable = game.room.find_interactable("banquet_seat", 1)
	_expect(await _reach(seat), "The banquet chairs are reachable")
	_use(game.room.find_interactable("banquet_seat", 0))
	_expect(game.state.held_station == "macbeth", "A banquet figure can be picked up")
	_use(game.room.find_interactable("ages_socket", 3))
	_expect(game.state.held_station.is_empty() and game.state.banquet == StudyState.new().banquet, "Using a solved station puts the carried figure back")
	_arrange("macbeth", "banquet_seat", StudyState.SOLVED_BANQUET)
	await _physics_frames(50)
	_expect(game.state.macbeth_solved and game.room.banquet.ghost.visible, "The unseen guest appears in the empty chair")
	var sun: StudyInteractable = game.room.find_interactable("take", -1, "sun")
	_expect(await _reach(sun), "The Sun Lens is reachable in the banquet drawer")
	await _capture("13_banquet")
	_use(sun)

	var page: StudyInteractable = game.room.find_interactable("read", -1, "page_bed")
	_expect(await _reach(page), "The note under the pillow is reachable")
	_use(page)
	await _frames(2)
	_expect(game.screen == game.Screen.NOTE and "page_bed" in game.state.clues, "Loose pages are kept as lore")
	_press("PUT_DOWN")
	await _frames(2)

	# Romeo & Juliet: fit lenses and turn the lanterns.
	var sun_lantern: StudyInteractable = game.room.find_interactable("lantern", 0)
	_expect(await _reach(sun_lantern), "The lanterns are reachable")
	_expect(game.prompt.text.contains(TranslationServer.translate("PROMPT_FIT_SUN")), "The prompt offers to fit the right lens")
	for index: int in range(2):
		var lantern: StudyInteractable = game.room.find_interactable("lantern", index)
		_use(lantern)
		var target: int = StudyState.SUN_TARGET if index == 0 else StudyState.MOON_TARGET
		while game.state.lanterns[index] != target and not game.state.balcony_solved:
			_use(lantern)
	await _physics_frames(80)
	_expect(game.state.balcony_solved and game.room.balcony.curtain.position.y > 1.9, "Crossed beams on the right balconies raise the curtain")
	_expect(game.state.letters() == ["H", "E", "L", "P"] and game._letter_row().contains("P"), "The HUD shows all four letters")
	await _look_from_target(game.room.find_interactable("lantern", 1), 1.8)
	await _capture("14_balcony")
	game._show_journal(game.Screen.EXPLORE)
	await _frames(2)
	await _capture("06_journal")
	game._show_hints()
	await _frames(2)
	await _capture("06b_hints")
	var hint_track: int = StudyState.PUZZLES.find("lock")
	_expect("ages" in game.state.clues and _button("HINT") != null, "The chapter page offers hints for discovered puzzles")
	game._explore()
	await _frames(2)

	# The letter lock.
	var wheel: StudyInteractable = game.room.find_interactable("lock_wheel", 0)
	_expect(await _reach(wheel), "The lock wheels are reachable on the door")
	game.room.player.interacted.emit(wheel, true)
	_expect(game.state.lock_text() == "ZAAA", "Right click turns a wheel backwards")
	game.room.player.interacted.emit(wheel, false)
	for index: int in [3, 2, 1, 0]:
		while game.state.lock[index] != StudyState.SOLVED_LOCK[index] and not game.state.door_open:
			_use(game.room.find_interactable("lock_wheel", index))
	await _capture("08_lock")
	await _physics_frames(110)
	_expect(game.state.door_open and game.room.door_pivot.rotation.y < -1.4 and game.room.door_body.collision_layer == 0, "HELP opens the door")
	_expect(hint_track == 4 and game.state.hints[hint_track] == 0, "No hint was needed to finish")
	var painting: StudyInteractable = game.room.find_interactable("painting")
	_expect(await _reach(painting), "The painting of London hangs at the end of the gallery")
	game.room.player.reset_at(Vector3(0, 0.05, -11.5), 0, 0)
	await _physics_frames(20)
	await _capture("09_painting")
	_expect(not game.state.completed, "Walking up to the painting does not leave the study")
	_use(painting)
	_expect(await _until(func() -> bool: return game.room is LondonStreet and game.room.player.enabled, 900), "Stepping into the painting loads the streets")
	_expect(game.room is LondonStreet and game.screen == game.Screen.EXPLORE and game.room.player.enabled, "The streets of London load after the study")
	_expect(game.store.load_run().completed, "Leaving the study persists")
	floating.clear()
	for node: Node in game.room.find_children("*", "Label3D", true, false):
		if not node.has_meta("diegetic"):
			floating.append((node as Label3D).text)
	_expect(floating.is_empty(), "No floating text in the streets: " + str(floating))
	await _capture("15_street_start")
	await _measure_rendering("streets")

	# Street life: loose goods, doors, the market bell, pigeons, and staying on the map.
	var trinkets: Array[Node] = game.room.find_children("*", "Trinket", true, false)
	_expect(trinkets.size() >= 20, "The streets are littered with things to pick up (%d)" % trinkets.size())
	var apple: Trinket = null
	for node: Node in trinkets:
		if (node as Trinket).kind == "apple" and (node as Trinket).global_position.z > -6.0:
			apple = node
	_expect(apple != null and await _reach(apple.handle), "A loose apple is reachable")
	if apple != null:
		_use(apple.handle)
		_expect(game.room.carried == apple and game.holding.text.contains(TranslationServer.translate("TRINKET_APPLE")), "The apple goes into the left hand")
		var before: Vector3 = game.room.player.global_position
		var throw := InputEventAction.new()
		throw.action = "drop"
		throw.pressed = true
		root.push_input(throw)
		await _physics_frames(40)
		_expect(game.room.carried == null and apple.get_parent() == game.room and apple.global_position.distance_to(before) > 0.4, "Q throws the apple back into the world")
	var door: StudyInteractable = game.room.find_interactable("knock")
	_expect(door != null and await _reach(door, true), "A front door can be knocked on")
	if door != null:
		_use(door)
		_expect(game.caption.text.length() > 0 and game.caption.text != TranslationServer.translate("SLOT_EMPTY"), "Someone (or no one) answers the knock")
	var flocks: Array[Node] = []
	for node: Node in game.room.get_children():
		if node is Birds.PigeonFlock:
			flocks.append(node)
	_expect(flocks.size() >= 3, "Pigeons peck around the streets")
	var bell: StudyInteractable = game.room.find_interactable("bell")
	_expect(bell != null and await _reach(bell), "The market bell can be reached")
	if bell != null:
		_use(bell)
		_expect(game.caption.text == TranslationServer.translate("BELL_RUNG"), "Ringing the bell is described")
	game.room.player.reset_at(Vector3(0, 0.05, -6.0), 0, 0)
	await _physics_frames(10)
	game.room.player.global_position = Vector3(0, -6.0, -6.0)
	await _frames(3)
	_expect(game.room.player.global_position.y > -1.0, "Falling out of the set returns the player to safe ground")

	# Balcony Lane: put the right props in the players' hands.
	game.room.player.reset_at(Vector3(0, 0.05, -26.5), 0, 0)
	Input.action_press("move_forward")
	await _physics_frames(90)
	Input.action_release("move_forward")
	_expect(game.room.player.position.z > -29.8, "The iron curtain blocks Balcony Lane")
	var playbill: StudyInteractable = game.room.find_interactable("read", -1, "playbill")
	_expect(await _reach(playbill, true), "The playbill is reachable beside the cart")
	_use(playbill)
	await _frames(2)
	_press("PUT_DOWN")
	await _frames(2)
	for slot: int in [0, 5, 6, 7]:
		_expect(await _reach(game.room.find_interactable("prop_slot", slot), true), "Prop slot %d is reachable" % slot)
	await _look_from_target(game.room.find_interactable("prop_slot", 6), 2.6, true)
	await _capture("16_balcony_scene")
	_use(game.room.find_interactable("prop_slot", 1))
	_expect(game.state.held_station == "props" and game.room.hand.get_child_count() > 1, "A prop from the cart appears in the hand")
	for index: int in range(3):
		var slot: int = StudyState.ACTOR_SLOTS[index]
		if game.state.held_station.is_empty():
			_use(game.room.find_interactable("prop_slot", game.state.props.find(StudyState.SOLVED_PROPS[index])))
		elif game.state.held_piece != StudyState.SOLVED_PROPS[index]:
			_use(game.room.find_interactable("prop_slot", game.state.props.find(-1)))
			_use(game.room.find_interactable("prop_slot", game.state.props.find(StudyState.SOLVED_PROPS[index])))
		_use(game.room.find_interactable("prop_slot", slot))
		if not game.state.held_station.is_empty():
			_use(game.room.find_interactable("prop_slot", game.state.props.find(-1)))
	await _physics_frames(200)
	_expect(game.state.props_solved and game.room.lane_gate.position.y > 10.0 and game.state.held_station.is_empty(), "The right props lift the iron curtain")
	await _capture("17_lane_open")

	# The Witches' Square: brew in the order of the verse.
	var jar: StudyInteractable = game.room.find_interactable("shelf_jar", 0)
	_expect(await _reach(jar, true), "The ingredient jars are reachable on the stall")
	var cauldron: StudyInteractable = game.room.find_interactable("cauldron")
	_use(game.room.find_interactable("shelf_jar", game.state.shelf.find(5)))
	_expect(await _reach(cauldron), "The cauldron is reachable")
	_expect(game.prompt.text.contains(TranslationServer.translate("INGREDIENT_MANDRAKE")), "The prompt names the carried ingredient")
	_use(cauldron)
	_expect(game.state.brew.is_empty() and game.caption.text == TranslationServer.translate("BREW_SPOILED"), "The wrong ingredient is spat back")
	var bellows: StudyInteractable = game.room.find_interactable("bellows")
	_expect(await _reach(bellows), "The bellows are reachable")
	_expect(game.room.find_children("*", "StudyInteractable", true, false).filter(func(node: Node) -> bool: return node.has_meta("witch")).size() == 3, "Each witch holds a readable scrap")
	for step: int in range(StudyState.RECIPE.size()):
		while game.state.heat != StudyState.RECIPE_HEAT[step]:
			_use(bellows)
		_use(game.room.find_interactable("shelf_jar", game.state.shelf.find(StudyState.RECIPE[step])))
		_use(cauldron)
	await _physics_frames(200)
	_expect(game.state.brew_solved and game.room.square.smoke.visible and game.room.square_gate.position.y > 9.0, "The witches' brew lifts the portcullis")
	await _look_from_target(cauldron, 4.0)
	await _capture("18_witches_square")

	# The riverside: the Ides of March lowers the drawbridge of London Bridge.
	var month: StudyInteractable = game.room.find_interactable("calendar_wheel", 0)
	_expect(await _reach(month, true), "The engine's calendar is reachable")
	_expect(await _reach(game.room.find_interactable("read", -1, "soothsayer"), true), "The soothsayer's scroll is reachable")
	var lever: StudyInteractable = game.room.find_interactable("bridge_lever")
	_expect(await _reach(lever, true), "The engine lever is reachable")
	_use(lever)
	_expect(not game.state.bridge_lowered and game.caption.text == TranslationServer.translate("LEVER_WRONG"), "The wrong date rattles the lever")
	game.room.player.reset_at(Vector3(0, 0.05, -88.0), 0, 0)
	await _physics_frames(3)
	Input.action_press("move_forward")
	await _physics_frames(90)
	Input.action_release("move_forward")
	_expect(game.room.player.global_position.z > -90.2 and game.room.player.global_position.y > -0.5, "A raised drawbridge cannot be walked off")
	game.room.player.reset_at(Vector3(0, 0.05, -76.0), 0, 0.12)
	await _physics_frames(4)
	await _capture("19_london_bridge_raised")
	game.room.player.interacted.emit(month, true)
	_expect(game.state.calendar[0] == 11, "Right click turns the month wheel back")
	for step: int in range(3):
		_use(month)
	for step: int in range(14):
		_use(game.room.find_interactable("calendar_wheel", 1))
	_expect(game.room.bridge.month_label.text == "MAR" and game.room.bridge.day_label.text == "15", "The engine wheels show the Ides of March")
	_use(lever)
	await _physics_frames(360)
	_expect(game.state.bridge_lowered and absf(game.room.bridge.drawbridge.rotation.x) < 0.05, "The drawbridge lowers")
	game.room.player.reset_at(Vector3(0, 0.05, -78.0), 0, 0.05)
	await _physics_frames(4)
	await _capture("20_london_bridge_lowered")
	game.room.player.reset_at(Vector3(0, 0.05, -81.5), 0, 0)
	await _physics_frames(3)
	Input.action_press("move_right")
	await _physics_frames(120)
	Input.action_release("move_right")
	_expect(game.room.player.global_position.x < 4.2 and game.room.player.global_position.y > -0.5, "Invisible walls keep the player on the bridge approach")
	# London Bridge is falling down, and the player with it.
	game.room.player.reset_at(Vector3(0, 0.05, -99.0), 0, 0)
	Input.action_press("move_forward")
	await _physics_frames(150)
	Input.action_release("move_forward")
	await _physics_frames(30)
	_expect(game.caption.text == TranslationServer.translate("LADY_RISES") and not game.room.player.enabled and game.room.bridge.lady.visible, "Stepping onto London Bridge wakes the immured girl")
	await _frames(60)
	await _capture("21a_lady_climbing")
	_expect(await _until(func() -> bool: return game.caption.text == TranslationServer.translate("LADY_SINGS"), 900), "She climbs over the parapet and starts to crawl")
	await _frames(40)
	await _capture("21_fair_lady")
	var face_to_player: Vector3 = game.room.player.position - game.room.bridge.lady.global_position
	face_to_player.y = 0
	_expect(game.room.bridge.crawling and game.room.bridge.lady.global_basis.z.dot(face_to_player.normalized()) > 0.97, "The crawling girl faces the player")
	var lady_start: Vector3 = game.room.bridge.lady.global_position
	_expect(await _until(func() -> bool: return game.caption.text == TranslationServer.translate("BRIDGE_FALLING"), 2400), "She reaches the player and the bridge comes down")
	_expect(game.room.bridge.lady.global_position.distance_to(game.room.player.global_position) < lady_start.distance_to(game.room.player.global_position), "She crawled closer before the lunge")
	var fall_height: float = game.room.player.position.y
	await _frames(14)
	await _capture("21c_lunge")
	await _until(func() -> bool: return game.fader.color.a > 0.99, 300)
	_expect(game.room is LondonStreet and game.room.player.position.y < fall_height - 1.0 and not game.room.player.enabled, "The player falls with the bridge as the picture goes black")
	await _capture("21b_bridge_falling")
	await _until(func() -> bool: return game.room is PlagueSewer and game.room.player.enabled, 2400)
	_expect(game.room is PlagueSewer and game.state.bridge_fallen and game.room.player.enabled, "The fall lands in the plague sewer")
	if not game.room is PlagueSewer:
		_finish()
		return
	_expect(game.store.load_run().act() == "sewer", "The fall persists")
	await _frames(120)
	await _capture("22_sewer_landing")

	# The plague sewer: a plague o' both your houses.
	var crypt: StudyInteractable = game.room.find_interactable("crypt_door", 0)
	_expect(await _reach(crypt, true), "The crypt doors are reachable")
	_use(crypt)
	_expect(game.state.crypts == [0, 0, 0, 0] and game.caption.text == TranslationServer.translate("CRYPT_NO_BRUSH"), "Without the brush no cross is painted")
	_expect(await _reach(game.room.find_interactable("read", -1, "warrant")), "The plague warrant is reachable")
	var brush: StudyInteractable = game.room.find_interactable("take", -1, "brush")
	_expect(await _reach(brush), "The brush in the paint pot is reachable")
	_use(brush)
	for index: int in range(4):
		_expect(await _reach(game.room.find_interactable("crypt_door", index), true), "Crypt door %d is reachable" % index)
	_use(game.room.find_interactable("crypt_door", 3))
	_use(game.room.find_interactable("crypt_door", 0))
	_expect(game.state.crypts == [1, 0, 0, 1] and not game.state.sewer_solved and game.room.crosses[3].visible, "A cross on the bell crypt keeps the gate shut")
	_use(game.room.find_interactable("crypt_door", 3))
	_use(game.room.find_interactable("crypt_door", 2))
	await _physics_frames(180)
	_expect(game.state.sewer_solved and game.room.gate.position.y > 7.0, "The feuding houses marked in red open the gate")
	await _look_from_target(game.room.find_interactable("crypt_door", 2), 5.0, true)
	await _capture("23_plague_cemetery")
	var ladder: StudyInteractable = game.room.find_interactable("climb")
	_expect(await _reach(ladder), "The ladder is reachable beyond the gate")
	_use(ladder)
	await _until(func() -> bool: return game.room is RipperStreet and game.room.player.enabled, 1500)
	_expect(game.room is RipperStreet and game.state.climbed_out and game.room.player.enabled, "Climbing out reaches the Ripper's streets")
	if not game.room is RipperStreet:
		_finish()
		return
	await _frames(90)
	await _capture("24_ripper_street")
	floating.clear()
	for node: Node in game.room.find_children("*", "Label3D", true, false):
		if not node.has_meta("diegetic"):
			floating.append((node as Label3D).text)
	_expect(floating.is_empty(), "No floating text in the dark streets: " + str(floating))
	var watch: RipperStreet = game.room
	watch.patrol_clock = 0
	var still: Vector3 = watch.shadow.position
	await _physics_frames(30)
	_expect(watch.shadow.position == still, "The suspect freezes while gas lamps are bright")
	watch.patrol_clock = RipperStreet.BRIGHT + 2.0
	await _physics_frames(30)
	_expect(watch.shadow.position != still, "The suspect moves in failing gaslight")
	var plan_desk: StudyInteractable = watch.find_interactable("inspection_lamp")
	_expect(await _reach(plan_desk), "The constable's street plan is reachable at the Watch Post")
	for stop_index: int in range(StudyState.WATCH_ROUTE.size()):
		watch.patrol_step = stop_index
		watch.waiting = 0
		watch.shadow.position = RipperStreet.STOPS[stop_index + 1]
		watch.player.reset_at(watch.shadow.position + Vector3(0, 0.05, 2.5), 0, 0)
		watch.player.camera.look_at(watch.shadow.position + Vector3(0, 1.6, 0))
		await _physics_frames(4)
		_expect(StudyState.WATCH_ROUTE[stop_index] in game.state.watch_seen, "Visible landmark is recorded")
	_expect(game.store.load_run().watch_seen.size() == StudyState.WATCH_ROUTE.size(), "Observed places survive reload")
	_expect(not game.state.report_watch(Array(["YARD", "CROSS", "WELL", "CHAPEL", "TANNERY", "GATE"], TYPE_STRING, "", null)), "Wrong police report preserves the locked cordon")
	game._show_police_map()
	await _frames(5)
	await _capture("25_police_map")
	game._explore()
	_expect(game.state.report_watch(StudyState.WATCH_ROUTE), "A verified ordered report opens the gate")
	await _physics_frames(120)
	game.room.player.reset_at(Vector3(0, 0.05, -52.0), 0, 0)
	Input.action_press("move_forward")
	await _physics_frames(240)
	Input.action_release("move_forward")
	await _until(func() -> bool: return game.room is DyerCourtyard and game.room.player.enabled, 1200)
	_expect(game.state.ripper_completed and game.room is DyerCourtyard, "Escaping the Shadow continues into the back court")
	if not game.room is DyerCourtyard:
		_finish()
		return
	await _capture("30_dyer_courtyard")
	game.room.player.reset_at(Vector3(0, 0.08, -6), 0, 0)
	Input.action_press("move_forward")
	await _physics_frames(225)
	Input.action_release("move_forward")
	_expect(game.room.player.position.y > 2.2 and game.room.player.position.z < -14.5, "The back staircase is continuously walkable into the house")
	var record: StudyInteractable = game.room.find_interactable("read", -1, "dyer_record")
	game.room.player.reset_at(Vector3(-2.4, 2.45, -16.6), 0, 0)
	game.room.player.camera.look_at(record.global_position)
	await _physics_frames(5)
	_expect(game.room.player.target == record, "Dyer's historical record is readable from the upstairs floor")
	_use(record)
	_expect("dyer_record" in game.state.clues and game.screen == game.Screen.NOTE, "The house tells Dyer's story before the fall")
	await _capture("31_dyer_record")
	game._explore()
	game.room.player.reset_at(Vector3(0, 2.45, -22), 0, 0)
	Input.action_press("move_forward")
	await _physics_frames(50)
	Input.action_release("move_forward")
	_expect(game.room is DyerCourtyard and game.room.player.position.z > -23.6, "The unsolved bookcase blocks the secret passage")
	var memory: StudyInteractable = game.room.find_interactable("house_replay")
	_expect(await _reach_upstairs(memory), "The memory box is reachable upstairs")
	_use(memory)
	await _until(func() -> bool: return not game.room.replay_tween.is_running(), 1800)
	_expect(game.state.celestial.house_steps.is_empty(), "Replaying the memory does not submit the solution")
	for index: int in range(4):
		_expect(await _reach_upstairs(game.room.find_interactable("house_bell", index)), "Upstairs bell %d is reachable" % index)
	_use(game.room.find_interactable("house_bell", 0))
	_expect(game.state.celestial.house_steps.is_empty(), "A wrong bell leaves the hidden passage closed")
	_use(game.room.find_interactable("house_bell", 2))
	_expect(game.store.load_run().celestial.house_steps == [2], "A partial memory is saved")
	for index: int in [0, 3, 1, 0]:
		_use(game.room.find_interactable("house_bell", index))
	await _physics_frames(135)
	_expect(game.state.celestial.house_solved and game.room.bookcase.position.x > 3.0, "The memory moves the bookcase aside")
	game.room.player.reset_at(Vector3(0, 2.45, -22), 0, 0)
	await _capture("31b_secret_passage")
	Input.action_press("move_forward")
	await _physics_frames(110)
	Input.action_release("move_forward")
	await _until(func() -> bool: return game.room is StarNursery and game.room.player.enabled, 1200)
	_expect(game.room is StarNursery and game.state.celestial.entered, "The secret passage leads directly into the great star hall")
	if not game.room is StarNursery:
		_finish()
		return
	await _capture("32_star_nursery")
	game.room.player.reset_at(Vector3(0, 0.05, -12), 0, 0.85)
	await _capture("33_constellations")
	for clue: String in ["star_rules", "star_covenant", "star_walk", "star_atlas"]:
		var nursery_note: StudyInteractable = game.room.find_interactable("read", -1, clue)
		_expect(await _reach(nursery_note), "Nursery clue is reachable: " + clue)
		_use(nursery_note)
		game._explore()
	var seal: StudyInteractable = game.room.find_interactable("star_confirm")
	_expect(await _reach(seal), "The central seal is reachable")
	_use(seal)
	_expect(not game.state.celestial.aligned, "An incorrect alignment does not open the seal")
	for index: int in range(4):
		var keeper: StudyInteractable = game.room.find_interactable("star_keeper", index)
		_expect(await _reach(keeper), "Keeper %d is reachable" % index)
		for turn: int in range(CelestialState.ORIENTATIONS[index]):
			_use(keeper)
	_use(seal)
	_expect(game.state.celestial.aligned and game.store.load_run().celestial.aligned, "The correct four sights align and persist")
	await _walk_plate(1)
	_expect(game.state.celestial.steps == [1], "Walking onto the Diamond enters one step")
	await _physics_frames(30)
	_expect(game.state.celestial.steps == [1], "Standing still never repeats a floor input")
	await _walk_plate(0)
	_expect(game.state.celestial.steps.is_empty() and game.state.celestial.aligned, "A wrong walked sign resets only the footsteps")
	for index: int in CelestialState.PATH:
		await _walk_plate(index)
	_expect(game.state.celestial.solved and game.store.load_run().celestial.solved, "The decoded back-mark route opens the nursery")
	await _physics_frames(140)
	_expect(game.room.gate.position.y > 4, "The railway gate physically rises")
	game.room.player.reset_at(Vector3(0, 0.05, -21.5), 0, 0)
	await _capture("34_nursery_open")
	Input.action_press("move_forward")
	await _physics_frames(110)
	Input.action_release("move_forward")
	await _until(func() -> bool: return game.room is MetropolitanStation and game.room.player.enabled, 1200)
	_expect(game.room is MetropolitanStation and game.state.celestial.railway_entered, "The solved nursery grants access to the Metropolitan Railway")
	if not game.room is MetropolitanStation:
		_finish()
		return
	await _capture("35_metropolitan")
	_expect(await _reach(game.room.find_interactable("read", -1, "railway_history"), true), "The station history is reachable")
	game.room.player.reset_at(Vector3(0, 0.05, -29), 0, 0)
	await _physics_frames(4)
	_expect(not game.state.celestial.completed and game.screen == game.Screen.EXPLORE, "Exploring the platform does not end the level")
	var board_train: StudyInteractable = game.room.find_interactable("train_board")
	_use(board_train)
	_expect(not game.bridge_falling and not game.state.celestial.completed, "An unrepaired train cannot depart")
	for control: String in ["feed", "union", "fire", "relief", "brake"]:
		_expect(await _reach(game.room.find_interactable("train_control", -1, control), true), "Train control is reachable: " + control)
	_expect(await _reach(game.room.find_interactable("read", -1, "train_manual"), true), "The repair book is reachable")
	_use(game.room.find_interactable("train_control", -1, "union"))
	_expect(not game.state.celestial.union_repaired and game.room.leak.visible, "The feed must be isolated before repair")
	for control: String in ["feed", "union", "feed", "fire", "fire", "relief"]:
		_use(game.room.find_interactable("train_control", -1, control))
	_expect(game.state.celestial.train_gauges() == Vector2i(3,1) and not game.room.leak.visible, "The repaired feed and calibrated controls restore working steam")
	_expect(not game.state.celestial.train_ready(), "The brake still holds a prepared locomotive")
	_use(game.room.find_interactable("train_control", -1, "brake"))
	_expect(game.store.load_run().celestial.train_ready(), "Departure preparation persists")
	_expect(await _reach(board_train, true), "The departure control is reachable from the platform")
	await _capture("35b_train_ready")
	_use(board_train)
	await _physics_frames(120)
	_expect(game.bridge_falling and not game.room.player.enabled and game.room.train.position.z < -0.8 and not game.state.celestial.completed, "The train moves with the player aboard before completion")
	await _capture("35c_departing")
	await _until(func() -> bool: return game.screen == game.Screen.END, 1800)
	_expect(game.state.celestial.completed and game.screen == game.Screen.END and game.store.load_run().celestial.completed, "Only the departure completes and saves the level")
	await _capture("36_railway_end")
	_press("END_LOOK")
	await _frames(3)
	game._show_settings(game.Screen.PAUSE)
	await _frames(2)
	await _capture("11_settings")
	game.settings.fov = 90
	game.settings.music = 0.0
	_press("SAVE_SETTINGS")
	var reloaded := StudySettings.new()
	reloaded.path = game.settings.path
	reloaded.load_settings()
	_expect(reloaded.fov == 90 and reloaded.music == 0.0, "Settings persist independently")
	game.room.restore(game.store.load_run())
	_expect(game.room.player.position.z > 0.0 and game.room is MetropolitanStation, "Reload returns to the unlocked railway")
	game._show_chapters()
	await _frames(2)
	await _capture("12_resume_title")
	_expect(_button("RESUME") != null and _button("NEW_RUN") != null, "Launcher offers resume and restart for an existing run")
	game.queue_free()
	paused = false
	await _frames(3)
	for suffix: String in ["", ".bak", ".tmp", ".settings"]:
		if FileAccess.file_exists(test_save + suffix):
			DirAccess.remove_absolute(test_save + suffix)
	print("Playable scene: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _reach_upstairs(target: StudyInteractable) -> bool:
	game.room.player.reset_at(Vector3(target.global_position.x + 0.3, 2.45, target.global_position.z + 2.1), 0, 0)
	game.room.player.camera.look_at(target.global_position)
	await _physics_frames(5)
	return game.room.player.target == target


func _walk_plate(index: int) -> void:
	var spot: Vector3 = StarNursery.PLATES[index]
	game.room.player.reset_at(spot + Vector3(0, 0.08, 1.6), 0, -0.5)
	await _physics_frames(3)
	Input.action_press("move_forward")
	await _physics_frames(30)
	Input.action_release("move_forward")
	await _physics_frames(3)


## Rearranges a slot station purely by using its sockets, as a player would.
func _arrange(station: String, id: String, target: Array[int]) -> void:
	var empty: int = -1 if station == "ages" else 0
	for slot: int in range(target.size()):
		var slots: Array[int] = game.state.ages if station == "ages" else game.state.banquet
		if slots[slot] == target[slot]:
			continue
		if target[slot] == empty:
			_use(game.room.find_interactable(id, slot))
			_use(game.room.find_interactable(id, slots.find(empty, slot + 1)))
		else:
			var source: int = slots.find(target[slot], slot + 1)
			_use(game.room.find_interactable(id, source))
			_use(game.room.find_interactable(id, slot))
			if not game.state.held_station.is_empty():
				_use(game.room.find_interactable(id, source))


## Stands in front of a target, looks at it, and reports whether the focus ray finds it.
## Waits up to `limit` frames for `condition`; returns whether it came true.
func _until(condition: Callable, limit: int) -> bool:
	for frame: int in range(limit):
		if condition.call():
			return true
		await process_frame
	return condition.call()


func _finish() -> void:
	print("Playable scene: %d checks, %d failures (stopped early)" % [checks, failures])
	quit(1)


func _reach(target: StudyInteractable, from_street_centre: bool = false) -> bool:
	if target == null:
		return false
	await _look_from_target(target, 1.3, from_street_centre)
	return game.room.player.target == target


## Stands `distance` away from a target, toward the room centre or across the street.
func _look_from_target(target: StudyInteractable, distance: float, from_street_centre: bool = false) -> void:
	var spot: Vector3 = target.global_position
	var away := Vector3(-signf(spot.x), 0, 0) if from_street_centre else Vector3(-spot.x, 0, -spot.z).normalized()
	if away.length() < 0.5:
		away = Vector3(0, 0, 1)
	var stand: Vector3 = spot + away * distance
	game.room.player.reset_at(Vector3(stand.x, 0.05, stand.z), 0, 0)
	game.room.player.camera.look_at(spot)
	await _physics_frames(4)


func _use(target: StudyInteractable) -> void:
	_expect(target != null, "Interactable exists")
	if target != null:
		game.room.player.interacted.emit(target, false)


func _button(key: String) -> Button:
	var wanted: String = TranslationServer.translate(key)
	for node: Node in game.overlay.find_children("*", "Button", true, false):
		var button := node as Button
		# Entries may carry arrows or a key reminder ("Lay It Down   ·   ESC").
		var label: String = button.text.get_slice("   ·   ", 0).replace("→", "").replace("←", "").strip_edges()
		if label == wanted and not button.disabled and button.is_visible_in_tree() and not button.is_queued_for_deletion():
			return button
	return null


func _press(key: String) -> void:
	var button: Button = _button(key)
	_expect(button != null, "Reachable UI button missing: " + key)
	if button != null:
		button.pressed.emit()


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)


func _frames(count: int) -> void:
	for index: int in range(count):
		await process_frame


func _physics_frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds/qa")
	root.get_texture().get_image().save_png("res://builds/qa/" + label + ".png")


func _measure_rendering(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var start: int = Time.get_ticks_usec()
	await _frames(120)
	var elapsed: float = float(Time.get_ticks_usec() - start) / 1000000.0
	print("Render sample — %s: %.1f FPS, %.2f ms/frame, viewport %s, %s" % [label, 120.0 / elapsed, elapsed * 1000.0 / 120.0, root.size, RenderingServer.get_video_adapter_name()])
