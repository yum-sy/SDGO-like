extends Node3D
var velocity := Vector3.ZERO
var shooter: RID
var lifetime := 3.0
func _ready() -> void:
	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	mesh.radial_segments = 8
	mesh.rings = 4
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1,0.4,0.15)
	body.material_override = mat
	add_child(body)
func _physics_process(delta: float) -> void:
	lifetime -= delta
	var end := global_position+velocity*delta
	var query := PhysicsRayQueryParameters3D.create(global_position,end,3,[shooter])
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		if result.collider.has_method("damage"):
			result.collider.damage(8)
		queue_free()
	elif lifetime <= 0:
		queue_free()
	else:
		global_position = end
