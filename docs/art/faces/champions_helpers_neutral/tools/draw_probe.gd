extends SceneTree
## Faces pass 2026-09-28: the draw instances of a model after _ready (the kit merge done): every visible
## GeometryInstance3D with its surfaces and vertices, and the totals (Art Lab B2 / B4 style). Headless.
## Run: tools\godot_run.ps1 --headless --path . -s res://docs/art/faces/champions_helpers_neutral/tools/draw_probe.gd
##      --quit-after 900 -- scenes=a.tscn,b.tscn


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scenes := PackedStringArray()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("scenes="):
			scenes = a.substr(7).split(",")
	for p: String in scenes:
		var m := (load(p) as PackedScene).instantiate() as Node3D
		root.add_child(m)
		for i: int in 8:
			await process_frame
		var rows: Array = []
		_walk(m, m, rows)
		var dv := 0
		var ds := 0
		for r: Array in rows:
			dv += int(r[1])
			ds += int(r[2])
		print("DRAW %s: %d instances, %d surfaces, %d vertices" % [p.get_file(), rows.size(), ds, dv])
		for r: Array in rows:
			print("   %-60s %2d surf %5d v" % [r[0], r[2], r[1]])
		m.queue_free()
		await process_frame
	quit(0)


func _walk(top: Node, n: Node, rows: Array) -> void:
	for c: Node in n.get_children():
		if c is GeometryInstance3D and (c as GeometryInstance3D).is_visible_in_tree():
			var v := 0
			var sc := 0
			if c is MeshInstance3D and (c as MeshInstance3D).mesh:
				var mesh := (c as MeshInstance3D).mesh
				sc = mesh.get_surface_count()
				for s: int in sc:
					v += mesh.surface_get_array_len(s)
			elif c is GPUParticles3D:
				sc = 1
			elif c is MultiMeshInstance3D:
				sc = 1
			rows.append([String(top.get_path_to(c)) + " (" + c.get_class() + ")", v, sc])
		_walk(top, c, rows)
