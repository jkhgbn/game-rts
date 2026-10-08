extends SceneTree
## Every speaker id used by a dialogue line in data/voice/lines/*.json has a Speakers.TABLE row (shown name + colour).
## Unit barks (`unit_*` ids, data/voice/lines/unit_barks.json) have no subtitle box and are skipped.
## Run: godot --headless --path . -s tests/test_speakers.gd --quit-after 600

const TASK_ID := "speakers"
const LINES_DIR := "res://data/voice/lines/"


func _initialize() -> void:
	var missing := {}
	var files := 0
	for f in DirAccess.get_files_at(LINES_DIR):
		if not f.ends_with(".json"):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(LINES_DIR + f))
		if not (data is Dictionary):
			print("  x %s does not parse" % f)
			missing["<parse " + f + ">"] = true
			continue
		files += 1
		for line in data.get("lines", []):
			var id := String(line.get("speaker", ""))
			if id == "" or id.begins_with("unit_"):
				continue
			if not Speakers.has(StringName(id)):
				missing["%s (%s)" % [id, f]] = true
	for id in ["rider", "gannet", "reeve", "herald", "dacian", "seraphine", "brannet", "diamond_archon", "ossavar", "child"]:
		if not Speakers.has(StringName(id)):
			missing[id] = true
		elif Speakers.color_of(StringName(id)) == Speakers.DEFAULT_COLOR:
			missing[id + " (default colour)"] = true
	if files == 0:
		print("FAIL %s: no line files found" % TASK_ID)
	elif missing.is_empty():
		print("PASS %s (%d line files)" % [TASK_ID, files])
	else:
		print("FAIL %s: speakers with no table row: %s" % [TASK_ID, ", ".join(PackedStringArray(missing.keys()))])
	quit()
