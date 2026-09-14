class_name CompanionAvatar
extends Node3D
## The other player in a co-op run: a travelling reader in a dark coat and wide hat, carrying a
## small lantern, gliding smoothly toward the pose sent over the network.

var figure: Node3D
var head: Node3D
var hand: Node3D
var held_key: String = ""
var target_position := Vector3.ZERO
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var placed: bool = false


static func make(kit: PropKit) -> CompanionAvatar:
	var avatar := CompanionAvatar.new()
	avatar.name = "Companion"
	avatar.figure = ActorKit.make(kit, {"costume": "blue", "cape": "velvet", "legs": "black", "hat": "cap", "mask": "plain", "right_arm": Vector3(0.5, 0, 0.15)})
	for body: Node in avatar.figure.find_children("*", "CollisionObject3D", true, false):
		(body as CollisionObject3D).collision_layer = 0
		(body as CollisionObject3D).collision_mask = 0
	avatar.figure.rotation.y = PI
	avatar.add_child(avatar.figure)
	avatar.head = avatar.figure.find_child("Head", true, false) as Node3D
	avatar.hand = ActorKit.hand_of(avatar.figure)
	var lantern := Node3D.new()
	lantern.position = Vector3(-0.32, 0.95, 0.12)
	avatar.add_child(lantern)
	kit.box(lantern, Vector3(0.12, 0.16, 0.12), Vector3.ZERO, "lit")
	kit.box(lantern, Vector3(0.14, 0.02, 0.14), Vector3(0, 0.09, 0), "iron")
	kit.light(lantern, Vector3.ZERO, Color("ffc98a"), 0.9, 3.5)
	return avatar


func set_pose(at: Vector3, yaw: float, pitch: float) -> void:
	target_position = at
	target_yaw = yaw
	target_pitch = pitch
	if not placed:
		placed = true
		global_position = at
		rotation.y = yaw


## Shows the team's puzzle piece in the companion's hand while they carry it.
func show_piece(room: ActScene, station: String, piece: int) -> void:
	var key: String = "" if station.is_empty() else "%s:%d" % [station, piece]
	if key == held_key:
		return
	held_key = key
	for child: Node in hand.get_children():
		if child.has_meta("carried"):
			child.queue_free()
	if key.is_empty():
		return
	var model: Node3D = room.make_held_piece(station, piece)
	if model != null:
		model.set_meta("carried", true)
		model.scale *= 0.7
		hand.add_child(model)


func _process(delta: float) -> void:
	if not placed:
		return
	var weight: float = minf(delta * 10.0, 1.0)
	global_position = global_position.lerp(target_position, weight)
	rotation.y = lerp_angle(rotation.y, target_yaw, weight)
	if head != null:
		head.rotation.x = lerpf(head.rotation.x, -target_pitch * 0.6, weight)
