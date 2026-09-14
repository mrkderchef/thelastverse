class_name AgesDialModel
extends Node3D
## As You Like It: a brass dial on the wall with seven sockets and seven carved tokens.
## A sideboard beneath holds the booklet and a drawer. Local +Z faces into the room;
## the wall is at local Z = 0. Sockets run clockwise from the top as seen by the player.

const RADIUS := 0.47
const CENTER := Vector3(0, 1.72, 0)

var tokens: Array[Node3D] = []
var drawer: MeshInstance3D
var card: Node3D
var handle: StudyInteractable
var inner: MeshInstance3D
var kit: PropKit


func build(prop_kit: PropKit) -> void:
	kit = prop_kit
	kit.box(self, Vector3(1.7, 0.85, 0.55), Vector3(0, 0.425, 0.28), "wood", true)
	kit.box(self, Vector3(1.8, 0.05, 0.6), Vector3(0, 0.875, 0.3), "trim")
	for x: float in [-0.6, 0.6]:
		kit.box(self, Vector3(0.36, 0.5, 0.02), Vector3(x, 0.35, 0.565), "trim")
	drawer = kit.box(self, Vector3(1.0, 0.18, 0.5), Vector3(0, 0.7, 0.29), "trim")
	kit.box(drawer, Vector3(0.14, 0.04, 0.04), Vector3(0, 0, 0.27), "gold")
	card = kit.letter_card(drawer, "H", 1, Vector3(-0.22, 0.14, 0.05), -0.35)
	handle = kit.interactable(drawer, "take", "ITEM_HANDLE_NAME", "TAKE_HANDLE_INSPECT", Vector3(0.22, 0.14, 0.05), Vector3(0.3, 0.2, 0.3), -1, "handle")
	kit.sphere(handle, 0.06, Vector3(0, 0.02, 0), "bone", 0.9)
	kit.box(handle, Vector3(0.16, 0.025, 0.025), Vector3(0, -0.02, 0.02), "iron")
	for eye: float in [-0.02, 0.02]:
		kit.box(handle, Vector3(0.018, 0.018, 0.01), Vector3(eye, 0.03, 0.055), "black")
	# The dial itself, mounted on the wall above.
	kit.cylinder(self, 0.64, 0.05, CENTER + Vector3(0, 0, 0.03), "gold").rotation.x = PI / 2
	inner = kit.cylinder(self, 0.36, 0.02, CENTER + Vector3(0, 0, 0.065), "dark")
	inner.rotation.x = PI / 2
	kit.cylinder(self, 0.05, 0.05, CENTER + Vector3(0, 0, 0.09), "gold").rotation.x = PI / 2
	# A gold arrow above the first socket points the way round.
	var arrow: MeshInstance3D = kit.cylinder(self, 0.035, 0.1, CENTER + Vector3(0.1, RADIUS + 0.14, 0.08), "gold", 0.0)
	arrow.rotation.z = -PI / 2
	kit.box(self, Vector3(0.1, 0.02, 0.02), CENTER + Vector3(0.0, RADIUS + 0.14, 0.08), "gold")
	for slot: int in range(7):
		var point: Vector3 = socket_point(slot)
		kit.cylinder(self, 0.085, 0.03, point + Vector3(0, 0, -0.01), "black").rotation.x = PI / 2
		kit.interactable(self, "ages_socket", "AGES_SOCKET", "AGES_INSPECT", point + Vector3(0, 0, 0.05), Vector3(0.2, 0.2, 0.12), slot)
	for piece: int in range(7):
		var token: Node3D = make_piece(kit, piece)
		add_child(token)
		tokens.append(token)
	kit.note(self, "booklet", Vector3(0.52, 0.91, 0.32), Vector2(0.24, 0.3), Vector3(-1.3, 0.3, 0))


func socket_point(slot: int) -> Vector3:
	var angle: float = slot * TAU / 7.0
	return CENTER + Vector3(sin(angle) * RADIUS, cos(angle) * RADIUS, 0.07)


func apply(state: StudyState, animate: bool) -> void:
	var tween: Tween = create_tween().set_parallel(true) if animate and is_inside_tree() else null
	for slot: int in range(7):
		var piece: int = state.ages[slot]
		if piece < 0:
			continue
		_move(tween, tokens[piece], "position", socket_point(slot) + Vector3(0, 0, 0.02))
	for piece: int in range(7):
		tokens[piece].visible = not (state.held_station == "ages" and state.held_piece == piece)
	_move(tween, drawer, "position:z", 0.72 if state.ages_solved else 0.29)
	card.visible = state.ages_solved
	handle.set_available(state.item_waiting("handle"))
	inner.material_override = kit.materials["ember" if state.ages_solved else "dark"]


func _move(tween: Tween, node: Node3D, property: String, value: Variant) -> void:
	if tween != null:
		tween.tween_property(node, property, value, 0.35).set_trans(Tween.TRANS_SINE)
	else:
		node.set_indexed(property, value)


## Carved token for a stage of life, facing +Z on a brass backing disc.
static func make_piece(kit: PropKit, piece: int) -> Node3D:
	var token := Node3D.new()
	kit.cylinder(token, 0.075, 0.02, Vector3(0, 0, -0.02), "gold").rotation.x = PI / 2
	match piece:
		0: # Infant: a cradle on rockers.
			kit.box(token, Vector3(0.13, 0.05, 0.05), Vector3(0, -0.005, 0.02), "wood")
			kit.box(token, Vector3(0.1, 0.02, 0.04), Vector3(0, 0.025, 0.02), "linen")
			kit.box(token, Vector3(0.16, 0.014, 0.02), Vector3(0, -0.04, 0.02), "trim")
		1: # Schoolchild: a satchel.
			kit.box(token, Vector3(0.1, 0.09, 0.035), Vector3(0, -0.01, 0.02), "blue")
			kit.box(token, Vector3(0.1, 0.03, 0.04), Vector3(0, 0.02, 0.025), "trim")
			kit.cylinder(token, 0.03, 0.012, Vector3(0, 0.05, 0.02), "trim", 0.03).rotation.z = PI / 2
		2: # Lover: a rose.
			kit.sphere(token, 0.038, Vector3(0, 0.025, 0.03), "rose")
			kit.cylinder(token, 0.007, 0.08, Vector3(0, -0.035, 0.02), "ivy")
			kit.box(token, Vector3(0.035, 0.012, 0.01), Vector3(0.02, -0.03, 0.02), "ivy").rotation.z = 0.5
		3: # Soldier: a sword.
			kit.box(token, Vector3(0.016, 0.13, 0.01), Vector3(0, 0.02, 0.02), "iron")
			kit.box(token, Vector3(0.07, 0.015, 0.018), Vector3(0, -0.045, 0.02), "gold")
			kit.sphere(token, 0.014, Vector3(0, -0.065, 0.02), "gold")
		4: # Judge: scales.
			kit.box(token, Vector3(0.012, 0.11, 0.012), Vector3(0, 0, 0.02), "gold")
			kit.box(token, Vector3(0.12, 0.01, 0.01), Vector3(0, 0.05, 0.02), "gold")
			for x: float in [-0.055, 0.055]:
				kit.cylinder(token, 0.025, 0.008, Vector3(x, 0.0, 0.03), "gold")
		5: # Elder: a walking cane.
			kit.cylinder(token, 0.01, 0.13, Vector3(0, -0.01, 0.02), "wood")
			kit.box(token, Vector3(0.05, 0.016, 0.016), Vector3(0.02, 0.055, 0.02), "wood")
		_: # Second Childhood: a snuffed candle.
			kit.cylinder(token, 0.022, 0.07, Vector3(0, -0.01, 0.025), "paper")
			kit.sphere(token, 0.01, Vector3(0, 0.03, 0.025), "black")
			kit.box(token, Vector3(0.06, 0.012, 0.03), Vector3(0, -0.05, 0.025), "gold")
	return token
