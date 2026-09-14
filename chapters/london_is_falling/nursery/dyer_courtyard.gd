class_name DyerCourtyard
extends ActScene
## A service court folds Whitechapel into a remembered Reading house.
signal bell_sounded(index: int)
var bookcase: Node3D
var passage_open: bool = false
var passage_tween: Tween
var replay_tween: Tween
var bells: Array[MeshInstance3D] = []
var hoops: Array[Node3D] = []
var dolls: Array[Node3D] = []
var rocker: Node3D
var cradle: Node3D
var flies: Array[Node3D] = []
var haunt_clock: float = 0.0
var candle_light: OmniLight3D
var bell_lights: Array[OmniLight3D] = []
var memory_lights: Array[MeshInstance3D] = []
const BELL_NAMES: Array[String] = ["LAMP", "MOON", "CRADLE", "DOOR"]

func _ready() -> void:
	CelestialArt.environment(self, 0.32)
	kit.box(self, Vector3(18, 0.25, 27), Vector3(0, -0.125, -10), "cobble", true)
	for side: float in [-1.0, 1.0]:
		kit.box(self, Vector3(0.5, 9, 27), Vector3(side * 9, 4.5, -10), "brick", true)
		for z: float in [-3.0, -9.0, -16.0]:
			kit.box(self, Vector3(0.05, 1.5, 1), Vector3(side * 8.72, 5.2, z), "black")
	kit.box(self, Vector3(18, 8, 0.4), Vector3(0, 4, 3.5), "brick", true)
	# Boarded back entrance; decorative risers sit over a smooth collision ramp.
	for index: int in range(12):
		kit.box(self, Vector3(3.2, (index + 1) * 0.2, 0.5), Vector3(0, (index + 1) * 0.1, -8.25 - index * 0.5), "stone")
	var ramp := kit.box(self, Vector3(3.2, 0.15, 6.65), Vector3(0, 1.2, -11), "stone", true)
	ramp.rotation.x = atan2(2.4, 6.0)
	ramp.visible = false
	for side: float in [-1.0, 1.0]:
		CelestialArt.line(kit, self, Vector3(side * 1.7, 0.9, -8), Vector3(side * 1.7, 3.3, -14), 0.055, "iron")
		kit.box(self, Vector3(0.18, 2.4, 6.3), Vector3(side * 1.8, 1.2, -11), "brick", true)
	kit.box(self, Vector3(12, 0.2, 10), Vector3(0, 2.3, -19), "wood", true)
	for side: float in [-1.0, 1.0]:
		kit.box(self, Vector3(4.4, 5.5, 0.4), Vector3(side * 3.8, 3.8, -14), "brick", true)
		kit.box(self, Vector3(0.35, 4, 10), Vector3(side * 6, 4.3, -19), "wall", true)
	for side: float in [-1.0, 1.0]:
		kit.box(self, Vector3(4.5, 4, 0.4), Vector3(side * 3.75, 4.3, -24), "wall", true)
		kit.box(self, Vector3(0.25, 3.7, 4.5), Vector3(side * 1.6, 4.2, -26), "brick", true)
	kit.box(self, Vector3(3.4, 0.2, 4.5), Vector3(0, 2.3, -26), "stone", true)
	kit.box(self, Vector3(3.4, 0.2, 4.5), Vector3(0, 6.2, -26), "stone")
	kit.box(self, Vector3(3.4, 4, 0.2), Vector3(0, 4.2, -28.3), "black", true)
	kit.light(self, Vector3(0, 4.8, -26), Color("94b5e8"), 2, 5)
	kit.box(self, Vector3(12, 0.2, 10), Vector3(0, 6.4, -19), "timber")
	kit.box(self, Vector3(3.2, 1.2, 0.4), Vector3(0, 6, -14), "brick")
	kit.box(self, Vector3(2.5, 0.85, 1.2), Vector3(-3.5, 2.825, -17.8), "wood", true)
	kit.note(self, "dyer_record", Vector3(-3.5, 3.3, -17.6), Vector2(0.65, 0.5), Vector3(-PI / 2 + 0.35, 0, 0))
	kit.note(self, "star_covenant", Vector3(3.5, 3.75, -23.75), Vector2(0.6, 0.7))
	_memory_room()
	_haunting()
	for spot: Vector3 in [Vector3(-3.1, 4.2, -17.8), Vector3(3, 4.8, -22), Vector3(0, 4, -12)]:
		kit.light(self, spot, Color("7f93b0"), 0.35, 6)
	for side: float in [-1.0, 1.0]:
		kit.cylinder(self, 0.4, 1.2, Vector3(side * 6, 0.6, -6), "timber", -1, true)
		kit.box(self, Vector3(1.2, 1.1, 1.2), Vector3(side * 5, 0.55, -4), "wood", true)
	_add_player(Vector3(5, 4, -1), Vector3(0, 3, -15))

func spawn_point() -> Array:
	return [Vector3(0, 0.08, 0), 0.0]

func _physics_process(_delta: float) -> void:
	if state == null or not player.enabled:
		return
	_report_threshold(state.celestial.house_solved and player.position.y > 2 and player.position.z < -26.5)


func _memory_room() -> void:
	bookcase = Node3D.new()
	add_child(bookcase)
	bookcase.position = Vector3(0, 2.4, -23.8)
	kit.box(bookcase, Vector3(3.0, 3.4, 0.4), Vector3(0, 1.7, 0), "wood", true)
	for y: float in [0.25, 1.0, 1.75, 2.5, 3.25]:
		kit.box(bookcase, Vector3(3.1, 0.12, 0.65), Vector3(0, y, 0.2), "timber")
		if y > 3:
			continue
		for i: int in range(10):
			kit.box(bookcase, Vector3(0.18, 0.5 + (i % 3) * 0.06, 0.3), Vector3(-1.25 + i * 0.27, y + 0.3, 0.3), ["velvet", "trim", "linen"][i % 3]).rotation.z = (i % 3 - 1) * 0.04
	kit.note(self, "house_song", Vector3(3.6, 3.45, -17.5), Vector2(0.6, 0.6), Vector3(-0.3, 0, 0))
	var board := Vector3(-2.2, 3.4, -20)
	for index: int in range(4):
		var bed := Vector3(-4.1 if index % 2 == 0 else 4.1, 2.4, -19.3 if index < 2 else -22.1)
		kit.box(self, Vector3(1.5, 0.18, 2), bed + Vector3(0, 0.55, 0), "wood", true)
		kit.box(self, Vector3(1.35, 0.12, 1.8), bed + Vector3(0, 0.7, 0), "linen")
		for side: float in [-0.7, 0.7]:
			kit.box(self, Vector3(0.06, 0.06, 2), bed + Vector3(side, 1.3, 0), "wood")
			for z: float in [-0.9, -0.45, 0, 0.45, 0.9]:
				kit.box(self, Vector3(0.04, 0.65, 0.04), bed + Vector3(side, 1, z), "wood")
		var spot: Vector3 = bed + Vector3(0, 2.3, 0)
		# Everything above the bed hangs from one cord and swings together: bell, then the
		# woven hoop, whose little charm tells whose bell it is.
		var hanger := Node3D.new()
		hanger.position = Vector3(spot.x, 6.3, spot.z)
		add_child(hanger)
		hoops.append(hanger)
		var local := Vector3(0, spot.y - 6.3, 0)
		CelestialArt.line(kit, hanger, Vector3.ZERO, local, 0.012, "iron")
		var bell := kit.interactable(hanger, "house_bell", "BELL_" + BELL_NAMES[index], "HOUSE_BELL_INSPECT", local, Vector3(0.6, 1.4, 0.6), index)
		bells.append(kit.cylinder(bell, 0.2, 0.26, Vector3.ZERO, "gold", 0.07))
		kit.sphere(bell, 0.05, Vector3(0, -0.16, 0), "iron")
		var hoop := local + Vector3(0, -0.6, 0)
		for part: int in range(24):
			var angle: float = TAU * part / 24
			var next_angle: float = TAU * (part + 1) / 24
			CelestialArt.line(kit, hanger, hoop + Vector3(cos(angle), sin(angle), 0) * 0.3, hoop + Vector3(cos(next_angle), sin(next_angle), 0) * 0.3, 0.015, "timber")
			if part % 3 == 0:
				CelestialArt.line(kit, hanger, hoop + Vector3(cos(angle), sin(angle), 0) * 0.29, hoop + Vector3(cos(angle + 2.4), sin(angle + 2.4), 0) * 0.29, 0.006, "linen")
		_charm(hanger, index, hoop)
		for x: float in [-0.18, 0, 0.18]:
			CelestialArt.line(kit, hanger, hoop + Vector3(x, -0.2, 0), hoop + Vector3(x, -0.7, 0), 0.009, "linen")
			kit.sphere(hanger, 0.035, hoop + Vector3(x, -0.65, 0), "linen", 3)
		bell_lights.append(kit.light(self, spot + Vector3(0, 0.35, 0.25), Color("ffdb94"), 0, 1.2))
	# A covered adult-sized mortuary form, still and deliberately indistinct.
	kit.box(self, Vector3(1, 0.7, 2.2), Vector3(-5.1, 2.75, -16.3), "wood", true)
	for part: Array in [[0.0, 0.30, 1.5], [-0.73, 0.2, 1.0], [0.65, 0.2, 1.8]]:
		var shroud := kit.sphere(self, part[1], Vector3(-5.1, 3.22, -16.3 + part[0]), "linen", part[2])
		shroud.scale.z = 1.5
	var memory := kit.interactable(self, "house_replay", "HOUSE_REPLAY", "HOUSE_REPLAY_INSPECT", Vector3(-2.2, 3.4, -20), Vector3(0.45, 0.65, 0.45))
	kit.box(memory, Vector3(0.35, 0.5, 0.25), Vector3.ZERO, "wood")
	kit.cylinder(memory, 0.12, 0.05, Vector3(0, 0, 0.15), "gold").rotation.x = PI / 2
	for index: int in range(5):
		memory_lights.append(kit.sphere(self, 0.04, board + Vector3(-0.6 + index * 0.3, 0.44, 0.2), "black"))


func play_bell(index: int) -> void:
	bell_sounded.emit(index)
	bell_lights[index].light_energy = 2.5
	var pulse := create_tween()
	pulse.tween_property(bell_lights[index], "light_energy", 0.0, 0.7)
	var swing := create_tween()
	swing.tween_property(hoops[index], "rotation:z", 0.18, 0.15)
	swing.tween_property(hoops[index], "rotation:z", -0.12, 0.3)
	swing.tween_property(hoops[index], "rotation:z", 0.06, 0.3)
	swing.tween_property(hoops[index], "rotation:z", 0.0, 0.3)


## The charm woven into a dreamcatcher: 0 lamp, 1 crescent moon, 2 cradle, 3 door.
func _charm(parent: Node3D, index: int, at: Vector3) -> void:
	var glow := "gas" if index == 0 else "bone"
	match index:
		0:
			kit.box(parent, Vector3(0.09, 0.12, 0.05), at, "iron")
			kit.box(parent, Vector3(0.06, 0.08, 0.055), at, glow)
			kit.cylinder(parent, 0.04, 0.03, at + Vector3(0, 0.08, 0), "iron", 0.01)
		1:
			var moon := kit.cylinder(parent, 0.11, 0.02, at, "bone")
			moon.rotation.x = PI / 2
			var bite := kit.cylinder(parent, 0.09, 0.025, at + Vector3(0.05, 0.03, 0.004), "black")
			bite.rotation.x = PI / 2
		2:
			kit.box(parent, Vector3(0.18, 0.07, 0.07), at + Vector3(0, -0.02, 0), "wood")
			for x: float in [-0.08, 0.08]:
				kit.box(parent, Vector3(0.02, 0.12, 0.07), at + Vector3(x, 0.02, 0), "wood")
			kit.box(parent, Vector3(0.22, 0.015, 0.05), at + Vector3(0, -0.07, 0), "timber").rotation.z = 0.0
		_:
			kit.box(parent, Vector3(0.1, 0.17, 0.02), at, "timber")
			kit.sphere(parent, 0.012, at + Vector3(0.03, 0, 0.015), "gold")


## The house's haunting: a veiled dead woman in a chair that rocks by itself, porcelain
## dolls that turn their heads while unwatched, a cot that rocks, flies, and stripped walls.
func _haunting() -> void:
	var floor_y: float = 2.4
	# The rocking chair by the covered window, and the woman who never rose from it.
	rocker = Node3D.new()
	rocker.position = Vector3(-2.35, floor_y, -22.9)
	rocker.rotation.y = 0.55
	add_child(rocker)
	for x: float in [-0.28, 0.28]:
		var runner := kit.box(rocker, Vector3(0.05, 0.05, 0.9), Vector3(x, 0.04, 0), "timber")
		runner.rotation.x = 0.0
		kit.box(rocker, Vector3(0.04, 0.45, 0.04), Vector3(x, 0.28, 0.25), "timber")
		kit.box(rocker, Vector3(0.04, 1.1, 0.04), Vector3(x, 0.6, -0.25), "timber")
	kit.box(rocker, Vector3(0.6, 0.06, 0.55), Vector3(0, 0.48, 0), "timber")
	kit.box(rocker, Vector3(0.6, 0.7, 0.05), Vector3(0, 0.9, -0.27), "timber")
	var dead := ActorKit.make(kit, {"costume": "black", "skirt": true, "sleeve": "black", "hat": "hood", "skin": "plaster_cool", "glove": "plaster_cool", "mask": "plain", "nod": 0.75, "lean": -0.35, "left_arm": Vector3(0.05, 0, 0.35), "right_arm": Vector3(0.1, 0, 0.45)})
	dead.position = Vector3(0, -0.02, 0.05)
	dead.scale = Vector3(0.95, 0.72, 0.95)
	for body: Node in dead.find_children("*", "StaticBody3D", true, false):
		(body as StaticBody3D).collision_layer = 0
	rocker.add_child(dead)
	kit.box(rocker, Vector3(0.36, 0.5, 0.02), Vector3(0, 1.35, 0.14), kit.glow(Color(0.02, 0.02, 0.03), 0.8))
	var chair_body := kit.box(self, Vector3(0.9, 1.4, 0.9), rocker.position + Vector3(0, 0.7, 0), "black", true)
	chair_body.visible = false
	for index: int in range(9):
		var fly := Node3D.new()
		fly.position = rocker.position + Vector3(0, 1.4, 0)
		add_child(fly)
		kit.sphere(fly, 0.012, Vector3(0.25 + index * 0.03, 0, 0), "black")
		flies.append(fly)
	# Porcelain dolls sitting on the beds, faces cracked.
	for spot: Array in [[Vector3(-3.6, floor_y + 0.78, -19.8), 0.5], [Vector3(4.5, floor_y + 0.78, -22.6), -2.2], [Vector3(3.7, floor_y + 0.78, -18.9), -1.0]]:
		var doll := Node3D.new()
		doll.position = spot[0]
		doll.rotation.y = spot[1]
		add_child(doll)
		kit.cylinder(doll, 0.1, 0.24, Vector3(0, 0.12, 0), ["velvet", "linen", "rose"][dolls.size()], 0.06)
		var head := Node3D.new()
		head.name = "Head"
		head.position = Vector3(0, 0.3, 0)
		doll.add_child(head)
		kit.sphere(head, 0.075, Vector3.ZERO, "bone")
		for x: float in [-0.025, 0.025]:
			kit.sphere(head, 0.014, Vector3(x, 0.01, 0.065), "black")
		kit.box(head, Vector3(0.006, 0.07, 0.004), Vector3(0.02, 0.02, 0.074), "black").rotation.z = 0.5
		kit.box(head, Vector3(0.12, 0.02, 0.1), Vector3(0, 0.07, -0.01), "trim")
		dolls.append(doll)
	# An empty cot that rocks with no hand on it.
	cradle = Node3D.new()
	cradle.position = Vector3(0, floor_y, -16.2)
	add_child(cradle)
	kit.box(cradle, Vector3(1.0, 0.5, 0.6), Vector3(0, 0.45, 0), "wood")
	kit.box(cradle, Vector3(0.9, 0.08, 0.5), Vector3(0, 0.66, 0), "linen")
	for x: float in [-0.45, 0.45]:
		kit.cylinder(cradle, 0.35, 0.05, Vector3(x, 0.25, 0), "timber").rotation.z = PI / 2
	var cot_body := kit.box(self, Vector3(1.0, 0.8, 0.6), cradle.position + Vector3(0, 0.4, 0), "black", true)
	cot_body.visible = false
	# Stripped wallpaper and scratch marks at child height.
	for spot: Vector3 in [Vector3(-5.8, floor_y + 1.6, -17.0), Vector3(5.8, floor_y + 1.2, -20.5), Vector3(-5.8, floor_y + 2.4, -21.5)]:
		var strip := kit.box(self, Vector3(0.02, 0.9, 0.35), spot, "plaster_warm")
		strip.rotation.x = 0.35
	for index: int in range(5):
		kit.box(self, Vector3(0.015, 0.4, 0.015), Vector3(5.82, floor_y + 0.5, -17.6 + index * 0.07), "black").rotation.x = 0.1
	# A thin grey light from the boarded window falls only on her.
	kit.light(self, rocker.position + Vector3(0.6, 2.2, 0.9), Color("9fb0c8"), 0.55, 2.6)
	candle_light = kit.light(self, Vector3(-2.2, floor_y + 1.4, -20.0), Color("ffb070"), 0.8, 5.0, true)
	flicker(candle_light)
	candle(Vector3(-2.5, floor_y + 0.96, -20.0), false)


func _process(delta: float) -> void:
	super._process(delta)
	haunt_clock += delta
	if rocker != null:
		rocker.rotation.x = sin(haunt_clock * 1.3) * 0.09
	if cradle != null:
		cradle.rotation.z = sin(haunt_clock * 1.7 + 1.0) * 0.12
	for index: int in range(flies.size()):
		var angle: float = haunt_clock * (3.0 + index * 0.4) + index
		flies[index].position = rocker.position + Vector3(cos(angle) * 0.3, 1.35 + sin(angle * 1.7) * 0.12, sin(angle) * 0.3)
	if player == null:
		return
	# The dolls only move while nobody looks at them.
	for doll: Node3D in dolls:
		var head := doll.get_node("Head") as Node3D
		var eye: Vector3 = head.global_position
		var watched: bool = not player.camera.is_position_behind(eye) and (-player.camera.global_basis.z).dot((eye - player.camera.global_position).normalized()) > 0.6
		if watched:
			continue
		var target: Vector3 = player.camera.global_position
		var local: Vector3 = doll.to_local(target)
		var yaw: float = atan2(local.x, local.z)
		head.rotation.y = lerp_angle(head.rotation.y, yaw, minf(delta * 2.0, 1.0))


func replay_memory() -> void:
	if replay_tween != null:
		replay_tween.kill()
	for light: OmniLight3D in bell_lights:
		light.light_energy = 0
	replay_tween = create_tween()
	for index: int in CelestialState.HOUSE_SONG:
		replay_tween.tween_callback(play_bell.bind(index))
		replay_tween.tween_callback(narrate.emit.bind("ECHO_" + BELL_NAMES[index]))
		replay_tween.tween_interval(1.1)


func apply_state(animate: bool = true) -> void:
	super.apply_state(animate)
	if state == null:
		return
	for index: int in range(5):
		memory_lights[index].material_override = kit.materials["gas" if state.celestial.house_steps.size() > index else "black"]
	if passage_open == state.celestial.house_solved and animate:
		return
	passage_open = state.celestial.house_solved
	if passage_tween != null:
		passage_tween.kill()
	if animate:
		passage_tween = create_tween()
		passage_tween.tween_property(bookcase, "position:x", 3.2 if passage_open else 0.0, 2.0).set_trans(Tween.TRANS_SINE)
	else:
		bookcase.position.x = 3.2 if passage_open else 0.0
