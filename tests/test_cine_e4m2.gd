extends SceneTree
## e4m2 in-mission scenes (data/cinematics/src/e4m2_{lantern,hush,border}.cine, mode=pause): cine checks 0 FAIL, the baked .tres
## (PAUSE, no stage, its length), MissionE402 plays each id, every subtitle is a mission line with French
## (tests/helpers/cine_scene_check.gd). The mission scene opens through MissionHarness like tests/test_cine_e3m1.gd; the
## live playback path itself is covered by tests/test_cine_e3m1.gd.
## Run:  godot --headless --path . -s tests/test_cine_e4m2.gd --fixed-fps 60 --quit-after 3000

const IDS := ["e4m2_lantern", "e4m2_hush", "e4m2_border"]
const MISSION_SCRIPT := "res://scripts/campaign/mission_e4_02.gd"
const MISSION_SCENE := "res://missions/mission_e4_02.tscn"

var h := MissionHarness.new()
var main: Node


func _initialize() -> void:
	main = h.open(self, MISSION_SCENE, {"task_id": "cine_e4m2", "difficulty": 1})
	h.timeout_frames = 2000
	h.steps.add("static checks", func() -> bool:
		for id: String in IDS:
			for e: String in CineSceneCheck.check(root, id, MISSION_SCRIPT):
				h.check(false, e)
		return true, 30)


func _process(_d: float) -> bool:
	return h.tick()
