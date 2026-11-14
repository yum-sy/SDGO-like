extends Control
var combat: Node3D
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(combat):
		return
	var center := size * 0.5
	var tint := Color(0.35, 1, 0.8)
	draw_line(center - Vector2(7,0), center + Vector2(7,0), tint, 1)
	draw_line(center - Vector2(0,7), center + Vector2(0,7), tint, 1)
	for target in combat.targets:
		if target.hp <= 0 or combat.camera.is_position_behind(target.aim_point()):
			continue
		var at: Vector2 = combat.camera.unproject_position(target.aim_point())
		if target == combat.selected:
			draw_rect(Rect2(at - Vector2(26,34), Vector2(52,68)), tint, false, 2)
			draw_string(ThemeDB.fallback_font, at + Vector2(-30,-43), "LOCK %d" % target.target_number, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, tint)
		draw_rect(Rect2(at + Vector2(-25,40),Vector2(50,5)), Color(0.1,0.1,0.1,0.8))
		draw_rect(Rect2(at + Vector2(-25,40),Vector2(target.hp * 0.5,5)), tint)
	if combat.hit_left > 0:
		for axis in [Vector2(1,1), Vector2(-1,1)]:
			draw_line(center - axis * 12, center + axis * 12, Color.WHITE, 2)
