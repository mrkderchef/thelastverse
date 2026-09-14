class_name SceneSlides
extends Control
## The chapter's scenes behind the title pages: each still slowly drifts and zooms, then
## dissolves into the next, while the name of its act glows in the corner.

const LONDON: Array = [["study", "study"], ["street", "street"], ["bridge", "street"], ["sewer", "sewer"], ["ripper", "ripper"], ["courtyard", "courtyard"], ["nursery", "nursery"], ["metropolitan", "metropolitan"]]
const HOLD := 7.0
const DISSOLVE := 1.8

## Shared across menu pages so turning a page does not restart the slideshow.
static var current: int = 0
static var elapsed: float = 0.0

var front: TextureRect
var back: TextureRect
var act_name: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var ground := ColorRect.new()
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.color = Color.BLACK
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	back = _layer()
	front = _layer()
	var shade := TextureRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.texture = ParchmentView.vignette()
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	act_name = TitlePage.ink("", 30, Color("f3dfb0"), true)
	act_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	act_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	act_name.add_theme_color_override("font_outline_color", Color(0.03, 0.01, 0.0, 0.9))
	act_name.add_theme_constant_override("outline_size", 8)
	act_name.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	act_name.offset_left = -620
	act_name.offset_top = -86
	act_name.offset_right = -48
	act_name.offset_bottom = -40
	act_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(act_name)
	_present(false)


func _layer() -> TextureRect:
	var layer := TextureRect.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	return layer


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed > HOLD:
		elapsed = 0.0
		current = (current + 1) % LONDON.size()
		_present(true)
	for layer: TextureRect in [back, front]:
		layer.pivot_offset = size / 2.0
	# A slow push-in with a sideways drift, alternating direction per scene.
	var t: float = elapsed / HOLD
	var drift: float = -1.0 if current % 2 == 0 else 1.0
	front.scale = Vector2.ONE * (1.06 + 0.07 * t)
	front.position = Vector2(drift * (t - 0.5) * 36.0, 0)
	if front.modulate.a < 1.0:
		front.modulate.a = minf(1.0, front.modulate.a + delta / DISSOLVE)


func _present(dissolve: bool) -> void:
	back.texture = front.texture
	back.scale = front.scale
	back.position = front.position
	var scene: Array = LONDON[current]
	front.texture = load("res://shared/menu/london_%s.jpg" % scene[0])
	front.modulate.a = 0.0 if dissolve else 1.0
	act_name.text = StoryBook.TITLES[scene[1]].replace("\n", "  ·  ")
