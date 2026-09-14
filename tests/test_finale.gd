extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	var state := StudyState.new()
	_expect(state.ring_house_bell(2) == "read", "The house record precedes the memory puzzle")
	var c := CelestialState.new()
	_expect(c.house_bell(2) == "step" and c.house_steps == [2], "The first memory note persists")
	_expect(CelestialState.from_data(JSON.parse_string(JSON.stringify(c.to_data()))).house_steps == [2], "Partial memory survives JSON")
	_expect(c.house_bell(1) == "wrong" and c.house_steps.is_empty(), "Wrong bell clears only the attempt")
	for bell: int in CelestialState.HOUSE_SONG:
		c.house_bell(bell)
	_expect(c.house_solved and c.house_bell(1) == "inactive", "The solved secret door cannot relock")
	c.entered = true
	c.bearings.assign(CelestialState.ORIENTATIONS)
	c.confirm()
	for glyph: int in CelestialState.PATH:
		c.step_on(glyph)
	_expect(c.operate_train("union") == "inactive", "Train repair is unavailable before reaching the platform")
	c.railway_entered = true
	_expect(not c.completed and not c.train_ready(), "Arrival on the platform does not finish the level")
	_expect(c.operate_train("union") == "isolate" and not c.union_repaired, "An open feed prevents repairing the leaking union")
	c.operate_train("feed")
	c.operate_train("union")
	_expect(c.union_repaired and c.train_gauges() == Vector2i.ZERO, "The isolated pipe can be repaired without producing pressure")
	c.operate_train("feed")
	var solutions: Array = []
	for fire: int in range(4):
		for relief: int in range(4):
			c.fire = fire
			c.relief = relief
			if c.train_gauges() == Vector2i(3, 1):
				solutions.append(Vector2i(fire, relief))
	_expect(solutions == [Vector2i(2,1)], "The two engraved gauge targets have one control solution")
	c.fire = 2
	c.relief = 1
	_expect(not c.train_ready() and c.train_blocker() == "TRAIN_NEEDS_BRAKE", "Working pressure is insufficient with the brake held")
	c.operate_train("brake")
	_expect(c.train_ready() and not c.completed, "Ready to depart still does not finish the level")
	var restored := CelestialState.from_data(JSON.parse_string(JSON.stringify(c.to_data())))
	_expect(restored != null and restored.train_ready(), "Repaired and prepared train survives reload")
	c.completed = true
	_expect(CelestialState.from_data(c.to_data()).completed, "Finished departure persists")
	_expect(c.operate_train("feed") == "inactive" and c.feed_open, "The completed train cannot be broken again")
	for patch: Dictionary in [{"fire": 4}, {"relief": 0}, {"union_repaired": false}, {"brake_released": false}, {"house_steps": [2,1]}]:
		var bad: Dictionary = c.to_data()
		bad.merge(patch, true)
		_expect(CelestialState.from_data(bad) == null, "Reject impossible finale state " + str(patch))
	var legacy := {"entered": true, "bearings": [2,1,0,2], "aligned": true, "steps": [1,4,3,2], "solved": true, "railway_entered": true, "completed": true}
	var migrated := CelestialState.from_data(legacy)
	_expect(migrated != null and migrated.railway_entered and migrated.house_solved and not migrated.completed, "Old platform endings keep access and unlock the new departure finale")
	print("House and departure: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
