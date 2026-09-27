class_name ArtLabBatch
extends RefCounted
## Art Lab v3 batch mode (docs/plan/art-lab.md section 1): several assets in ONE Godot process. The stage (ground,
## lights, shaders) is built once per light preset and warmed before the first asset (ArtLabStage.warm); every asset
## gets a fresh ArtLabRunner on the reset stage (ArtLabStage.reset: the last asset's nodes freed, lit mode).
## Entry: tools/art_lab/art_lab.gd `batch=<file or comma list>`.
## Entries: a comma list of scenes (short names work) sharing the other args, or a text file (.txt / .list) with one
## asset per line: `<scene> [key=value ...]` (per-line args override the shared ones; `#` starts a comment line).
## `kind=` is guessed from the path when missing. `out_root=<dir>` puts each scorecard in <dir>/<name>/ (default:
## docs/art/lab/<name>/ as for a single run).


## Batch entries (each a PackedStringArray of key=value args, scene= first) from a file or a comma list.
static func entries(spec: String) -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = []
	var path := spec if spec.begins_with("res://") or spec.begins_with("user://") or spec.is_absolute_path() else "res://" + spec
	var lines: PackedStringArray = []
	if (spec.ends_with(".txt") or spec.ends_with(".list")) and FileAccess.file_exists(path):
		lines = FileAccess.get_file_as_string(path).split("\n", false)
	else:
		lines = spec.split(",", false)
	for l: String in lines:
		var s := l.strip_edges()
		if s == "" or s.begins_with("#"):
			continue
		var parts := s.split(" ", false)
		var e := PackedStringArray()
		for i: int in parts.size():
			if i == 0 and not parts[i].begins_with("scene="):
				e.append("scene=" + parts[i])
			else:
				e.append(parts[i])
		out.append(e)
	return out


## The asset kind from its path (batch entries without kind=).
static func guess_kind(scene: String) -> String:
	var p := scene.to_lower()
	if not p.begins_with("res://"):
		var rs := ArtLabScenes.resolve_scene(scene)
		p = rs.to_lower() if rs != "" else p
	if p.ends_with("_set.gd"):
		return "decor_set"
	if "/vfx/" in p or p.ends_with("_vfx.gd"):
		return "vfx"
	for pair: Array in [["/mounts/", "mount"], ["/titans/", "titan"], ["/beasts/", "beast"], ["/critters/", "critter"],
			["/landmarks/", "landmark"], ["/lairs/", "landmark"], ["/buildings/", "building"]]:
		if String(pair[0]) in p:
			return pair[1]
	return "unit"


## One entry's runner args: its own args, then the shared ones it does not set (kind guessed, out from out_root).
static func entry_args(e: PackedStringArray, shared: Dictionary) -> PackedStringArray:
	var ra := PackedStringArray()
	var keys := {}
	for s: String in e:
		ra.append(s)
		keys[s.get_slice("=", 0).to_lower()] = true
	for k: String in shared:
		if not keys.has(k) and k != "out_root" and k != "out" and k != "batch":
			ra.append("%s=%s" % [k, shared[k]])
			keys[k] = true
	var scene := ""
	var nm := ""
	for s2: String in ra:
		if s2.begins_with("scene="):
			scene = s2.substr(6)
		elif s2.begins_with("name="):
			nm = s2.substr(5)
	if not keys.has("kind"):
		ra.append("kind=" + guess_kind(scene))
	if shared.has("out_root") and not keys.has("out"):
		if nm == "":
			nm = scene.get_file().get_basename().trim_suffix("_set")
		ra.append("out=%s/%s" % [String(shared["out_root"]).trim_suffix("/"), nm])
	return ra


## Runs every entry under `parent` (runners + the stage pool are its children). Returns {"rows": [{asset, result,
## quality, code, seconds, scene, kind, tier, kingdom, ground, out, headless, checks, improve}], "seconds": [per asset],
## "code": worst exit code (0 / 1 / 2), "stages": stages built}. v3 sweep (1.E): pass `pool_parent` + `pool` to keep
## the stages alive after the batch (the army silhouette pass reuses them); the caller frees them then.
static func run_all(parent: Node, list: Array[PackedStringArray], shared: Dictionary, pool_parent: Node = null,
		pool_in: Variant = null) -> Dictionary:
	# Frames are not tied to the display in a batch (`vsync=1` keeps it): a grab = 4 frames, ~90 grabs per model. The
	# lab's waits are timers (same animation time either way); capped at 240 fps so a batch does not hog the GPU.
	if DisplayServer.get_name() != "headless" and String(shared.get("vsync", "0")) != "1":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 240
	var own_pool := pool_parent == null
	var pool: Dictionary = pool_in if pool_in is Dictionary else {}
	if own_pool:
		pool_parent = Node.new()
		pool_parent.name = "StagePool"
		parent.add_child(pool_parent)
	var progress := String(shared.get("progress", "0")) == "1"
	var rows: Array[Dictionary] = []
	var per: Array[float] = []
	var worst := 0
	for e: PackedStringArray in list:
		var ra := entry_args(e, shared)
		var ta := Time.get_ticks_msec()
		var r := ArtLabRunner.new()
		r.stage_parent = pool_parent
		r.stage_pool = pool
		parent.add_child(r)
		var code: int = await r.run(ra)
		var sec := float(Time.get_ticks_msec() - ta) / 1000.0
		per.append(sec)
		worst = maxi(worst, code)
		var row := {"asset": r.asset if r.asset != "" else String(ra[0]).substr(6), "code": code, "seconds": sec,
			"result": "ERROR", "quality": -1.0, "scene": r.scene_path, "kind": String(r.kind), "tier": String(r.tier),
			"kingdom": String(r.kingdom), "ground": String(r.ground_id), "out": r.out_dir, "headless": r.headless,
			"checks": [], "improve": []}
		if r.rep != null:
			row["result"] = r.rep.result()
			row["quality"] = r.rep.quality()
			row["checks"] = r.rep.checks
			row["improve"] = r.rep.improve_next()
		rows.append(row)
		if progress:
			print("ART LAB BATCH %d / %d: %s %s %.0f (%.1f s)" % [rows.size(), list.size(), row["asset"], row["result"],
				float(row["quality"]), sec])
		r.queue_free()
		await parent.get_tree().process_frame
	var stages := pool.size()
	if own_pool:
		pool_parent.queue_free()
	return {"rows": rows, "seconds": per, "code": worst, "stages": stages}


## The summary line: total, mean, first asset (pays the stage build + warm-up) and the rest.
static func summary(res: Dictionary, total_s: float) -> String:
	var per: Array = res["seconds"]
	var n := per.size()
	var rest := 0.0
	for i: int in range(1, n):
		rest += float(per[i])
	return "ART LAB BATCH done: %d assets in %.1f s (%.1f s / asset; first %.1f s, then %.1f s / asset)" % [n, total_s,
		total_s / float(maxi(n, 1)), float(per[0]) if n > 0 else 0.0, rest / float(maxi(n - 1, 1))]
