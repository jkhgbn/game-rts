extends SceneTree
## cine -> game: bakes `data/cinematics/<id>.tres` and saves the runtime stage `scenes/cinematics/<id>.tscn` (a
## CinematicStage with the movie's World Forge sets, its `prop` / `cast` lines posed as `cine` poses them, a LightingRig
## that takes each set's LightingPreset, and every actor tag registered in `actor_paths`). The saved scene only uses
## game resources (art/, data/, scripts/): the game never needs tools/ (tools/* is excluded from the export).
## Run (headless, ~20 s):
##   $GODOT --headless --path . -s tools/cine/cine_stage_export.gd --quit-after 3000 -- prologue_3min
## Prints `CINE export <id>: PASS ...` (or FAIL + why). Re-run after changing the .cine or a set.

const OUT_DIR := "res://scenes/cinematics/"
const DATA_DIR := "res://data/cinematics/"
const RIG_SCRIPT := "res://art/environment/lighting/lighting_rig.gd"


var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true   # first frame: the root is inside the tree (global transforms work)
	_run()
	return false


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var id := String(args[0]) if args.size() > 0 else "prologue_3min"
	var err := _export(id)
	if err == "":
		print("CINE export %s: PASS -> %s%s.tscn + %s%s.tres" % [id, OUT_DIR, id, DATA_DIR, id])
	else:
		print("CINE export %s: FAIL %s" % [id, err])
	quit(0 if err == "" else 1)


func _export(id: String) -> String:
	var src := CineDoc.source_of(id)
	if not FileAccess.file_exists(src):
		return "no source " + src
	var doc := CineDoc.load_file(src)
	var stage := CineStage.new()
	root.add_child(stage)
	stage.build(doc, false)
	var bake := CineBake.run(doc, stage)
	for p: Dictionary in stage.problems:
		if String(p.get("status", "")) == "FAIL":
			return "stage: %s %s" % [p.get("name", ""), p.get("value", "")]
	var res := bake.to_resource()
	if res == null:
		return "bake: runtime classes missing"
	var scene_path := OUT_DIR + id + ".tscn"
	var tres_path := DATA_DIR + id + ".tres"
	res.set(&"stage_scene", scene_path)
	if ResourceSaver.save(res, tres_path) != OK:
		return "cannot write " + tres_path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	# ---- the runtime stage: sets, props and cast moved (world transforms kept) under a CinematicStage
	var rt := CinematicStage.new()
	rt.name = id.to_pascal_case() + "Stage"
	root.add_child(rt)
	var moved: Array[Node] = []
	for sid: String in stage.set_order:
		var sn: Node3D = stage.sets[sid]["node"]
		sn.reparent(rt, true)
		moved.append(sn)
	if not stage.multi and stage.set_node != null and stage.set_node.get_parent() == stage:
		stage.set_node.reparent(rt, true)
		moved.append(stage.set_node)
	# props / cast placed directly on the stage (no set=): instanced scenes only (capsules = voice-over stand-ins)
	for c: Node in stage.get_children():
		if c is Node3D and c.scene_file_path != "" and not c in moved:
			(c as Node3D).reparent(rt, true)
			moved.append(c)
	# props / cast placed in a set (set=): children of the set instance that the set scene does not have
	for sn2: Node in moved:
		_own(sn2, rt)
		for c2: Node in sn2.get_children():
			if c2.owner != sn2 and c2.scene_file_path != "":
				_own(c2, rt)
	# lighting: each set's LightingPreset, the cine env for a set without one
	if ResourceLoader.exists(RIG_SCRIPT):
		var rig := (load(RIG_SCRIPT) as Script).new() as Node3D
		rig.name = "LightingRig"
		var fb: Variant = stage.get(&"_fallback_preset")
		if fb is Resource:
			rig.set(&"preset", fb)
		rt.add_child(rig)
		rig.owner = rt
		rt.lighting_rig = NodePath("LightingRig")
	# every actor tag -> its node (set puppets whose tag cine prefixed, e.g. malrik_army_host, and cast in sets)
	var paths := {}
	for tag: String in stage.actors:
		var n: Node = stage.actors[tag]
		if n != null and rt.is_ancestor_of(n):
			paths[tag] = rt.get_path_to(n)
	rt.actor_paths = paths
	rt.autoplay_script = load(tres_path) as CinematicScript
	rt.autoplay = true
	var ps := PackedScene.new()
	var perr := ps.pack(rt)
	if perr != OK:
		return "pack failed (%d)" % perr
	if ResourceSaver.save(ps, scene_path) != OK:
		return "cannot write " + scene_path
	print("CINE export %s: %d sets, %d actors, %d shots, %.1f s" % [id, stage.set_order.size(), paths.size(),
			(res.get(&"shots") as Array).size(), float(res.call(&"total_duration"))])
	return ""


## Marks an instanced node as saved in the packed stage (its own children stay in its scene).
func _own(n: Node, owner_node: Node) -> void:
	n.owner = owner_node
