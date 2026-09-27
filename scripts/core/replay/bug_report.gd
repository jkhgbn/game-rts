extends RefCounted
## Replay Lab (docs/plan/replay-lab.md): "Save bug report" (F8 in a skirmish, ReplaySession.save_bug_report).
## Writes user://bug_reports/bug_<date>.zip with:
##   replay.replay   the match so far (header + commands + hashes; replay it with tools/replay_lab/replay_match.gd)
##   log.txt         the last LOG_LINES lines of user://logs/godot.log
##   settings.cfg    user://settings.cfg (volume, controls, map detail, time limit...)
##   screenshot.png  the current frame (not in headless runs)
##   info.json       game version, Godot version, OS, GPU, match time, frame
## Nothing is ever uploaded: the user copies the zip by hand (OneDrive).

const DIR := "user://bug_reports"
const LOG_PATH := "user://logs/godot.log"
const SETTINGS_PATH := "user://settings.cfg"
const LOG_LINES := 2000


## Returns the zip path ("" on failure).
static func save(tree: SceneTree, session: Object) -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := "%s/bug_%s.zip" % [DIR, stamp]
	var zip := ZIPPacker.new()
	if zip.open(path) != OK:
		push_warning("Bug report: can't write %s" % path)
		return ""
	if session != null and is_instance_valid(session) and session.has_method(&"text"):
		_add(zip, "replay.replay", str(session.call(&"text")).to_utf8_buffer())
	_add(zip, "log.txt", last_log_lines(LOG_LINES).to_utf8_buffer())
	if FileAccess.file_exists(SETTINGS_PATH):
		_add(zip, "settings.cfg", FileAccess.get_file_as_bytes(SETTINGS_PATH))
	var png := _screenshot(tree)
	if not png.is_empty():
		_add(zip, "screenshot.png", png)
	_add(zip, "info.json", JSON.stringify(_info(tree, session), "  ").to_utf8_buffer())
	zip.close()
	print("Bug report saved: %s" % ProjectSettings.globalize_path(path))
	return path


static func last_log_lines(count: int) -> String:
	var text := FileAccess.get_file_as_string(LOG_PATH)
	if text == "":
		return "(no log file at %s: enable application/run/file_logging)\n" % LOG_PATH
	var lines := text.split("\n")
	var start := maxi(0, lines.size() - count)
	return "\n".join(lines.slice(start))


static func _add(zip: ZIPPacker, name: String, data: PackedByteArray) -> void:
	zip.start_file(name)
	zip.write_file(data)
	zip.close_file()


static func _screenshot(tree: SceneTree) -> PackedByteArray:
	if DisplayServer.get_name() == "headless" or tree == null or tree.root == null:
		return PackedByteArray()
	var tex := tree.root.get_texture()
	if tex == null:
		return PackedByteArray()
	var img := tex.get_image()
	return img.save_png_to_buffer() if img != null else PackedByteArray()


static func _info(tree: SceneTree, session: Object) -> Dictionary:
	var info := {"engine": Engine.get_version_info().get("string", ""), "os": OS.get_name(),
			"os_version": OS.get_version(), "gpu": RenderingServer.get_video_adapter_name(),
			"cpu": OS.get_processor_name(), "date": Time.get_datetime_string_from_system()}
	if session != null and is_instance_valid(session):
		info["game"] = str(session.call(&"game_version")) if session.has_method(&"game_version") else ""
		info["frame"] = session.get(&"frame")
		info["seed"] = session.get(&"match_seed")
		var lvl: Variant = session.get(&"level")
		if lvl is Object and is_instance_valid(lvl) and (lvl as Object).has_method(&"match_time"):
			info["match_time"] = snappedf(float((lvl as Object).call(&"match_time")), 0.01)
	return info
