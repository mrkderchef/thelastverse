class_name SaveStore
extends RefCounted

var path: String
var message_key: String = ""


func _init(save_path: String = "user://london_is_falling.json") -> void:
	path = save_path


func load_run() -> StudyState:
	message_key = ""
	var state: StudyState = _read(path)
	if state != null:
		return state
	state = _read(path + ".bak")
	if state != null:
		message_key = "SAVE_RECOVERED"
		return state
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		message_key = "SAVE_DAMAGED"
	return null


func save_run(state: StudyState) -> bool:
	var temporary: String = path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		message_key = "SAVE_FAILED"
		return false
	file.store_string(JSON.stringify(state.to_data(), "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK or _read(temporary) == null:
		message_key = "SAVE_FAILED"
		return false
	# Never replace the last good backup with a corrupt primary.
	if _read(path) != null:
		var backup_error: Error = DirAccess.copy_absolute(path, path + ".bak")
		if backup_error != OK:
			message_key = "SAVE_FAILED"
			return false
	var rename_error: Error = DirAccess.rename_absolute(temporary, path)
	message_key = "SAVE_OK" if rename_error == OK else "SAVE_FAILED"
	return rename_error == OK


func _read(file_path: String) -> StudyState:
	if not FileAccess.file_exists(file_path):
		return null
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	return StudyState.from_data(parser.data)
