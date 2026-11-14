extends Control
var pilot: Node
func _process(_delta: float) -> void:
	visible = DisplayServer.is_touchscreen_available()
	queue_redraw()
func _draw() -> void:
	if not visible or not is_instance_valid(pilot):
		return
	var center: Vector2 = Vector2(110, size.y - 110) if pilot.stick_id == -1 else pilot.stick_origin
	draw_circle(center, 65, Color(0.6, 0.8, 1, 0.13))
	draw_arc(center, 65, 0, TAU, 48, Color(0.7, 0.85, 1, 0.5), 2)
	draw_circle(center + pilot.touch_move * 50, 24, Color(0.7, 0.85, 1, 0.4))
	var button := Vector2(size.x - 100, size.y - 100)
	draw_circle(button, 60, Color(0.3, 0.7, 1, 0.25))
	draw_arc(button, 60, 0, TAU, 48, Color(0.7, 0.85, 1, 0.65), 2)
	draw_string(ThemeDB.fallback_font, button + Vector2(-30, 5), "BOOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)

	for entry in [[Vector2(size.x-240,size.y-100),55.0,"FIRE"], [Vector2(size.x-240,size.y-220),40.0,"RELOAD"], [Vector2(size.x-100,size.y-220),40.0,"TARGET"]]:
		draw_circle(entry[0], entry[1], Color(0.3,0.7,1,0.25))
		draw_arc(entry[0], entry[1], 0, TAU, 48, Color(0.7,0.85,1,0.65),2)
		draw_string(ThemeDB.fallback_font, entry[0] + Vector2(-30,5),entry[2],HORIZONTAL_ALIGNMENT_LEFT,-1,16)
