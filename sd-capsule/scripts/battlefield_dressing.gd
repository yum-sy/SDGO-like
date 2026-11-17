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

	# Service walls, illuminated bays and heavy external infrastructure.
	for side in [-1,1]:
		for z in range(-24,29,8):
			game.box(self,Vector3(0.30,3.8,0.65),Vector3(side*29.42,2.0,z),Color("526475"))
			game.box(self,Vector3(0.035,0.25,2.4),Vector3(side*29.22,3.4,z+2.8),accent)
		for i in range(5):
			for row in range(3):
				game.box(self,Vector3(0.04,0.7,1.3),Vector3(side*31.4,6+row*2,-20+i*7),Color("7d9da8"))
	if arena_id == 0:
		for side in [-1,1]:
			for level in range(3):
				game.box(self,Vector3(9,2.8,3.5),Vector3(side*20,1.4+level*3,-33),Color("405f6d") if level%2 == 0 else Color("a27a45"))
				for rib in range(8):
					game.box(self,Vector3(0.10,2.5,0.06),Vector3(side*20-4+rib*1.1,1.4+level*3,-31.2),Color("273d49"))
	else:
		for side in [-1,1]:
			game.box(self,Vector3(5,18,5),Vector3(side*18,9,-34),Color("263f53"))
			for level in range(6):
				game.box(self,Vector3(5.2,0.25,5.2),Vector3(side*18,2+level*2.6,-34),accent)
			game.box(self,Vector3(2,2,24),Vector3(side*34,7,0),Color("506779"))
	# Bay markings stay clear of navigation and combat silhouettes.
	for x in [-18,18]:
		game.box(self,Vector3(5,0.012,0.14),Vector3(x,0.032,21),accent)
		for offset in [-2.4,2.4]:
			game.box(self,Vector3(0.14,0.012,5),Vector3(x+offset,0.032,23.5),accent)
	# Broad, subdued service pads establish scale without adding visual noise.
	for x in [-12,12]:
		for z in [-15,5,21]:
			game.box(self,Vector3(7,0.012,5),Vector3(x,0.018,z),Color("2b4051"))
			for edge in [-1,1]:
				game.box(self,Vector3(0.10,0.012,1.4),Vector3(x+edge*3.5,0.034,z),accent.darkened(0.35))
	batch_static_geometry()

func batch_static_geometry() -> void:
	# One surface per palette color instead of one draw per decorative block.
	var batches := {}
	for child in get_children():
		if not child is MeshInstance3D: continue
		var mat: StandardMaterial3D = child.material_override
		var key := mat.albedo_color.to_html()
		if not batches.has(key):
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tool.set_material(mat)
			batches[key] = tool
		batches[key].append_from(child.mesh,0,child.transform)
		remove_child(child)
		child.free()
	for key in batches:
		var mesh := MeshInstance3D.new()
		mesh.name = "SceneryBatch_"+key
		mesh.mesh = batches[key].commit()
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
