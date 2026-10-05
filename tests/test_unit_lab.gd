extends SceneTree
## Unit Lab (docs/plan/unit-lab.md): spec parsing (text line, presets, bad ids), the cost-equal normaliser, the report
## statistics, and real fights in the arena: a deterministic replay (same seed = same result), two identical units tie
## within tolerance over many seeds, +25 % damage wins > 60 %, and a 4-unit matrix (6 pairs) through the report.
## Run:  godot --headless --path . -s tests/test_unit_lab.gd --fixed-fps 60 --quit-after 120000

const TASK_ID := "unit_lab"
const SPEC := preload("res://tools/unit_lab/unit_lab_spec.gd")
const ARENA := preload("res://tools/unit_lab/unit_lab_arena.gd")
const REPORT := preload("res://tools/unit_lab/unit_lab_report.gd")
const TIMEOUT_FRAMES := 110000

var frame := 0
var _started := false
var _done := false
var _errors: Array[String] = []
var _cases := 0


func _initialize() -> void:
	Engine.physics_ticks_per_second = 60


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2 and not _started:
		_started = true
		_run()
	if _done:
		if _errors.is_empty():
			print("PASS %s (%d checks)" % [TASK_ID, _cases])
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 20))])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out; %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	_cases += 1
	if not ok:
		_errors.append(what)
		print("  x " + what)


func _run() -> void:
	print("---- spec")
	_check_spec()
	print("---- equal cost")
	_check_equal()
	print("---- stats")
	_check_stats()
	print("---- determinism")
	var r1 := await _fight(SPEC.load_any("1 flame_guard vs 1 shade ; dist=10 limit=60", []), 0, 3)
	var r2 := await _fight(SPEC.load_any("1 flame_guard vs 1 shade ; dist=10 limit=60", []), 0, 3)
	_check(r1["winner"] == r2["winner"] and absf(float(r1["time"]) - float(r2["time"])) < 0.02 \
			and float(r1["a"]["hp_left"]) == float(r2["a"]["hp_left"]),
			"same seed, same fight: %s %s / %s %s" % [r1["winner"], r1["time"], r2["winner"], r2["time"]])
	_check(float(r1["a"]["dealt"]) > 0.0 and float(r1["b"]["dealt"]) > 0.0, "both sides dealt damage")
	print("---- mirror 1 v 1 over 12 seeds")
	var mirror := SPEC.load_any("1 flame_guard vs 1 flame_guard ; dist=10 limit=60", [])
	var ms := await _series(mirror, 12)
	_check(ms >= 0.35 and ms <= 0.65, "two identical units tie within tolerance (A score %.2f, want 0.35-0.65)" % ms)
	print("---- +25 % damage over 10 seeds")
	var plus := SPEC.load_any("damage_plus25", [])
	plus["seeds"] = SPEC.parse_seeds("1-10")
	var ps := await _series(plus, 10)
	_check(ps > 0.6, "+25 %% damage wins > 60 %% (A score %.2f)" % ps)
	print("---- matrix on 4 units")
	await _check_matrix()
	_done = true


func _check_spec() -> void:
	var errs: Array = []
	var s := SPEC.parse_text("6 flame_guard + 1 kilnwarden mana=full level=2 vs 7 rimeshield order=hold ; dist=18 seeds=1-5 limit=70",
			errs)
	_check(errs.is_empty(), "text parse has no error (%s)" % str(errs))
	var arm: Dictionary = s["arms"][0]
	var ga: Array = arm["a"]["groups"]
	_check(ga.size() == 2 and ga[0]["id"] == "flame_guard" and int(ga[0]["count"]) == 6, "side A groups %s" % str(ga))
	_check(float(ga[1]["mana"]) > 1000.0 and int(ga[1]["level"]) == 2, "mana=full and level=2 read")
	_check(String(arm["b"]["order"]) == "hold" and int(arm["b"]["groups"][0]["count"]) == 7, "side B order hold, 7 units")
	_check(float(s["distance"]) == 18.0 and (s["seeds"] as Array).size() == 5 and float(s["time_limit"]) == 70.0,
			"options dist / seeds / limit")
	var mods := SPEC.parse_text("3 shade attack_damage_pct=0.25 vs 3 shade", [])
	_check(is_equal_approx(float(mods["arms"][0]["a"]["groups"][0]["mods"].get("attack_damage_pct", 0.0)), 0.25),
			"a Stats key becomes a modifier")
	var bad: Array = []
	SPEC.parse_text("2 no_such_unit vs 1 shade", bad)
	_check(not bad.is_empty(), "an unknown id is reported")
	for p in SPEC.preset_names():
		var pe: Array = []
		var ps := SPEC.load_any(p, pe)
		_check(pe.is_empty(), "preset %s parses (%s)" % [p, str(pe)])
		_check(not (ps["arms"] as Array).is_empty() or String(ps["mode"]) == "matrix", "preset %s has fights" % p)
	_check(SPEC.preset_names().has("c1_kilnwarden") and SPEC.preset_names().has("c7_passage_retreat"),
			"the caster duels C1-C7 are presets")
	var m := SPEC.load_any("matrix_t1t2", [])
	_check((m["matrix"]["entries"] as Array).size() >= 40, "the T1/T2 matrix lists >= 40 entries (%d)" \
			% (m["matrix"]["entries"] as Array).size())
	_check((m["matrix"]["entries"] as Array).has("kilnwarden+flame_guard"), "casters enter as caster + line unit")
	_check(not (m["matrix"]["entries"] as Array).has("sunforge_cataphract"), "tier 3 is not in a tier 1-2 matrix")


func _check_equal() -> void:
	var errs: Array = []
	var pair := SPEC.equal_cost("grave_hound", "flame_guard", 720, errs)
	var a := SPEC.normalize_side(pair[0], errs)
	var b := SPEC.normalize_side(pair[1], errs)
	var ca := SPEC.side_cost(a).x
	var cb := SPEC.side_cost(b).x
	_check(errs.is_empty() and absf(float(ca) / float(cb) - 1.0) <= 0.08, "equal cost hound / guard: %d vs %d" % [ca, cb])
	_check(ca >= 500 and ca <= 1000, "near the budget (%d)" % ca)
	var cpair := SPEC.equal_cost("kilnwarden+flame_guard", "rimeshield", 720, errs)
	var cs := SPEC.normalize_side(cpair[0], errs)
	_check((cs["groups"] as Array).size() == 2 and cs["groups"][0]["id"] == "kilnwarden" and int(cs["groups"][0]["count"]) == 1,
			"a caster entry = 1 caster + the line unit")
	var cc := SPEC.side_cost(cs).x
	var cr := SPEC.side_cost(SPEC.normalize_side(cpair[1], errs)).x
	_check(absf(float(cc) / float(cr) - 1.0) <= 0.1, "caster entry cost %d vs %d" % [cc, cr])


func _check_stats() -> void:
	var w := REPORT.wilson(0.5, 100)
	_check(w.x > 0.39 and w.x < 0.41 and w.y > 0.59 and w.y < 0.61, "Wilson 50 %% of 100 = %s" % str(w))
	_check(REPORT.score_of({"winner": "draw"}) == 0.5 and REPORT.score_of({"winner": "b"}, "b") == 1.0, "score_of")
	_check(REPORT.median([3, 1, 2]) == 2.0 and REPORT.median([1, 2, 3, 4]) == 2.5, "median")


## One fight in a fresh arena; returns the result.
func _fight(spec: Dictionary, arm_i: int, sd: int) -> Dictionary:
	var arena: Node3D = ARENA.new()
	arena.set(&"log_enabled", false)
	root.add_child(arena)
	current_scene = arena
	arena.call(&"setup", spec, spec["arms"][arm_i], sd, sd % 2 == 0)
	var frames := 0
	while not bool(arena.get(&"ended")) and frames < 60 * 150:
		await physics_frame
		frames += 1
	if not bool(arena.get(&"ended")):
		arena.call(&"end_fight", "draw", "cap")
	var r: Dictionary = arena.get(&"result")
	arena.call(&"clear_units")
	root.remove_child(arena)
	arena.free()
	current_scene = null
	await process_frame
	return r


## Side A's score over `n` seeds (1..n) of arm 0.
func _series(spec: Dictionary, n: int) -> float:
	var sc := 0.0
	for sd in range(1, n + 1):
		var r := await _fight(spec, 0, sd)
		sc += REPORT.score_of(r)
	return sc / float(n)


func _check_matrix() -> void:
	var spec := SPEC.normalize({"matrix": {"ids": ["flame_guard", "shade", "rimeshield", "thornling"], "budget": 360},
			"seeds": "1-2", "time_limit": 90}, [])
	var m: Dictionary = spec["matrix"]
	var pairs := SPEC.matrix_pairs(m)
	_check(pairs.size() == 6, "4 entries -> 6 pairs (%d)" % pairs.size())
	var lines: Array = []
	for pair: Array in pairs:
		for sd in [1, 2]:
			var arm := SPEC.matrix_arm(m, pair[0], pair[1], [])
			var one := {"name": "matrix", "arms": [arm], "time_limit": 90.0, "distance": 20.0}
			var r := await _fight(one, 0, sd)
			r["entry_a"] = pair[0]
			r["entry_b"] = pair[1]
			r["budget"] = 360
			lines.append(r)
	var t := REPORT.matrix_table(lines)
	_check((t["entries"] as Array).size() == 4, "matrix table has 4 entries")
	var total := 0.0
	for e: String in t["entries"]:
		total += float(t["mean"][e])
	_check(absf(total - 2.0) < 0.01, "mean scores sum to n/2 (zero-sum, %.2f)" % total)
	var outs := REPORT.outliers(t)
	_check(outs.size() == 4, "outliers ranks every entry")
	var rep := REPORT.build(lines, spec, "test matrix")
	_check(String(rep["md"]).contains("Counter table") and String(rep["matrix_csv"]).contains("flame_guard"),
			"matrix report has the counter table and the CSV")
