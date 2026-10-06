extends SceneTree
## Game Health Dashboard entry (docs/design/health-and-playtests.md). Reads the labs' latest outputs, computes the
## health score, writes docs/health/latest.md + latest.html and appends docs/health/history.jsonl.
## Run through tools\health\run_health.ps1 (or: godot --headless --path . -s tools/health/health.gd --quit-after 3000
## ++ [--out=<dir>] [--no-history]). Prints "HEALTH: <score> / 100" and "HEALTH TOP<n>: ..." lines.

const Core := preload("res://tools/health/health_core.gd")
const Inputs := preload("res://tools/health/health_inputs.gd")
const Report := preload("res://tools/health/health_report.gd")
const Session := preload("res://scripts/core/replay/replay_session.gd")


func _initialize() -> void:
	var opts := {}
	for a in OS.get_cmdline_user_args():
		var s := String(a).trim_prefix("--")
		opts[s.get_slice("=", 0)] = s.get_slice("=", 1) if s.contains("=") else "1"
	var root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var out_dir := String(opts.get("out", root.path_join("docs/health")))
	DirAccess.make_dir_recursive_absolute(out_dir)
	var hist_path := out_dir.path_join("history.jsonl")
	var history := Inputs.read_jsonl(hist_path)
	var comps := Inputs.collect(root)
	var res := Core.compute(comps, history)
	var when := Time.get_datetime_string_from_system(false, true)
	var commit := Session.game_version()
	_write(out_dir.path_join("latest.md"), Report.markdown(res, when, commit))
	_write(out_dir.path_join("latest.html"), Report.html(res, history, when, commit))
	if not opts.has("no-history"):
		var f := FileAccess.open(hist_path, FileAccess.READ_WRITE if FileAccess.file_exists(hist_path) else FileAccess.WRITE)
		if f:
			f.seek_end()
			f.store_line(JSON.stringify(Core.history_row(res, when, commit)))
			f.close()
	print("HEALTH: %s / 100 (coverage %d %%)" % [Report.fmt(float(res["score"])), roundi(float(res["coverage"]) * 100.0)])
	for aid in Core.area_ids():
		print("HEALTH AREA %s: %s" % [aid, Report.fmt(float(res["areas"][aid]["score"]))])
	var i := 1
	for p in res["top3"]:
		print("HEALTH TOP%d: [%s, %.1f pts] %s | %s" % [i, p["area_title"], float(p["impact"]), p["text"], p.get("evidence", "")])
		i += 1
	print("HEALTH: wrote %s" % out_dir.path_join("latest.html"))
	quit(0)


func _write(path: String, txt: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(txt)
		f.close()
