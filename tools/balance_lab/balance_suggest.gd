extends SceneTree
## Balance Lab "suggest" step (docs/plan/balance-lab.md): ranks candidate knob changes (stat or cost) that bring each
## kingdom toward 45-55 % win rate, from
##   1. the Data Lab balance table (B1: EHP / DPS per 100 crystals per barracks slot, same formulas), and
##   2. the kingdoms' win rates in a Bot Lab / Balance Lab results.jsonl (baseline arm only when there are arms).
## Writes suggest.md + suggest.json and one ready-to-run variant JSON per top knob (variants/<name>.json) for
## tools/balance_lab/run_balance.ps1 -Variants ...
##   godot --headless --path . -s res://tools/balance_lab/balance_suggest.gd --quit-after 600 -- \
##       [--results=<results.jsonl>] [--out=<dir>] [--top=3] [--arm=baseline]
## Default --results: the results.jsonl with the most matches under ..\four-wizards-lab-runs\ (ties: the newest).
## Default --out: res://docs/balance/lab/suggest_<date_time>/.
## Model (a prior, not a verdict; the A/B run measures the real effect):
##   power per cost = sqrt(EHP/100 x DPS/100) (Lanchester square law for a fixed budget);
##   a knob changes a unit's power by dP; expected kingdom win-rate shift = WR_PER_POWER x dP (rough prior);
##   rank = shape fix (log distance to the combat peers' median removed) + band gain (points moved into 45-55 %,
##   weighted by the win-rate sample size). Support units (support_kind set) are listed but not compared on DPS.
## Untyped access to the data resources so it runs on any commit.

const UNITS_DIR := "res://data/units/"
const BUILDINGS_DIR := "res://data/buildings/"
const KINGDOMS: Array[String] = ["fire", "shadow", "ice", "nature"]
const ROWS: Array[String] = ["Z", "X", "C", "V", "B"]
const STEP_MAX := 0.25        ## one knob moves a stat by at most 25 %
const SHAPE_TOL := 1.25       ## a metric within x1.25 of the peers' median is not an outlier
const WR_PER_POWER := 0.3     ## prior: +10 % power of one barracks unit ~ +3 win-rate points for its kingdom
const FULL_N := 20            ## win-rate sample (non-mirror games) that counts fully
const LEAD_FACTOR := 1.6      ## Data Lab B1 (Rules.BALANCE_FACTOR): per-100 ratio vs the whole row
const RAW_FACTOR := 2.5       ## Data Lab F6-like: raw max_hp / damage vs the whole row

var args := {}


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var res := run(args)
	quit(0 if not res.is_empty() else 1)


static func run(opts: Dictionary) -> Dictionary:
	var results_path := String(opts.get("results", ""))
	if results_path == "":
		results_path = find_results()
	var wr := win_rates(results_path, String(opts.get("arm", "baseline")))
	var table := unit_table()
	var knobs := candidates(table, wr)
	var top := int(String(opts.get("top", "3")))
	var now := Time.get_datetime_dict_from_system()
	var stamp := "%04d-%02d-%02d_%02d%02d" % [now.year, now.month, now.day, now.hour, now.minute]
	var out_dir := String(opts.get("out", "res://docs/balance/lab/suggest_" + stamp))
	var picked: Array = []
	var seen := {}
	for k: Dictionary in knobs:
		if picked.size() >= top:
			break
		if seen.has(k["unit"]) or float(k["score"]) <= 0.0 or String(k["verdict"]).begins_with("away"):
			continue
		seen[k["unit"]] = true
		picked.append(k)
	var out := {"date": stamp, "results": results_path, "win_rates": wr, "table": table, "knobs": knobs, "picked": picked}
	if out_dir != "":
		var vdir := ProjectSettings.globalize_path(out_dir.path_join("variants"))
		DirAccess.make_dir_recursive_absolute(vdir)
		var old := DirAccess.open(vdir)
		if old:   # a rerun into the same folder: drop the previous run's suggested variants
			for file in old.get_files():
				if file.ends_with(".json"):
					old.remove(file)
		for k: Dictionary in picked:
			var v := {"name": k["variant_name"], "notes": k["why"], "units": {k["unit"]: k["overrides"]}}
			_write(out_dir.path_join("variants/%s.json" % k["variant_name"]), JSON.stringify(v, "\t"))
			k["variant_file"] = ProjectSettings.globalize_path(out_dir.path_join("variants/%s.json" % k["variant_name"]))
		_write(out_dir.path_join("suggest.md"), to_markdown(out))
		_write(out_dir.path_join("suggest.json"), JSON.stringify(out, "\t"))
	print("BALANCE SUGGEST: %d candidate knobs, top %d written -> %s" % [knobs.size(), picked.size(), out_dir.path_join("suggest.md")])
	for k: Dictionary in picked:
		print("  %s: %s (score %.1f, %s)" % [k["unit"], k["knob"], k["score"], k["verdict"]])
	return out


## The results.jsonl with the most rows under ../four-wizards-lab-runs/ (ties: newest). "" if none.
static func find_results() -> String:
	var runs := ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir().path_join("four-wizards-lab-runs")
	var best := ""
	var best_rows := -1
	var best_time := 0
	var d := DirAccess.open(runs)
	if d == null:
		return ""
	for sub in d.get_directories():
		var p := runs.path_join(sub).path_join("results.jsonl")
		if not FileAccess.file_exists(p):
			continue
		var f := FileAccess.open(p, FileAccess.READ)
		var n := 0
		while f and not f.eof_reached():
			if f.get_line().begins_with("{"):
				n += 1
		var t := FileAccess.get_modified_time(p)
		if n > best_rows or (n == best_rows and t > best_time):
			best = p
			best_rows = n
			best_time = t
	return best


## Non-mirror win rate per kingdom: {kingdom: {wins, games, rate}}. Rows with an "arm" key count only for `arm`.
static func win_rates(path: String, arm: String) -> Dictionary:
	var out := {}
	for k in KINGDOMS:
		out[k] = {"wins": 0, "games": 0, "rate": -1.0}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ) if path != "" else null
	if f == null:
		return out
	while not f.eof_reached():
		var line := f.get_line()
		if not line.begins_with("{"):
			continue
		var r: Variant = JSON.parse_string(line)
		if not (r is Dictionary) or (r as Dictionary).has("error") or not (r as Dictionary).has("winner"):
			continue
		if (r as Dictionary).has("arm") and String(r["arm"]) != arm:
			continue
		var p := String(r.get("player", ""))
		var e := String(r.get("enemy", ""))
		if p == e or not out.has(p) or not out.has(e):
			continue
		for k: String in [p, e]:
			out[k]["games"] += 1
			if String(r["winner"]) == k:
				out[k]["wins"] += 1
	for k: String in out:
		if int(out[k]["games"]) > 0:
			out[k]["rate"] = float(out[k]["wins"]) / float(out[k]["games"])
	return out


## Barracks units per slot (Data Lab B1 rows Z X C V B): id, kingdom, row, cost, max_hp, armor, attack_damage,
## attack_cooldown, support, ehp100, dps100, power, and the ratios to the combat peers' medians of the same row.
static func unit_table() -> Array:
	var rows: Array = []
	var d := DirAccess.open(BUILDINGS_DIR)
	if d == null:
		return rows
	var files := Array(d.get_files())
	files.sort()
	for file: String in files:
		if not file.ends_with(".tres"):
			continue
		var b: Resource = load(BUILDINGS_DIR + file)
		if b == null or String(b.get(&"kind")) != "barracks":
			continue
		if b.has_method(&"resolve_trains"):
			b.call(&"resolve_trains")
		var trains: Variant = b.get(&"trains")
		if not (trains is Array):
			continue
		for i in (trains as Array).size():
			var u: Resource = trains[i]
			if u == null or i >= ROWS.size() or int(u.get(&"cost")) <= 0 or bool(u.get(&"is_worker")):
				continue
			if &"is_caravan" in u and bool(u.get(&"is_caravan")):
				continue
			var cost := float(u.get(&"cost"))
			var armor := float(u.get(&"armor")) if &"armor" in u else 0.0
			var ehp := float(u.get(&"max_hp")) * (1.0 + maxf(0.0, armor) / 100.0)
			var dps := float(u.get(&"attack_damage")) / maxf(0.1, float(u.get(&"attack_cooldown")))
			var support := String(u.get(&"support_kind")) if &"support_kind" in u else ""
			rows.append({"unit": String(u.get(&"id")), "name": String(u.get(&"display_name")), "kingdom": String(b.get(&"faction")),
					"row": ROWS[i], "cost": int(cost), "max_hp": float(u.get(&"max_hp")), "armor": armor,
					"attack_damage": float(u.get(&"attack_damage")), "attack_cooldown": float(u.get(&"attack_cooldown")),
					"support": support, "ehp100": ehp / cost * 100.0, "dps100": dps / cost * 100.0,
					"power": sqrt(ehp / cost * 100.0 * dps / cost * 100.0)})
	# Ratios to the row's COMBAT peers (support units excluded when at least 2 combat units remain).
	for r: Dictionary in rows:
		# Combat units vs combat units; support units vs the other support units of the slot (their worth is the
		# support, which these stats don't measure).
		var is_support: bool = r["support"] != ""
		var peers: Array = rows.filter(func(o: Dictionary) -> bool: return o["row"] == r["row"] and (o["support"] != "") == is_support)
		if peers.size() < 2:
			peers = rows.filter(func(o: Dictionary) -> bool: return o["row"] == r["row"])
		var all_row: Array = rows.filter(func(o: Dictionary) -> bool: return o["row"] == r["row"])
		r["peers"] = peers.map(func(o: Dictionary) -> String: return String(o["unit"]))
		r["ehp_ratio"] = float(r["ehp100"]) / maxf(0.001, _median(peers.map(func(o: Dictionary) -> float: return o["ehp100"])))
		r["dps_ratio"] = float(r["dps100"]) / maxf(0.001, _median(peers.map(func(o: Dictionary) -> float: return o["dps100"])))
		r["power_ratio"] = float(r["power"]) / maxf(0.001, _median(peers.map(func(o: Dictionary) -> float: return o["power"])))
		r["dps_ratio_all"] = float(r["dps100"]) / maxf(0.001, _median(all_row.map(func(o: Dictionary) -> float: return o["dps100"])))
		r["ehp_ratio_all"] = float(r["ehp100"]) / maxf(0.001, _median(all_row.map(func(o: Dictionary) -> float: return o["ehp100"])))
		r["power_ratio_all"] = float(r["power"]) / maxf(0.001, _median(all_row.map(func(o: Dictionary) -> float: return o["power"])))
		# Raw stats vs the whole row (the Data Lab F6 view, no cost): max_hp and attack_damage.
		r["hp_raw_all"] = float(r["max_hp"]) / maxf(0.001, _median(all_row.map(func(o: Dictionary) -> float: return o["max_hp"])))
		r["dmg_raw_all"] = float(r["attack_damage"]) / maxf(0.001, _median(all_row.map(func(o: Dictionary) -> float: return o["attack_damage"])))
		var why: Array[String] = []
		for pair: Array in [["EHP/100", r["ehp_ratio_all"], LEAD_FACTOR], ["DPS/100", r["dps_ratio_all"], LEAD_FACTOR],
				["raw max_hp", r["hp_raw_all"], RAW_FACTOR], ["raw damage", r["dmg_raw_all"], RAW_FACTOR]]:
			var x := float(pair[1])
			if x > float(pair[2]) or x < 1.0 / float(pair[2]):
				why.append("%s x%.2f of the row" % [pair[0], x])
		r["lead"] = not why.is_empty()
		r["lead_why"] = ", ".join(why)
	return rows


## Candidate knobs for every outlier, ranked (best first). A knob = multipliers on max_hp (h), attack_damage (d) and
## cost (c): EHP/100 x h/c, DPS/100 x d/c, power x sqrt(h d)/c. Two bases: the row's combat peers (always) and, for a
## Data Lab lead (whole-row ratio beyond x1.6), the whole row as the Data Lab B1 table sees it.
static func candidates(table: Array, wr: Dictionary) -> Array:
	var out: Array = []
	var seen := {}
	for r: Dictionary in table:
		var bases: Array = [["peers", float(r["ehp_ratio"]), float(r["dps_ratio"]), float(r["power_ratio"])]]
		if bool(r["lead"]):
			bases.append(["row", float(r["ehp_ratio_all"]), float(r["dps_ratio_all"]), float(r["power_ratio_all"])])
		for basis: Array in bases:
			for o: Dictionary in _options(r, basis[1], basis[2], basis[3], String(basis[0])):
				var key := "%s|%s" % [r["unit"], JSON.stringify(o["mult"])]
				if seen.has(key):
					continue
				seen[key] = true
				out.append(_knob(r, o, basis, wr))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	return out


## The knob options for one unit on one basis (ratios er / dr / pr): [{mult: {h, d, c}, what, kind}].
static func _options(r: Dictionary, er: float, dr: float, pr: float, basis: String) -> Array:
	var opts: Array = []
	var support := String(r["support"]) != ""
	var tol := log(SHAPE_TOL)
	if absf(log(er)) > tol:
		var f := _step(er)
		opts.append({"mult": {"h": f, "d": 1.0, "c": 1.0}, "kind": "max_hp", "what": "EHP/100 x%.2f of %s" % [er, basis]})
		opts.append({"mult": {"h": f, "d": 1.0, "c": sqrt(f)}, "kind": "max_hp_neutral", "what": "EHP/100 x%.2f of %s, cost keeps power" % [er, basis]})
	if not support and absf(log(dr)) > tol:
		var f2 := _step(dr)
		opts.append({"mult": {"h": 1.0, "d": f2, "c": 1.0}, "kind": "attack_damage", "what": "DPS/100 x%.2f of %s" % [dr, basis]})
		opts.append({"mult": {"h": 1.0, "d": f2, "c": sqrt(f2)}, "kind": "attack_damage_neutral", "what": "DPS/100 x%.2f of %s, cost keeps power" % [dr, basis]})
	if not support and absf(log(pr)) > tol:
		var g :=clampf(sqrt(pr), 1.0 - STEP_MAX, 1.0 + STEP_MAX)
		opts.append({"mult": {"h": 1.0, "d": 1.0, "c": g}, "kind": "cost", "what": "power/cost x%.2f of %s" % [pr, basis]})
	if not support and (er - 1.0) * (dr - 1.0) < 0.0 and absf(log(er / dr)) > 2.0 * tol:
		var t := clampf(pow(er / dr, 0.25), 1.0 - STEP_MAX, 1.0 + STEP_MAX)
		opts.append({"mult": {"h": 1.0 / t, "d": t, "c": 1.0}, "kind": "trade", "what": "shape EHP x%.2f / DPS x%.2f of %s" % [er, dr, basis]})
	for o: Dictionary in opts:
		var m: Dictionary = o["mult"]
		for key: String in ["h", "d", "c"]:
			m[key] = snappedf(float(m[key]), 0.01)
	return opts


static func _knob(r: Dictionary, o: Dictionary, basis: Array, wr: Dictionary) -> Dictionary:
	var k := String(r["kingdom"])
	var m: Dictionary = o["mult"]
	var h := float(m["h"])
	var d := float(m["d"])
	var c := float(m["c"])
	var er := float(basis[1])
	var dr := float(basis[2])
	# Shape: log distance to the basis median removed, in points (EHP always, DPS unless support).
	var shape := (absf(log(er)) - absf(log(er * h / c))) * 100.0
	if String(r["support"]) == "":
		shape += (absf(log(dr)) - absf(log(dr * d / c))) * 100.0
	var dpow := sqrt(h * d) / c - 1.0
	var shift := WR_PER_POWER * dpow
	var rate := float(wr[k]["rate"]) if wr.has(k) else -1.0
	var conf := _confidence(wr, k)
	var band_gain := 0.0
	var verdict := "no win-rate data"
	if rate >= 0.0:
		band_gain = (_outside(rate) - _outside(rate + shift)) * 100.0
		verdict = "toward 45-55 %" if band_gain > 0.2 else ("away from 45-55 %" if band_gain < -0.2 else "neutral")
	var score := 0.5 * shape + 3.0 * band_gain * conf
	var ov := {}
	var parts: Array[String] = []
	for pair: Array in [["max_hp", h], ["attack_damage", d], ["cost", c]]:
		var f := float(pair[1])
		if absf(f - 1.0) < 0.005:
			continue
		ov[pair[0]] = "x%.2f" % f
		parts.append("%s %s -> %s" % [pair[0], _num(float(r[pair[0]])), _num(float(r[pair[0]]) * f)])
	var knob := ", ".join(parts)
	var vname := "%s_%s" % [r["unit"], o["kind"]]
	return {"unit": r["unit"], "kingdom": k, "row": r["row"], "knob": knob, "overrides": ov, "reason": o["what"],
			"basis": basis[0], "power_delta": dpow, "expected_shift": shift, "band_gain": band_gain, "shape_gain": shape,
			"confidence": conf, "score": snappedf(score, 0.1), "verdict": verdict, "support": String(r["support"]) != "",
			"lead": r["lead"], "variant_name": vname,
			"why": "Balance Lab suggest: %s %s (%s); %s win rate %s; power %+.0f %%, expected shift %+.1f pts (prior); %s." % [
					r["unit"], knob, o["what"], k, _rate_text(wr, k), dpow * 100.0, shift * 100.0, verdict]}


## Factor that moves a metric at ratio r half-way (log) toward 1, capped at STEP_MAX.
static func _step(r: float) -> float:
	return clampf(pow(r, -0.5), 1.0 - STEP_MAX, 1.0 + STEP_MAX)


## Log distance to the median removed by multiplying the metric by f (fraction of the old distance, 0..1).
static func _gain(r: float, f: float) -> float:
	var before := absf(log(r))
	if before < 0.0001:
		return 0.0
	return (before - absf(log(r * f))) / before


static func _need(wr: Dictionary, k: String) -> float:
	var rate := float(wr[k]["rate"]) if wr.has(k) else -1.0
	if rate < 0.0:
		return 0.0
	return 0.45 - rate if rate < 0.45 else (0.55 - rate if rate > 0.55 else 0.0)


static func _confidence(wr: Dictionary, k: String) -> float:
	return clampf(float(wr[k]["games"]) / FULL_N, 0.0, 1.0) if wr.has(k) else 0.0


static func _outside(rate: float) -> float:
	return 0.45 - rate if rate < 0.45 else (rate - 0.55 if rate > 0.55 else 0.0)


static func _rate_text(wr: Dictionary, k: String) -> String:
	if not wr.has(k) or int(wr[k]["games"]) == 0:
		return "unknown"
	return "%d %% (%d/%d)" % [roundi(float(wr[k]["rate"]) * 100.0), wr[k]["wins"], wr[k]["games"]]


static func _median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var v := values.duplicate()
	v.sort()
	var m := v.size() / 2
	return float(v[m]) if v.size() % 2 == 1 else (float(v[m - 1]) + float(v[m])) / 2.0


static func _num(x: float) -> String:
	return str(roundi(x)) if absf(x - roundf(x)) < 0.05 or absf(x) >= 20.0 else "%.1f" % x


static func to_markdown(o: Dictionary) -> String:
	var md := "# Balance Lab suggest: %s\n\n" % o["date"]
	md += "Win rates from `%s` (non-mirror, baseline arm). Table = Data Lab B1 formulas: EHP = max_hp x (1 + armor / 100), " % o["results"]
	md += "DPS = attack_damage / attack_cooldown, per 100 crystals; ratios vs the slot's peers: combat units vs combat units, support units vs support units (their support is not in these stats, so they get no DPS or cost knob). "
	md += "Power = sqrt(EHP/100 x DPS/100). Expected shift = %.1f pts per 10 %% unit power (a prior; run the variant to measure).\n\n" % (WR_PER_POWER * 10.0)
	md += "## Kingdom win rates\n\n| Kingdom | Win rate | Need |\n|---|---|---|\n"
	for k in KINGDOMS:
		var need := _need(o["win_rates"], k)
		md += "| %s | %s | %s |\n" % [k, _rate_text(o["win_rates"], k), "buff" if need > 0.0 else ("nerf" if need < 0.0 else "-")]
	md += "\n## Top knobs (one per unit, written as variants)\n\n"
	var i := 1
	for k: Dictionary in o["picked"]:
		md += "%d. **%s** (%s, slot %s): %s. %s. Score %.1f, %s.\n   `run_balance.ps1 -Variants \"%s\"`\n" % [i, k["unit"], k["kingdom"],
				k["row"], k["knob"], k["reason"], k["score"], k["verdict"], String(k.get("variant_file", "")).replace("\\", "/")]
		i += 1
	md += "\n## Data Lab leads\n\nUnits the Data Lab flags (B1 per-100 ratio beyond x%.1f of the whole row, or raw max_hp / damage beyond x%.1f): what the lab says.\n\n" % [LEAD_FACTOR, RAW_FACTOR]
	md += lead_text(o) + "\n"
	md += "\n## All candidates\n\n| # | Unit | Kingdom | Basis | Knob | Reason | Power | Expected shift | Verdict | Score |\n|---|---|---|---|---|---|---|---|---|---|\n"
	i = 1
	for k: Dictionary in o["knobs"]:
		md += "| %d | %s%s | %s | %s | %s | %s | %+.0f %% | %+.1f pts | %s | %.1f |\n" % [i, k["unit"], " (support)" if k["support"] else "",
				k["kingdom"], k["basis"], k["knob"], k["reason"], float(k["power_delta"]) * 100.0, float(k["expected_shift"]) * 100.0, k["verdict"], k["score"]]
		i += 1
	md += "\n## Unit table (barracks slots)\n\n| Unit | Kingdom | Slot | Cost | EHP/100 | DPS/100 | Power | vs combat peers (EHP / DPS / power) | vs whole row (EHP / DPS) |\n|---|---|---|---|---|---|---|---|---|\n"
	for r: Dictionary in o["table"]:
		md += "| %s%s | %s | %s | %d | %.0f | %.1f | %.1f | x%.2f / x%.2f / x%.2f | x%.2f / x%.2f |\n" % [r["unit"],
				" (support: %s)" % r["support"] if r["support"] != "" else "", r["kingdom"], r["row"], r["cost"], r["ehp100"],
				r["dps100"], r["power"], r["ehp_ratio"], r["dps_ratio"], r["power_ratio"], r["ehp_ratio_all"], r["dps_ratio_all"]]
	return md


## One bullet per Data Lab lead: why it is flagged, how it looks against its combat peers, the best knob and the
## best knob that does not push its kingdom away from 45-55 %.
static func lead_text(o: Dictionary) -> String:
	var md := ""
	for r: Dictionary in o["table"]:
		if not bool(r["lead"]):
			continue
		var peers_ok := absf(log(float(r["ehp_ratio"]))) <= log(SHAPE_TOL) and absf(log(float(r["dps_ratio"]))) <= log(SHAPE_TOL)
		md += "- **%s** (%s, slot %s): flagged for %s. Against its peers (%s): EHP x%.2f, DPS x%.2f, power/cost x%.2f%s. " % [
				r["unit"], r["kingdom"], r["row"], r["lead_why"], ", ".join(r["peers"]), r["ehp_ratio"], r["dps_ratio"],
				r["power_ratio"], " (within x%.2f: the flag comes from mixing combat and support units in one slot)" % SHAPE_TOL if peers_ok else ""]
		md += "%s win rate %s. " % [r["kingdom"], _rate_text(o["win_rates"], String(r["kingdom"]))]
		var best: Dictionary = {}
		var best_ok: Dictionary = {}
		for k: Dictionary in o["knobs"]:
			if k["unit"] != r["unit"]:
				continue
			if best.is_empty():
				best = k
			if best_ok.is_empty() and not String(k["verdict"]).begins_with("away"):
				best_ok = k
		if best.is_empty():
			md += "No knob needed.\n"
			continue
		md += "Top knob: %s (%s basis, power %+.0f %%, %s, score %.1f)." % [best["knob"], best["basis"],
				float(best["power_delta"]) * 100.0, best["verdict"], best["score"]]
		if best_ok != best and not best_ok.is_empty():
			md += " Without pushing %s away from 45-55 %%: %s (%s, score %.1f)." % [r["kingdom"], best_ok["knob"], best_ok["verdict"],
					best_ok["score"]]
		elif best_ok.is_empty():
			md += " Every knob pushes %s away from 45-55 %%: fix it together with a %s change elsewhere, or wait for more games." % [
					r["kingdom"], "nerf" if _need(o["win_rates"], String(r["kingdom"])) < 0.0 else "buff"]
		md += "\n"
	return md if md != "" else "None.\n"


static func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("BALANCE SUGGEST: can't write %s" % path)
		return
	f.store_string(text)
	f.close()
