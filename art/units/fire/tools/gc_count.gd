extends SceneTree
## G-C budget probe (headless): visible vertices / mesh nodes per Fire scene AFTER _ready (code-built parts, kit merge),
## the face kit's vertices apart (Art Lab B4 budgets the body; the face has its own allowance).
##   tools\godot_run.ps1 --headless --path . -s res://art/units/fire/tools/gc_count.gd --quit-after 600 -- [dir=user://fire_try/] [all]
## Breakdown per node helps find what to trim when a scene is over the B4 budget (2500 for a soldier).

const HALL: Array[String] = ["cinder_hand", "flame_guard", "ember_archer", "ash_hurler"]
const MORE: Array[String] = ["scorchling/scorchling", "scorchbow/scorchbow", "pyre_adept/pyre_adept",
	"kilnwarden/kilnwarden", "cinderlock/cinderlock", "cinder_arbalest/cinder_arbalest",
	"ashveil_saboteur/ashveil_saboteur"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var dirs: Array[String] = ["res://art/units/fire/"]
	var ids: Array[String] = HALL.duplicate()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("dir="):
			dirs.append(a.substr(4))
		elif a == "all":
			ids.append_array(MORE)
	for d: String in dirs:
		for id: String in ids:
			var p := d + id + ".tscn"
			if not ResourceLoader.exists(p):
				continue
			var n := (load(p) as PackedScene).instantiate() as Node3D
			root.add_child(n)
			await process_frame
			await process_frame
			var per: Dictionary = {}
			var c: Array[int] = [0, 0, 0]
			_count(n, c, per)
			var keys: Array = per.keys()
			keys.sort_custom(func(x: Variant, y: Variant) -> bool: return int(per[x]) > int(per[y]))
			var top: PackedStringArray = []
			for k: Variant in keys.slice(0, 12):
				top.append("%s %d" % [k, per[k]])
			print("GC COUNT %s: body verts %d (face %d) nodes %d | %s" % [p.trim_prefix("res://art/units/fire/"), c[1], c[2],
				c[0], ", ".join(top)])
			n.queue_free()
			await process_frame
	quit(0)


func _count(n: Node, c: Array[int], per: Dictionary) -> void:
	if n is Node3D and not (n as Node3D).visible:
		return
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		var v := 0
		for s: int in mi.mesh.get_surface_count():
			v += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if String(n.name).containsn("face"):
			c[2] += v
		else:
			c[0] += 1
			c[1] += v
			var key := "%s/%s" % [n.get_parent().name, n.name]
			per[key] = int(per.get(key, 0)) + v
	for ch: Node in n.get_children():
		_count(ch, c, per)
