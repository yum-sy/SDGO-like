extends StaticBody3D
signal broken(index)
var cover_index := 0
var hp := 75
var visual: Node3D
var flash := 0.0
func _ready() -> void:
	add_to_group("breakable_cover")
	visual = Node3D.new()
	add_child(visual)
	var model := preload("res://assets/props/crate.glb").instantiate()
	visual.add_child(model)
	var bounds := model_bounds(model,Transform3D.IDENTITY)
	var factor := Vector3(3,2.7,2.5)/bounds.size
	model.transform = Transform3D(Basis.IDENTITY.scaled(factor),-bounds.position*factor-Vector3(1.5,0,1.25))*model.transform
	paint_industrial(model)
	var kit = preload("res://scripts/weapon_kit.gd")
	for face in [-1,1]:
		kit.block(visual,"SafetyBand",Vector3(2.7,0.16,0.025),Vector3(0,1.7,face*1.265),Color("c69a48"))
		for stripe in range(5):
			kit.block(visual,"BandBreak",Vector3(0.16,0.16,0.027),Vector3(-1.05+stripe*0.5,1.7,face*1.266),Color("34434b"))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3,2.7,2.5)
	collision.shape = shape
	collision.position.y = 1.35
	add_child(collision)
func aim_point() -> Vector3:
	return global_position+Vector3.UP*1.35
func damage(amount: int, _kind: String = "other") -> void:
	if hp <= 0: return
	hp = maxi(0,hp-amount)
	flash = 0.1
	if hp == 0:
		collision_layer = 0
		collision_mask = 0
		visual.hide()
		preload("res://scripts/combat_fx.gd").spawn(get_parent(),global_position+Vector3.UP,Color(0.75,0.85,1),1.4)
		broken.emit(cover_index)
		# Keep the node for stable IDs/snapshots; no collision or rendering remains.
func _process(delta: float) -> void:
	if get_parent().get("mode") == "paused": return
	flash = maxf(0,flash-delta)
	visual.position.y = sin(flash*120)*flash*0.18

func paint_industrial(node: Node) -> void:
	if node is MeshInstance3D:
		for i in range(node.mesh.get_surface_count()):
			var source = node.get_active_material(i)
			if source is StandardMaterial3D:
				var paint: StandardMaterial3D = source.duplicate()
				var original: Color = source.albedo_color
				paint.albedo_color = Color("b98a43") if original.b > original.g*1.15 else (Color("627887") if original.v > 0.5 else Color("263741"))
				paint.roughness = 0.85
				paint.albedo_texture = null
				paint.vertex_color_use_as_albedo = false
				node.set_surface_override_material(i,paint)
	for child in node.get_children(): paint_industrial(child)

func model_bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
	var transform_at := parent_transform*node.transform
	var bounds := AABB()
	if node is MeshInstance3D: bounds = transform_at*node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var child_bounds := model_bounds(child,transform_at)
			if child_bounds.size.length_squared() > 0:
				bounds = child_bounds if bounds.size.length_squared() == 0 else bounds.merge(child_bounds)
	return bounds
