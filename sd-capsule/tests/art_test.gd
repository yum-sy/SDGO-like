extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
 if ok: print("PASS ",label)
 else:
  failures += 1
  push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = preload("res://main.tscn").instantiate()
 root.add_child(game)
 await physics_frame
 await physics_frame
 game.set_physics_process(false)
 var rig = game.unit.rig
 check(rig.elbows.size() == 2,"both Gundam arms have articulated elbows")
 check(rig.hand_socket.get_parent() == rig.elbows[rig.gun_side],"weapon hand follows the articulated forearm")
 rig.fire()
 rig.animate(Vector3.ZERO,true,0,0.1)
 check(rig.elbows[rig.gun_side].rotation.x < -0.2,"rifle aiming flexes the elbow")
 for i in range(120): rig.animate(Vector3.ZERO,true,0,0.016)
 check(absf(rig.elbows[rig.gun_side].rotation.x+0.14) < 0.01,"elbow recovers without pose accumulation")
 var source = preload("res://assets/prepared/rx78.scn").instantiate()
 var raw = source.get_child(0).get_active_material(0)
 var painted = rig.weapon.get_active_material(0)
 check(painted != raw and painted.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON,"armor finish uses a separate toon material")
 check(raw.diffuse_mode != BaseMaterial3D.DIFFUSE_TOON,"source asset material stays unmodified")
 source.free()
 for arena_id in [0,1]:
  var dressing = preload("res://scripts/battlefield_dressing.gd").new()
  game.add_child(dressing)
  dressing.build(game,arena_id)
  check(dressing.get_child_count() < 20,"arena decoration stays under 20 palette batches: "+str(arena_id))
  check(dressing.get_children().all(func(n): return n is MeshInstance3D and n.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF),"decoration has no collision or shadow passes: "+str(arena_id))
  dressing.queue_free()
 game.queue_free()
 await process_frame
 print("FAILURES ",failures)
 quit(failures)
