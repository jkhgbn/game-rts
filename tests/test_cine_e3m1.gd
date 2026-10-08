extends SceneTree
## e3m1 in-mission scenes (data/cinematics/src/e3m1_{ford,standard,dusk}.cine, mode=pause): cine checks 0 FAIL, the baked
## .tres (PAUSE, no stage, its length), MissionE301 plays each id, every subtitle is a mission line with French
## (tests/helpers/cine_scene_check.gd). Then one plays for real in the live mission: e3m1_ford freezes the tree, the
## camera orbits / frames from the cinematic camera, `malrik` resolves to the hero (MissionBase.cinematic_actor), a skip
## runs the end state once with the tree running again, and the line the film showed is not repeated as a dialogue card.
## Run:  godot --headless --path . -s tests/test_cine_e3m1.gd --fixed-fps 60 --quit-after 9000

const IDS := ["e3m1_ford", "e3m1_standard", "e3m1_dusk"]
const MISSION_SCRIPT := "res://scripts/campaign/mission_e3_01.gd"
const MISSION_SCENE := "res://missions/mission_e3_01.tscn"
const L10 := "The ford is mine. Write it down, Ysolde. You like things that last."

var h := MissionHarness.new()
var main: Node
var player: Node
var line_seen := false
var end_calls := 0
var said_before := 0


func _initialize() -> void:
	main = h.open(self, MISSION_SCENE, {"task_id": "cine_e3m1", "difficulty": 1})
	h.timeout_frames = 4000
	h.steps.add("static checks", func() -> bool:
		for id: String in IDS:
			for e: String in CineSceneCheck.check(root, id, MISSION_SCRIPT):
				h.check(false, e)
		return true, 30)
	h.steps.add("e3m1_ford plays over the frozen mission", func() -> bool:
		main.set(&"cinematics_enabled", true)
		player = CinematicPlayer.instance(self)
		player.connect(&"line_started", func(_sp: StringName, text: String) -> void:
			if text == L10:
				line_seen = true)
		said_before = h.dialogue_log.size()
		var why: String = main.call(&"play_cutscene", &"e3m1_ford", func() -> void:
			end_calls += 1
			main.call(&"say", &"malrik", L10))
		h.check(why == "", "play_cutscene refused: %s" % why)
		h.check(bool(player.call(&"is_playing")), "the player does not play")
		h.check(paused, "the mission world is not frozen (PAUSE)")
		h.check(player.call(&"actor", &"malrik") == main.get(&"hero"), "`malrik` does not resolve to the hero")
		h.check(end_calls == 0, "the end state ran before the film")
		player.call(&"seek", 6.0)
		return true, 30)
	h.steps.add("the line shows", func() -> bool:
		if line_seen:
			var st: Dictionary = player.call(&"debug_state")
			h.check(String(st.get("shot_id", "")) == "F2", "line shown outside shot F2 (%s)" % st.get("shot_id", ""))
			player.call(&"skip")
			return true
		return false, 600)
	h.steps.add("skip: end state once, world running, no second card", func() -> bool:
		if end_calls == 0:
			return false
		h.check(end_calls == 1, "end state ran %d times" % end_calls)
		h.check(not paused, "the tree is still paused after the film")
		h.check(not bool(player.call(&"is_playing")), "the player still plays")
		var cards := h.dialogue_log.slice(said_before).filter(func(s: String) -> bool: return L10 in s)
		h.check(cards.is_empty(), "L10 shown again as a dialogue card after the film")
		var logged := (main.get(&"dialogue_log") as Array).filter(func(s: String) -> bool: return L10 in s)
		h.check(not logged.is_empty(), "L10 missing from the mission's dialogue_log")
		return true, 300)


func _process(_d: float) -> bool:
	return h.tick()
