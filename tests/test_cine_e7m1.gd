extends SceneTree
## e7m1 in-mission scenes (data/cinematics/src/e7m1_{arrival,laurel,dusk}.cine, mode=pause): cine checks 0 FAIL, the baked .tres
## (PAUSE, no stage, its length), the mission script plays each id, every subtitle is a mission line with French
## (tests/helpers/cine_scene_check.gd). The mission scene opens through MissionHarness like tests/test_cine_e6m4.gd.
## Run:  godot --headless --path . -s tests/test_cine_e7m1.gd --fixed-fps 60 --quit-after 3000

const IDS := ["e7m1_arrival", "e7m1_laurel", "e7m1_dusk"]
const MISSION_SCRIPT := "res://scripts/campaign/mission_e7_01.gd"
const MISSION_SCENE := "res://missions/mission_e7_01.tscn"

var h := MissionHarness.new()
var main: Node


func _initialize() -> void:
	main = h.open(self, MISSION_SCENE, {"task_id": "cine_e7m1", "difficulty": 1})
	h.timeout_frames = 2000
	h.steps.add("static checks", func() -> bool:
		for id: String in IDS:
			for e: String in CineSceneCheck.check(root, id, MISSION_SCRIPT):
				h.check(false, e)
		return true, 30)


func _process(_d: float) -> bool:
	return h.tick()
