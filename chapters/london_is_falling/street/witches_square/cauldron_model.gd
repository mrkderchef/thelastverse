class_name CauldronModel
extends Node3D
## Macbeth in the Witches' Square: three witches bend over a cauldron. Ingredients sit in
## jars on an apothecary stall; the incantation nailed to it names four of them in order.
## Built in street coordinates.

const CENTER := Vector3(0, 0, -46)
const SHELF_X := -8.35
const SHELF_Y := 1.25

var jars: Array[Node3D] = []
var slot_points: Array[Vector3] = []
var surface: MeshInstance3D
var smoke: MeshInstance3D
var fire_light: OmniLight3D
var flames: Array[MeshInstance3D] = []
var hearth_light: OmniLight3D
var bellows: Node3D
var kit: PropKit


func build(prop_kit: PropKit, scene: ActScene) -> void:
	kit = prop_kit
	kit.cylinder(self, 0.72, 0.9, CENTER + Vector3(0, 0.65, 0), "iron", 0.84, true)
	kit.cylinder(self, 0.88, 0.1, CENTER + Vector3(0, 1.12, 0), "iron")
	surface = kit.cylinder(self, 0.8, 0.03, CENTER + Vector3(0, 1.08, 0), "brew")
	for index: int in range(3):
		var angle: float = index * TAU / 3
		kit.box(self, Vector3(0.12, 0.35, 0.12), CENTER + Vector3(cos(angle) * 0.6, 0.17, sin(angle) * 0.6), "iron")
	for index: int in range(6):
		var angle: float = index * TAU / 6
		kit.cylinder(self, 0.05, 0.7, CENTER + Vector3(cos(angle) * 0.35, 0.08, sin(angle) * 0.35), "timber").rotation = Vector3(PI / 2, angle, 0)
	for index: int in range(4):
		flames.append(kit.sphere(self, 0.12, CENTER + Vector3(sin(index * 1.7) * 0.25, 0.22, cos(index * 1.7) * 0.25), "flame", 1.8))
	kit.flare(self, CENTER + Vector3(0, 0.3, 0), Color("9aff5a"), 1.5)
	fire_light = kit.light(self, CENTER + Vector3(0, 1.5, 0), Color("8aff5a"), 2.4, 7.0, true)
	hearth_light = kit.light(self, CENTER + Vector3(0, 0.4, 0), Color("ffb060"), 1.2, 4.0)
	# The bellows at the front of the hearth: two paddles and a leather belly.
	bellows = Node3D.new()
	bellows.position = CENTER + Vector3(0.15, 0.28, 1.2)
	bellows.rotation.y = 0.3
	add_child(bellows)
	for y: float in [-0.08, 0.08]:
		kit.box(bellows, Vector3(0.4, 0.04, 0.6), Vector3(0, y, 0), "wood")
	kit.box(bellows, Vector3(0.34, 0.12, 0.5), Vector3.ZERO, "velvet")
	kit.cylinder(bellows, 0.03, 0.4, Vector3(0, 0, -0.45), "iron", 0.015).rotation.x = PI / 2
	for x: float in [-0.08, 0.08]:
		kit.cylinder(bellows, 0.02, 0.3, Vector3(x, 0.1, 0.42), "timber").rotation.x = PI / 2 - 0.3
	kit.interactable(self, "bellows", "BELLOWS", "BELLOWS_INSPECT", bellows.position + Vector3(0, 0.05, 0), Vector3(0.6, 0.4, 0.8))
	smoke = kit.cylinder(self, 0.5, 6.0, CENTER + Vector3(0, 4.2, 0), kit.glow(Color("8aff6a"), 0.18), 1.4)
	kit.interactable(self, "cauldron", "CAULDRON", "BREW_INSPECT", CENTER + Vector3(0, 1.0, 0), Vector3(1.9, 0.8, 1.9))
	var spots: Array = [[Vector3(-1.35, 0, -46.5), 0.9], [Vector3(1.35, 0, -46.5), -0.9], [Vector3(0, 0, -47.5), PI]]
	for witch_index: int in range(spots.size()):
		var spot: Array = spots[witch_index]
		var witch: Node3D = ActorKit.make(kit, {"costume": "black", "skirt": true, "hat": "pointed", "lean": 0.35, "skin": "plaster_cool", "right_arm": Vector3(1.3, 0, 0.3), "left_arm": Vector3(1.1, 0, 0.5), "nod": 0.4})
		add_child(witch)
		witch.global_position = spot[0]
		witch.look_at(Vector3(CENTER.x, witch.global_position.y, CENTER.z), Vector3.UP, true)
		# Each witch holds a torn scrap of the recipe out toward the fire.
		var scrap: StudyInteractable = kit.note(ActorKit.hand_of(witch), "witch_scrap_%d" % witch_index, Vector3(0, -0.14, 0.06), Vector2(0.24, 0.18), Vector3(-0.6, 0, 0))
		scrap.set_meta("witch", true)
	# The apothecary stall against the left facade.
	kit.box(self, Vector3(0.5, 2.1, 2.9), Vector3(-8.75, 1.05, -44.0), "timber", true)
	for y: float in [0.55, 1.12, 1.75]:
		kit.box(self, Vector3(0.6, 0.05, 2.9), Vector3(-8.5, y, -44.0), "wood")
	for z: float in [-45.45, -42.55]:
		kit.box(self, Vector3(0.6, 2.5, 0.08), Vector3(-8.5, 1.25, z), "wood")
	for index: int in range(6):
		kit.box(self, Vector3(1.4, 0.04, 0.5), Vector3(-8.0, 2.55, -45.25 + index * 0.5), "curtain" if index % 2 == 0 else "linen").rotation.z = -0.25
	for index: int in range(6):
		var point := Vector3(SHELF_X, SHELF_Y, -45.1 + index * 0.44)
		slot_points.append(point)
		kit.interactable(self, "shelf_jar", "SHELF_SLOT", "SHELF_INSPECT", point + Vector3(0, 0.08, 0), Vector3(0.36, 0.4, 0.4), index)
	for index: int in range(5):
		kit.sphere(self, 0.08, Vector3(-8.45, 1.85, -45.0 + index * 0.5), "bone", 0.9)
	var page: StudyInteractable = kit.note(self, "incantation", Vector3(-8.45, 0.85, -44.0), Vector2(0.5, 0.32))
	page.rotation.y = PI / 2
	for piece: int in range(6):
		var jar: Node3D = make_ingredient(kit, piece)
		add_child(jar)
		jars.append(jar)


func apply(state: StudyState, animate: bool) -> void:
	var tween: Tween = create_tween().set_parallel(true) if animate and is_inside_tree() else null
	for slot: int in range(6):
		var piece: int = state.shelf[slot]
		if piece < 0:
			continue
		jars[piece].visible = true
		if tween != null:
			tween.tween_property(jars[piece], "position", slot_points[slot], 0.3)
		else:
			jars[piece].position = slot_points[slot]
	for piece: int in state.brew:
		jars[piece].visible = false
	if state.held_station == "shelf":
		jars[state.held_piece].visible = false
	smoke.visible = state.brew_solved
	var fire: float = [0.45, 1.0, 1.9][state.heat]
	for flame: MeshInstance3D in flames:
		if tween != null:
			tween.tween_property(flame, "scale", Vector3(fire, fire * (1.3 if state.heat == 2 else 1.0), fire), 0.4)
		else:
			flame.scale = Vector3.ONE * fire
	hearth_light.light_energy = [0.35, 1.2, 3.0][state.heat]
	hearth_light.light_color = [Color("b0401a"), Color("ffb060"), Color("fff0a0")][state.heat]
	surface.scale = Vector3.ONE * (1.0 + 0.08 * state.brew.size())
	fire_light.light_energy = 2.4 + state.brew.size() * 0.9


## Jars: 0 eye of newt, 1 toe of frog, 2 wool of bat, 3 tongue of dog, 4 raven feather,
## 5 mandrake root. Each shows its contents on top of the cork.
static func make_ingredient(kit: PropKit, piece: int) -> Node3D:
	var jar := Node3D.new()
	kit.cylinder(jar, 0.07, 0.16, Vector3(0, 0.08, 0), "glass", 0.06)
	kit.cylinder(jar, 0.045, 0.03, Vector3(0, 0.175, 0), "trim")
	var top := Vector3(0, 0.22, 0)
	match piece:
		0:
			kit.sphere(jar, 0.045, top, "bone")
			kit.sphere(jar, 0.02, top + Vector3(0, 0.0, 0.035), "black")
		1:
			kit.sphere(jar, 0.035, top, "ivy", 0.7)
			for index: int in range(3):
				kit.box(jar, Vector3(0.012, 0.012, 0.06), top + Vector3(-0.02 + index * 0.02, -0.01, 0.045), "ivy")
		2:
			for index: int in range(4):
				kit.sphere(jar, 0.03, top + Vector3(sin(index * 1.6) * 0.03, index * 0.012, cos(index * 1.6) * 0.03), "black")
			kit.box(jar, Vector3(0.12, 0.01, 0.04), top + Vector3(0, 0.04, 0), "dark").rotation.z = 0.2
		3:
			kit.box(jar, Vector3(0.05, 0.016, 0.11), top + Vector3(0, -0.01, 0.02), "flesh").rotation.x = -0.3
		4:
			kit.box(jar, Vector3(0.015, 0.2, 0.045), top + Vector3(0, 0.07, 0), "black").rotation.z = 0.3
		_:
			kit.cylinder(jar, 0.012, 0.14, top + Vector3(0, 0.02, 0), "wood").rotation.z = 0.6
			kit.cylinder(jar, 0.012, 0.12, top + Vector3(0, 0.02, 0), "wood").rotation.z = -0.5
			kit.box(jar, Vector3(0.05, 0.01, 0.03), top + Vector3(0, 0.08, 0), "ivy")
	return jar
