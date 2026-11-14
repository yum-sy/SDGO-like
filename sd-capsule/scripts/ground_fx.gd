extends Node3D
# Bounded ground dust for thrust/landing; independent of collision and damage.
var age := 0.0
const LIFE := 0.42
var puffs: Array[MeshInstance3D] = []
static func spawn(parent: Node, point: Vector3) -> Node3D:
	if parent.get_tree().get_nodes_in_group("ground_fx").size() >= 8: return null
	var effect = load("res://scripts/ground_fx.gd").new()
	parent.add_child(effect)
	effect.global_position = point+Vector3.UP*0.06
	return effect
func _ready() -> void:
	add_to_group("ground_fx")
	var dust := SphereMesh.new()
	dust.radius = 0.2
	dust.height = 0.4
	dust.radial_segments = 8
	dust.rings = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.65,0.69,0.7,0.25)
	for i in range(6):
		var puff := MeshInstance3D.new()
		puff.mesh = dust
		puff.material_override = material
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(puff)
		puffs.append(puff)
func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if is_instance_valid(scene) and scene.get("mode") == "paused": return
	age += delta
	for i in range(puffs.size()):
		puffs[i].position = Vector3(sin(i*TAU/6),0,cos(i*TAU/6))*(0.15+age*2.6)
		puffs[i].scale = Vector3(1+age*2,0.3+age,1+age*2)
	puffs[0].material_override.albedo_color.a = maxf(0,1-age/LIFE)*0.25
	if age >= LIFE: queue_free()
