class_name PoliceMap
extends Control
## The constable's street plan of Whitechapel, inked on old paper. The player marks the
## Shadow's stops in order, starting from the Watch Post, then files the report.

signal closed

const CELL := 128.0
const ORIGIN := Vector2(96, 56)
## Grid coordinates of each landmark (column, row), matching RipperStreet.LANDMARKS.
const GRID: Dictionary = {"WATCH": Vector2(1, 0), "YARD": Vector2(0, 0), "PUB": Vector2(2, 0), "CROSS": Vector2(0, 1), "CHAPEL": Vector2(1, 1), "WELL": Vector2(2, 1), "MARKET": Vector2(0, 2), "TANNERY": Vector2(2, 2), "GATE": Vector2(1, 2)}

var run: StudyState
## Co-op companion side: files the report with the host instead of deciding locally.
var remote_report: Callable
var route: Array[String] = []
var status: Label
var canvas: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = ParchmentView.vignette()
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var sheet := PanelContainer.new()
	var paper := StyleBoxTexture.new()
	paper.texture = ParchmentView.paper("letter")
	paper.content_margin_left = 46
	paper.content_margin_right = 46
	paper.content_margin_top = 30
	paper.content_margin_bottom = 26
	sheet.add_theme_stylebox_override("panel", paper)
	center.add_child(sheet)
	var column := StudyTheme.column(4)
	sheet.add_child(column)
	column.add_child(TitlePage.ink("Metropolitan Police · H Division", 15, ParchmentView.INK, true))
	var heading: Label = TitlePage.ink("A Plan of the Streets about the Watch Post", 26, ParchmentView.RUBRIC, true)
	column.add_child(heading)
	canvas = Control.new()
	canvas.custom_minimum_size = Vector2(ORIGIN.x * 2 + CELL * 2 + 40, ORIGIN.y * 2 + CELL * 2)
	canvas.draw.connect(_draw_map)
	column.add_child(canvas)
	var watch_label: Label = TitlePage.ink("Watch Post", 17, Color("2a3a8a"), true)
	watch_label.position = _point("WATCH") + Vector2(-60, -40)
	watch_label.size = Vector2(120, 26)
	canvas.add_child(watch_label)
	var north: Label = TitlePage.ink("N ↑", 15, ParchmentView.INK, true)
	north.position = Vector2(ORIGIN.x + CELL * 2 + 30, 0)
	canvas.add_child(north)
	for key: String in GRID:
		var point: Vector2 = _point(key)
		if key == "WATCH":
			continue
		var pin: Button = TitlePage.entry(tr("LANDMARK_" + key), _pin.bind(key), 17)
		pin.position = point + Vector2(-80, 12)
		pin.size = Vector2(160, 30)
		pin.set_meta("landmark", key)
		canvas.add_child(pin)
	status = TitlePage.ink("", 16, ParchmentView.INK)
	column.add_child(status)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 40)
	column.add_child(actions)
	actions.add_child(TitlePage.entry("Blot out the route", _clear, 19))
	actions.add_child(TitlePage.entry("File the report", _report, 21))
	actions.add_child(TitlePage.entry("Fold the plan", func() -> void: closed.emit(), 19))
	_describe()


func _point(key: String) -> Vector2:
	return ORIGIN + GRID[key] * CELL


func _draw_map() -> void:
	var road := Color("8a7458", 0.55)
	for row: int in range(3):
		canvas.draw_line(ORIGIN + Vector2(-40, row * CELL), ORIGIN + Vector2(CELL * 2 + 40, row * CELL), road, 22.0)
	for column: int in range(3):
		canvas.draw_line(ORIGIN + Vector2(column * CELL, -40), ORIGIN + Vector2(column * CELL, CELL * 2 + 30), road, 22.0)
	for row: int in range(2):
		for column: int in range(2):
			var block := Rect2(ORIGIN + Vector2(column, row) * CELL + Vector2(16, 16), Vector2(CELL - 32, CELL - 32))
			canvas.draw_rect(block, Color(ParchmentView.INK, 0.08))
			for hatch: int in range(0, int(block.size.x), 12):
				canvas.draw_line(block.position + Vector2(hatch, 0), block.position + Vector2(0, hatch), Color(ParchmentView.INK, 0.12), 1.0)
	var watch: Vector2 = _point("WATCH")
	canvas.draw_circle(watch, 9.0, Color("2a3a8a"))
	for key: String in GRID:
		if key != "WATCH":
			canvas.draw_circle(_point(key), 5.0, ParchmentView.INK)
	var previous: Vector2 = watch
	for index: int in range(route.size()):
		var next: Vector2 = _point(route[index])
		canvas.draw_line(previous, next, ParchmentView.RUBRIC, 4.0, true)
		# Numbered wax dots mark the order of the stops.
		canvas.draw_circle(next, 10.0 + index, ParchmentView.RUBRIC)
		previous = next


func _describe(extra: String = "") -> void:
	var needed: int = StudyState.WATCH_ROUTE.size()
	var text: String = "From the Watch Post, mark his %d stops in the order he walked them." % needed
	if not route.is_empty():
		var names: Array[String] = []
		for key: String in route:
			names.append(tr("LANDMARK_" + key))
		text = " → ".join(names)
	status.text = text + ("\n" + extra if not extra.is_empty() else "")


func _pin(key: String) -> void:
	if route.size() >= StudyState.WATCH_ROUTE.size() or (not route.is_empty() and route[-1] == key):
		return
	route.append(key)
	_describe()
	canvas.queue_redraw()


func _clear() -> void:
	route.clear()
	_describe()
	canvas.queue_redraw()


func _report() -> void:
	if remote_report.is_valid():
		remote_report.call(route.duplicate())
		_describe("You hand the plan to the constable.")
		return
	if run.report_watch(route):
		_describe("The constable reads it twice, and unbars the Mourning Gate.")
	elif run.watch_seen.size() < StudyState.WATCH_ROUTE.size():
		_describe("“You’ve not seen him at every stop, sir. I can’t send a guess.”")
	else:
		_describe("“That’s not the road he walked. Look again at your own notes.”")
