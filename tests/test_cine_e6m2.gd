extends SceneTree
## e6m2 in-mission scenes (data/cinematics/src/e6m2_{rider,dawn_open,dawn_shut}.cine, mode=pause): cine checks 0 FAIL, the baked .tres
## (PAUSE, no stage, its length), MissionE6_02 plays each id, every subtitle is a mission line with French
## (tests/helpers/cine_scene_check.gd). The mission scene opens through MissionHarness like tests/test_cine_e4m1.gd; the
## live playback path itself is covered by tests/test_cine_e3m1.gd.
## Run:  godot --headless --path . -s tests/test_cine_e6m2.gd --fixed-fps 60 --quit-after 3000

const IDS := ["e6m2_rider", "e6m2_dawn_open", "e6m2_dawn_shut"]
const MISSION_SCRIPT := "res://scripts/campaign/mission_e6_02.gd"
const MISSION_SCENE := "res://missions/mission_e6_02.tscn"

var h := MissionHarness.new()
var main: Node


func _initialize() -> void:
	main = h.open(self, MISSION_SCENE, {"task_id": "cine_e6m2", "difficulty": 1})
	h.timeout_frames = 2000
	h.steps.add("static checks", func() -> bool:
		for id: String in IDS:
			for e: String in CineSceneCheck.check(root, id, MISSION_SCRIPT):
				h.check(false, e)
		return true, 30)


func _process(_d: float) -> bool:
	return h.tick()
