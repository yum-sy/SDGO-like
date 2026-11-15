extends SceneTree
const Details = preload("res://scripts/gundam_details.gd")
var failures := 0
func check(ok: bool, label: String):
 if ok: print("PASS ",label)
 else:
  failures += 1
  push_error(label)
func _initialize(): call_deferred("run")
func run():
 var model = load("res://assets/prepared/rx78.scn").instantiate()
 root.add_child(model)
 var head: MeshInstance3D
 for part in model.get_children():
  if "head" in str(part.name): head = part
 var source: PackedVector3Array = head.mesh.get_faces()
 Details.build(model)
 var eyes = model.get_node("FaceDetails").get_children().filter(func(n): return str(n.name).begins_with("Eye"))
 var height_ok: bool = eyes.size() == 2
 var depth_ok := true
 for eye in eyes:
  for v in eye.mesh.get_faces():
   height_ok = height_ok and v.y > 1.34 and v.y < 1.47
   var surface_z := -10.0
   for i in range(0,source.size(),3):
    var hit = Geometry3D.ray_intersects_triangle(Vector3(v.x,v.y,2),Vector3.FORWARD,source[i],source[i+1],source[i+2])
    if hit != null: surface_z = maxf(surface_z,hit.z)
   depth_ok = depth_ok and absf(v.z-surface_z-0.003) < 0.0002
 check(height_ok,"eye lenses sit in the anatomical recess below brow, not on forehead")
 check(depth_ok,"every lens vertex follows the source recess surface with only 3mm lift")
 var arrays = head.mesh.surface_get_arrays(0)
 var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
 var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
 var indexes = arrays[Mesh.ARRAY_INDEX]
 if indexes == null: indexes = range(verts.size())
 var dark_count := 0
 var painted := true
 for i in range(0,indexes.size(),3):
  var a: int = indexes[i]
  var b: int = indexes[i+1]
  var c: int = indexes[i+2]
  if Details.is_eye_recess(verts[a],verts[b],verts[c]):
   dark_count += 1
   for index in [a,b,c]: painted = painted and colors[index].r < 0.1 and colors[index].b < 0.2
 check(painted and dark_count >= 16,"original cavity triangles are dark-painted, not a floating visor overlay")
 model.queue_free()
 await process_frame
 quit(failures)
