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
 # Paint the face surface itself: broad visor, separate white mask and red chin.
 face_patch(face,faces,"Visor",Vector2(-0.111,1.565),Vector2(0.52,0.16),0,Color("101c2b"),0.012,true)
 face_patch(face,faces,"FaceMask",Vector2(-0.111,1.385),Vector2(0.245,0.20),0,Color("dde7ed"),0.015,true)
 for side in [-1,1]:
  var eye_x: float = -0.111+side*0.128
  face_patch(face,faces,"EyeSocket"+str(side),Vector2(eye_x,1.565),Vector2(0.215,0.085),side*0.15,Color("101c2b"),0.020,true)
  face_patch(face,faces,"Eye"+str(side),Vector2(eye_x,1.57),Vector2(0.175,0.048),side*0.15,Color("ffeb3b"),0.026,true)
  face_patch(face,faces,"MaskVent"+str(side),Vector2(-0.111+side*0.040,1.36),Vector2(0.023,0.066),0,Color("172333"),0.024,true)
  face_patch(face,faces,"CheekInset"+str(side),Vector2(-0.111+side*0.235,1.37),Vector2(0.055,0.17),side*0.1,Color("6f859c"),0.012,false)
 face_patch(face,faces,"Chin",Vector2(-0.111,1.245),Vector2(0.13,0.115),0,Color("c72e3e"),0.018,true)
 face_patch(face,faces,"CameraFrame",Vector2(-0.111,1.815),Vector2(0.12,0.065),0,Color("172333"),0.012,true)
 face_patch(face,faces,"ForeheadCamera",Vector2(-0.111,1.815),Vector2(0.085,0.038),0,Color("62ead1"),0.020,true)
 for side in [-1,1]:
  var vent = kit.block(rig,"ChestVent",Vector3(0.15,0.085,0.025),Vector3(-0.111+side*0.26,0.94,0.398),Color("cbab53"))
  for rib in [-1,0,1]:
   kit.block(vent,"Louvre",Vector3(0.13,0.009,0.008),Vector3(0,rib*0.022,0.016),Color("4c5048"))

static func face_patch(parent: Node3D, faces: PackedVector3Array, label: String, center: Vector2, size: Vector2, angle: float, color: Color, lift: float, glow: bool) -> void:
 var vertices := PackedVector3Array()
 # Clip each original face triangle to the marking rectangle. Exact surface
 # geometry avoids both buried interiors and grid artifacts across the nose.
 for i in range(0,faces.size(),3):
  var polygon: Array[Vector3] = [faces[i],faces[i+1],faces[i+2]]
  if maxf(polygon[0].z,maxf(polygon[1].z,polygon[2].z)) < 0.1: continue
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
