extends SceneTree
## Playtest analyzer entry (docs/design/health-and-playtests.md). Use tools\playtest\analyze.ps1, or:
##   godot --headless --path . -s tools/playtest/analyze.gd --quit-after 3000 ++ [files=a.jsonl,b.jsonl] [dir=<folder>]
##        [latest=N] [name=<report name>] [out=<folder>]
## Default input: every *.jsonl in user://playtests/ (the game's recordings). Default out: docs/playtests/.
## Writes <out>/<name>.md + <name>_fights.png + <name>_deaths.png; prints "PLAYTEST REPORT: <path>".

const Analyzer := preload("res://tools/playtest/playtest_analyzer.gd")


func _initialize() -> void:
	var opts := {}
	for a in OS.get_cmdline_user_args():
		var s := String(a).trim_prefix("--")
		opts[s.get_slice("=", 0)] = s.get_slice("=", 1) if s.contains("=") else "1"
	var paths: Array[String] = []
	if opts.has("files"):
		for f in String(opts["files"]).split(",", false):
			paths.append(f.strip_edges())
	else:
		var dir := String(opts.get("dir", "user://playtests"))
		if DirAccess.dir_exists_absolute(dir):
			for f in DirAccess.get_files_at(dir):
				if f.ends_with(".jsonl"):
					paths.append(dir.path_join(f))
		paths.sort_custom(func(a: String, b: String) -> bool:
			return FileAccess.get_modified_time(a) < FileAccess.get_modified_time(b))
		if opts.has("latest"):
			paths = paths.slice(maxi(paths.size() - int(opts["latest"]), 0))
	if paths.is_empty():
		print("PLAYTEST REPORT: FAIL no recordings (turn on Settings > Playtest data, play a match; or pass files=)")
		quit(1)
		return
	var name := String(opts.get("name", paths[0].get_file().get_basename() if paths.size() == 1
			else "playtests_%s_%d" % [Time.get_date_string_from_system(), paths.size()]))
	var out := String(opts.get("out", ProjectSettings.globalize_path("res://docs/playtests")))
	var res := Analyzer.report(paths, out, name)
	var md_path := out.path_join(name + ".md")
	var f := FileAccess.open(md_path, FileAccess.WRITE)
	if f:
		f.store_string(String(res["md"]))
		f.close()
	for e in res["errors"]:
		print("PLAYTEST SCHEMA: %s" % e)
	print("PLAYTEST REPORT: %s (%d recordings)" % [md_path, int(res["recordings"])])
	quit(0)
