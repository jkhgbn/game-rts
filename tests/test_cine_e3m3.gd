extends SceneTree
## e3m3 in-mission scenes (data/cinematics/src/{e3m3_homecoming,e3m3_offer,e3m3_sexton,e3m3_rest}.cine, mode=pause): cine checks 0 FAIL, the baked .tres (PAUSE,
## no stage, its length), MissionE303 plays each id, every subtitle is a mission line with French
## (tests/helpers/cine_scene_check.gd). The live playback path is covered by tests/test_cine_e3m1.gd.
## Run:  godot --headless --path . -s tests/test_cine_e3m3.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "cine_e3m3"
const IDS := ["e3m3_homecoming", "e3m3_offer", "e3m3_sexton", "e3m3_rest"]
const MISSION_SCRIPT := "res://scripts/campaign/mission_e3_03.gd"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var errs: Array[String] = []
	for id: String in IDS:
		errs.append_array(CineSceneCheck.check(root, id, MISSION_SCRIPT))
	await process_frame
	if errs.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errs)])
	quit(0 if errs.is_empty() else 1)