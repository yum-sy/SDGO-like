extends SceneTree
var failures := 0
func check(ok: bool, label: String):
 if ok: print("PASS ",label)
 else:
  failures += 1
  push_error(label)
func _initialize(): call_deferred("run")
func run():
 var game = preload("res://main.tscn").instantiate()
 root.add_child(game)
 await physics_frame
 game.set_physics_process(false)
 var pilot = game.pilot
 pilot.menu_open = false
 var at := Vector2(150,root.get_visible_rect().size.y-150)
 var press := InputEventScreenTouch.new()
 press.index = 0
 press.position = at
 press.pressed = true
 pilot._input(press)
 var drag := InputEventScreenDrag.new()
 drag.index = 0
 drag.position = at+Vector2(4,0)
 pilot._input(drag)
 check(pilot.sample().move == Vector2.ZERO,"thumb jitter inside dead zone does not move unit")
 drag.position = at+Vector2(80,0)
 pilot._input(drag)
 check(is_equal_approx(pilot.sample().move.x,1),"full joystick travel reaches full speed")
 press.index = 1
 press.position = preload("res://scripts/control_layout.gd").buttons(root.get_visible_rect().size).boost.get_center()
 pilot._input(press)
 drag.index = 1
 drag.relative = Vector2(30,0)
 drag.position = press.position+drag.relative
 pilot._input(drag)
 var command = pilot.sample()
 check(command.boost and command.look.x > 0 and command.move.x > 0,"move boost and camera remain independent simultaneous touches")
 pilot._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 command = pilot.sample()
 check(not command.boost and command.move == Vector2.ZERO and command.look == Vector2.ZERO and command.suspend,"backgrounding clears all input and requests pause")
 pilot._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
 command = pilot.sample()
 check(not command.boost and command.move == Vector2.ZERO,"returning to foreground does not replay held touch")
 var model = load("res://assets/prepared/rx78.scn").instantiate()
 var feet = model.get_children().filter(func(n): return "leg_" in str(n.name))[0]
 var colors: PackedColorArray = feet.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
 check(colors.has(Color("c83443")) and colors.has(Color("d5dfe7")) and colors.has(Color("293c50")),"boots retain red armor white shins and dark soles in baked mesh")
 game.low_quality = true
 game.apply_quality()
 check(not game.key_light.shadow_enabled and game.get_viewport().msaa_3d == Viewport.MSAA_DISABLED,"mobile low preset removes shadow and MSAA cost")
 model.free()
 game.queue_free()
 await process_frame
 quit(failures)
