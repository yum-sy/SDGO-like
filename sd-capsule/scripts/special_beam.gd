extends Node3D
# Two reusable unlit meshes: bounded mobile cost, no particle storm or camera cut.
var charge_ring: MeshInstance3D
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
	charge_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.40
	ring.outer_radius = 0.44
	ring.rings = 24
	ring.ring_segments = 6
	charge_ring.mesh = ring
	charge_ring.rotation.x = PI/2
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(0.4,0.9,1,0.8)
	charge_ring.material_override = glow
	charge_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(charge_ring)
	hide()
func sync(start: Vector3, end: Vector3, phase: String, time: float) -> void:
	visible = phase in ["WINDUP","DISCHARGE"]
	if not visible: return
	var length := maxf(0.01,start.distance_to(end))
	global_position = start
	if length > 0.01: look_at(end,Vector3.UP if absf((end-start).normalized().y)<0.95 else Vector3.RIGHT)
	var fire_age := maxf(0,time-0.65)
	var radius := 0.55+sin(time*32)*0.025+0.18*exp(-fire_age*14)
	charge_ring.visible = phase == "WINDUP" or fire_age < 0.28
	var ring_size := lerpf(2.5,0.65,clampf(time/0.65,0,1)) if phase == "WINDUP" else 1+fire_age*8
	charge_ring.scale = Vector3.ONE*ring_size
	charge_ring.position.z = -0.12
	charge_ring.material_override.albedo_color.a = 0.7 if phase == "WINDUP" else maxf(0,0.8-fire_age*3)

	if phase == "WINDUP":
		length = 0.35
		radius = 0.06+0.22*pow(clampf(time/0.65,0,1),2)
	for node in [outer,core]:
		node.position.z = -length/2
		node.scale = Vector3(radius*(0.48 if node == core else 1.0),length,radius*(0.48 if node == core else 1.0))
