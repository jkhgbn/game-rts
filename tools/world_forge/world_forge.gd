extends SceneTree
## World Forge CLI (tools/world_forge/README.md). Run through tools/world_forge/run_world_forge.ps1:
##   run_world_forge.ps1 <verb> <id> [key=value...]
## Verbs: help, check <set>, build <set>, sheet <set> (windowed stills), map <map>, export-map <crown_hollow|scene path>,
##        demo (the acceptance demo: set forge_watch_keep, map fourfold_hollow, Crown Hollow round trip).
## Exit codes: 0 PASS / WARN, 1 FAIL, 2 bad input (spec errors name file:line, token and "did you mean").

const FSet := preload("res://tools/world_forge/forge_set.gd")
const Checks := preload("res://tools/world_forge/forge_set_checks.gd")
const FMap := preload("res://tools/world_forge/forge_map.gd")
const Report := preload("res://tools/world_forge/forge_report.gd")

const Gen := preload("res://tools/world_forge/forge_gen.gd")
const Sheet := preload("res://tools/world_forge/forge_sheet.gd")
const Grammar := preload("res://tools/world_forge/forge_map_grammar.gd")

const VERBS: Array[String] = ["help", "check", "build", "sheet", "map", "export-map", "demo", "fix", "gen", "template", "mapsheet"]
const FIX_ROUNDS := 3   ## map-production.md 9: auto-fix stops after 3 rounds (was 5)

var opts := {}
var verb := ""
var id := ""
var frame := 0
var step := 0
var t0 := 0
var fs: FSet
var holder: Node3D
var inst: Node3D
var queue: Array = []     ## demo: [[verb, id], ...]
var results: Array[String] = []
var worst := 0
var fmap: FMap
var base_opts := {}
var fix_round := 0
var fix_log: Array[String] = []
var fix_best := {}       ## fix: the best round so far {rank, round, text} (review M3 rollback)
var gen_runs := {}      ## gen: candidate id -> {grid, text path, lab score / result, fixes} (filled as jobs end)
var gen_info := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	verb = String(opts.get("verb", "help"))
	id = String(opts.get("id", ""))
	if not VERBS.has(verb):
		print("WORLD FORGE: unknown verb \"%s\" -> did you mean \"%s\"? (verbs: %s)" % [verb, _near(verb, VERBS), ", ".join(VERBS)])
		quit(2)
		return
	if verb == "help":
		print(help_text())
		quit(0)
		return
	base_opts = opts.duplicate()
	if verb == "demo":
		queue = [["build", "forge_watch_keep"], ["map", "fourfold_hollow"], ["export-map", "crown_hollow"], ["map", "crown_hollow"]]
	else:
		if id == "":
			print("WORLD FORGE: %s wants an id (run_world_forge.ps1 %s <id>)" % [verb, verb])
			quit(2)
			return
		if verb == "template" and id == "all":
			for t in Grammar.list_templates():
				queue.append(["template", t])
		else:
			queue = [[verb, id]]
	_next_job()


func _near(t: String, choices: Array) -> String:
	var best := ""
	var bs := -1.0
	for c: String in choices:
		var s := t.similarity(c)
		if s > bs:
			bs = s
			best = c
	return best


func _next_job() -> void:
	if queue.is_empty():
		for r in results:
			print(r)
		quit(worst)
		return
	var job: Array = queue.pop_front()
	verb = job[0]
	id = job[1]
	opts = base_opts.duplicate()
	if job.size() > 2:
		for k: String in job[2]:
			opts[k] = job[2][k]
	frame = 0
	step = 0
	t0 = Time.get_ticks_usec()
	match verb:
		"check", "build", "sheet":
			_start_set()
		"map":
			_start_map()
		"fix":
			fix_round = int(opts.get("round", 0))
			if fix_round == 0:
				fix_log.clear()
				fix_best = {}
			if not opts.has("spec") and not FileAccess.file_exists("%s/%s.map" % [FMap.MAPS_DIR, id]) and FileAccess.file_exists("%s/%s.map" % [Gen.GEN_DIR, id]):
				opts["spec"] = "%s/%s.map" % [Gen.GEN_DIR, id]
			_start_map()
		"template":
			_start_template()
		"export-map":
			_start_export()
		"gen":
			_start_gen()
		"gen_sheet":
			_gen_sheet()
		"mapsheet":
			_start_mapsheet()


func _finish(code: int, line: String) -> void:
	results.append(line)
	worst = maxi(worst, code)
	if holder and is_instance_valid(holder):
		holder.queue_free()
	holder = null
	inst = null
	# let queued frees run before the next job
	step = -100
	frame = 0


func _process(_delta: float) -> bool:
	frame += 1
	if step == -100:
		if frame > 2:
			step = 0
			_next_job()
		return false
	match verb:
		"check", "build":
			_tick_set()
		"sheet":
			_tick_sheet()
		"map", "fix", "template":
			_tick_map()
		"export-map":
			_tick_export()
		"mapsheet":
			_tick_mapsheet()
	return false


# ---------------------------------------------------------------- sets

func spec_path(set_id: String) -> String:
	return "%s/%s/%s.set" % [FSet.SETS_DIR, set_id, set_id]


func _start_set() -> void:
	fs = FSet.new()
	var path := String(opts.get("spec", spec_path(id)))
	if not fs.compile(path):
		for l in fs.spec.error_lines():
			print("ERROR " + l)
		for l in fs.spec.warning_lines():
			print("WARN  " + l)
		print("WORLD FORGE set %s: BAD INPUT (%d errors)" % [id, fs.spec.errors.size()])
		_finish(2, "WORLD FORGE set %s: BAD INPUT" % id)
		return
	for l in fs.spec.warning_lines():
		print("WARN  " + l)
	fs.report.setup(verb, id)
	holder = Node3D.new()
	holder.name = "ForgeHolder"
	root.add_child(holder)
	step = 1


func _tick_set() -> void:
	match step:
		1:
			fs.build(holder)
			step = 2
			frame = 0
		2:
			if frame < 3:
				return
			var built: Node3D = holder.get_child(0)
			if verb == "build":
				fs.save(built)
				built.queue_free()
				step = 3
			else:
				inst = built
				step = 4
			frame = 0
		3:
			if frame < 2:
				return
			var scene_path := "%s/%s.tscn" % [fs.set_dir(), id]
			ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_REPLACE)
			inst = (load(scene_path) as PackedScene).instantiate()
			holder.add_child(inst)
			step = 4
			frame = 0
		4:
			if frame < 4:
				return
			Checks.run(fs, inst)
			var h1 := fs.layout_hash()
			# determinism: rebuild the layout from the same spec in memory
			var fs2 := FSet.new()
			fs2.compile(fs.plan["path"])
			var h2_holder := Node3D.new()
			holder.add_child(h2_holder)
			fs2.build(h2_holder)
			var h2 := fs2.layout_hash()
			h2_holder.queue_free()
			fs.report.fcheck("D1", "Deterministic layout", "PASS" if h1 == h2 else "FAIL", "%s vs %s" % [h1, h2],
				"same spec + seed = the same layout (every transform)", "a scatter / row depends on something outside the spec", 1.5)
			fs.report.hash_value = h1
			var od := fs.out_dir()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(od))
			var img := Checks.plan_image(fs)
			img.save_png(od + "/plan.png")
			fs.report.files.append(od + "/plan.png")
			if verb == "build":
				var md5s: Array[String] = []
				for f in fs.report.files:
					if f.ends_with(".res"):
						md5s.append(f.get_file() + " " + FileAccess.get_md5(f).substr(0, 8))
				fs.report.notes.append("Mesh file md5: " + ", ".join(md5s))
			fs.report.notes.append("Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).")
			var code := fs.report.done(verb == "build")
			_finish(code, "WORLD FORGE set %s: %s quality %.0f" % [id, fs.report.result(), fs.report.quality()])


# ---------------------------------------------------------------- sheet (windowed stills)

var _shots: Array = []   ## [[label, cam, look, fov]]
var _cam: Camera3D
var _rig: Node
var _label: Label
var _images: Array = []  ## [[label, Image]]


func _tick_sheet() -> void:
	match step:
		1:
			if DisplayServer.get_name() == "headless":
				print("WORLD FORGE sheet: needs a window (run without --headless; the ps1 does this)")
				_finish(2, "WORLD FORGE sheet %s: needs a window" % id)
				return
			var scene_path := "%s/%s.tscn" % [fs.set_dir(), id]
			if not ResourceLoader.exists(scene_path):
				print("WORLD FORGE sheet: %s not built yet (run build first)" % scene_path)
				_finish(2, "WORLD FORGE sheet %s: not built" % id)
				return
			root.size = Vector2i(1600, 900)
			DisplayServer.window_set_size(Vector2i(1600, 900))
			inst = (load(scene_path) as PackedScene).instantiate()
			holder.add_child(inst)
			_rig = LightingRig.new()
			_rig.set(&"preset", inst.get(&"lighting"))
			holder.add_child(_rig)
			_cam = Camera3D.new()
			_cam.near = 0.1
			_cam.far = 400.0
			holder.add_child(_cam)
			_cam.current = true
			var layer := CanvasLayer.new()
			layer.layer = 10
			holder.add_child(layer)
			for y in [0, 1]:
				var bar := ColorRect.new()
				bar.color = Color.BLACK
				var bh := int((900.0 - 1600.0 / 2.39) * 0.5)
				bar.position = Vector2(0, 0 if y == 0 else 900 - bh)
				bar.size = Vector2(1600, bh)
				layer.add_child(bar)
			_label = Label.new()
			_label.position = Vector2(16, 8)
			_label.add_theme_font_size_override(&"font_size", 28)
			layer.add_child(_label)
			for m: Dictionary in fs.plan["marks"]:
				for ph: Array in [["a", 0.0], ["b", 0.5], ["c", 1.0]]:
					var t: float = ph[1]
					_shots.append(["%s_%s" % [m["shot"], ph[0]], (m["from"] as Vector3).lerp(m["to"], t),
						(m["look_from"] as Vector3).lerp(m["look_to"], t), lerpf(m["fov_from"], m["fov_to"], t), t * float(m["dur"])])
			var sz: Vector2 = fs.plan["size"]
			_shots.append(["top", Vector3(0, maxf(sz.x, sz.y) * 1.25, 0.01), Vector3.ZERO, 0.0])
			step = 2
			frame = 0
		2:
			if _shots.is_empty():
				step = 5
				return
			var s: Array = _shots[0]
			if s[0] == "top":
				_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
				_cam.size = maxf(fs.plan["size"].x / 1.7778, fs.plan["size"].y) * 1.02
				_cam.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), s[1])
			else:
				_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
				_cam.fov = s[3]
				_cam.global_transform = Transform3D.IDENTITY.translated(s[1]).looking_at(s[2], Vector3.UP)
			# timed actors (flocks) pose at the mark's a / b / c time (s[4] = t * dur)
			call_group(&"cine_timed", &"set_cine_time", float(s[4]) if s.size() > 4 else 0.0)
			_label.text = "%s  %s" % [id, s[0]]
			step = 3
			frame = 0
		3:
			if frame < 12:
				return
			var img := root.get_texture().get_image()
			_images.append([_shots[0][0], img])
			_shots.pop_front()
			step = 2
		5:
			var od := fs.out_dir()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(od + "/stills"))
			var tw := 400
			var th := 225
			var cols := 3
			var rows := int(ceil(_images.size() / float(cols)))
			var sheet := Image.create(tw * cols, th * rows, false, Image.FORMAT_RGBA8)
			sheet.fill(Color(0.1, 0.1, 0.1))
			var k := 0
			for e: Array in _images:
				var img: Image = e[1]
				img.convert(Image.FORMAT_RGBA8)
				img.save_png("%s/stills/%s.png" % [od, e[0]])
				var small := img.duplicate() as Image
				small.resize(tw, th, Image.INTERPOLATE_BILINEAR)
				sheet.blit_rect(small, Rect2i(0, 0, tw, th), Vector2i((k % cols) * tw, (k / cols) * th))
				k += 1
			sheet.save_png(od + "/sheet.png")
			print("WORLD FORGE sheet %s: %d stills -> %s/sheet.png (+ stills/*.png, top.png = top-down)" % [id, _images.size(), od])
			_finish(0, "WORLD FORGE sheet %s: %d stills" % [id, _images.size()])


# ---------------------------------------------------------------- maps

func _start_map() -> void:
	fmap = FMap.new()
	holder = Node3D.new()
	holder.name = "ForgeMapHolder"
	root.add_child(holder)
	var err := fmap.start_map(id, opts, holder)
	if err != "":
		print(err)
		_finish(2, "WORLD FORGE map %s: BAD INPUT" % id)
		return
	step = 1


func _tick_map() -> void:
	var r := fmap.tick_map(frame)
	if r.is_empty():
		return
	if verb == "fix":
		_fix_step(r)
		return
	if verb == "template":
		print("  template %s: %s" % [id.trim_prefix("tpl_"), String(r["line"])])
	_record_run(int(r["code"]))
	_finish(int(r["code"]), String(r["line"]))


## gen bookkeeping: the candidate's final Map Lab numbers (gen_sheet reads them).
func _record_run(code: int) -> void:
	if not opts.has("gen"):
		return
	gen_runs[id] = {"lab_score": fmap.lab_score, "lab_result": fmap.lab_result, "lab_fails": fmap.lab_fails, "code": code,
		"rounds": fix_round, "fixes_left": fmap.lab_fixes.size(), "spec": String(opts.get("spec", "")), "log": fix_log.duplicate()}


# ---------------------------------------------------------------- fix (map-production.md 2.5 / 9: auto-fix, 3 rounds)

## A fix round's rank (higher = better): Map Lab score, minus 100 per FAIL check and 50 for a World Forge FAIL (L1-L3).
func _fix_rank(code: int) -> float:
	return fmap.lab_score - 100.0 * float(fmap.lab_fails) - (50.0 if code != 0 else 0.0)


func _fix_step(r: Dictionary) -> void:
	var rounds := int(opts.get("rounds", FIX_ROUNDS))
	var path := String(opts.get("spec", "%s/%s.map" % [FMap.MAPS_DIR, id]))
	var ok := fmap.lab_fails == 0 and fmap.lab_score >= FMap.LAB_MIN and fmap.lab_result != "FAIL" and int(r["code"]) == 0
	fix_log.append("round %d: Map Lab %s %.0f (%d FAIL checks), %d fixable move(s)" % [fix_round, fmap.lab_result, fmap.lab_score,
		fmap.lab_fails, fmap.lab_fixes.size()])
	print("  fix %s %s" % [id, fix_log[fix_log.size() - 1]])
	# review M3: remember the best round's .map text; a final round worse than it is rolled back
	var rank := _fix_rank(int(r["code"]))
	if fix_round == 0 or rank > float(fix_best.get("rank", -INF)):
		fix_best = {"rank": rank, "round": fix_round, "text": FileAccess.get_file_as_string(path)}
	if bool(opts.get("rollback", false)):
		# the re-run of the restored best round: report it as is
		_record_run(0 if ok else 1)
		var rl := "WORLD FORGE fix %s: rolled back to round %d; Map Lab %s %.0f" % [id, int(opts.get("best_round", 0)), fmap.lab_result, fmap.lab_score]
		fix_log.clear()
		fix_best = {}
		_finish(0 if ok else 1, rl)
		return
	if ok or fix_round >= rounds or fmap.lab_fixes.is_empty():
		if not ok and int(fix_best.get("round", fix_round)) != fix_round:
			# the last round is worse than an earlier one: restore that round's .map and rebuild its layout once more
			var best_round := int(fix_best["round"])
			_write(path, String(fix_best["text"]))
			print("  fix %s: round %d is worse than round %d: .map restored (layout rebuilt next)" % [id, fix_round, best_round])
			fix_log.append("round %d worse than round %d: rolled back" % [fix_round, best_round])
			var again0 := opts.duplicate()
			again0["round"] = fix_round
			again0["rollback"] = true
			again0["best_round"] = best_round
			queue.push_front(["fix", id, again0])
			if holder and is_instance_valid(holder):
				holder.queue_free()
			holder = null
			step = -100
			frame = 0
			return
		var why := "PASS" if ok else ("needs a designer (%s)" % ("no fixable finding left" if fmap.lab_fixes.is_empty() else "%d rounds used" % rounds))
		_record_run(0 if ok else 1)
		var line := "WORLD FORGE fix %s: %s after %d fix round(s); Map Lab %s %.0f" % [id, why, fix_round, fmap.lab_result, fmap.lab_score]
		fix_log.clear()
		fix_best = {}
		_finish(0 if ok else 1, line)
		return
	var changed := FMap.apply_fixes(path, fmap.layout, fmap.lab_fixes, fix_round + 1)
	for c in changed:
		print("    autofix " + c)
	# the same job again, one round later
	var again := opts.duplicate()
	again["round"] = fix_round + 1
	queue.push_front(["fix", id, again])
	if holder and is_instance_valid(holder):
		holder.queue_free()
	holder = null
	step = -100
	frame = 0


# ---------------------------------------------------------------- template (mini Lab check of one template)

func _start_template() -> void:
	var tname := id
	var tid := "tpl_" + tname
	var od := "%s/%s" % [FMap.OUT_DIR, tid]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(od))
	var path := "%s/%s.map" % [od, tid]
	var body := "use %s t  at=(0,0)  yaw=0\n" % tname
	# a first pass for the extent and whether the template brings its own keep
	_write(path, "map %s  size=200  symmetry=none  title=\"Template %s\"\nseat 0 name=\"ref\" side=0 frame=identity\n%s" % [tid, tname, body])
	var probe := FMap.new()
	if not probe.compile(path):
		for l in probe.spec.error_lines():
			print("ERROR " + l)
		_finish(2, "WORLD FORGE template %s: BAD INPUT" % tname)
		return
	var ext := 10.0
	for s: Dictionary in probe.layout.spots:
		ext = maxf(ext, maxf(absf(s["pos"].x), absf(s["pos"].z)))
	for b: Dictionary in probe.layout.blocks:
		ext = maxf(ext, maxf(absf(b["center"].x), absf(b["center"].z)) + Vector2(b["half"].x, b["half"].z).length())
	for a: Dictionary in probe.layout.river:
		for p: Vector3 in (a["poly"] as PackedVector3Array):
			ext = maxf(ext, minf(maxf(absf(p.x), absf(p.z)), 90.0))
	var size := minf(ceilf((ext + 22.0) / 4.0) * 8.0, 184.0)
	var head := "map %s  size=%.0f  symmetry=none  title=\"Template %s\"\nseat 0 name=\"ref\" side=0 frame=identity\nrules archetype=template\n" % [tid, size, tname]
	if probe.layout.spots_of("keep").is_empty():
		head += "keep ref  at=(%.1f,%.1f)  team=0  solo\n" % [-size * 0.5 + 9.0, size * 0.5 - 9.0]
	_write(path, head + body)
	id = tid
	opts["spec"] = path
	_start_map()


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


# ---------------------------------------------------------------- gen (map-production.md 2.4)

func _start_gen() -> void:
	var arch := String(opts.get("archetype", "river_split"))
	var players := int(String(opts.get("players", "2")))
	var tempo := String(opts.get("tempo", "standard"))
	var biome := String(opts.get("biome", "grass"))
	if not Gen.ARCHETYPES.has(arch) or not players in [2, 4] or not Gen.TEMPOS.has(tempo):
		print("WORLD FORGE gen: archetype in %s, players 2 or 4, tempo in %s" % [", ".join(Gen.ARCHETYPES), ", ".join(Gen.TEMPOS)])
		_finish(2, "WORLD FORGE gen %s: BAD INPUT" % id)
		return
	var g := Gen.new(id, arch, players, tempo, biome, float(String(opts.get("size", "0"))))
	var seed0 := int(String(opts.get("seed", "1")))
	var count := int(String(opts.get("count", "40")))
	var full := int(String(opts.get("full", "3")))
	var od := "%s/gen_%s" % [FMap.OUT_DIR, id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(od + "/cand"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(Gen.GEN_DIR))
	var cands: Array = []
	var tg0 := Time.get_ticks_usec()
	for s in range(seed0, seed0 + count):
		var cp := "%s/cand/%s_s%d.map" % [od, id, s]
		_write(cp, g.map_text(s))
		var sc := g.score_file(cp)
		sc["seed"] = s
		sc["path"] = cp
		cands.append(sc)
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) < float(b["score"]))
	var sweep_s := float(Time.get_ticks_usec() - tg0) / 1e6
	var tg: Dictionary = g.targets()
	var rows := "| # | Seed | Grid score | Unreachable | Spacing FAIL | %s | contest |\n|---|---|---|---|---|%s---|\n" % [" | ".join(tg.keys()), "---|".repeat(tg.size())]
	var k := 1
	for c: Dictionary in cands:
		var cells: Array[String] = []
		var m: Dictionary = c.get("measures", {})
		for key: String in tg:
			cells.append("-" if not m.has(key) else ("%.2f" % float(m[key]) if key == "enemy_ally" else "%.0f" % float(m[key])))
		rows += "| %d | %d | %.2f | %d | %d | %s | %s |\n" % [k, c["seed"], float(c["score"]), int(c.get("unreachable", 0)), int(c.get("close", 0)), " | ".join(cells),
			str(m.get("contest", "-"))]
		k += 1
	gen_info = {"id": id, "archetype": arch, "players": players, "tempo": tempo, "biome": biome, "size": g.size, "count": count,
		"sweep_s": sweep_s, "rows": rows, "targets": tg, "cands": cands.slice(0, full)}
	var picks: Array[String] = []
	# review H2: a candidate with a spacing FAIL (stacked spots, overlapping structures, a doubled guild house) is
	# rejected before the Map Lab, whatever its grid score
	var good := cands.filter(func(c: Dictionary) -> bool: return not is_inf(float(c["score"])) and int(c.get("close", 0)) == 0)
	gen_info["cands"] = good.slice(0, full)
	for c: Dictionary in good.slice(0, full):
		var cid := "%s_s%d" % [id, c["seed"]]
		var gp := "%s/%s.map" % [Gen.GEN_DIR, cid]
		_write(gp, FileAccess.get_file_as_string(String(c["path"])))
		queue.append(["fix", cid, {"spec": gp, "gen": id, "rounds": int(String(opts.get("rounds", str(FIX_ROUNDS)))), "live": String(opts.get("live", "0"))}])
		picks.append(cid)
	queue.append(["gen_sheet", id, {}])
	print("WORLD FORGE gen %s: %d candidates scored in %.1f s (grid pre-filter); best %s -> forge map + Map Lab + fix: %s" % [id, count, sweep_s,
		"%.2f" % float(cands[0]["score"]) if not cands.is_empty() else "-", ", ".join(picks)])
	_finish(0, "WORLD FORGE gen %s: %d candidates, %d to the Map Lab" % [id, count, picks.size()])


func _gen_sheet() -> void:
	var od := "%s/gen_%s" % [FMap.OUT_DIR, id]
	var finals: Array = []
	for c: Dictionary in gen_info.get("cands", []):
		var cid := "%s_s%d" % [id, c["seed"]]
		var run: Dictionary = gen_runs.get(cid, {})
		finals.append({"cid": cid, "seed": c["seed"], "grid": float(c["score"]), "m": c.get("measures", {}),
			"lab_score": float(run.get("lab_score", -1.0)), "lab_result": String(run.get("lab_result", "-")),
			# a World Forge FAIL (L1 / L2...) counts as a FAIL check too
			"fails": int(run.get("lab_fails", 99)) + (0 if int(run.get("code", 1)) == 0 else 1),
			"rounds": int(run.get("rounds", 0)), "log": run.get("log", [])})
	finals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var oa: bool = int(a["fails"]) == 0 and float(a["lab_score"]) >= FMap.LAB_MIN
		var ob: bool = int(b["fails"]) == 0 and float(b["lab_score"]) >= FMap.LAB_MIN
		if oa != ob:
			return oa
		return float(a["lab_score"]) > float(b["lab_score"]))
	var entries: Array = []
	for f: Dictionary in finals.slice(0, 3):
		var m: Dictionary = f["m"]
		var lines: Array[String] = ["GRID %.2f  FIX ROUNDS %d" % [f["grid"], f["rounds"]]]
		for key: String in ["keep_enemy", "ally", "natural", "rich", "crown"]:
			if m.has(key):
				lines.append("%s %.0f M" % [key.replace("_", " "), float(m[key])])
		if m.has("enemy_ally"):
			lines.append("ENEMY/ALLY %.2f" % float(m["enemy_ally"]))
		entries.append({"title": f["cid"], "plan": "%s/%s/layout.png" % [FMap.OUT_DIR, f["cid"]], "heat": "%s/%s/map_lab/heatmap.png" % [FMap.OUT_DIR, f["cid"]],
			"lab_score": f["lab_score"], "lab_result": f["lab_result"], "lines": lines})
	var img := Sheet.contact_sheet(entries, "GEN %s  %s  %dP  %s  %s" % [id, gen_info.get("archetype", ""), int(gen_info.get("players", 2)),
		gen_info.get("tempo", ""), gen_info.get("biome", "")])
	img.save_png(od + "/contact_sheet.png")
	var pick: Dictionary = finals[0] if not finals.is_empty() else {}
	var ok: bool = not pick.is_empty() and pick["fails"] == 0 and pick["lab_score"] >= FMap.LAB_MIN
	var md := "# World Forge gen: %s\n\n" % id
	md += "`run_world_forge.ps1 gen %s archetype=%s players=%d tempo=%s biome=%s count=%d` (size %.0f m). Grid pre-filter %.1f s.\n\n" % [id,
		gen_info.get("archetype", ""), int(gen_info.get("players", 2)), gen_info.get("tempo", ""), gen_info.get("biome", ""), int(gen_info.get("count", 0)),
		float(gen_info.get("size", 0.0)), float(gen_info.get("sweep_s", 0.0))]
	md += "## Pick\n%s\n\n" % ("**%s**: Map Lab %s %.0f after %d fix round(s). Adopt: copy `data/maps/gen/%s.map` to `data/maps/<name>.map`, change the `map` id, run `map <name>`." % [
		pick["cid"], pick["lab_result"], pick["lab_score"], pick["rounds"], pick["cid"]] if ok else "None clears Map Lab >= 75 with 0 FAIL: run more seeds or hand-fix the best (contact sheet).")
	md += "## Map Lab finals (top %d of the sweep)\n| Candidate | Grid | Map Lab | FAIL checks | Fix rounds | Log |\n|---|---|---|---|---|---|\n" % finals.size()
	for f: Dictionary in finals:
		md += "| %s | %.2f | %s %.0f | %d | %d | %s |\n" % [f["cid"], f["grid"], f["lab_result"], f["lab_score"], f["fails"], f["rounds"], "; ".join(f["log"])]
	md += "\n## Sweep (grid pre-filter, best first; targets %s)\n%s\n![contact sheet](contact_sheet.png)\n" % [str(gen_info.get("targets", {})), gen_info.get("rows", "")]
	_write(od + "/gen.md", md)
	var line := "WORLD FORGE gen %s: pick %s, Map Lab %s %.0f -> %s/contact_sheet.png" % [id, pick.get("cid", "-"), pick.get("lab_result", "-"),
		float(pick.get("lab_score", -1.0)), od] if ok else "WORLD FORGE gen %s: no candidate clears 75 / 0 FAIL (see %s/gen.md)" % [id, od]
	print(line)
	_finish(0 if ok else 1, line)


# ---------------------------------------------------------------- mapsheet (map-production.md 2.6, MT7; windowed)

var _ms_level: Node3D
var _ms_cam: Camera3D
var _ms_layout: MapLayout
var _ms_top: Image


func _start_mapsheet() -> void:
	if DisplayServer.get_name() == "headless":
		print("WORLD FORGE mapsheet: needs a window (run without --headless; the ps1 does this)")
		_finish(2, "WORLD FORGE mapsheet %s: needs a window" % id)
		return
	var lpath := String(opts.get("layout", "%s/%s_layout.tres" % [FMap.MAPS_DIR, id]))
	if not ResourceLoader.exists(lpath):
		lpath = "%s/%s_layout.tres" % [Gen.GEN_DIR, id]
	_ms_layout = load(lpath) as MapLayout if ResourceLoader.exists(lpath) else null
	if _ms_layout == null:
		print("WORLD FORGE mapsheet: no layout %s (run `map %s` first)" % [lpath, id])
		_finish(2, "WORLD FORGE mapsheet %s: no layout" % id)
		return
	DisplayServer.window_set_size(Vector2i(1024, 1024))
	root.size = Vector2i(1024, 1024)
	holder = Node3D.new()
	holder.name = "ForgeMapSheet"
	root.add_child(holder)
	_ms_level = (load(FMap.LIVE_SCENE) as PackedScene).instantiate()
	_ms_level.set(&"layout", _ms_layout)
	MapLab_disable(_ms_level)
	holder.add_child(_ms_level)
	step = 1


static func MapLab_disable(n: Node) -> void:
	for c: Node in n.get_children():
		var s: Script = c.get_script()
		if s and s.resource_path.contains("/ai/") and &"enabled" in c:
			c.set(&"enabled", false)


func _tick_mapsheet() -> void:
	match step:
		1:
			MapLab_disable(_ms_level)
			if _ms_level.get(&"match_started") != true:
				if frame > 9000:
					_finish(1, "WORLD FORGE mapsheet %s: the level never started" % id)
				return
			step = 2
			frame = 0
		2:
			if frame < 30:
				return
			# a clean top-down view: no HUD, no fog, our orthographic camera
			for key: StringName in [&"hud"]:
				var n: Variant = _ms_level.get(key)
				if n is CanvasLayer:
					(n as CanvasLayer).visible = false
			for c: Node in _ms_level.get_children():
				if c is CanvasLayer:
					(c as CanvasLayer).visible = false
			var fog: Variant = _ms_level.get(&"fog")
			if fog is Node:
				(fog as Node).set(&"enabled", false)
			_ms_cam = Camera3D.new()
			_ms_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			_ms_cam.size = maxf(_ms_layout.size_x, _ms_layout.size_z) * 1.02
			_ms_cam.near = 1.0
			_ms_cam.far = 400.0
			holder.add_child(_ms_cam)
			_ms_cam.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 160, 0.01))
			_ms_cam.current = true
			step = 3
			frame = 0
		3:
			if frame < 20:
				return
			_ms_top = root.get_texture().get_image()
			_ms_top.convert(Image.FORMAT_RGBA8)
			step = 4
		4:
			var od := "%s/%s" % [FMap.OUT_DIR, id]
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(od))
			var sheet := Image.create(2048, 1024, false, Image.FORMAT_RGBA8)
			sheet.fill(Color(0.08, 0.09, 0.1))
			var top := _ms_top.duplicate() as Image
			top.resize(1024, 1024, Image.INTERPOLATE_BILINEAR)
			sheet.blit_rect(top, Rect2i(0, 0, 1024, 1024), Vector2i(0, 0))
			var plan := FMap.layout_image(_ms_layout)
			plan.resize(512, 512, Image.INTERPOLATE_BILINEAR)
			sheet.blit_rect(plan, Rect2i(0, 0, 512, 512), Vector2i(1024, 0))
			sheet.blit_rect(Sheet.load_fit(od + "/map_lab/heatmap.png", 512, 512), Rect2i(0, 0, 512, 512), Vector2i(1536, 0))
			_mapsheet_text(sheet, od)
			sheet.save_png(od + "/mapsheet.png")
			# lobby preview + minimap background: the top-down render, 512 x 512
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FMap.MAPS_DIR + "/previews"))
			var prev := _ms_top.duplicate() as Image
			prev.resize(512, 512, Image.INTERPOLATE_LANCZOS)
			prev.save_png("%s/previews/%s.png" % [FMap.MAPS_DIR, id])
			print("WORLD FORGE mapsheet %s: %s/mapsheet.png (2048 x 1024), data/maps/previews/%s.png (512 x 512)" % [id, od, id])
			_finish(0, "WORLD FORGE mapsheet %s: done" % id)


## The text block of the map sheet: title, size, score, travel times from the Map Lab scorecard JSON.
func _mapsheet_text(sheet: Image, od: String) -> void:
	var x := 1040
	var y := 530
	Sheet.draw_text(sheet, _ms_layout.title, Vector2i(x, y), Color(0.95, 0.9, 0.7), 3)
	y += 34
	Sheet.draw_text(sheet, "%s  %.0f X %.0f M  %s  %d SEATS  BIOME %s" % [_ms_layout.id, _ms_layout.size_x, _ms_layout.size_z,
		_ms_layout.symmetry, _ms_layout.seats.size(), _ms_layout.biome if _ms_layout.biome != "" else "GRASS"], Vector2i(x, y), Color(0.85, 0.85, 0.9), 2)
	y += 26
	var sc: Variant = JSON.parse_string(FileAccess.get_file_as_string(od + "/map_lab/scorecard.json")) if FileAccess.file_exists(od + "/map_lab/scorecard.json") else null
	if sc is Dictionary:
		var ok: bool = sc["result"] != "FAIL" and float(sc["quality"]) >= FMap.LAB_MIN
		Sheet.draw_text(sheet, "MAP LAB %s %.0f / 100" % [sc["result"], float(sc["quality"])], Vector2i(x, y), Color(0.4, 1, 0.5) if ok else Color(1, 0.45, 0.4), 3)
		y += 34
		for c: Dictionary in sc.get("checks", []):
			if String(c.get("id", "")).begins_with("R") or String(c.get("id", "")) in ["N2", "M1", "F1", "D1", "T1", "A1", "C1", "C2"]:
				if y > 1000:
					break
				Sheet.draw_text(sheet, "%s %s %s" % [c["id"], c["status"], String(c.get("value", "")).left(60)], Vector2i(x, y), Color(0.8, 0.85, 0.9), 2)
				y += 18
		for t: Dictionary in sc.get("tables", []):
			if String(t.get("title", "")).begins_with("Travel times") and y < 960:
				y += 6
				for row: String in String(t["markdown"]).split("\n").slice(2, 10):
					if y > 1000 or row.strip_edges() == "":
						break
					var cols := row.split("|")
					if cols.size() > 6:
						Sheet.draw_text(sheet, "%s %s %s M" % [cols[1].strip_edges().left(14), cols[2].strip_edges().left(26), cols[3].strip_edges()], Vector2i(x, y), Color(0.75, 0.8, 0.75), 2)
						y += 18
	else:
		Sheet.draw_text(sheet, "NO MAP LAB SCORECARD (RUN MAP %s FIRST)" % _ms_layout.id, Vector2i(x, y), Color(1, 0.6, 0.4), 2)


func _start_export() -> void:
	fmap = FMap.new()
	holder = Node3D.new()
	holder.name = "ForgeExportHolder"
	root.add_child(holder)
	var err := fmap.start_export(id, opts, holder)
	if err != "":
		print(err)
		_finish(2, "WORLD FORGE export-map %s: BAD INPUT" % id)
		return
	step = 1


func _tick_export() -> void:
	var r := fmap.tick_export(frame)
	if r.is_empty():
		return
	_finish(int(r["code"]), String(r["line"]))


# ---------------------------------------------------------------- help

static func help_text() -> String:
	return FileAccess.get_file_as_string("res://tools/world_forge/README.md") if FileAccess.file_exists("res://tools/world_forge/README.md") else "see tools/world_forge/README.md"
