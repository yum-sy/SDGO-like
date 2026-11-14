extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS ",label)
	else:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var gauge = preload("res://scripts/damage_gauge.gd").new()
	gauge.update(0.75,0.016)
	check(gauge.current == 0.75 and gauge.trailing == 1,"damage gauge immediately shows HP and holds lost portion")
	gauge.update(0.75,0)
	check(gauge.hold > 0.2 and gauge.trailing == 1,"paused gauge does not consume its hold")
	for i in range(60): gauge.update(0.75,0.016)
	check(is_equal_approx(gauge.trailing,0.75),"damage trail converges without undershooting actual HP")
	gauge.update(1.0,0.016)
	check(gauge.trailing == 1 and gauge.current == 1,"health restore resets gauge without stale damage")
	var scene = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	scene.set_physics_process(false)
	var enemy = scene.combat.targets[0]
	var warning = enemy.attack_warning
	check(not warning.visible,"idle enemy has no attack warning")
	enemy.melee_facing = Vector3.RIGHT
	enemy.melee_clock.begin(1)
	warning.sync(enemy)
	check(warning.visible and warning.global_basis.z.dot(Vector3.RIGHT) > 0.99,"windup warning follows committed melee facing")
	var vertices: PackedVector3Array = warning.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(Array(vertices).all(func(v): return v.length() <= 2.801 and (v.length() < 0.01 or v.normalized().z >= 0.449)),"warning geometry matches melee reach and cone")
	enemy.melee_clock.advance(0.6)
	warning.sync(enemy)
	check(warning.visible,"warning stays visible during active contact")
	enemy.melee_clock.advance(0.2)
	warning.sync(enemy)
	check(not warning.visible,"recovery removes attack warning")
	enemy.melee_clock.begin(1)
	warning.sync(enemy)
	enemy.damage(25)
	check(not warning.visible and not enemy.melee_clock.running,"stagger cancels both warning and attack authority")
	scene.camera.global_position = scene.unit.aim_point()+Vector3.BACK
	scene.update_player_visibility()
	check(not scene.unit.visual.visible,"compressed camera hides obstructing player geometry")
	scene.camera.global_position = scene.unit.aim_point()+Vector3.BACK*1.7
	scene.update_player_visibility()
	check(not scene.unit.visual.visible,"visibility hysteresis prevents near-camera flicker")
	scene.camera.global_position = scene.unit.aim_point()+Vector3.BACK*3
	scene.update_player_visibility()
	check(scene.unit.visual.visible,"player geometry restores after camera clears cover")
	scene.queue_free()
	await process_frame
	print("FAILURES ",failures)
	quit(failures)
