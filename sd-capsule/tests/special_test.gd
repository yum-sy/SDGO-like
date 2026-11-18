extends SceneTree
var failures := 0
func check(ok: bool,label: String):
	if ok: print("PASS ",label)
	else:
		failures += 1
		push_error(label)
func _initialize(): call_deferred("run")
func run():
	for hz in [30,60,120]:
		var sp = preload("res://scripts/special_attack.gd").new()
		check(not sp.begin(),"empty gauge rejects special at %d Hz" % hz)
		sp.gain(100)
		check(sp.begin() and not sp.begin(),"gauge consumed exactly once")
		var count := 0
		while sp.running:
			count += sp.advance(1.0/hz)
			sp.gain(50)
		check(count == 10,"exactly ten damage pulses at %d Hz" % hz)
		# Gain only becomes available again after recovery ends.
		check(sp.gauge == 50,"active special cannot refill itself")
	var game = preload("res://main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	game.set_process(false)
	var c = game.combat
	c.ai_enabled = false
	game.unit.position = Vector3(0,0,5)
	for i in range(3): c.targets[i].position = Vector3(12+i*3,0,-10)
	var target = c.targets[0]
	target.position = Vector3(0,0,-4)
	target.hp = 500
	await physics_frame
	await physics_frame
	c.special.gain(50); c.special.gain(50)
	check(c.special.gauge == 100,"two kill awards guarantee readiness")
	c.selected = target
	check(c.start_special() and game.unit.special_locked,"special locks movement")
	c.special_origin = game.unit.aim_point()+Vector3.UP*0.2
	c.special_direction = Vector3.FORWARD
	c.advance_special(0.6)
	check(target.hp == 500,"windup never damages target")
	check(game.unit.rig.heavy_rifle.visible and not game.unit.rig.weapon.visible and not game.unit.rig.saber.visible,"weapon 03 replaces normal weapons during charge")
	check(c.special_origin.distance_to(game.unit.rig.heavy_rifle.muzzle.global_position)<0.001,"beam starts at heavy rifle muzzle")
	check(game.unit.rig.heavy_rifle.global_position.distance_to(game.unit.rig.hand_socket.global_position)<0.001,"heavy rifle grip remains attached to hand")
	check(game.unit.rig.special_raise > 0.99 and game.unit.rig.special_kick == 0,"weapon raised before discharge without premature recoil")
	check(c.special_visual.charge_ring.visible,"charge ring concentrates at muzzle")
	c.advance_special(0.07)
	check(game.unit.rig.special_kick > 0.5,"discharge starts with a strong recoil impulse")
	for i in range(120): c.advance_special(1.0/60)
	check(target.hp == 260,"full beam deals 240 damage")
	check(not game.unit.special_locked and not c.special_visual.visible,"recovery restores movement and removes beam")
	check(not game.unit.rig.heavy_rifle.visible and game.unit.rig.weapon.visible,"recovery restores normal rifle")
	check(c.special.gauge == 0,"beam damage does not recharge SP")
	c.special.gain(100)
	game.block(Vector3(5,5,1),Vector3(0,2,-1),Color.GRAY)
	await physics_frame
	await physics_frame
	c.start_special()
	c.special_origin = game.unit.aim_point()+Vector3.UP*0.2
	c.special_direction = Vector3.FORWARD
	for i in range(150): c.advance_special(1.0/60)
	check(target.hp == 260,"solid cover blocks beam damage")
	c.special.gauge = 0
	game.unit.state.invulnerable = 0
	game.unit.damage(8)
	c.step({},0.01)
	check(c.special.gauge == 12,"actual eight damage grants twelve gauge")
	c.step({},0.01)
	check(c.special.gauge == 12,"same damage cannot be counted twice")
	c.special.gain(100)
	c.start_special()
	c.finish_special()
	check(not game.unit.special_locked and not c.special.running,"cancel cleans up movement lock")
	# Exercise pause through the actual gameplay loop, including input clearing.
	c.special.gain(100)
	c.start_special()
	game.mode = "paused"
	var clock_before: float = c.special.elapsed
	game._physics_process(0.5)
	check(c.special.elapsed == clock_before,"pause freezes special clock")
	c.finish_special()
	c.won = false
	c.kills = 2
	for enemy in c.targets: enemy.hp = 0
	target.hp = 24
	c.special.gain(100)
	c.start_special()
	target.damage(24,"special")
	check(c.won and not game.unit.special_locked and not c.special_visual.visible,"last kill during special cleans up beam and movement lock")
	var layout = preload("res://scripts/control_layout.gd")
	for size in [Vector2(1280,720),Vector2(1558,720)]:
		var buttons = layout.buttons(size)
		for key in buttons:
			if key != "special": check(not buttons.special.intersects(buttons[key]),"SP does not overlap "+key)
	game.pilot.clear()
	game.pilot.menu_open = false
	var tap := InputEventScreenTouch.new()
	tap.index = 4
	tap.pressed = true
	tap.position = layout.buttons(root.get_visible_rect().size).special.get_center()
	game.pilot._input(tap)
	check(game.pilot.sample().special,"SP touch button emits activation")
	check(not game.pilot.sample().special,"held SP touch cannot repeat activation")
	var drag := InputEventScreenDrag.new()
	drag.index = 4
	drag.position = tap.position+Vector2(30,0)
	game.pilot._input(drag)
	check(game.pilot.sample().look == Vector2.ZERO,"SP button drag never rotates camera")
	game.queue_free()
	await process_frame
	quit(failures)
