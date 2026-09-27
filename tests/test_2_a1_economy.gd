extends SceneTree
## Task 2.A1 (the bot), economy: on scenes/skirmish.tscn with a passive player, after 3 game-minutes the
## Shadow bot (normal) has more workers than it started with, has spent crystals, and has a Gloom Hall
## (built or under construction). Also prints the opening timeline of ai.md (hall placed / done,
## 6 workers, first soldier) and the bot's think-tick cost.
## Run:  godot --headless --path . -s tests/test_2_a1_economy.gd --fixed-fps 60 --quit-after 12500

const TASK_ID := "2.A1 economy"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const RUN_SECONDS := 180.0
const TIMEOUT_FRAMES := 12000
const SHADOW := 1

var main: Node
var bot: Node
var frame := 0
var _wait := 0
var _start_workers := -1
var _hall: Node = null
var _hall_placed := -1.0
var _hall_done := -1.0
var _six_workers := -1.0
var _first_soldier := -1.0
var _hovel_placed := -1.0
var _hovel_pop := -1


func _initialize() -> void:
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main
	bot = _bot_for(SHADOW)


## The scene's own bot for `team` if the level already has one, else a new one.
func _bot_for(team: int) -> Node:
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			child.debug_log = true
			return child
	var b: Node = COMMANDER.new()
	b.team = team
	b.debug_log = true
	main.add_child(b)
	return b


func _process(_delta: float) -> bool:
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	var t: float = main.match_time()
	if _start_workers < 0:
		_start_workers = main.workers_of(SHADOW).size()
	if frame % 10 == 0:
		_watch(t)
	if t >= RUN_SECONDS:
		return _finish()
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _watch(t: float) -> void:
	var eco: Economy = Economy.for_team(SHADOW)
	if _hall == null:
		for b in Building.for_team(SHADOW):
			if b.building_type and b.building_type.id == &"shadow_barracks":
				_hall = b
				_hall_placed = t
				print("hall placed at %.1f s at (%d, %d)" % [t, b.global_position.x, b.global_position.z])
	elif _hall_done < 0.0 and is_instance_valid(_hall) and _hall.is_constructed():
		_hall_done = t
	if _six_workers < 0.0 and main.workers_of(SHADOW).size() >= 6:
		_six_workers = t
	if _first_soldier < 0.0:
		for node in get_nodes_in_group("units"):
			var u := node as Unit
			if u and int(u.team) == SHADOW and u.is_alive() and u.unit_type and not u.unit_type.is_worker:
				_first_soldier = t
				print("first soldier %s at %.1f s" % [u.unit_name, t])
				break
	if _hovel_placed < 0.0 and Building.count_of(&"shadow_hovel", SHADOW) > 0:
		_hovel_placed = t
		_hovel_pop = eco.pop_used


func _finish() -> bool:
	var eco: Economy = Economy.for_team(SHADOW)
	var workers: int = main.workers_of(SHADOW).size()
	var spent: int = Economy.START_CRYSTALS + eco.gathered_total - eco.crystals
	var halls := Building.count_of(&"shadow_barracks", SHADOW)
	print("timeline: hall placed %.1f s, done %.1f s, 6 workers %.1f s, first soldier %.1f s, hovel %.1f s (pop %d)" % [
			_hall_placed, _hall_done, _six_workers, _first_soldier, _hovel_placed, _hovel_pop])
	print("at %.0f s: workers %d (start %d), crystals %d, gathered %d, spent %d, halls %d, pop %d / %d, strength %.0f" % [
			main.match_time(), workers, _start_workers, eco.crystals, eco.gathered_total, spent, halls,
			eco.pop_used, eco.pop_cap, bot.own_strength])
	print("bot ticks %d, avg %.3f ms, max %.3f ms" % [bot.tick_count, bot.tick_usec_average() / 1000.0,
			bot.tick_usec_max / 1000.0])
	var errors: Array[String] = []
	if workers <= _start_workers:
		errors.append("workers %d <= start %d" % [workers, _start_workers])
	if spent <= 0:
		errors.append("no crystals spent")
	if halls < 1:
		errors.append("no Gloom Hall")
	if _hall_placed > 2.0:
		errors.append("hall placed late (%.1f s)" % _hall_placed)
	if _hall != null and is_instance_valid(_hall) and Vector2(_hall.global_position.x - 27.0, _hall.global_position.z + 45.0).length() > 0.1:
		errors.append("hall not at the H1 slot (27, -45)")
	if _six_workers < 0.0 or _six_workers > 80.0:
		errors.append("6 workers at %.1f s (want <= 80)" % _six_workers)
	if _first_soldier < 0.0 or _first_soldier > 90.0:
		errors.append("first soldier at %.1f s (want <= 90)" % _first_soldier)
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
	return true
