extends Node3D
# Static scenery outside the playable boundary, with no collision/navigation cost.
func build(game: Node3D, arena_id: int) -> void:
	var accent := Color("e6a766") if arena_id == 0 else Color("61cbd0")
	for side in [-1,1]:
		for i in range(6):
			var x: float = side*(35+i%2*7)
			var z: float = -32+i*12
			var height: float = 7+(i*7)%11
			game.box(self,Vector3(7,height,8),Vector3(x,height/2,z),Color("233343"))
			game.box(self,Vector3(7.1,0.3,0.15),Vector3(x,height-1,z+4.05),accent)
	# Cargo gantry / reactor service gantry silhouettes beyond the rear wall.
	for x in [-24,24]:
		game.box(self,Vector3(1.5,16,1.5),Vector3(x,8,-36),Color("354657"))
	game.box(self,Vector3(51,1.4,2),Vector3(0,16,-36),Color("44566a"))
	for x in [-18,-6,6,18]:
		game.box(self,Vector3(0.1,5,0.1),Vector3(x,12.8,-36),accent)
	# Painted lanes and landing marks use shallow geometry, never physics bodies.
	for side in [-1,1]:
		for z in range(-25,27,4):
			game.box(self,Vector3(0.18,0.012,1.8),Vector3(side*23,0.025,z),accent.darkened(0.25))
	for x in [-2,2]:
		game.box(self,Vector3(0.12,0.012,4),Vector3(x,0.025,5),accent)
	game.box(self,Vector3(4,0.012,0.12),Vector3(0,0.025,7),accent)

	for mesh in get_children():
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
