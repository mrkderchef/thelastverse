class_name StreetDressing
extends RefCounted
## The street set: cobbled lanes and a market square, varied timber-framed and pastel houses
## with doors to knock on, shop signs, awnings, flower boxes, neighbours in doors and windows,
## washing lines, bunting, pigeons and gulls, loose goods to pick up, and a frozen cast of
## actors. Puzzle stations are built by their own models.


static func build(scene: ActScene, kit: PropKit) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1606
	# Floors: the lane, the square, and the riverside.
	kit.box(scene, Vector3(10.4, 0.2, 32.5), Vector3(0, -0.1, -14.75), "cobble", true)
	kit.box(scene, Vector3(18.4, 0.2, 32.0), Vector3(0, -0.1, -46.0), "cobble", true)
	kit.box(scene, Vector3(18.4, 0.2, 18.0), Vector3(0, -0.1, -71.0), "cobble", true)
	for spot: Vector3 in [Vector3(0, 0.005, -9.0), Vector3(-2.5, 0.005, -40.0), Vector3(3.0, 0.005, -68.0)]:
		kit.box(scene, Vector3(0.9, 0.01, 1.3), spot, "water").rotation.y = spot.z
	_stage_door(scene, kit)
	_facades(scene, kit, rng, -1, -5.0, 1.5, -30.0, Vector2(-17.0, -13.0))
	_facades(scene, kit, rng, 1, 5.0, 1.5, -30.0, Vector2.ZERO)
	_facades(scene, kit, rng, -1, -9.0, -30.0, -80.0, Vector2.ZERO)
	_facades(scene, kit, rng, 1, 9.0, -30.0, -80.0, Vector2.ZERO)
	for side: int in [-1, 1]:
		var corner := Node3D.new()
		corner.position = Vector3(side * 7.0, 0, -30.0)
		scene.add_child(corner)
		kit.box(corner, Vector3(4.2, 9.0, 0.5), Vector3(0, 4.5, 0.25), "plaster_warm", true)
		for x: float in [-1.0, 1.0]:
			kit.box(corner, Vector3(0.7, 0.9, 0.06), Vector3(x, 5.5, -0.02), "window")
		kit.box(corner, Vector3(4.2, 0.2, 0.1), Vector3(0, 3.2, -0.05), "timber")
	for spot: Vector3 in [Vector3(4.2, 0, -3.0), Vector3(-4.2, 0, -10.5), Vector3(4.2, 0, -18.5), Vector3(-4.2, 0, -27.0), Vector3(8.3, 0, -33.5), Vector3(-8.2, 0, -37.0), Vector3(8.3, 0, -48.5), Vector3(-8.2, 0, -52.0), Vector3(-8.2, 0, -66.0), Vector3(8.3, 0, -61.0)]:
		_lamp(scene, kit, spot)
	_laundry(scene, kit, rng)
	_bunting(scene, kit)
	_market(scene, kit, rng)
	_trinkets(scene)
	_lear(scene, kit)
	_graveyard(scene, kit)
	_midsummer(scene, kit)
	_onlookers(scene, kit)


static func _stage_door(scene: ActScene, kit: PropKit) -> void:
	kit.box(scene, Vector3(10.4, 9.0, 0.4), Vector3(0, 4.5, 1.7), "timber", true)
	kit.box(scene, Vector3(1.6, 2.6, 0.1), Vector3(0, 1.3, 1.46), "black")
	kit.box(scene, Vector3(1.9, 0.2, 0.2), Vector3(0, 2.7, 1.45), "gold")
	for x: float in [-0.9, 0.9]:
		kit.box(scene, Vector3(0.2, 2.7, 0.2), Vector3(x, 1.35, 1.45), "gold")
	kit.flare(scene, Vector3(0, 2.2, 1.2), Color("ff5a3c"), 1.2)
	for index: int in range(6):
		kit.box(scene, Vector3(0.5, 0.8, 0.4), Vector3(-3.5 + index * 0.25, 0.4 + (index % 2) * 0.8, 1.2), "wood", index % 2 == 0).rotation.y = index * 0.2


## Facade stretches kept clear for puzzle stations: [side, z_from, z_to].
const KEEP_CLEAR: Array = [[-1, -12.5, -17.5], [1, -5.5, -12.8], [1, -19.8, -23.2], [-1, -41.8, -46.2], [1, -36.8, -40.2], [-1, -52.5, -58.5], [1, -53.0, -57.5], [1, -69.5, -76.5], [-1, -68.0, -74.0]]
const SIGNS: Array[String] = ["boot", "loaf", "key", "fish", "tankard", "scissors"]


## A row of houses along one side. Faces point toward the street centre.
static func _facades(scene: ActScene, kit: PropKit, rng: RandomNumberGenerator, side: int, x: float, z_from: float, z_to: float, no_jetty: Vector2) -> void:
	var length: float = z_from - z_to
	kit.box(scene, Vector3(0.4, 10.0, length), Vector3(x + side * 0.2, 5.0, (z_from + z_to) / 2.0), "dark", true).visible = false
	var z: float = z_from
	var looks: Array[String] = ["plaster_cream", "plaster_sky", "plaster_rose", "plaster_mint", "brick", "plaster_lilac", "plaster_ochre"]
	var roofs: Array[String] = ["roof", "roof_red", "roof_slate"]
	var doors: Array[String] = ["door_green", "door_red", "door_blue", "timber"]
	var house: int = 0
	while z > z_to + 0.5:
		var width: float = minf(rng.randf_range(3.4, 5.8), z - z_to)
		var center: float = z - width / 2.0
		var height: float = rng.randf_range(6.0, 11.0)
		var look: String = looks[rng.randi() % looks.size()]
		var busy: bool = _kept_clear(side, center, width)
		var face: float = x
		var jetty: bool = rng.randf() < 0.6 and not (no_jetty != Vector2.ZERO and center > no_jetty.x and center < no_jetty.y)
		var upper_face: float = x - side * 0.35 if jetty else x
		kit.box(scene, Vector3(0.5, 3.2, width), Vector3(x + side * 0.25, 1.6, center), look)
		kit.box(scene, Vector3(0.5, height - 3.2, width), Vector3(upper_face + side * 0.25, 3.2 + (height - 3.2) / 2.0, center), look if rng.randf() < 0.7 else looks[rng.randi() % looks.size()])
		var timbered: bool = look != "brick" and rng.randf() < 0.75
		if timbered:
			for beam_z: float in [center - width / 2.0 + 0.1, center, center + width / 2.0 - 0.1]:
				kit.box(scene, Vector3(0.08, 3.2, 0.16), Vector3(face - side * 0.02, 1.6, beam_z), "timber")
				kit.box(scene, Vector3(0.08, height - 3.2, 0.16), Vector3(upper_face - side * 0.02, 3.2 + (height - 3.2) / 2.0, beam_z), "timber")
		kit.box(scene, Vector3(0.1, 0.18, width), Vector3(upper_face - side * 0.03, 3.2, center), "timber")
		var floors: Array[float] = [4.4, 7.0, 9.4]
		for floor_y: float in floors:
			if floor_y > height - 1.0:
				continue
			for offset: float in [-width / 4.0, width / 4.0]:
				_window(scene, kit, rng, side, upper_face, floor_y, center + offset, busy)
		if not busy:
			_shopfront(scene, kit, rng, side, face, center, width, doors[rng.randi() % doors.size()], house)
		# Roof: a sloped eave or a front gable.
		var roof_look: String = roofs[rng.randi() % roofs.size()]
		if rng.randf() < 0.45:
			for slope: float in [-1.0, 1.0]:
				var panel: MeshInstance3D = kit.box(scene, Vector3(0.5, 0.18, width * 0.62), Vector3(upper_face + side * 0.15, height + width * 0.22, center + slope * width * 0.24), roof_look)
				panel.rotation.x = slope * 0.75
			kit.box(scene, Vector3(0.45, width * 0.35, width * 0.45), Vector3(upper_face + side * 0.3, height + width * 0.12, center), look).rotation.x = PI / 4
		else:
			var roof: MeshInstance3D = kit.box(scene, Vector3(2.4, 0.25, width + 0.3), Vector3(upper_face + side * 0.9, height + 0.55, center), roof_look)
			roof.rotation.z = side * 0.55
		if rng.randf() < 0.6:
			kit.box(scene, Vector3(0.5, 1.4, 0.5), Vector3(x + side * 1.2, height + 1.0, center + 0.8), "brick")
			kit.cylinder(scene, 0.12, 0.3, Vector3(x + side * 1.2, height + 1.8, center + 0.8), "roof_red")
		z -= width
		house += 1


static func _kept_clear(side: int, center: float, width: float) -> bool:
	for entry: Array in KEEP_CLEAR:
		if entry[0] == side and center + width / 2.0 > entry[2] and center - width / 2.0 < entry[1]:
			return true
	return false


static func _window(scene: ActScene, kit: PropKit, rng: RandomNumberGenerator, side: int, face: float, y: float, z: float, busy: bool) -> void:
	var lit: bool = rng.randf() < 0.35
	kit.box(scene, Vector3(0.06, 0.95, 0.7), Vector3(face - side * 0.03, y, z), "window" if lit else "black")
	kit.box(scene, Vector3(0.07, 0.06, 0.8), Vector3(face - side * 0.04, y, z), "timber")
	kit.box(scene, Vector3(0.12, 0.07, 0.86), Vector3(face - side * 0.07, y - 0.5, z), "timber")
	var roll: float = rng.randf()
	if roll < 0.35:
		for shutter: float in [-1.0, 1.0]:
			kit.box(scene, Vector3(0.05, 0.95, 0.34), Vector3(face - side * 0.05, y, z + shutter * 0.54), ["door_green", "door_blue", "door_red"][int(absf(z * 3.0)) % 3])
	elif roll < 0.6:
		kit.box(scene, Vector3(0.22, 0.16, 0.8), Vector3(face - side * 0.14, y - 0.58, z), "wood")
		for flower: int in range(5):
			kit.sphere(scene, 0.06, Vector3(face - side * 0.16, y - 0.44, z - 0.3 + flower * 0.15), ["rose", "flag_yellow", "linen"][flower % 3])
	elif roll < 0.72 and not busy:
		# Someone leans out to watch the street.
		var bust: Node3D = ActorKit.bust(kit, {"costume": ["velvet", "plaster_rose", "linen", "ivy", "blue"][rng.randi() % 5], "hat": ["", "cap", "hood", "bald"][rng.randi() % 4], "wave": rng.randf() < 0.4})
		scene.add_child(bust)
		bust.position = Vector3(face - side * 0.12, y - 0.75, z)
		bust.rotation.y = -side * PI / 2 + rng.randf_range(-0.4, 0.4)


static func _shopfront(scene: ActScene, kit: PropKit, rng: RandomNumberGenerator, side: int, face: float, center: float, width: float, door_look: String, house: int) -> void:
	var door_z: float = center + rng.randf_range(-width / 4.0, width / 4.0)
	kit.box(scene, Vector3(0.08, 2.1, 0.95), Vector3(face - side * 0.04, 1.05, door_z), door_look)
	kit.box(scene, Vector3(0.1, 2.25, 1.15), Vector3(face - side * 0.02, 1.1, door_z), "timber")
	kit.sphere(scene, 0.04, Vector3(face - side * 0.1, 1.05, door_z + 0.3), "gold")
	kit.box(scene, Vector3(0.5, 0.12, 1.2), Vector3(face - side * 0.25, 0.06, door_z), "stone", true)
	var knock: StudyInteractable = kit.interactable(scene, "knock", "DOOR_NAME", "DOOR_INSPECT", Vector3(face - side * 0.12, 1.2, door_z), Vector3(0.2, 2.0, 0.9), house)
	knock.set_meta("house", house)
	var window_z: float = center - (width / 4.0 if door_z > center else -width / 4.0)
	kit.box(scene, Vector3(0.06, 1.1, 1.2), Vector3(face - side * 0.03, 1.5, window_z), "window" if rng.randf() < 0.5 else "black")
	var roll: float = rng.randf()
	if roll < 0.35:
		# A striped shop awning.
		for stripe: int in range(6):
			var strip: MeshInstance3D = kit.box(scene, Vector3(1.1, 0.04, 0.22), Vector3(face - side * 0.5, 2.55, window_z - 0.55 + stripe * 0.22), "awning_red" if stripe % 2 == 0 else "linen")
			strip.rotation.z = side * 0.35
		if rng.randf() < 0.7:
			kit.box(scene, Vector3(0.6, 0.8, 1.2), Vector3(face - side * 0.35, 0.4, window_z), "wood", true)
			for crate: int in range(3):
				scene.scatter_trinkets([[["apple", "pear", "cabbage", "bread"][rng.randi() % 4], Vector3(face - side * 0.35, 0.85, window_z - 0.4 + crate * 0.4)]])
	elif roll < 0.7:
		# A hanging trade sign on an iron bracket.
		kit.box(scene, Vector3(0.9, 0.05, 0.05), Vector3(face - side * 0.45, 3.0, door_z + 0.8), "iron")
		var sign_board: MeshInstance3D = kit.box(scene, Vector3(0.04, 0.55, 0.7), Vector3(face - side * 0.7, 2.62, door_z + 0.8), "wood")
		sign_board.rotation.z = side * 0.04
		_pictogram(scene, kit, SIGNS[house % SIGNS.size()], Vector3(face - side * 0.68, 2.62, door_z + 0.8), side)
	else:
		for barrel: int in range(rng.randi_range(1, 2)):
			kit.cylinder(scene, 0.28, 0.75, Vector3(face - side * 0.45, 0.375, window_z + barrel * 0.62), "wood", 0.25, true)
		scene.scatter_trinkets([[["bottle", "tankard", "cup"][rng.randi() % 3], Vector3(face - side * 0.45, 0.85, window_z)]])
	if rng.randf() < 0.2:
		# A neighbour standing in the doorway.
		var neighbour: Node3D = ActorKit.make(kit, {"costume": ["plaster_ochre", "velvet", "ivy", "trim"][rng.randi() % 4], "skirt": rng.randf() < 0.5, "hat": ["cap", "hood", "bald"][rng.randi() % 3], "left_arm": Vector3(0.1, 0, 0.1), "right_arm": Vector3(rng.randf_range(0.2, 2.6), 0, 0.2)})
		scene.add_child(neighbour)
		neighbour.position = Vector3(face - side * 0.45, 0.1, door_z)
		neighbour.rotation.y = -side * PI / 2


static func _pictogram(scene: ActScene, kit: PropKit, kind: String, spot: Vector3, side: int) -> void:
	var out := Vector3(-side * 0.04, 0, 0)
	match kind:
		"boot":
			kit.box(scene, Vector3(0.04, 0.3, 0.12), spot + out + Vector3(0, 0.03, -0.06), "black")
			kit.box(scene, Vector3(0.04, 0.1, 0.28), spot + out + Vector3(0, -0.12, 0.02), "black")
		"loaf":
			kit.sphere(scene, 0.2, spot + out, "plaster_ochre", 0.45).scale = Vector3(0.2, 1.0, 1.4)
		"key":
			kit.cylinder(scene, 0.09, 0.03, spot + out + Vector3(0, 0.12, 0), "gold").rotation.z = PI / 2
			kit.box(scene, Vector3(0.03, 0.3, 0.04), spot + out + Vector3(0, -0.06, 0), "gold")
		"fish":
			kit.sphere(scene, 0.22, spot + out, "blue", 0.35).scale = Vector3(0.2, 1.0, 1.3)
		"tankard":
			kit.box(scene, Vector3(0.04, 0.28, 0.2), spot + out, "iron")
			kit.box(scene, Vector3(0.04, 0.16, 0.05), spot + out + Vector3(0, 0, 0.15), "iron")
		_:
			for angle: float in [0.5, -0.5]:
				kit.box(scene, Vector3(0.03, 0.34, 0.04), spot + out, "iron").rotation.x = angle


static func _lamp(scene: ActScene, kit: PropKit, spot: Vector3) -> void:
	kit.cylinder(scene, 0.08, 3.6, spot + Vector3(0, 1.8, 0), "iron", -1.0, true)
	kit.cylinder(scene, 0.2, 0.3, spot + Vector3(0, 0.15, 0), "iron")
	kit.box(scene, Vector3(0.36, 0.5, 0.36), spot + Vector3(0, 3.85, 0), "gas")
	kit.cylinder(scene, 0.28, 0.22, spot + Vector3(0, 4.2, 0), "iron", 0.02)


## Washing lines strung between the houses, hung with shirts, sheets, and stockings.
static func _laundry(scene: ActScene, kit: PropKit, rng: RandomNumberGenerator) -> void:
	var cloths: Array[String] = ["linen", "plaster_sky", "plaster_rose", "paper", "velvet", "flag_yellow"]
	for z: float in [-7.5, -15.5, -24.5, -35.0, -51.0, -65.0, -77.0]:
		var half: float = 4.5 if z > -30.0 else 8.5
		var y: float = rng.randf_range(5.6, 6.6)
		kit.rope(scene, Vector3(-half, y, z), Vector3(half, y + rng.randf_range(-0.3, 0.3), z), 0.45)
		var x: float = -half + 0.8
		while x < half - 0.8:
			var t: float = (x + half) / (half * 2.0)
			var hang_y: float = y - 0.45 * 4.0 * t * (1.0 - t)
			var roll: float = rng.randf()
			if roll < 0.45:
				var width: float = rng.randf_range(0.6, 1.2)
				var sheet: MeshInstance3D = kit.box(scene, Vector3(width, rng.randf_range(0.7, 1.1), 0.02), Vector3(x + width / 2.0, hang_y - 0.45, z), cloths[rng.randi() % cloths.size()])
				sheet.rotation.x = rng.randf_range(-0.12, 0.12)
				x += width + 0.2
			elif roll < 0.8:
				var shirt := Node3D.new()
				shirt.position = Vector3(x + 0.3, hang_y, z)
				scene.add_child(shirt)
				var look: String = cloths[rng.randi() % cloths.size()]
				kit.box(shirt, Vector3(0.42, 0.5, 0.02), Vector3(0, -0.3, 0), look)
				kit.box(shirt, Vector3(0.8, 0.14, 0.02), Vector3(0, -0.1, 0), look)
				x += 0.8
			else:
				for sock: float in [0.0, 0.18]:
					kit.box(scene, Vector3(0.1, 0.4, 0.02), Vector3(x + sock, hang_y - 0.2, z), "linen")
				x += 0.5


## Pennant strings across the street on thick ropes.
static func _bunting(scene: ActScene, kit: PropKit) -> void:
	var colours: Array[String] = ["flag_red", "flag_yellow", "flag_blue", "linen"]
	for z: float in [-3.5, -19.5, -29.0, -42.0, -58.0, -72.0]:
		var half: float = 4.8 if z > -30.0 else 8.8
		kit.rope(scene, Vector3(-half, 7.2, z), Vector3(half, 7.2, z), 0.7, "linen")
		var count: int = int(half * 2.0 / 0.7)
		for index: int in range(1, count):
			var x: float = -half + index * 0.7
			var t: float = (x + half) / (half * 2.0)
			var flag: MeshInstance3D = kit.box(scene, Vector3(0.3, 0.3, 0.02), Vector3(x, 7.2 - 0.7 * 4.0 * t * (1.0 - t) - 0.2, z), colours[index % colours.size()])
			flag.rotation.z = PI / 4


## The market in the square: stalls, crates, a well, a bell post, pigeons, and loose goods.
static func _market(scene: ActScene, kit: PropKit, rng: RandomNumberGenerator) -> void:
	for stall: Array in [[Vector3(4.6, 0, -33.8), "awning_red"], [Vector3(-5.0, 0, -49.0), "awning_green"], [Vector3(4.8, 0, -60.0), "awning_red"]]:
		var spot: Vector3 = stall[0]
		kit.box(scene, Vector3(2.4, 0.9, 1.0), spot + Vector3(0, 0.45, 0), "wood", true)
		for corner: Vector2 in [Vector2(-1.1, -0.45), Vector2(1.1, -0.45), Vector2(-1.1, 0.45), Vector2(1.1, 0.45)]:
			kit.box(scene, Vector3(0.08, 2.3, 0.08), spot + Vector3(corner.x, 1.15, corner.y), "timber")
		for stripe: int in range(6):
			kit.box(scene, Vector3(0.42, 0.05, 1.3), spot + Vector3(-1.05 + stripe * 0.42, 2.35, 0), stall[1] if stripe % 2 == 0 else "linen").rotation.x = 0.15
		var goods: Array = []
		for item: int in range(5):
			goods.append([["apple", "pear", "cabbage", "fish", "bread", "bottle"][rng.randi() % 6], spot + Vector3(-0.9 + item * 0.45, 0.95, rng.randf_range(-0.25, 0.25))])
		scene.scatter_trinkets(goods)
		var seller: Node3D = ActorKit.make(kit, {"costume": ["plaster_ochre", "velvet", "trim"][rng.randi() % 3], "skirt": rng.randf() < 0.5, "hat": "cap", "right_arm": Vector3(1.5, 0, 0.3), "left_arm": Vector3(0.6, 0, 0.1)})
		scene.add_child(seller)
		seller.position = spot + Vector3(0, 0, 0.9 if spot.x < 0 else -0.9)
		seller.look_at(spot, Vector3.UP, true)
	for index: int in range(8):
		var crate := Vector3(rng.randf_range(-7.5, 7.5), 0, rng.randf_range(-62.0, -32.0))
		if absf(crate.x) < 3.0:
			continue
		kit.box(scene, Vector3(0.6, 0.5, 0.6), crate + Vector3(0, 0.25, 0), "wood", true).rotation.y = rng.randf()
	# The well.
	var well := Vector3(-4.2, 0, -35.0)
	kit.cylinder(scene, 0.9, 0.8, well + Vector3(0, 0.4, 0), "stone", 0.9, true)
	kit.cylinder(scene, 0.75, 0.05, well + Vector3(0, 0.78, 0), "water")
	for x: float in [-0.8, 0.8]:
		kit.box(scene, Vector3(0.1, 1.8, 0.1), well + Vector3(x, 1.3, 0), "timber")
	kit.box(scene, Vector3(1.8, 0.1, 0.1), well + Vector3(0, 2.2, 0), "timber")
	kit.cylinder(scene, 0.15, 0.2, well + Vector3(0, 1.7, 0), "wood", 0.13)
	kit.interactable(scene, "well", "WELL_NAME", "WELL_INSPECT", well + Vector3(0, 0.9, 0), Vector3(1.9, 0.8, 1.9))
	# A bell on a post; ringing it scatters the pigeons.
	var post := Vector3(3.4, 0, -52.0)
	kit.box(scene, Vector3(0.14, 3.2, 0.14), post + Vector3(0, 1.6, 0), "timber", true)
	kit.box(scene, Vector3(0.7, 0.1, 0.1), post + Vector3(-0.3, 3.1, 0), "timber")
	kit.cylinder(scene, 0.22, 0.32, post + Vector3(-0.55, 2.8, 0), "gold", 0.08)
	kit.interactable(scene, "bell", "BELL_NAME", "BELL_INSPECT", post + Vector3(-0.3, 2.3, 0), Vector3(0.9, 1.6, 0.5))
	for flock: Array in [[Vector3(-1.5, 0, -8.0), 7], [Vector3(2.0, 0, -38.0), 10], [Vector3(-2.5, 0, -56.0), 8], [Vector3(1.2, 0, -66.0), 6]]:
		Birds.flock(scene, kit, flock[0], flock[1], int(flock[0].z))
	Birds.gulls(scene, kit, Vector3(0, 16.0, -80.0), 4)
	Birds.gulls(scene, kit, Vector3(0, 14.0, -40.0), 2)


## Loose everyday objects lying about the street.
static func _trinkets(scene: ActScene) -> void:
	scene.scatter_trinkets([
		["apple", Vector3(1.2, 0.1, -4.2)], ["bottle", Vector3(-3.6, 0.1, -6.0)], ["book", Vector3(3.5, 0.1, -25.5)],
		["tankard", Vector3(-3.4, 0.1, -20.0)], ["cup", Vector3(2.9, 0.1, -14.0)], ["coin", Vector3(-1.0, 0.1, -27.8)],
		["fish", Vector3(6.2, 0.1, -64.5)], ["bone", Vector3(-6.4, 0.1, -58.8)], ["candle", Vector3(-6.2, 0.1, -54.4)],
		["bread", Vector3(0.8, 0.1, -44.0)], ["apple", Vector3(-1.6, 0.1, -61.0)], ["pear", Vector3(5.8, 0.1, -46.0)],
	])


static func _lear(scene: ActScene, kit: PropKit) -> void:
	kit.box(scene, Vector3(2.4, 0.5, 2.4), Vector3(6.9, 0.25, -38.5), "wood", true)
	var lear: Node3D = ActorKit.make(kit, {"costume": "linen", "cape": "blue", "hat": "crown", "left_arm": Vector3(2.7, 0, 0.6), "right_arm": Vector3(2.6, 0, 0.5), "nod": -0.5})
	_stand(scene, lear, Vector3(6.9, 0.5, -38.2), -PI / 2)
	var fool: Node3D = ActorKit.make(kit, {"costume": "rose", "legs": "ivy", "hat": "cap", "kneel": true, "right_arm": Vector3(0.9, 0, 0.6), "left_arm": Vector3(1.2, 0, 0.3)})
	_stand(scene, fool, Vector3(6.3, 0.5, -39.3), -PI / 2 + 0.5)
	kit.light(scene, Vector3(6.0, 4.5, -38.5), Color("c8d8ff"), 2.0, 6.0)
	kit.flare(scene, Vector3(7.5, 7.5, -38.5), Color("dfe8ff"), 3.0)


static func _graveyard(scene: ActScene, kit: PropKit) -> void:
	for spot: Vector3 in [Vector3(-8.3, 0.45, -54.0), Vector3(-8.2, 0.4, -55.4), Vector3(-8.35, 0.5, -57.6)]:
		kit.box(scene, Vector3(0.18, 0.9, 0.6), spot, "stone", true).rotation.x = spot.z * 0.1
	kit.box(scene, Vector3(1.6, 0.25, 1.0), Vector3(-6.6, 0.12, -57.2), "wood")
	var hamlet: Node3D = ActorKit.make(kit, {"costume": "black", "cape": "black", "legs": "black", "right_arm": Vector3(1.35, 0, 0.1), "left_arm": Vector3(0.2, 0, 0.1), "nod": 0.2})
	_stand(scene, hamlet, Vector3(-6.4, 0, -55.6), PI / 2 - 0.4)
	var skull: Node3D = BalconyLaneModel.make_prop(kit, 3)
	ActorKit.hand_of(hamlet).add_child(skull)
	skull.position = Vector3(0, 0.02, 0.05)
	var digger: Node3D = ActorKit.make(kit, {"costume": "trim", "hat": "cap", "kneel": true, "right_arm": Vector3(1.0, 0, 0.2), "left_arm": Vector3(1.2, 0, -0.1)})
	_stand(scene, digger, Vector3(-7.3, 0, -57.2), PI / 2 + 0.5)
	kit.box(ActorKit.hand_of(digger), Vector3(0.05, 1.1, 0.05), Vector3(0, -0.2, 0.1), "wood")
	kit.light(scene, Vector3(-5.8, 3.5, -56.0), Color("b8c8e8"), 1.6, 5.0)


static func _midsummer(scene: ActScene, kit: PropKit) -> void:
	kit.box(scene, Vector3(0.8, 0.5, 2.2), Vector3(7.8, 0.25, -55.5), "wood", true)
	var titania: Node3D = ActorKit.make(kit, {"costume": "ivy", "skirt": true, "sleeve": "linen", "hat": "laurel", "left_arm": Vector3(0.2, 0, 1.2), "right_arm": Vector3(2.8, 0, 0.1)})
	_stand(scene, titania, Vector3(7.8, 0.72, -56.4), 0.0)
	titania.rotation = Vector3(-PI / 2, PI, 0)
	var bottom: Node3D = ActorKit.make(kit, {"costume": "plaster_warm", "legs": "trim", "hat": "donkey", "kneel": true, "right_arm": Vector3(1.4, 0, -0.3), "left_arm": Vector3(0.6, 0, 0.4)})
	_stand(scene, bottom, Vector3(6.7, 0, -55.3), -PI / 2 - 0.4)
	for index: int in range(10):
		kit.sphere(scene, 0.07, Vector3(7.2 + sin(index) * 0.8, 0.07, -54.0 - index * 0.35), "rose" if index % 2 == 0 else "linen")
	kit.light(scene, Vector3(7.0, 3.2, -55.5), Color("b8ffcc"), 1.4, 5.0)


static func _onlookers(scene: ActScene, kit: PropKit) -> void:
	var cast: Array = [
		[Vector3(3.9, 0, -2.6), PI - 0.6, {"costume": "blue", "skirt": true, "hat": "hood"}],
		[Vector3(-3.9, 0, -24.5), PI / 2 + 0.3, {"costume": "plaster_warm", "hat": "cap", "left_arm": Vector3(1.9, 0, 0.3)}],
		[Vector3(-7.6, 0, -33.0), PI / 2 + 0.8, {"costume": "velvet", "skirt": true, "right_arm": Vector3(0.9, 0, -0.4)}],
		[Vector3(4.2, 0, -43.5), -PI / 2 - 0.5, {"costume": "trim", "hat": "bald", "right_arm": Vector3(1.6, 0, 0.1), "lean": -0.1}],
		[Vector3(-4.6, 0, -49.5), PI / 2, {"costume": "linen", "skirt": true, "hat": "hood", "left_arm": Vector3(1.4, 0, 0.3)}],
		[Vector3(-7.6, 0, -79.0), PI, {"costume": "dark", "hat": "cap", "lean": 0.2}],
		[Vector3(7.9, 0, -66.0), -PI / 2 - 0.8, {"costume": "blue", "legs": "black", "hat": "pointed", "right_arm": Vector3(0.5, 0, 0.2)}],
	]
	for entry: Array in cast:
		var actor: Node3D = ActorKit.make(kit, entry[2])
		_stand(scene, actor, entry[0], entry[1])


static func _stand(scene: ActScene, actor: Node3D, location: Vector3, yaw: float) -> void:
	scene.add_child(actor)
	actor.position = location
	actor.rotation.y = yaw
