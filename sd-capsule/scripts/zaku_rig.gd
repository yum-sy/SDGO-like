extends Node3D
# Six rigid joints reconstructed from source mesh islands, not skeletal skinning.
var joints := {}
var strike_left := 0.0
var recoil := 0.0
var hurt := 0.0
var phase := 0.0
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
	phase += delta * (7 + speed*1.5)
	var stride := clampf(speed/4,0,1)*0.36
	var wave := sin(phase)*stride
	joints.leg_L.rotation.x = wave
	joints.leg_R.rotation.x = -wave
	joints.arm_L.rotation.x = -wave*0.45 - windup*0.45 + recoil*0.25
	joints.arm_R.rotation.x = wave*0.45 - windup*0.45 + recoil*0.25
	joints.arm_R.rotation.x -= sin(strike_left/0.35*PI)*1.2
	joints.head.rotation.y = sin(phase*0.17)*0.06
	joints.torso.rotation.x = -hurt*0.18 + recoil*0.08
	position.y = absf(sin(phase))*stride*0.12
	rotation.x = lerpf(rotation.x,0.08 if evade else 0.0,delta*9)
	rotation.z = hurt*0.17
