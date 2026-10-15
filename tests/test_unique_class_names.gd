extends SceneTree
## Root-cause test (2026-10-15): two scripts with the same `class_name` make the global class cache point at whichever
## was imported last, and every script using the other one stops parsing (graphics week: art/units/ice/ice_shapes.gd
## and art/buildings/ice_hall_shapes.gd both declared IceShapes; every Ice building broke).
## Scans every .gd under res:// (skips .godot / addons) and fails on a class_name declared twice or equal to an autoload.
## Run: $GODOT --headless --path . -s tests/test_unique_class_names.gd --quit-after 600
## Prints "PASS unique_class_names" or "FAIL unique_class_names: <reasons>".

const TASK_ID := "unique_class_names"
const SKIP_DIRS: Array[String] = [".godot", "addons", ".git"]

var _seen: Dictionary = {}   # class name -> first path
var _fails: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var autoloads: Dictionary = {}
	for prop: Dictionary in ProjectSettings.get_property_list():
		var key: String = prop.get("name", "")
		if key.begins_with("autoload/"):
			autoloads[key.trim_prefix("autoload/")] = true
	_scan("res://")
	for cls: String in _seen:
		if autoloads.has(cls):
			_fails.append("%s (%s) equals an autoload" % [cls, _seen[cls]])
	if _fails.is_empty():
		print("PASS %s (%d classes)" % [TASK_ID, _seen.size()])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _scan(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f: String in d.get_files():
		if f.get_extension() == "gd":
			_check_file(dir.path_join(f))
	for sub: String in d.get_directories():
		if sub in SKIP_DIRS or sub.begins_with("."):
			continue
		if FileAccess.file_exists(dir.path_join(sub).path_join(".gdignore")):
			continue
		_scan(dir.path_join(sub))


func _check_file(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	for line: String in text.split("\n"):
		var s := line.strip_edges()
		if not s.begins_with("class_name "):
			continue
		var cls := s.trim_prefix("class_name ").split(" ")[0].strip_edges()
		if _seen.has(cls):
			_fails.append("%s declared in %s and %s" % [cls, _seen[cls], path])
		else:
			_seen[cls] = path
		return
