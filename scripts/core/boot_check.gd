class_name BootCheck
extends RefCounted
## Exported-build check (2026-10-14): the exported game compiles GDScript stricter than the editor (a bare free() broke
## items / champions / helpers in two playtest builds while every test passed). `FourWizards.exe --headless -- --boot-check`
## loads every class_name script and every scene under scenes/ and missions/, prints "BOOT CHECK scripts=N scenes=M",
## then quits; any broken script shows as SCRIPT ERROR / Parse Error on stderr (the playtest-release skill fails on it).
## Started by the Events autoload; does nothing without the argument.

const SCENE_DIRS: Array[String] = ["res://scenes", "res://missions"]


static func wanted() -> bool:
	return OS.get_cmdline_user_args().has("--boot-check")


static func run(tree: SceneTree) -> void:
	var scripts := 0
	for c: Dictionary in ProjectSettings.get_global_class_list():
		var path := String(c.get("path", ""))
		if path.begins_with("res://addons/") or path.begins_with("res://tests/") or path.begins_with("res://tools/"):
			continue
		if ResourceLoader.exists(path) and load(path) != null:
			scripts += 1
	var scenes := 0
	for dir: String in SCENE_DIRS:
		scenes += _load_scenes(dir)
	print("BOOT CHECK scripts=%d scenes=%d" % [scripts, scenes])
	tree.quit(0)


static func _load_scenes(dir: String) -> int:
	var n := 0
	var d := DirAccess.open(dir)
	if d == null:
		return 0
	for sub: String in d.get_directories():
		n += _load_scenes(dir.path_join(sub))
	for f: String in d.get_files():
		# exported packs list "x.tscn.remap" for converted scenes
		var file := f.trim_suffix(".remap")
		if file.ends_with(".tscn") or file.ends_with(".scn"):
			if load(dir.path_join(file)) != null:
				n += 1
	return n
