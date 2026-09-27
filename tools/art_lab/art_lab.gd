extends SceneTree
## ART LAB: judges one art asset and writes a scorecard (docs/plan/art-lab.md is the manual).
## Windowed (renders 1600 x 900 shots; headless only runs budgets / health / hooks and SKIPs the render checks):
##   & $GODOT --path . -s res://tools/art_lab/art_lab.gd --quit-after 90000 -- scene=res://art/units/neutral/mirefang/mirefang.tscn kind=unit kingdom=neutral
## Args after `--` (key=value):
##   scene    res:// path: a model .tscn (unit, mount, titan, building, beast, critter, landmark), a biome set
##            `<id>_set.gd` (decor_set) or a VFX family script / scene with play(id, at, target) (vfx)
##   kind     unit | mount | titan | building | beast | critter | decor_set | vfx | landmark
##   kingdom  fire | shadow | ice | nature | neutral (default: guessed from the path / UnitType faction)
##   out      output folder (default docs/art/lab/<name>/): scorecard.md, scorecard.json, contact_sheet.png, shots
##   ref      comma list of reference scenes (default: auto-picked, same kind + neutral neighbours of similar size)
##   tier     budget row inside the kind (default guessed; see tools/art_lab/lab_budgets.gd)
##            (short names work: scene=sapling, ref=ember_archer,flame_guard; a missing ref is a loud WARN)
##   ground   meadow (default) | heath | old_wood | riverbank | dirt | snow | ash | sand | marsh (stand-in patches)
##   light    warm (default) | ice (default on ground=snow)
##   sweep    v3 (lab_army.gd): all | <kingdom>[,<kingdom>] (fire ice nature shadow neutral): every asset of those
##            kingdoms (units, cavalry, wizard, titan, mount, buildings) in ONE batch (quick=1; full=1 keeps refs /
##            frame cost), then one silhouette pass with the neutral neighbours + side-by-side tiles of the closest
##            pairs -> docs/art/lab/_army/army.md (ranking) and, for all, docs/art/lab/backlog.md (ranked to-do list).
##            only=a,b  buildings=0  pairs=<tiles per kingdom>  log=1. With dir=<folder>: the v2 folder sweep
##            (-> docs/art/lab/_sweep_<kingdom>/sweep.md)
##   name     asset name (default: the file name)   ids  vfx ids (default: the family's EFFECTS list)
##   n        instances for the frame-cost check    quick=1  no references / frame cost    log=0  no log row
##   batch    v3: <file or comma list> of assets run in one process (stage built once; lab_batch.gd; decor sets and
##            VFX families by short name too: batch=heath,unit_fire_gun_vfx,shade); fail_fast=1 skips
##            the render passes of an asset whose headless checks FAIL; timing=1 prints where the time goes
##   table    print the budget table as Markdown and quit
## Exit code: 0 PASS / WARN, 1 FAIL, 2 bad arguments. Last lines of the output: the result and every FAIL / WARN.

const WATCHDOG_S := 900.0


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var args := OS.get_cmdline_user_args()
	if "table" in args or "--table" in args:
		print(ArtLabBudgets.markdown_table())
		quit(0)
		return
	for a: String in args:
		if a.trim_prefix("--").begins_with("sweep="):
			var opts := _opts(args)
			if opts.has("dir"):
				await _sweep(args)   # v2 folder sweep (one folder, no neutral neighbours)
				return
			var n := ArtLabArmy.assets(ArtLabArmy.parse_groups(String(opts["sweep"])), String(opts.get("buildings", "1")) != "0").size()
			create_timer(WATCHDOG_S + 150.0 * float(maxi(n, 1)) * (2.0 if opts.get("full", "0") == "1" else 1.0)).timeout.connect(func() -> void:
				print("ART LAB ERROR: sweep watchdog")
				quit(3))
			quit(await ArtLabArmy.sweep(self, opts))
			return
		if a.trim_prefix("--").begins_with("batch="):
			await _batch(args)
			return
	create_timer(WATCHDOG_S).timeout.connect(func() -> void:
		print("ART LAB ERROR: watchdog (%d s)" % int(WATCHDOG_S))
		quit(3))
	var runner := ArtLabRunner.new()
	runner.name = "ArtLab"
	root.add_child(runner)
	var code: int = await runner.run(args)
	quit(code)


## key=value args (keys lower case; a bare key = "1").
func _opts(args: PackedStringArray) -> Dictionary:
	var opts := {}
	for a: String in args:
		var s := a.trim_prefix("--")
		opts[s.get_slice("=", 0).to_lower()] = s.substr(s.find("=") + 1) if "=" in s else "1"
	return opts


## v2 folder sweep (only with `dir=`; `sweep=<kingdoms>` without dir= is the v3 army sweep, lab_army.gd): runs every model in res://art/units/<kingdom>/ (or `dir=`), each with quick=1 (no
## per-asset references / frame cost; `full=1` keeps them), then renders every silhouette ONCE and compares all pairs
## (the references run once for the whole army). Other args (kind, ground, light, log) pass through.
## Writes docs/art/lab/_sweep_<kingdom>/sweep.md (+ army_silhouettes.png). Exit 1 if any asset FAILs.
func _sweep(args: PackedStringArray) -> void:
	var opts := {}
	for a: String in args:
		var s := a.trim_prefix("--")
		opts[s.get_slice("=", 0)] = s.substr(s.find("=") + 1) if "=" in s else "1"
	var k := String(opts.get("sweep", "fire")).to_lower()
	var dir := String(opts.get("dir", "res://art/units/%s/" % k))
	var out := String(opts.get("out", "res://docs/art/lab/_sweep_%s" % k)).trim_suffix("/")
	var lister := ArtLabRunner.new()
	root.add_child(lister)
	var pool := {}   # v3: one stage per light preset for the whole sweep
	var pool_parent := Node.new()
	pool_parent.name = "StagePool"
	root.add_child(pool_parent)
	lister.stage_pool = pool
	lister.stage_parent = pool_parent
	var paths: Array[String] = ArtLabScenes.list_scenes(dir, true)
	paths.sort()
	if opts.has("only"):
		var keep: Array[String] = []
		for p: String in paths:
			for w: String in String(opts["only"]).split(",", false):
				if w.strip_edges() in p.get_file():
					keep.append(p)
					break
		paths = keep
	create_timer(WATCHDOG_S * maxf(1.0, float(paths.size()) * 0.3) + 600.0).timeout.connect(func() -> void:
		print("ART LAB ERROR: sweep watchdog")
		quit(3))
	print("ART LAB SWEEP %s: %d models in %s" % [k, paths.size(), dir])
	var rows: Array[String] = []
	var any_fail := false
	for p: String in paths:
		var ra := PackedStringArray(["scene=" + p, "kind=" + String(opts.get("kind", "unit")), "kingdom=" + k])
		if opts.get("full", "0") != "1":
			ra.append("quick=1")
		if DisplayServer.get_name() == "headless" or opts.get("keep_out", "0") == "1":
			# a headless sweep (budgets only) must not overwrite the windowed scorecards in docs/art/lab/<name>/
			ra.append("out=%s/%s" % [out, p.get_file().get_basename()])
		for pass_k: String in ["ground", "light", "log", "tier"]:
			if opts.has(pass_k):
				ra.append("%s=%s" % [pass_k, opts[pass_k]])
		var r := ArtLabRunner.new()
		r.stage_parent = pool_parent
		r.stage_pool = pool
		root.add_child(r)
		var code: int = await r.run(ra)
		if r.rep != null:
			var bad: Array[String] = []
			for c: Dictionary in r.rep.checks:
				if c["status"] == "FAIL" or c["status"] == "WARN":
					bad.append("%s %s" % [c["status"], c["id"]])
			rows.append("| %s | %s | %.0f | %s | %s |" % [p.get_file().get_basename(), r.rep.result(), r.rep.quality(),
				", ".join(bad), r.out_dir.path_join("scorecard.md")])
		else:
			rows.append("| %s | ERROR (exit %d) | | | |" % [p.get_file().get_basename(), code])
		any_fail = any_fail or code != 0
		r.queue_free()
		await process_frame
	var army: Dictionary = await ArtLabShots.army_pass(lister, paths, out)
	var md := "# Art Lab army sweep: %s\n\n%s, %d models, lab v%s. Per-asset runs use quick=1 (no references / frame cost);\n" % [
		k, Time.get_datetime_string_from_system(false, true), paths.size(), ArtLabReport.VERSION]
	md += "the army silhouettes are rendered once and compared pairwise below.\n\n| asset | result | quality | FAIL / WARN | scorecard |\n|---|---|---|---|---|\n"
	md += "\n".join(rows) + "\n\n## Army silhouettes (40 m, 4 turns, mean IoU; reads alike = IoU > 0.8 and colour dE < 15)\n\n"
	if bool(army.get("skipped", false)):
		md += "Skipped (headless or < 2 models).\n"
	else:
		md += "![army](army_silhouettes.png)\n\n| pair | IoU | colour dE | verdict |\n|---|---|---|---|\n"
		for pr: Dictionary in (army["pairs"] as Array).slice(0, 12):
			var alike := float(pr["iou"]) > 0.8 and float(pr["de"]) < 15.0
			md += "| %s / %s | %.2f | %.1f | %s |\n" % [pr["a"], pr["b"], float(pr["iou"]), float(pr["de"]),
				"READS ALIKE" if alike else ("same shape family, colour differs" if float(pr["iou"]) > 0.8 else "distinct")]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var f := FileAccess.open(out.path_join("sweep.md"), FileAccess.WRITE)
	if f:
		f.store_string(md)
		f.close()
	print("ART LAB SWEEP %s done: %d models, %d read alike -> %s" % [k, paths.size(), (army.get("alike", []) as Array).size(), out.path_join("sweep.md")])
	for row: String in rows:
		print("  " + row)
	quit(1 if any_fail else 0)


## v3 batch: `batch=<file or comma list>` (tools/art_lab/lab_batch.gd): the assets run in this one process, the stage
## is built once. Prints one line per asset and the s / asset. Exit 1 if any asset FAILs, 2 on bad arguments.
func _batch(args: PackedStringArray) -> void:
	var t0 := Time.get_ticks_msec()
	var shared := {}
	for a: String in args:
		var s := a.trim_prefix("--")
		shared[s.get_slice("=", 0).to_lower()] = s.substr(s.find("=") + 1) if "=" in s else "1"
	var list := ArtLabBatch.entries(String(shared.get("batch", "")))
	if list.is_empty():
		print("ART LAB ERROR: batch=%s lists no asset" % shared.get("batch", ""))
		quit(2)
		return
	create_timer(WATCHDOG_S + 120.0 * float(list.size())).timeout.connect(func() -> void:
		print("ART LAB ERROR: batch watchdog")
		quit(3))
	print("ART LAB BATCH: %d assets" % list.size())
	var res: Dictionary = await ArtLabBatch.run_all(root, list, shared)
	print(ArtLabBatch.summary(res, float(Time.get_ticks_msec() - t0) / 1000.0))
	for row: Dictionary in res["rows"]:
		print("  | %s %s %d (%.1f s)" % [row["asset"], row["result"], ArtLabScore.shown(float(row["quality"])), float(row["seconds"])])
	quit(int(res["code"]))
