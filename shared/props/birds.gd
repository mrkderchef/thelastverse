class_name Birds
extends RefCounted
## Pigeons that peck on the cobbles and scatter into the sky when the player walks close,
## and gulls that wheel slowly overhead.


static func bird(kit: PropKit, look: String, size: float = 1.0) -> Node3D:
	var node := Node3D.new()
	kit.sphere(node, 0.08 * size, Vector3(0, 0.08 * size, 0), look, 0.8).scale = Vector3(0.8, 1.0, 1.3)
	kit.sphere(node, 0.045 * size, Vector3(0, 0.16 * size, 0.08 * size), look)
	kit.cylinder(node, 0.015 * size, 0.04 * size, Vector3(0, 0.155 * size, 0.13 * size), "gold", 0.0).rotation.x = PI / 2
	for side: float in [-1.0, 1.0]:
		var wing: MeshInstance3D = kit.box(node, Vector3(0.14 * size, 0.012, 0.1 * size), Vector3(side * 0.07 * size, 0.1 * size, 0), look)
		wing.name = "Wing" + ("L" if side < 0 else "R")
	kit.box(node, Vector3(0.06 * size, 0.01, 0.08 * size), Vector3(0, 0.07 * size, -0.12 * size), look).rotation.x = 0.3
	for mesh: Node in node.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


## A flock of pigeons around `center` that flies off when the player comes within `radius`.
static func flock(scene: ActScene, kit: PropKit, center: Vector3, count: int, seed_value: int) -> Node3D:
	var group := PigeonFlock.new()
	group.scene = scene
	group.position = center
	scene.add_child(group)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for index: int in range(count):
		var pigeon: Node3D = bird(kit, ["iron", "stone", "dark"][index % 3])
		pigeon.position = Vector3(rng.randf_range(-1.4, 1.4), 0, rng.randf_range(-1.4, 1.4))
		pigeon.rotation.y = rng.randf() * TAU
		group.add_child(pigeon)
		group.homes.append(pigeon.position)
		var peck: Tween = pigeon.create_tween().set_loops()
		peck.tween_interval(rng.randf_range(0.4, 2.0))
		peck.tween_property(pigeon, "rotation:x", 0.5, 0.12)
		peck.tween_property(pigeon, "rotation:x", 0.0, 0.12)
	return group


## Gulls circling high above a point.
static func gulls(scene: ActScene, kit: PropKit, center: Vector3, count: int) -> void:
	for index: int in range(count):
		var pivot := Node3D.new()
		pivot.position = center + Vector3(0, index * 1.5, 0)
		scene.add_child(pivot)
		var gull: Node3D = bird(kit, "linen", 2.0)
		gull.position = Vector3(6.0 + index * 2.0, 0, 0)
		gull.rotation.y = PI
		pivot.add_child(gull)
		var circle: Tween = pivot.create_tween().set_loops()
		circle.tween_property(pivot, "rotation:y", TAU * (1 if index % 2 == 0 else -1), 14.0 + index * 3.0).as_relative()
		_flap(gull, 0.5)


static func _flap(node: Node3D, period: float) -> void:
	for side: String in ["L", "R"]:
		var wing: Node3D = node.find_child("Wing" + side, true, false) as Node3D
		var direction: float = -1.0 if side == "L" else 1.0
		var flap: Tween = wing.create_tween().set_loops()
		flap.tween_property(wing, "rotation:z", 0.7 * direction, period / 2.0)
		flap.tween_property(wing, "rotation:z", -0.4 * direction, period / 2.0)


class PigeonFlock:
	extends Node3D

	var scene: ActScene
	var homes: Array[Vector3] = []
	var flown: bool = false
	var away_time: float = 0.0

	func _process(delta: float) -> void:
		if scene == null or scene.player == null:
			return
		var offset: Vector3 = scene.player.global_position - global_position
		offset.y = 0
		if not flown and offset.length() < 3.2:
			flown = true
			away_time = 0.0
			scatter()
		elif flown:
			away_time += delta
			if away_time > 14.0 and offset.length() > 8.0:
				flown = false
				land()

	func scatter() -> void:
		for index: int in range(get_child_count()):
			var pigeon := get_child(index) as Node3D
			if not pigeon.has_meta("flapping"):
				pigeon.set_meta("flapping", true)
				Birds._flap(pigeon, 0.18)
			var flee := Vector3(randf_range(-6.0, 6.0), randf_range(7.0, 11.0), randf_range(-6.0, 6.0))
			pigeon.look_at(pigeon.global_position + Vector3(flee.x, 0, flee.z), Vector3.UP, true)
			var tween: Tween = pigeon.create_tween()
			tween.tween_property(pigeon, "position", homes[index] + flee, randf_range(1.4, 2.2)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_callback(pigeon.hide)

	func land() -> void:
		for index: int in range(get_child_count()):
			var pigeon := get_child(index) as Node3D
			pigeon.position = homes[index]
			pigeon.show()
