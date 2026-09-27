class_name ArtLabScenes
extends RefCounted
## Art Lab (docs/plan/art-lab.md): finding scenes. Short names (`scene=sapling`, `ref=ember_archer`), the model scenes
## of a folder (sweeps, batches) and the auto-picked references of an asset (same kind, closest height + neutral
## neighbours).

static var _scene_index: Dictionary = {}   # base name -> res:// path (every .tscn under res://art/)
static var _heights: Dictionary = {}       # v3 batch: reference scene -> probed height (m), kept for the whole process


## A scene from a short name ("ember_archer", "ember_archer.tscn", "fire/ember_archer") or a path ("art/..." or
## "res://..."); "" when nothing matches.
static func resolve_scene(s: String) -> String:
	if s == "":
		return ""
	var p := s if s.begins_with("res://") else "res://" + s.trim_prefix("/")
	if p.ends_with(".tscn") and ResourceLoader.exists(p):
		return p
	if ResourceLoader.exists(p + ".tscn"):
		return p + ".tscn"
	if _scene_index.is_empty():
		_index_scenes("res://art/")
	var key := s.get_file().trim_suffix(".tscn").to_lower()
	var hit: String = _scene_index.get(key, "")
	if hit != "" and ("/" in s):
		# "fire/ember_archer": the folder part must match too
		var want := s.trim_suffix(".tscn").to_lower()
		if not hit.to_lower().trim_suffix(".tscn").ends_with(want):
			return ""
	return hit


static func _index_scenes(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f: String in d.get_files():
		if f.ends_with(".tscn"):
			var k := f.get_basename().to_lower()
			if not _scene_index.has(k):
				_scene_index[k] = dir.path_join(f)
	for sub: String in d.get_directories():
		if not sub.begins_with("."):
			_index_scenes(dir.path_join(sub))


## Model scenes of a folder (the same filter as the auto references: no previews, riders, axemen, flags).
static func list_scenes(dir: String, recursive: bool = true) -> Array[String]:
	return scenes_in(dir, recursive)


static func scenes_in(dir: String, recursive: bool) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.ends_with(".tscn") and not ("preview" in f or f.ends_with("_rider.tscn") or f.ends_with("_axeman.tscn")
				or f in ["howdah.tscn", "bounty_flag.tscn"]):
			out.append(dir.path_join(f))
	if recursive:
		for sub: String in d.get_directories():
			if sub in ["tools", "materials", "meshes", "kit", "parts", "baked"]:
				continue
			out.append_array(scenes_in(dir.path_join(sub), true))
	return out


static func auto_candidates(ctx: ArtLabRunner) -> Array:
	var same: Array[String] = []
	var near: Array[String] = []
	var u := "res://art/units/"
	match ctx.kind:
		&"unit":
			if ctx.kingdom == &"neutral":
				for s: String in scenes_in(u + "neutral/", true):
					if not ("/beasts/" in s or "/critters/" in s):
						same.append(s)
				for k: String in ["fire", "shadow", "ice", "nature"]:
					near.append_array(scenes_in(u + k + "/", false))
			else:
				same = scenes_in(u + String(ctx.kingdom) + "/", true)
				if ctx.tier == &"wizard":
					same.append_array(scenes_in(u + "wizards/", false))
				elif ctx.tier == &"champion":
					same.append_array(scenes_in(u + "champions/", true))
				for s2: String in scenes_in(u + "neutral/", true):
					if not ("/beasts/" in s2 or "/critters/" in s2):
						near.append(s2)
		&"mount":
			same = scenes_in(u + "mounts/", true)
			near = scenes_in(u + "neutral/beasts/", true)
		&"titan":
			same = scenes_in(u + "titans/", true)
			near = scenes_in(u + "neutral/beasts/", true)
		&"beast":
			same = scenes_in(u + "neutral/beasts/", true)
			near = scenes_in(u + "titans/", true)
		&"critter":
			same = scenes_in(u + "neutral/critters/", false)
			near = scenes_in(u + "neutral/", false)
		&"building":
			for s3: String in scenes_in("res://art/buildings/", true):
				var f := s3.to_lower()
				if String(ctx.kingdom) in f or (ctx.kingdom == &"shadow" and "dusk" in f):
					same.append(s3)
				elif "/capture/" in f or "/tavern/" in f or "/guilds/" in f or "trade_post" in f:
					near.append(s3)
		&"landmark":
			same = scenes_in("res://art/environment/landmarks/", false)
			near = scenes_in("res://art/environment/lairs/", false)
	same.erase(ctx.scene_path)
	near.erase(ctx.scene_path)
	return [same, near]


## Height (m) of a candidate scene (instantiated off-screen for a frame).
static func probe_height(ctx: ArtLabRunner, path: String) -> float:
	if _heights.has(path):
		return _heights[path]   # v3 batch: probed once per process
	var far := Node3D.new()
	far.position = ctx.gp + Vector3(-400.0, 0.0, 400.0)
	ctx.stage.world.add_child(far)
	var inst := ctx.spawn(path, Vector3.ZERO, 0.0, far)
	await ctx.frames(2)
	var h := 0.0
	if inst:
		var b := ArtLabCensus.world_aabb(inst, far.global_position.y)
		h = b.end.y - far.global_position.y
	far.queue_free()
	_heights[path] = h
	return h


static func pick_refs(ctx: ArtLabRunner) -> Array[String]:
	var explicit := String(ctx.opts.get("ref", ""))
	var out: Array[String] = []
	if explicit != "":
		var missing: Array[String] = []
		for r: String in explicit.split(",", false):
			var p := resolve_scene(r.strip_edges())
			if p != "":
				out.append(p)
			else:
				missing.append(r.strip_edges())
		if not missing.is_empty():
			var msg := "ref not found: %s (use a short name like ember_archer or a res:// path)" % ", ".join(missing)
			printerr("ART LAB WARNING: " + msg)
			print("ART LAB WARNING: " + msg)
			ctx.rep.add("R2r", "read", "References found", "WARN", msg, "every ref= must resolve (else R2 compares against fewer assets)",
				"Fix the ref= list")
		return out
	var box: AABB = ctx.m["box"]
	var ht := maxf(box.end.y - ctx.gp.y, 0.2)
	var cands := auto_candidates(ctx)
	for group_i: int in 2:
		var lst: Array[String] = []
		lst.assign(cands[group_i])
		var scored: Array = []
		for p2: String in lst.slice(0, 24):
			var h: float = await probe_height(ctx, p2)
			if h > 0.05:
				scored.append([absf(log(h / ht)), p2])
		scored.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		var take := 4 if group_i == 0 else 2
		for s: Array in scored.slice(0, take):
			out.append(String(s[1]))
	return out
