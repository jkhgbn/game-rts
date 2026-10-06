extends SceneTree
## Unit Lab (docs/plan/unit-lab.md): the REPORT. Reads the JSONL lines of a run (unit_lab_run.gd, one file per shard)
## and writes scorecard.md + scorecard.json (+ matrix.md / matrix.csv in matrix mode) to --out.
##   godot --headless --path . -s tools/unit_lab/unit_lab_report.gd --quit-after 6000 -- \
##       --in=C:/runs/unit-lab-x --spec=c1_kilnwarden --out=res://docs/balance/unit_lab/x
## Arms mode: per variant x arm: games, A wins / draws / B wins, A's score rate (win 1, draw 0.5) with a Wilson 95 %
## interval, median time to kill, units / HP left, per unit type damage dealt / taken, DPS, kills, kills and damage
## per 100 crystals, crystals traded (enemy value destroyed / own value lost), spells cast; then the spec's checks.
## Matrix mode: entry x entry score table (sorted), per-entry mean score, cost efficiency, the counter table (best
## counters / best prey) and flagged outliers (beats nearly everything / loses to nearly everything at equal cost).
## Static helpers (wilson, score_of, ...) are used by tests/test_unit_lab.gd.

const SPEC := preload("res://tools/unit_lab/unit_lab_spec.gd")
const STRONG_MEAN := 0.70     ## an entry whose mean score is >= this is flagged "too strong"
const WEAK_MEAN := 0.30
const SWEEP_SHARE := 0.85     ## ... or that beats (score > 0.5) / loses to >= this share of its opponents
const MIN_GAMES_CELL := 2

var args := {}


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--").trim_prefix("++")
		var eq := s.find("=")
		if eq < 0:
			args[s] = "1"
		else:
			args[s.substr(0, eq)] = s.substr(eq + 1)
	var lines := read_lines(String(args.get("in", "")))
	var errors: Array = []
	var spec: Dictionary = {}
	if args.has("spec"):
		var src := String(args["spec"])
		var data: Variant = SPEC.read_json(src) if src.ends_with(".json") else null
		spec = SPEC.parse_text(String(data["text"]), errors) if data is Dictionary and (data as Dictionary).has("text") \
				else SPEC.load_any(src, errors)
	var out := String(args.get("out", "user://unit_lab_report"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out) if out.begins_with("res://") \
			or out.begins_with("user://") else out)
	var title := String(args.get("title", spec.get("name", "unit lab run")))
	var rep := build(lines, spec, title)
	_write(out.path_join("scorecard.md"), String(rep["md"]))
	_write(out.path_join("scorecard.json"), JSON.stringify(rep["json"], "\t"))
	if rep.has("matrix_md"):
		_write(out.path_join("matrix.md"), String(rep["matrix_md"]))
		_write(out.path_join("matrix.csv"), String(rep["matrix_csv"]))
	print("UNIT_LAB_REPORT %d fights -> %s" % [lines.size(), out])
	quit(0)


static func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()


## Every JSON line of every *.jsonl in `dir` (or of the file `dir`).
static func read_lines(dir: String) -> Array:
	var out: Array = []
	var files: Array[String] = []
	if dir.ends_with(".jsonl"):
		files.append(dir)
	else:
		var d := DirAccess.open(dir)
		if d:
			for f in d.get_files():
				if f.ends_with(".jsonl"):
					files.append(dir.path_join(f))
	for path in files:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		while not f.eof_reached():
			var l := f.get_line().strip_edges()
			if l == "":
				continue
			var v: Variant = JSON.parse_string(l)
			if v is Dictionary:
				out.append(v)
		f.close()
	return out


# ---------------------------------------------------------------- statistics

## Wilson score interval (95 %) of a rate p over n trials -> Vector2(low, high).
static func wilson(p: float, n: int, z: float = 1.96) -> Vector2:
	if n <= 0:
		return Vector2(0.0, 1.0)
	var nf := float(n)
	var denom := 1.0 + z * z / nf
	var centre := (p + z * z / (2.0 * nf)) / denom
	var half := z * sqrt(p * (1.0 - p) / nf + z * z / (4.0 * nf * nf)) / denom
	return Vector2(maxf(0.0, centre - half), minf(1.0, centre + half))


## Side A's score in one fight: 1 win, 0.5 draw, 0 loss.
static func score_of(r: Dictionary, side: String = "a") -> float:
	var w := String(r.get("winner", "draw"))
	if w == "draw":
		return 0.5
	return 1.0 if w == side else 0.0


static func median(values: Array) -> float:
	if values.is_empty():
		return NAN
	var v := values.duplicate()
	v.sort()
	var n := v.size()
	return float(v[n / 2]) if n % 2 == 1 else (float(v[n / 2 - 1]) + float(v[n / 2])) * 0.5


## Arm stats over fights (all of one variant + arm): {n, a_wins, draws, b_wins, score, lo, hi, ttk, ...}.
static func arm_stats(fights: Array) -> Dictionary:
	var n := fights.size()
	var aw := 0
	var bw := 0
	var dr := 0
	var sc := 0.0
	var ttk: Array = []
	var times: Array = []
	var alive := [0.0, 0.0]
	var hp_frac := [0.0, 0.0]
	var traded := [0.0, 0.0]   # value destroyed (enemy cost - enemy value left)
	var lost := [0.0, 0.0]
	var types: Array = [{}, {}]
	var casts: Array = [{}, {}]
	var first: Array = [{}, {}]
	for r: Dictionary in fights:
		var w := String(r.get("winner", "draw"))
		if w == "a":
			aw += 1
		elif w == "b":
			bw += 1
		else:
			dr += 1
		sc += score_of(r)
		times.append(float(r.get("time", 0.0)))
		if String(r.get("reason", "")) == "kill":
			ttk.append(float(r.get("time", 0.0)))
		for s in 2:
			var sd: Dictionary = r.get(["a", "b"][s], {})
			var od: Dictionary = r.get(["b", "a"][s], {})
			alive[s] += float(sd.get("alive", 0))
			hp_frac[s] += float(sd.get("hp_left", 0.0)) / maxf(1.0, float(sd.get("hp_max", 1.0)))
			traded[s] += float(od.get("cost", 0)) - float(od.get("value_left", 0.0))
			lost[s] += float(sd.get("cost", 0)) - float(sd.get("value_left", 0.0))
			var tt: Dictionary = sd.get("types", {})
			for id: String in tt:
				var row: Dictionary = tt[id]
				var acc: Dictionary = types[s].get(id, {"n": 0.0, "alive": 0.0, "dealt": 0.0, "taken": 0.0, "kills": 0.0,
						"alive_time": 0.0, "cost": 0.0, "summon": bool(row.get("summon", false))})
				for k: String in ["n", "alive", "dealt", "taken", "kills", "alive_time", "cost"]:
					acc[k] = float(acc[k]) + float(row.get(k, 0.0))
				types[s][id] = acc
			var cc: Dictionary = sd.get("casts", {})
			for sp: String in cc:
				casts[s][sp] = float(casts[s].get(sp, 0.0)) + float(cc[sp])
			var fc: Dictionary = sd.get("first_cast", {})
			for sp: String in fc:
				var arr: Array = first[s].get(sp, [])
				arr.append(float(fc[sp]))
				first[s][sp] = arr
	var p := sc / maxf(1.0, float(n))
	var ci := wilson(p, n)
	var nn := maxf(1.0, float(n))
	var out := {"n": n, "a_wins": aw, "draws": dr, "b_wins": bw, "score": p, "lo": ci.x, "hi": ci.y,
			"ttk_median": median(ttk), "time_median": median(times),
			"alive": [alive[0] / nn, alive[1] / nn], "hp_left_pct": [hp_frac[0] / nn, hp_frac[1] / nn],
			"trade": [traded[0] / maxf(1.0, lost[0]), traded[1] / maxf(1.0, lost[1])],
			"types": [{}, {}], "casts": [{}, {}], "first_cast": [{}, {}]}
	for s in 2:
		for id: String in types[s]:
			var a: Dictionary = types[s][id]
			var cost := float(a["cost"])
			out["types"][s][id] = {"per_fight": a["n"] / nn, "survival": a["alive"] / maxf(1.0, a["n"]),
					"dealt": a["dealt"] / nn, "taken": a["taken"] / nn, "dps": a["dealt"] / maxf(0.1, a["alive_time"]),
					"kills": a["kills"] / nn, "kills_per_100": a["kills"] * 100.0 / cost if cost > 0.0 else NAN,
					"dealt_per_100": a["dealt"] * 100.0 / cost if cost > 0.0 else NAN, "summon": a["summon"]}
		for sp: String in casts[s]:
			out["casts"][s][sp] = float(casts[s][sp]) / nn
		for sp: String in first[s]:
			out["first_cast"][s][sp] = {"median": median(first[s][sp]), "fights": (first[s][sp] as Array).size()}
	return out


# ---------------------------------------------------------------- report

static func build(lines: Array, spec: Dictionary, title: String) -> Dictionary:
	var is_matrix := false
	for r: Dictionary in lines:
		if r.has("entry_a"):
			is_matrix = true
			break
	if is_matrix:
		return build_matrix(lines, spec, title)
	return build_arms(lines, spec, title)


static func _group(lines: Array) -> Dictionary:
	var g := {}   # variant -> arm -> [fights]
	for r: Dictionary in lines:
		var v := String(r.get("variant", "baseline"))
		var a := String(r.get("arm", "main"))
		if not g.has(v):
			g[v] = {}
		if not g[v].has(a):
			g[v][a] = []
		g[v][a].append(r)
	return g


static func _pct(x: float) -> String:
	return "-" if is_nan(x) else "%d %%" % roundi(x * 100.0)


static func _f(x: float, d: int = 1) -> String:
	if is_nan(x):
		return "-"
	return ("%." + str(d) + "f") % x


static func build_arms(lines: Array, spec: Dictionary, title: String) -> Dictionary:
	var g := _group(lines)
	var md := PackedStringArray()
	md.append("# Unit Lab: %s" % title)
	md.append("")
	md.append("%d fights. Score = side A's rate (win 1, draw 0.5) with a Wilson 95 %% interval. Teams alternate per seed " \
			% lines.size() + "(odd seeds: A = player team, even: A = enemy team). Generated by tools/unit_lab/unit_lab_report.gd.")
	if String(spec.get("notes", "")) != "":
		md.append("")
		md.append("> " + String(spec["notes"]))
	var json := {"title": title, "fights": lines.size(), "variants": {}}
	var stats := {}
	for v: String in g:
		stats[v] = {}
		md.append("")
		md.append("## Variant `%s`" % v)
		md.append("")
		md.append("| Arm | Side A | Side B | Games | A / draw / B | A score | 95 % | TTK median | A alive | B alive | A trade | B trade |")
		md.append("|---|---|---|---|---|---|---|---|---|---|---|---|")
		for arm: String in g[v]:
			var fights: Array = g[v][arm]
			var st := arm_stats(fights)
			stats[v][arm] = st
			var f0: Dictionary = fights[0]
			md.append("| %s | %s (%d c) | %s (%d c) | %d | %d / %d / %d | %s | %s-%s | %s s | %s | %s | %s | %s |" % [arm,
					(f0["a"] as Dictionary).get("label", ""), int((f0["a"] as Dictionary).get("cost", 0)),
					(f0["b"] as Dictionary).get("label", ""), int((f0["b"] as Dictionary).get("cost", 0)),
					st["n"], st["a_wins"], st["draws"], st["b_wins"], _pct(st["score"]), _pct(st["lo"]), _pct(st["hi"]),
					_f(st["ttk_median"]), _f(st["alive"][0]), _f(st["alive"][1]), _f(st["trade"][0], 2),
					_f(st["trade"][1], 2)])
		for arm: String in g[v]:
			var st: Dictionary = stats[v][arm]
			md.append("")
			md.append("### %s / %s: per unit type (averages per fight)" % [v, arm])
			md.append("")
			md.append("| Side | Unit | Count | Survival | Dealt | Taken | DPS | Kills | Kills / 100 c | Dmg / 100 c |")
			md.append("|---|---|---|---|---|---|---|---|---|---|")
			for s in 2:
				for id: String in st["types"][s]:
					var t: Dictionary = st["types"][s][id]
					md.append("| %s | %s%s | %s | %s | %s | %s | %s | %s | %s | %s |" % [["A", "B"][s], id,
							" (summon)" if bool(t["summon"]) else "", _f(t["per_fight"]), _pct(t["survival"]),
							_f(t["dealt"], 0), _f(t["taken"], 0), _f(t["dps"]), _f(t["kills"], 2),
							_f(t["kills_per_100"], 2), _f(t["dealt_per_100"], 0)])
			var spells := PackedStringArray()
			for s in 2:
				for sp: String in st["casts"][s]:
					var fc: Dictionary = st["first_cast"][s].get(sp, {})
					spells.append("%s %s x%s/fight (first at %s s median, in %d fights)" % [["A", "B"][s], sp,
							_f(st["casts"][s][sp], 2), _f(float(fc.get("median", NAN))), int(fc.get("fights", 0))])
			if not spells.is_empty():
				md.append("")
				md.append("Spells: " + "; ".join(spells) + ".")
	json["stats"] = stats
	var checks := eval_checks(spec.get("checks", []), stats, g)
	json["checks"] = checks
	if not checks.is_empty():
		md.append("")
		md.append("## Checks")
		md.append("")
		md.append("| Check | Result | Detail |")
		md.append("|---|---|---|")
		for c: Dictionary in checks:
			md.append("| %s | **%s** | %s |" % [c["label"], c["result"], c["detail"]])
	if g.size() > 1 and g.has("baseline"):
		md.append("")
		md.append("## Variants vs baseline (A score)")
		md.append("")
		md.append("| Variant | Arm | Baseline | Variant | Change |")
		md.append("|---|---|---|---|---|")
		for v: String in g:
			if v == "baseline":
				continue
			for arm: String in stats[v]:
				if not stats["baseline"].has(arm):
					continue
				var b0 := float(stats["baseline"][arm]["score"])
				var b1 := float(stats[v][arm]["score"])
				md.append("| %s | %s | %s | %s | %+d points |" % [v, arm, _pct(b0), _pct(b1), roundi((b1 - b0) * 100.0)])
	return {"md": "\n".join(md) + "\n", "json": json}


## The spec's checks (caster-units.md 7.2 bands) on the baseline variant:
##   {"type": "wr_delta", "arm": "caster", "control": "control", "min": 20, "max": 60}   score points (A side)
##   {"type": "spell_rate", "arm": "x", "side": "a", "spell": "snagroot", "min": 0.8}     share of fights with a cast
##   {"type": "first_spell", "arm": "x", "first": ["a", "mana_scald"], "then": ["b", "snagroot"], "min": 0.6}
##   {"type": "alive_avg", "arm": "x", "side": "a", "unit": "shade", "min": 8} / "max"
##   {"type": "survival", "arm": "x", "side": "a", "unit": "kilnwarden", "min": 0.6}      share of fights it lived
static func eval_checks(checks: Array, stats: Dictionary, g: Dictionary) -> Array:
	var out: Array = []
	var v: String = "baseline" if stats.has("baseline") else (String(stats.keys()[0]) if not stats.is_empty() else "")
	if v == "":
		return out
	for c: Dictionary in checks:
		var t := String(c.get("type", ""))
		var label := String(c.get("label", t))
		var arm := String(c.get("arm", "main"))
		if not stats[v].has(arm):
			out.append({"label": label, "result": "SKIP", "detail": "arm %s not run" % arm})
			continue
		var st: Dictionary = stats[v][arm]
		var fights: Array = g[v][arm]
		match t:
			"wr_delta":
				var ctl := String(c.get("control", "control"))
				if not stats[v].has(ctl):
					out.append({"label": label, "result": "SKIP", "detail": "control %s not run" % ctl})
					continue
				var d := (float(st["score"]) - float(stats[v][ctl]["score"])) * 100.0
				var lo := float(c.get("min", -1000.0))
				var hi := float(c.get("max", 1000.0))
				out.append({"label": label, "result": "PASS" if d >= lo and d <= hi else "FAIL",
						"detail": "%s %s vs %s %s = %+d points (band %s..%s)" % [arm, _pct(st["score"]), ctl,
						_pct(stats[v][ctl]["score"]), roundi(d), _f(lo, 0), _f(hi, 0)]})
			"spell_rate":
				var side := String(c.get("side", "a"))
				var sp := String(c.get("spell", ""))
				var k := 0
				for r: Dictionary in fights:
					if int(((r.get(side, {}) as Dictionary).get("casts", {}) as Dictionary).get(sp, 0)) > 0:
						k += 1
				var rate := float(k) / maxf(1.0, float(fights.size()))
				out.append({"label": label, "result": "PASS" if rate >= float(c.get("min", 0.0)) else "FAIL",
						"detail": "%s cast by %s in %d / %d fights (min %s)" % [sp, side.to_upper(), k, fights.size(),
						_pct(float(c.get("min", 0.0)))]})
			"first_spell":
				var fa: Array = c.get("first", ["a", ""])
				var fb: Array = c.get("then", ["b", ""])
				var k := 0
				for r: Dictionary in fights:
					var ta := float(((r.get(fa[0], {}) as Dictionary).get("first_cast", {}) as Dictionary).get(fa[1], INF))
					var tb := float(((r.get(fb[0], {}) as Dictionary).get("first_cast", {}) as Dictionary).get(fb[1], INF))
					if ta < INF and ta <= tb:
						k += 1
				var rate := float(k) / maxf(1.0, float(fights.size()))
				out.append({"label": label, "result": "PASS" if rate >= float(c.get("min", 0.0)) else "FAIL",
						"detail": "%s %s before %s %s in %d / %d fights" % [String(fa[0]).to_upper(), fa[1],
						String(fb[0]).to_upper(), fb[1], k, fights.size()]})
			"alive_avg", "survival":
				var side := String(c.get("side", "a"))
				var unit := String(c.get("unit", ""))
				var s := 0 if side == "a" else 1
				var row: Dictionary = st["types"][s].get(unit, {})
				var val := float(row.get("per_fight", 0.0)) * float(row.get("survival", 0.0)) if t == "alive_avg" \
						else float(row.get("survival", 0.0))
				var ok := val >= float(c.get("min", -INF)) and val <= float(c.get("max", INF))
				out.append({"label": label, "result": "PASS" if ok else "FAIL",
						"detail": "%s %s %s = %s (min %s, max %s)" % [side.to_upper(), unit,
						"alive per fight" if t == "alive_avg" else "survival", _f(val, 2), str(c.get("min", "-")),
						str(c.get("max", "-"))]})
			_:
				out.append({"label": label, "result": "SKIP", "detail": "unknown check type %s" % t})
	return out


# ---------------------------------------------------------------- matrix

## {entries: [..], cells: {"a|b": {n, score (a's)}}, mean: {e: x}, ...}
static func matrix_table(lines: Array, variant: String = "") -> Dictionary:
	var cells := {}
	var entries: Array[String] = []
	var kingdom := {}
	var trade := {}   # entry -> [destroyed, lost]
	for r: Dictionary in lines:
		if variant != "" and String(r.get("variant", "baseline")) != variant:
			continue
		var ea := String(r.get("entry_a", ""))
		var eb := String(r.get("entry_b", ""))
		if ea == "" or eb == "":
			continue
		for e: String in [ea, eb]:
			if not entries.has(e):
				entries.append(e)
		var sa := score_of(r, "a")
		for pair: Array in [[ea, eb, sa, "a", "b"], [eb, ea, 1.0 - sa, "b", "a"]]:
			if pair[0] == pair[1] and pair[3] == "b":
				continue
			var key := "%s|%s" % [pair[0], pair[1]]
			var c: Dictionary = cells.get(key, {"n": 0, "sum": 0.0})
			c["n"] += 1
			c["sum"] += float(pair[2])
			cells[key] = c
			var mine: Dictionary = r.get(pair[3], {})
			var theirs: Dictionary = r.get(pair[4], {})
			var t: Array = trade.get(pair[0], [0.0, 0.0])
			t[0] += float(theirs.get("cost", 0)) - float(theirs.get("value_left", 0.0))
			t[1] += float(mine.get("cost", 0)) - float(mine.get("value_left", 0.0))
			trade[pair[0]] = t
	var mean := {}
	var wins := {}
	var losses := {}
	var games := {}
	for e in entries:
		var sum := 0.0
		var k := 0
		var w := 0
		var l := 0
		var g := 0
		for o in entries:
			if o == e:
				continue
			var c: Dictionary = cells.get("%s|%s" % [e, o], {})
			if c.is_empty():
				continue
			var s := float(c["sum"]) / float(c["n"])
			sum += s
			k += 1
			g += int(c["n"])
			if s > 0.5:
				w += 1
			elif s < 0.5:
				l += 1
		mean[e] = sum / float(k) if k > 0 else NAN
		wins[e] = [w, k]
		losses[e] = [l, k]
		games[e] = g
		var parts := e.split("+")
		var tt := UnitType.find(parts[parts.size() - 1])
		kingdom[e] = String(tt.faction) if tt else ""
	var sorted := entries.duplicate()
	sorted.sort_custom(func(x: String, y: String) -> bool: return float(mean[x]) > float(mean[y]))
	var tr := {}
	for e: String in trade:
		tr[e] = float(trade[e][0]) / maxf(1.0, float(trade[e][1]))
	return {"entries": sorted, "cells": cells, "mean": mean, "wins": wins, "losses": losses, "games": games,
			"kingdom": kingdom, "trade": tr}


static func cell_score(m: Dictionary, a: String, b: String) -> float:
	var c: Dictionary = m["cells"].get("%s|%s" % [a, b], {})
	return NAN if c.is_empty() else float(c["sum"]) / float(c["n"])


## Outliers: [{entry, mean, verdict ("too strong" / "too weak"), why}], strongest deviation first.
static func outliers(m: Dictionary) -> Array:
	var out: Array = []
	for e: String in m["entries"]:
		var mean := float(m["mean"][e])
		if is_nan(mean):
			continue
		var w: Array = m["wins"][e]
		var l: Array = m["losses"][e]
		var why: Array[String] = []
		var verdict := ""
		if mean >= STRONG_MEAN:
			why.append("mean score %s >= %s" % [_pct(mean), _pct(STRONG_MEAN)])
			verdict = "too strong"
		if int(w[1]) > 0 and float(w[0]) / float(w[1]) >= SWEEP_SHARE:
			why.append("beats %d / %d" % [w[0], w[1]])
			verdict = "too strong"
		if mean <= WEAK_MEAN:
			why.append("mean score %s <= %s" % [_pct(mean), _pct(WEAK_MEAN)])
			verdict = "too weak"
		if int(l[1]) > 0 and float(l[0]) / float(l[1]) >= SWEEP_SHARE:
			why.append("loses to %d / %d" % [l[0], l[1]])
			verdict = "too weak"
		out.append({"entry": e, "mean": mean, "verdict": verdict, "why": ", ".join(why), "dev": absf(mean - 0.5),
				"kingdom": m["kingdom"].get(e, ""), "trade": m["trade"].get(e, NAN), "wins": w, "losses": l})
	out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["dev"]) > float(y["dev"]))
	return out


static func build_matrix(lines: Array, spec: Dictionary, title: String) -> Dictionary:
	var variants: Array[String] = []
	for r: Dictionary in lines:
		var v := String(r.get("variant", "baseline"))
		if not variants.has(v):
			variants.append(v)
	var md := PackedStringArray()
	var mmd := PackedStringArray()
	var csv := PackedStringArray()
	var json := {"title": title, "fights": lines.size(), "variants": {}}
	var budget := 0
	var basis := "cost"
	var pop_budget := 0
	for r: Dictionary in lines:
		budget = int(r.get("budget", 0))
		basis = String(r.get("basis", "cost"))
		pop_budget = int(r.get("pop_budget", 0))
		break
	md.append("# Unit Lab matrix: %s" % title)
	md.append("")
	md.append(("%d fights, %s, score = the row's rate (win 1, draw 0.5). " \
			+ "Outlier rule: mean score >= %s or beats >= %s of its opponents = too strong; mean <= %s or loses to >= %s = " \
			+ "too weak. Generated by tools/unit_lab/unit_lab_report.gd.") % [lines.size(),
			basis_text(basis, budget, pop_budget), _pct(STRONG_MEAN), _pct(SWEEP_SHARE), _pct(WEAK_MEAN), _pct(SWEEP_SHARE)])
	for v in variants:
		var m := matrix_table(lines, v)
		var outs := outliers(m)
		json["variants"][v] = {"mean": m["mean"], "trade": m["trade"], "outliers": outs, "games": m["games"]}
		md.append("")
		md.append("## Variant `%s`: ranking" % v)
		md.append("")
		md.append("| # | Entry | Kingdom | Mean score | 95 % | Beats | Loses to | Crystal trade | Verdict |")
		md.append("|---|---|---|---|---|---|---|---|---|")
		var i := 0
		for e: String in m["entries"]:
			i += 1
			var mean := float(m["mean"][e])
			var ci := wilson(mean, int(m["games"][e]))
			var o: Dictionary = {}
			for x: Dictionary in outs:
				if x["entry"] == e:
					o = x
			md.append("| %d | %s | %s | %s | %s-%s | %d / %d | %d / %d | %s | %s |" % [i, e, m["kingdom"][e], _pct(mean),
					_pct(ci.x), _pct(ci.y), m["wins"][e][0], m["wins"][e][1], m["losses"][e][0], m["losses"][e][1],
					_f(float(m["trade"].get(e, NAN)), 2), o.get("verdict", "")])
		md.append("")
		md.append("### Top 10 outliers (%s)" % v)
		md.append("")
		md.append("| # | Entry | Role | Mean | Verdict | Why |")
		md.append("|---|---|---|---|---|---|")
		for k in mini(10, outs.size()):
			var o: Dictionary = outs[k]
			md.append("| %d | %s | %s | %s | %s | %s |" % [k + 1, o["entry"], role_of(String(o["entry"])), _pct(o["mean"]),
					o["verdict"] if o["verdict"] != "" else ("strong side" if float(o["mean"]) > 0.5 else "weak side"),
					o["why"] if o["why"] != "" else "largest deviation from 50 %"])
		md.append("")
		md.append("### Counter table (%s)" % v)
		md.append("")
		md.append("| Entry | Best counters (its score) | Best prey (its score) |")
		md.append("|---|---|---|")
		for e: String in m["entries"]:
			var opp: Array = []
			for o: String in m["entries"]:
				if o != e and not is_nan(cell_score(m, e, o)):
					opp.append([cell_score(m, e, o), o])
			opp.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
			var counters: Array[String] = []
			var prey: Array[String] = []
			for k in opp.size():
				if counters.size() < 3 and float(opp[k][0]) < 0.5:
					counters.append("%s %s" % [opp[k][1], _pct(opp[k][0])])
				var q: Array = opp[opp.size() - 1 - k]
				if prey.size() < 3 and float(q[0]) > 0.5:
					prey.append("%s %s" % [q[1], _pct(q[0])])
			md.append("| %s | %s | %s |" % [e, ", ".join(counters) if not counters.is_empty() else "-",
					", ".join(prey) if not prey.is_empty() else "-"])
		# full table
		mmd.append("# Unit Lab matrix table: %s (variant `%s`)" % [title, v])
		mmd.append("")
		mmd.append("Cell = the ROW entry's score (%%) against the COLUMN entry at equal cost; rows / columns sorted by mean score.")
		mmd.append("")
		var es: Array = m["entries"]
		var head := "| Row \\ Col | " + " | ".join(PackedStringArray(es.map(func(x: String) -> String: return _short(x)))) + " |"
		mmd.append(head)
		mmd.append("|---|" + "---|".repeat(es.size()))
		csv.append("variant,row," + ",".join(es))
		for e: String in es:
			var cells: Array[String] = []
			var ccells: Array[String] = []
			for o: String in es:
				var sv := cell_score(m, e, o)
				cells.append("" if e == o or is_nan(sv) else str(roundi(sv * 100.0)))
				ccells.append("" if is_nan(sv) else str(snappedf(sv, 0.001)))
			mmd.append("| %s | %s |" % [_short(e), " | ".join(cells)])
			csv.append("%s,%s,%s" % [v, e, ",".join(ccells)])
		mmd.append("")
	return {"md": "\n".join(md) + "\n", "json": json, "matrix_md": "\n".join(mmd) + "\n",
			"matrix_csv": "\n".join(csv) + "\n"}


## How the matrix armies were sized, for the scorecard header.
static func basis_text(basis: String, budget: int, pop_budget: int) -> String:
	match basis:
		"pop":
			return "armies of ~%d pop each side (equal-pop normaliser)" % pop_budget
		"both":
			return "armies sized by both budgets, ~%d crystals and ~%d pop each side (whichever binds first)" % [budget,
					pop_budget]
	return "armies of ~%d crystals each side (cost-equal normaliser)" % budget


## "melee" / "ranged" / "support" / "flyer?" / "caster mix" from the entry's data (a hint for reading the matrix:
## support units are judged alone here, which is not how they are used).
static func role_of(e: String) -> String:
	if e.contains("+"):
		return "caster mix"
	var t := UnitType.find(e)
	if t == null:
		return "?"
	if t.support_kind != &"":
		return "support (%s)" % t.support_kind
	var r := "ranged" if t.attack_range > 3.0 else "melee"
	if HelperAbilities.FLYER_IDS.has(t.id):
		r += ", flyer"
	return r


## Short column names for the wide table ("kilnwarden+flame_guard" -> "kilnwarden+").
static func _short(e: String) -> String:
	if e.contains("+"):
		return e.split("+")[0] + "+"
	return e
