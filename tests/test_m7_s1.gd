extends SceneTree
## M7.S1 + M7.S2: mission 1 "The Crown in the Ashes" (docs/design/mission-01.md).
## Checks: Emberfall builds (nodes, pre-built hall, start state 300 / 11 of 20, braziers, peddler, guards,
## dormant crown wardens, Blaze Rider locked); objectives are emitted in order; Hearthward lights after 3 s
## within 3 m and resets when Vessa leaves; dormant wardens take no damage; Vessa's death = defeat after 3 s.
## Run: godot --headless --path . -s tests/test_m7_s1.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "m7_s1"
const TIMEOUT_FRAMES := 1500

var main: Node
var frame := 0
var _wait := 0
var _events: Array[String] = []
var _ended := []            # [victory, frame]
var _errors: Array[String] = []
var _step := 0
var _t0 := 0
var _death_frame := -1


func _initialize() -> void:
	var ev := root.get_node_or_null("Events")
	if ev:
		ev.objective_changed.connect(func(id: StringName, state: StringName) -> void:
			_events.append("%s=%s" % [id, state]))
		ev.mission_ended.connect(func(victory: bool) -> void: _ended.append([victory, frame]))
	main = load("res://missions/mission_01.tscn").instantiate()
	main.set(&"show_briefing", false)
	main.set(&"save_campaign_on_victory", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	var done := _run()
	if done or frame > TIMEOUT_FRAMES:
		if frame > TIMEOUT_FRAMES and _step < 99:
			_errors.append("timed out at step %d" % _step)
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)
		print("  x ", what)


func _run() -> bool:
	var hero: Node3D = main.hero
	var b1: Node = main.brazier(&"hearthward")
	match _step:
		0:
			if frame < 5:
				return false
			_check_map()
			# Clear G1 so Vessa can stand at Hearthward.
			for u in main.guard_groups[&"G1"]:
				u.take_damage(1.0e7, null)
			_step = 1
		1:
			hero.global_position = b1.global_position + Vector3(2.0, 0.0, 0.0)
			hero.command_stop()
			_t0 = frame
			_step = 2
		2:
			if frame - _t0 == 90:   # 1.5 s in: halfway, then leave
				_check(b1.progress > 0.4 and not b1.lit, "brazier progress after 1.5 s (%.2f)" % b1.progress)
				hero.global_position = b1.global_position + Vector3(8.0, 0.0, 0.0)
			if frame - _t0 == 93:
				_check(b1.progress == 0.0, "brazier progress resets when Vessa leaves (%.2f)" % b1.progress)
				hero.global_position = b1.global_position + Vector3(0.0, 0.0, 2.5)
				_t0 = frame
				_step = 3
		3:
			if frame - _t0 == 165:
				_check(not b1.lit, "brazier lit before 3 s")
			if b1.lit:
				_check(frame - _t0 >= 170 and frame - _t0 <= 200, "brazier lit after %d frames (want ~180)" % (frame - _t0))
				_step = 4
				_t0 = frame
			elif frame - _t0 > 240:
				_check(false, "brazier never lit")
				_step = 4
				_t0 = frame
		4:
			if frame - _t0 < 30:
				return false
			_check(main.lit_count == 1, "lit_count 1")
			_check(_events.has("obj_braziers=active") and _events.count("obj_braziers=active") >= 2,
					"obj_braziers re-emitted on the counter change")
			_check(main.dialogue_log.size() >= 5, "E2 / E3 dialogue (L4, L5) said: %d lines" % main.dialogue_log.size())
			var objs: Array = main.objectives()
			_check(objs.size() == 6 and objs[0]["progress"] == 1 and objs[0]["goal"] == 3, "objectives() braziers 1 / 3")
			# Dormant crown wardens take no damage.
			for w in main.guard_groups[&"G5"]:
				w.take_damage(1.0e7, null)
			_step = 5
			_t0 = frame
		5:
			if frame - _t0 < 5:
				return false
			for w in main.guard_groups[&"G5"]:
				_check(w.is_alive() and w.hp == w.max_hp, "dormant warden took damage")
			# Vessa dies: defeat 3 s later.
			hero.take_damage(1.0e7, null)
			_death_frame = frame
			_step = 6
		6:
			if not _ended.is_empty():
				var dt: int = int(_ended[0][1]) - _death_frame
				_check(_ended[0][0] == false, "Vessa's death must be a defeat")
				_check(dt >= 170 and dt <= 215, "defeat after 3 s (%d frames)" % dt)
				_check(_events.has("obj_vessa=failed"), "obj_vessa failed emitted")
				_check(String(main.dialogue_log[-1]).ends_with("I was winning."), "L15 said last")
				_step = 99
				return true
			if frame - _death_frame > 400:
				_check(false, "no mission_ended after Vessa's death")
				_step = 99
				return true
	return false


func _check_map() -> void:
	var nodes: Dictionary = main.crystal_nodes
	var want := {&"m1_fire_a": 1500, &"m1_fire_b": 1500, &"m1_west": 2000, &"m1_south": 1500,
			&"node_shadow_a": 1500, &"node_shadow_b": 1500}
	for id in want:
		_check(nodes.has(id), "node %s missing" % id)
		if nodes.has(id):
			_check(nodes[id].crystals_left >= want[id] - 60, "node %s amount %d" % [id, nodes[id].crystals_left])
	_check(main.economy.crystals == 300, "start crystals %d" % main.economy.crystals)
	_check(main.economy.pop_used == 11 and main.economy.pop_cap == 20,
			"pop %d / %d" % [main.economy.pop_used, main.economy.pop_cap])
	_check(main.ember_hall != null and main.ember_hall.is_constructed(), "pre-built Ember Hall")
	var ids: Array = []
	for t in main.ember_hall.trainable_types():
		ids.append(String(t.id))
	_check(not ids.has("blaze_rider") and not ids.has("ash_hurler") and ids.has("flame_guard"),
			"hall trains %s (Blaze Rider locked)" % [ids])
	_check(main.braziers.size() == 3, "3 braziers")
	_check(main.pell != null and not main.pell.is_shop(), "caged peddler is not a shop")
	_check(main.gloom_hall != null and main.westwatch_spire != null and main.westwatch_spire.max_hp == 750.0,
			"Gloom Hall + Westwatch spire")
	_check(main.guard_groups[&"G1"].size() == 3 and main.guard_groups[&"G2"].size() == 3
			and main.guard_groups[&"G3"].size() == 5 and main.guard_groups[&"G4"].size() == 3
			and main.guard_groups[&"G5"].size() == 4, "guard group sizes")
	for w in main.guard_groups[&"G5"]:
		_check(not w.is_in_group("units"), "dormant warden still targetable")
	for u in main.guard_groups[&"G1"]:
		_check(u.is_in_group("scripted"), "guard not in group scripted")
	_check(main.crown != null and not main.crown.can_be_claimed(), "crown sealed")
	_check(main.shadow_hero.level == 3, "Malrik level %d" % main.shadow_hero.level)
	var order := ["obj_braziers=active", "obj_vessa=active", "sec_peddler=active", "sec_outpost=active"]
	_check(_events.slice(0, 4) == order, "objectives order %s" % [_events])
	_check(main.dialogue_log.size() == 3, "E1 lines L1-L3 (%d)" % main.dialogue_log.size())
	var brief: Dictionary = main.briefing()
	_check(brief["paragraphs"].size() == 3 and brief["objectives"].size() == 3, "briefing()")
