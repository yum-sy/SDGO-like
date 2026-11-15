extends RefCounted
# Single-pass painted armor. Preserve source textures and material attribution.
static func apply(root: Node3D, gundam: bool) -> void:
 var cache := {}
 for node in root.find_children("*","MeshInstance3D",true,false):
  for surface in range(node.mesh.get_surface_count()):
   var source = node.get_active_material(surface)
   if not source is StandardMaterial3D: continue
   var key := str(source.get_instance_id())
   if not cache.has(key):
    var paint: StandardMaterial3D = source.duplicate()
    paint.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    paint.specular_mode = BaseMaterial3D.SPECULAR_TOON
    paint.metallic = 0.08
    paint.metallic_specular = 0.22
    paint.roughness = 0.58
    paint.rim_enabled = true
    paint.rim = 0.12
    paint.rim_tint = 0.65
    if gundam:
     var tint := paint.albedo_color
     if tint.r > 0.65 and tint.g > 0.65: paint.albedo_color = Color("aabac9")
     elif tint.b > tint.r*1.4: paint.albedo_color = Color("235b9e")
     elif tint.r > tint.b*1.4: paint.albedo_color = Color("b93d47")
    else:
     # Textured Zaku armor needs continuous shading; toon highlights wash it out.
     paint.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
     paint.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
     paint.rim_enabled = false
     paint.metallic = 0.15
     paint.roughness = 0.78
     paint.albedo_color = source.albedo_color
    cache[key] = paint
   node.set_surface_override_material(surface,cache[key])
