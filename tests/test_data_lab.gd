extends SceneTree
## Data Lab test (docs/plan/data-lab.md). Headless:
##   & $GODOT --headless --path . -s tests/test_data_lab.gd --fixed-fps 60 --quit-after 900
## 1. The lab runs on the real data in seconds and writes scorecard.md / .json with a 0-100 score (no history row).
## 2. Synthetic bad data is caught: model_path without model_scene (R2), NaN (F2), negative cost (F3), duplicate
##    build key (K2), reserved build key (K4), placeholder text (T2), missing tooltip on an item with an active (F5).
## 3. The history log appends a row and reads the score back.
## Prints "PASS data_lab" or "FAIL data_lab: <reason>".

const TASK_ID := "data_lab"
const Lab := preload("res://tools/data_lab/data_lab.gd")
const Report := preload("res://tools/data_lab/data_lab_report.gd")
const Checks := preload("res://tools/data_lab/data_lab_checks.gd")
const OUT := "user://data_lab_test"

var _errors: Array[String] = []


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
	var t0 := Time.get_ticks_msec()
	Lab.run({"out": OUT, "log": "0", "run": "test"})
	var secs := float(Time.get_ticks_msec() - t0) / 1000.0
	_expect(secs < 60.0, "real run took %.1f s" % secs)
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
	var log_path := OUT.path_join("history_test.md")
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
