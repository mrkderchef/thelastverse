class_name MetropolitanStation
extends ActScene
## A remembered 1863 Metropolitan Railway platform: steam, brick vaults, gas and timber.
var train: Node3D
var gauge_steam: Label3D
var gauge_return: Label3D
var gauge_steam_needle: Node3D
var gauge_return_needle: Node3D
var control_labels: Dictionary = {}
var leak: Node3D
var repair_band: MeshInstance3D
var boarding: StudyInteractable
var feed_wheel: Node3D
var brake_handle: Node3D

func _ready() -> void:
	CelestialArt.environment(self, 0.7)
	kit.box(self, Vector3(6, 0.4, 43), Vector3(0, -0.2, -16), "stone", true)
	kit.box(self, Vector3(4, 0.2, 43), Vector3(5, -0.9, -16), "cobble", true)
	# A physical platform edge keeps the station an observation space, without track falls.
	kit.box(self, Vector3(0.12, 1, 43), Vector3(2.9, 0.5, -16), "iron", true)
	for z: int in range(-36, 5, 2):
		kit.box(self, Vector3(3.6, 0.15, 0.22), Vector3(5, -0.65, z), "wood")
	for x: float in [4.25, 5.75]:
		kit.box(self, Vector3(0.1, 0.15, 43), Vector3(x, -0.5, -16), "iron")
	kit.box(self, Vector3(0.5, 7, 43), Vector3(-3.3, 3.5, -16), "brick", true)
	kit.box(self, Vector3(0.5, 7, 43), Vector3(7.3, 3.5, -16), "brick", true)
	for z: float in [-36, 5]:
		kit.box(self, Vector3(11, 7, 0.4), Vector3(2, 3.5, z), "black", true)
	for z: int in range(-33, 4, 6):
		for index: int in range(12):
			var angle: float = (index + 0.5) * PI / 12
			var rib := kit.box(self, Vector3(1.4, 0.2, 0.35), Vector3(2 + cos(angle) * 5.1, 4 + sin(angle) * 2, z), "iron")
			rib.rotation.z = atan2(2 * cos(angle), -5.1 * sin(angle))
		kit.light(self, Vector3(-1.8, 3.3, z), Color("ffd492"), 1.8, 7)
		kit.box(self, Vector3(0.32, 0.45, 0.32), Vector3(-2.8, 3.4, z), "gas")
	for index: int in range(16):
		var a: float = index * PI / 16.0
		var b: float = (index + 1) * PI / 16.0
		var start := Vector2(2 + cos(a) * 5.25, 4 + sin(a) * 2.15)
		var finish := Vector2(2 + cos(b) * 5.25, 4 + sin(b) * 2.15)
		var midpoint: Vector2 = (start + finish) * 0.5
		var roof := kit.box(self, Vector3(start.distance_to(finish) + 0.06, 0.18, 43), Vector3(midpoint.x, midpoint.y, -16), "brick")
		roof.rotation.z = (finish - start).angle()
	kit.light(self, Vector3(2, 3.7, -19), Color("c1b8a9"), 2.0, 13)
	# Sign on the wall, built as physical station lettering.
	var sign := Node3D.new()
	add_child(sign)
	sign.position = Vector3(-2.99, 2.5, -13)
	sign.rotation.y = PI / 2
	kit.box(sign, Vector3(5.2, 1.3, 0.06), Vector3.ZERO, "linen")
	var title := CelestialArt.inscription(kit, sign, "BAKER STREET\nMETROPOLITAN RAILWAY", Vector3(0, 0, 0.04), 42)
	title.modulate = Color("272a34")
	var history := kit.note(self, "railway_history", Vector3(-2.85, 1.5, -5), Vector2(0.7, 0.8))
	history.rotation.y = PI / 2
	for z: float in [-8.0, -19.0]:
		kit.box(self, Vector3(0.8, 0.15, 2.5), Vector3(-2, 0.5, z), "wood", true)
		kit.box(self, Vector3(0.1, 0.8, 2.5), Vector3(-2.4, 0.95, z), "wood")
		for offset: float in [-0.9, 0.9]:
			kit.box(self, Vector3(0.65, 0.5, 0.12), Vector3(-2, 0.25, z + offset), "iron")
	_train()
	_controls()
	_add_player(Vector3(1, 3, 2), Vector3(3.5, 1.4, -16))

func _train() -> void:
	train = Node3D.new()
	train.name = "DepartureTrain"
	add_child(train)
	kit.box(train, Vector3(2.5, 0.3, 14), Vector3(5, 0.25, -19), "iron")
	for z: float in [-14, -19, -24]:
		for x: float in [3.85, 6.15]:
			kit.cylinder(train, 0.6, 0.15, Vector3(x, -0.1, z), "iron").rotation.z = PI / 2
	kit.box(train, Vector3(2.4, 2.5, 9), Vector3(5, 1.6, -16.5), "wood")
	kit.box(train, Vector3(2.6, 0.25, 9.3), Vector3(5, 2.95, -16.5), "black")
	for z: float in [-13.0, -15, -17, -19]:
		kit.box(train, Vector3(0.04, 1.1, 1.15), Vector3(3.78, 1.95, z), "window")
		kit.box(train, Vector3(0.07, 0.08, 1.25), Vector3(3.75, 1.35, z), "gold")
	var boiler := kit.cylinder(train, 0.95, 4, Vector3(5, 1.2, -24), "black")
	boiler.rotation.x = PI / 2
	kit.cylinder(train, 0.22, 1.8, Vector3(5, 2.1, -25.5), "iron", 0.3)
	# Open cab: the departing camera sits inside real geometry, clear of the boiler.
	kit.box(train, Vector3(2.4, 0.15, 1.7), Vector3(5, 0.55, -21.8), "wood")
	kit.box(train, Vector3(2.6, 0.2, 1.9), Vector3(5, 3.2, -21.8), "black")
	for x: float in [3.85, 6.15]:
		kit.box(train, Vector3(0.12, 2.5, 0.12), Vector3(x, 1.9, -22.6), "iron")
		kit.box(train, Vector3(0.1, 0.8, 1.6), Vector3(x, 1.05, -21.8), "wood")
	for index: int in range(6):
		var steam := kit.sphere(train, 0.4 + index * 0.13, Vector3(5, 3 + index * 0.38, -25.5 + index * 0.23), kit.glow(Color("adb9c4"), 0.06))
		var drift := create_tween().set_loops()
		drift.tween_property(steam, "position:y", steam.position.y + 0.22, 2)
		drift.tween_property(steam, "position:y", steam.position.y, 2)
	kit.light(train, Vector3(3.2, 2, -24), Color("ffbb6a"), 1.5, 6)

func spawn_point() -> Array:
	return [Vector3(0, 0.08, 1.5), 0.0]

func _controls() -> void:
	# A small workshop on the platform; the repair stays attached to the locomotive.
	var board := Node3D.new()
	add_child(board)
	board.position = Vector3(-2.8, 1.6, -23)
	board.rotation.y = PI / 2
	kit.box(board, Vector3(4.8, 2.0, 0.2), Vector3.ZERO, "timber")
	for index: int in range(2):
		var x: float = -1.0 + index * 2.0
		kit.cylinder(board, 0.38, 0.035, Vector3(x, 0.25, 0.13), "linen").rotation.x = PI / 2
		var needle := Node3D.new()
		needle.position = Vector3(x, 0.25, 0.18)
		board.add_child(needle)
		kit.box(needle, Vector3(0.025, 0.3, 0.025), Vector3(0, 0.12, 0), "black")
		var label := CelestialArt.inscription(kit, board, "0", Vector3(x, -0.35, 0.2), 35)
		CelestialArt.inscription(kit, board, "STEAM · III" if index == 0 else "RETURN · I", Vector3(x, 0.85, 0.17), 25)
		if index == 0:
			gauge_steam = label
			gauge_steam_needle = needle
		else:
			gauge_return = label
			gauge_return_needle = needle
	for entry: Array in [["fire", -1.0], ["relief", 1.0]]:
		var knob := kit.interactable(board, "train_control", "TRAIN_" + str(entry[0]).to_upper(), "TRAIN_" + str(entry[0]).to_upper() + "_INSPECT", Vector3(entry[1], -0.75, 0.32), Vector3(0.55, 0.45, 0.4), -1, entry[0])
		kit.cylinder(knob, 0.17, 0.1, Vector3.ZERO, "gold").rotation.x = PI / 2
		control_labels[entry[0]] = CelestialArt.inscription(kit, board, "0", Vector3(entry[1] + 0.42, -0.75, 0.23), 25)
	var feed := kit.interactable(self, "train_control", "TRAIN_FEED", "TRAIN_FEED_INSPECT", Vector3(2.2, 1.1, -18.4), Vector3(0.7, 0.7, 0.7), -1, "feed")
	feed_wheel = Node3D.new()
	feed.add_child(feed_wheel)
	kit.cylinder(feed_wheel, 0.24, 0.04, Vector3.ZERO, "rose").rotation.x = PI / 2
	kit.box(feed_wheel, Vector3(0.35, 0.035, 0.04), Vector3(0, 0, 0.04), "gold")
	control_labels["feed"] = CelestialArt.inscription(kit, feed, "OPEN", Vector3(0, 0.52, 0), 23)
	var repair := kit.interactable(self, "train_control", "TRAIN_UNION", "TRAIN_UNION_INSPECT", Vector3(2.25, 1.2, -24), Vector3(0.7, 0.8, 0.7), -1, "union")
	kit.cylinder(repair, 0.12, 1.1, Vector3.ZERO, "iron").rotation.x = PI / 2
	repair_band = kit.cylinder(repair, 0.16, 0.18, Vector3.ZERO, "gold")
	repair_band.rotation.x = PI / 2
	kit.box(repair, Vector3(0.08, 0.6, 0.08), Vector3(0.15, 0.1, 0.1), "iron").rotation.z = 0.6
	CelestialArt.line(kit, self, Vector3(2.25, 1.2, -24.5), Vector3(3.8, 1.2, -24.5), 0.1, "iron")
	leak = Node3D.new()
	repair.add_child(leak)
	for index: int in range(4):
		kit.sphere(leak, 0.1 + index * 0.045, Vector3(-index * 0.08, index * 0.19, 0.1), kit.glow(Color("cadce2"), 0.18))
	var brake := kit.interactable(self, "train_control", "TRAIN_BRAKE", "TRAIN_BRAKE_INSPECT", Vector3(2.25, 1.2, -21), Vector3(0.6, 0.8, 0.6), -1, "brake")
	brake_handle = Node3D.new()
	brake.add_child(brake_handle)
	kit.box(brake_handle, Vector3(0.08, 0.65, 0.08), Vector3(0, 0.25, 0), "iron")
	kit.sphere(brake_handle, 0.1, Vector3(0, 0.58, 0), "rose")
	control_labels["brake"] = CelestialArt.inscription(kit, brake, "HELD", Vector3(0, 0.85, 0), 23)
	boarding = kit.interactable(self, "train_board", "TRAIN_BOARD", "TRAIN_BOARD_INSPECT", Vector3(1.9, 1.35, -22.25), Vector3(0.65, 0.8, 0.65))
	kit.box(boarding, Vector3(0.45, 0.4, 0.18), Vector3.ZERO, "door_green")
	CelestialArt.inscription(kit, boarding, "DEPART", Vector3(0, 0.35, 0.12), 22)
	var manual := kit.note(self, "train_manual", Vector3(-2.95, 1.5, -17), Vector2(0.7, 0.8))
	manual.rotation.y = PI / 2
	kit.light(self, Vector3(0, 3.4, -22), Color("e5c392"), 2.4, 9)


func apply_state(animate: bool = true) -> void:
	super.apply_state(animate)
	if state == null:
		return
	var pressure: Vector2i = state.celestial.train_gauges()
	gauge_steam.text = str(pressure.x)
	gauge_return.text = str(pressure.y)
	gauge_steam.modulate = Color("a3d9a8") if pressure.x == 3 else Color("ead8a8")
	gauge_return.modulate = Color("a3d9a8") if pressure.y == 1 else Color("ead8a8")
	gauge_steam_needle.rotation.z = 1.1 - pressure.x * 0.37
	gauge_return_needle.rotation.z = 1.1 - pressure.y * 0.7
	control_labels["fire"].text = str(state.celestial.fire)
	control_labels["relief"].text = str(state.celestial.relief)
	control_labels["feed"].text = "OPEN" if state.celestial.feed_open else "SHUT"
	control_labels["brake"].text = "FREE" if state.celestial.brake_released else "HELD"
	feed_wheel.rotation.z = 0 if state.celestial.feed_open else PI / 2
	brake_handle.rotation.z = -0.7 if state.celestial.brake_released else 0.0
	leak.visible = state.celestial.feed_open and not state.celestial.union_repaired
	repair_band.material_override = kit.materials["gold" if state.celestial.union_repaired else "iron"]


func begin_departure() -> Tween:
	player.enabled = false
	player.reset_at(Vector3(5, 0.75, -21.65), 0, 0.08)
	player.reparent(train, true)
	var departure := create_tween()
	departure.tween_property(train, "position:z", -18.0, 6.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return departure
