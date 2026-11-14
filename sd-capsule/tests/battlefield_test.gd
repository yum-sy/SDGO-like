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
	current_scene = scene
	await physics_frame
	await physics_frame
	scene.set_physics_process(false)
	var dust = preload("res://scripts/ground_fx.gd")
	for i in range(20): dust.spawn(scene,Vector3(7,0,5))
	check(get_nodes_in_group("ground_fx").size() == 8,"ground effects enforce an eight-effect cap")
	var effect = get_nodes_in_group("ground_fx")[0]
	check(effect.global_position.is_equal_approx(Vector3(7,0.06,5)),"thrust dust originates at the actor ground contact")
	scene.mode = "paused"
	var before: float = effect.age
	await create_timer(0.1).timeout
	check(effect.age == before,"paused ground dust preserves its animation time")
	scene.mode = "playing"
	await create_timer(0.5).timeout
	check(get_nodes_in_group("ground_fx").is_empty(),"ground dust releases nodes after its short lifetime")
	var explosion = preload("res://scripts/combat_fx.gd").spawn(scene,Vector3(2,1,2),Color.ORANGE,2)
	check(explosion.smoke.size() == 4 and explosion.fragments.size() == 16,"destruction layers four smoke puffs under sixteen sparks")
	var impact = preload("res://scripts/combat_fx.gd").spawn(scene,Vector3.ZERO,Color.WHITE,1)
	check(impact.smoke.is_empty(),"ordinary hits do not allocate destruction smoke")
	await create_timer(1.1).timeout
	check(get_nodes_in_group("combat_fx").is_empty(),"layered destruction effects expire completely")
	var command := {"look":Vector2.ZERO,"move":Vector2.ZERO,"dash":false,"boost":false,"jump":false}
	scene.unit.velocity = Vector3.ZERO
	var phase: float = scene.unit.animation_time
	scene.unit.simulate(command,0.016)
	check(is_equal_approx(phase,scene.unit.animation_time),"stationary Gundam does not advance its walking cycle")
	command.move = Vector2.RIGHT
	scene.unit.simulate(command,0.1)
	check(scene.unit.animation_time > phase,"walking cycle advances with actual movement speed")
	scene.queue_free()
	await process_frame
	print("FAILURES ",failures)
	quit(failures)
