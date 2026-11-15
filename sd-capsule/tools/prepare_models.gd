extends SceneTree
# Bake source transforms; batch Zaku by rigid articulation region AND material.
func collect(node: Node, transform: Transform3D, result: Array) -> void:
	if node is Node3D:
		transform *= node.transform
	if node is MeshInstance3D:
		result.append({"node": node, "transform": transform})
	for child in node.get_children():
		collect(child, transform, result)

func split_horizontal(mesh: ArrayMesh, levels: Array) -> ArrayMesh:
	var raw := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = raw[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = raw[Mesh.ARRAY_NORMAL]
	var out := SurfaceTool.new()
	out.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,verts.size(),3):
		var polygons: Array = [[{"p":verts[i],"n":normals[i]},{"p":verts[i+1],"n":normals[i+1]},{"p":verts[i+2],"n":normals[i+2]}]]
		for level in levels:
			var next: Array = []
			for polygon in polygons:
				for sign_value in [-1,1]:
					var clipped: Array = []
					for j in range(polygon.size()):
						var a: Dictionary = polygon[j]
						var b: Dictionary = polygon[(j+1)%polygon.size()]
						var inside_a: bool = (a.p.y-level)*sign_value >= 0
						var inside_b: bool = (b.p.y-level)*sign_value >= 0
						if inside_a: clipped.append(a)
						if inside_a != inside_b:
							var t: float = (level-a.p.y)/(b.p.y-a.p.y)
							clipped.append({"p":a.p.lerp(b.p,t),"n":a.n.lerp(b.n,t).normalized()})
					if clipped.size() >= 3: next.append(clipped)
			polygons = next
		for polygon in polygons:
			for j in range(1,polygon.size()-1):
				for vertex in [polygon[0],polygon[j],polygon[j+1]]:
					out.set_normal(vertex.n)
					out.add_vertex(vertex.p)
	return out.commit()

func paint_details(mesh: ArrayMesh, part: String) -> ArrayMesh:
	if not ("head" in part or "leg_" in part or "shield" in part or "boy_bottom" in part): return mesh
	var unpack := SurfaceTool.new()
	unpack.create_from(mesh,0)
	unpack.deindex()
	var unpacked := unpack.commit()
	if "leg_" in part: unpacked = split_horizontal(unpacked,[0.055,0.19])
	elif "boy_bottom" in part: unpacked = split_horizontal(unpacked,[0.52])
	var arrays := unpacked.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	for index in range(vertices.size()):
		var base := (index/3)*3
		var v := (vertices[base]+vertices[base+1]+vertices[base+2])/3.0
		var color := Color("d5dfe7")
		var x: float = absf(v.x+0.111)
		if "head" in part:
			if x < 0.09 and v.y > 1.79 and v.z > 0.04: color = Color("c83443")
			elif v.z < -0.36 and v.y < 1.35: color = Color("354558")
		elif "leg_" in part:
			if v.y < 0.055: color = Color("293c50")
			elif v.y < 0.19: color = Color("c83443")
		elif "shield" in part:
			if v.z > 0.25 and absf(v.x-0.859) < 0.16 and v.y > 0.4 and v.y < 0.83: color = Color("f0cc54")
			elif v.z > 0.18 and v.x > 0.61 and v.x < 1.10 and v.y > 0.17 and v.y < 1.15: color = Color("bd2d40")
			elif v.z < 0: color = Color("344454")
		elif "boy_bottom" in part:
			if v.y > 0.52: color = Color("bd2d40")
		colors.append(color)
	arrays[Mesh.ARRAY_COLOR] = colors
	var output := ArrayMesh.new()
	output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var paint := StandardMaterial3D.new()
	paint.vertex_color_use_as_albedo = true
	paint.roughness = 0.75
	output.surface_set_material(0,paint)
	return output

func _initialize() -> void:
	for id in ["rx78", "zaku"]:
		var source: Node3D = load("res://assets/models/" + id + ".glb").instantiate()
		var entries: Array = []
		collect(source, Transform3D.IDENTITY, entries)
		var bounds: AABB
		var first := true
		for entry in entries:
			var aabb: AABB = entry.transform * entry.node.get_aabb()
			bounds = aabb if first else bounds.merge(aabb)
			first = false
		print(id, " bounds=", bounds)
		var factor := 2.1 / bounds.size.y
		var offset := Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor
		var normalize := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * factor), offset)
		var output := Node3D.new()
		output.name = id
		var batches := {}
		for entry in entries:
			var instance: MeshInstance3D = entry.node
			var transform: Transform3D = normalize * entry.transform
			for s in range(instance.mesh.get_surface_count()):
				var primitive: int = instance.mesh.surface_get_primitive_type(s)
				if primitive != Mesh.PRIMITIVE_TRIANGLES:
					continue # SketchUp line overlays omitted in runtime mesh.
				var mat: Material = instance.mesh.surface_get_material(s)
				if id == "rx78":
					# Original is untextured white. Palette edits are explicit derivatives.
					var paint := StandardMaterial3D.new()
					paint.roughness = 0.65
					paint.metallic = 0.15
					paint.albedo_color = Color("cbd8df")
					var part_name := str(instance.name)
					if "rx8_body" in part_name: paint.albedo_color = Color("285b9a")
					elif "shield" in part_name: paint.albedo_color = Color("c03942")
					elif "gun" in part_name or "sendi" in part_name: paint.albedo_color = Color("344454")
					elif "boy_bottom" in part_name: paint.albedo_color = Color("a63b47")
					mat = paint
				var region := ""
				if id == "zaku":
					var center: Vector3 = (transform * instance.get_aabb()).get_center()
					# Source has no skin or semantic bones. Preserve complete source mesh
					# islands and classify their centers; never cut triangles at a joint.
					region = "torso"
					if center.y < 0.82:
						region = "leg_L" if center.x > 0 else "leg_R"
					elif absf(center.x) > 0.53 and center.y < 1.72:
						region = "arm_L" if center.x > 0 else "arm_R"
					elif center.y > 1.47:
						region = "head"
				var key: String = region + "_" + str(mat.get_instance_id()) if id == "zaku" else str(instance.name) + str(s)
				if not batches.has(key):
					var surface := SurfaceTool.new()
					surface.begin(primitive)
					surface.set_material(mat)
					batches[key] = {"surface": surface, "name": region + "_" + str(batches.size()) if id == "zaku" else str(instance.name)}
				batches[key].surface.append_from(instance.mesh, s, transform)
		for key in batches:
			var instance := MeshInstance3D.new()
			instance.name = batches[key].name
			var raw_mesh: ArrayMesh = batches[key].surface.commit()
			if id == "rx78": raw_mesh = paint_details(raw_mesh,batches[key].name)
			var importer := ImporterMesh.new()
			importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,raw_mesh.surface_get_arrays(0),[],{},raw_mesh.surface_get_material(0))
			importer.generate_lods(25.0,60.0,[])
			instance.mesh = importer.get_mesh()
			output.add_child(instance)
			instance.owner = output
		var packed := PackedScene.new()
		packed.pack(output)
		ResourceSaver.save(packed, "res://assets/prepared/" + id + ".scn")
		print(id, " output meshes=", batches.size())
		source.free()
		output.free()
	quit()
