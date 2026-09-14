extends SceneTree

var checks: int = 0
var failures: int = 0
var solved_events: Array[String] = []


func _initialize() -> void:
	_test_slots_and_hands()
	_test_dependencies_and_rewards()
	_test_balcony_rules()
	_test_lock()
	_test_street()
	_test_partial_and_solved_roundtrips()
	_test_validation()
	_test_storage_recovery()
	print("Study logic: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)


## Arranges a slot station by picking pieces up and swapping them, as a player would.
func _arrange(state: StudyState, station: String, target: Array[int]) -> void:
	var slots: Array[int] = state.ages if station == "ages" else state.banquet
	var empty: int = -1 if station == "ages" else 0
	for slot: int in range(target.size()):
		if slots[slot] == target[slot]:
			continue
		var source: int = -1
		for other: int in range(slot + 1, slots.size()):
			if slots[other] == target[slot]:
				source = other
				break
		if target[slot] == empty:
			# Carry the misplaced piece to where the empty place currently is.
			state.use_slot(station, slot)
			state.use_slot(station, slots.find(empty, slot + 1))
		else:
			state.use_slot(station, source)
			state.use_slot(station, slot)
			if not state.held_station.is_empty():
				state.use_slot(station, source)


func _solve_ages(state: StudyState) -> void:
	_arrange(state, "ages", StudyState.SOLVED_AGES)


func _solve_mirror(state: StudyState) -> void:
	state.take("handle")
	state.insert_handle()
	for index: int in range(3):
		while state.mirror[index] != index:
			state.turn_mirror_dial(index)


func _solve_macbeth(state: StudyState) -> void:
	_arrange(state, "macbeth", StudyState.SOLVED_BANQUET)


func _solve_balcony(state: StudyState) -> void:
	state.take("sun")
	state.take("moon")
	for index: int in range(2):
		state.use_lantern(index)
		var target: int = StudyState.SUN_TARGET if index == 0 else StudyState.MOON_TARGET
		while state.lanterns[index] != target and not state.balcony_solved:
			state.use_lantern(index)


func _set_lock(state: StudyState, word: Array[int]) -> void:
	for index: int in [3, 2, 1, 0]:
		while state.lock[index] != word[index] and not state.door_open:
			state.turn_lock(index, 1)


func _test_slots_and_hands() -> void:
	var state := StudyState.new()
	state.use_slot("ages", 0)
	_expect(state.held_station == "ages" and state.held_piece == 3 and state.ages[0] == -1, "Picking up a token empties its socket")
	state.use_slot("ages", 1)
	_expect(state.ages[1] == 3 and state.held_piece == 5, "Placing onto an occupied socket swaps into the hand")
	state.use_slot("ages", 0)
	_expect(state.held_station.is_empty() and state.ages == [5, 3, 0, 6, 2, 1, 4], "Placing into the empty socket frees the hand")
	state.use_slot("macbeth", 2)
	_expect(state.to_data() == StudyState.new().to_data().merged({"ages": [5, 3, 0, 6, 2, 1, 4]}, true), "The empty banquet seat cannot be picked up")
	state.use_slot("ages", 4)
	state.use_slot("macbeth", 0)
	_expect(state.ages == [5, 3, 0, 6, 2, 1, 4] and state.held_station == "macbeth" and state.held_piece == 3, "A carried token returns home before touching another station")
	state.use_slot("macbeth", 9)
	state.use_slot("library", 0)
	_expect(state.held_piece == 3, "Unknown slots and stations are ignored")
	state.solved.connect(func(id: String) -> void: solved_events.append(id))
	_solve_ages(state)
	_expect(state.ages_solved and "ages" in solved_events and state.held_station.is_empty() and 3 in state.banquet, "Touching the dial returns the carried figure to its seat, then the life solves it")
	var locked: Array[int] = state.ages.duplicate()
	state.use_slot("ages", 0)
	_expect(state.ages == locked and state.held_station.is_empty(), "A solved dial ignores further moves")
	_solve_macbeth(state)
	_expect(state.macbeth_solved and state.held_station.is_empty() and state.banquet == StudyState.SOLVED_BANQUET, "Seating the banquet solves it with empty hands")
	_expect(solved_events.count("ages") == 1 and solved_events.count("macbeth") == 1, "Each mechanism reports completion once")


func _test_dependencies_and_rewards() -> void:
	var state := StudyState.new()
	var starting: Dictionary = state.to_data()
	_expect(not state.take("handle") and not state.take("moon") and not state.take("sun") and not state.take("crown"), "Rewards cannot be taken before they are revealed")
	_expect(not state.insert_handle() and not state.turn_mirror_dial(0), "The mirror needs its handle")
	_expect(state.use_lantern(0).is_empty() and state.use_lantern(1).is_empty(), "Lensless lanterns do nothing")
	state.finish()
	_expect(state.to_data() == starting, "Premature actions must not mutate progress")
	_solve_ages(state)
	_expect(state.letters() == ["H", "", "", ""] and state.item_waiting("handle") and state.inventory_keys().is_empty(), "The dial reveals H and a handle waiting in the drawer")
	_expect(state.take("handle") and not state.take("handle") and state.inventory_keys() == ["ITEM_HANDLE"], "The handle is pocketed exactly once")
	_expect(state.insert_handle() and not state.insert_handle() and state.installed_keys() == ["HANDLE_INSTALLED"], "The handle moves into its socket once")
	state.turn_mirror_dial(0)
	_expect(state.mirror == [4, 4, 3] and not state.mirror_solved, "Dials turn one symbol per use")
	_solve_mirror(state)
	_expect(state.mirror_solved and not state.turn_mirror_dial(1) and state.mirror == StudyState.SOLVED_MIRROR, "Matching the reflection solves Hamlet and locks the dials")
	_solve_macbeth(state)
	_expect(state.letters() == ["H", "E", "L", ""] and state.letter_count() == 3, "Letters follow the solved stories")
	_solve_balcony(state)
	_expect(state.balcony_solved and state.inventory_keys().is_empty() and state.installed_keys().size() == 3, "Both lenses end up fitted, none lost")
	_expect(state.letters() == ["H", "E", "L", "P"], "All four letters spell HELP")
	for attempt: int in range(5):
		state.discover("ages")
		state.next_hint(4)
	_expect(state.clues.count("ages") == 1 and state.hints[4] == 3 and state.next_hint(13) == 0, "Clues and hints are bounded and unique")
	state.discover("secret")
	_expect("secret" not in state.clues, "Unknown notes are ignored")


func _test_balcony_rules() -> void:
	var state := StudyState.new()
	_solve_ages(state)
	_solve_mirror(state)
	state.take("moon")
	_expect(state.use_lantern(1) == "fitted" and state.receivers_lit() == [false, false], "Fitting a lens does not turn the lantern")
	_expect(state.use_lantern(1) == "turned" and state.lanterns[1] == 0, "A fitted lantern turns and wraps through four targets")
	_expect(state.use_lantern(0).is_empty(), "The sun lantern stays dark without its own lens")
	state.use_lantern(1)
	state.use_lantern(1)
	_expect(state.receivers_lit() == [false, true] and not state.balcony_solved, "One lit balcony is not enough")
	_solve_macbeth(state)
	state.take("sun")
	state.use_lantern(0)
	state.use_lantern(0)
	_expect(state.lanterns[0] == 2 and state.receivers_lit() == [false, true], "The sun on the ivy balcony wakes nothing")
	state.use_lantern(0)
	state.use_lantern(0)
	_expect(state.balcony_solved and state.use_lantern(0).is_empty(), "Sun to rose and moon to ivy solves the balcony and locks it")


func _test_lock() -> void:
	var state := StudyState.new()
	state.turn_lock(0, -1)
	_expect(state.lock_text() == "ZAAA", "Wheels wrap backwards through the alphabet")
	_set_lock(state, [7, 4, 11, 16])
	_expect(state.lock_text() == "HELQ" and not state.door_open, "A wrong word keeps the door shut")
	state.turn_lock(3, -1)
	_expect(state.door_open and state.lock_text() == "HELP", "HELP opens the door")
	state.turn_lock(0, 1)
	state.turn_lock(7, 1)
	_expect(state.lock_text() == "HELP", "An open lock stays set")
	state.finish()
	state.finish()
	_expect(state.completed, "Reveal records completion idempotently")


func _complete_study(state: StudyState) -> void:
	_solve_ages(state)
	_solve_mirror(state)
	_solve_macbeth(state)
	_solve_balcony(state)
	_set_lock(state, StudyState.SOLVED_LOCK)
	state.finish()


## Hands each actor its prop by carrying pieces from wherever they are.
func _give_props(state: StudyState, targets: Array[int]) -> void:
	for index: int in range(3):
		var slot: int = StudyState.ACTOR_SLOTS[index]
		if state.props[slot] == targets[index]:
			continue
		state.use_slot("props", state.props.find(targets[index]))
		state.use_slot("props", slot)
		if not state.held_station.is_empty():
			state.use_slot("props", state.props.find(-1))


func _test_street() -> void:
	var state := StudyState.new()
	_complete_study(state)
	_expect(state.completed and not state.props_solved, "Leaving the study starts the streets")
	var events: Array[String] = []
	state.solved.connect(func(id: String) -> void: events.append(id))
	state.use_slot("props", 5)
	_expect(state.held_station.is_empty(), "An empty actor hand gives nothing")
	state.use_slot("props", 1)
	state.use_slot("props", 5)
	_expect(state.props[5] == 4 and state.held_station.is_empty(), "A prop can be placed in an actor's hand")
	_give_props(state, [0, 1, 3])
	_expect(not state.props_solved and state.actor_props() == [0, 1, 3], "The skull in the Friar's hand does not satisfy the playbill")
	_expect_roundtrip(state, "Props partly handed out")
	_give_props(state, StudyState.SOLVED_PROPS)
	_expect(state.props_solved and events == ["props"], "Rose, letter, and vial in the right hands lift the curtain")
	state.use_slot("props", 5)
	_expect(state.actor_props() == StudyState.SOLVED_PROPS and state.held_station.is_empty(), "Solved props stay in place")
	state.use_slot("shelf", state.shelf.find(4))
	_expect(state.add_to_brew() == "spoiled" and state.brew.is_empty() and -1 not in state.shelf, "A wrong first ingredient is spat back onto the shelf")
	_expect(state.add_to_brew().is_empty(), "Empty hands add nothing to the brew")
	state.stoke_fire()
	state.use_slot("shelf", state.shelf.find(0))
	_expect(state.add_to_brew() == "spoiled" and state.brew.is_empty(), "The right ingredient on the wrong fire is spat back")
	state.stoke_fire()
	state.stoke_fire()
	_expect(state.heat == 0, "The bellows cycle embers, flame, blaze, and back to embers")
	state.use_slot("shelf", state.shelf.find(0))
	_expect(state.add_to_brew() == "added" and state.brew == [0], "The first ingredient of the verse sinks in")
	_expect_roundtrip(state, "A brew in progress")
	state.use_slot("shelf", state.shelf.find(2))
	_expect(state.add_to_brew() == "spoiled" and state.brew.is_empty() and -1 not in state.shelf, "Skipping an ingredient returns every jar")
	var result: String = ""
	for step: int in range(StudyState.RECIPE.size()):
		while state.heat != StudyState.RECIPE_HEAT[step]:
			state.stoke_fire()
		state.use_slot("shelf", state.shelf.find(StudyState.RECIPE[step]))
		result = state.add_to_brew()
	_expect(result == "solved" and state.brew_solved and events.count("brew") == 1, "The verse's four ingredients, each on its own fire, complete the brew")
	_expect(not state.pull_bridge_lever() and not state.bridge_lowered, "The lever does nothing on the wrong date")
	state.turn_calendar(0, -10)
	state.turn_calendar(1, 45)
	_expect(state.calendar == [2, 14], "Calendar wheels wrap through months and days")
	_expect_roundtrip(state, "The date set on the engine")
	_expect(state.pull_bridge_lever() and state.bridge_lowered and events.count("bridge") == 1, "The Ides of March lowers the bridge")
	state.turn_calendar(1, 1)
	_expect(state.calendar == StudyState.IDES, "The engine's date is locked once the bridge is down")
	_expect(state.act() == "street", "The streets hold the run until the bridge falls")
	state.fall_bridge()
	_expect(state.bridge_fallen and state.act() == "sewer", "Walking onto London Bridge drops the run into the sewer")
	_expect_roundtrip(state, "Fallen into the sewer")
	_expect(not state.mark_crypt(0) and state.crypts == [0, 0, 0, 0], "Crypts cannot be marked without the brush")
	_expect(not state.climb_out(), "The ladder is barred until the gate opens")
	_expect(state.take("brush") and state.has_item("brush"), "The brush is taken from the paint pot")
	state.mark_crypt(1)
	state.mark_crypt(0)
	_expect(state.crypts == [1, 1, 0, 0] and not state.sewer_solved, "A cross on the crown crypt is wrong")
	_expect_roundtrip(state, "Crosses partly painted")
	state.mark_crypt(1)
	_expect(state.crypts == [1, 0, 0, 0], "Using a marked door again scrubs its cross")
	state.mark_crypt(2)
	_expect(state.sewer_solved and events.count("plague") == 1, "Crosses on the rose and ivy crypts open the gate")
	_expect(not state.mark_crypt(3) and state.crypts == StudyState.SOLVED_CRYPTS, "Solved crypts stay marked")
	_expect(state.has_item("brush"), "The brush is never used up")
	_expect(state.climb_out() and state.act() == "ripper", "Climbing the ladder reaches the Ripper's streets")
	state.finish_ripper()
	_expect(not state.ripper_completed, "The false exit must be solved before finishing")
	_expect(not state.close_shadow_shutter(1), "An unlit solid passage stays locked")
	state.turn_shadow_lamp()
	_expect_roundtrip(state, "Inspection lamp aimed at the middle exit")
	_expect(not state.close_shadow_shutter(0), "A painted exit cannot open")
	_expect(not state.report_watch(StudyState.WATCH_ROUTE), "A guessed route without sightings is rejected")
	for place: String in StudyState.WATCH_ROUTE:
		state.observe_watch(place)
	_expect(state.report_watch(StudyState.WATCH_ROUTE) and events.count("shadow") == 1, "Verified route opens the police cordon")
	state.turn_shadow_lamp()
	_expect(state.shadow_lamp == 1 and not state.close_shadow_shutter(1), "Solved lantern and shutter remain fixed")
	var legacy: Dictionary = state.to_data()
	legacy.erase("shadow_lamp")
	legacy.erase("shadow_solved")
	legacy.erase("celestial")
	legacy.hints.resize(9)
	_expect(StudyState.from_data(legacy) != null, "Older unfinished runs migrate without losing their chapter")
	state.finish_ripper()
	state.finish_ripper()
	_expect(state.ripper_completed, "The end of the current build is recorded once")
	_expect_roundtrip(state, "The Uncast Shadow's street")


func _test_partial_and_solved_roundtrips() -> void:
	var state := StudyState.new()
	state.use_slot("ages", 3)
	state.discover("note")
	state.discover("page_bed")
	state.discover("ages")
	state.next_hint(0)
	_expect_roundtrip(state, "A token in hand, notes, and hint progress")
	state.use_slot("macbeth", 0)
	_expect_roundtrip(state, "A banquet figure in hand after returning the token")
	state.use_slot("macbeth", 2)
	_solve_ages(state)
	_expect_roundtrip(state, "Handle waiting in the drawer")
	state.take("handle")
	_expect_roundtrip(state, "Handle in pocket")
	state.insert_handle()
	state.turn_mirror_dial(2)
	_expect_roundtrip(state, "Socket and partial dials")
	_solve_mirror(state)
	_solve_macbeth(state)
	state.take("moon")
	state.use_lantern(1)
	_expect_roundtrip(state, "One lens fitted, one waiting")
	_solve_balcony(state)
	state.turn_lock(0, 3)
	_expect_roundtrip(state, "All letters and a partial lock")
	_set_lock(state, StudyState.SOLVED_LOCK)
	_expect_roundtrip(state, "Open door")
	state.finish()
	_expect_roundtrip(state, "Completed reveal")


func _expect_roundtrip(state: StudyState, label: String) -> void:
	var restored: StudyState = StudyState.from_data(JSON.parse_string(JSON.stringify(state.to_data())))
	_expect(restored != null and restored.to_data() == state.to_data(), label + " must roundtrip through JSON")
	if restored != null:
		_expect(restored.inventory_keys() == state.inventory_keys() and restored.letters() == state.letters(), label + " preserves items and letters")


func _test_validation() -> void:
	var good: Dictionary = StudyState.new().to_data()
	for bad: Variant in [null, [], "text", 3, true]:
		_expect(StudyState.from_data(bad) == null, "Reject non-dictionary save")
	var older: Dictionary = good.duplicate(true)
	older.merge({"schema": 4, "content": "london-chapter-3"}, true)
	_expect(StudyState.from_data(older) == null, "Reject saves from the interface-driven build")
	var variants: Array[Dictionary] = [
		{"schema": 99}, {"content": "release"}, {"ages": [0, 0, 1, 2, 3, 4, 5]},
		{"ages": [0, 1, 2, 3, 4, 5, 7]}, {"ages": [0, 1, 2, 3, 4, 5, 5.5]}, {"ages": [-1, 1, 2, 3, 4, 5, 6]},
		{"ages": [true, 1, 2, 3, 4, 5, 6]}, {"ages": [0, 1]}, {"mirror": [0, 1, 5]},
		{"banquet": [0, 0, 1, 2]}, {"banquet": [1, 1, 2, 3]}, {"banquet": [0, 1, 2]},
		{"lanterns": [0, 4]}, {"lanterns": [-1, 0]}, {"lanterns": "rose"}, {"lock": [0, 0, 0, 26]},
		{"lock": [7, 4, 11, 15]}, {"hints": [4, 0, 0, 0, 0, 0, 0, 0]}, {"hints": [0, 0, 0, 0, 0]},
		{"props_solved": true}, {"props": [0, 1, 2, 3, 3, -1, -1, -1]}, {"brew": [1]}, {"brew": [0, 1, 2, 3]},
		{"brew_solved": true}, {"bridge_lowered": true}, {"calendar": [12, 0]}, {"calendar": [2, 31]},
		{"shelf": [0, 0, 1, 2, 3, 4]}, {"bridge_fallen": true}, {"crypts": [1, 0, 0, 0]}, {"crypts": [2, 0, 0, 0]},
		{"sewer_solved": true}, {"climbed_out": true}, {"ripper_completed": true}, {"taken": ["brush"]},
		{"held_station": "ages", "held_piece": 3}, {"held_station": "attic"}, {"held_piece": 2},
		{"held_station": "ages", "held_piece": 3, "ages": [-1, 5, 0, 6, 2, 3, 4]},
		{"taken": ["handle"]}, {"taken": ["crown"]}, {"clues": ["unknown"]}, {"clues": ["note", "note"]},
		{"clues": "note"}, {"ages_solved": 1}, {"ages_solved": true}, {"handle_inserted": true},
		{"mirror_solved": true}, {"macbeth_solved": true}, {"sun_lens_inserted": true},
		{"moon_lens_inserted": true}, {"balcony_solved": true}, {"door_open": true}, {"completed": true},
	]
	for variant: Dictionary in variants:
		var broken: Dictionary = good.duplicate(true)
		broken.merge(variant, true)
		_expect(StudyState.from_data(broken) == null, "Reject malformed/impossible state: " + str(variant))


func _test_storage_recovery() -> void:
	var path: String = "user://test_study_%s.json" % Time.get_ticks_usec()
	var store := SaveStore.new(path)
	_expect(store.load_run() == null and store.message_key.is_empty(), "Missing save starts cleanly")
	var state := StudyState.new()
	_expect(store.save_run(state), "Initial save succeeds")
	state.use_slot("ages", 0)
	state.use_slot("ages", 1)
	_expect(store.save_run(state), "Second write creates a backup")
	var loaded: StudyState = store.load_run()
	_expect(loaded != null and loaded.ages == state.ages and loaded.held_piece == state.held_piece, "Load reads the latest committed arrangement and hand")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	loaded = store.load_run()
	_expect(loaded != null and store.message_key == "SAVE_RECOVERED", "Damaged primary recovers a valid backup")
	_expect(loaded != null and loaded.ages == StudyState.new().ages, "Backup is the previous good state")
	_expect(store.save_run(state), "Can save after recovery")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken again")
	file.close()
	loaded = store.load_run()
	_expect(loaded != null, "Corrupt primary never overwrites the good backup")
	file = FileAccess.open(path + ".bak", FileAccess.WRITE)
	file.store_string("[]")
	file.close()
	_expect(store.load_run() == null and store.message_key == "SAVE_DAMAGED", "Two corrupt copies produce a recovery message")
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	var unwritable := SaveStore.new("user://missing_test_directory/save.json")
	_expect(not unwritable.save_run(state) and unwritable.message_key == "SAVE_FAILED", "I/O failure is reported")
