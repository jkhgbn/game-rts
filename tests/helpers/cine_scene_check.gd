class_name CineSceneCheck
extends RefCounted
## Checks of an in-mission scene (a mode=pause .cine in data/cinematics/src/, baked to data/cinematics/<id>.tres) for the
## per-mission cine tests (tests/test_cine_<mission>.gd): cine's own checks (parse, resolve, timing, framing, continuity,
## subtitles: 0 FAIL; V1 "not voiced" stays a WARN), the baked script (PAUSE, no stage, the .cine's length, the same
## shots), the mission script calls play_cutscene with that id, and every subtitle is a line of that mission script
## (so its French is in data/i18n/fr/campaign.po) with a French translation.
## Use:  var errs := CineSceneCheck.check(root, "e3m1_ford", "res://scripts/campaign/mission_e3_01.gd")

const PO_FILES := ["res://data/i18n/fr/campaign.po", "res://data/i18n/fr/dialogue.po"]

static var _fr_cache: Dictionary = {}


## Errors ([] = pass) of the scene `id` played by the mission script `mission_script`.
static func check(root: Node, id: String, mission_script: String) -> Array[String]:
	var errs: Array[String] = []
	var src := CineDoc.source_of(id)
	if not FileAccess.file_exists(src):
		errs.append("%s: no source %s" % [id, src])
		return errs
	var doc := CineDoc.load_file(src)
	if doc.world_mode != "pause":
		errs.append("%s: header mode=%s, want pause (in-mission)" % [id, doc.world_mode])
	var stage := CineStage.new()
	root.add_child(stage)
	stage.build(doc)
	var bake := CineBake.run(doc, stage)
	var ev := CineEval.create(bake.shots, stage.actor_start)
	var rep := ToolReport.start("cine", "check", id)
	CineChecks.add_groups(rep)
	CineChecks.problems(doc, stage, bake, rep)
	CineChecks.timing(doc, bake, ev, rep)
	CineChecks.framing(bake, ev, rep)
	CineChecks.continuity(bake, ev, rep)
	CineChecks.subtitles(doc, bake, rep)
	if rep.count("FAIL") > 0:
		errs.append("%s: cine check FAIL %s" % [id, rep.problem_lines()])
	stage.queue_free()
	# the baked script
	var cs := CinematicScript.find(StringName(id))
	if cs == null:
		errs.append("%s: data/cinematics/%s.tres missing (run_cine.ps1 build %s)" % [id, id, id])
	else:
		if cs.world_mode != CinematicScript.WorldMode.PAUSE:
			errs.append("%s: baked world_mode %d, want PAUSE" % [id, cs.world_mode])
		if cs.stage_scene != "":
			errs.append("%s: an in-mission scene names a stage (%s)" % [id, cs.stage_scene])
		if cs.shots.size() != doc.shots.size():
			errs.append("%s: .tres has %d shots, the .cine %d (rebuild it)" % [id, cs.shots.size(), doc.shots.size()])
		var total := cs.total_duration()
		if total < doc.length_range.x - 0.01 or total > doc.length_range.y + 0.01:
			errs.append("%s: %.1f s outside length %s" % [id, total, doc.length_range])
		if not cs.skippable:
			errs.append("%s: not skippable" % id)
	# the mission plays it, and every subtitle is one of its lines with a French translation
	var code := FileAccess.get_file_as_string(mission_script)
	if code == "":
		errs.append("%s: cannot read %s" % [id, mission_script])
		return errs
	if not ("&\"%s\"" % id) in code:
		errs.append("%s: %s never plays it" % [id, mission_script.get_file()])
	for s: Dictionary in doc.shots:
		for ln: Dictionary in s.get("lines", []):
			var text := String(ln.get("text", ""))
			if not ("\"%s\"" % text.replace("\\", "\\\\").replace("\"", "\\\"")) in code:
				errs.append("%s: line \"%s\" is not a line of %s" % [id, text, mission_script.get_file()])
			elif _french(text) == "":
				errs.append("%s: line \"%s\" has no French" % [id, text])
	return errs


## The French of `text` in the campaign / dialogue .po files ("" = none).
static func _french(text: String) -> String:
	if _fr_cache.is_empty():
		for p: String in PO_FILES:
			var lines := FileAccess.get_file_as_string(p).split("\n")
			for i in lines.size() - 1:
				var l := lines[i]
				if l.begins_with("msgid \"") and lines[i + 1].begins_with("msgstr \""):
					var k := l.substr(7, l.length() - 8).c_unescape()
					var v := lines[i + 1].substr(8, lines[i + 1].length() - 9).c_unescape()
					if v != "":
						_fr_cache[k] = v
	return String(_fr_cache.get(text, ""))
