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
	var gun_arm: Node3D = rig.hand_socket.get_parent()
	check(rig.weapon.get_parent() == gun_arm,"rifle is physically parented to the hand's arm")
	check(rig.saber.get_parent() == rig.hand_socket,"saber hilt is attached to the hand socket")
	for pose in [0.0,0.13,0.25,0.4]:
		clock.begin(1)
		clock.advance(pose)
		rig.set_attack_pose(clock)
		rig.animate(Vector3(3,0,2),true,pose,0.016)
		var grip_point: Vector3 = rig.saber.to_global(Vector3(0,-0.91,0))
		check(grip_point.distance_to(rig.hand_socket.global_position) < 0.001,"saber grip stays in the hand through attack at " + str(pose))
	var battle = scene.combat
	battle.ai_enabled = false
	battle.cancel_melee()
	battle.melee_cooldown = 0
	for i in range(120): battle.step({"melee":true},1.0/60)
	check(battle.combo == 1 and not battle.attack.running,"holding melee for two seconds performs exactly one swing")
	battle.step({},0.016)
	battle.step({"melee":true},0.016)
	check(battle.attack.running,"release and press starts the next deliberate swing")
	battle.cancel_melee()
	battle.melee_cooldown = 0
	battle.melee_was_held = false
	battle.weapon = 1
	for i in range(120): battle.step({"fire":true},1.0/60)
	check(not battle.attack.running,"holding fire with saber equipped does not repeat swings")
	var pilot = scene.pilot
	pilot.clear()
	pilot.menu_open = false
	var tap := InputEventScreenTouch.new()
	tap.index = 6
	tap.position = preload("res://scripts/control_layout.gd").buttons(root.get_visible_rect().size).melee.get_center()
	tap.pressed = true
	pilot._input(tap)
	tap.pressed = false
	pilot._input(tap)
	check(pilot.sample().melee,"quick touch tap survives press and release between physics ticks")
	check(not pilot.sample().melee,"quick touch tap is consumed exactly once")
	scene.queue_free()
	await process_frame
	print("FAILURES ",failures)
	quit(failures)
