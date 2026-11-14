extends Node3D
var velocity := Vector3.ZERO
var shooter: RID
var lifetime := 3.0
var streak: MeshInstance3D
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
	streak = MeshInstance3D.new()
	var trail := BoxMesh.new()
	trail.size = Vector3(0.05,0.05,0.7)
	streak.mesh = trail
	streak.material_override = mat
	streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(streak)
func _physics_process(delta: float) -> void:
	lifetime -= delta
	if velocity.length_squared() > 0.01:
		streak.basis = Basis(Quaternion(Vector3.BACK,velocity.normalized()))
		streak.position = -velocity.normalized()*0.35
	var end := global_position+velocity*delta
	var query := PhysicsRayQueryParameters3D.create(global_position,end,3,[shooter])
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		if result.collider.has_method("damage_from"):
			result.collider.damage_from(8,global_position)
		elif result.collider.has_method("damage"):
			result.collider.damage(8)
		preload("res://scripts/combat_fx.gd").spawn(get_parent(),result.position,Color(1,0.5,0.15),0.55)
		queue_free()
	elif lifetime <= 0:
		queue_free()
	else:
		global_position = end
