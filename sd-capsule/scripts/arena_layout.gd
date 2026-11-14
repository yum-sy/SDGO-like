extends RefCounted
# Shared collision footprints and navigation; only instantiated once per sortie.
const NAMES = ["CARGO YARD","REACTOR RING"]
static var selected := 0
var removed_covers: Array[int] = []
var index := 0
var footprints: Array[Rect2] = []
var navigation := AStarGrid2D.new()
func crates() -> Array[Vector3]:
	if index == 0:
		return [Vector3(-9,0,-6),Vector3(9,0,-6),Vector3(-13,0,9),Vector3(13,0,9),Vector3(-5,0,-16),Vector3(6,0,-21),Vector3(-9,0,-9),Vector3(9,0,-9)]
	return [Vector3(-12,0,-3),Vector3(12,0,-3),Vector3(-12,0,-16),Vector3(12,0,-16),Vector3(-5,0,9),Vector3(5,0,9)]
func structures() -> Array[Dictionary]:
	if index == 0:
		return [{"size":Vector3(6,1.5,8),"at":Vector3(19,0.75,-16)}]
	return [{"size":Vector3(7,4,7),"at":Vector3(0,2,-9)},{"size":Vector3(6,1.5,7),"at":Vector3(-20,0.75,-18)}]
func spawns() -> Array[Vector3]:
	if index == 0: return [Vector3(0,0,-13),Vector3(-13,0,-17),Vector3(19,1.5,-16)]
	return [Vector3(-6,0,-16),Vector3(13,0,-18),Vector3(-20,1.5,-18)]
func build_navigation() -> void:
	navigation = AStarGrid2D.new()
	footprints.clear()
	for i in range(crates().size()):
		if i in removed_covers: continue
		var at: Vector3 = crates()[i]
		footprints.append(Rect2(Vector2(at.x-1.5,at.z-1.25),Vector2(3,2.5)))
	for item in structures(): footprints.append(Rect2(Vector2(item.at.x-item.size.x/2,item.at.z-item.size.z/2),Vector2(item.size.x,item.size.z)))
	navigation.region = Rect2i(-14,-14,29,29)
	navigation.cell_size = Vector2(2,2)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in range(-14,15):
		for z in range(-14,15):
			for rect in footprints:
				if rect.grow(0.8).has_point(Vector2(x*2,z*2)):
					navigation.set_point_solid(Vector2i(x,z))
					break
func closest_cell(at: Vector3) -> Vector2i:
	var cell := Vector2i(clampi(roundi(at.x/2),-14,14),clampi(roundi(at.z/2),-14,14))
	if not navigation.is_point_solid(cell): return cell
	var best := cell
	var distance := INF
	for x in range(-14,15):
		for z in range(-14,15):
			var candidate := Vector2i(x,z)
			if not navigation.is_point_solid(candidate) and candidate.distance_squared_to(cell) < distance:
				best = candidate
				distance = candidate.distance_squared_to(cell)
	return best
func path(from: Vector3, to: Vector3) -> PackedVector2Array:
	return navigation.get_point_path(closest_cell(from),closest_cell(to))

func remove_cover(index_to_remove: int) -> void:
	if index_to_remove in removed_covers: return
	removed_covers.append(index_to_remove)
	build_navigation()
