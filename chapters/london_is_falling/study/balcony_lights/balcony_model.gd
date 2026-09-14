class_name BalconyModel
extends Node3D
## Romeo & Juliet: a model theatre on a table against the wall. Rose and ivy balconies are
## parted by a black curtain; two crossed lanterns take the lenses and turn between four
## snapped targets. Local +Z faces into the room; the wall is at Z = 0.
## Lantern 0 is the sun lantern (player's right), lantern 1 the moon lantern.

const LANTERN_X: Array[float] = [0.45, -0.45]
const LANTERN_Y := 1.12
const LANTERN_Z := 0.87
## Local aim points for targets 0 rose receiver, 1 curtain, 2 ivy receiver, 3 empty stalls.
const TARGETS: Array[Vector3] = [Vector3(-0.6, 1.68, 0.3), Vector3(0, 1.38, 0.38), Vector3(0.6, 1.68, 0.3), Vector3(0, 0.6, 1.9)]

var pivots: Array[Node3D] = []
var beams: Array[MeshInstance3D] = []
var lenses: Array[MeshInstance3D] = []
var receivers: Array[MeshInstance3D] = []
var receiver_flares: Array[MeshInstance3D] = []
var curtain: MeshInstance3D
var joined: MeshInstance3D
var card: Node3D
var kit: PropKit


func build(prop_kit: PropKit) -> void:
	kit = prop_kit
	kit.box(self, Vector3(2.0, 0.9, 1.1), Vector3(0, 0.45, 0.55), "wood", true)
	kit.box(self, Vector3(2.1, 0.06, 1.16), Vector3(0, 0.93, 0.58), "trim")
	kit.box(self, Vector3(1.9, 0.05, 0.95), Vector3(0, 0.985, 0.55), "dark")
	for x: float in [-0.95, 0.95]:
		kit.box(self, Vector3(0.08, 1.05, 0.08), Vector3(x, 1.5, 0.95), "gold")
	kit.box(self, Vector3(1.98, 0.12, 0.08), Vector3(0, 2.05, 0.95), "curtain")
	kit.box(self, Vector3(1.9, 1.1, 0.04), Vector3(0, 1.55, 0.04), "blue")
	for side: int in [-1, 1]:
		var x: float = side * 0.6
		kit.box(self, Vector3(0.5, 0.56, 0.35), Vector3(x, 1.29, 0.27), "wall")
		kit.box(self, Vector3(0.62, 0.04, 0.46), Vector3(x, 1.58, 0.33), "trim")
		kit.box(self, Vector3(0.62, 0.08, 0.02), Vector3(x, 1.63, 0.55), "gold")
		for index: int in range(5):
			var spot := Vector3(x - 0.24 + index * 0.12, 1.66, 0.56)
			if side < 0:
				kit.sphere(self, 0.03, spot, "rose")
			else:
				kit.box(self, Vector3(0.05, 0.05, 0.05), spot, "ivy").rotation.y = index
		var receiver: MeshInstance3D = kit.sphere(self, 0.06, TARGETS[0 if side < 0 else 2], "iron")
		receivers.append(receiver)
		receiver_flares.append(kit.flare(self, receiver.position + Vector3(0, 0, 0.08), Color("ffc27a"), 0.7))
	curtain = kit.box(self, Vector3(0.42, 0.78, 0.05), Vector3(0, 1.38, 0.35), "black")
	joined = kit.box(self, Vector3(0.78, 0.03, 0.12), Vector3(0, 1.6, 0.33), "gold")
	card = kit.letter_card(self, "P", 4, Vector3(0, 1.74, 0.34), 0.0)
	kit.note(self, "diagram", Vector3(-0.72, 0.99, 0.95), Vector2(0.24, 0.18), Vector3(-PI / 2, 0, 0.3))
	for index: int in range(2):
		var pivot := Node3D.new()
		pivot.position = Vector3(LANTERN_X[index], LANTERN_Y, LANTERN_Z)
		add_child(pivot)
		pivots.append(pivot)
		kit.box(pivot, Vector3(0.12, 0.16, 0.14), Vector3.ZERO, "iron")
		var lens: MeshInstance3D = kit.cylinder(pivot, 0.045, 0.02, Vector3(0, 0, -0.08), "lit" if index == 0 else "glass")
		lens.rotation.x = PI / 2
		lenses.append(lens)
		var beam: MeshInstance3D = kit.box(pivot, Vector3(0.025, 0.025, 1.0), Vector3.ZERO, "beam")
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beams.append(beam)
		kit.cylinder(self, 0.03, 0.12, Vector3(LANTERN_X[index], 1.0, LANTERN_Z), "iron")
		# A sun disc or a pale crescent on top marks each lantern.
		if index == 0:
			kit.cylinder(pivot, 0.05, 0.015, Vector3(0, 0.1, 0), "gold")
		else:
			kit.sphere(pivot, 0.04, Vector3(0, 0.1, 0), "bone", 0.4)
		kit.interactable(self, "lantern", "LANTERN_SUN_NAME" if index == 0 else "LANTERN_MOON_NAME", "BALCONY_INSPECT", pivot.position, Vector3(0.24, 0.3, 0.26), index)


func apply(state: StudyState, animate: bool) -> void:
	var fitted: Array[bool] = [state.sun_lens_inserted, state.moon_lens_inserted]
	var lit: Array[bool] = state.receivers_lit()
	var tween: Tween = create_tween().set_parallel(true) if animate and is_inside_tree() else null
	for index: int in range(2):
		var aim: Vector3 = TARGETS[state.lanterns[index]] - pivots[index].position
		var turn := Quaternion(Basis.looking_at(aim, Vector3.UP))
		if tween != null:
			tween.tween_property(pivots[index], "quaternion", turn, 0.35)
		else:
			pivots[index].quaternion = turn
		(beams[index].mesh as BoxMesh).size.z = aim.length()
		beams[index].position = Vector3(0, 0, -aim.length() / 2)
		beams[index].visible = fitted[index]
		lenses[index].visible = fitted[index]
		receivers[index].material_override = kit.materials["lit" if lit[index] else "iron"]
		receiver_flares[index].visible = lit[index]
	joined.visible = state.balcony_solved
	card.visible = state.balcony_solved
	var curtain_y: float = 2.06 if state.balcony_solved else 1.38
	if tween != null:
		tween.tween_property(curtain, "position:y", curtain_y, 1.1).set_trans(Tween.TRANS_SINE)
	else:
		curtain.position.y = curtain_y
