class_name StudyRoom
extends ActScene
## Act I study: a lived-in bedroom-study with four puzzles hidden in its furniture.
## Authored dimensions with procedural placeholder meshes; no external assets and no
## floating text. The look is deliberately degraded early-3D.

const NIGHT_SKY := preload("res://shared/shaders/night_sky.gdshader")
const AGES := preload("res://chapters/london_is_falling/study/seven_ages/ages_dial_model.gd")
const MIRROR := preload("res://chapters/london_is_falling/study/hamlet_mirror/mirror_cabinet_model.gd")
const BANQUET := preload("res://chapters/london_is_falling/study/macbeth_banquet/banquet_model.gd")
const BALCONY := preload("res://chapters/london_is_falling/study/balcony_lights/balcony_model.gd")
const LOCK := preload("res://chapters/london_is_falling/study/exit_lock/letter_lock_model.gd")
## Inner wall planes, just in front of the chair rail.
const LEFT_WALL := -5.84
const RIGHT_WALL := 5.84
const SPAWN := Vector3(0, 0.05, 2.6)
const SPAWN_YAW := -0.45

var door_pivot: Node3D
var door_body: StaticBody3D
var ages: AgesDialModel
var mirror: MirrorCabinetModel
var banquet: BanquetModel
var balcony: BalconyModel
var lock: LetterLockModel


func _ready() -> void:
	_build_environment()
	_build_shell()
	_build_door()
	ages = _station(AGES.new(), Vector3(LEFT_WALL, 0, -2.6), PI / 2)
	mirror = _station(MIRROR.new(), Vector3(RIGHT_WALL, 0, -2.3), -PI / 2)
	banquet = _station(BANQUET.new(), Vector3(LEFT_WALL, 0, 3.0), PI / 2)
	balcony = _station(BALCONY.new(), Vector3(RIGHT_WALL, 0, 1.5), -PI / 2)
	candle(ages.to_global(Vector3(-0.62, 0.9, 0.3)), false)
	candle(banquet.to_global(Vector3(-0.8, 0.95, 0.55)), false)
	candle(balcony.to_global(Vector3(0.8, 1.01, 0.62)), false)
	StudyDressing.build(self, kit)
	scatter_trinkets([["book", Vector3(-2.1, 0.12, 2.6)], ["apple", Vector3(3.2, 0.95, -5.2)], ["cup", Vector3(-4.3, 0.75, -0.7)], ["candle", Vector3(-0.6, 1.02, 5.55)], ["book", Vector3(0.4, 0.12, -3.3)], ["bottle", Vector3(-5.35, 0.7, 3.4)], ["bread", Vector3(2.2, 0.12, 3.6)]])
	_build_backstage()
	_add_player(Vector3(3.4, 2.3, 4.3), Vector3(-2.8, 1.3, -2.2))
	player.reset_at(SPAWN, SPAWN_YAW)


func spawn_point() -> Array:
	return [SPAWN, SPAWN_YAW]


func apply_state(animate: bool = true) -> void:
	if state == null:
		return
	var angle: float = -1.5 if state.door_open else 0.0
	if animate and is_inside_tree():
		create_tween().tween_property(door_pivot, "rotation:y", angle, 1.6).set_trans(Tween.TRANS_SINE)
	else:
		door_pivot.rotation.y = angle
	door_body.collision_layer = 0 if state.door_open else 1
	ages.apply(state, animate)
	mirror.apply(state, animate)
	banquet.apply(state, animate)
	balcony.apply(state, animate)
	lock.apply(state)
	super.apply_state(animate)


func make_held_piece(station: String, piece: int) -> Node3D:
	var model: Node3D
	if station == "ages":
		model = AGES.make_piece(kit, piece)
		model.scale = Vector3.ONE * 1.6
	elif station == "macbeth":
		model = BANQUET.make_figure(kit, piece)
		model.position.y = -0.18
		model.scale = Vector3.ONE * 0.9
	return model


func _station(model: Node3D, location: Vector3, yaw: float) -> Variant:
	model.position = location
	model.rotation.y = yaw
	add_child(model)
	model.call("build", kit)
	return model


func _build_environment() -> void:
	var environment := Environment.new()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = NIGHT_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e8dcc8")
	environment.ambient_light_energy = 1.05
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.35
	environment.glow_enabled = true
	environment.glow_intensity = 1.1
	environment.glow_strength = 1.15
	environment.glow_bloom = 0.05
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	environment.ssao_enabled = true
	environment.ssao_intensity = 1.4
	environment.fog_enabled = true
	environment.fog_light_color = Color("3c3f52")
	environment.fog_density = 0.008
	environment.fog_sky_affect = 0.2
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.007
	environment.volumetric_fog_albedo = Color("cdd2de")
	environment.volumetric_fog_length = 40.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.1
	environment.adjustment_contrast = 1.06
	environment.adjustment_brightness = 1.0
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	# Moonlight through the painted window, a dim bruise by the bed, red at the door.
	# Afternoon sun pours through the window; the room is warm and bright.
	kit.light(self, Vector3(3.8, 2.8, -4.6), Color("fff0c8"), 4.0, 10.0, true)
	kit.light(self, Vector3(-4.0, 2.8, 4.4), Color("ffe6c8"), 1.6, 6.0)
	kit.light(self, Vector3(4.2, 2.8, 3.6), Color("fff2dc"), 1.6, 6.0)
	kit.light(self, Vector3(0, 3.0, -5.0), Color("ffd8a8"), 1.2, 5.0)
	# Cool fill so the walls and furniture read, balancing the warm candles.
	for spot: Vector3 in [Vector3(-3.5, 3.4, -3.0), Vector3(3.5, 3.4, -1.0), Vector3(-3.0, 3.4, 3.0), Vector3(3.0, 3.4, 4.2)]:
		kit.light(self, spot, Color("fff4e0"), 1.0, 7.5)


func _build_shell() -> void:
	kit.box(self, Vector3(12.4, 0.25, 12.4), Vector3(0, -0.125, 0), "dark", true)
	for index: int in range(24):
		var shade: float = 0.34 + float(index % 4) * 0.035
		var plank: MeshInstance3D = kit.box(self, Vector3(0.49, 0.035, 12), Vector3(-5.75 + index * 0.5, 0.015, 0), "wood")
		plank.material_override = kit.material(Color(shade * 1.45, shade * 1.02, shade * 0.72))
	kit.box(self, Vector3(0.25, 4.5, 12), Vector3(-6.1, 2.25, 0), "wall", true)
	kit.box(self, Vector3(0.25, 4.5, 12), Vector3(6.1, 2.25, 0), "wall", true)
	kit.box(self, Vector3(12, 4.5, 0.25), Vector3(0, 2.25, 6.1), "wall", true)
	for x: float in [-3.65, 3.65]:
		kit.box(self, Vector3(4.7, 4.5, 0.25), Vector3(x, 2.25, -6.1), "wall", true)
	kit.box(self, Vector3(2.6, 1.1, 0.25), Vector3(0, 3.95, -6.1), "wall", true)
	kit.box(self, Vector3(12.4, 0.2, 12.4), Vector3(0, 4.55, 0), "dark")
	for x: float in [-5.95, 5.95]:
		for z: float in [-5.8, 5.8]:
			kit.box(self, Vector3(0.18, 4.4, 0.22), Vector3(x, 2.2, z), "trim")
		for y: float in [0.1, 4.0]:
			kit.box(self, Vector3(0.18, 0.13, 12), Vector3(x, y, 0), "trim")
	for z: float in [-5.95, 5.95]:
		kit.box(self, Vector3(12, 0.15, 0.16), Vector3(0, 4.0, z), "trim")
	for x: float in [-4.0, 0.0, 4.0]:
		kit.box(self, Vector3(0.22, 0.3, 12), Vector3(x, 4.3, 0), "wood")
	kit.box(self, Vector3(5.0, 0.025, 6.4), Vector3(-0.2, 0.047, 0.2), "rug")
	for x: float in [-2.6, 2.2]:
		kit.box(self, Vector3(0.035, 0.01, 6.2), Vector3(x, 0.065, 0.2), "gold")
	# A moonlit painted window, visibly a stage flat from the passage.
	kit.box(self, Vector3(2.4, 2.7, 0.12), Vector3(3.8, 2.5, -5.9), "daylight")
	for x: float in [2.55, 3.8, 5.05]:
		kit.box(self, Vector3(0.1, 2.9, 0.2), Vector3(x, 2.5, -5.8), "trim")
	for y: float in [1.05, 2.4, 3.95]:
		kit.box(self, Vector3(2.6, 0.1, 0.2), Vector3(3.8, y, -5.8), "trim")
	for index: int in range(6):
		kit.box(self, Vector3(0.12, 0.6 + (index % 3) * 0.18, 0.04), Vector3(2.8 + index * 0.36, 1.5, -5.81), "dark")
	kit.flare(self, Vector3(4.4, 3.3, -5.7), Color("fff4c8"), 1.2)
	for x: float in [2.3, 5.15]:
		kit.box(self, Vector3(0.3, 3.3, 0.06), Vector3(x, 2.3, -5.72), "velvet")
	kit.box(self, Vector3(3.3, 0.06, 0.06), Vector3(3.8, 3.98, -5.7), "iron")


func _build_door() -> void:
	door_pivot = Node3D.new()
	door_pivot.position = Vector3(-1.2, 0, -6.0)
	add_child(door_pivot)
	kit.box(door_pivot, Vector3(2.4, 3.35, 0.16), Vector3(1.2, 1.675, 0), "wood")
	for x: float in [0.18, 1.2, 2.22]:
		kit.box(door_pivot, Vector3(0.07, 3.1, 0.05), Vector3(x, 1.65, 0.1), "gold")
	for y: float in [0.2, 1.55, 3.15]:
		kit.box(door_pivot, Vector3(2.2, 0.07, 0.05), Vector3(1.2, y, 0.1), "gold")
	lock = LOCK.new()
	lock.position = Vector3(1.75, 1.25, 0.12)
	door_pivot.add_child(lock)
	lock.build(kit)
	door_body = StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 3.4, 0.22)
	shape.shape = box
	door_body.position = Vector3(0, 1.7, -6.0)
	door_body.add_child(shape)
	add_child(door_body)


func _build_backstage() -> void:
	# A short, sunlit gallery behind the door ends at a painting of London on a spring day.
	# Stepping into the painting leaves the study.
	kit.box(self, Vector3(4, 0.2, 8), Vector3(0, -0.1, -10), "wood", true)
	kit.box(self, Vector3(4, 0.2, 8), Vector3(0, 4.6, -10), "plaster_cream")
	for x: float in [-2.0, 2.0]:
		kit.box(self, Vector3(0.2, 4.5, 8), Vector3(x, 2.25, -10), "plaster_cream", true)
		kit.box(self, Vector3(0.1, 1.1, 8), Vector3(x * 0.96, 0.55, -10), "wood")
		for z: float in [-8.0, -11.0]:
			kit.box(self, Vector3(0.12, 0.3, 0.6), Vector3(x * 0.93, 2.2, z), "gold")
			candle(Vector3(x * 0.88, 2.35, z), false)
	kit.box(self, Vector3(1.6, 0.03, 7.0), Vector3(0, 0.02, -10), "rug")
	kit.box(self, Vector3(4, 4.5, 0.2), Vector3(0, 2.25, -14.2), "plaster_cream", true)
	var painting := Node3D.new()
	painting.position = Vector3(0, 1.9, -14.05)
	add_child(painting)
	kit.box(painting, Vector3(3.0, 2.3, 0.1), Vector3.ZERO, "gold")
	kit.box(painting, Vector3(2.7, 2.0, 0.04), Vector3(0, 0, 0.05), "plaster_sky")
	kit.box(painting, Vector3(2.7, 0.8, 0.04), Vector3(0, -0.6, 0.055), "water")
	kit.sphere(painting, 0.2, Vector3(0.9, 0.6, 0.07), "flag_yellow", 0.15)
	for cloud: Vector2 in [Vector2(-0.8, 0.7), Vector2(-0.4, 0.75), Vector2(0.2, 0.55)]:
		kit.sphere(painting, 0.14, Vector3(cloud.x, cloud.y, 0.07), "linen", 0.2).scale = Vector3(1.8, 1.0, 1.0)
	var looks: Array[String] = ["plaster_rose", "plaster_mint", "plaster_ochre", "plaster_lilac", "plaster_cream", "plaster_rose"]
	for index: int in range(6):
		var height: float = 0.35 + (index % 3) * 0.12
		kit.box(painting, Vector3(0.36, height, 0.03), Vector3(-1.1 + index * 0.44, -0.2 + height / 2.0, 0.08), looks[index])
		kit.box(painting, Vector3(0.38, 0.08, 0.03), Vector3(-1.1 + index * 0.44, -0.18 + height, 0.085), "roof_red").rotation.z = 0.3 * (index % 2 * 2 - 1)
	kit.box(painting, Vector3(2.6, 0.08, 0.03), Vector3(0, -0.28, 0.09), "stone")
	for arch: int in range(5):
		kit.box(painting, Vector3(0.12, 0.28, 0.03), Vector3(-1.05 + arch * 0.52, -0.43, 0.09), "stone")
	for flag: int in range(9):
		kit.box(painting, Vector3(0.06, 0.06, 0.02), Vector3(-1.2 + flag * 0.3, 0.3 - absf(flag - 4) * -0.02, 0.1), ["flag_red", "flag_yellow", "flag_blue"][flag % 3]).rotation.z = PI / 4
	kit.interactable(self, "painting", "PAINTING_NAME", "PAINTING_INSPECT", Vector3(0, 1.9, -13.9), Vector3(3.0, 2.3, 0.3))
	kit.light(self, Vector3(0, 3.4, -12.2), Color("fff2d8"), 1.3, 4.5)
	kit.light(self, Vector3(0, 2.8, -8), Color("ffe6c0"), 1.4, 5, true)
