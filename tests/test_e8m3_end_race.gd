extends SceneTree
## Review 2026-10-10 #1 (e8m3 soft-lock): the Hollow King falls while a defeat is pending (the player's wizard died, the
## 3 s lose() timer runs). The fall must not hold the world (that froze the defeat timer forever): no E14, the world is
## not held, and the defeat ends the mission. Also checks that phase 2 / 3 films do not start during a pending defeat.
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_e8m3_end_race.gd --fixed-fps 60 --quit-after 20000
## Prints "PASS e8m3_end_race" or "FAIL e8m3_end_race: <reasons>".

var h := MissionHarness.new()
var m: MissionBase
var king: Unit
var _settle := 0
var _held_seen := false


func _initialize() -> void:
	h.task_id = "e8m3_end_race"
	h.timeout_frames = 6000
	m = h.open(self, "res://missions/mission_e8_03.tscn", {"difficulty": 1}) as MissionBase
	h.steps.add("intro done", func() -> bool:
		_settle += 1
		return _settle > 60, 600)
	h.steps.add("the King falls during a pending defeat", _race, 10)
	h.steps.add("the defeat ends the mission", func() -> bool:
		if bool(m.get(&"world_is_held")):
			_held_seen = true
		return bool(m.get(&"game_over")), 900)
	h.steps.add("verdict", func() -> bool:
		h.check(not _held_seen, "the world was held while the defeat was pending")
		h.check(h.ended == 0, "the mission did not end in a defeat (ended=%d)" % h.ended)
		h.check(not m.has_fired(&"E14"), "the fall (E14) fired during a pending defeat")
		return true, 10)


func _race() -> bool:
	king = m.get(&"king") as Unit
	if not h.check(king != null and is_instance_valid(king), "no King"):
		return true
	m.set(&"phase", 3)
	m.set(&"turns", 9)
	king.hp = 50.0
	m.lose(3.0)   # what the player's wizard's death does (instant loss, 3 s)
	if not h.check(m.is_ending(), "lose(3.0) did not start a pending ending"):
		return true
	king.take_damage(1.0e6, null)   # the death guard -> _check_fall
	m.call(&"_on_king_hit", 0.0, null)
	m.call(&"_check_fall")
	m.call(&"_fall")
	# phase 2 / 3 films must not start either
	m.set(&"phase", 1)
	m.call(&"_phase2")
	h.check(int(m.get(&"phase")) == 1, "_phase2 ran during a pending defeat")
	m.set(&"phase", 2)
	m.call(&"_phase3")
	h.check(int(m.get(&"phase")) == 2, "_phase3 ran during a pending defeat")
	m.set(&"phase", 3)
	h.check(not bool(m.get(&"world_is_held")), "the King's fall held the world during a pending defeat")
	h.check(king.is_alive(), "the King died instead of holding at 1 HP")
	return true


func _process(_d: float) -> bool:
	return h.tick()
