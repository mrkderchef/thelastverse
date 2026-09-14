class_name RipperStreet
extends ActScene
## Act IV: the Whitechapel watch. A rain-soaked grid of slum streets at night. The Uncast
## Shadow, a fictional figure shaped by the city's fear of Jack the Ripper, walks a fixed
## circuit of six stops from the Watch Post, but only while the gaslight gutters and dims;
## in full light he stands frozen wherever he is. Seeing him at a stop records a sighting.
## Filing the ordered route at the Watch Post unbars the Mourning Gate. He never attacks.
##
## Streets run north-south at x = -20, 0, 20 and east-west at z = -10, -32, -54 (6 m wide),
## with tenement blocks between them. The sewer grate opens at the north end of the centre.

const NIGHT_SKY := preload("res://shared/shaders/night_sky.gdshader")
const STREET_X: Array[float] = [-20.0, 0.0, 20.0]
const STREET_Z: Array[float] = [-10.0, -32.0, -54.0]
const HALF := 3.0
## Where each landmark stands on the grid.
const LANDMARKS: Dictionary = {
	"WATCH": Vector3(0, 0, -10), "YARD": Vector3(-20, 0, -10), "PUB": Vector3(20, 0, -10),
	"CROSS": Vector3(-20, 0, -32), "CHAPEL": Vector3(0, 0, -32), "WELL": Vector3(20, 0, -32),
	"MARKET": Vector3(-20, 0, -54), "TANNERY": Vector3(20, 0, -54), "GATE": Vector3(0, 0, -54),
}
## The circuit as positions: the Watch Post, then each stop in StudyState.WATCH_ROUTE.
static var STOPS: Array[Vector3] = [Vector3(0, 0, -10), Vector3(-20, 0, -10), Vector3(-20, 0, -32), Vector3(0, 0, -32), Vector3(20, 0, -32), Vector3(20, 0, -54), Vector3(0, 0, -54)]
const WALK_SPEED := 1.5
## Gaslight cycle in seconds: bright, then guttering, then dim. He moves only when not bright.
const BRIGHT := 4.5
const GUTTER := 1.3
const CYCLE := 11.5
const SIGHT_RANGE := 26.0
const END_Z := -59.0

signal shadow_seen

var shadow: Node3D
var gas_lights: Array[OmniLight3D] = []
var lamp_base: Array[float] = []
var exit_gate: Node3D
var gate_open: bool = false
var patrol_clock: float = 0.0
var patrol_step: int = 0
var waiting: float = 0.0
var resting: float = 0.0
## Stops this companion has already reported to the host.
var asked: Array[String] = []
var was_dark: bool = false
var apparition: Node3D
var apparition_done: bool = false
var rain_player: AudioStreamPlayer
var heart_player: AudioStreamPlayer
var steps_player: AudioStreamPlayer3D
var whisper_player: AudioStreamPlayer3D
var world_volume: float = 0.5
var rain: GPUParticles3D


func _ready() -> void:
	_build_environment()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1888
	_streets()
	_blocks(rng)
	_landmarks()
	for x: float in STREET_X:
		for z: float in STREET_Z:
			_lamp(Vector3(x + 2.6, 0, z + 2.6))
		for z: float in [-21.0, -43.0]:
			_lamp(Vector3(x - 2.6, 0, z))
	for z: float in STREET_Z:
		for x: float in [-10.0, 10.0]:
			_lamp(Vector3(x, 0, z - 2.6))
	_lamp(Vector3(2.4, 0, -2.0))
	_laundry(rng)
	_residents()
	_rats(rng)
	scatter_trinkets([["bottle", Vector3(-2.0, 0.1, -4.0)], ["tankard", Vector3(18.4, 0.8, -12.5)], ["bottle", Vector3(21.5, 0.1, -30.0)], ["book", Vector3(-18.0, 0.1, -50.0)], ["coin", Vector3(1.0, 0.1, -20.0)], ["bone", Vector3(22.0, 0.1, -51.0)], ["cup", Vector3(-22.0, 0.1, -34.0)]])
	shadow = _make_shadow()
	add_child(shadow)
	shadow.position = STOPS[0]
	apparition = _make_shadow()
	add_child(apparition)
	apparition.visible = false
	_rain_and_sound()
	_add_player(Vector3(8.0, 9.0, 4.0), Vector3(-6.0, 0.0, -30.0))


func spawn_point() -> Array:
	if state != null and state.shadow_solved:
		return [Vector3(0, 0.05, -50.0), 0.0]
	return [Vector3(0, 0.05, -1.2), 0.0]


func apply_state(animate: bool = true) -> void:
	super.apply_state(animate)
	if state == null:
		return
	if state.shadow_solved:
		shadow.visible = false
	var open: bool = state.shadow_solved
	if gate_open == open and animate:
		return
	gate_open = open
	if animate and is_inside_tree():
		create_tween().tween_property(exit_gate, "position:y", 4.2 if open else 0.0, 2.2).set_trans(Tween.TRANS_SINE)
	else:
		exit_gate.position.y = 4.2 if open else 0.0


func set_world_volume(linear: float) -> void:
	world_volume = linear


func music_duck() -> float:
	return 0.55


## True while the gaslight is failing, the only time the Shadow walks.
func lamps_failing() -> bool:
	return fmod(patrol_clock, CYCLE) > BRIGHT


func _physics_process(delta: float) -> void:
	if state == null or player == null or not player.enabled:
		return
	_report_threshold(state.shadow_solved and player.position.z < END_Z)
	patrol_clock += delta
	var phase: float = fmod(patrol_clock, CYCLE)
	var dark: bool = phase > BRIGHT
	var guttering: bool = dark and phase < BRIGHT + GUTTER
	for index: int in range(gas_lights.size()):
		var level: float = 1.0
		if guttering:
			level = 0.15 + 0.85 * absf(sin(patrol_clock * (23.0 + index % 5)))
		elif dark:
			level = 0.1 + 0.05 * sin(patrol_clock * 3.0 + index)
		gas_lights[index].light_energy = lamp_base[index] * level
	if dark and not was_dark:
		_on_lamps_fail()
	was_dark = dark
	_update_sound(delta)
	if state.shadow_solved:
		return
	if follower:
		# The host walks him; this side only watches for him at his stops.
		var stop: int = patrol_step + 1
		if shadow.visible and stop < STOPS.size() and shadow.position.distance_to(STOPS[stop]) <= 0.2:
			_try_sighting(StudyState.WATCH_ROUTE[patrol_step], shadow.global_position)
	else:
		_patrol(delta, dark)
	_apparition_cue()


func _patrol(delta: float, dark: bool) -> void:
	if resting > 0.0:
		resting -= delta
		shadow.visible = false
		if resting <= 0.0:
			patrol_step = 0
			waiting = 0.0
			shadow.position = STOPS[0]
		return
	shadow.visible = manifest()
	var target: Vector3 = STOPS[patrol_step + 1]
	var moving: bool = dark and shadow.position.distance_to(target) > 0.1
	if moving:
		var flat: Vector3 = target - shadow.position
		shadow.look_at(shadow.position + flat.normalized() + Vector3(0, 0, 0.0001), Vector3.UP, true)
		shadow.position = shadow.position.move_toward(target, delta * WALK_SPEED)
		shadow.rotation.z = sin(patrol_clock * 5.0) * 0.03
	if steps_player != null:
		if moving and not steps_player.playing:
			steps_player.play()
		elif not moving and steps_player.playing:
			steps_player.stop()
	if shadow.position.distance_to(target) <= 0.1:
		_try_sighting(StudyState.WATCH_ROUTE[patrol_step], shadow.global_position)
		# He lingers at each stop for one full turn of the lamps, then walks on in the dark.
		waiting += delta
		if waiting > CYCLE and dark:
			waiting = 0.0
			patrol_step += 1
			if patrol_step >= StudyState.WATCH_ROUTE.size():
				resting = 9.0
				shadow_seen.emit()


## He exists only in the dark: invisible while the gas burns bright, stuttering into view as
## the flames gutter, and fully there once the street goes dim.
func manifest() -> bool:
	var phase: float = fmod(patrol_clock, CYCLE)
	if phase <= BRIGHT:
		return false
	if phase < BRIGHT + GUTTER:
		return sin(patrol_clock * 31.0) > 0.35
	return true


## Records a sighting when the player can actually see the Shadow at his stop.
func _try_sighting(place: String, at: Vector3) -> void:
	if place in state.watch_seen or not manifest():
		return
	var head: Vector3 = at + Vector3(0, 1.7, 0)
	if player.camera.global_position.distance_to(head) > SIGHT_RANGE or player.camera.is_position_behind(head):
		return
	if not get_viewport().get_visible_rect().has_point(player.camera.unproject_position(head)):
		return
	var ray := PhysicsRayQueryParameters3D.create(player.camera.global_position, head, 1, [player.get_rid()])
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		return
	if follower:
		if place not in asked:
			asked.append(place)
			ask.call("observe_watch", [place])
		return
	state.observe_watch(place)
	narrate.emit(tr("SIGHTING") % tr("LANDMARK_" + place))


## Co-op companion side: the host's Shadow, sent twenty times a second.
func follow_shadow(at: Vector3, rotation_euler: Vector3, shown: bool, clock: float, step: int) -> void:
	shadow.position = at
	shadow.rotation = rotation_euler
	shadow.visible = shown and not state.shadow_solved
	patrol_clock = clock
	patrol_step = step


func _on_lamps_fail() -> void:
	if whisper_player != null and not state.shadow_solved and player.global_position.distance_to(shadow.global_position) < 18.0 and randf() < 0.5:
		whisper_player.global_position = shadow.global_position + Vector3(0, 1.7, 0)
		whisper_player.play()


## Once, deep in the district, the lamps die and he stands close ahead for a heartbeat.
func _apparition_cue() -> void:
	if apparition_done:
		if apparition.visible and fmod(patrol_clock, CYCLE) < BRIGHT:
			apparition.visible = false
		return
	var near_market: bool = player.position.x < -14.0 and player.position.z < -40.0
	if near_market and lamps_failing() and fmod(patrol_clock, CYCLE) > BRIGHT + GUTTER:
		apparition_done = true
		var forward: Vector3 = -player.global_basis.z
		forward.y = 0
		apparition.global_position = player.global_position + forward.normalized() * 6.0
		apparition.look_at(Vector3(player.global_position.x, 0, player.global_position.z), Vector3.UP, true)
		apparition.visible = true
		narrate.emit("SHADOW_CLOSE")
		if whisper_player != null:
			whisper_player.global_position = apparition.global_position + Vector3(0, 1.7, 0)
			whisper_player.play()
		var gone: Tween = create_tween()
		gone.tween_interval(0.9)
		gone.tween_callback(apparition.hide)


func _update_sound(_delta: float) -> void:
	if heart_player == null:
		return
	var distance: float = player.global_position.distance_to(shadow.global_position if shadow.visible else apparition.global_position)
	var fear: float = clampf(1.0 - (distance - 4.0) / 14.0, 0.0, 1.0)
	if not shadow.visible and not apparition.visible:
		fear = 0.0
	heart_player.volume_db = linear_to_db(maxf(fear * world_volume * 2.5, 0.0001))
	heart_player.pitch_scale = 1.0 + fear * 0.6
	rain_player.volume_db = linear_to_db(maxf(world_volume * 1.4, 0.0001))
	if steps_player != null:
		steps_player.volume_db = linear_to_db(maxf(world_volume * 3.0, 0.0001))


func _build_environment() -> void:
	var environment := Environment.new()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = NIGHT_SKY
	sky_material.set_shader_parameter("cloud_light", Color(0.22, 0.24, 0.3))
	sky_material.set_shader_parameter("fire", Color(0.25, 0.2, 0.18))
	sky_material.set_shader_parameter("moon_color", Color(0.75, 0.8, 0.9))
	environment.sky = Sky.new()
	environment.sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("56607a")
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.15
	environment.glow_enabled = true
	environment.glow_intensity = 1.0
	environment.ssao_enabled = true
	environment.ssao_intensity = 1.8
	environment.fog_enabled = true
	environment.fog_light_color = Color("3c4250")
	environment.fog_density = 0.045
	environment.fog_sky_affect = 0.8
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.035
	environment.volumetric_fog_albedo = Color("bcc4d0")
	environment.volumetric_fog_length = 40.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.7
	environment.adjustment_contrast = 1.15
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)


func _streets() -> void:
	# Wet cobbles: the grid of streets plus the lane up from the sewer grate.
	var wet: StandardMaterial3D = (kit.materials["cobble"] as StandardMaterial3D).duplicate()
	wet.roughness = 0.18
	wet.albedo_color = Color(0.55, 0.57, 0.62)
	kit.materials["wet_cobble"] = wet
	for x: float in STREET_X:
		kit.box(self, Vector3(HALF * 2.0, 0.2, 50.0), Vector3(x, -0.1, -32.0), "wet_cobble", true)
	for z: float in STREET_Z:
		kit.box(self, Vector3(46.0, 0.2, HALF * 2.0), Vector3(0, -0.1, z), "wet_cobble", true)
	kit.box(self, Vector3(HALF * 2.0, 0.2, 8.0), Vector3(0, -0.1, -3.0), "wet_cobble", true)
	kit.box(self, Vector3(HALF * 2.0, 0.2, 6.0), Vector3(0, -0.1, -60.0), "wet_cobble", true)
	# The open sewer grate the player climbs out of.
	kit.box(self, Vector3(1.2, 0.02, 1.2), Vector3(0, 0.01, 0.2), "black")
	for x: float in [-0.5, 0.0, 0.5]:
		kit.box(self, Vector3(0.06, 0.04, 1.2), Vector3(x + 0.9, 0.02, 0.7), "iron").rotation.y = 0.6
	# The outer ring of tenements that closes the district.
	kit.box(self, Vector3(HALF * 2.0 + 1.0, 12.0, 0.6), Vector3(0, 6.0, 1.2), "brick", true)
	kit.box(self, Vector3(0.6, 12.0, 70.0), Vector3(-23.3, 6.0, -30.0), "brick", true)
	kit.box(self, Vector3(0.6, 12.0, 70.0), Vector3(23.3, 6.0, -30.0), "brick", true)
	for side: float in [-1.0, 1.0]:
		kit.box(self, Vector3(20.0, 12.0, 0.6), Vector3(side * 13.0, 6.0, -6.7), "brick", true)
		kit.box(self, Vector3(20.3, 12.0, 0.6), Vector3(side * 13.2, 6.0, -57.3), "brick", true)
		kit.box(self, Vector3(3.0, 12.0, 0.6), Vector3(side * 21.8, 6.0, -6.7), "brick", true)
		kit.box(self, Vector3(3.0, 12.0, 0.6), Vector3(side * 21.8, 6.0, -57.3), "brick", true)
	kit.box(self, Vector3(1.0, 12.0, 8.0), Vector3(-3.5, 6.0, -3.0), "brick", true)
	kit.box(self, Vector3(1.0, 12.0, 8.0), Vector3(3.5, 6.0, -3.0), "brick", true)
	kit.box(self, Vector3(8.0, 12.0, 0.6), Vector3(0, 6.0, -63.2), "brick", true)
	for side: float in [-1.0, 1.0]:
		kit.box(self, Vector3(1.0, 12.0, 6.0), Vector3(side * 3.5, 6.0, -60.0), "brick", true)
	# Facade detail on the outer walls.
	for z: int in range(-12, -56, -4):
		for side: float in [-1.0, 1.0]:
			_windows(Vector3(side * 23.0, 0, float(z)), Vector3(-side, 0, 0))


func _blocks(rng: RandomNumberGenerator) -> void:
	for x_range: Vector2 in [Vector2(-17.0, -3.0), Vector2(3.0, 17.0)]:
		for z_range: Vector2 in [Vector2(-13.0, -29.0), Vector2(-35.0, -51.0)]:
			var center := Vector3((x_range.x + x_range.y) / 2.0, 0, (z_range.x + z_range.y) / 2.0)
			var extent := Vector2(x_range.y - x_range.x, z_range.x - z_range.y)
			var height: float = rng.randf_range(9.0, 13.0)
			kit.box(self, Vector3(extent.x, height, extent.y), center + Vector3(0, height / 2.0, 0), "brick" if rng.randf() < 0.75 else "plaster_cool", true)
			kit.box(self, Vector3(extent.x + 0.6, 0.4, extent.y + 0.6), center + Vector3(0, height + 0.2, 0), "dark")
			for chimney: int in range(4):
				kit.box(self, Vector3(0.8, 2.2, 0.8), center + Vector3(rng.randf_range(-5, 5), height + 1.1, rng.randf_range(-6, 6)), "brick")
			# Windows and doors on all four street faces.
			for step: int in range(int(x_range.x) + 2, int(x_range.y) - 1, 3):
				_windows(Vector3(float(step), 0, z_range.x), Vector3(0, 0, 1))
				_windows(Vector3(float(step), 0, z_range.y), Vector3(0, 0, -1))
			for step: int in range(int(z_range.y) + 2, int(z_range.x) - 1, 3):
				_windows(Vector3(x_range.x, 0, float(step)), Vector3(-1, 0, 0))
				_windows(Vector3(x_range.y, 0, float(step)), Vector3(1, 0, 0))


## One bay of a tenement face: two storeys of dark or dimly lit windows and a door or poster.
func _windows(at: Vector3, outward: Vector3) -> void:
	var seed_value: int = int(absf(at.x * 13.0 + at.z * 7.0))
	var along := Vector3(outward.z, 0, -outward.x)
	for storey: int in range(3):
		var lit: bool = (seed_value + storey * 5) % 9 == 0
		var pane: MeshInstance3D = kit.box(self, Vector3(0.9, 1.1, 0.06), at + outward * 0.03 + Vector3(0, 3.6 + storey * 2.6, 0), "window" if lit else "black")
		pane.look_at(pane.global_position + outward, Vector3.UP)
		if (seed_value + storey) % 4 == 0:
			var board: MeshInstance3D = kit.box(self, Vector3(1.0, 0.12, 0.08), at + outward * 0.07 + Vector3(0, 3.6 + storey * 2.6, 0), "timber")
			board.look_at(board.global_position + outward, Vector3.UP)
			board.rotation.z = 0.4
	if seed_value % 3 == 0:
		var door: MeshInstance3D = kit.box(self, Vector3(1.0, 2.1, 0.08), at + outward * 0.04 + Vector3(0, 1.05, 0), "timber")
		door.look_at(door.global_position + outward, Vector3.UP)
	elif seed_value % 3 == 1:
		var poster: MeshInstance3D = kit.box(self, Vector3(0.6, 0.8, 0.02), at + outward * 0.03 + along * 0.4 + Vector3(0, 1.6, 0), "paper")
		poster.look_at(poster.global_position + outward, Vector3.UP)


func _landmarks() -> void:
	# The Watch Post: a police station front with its blue lamp, a constable, and the desk
	# where the street plan lies.
	var watch: Vector3 = LANDMARKS["WATCH"]
	kit.box(self, Vector3(3.6, 3.6, 0.3), watch + Vector3(0, 1.8, -3.1), "blue")
	kit.box(self, Vector3(1.2, 2.3, 0.1), watch + Vector3(0, 1.15, -2.9), "window")
	var blue_lamp: MeshInstance3D = kit.box(self, Vector3(0.5, 0.5, 0.5), watch + Vector3(1.4, 3.1, -2.6), "glass")
	blue_lamp.material_override = kit.material(Color("4a78ff"), 0.0, Color("5a86ff"), 2.4)
	kit.light(self, watch + Vector3(1.4, 3.0, -2.0), Color("6a90ff"), 2.4, 7.0)
	_sign(watch + Vector3(0, 3.35, -2.9), "POLICE", 0.0)
	var constable: Node3D = ActorKit.make(kit, {"costume": "blue", "legs": "black", "hat": "bobby", "mask": "plain", "right_arm": Vector3(0.9, 0, 0.1), "left_arm": Vector3(0.2, 0, 0.1)})
	add_child(constable)
	constable.position = watch + Vector3(-1.9, 0, -2.2)
	var desk: StudyInteractable = kit.interactable(self, "inspection_lamp", "SHADOW_LAMP", "SHADOW_LAMP_INSPECT", watch + Vector3(1.6, 1.0, -1.7), Vector3(1.4, 0.8, 0.8))
	kit.box(desk, Vector3(1.3, 0.1, 0.7), Vector3(0, 0.05, 0), "wood")
	for x: float in [-0.55, 0.55]:
		kit.box(desk, Vector3(0.08, 1.0, 0.08), Vector3(x, -0.45, 0), "timber")
	kit.box(desk, Vector3(0.9, 0.01, 0.6), Vector3(0, 0.11, 0), "paper").rotation.y = 0.1
	candle(watch + Vector3(2.1, 1.1, -1.9), false)
	var notice: StudyInteractable = kit.note(self, "shadow_letter", watch + Vector3(-1.0, 1.7, -2.93), Vector2(0.5, 0.65))
	notice.rotation.y = 0.0
	# Cooper's Yard: stacked barrels and a cart.
	var yard: Vector3 = LANDMARKS["YARD"] + Vector3(-2.2, 0, -2.4)
	for index: int in range(7):
		kit.cylinder(self, 0.35, 0.9, yard + Vector3((index % 3) * 0.75, 0.45 + (index / 3) * 0.9, 0), "wood", 0.3, index < 3)
	_sign(LANDMARKS["YARD"] + Vector3(-2.9, 3.0, 0), "COOPER’S YARD", PI / 2)
	# The Crooked Crown: a warm pub window, a crooked crown sign, benches.
	var pub: Vector3 = LANDMARKS["PUB"]
	kit.box(self, Vector3(0.1, 1.8, 3.0), pub + Vector3(2.95, 1.6, -3.0), "window")
	kit.light(self, pub + Vector3(1.8, 2.0, -3.0), Color("ffb060"), 1.8, 6.0)
	kit.cylinder(self, 0.25, 0.25, pub + Vector3(2.4, 3.3, 2.0), "gold", 0.3).rotation.z = 0.4
	_sign(pub + Vector3(2.9, 3.0, 0), "THE CROOKED CROWN", -PI / 2)
	# Bell Passage: an arch with a hanging bell.
	var cross: Vector3 = LANDMARKS["CROSS"]
	kit.box(self, Vector3(0.6, 4.0, 0.6), cross + Vector3(-2.7, 2.0, 2.7), "stone", true)
	kit.box(self, Vector3(0.6, 4.0, 0.6), cross + Vector3(-2.7, 2.0, -2.7), "stone", true)
	kit.box(self, Vector3(0.6, 0.6, 6.0), cross + Vector3(-2.7, 4.2, 0), "stone")
	kit.cylinder(self, 0.3, 0.45, cross + Vector3(-2.7, 3.55, 0), "gold", 0.08)
	_sign(cross + Vector3(-2.9, 2.8, 1.6), "BELL PASSAGE", PI / 2)
	# Chapel Steps: a small chapel door on the block corner, with worn steps.
	var chapel: Vector3 = LANDMARKS["CHAPEL"]
	for step: int in range(3):
		kit.box(self, Vector3(2.4 - step * 0.3, 0.18, 0.5), chapel + Vector3(-4.2, 0.09 + step * 0.18, -2.4 - step * 0.35), "stone")
	kit.box(self, Vector3(1.6, 2.6, 0.2), chapel + Vector3(-4.2, 1.8, -3.1), "timber")
	kit.cylinder(self, 0.8, 0.2, chapel + Vector3(-4.2, 3.4, -3.05), "glass").rotation.x = PI / 2
	_sign(chapel + Vector3(-4.2, 4.3, -2.9), "CHAPEL STEPS", 0.0)
	# The Widow's Well: a stone well with a winch in the crossing.
	var well: Vector3 = LANDMARKS["WELL"] + Vector3(1.6, 0, 1.6)
	kit.cylinder(self, 0.8, 0.8, well + Vector3(0, 0.4, 0), "stone", 0.85, true)
	for x: float in [-0.7, 0.7]:
		kit.box(self, Vector3(0.1, 1.7, 0.1), well + Vector3(x, 1.2, 0), "timber")
	kit.box(self, Vector3(1.6, 0.1, 0.1), well + Vector3(0, 2.05, 0), "timber")
	_sign(LANDMARKS["WELL"] + Vector3(2.9, 3.0, 0), "WIDOW’S WELL", -PI / 2)
	# The Old Rag Market: tattered awnings and heaps of cloth.
	var market: Vector3 = LANDMARKS["MARKET"]
	for index: int in range(3):
		var stall := market + Vector3(-2.2, 0, -2.0 + index * 2.0)
		kit.box(self, Vector3(1.2, 0.8, 1.6), stall + Vector3(0, 0.4, 0), "wood", true)
		kit.box(self, Vector3(1.6, 0.05, 1.8), stall + Vector3(0.2, 2.2, 0), ["curtain", "linen", "velvet"][index]).rotation.z = 0.3
		kit.sphere(self, 0.5, stall + Vector3(0, 0.9, 0), ["linen", "trim", "velvet"][index], 0.5)
	_sign(market + Vector3(-2.9, 3.0, -1.5), "RAG MARKET", PI / 2)
	# Tanner's Row: hides stretched on frames above red-stained vats.
	var tannery: Vector3 = LANDMARKS["TANNERY"]
	for index: int in range(2):
		kit.cylinder(self, 0.7, 0.8, tannery + Vector3(2.2, 0.4, -1.2 + index * 2.4), "wood", 0.7, true)
		kit.cylinder(self, 0.62, 0.02, tannery + Vector3(2.2, 0.79, -1.2 + index * 2.4), kit.material(Color("5a1010"), 0.4))
		kit.box(self, Vector3(0.06, 1.6, 1.4), tannery + Vector3(2.9, 2.2, -1.2 + index * 2.4), "plaster_warm")
	_sign(tannery + Vector3(2.9, 3.6, 0), "TANNER’S ROW", -PI / 2)
	# The Mourning Gate in the south wall: barred until the police are satisfied.
	var gate: Vector3 = LANDMARKS["GATE"]
	for side: float in [-1.0, 1.0]:
		kit.box(self, Vector3(0.6, 4.6, 0.6), gate + Vector3(side * 3.2, 2.3, -3.3), "stone", true)
	kit.box(self, Vector3(7.0, 0.6, 0.8), gate + Vector3(0, 4.8, -3.3), "stone")
	_sign(gate + Vector3(0, 5.5, -3.0), "MOURNING GATE", 0.0)
	exit_gate = Node3D.new()
	add_child(exit_gate)
	kit.box(exit_gate, Vector3(5.8, 4.2, 0.2), gate + Vector3(0, 2.1, -3.3), "dark", true).visible = false
	for index: int in range(15):
		kit.box(exit_gate, Vector3(0.08, 4.2, 0.08), gate + Vector3(-2.8 + index * 0.4, 2.1, -3.3), "iron")
		kit.sphere(exit_gate, 0.07, gate + Vector3(-2.8 + index * 0.4, 4.25, -3.3), "iron")
	for y: float in [0.6, 2.1, 3.6]:
		kit.box(exit_gate, Vector3(5.8, 0.1, 0.1), gate + Vector3(0, y, -3.3), "iron")


## A painted hanging sign on a bracket. The lettering belongs to the world.
func _sign(at: Vector3, text: String, yaw: float) -> void:
	var board := Node3D.new()
	board.position = at
	board.rotation.y = yaw
	add_child(board)
	kit.box(board, Vector3(0.05, 0.05, 1.2), Vector3(0, 0.45, 0), "iron").rotation.y = PI / 2
	kit.box(board, Vector3(max(1.4, text.length() * 0.12), 0.5, 0.06), Vector3.ZERO, "timber")
	var label := Label3D.new()
	label.set_meta("diegetic", true)
	label.text = text
	label.font_size = 42
	label.pixel_size = 0.0045
	label.modulate = Color("e8d7a8")
	label.outline_size = 0
	label.position = Vector3(0, 0, 0.04)
	board.add_child(label)
	var back := label.duplicate() as Label3D
	back.set_meta("diegetic", true)
	back.position = Vector3(0, 0, -0.04)
	back.rotation.y = PI
	board.add_child(back)


func _lamp(spot: Vector3) -> void:
	kit.cylinder(self, 0.08, 3.6, spot + Vector3(0, 1.8, 0), "iron", -1.0, true)
	kit.box(self, Vector3(0.36, 0.5, 0.36), spot + Vector3(0, 3.85, 0), "gas")
	kit.flare(self, spot + Vector3(0, 3.85, 0), Color("e8f0a0"), 0.7)
	var light: OmniLight3D = kit.light(self, spot + Vector3(0, 3.6, 0), Color("d8e0a0"), 2.6, 9.0)
	gas_lights.append(light)
	lamp_base.append(light.light_energy)


func _laundry(rng: RandomNumberGenerator) -> void:
	for spot: Array in [[-20.0, -20.0], [0.0, -20.0], [20.0, -43.0], [-20.0, -43.0], [0.0, -43.0]]:
		var x: float = spot[0]
		var z: float = spot[1]
		kit.rope(self, Vector3(x - HALF, 6.4, z), Vector3(x + HALF, 6.4, z), 0.4, "linen")
		for index: int in range(4):
			kit.box(self, Vector3(0.6, rng.randf_range(0.6, 1.1), 0.02), Vector3(x - 2.2 + index * 1.4, 5.6, z), ["linen", "plaster_cool", "trim"][index % 3]).rotation.x = rng.randf_range(-0.15, 0.15)


func _residents() -> void:
	# Frightened residents frozen in doorways; tragedy masks, turned toward the fog.
	var cast: Array = [
		[Vector3(-3.4, 0, -17.0), PI / 2 + 0.4, {"costume": "velvet", "skirt": true, "hat": "hood", "mask": "tragedy", "left_arm": Vector3(2.2, 0, 0.4), "right_arm": Vector3(2.0, 0, 0.5), "lean": -0.2}],
		[Vector3(16.6, 0, -23.0), -PI / 2 - 0.3, {"costume": "trim", "hat": "cap", "kneel": true, "mask": "tragedy", "lean": 0.4, "right_arm": Vector3(2.4, 0, 0.3), "left_arm": Vector3(2.3, 0, 0.3)}],
		[Vector3(-16.6, 0, -40.0), PI / 2, {"costume": "linen", "skirt": true, "hat": "hood", "mask": "tragedy", "right_arm": Vector3(1.2, 0, 0.1)}],
		[Vector3(3.4, 0, -47.0), -PI / 2 + 0.6, {"costume": "plaster_warm", "hat": "cap", "mask": "tragedy", "right_arm": Vector3(1.5, 0, -0.2), "lean": 0.1}],
		[Vector3(22.4, 0, -12.5), -PI / 2, {"costume": "rose", "hat": "tophat", "mask": "comedy", "right_arm": Vector3(1.6, 0, 0.1), "left_arm": Vector3(0.3, 0, 0.1)}],
	]
	for entry: Array in cast:
		var actor: Node3D = ActorKit.make(kit, entry[2])
		add_child(actor)
		actor.position = entry[0]
		actor.rotation.y = entry[1]


func _rats(rng: RandomNumberGenerator) -> void:
	for index: int in range(20):
		var street: bool = index % 2 == 0
		var spot := Vector3(STREET_X[index % 3] + rng.randf_range(-2.6, 2.6), 0.07, rng.randf_range(-56.0, -8.0)) if street else Vector3(rng.randf_range(-22.0, 22.0), 0.07, STREET_Z[index % 3] + rng.randf_range(-2.6, 2.6))
		var rat := Node3D.new()
		rat.position = spot
		rat.rotation.y = rng.randf() * TAU
		add_child(rat)
		kit.sphere(rat, 0.08, Vector3.ZERO, "iron", 0.7)
		kit.sphere(rat, 0.045, Vector3(0, 0.01, 0.1), "iron")
		kit.cylinder(rat, 0.008, 0.25, Vector3(0, 0, -0.18), "flesh", 0.003).rotation.x = PI / 2
		if index % 3 == 0:
			var run := create_tween().set_loops()
			run.tween_property(rat, "position", spot + Vector3(rng.randf_range(-2, 2), 0, rng.randf_range(-2, 2)), rng.randf_range(0.8, 1.4))
			run.tween_property(rat, "position", spot, rng.randf_range(0.8, 1.4))


func _make_shadow() -> Node3D:
	var figure: Node3D = ActorKit.make(kit, {"costume": "black", "cape": "black", "legs": "black", "sleeve": "black", "hat": "tophat", "skin": "black", "glove": "black", "right_arm": Vector3(0.12, 0, 0.08), "left_arm": Vector3(0.05, 0, 0.08), "nod": 0.25})
	# A spectre cannot block the route or occlude its own visibility ray.
	for body: Node in figure.find_children("*", "CollisionObject3D", true, false):
		(body as CollisionObject3D).collision_layer = 0
	figure.scale = Vector3.ONE * 1.15
	kit.box(ActorKit.hand_of(figure), Vector3(0.36, 0.24, 0.14), Vector3(0, -0.1, 0.05), "black")
	# Two faint pale points where his eyes should be, and a cold rim light behind him.
	for x: float in [-0.045, 0.045]:
		var eye: MeshInstance3D = kit.sphere(figure, 0.014, Vector3(x, 1.69, 0.12), kit.material(Color("ffffff"), 0.0, Color("e8f0ff"), 2.0))
		eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rim: OmniLight3D = kit.light(figure, Vector3(0, 2.2, -1.1), Color("c8dcff"), 3.2, 4.0)
	rim.shadow_enabled = false
	return figure


func _rain_and_sound() -> void:
	rain = GPUParticles3D.new()
	rain.amount = 1400
	rain.lifetime = 1.0
	rain.visibility_aabb = AABB(Vector3(-14, -8, -14), Vector3(28, 20, 28))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(12, 0.5, 12)
	process.direction = Vector3(0.1, -1, 0)
	process.spread = 3.0
	process.initial_velocity_min = 16.0
	process.initial_velocity_max = 20.0
	process.gravity = Vector3(0, -9.8, 0)
	rain.process_material = process
	var streak := BoxMesh.new()
	streak.size = Vector3(0.012, 0.45, 0.012)
	var streak_material := StandardMaterial3D.new()
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.albedo_color = Color(0.75, 0.8, 0.9, 0.28)
	streak.material = streak_material
	rain.draw_pass_1 = streak
	add_child(rain)
	if DisplayServer.get_name() == "headless":
		return
	rain_player = _loop_player("res://shared/audio/whitechapel_rain.wav")
	heart_player = _loop_player("res://shared/audio/heartbeat.wav")
	var steps: AudioStreamWAV = load("res://shared/audio/shadow_steps.wav")
	steps.loop_mode = AudioStreamWAV.LOOP_FORWARD
	steps.loop_end = roundi(steps.get_length() * steps.mix_rate)
	steps_player = AudioStreamPlayer3D.new()
	steps_player.stream = steps
	steps_player.unit_size = 6.0
	steps_player.max_distance = 30.0
	steps_player.position.y = 0.2
	shadow.add_child(steps_player)
	whisper_player = AudioStreamPlayer3D.new()
	whisper_player.stream = load("res://shared/audio/shadow_whisper.wav")
	whisper_player.unit_size = 5.0
	add_child(whisper_player)


func _loop_player(path: String) -> AudioStreamPlayer:
	var stream: AudioStreamWAV = load(path)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.autoplay = true
	audio.volume_db = -80.0
	add_child(audio)
	return audio


func _process(delta: float) -> void:
	super._process(delta)
	if rain != null and player != null:
		rain.global_position = player.global_position + Vector3(0, 9.0, 0)
