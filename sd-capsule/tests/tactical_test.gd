extends SceneTree
const Clock = preload("res://scripts/attack_clock.gd")
const Arena = preload("res://scripts/arena_layout.gd")
var failures := 0
func check(value: bool, description: String) -> void:
	if value: print("PASS ",description)
	else:
		failures += 1
		push_error(description)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for hz in [30,60,120]:
		var clock := Clock.new()
		clock.begin(1)
		var touched := false
		while clock.running:
			if clock.advance(1.0/hz): touched = touched or clock.intersects(Vector3(0,0,-2.4),Vector3.FORWARD)
			clock.finish_tick()
		check(touched,"swept blade crosses front target at %d Hz" % hz)
	var skip := Clock.new()
	skip.begin(1)
	check(skip.advance(0.3) and skip.intersects(Vector3(0,0,-2.4),Vector3.FORWARD),"frame skip cannot tunnel over active arc")
	check(not skip.intersects(Vector3(0,0,2),Vector3.FORWARD),"blade never hits behind committed facing")
	check(not skip.intersects(Vector3(0,2,-2),Vector3.FORWARD),"vertical separation rejects melee")
	for map_id in range(2):
		var arena := Arena.new()
		arena.index = map_id
		arena.build_navigation()
		var route := arena.path(Vector3(-10,0,-9),Vector3(10,0,-9))
		check(route.size() > 2,"arena %d supplies a route around cover" % map_id)
		var clear := true
		for point in route:
			for rect in arena.footprints: clear = clear and not rect.grow(0.8).has_point(point)
		check(clear,"arena %d route avoids expanded collision footprints" % map_id)
	Arena.selected = 0
	var scene = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	scene.set_physics_process(false)
	var battle = scene.combat
	battle.ai_enabled = false
	var player = scene.unit
	var target = battle.targets[0]
	player.position = Vector3(0,0,2.4)
	target.position = Vector3.ZERO
	for enemy in battle.targets: enemy.hp = 100
	scene.update_camera()
	await physics_frame
	await physics_frame
	battle.update_target(false)
	battle.step({"melee":true},0.016)
	check(target.hp == 100 and battle.attack.stage() == "WINDUP","input starts windup without immediate damage")
	battle.step({},0.08)
	check(target.hp == 100,"windup remains non-damaging")
	battle.step({},0.13)
	check(target.hp == 75,"damage occurs as blade crosses target")
	check(is_equal_approx(player.rig.attack_angle,battle.attack.pose_angle()),"visual blade reads the same authoritative clock")
	for i in range(10): battle.step({},0.01)
	check(target.hp == 75,"one swing cannot damage same target twice")
	battle.step({"melee":true},0.01)
	battle.step({},0.13)
	check(battle.combo == 2 and battle.attack.running,"late recovery input buffers next combo")
	player.damage(8)
	check(not battle.attack.running and player.attack_slow == 1.0,"incoming damage interrupts swing and restores movement")
	battle.step({},0.25)
	target.position = Vector3.ZERO
	battle.step({"melee":true},0.016)
	target.position = Vector3(0,0,-8)
	await physics_frame
	battle.step({},0.3)
	check(target.hp == 75,"moving out before strike avoids committed attack")
	battle.cancel_melee()
	battle.step({},0.3)
	target.position = Vector3.ZERO
	await physics_frame
	battle.selected = target
	battle.step({"melee":true},0.016)
	scene.block(Vector3(6,4,0.3),Vector3(0,2,1),Color.GRAY)
	await physics_frame
	await physics_frame
	battle.step({},0.3)
	check(target.hp == 75,"new obstacle during windup blocks actual strike")
	battle.cancel_melee()
	check(battle.targets[0].role != battle.targets[1].role and battle.targets[1].role != battle.targets[2].role,"encounter assigns three distinct tactical roles")
	var support = battle.targets[2]
	var intent: Dictionary = support.brain.sample(support,player,0.1)
	check(intent.move.length() < 0.1 and intent.fire,"support holds elevated firing position")
	# Clear fixture wall, then validate offscreen acquisition without shooting backward.
	var wall = scene.get_child(scene.get_child_count()-1)
	wall.queue_free()
	await physics_frame
	await physics_frame
	for other in battle.targets: other.hp = 0
	target.hp = 100
	target.position = Vector3(0,0,8)
	player.yaw = 0
	player.focus_yaw = NAN
	scene.update_camera()
	await physics_frame
	await physics_frame
	battle.selected = null
	battle.update_target(true)
	check(battle.selected == target and not is_nan(player.focus_yaw),"manual target switch acquires visible rear enemy and requests camera turn")
	var ammo_before: int = battle.rifle.ammo
	battle.step({"fire":true},0.01)
	check(battle.rifle.ammo == ammo_before,"rifle cannot fire backward during camera acquisition")
	var command := {"move":Vector2.ZERO,"look":Vector2.ZERO,"jump":false,"boost":false,"dash":false}
	for i in range(90): player.simulate(command,1.0/60) # 180-degree turn is now speed-limited.
	check(is_nan(player.focus_yaw) and absf(angle_difference(player.yaw,PI)) < 0.02,"manual camera acquisition converges smoothly")
	player.focus_yaw = 0
	command.look = Vector2(0.1,0)
	player.simulate(command,0.016)
	check(is_nan(player.focus_yaw),"manual mouse movement cancels assisted camera turn")
	player.yaw = 0
	scene.update_camera()
	battle.update_target(false)
	check(battle.selected == null,"cancelling camera assist also releases offscreen lock")
	scene.queue_free()
	await create_timer(0.15).timeout
	print("FAILURES ",failures)
	quit(failures)
