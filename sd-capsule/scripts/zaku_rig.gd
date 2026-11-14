extends Node3D
# Six rigid joints reconstructed from source mesh islands, not skeletal skinning.
var joints := {}
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
func fire() -> void: recoil = 1.0
func hit() -> void: hurt = 1.0
func strike() -> void: strike_left = 0.35
func apply_strike_pose() -> void:
	if strike_phase >= 0:
		# Preparation draws the fist back; contact extends it along the attack clock.
		joints.arm_R.rotation.x = lerpf(0.5,-1.45,strike_phase)
		joints.arm_R.rotation.y = lerpf(-0.35,0.15,strike_phase)
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
	apply_strike_pose()
	joints.head.rotation.y = sin(phase*0.17)*0.06*(1-aim_weight)
	joints.torso.rotation.x = lerpf(joints.torso.rotation.x,-hurt*0.24+recoil*0.12,blend)
	position.y = lerpf(position.y,absf(sin(phase))*stride*0.12-evade_weight*0.12,blend)
	var local_motion := global_basis.inverse()*velocity
	rotation.x = lerpf(rotation.x,-0.16*evade_weight,blend)
	rotation.z = lerpf(rotation.z,clampf(-local_motion.x/7,-0.32,0.32)*evade_weight+hurt*0.17,blend)
