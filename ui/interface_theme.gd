class_name InterfaceTheme
extends RefCounted
## Shared, era-independent navigation. Physical documents keep their own materials.
const TEXT := Color("ecece6")
const ACCENT := Color("cfb98c")
const MUTED := Color("89949f")
const SURFACE := Color("111820")

static func font(serif: bool = false) -> Font:
	var face := SystemFont.new()
	face.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"] if serif else ["Helvetica Neue", "Segoe UI", "Arial", "sans-serif"])
	return face

static func create() -> Theme:
	var theme := StudyTheme.create()
	theme.default_font = font()
	theme.set_icon("checked", "CheckBox", check_icon(true))
	theme.set_icon("unchecked", "CheckBox", check_icon(false))
	for kind: String in ["Label", "Button", "CheckBox", "OptionButton"]:
		theme.set_color("font_shadow_color", kind, Color.TRANSPARENT)
		theme.set_constant("outline_size", kind, 0)
	for kind: String in ["Button", "OptionButton"]:
		for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			theme.set_stylebox(state, kind, box(Color("1d2832") if state == "hover" else SURFACE, ACCENT if state == "focus" else Color("36424c"), 10))
	return theme

static func check_icon(checked: bool) -> Texture2D:
	var image := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y: int in range(2, 18):
		for x: int in range(2, 18):
			if x in [2, 17] or y in [2, 17]:
				image.set_pixel(x, y, ACCENT if checked else MUTED)
	if checked:
		for i: int in range(9):
			var x: int = 5 + i
			var y: int = 10 + i if i < 3 else 15 - i
			image.set_pixel(x, y, ACCENT)
			image.set_pixel(x, y + 1, ACCENT)
	return ImageTexture.create_from_image(image)

static func box(fill: Color = SURFACE, edge: Color = Color("36424c"), margin: int = 28) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = edge
	result.set_border_width_all(1)
	result.set_content_margin_all(margin)
	result.set_corner_radius_all(3)
	result.shadow_color = Color(0, 0, 0, 0.35)
	result.shadow_size = 18
	return result

static func ink(text: String, size: int = 20, color: Color = TEXT, serif: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", font(serif))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	return label

static func entry(text: String, callback: Callable, size: int = 22) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.add_theme_font_override("font", font())
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", ACCENT)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_constant_override("outline_size", 0)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var fill := Color(1, 1, 1, 0.055) if state in ["hover", "pressed"] else Color.TRANSPARENT
		var style := box(fill, ACCENT if state == "focus" else Color.TRANSPARENT, 7)
		style.shadow_size = 0
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(callback)
	return button

class Rule:
	extends Control
	func _init() -> void:
		custom_minimum_size = Vector2(100, 18)
	func _draw() -> void:
		draw_line(Vector2(0, 9), Vector2(size.x, 9), Color("36424c"), 1)
