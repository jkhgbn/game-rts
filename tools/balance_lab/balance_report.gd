extends SceneTree
## Balance Lab scorecard (docs/plan/balance-lab.md): results.jsonl of tools/balance_lab/run_balance.ps1 (one JSON line
## per match, key "arm" = "baseline" or the variant name) -> scorecard.md + scorecard.json, one row in history.md.
##   godot --headless --path <any project> -s <abs>/tools/balance_lab/balance_report.gd --quit-after 600 -- \
##       --in=<results.jsonl> --out=<dir> [--run=name] [--history=<history.md>] [--log=0] [--wall=s] [--limit=s]
## Compares every variant arm with the baseline arm: win rate per matchup (both seat orders together) and per kingdom,
## length, score share, Fisher exact p (win / loss counts), Wilson 95 % intervals. Scorecard style of the other labs:
## PASS / WARN / FAIL per check, score 0-100, "Improve next", history.
## No game class is used (runs on any commit).

const KINGDOMS: Array[String] = ["fire", "shadow", "ice", "nature"]
const TARGET_LO := 0.45
const TARGET_HI := 0.55
const WARN_LO := 0.35
const WARN_HI := 0.65
const LOW_N := 10            ## fewer games than this per kingdom: no FAIL, only WARN ("low N")
const LENGTH_LO := 900.0     ## rush-balance.md: median length 15:00-20:00
const LENGTH_HI := 1200.0

var args := {}


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var code := run(args)
	quit(code)


## Returns 0 PASS / WARN, 1 FAIL, 2 no input.
static func run(opts: Dictionary) -> int:
	var rows := read_jsonl(String(opts.get("in", "")))
	if rows.is_empty():
		print("BALANCE LAB: no results in %s" % opts.get("in", ""))
		return 2
	var card := build(rows, opts)
	var out_dir := String(opts.get("out", ""))
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
		_write(out_dir.path_join("scorecard.md"), to_markdown(card))
		_write(out_dir.path_join("scorecard.json"), JSON.stringify(card, "\t"))
	if String(opts.get("log", "1")) != "0" and String(opts.get("history", "")) != "":
		append_history(String(opts["history"]), card, out_dir)
	print("BALANCE LAB: %s score %d / 100 (best arm %s; %d matches, %d failed) -> %s" % [card["result"], card["score"],
			card["best_arm"], card["matches"], card["failed"], out_dir.path_join("scorecard.md")])
	for c: Dictionary in card["checks"]:
		if c["status"] != "PASS":
			print("  %s %s %s: %s" % [c["status"], c["id"], c["name"], c["value"]])
	return 1 if card["result"] == "FAIL" else 0


static func read_jsonl(path: String) -> Array:
	var out: Array = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("{"):
			var d: Variant = JSON.parse_string(line)
			if d is Dictionary:
				out.append(d)
	f.close()
	return out


# ---------------------------------------------------------------- statistics

## Two-sided Fisher exact test on [[a, b], [c, d]] (sum of the tables as likely or less likely than the observed one).
static func fisher_p(a: int, b: int, c: int, d: int) -> float:
	var r1 := a + b
	var c1 := a + c
	var n := a + b + c + d
	if n == 0:
		return 1.0
	var lf: Array[float] = [0.0]
	for i in range(1, n + 1):
		lf.append(lf[i - 1] + log(float(i)))
	var base := lf[r1] + lf[n - r1] + lf[c1] + lf[n - c1] - lf[n]
	var p_obs := exp(base - lf[a] - lf[b] - lf[c] - lf[d])
	var p := 0.0
	for x in range(maxi(0, c1 - (n - r1)), mini(r1, c1) + 1):
		var px := exp(base - lf[x] - lf[r1 - x] - lf[c1 - x] - lf[n - r1 - c1 + x])
		if px <= p_obs * (1.0 + 1e-7):
			p += px
	return minf(1.0, p)


## Wilson 95 % interval of k successes in n: [lo, hi].
static func wilson(k: float, n: float) -> Array[float]:
	if n <= 0.0:
		return [0.0, 1.0]
	var z := 1.96
	var p := k / n
	var den := 1.0 + z * z / n
	var mid := (p + z * z / (2.0 * n)) / den
	var half := z * sqrt(p * (1.0 - p) / n + z * z / (4.0 * n * n)) / den
	return [maxf(0.0, mid - half), minf(1.0, mid + half)]


## Games per arm to see a win-rate change of `delta` (two-sided 5 %, power 80 %, around 50 %).
static func games_needed(delta: float) -> int:
	return ceili(pow(1.96 + 0.84, 2.0) * 2.0 * 0.25 / (delta * delta))


static func median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var v := values.duplicate()
	v.sort()
	var m := v.size() / 2
	return float(v[m]) if v.size() % 2 == 1 else (float(v[m - 1]) + float(v[m])) / 2.0


# ---------------------------------------------------------------- aggregation

## One arm's numbers: matchups (unordered, "a-b" with a < b in KINGDOMS order), kingdoms, lengths, ends.
static func aggregate(rows: Array) -> Dictionary:
	var ok: Array = []
	var failed := 0
	var script_errors := 0
	var variant_errors: Array = []
	var applied := {}
	var live_recorded := false
	var live := {}   # id -> {seen, same}: units / buildings of an overridden id seen in the matches, and how many used the edited type
	for r: Dictionary in rows:
		script_errors += int(r.get("script_errors", 0))
		if r.has("error") or not r.has("winner"):
			failed += 1
			continue
		ok.append(r)
		var v: Variant = r.get("variant", {})
		if v is Dictionary:
			for e: Variant in (v as Dictionary).get("errors", []):
				if not variant_errors.has(str(e)):
					variant_errors.append(str(e))
			for a: Dictionary in (v as Dictionary).get("applied", []):
				applied["%s.%s" % [a.get("id", "?"), a.get("field", "?")]] = "%s -> %s" % [str(a.get("from")), str(a.get("to"))]
			var lv: Variant = (v as Dictionary).get("live", null)
			if lv is Dictionary:
				live_recorded = true
				for id: String in lv:
					var row: Dictionary = live.get(id, {"seen": 0, "same": 0})
					row["seen"] += int(lv[id].get("seen", 0))
					row["same"] += int(lv[id].get("same", 0))
					live[id] = row
	var matchups := {}
	var kingdoms := {}
	for k in KINGDOMS:
		kingdoms[k] = {"wins": 0, "games": 0}
	var lengths: Array = []
	var ends := {}
	var seat := {"player": 0, "enemy": 0, "none": 0}
	for r: Dictionary in ok:
		var p := String(r.get("player", ""))
		var e := String(r.get("enemy", ""))
		var w := String(r.get("winner", "none"))
		lengths.append(float(r.get("end_time", 0.0)))
		var why := String(r.get("end_reason", "?"))
		ends[why] = int(ends.get(why, 0)) + 1
		var ws := String(r.get("winner_side", "none"))
		seat[ws] = int(seat.get(ws, 0)) + 1
		if p == e or not KINGDOMS.has(p) or not KINGDOMS.has(e):
			continue
		var a := p if KINGDOMS.find(p) < KINGDOMS.find(e) else e
		var b := e if a == p else p
		var key := "%s-%s" % [a, b]
		if not matchups.has(key):
			matchups[key] = {"a": a, "b": b, "a_wins": 0, "b_wins": 0, "draws": 0, "games": 0, "lengths": [], "a_share": []}
		var m: Dictionary = matchups[key]
		m["games"] += 1
		m["lengths"].append(float(r.get("end_time", 0.0)))
		if w == a:
			m["a_wins"] += 1
		elif w == b:
			m["b_wins"] += 1
		else:
			m["draws"] += 1
		var sc: Variant = r.get("score", {})
		if sc is Dictionary and (sc as Dictionary).has("player"):
			var ta := float(sc["player"].get("total", 0)) if a == p else float(sc["enemy"].get("total", 0))
			var tb := float(sc["enemy"].get("total", 0)) if a == p else float(sc["player"].get("total", 0))
			if ta + tb > 0.0:
				m["a_share"].append(ta / (ta + tb))
		for k: String in [p, e]:
			kingdoms[k]["games"] += 1
			if w == k:
				kingdoms[k]["wins"] += 1
	for key: String in matchups:
		var m: Dictionary = matchups[key]
		var decided := int(m["a_wins"]) + int(m["b_wins"])
		m["a_rate"] = float(m["a_wins"]) / decided if decided > 0 else 0.5
		m["median_length"] = median(m["lengths"])
		var sh: Array = m["a_share"]
		var s := 0.0
		for x: float in sh:
			s += x
		m["a_share_mean"] = s / sh.size() if sh.size() > 0 else 0.5
	for k: String in kingdoms:
		var kd: Dictionary = kingdoms[k]
		kd["rate"] = float(kd["wins"]) / kd["games"] if int(kd["games"]) > 0 else -1.0
		kd["ci"] = wilson(float(kd["wins"]), float(kd["games"]))
	var real_ends := int(ends.get("kill", 0)) + int(ends.get("concede", 0))
	return {"matches": ok.size(), "failed": failed, "script_errors": script_errors, "variant_errors": variant_errors,
			"applied": applied, "live": live, "live_recorded": live_recorded, "matchups": matchups, "kingdoms": kingdoms, "median_length": median(lengths),
			"ends": ends, "real_end_share": float(real_ends) / ok.size() if ok.size() > 0 else 0.0, "seat": seat}


## Balance score of one arm, 0-100: 100 - 2 x mean over kingdoms of the points outside 45-55 % (and the same on
## matchups, weighted half). A kingdom at 65 % costs 20 points on its share.
static func balance_score(agg: Dictionary) -> int:
	var excess := 0.0
	var n := 0
	for k: String in agg["kingdoms"]:
		var kd: Dictionary = agg["kingdoms"][k]
		if int(kd["games"]) == 0:
			continue
		excess += _outside(float(kd["rate"]))
		n += 1
	var k_part := excess / n if n > 0 else 0.0
	var m_ex := 0.0
	var mn := 0
	for key: String in agg["matchups"]:
		m_ex += _outside(float(agg["matchups"][key]["a_rate"]))
		mn += 1
	var m_part := m_ex / mn if mn > 0 else 0.0
	return clampi(roundi(100.0 - 2.0 * (0.67 * k_part + 0.33 * m_part)), 0, 100)


static func _outside(rate: float) -> float:
	if rate < TARGET_LO:
		return (TARGET_LO - rate) * 100.0
	if rate > TARGET_HI:
		return (rate - TARGET_HI) * 100.0
	return 0.0


## PASS in 45-55 %, WARN in 35-65 %, else FAIL; below LOW_N games never PASS nor FAIL (not enough evidence): WARN.
static func _band(rate: float, games: int) -> String:
	if games < LOW_N:
		return "WARN"
	if rate >= TARGET_LO and rate <= TARGET_HI:
		return "PASS"
	if rate >= WARN_LO and rate <= WARN_HI:
		return "WARN"
	return "FAIL"


static func _worst(a: String, b: String) -> String:
	var order := ["PASS", "WARN", "FAIL"]
	return a if order.find(a) >= order.find(b) else b


# ---------------------------------------------------------------- the card

static func build(rows: Array, opts: Dictionary) -> Dictionary:
	var by_arm := {}
	var arm_order: Array[String] = []
	for r: Dictionary in rows:
		var arm := String(r.get("arm", "baseline"))
		if not by_arm.has(arm):
			by_arm[arm] = []
			arm_order.append(arm)
		by_arm[arm].append(r)
	if arm_order.has("baseline"):
		arm_order.erase("baseline")
		arm_order.push_front("baseline")
	var arms := {}
	var total := 0
	var failed := 0
	for arm in arm_order:
		var agg := aggregate(by_arm[arm])
		agg["score"] = balance_score(agg)
		arms[arm] = agg
		total += int(agg["matches"])
		failed += int(agg["failed"])
	# Comparisons: every variant arm vs baseline, per matchup and per kingdom.
	var comparisons := {}
	if arms.has("baseline"):
		var base: Dictionary = arms["baseline"]
		for arm in arm_order:
			if arm == "baseline":
				continue
			comparisons[arm] = compare(base, arms[arm])
	var best := arm_order[0]
	for arm in arm_order:
		if int(arms[arm]["score"]) > int(arms[best]["score"]):
			best = arm
	var checks := _checks(arms, arm_order, comparisons, opts)
	var result := "PASS"
	for c: Dictionary in checks:
		result = _worst(result, String(c["status"]))
	var improve := _improve(arms, arm_order, comparisons, best)
	var now := Time.get_datetime_dict_from_system()
	return {"run": String(opts.get("run", "")), "date": "%04d-%02d-%02d %02d:%02d" % [now.year, now.month, now.day, now.hour, now.minute],
			"input": String(opts.get("in", "")), "wall_s": String(opts.get("wall", "")), "limit": String(opts.get("limit", "")),
			"tick": String(opts.get("tick", "")), "sim": String(opts.get("sim", "")),
			"result": result, "score": int(arms[best]["score"]), "best_arm": best, "matches": total, "failed": failed,
			"arm_order": arm_order, "arms": arms, "comparisons": comparisons, "checks": checks, "improve": improve}


static func compare(base: Dictionary, v: Dictionary) -> Dictionary:
	var out := {"matchups": {}, "kingdoms": {}, "length_delta": float(v["median_length"]) - float(base["median_length"])}
	for key: String in v["matchups"]:
		if not base["matchups"].has(key):
			continue
		var b: Dictionary = base["matchups"][key]
		var m: Dictionary = v["matchups"][key]
		var p := fisher_p(int(b["a_wins"]), int(b["b_wins"]), int(m["a_wins"]), int(m["b_wins"]))
		var toward := absf(float(m["a_rate"]) - 0.5) < absf(float(b["a_rate"]) - 0.5)
		out["matchups"][key] = {"base_rate": b["a_rate"], "rate": m["a_rate"], "delta": float(m["a_rate"]) - float(b["a_rate"]),
				"base_share": b["a_share_mean"], "share": m["a_share_mean"],
				"share_delta": float(m["a_share_mean"]) - float(b["a_share_mean"]),
				"p": p, "note": _sig_note(p, int(b["games"]) + int(m["games"])),
				"toward_50": toward, "games": [b["games"], m["games"]]}
	for k: String in v["kingdoms"]:
		var bk: Dictionary = base["kingdoms"][k]
		var vk: Dictionary = v["kingdoms"][k]
		if int(bk["games"]) == 0 or int(vk["games"]) == 0:
			continue
		var p2 := fisher_p(int(bk["wins"]), int(bk["games"]) - int(bk["wins"]), int(vk["wins"]), int(vk["games"]) - int(vk["wins"]))
		out["kingdoms"][k] = {"base_rate": bk["rate"], "rate": vk["rate"], "delta": float(vk["rate"]) - float(bk["rate"]),
				"p": p2, "note": _sig_note(p2, int(bk["games"]) + int(vk["games"]))}
	return out


static func _sig_note(p: float, n: int) -> String:
	if p < 0.05:
		return "significant (p %.3f)" % p
	if p < 0.2:
		return "a hint (p %.2f): confirm with more seeds" % p
	if n < 20:
		return "noise at this N (p %.2f, %d games; ~%d per arm to see a 20-pt change)" % [p, n, games_needed(0.2)]
	return "no clear change (p %.2f)" % p


static func _checks(arms: Dictionary, order: Array[String], comparisons: Dictionary, opts: Dictionary) -> Array:
	var checks: Array = []
	# R1: every match ran, no script error.
	var failed := 0
	var errs := 0
	var total := 0
	for arm in order:
		failed += int(arms[arm]["failed"])
		errs += int(arms[arm]["script_errors"])
		total += int(arms[arm]["matches"]) + int(arms[arm]["failed"])
	var r1 := "PASS" if failed == 0 and errs == 0 else ("WARN" if failed * 4 < total else "FAIL")
	checks.append({"id": "R1", "name": "Matches ran", "status": r1, "score": 100 if r1 == "PASS" else (60 if r1 == "WARN" else 0),
			"value": "%d / %d ok, %d script errors" % [total - failed, total, errs], "target": "every match ends with a result, 0 SCRIPT ERROR"})
	# V1: the variants applied cleanly.
	var v_bad: Array[String] = []
	var v_txt: Array[String] = []
	for arm in order:
		if arm == "baseline":
			continue
		var ap: Dictionary = arms[arm]["applied"]
		var lv: Dictionary = arms[arm].get("live", {})
		var live_txt: Array[String] = []
		var live_bad := false
		for id: String in lv:
			live_txt.append("%s %d/%d live on the edited type" % [id, lv[id]["same"], lv[id]["seen"]])
			if int(lv[id]["same"]) < int(lv[id]["seen"]):
				live_bad = true
		if ap.is_empty() or live_bad or not (arms[arm]["variant_errors"] as Array).is_empty():
			v_bad.append("%s (%d applied, errors: %s; %s)" % [arm, ap.size(), ", ".join(arms[arm]["variant_errors"]), ", ".join(live_txt)])
		else:
			v_txt.append("%s: %s%s" % [arm, ", ".join(ap.keys().map(func(k: String) -> String: return "%s %s" % [k, ap[k]])),
					" (%s)" % ", ".join(live_txt) if not live_txt.is_empty() else (" (no live unit of it seen)" if bool(arms[arm].get("live_recorded", false)) else " (live check not recorded)")])
	if order.size() > 1 or not order.has("baseline"):
		checks.append({"id": "V1", "name": "Variants applied", "status": "PASS" if v_bad.is_empty() else "FAIL",
				"score": 100 if v_bad.is_empty() else 0, "value": "; ".join(v_txt) if v_bad.is_empty() else "; ".join(v_bad),
				"target": "every override found and applied, no variant error, every live unit of an overridden id uses the edited type"})
	# K1 / M1 per arm: kingdoms and matchups in 45-55 %.
	for arm in order:
		var agg: Dictionary = arms[arm]
		var st := "PASS"
		var parts: Array[String] = []
		for k in KINGDOMS:
			var kd: Dictionary = agg["kingdoms"][k]
			if int(kd["games"]) == 0:
				continue
			st = _worst(st, _band(float(kd["rate"]), int(kd["games"])))
			parts.append("%s %d%% (%d/%d)" % [k, roundi(float(kd["rate"]) * 100.0), kd["wins"], kd["games"]])
		if not parts.is_empty():
			checks.append({"id": "K1", "name": "Kingdom win rates [%s]" % arm, "status": st, "score": agg["score"],
					"value": ", ".join(parts), "target": "45-55 %% per kingdom (non-mirror); WARN 35-65 %% or < %d games" % LOW_N})
		var ms := "PASS"
		var mparts: Array[String] = []
		for key: String in agg["matchups"]:
			var m: Dictionary = agg["matchups"][key]
			ms = _worst(ms, _band(float(m["a_rate"]), int(m["games"])))
			mparts.append("%s %d-%d" % [key, m["a_wins"], m["b_wins"]])
		if not mparts.is_empty():
			checks.append({"id": "M1", "name": "Matchups [%s]" % arm, "status": ms, "score": agg["score"],
					"value": ", ".join(mparts), "target": "each matchup 45-55 % (both seat orders together)"})
	# L1: length (only meaningful when the limit allows 20:00).
	var limit := String(opts.get("limit", "1800")).to_float()
	for arm in order:
		var ml := float(arms[arm]["median_length"])
		var ls := "PASS" if ml >= LENGTH_LO and ml <= LENGTH_HI else "WARN"
		var note := ""
		if limit > 0.0 and limit < LENGTH_HI:
			ls = "PASS"
			note = " (limit %s: length not judged)" % _clock(limit)
		checks.append({"id": "L1", "name": "Median length [%s]" % arm, "status": ls, "score": 100 if ls == "PASS" else 60,
				"value": "%s, real ends (kill / concede) %d%%%s" % [_clock(ml), roundi(float(arms[arm]["real_end_share"]) * 100.0), note],
				"target": "15:00-20:00 (rush-balance.md)"})
	# S1: did any variant move something with evidence?
	for arm: String in comparisons:
		var cmp: Dictionary = comparisons[arm]
		var best_p := 2.0
		var what := ""
		for key: String in cmp["matchups"]:
			var c: Dictionary = cmp["matchups"][key]
			if float(c["p"]) < best_p:
				best_p = float(c["p"])
				what = key
		var s1 := "PASS" if best_p < 0.05 else "WARN"
		checks.append({"id": "S1", "name": "Evidence [%s vs baseline]" % arm, "status": s1, "score": 100 if s1 == "PASS" else 50,
				"value": "lowest p %.2f (%s)" % [best_p, what] if what != "" else "no common matchup",
				"target": "a matchup change with p < 0.05 (Fisher exact on wins)"})
	return checks


static func _improve(arms: Dictionary, order: Array[String], comparisons: Dictionary, best: String) -> Array[String]:
	var out: Array[String] = []
	var agg: Dictionary = arms[best]
	var worst_key := ""
	var worst := -1.0
	for key: String in agg["matchups"]:
		var d := absf(float(agg["matchups"][key]["a_rate"]) - 0.5)
		if d > worst:
			worst = d
			worst_key = key
	if worst_key != "" and _outside(float(agg["matchups"][worst_key]["a_rate"])) > 0.0:
		var m: Dictionary = agg["matchups"][worst_key]
		var loser: String = m["b"] if float(m["a_rate"]) > 0.5 else m["a"]
		out.append("Worst matchup in %s: %s (%d-%d). Run `balance_suggest.gd` and try its top knob for %s." % [best,
				worst_key, m["a_wins"], m["b_wins"], loser])
	var min_games := 1 << 30
	for arm in order:
		for key: String in arms[arm]["matchups"]:
			min_games = mini(min_games, int(arms[arm]["matchups"][key]["games"]))
	if min_games < games_needed(0.2):
		out.append("N is small (%d games per matchup per arm): ~%d per arm are needed to see a 20-pt change, ~%d for 10 pts. Add seeds (-Seeds 1-12) and prefer -Tick 30 sweeps, confirmed at 60." % [
				min_games if min_games < (1 << 30) else 0, games_needed(0.2), games_needed(0.1)])
	for arm: String in comparisons:
		for key: String in comparisons[arm]["matchups"]:
			var c: Dictionary = comparisons[arm]["matchups"][key]
			if float(c["p"]) < 0.2 and bool(c["toward_50"]):
				out.append("%s moved %s toward 50 %% (%s): confirm, then hand it to game-designer." % [arm, key, c["note"]])
	if int(arms[order[0]]["script_errors"]) > 0:
		out.append("Fix the SCRIPT ERRORs in the match logs first.")
	return out


# ---------------------------------------------------------------- output

static func to_markdown(card: Dictionary) -> String:
	var md := "# Balance Lab scorecard: %s\n\n" % card["run"]
	md += "**%s, score %d / 100** (best arm `%s`). %d matches, %d failed. %s. Limit %s s, tick %s, sim %s, wall %s s.\n\n" % [
			card["result"], card["score"], card["best_arm"], card["matches"], card["failed"], card["date"], card["limit"],
			card["tick"], card["sim"], card["wall_s"]]
	var min_games := 1 << 30
	for arm: String in card["arm_order"]:
		for k: String in card["arms"][arm]["kingdoms"]:
			var g := int(card["arms"][arm]["kingdoms"][k]["games"])
			if g > 0:
				min_games = mini(min_games, g)
	if min_games < LOW_N:
		md += "> **Low N**: as few as %d games per kingdom in an arm. Score and win rates are a smoke of the lab, not a balance verdict (K1 / M1 stay WARN below %d games).\n\n" % [min_games, LOW_N]
	md += "Input: `%s`\n\n" % card["input"]
	md += "Score = 100 - 2 x points outside 45-55 %% (kingdoms 2/3, matchups 1/3). Arms: %s.\n\n" % ", ".join(
			(card["arm_order"] as Array).map(func(a: String) -> String: return "`%s` %d" % [a, card["arms"][a]["score"]]))
	md += "## Checks\n\n| Id | Check | Status | Value | Target |\n|---|---|---|---|---|\n"
	for c: Dictionary in card["checks"]:
		md += "| %s | %s | **%s** | %s | %s |\n" % [c["id"], c["name"], c["status"], c["value"], c["target"]]
	md += "\n## Improve next\n\n"
	var i := 1
	for s: String in card["improve"]:
		md += "%d. %s\n" % [i, s]
		i += 1
	for arm: String in card["arm_order"]:
		var agg: Dictionary = card["arms"][arm]
		md += "\n## Arm `%s` (score %d)\n\n" % [arm, agg["score"]]
		if not (agg["applied"] as Dictionary).is_empty():
			md += "Overrides: %s\n\n" % ", ".join((agg["applied"] as Dictionary).keys().map(
					func(k: String) -> String: return "`%s` %s" % [k, agg["applied"][k]]))
		md += "| Kingdom | Wins / games | Win rate | 95 % interval |\n|---|---|---|---|\n"
		for k in KINGDOMS:
			var kd: Dictionary = agg["kingdoms"][k]
			if int(kd["games"]) == 0:
				continue
			md += "| %s | %d / %d | %d %% | %d-%d %% |\n" % [k, kd["wins"], kd["games"], roundi(float(kd["rate"]) * 100.0),
					roundi(float(kd["ci"][0]) * 100.0), roundi(float(kd["ci"][1]) * 100.0)]
		md += "\n| Matchup | Wins | Draws | Games | Median length | Score share (first) |\n|---|---|---|---|---|---|\n"
		for key: String in agg["matchups"]:
			var m: Dictionary = agg["matchups"][key]
			md += "| %s | %d-%d | %d | %d | %s | %d %% |\n" % [key, m["a_wins"], m["b_wins"], m["draws"], m["games"],
					_clock(float(m["median_length"])), roundi(float(m["a_share_mean"]) * 100.0)]
		md += "\nMedian length %s; ends %s; seat wins %s.\n" % [_clock(float(agg["median_length"])), JSON.stringify(agg["ends"]),
				JSON.stringify(agg["seat"])]
	for arm: String in card["comparisons"]:
		var cmp: Dictionary = card["comparisons"][arm]
		md += "\n## `%s` vs baseline\n\n" % arm
		md += "| Matchup | Win rate (first) base -> variant | Score share base -> variant | Toward 50 % | Significance |\n|---|---|---|---|---|\n"
		for key: String in cmp["matchups"]:
			var c: Dictionary = cmp["matchups"][key]
			md += "| %s | %d %% -> %d %% | %d %% -> %d %% (%+.1f pts) | %s | %s |\n" % [key, roundi(float(c["base_rate"]) * 100.0),
					roundi(float(c["rate"]) * 100.0), roundi(float(c["base_share"]) * 100.0), roundi(float(c["share"]) * 100.0),
					float(c["share_delta"]) * 100.0, "yes" if c["toward_50"] else "no", c["note"]]
		md += "\n| Kingdom | Win rate base -> variant | Significance |\n|---|---|---|\n"
		for k: String in cmp["kingdoms"]:
			var kc: Dictionary = cmp["kingdoms"][k]
			md += "| %s | %d %% -> %d %% | %s |\n" % [k, roundi(float(kc["base_rate"]) * 100.0), roundi(float(kc["rate"]) * 100.0), kc["note"]]
		md += "\nMedian length change %+.0f s. Score share is the continuous signal (sensitive at small N); win rate is the verdict.\n" % float(cmp["length_delta"])
	return md


static func append_history(path: String, card: Dictionary, out_dir: String) -> void:
	var text := ""
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		text = f.get_as_text()
		f.close()
	else:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		text = "# Balance Lab history\n\n| Run | Date | Result | Score | Best arm | Arms (score) | Matches | Scorecard |\n|---|---|---|---|---|---|---|---|\n"
	var arms_txt := ", ".join((card["arm_order"] as Array).map(func(a: String) -> String: return "%s %d" % [a, card["arms"][a]["score"]]))
	text += "| %s | %s | %s | %d | %s | %s | %d (%d failed) | %s |\n" % [card["run"], card["date"], card["result"], card["score"],
			card["best_arm"], arms_txt, card["matches"], card["failed"], out_dir.path_join("scorecard.md").replace("\\", "/")]
	_write(path, text)


static func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("BALANCE LAB: can't write %s" % path)
		return
	f.store_string(text)
	f.close()


static func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
