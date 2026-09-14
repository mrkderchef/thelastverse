class_name ParchmentView
extends Control
## A readable prop shown as the object itself, lettered in ink over a candle-dark backdrop.
## Styles: "scroll" (a rolled manuscript belonging to a mechanism), "letter" (a folded,
## sealed note written by a person), "book" (a bound volume, two pages), and "tablet"
## (words cut in stone). The body is verse; its first letter becomes a rubricated capital.

signal closed

const INK := Color("33200f")
const RUBRIC := Color("7d1a12")
const GILT := Color("c89b45")

static var textures: Dictionary = {}

var style: String = "scroll"
var title: String = ""
var body: String = ""
var close_label: String = ""
var close_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = vignette()
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 28)
	add_child(margins)
	var reading := ScrollContainer.new()
	reading.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	reading.follow_focus = true
	margins.add_child(reading)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reading.add_child(center)
	var stack := StudyTheme.column(14)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(stack)
	match style:
		"book": _book(stack)
		"letter": _letter(stack)
		"tablet": _tablet(stack)
		_: _scroll(stack)
	close_button = Button.new()
	close_button.text = close_label + "   ·   ESC"
	close_button.flat = true
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.add_theme_font_override("font", InterfaceTheme.font())
	close_button.add_theme_font_size_override("font_size", 15)
	close_button.custom_minimum_size.y = 34
	close_button.add_theme_color_override("font_color", Color("d9c49a"))
	for state_name: String in ["font_hover_color", "font_focus_color", "font_pressed_color"]:
		close_button.add_theme_color_override(state_name, Color("fff1cf"))
	close_button.add_theme_constant_override("outline_size", 0)
	for box_name: String in ["normal", "hover", "pressed", "focus"]:
		close_button.add_theme_stylebox_override(box_name, StyleBoxEmpty.new())
	close_button.pressed.connect(func() -> void: closed.emit())
	stack.add_child(close_button)
	close_button.grab_focus()
	# A restrained reveal gives the object weight without delaying interaction.
	stack.modulate.a = 0.0
	var reveal := create_tween()
	reveal.tween_property(stack, "modulate:a", 1.0, 0.28)
	reading.set_deferred("scroll_vertical", 0)


static func ink_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Palatino", "Georgia", "serif"])
	return font


## Calligraphic face for titles and capitals; falls back to the body serif.
static func title_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Apple Chancery", "Luminari", "Palatino Linotype", "Palatino", "Georgia", "serif"])
	return font


func _scroll(stack: VBoxContainer) -> void:
	var sheet := _sheet(Vector2(660, 0), "scroll", Vector2(76, 46))
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", -12)
	var top := Roll.new()
	shell.add_child(top)
	shell.add_child(sheet)
	var bottom := Roll.new()
	bottom.bottom = true
	shell.add_child(bottom)
	stack.add_child(shell)
	sheet.add_child(_verse(body.split("\n"), true, 22))


func _letter(stack: VBoxContainer) -> void:
	var sheet := _sheet(Vector2(610, 0), "letter", Vector2(64, 40))
	stack.add_child(sheet)
	sheet.add_child(_verse(body.split("\n"), true, 22))


func _tablet(stack: VBoxContainer) -> void:
	var slab := PanelContainer.new()
	slab.custom_minimum_size = Vector2(660, 0)
	var box := StyleBoxTexture.new()
	box.texture = paper("stone")
	box.set_content_margin_all(52)
	slab.add_theme_stylebox_override("panel", box)
	stack.add_child(slab)
	var column: VBoxContainer = _verse(body.split("\n"), true, 22)
	for label: Node in column.find_children("*", "Label", true, false):
		(label as Label).add_theme_color_override("font_color", Color("e4dccb"))
		(label as Label).add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		(label as Label).add_theme_constant_override("shadow_offset_y", 2)
	slab.add_child(column)


func _book(stack: VBoxContainer) -> void:
	var cover := PanelContainer.new()
	var leather := StyleBoxTexture.new()
	leather.texture = paper("leather")
	leather.set_content_margin_all(18)
	cover.add_theme_stylebox_override("panel", leather)
	stack.add_child(cover)
	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation", 0)
	cover.add_child(spread)
	var lines: PackedStringArray = body.split("\n")
	var half: int = ceili(lines.size() / 2.0)
	for page: int in range(2):
		var sheet := _sheet(Vector2(530, 520), "page_left" if page == 0 else "page_right", Vector2(44, 46))
		spread.add_child(sheet)
		var slice: PackedStringArray = lines.slice(0, half) if page == 0 else lines.slice(half)
		var column: VBoxContainer = _verse(slice, page == 0, 18)
		column.alignment = BoxContainer.ALIGNMENT_BEGIN
		if page == 1:
			# The facing page starts level with the first line of verse, below the heading.
			var level := Control.new()
			level.custom_minimum_size.y = 58
			column.add_child(level)
			column.move_child(level, 0)
		if page == 1:
			column.add_child(_line("❧", 22, RUBRIC))
		sheet.add_child(column)


func _sheet(minimum: Vector2, kind: String, margin: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum
	var box := StyleBoxTexture.new()
	box.texture = paper(kind)
	box.content_margin_left = margin.x
	box.content_margin_right = margin.x
	box.content_margin_top = margin.y
	box.content_margin_bottom = margin.y
	panel.add_theme_stylebox_override("panel", box)
	var frame := DocumentFrame.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(frame)
	return panel


func _verse(lines: PackedStringArray, with_title: bool, size: int) -> VBoxContainer:
	var long_poem: bool = body.split("\n").size() > 9 and style != "book"
	var body_size: int = size - 2 if long_poem else size
	var column := StudyTheme.column(0 if long_poem else 3)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	if with_title:
		var heading: Label = _line(title.left(1).to_upper() + title.substr(1), 25 if style == "book" else (27 if long_poem else 31), RUBRIC)
		heading.add_theme_font_override("font", title_font())
		column.add_child(heading)
		column.add_child(Rule.new())
	if with_title:
		# Breathing room so the raised capital never touches the rule above it.
		var gap := Control.new()
		gap.custom_minimum_size.y = 6
		column.add_child(gap)
	for index: int in range(lines.size()):
		var text: String = lines[index]
		if with_title and index == 0 and text.length() > 1 and text.length() < 58 and text.left(1).is_valid_identifier():
			column.add_child(_capital_line(text, body_size))
			continue
		column.add_child(_line(text, body_size, INK))
	return column


## A line whose first letter is a large red capital.
func _capital_line(text: String, size: int) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 1)
	var capital_size: int = int(size * 1.8)
	var capital: Label = _line(text.left(1), capital_size, RUBRIC)
	capital.add_theme_font_override("font", title_font())
	capital.custom_minimum_size.x = 0
	capital.autowrap_mode = TextServer.AUTOWRAP_OFF
	# Sit the capital on the same baseline as the rest of the line.
	var holder := Control.new()
	var cap_font: Font = title_font()
	var body_font: Font = ink_font()
	var height: float = maxf(body_font.get_height(size), cap_font.get_ascent(capital_size) + body_font.get_descent(size))
	holder.custom_minimum_size = Vector2(cap_font.get_string_size(text.left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, capital_size).x + 2.0, height)
	# The rest of the line sits at the bottom of the row; its baseline is the capital's.
	var baseline: float = height - body_font.get_descent(size)
	capital.position = Vector2(0, baseline - cap_font.get_ascent(capital_size))
	holder.add_child(capital)
	row.add_child(holder)
	var rest: Label = _line(text.substr(1), size, INK)
	rest.custom_minimum_size.x = 0
	rest.autowrap_mode = TextServer.AUTOWRAP_OFF
	rest.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(rest)
	return row


func _line(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 440 if style == "book" else 500
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ink_font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(color, 0.18))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.add_theme_constant_override("outline_size", 0)
	return label


## Plain aged paper, used by other panels such as the police map.
static func parchment() -> ImageTexture:
	return paper("plain")


## Procedural materials: aged paper with fibres, foxing, and burnt deckled edges (alpha),
## book pages with a gutter shadow, tooled leather with a gilt border, and stone.
static func paper(kind: String) -> ImageTexture:
	if textures.has(kind):
		return textures[kind]
	var size: int = 384
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var mottle := FastNoiseLite.new()
	mottle.seed = kind.hash() % 10000
	mottle.frequency = 0.016
	mottle.fractal_octaves = 5
	var fibre := FastNoiseLite.new()
	fibre.seed = 77
	fibre.frequency = 0.09
	var edge_noise := FastNoiseLite.new()
	edge_noise.seed = kind.hash() % 10000 + 3
	edge_noise.frequency = 0.04
	edge_noise.fractal_octaves = 3
	for y: int in range(size):
		for x: int in range(size):
			var u: float = float(x) / size
			var v: float = float(y) / size
			var m: float = mottle.get_noise_2d(x, y) * 0.5 + 0.5
			var colour: Color
			var alpha: float = 1.0
			match kind:
				"leather":
					colour = Color("55200f").lerp(Color("200808"), m * 0.85)
					var inset: float = minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
					if absf(inset - 0.022) < 0.003 or absf(inset - 0.034) < 0.002:
						colour = GILT.darkened(m * 0.35)
				"stone":
					colour = Color("615d57").lerp(Color("2b2926"), m)
					colour = colour.lightened(fibre.get_noise_2d(x * 3.0, y * 3.0) * 0.08)
					var bevel: float = minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
					colour = colour.darkened(clampf(0.04 - bevel, 0.0, 0.04) * 12.0)
				_:
					var light := Color("f3e3ba")
					var dark := Color("b0824a")
					var streak: float = fibre.get_noise_2d(x * 0.4, y * 6.0) * 0.5 + 0.5
					var shade: float = m * 0.2 + streak * 0.06
					var fox: float = smoothstep(0.64, 0.82, mottle.get_noise_2d(x * 3.1 + 900.0, y * 3.1) * 0.5 + 0.5)
					shade += fox * 0.16
					var dist: float = minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
					if kind == "page_left":
						dist = minf(minf(u, v), 1.0 - v)
						shade += pow(u, 10.0) * 0.6
					elif kind == "page_right":
						dist = minf(minf(1.0 - u, v), 1.0 - v)
						shade += pow(1.0 - u, 10.0) * 0.6
					var ragged: float = dist - (edge_noise.get_noise_2d(x, y) * 0.5 + 0.5) * 0.03
					shade += clampf(0.06 - ragged, 0.0, 0.06) * 8.0
					if kind in ["letter", "scroll"]:
						alpha = clampf(ragged * 140.0, 0.0, 1.0)
						if kind == "letter" and (absf(v - 0.5) < 0.003 or absf(u - 0.5) < 0.002):
							shade += 0.1
					colour = light.lerp(dark, clampf(shade, 0.0, 1.0))
			image.set_pixel(x, y, Color(colour, alpha))
	var texture := ImageTexture.create_from_image(image)
	textures[kind] = texture
	return texture


## Soft candle-lit darkness behind the page.
static func vignette() -> Texture2D:
	if textures.has("vignette"):
		return textures["vignette"]
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.1, 0.06, 0.02, 0.5))
	gradient.set_color(1, Color(0.01, 0.005, 0.0, 0.93))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.1, 1.1)
	texture.width = 256
	texture.height = 256
	textures["vignette"] = texture
	return texture


## A turned wooden roller with finials, shaded like a cylinder.
class Roll:
	extends Control
	var bottom: bool = false

	func _init() -> void:
		custom_minimum_size = Vector2(760, 46)

	func _draw() -> void:
		var w: float = size.x
		var bands: int = 12
		for band: int in range(bands):
			var t: float = float(band) / (bands - 1)
			var shade: Color = Color("4a2e16").lerp(Color("c7955a"), sin(t * PI) * 0.9).darkened(0.12 if bottom else 0.0)
			draw_rect(Rect2(40, 6 + band * 34.0 / bands, w - 80, 34.0 / bands + 1), shade)
		for x: float in [18.0, w - 18.0]:
			for ring: int in range(6):
				draw_circle(Vector2(x, 23), 22.0 - ring * 3.2, Color("2e1c0c").lerp(Color("e0b26a"), float(ring) / 5.0))
		draw_line(Vector2(40, 41), Vector2(w - 40, 41), Color(0, 0, 0, 0.3), 3.0)


## A hand-drawn ornamental rule with a central fleuron.
class Rule:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(300, 22)

	func _draw() -> void:
		var mid := Vector2(size.x / 2.0, 11)
		for side: float in [-1.0, 1.0]:
			draw_line(mid + Vector2(side * 16, 0), mid + Vector2(side * 130, 0), ParchmentView.RUBRIC, 1.5, true)
			draw_line(mid + Vector2(side * 30, 4), mid + Vector2(side * 100, 4), Color(ParchmentView.RUBRIC, 0.45), 1.0, true)
			draw_circle(mid + Vector2(side * 136, 0), 2.5, ParchmentView.RUBRIC)
		var points := PackedVector2Array()
		for index: int in range(16):
			var angle: float = TAU * index / 16.0
			points.append(mid + Vector2(cos(angle), sin(angle)) * (7.0 if index % 2 == 0 else 3.0))
		draw_colored_polygon(points, ParchmentView.RUBRIC)


## Fine marginal rules and engraved corner marks, separate from the readable text.
class DocumentFrame:
	extends Control
	func _draw() -> void:
		var bounds := Rect2(Vector2(-27, -22), size + Vector2(54, 44))
		draw_rect(bounds, Color(ParchmentView.RUBRIC, 0.35), false, 1, true)
		for corner: Vector2 in [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]:
			var direction := (bounds.get_center() - corner).sign()
			draw_line(corner + Vector2(direction.x * 6, 0), corner + Vector2(direction.x * 30, 0), ParchmentView.GILT, 2, true)
			draw_line(corner + Vector2(0, direction.y * 6), corner + Vector2(0, direction.y * 22), ParchmentView.GILT, 2, true)
