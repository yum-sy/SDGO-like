extends Node3D
# Rigid-part animation, not skinning. Original source geometry stays intact.
var joints := {}
var weapon: MeshInstance3D
var saber: MeshInstance3D
var down := false
var saber_equipped := false
var joint_sides := {}
var aim_left := 0.0
var aim_pitch := 0.0
var gun_side := "R"
var recoil := 0.0
var hurt := 0.0
var landing := 0.0
var boost_active := false
var reload_progress := 0.0
var thrusters: Array[MeshInstance3D] = []
var attack_angle := 0.0
var attack_stage := "READY"
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
				gun_side = limb_side
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
	var grip := MeshInstance3D.new()
	var handle := CylinderMesh.new()
	handle.top_radius = 0.07
	handle.bottom_radius = 0.07
	handle.height = 0.22
	grip.mesh = handle
	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color("394856")
	grip.material_override = grip_mat
	grip.position.y = -0.91
	saber.add_child(grip)
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
func fire() -> void:
	recoil = 1.0
	aim_left = 0.65
func hit() -> void: hurt = 1.0
func land() -> void: landing = 1.0
func set_attack_pose(clock: RefCounted) -> void:
	swing_index = clock.index
	attack_stage = clock.stage()
	attack_angle = clock.pose_angle()
	swing_left = 1.0 if clock.running else 0.0
	apply_blade_pose()
func apply_blade_pose() -> void:
	saber.visible = swing_left > 0 or saber_equipped
	if is_instance_valid(weapon): weapon.visible = not saber.visible
	if swing_left > 0:
		# The same local arc is used by the authoritative swept hit test.
		var direction := Vector3(sin(attack_angle),0,cos(attack_angle))
		saber.position = Vector3(-0.65,1.15,0.55)+direction*0.8
		saber.basis = Basis(Quaternion(Vector3.UP,direction))
	else:
		saber.position = Vector3(-0.65,1.4,0.6)
		saber.rotation = Vector3(0.2,0,-0.2)
func animate(velocity: Vector3, grounded: bool, time: float, delta: float) -> void:
	aim_left = maxf(0,aim_left-delta)
	recoil = move_toward(recoil,0,delta*9)
	hurt = move_toward(hurt,0,delta*5)
	landing = move_toward(landing,0,delta*6)
	rotation.x = lerpf(rotation.x,(-0.22 if boost_active else 0.0)+hurt*0.16,delta*12)
	rotation.z = sin(time*1.6)*hurt*0.08
	position.y = -landing*0.12
	for flame in thrusters:
		flame.visible = boost_active
		flame.scale.y = 0.8+sin(time*7)*0.2
	var stride := clampf(Vector2(velocity.x,velocity.z).length()/7.0,0,1) * 0.35 if grounded else 0.0
	for key in joints:
		var joint: Node3D = joints[key]
		var side := 1.0 if joint_sides[key] == "L" else -1.0
		var angle := sin(time) * stride * side
		if "leg_" in key:
			joint.rotation.x = angle if grounded else -0.25
		else:
			joint.rotation.x = -angle * 0.4 - recoil*0.25 - sin(reload_progress*PI)*0.65
			joint.rotation.y = 0
			if joint_sides[key] == gun_side and reload_progress == 0 and swing_left == 0:
				joint.rotation.x -= (0.95+aim_pitch)*minf(1,aim_left*8)
	apply_blade_pose()
	if swing_left > 0:
		for key in joints:
			if ("hand_" in key or "armor_" in key) and joint_sides[key] == gun_side:
				joints[key].rotation.x = -0.8
				joints[key].rotation.y = attack_angle*0.55
		rotation.z += sin(attack_angle)*0.12

func die() -> void:
	down = true
	saber.hide()
	for flame in thrusters: flame.hide()
func _process(delta: float) -> void:
	if not down: return
	rotation.z = lerpf(rotation.z,1.2,1-exp(-5*delta))
	position.y = lerpf(position.y,-0.55,1-exp(-5*delta))
