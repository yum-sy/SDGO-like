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
 for side in [-1,1]:
  var eye_x: float = -0.111+side*0.112
  face_patch(face,faces,"EyeSocket"+str(side),Vector2(eye_x,1.565),Vector2(0.175,0.065),side*0.10,Color("182831"),0.006,false)
  face_patch(face,faces,"Eye"+str(side),Vector2(eye_x,1.57),Vector2(0.135,0.028),side*0.10,Color("e9e788"),0.010,true)
  kit.block(face,"MaskVent",Vector3(0.018,0.072,0.014),Vector3(-0.111+side*0.037,1.335,0.317),Color("344653"))
 kit.block(face,"Chin",Vector3(0.105,0.10,0.032),Vector3(-0.111,1.23,0.316),Color("b5303c"))
 kit.block(face,"ForeheadCamera",Vector3(0.075,0.045,0.024),Vector3(-0.111,1.802,0.195),Color("67cdb5"))
 for side in [-1,1]:
  var vent = kit.block(rig,"ChestVent",Vector3(0.15,0.085,0.025),Vector3(-0.111+side*0.26,0.94,0.398),Color("cbab53"))
  for rib in [-1,0,1]:
   kit.block(vent,"Louvre",Vector3(0.13,0.009,0.008),Vector3(0,rib*0.022,0.016),Color("4c5048"))

static func face_patch(parent: Node3D, faces: PackedVector3Array, label: String, center: Vector2, size: Vector2, angle: float, color: Color, lift: float, glow: bool) -> void:
 var vertices := PackedVector3Array()
 for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,-1),Vector2(1,1),Vector2(-1,1)]:
  var xy: Vector2 = center+(corner*size*0.5).rotated(angle)
  var depth := -1.0
  for i in range(0,faces.size(),3):
   var hit = Geometry3D.ray_intersects_triangle(Vector3(xy.x,xy.y,2),Vector3.FORWARD,faces[i],faces[i+1],faces[i+2])
   if hit != null: depth = maxf(depth,hit.z)
  vertices.append(Vector3(xy.x,xy.y,(depth if depth > -0.5 else 0.30)+lift))
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
