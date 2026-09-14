extends Node

const ROOM_SCENE := preload("res://chapters/london_is_falling/study/study.gd")
const STREET_SCENE := preload("res://chapters/london_is_falling/street/london_street.gd")
const SEWER_SCENE := preload("res://chapters/london_is_falling/sewer/plague_sewer.gd")
const COURTYARD_SCENE := preload("res://chapters/london_is_falling/nursery/dyer_courtyard.gd")
const NURSERY_SCENE := preload("res://chapters/london_is_falling/nursery/star_nursery.gd")
const METROPOLITAN_SCENE := preload("res://chapters/london_is_falling/metropolitan/metropolitan_station.gd")
const RIPPER_SCENE := preload("res://chapters/london_is_falling/whitechapel/ripper_street.gd")
const POST_SHADER := preload("res://shared/shaders/cursed_post.gdshader")
## London Bridge loops; see shared/audio/generate_audio.py. While London stands the song is a
## cheerful nursery rhyme (0 melody only, 1 sung). After the bridge falls it turns: 2 broken
## music box, 3 slowed vocals, 4 heartbeat, 5 drums, 6 frantic.
const MUSIC_STAGES: Array[AudioStreamWAV] = [
	preload("res://shared/audio/london_bridge_bright_0.wav"),
	preload("res://shared/audio/london_bridge_bright_1.wav"),
	preload("res://shared/audio/london_bridge_0.wav"),
	preload("res://shared/audio/london_bridge_1.wav"),
	preload("res://shared/audio/london_bridge_2.wav"),
	preload("res://shared/audio/london_bridge_3.wav"),
	preload("res://shared/audio/london_bridge_4.wav"),
]
const MUSIC_FADE := 3.5
## Launcher cards. Only the first chapter exists; the rest are unwritten placeholders.
var chapter_count: int = ChapterCatalog.ENTRIES.size()
const CHAPTER_NUMERALS: Array[String] = ["I", "II", "III"]
const TOKEN_KEYS: Array[String] = ["TOKEN_CRADLE", "TOKEN_SATCHEL", "TOKEN_ROSE", "TOKEN_SWORD", "TOKEN_SCALES", "TOKEN_CANE", "TOKEN_CANDLE"]
const FIGURE_KEYS: Array[String] = ["", "FIGURE_HOST", "FIGURE_COMPANION", "FIGURE_GUEST"]
const PROP_KEYS: Array[String] = ["PROP_ROSE", "PROP_LETTER", "PROP_VIAL", "PROP_SKULL", "PROP_CROWN"]
const INGREDIENT_KEYS: Array[String] = ["INGREDIENT_EYE", "INGREDIENT_TOE", "INGREDIENT_WOOL", "INGREDIENT_TONGUE", "INGREDIENT_FEATHER", "INGREDIENT_MANDRAKE"]
## Interactables that carry pieces, mapped to their slot station.
## How each readable prop is presented.
const NOTE_STYLES: Dictionary = {"note": "letter", "booklet": "book", "card": "letter", "sheet": "scroll", "diagram": "scroll", "page_bed": "letter", "page_cues": "scroll", "page_costumes": "letter", "page_window": "letter", "playbill": "scroll", "incantation": "scroll", "tender_note": "letter", "soothsayer": "scroll", "almanac": "book", "warrant": "letter", "plague_bill": "scroll", "shadow_letter": "letter", "confession": "book", "witch_scrap_0": "scroll", "witch_scrap_1": "scroll", "witch_scrap_2": "scroll"}
const SLOT_STATIONS: Dictionary = {"ages_socket": "ages", "banquet_seat": "macbeth", "prop_slot": "props", "shelf_jar": "shelf"}

enum Screen { MENU, EXPLORE, NOTE, JOURNAL, PAUSE, SETTINGS, END }

var room: ActScene
var state: StudyState
var store := SaveStore.new()
var settings := StudySettings.new()
var has_run: bool = false
var screen: Screen = Screen.MENU
var journal_return: Screen = Screen.EXPLORE
var settings_return: Screen = Screen.MENU
var root_ui: Control
var overlay: Control
var hud: Control
var prompt: Label
var caption: Label
var caption_tween: Tween
var holding: Label
var objective: Label
var chapter_label: Label
var fader: ColorRect
var letters: Label
var save_status: Label
var music_player: AudioStreamPlayer
var fading_player: AudioStreamPlayer
var music_stage: int = -1
var music_tween: Tween
var post: ShaderMaterial
var smear := Vector2.ZERO
var effect_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var bridge_falling: bool = false
## While the fair lady comes for the player, the camera will not look away from her.
var watching_lady: bool = false
var last_save_ok: bool = true
var is_quitting: bool = false
var knock_count: int = 0
var launcher_index: int = 0
var browsing: bool = false
## Which page of the title menu is open: "title", "chapters", "hints" or "restart".
var menu_page: String = "title"
var narrator: AudioStreamPlayer
var announced_act: String = ""
var verse_serial: int = 0
var act_card: Control
var net: NetSession
## While the host performs a companion's interaction, the id of that companion; -1 marks an
## interaction the companion handles on its own side; 0 is a normal local interaction.
var acting_peer: int = 0
## A host state that arrived during a cinematic, applied once it ends.
var pending_state: Dictionary = {}
var coop_status: String = ""


func _ready() -> void:
	TranslationServer.set_locale("en")
	get_tree().auto_accept_quit = false
	net = NetSession.new()
	net.name = "Net"
	net.game = self
	add_child(net)
	net.companion_joined.connect(_on_companion_joined)
	net.companion_left.connect(_on_companion_left)
	net.connected_to_host.connect(func() -> void:
		coop_status = tr("COOP_CONNECTED")
		if menu_page == "join":
			_show_join()
	)
	net.connection_failed.connect(func() -> void:
		coop_status = tr("COOP_FAILED")
		if menu_page == "join":
			_show_join()
	)
	settings.load_settings()
	_build_audio()
	_build_ui()
	var loaded: StudyState = store.load_run()
	has_run = loaded != null
	_adopt(loaded if loaded != null else StudyState.new())
	_show_menu()
	if not store.message_key.is_empty():
		save_status.text = tr(store.message_key)


func _adopt(next: StudyState) -> void:
	if state != null:
		state.changed.disconnect(_state_changed)
		state.solved.disconnect(_on_solved)
	state = next
	state.changed.connect(_state_changed)
	state.solved.connect(_on_solved)
	_load_act(state.act())
	_update_mood()


## Builds the scene for an act ("study", "street", "sewer", "ripper"), replacing the last.
func _load_act(act: String) -> void:
	if room != null:
		remove_child(room)
		room.queue_free()
	match act:
		"street": room = STREET_SCENE.new()
		"sewer": room = SEWER_SCENE.new()
		"ripper": room = RIPPER_SCENE.new()
		"courtyard": room = COURTYARD_SCENE.new()
		"nursery": room = NURSERY_SCENE.new()
		"metropolitan": room = METROPOLITAN_SCENE.new()
		_: room = ROOM_SCENE.new()
	room.name = act.capitalize()
	if room is DyerCourtyard:
		(room as DyerCourtyard).bell_sounded.connect(_house_bell_sound)
	if room is RipperStreet:
		(room as RipperStreet).shadow_seen.connect(_on_shadow_seen)
	add_child(room)
	move_child(room, 0)
	room.player.focused.connect(_on_focus)
	room.player.interacted.connect(_interact)
	room.crossed_threshold.connect(_on_threshold)
	room.follower = net.is_client()
	room.ask = func(action: String, arguments: Array) -> void: net.request(action, arguments)
	room.hand_owned = net.holds_locally()
	room.narrate.connect(func(key: String) -> void: _caption(tr(key)))
	settings.apply(room.player)
	room.set_world_volume(settings.music)
	room.restore(state)


## Each act opens like a scene: the screen dims behind letterbox bars, the act number and
## title glow in gold, and the narrator speaks the act's verse, line by line.
func _announce_act() -> void:
	var act: String = state.act()
	if act == announced_act:
		return
	announced_act = act
	if is_instance_valid(act_card):
		act_card.queue_free()
	act_card = Control.new()
	act_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	act_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(act_card)
	hud.move_child(caption, -1)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	act_card.add_child(dim)
	for top: bool in [true, false]:
		var bar := ColorRect.new()
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.custom_minimum_size.y = 84
		bar.offset_top = 0 if top else -84
		bar.offset_bottom = 84 if top else 0
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		act_card.add_child(bar)
	var column := StudyTheme.column(2)
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.offset_left = -560
	column.offset_right = 560
	column.offset_top = -150
	column.offset_bottom = 90
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	act_card.add_child(column)
	var parts: PackedStringArray = StoryBook.TITLES[act].split("\n")
	var number: Label = InterfaceTheme.ink(parts[0], 30, Color("e3c07a"))
	number.add_theme_constant_override("outline_size", 0)
	number.add_theme_color_override("font_shadow_color", Color("ffb050", 0.6))
	number.add_theme_constant_override("shadow_outline_size", 4)
	column.add_child(number)
	var rule := InterfaceTheme.Rule.new()
	rule.modulate = Color(3.0, 2.2, 1.2)
	column.add_child(rule)
	var name_label: Label = InterfaceTheme.ink(parts[1], 56, Color("f5e2b3"), true)
	name_label.add_theme_color_override("font_shadow_color", Color("ff9a3a", 0.2))
	name_label.add_theme_constant_override("shadow_outline_size", 7)
	column.add_child(name_label)
	act_card.modulate.a = 0.0
	var reveal := create_tween()
	reveal.tween_property(act_card, "modulate:a", 1.0, 1.2)
	reveal.parallel().tween_property(column, "scale", Vector2.ONE, 4.2).from(Vector2.ONE * 0.94)
	reveal.tween_interval(0.6)
	reveal.tween_property(dim, "color:a", 0.0, 1.2)
	reveal.parallel().tween_property(column, "modulate:a", 0.0, 1.6)
	reveal.tween_property(act_card, "modulate:a", 0.0, 0.8)
	column.pivot_offset = Vector2(560, 120)
	var verse: String = StoryBook.VOICES[act]
	var length: float = 3.6 * verse.split("\n").size()
	if narrator != null:
		narrator.stream = load("res://shared/audio/narrator/" + act + ".wav")
		narrator.volume_db = linear_to_db(maxf(settings.effects * 1.6, 0.0001))
		narrator.play()
		length = narrator.stream.get_length()
	_caption_verse(verse, length, act)


## Follow the recorded line starts, including pauses and paused playback.
func _caption_verse(verse: String, duration: float, act: String = "") -> void:
	var lines: PackedStringArray = verse.split("\n")
	var starts: Array = preload("res://shared/audio/narrator/narration_cues.gd").STARTS.get(act, [])
	verse_serial += 1
	var serial: int = verse_serial
	if starts.size() == lines.size() and narrator != null:
		var next_line: int = 0
		while serial == verse_serial and is_instance_valid(narrator):
			if narrator.stream_paused:
				await get_tree().process_frame
				continue
			if not narrator.playing:
				return
			var position: float = narrator.get_playback_position()
			if position >= float(starts[next_line]):
				var end: float = float(starts[next_line + 1]) if next_line + 1 < starts.size() else duration
				_caption(lines[next_line], maxf(end - position, 0.1))
				next_line += 1
				if next_line == lines.size():
					return
			await get_tree().process_frame
		return
	# Fallback for callers without a generated recording.
	var total: int = 0
	for line: String in lines:
		total += line.length() + 12
	await get_tree().create_timer(1.2, true).timeout
	for line: String in lines:
		if serial != verse_serial:
			return
		_caption(line, duration * float(line.length() + 12) / total + 0.6)
		await get_tree().create_timer(maxf(duration * float(line.length() + 12) / total, 1.0), true).timeout


func _show_story(page: int = -1) -> void:
	_switch(Screen.NOTE)
	var book := StoryBook.new()
	book.run = state
	book.page = StoryBook.ACTS.find(state.act()) if page < 0 else page
	book.closed.connect(_explore)
	overlay.add_child(book)


func _show_police_map() -> void:
	if acting_peer > 0:
		net.tell(acting_peer, "map", [])
		return
	_switch(Screen.NOTE)
	var map := PoliceMap.new()
	map.run = state
	if net.is_client():
		map.remote_report = func(route: Array[String]) -> void: net.request("report_watch", [route])
	map.closed.connect(_explore)
	overlay.add_child(map)


func _build_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for stream: AudioStreamWAV in MUSIC_STAGES:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	music_player = AudioStreamPlayer.new()
	fading_player = AudioStreamPlayer.new()
	add_child(music_player)
	add_child(fading_player)
	effect_player = AudioStreamPlayer.new()
	add_child(effect_player)
	voice_player = AudioStreamPlayer.new()
	voice_player.stream = preload("res://shared/audio/fair_lady.wav")
	add_child(voice_player)
	narrator = AudioStreamPlayer.new()
	add_child(narrator)
	_apply_audio()


func _apply_audio() -> void:
	if music_player == null:
		return
	if music_tween == null or not music_tween.is_running():
		music_player.volume_db = linear_to_db(maxf(settings.music * (1.0 - _duck()), 0.0001))
	effect_player.volume_db = linear_to_db(settings.effects)
	voice_player.volume_db = linear_to_db(maxf(settings.music * 2.4, 0.0001))
	if narrator != null:
		narrator.volume_db = linear_to_db(maxf(settings.effects, 0.0001))
	if room != null:
		room.set_world_volume(settings.music)


## Sounds in the world, like the witches' chant, push the background music down.
func _duck() -> float:
	if bridge_falling or (narrator != null and narrator.playing):
		return 1.0
	return room.music_duck() * 0.9 if room != null else 0.0


## Progress drives the song: a bright nursery rhyme until London Bridge falls, then the
## broken, escalating versions below the city.
func _mood_stage() -> int:
	match state.act():
		"courtyard", "nursery":
			return 4
		"metropolitan":
			return 6
		"ripper":
			return 6 if state.ripper_completed else 5
		"sewer":
			return 3 if state.sewer_solved else 2
	return 1 if "note" in state.clues else 0


## How badly the picture decays: clean while London stands, torn apart after the fall.
func _dread() -> float:
	match state.act():
		"courtyard", "nursery", "metropolitan": return 0.2
		"ripper": return 0.5
		"sewer": return 0.32
	return 0.0


func _update_mood() -> void:
	var stage: int = _mood_stage()
	if post != null:
		post.set_shader_parameter("dread", _dread())
	if music_player == null or stage == music_stage:
		return
	music_stage = stage
	# Swap roles: the old song fades on the spare player, the new one rises from silence.
	var previous: AudioStreamPlayer = music_player
	music_player = fading_player
	fading_player = previous
	music_player.stream = MUSIC_STAGES[stage]
	music_player.volume_db = linear_to_db(0.001)
	music_player.play()
	if music_tween != null:
		music_tween.kill()
	var from_volume: float = db_to_linear(fading_player.volume_db) if fading_player.playing else 0.0
	music_tween = create_tween().set_parallel(true)
	music_tween.tween_method(func(amount: float) -> void:
		music_player.volume_db = linear_to_db(maxf(amount * settings.music * (1.0 - _duck()), 0.0001))
	, 0.0, 1.0, MUSIC_FADE)
	music_tween.tween_method(func(amount: float) -> void:
		fading_player.volume_db = linear_to_db(maxf(amount * from_volume, 0.0001))
	, 1.0, 0.0, MUSIC_FADE)
	music_tween.chain().tween_callback(fading_player.stop)


func _build_ui() -> void:
	# The degradation pass sits beneath the UI so text stays legible.
	var post_layer := CanvasLayer.new()
	post_layer.layer = 0
	add_child(post_layer)
	var post_rect := ColorRect.new()
	post_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post = ShaderMaterial.new()
	post.shader = POST_SHADER
	post_rect.material = post
	post_layer.add_child(post_rect)
	_apply_visuals()
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.theme = InterfaceTheme.create()
	layer.add_child(root_ui)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(hud)
	var top := MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.add_theme_constant_override("margin_left", 32)
	top.add_theme_constant_override("margin_top", 26)
	top.add_theme_constant_override("margin_right", 32)
	hud.add_child(top)
	var column := StudyTheme.column(5)
	top.add_child(column)
	chapter_label = StudyTheme.label(tr("HUD_CHAPTER"), 14, StudyTheme.GOLD)
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	chapter_label.add_theme_font_size_override("font_size", 12)
	chapter_label.add_theme_color_override("font_color", InterfaceTheme.TEXT)
	column.add_child(chapter_label)
	objective = StudyTheme.label("", 20)
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(objective)
	letters = StudyTheme.label("", 19, StudyTheme.GOLD, false)
	letters.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(letters)
	var shortcuts := InterfaceTheme.ink("B  BOOK     J  JOURNAL     ESC  PAUSE", 11, InterfaceTheme.TEXT)
	shortcuts.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	shortcuts.offset_left = -355
	shortcuts.offset_right = -32
	shortcuts.offset_top = 26
	shortcuts.offset_bottom = 52
	shortcuts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(shortcuts)
	var crosshair := StudyTheme.label("·", 32, StudyTheme.PAPER, false)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -12
	crosshair.offset_right = 12
	crosshair.offset_top = -20
	crosshair.offset_bottom = 20
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud.add_child(crosshair)
	caption = _bottom_label(-186, -130, 19, StudyTheme.PAPER)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.offset_left = 220
	caption.offset_right = -220
	caption.add_theme_font_override("font", InterfaceTheme.font())
	caption.add_theme_font_size_override("font_size", 21)
	caption.add_theme_color_override("font_color", InterfaceTheme.TEXT)
	caption.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.0, 0.9))
	caption.add_theme_constant_override("outline_size", 3)
	prompt = _bottom_label(-119, -69, 18, InterfaceTheme.TEXT)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.offset_left = 225
	prompt.offset_right = -225
	var prompt_box := InterfaceTheme.box(Color(0.035, 0.05, 0.065, 0.85), Color(0.7, 0.65, 0.5, 0.3), 10)
	prompt_box.shadow_size = 0
	prompt.add_theme_stylebox_override("normal", prompt_box)
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	holding = _bottom_label(-62, -31, 13, InterfaceTheme.ACCENT)
	holding.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	holding.offset_left = 100
	holding.offset_right = -100
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(overlay)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 3
	add_child(fade_layer)
	fader = ColorRect.new()
	fader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fader.color = Color(0, 0, 0, 0)
	fade_layer.add_child(fader)
	save_status = StudyTheme.label("", 14, StudyTheme.GOLD, false)
	save_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	save_status.offset_left = 32
	save_status.offset_top = -27
	save_status.offset_right = -32
	save_status.offset_bottom = -5
	save_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	save_status.add_theme_color_override("font_color", InterfaceTheme.MUTED)
	save_status.add_theme_font_size_override("font_size", 11)
	root_ui.add_child(save_status)


func _bottom_label(top: float, bottom: float, size: int, color: Color) -> Label:
	var label: Label = StudyTheme.label("", size, color, false)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = top
	label.offset_bottom = bottom
	hud.add_child(label)
	return label


func _switch(next: Screen) -> void:
	screen = next
	browsing = false
	var exploring: bool = next == Screen.EXPLORE
	get_tree().paused = not exploring
	if narrator != null:
		narrator.stream_paused = not exploring
	room.player.enabled = exploring
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if exploring else Input.MOUSE_MODE_VISIBLE
	hud.visible = exploring
	if exploring:
		for item: Node in hud.get_children():
			if item is CanvasItem:
				(item as CanvasItem).visible = true
	overlay.visible = not exploring
	for child: Node in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	if not exploring:
		var shade := ColorRect.new()
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.color = Color(0.02, 0.012, 0.02, 0.62 if next != Screen.MENU else 0.82)
		overlay.add_child(shade)
	_update_hud()
	if state != null:
		_update_mood()


## Neutral shell shared by settings, pause, hints and multiplayer.
func _card(width: float = 1040, height: float = 580, anchor_x: float = 0.5) -> VBoxContainer:
	var leaf := PanelContainer.new()
	leaf.name = "InterfacePanel"
	leaf.anchor_left = anchor_x
	leaf.anchor_right = anchor_x
	leaf.anchor_top = 0.5
	leaf.anchor_bottom = 0.5
	leaf.offset_left = -width / 2
	leaf.offset_right = width / 2
	leaf.offset_top = -height / 2
	leaf.offset_bottom = height / 2
	leaf.add_theme_stylebox_override("panel", InterfaceTheme.box())
	overlay.add_child(leaf)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	leaf.add_child(scroll)
	var column := StudyTheme.column(8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(column)
	leaf.modulate.a = 0.0
	create_tween().tween_property(leaf, "modulate:a", 1.0, 0.3)
	return column


func _menu_background(poster: bool = false) -> void:
	var backdrop := MenuBackdrop.new()
	backdrop.poster = poster
	overlay.add_child(backdrop)


func _menu_label(text: String, at: Vector2, extent: Vector2, font_size: int, color: Color, serif: bool = false) -> Label:
	var label := InterfaceTheme.ink(text, font_size, color, serif)
	label.position = at
	label.size = extent
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	overlay.add_child(label)
	return label


## The chapter's scenes, dissolving one into the next behind the title pages.
func _scenes(caption_shown: bool = true) -> void:
	var slides := SceneSlides.new()
	overlay.add_child(slides)
	slides.act_name.visible = caption_shown


## The anthology identity stays independent of any period or chapter.
func _show_menu() -> void:
	_switch(Screen.MENU)
	menu_page = "title"
	room.overview.current = true
	_menu_background()
	_menu_label("T L V   /   AN INTERACTIVE ANTHOLOGY", Vector2(66, 29), Vector2(660, 24), 12, InterfaceTheme.MUTED)
	_menu_label("EVERY WORLD HAS A FINAL LINE.", Vector2(96, 150), Vector2(530, 25), 12, InterfaceTheme.ACCENT)
	var title := _menu_label("THE LAST\nVERSE", Vector2(90, 188), Vector2(600, 190), 76, InterfaceTheme.TEXT, true)
	title.add_theme_constant_override("line_spacing", -7)
	_menu_label("Enter the story. Find your way out.", Vector2(96, 385), Vector2(500, 38), 19, InterfaceTheme.MUTED)
	var column := StudyTheme.column(7)
	column.position = Vector2(89, 454)
	column.size = Vector2(310, 155)
	overlay.add_child(column)
	var play := InterfaceTheme.entry(tr("MENU_PLAY") + "    →", _show_chapters, 24)
	play.alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(play)
	for item: Array in [[tr("MENU_SETTINGS"), func() -> void: _show_settings(Screen.MENU)], [tr("MENU_EXIT"), _request_quit]]:
		var entry := InterfaceTheme.entry(item[0], item[1], 18)
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		column.add_child(entry)
	_menu_label("STORIES ACROSS TIME", Vector2(66, 671), Vector2(470, 22), 11, InterfaceTheme.MUTED)
	_menu_label("01  /  SHAKESPEARE & LONDON TIMES", Vector2(810, 594), Vector2(420, 24), 11, InterfaceTheme.ACCENT)
	play.grab_focus()


func _gap(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	return gap


## Each chapter supplies its own presentation inside the common chapter navigator.
func _show_chapters() -> void:
	_switch(Screen.MENU)
	menu_page = "chapters"
	browsing = true
	room.overview.current = true
	var chapter: Dictionary = ChapterCatalog.ENTRIES[launcher_index]
	var available: bool = chapter.available
	if available:
		_scenes(false)
		_manuscript_chapter()
	else:
		_menu_background(chapter.presentation == "poster")
		_unannounced_chapter(chapter.presentation)
	_menu_label("THE LAST VERSE  /  CHAPTER SELECT", Vector2(66, 28), Vector2(700, 28), 12, InterfaceTheme.TEXT)
	var back := InterfaceTheme.entry("←  " + tr("BACK"), _show_menu, 16)
	back.position = Vector2(64, 652)
	back.size = Vector2(125, 42)
	overlay.add_child(back)
	_menu_label("%02d   /   %02d" % [launcher_index + 1, chapter_count], Vector2(590, 666), Vector2(180, 26), 13, InterfaceTheme.TEXT)
	_menu_label("←  →   BROWSE CHAPTERS", Vector2(930, 666), Vector2(300, 26), 11, InterfaceTheme.MUTED)
	for step: int in [-1, 1]:
		var arrow: Button = _arrow_button("←" if step < 0 else "→", step)
		arrow.anchor_left = 0.0 if step < 0 else 1.0
		arrow.anchor_right = arrow.anchor_left
		arrow.anchor_top = 0.5
		arrow.anchor_bottom = 0.5
		arrow.offset_left = 18.0 if step < 0 else -80.0
		arrow.offset_right = arrow.offset_left + 62.0
		arrow.offset_top = -32.0
		arrow.offset_bottom = 32.0
		overlay.add_child(arrow)
	if not available:
		back.grab_focus()
	_update_mood()


func _manuscript_chapter() -> void:
	var column := _card(590, 548, 0.34)
	var panel := column.get_parent().get_parent() as PanelContainer
	panel.name = "ManuscriptChapter"
	var paper := StyleBoxTexture.new()
	paper.texture = ParchmentView.paper("letter")
	paper.set_content_margin_all(38)
	panel.add_theme_stylebox_override("panel", paper)
	column.add_theme_constant_override("separation", 4)
	column.add_child(TitlePage.ink("CHAPTER I  /  A TALE OF BORROWED WORDS", 12, ParchmentView.RUBRIC))
	column.add_child(TitlePage.ink(tr("MENU_CHAPTER"), 38, ParchmentView.RUBRIC, true))
	column.add_child(ParchmentView.Rule.new())
	column.add_child(TitlePage.ink(tr("MENU_DESCRIPTION"), 17))
	column.add_child(ParchmentView.Rule.new())
	column.add_child(TitlePage.ink(_chapter_status(), 12, ParchmentView.INK))
	var begin := TitlePage.entry(tr("RESUME" if has_run else "BEGIN"), _begin, 27)
	column.add_child(begin)
	var extras := HBoxContainer.new()
	extras.alignment = BoxContainer.ALIGNMENT_CENTER
	extras.add_theme_constant_override("separation", 24)
	column.add_child(extras)
	if has_run:
		extras.add_child(TitlePage.entry(tr("NEW_RUN"), _confirm_restart, 17))
	extras.add_child(TitlePage.entry(tr("HINTS"), _show_hints, 17))
	extras.add_child(TitlePage.entry(tr("COOP"), _show_coop, 17))
	_menu_label("LONDON\nOUTSIDE TIME", Vector2(820, 414), Vector2(370, 110), 35, InterfaceTheme.TEXT, true)
	_menu_label("POETRY  /  MYSTERY  /  ESCAPE", Vector2(825, 543), Vector2(360, 22), 11, InterfaceTheme.ACCENT)
	begin.grab_focus()


func _unannounced_chapter(presentation: String) -> void:
	var column := _card(540, 520, 0.35)
	var panel := column.get_parent().get_parent() as PanelContainer
	panel.name = "PosterChapter" if presentation == "poster" else "FutureChapter"
	if presentation == "poster":
		panel.add_theme_stylebox_override("panel", InterfaceTheme.box(Color("d5dedb"), Color("d5dedb"), 36))
	var ink := Color("182e36") if presentation == "poster" else InterfaceTheme.TEXT
	column.add_child(InterfaceTheme.ink("THE LAST VERSE    /    CHAPTER " + CHAPTER_NUMERALS[launcher_index], 12, ink))
	column.add_child(_gap(24))
	column.add_child(InterfaceTheme.ink("TO BE\nCONTINUED", 60, ink, presentation != "poster"))
	column.add_child(_gap(20))
	column.add_child(InterfaceTheme.ink("A different time.\nAnother story waiting to be told.", 19, ink))
	column.add_child(_gap(22))
	column.add_child(InterfaceTheme.ink("NOT YET ANNOUNCED", 12, ink))
	_menu_label("THE NEXT\nSTORY", Vector2(830, 428), Vector2(360, 100), 35, InterfaceTheme.TEXT, true)
	_menu_label("MORE CHAPTERS TO COME", Vector2(835, 543), Vector2(350, 22), 11, InterfaceTheme.MUTED)


## Playing together: one player hosts the run, the other joins by address.
func _show_coop() -> void:
	_switch(Screen.MENU)
	menu_page = "coop"
	room.overview.current = true
	_menu_background()
	var column: VBoxContainer = _card(700, 520)
	column.add_child(InterfaceTheme.ink(tr("COOP_EYEBROW"), 15, InterfaceTheme.TEXT, true))
	column.add_child(InterfaceTheme.ink(tr("COOP"), 46, InterfaceTheme.ACCENT, true))
	column.add_child(InterfaceTheme.Rule.new())
	column.add_child(InterfaceTheme.ink(tr("COOP_BODY"), 17))
	column.add_child(_gap(8))
	var host_entry: Button = InterfaceTheme.entry(tr("COOP_HOST"), func() -> void:
		coop_status = ""
		if net.host() != OK:
			coop_status = tr("COOP_HOST_FAILED")
		_show_host()
	, 28)
	column.add_child(host_entry)
	column.add_child(InterfaceTheme.entry(tr("COOP_JOIN"), func() -> void:
		coop_status = ""
		_show_join()
	, 28))
	column.add_child(InterfaceTheme.entry(tr("BACK"), _show_chapters, 21))
	host_entry.grab_focus()


func _show_host() -> void:
	_switch(Screen.MENU)
	menu_page = "host"
	room.overview.current = true
	_menu_background()
	var column: VBoxContainer = _card(700, 520)
	column.add_child(InterfaceTheme.ink(tr("COOP_HOST"), 42, InterfaceTheme.ACCENT, true))
	column.add_child(InterfaceTheme.Rule.new())
	if net.together():
		column.add_child(InterfaceTheme.ink(tr("COOP_JOINED"), 20, InterfaceTheme.ACCENT, true))
		var start: Button = InterfaceTheme.entry(tr("COOP_BEGIN"), _begin, 30)
		column.add_child(start)
		start.grab_focus()
	elif net.is_host():
		column.add_child(InterfaceTheme.ink(tr("COOP_WAITING"), 19, InterfaceTheme.TEXT, true))
		var here: Array[String] = NetSession.addresses()
		column.add_child(InterfaceTheme.ink(tr("COOP_ADDRESS") % [", ".join(here) if not here.is_empty() else "127.0.0.1", NetSession.PORT], 18))
		column.add_child(InterfaceTheme.ink(tr("COOP_ADDRESS_NOTE"), 14, Color(InterfaceTheme.TEXT, 0.7)))
	else:
		column.add_child(InterfaceTheme.ink(coop_status, 18, InterfaceTheme.ACCENT))
	var cancel: Button = InterfaceTheme.entry(tr("COOP_CANCEL"), func() -> void:
		net.close()
		_show_coop()
	, 21)
	column.add_child(cancel)
	if not net.together():
		cancel.grab_focus()


func _show_join() -> void:
	_switch(Screen.MENU)
	menu_page = "join"
	room.overview.current = true
	_menu_background()
	var column: VBoxContainer = _card(700, 520)
	column.add_child(InterfaceTheme.ink(tr("COOP_JOIN"), 42, InterfaceTheme.ACCENT, true))
	column.add_child(InterfaceTheme.Rule.new())
	if net.is_client():
		column.add_child(InterfaceTheme.ink(coop_status if not coop_status.is_empty() else tr("COOP_CONNECTING"), 19, InterfaceTheme.TEXT, true))
	else:
		column.add_child(InterfaceTheme.ink(tr("COOP_JOIN_BODY"), 17))
		var field := LineEdit.new()
		field.placeholder_text = "192.168.0.12"
		field.text = settings.get_meta("last_address", "")
		field.alignment = HORIZONTAL_ALIGNMENT_CENTER
		field.custom_minimum_size = Vector2(320, 44)
		field.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		field.add_theme_font_override("font", InterfaceTheme.font())
		field.add_theme_font_size_override("font_size", 22)
		field.add_theme_color_override("font_color", InterfaceTheme.TEXT)
		field.add_theme_color_override("font_placeholder_color", Color(InterfaceTheme.TEXT, 0.4))
		field.add_theme_color_override("caret_color", InterfaceTheme.ACCENT)
		var line := StyleBoxFlat.new()
		line.bg_color = Color(1, 1, 1, 0.12)
		line.border_color = InterfaceTheme.ACCENT
		line.border_width_bottom = 2
		for box_name: String in ["normal", "focus"]:
			field.add_theme_stylebox_override(box_name, line)
		column.add_child(field)
		if not coop_status.is_empty():
			column.add_child(InterfaceTheme.ink(coop_status, 16, InterfaceTheme.ACCENT))
		var connect: Callable = func() -> void:
			settings.set_meta("last_address", field.text)
			coop_status = tr("COOP_CONNECTING")
			if net.join(field.text) != OK:
				coop_status = tr("COOP_FAILED")
			_show_join()
		field.text_submitted.connect(func(_text: String) -> void: connect.call())
		column.add_child(InterfaceTheme.entry(tr("COOP_CONNECT"), connect, 28))
		field.grab_focus()
	column.add_child(InterfaceTheme.entry(tr("COOP_CANCEL"), func() -> void:
		net.close()
		_show_coop()
	, 21))


## Hints for every riddle found so far, revealed one at a time from the chapter page.
func _show_hints() -> void:
	_switch(Screen.MENU)
	menu_page = "hints"
	room.overview.current = true
	_menu_background()
	var column: VBoxContainer = _card(820, 640)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_child(InterfaceTheme.ink(tr("HINTS_EYEBROW"), 15, InterfaceTheme.TEXT, true))
	column.add_child(InterfaceTheme.ink(tr("HINTS_TITLE"), 44, InterfaceTheme.ACCENT, true))
	column.add_child(InterfaceTheme.Rule.new())
	var found: int = 0
	for puzzle: String in StudyState.PUZZLES:
		if not puzzle in state.clues:
			continue
		found += 1
		var track: int = StudyState.PUZZLES.find(puzzle)
		column.add_child(_gap(8))
		column.add_child(InterfaceTheme.ink(tr(puzzle.to_upper() + "_TITLE"), 26, InterfaceTheme.ACCENT, true))
		var level: int = state.hints[track]
		for step: int in range(1, level + 1):
			column.add_child(InterfaceTheme.ink(tr("HINT_%s_%d" % [puzzle.to_upper(), step]), 17))
		var reveal: Button = InterfaceTheme.entry(tr("HINT"), func() -> void:
			if net.is_client():
				net.request("hint", [track])
			else:
				state.next_hint(track)
			_show_hints()
		, 19)
		reveal.disabled = level >= 3
		column.add_child(reveal)
	if found == 0:
		column.add_child(InterfaceTheme.ink(tr("HINTS_EMPTY"), 18, InterfaceTheme.TEXT, true))
	column.add_child(_gap(10))
	var back: Button = InterfaceTheme.entry(tr("BACK"), _show_chapters, 22)
	column.add_child(back)
	back.grab_focus()
	column.get_parent().set_deferred("scroll_vertical", 0)


func _arrow_button(glyph: String, step: int) -> Button:
	var button: Button = InterfaceTheme.entry(glyph, func() -> void: _browse(step), 30)
	button.focus_mode = Control.FOCUS_ALL
	for state_name: String in ["font_color", "font_hover_color"]:
		button.add_theme_color_override(state_name, Color("e8d5a8") if state_name == "font_color" else Color("fff1cf"))
	var target: int = launcher_index + step
	button.disabled = target < 0 or target >= chapter_count
	button.modulate.a = 0.25 if button.disabled else 1.0
	return button


func _browse(step: int) -> void:
	var target: int = clampi(launcher_index + step, 0, chapter_count - 1)
	if target == launcher_index:
		return
	launcher_index = target
	_play_feedback(false)
	_show_chapters()


func _chapter_status() -> String:
	if state != null and state.celestial.completed:
		return tr("STATUS_COMPLETE")
	if not has_run:
		return tr("STATUS_NEW")
	match state.act():
		"courtyard", "nursery", "metropolitan": return tr("STATUS_" + state.act().to_upper())
		"ripper": return tr("STATUS_RIPPER")
		"sewer": return tr("STATUS_SEWER")
		"street": return tr("STATUS_STREET")
	return tr("STATUS_PROGRESS") % state.letter_count()


func _begin() -> void:
	var fresh: bool = not has_run
	if not has_run:
		has_run = true
		_state_changed()
	room.player.camera.current = true
	net.send_begin(fresh)
	if fresh:
		# The stranger wakes holding the book that tells this journey.
		_show_story(0)
		return
	_explore()


func _explore() -> void:
	_switch(Screen.EXPLORE)
	room.player.camera.current = true
	room.apply_state()
	_on_focus(room.player.target)
	_announce_act()


func _confirm_restart() -> void:
	_switch(Screen.MENU)
	menu_page = "restart"
	_menu_background()
	var column: VBoxContainer = _card(640, 380)
	column.add_child(InterfaceTheme.ink(tr("RESTART_TITLE"), 38, InterfaceTheme.ACCENT, true))
	column.add_child(InterfaceTheme.Rule.new())
	column.add_child(InterfaceTheme.ink(tr("RESTART_BODY"), 18))
	column.add_child(InterfaceTheme.entry(tr("RESTART_CONFIRM"), _restart, 24))
	var cancel: Button = InterfaceTheme.entry(tr("CANCEL"), _show_chapters, 22)
	column.add_child(cancel)
	cancel.grab_focus()


func _restart() -> void:
	announced_act = ""
	_adopt(StudyState.new())
	has_run = false
	_begin()


## Everything in the room is operated directly: E acts, right click looks closer.
## The lock wheels are the exception: right click turns them backwards.
func _interact(target: StudyInteractable, alternate: bool) -> void:
	var id: String = target.interaction_id
	if net.is_client() and acting_peer == 0:
		_companion_interact(target, alternate)
		return
	if net.is_host() and acting_peer == 0 and _companion_carries(id):
		_caption(tr("COOP_COMPANION_HOLDS"))
		return
	if id == "lock_wheel" or id == "calendar_wheel":
		state.discover("lock" if id == "lock_wheel" else "bridge")
		_play_feedback(false)
		if id == "lock_wheel":
			state.turn_lock(target.index, -1 if alternate else 1)
		else:
			state.turn_calendar(target.index, -1 if alternate else 1)
		if acting_peer <= 0:
			_on_focus(target)
		return
	if id == "star_keeper":
		state.discover("celestial")
		if alternate:
			_caption(tr(target.description_key))
		else:
			state.celestial.turn(target.index)
			_play_feedback(false)
			_caption(tr("KEEPER_TURNED") % [tr(target.title_key), tr("GLYPH_" + CelestialState.GLYPHS[state.celestial.bearings[target.index]])])
		return
	if alternate or id == "actor":
		_caption(tr(target.description_key))
		return
	match id:
		"read":
			_discover_note(target.argument)
			_show_note(target.title_key, target.argument.to_upper() + "_BODY", NOTE_STYLES.get(target.argument, "scroll"))
			return
		"take":
			if state.take(target.argument):
				_caption(tr("TAKEN_" + target.argument.to_upper()))
		"ages_socket", "banquet_seat", "prop_slot", "shelf_jar":
			var station: String = SLOT_STATIONS[id]
			state.discover({"ages": "ages", "macbeth": "macbeth", "props": "props", "shelf": "brew"}[station])
			var before: Dictionary = state.to_data()
			_play_feedback(false)
			state.use_slot(station, target.index)
			if state.to_data() == before and not state.station_solved(station):
				_caption(tr("SLOT_EMPTY"))
		"bellows":
			state.discover("brew")
			if not state.brew_solved:
				state.stoke_fire()
				_play_feedback(false)
				_caption(tr("HEAT_%d" % state.heat))
		"cauldron":
			state.discover("brew")
			var result: String = state.add_to_brew()
			if result == "added":
				_play_feedback(false)
				_caption(tr("BREW_ADDED"))
			elif result == "spoiled":
				_play_feedback(false)
				_caption(tr("BREW_SPOILED"))
			elif not state.brew_solved:
				_caption(tr("BREW_EMPTY_HANDS"))
		"bridge_lever":
			state.discover("bridge")
			if not state.pull_bridge_lever():
				_play_feedback(false)
				_room_effect("rattle_lever", [])
				_caption(tr("LEVER_WRONG"))
		"house_replay":
			state.discover("house")
			if "dyer_record" not in state.clues:
				_caption(tr("DYER_READ_FIRST"))
			else:
				_room_effect("replay_memory", [])
		"house_bell":
			state.discover("house")
			var result: String = state.ring_house_bell(target.index)
			if result == "read":
				_caption(tr("DYER_READ_FIRST"))
			elif result != "inactive":
				_room_effect("play_bell", [target.index])
				if result != "solved":
					_caption(tr("HOUSE_BELL_" + result.to_upper()))
		"train_control":
			state.discover("railway")
			var result: String = state.celestial.operate_train(target.argument)
			_play_feedback(false)
			_caption(tr("TRAIN_ISOLATE_FIRST") if result == "isolate" else tr("TRAIN_CONTROL_CHANGED"))
		"train_board":
			_depart_train()
			return
		"star_confirm":
			state.discover("celestial")
			if state.celestial.confirm():
				_play_feedback(true)
				_caption(tr("STARS_ALIGNED"))
			elif not state.celestial.aligned:
				_play_feedback(false)
				_caption(tr("STARS_WRONG"))
		"floor_glyph":
			_caption(tr("FLOOR_INSPECT"))
		"inspection_lamp":
			state.discover("shadow")
			_show_police_map()
		"shadow_shutter":
			state.discover("shadow")
			if not state.close_shadow_shutter(target.index):
				_play_feedback(false)
				_caption(tr("SHADOW_WRONG"))
		"crypt_door":
			state.discover("plague")
			if state.mark_crypt(target.index):
				_play_feedback(false)
				_caption(tr("CRYPT_MARKED" if state.crypts[target.index] == 1 else "CRYPT_SCRUBBED"))
			elif not state.sewer_solved:
				_caption(tr("CRYPT_NO_BRUSH"))
		"climb":
			if state.climb_out():
				_climb_out()
				return
		"painting":
			if state.door_open:
				_enter_painting()
				return
		"trinket":
			var item := target.get_parent() as Trinket
			if item != null:
				room.pick_up(item)
				_caption(tr("TRINKET_TAKEN") % tr(target.title_key))
				_update_hud()
		"knock":
			_play_feedback(false)
			var answers: Array[String] = ["KNOCK_SILENCE", "KNOCK_BUSY", "KNOCK_DOG", "KNOCK_LATER", "KNOCK_WHO"]
			_caption(tr(answers[(target.index + knock_count) % answers.size()]))
			knock_count += 1
		"well":
			_play_feedback(false)
			_caption(tr("WELL_USED"))
		"bell":
			_play_feedback(true)
			_caption(tr("BELL_RUNG"))
			for flock: Node in room.get_children():
				if flock is Birds.PigeonFlock and not (flock as Birds.PigeonFlock).flown:
					(flock as Birds.PigeonFlock).flown = true
					(flock as Birds.PigeonFlock).scatter()
		"mirror_dial":
			state.discover("mirror")
			if state.handle_inserted and not state.mirror_solved:
				_play_feedback(false)
			if not state.turn_mirror_dial(target.index) and not state.mirror_solved:
				_caption(tr("MIRROR_DIALS_LOCKED"))
		"handle_socket":
			state.discover("mirror")
			if state.insert_handle():
				_play_feedback(false)
				_caption(tr("HANDLE_FITTED"))
			elif not state.handle_inserted:
				_caption(tr("MIRROR_NEEDS_HANDLE"))
		"lantern":
			state.discover("balcony")
			_play_feedback(false)
			var result: String = state.use_lantern(target.index)
			if result == "fitted":
				_caption(tr("LENS_FITTED"))
			elif result.is_empty() and not state.balcony_solved:
				_caption(tr("LANTERN_NO_LENS_SUN" if target.index == 0 else "LANTERN_NO_LENS_MOON"))
	if net.together() and acting_peer >= 0:
		_update_holder(acting_peer if acting_peer > 0 else net.local_id())
	if acting_peer <= 0:
		_on_focus(room.player.target)


func _discover_note(argument: String) -> void:
	state.discover(argument)
	if argument in ["dyer_record", "house_song"]:
		state.discover("house")
	if argument == "train_manual":
		state.discover("railway")
	if argument.begins_with("star_"):
		state.discover("celestial")
	if argument == "shadow_letter":
		state.discover("shadow")
	if argument.begins_with("witch_scrap") or argument == "incantation":
		state.discover("brew")


## Interactions that use the team's carried piece are refused while the other player holds it.
func _companion_carries(id: String) -> bool:
	var uses_piece: bool = id in ["ages_socket", "banquet_seat", "prop_slot", "shelf_jar", "cauldron"]
	var actor: int = acting_peer if acting_peer > 0 else net.local_id()
	return uses_piece and not state.held_station.is_empty() and net.holder != 0 and net.holder != actor


func _update_holder(actor: int) -> void:
	if state.held_station.is_empty():
		net.holder = 0
	elif net.holder == 0:
		net.holder = actor
	room.hand_owned = net.holds_locally()
	room.apply_state()
	net.send_state()


## Companion side: reading, looking closer and small comforts happen here; everything that
## changes the run is performed by the host.
func _companion_interact(target: StudyInteractable, alternate: bool) -> void:
	var id: String = target.interaction_id
	var local: bool = (alternate and id not in ["lock_wheel", "calendar_wheel"]) or id in ["actor", "trinket", "knock", "well", "bell", "floor_glyph", "read", "inspection_lamp"]
	if not local:
		net.request_interact(id, target.index, target.argument, target.global_position, alternate)
		return
	if id == "read":
		net.request("discover_note", [target.argument])
	elif id == "inspection_lamp":
		net.request("discover", ["shadow"])
	acting_peer = -1
	_interact(target, alternate)
	acting_peer = 0


## Host side: a companion's interaction, found by kind, index, argument and position.
func _remote_interact(peer: int, id: String, index: int, argument: String, at: Vector3, alternate: bool) -> void:
	var best: StudyInteractable = null
	for node: Node in room.find_children("*", "StudyInteractable", true, false):
		var candidate := node as StudyInteractable
		if candidate.interaction_id != id or candidate.index != index or candidate.argument != argument:
			continue
		if best == null or candidate.global_position.distance_to(at) < best.global_position.distance_to(at):
			best = candidate
	if best == null or best.global_position.distance_to(at) > 2.0 or bridge_falling:
		return
	acting_peer = peer
	if _companion_carries(id):
		_caption(tr("COOP_COMPANION_HOLDS"))
	else:
		_interact(best, alternate)
	acting_peer = 0
	net.send_state()


func _remote_action(peer: int, action: String, arguments: Array) -> void:
	acting_peer = peer
	match action:
		"observe_watch":
			var place: String = arguments[0]
			if place in StudyState.WATCH_ROUTE and place not in state.watch_seen:
				state.observe_watch(place)
				_caption(tr("SIGHTING") % tr("LANDMARK_" + place))
		"step_on":
			var result: String = state.celestial.step_on(int(arguments[0]))
			if result in ["wrong", "step"]:
				_caption(tr("STAR_WALK_" + result.to_upper()))
		"reveal":
			acting_peer = 0
			_on_reveal()
		"discover_note":
			_discover_note(str(arguments[0]))
		"discover":
			state.discover(str(arguments[0]))
		"report_watch":
			var route: Array[String] = []
			for place: Variant in arguments[0]:
				route.append(str(place))
			if not state.report_watch(route):
				_caption(tr("SHADOW_WRONG"))
		"hint":
			state.next_hint(int(arguments[0]))
	acting_peer = 0
	net.send_state()


## Plays a visible mechanism effect here and on the companion's screen.
func _room_effect(method: String, arguments: Array) -> void:
	if room.has_method(method):
		room.callv(method, arguments)
	if net.is_host() and net.together():
		net.tell(net.companion, "room", [method, arguments])


## Feedback sent by the host to the player it belongs to.
func _feedback(kind: String, arguments: Array) -> void:
	match kind:
		"caption":
			_caption(str(arguments[0]), float(arguments[1]))
		"note":
			if screen == Screen.EXPLORE:
				_show_note(str(arguments[0]), str(arguments[1]), str(arguments[2]))
		"map":
			if screen == Screen.EXPLORE:
				_show_police_map()
		"sound":
			_play_feedback(bool(arguments[0]))
		"room":
			if room != null and room.has_method(str(arguments[0])):
				room.callv(str(arguments[0]), arguments[1])


## Companion side: the host's run arrived.
func _follow_state(data: Dictionary) -> void:
	if bridge_falling:
		pending_state = data
		return
	var next: StudyState = StudyState.from_data(data)
	if next == null:
		return
	if next.act() != state.act():
		_adopt(next)
		if screen == Screen.EXPLORE:
			_explore()
		return
	state.changed.disconnect(_state_changed)
	state.solved.disconnect(_on_solved)
	state = next
	state.changed.connect(_state_changed)
	state.solved.connect(_on_solved)
	room.state = state
	room.hand_owned = net.holds_locally()
	room.apply_state()
	_update_hud()
	_update_mood()
	if screen == Screen.EXPLORE:
		_on_focus(room.player.target)
	elif screen == Screen.MENU and menu_page == "hints":
		_show_hints()
	if room.companion != null and net.holder == net.companion:
		room.companion.show_piece(room, state.held_station, state.held_piece)
	elif room.companion != null:
		room.companion.show_piece(room, "", -1)


func _apply_pending() -> void:
	if net.is_client() and not pending_state.is_empty():
		var data: Dictionary = pending_state
		pending_state = {}
		_follow_state(data)


## Companion side: the host began (or resumed) the tale.
func _follow_begin(data: Dictionary, fresh: bool) -> void:
	var next: StudyState = StudyState.from_data(data)
	if next == null:
		return
	announced_act = ""
	_adopt(next)
	has_run = true
	room.player.camera.current = true
	if fresh:
		_show_story(0)
	else:
		_explore()


func _follow_cinematic(kind: String) -> void:
	match kind:
		"bridge":
			if room is LondonStreet:
				_collapse_bridge()
		"painting":
			_enter_painting()
		"climb":
			_climb_out()
		"train":
			_depart_train()
		"ripper", "courtyard", "nursery", "metropolitan":
			_transition_later_act(kind)


func _companion_pose(act: String, at: Vector3, yaw: float, pitch: float) -> void:
	if room == null or not net.together():
		return
	if act != state.act():
		if room.companion != null:
			room.companion.visible = false
		return
	if room.companion == null:
		room.companion = CompanionAvatar.make(room.kit)
		room.add_child(room.companion)
	room.companion.visible = true
	room.companion.set_pose(at, yaw, pitch)
	room.companion.show_piece(room, state.held_station if net.holder == net.companion else "", state.held_piece)


func _on_threshold() -> void:
	if net.is_client():
		net.request("reveal", [])
	else:
		_on_reveal()


func _on_companion_joined() -> void:
	coop_status = tr("COOP_JOINED")
	if menu_page == "host":
		_show_host()
	elif screen == Screen.EXPLORE:
		_caption(tr("COOP_JOINED_PLAYING"))
		net.send_begin(false)


func _on_companion_left() -> void:
	if net.is_client() or net.mode == "solo" and room != null and room.follower:
		# Back to this player's own journey.
		net.close()
		var own: StudyState = store.load_run()
		has_run = own != null
		announced_act = ""
		bridge_falling = false
		_adopt(own if own != null else StudyState.new())
		coop_status = tr("COOP_HOST_LEFT")
		_show_menu()
		save_status.text = coop_status
		return
	if room != null and room.companion != null:
		room.companion.queue_free()
		room.companion = null
	net.holder = 0
	if room != null:
		room.hand_owned = true
		room.apply_state()
	_caption(tr("COOP_COMPANION_LEFT"))


func _on_solved(id: String) -> void:
	# A solved riddle is announced to both players, whoever solved it.
	var actor: int = acting_peer
	acting_peer = 0
	_play_feedback(true)
	if screen == Screen.EXPLORE:
		room.apply_state()
	_caption(tr("SOLVED_" + id.to_upper()))
	if net.is_host() and net.together():
		net.tell(net.companion, "sound", [true])
		net.tell(net.companion, "caption", [tr("SOLVED_" + id.to_upper()), 3.5])
	acting_peer = actor


func _caption(text: String, hold: float = 3.5) -> void:
	if acting_peer > 0:
		net.tell(acting_peer, "caption", [text, hold])
		return
	if caption == null or text.is_empty():
		return
	caption.text = text
	caption.modulate.a = 1.0
	if caption_tween != null:
		caption_tween.kill()
	caption_tween = create_tween()
	caption_tween.tween_interval(hold if hold != 3.5 else maxf(3.5, text.length() / 16.0))
	caption_tween.tween_property(caption, "modulate:a", 0.0, 0.8)


## Readable props appear as the object itself: a scroll, an open book, or a sealed letter.
func _show_note(title_key: String, body_key: String, style: String = "scroll") -> void:
	if acting_peer > 0:
		net.tell(acting_peer, "note", [title_key, body_key, style])
		return
	_switch(Screen.NOTE)
	var sheet := ParchmentView.new()
	sheet.style = style
	sheet.title = tr(title_key)
	sheet.body = tr(body_key)
	sheet.close_label = tr("PUT_DOWN")
	sheet.closed.connect(_explore)
	overlay.add_child(sheet)


func _show_journal(return_to: Screen) -> void:
	journal_return = return_to
	_switch(Screen.JOURNAL)
	var column: VBoxContainer = _card(860, 640)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_child(InterfaceTheme.ink(tr("JOURNAL_EYEBROW"), 15, InterfaceTheme.TEXT, true))
	column.add_child(InterfaceTheme.ink(tr("JOURNAL"), 42, InterfaceTheme.ACCENT, true))
	column.add_child(InterfaceTheme.Rule.new())
	column.add_child(InterfaceTheme.entry(tr("STORY_BOOK"), _show_story, 20))
	column.add_child(InterfaceTheme.ink(tr("JOURNAL_LETTERS"), 16, InterfaceTheme.ACCENT))
	column.add_child(InterfaceTheme.ink(_letter_row(), 40, InterfaceTheme.TEXT, true))
	column.add_child(InterfaceTheme.ink(tr("INVENTORY_HEADING"), 16, InterfaceTheme.ACCENT))
	var items: Array[String] = []
	for key: String in state.inventory_keys() + state.installed_keys():
		items.append(tr(key))
	column.add_child(InterfaceTheme.ink("\n".join(items) if not items.is_empty() else tr("INVENTORY_EMPTY"), 17))
	var notes: Array[String] = []
	var pages: Array[String] = []
	for clue: String in state.clues:
		if clue in StudyState.PUZZLES:
			continue
		if clue in StudyState.LORE:
			pages.append(clue)
		else:
			notes.append(clue)
	if notes.is_empty():
		column.add_child(InterfaceTheme.ink(tr("JOURNAL_EMPTY"), 17))
	for note: String in notes:
		column.add_child(InterfaceTheme.Rule.new())
		column.add_child(InterfaceTheme.ink(tr(note.to_upper() + "_TITLE"), 26, InterfaceTheme.ACCENT, true))
		column.add_child(InterfaceTheme.ink(tr(note.to_upper() + "_BODY"), 17))
	if not pages.is_empty():
		column.add_child(InterfaceTheme.Rule.new())
		column.add_child(InterfaceTheme.ink(tr("JOURNAL_PAGES"), 16, InterfaceTheme.ACCENT))
		for page: String in pages:
			column.add_child(InterfaceTheme.ink(tr(page.to_upper() + "_TITLE"), 24, InterfaceTheme.ACCENT, true))
			column.add_child(InterfaceTheme.ink(tr(page.to_upper() + "_BODY"), 17))
	column.add_child(InterfaceTheme.ink(tr("JOURNAL_HINT_NOTE"), 14, Color(InterfaceTheme.TEXT, 0.7), true))
	var close: Button = InterfaceTheme.entry(tr("BACK"), _close_journal, 22)
	column.add_child(close)
	close.grab_focus()
	# Keep the beginning visible; keyboard focus may still scroll to the Back button.
	column.get_parent().set_deferred("scroll_vertical", 0)


func _letter_row() -> String:
	var shown: Array[String] = []
	for letter: String in state.letters():
		shown.append(letter if not letter.is_empty() else "_")
	return "   ".join(shown)


func _close_journal() -> void:
	if journal_return == Screen.PAUSE:
		_show_pause()
	else:
		_explore()


func _show_pause() -> void:
	_switch(Screen.PAUSE)
	var column: VBoxContainer = _card(520, 560)
	column.add_child(InterfaceTheme.ink(tr("PAUSE_EYEBROW"), 15, InterfaceTheme.TEXT, true))
	column.add_child(InterfaceTheme.ink(tr("PAUSED"), 50, InterfaceTheme.ACCENT, true))
	column.add_child(InterfaceTheme.ink(StoryBook.TITLES[state.act()].replace("\n", "  ·  "), 15, InterfaceTheme.TEXT))
	column.add_child(InterfaceTheme.Rule.new())
	column.add_child(_gap(8))
	var resume: Button = InterfaceTheme.entry(tr("RESUME"), _explore, 30)
	column.add_child(resume)
	column.add_child(InterfaceTheme.entry(tr("STORY_BOOK"), _show_story, 23))
	column.add_child(InterfaceTheme.entry(tr("JOURNAL"), func() -> void: _show_journal(Screen.PAUSE), 23))
	column.add_child(InterfaceTheme.entry(tr("MENU_SETTINGS"), func() -> void: _show_settings(Screen.PAUSE), 23))
	column.add_child(InterfaceTheme.entry(tr("SAVE_MENU"), _save_and_menu, 23))
	column.add_child(InterfaceTheme.entry(tr("MENU_EXIT"), _request_quit, 23))
	resume.grab_focus()


func _show_settings(return_to: Screen) -> void:
	settings_return = return_to
	_switch(Screen.SETTINGS)
	if return_to == Screen.MENU:
		room.overview.current = true
		_menu_background()
	var column: VBoxContainer = _card(820, 660)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_child(InterfaceTheme.ink(tr("SETTINGS_EYEBROW"), 15, InterfaceTheme.TEXT, true))
	column.add_child(InterfaceTheme.ink(tr("MENU_SETTINGS"), 44, InterfaceTheme.ACCENT, true))
	column.add_child(InterfaceTheme.Rule.new())
	_slider(column, "SETTING_SENSITIVITY", 0.5, 6.0, settings.sensitivity * 1000, func(value: float) -> void: settings.sensitivity = value / 1000)
	_slider(column, "SETTING_FOV", 60, 100, settings.fov, func(value: float) -> void: settings.fov = value)
	_slider(column, "SETTING_MUSIC", 0, 100, settings.music * 100, func(value: float) -> void:
		settings.music = value / 100
		_apply_audio()
	)
	_slider(column, "SETTING_EFFECTS", 0, 100, settings.effects * 100, func(value: float) -> void:
		settings.effects = value / 100
		_apply_audio()
	)
	_slider(column, "SETTING_DISTORTION", 0, 100, settings.distortion * 100, func(value: float) -> void:
		settings.distortion = value / 100
		_apply_visuals()
	)
	_check(column, "SETTING_INVERT", settings.invert_y, func(value: bool) -> void: settings.invert_y = value)
	_check(column, "SETTING_FULLSCREEN", settings.fullscreen, func(value: bool) -> void: settings.fullscreen = value)
	column.add_child(InterfaceTheme.ink(tr("SETTING_COMFORT"), 14, Color(InterfaceTheme.TEXT, 0.75)))
	column.add_child(InterfaceTheme.Rule.new())
	column.add_child(InterfaceTheme.ink(tr("CONTROLS_TITLE"), 28, InterfaceTheme.ACCENT, true))
	for line: String in tr("CONTROLS_LIST").split("\n"):
		var parts: PackedStringArray = line.split("|")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		column.add_child(row)
		var key: Label = InterfaceTheme.ink(parts[0], 17, InterfaceTheme.ACCENT)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key.size_flags_stretch_ratio = 0.8
		row.add_child(key)
		var meaning: Label = InterfaceTheme.ink(parts[1] if parts.size() > 1 else "", 17)
		meaning.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		meaning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(meaning)
	column.add_child(_gap(8))
	var close: Button = InterfaceTheme.entry(tr("SAVE_SETTINGS"), _close_settings, 20)
	var panel := column.get_parent().get_parent() as PanelContainer
	var surface := InterfaceTheme.box()
	surface.content_margin_bottom = 82
	panel.add_theme_stylebox_override("panel", surface)
	close.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	close.offset_left = -180
	close.offset_right = 180
	close.offset_top = 269
	close.offset_bottom = 313
	overlay.add_child(close)
	close.grab_focus()
	column.get_parent().set_deferred("scroll_vertical", 0)


func _slider(parent: VBoxContainer, key: String, minimum: float, maximum: float, value: float, callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	var label: Label = InterfaceTheme.ink(tr(key), 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.custom_minimum_size.x = 250
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.1 if maximum < 10 else 1.0
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size.x = 240
	slider.modulate = Color("c5d7dc")
	row.add_child(slider)
	var amount: Label = InterfaceTheme.ink("%.1f" % value if maximum < 10 else str(int(value)), 18, InterfaceTheme.ACCENT)
	amount.custom_minimum_size.x = 55
	row.add_child(amount)
	slider.value_changed.connect(func(next: float) -> void:
		callback.call(next)
		amount.text = "%.1f" % next if maximum < 10 else str(int(next))
	)


func _check(parent: VBoxContainer, key: String, value: bool, callback: Callable) -> void:
	var control := CheckBox.new()
	control.text = tr(key)
	control.button_pressed = value
	control.toggled.connect(callback)
	control.add_theme_font_override("font", InterfaceTheme.font())
	control.add_theme_font_size_override("font_size", 18)
	for color_name: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		control.add_theme_color_override(color_name, InterfaceTheme.TEXT if color_name == "font_color" else InterfaceTheme.ACCENT)
	control.add_theme_constant_override("outline_size", 0)
	control.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	for box_name: String in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		control.add_theme_stylebox_override(box_name, StyleBoxEmpty.new())
	control.modulate = Color.WHITE
	parent.add_child(control)


func _close_settings() -> void:
	settings.apply(room.player)
	if not settings.save_settings():
		save_status.text = tr("SETTINGS_FAILED")
	if settings_return == Screen.MENU:
		_show_menu()
	else:
		_show_pause()


func _apply_visuals() -> void:
	if post != null:
		post.set_shader_parameter("strength", settings.distortion)


func _process(delta: float) -> void:
	if prompt != null:
		prompt.visible = not prompt.text.is_empty()
	if post == null:
		return
	# Mouse look smears the image like a cheap video encoder.
	var look: Vector2 = room.player.consume_look()
	var target: Vector2 = Vector2(-look.x, look.y) * 0.00045 if screen == Screen.EXPLORE else Vector2.ZERO
	smear = smear.lerp(target.limit_length(0.025), minf(delta * 14.0, 1.0))
	post.set_shader_parameter("smear", smear)
	if watching_lady and room is LondonStreet:
		var player: StudyPlayer = room.player
		var toward: Vector3 = (room as LondonStreet).bridge.lady_position() - player.camera.global_position
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-toward.x, -toward.z), minf(delta * 6.0, 1.0))
		player.camera.rotation.x = lerpf(player.camera.rotation.x, atan2(toward.y, Vector2(toward.x, toward.z).length()), minf(delta * 6.0, 1.0))
	if music_player != null and (music_tween == null or not music_tween.is_running()):
		var wanted: float = settings.music * (1.0 - _duck())
		var current: float = db_to_linear(music_player.volume_db)
		music_player.volume_db = linear_to_db(maxf(lerpf(current, wanted, minf(delta * 3.0, 1.0)), 0.0001))


func _state_changed() -> void:
	# In co-op only the host keeps the run; the companion's own save is left untouched.
	if not net.is_client():
		last_save_ok = store.save_run(state)
		save_status.text = tr(store.message_key)
		net.send_state()
	_update_hud()
	_update_mood()
	# Mechanisms move while the player operates them; menus keep scenery suspended.
	if screen == Screen.EXPLORE:
		room.apply_state()


func _update_hud() -> void:
	if state == null or objective == null:
		return
	# Only the act's name; what to do next is left to the player, the book and the hints.
	objective.text = ""
	chapter_label.text = StoryBook.TITLES[state.act()].replace("\n", "  ·  ")
	letters.text = ""
	var held: String = _piece_name(state.held_station, state.held_piece)
	var names: Array[String] = []
	if not held.is_empty():
		names.append(held)
	if room != null and room.carried != null:
		names.append(tr("TRINKET_" + room.carried.kind.to_upper()))
	holding.text = tr("HUD_HOLDING") % "  ·  ".join(names) if not names.is_empty() else ""


func _objective_key() -> String:
	if state.act() == "courtyard":
		if state.celestial.house_solved:
			return "OBJECTIVE_HOUSE_PASSAGE"
		return "OBJECTIVE_HOUSE_BELLS" if "dyer_record" in state.clues else "OBJECTIVE_COURTYARD"
	if state.act() == "nursery":
		if state.celestial.solved:
			return "OBJECTIVE_STAR_EXIT"
		return "OBJECTIVE_STAR_WALK" if state.celestial.aligned else "OBJECTIVE_STARS"
	if state.act() == "metropolitan":
		return "OBJECTIVE_TRAIN_DEPART" if state.celestial.train_ready() else "OBJECTIVE_METROPOLITAN"
	if state.act() == "ripper":
		return "OBJECTIVE_RIPPER_EXIT" if state.shadow_solved else "OBJECTIVE_RIPPER"
	if state.act() == "sewer":
		if state.sewer_solved:
			return "OBJECTIVE_CLIMB"
		return "OBJECTIVE_CRYPTS" if state.has_item("brush") else "OBJECTIVE_SEWER"
	if state.completed:
		if state.bridge_lowered:
			return "OBJECTIVE_CROSS"
		if state.brew_solved:
			return "OBJECTIVE_BRIDGE"
		return "OBJECTIVE_SQUARE" if state.props_solved else "OBJECTIVE_LANE"
	if "note" not in state.clues:
		return "OBJECTIVE_NOTE"
	if state.completed:
		return "OBJECTIVE_END"
	if state.door_open:
		return "OBJECTIVE_LEAVE"
	if state.letter_count() == 4:
		return "OBJECTIVE_LOCK"
	return "OBJECTIVE_SEARCH"


func _piece_name(station: String, piece: int) -> String:
	if station == "ages" and piece >= 0:
		return tr(TOKEN_KEYS[piece])
	if station == "macbeth" and piece > 0:
		return tr(FIGURE_KEYS[piece])
	if station == "props" and piece >= 0:
		return tr(PROP_KEYS[piece])
	if station == "shelf" and piece >= 0:
		return tr(INGREDIENT_KEYS[piece])
	return ""


func _on_focus(target: StudyInteractable) -> void:
	if prompt == null:
		return
	if not is_instance_valid(target):
		prompt.text = ""
		return
	if target.interaction_id == "lock_wheel" or target.interaction_id == "calendar_wheel":
		prompt.text = tr("PROMPT_LOCK")
		return
	var action: String = _action_text(target)
	prompt.text = (action + "     ·     " + tr("PROMPT_LOOK")) if not action.is_empty() else tr("PROMPT_LOOK")


func _action_text(target: StudyInteractable) -> String:
	match target.interaction_id:
		"read":
			return tr("PROMPT_READ") % tr(target.title_key)
		"take":
			return tr("PROMPT_TAKE") % tr(target.title_key)
		"ages_socket", "banquet_seat", "prop_slot", "shelf_jar":
			var station: String = SLOT_STATIONS[target.interaction_id]
			if state.station_solved(station):
				return ""
			var slots: Array[int] = state.slot_values(station)
			var here: String = _piece_name(station, slots[target.index])
			if state.held_station == station:
				return tr("PROMPT_SWAP") % here if not here.is_empty() else tr("PROMPT_PLACE") % _piece_name(station, state.held_piece)
			return tr("PROMPT_PICK") % here if not here.is_empty() else ""
		"mirror_dial":
			return tr("PROMPT_TURN_DIAL") if state.handle_inserted and not state.mirror_solved else ""
		"handle_socket":
			return tr("PROMPT_FIT_HANDLE") if state.has_item("handle") else ""
		"lantern":
			if state.balcony_solved:
				return ""
			var fitted: bool = state.sun_lens_inserted if target.index == 0 else state.moon_lens_inserted
			if fitted:
				return tr("PROMPT_TURN_LANTERN")
			var lens: String = "sun" if target.index == 0 else "moon"
			return tr("PROMPT_FIT_" + lens.to_upper()) if state.has_item(lens) else ""
		"bellows":
			return tr("PROMPT_BELLOWS") if not state.brew_solved else ""
		"cauldron":
			return tr("PROMPT_BREW") % _piece_name("shelf", state.held_piece) if state.held_station == "shelf" and not state.brew_solved else ""
		"bridge_lever":
			return tr("PROMPT_LEVER") if not state.bridge_lowered else ""
		"house_replay":
			return tr("PROMPT_REPLAY")
		"house_bell":
			return tr("PROMPT_RING") if not state.celestial.house_solved else ""
		"train_control":
			return tr("PROMPT_MECHANISM") if not state.celestial.completed else ""
		"train_board":
			return tr("PROMPT_BOARD")
		"star_keeper":
			return tr("PROMPT_TURN_DIAL") if not state.celestial.aligned else ""
		"star_confirm":
			return tr("PROMPT_STAR_CONFIRM") if not state.celestial.aligned else ""
		"inspection_lamp":
			return tr("PROMPT_POLICE_PLAN") if not state.shadow_solved else ""
		"shadow_shutter":
			return tr("PROMPT_LEVER") if not state.shadow_solved else ""
		"crypt_door":
			if state.sewer_solved or not state.has_item("brush"):
				return ""
			return tr("PROMPT_SCRUB" if state.crypts[target.index] == 1 else "PROMPT_MARK")
		"climb":
			return tr("PROMPT_CLIMB") if state.sewer_solved else ""
		"trinket":
			return tr("PROMPT_TAKE") % tr(target.title_key)
		"painting":
			return tr("PROMPT_PAINTING")
		"knock":
			return tr("PROMPT_KNOCK")
		"well":
			return tr("PROMPT_WELL")
		"bell":
			return tr("PROMPT_BELL")
	return ""


func _play_feedback(success: bool) -> void:
	if acting_peer > 0:
		net.tell(acting_peer, "sound", [success])
		return
	if effect_player == null:
		return
	effect_player.stream = preload("res://shared/audio/solved.wav") if success else preload("res://shared/audio/mechanism.wav")
	effect_player.play()


func _save_and_menu() -> void:
	if net.is_client():
		_on_companion_left()
		return
	_state_changed()
	if last_save_ok:
		if net.mode != "solo":
			net.close()
		_show_menu()


func _request_quit() -> void:
	if is_quitting:
		return
	if has_run and not net.is_client():
		_state_changed()
		if not last_save_ok:
			_show_pause()
			return
	net.close()
	is_quitting = true
	if music_player != null:
		if music_tween != null:
			music_tween.kill()
		music_player.stop()
		fading_player.stop()
		effect_player.stop()
		# Let the audio thread release its playback references before shutdown.
		await get_tree().create_timer(0.1, true).timeout
	get_tree().quit()


func _on_reveal() -> void:
	if bridge_falling:
		return
	if room is LondonStreet:
		_collapse_bridge()
		return
	if room is RipperStreet:
		if state.shadow_solved:
			_transition_later_act("courtyard")
		return
	if room is DyerCourtyard:
		_transition_later_act("nursery")
		return
	if room is StarNursery:
		_transition_later_act("metropolitan")
		return
	return


func _cinematic_hud() -> void:
	for item: Node in hud.get_children():
		if item is CanvasItem:
			(item as CanvasItem).visible = false
	caption.visible = true


func _depart_train() -> void:
	if bridge_falling or not room is MetropolitanStation:
		return
	state.discover("railway")
	if not state.celestial.train_ready():
		_caption(tr(state.celestial.train_blocker()))
		_play_feedback(false)
		return
	if state.celestial.completed:
		_show_level_end()
		return
	bridge_falling = true
	net.broadcast_cinematic("train")
	_cinematic_hud()
	(room as MetropolitanStation).begin_departure()
	_caption(tr("TRAIN_DEPARTING"))
	if effect_player != null:
		effect_player.stream = preload("res://shared/audio/train_departure.wav")
		effect_player.play()
	await get_tree().create_timer(4.0, true).timeout
	await _fade(1.0, 0.8)
	state.celestial.completed = true
	state.changed.emit()
	# Return-to-platform and resume start safely; no saved camera inside a moving train.
	_load_act("metropolitan")
	bridge_falling = false
	_apply_pending()
	_show_level_end()
	fader.color = Color(0, 0, 0, 0)


func _show_level_end() -> void:
	_switch(Screen.END)
	var column: VBoxContainer = _card(720, 480)
	column.add_child(InterfaceTheme.ink(tr("END_EYEBROW"), 15, InterfaceTheme.TEXT, true))
	column.add_child(InterfaceTheme.ink(tr("END_TITLE"), 46, InterfaceTheme.ACCENT, true))
	column.add_child(InterfaceTheme.Rule.new())
	column.add_child(InterfaceTheme.ink(tr("END_BODY"), 19))
	var go_on: Button = InterfaceTheme.entry(tr("END_LOOK"), _explore, 26)
	column.add_child(go_on)
	column.add_child(InterfaceTheme.entry(tr("SAVE_MENU"), _save_and_menu, 22))
	go_on.grab_focus()


func _transition_later_act(destination: String) -> void:
	if bridge_falling:
		return
	net.broadcast_cinematic(destination)
	bridge_falling = true
	room.player.enabled = false
	fader.color = Color(0, 0, 0, 0)
	await _fade(1.0, 0.8)
	match destination:
		"courtyard": state.finish_ripper()
		"nursery":
			if not state.enter_farm():
				await _fade(0.0, 0.5)
				bridge_falling = false
				room.player.enabled = true
				return
		"metropolitan":
			if not state.enter_railway():
				await _fade(0.0, 0.5)
				bridge_falling = false
				room.player.enabled = true
				return
	await get_tree().create_timer(0.5, true).timeout
	_load_act(destination)
	_explore()
	room.player.enabled = false
	# The act narrator supplies the arrival caption.
	await _fade(0.0, 1.2)
	bridge_falling = false
	_apply_pending()
	room.player.enabled = true


## Stepping into the painting of spring-time London leaves the study.
func _enter_painting() -> void:
	net.broadcast_cinematic("painting")
	bridge_falling = true
	room.player.enabled = false
	fader.color = Color(1, 1, 1, 0)
	await _fade(1.0, 1.2)
	state.finish()
	_load_act("street")
	_explore()
	_caption(tr("PAINTING_ENTERED"))
	# The streets are playable while the white fades away.
	bridge_falling = false
	_apply_pending()
	await _fade(0.0, 1.6)
	fader.color = Color(0, 0, 0, 0)


## London Bridge is falling down, with the player on it. The girl the masons walled into its
## pier climbs up over the parapet, crawls toward the player singing, springs into their
## face and drags them down with the spans, falling as the picture goes black.
func _collapse_bridge() -> void:
	var street := room as LondonStreet
	var bridge: LondonBridgeModel = street.bridge
	var player: StudyPlayer = street.player
	player.enabled = false
	bridge_falling = true
	net.broadcast_cinematic("bridge")
	_sound("res://shared/audio/bridge_crack.wav")
	street.darken(2.5)
	var to_climb: Vector3 = bridge.climb_point() - player.camera.global_position
	var turn: Tween = create_tween().set_parallel(true)
	turn.tween_property(player, "rotation:y", atan2(-to_climb.x, -to_climb.z), 0.9).set_trans(Tween.TRANS_SINE)
	turn.tween_property(player.camera, "rotation:x", atan2(to_climb.y, Vector2(to_climb.x, to_climb.z).length()), 0.9).set_trans(Tween.TRANS_SINE)
	var climbing: float = bridge.awaken(player.camera.global_position)
	_caption(tr("LADY_RISES"))
	await get_tree().create_timer(1.0, true).timeout
	watching_lady = true
	if voice_player != null:
		voice_player.play()
	await get_tree().create_timer(climbing - 1.0, true).timeout
	_caption(tr("LADY_SINGS"))
	bridge.tremble()
	await get_tree().create_timer(bridge.crawl(player.camera.global_position), true).timeout
	# She stops just out of reach, and the song stops with her.
	if voice_player != null:
		voice_player.stop()
	await get_tree().create_timer(0.8, true).timeout
	watching_lady = false
	_caption(tr("BRIDGE_FALLING"))
	_sound("res://shared/audio/lady_lunge.wav")
	bridge.lunge(player.camera)
	await get_tree().create_timer(0.2, true).timeout
	bridge.collapse()
	# Dragged backwards off the deck: the sky swings into view while the fall goes dark.
	var fall: Tween = create_tween().set_parallel(true)
	fall.tween_property(player, "position:y", player.position.y - 11.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(player, "position:x", player.position.x - 1.5, 1.5)
	fall.tween_property(player.camera, "rotation:x", 1.15, 1.1).set_trans(Tween.TRANS_SINE)
	fall.tween_property(player.camera, "rotation:z", 0.6, 1.3)
	fader.color = Color(0, 0, 0, 0)
	await get_tree().create_timer(0.35, true).timeout
	await _fade(1.0, 0.8)
	_sound("res://shared/audio/water_impact.wav")
	await get_tree().create_timer(1.6, true).timeout
	state.fall_bridge()
	_load_act("sewer")
	_explore()
	room.player.enabled = false
	_caption(tr("SEWER_WAKE"))
	await _fade(0.0, 1.6)
	bridge_falling = false
	_apply_pending()
	room.player.enabled = true


func _sound(path: String) -> void:
	if effect_player == null:
		return
	effect_player.stream = load(path)
	effect_player.play()


func _climb_out() -> void:
	await _transition_later_act("ripper")


func _house_bell_sound(index: int) -> void:
	if effect_player == null:
		return
	effect_player.stream = [preload("res://shared/audio/memory_0.wav"), preload("res://shared/audio/memory_1.wav"), preload("res://shared/audio/memory_2.wav"), preload("res://shared/audio/memory_3.wav")][index]
	effect_player.play()


func _on_shadow_seen() -> void:
	_caption(tr("SHADOW_SEEN"))
	_play_feedback(false)


func _fade(alpha: float, seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(fader, "color:a", alpha, seconds)
	await tween.finished


func _input(event: InputEvent) -> void:
	# Arrow keys browse chapters before focus navigation can claim them.
	if not browsing or screen != Screen.MENU or menu_page != "chapters":
		return
	for pair: Array in [["ui_left", -1], ["ui_right", 1]]:
		if event.is_action_pressed(pair[0]):
			_browse(pair[1])
			get_viewport().set_input_as_handled()
			return


func _unhandled_input(event: InputEvent) -> void:
	if bridge_falling:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_B and screen == Screen.EXPLORE:
		_show_story()
		get_viewport().set_input_as_handled()
	elif screen == Screen.NOTE and event.is_action_pressed("interact"):
		_explore()
		get_viewport().set_input_as_handled()
	elif screen == Screen.EXPLORE and event.is_action_pressed("drop") and room.carried != null:
		room.drop_trinket()
		_update_hud()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		match screen:
			Screen.EXPLORE: _show_pause()
			Screen.PAUSE, Screen.NOTE, Screen.END: _explore()
			Screen.MENU:
				if menu_page == "chapters":
					_show_menu()
				elif menu_page in ["hints", "restart", "coop"]:
					_show_chapters()
				elif menu_page in ["host", "join"]:
					net.close()
					_show_coop()
			Screen.JOURNAL: _close_journal()
			Screen.SETTINGS: _close_settings()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("journal") or event.is_action_pressed("inventory"):
		if screen == Screen.JOURNAL:
			_close_journal()
		elif screen in [Screen.EXPLORE, Screen.PAUSE]:
			_show_journal(screen)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():
		_request_quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and screen == Screen.EXPLORE and not bridge_falling:
		_show_pause()


func _exit_tree() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
	if is_instance_valid(fading_player):
		fading_player.stop()
	if is_instance_valid(effect_player):
		effect_player.stop()
