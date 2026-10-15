extends SceneTree
## G-C helper: prints a Shadow scene's vertex bounds (x / z footprint, top) and the meshes that reach the extremes.
##   tools\godot_run.ps1 --headless --path . -s res://art/units/shadow/tools/gc_bounds_probe.gd --quit-after 300 '--' shadow_knight [--before]


func _initialize() -> void:
	var id := "shadow_knight"
	for a: String in OS.get_cmdline_user_args():
		if a == "--before":
			ShadowUnitDress.enabled = false
		elif not a.begins_with("--"):
			id = a
	var m := (load("res://art/units/shadow/%s.tscn" % id) as PackedScene).instantiate() as Node3D
	root.add_child(m)
	_measure.call_deferred(m, id)


func _measure(m: Node3D, id: String) -> void:
	await process_frame
	await process_frame
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	var who := {}
	for g: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		var xf := mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w := xf * v
				for ax: int in 3:
					if w[ax] < lo[ax]:
						lo[ax] = w[ax]
						who["-%d" % ax] = String(m.get_path_to(mi))
					if w[ax] > hi[ax]:
						hi[ax] = w[ax]
						who["+%d" % ax] = String(m.get_path_to(mi))
	print("GC BOUNDS %s: x %.2f..%.2f, y %.2f..%.2f, z %.2f..%.2f, footprint %.2f m2" % [id, lo.x, hi.x, lo.y, hi.y,
		lo.z, hi.z, (hi.x - lo.x) * (hi.z - lo.z)])
	print("GC BOUNDS extremes: ", who)
	quit(0)
