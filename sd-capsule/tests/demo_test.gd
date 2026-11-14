extends SceneTree
var failures := 0
func check(value: bool, description: String) -> void:
	if value: print("PASS ",description)
	else:
		failures += 1
		push_error(description)
func touch(pilot: Node, id: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = position
	event.pressed = pressed
	pilot._input(event)
func drag(pilot: Node, id: int, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = position
	event.relative = relative
	pilot._input(event)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	scene.set_physics_process(false)
	# Fixed 100HP fixture isolates weapon arithmetic from encounter tuning.
	for enemy in scene.combat.targets: enemy.hp = 100
	var battle = scene.combat
	battle.ai_enabled = false
	var player = scene.unit
	player.position = Vector3(0,0,2.4)
	var target = battle.targets[0]
	target.position = Vector3.ZERO
	scene.update_camera()
	await physics_frame
	await physics_frame
	battle.update_target(false)
	check(battle.selected == target,"close target acquired for melee")
	for i in range(3):
		battle.step({"melee":true},0.016)
		for tick in range(45): battle.step({},1.0/60.0)
	check(target.hp == 0 and battle.combo == 3,"three-hit saber combo defeats 100HP target")
	check(target.knockback.length() > 8,"finisher applies knockback")
	check(player.rig.joints.size() >= 8,"rigid-part joints prepared")
	player.damage(8)
	player.damage(8)
	check(player.hp == 92,"damage invulnerability prevents simultaneous stacking")
	var command := {"move":Vector2(0,-1),"look":Vector2.ZERO,"jump":false,"boost":false,"dash":true}
	player.booster = 100
	player.simulate(command,0.016)
	check(player.dash_left>0 and player.booster < 80,"directional dash consumes boost")
	player.position.y = 3
	player.booster = 0
	command.boost = true
	command.dash = false
	player.simulate(command,0.016)
	check(player.state.boost_locked,"depleted boost locks until recharge")
	player.booster = 30
	player.simulate(command,0.016)
	check(not player.state.boost_locked,"boost unlocks after threshold")
	var pilot = scene.pilot
	pilot.menu_open = false
	var size := root.get_visible_rect().size
	var layout = preload("res://scripts/control_layout.gd").buttons(size)
	touch(pilot,0,Vector2(100,size.y-100),true)
	touch(pilot,1,layout.fire.get_center(),true)
	touch(pilot,2,Vector2(size.x*0.55,size.y*0.4),true)
	drag(pilot,0,Vector2(140,size.y-130),Vector2(40,-30))
	drag(pilot,2,Vector2(size.x*0.55+20,size.y*0.4),Vector2(20,0))
	var sampled: Dictionary = pilot.sample()
	check(sampled.fire and sampled.move.length()>0 and sampled.look.length()>0,"move + fire + camera multi-touch coexist")
	touch(pilot,1,layout.fire.get_center(),false)
	sampled = pilot.sample()
	check(not sampled.fire and sampled.move.length()>0,"releasing fire preserves joystick")
	pilot.clear()
	check(pilot.stick_id == -1 and pilot.look_id == -1 and pilot.touches.is_empty(),"focus/pause clears touch ownership")
	var enemy = battle.targets[1]
	enemy.position = Vector3(0,0,-18)
	player.position = Vector3(0,0,5)
	await physics_frame
	var start: Vector3 = enemy.position
	for i in range(40):
		enemy.step(player,battle,1.0/60.0)
		await physics_frame
	check(enemy.position.distance_to(start)>0.5,"AI chases player using physics")
	enemy.damage(1)
	check(enemy.brain.dodge_left>0 and enemy.stun>0,"AI enters evade after hit")
	player.state.invulnerable = 0
	player.damage(200)
	battle.step({},0.016)
	check(battle.lost and not battle.won,"zero player HP produces defeat")
	scene.queue_free()
	await create_timer(0.15).timeout
	print("FAILURES ",failures)
	quit(failures)
