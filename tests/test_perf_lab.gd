extends SceneTree
## Perf Lab self-test (docs/plan/perf-lab.md). No level, no child process: checks the lab's own pieces.
## 1. perf_stats: percentiles, frame summary, median merge of repeats.
## 2. perf_budgets: logic budget scaling, script -> system mapping, budget table.
## 3. perf_probe: the band profiler times two synthetic scripts that burn a known amount of CPU per frame
##    (0.4 ms and 1.2 ms, one in _process, one in _physics_process) and must attribute them to the right bands.
## 4. perf_hints: the lint finds a costly pattern in a per-frame function (and in a helper it calls), not elsewhere.
## 5. perf_scorecard: judges a fake result (verdict, score range, >= 3 "Improve next" items), writes md / json and
##    a history row, and reads it back as the previous run.
## Run:  godot --headless --path . -s tests/test_perf_lab.gd --fixed-fps 60 --quit-after 900
## Prints "PASS perf lab" or "FAIL perf lab: <reasons>".

const TASK_ID := "perf lab"
const Stats := preload("res://tools/perf_lab/perf_stats.gd")
const Budgets := preload("res://tools/perf_lab/perf_budgets.gd")
const Probe := preload("res://tools/perf_lab/perf_probe.gd")
const Hints := preload("res://tools/perf_lab/perf_hints.gd")
const Scorecard := preload("res://tools/perf_lab/perf_scorecard.gd")
const BUSY_A_US := 400
const BUSY_B_US := 1200
const FRAMES := 60

var fails: Array[String] = []
var probe: Node
var frame := 0
var sums := {}
var _dir := ""


func _initialize() -> void:
	_dir = ProjectSettings.globalize_path("user://perf_lab_test")
	DirAccess.make_dir_recursive_absolute(_dir)
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	_test_stats()
	_test_budgets()
	_test_hints()
	_test_scorecard()
	# The probe first, then two scripted nodes (their scripts get a fake res:// path = their band key).
	probe = Probe.new()
	root.add_child(probe)
	root.add_child(_busy_node("res://lab_test/busy_a.gd", "_process", BUSY_A_US))
	root.add_child(_busy_node("res://lab_test/busy_b.gd", "_physics_process", BUSY_B_US))


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)


func _busy_node(path: String, fn: String, usec: int) -> Node:
	var s := GDScript.new()
	s.source_code = "extends Node\nfunc %s(_d: float) -> void:\n\tvar t := Time.get_ticks_usec()\n\twhile Time.get_ticks_usec() - t < %d:\n\t\tpass\n" % [fn, usec]
	s.reload()
	s.resource_path = path
	var n := Node.new()
	n.set_script(s)
	n.name = path.get_file().get_basename()
	return n


func _process(_delta: float) -> bool:
	var bands: Dictionary = probe.call(&"begin_frame")
	frame += 1
	if frame > 5 and frame <= 5 + FRAMES:
		var keys: Array = probe.get(&"bands")
		var pr: PackedInt64Array = bands["proc"]
		var ph: PackedInt64Array = bands["phys"]
		for k in pr.size():
			var key: String = keys[k]
			sums[key] = int(sums.get(key, 0)) + int(pr[k]) + int(ph[k] if k < ph.size() else 0)
	if frame == 6 + FRAMES:
		var a := float(sums.get("lab_test/busy_a.gd", 0)) / FRAMES
		var b := float(sums.get("lab_test/busy_b.gd", 0)) / FRAMES
		_check(a >= BUSY_A_US * 0.9 and a < BUSY_A_US * 3.0, "probe band busy_a = %.0f us/frame (want ~%d)" % [a, BUSY_A_US])
		_check(b >= BUSY_B_US * 0.9 and b < BUSY_B_US * 3.0, "probe band busy_b = %.0f us/frame (want ~%d)" % [b, BUSY_B_US])
		var other := float(sums.get("(other: unclassified nodes)", 0)) / FRAMES
		_check(other < BUSY_A_US * 0.5, "the busy nodes leaked into the unclassified band (%.0f us)" % other)
		if fails.is_empty():
			print("PASS %s (probe: busy_a %.0f us, busy_b %.0f us per frame)" % [TASK_ID, a, b])
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
		return true
	return false


func _test_stats() -> void:
	var v := [5.0, 1.0, 3.0, 2.0, 4.0]
	_check(is_equal_approx(Stats.median(v), 3.0), "median")
	_check(is_equal_approx(Stats.percentile(v, 100.0), 5.0), "p100")
	_check(is_equal_approx(Stats.percentile(v, 25.0), 2.0), "p25")
	var fs := Stats.frame_summary([10.0, 12.0, 40.0, 11.0], 33.3)
	_check(int(fs["hitches"]) == 1 and is_equal_approx(float(fs["max"]), 40.0), "frame_summary hitches / max")
	var m := Stats.median_merge([{"frame": {"avg": 10.0}, "units_avg": 100, "mode": "cpu"},
		{"frame": {"avg": 30.0}, "units_avg": 104, "mode": "cpu"}, {"frame": {"avg": 12.0}, "units_avg": 102, "mode": "cpu"}])
	_check(is_equal_approx(float(m["frame"]["avg"]), 12.0) and int(m["units_avg"]) == 102, "median_merge")
	_check(Stats.spread([10.0, 12.0, 11.0]) > 0.17 and Stats.spread([10.0, 12.0, 11.0]) < 0.19, "spread")


func _test_budgets() -> void:
	var b := Budgets.logic_budget("late200", 200)
	_check(is_equal_approx(float(b["limit"]), 16.0), "late200 budget 16 ms")
	var e := Budgets.logic_budget("early", 40)
	_check(is_equal_approx(float(e["limit"]), 3.2), "early budget scales 8 ms / 100 units (40 units -> 3.2)")
	_check(String(Budgets.system_of("scripts/ai/commander.gd")["id"]) == "ai_commander", "commander -> ai_commander")
	_check(String(Budgets.system_of("res://art/units/fire/fire_model.gd")["id"]) == "unit_models", "fire_model -> unit_models")
	_check(String(Budgets.system_of("scripts/world/fog_of_war.gd")["id"]) == "fog", "fog_of_war -> fog")
	_check(String(Budgets.system_of("[NavigationAgent3D]")["id"]) == "engine_nodes", "builtin band")
	_check(Budgets.markdown_table().count("\n") > 20, "budget table")


func _test_hints() -> void:
	var p := _dir.path_join("lint_me.gd")
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string("extends Node\n\nfunc _ready() -> void:\n\tvar a := get_tree().get_nodes_in_group(&\"units\")\n\n" +
		"func _process(_d: float) -> void:\n\t_helper()\n\tvar b := Node.new()\n\tb.free()\n\n" +
		"func _helper() -> void:\n\tfor u in get_tree().get_nodes_in_group(&\"units\"):\n\t\tpass\n")
	f.close()
	var rows := Hints.lint_script(p)
	var lines := {}
	for r: Dictionary in rows:
		lines[int(r["line"])] = r["pattern"]
	_check(lines.has(8), "lint: .new() inside _process (line 8)")
	_check(lines.has(12), "lint: get_nodes_in_group in a helper called from _process (line 12)")
	_check(not lines.has(4), "lint: _ready is not a per-frame function (line 4)")
	var s := Hints.for_script(p, rows, 1.5, 10)
	_check(String(s.get("text", "")).contains("lint_me.gd:"), "for_script cites file:line")


func _test_scorecard() -> void:
	var res := {"scenario": "mid100", "mode": "cpu", "commit": "test@0000", "started": "now", "measured_s": 30.0,
		"frame": {"avg": 7.0, "p95": 9.0, "p99": 13.0, "max": 40.0, "hitches": 1, "frames": 1800}, "units_avg": 100,
		"systems": {"ai_commander": {"avg_ms": 0.2, "median_ms": 0.05, "max_ms": 2.0}, "fog": {"avg_ms": 0.1, "median_ms": 0.0, "max_ms": 1.0}},
		"hot": [{"key": "scripts/units/unit.gd", "system": "Units (gameplay)", "nodes": 100, "avg_ms": 2.5, "max_ms": 9.0}],
		"census": {"lights": 20, "shadow_lights": 1, "decor_instances": 5000},
		"health": {"vfx_nodes_created": 0, "orphan_nodes": 0, "node_growth_pct": 1.0},
		"ai": {"tick_median_ms": 0.2, "tick_max_ms": 0.9, "ticks": 30, "worst_step": "scan"}}
	var sc := Scorecard.new()
	sc.judge(res, {})
	_check(sc.verdict() == "FAIL", "scorecard: 20 lights > 15 must FAIL (got %s)" % sc.verdict())
	var score := sc.score()
	_check(score > 20.0 and score < 95.0, "scorecard score in range (%.0f)" % score)
	_check(sc.ideas.size() >= 3, "scorecard: >= 3 Improve next items (%d)" % sc.ideas.size())
	var md := sc.to_markdown()
	_check(md.contains("## Improve next") and md.contains("## Hot list"), "scorecard markdown sections")
	sc.write(_dir)
	_check(FileAccess.file_exists(_dir.path_join("mid100_cpu.md")) and FileAccess.file_exists(_dir.path_join("mid100_cpu.json")),
		"scorecard files written")
	Scorecard.append_history(_dir, sc.history_row())
	var prev := Scorecard.previous_row(_dir, "mid100", "cpu", "")
	_check(String(prev.get("commit", "")) == "test@0000", "history row read back")
	var sc2 := Scorecard.new()
	var res2 := res.duplicate(true)
	res2["frame"]["avg"] = 9.0
	sc2.judge(res2, prev)
	var found := false
	for c: Dictionary in sc2.checks:
		if c["id"] == "R1" and c["status"] == "WARN":
			found = true
	_check(found, "regression check: +29 % vs the previous run must WARN")
