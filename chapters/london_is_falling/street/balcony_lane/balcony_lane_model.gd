class_name BalconyLaneModel
extends Node3D
## Romeo & Juliet in Balcony Lane. Juliet leans from a balcony, Romeo kneels below, and
## Friar Laurence waits by his chapel door, all frozen with empty hands. A prop cart holds
## five props; the playbill shows who carries what. Built in street coordinates.

const CART_SLOTS: Array[Vector3] = [Vector3(3.35, 0.98, -7.3), Vector3(3.35, 0.98, -7.75), Vector3(3.35, 0.98, -8.2), Vector3(3.35, 0.98, -8.65), Vector3(3.35, 0.98, -9.1)]

var props: Array[Node3D] = []
var slot_points: Array[Vector3] = []
var spotlights: Array[OmniLight3D] = []
var kit: PropKit


func build(prop_kit: PropKit, scene: ActScene) -> void:
	kit = prop_kit
	# Juliet's balcony on the left facade.
	kit.box(self, Vector3(1.2, 0.14, 1.9), Vector3(-4.35, 2.2, -15), "stone", true)
	for z: float in [-15.85, -14.15]:
		kit.box(self, Vector3(0.12, 0.8, 0.12), Vector3(-3.8, 2.65, z), "stone")
	kit.box(self, Vector3(0.1, 0.08, 1.9), Vector3(-3.8, 3.05, -15), "stone")
	for index: int in range(9):
		kit.box(self, Vector3(0.05, 0.7, 0.05), Vector3(-3.8, 2.62, -15.8 + index * 0.2), "iron")
	for index: int in range(3):
		kit.box(self, Vector3(0.3, 0.3, 0.14), Vector3(-4.8 + index * 0.1, 1.95 - index * 0.35, -15.6 + index * 0.4), "stone").rotation.z = 0.4
	kit.box(self, Vector3(0.06, 1.9, 1.1), Vector3(-4.94, 3.1, -15), "window")
	for index: int in range(14):
		var spot := Vector3(-4.9, 0.4 + index * 0.25, -16.4 + sin(index * 1.3) * 0.5)
		kit.box(self, Vector3(0.12, 0.28, 0.2), spot, "ivy").rotation.x = index
	for index: int in range(6):
		kit.sphere(self, 0.06, Vector3(-3.75, 3.12, -15.75 + index * 0.3), "rose")
	var juliet: Node3D = ActorKit.make(kit, {"costume": "linen", "skirt": true, "sleeve": "linen", "left_arm": Vector3(0.5, 0, 0.3), "right_arm": Vector3(1.15, 0, 0.35), "nod": 0.35})
	_place(juliet, Vector3(-4.45, 2.27, -15.1), PI / 2)
	var romeo: Node3D = ActorKit.make(kit, {"costume": "velvet", "legs": "dark", "hat": "cap", "kneel": true, "right_arm": Vector3(2.35, 0, 0.25), "left_arm": Vector3(0.9, 0, -0.3), "nod": -0.4})
	_place(romeo, Vector3(-2.55, 0, -15.1), -PI / 2)
	# Friar Laurence by the chapel door on the right.
	kit.box(self, Vector3(0.2, 2.4, 1.4), Vector3(4.92, 1.2, -21.5), "timber")
	kit.box(self, Vector3(0.22, 0.12, 0.5), Vector3(4.9, 2.7, -21.5), "gold")
	kit.box(self, Vector3(0.22, 0.5, 0.12), Vector3(4.9, 2.75, -21.5), "gold")
	var friar: Node3D = ActorKit.make(kit, {"costume": "trim", "skirt": true, "hat": "hood", "right_arm": Vector3(1.0, 0, 0.1), "left_arm": Vector3(0.35, 0, 0.1), "nod": 0.25})
	_place(friar, Vector3(4.0, 0, -20.6), -PI / 2 - 0.3)
	# Mercutio and Tybalt, mid-duel.
	var mercutio: Node3D = ActorKit.make(kit, {"costume": "rose", "legs": "dark", "hat": "cap", "right_arm": Vector3(1.45, 0, 0.1), "left_arm": Vector3(0.4, 0, 0.9), "lean": 0.12})
	_place(mercutio, Vector3(0.1, 0, -25.4), PI / 2)
	var tybalt: Node3D = ActorKit.make(kit, {"costume": "black", "cape": "curtain", "right_arm": Vector3(1.6, 0, -0.1), "left_arm": Vector3(0.3, 0, 0.6), "lean": 0.15})
	_place(tybalt, Vector3(1.75, 0, -25.4), -PI / 2)
	for fighter: Node3D in [mercutio, tybalt]:
		kit.box(ActorKit.hand_of(fighter), Vector3(0.02, 0.02, 0.9), Vector3(0, 0, 0.45), "iron")
		kit.box(ActorKit.hand_of(fighter), Vector3(0.14, 0.03, 0.03), Vector3.ZERO, "gold")
	# The prop cart against the right facade.
	kit.box(self, Vector3(0.9, 0.62, 2.5), Vector3(3.8, 0.62, -8.2), "wood", true)
	kit.box(self, Vector3(1.0, 0.06, 2.6), Vector3(3.8, 0.95, -8.2), "trim")
	for z: float in [-7.3, -9.1]:
		kit.cylinder(self, 0.42, 0.08, Vector3(3.3, 0.42, z), "timber").rotation.z = PI / 2
		kit.cylinder(self, 0.06, 0.1, Vector3(3.27, 0.42, z), "iron").rotation.z = PI / 2
	kit.box(self, Vector3(0.05, 0.05, 1.2), Vector3(3.3, 0.9, -6.2), "wood").rotation.x = 0.3
	for index: int in range(5):
		kit.cylinder(self, 0.14, 0.03, CART_SLOTS[index] + Vector3(0, -0.02, 0), "curtain")
		kit.interactable(self, "prop_slot", "PROP_CART", "PROPS_INSPECT", CART_SLOTS[index] + Vector3(0, 0.1, 0), Vector3(0.36, 0.3, 0.42), index)
	slot_points.assign(CART_SLOTS)
	for pair: Array in [[5, romeo], [6, juliet], [7, friar]]:
		var point: Vector3 = ActorKit.hand_of(pair[1]).global_position
		slot_points.append(point)
		kit.interactable(self, "prop_slot", ["PROP_ROMEO", "PROP_JULIET", "PROP_FRIAR"][pair[0] - 5], "PROPS_INSPECT", point, Vector3(0.42, 0.42, 0.42), pair[0])
		var light: OmniLight3D = kit.light(self, (pair[1] as Node3D).global_position + Vector3(0.4, 2.4, 0), Color("ffe2bd"), 0.0, 4.5)
		spotlights.append(light)
	var playbill: StudyInteractable = kit.note(self, "playbill", Vector3(4.92, 1.75, -11.6), Vector2(0.7, 0.95))
	playbill.rotation.y = -PI / 2
	kit.box(playbill, Vector3(0.78, 1.03, 0.004), Vector3(0, 0, -0.004), "curtain")
	for piece: int in range(5):
		var model: Node3D = make_prop(kit, piece)
		add_child(model)
		props.append(model)
	scene.flicker(kit.light(self, Vector3(-3.0, 3.4, -15.0), Color("ffc98a"), 1.6, 5.0))


func apply(state: StudyState, animate: bool) -> void:
	var tween: Tween = create_tween().set_parallel(true) if animate and is_inside_tree() else null
	for slot: int in range(8):
		var piece: int = state.props[slot]
		if piece < 0:
			continue
		var target: Vector3 = slot_points[slot] + (Vector3(0, 0.06, 0) if slot < 5 else Vector3.ZERO)
		if tween != null:
			tween.tween_property(props[piece], "position", target, 0.3)
		else:
			props[piece].position = target
	for piece: int in range(5):
		props[piece].visible = not (state.held_station == "props" and state.held_piece == piece)
	for light: OmniLight3D in spotlights:
		light.light_energy = 2.2 if state.props_solved else 0.0


func _place(actor: Node3D, location: Vector3, yaw: float) -> void:
	add_child(actor)
	actor.global_position = location
	actor.rotation.y = yaw


## Props 0 rose, 1 sealed letter, 2 sleeping-potion vial, 3 skull, 4 tin crown.
static func make_prop(kit: PropKit, piece: int) -> Node3D:
	var node := Node3D.new()
	match piece:
		0:
			kit.sphere(node, 0.06, Vector3(0, 0.1, 0), "rose")
			kit.cylinder(node, 0.01, 0.22, Vector3(0, -0.02, 0), "ivy")
			kit.box(node, Vector3(0.06, 0.015, 0.03), Vector3(0.03, 0.0, 0), "ivy").rotation.z = 0.6
		1:
			kit.box(node, Vector3(0.2, 0.012, 0.14), Vector3.ZERO, "paper").rotation.x = 0.3
			kit.cylinder(node, 0.025, 0.02, Vector3(0, 0.02, 0.02), "rose").rotation.x = 0.3
		2:
			kit.cylinder(node, 0.035, 0.12, Vector3(0, 0.05, 0), "glass", 0.02)
			kit.cylinder(node, 0.012, 0.04, Vector3(0, 0.13, 0), "trim")
			kit.sphere(node, 0.02, Vector3(0, 0.02, 0), "brew")
		3:
			kit.sphere(node, 0.08, Vector3(0, 0.08, 0), "bone", 0.95)
			kit.box(node, Vector3(0.09, 0.04, 0.07), Vector3(0, 0.0, 0.03), "bone")
			for x: float in [-0.03, 0.03]:
				kit.box(node, Vector3(0.025, 0.025, 0.02), Vector3(x, 0.09, 0.07), "black")
		_:
			kit.cylinder(node, 0.09, 0.07, Vector3(0, 0.04, 0), "gold", 0.1)
			for index: int in range(5):
				var angle: float = index * TAU / 5
				kit.box(node, Vector3(0.02, 0.06, 0.02), Vector3(cos(angle) * 0.09, 0.1, sin(angle) * 0.09), "gold")
	return node
