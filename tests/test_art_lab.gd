extends SceneTree
## Art Lab tool test (docs/plan/art-lab.md). Headless: the pixel analysis on synthetic images, the budget table, the
## scorecard (score, "Improve next", writers, log) and a headless lab run on a finished model (budgets / health / hooks;
## the render checks come out SKIP).
## Run:  godot --headless --path . -s tests/test_art_lab.gd --fixed-fps 60 --quit-after 6000
## Prints "PASS art_lab" or "FAIL art_lab: <reason>".

const TASK_ID := "art_lab"
const MODEL := "res://art/units/neutral/mirefang/mirefang.tscn"
const OUT := "user://art_lab_test"

var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  x " + what)


func _run() -> void:
	_test_image()
	_test_budgets()
	_test_report()
	await _test_census()
	await _test_runner()
	await _test_batch()
	await _test_diff()
	await _test_fixes()   # v3 1.A fix recipes (lab_fixes.gd): its own function, kept apart from the other tasks' cases
	await _test_army()    # v3 1.E army sweep + backlog (lab_army.gd): its own function
	_test_read_v3()       # v3 1.D new quality checks (checks/read_v3.gd + lab_image / lab_stage helpers): its own function
	await _test_v31()     # v3.1 fix round: craft (C1 / C2), A3r reach, recipes (team colour, B5, B8), shown quality, focus links
	await _test_u1()      # tools upgrade U1: log=<file>, craft per kind, palette snap, settle_all, cast pose constants
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _img(w: int, h: int, bg: Color) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	return img


func _test_image() -> void:
	var roi := Rect2i(0, 0, 40, 30)
	var a := _img(40, 30, Color.WHITE)
	a.fill_rect(Rect2i(5, 5, 10, 10), Color.BLACK)
	var b := _img(40, 30, Color.WHITE)
	b.fill_rect(Rect2i(10, 5, 10, 10), Color.BLACK)
	var ma := ArtLabImage.sil_mask(a, roi)
	var mb := ArtLabImage.sil_mask(b, roi)
	_check(ma.count == 100, "mask count 100 (got %d)" % ma.count)
	_check(ma.bbox == Rect2i(5, 5, 10, 10), "mask bbox")
	_check(is_equal_approx(ArtLabImage.iou(ma, ma), 1.0), "IoU identical = 1")
	_check(absf(ArtLabImage.iou(ma, mb) - 50.0 / 150.0) < 0.001, "IoU half overlap = 1/3")
	# glow clusters: three bright dots on black, two of them 2 px apart (merge into one point)
	var d := _img(60, 30, Color.BLACK)
	d.fill_rect(Rect2i(5, 5, 3, 3), Color.WHITE)
	d.fill_rect(Rect2i(10, 5, 3, 3), Color.WHITE)
	d.fill_rect(Rect2i(40, 20, 4, 4), Color(1.0, 0.6, 0.2))
	d.set_pixel(30, 2, Color.WHITE)   # a single hot pixel: below min_px
	var cl := ArtLabImage.glow_clusters(d, Rect2i(0, 0, 60, 30), 0.3, 3, 2)
	_check(cl.size() == 2, "glow clusters = 2 (got %d)" % cl.size())
	# contrast: a grey body on green vs the green ground behind it
	var ground := _img(40, 30, Color(0.32, 0.43, 0.2))
	var lit := ground.duplicate() as Image
	lit.fill_rect(Rect2i(5, 5, 10, 10), Color(0.35, 0.36, 0.16))
	var c := ArtLabImage.contrast(lit, ground, roi, ma)
	_check(int(c["n"]) == 100, "contrast pixel count")
	_check(float(c["de_mean"]) > 3.0 and float(c["de_mean"]) < 20.0, "olive on grass is a low dE (got %.1f)" % float(c["de_mean"]))
	# the Mirefang scale colour flat on the grass colour: R3 must FAIL it (mean-colour dE < 10 or > 60 % melting)
	_check(float(c["de_means"]) < 10.0 or float(c["melt_frac"]) > 0.6, "green-on-grass case fails R3 (dE %.1f, melt %.2f)" % [float(c["de_means"]), float(c["melt_frac"])])
	var lit2 := ground.duplicate() as Image
	lit2.fill_rect(Rect2i(5, 5, 10, 10), Color(0.85, 0.3, 0.12))
	_check(float(ArtLabImage.contrast(lit2, ground, roi, ma)["de_mean"]) > 40.0, "orange on grass is a high dE")
	_check(is_equal_approx(ArtLabImage.changed_fraction(lit, lit2, roi, ma, 8.0), 1.0), "changed fraction 1")
	_check(ArtLabImage.changed_fraction(lit, lit, roi, ma, 8.0) == 0.0, "changed fraction 0")
	# outline complexity: a filled disc is ~1, a thin cross much more
	var disc := _img(60, 60, Color.WHITE)
	for y: int in 60:
		for x: int in 60:
			if Vector2(x - 30, y - 30).length() < 20.0:
				disc.set_pixel(x, y, Color.BLACK)
	var cx := ArtLabImage.complexity(ArtLabImage.sil_mask(disc, Rect2i(0, 0, 60, 60)))
	_check(cx > 0.6 and cx < 1.6, "disc complexity ~1 (got %.2f)" % cx)
	var cross := _img(60, 60, Color.WHITE)
	cross.fill_rect(Rect2i(28, 2, 3, 56), Color.BLACK)
	cross.fill_rect(Rect2i(2, 28, 56, 3), Color.BLACK)
	_check(ArtLabImage.complexity(ArtLabImage.sil_mask(cross, Rect2i(0, 0, 60, 60))) > 3.0, "cross complexity > 3")
	_check(ArtLabImage.asymmetry(ArtLabImage.sil_mask(disc, Rect2i(0, 0, 60, 60)), 29.5) < 0.1, "disc symmetric")
	_check(ArtLabImage.asymmetry(ma, 20.0) > 0.9, "off-axis square asymmetric")
	# v2: "hot" clusters by the brightest channel (a saturated red at the bloom level has a low luma)
	var hot := _img(40, 20, Color.BLACK)
	hot.fill_rect(Rect2i(5, 5, 3, 3), Color(1.0, 0.1, 0.0))
	hot.fill_rect(Rect2i(25, 5, 3, 3), Color(0.5, 0.5, 0.5))   # below the bloom level
	_check(ArtLabImage.glow_clusters(hot, Rect2i(0, 0, 40, 20), 0.97, 3, 2, true).size() == 1, "hot pass: 1 cluster (red counts, grey not)")
	_check(ArtLabImage.glow_clusters(hot, Rect2i(0, 0, 40, 20), 0.4, 3, 2).size() == 1, "luma pass: grey only")
	# v2: rim specks sit on the outline
	_check(ArtLabImage.near_edge(ma, 5, 5, 2) and not ArtLabImage.near_edge(ma, 9, 9, 2), "near_edge: corner yes, centre no")
	# v2: world-height masks (the height pass writes linear grey, the frame is sRGB)
	var hgt := _img(40, 30, Color.BLACK)
	hgt.fill_rect(Rect2i(5, 5, 10, 3), Color(1.0, 1.0, 1.0))
	hgt.fill_rect(Rect2i(5, 12, 10, 3), Color(0.2, 0.2, 0.2))
	_check(ArtLabImage.height_mask(ma, hgt, roi, 0.667, 1.0).count == 30, "height mask top = 30 px")
	_check(absf(ArtLabImage.height_at(hgt, roi, 6, 6) - 1.0) < 0.01, "height_at top = 1")
	_check(ArtLabImage.top_rows(ma, 0.34).count == 40, "top rows 34 % = 4 rows x 10")
	# v2 census helpers
	_check(ArtLabCensus.is_line_part(Vector3(0.04, 1.6, 0.05)) and not ArtLabCensus.is_line_part(Vector3(0.3, 1.0, 0.05)), "line parts")
	var bm := BoxMesh.new()
	_check(ArtLabCensus.down_tris(bm, Basis.IDENTITY) == 2, "a box has 2 downward triangles (got %d)" % ArtLabCensus.down_tris(bm, Basis.IDENTITY))


func _test_budgets() -> void:
	for k: StringName in ArtLabBudgets.KINDS:
		var t: StringName = ArtLabBudgets.DEFAULT_TIER.get(k, &"")
		_check(ArtLabBudgets.has_tier(k, t), "default tier of %s exists" % k)
		_check(ArtLabBudgets.READ.has(k), "read rules for %s" % k)
	_check(ArtLabBudgets.guess_tier(&"unit", "res://art/units/neutral/mirefang/mirefang.tscn", {}) == &"creature", "mirefang = creature")
	_check(ArtLabBudgets.guess_tier(&"unit", "res://art/units/wizards/vessa.tscn", {}) == &"wizard", "vessa = wizard")
	_check(ArtLabBudgets.guess_tier(&"beast", "res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn", {}) == &"titan", "wyrm = titan budget")
	var r := ArtLabBudgets.row(&"unit", &"soldier")
	_check(bool(ArtLabBudgets.limit(r, "meshes")["hard"]), "soldier meshes hard")
	_check(not bool(ArtLabBudgets.limit(r, "casters")["hard"]), "soldier casters soft")
	_check(ArtLabBudgets.markdown_table().count("\n") > ArtLabBudgets.BUDGETS.size(), "budget table")
	# v2 tier rules
	_check(ArtLabBudgets.read_rules(&"building", &"keep")["glow"] == Vector2i(4, 12), "keep glow 4-12")
	_check(ArtLabBudgets.read_rules(&"unit", &"soldier")["glow"] == Vector2i(1, 3), "soldier glow 1-3")
	_check(float(ArtLabBudgets.read_rules(&"unit", &"wizard").get("top_width", 0.0)) > 0.35, "wizard crest tolerance")
	_check(ArtLabBudgets.guess_tier(&"landmark", "res://art/environment/crown/crown_altar.tscn", {}) == &"objective", "crown = objective landmark")
	_check(ArtLabRunner.resolve_scene("mirefang") == MODEL, "short ref name resolves (got %s)" % ArtLabRunner.resolve_scene("mirefang"))
	_check(ArtLabRunner.resolve_scene("no_such_asset_xyz") == "", "missing ref -> empty")
	for gid: StringName in [&"snow", &"ash", &"sand", &"marsh"]:
		_check(ArtLabStage.GROUND_POINTS.has(gid), "ground %s" % gid)


func _test_report() -> void:
	var rep := ArtLabReport.new()
	rep.asset = "test"
	rep.kind = "unit"
	rep.add("B1", "budget", "Meshes", "PASS", "10", "<= 26")
	rep.add("R3", "read", "Contrast", "WARN", "dE 15", ">= 18", "hint", 0.5, "raise contrast", "z40")
	_check(rep.result() == "WARN" and rep.exit_code() == 0, "WARN result, exit 0")
	rep.extras.append({"title": "a", "text": "a", "source": "x"})
	rep.extras.append({"title": "b", "text": "b", "source": "x"})
	rep.extras.append({"title": "c", "text": "c", "source": "x"})
	var imp := rep.improve_next()
	_check(imp.size() >= 3, "improve next >= 3 items (got %d)" % imp.size())
	_check(String(imp[0]["title"]) == "Contrast", "the WARN with a suggestion comes first")
	var q1 := rep.quality()
	rep.add("R1", "read", "Area", "FAIL", "30 px", ">= 45")
	_check(rep.quality() < q1 and rep.exit_code() == 1, "a FAIL lowers the score and exits 1")
	_check(ArtLabScore.grade(5.0, 0.0, 10.0) == 0.5 and ArtLabScore.grade(20.0, 10.0, 0.0) == 0.0, "grade")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	rep.write(OUT)
	_check(FileAccess.file_exists(OUT + "/scorecard.md") and FileAccess.file_exists(OUT + "/scorecard.json"), "scorecard written")
	_check(ArtLabReport.read_previous(OUT) >= 0.0, "previous score readable")
	var log_path := OUT + "/log.md"
	if FileAccess.file_exists(log_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(log_path))
	rep.append_log(log_path, OUT)
	rep.append_log(log_path, OUT)
	var text := FileAccess.get_file_as_string(log_path)
	_check(text.count("| test |") == 2 and text.begins_with("# Art Lab improvement log"), "improvement log appended")


func _test_census() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var inst := (load(MODEL) as PackedScene).instantiate() as Node3D
	holder.add_child(inst)
	for i: int in 3:
		await process_frame
	var c := ArtLabCensus.census(inst, 0.0)
	_check(int(c["draw"]) > 0 and int(c["draw"]) <= 10, "mirefang draw instances 1-10 (got %d)" % int(c["draw"]))
	_check(int(c["lights"]) == 0, "mirefang has no lights")
	_check(int(c["verts"]) > 100, "vertices counted")
	var vb := ArtLabCensus.vertex_bounds(inst, holder.global_transform, 0.0)
	_check(absf((vb["min"] as Vector3).y) < 0.1, "feet near y 0")
	_check(ArtLabCensus.has_hook(inst, "play_death") and ArtLabCensus.has_hook(inst, "signal:death_finished"), "hooks found")
	holder.queue_free()
	await process_frame


func _test_runner() -> void:
	var runner := ArtLabRunner.new()
	root.add_child(runner)
	var code: int = await runner.run(PackedStringArray(["scene=" + MODEL, "kind=unit", "kingdom=neutral", "out=" + OUT + "/run", "log=0"]))
	_check(code == 0 or code == 1, "runner exit code 0 / 1 (got %d)" % code)
	var p := OUT + "/run/scorecard.json"
	_check(FileAccess.file_exists(p), "runner wrote scorecard.json")
	if FileAccess.file_exists(p):
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(p))
		_check((d["checks"] as Array).size() >= 10, "scorecard has checks")
		_check(bool(d["headless"]), "headless flagged")
		_check((d["improve_next"] as Array).size() >= 3, "scorecard improve_next >= 3")
		var ids := {}
		for ch: Dictionary in d["checks"]:
			ids[ch["id"]] = ch["status"]
		_check(ids.get("B1", "") == "PASS" and ids.get("B5", "") == "PASS", "mirefang budgets pass (B1 %s, B5 %s)" % [ids.get("B1", "?"), ids.get("B5", "?")])
		_check(ids.get("B1a", "") == "INFO", "authored parts reported as INFO (B1a)")
		_check(ids.has("B11") and ids.has("B12"), "surfaces / downward-face checks present")
		_check(ids.get("B10", "") == "PASS", "mirefang allocations pass (B10 %s)" % ids.get("B10", "?"))
		_check(ids.get("R3", "") == "SKIP", "render checks skipped headless")
		_check(ids.get("H1", "") == "PASS", "no asset errors")
	var bad := ArtLabRunner.new()
	root.add_child(bad)
	_check(await bad.run(PackedStringArray(["scene=res://nope.tscn", "kind=unit"])) == 2, "bad scene -> exit 2")
	runner.queue_free()
	bad.queue_free()


## v3 batch mode (lab_batch.gd): entry parsing, kind guess, per-entry args, one stage for the whole batch, fail_fast.
func _test_batch() -> void:
	var e := ArtLabBatch.entries("mirefang, dusk_steed")
	_check(e.size() == 2 and e[0][0] == "scene=mirefang" and e[1][0] == "scene=dusk_steed", "batch comma list")
	var lf := OUT + "/batch.txt"
	var f := FileAccess.open(lf, FileAccess.WRITE)
	f.store_string("# comment\nmirefang kind=unit\n\nres://art/vfx/unit_fire_gun_vfx.gd ids=a\n")
	f.close()
	var ef := ArtLabBatch.entries(lf)
	_check(ef.size() == 2 and "kind=unit" in ef[0] and "ids=a" in ef[1], "batch list file (%d entries)" % ef.size())
	_check(ArtLabBatch.guess_kind("res://art/vfx/unit_fire_gun_vfx.gd") == "vfx", "guess kind vfx")
	_check(ArtLabBatch.guess_kind("dusk_steed") == "mount", "guess kind mount (short name)")
	_check(ArtLabBatch.guess_kind("res://art/environment/landmarks/aqueduct.tscn") == "landmark", "guess kind landmark")
	_check(ArtLabBatch.guess_kind("mirefang") == "unit", "guess kind unit")
	var ra := ArtLabBatch.entry_args(PackedStringArray(["scene=mirefang", "ground=heath"]),
		{"batch": "x", "ground": "meadow", "log": "0", "out_root": "user://b"})
	_check("ground=heath" in ra and not "ground=meadow" in ra and "log=0" in ra and "kind=unit" in ra
		and "out=user://b/mirefang" in ra and not "batch=x" in ra, "batch entry args (%s)" % ", ".join(ra))
	# two assets in one process: the second is a planted FAIL (critter rabbit budget: 300 triangles) with fail_fast
	var list: Array[PackedStringArray] = [PackedStringArray(["scene=" + MODEL]),
		PackedStringArray(["scene=" + MODEL, "kind=critter", "tier=rabbit", "name=mirefang_ff"])]
	var holder := Node.new()
	root.add_child(holder)
	var res: Dictionary = await ArtLabBatch.run_all(holder, list,
		{"kingdom": "neutral", "log": "0", "fail_fast": "1", "out_root": OUT + "/batch"})
	var rows: Array = res["rows"]
	_check(rows.size() == 2, "batch ran 2 assets")
	_check(int(res["stages"]) == 1, "batch built the stage once (got %d)" % int(res["stages"]))
	if rows.size() == 2:
		_check(int(rows[0]["code"]) == 0 and int(rows[1]["code"]) == 1, "batch codes 0 / 1 (got %d / %d)" % [int(rows[0]["code"]), int(rows[1]["code"])])
	var p := OUT + "/batch/mirefang_ff/scorecard.json"
	_check(FileAccess.file_exists(p) and FileAccess.file_exists(OUT + "/batch/mirefang/scorecard.json"), "batch scorecards per asset")
	if FileAccess.file_exists(p):
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(p))
		_check(String(d["result"]) == "FAIL" and "fail_fast" in " ".join(PackedStringArray(d["notes"])), "fail_fast stopped the planted FAIL")
	_check(ArtLabBatch.summary(res, 2.0).begins_with("ART LAB BATCH done: 2 assets"), "batch summary line")
	holder.queue_free()
	await process_frame


## v3 1.B before / after + focus (tools/art_lab/lab_diff.gd): focus sets, per-check deltas, the focus merge, the pixel
## diff, the scorecard's "What got worse" section, and a headless `focus=B4` run merged into a full run's scorecard.
func _test_diff() -> void:
	var fs := ArtLabDiff.focus_set("contrast, r5 ,b4T")
	_check(fs.has("R3") and fs.has("R4k") and fs.has("R3t") and fs.has("R5") and fs.has("B4t") and not fs.has("R6"),
		"diff: focus set (%s)" % ", ".join(PackedStringArray(fs.keys())))
	_check(ArtLabDiff.needs(fs, "read40") and ArtLabDiff.needs(fs, "shots") and ArtLabDiff.needs(fs, "budgets"),
		"diff: focus needs read40 / shots / budgets")
	_check(not ArtLabDiff.needs(fs, "actions") and not ArtLabDiff.needs(fs, "refs") and not ArtLabDiff.needs(fs, "turns"),
		"diff: focus skips actions / refs / turns")
	_check(not ArtLabDiff.needs(ArtLabDiff.focus_set("B4"), "shots"), "diff: a budget-only focus takes no shots")
	_check(ArtLabDiff.needs(ArtLabDiff.focus_set("Z9"), "refs"), "diff: an unknown id runs every pass")
	_check(ArtLabDiff.needs({}, "turns"), "diff: no focus = full run")
	# per-check deltas: R5 drops a status, P1 loses 10 points, R3 rises, R6 is new, B13 is gone, B1 unchanged
	var old: Array = [_dchk("R3", "WARN", 0.5), _dchk("B1", "PASS", 1.0), _dchk("P1", "INFO", 0.4), _dchk("R5", "PASS", 0.9),
		_dchk("B13", "PASS", 0.8)]
	var new: Array = [_dchk("R3", "PASS", 0.8), _dchk("B1", "PASS", 1.0), _dchk("P1", "INFO", 0.3), _dchk("R5", "WARN", 0.6),
		_dchk("R6", "PASS", 1.0)]
	var cmp := ArtLabDiff.compare_checks(old, new)
	var worse: Array = cmp["worse"]
	_check(worse.size() == 2 and worse[0]["id"] == "R5" and worse[1]["id"] == "P1", "diff: worse = R5 (status) then P1 (score)")
	_check((cmp["better"] as Array).size() == 1 and cmp["better"][0]["id"] == "R3", "diff: better = R3")
	_check((cmp["new"] as Array).size() == 1 and (cmp["gone"] as Array).size() == 1 and int(cmp["unchanged"]) == 1,
		"diff: new R6 / gone B13 / 1 unchanged")
	_check(ArtLabDiff.row_text(worse[0]).begins_with("R5 check R5: PASS 97 -> WARN"), "diff: row text (%s)" % ArtLabDiff.row_text(worse[0]))
	# the scorecard shows "What got worse" above "Improve next"; ToolReport's JSON is unchanged
	var rep := ArtLabReport.new()
	rep.asset = "diff"
	for c: Dictionary in new:
		rep.checks.append(c)
	cmp["prev_quality"] = 80.0
	rep.compare = cmp
	var md := rep.to_markdown()
	var iw := md.find("### What got worse (2)")
	_check(iw > 0 and iw < md.find("## Improve next") and md.find("R5 check R5") > iw, "diff: 'What got worse' at the top of scorecard.md")
	_check(rep.to_dict().has("compare") and not ToolReport.new().to_dict().has("compare"), "diff: compare in the JSON (not in ToolReport's)")
	# focus merge: R3 re-measured, the rest kept; H1 taken only when worse
	var prev: Array = [_dchk("H0", "PASS", -1.0), _dchk("B4", "PASS", 1.0), _dchk("R3", "WARN", 0.5), _dchk("R5", "PASS", 0.9),
		_dchk("H1", "PASS", -1.0)]
	var run: Array[Dictionary] = [_dchk("H0", "PASS", -1.0), _dchk("B4", "FAIL", 0.1), _dchk("B1", "PASS", 1.0),
		_dchk("R3", "PASS", 0.9), _dchk("H1", "PASS", -1.0)]
	var mg := ArtLabDiff.merge_focus(prev, run, ArtLabDiff.focus_set("R3"))
	var ids: Array[String] = []
	for c2: Dictionary in mg:
		ids.append("%s%s" % [c2["id"], "*" if bool(c2.get("kept", false)) else ""])
	_check(", ".join(ids) == "H0, B4*, R3, R5*, H1*" and mg[1]["status"] == "PASS" and mg[2]["status"] == "PASS",
		"diff: focus merge (%s)" % ", ".join(ids))
	run[4] = _dchk("H1", "FAIL", -1.0)
	_check(ArtLabDiff.merge_focus(prev, run, ArtLabDiff.focus_set("R3"))[4]["status"] == "FAIL", "diff: a new error (H1) is never hidden")
	# pixel diff: a 10 x 10 block changes, JPEG-size noise does not, a size change is resized
	var a := _img(40, 30, Color(0.2, 0.5, 0.2))
	var b := a.duplicate() as Image
	b.fill_rect(Rect2i(0, 0, 10, 10), Color.RED)
	b.set_pixel(30, 20, Color(0.22, 0.51, 0.21))
	var pd := ArtLabDiff.pixel_diff(a, b)
	_check(int(pd["changed"]) == 100 and absf(float(pd["frac"]) - 100.0 / 1200.0) < 0.001, "diff: 100 changed pixels (got %d)" % int(pd["changed"]))
	_check((pd["mask"] as Image).get_size() == Vector2i(40, 30) and (pd["mask"] as Image).get_pixel(2, 2).b > 0.5, "diff: mask marks the change")
	_check(bool(ArtLabDiff.pixel_diff(_img(20, 15, Color.BLACK), b)["resized"]), "diff: sizes differ -> resized")
	_check(ArtLabDiff.prepare(_img(1600, 900, Color.GRAY), "z40").get_size() == Vector2i(256, 144) and ArtLabDiff.prepare(_img(1600, 1200, Color.GRAY), "turns").get_size() == Vector2i(300, 225), "diff: z40 cropped, others fitted")
	# end to end (headless): a focus=B4 run on a copy of the full run's scorecard (B4 planted as a FAIL)
	var src := OUT + "/run/scorecard.json"
	if not FileAccess.file_exists(src):
		_check(false, "diff: no full-run scorecard to merge into")
		return
	var full: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(src))
	for c3: Dictionary in full["checks"]:
		if c3["id"] == "B4":
			c3["status"] = "FAIL"
			c3["score"] = 0.0
	var dir := OUT + "/diff"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(dir + "/scorecard.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(full))
	f.close()
	var runner := ArtLabRunner.new()
	root.add_child(runner)
	var t0 := Time.get_ticks_msec()
	var code: int = await runner.run(PackedStringArray(["scene=" + MODEL, "kind=unit", "kingdom=neutral", "out=" + dir, "log=0", "focus=B4"]))
	var focus_s := float(Time.get_ticks_msec() - t0) / 1000.0
	_check(code == 0 or code == 1, "diff: focus run exit code (got %d)" % code)
	var d: Dictionary = ArtLabDiff.read_json(dir + "/scorecard.json")
	if d.is_empty():
		_check(false, "diff: focus run wrote no scorecard")
	else:
		var st := {}
		var kept := {}
		for c4: Dictionary in d["checks"]:
			st[c4["id"]] = c4["status"]
			kept[c4["id"]] = bool(c4.get("kept", false))
		_check((d["checks"] as Array).size() == (full["checks"] as Array).size(), "diff: merged scorecard keeps every check (%d / %d)" % [
			(d["checks"] as Array).size(), (full["checks"] as Array).size()])
		_check(st.get("B4", "") == "PASS" and not kept.get("B4", true) and kept.get("B10", false), "diff: B4 re-measured, B10 kept")
		var better_ids: Array[String] = []
		for r: Dictionary in (d.get("compare", {}) as Dictionary).get("better", []):
			better_ids.append(String(r["id"]))
		_check("B4" in better_ids, "diff: compare=prev lists B4 as better (%s)" % ", ".join(better_ids))
		var mdf := FileAccess.get_file_as_string(dir + "/scorecard.md")
		_check("**Focus run**" in mdf and "### What got worse" in mdf and "_kept_" in mdf, "diff: focus / before-after in scorecard.md")
		print("  diff: headless focus=B4 %.1f s vs full %.1f s" % [focus_s, float(full.get("seconds", 0.0))])
	runner.queue_free()
	await process_frame


func _dchk(id: String, status: String, g: float) -> Dictionary:
	var r := ArtLabReport.new()
	var grp := "read" if id.begins_with("R") else ("polish" if id.begins_with("P") else ("health" if id.begins_with("H") else "budget"))
	return r.add(id, grp, "check " + id, status, "value " + id, "rule", "", g)


## v3 task 1.E (lab_army.gd, lab_scenes.gd): decor / VFX short names in batch=, cavalry in the sweep list, kingdoms,
## the backlog ranking (FAIL first, then gain per minute), offset IoU, fixes.json reader, and a headless mini sweep.
func _test_army() -> void:
	var heath := ArtLabScenes.resolve_scene("heath")
	_check(heath.ends_with("/heath_set.gd"), "army: decor short name heath -> heath_set.gd (got %s)" % heath)
	_check(ArtLabScenes.resolve_scene("heath_set") == heath and ArtLabScenes.resolve_scene("heath_set.gd") == heath, "army: heath_set / heath_set.gd resolve")
	_check(ArtLabScenes.resolve_scene("unit_fire_gun_vfx").ends_with("/unit_fire_gun_vfx.gd"), "army: vfx short name resolves")
	_check(ArtLabScenes.resolve_scene("mirefang") == MODEL, "army: a .tscn short name still wins")
	_check(ArtLabBatch.guess_kind("heath") == "decor_set", "army: guess kind decor_set (short name)")
	var ra := ArtLabBatch.entry_args(PackedStringArray(["scene=heath"]), {"out_root": "user://b"})
	_check("kind=decor_set" in ra and "out=user://b/heath" in ra, "army: decor batch entry (%s)" % ", ".join(ra))
	var fire_cav := ArtLabScenes.list_scenes("res://art/units/fire/", true, true)
	var fire_old := ArtLabScenes.list_scenes("res://art/units/fire/", true)
	_check(fire_cav.has("res://art/units/fire/blaze_rider.tscn"), "army: cavalry kept with cavalry=true")
	_check(not "blaze_rider_rider.tscn" in " ".join(fire_cav), "army: rider sub-scene dropped")
	_check(not fire_old.has("res://art/units/fire/blaze_rider.tscn"), "army: default list unchanged (auto references)")
	for kc: Array in [["res://art/units/wizards/vessa.tscn", "fire"], ["res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn", "neutral"],
			["res://art/buildings/dusk_keep.tscn", "shadow"], ["res://art/units/titans/war_mammoth/war_mammoth.tscn", "ice"],
			["res://art/units/mounts/roan_courser/roan_courser.tscn", "neutral"], ["res://art/buildings/lair/fire/dragon_roost.tscn", "fire"],
			["res://art/units/champions/oathwall/oathwall.tscn", "neutral"], ["res://art/buildings/ice_wall.tscn", "ice"]]:
		_check(ArtLabArmy.kingdom_of(kc[0]) == kc[1], "army: kingdom of %s = %s (got %s)" % [String(kc[0]).get_file(), kc[1], ArtLabArmy.kingdom_of(kc[0])])
	_check(ArtLabArmy.parse_groups("all").size() == 5 and ArtLabArmy.parse_groups("fire,ice").size() == 2
		and ArtLabArmy.parse_groups("fire,bogus").is_empty(), "army: parse sweep groups")
	var all := ArtLabArmy.assets(ArtLabArmy.parse_groups("all"))
	var per := {}
	var kinds := {}
	for a: Dictionary in all:
		per[a["group"]] = int(per.get(a["group"], 0)) + 1
		kinds[a["kind"]] = true
	for g: String in ArtLabArmy.GROUPS:
		_check(int(per.get(g, 0)) >= 5, "army: sweep lists >= 5 %s assets (got %d)" % [g, int(per.get(g, 0))])
	_check(kinds.has("building") and kinds.has("titan") and kinds.has("mount"), "army: sweep covers buildings, titans, mounts")
	# ranking: a FAIL beats a bigger-rate WARN; per asset every FAIL + one other item; SKIP ignored
	var checks := [
		{"id": "B4", "name": "Vertices", "status": "FAIL", "score": 0.2, "weight": 1.0, "group": "budget", "value": "14775", "hint": "fewer segments", "improve": ""},
		{"id": "R3", "name": "Contrast", "status": "WARN", "score": 0.4, "weight": 1.5, "group": "read", "value": "dE 18", "hint": "", "improve": "push the shell off the grass hue"},
		{"id": "P5", "name": "Glow placement", "status": "INFO", "score": 0.6, "weight": 1.0, "group": "polish", "value": "", "hint": "", "improve": "one glow high"},
		{"id": "R1", "name": "Area", "status": "SKIP", "score": -1.0, "weight": 1.0, "group": "read", "value": "", "hint": "", "improve": "x"},
		{"id": "H1", "name": "Errors", "status": "PASS", "score": 1.0, "weight": 1.0, "group": "health", "value": "0", "hint": "", "improve": ""}]
	var its := ArtLabArmy.items_of(checks)
	_check(its.size() == 3 and its[0]["id"] == "B4" and its[0]["text"] == "fewer segments", "army: items FAIL first, hint as the fix (%d items)" % its.size())
	if its.size() == 3:
		_check(its[1]["id"] == "R3" and float(its[1]["rate"]) > float(its[2]["rate"]), "army: then gain per minute (R3 recolour before P5)")
		_check(float(its[1]["gain"]) > 5.0 and float(its[1]["gain"]) < 30.0, "army: R3 gain in points (got %.1f)" % float(its[1]["gain"]))
	var ok_checks := [{"id": "P1", "name": "Hook", "status": "INFO", "score": 0.5, "weight": 1.0, "group": "polish", "value": "", "hint": "", "improve": "a hook"}]
	var bl := ArtLabArmy.backlog([{"name": "good", "kind": "unit", "kingdom": "ice", "ground": "snow", "checks": ok_checks},
		{"name": "bad", "kind": "building", "kingdom": "fire", "ground": "meadow", "checks": checks}])
	_check(bl.size() == 3 and bl[0]["asset_name"] == "bad" and bl[0]["status"] == "FAIL", "army: backlog FAIL first, 1 other item per asset (%d)" % bl.size())
	if bl.size() == 3:
		var line := ArtLabArmy.backlog_line(1, bl[0])
		_check(line.begins_with("| 1 | bad | fire | FAIL | B4 Vertices") and "run_art_lab.ps1 bad building fire" in line and "tech-artist" in line, "army: backlog line: " + line)
		_check("-Extra 'ground=snow'" in ArtLabArmy.recheck_cmd("good", "unit", "ice", "snow"), "army: re-check keeps the ground")
	# IoU of masks on offset frame rects (only the overlap is scanned)
	var ma := ArtLabImage.Mask.new(10, 10)
	var mb := ArtLabImage.Mask.new(12, 12)
	for y: int in 4:
		for x: int in 4:
			ma.bits[(y + 2) * 10 + x + 2] = 1   # frame x 102-105, y 52-55
			mb.bits[(y + 4) * 12 + x + 4] = 1   # on rect (100, 50): frame x 104-107, y 54-57
	ma.finish()
	mb.finish()
	_check(is_equal_approx(ArtLabArmy.iou_at(ma, Rect2i(100, 50, 10, 10), ma, Rect2i(100, 50, 10, 10)), 1.0), "army: offset IoU identical = 1")
	_check(absf(ArtLabArmy.iou_at(ma, Rect2i(100, 50, 10, 10), mb, Rect2i(100, 50, 12, 12)) - 4.0 / 28.0) < 0.001, "army: offset IoU 2x2 overlap = 4 / 28")
	_check(absf(ArtLabArmy.iou_at(ma, Rect2i(100, 50, 10, 10), mb, Rect2i(98, 48, 12, 12)) - 1.0) < 0.001, "army: offset IoU shifted rect = 1")
	var sa := {"name": "u1", "group": "nature", "kind": "unit", "roi": Rect2i(100, 50, 10, 10), "masks": [ma, ma, ma, ma], "lab": Vector3(50, 0, 0)}
	var sb := {"name": "u2", "group": "neutral", "kind": "unit", "roi": Rect2i(98, 48, 12, 12), "masks": [mb, mb, mb, mb], "lab": Vector3(55, 0, 0)}
	var sm := {"name": "m1", "group": "nature", "kind": "mount", "roi": Rect2i(100, 50, 10, 10), "masks": [ma, ma, ma, ma], "lab": Vector3(50, 0, 0)}
	var prs := ArtLabArmy.pairs_of({"u1": sa, "u2": sb, "m1": sm})
	_check(prs.size() == 1 and prs[0]["a"] == "u1" and ArtLabArmy.verdict(prs[0]) == "READS ALIKE", "army: pairs (no mount / unit pair; same shape + colour reads alike)")
	# fixes.json (task 1.A) read when present, any shape; the recipe of the asked check wins
	var fd := OUT + "/army_fixes"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fd))
	if FileAccess.file_exists(fd + "/fixes.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(fd + "/fixes.json"))
	_check(ArtLabArmy.top_recipe(fd) == "", "army: no fixes.json -> no recipe")
	var ff := FileAccess.open(fd + "/fixes.json", FileAccess.WRITE)
	ff.store_string(JSON.stringify({"fixes": [{"check": "R5", "proposal": "Eye_L energy 1.0 -> 1.4"}, {"check": "R3", "proposal": "Shell #5c7a3a -> #7a5c3a"}]}))
	ff.close()
	_check(ArtLabArmy.top_recipe(fd) == "R5: Eye_L energy 1.0 -> 1.4", "army: top recipe (%s)" % ArtLabArmy.top_recipe(fd))
	_check(ArtLabArmy.top_recipe(fd, "R3") == "R3: Shell #5c7a3a -> #7a5c3a", "army: recipe for the asked check")
	# headless mini sweep (budgets only, no silhouettes): army.md + backlog written outside docs/
	var code: int = await ArtLabArmy.sweep(self, {"sweep": "neutral", "only": "mirefang", "buildings": "0", "out": OUT + "/army",
		"out_root": OUT + "/army/assets", "backlog": OUT + "/army_backlog.md"})
	_check(code == 0 or code == 1, "army: mini sweep exit 0 / 1 (got %d)" % code)
	var army := FileAccess.get_file_as_string(OUT + "/army/army.md")
	_check("| 1 | mirefang | neutral |" in army and "## Ranking" in army, "army: army.md ranks the asset")
	_check(FileAccess.get_file_as_string(OUT + "/army_backlog.md").begins_with("# Art backlog"), "army: backlog written")
	_check(FileAccess.file_exists(OUT + "/army/assets/mirefang/scorecard.json"), "army: sweep scorecard in out_root")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OUT + "/army_backlog.md"))
	_check(await ArtLabArmy.sweep(self, {"sweep": "neutral", "only": "mirefang", "buildings": "0", "out": OUT + "/army",
		"out_root": OUT + "/army/assets", "backlog": OUT + "/army_backlog.md", "backlog_only": "1"}) == 0
		and FileAccess.file_exists(OUT + "/army_backlog.md"), "army: backlog_only rebuilds from the scorecards")
	_check(await ArtLabArmy.sweep(self, {"sweep": "bogus"}) == 2, "army: bad sweep group -> exit 2")


## v3 1.A fix recipes (tools/art_lab/lab_fixes.gd): the colour maths, the computed colour recipe on a planted
## green-on-grass body (R3 + R3t + R4k at once), the merge recipe (B1 over budget: 3 same-material boxes under one
## pivot), fixes.json and the top recipe leading "Improve next". Headless, no renders (the lab's data is planted).
func _test_fixes() -> void:
	var v := Vector3(0.18, 0.32, 0.07)
	_check(ArtLabFixes.lab_to_lin(ArtLabFixes.lin_to_lab(v)).distance_to(v) < 0.002, "fixes: Lab round trip")
	_check(ArtLabFixes.lin_to_lab(ArtLabFixes.srgb_to_lin(Color8(90, 140, 60))).distance_to(ArtLabImage.lab(90, 140, 60)) < 0.05,
		"fixes: same L*a*b* as ArtLabImage")
	var ctx := ArtLabRunner.new()
	ctx.kind = &"unit"
	ctx.tier = &"soldier"
	ctx.kingdom = &"nature"
	ctx.asset = "fixes_test"
	ctx.scene_path = "res://art/units/nature/fixes_test/fixes_test.tscn"
	ctx.out_dir = OUT + "/fixes"
	ctx.rep = ArtLabReport.new()
	ctx.rep.budget_row = {"meshes": 2, "src": "test"}
	var model := Node3D.new()
	root.add_child(model)
	ctx.target = model
	var pivot := Node3D.new()
	pivot.name = "Body"
	model.add_child(pivot)
	var green := StandardMaterial3D.new()
	green.resource_name = "fixes_shell"
	green.albedo_color = Color(0.30, 0.42, 0.18)
	var brown := StandardMaterial3D.new()
	brown.resource_name = "fixes_belly"
	brown.albedo_color = Color(0.35, 0.25, 0.15)
	for i: int in 4:
		var mi := MeshInstance3D.new()
		mi.name = ("Strap%d" % i) if i < 3 else "Belly"
		var bm := BoxMesh.new()
		bm.size = Vector3(1.0, 0.5, 1.0) if i < 3 else Vector3(0.4, 0.2, 0.4)
		mi.mesh = bm
		mi.material_override = green if i < 3 else brown
		mi.position = Vector3(float(i) * 1.1, 0.3, 0.0)
		pivot.add_child(mi)
	await process_frame
	ctx.m["census"] = ArtLabCensus.census(model, 0.0)
	# the "render": the same mix model the recipe uses (weights x albedo x a 0.9 light gain) on grass / Old Wood
	var ws := ArtLabFixes.material_weights(model, 0.0, ArtLabFixes.to_camera(ctx))
	var render := func(shell: Color) -> Vector3:
		var mix := Vector3.ZERO
		for k: String in ws:
			var lab: String = ws[k]["info"]["label"]
			mix += ArtLabFixes.srgb_to_lin(shell if lab == "fixes_shell" else brown.albedo_color) * float(ws[k]["w"])
		return ArtLabFixes.lin_to_lab(mix * 0.9)
	var body: Vector3 = render.call(green.albedo_color)
	var grass := ArtLabImage.lab(88, 118, 50)
	var wood := ArtLabImage.lab(62, 52, 38)
	ctx.m["con"] = {"n": 500, "de_means": body.distance_to(grass), "melt_frac": 0.2, "model_lab": body, "ground_lab": grass}
	ctx.m["fix_team"] = {"nature": {"n": 500, "model_lab": body, "ground_lab": grass},
		"fire": {"n": 500, "model_lab": body + Vector3(4.0, 10.0, 6.0), "ground_lab": grass}}
	ctx.m["fix_grounds"] = {"old_wood": {"n": 500, "model_lab": body, "ground_lab": wood}}
	var de0 := body.distance_to(grass)
	_check(de0 < 20.0, "fixes: planted body melts into the grass (dE %.1f)" % de0)
	ctx.rep.add("R3", "read", "Contrast vs ground (meadow)", "WARN" if de0 >= 10.0 else "FAIL", "mean-colour dE %.1f" % de0,
		"dE >= 20", "Melts into the meadow", 0.3, "raise contrast", "z40", 1.5)
	ctx.rep.add("R4k", "read", "Contrast on the home ground (old_wood)", "WARN", "dE %.1f" % body.distance_to(wood), "dE >= 20", "", 0.4)
	var cen: Dictionary = ctx.m["census"]
	ctx.rep.add("B1", "budget", "Meshes after the kit merge", "FAIL", str(int(cen["meshes"])), "<= 2", "Merge static parts", 0.0, "merge")
	var t0 := Time.get_ticks_msec()
	var out := ArtLabFixes.build(ctx)
	var ms := Time.get_ticks_msec() - t0
	_check(FileAccess.file_exists(OUT + "/fixes/fixes.json"), "fixes: fixes.json written")
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT + "/fixes/fixes.json"))
	_check(d is Dictionary and int((d as Dictionary).get("count", 0)) == 2, "fixes: 2 recipes (colour covers R3 + R4k, merge B1)")
	var col := {}
	var mer := {}
	for f: Dictionary in out["fixes"]:
		if String(f["check"]) in ["R3", "R4k"]:
			col = f
		elif String(f["check"]) == "B1":
			mer = f
	_check(String(out["fixes"][0]["status"]) == "FAIL" and int(out["fixes"][0]["rank"]) == 1, "fixes: a FAIL ranks first")
	_check(bool(col.get("computed", false)) and (col.get("changes", []) as Array).size() == 1, "fixes: colour recipe computed")
	if bool(col.get("computed", false)):
		var ch: Dictionary = col["changes"][0]
		_check(String(ch["material"]) == "fixes_shell" and String(ch["param"]) == "albedo_color", "fixes: recolours the biggest mass (%s)" % ch["material"])
		var pred: Dictionary = col["predicted"]
		var ok := true
		for k2: String in pred:
			if not k2.begins_with("R4 ") and float(pred[k2]) < 24.0:
				ok = false
		_check(ok, "fixes: R3 / R3t / R4k all predicted >= 24 at once (%s)" % str(pred))
		# apply the proposal to the planted model: the "re-run" must pass what it promised
		var to := Color.html(String(ch["to"]))
		var body2: Vector3 = render.call(to)
		_check(body2.distance_to(grass) >= 20.0 and body2.distance_to(wood) >= 20.0,
			"fixes: applied colour passes on grass (%.1f) and Old Wood (%.1f)" % [body2.distance_to(grass), body2.distance_to(wood)])
	var chs: Array = mer.get("changes", [])
	_check(not chs.is_empty() and "Strap*" in String(chs[0].get("words", "")) and int(mer["predicted"]["meshes"]) <= 2,
		"fixes: merge `Strap*` 3 -> 1 (%s)" % str(mer.get("text", "")))
	var imp := ctx.rep.improve_next()
	_check(not imp.is_empty() and "fixes.json #1" in String(imp[0]["text"]), "fixes: Improve next #1 is the top recipe")
	_check(ms < 4000, "fixes: build in %d ms" % ms)
	model.queue_free()
	ctx.free()
	await process_frame



## v3.1 fix round (docs/plan/art-lab-v3-trial-notes.md + craft + reach): headless, planted geometry.
func _test_v31() -> void:
	# quality shown the same everywhere (console / scorecard / diff): from the 0.1-snapped json value
	_check(ArtLabScore.shown(82.46) == 83 and ArtLabScore.shown(82.44) == 82 and ArtLabScore.delta_text(82.46, 84.95) == "+2",
		"v3.1: shown quality / delta (%d, %s)" % [ArtLabScore.shown(82.46), ArtLabScore.delta_text(82.46, 84.95)])
	# focus links: R3 re-measures R3t / R4 / R4k too
	var fs := ArtLabDiff.focus_set("R3")
	_check(fs.has("R3t") and fs.has("R4") and fs.has("R4k") and not fs.has("R6"), "v3.1: focus=R3 also re-measures R3t / R4 / R4k")
	_check("R3t" in ArtLabDiff.focus_text(fs) and "read40" in ArtLabDiff.focus_text(fs), "v3.1: focus text names the checks and passes")
	# C1 geometry: 7 box body parts (one box each) = plain; the same with 4 extra spheres per part = richer
	var ctx := ArtLabRunner.new()
	root.add_child(ctx)
	ctx.kind = &"unit"
	ctx.tier = &"soldier"
	ctx.kingdom = &"nature"
	ctx.rep = ArtLabReport.new()
	ctx.rep.budget_row = ArtLabBudgets.row(&"unit", &"soldier")
	var built: Array = []
	for rich: int in 2:
		var holder := Node3D.new()
		root.add_child(holder)
		var model := Node3D.new()
		holder.add_child(model)
		for p: int in 7:
			var piv := Node3D.new()
			piv.name = "Part%d" % p
			model.add_child(piv)
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.2, 0.4, 0.2)
			mi.mesh = bm
			mi.position = Vector3(0.0, 0.3 + 0.25 * float(p), 0.0)
			piv.add_child(mi)
			if rich == 1:
				for k: int in 4:
					var sp := MeshInstance3D.new()
					var sm := SphereMesh.new()
					sm.radius = 0.06
					sm.height = 0.12
					sp.mesh = sm
					sp.position = mi.position + Vector3(0.12 * cos(float(k)), 0.1, 0.12 * sin(float(k)))
					piv.add_child(sp)
		built.append([holder, model])
	await process_frame
	var g0 := ArtLabCheckCraft.measure_geometry(built[0][1], (built[0][0] as Node3D).global_transform, 0.0)
	var g1 := ArtLabCheckCraft.measure_geometry(built[1][1], (built[1][0] as Node3D).global_transform, 0.0)
	_check(int(g0["islands"]) == 7 and float(g0["plain_share"]) > 0.95, "v3.1 C1: 7 boxes = 7 plain shapes (%d, %.2f)" % [int(g0["islands"]), float(g0["plain_share"])])
	_check(int(g1["islands"]) == 35 and float(g1["plain_share"]) < float(g0["plain_share"]) and float(g1["entropy"]) > float(g0["entropy"]),
		"v3.1 C1: secondary spheres add shapes and normal variety (%d, %.2f, %.3f vs %.3f)" % [int(g1["islands"]),
		float(g1["plain_share"]), float(g1["entropy"]), float(g0["entropy"])])
	ctx.target = built[0][1]
	ctx.holder = built[0][0]
	ArtLabCheckCraft.check_geometry(ctx)
	var c1 := {}
	var c2 := {}
	for c: Dictionary in ctx.rep.checks:
		if c["id"] == "C1":
			c1 = c
		elif c["id"] == "C2":
			c2 = c
	_check(not c1.is_empty() and float(c1["score"]) < 0.3 and String(c1["improve"]) != "", "v3.1 C1: a box figure scores low with a hint (%s)" % str(c1.get("score", -1)))
	_check(not c2.is_empty() and float(c2["score"]) < 0.1, "v3.1 C2: 168 of 2500 verts is under-use (%s)" % str(c2.get("value", "")))
	for b: Array in built:
		(b[0] as Node3D).queue_free()
	# A3r: a 3 m lash driven into the ground at ~1.8 m must not PASS; the same lash held level passes
	for level: int in 2:
		var holder2 := Node3D.new()
		root.add_child(holder2)
		var model2 := Node3D.new()
		holder2.add_child(model2)
		var lash := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.02
		cm.bottom_radius = 0.02
		cm.height = 3.0
		lash.mesh = cm
		var a := Vector3(0.0, 0.8, 0.0)
		var dir := Vector3(0.0, -0.78, 1.8).normalized() if level == 0 else Vector3(0.0, 0.0, 1.0)
		lash.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), a + dir * 1.5)
		model2.add_child(lash)
		await process_frame
		ctx.target = model2
		ctx.holder = holder2
		ctx.opts = {"reach": "3.0"}
		var rr := ArtLabCheckAnim.tip_reach(ctx)
		var n0 := ctx.rep.checks.size()
		ArtLabCheckAnim.reach_report(ctx, ArtLabCheckAnim.declared_reach(ctx), rr)
		var st := String(ctx.rep.checks[n0]["status"]) if ctx.rep.checks.size() > n0 else "-"
		if level == 0:
			_check(float(rr["reach"]) > 1.6 and float(rr["reach"]) < 2.0 and st == "WARN",
				"v3.1 A3r: a lash in the ground at 1.8 m does not PASS (reach %.2f, %s)" % [float(rr["reach"]), st])
		else:
			_check(float(rr["reach"]) > 2.9 and st == "PASS", "v3.1 A3r: a level 3 m lash passes (reach %.2f, %s)" % [float(rr["reach"]), st])
		holder2.queue_free()
	# recipes: team-coloured materials are found by their albedo changing between team instances
	var tl := ArtLabFixes.team_labels([{"Body/Leaves#0": ["Leaves", Color(0.3, 0.6, 0.2)], "Body/Trunk#0": ["Bark", Color(0.3, 0.2, 0.1)]},
		{"Body/Leaves#0": ["Leaves", Color(0.8, 0.3, 0.1)], "Body/Trunk#0": ["Bark", Color(0.3, 0.2, 0.1)]}])
	_check(tl.has("Leaves") and not tl.has("Bark"), "v3.1 recipes: team-coloured material found (%s)" % str(tl.keys()))
	# B8: never proposes folding two different colours (dE 98); B5: a real light becomes a shared-material halo
	var model3 := Node3D.new()
	root.add_child(model3)
	var holder3 := Node3D.new()
	root.add_child(holder3)
	for k2: int in 2:
		var mi2 := MeshInstance3D.new()
		mi2.mesh = BoxMesh.new()
		var mat := StandardMaterial3D.new()
		mat.resource_name = "Leaves" if k2 == 0 else "DarkStone"
		mat.albedo_color = Color(0.35, 0.75, 0.25) if k2 == 0 else Color(0.08, 0.07, 0.09)
		mi2.material_override = mat
		model3.add_child(mi2)
	var omni := OmniLight3D.new()
	omni.name = "OrbLight"
	omni.light_color = ArtLabBudgets.KINGDOM_COLORS[&"fire"]
	omni.omni_range = 3.0
	model3.add_child(omni)
	await process_frame
	ctx.target = model3
	ctx.holder = holder3
	ctx.kingdom = &"fire"
	ctx.rep.budget_row = {"materials": 1, "lights": 0, "src": "test"}
	var b8 := ArtLabFixes.materials_fix(ctx, {"id": "B8", "status": "WARN", "name": "Unique materials", "hint": "snap to the palette"})
	_check((b8.get("changes", []) as Array).is_empty() and "no other pair is a look-alike" in String(b8.get("text", "")),
		"v3.1 B8: no merge of Leaves / DarkStone (%s)" % String(b8.get("text", "")).left(120))
	var b5 := ArtLabFixes.light_fix(ctx, {"id": "B5", "status": "FAIL", "name": "Real lights"})
	var t5 := String(b5.get("text", ""))
	_check("halo" in t5 and "B8" in t5 and "R6" in t5, "v3.1 B5: fake-glow recipe names B8 and the team-colour R6 risk (%s)" % t5.left(160))
	model3.queue_free()
	holder3.queue_free()
	ctx.queue_free()
	await process_frame


## v3 1.D (checks/read_v3.gd): colour-blind simulation, glow local contrast, walk / flicker stats, the pure verdicts of
## R11 / R5w / R5c / R6cb / S1, the terrain mask and the stage's extra light presets / autumn ground look.
func _test_read_v3() -> void:
	# CVD (Machado 2009): red and green move much closer for a deuteranope / protanope; greys stay grey
	var lr := ArtLabImage.lab(200, 40, 30)
	var lg := ArtLabImage.lab(60, 150, 40)
	for k: StringName in [&"deutan", &"protan"]:
		var sr := ArtLabImage.cvd_rgb(200, 40, 30, k)
		var sg := ArtLabImage.cvd_rgb(60, 150, 40, k)
		var d_sim := ArtLabImage.lab(sr.x, sr.y, sr.z).distance_to(ArtLabImage.lab(sg.x, sg.y, sg.z))
		_check(d_sim < lr.distance_to(lg) * 0.75, "v3 cvd %s: red / green closer (%.1f vs %.1f)" % [k, d_sim, lr.distance_to(lg)])
		var gy := ArtLabImage.cvd_rgb(128, 128, 128, k)
		_check(absi(gy.x - 128) <= 3 and absi(gy.y - 128) <= 3 and absi(gy.z - 128) <= 3, "v3 cvd %s keeps grey (%s)" % [k, gy])
	var im := _img(10, 10, Color(0.8, 0.1, 0.1))
	var sim := ArtLabImage.cvd_image(im, Rect2i(0, 0, 5, 10), &"deutan")
	_check(sim.get_pixel(7, 5).is_equal_approx(im.get_pixel(7, 5)) and not sim.get_pixel(2, 5).is_equal_approx(im.get_pixel(2, 5)),
		"v3 cvd_image changes the ROI only")
	# team-colour area (diff_mask) and mean dE: 4 kingdom colours on the left 5 columns of a grey body
	var roi := Rect2i(0, 0, 20, 10)
	var body := _mask_rect(20, 10, Rect2i(0, 0, 20, 10))
	var imgs: Array[Image] = []
	for c: Color in [Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60), Color(0.45, 0.75, 0.95), Color(0.35, 0.70, 0.25)]:
		var ti := _img(20, 10, Color(0.4, 0.4, 0.4))
		ti.fill_rect(Rect2i(0, 0, 5, 10), c)
		imgs.append(ti)
	var team := ArtLabImage.diff_mask(imgs, roi, body, 8.0)
	_check(team.count == 50, "v3 diff_mask = the team-colour area (50, got %d)" % team.count)
	_check(ArtLabImage.mean_de(imgs[0], imgs[0], roi, team) == 0.0 and ArtLabImage.mean_de(imgs[0], imgs[3], roi, team) > 20.0,
		"v3 mean_de on the team area")
	# glow local contrast: a warm dot on a dark body stands out, the same dot on a pale body does not
	var dark := _img(60, 60, Color(0.15, 0.15, 0.15))
	dark.fill_rect(Rect2i(29, 29, 3, 3), Color(1.0, 0.95, 0.8))
	var pale := _img(60, 60, Color(0.85, 0.85, 0.8))
	pale.fill_rect(Rect2i(29, 29, 3, 3), Color(1.0, 0.95, 0.8))
	var lc_d := ArtLabImage.local_contrast(dark, 30, 30, 2.0, 20.0)
	var lc_p := ArtLabImage.local_contrast(pale, 30, 30, 2.0, 20.0)
	_check(float(lc_d["dL"]) > 60.0 and float(lc_p["dL"]) < 15.0, "v3 local contrast dark %.0f / pale %.0f" % [float(lc_d["dL"]), float(lc_p["dL"])])
	# verdicts relative to the live thresholds (ArtLabBudgets.V3, calibrated by 1.C)
	var gw: float = ArtLabCheckReadV3.V3["glow_dl_warn"]
	var gv := ArtLabCheckReadV3.glow_contrast_verdict([gw + 20.0, gw - 5.0] as Array[float])
	_check(gv["status"] == "WARN" and int(gv["weak"]) == 1, "v3 R5c: a point under the warn line is weak (%s)" % str(gv))
	_check(ArtLabCheckReadV3.glow_contrast_verdict([gw + 10.0, gw + 30.0] as Array[float])["status"] == "PASS", "v3 R5c pass")
	# walk stats / verdict: a steady gait passes, a gait that loses half the silhouette warns
	var rest := _mask_rect(40, 40, Rect2i(10, 5, 10, 30))
	var ws_ok := ArtLabImage.walk_stats(rest, [rest, _mask_rect(40, 40, Rect2i(11, 5, 10, 30))])
	var ws_bad := ArtLabImage.walk_stats(rest, [rest, _mask_rect(40, 40, Rect2i(10, 5, 10, 15))])
	_check(absf(float(ws_bad["mean_iou"]) - 0.75) < 0.01 and absf(float(ws_bad["area_ratio_min"]) - 0.5) < 0.01, "v3 walk_stats %s" % str(ws_bad))
	_check(ArtLabCheckReadV3.walk_verdict(ws_ok, 300, 100)["status"] == "PASS", "v3 R11 steady gait passes")
	var vb := ArtLabCheckReadV3.walk_verdict(ws_bad, 150, 100)
	_check(vb["status"] == "WARN" and float(vb["grade"]) < 0.3, "v3 R11 half silhouette warns (%s)" % str(vb))
	_check(ArtLabCheckReadV3.walk_verdict(ArtLabImage.walk_stats(rest, [_mask_rect(40, 40, Rect2i(4, 5, 22, 30))]), 660, 100, true)["status"] == "INFO", "v3 R11 flyer: wing beat alone is INFO")
	# flicker
	var f_ok := ArtLabImage.flicker([1, 1, 1, 1, 1, 1, 1, 1] as Array[int])
	var hi := int(ArtLabCheckReadV3.V3["flicker_range_warn"]) + 1
	var f_bad := ArtLabImage.flicker([hi, 0, hi, 1, hi, hi, hi, hi] as Array[int])
	_check(ArtLabCheckReadV3.flicker_verdict(f_ok)["status"] == "PASS" and int(f_bad["drops"]) == 1 and int(f_bad["range"]) == hi
		and ArtLabCheckReadV3.flicker_verdict(f_bad)["status"] == "WARN", "v3 R5w flicker")
	# colour-blind verdict (WARN only, never FAIL)
	var cw: float = ArtLabCheckReadV3.V3["cb_pair_warn"]
	_check(ArtLabCheckReadV3.cb_verdict(cw + 10.0, 40.0, 10.0, 20.0)["status"] == "PASS"
		and ArtLabCheckReadV3.cb_verdict(cw - 1.0, 40.0, 10.0, 20.0)["status"] == "WARN"
		and ArtLabCheckReadV3.cb_verdict(cw + 10.0, 7.0, 10.0, 20.0)["status"] == "WARN", "v3 R6cb verdicts")
	# style bible: outside the autumn floor band scores high, a mid brown that melts scores low
	var s_ok := ArtLabCheckReadV3.style_verdict(45.0, 0.02, 70.0, 50.0, -1.0)
	var s_bad := ArtLabCheckReadV3.style_verdict(9.0, 0.6, 40.0, 20.0, -1.0)
	_check(float(s_ok["grade"]) > 0.9 and not s_ok["in_band"] and s_bad["in_band"] and float(s_bad["grade"]) < 0.2, "v3 S1 grades")
	var sw := ArtLabCheckReadV3.style_swatches()
	var tv := ArtLabCheckReadV3.team_vs_swatches(ArtLabBudgets.KINGDOM_COLORS[&"fire"], sw)
	_check(sw.size() >= 12 and float(tv["de"]) > 20.0, "v3 S1 swatches %d, fire vs floor dE %.1f" % [sw.size(), float(tv["de"])])
	# terrain mask (terrain.md 7.1: R snow, G sand, B ash, A marsh) over the stand-in spots
	var tm := ArtLabStage.terrain_mask_image()
	var snow := tm.get_pixel(204, 204)
	var ash := tm.get_pixel(204, 36)
	_check(snow.r > 0.99 and snow.b < 0.01 and ash.b > 0.99 and ash.r < 0.01 and tm.get_pixel(120, 120).r < 0.01, "v3 terrain mask")
	# stage: extra light presets (night stand-in, autumn) and the autumn ground look switch and switch back
	var st := ArtLabStage.new()
	root.add_child(st)
	st.setup(&"warm")
	var env0 := st.env_lit
	var mat0 := st.ground.material_override
	_check(st.terrain_mode == "stand-in" and "stand-in" in st.terrain_note(), "v3 stage terrain mode %s" % st.terrain_mode)
	_check(st.set_light(&"night") and st.light_now == &"night" and st.env_lit != env0, "v3 stage night preset")
	_check(st.set_light(&"autumn") and st.set_light(&"warm") and st.env_lit == env0, "v3 stage autumn preset and back")
	_check(st.set_ground_look(&"autumn") and st.ground.material_override != mat0, "v3 stage autumn ground look")
	_check(st.set_ground_look(&"") and st.ground.material_override == mat0, "v3 stage ground look back")
	st.queue_free()


func _mask_rect(w: int, h: int, r: Rect2i) -> ArtLabImage.Mask:
	var m := ArtLabImage.Mask.new(w, h)
	for y: int in range(r.position.y, r.end.y):
		for x: int in range(r.position.x, r.end.x):
			m.bits[y * w + x] = 1
	return m.finish()


## Tools upgrade U1 (2026-09-27, docs/plan/tools-upgrade-30min.md): log=<file>, C1-C4 ends per kind, the shared-kit
## palette snap recipe, settle_all (one shared settle wait), cast-pose constants.
func _test_u1() -> void:
	var r := ArtLabRunner.new()
	root.add_child(r)
	r.opts = {"log": "0"}
	_check(r.log_path() == "", "U1 log=0 -> no log")
	r.opts = {}
	_check(r.log_path() == ArtLabRunner.LOG_PATH, "U1 default log = the shared improvement log")
	r.opts = {"log": "trial_low"}
	_check(r.log_path() == "res://docs/art/lab/trial_low.md", "U1 log=<name> -> docs/art/lab/<name>.md (got %s)" % r.log_path())
	r.opts = {"log": "docs/art/lab/effort-trial/log.md"}
	_check(r.log_path() == "res://docs/art/lab/effort-trial/log.md", "U1 log=<path> under res:// (got %s)" % r.log_path())
	r.opts = {"log": "user://x/log.md"}
	_check(r.log_path() == "user://x/log.md", "U1 log=user:// kept")
	# a per-run log file gets its own header + row
	var rep := ArtLabReport.new()
	rep.asset = "u1_probe"
	rep.kind = "unit"
	rep.tier = "soldier"
	rep.add("B1", "budget", "Meshes", "PASS", "3", "<= 26", "", 1.0)
	var lp := OUT + "/u1_log.md"
	if FileAccess.file_exists(lp):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(lp))
	rep.append_log(lp, OUT + "/u1")
	var txt := FileAccess.get_file_as_string(lp)
	_check("u1_probe" in txt and txt.count("| When |") == 1, "U1 log=<file> writes its own log with one header")
	# craft ends per kind
	var cu := ArtLabBudgets.craft_for(&"unit")
	var cc := ArtLabBudgets.craft_for(&"critter")
	var cb := ArtLabBudgets.craft_for(&"building")
	_check(float(cu["w_per_part"]) == 1.0 and float(cc["w_per_part"]) == 0.0 and float(cb["w_plain"]) == 0.0,
		"U1 craft_for: critters / buildings drop shapes-per-part, buildings drop the plain share")
	_check(float(ArtLabBudgets.CRAFT["w_per_part"]) == 1.0, "U1 craft_for does not change CRAFT")
	_check(&"critter" in ArtLabCheckCraft.GRADED_KINDS and &"building" in ArtLabCheckCraft.GRADED_KINDS \
		and &"landmark" in ArtLabCheckCraft.GRADED_KINDS, "U1 C1-C4 graded for critters / buildings / landmarks")
	# known-good values (deer / aqueduct, calibration run) land near the good end
	_check(ArtLabScore.grade(0.94, float(cc["use_bad"]), float(cc["use_good"])) >= 0.9 \
		and ArtLabScore.grade(0.8, float(cc["edges_bad"]), float(cc["edges_good"])) >= 0.9, "U1 deer craft near the good end")
	var cl := ArtLabBudgets.craft_for(&"landmark")
	_check(ArtLabScore.grade(0.38, float(cl["use_bad"]), float(cl["use_good"])) >= 0.85 \
		and ArtLabScore.grade(0.841, float(cl["entropy_bad"]), float(cl["entropy_good"])) >= 0.9, "U1 aqueduct craft near the good end")
	# palette snap: a shared kit material -> the nearest other kit material; the asset's own material -> none
	r.scene_path = MODEL
	r.asset = "mirefang"
	var shared := "res://art/units/kit/materials/fire_cloth.tres"
	var info := ArtLabFixes.material_info(load(shared) as Material)
	info["path"] = shared
	var snap := ArtLabFixes.palette_snap(r, info, Color(0.2, 0.3, 0.6))
	_check(not snap.is_empty() and String(snap["material_path"]).begins_with("res://art/units/kit/materials/") \
		and String(snap["material_path"]) != shared, "U1 palette snap proposes another kit material (got %s)" % str(snap))
	var own := {"path": "res://art/units/neutral/mirefang/own.tres"}
	_check(ArtLabFixes.palette_snap(r, own, Color.RED).is_empty(), "U1 no snap for the asset's own material")
	# settle_all: several instances share one wait
	var a := Node3D.new()
	var b := Node3D.new()
	root.add_child(a)
	root.add_child(b)
	var f0 := Engine.get_process_frames()   # --fixed-fps 60: timers run on game time = frames / 60
	await r.settle_all([a, b, null])
	var dt := float(Engine.get_process_frames() - f0) / 60.0
	_check(dt >= 0.5 and dt < 1.5, "U1 settle_all: one 0.6 s wait for all (%.2f s game time)" % dt)
	a.queue_free()
	b.queue_free()
	_check(ArtLabCheckAnim.CAST_SAMPLES.size() >= 3, "U1 cast pose sampled at >= 3 moments")
	r.queue_free()
