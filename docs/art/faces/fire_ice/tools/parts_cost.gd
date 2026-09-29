extends SceneTree
## Faces pass 2026-09-28: where a unit's vertices go (headless). For each scene: calls _build_parts() on a fresh,
## out-of-tree instance (nothing cached yet, so every authored part exists) and prints the heaviest parts with their
## pivot, mesh kind and vertex count. Used to find cheap trims that pay for a face.
## Run: tools\godot_run.ps1 --headless --path . -s res://docs/art/faces/fire_ice/tools/parts_cost.gd --quit-after 600 -- scenes=a.tscn,b.tscn [top=25]


func _initialize() -> void:
	var scenes := PackedStringArray()
	var top := 25
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("scenes="):
			scenes = a.substr(7).split(",")
		elif a.begins_with("top="):
			top = int(a.substr(4))
	for p: String in scenes:
		var m := (load(p) as PackedScene).instantiate()
		if m.has_method(&"_build_parts"):
			m.call(&"_build_parts")
		var rows: Array = []
		_walk(m, m, rows)
		rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
		var total := 0
		for r: Array in rows:
			total += int(r[0])
		print("PARTS %s: %d parts, %d vertices" % [p.get_file(), rows.size(), total])
		for i: int in mini(top, rows.size()):
			print("  %5d  %s" % [rows[i][0], rows[i][1]])
		m.free()
	quit(0)


func _walk(root: Node, n: Node, rows: Array) -> void:
	for c: Node in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			var mesh := (c as MeshInstance3D).mesh
			var v := 0
			for s: int in mesh.get_surface_count():
				v += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var desc := "%s/%s %s" % [root.get_path_to(n), c.name, _kind(mesh)]
			rows.append([v, desc])
		_walk(root, c, rows)


static func _kind(m: Mesh) -> String:
	if m is SphereMesh:
		return "sphere r%.3f %dx%d" % [(m as SphereMesh).radius, (m as SphereMesh).radial_segments, (m as SphereMesh).rings]
	if m is CylinderMesh:
		return "cyl %.3f/%.3f h%.2f seg%d" % [(m as CylinderMesh).top_radius, (m as CylinderMesh).bottom_radius, (m as CylinderMesh).height, (m as CylinderMesh).radial_segments]
	if m is TorusMesh:
		return "torus %.3f/%.3f rings%d x%d" % [(m as TorusMesh).inner_radius, (m as TorusMesh).outer_radius, (m as TorusMesh).rings, (m as TorusMesh).ring_segments]
	if m is CapsuleMesh:
		return "capsule r%.3f h%.2f" % [(m as CapsuleMesh).radius, (m as CapsuleMesh).height]
	if m is BoxMesh:
		return "box"
	return m.get_class() + " " + m.resource_name
