class_name LondonBridgeModel
extends Node3D
## The riverside and old London Bridge: stone arches crowded with houses, a gatehouse whose
## drawbridge stands raised, and the bridge engine whose calendar must be set to the Ides of
## March to lower it. Once the player walks out onto the bridge, it falls down, as the song
## promised. Built in street coordinates; the road runs toward -Z.

const MONTHS: Array[String] = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
const RAISED := 1.2
const HINGE_Z := -90.0
const DECK_START := -96.0
const SEGMENT_LENGTH := 7.5

var drawbridge: Node3D
var lady: Node3D
var lady_light: OmniLight3D
var niche: Node3D
var gap_wall: MeshInstance3D
var segments: Array[Node3D] = []
var month_label: Label3D
var day_label: Label3D
var lever: Node3D
var kit: PropKit
## True while she drags herself along the deck toward the player.
var crawling: bool = false
var crawl_clock: float = 0.0
var arms: Array[Node3D] = []
var lady_head: Node3D
var lady_mouth: MeshInstance3D
var debris: Node3D
var face_light: OmniLight3D
## The bricks that seal her alcove, and the chain nailed across them.
var seal_bricks: Array[MeshInstance3D] = []
var seal_chain: Node3D


func build(prop_kit: PropKit, scene: ActScene) -> void:
	kit = prop_kit
	_river(scene)
	_gatehouse()
	# While the drawbridge is raised, nobody walks off the end of the gatehouse.
	gap_wall = kit.box(self, Vector3(8.0, 4.0, 0.3), Vector3(0, 2.0, HINGE_Z - 0.2), "dark", true)
	gap_wall.visible = false
	drawbridge = Node3D.new()
	drawbridge.position = Vector3(0, 0, HINGE_Z)
	add_child(drawbridge)
	kit.box(drawbridge, Vector3(5.8, 0.4, 6.0), Vector3(0, -0.2, -3.0), "wood", true)
	for x: float in [-2.9, 2.9]:
		kit.box(drawbridge, Vector3(0.2, 1.0, 6.0), Vector3(x, 0.3, -3.0), "timber", true)
	for step: int in range(6):
		kit.box(drawbridge, Vector3(5.8, 0.03, 0.1), Vector3(0, 0.02, -0.5 - step), "iron")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1209
	for index: int in range(4):
		segments.append(_segment(DECK_START - index * SEGMENT_LENGTH, index, rng))
	kit.box(self, Vector3(8.0, 0.4, 10.0), Vector3(0, -0.2, -131.0), "cobble", true)
	for z: float in [-82.0]:
		for x: float in [-3.4, 3.4]:
			_lamp(scene, Vector3(x, 0, z))
	_engine(scene)
	_immured_lady()
	var plaque: StudyInteractable = kit.note(self, "confession", Vector3(-2.99, 1.6, -85.5), Vector2(0.6, 0.8))
	plaque.rotation.y = PI / 2
	kit.box(plaque, Vector3(0.7, 0.9, 0.02), Vector3(0, 0, -0.012), "stone")
	_caesar()


func apply(state: StudyState, animate: bool) -> void:
	var angle: float = 0.0 if state.bridge_lowered else RAISED
	if animate and is_inside_tree():
		create_tween().tween_property(drawbridge, "rotation:x", angle, 5.0).set_trans(Tween.TRANS_SINE)
	else:
		drawbridge.rotation.x = angle
	(gap_wall.get_child(0) as StaticBody3D).collision_layer = 0 if state.bridge_lowered else 1
	month_label.text = MONTHS[state.calendar[0]]
	day_label.text = str(state.calendar[1] + 1)
	lever.rotation.x = 1.0 if state.bridge_lowered else 0.0


## Her head, which the camera follows while she climbs and crawls.
func lady_position() -> Vector3:
	return lady_head.global_position if lady_head != null else lady.global_position + Vector3(0, 0.7, 0)


## The sealed alcove in the parapet, where the camera turns first.
func climb_point() -> Vector3:
	return Vector3(-4.1, 0.75, DECK_START - SEGMENT_LENGTH * 1.5)


## Something knocks behind the bricks; a hand punches through; the wall bursts outward and she
## drags herself out of the dark, head first, onto the deck. Returns how long this takes.
func awaken(witness: Vector3) -> float:
	var z: float = DECK_START - SEGMENT_LENGTH * 1.5
	lady.visible = true
	lady.position = Vector3(-5.25, 0.1, z)
	lady.rotation = Vector3(0, PI / 2.0, 0)
	crawling = true
	var escape := create_tween()
	for knock: int in range(3):
		escape.tween_callback(_shiver_bricks.bind(0.02 + knock * 0.015))
		escape.tween_interval(0.5 - knock * 0.08)
	# A hand breaks through the middle of the wall.
	escape.tween_callback(_burst_bricks.bind([7, 10]))
	escape.tween_property(lady, "position:x", -4.75, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	escape.tween_interval(0.8)
	escape.tween_callback(_burst_bricks.bind([]))
	escape.tween_property(lady, "position:x", -4.3, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# She drags herself out of the alcove in lurches.
	for step: int in range(3):
		escape.tween_interval(0.25)
		escape.tween_property(lady, "position", Vector3(-4.3 + (step + 1) * 0.35, 0.02, z), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	escape.tween_callback(_face_witness.bind(witness))
	var light_up := create_tween()
	light_up.tween_interval(1.5)
	light_up.tween_property(lady_light, "light_energy", 1.4, 1.5)
	return 4.4


## She crawls toward the player in fits and starts, stopping just out of reach.
## Returns how long the approach takes.
func crawl(witness: Vector3) -> float:
	var start: Vector3 = lady.position
	var goal := Vector3(witness.x, 0.02, witness.z)
	var direction: Vector3 = goal - start
	direction.y = 0
	var distance: float = maxf(direction.length() - 1.6, 0.0)
	var steps: int = maxi(1, ceili(distance / 0.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1606
	var approach := create_tween()
	var time: float = 0.0
	for step: int in range(steps):
		var at: Vector3 = start + direction.normalized() * distance * float(step + 1) / steps
		approach.tween_callback(_face_witness.bind(witness))
		approach.tween_property(lady, "position", at, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var pause: float = rng.randf_range(0.1, 0.45)
		approach.tween_interval(pause)
		time += 0.26 + pause
	approach.tween_callback(_face_witness.bind(witness))
	return time + 0.1


## The lunge: she springs up into the player's face and holds on.
func lunge(camera: Camera3D) -> void:
	crawling = false
	lady.reparent(camera, true)
	var start: Transform3D = lady.transform
	# In camera space: facing the lens, tipped up, her face a hand's width away.
	var basis_at := Basis(Vector3.RIGHT, -0.2)
	var head_offset: Vector3 = basis_at * lady_head.position
	var goal := Transform3D(basis_at, Vector3(0.02, -0.02, -0.5) - head_offset)
	var leap := create_tween()
	leap.tween_method(func(t: float) -> void:
		lady.transform = start.interpolate_with(goal, t)
	, 0.0, 1.0, 0.17).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	leap.parallel().tween_property(lady_mouth, "scale:y", 3.4, 0.14)
	leap.parallel().tween_property(face_light, "light_energy", 0.12, 0.17)
	for arm: Node3D in arms:
		leap.parallel().tween_property(arm, "rotation:x", -1.0, 0.17)
	leap.tween_property(lady_head, "rotation:z", 0.35, 0.08)


func _yaw_toward(from: Vector3, witness: Vector3) -> float:
	var flat: Vector3 = witness - from
	return atan2(flat.x, flat.z)


func _face_witness(witness: Vector3) -> void:
	lady.rotation.y = _yaw_toward(lady.global_position, witness)
	if lady_head != null:
		var delta: Vector3 = witness - lady_head.global_position
		lady_head.rotation.x = -atan2(delta.y, Vector2(delta.x, delta.z).length()) * 0.8


func _process(delta: float) -> void:
	if not crawling or lady == null:
		return
	crawl_clock += delta
	# Arms claw alternately; the head twitches on its neck.
	for index: int in range(arms.size()):
		arms[index].rotation.x = sin(crawl_clock * 7.0 + index * PI) * 0.45
	if lady_head != null:
		lady_head.rotation.z = sin(crawl_clock * 1.7) * 0.25 + (0.35 if fmod(crawl_clock, 1.9) < 0.08 else 0.0)


## The spans shiver as her song grows.
func tremble() -> void:
	for piece: Node3D in segments:
		var shake: Tween = piece.create_tween().set_loops(24)
		shake.tween_property(piece, "position:x", 0.05, 0.07)
		shake.tween_property(piece, "position:x", -0.05, 0.07)


## London Bridge is falling down: the spans crack and drop into the Thames one by one.
func collapse() -> void:
	for index: int in range(segments.size()):
		var piece: Node3D = segments[index]
		var tween: Tween = create_tween().set_parallel(true)
		var delay: float = 0.25 + absf(index - 1) * 0.35
		tween.tween_property(piece, "position:y", -22.0, 2.6).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(piece, "rotation", Vector3(0.35 * (1 - index % 2 * 2), 0.1 * index, 0.45 * (index % 2 * 2 - 1)), 2.6).set_delay(delay)
	var leaf: Tween = create_tween()
	leaf.tween_property(drawbridge, "rotation:x", -0.9, 1.6).set_delay(0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Snaps the lever down and back up when the date is wrong.
func rattle_lever() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(lever, "rotation:x", 0.7, 0.15)
	tween.tween_property(lever, "rotation:x", 0.0, 0.4).set_trans(Tween.TRANS_BOUNCE)


func _shiver_bricks(amount: float) -> void:
	for brick: MeshInstance3D in seal_bricks:
		if not brick.visible:
			continue
		var home: Vector3 = brick.get_meta("home")
		var shake := brick.create_tween()
		for beat: int in range(3):
			shake.tween_property(brick, "position", home + Vector3(amount, randf_range(-amount, amount) * 0.5, randf_range(-amount, amount)), 0.04)
			shake.tween_property(brick, "position", home, 0.05)


## Bricks burst out onto the deck: the listed ones, or all that remain.
func _burst_bricks(which: Array) -> void:
	for index: int in range(seal_bricks.size()):
		var brick: MeshInstance3D = seal_bricks[index]
		if brick.has_meta("burst") or (not which.is_empty() and index not in which):
			continue
		brick.set_meta("burst", true)
		var landing: Vector3 = brick.position + Vector3(randf_range(0.9, 2.4), 0, randf_range(-0.8, 0.8))
		landing.y = 0.1
		var fly := brick.create_tween().set_parallel(true)
		fly.tween_property(brick, "position:x", landing.x, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fly.tween_property(brick, "position:z", landing.z, 0.5)
		fly.tween_property(brick, "position:y", landing.y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		fly.tween_property(brick, "rotation", Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2)), 0.5)
	if which.is_empty() and seal_chain != null:
		var drop := seal_chain.create_tween().set_parallel(true)
		drop.tween_property(seal_chain, "position", seal_chain.position + Vector3(0.7, -1.0, 0), 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		drop.tween_property(seal_chain, "rotation:x", 1.2, 0.45)


## The alcove she was walled into: a bricked arch breaking the parapet, a hollow stone chamber
## built out over the river behind it, and the marks of those who sealed and mourned her.
func _sealed_alcove() -> void:
	var piece: Node3D = segments[1]
	# The hollow chamber behind the arch, dark inside.
	kit.box(piece, Vector3(0.2, 1.7, 1.9), Vector3(-5.9, 0.35, 0), "stone")
	kit.box(piece, Vector3(1.7, 0.25, 2.2), Vector3(-5.1, 1.3, 0), "stone")
	kit.box(piece, Vector3(1.7, 0.3, 2.2), Vector3(-5.1, -0.15, 0), "stone")
	for z: float in [-1.0, 1.0]:
		kit.box(piece, Vector3(1.7, 1.6, 0.2), Vector3(-5.1, 0.55, z), "stone")
	for inner: Array in [[Vector3(0.05, 1.3, 1.7), Vector3(-5.78, 0.6, 0)], [Vector3(1.4, 0.05, 1.7), Vector3(-5.05, 1.16, 0)], [Vector3(1.4, 0.05, 1.7), Vector3(-5.05, 0.01, 0)], [Vector3(1.4, 1.2, 0.05), Vector3(-5.05, 0.6, -0.88)], [Vector3(1.4, 1.2, 0.05), Vector3(-5.05, 0.6, 0.88)]]:
		kit.box(piece, inner[0], inner[1], "black")
	kit.box(piece, Vector3(2.0, 3.2, 2.4), Vector3(-5.1, -2.3, 0), "stone")
	# The arch in the parapet, taller than the wall, like a sealed doorway.
	for z: float in [-0.82, 0.82]:
		kit.box(piece, Vector3(0.42, 1.55, 0.3), Vector3(-4.15, 0.78, z), "stone", true)
	kit.box(piece, Vector3(0.46, 0.34, 1.95), Vector3(-4.15, 1.62, 0), "stone")
	kit.box(piece, Vector3(0.36, 0.18, 1.2), Vector3(-4.15, 1.87, 0), "stone")
	# Hurried brickwork, darker than the old stone, sealing the arch.
	for row: int in range(5):
		for column: int in range(4):
			var at := Vector3(-4.08, 0.14 + row * 0.27, -0.5 + column * 0.33 + (0.08 if row % 2 else 0.0))
			var brick: MeshInstance3D = kit.box(piece, Vector3(0.22, 0.24, 0.3), at, "brick")
			brick.set_meta("home", at)
			seal_bricks.append(brick)
	# Nobody could walk through it, before or after.
	var plug := kit.box(piece, Vector3(0.3, 1.3, 1.4), Vector3(-4.15, 0.65, 0), "black", true)
	plug.visible = false
	# An iron cross, a chain and padlock over the bricks, dead flowers and a small shoe.
	kit.box(piece, Vector3(0.04, 0.42, 0.06), Vector3(-3.9, 1.64, 0), "iron")
	kit.box(piece, Vector3(0.04, 0.06, 0.28), Vector3(-3.9, 1.72, 0), "iron")
	seal_chain = Node3D.new()
	seal_chain.position = Vector3(-3.93, 0.7, 0)
	piece.add_child(seal_chain)
	for side: float in [-1.0, 1.0]:
		for link: int in range(8):
			var t: float = (link + 0.5) / 8.0
			kit.box(seal_chain, Vector3(0.03, 0.03, 0.12), Vector3(0, side * (0.5 - t) * 0.9, (t - 0.5) * 1.5), "iron").rotation.x = side * 0.55
	kit.box(seal_chain, Vector3(0.06, 0.12, 0.1), Vector3(-0.02, -0.02, 0), "gold")
	for stem: int in range(5):
		kit.cylinder(piece, 0.008, 0.3, Vector3(-3.78, 0.08, 0.5 + stem * 0.03), "timber").rotation = Vector3(1.3, stem * 0.3, 0.2)
		kit.sphere(piece, 0.03, Vector3(-3.64, 0.06, 0.48 + stem * 0.035), "plaster_warm", 0.6)
	kit.box(piece, Vector3(0.14, 0.07, 0.07), Vector3(-3.78, 0.035, -0.55), "velvet").rotation.y = 0.4
	kit.box(piece, Vector3(0.05, 0.05, 0.06), Vector3(-3.74, 0.08, -0.53), "velvet")
	for scratch: int in range(4):
		kit.box(piece, Vector3(0.01, 0.35, 0.012), Vector3(-3.93, 0.45, 0.66 + scratch * 0.025), "black").rotation.x = 0.15


func _immured_lady() -> void:
	niche = Node3D.new()
	add_child(niche)
	_sealed_alcove()
	debris = Node3D.new()
	add_child(debris)
	lady = Node3D.new()
	add_child(lady)
	var dress := StandardMaterial3D.new()
	dress.albedo_color = Color("7f8784")
	dress.roughness = 0.35
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("c4c9c2")
	skin.roughness = 0.5
	skin.emission_enabled = true
	skin.emission = Color("6f8a96")
	skin.emission_energy_multiplier = 0.12
	var hair := StandardMaterial3D.new()
	hair.albedo_color = Color("0d0b0c")
	hair.roughness = 1.0
	hair.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var body := Node3D.new()
	lady.add_child(body)
	CelestialArt.line(kit, body, Vector3(0, 0.44, -0.36), Vector3(0, 0.56, 0.2), 0.14, dress)
	kit.sphere(body, 0.16, Vector3(0, 0.56, 0.18), dress, 0.8)
	var skirt: MeshInstance3D = kit.cylinder(body, 0.34, 0.9, Vector3(0, 0.26, -0.72), dress, 0.12)
	skirt.rotation.x = PI / 2.0 - 0.3
	for side: float in [-1.0, 1.0]:
		CelestialArt.line(kit, body, Vector3(side * 0.1, 0.3, -0.5), Vector3(side * 0.16, 0.06, -0.8), 0.045, skin)
		CelestialArt.line(kit, body, Vector3(side * 0.16, 0.06, -0.8), Vector3(side * 0.13, 0.05, -1.2), 0.035, skin)
		# Long, thin arms with the elbows splayed out like a spider's.
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.2, 0.5, 0.2)
		body.add_child(arm)
		arms.append(arm)
		var elbow := Vector3(side * 0.24, -0.12, 0.12)
		var hand := Vector3(side * 0.3, -0.5, 0.34)
		CelestialArt.line(kit, arm, Vector3.ZERO, elbow, 0.045, dress)
		CelestialArt.line(kit, arm, elbow, hand, 0.028, skin)
		kit.sphere(arm, 0.045, hand, skin, 0.5)
		for finger: int in range(4):
			CelestialArt.line(kit, arm, hand + Vector3(0, 0, 0.02), hand + Vector3(side * (finger - 1.5) * 0.035, -0.02, 0.16), 0.008, skin)
	lady_head = Node3D.new()
	lady_head.name = "Head"
	lady_head.position = Vector3(0, 0.6, 0.42)
	body.add_child(lady_head)
	kit.sphere(lady_head, 0.13, Vector3.ZERO, skin, 1.18)
	kit.sphere(lady_head, 0.145, Vector3(0, 0.05, -0.05), hair, 0.95)
	# Wet hair hangs to the stones on both sides and over one eye; a gap shows the other eye
	# and the mouth.
	for strand: int in range(22):
		var x: float = -0.13 + strand * 0.0124
		if x > -0.02 and x < 0.07:
			continue
		var front: float = 0.1 if absf(x) < 0.09 else 0.02
		CelestialArt.line(kit, lady_head, Vector3(x, 0.12, front), Vector3(x * 1.5, -0.68 - (strand % 4) * 0.05, front + 0.04), 0.009, hair)
	for side: float in [-1.0, 1.0]:
		kit.sphere(lady_head, 0.026, Vector3(side * 0.045, 0.02, 0.112), "black", 0.55)
		kit.sphere(lady_head, 0.006, Vector3(side * 0.045, 0.018, 0.134), kit.material(Color.WHITE, 0.0, Color("dff4ff"), 2.5))
	var void_black := StandardMaterial3D.new()
	void_black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	void_black.albedo_color = Color.BLACK
	lady_mouth = kit.box(lady_head, Vector3(0.036, 0.03, 0.02), Vector3(0.012, -0.075, 0.118), void_black)
	var bruise := StandardMaterial3D.new()
	bruise.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bruise.albedo_color = Color("2a2430")
	for side: float in [-1.0, 1.0]:
		kit.sphere(lady_head, 0.03, Vector3(side * 0.047, -0.012, 0.106), bruise, 0.45)
	# Hairline cracks in the pale skin, as if she were plaster.
	CelestialArt.line(kit, lady_head, Vector3(0.07, 0.07, 0.105), Vector3(0.03, -0.02, 0.124), 0.003, void_black)
	CelestialArt.line(kit, lady_head, Vector3(0.03, -0.02, 0.124), Vector3(0.055, -0.1, 0.108), 0.003, void_black)
	lady_light = kit.light(lady, Vector3(0, 1.2, 0.9), Color("bfe0ff"), 0, 4)
	face_light = kit.light(lady_head, Vector3(0, 0.1, 0.45), Color("d3e4ff"), 0.5, 1.4)
	for mesh: Node in lady.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lady.visible = false


func _river(scene: ActScene) -> void:
	# Water, banks, harbour, lock and river traffic all live in ThamesScenery.
	var scenery := ThamesScenery.new()
	scenery.name = "Thames"
	add_child(scenery)
	scenery.build(kit, scene)
	kit.box(self, Vector3(8.0, 0.4, 4.0), Vector3(0, -0.2, -82.0), "stone", true)
	# Invisible walls keep the player on the approach, the gatehouse, and the spans.
	for x: float in [-4.1, 4.1]:
		kit.box(self, Vector3(0.2, 4.0, 5.0), Vector3(x, 2.0, -82.4), "dark", true).visible = false
		kit.box(self, Vector3(0.2, 4.0, 42.0), Vector3(x * 0.97, 2.0, -111.0), "dark", true).visible = false
	kit.box(self, Vector3(8.0, 4.0, 0.2), Vector3(0, 2.0, -136.0), "dark", true).visible = false
	for x: float in [-6.45, 6.45]:
		kit.box(self, Vector3(5.1, 1.1, 0.25), Vector3(x, 0.55, -80.1), "iron", true)
	for index: int in range(12):
		var post_x: float = -8.5 + index * 1.55
		if absf(post_x) > 4.0:
			kit.box(self, Vector3(0.12, 1.1, 0.12), Vector3(post_x, 0.55, -80.1), "iron")


func _gatehouse() -> void:
	kit.box(self, Vector3(8.0, 0.4, 6.0), Vector3(0, -0.2, -87.0), "stone", true)
	for x: float in [-4.4, 4.4]:
		kit.box(self, Vector3(2.8, 13.0, 6.0), Vector3(x, 4.5, -87.0), "stone", true)
		kit.cylinder(self, 1.5, 3.0, Vector3(x, 12.5, -87.0), "roof", 0.0)
		for y: float in [3.0, 6.5]:
			kit.box(self, Vector3(0.6, 1.4, 0.05), Vector3(x, y, -83.97), "black")
	kit.box(self, Vector3(6.0, 5.0, 6.0), Vector3(0, 8.5, -87.0), "stone")
	for index: int in range(5):
		kit.box(self, Vector3(0.9, 0.8, 6.2), Vector3(-3.6 + index * 1.8, 11.4, -87.0), "stone")
	kit.box(self, Vector3(6.0, 0.4, 0.05), Vector3(0, 6.1, -83.97), "gold")
	for x: float in [-4.4, 4.4]:
		kit.cylinder(self, 0.05, 3.0, Vector3(x, 15.5, -87.0), "iron")
		kit.box(self, Vector3(0.04, 0.8, 1.3), Vector3(x, 16.5, -86.4), "flag_red")


## One span of the bridge: deck, stone pier and arch below, and houses on either side.
func _segment(z_start: float, index: int, rng: RandomNumberGenerator) -> Node3D:
	var piece := Node3D.new()
	piece.position = Vector3(0, 0, z_start - SEGMENT_LENGTH / 2.0)
	add_child(piece)
	kit.box(piece, Vector3(8.6, 0.6, SEGMENT_LENGTH), Vector3(0, -0.3, 0), "stone", true)
	kit.box(piece, Vector3(3.2, 3.6, 2.0), Vector3(0, -2.4, SEGMENT_LENGTH / 2.0 - 1.0), "stone")
	for side: float in [-1.0, 1.0]:
		kit.box(piece, Vector3(1.2, 3.4, SEGMENT_LENGTH - 2.0), Vector3(side * 3.7, -2.3, -1.0), "stone")
		if index == 1 and side < 0:
			# The parapet is broken by the sealed alcove where she was walled in.
			for end: float in [-1.0, 1.0]:
				kit.box(piece, Vector3(0.3, 1.0, SEGMENT_LENGTH / 2.0 - 0.8), Vector3(side * 4.15, 0.5, end * (SEGMENT_LENGTH / 4.0 + 0.4)), "stone", true)
		else:
			kit.box(piece, Vector3(0.3, 1.0, SEGMENT_LENGTH), Vector3(side * 4.15, 0.5, 0), "stone", true)
	var looks: Array[String] = ["plaster_cream", "plaster_sky", "plaster_rose", "plaster_mint"]
	for side: float in [-1.0, 1.0]:
		if (index + int(side > 0)) % 2 == 0 and not (index == 1 and side < 0):
			var height: float = rng.randf_range(4.5, 6.5)
			var look: String = looks[rng.randi() % looks.size()]
			kit.box(piece, Vector3(1.6, height, SEGMENT_LENGTH - 1.4), Vector3(side * 3.35, height / 2.0, 0), look, true)
			for beam_z: float in [-2.4, 0.0, 2.4]:
				kit.box(piece, Vector3(0.06, height, 0.14), Vector3(side * 2.53, height / 2.0, beam_z), "timber")
			for y: float in [1.2, 3.4]:
				kit.box(piece, Vector3(0.05, 0.9, 1.0), Vector3(side * 2.52, y + 0.4, -1.2), "window")
				kit.box(piece, Vector3(0.05, 0.9, 1.0), Vector3(side * 2.52, y + 0.4, 1.2), "black")
			var roof: MeshInstance3D = kit.box(piece, Vector3(2.4, 0.2, SEGMENT_LENGTH - 1.2), Vector3(side * 3.35, height + 0.55, 0), "roof")
			roof.rotation.z = -side * 0.5
	kit.cylinder(piece, 0.015, 5.2, Vector3(0, 4.6, 0), "linen").rotation.z = PI / 2
	for flag: int in range(8):
		kit.box(piece, Vector3(0.26, 0.26, 0.02), Vector3(-2.2 + flag * 0.62, 4.45, 0), ["flag_red", "flag_yellow", "flag_blue", "linen"][flag % 4]).rotation.z = PI / 4
	return piece


func _lamp(_scene: ActScene, spot: Vector3) -> void:
	kit.cylinder(self, 0.07, 3.6, spot + Vector3(0, 1.8, 0), "iron")
	kit.box(self, Vector3(0.36, 0.5, 0.36), spot + Vector3(0, 3.8, 0), "gas")
	kit.cylinder(self, 0.26, 0.2, spot + Vector3(0, 4.15, 0), "iron", 0.02)


func _engine(scene: ActScene) -> void:
	kit.box(self, Vector3(4.5, 4.2, 5.5), Vector3(7.25, 2.1, -73.0), "brick", true)
	kit.box(self, Vector3(5.0, 0.3, 6.0), Vector3(7.25, 4.35, -73.0), "roof")
	kit.box(self, Vector3(0.8, 3.0, 0.8), Vector3(8.2, 5.8, -74.5), "brick")
	var front := Node3D.new()
	front.position = Vector3(4.99, 0, -73.0)
	front.rotation.y = -PI / 2
	add_child(front)
	kit.box(front, Vector3(2.4, 1.7, 0.06), Vector3(0, 1.55, 0.03), "gold")
	for gear: Array in [[Vector3(-0.9, 2.2, 0.1), 0.3], [Vector3(0.95, 0.85, 0.1), 0.22], [Vector3(-0.2, 0.85, 0.1), 0.16]]:
		kit.cylinder(front, gear[1], 0.06, gear[0], "iron").rotation.x = PI / 2
	for index: int in range(2):
		var x: float = -0.5 if index == 0 else 0.35
		kit.cylinder(front, 0.24, 0.62 if index == 0 else 0.4, Vector3(x, 1.6, 0.25), "iron").rotation.z = PI / 2
		kit.box(front, Vector3(0.6 if index == 0 else 0.42, 0.26, 0.02), Vector3(x, 1.6, 0.49), "black")
		var label := Label3D.new()
		label.set_meta("diegetic", true)
		label.font_size = 64
		label.pixel_size = 0.0028
		label.modulate = Color("f2d9a0")
		label.outline_size = 0
		label.position = Vector3(x, 1.6, 0.51)
		front.add_child(label)
		if index == 0:
			month_label = label
		else:
			day_label = label
		kit.interactable(front, "calendar_wheel", "CALENDAR_MONTH" if index == 0 else "CALENDAR_DAY", "ENGINE_INSPECT", Vector3(x, 1.6, 0.42), Vector3(0.66 if index == 0 else 0.48, 0.52, 0.3), index)
	lever = Node3D.new()
	lever.position = Vector3(1.0, 1.15, 0.2)
	front.add_child(lever)
	kit.box(lever, Vector3(0.08, 0.7, 0.08), Vector3(0, 0.35, 0), "iron")
	kit.sphere(lever, 0.08, Vector3(0, 0.72, 0), "rose")
	kit.interactable(front, "bridge_lever", "BRIDGE_LEVER", "ENGINE_INSPECT", Vector3(1.0, 1.55, 0.3), Vector3(0.34, 0.9, 0.34))
	var note: StudyInteractable = kit.note(front, "tender_note", Vector3(-1.6, 1.7, 0.08), Vector2(0.4, 0.5))
	note.rotation.z = 0.05
	kit.note(front, "almanac", Vector3(1.65, 1.8, 0.08), Vector2(0.42, 0.56))
	scene.flicker(kit.light(front, Vector3(0, 3.0, 1.2), Color("ffd27a"), 2.0, 5.0))


func _caesar() -> void:
	var caesar: Node3D = ActorKit.make(kit, {"costume": "linen", "skirt": true, "cape": "curtain", "hat": "laurel", "right_arm": Vector3(0.5, 0, 0.15), "left_arm": Vector3(0.2, 0, 0.1), "nod": -0.15})
	var soothsayer: Node3D = ActorKit.make(kit, {"costume": "dark", "skirt": true, "hat": "hood", "lean": 0.25, "right_arm": Vector3(1.55, 0, 0.0), "left_arm": Vector3(0.6, 0, 0.1)})
	var brutus: Node3D = ActorKit.make(kit, {"costume": "velvet", "skirt": true, "cape": "black", "right_arm": Vector3(-0.35, 0, 0.1), "left_arm": Vector3(0.4, 0, 0.2)})
	for pair: Array in [[caesar, Vector3(-6.4, 0, -71.2)], [soothsayer, Vector3(-4.7, 0, -69.4)], [brutus, Vector3(-7.4, 0, -72.6)]]:
		add_child(pair[0])
		(pair[0] as Node3D).global_position = pair[1]
	caesar.rotation.y = atan2(1.7, 1.8)
	soothsayer.rotation.y = atan2(-1.7, -1.8)
	brutus.rotation.y = atan2(1.0, 1.4)
	kit.box(ActorKit.hand_of(brutus), Vector3(0.02, 0.3, 0.03), Vector3(0, -0.12, 0), "iron")
	kit.box(self, Vector3(0.5, 1.1, 0.4), Vector3(-3.9, 0.55, -70.6), "timber", true)
	var scroll: StudyInteractable = kit.note(self, "soothsayer", Vector3(-3.9, 1.14, -70.6), Vector2(0.36, 0.26), Vector3(-PI / 2 + 0.4, 0, 0))
	scroll.rotation.y = PI / 2
	for x: float in [-0.19, 0.19]:
		kit.cylinder(scroll, 0.025, 0.3, Vector3(x, 0, 0), "wood")
