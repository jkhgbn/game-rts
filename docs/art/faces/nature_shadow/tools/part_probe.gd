extends SceneTree
## Lists every authored mesh part of a unit model (before the kit merge) with its vertex count, sorted, so the face
## rework can find where to trim to stay in the Art Lab B4 budget. Headless.
## Run: tools\godot_run.ps1 --headless --path . -s res://docs/art/faces/nature_shadow/tools/part_probe.gd --quit-after 20000 -- scene=res://...tscn [top=40]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := ""
	var top := 40
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("scene="):
			scene = a.substr(6)
		elif a.begins_with("top="):
			top = int(a.substr(4))
	for sp: String in scene.split(","):
		var m := (load(sp) as PackedScene).instantiate() as Node3D
		# build the parts without entering the tree (no merge): _build_parts on every model script in the scene
		var models: Array[Node] = []
		_models(m, models)
		for cm: Node in models:
			if cm.has_method(&"_build_parts"):
				cm.call(&"_build_parts")
		var rows: Array = []
		_collect(m, m, rows)
		rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
		var total := 0
		for r: Array in rows:
			total += int(r[0])
		print("PARTS ", sp, " total=", total, " parts=", rows.size())
		for i: int in mini(top, rows.size()):
			print("PARTS   %5d  %s" % [rows[i][0], rows[i][1]])
		m.free()
	quit(0)


func _models(n: Node, out: Array[Node]) -> void:
	if n is CharacterModel:
		out.append(n)
	for c: Node in n.get_children():
		_models(c, out)


func _collect(model: Node3D, n: Node, rows: Array) -> void:
	for c: Node in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh and (c as MeshInstance3D).visible:
			var mi := c as MeshInstance3D
			var cnt := 0
			for s: int in mi.mesh.get_surface_count():
				cnt += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var p := Vector3.ZERO
			var q: Node = mi
			while q and q != model:
				p += (q as Node3D).position
				q = q.get_parent()
			var mat := mi.material_override
			var mn := (mat.resource_path.get_file() if mat and mat.resource_path != "" else ("-" if mat == null else mat.resource_name))
			var desc := mi.mesh.get_class()
			if mi.mesh is SphereMesh:
				desc = "Sphere r%.3f %dx%d" % [(mi.mesh as SphereMesh).radius, (mi.mesh as SphereMesh).radial_segments, (mi.mesh as SphereMesh).rings]
			elif mi.mesh is CylinderMesh:
				desc = "Cyl %.3f/%.3f h%.2f s%d" % [(mi.mesh as CylinderMesh).top_radius, (mi.mesh as CylinderMesh).bottom_radius, (mi.mesh as CylinderMesh).height, (mi.mesh as CylinderMesh).radial_segments]
			elif mi.mesh is TorusMesh:
				desc = "Torus %.3f-%.3f r%d s%d" % [(mi.mesh as TorusMesh).inner_radius, (mi.mesh as TorusMesh).outer_radius, (mi.mesh as TorusMesh).rings, (mi.mesh as TorusMesh).ring_segments]
			elif mi.mesh is CapsuleMesh:
				desc = "Capsule r%.3f %dx%d" % [(mi.mesh as CapsuleMesh).radius, (mi.mesh as CapsuleMesh).radial_segments, (mi.mesh as CapsuleMesh).rings]
			rows.append([cnt, "%s  %s  at %s  scl %s  %s%s" % [String(model.get_path_to(mi.get_parent())), desc,
				str(p).replace(" ", ""), str(mi.scale).replace(" ", ""), mn, " SEP" if mi.has_meta(&"keep_separate") else ""]])
		_collect(model, c, rows)
