extends SceneTree
## Episode 8 in-mission scenes (data/cinematics/src/e8m*_*.cine, mode=pause): cine checks 0 FAIL, the baked .tres
## (PAUSE, no stage, its length), the mission script plays each id, every subtitle is an Episode 8 line
## (scripts/campaign/e8_lines.gd, generated from data/voice/lines) with French (tests/helpers/cine_scene_check.gd).
## Run:  godot --headless --path . -s tests/test_cine_e8.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "cine_e8"
const LINES_SCRIPT := "res://scripts/campaign/e8_lines.gd"
const IDS := {
	"e8m1_fire_stakes": "res://scripts/campaign/mission_e8_01_fire.gd",
	"e8m1_fire_storm": "res://scripts/campaign/mission_e8_01_fire.gd",
	"e8m1_shadow_home": "res://scripts/campaign/mission_e8_01_shadow.gd",
	"e8m1_shadow_father": "res://scripts/campaign/mission_e8_01_shadow.gd",
	"e8m1_shadow_hush": "res://scripts/campaign/mission_e8_01_shadow.gd",
	"e8m1_shadow_stair": "res://scripts/campaign/mission_e8_01_shadow.gd",
	"e8m1_ice_gate": "res://scripts/campaign/mission_e8_01_ice.gd",
	"e8m1_ice_south": "res://scripts/campaign/mission_e8_01_ice.gd",
	"e8m1_nature_road": "res://scripts/campaign/mission_e8_01_nature.gd",
	"e8m1_nature_out": "res://scripts/campaign/mission_e8_01_nature.gd",
	"e8m2_seats": "res://scripts/campaign/mission_e8_02.gd",
	"e8m2_hand": "res://scripts/campaign/mission_e8_02.gd",
	"e8m2_turn": "res://scripts/campaign/mission_e8_02.gd",
	"e8m3_king": "res://scripts/campaign/mission_e8_03.gd",
	"e8m3_walk": "res://scripts/campaign/mission_e8_03.gd",
	"e8m3_chains": "res://scripts/campaign/mission_e8_03.gd",
}

var _done := false


func _process(_d: float) -> bool:
	if _done:
		return true
	_done = true
	var lines := FileAccess.get_file_as_string(LINES_SCRIPT)
	var fails: Array[String] = []
	for id: String in IDS:
		for e: String in CineSceneCheck.check(root, id, IDS[id]):
			# the lines live in E8Lines, not in the mission script: a subtitle found there is a mission line
			var at := e.find("line \"")
			if at >= 0 and e.ends_with(String(IDS[id]).get_file()):
				var text := e.substr(at + 6, e.rfind("\" is not a line") - at - 6)
				if ("\"%s\"" % text.replace("\\", "\\\\").replace("\"", "\\\"")) in lines:
					continue
			fails.append(e)
	if fails.is_empty():
		print("PASS %s (%d scenes)" % [TASK_ID, IDS.size()])
	else:
		for f in fails:
			print("  x ", f)
		print("FAIL %s: %d problems" % [TASK_ID, fails.size()])
	return true
