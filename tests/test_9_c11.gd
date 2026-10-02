extends SceneTree
## Task 9.C11 (lead): champions integration run. Headless 1v1, normal bot vs normal bot, cap 24:00.
## Checks (champions.md "Done when" 9.C11): both sides hire; at least one bounty of each kind is paid (the bots
## never place Escort and their Hunt / Guard rules need long games, so the test also acts like a player: Escort 50
## on the wizard + Guard 50 on the keep at 7:00 and 12:00, one Hunt 75 near a champion from 5:00);
## no champion is ever orderable through the player's selection; the match ends between 14:00 and 22:00 (reported,
## a note only if outside: balance is 9.D4's job); frame time reported.
## Run:  godot --headless --path . -s tests/test_9_c11.gd --fixed-fps 60 --quit-after 95000 -- --pair=fire:shadow
##   Options: --minutes=24, --no-champions (9.D4 control run), --full (play the match out).
## Early stop (fast CI, 2026-10-02): the run ends as soon as both sides have hired and a bounty of every kind is paid
## (those only grow, so the verdict cannot turn); the "never orderable" check runs on every scan until then. --full
## plays the match out (the old behaviour, for the 9.D4 match length note); the control run always plays it out.

const TASK_ID := "9.C11"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const BOARD_PATH := "res://scripts/world/bounty_board.gd"
const PLAYER := 0
const ENEMY := 1
const KIND_NAMES := ["Hunt", "Explore", "Guard", "Escort"]
const ESCORT_TIMES: Array[float] = [420.0, 720.0]

var main: Node
var bots := {}
var _kingdoms := {PLAYER: &"fire", ENEMY: &"shadow"}
var _minutes := 24.0
var _wait := 0
var _frame := 0
var _t := 0.0
var _started := false
var _errors: Array[String] = []
var _notes: Array[String] = []
var _hires := {PLAYER: [], ENEMY: []}          # [time, id, name]
var _seen_champs := {}                         # instance id -> true
var _deaths := {PLAYER: 0, ENEMY: 0}
var _casts := {PLAYER: 0, ENEMY: 0}
var _placed := [0, 0, 0, 0]
var _paid := [0, 0, 0, 0]
var _paid_essence := {PLAYER: 0, ENEMY: 0}
var _boards := {}                              # instance id -> true (connected)
var _escorts_done := 0
var _hunt_done := {}
var _control := false
var _full := false
var _early := false
var _orderable_leaks := 0
var _max_level := {PLAYER: 0, ENEMY: 0}
var _usec := 0
var _usec_frames := 0
var _last_usec := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pair="):
			var ks := a.trim_prefix("--pair=").split(":")
			_kingdoms = {PLAYER: StringName(ks[0]), ENEMY: StringName(ks[1] if ks.size() > 1 else "shadow")}
		elif a.begins_with("--minutes="):
			_minutes = a.trim_prefix("--minutes=").to_float()
		elif a == "--full":
			_full = true
		elif a == "--no-champions":   # control run for 9.D4: same match without taverns (checks are skipped)
			_control = true
	main = load(SCENE).instantiate()
	if _control:
		main.set(&"tavern_enabled", false)
	main.set(&"player_kingdom", _kingdoms[PLAYER])
	main.set(&"enemy_kingdom", _kingdoms[ENEMY])
	bots = {PLAYER: _bot_for(PLAYER), ENEMY: _bot_for(ENEMY)}
	root.add_child(main)
	current_scene = main


func _bot_for(team: int) -> Node:
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			child.difficulty = 1
			child.profile = null
			child.profile_id = &""
			return child
	var b: Node = COMMANDER.new()
	b.team = team
	b.difficulty = 1
	main.add_child(b)
	return b


func _process(_delta: float) -> bool:
	if main == null:
		return true
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	var now := Time.get_ticks_usec()
	if _last_usec > 0 and _started:
		_usec += now - _last_usec
		_usec_frames += 1
	_last_usec = now
	_frame += 1
	_t = main.match_time()
	if not _started:
		if not bots[PLAYER].get(&"_ready_done") or not bots[ENEMY].get(&"_ready_done"):
			return false
		_started = true
		print("RUN start: player %s vs enemy %s, both normal bots" % [_kingdoms[PLAYER], _kingdoms[ENEMY]])
	if _frame % 30 == 0:
		_scan()
	if _escorts_done < ESCORT_TIMES.size() and _t >= ESCORT_TIMES[_escorts_done]:
		_escorts_done += 1
		for team in [PLAYER, ENEMY]:
			_place_escort(team)
			_place_guard(team)
	# Like a player: from 5:00, every 10 s, a Hunt 75 on a visible enemy near an own champion (once per team).
	if _t >= 300.0 and _frame % 600 == 0:
		for team in [PLAYER, ENEMY]:
			if not _hunt_done.has(team):
				_place_hunt(team)
	if not main.game_over and _t < _minutes * 60.0:
		if _full or _control or _frame % 30 != 0 or not _verdict_reached():
			return false
		_early = true
		print("EARLY STOP at %s (frame %d): both sides hired and every bounty kind is paid (--full plays the match out)" % [
				_clock(_t), _frame])
	_finish()
	return true


## The positive checks only grow (hires, paid bounties): once all hold, the verdict is final but for the
## "never orderable" check, which _scan has run up to here.
func _verdict_reached() -> bool:
	if (_hires[PLAYER] as Array).is_empty() or (_hires[ENEMY] as Array).is_empty():
		return false
	for k in 4:
		if _paid[k] == 0:
			return false
	return true


func _scan() -> void:
	for node in get_nodes_in_group("champions"):
		var ch := node as Unit
		if ch == null:
			continue
		var team := int(ch.team)
		var key := ch.get_instance_id()
		if not _seen_champs.has(key):
			_seen_champs[key] = true
			var id: Variant = ch.call(&"type_id") if ch.has_method(&"type_id") else &"?"
			_hires[team].append([_t, str(id), str(ch.get(&"display_name"))])
			print("  %s hired %s (%s) at %s" % ["player" if team == PLAYER else "enemy", str(id),
					str(ch.get(&"display_name")), _clock(_t)])
			ch.died.connect(func(_u: Variant = null) -> void: _deaths[team] += 1)
			var ab: Node = ch.get(&"abilities")
			if ab and ab.has_signal(&"ability_cast"):
				ab.connect(&"ability_cast", func(_id: StringName) -> void: _casts[team] += 1)
		_max_level[team] = maxi(int(_max_level[team]), int(ch.get(&"level")))
		if ch.has_method(&"is_commandable") and bool(ch.call(&"is_commandable")):
			_orderable_leaks += 1
	for board in get_nodes_in_group("bounty_boards"):
		var key := board.get_instance_id()
		if _boards.has(key):
			continue
		_boards[key] = true
		var bteam := int(board.get(&"team"))
		board.connect(&"bounty_placed", func(b: Node) -> void: _placed[int(b.get(&"kind"))] += 1)
		board.connect(&"bounty_paid", func(b: Node, _c: Node, amount: int) -> void:
			_paid[int(b.get(&"kind"))] += 1
			_paid_essence[bteam] += amount)
	# The player's selection must never pick up a champion (box select / groups / F2 all go through here).
	var sel := _find_selection(main)
	if sel and _frame % 600 == 0:
		var champs: Array = get_nodes_in_group("champions").filter(func(n: Node) -> bool:
			return n is Unit and int(n.get(&"team")) == PLAYER)
		if not champs.is_empty() and sel.has_method(&"orderable_units"):
			var before: Variant = sel.get(&"selected")
			sel.call(&"select_units", champs)
			var ord: Array = sel.call(&"orderable_units")
			for u in ord:
				if u in champs:
					_orderable_leaks += 1
			if before is Array:
				sel.call(&"select_units", before)


func _place_escort(team: int) -> void:
	if not ResourceLoader.exists(BOARD_PATH):
		return
	var board: Node = load(BOARD_PATH).call(&"for_team", team)
	var wiz: Node3D = main.wizard_of(team)
	if board == null or wiz == null or not (wiz as Unit).is_alive():
		_notes.append("%s escort at %s skipped (no board / wizard)" % [team, _clock(_t)])
		return
	var r: String = board.call(&"place", 3, wiz, wiz.global_position)
	print("  %s places Escort on its wizard at %s: %s" % ["player" if team == PLAYER else "enemy", _clock(_t),
			"ok" if r == "" else r])


func _board(team: int) -> Node:
	return load(BOARD_PATH).call(&"for_team", team) if ResourceLoader.exists(BOARD_PATH) else null


## Guard 50 on the own building with the most HP (the keep), where the Oathwall patrols.
func _place_guard(team: int) -> void:
	var board := _board(team)
	if board == null:
		return
	var best: Node3D = null
	var best_hp := -1.0
	for node in get_nodes_in_group("buildings"):
		var b := node as Node3D
		if b == null or int(b.get(&"team")) != team or int(board.call(&"kind_for", b)) != 2:
			continue
		var hp: Variant = b.get(&"max_hp")
		if hp != null and float(hp) > best_hp:
			best_hp = float(hp)
			best = b
	if best == null:
		return
	var r: String = board.call(&"place", 2, best, best.global_position)
	print("  %s places Guard on %s at %s: %s" % ["player" if team == PLAYER else "enemy", best.name, _clock(_t),
			"ok" if r == "" else r])


## Hunt 75 on the visible enemy unit nearest to one of the team's living champions (within 25 m).
func _place_hunt(team: int) -> void:
	var board := _board(team)
	if board == null:
		return
	var champs: Array = get_nodes_in_group("champions").filter(func(n: Node) -> bool:
		return n is Unit and int(n.get(&"team")) == team and (n as Unit).is_alive())
	if champs.is_empty():
		return
	var best: Node3D = null
	var best_d := 25.0
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive() or int(u.team) == team or int(board.call(&"kind_for", u)) != 0:
			continue
		for c: Node3D in champs:
			var d := c.global_position.distance_to(u.global_position)
			if d < best_d:
				best_d = d
				best = u
	if best == null:
		return
	var r: String = board.call(&"place", 0, best, best.global_position)
	if r == "":
		_hunt_done[team] = true
	print("  %s places Hunt on %s at %s: %s" % ["player" if team == PLAYER else "enemy", best.name, _clock(_t),
			"ok" if r == "" else r])


func _find_selection(n: Node) -> Node:
	if n.has_method(&"orderable_units") and n.has_method(&"select_units"):
		return n
	for c in n.get_children():
		var f := _find_selection(c)
		if f:
			return f
	return null


static func _clock(t: Variant) -> String:
	var s := float(t)
	if s < 0.0:
		return "-"
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


func _finish() -> void:
	_scan()
	var winner := "no winner"
	if main.game_over and int(main.winner_team) >= 0:
		winner = "%s wins" % _kingdoms[int(main.winner_team)]
	var ms := (float(_usec) / maxf(1.0, float(_usec_frames))) / 1000.0
	print("RESULT %s:%s: %s at %s | hires P %s / E %s | champion deaths %d / %d | max level %d / %d | casts %d / %d | bounties placed H/X/G/E %s, paid %s | paid essence %d / %d | avg frame %.2f ms" % [
			_kingdoms[PLAYER], _kingdoms[ENEMY], winner, _clock(_t), str(_hires[PLAYER]), str(_hires[ENEMY]),
			_deaths[PLAYER], _deaths[ENEMY], _max_level[PLAYER], _max_level[ENEMY], _casts[PLAYER], _casts[ENEMY],
			str(_placed), str(_paid), _paid_essence[PLAYER], _paid_essence[ENEMY], ms])
	if _control:
		print("CONTROL (no champions): %s at %s" % [winner, _clock(_t)])
		quit()
		return
	for team in [PLAYER, ENEMY]:
		if (_hires[team] as Array).is_empty():
			_errors.append("%s side never hired a champion" % ("player" if team == PLAYER else "enemy"))
	for k in 4:
		if _paid[k] == 0:
			_errors.append("no %s bounty paid (placed %d)" % [KIND_NAMES[k], _placed[k]])
	if _orderable_leaks > 0:
		_errors.append("a champion was orderable %d times" % _orderable_leaks)
	if _early:
		_notes.append("stopped early at %s, match length not measured (--full for 9.D4)" % _clock(_t))
	elif not main.game_over or _t < 14.0 * 60.0 or _t > 22.0 * 60.0:
		_notes.append("match length %s outside 14:00-22:00 (%s): for 9.D4" % [_clock(_t), winner])
	for n in _notes:
		print("note: " + n)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	quit()
