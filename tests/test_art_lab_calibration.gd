extends SceneTree
# error_lab: verdict=last (planted-bad cases print inner "FAIL ..." lines; the final PASS / FAIL line decides)
## Art Lab v3 calibration ("lab-on-lab") test, task 1.C (docs/plan/art-lab.md "Calibration").
## Runs the 12 calibration cases (tools/art_lab/calibration/calibration.gd: 6 good finished assets + 6 planted-bad
## variants built in memory from real assets) as ONE Art Lab batch in this process, then judges every scorecard
## against its band (quality range, result, the planted check, no new WARN / FAIL). A rule or threshold change that
## moves a known case out of its band fails the test.
## Windowed (the real judge, ~4-5 min on the laptop):
##   .\tools\godot_run.ps1 --path . -s tests/test_art_lab_calibration.gd --quit-after 400000
## Headless (budgets / health / geometry only; render checks SKIP, no quality band, ~2 min):
##   .\tools\godot_run.ps1 --headless --path . -s tests/test_art_lab_calibration.gd --quit-after 400000
## Args after `--`: only=<case,case> (a subset), keep=1 (keep going after a batch error).
## Prints "PASS art_lab_calibration" or "FAIL art_lab_calibration: <cases out of band>".

const TASK_ID := "art_lab_calibration"
const WATCHDOG_S := 900.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(WATCHDOG_S).timeout.connect(func() -> void:
		print("FAIL %s: watchdog (%d s)" % [TASK_ID, int(WATCHDOG_S)])
		quit(3))
	var t0 := Time.get_ticks_msec()
	var opts := {}
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		opts[s.get_slice("=", 0)] = s.substr(s.find("=") + 1) if "=" in s else "1"
	var only := PackedStringArray()
	if opts.has("only"):
		only = String(opts["only"]).split(",", false)
	var headless := DisplayServer.get_name() == "headless"
	var err := ArtLabCalibration.register_plants(only)
	if err != "":
		print("FAIL %s: planted variants: %s" % [TASK_ID, err])
		quit(1)
		return
	var list := ArtLabCalibration.entries(only)
	if list.is_empty():
		print("FAIL %s: no case matches only=%s" % [TASK_ID, opts.get("only", "")])
		quit(1)
		return
	# old scorecards must not be judged if a case errors before writing its own
	for e: PackedStringArray in list:
		var id := String(e[e.size() - 1]).trim_prefix("name=")
		var p := ProjectSettings.globalize_path(ArtLabCalibration.out_root(headless).path_join(id).path_join("scorecard.json"))
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	var shared := {"quick": "1", "log": "0", "out_root": ArtLabCalibration.out_root(headless)}
	if headless:
		# uncapped headless frames run out the lab's frame guards (A2 waits <= 600 frames for death_finished) before
		# the 2-3 s they stand for: cap like a windowed batch
		Engine.max_fps = 120
	print("ART LAB CALIBRATION: %d cases (%s)" % [list.size(), "headless" if headless else "windowed"])
	var res: Dictionary = await ArtLabBatch.run_all(root, list, shared)
	var total := float(Time.get_ticks_msec() - t0) / 1000.0
	var rows: Array[Dictionary] = []
	var bad: Array[String] = []
	for e2: PackedStringArray in list:
		var cid := String(e2[e2.size() - 1]).trim_prefix("name=")
		var c := ArtLabCalibration.case_of(cid)
		var mes := ArtLabCalibration.measured(cid, ArtLabCalibration.out_root(headless))
		var problems := ArtLabCalibration.judge(c, mes, headless)
		var alarms: Array[String] = []
		if not mes.is_empty():
			for k: String in mes["checks"]:
				var st := String(mes["checks"][k]["status"])
				if st == "WARN" or st == "FAIL":
					alarms.append("%s %s" % [st, k])
		var band: Array = c["quality"]
		rows.append({"id": cid, "plant": c["plant"], "result": mes.get("result", "-"), "quality": float(mes.get("quality", -1.0)),
			"band": "%.0f-%.0f" % [float(band[0]), float(band[1])], "alarms": ", ".join(alarms), "problems": problems,
			"seconds": float(mes.get("seconds", 0.0))})
		print("  %-26s %-4s q %5.1f band %-7s %5.1f s  %s%s" % [cid, mes.get("result", "-"), float(mes.get("quality", -1.0)),
			"%.0f-%.0f" % [float(band[0]), float(band[1])], float(mes.get("seconds", 0.0)), ", ".join(alarms),
			"" if problems.is_empty() else "  <- OUT: " + "; ".join(problems)])
		if not problems.is_empty():
			bad.append("%s (%s)" % [cid, "; ".join(problems)])
	var md := ArtLabCalibration.summary_md(rows, total, headless)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ArtLabCalibration.out_root(headless)))
	var f := FileAccess.open(ArtLabCalibration.out_root(headless).path_join("calibration.md"), FileAccess.WRITE)
	if f:
		f.store_string(md)
		f.close()
	print(ArtLabBatch.summary(res, total))
	if bad.is_empty():
		print("PASS %s (%d cases in band, %s, %.0f s)" % [TASK_ID, list.size(), "headless: render checks not judged" if headless else "windowed", total])
		quit(0)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(bad)])
		quit(1)
