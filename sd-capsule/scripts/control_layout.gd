extends RefCounted
static var safe := Vector4.ZERO
static func buttons(size: Vector2) -> Dictionary:
	size -= Vector2(safe.z,safe.w)
	return {
		"fire":Rect2(size-Vector2(150,160),Vector2(110,110)),
		"melee":Rect2(size-Vector2(280,160),Vector2(110,110)),
		"boost":Rect2(size-Vector2(150,290),Vector2(110,110)),
		"dash":Rect2(size-Vector2(280,290),Vector2(110,110)),
		"weapon":Rect2(size-Vector2(400,150),Vector2(90,90)),
		"reload":Rect2(size-Vector2(400,270),Vector2(90,90)),
		"aim":Rect2(size-Vector2(270,400),Vector2(105,80)),
		"cycle":Rect2(size-Vector2(145,400),Vector2(100,80)),
		"pause":Rect2(Vector2(size.x-120,94),Vector2(80,58))}
static func menu_buttons(size: Vector2) -> Dictionary:
	var x := 48.0+safe.x
	var y := size.y-214-safe.w
	return {
		"restart":Rect2(x,y+88,528,80),
		"arena":Rect2(x,y,258,76),
		"difficulty":Rect2(x+270,y,258,76),
		"mute":Rect2(size.x-354-safe.z,20+safe.y,170,36),
		"quality":Rect2(size.x-174-safe.z,20+safe.y,126,36)}
