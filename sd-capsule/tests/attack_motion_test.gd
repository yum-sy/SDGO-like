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
	var rig = scene.unit.rig
	var clock = preload("res://scripts/attack_clock.gd").new()
	clock.begin(3)
	rig.set_attack_pose(clock)
	check(rig.attack_weight == 0,"heavy attack starts from neutral rather than snapping into brace")
	clock.advance(0.23)
	rig.set_attack_pose(clock)
	rig.animate(Vector3.ZERO,true,0,0.1)
	check(rig.attack_weight == 1 and rig.position.y < -0.07,"third strike plants the body into a heavier stance")
	var shield_braced := false
	for key in rig.joints:
		if "armor_shield" in key: shield_braced = rig.joints[key].rotation.x < -0.2
	check(shield_braced,"shield arm counterbalances the committed saber strike")
	clock.advance(1)
	clock.finish_tick()
	rig.set_attack_pose(clock)
	for i in range(60): rig.animate(Vector3.ZERO,true,0,0.016)
	check(rig.attack_weight == 0 and absf(rig.position.y) < 0.01,"finished combo releases the braced stance")
	rig.fire()
	rig.animate(Vector3.ZERO,true,0,0.016)
	var displaced := false
	for key in rig.joints:
		if "armor_gun" in key: displaced = rig.joints[key].position.distance_to(rig.joint_rest[key]) > 0.04
	check(displaced,"rifle recoil moves the shared weapon shoulder backward")
	for i in range(60): rig.animate(Vector3.ZERO,true,0,0.016)
	check(rig.joints.keys().all(func(k): return rig.joints[k].position.is_equal_approx(rig.joint_rest[k])),"recoil returns every limb and weapon to its original pivot")
	scene.queue_free()
	await process_frame
	print("FAILURES ",failures)
	quit(failures)
