extends SceneTree
var failures := 0
func check(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error(description)
	else:
		print("PASS ", description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	await physics_frame
	scene.set_physics_process(false)
	# Fixed 100HP fixture isolates weapon arithmetic from encounter tuning.
	for i in range(3):
		scene.combat.targets[i].hp = 100
		scene.combat.targets[i].position = Vector3((i-1)*4,0,-10)
	await physics_frame
	await physics_frame
	var combat = scene.combat
	combat.ai_enabled = false
	combat.update_target(false)
	check(combat.selected != null, "visible target acquired")
	var original = combat.selected
	combat.update_target(true)
	check(combat.selected != original, "Tab cycles eligible targets")
	var target = combat.selected
	scene.unit.yaw = scene.unit.focus_yaw
	scene.unit.focus_yaw = NAN
	scene.update_camera()
	combat.step({"fire":true,"reload":false,"cycle":false}, 0.01)
	check(target.hp == 75 and combat.rifle.ammo == 5, "ray hits target and consumes one round")
	combat.step({"fire":true,"reload":false,"cycle":false}, 0.01)
	check(target.hp == 75 and combat.rifle.ammo == 5, "cooldown prevents duplicate shot")
	combat.rifle.reload()
	combat.step({"fire":true,"reload":false,"cycle":false}, 0.5)
	check(target.hp == 75 and combat.rifle.ammo == 5, "reload blocks fire")
	combat.rifle.tick(2)
	check(combat.rifle.ammo == 6 and combat.rifle.reload_left == 0, "manual reload restores magazine")
	scene.block(Vector3(30,10,1),Vector3(0,5,-5),Color.GRAY)
	var wall = scene.get_child(scene.get_child_count()-1)
	await physics_frame
	await physics_frame
	combat.update_target(false)
	check(combat.selected == null, "wall prevents target lock")
	combat.step({"fire":true,"reload":false,"cycle":false}, 1)
	check(target.hp == 75, "wall absorbs shot without damaging target")
	wall.queue_free()
	await physics_frame
	await physics_frame
	var saved: Vector3 = scene.unit.position
	scene.unit.position = Vector3(0,0,60)
	combat.update_target(false)
	check(combat.selected == null, "targets outside range rejected")
	scene.unit.position = saved
	var auto_reload_seen := false
	for i in range(120):
		combat.step({"fire":true,"reload":false,"cycle":false}, 0.1)
		if combat.rifle.ammo == 0 and combat.rifle.reload_left > 0:
			auto_reload_seen = true
	check(auto_reload_seen, "empty magazine auto reloads")
	check(combat.won and combat.kills == 3, "three targets defeated and victory reached")
	combat.targets[0].damage(25)
	check(combat.kills == 3, "dead target cannot count twice")
	var remaining: int = combat.rifle.ammo
	combat.step({"fire":true,"reload":false,"cycle":false}, 0.01)
	check(combat.rifle.ammo == remaining, "victory blocks further firing")
	scene.queue_free()
	await create_timer(0.15).timeout
	print("FAILURES ",failures)
	quit(failures)
