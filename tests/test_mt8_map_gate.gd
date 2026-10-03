extends SceneTree
## MT8 (docs/design/map-production.md 4.2 / 4.3 / 9): the map gate (tools/map_lab/map_gate.gd + run_map_gate.ps1, also
## `run_world_forge.ps1 gate <map>`), without the long runs (the runner itself was run on Thornwater; its scorecard is
## docs/tools/map_gate/thornwater/scorecard.md):
## - ids: Crown Hollow is judged through crown_hollow_level (World Forge) and plays skirmish.tscn (no layout);
## - G1-G4 on the real World Forge reports + Map Lab scorecards of Thornwater, Quartermeet and Crown Hollow: PASS
##   (score >= 75, 0 FAIL, spacing L3 / R4, symmetry N2 M1-M4 F1 D1 T1 C1 C2); the freshness check compiles each .map;
## - G5 on synthetic Bot Lab lines: 50 % -> PASS; 46 % in the 40-game pass -> WARN + second_pass; 30 % -> FAIL; a lopsided
##   cell with 10 games -> FAIL (cells are not judged in the 40-game pass); script errors, a stall or a game without a result -> FAIL;
## - G6 from a perf log (PASS / FAIL / skipped), the verdict (PASS / PARTIAL / FAIL), the markdown + JSON scorecard;
## - the runner and the World Forge verb exist (help text names the passes and the options).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_mt8_map_gate.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS mt8_map_gate" or "FAIL mt8_map_gate: <reasons>".

const TASK_ID := "mt8_map_gate"
const Gate := preload("res://tools/map_lab/map_gate.gd")

var fails: Array[String] = []
var notes: Array[String] = []


func _initialize() -> void:
	_ids()
	_forge()
	_bots()
	_verdict()
	_runner()
	for n in notes:
		print("  " + n)
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(fails)])
	quit(0 if fails.is_empty() else 1)


func _ids() -> void:
	if Gate.forge_id_of("crown_hollow") != "crown_hollow_level" or Gate.forge_id_of("thornwater") != "thornwater":
		fails.append("forge_id_of")
	if Gate.layout_path_of("crown_hollow") != "" or Gate.layout_path_of("quartermeet") != "res://data/maps/quartermeet_layout.tres":
		fails.append("layout_path_of")


func _forge() -> void:
	for id: String in ["thornwater", "quartermeet", "crown_hollow"]:
		var rows: Array[Dictionary] = Gate.forge_rows(id)
		var ids: Array[String] = []
		for r in rows:
			ids.append(r["id"])
			if r["status"] != "PASS":
				fails.append("%s %s %s: %s" % [id, r["id"], r["status"], r["value"]])
		if ids != ["G1", "G2", "G3", "G4"]:
			fails.append("%s forge rows %s" % [id, str(ids)])
		var f: Dictionary = Gate.fresh(id)
		if String(f["why"]).contains("does not compile") or String(f["why"]).begins_with("no "):
			fails.append("%s freshness: %s" % [id, f["why"]])
		notes.append("%s: %s" % [id, f["why"]])
	var none: Array[Dictionary] = Gate.forge_rows("no_such_map")
	if none.is_empty() or none[0]["status"] != "FAIL":
		fails.append("a map without a report does not FAIL G1")


## `n` mirror games per difficulty x kingdom with `wins` of them won by the PLAYER seat (spread over the mirrors).
static func _games(diffs: Dictionary, extra := {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ks := ["fire", "shadow", "ice", "nature"]
	for d: String in diffs:
		var n: int = diffs[d][0]
		var wins: int = diffs[d][1]
		for i in n:
			var k: String = ks[i % 4]
			var r := {"pair": "%s:%s" % [k, k], "player": k, "enemy": k, "difficulty": d, "seed": i / 4 + 1,
				"winner_side": "player" if i < wins else "enemy", "end_reason": "kill", "script_errors": 0,
				"startup_s": 4.0, "startup_parts": {"bake_s": 1.5}}
			for key: String in extra:
				r[key] = extra[key]
			out.append(r)
	return out


func _bots() -> void:
	# pass 1 balanced
	var g := _games({"easy": [12, 6], "normal": [16, 8], "hard": [12, 6]})
	var r: Dictionary = Gate.bot_row(Gate.bot_summary(g))
	if r["row"]["status"] != "PASS" or bool(r["second_pass"]):
		fails.append("50 %% pass 1: %s second %s" % [r["row"]["value"], r["second_pass"]])
	# 46 % (near the edge) in pass 1 -> the 120-game pass
	g = _games({"easy": [12, 6], "normal": [16, 7], "hard": [12, 6]})   # 7 / 16 = 43.75 %: within 3 points of 45
	r = Gate.bot_row(Gate.bot_summary(g))
	if r["row"]["status"] != "WARN" or not bool(r["second_pass"]):
		fails.append("43.75 %% pass 1 should ask for pass 2: %s %s" % [r["row"]["status"], r["second_pass"]])
	# far out -> FAIL at once
	g = _games({"easy": [12, 6], "normal": [16, 4], "hard": [12, 6]})
	r = Gate.bot_row(Gate.bot_summary(g))
	if r["row"]["status"] != "FAIL" or bool(r["second_pass"]):
		fails.append("25 %% should FAIL: %s" % r["row"]["value"])
	# pass 2 (10 per cell): a lopsided cell fails; a balanced one passes
	g = _games({"easy": [40, 20], "normal": [40, 20], "hard": [40, 20]})
	r = Gate.bot_row(Gate.bot_summary(g))
	if r["row"]["status"] != "PASS":
		fails.append("120 balanced games: %s" % r["row"]["value"])
	var lop: Array[Dictionary] = []
	for i in 10:
		lop.append({"player": "fire", "enemy": "fire", "difficulty": "hard", "winner_side": "player" if i < 9 else "enemy",
			"end_reason": "kill", "script_errors": 0})
	for i in 30:
		lop.append({"player": ["shadow", "ice", "nature"][i % 3], "enemy": "x", "difficulty": "hard",
			"winner_side": "enemy" if i < 18 else "player", "end_reason": "time-score", "script_errors": 0})
	r = Gate.bot_row(Gate.bot_summary(lop))
	if r["row"]["status"] != "FAIL" or not String(r["row"]["value"]).contains("cell hard fire"):
		fails.append("a 90 %% cell of 10 games should FAIL: %s" % r["row"]["value"])
	# hard failures
	for bad: Dictionary in [{"script_errors": 2}, {"end_reason": "stall"}]:
		g = _games({"normal": [8, 4]}, bad)
		r = Gate.bot_row(Gate.bot_summary(g))
		if r["row"]["status"] != "FAIL":
			fails.append("%s should FAIL: %s" % [str(bad), r["row"]["value"]])
	g = _games({"normal": [8, 4]})
	g.append({"pair": "fire:fire", "error": "no result (exit code 1)"})
	r = Gate.bot_row(Gate.bot_summary(g))
	if r["row"]["status"] != "FAIL":
		fails.append("a game without a result should FAIL: %s" % r["row"]["value"])
	var sm: Dictionary = Gate.bot_summary(_games({"normal": [8, 4]}))
	if not is_equal_approx(float(sm["startup_s"]), 4.0) or not is_equal_approx(float(sm["bake_s"]), 1.5):
		fails.append("startup / bake medians %s / %s" % [sm["startup_s"], sm["bake_s"]])
	var empty: Array[Dictionary] = []
	if Gate.bot_row(Gate.bot_summary(empty))["row"]["status"] != "SKIP":
		fails.append("no games should SKIP G5")


func _verdict() -> void:
	if Gate.perf_row("x\nPASS mt2_perf\n")["status"] != "PASS" or Gate.perf_row("FAIL mt2_perf: 3 stuck")["status"] != "FAIL" \
			or Gate.perf_row("")["status"] != "SKIP" or Gate.perf_row("garbage")["status"] != "FAIL":
		fails.append("perf_row")
	var good := _games({"easy": [12, 6], "normal": [16, 8], "hard": [12, 6]})
	var v: Dictionary = Gate.evaluate("thornwater", good, "PASS mt2_perf")
	if v["result"] != "PASS":
		fails.append("thornwater with passing bots + perf: %s (%s)" % [v["result"], v["summary"]])
	var none: Array[Dictionary] = []
	v = Gate.evaluate("thornwater", none, "", ["bots", "perf"])
	if v["result"] != "PARTIAL":
		fails.append("skipped bots + perf should be PARTIAL, got %s" % v["result"])
	v = Gate.evaluate("quartermeet", _games({"normal": [16, 2]}), "PASS mt2_perf")
	if v["result"] != "FAIL":
		fails.append("lopsided bots should FAIL the gate, got %s" % v["result"])
	var md: String = Gate.markdown(v)
	for want in ["# Map gate: quartermeet", "| G1 |", "| G5 |", "| G6 |", "FAIL"]:
		if not md.contains(want):
			fails.append("markdown lacks %s" % want)
	Gate.write(v, "user://mt8_gate_test")
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://mt8_gate_test/scorecard.json"))
	if not (j is Dictionary) or String(j.get("result", "")) != "FAIL" or (j["rows"] as Array).size() != 7:
		fails.append("scorecard.json not written / wrong")


func _runner() -> void:
	var ps := FileAccess.get_file_as_string("res://tools/map_lab/run_map_gate.ps1")
	for want in ["$Games = 40", "$Games2 = 120", "second_pass", "test_mt2_perf.gd", "run_lab.ps1", "step=verdict", "step=fresh"]:
		if not ps.contains(want):
			fails.append("run_map_gate.ps1 lacks %s" % want)
	var wf := FileAccess.get_file_as_string("res://tools/world_forge/run_world_forge.ps1")
	if not wf.contains("run_map_gate.ps1") or not wf.contains("\"gate\""):
		fails.append("run_world_forge.ps1 has no gate verb")
