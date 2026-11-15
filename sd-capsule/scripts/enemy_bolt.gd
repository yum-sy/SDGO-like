extends Node3D
var velocity := Vector3.ZERO
var explosive := false
var destination := Vector3.ZERO
var target: Node3D
var damage_amount := 8
const BLAST_RADIUS := 3.2
var shooter: RID
var lifetime := 3.0
var streak: MeshInstance3D
var body: MeshInstance3D
func _ready() -> void:
	body = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.18 if explosive else 0.09
	mesh.height = 0.50 if explosive else 0.18
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
	trail.size = Vector3(0.11,0.11,1.1) if explosive else Vector3(0.04,0.04,0.7)
	streak.mesh = trail
	streak.material_override = mat
	streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(streak)
func _physics_process(delta: float) -> void:
	var game := get_tree().current_scene
	if is_instance_valid(game) and game.get("mode") == "paused": return
	lifetime -= delta
	if velocity.length_squared() > 0.01:
		if explosive: body.basis = Basis(Quaternion(Vector3.UP,velocity.normalized()))
		streak.basis = Basis(Quaternion(Vector3.BACK,velocity.normalized()))
		streak.position = -velocity.normalized()*0.35
	var arrived := explosive and global_position.distance_to(destination) <= velocity.length()*delta
	var end := destination if arrived else global_position+velocity*delta
	var query := PhysicsRayQueryParameters3D.create(global_position,end,3,[shooter])
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		if explosive:
			explode(result.position + result.normal*0.07)
		else:
			if result.collider.has_method("damage_from"):
				result.collider.damage_from(damage_amount,global_position)
			elif result.collider.has_method("damage"):
				result.collider.damage(damage_amount)
			preload("res://scripts/combat_fx.gd").spawn(get_parent(),result.position,Color(1,0.5,0.15),0.55)
		queue_free()
	elif arrived:
		explode(destination)
		queue_free()
	elif lifetime <= 0:
		queue_free()
	else:
		global_position = end

func explode(point: Vector3) -> void:
	if get_parent().has_method("sound"): get_parent().sound("destroy")
	preload("res://scripts/blast_damage.gd").apply(self,point,target,BLAST_RADIUS,20,[shooter])
	for cover in get_tree().get_nodes_in_group("breakable_cover"):
		preload("res://scripts/blast_damage.gd").apply(self,point,cover,BLAST_RADIUS,40,[shooter])
	preload("res://scripts/combat_fx.gd").spawn(get_parent(),point,Color(1,0.55,0.16),2.2)
