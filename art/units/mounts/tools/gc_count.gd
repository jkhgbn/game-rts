extends SceneTree
## G-C mounts + titans budget probe (headless): visible vertices per draw node and per material AFTER _ready (the kit
## merge), so a pass can see what to trim when a model is over its Art Lab B4 budget (mount 6000, titan 12000 soft).
##   tools\godot_run.ps1 --headless --path . -s res://art/units/mounts/tools/gc_count.gd --quit-after 900 -- [ids=a,b] [mats]

const SCENES: Array[String] = ["mounts/ember_boar/ember_boar", "mounts/dusk_steed/dusk_steed", "mounts/grove_stag/grove_stag",
	"mounts/rimehorn/rimehorn", "mounts/roan_courser/roan_courser", "titans/cinder_dragon/cinder_dragon",
	"titans/frost_dragon/frost_dragon", "titans/elder_treant/elder_treant", "titans/nightmare_knight/nightmare_knight",
	"titans/war_mammoth/war_mammoth"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var only: PackedStringArray = []
	var mats := false
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("ids="):
			only = a.substr(4).split(",")
		elif a == "mats":
			mats = true
	for sp: String in SCENES:
		var id := sp.get_file()
		if not only.is_empty() and not only.has(id):
			continue
		var n := (load("res://art/units/%s.tscn" % sp) as PackedScene).instantiate() as Node3D
		root.add_child(n)
		await process_frame
		await process_frame
		var per: Dictionary = {}
		var by_mat: Dictionary = {}
		var c: Array[int] = [0, 0]
		_count(n, n, c, per, by_mat)
		print("GC COUNT %s: verts %d, draw nodes %d | %s" % [id, c[1], c[0], _top(per, 14)])
		if mats:
			print("   by material: %s" % _top(by_mat, 20))
		n.queue_free()
		await process_frame
	quit(0)


func _top(d: Dictionary, k: int) -> String:
	var keys: Array = d.keys()
	keys.sort_custom(func(x: Variant, y: Variant) -> bool: return int(d[x]) > int(d[y]))
	var out: PackedStringArray = []
	for key: Variant in keys.slice(0, k):
		out.append("%s %d" % [key, d[key]])
	return ", ".join(out)


func _count(top: Node, n: Node, c: Array[int], per: Dictionary, by_mat: Dictionary) -> void:
	if n is Node3D and not (n as Node3D).visible:
		return
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		var v := 0
		for s: int in mi.mesh.get_surface_count():
			var sv: int = (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			v += sv
			var mat: Material = mi.get_active_material(s)
			var mk: String = mat.resource_path.get_file() if mat and mat.resource_path != "" else "<built-in>"
			by_mat[mk] = int(by_mat.get(mk, 0)) + sv
		c[0] += 1
		c[1] += v
		var key := String(top.get_path_to(mi.get_parent()))
		per[key] = int(per.get(key, 0)) + v
	for ch: Node in n.get_children():
		_count(top, ch, c, per, by_mat)
