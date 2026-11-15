extends SceneTree
# Run without --headless: renders a reproducible geometry review artifact.
# -- --yaw=25 --output=/absolute/path.png
var output := "res://evidence/head-review.png"
var yaw := 0.0
func _initialize(): call_deferred('run')
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--yaw="): yaw = deg_to_rad(float(arg.trim_prefix("--yaw=")))
  if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
 root.size = Vector2i(900,900)
 var world := Node3D.new()
 root.add_child(world)
 var model = load('res://assets/prepared/rx78.scn').instantiate()
 world.add_child(model)
 for part in model.get_children():
  if not 'head' in str(part.name): part.hide()
 preload("res://scripts/mecha_finish.gd").apply(model,true)
 preload("res://scripts/gundam_details.gd").build(model)
 var cam := Camera3D.new()
 world.add_child(cam)
 cam.projection = Camera3D.PROJECTION_ORTHOGONAL
 cam.size = 1.22
 cam.position = Vector3(-0.111+3*sin(yaw),1.56,3*cos(yaw))
 cam.look_at(Vector3(-0.111,1.56,0))
 var light := DirectionalLight3D.new()
 world.add_child(light)
 light.rotation_degrees = Vector3(-30,-25,0)
 light.light_energy = 0.85
 var env := WorldEnvironment.new()
 world.add_child(env)
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_COLOR
 env.environment.background_color = Color('172536')
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color.WHITE
 env.environment.ambient_light_energy = 0.25
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output)
 quit()
