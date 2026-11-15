extends SceneTree
const Layout = preload("res://scripts/control_layout.gd")
var failures := 0
func check(ok: bool, label: String):
 if ok: print("PASS ",label)
 else:
  failures += 1
  push_error(label)
func touch(pilot, id: int, at: Vector2, down: bool):
 var e := InputEventScreenTouch.new()
 e.index=id; e.position=at; e.pressed=down
 pilot._input(e)
func drag(pilot, id: int, at: Vector2):
 var e := InputEventScreenDrag.new()
 e.index=id; e.position=at
 e.relative=Vector2(999,-999) # Deliberately bogus cross-finger relative data.
 pilot._input(e)
func _initialize(): call_deferred("run")
func run():
 var game = preload("res://main.tscn").instantiate()
 root.add_child(game)
 await physics_frame
 game.set_physics_process(false)
 game.combat.ai_enabled=false
 var p=game.pilot
 p.clear(); p.menu_open=false
 var size=root.get_visible_rect().size
 var fire: Vector2=Layout.buttons(size).fire.get_center()
 var boost: Vector2=Layout.buttons(size).boost.get_center()
 var free:=Vector2(size.x*0.5,size.y*0.4)
 touch(p,1,fire,true)
 drag(p,1,fire+Vector2(3,0))
 var command=p.sample()
 check(command.fire and command.look==Vector2.ZERO,"fire thumb jitter does not steal camera or cancel target turn")
 touch(p,2,free,true)
 drag(p,2,free+Vector2(30,0))
 command=p.sample()
 check(p.camera_touch_id==2 and command.look.x>0 and command.look.y==0,"camera uses owning finger positions, not inconsistent relative events")
 touch(p,3,boost,true)
 drag(p,1,fire+Vector2(-40,20))
 drag(p,3,boost+Vector2(40,-20))
 command=p.sample()
 check(command.fire and command.boost and command.look==Vector2.ZERO,"fire and boost cannot add conflicting rotation while another finger aims")
 var mouse:=InputEventMouseMotion.new()
 mouse.relative=Vector2(100,100)
 p.left_down=true; p._input(mouse)
 check(p.sample().look==Vector2.ZERO,"compatibility mouse events cannot double mobile rotation")
 p.left_down=false
 touch(p,2,free+Vector2(30,0),false)
 drag(p,1,fire+Vector2(-42,20))
 check(p.sample().look==Vector2.ZERO,"camera handoff discards movement accumulated by other fingers")
 drag(p,1,fire+Vector2(-62,20))
 check(p.sample().look==Vector2.ZERO and p.camera_touch_id==-1,"fire finger never takes over camera after look finger releases")
 drag(p,1,fire+Vector2(-62,-size.y))
 check(p.sample().look==Vector2.ZERO,"discontinuous touch coordinates do not spin camera")
 p.clear()
 touch(p,0,Vector2(120,size.y-120),true)
 touch(p,1,Vector2(140,size.y-140),true)
 drag(p,1,Vector2(180,size.y-140))
 check(p.sample().look==Vector2.ZERO,"second touch in joystick region never becomes a camera gesture")
 p.clear()
 game.unit.yaw=0
 game.unit.focus_yaw=PI
 var idle={"move":Vector2.ZERO,"look":Vector2.ZERO,"jump":false,"boost":false,"dash":false}
 game.unit.simulate(idle,1.0/60)
 check(absf(game.unit.yaw)<=3.0/60+0.0001,"target recenter has a bounded angular speed instead of a sudden turn")
 idle.look=Vector2(0.08,0)
 game.unit.simulate(idle,1.0/60)
 game.combat.step({"look":Vector2(0.08,0),"cycle":true},1.0/60)
 check(is_nan(game.unit.focus_yaw),"intentional drag wins over target recenter even in the same tick")
 idle.look=Vector2(100,-100)
 idle.touch_look=true
 var before_yaw: float=game.unit.yaw
 var before_pitch: float=game.unit.pitch
 game.unit.simulate(idle,1.0/60)
 var angular_step:=Vector2(game.unit.yaw-before_yaw,game.unit.pitch-before_pitch).length()
 print("CAMERA burst angular step degrees: ",rad_to_deg(angular_step))
 check(angular_step<=PI/60+0.0001,"coalesced touch burst cannot rotate more than 3 degrees per 60Hz tick")
 idle.look=Vector2.ZERO
 before_yaw=game.unit.yaw
 game.unit.simulate(idle,1.0/60)
 check(is_equal_approx(game.unit.yaw,before_yaw),"no camera backlog remains when touch stops")
 var yaw: float=game.unit.yaw
 var pitch: float=game.unit.pitch
 for i in range(30):
  game.combat.selected=null
  game.combat.update_target(false)
  game.unit.visual.rotation.y+=0.2
  game.update_camera(1.0/60)
 check(is_equal_approx(game.unit.yaw,yaw) and is_equal_approx(game.unit.pitch,pitch) and absf(angle_difference(game.pivot.rotation.y,yaw))<0.0001,"automatic target selection and unit facing never rewrite camera orientation")
 p.clear()
 check(p.camera_touch_id==-1 and p.touch_positions.is_empty(),"suspend clears camera owner and gesture history")
 game.queue_free()
 await process_frame
 quit(failures)
