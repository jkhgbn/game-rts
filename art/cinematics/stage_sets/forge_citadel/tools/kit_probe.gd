extends SceneTree
## forge_citadel helper: measures candidate kit scenes (draws, lights, bakeable, size). Tech-art tool, not game code.
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_citadel/tools/kit_probe.gd --quit-after 600

const FMesh := preload("res://tools/world_forge/forge_mesh.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var paths: Array[String] = []
	for dir: String in ["res://art/buildings", "res://art/environment/bridges", "res://art/environment/landmarks", "res://art/environment/horizon", "res://art/environment/water"]:
		_collect(dir, paths)
	for extra: String in ["res://art/environment/ruin_pillar.tscn", "res://art/environment/crown_pedestal.tscn", "res://art/environment/map_dressing.tscn"]:
		paths.append(extra)
	for p in paths:
		if p.contains("preview") or p.contains("/tools/"):
			continue
		var ps := load(p) as PackedScene
		if ps == null:
			print("PROBE %s LOAD_FAIL" % p)
			continue
		var inst := ps.instantiate()
		var bake := FMesh.is_bakeable(inst)
		root.add_child(inst)
		await process_frame
		await process_frame
		var draws := 0
		var tris := 0
		var ab := AABB()
		var first := true
		for c: Node in inst.find_children("*", "GeometryInstance3D", true, false):
			var gi := c as GeometryInstance3D
			if not gi.is_visible_in_tree():
				continue
			if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
				var m := (gi as MeshInstance3D).mesh
				draws += m.get_surface_count()
				for s in m.get_surface_count():
					var a := m.surface_get_arrays(s)
					var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
					tris += idx.size() / 3 if idx.size() > 0 else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
				var box := gi.global_transform * m.get_aabb()
				ab = box if first else ab.merge(box)
				first = false
			elif gi is MultiMeshInstance3D:
				draws += 1
			else:
				draws += 1
		var lights := inst.find_children("*", "Light3D", true, false).size()
		print("PROBE %s draws=%d tris=%d lights=%d bake=%s size=(%.1f,%.1f,%.1f) script=%s" % [p, draws, tris, lights, bake, ab.size.x, ab.size.y, ab.size.z, inst.get_script() != null])
		inst.queue_free()
		await process_frame
	quit()


func _collect(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".tscn"):
			out.append(dir + "/" + f)
	for sd in d.get_directories():
		_collect(dir + "/" + sd, out)
