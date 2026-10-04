extends SceneTree
## MAP GATE (docs/design/map-production.md 4.3 + 9, tool task MT8): one verdict per map from the acceptance gates.
## The runner tools/map_lab/run_map_gate.ps1 <map> (also `tools\world_forge\run_world_forge.ps1 gate <map>`) runs the
## steps and this script reads their outputs:
##   G1 World Forge `map`: exit / report PASS or WARN, L1 keeps, L2 inside, R5 engine limits
##   G2 Map Lab: score >= 75 and 0 FAIL checks
##   G3 Spacing: World Forge L3 + Map Lab R4 (forge_spacing.gd: >= 3 m between spots, >= 6 m between structures)
##   G4 Symmetry / fairness: Map Lab N2, M1-M4, F1, D1, T1 (+ A1 on team maps, C1 / C2) not FAIL
##   G5 Bot fairness (Bot Lab, mirrors fire / shadow / ice / nature x easy / normal / hard, seats = sides): pooled seat-1
##      win rate per difficulty 45-55 %, no cell (difficulty x mirror, >= 8 games) over 65 %, 0 script errors, every game
##      ends (kill, concede, early score or the score at the limit). Two passes (section 9): 40 games, then 120 only
##      when a rate is within CLOSE_BAND points of the 45 / 55 edge (`second_pass` in the JSON).
##   G6 Performance: tests/test_mt2_perf.gd on the map prints "PASS mt2_perf" (frame time within live Crown Hollow's)
##   G7 Load (info): Bot Lab startup / bake medians (sim mode)
## CLI (through tools/godot_run.ps1, headless):
##   -s res://tools/map_lab/map_gate.gd --quit-after 4000 -- id=<map> step=fresh        exit 0 fresh, 3 stale / missing
##   -s res://tools/map_lab/map_gate.gd --quit-after 4000 -- id=<map> step=verdict [bots=<dir>] [perf=<log>]
##        [skip=bots,perf] [out=<dir>]   prints the scorecard; writes <out>/scorecard.md + scorecard.json; exit 0 PASS /
##        PARTIAL (a step skipped, nothing failed), 1 FAIL, 2 bad input
## Static helpers (tests): forge_id_of, layout_path_of, fresh, forge_rows, bot_summary, bot_row, perf_row, evaluate,
## markdown.

const FMap := preload("res://tools/world_forge/forge_map.gd")
const LAB_MIN := 75.0
const RATE_LO := 0.45
const RATE_HI := 0.55
const CELL_MAX := 0.65
const CELL_MIN_GAMES := 8       ## the "no cell over 65 %" rule is judged on cells with this many games (pass 2)
const CLOSE_BAND := 0.03        ## within 3 points of an edge (42-48 % / 52-58 %): run the 120-game pass
const FAIR_CHECKS: Array[String] = ["N2", "M1", "M2", "M3", "M4", "F1", "D1", "T1", "C1", "C2"]
const ENDINGS: Array[String] = ["kill", "concede", "early-score", "time-score"]
const OUT_ROOT := "res://docs/tools/map_gate"
const FORGE_OUT := "res://docs/tools/world_forge/out"

var opts := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var id := String(opts.get("id", ""))
	if id == "":
		print("MAP GATE: give a map id (id=thornwater)")
		quit(2)
		return
	match String(opts.get("step", "verdict")):
		"fresh":
			var f := fresh(id)
			print("MAP GATE fresh %s: %s" % [id, f["why"]])
			quit(0 if bool(f["fresh"]) else 3)
		"verdict":
			var skips := String(opts.get("skip", "")).split(",", false)
			var bots: Array[Dictionary] = []
			if not skips.has("bots"):
				bots = read_results(String(opts.get("bots", "")))
			var perf_text := ""
			var perf_path := String(opts.get("perf", ""))
			if not skips.has("perf") and perf_path != "" and FileAccess.file_exists(perf_path):
				perf_text = read_log(perf_path)
			var v := evaluate(id, bots, perf_text, skips)
			var out := String(opts.get("out", "%s/%s" % [OUT_ROOT, id]))
			write(v, out)
			print(markdown(v))
			print("MAP GATE %s: %s (%s) -> %s/scorecard.md" % [id, v["result"], v["summary"], out])
			quit(1 if v["result"] == "FAIL" else 0)
		_:
			print("MAP GATE: unknown step %s (fresh | verdict)" % opts.get("step"))
			quit(2)


# ---------------------------------------------------------------- map ids

## The World Forge id of a gate map: the map itself, or `crown_hollow_level` for Crown Hollow (the scene map; its
## LayoutLevel rebuild is what World Forge and the Map Lab judge).
static func forge_id_of(id: String) -> String:
	return "crown_hollow_level" if id == "crown_hollow" else id


## The layout the Bot Lab and the perf test load ("" = Crown Hollow's scene, scenes/skirmish.tscn).
static func layout_path_of(id: String) -> String:
	if id == "crown_hollow":
		return ""
	return "res://data/maps/%s_layout.tres" % id


## {fresh: bool, why}: the World Forge report of the map exists and was made from the current .map (+ templates) text.
static func fresh(id: String) -> Dictionary:
	var fid := forge_id_of(id)
	var rep := _json("%s/%s/report_map.json" % [FORGE_OUT, fid])
	if rep.is_empty():
		return {"fresh": false, "why": "no World Forge report (docs/tools/world_forge/out/%s/report_map.json)" % fid}
	if _json("%s/%s/map_lab/scorecard.json" % [FORGE_OUT, fid]).is_empty():
		return {"fresh": false, "why": "no Map Lab scorecard"}
	var fm := FMap.new()
	if not fm.compile("res://data/maps/%s.map" % fid):
		return {"fresh": false, "why": "the .map does not compile"}
	var src := String(fm.layout.source_hash)
	var have := String(rep.get("hash", "")).get_slice("/", 0)
	if src != have:
		return {"fresh": false, "why": "stale: report hash %s, .map hash %s" % [have, src]}
	return {"fresh": true, "why": "report of %s matches the .map (hash %s)" % [String(rep.get("started", "?")), src]}


# ---------------------------------------------------------------- rows

## G1-G4 from the World Forge report and the Map Lab scorecard of the map.
static func forge_rows(id: String) -> Array[Dictionary]:
	var fid := forge_id_of(id)
	var rep := _json("%s/%s/report_map.json" % [FORGE_OUT, fid])
	var lab := _json("%s/%s/map_lab/scorecard.json" % [FORGE_OUT, fid])
	var rows: Array[Dictionary] = []
	if rep.is_empty():
		rows.append(_row("G1", "World Forge map", "FAIL", "no report: run `run_world_forge.ps1 map %s`" % fid, "report PASS / WARN"))
	else:
		var fc := _checks(rep)
		var bad: Array[String] = []
		for k: String in ["L1", "L2", "N0", "LAB.R5"]:
			if fc.has(k) and fc[k]["status"] == "FAIL":
				bad.append("%s %s" % [k, fc[k]["value"]])
		var st := "FAIL" if String(rep.get("result", "FAIL")) == "FAIL" or not bad.is_empty() else "PASS"
		rows.append(_row("G1", "World Forge map", st, "%s %.0f / 100%s; R5 %s" % [rep.get("result", "?"), float(rep.get("quality", 0)),
			("; " + ", ".join(bad)) if not bad.is_empty() else "", String(fc.get("LAB.R5", {}).get("value", "-"))],
			"exit 0 (PASS / WARN), L1 / L2 / N0 / R5 not FAIL"))
	if lab.is_empty():
		rows.append(_row("G2", "Map Lab", "FAIL", "no scorecard", "score >= %.0f, 0 FAIL" % LAB_MIN))
		rows.append(_row("G3", "Spacing", "FAIL", "no scorecard", "L3 PASS, R4 not FAIL"))
		rows.append(_row("G4", "Symmetry / fairness", "FAIL", "no scorecard", "N2 M1-M4 F1 D1 T1 (A1) C1 C2 not FAIL"))
		return rows
	var lc := _checks(lab)
	var fails: Array[String] = []
	for k: String in lc:
		if lc[k]["status"] == "FAIL":
			fails.append(k)
	var q := float(lab.get("quality", 0.0))
	rows.append(_row("G2", "Map Lab", "PASS" if q >= LAB_MIN and fails.is_empty() else "FAIL",
		"%s %.0f / 100, %d FAIL check(s)%s" % [lab.get("result", "?"), q, fails.size(), (" (" + ", ".join(fails) + ")") if not fails.is_empty() else ""],
		"score >= %.0f and 0 FAIL (map-production.md 9)" % LAB_MIN))
	var fl3: Dictionary = _checks(rep).get("L3", {}) if not rep.is_empty() else {}
	var r4: Dictionary = lc.get("R4", {})
	var sp_ok := String(fl3.get("status", "FAIL")) == "PASS" and String(r4.get("status", "PASS")) != "FAIL"
	rows.append(_row("G3", "Spacing", "PASS" if sp_ok else "FAIL", "L3 %s (%s); R4 %s (%s)" % [fl3.get("status", "-"), fl3.get("value", "-"),
		r4.get("status", "-"), r4.get("value", "-")], ">= 3 m between spots, >= 6 m between structures; R4 clearances not FAIL"))
	var parts: Array[String] = []
	var bad2: Array[String] = []
	var want := FAIR_CHECKS.duplicate()
	if lc.has("A1") and lc["A1"]["status"] != "INFO":
		want.append("A1")
	for k: String in want:
		if not lc.has(k):
			continue
		parts.append("%s %s" % [k, lc[k]["status"]])
		if lc[k]["status"] == "FAIL":
			bad2.append("%s: %s" % [k, lc[k]["value"]])
	rows.append(_row("G4", "Symmetry / fairness", "PASS" if bad2.is_empty() else "FAIL", ", ".join(parts) + ("; " + "; ".join(bad2) if not bad2.is_empty() else ""),
		"Map Lab N2, M1-M4, F1, D1, T1, C1, C2 (A1 on team maps) not FAIL"))
	return rows


## The Bot Lab result lines of every results.jsonl under `dirs` (";"-separated folders or files).
static func read_results(dirs: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: String in dirs.split(";", false):
		var files: Array[String] = []
		if d.ends_with(".jsonl"):
			files.append(d)
		else:
			files.append(d.path_join("results.jsonl"))
		for f in files:
			if not FileAccess.file_exists(f):
				continue
			for line: String in FileAccess.get_file_as_string(f).split("\n", false):
				var v: Variant = JSON.parse_string(line.strip_edges())
				if v is Dictionary:
					out.append(v)
	return out


## Pooled numbers of Bot Lab games: {games, decided, ended, errors, script_errors, by_diff: {d: {games, seat1, rate}},
## cells: {"d mirror": {games, seat1, rate}}, startup_s, bake_s (medians)}. Seat 1 = the PLAYER side (south-west / A1).
static func bot_summary(results: Array[Dictionary]) -> Dictionary:
	var s := {"games": 0, "decided": 0, "ended": 0, "errors": 0, "script_errors": 0, "by_diff": {}, "cells": {}, "startup_s": -1.0,
		"bake_s": -1.0, "reasons": {}}
	var startups: Array[float] = []
	var bakes: Array[float] = []
	for r in results:
		s["games"] += 1
		if r.has("error"):
			s["errors"] += 1
			continue
		s["script_errors"] += int(r.get("script_errors", 0))
		var reason := String(r.get("end_reason", ""))
		s["reasons"][reason] = int(s["reasons"].get(reason, 0)) + 1
		if ENDINGS.has(reason):
			s["ended"] += 1
		var side := String(r.get("winner_side", "none"))
		if side != "player" and side != "enemy":
			continue
		s["decided"] += 1
		var diff := String(r.get("difficulty", "normal"))
		var cell := "%s %s" % [diff, String(r.get("player", "?"))]
		for key: Array in [["by_diff", diff], ["cells", cell]]:
			var bucket: Dictionary = s[key[0]]
			if not bucket.has(key[1]):
				bucket[key[1]] = {"games": 0, "seat1": 0, "rate": 0.0}
			var b: Dictionary = bucket[key[1]]
			b["games"] += 1
			b["seat1"] += 1 if side == "player" else 0
			b["rate"] = float(b["seat1"]) / float(b["games"])
		if r.get("startup_s") != null:
			startups.append(float(r["startup_s"]))
		var parts: Variant = r.get("startup_parts")
		if parts is Dictionary and float((parts as Dictionary).get("bake_s", -1.0)) >= 0.0:
			bakes.append(float(parts["bake_s"]))
	s["startup_s"] = _median(startups)
	s["bake_s"] = _median(bakes)
	return s


## G5 from a bot summary: {row, second_pass: bool}. In the 40-game pass a rate within CLOSE_BAND of the 45 / 55 % edge
## asks for the 120-game pass instead of a verdict; a rate further out fails at once. Cells (difficulty x mirror) are
## judged only with CELL_MIN_GAMES games or more (pass 2).
static func bot_row(summary: Dictionary) -> Dictionary:
	var games := int(summary["games"])
	if games == 0:
		return {"row": _row("G5", "Bot fairness", "SKIP", "no Bot Lab games", "45-55 % seat win rate per difficulty"), "second_pass": false}
	var problems: Array[String] = []
	var close := false
	var parts: Array[String] = []
	for d: String in ["easy", "normal", "hard"]:
		if not (summary["by_diff"] as Dictionary).has(d):
			continue
		var b: Dictionary = summary["by_diff"][d]
		var rate := float(b["rate"])
		parts.append("%s %d / %d = %.0f %%" % [d, int(b["seat1"]), int(b["games"]), 100.0 * rate])
		var near_edge := absf(rate - RATE_LO) <= CLOSE_BAND or absf(rate - RATE_HI) <= CLOSE_BAND
		if near_edge:
			close = true
		if (rate < RATE_LO or rate > RATE_HI) and not (near_edge and int(b["games"]) < CELL_MIN_GAMES * 3):
			problems.append("%s seat rate %.0f %%" % [d, 100.0 * rate])
	var max_games := 0
	for c: String in summary["cells"]:
		var b: Dictionary = summary["cells"][c]
		max_games = maxi(max_games, int(b["games"]))
		var r := float(b["rate"])
		var lop := r > CELL_MAX or r < 1.0 - CELL_MAX
		if lop and int(b["games"]) >= CELL_MIN_GAMES:   # pass 1 (3-4 games a cell) never judges cells: coin noise
			problems.append("cell %s %.0f %%" % [c, 100.0 * r])
	if int(summary["errors"]) > 0:
		problems.append("%d game(s) without a result" % int(summary["errors"]))
	if int(summary["script_errors"]) > 0:
		problems.append("%d script error(s)" % int(summary["script_errors"]))
	var not_ended := games - int(summary["errors"]) - int(summary["ended"])
	if not_ended > 0:
		problems.append("%d game(s) did not end (stall / cap)" % not_ended)
	# pass 1 (cells under CELL_MIN_GAMES): a close or lopsided result asks for the 120-game pass instead of a verdict
	var second := close and problems.is_empty() and max_games < CELL_MIN_GAMES
	var st := "PASS"
	if not problems.is_empty():
		st = "FAIL"
	if second:
		st = "WARN"
	var value := "%d games (%d decided): %s" % [games, int(summary["decided"]), "; ".join(parts)]
	if not problems.is_empty():
		value += " | " + ", ".join(problems)
	if second:
		value += " | close to the edge: run the 120-game pass"
	return {"row": _row("G5", "Bot fairness", st, value, "seat win rate 45-55 %% per difficulty, no cell > 65 %% (>= %d games), 0 script errors, every game ends" % CELL_MIN_GAMES),
		"second_pass": second}


## A log file as text. Windows PowerShell 5.1's `*>` writes UTF-16 LE with a BOM (the runner's perf.log): decode it,
## else the file is UTF-8 (BOM or not).
static func read_log(path: String) -> String:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() >= 2 and bytes[0] == 0xFF and bytes[1] == 0xFE:
		return bytes.slice(2).get_string_from_utf16()
	if bytes.size() >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF:
		return bytes.slice(3).get_string_from_utf8()
	return bytes.get_string_from_utf8()


## G6 from the test_mt2_perf.gd log ("" = skipped).
static func perf_row(text: String) -> Dictionary:
	if text == "":
		return _row("G6", "Performance", "SKIP", "not run", "test_mt2_perf.gd prints PASS mt2_perf")
	for raw: String in text.split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("PASS mt2_perf"):
			return _row("G6", "Performance", "PASS", _perf_numbers(text), "frame time within live Crown Hollow's (+15 % + 0.5 ms), no stuck unit")
		if line.begins_with("FAIL mt2_perf"):
			return _row("G6", "Performance", "FAIL", line.strip_edges(), "frame time within live Crown Hollow's (+15 % + 0.5 ms), no stuck unit")
	return _row("G6", "Performance", "FAIL", "no PASS / FAIL line in the perf log", "test_mt2_perf.gd prints PASS mt2_perf")


static func _perf_numbers(text: String) -> String:
	var keep: Array[String] = []
	for line: String in text.split("\n"):
		var l := line.strip_edges()
		if l.contains(" ms") and (l.contains("skirmish") or l.contains("layout") or l.contains("frame")):
			keep.append(l)
	return "; ".join(keep.slice(0, 3)) if not keep.is_empty() else "PASS mt2_perf"


## The verdict: {id, result PASS / PARTIAL / FAIL, rows, second_pass, summary, bots}.
static func evaluate(id: String, bots: Array[Dictionary], perf_text: String, skips: Array = []) -> Dictionary:
	var rows := forge_rows(id)
	var bs := bot_summary(bots)
	var br := bot_row(bs)
	rows.append(br["row"])
	rows.append(perf_row(perf_text))
	var load_v := "startup %.1f s, bake %.1f s (Bot Lab medians, sim mode, headless)" % [float(bs["startup_s"]), float(bs["bake_s"])] \
			if float(bs["startup_s"]) >= 0.0 else "no Bot Lab games"
	rows.append(_row("G7", "Load (info)", "INFO", load_v, "first bake <= 5 s, load to playable <= 10 s (desktop, windowed: lead check)"))
	var result := "PASS"
	var n_fail := 0
	var n_open := 0
	for r in rows:
		if r["status"] == "FAIL":
			n_fail += 1
		elif r["status"] == "SKIP" or r["status"] == "WARN":
			n_open += 1
	if n_fail > 0:
		result = "FAIL"
	elif n_open > 0:
		result = "PARTIAL"
	var names: Array[String] = []
	for r in rows:
		if r["status"] != "PASS" and r["status"] != "INFO":
			names.append("%s %s" % [r["id"], r["status"]])
	return {"id": id, "result": result, "rows": rows, "second_pass": bool(br["second_pass"]), "bots": bs,
		"summary": ("all gates pass" if names.is_empty() else ", ".join(names)), "skips": skips}


static func markdown(v: Dictionary) -> String:
	var md := "# Map gate: %s\n\n**%s** (%s)\n\n| # | Gate | Result | Measured | Rule |\n|---|---|---|---|---|\n" % [v["id"], v["result"], v["summary"]]
	for r: Dictionary in v["rows"]:
		md += "| %s | %s | %s | %s | %s |\n" % [r["id"], r["name"], r["status"], String(r["value"]).replace("|", "/"), r["rule"]]
	if bool(v.get("second_pass", false)):
		md += "\nBot fairness is close to the 45-55 % edge: the runner plays the 120-game pass (`-Pass 2`).\n"
	return md


static func write(v: Dictionary, out_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var f := FileAccess.open(out_dir.path_join("scorecard.md"), FileAccess.WRITE)
	if f:
		f.store_string(markdown(v))
		f.close()
	var j := FileAccess.open(out_dir.path_join("scorecard.json"), FileAccess.WRITE)
	if j:
		j.store_string(JSON.stringify(v, "\t", false))
		j.close()


# ---------------------------------------------------------------- helpers

static func _row(id: String, name: String, status: String, value: String, rule: String) -> Dictionary:
	return {"id": id, "name": name, "status": status, "value": value, "rule": rule}


static func _checks(rep: Dictionary) -> Dictionary:
	var out := {}
	for c: Variant in rep.get("checks", []):
		if c is Dictionary:
			out[String(c.get("id", ""))] = c
	return out


static func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return v if v is Dictionary else {}


static func _median(a: Array[float]) -> float:
	if a.is_empty():
		return -1.0
	var b := a.duplicate()
	b.sort()
	return b[b.size() / 2]
