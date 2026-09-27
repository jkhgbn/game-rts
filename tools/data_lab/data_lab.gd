extends SceneTree
## DATA LAB: validates every game data file and writes a scorecard (docs/plan/data-lab.md is the manual).
## Headless, a few seconds:
##   & $GODOT --headless --path . -s res://tools/data_lab/data_lab.gd --quit-after 600 -- [out=<dir>] [log=0] [run=<name>]
## Args after `--` (key=value):
##   out   output folder (default docs/data/lab/<run>/): scorecard.md, scorecard.json
##   run   run name (default: date_time, e.g. 2026-09-26_2310)
##   log   0 = no row in docs/data/lab/history.md
##   ui    0 = skip the hard-coded UI string scan (T7)
## Exit code: 0 PASS / WARN, 1 FAIL. Last lines: `DATA LAB: <RESULT> score <N> ...` and one line per FAIL check.

const Report := preload("res://tools/data_lab/data_lab_report.gd")
const Checks := preload("res://tools/data_lab/data_lab_checks.gd")
const HISTORY := "res://docs/data/lab/history.md"


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var opts := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var code := run(opts)
	quit(code)


## Runs the lab; returns the exit code. Usable from a test (opts: out, run, log, ui).
static func run(opts: Dictionary) -> int:
	var t0 := Time.get_ticks_usec()
	var report := Report.new()
	var now := Time.get_datetime_dict_from_system()
	report.run_id = String(opts.get("run", "%04d-%02d-%02d_%02d%02d" % [now.year, now.month, now.day, now.hour, now.minute]))
	report.started = "%04d-%02d-%02d %02d:%02d" % [now.year, now.month, now.day, now.hour, now.minute]
	var out_dir := String(opts.get("out", "res://docs/data/lab/" + report.run_id))
	var log_on := String(opts.get("log", "1")) != "0"
	if log_on:
		report.previous_score = Report.read_previous(HISTORY)
	var checks := Checks.new(report)
	checks.scan_ui = String(opts.get("ui", "1")) != "0"
	checks.load_all()
	var t_load := Time.get_ticks_usec()
	checks.run_checks()
	report.notes.append("Load %.2f s (every .tres with its model scenes), checks %.2f s." % [
		float(t_load - t0) / 1000000.0, float(Time.get_ticks_usec() - t_load) / 1000000.0])
	report.seconds = float(Time.get_ticks_usec() - t0) / 1000000.0
	report.write(out_dir)
	if log_on:
		report.append_history(HISTORY, out_dir)
	print("DATA LAB: %s score %.0f / 100 (%d FAIL, %d WARN, %d PASS checks; %d FAIL, %d WARN findings) %.2f s -> %s" % [
		report.result(), report.quality(), report.count("FAIL"), report.count("WARN"), report.count("PASS"),
		report.count_findings("FAIL"), report.count_findings("WARN"), report.seconds, out_dir.path_join("scorecard.md")])
	for c: Dictionary in report.checks:
		if c["status"] == "FAIL" or c["status"] == "WARN":
			print("  %s %s %s: %s" % [c["status"], c["id"], c["name"], c["value"]])
	return report.exit_code()
