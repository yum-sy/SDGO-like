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
		"cycle":Rect2(size-Vector2(145,400),Vector2(100,80)),
		"pause":Rect2(Vector2(size.x-120,54),Vector2(80,58))}
static func menu_buttons(size: Vector2) -> Dictionary:
	return {"mute":Rect2(Vector2(size.x*0.5-280,size.y*0.5+105),Vector2(180,52)),"quality":Rect2(Vector2(size.x*0.5-80,size.y*0.5+105),Vector2(220,52))}
