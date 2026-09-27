extends SceneTree
## Task 2.A1 (the bot), rules of docs/design/ai.md on scenes/skirmish.tscn, passive player, normal bot:
## - seen_strength stays 0 until a Fire unit comes within 16 m of a Shadow unit (20 m of a building);
## - 3 Flame Guards dropped 12 m from the Gloom Hall: a home soldier attack-moves within 2.5 s (seen on
##   the next tick + the 1.5 s reaction delay);
## - the Gloom Hall destroyed: the next building the bot places is a barracks;
## - 20 Ember Archers near the scout path: once seen, the next 4 soldiers queued include >= 2 Grave Hounds;
## - Malrik put at 30 % HP in mid-map walks home, heals, and goes back to his anchor at >= 70 %.
## Run:  godot --headless --path . -s tests/test_2_a1_rules.gd --fixed-fps 60 --quit-after 18000

const TASK_ID := "2.A1 rules"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const TIMEOUT_FRAMES := 17000
const END_SECONDS := 270.0
const FIRE := 0
const SHADOW := 1
const GUARDS_AT := 75.0
const GUARDS_POS := Vector3(28.0, 0.0, -55.0)  # step 12: clear of the Bristleback Wallow at (14, -57)
const HALL_KILL_AT := 105.0
const ARCHERS_AT := 110.0
const ARCHERS_POS := Vector3(-16.0, 0.0, 12.0)
const MALRIK_AT := 150.0
const MALRIK_POS := Vector3(8.0, 0.0, -14.0)

var main: Node
var bot: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _t := 0.0

var _contact_at := -1.0
var _seen_before_contact := false
var _guards_defended := -1.0
var _hall_killed := false
var _known_buildings := {}
var _first_after_kill := ""
var _archers_seen_at := -1.0
var _archer_log_index := -1
var _malrik_started := false
var _malrik_home_at := -1.0
var _malrik_back_at := -1.0


func _initialize() -> void:
	# 20.A3: the Replay Lab's auto recorder off (docs/plan/replay-lab.md: tests turn it off; its session froze the
	# skirmish economy on 2026-09-26 22:00).
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == SHADOW:
			bot = child
	if bot == null:
		bot = COMMANDER.new()
		bot.team = SHADOW
		main.add_child(bot)
	bot.debug_log = true


func _process(_delta: float) -> bool:
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	_t = main.match_time()
	if frame % 6 == 0:
		_check_seen()
		_check_guards()
		_check_rebuild()
		_check_mix()
		_check_malrik()
	if _t >= END_SECONDS or frame > TIMEOUT_FRAMES or main.game_over:
		return _finish()
	return false


# seen_strength is 0 until real contact (16 m)
func _check_seen() -> void:
	if _contact_at >= 0.0:
		return
	var shadow: Array[Unit] = []
	var fire: Array[Unit] = []
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive():
			continue
		if int(u.team) == SHADOW:
			shadow.append(u)
		elif int(u.team) == FIRE:
			fire.append(u)
	var eyes: Array = []   # [position, sight]: Shadow units 16 m, Shadow buildings 20 m
	for s in shadow:
		eyes.append([s.global_position, 16.5])
	for b in Building.for_team(SHADOW):
		eyes.append([b.global_position, 20.0 + b.target_radius() + 0.5])
	for eye in eyes:
		var p: Vector3 = eye[0]
		for f in fire:
			if Vector2(p.x - f.global_position.x, p.z - f.global_position.z).length() <= float(eye[1]):
				_contact_at = _t
				print("first contact at %.1f s" % _t)
				return
	if bot.seen_strength > 0.0 and not _seen_before_contact:
		_seen_before_contact = true
		_errors.append("seen_strength %.0f at %.1f s before any contact" % [bot.seen_strength, _t])


# the defence reacts within 3 s
func _check_guards() -> void:
	if _t >= GUARDS_AT and _guards_defended < -1.5:
		return
	if _t >= GUARDS_AT and _guards_defended == -1.0:
		for i in 3:
			var g: Unit = main.make_unit("flame_guard")
			g.team = FIRE
			main.add_child(g)
			g.global_position = GUARDS_POS + Vector3(i * 1.2, 0.0, 0.0)
			g.command_stop()
		_guards_defended = -1.5
		print("3 Flame Guards dropped at %.1f s" % _t)
		return
	if _guards_defended == -1.5:
		for node in get_nodes_in_group("units"):
			var u := node as Unit
			if u and int(u.team) == SHADOW and u.is_alive() and u.unit_type and not u.unit_type.is_worker \
					and u.is_attack_moving():
				_guards_defended = _t
				print("a Shadow soldier attack-moves %.1f s after the drop" % (_t - GUARDS_AT))
				if _t - GUARDS_AT > 2.6:
					_errors.append("defence took %.1f s (want <= 2.5)" % (_t - GUARDS_AT))
				_guards_defended = -2.0
				return
		if _t - GUARDS_AT > 6.0:
			_errors.append("no Shadow soldier attack-moved within 6 s of the drop")
			_guards_defended = -2.0


# the Gloom Hall is rebuilt before anything else
func _check_rebuild() -> void:
	if _t < HALL_KILL_AT:
		for b in Building.for_team(SHADOW):
			_known_buildings[b.get_instance_id()] = true
		return
	if not _hall_killed:
		_hall_killed = true
		for b in Building.for_team(SHADOW):
			if b.building_type and b.building_type.id == &"shadow_barracks":
				b.take_damage(1.0e6, null)
				print("Gloom Hall destroyed at %.1f s" % _t)
		return
	if _first_after_kill != "":
		return
	for b in Building.for_team(SHADOW):
		if not _known_buildings.has(b.get_instance_id()):
			_first_after_kill = String(b.building_type.id)
			print("first building after the kill: %s at %.1f s" % [_first_after_kill, _t])
			if _first_after_kill != "shadow_barracks":
				_errors.append("rebuilt %s before the barracks" % _first_after_kill)


# the unit mix follows what was seen
func _check_mix() -> void:
	if _t >= ARCHERS_AT and _archers_seen_at == -1.0:
		for i in 20:
			var a: Unit = main.make_unit("ember_archer")
			a.team = FIRE
			main.add_child(a)
			a.global_position = ARCHERS_POS + Vector3((i % 5) * 1.2, 0.0, floorf(i / 5.0) * 1.2)
			a.command_stop()
		_archers_seen_at = -2.0
		print("20 Ember Archers dropped at %.1f s" % _t)
		return
	if _archers_seen_at == -2.0:
		for e: Dictionary in bot.memory.units.values():
			if e["type"] == &"ember_archer":
				_archers_seen_at = _t
				_archer_log_index = bot.log_lines.size()
				print("archers seen at %.1f s" % _t)
				return


func _mix_result() -> Array[String]:
	var queued: Array[String] = []
	if _archer_log_index < 0:
		return queued
	for i in range(_archer_log_index, bot.log_lines.size()):
		var line: String = bot.log_lines[i]
		if line.contains("TRAIN ") and not line.contains("Thrall"):
			queued.append(line.get_slice("TRAIN ", 1).get_slice(" (", 0))
	return queued


# Malrik goes home under 35 % and comes back at 70 %
func _check_malrik() -> void:
	var m: Unit = main.shadow_hero
	if not _malrik_started:
		if _t >= MALRIK_AT and m.is_alive():
			_malrik_started = true
			m.global_position = MALRIK_POS
			m.command_stop()
			m.hp = m.max_hp * 0.3
			print("Malrik at 30 %% HP in mid-map at %.1f s" % _t)
		return
	if not m.is_alive():
		return
	var keep: Node3D = main.keep_of(SHADOW)
	var d_keep := Vector2(m.global_position.x - keep.global_position.x, m.global_position.z - keep.global_position.z).length()
	if _malrik_home_at < 0.0 and d_keep <= 15.0:
		_malrik_home_at = _t
		print("Malrik home at %.1f s (%.0f %% HP)" % [_t, m.hp / m.max_hp * 100.0])
	if _malrik_home_at >= 0.0 and _malrik_back_at < 0.0 and m.hp >= 0.7 * m.max_hp:
		var anchor := Vector3(36.0, 0.0, -36.0)
		if Vector2(m.global_position.x - anchor.x, m.global_position.z - anchor.z).length() <= 7.0:
			_malrik_back_at = _t
			print("Malrik back at the anchor at %.1f s (%.0f %% HP)" % [_t, m.hp / m.max_hp * 100.0])


func _finish() -> bool:
	if _contact_at < 0.0:
		_errors.append("no contact happened")
	if _guards_defended > -2.0 and _guards_defended < 0.0:
		_errors.append("defence not checked")
	if _first_after_kill == "":
		_errors.append("nothing rebuilt after the Gloom Hall died")
	var mix := _mix_result()
	print("soldiers queued after the archers were seen: %s" % [mix])
	if _archers_seen_at < 0.0:
		_errors.append("the archers were never seen")
	elif mix.size() < 4:
		_errors.append("only %d soldiers queued after the archers were seen" % mix.size())
	else:
		var hounds := 0
		for i in 4:
			if mix[i] == "Grave Hound":
				hounds += 1
		if hounds < 2:
			_errors.append("%d Grave Hounds in the next 4 (want >= 2)" % hounds)
	if _malrik_home_at < 0.0:
		_errors.append("Malrik never went home at 30 % HP")
	elif _malrik_back_at < 0.0:
		_errors.append("Malrik never went back to the anchor at 70 % HP")
	print("bot ticks %d, avg %.3f ms, max %.3f ms" % [bot.tick_count, bot.tick_usec_average() / 1000.0,
			bot.tick_usec_max / 1000.0])
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true
