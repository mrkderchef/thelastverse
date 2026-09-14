class_name MenuBackdrop
extends Control
## An abstract threshold made from suspended frames; no chapter-specific scenery.
var poster: bool = false
var elapsed: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("090f16"))
	var center := Vector2(size.x * 0.73, size.y * 0.49)
	for i: int in range(45, 0, -1):
		var radius: float = i * size.y * 0.011
		draw_circle(center, radius, Color(0.14, 0.25, 0.3, 0.013))
	for i: int in range(7):
		var shift := Vector2(i * 19, -i * 13)
		var w: float = 240.0 - i * 14
		var h: float = 346.0 - i * 19
		var at: Vector2 = center - Vector2(w, h) / 2 + shift + Vector2(0, sin(elapsed * 0.22 + i * 0.6) * 5)
		var points := PackedVector2Array([at + Vector2(0, 30), at + Vector2(w, 0), at + Vector2(w, h - 24), at + Vector2(0, h), at + Vector2(0, 30)])
		draw_colored_polygon(points.slice(0, 4), Color(0.03, 0.06, 0.085, 0.55))
		draw_polyline(points, Color(0.7, 0.72, 0.65, 0.16 + i * 0.065), 1.2, true)
		if i == 6:
			draw_line(at + Vector2(0, 30), at + Vector2(0, h), InterfaceTheme.ACCENT, 2, true)
	for i: int in range(55):
		var x: float = fmod(i * 137.7 + sin(i * 2.0) * 45, size.x)
		var y: float = fmod(i * 81.3 - elapsed * (2 + i % 3) + 10000, size.y)
		draw_circle(Vector2(x, y), 0.7 if i % 4 else 1.3, Color(0.8, 0.8, 0.68, 0.12 + (i % 4) * 0.06))
	draw_line(Vector2(64, 72), Vector2(size.x - 64, 72), Color("2b353e"), 1)
	draw_line(Vector2(64, size.y - 64), Vector2(size.x - 64, size.y - 64), Color("2b353e"), 1)
	if poster:
		for i: int in range(12):
			draw_line(Vector2(size.x * 0.57 + i * 27, size.y * 0.12), Vector2(size.x * 0.43 + i * 27, size.y * 0.9), Color(0.3, 0.5, 0.57, 0.08), 1, true)
