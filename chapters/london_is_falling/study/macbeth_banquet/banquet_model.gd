class_name BanquetModel
extends Node3D
## Macbeth: a toy banquet on a sideboard against the wall. Four chairs carry one to four
## notches, counted left to right from the gold floor marker; three figures wait to be
## seated and one place must stay empty. Local +Z faces into the room; the wall is at Z = 0.

const SEAT_X: Array[float] = [-0.54, -0.18, 0.18, 0.54]
const SEAT_Y := 0.94
const SEAT_Z := 0.46

var figures: Array[Node3D] = []
var ghost: Node3D
var compartment: MeshInstance3D
var card: Node3D
var sun: StudyInteractable


func build(kit: PropKit) -> void:
	kit.box(self, Vector3(1.9, 0.88, 0.7), Vector3(0, 0.44, 0.35), "wood", true)
	kit.box(self, Vector3(2.0, 0.05, 0.76), Vector3(0, 0.895, 0.38), "trim")
	kit.box(self, Vector3(1.8, 0.03, 0.66), Vector3(0, 0.935, 0.36), "rug")
	kit.box(self, Vector3(1.8, 0.72, 0.04), Vector3(0, 1.3, 0.06), "curtain")
	kit.box(self, Vector3(1.9, 0.06, 0.08), Vector3(0, 1.68, 0.06), "gold")
	for x: float in [-0.93, 0.93]:
		kit.box(self, Vector3(0.05, 0.78, 0.05), Vector3(x, 1.3, 0.06), "gold")
	kit.note(self, "sheet", Vector3(0.62, 1.42, 0.1), Vector2(0.22, 0.28), Vector3(0, 0, -0.06))
	kit.box(self, Vector3(1.4, 0.03, 0.2), Vector3(0, 1.07, 0.26), "linen")
	for x: float in [-0.62, 0.62]:
		kit.box(self, Vector3(0.04, 0.12, 0.04), Vector3(x, 1.0, 0.26), "dark")
	for index: int in range(4):
		var x: float = SEAT_X[index]
		kit.cylinder(self, 0.022, 0.05, Vector3(x, 1.11, 0.24), "gold", 0.03)
		kit.box(self, Vector3(0.14, 0.08, 0.14), Vector3(x, 0.99, SEAT_Z + 0.03), "dark")
		kit.box(self, Vector3(0.14, 0.22, 0.025), Vector3(x, 1.1, SEAT_Z + 0.1), "dark")
		# Notches on the chair back: one to four.
		for notch: int in range(index + 1):
			kit.box(self, Vector3(0.016, 0.03, 0.008), Vector3(x + (notch - index / 2.0) * 0.028, 1.15, SEAT_Z + 0.117), "gold")
		kit.interactable(self, "banquet_seat", "BANQUET_SEAT", "MACBETH_INSPECT", Vector3(x, 1.06, SEAT_Z), Vector3(0.32, 0.34, 0.3), index)
	# An engraved arrow on the front edge points toward higher numbers.
	kit.box(self, Vector3(0.9, 0.02, 0.01), Vector3(-0.05, 0.8, 0.705), "gold")
	kit.cylinder(self, 0.03, 0.08, Vector3(0.44, 0.8, 0.705), "gold", 0.0).rotation.z = -PI / 2
	# The marked viewing position on the floor.
	kit.box(self, Vector3(0.7, 0.012, 0.07), Vector3(0, 0.02, 1.6), "gold")
	kit.box(self, Vector3(0.07, 0.012, 0.35), Vector3(0, 0.02, 1.75), "gold")
	for figure_id: int in range(1, 4):
		var figure: Node3D = make_figure(kit, figure_id)
		add_child(figure)
		figures.append(figure)
	ghost = Node3D.new()
	add_child(ghost)
	kit.cylinder(ghost, 0.06, 0.26, Vector3(0, 0.13, 0), "ghost", 0.035)
	kit.sphere(ghost, 0.05, Vector3(0, 0.31, 0), "ghost")
	kit.flare(ghost, Vector3(0, 0.22, 0.06), Color("9fd4ff"), 0.45)
	compartment = kit.box(self, Vector3(0.8, 0.18, 0.5), Vector3(0, 0.62, 0.45), "trim")
	kit.box(compartment, Vector3(0.14, 0.04, 0.04), Vector3(0, 0, 0.27), "gold")
	card = kit.letter_card(compartment, "L", 3, Vector3(-0.2, 0.14, 0.0), -0.35)
	sun = kit.interactable(compartment, "take", "ITEM_SUN_NAME", "TAKE_SUN_INSPECT", Vector3(0.2, 0.13, 0.0), Vector3(0.3, 0.2, 0.3), -1, "sun")
	kit.cylinder(sun, 0.07, 0.02, Vector3.ZERO, "lit").rotation.x = PI / 2
	kit.cylinder(sun, 0.075, 0.015, Vector3(0, 0, -0.012), "iron").rotation.x = PI / 2


func apply(state: StudyState, animate: bool) -> void:
	var tween: Tween = create_tween().set_parallel(true) if animate and is_inside_tree() else null
	for seat: int in range(4):
		var figure_id: int = state.banquet[seat]
		if figure_id == 0:
			continue
		var target := Vector3(SEAT_X[seat], SEAT_Y, SEAT_Z)
		if tween != null:
			tween.tween_property(figures[figure_id - 1], "position", target, 0.35).set_trans(Tween.TRANS_SINE)
		else:
			figures[figure_id - 1].position = target
	for figure_id: int in range(1, 4):
		figures[figure_id - 1].visible = not (state.held_station == "macbeth" and state.held_piece == figure_id)
	ghost.visible = state.macbeth_solved
	ghost.position = Vector3(SEAT_X[state.banquet.find(0)], SEAT_Y, SEAT_Z)
	var drawer_z: float = 0.98 if state.macbeth_solved else 0.45
	if tween != null:
		tween.tween_property(compartment, "position:z", drawer_z, 0.65)
	else:
		compartment.position.z = drawer_z
	card.visible = state.macbeth_solved
	sun.set_available(state.item_waiting("sun"))


## Figure 1 crowned host, 2 companion in a hat, 3 guest.
static func make_figure(kit: PropKit, figure_id: int) -> Node3D:
	var figure := Node3D.new()
	var body: String = ["rug", "blue", "linen"][figure_id - 1]
	kit.cylinder(figure, 0.06, 0.26, Vector3(0, 0.13, 0), body, 0.035)
	kit.sphere(figure, 0.05, Vector3(0, 0.31, 0), "bone")
	if figure_id == 1:
		kit.cylinder(figure, 0.045, 0.045, Vector3(0, 0.37, 0), "gold", 0.052)
		for index: int in range(5):
			var angle: float = index * TAU / 5
			kit.box(figure, Vector3(0.014, 0.04, 0.014), Vector3(cos(angle) * 0.045, 0.405, sin(angle) * 0.045), "gold")
	elif figure_id == 2:
		kit.cylinder(figure, 0.07, 0.012, Vector3(0, 0.355, 0), "dark")
		kit.cylinder(figure, 0.04, 0.08, Vector3(0, 0.4, 0), "dark", 0.035)
	else:
		kit.box(figure, Vector3(0.14, 0.03, 0.03), Vector3(0, 0.2, 0.04), "ivy")
	return figure
