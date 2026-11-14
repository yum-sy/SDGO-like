extends MeshInstance3D
# World-space ribbon follows the authoritative swept interval; cosmetic only.
var age := 0.0
const LIFE := 0.14
static func spawn(parent: Node3D, origin: Vector3, facing: Vector3, clock: RefCounted) -> void:
	if parent.get_tree().get_nodes_in_group("saber_trails").size() >= 12: return
	var trail = load("res://scripts/saber_trail.gd").new()
	parent.add_child(trail)
	trail.add_to_group("saber_trails")
	trail.top_level = true
	trail.global_transform = Transform3D.IDENTITY
	var right := Vector3(facing.z,0,-facing.x)
	var anchor := origin+right*(-0.65)+facing*0.55+Vector3.UP*0.05
	var vertices := PackedVector3Array()
	var a: float = clock.sweep_angle(clock.previous)
	var b: float = clock.sweep_angle(clock.elapsed)
	for i in range(4):
		var d0 := right*sin(lerpf(a,b,i/4.0))+facing*cos(lerpf(a,b,i/4.0))
		var d1 := right*sin(lerpf(a,b,(i+1)/4.0))+facing*cos(lerpf(a,b,(i+1)/4.0))
		vertices.append_array(PackedVector3Array([anchor+d0*0.35,anchor+d0*1.6,anchor+d1*1.6,anchor+d0*0.35,anchor+d1*1.6,anchor+d1*0.35]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var ribbon := ArrayMesh.new()
	ribbon.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	trail.mesh = ribbon
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1,0.3,0.75,0.55)
	trail.material_override = mat
func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if is_instance_valid(scene) and scene.get("mode") == "paused": return
	age += delta
	material_override.albedo_color.a = 0.55*maxf(0,1-age/LIFE)
	if age >= LIFE: queue_free()
