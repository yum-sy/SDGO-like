extends RefCounted
# Additive, low-poly markings. Original licensed source mesh stays untouched.
static func build(rig: Node3D) -> void:
 var kit = preload("res://scripts/weapon_kit.gd")
 var head: MeshInstance3D
 for part in rig.get_children():
  if part is MeshInstance3D and "head" in str(part.name): head = part
 var faces: PackedVector3Array = head.mesh.get_faces()
 var face := Node3D.new()
 face.name = "FaceDetails"
 rig.add_child(face)
 # The actual recessed eye backing is y=1.33..1.518, behind the brow.
 # Earlier markings at y=1.57 were on the forehead, not in this cavity.
 var recess := PackedVector3Array()
 for i in range(0,faces.size(),3):
  if is_eye_recess(faces[i],faces[i+1],faces[i+2]):
   recess.append_array(PackedVector3Array([faces[i],faces[i+1],faces[i+2]]))
 for side in [-1,1]:
  var eye_x: float = -0.1114+side*0.132
  face_patch(face,recess,"Eye"+str(side),Vector2(eye_x,1.404),Vector2(0.205,0.055),side*0.22,Color("ffdf35"),0.003,true)
  face_patch(face,faces,"MaskVent"+str(side),Vector2(-0.1114+side*0.034,1.254),Vector2(0.016,0.055),0,Color("182536"),0.002,true)
 face_patch(face,faces,"ForeheadCamera",Vector2(-0.1114,1.90),Vector2(0.075,0.045),0,Color("68e2b7"),0.002,true)
 for side in [-1,1]:
  var vent = kit.block(rig,"ChestVent",Vector3(0.15,0.085,0.025),Vector3(-0.111+side*0.26,0.94,0.398),Color("cbab53"))
  for rib in [-1,0,1]:
   kit.block(vent,"Louvre",Vector3(0.13,0.009,0.008),Vector3(0,rib*0.022,0.016),Color("4c5048"))

static func is_eye_recess(a: Vector3, b: Vector3, c: Vector3) -> bool:
 var has_top := false
 for p in [a,b,c]:
  if p.y < 1.33 or p.y > 1.519 or p.z > 0.274 or p.z < 0.08 or p.x < -0.36 or p.x > 0.14: return false
  if absf(p.y-1.5177) < 0.001: has_top = true
 return has_top

static func is_crest(a: Vector3, b: Vector3, c: Vector3) -> bool:
 for p in [a,b,c]:
  if absf(p.x+0.1114) > 0.094 or p.y < 1.528 or p.y > 1.768 or p.z < 0.33: return false
 return true

static func is_chin(a: Vector3, b: Vector3, c: Vector3) -> bool:
 for p in [a,b,c]:
  if absf(p.x+0.1114) > 0.057 or p.y < 1.056 or p.y > 1.201 or p.z < 0.303: return false
 return true

static func face_patch(parent: Node3D, faces: PackedVector3Array, label: String, center: Vector2, size: Vector2, angle: float, color: Color, lift: float, glow: bool) -> void:
 var vertices := PackedVector3Array()
 # Clip each original face triangle to the marking rectangle. Exact surface
 # geometry avoids both buried interiors and grid artifacts across the nose.
 for i in range(0,faces.size(),3):
  var polygon: Array[Vector3] = [faces[i],faces[i+1],faces[i+2]]
  if maxf(polygon[0].z,maxf(polygon[1].z,polygon[2].z)) < 0.07: continue
  if absf((polygon[1]-polygon[0]).cross(polygon[2]-polygon[0]).z) < 0.000001: continue
  for axis in [0,1]:
   for direction in [-1,1]:
    var clipped: Array[Vector3] = []
    for j in range(polygon.size()):
     var a: Vector3 = polygon[j]
     var b: Vector3 = polygon[(j+1)%polygon.size()]
     var pa := (Vector2(a.x,a.y)-center).rotated(-angle)
     var pb := (Vector2(b.x,b.y)-center).rotated(-angle)
     var da: float = size[axis]*0.5-pa[axis]*direction
     var db: float = size[axis]*0.5-pb[axis]*direction
     if da >= 0: clipped.append(a)
     if (da >= 0) != (db >= 0): clipped.append(a.lerp(b,da/(da-db)))
    polygon = clipped
  for j in range(1,polygon.size()-1):
   for point in [polygon[0],polygon[j],polygon[j+1]]:
    vertices.append(point+Vector3(0,0,lift))
 var tool := SurfaceTool.new()
 tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for vertex in vertices: tool.add_vertex(vertex)
 tool.generate_normals()
 var patch := MeshInstance3D.new()
 patch.name = label
 patch.mesh = tool.commit()
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 if glow: mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 patch.material_override = mat
 patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 parent.add_child(patch)
