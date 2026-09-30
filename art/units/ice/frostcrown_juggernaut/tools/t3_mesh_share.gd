extends SceneTree
## Diagnostic (read-only): lists the meshes a 2nd / 3rd instance of a scene does not share with the 1st (Art Lab B9m).
##   tools\godot_run.ps1 --path . -s res://art/units/ice/frostcrown_juggernaut/tools/t3_mesh_share.gd --quit-after 600 --
##     --scene=res://...tscn


func _initialize() -> void:
	_run.call_deferred()


func _meshes(n: Node, out: Dictionary) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		out[(n as MeshInstance3D).mesh.get_instance_id()] = String(n.get_path())
	elif n is GPUParticles3D:
		var p := n as GPUParticles3D
		if p.draw_pass_1:
			out[p.draw_pass_1.get_instance_id()] = String(n.get_path()) + " (draw pass)"
	for c in n.get_children():
		_meshes(c, out)


func _run() -> void:
	var scene := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene = a.substr(8)
	var ps := load(scene) as PackedScene
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 10, 20)
	var a := ps.instantiate() as Node3D
	root.add_child(a)
	var far := Node3D.new()
	far.position = Vector3(400, 0, 400)
	root.add_child(far)
	var b := ps.instantiate() as Node3D
	far.add_child(b)
	var c := ps.instantiate() as Node3D
	far.add_child(c)
	c.position = Vector3(6, 0, 0)
	for i in 6:
		await process_frame
	var ma := {}
	var mb := {}
	var mc := {}
	_meshes(a, ma)
	_meshes(b, mb)
	_meshes(c, mc)
	for id: int in mb:
		if not ma.has(id) and not mc.has(id):
			print("MESHSHARE per-instance: ", mb[id])
	for id: int in mb:
		if not ma.has(id):
			print("MESHSHARE not in 1st: ", mb[id])
	print("MESHSHARE done")
	quit(0)
