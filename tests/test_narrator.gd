extends SceneTree

var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var cues: Dictionary = preload("res://shared/audio/narrator/narration_cues.gd").STARTS
	for act: String in StoryBook.VOICES:
		var stream: AudioStream = load("res://shared/audio/narrator/" + act + ".wav")
		assert(stream != null and stream.get_length() > 10.0)
		assert(cues[act].size() == StoryBook.VOICES[act].split("\n").size())
		var previous: float = -1.0
		for start: float in cues[act]:
			assert(start > previous and start < stream.get_length())
			previous = start
	game = load("res://app/main.tscn").instantiate()
	game.store = SaveStore.new("user://narrator_qa_%s.json" % Time.get_ticks_usec())
	game.settings.path = "user://narrator_qa.settings"
	root.add_child(game)
	# The game deliberately skips audio construction in headless mode.
	if game.narrator == null:
		game.narrator = AudioStreamPlayer.new()
		game.add_child(game.narrator)
	await create_timer(0.7).timeout
	game._begin()
	game._explore()
	await create_timer(1.1).timeout
	var lines: PackedStringArray = StoryBook.VOICES.study.split("\n")
	assert(game.caption.text == lines[0], "First caption must match the audio cue")
	game.narrator.stream_paused = true
	await create_timer(float(cues.study[1]) + 0.4).timeout
	assert(game.caption.text == lines[0], "Paused audio must not advance verse captions")
	game.narrator.stream_paused = false
	await create_timer(float(cues.study[1]) + 0.2).timeout
	assert(game.caption.text == lines[1], "Second caption must follow resumed audio")
	game.narrator.stop()
	await process_frame
	game.queue_free()
	# Allow the audio mixer to release its final playback reference before exit.
	await create_timer(0.2).timeout
	print("Narrator QA passed: seven recordings, cue bounds, playback and pause/resume captions")
	quit()
