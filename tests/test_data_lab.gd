extends SceneTree
## Data Lab test (docs/plan/data-lab.md). Headless:
##   & $GODOT --headless --path . -s tests/test_data_lab.gd --fixed-fps 60 --quit-after 900
## 1. The lab runs on the real data within RUN_BUDGET_CAL calibration loops of wall time (see below) and writes scorecard.md / .json with a 0-100 score (no history row).
## 2. Synthetic bad data is caught: model_path without model_scene (R2), NaN (F2), negative cost (F3), duplicate
##    build key (K2), reserved build key (K4), placeholder text (T2), missing tooltip on an item with an active (F5).
## 3. The history log appends a row and reads the score back.
## Prints "PASS data_lab" or "FAIL data_lab: <reason>".

const TASK_ID := "data_lab"
const Lab := preload("res://tools/data_lab/data_lab.gd")
const Report := preload("res://tools/data_lab/data_lab_report.gd")
const Checks := preload("res://tools/data_lab/data_lab_checks.gd")
const OUT := "user://data_lab_test"

## Wall time of the real-data run, judged against a same-run calibration loop (2026-10-02). The run took ~20 s alone
## and 115 s in a loaded CI run (4 Godot runs in parallel + a background service on 13 of 16 threads) with no code
## change, so the fixed 60 s line flipped. Lab.run is one blocking call, so a sampler THREAD times the fixed GDScript
## loop of test_20_a3 (_calib_once, best of CAL_REPEAT) every CAL_SLEEP_MS while the lab runs; the run's wall time is
## judged in loop medians: same machine, same moment. The loop is 0.232 ms on the quiet laptop, so RUN_BUDGET_CAL =
## 60 s / 0.232 ms = the old 60 s line on that quiet machine (a hang or a several-x slowdown of the lab still fails).
const RUN_BUDGET_S := 60.0   ## info only now (the old absolute line, printed next to the ratio verdict)
const RUN_BUDGET_CAL := 258000.0
const CAL_REPEAT := 3
const CAL_SLEEP_MS := 200

var _errors: Array[String] = []
var _cal_mutex := Mutex.new()
var _cal_stop := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_real_data()
	_test_synthetic()
	_test_history()
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	quit(0 if _errors.is_empty() else 1)


func _expect(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)


func _test_real_data() -> void:
	var pre := _main_calib_ms()
	_cal_mutex.lock()
	_cal_stop = false
	_cal_mutex.unlock()
	var sampler := Thread.new()
	sampler.start(_sampler_loop)
	var t0 := Time.get_ticks_msec()
	Lab.run({"out": OUT, "log": "0", "run": "test"})
	var secs := float(Time.get_ticks_msec() - t0) / 1000.0
	_cal_mutex.lock()
	_cal_stop = true
	_cal_mutex.unlock()
	var samples: Array = sampler.wait_to_finish()
	var post := _main_calib_ms()
	var cal_ms := _median(samples)
	if cal_ms <= 0.0:   # the lab finished before the first sample: fall back on the main-thread loops around it
		cal_ms = (pre + post) * 0.5
	var loops := secs * 1000.0 / cal_ms if cal_ms > 0.0 else INF
	print("  real run %.1f s; calibration loop median %.3f ms over %d samples during the run (main thread before %.3f / after %.3f ms) = %.0f loops (budget %.0f; the old %.0f s line %s)"
			% [secs, cal_ms, samples.size(), pre, post, loops, RUN_BUDGET_CAL, RUN_BUDGET_S, "over" if secs >= RUN_BUDGET_S else "under"])
	_expect(loops <= RUN_BUDGET_CAL, "real run took %.0f calibration loops > %.0f (%.1f s, loop %.3f ms)" % [loops,
			RUN_BUDGET_CAL, secs, cal_ms])
	_expect(FileAccess.file_exists(OUT.path_join("scorecard.md")), "no scorecard.md")
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT.path_join("scorecard.json")))
	_expect(d is Dictionary, "scorecard.json unreadable")
	if d is Dictionary:
		var q := float(d.get("quality", -1.0))
		_expect(q >= 0.0 and q <= 100.0, "quality %.1f out of 0-100" % q)
		_expect((d.get("checks", []) as Array).size() >= 25, "only %d checks" % (d.get("checks", []) as Array).size())
		_expect((d.get("improve_next", []) as Array).size() >= 3, "improve_next < 3 items")
		var scanned: Dictionary = d.get("scanned", {})
		_expect(int(scanned.get("units", 0)) >= 30 and int(scanned.get("items", 0)) >= 30, "scanned too few resources %s" % str(scanned))
		for c: Dictionary in d.get("checks", []):
			if c["id"] == "L1":
				_expect(c["status"] == "PASS", "real data: a .tres does not load (%s)" % c["value"])
		print("  real data: %s score %.0f in %.1f s" % [d.get("result"), q, secs])


## Sampler thread: best-of-CAL_REPEAT calibration loops (ms) until _cal_stop. Light: ~1 ms of work per CAL_SLEEP_MS.
func _sampler_loop() -> Array:
	var out: Array = []
	var data := _calib_data()
	while true:
		_cal_mutex.lock()
		var stop := _cal_stop
		_cal_mutex.unlock()
		if stop:
			break
		var best := 1 << 30
		for r in CAL_REPEAT:
			best = mini(best, _calib_once(data[0], data[1]))
		out.append(float(best) / 1000.0)
		OS.delay_msec(CAL_SLEEP_MS)
	return out


## The same calibration loop on the main thread (ms, median of 9 best-of-3 samples), before and after the run.
func _main_calib_ms() -> float:
	var data := _calib_data()
	var s: Array = []
	for k in 9:
		var best := 1 << 30
		for r in CAL_REPEAT:
			best = mini(best, _calib_once(data[0], data[1]))
		s.append(float(best) / 1000.0)
	return _median(s)


func _calib_data() -> Array:
	var pts: Array[Vector3] = []
	var dict := {}
	for i in 256:
		pts.append(Vector3(float((i * 37) % 101) - 50.0, 0.0, float((i * 53) % 97) - 48.0))
	for i in 64:
		dict[i] = i * 0.5
	return [pts, dict]


## test_20_a3's calibration workload (usec): a fixed loop of Vector3 math, typed-array reads and Dictionary lookups.
func _calib_once(pts: Array[Vector3], dict: Dictionary) -> int:
	var t0 := Time.get_ticks_usec()
	var acc := 0.0
	var n := pts.size()
	for r in 8:
		for i in n:
			var p := pts[i]
			var d := p.distance_squared_to(pts[(i * 7 + r) % n])
			if d < 400.0:
				acc += sqrt(d)
			acc += float(dict.get(i & 63, 0.0))
	if acc < 0.0:
		print(acc)   # never: keeps the loop's result alive
	return Time.get_ticks_usec() - t0


static func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	return float(s[s.size() / 2])


func _status(report: RefCounted, id: String) -> String:
	for c: Dictionary in report.checks:
		if c["id"] == id:
			return c["status"]
	return "missing"


func _test_synthetic() -> void:
	var report := Report.new()
	var checks := Checks.new(report)
	checks.scan_ui = false
	checks.scan_code_tables = false
	# A unit whose finished model is only in model_path (the step-10 bug class), a NaN HP and a negative cost.
	var u := UnitType.new()
	u.id = &"bad_unit"
	u.display_name = "Bad Unit"
	u.faction = &"fire"
	u.model_path = "res://art/units/caravan/caravan.tscn"
	u.max_hp = NAN
	u.cost = -5
	checks.units.append({"path": "res://data/units/bad_unit.tres", "res": u})
	# Two buildings of one kingdom on the same build key, one on a reserved letter.
	for spec: Array in [["bad_a", "Z"], ["bad_b", "Z"], ["bad_c", "W"]]:
		var b := BuildingType.new()
		b.id = StringName(spec[0])
		b.display_name = String(spec[0]).capitalize()
		b.faction = &"fire"
		b.kind = &"tower"
		b.cost = 100
		b.attack_damage = 10.0
		b.attack_range = 10.0
		b.hotkey_label = spec[1]
		checks.buildings.append({"path": "res://data/buildings/%s.tres" % spec[0], "res": b})
	# An item with placeholder text, and one with an active but no tooltip.
	var it := ItemType.new()
	it.id = &"bad_item"
	it.display_name = "Bad Item"
	it.icon_abbrev = "BI"
	it.passive_id = &"thing"
	it.passives = {&"thing": {}}
	it.tooltip = "TODO write this"
	checks.items.append({"path": "res://data/items/bad_item.tres", "res": it})
	var it2 := ItemType.new()
	it2.id = &"mute_item"
	it2.display_name = "Mute Item"
	it2.icon_abbrev = "MI"
	it2.active_id = &"stride"
	it2.active_cooldown = 10.0
	checks.items.append({"path": "res://data/items/mute_item.tres", "res": it2})
	# A tooltip that prints a number the data does not have (99), next to ones it has (2 s, 4 x 2 / 0.5 = 16).
	var it3 := ItemType.new()
	it3.id = &"drift_item"
	it3.display_name = "Drift Item"
	it3.icon_abbrev = "DI"
	it3.passive_id = &"burn"
	it3.passives = {&"burn": {"duration": 2.0, "interval": 0.5, "per_tick": 4.0}}
	it3.tooltip = "Burn: attacks burn for 16 over 2 s, then 99 more."
	checks.items.append({"path": "res://data/items/drift_item.tres", "res": it3})
	checks.check_load()
	checks.check_fields()
	checks.check_refs()
	checks.check_keys()
	checks.check_text()
	var want := {"R2": "FAIL", "F2": "FAIL", "F3": "FAIL", "K2": "FAIL", "K4": "FAIL", "T2": "FAIL", "F5": "FAIL", "T5": "WARN"}
	for id: String in want:
		_expect(_status(report, id) == want[id], "synthetic %s = %s, want %s" % [id, _status(report, id), want[id]])
	var t5: Array[String] = []
	for f: Dictionary in report.findings:
		if f["check"] == "T5":
			t5.append(String(f["what"]))
	_expect(t5.size() == 1 and t5[0].contains("99"), "T5 should flag only 99: %s" % str(t5))
	_expect(report.result() == "FAIL" and report.exit_code() == 1, "synthetic result %s" % report.result())
	_expect(report.quality() < 80.0, "synthetic score %.0f should be low" % report.quality())
	var md: String = report.to_markdown()
	_expect(md.contains("model_path") and md.contains("Improve next"), "markdown misses the R2 finding or Improve next")


func _test_history() -> void:
	# One file per process: two runs of this test at once (parallel CI / a stress run) appended to one shared file and
	# counted each other's rows.
	var log_path := OUT.path_join("history_test_%d.md" % OS.get_process_id())
	if FileAccess.file_exists(log_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(log_path))
	var r := Report.new()
	r.run_id = "hist"
	r.started = "now"
	r.add_check("X1", "fields", "Probe", "rule", 4, [{"sev": "WARN", "where": "a", "what": "b", "fix": "c"}])
	r.append_history(log_path, OUT)
	r.append_history(log_path, OUT)
	var prev := Report.read_previous(log_path)
	_expect(absf(prev - r.quality()) < 1.0, "history read back %.1f, wrote %.1f" % [prev, r.quality()])
	_expect(FileAccess.get_file_as_string(log_path).count("| hist |") == 2, "history rows not appended")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(log_path))   # this run's own scratch file
