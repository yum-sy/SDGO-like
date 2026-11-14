extends Node3D
# Rigid-part animation, not skinning. Original source geometry stays intact.
var joints := {}
var weapon: MeshInstance3D
var saber: MeshInstance3D
var down := false
var saber_equipped := false
var joint_sides := {}
var recoil := 0.0
var hurt := 0.0
var landing := 0.0
var boost_active := false
var reload_progress := 0.0
var thrusters: Array[MeshInstance3D] = []
var swing_left := 0.0
var swing_duration := 0.32
var swing_index := 0
func _ready() -> void:
	var shoulders := {}
	for part in get_children():
		if part is MeshInstance3D and "hand_lengan" in str(part.name):
			var bound: AABB = part.get_aabb()
			shoulders["L" if "_L" in str(part.name) else "R"] = Vector3(bound.get_center().x,bound.end.y-0.03,bound.get_center().z)
	for part in get_children():
		if not part is MeshInstance3D:
			continue
		var name_text := str(part.name)
		if "leg_" in name_text or "hand_" in name_text or "armor_gun" in name_text or "armor_shield" in name_text:
			var bounds: AABB = part.get_aabb()
			var pivot_at := bounds.get_center()
			pivot_at.y = bounds.end.y - bounds.size.y * 0.08
			var limb_side := "L" if "_L" in name_text else "R"
			if "armor_" in name_text and not shoulders.is_empty():
				limb_side = "L" if pivot_at.distance_squared_to(shoulders.L) < pivot_at.distance_squared_to(shoulders.R) else "R"
			if "hand_" in name_text or "armor_" in name_text:
				pivot_at = shoulders.get(limb_side,pivot_at)
			joint_sides[name_text] = limb_side
			var joint := Node3D.new()
			add_child(joint)
			joint.position = pivot_at
			part.reparent(joint)
			part.position = -pivot_at
			joints[name_text] = joint
			if "armor_gun" in name_text:
				weapon = part
	saber = MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.045
	shape.bottom_radius = 0.045
	shape.height = 1.6
	saber.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1,0.2,0.75)
	saber.material_override = mat
	add_child(saber)
	saber.hide()
	for side in [-1,1]:
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.12
		cone.bottom_radius = 0.015
		cone.height = 0.65
		flame.mesh = cone
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = Color(0.3,0.85,1)
		flame.material_override = glow
		flame.position = Vector3(side*0.25,1.12,-0.48)
		flame.rotation.x = PI*0.5
		add_child(flame)
		thrusters.append(flame)
func fire() -> void: recoil = 1.0
func hit() -> void: hurt = 1.0
func land() -> void: landing = 1.0
func swing(combo: int) -> void:
	swing_index = combo
	swing_left = 0.32 if combo < 3 else 0.45
	swing_duration = swing_left
func animate(velocity: Vector3, grounded: bool, time: float, delta: float) -> void:
	recoil = move_toward(recoil,0,delta*9)
	hurt = move_toward(hurt,0,delta*5)
	landing = move_toward(landing,0,delta*6)
	rotation.x = lerpf(rotation.x,(-0.22 if boost_active else 0.0)+hurt*0.16,delta*12)
	rotation.z = sin(time*1.6)*hurt*0.08
	position.y = -landing*0.12
	for flame in thrusters:
		flame.visible = boost_active
		flame.scale.y = 0.8+sin(time*7)*0.2
	swing_left = maxf(0,swing_left-delta)
	var stride := clampf(Vector2(velocity.x,velocity.z).length()/7.0,0,1) * 0.35 if grounded else 0.0
	for key in joints:
		var joint: Node3D = joints[key]
		var side := 1.0 if joint_sides[key] == "L" else -1.0
		var angle := sin(time) * stride * side
		if "leg_" in key:
			joint.rotation.x = angle if grounded else -0.25
		else:
			joint.rotation.x = -angle * 0.4 - recoil*0.25 - sin(reload_progress*PI)*0.65
	saber.visible = swing_left > 0 or saber_equipped
	if is_instance_valid(weapon):
		weapon.visible = not saber.visible
	if saber_equipped and swing_left == 0:
		saber.position = Vector3(-0.65,1.4,0.6)
		saber.rotation = Vector3(0.2,0,-0.2)
	if swing_left > 0:
		var phase := 1 - swing_left / swing_duration
		var arc := lerpf(-1.2,1.2,phase) * (1 if swing_index % 2 else -1)
		saber.position = Vector3(-0.65,1.25,0.5)
		saber.rotation = Vector3(PI*0.5,0,arc)
		saber.position += Vector3(sin(arc),0,cos(arc)) * 0.7
		for key in joints:
			if "hand_" in key or "armor_shield" in key:
				joints[key].rotation.x = -0.6 + sin(phase*PI)*0.8
		rotation.z += sin(arc)*0.12

func die() -> void:
	down = true
	saber.hide()
	for flame in thrusters: flame.hide()
func _process(delta: float) -> void:
	if not down: return
	rotation.z = lerpf(rotation.z,1.2,1-exp(-5*delta))
	position.y = lerpf(position.y,-0.55,1-exp(-5*delta))
