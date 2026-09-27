extends SceneTree
## STR / INT path (docs/design/level-boons.md "STR / INT path"), scenes/skirmish.tscn headless.
## - both skirmish wizards auto-pick at 0:00 by kingdom (Fire Vessa -> INT, Shadow Malrik -> STR), locked after;
##   AIStrInt.choose for the 4 kingdoms; a wizard outside a skirmish host has no path until choose();
## - modifiers: STR = attack_damage x1.15, max_hp x1.20; INT = spell_power +15, max_mana x1.25;
## - Vigor (STR): hp_regen modifier + red-gold VFX visible while active, "Active" refusal, ends after
##   ABILITY_DURATION, then "On cooldown" for ABILITY_COOLDOWN, then ready again;
## - Snow Shield (INT): shield given, frost VFX visible, a broken shield ends it early (cooldown starts);
## - VFX adds 0 lights; the bot wizard uses its ability when hurt in a fight.
## Run:  godot --headless --path . -s tests/test_str_int.gd --fixed-fps 60 --quit-after 12000

const TASK_ID := "str_int"
const SCENE := "res://scenes/skirmish.tscn"

var main: Node
var _wait := 0
var _frame := 0
var _errors: Array[String] = []
var w_str: Node = null
var w_int: Node = null
var w_brk: Node = null
var _t_act := 0.0
var _t := 0.0
var _stage := 0


func _initialize() -> void:
	StrIntPath.force_auto = true
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main


func _check(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)


func _process(delta: float) -> bool:
	if main.get(&"hero") == null or main.get(&"shadow_hero") == null:
		_wait += 1
		if _wait > 6000:
			print("FAIL %s: map never ready" % TASK_ID)
			return true
		return false
	_frame += 1
	_t += delta
	if _frame == 5:
		_static_and_picks()
		_make_fresh()
	elif _frame == 8:
		_stats_and_start()
	elif _stage == 1 and _t - _t_act > StrIntPath.ABILITY_DURATION + 0.5:
		_after_expiry()
	elif _stage == 2 and _t - _t_act > StrIntPath.ABILITY_DURATION + StrIntPath.ABILITY_COOLDOWN + 1.0:
		_after_cooldown()
		return _finish()
	if not _errors.is_empty():
		return _finish()
	if _frame > 11000:
		_errors.append("timed out at stage %d" % _stage)
		return _finish()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


func _static_and_picks() -> void:
	_check(StrIntPath.ENABLED, "switch ENABLED is off")
	_check(AIStrInt.choose(&"fire") == &"int" and AIStrInt.choose(&"ice") == &"int"
			and AIStrInt.choose(&"shadow") == &"str" and AIStrInt.choose(&"nature") == &"str", "AIStrInt kingdom rule")
	var hero: Node = main.get(&"hero")
	var bot: Node = main.get(&"shadow_hero")
	var ph := StrIntPath.of(hero)
	var pb := StrIntPath.of(bot)
	_check(ph != null and pb != null, "wizards have no StrIntPath")
	if ph == null or pb == null:
		return
	_check(ph.path == AIStrInt.choose(hero.get(&"kingdom")), "player auto-pick %s" % ph.path)
	_check(pb.path == AIStrInt.choose(bot.get(&"kingdom")), "bot pick %s" % pb.path)
	_check(ph.in_match and pb.in_match, "skirmish host not found")
	_check(pb.auto_use and not ph.auto_use, "auto_use flags")
	_check(ph.choose(&"str") == "Already chosen" and pb.choose(&"int") == "Already chosen", "choice not locked")
	_check(hero.call(&"has_modifier", StringName("path:" + String(ph.path))), "player path modifier missing")
	print("picks: player %s (%s) -> %s, bot %s (%s) -> %s" % [hero.get(&"kingdom"), hero.get(&"unit_name"), ph.path,
			bot.get(&"kingdom"), bot.get(&"unit_name"), pb.path])


func _make_fresh() -> void:
	# Outside the skirmish host (child of root): no path until choose().
	var at: Vector3 = (main.get(&"hero") as Node3D).global_position
	var ws: Array[Node] = []
	for i in 4:
		var w := Wizard.new()
		w.team = Unit.Team.PLAYER
		root.add_child(w)
		w.global_position = at + Vector3(2.0 * (i + 1), 0.0, -2.0)
		ws.append(w)
	w_str = ws[0]
	w_int = ws[1]
	w_brk = ws[2]
	_panel_check(ws[3])


## The start panel pauses the game until a path is taken, then shows the ability button and resumes.
func _panel_check(w: Node) -> void:
	var p := StrIntPath.of(w)
	if p == null:
		_errors.append("panel wizard has no StrIntPath")
		return
	var panel := StrIntPanel.new()
	root.add_child(panel)
	panel.open_for(p)
	_check(paused, "panel did not pause the game")
	_check(p.choose(&"str") == "", "panel wizard choose")
	panel.on_path_chosen()
	_check(not paused, "panel did not resume the game")
	var buttons := panel.find_children("*", "Button", true, false)
	var ability := 0
	for b: Node in buttons:
		if (b as Button).focus_mode == Control.FOCUS_NONE:
			ability += 1
	_check(ability == 1, "ability button count %d" % ability)
	panel.queue_free()


func _stats_and_start() -> void:
	var ps := StrIntPath.of(w_str)
	var pi := StrIntPath.of(w_int)
	var pk := StrIntPath.of(w_brk)
	_check(ps != null and ps.path == &"" and not ps.in_match, "fresh wizard picked without a host")
	if ps == null or pi == null or pk == null:
		return
	_check(ps.activate() == "No path", "activate before a path")
	var hp0 := float(w_str.call(&"get_stat", &"max_hp"))
	var ad0 := float(w_str.call(&"get_stat", &"attack_damage"))
	var sp0 := float(w_int.call(&"get_stat", &"spell_power"))
	var mm0 := float(w_int.call(&"get_stat", &"max_mana"))
	_check(ps.choose(&"xyz") == "Unknown path", "unknown path accepted")
	_check(ps.choose(&"str") == "", "choose str")
	_check(ps.choose(&"int") == "Already chosen", "fresh str not locked")
	_check(pi.choose(&"int") == "", "choose int")
	_check(pk.choose(&"int") == "", "choose int (break)")
	var hp1 := float(w_str.call(&"get_stat", &"max_hp"))
	var ad1 := float(w_str.call(&"get_stat", &"attack_damage"))
	var sp1 := float(w_int.call(&"get_stat", &"spell_power"))
	var mm1 := float(w_int.call(&"get_stat", &"max_mana"))
	_check(absf(hp1 - roundf(hp0 * 1.2)) <= 1.0, "STR max_hp %.1f -> %.1f" % [hp0, hp1])
	_check(absf(ad1 - ad0 * 1.15) < 0.01, "STR attack_damage %.2f -> %.2f" % [ad0, ad1])
	_check(absf(sp1 - sp0 - 15.0) < 0.01, "INT spell_power %.1f -> %.1f" % [sp0, sp1])
	_check(absf(mm1 - mm0 * 1.25) < 0.01 and absf(float(w_int.get(&"max_mana")) - mm1) < 0.01,
			"INT max_mana %.1f -> %.1f" % [mm0, mm1])
	print("stats: STR max_hp %.0f -> %.0f, attack %.1f -> %.1f; INT spell_power %.0f -> %.0f, max_mana %.0f -> %.0f"
			% [hp0, hp1, ad0, ad1, sp0, sp1, mm0, mm1])
	var lights_before := _count_lights(root)
	# Vigor
	_check(ps.activate() == "", "Vigor refused")
	_check(ps.is_active() and w_str.call(&"has_modifier", &"path:vigor"), "Vigor modifier missing")
	_check(float(w_str.call(&"get_stat", &"hp_regen")) >= hp1 * StrIntPath.VIGOR_REGEN_PCT - 0.01, "Vigor hp_regen")
	_check(ps.vfx != null and ps.vfx.call(&"is_showing"), "Vigor VFX not visible")
	_check(ps.activate() == "Active", "second activate not refused")
	# Snow Shield
	_check(pi.activate() == "", "Snow Shield refused")
	var sh := float(w_int.get(&"shield"))
	_check(sh >= float(w_int.get(&"max_hp")) * StrIntPath.SNOW_SHIELD_HP_PCT, "Snow Shield amount %.1f" % sh)
	_check(pi.vfx != null and pi.vfx.call(&"is_showing"), "Snow Shield VFX not visible")
	_check(pk.activate() == "", "Snow Shield (break) refused")
	w_brk.call(&"take_damage", float(w_brk.get(&"shield")) * 3.0 + 20.0, null)
	_check(_count_lights(root) == lights_before, "VFX added lights")
	_t_act = _t
	_stage = 1
	# Bot use: hurt the Shadow bot wizard in a fight.
	var bot: Node = main.get(&"shadow_hero")
	bot.set(&"hp", float(bot.get(&"max_hp")) * 0.5)
	bot.call(&"take_damage", 5.0, main.get(&"hero"))
	print("abilities started: shield %.0f" % sh)


func _after_expiry() -> void:
	_stage = 2
	var ps := StrIntPath.of(w_str)
	var pi := StrIntPath.of(w_int)
	var pk := StrIntPath.of(w_brk)
	_check(pk.cooldown_left() < StrIntPath.ABILITY_COOLDOWN - StrIntPath.ABILITY_DURATION + 1.0
			and pk.cooldown_left() > 0.0, "broken shield did not end early (cd %.1f)" % pk.cooldown_left())
	for p: StrIntPath in [ps, pi]:
		_check(not p.is_active(), "%s still active" % p.path)
		_check(not p.vfx.call(&"is_showing"), "%s VFX still visible" % p.path)
		_check(p.cooldown_left() > StrIntPath.ABILITY_COOLDOWN - 2.0, "%s cooldown %.1f" % [p.path, p.cooldown_left()])
		_check(p.activate() == "On cooldown", "%s not on cooldown" % p.path)
	_check(not w_str.call(&"has_modifier", &"path:vigor"), "Vigor modifier kept")
	var pb := StrIntPath.of(main.get(&"shadow_hero"))
	_check(pb.is_active() or pb.cooldown_left() > 0.0, "bot never used its ability")
	print("expired OK; bot used its ability: %s" % str(pb.is_active() or pb.cooldown_left() > 0.0))


func _after_cooldown() -> void:
	for w in [w_str, w_int]:
		var p := StrIntPath.of(w)
		_check(p.cooldown_left() == 0.0 and p.can_activate() == "", "%s not ready after cooldown" % p.path)
		_check(p.activate() == "" and p.vfx.call(&"is_showing"), "%s reactivate" % p.path)


func _count_lights(n: Node) -> int:
	var c := 1 if n is Light3D else 0
	for ch in n.get_children():
		c += _count_lights(ch)
	return c
