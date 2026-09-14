class_name Trinket
extends RigidBody3D
## A loose everyday object with no puzzle purpose: it can be picked up, carried in the left
## hand, and thrown with Q. Trinkets are scenery and are not saved.

const KINDS: Array[String] = ["apple", "pear", "bread", "bottle", "tankard", "book", "cabbage", "fish", "candle", "bone", "cup", "coin"]

var kind: String
var handle: StudyInteractable


static func make(kit: PropKit, kind_name: String) -> Trinket:
	var item := Trinket.new()
	item.kind = kind_name
	item.collision_layer = 8
	item.collision_mask = 1 | 8
	item.mass = 0.4
	item.continuous_cd = true
	var model: Node3D = model_for(kit, kind_name)
	item.add_child(model)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size_for(kind_name)
	shape.shape = box
	shape.position.y = box.size.y / 2.0
	item.add_child(shape)
	item.handle = StudyInteractable.new()
	item.handle.interaction_id = "trinket"
	item.handle.title_key = "TRINKET_" + kind_name.to_upper()
	item.handle.description_key = "TRINKET_INSPECT"
	item.handle.collision_layer = 16
	item.handle.collision_mask = 0
	var handle_shape := CollisionShape3D.new()
	var handle_box := BoxShape3D.new()
	handle_box.size = box.size + Vector3.ONE * 0.12
	handle_shape.shape = handle_box
	handle_shape.position = shape.position
	item.handle.add_child(handle_shape)
	item.add_child(item.handle)
	for mesh: Node in model.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return item


## Whether the focus ray can find this trinket.
func set_reachable(reachable: bool) -> void:
	handle.collision_layer = 16 if reachable else 0


static func size_for(kind_name: String) -> Vector3:
	match kind_name:
		"bread": return Vector3(0.24, 0.1, 0.12)
		"bottle": return Vector3(0.08, 0.28, 0.08)
		"tankard": return Vector3(0.12, 0.14, 0.12)
		"book": return Vector3(0.2, 0.06, 0.26)
		"cabbage": return Vector3(0.18, 0.16, 0.18)
		"fish": return Vector3(0.1, 0.06, 0.3)
		"candle": return Vector3(0.08, 0.2, 0.08)
		"bone": return Vector3(0.28, 0.05, 0.06)
		"coin": return Vector3(0.1, 0.08, 0.1)
	return Vector3(0.1, 0.1, 0.1)


static func model_for(kit: PropKit, kind_name: String) -> Node3D:
	var node := Node3D.new()
	match kind_name:
		"apple":
			kit.sphere(node, 0.05, Vector3(0, 0.05, 0), "rose")
			kit.cylinder(node, 0.006, 0.03, Vector3(0, 0.1, 0), "wood")
		"pear":
			kit.sphere(node, 0.045, Vector3(0, 0.045, 0), "ivy")
			kit.sphere(node, 0.03, Vector3(0, 0.1, 0), "ivy")
		"bread":
			kit.sphere(node, 0.12, Vector3(0, 0.05, 0), "wood", 0.4).scale = Vector3(1.0, 1.0, 0.5)
			for x: float in [-0.05, 0.0, 0.05]:
				kit.box(node, Vector3(0.012, 0.01, 0.08), Vector3(x, 0.095, 0), "plaster_warm")
		"bottle":
			kit.cylinder(node, 0.04, 0.18, Vector3(0, 0.09, 0), "ivy", 0.04)
			kit.cylinder(node, 0.015, 0.08, Vector3(0, 0.22, 0), "ivy")
			kit.cylinder(node, 0.017, 0.02, Vector3(0, 0.27, 0), "trim")
		"tankard":
			kit.cylinder(node, 0.055, 0.14, Vector3(0, 0.07, 0), "iron", 0.05)
			kit.box(node, Vector3(0.02, 0.09, 0.04), Vector3(0.07, 0.07, 0), "iron")
		"book":
			kit.box(node, Vector3(0.2, 0.06, 0.26), Vector3(0, 0.03, 0), "velvet")
			kit.box(node, Vector3(0.19, 0.045, 0.25), Vector3(0.006, 0.03, 0), "paper")
		"cabbage":
			kit.sphere(node, 0.09, Vector3(0, 0.08, 0), "ivy", 0.9)
			kit.sphere(node, 0.07, Vector3(0, 0.1, 0.02), "plaster_mint")
		"fish":
			kit.sphere(node, 0.12, Vector3(0, 0.03, 0), "iron", 0.25).scale = Vector3(0.4, 1.0, 1.2)
			kit.box(node, Vector3(0.01, 0.06, 0.06), Vector3(0, 0.03, -0.16), "iron").rotation.x = PI / 4
		"candle":
			kit.cylinder(node, 0.03, 0.16, Vector3(0, 0.08, 0), "paper")
			kit.cylinder(node, 0.04, 0.02, Vector3(0, 0.01, 0), "gold")
		"bone":
			kit.cylinder(node, 0.014, 0.24, Vector3(0, 0.025, 0), "bone").rotation.z = PI / 2
			for x: float in [-0.12, 0.12]:
				kit.sphere(node, 0.026, Vector3(x, 0.025, 0), "bone")
		"cup":
			kit.cylinder(node, 0.045, 0.08, Vector3(0, 0.04, 0), "bone", 0.035)
		"coin":
			kit.sphere(node, 0.05, Vector3(0, 0.04, 0), "trim", 0.9)
			kit.cylinder(node, 0.02, 0.02, Vector3(0, 0.09, 0), "gold")
	return node
