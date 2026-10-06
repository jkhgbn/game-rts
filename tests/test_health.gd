extends SceneTree
## Game Health Dashboard test (docs/design/health-and-playtests.md): score math on synthetic inputs, missing data,
## trend, top-3 ranking, the report pages, and one read of the real labs (must not crash).
## Run:  godot --headless --path . -s tests/test_health.gd --quit-after 3000
## Prints "PASS health" or "FAIL health: <reasons>".

const TASK_ID := "health"
const Core := preload("res://tools/health/health_core.gd")
const Inputs := preload("res://tools/health/health_inputs.gd")
const Report := preload("res://tools/health/health_report.gd")

var _fails: Array[String] = []


func _initialize() -> void:
	_score_math()
	_missing_data()
	_trend()
	_top3()
	_report_and_real_inputs()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.05


func _score_math() -> void:
	# Stability (20): 100 (w3) + 50 (w1) = 87.5. Performance (15): 60. Others: no data.
	var comps := [
		Core.component("a", "stability", "A", 100.0, 3.0),
		Core.component("b", "stability", "B", 50.0, 1.0),
		Core.component("p", "performance", "P", 60.0, 1.0),
	]
	var r := Core.compute(comps)
	_check(_near(float(r["areas"]["stability"]["score"]), 87.5), "stability area %s != 87.5" % r["areas"]["stability"]["score"])
	var want := (87.5 * 20.0 + 60.0 * 15.0) / 35.0
	_check(_near(float(r["score"]), snappedf(want, 0.1)), "health %s != %.1f" % [r["score"], want])
	_check(_near(float(r["coverage"]), 0.35), "coverage %s != 0.35" % r["coverage"])
	_check(r["areas"]["stability"]["status"] == "good" and r["areas"]["performance"]["status"] == "bad",
			"status labels %s / %s" % [r["areas"]["stability"]["status"], r["areas"]["performance"]["status"]])
	# All areas at 100 = 100; clamping.
	var full: Array = []
	for aid in Core.area_ids():
		full.append(Core.component(aid, aid, aid, 140.0))
	_check(_near(float(Core.compute(full)["score"]), 100.0), "all-100 health != 100")
	# Weights sum to 100.
	var w := 0.0
	for a in Core.AREAS:
		w += float(a[2])
	_check(_near(w, 100.0), "area weights sum %s" % w)


func _missing_data() -> void:
	var r := Core.compute([Core.component("x", "art", "X", -1.0)])
	_check(float(r["score"]) < 0.0, "no data should give score -1, got %s" % r["score"])
	_check(r["areas"]["art"]["status"] == "none", "art without data should be 'none'")
	_check((r["top3"] as Array).is_empty(), "no data -> no problems")
	var md := Report.markdown(r, "t", "c")
	_check(md.contains("no data"), "markdown should say 'no data'")
	# An empty project folder: every reader says no data, nothing crashes.
	var tmp := ProjectSettings.globalize_path("user://health_test_empty")
	DirAccess.make_dir_recursive_absolute(tmp)
	var comps := Inputs.collect(tmp)
	var with_data := 0
	for c in comps:
		if float(c["score"]) >= 0.0:
			with_data += 1
	_check(with_data == 0, "empty root gave %d components with data" % with_data)
	_check(not comps.is_empty(), "empty root should still list 'no data' components")
	var r2 := Core.compute(comps)
	_check(float(r2["score"]) < 0.0 and float(r2["coverage"]) == 0.0, "empty root score %s coverage %s" % [r2["score"], r2["coverage"]])
	# Broken JSON is no data, not a crash.
	DirAccess.make_dir_recursive_absolute(tmp.path_join("docs/data/lab/bad"))
	var f := FileAccess.open(tmp.path_join("docs/data/lab/bad/scorecard.json"), FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	var d: Array = Inputs.data(tmp)
	_check(d.size() == 1 and float(d[0]["score"]) < 0.0, "broken data scorecard should be no data")


func _trend() -> void:
	var hist := []
	for s in [60.0, 62.0, 64.0, 66.0, 68.0, 70.0]:
		hist.append({"score": s, "areas": {"stability": s}})
	var r := Core.compute([Core.component("a", "stability", "A", 75.0)], hist)
	var t: Dictionary = r["trend"]
	# Last 5 = 62..70, mean 66 -> +9.
	_check(int(t["runs"]) == 5, "trend runs %s != 5" % t["runs"])
	_check(_near(float(t["prev_mean"]), 66.0), "trend mean %s != 66" % t["prev_mean"])
	_check(_near(float(t["delta"]), 9.0) and t["arrow"] == "up", "trend delta %s %s" % [t["delta"], t["arrow"]])
	_check(_near(float(t["areas"]["stability"]), 9.0), "area trend %s" % t["areas"].get("stability"))
	var r2 := Core.compute([Core.component("a", "stability", "A", 60.0)], [{"score": 60.5, "areas": {}}])
	_check(r2["trend"]["arrow"] == "flat", "a 0.5 drop should be flat")
	_check(Core.compute([Core.component("a", "stability", "A", 60.0)], [])["trend"]["arrow"] == "new", "no history = new")
	var row := Core.history_row(r, "when", "abc")
	_check(row.has("score") and row["areas"].has("stability") and row["top3"] is Array, "history row keys")


func _top3() -> void:
	var comps := [
		# stability (20 of 45 present): gap 50 on the only component -> 20/45*50 = 22.2, split 2 problems 0.75 / 0.25.
		Core.component("s", "stability", "S", 50.0, 1.0, "", "", [Core.problem("S big", "", "", "", 0.75), Core.problem("S small", "", "", "", 0.25)]),
		# balance (15): gap 40 -> 15/45*40 = 13.3
		Core.component("b", "balance", "B", 60.0, 1.0, "", "", [Core.problem("B one")]),
		# maps (10): gap 90 -> 10/45*90 = 20
		Core.component("m", "maps", "M", 10.0, 1.0, "", "", [Core.problem("M one")]),
	]
	var r := Core.compute(comps)
	var top: Array = r["top3"]
	var texts: Array = top.map(func(p: Dictionary) -> String: return String(p["text"]))
	# Impacts: S big 16.7, M 20.0, B 13.3, S small 5.6 -> one per area first: M, S big, B.
	_check(texts == ["M one", "S big", "B one"], "top3 order %s" % [texts])
	_check(_near(float(top[0]["impact"]), 20.0) and _near(float(top[1]["impact"]), 16.67), "top3 impacts %s / %s" % [top[0]["impact"], top[1]["impact"]])
	var all_imp := 0.0
	for p in r["problems"]:
		all_imp += float(p["impact"])
	_check(absf(all_imp - (100.0 - float(r["score"]))) < 0.15, "impacts sum %.2f != health gap %.2f" % [all_imp, 100.0 - float(r["score"])])
	# Fewer areas than 3: the list fills with the next highest.
	var r2 := Core.compute([comps[0]])
	_check((r2["top3"] as Array).size() == 2, "one area with 2 problems -> 2 in top3")


func _report_and_real_inputs() -> void:
	var root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var comps := Inputs.collect(root)
	_check(comps.size() >= 8, "real inputs: %d components" % comps.size())
	var r := Core.compute(comps, [{"time": "x", "score": 50.0, "areas": {}}])
	var html := Report.html(r, [{"time": "x", "score": 50.0}], "now", "abc")
	_check(html.begins_with("<!doctype html>") and html.contains("Top 3 problems") and html.contains("<svg"), "html sections")
	_check(not html.contains("http://") and not html.contains("https://") and not html.contains("<script src"), "html must be self-contained")
	var md := Report.markdown(r, "now", "abc")
	for s in ["# Game Health", "## Top 3 problems", "## Areas", "## Components"]:
		_check(md.contains(s), "markdown misses %s" % s)
