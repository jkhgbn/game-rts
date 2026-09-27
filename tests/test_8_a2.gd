extends SceneTree
## Task 8.A2 (the Fire bot casts Vessa's spells), scenes/skirmish.tscn.
## Part 1: a normal Fire bot (ENEMY, Vessa) vs an idle Shadow player. Vessa gets 750 XP (level 4, 3 points): she
##   learns Q1, F2, E1 (levels.md normal order). 4 held Flame Guards beside her, 4 held Shades in a tight group 10 m
##   away: the first cast comes no sooner than the profile's reaction delay, it is a Fireball ("cluster" rule) that
##   lands on the group, and Kindle follows (her army fights nearby). Then HP 25 % with Shades next to her: Ember
##   Step "escape" (>= 5 m blink) and the Commander's HEAL retreat.
## Part 2: the human's Vessa (PLAYER, no Commander for her team) with the same setup never casts by herself.
## Part 3: fire:shadow bot vs bot (both normal bots, "player:enemy"), cap 24:00: winner / time, casts per rule.
## Run:  godot --headless --path . -s tests/test_8_a2.gd --fixed-fps 60 --quit-after 100000
##   Options after `--`: --skip-match (parts 1-2 only), --minutes=24

const TASK_ID := "8.A2"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const XP_L4 := 750

var main: Node
var bot: Node
var bot2: Node
var part := 0
var _queue: Array[int] = []
var _wait := 0
var _gap := 0
var _t := 0.0
var _frame := 0
var _errors: Array[String] = []
var _results: Array[String] = []
var _minutes := 24.0

# parts 1 / 2
var _step := 0
var _step_at := 0.0
var _vessa: Node
var _casts: Array = []            # [time, id]
var _effects: Array = []          # [time, id, position]
var _cluster := Vector3.ZERO
var _spawn_at := -1.0
var _escape_mark := 0
# part 3
var _match_casts := {PLAYER: 0, ENEMY: 0}
var _army_max := {PLAYER: 0, ENEMY: 0}


func _initialize() -> void:
	var skip_match := false
	for a in OS.get_cmdline_user_args():
		if a == "--skip-match":
			skip_match = true
		elif a.begins_with("--minutes="):
			_minutes = a.trim_prefix("--minutes=").to_float()
	_queue = [1, 2]
	if not skip_match:
		_queue.append(3)
	_next_part()


func _next_part() -> void:
	if _queue.is_empty():
		_finish()
		return
	part = _queue.pop_front()
	_wait = 0
	_frame = 0
	_step = 0
	_casts.clear()
	_effects.clear()
	_vessa = null
	bot = null
	bot2 = null
	main = load(SCENE).instantiate()
	match part:
		1:
			_set_kingdoms(&"shadow", &"fire")
			bot = _bot_for(ENEMY)
			bot.debug_log = true
		2:
			_set_kingdoms(&"fire", &"shadow")
			bot = _bot_for(ENEMY)
			bot.enabled = false
		3:
			_set_kingdoms(&"fire", &"shadow")
			bot = _bot_for(ENEMY)
			bot2 = _bot_for(PLAYER)
	root.add_child(main)
	current_scene = main


func _set_kingdoms(p: StringName, e: StringName) -> void:
	main.set(&"player_kingdom", p)
	main.set(&"enemy_kingdom", e)


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


func _end_part() -> void:
	main.queue_free()
	main = null
	_gap = 3


func _process(_delta: float) -> bool:
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_next_part()
		return false
	if main == null:
		return true
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_frame += 1
	_t = main.match_time()
	match part:
		1:
			_bot_tick()
		2:
			_human_tick()
		3:
			_match_tick()
	return false


# ---------------------------------------------------------------- shared setup

func _watch(w: Node) -> void:
	var c: Object = w.get(&"spell_caster")
	c.connect(&"spell_cast", func(id: StringName) -> void: _casts.append([_t, id]))
	c.connect(&"spell_effect", func(id: StringName, pos: Vector3) -> void: _effects.append([_t, id, pos]))


## 4 held Flame Guards (own team, "scripted" so the Commander leaves them) around `w`, 4 held Shades (the other
## team) in a 1 m grid 10 m from it toward the map centre. Returns the group's centre.
func _spawn_fight(w: Node3D, own: int) -> Vector3:
	var me := w.global_position
	var dir := -me
	dir.y = 0.0
	dir = dir.normalized()
	var side := dir.cross(Vector3.UP)
	for i in 4:
		var g: Unit = main.make_unit("flame_guard")
		g.team = own
		g.add_to_group(&"scripted")
		main.add_child(g)
		g.global_position = me + side * (2.5 if i % 2 == 0 else -2.5) + dir * (1.0 if i < 2 else -1.5)
		g.command_hold()
	var centre := me + dir * 10.0
	for i in 4:
		var s: Unit = main.make_unit("shade")
		s.team = 1 - own
		main.add_child(s)
		s.global_position = centre + side * (0.5 if i % 2 == 0 else -0.5) + dir * (0.5 if i < 2 else -0.5)
		s.command_hold()
	return centre


func _count(id: StringName, since: float = -1.0) -> int:
	var n := 0
	for c in _casts:
		if c[1] == id and float(c[0]) >= since:
			n += 1
	return n


# ---------------------------------------------------------------- part 1: the Fire bot

func _bot_tick() -> void:
	if not bot.get(&"_ready_done") or _t < 2.0:
		return
	var w: Wizard = main.wizard_of(ENEMY)
	match _step:
		0:
			_vessa = w
			if bot.faction != &"fire" or not AICasts.is_vessa(w):
				_errors.append("part 1: bot faction %s, wizard spells %s" % [bot.faction, str(w.spell_ids())])
			_watch(w)
			w.add_xp(XP_L4)
			_step = 1
			_step_at = _t
			print("part 1: Fire bot profile %s (%s), Vessa level %d, points %d, reaction %.1f s" % [bot.ai.id,
					bot.ai.profile_id, w.level, w.spell_points, bot.ai.reaction_delay])
		1:
			if _t - _step_at < 2.5:
				return
			var want: Array[String] = ["Q1", "F2", "E1"]
			if bot.spells_learned != want or w.spell_rank(&"fireball") != 2 or w.spell_rank(&"ember_step") != 1 \
					or w.spell_rank(&"kindle") != 1:
				_errors.append("part 1: learned %s (ranks F %d Q %d E %d), want Q1 F2 E1" % [str(bot.spells_learned),
						w.spell_rank(&"fireball"), w.spell_rank(&"ember_step"), w.spell_rank(&"kindle")])
			print("part 1: learned %s at level %d, casts owned %s" % [str(bot.spells_learned), w.level,
					str(bot.casts_owned)])
			if not _casts.is_empty():
				_errors.append("part 1: cast %s before any enemy came near" % str(_casts))
			w.mana = w.max_mana
			_cluster = _spawn_fight(w, ENEMY)
			_spawn_at = _t
			_step = 2
		2:
			if _t - _spawn_at < 7.0:
				return
			var fb := -1.0
			for c in _casts:
				if c[1] == &"fireball":
					fb = float(c[0])
					break
			var first := float(_casts[0][0]) if not _casts.is_empty() else -1.0
			var hit := Vector3.INF
			for e in _effects:
				if e[1] == &"fireball":
					hit = e[2]
					break
			print("part 1: casts %s, rules %s, first cast %.2f s after the spawn, first Fireball at %s (group %s)" % [
					str(_casts.map(func(c: Array) -> String: return "%.1f %s" % [c[0] - _spawn_at, c[1]])),
					str(bot.vessa_casts), first - _spawn_at, str(hit), str(_cluster)])
			if fb < 0.0:
				_errors.append("part 1: no Fireball on the cluster")
			elif int(bot.vessa_casts.get("cluster", 0)) < 1:
				_errors.append("part 1: Fireball not from the cluster rule (%s)" % str(bot.vessa_casts))
			elif Vector2(hit.x - _cluster.x, hit.z - _cluster.z).length() > 2.0:
				_errors.append("part 1: Fireball landed at %s, group at %s" % [str(hit), str(_cluster)])
			if first >= 0.0 and first - _spawn_at < float(bot.ai.reaction_delay) - 0.05:
				_errors.append("part 1: first cast %.2f s after the threat (reaction %.1f)" % [first - _spawn_at,
						bot.ai.reaction_delay])
			if _count(&"kindle") < 1:
				_errors.append("part 1: no Kindle with 4 Flame Guards beside her and Shades 10 m away")
			# escape: Shades next to her, HP 25 %, full mana
			var me := w.global_position
			for i in 2:
				var s: Unit = main.make_unit("shade")
				s.team = PLAYER
				main.add_child(s)
				s.global_position = me + Vector3(1.5 if i == 0 else -1.5, 0.0, 1.0)
			w.mana = w.max_mana
			w.hp = w.max_hp * 0.25
			_escape_mark = _effects.size()
			_step = 3
			_step_at = _t
		3:
			if _t - _step_at < 3.0:
				return
			var origin := Vector3.INF
			var arrive := Vector3.INF
			for i in range(_escape_mark, _effects.size()):
				var e: Array = _effects[i]
				if e[1] == &"ember_step" and origin == Vector3.INF:
					origin = e[2]
				elif e[1] == &"ember_step_arrive" and arrive == Vector3.INF:
					arrive = e[2]
			var blink := Vector2(arrive.x - origin.x, arrive.z - origin.z).length() if arrive != Vector3.INF else 0.0
			var state := int(bot.get(&"_hero_state"))
			print("part 1: escape rules %s, blink %.1f m, hero state %d, HP %.0f / %.0f" % [str(bot.vessa_casts),
					blink, state, w.hp, w.max_hp])
			if int(bot.vessa_casts.get("escape", 0)) < 1 or blink < 5.0:
				_errors.append("part 1: no Ember Step escape at 25 %% HP (rules %s, blink %.1f m)" % [
						str(bot.vessa_casts), blink])
			if state != COMMANDER.HeroState.HEAL:
				_errors.append("part 1: after the escape the hero state is %d, want HEAL" % state)
			for line in bot.log_lines:
				if line.contains("WIZARD"):
					print("  " + line)
			_end_part()


# ---------------------------------------------------------------- part 2: the human's Vessa

func _human_tick() -> void:
	if _t < 2.0:
		return
	var w: Wizard = main.wizard_of(PLAYER)
	match _step:
		0:
			_vessa = w
			_watch(w)
			w.add_xp(XP_L4)
			w.learn_spell(&"ember_step")
			w.learn_spell(&"kindle")
			w.mana = w.max_mana
			_cluster = _spawn_fight(w, PLAYER)
			_step = 1
			_step_at = _t
		1:
			if _t - _step_at < 8.0:
				return
			print("part 2: the human's Vessa (level %d, ranks F %d Q %d E %d): %d casts in 8 s next to a cluster" % [
					w.level, w.spell_rank(&"fireball"), w.spell_rank(&"ember_step"), w.spell_rank(&"kindle"),
					_casts.size()])
			if not _casts.is_empty():
				_errors.append("part 2: the human's Vessa cast by herself: %s" % str(_casts))
			_end_part()


# ---------------------------------------------------------------- part 3: fire:shadow bot vs bot

func _match_tick() -> void:
	if _step == 0:
		if not bot.get(&"_ready_done") or not bot2.get(&"_ready_done"):
			return
		_step = 1
		for team in [PLAYER, ENEMY]:
			var c: Object = main.wizard_of(team).get(&"spell_caster")
			c.connect(&"spell_cast", func(_id: StringName) -> void: _match_casts[team] += 1)
		print("part 3: fire:shadow, player bot %s (%s) vs enemy bot %s (%s)" % [bot2.ai.id, bot2.faction, bot.ai.id,
				bot.faction])
	if _frame % 60 == 0:
		for team in [PLAYER, ENEMY]:
			_army_max[team] = maxi(int(_army_max[team]), _army_pop(team))
	if _frame % 18000 == 0:
		print("  [%d:%02d] army pop %d / %d, gathered %d / %d, Vessa rules %s, casts %d / %d" % [int(_t) / 60,
				int(_t) % 60, _army_pop(PLAYER), _army_pop(ENEMY), Economy.for_team(PLAYER).gathered_total,
				Economy.for_team(ENEMY).gathered_total, str(bot2.vessa_casts), _match_casts[PLAYER],
				_match_casts[ENEMY]])
	if not main.game_over and _t < _minutes * 60.0:
		return
	var winner := "no winner"
	if main.game_over and int(main.winner_team) >= 0:
		winner = "%s wins" % ("fire" if int(main.winner_team) == PLAYER else "shadow")
	var line := "MATCH fire:shadow: %s at %d:%02d | army pop %d / %d (max %d / %d) | gathered %d / %d | attacks %d / %d | wizard lvl %d / %d | casts %d / %d | Vessa rules %s" % [
			winner, int(_t) / 60, int(_t) % 60, _army_pop(PLAYER), _army_pop(ENEMY), _army_max[PLAYER],
			_army_max[ENEMY], Economy.for_team(PLAYER).gathered_total, Economy.for_team(ENEMY).gathered_total,
			bot2.attacks_launched, bot.attacks_launched, (main.wizard_of(PLAYER) as Unit).level,
			(main.wizard_of(ENEMY) as Unit).level, _match_casts[PLAYER], _match_casts[ENEMY], str(bot2.vessa_casts)]
	_results.append(line)
	print(line)
	if int(_match_casts[PLAYER]) == 0:
		_errors.append("part 3: the Fire bot never cast in the match")
	_end_part()


func _army_pop(team: int) -> int:
	var pop := 0
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == team and not u is Wizard and u.unit_type \
				and not u.unit_type.is_worker and not AICasts.is_summon(u):
			pop += u.unit_type.pop
	return pop


# ---------------------------------------------------------------- end

func _finish() -> void:
	for r in _results:
		print(r)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	quit()
