extends SceneTree
## G-C champions budget probe (headless): vertices per drawn node after _ready, per champion and class.
##   tools\godot_run.ps1 --headless --path . -s res://art/units/champions/tools/gc_count.gd --quit-after 2000 '--' all

const IDS: Array[String] = ["oathwall", "wayfinder", "coin_cutter", "mender", "wildcaller", "mage_archer"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var host := Node3D.new()
	root.add_child(host)
	for id: String in IDS:
		for v: int in 2:
			var m := (load("res://art/units/champions/%s/%s.tscn" % [id, id]) as PackedScene).instantiate() as Node3D
			if m.has_method("set_variant"):
				m.call("set_variant", v)
			host.add_child(m)
			await process_frame
			var per: Array[String] = []
			var total := 0
			var draws := 0
			for gi: Node in m.find_children("*", "GeometryInstance3D", true, false):
				if not (gi as GeometryInstance3D).visible:
					continue
				draws += 1
				if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
					var mesh := (gi as MeshInstance3D).mesh
					var nv := 0
					for s: int in mesh.get_surface_count():
						nv += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
					total += nv
					var shaders: Array[String] = []
					for s2: int in mesh.get_surface_count():
						var sm := mesh.surface_get_material(s2) as ShaderMaterial
						shaders.append(sm.shader.resource_path.get_file() if sm and sm.shader else "-")
					per.append("%s %d %s" % [m.get_path_to(gi), nv, ",".join(shaders)])
			var authored: int = int(m.call(&"authored_mesh_count")) if m.has_method("authored_mesh_count") else -1
			print("GC COUNT %s v%d: verts %d, draws %d, authored %d" % [id, v, total, draws, authored])
			for p: String in per:
				print("    ", p)
			m.queue_free()
			await process_frame
	quit(0)
