extends SceneTree
## Draw census of the built forge_evenmead scene per puppet / place (set-only helper, same counting as World Forge B1:
## mesh surfaces + 1 per MultiMesh / particles node).
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_evenmead/tools/draws.gd --quit-after 600

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var inst: Node3D = (load("res://art/cinematics/stage_sets/forge_evenmead/forge_evenmead.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for k in 5:
		await process_frame
	var total := 0
	for group: String in ["Puppets", "Placed"]:
		var g := inst.get_node_or_null(group)
		if g == null:
			continue
		for c in g.get_children():
			var d := _count(c)
			total += d
			print("DRAWS %-16s %3d" % [c.name, d])
	for c in inst.get_children():
		if c is MeshInstance3D:
			var d := _count(c)
			total += d
			print("DRAWS %-16s %3d" % [c.name, d])
	print("DRAWS total %d" % total)
	quit()


func _count(n: Node) -> int:
	var d := 0
	if n is MeshInstance3D and (n as MeshInstance3D).mesh and (n as GeometryInstance3D).is_visible_in_tree():
		d += (n as MeshInstance3D).mesh.get_surface_count()
	elif n is MultiMeshInstance3D or n is GPUParticles3D or n is CPUParticles3D:
		if (n as GeometryInstance3D).is_visible_in_tree():
			d += 1
	for c in n.get_children():
		d += _count(c)
	return d
