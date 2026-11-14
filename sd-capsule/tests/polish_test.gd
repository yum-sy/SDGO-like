extends SceneTree
var failures := 0
func check(value: bool, description: String) -> void:
	if value: print("PASS ",description)
	else:
		failures += 1
		push_error(description)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	scene.set_physics_process(false)
	var enemy = scene.combat.targets[0]
	check(enemy.hp == 180 and enemy.max_hp == 180,"combat encounter uses tougher 180HP opponents")
	var rig = enemy.model
	check(rig.joints.size() == 6,"Zaku has six independently articulated regions")
	var mesh_count := 0
	for joint in rig.joints.values(): mesh_count += joint.get_child_count()
	check(mesh_count == 58,"all 58 Zaku material-region meshes attached once")
	rig.animate(Vector3(3,0,0),0,false,0.1)
	check(absf(rig.joints.leg_L.rotation.x) > 0.1 and is_equal_approx(rig.joints.leg_L.rotation.x,-rig.joints.leg_R.rotation.x),"moving Zaku alternates legs")
	rig.fire()
	rig.animate(Vector3.ZERO,0,false,0.016)
	check(rig.recoil > 0 and rig.joints.arm_L.rotation.x > 0,"Zaku shot drives arm recoil")
	enemy.damage(25)
	check(rig.hurt > 0 and enemy.windup == 0,"damage interrupts attack and triggers visual stagger")
	var pilot_rig = scene.unit.rig
	scene.combat.step({"weapon":true},0.016)
	pilot_rig.animate(Vector3.ZERO,true,0,0.016)
	check(pilot_rig.saber.visible and not pilot_rig.weapon.visible,"saber remains equipped between swings")
	pilot_rig.boost_active = true
	pilot_rig.animate(Vector3.ZERO,false,1,0.016)
	check(pilot_rig.thrusters.all(func(mesh): return mesh.visible),"boost displays both engine plumes")
	pilot_rig.boost_active = false
	pilot_rig.animate(Vector3.ZERO,true,1,0.016)
	check(pilot_rig.thrusters.all(func(mesh): return not mesh.visible),"engine plumes stop when boost ends")
	var attacker = scene.combat.targets[1]
	scene.unit.position = Vector3(0,0,0)
	attacker.position = Vector3(0,0,-2)
	attacker.cooldown = 0
	await physics_frame
	await physics_frame
	attacker.step(scene.unit,scene.combat,0.016)
	check(attacker.attack_kind == "melee" and attacker.windup > 0,"close enemy telegraphs melee before dealing damage")
	attacker.windup = 0.01
	attacker.step(scene.unit,scene.combat,0.016)
	check(scene.unit.hp == 88,"telegraphed close attack deals damage on contact")
	scene.unit.state.invulnerable = 0
	scene.unit.position = Vector3(0,0,10)
	attacker.attack_kind = "melee"
	attacker.windup = 0.01
	attacker.step(scene.unit,scene.combat,0.016)
	check(scene.unit.hp == 88,"escaping melee range avoids enemy strike")
	enemy.damage(200)
	check(rig.dying and rig.visible and enemy.collision_layer == 0,"destroyed Zaku animates with collision disabled")
	rig.animate(Vector3.ZERO,0,false,0.7)
	check(not rig.visible,"death animation completes and removes visual")
	var fx = preload("res://scripts/combat_fx.gd")
	for i in range(40): fx.spawn(scene,Vector3.ZERO,Color.WHITE)
	check(get_nodes_in_group("combat_fx").size() <= 24,"impact effects have a fixed concurrency bound")
	await create_timer(0.9).timeout
	check(get_nodes_in_group("combat_fx").is_empty(),"impact effects expire without accumulating nodes")
	scene.queue_free()
	await create_timer(0.15).timeout
	print("FAILURES ",failures)
	quit(failures)
