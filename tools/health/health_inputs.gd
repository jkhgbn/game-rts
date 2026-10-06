extends RefCounted
## Game Health Dashboard: reads the LATEST outputs of every lab (never re-runs them) and turns each into
## HealthCore components (health_core.gd). Every reader is defensive: a missing / unreadable file gives a component
## with score -1 ("no data"), never an error. `root` = the project folder (absolute, with or without a trailing /).

const Core := preload("res://tools/health/health_core.gd")

const KINGDOMS := ["fire", "ice", "nature", "shadow"]
const LOCALE_DIRS := ["locale", "locales", "localization", "translations", "data/i18n", "data/locale", "data/localization"]
const PERF_TOOL := "tools\\perf_lab\\run_perf_lab.ps1 -WaitQuietS 600"

static var _now := 0.0


## Every component, in area order.
static func collect(root: String) -> Array:
	_now = Time.get_unix_time_from_system()
	root = root.trim_suffix("/").trim_suffix("\\")
	var out: Array = []
	out.append_array(stability(root))
	out.append_array(performance(root))
	out.append_array(balance(root))
	out.append_array(maps(root))
	out.append_array(art(root))
	out.append_array(ui(root))
	out.append_array(data(root))
	out.append_array(content(root))
	return out


# --- helpers ------------------------------------------------------------------------------------------------------

static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var txt := FileAccess.get_file_as_string(path)
	if txt.begins_with("﻿"):
		txt = txt.substr(1)
	var j := JSON.new()
	if j.parse(txt) != OK:
		return null
	return j.data


## The rows of a .jsonl file (bad lines skipped), oldest first.
static func read_jsonl(path: String) -> Array:
	var out: Array = []
	if not FileAccess.file_exists(path):
		return out
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var s := line.strip_edges()
		if s.begins_with("﻿"):
			s = s.substr(1)
		if s == "":
			continue
		var j := JSON.new()
		if j.parse(s) == OK and j.data is Dictionary:
			out.append(j.data)
	return out


static func mtime(path: String) -> float:
	return float(FileAccess.get_modified_time(path)) if FileAccess.file_exists(path) else 0.0


static func age_days(path: String) -> float:
	var t := mtime(path)
	return snappedf((_now - t) / 86400.0, 0.1) if t > 0.0 else -1.0


static func rel(root: String, path: String) -> String:
	return path.replace("\\", "/").trim_prefix(root.replace("\\", "/") + "/")


## `<dir>/*/<file>` paths that exist, newest first (by the file's mtime).
static func files_in_subdirs(dir: String, file: String) -> Array[String]:
	var out: Array[String] = []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for d in DirAccess.get_directories_at(dir):
		var p := dir.path_join(d).path_join(file)
		if FileAccess.file_exists(p):
			out.append(p)
	out.sort_custom(func(a: String, b: String) -> bool: return mtime(a) > mtime(b))
	return out


static func files_matching(dir: String, prefix: String, suffix: String) -> Array[String]:
	var out: Array[String] = []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for f in DirAccess.get_files_at(dir):
		if f.begins_with(prefix) and f.ends_with(suffix):
			out.append(dir.path_join(f))
	out.sort()
	return out


## A JSON number as text ("3", not "3.0").
static func num(v: Variant) -> String:
	if (v is float or v is int) and is_equal_approx(float(v), roundf(float(v))):
		return str(int(v))
	return str(v)


static func none(id: String, area: String, label: String, why: String) -> Dictionary:
	return Core.component(id, area, label, -1.0, 1.0, "no data: " + why)


## `improve_next` rows of a scorecard as problems (first `n`).
static func improve_problems(card: Dictionary, n: int, owner: String, fix: String) -> Array:
	var out: Array = []
	var rows: Array = card.get("improve_next", []) if card.get("improve_next", []) is Array else []
	for r in rows:
		if out.size() >= n:
			break
		if r is Dictionary and String(r.get("status", "WARN")) in ["FAIL", "WARN"]:
			out.append(Core.problem(String(r.get("text", "")).left(220), String(r.get("source", "")), owner, fix))
	return out


# --- Stability ----------------------------------------------------------------------------------------------------

static func error_lab_cards(root: String) -> Array[String]:
	var cards: Array[String] = []
	var ci := root.path_join("docs/ci")
	if DirAccess.dir_exists_absolute(ci):
		for d in DirAccess.get_directories_at(ci):
			var p := ci.path_join(d).path_join("error_lab/scorecard.json")
			if FileAccess.file_exists(p):
				cards.append(p)
	cards.append_array(files_in_subdirs(root.path_join("docs/errors/lab"), "scorecard.json"))
	cards.sort_custom(func(a: String, b: String) -> bool: return mtime(a) > mtime(b))
	return cards


static func stability(root: String) -> Array:
	var out: Array = []
	var test_files := files_matching(root.path_join("tests"), "test_", ".gd").size()
	var cards := error_lab_cards(root)
	var card: Variant = read_json(cards[0]) if not cards.is_empty() else null
	if card is Dictionary and card.get("tests", []) is Array and not (card["tests"] as Array).is_empty():
		var tests: Array = card["tests"]
		var ok := 0
		var probs: Array = []
		for t in tests:
			if bool(t.get("ok", false)):
				ok += 1
			else:
				var why := String(t.get("why", ""))
				var fl: Array = t.get("fail_lines", []) if t.get("fail_lines", []) is Array else []
				if not fl.is_empty():
					why += ": " + String(fl[0]).left(160)
				probs.append(Core.problem("Fix failing test %s" % String(t.get("test", "?")), why,
						String(t.get("owner", "")), "tools\\ci\\ci_quick.ps1 -Changed"))
		var scope := "" if tests.size() * 2 >= test_files else " (subset run: %d of %d test files)" % [tests.size(), test_files]
		out.append(Core.component("ci_tests", "stability", "Tests pass (latest CI / Error Lab run)",
				100.0 * ok / tests.size(), 3.0, "%d / %d pass in %s%s" % [ok, tests.size(), String(card.get("run", "?")), scope],
				rel(root, cards[0]), probs, age_days(cards[0])))
		out.append(Core.component("error_lab", "stability", "Error Lab score (unique errors)", float(card.get("score", -1)),
				2.0, "%s %s / 100, %s FAIL / %s WARN unique errors, %s new" % [card.get("result", "?"), num(card.get("score", "?")),
				num(card.get("unique_fail", "?")), num(card.get("unique_warn", "?")), num(card.get("new", "?"))], rel(root, cards[0]), [],
				age_days(cards[0])))
	else:
		out.append(none("ci_tests", "stability", "Tests pass", "no Error Lab scorecard (run tools\\ci\\ci_quick.ps1)"))
	# Flaky: tests that both passed and failed over the last 6 Error Lab runs.
	var seen := {}
	var used := 0
	for p in cards.slice(0, 6):
		var c: Variant = read_json(p)
		if not (c is Dictionary) or not (c.get("tests", []) is Array):
			continue
		used += 1
		for t in c["tests"]:
			var id := String(t.get("test", ""))
			if not seen.has(id):
				seen[id] = [0, 0]
			seen[id][0 if bool(t.get("ok", false)) else 1] += 1
	if used >= 2:
		var flaky: Array[String] = []
		for id in seen:
			if seen[id][0] > 0 and seen[id][1] > 0:
				flaky.append(id)
		flaky.sort()
		var fp: Array = []
		if not flaky.is_empty():
			var evs: Array[String] = []
			for id in flaky.slice(0, 10):
				evs.append("%s %d/%d" % [id, seen[id][0], seen[id][1]])
			fp.append(Core.problem("%d tests flip between pass and fail (last %d Error Lab runs)" % [flaky.size(), used],
					"pass/fail counts: " + ", ".join(evs) + " (timing tests flip when the PC is loaded)", "test owners",
					"re-run each alone 3x on a quiet PC; fix the timing budget or the seed"))
		out.append(Core.component("flaky", "stability", "Flip-flop tests (last %d Error Lab runs)" % used,
				maxf(0.0, 100.0 - 6.0 * flaky.size()), 1.0, "%d tests flipped: %s" % [flaky.size(), ", ".join(flaky.slice(0, 10))],
				"docs/ci/*/error_lab", fp, -1.0))
	# Smoke + CI verdict from the newest ci_result.txt.
	var results := files_in_subdirs(root.path_join("docs/ci"), "ci_result.txt")
	if not results.is_empty():
		var txt := FileAccess.get_file_as_string(results[0])
		var smoke_ok := txt.contains("Smoke PASS") or txt.contains("victory=true")
		out.append(Core.component("smoke", "stability", "Smoke test (mission 1 won)", 100.0 if smoke_ok else 0.0, 1.0,
				txt.get_slice("\n", 1).strip_edges(), rel(root, results[0]),
				[] if smoke_ok else [Core.problem("Smoke test fails", txt.get_slice("\n", 1), "lead", "tests/smoke_test.gd")],
				age_days(results[0])))
	var rh := read_jsonl(root.path_join("docs/replay/lab/history.jsonl"))
	if not rh.is_empty():
		var r: Dictionary = rh[-1]
		out.append(Core.component("replay", "stability", "Replay Lab (determinism)", float(r.get("score", 0)), 1.0,
				"%s: %s, %s replays (%s pass, %s fail)" % [r.get("run", "?"), r.get("result", "?"), num(r.get("replays", "?")),
				num(r.get("pass", "?")), num(r.get("fail", "?"))], "docs/replay/lab/history.jsonl",
				[Core.problem("Replays diverge (Replay Lab %s)" % r.get("result", "?"), String(r.get("run", "")), "lead",
				"tools\\replay_lab\\run_replay.ps1 -Record")] if float(r.get("score", 0)) < 100.0 else [],
				age_days(root.path_join("docs/replay/lab/history.jsonl"))))
	var bh := read_jsonl(root.path_join("docs/build/lab/history.jsonl"))
	if not bh.is_empty():
		var b: Dictionary = bh[-1]
		out.append(Core.component("build", "stability", "Build Lab (exported game)", float(b.get("score", 0)), 1.0,
				"%s: %s, %s fails" % [b.get("run", "?"), b.get("result", "?"), num(b.get("fails", "?"))], "docs/build/lab/history.jsonl",
				[], age_days(root.path_join("docs/build/lab/history.jsonl"))))
	return out


# --- Performance --------------------------------------------------------------------------------------------------

static func performance(root: String) -> Array:
	var out: Array = []
	var dir := root.path_join("docs/perf/lab/latest")
	var scen: Array = []
	var newest := ""
	for p in files_matching(dir, "", ".json"):
		var c: Variant = read_json(p)
		if c is Dictionary and c.has("score"):
			scen.append([p, c])
			if newest == "" or mtime(p) > mtime(newest):
				newest = p
	if not scen.is_empty():
		var t := 0.0
		var parts: Array[String] = []
		var probs: Array = []
		var gaps := 0.0
		for e in scen:
			gaps += 100.0 - float(e[1]["score"])
		for e in scen:
			var c: Dictionary = e[1]
			t += float(c["score"])
			parts.append("%s %s %s%s" % [c.get("scenario", "?"), c.get("mode", ""), c["score"], " (noisy)" if bool(c.get("noisy", false)) else ""])
			if String(c.get("verdict", "")) == "FAIL":
				var tip := ""
				var imp: Array = c.get("improve_next", []) if c.get("improve_next", []) is Array else []
				if not imp.is_empty():
					tip = String(imp[0].get("text", "")).left(200)
				probs.append(Core.problem("Perf %s (%s) FAILs its budget: %s" % [c.get("scenario", "?"), c.get("mode", ""), tip],
						"score %s, %s" % [c["score"], rel(root, e[0])], "perf (owner of the hot file)", PERF_TOOL,
						(100.0 - float(c["score"])) / gaps if gaps > 0.0 else -1.0))
		out.append(Core.component("perf_lab", "performance", "Perf Lab scenarios (latest)", t / scen.size(), 2.0,
				", ".join(parts), "docs/perf/lab/latest", probs, age_days(newest)))
	else:
		out.append(none("perf_lab", "performance", "Perf Lab", "docs/perf/lab/latest is empty"))
	var results := files_in_subdirs(root.path_join("docs/ci"), "ci_result.txt")
	if not results.is_empty():
		var lines: Array[String] = []
		var t := 0.0
		var n := 0
		var probs: Array = []
		for line in FileAccess.get_file_as_string(results[0]).split("\n"):
			if not line.begins_with("PERF "):
				continue
			var ms := float(line.get_slice("ms_per_frame=", 1).get_slice(" ", 0))
			var budget := float(line.get_slice("budget=", 1).get_slice(" ", 0))
			if ms <= 0.0 or budget <= 0.0:
				continue
			var s := minf(100.0, 100.0 * budget / ms)
			t += s
			n += 1
			lines.append("%s units %.2f / %.1f ms" % [line.get_slice("units=", 1).get_slice(" ", 0), ms, budget])
			if ms > budget:
				probs.append(Core.problem("Perf test over budget: %s" % line.strip_edges(), "CI " + rel(root, results[0]),
						"perf", PERF_TOOL))
		if n > 0:
			out.append(Core.component("ci_perf", "performance", "CI perf tests (frame ms vs budget)", t / n, 1.0,
					", ".join(lines), rel(root, results[0]), probs, age_days(results[0])))
	return out


# --- Balance ------------------------------------------------------------------------------------------------------

static func balance(root: String) -> Array:
	var out: Array = []
	var cards := files_in_subdirs(root.path_join("docs/balance/lab"), "scorecard.json")
	var card: Variant = read_json(cards[0]) if not cards.is_empty() else null
	if card is Dictionary:
		var matches := int(card.get("matches", 0))
		var probs: Array = []
		if matches < 40:
			probs.append(Core.problem("Balance Lab sample too small (%d matches)" % matches, "run %s" % card.get("run", "?"),
					"balance", "tools\\balance_lab\\run_balance.ps1 -Seeds 1-12"))
		for c in card.get("checks", []):
			if c is Dictionary and String(c.get("status", "")) == "FAIL":
				probs.append(Core.problem("Balance check %s %s: %s" % [c.get("id", ""), c.get("name", ""), c.get("value", "")],
						String(c.get("target", "")), "balance", ""))
		out.append(Core.component("balance_lab", "balance", "Balance Lab (bot matches)", float(card.get("score", -1)),
				0.5 if matches < 40 else 1.0, "%s %s, %d matches, best arm %s" % [card.get("run", "?"), card.get("result", "?"),
				matches, card.get("best_arm", "?")], rel(root, cards[0]), probs, age_days(cards[0])))
	else:
		out.append(none("balance_lab", "balance", "Balance Lab", "no docs/balance/lab/*/scorecard.json"))
	# Unit Lab: the newest full matrix run (folder "matrix*" / "final_matrix*", else any) with a baseline variant and
	# >= 20 entries; A/B screens (ab_*) are experiments, not the current game. Outlier = verdict too strong / too weak.
	var cands := files_in_subdirs(root.path_join("docs/balance/unit_lab"), "scorecard.json")
	var preferred: Array[String] = []
	for p in cands:
		var dn := p.get_base_dir().get_file()
		if dn.begins_with("matrix") or dn.begins_with("final_matrix"):
			preferred.append(p)
	for p in cands:
		if not preferred.has(p):
			preferred.append(p)
	for p in preferred:
		var c: Variant = read_json(p)
		if not (c is Dictionary) or not (c.get("variants", null) is Dictionary):
			continue
		var vs: Dictionary = c["variants"]
		var key := "baseline" if vs.has("baseline") else (String(vs.keys()[0]) if vs.size() == 1 else "")
		if key == "" or not (vs[key] is Dictionary):
			continue
		var games: Variant = vs[key].get("games", {})
		var outs: Variant = vs[key].get("outliers", [])
		if not (games is Dictionary) or (games as Dictionary).size() < 20 or not (outs is Array):
			continue
		var flagged: Array = []
		for o in outs:
			if o is Dictionary and String(o.get("verdict", "")) != "":
				flagged.append(o)
		flagged.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return absf(float(a.get("mean", 0.5)) - 0.5) > absf(float(b.get("mean", 0.5)) - 0.5))
		var probs: Array = []
		if not flagged.is_empty():
			var worst: Array[String] = []
			for o in flagged.slice(0, 6):
				worst.append("%s %s (%s)" % [o.get("entry", "?"), o.get("verdict", ""), String(o.get("why", "")).left(60)])
			probs.append(Core.problem("%d of %d units are Unit Lab outliers at equal cost" % [flagged.size(), (games as Dictionary).size()],
					"worst: " + "; ".join(worst), "gameplay-coder (data/units)",
					"tools\\unit_lab\\run_unit_lab.ps1 -Matrix, then confirm in the Balance Lab"))
		var n := (games as Dictionary).size()
		var strong := flagged.filter(func(o: Dictionary) -> bool: return String(o["verdict"]) == "too strong").size()
		out.append(Core.component("unit_lab", "balance", "Unit Lab matrix: entries that are not outliers",
				100.0 * (1.0 - float(flagged.size()) / n), 1.0, "%d outliers of %d entries (%d too strong, %d too weak; %s, variant %s)" % [
				flagged.size(), n, strong, flagged.size() - strong, p.get_base_dir().get_file(), key],
				rel(root, p), probs, age_days(p)))
		break
	return out


# --- Maps ---------------------------------------------------------------------------------------------------------

static func ready_map_ids() -> Array[String]:
	var out: Array[String] = []
	if not ResourceLoader.exists("res://data/maps/catalog.tres"):
		return out
	var cat: Resource = load("res://data/maps/catalog.tres")
	var maps: Variant = cat.get(&"maps") if cat != null else null
	if maps is Array:
		for e in maps:
			if e is Dictionary and bool(e.get("ready", false)) and String(e.get("mode", "skirmish")) != "wave_strike":
				out.append(String(e.get("id", "")))
	return out


static func maps(root: String) -> Array:
	var out: Array = []
	var gate_dir := root.path_join("docs/tools/map_gate")
	var gates := files_in_subdirs(gate_dir, "scorecard.json")
	if not gates.is_empty():
		var t := 0.0
		var parts: Array[String] = []
		var probs: Array = []
		var newest := gates[0]
		for p in gates:
			var c: Variant = read_json(p)
			if not (c is Dictionary):
				continue
			var r := String(c.get("result", "?"))
			t += {"PASS": 100.0, "PARTIAL": 70.0, "FAIL": 35.0}.get(r, 35.0)
			parts.append("%s %s (%s)" % [c.get("id", "?"), r, c.get("summary", "")])
			for row in c.get("rows", []):
				if row is Dictionary and String(row.get("status", "")) in ["FAIL", "SKIP"]:
					probs.append(Core.problem("Map %s: gate %s %s %s" % [c.get("id", "?"), row.get("id", ""), row.get("name", ""), row.get("status", "")],
							String(row.get("value", "")).left(200), "map tools (four-wizards-high)",
							"tools\\map_lab\\run_map_gate.ps1 %s -Resume" % c.get("id", "?"),
							0.7 if String(row.get("status", "")) == "FAIL" else 0.3))
		out.append(Core.component("map_gate", "maps", "Map gate verdicts", t / gates.size(), 2.0, "; ".join(parts),
				"docs/tools/map_gate", probs, age_days(newest)))
	else:
		out.append(none("map_gate", "maps", "Map gate", "no docs/tools/map_gate/*/scorecard.json"))
	var ids := ready_map_ids()
	var ds := root.path_join("tools/map_lab/balance/dataset")
	var t2 := 0.0
	var n2 := 0
	var parts2: Array[String] = []
	var probs2: Array = []
	var newest2 := ""
	for id in ids:
		var p := ds.path_join(id + ".json")
		var rp := root.path_join("docs/health/refresh/map_balance/%s.json" % id)   # run_health.ps1 -Refresh
		if mtime(rp) > mtime(p):
			p = rp
		var c: Variant = read_json(p)
		if not (c is Dictionary) or not c.has("score"):
			continue
		var s := float(c["score"])
		t2 += s
		n2 += 1
		var verdict := String((c.get("prediction", {}) as Dictionary).get("verdict", "")) if c.get("prediction", {}) is Dictionary else ""
		parts2.append("%s %.0f (%s)" % [id, s, verdict])
		if newest2 == "" or mtime(p) > mtime(newest2):
			newest2 = p
		if s < 85.0 or verdict == "likely biased":
			probs2.append(Core.problem("Map %s internal balance %.0f / 100 (%s)" % [id, s, verdict], "balance model dataset",
					"map tools", "tools\\world_forge\\run_world_forge.ps1 balance %s" % id))
	if n2 > 0:
		out.append(Core.component("map_balance", "maps", "Map balance model (ready maps)", t2 / n2, 1.0,
				", ".join(parts2), "tools/map_lab/balance/dataset", probs2, age_days(newest2)))
	var labs := files_in_subdirs(root.path_join("docs/maps/lab"), "scorecard.json")
	if not labs.is_empty():
		var c: Variant = read_json(labs[0])
		if c is Dictionary and c.has("quality"):
			out.append(Core.component("map_lab", "maps", "Map Lab (Crown Hollow)", float(c["quality"]), 0.5,
					"%s %s" % [c.get("run", "?"), c.get("result", "?")], rel(root, labs[0]),
					improve_problems(c, 2, "map tools", "tools\\map_lab"), age_days(labs[0])))
	return out


# --- Art ----------------------------------------------------------------------------------------------------------

static func art(root: String) -> Array:
	var out: Array = []
	var cards := files_in_subdirs(root.path_join("docs/art/lab"), "scorecard.json")
	var t := 0.0
	var n := 0
	var fails: Array = []
	var newest := ""
	for p in cards:
		var c: Variant = read_json(p)
		if not (c is Dictionary) or not c.has("quality"):
			continue
		t += float(c["quality"])
		n += 1
		if newest == "":
			newest = p
		if String(c.get("result", "")) == "FAIL":
			fails.append([float(c["quality"]), String(c.get("asset", rel(root, p).get_base_dir().get_file())),
					String(c.get("scene", "")), c])
	if n > 0:
		fails.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var probs: Array = []
		if not fails.is_empty():
			var names: Array[String] = []
			for f in fails.slice(0, 8):
				names.append("%s %.0f" % [f[1], f[0]])
			probs.append(Core.problem("%d art assets FAIL the Art Lab" % fails.size(), "lowest: " + ", ".join(names), "tech-artist",
					"docs/art/lab/backlog.md (ranked fixes), re-check: tools\\art_lab\\run_art_lab.ps1 <scene>"))
		out.append(Core.component("art_quality", "art", "Art Lab mean quality (%d assets)" % n, t / n, 2.0,
				"mean %.1f over %d scorecards" % [t / n, n], "docs/art/lab/*/scorecard.json", [], age_days(newest)))
		out.append(Core.component("art_fails", "art", "Art assets without a FAIL", 100.0 * (1.0 - float(fails.size()) / n), 1.0,
				"%d of %d assets FAIL" % [fails.size(), n], "docs/art/lab/*/scorecard.json", probs, age_days(newest)))
	else:
		out.append(none("art_quality", "art", "Art Lab", "no docs/art/lab/*/scorecard.json"))
	var vh := read_jsonl(root.path_join("docs/visual/lab/history.jsonl"))
	if not vh.is_empty():
		var v: Dictionary = vh[-1]
		out.append(Core.component("visual_diff", "art", "Visual Diff Lab (golden shots)", float(v.get("score", 0)), 0.5,
				"%s %s (%s)" % [v.get("result", "?"), num(v.get("score", "?")), v.get("when", "?")], "docs/visual/lab/history.jsonl",
				[] if float(v.get("score", 0)) >= 100.0 else [Core.problem("Golden shots changed", String(v.get("when", "")),
				"tech-artist", "tools\\visual_diff_lab")], age_days(root.path_join("docs/visual/lab/history.jsonl"))))
	var aud := files_in_subdirs(root.path_join("docs/audio/lab"), "scorecard.json")
	var at := 0.0
	var an := 0
	for p in aud:
		var c: Variant = read_json(p)
		if c is Dictionary and c.has("score"):
			at += float(c["score"])
			an += 1
	if an > 0:
		out.append(Core.component("audio", "art", "Audio Lab mean score (%d sets)" % an, at / an, 0.5,
				"mean %.1f" % (at / an), "docs/audio/lab/*/scorecard.json", [], age_days(aud[0])))
	return out


# --- UI / Data ----------------------------------------------------------------------------------------------------

static func ui(root: String) -> Array:
	var out: Array = []
	var p := root.path_join("docs/ui/lab/scorecard.json")
	var c: Variant = read_json(p)
	if c is Dictionary and c.has("quality"):
		var counts: Dictionary = c.get("counts", {}) if c.get("counts", {}) is Dictionary else {}
		out.append(Core.component("ui_lab", "ui", "UI Lab quality", float(c["quality"]), 2.0,
				"%s %s (FAIL %s, WARN %s checks)" % [c.get("result", "?"), c["quality"], num(counts.get("FAIL", "?")), num(counts.get("WARN", "?"))],
				rel(root, p), improve_problems(c, 3, "ui-coder", "tools\\ui_lab"), age_days(p)))
	else:
		out.append(none("ui_lab", "ui", "UI Lab", "no docs/ui/lab/scorecard.json"))
	for sub in ["lab_u7", "tier_audit", "unit_guide"]:
		var q := root.path_join("docs/ui").path_join(sub).path_join("scorecard.json")
		var d: Variant = read_json(q)
		if d is Dictionary and (d.has("quality") or d.has("score")):
			out.append(Core.component("ui_" + sub, "ui", "UI %s" % sub, float(d.get("quality", d.get("score", 0))), 0.5,
					String(d.get("result", "")), rel(root, q), improve_problems(d, 1, "ui-coder", ""), age_days(q)))
	return out


static func data(root: String) -> Array:
	var cards := files_in_subdirs(root.path_join("docs/data/lab"), "scorecard.json")
	var rp := root.path_join("docs/health/refresh/data_lab/scorecard.json")   # run_health.ps1 -Refresh
	if FileAccess.file_exists(rp) and (cards.is_empty() or mtime(rp) > mtime(cards[0])):
		cards.insert(0, rp)
	var c: Variant = read_json(cards[0]) if not cards.is_empty() else null
	if not (c is Dictionary) or not c.has("quality"):
		return [none("data_lab", "data", "Data Lab", "no docs/data/lab/*/scorecard.json")]
	var fc: Dictionary = c.get("finding_counts", {}) if c.get("finding_counts", {}) is Dictionary else {}
	return [Core.component("data_lab", "data", "Data Lab quality", float(c["quality"]), 1.0,
			"%s %s %s (%s FAIL, %s WARN findings)" % [c.get("run", "?"), c.get("result", "?"), c["quality"], num(fc.get("FAIL", "?")), num(fc.get("WARN", "?"))],
			rel(root, cards[0]), improve_problems(c, 3, "data owner (see finding)", "tools\\data_lab"), age_days(cards[0]))]


# --- Content completeness -----------------------------------------------------------------------------------------

static func kingdom_units(root: String) -> Array[String]:
	var out: Array[String] = []
	for p in files_matching(root.path_join("data/units"), "", ".tres"):
		var txt := FileAccess.get_file_as_string(p)
		var f := txt.get_slice("faction = &\"", 1).get_slice("\"", 0)
		if f in KINGDOMS:
			out.append(p.get_file().get_basename())
	return out


static func content(root: String) -> Array:
	var out: Array = []
	var built := files_matching(root.path_join("missions"), "mission_", ".tscn").size()
	var specs := files_matching(root.path_join("docs/design"), "mission-", ".md")
	var ep1 := 0
	var all := 0
	for s in specs:
		var f := s.get_file()
		if f == "mission-framework.md":
			continue
		all += 1
		if not f.begins_with("mission-e"):
			ep1 += 1
	if all > 0:
		out.append(Core.component("missions_ep1", "content", "Episode 1 missions built vs specified",
				100.0 * minf(1.0, float(built) / maxi(ep1, 1)), 1.0, "%d built / %d episode-1 specs" % [built, ep1], "missions/",
				[Core.problem("Build the %d missing episode-1 missions" % (ep1 - built), "", "systems-coder", "")] if built < ep1 else []))
		out.append(Core.component("missions_all", "content", "Campaign missions built vs all specs",
				100.0 * minf(1.0, float(built) / all), 0.5, "%d built / %d specs (episodes 1-8)" % [built, all], "docs/design/mission-*.md",
				[Core.problem("Campaign: %d of %d specified missions not built yet" % [all - built, all], "episodes 2-8 specs exist",
				"systems-coder", "")]))
	var units := kingdom_units(root)
	if not units.is_empty():
		var guide: Variant = read_json(root.path_join("data/ui/unit_guide.json"))
		var gu: Dictionary = guide.get("units", {}) if guide is Dictionary and guide.get("units", {}) is Dictionary else {}
		var miss := {"guide": [], "icon": [], "voice": []}
		for u in units:
			if not gu.has(u):
				miss["guide"].append(u)
			if not FileAccess.file_exists(root.path_join("art/icons/units/%s.png" % u)):
				miss["icon"].append(u)
			if not DirAccess.dir_exists_absolute(root.path_join("assets/audio/voice/unit_" + u)):
				miss["voice"].append(u)
		for k in [["guide", "Unit Guide entry", "ui-coder (data/ui/unit_guide.json)", "tools/unit_guide/gen_guide.gd '--' write"],
				["icon", "unit icon", "tech-artist (art/icons/units)", "art/icons/render_icons.gd"],
				["voice", "voice barks", "audio (assets/audio/voice)", "tools\\voice_forge"]]:
			var m: Array = miss[k[0]]
			out.append(Core.component("units_" + k[0], "content", "Kingdom units with a %s" % k[1],
					100.0 * (1.0 - float(m.size()) / units.size()), 1.0, "%d / %d (missing: %s)" % [units.size() - m.size(),
					units.size(), ", ".join(PackedStringArray(m.slice(0, 8)))], "data/units",
					[Core.problem("%d kingdom units have no %s" % [m.size(), k[1]], ", ".join(PackedStringArray(m.slice(0, 8))), k[2], k[3])]
					if not m.is_empty() else []))
	out.append(localization(root))
	return out


## Localization coverage: translated cells / expected cells over the CSV / PO files of the first locale folder found.
static func localization(root: String) -> Dictionary:
	for d in LOCALE_DIRS:
		var dir := root.path_join(d)
		if not DirAccess.dir_exists_absolute(dir):
			continue
		var filled := 0
		var total := 0
		var langs := {}
		for f in DirAccess.get_files_at(dir):
			var p := dir.path_join(f)
			if f.ends_with(".csv"):
				var lines := FileAccess.get_file_as_string(p).split("\n", false)
				if lines.size() < 2:
					continue
				var head := lines[0].split(",")
				for i in range(2, head.size()):
					langs[head[i].strip_edges()] = true
				for li in range(1, lines.size()):
					var cells := lines[li].split(",")
					for i in range(2, head.size()):
						total += 1
						if i < cells.size() and cells[i].strip_edges().replace("\"", "") != "":
							filled += 1
			elif f.ends_with(".po"):
				langs[f.get_basename()] = true
				var txt := FileAccess.get_file_as_string(p)
				var parts := txt.split("msgstr ")
				for i in range(2, parts.size()):   # [0] = before the first, [1] = the header entry
					total += 1
					var body := parts[i].replace("\r", "")
					var empty := body.begins_with("\"\"") and not body.get_slice("\n", 1).begins_with("\"")
					if not empty:
						filled += 1
		if total > 0:
			var s := 100.0 * filled / total
			return Core.component("localization", "content", "Localization coverage", s, 1.0,
					"%d / %d strings translated (%s) in %s/" % [filled, total, ", ".join(PackedStringArray(langs.keys())), d], d,
					[Core.problem("%d strings untranslated" % (total - filled), d, "localization", "")] if filled < total else [],
					age_days(dir))
	return none("localization", "content", "Localization coverage", "no locale folder yet")
