extends SceneTree
## Task 2.A1 (the bot), attack: on scenes/skirmish.tscn the player does nothing (workers mine, Vessa
## stands at her start); the Shadow bot (normal) must launch an attack, reach the Fire base and destroy
## a Fire building within 10 game-minutes. Prints the first attack time, the arrival at the Fire base,
## the first Fire building lost, and the bot's think-tick cost.
## Run:  godot --headless --path . -s tests/test_2_a1_attack.gd --fixed-fps 60 --quit-after 38000

const TASK_ID := "2.A1 attack"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const LIMIT_SECONDS := 600.0
const TIMEOUT_FRAMES := 37000
const FIRE := 0
const SHADOW := 1
const BASE_REACH := 20.0

var main: Node
var bot: Node
var frame := 0
var _wait := 0
var _fire_buildings := -1
var _arrived := -1.0
var _building_lost := -1.0
var _buildings_lost := 0


func _initialize() -> void:
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main
	bot = _bot_for(SHADOW)


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
	if _fire_buildings < 0:
		_fire_buildings = Building.for_team(FIRE).size()
		for b in Building.for_team(FIRE):
			b.destroyed.connect(func(_b: Building) -> void: _buildings_lost += 1)
	if frame % 30 == 0:
		_watch(t)
	if _building_lost >= 0.0 or main.game_over:
		return _finish(t)
	if t >= LIMIT_SECONDS or frame > TIMEOUT_FRAMES:
		return _finish(t)
	return false


func _watch(t: float) -> void:
	if _arrived < 0.0:
		var base: Vector3 = main.base_center(FIRE)
		for node in get_nodes_in_group("units"):
			var u := node as Unit
			if u and int(u.team) == SHADOW and u.is_alive() and u.unit_type and not u.unit_type.is_worker \
					and Vector2(u.global_position.x - base.x, u.global_position.z - base.z).length() <= BASE_REACH:
				_arrived = t
				print("a Shadow soldier reached the Fire base at %.0f s" % t)
				break
	if _buildings_lost > 0 and _building_lost < 0.0:
		_building_lost = t


func _finish(t: float) -> bool:
	if _buildings_lost > 0 and _building_lost < 0.0:
		_building_lost = t
	var eco: Economy = Economy.for_team(SHADOW)
	print("first attack %.0f s (%d launched), reached the Fire base %.0f s, first Fire building lost %.0f s, winner %d" % [
			bot.first_attack_time, bot.attacks_launched, _arrived, _building_lost, main.winner_team])
	print("Shadow at %.0f s: crystals %d, gathered %d, pop %d / %d, strength %.0f, seen %.0f" % [
			t, eco.crystals, eco.gathered_total, eco.pop_used, eco.pop_cap, bot.own_strength, bot.seen_strength])
	print("bot ticks %d, avg %.3f ms, max %.3f ms (at %.0f s)" % [bot.tick_count, bot.tick_usec_average() / 1000.0,
			bot.tick_usec_max / 1000.0, bot.tick_max_at])
	print("rule usec totals: %s" % [bot.rule_usec])
	var errors: Array[String] = []
	if bot.first_attack_time < 0.0:
		errors.append("the bot never attacked")
	if _arrived < 0.0:
		errors.append("no bot soldier reached the Fire base")
	if _building_lost < 0.0:
		errors.append("no Fire building destroyed in %.0f s" % LIMIT_SECONDS)
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
	return true
