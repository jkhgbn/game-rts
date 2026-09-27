extends SceneTree
## Replay Lab test (docs/plan/replay-lab.md). Runs tools/replay_lab/replay_match.gd in child Godot processes
## (a replay always starts from a fresh process, like replaying a file later):
##   1. script: a 3-minute match where the player side gets orders through the real SelectionManager API (recorded
##      like a human's), then replayed headless: the checkpoint hashes (every 300 frames) and the end hash must match.
##   2. bots: the same bot-vs-bot seed recorded twice: the two hash streams must be equal (determinism), and the
##      first record replayed from its file must match too.
## Run:  godot --headless --path . -s tests/test_replay_lab.gd --quit-after 8000
## (children go through tools/godot_run.ps1 when it exists: max 4 Godot runs at once for everyone)
## (no --fixed-fps needed here: this script only waits; each child gets --fixed-fps 60.) ~6-10 min.
## Prints "PASS replay_lab" or "FAIL replay_lab: <reasons>"; part results as "REPLAY_LAB ..." lines.

const TASK_ID := "replay_lab"
const RUNNER := "res://tools/replay_lab/replay_match.gd"
const MINUTES := "3"
const OUT_DIR := "user://replay_lab_test"
const GATE := "res://tools/godot_run.ps1"

var _phase := 0
var _pids: Array[int] = []
var _results := {}
var _fails: Array[String] = []
var _t0 := 0


func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for f in DirAccess.get_files_at(OUT_DIR):
		DirAccess.remove_absolute(OUT_DIR + "/" + f)
	_launch("script_rec", ["--mode=script", "--seed=7", "--minutes=" + MINUTES, "--sim=1", "--out=" + _p("script.replay")])
	_launch("bots_a", ["--mode=bots", "--seed=3", "--minutes=" + MINUTES, "--sim=1", "--out=" + _p("bots_a.replay")])
	_launch("bots_b", ["--mode=bots", "--seed=3", "--minutes=" + MINUTES, "--sim=1", "--out=" + _p("bots_b.replay")])
	_phase = 1


func _p(name: String) -> String:
	return OUT_DIR + "/" + name


func _launch(id: String, user_args: Array) -> void:
	var a := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", RUNNER,
			"--fixed-fps", "60", "--quit-after", "60000", "++"])   # "++" = Godot's user-args separator ("--" is eaten by PowerShell)
	a.append_array(PackedStringArray(user_args))
	a.append("--result=" + _p(id + ".json"))   # user:// (no spaces on the command line)
	var pid := -1
	var gate := ProjectSettings.globalize_path(GATE)
	if OS.get_name() == "Windows" and FileAccess.file_exists(GATE):
		# Through the Godot gate (max 4 runs at once for every agent / lab): powershell -File tools/godot_run.ps1 <args>
		var pa := PackedStringArray(["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", gate])
		pa.append_array(a)
		pid = OS.create_process("powershell.exe", pa)
	else:
		pid = OS.create_process(OS.get_executable_path(), a)
	if pid <= 0:
		_fails.append("%s: could not start Godot" % id)
	_pids.append(pid)
	_results[id] = null


func _process(_delta: float) -> bool:
	OS.delay_msec(250)   # this script only waits for the children
	for id: String in _results:
		if _results[id] == null and FileAccess.file_exists(_p(id + ".json")):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(_p(id + ".json")))
			_results[id] = d if d is Dictionary else {"ok": false, "error": "bad result file"}
			print("REPLAY_LAB %s: %s" % [id, JSON.stringify(_results[id])])
	for id: String in _results:
		if _results[id] == null:
			if Time.get_ticks_msec() - _t0 > 1500000:
				return _finish(["timed out waiting for %s" % id])
			return false
	if _phase == 1:
		_phase = 2
		_launch("script_play", ["--mode=play", "--file=" + _p("script.replay")])
		_launch("bots_play", ["--mode=play", "--file=" + _p("bots_a.replay")])
		return false
	return _finish(_verdict())


func _verdict() -> Array[String]:
	var fails: Array[String] = _fails.duplicate()
	var sp: Dictionary = _results.get("script_play", {})
	if not bool(sp.get("ok", false)):
		fails.append("script replay does not match (%s)" % JSON.stringify(sp.get("divergence", sp.get("error", ""))))
	else:
		print("REPLAY_LAB script replay OK: %d/%d checkpoints + end hash" % [int(sp["checks_ok"]), int(sp["checks"])])
	var cmds := _count(_p("script.replay"), "cmd")
	if cmds < 5:
		fails.append("script replay recorded only %d commands" % cmds)
	var a := _hashes(_p("bots_a.replay"))
	var b := _hashes(_p("bots_b.replay"))
	var first := -1
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			first = i
			break
	if a.is_empty() or a.size() != b.size() or first >= 0:
		fails.append("bot-vs-bot seed 3 is not deterministic: first different checkpoint %s (%d vs %d checkpoints)" %
				[str(a[first]["f"]) if first >= 0 else "-", a.size(), b.size()])
		if first >= 0:
			print("REPLAY_LAB bots diverge at frame %s: %s" % [str(a[first]["f"]), _diff(a[first]["s"], b[first]["s"])])
	else:
		print("REPLAY_LAB bots deterministic: %d checkpoints + end hash equal" % a.size())
	var bp: Dictionary = _results.get("bots_play", {})
	if not bool(bp.get("ok", false)):
		fails.append("bot replay from file does not match (%s)" % JSON.stringify(bp.get("divergence", bp.get("error", ""))))
	return fails


func _hashes(path: String) -> Array:
	var out := []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "":
			continue
		var d: Variant = JSON.parse_string(line)
		if d is Dictionary and (String(d.get("k", "")) == "hash" or String(d.get("k", "")) == "end"):
			out.append({"f": int(d["f"]), "h": String(d["h"]), "s": d.get("s", {})})
	return out


func _count(path: String, kind: String) -> int:
	var n := 0
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return 0
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "":
			continue
		var d: Variant = JSON.parse_string(line)
		if d is Dictionary and String(d.get("k", "")) == kind:
			n += 1
	return n


func _diff(a: Dictionary, b: Dictionary) -> String:
	var out := []
	for k in a:
		if JSON.stringify(a[k]) != JSON.stringify(b.get(k)):
			out.append("%s %s vs %s" % [k, JSON.stringify(a[k]), JSON.stringify(b.get(k))])
	return "; ".join(PackedStringArray(out))


func _finish(fails: Array) -> bool:
	print("REPLAY_LAB took %.0f s" % ((Time.get_ticks_msec() - _t0) / 1000.0))
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(PackedStringArray(fails))])
	return true
