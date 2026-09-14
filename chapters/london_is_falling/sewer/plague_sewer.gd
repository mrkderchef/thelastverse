class_name PlagueSewer
extends ActScene
## Act III, beneath the fallen bridge: a vaulted sewer crawling with plague rats, heaped with
## shrouded dead, and watched by beaked plague doctors. A buried plague cemetery holds four
## crypts; marking the two feuding houses with red crosses opens the gate to the ladder out.
## The tunnel runs toward -Z from where the player lands.

const NIGHT_SKY := preload("res://shared/shaders/night_sky.gdshader")
const CRYPT_SPOTS: Array[Vector3] = [Vector3(-8.85, 0, -31.0), Vector3(8.85, 0, -33.5), Vector3(-8.85, 0, -40.0), Vector3(8.85, 0, -42.5)]
const GATE_Z := -57.0

var crosses: Array[Node3D] = []
var gate: Node3D
var brush: StudyInteractable
var ladder: StudyInteractable


func _ready() -> void:
	_build_environment()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1665
	_tunnel(0.0, -26.0, 4.0)
	_tunnel(-48.0, -64.0, 3.0)
	_landing()
	_cemetery(rng)
	_exit()
	_rats(rng)
	scatter_trinkets([["bone", Vector3(-2.6, 0.1, -6.0)], ["bottle", Vector3(2.8, 0.1, -12.0)], ["bone", Vector3(1.8, 0.1, -36.0)], ["cup", Vector3(-3.2, 0.1, -41.0)], ["coin", Vector3(5.5, 0.1, -30.0)], ["candle", Vector3(-1.6, 0.1, -52.0)]])
	_add_player(Vector3(2.8, 2.6, -14.0), Vector3(-2.0, 0.6, -24.0))


func spawn_point() -> Array:
	if state != null and state.sewer_solved:
		return [Vector3(0, 0.05, -50.0), 0.0]
	return [Vector3(0, 0.05, -2.5), 0.0]


func apply_state(animate: bool = true) -> void:
	if state == null:
		return
	for index: int in range(4):
		crosses[index].visible = state.crypts[index] == 1
	brush.set_available(state.item_waiting("brush"))
	var y: float = 7.5 if state.sewer_solved else 2.0
	if animate and is_inside_tree():
		create_tween().tween_property(gate, "position:y", y, 2.5).set_trans(Tween.TRANS_SINE)
	else:
		gate.position.y = y
	ladder.set_available(state.sewer_solved)
	super.apply_state(animate)


func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("050806")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("6a7a58")
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.25
	environment.glow_enabled = true
	environment.glow_intensity = 1.1
	environment.ssao_enabled = true
	environment.ssao_intensity = 1.8
	environment.fog_enabled = true
	environment.fog_light_color = Color("2a3420")
	environment.fog_density = 0.03
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.025
	environment.volumetric_fog_albedo = Color("b8c89a")
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.9
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)


## A brick sewer tunnel: walls, a vaulted roof, ribs, a sludge channel, and torches.
func _tunnel(z_from: float, z_to: float, half_width: float) -> void:
	var length: float = z_from - z_to
	var mid: float = (z_from + z_to) / 2.0
	kit.box(self, Vector3(half_width * 2.0, 0.2, length), Vector3(0, -0.1, mid), "cobble", true)
	for side: float in [-1.0, 1.0]:
		kit.box(self, Vector3(0.4, 3.2, length), Vector3(side * (half_width + 0.2), 1.6, mid), "brick", true)

		kit.box(self, Vector3(0.3, 0.25, length), Vector3(side * 1.25, 0.06, mid), "stone")
	for segment: int in range(16):
		var a: float = segment * PI / 16.0
		var b: float = (segment + 1) * PI / 16.0
		var start := Vector2(cos(a) * half_width, 2.35 + sin(a) * 1.5)
		var finish := Vector2(cos(b) * half_width, 2.35 + sin(b) * 1.5)
		var center: Vector2 = (start + finish) * 0.5
		var vault := kit.box(self, Vector3(start.distance_to(finish) + 0.06, 0.2, length), Vector3(center.x, center.y, mid), "brick")
		vault.rotation.z = (finish - start).angle()
	var water := ShaderMaterial.new()
	water.shader = preload("res://shared/shaders/sewer_water.gdshader")
	kit.box(self, Vector3(2.3, 0.02, length), Vector3(0, 0.025, mid), water)
	# Low wet masonry ledges, rusted service pipes and repeated stone vault ribs.
	for side: float in [-1.0, 1.0]:
		kit.cylinder(self, 0.11, length, Vector3(side * (half_width - 0.15), 2.3, mid), "iron").rotation.x = PI / 2
		var detail_z: float = z_from - 2.0
		while detail_z > z_to:
			kit.cylinder(self, 0.15, 0.1, Vector3(side * (half_width - 0.15), 2.3, detail_z), "trim").rotation.x = PI / 2
			kit.box(self, Vector3(0.025, 1.2, 0.55), Vector3(side * (half_width - 0.015), 0.65, detail_z), "ivy")
			kit.box(self, Vector3(0.32, 0.12, 0.48), Vector3(side * 1.29, 0.15, detail_z), "brick")
			detail_z -= 2.5
	var arch_z: float = z_from - 1.5
	while arch_z > z_to:
		for segment: int in range(11):
			var angle: float = (segment + 0.5) * PI / 11.0
			var rib := kit.box(self, Vector3(half_width * PI / 11.0 + 0.04, 0.22, 0.28), Vector3(cos(angle) * (half_width - 0.22), 2.35 + sin(angle) * 1.3, arch_z), "stone")
			rib.rotation.z = atan2(1.3 * cos(angle), -(half_width - 0.22) * sin(angle))
		arch_z -= 4.0
	kit.box(self, Vector3(half_width * 2.0, 0.3, length), Vector3(0, 4.1, mid), "black")
	var z: float = z_from - 1.5
	while z > z_to:
		for side: float in [-1.0, 1.0]:
			kit.box(self, Vector3(0.5, 3.4, 0.4), Vector3(side * (half_width - 0.05), 1.7, z), "brick")
		if int(absf(z)) % 8 < 3:
			_torch(Vector3(-half_width + 0.25, 1.9, z))
		z -= 4.0


func _torch(spot: Vector3) -> void:
	var inward: float = -signf(spot.x)
	kit.box(self, Vector3(0.1, 0.1, 0.1), spot + Vector3(inward * 0.05, 0, 0), "iron")
	kit.cylinder(self, 0.04, 0.5, spot + Vector3(inward * 0.2, 0.2, 0), "timber").rotation.z = inward * 0.5
	kit.sphere(self, 0.09, spot + Vector3(inward * 0.32, 0.48, 0), "flame", 1.8)
	kit.flare(self, spot + Vector3(inward * 0.32, 0.5, 0), Color("ffa04a"), 1.0)
	flicker(kit.light(self, spot + Vector3(inward * 0.5, 0.6, 0), Color("ff9a4a"), 2.2, 7.0))


func _landing() -> void:
	# Daylight falls through the hole the bridge tore open.
	kit.light(self, Vector3(0, 3.8, -1.5), Color("d8e8ff"), 3.0, 8.0, true)
	kit.flare(self, Vector3(0, 4.0, -1.5), Color("eef6ff"), 3.0)
	kit.box(self, Vector3(8.0, 4.5, 0.4), Vector3(0, 2.2, 0.6), "brick", true)
	for index: int in range(9):
		var spot := Vector3(-2.5 + index * 0.65, 0.25 + (index % 3) * 0.2, -0.3 - (index % 4) * 0.4)
		kit.box(self, Vector3(0.7, 0.5, 0.6), spot, "stone").rotation = Vector3(index * 0.4, index, 0.3)
	for index: int in range(5):
		kit.box(self, Vector3(0.26, 0.26, 0.02), Vector3(-1.0 + index * 0.5, 0.05, -1.8 - index * 0.2), ["flag_red", "flag_yellow", "flag_blue"][index % 3]).rotation = Vector3(-PI / 2, index, 0)
	var bill: StudyInteractable = kit.note(self, "plague_bill", Vector3(3.75, 1.6, -6.0), Vector2(0.45, 0.6))
	bill.rotation.y = -PI / 2
	_corpse(Vector3(-3.0, 0.15, -9.0), 0.4)
	_corpse(Vector3(2.9, 0.15, -16.5), -0.2)
	_corpse(Vector3(3.1, 0.35, -16.9), 0.3)
	var doctor: Node3D = _doctor(Vector3(-2.8, 0, -18.0), PI / 2 - 0.3, {"right_arm": Vector3(1.4, 0, 0.1)})
	kit.sphere(ActorKit.hand_of(doctor), 0.1, Vector3(0, -0.1, 0), "flame", 1.2)
	flicker(kit.light(doctor, Vector3(0.3, 1.0, 0.6), Color("ffc070"), 1.4, 4.0))


func _cemetery(rng: RandomNumberGenerator) -> void:
	kit.box(self, Vector3(18.0, 0.2, 22.0), Vector3(0, -0.1, -37.0), "cobble", true)
	for side: float in [-1.0, 1.0]:
		kit.box(self, Vector3(0.4, 5.0, 22.0), Vector3(side * 9.2, 2.5, -37.0), "stone", true)
		kit.box(self, Vector3(5.0, 5.0, 0.4), Vector3(side * 6.5, 2.5, -26.0), "stone", true)
		kit.box(self, Vector3(6.0, 5.0, 0.4), Vector3(side * 6.0, 2.5, -48.0), "stone", true)
	kit.box(self, Vector3(18.4, 0.4, 22.0), Vector3(0, 5.2, -37.0), "black")
	for index: int in range(6):
		kit.cylinder(self, 0.35, 5.0, Vector3(-4.5 + (index % 2) * 9.0, 2.5, -30.0 - index * 3.2), "stone", -1.0, true)
	# Rows of graves, crosses, and a plague pit.
	for row: int in range(3):
		for column: int in range(5):
			var spot := Vector3(-5.5 + column * 2.2 + rng.randf_range(-0.3, 0.3), 0, -33.0 - row * 3.4)
			if absf(spot.x) < 1.3:
				continue
			if (row + column) % 2 == 0:
				kit.box(self, Vector3(0.6, 0.9, 0.15), spot + Vector3(0, 0.45, 0), "stone").rotation.z = rng.randf_range(-0.2, 0.2)
			else:
				kit.box(self, Vector3(0.1, 1.0, 0.1), spot + Vector3(0, 0.5, 0), "timber")
				kit.box(self, Vector3(0.6, 0.1, 0.1), spot + Vector3(0, 0.75, 0), "timber")
			kit.box(self, Vector3(0.9, 0.15, 1.6), spot + Vector3(0, 0.07, 0.9), "trim")
			if rng.randf() < 0.4:
				candle(spot + Vector3(0.3, 0.0, 0.3), false)
	kit.box(self, Vector3(3.2, 0.05, 2.2), Vector3(4.6, 0.02, -45.5), "black")
	for index: int in range(4):
		_corpse(Vector3(3.8 + index * 0.5, 0.2 + (index % 2) * 0.2, -45.6 + (index % 3) * 0.4), index * 0.4)
	var cart := Vector3(-5.2, 0, -45.0)
	kit.box(self, Vector3(1.4, 0.5, 2.4), cart + Vector3(0, 0.65, 0), "wood", true)
	for z: float in [-0.9, 0.9]:
		kit.cylinder(self, 0.4, 0.1, cart + Vector3(0.75, 0.4, z), "timber").rotation.z = PI / 2
	for index: int in range(3):
		_corpse(cart + Vector3(-0.2 + index * 0.25, 1.05 + index * 0.18, 0), index * 0.3)
	_doctor(Vector3(-1.9, 0, -38.5), PI / 2 + 0.6, {"right_arm": Vector3(1.6, 0, 0.3), "left_arm": Vector3(0.3, 0, 0.1)})
	_doctor(Vector3(3.2, 0, -44.3), PI + 0.4, {"kneel": true, "right_arm": Vector3(1.0, 0, 0.2), "left_arm": Vector3(1.1, 0, -0.2)})
	# Four crypt doors, each carved with a house's crest.
	for index: int in range(4):
		_crypt(index)
	var pot := Vector3(-2.6, 0, -28.2)
	kit.cylinder(self, 0.25, 0.45, pot + Vector3(0, 0.22, 0), "iron", 0.28, true)
	kit.cylinder(self, 0.25, 0.02, pot + Vector3(0, 0.44, 0), "rose")
	brush = kit.interactable(self, "take", "ITEM_BRUSH_NAME", "TAKE_BRUSH_INSPECT", pot + Vector3(0, 0.62, 0), Vector3(0.4, 0.4, 0.4), -1, "brush")
	kit.cylinder(brush, 0.02, 0.5, Vector3(0, 0, 0), "wood").rotation.z = 0.4
	kit.box(brush, Vector3(0.08, 0.12, 0.04), Vector3(-0.1, -0.22, 0), "rose").rotation.z = 0.4
	kit.box(self, Vector3(0.6, 1.1, 0.5), Vector3(2.4, 0.55, -28.3), "timber", true)
	var warrant: StudyInteractable = kit.note(self, "warrant", Vector3(2.4, 1.14, -28.3), Vector2(0.4, 0.3), Vector3(-PI / 2 + 0.4, 0, 0))
	warrant.rotation.y = PI
	candle(Vector3(2.7, 1.1, -28.1), false)
	flicker(kit.light(self, Vector3(0, 4.2, -37.0), Color("b8d0a0"), 2.6, 14.0))
	for spot: Vector3 in [Vector3(-6.0, 3.5, -31.0), Vector3(6.0, 3.5, -42.0)]:
		kit.light(self, spot, Color("9ab88a"), 1.4, 8.0)


func _crypt(index: int) -> void:
	var spot: Vector3 = CRYPT_SPOTS[index]
	var node := Node3D.new()
	node.position = spot
	node.rotation.y = PI / 2 if spot.x < 0 else -PI / 2
	add_child(node)
	kit.box(node, Vector3(2.2, 3.2, 0.3), Vector3(0, 1.6, 0.05), "stone")
	kit.box(node, Vector3(1.3, 2.2, 0.1), Vector3(0, 1.1, 0.22), "iron")
	kit.box(node, Vector3(1.6, 0.3, 0.2), Vector3(0, 2.4, 0.25), "stone")
	var crest := Vector3(0, 2.75, 0.3)
	match index:
		0:
			for offset: Vector3 in [Vector3(0, 0.08, 0), Vector3(-0.08, -0.02, 0), Vector3(0.08, -0.02, 0)]:
				kit.sphere(node, 0.08, crest + offset, "rose")
		1:
			kit.cylinder(node, 0.14, 0.12, crest, "gold", 0.16).rotation.x = 0.2
		2:
			for offset: Vector3 in [Vector3(0, 0.08, 0), Vector3(-0.09, -0.03, 0), Vector3(0.09, -0.03, 0)]:
				kit.box(node, Vector3(0.1, 0.1, 0.06), crest + offset, "ivy").rotation.z = 0.7
		_:
			kit.cylinder(node, 0.14, 0.2, crest, "gold", 0.05)
	var cross := Node3D.new()
	node.add_child(cross)
	kit.box(cross, Vector3(0.18, 1.5, 0.02), Vector3(0, 1.2, 0.28), "sigil")
	kit.box(cross, Vector3(1.0, 0.18, 0.02), Vector3(0, 1.4, 0.28), "sigil")
	crosses.append(cross)
	kit.interactable(node, "crypt_door", ["CRYPT_ROSE", "CRYPT_CROWN", "CRYPT_IVY", "CRYPT_BELL"][index], "CRYPT_INSPECT", Vector3(0, 1.3, 0.35), Vector3(1.4, 2.4, 0.3), index)
	candle(node.to_global(Vector3(0.85, 0, 0.7)), false)


func _exit() -> void:
	gate = Node3D.new()
	gate.position = Vector3(0, 2.0, GATE_Z)
	add_child(gate)
	kit.box(gate, Vector3(6.0, 4.0, 0.2), Vector3.ZERO, "dark", true).visible = false
	for index: int in range(11):
		kit.box(gate, Vector3(0.1, 4.0, 0.1), Vector3(-3.0 + index * 0.6, 0, 0), "iron")
	for y: float in [-1.4, 0.0, 1.4]:
		kit.box(gate, Vector3(6.0, 0.14, 0.14), Vector3(0, y, 0), "iron")
	kit.box(self, Vector3(6.4, 4.4, 0.4), Vector3(0, 2.2, -64.2), "brick", true)
	for index: int in range(12):
		kit.box(self, Vector3(1.0, 0.06, 0.06), Vector3(0, 0.4 + index * 0.35, -63.8), "iron")
	for x: float in [-0.5, 0.5]:
		kit.box(self, Vector3(0.08, 4.2, 0.08), Vector3(x, 2.1, -63.8), "iron")
	kit.light(self, Vector3(0, 3.9, -63.0), Color("b8c8e0"), 2.2, 6.0)
	kit.flare(self, Vector3(0, 4.0, -63.4), Color("d0dcf0"), 2.0)
	ladder = kit.interactable(self, "climb", "LADDER", "LADDER_INSPECT", Vector3(0, 1.4, -63.6), Vector3(1.2, 2.4, 0.4))


func _doctor(spot: Vector3, yaw: float, pose: Dictionary) -> Node3D:
	var look: Dictionary = {"costume": "black", "cape": "black", "legs": "black", "sleeve": "black", "hat": "plague", "skin": "dark"}
	look.merge(pose, true)
	var doctor: Node3D = ActorKit.make(kit, look)
	add_child(doctor)
	doctor.position = spot
	doctor.rotation.y = yaw
	var subject := Vector3(3.9, 0, -45.6) if spot.z < -40.0 else Vector3(0, 0, spot.z + 1.2)
	doctor.look_at(subject, Vector3.UP, true)
	kit.box(ActorKit.hand_of(doctor), Vector3(0.03, 1.0, 0.03), Vector3(0, -0.3, 0.05), "timber")
	return doctor


## A body sewn into a linen shroud and bound with rope.
func _corpse(spot: Vector3, yaw: float) -> void:
	var body := Node3D.new()
	body.position = spot
	body.rotation.y = yaw
	add_child(body)
	kit.cylinder(body, 0.2, 1.6, Vector3.ZERO, "linen", 0.16).rotation.x = PI / 2
	kit.sphere(body, 0.17, Vector3(0, 0.02, -0.85), "linen")
	for z: float in [-0.5, 0.0, 0.5]:
		kit.cylinder(body, 0.215, 0.04, Vector3(0, 0, z), "trim").rotation.x = PI / 2


## Plague rats: some huddle in heaps, others scurry back and forth along the walls.
func _rats(rng: RandomNumberGenerator) -> void:
	for index: int in range(46):
		var spot := Vector3(rng.randf_range(-3.6, 3.6), 0.07, rng.randf_range(-62.0, -4.0))
		if absf(spot.x) < 1.5:
			spot.x = 1.6 if spot.x >= 0 else -1.6
		if spot.z < -26.0 and spot.z > -48.0:
			spot.x = rng.randf_range(-8.5, 8.5)
		var rat := Node3D.new()
		rat.position = spot
		rat.rotation.y = rng.randf() * TAU
		add_child(rat)
		kit.sphere(rat, 0.08, Vector3.ZERO, "iron", 0.7)
		kit.sphere(rat, 0.045, Vector3(0, 0.01, 0.1), "iron")
		kit.cylinder(rat, 0.008, 0.25, Vector3(0, 0, -0.18), "flesh", 0.003).rotation.x = PI / 2
		for x: float in [-0.02, 0.02]:
			kit.sphere(rat, 0.008, Vector3(x, 0.03, 0.14), "sigil")
		if index % 3 == 0:
			var run := create_tween().set_loops()
			var target: Vector3 = spot + Vector3(0, 0, rng.randf_range(-2.5, 2.5))
			run.tween_property(rat, "position", target, rng.randf_range(0.8, 1.6))
			run.tween_callback(rat.rotate_y.bind(PI))
			run.tween_property(rat, "position", spot, rng.randf_range(0.8, 1.6))
			run.tween_callback(rat.rotate_y.bind(PI))
