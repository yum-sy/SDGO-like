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
	var player = scene.unit
	var assault = scene.combat.targets[0]
	var flanker = scene.combat.targets[1]
	var support = scene.combat.targets[2]
	player.position = Vector3.ZERO
	assault.position = Vector3(0,0,-3)
	assault.cooldown = 1
	assault.brain.sample(assault,player,0.016)
	check(assault.brain.state == "CIRCLE","assault creates spacing while its attack recharges")
	assault.cooldown = 0
	var attack_intent: Dictionary = assault.brain.sample(assault,player,0.016)
	check(assault.brain.state != "CIRCLE","assault returns to approach when attack is ready")
	flanker.position = Vector3(0,0,-5)
	flanker.brain.sample(flanker,player,0.016)
	check(flanker.brain.retreating,"flanker retreats when player closes to five meters")
	flanker.position.z = -7
	flanker.brain.sample(flanker,player,0.016)
	check(flanker.brain.retreating,"retreat hysteresis prevents range-boundary oscillation")
	flanker.position.z = -10
	flanker.brain.sample(flanker,player,0.016)
	check(not flanker.brain.retreating,"flanker resumes flanking after recovering safe distance")
	flanker.brain.evade()
	var evade_intent: Dictionary = flanker.brain.sample(flanker,player,0.016)
	check(not evade_intent.fire,"evasion cannot start a new attack")
	support.brain.line_of_sight = false
	var support_intent: Dictionary = support.brain.sample(support,player,0.9)
	check(support.brain.state == "REPOSITION" and support_intent.move.length() > 0,"blocked support seeks a different firing angle")
	check(absf(support.brain.support_offset.x) <= 1.7 and support.brain.support_offset.z == 0,"support reposition remains within its raised deck")
	support.brain.line_of_sight = true
	support_intent = support.brain.sample(support,player,0.016)
	check(support.brain.state == "AIM" and support_intent.move.length() < 0.1,"support holds position once sight is restored")
	player.visual.rotation.y = 0
	player.rig.fire()
	var command := {"move":Vector2.RIGHT,"look":Vector2.ZERO,"dash":false,"boost":false,"jump":false}
	player.simulate(command,0.016)
	check(is_zero_approx(player.visual.rotation.y),"moving sideways preserves active rifle facing")
	player.rig.aim_left = 0
	player.simulate(command,0.016)
	check(absf(player.visual.rotation.y) > 0.05,"movement facing resumes after rifle stance expires")
	player.rig.swing_left = 1
	player.rig.attack_angle = 1
	player.rig.boost_active = false
	player.rig.hurt = 0
	for i in range(120): player.rig.animate(Vector3.ZERO,true,0,1.0/120)
	check(absf(player.rig.rotation.z) < 0.13,"saber body lean stays bounded across repeated animation frames")
	scene.queue_free()
	await process_frame
	print("FAILURES ",failures)
	quit(failures)
