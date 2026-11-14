extends StaticBody3D
signal broken(index)
var cover_index := 0
var hp := 75
var visual: Node3D
var flash := 0.0
func _ready() -> void:
	add_to_group("breakable_cover")
	visual = preload("res://assets/props/crate.glb").instantiate()
	visual.scale = Vector3.ONE*3
	add_child(visual)
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
