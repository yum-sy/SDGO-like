extends SceneTree
# Bake source transforms; batch Zaku by rigid articulation region AND material.
func collect(node: Node, transform: Transform3D, result: Array) -> void:
	if node is Node3D:
		transform *= node.transform
	if node is MeshInstance3D:
		result.append({"node": node, "transform": transform})
	for child in node.get_children():
		collect(child, transform, result)

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
