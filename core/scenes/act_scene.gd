class_name ActScene
extends Node3D
## Shared scaffolding for a playable act: the prop kit, the first-person player, the puzzle
## piece in their right hand and any trinket in their left, the launcher camera, flickering
## lights, fall recovery, and state application.
## Subclasses build their world in `_ready`, call `_add_player`, and override the hooks.

signal crossed_threshold
## Asks the game to show a one-line caption, given as a translation key.
signal narrate(key: String)

var kit: PropKit
var player: StudyPlayer
var overview: Camera3D
var hand: Node3D
var hand_key: String = ""
var flickering: Array[OmniLight3D] = []
var flicker_base: Array[float] = []
var state: StudyState
var threshold_reported: bool = false
var story_volume: Node3D
var left_hand: Node3D
var carried: Trinket
var safe_position := Vector3.ZERO
## Co-op: whether this player (rather than the companion) carries the team's puzzle piece.
var hand_owned: bool = true
## Co-op companion side: the host runs the world, so scene-level actions are sent to it.
var follower: bool = false
## Called as ask.call(action, arguments) when `follower` is set.
var ask: Callable
var companion: CompanionAvatar


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	kit = PropKit.new()


func restore(run: StudyState) -> void:
	state = run
	threshold_reported = false
	apply_state(false)
	var spawn: Array = spawn_point()
	player.reset_at(spawn[0], spawn[1])
	safe_position = spawn[0]


func apply_state(_animate: bool = true) -> void:
	_update_hand()


## [position, yaw] where the player appears after loading this act.
func spawn_point() -> Array:
	return [Vector3.ZERO, 0.0]


## How far the background music should duck (0 none, 1 silent) for sounds in the world.
func music_duck() -> float:
	return 0.0


func set_world_volume(_linear: float) -> void:
	pass


## The 3D model of a carried puzzle piece, or null if this act has no such station.
func make_held_piece(_station: String, _piece: int) -> Node3D:
	return null


func find_interactable(id: String, index: int = -1, argument: String = "") -> StudyInteractable:
	for node: Node in find_children("*", "StudyInteractable", true, false):
		var target := node as StudyInteractable
		if target.interaction_id == id and (index < 0 or target.index == index) and (argument.is_empty() or target.argument == argument):
			return target
	return null


## A flickering candle whose base sits at `location`.
func candle(location: Vector3, shadow: bool = true) -> void:
	kit.box(self, Vector3(0.12, 0.03, 0.12), location + Vector3(0, 0.015, 0), "gold")
	kit.cylinder(self, 0.04, 0.24, location + Vector3(0, 0.15, 0), "paper")
	var flame: MeshInstance3D = kit.sphere(self, 0.035, location + Vector3(0, 0.3, 0), "flame", 1.6)
	kit.flare(self, flame.position, Color("ffc27a"), 0.8)
	flicker(kit.light(self, location + Vector3(0, 0.42, 0), Color("ffc98a"), 1.7 if shadow else 1.0, 3.6 if shadow else 2.6, shadow))


func flicker(light: OmniLight3D) -> void:
	flickering.append(light)
	flicker_base.append(light.light_energy)


func _add_player(overview_position: Vector3, overview_target: Vector3) -> void:
	player = StudyPlayer.new()
	player.name = "Player"
	add_child(player)
	hand = Node3D.new()
	hand.position = Vector3(0.24, -0.17, -0.45)
	hand.rotation = Vector3(0.2, -0.4, 0)
	player.camera.add_child(hand)
	kit.light(hand, Vector3(-0.1, 0.12, 0.15), Color("ffcf94"), 0.5, 0.7)
	left_hand = Node3D.new()
	left_hand.position = Vector3(-0.26, -0.2, -0.46)
	left_hand.rotation = Vector3(0.25, 0.4, 0)
	player.camera.add_child(left_hand)
	story_volume = Node3D.new()
	# Tucked low at the edge of view, so the book is present without hiding the room.
	story_volume.position = Vector3(-0.07, -0.09, 0.05)
	story_volume.rotation = Vector3(0.35, 0.2, 0.15)
	story_volume.scale = Vector3.ONE * 0.72
	left_hand.add_child(story_volume)
	kit.box(story_volume, Vector3(0.19, 0.025, 0.25), Vector3.ZERO, "velvet")
	kit.box(story_volume, Vector3(0.17, 0.03, 0.23), Vector3(0, 0.027, 0), "paper")
	kit.box(story_volume, Vector3(0.19, 0.012, 0.25), Vector3(0, 0.048, 0), "velvet")
	kit.box(story_volume, Vector3(0.025, 0.004, 0.19), Vector3(0, 0.057, 0), "gold")
	overview = Camera3D.new()
	overview.position = overview_position
	overview.fov = 72
	add_child(overview)
	overview.look_at(overview_target)
	overview.current = true


func _update_hand() -> void:
	if story_volume != null:
		story_volume.visible = carried == null
	if state == null or hand == null:
		return
	var key: String = "" if state.held_station.is_empty() or not hand_owned else "%s:%d" % [state.held_station, state.held_piece]
	if key == hand_key:
		return
	hand_key = key
	for child: Node in hand.get_children():
		if not child is OmniLight3D:
			child.queue_free()
	if key.is_empty():
		return
	var piece: Node3D = make_held_piece(state.held_station, state.held_piece)
	if piece == null:
		return
	hand.add_child(piece)
	for mesh: Node in piece.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Scatters loose trinkets: `spots` are [kind, position] pairs.
func scatter_trinkets(spots: Array) -> void:
	for spot: Array in spots:
		var item: Trinket = Trinket.make(kit, spot[0])
		add_child(item)
		item.position = spot[1]
		item.rotation.y = float(spot[1].x * 3.1 + spot[1].z)


## Takes a trinket into the left hand, swapping out whatever was there.
func pick_up(item: Trinket) -> void:
	if carried != null:
		drop_trinket(item.global_position + Vector3(0, 0.15, 0), Vector3.ZERO)
	carried = item
	item.freeze = true
	item.set_reachable(false)
	item.reparent(left_hand, false)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO


## Throws the carried trinket forward, or sets it at `at` when given.
func drop_trinket(at: Variant = null, impulse: Variant = null) -> void:
	if carried == null:
		return
	var item: Trinket = carried
	carried = null
	var forward: Vector3 = -player.camera.global_basis.z
	item.reparent(self, false)
	item.global_position = at if at != null else player.camera.global_position + forward * 0.6
	item.freeze = false
	item.set_reachable(true)
	item.linear_velocity = Vector3.ZERO
	item.apply_central_impulse(impulse if impulse != null else forward * 2.4 + Vector3(0, 0.8, 0))


func _process(_delta: float) -> void:
	# Anyone who slips out of the set is put back where they last stood safely.
	if player != null and player.enabled:
		if player.is_on_floor() and player.global_position.y > -0.5:
			safe_position = player.global_position
		elif player.global_position.y < -3.0:
			player.reset_at(safe_position + Vector3(0, 0.1, 0), player.rotation.y, player.camera.rotation.x)
	var t: float = Time.get_ticks_msec() / 1000.0
	for index: int in range(flickering.size()):
		var wobble: float = sin(t * 7.3 + index * 1.7) * 0.12 + sin(t * 17.9 + index * 4.1) * 0.08 + sin(t * 31.0 + index) * 0.05
		flickering[index].light_energy = flicker_base[index] * (1.0 + wobble)


## Emits `crossed_threshold` once when `reached` first becomes true during play.
func _report_threshold(reached: bool) -> void:
	if reached and not threshold_reported and player.enabled:
		threshold_reported = true
		crossed_threshold.emit()
