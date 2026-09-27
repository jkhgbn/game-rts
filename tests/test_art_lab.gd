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
	_check(ArtLabReport.grade(5.0, 0.0, 10.0) == 0.5 and ArtLabReport.grade(20.0, 10.0, 0.0) == 0.0, "grade")
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
