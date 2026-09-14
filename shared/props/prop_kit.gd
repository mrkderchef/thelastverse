class_name PropKit
extends RefCounted
## Procedural placeholder primitives with the shared grimy early-3D material palette.

const STARBURST := preload("res://shared/shaders/starburst.gdshader")

var materials: Dictionary = {}
var grime: NoiseTexture2D
var grit: NoiseTexture2D
var grime_normal: NoiseTexture2D


func _init() -> void:
	grime = _noise_texture(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.02, 11, false, 0.5)
	grit = _noise_texture(FastNoiseLite.TYPE_CELLULAR, 0.08, 29, false, 0.7)
	grime_normal = _noise_texture(FastNoiseLite.TYPE_SIMPLEX, 0.045, 5, true)
	# Contrasting palette: bottle-green walls, walnut, crimson, royal-blue velvet, brass, bone.
	materials["wood"] = material(Color("7a5236"))
	materials["dark"] = material(Color("34323a"))
	materials["black"] = material(Color("121014"))
	materials["wall"] = material(Color("4f7462"))
	materials["trim"] = material(Color("5e3e2a"))
	materials["gold"] = material(Color("e6b24c"), 0.85)
	materials["iron"] = material(Color("5d5b63"), 0.7)
	materials["paper"] = material(Color("f2e6c4"))
	materials["linen"] = material(Color("ddd4bd"))
	materials["bone"] = material(Color("ebe1c6"))
	materials["rug"] = material(Color("7c1a25"))
	materials["curtain"] = material(Color("7d1726"))
	materials["velvet"] = material(Color("2b4a92"))
	materials["blue"] = material(Color("2f58a0"))
	materials["ivy"] = material(Color("468a3a"))
	materials["rose"] = material(Color("c41d34"))
	materials["glass"] = material(Color("35699c"), 0.75, Color("2a5f9e"), 0.5)
	materials["flame"] = material(Color("ffd396"), 0.0, Color("ffae52"), 3.5)
	materials["lit"] = material(Color("ffd08a"), 0.0, Color("ffb45a"), 4.0)
	materials["sigil"] = material(Color("ff6a45"), 0.0, Color("ff5a3c"), 3.0)
	materials["ember"] = material(Color("b3643a"), 0.6, Color("ff8a3a"), 0.9)
	materials["flesh"] = material(Color("c9787a"))
	materials["stone"] = material(Color("9aa0ab"))
	materials["roof"] = material(Color("3b4256"))
	materials["brick"] = material(Color.WHITE)
	materials["brick"].albedo_texture = brickwork()
	materials["brick"].uv1_scale = Vector3.ONE * 0.7
	materials["plaster"] = material(Color("9a8a70"))
	materials["plaster_cool"] = material(Color("7d7a8c"))
	materials["plaster_warm"] = material(Color("8c664e"))
	materials["timber"] = material(Color("2e2420"))
	materials["river"] = material(Color("0e1c26"), 0.9)
	materials["gas"] = material(Color("ffe6a0"), 0.0, Color("ffd27a"), 1.6)
	materials["window"] = material(Color("e0a060"), 0.0, Color("ffb060"), 0.9)
	materials["daylight"] = material(Color("8cc4f0"), 0.0, Color("a8d4f8"), 0.7)
	materials["sludge"] = material(Color("3a4a22"), 0.5, Color("4a6a1a"), 0.35)
	materials["plaster_cream"] = material(Color("f4d89a"))
	materials["plaster_sky"] = material(Color("86bff0"))
	materials["plaster_rose"] = material(Color("f09a8e"))
	materials["plaster_mint"] = material(Color("92dca4"))
	materials["plaster_lilac"] = material(Color("c6a8e8"))
	materials["plaster_ochre"] = material(Color("eab04c"))
	materials["door_green"] = material(Color("2e7a4a"))
	materials["door_red"] = material(Color("b02a2a"))
	materials["door_blue"] = material(Color("2a4ab0"))
	materials["roof_red"] = material(Color("9a3a26"))
	materials["roof_slate"] = material(Color("46506a"))
	materials["awning_red"] = material(Color("d83a3a"))
	materials["awning_green"] = material(Color("3aa05a"))
	materials["flag_red"] = material(Color("e03a3a"))
	materials["flag_yellow"] = material(Color("f2c63a"))
	materials["flag_blue"] = material(Color("3a6ae0"))
	materials["water"] = material(Color("2f6fa8"), 0.6)
	materials["brew"] = material(Color("5ea83a"), 0.0, Color("7adf3a"), 2.2)
	var cobble: StandardMaterial3D = material(Color("ffffff"))
	cobble.albedo_texture = cobblestones()
	cobble.detail_enabled = false
	cobble.uv1_scale = Vector3.ONE * 0.42
	materials["cobble"] = cobble
	materials["ghost"] = glow(Color("9fd4ff"), 0.28)
	materials["beam"] = glow(Color("ffd9a0"), 0.35)


func material(color: Color, metallic: float = 0.0, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.42 if metallic > 0 else 0.7
	mat.metallic = metallic
	# Unfiltered, object-space noise gives the crunchy, oversharpened early-3D surface.
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * 0.9
	mat.albedo_texture = grime
	mat.normal_enabled = true
	mat.normal_texture = grime_normal
	mat.detail_enabled = true
	mat.detail_mask = grime
	mat.detail_albedo = grit
	mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_1
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = energy if energy > 0 else 0.5
	return mat


func glow(color: Color, alpha: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(color, alpha)
	return mat


func box(parent: Node3D, size: Vector3, location: Vector3, look: Variant, collision: bool = false) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	var mesh: MeshInstance3D = _mesh(parent, shape, location, look)
	if collision:
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		_collide(mesh, box_shape)
	return mesh


func cylinder(parent: Node3D, radius: float, height: float, location: Vector3, look: Variant, top_radius: float = -1.0, collision: bool = false) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top_radius < 0 else top_radius
	shape.height = height
	shape.radial_segments = 12
	var mesh: MeshInstance3D = _mesh(parent, shape, location, look)
	if collision:
		var cylinder_shape := CylinderShape3D.new()
		cylinder_shape.radius = radius
		cylinder_shape.height = height
		_collide(mesh, cylinder_shape)
	return mesh


func sphere(parent: Node3D, radius: float, location: Vector3, look: Variant, squash: float = 1.0) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0 * squash
	shape.radial_segments = 12
	shape.rings = 6
	return _mesh(parent, shape, location, look)


func flare(parent: Node3D, location: Vector3, color: Color, size: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	var mat := ShaderMaterial.new()
	mat.shader = STARBURST
	mat.set_shader_parameter("tint", color)
	mat.set_shader_parameter("seed", location.x * 3.1 + location.y * 5.3 + location.z * 1.7)
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.material_override = mat
	mesh.position = location
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.extra_cull_margin = size
	parent.add_child(mesh)
	return mesh


func label(parent: Node3D, key: String, location: Vector3, size: int, color: Color) -> Label3D:
	var text := Label3D.new()
	text.text = tr(key)
	text.position = location
	text.font_size = size
	text.pixel_size = 0.004
	text.modulate = color
	text.outline_size = 8
	text.outline_modulate = Color("2a0306")
	text.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	parent.add_child(text)
	return text


func light(parent: Node3D, location: Vector3, color: Color, energy: float, radius: float, shadow: bool = false) -> OmniLight3D:
	var omni := OmniLight3D.new()
	omni.position = location
	omni.light_color = color
	omni.light_energy = energy
	omni.omni_range = radius
	omni.shadow_enabled = shadow
	omni.light_volumetric_fog_energy = 2.0
	parent.add_child(omni)
	return omni


func interactable(parent: Node3D, id: String, title: String, description: String, location: Vector3, size: Vector3, index: int = -1, argument: String = "") -> StudyInteractable:
	var target := StudyInteractable.new()
	target.interaction_id = id
	target.title_key = title
	target.description_key = description
	target.index = index
	target.argument = argument
	target.position = location
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	target.add_child(collider)
	parent.add_child(target)
	return target


## Staggered handmade bricks with chipped mortar, shared by the street and sewer.
func brickwork() -> ImageTexture:
	var image := Image.create(256, 256, false, Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 1888
	noise.frequency = 0.24
	for y: int in range(256):
		for x: int in range(256):
			var row: int = y / 32
			var offset: int = (x + (row % 2) * 32) % 64
			var grain: float = noise.get_noise_2d(x, y)
			var joint: bool = y % 32 < 3 or offset < 3 + int(grain * 2.0)
			var shade: float = 0.85 + 0.15 * sin(row * 13.0 + floor(float(x + (row % 2) * 32) / 64.0) * 7.0) + grain * 0.16
			image.set_pixel(x, y, Color("48443d") if joint else Color("915440") * shade)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


## Tileable cobblestones: rounded stones of varied grey-brown with dark mortar joints.
func cobblestones() -> ImageTexture:
	var size: int = 256
	var cells: int = 8
	var cell: float = float(size) / cells
	var rng := RandomNumberGenerator.new()
	rng.seed = 1666
	var points: Array[Vector2] = []
	var tones: Array[Color] = []
	var palette: Array[Color] = [Color("8a8278"), Color("9a8e7e"), Color("7a746e"), Color("a09888"), Color("857a6a"), Color("6e6a66")]
	for index: int in range(cells * cells):
		points.append(Vector2(rng.randf_range(0.25, 0.75), rng.randf_range(0.25, 0.75)))
		tones.append(palette[rng.randi() % palette.size()].lerp(Color("b0a898"), rng.randf() * 0.3))
	var speckle := FastNoiseLite.new()
	speckle.seed = 7
	speckle.frequency = 0.25
	var image := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y: int in range(size):
		for x: int in range(size):
			var cx: int = int(x / cell)
			var cy: int = int(y / cell)
			var first: float = 99.0
			var second: float = 99.0
			var owner: int = 0
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var gx: int = posmod(cx + dx, cells)
					var gy: int = posmod(cy + dy, cells)
					var point := (Vector2(cx + dx, cy + dy) + points[gy * cells + gx]) * cell
					var distance: float = Vector2(x, y).distance_to(point)
					if distance < first:
						second = first
						first = distance
						owner = gy * cells + gx
					elif distance < second:
						second = distance
			var edge: float = second - first
			var shade: float = speckle.get_noise_2d(x, y) * 0.08
			var colour: Color = tones[owner].darkened(clampf(first / cell * 0.35, 0.0, 0.3)) + Color(shade, shade, shade)
			if edge < 3.0:
				colour = Color("2a2622").lerp(colour, edge / 3.0 * 0.4)
			image.set_pixel(x, y, colour)
	return ImageTexture.create_from_image(image)


## A rope that sags visibly between two points, thick enough to survive the pixel filter.
func rope(parent: Node3D, from: Vector3, to: Vector3, sag: float = 0.5, look: String = "trim") -> void:
	var steps: int = 6
	for index: int in range(steps):
		var a: Vector3 = _sag_point(from, to, float(index) / steps, sag)
		var b: Vector3 = _sag_point(from, to, float(index + 1) / steps, sag)
		var segment: MeshInstance3D = cylinder(parent, 0.028, a.distance_to(b) + 0.02, (a + b) / 2.0, look)
		var up: Vector3 = (b - a).normalized()
		var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
		segment.basis = Basis(side, up, side.cross(up))
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _sag_point(from: Vector3, to: Vector3, t: float, sag: float) -> Vector3:
	return from.lerp(to, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)


## A small paper card with a large inked letter and position pips beneath it.
func letter_card(parent: Node3D, letter: String, pips: int, location: Vector3, tilt: float = -0.4) -> Node3D:
	var card := Node3D.new()
	card.position = location
	card.rotation.x = tilt
	parent.add_child(card)
	box(card, Vector3(0.17, 0.23, 0.006), Vector3.ZERO, "paper")
	var ink := Label3D.new()
	ink.set_meta("diegetic", true)
	ink.text = letter
	ink.font_size = 120
	ink.pixel_size = 0.0012
	ink.modulate = Color("3a0508")
	ink.outline_size = 0
	ink.position = Vector3(0, 0.02, 0.005)
	card.add_child(ink)
	for pip: int in range(pips):
		box(card, Vector3(0.014, 0.014, 0.004), Vector3((pip - (pips - 1) / 2.0) * 0.024, -0.085, 0.005), "black")
	return card


## Readable paper: interacting opens it; right click describes it.
func note(parent: Node3D, argument: String, location: Vector3, size: Vector2, tilt: Vector3 = Vector3.ZERO) -> StudyInteractable:
	var key: String = argument.to_upper()
	var target: StudyInteractable = interactable(parent, "read", key + "_TITLE", key + "_INSPECT", location, Vector3(maxf(size.x, 0.3), maxf(size.y, 0.3), 0.2), -1, argument)
	box(target, Vector3(size.x, size.y, 0.006), Vector3.ZERO, "paper").rotation = tilt
	return target


func _mesh(parent: Node3D, shape: Mesh, location: Vector3, look: Variant) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = materials[look] if look is String else look
	mesh.position = location
	parent.add_child(mesh)
	return mesh


func _collide(mesh: MeshInstance3D, shape: Shape3D) -> void:
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	mesh.add_child(body)


func _noise_texture(kind: FastNoiseLite.NoiseType, frequency: float, seed_value: int, normal: bool, low: float = 0.5) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = kind
	noise.frequency = frequency
	noise.seed = seed_value
	noise.fractal_octaves = 5
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	if normal:
		texture.as_normal_map = true
		texture.bump_strength = 7.0
	else:
		var ramp := Gradient.new()
		ramp.set_color(0, Color(low, low * 0.97, low * 0.95))
		ramp.set_color(1, Color(1.0, 0.96, 0.9))
		texture.color_ramp = ramp
	return texture
