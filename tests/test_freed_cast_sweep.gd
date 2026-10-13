extends SceneTree
## Freed-object cast sweep (Error Lab: mission_e8_01_fire.gd "Trying to cast a freed object").
## In Godot 4, `v as Unit`, `v is Unit` and `for u: Unit in arr` on a FREED object are runtime errors that abort the
## function. Stored arrays / dictionaries in scripts/campaign/ must check is_instance_valid(v) first.
## Covers: campaign_state.gd, ember_crown.gd, m00_cast.gd, mission_base.gd, mission_00.gd, mission_02.gd,
## mission_03.gd, mission_e2_02.gd, mission_e2_04.gd, mission_e3_02.gd, mission_e3_03.gd, mission_e4_01.gd,
## mission_e4_02.gd, mission_e4_03.gd, mission_e4_04.gd, mission_e5_01.gd, mission_e6_02.gd, mission_e6_03.gd,
## mission_e6_04.gd, mission_e6_base.gd, mission_e7_03.gd, mission_e7_04.gd, mission_e8_base.gd.
## Run: godot --headless --path . -s tests/test_freed_cast_sweep.gd --quit-after 600

const TASK_ID := "freed_cast_sweep"
const DIR := "res://scripts/campaign/"


func _initialize() -> void:
	var fails: Array[String] = []
	# 1. Static: `x is T and is_instance_valid(x)` tests the type of a freed object first (an error): the check
	# must come first. And a cast right before its own validity check (`var u := v as Unit` then
	# `is_instance_valid(u)`) casts the freed value before the check.
	var is_first := RegEx.create_from_string("\\b(\\w+) is [A-Z]\\w* and (not )?is_instance_valid\\(\\1\\)")
	var cast_line := RegEx.create_from_string("^\\s*var (\\w+) := (\\S+) as [A-Z]\\w*\\s*$")
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".gd"):
			continue
		var lines := FileAccess.get_file_as_string(DIR + f).split("\n")
		for i in lines.size():
			if is_first.search(lines[i]):
				fails.append("%s:%d type test before is_instance_valid" % [f, i + 1])
			var m := cast_line.search(lines[i])
			if m and i + 1 < lines.size() and lines[i + 1].contains("is_instance_valid(%s)" % m.get_string(1)) \
					and not _fresh(lines, i, m.get_string(2)):
				fails.append("%s:%d cast before is_instance_valid" % [f, i + 1])
	# 2. Runtime: the Variant helpers return false on a freed unit (no "Trying to cast a freed object").
	var u := Unit.new()
	u.free()
	var e6 := MissionE6Base.new()
	var e8 := MissionE8Base.new()
	if e6.is_breaker(u) or e8.is_host(u):
		fails.append("helpers accept a freed unit")
	e8.tick_kneelers([u])
	e6.free()
	e8.free()
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, ", ".join(fails)])
	quit()


## True when `src` is checked just before, or is a fresh value (a loop variable over a group, a function argument).
func _fresh(lines: PackedStringArray, i: int, src: String) -> bool:
	for j in range(i - 1, maxi(-1, i - 6), -1):
		var l := lines[j].strip_edges()
		if j >= i - 2 and l.contains("is_instance_valid(%s)" % src):
			return true
		if l.begins_with("for %s in get_tree().get_nodes_in_group" % src) or l.begins_with("for %s: Variant in get_tree().get_nodes_in_group" % src):
			return true
		if l.begins_with("func ") and l.contains("(%s:" % src):
			return true
	return false
