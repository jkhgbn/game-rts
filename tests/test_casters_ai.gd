extends SceneTree
## Caster units, the bot (docs/design/caster-units.md 8, task CU.A1). Two skirmishes (the bot plays Ice on hard, then
## Shadow on normal), the bot's commander driving everything; the test stages the situations:
## - 8.1 training: the hard Ice bot at the Stronghold with an army of 12 pop queues 2 Rimecarvers at its keep (cap 10 %
##   of the soldier pop rounded up); easy never trains one; normal wants 1 at tier 2;
## - 8.2 positioning: the casters stand within ~4-8 m behind the army's centre (never in front of it toward the enemy);
##   flee: a melee enemy at 2 m -> the caster steps away; strength: cost x 0.5 / x 1.0 with mana;
##   target preference: bot soldiers switch to a player caster in reach; counter-mix +0.05 for fast units once 2 player
##   casters were seen;
## - 8.3 casting: Rimecarver dive guard (a Bulwark in front of a Shardcaster a Flame Guard dives, rule "dive_guard"),
##   Gloom Deacon retreat Passage (a retreating group 30 m away is recalled, rule "retreat_passage"), the anchor Deacon
##   stays home with 2 Deacons; every bot caster autocasts (bot_controlled).
## Run:  godot --headless --path . -s tests/test_casters_ai.gd --fixed-fps 60 --quit-after 60000

const TASK_ID := "casters_ai"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1

var main: Node
var cmd: Node
var _errors: Array[String] = []
var _cases := 0
var _k: StringName = &""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _level(&"ice", 2)
	await _ice_hard()
	await _unload()
	await _level(&"shadow", 1)
	await _shadow_normal()
	await _unload()
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _cases])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit(0 if _errors.is_empty() else 1)


func _check(ok: bool, what: String) -> void:
	_cases += 1
	if not ok:
		_errors.append("%s: %s" % [_k, what])
		print("  x %s: %s" % [_k, what])


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _secs(s: float) -> void:
	await _frames(roundi(s * 60.0))


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# ---------------------------------------------------------------- level

func _level(enemy_kingdom: StringName, difficulty: int) -> void:
	_k = enemy_kingdom
	print("---- enemy %s, difficulty %d" % [enemy_kingdom, difficulty])
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", enemy_kingdom)
	main.set(&"camps_enabled", false)
	main.set(&"beasts_enabled", false)
	cmd = null
	for n in main.get_children():
		if n.get_script() == COMMANDER and int(n.get(&"team")) == ENEMY:
			cmd = n
			n.set(&"difficulty", difficulty)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_check(false, "the skirmish never started")
			return
	var hero: Wizard = main.get(&"hero")
	var path := StrIntPath.of(hero)
	if path != null and not path.is_locked():
		path.choose(&"str")
	paused = false
	await _secs(2.0)   # the commander's first think (setup, AICasters)
	_check(cmd != null and cmd.get(&"casters_ai") != null, "the commander has no AICasters")
	var ai: Variant = cmd.get(&"ai")
	if ai:
		ai.set(&"launch_attacks", false)   # the test stages the army's moves itself
	Economy.for_team(PLAYER).add(20000)
	Economy.for_team(PLAYER).add_pop_bonus(150)


func _unload() -> void:
	if main:
		main.queue_free()
	main = null
	cmd = null
	await _frames(6)


func _spawn(id: String, team: int, pos: Vector3, harmless := false) -> Unit:
	var t := UnitType.find(id)
	var u: Unit = Worker.make_unit(t) if t.is_worker else t.create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	if harmless:
		u.add_modifier(&"test_harmless", {&"attack_damage_pct": -1.0})
	return u


## A unit that survives the test (the bot's army hits it meanwhile).
func _sturdy(u: Unit) -> Unit:
	u.add_modifier(&"test_sturdy", {&"max_hp_pct": 100.0})
	u.heal(99999.0)
	return u


func _enemy_casters(id: StringName) -> Array[Unit]:
	return CasterKit.casters_of(ENEMY, id)


# ---------------------------------------------------------------- Ice, hard

func _ice_hard() -> void:
	var ai: AICasters = cmd.get(&"casters_ai")
	var keep: Keep = main.keep_of(ENEMY)
	var rally: Vector3 = cmd.call(&"rally_point")
	var eco := Economy.for_team(ENEMY)
	eco.add(6000)
	eco.add_pop_bonus(150)
	var ts := TierSystem.instance()
	ts.set_tier(ENEMY, 1)
	# Workers at their target (the keep's queue holds no worker then) and an army of 12 pop at the rally.
	var wt: UnitType = keep.building_type.trains[0]
	var extra: Array[Unit] = []
	for i in 12:
		extra.append(_spawn(String(wt.id), ENEMY, keep.global_position + Vector3(cos(i), 0, sin(i)) * 6.0))
	var army: Array[Unit] = []
	for i in 12:
		army.append(_spawn("rimeshield", ENEMY, rally + Vector3(cos(i * 0.5), 0, sin(i * 0.5)) * (1.0 + i * 0.3)))
	await _secs(4.0)
	_check(_enemy_casters(&"rimecarver").is_empty() and T3Kit.count_alive(ENEMY, &"rimecarver", true) == 0,
			"a caster before the Stronghold")
	# Stronghold: the hard bot queues 2 (cap = ceil(12 x 0.10) = 2).
	ts.set_tier(ENEMY, 2)
	var t := 0.0
	while t < 100.0 and _enemy_casters(&"rimecarver").size() < 2:
		await _secs(1.0)
		t += 1.0
	_check(_enemy_casters(&"rimecarver").size() == 2, "hard bot: 2 Rimecarvers by %.0f s (%d, %d queued)" % [t,
			_enemy_casters(&"rimecarver").size(), T3Kit.count_alive(ENEMY, &"rimecarver", true)])
	_check(T3Kit.count_alive(ENEMY, &"rimecarver", true) == 2, "hard bot: no third caster at tier 2 (%d)"
			% T3Kit.count_alive(ENEMY, &"rimecarver", true))
	_check(ai.trained >= 2, "AICasters.trained %d" % ai.trained)
	await _secs(2.0)   # the commander's next scans adopt them
	var casters := _enemy_casters(&"rimecarver")
	for c in casters:
		var ab := CasterKit.ability_of(c)
		_check(ab.bot_controlled and ab.autocast(&"rime_bulwark") and ab.autocast(&"scrying_rune"),
				"bot caster not bot_controlled / all autocast on")
		_check(absf(ab.reaction - 0.25) < 0.01 and ab.bot_hard, "hard reaction 0.25 (%.2f)" % ab.reaction)
	# 8.2 positioning: 4 m behind the army at the rally (never in front of it toward the map centre).
	await _secs(8.0)
	# The group they follow: the bot's soldiers at the rally (the commander may send some away to scout / capture).
	var centre := Vector3.ZERO
	var home := 0
	for u: Unit in cmd.call(&"own_soldiers"):
		if _flat(u.global_position, rally) <= AICasters.HOME_GROUP_RADIUS:
			centre += u.global_position
			home += 1
	centre = centre / float(maxi(home, 1)) if home > 0 else rally
	for c in casters:
		var d := _flat(c.global_position, centre)
		_check(d <= 8.5, "caster %.1f m from the army centre (want ~4)" % d)
		var toward_mid := -Vector3(centre.x, 0, centre.z).normalized()
		_check((c.global_position - centre).dot(toward_mid) < 1.0, "caster stands in front of the army")
	# Strength (8.2): cost x 0.5, x 1.0 with mana >= twice the cheapest spell.
	var kw := _spawn("kilnwarden", ENEMY, rally + Vector3(0, 0, -30), true)
	await _frames(3)
	CasterKit.ability_of(kw).mana = 50.0
	_check(absf(AIMemory.strength_of(kw) - 75.0) < 0.1, "strength at 50 mana %.1f (want 75)" % AIMemory.strength_of(kw))
	CasterKit.ability_of(kw).mana = 120.0
	_check(absf(AIMemory.strength_of(kw) - 150.0) < 0.1, "strength at 120 mana %.1f (want 150)" % AIMemory.strength_of(kw))
	kw.queue_free()
	# 8.3 a) dive guard: a player Flame Guard dives an own Shardcaster 7 m away -> a Bulwark in front of it.
	var rc := casters[0]
	var victim := _spawn("shardcaster", ENEMY, rc.global_position + Vector3(2, 0, 0), true)
	victim.command_hold()
	await _secs(0.5)
	var away := (victim.global_position - rally)
	away.y = 0.0
	away = away.normalized() if away.length() > 0.5 else Vector3(1, 0, 0)
	var diver := _spawn("flame_guard", PLAYER, victim.global_position + away * 7.5, true)
	diver.command_attack(victim)
	for c in casters:
		CasterKit.ability_of(c).mana = 200.0
	var got := false
	t = 0.0
	while t < 4.0 and not got:
		await _frames(6)
		t += 0.1
		got = String(AICasters.last_cast(ENEMY).get("rule", "")) == "dive_guard"
	_check(got, "no dive-guard Bulwark in 4 s (last %s)" % str(AICasters.last_cast(ENEMY)))
	var walls := CasterKit.bulwarks_of(ENEMY)
	_check(not walls.is_empty(), "no enemy Bulwark standing")
	if not walls.is_empty():
		var w: RimeBulwark = walls[walls.size() - 1]
		var d := _flat(w.global_position, victim.global_position)
		_check(d >= 1.5 and d <= 4.0, "the Bulwark is %.1f m from the victim (want ~2.5)" % d)
		var dir := (diver.global_position - victim.global_position)
		dir.y = 0.0
		_check(absf(w.global_transform.basis.x.normalized().dot(dir.normalized())) < 0.35,
				"the Bulwark does not lie across the diver's line")
	# Flee: a melee enemy at 2 m -> the caster steps away.
	var rc2 := casters[1]
	var p0 := rc2.global_position
	var bully := _sturdy(_spawn("flame_guard", PLAYER, p0 + Vector3(1.8, 0, 0), true))
	bully.command_hold()
	var fled := 0.0
	for i in 25:
		await _secs(0.1)
		fled = maxf(fled, _flat(rc2.global_position, bully.global_position))
	_check(fled >= 4.0, "the caster did not flee a melee unit (%.1f m)" % fled)
	# Target preference: bot soldiers fighting near a player caster switch to it.
	var fighters := army.slice(0, 4)
	var spot := rally + Vector3(0, 0, -12)
	for i in fighters.size():
		fighters[i].global_position = spot + Vector3(float(i) * 1.2, 0, 0)
	var bait := _sturdy(_spawn("flame_guard", PLAYER, spot + Vector3(1.8, 0, 3), true))
	bait.command_hold()
	var player_kw := _sturdy(_spawn("kilnwarden", PLAYER, spot + Vector3(0, 0, 6), true))
	var player_kw2 := _sturdy(_spawn("kilnwarden", PLAYER, spot + Vector3(3, 0, 6), true))
	for c in [player_kw, player_kw2]:
		(c as Unit).command_hold()
	await _frames(2)
	for f in fighters:
		f.command_stop()   # idle: their auto-aggro sees the bait (3 m) and the casters (6 m)
	var switched := 0
	for i in 15:   # the commander may call them back to the rally afterwards: the pick itself is checked
		await _secs(0.1)
		var n := 0
		for f in fighters:
			if f.attack_target == player_kw or f.attack_target == player_kw2:
				n += 1
		switched = maxi(switched, n)
	_check(switched >= 2, "bot soldiers did not switch to the player's casters (%d of 4)" % switched)
	# Counter-mix: 2 player casters seen -> fast units +0.05.
	_check(absf(AICasters.mix_bonus(ENEMY, UnitType.find("rimehorn_rider")) - 0.05) < 0.001,
			"counter-mix for a fast unit %.2f" % AICasters.mix_bonus(ENEMY, UnitType.find("rimehorn_rider")))
	_check(AICasters.mix_bonus(ENEMY, UnitType.find("rimeshield")) == 0.0, "counter-mix for a slow unit")
	# Easy: never trains a caster.
	cmd.set(&"difficulty", 0)
	ai.difficulty = 0
	_check(not ai.try_train(false) and not ai.try_train(true), "easy bot trained a caster")
	ai.difficulty = 2
	cmd.set(&"difficulty", 2)
	for n in [victim, diver, bully, bait, player_kw, player_kw2]:
		if is_instance_valid(n):
			n.queue_free()
	await _frames(3)


# ---------------------------------------------------------------- Shadow, normal

func _shadow_normal() -> void:
	var ai: AICasters = cmd.get(&"casters_ai")
	var rally: Vector3 = cmd.call(&"rally_point")
	_check(absf(float(AICasters.REACTION[1]) - 0.5) < 0.01, "normal reaction")
	# Normal at tier 2 wants 1 caster (cap allowing).
	var eco := Economy.for_team(ENEMY)
	eco.add(6000)
	eco.add_pop_bonus(150)
	TierSystem.instance().set_tier(ENEMY, 2)
	var d1 := _spawn("gloom_deacon", ENEMY, rally, true)
	var d2 := _spawn("gloom_deacon", ENEMY, rally + Vector3(1.5, 0, 0), true)
	await _secs(1.5)
	_check(ai.anchor == d1 or ai.anchor == d2, "no anchor Deacon with 2 Deacons")
	d2.queue_free()
	await _secs(1.0)
	_check(ai.anchor == null, "anchor kept with one Deacon")
	# A retreating group 30 m away from the Deacon (at the rally): retreat Passage.
	var toward := -Vector3(rally.x, 0, rally.z).normalized()
	var far := rally + toward * 30.0
	var group: Array = []
	for i in 6:
		group.append(_spawn("shade", ENEMY, far + Vector3(cos(i), 0, sin(i)) * 1.5, true))
	for u: Unit in group:
		u.set_physics_process(false)   # they stand still (the commander orders them home)
	CasterKit.ability_of(d1).mana = 200.0
	d1.global_position = rally
	d1.command_stop()
	cmd.set(&"_group", group)
	cmd.set(&"stage", Commander.Stage.RETREAT)
	var got := false
	var t := 0.0
	while t < 5.0 and not got:
		await _frames(6)
		t += 0.1
		got = String(AICasters.last_cast(ENEMY).get("rule", "")) == "retreat_passage"
	_check(got, "no retreat Passage in 5 s (last %s)" % str(AICasters.last_cast(ENEMY)))
	for u: Unit in group:
		u.set_physics_process(true)
	await _frames(2)
	var home := 0
	for u: Unit in group:
		if _flat(u.global_position, d1.global_position) <= 6.0:
			home += 1
	_check(home >= 4, "Passage carried %d of 6 home" % home)
	_check(CasterKit.ability_of(d1).cooldown_left(&"umbral_passage") > 30.0, "Passage cooldown after the bot's cast")
	cmd.set(&"stage", Commander.Stage.NONE)
	cmd.set(&"_group", [])
	for n in group:
		if is_instance_valid(n):
			n.queue_free()
	d1.queue_free()
	await _frames(3)
