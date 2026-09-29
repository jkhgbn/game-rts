extends SceneTree
## Faces pass 2026-09-28: the lowest visible vertex of a model at rest (which node), headless.
## Run: tools\godot_run.ps1 --headless --path . -s res://docs/art/faces/champions_helpers_neutral/tools/low_probe.gd --quit-after 600 -- scene=res://...


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var sc := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("scene="):
			sc = a.substr(6)
	var m := (load(sc) as PackedScene).instantiate() as Node3D
	root.add_child(m)
	for i: int in 10:
		await process_frame
	var rows: Array = []
	_walk(m, rows)
	rows.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for i: int in mini(8, rows.size()):
		print("LOW %.3f %s" % [rows[i][0], rows[i][1]])
	quit(0)


func _walk(n: Node, rows: Array) -> void:
	for c: Node in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh and (c as MeshInstance3D).is_visible_in_tree() and c.name != "Shadow":
			var mi := c as MeshInstance3D
			var lo := INF
			for s: int in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(s)
				for v: Vector3 in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
					lo = minf(lo, (mi.global_transform * v).y)
			rows.append([lo, str(mi.get_path())])
		_walk(c, rows)
