class_name ThamesScenery
extends Node3D
## Everything the player can see from London Bridge: both banks built up to the horizon, a
## merchant harbour with cranes and moored ships downstream (left), a pound lock, weir and
## water mill upstream (right), the Globe and a cathedral on the far bank, and ships of every
## kind working the river. Static masonry is merged into one mesh per material so the whole
## city costs only a few draw calls; ships, cranes, wheels and sails move in `_process`.

const WATER_Y := -4.1
const UPSTREAM_Y := -3.25
const LOCK_Y := -3.7
const NEAR_FACE := -82.0
const FAR_FACE := -126.0
## Static geometry within this distance of the bridge casts shadows; the rest does not.
const SHADOW_RANGE := 70.0
const HOUSE_LOOKS: Array[String] = ["plaster_cream", "plaster_sky", "plaster_rose", "plaster_mint", "brick", "plaster_lilac", "plaster_ochre", "plaster_warm"]
const ROOF_LOOKS: Array[String] = ["roof", "roof_red", "roof_slate"]

var kit: PropKit
var rng := RandomNumberGenerator.new()
var near := Batch.new()
var far := Batch.new()
## Ships sailing long, flat ellipses on the river: {node, center, half, lane, width, rate, phase, water, oars}.
var sailing: Array[Dictionary] = []
var moored: Array[Node3D] = []
var cranes: Array[Node3D] = []
var spinners: Array[Node3D] = []
var foam: StandardMaterial3D
var clock: float = 0.0


class Batch:
	var tools: Dictionary = {}

	func add(look: String, shape: Mesh, xform: Transform3D) -> void:
		if not tools.has(look):
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[look] = tool
		(tools[look] as SurfaceTool).append_from(shape, 0, xform)

	func commit(parent: Node3D, kit: PropKit, shadows: bool) -> void:
		for look: String in tools:
			var node := MeshInstance3D.new()
			node.mesh = (tools[look] as SurfaceTool).commit()
			node.material_override = kit.materials[look]
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(node)
		tools.clear()


func build(prop_kit: PropKit, scene: ActScene) -> void:
	kit = prop_kit
	rng.seed = 1613
	_materials()
	_water_and_banks()
	_near_bank()
	_harbour()
	_lock()
	_upstream()
	_far_bank()
	_horizon()
	near.commit(self, kit, true)
	far.commit(self, kit, false)
	_traffic()
	Birds.gulls(scene, kit, Vector3(-70, 13.0, -86.0), 5)
	Birds.gulls(scene, kit, Vector3(78, 10.0, -96.0), 3)


func _materials() -> void:
	kit.materials["hull"] = kit.material(Color("4a3222"))
	kit.materials["hull_red"] = kit.material(Color("8e2f24"))
	kit.materials["hull_green"] = kit.material(Color("2f5a3e"))
	kit.materials["sail"] = kit.material(Color("f1e6c8"))
	kit.materials["sail_red"] = kit.material(Color("a8502e"))
	kit.materials["thatch"] = kit.material(Color("b8924a"))
	kit.materials["whitestone"] = kit.material(Color("e4ddcc"))
	kit.materials["hill"] = kit.material(Color("6e9a56"))
	kit.materials["leaf"] = kit.material(Color("4f8a3e"))
	kit.materials["wake"] = kit.glow(Color("ffffff"), 0.22)
	foam = kit.glow(Color("ffffff"), 0.5)
	kit.materials["foam"] = foam


# --- Geometry helpers --------------------------------------------------------------------

func _batch_for(at: Vector3) -> Batch:
	return near if at.distance_to(Vector3(0, 0, -104)) < SHADOW_RANGE else far


func _box(look: String, size: Vector3, at: Vector3, rotation_euler: Vector3 = Vector3.ZERO, batch: Batch = null) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	(batch if batch != null else _batch_for(at)).add(look, shape, Transform3D(Basis.from_euler(rotation_euler), at))


func _cylinder(look: String, radius: float, height: float, at: Vector3, top: float = -1.0, rotation_euler: Vector3 = Vector3.ZERO, batch: Batch = null, sides: int = 10) -> void:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top < 0 else top
	shape.height = height
	shape.radial_segments = sides
	shape.rings = 1
	(batch if batch != null else _batch_for(at)).add(look, shape, Transform3D(Basis.from_euler(rotation_euler), at))


func _ball(look: String, radius: float, at: Vector3, squash: float = 1.0, batch: Batch = null) -> void:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0 * squash
	shape.radial_segments = 10
	shape.rings = 5
	(batch if batch != null else _batch_for(at)).add(look, shape, Transform3D(Basis.IDENTITY, at))


## A thin square spar from `a` to `b` (rigging, jibs, stays).
func _spar(look: String, a: Vector3, b: Vector3, thickness: float, batch: Batch = null) -> void:
	var direction: Vector3 = b - a
	var up: Vector3 = Vector3.UP if absf(direction.normalized().y) < 0.98 else Vector3.RIGHT
	var shape := BoxMesh.new()
	shape.size = Vector3(thickness, thickness, direction.length())
	(batch if batch != null else _batch_for(a)).add(look, shape, Transform3D(Basis.looking_at(direction, up), (a + b) / 2.0))


## A level beam from `a` to `b` with the given cross-section (lock gates, jetty rails).
func _beam(look: String, a: Vector3, b: Vector3, width: float, height: float, batch: Batch = null) -> void:
	var direction: Vector3 = b - a
	_box(look, Vector3(direction.length(), height, width), (a + b) / 2.0, Vector3(0, atan2(-direction.z, direction.x), 0), batch)


## A house standing on `ground` (centre of its footprint): body, gabled roof, windows on the
## faces named in `faces` ("+z", "-z", "+x", "-x"), and sometimes a chimney.
func _house(ground: Vector3, size: Vector3, faces: Array[String], ridge_along_x: bool, look: String = "", roof: String = "") -> void:
	if look.is_empty():
		look = HOUSE_LOOKS[rng.randi() % HOUSE_LOOKS.size()]
	if roof.is_empty():
		roof = ROOF_LOOKS[rng.randi() % ROOF_LOOKS.size()]
	var top: float = ground.y + size.y
	_box(look, size, ground + Vector3(0, size.y / 2.0, 0))
	var span: float = size.z if ridge_along_x else size.x
	var length: float = size.x if ridge_along_x else size.z
	var slab := Vector3(length + 0.5, 0.22, span * 0.74) if ridge_along_x else Vector3(span * 0.74, 0.22, length + 0.5)
	for side: float in [-1.0, 1.0]:
		var offset := Vector3(0, top + span / 4.0, side * span / 4.0) if ridge_along_x else Vector3(side * span / 4.0, top + span / 4.0, 0)
		var tilt := Vector3(side * PI / 4.0, 0, 0) if ridge_along_x else Vector3(0, 0, -side * PI / 4.0)
		_box(roof, slab, Vector3(ground.x, 0, ground.z) + offset, tilt)
	var gable: float = span * 0.7071
	if ridge_along_x:
		_box(look, Vector3(length - 0.06, gable, gable), Vector3(ground.x, top, ground.z), Vector3(PI / 4.0, 0, 0))
	else:
		_box(look, Vector3(gable, gable, length - 0.06), Vector3(ground.x, top, ground.z), Vector3(0, 0, PI / 4.0))
	for face: String in faces:
		var along_x: bool = face.ends_with("z")
		var sign_value: float = -1.0 if face.begins_with("-") else 1.0
		var width: float = size.x if along_x else size.z
		var count: int = maxi(1, int(width / 2.4))
		var y: float = 2.0
		while y < size.y - 0.8:
			for index: int in range(count):
				var along: float = -width / 2.0 + (index + 0.5) * width / count
				var at: Vector3 = ground + (Vector3(along, y, sign_value * (size.z / 2.0 + 0.03)) if along_x else Vector3(sign_value * (size.x / 2.0 + 0.03), y, along))
				var pane := Vector3(0.75, 1.0, 0.08) if along_x else Vector3(0.08, 1.0, 0.75)
				_box("window" if rng.randf() < 0.3 else "black", pane, at)
			y += 2.6
	if rng.randf() < 0.55:
		_box("brick", Vector3(0.7, 2.0, 0.7), Vector3(ground.x + size.x * 0.25, top + span * 0.3, ground.z + size.z * 0.2))


## A row of houses along X between `x_from` and `x_to`, fronts facing `front` ("+z"/"-z").
func _row_x(x_from: float, x_to: float, z: float, depth: float, heights: Vector2, front: String, skip: Array = []) -> void:
	var x: float = minf(x_from, x_to)
	var end: float = maxf(x_from, x_to)
	while x < end:
		var width: float = rng.randf_range(5.0, 8.5)
		var center: float = x + width / 2.0
		var skipped: bool = false
		for gap: Vector2 in skip:
			if center > gap.x and center < gap.y:
				skipped = true
		if not skipped:
			_house(Vector3(center, 0, z + rng.randf_range(-0.6, 0.6)), Vector3(width - 0.2, rng.randf_range(heights.x, heights.y), depth), [front], rng.randf() < 0.5)
		x += width


## A row of houses along Z, fronts facing `front` ("+x"/"-x").
func _row_z(x: float, z_from: float, z_to: float, depth: float, heights: Vector2, faces: Array[String]) -> void:
	var z: float = maxf(z_from, z_to)
	var end: float = minf(z_from, z_to)
	while z > end:
		var width: float = rng.randf_range(5.0, 8.0)
		_house(Vector3(x + rng.randf_range(-0.5, 0.5), 0, z - width / 2.0), Vector3(depth, rng.randf_range(heights.x, heights.y), width - 0.2), faces, false)
		z -= width


func _spire(at: Vector3, tower: Vector3, spire: float, look: String = "whitestone") -> void:
	_box(look, tower, at + Vector3(0, tower.y / 2.0, 0))
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			_box(look, Vector3(0.9, 1.6, 0.9), at + Vector3(x * tower.x / 2.0, tower.y + 0.8, z * tower.z / 2.0))
	_cylinder("roof_slate", tower.x * 0.48, spire, at + Vector3(0, tower.y + spire / 2.0, 0), 0.0, Vector3.ZERO, null, 8)
	_box("gold", Vector3(0.2, 1.6, 0.2), at + Vector3(0, tower.y + spire + 0.8, 0))
	for y: float in [tower.y * 0.55, tower.y * 0.8]:
		_box("black", Vector3(tower.x * 0.3, 2.2, tower.z + 0.1), at + Vector3(0, y, 0))


func _tree(at: Vector3, size: float) -> void:
	_cylinder("timber", 0.25 * size, 3.0 * size, at + Vector3(0, 1.5 * size, 0))
	_ball("leaf", 2.2 * size, at + Vector3(0, 3.8 * size, 0), 0.9)
	_ball("leaf", 1.6 * size, at + Vector3(0.9 * size, 5.0 * size, 0.4 * size), 0.9)


# --- The river and its banks --------------------------------------------------------------

func _water_and_banks() -> void:
	_box("water", Vector3(440, 0.2, 52), Vector3(-130, WATER_Y - 0.1, -104))
	_box("water", Vector3(260, 0.2, 52), Vector3(220, UPSTREAM_Y - 0.1, -104))
	for z: float in [NEAR_FACE + 1.0, FAR_FACE - 1.0]:
		_box("stone", Vector3(700, 4.6, 2.0), Vector3(0, -2.3, z))
		# Coping stones along the quay edge, left and right of the bridge.
		for side: float in [-1.0, 1.0]:
			_box("whitestone", Vector3(345, 0.25, 2.3), Vector3(side * 177.5, 0.05, z))
	for side: float in [-1.0, 1.0]:
		_box("stone", Vector3(340.7, 0.4, 70), Vector3(side * 179.65, -0.2, -45))
		_box("cobble", Vector3(340.7, 0.02, 12), Vector3(side * 179.65, 0.01, -75))
	_box("stone", Vector3(700, 0.4, 220), Vector3(0, -0.2, -237))
	_box("cobble", Vector3(700, 0.02, 8), Vector3(0, 0.01, -131))


## The houses around the street, so the thin facades have bodies and roofs behind them.
func _near_bank() -> void:
	for side: float in [-1.0, 1.0]:
		_box("plaster_warm", Vector3(4.2, 5.6, 50), Vector3(side * 11.7, 2.8, -55))
		_box("plaster_warm", Vector3(3.6, 5.6, 32), Vector3(side * 7.3, 2.8, -14.5))
		var faces: Array[String] = ["+x" if side < 0 else "-x", "-z"]
		_row_z(side * 18.5, -30.0, -79.0, 9.0, Vector2(10.0, 15.0), faces)
		_row_z(side * 13.5, 2.0, -30.0, 8.0, Vector2(9.0, 13.0), faces)
		_row_z(side * 27.0, -8.0, -60.0, 8.0, Vector2(11.0, 17.0), faces)
		_row_x(side * 12.0, side * 200.0, -6.0, 10.0, Vector2(9.0, 16.0), "-z")
	# Merchants' houses whose windows look straight over the water.
	_row_x(-34.0, -23.0, -74.5, 10.0, Vector2(10.0, 14.0), "-z")
	_row_x(23.0, 44.0, -74.5, 10.0, Vector2(10.0, 14.0), "-z")
	_spire(Vector3(-38, 0, -44), Vector3(6, 20, 6), 16)
	_spire(Vector3(54, 0, -58), Vector3(5, 15, 5), 12, "brick")
	_house(Vector3(54, 0, -69), Vector3(9, 8, 12), ["-z", "-x"], false, "whitestone", "roof_slate")
	_spire(Vector3(-95, 0, -30), Vector3(7, 26, 7), 22)
	_spire(Vector3(120, 0, -24), Vector3(6, 18, 6), 15)
	# Watermen's stairs down to the river, with wherries waiting for fares.
	for step: int in range(9):
		_box("whitestone", Vector3(3.0, 0.45, 0.9), Vector3(31.0, -0.25 - step * 0.45, NEAR_FACE - 0.4 - step * 0.9))
	for x: float in [29.3, 32.7]:
		_box("stone", Vector3(0.35, 4.4, 8.6), Vector3(x, -2.1, NEAR_FACE - 4.2))
	for spot: Vector3 in [Vector3(27.0, WATER_Y, -85.5), Vector3(35.0, WATER_Y, -86.0)]:
		var boat: Node3D = _wherry(false)
		boat.position = spot
		boat.rotation.y = PI / 2.0 + rng.randf_range(-0.2, 0.2)
		moored.append(boat)


# --- Downstream: the merchant harbour ------------------------------------------------------

func _harbour() -> void:
	var x: float = -36.0
	while x > -136.0:
		var width: float = rng.randf_range(12.0, 16.0)
		var center: float = x - width / 2.0
		var height: float = rng.randf_range(11.0, 16.0)
		# Warehouses stand gable-end to the river, with a hoist beam over their loading doors.
		_house(Vector3(center, 0, -61.0), Vector3(width - 0.6, height, 14.0), ["-z"], false, ["brick", "plaster_warm", "wood", "plaster_ochre"][rng.randi() % 4], "roof_red" if rng.randf() < 0.5 else "roof")
		for y: float in [1.4, 5.0, 8.6]:
			if y < height - 2.0:
				_box("wood", Vector3(2.0, 2.4, 0.12), Vector3(center, y, -68.05))
		_box("timber", Vector3(0.3, 0.3, 2.2), Vector3(center, height + 1.8, -69.0))
		_spar("trim", Vector3(center, height + 1.7, -70.0), Vector3(center, height - 3.5, -70.0), 0.04)
		x -= width
	_row_x(-136.0, -330.0, -62.0, 12.0, Vector2(9.0, 15.0), "-z")
	for jetty_x: float in [-45.0, -75.0, -105.0]:
		_box("wood", Vector3(3.2, 0.3, 15.0), Vector3(jetty_x, -0.35, NEAR_FACE - 7.5))
		for z: int in range(5):
			for side: float in [-1.4, 1.4]:
				_cylinder("timber", 0.18, 4.4, Vector3(jetty_x + side, -2.4, NEAR_FACE - 1.0 - z * 3.4))
		for z: float in [-86.0, -95.0]:
			_cylinder("iron", 0.16, 0.6, Vector3(jetty_x + 1.2, 0.1, z))
		for index: int in range(rng.randi_range(2, 5)):
			var spot := Vector3(jetty_x + rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-84.0, -95.0))
			if rng.randf() < 0.5:
				_cylinder("wood", 0.35, 0.9, spot + Vector3(0, 0.25, 0))
			else:
				_box(["wood", "linen", "trim"][index % 3], Vector3(0.9, 0.8, 0.9), spot + Vector3(0, 0.2, 0), Vector3(0, rng.randf(), 0))
	# Barrels, crates and bales wait on the quay.
	for index: int in range(46):
		var spot := Vector3(rng.randf_range(-138.0, -24.0), 0, rng.randf_range(-79.0, -70.0))
		if rng.randf() < 0.45:
			_cylinder("wood", 0.4, 1.0, spot + Vector3(0, 0.5, 0))
			if rng.randf() < 0.4:
				_cylinder("wood", 0.4, 1.0, spot + Vector3(0, 1.5, 0))
		else:
			var size := Vector3.ONE * rng.randf_range(0.8, 1.4)
			_box(["wood", "linen", "trim", "sail"][index % 4], size, spot + Vector3(0, size.y / 2.0, 0), Vector3(0, rng.randf(), 0))
	for crane_x: float in [-58.0, -92.0, -124.0]:
		cranes.append(_crane(Vector3(crane_x, 0, -78.5)))
	# The harbour mole curls out into the river and ends at a small beacon tower.
	for index: int in range(8):
		var t: float = index / 7.0
		var at := Vector3(-142.0 + t * 16.0, -1.8, NEAR_FACE - 1.0 - t * 21.0)
		_box("stone", Vector3(5.0, 5.0, 4.0), at, Vector3(0, -0.6, 0))
		_box("whitestone", Vector3(5.2, 0.3, 4.2), at + Vector3(0, 2.6, 0), Vector3(0, -0.6, 0))
	var beacon := Vector3(-126.0, 0.8, -104.0)
	_cylinder("whitestone", 1.6, 8.0, beacon + Vector3(0, 4.0, 0), 1.3)
	_box("lit", Vector3(1.6, 1.4, 1.6), beacon + Vector3(0, 8.7, 0))
	_cylinder("roof_red", 1.6, 1.8, beacon + Vector3(0, 10.3, 0), 0.0)
	# Ships tied up at the jetties.
	var docked: Array = [[_galleon(), Vector3(-52.0, WATER_Y, -92.0), PI / 2.0], [_hoy("sail_red"), Vector3(-81.0, WATER_Y, -90.0), PI / 2.0 + 0.05], [_barge(false), Vector3(-99.0, WATER_Y, -89.0), -PI / 2.0], [_barge(true), Vector3(-111.0, WATER_Y, -90.0), PI / 2.0], [_wherry(false), Vector3(-66.0, WATER_Y, -84.5), 0.1]]
	for entry: Array in docked:
		var ship: Node3D = entry[0]
		ship.position = entry[1]
		ship.rotation.y = entry[2]
		moored.append(ship)


func _crane(foot: Vector3) -> Node3D:
	# A treadwheel crane: timber house, wheel, and a jib that slowly swings cargo ashore.
	var fixed := Batch.new()
	var crane := Node3D.new()
	crane.position = foot
	add_child(crane)
	_box("wood", Vector3(4.0, 5.0, 4.0), Vector3(0, 2.5, 0), Vector3.ZERO, fixed)
	_cylinder("roof_red", 3.2, 2.6, Vector3(0, 6.3, 0), 0.4, Vector3.ZERO, fixed, 8)
	for x: float in [-2.05, 2.05]:
		_cylinder("timber", 1.9, 0.2, Vector3(x, 2.5, 0), -1.0, Vector3(0, 0, PI / 2.0), fixed, 14)
	var jib := Node3D.new()
	jib.position = Vector3(0, 6.8, 0)
	crane.add_child(jib)
	var arm := Batch.new()
	_spar("timber", Vector3(0, 0, 0), Vector3(0, 3.0, -7.5), 0.45, arm)
	_spar("timber", Vector3(0, 0, 1.0), Vector3(0, 3.0, -7.5), 0.18, arm)
	_spar("trim", Vector3(0, 3.0, -7.5), Vector3(0, -3.2, -7.5), 0.05, arm)
	_box("wood", Vector3(1.3, 1.0, 1.3), Vector3(0, -3.7, -7.5), Vector3.ZERO, arm)
	arm.commit(jib, kit, true)
	fixed.commit(crane, kit, true)
	return jib


# --- Upstream: lock, weir and mill --------------------------------------------------------

func _lock() -> void:
	var chamber := Vector2(66.0, 90.0)
	var island := -90.2
	_box("water", Vector3(chamber.y - chamber.x, 0.2, 7.0), Vector3((chamber.x + chamber.y) / 2.0, LOCK_Y - 0.1, -85.5))
	_box("stone", Vector3(35.0, 4.8, 2.4), Vector3(77.0, -2.2, island))
	_box("whitestone", Vector3(35.2, 0.25, 2.6), Vector3(77.0, 0.25, island))
	# The weir: a stone sill from the island to the far bank, white water spilling over it.
	_box("stone", Vector3(2.4, 1.2, 35.0), Vector3(91.3, UPSTREAM_Y - 0.35, -109.0))
	for index: int in range(7):
		var z: float = -93.8 - index * 5.0
		_box("foam", Vector3(1.6, 0.9, 4.8), Vector3(89.6, WATER_Y + 0.3, z), Vector3(0, 0, 0.5))
		_box("foam", Vector3(4.0, 0.08, 4.8), Vector3(87.0, WATER_Y + 0.03, z))
	# Two pairs of mitre gates, closing upstream, with balance beams over the walls.
	for gate_x: float in [chamber.x, chamber.y]:
		var meet := Vector3(gate_x + 1.3, 0, -86.1)
		for hinge_z: float in [NEAR_FACE, island + 1.2]:
			var hinge := Vector3(gate_x, 0, hinge_z)
			_beam("wood", Vector3(hinge.x, -1.9, hinge.z), Vector3(meet.x, -1.9, meet.z), 0.45, 4.2)
			_beam("timber", Vector3(hinge.x, 0.35, hinge.z), Vector3(meet.x, 0.35, meet.z), 0.5, 0.3)
			var back := Vector3(hinge.x - 5.5, 0.9, hinge.z + (3.4 if hinge_z == NEAR_FACE else -3.4))
			_beam("timber", Vector3(meet.x, 0.9, meet.z), back, 0.35, 0.35)
			_cylinder("timber", 0.12, 1.0, Vector3(hinge.x, 0.9, hinge.z))
			_cylinder("iron", 0.35, 0.9, back + Vector3(0.6, -0.45, 0))
		for rail: float in [-0.25, 0.25]:
			_beam("iron", Vector3(gate_x, 1.3, NEAR_FACE), Vector3(meet.x + rail, 1.3, meet.z), 0.05, 0.05)
	# The lock-keeper's cottage, garden and lamp.
	_house(Vector3(78.0, 0, -71.0), Vector3(8.0, 4.8, 6.0), ["-z", "+x"], true, "brick", "roof_red")
	_box("door_green", Vector3(1.1, 2.1, 0.08), Vector3(76.0, 1.05, -74.05))
	for x: int in range(9):
		_box("wood", Vector3(0.12, 0.9, 0.12), Vector3(72.0 + x * 1.5, 0.45, -77.2))
		_ball("rose" if x % 2 == 0 else "flag_yellow", 0.3, Vector3(72.7 + x * 1.5, 0.35, -76.4))
	_beam("wood", Vector3(72.0, 0.75, -77.2), Vector3(84.0, 0.75, -77.2), 0.08, 0.1)
	_cylinder("iron", 0.08, 3.2, Vector3(86.0, 1.6, -79.5))
	_box("gas", Vector3(0.35, 0.45, 0.35), Vector3(86.0, 3.4, -79.5))
	var waiting: Node3D = _barge(true)
	waiting.position = Vector3(78.0, LOCK_Y, -85.8)
	moored.append(waiting)
	var upstream_boat: Node3D = _hoy("sail")
	upstream_boat.position = Vector3(104.0, UPSTREAM_Y, -87.0)
	upstream_boat.rotation.y = PI
	moored.append(upstream_boat)


func _upstream() -> void:
	for index: int in range(26):
		_tree(Vector3(98.0 + index * 9.0 + rng.randf_range(-2, 2), 0, -77.0 + rng.randf_range(-2, 1)), rng.randf_range(0.9, 1.4))
	_row_x(100.0, 330.0, -60.0, 9.0, Vector2(6.0, 10.0), "-z", [Vector2(118, 142)])
	_row_x(62.0, 98.0, -56.0, 9.0, Vector2(7.0, 11.0), "-z")
	# A water mill, its wheel turning in the upstream current.
	_house(Vector3(130.0, 0, -72.0), Vector3(10.0, 7.0, 8.0), ["-z", "-x"], true, "plaster_cream", "thatch")
	var wheel := Node3D.new()
	wheel.position = Vector3(130.0, -1.4, -83.6)
	add_child(wheel)
	var parts := Batch.new()
	_cylinder("iron", 0.4, 1.8, Vector3.ZERO, -1.0, Vector3(PI / 2.0, 0, 0), parts)
	for index: int in range(12):
		var angle: float = TAU * index / 12.0
		var out := Vector3(cos(angle), sin(angle), 0)
		_box("wood", Vector3(0.18, 1.2, 1.4), out * 3.0, Vector3(0, 0, angle), parts)
		_spar("timber", Vector3(0, 0, 0.6), out * 3.2 + Vector3(0, 0, 0.6), 0.14, parts)
		_spar("timber", Vector3(0, 0, -0.6), out * 3.2 + Vector3(0, 0, -0.6), 0.14, parts)
	parts.commit(wheel, kit, true)
	spinners.append(wheel)
	for side: float in [-1.0, 1.0]:
		_box("stone", Vector3(0.5, 4.5, 3.0), Vector3(130.0 + side * 3.8, -2.0, -83.6))


# --- The far bank --------------------------------------------------------------------------

func _far_bank() -> void:
	var landmarks: Array = [Vector2(-6.5, 6.5), Vector2(24.0, 54.0)]
	_row_x(-330.0, 330.0, -138.0, 9.0, Vector2(8.0, 14.0), "+z", [Vector2(-7.0, 7.0), Vector2(26.0, 50.0), Vector2(126.0, 174.0)])
	_row_x(-330.0, 330.0, -152.0, 12.0, Vector2(12.0, 20.0), "+z", landmarks + [Vector2(-80.0, -40.0), Vector2(128.0, 172.0)])
	_row_x(-330.0, 330.0, -185.0, 14.0, Vector2(10.0, 22.0), "+z", [Vector2(-80.0, -40.0), Vector2(124.0, 176.0)])
	# The bridge's southern gate, with the traitors' heads on their pikes.
	var gate := Vector3(0, 0, -139.5)
	_box("stone", Vector3(14.0, 12.0, 7.0), gate + Vector3(0, 6.0, 0))
	_box("black", Vector3(4.6, 5.4, 0.1), gate + Vector3(0, 2.7, 3.52))
	for x: int in range(7):
		_box("stone", Vector3(1.2, 1.3, 7.2), gate + Vector3(-6.4 + x * 2.13, 12.6, 0))
		_cylinder("timber", 0.05, 3.0, gate + Vector3(-6.0 + x * 2.0, 14.2, 3.2))
		_ball("bone", 0.22, gate + Vector3(-6.0 + x * 2.0, 15.8, 3.2))
	for x: float in [-7.8, 7.8]:
		_cylinder("stone", 2.2, 16.0, gate + Vector3(x, 8.0, 0))
		_cylinder("roof_slate", 2.4, 3.5, gate + Vector3(x, 17.7, 0), 0.0)
	_globe(Vector3(38.0, 0, -153.0))
	_cathedral(Vector3(-60.0, 0, -168.0))
	_keep(Vector3(150.0, 0, -160.0))
	for spot: Vector3 in [Vector3(-150, 0, -200), Vector3(95, 0, -205), Vector3(-20, 0, -230), Vector3(215, 0, -205), Vector3(-240, 0, -165)]:
		_spire(spot, Vector3(5.5, rng.randf_range(16, 24), 5.5), rng.randf_range(12, 20))
	# Barges unloading at the far wharf above the weir.
	for spot: Vector3 in [Vector3(240.0, UPSTREAM_Y, -123.5), Vector3(300.0, UPSTREAM_Y, -123.2)]:
		var barge: Node3D = _barge(rng.randf() < 0.5)
		barge.position = spot
		moored.append(barge)


func _globe(center: Vector3) -> void:
	# The Globe: a many-sided timber playhouse, open to the sky, flying its flag.
	_cylinder("plaster_cream", 10.0, 10.0, center + Vector3(0, 5.0, 0), -1.0, Vector3.ZERO, null, 20)
	for index: int in range(20):
		var angle: float = TAU * index / 20.0
		_box("timber", Vector3(0.3, 10.0, 0.3), center + Vector3(cos(angle) * 10.02, 5.0, sin(angle) * 10.02), Vector3(0, -angle, 0))
	for y: float in [3.4, 6.8]:
		_cylinder("timber", 10.1, 0.25, center + Vector3(0, y, 0), -1.0, Vector3.ZERO, null, 20)
	_cylinder("thatch", 10.6, 2.6, center + Vector3(0, 11.3, 0), 7.2, Vector3.ZERO, null, 20)
	_cylinder("black", 7.0, 0.2, center + Vector3(0, 12.5, 0), -1.0, Vector3.ZERO, null, 20)
	_box("plaster_cream", Vector3(5.0, 4.0, 4.0), center + Vector3(0, 13.0, -7.0))
	_box("thatch", Vector3(5.6, 0.3, 4.6), center + Vector3(0, 15.2, -7.0))
	_cylinder("timber", 0.1, 6.0, center + Vector3(0, 18.0, -7.0))
	_box("flag_red", Vector3(2.4, 1.4, 0.06), center + Vector3(1.25, 20.2, -7.0))


func _cathedral(at: Vector3) -> void:
	_box("whitestone", Vector3(16.0, 18.0, 50.0), at + Vector3(0, 9.0, 0))
	for side: float in [-1.0, 1.0]:
		_box("roof_slate", Vector3(12.0, 0.4, 51.0), at + Vector3(side * 4.2, 22.2, 0), Vector3(0, 0, -side * 0.8))
		for z: int in range(7):
			_box("whitestone", Vector3(1.6, 14.0, 1.6), at + Vector3(side * 8.6, 7.0, -21.0 + z * 7.0))
			_box("black", Vector3(0.1, 7.0, 2.4), at + Vector3(side * 8.02, 10.0, -17.5 + z * 7.0 - 3.5))
	_box("whitestone", Vector3(42.0, 18.0, 13.0), at + Vector3(0, 9.0, 4.0))
	_box("whitestone", Vector3(13.0, 22.0, 13.0), at + Vector3(0, 29.0, 4.0))
	_cylinder("roof_slate", 6.0, 42.0, at + Vector3(0, 61.0, 4.0), 0.0, Vector3.ZERO, null, 8)
	_box("gold", Vector3(0.4, 3.0, 0.4), at + Vector3(0, 83.5, 4.0))
	_cylinder("black", 3.5, 0.1, at + Vector3(0, 12.0, 25.05), -1.0, Vector3(PI / 2.0, 0, 0), null, 16)


func _keep(at: Vector3) -> void:
	# A white fortress keep inside its curtain wall, corner turrets capped in lead.
	_box("whitestone", Vector3(22.0, 24.0, 20.0), at + Vector3(0, 12.0, 0))
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			_cylinder("whitestone", 2.6, 29.0, at + Vector3(x * 11.0, 14.5, z * 10.0))
			_cylinder("roof_slate", 2.8, 4.0, at + Vector3(x * 11.0, 31.0, z * 10.0), 0.0)
			_cylinder("stone", 3.2, 10.0, at + Vector3(x * 22.0, 5.0, z * 20.0))
	for z: float in [-20.0, 20.0]:
		_box("stone", Vector3(44.0, 8.0, 2.0), at + Vector3(0, 4.0, z))
	for x: float in [-22.0, 22.0]:
		_box("stone", Vector3(2.0, 8.0, 40.0), at + Vector3(x, 4.0, 0))
	for index: int in range(10):
		_box("stone", Vector3(1.6, 1.2, 2.2), at + Vector3(-20.0 + index * 4.4, 8.6, 20.0))
		_box("black", Vector3(0.9, 1.6, 0.1), at + Vector3(-9.0 + (index % 4) * 6.0, 8.0 + (index / 4) * 6.0, 10.05))
	_cylinder("timber", 0.12, 8.0, at + Vector3(0, 28.0, 0))
	_box("flag_red", Vector3(3.2, 2.0, 0.06), at + Vector3(1.6, 30.8, 0))


func _horizon() -> void:
	# Green hills close the far view, windmills turning on their crests.
	for spot: Vector3 in [Vector3(-220, -26, -330), Vector3(-40, -30, -350), Vector3(150, -24, -320), Vector3(360, -30, -300), Vector3(-400, -30, -300), Vector3(0, -32, 160), Vector3(-260, -30, 110), Vector3(260, -30, 120)]:
		_ball("hill", 120.0, spot, 0.42)
	for spot: Vector3 in [Vector3(-220, 23.5, -330), Vector3(-40, 19.5, -350), Vector3(150, 25.5, -320)]:
		_cylinder("whitestone", 2.6, 12.0, spot + Vector3(0, 6.0, 0), 1.8)
		_cylinder("roof", 2.2, 3.0, spot + Vector3(0, 13.4, 0), 0.0)
		var sails := Node3D.new()
		sails.position = spot + Vector3(0, 11.0, 2.4)
		add_child(sails)
		var blades := Batch.new()
		for index: int in range(4):
			var angle: float = TAU * index / 4.0
			_box("sail", Vector3(1.6, 9.0, 0.1), Vector3(cos(angle), sin(angle), 0) * 4.6, Vector3(0, 0, angle - PI / 2.0), blades)
		blades.commit(sails, kit, false)
		spinners.append(sails)
	# The river bends out of sight at both ends, between wooded banks.
	for side: float in [-1.0, 1.0]:
		_box("stone", Vector3(40.0, 4.6, 52.0), Vector3(side * 350.0, -2.1, -104.0))
		for index: int in range(10):
			_tree(Vector3(side * rng.randf_range(335.0, 365.0), 0, rng.randf_range(-82.0, -128.0)), rng.randf_range(1.6, 2.4))
		_row_z(side * 345.0, -60.0, -150.0, 10.0, Vector2(8.0, 14.0), ["+x" if side < 0 else "-x"])


# --- Ships -----------------------------------------------------------------------------------

func _traffic() -> void:
	# [ship, centre x, half length of the run, lane z, lane width, speed, water level]
	var runs: Array = [
		[_galleon(), -135.0, 90.0, -120.0, 2.0, 1.6, WATER_Y],
		[_hoy("sail_red"), -95.0, 80.0, -109.5, 1.8, 2.6, WATER_Y],
		[_wherry(true), -28.0, 13.0, -97.0, 1.5, 1.6, WATER_Y],
		[_galleon(), -285.0, 45.0, -120.0, 2.0, 1.2, WATER_Y],
		[_state_barge(), 36.0, 22.0, -101.0, 2.5, 1.7, WATER_Y],
		[_barge(true), 48.0, 30.0, -113.0, 3.0, 1.1, WATER_Y],
		[_wherry(true), 45.0, 32.0, -121.0, 1.5, 2.2, WATER_Y],
		[_hoy("sail"), 165.0, 60.0, -106.0, 4.0, 2.0, UPSTREAM_Y],
		[_wherry(true), 210.0, 70.0, -96.0, 2.0, 1.8, UPSTREAM_Y],
	]
	for index: int in range(runs.size()):
		var run: Array = runs[index]
		var ship: Node3D = run[0]
		sailing.append({"node": ship, "center": run[1], "half": run[2], "lane": run[3], "width": run[4], "rate": float(run[5]) / float(run[2]), "phase": index * 1.7, "water": run[6], "oars": ship.find_children("Oar*", "Node3D", true, false)})
	for swan: int in range(6):
		var bird := Node3D.new()
		add_child(bird)
		var parts := Batch.new()
		_ball("linen", 0.35, Vector3(0, 0.2, 0), 0.6, parts)
		_spar("linen", Vector3(0.25, 0.2, 0), Vector3(0.45, 0.8, 0), 0.08, parts)
		_ball("linen", 0.1, Vector3(0.5, 0.85, 0), 1.0, parts)
		_box("flag_yellow", Vector3(0.14, 0.05, 0.05), Vector3(0.62, 0.84, 0), Vector3.ZERO, parts)
		parts.commit(bird, kit, false)
		var upstream: bool = swan >= 3
		sailing.append({"node": bird, "center": 120.0 if upstream else -20.0, "half": 5.0 + swan, "lane": -88.0 - float(swan % 3), "width": 2.0 + swan * 0.5, "rate": 0.08, "phase": swan * 2.1, "water": UPSTREAM_Y if upstream else WATER_Y, "oars": []})


func _process(delta: float) -> void:
	clock += delta
	for index: int in range(sailing.size()):
		var run: Dictionary = sailing[index]
		run["phase"] = float(run["phase"]) + float(run["rate"]) * delta
		var phase: float = run["phase"]
		var node: Node3D = run["node"]
		var half: float = run["half"]
		var width: float = run["width"]
		node.position = Vector3(float(run["center"]) - half * cos(phase), float(run["water"]) + sin(clock * 1.1 + index) * 0.07, float(run["lane"]) + width * sin(phase))
		var heading: float = atan2(-width * cos(phase), half * sin(phase))
		node.rotation = Vector3(sin(clock * 0.9 + index) * 0.03, heading, sin(clock * 0.7 + index * 2.0) * 0.02)
		for oar: Node3D in run["oars"]:
			var stroke: float = clock * 2.6 + index
			oar.rotation = Vector3(0.25 + sin(stroke) * 0.12, sin(stroke + PI / 2.0) * 0.5 * oar.scale.z, 0)
	for index: int in range(moored.size()):
		var ship: Node3D = moored[index]
		ship.rotation.x = sin(clock * 0.8 + index * 1.3) * 0.025
		ship.rotation.z = sin(clock * 0.6 + index) * 0.015
	for index: int in range(cranes.size()):
		cranes[index].rotation.y = sin(clock * 0.18 + index * 2.0) * 1.1
	for spinner: Node3D in spinners:
		spinner.rotation.z -= delta * 0.45
	if foam != null:
		foam.albedo_color.a = 0.42 + sin(clock * 5.0) * 0.08


func _hull(ship: Batch, length: float, beam: float, depth: float, look: String, pointed: bool) -> void:
	var body_length: float = length - (beam * 0.5 if pointed else 0.0)
	_box(look, Vector3(body_length, depth, beam), Vector3(-length / 2.0 + body_length / 2.0, depth * 0.15, 0), Vector3.ZERO, ship)
	if pointed:
		var side: float = beam * 0.7071
		_box(look, Vector3(side, depth, side), Vector3(length / 2.0 - beam * 0.5, depth * 0.15, 0), Vector3(0, PI / 4.0, 0), ship)
	_box("trim", Vector3(body_length, 0.2, beam + 0.08), Vector3(-length / 2.0 + body_length / 2.0, depth * 0.65, 0), Vector3.ZERO, ship)
	_box("wake", Vector3(length * 0.6, 0.05, beam * 1.3), Vector3(-length * 0.7, 0.03, 0), Vector3.ZERO, ship)


func _ship_node(parts: Batch) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	parts.commit(node, kit, false)
	return node


func _galleon() -> Node3D:
	var parts := Batch.new()
	_hull(parts, 24.0, 6.4, 4.2, "hull", true)
	_box("hull_red", Vector3(6.0, 3.6, 6.2), Vector3(-9.0, 3.6, 0), Vector3.ZERO, parts)
	_box("gold", Vector3(6.1, 0.3, 6.3), Vector3(-9.0, 5.45, 0), Vector3.ZERO, parts)
	_box("hull_red", Vector3(4.0, 2.2, 5.2), Vector3(6.5, 3.0, 0), Vector3.ZERO, parts)
	_spar("hull", Vector3(10.5, 2.2, 0), Vector3(14.0, 3.2, 0), 0.7, parts)
	for x: int in range(7):
		for side: float in [-1.0, 1.0]:
			_box("black", Vector3(0.7, 0.6, 0.08), Vector3(-6.0 + x * 2.2, 1.0, side * 3.23), Vector3.ZERO, parts)
	for z: float in [-1.8, 0.0, 1.8]:
		_box("window", Vector3(0.08, 0.8, 1.0), Vector3(-12.03, 4.2, z), Vector3.ZERO, parts)
	_box("lit", Vector3(0.5, 0.7, 0.5), Vector3(-12.3, 6.2, 0), Vector3.ZERO, parts)
	_spar("timber", Vector3(8.0, 2.5, 0), Vector3(16.0, 6.0, 0), 0.25, parts)
	for mast: Array in [[5.0, 15.0, 5.6], [-1.0, 19.0, 6.6], [-7.0, 12.0, 0.0]]:
		var x: float = mast[0]
		var height: float = mast[1]
		var width: float = mast[2]
		_cylinder("timber", 0.24, height, Vector3(x, 2.0 + height / 2.0, 0), 0.14, Vector3.ZERO, parts)
		_box("flag_red", Vector3(2.4, 0.5, 0.06), Vector3(x - 1.2, 2.0 + height + 0.1, 0), Vector3.ZERO, parts)
		if width > 0.0:
			for level: Array in [[0.36, 0.32], [0.72, 0.24]]:
				var y: float = 2.0 + height * float(level[0])
				var tall: float = height * float(level[1])
				_cylinder("timber", 0.12, width + 1.4, Vector3(x, y + tall / 2.0, 0), -1.0, Vector3(PI / 2.0, 0, 0), parts)
				_box("sail", Vector3(0.18, tall, width), Vector3(x + 0.25, y, 0), Vector3(0, 0, -0.08), parts)
			if x < 0.0:
				_box("flag_red", Vector3(0.1, height * 0.3, 0.7), Vector3(x + 0.37, 2.0 + height * 0.36, 0), Vector3(0, 0, -0.08), parts)
				_box("flag_red", Vector3(0.1, 0.7, width * 0.95), Vector3(x + 0.37, 2.0 + height * 0.36, 0), Vector3(0, 0, -0.08), parts)
		else:
			_box("sail", Vector3(6.5, 5.5, 0.12), Vector3(x - 0.5, 2.0 + height * 0.5, 0), Vector3(0, 0, 0.55), parts)
		for side: float in [-1.0, 1.0]:
			_spar("trim", Vector3(x, 2.0 + height, 0), Vector3(x - 1.5, 2.6, side * 3.2), 0.05, parts)
			_spar("trim", Vector3(x, 2.0 + height, 0), Vector3(x + 1.5, 2.6, side * 3.2), 0.05, parts)
	_spar("trim", Vector3(5.0, 17.0, 0), Vector3(16.0, 6.0, 0), 0.05, parts)
	_spar("trim", Vector3(-1.0, 21.0, 0), Vector3(5.0, 17.0, 0), 0.05, parts)
	return _ship_node(parts)


func _hoy(sail: String) -> Node3D:
	var parts := Batch.new()
	_hull(parts, 13.0, 4.2, 2.6, "hull_green" if sail == "sail" else "hull", true)
	_box("wood", Vector3(3.0, 1.4, 3.2), Vector3(-3.8, 1.8, 0), Vector3.ZERO, parts)
	_box("roof", Vector3(3.4, 0.2, 3.6), Vector3(-3.8, 2.6, 0), Vector3.ZERO, parts)
	_cylinder("timber", 0.18, 11.0, Vector3(1.0, 6.2, 0), 0.1, Vector3.ZERO, parts)
	_box(sail, Vector3(5.5, 7.5, 0.12), Vector3(-1.9, 5.6, 0.2), Vector3(0, 0.2, 0), parts)
	_spar("timber", Vector3(1.0, 2.2, 0), Vector3(-4.6, 2.4, 0.9), 0.14, parts)
	_box(sail, Vector3(3.2, 5.0, 0.1), Vector3(3.4, 5.0, 0), Vector3(0, 0, 0.45), parts)
	_box("flag_blue", Vector3(1.6, 0.4, 0.05), Vector3(0.2, 11.8, 0), Vector3.ZERO, parts)
	_spar("trim", Vector3(1.0, 11.6, 0), Vector3(6.5, 1.4, 0), 0.04, parts)
	_spar("trim", Vector3(1.0, 11.6, 0), Vector3(-6.0, 1.4, 0), 0.04, parts)
	var ship: Node3D = _ship_node(parts)
	_crew(ship, Vector3(-5.6, 1.2, 0), {"costume": "blue", "hat": "cap"})
	return ship


func _barge(sailed: bool) -> Node3D:
	var parts := Batch.new()
	_hull(parts, 15.0, 4.6, 1.8, "hull", false)
	for index: int in range(6):
		var x: float = -5.0 + index * 1.9
		if index % 2 == 0:
			_box(["wood", "linen", "trim"][index % 3], Vector3(1.6, 1.2, 1.8), Vector3(x, 1.4, -0.9), Vector3(0, index * 0.2, 0), parts)
		for z: float in [-1.0, 1.0]:
			if (index + int(z)) % 3 != 0:
				_cylinder("wood", 0.45, 1.1, Vector3(x, 1.35, z), -1.0, Vector3.ZERO, parts)
	if sailed:
		_cylinder("timber", 0.16, 10.0, Vector3(3.0, 5.8, 0), 0.1, Vector3.ZERO, parts)
		_box("sail_red", Vector3(5.0, 6.5, 0.12), Vector3(0.5, 5.8, 0.25), Vector3(0, 0.15, 0.08), parts)
		_spar("timber", Vector3(3.0, 2.0, 0), Vector3(-2.0, 9.0, 0.6), 0.14, parts)
	var ship: Node3D = _ship_node(parts)
	_crew(ship, Vector3(-6.4, 0.9, 0.6), {"costume": "dark", "hat": "cap", "right_arm": Vector3(0.6, 0, 0.2)})
	return ship


func _state_barge() -> Node3D:
	var parts := Batch.new()
	_hull(parts, 14.0, 3.4, 1.6, "hull_red", true)
	_box("gold", Vector3(12.0, 0.25, 3.5), Vector3(-0.8, 1.15, 0), Vector3.ZERO, parts)
	for x: float in [-6.0, -2.4]:
		for z: float in [-1.5, 1.5]:
			_cylinder("gold", 0.08, 2.4, Vector3(x, 2.3, z), -1.0, Vector3.ZERO, parts)
	_box("curtain", Vector3(4.2, 0.35, 3.6), Vector3(-4.2, 3.6, 0), Vector3.ZERO, parts)
	_box("velvet", Vector3(3.4, 1.5, 0.08), Vector3(-4.2, 2.5, -1.6), Vector3.ZERO, parts)
	_spar("gold", Vector3(-7.0, 1.0, 0), Vector3(-8.2, 3.8, 0), 0.12, parts)
	_box("flag_red", Vector3(1.6, 1.0, 0.05), Vector3(-9.0, 3.6, 0), Vector3.ZERO, parts)
	_box("flag_yellow", Vector3(1.2, 0.7, 0.05), Vector3(6.2, 2.6, 0), Vector3.ZERO, parts)
	var ship: Node3D = _ship_node(parts)
	for index: int in range(5):
		for side: float in [-1.0, 1.0]:
			_oar(ship, Vector3(-1.0 + index * 1.4, 1.1, side * 1.7), side, 3.8)
	_crew(ship, Vector3(-4.2, 0.9, 0), {"costume": "velvet", "hat": "crown", "belt": "gold"})
	return ship


func _wherry(rowed: bool) -> Node3D:
	var parts := Batch.new()
	_hull(parts, 6.2, 1.5, 0.9, "wood", true)
	_box("wood", Vector3(0.9, 0.5, 1.4), Vector3(-2.7, 0.7, 0), Vector3(0, 0, 0.25), parts)
	_box("linen", Vector3(1.2, 0.1, 1.2), Vector3(-1.6, 0.55, 0), Vector3.ZERO, parts)
	var ship: Node3D = _ship_node(parts)
	if rowed:
		for side: float in [-1.0, 1.0]:
			_oar(ship, Vector3(0.2, 0.6, side * 0.7), side, 2.8)
		_crew(ship, Vector3(0.6, -0.2, 0), {"costume": ["rose", "blue", "dark"][rng.randi() % 3], "hat": "cap", "lean": 0.3, "left_arm": Vector3(-0.9, 0, 0.3), "right_arm": Vector3(-0.9, 0, -0.3)}, -PI / 2.0)
	return ship


func _oar(ship: Node3D, lock: Vector3, side: float, length: float) -> void:
	var oar := Node3D.new()
	oar.name = "Oar%d" % ship.get_child_count()
	oar.position = lock
	# The sign of the z scale tells _process which way this oar sweeps.
	oar.scale = Vector3(1, 1, side)
	ship.add_child(oar)
	var parts := Batch.new()
	_box("wood", Vector3(0.08, 0.08, length), Vector3(0, 0, length * 0.4), Vector3.ZERO, parts)
	_box("wood", Vector3(0.35, 0.05, 0.7), Vector3(0, 0, length * 0.85), Vector3.ZERO, parts)
	parts.commit(oar, kit, false)


func _crew(ship: Node3D, at: Vector3, look: Dictionary, yaw: float = PI / 2.0) -> void:
	var sailor: Node3D = ActorKit.make(kit, look)
	sailor.position = at
	sailor.rotation.y = yaw
	for body: Node in sailor.find_children("*", "StaticBody3D", true, false):
		body.queue_free()
	for mesh: Node in sailor.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ship.add_child(sailor)
