class_name CelestialArt
extends RefCounted
## The same authored geometry appears in the sky, on backs, and in the floor inlay.
const POINTS: Array = [
	[Vector2(0, 1), Vector2(-1, -1), Vector2(1, -1)],
	[Vector2(0, 1.2), Vector2(-0.85, 0), Vector2(0, -1.2), Vector2(0.85, 0)],
	[Vector2(-1.2, 0.8), Vector2(-0.6, -0.7), Vector2(0, 0.8), Vector2(0.6, -0.7), Vector2(1.2, 0.8)],
	[Vector2(-0.7, 0.7), Vector2(0, 1.4), Vector2(0.7, 0.7), Vector2(0, 0), Vector2(0, -1.2), Vector2(0.65, -1.2)],
	[Vector2(-1.3, 0), Vector2(-0.65, 0.65), Vector2(0.3, 0.65), Vector2(1.3, 0), Vector2(0.3, -0.65), Vector2(-0.65, -0.65), Vector2(0, 0)],
	[Vector2(-1, 1.2), Vector2(0, 1.2), Vector2(1, 0.6), Vector2(0, 0), Vector2(-1, 0), Vector2(-1, -0.6), Vector2(0, -1.2), Vector2(1, -1.2)],
]

static func line(kit: PropKit, parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Variant) -> void:
	var length: float = a.distance_to(b)
	if length < 0.001:
		return
	var mesh := kit.cylinder(parent, radius, length, (a + b) / 2.0, material)
	var up: Vector3 = (b - a).normalized()
	var right: Vector3 = up.cross(Vector3.FORWARD)
	if right.length_squared() < 0.01:
		right = up.cross(Vector3.RIGHT)
	right = right.normalized()
	mesh.basis = Basis(right, up, right.cross(up))

static func glyph(kit: PropKit, parent: Node3D, index: int, size: float, material: Variant = "gold", stars: bool = false) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var points: Array = POINTS[index]
	for i: int in range(points.size()):
		var p: Vector2 = points[i] * size
		if stars:
			kit.sphere(root, 0.085 * size, Vector3(p.x, p.y, 0), "gas")
		if i > 0:
			var previous: Vector2 = points[i - 1] * size
			line(kit, root, Vector3(previous.x, previous.y, 0), Vector3(p.x, p.y, 0), size * (0.012 if stars else 0.027), material)
	if index < 2:
		var first: Vector2 = points[0] * size
		var last: Vector2 = points[-1] * size
		line(kit, root, Vector3(first.x, first.y, 0), Vector3(last.x, last.y, 0), size * 0.027, material)
	return root

static func inscription(kit: PropKit, parent: Node3D, text: String, position: Vector3, font_size: int = 38) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.006
	label.position = position
	label.modulate = Color("ead8a8")
	label.outline_size = 2
	label.set_meta("diegetic", true)
	parent.add_child(label)
	return label

static func environment(parent: Node3D, ambient: float = 0.7) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("040919")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7285b2")
	env.ambient_light_energy = ambient
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.65
	env.ssao_enabled = true
	var world := WorldEnvironment.new()
	world.environment = env
	parent.add_child(world)
