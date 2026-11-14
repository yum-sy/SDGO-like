extends Node3D
# Short-lived geometry only; no simulation/collision/network authority.
var age := 0.0
var lifetime := 0.5
var fragments: Array[Dictionary] = []
var smoke: Array[MeshInstance3D] = []
var shockwave: MeshInstance3D
var ring: MeshInstance3D
static func spawn(parent: Node, at: Vector3, tint: Color, intensity: float = 1.0) -> Node3D:
	# Bound effect count even under sustained fire.
	if parent.get_tree().get_nodes_in_group("combat_fx").size() >= 24: return null
	var effect: Node3D = load("res://scripts/combat_fx.gd").new()
	parent.add_child(effect)
	effect.global_position = at
	effect.setup(tint,intensity)
	return effect
func material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = tint
	return mat
func setup(tint: Color, intensity: float) -> void:
	add_to_group("combat_fx")
	lifetime = 0.35+intensity*0.16
	if intensity >= 2:
		lifetime = 0.95
		var cloud_mesh := SphereMesh.new()
		cloud_mesh.radius = 0.35
		cloud_mesh.height = 0.7
		cloud_mesh.radial_segments = 8
		cloud_mesh.rings = 4
		var cloud_mat := material(Color(0.2,0.23,0.28,0.5))
		cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		for i in range(4):
			var cloud := MeshInstance3D.new()
			cloud.mesh = cloud_mesh
			cloud.material_override = cloud_mat
			cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(cloud)
			smoke.append(cloud)
	var mat := material(tint)
	for i in range(8 if intensity <= 1 else 16):
		var shard := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.035,0.035,0.19)*intensity
		shard.mesh = mesh
		shard.material_override = mat
		add_child(shard)
		var direction := Vector3(sin(i*2.4),0.3+fmod(i*0.37,1.0),cos(i*2.4)).normalized()
		shard.look_at(global_position+direction)
		fragments.append({"mesh":shard,"velocity":direction*(2.0+fmod(i*0.73,3.0))*intensity})
	ring = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12*intensity
	sphere.height = 0.24*intensity
	ring.mesh = sphere
	ring.material_override = material(Color(1,0.95,0.7))
	add_child(ring)
	if intensity >= 1:
		shockwave = MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.38
		torus.outer_radius = 0.43
		torus.rings = 16
		torus.ring_segments = 6
		shockwave.mesh = torus
		var glow := material(tint)
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shockwave.material_override = glow
		add_child(shockwave)
func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if is_instance_valid(scene) and scene.get("mode") == "paused": return
	age += delta
	var fade := maxf(0,1-age/lifetime)
	for fragment in fragments:
		fragment.velocity.y -= delta*7
		fragment.mesh.position += fragment.velocity*delta
		fragment.mesh.scale = Vector3.ONE*fade
	ring.scale = Vector3.ONE*maxf(0,1-age/0.16)*3
	if is_instance_valid(shockwave):
		shockwave.scale = Vector3.ONE*(0.3+age*6)
		shockwave.material_override.albedo_color.a = fade*0.7
	for i in range(smoke.size()):
		smoke[i].position = Vector3(sin(i*2.4)*age,age*1.5,cos(i*2.4)*age)
		smoke[i].scale = Vector3.ONE*(0.3+age*2.4)
		smoke[i].material_override.albedo_color.a = minf(age*5,1)*fade*0.5
	if age >= lifetime: queue_free()
