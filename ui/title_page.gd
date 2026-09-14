class_name TitlePage
extends Control
## The launcher drawn as the title leaf of an old quarto: a deckled vellum page with a
## double ruled border, corner fleurons, and inked entries instead of modern buttons.


## An inked menu entry: plain lettering that reddens and gains a manicule when chosen.
static func entry(text: String, callback: Callable, size: int = 28) -> Button:
	var button := InkEntry.new()
	button.text = text
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", ParchmentView.title_font())
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", ParchmentView.INK)
	for state_name: String in ["font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(state_name, ParchmentView.RUBRIC)
	button.add_theme_color_override("font_disabled_color", Color(ParchmentView.INK, 0.35))
	button.add_theme_constant_override("outline_size", 0)
	button.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	for box_name: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(box_name, StyleBoxEmpty.new())
	button.pressed.connect(callback)
	button.mouse_entered.connect(func() -> void:
		if button.focus_mode != Control.FOCUS_NONE:
			button.grab_focus()
	)
	return button


## Lettering in ink for the page.
static func ink(text: String, size: int, color: Color = ParchmentView.INK, calligraphic: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", ParchmentView.title_font() if calligraphic else ParchmentView.ink_font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(color, 0.15))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("outline_size", 0)
	return label


func _draw() -> void:
	# Drawn around the content, out into the page margin.
	var outer := Rect2(Vector2.ZERO, size).grow(-4.0).grow_individual(34.0, 30.0, 34.0, 26.0)
	var inner := outer.grow(-9.0)
	draw_rect(outer, ParchmentView.RUBRIC, false, 2.5, true)
	draw_rect(inner, Color(ParchmentView.RUBRIC, 0.6), false, 1.0, true)
	for corner: Vector2 in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
		_fleuron(corner + (inner.get_center() - corner).normalized() * 26.0)
	for mid: Vector2 in [Vector2(inner.get_center().x, inner.position.y), Vector2(inner.get_center().x, inner.end.y)]:
		draw_circle(mid, 5.0, ParchmentView.RUBRIC)
		draw_line(mid - Vector2(60, 0), mid - Vector2(12, 0), ParchmentView.RUBRIC, 1.5, true)
		draw_line(mid + Vector2(12, 0), mid + Vector2(60, 0), ParchmentView.RUBRIC, 1.5, true)


func _fleuron(at: Vector2) -> void:
	for index: int in range(4):
		var angle: float = TAU * index / 4.0 + PI / 4.0
		var petal := PackedVector2Array([at, at + Vector2(cos(angle - 0.35), sin(angle - 0.35)) * 12.0, at + Vector2(cos(angle), sin(angle)) * 18.0, at + Vector2(cos(angle + 0.35), sin(angle + 0.35)) * 12.0])
		draw_colored_polygon(petal, ParchmentView.RUBRIC)
	draw_circle(at, 3.5, ParchmentView.GILT)


## A flat inked button; pointing hands appear on either side while it is chosen.
class InkEntry:
	extends Button

	func _ready() -> void:
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		if disabled or not (has_focus() or is_hovered()) or text.length() <= 1:
			return
		var font: Font = get_theme_font("font")
		var font_size: int = get_theme_font_size("font_size")
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline: float = size.y / 2.0 + font_size * 0.32
		for side: float in [-1.0, 1.0]:
			var hand: String = "☞" if side < 0 else "☜"
			var hand_width: float = font.get_string_size(hand, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var x: float = size.x / 2.0 + side * (width / 2.0 + 14.0) - (hand_width if side < 0 else 0.0)
			draw_string(font, Vector2(x, baseline), hand, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ParchmentView.RUBRIC)
