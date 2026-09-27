extends RefCounted
## Perf Lab (docs/plan/perf-lab.md): the scorecard of one scenario in one mode (cpu = headless logic, gpu = windowed).
## Takes the merged result dictionary of perf_lab.gd (median of the repeats + the profiled run's hot list), judges it
## against perf_budgets.gd (PASS / WARN / FAIL / INFO), turns it into a 0-100 perf score and an "Improve next" list
## (always >= 3 concrete suggestions pointing at a file / function), writes scorecard.md + scorecard.json and a row in
## docs/perf/lab/history.md (+ history.jsonl, which the next run reads to flag regressions).
## Plain dictionaries only (no game class), so tests/test_perf_lab.gd can build one from fake numbers.

const Budgets := preload("res://tools/perf_lab/perf_budgets.gd")
const Stats := preload("res://tools/perf_lab/perf_stats.gd")
const Hints := preload("res://tools/perf_lab/perf_hints.gd")

const VERSION := "1.0"
const GROUP_WEIGHT := {"frame": 3.0, "shape": 1.5, "gpu": 3.0, "system": 1.5, "census": 1.0, "health": 1.5}
const GROUP_TITLE := {"frame": "Frame time", "shape": "Frame shape (spikes, hitches)", "gpu": "GPU / render",
	"system": "Systems (band profiler)", "census": "Scene census", "health": "Health (leaks, pools, noise)"}
const GROUP_ORDER: Array[String] = ["frame", "shape", "gpu", "system", "census", "health"]
## A metric this much worse than the previous clean run of the same scenario + mode is a regression (WARN).
const REGRESSION_PCT := 10.0

var scenario := ""
var mode := ""                    ## "cpu" or "gpu"
var result: Dictionary = {}       ## merged run result (see perf_lab.gd _result())
var checks: Array[Dictionary] = []
var ideas: Array[Dictionary] = []  ## {title, text, source, rank}
var previous: Dictionary = {}     ## the previous clean history row (same scenario + mode), {} when none
var noisy := false
var noise_reasons: Array[String] = []


func add(id: String, group: String, check_name: String, status: String, value: String, rule: String, graded: float = -1.0,
		weight: float = 1.0) -> Dictionary:
	var c := {"id": id, "group": group, "name": check_name, "status": status, "value": value, "rule": rule,
		"weight": weight, "graded": graded}
	c["score"] = score_of(status, graded)
	checks.append(c)
	return c


static func score_of(status: String, graded: float) -> float:
	var g := clampf(graded, 0.0, 1.0)
	match status:
		"PASS":
			return 1.0 if graded < 0.0 else lerpf(0.7, 1.0, g)
		"WARN":
			return 0.5 if graded < 0.0 else lerpf(0.35, 0.69, g)
		"FAIL":
			return 0.0 if graded < 0.0 else lerpf(0.0, 0.34, g)
	return -1.0


## 0 at `bad`, 1 at `good` (either direction).
static func grade(value: float, bad: float, good: float) -> float:
	if is_equal_approx(bad, good):
		return 1.0 if value <= good else 0.0
	return clampf((value - bad) / (good - bad), 0.0, 1.0)


## PASS / WARN / FAIL for a "lower is better" value: > fail = FAIL, > warn = WARN.
static func status_of(value: float, fail: float, warn: float) -> String:
	if fail >= 0.0 and value > fail:
		return "FAIL"
	if warn >= 0.0 and value > warn:
		return "WARN"
	return "PASS"


## Grade for a lower-is-better value: within PASS it climbs from `warn` (0) to warn/2 (1); in WARN from `fail` to
## `warn`; in FAIL from 2x fail to fail.
static func grade_low(value: float, fail: float, warn: float) -> float:
	var st := status_of(value, fail, warn)
	var w := warn if warn >= 0.0 else fail
	if st == "PASS":
		return grade(value, w, w * 0.5)
	if st == "WARN":
		return grade(value, fail if fail >= 0.0 else w * 2.0, w)
	return grade(value, fail * 2.0, fail)


func count(status: String) -> int:
	var n := 0
	for c: Dictionary in checks:
		if c["status"] == status:
			n += 1
	return n


func verdict() -> String:
	if count("FAIL") > 0:
		return "FAIL"
	if count("WARN") > 0:
		return "WARN"
	return "PASS"


func score() -> float:
	var sw := 0.0
	var ss := 0.0
	for c: Dictionary in checks:
		var s: float = c["score"]
		if s < 0.0:
			continue
		var w: float = float(c["weight"]) * float(GROUP_WEIGHT.get(c["group"], 1.0))
		sw += w
		ss += w * s
	return 100.0 * ss / sw if sw > 0.0 else 0.0


# ---------------------------------------------------------------- judging

## Fills `checks` and `ideas` from `result`. `prev` = the previous clean history row of this scenario + mode.
func judge(p_result: Dictionary, prev: Dictionary = {}) -> void:
	result = p_result
	scenario = String(result.get("scenario", ""))
	mode = String(result.get("mode", "cpu"))
	previous = prev
	noisy = bool(result.get("noisy", false))
	noise_reasons.assign(result.get("noise_reasons", []))
	var f: Dictionary = result.get("frame", {})
	var units := int(result.get("units_avg", Budgets.SCENARIO_UNITS.get(scenario, 0)))
	var measured_s := maxf(float(result.get("measured_s", 1.0)), 1.0)
	if mode == "cpu":
		var b := Budgets.logic_budget(scenario, units)
		_frame_checks(f, float(b["limit"]), float(b["warn"]), "logic", "%s (%d units)" % [b["src"], units])
	else:
		_frame_checks(f, float(Budgets.GPU["avg"]), float(Budgets.GPU["avg_warn"]), "windowed", Budgets.GPU["src"])
		_gpu_checks()
	var hpm := float(f.get("hitches", 0)) / (measured_s / 60.0)
	var hs := status_of(hpm, float(Budgets.SHAPE["hitch_fail"]), float(Budgets.SHAPE["hitch_warn"]))
	add("S3", "shape", "Hitches (> %.0f ms)" % Budgets.HITCH_MS, hs, "%d in %.0f s (%.2f / min)" % [int(f.get("hitches", 0)),
		measured_s, hpm], "FAIL > %.1f / min, WARN > %.1f / min (%s)" % [Budgets.SHAPE["hitch_fail"],
		Budgets.SHAPE["hitch_warn"], Budgets.SHAPE["src"]], grade_low(hpm, float(Budgets.SHAPE["hitch_fail"]),
		maxf(float(Budgets.SHAPE["hitch_warn"]), 0.01)))
	_system_checks(units)
	_census_checks()
	_health_checks()
	_regression_checks()
	_build_ideas()


func _frame_checks(f: Dictionary, lim: float, warn: float, what: String, src: String) -> void:
	var avg := float(f.get("avg", 0.0))
	add("F1", "frame", "Frame avg (%s)" % what, status_of(avg, lim, warn), "%.2f ms" % avg,
		"FAIL > %.2f, WARN > %.2f ms (%s)" % [lim, warn, src], grade_low(avg, lim, warn), 2.0)
	var p95 := float(f.get("p95", 0.0))
	var p95l := lim * float(Budgets.SHAPE["p95_x"])
	add("S1", "shape", "Frame p95", status_of(p95, -1.0, p95l), "%.2f ms" % p95, "WARN > %.2f ms (%.1fx the avg budget)" % [
		p95l, Budgets.SHAPE["p95_x"]], grade_low(p95, p95l * 1.5, p95l))
	var p99 := float(f.get("p99", 0.0))
	var p99l := lim * float(Budgets.SHAPE["p99_x"])
	if what == "windowed":
		p99l = maxf(p99l, float(Budgets.GPU["p99"]))
	add("S2", "shape", "Frame p99", status_of(p99, -1.0, p99l), "%.2f ms (max %.1f ms)" % [p99, float(f.get("max", 0.0))],
		"WARN > %.2f ms" % p99l, grade_low(p99, p99l * 1.5, p99l))


func _gpu_checks() -> void:
	var g: Dictionary = result.get("gpu", {})
	var rb: Dictionary = Budgets.RENDER.get(scenario, Budgets.RENDER["mid100"])
	if g.has("gpu_ms_avg"):
		var gm := float(g["gpu_ms_avg"])
		add("G1", "gpu", "GPU render time avg", status_of(gm, Budgets.FRAME_60_MS, Budgets.FRAME_120_MS),
			"%.2f ms (p95 %.2f)" % [gm, float(g.get("gpu_ms_p95", 0.0))], "FAIL > 16.7 ms, WARN > 8.3 ms (%s)" % Budgets.GPU["src"],
			grade_low(gm, Budgets.FRAME_60_MS, Budgets.FRAME_120_MS), 2.0)
	for k: String in ["draw_calls", "objects", "primitives"]:
		if not g.has(k + "_avg"):
			continue
		var v := float(g[k + "_avg"])
		var l := float(rb[k])
		add("G-" + k, "gpu", "Render %s (avg per frame)" % k.replace("_", " "), status_of(v, -1.0, l), "%.0f (max %.0f)" % [v,
			float(g.get(k + "_max", v))], "WARN > %.0f (%s)" % [l, Budgets.RENDER["src"]], grade_low(v, l * 1.5, l))
	if g.has("video_mem_mb"):
		add("G-vmem", "gpu", "Video memory", "INFO", "%.0f MB" % float(g["video_mem_mb"]), "info (GTX 1660: 6 GB)")


func _system_checks(units: int) -> void:
	var sys: Dictionary = result.get("systems", {})
	if sys.is_empty():
		add("P0", "system", "Band profiler", "INFO", "no profiled run", "run with --profile=1 for the hot list")
		return
	var i := 1
	for row: Dictionary in Budgets.SYSTEMS:
		var id: String = row["id"]
		if not sys.has(id):
			continue
		var s: Dictionary = sys[id]
		var avg := float(s.get("avg_ms", 0.0))
		var mx := float(s.get("max_ms", 0.0))
		var med := float(s.get("median_ms", 0.0))
		var lim := -1.0
		if row.has("avg"):
			lim = float(row["avg"])
		elif row.has("per100") and units >= 10:   # a per-unit rule means nothing without units (menu)
			lim = float(row["per100"]) * float(units) / 100.0
		if lim < 0.0:
			add("P%d" % i, "system", row["label"], "INFO", "avg %.3f ms, median %.3f, max %.2f ms" % [avg, med, mx],
				"inside the frame budget (%s)" % row["src"])
		else:
			var st := status_of(avg, lim, lim * 0.75)
			add("P%d" % i, "system", row["label"] + " avg", st, "avg %.3f ms, median %.3f, max %.2f ms" % [avg, med, mx],
				"FAIL > %.3f ms, WARN > %.3f (%s)" % [lim, lim * 0.75, row["src"]], grade_low(avg, lim, lim * 0.75))
		if row.has("max"):
			var ml := float(row["max"])
			add("P%da" % i, "system", row["label"] + " worst frame", status_of(mx, ml, ml * 0.5), "%.2f ms" % mx,
				"FAIL > %.1f ms (%s)" % [ml, row["src"]], grade_low(mx, ml, ml * 0.5))
		if row.has("median_warn"):
			var mw := float(row["median_warn"])
			add("P%db" % i, "system", row["label"] + " median frame", status_of(med, -1.0, mw), "%.3f ms" % med,
				"WARN > %.2f ms (lab target)" % mw, grade_low(med, mw * 3.0, mw))
		i += 1
	# The Commander's own think tick counters (commander.gd tick_usec_*), when the bots ran.
	var ai: Dictionary = result.get("ai", {})
	if not ai.is_empty():
		var med_ms := float(ai.get("tick_median_ms", 0.0))
		var max_ms := float(ai.get("tick_max_ms", 0.0))
		add("A1", "system", "Commander think tick median", status_of(med_ms, 0.3, 0.1), "%.3f ms over %d ticks (step %s)" % [med_ms,
			int(ai.get("ticks", 0)), String(ai.get("worst_step", "?"))], "FAIL > 0.3 ms (ai.md:146), WARN > 0.1 ms (lab target; ai-2v2.md:340 median <= 0.25)",
			grade_low(med_ms, 0.3, 0.1), 1.5)
		add("A2", "system", "Commander think tick max", status_of(max_ms, 1.5, 0.45), "%.2f ms (step %s)" % [max_ms,
			String(ai.get("worst_step", "?"))], "FAIL > 1.5 ms (no frame > 1.5 ms of AI), WARN > 0.45 (ai-2v2.md:340)",
			grade_low(max_ms, 1.5, 0.45))


func _census_checks() -> void:
	var c: Dictionary = result.get("census", {})
	if c.is_empty():
		return
	var rules: Dictionary = Budgets.CENSUS
	var i := 1
	for k: String in ["lights", "shadow_lights", "decor_instances", "draw_nodes_decor"]:
		if not c.has(k):
			continue
		var r: Dictionary = rules[k]
		var v := float(c[k])
		var hard: bool = bool(r.get("hard", true))
		var lim := float(r["limit"])
		var st := status_of(v, lim if hard else -1.0, -1.0 if hard else lim)
		add("C%d" % i, "census", k.replace("_", " "), st, str(c[k]), ("FAIL > " if hard else "WARN > ") + str(r["limit"]) +
			" (%s)" % r["src"], grade_low(v, lim * 1.5, lim) if st != "PASS" else 1.0)
		i += 1
	for k2: String in ["geometry_nodes", "shadow_casters", "particle_systems", "multimesh_nodes", "nodes"]:
		if c.has(k2):
			add("C%d" % i, "census", k2.replace("_", " "), "INFO", str(c[k2]), "info")
			i += 1


func _health_checks() -> void:
	var h: Dictionary = result.get("health", {})
	var r: Dictionary = Budgets.CENSUS
	if h.has("vfx_nodes_created"):
		var v := int(h["vfx_nodes_created"])
		add("H1", "health", "VFX nodes created after warm-up", "FAIL" if v > int(r["vfx_nodes_created"]["limit"]) else "PASS",
			"%d%s" % [v, (" (" + String(h.get("vfx_nodes_top", "")) + ")") if v > 0 else ""],
			"FAIL > 0 (%s)" % r["vfx_nodes_created"]["src"], -1.0 if v > 0 else 1.0)
	if h.has("orphan_nodes"):
		var o := int(h["orphan_nodes"])
		add("H2", "health", "Orphan nodes at the end", "WARN" if o > 0 else "PASS", str(o), "WARN > 0 (%s)" % r["orphan_nodes"]["src"])
	if h.has("node_growth_pct"):
		var g := float(h["node_growth_pct"])
		add("H3", "health", "Node growth (non-unit)", status_of(g, -1.0, 10.0), "%+.1f %%" % g,
			"WARN > 10 %% (%s)" % r["node_growth_pct"]["src"], grade_low(maxf(g, 0.0), 30.0, 10.0))
	if h.has("static_mem_growth_mb"):
		add("H4", "health", "Static memory growth", "INFO", "%+.1f MB" % float(h["static_mem_growth_mb"]), "info")
	add("H5", "health", "Machine noise", "WARN" if noisy else "PASS", ("noisy: " + "; ".join(noise_reasons)) if noisy else "quiet",
		"WARN when other Godot processes ran or the CPU was busy (numbers not comparable)")
	if int(result.get("script_errors", 0)) > 0:
		add("H6", "health", "Script errors during the run", "FAIL", str(result["script_errors"]), "FAIL > 0")


func _regression_checks() -> void:
	if previous.is_empty():
		return
	var cur_avg := float((result.get("frame", {}) as Dictionary).get("avg", 0.0))
	var prev_avg := float(previous.get("avg", 0.0))
	if prev_avg > 0.0:
		var d := 100.0 * (cur_avg - prev_avg) / prev_avg
		add("R1", "health", "Change vs previous clean run", "WARN" if d > REGRESSION_PCT and not noisy else "PASS",
			"%+.1f %% (%.2f -> %.2f ms, %s)" % [d, prev_avg, cur_avg, String(previous.get("commit", "?"))],
			"WARN > +%.0f %% (only judged on quiet runs)" % REGRESSION_PCT)


# ---------------------------------------------------------------- improve next

func _build_ideas() -> void:
	ideas.clear()
	var hot: Array = result.get("hot", [])
	var lint: Dictionary = result.get("lint", {})
	# 1. The hottest scripts, with the costly patterns found in their per-frame functions.
	var rank := 100.0
	for h: Variant in hot.slice(0, 6):
		var row: Dictionary = h
		var path: String = row.get("key", "")
		var sug := Hints.for_script(path, lint.get(path, []), float(row.get("avg_ms", 0.0)), int(row.get("nodes", 0)))
		if sug.is_empty():
			continue
		sug["rank"] = rank + float(row.get("avg_ms", 0.0))
		ideas.append(sug)
		rank -= 1.0
	# 2. Hitches: the band that dominated the worst frames.
	var hitches: Array = result.get("hitch_list", [])
	if not hitches.is_empty():
		var h0: Dictionary = hitches[0]
		var top: Array = h0.get("top", [])
		if not top.is_empty():
			var t0: Dictionary = top[0]
			var s2 := Hints.for_hitch(String(t0.get("key", "")), float(h0.get("ms", 0.0)), float(t0.get("ms", 0.0)),
				String(h0.get("events", "")))
			s2["rank"] = 150.0
			ideas.append(s2)
	# GPU cost by layer (windowed late200): layers over 8 % of the GPU frame.
	for row: Variant in result.get("gpu_ablation", []):
		var d: Dictionary = row
		if float(d.get("cost_pct", 0.0)) >= 8.0:
			var sl := for_layer(String(d["layer"]), float(d["cost_ms"]), float(d["cost_pct"]))
			sl["rank"] = 130.0 + float(d["cost_pct"])
			ideas.append(sl)
	# 3. Failing / warning checks with a generic fix (render, lights, census, pools).
	for c: Dictionary in checks:
		if c["status"] != "FAIL" and c["status"] != "WARN":
			continue
		var s3 := Hints.for_check(String(c["id"]), String(c["name"]), String(c["value"]), mode)
		if s3.is_empty():
			continue
		s3["rank"] = (200.0 if c["status"] == "FAIL" else 120.0)
		if c["id"] == "F1":
			s3["rank"] = 90.0   # generic: the hot-script items say more
		ideas.append(s3)
	ideas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["rank"]) > float(b["rank"]))
	# De-duplicate by title, then top up with the standing ideas so there are always >= 3.
	var seen := {}
	var out: Array[Dictionary] = []
	for it: Dictionary in ideas:
		if seen.has(it["title"]):
			continue
		seen[it["title"]] = true
		out.append(it)
	for e: Dictionary in Hints.standing(mode, scenario):
		if out.size() >= 3:
			break
		if not seen.has(e["title"]):
			out.append(e)
			seen[e["title"]] = true
	ideas = out.slice(0, 8)


## A GPU layer suggestion (from the windowed ablation).
static func for_layer(layer: String, cost_ms: float, pct: float) -> Dictionary:
	var fix := "hide it beyond a visibility range, or draw less of it."
	if layer.begins_with("map dressing"):
		fix = "art/environment/map_dressing.gd (+ the biome sets): visibility_range_end 65 / 90 m with fade on tufts / flowers / bushes (map-fill.md:400), cast_shadow OFF on everything but trees / logs / big rocks, density x0.6-0.8 (the open 12.L2 question, lead-status.md:115), and map_detail Low = half."
	elif layer.begins_with("ground mesh"):
		fix = "the ground shader (river paint + biome splats, art/environment/ground_params.gd): cast_shadow OFF on the ground (for-systems-coder.md:586-590), fewer texture samples, and a cheap path for the river paint far from the camera / on map_detail Low."
	elif layer.begins_with("river"):
		fix = "RiverSystem visuals (art/environment/water/): one opaque material, <= 6 000 triangles (map-fill.md:401), no screen / depth reads, foam scroll off on map_detail Low."
	elif layer.begins_with("env props"):
		fix = "EnvProps MultiMeshes (trees / rocks): add mesh LODs or a visibility range on small rocks; only trees and big rocks cast shadows."
	elif layer.begins_with("units"):
		fix = "unit models: merge parts (<= 14 instances per unit, art-units.md 8), shadows only on 4 merged parts, and an impostor / MultiMesh tier for far units."
	elif layer.begins_with("buildings"):
		fix = "building models: <= 32 draw calls per keep (art-keep.md 9), shaders off beyond 60 m, particles hidden beyond 60 m."
	elif layer.begins_with("sun shadows"):
		fix = "the sun's shadows: shorter shadow max distance / fewer cascades at RTS zoom, and fewer casters (decor, small props)."
	elif layer.begins_with("cosmetic critters"):
		fix = "CritterSystem: <= 60 animated, one MultiMesh per kind, 50 m range (map-fill.md:402)."
	elif layer.begins_with("HUD"):
		fix = "the HUD: fewer redrawn controls per frame (queue_redraw only on change), the portrait SubViewport at a lower rate."
	return {"title": "GPU: %s" % layer.get_slice(" (", 0), "text": "Costs %.2f ms (%.0f %% of the GPU frame, windowed ablation over the Crown Isle at zoom 55). Fix: %s" % [cost_ms, pct, fix],
		"source": "GPU cost by layer"}


# ---------------------------------------------------------------- writers

func to_dict() -> Dictionary:
	return {"lab_version": VERSION, "scenario": scenario, "mode": mode, "verdict": verdict(),
		"score": snappedf(score(), 0.1), "noisy": noisy, "noise_reasons": noise_reasons,
		"counts": {"PASS": count("PASS"), "WARN": count("WARN"), "FAIL": count("FAIL"), "INFO": count("INFO")},
		"checks": checks, "improve_next": ideas, "previous": previous, "result": result}


func to_markdown() -> String:
	var r := result
	var f: Dictionary = r.get("frame", {})
	var s := "# Perf Lab scorecard: %s (%s)\n\n" % [scenario, "headless logic" if mode == "cpu" else "windowed " + String(r.get("resolution", ""))]
	s += "Commit `%s` · %s · %d run(s) (median) · seed %d · %.0f s measured · lab v%s\n\n" % [String(r.get("commit", "?")),
		String(r.get("started", "")), int(r.get("repeats", 1)), int(r.get("seed", 1)), float(r.get("measured_s", 0.0)), VERSION]
	s += "Scenario: %s.\n\n" % String(r.get("what", ""))
	if noisy:
		s += "> **NOISY**: %s. Treat the numbers as an upper bound; re-run on a quiet PC before comparing (`run_perf_lab.ps1 -WaitQuietS 600 -Repeats 3` waits for no other Godot and a low other-CPU load before each run).\n\n" % "; ".join(noise_reasons)
	var delta := ""
	if not previous.is_empty() and float(previous.get("score", -1.0)) >= 0.0:
		delta = " (previous %.0f on %s)" % [float(previous["score"]), String(previous.get("commit", "?"))]
	s += "## Result: **%s** · perf score **%.0f / 100**%s\n\n" % [verdict(), score(), delta]
	s += "Frame avg **%.2f ms** · p95 %.2f · p99 %.2f · max %.1f · hitches %d · %d frames · units %d · nodes %d\n\n" % [
		float(f.get("avg", 0.0)), float(f.get("p95", 0.0)), float(f.get("p99", 0.0)), float(f.get("max", 0.0)),
		int(f.get("hitches", 0)), int(f.get("frames", 0)), int(r.get("units_avg", 0)), int(r.get("nodes_avg", 0))]
	if r.has("repeat_avgs"):
		s += "Repeats (frame avg ms): %s\n\n" % str(r["repeat_avgs"])
	s += "## Improve next\n"
	var i := 1
	for it: Dictionary in ideas:
		s += "%d. **%s**: %s _(%s)_\n" % [i, it["title"], it["text"], it.get("source", "")]
		i += 1
	s += "\n"
	for g: String in GROUP_ORDER:
		var rows: Array[Dictionary] = []
		for c: Dictionary in checks:
			if c["group"] == g:
				rows.append(c)
		if rows.is_empty():
			continue
		s += "## %s\n| # | Check | Result | Measured | Rule |\n|---|---|---|---|---|\n" % GROUP_TITLE.get(g, g)
		for c: Dictionary in rows:
			var st: String = c["status"]
			if st == "FAIL" or st == "WARN":
				st = "**%s**" % st
			if float(c["score"]) >= 0.0:
				st += " %.0f" % (100.0 * float(c["score"]))
			s += "| %s | %s | %s | %s | %s |\n" % [c["id"], c["name"], st, _cell(c["value"]), _cell(c["rule"])]
		s += "\n"
	var hot: Array = r.get("hot", [])
	if not hot.is_empty():
		s += "## Hot list (band profiler, top 15 scripts by avg ms per frame)\n"
		s += "| # | Script | System | Nodes | Avg ms | Median | p95 | Max ms | Share |\n|---|---|---|---|---|---|---|---|---|\n"
		var n := 1
		for h: Variant in hot.slice(0, 15):
			var row: Dictionary = h
			s += "| %d | `%s` | %s | %d | %.3f | %.3f | %.3f | %.2f | %.1f %% |\n" % [n, row.get("key", ""), row.get("system", ""),
				int(row.get("nodes", 0)), float(row.get("avg_ms", 0.0)), float(row.get("median_ms", 0.0)),
				float(row.get("p95_ms", 0.0)), float(row.get("max_ms", 0.0)), float(row.get("share_pct", 0.0))]
			n += 1
		var eng: Dictionary = r.get("engine", {})
		if not eng.is_empty():
			s += "\nEngine gaps (avg ms per frame): physics + navigation server step %.3f · render / tweens / idle %.3f · " % [
				float(eng.get("physics_ms", 0.0)), float(eng.get("other_ms", 0.0))]
			s += "unclassified nodes %.3f · probe overhead ~%.3f\n\n" % [float(eng.get("unclassified_ms", 0.0)),
				float(eng.get("probe_overhead_ms", 0.0))]
	var ab: Array = r.get("gpu_ablation", [])
	if not ab.is_empty():
		s += "## GPU cost by layer (windowed ablation: tree paused, camera over the Crown Isle at zoom 55)\n"
		s += "| Layer hidden | Baseline GPU ms | Hidden GPU ms | Cost ms | Cost % |\n|---|---|---|---|---|\n"
		for a: Variant in ab:
			var ad: Dictionary = a
			s += "| %s | %.2f | %.2f | %.2f | %.1f %% |\n" % [ad["layer"], float(ad["base_ms"]), float(ad["off_ms"]),
				float(ad["cost_ms"]), float(ad["cost_pct"])]
		s += "\n"
	var hl: Array = r.get("hitch_list", [])
	if not hl.is_empty():
		s += "## Hitches (worst first, what happened)\n| Game time | Frame ms | Top bands | Events |\n|---|---|---|---|\n"
		for h2: Variant in hl.slice(0, 10):
			var hd: Dictionary = h2
			var tops: Array[String] = []
			for t: Variant in hd.get("top", []):
				tops.append("%s %.1f" % [String((t as Dictionary).get("key", "")).get_file(), float((t as Dictionary).get("ms", 0.0))])
			s += "| %s | %.1f | %s | %s |\n" % [str(hd.get("t", "")), float(hd.get("ms", 0.0)), _cell(", ".join(tops)),
				_cell(hd.get("events", ""))]
		s += "\n"
	var mon: Dictionary = r.get("monitors", {})
	if not mon.is_empty():
		s += "## Performance monitors (avg over the measured frames)\nGodot's TIME_* monitors (process_ms, physics_ms, " + \
			"navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.\n\n" + \
			"| Monitor | Value |\n|---|---|\n"
		for k: String in mon:
			s += "| %s | %s |\n" % [k, str(mon[k])]
		s += "\n"
	var ai: Dictionary = r.get("ai", {})
	if not ai.is_empty():
		s += "## AI think ticks (commander.gd counters)\n`%s`\n\n" % JSON.stringify(ai)
	s += "## Notes\n- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, " + \
		"PASS 70-100, WARN 35-69, FAIL 0-34.\n- Frame numbers come from runs without the band profiler; the hot list " + \
		"from one profiled run (marker overhead listed above).\n"
	for n2: Variant in r.get("notes", []):
		s += "- %s\n" % str(n2)
	return s


static func _cell(v: Variant) -> String:
	return str(v).replace("|", "/").replace("\n", " ")


func write(out_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var base := out_dir.path_join("%s_%s" % [scenario, mode])
	var f := FileAccess.open(base + ".md", FileAccess.WRITE)
	if f:
		f.store_string(to_markdown())
		f.close()
	var j := FileAccess.open(base + ".json", FileAccess.WRITE)
	if j:
		j.store_string(JSON.stringify(to_dict(), "\t"))
		j.close()


## The history row of this scorecard (history.jsonl + one table row in history.md).
func history_row() -> Dictionary:
	var f: Dictionary = result.get("frame", {})
	var tops: Array[String] = []
	for h: Variant in (result.get("hot", []) as Array).slice(0, 3):
		tops.append("%s %.2f" % [String((h as Dictionary).get("key", "")).get_file().get_basename(), float((h as Dictionary).get("avg_ms", 0.0))])
	return {"when": String(result.get("started", "")), "commit": String(result.get("commit", "")), "scenario": scenario,
		"mode": mode, "resolution": String(result.get("resolution", "")), "noisy": noisy, "repeats": int(result.get("repeats", 1)),
		"avg": float(f.get("avg", 0.0)), "p95": float(f.get("p95", 0.0)), "p99": float(f.get("p99", 0.0)),
		"max": float(f.get("max", 0.0)), "hitches": int(f.get("hitches", 0)), "units": int(result.get("units_avg", 0)),
		"gpu_ms": float((result.get("gpu", {}) as Dictionary).get("gpu_ms_avg", 0.0)), "score": snappedf(score(), 0.1),
		"verdict": verdict(), "top": ", ".join(tops)}


static func append_history(dir: String, row: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var md := dir.path_join("history.md")
	var exists := FileAccess.file_exists(md)
	var f := FileAccess.open(md, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if f:
		if not exists:
			f.store_string("# Perf Lab history\n\nOne row per scenario and mode per lab run (`tools/perf_lab/run_perf_lab.ps1`, " +
				"docs/plan/perf-lab.md). Frame numbers in ms (median of the repeats). **noisy** rows were measured while other " +
				"Godot processes or programs loaded the CPU: never compare them with quiet rows.\n\n" +
				"| When | Commit | Scenario | Mode | Noise | avg | p95 | p99 | max | Hitches | GPU ms | Units | Score | Result | Top 3 scripts |\n" +
				"|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n")
		else:
			f.seek_end()
		f.store_string("| %s | %s | %s | %s | %s | %.2f | %.2f | %.2f | %.1f | %d | %s | %d | %.0f | %s | %s |\n" % [row["when"],
			row["commit"], row["scenario"], String(row["mode"]) + ((" " + String(row["resolution"])) if String(row["resolution"]) != "" else ""),
			"**noisy**" if bool(row["noisy"]) else "quiet", row["avg"], row["p95"], row["p99"], row["max"], row["hitches"],
			("%.2f" % float(row["gpu_ms"])) if float(row["gpu_ms"]) > 0.0 else "-", row["units"], row["score"], row["verdict"],
			_cell(row["top"])])
		f.close()
	var jl := dir.path_join("history.jsonl")
	var j := FileAccess.open(jl, FileAccess.READ_WRITE if FileAccess.file_exists(jl) else FileAccess.WRITE)
	if j:
		j.seek_end()
		j.store_line(JSON.stringify(row))
		j.close()


## The latest quiet history row of this scenario + mode (+ resolution), {} when none.
static func previous_row(dir: String, p_scenario: String, p_mode: String, resolution: String = "") -> Dictionary:
	var jl := dir.path_join("history.jsonl")
	if not FileAccess.file_exists(jl):
		return {}
	var best := {}
	var f := FileAccess.open(jl, FileAccess.READ)
	while f and not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "":
			continue
		var v: Variant = JSON.parse_string(line)
		if not (v is Dictionary):
			continue
		var d: Dictionary = v
		if String(d.get("scenario", "")) == p_scenario and String(d.get("mode", "")) == p_mode \
				and String(d.get("resolution", "")) == resolution and not bool(d.get("noisy", false)):
			best = d
	return best
