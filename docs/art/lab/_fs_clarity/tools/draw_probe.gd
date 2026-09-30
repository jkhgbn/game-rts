extends SceneTree
## Lists the visible draw instances (meshes, multimeshes, particles) of a model scene after the kit merge.
## Run: tools\godot_run.ps1 --headless --path . -s res://docs/art/lab/_fs_clarity/tools/draw_probe.gd --quit-after 600 -- scene=res://...


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var path := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("scene="):
			path = a.substr(6)
	var holder := Node3D.new()
	root.add_child(holder)
	var n: Node3D = (load(path) as PackedScene).instantiate()
	holder.add_child(n)
	for i in 10:
		await process_frame
	var total := 0
	var verts := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var info := ""
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var m := (gi as MeshInstance3D).mesh
			var v := 0
			var mats: Array[String] = []
			for s in m.get_surface_count():
				v += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				var mat := (gi as MeshInstance3D).get_active_material(s)
				mats.append(mat.resource_name if mat and mat.resource_name != "" else (mat.resource_path.get_file() if mat else "-"))
			verts += v
			info = "mesh surf %d verts %d keep=%s mats %s" % [m.get_surface_count(), v, str(gi.has_meta(&"keep_separate")), ", ".join(mats)]
		elif gi is MultiMeshInstance3D:
			info = "multimesh"
		elif gi is GPUParticles3D:
			if not (gi as GPUParticles3D).emitting:
				continue
			info = "particles emitting"
		else:
			info = gi.get_class()
		total += 1
		print("DRAW ", n.get_path_to(gi), "  ", info)
	print("DRAW TOTAL ", total, " verts ", verts)
	quit(0)
