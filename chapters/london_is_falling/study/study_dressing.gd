class_name StudyDressing
extends RefCounted
## Furniture and clutter that make the study read as a lived-in room, all set against the
## walls: desk under the window, fireplace and armchair, bed, wardrobe, clock, shelves,
## chest of drawers, trunk, dress form, chandelier, and loose papers. Four loose pages are
## optional readable lore. No floating text.


static func build(room: StudyRoom, kit: PropKit) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1606
	_desk(room, kit)
	_fireplace(room, kit)
	_armchair(room, kit)
	_bed(room, kit)
	_trunk(room, kit)
	_chest_of_drawers(room, kit)
	_dress_form(room, kit)
	_wardrobe(room, kit)
	_clock(room, kit)
	_coat_stand(room, kit)
	_shelf(room, kit, Vector3(-4.3, 0, -5.65), 0.0)
	_shelf(room, kit, Vector3(5.65, 0, 4.6), -PI / 2)
	_crates(room, kit)
	_chandelier(room, kit)
	_candelabra(room, kit)
	_globe(room, kit)
	_walls(room, kit)
	_floor_clutter(room, kit, rng)
	_rigging(room, kit, rng)


static func _desk(room: StudyRoom, kit: PropKit) -> void:
	kit.box(room, Vector3(2.2, 0.08, 0.85), Vector3(3.8, 0.84, -5.42), "trim", true)
	for x: float in [2.8, 4.8]:
		kit.box(room, Vector3(0.5, 0.8, 0.8), Vector3(x, 0.4, -5.42), "wood", true)
		for y: float in [0.2, 0.45, 0.68]:
			kit.box(room, Vector3(0.44, 0.02, 0.01), Vector3(x, y, -5.01), "dark")
			kit.box(room, Vector3(0.08, 0.025, 0.03), Vector3(x, y + 0.08, -5.0), "gold")
	kit.note(room, "note", Vector3(3.6, 0.9, -5.25), Vector2(0.32, 0.42), Vector3(-PI / 2, 0, 0.25))
	room.candle(Vector3(4.55, 0.88, -5.6))
	kit.cylinder(room, 0.045, 0.07, Vector3(4.2, 0.915, -5.3), "black")
	kit.box(room, Vector3(0.012, 0.012, 0.32), Vector3(4.25, 1.0, -5.3), "linen").rotation = Vector3(-0.9, 0.4, 0)
	for index: int in range(5):
		kit.box(room, Vector3(0.3, 0.012, 0.42), Vector3(3.05, 0.89 + index * 0.013, -5.5), "paper").rotation.y = index * 0.15
	for index: int in range(3):
		kit.box(room, Vector3(0.36, 0.08, 0.26), Vector3(2.95, 0.92 + index * 0.08, -5.72), ["rug", "blue", "trim"][index]).rotation.y = 0.1 * index
	kit.sphere(room, 0.08, Vector3(4.85, 0.96, -5.4), "bone", 0.9)
	kit.box(room, Vector3(0.09, 0.035, 0.07), Vector3(4.85, 0.9, -5.35), "bone")
	var chair := Node3D.new()
	chair.position = Vector3(3.7, 0, -4.55)
	chair.rotation.y = 0.25
	room.add_child(chair)
	kit.box(chair, Vector3(0.5, 0.06, 0.5), Vector3(0, 0.48, 0), "wood", true)
	for x: float in [-0.21, 0.21]:
		for z: float in [-0.21, 0.21]:
			kit.box(chair, Vector3(0.05, 0.48, 0.05), Vector3(x, 0.24, z), "wood")
	kit.box(chair, Vector3(0.5, 0.6, 0.05), Vector3(0, 0.8, 0.23), "trim")


static func _fireplace(room: StudyRoom, kit: PropKit) -> void:
	var z: float = 0.35
	kit.box(room, Vector3(0.5, 4.5, 2.3), Vector3(-5.72, 2.25, z), "wall", true)
	kit.box(room, Vector3(0.06, 0.85, 1.05), Vector3(-5.45, 0.47, z), "black")
	for side: float in [-0.68, 0.68]:
		kit.box(room, Vector3(0.18, 1.2, 0.3), Vector3(-5.4, 0.6, z + side), "trim", true)
	kit.box(room, Vector3(0.38, 0.1, 2.2), Vector3(-5.36, 1.25, z), "wood")
	kit.box(room, Vector3(0.7, 0.04, 1.9), Vector3(-5.15, 0.02, z), "iron")
	for offset: float in [-0.15, 0.15]:
		kit.cylinder(room, 0.06, 0.7, Vector3(-5.55, 0.13, z + offset), "wood").rotation.x = PI / 2
	for offset: float in [-0.2, 0.0, 0.2]:
		kit.sphere(room, 0.08, Vector3(-5.55, 0.32, z + offset), "flame", 2.2)
	kit.flare(room, Vector3(-5.45, 0.35, z), Color("ff8a3a"), 1.6)
	room.flicker(kit.light(room, Vector3(-5.1, 0.6, z), Color("ff7a2e"), 2.4, 6.5, true))
	room.candle(Vector3(-5.4, 1.3, z - 0.85), false)
	room.candle(Vector3(-5.4, 1.3, z + 0.85), false)
	kit.box(room, Vector3(0.14, 0.24, 0.3), Vector3(-5.42, 1.42, z), "wood")
	kit.cylinder(room, 0.09, 0.02, Vector3(-5.34, 1.46, z), "bone").rotation.z = PI / 2
	# A painting above the mantel, turned to face the wall.
	kit.box(room, Vector3(0.05, 0.95, 1.2), Vector3(-5.45, 2.35, z), "gold")
	kit.box(room, Vector3(0.06, 0.85, 1.1), Vector3(-5.43, 2.35, z), "wood")
	kit.box(room, Vector3(0.04, 0.05, 1.0), Vector3(-5.4, 2.35, z), "trim")
	kit.cylinder(room, 0.015, 0.8, Vector3(-5.0, 0.4, z + 1.05), "iron").rotation.z = 0.2


static func _armchair(room: StudyRoom, kit: PropKit) -> void:
	var chair := Node3D.new()
	chair.position = Vector3(-4.0, 0, 0.35)
	chair.rotation.y = PI / 2 - 0.3
	room.add_child(chair)
	kit.box(chair, Vector3(0.75, 0.42, 0.7), Vector3(0, 0.21, 0), "rug", true)
	kit.box(chair, Vector3(0.75, 0.8, 0.16), Vector3(0, 0.8, 0.3), "rug")
	for x: float in [-0.36, 0.36]:
		kit.box(chair, Vector3(0.12, 0.25, 0.7), Vector3(x, 0.55, 0), "velvet")
	kit.box(chair, Vector3(0.5, 0.06, 0.5), Vector3(0.1, 0.46, -0.05), "linen").rotation.y = 0.4
	var table := Vector3(-4.3, 0, -0.75)
	kit.cylinder(room, 0.3, 0.04, table + Vector3(0, 0.66, 0), "trim", -1.0, true)
	kit.cylinder(room, 0.04, 0.64, table + Vector3(0, 0.32, 0), "wood")
	kit.cylinder(room, 0.2, 0.03, table + Vector3(0, 0.02, 0), "wood")
	kit.cylinder(room, 0.04, 0.24, table + Vector3(0.08, 0.8, 0.05), "black", 0.03)
	kit.cylinder(room, 0.015, 0.08, table + Vector3(0.08, 0.96, 0.05), "black")
	kit.cylinder(room, 0.035, 0.07, table + Vector3(-0.1, 0.72, -0.08), "gold", 0.045)
	kit.box(room, Vector3(0.2, 0.05, 0.28), table + Vector3(-0.05, 0.705, 0.12), "blue").rotation.y = 0.5


static func _bed(room: StudyRoom, kit: PropKit) -> void:
	var bed := Node3D.new()
	bed.position = Vector3(-4.75, 0, 5.05)
	room.add_child(bed)
	kit.box(bed, Vector3(2.3, 0.4, 1.7), Vector3(0, 0.2, 0), "wood", true)
	kit.box(bed, Vector3(2.2, 0.2, 1.6), Vector3(0, 0.5, 0), "linen")
	kit.box(bed, Vector3(0.45, 0.14, 1.2), Vector3(-0.85, 0.66, 0), "linen").rotation.y = 0.05
	kit.box(bed, Vector3(1.5, 0.06, 1.66), Vector3(0.3, 0.63, 0.02), "rug").rotation.z = -0.02
	kit.box(bed, Vector3(1.5, 0.42, 0.04), Vector3(0.3, 0.43, -0.84), "rug").rotation.x = 0.08
	kit.box(bed, Vector3(0.08, 1.0, 1.7), Vector3(-1.15, 0.9, 0), "trim")
	for x: float in [-1.1, 1.1]:
		for z: float in [-0.8, 0.8]:
			kit.cylinder(bed, 0.06, 2.4, Vector3(x, 1.2, z), "wood")
	for z: float in [-0.8, 0.8]:
		kit.box(bed, Vector3(2.3, 0.08, 0.08), Vector3(0, 2.4, z), "trim")
	for x: float in [-1.1, 1.1]:
		kit.box(bed, Vector3(0.08, 0.08, 1.7), Vector3(x, 2.4, 0), "trim")
	kit.box(bed, Vector3(2.3, 0.03, 1.7), Vector3(0, 2.45, 0), "velvet")
	kit.box(bed, Vector3(2.2, 1.9, 0.03), Vector3(0, 1.45, 0.82), "velvet")
	kit.box(bed, Vector3(0.03, 1.9, 1.6), Vector3(-1.13, 1.45, 0), "velvet")
	kit.box(bed, Vector3(0.4, 1.6, 0.03), Vector3(1.0, 1.6, -0.82), "velvet").rotation.z = 0.06
	kit.note(room, "page_bed", Vector3(-5.45, 0.74, 4.67), Vector2(0.2, 0.15), Vector3(-PI / 2, 0, 0.5))


static func _trunk(room: StudyRoom, kit: PropKit) -> void:
	kit.box(room, Vector3(1.0, 0.55, 0.6), Vector3(-2.9, 0.275, 5.4), "trim", true)
	for x: float in [-3.25, -2.9, -2.55]:
		kit.box(room, Vector3(0.04, 0.57, 0.62), Vector3(x, 0.275, 5.4), "iron")
	kit.box(room, Vector3(1.02, 0.08, 0.62), Vector3(-2.9, 0.66, 5.62), "trim").rotation.x = -0.45
	kit.note(room, "page_costumes", Vector3(-3.05, 0.57, 5.3), Vector2(0.22, 0.28), Vector3(-PI / 2, 0, -0.3))
	room.candle(Vector3(-2.6, 0.55, 5.25), false)
	kit.cylinder(room, 0.12, 0.1, Vector3(-2.2, 0.1, 4.75), "gold", 0.14).rotation.z = 1.2
	kit.box(room, Vector3(0.7, 0.03, 0.4), Vector3(-2.3, 0.03, 5.5), "curtain").rotation.y = 0.4


static func _chest_of_drawers(room: StudyRoom, kit: PropKit) -> void:
	var x: float = -0.9
	kit.box(room, Vector3(1.2, 0.95, 0.55), Vector3(x, 0.475, 5.65), "wood", true)
	for y: float in [0.22, 0.5, 0.78]:
		kit.box(room, Vector3(1.1, 0.22, 0.02), Vector3(x, y, 5.365), "trim")
		for knob: float in [-0.3, 0.3]:
			kit.sphere(room, 0.025, Vector3(x + knob, y, 5.35), "gold")
	kit.cylinder(room, 0.25, 0.09, Vector3(x - 0.15, 1.0, 5.65), "bone", 0.3)
	kit.cylinder(room, 0.08, 0.26, Vector3(x + 0.35, 1.08, 5.7), "bone", 0.05)
	kit.box(room, Vector3(0.3, 0.02, 0.2), Vector3(x + 0.1, 0.96, 5.5), "linen").rotation.y = 0.3
	# A small mirror above it, cracked and dark.
	kit.box(room, Vector3(0.7, 0.9, 0.04), Vector3(x, 1.95, 5.95), "gold")
	kit.box(room, Vector3(0.6, 0.8, 0.02), Vector3(x, 1.95, 5.92), "black")
	kit.box(room, Vector3(0.01, 0.7, 0.005), Vector3(x + 0.05, 1.95, 5.905), "bone").rotation.z = 0.35


static func _dress_form(room: StudyRoom, kit: PropKit) -> void:
	var form := Node3D.new()
	form.position = Vector3(1.0, 0, 5.35)
	form.rotation.y = 0.5
	room.add_child(form)
	kit.cylinder(form, 0.25, 0.05, Vector3(0, 0.025, 0), "iron")
	kit.cylinder(form, 0.42, 0.95, Vector3(0, 0.53, 0), "curtain", 0.17, true)
	kit.cylinder(form, 0.17, 0.45, Vector3(0, 1.22, 0), "curtain", 0.14)
	kit.cylinder(form, 0.21, 0.05, Vector3(0, 1.47, 0), "linen")
	kit.cylinder(form, 0.05, 0.12, Vector3(0, 1.53, 0), "bone")
	kit.sphere(form, 0.12, Vector3(0, 1.7, 0), "bone", 1.15)
	for x: float in [0.3, 1.5]:
		var mask: MeshInstance3D = kit.sphere(room, 0.18, Vector3(x, 2.6, 5.93), "bone")
		mask.scale = Vector3(1.0, 1.25, 0.3)
		for eye: float in [-0.06, 0.06]:
			kit.box(room, Vector3(0.05, 0.03, 0.02), Vector3(x + eye, 2.66, 5.87), "black")
		kit.box(room, Vector3(0.12, 0.025, 0.02), Vector3(x, 2.5, 5.87), "black").rotation.z = 0.3 if x < 1 else -0.3


static func _wardrobe(room: StudyRoom, kit: PropKit) -> void:
	var node := _against(room, Vector3(5.84, 0, -4.5), -PI / 2)
	kit.box(node, Vector3(1.2, 2.3, 0.6), Vector3(0, 1.15, 0.3), "wood", true)
	kit.box(node, Vector3(1.3, 0.1, 0.66), Vector3(0, 2.35, 0.32), "trim")
	kit.box(node, Vector3(0.02, 2.0, 0.02), Vector3(0, 1.2, 0.61), "black")
	for x: float in [-0.08, 0.08]:
		kit.box(node, Vector3(0.03, 0.12, 0.03), Vector3(x, 1.2, 0.63), "gold")
	# One door hangs ajar with a sleeve caught in it.
	var door: MeshInstance3D = kit.box(node, Vector3(0.58, 2.0, 0.04), Vector3(0.45, 1.2, 0.72), "trim")
	door.rotation.y = -0.35
	kit.box(node, Vector3(0.12, 0.6, 0.08), Vector3(0.12, 0.9, 0.64), "curtain").rotation.z = 0.15


static func _clock(room: StudyRoom, kit: PropKit) -> void:
	var node := _against(room, Vector3(5.84, 0, -0.55), -PI / 2)
	kit.box(node, Vector3(0.5, 2.1, 0.35), Vector3(0, 1.05, 0.18), "wood", true)
	kit.box(node, Vector3(0.6, 0.12, 0.42), Vector3(0, 2.15, 0.2), "trim")
	kit.cylinder(node, 0.19, 0.03, Vector3(0, 1.75, 0.37), "bone").rotation.x = PI / 2
	kit.box(node, Vector3(0.012, 0.13, 0.01), Vector3(0.0, 1.8, 0.39), "black").rotation.z = 0.4
	kit.box(node, Vector3(0.012, 0.09, 0.01), Vector3(0.0, 1.74, 0.39), "black").rotation.z = -1.9
	kit.box(node, Vector3(0.3, 0.8, 0.01), Vector3(0, 0.95, 0.36), "black")
	kit.cylinder(node, 0.06, 0.02, Vector3(0.05, 0.75, 0.37), "gold").rotation.x = PI / 2
	kit.box(node, Vector3(0.01, 0.45, 0.01), Vector3(0.03, 0.98, 0.37), "gold").rotation.z = 0.12


static func _coat_stand(room: StudyRoom, kit: PropKit) -> void:
	var spot := Vector3(5.3, 0, 3.05)
	kit.cylinder(room, 0.22, 0.04, spot + Vector3(0, 0.02, 0), "iron", -1.0, true)
	kit.cylinder(room, 0.03, 1.85, spot + Vector3(0, 0.95, 0), "wood")
	kit.box(room, Vector3(0.34, 1.0, 0.12), spot + Vector3(0, 1.3, 0.1), "dark").rotation.z = 0.05
	kit.cylinder(room, 0.16, 0.04, spot + Vector3(0, 1.9, 0), "black")
	kit.cylinder(room, 0.1, 0.14, spot + Vector3(0, 1.98, 0), "black")


static func _shelf(room: StudyRoom, kit: PropKit, location: Vector3, yaw: float) -> void:
	var shelf := Node3D.new()
	shelf.position = location
	shelf.rotation.y = yaw
	room.add_child(shelf)
	kit.box(shelf, Vector3(2.4, 3.5, 0.35), Vector3(0, 1.75, 0), "wood", true)
	for y: float in [0.25, 1.1, 1.95, 2.8, 3.55]:
		kit.box(shelf, Vector3(2.6, 0.12, 0.7), Vector3(0, y, 0.2), "trim")
	for row: int in range(4):
		for index: int in range(11):
			if (index * 5 + row * 7) % 9 == 0:
				continue
			var height: float = 0.42 + float((index * 7 + row * 3) % 4) * 0.065
			var book: MeshInstance3D = kit.box(shelf, Vector3(0.15, height, 0.34), Vector3(-1.03 + index * 0.2, 0.34 + row * 0.85 + height / 2, 0.32), ["rug", "blue", "trim", "ivy"][(index + row) % 4])
			book.rotation.z = 0.07 if index % 4 == 0 else 0.0
			kit.box(shelf, Vector3(0.13, 0.018, 0.01), Vector3(-1.03 + index * 0.2, 0.44 + row * 0.85, 0.496), "gold")
	kit.sphere(shelf, 0.12, Vector3(0.9, 3.72, 0.3), "bone", 0.9)


static func _crates(room: StudyRoom, kit: PropKit) -> void:
	kit.box(room, Vector3(0.8, 0.6, 0.6), Vector3(3.0, 0.3, 5.5), "trim", true)
	kit.box(room, Vector3(0.6, 0.45, 0.5), Vector3(3.05, 0.83, 5.5), "wood", true).rotation.y = 0.2
	kit.box(room, Vector3(0.5, 0.4, 0.5), Vector3(3.9, 0.2, 5.4), "wood", true).rotation.y = -0.3
	for y: float in [0.15, 0.45]:
		kit.box(room, Vector3(0.82, 0.04, 0.62), Vector3(3.0, y, 5.5), "iron")
	# A painted crescent moon from an old production leans against them.
	kit.cylinder(room, 0.45, 0.04, Vector3(2.4, 0.46, 5.75), "bone").rotation = Vector3(PI / 2 - 0.2, 0, 0)
	kit.cylinder(room, 0.4, 0.05, Vector3(2.55, 0.5, 5.72), "dark").rotation = Vector3(PI / 2 - 0.2, 0, 0)


static func _chandelier(room: StudyRoom, kit: PropKit) -> void:
	var center := Vector3(-0.2, 3.35, 0.2)
	kit.cylinder(room, 0.02, 1.0, center + Vector3(0, 0.6, 0), "iron")
	for index: int in range(10):
		var angle: float = index * TAU / 10
		kit.box(room, Vector3(0.3, 0.04, 0.04), center + Vector3(cos(angle), 0, sin(angle)) * 0.55, "iron").rotation.y = -angle + PI / 2
	for index: int in range(6):
		var angle: float = index * TAU / 6
		var spot: Vector3 = center + Vector3(cos(angle) * 0.55, 0.02, sin(angle) * 0.55)
		kit.cylinder(room, 0.025, 0.14, spot + Vector3(0, 0.07, 0), "paper")
		kit.sphere(room, 0.025, spot + Vector3(0, 0.18, 0), "flame", 1.6)
		kit.flare(room, spot + Vector3(0, 0.18, 0), Color("ffc27a"), 0.6)
	room.flicker(kit.light(room, center + Vector3(0, -0.2, 0), Color("ffe2bd"), 2.6, 10.0, true))


static func _candelabra(room: StudyRoom, kit: PropKit) -> void:
	var spot := Vector3(1.9, 0, -5.45)
	kit.cylinder(room, 0.2, 0.05, spot + Vector3(0, 0.025, 0), "iron", -1.0, true)
	kit.cylinder(room, 0.025, 1.3, spot + Vector3(0, 0.67, 0), "iron")
	kit.box(room, Vector3(0.5, 0.03, 0.03), spot + Vector3(0, 1.32, 0), "iron")
	for x: float in [-0.25, 0.25]:
		room.candle(spot + Vector3(x, 1.33, 0), false)


static func _globe(room: StudyRoom, kit: PropKit) -> void:
	var spot := Vector3(-2.35, 0, -5.2)
	kit.cylinder(room, 0.25, 0.05, spot + Vector3(0, 0.025, 0), "trim", -1.0, true)
	kit.cylinder(room, 0.03, 0.9, spot + Vector3(0, 0.47, 0), "wood")
	kit.sphere(room, 0.28, spot + Vector3(0, 1.15, 0), "blue")
	kit.cylinder(room, 0.32, 0.02, spot + Vector3(0, 1.15, 0), "gold").rotation = Vector3(PI / 2, 0.4, 0)


static func _walls(room: StudyRoom, kit: PropKit) -> void:
	# Faceless portraits: the company that left.
	for spot: Array in [[Vector3(-5.95, 2.6, -4.5), Vector2(0.75, 1.0)], [Vector3(5.95, 2.9, 1.5), Vector2(0.6, 0.6)], [Vector3(5.95, 2.5, -3.9), Vector2(0.0, 0.0)], [Vector3(2.9, 2.6, 5.95), Vector2(0.9, 0.7)]]:
		var location: Vector3 = spot[0]
		var size: Vector2 = spot[1]
		if size.x <= 0:
			continue
		var along_x: bool = absf(location.z) > 5.9
		var inward: Vector3 = Vector3(0, 0, -signf(location.z)) if along_x else Vector3(-signf(location.x), 0, 0)
		var frame := Vector3(size.x, size.y, 0.06) if along_x else Vector3(0.06, size.y, size.x)
		var canvas := Vector3(size.x - 0.14, size.y - 0.14, 0.07) if along_x else Vector3(0.07, size.y - 0.14, size.x - 0.14)
		kit.box(room, frame, location, "gold")
		kit.box(room, canvas, location + inward * 0.01, "black")
		kit.sphere(room, size.x * 0.17, location + inward * 0.05 + Vector3(0, size.y * 0.12, 0), "bone").scale = Vector3(1.0, 1.2, 0.3) if along_x else Vector3(0.3, 1.2, 1.0)
	# Wall sconces.
	for spot: Vector3 in [Vector3(5.8, 1.75, -3.35), Vector3(5.8, 1.75, 0.2), Vector3(-5.8, 1.75, -4.1), Vector3(-5.8, 1.75, 1.8)]:
		var inward: float = -signf(spot.x)
		kit.box(room, Vector3(0.05, 0.25, 0.12), spot + Vector3(inward * 0.03, -0.05, 0), "iron")
		kit.box(room, Vector3(0.18, 0.03, 0.03), spot + Vector3(inward * 0.1, -0.1, 0), "iron")
		room.candle(spot + Vector3(inward * 0.18, -0.12, 0), false)
	# Stage blocking tape: someone rehearsed here.
	for spot: Vector3 in [Vector3(-1.6, 0.065, -1.6), Vector3(1.6, 0.065, -0.8), Vector3(-1.2, 0.065, 2.9)]:
		for angle: float in [PI / 4, -PI / 4]:
			kit.box(room, Vector3(0.5, 0.006, 0.05), spot, "sigil").rotation.y = angle


static func _floor_clutter(room: StudyRoom, kit: PropKit, rng: RandomNumberGenerator) -> void:
	for index: int in range(30):
		var x: float = rng.randf_range(-3.8, 3.8)
		var z: float = rng.randf_range(-4.4, 4.4)
		var on_rug: bool = x > -2.7 and x < 2.3 and z > -3.0 and z < 3.4
		kit.box(room, Vector3(0.21, 0.004, 0.3), Vector3(x, 0.065 if on_rug else 0.037, z), "paper").rotation = Vector3(rng.randf_range(-0.05, 0.05), rng.randf() * TAU, rng.randf_range(-0.05, 0.05))
	for index: int in range(12):
		kit.sphere(room, rng.randf_range(0.035, 0.055), Vector3(rng.randf_range(-4.5, 4.5), 0.09, rng.randf_range(-4.8, 4.8)), "paper", 0.8)
	kit.note(room, "page_cues", Vector3(1.0, 0.07, 1.8), Vector2(0.3, 0.4), Vector3(-PI / 2, 0, 0.7))
	kit.note(room, "page_window", Vector3(2.25, 1.7, -5.88), Vector2(0.2, 0.26), Vector3(0, 0, 0.12))
	var looks: Array[String] = ["rug", "blue", "trim", "ivy", "dark"]
	for spot: Vector3 in [Vector3(-2.9, 0, -4.6), Vector3(2.5, 0, -4.2), Vector3(-5.0, 0, -1.25), Vector3(-2.2, 0, 4.55), Vector3(0.2, 0, 5.35), Vector3(4.5, 0, 3.45), Vector3(5.2, 0, -1.3)]:
		var height: float = 0.035
		for book: int in range(rng.randi_range(3, 7)):
			var thickness: float = rng.randf_range(0.05, 0.08)
			kit.box(room, Vector3(rng.randf_range(0.22, 0.3), thickness, rng.randf_range(0.3, 0.4)), Vector3(spot.x, height + thickness / 2, spot.z), looks[rng.randi() % looks.size()]).rotation.y = rng.randf_range(-0.5, 0.5)
			height += thickness
		kit.box(room, Vector3(0.45, 0.03, 0.3), Vector3(spot.x + 0.35, 0.05, spot.z + 0.1), looks[rng.randi() % looks.size()]).rotation = Vector3(0, rng.randf() * TAU, 0.12)


static func _rigging(room: StudyRoom, kit: PropKit, rng: RandomNumberGenerator) -> void:
	for spot: Vector2 in [Vector2(-2.6, -3.6), Vector2(2.7, -3.0), Vector2(-2.9, 2.6), Vector2(2.6, 3.0), Vector2(1.3, 4.6)]:
		var length: float = rng.randf_range(1.0, 2.2)
		kit.cylinder(room, 0.012, length, Vector3(spot.x, 4.45 - length / 2, spot.y), "linen")
		if rng.randf() < 0.6:
			kit.box(room, Vector3(0.16, 0.22, 0.16), Vector3(spot.x, 4.4 - length, spot.y), "linen").rotation.y = rng.randf()


static func _against(room: StudyRoom, location: Vector3, yaw: float) -> Node3D:
	var node := Node3D.new()
	node.position = location
	node.rotation.y = yaw
	room.add_child(node)
	return node
