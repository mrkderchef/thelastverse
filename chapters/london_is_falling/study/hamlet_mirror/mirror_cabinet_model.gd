class_name MirrorCabinetModel
extends Node3D
## Hamlet: a tall mirror cabinet against the wall. The Skull Handle uncovers the mirror,
## which shows the witness's props reflected; three symbol dials must match the reflection.
## Local +Z faces into the room; the wall is at local Z = 0.

const DIAL_X: Array[float] = [-0.36, -0.1, 0.16]
const DIAL_Y := 1.02

var cloth: MeshInstance3D
var reflection: Node3D
var socket_handle: Node3D
var dial_symbols: Array[Array] = []
var door_pivot: Node3D
var card: Node3D
var moon: StudyInteractable
var kit: PropKit


func build(prop_kit: PropKit) -> void:
	kit = prop_kit
	kit.box(self, Vector3(1.5, 1.5, 0.55), Vector3(0, 1.55, 0.275), "wood", true)
	kit.box(self, Vector3(1.62, 0.1, 0.62), Vector3(0, 2.34, 0.3), "trim")
	kit.box(self, Vector3(1.5, 0.8, 0.22), Vector3(0, 0.4, 0.11), "dark", true)
	for x: float in [-0.725, 0.725]:
		kit.box(self, Vector3(0.05, 0.8, 0.55), Vector3(x, 0.4, 0.275), "wood")
	kit.box(self, Vector3(1.5, 0.05, 0.55), Vector3(0, 0.025, 0.275), "wood")
	kit.box(self, Vector3(1.4, 0.03, 0.5), Vector3(0, 0.36, 0.28), "trim")
	# The mirror, covered by a cloth until the handle is fitted.
	kit.box(self, Vector3(1.1, 0.95, 0.04), Vector3(0, 1.72, 0.56), "gold")
	kit.box(self, Vector3(0.96, 0.8, 0.02), Vector3(0, 1.72, 0.585), "glass")
	cloth = kit.box(self, Vector3(1.04, 0.9, 0.03), Vector3(0, 1.72, 0.61), "curtain")
	reflection = Node3D.new()
	add_child(reflection)
	for index: int in range(3):
		var symbol: Node3D = make_symbol(kit, index, kit.materials["ghost"])
		symbol.position = Vector3(-0.28 + index * 0.28, 1.78, 0.6)
		symbol.scale = Vector3.ONE * 1.8
		reflection.add_child(symbol)
	# The reading arrow engraved along the bottom of the glass.
	kit.box(reflection, Vector3(0.5, 0.012, 0.01), Vector3(-0.02, 1.4, 0.6), "gold")
	kit.cylinder(reflection, 0.025, 0.06, Vector3(0.25, 1.4, 0.6), "gold", 0.0).rotation.z = -PI / 2
	# The physical props on top stand in the opposite order: a decoy.
	for index: int in range(3):
		var prop: Node3D = make_symbol(kit, 2 - index, null)
		prop.position = Vector3(-0.45 + index * 0.45, 2.45, 0.3)
		prop.scale = Vector3.ONE * 1.6
		add_child(prop)
	for index: int in range(3):
		kit.cylinder(self, 0.09, 0.04, Vector3(DIAL_X[index], DIAL_Y, 0.565), "gold").rotation.x = PI / 2
		kit.box(self, Vector3(0.14, 0.14, 0.01), Vector3(DIAL_X[index], DIAL_Y, 0.59), "black")
		var symbols: Array[Node3D] = []
		for symbol_index: int in range(StudyState.SYMBOL_COUNT):
			var symbol: Node3D = make_symbol(kit, symbol_index, null)
			symbol.position = Vector3(DIAL_X[index], DIAL_Y, 0.62)
			add_child(symbol)
			symbols.append(symbol)
		dial_symbols.append(symbols)
		kit.interactable(self, "mirror_dial", "MIRROR_DIAL", "MIRROR_DIAL_INSPECT", Vector3(DIAL_X[index], DIAL_Y, 0.63), Vector3(0.22, 0.22, 0.12), index)
	kit.box(self, Vector3(0.16, 0.16, 0.03), Vector3(0.48, DIAL_Y, 0.56), "black")
	socket_handle = Node3D.new()
	socket_handle.position = Vector3(0.48, DIAL_Y, 0.6)
	add_child(socket_handle)
	kit.sphere(socket_handle, 0.06, Vector3.ZERO, "bone", 0.9)
	kit.box(socket_handle, Vector3(0.16, 0.025, 0.025), Vector3(0, -0.04, 0.02), "iron")
	kit.interactable(self, "handle_socket", "HANDLE_SOCKET_NAME", "MIRROR_INSPECT", Vector3(0.48, DIAL_Y, 0.63), Vector3(0.22, 0.22, 0.12))
	kit.note(self, "card", Vector3(-0.66, 2.02, 0.6), Vector2(0.14, 0.2), Vector3(0, 0, 0.12))
	# Lower compartment door, hinged on the left.
	door_pivot = Node3D.new()
	door_pivot.position = Vector3(-0.7, 0, 0.56)
	add_child(door_pivot)
	kit.box(door_pivot, Vector3(1.4, 0.72, 0.04), Vector3(0.7, 0.42, 0), "trim")
	kit.box(door_pivot, Vector3(0.04, 0.12, 0.04), Vector3(1.28, 0.42, 0.04), "gold")
	card = kit.letter_card(self, "E", 2, Vector3(-0.25, 0.5, 0.35), -0.2)
	moon = kit.interactable(self, "take", "ITEM_MOON_NAME", "TAKE_MOON_INSPECT", Vector3(0.25, 0.45, 0.35), Vector3(0.3, 0.2, 0.3), -1, "moon")
	kit.cylinder(moon, 0.07, 0.02, Vector3.ZERO, "glass").rotation.x = PI / 2
	kit.cylinder(moon, 0.075, 0.015, Vector3(0, 0, -0.012), "iron").rotation.x = PI / 2


func apply(state: StudyState, animate: bool) -> void:
	cloth.visible = not state.handle_inserted
	reflection.visible = state.handle_inserted
	socket_handle.visible = state.handle_inserted
	for index: int in range(3):
		for symbol_index: int in range(StudyState.SYMBOL_COUNT):
			(dial_symbols[index][symbol_index] as Node3D).visible = state.mirror[index] == symbol_index
	var angle: float = -1.9 if state.mirror_solved else 0.0
	if animate and is_inside_tree():
		create_tween().tween_property(door_pivot, "rotation:y", angle, 0.9).set_trans(Tween.TRANS_SINE)
	else:
		door_pivot.rotation.y = angle
	card.visible = state.mirror_solved
	moon.set_available(state.item_waiting("moon"))


## Symbols 0 ear, 1 crown, 2 cup, 3 rose, 4 bell; `look` overrides every material.
static func make_symbol(kit: PropKit, symbol: int, look: Variant) -> Node3D:
	var node := Node3D.new()
	var paint := func(name: String) -> Variant: return name if look == null else look
	match symbol:
		0:
			kit.sphere(node, 0.05, Vector3.ZERO, paint.call("bone")).scale = Vector3(0.6, 1.0, 0.35)
			kit.sphere(node, 0.022, Vector3(0.006, 0.005, 0.014), paint.call("dark")).scale = Vector3(0.6, 1.2, 0.4)
		1:
			kit.cylinder(node, 0.045, 0.035, Vector3(0, -0.01, 0), paint.call("gold"), 0.05)
			for index: int in range(5):
				kit.box(node, Vector3(0.012, 0.035, 0.012), Vector3(-0.04 + index * 0.02, 0.022, 0.03), paint.call("gold"))
		2:
			kit.cylinder(node, 0.02, 0.045, Vector3(0, 0.025, 0), paint.call("gold"), 0.042)
			kit.cylinder(node, 0.008, 0.035, Vector3(0, -0.015, 0), paint.call("gold"))
			kit.cylinder(node, 0.03, 0.008, Vector3(0, -0.035, 0), paint.call("gold"))
		3:
			kit.sphere(node, 0.035, Vector3(0, 0.02, 0), paint.call("rose"))
			kit.cylinder(node, 0.007, 0.06, Vector3(0, -0.03, 0), paint.call("ivy"))
		_:
			kit.cylinder(node, 0.05, 0.065, Vector3(0, -0.005, 0), paint.call("gold"), 0.018)
			kit.sphere(node, 0.012, Vector3(0, -0.045, 0), paint.call("iron"))
	return node
