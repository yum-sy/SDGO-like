extends SceneTree
const Layout = preload("res://scripts/control_layout.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS ",label)
	else:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for screen in [Vector2(1280,720),Vector2(1558,720)]:
		var buttons := Layout.menu_buttons(screen)
		var valid := true
		for key in buttons:
			valid = valid and Rect2(Vector2.ZERO,screen).encloses(buttons[key])
			for other in buttons:
				if key != other: valid = valid and not buttons[key].intersects(buttons[other])
		check(valid,"showcase buttons fit without overlap at %s" % screen)
		check(not Layout.buttons(screen).pause.intersects(Rect2(screen.x-290,14,266,64)),"touch pause stays below mission card at %s" % screen)
	var flow = preload("res://scripts/showcase_flow.gd").new()
	check(flow.moved == 0 and not flow.fired,"coaching starts without completed actions")
	flow.observe({"move":Vector2.RIGHT,"fire":true,"dash":true,"melee":true},0.5)
	check(flow.moved >= 0.4 and flow.fired and flow.dashed and flow.slashed,"coaching tracks independent player actions")
	var scene = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await process_frame
	scene._process(0.1)
	check(scene.camera.top_level and scene.menu_camera,"ready screen frames the real 3D unit with a showcase camera")
	scene.set_physics_process(false)
	scene.pilot.clear()
	scene.pilot.menu_press(Vector2(900,300))
	check(not scene.pilot.sample().restart,"clicking showcase background cannot accidentally launch")
	scene.pilot.menu_press(Layout.menu_buttons(root.get_visible_rect().size).restart.get_center())
	scene._physics_process(0.016)
	check(scene.mode == "playing" and not scene.camera.top_level and not scene.menu_camera,"launch button restores gameplay camera and starts the sortie")
	check(is_equal_approx(scene.camera.fov,65) and scene.camera.h_offset == 0,"launch restores aiming projection without showcase offset")
	scene.mode = "paused"
	scene.overlay_open = true
	scene.pilot.queued.restart = true
	scene._physics_process(0.016)
	check(scene.mode == "paused","guide dialog cannot accidentally resume combat with Enter")
	scene.overlay_open = false
	scene.mode = "playing"
	scene.combat.elapsed = 26
	check(scene.coaching.hint(scene.combat,false).is_empty(),"coaching automatically clears after the opening segment")
	scene.combat.elapsed = 0
	scene.combat.ai_enabled = false
	scene.unit.position = Vector3(0,0,5)
	scene.combat.targets[0].position = Vector3(0,0,-5)
	for i in [1,2]: scene.combat.targets[i].hp = 0
	scene.block(Vector3(6,4,1),Vector3(0,2,0),Color.GRAY)
	scene.update_camera()
	await physics_frame
	await physics_frame
	scene.combat.update_target(true)
	check(not is_nan(scene.unit.focus_yaw) and scene.combat.selected == null,"target cycle locates an occluded enemy without granting a wall lock")
	var hp: int = scene.combat.targets[0].hp
	scene.combat.step({"fire":true},0.016)
	check(scene.combat.targets[0].hp == hp,"occluded target search cannot cause through-wall damage")
	check("COVER" in scene.combat.notice,"blocked target produces an actionable reposition notice")
	scene.queue_free()
	await process_frame
	print("FAILURES ",failures)
	quit(failures)
