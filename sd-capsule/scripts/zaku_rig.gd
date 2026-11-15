extends Node3D
# Six rigid joints reconstructed from source mesh islands, not skeletal skinning.
var joints := {}
var loadout_role := "ASSAULT"
var weapon_socket: Node3D
var ranged_weapon: Node3D
var heat_hawk: Node3D
var weapon_label := "MACHINE GUN"
var strike_phase := -1.0
var strike_left := 0.0
var recoil := 0.0
var hurt := 0.0
var phase := 0.0
var aim_weight := 0.0
var evade_weight := 0.0
var melee_windup := false
var dying := false
var death_time := 0.0
var boost_meshes: Array[MeshInstance3D] = []
func _ready() -> void:
	preload("res://scripts/mecha_finish.gd").apply(self,false)
	var pivots := {"torso":Vector3(0,1.05,0),"head":Vector3(0,1.48,0),"leg_L":Vector3(0.32,0.8,0),"leg_R":Vector3(-0.32,0.8,0),"arm_L":Vector3(0.58,1.38,0),"arm_R":Vector3(-0.58,1.38,0)}
	var parts := get_children()
	for key in pivots:
		var joint := Node3D.new()
		joint.name = key
		add_child(joint)
		joint.position = pivots[key]
		joints[key] = joint
	for part in parts:
		for key in pivots:
			if str(part.name).begins_with(key+"_"):
				part.reparent(joints[key])
				part.position = -pivots[key]
				break
	weapon_socket = Node3D.new()
	weapon_socket.name = "WeaponHand"
	joints.arm_R.add_child(weapon_socket)
	weapon_socket.position = Vector3(0,-0.52,0.07)
	var kit = preload("res://scripts/weapon_kit.gd")
	kit.block(weapon_socket,"GrippingHand",Vector3(0.20,0.17,0.18),Vector3.ZERO,Color("69766c"))
	for finger in range(4):
		kit.block(weapon_socket,"Finger%d" % finger,Vector3(0.043,0.10,0.06),Vector3((finger-1.5)*0.05,0,0.10),Color("a0aaa0"))
	weapon_label = "BAZOOKA" if loadout_role == "SUPPORT" else "MACHINE GUN"
	ranged_weapon = kit.build(weapon_label)
	weapon_socket.add_child(ranged_weapon)
	heat_hawk = kit.build("HEAT HAWK")
	weapon_socket.add_child(heat_hawk)
	heat_hawk.visible = loadout_role == "ASSAULT"
	ranged_weapon.visible = not heat_hawk.visible

func update_weapon_pose() -> void:
	var chopping := strike_phase >= 0 or melee_windup
	var axe_ready := loadout_role == "ASSAULT" and aim_weight < 0.1 and recoil == 0
	heat_hawk.visible = chopping or axe_ready
	ranged_weapon.visible = not heat_hawk.visible
	# Firearms stay level as the arm raises into aim. Axe follows the chop.
	weapon_socket.basis = Basis.IDENTITY if heat_hawk.visible else joints.arm_R.basis.inverse()

func fire() -> void:
	recoil = 1.0
	update_weapon_pose()
func muzzle_position() -> Vector3:
	return ranged_weapon.get_node("Muzzle").global_position
func hit() -> void: hurt = 1.0
func strike() -> void: strike_left = 0.35
func apply_strike_pose() -> void:
	update_weapon_pose()
	if strike_phase >= 0:
		# Preparation draws the fist back; contact extends it along the attack clock.
		joints.arm_R.rotation.x = lerpf(0.5,-1.45,strike_phase)
		joints.arm_R.rotation.y = lerpf(-0.35,0.15,strike_phase)
		joints.torso.rotation.y = lerpf(-0.22,0.18,strike_phase)
		joints.arm_L.rotation.x = -0.55
		joints.leg_L.rotation.x = -0.15
		joints.leg_R.rotation.x = 0.18
func die() -> void:
	dying = true
	death_time = 0
func animate(velocity: Vector3, windup: float, evade: bool, delta: float) -> void:
	if dying:
		death_time += delta
		rotation.z = lerpf(rotation.z,-1.1,delta*5)
		position.y = -minf(0.8,death_time*0.8)
		if death_time > 0.65: hide()
		return
	strike_left = maxf(0,strike_left-delta)
	recoil = move_toward(recoil,0,delta*7)
	hurt = move_toward(hurt,0,delta*5)
	var speed := Vector2(velocity.x,velocity.z).length()
	phase += delta * speed*2.6
	var blend := 1-exp(-14*delta)
	aim_weight = lerpf(aim_weight,1.0 if windup > 0 or recoil > 0.05 else 0.0,blend)
	evade_weight = lerpf(evade_weight,1.0 if evade else 0.0,blend)
	var stride := clampf(speed/4,0,1)*0.36*(1-evade_weight)
	var wave := sin(phase)*stride
	joints.leg_L.rotation.x = lerpf(joints.leg_L.rotation.x,wave-evade_weight*0.4,blend)
	joints.leg_R.rotation.x = lerpf(joints.leg_R.rotation.x,-wave+evade_weight*0.3,blend)
	joints.leg_L.rotation.z = evade_weight*0.2
	joints.leg_R.rotation.z = -evade_weight*0.2
	var guard := aim_weight*(0.2 if melee_windup else -0.9)
	joints.arm_L.rotation.x = lerpf(joints.arm_L.rotation.x,-wave*0.45+guard+recoil*0.3,blend)
	joints.arm_R.rotation.x = lerpf(joints.arm_R.rotation.x,wave*0.45+guard+recoil*0.3,blend)
	joints.arm_R.rotation.y = lerp_angle(joints.arm_R.rotation.y,0,blend)
	if strike_phase < 0: joints.torso.rotation.y = lerp_angle(joints.torso.rotation.y,0,blend)
	apply_strike_pose()
	joints.head.rotation.y = sin(phase*0.17)*0.06*(1-aim_weight)
	joints.torso.rotation.x = lerpf(joints.torso.rotation.x,-hurt*0.24+recoil*0.12,blend)
	position.y = lerpf(position.y,absf(sin(phase))*stride*0.12-evade_weight*0.12,blend)
	var local_motion := global_basis.inverse()*velocity
	rotation.x = lerpf(rotation.x,-0.16*evade_weight+clampf(local_motion.z/65,-0.06,0.06),blend)
	joints.torso.rotation.z = lerpf(joints.torso.rotation.z,clampf(-local_motion.x/70,-0.07,0.07),blend)
	rotation.z = lerpf(rotation.z,clampf(-local_motion.x/7,-0.32,0.32)*evade_weight+hurt*0.17,blend)
	update_weapon_pose()
