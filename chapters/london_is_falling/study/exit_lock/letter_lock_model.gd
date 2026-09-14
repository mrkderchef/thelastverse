class_name LetterLockModel
extends Node3D
## A brass four-wheel letter lock bolted to the study door. Local +Z faces the player.

const WHEEL_X: Array[float] = [-0.21, -0.07, 0.07, 0.21]

var letters: Array[Label3D] = []
var shackle: Node3D


func build(kit: PropKit) -> void:
	kit.box(self, Vector3(0.66, 0.3, 0.05), Vector3(0, 0, -0.01), "gold")
	kit.box(self, Vector3(0.6, 0.24, 0.07), Vector3(0, 0, 0.02), "iron")
	shackle = Node3D.new()
	add_child(shackle)
	for x: float in [-0.22, 0.22]:
		kit.cylinder(shackle, 0.022, 0.22, Vector3(x, 0.23, 0.02), "iron")
	kit.box(shackle, Vector3(0.48, 0.045, 0.045), Vector3(0, 0.34, 0.02), "iron")
	for index: int in range(4):
		var x: float = WHEEL_X[index]
		kit.cylinder(self, 0.075, 0.11, Vector3(x, 0, 0.06), "gold").rotation.z = PI / 2
		for ridge: float in [-0.055, 0.055]:
			kit.box(self, Vector3(0.1, 0.008, 0.02), Vector3(x, ridge, 0.13), "iron")
		kit.box(self, Vector3(0.1, 0.09, 0.01), Vector3(x, 0, 0.13), "black")
		var letter := Label3D.new()
		letter.set_meta("diegetic", true)
		letter.font_size = 64
		letter.pixel_size = 0.0013
		letter.modulate = Color("f2d9a0")
		letter.outline_size = 0
		letter.position = Vector3(x, 0, 0.14)
		add_child(letter)
		letters.append(letter)
		kit.interactable(self, "lock_wheel", "LOCK_WHEEL", "LOCK_INSPECT", Vector3(x, 0, 0.1), Vector3(0.13, 0.22, 0.14), index)


func apply(state: StudyState) -> void:
	var text: String = state.lock_text()
	for index: int in range(4):
		letters[index].text = text[index]
	shackle.position.y = 0.12 if state.door_open else 0.0
