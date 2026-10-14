extends SceneTree
## B13 Cause 2 (docs/balance/b13_2026-10-13/diagnosis.md), ai-coder part: a bot wizard without a ready escape goes
## home from 50 % HP when a foe fighter is near, around it (not through it), and casts on chasers; with a ready
## escape (or as Vessa) the line stays 35 %.
## Static part (AICasts): low_hp_line, retreat_point geometry, suggest_retreat_cast (Malrik Soul Siphon on 2 chasers).
## Live part (normal-difficulty Shadow bot on Crown Hollow): Malrik 30 m out from his keep, a rooted foe 7 m away on
## his way home. A: Umbral Shroud not learned, 45 % HP -> the bot retreats and his distance to the foe grows.
## B: Shroud learned and ready, 45 % HP -> no retreat.
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_bal_cause2.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "bal_cause2"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const TIMEOUT_FRAMES := 6000
const WATCH_FRAMES := 300   # 5 s per phase

var _errors: Array[String] = []
var _level: Node
var _bot: Node
var _w: Wizard
var _chaser: Unit
var _home := Vector3.ZERO
var _spot := Vector3.ZERO
var _frame := 0
var _phase := 0
var _phase_frame := 0
var _retreats_before := 0
var _start_dist := 0.0
var _min_dist := INF


func _initialize() -> void:
	AICasts.retreat_rule = true   # the Cause 2 switch is OFF by default (lead 2026-10-14)
	_level = load(SCENE).instantiate()
	_level.name = "Cause2Level"   # keep MenuFlow's restart hook (settings pace / kingdoms) off this test level
	_level.set(&"player_kingdom", &"fire")
	_level.set(&"enemy_kingdom", &"shadow")
	_bot = _bot_for(1)
	root.add_child(_level)
	current_scene = _level


func _bot_for(team: int) -> Node:
	for child in _level.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			child.difficulty = 1
			child.profile = null
			child.profile_id = &""
			return child
	var b: Node = COMMANDER.new()
	b.team = team
	b.difficulty = 1
	_level.add_child(b)
	return b


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame > TIMEOUT_FRAMES:
		_errors.append("timed out in phase %d" % _phase)
		return _finish()
	match _phase:
		0:
			if not is_instance_valid(_bot) or _bot.get(&"faction") == &"" or not bool(_level.get(&"match_started")):
				return false
			_w = _level.call(&"wizard_of", 1)
			if _w == null or _w.spell_caster == null:
				return false
			_setup_scene()
			_static_checks()
			_start_phase_a()
		1:
			_phase_frame += 1
			_track()
			if _phase_frame >= WATCH_FRAMES:
				_end_phase_a()
		2:
			_phase_frame += 1
			if _phase_frame == 120:   # healed: rule 8 left HEAL; now the ready-escape case
				_start_phase_b()
		3:
			_phase_frame += 1
			if _phase_frame >= WATCH_FRAMES:
				var n := int(_bot.get(&"hero_retreats")) - _retreats_before
				if n != 0:
					_errors.append("B: Malrik with Umbral Shroud ready retreated at 45 %% HP (%d)" % n)
				print("B: ready escape, retreats %d" % n)
				return _finish()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


func _setup_scene() -> void:
	var keep: Node = _level.call(&"keep_of", 1)
	_home = keep.call(&"drop_off_point")
	var out := -_home
	out.y = 0.0
	_spot = _home + out.normalized() * 30.0
	_w.set_down(_spot)
	_spot = _w.global_position
	# A rooted, very sturdy foe on Malrik's way home, 7 m from him.
	var toward := _home - _spot
	toward.y = 0.0
	_chaser = _level.call(&"make_unit", "flame_guard")
	_chaser.set(&"team", Unit.Team.PLAYER)
	_level.add_child(_chaser)
	_chaser.set_down(_spot + toward.normalized() * 7.0)
	_chaser.add_modifier(&"test:cause2", {"max_hp": 20000.0})
	_chaser.hp = _chaser.get_stat(&"max_hp")
	_chaser.apply_status(&"rooted", 60.0)


func _static_checks() -> void:
	var me := _spot
	var fighters: Array[Unit] = [_chaser]
	# Switch off = the pre-Cause-2 rule (35 %, straight home, no chaser cast).
	AICasts.retreat_rule = false
	(_w.spell_caster as SpellCaster).set_rank(&"umbral_shroud", 0)
	if not is_equal_approx(AICasts.low_hp_line(_w, true), 0.35) or AICasts.retreat_point(me, _home, fighters) != _home:
		_errors.append("switch off still changes the line / the path")
	AICasts.retreat_rule = true
	var p := AICasts.retreat_point(me, _home, fighters)
	var d_now := _flat(me, _chaser.global_position)
	if _flat(p, _chaser.global_position) <= d_now + 3.0:
		_errors.append("retreat_point %s goes toward the foe (foe %.1f m now, %.1f m from the point)" % [str(p), d_now,
				_flat(p, _chaser.global_position)])
	# Foe behind him (not on the way home): straight home.
	var behind := _chaser.global_position + (_chaser.global_position - me)   # past the foe, toward home
	if AICasts.retreat_point(behind, _home, fighters) != _home:
		_errors.append("retreat_point detours although the foe is behind")
	if AICasts.retreat_point(me, _home, [] as Array[Unit]) != _home:
		_errors.append("retreat_point without foes is not home")
	# Lines.
	var c := _w.spell_caster as SpellCaster
	c.set_rank(&"umbral_shroud", 0)
	if AICasts.escape_spell(_w) != &"umbral_shroud":
		_errors.append("Malrik's escape spell = %s" % AICasts.escape_spell(_w))
	if not is_equal_approx(AICasts.low_hp_line(_w, true), 0.5) or not is_equal_approx(AICasts.low_hp_line(_w, false), 0.35):
		_errors.append("Malrik without Shroud: lines %.2f / %.2f (want 0.5 chased / 0.35)" % [AICasts.low_hp_line(_w, true),
				AICasts.low_hp_line(_w, false)])
	c.set_rank(&"umbral_shroud", 1)
	_w.mana = _w.get_stat(&"max_mana")
	if not is_equal_approx(AICasts.low_hp_line(_w, true), 0.35):
		_errors.append("Malrik with Shroud ready: line %.2f (want 0.35)" % AICasts.low_hp_line(_w, true))
	c.set_rank(&"umbral_shroud", 0)
	var vessa: Wizard = _level.call(&"wizard_of", 0)
	if vessa and AICasts.is_vessa(vessa) and not is_equal_approx(AICasts.low_hp_line(vessa, true), 0.35):
		_errors.append("Vessa's line moved: %.2f" % AICasts.low_hp_line(vessa, true))
	# Retreat cast: Soul Siphon on 2 chasers (in range), not on 1.
	c.set_rank(&"soul_siphon", maxi(1, c.rank_of(&"soul_siphon")))
	_w.mana = _w.get_stat(&"max_mana")
	var one := AICasts.suggest_retreat_cast(_w, fighters)
	if not one.is_empty():
		_errors.append("retreat cast on a single chaser: %s" % str(one))
	var second: Unit = _level.call(&"make_unit", "flame_guard")
	second.set(&"team", Unit.Team.PLAYER)
	_level.add_child(second)
	second.set_down(_chaser.global_position + Vector3(1.0, 0.0, 0.0))
	var two := AICasts.suggest_retreat_cast(_w, [_chaser, second] as Array[Unit])
	if StringName(str(two.get("spell_id", ""))) != &"soul_siphon":
		_errors.append("no Soul Siphon on 2 chasers: %s" % str(two))
	second.queue_free()
	print("static: retreat point %s (foe %.1f m -> %.1f m), siphon %s" % [str(p), d_now, _flat(p, _chaser.global_position),
			str(two.get("spell_id", ""))])


func _start_phase_a() -> void:
	(_w.spell_caster as SpellCaster).set_rank(&"umbral_shroud", 0)
	_w.hp = _w.max_hp * 0.45
	_retreats_before = int(_bot.get(&"hero_retreats"))
	_start_dist = _flat(_w.global_position, _chaser.global_position)
	_min_dist = _start_dist
	_phase = 1
	_phase_frame = 0


func _track() -> void:
	if not _w.is_alive():
		return
	_min_dist = minf(_min_dist, _flat(_w.global_position, _chaser.global_position))


func _end_phase_a() -> void:
	var n := int(_bot.get(&"hero_retreats")) - _retreats_before
	var d := _flat(_w.global_position, _chaser.global_position)
	print("A: no escape, retreats %d, foe %.1f m -> %.1f m (closest %.1f), HP %.0f %%" % [n, _start_dist, d, _min_dist,
			100.0 * _w.hp / _w.max_hp])
	if n < 1:
		_errors.append("A: Malrik at 45 %% HP without an escape and a foe near did not retreat")
	if d < _start_dist + 3.0:
		_errors.append("A: Malrik did not get away from the foe (%.1f -> %.1f m)" % [_start_dist, d])
	if _min_dist < _start_dist - 2.0:
		_errors.append("A: Malrik walked toward the foe (closest %.1f m, start %.1f m)" % [_min_dist, _start_dist])
	_w.hp = _w.max_hp   # healed: rule 8 leaves HEAL on its next tick
	_phase = 2
	_phase_frame = 0


func _start_phase_b() -> void:
	var c := _w.spell_caster as SpellCaster
	c.set_rank(&"umbral_shroud", 1)
	_w.mana = _w.get_stat(&"max_mana")
	_w.set_down(_spot)
	_w.hp = _w.max_hp * 0.45
	_retreats_before = int(_bot.get(&"hero_retreats"))
	_phase = 3
	_phase_frame = 0


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
