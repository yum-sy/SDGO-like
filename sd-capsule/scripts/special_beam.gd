extends Node3D
# Two reusable unlit meshes: bounded mobile cost, no particle storm or camera cut.
var outer: MeshInstance3D
var core: MeshInstance3D
func _ready() -> void:
	for color in [Color(0.25,0.85,1),Color(0.88,1,1)]:
		var node := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 1
		mesh.bottom_radius = 1
		mesh.height = 1
		mesh.radial_segments = 12
		node.mesh = mesh
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		if outer == null:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = 0.3
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.rotation.x = PI/2
		add_child(node)
		if outer == null: outer = node
		else: core = node
	hide()
func sync(start: Vector3, end: Vector3, phase: String, time: float) -> void:
	visible = phase in ["WINDUP","DISCHARGE"]
	if not visible: return
	var length := maxf(0.01,start.distance_to(end))
	global_position = start
	if length > 0.01: look_at(end,Vector3.UP if absf((end-start).normalized().y)<0.95 else Vector3.RIGHT)
	var radius := 0.65+sin(time*42)*0.07
	if phase == "WINDUP":
		length = 0.35
		radius = 0.12+0.4*clampf(time/0.65,0,1)
	for node in [outer,core]:
		node.position.z = -length/2
		node.scale = Vector3(radius*(0.62 if node == core else 1.0),length,radius*(0.62 if node == core else 1.0))
