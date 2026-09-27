extends SceneTree
## Map Lab (docs/plan/map-lab.md): the grid maths on a synthetic navmesh, the constant mirror rules on synthetic
## entries, the 2v2 profile, then one real run on Crown Hollow (sim mode, no history row, output in user://).
## Run: & tools/godot_run.ps1 --headless --path . -s tests/test_map_lab.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "map_lab"
const MapLab := preload("res://tools/map_lab/map_lab.gd")
const Grid := preload("res://tools/map_lab/map_grid.gd")
const Checks := preload("res://tools/map_lab/map_checks.gd")
const Report := preload("res://tools/map_lab/map_report.gd")
const Profiles := preload("res://tools/map_lab/map_profiles.gd")
const _SIM := preload("res://scripts/core/sim_mode.gd")
const OUT := "user://map_lab_test"
const TIMEOUT_FRAMES := 7000

var _fails: PackedStringArray = PackedStringArray()
var level: Node
var frame := 0
var ready_frame := -1


func _initialize() -> void:
	_test_grid()
	_test_constants()
	_test_profiles()
	_SIM.enabled = true
	level = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	MapLab._disable_bots(level)
	root.add_child(level)
	current_scene = level


func _process(_delta: float) -> bool:
	frame += 1
	if ready_frame < 0:
		MapLab._disable_bots(level)
		if level.get(&"match_started") == true or level.get(&"hero") != null:
			ready_frame = frame
		elif frame > TIMEOUT_FRAMES:
			_fail("the skirmish never finished its bake")
			return _finish()
		return false
	if frame < ready_frame + 10:
		return false
	_test_real_run()
	return _finish()


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("  - %s" % f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	return true


func _fail(msg: String) -> void:
	_fails.append(msg)


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fail(msg)


# ---------------------------------------------------------------- synthetic navmesh

## A 20 x 20 m square (-10..10) plus a 2 x 2 m island at (20..22, 20..22) with no mirror twin.
func _test_grid() -> void:
	var nm := NavigationMesh.new()
	nm.vertices = PackedVector3Array([Vector3(-10, 0, -10), Vector3(10, 0, -10), Vector3(10, 0, 10), Vector3(-10, 0, 10),
		Vector3(20, 0, 20), Vector3(22, 0, 20), Vector3(22, 0, 22), Vector3(20, 0, 22)])
	nm.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	nm.add_polygon(PackedInt32Array([4, 5, 6, 7]))
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nm
	root.add_child(region)
	var g := Grid.new()
	g.build([region], 30.0)
	_check(g.comp_area.size() == 2, "grid: 2 components expected, got %d" % g.comp_area.size())
	_check(absf(g.comp_area[g.main_comp] - 400.0) < 1.0, "grid: main area %.1f != 400" % g.comp_area[g.main_comp])
	_check(g.walkable(0, 0) and not g.walkable(21, 21) and not g.walkable(15, 0), "grid: walkable() wrong")
	var w: Dictionary = g.width_at(Vector2(0, 3), Vector2(1, 0))
	_check(absf(float(w["width"]) - 20.0) < 0.5, "grid: width across the square %.2f != 20" % w["width"])
	var near := g.nearest_main(12.0, 0.0, 5.0)
	_check(near != Vector3.INF and absf(near.x - 9.875) < 0.01, "grid: nearest_main %s" % str(near))
	var m: Dictionary = g.mirror_mismatch(Profiles.HALF_TURN)
	_check(int(m["mismatch"]) == 0, "grid: the island is not on the main component, so the main navmesh mirrors (%d)" % m["mismatch"])
	# Break the symmetry: a 4 x 4 m bump east of the square, joined by a shared edge, with no twin in the west.
	var nm3 := NavigationMesh.new()
	nm3.vertices = PackedVector3Array([Vector3(-10, 0, -10), Vector3(10, 0, -10), Vector3(10, 0, 0), Vector3(10, 0, 4),
		Vector3(10, 0, 10), Vector3(-10, 0, 10), Vector3(14, 0, 0), Vector3(14, 0, 4)])
	nm3.add_polygon(PackedInt32Array([0, 1, 2, 3, 4, 5]))
	nm3.add_polygon(PackedInt32Array([2, 6, 7, 3]))
	region.navigation_mesh = nm3
	var g3 := Grid.new()
	g3.build([region], 30.0)
	_check(g3.comp_area.size() == 1, "grid: shared edge must join the bump (%d comps)" % g3.comp_area.size())
	var m3: Dictionary = g3.mirror_mismatch(Profiles.HALF_TURN)
	_check(int(m3["mismatch"]) > 150, "grid: the one-sided bump (16 m²) must show as mirror mismatch (%d cells)" % m3["mismatch"])
	var tiles: Array = m3["tiles"]
	_check(not tiles.is_empty() and (tiles[0][0] as Vector2).distance_to(Vector2(12, 2)) < 4.0,
		"grid: mismatch tile near the bump (%s)" % [str(tiles[0][0]) if not tiles.is_empty() else "none"])
	# Octile Dijkstra on the plain square: corner to corner ~ 19 m diagonal.
	var g4 := Grid.new()
	region.navigation_mesh = nm
	g4.build([region], 30.0)
	g4.build_coarse()
	var src := g4.coarse_near(-9.5, -9.5)
	var dst := g4.coarse_near(9.5, 9.5)
	var d: PackedFloat32Array = g4.dijkstra(PackedInt32Array([src]))
	_check(absf(d[dst] - 19.0 * sqrt(2.0)) < 1.0, "grid: dijkstra corner to corner %.2f != %.2f" % [d[dst], 19.0 * sqrt(2.0)])
	_check(is_inf(d[g4.coarse_index(21, 21)]), "grid: the island is unreachable")
	g4.add_heat(PackedVector3Array([Vector3(-5, 0, 0), Vector3(5, 0, 0)]))
	var hot: Array = g4.hot_spots(1)
	_check(not hot.is_empty() and absf((hot[0][0] as Vector2).y) < 1.0, "grid: heat along the path")
	var img: Image = g4.heat_image([{"pos": Vector3.ZERO, "color": Color.RED}])
	_check(img.get_width() == g4.n, "grid: heat image size")
	region.queue_free()


# ---------------------------------------------------------------- constants

func _test_constants() -> void:
	var report := Report.new()
	var checks := Checks.new(report, Profiles.get_profile("1v1"), null)
	var issues: Array = []
	var ok := [{"label": "a", "pos": Vector3(1, 0, 2), "props": {"kind": "x", "tier": 1}},
		{"label": "b", "pos": Vector3(-1, 0, -2), "props": {"kind": "x", "tier": 1}}]
	_check(checks._mirror_constant("OK", ok, issues) == "mirrored" and issues.is_empty(), "const: mirrored pair")
	var one := [{"label": "a", "pos": Vector3(1, 0, 2), "props": {}}, {"label": "b", "pos": Vector3(3, 0, 2), "props": {}}]
	issues = []
	checks._mirror_constant("ONE", one, issues)
	_check(issues.size() == 1 and issues[0]["sev"] == "INFO", "const: one-sided list = INFO")
	var partial := ok.duplicate()
	partial.append({"label": "c", "pos": Vector3(5, 0, 5), "props": {"kind": "x"}})
	issues = []
	checks._mirror_constant("PART", partial, issues)
	_check(issues.size() == 1 and issues[0]["sev"] == "FAIL", "const: an entry without its twin = FAIL")
	var bad := [{"label": "a", "pos": Vector3(1, 0, 2), "props": {"kind": "x", "tier": 1}},
		{"label": "b", "pos": Vector3(-1, 0, -2), "props": {"kind": "x", "tier": 2}}]
	issues = []
	checks._mirror_constant("BAD", bad, issues)
	_check(not issues.is_empty() and issues[0]["sev"] == "FAIL" and String(issues[0]["what"]).contains("tier"),
		"const: twins with different tiers = FAIL")
	var kinds := [{"label": "a", "pos": Vector3(1, 0, 2), "props": {"kind": "x"}},
		{"label": "b", "pos": Vector3(-1, 0, -2), "props": {"kind": "y"}}, {"label": "d", "pos": Vector3(3, 0, 3), "props": {"kind": "z"}},
		{"label": "e", "pos": Vector3(-3, 0, -3), "props": {"kind": "z"}}]
	issues = []
	checks._mirror_constant("KIND", kinds, issues)
	_check(not issues.is_empty() and issues[0]["sev"] == "FAIL", "const: a twin of another kind does not count")
	var patrol := [{"label": "a", "pos": Vector3(1, 0, 2), "props": {}, "extra": [Vector3(1, 0, 3)]},
		{"label": "b", "pos": Vector3(-1, 0, -2), "props": {}, "extra": [Vector3(-1, 0, -4)]}]
	issues = []
	checks._mirror_constant("PATROL", patrol, issues)
	_check(not issues.is_empty() and String(issues[0]["what"]).contains("no mirror"), "const: unmirrored patrol point = FAIL")


func _test_profiles() -> void:
	var p1 := Profiles.get_profile("1v1")
	var p2 := Profiles.get_profile("2v2")
	_check((p1["symmetries"] as Array).size() == 1 and (p1["seats"] as Array).size() == 2, "profile 1v1 shape")
	_check((p2["symmetries"] as Array).size() == 3 and (p2["seats"] as Array).size() == 4, "profile 2v2 shape")
	_check(float(p2["half_size"]) == 84.0, "profile 2v2 is 168 m (map-2v2.md)")
	_check(Profiles.get_profile("nope").is_empty(), "unknown profile = {}")
	# The 2v2 symmetries map the A1 keep (-66, 66) onto the 3 other keeps.
	var keeps := [Vector3(-66, 0, -66), Vector3(66, 0, -66), Vector3(66, 0, 66)]
	for sym: Dictionary in p2["symmetries"]:
		var q: Vector3 = (sym["xf"] as Transform3D) * Vector3(-66, 0, 66)
		var hit := false
		for k: Vector3 in keeps:
			if k.distance_to(q) < 0.01:
				hit = true
		_check(hit, "profile 2v2: %s maps the A1 keep to a keep" % sym["name"])


# ---------------------------------------------------------------- real map

func _test_real_run() -> void:
	var report: Report = MapLab.run_on(level, Profiles.get_profile("1v1"), {"out": OUT, "run": "test", "log": "0"}, 0, ready_frame)
	var by_id := {}
	for c: Dictionary in report.checks:
		by_id[c["id"]] = c
	for id: String in ["N1", "N2", "N3", "M1", "M2", "M3", "M4", "F1", "F2", "D1", "C1", "C2", "H1"]:
		_check(by_id.has(id), "real: check %s missing" % id)
	for id: String in ["N1", "N2", "M1", "M2", "F1"]:
		if by_id.has(id):
			_check(by_id[id]["status"] != "FAIL", "real: %s FAILs on Crown Hollow: %s" % [id, by_id[id]["value"]])
	_check(int(report.counts_scanned.get("spots", 0)) >= 50, "real: only %d spots" % int(report.counts_scanned.get("spots", 0)))
	_check(FileAccess.file_exists(OUT.path_join("scorecard.md")) and FileAccess.file_exists(OUT.path_join("scorecard.json")),
		"real: scorecard not written")
	_check(FileAccess.file_exists(OUT.path_join("heatmap.png")), "real: heat map not written")
	var md := FileAccess.get_file_as_string(OUT.path_join("scorecard.md"))
	_check(md.contains("## Improve next") and md.contains("bridge_crown_w") and md.contains("Crossings"), "real: scorecard content")
	_check(report.quality() > 50.0, "real: score %.0f" % report.quality())
	print("map lab on Crown Hollow: %s score %.0f" % [report.result(), report.quality()])
