class_name StrIntPath
extends Node
## The STR / INT path of a wizard (docs/design/level-boons.md "STR / INT path"; JS 2026-09-27).
## Child "StrIntPath" of every Wizard (created by Wizard._ready when this script exists).
## - One mandatory choice at the START of a skirmish, locked for the match: STR (attack + HP, ability Vigor =
##   HP regeneration) or INT (spell power + mana, ability Snow Shield). Same rule for AI wizards.
## - Skirmish player wizard (with a display): a 2-button panel (scripts/ui/str_int_panel.gd) opens at 0:00 and the
##   game waits (paused) until a path is taken. Bots, headless runs and tests: auto-pick (AIStrInt.choose, by kingdom).
## - Missions (scene script named Mission*, or no Skirmish host, e.g. scenes/main.tscn): no path, nothing happens
##   (choose() still works for tests / a future mission setting).
## - Everything is behind ENABLED: false = the node does nothing (no stats, no panel, no ability).
## Modifiers: `path:str` / `path:int` (permanent), `path:vigor` (while Vigor is active).

signal path_chosen(path: StringName)
signal ability_started(path: StringName)
signal ability_ended(path: StringName)

## Master switch. false = the whole feature is off and the game plays exactly as before.
const ENABLED := true
## Ability timing. JS's words "2 min ability 1 min cooldown" are unconfirmed; defensible default until the
## playtest: 20 s active, 60 s cooldown (the cooldown starts when the effect ends). JS sets these two.
const ABILITY_DURATION := 20.0
const ABILITY_COOLDOWN := 60.0

const PATH_STR := &"str"
const PATH_INT := &"int"
const STR_STATS := {"attack_damage_pct": 0.15, "max_hp_pct": 0.20}
const INT_STATS := {"spell_power": 15.0, "max_mana_pct": 0.25}
## Vigor (STR): + this fraction of max HP per second as hp_regen while active (20 s = 40 % max HP).
const VIGOR_REGEN_PCT := 0.02
## Snow Shield (INT): shield = this fraction of max HP + SNOW_SHIELD_PER_SP x spell_power, for the duration.
## It ends early when broken (the dome disappears: the enemy can see it is down).
const SNOW_SHIELD_HP_PCT := 0.25
const SNOW_SHIELD_PER_SP := 2.0
const NAMES := {&"str": "Strength", &"int": "Intellect"}
const ABILITY_NAMES := {&"str": "Vigor", &"int": "Snow Shield"}
const AI_SCRIPT := "res://scripts/ai/ai_str_int.gd"
const VFX_SCRIPT := "res://art/vfx/str_int/str_int_vfx.gd"
const PANEL_SCRIPT := "res://scripts/ui/str_int_panel.gd"
const BOT_THINK := 0.5

## Tests: true = never open the panel (auto-pick), even with a display.
static var force_auto := false

var wizard: Node = null
var path: StringName = &""
## Bots (and every wizard but the human's) use the ability on their own.
var auto_use := false
## A bot drives this wizard (its Commander owns the wizard, e.g. a Bot Lab bot on the human's side): the human's
## wizard then uses the ability by itself too (seat-bias fix 2026-10-05: the PLAYER team's bot never used Vigor /
## Snow Shield, so every bot-vs-bot match and map gate G5 handicapped team 0).
var bot_driven := false
## false in missions / without a skirmish host: no auto-pick, no panel.
var in_match := false
var vfx: Node3D = null

var _active_left := 0.0
var _cooldown_left := 0.0
var _think_left := 0.0
var _panel: Node = null


static func of(w: Node) -> StrIntPath:
	if w == null or not is_instance_valid(w):
		return null
	return w.get_node_or_null(^"StrIntPath") as StrIntPath


## The Commander driving `wizard` calls it: the ability is used by the bot rule, whoever's wizard it is.
func set_bot_driven() -> void:
	bot_driven = true
	auto_use = true


func setup(w: Node) -> void:
	wizard = w
	name = "StrIntPath"


func _ready() -> void:
	if wizard == null:
		wizard = get_parent()
	set_physics_process(ENABLED)
	if not ENABLED:
		return
	if wizard and wizard.has_signal(&"died"):
		wizard.connect(&"died", _on_wizard_died)
	_decide_start.call_deferred()


## 0:00 of a skirmish: the human's wizard gets the panel, everyone else auto-picks. Missions: nothing.
func _decide_start() -> void:
	if not is_inside_tree() or path != &"":
		return
	var host := _skirmish_host()
	if host == null:
		return
	in_match = true
	var human: bool = host.get(&"hero") == wizard
	auto_use = not human or bot_driven
	if human and not force_auto and DisplayServer.get_name() != "headless" and _open_panel(host):
		return
	choose(default_pick())


## The bot / default path for this wizard (AIStrInt rule by kingdom; STR without the AI script).
func default_pick() -> StringName:
	var k: Variant = wizard.get(&"kingdom") if wizard else null
	if ResourceLoader.exists(AI_SCRIPT):
		var s := load(AI_SCRIPT) as Script
		if s and s.has_method(&"choose"):
			return StringName(s.call(&"choose", StringName(str(k)) if k != null else &""))
	return PATH_STR


## Takes the path. "" = ok, else "Disabled", "Unknown path", "Already chosen" (locked for the match).
func choose(p: StringName) -> String:
	if not ENABLED:
		return "Disabled"
	if p != PATH_STR and p != PATH_INT:
		return "Unknown path"
	if path != &"":
		return "Already chosen"
	path = p
	var mana_before := float(wizard.get(&"mana"))
	var max_mana_before := float(wizard.get(&"max_mana"))
	wizard.call(&"add_modifier", StringName("path:" + String(p)), STR_STATS if p == PATH_STR else INT_STATS)
	var gain := maxf(0.0, float(wizard.get(&"max_mana")) - max_mana_before)
	wizard.set(&"mana", minf(float(wizard.get(&"max_mana")), mana_before + gain))
	_build_vfx()
	if _panel and is_instance_valid(_panel) and _panel.has_method(&"on_path_chosen"):
		_panel.call(&"on_path_chosen")
	path_chosen.emit(p)
	return ""


func is_locked() -> bool:
	return path != &""


func path_name() -> String:
	return NAMES.get(path, "")


func ability_name() -> String:
	return ABILITY_NAMES.get(path, "")


func is_active() -> bool:
	return _active_left > 0.0


func time_left() -> float:
	return _active_left


func cooldown_left() -> float:
	return _cooldown_left


## "" = ok, else "No path", "Dead", "Active", "On cooldown".
func can_activate() -> String:
	if path == &"":
		return "No path"
	if wizard == null or not wizard.call(&"is_alive"):
		return "Dead"
	if _active_left > 0.0:
		return "Active"
	if _cooldown_left > 0.0:
		return "On cooldown"
	return ""


## Starts Vigor (STR) or Snow Shield (INT). Same reasons as can_activate.
func activate() -> String:
	var reason := can_activate()
	if reason != "":
		return reason
	_active_left = ABILITY_DURATION
	var max_hp := float(wizard.get(&"max_hp"))
	if path == PATH_STR:
		wizard.call(&"add_modifier", &"path:vigor", {"hp_regen": max_hp * VIGOR_REGEN_PCT})
	else:
		var sp := float(wizard.call(&"get_stat", &"spell_power"))
		wizard.call(&"add_shield", max_hp * SNOW_SHIELD_HP_PCT + SNOW_SHIELD_PER_SP * maxf(0.0, sp), ABILITY_DURATION)
	if vfx:
		vfx.call(&"set_active", true)
	ability_started.emit(path)
	return ""


## Ends the active effect now (expiry, broken shield, death); the cooldown starts.
func end_ability() -> void:
	if _active_left <= 0.0:
		return
	_active_left = 0.0
	_cooldown_left = ABILITY_COOLDOWN
	if wizard and wizard.has_method(&"remove_modifier"):
		wizard.call(&"remove_modifier", &"path:vigor")
	if vfx:
		vfx.call(&"set_active", false)
	ability_ended.emit(path)


func _physics_process(delta: float) -> void:
	if path == &"":
		return
	if _active_left > 0.0:
		_active_left -= delta
		var broken := path == PATH_INT and float(wizard.get(&"shield")) <= 0.0
		if _active_left <= 0.0 or broken:
			_active_left = 0.001
			end_ability()
	elif _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if auto_use:
		_think_left -= delta
		if _think_left <= 0.0:
			_think_left = BOT_THINK
			_bot_think()


## Bot use: STR when hurt in a fight (HP < 60 %, hit in the last 3 s); INT when under attack (hit in the
## last 1.5 s and HP < 85 %).
func _bot_think() -> void:
	if can_activate() != "":
		return
	var frac := float(wizard.get(&"hp")) / maxf(1.0, float(wizard.get(&"max_hp")))
	var since := 999.0
	if wizard.has_method(&"seconds_since_damage"):
		since = float(wizard.call(&"seconds_since_damage"))
	if (path == PATH_STR and frac < 0.6 and since < 3.0) or (path == PATH_INT and frac < 0.85 and since < 1.5):
		activate()


func _on_wizard_died(_u: Variant = null) -> void:
	end_ability()


func _build_vfx() -> void:
	if vfx != null or not ResourceLoader.exists(VFX_SCRIPT):
		return
	var s := load(VFX_SCRIPT) as Script
	if s == null or not s.can_instantiate():
		return
	vfx = s.new() as Node3D
	if vfx == null:
		return
	var h: Variant = wizard.get(&"body_height")
	vfx.call(&"setup", path, float(h) if h != null else 2.0)
	(wizard as Node).add_child(vfx)


func _skirmish_host() -> Node:
	var n := get_parent()
	while n != null:
		if n.has_method(&"wizard_of"):
			var sc := n.get_script() as Script
			var gname := String(sc.get_global_name()) if sc else ""
			if gname.begins_with("Mission"):
				return null
			return n
		n = n.get_parent()
	return null


func _open_panel(host: Node) -> bool:
	if not ResourceLoader.exists(PANEL_SCRIPT):
		return false
	var s := load(PANEL_SCRIPT) as Script
	if s == null or not s.can_instantiate():
		return false
	_panel = s.new() as Node
	if _panel == null or not _panel.has_method(&"open_for"):
		_panel = null
		return false
	host.add_child(_panel)
	_panel.call(&"open_for", self)
	return true
