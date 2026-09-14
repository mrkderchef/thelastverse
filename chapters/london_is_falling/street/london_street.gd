class_name LondonStreet
extends ActScene
## Act II: the streets of London on a bright afternoon, assembled by a theatre dreaming of
## London. The player steps out of the stage door and walks toward London Bridge, which
## falls as soon as they are on it, through three gates:
## Balcony Lane (Romeo & Juliet), the Witches' Square (Macbeth), and the riverside
## (Julius Caesar). Frozen actors stand everywhere. The road runs toward -Z.

const DAY_SKY := preload("res://shared/shaders/day_sky.gdshader")
const LANE := preload("res://chapters/london_is_falling/street/balcony_lane/balcony_lane_model.gd")
const SQUARE := preload("res://chapters/london_is_falling/street/witches_square/cauldron_model.gd")
const BRIDGE := preload("res://chapters/london_is_falling/street/london_bridge/london_bridge_model.gd")
const LANE_GATE_Z := -30.0
const SQUARE_GATE_Z := -62.0
## Walking this far onto London Bridge brings it down.
const COLLAPSE_Z := -104.0

var lane: BalconyLaneModel
var square: CauldronModel
var bridge: LondonBridgeModel
var chant: AudioStreamPlayer3D
var chant_announced: bool = false
var lane_gate: Node3D
var square_gate: Node3D
var environment: Environment
var sun: DirectionalLight3D


func _ready() -> void:
	_build_environment()
	StreetDressing.build(self, kit)
	lane = _model(LANE.new())
	square = _model(SQUARE.new())
	bridge = _model(BRIDGE.new())
	lane_gate = _gate(LANE_GATE_Z, 10.2, 7.5, true)
	square_gate = _gate(SQUARE_GATE_Z, 18.2, 6.5, false)
	# The witches never stop singing the rhyme over their cauldron.
	if DisplayServer.get_name() != "headless":
		chant = AudioStreamPlayer3D.new()
		var song: AudioStreamWAV = preload("res://shared/audio/witches_chant.wav")
		song.loop_mode = AudioStreamWAV.LOOP_FORWARD
		song.loop_end = roundi(song.get_length() * song.mix_rate)
		chant.stream = song
		chant.position = SQUARE.CENTER + Vector3(0, 1.6, 0)
		chant.unit_size = 9.0
		chant.max_distance = 40.0
		chant.autoplay = true
		add_child(chant)
	_add_player(Vector3(3.6, 3.4, -21.0), Vector3(-3.6, 2.2, -14.5))


func spawn_point() -> Array:
	if state != null and state.brew_solved:
		return [Vector3(0, 0.05, -64.0), 0.0]
	if state != null and state.props_solved:
		return [Vector3(0, 0.05, -32.0), 0.0]
	return [Vector3(0, 0.05, 0.8), 0.0]


func apply_state(animate: bool = true) -> void:
	if state == null:
		return
	lane.apply(state, animate)
	square.apply(state, animate)
	bridge.apply(state, animate)
	_lift(lane_gate, state.props_solved, 3.75, animate)
	_lift(square_gate, state.brew_solved, 3.25, animate)
	super.apply_state(animate)


func make_held_piece(station: String, piece: int) -> Node3D:
	var model: Node3D
	if station == "props":
		model = LANE.make_prop(kit, piece)
		model.scale = Vector3.ONE * 1.5
		model.position.y = -0.05
	elif station == "shelf":
		model = SQUARE.make_ingredient(kit, piece)
		model.scale = Vector3.ONE * 1.3
		model.position.y = -0.15
	return model


func _physics_process(_delta: float) -> void:
	if state != null:
		_report_threshold(state.bridge_lowered and player.position.z < COLLAPSE_Z)
		if not chant_announced and player.enabled and player.position.z < -33.0:
			chant_announced = true
			narrate.emit("WITCHES_SINGING")


func music_duck() -> float:
	if player == null:
		return 0.0
	var distance: float = player.global_position.distance_to(SQUARE.CENTER)
	return clampf(1.0 - (distance - 8.0) / 18.0, 0.0, 1.0)


func set_world_volume(linear: float) -> void:
	if chant != null:
		chant.volume_db = linear_to_db(maxf(linear * 2.2, 0.0001))


## A cloud crosses the sun when the fair lady climbs out: the bright afternoon drains to a
## cold, grey, foggy dusk within a few seconds.
func darken(seconds: float) -> void:
	var dusk: Tween = create_tween().set_parallel(true)
	dusk.tween_property(sun, "light_energy", 0.18, seconds)
	dusk.tween_property(sun, "light_color", Color("8a9ab8"), seconds)
	dusk.tween_property(environment, "ambient_light_energy", 0.22, seconds)
	dusk.tween_property(environment, "ambient_light_color", Color("7d8ca8"), seconds)
	dusk.tween_property(environment, "tonemap_exposure", 0.62, seconds)
	dusk.tween_property(environment, "adjustment_saturation", 0.45, seconds)
	dusk.tween_property(environment, "fog_density", 0.022, seconds)
	dusk.tween_property(environment, "fog_light_color", Color("4a5566"), seconds)
	dusk.tween_property(environment, "fog_sky_affect", 0.85, seconds)


func _model(model: Node3D) -> Variant:
	add_child(model)
	model.call("build", kit, self)
	return model


func _gate(z: float, width: float, height: float, curtain: bool) -> Node3D:
	var gate := Node3D.new()
	gate.position = Vector3(0, height / 2.0, z)
	add_child(gate)
	kit.box(gate, Vector3(width, height, 0.3), Vector3.ZERO, "iron" if curtain else "dark", true).visible = curtain
	if curtain:
		# An iron safety curtain, riveted and painted with a brick wall.
		kit.box(gate, Vector3(width - 0.4, height - 0.6, 0.05), Vector3(0, 0, 0.18), "brick")
		for row: int in range(int(height / 0.5)):
			kit.box(gate, Vector3(width - 0.4, 0.03, 0.02), Vector3(0, -height / 2.0 + 0.4 + row * 0.5, 0.21), "timber")
		for x: float in [-width / 2.0 + 0.2, width / 2.0 - 0.2]:
			for row: int in range(8):
				kit.sphere(gate, 0.05, Vector3(x, -height / 2.0 + 0.5 + row * 0.9, 0.2), "gold")
	else:
		# A rigging portcullis of timber and iron bars.
		for index: int in range(int(width / 0.6) + 1):
			kit.box(gate, Vector3(0.1, height, 0.1), Vector3(-width / 2.0 + index * 0.6, 0, 0), "iron")
		for row: int in range(5):
			kit.box(gate, Vector3(width, 0.18, 0.16), Vector3(0, -height / 2.0 + 0.4 + row * 1.4, 0), "timber")
	return gate


func _lift(gate: Node3D, open: bool, rest_y: float, animate: bool) -> void:
	var y: float = rest_y + 8.5 if open else rest_y
	if animate and is_inside_tree():
		create_tween().tween_property(gate, "position:y", y, 3.0).set_trans(Tween.TRANS_SINE)
	else:
		gate.position.y = y


func _build_environment() -> void:
	# A bright, cheerful afternoon: London is still whole.
	environment = Environment.new()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = DAY_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("f0e4d0")
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	environment.glow_bloom = 0.04
	environment.ssao_enabled = true
	environment.ssao_intensity = 1.2
	environment.fog_enabled = true
	environment.fog_light_color = Color("d8e4f0")
	environment.fog_density = 0.0025
	environment.fog_sky_affect = 0.1
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.35
	environment.adjustment_contrast = 1.05
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("ffe8c0")
	sun.light_energy = 1.9
	sun.shadow_enabled = true
	sun.basis = Basis.looking_at(-Vector3(-0.35, 0.55, -0.75).normalized(), Vector3.UP)
	add_child(sun)
