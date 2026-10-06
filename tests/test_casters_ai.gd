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
## - code review 2026-10-02: H1 an idle bot soldier pointed at a player caster keeps its chase leash (the caster jumps
##   40 m away, the soldier stops within aggro x 2); M1 the hard Rimecarver spends no rune on a keep's hits and at most
##   one per 6 s on hits from an unseen enemy; M4 the next level's main.gd _ready clears a live rune, a claim and
##   AICasters.last_cast / history (unit.gd set_auto_target, caster_kit.gd reset, ai_casters.gd).
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
var _check_restart := false   # the next _level checks that the previous match's caster state is gone (review M4)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _level(&"ice", 2)
	await _ice_hard()
	await _leash()
	await _rune_spam()
	_leave_state()
	await _unload()
	_check_restart = true
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
	if _check_restart:
		# main.gd _ready (a new match / F9) cleared the old match's rune, claim and bot cast history.
		_check_restart = false
		_check(CasterKit.runes_of(-1).is_empty(), "restart: a Scrying Rune of the old match survived")
		_check(CasterKit.claims_of(ENEMY).is_empty(), "restart: an old claim survived")
		_check(AICasters.last_cast(ENEMY).is_empty() and AICasters.history(ENEMY).is_empty(),
				"restart: AICasters.last_cast kept the old match's cast %s" % str(AICasters.last_cast(ENEMY)))
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
	_check(absf(AIMemory.strength_of(kw) - 60.0) < 0.1, "strength at 50 mana %.1f (want 60 = cost 120 x 0.5)" % AIMemory.strength_of(kw))
	CasterKit.ability_of(kw).mana = 120.0
	_check(absf(AIMemory.strength_of(kw) - 120.0) < 0.1, "strength at 120 mana %.1f (want 120 = cost)" % AIMemory.strength_of(kw))
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


# ---------------------------------------------------------------- code review fixes (H1, M1, M4)

## H1: an idle bot soldier the caster rule points at a player caster keeps its chase leash: the caster jumps 40 m
## away and the soldier gives up within aggro_range x 2 of where it stood (it used to chase it across the map).
func _leash() -> void:
	print("---- leash on a caster chase (review H1)")
	var rally: Vector3 = cmd.call(&"rally_point")
	var toward := -Vector3(rally.x, 0, rally.z).normalized()
	var p := rally + toward * 22.0
	p.y = 0.0
	var s := _sturdy(_spawn("rimeshield", ENEMY, p, true))
	var k := _sturdy(_spawn("kilnwarden", PLAYER, p + toward * (s.aggro_range + 1.0), true))
	k.command_hold()
	var kab := CasterKit.ability_of(k)
	for sid in kab.spell_ids():
		kab.set_autocast(sid, false)
	await _frames(2)
	s.command_stop()   # idle, anchored at p; the caster stands beyond its own aggro range, inside the rule's reach
	var picked := false
	for i in 60:
		await _secs(0.1)
		if s.attack_target == k:
			picked = true
			break
	_check(picked, "the bot's caster rule never pointed the idle soldier at the player caster (target %s, move order %s, own %s, seen %s, aggro %.1f, d %.1f)"
			% [str(s.attack_target), s.has_move_order(), (cmd.call(&"own_soldiers") as Array).has(s),
			(cmd.call(&"seen_enemies") as Array).has(k), s.aggro_range, _flat(s.global_position, k.global_position)])
	if picked:
		_check(bool(s.get(&"_auto_target")), "the caster pick is not an auto target (no leash)")
	k.global_position = p + toward * 40.0   # the caster runs off
	var far := 0.0
	for i in 80:
		await _secs(0.1)
		far = maxf(far, _flat(s.global_position, p))
	var leash := s.aggro_range * 2.0
	_check(far <= leash + 3.0, "the soldier chased the caster %.1f m from its spot (leash %.1f)" % [far, leash])
	_check(s.attack_target != k, "the soldier still targets the caster 40 m away")
	for n in [s, k]:
		if is_instance_valid(n):
			n.queue_free()
	await _frames(3)


## M1: the hard Rimecarver's "rune_blind" rule ignores hits from buildings (towers, keeps) and spends at most one
## rune per RUNE_BLIND_EVERY s on hits from an unseen enemy unit (it cast a 25-mana rune every second under tower fire).
func _rune_spam() -> void:
	print("---- rune spam (review M1)")
	var ai: AICasters = cmd.get(&"casters_ai")
	var rally: Vector3 = cmd.call(&"rally_point")
	var casters := _enemy_casters(&"rimecarver")
	_check(not casters.is_empty(), "no Rimecarver left for the rune test")
	var member: Unit = null
	for u: Unit in cmd.call(&"own_soldiers"):
		if is_instance_valid(u) and u.is_alive() and _flat(u.global_position, rally) <= AICasters.HOME_GROUP_RADIUS - 3.0:
			member = u
			break
	if member == null:
		member = _sturdy(_spawn("rimeshield", ENEMY, rally, true))
	# It stays in the rally group: held (no chase after the attacker) and put back on its spot before each hit.
	var spot := rally + (member.global_position - rally).limit_length(4.0)
	spot.y = member.global_position.y
	var pin := func() -> void:
		member.command_hold()
		member.global_position = spot
	var keep: Node3D = main.keep
	var count := func() -> int: return int(ai.casts_by_rule.get("rune_blind", 0))
	var before: int = count.call()
	for i in 20:   # 6 s of hits from the player's keep (a building: never "from the fog")
		for c in casters:
			if is_instance_valid(c):
				CasterKit.ability_of(c).mana = 200.0
		pin.call()
		member.take_damage(0.5, keep)
		member.heal(0.5)
		await _secs(0.3)
	_check(int(count.call()) == before, "building hits spent %d runes (want 0)" % (int(count.call()) - before))
	var seen: Array[Unit] = []
	for e: Variant in cmd.call(&"seen_enemies"):
		if is_instance_valid(e) and e is Unit:
			seen.append(e)
	_check(not ai.hit_from_fog(member, seen), "a keep's hit counts as from the fog")
	# An enemy unit out of the bot's sight (at the player's keep) hits the member for 8 s: 1, at most 2 runes.
	var hidden := _spawn("flame_guard", PLAYER, keep.global_position + Vector3(0, 0, 4), true)
	hidden.command_hold()
	await _frames(2)
	_check(not (cmd.call(&"seen_enemies") as Array).has(hidden), "the hidden attacker is seen by the bot")
	before = count.call()
	for c in casters:   # within the rune's 12 m of the member (the casters' 8.2 spot may be farther after the tests)
		if is_instance_valid(c):
			c.global_position = spot + Vector3(2.0, 0, 0)
			c.command_stop()
	for i in 27:
		for c in casters:
			if is_instance_valid(c):
				CasterKit.ability_of(c).mana = 200.0
		pin.call()
		member.take_damage(0.5, hidden)
		member.heal(0.5)
		await _secs(0.3)
	var got: int = int(count.call()) - before
	var diag := []
	for c in casters:
		if is_instance_valid(c):
			diag.append("%.1f m, mana %d" % [_flat(c.global_position, member.global_position), int(CasterKit.ability_of(c).mana)])
	_check(got >= 1 and got <= 2, "hits from the fog for 8 s: %d runes (want 1-2, one per %.0f s; member %.1f m from the rally, casters %s, last %s)"
			% [got, AICasters.RUNE_BLIND_EVERY, _flat(member.global_position, rally), str(diag), str(AICasters.last_cast(ENEMY))])
	member.command_stop()
	hidden.queue_free()
	await _frames(3)


## M4: leaves a live rune, a claim and the bot's cast history for the next level's _ready to clear.
func _leave_state() -> void:
	CasterKit.register_rune(ENEMY, Vector3.ZERO, 10.0, CasterKit.now_s() + 9999.0, null, null)
	CasterKit.claim(ENEMY, &"slag_rain", Vector3.ZERO, main, CasterKit.now_s() + 9999.0)
	_check(not CasterKit.runes_of(-1).is_empty() and not CasterKit.claims_of(ENEMY).is_empty(), "staged rune / claim")
	_check(not AICasters.last_cast(ENEMY).is_empty(), "the hard Ice bot cast nothing (no history to carry over)")


# ---------------------------------------------------------------- Shadow, normal

func _shadow_normal() -> void:
	var ai: AICasters = cmd.get(&"casters_ai")
	var rally: Vector3 = cmd.call(&"rally_point")
	# Normal at tier 2 wants 1 caster (cap allowing).
	var eco := Economy.for_team(ENEMY)
	eco.add(6000)
	eco.add_pop_bonus(150)
	TierSystem.instance().set_tier(ENEMY, 2)
	var d1 := _spawn("gloom_deacon", ENEMY, rally, true)
	var d2 := _spawn("gloom_deacon", ENEMY, rally + Vector3(1.5, 0, 0), true)
	await _secs(1.5)
	_check(ai.anchor == d1 or ai.anchor == d2, "no anchor Deacon with 2 Deacons")
	# The normal bot adopted them with its reaction (0.5 s), not just the table value (review L11).
	var dab := CasterKit.ability_of(d1)
	_check(dab.bot_controlled and absf(dab.reaction - 0.5) < 0.01, "normal reaction on the adopted Deacon (%.2f)" % dab.reaction)
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
