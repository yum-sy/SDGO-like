extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS ",label)
	else:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	scene.set_physics_process(false)
	var rig = scene.combat.targets[0].model
	rig.rotation = Vector3.ZERO
	for i in range(20): rig.animate(Vector3(7,0,0),0,true,0.016)
	check(rig.rotation.z < -0.15 and rig.position.y < 0,"Zaku side evade banks into motion and lowers stance")
	for i in range(60): rig.animate(Vector3.ZERO,0,false,0.016)
	check(absf(rig.rotation.z) < 0.01 and rig.evade_weight < 0.01,"Zaku evade smoothly recovers to neutral")
	rig.strike_phase = 0
	rig.apply_strike_pose()
	var prepared: float = rig.joints.arm_R.rotation.x
	rig.strike_phase = 1
	rig.apply_strike_pose()
	check(prepared > 0 and rig.joints.arm_R.rotation.x < -1,"Zaku punch draws back before extending at contact")
	var pilot = scene.unit.rig
	pilot.boost_active = true
	pilot.animate(Vector3(24,0,0),true,0,0.016)
	check(pilot.evade_weight > 0 and pilot.evade_weight < 0.5,"Gundam dodge blends in rather than snapping")
	pilot.boost_active = false
	for i in range(60): pilot.animate(Vector3.ZERO,true,0,0.016)
	check(pilot.evade_weight < 0.01,"Gundam dodge recovers without a stuck pose")
	var attack = preload("res://scripts/attack_clock.gd").new()
	attack.begin(1)
	attack.advance(0.18)
	for i in range(20): preload("res://scripts/saber_trail.gd").spawn(scene.combat,Vector3.ZERO,Vector3.FORWARD,attack)
	check(get_nodes_in_group("saber_trails").size() == 12,"saber ribbons have a hard allocation bound")
	var trail = get_nodes_in_group("saber_trails")[0]
	check(trail.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 24,"swept ribbon builds four connected arc segments")
	await create_timer(0.3).timeout
	check(get_nodes_in_group("saber_trails").is_empty(),"expired ribbons release their nodes")
	scene.queue_free()
	await process_frame
	print("FAILURES ",failures)
	quit(failures)
