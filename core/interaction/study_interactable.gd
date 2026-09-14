class_name StudyInteractable
extends StaticBody3D
## A focusable object. `interaction_id` names the behaviour; `index` picks a socket, seat,
## dial, lantern, or lock wheel; `argument` names the note or item it concerns.

@export var interaction_id: String
@export var title_key: String
@export var description_key: String
@export var index: int = -1
@export var argument: String = ""


## Hides the object and removes it from the focus ray and collision.
func set_available(available: bool) -> void:
	visible = available
	collision_layer = 1 if available else 0
