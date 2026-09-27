extends SceneTree
## Task 3.A1: the bot learns and casts spells (levels.md "The bot"). On scenes/skirmish.tscn with the
## normal Shadow bot and a passive player:
## 1. Malrik gets 3 levels of XP -> on the next ticks he learns Q1, F2, E1 in that order (normal list).
## 2. Vessa placed 8 m from a full-HP Malrik -> he casts Shadow Lance on her (one cast owner, no double).
## 3. Strength: Malrik (level 4) is worth 170 + 30 x 4; a Shade that becomes a Veteran raises
##    own_strength by 0.2 x its cost; a dead Vessa leaves seen_strength.
## Run:  godot --headless --path . -s tests/test_3_a1.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "3.A1"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const MEMORY := preload("res://scripts/ai/ai_memory.gd")
const SHADOW := 1
const TIMEOUT_FRAMES := 3600

var main: Node
var bot: Node
var malrik   # ShadowWizard (untyped: shadow_lance_cast)
var vessa: Wizard
var frame := 0
var _wait := 0
var _step := 0
var _step_at := 0.0
var _errors: Array[String] = []
var _lances_on_vessa := 0
var _casts := 0
var _cast_times: Array[float] = []
var _shade: Unit
var _str_before := 0.0


func _initialize() -> void:
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
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out at step %d" % _step)
		return _finish()
	var t: float = main.match_time()
	match _step:
		0:
			malrik = main.wizard_of(SHADOW)
			vessa = main.wizard_of(0)
			if int(bot.difficulty) != 1:
				_errors.append("bot is not normal")
			malrik.spell_caster.spell_cast.connect(func(id: StringName) -> void:
				_casts += 1
				_cast_times.append(main.match_time()))
			malrik.shadow_lance_cast.connect(func(target: Unit) -> void:
				if target == vessa:
					_lances_on_vessa += 1)
			# Level 1 -> 4 (one level at a time, a tick apart is not needed: the list order decides).
			for i in 3:
				malrik.add_xp(malrik.xp_to_next())
			print("Malrik level %d, points %d" % [malrik.level, malrik.spell_points])
			_next(t)
		1:
			if t - _step_at < 2.5:
				return false
			var ranks := "F%d Q%d E%d" % [malrik.spell_rank(&"shadow_lance"), malrik.spell_rank(&"soul_siphon"),
					malrik.spell_rank(&"umbral_shroud")]
			print("learned %s -> ranks %s, points left %d" % [str(bot.spells_learned), ranks, malrik.spell_points])
			if str(bot.spells_learned) != str(["Q1", "F2", "E1"]):
				_errors.append("learn order %s (want Q1, F2, E1)" % str(bot.spells_learned))
			if ranks != "F2 Q1 E1":
				_errors.append("ranks %s (want F2 Q1 E1)" % ranks)
			if malrik.spell_points != 0:
				_errors.append("%d points left" % malrik.spell_points)
			var ws: float = MEMORY.strength_of(malrik)
			print("Malrik strength %.0f" % ws)
			if absf(ws - 290.0) > 0.01:
				_errors.append("level-4 wizard strength %.0f (want 290)" % ws)
			# Vessa walks into Malrik's lance range; Malrik at full HP and mana.
			malrik.hp = malrik.max_hp
			malrik.mana = malrik.max_mana
			vessa.global_position = malrik.global_position + Vector3(6.0, 0.0, 5.0)
			vessa.command_stop()
			_casts = 0
			_cast_times.clear()
			_next(t)
		2:
			if _lances_on_vessa > 0 or t - _step_at > 4.0:
				print("lances on Vessa %d, casts %d at %s" % [_lances_on_vessa, _casts, str(_cast_times)])
				if _lances_on_vessa == 0:
					_errors.append("no Shadow Lance on Vessa within 4 s")
				for i in range(1, _cast_times.size()):
					if _cast_times[i] - _cast_times[i - 1] < 0.4:
						_errors.append("two casts %.2f s apart (double caster?)" % (_cast_times[i] - _cast_times[i - 1]))
				# Get Vessa out of the way again (she stays alive for the last step).
				vessa.global_position = main.start_position(0)
				vessa.command_stop()
				# A Shade for the veterancy check, parked at the rally.
				_shade = main.make_unit("shade")
				_shade.team = SHADOW
				main.add_child(_shade)
				_shade.global_position = Vector3(30.0, 0.0, -30.0)
				_shade.command_stop()
				_next(t)
		3:
			if t - _step_at < 2.5:
				return false
			_str_before = bot.own_strength
			_shade.add_xp(Unit.VETERANCY_XP[1])   # Veteran (120 XP since balance-1)
			print("shade level %d, own_strength before %.0f" % [_shade.level, _str_before])
			_next(t)
		4:
			if t - _step_at < 2.5:
				return false
			var cost: float = float(_shade.unit_type.cost)
			var gain: float = bot.own_strength - _str_before
			print("own_strength after %.0f (gain %.1f, want %.1f)" % [bot.own_strength, gain, 0.2 * cost])
			if _shade.level != 2:
				_errors.append("shade level %d after Veteran XP" % _shade.level)
			elif absf(gain - 0.2 * cost) > 0.5:
				_errors.append("veteran gain %.1f (want %.1f)" % [gain, 0.2 * cost])
			# Seen Vessa: bring her next to the Shade so the bot sees her, then kill her.
			vessa.global_position = Vector3(26.0, 0.0, -26.0)
			vessa.command_stop()
			_next(t)
		5:
			if t - _step_at < 2.5:
				return false
			var seen_alive: float = bot.seen_strength
			vessa.take_damage(100000.0, null)
			print("seen_strength with Vessa %.0f" % seen_alive)
			_str_before = seen_alive
			_next(t)
		6:
			if t - _step_at < 2.5:
				return false
			print("seen_strength after Vessa died %.0f" % bot.seen_strength)
			if _str_before < 200.0:
				_errors.append("Vessa never entered seen_strength (%.0f)" % _str_before)
			elif bot.seen_strength > _str_before - 199.0:
				_errors.append("dead Vessa still counted (%.0f -> %.0f)" % [_str_before, bot.seen_strength])
			return _finish()
	return false


func _next(t: float) -> void:
	_step += 1
	_step_at = t


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true
