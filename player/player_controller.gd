class_name StudyPlayer
extends CharacterBody3D

signal focused(target: StudyInteractable)
signal interacted(target: StudyInteractable, inspect_only: bool)

@export var walk_speed: float = 3.0
@export var reach: float = 3.4
@export var sensitivity: float = 0.002
@export var invert_y: bool = false
var enabled: bool = false
var camera: Camera3D
var target: StudyInteractable
var look_delta := Vector2.ZERO


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.7
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.85
	add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.6
	camera.fov = 78
	camera.near = 0.05
	add_child(camera)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look_delta += event.relative
		rotate_y(-event.relative.x * sensitivity)
		var direction: float = 1.0 if invert_y else -1.0
		camera.rotation.x = clampf(camera.rotation.x + event.relative.y * sensitivity * direction, -1.35, 1.35)
	if event.is_action_pressed("interact") or event.is_action_pressed("inspect"):
		_update_target()
		if is_instance_valid(target):
			interacted.emit(target, event.is_action_pressed("inspect"))
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not enabled:
		velocity = Vector3.ZERO
		return
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = transform.basis * Vector3(input_vector.x, 0, input_vector.y)
	velocity.x = move_toward(velocity.x, direction.x * walk_speed, 18.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * walk_speed, 18.0 * delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0
	move_and_slide()
	_update_target()


func _update_target() -> void:
	var start: Vector3 = camera.global_position
	# Layer 1 is the world; layer 5 holds loose objects that can be picked up.
	var query := PhysicsRayQueryParameters3D.create(start, start - camera.global_basis.z * reach, 1 | 16)
	query.exclude = [get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var next_target: StudyInteractable = hit.get("collider") as StudyInteractable
	if next_target != target:
		target = next_target
		focused.emit(target)


## Mouse motion since the last call, for screen effects.
func consume_look() -> Vector2:
	var result: Vector2 = look_delta
	look_delta = Vector2.ZERO
	return result


func reset_at(position_value: Vector3, yaw: float = 0.0, pitch: float = -0.14) -> void:
	position = position_value
	rotation = Vector3(0, yaw, 0)
	camera.rotation = Vector3(pitch, 0, 0)
	velocity = Vector3.ZERO
	target = null
	focused.emit(null)
