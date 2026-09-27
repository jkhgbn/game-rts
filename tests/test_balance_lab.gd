extends SceneTree
## Balance Lab (docs/plan/balance-lab.md) unit test: no match is played (the runner does that). Checks
##  1. balance_match.gd: value specs ("x1.1", "+5", numbers), a variant applied in memory to the cached UnitType
##     (and restored), unknown ids / fields / bad values reported, never guessed; the example variant parses.
##  2. balance_report.gd: Fisher exact / Wilson numbers, aggregation of a synthetic baseline + variant results.jsonl,
##     scorecard checks and markdown.
##  3. balance_suggest.gd: the unit table (Data Lab B1 formulas) and ranked knobs; a nerf of a unit whose kingdom
##     already loses is marked "away from 45-55 %".
## Run: godot --headless --path . -s tests/test_balance_lab.gd --fixed-fps 60 --quit-after 600
## Prints "PASS balance_lab" or "FAIL balance_lab: <reasons>".

const TASK_ID := "balance_lab"
const MATCH := "res://tools/balance_lab/balance_match.gd"
const REPORT := "res://tools/balance_lab/balance_report.gd"
const SUGGEST := "res://tools/balance_lab/balance_suggest.gd"

var fails: Array[String] = []


func _initialize() -> void:
	_test_match()
	_test_report()
	_test_suggest()
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
	quit(0 if fails.is_empty() else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)
		print("  check failed: " + what)


func _test_match() -> void:
	var m: GDScript = load(MATCH)
	_check(m != null, "balance_match.gd loads")
	if m == null:
		return
	_check(is_equal_approx(m.call(&"resolve_value", 10.0, "x1.5"), 15.0), "x1.5")
	_check(is_equal_approx(m.call(&"resolve_value", 10.0, "*0.5"), 5.0), "*0.5")
	_check(is_equal_approx(m.call(&"resolve_value", 10.0, "+5"), 15.0), "+5")
	_check(is_equal_approx(m.call(&"resolve_value", 10.0, "-2.5"), 7.5), "-2.5")
	_check(is_equal_approx(m.call(&"resolve_value", 10.0, 7), 7.0), "plain number")
	_check(is_nan(m.call(&"resolve_value", 10.0, "lots")), "bad spec is NAN")
	var ex: Variant = m.call(&"read_variant", "res://tools/balance_lab/variants/grave_hound_dps.json")
	_check(ex is Dictionary and (ex as Dictionary).has("units"), "example variant parses")
	# Apply in memory, check the cached resource changed, then restore it.
	var ut: Resource = load("res://data/units/grave_hound.tres")
	var old_dmg: float = ut.get(&"attack_damage")
	var old_cost: int = ut.get(&"cost")
	var applied: Array = []
	var errors: Array = []
	var held: Array = []
	m.call(&"apply_to_resources", {"units": {"grave_hound": {"attack_damage": "x0.5", "cost": "+10", "nope": 3,
			"display_name": 4, "max_hp": "lots"}, "no_such_unit": {"cost": 1}}}, applied, errors, held)
	var again: Resource = load("res://data/units/grave_hound.tres")
	_check(again == ut, "same cached resource")
	_check(is_equal_approx(float(again.get(&"attack_damage")), old_dmg * 0.5), "damage halved in memory")
	_check(int(again.get(&"cost")) == old_cost + 10 and again.get(&"cost") is int, "cost +10 stays an int")
	_check(applied.size() == 2, "2 overrides applied (got %d)" % applied.size())
	_check(errors.size() == 4, "4 errors: unknown field, text field, bad value, unknown unit (got %d: %s)" % [errors.size(), str(errors)])
	ut.set(&"attack_damage", old_dmg)
	ut.set(&"cost", old_cost)


func _test_report() -> void:
	var r: GDScript = load(REPORT)
	_check(r != null, "balance_report.gd loads")
	if r == null:
		return
	_check(absf(float(r.call(&"fisher_p", 3, 0, 0, 3)) - 0.1) < 0.001, "fisher 3-0 vs 0-3 = 0.1")
	_check(absf(float(r.call(&"fisher_p", 1, 1, 1, 1)) - 1.0) < 0.001, "fisher equal = 1")
	var w: Array = r.call(&"wilson", 5.0, 10.0)
	_check(absf(float(w[0]) - 0.237) < 0.01 and absf(float(w[1]) - 0.763) < 0.01, "wilson 5/10 = 24-76 %")
	_check(int(r.call(&"games_needed", 0.2)) == 98, "98 games per arm for 20 pts")
	var rows: Array = []
	for i in 6:   # baseline: fire beats shadow 5-1; variant: 3-3
		rows.append(_row("baseline", "fire", "shadow", "fire" if i < 5 else "shadow", i))
		rows.append(_row("hound_up", "fire", "shadow", "fire" if i < 3 else "shadow", i))
	rows.append({"arm": "hound_up", "pair": "fire:shadow", "player": "fire", "enemy": "shadow", "seed": 9, "error": "timeout"})
	var card: Dictionary = r.call(&"build", rows, {"run": "t", "limit": "1800"})
	var base: Dictionary = card["arms"]["baseline"]
	var var_arm: Dictionary = card["arms"]["hound_up"]
	_check(int(base["kingdoms"]["fire"]["wins"]) == 5 and int(base["kingdoms"]["fire"]["games"]) == 6, "baseline fire 5/6")
	_check(int(var_arm["failed"]) == 1, "failed match counted")
	_check(int(var_arm["score"]) == 100 and int(base["score"]) < 100, "variant 50 %% scores 100, baseline less (%d / %d)" % [var_arm["score"], base["score"]])
	_check(card["best_arm"] == "hound_up", "best arm")
	var cmp: Dictionary = card["comparisons"]["hound_up"]["matchups"]["fire-shadow"]
	_check(bool(cmp["toward_50"]), "variant moved toward 50")
	_check(float(cmp["p"]) > 0.05, "5-1 vs 3-3 is not significant")
	var ids: Array = (card["checks"] as Array).map(func(c: Dictionary) -> String: return c["id"])
	for id in ["R1", "V1", "K1", "M1", "L1", "S1"]:
		_check(ids.has(id), "check %s present" % id)
	var r1: Dictionary = (card["checks"] as Array).filter(func(c: Dictionary) -> bool: return c["id"] == "R1")[0]
	_check(r1["status"] == "WARN", "R1 WARN with 1 of 13 failed (got %s)" % r1["status"])
	var md: String = r.call(&"to_markdown", card)
	_check(md.contains("Balance Lab scorecard") and md.contains("`hound_up` vs baseline") and md.contains("Improve next"), "markdown sections")


func _row(arm: String, p: String, e: String, winner: String, s: int) -> Dictionary:
	var pw := 6000 if winner == p else 3000
	var ew := 9000 - pw
	return {"arm": arm, "pair": "%s:%s" % [p, e], "player": p, "enemy": e, "seed": s, "winner": winner,
			"winner_side": "player" if winner == p else "enemy", "end_reason": "early-score", "end_time": 960.0 + s * 10.0,
			"script_errors": 0, "score": {"player": {"total": pw}, "enemy": {"total": ew}},
			"variant": {"name": arm, "applied": [] if arm == "baseline" else [{"id": "grave_hound", "field": "cost", "from": 70, "to": 60}], "errors": []}}


func _test_suggest() -> void:
	var s: GDScript = load(SUGGEST)
	_check(s != null, "balance_suggest.gd loads")
	if s == null:
		return
	var table: Array = s.call(&"unit_table")
	_check(table.size() >= 12, "unit table has the barracks units (got %d)" % table.size())
	var hound: Dictionary = {}
	for r: Dictionary in table:
		if r["unit"] == "grave_hound":
			hound = r
	_check(not hound.is_empty(), "grave_hound in the table")
	if hound.is_empty():
		return
	var gh: Resource = load("res://data/units/grave_hound.tres")
	var cd := maxf(0.1, float(gh.get(&"attack_cooldown")))
	_check(absf(float(hound["dps100"]) - float(gh.get(&"attack_damage")) / cd / float(gh.get(&"cost")) * 100.0) < 0.01, "DPS/100 formula = Data Lab B1")
	# Shadow loses 1/10, fire wins 9/10: any grave_hound nerf is "away", and no knob is picked "away".
	var wr := {"fire": {"wins": 9, "games": 10, "rate": 0.9}, "shadow": {"wins": 1, "games": 10, "rate": 0.1},
			"ice": {"wins": 5, "games": 10, "rate": 0.5}, "nature": {"wins": 5, "games": 10, "rate": 0.5}}
	var knobs: Array = s.call(&"candidates", table, wr)
	_check(not knobs.is_empty(), "some knobs")
	var sorted := true
	for i in range(1, knobs.size()):
		if float(knobs[i]["score"]) > float(knobs[i - 1]["score"]):
			sorted = false
	_check(sorted, "knobs ranked by score")
	for k: Dictionary in knobs:
		if k["unit"] == "grave_hound" and float(k["power_delta"]) < -0.02:
			_check(String(k["verdict"]).begins_with("away"), "grave_hound nerf marked away (%s)" % k["knob"])
		if k["kingdom"] == "fire" and float(k["power_delta"]) < -0.02:
			_check(String(k["verdict"]).begins_with("toward"), "fire nerf marked toward (%s)" % k["knob"])
