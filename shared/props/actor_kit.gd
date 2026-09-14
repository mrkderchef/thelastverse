class_name ActorKit
extends RefCounted
## Frozen theatre players: jointed Elizabethan mannequins in porcelain stage masks, with ruffs,
## slashed doublets, puffed sleeves, breeches, boots, and gloves. The figure faces +Z. Arm
## angles are (raise forward, 0, raise outward) in radians; "elbow" bends the forearms. Each
## actor has a "RightHand" marker node where a prop can be attached.


static func make(kit: PropKit, look: Dictionary) -> Node3D:
	var root := Node3D.new()
	var costume: String = look.get("costume", "dark")
	var trim: String = look.get("belt", "gold" if costume in ["velvet", "rose", "black", "blue", "curtain"] else "trim")
	var skin: String = look.get("skin", "bone")
	var kneel: bool = look.get("kneel", false)
	var body := Node3D.new()
	body.position.y = -0.35 if kneel else 0.0
	body.name = "Body"
	root.add_child(body)
	# Legs: breeches, stockings, knees, and turned-down boots; or a long gown.
	if look.get("skirt", false):
		kit.cylinder(body, 0.4, 0.98, Vector3(0, 0.49, 0), costume, 0.16)
		kit.cylinder(body, 0.41, 0.06, Vector3(0, 0.03, 0), trim, 0.4)
		kit.cylinder(body, 0.3, 0.05, Vector3(0, 0.55, 0), trim, 0.3)
		var panel: MeshInstance3D = kit.box(body, Vector3(0.22, 0.9, 0.02), Vector3(0, 0.48, 0.3), look.get("sleeve", "linen") if look.get("sleeve", costume) != costume else trim)
		panel.rotation.x = -0.24
	elif kneel:
		_leg(kit, body, Vector3(-0.11, 0.9, 0), Vector3(1.39, 0, 0), look, costume, 1.39)
		_leg(kit, body, Vector3(0.11, 0.9, 0), Vector3(0.0, 0, 0), look, costume, 1.55)
	else:
		for x: float in [-0.11, 0.11]:
			_leg(kit, body, Vector3(x, 0.9, 0), Vector3(0, 0, x * 0.3), look, costume)
	var torso := Node3D.new()
	torso.position.y = 0.9
	torso.rotation.x = look.get("lean", 0.0)
	body.add_child(torso)
	var upper := Node3D.new()
	upper.position.y = -0.9
	torso.add_child(upper)
	body = upper
	# A tapered doublet with a peascod belly, gold buttons, a belt, and a stiff ruff.
	kit.cylinder(body, 0.17, 0.58, Vector3(0, 1.17, 0), costume, 0.24).scale = Vector3(1.0, 1.0, 0.72)
	kit.sphere(body, 0.16, Vector3(0, 1.02, 0.05), costume, 0.9).scale = Vector3(1.0, 0.8, 0.8)
	for index: int in range(5):
		kit.sphere(body, 0.018, Vector3(0, 1.0 + index * 0.1, 0.17 - index * 0.004), "gold")
	kit.cylinder(body, 0.2, 0.06, Vector3(0, 0.9, 0), trim, 0.18).scale = Vector3(1.0, 1.0, 0.78)
	for x: float in [-0.12, 0.12]:
		kit.box(body, Vector3(0.03, 0.4, 0.02), Vector3(x, 1.2, 0.165), trim)
	if look.has("cape"):
		var cape: MeshInstance3D = kit.box(body, Vector3(0.62, 1.15, 0.04), Vector3(0, 0.98, -0.17), look["cape"])
		cape.rotation.x = -0.1
		kit.box(body, Vector3(0.66, 0.08, 0.3), Vector3(0, 1.46, -0.04), look["cape"])
	kit.cylinder(body, 0.05, 0.1, Vector3(0, 1.52, 0), skin)
	if skin == "bone":
		for layer: int in range(3):
			kit.cylinder(body, 0.19 - layer * 0.025, 0.035, Vector3(0, 1.5 + layer * 0.03, 0), "linen", 0.19 - layer * 0.025)
	_head(kit, body, look, skin)
	# Arms: puffed shoulders, sleeves slashed with trim, elbows, forearms, gloves.
	for side: int in [-1, 1]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(side * 0.25, 1.42, 0)
		var angles: Vector3 = look.get("right_arm" if side > 0 else "left_arm", Vector3(0.1, 0, 0.12))
		shoulder.rotation = Vector3(-angles.x, 0, side * angles.z)
		body.add_child(shoulder)
		var sleeve: String = look.get("sleeve", costume)
		kit.sphere(shoulder, 0.1, Vector3(0, -0.04, 0), sleeve, 1.1)
		kit.cylinder(shoulder, 0.055, 0.3, Vector3(0, -0.2, 0), sleeve, 0.065)
		kit.box(shoulder, Vector3(0.02, 0.26, 0.13), Vector3(side * 0.04, -0.2, 0), trim)
		kit.sphere(shoulder, 0.045, Vector3(0, -0.36, 0), sleeve)
		var elbow := Node3D.new()
		elbow.position = Vector3(0, -0.36, 0)
		elbow.rotation.x = -float(look.get("elbow", 0.25))
		shoulder.add_child(elbow)
		kit.cylinder(elbow, 0.042, 0.28, Vector3(0, -0.15, 0), sleeve, 0.05)
		kit.cylinder(elbow, 0.05, 0.04, Vector3(0, -0.28, 0), "linen", 0.06)
		var glove: String = look.get("glove", "black" if skin == "bone" else skin)
		kit.sphere(elbow, 0.045, Vector3(0, -0.34, 0.01), glove, 1.2)
		kit.box(elbow, Vector3(0.02, 0.07, 0.04), Vector3(side * 0.03, -0.33, 0.04), glove).rotation.x = 0.4
		if side > 0:
			var marker := Node3D.new()
			marker.name = "RightHand"
			marker.position = Vector3(0, -0.36, 0.03)
			elbow.add_child(marker)
	# Collision so nobody walks through the cast.
	var blocker := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CylinderShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	blocker.add_child(shape)
	root.add_child(blocker)
	return root


## One leg hanging from the hip: puffed trunk-hose, stocking, knee, boot.
static func _leg(kit: PropKit, body: Node3D, hip: Vector3, angles: Vector3, look: Dictionary, costume: String, knee_bend: float = 0.0) -> void:
	var joint := Node3D.new()
	joint.position = hip
	joint.rotation = Vector3(-angles.x, 0, angles.z)
	body.add_child(joint)
	var hose: String = look.get("legs", costume)
	kit.sphere(joint, 0.11, Vector3(0, -0.08, 0), hose, 1.1)
	kit.cylinder(joint, 0.055, 0.34, Vector3(0, -0.3, 0), look.get("stockings", "linen" if hose != "black" else "dark"), 0.05)
	kit.sphere(joint, 0.05, Vector3(0, -0.46, 0), look.get("stockings", "linen" if hose != "black" else "dark"))
	var knee := Node3D.new()
	knee.position = Vector3(0, -0.46, 0)
	knee.rotation.x = knee_bend
	joint.add_child(knee)
	kit.cylinder(knee, 0.06, 0.34, Vector3(0, -0.2, 0), "trim", 0.05)
	kit.cylinder(knee, 0.075, 0.06, Vector3(0, -0.04, 0), "trim", 0.08)
	kit.box(knee, Vector3(0.1, 0.07, 0.22), Vector3(0, -0.4, -0.06 if knee_bend > 1.5 else 0.05), "black")


## A porcelain stage mask: comedy smiles, tragedy frowns; non-bone skins stay blank.
static func _head(kit: PropKit, body: Node3D, look: Dictionary, skin: String) -> void:
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.66, 0)
	head.rotation.x = look.get("nod", 0.0)
	body.add_child(head)
	var headwear := Node3D.new()
	headwear.position.y = -1.66
	head.add_child(headwear)
	_hat(kit, headwear, look.get("hat", ""))
	kit.sphere(head, 0.12, Vector3.ZERO, skin, 1.15)
	if skin != "bone":
		for x: float in [-0.04, 0.04]:
			kit.box(head, Vector3(0.03, 0.02, 0.02), Vector3(x, 0.02, 0.11), "black")
		return
	var mask: String = look.get("mask", ["comedy", "tragedy", "plain"][absi(hash(str(look.get("costume", "")) + str(look.get("hat", "")))) % 3])
	kit.sphere(head, 0.115, Vector3(0, 0.0, 0.035), "paper", 1.1).scale = Vector3(0.95, 1.0, 0.75)
	for x: float in [-0.045, 0.045]:
		var eye: MeshInstance3D = kit.sphere(head, 0.034, Vector3(x * 1.1, 0.03, 0.112), "black", 0.6)
		eye.rotation.z = x * (8.0 if mask == "tragedy" else -8.0)
		kit.box(head, Vector3(0.06, 0.014, 0.012), Vector3(x * 1.1, 0.075, 0.118), "black").rotation.z = x * (6.0 if mask == "tragedy" else -4.0)
		if mask == "comedy":
			kit.sphere(head, 0.026, Vector3(x * 1.4, -0.03, 0.108), "rose", 0.5)
	match mask:
		"comedy":
			for x: float in [-0.04, -0.013, 0.013, 0.04]:
				kit.box(head, Vector3(0.03, 0.016, 0.012), Vector3(x, -0.06 + absf(x) * 0.9, 0.12), "curtain")
		"tragedy":
			for x: float in [-0.04, -0.013, 0.013, 0.04]:
				kit.box(head, Vector3(0.03, 0.016, 0.012), Vector3(x, -0.05 - absf(x) * 0.9, 0.12), "black")
			kit.box(head, Vector3(0.008, 0.05, 0.006), Vector3(0.05, -0.02, 0.118), "blue")
		_:
			kit.box(head, Vector3(0.05, 0.008, 0.01), Vector3(0, -0.055, 0.12), "curtain")


## Head, shoulders, and forearms leaning on a window sill; the figure faces +Z. The sill line
## sits at local y 0.75.
static func bust(kit: PropKit, look: Dictionary) -> Node3D:
	var root := Node3D.new()
	var costume: String = look.get("costume", "linen")
	kit.box(root, Vector3(0.42, 0.42, 0.22), Vector3(0, 0.95, -0.05), costume)
	kit.cylinder(root, 0.05, 0.1, Vector3(0, 1.2, 0), "bone")
	for layer: int in range(3):
		kit.cylinder(root, 0.18 - layer * 0.025, 0.035, Vector3(0, 1.18 + layer * 0.03, 0), "linen", 0.18 - layer * 0.025)
	var face := Node3D.new()
	root.add_child(face)
	_head(kit, face, look, "bone")
	face.position.y = -0.33
	(face.get_child(0) as Node3D).position.z = 0.02

	for child: Node in root.get_children():
		if child is Node3D and (child as Node3D).position.y > 1.6:
			(child as Node3D).position.y -= 0.33
	for side: float in [-1.0, 1.0]:
		if side > 0 and look.get("wave", false):
			var arm: MeshInstance3D = kit.cylinder(root, 0.045, 0.5, Vector3(0.3, 1.25, 0.05), costume)
			arm.rotation.z = -0.35
			kit.sphere(root, 0.05, Vector3(0.39, 1.5, 0.05), "bone")
		else:
			kit.box(root, Vector3(0.09, 0.09, 0.36), Vector3(side * 0.17, 0.8, 0.14), costume)
			kit.sphere(root, 0.05, Vector3(side * 0.15, 0.8, 0.33), "bone")
	for mesh: Node in root.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


static func hand_of(actor: Node3D) -> Node3D:
	return actor.find_child("RightHand", true, false) as Node3D


static func _hat(kit: PropKit, body: Node3D, hat: String) -> void:
	var top := Vector3(0, 1.78, 0)
	match hat:
		"crown":
			kit.cylinder(body, 0.11, 0.08, top, "gold", 0.12)
			for index: int in range(6):
				var angle: float = index * TAU / 6
				kit.box(body, Vector3(0.025, 0.07, 0.025), top + Vector3(cos(angle) * 0.11, 0.07, sin(angle) * 0.11), "gold")
		"laurel":
			kit.cylinder(body, 0.125, 0.03, top + Vector3(0, -0.04, 0), "ivy", 0.13)
		"hood":
			kit.sphere(body, 0.16, top + Vector3(0, -0.1, -0.03), "dark", 1.2)
		"pointed":
			kit.cylinder(body, 0.26, 0.02, top + Vector3(0, -0.02, 0), "black")
			kit.cylinder(body, 0.11, 0.42, top + Vector3(0, 0.2, -0.02), "black", 0.0).rotation.x = -0.25
		"cap":
			kit.cylinder(body, 0.13, 0.08, top + Vector3(0, -0.02, 0), "velvet", 0.11)
			kit.box(body, Vector3(0.02, 0.18, 0.02), top + Vector3(0.08, 0.1, -0.05), "bone").rotation.z = -0.5
		"donkey":
			kit.sphere(body, 0.17, top + Vector3(0, -0.08, 0.06), "iron", 1.3)
			for x: float in [-0.08, 0.08]:
				kit.box(body, Vector3(0.05, 0.26, 0.04), top + Vector3(x, 0.18, -0.02), "iron").rotation.z = x * 3.0
			kit.box(body, Vector3(0.12, 0.1, 0.16), top + Vector3(0, -0.16, 0.18), "iron")
		"plague":
			# Plague doctor: wide-brimmed hat, round dark lenses, and a long leather beak.
			kit.cylinder(body, 0.26, 0.03, top + Vector3(0, -0.02, 0), "black")
			kit.cylinder(body, 0.12, 0.2, top + Vector3(0, 0.08, 0), "black", 0.1)
			var beak: MeshInstance3D = kit.cylinder(body, 0.06, 0.34, Vector3(0, 1.6, 0.26), "trim", 0.0)
			beak.rotation.x = PI / 2 + 0.35
			for x: float in [-0.05, 0.05]:
				kit.cylinder(body, 0.035, 0.03, Vector3(x, 1.7, 0.11), "glass").rotation.x = PI / 2
		"tophat":
			kit.cylinder(body, 0.2, 0.02, top + Vector3(0, -0.03, 0), "black")
			kit.cylinder(body, 0.11, 0.3, top + Vector3(0, 0.13, 0), "black", 0.115)
		"bobby":
			kit.cylinder(body, 0.12, 0.3, top + Vector3(0, 0.08, 0), "blue", 0.08)
			kit.sphere(body, 0.03, top + Vector3(0, 0.25, 0), "gold")
		"bald":
			pass
