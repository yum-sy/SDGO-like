extends RefCounted
# Small runtime meshes; no downloads or additional textures.
static func block(root: Node3D, label: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
 var part := MeshInstance3D.new()
 part.name = label
 var box := BoxMesh.new()
 box.size = size
 part.mesh = box
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.65
 part.material_override = material
 part.position = at
 root.add_child(part)
 return part
static func tube(root: Node3D, label: String, radius: float, length: float, at: Vector3, color: Color) -> MeshInstance3D:
 var part := MeshInstance3D.new()
 part.name = label
 var mesh := CylinderMesh.new()
 mesh.top_radius = radius
 mesh.bottom_radius = radius
 mesh.height = length
 mesh.radial_segments = 10
 part.mesh = mesh
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.6
 part.material_override = material
 part.position = at
 part.rotation.x = PI/2
 root.add_child(part)
 return part
static func build(kind: String) -> Node3D:
 var root := Node3D.new()
 root.name = kind
 var dark := Color("303c42")
 var steel := Color("65757b")
 block(root,"Grip",Vector3(0.09,0.22,0.11),Vector3.ZERO,dark)
 if kind == "HEAT HAWK":
  tube(root,"Haft",0.045,0.70,Vector3(0,0.28,0),steel).rotation.x = 0
  block(root,"AxeHead",Vector3(0.39,0.24,0.10),Vector3(0.12,0.63,0),dark)
  var edge := block(root,"HeatedEdge",Vector3(0.09,0.30,0.12),Vector3(0.35,0.63,0),Color("ff893a"))
  edge.rotation.z = -0.16
 elif kind == "BAZOOKA":
  tube(root,"Launcher",0.16,1.35,Vector3(0,0.20,0.20),steel)
  tube(root,"MuzzleRim",0.19,0.10,Vector3(0,0.20,0.91),dark)
  tube(root,"Bore",0.14,0.012,Vector3(0,0.20,0.967),Color("10181c"))
  tube(root,"RearVent",0.19,0.15,Vector3(0,0.20,-0.49),dark)
  block(root,"Sight",Vector3(0.07,0.10,0.24),Vector3(0,0.40,0.18),dark)
 else:
  block(root,"Receiver",Vector3(0.20,0.19,0.43),Vector3(0,0.13,0.16),dark)
  block(root,"Stock",Vector3(0.16,0.17,0.26),Vector3(0,0.13,-0.19),steel)
  tube(root,"Barrel",0.06,0.49,Vector3(0,0.13,0.60),steel)
  tube(root,"Muzzle",0.085,0.10,Vector3(0,0.13,0.88),dark)
  tube(root,"DrumMagazine",0.19,0.13,Vector3(0,0.28,0.14),steel).rotation.x = 0
  block(root,"Sight",Vector3(0.055,0.09,0.08),Vector3(0,0.25,0.57),dark)
 var muzzle := Marker3D.new()
 muzzle.name = "Muzzle"
 muzzle.position = Vector3(0,0.20,0.99) if kind == "BAZOOKA" else Vector3(0,0.13,0.95)
 root.add_child(muzzle)
 return root
