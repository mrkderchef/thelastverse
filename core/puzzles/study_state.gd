class_name StudyState
extends RefCounted
## Serializable chapter state: the study (Act I), the bright streets to London Bridge
## (Act II), and, once the bridge falls, the plague sewer and the Ripper's streets (Act III).
## Every puzzle is solved by direct interaction. In the study each solved puzzle reveals one
## letter and the door's lock opens on H-E-L-P; the streets have three gates to London Bridge.
## Rewards derive from completion and socket flags, so reloads never duplicate or lose items.

signal changed
## Emitted once when a mechanism completes: a PUZZLES id.
signal solved(id: String)

const SCHEMA := 5
const CONTENT_VERSION := "london-chapter-4"
const PUZZLES: Array[String] = ["ages", "mirror", "macbeth", "balcony", "lock", "props", "brew", "bridge", "plague", "shadow", "celestial", "house", "railway"]
const NOTES: Array[String] = ["note", "booklet", "card", "sheet", "diagram", "page_bed", "page_cues", "page_costumes", "page_window", "playbill", "incantation", "tender_note", "soothsayer", "almanac", "warrant", "plague_bill", "shadow_letter", "confession", "dyer_record", "star_rules", "star_covenant", "star_walk", "star_atlas", "railway_history", "house_song", "train_manual", "witch_scrap_0", "witch_scrap_1", "witch_scrap_2"]
const LORE: Array[String] = ["page_bed", "page_cues", "page_costumes", "page_window", "plague_bill", "shadow_letter", "confession", "dyer_record", "star_rules", "star_covenant", "star_walk", "star_atlas", "railway_history", "house_song", "train_manual"]
const LETTERS: Array[String] = ["H", "E", "L", "P"]
const SOLVED_AGES: Array[int] = [0, 1, 2, 3, 4, 5, 6]
const SOLVED_MIRROR: Array[int] = [0, 1, 2]
## Seats hold 0 empty, 1 crowned host, 2 companion, 3 guest.
const SOLVED_BANQUET: Array[int] = [0, 1, 2, 3]
## Lantern targets: 0 rose balcony, 1 curtain, 2 ivy balcony, 3 empty stalls.
const TARGET_COUNT := 4
const SUN_TARGET := 0
const MOON_TARGET := 2
const SYMBOL_COUNT := 5
## H, E, L, P as alphabet positions.
const SOLVED_LOCK: Array[int] = [7, 4, 11, 15]
const ITEMS: Array[String] = ["handle", "moon", "sun", "brush"]
const BOOLEANS: Array[String] = ["ages_solved", "handle_inserted", "mirror_solved", "macbeth_solved", "sun_lens_inserted", "moon_lens_inserted", "balcony_solved", "door_open", "completed", "props_solved", "brew_solved", "bridge_lowered", "bridge_fallen", "sewer_solved", "climbed_out", "ripper_completed"]
## Plague crypt doors: 0 rose (Capulet), 1 crown, 2 ivy (Montague), 3 bell. Mark the feud.
const SOLVED_CRYPTS: Array[int] = [1, 0, 1, 0]
## Balcony Lane: slots 0-4 are the prop cart, 5 Romeo's hand, 6 Juliet's, 7 Friar Laurence's.
## Props: 0 rose, 1 letter, 2 vial, 3 skull, 4 crown.
const ACTOR_SLOTS: Array[int] = [5, 6, 7]
const SOLVED_PROPS: Array[int] = [0, 1, 2]
## Witches' Square shelf ingredients: 0 eye of newt, 1 toe of frog, 2 wool of bat,
## 3 tongue of dog, 4 raven feather, 5 mandrake root. The incantation names 0-3 in order.
const RECIPE: Array[int] = [0, 1, 2, 3]
## How hot the fire must burn as each ingredient goes in: 0 embers, 1 steady flame, 2 roaring.
## The three witches' scraps give these: eye at embers, toe roaring, wool steady, tongue roaring.
const RECIPE_HEAT: Array[int] = [0, 2, 1, 2]
## Bridge engine calendar [month 0-11, day 0-30]: the Ides of March.
const IDES: Array[int] = [2, 14]

var ages: Array[int] = [3, 5, 0, 6, 2, 1, 4]
var mirror: Array[int] = [3, 4, 3]
var banquet: Array[int] = [3, 2, 0, 1]
var lanterns: Array[int] = [1, 3]
var lock: Array[int] = [0, 0, 0, 0]
var props: Array[int] = [2, 4, 0, 3, 1, -1, -1, -1]
var shelf: Array[int] = [3, 5, 0, 2, 4, 1]
var brew: Array[int] = []
## The fire under the cauldron, raised by the bellows: 0 embers, 1 steady flame, 2 roaring.
var heat: int = 0
var calendar: Array[int] = [0, 0]
var crypts: Array[int] = [0, 0, 0, 0]
## A puzzle piece in the player's hand: its station ("ages" or "macbeth") and piece value.
var held_station: String = ""
var held_piece: int = -1
var taken: Array[String] = []
var ages_solved: bool = false
var handle_inserted: bool = false
var mirror_solved: bool = false
var macbeth_solved: bool = false
var sun_lens_inserted: bool = false
var moon_lens_inserted: bool = false
var balcony_solved: bool = false
var door_open: bool = false
## The study has been left; the chapter continues in the streets.
var completed: bool = false
var props_solved: bool = false
var brew_solved: bool = false
var bridge_lowered: bool = false
## London Bridge has fallen with the player on it; the chapter continues in the sewer.
var bridge_fallen: bool = false
var sewer_solved: bool = false
var climbed_out: bool = false
var ripper_completed: bool = false
var clues: Array[String] = []
var hints: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var celestial := CelestialState.new()
var shadow_lamp: int = 0
var shadow_solved: bool = false
var watch_seen: Array[String] = []
## The Shadow's circuit from the Watch Post, six stops along the Whitechapel streets.
const WATCH_ROUTE: Array[String] = ["YARD", "CROSS", "CHAPEL", "WELL", "TANNERY", "GATE"]
## Every landmark on the constable's street plan, including two he never visits.
const WATCH_PLACES: Array[String] = ["YARD", "PUB", "CROSS", "CHAPEL", "WELL", "MARKET", "TANNERY", "GATE"]

func observe_watch(place: String) -> void:
	if climbed_out and place in WATCH_ROUTE and place not in watch_seen:
		watch_seen.append(place)
		changed.emit()

func report_watch(route: Array[String]) -> bool:
	if shadow_solved:
		return true
	if not climbed_out or route != WATCH_ROUTE or watch_seen.size() != WATCH_ROUTE.size():
		return false
	shadow_lamp = 1
	shadow_solved = true
	changed.emit()
	solved.emit("shadow")
	return true



func _init() -> void:
	_connect_celestial()


func _connect_celestial() -> void:
	celestial.changed.connect(_celestial_changed)
	celestial.solved_now.connect(_celestial_solved)


func _celestial_changed() -> void:
	changed.emit()


func _celestial_solved() -> void:
	solved.emit("celestial")


func ring_house_bell(index: int) -> String:
	if not ripper_completed or "dyer_record" not in clues:
		return "read"
	var result: String = celestial.house_bell(index)
	if result == "solved":
		solved.emit("house")
	return result


func enter_farm() -> bool:
	if not ripper_completed or "dyer_record" not in clues or not celestial.house_solved or celestial.entered:
		return false
	celestial.entered = true
	discover("celestial")
	changed.emit()
	return true


func enter_railway() -> bool:
	if not celestial.solved or celestial.railway_entered:
		return false
	celestial.railway_entered = true
	changed.emit()
	return true


func discover(id: String) -> void:
	if (id in NOTES or id in PUZZLES) and id not in clues:
		clues.append(id)
		changed.emit()


## Take or place a piece at a slot station: "ages" dial sockets, "macbeth" banquet seats,
## "props" cart and actor hands, or the "shelf" of ingredients.
## Placing onto an occupied slot swaps the pieces; a piece from another station returns home first.
func use_slot(station: String, index: int) -> void:
	var slots: Array[int] = _slots(station)
	if slots.is_empty() or index < 0 or index >= slots.size():
		return
	if not held_station.is_empty() and held_station != station:
		_return_held()
		if _station_solved(station):
			changed.emit()
			return
	if _station_solved(station):
		return
	var empty: int = _empty_value(station)
	if held_station.is_empty():
		if slots[index] == empty:
			return
		held_station = station
		held_piece = slots[index]
		slots[index] = empty
	else:
		var existing: int = slots[index]
		slots[index] = held_piece
		if existing == empty:
			held_station = ""
			held_piece = -1
		else:
			held_piece = existing
	_check_arrangement(station)
	# A spare piece still in hand when the station completes goes back where it came from.
	if held_station == station and _station_solved(station):
		_return_held()
	changed.emit()


func turn_mirror_dial(index: int) -> bool:
	if not handle_inserted or mirror_solved or index < 0 or index > 2:
		return false
	mirror[index] = posmod(mirror[index] + 1, SYMBOL_COUNT)
	if mirror == SOLVED_MIRROR:
		mirror_solved = true
		changed.emit()
		solved.emit("mirror")
	else:
		changed.emit()
	return true


## Drops the carried ingredient into the cauldron. A wrong order spits everything back.
func add_to_brew() -> String:
	if brew_solved or held_station != "shelf":
		return ""
	brew.append(held_piece)
	held_station = ""
	held_piece = -1
	if brew != RECIPE.slice(0, brew.size()) or heat != RECIPE_HEAT[brew.size() - 1]:
		for piece: int in brew:
			shelf[shelf.find(-1)] = piece
		brew.clear()
		changed.emit()
		return "spoiled"
	if brew.size() == RECIPE.size():
		brew_solved = true
		changed.emit()
		solved.emit("brew")
		return "solved"
	changed.emit()
	return "added"


## Works the bellows: embers, then a steady flame, then a roaring blaze, then back to embers.
func stoke_fire() -> void:
	if brew_solved:
		return
	heat = (heat + 1) % 3
	changed.emit()


func turn_calendar(index: int, step: int) -> void:
	if bridge_lowered or index < 0 or index > 1:
		return
	calendar[index] = posmod(calendar[index] + step, 12 if index == 0 else 31)
	changed.emit()


func pull_bridge_lever() -> bool:
	if bridge_lowered:
		return true
	if calendar != IDES:
		return false
	bridge_lowered = true
	changed.emit()
	solved.emit("bridge")
	return true


func fall_bridge() -> void:
	if bridge_lowered and not bridge_fallen:
		bridge_fallen = true
		changed.emit()


## Paints or scrubs a plague cross on a crypt door. Needs the brush from the paint pot.
func mark_crypt(index: int) -> bool:
	if sewer_solved or index < 0 or index > 3 or not has_item("brush"):
		return false
	crypts[index] = 1 - crypts[index]
	if crypts == SOLVED_CRYPTS:
		sewer_solved = true
		changed.emit()
		solved.emit("plague")
	else:
		changed.emit()
	return true


func climb_out() -> bool:
	if not sewer_solved:
		return false
	if not climbed_out:
		climbed_out = true
		changed.emit()
	return true


func turn_shadow_lamp() -> void:
	if not climbed_out or shadow_solved:
		return
	shadow_lamp = (shadow_lamp + 1) % 3
	changed.emit()


func close_shadow_shutter(index: int) -> bool:
	if not climbed_out or shadow_solved or index != 1 or shadow_lamp != 1 or watch_seen.size() != WATCH_ROUTE.size():
		return false
	shadow_solved = true
	changed.emit()
	solved.emit("shadow")
	return true


func finish_ripper() -> void:
	if climbed_out and shadow_solved and not ripper_completed:
		ripper_completed = true
		changed.emit()


## Which scene the run belongs in: "study", "street", "sewer", or "ripper".
func act() -> String:
	if celestial.railway_entered:
		return "metropolitan"
	if celestial.entered:
		return "nursery"
	if ripper_completed:
		return "courtyard"
	if climbed_out:
		return "ripper"
	if bridge_fallen:
		return "sewer"
	return "street" if completed else "study"


func slot_values(station: String) -> Array[int]:
	return _slots(station)


func empty_value(station: String) -> int:
	return _empty_value(station)


func station_solved(station: String) -> bool:
	return _station_solved(station)


func take(item: String) -> bool:
	if item not in ITEMS or item in taken or not _item_available(item):
		return false
	taken.append(item)
	changed.emit()
	return true


func insert_handle() -> bool:
	if handle_inserted or not has_item("handle"):
		return false
	handle_inserted = true
	changed.emit()
	return true


## Fits the matching lens if it is in the player's pockets, otherwise turns a fitted lantern.
func use_lantern(index: int) -> String:
	if balcony_solved or index < 0 or index > 1:
		return ""
	var lens: String = "sun" if index == 0 else "moon"
	var fitted: bool = sun_lens_inserted if index == 0 else moon_lens_inserted
	if not fitted:
		if not has_item(lens):
			return ""
		if index == 0:
			sun_lens_inserted = true
		else:
			moon_lens_inserted = true
		_check_balcony()
		return "fitted"
	lanterns[index] = posmod(lanterns[index] + 1, TARGET_COUNT)
	_check_balcony()
	return "turned"


## [rose receiver lit, ivy receiver lit]. Each receiver wakes only for its own fitted lantern.
func receivers_lit() -> Array[bool]:
	return [sun_lens_inserted and lanterns[0] == SUN_TARGET, moon_lens_inserted and lanterns[1] == MOON_TARGET]


func turn_lock(index: int, step: int) -> void:
	if door_open or index < 0 or index > 3:
		return
	lock[index] = posmod(lock[index] + step, 26)
	if lock == SOLVED_LOCK:
		door_open = true
		changed.emit()
		solved.emit("lock")
	else:
		changed.emit()


func finish() -> void:
	if door_open and not completed:
		completed = true
		changed.emit()


func next_hint(puzzle: int) -> int:
	if puzzle < 0 or puzzle >= hints.size():
		return 0
	hints[puzzle] = mini(hints[puzzle] + 1, 3)
	changed.emit()
	return hints[puzzle]


func lock_text() -> String:
	var text: String = ""
	for value: int in lock:
		text += char(65 + value)
	return text


## Letters revealed so far, in lock order; unrevealed positions are empty strings.
func letters() -> Array[String]:
	var flags: Array[bool] = [ages_solved, mirror_solved, macbeth_solved, balcony_solved]
	var result: Array[String] = []
	for index: int in range(4):
		result.append(LETTERS[index] if flags[index] else "")
	return result


func letter_count() -> int:
	return int(ages_solved) + int(mirror_solved) + int(macbeth_solved) + int(balcony_solved)


func has_item(item: String) -> bool:
	if item not in taken:
		return false
	match item:
		"handle": return not handle_inserted
		"moon": return not moon_lens_inserted
		"brush": return true
		_: return not sun_lens_inserted


## Rewards lying in an opened compartment, waiting to be picked up.
func item_waiting(item: String) -> bool:
	return item not in taken and _item_available(item)


func inventory_keys() -> Array[String]:
	var result: Array[String] = []
	for pair: Array in [["handle", "ITEM_HANDLE"], ["moon", "ITEM_MOON"], ["sun", "ITEM_SUN"], ["brush", "ITEM_BRUSH"]]:
		if has_item(pair[0]):
			result.append(pair[1])
	return result


func installed_keys() -> Array[String]:
	var result: Array[String] = []
	if handle_inserted:
		result.append("HANDLE_INSTALLED")
	if moon_lens_inserted:
		result.append("MOON_INSTALLED")
	if sun_lens_inserted:
		result.append("SUN_INSTALLED")
	return result


func to_data() -> Dictionary:
	return {
		"celestial": celestial.to_data(),
		"watch_seen": watch_seen.duplicate(),
		"shadow_lamp": shadow_lamp, "shadow_solved": shadow_solved,
		"schema": SCHEMA, "content": CONTENT_VERSION,
		"ages": ages.duplicate(), "mirror": mirror.duplicate(), "banquet": banquet.duplicate(),
		"lanterns": lanterns.duplicate(), "lock": lock.duplicate(),
		"props": props.duplicate(), "shelf": shelf.duplicate(), "brew": brew.duplicate(), "heat": heat,
		"calendar": calendar.duplicate(), "props_solved": props_solved, "brew_solved": brew_solved,
		"bridge_lowered": bridge_lowered, "bridge_fallen": bridge_fallen, "crypts": crypts.duplicate(),
		"sewer_solved": sewer_solved, "climbed_out": climbed_out, "ripper_completed": ripper_completed,
		"held_station": held_station, "held_piece": held_piece, "taken": taken.duplicate(),
		"ages_solved": ages_solved, "handle_inserted": handle_inserted, "mirror_solved": mirror_solved,
		"macbeth_solved": macbeth_solved, "sun_lens_inserted": sun_lens_inserted,
		"moon_lens_inserted": moon_lens_inserted, "balcony_solved": balcony_solved,
		"door_open": door_open, "completed": completed,
		"clues": clues.duplicate(), "hints": hints.duplicate(),
	}


static func from_data(data: Variant) -> StudyState:
	if not data is Dictionary:
		return null
	if data.get("schema") != SCHEMA or data.get("content") != CONTENT_VERSION:
		return null
	# Schema 5 saves from before the false-exit puzzle remain resumable.
	data = data.duplicate(true)
	if not data.has("shadow_lamp") and not data.has("shadow_solved"):
		data["shadow_lamp"] = 1 if data.get("ripper_completed", false) else 0
		data["shadow_solved"] = data.get("ripper_completed", false)
		if data.get("hints") is Array and data.hints.size() == 9:
			data.hints.append(0)
	# Saves from before the bellows start with the fire at embers.
	if not data.has("heat"):
		data["heat"] = 0
	if not data.has("celestial"):
		data["celestial"] = {"entered": false, "bearings": [0, 0, 0, 0], "aligned": false, "steps": [], "solved": false, "railway_entered": false, "completed": false}
		if data.get("hints") is Array and data.hints.size() == 10:
			data.hints.append(0)
	if data.get("hints") is Array and data.hints.size() == 11 and data.get("celestial") is Dictionary and not data.celestial.has("house_steps"):
		data.hints.append(0)
		data.hints.append(0)
	var saved_celestial := CelestialState.from_data(data.get("celestial"))
	if saved_celestial == null:
		return null
	if not data.get("shadow_solved") is bool or not _valid_numbers([data.get("shadow_lamp")], 1, 2, 0):
		return null
	for key: String in BOOLEANS:
		if not data.get(key) is bool:
			return null
	for pair: Array in [["ages", 7, 6, -1], ["mirror", 3, SYMBOL_COUNT - 1, 0], ["banquet", 4, 3, 0], ["lanterns", 2, TARGET_COUNT - 1, 0], ["lock", 4, 25, 0], ["hints", 13, 3, 0], ["props", 8, 4, -1], ["shelf", 6, 5, -1], ["calendar", 2, 30, 0], ["crypts", 4, 1, 0]]:
		if not _valid_numbers(data.get(pair[0]), pair[1], pair[2], pair[3]):
			return null
	var station: Variant = data.get("held_station")
	var piece: Variant = data.get("held_piece")
	if not _valid_numbers(data.get("brew"), -1, 5, 0) or not _valid_numbers([data.get("heat")], 1, 2, 0) or (data.calendar as Array)[0] > 11:
		return null
	if not station is String or station not in ["", "ages", "macbeth", "props", "shelf"] or not (piece is int or piece is float) or piece != int(piece):
		return null
	var restored := StudyState.new()
	restored.celestial = saved_celestial
	restored._connect_celestial()
	for key: String in ["clues", "taken"]:
		var entries: Variant = data.get(key)
		if not entries is Array:
			return null
		var seen: Array[String] = []
		for entry: Variant in entries:
			var allowed: Array[String] = ITEMS if key == "taken" else NOTES + PUZZLES
			if not entry is String or entry not in allowed or entry in seen:
				return null
			seen.append(entry)
		(restored.get(key) as Array).assign(seen)
	restored.ages.assign(data.ages)
	restored.mirror.assign(data.mirror)
	restored.banquet.assign(data.banquet)
	restored.lanterns.assign(data.lanterns)
	restored.lock.assign(data.lock)
	restored.props.assign(data.props)
	restored.shelf.assign(data.shelf)
	restored.brew.assign(data.brew)
	restored.heat = int(data.heat)
	restored.calendar.assign(data.calendar)
	restored.crypts.assign(data.crypts)
	restored.hints.assign(data.hints)
	var sightings: Variant = data.get("watch_seen", [])
	if not sightings is Array or sightings.size() > WATCH_PLACES.size():
		return null
	for place: Variant in sightings:
		if not place is String or place in restored.watch_seen:
			return null
		# Sightings from the earlier four-stop circuit that are no longer on his road are dropped.
		if place in WATCH_ROUTE:
			restored.watch_seen.append(place)
	if not restored.watch_seen.is_empty() and not data.climbed_out:
		return null
	restored.shadow_lamp = int(data.shadow_lamp)
	restored.shadow_solved = data.shadow_solved
	if (restored.shadow_solved and (not data.climbed_out or restored.shadow_lamp != 1)) or (data.ripper_completed and not restored.shadow_solved) or (restored.shadow_lamp != 0 and not data.climbed_out):
		return null
	restored.held_station = station
	restored.held_piece = int(piece)
	for key: String in BOOLEANS:
		restored.set(key, data[key])
	# Every piece must exist exactly once, either in a slot or in the hand.
	if not restored._pieces_complete("ages", [0, 1, 2, 3, 4, 5, 6]) or not restored._pieces_complete("macbeth", [1, 2, 3]) or not restored._pieces_complete("props", [0, 1, 2, 3, 4]):
		return null
	var ingredients: Array[int] = restored.brew.duplicate()
	for value: int in restored.shelf:
		if value >= 0:
			ingredients.append(value)
	if restored.held_station == "shelf":
		ingredients.append(restored.held_piece)
	ingredients.sort()
	if ingredients != [0, 1, 2, 3, 4, 5] or restored.brew != RECIPE.slice(0, restored.brew.size()):
		return null
	# Reject impossible dependency chains instead of silently losing items.
	if restored.ages_solved != (restored.ages == SOLVED_AGES):
		return null
	if restored.macbeth_solved != (restored.banquet == SOLVED_BANQUET):
		return null
	if restored.mirror_solved and (not restored.handle_inserted or restored.mirror != SOLVED_MIRROR):
		return null
	if ("handle" in restored.taken and not restored.ages_solved) or (restored.handle_inserted and "handle" not in restored.taken):
		return null
	if ("moon" in restored.taken and not restored.mirror_solved) or (restored.moon_lens_inserted and "moon" not in restored.taken):
		return null
	if ("sun" in restored.taken and not restored.macbeth_solved) or (restored.sun_lens_inserted and "sun" not in restored.taken):
		return null
	if restored.balcony_solved != (restored.receivers_lit() == [true, true]):
		return null
	if restored.door_open != (restored.lock == SOLVED_LOCK):
		return null
	if restored.completed and not restored.door_open:
		return null
	if restored.props_solved != (restored.actor_props() == SOLVED_PROPS) or (restored.props_solved and not restored.completed):
		return null
	if restored.brew_solved != (restored.brew == RECIPE) or (restored.brew_solved and not restored.props_solved):
		return null
	if restored.bridge_lowered and (restored.calendar != IDES or not restored.brew_solved):
		return null
	if restored.bridge_fallen and not restored.bridge_lowered:
		return null
	if ("brush" in restored.taken and not restored.bridge_fallen) or (restored.crypts != [0, 0, 0, 0] and "brush" not in restored.taken):
		return null
	if restored.sewer_solved != (restored.crypts == SOLVED_CRYPTS):
		return null
	if (restored.climbed_out and not restored.sewer_solved) or (restored.ripper_completed and not restored.climbed_out):
		return null
	if not restored.celestial.house_steps.is_empty() and (not restored.ripper_completed or "dyer_record" not in restored.clues):
		return null
	if restored.celestial.entered and (not restored.ripper_completed or "dyer_record" not in restored.clues):
		return null
	return restored


func actor_props() -> Array[int]:
	var result: Array[int] = []
	for slot: int in ACTOR_SLOTS:
		result.append(props[slot])
	return result


func _slots(station: String) -> Array[int]:
	match station:
		"ages": return ages
		"macbeth": return banquet
		"props": return props
		"shelf": return shelf
	return []


func _empty_value(station: String) -> int:
	return 0 if station == "macbeth" else -1


func _station_solved(station: String) -> bool:
	match station:
		"ages": return ages_solved
		"macbeth": return macbeth_solved
		"props": return props_solved
		"shelf": return brew_solved
	return true


func _return_held() -> void:
	var slots: Array[int] = _slots(held_station)
	slots[slots.find(_empty_value(held_station))] = held_piece
	var station: String = held_station
	held_station = ""
	held_piece = -1
	_check_arrangement(station)


func _check_arrangement(station: String) -> void:
	if station == "ages" and not ages_solved and ages == SOLVED_AGES:
		ages_solved = true
		solved.emit("ages")
	elif station == "macbeth" and not macbeth_solved and banquet == SOLVED_BANQUET:
		macbeth_solved = true
		solved.emit("macbeth")
	elif station == "props" and not props_solved and actor_props() == SOLVED_PROPS:
		props_solved = true
		solved.emit("props")


func _check_balcony() -> void:
	if receivers_lit() == [true, true]:
		balcony_solved = true
		changed.emit()
		solved.emit("balcony")
	else:
		changed.emit()


func _item_available(item: String) -> bool:
	match item:
		"handle": return ages_solved
		"moon": return mirror_solved
		"brush": return bridge_fallen
		_: return macbeth_solved


func _pieces_complete(station: String, expected: Array[int]) -> bool:
	var pieces: Array[int] = []
	for value: int in _slots(station):
		if value != _empty_value(station):
			pieces.append(value)
	if held_station == station:
		pieces.append(held_piece)
	elif held_station.is_empty() and held_piece != -1:
		return false
	pieces.sort()
	return pieces == expected


## `count` of -1 accepts any length up to `maximum` + 1 entries.
static func _valid_numbers(value: Variant, count: int, maximum: int, minimum: int) -> bool:
	if not value is Array or (count >= 0 and value.size() != count) or (count < 0 and value.size() > maximum + 1):
		return false
	for entry: Variant in value:
		if not (entry is int or entry is float):
			return false
		if not is_finite(float(entry)) or entry != int(entry) or entry < minimum or entry > maximum:
			return false
	return true
