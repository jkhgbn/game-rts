extends SceneTree
## Bot Lab smoke test (docs/plan/bot-lab.md): two short sim matches run as their own Godot processes (the way
## run_lab.ps1 runs them), each must write a valid JSON line; then lab_report.gd must turn them into report.md and
## report.html. Checks the whole pipeline except the PowerShell loop.
## Run:  godot --headless --path . -s tests/test_bot_lab.gd --fixed-fps 60 --quit-after 60000
## (--quit-after only guards this process: it waits in real time for its two children, up to TIMEOUT_S.)

const TASK_ID := "bot lab"
const MATCH_SCRIPT := "res://tools/bot_lab/lab_match.gd"
const REPORT_SCRIPT := "res://tools/bot_lab/lab_report.gd"
const LIMIT_S := 120          ## Game seconds per match.
const TIMEOUT_S := 900.0      ## Real seconds for both matches.
const MATCHES := [["fire:ice", 1], ["nature:shadow", 2]]

var _dir := ""
var _pids: Array[int] = []
var _outs: Array[String] = []
var _pending: Array[PackedStringArray] = []
var _t0 := 0


## User arg "--serial" (after "--"): the two matches run one after the other (one child at a time: for a shared PC).
func _initialize() -> void:
	_dir = ProjectSettings.globalize_path("user://bot_lab_test")
	DirAccess.make_dir_recursive_absolute(_dir)
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	var project := ProjectSettings.globalize_path("res://")
	for m: Array in MATCHES:
		var out := _dir.path_join("%s_s%d.json" % [String(m[0]).replace(":", "-"), int(m[1])])
		_outs.append(out)
		_pending.append(PackedStringArray(["--headless", "--path", project, "-s", MATCH_SCRIPT, "--fixed-fps", "60",
				"--quit-after", str((LIMIT_S + 240) * 60), "--", "--pair=%s" % m[0], "--seed=%d" % int(m[1]), "--sim=1",
				"--limit=%d" % LIMIT_S, "--early=0", "--out=%s" % out]))
	var serial := OS.get_cmdline_user_args().has("--serial")
	_t0 = Time.get_ticks_msec()
	while not _pending.is_empty() and (_pids.is_empty() or not serial):
		if not _launch_next():
			return
	print("bot lab test: %d match(es) started%s (%s), %d game s each" % [_pids.size(), ", serial" if serial else "", _dir, LIMIT_S])


func _launch_next() -> bool:
	var exe := OS.get_executable_path()
	var pid := OS.create_process(exe, _pending.pop_front())
	if pid <= 0:
		print("FAIL %s: could not start %s" % [TASK_ID, exe])
		quit(1)
		return false
	_pids.append(pid)
	return true


func _process(_delta: float) -> bool:
	for pid in _pids:
		if OS.is_process_running(pid):
			if (Time.get_ticks_msec() - _t0) / 1000.0 > TIMEOUT_S:
				print("FAIL %s: matches still running after %d s" % [TASK_ID, int(TIMEOUT_S)])
				for p in _pids:
					if OS.is_process_running(p):
						OS.kill(p)   # our own children only
				return true
			OS.delay_msec(200)
			return false
	if not _pending.is_empty():   # serial: the next match
		_launch_next()
		return false
	return _check()


func _check() -> bool:
	var lines: Array[String] = []
	for out in _outs:
		if not FileAccess.file_exists(out):
			print("FAIL %s: no result file %s" % [TASK_ID, out])
			return true
		var line := FileAccess.get_file_as_string(out).strip_edges()
		var r: Variant = JSON.parse_string(line)
		if not (r is Dictionary):
			print("FAIL %s: bad JSON in %s" % [TASK_ID, out])
			return true
		var d: Dictionary = r
		for key in ["pair", "seed", "winner_team", "end_reason", "end_time", "score", "stats", "sim", "real_s", "speed"]:
			if not d.has(key):
				print("FAIL %s: %s has no '%s'" % [TASK_ID, out.get_file(), key])
				return true
		if String(d["sim"]) == "off":
			print("FAIL %s: sim mode was off" % TASK_ID)
			return true
		if not ["kill", "concede", "time-score", "stall", "early-score"].has(String(d["end_reason"])):
			print("FAIL %s: end reason %s" % [TASK_ID, d["end_reason"]])
			return true
		if String(d["end_reason"]) == "time-score" and float(d["end_time"]) < LIMIT_S - 1:
			print("FAIL %s: time-score before the limit (%s)" % [TASK_ID, d["end_time"]])
			return true
		print("  %s seed %d: %s, winner %s at %s, x%.1f, %.0f s real" % [d["pair"], int(d["seed"]), d["end_reason"],
				d["winner"], d["end_clock"], float(d["speed"]), float(d["real_s"])])
		lines.append(line)
	# The same two matches again as a second arm ("arm" = what run_lab.ps1 -Validate adds): exercises the arms table.
	var arm_lines: Array[String] = []
	for arm in ["normal", "sim"]:
		for line in lines:
			arm_lines.append("{\"arm\":\"%s\",%s" % [arm, line.substr(1)])
	var jsonl := _dir.path_join("results.jsonl")
	var f := FileAccess.open(jsonl, FileAccess.WRITE)
	f.store_string("\n".join(arm_lines) + "\n")
	f.close()
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(), PackedStringArray(["--headless", "--path",
			ProjectSettings.globalize_path("res://"), "-s", REPORT_SCRIPT, "--quit-after", "600", "--",
			"--in=%s" % jsonl, "--out=%s" % _dir, "--title=Bot Lab test"]), out, true)
	var md := _dir.path_join("report.md")
	var html := _dir.path_join("report.html")
	if code != 0 or not FileAccess.file_exists(md) or not FileAccess.file_exists(html):
		print("FAIL %s: report not written (exit %d)" % [TASK_ID, code])
		return true
	var text := FileAccess.get_file_as_string(md)
	for section in ["Win % matrix", "How matches ended", "## Arms", "## Start-up", "## Next steps"]:
		if not text.contains(section):
			print("FAIL %s: report.md has no '%s'" % [TASK_ID, section])
			return true
	if not text.contains("| sim | 2 |") or not text.contains("+0.0 %"):
		print("FAIL %s: arms table wrong (two identical arms must show N 2 and a +0.0 %% delta)" % TASK_ID)
		return true
	# run_lab.ps1 -Short (the 10-minute validation): the dry run must plan 6 matches (1 pair x 2 seeds x 3 arms, 330 s).
	if OS.get_name() == "Windows":
		var ps_out: Array = []
		OS.execute("powershell", PackedStringArray(["-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
				ProjectSettings.globalize_path("res://tools/bot_lab/run_lab.ps1"), "-Short", "-DryRun"]), ps_out, true)
		var plan := "".join(ps_out)
		if not plan.contains("Bot Lab: 6 matches") or not plan.contains("limit 330") or not plan.contains("[sim30]"):
			print("FAIL %s: run_lab.ps1 -Short -DryRun plan wrong: %s" % [TASK_ID, plan.substr(0, 300)])
			return true
	print("PASS %s (%s)" % [TASK_ID, md])
	return true
