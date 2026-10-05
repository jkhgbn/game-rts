extends SceneTree
## Seat-bias root cause (2026-10-05, map gate G5 on Thornwater): a bot driving the PLAYER team (Bot Lab, map gate)
## never used its wizard's STR / INT path ability (Vigor / Snow Shield): StrIntPath turned auto_use off for the
## human's wizard (`hero`) and nothing turned it on for a bot. Fix: Commander._take_casting calls
## StrIntPath.set_bot_driven(). Checks, on scenes/skirmish.tscn with a second Commander for the PLAYER (as lab_match.gd):
## - both wizards' StrIntPath have auto_use (and the PLAYER's bot_driven) once the Commanders think;
## - the PLAYER bot's wizard really uses the ability when hurt in a fight (the bot rule), like the ENEMY's;
## - a plain StrIntPath on a human's wizard (no Commander) keeps auto_use off (the human presses J).
## Run:  godot --headless --path . -s tests/test_seat_bias_fix.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "seat_bias_fix"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER_PATH := "res://scripts/ai/commander.gd"

var main: Node
var _wait := 0
var _frame := 0
var _errors: Array[String] = []
var _stage := 0
var _t := 0.0
var _t_hit := 0.0


func _initialize() -> void:
	StrIntPath.force_auto = true
	main = load(SCENE).instantiate()
	var bot: Node = (load(COMMANDER_PATH) as Script).new()
	bot.name = "TestBotPlayer"
	bot.set(&"team", Unit.Team.PLAYER)
	main.add_child(bot)
	root.add_child(main)
	current_scene = main


func _check(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)


func _process(delta: float) -> bool:
	if main.get(&"hero") == null or main.get(&"shadow_hero") == null or not bool(main.get(&"match_started")):
		_wait += 1
		if _wait > 6000:
			print("FAIL %s: map never ready" % TASK_ID)
			return true
		return false
	_frame += 1
	_t += delta
	if _stage == 0 and _t > 3.0:
		_flags()
		_hurt()
		_stage = 1
	elif _stage == 1 and _t - _t_hit > 1.5:
		_used()
		_human_default()
		return _finish()
	if _frame > 8000:
		_errors.append("timed out at stage %d" % _stage)
		return _finish()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


func _flags() -> void:
	var ph := StrIntPath.of(main.get(&"hero"))
	var pe := StrIntPath.of(main.get(&"shadow_hero"))
	_check(ph != null and pe != null, "wizards have no StrIntPath")
	if ph == null or pe == null:
		return
	_check(ph.path != &"" and pe.path != &"", "no path picked")
	_check(ph.bot_driven and ph.auto_use, "PLAYER bot's wizard: bot_driven %s auto_use %s" % [ph.bot_driven, ph.auto_use])
	_check(pe.auto_use, "ENEMY bot's wizard: auto_use off")


## Both wizards drop to 50 % HP from a hit by the other side: the bot rule (STR < 60 % / INT < 85 %, hit just now)
## fires on both.
func _hurt() -> void:
	for pair: Array in [[main.get(&"hero"), main.get(&"shadow_hero")], [main.get(&"shadow_hero"), main.get(&"hero")]]:
		var w: Unit = pair[0]
		var by: Unit = pair[1]
		w.hp = w.get_stat(&"max_hp") * 0.5 + 1.0
		w.take_damage(1.0, by)
	_t_hit = _t


func _used() -> void:
	for key: StringName in [&"hero", &"shadow_hero"]:
		var p := StrIntPath.of(main.get(key))
		if p == null:
			continue
		_check(p.is_active() or p.cooldown_left() > 0.0, "%s (%s) did not use %s when hurt" % [key, p.path, p.ability_name()])


func _human_default() -> void:
	var p := StrIntPath.new()
	_check(not p.auto_use and not p.bot_driven, "a fresh StrIntPath auto-uses")
	p.set_bot_driven()
	_check(p.auto_use, "set_bot_driven did not turn auto_use on")
	p.free()
