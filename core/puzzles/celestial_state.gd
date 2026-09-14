class_name CelestialState
extends RefCounted
## The nursery's three deductions: counts -> reflected bearings -> a walked glyph order.
signal changed
signal aligned_now
signal solved_now
const HOUSE_SONG: Array[int] = [2, 0, 3, 1, 0]
const COUNTS: Array[int] = [3, 4, 5, 6, 7, 8]
const GLYPHS: Array[String] = ["TRIANGLE", "DIAMOND", "CROWN", "KEY", "EYE", "SERPENT"]
const KEEPERS: Array[String] = ["SUN", "MOON", "TIDE", "ASH"]
## Moon and Ash watch over their shoulders. The others look forward.
const REFLECTED: Array[bool] = [false, true, false, true]
const TARGETS: Array[int] = [2, 4, 0, 5]
const ORIENTATIONS: Array[int] = [2, 1, 0, 2]
const BACK_MARKS: Array[int] = [4, 3, 1, 2]
const PATH: Array[int] = [1, 4, 3, 2]
var house_steps: Array[int] = []
var house_solved: bool = false
var feed_open: bool = true
var union_repaired: bool = false
var fire: int = 0
var relief: int = 0
var brake_released: bool = false
var entered: bool = false
var bearings: Array[int] = [0, 0, 0, 0]
var aligned: bool = false
var steps: Array[int] = []
var solved: bool = false
var railway_entered: bool = false
var completed: bool = false

func house_bell(index: int) -> String:
	if house_solved or index < 0 or index > 3:
		return "inactive"
	if index != HOUSE_SONG[house_steps.size()]:
		house_steps.clear()
		changed.emit()
		return "wrong"
	house_steps.append(index)
	house_solved = house_steps == HOUSE_SONG
	changed.emit()
	return "solved" if house_solved else "step"

func operate_train(control: String) -> String:
	if not railway_entered or completed:
		return "inactive"
	match control:
		"feed": feed_open = not feed_open
		"union":
			if union_repaired:
				return "inactive"
			if feed_open:
				return "isolate"
			union_repaired = true
		"fire": fire = (fire + 1) % 4
		"relief": relief = (relief + 1) % 4
		"brake": brake_released = not brake_released
		_:
			return "inactive"
	changed.emit()
	return "changed"

func train_gauges() -> Vector2i:
	if not union_repaired or not feed_open:
		return Vector2i.ZERO
	return Vector2i(maxi(0, fire * 2 - relief), maxi(0, fire - relief))

func train_ready() -> bool:
	return railway_entered and union_repaired and feed_open and fire == 2 and relief == 1 and brake_released

func train_blocker() -> String:
	if not union_repaired:
		return "TRAIN_NEEDS_REPAIR"
	if not feed_open:
		return "TRAIN_NEEDS_FEED"
	if fire != 2 or relief != 1:
		return "TRAIN_NEEDS_PRESSURE"
	if not brake_released:
		return "TRAIN_NEEDS_BRAKE"
	return ""

func turn(index: int, direction: int = 1) -> void:
	if not entered or aligned or index < 0 or index >= 4:
		return
	bearings[index] = posmod(bearings[index] + direction, 6)
	changed.emit()

func confirm() -> bool:
	if not entered or aligned or bearings != ORIENTATIONS:
		return false
	aligned = true
	changed.emit()
	aligned_now.emit()
	return true

## Only entering a floor plate triggers a step. Standing still never repeats it.
func step_on(index: int) -> String:
	if not aligned or solved or index < 0 or index > 5:
		return "inactive"
	if index != PATH[steps.size()]:
		steps.clear()
		changed.emit()
		return "wrong"
	steps.append(index)
	if steps == PATH:
		solved = true
	changed.emit()
	if solved:
		solved_now.emit()
		return "solved"
	return "step"

func to_data() -> Dictionary:
	return {"house_steps": house_steps.duplicate(), "house_solved": house_solved, "feed_open": feed_open, "union_repaired": union_repaired, "fire": fire, "relief": relief, "brake_released": brake_released, "entered": entered, "bearings": bearings.duplicate(), "aligned": aligned, "steps": steps.duplicate(), "solved": solved, "railway_entered": railway_entered, "completed": completed}

static func from_data(data: Variant) -> CelestialState:
	if not data is Dictionary:
		return null
	data = data.duplicate(true)
	# Earlier builds ended on platform arrival; keep the route, allow the new departure.
	if not data.has("house_steps") and not data.has("union_repaired"):
		data["house_solved"] = data.get("entered", false)
		data["house_steps"] = HOUSE_SONG.duplicate() if data.house_solved else []
		data["feed_open"] = true
		data["union_repaired"] = false
		data["fire"] = 0
		data["relief"] = 0
		data["brake_released"] = false
		data["completed"] = false
	for flag: String in ["house_solved", "feed_open", "union_repaired", "brake_released"]:
		if not data.get(flag) is bool:
			return null
	if not data.get("house_steps") is Array:
		return null
	if not StudyState._valid_numbers(data.house_steps, data.house_steps.size(), 3, 0) or not StudyState._valid_numbers([data.get("fire"), data.get("relief")], 2, 3, 0):
		return null
	var song: Array[int] = []
	song.assign(data.house_steps)
	if song.size() > HOUSE_SONG.size() or song != HOUSE_SONG.slice(0, song.size()) or data.house_solved != (song == HOUSE_SONG):
		return null
	if data.get("entered", false) and not data.house_solved:
		return null
	if not data.get("railway_entered", false) and (data.union_repaired or not data.feed_open or data.fire != 0 or data.relief != 0 or data.brake_released):
		return null
	for key: String in ["entered", "aligned", "solved", "railway_entered", "completed"]:
		if not data.get(key) is bool:
			return null
	if not StudyState._valid_numbers(data.get("bearings"), 4, 5, 0) or not StudyState._valid_numbers(data.get("steps"), -1, 5, 0):
		return null
	data = data.duplicate(true)
	var normalized_bearings: Array[int] = []
	var normalized_steps: Array[int] = []
	normalized_bearings.assign(data.bearings)
	normalized_steps.assign(data.steps)
	data.bearings = normalized_bearings
	data.steps = normalized_steps
	if data.steps.size() > 4 or data.steps != PATH.slice(0, data.steps.size()):
		return null
	if (not data.entered and (data.bearings != [0, 0, 0, 0] or data.aligned)) or (data.aligned and data.bearings != ORIENTATIONS):
		return null
	if (not data.aligned and not data.steps.is_empty()) or data.solved != (data.steps == PATH):
		return null
	if (data.railway_entered and not data.solved) or (data.completed and not data.railway_entered):
		return null
	var result := CelestialState.new()
	for key: String in ["entered", "aligned", "solved", "railway_entered", "completed"]:
		result.set(key, data[key])
	result.house_steps.assign(song)
	result.house_solved = data.house_solved
	result.feed_open = data.feed_open
	result.union_repaired = data.union_repaired
	result.fire = int(data.fire)
	result.relief = int(data.relief)
	result.brake_released = data.brake_released
	if result.completed and not result.train_ready():
		return null
	result.bearings.assign(data.bearings)
	result.steps.assign(data.steps)
	return result
