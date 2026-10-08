extends SceneTree
## m03 E13 scene m3_parting (data/cinematics/src/m3_parting.cine, mode=pause): cine checks 0 FAIL, the baked .tres
## (PAUSE, no stage, its length), Mission03 plays it, every subtitle is a mission line with French and a voice
## (tests/helpers/cine_scene_check.gd + data/voice/manifest.json); its cameras follow live actors (orbit pivots `vessa` /
## `ysolde`, never a fixed point: the last gate falls anywhere); Mission03 exposes `ysolde` and `cine_sink_ysolde`.
## Run:  godot --headless --path . -s tests/test_cine_m03_parting.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "cine_m03_parting"
const ID := "m3_parting"
const MISSION_SCRIPT := "res://scripts/campaign/mission_03.gd"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var errs: Array[String] = CineSceneCheck.check(root, ID, MISSION_SCRIPT)
	var cs := CinematicScript.find(StringName(ID))
	if cs != null:
		for s: CinematicShot in cs.shots:
			if s.camera_mode != CinematicShot.CameraMode.ORBIT or not s.pivot_actor in [&"vessa", &"ysolde"]:
				errs.append("shot %s is not an orbit on vessa / ysolde" % s.id)
	var code := FileAccess.get_file_as_string(MISSION_SCRIPT)
	for needle: String in ["var ysolde: Node3D", "func cine_sink_ysolde()"]:
		if not needle in code:
			errs.append("mission_03.gd lacks %s" % needle)
	var voiced := {}
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/voice/manifest.json"))
	if m is Dictionary:
		var entries: Variant = (m as Dictionary).get("lines", m)
		if entries is Dictionary:
			for k: Variant in entries:
				var e: Variant = entries[k]
				if e is Dictionary and (e as Dictionary).has("text"):
					voiced[String((e as Dictionary)["text"])] = true
	var doc := CineDoc.load_file(CineDoc.source_of(ID))
	for s: Dictionary in doc.shots:
		for ln: Dictionary in s.get("lines", []):
			if not voiced.has(String(ln["text"])):
				errs.append("not voiced: \"%s\"" % ln["text"])
	await process_frame
	if errs.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errs)])
	quit(0 if errs.is_empty() else 1)
