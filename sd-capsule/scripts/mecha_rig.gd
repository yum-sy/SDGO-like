extends Node3D
# Rigid-part animation, not skinning. Original source geometry stays intact.
var joints := {}
var joint_rest := {}
var elbows := {}
var attack_weight := 0.0
var weapon: MeshInstance3D
var hand_socket: Node3D
var shield_mount: Node3D
var saber: MeshInstance3D
var down := false
var saber_equipped := false
var joint_sides := {}
var aim_left := 0.0
var aim_pitch := 0.0
var gun_side := "R"
var evade_weight := 0.0
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
	preload("res://scripts/mecha_finish.gd").apply(self,true)
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
			joint_rest[name_text] = pivot_at
			if "armor_gun" in name_text:
				weapon = part
				gun_side = limb_side
	# One physical shoulder hierarchy per arm. The imported props were exploded
	# sideways; align their grip with the source hand instead of animating props alone.
	for side_name in ["L", "R"]:
		var arm: Node3D
		var hand_center := Vector3.ZERO
		for key in joints:
			if "hand_lengan" in key and joint_sides[key] == side_name: arm = joints[key]
			if ("hand_" + side_name + "__") in key:
				hand_center = joints[key].get_child(0).get_aabb().get_center()
				hand_center.y -= 0.18 # fist sits below the forearm, not inside it
		if arm == null: continue
		for key in joints:
			if joint_sides[key] != side_name or "leg_" in key or joints[key] == arm: continue
			var old: Node3D = joints[key]
			var part: MeshInstance3D = old.get_child(0)
			part.reparent(arm)
			if "armor_gun" in key:
				part.position.x += hand_center.x - part.get_aabb().get_center().x
				part.position.y -= 0.18
			elif "armor_shield" in key:
				part.position.x += hand_center.x + 0.22 - part.get_aabb().get_center().x
				part.position.y -= 0.18
			old.queue_free()
			joints[key] = arm
			joint_rest[key] = arm.position
		var socket := Node3D.new()
		arm.add_child(socket)
		socket.position = hand_center - arm.position
		if side_name == gun_side: hand_socket = socket
		else: shield_mount = socket
		build_hand(socket,side_name)
		var elbow := Node3D.new()
		elbow.name = "Elbow"+side_name
		arm.add_child(elbow)
		elbow.position = Vector3(hand_center.x,0.73,hand_center.z)-arm.position
		for child in arm.get_children():
			if child == elbow: continue
			if child == socket or (child is MeshInstance3D and (("hand_"+side_name+"__") in str(child.name) or "armor_" in str(child.name))):
				child.reparent(elbow)
		elbows[side_name] = elbow
		var bearing := MeshInstance3D.new()
		var bearing_mesh := CylinderMesh.new()
		bearing_mesh.top_radius = 0.095
		bearing_mesh.bottom_radius = 0.095
		bearing_mesh.height = 0.19
		bearing_mesh.radial_segments = 10
		bearing.mesh = bearing_mesh
		bearing.rotation.z = PI/2
		var bearing_mat := StandardMaterial3D.new()
		bearing_mat.albedo_color = Color("3e5061")
		bearing_mat.roughness = 0.6
		bearing.material_override = bearing_mat
		elbow.add_child(bearing)
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
	hand_socket.add_child(saber)
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
func hand_block(parent: Node3D, label: String, size: Vector3, at: Vector3, color: String) -> void:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = 0.6
	part.material_override = material
	part.position = at
	parent.add_child(part)

func build_hand(socket: Node3D, side_name: String) -> void:
	# Readable closed mechanical fist: wrist, dorsal plate, curled fingers and thumb.
	# Fingers surround a central grip channel shared by rifle and saber.
	hand_block(socket,"Wrist",Vector3(0.14,0.13,0.14),Vector3(0,0.15,0),"657787")
	hand_block(socket,"Palm",Vector3(0.25,0.18,0.16),Vector3(0,0,-0.04),"465969")
	hand_block(socket,"BackPlate",Vector3(0.23,0.15,0.045),Vector3(0,0.01,-0.14),"9eafbc")
	for finger in range(4):
		var x := (finger-1.5)*0.064
		hand_block(socket,"Knuckle%d" % finger,Vector3(0.054,0.095,0.085),Vector3(x,0.025,0.075),"8296a5")
		hand_block(socket,"Finger%d" % finger,Vector3(0.054,0.065,0.105),Vector3(x,-0.058,0.06),"526879")
	var inner := 1.0 if side_name == gun_side else -1.0
	hand_block(socket,"Thumb",Vector3(0.07,0.135,0.09),Vector3(inner*0.151,0.01,0.04),"a3b3be")
	if side_name != gun_side:
		hand_block(socket,"ShieldHandle",Vector3(0.26,0.065,0.07),Vector3(0.13,0,0),"344454")

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
	attack_weight = 0.0
	if clock.running:
		var clip: Vector3 = clock.clip()
		attack_weight = smoothstep(0,1,clock.elapsed/clip.x) if attack_stage == "WINDUP" else 1.0
		if attack_stage == "RECOVERY": attack_weight = 1-smoothstep(0,1,(clock.elapsed-clip.x-clip.y)/clip.z)
	apply_blade_pose()
func apply_blade_pose() -> void:
	saber.visible = swing_left > 0 or saber_equipped
	if is_instance_valid(weapon): weapon.visible = not saber.visible
	if saber.visible:
		var direction := Vector3(sin(attack_angle),0,cos(attack_angle)) if swing_left > 0 else Vector3(-0.25,0.65,0.72).normalized()
		var local_direction: Vector3 = hand_socket.get_parent().global_basis.inverse() * global_basis * direction
		# Rotate the entire gripping hand with the hilt, not the blade alone.
		hand_socket.basis = Basis(Quaternion(Vector3.UP,local_direction.normalized()))
		saber.position = Vector3.UP*0.91
		saber.basis = Basis.IDENTITY
	else:
		hand_socket.basis = Basis.IDENTITY
func animate(velocity: Vector3, grounded: bool, time: float, delta: float) -> void:
	aim_left = maxf(0,aim_left-delta)
	recoil = move_toward(recoil,0,delta*9)
	hurt = move_toward(hurt,0,delta*5)
	landing = move_toward(landing,0,delta*6)
	var forward_speed := (global_basis.inverse()*velocity).z
	rotation.x = lerpf(rotation.x,(-0.22 if boost_active else clampf(forward_speed/70,-0.1,0.1))+hurt*0.16,1-exp(-12*delta))
	var blend := 1-exp(-16*delta)
	evade_weight = lerpf(evade_weight,1.0 if boost_active else 0.0,blend)
	var local_motion := global_basis.inverse()*velocity
	var slash_bank := sin(attack_angle)*0.12 if swing_left > 0 else 0.0
	rotation.z = lerpf(rotation.z,clampf(-local_motion.x/24,-0.28,0.28)*evade_weight+hurt*0.08+slash_bank,blend)
	position.y = -landing*0.12 - attack_weight*(0.08 if swing_index == 3 else 0.035) + (absf(sin(time))*0.025 if grounded and velocity.length() > 0.5 and not boost_active else 0.0)
	for flame in thrusters:
		flame.visible = boost_active
		flame.scale.y = 0.8+sin(time*7)*0.2
	var stride := clampf(Vector2(velocity.x,velocity.z).length()/7.0,0,1) * 0.35 if grounded else 0.0
	var animated := {}
	for key in joints:
		var joint: Node3D = joints[key]
		if animated.has(joint): continue
		animated[joint] = true
		var side := 1.0 if joint_sides[key] == "L" else -1.0
		var angle := sin(time) * stride * side
		if "leg_" in key:
			var forward_weight := clampf(local_motion.z/7,-1,1)
			var strafe_weight := clampf(local_motion.x/7,-1,1)
			var leg_pose := angle*forward_weight if grounded else -0.25
			joint.rotation.z = lerpf(joint.rotation.z,angle*strafe_weight*0.65,blend)
			leg_pose = lerpf(leg_pose,-0.35+side*0.3,evade_weight)
			leg_pose += attack_weight*side*(0.24 if swing_index == 3 else 0.12)
			joint.rotation.x = lerpf(joint.rotation.x,leg_pose,blend)
		else:
			var firing_arm: bool = joint_sides[key] == gun_side
			var arm_pose := -0.20-angle*0.22-sin(reload_progress*PI)*0.65-evade_weight*0.25
			var yaw_pose := 0.0
			var roll_pose := 0.0
			joint.position = joint_rest[key]
			if swing_left > 0:
				if firing_arm:
					arm_pose = lerpf(arm_pose,-0.9-(0.18 if swing_index == 3 else 0.0),attack_weight)
					yaw_pose = attack_angle*0.75*attack_weight
					roll_pose = -0.2*attack_weight
				else:
					# Shield arm counterbalances the blade and braces the heavy finisher.
					arm_pose -= attack_weight*0.55
					yaw_pose = -attack_angle*0.16*attack_weight
			elif firing_arm and saber_equipped:
				arm_pose -= 0.38
				roll_pose = -0.12
			elif firing_arm and reload_progress == 0:
				arm_pose -= (0.85+aim_pitch)*minf(1,aim_left*8)
				arm_pose -= recoil*0.18
				joint.position += Vector3(0,recoil*0.025,-recoil*0.09)
			elif aim_left > 0 and reload_progress == 0:
				arm_pose -= minf(1,aim_left*8)*0.25
			joint.rotation.x = lerpf(joint.rotation.x,arm_pose,blend)
			joint.rotation.y = lerp_angle(joint.rotation.y,yaw_pose,blend)
			joint.rotation.z = lerp_angle(joint.rotation.z,roll_pose,blend)
	for side_name in elbows:
		var bend := -0.14
		if side_name == gun_side:
			bend -= 0.30*minf(1,aim_left*8) + 0.34*sin(reload_progress*PI)
			bend -= 0.20*attack_weight
		else: bend -= 0.18*attack_weight
		elbows[side_name].rotation.x = lerpf(elbows[side_name].rotation.x,bend,blend)
	apply_blade_pose()

func die() -> void:
	down = true
	saber.hide()
	for flame in thrusters: flame.hide()
func _process(delta: float) -> void:
	if not down: return
	rotation.z = lerpf(rotation.z,1.2,1-exp(-5*delta))
	position.y = lerpf(position.y,-0.55,1-exp(-5*delta))
