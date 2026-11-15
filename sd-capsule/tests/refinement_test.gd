extends SceneTree
const Bolt = preload("res://scripts/enemy_bolt.gd")
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
 scene.combat.ai_enabled = false
 var cover = get_nodes_in_group("breakable_cover")[0]
 var visible_bounds: AABB = cover.model_bounds(cover.visual.get_child(0),Transform3D.IDENTITY)
 check(visible_bounds.size.is_equal_approx(Vector3(3,2.7,2.5)) and absf(visible_bounds.position.y) < 0.001,"cover art matches collision size and ground contact")
 var player = scene.unit
 player.position = Vector3(0,10,5)
 await physics_frame
 var blast = preload("res://scripts/blast_damage.gd")
 var point: Vector3 = player.aim_point()+Vector3(0,0,-2)
 var amount: int = blast.apply(scene,point,player,3.2,20)
 check(amount > 0 and amount < 20 and player.hp == 100-amount,"rocket blast applies distance falloff exactly once")
 player.state.invulnerable = 0
 var before: int = player.hp
 check(blast.apply(scene,point-Vector3(0,0,5),player,3.2,20) == 0 and player.hp == before,"leaving blast radius prevents damage")
 var wall := StaticBody3D.new()
 var collision := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(4,4,0.3)
 collision.shape = box
 wall.add_child(collision)
 scene.add_child(wall)
 wall.position = point+Vector3(0,0,1)
 await physics_frame
 await physics_frame
 check(blast.apply(scene,point,player,3.2,20) == 0 and player.hp == before,"solid cover blocks blast damage")
 var support = scene.combat.targets[2]
 scene.combat.enemy_shot(support,player.aim_point())
 var bolts = scene.combat.get_children().filter(func(n): return n is Bolt)
 check(bolts.size() == 1 and bolts[0].explosive and is_equal_approx(bolts[0].velocity.length(),12),"support fires a slower explosive rocket")
 check(bolts[0].destination.is_equal_approx(player.aim_point()),"rocket commits to the telegraphed location")
 support.rocket_warning.show()
 support.damage(1)
 check(not support.rocket_warning.visible,"stagger cancels rocket warning")
 var pilot = scene.pilot
 pilot.clear()
 pilot.menu_open = false
 var press := InputEventScreenTouch.new()
 press.index = 4
 press.pressed = true
 press.position = preload("res://scripts/control_layout.gd").buttons(root.get_visible_rect().size).fire.get_center()
 pilot._input(press)
 var drag := InputEventScreenDrag.new()
 drag.index = 4
 drag.relative = Vector2(20,-10)
 drag.position = press.position+drag.relative
 pilot._input(drag)
 var command = pilot.sample()
 check(command.fire and command.look == Vector2.ZERO,"fire thumb drag preserves fire without rotating camera")
 press.pressed = false
 pilot._input(press)
 check(not pilot.sample().fire,"fire release clears aim-and-fire ownership")
 scene.queue_free()
 await process_frame
 print("FAILURES ",failures)
 quit(failures)
