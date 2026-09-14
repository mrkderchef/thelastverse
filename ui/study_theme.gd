class_name StudyTheme
extends RefCounted

const INK := Color(0.035, 0.028, 0.035, 0.94)
const PAPER := Color("e9dfcb")
const GOLD := Color("d9a64e")
const MUTED := Color("a39c96")
const BLOOD := Color("a3161c")
## Offset red shadow: a cheap chromatic ghost on every line of text.
const GHOST := Color(0.55, 0.02, 0.04, 0.55)


static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 19
	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", MUTED)
	for type: String in ["Label", "Button"]:
		theme.set_color("font_outline_color", type, Color(0.02, 0.01, 0.02, 0.85))
		theme.set_constant("outline_size", type, 5)
		theme.set_color("font_shadow_color", type, GHOST)
		theme.set_constant("shadow_offset_x", type, 2)
		theme.set_constant("shadow_offset_y", type, 1)
	for type: String in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, panel(Color(0.06, 0.045, 0.05, 0.92), Color("3a2426"), 1, 10))
		theme.set_stylebox("hover", type, panel(Color("2b0d10"), BLOOD, 1, 10))
		theme.set_stylebox("pressed", type, panel(Color("4a0f14"), Color("e0343a"), 1, 10))
		theme.set_stylebox("focus", type, panel(Color(0, 0, 0, 0), Color("e0343a"), 2, 10))
		theme.set_stylebox("disabled", type, panel(Color(0.05, 0.045, 0.05, 0.85), Color("2a2527"), 1, 10))
	theme.set_stylebox("panel", "PanelContainer", panel(INK, Color("4d1a1d"), 1, 28))
	theme.set_stylebox("panel", "PopupMenu", panel(INK, BLOOD, 1, 12))
	theme.set_color("font_color", "PopupMenu", PAPER)
	theme.set_constant("v_separation", "PopupMenu", 12)
	return theme


static func panel(color: Color, border: Color, width: int, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_content_margin_all(margin)
	box.set_corner_radius_all(0)
	return box


static func label(text: String, size: int = 19, color: Color = PAPER, wrap: bool = true) -> Label:
	var control := Label.new()
	control.text = text
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)
	if wrap:
		control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return control


static func heading(text: String, size: int = 40) -> Label:
	var control: Label = label(text, size)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	control.add_theme_font_override("font", font)
	return control


static func button(text: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 46
	control.pressed.connect(callback)
	return control


static func column(gap: int = 14) -> VBoxContainer:
	var control := VBoxContainer.new()
	control.add_theme_constant_override("separation", gap)
	return control
