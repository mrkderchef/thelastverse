class_name StarNursery
extends ActScene
## An impossible roofless nursery. Observe the sky, reason about its keepers, walk a seal.
const CENTER := Vector3(0, 0, -12)
const KEEPER_SPOTS: Array[Vector3] = [Vector3(-6, 0, -7), Vector3(6, 0, -7), Vector3(-6, 0, -18), Vector3(6, 0, -18)]
const PLATES: Array[Vector3] = [Vector3(-3, 0, -10), Vector3(0, 0, -10), Vector3(3, 0, -10), Vector3(-3, 0, -14), Vector3(0, 0, -14), Vector3(3, 0, -14)]
var figures: Array[Node3D] = []
var needles: Array[Node3D] = []
var plate_lights: Array[OmniLight3D] = []
var progress_lights: Array[MeshInstance3D] = []
var gate: Node3D
var gate_tween: Tween
var gate_open: bool = false
var occupied: int = -1

func _ready() -> void:
	CelestialArt.environment(self, 0.85)
	var world := get_child(0) as WorldEnvironment
	var sky_material := ShaderMaterial.new()
	sky_material.shader = preload("res://shared/shaders/nursery_sky.gdshader")
	world.environment.sky = Sky.new()
	world.environment.sky.sky_material = sky_material
	world.environment.background_mode = Environment.BG_SKY
	kit.box(self, Vector3(22, 0.25, 30), Vector3(0, -0.125, -12), "wood", true)
	for side: float in [-1.0, 1.0]:
		kit.box(self, Vector3(0.5, 5.5, 30), Vector3(side * 11, 2.75, -12), "wall", true)
		for z: float in [-3.0, -9.0, -15.0, -21.0]:
			kit.box(self, Vector3(0.2, 4.5, 0.18), Vector3(side * 10.7, 2.25, z), "timber")
			kit.box(self, Vector3(0.1, 1.7, 1.4), Vector3(side * 10.7, 2.7, z), "black")
	kit.box(self, Vector3(22, 5.5, 0.4), Vector3(0, 2.75, 3), "wall", true)
	for side: float in [-1.0, 1.0]:
		kit.box(self, Vector3(9.2, 5.5, 0.4), Vector3(side * 6.4, 2.75, -25), "brick", true)
	kit.box(self, Vector3(3.6, 1.4, 0.4), Vector3(0, 4.8, -25), "brick")
	kit.box(self, Vector3(22, 5.5, 0.3), Vector3(0, 2.75, -27), "black", true)
	_sky()
	for index: int in range(4):
		_keeper(index)
	for index: int in range(6):
		kit.box(self, Vector3(1.55, 0.04, 1.55), PLATES[index] + Vector3(0, 0.025, 0), "stone")
		var mark := CelestialArt.glyph(kit, self, index, 0.45)
		mark.position = PLATES[index] + Vector3(0, 0.055, 0)
		mark.rotation.x = -PI / 2
		plate_lights.append(kit.light(self, PLATES[index] + Vector3(0, 0.35, 0), Color("85cedc"), 0, 1.8))
		var floor_target := kit.interactable(self, "floor_glyph", "GLYPH_" + CelestialState.GLYPHS[index], "FLOOR_INSPECT", PLATES[index] + Vector3(0, 0.07, 0), Vector3(1.55, 0.1, 1.55), index)
		floor_target.collision_layer = 16
	var seal := kit.interactable(self, "star_confirm", "STAR_SEAL", "STAR_SEAL_INSPECT", Vector3(0, 1, -5.5), Vector3(1, 0.5, 0.7))
	kit.cylinder(seal, 0.55, 0.9, Vector3(0, -0.3, 0), "stone")
	kit.cylinder(seal, 0.5, 0.05, Vector3(0, 0.2, 0), "gold")
	for index: int in range(4):
		progress_lights.append(kit.sphere(seal, 0.055, Vector3(-0.3 + index * 0.2, 0.28, 0.12), "black"))
	CelestialArt.inscription(kit, self, "XXIII", Vector3(0, 1.3, -5.15), 34)
	for entry: Array in [["star_rules", Vector3(-8.8, 1.4, -3.0)], ["star_covenant", Vector3(8.8, 1.4, -3.0)], ["star_walk", Vector3(8.8, 1.4, -22.0)], ["star_atlas", Vector3(-8.8, 1.4, -22.0)]]:
		kit.box(self, Vector3(1.5, 1.1, 0.8), entry[1] - Vector3(0, 0.85, 0), "wood", true)
		kit.note(self, entry[0], entry[1], Vector2(0.65, 0.65), Vector3(-0.4, 0, 0))
		kit.light(self, entry[1] + Vector3(0, 1.5, 0.4), Color("ffcf9a"), 1.1, 4)
	gate = Node3D.new()
	add_child(gate)
	kit.box(gate, Vector3(3.5, 3.8, 0.25), Vector3(0, 1.9, -25), "iron", true)
	CelestialArt.inscription(kit, gate, "METROPOLITAN\nRAILWAY", Vector3(0, 2.5, -24.84), 40)
	kit.light(self, Vector3(0, 3.8, -24), Color("d8ae72"), 2, 6)
	kit.light(self, Vector3(0, 7, -12), Color("91b3ea"), 4, 22)
	kit.light(self, Vector3(-5, 4, -8), Color("97a9d1"), 1.6, 11)
	kit.light(self, Vector3(5, 4, -18), Color("97a9d1"), 1.6, 11)
	# Empty cot bays around the observation floor, kept out of the route.
	for x: float in [-9.0, 9.0]:
		for z: float in [-8.0, -13.0, -18.0]:
			kit.box(self, Vector3(1.1, 0.2, 1.9), Vector3(x, 0.55, z), "wood", true)
			kit.box(self, Vector3(0.95, 0.1, 1.7), Vector3(x, 0.7, z), "linen")
			for side: float in [-0.55, 0.55]:
				for rail: int in range(5):
					kit.box(self, Vector3(0.045, 0.9, 0.045), Vector3(x + side, 0.8, z - 0.85 + rail * 0.42), "timber")
	_add_player(Vector3(0, 5, 1), Vector3(0, 1, -12))

func _sky() -> void:
	for index: int in range(6):
		var angle: float = index * TAU / 6.0
		var constellation := CelestialArt.glyph(kit, self, index, 2.6, "glass", true)
		constellation.position = CENTER + Vector3(sin(angle) * 27, 23, -cos(angle) * 27)
		constellation.look_at(CENTER + Vector3(0, 1.6, 0), Vector3.UP, true)
	# Sparse minor stars are dim and unconnected, unlike the six major figures.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1896
	for index: int in range(85):
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.6, 1.5), rng.randf_range(-1, 1)).normalized()
		kit.sphere(self, 0.04, CENTER + direction * 48, "daylight")

func _keeper(index: int) -> void:
	var spot: Vector3 = KEEPER_SPOTS[index]
	kit.cylinder(self, 0.72, 0.24, spot + Vector3(0, 0.12, 0), "stone", -1, true)
	var figure := ActorKit.make(kit, {"costume": "stone", "skin": "stone", "glove": "stone", "legs": "stone", "hat": "bald", "right_arm": Vector3(1.4, 0, 0.18), "left_arm": Vector3(0.1, 0, 0.15), "nod": -0.28})
	add_child(figure)
	figure.position = spot + Vector3(0, 0.24, 0)
	figures.append(figure)
	# Chest identity and an independently meaningful mark on the back.
	CelestialArt.inscription(kit, figure, CelestialState.KEEPERS[index], Vector3(0, 1.15, 0.20), 20)
	var back := CelestialArt.glyph(kit, figure, CelestialState.BACK_MARKS[index], 0.13, "gas")
	back.position = Vector3(0, 1.2, -0.2)
	back.rotation.y = PI
	var needle := Node3D.new()
	add_child(needle)
	needle.position = spot + Vector3(0, 0.27, 0)
	CelestialArt.line(kit, needle, Vector3.ZERO, Vector3(0, 0, 0.7), 0.025, "gold")
	needles.append(needle)
	for bearing: int in range(6):
		var angle: float = bearing * TAU / 6.0
		var mark := CelestialArt.glyph(kit, self, bearing, 0.17, "gold")
		mark.position = spot + Vector3(sin(angle) * 1.1, 0.035, -cos(angle) * 1.1)
		mark.rotation.x = -PI / 2
	kit.interactable(self, "star_keeper", "KEEPER_" + CelestialState.KEEPERS[index], "KEEPER_INSPECT_" + str(index), spot + Vector3(0, 1.0, 0), Vector3(0.85, 1.8, 0.85), index)
	kit.light(self, spot + Vector3(0, 3, 0), Color("dfca9f"), 1.2, 4)

func spawn_point() -> Array:
	return [Vector3(0, 0.08, 0), 0.0]

func apply_state(animate: bool = true) -> void:
	super.apply_state(animate)
	if state == null:
		return
	for index: int in range(4):
		var angle: float = PI - state.celestial.bearings[index] * TAU / 6.0
		figures[index].rotation.y = angle
		needles[index].rotation.y = angle
		progress_lights[index].material_override = kit.materials["gas" if state.celestial.steps.size() > index else "black"]
	for index: int in range(6):
		plate_lights[index].light_energy = 1.2 if index in state.celestial.steps else 0.0
	if gate_open == state.celestial.solved and animate:
		return
	gate_open = state.celestial.solved
	if gate_tween != null:
		gate_tween.kill()
	if animate:
		gate_tween = create_tween()
		gate_tween.tween_property(gate, "position:y", 4.3 if gate_open else 0.0, 2)
	else:
		gate.position.y = 4.3 if gate_open else 0.0

func _physics_process(_delta: float) -> void:
	if state == null or not player.enabled:
		return
	_report_threshold(state.celestial.solved and player.position.z < -25.8)
	var next: int = -1
	for index: int in range(6):
		var offset: Vector3 = player.position - PLATES[index]
		if absf(offset.x) < 0.77 and absf(offset.z) < 0.77:
			next = index
	if next == occupied:
		return
	occupied = next
	if next < 0:
		return
	if follower:
		ask.call("step_on", [next])
		return
	var result: String = state.celestial.step_on(next)
	if result in ["wrong", "step"]:
		narrate.emit("STAR_WALK_" + result.to_upper())
