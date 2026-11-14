extends MeshInstance3D
# Ground projection of the enemy's committed melee cone. No collision authority.
const REACH := 2.8
const DOT_LIMIT := 0.45
func _ready() -> void:
	var vertices := PackedVector3Array()
	var angle := acos(DOT_LIMIT)
	for i in range(24):
		var a := lerpf(-angle,angle,i/24.0)
		var b := lerpf(-angle,angle,(i+1)/24.0)
		vertices.append_array(PackedVector3Array([Vector3.ZERO,Vector3(sin(a),0,cos(a))*REACH,Vector3(sin(b),0,cos(b))*REACH]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var fan := ArrayMesh.new()
	fan.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh = fan
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1,0.35,0.08,0.18)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hide()
func sync(actor: CharacterBody3D) -> void:
	visible = actor.hp > 0 and actor.melee_clock.running and actor.melee_clock.stage() in ["WINDUP","STRIKE"]
	if not visible: return
	global_position = actor.global_position+Vector3.UP*0.045
	global_rotation = Vector3(0,atan2(actor.melee_facing.x,actor.melee_facing.z),0)
	var progress: float = clampf(actor.melee_clock.elapsed/actor.melee_clock.clip().x,0,1)
	material_override.albedo_color = Color(1,lerpf(0.6,0.18,progress),0.08,lerpf(0.12,0.32,progress))
