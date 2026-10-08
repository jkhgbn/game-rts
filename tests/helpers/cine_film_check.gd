class_name CineFilmCheck
extends RefCounted
## Checks of a stage film (a between-mission / episode film: `.cine` in data/cinematics/src/, baked to
## data/cinematics/<id>.tres, its stage scenes/cinematics/<id>.tscn written by tools/cine/cine_stage_export.gd) for the
## per-episode film tests (tests/test_cine_ep<N>_films.gd): cine's own checks (parse, resolve, timing, framing,
## continuity, subtitles: 0 FAIL), the baked script (STAGE, names its stage, the .cine's shots and length, skippable),
## the stage exists, and every line is French-translated (data/i18n/fr/dialogue.po / campaign.po) and voiced
## (data/voice/manifest.json, speaker + text). The films of missions not built yet are not in
## CampaignState.STORY_FILMS: they play from the cine tool (`run_cine.ps1 play <id>`) or StoryFilms.play_only.
## Use:  var errs := CineFilmCheck.check(root, "c_e4_refuge", voiced)   (voiced = CineFilmCheck.voiced_lines())
## `report` = true also returns every WARN row (prefixed "WARN ") so a dev run can print them.

const MANIFEST := "res://data/voice/manifest.json"


## "speaker|text" -> true for every voiced line of the manifest.
static func voiced_lines() -> Dictionary:
	var out := {}
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if m is Dictionary:
		var entries: Variant = (m as Dictionary).get("lines", m)
		if entries is Dictionary:
			for k: Variant in entries:
				var e: Variant = entries[k]
				if e is Dictionary and (e as Dictionary).has("text"):
					var d := e as Dictionary
					out["%s|%s" % [d.get("speaker", ""), d["text"]]] = true
					# an alias speaker (cast.json alias_of: obren -> whisper) is named in the line's sources
					for src: Variant in d.get("sources", []):
						if src is Dictionary and (src as Dictionary).has("speaker_id"):
							out["%s|%s" % [(src as Dictionary)["speaker_id"], d["text"]]] = true
	return out


## Errors ([] = pass) of the stage film `id`; `info` collects the length and WARN rows for the dev report.
static func check(root: Node, id: String, voiced: Dictionary, info: Array[String] = []) -> Array[String]:
	var errs: Array[String] = []
	var src := CineDoc.source_of(id)
	if not FileAccess.file_exists(src):
		errs.append("%s: no source %s" % [id, src])
		return errs
	var doc := CineDoc.load_file(src)
	if doc.world_mode == "pause":
		errs.append("%s: header mode=pause, want a stage film" % id)
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
	for l: String in rep.problem_lines():
		info.append("%s: %s" % [id, l])
	stage.queue_free()
	# the baked script and its stage
	var cs := CinematicScript.find(StringName(id))
	if cs == null:
		errs.append("%s: data/cinematics/%s.tres missing (cine_stage_export.gd %s)" % [id, id, id])
	else:
		if cs.world_mode == CinematicScript.WorldMode.PAUSE:
			errs.append("%s: baked as PAUSE, want a stage film" % id)
		if cs.stage_scene != StoryFilms.stage_of(StringName(id)):
			errs.append("%s: baked stage_scene %s, want %s" % [id, cs.stage_scene, StoryFilms.stage_of(StringName(id))])
		if cs.shots.size() != doc.shots.size():
			errs.append("%s: .tres has %d shots, the .cine %d (re-export it)" % [id, cs.shots.size(), doc.shots.size()])
		var total := cs.total_duration()
		info.append("%s: %.1f s, %d shots" % [id, total, cs.shots.size()])
		if total < doc.length_range.x - 0.01 or total > doc.length_range.y + 0.01:
			errs.append("%s: %.1f s outside length %s" % [id, total, doc.length_range])
		if not cs.skippable:
			errs.append("%s: not skippable" % id)
	if not StoryFilms.available(StringName(id)):
		errs.append("%s: stage %s missing" % [id, StoryFilms.stage_of(StringName(id))])
	# every line translated and voiced
	for s: Dictionary in doc.shots:
		for ln: Dictionary in s.get("lines", []):
			var text := String(ln.get("text", ""))
			var who := String(ln.get("speaker", ""))
			if CineSceneCheck._french(text) == "":
				errs.append("%s: no French for \"%s\"" % [id, text])
			if not voiced.has("%s|%s" % [who, text]):
				errs.append("%s: %s \"%s\" not voiced" % [id, who, text])
	return errs
