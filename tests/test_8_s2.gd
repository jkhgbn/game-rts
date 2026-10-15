extends SceneTree
## Task 8.S2 (docs/design/kingdom-nature.md section 10): any kingdom on either side of the skirmish.
## Runs every pair of Fire / Shadow / Ice / Nature (player x bot, mirror included) in scenes/skirmish.tscn,
## one after the other, and checks for each: the right keeps, 3 workers of the right kingdom gathering,
## the right wizard on each side (main.hero = the player's wizard, groups heroes / enemy_heroes, no
## self-casting for the player's), kingdom colours on wizards / workers / keeps, the HUD set up on the
## player's wizard with the player's skin, the start fog per team, the camera near the player's keep and
## the bot (Commander) playing the enemy kingdom. A kingdom whose data is not there yet (Nature while
## 8.S1 / 8.G1 run) must fall back as a whole to the side's default (Fire / Shadow), never a mixed start.
## Each combo runs RUN_SECONDS of match time with the bot on; the two named combos run LONG_SECONDS.
## Run:  godot --headless --path . -s tests/test_8_s2.gd --fixed-fps 60 --quit-after 60000

const TASK_ID := "8.S2"
const SCENE := "res://scenes/skirmish.tscn"
const KINGDOMS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
## [player, bot] pairs that run LONG_SECONDS (the task's examples); every other pair runs RUN_SECONDS.
const LONG_COMBOS := [[&"ice", &"fire"], [&"shadow", &"shadow"]]
const RUN_SECONDS := 3.0
const LONG_SECONDS := 20.0
const BAKE_TIMEOUT := 3000
const PLAYER_START := Vector3(-36.0, 0.0, 36.0)
const SHADOW_START := Vector3(36.0, 0.0, -36.0)

var main: Node
var _combos: Array = []
var _index := -1
var _wait := 0
var _frame := 0
var _run_frames := 0
var _checked_bot := false
var _errors: Array[String] = []
var _notes: Array[String] = []
var _cleanup := 0


func _initialize() -> void:
	for p in KINGDOMS:
		for e in KINGDOMS:
			_combos.append([p, e])
	_combos.append([&"atlantis", &"atlantis"])   # unknown kingdoms: whole-side fallback to Fire / Shadow
	_next_combo()


func _process(_delta: float) -> bool:
	if _cleanup > 0:   # let the previous level free before the next one enters the tree
		_cleanup -= 1
		if _cleanup == 0:
			return _next_combo()
		return false
	if main == null:
		return _finish()
	if main.hero == null:
		_wait += 1
		if _wait > BAKE_TIMEOUT:
			_errors.append("%s: navigation never finished baking" % _label())
			return _finish()
		return false
	_frame += 1
	if _frame == 2:
		_check_start()
	if not _checked_bot and main.match_time() >= 2.0:
		_checked_bot = true
		_check_bot()
	if _frame >= _run_frames:
		_check_running()
		main.get_parent().remove_child(main)
		main.free()
		main = null
		_cleanup = 3
	return false


func _next_combo() -> bool:
	_index += 1
	if _index >= _combos.size():
		return _finish()
	var c: Array = _combos[_index]
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", c[0])
	main.set(&"enemy_kingdom", c[1])
	root.add_child(main)
	current_scene = main
	_wait = 0
	_frame = 0
	_checked_bot = false
	var secs := LONG_SECONDS if LONG_COMBOS.has(c) else RUN_SECONDS
	_run_frames = int(secs * 60.0)
	return false


func _finish() -> bool:
	for n in _notes:
		print("NOTE %s" % n)
	if _errors.is_empty():
		print("PASS %s (%d combos)" % [TASK_ID, _combos.size()])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


func _label() -> String:
	var c: Array = _combos[_index]
	return "%s vs %s" % [c[0], c[1]]


## The kingdom the side must really play: the requested one, or the side's default when it can't start yet.
func _expected(requested: StringName, fallback: StringName) -> StringName:
	if bool(main.call(&"kingdom_available", requested)):
		return requested
	if not _notes.has("%s not available yet: falls back" % requested):
		_notes.append("%s not available yet: falls back" % requested)
	return fallback


## Skirmish.KINGDOMS, read from the level's script (no class constant access from a test script).
func _kingdoms() -> Dictionary:
	return (main.get_script() as Script).get_script_constant_map()["KINGDOMS"]


func _err(msg: String) -> void:
	_errors.append("%s: %s" % [_label(), msg])


# ---------------------------------------------------------------- start state

func _check_start() -> void:
	var c: Array = _combos[_index]
	var pk := _expected(c[0], &"fire")
	var ek := _expected(c[1], &"shadow")
	var mine := {0: pk, 1: ek}   # Unit.Team.PLAYER = 0, ENEMY = 1 (checked below)
	if int(Unit.Team.PLAYER) != 0 or int(Unit.Team.ENEMY) != 1:
		_err("Unit.Team values changed")
		return
	if main.player_kingdom != pk or main.enemy_kingdom != ek:
		_err("kingdoms resolved to %s / %s, expected %s / %s" % [main.player_kingdom, main.enemy_kingdom, pk, ek])
	for team: int in [0, 1]:
		var k: StringName = mine[team]
		if main.kingdom_of(team) != k:
			_err("kingdom_of(%d) = %s" % [team, main.kingdom_of(team)])
		# Keep
		var keep: Node = main.keep if team == 0 else main.shadow_keep
		if keep == null or keep.building_type == null or keep.building_type.id != StringName("%s_keep" % k):
			_err("team %d keep is %s, not %s_keep" % [team, keep.building_type.id if keep and keep.building_type else &"none", k])
		elif int(keep.team) != team:
			_err("team %d keep has team %d" % [team, int(keep.team)])
		elif keep.team_color != keep.building_type.color:
			_err("team %d keep colour is not its kingdom's" % team)
		# Workers: 3, this kingdom's worker, gathering.
		var workers: Array = main.workers_of(team)
		if workers.size() != 3:
			_err("team %d has %d workers" % [team, workers.size()])
		for w: Unit in workers:
			if w.unit_type == null or w.unit_type.faction != k or not w.unit_type.is_worker:
				_err("team %d worker %s is not a %s worker" % [team, w.unit_type.id if w.unit_type else &"?", k])
				break
			if w.call(&"_kingdom_color") != Unit.kingdom_color_for(team, k):   # G-E: mirror = alt palette for team 1
				_err("team %d worker colour is not %s's" % [team, k])
				break
		# Wizard
		var wiz: Node = main.wizard_of(team)
		if wiz == null or not wiz is Wizard:
			_err("team %d has no wizard" % team)
			continue
		if StringName(wiz.get(&"kingdom")) != k:
			_err("team %d wizard %s is kingdom %s, not %s" % [team, wiz.unit_name, wiz.get(&"kingdom"), k])
		if int(wiz.team) != team:
			_err("team %d wizard is on team %d" % [team, int(wiz.team)])
		if wiz.call(&"_kingdom_color") != Unit.kingdom_color_for(team, k):
			_err("team %d wizard colour is not %s's" % [team, k])
		var mirror_alt: bool = team == 1 and main.player_kingdom == main.enemy_kingdom
		if wiz.call(&"_kingdom_color") != (Unit.KINGDOM_ALT_COLORS.get(k) if mirror_alt else Unit.KINGDOM_COLORS.get(k)):
			_err("team %d wizard colour: a mirror's second side should wear the %s alt palette" % [team, k])
		var in_heroes: bool = wiz.is_in_group(&"heroes")
		var in_enemy: bool = wiz.is_in_group(&"enemy_heroes")
		if team == 0 and (not in_heroes or in_enemy):
			_err("the player's wizard is not (only) in 'heroes'")
		if team == 1 and (in_heroes or not in_enemy):
			_err("the bot's wizard is not (only) in 'enemy_heroes'")
		if team == 0 and &"ai_auto_cast" in wiz and bool(wiz.get(&"ai_auto_cast")):
			_err("the player's wizard casts by himself")
		var expected_name: String = _kingdoms()[k]["hero"]
		if not String(wiz.unit_name).begins_with(expected_name):
			_err("team %d wizard is %s, not %s" % [team, wiz.unit_name, expected_name])
	# main.hero is the player's wizard; the HUD and selection follow it.
	if main.hero != main.wizard_of(0) or main.hero.team != Unit.Team.PLAYER:
		_err("main.hero is not the player's wizard")
	if main.selection.hero != main.hero:
		_err("selection.hero is not the player's wizard")
	if main.hud.get(&"_hero") != main.hero:
		_err("the HUD is not set up on the player's wizard")
	var skin := pk if UIStyle.SKINS.has(pk) else &"fire"
	if UIStyle.get_kingdom() != skin:
		_err("HUD skin is %s, not %s" % [UIStyle.get_kingdom(), skin])
	# Camera: main._ready focuses on `keep` (the player's, checked above); headless edge-scroll moves it after
	# that, so check Space instead: it centres on the player's wizard.
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	main.call(&"_unhandled_input", space)
	var cam: Vector3 = main.camera_rig.global_position
	if Vector2(cam.x - main.hero.global_position.x, cam.z - main.hero.global_position.z).length() > 0.5:
		_err("Space does not centre on the player's wizard (camera %s)" % str(cam))
	# Fog: each team sees its own start, the player has not explored the bot's.
	var fog: FogOfWar = main.fog
	if not fog.is_explored(0, PLAYER_START) or not fog.is_explored(1, SHADOW_START):
		_err("start fog not revealed for its team")
	if fog.is_explored(0, SHADOW_START):
		_err("the player starts with the bot's base explored")
	# Objective names the enemy kingdom.
	var enemy_name: String = _kingdoms()[ek]["name"]
	if not String(main.call(&"_objective_text")).contains("every %s building" % enemy_name):
		_err("objective does not name %s" % enemy_name)


## The Commander plays the ENEMY team with the enemy kingdom's buildings.
func _check_bot() -> void:
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot == null:
		_err("no ShadowBot")
		return
	if int(bot.get(&"team")) != 1:
		_err("the bot plays team %d" % int(bot.get(&"team")))
	var f: Variant = bot.get(&"_faction")
	if f != null and StringName(str(f)) != main.enemy_kingdom:
		_err("the bot plays %s, not %s" % [f, main.enemy_kingdom])


## After the run: nobody lost at the start, both wizards still exist, workers still there.
func _check_running() -> void:
	if main.game_over:
		_err("the match ended after %.1f s (winner %d)" % [main.match_time(), int(main.winner_team)])
	for team: int in [0, 1]:
		if main.keep_of(team) == null:
			_err("team %d lost its keep" % team)
		if main.workers_of(team).size() < 3:
			_err("team %d has %d workers after %.1f s" % [team, main.workers_of(team).size(), main.match_time()])
