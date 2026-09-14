class_name StudySettings
extends RefCounted

var sensitivity: float = 0.002
var fov: float = 78.0
var invert_y: bool = false
var fullscreen: bool = false
var music: float = 0.35
var effects: float = 0.6
var distortion: float = 1.0
var path: String = "user://study_settings.cfg"


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	sensitivity = _number(config, "sensitivity", 0.002, 0.0005, 0.006)
	fov = _number(config, "fov", 78.0, 60.0, 100.0)
	music = _number(config, "music", 0.35, 0.0, 1.0)
	effects = _number(config, "effects", 0.6, 0.0, 1.0)
	distortion = _number(config, "distortion", 1.0, 0.0, 1.0)
	var inverted: Variant = config.get_value("controls", "invert_y", false)
	var full: Variant = config.get_value("controls", "fullscreen", false)
	invert_y = inverted if inverted is bool else false
	fullscreen = full if full is bool else false


func save_settings() -> bool:
	var config := ConfigFile.new()
	for key: String in ["sensitivity", "fov", "invert_y", "fullscreen", "music", "effects", "distortion"]:
		config.set_value("controls", key, get(key))
	return config.save(path) == OK


func apply(player: StudyPlayer) -> void:
	player.sensitivity = sensitivity
	player.invert_y = invert_y
	player.camera.fov = fov
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func _number(config: ConfigFile, key: String, fallback: float, minimum: float, maximum: float) -> float:
	var value: Variant = config.get_value("controls", key, fallback)
	if (value is int or value is float) and is_finite(float(value)):
		return clampf(float(value), minimum, maximum)
	return fallback
