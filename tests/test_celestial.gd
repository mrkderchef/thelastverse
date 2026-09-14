extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	var candidates: Array = []
	for sun: int in range(3, 9):
		for moon: int in range(3, 9):
			for tide: int in range(3, 9):
				for ash: int in range(3, 9):
					var counts: Array[int] = [sun, moon, tide, ash]
					var unique := {}
					for count: int in counts:
						unique[count] = true
					if unique.size() == 4 and sun == tide + 2 and ash == moon + 1 and tide < mini(sun, mini(moon, ash)) and sun + moon + tide + ash == 23:
						candidates.append(counts)
	_expect(candidates == [[5, 7, 3, 8]], "The written covenant has exactly one solution among all 1,296 count assignments")
	var puzzle := CelestialState.new()
	puzzle.turn(0)
	_expect(puzzle.bearings == [0, 0, 0, 0] and not puzzle.confirm() and puzzle.step_on(1) == "inactive", "The nightmare cannot be solved before arrival")
	puzzle.house_steps.assign(CelestialState.HOUSE_SONG)
	puzzle.house_solved = true
	puzzle.entered = true
	for index: int in range(4):
		var target: int = candidates[0][index] - 3
		var direction: int = posmod(target + (3 if CelestialState.REFLECTED[index] else 0), 6)
		for step: int in range(direction):
			puzzle.turn(index)
		_expect(_restore(puzzle) != null, "Partial keeper bearings survive JSON")
	_expect(puzzle.confirm(), "Derived star assignments and reversed sight align the seal")
	var before: Array[int] = puzzle.bearings.duplicate()
	puzzle.turn(1)
	_expect(puzzle.bearings == before and not puzzle.confirm(), "Alignment cannot be undone")
	_expect(puzzle.step_on(1) == "step", "Walking the first back-mark starts the seal")
	_expect(_restore(puzzle).steps == [1], "A partial walked seal persists")
	_expect(puzzle.step_on(0) == "wrong" and puzzle.steps.is_empty() and puzzle.aligned, "Wrong footsteps clear only the attempted walk")
	# Derive the walked order from counts and back inscriptions, not the solution constant.
	var order: Array[int] = [0, 1, 2, 3]
	order.sort_custom(func(a: int, b: int) -> bool: return candidates[0][a] < candidates[0][b])
	for index: int in order:
		puzzle.step_on(CelestialState.BACK_MARKS[index])
	_expect(puzzle.solved and _restore(puzzle).solved, "Reading backs in ascending star order opens the nursery")
	var solved_steps: Array[int] = puzzle.steps.duplicate()
	_expect(puzzle.step_on(5) == "inactive" and puzzle.steps == solved_steps, "Solved floor plates cannot reset the route")
	for patch: Dictionary in [{"bearings": [0,0,0,6]}, {"bearings": [0,0,0,1.5]}, {"steps": [1,0]}, {"steps": [1,4,3,2,0]}, {"solved": false}, {"entered": false}, {"aligned": false}]:
		var bad: Dictionary = puzzle.to_data()
		bad.merge(patch, true)
		_expect(CelestialState.from_data(bad) == null, "Reject impossible celestial save " + str(patch))
	var fresh := StudyState.new()
	_expect(not fresh.enter_farm() and not fresh.enter_railway(), "Chapter transitions enforce prerequisites")
	var old: Dictionary = fresh.to_data()
	old.erase("celestial")
	old.hints.resize(10)
	var restored := StudyState.from_data(JSON.parse_string(JSON.stringify(old)))
	_expect(restored != null and restored.hints.size() == 13 and not restored.celestial.entered, "Existing False Exit saves migrate without resetting progress")
	print("Celestial deduction: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func _restore(puzzle: CelestialState) -> CelestialState:
	return CelestialState.from_data(JSON.parse_string(JSON.stringify(puzzle.to_data())))
func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
