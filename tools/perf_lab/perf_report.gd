extends SceneTree
## Perf Lab report (docs/plan/perf-lab.md): turns the JSON lines of tools/perf_lab/perf_lab.gd (results.jsonl, one per
## run, the runner adds noise fields) into one scorecard per scenario + mode (md + json), a summary.md with the
## cross-scenario hot list, and rows in docs/perf/lab/history.md + history.jsonl.
## Run by run_perf_lab.ps1 at the end, or alone:
##   godot --headless --path . -s tools/perf_lab/perf_report.gd --quit-after 600 -- --in=C:/runs/x/results.jsonl \
##       [--out=C:/runs/x] [--latest=res://docs/perf/lab/latest] [--history=res://docs/perf/lab] [--no-history]
##   godot --headless --path . -s tools/perf_lab/perf_report.gd --quit-after 600 -- --table   (prints the budget table)
## Merge rule: per scenario + mode + resolution, the quiet runs only when there is at least one (else all, marked
## noisy); frame numbers = element-wise median of the unprofiled runs (the profiled run when it is the only one);
## hot list / systems / lint / engine gaps = the profiled run; hitch list = the run with the median frame avg.

const Stats := preload("res://tools/perf_lab/perf_stats.gd")
const Budgets := preload("res://tools/perf_lab/perf_budgets.gd")
const Scorecard := preload("res://tools/perf_lab/perf_scorecard.gd")

var args := {}


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	if args.has("table"):
		print(Budgets.markdown_table())
		quit(0)
		return
	var in_path := String(args.get("in", ""))
	if in_path == "" or not FileAccess.file_exists(in_path):
		push_error("PERF_LAB report: --in=<results.jsonl> missing (%s)" % in_path)
		quit(1)
		return
	var rows: Array[Dictionary] = []
	var f := FileAccess.open(in_path, FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "":
			continue
		var v: Variant = JSON.parse_string(line)
		if v is Dictionary:
			rows.append(v)
	f.close()
	var out_dir := String(args.get("out", in_path.get_base_dir()))
	var latest := ProjectSettings.globalize_path(String(args.get("latest", "res://docs/perf/lab/latest")))
	var hist := ProjectSettings.globalize_path(String(args.get("history", "res://docs/perf/lab")))
	var cards := build_scorecards(rows, hist)
	var summary := summary_markdown(cards, String(args.get("title", "Perf Lab run")))
	for dir: String in [out_dir, latest]:
		for c: RefCounted in cards:
			c.call(&"write", dir)
		_write(dir.path_join("summary.md"), summary)
	if not args.has("no-history"):
		for c2: RefCounted in cards:
			Scorecard.append_history(hist, c2.call(&"history_row"))
	print("PERF_LAB report: %d runs -> %d scorecards -> %s" % [rows.size(), cards.size(), latest.path_join("summary.md")])
	for c3: RefCounted in cards:
		print("  %s %s %s score %.0f %s" % [c3.get(&"scenario"), c3.get(&"mode"), c3.call(&"verdict"), c3.call(&"score"),
			"(noisy)" if c3.get(&"noisy") else ""])
	quit(0)


## One scorecard per scenario + mode + resolution.
static func build_scorecards(rows: Array[Dictionary], history_dir: String) -> Array:
	# Calibration guard: a run whose fixed GDScript workload ran > 1.3x slower than the batch's fastest was slowed
	# down by the machine (other programs, throttling).
	var best := INF
	for r0: Dictionary in rows:
		var cal: Array = r0.get("calib_ms", [])
		if not cal.is_empty():
			best = minf(best, float(cal[0]))
	for r1: Dictionary in rows:
		var cal1: Array = r1.get("calib_ms", [])
		if best < INF and not cal1.is_empty() and Stats.max_of(cal1) > best * 1.3:
			r1["noisy"] = true
			var why: Array = r1.get("noise_reasons", [])
			why.append("calibration %.0f ms vs best %.0f (x%.1f)" % [Stats.max_of(cal1), best, Stats.max_of(cal1) / best])
			r1["noise_reasons"] = why
	var groups := {}
	var order: Array[String] = []
	for r: Dictionary in rows:
		if r.has("error") and not r.has("frame"):
			continue
		var key := "%s|%s|%s" % [r.get("scenario", "?"), r.get("mode", "cpu"), r.get("resolution", "")]
		if not groups.has(key):
			groups[key] = []
			order.append(key)
		(groups[key] as Array).append(r)
	var cards: Array = []
	for key2: String in order:
		var runs: Array = groups[key2]
		var merged := merge_runs(runs)
		var sc := Scorecard.new()
		var prev := Scorecard.previous_row(history_dir, String(merged.get("scenario", "")), String(merged.get("mode", "")),
			String(merged.get("resolution", "")))
		sc.judge(merged, prev)
		cards.append(sc)
	return cards


static func merge_runs(runs: Array) -> Dictionary:
	var quiet: Array = []
	for r: Variant in runs:
		if not bool((r as Dictionary).get("noisy", false)):
			quiet.append(r)
	var use: Array = quiet if not quiet.is_empty() else runs
	var plain: Array = []
	var profiled: Dictionary = {}
	for r2: Variant in use:
		if bool((r2 as Dictionary).get("profile", false)):
			if profiled.is_empty():
				profiled = r2
		else:
			plain.append(r2)
	if profiled.is_empty():
		for r3: Variant in runs:
			if bool((r3 as Dictionary).get("profile", false)):
				profiled = r3
				break
	var base: Array = plain if not plain.is_empty() else use
	var merged := Stats.median_merge(base)
	var avgs: Array = []
	for r4: Variant in base:
		avgs.append(float(((r4 as Dictionary).get("frame", {}) as Dictionary).get("avg", 0.0)))
	merged["repeats"] = base.size()
	merged["repeat_avgs"] = avgs
	merged["repeat_spread_pct"] = snappedf(100.0 * Stats.spread(avgs), 0.1)
	# The hitch list of the median run.
	var med := Stats.median(avgs)
	var best: Dictionary = base[0]
	for r5: Variant in base:
		if absf(float(((r5 as Dictionary).get("frame", {}) as Dictionary).get("avg", 0.0)) - med) < \
				absf(float((best.get("frame", {}) as Dictionary).get("avg", 0.0)) - med):
			best = r5
	merged["hitch_list"] = best.get("hitch_list", [])
	if not profiled.is_empty():
		for k: String in ["hot", "systems", "engine", "lint"]:
			if profiled.has(k):
				merged[k] = profiled[k]
		merged["profiled_frame_avg"] = float((profiled.get("frame", {}) as Dictionary).get("avg", 0.0))
	merged["noisy"] = quiet.is_empty()
	var reasons: Array = []
	if quiet.is_empty():
		for r6: Variant in runs:
			for why: Variant in (r6 as Dictionary).get("noise_reasons", []):
				if not reasons.has(why):
					reasons.append(why)
	merged["noise_reasons"] = reasons
	var errs := 0
	for r7: Variant in runs:
		errs += int((r7 as Dictionary).get("script_errors", 0))
	merged["script_errors"] = errs
	merged["runs_total"] = runs.size()
	merged["runs_quiet"] = quiet.size()
	return merged


static func summary_markdown(cards: Array, title: String) -> String:
	var s := "# Perf Lab summary: %s\n\n" % title
	s += "Generated %s. One scorecard per scenario and mode in this folder (`<scenario>_<mode>.md`). " % \
		Time.get_datetime_string_from_system(false, true)
	s += "Budgets: `tools/perf_lab/perf_budgets.gd`; how to read: docs/plan/perf-lab.md.\n\n"
	s += "| Scenario | Mode | Result | Score | Frame avg | p95 | p99 | max | Hitches | GPU ms | Units | Noise | Runs |\n"
	s += "|---|---|---|---|---|---|---|---|---|---|---|---|---|\n"
	for c: RefCounted in cards:
		var r: Dictionary = c.get(&"result")
		var f: Dictionary = r.get("frame", {})
		var g: Dictionary = r.get("gpu", {})
		s += "| [%s](%s_%s.md) | %s | %s | %.0f | %.2f | %.2f | %.2f | %.1f | %d | %s | %d | %s | %d (%d quiet) |\n" % [
			c.get(&"scenario"), c.get(&"scenario"), c.get(&"mode"), String(c.get(&"mode")) + (" " + String(r.get("resolution", "")) if String(r.get("resolution", "")) != "" else ""),
			c.call(&"verdict"), c.call(&"score"), float(f.get("avg", 0.0)), float(f.get("p95", 0.0)), float(f.get("p99", 0.0)),
			float(f.get("max", 0.0)), int(f.get("hitches", 0)), ("%.2f" % float(g["gpu_ms_avg"])) if g.has("gpu_ms_avg") else "-",
			int(r.get("units_avg", 0)), "**noisy**" if c.get(&"noisy") else "quiet", int(r.get("runs_total", 1)), int(r.get("runs_quiet", 0))]
	# Cross-scenario hot list: each script's worst avg over the profiled CPU runs.
	var worst := {}
	for c2: RefCounted in cards:
		var r2: Dictionary = c2.get(&"result")
		for h: Variant in r2.get("hot", []):
			var d: Dictionary = h
			var k: String = d.get("key", "")
			if not worst.has(k) or float(d.get("avg_ms", 0.0)) > float((worst[k] as Dictionary).get("avg_ms", 0.0)):
				var e := d.duplicate()
				e["scenario"] = "%s/%s" % [c2.get(&"scenario"), c2.get(&"mode")]
				worst[k] = e
	var lst: Array = worst.values()
	lst.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["avg_ms"]) > float(b["avg_ms"]))
	if not lst.is_empty():
		s += "\n## Top 15 hot scripts (worst scenario each, avg ms per frame, band profiler)\n"
		s += "| # | Script | System | Scenario | Nodes | Avg ms | Max ms |\n|---|---|---|---|---|---|---|\n"
		var i := 1
		for e2: Variant in lst.slice(0, 15):
			var d2: Dictionary = e2
			s += "| %d | `%s` | %s | %s | %d | %.3f | %.2f |\n" % [i, d2["key"], d2.get("system", ""), d2["scenario"],
				int(d2.get("nodes", 0)), float(d2["avg_ms"]), float(d2.get("max_ms", 0.0))]
			i += 1
	s += "\n## Improve next (top item of each scorecard)\n"
	for c3: RefCounted in cards:
		var ideas: Array = c3.get(&"ideas")
		if not ideas.is_empty():
			var it: Dictionary = ideas[0]
			s += "- **%s / %s: %s**: %s\n" % [c3.get(&"scenario"), c3.get(&"mode"), it["title"], it["text"]]
	return s


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()
	else:
		push_error("PERF_LAB report: can't write %s" % path)
