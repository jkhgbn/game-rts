extends SceneTree
## Caster units (docs/design/caster-units.md, task CU.C1 / C2 "done when" 9.3): the 4 casters' data and keep slot B
## (Requires Stronghold at tier 1), mana 50 -> 200 at 0.8 / s, every spell's numbers (Slag Rain armour 20 -> 0 floor,
## x1.10, 10 s / heroes 5 s; Mana Scald burns min(60, mana) and deals it, `scalded` 6 s; Rime Bulwark blocks for 8 s, a
## pop-3 unit shatters it in ~1 s, max 4; Scrying Rune reveals a veiled Hush and a disguised Saboteur; Snagroot drags a
## Shade 7 m and a wizard 4 m, roots 1 s, never a titan / pop-4; Pollen Haze stops an Ember Archer shooting at 9 m, not
## at 2 m; Blood Tithe heals 10 / s and drains 5 / s at 2.5 mana / s, max 2 tethers; Umbral Passage carries <= 10 pop in
## 2.5 s and cancels on a move), the passives (Stoke, Stillness, Seedcloak, Vigil), autocast defaults and a real
## autocast, smart-cast (most mana in range, else the nearest walks in), levels (3.4) and spell XP.
## Run:  godot --headless --path . -s tests/test_casters.gd --fixed-fps 60 --quit-after 20000

const TASK_ID := "casters"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const TIMEOUT_FRAMES := 18000

var main: Node
var frame := 0
var _wait := 0
var _started := false
var _done := false
var _errors: Array[String] = []
var _spot := Vector3.ZERO
var _dir := Vector3.ZERO
var _side := Vector3.ZERO
var _cases := 0


func _initialize() -> void:
	main = load(SCENE).instantiate()
	main.camps_enabled = false
	main.beasts_enabled = false
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 5 and not _started:
		_started = true
		_run()
	if _done:
		if _errors.is_empty():
			print("PASS %s (%d checks)" % [TASK_ID, _cases])
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out; %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	_cases += 1
	if not ok:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _secs(s: float) -> void:
	await _frames(roundi(s * 60.0))


func _near(a: float, b: float, eps: float = 0.6) -> bool:
	return absf(a - b) <= eps


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _run() -> void:
	for n in main.get_children():
		if n.get_script() == COMMANDER:
			n.set(&"enabled", false)
	var keep: Node3D = main.keep
	_dir = -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	_side = _dir.cross(Vector3.UP)
	_spot = keep.global_position + _dir * 24.0
	main.economy.add(30000)
	main.economy.add_pop_bonus(150)
	var hero: Unit = main.hero
	hero.global_position = keep.global_position - _dir * 4.0   # out of the way
	var enemy_hero: Unit = main.wizard_of(ENEMY)
	if enemy_hero:
		enemy_hero.set_physics_process(false)
	print("---- data / keep")
	_check_data()
	await _check_keep()
	print("---- mana")
	await _check_mana()
	print("---- Kilnwarden")
	await _check_slag()
	await _check_scald()
	await _check_stoke()
	print("---- Rimecarver")
	await _check_bulwark()
	await _check_rune()
	await _check_stillness()
	print("---- Bramblesage")
	await _check_snagroot()
	await _check_haze()
	await _check_seedcloak()
	print("---- Gloom Deacon")
	await _check_tithe()
	await _check_passage()
	await _check_vigil()
	print("---- autocast / smart-cast / levels")
	await _check_autocast()
	await _check_smart_cast()
	await _check_levels()
	print("---- code review fixes")
	await _check_double_cast()
	await _check_walk_while_recharging()
	_check_registries()
	_done = true


# ---------------------------------------------------------------- spawning

func _spawn(id: String, team: int, pos: Vector3, harmless := false) -> Unit:
	var u := UnitType.find(id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	if harmless:
		u.add_modifier(&"test_harmless", {&"attack_damage_pct": -1.0})
	return u


func _dummy(pos: Vector3, hp: float = 5000.0, team: int = ENEMY) -> Unit:
	var u := Unit.new()
	u.team = team as Unit.Team
	u.max_hp = hp
	u.aggro_range = 0.0
	u.attack_damage = 0.0
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	u.hide_from_auto_target(9999.0)
	return u


func _caster(id: String, pos: Vector3, team: int = PLAYER, mana := 200.0) -> Unit:
	var u := _spawn(id, team, pos)
	u.add_modifier(&"test_harmless", {&"attack_damage_pct": -1.0})
	var ab := CasterKit.ability_of(u)
	if ab:
		for s in ab.spell_ids():
			ab.set_autocast(s, false)   # the test casts by hand
	await _frames(2)
	if ab:
		ab.stop_channel()
		ab.mana = mana
	return u


func _cleanup(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	await _frames(3)


## Casts and waits `after` seconds; returns the refusal ("" = cast).
func _cast(u: Unit, sid: StringName, target: Variant, after: float = 0.0) -> String:
	var ab := CasterKit.ability_of(u)
	var r := ab.cast(sid, target) if ab else "no ability"
	if after > 0.0:
		await _secs(after)
	return r


# ---------------------------------------------------------------- data / keep slot B

func _check_data() -> void:
	_check(CasterKit.ENABLED and CasterKit.enabled_here(), "casters not enabled in the skirmish")
	var hp := {&"kilnwarden": 100.0, &"rimecarver": 90.0, &"bramblesage": 85.0, &"gloom_deacon": 100.0}
	var speed := {&"kilnwarden": 4.6, &"rimecarver": 4.2, &"bramblesage": 4.8, &"gloom_deacon": 4.6}
	for cid: StringName in CasterKit.IDS:
		var t := UnitType.find(String(cid))
		_check(t != null, "%s.tres missing" % cid)
		if t == null:
			continue
		_check(t.requires_tier == 2 and t.cost == 150 and t.pop == 2 and _near(t.train_time, 30.0, 0.01) \
				and t.card_key == "B" and t.kill_xp == 75, "%s tier / cost / pop / time / key / xp" % cid)
		_check(_near(t.max_hp, hp[cid], 0.01) and _near(t.move_speed, speed[cid], 0.01) \
				and _near(t.attack_damage, 5.0, 0.01) and _near(t.attack_range, 7.0, 0.01) \
				and _near(t.attack_cooldown, 1.6, 0.01), "%s stats" % cid)
		_check(t.model_scene != null and t.faction == CasterKit.CASTERS[cid]["faction"], "%s model / faction" % cid)
		_check(CasterKit.spells_of(cid).size() == 2 and CasterKit.passive_of(cid) != &"", "%s spells" % cid)
	_check(_near(UnitType.find("rimecarver").armor, 5.0, 0.01), "Rimecarver armour 5")
	_check(_near(UnitType.find("bramblesage").idle_regen_pct, 1.0, 0.01), "Bramblesage idle regen 1 %")


func _check_keep() -> void:
	var keep: Keep = main.keep
	var ts := TierSystem.instance()
	_check(ts != null, "no TierSystem")
	if ts == null:
		return
	ts.set_tier(PLAYER, 1)
	var k: StringName = main.kingdom_of(PLAYER)
	var caster := UnitType.find(String(CasterKit.caster_for(k)))
	var types := keep.trainable_types()
	_check(types.has(caster), "keep does not list the %s caster" % k)
	main.selection.select_building(keep)
	var slots: Array = main.selection.train_slots()
	_check(slots.find(caster) == 4, "caster not on keep slot 5 (B): %s" % str(slots.map(func(t: Variant) -> String:
			return str((t as UnitType).id) if t else "-")))
	_check(keep.can_queue(caster) == TierSystem.MSG_T2, "tier 1 caster refusal '%s'" % keep.can_queue(caster))
	ts.set_tier(PLAYER, 2)
	_check(keep.can_queue(caster) == "", "tier 2 caster refused: %s" % keep.can_queue(caster))
	caster.train_time = 0.2
	var n0 := CasterKit.casters_of(PLAYER).size()
	_check(keep.queue_unit(caster) == "", "queue caster")
	await _frames(30)
	caster.train_time = 30.0
	var got := CasterKit.casters_of(PLAYER)
	_check(got.size() == n0 + 1, "the keep did not train the caster (%d -> %d)" % [n0, got.size()])
	for u in got:
		_check(CasterKit.ability_of(u) != null and _near(CasterKit.ability_of(u).mana, 50.0, 1.0),
				"trained caster starts with 50 mana (%s)" % (CasterKit.ability_of(u).mana if CasterKit.ability_of(u) else -1.0))
	# Citadel: the caster keeps B.
	ts.set_tier(PLAYER, 3)
	keep.set_tier_now(3)
	main.selection.select_building(keep)
	slots = main.selection.train_slots()
	_check(slots.find(caster) == 4, "caster moved off B at the Citadel")
	main.selection.select_units([])
	await _cleanup(got)


# ---------------------------------------------------------------- mana

func _check_mana() -> void:
	var u := await _caster("kilnwarden", _spot, PLAYER, 50.0)
	var ab := CasterKit.ability_of(u)
	_check(ab != null and _near(ab.max_mana(), 200.0, 0.01) and _near(ab.mana_regen(), 0.8, 0.001), "mana 200 / 0.8")
	ab.mana = 0.0
	await _secs(5.0)
	_check(_near(ab.mana, 4.0, 0.25), "regen 5 s -> %.2f (want 4)" % ab.mana)
	ab.mana = 199.5
	await _secs(2.0)
	_check(_near(ab.mana, 200.0, 0.01), "mana capped at 200 (%.2f)" % ab.mana)
	ab.mana = 10.0
	var foe := _dummy(_spot + _dir * 5.0)
	await _frames(20)
	_check(ab.cast(&"slag_rain", foe.global_position) == CasterKit.REASON_MANA, "Not enough mana refusal")
	ab.mana = 200.0
	_check(ab.cast(&"slag_rain", _spot + _dir * 25.0) != "", "a far point refused")
	_check(ab.can_cast(&"slag_rain", _spot + _dir * 25.0) in [CasterKit.REASON_RANGE, CasterKit.REASON_INVALID],
			"far point: %s" % ab.can_cast(&"slag_rain", _spot + _dir * 25.0))
	_check(ab.cast(&"mana_scald", null) == CasterKit.REASON_NO_TARGET, "No target refusal")
	_check(ab.cast(&"mana_scald", foe) == CasterKit.REASON_INVALID, "Scald on a unit without mana")
	u.apply_status(&"dazed", 1.0)
	_check(ab.cast(&"slag_rain", foe.global_position) == CasterKit.REASON_CANT, "dazed: Can't cast now")
	await _secs(1.2)
	_check(ab.cast(&"slag_rain", foe.global_position) == "", "slag after daze")
	_check(ab.cast(&"mana_scald", foe) == CasterKit.REASON_CANT or ab.cast(&"mana_scald", foe) == CasterKit.REASON_RECHARGING,
			"a second cast during the first")
	await _secs(1.5)
	await _cleanup([u, foe])


# ---------------------------------------------------------------- Kilnwarden

func _check_slag() -> void:
	var at := _spot + _side * 12.0
	var kw := await _caster("kilnwarden", at)
	var centre := at + _dir * 7.0
	var armored := _spawn("rimeshield", ENEMY, centre, true)         # armour 15
	var heavy := _spawn("shardguard", ENEMY, centre + _side * 1.0, true)   # armour 25
	var bare := _dummy(centre - _side * 1.0)                         # armour 0
	var far := _dummy(centre + _dir * 5.0)
	var enemy_hero: Unit = main.wizard_of(ENEMY)
	var hero_pos0 := enemy_hero.global_position if enemy_hero else Vector3.ZERO
	if enemy_hero:
		enemy_hero.global_position = centre + _side * -2.0 + _dir * 0.5
	await _frames(30)
	var hp_bare := bare.hp
	var speed0 := armored.move_speed
	var xp0 := kw.xp
	_check(await _cast(kw, &"slag_rain", centre, 1.2) == "", "Slag Rain refused: %s" % CasterKit.ability_of(kw).can_cast(&"slag_rain", centre))
	_check(_near(hp_bare - bare.hp, 12.0, 0.01), "slag 12 on armour 0 (%.2f)" % (hp_bare - bare.hp))
	_check(armored.has_status(&"slagged") and heavy.has_status(&"slagged") and not far.has_status(&"slagged"),
			"slagged in 3 m only")
	_check(_near(armored.get_stat(&"armor"), 0.0, 0.01), "armour 15 -> 0 (floor), got %.1f" % armored.get_stat(&"armor"))
	_check(_near(heavy.get_stat(&"armor"), 5.0, 0.01), "armour 25 -> 5, got %.1f" % heavy.get_stat(&"armor"))
	_check(_near(speed0 - armored.move_speed, 0.6, 0.01), "move -0.6 (%.2f -> %.2f)" % [speed0, armored.move_speed])
	_check(_near(armored.status_time_left(&"slagged"), 10.0 - 0.2, 0.3), "slag 10 s (%.2f left)" % armored.status_time_left(&"slagged"))
	_check(enemy_hero != null, "no enemy wizard for the hero slag check")
	if enemy_hero:
		# Same timing as the 10 s check above: landed 0.2 s ago (review L11: "<= 5" also passed at 0.1 s).
		_check(enemy_hero.has_status(&"slagged") and _near(enemy_hero.status_time_left(&"slagged"), 5.0 - 0.2, 0.3),
				"the enemy wizard slagged 5 s (%.2f)" % enemy_hero.status_time_left(&"slagged"))
	var h0 := bare.hp
	bare.take_damage(10.0, null)
	_check(_near(h0 - bare.hp, 11.0, 0.01), "damage taken x1.10 (%.2f)" % (h0 - bare.hp))
	_check(kw.xp - xp0 >= 9, "spell XP 3 per unit slagged (%d)" % (kw.xp - xp0))
	await _secs(10.0)
	_check(not armored.has_status(&"slagged") and _near(armored.get_stat(&"armor"), 15.0, 0.01), "slag ends after 10 s")
	if enemy_hero:
		enemy_hero.global_position = hero_pos0
	await _cleanup([kw, armored, heavy, bare, far])


func _check_scald() -> void:
	var at := _spot + _side * 12.0
	var kw := await _caster("kilnwarden", at)
	var victim := await _caster("gloom_deacon", at + _dir * 6.0, ENEMY, 100.0)
	var vab := CasterKit.ability_of(victim)
	await _frames(30)
	var hp0 := victim.hp
	_check(await _cast(kw, &"mana_scald", victim, 0.8) == "", "Mana Scald refused: %s" % CasterKit.ability_of(kw).can_cast(&"mana_scald", victim))
	_check(_near(vab.mana, 41.0, 1.5), "Scald burns 60 of 100 (%.1f left; + regen)" % vab.mana)
	_check(_near(hp0 - victim.hp, 60.0, 0.5), "Scald deals the 60 burnt (%.1f)" % (hp0 - victim.hp))
	_check(victim.has_status(&"scalded") and _near(victim.status_time_left(&"scalded"), 6.0 - 0.4, 0.4), "scalded 6 s")
	await _secs(1.2)
	_check(CasterKit.ability_of(kw).can_cast(&"mana_scald", victim) == CasterKit.REASON_INVALID, "no second Scald while scalded")
	await _secs(5.5)
	vab.mana = 25.0
	victim.heal(999.0)
	var hp1 := victim.hp
	_check(await _cast(kw, &"mana_scald", victim, 0.8) == "", "second Scald after `scalded`")
	_check(_near(vab.mana, 0.0, 0.5) and _near(hp1 - victim.hp, 25.0, 0.6), "Scald burns min(60, 25) (mana %.1f, dmg %.1f)"
			% [vab.mana, hp1 - victim.hp])
	# The enemy wizard: its own mana pool.
	var wiz: Wizard = main.wizard_of(ENEMY)
	_check(wiz != null, "no enemy wizard for the Scald-on-a-wizard check")
	if wiz:
		var pos0 := wiz.global_position
		wiz.global_position = at + _dir * 7.0
		wiz.mana = 30.0
		await _secs(1.3)
		_check(await _cast(kw, &"mana_scald", wiz, 0.8) == "", "Scald on the enemy wizard: %s" % CasterKit.ability_of(kw).can_cast(&"mana_scald", wiz))
		_check(wiz.mana <= 0.5, "wizard mana burnt (%.1f)" % wiz.mana)
		wiz.global_position = pos0
		wiz.heal(9999.0)
	await _cleanup([kw, victim])


func _check_stoke() -> void:
	var at := _spot + _side * 12.0
	var kw := await _caster("kilnwarden", at)
	var ab := CasterKit.ability_of(kw)
	var foe := _dummy(at + _dir * 6.0, 200.0)
	await _frames(30)
	await _cast(kw, &"slag_rain", foe.global_position, 1.2)
	_check(foe.has_status(&"slagged"), "stoke: foe slagged")
	ab.mana = 100.0
	foe.take_damage(9999.0, null)
	await _frames(3)
	_check(_near(ab.mana, 108.0, 0.3), "Stoke +8 mana (%.1f)" % ab.mana)
	await _cleanup([kw, foe])


# ---------------------------------------------------------------- Rimecarver

func _check_bulwark() -> void:
	var at := _spot - _side * 12.0
	var rc := await _caster("rimecarver", at)
	var wall_at := at + _dir * 6.0
	# A Shade walks from one side to the other straight through the wall's spot.
	var walker := _spawn("shade", PLAYER, wall_at - _dir * 3.0, true)
	walker.command_stop()
	await _frames(20)
	_check(await _cast(rc, &"rime_bulwark", wall_at, 0.6) == "", "Bulwark refused: %s" % CasterKit.ability_of(rc).can_cast(&"rime_bulwark", wall_at))
	var walls := CasterKit.bulwarks_of(PLAYER)
	_check(walls.size() == 1, "one Bulwark standing (%d)" % walls.size())
	var wall: RimeBulwark = walls[0] if walls.size() > 0 else null
	if wall:
		# The wall lies across the caster -> point line (x = the long axis, perpendicular to _dir).
		_check(absf(wall.global_transform.basis.x.normalized().dot(_dir)) < 0.1, "Bulwark orientation")
		_check(_near(wall.length, 4.0, 0.01) and _near(wall.thickness, 0.9, 0.01) and _near(wall.height, 2.2, 0.01),
				"Bulwark 4 x 0.9 x 2.2")
	walker.command_move(wall_at + _dir * 3.0)
	await _secs(3.0)
	var crossed := (walker.global_position - wall_at).dot(_dir) > 0.3
	_check(not crossed, "a Shade walked through the Bulwark")
	await _secs(5.5)
	_check(wall == null or not is_instance_valid(wall) or wall.ended, "the Bulwark did not melt after 8 s")
	walker.command_move(wall_at + _dir * 3.0)
	await _secs(3.0)
	_check((walker.global_position - wall_at).dot(_dir) > 0.3, "the Shade could not pass once the wall melted")
	# A pop-3 unit pressing on it shatters it in ~1 s.
	var ab := CasterKit.ability_of(rc)
	ab.mana = 200.0
	var knight := _spawn("shadow_knight", PLAYER, wall_at - _dir * 3.0, true)
	await _frames(20)
	_check(await _cast(rc, &"rime_bulwark", wall_at, 0.6) == "", "second Bulwark refused")
	walls = CasterKit.bulwarks_of(PLAYER)
	var w2: RimeBulwark = walls[0] if walls.size() > 0 else null
	knight.command_move(wall_at + _dir * 4.0)
	var t := 0.0
	while t < 4.0 and w2 != null and is_instance_valid(w2) and not w2.ended:
		await _frames(6)
		t += 0.1
	_check(w2 != null and (not is_instance_valid(w2) or (w2.ended and w2.end_reason == &"shatter")), "pop-3 unit did not shatter it")
	_check(t <= 3.0, "shatter took %.1f s" % t)
	# Max 4 per team: the oldest melts.
	ab.mana = 400.0
	for i in 5:
		ab.mana = 200.0
		var p := at + _dir * 4.0 + _side * (float(i) * 3.0 - 6.0)
		var r := await _cast(rc, &"rime_bulwark", p, 1.1)
		_check(r == "", "Bulwark %d refused: %s" % [i, r])
	_check(CasterKit.bulwarks_of(PLAYER).size() == 4, "max 4 Bulwarks (%d)" % CasterKit.bulwarks_of(PLAYER).size())
	# Refused on a building.
	var keep: Node3D = main.keep
	rc.global_position = keep.global_position + _dir * 8.0
	await _frames(5)
	_check(ab.can_cast(&"rime_bulwark", keep.global_position) == CasterKit.REASON_INVALID, "Bulwark on the keep: '%s'"
			% ab.can_cast(&"rime_bulwark", keep.global_position))
	for w in CasterKit.bulwarks_of(PLAYER):
		(w as RimeBulwark).finish(&"melt")
	await _cleanup([rc, walker, knight])


func _check_rune() -> void:
	var at := _spot - _side * 20.0
	var rc := await _caster("rimecarver", at)
	var ab := CasterKit.ability_of(rc)
	# A veiled enemy Hush.
	var hush := Helper.new()
	hush.apply_helper_type(HelperType.find(&"helper_hush"), 1)
	hush.team = Unit.Team.ENEMY
	main.add_child(hush)
	hush.global_position = at + _dir * 9.0
	hush.command_stop()
	hush.set_physics_process(false)
	var hcd: Dictionary = hush.helper_abilities.get(&"_cd")
	for k: Variant in hcd.keys():
		hcd[k] = 9999.0   # no Blink Strike onto the Rimecarver (it would break the veil)
	await _secs(4.8)
	_check(hush.helper_abilities.veiled, "Hush not veiled before the rune")
	# Scrying Rune: fog allowed, 12 m, 25 mana.
	var m0 := ab.mana
	_check(await _cast(rc, &"scrying_rune", hush.global_position, 0.8) == "", "Rune refused: %s" % ab.can_cast(&"scrying_rune", hush.global_position))
	_check(_near(m0 - ab.mana, 25.0, 0.5), "Rune costs 25 (%.1f)" % (m0 - ab.mana))
	await _secs(0.6)
	_check(not hush.helper_abilities.veiled and CasterKit.revealed_for(hush), "the rune did not reveal Hush")
	var markers := get_nodes_in_group(&"fog_sources").filter(func(n: Node) -> bool: return n is SightMarker \
			and int(n.get(&"team")) == PLAYER and _near(float(n.get(&"sight_radius")), 10.0, 0.01))
	_check(markers.size() >= 1, "no 10 m SightMarker for the rune")
	# A disguised Saboteur.
	var sab := _spawn("ashveil_saboteur", ENEMY, at + _dir * 9.0 + _side * 2.0, true)
	await _secs(1.0)
	var t3 := T3Kit.ability_of(sab)
	_check(t3 != null and not t3.disguised, "the rune did not reveal the Saboteur")
	# Max 3 runes per Rimecarver.
	for i in 3:
		ab.mana = 200.0
		await _cast(rc, &"scrying_rune", at + _side * float(i * 3), 1.1)
	_check(ab.rune_count() == 3, "max 3 runes (%d)" % ab.rune_count())
	await _cleanup([rc, hush, sab])


func _check_stillness() -> void:
	var rc := await _caster("rimecarver", _spot - _side * 12.0, PLAYER, 0.0)
	var ab := CasterKit.ability_of(rc)
	await _secs(3.3)
	_check(ab.is_still() and _near(ab.mana_regen(), 1.2, 0.01), "Stillness x1.5 regen (%.2f)" % ab.mana_regen())
	rc.command_move(rc.global_position + _dir * 6.0)
	await _secs(0.5)
	_check(not ab.is_still() and _near(ab.mana_regen(), 0.8, 0.01), "Stillness ends when it walks")
	await _cleanup([rc])


# ---------------------------------------------------------------- Bramblesage

func _check_snagroot() -> void:
	var at := _spot + _side * 20.0
	var bs := await _caster("bramblesage", at)
	var ab := CasterKit.ability_of(bs)
	var shade := _spawn("shade", ENEMY, at + _dir * 9.0, true)
	await _frames(30)
	var d0 := _flat(shade.global_position, bs.global_position)
	_check(await _cast(bs, &"snagroot", shade, 1.3) == "", "Snagroot refused: %s" % ab.can_cast(&"snagroot", shade))
	var d1 := _flat(shade.global_position, bs.global_position)
	_check(_near(d0 - d1, 7.0, 0.6), "Shade dragged 7 m (%.2f -> %.2f)" % [d0, d1])
	_check(shade.has_status(&"rooted") and shade.status_time_left(&"rooted") > 0.3, "Snagroot roots")
	# A wizard: 4 m, rooted 0.5 s.
	var wiz: Wizard = main.wizard_of(ENEMY)
	if wiz:
		var pos0 := wiz.global_position
		wiz.global_position = at - _dir * 9.0
		wiz.set_physics_process(true)
		wiz.command_hold()
		await _secs(1.2)
		ab.mana = 200.0
		var w0 := _flat(wiz.global_position, bs.global_position)
		_check(await _cast(bs, &"snagroot", wiz, 1.3) == "", "Snagroot on the wizard: %s" % ab.can_cast(&"snagroot", wiz))
		var w1 := _flat(wiz.global_position, bs.global_position)
		_check(_near(w0 - w1, 4.0, 0.6), "wizard dragged 4 m (%.2f -> %.2f)" % [w0, w1])
		wiz.global_position = pos0
		wiz.set_physics_process(false)
	# Immune: a titan, a pop-4 unit.
	var roc := _spawn("briar_roc", ENEMY, at + _dir * 6.0 + _side * 3.0, true)
	var titan := _spawn("rimeshield", ENEMY, at + _dir * 6.0 - _side * 3.0, true)
	titan.add_to_group(&"titans")
	await _frames(20)
	ab.mana = 200.0
	await _secs(1.1)
	_check(ab.can_cast(&"snagroot", roc) == CasterKit.REASON_INVALID, "Snagroot on a pop-4 unit: '%s'" % ab.can_cast(&"snagroot", roc))
	_check(ab.can_cast(&"snagroot", titan) == CasterKit.REASON_INVALID, "Snagroot on a titan: '%s'" % ab.can_cast(&"snagroot", titan))
	# It breaks a channel: a Deacon's Blood Tithe.
	var deacon := await _caster("gloom_deacon", at + _dir * 8.0 + _side * 4.0, ENEMY)
	var ally := _dummy(deacon.global_position + _side * 3.0, 200.0, ENEMY)
	ally.take_damage(120.0, null)
	await _frames(20)
	var dab := CasterKit.ability_of(deacon)
	_check(dab.cast(&"blood_tithe", ally) == "", "enemy Tithe: %s" % dab.can_cast(&"blood_tithe", ally))
	await _secs(0.3)
	_check(dab.is_channelling(), "enemy Deacon channelling")
	await _cast(bs, &"snagroot", deacon, 1.0)
	_check(not dab.is_channelling(), "Snagroot did not break the Tithe")
	await _cleanup([bs, shade, roc, titan, deacon, ally])


func _check_haze() -> void:
	var at := _spot + _side * 20.0
	var bs := await _caster("bramblesage", at)
	var ab := CasterKit.ability_of(bs)
	var target := _dummy(at + _dir * 3.0, 5000.0, PLAYER)
	var far_archer := _spawn("ember_archer", ENEMY, target.global_position + _dir * 9.0)
	var near_archer := _spawn("ember_archer", ENEMY, target.global_position + _dir * 2.0 + _side * 1.0)
	for a in [far_archer, near_archer]:
		a.add_modifier(&"test_stay", {&"move_speed_pct": -1.0})
		a.command_attack(target)
	await _frames(20)
	var hp_mid := (far_archer.global_position + near_archer.global_position) * 0.5
	var r := await _cast(bs, &"pollen_haze", hp_mid, 0.7)
	_check(r == "", "Pollen Haze refused: %s" % r)
	_check(far_archer.has_status(&"hazed") and near_archer.has_status(&"hazed"), "archers hazed")
	# Only the far one: stop the near one, count the far one's hits.
	near_archer.command_stop()
	near_archer.set_physics_process(false)
	var hp0 := target.hp
	await _secs(3.0)
	_check(_near(target.hp, hp0, 0.01), "a hazed archer at 9 m still shot (%.1f)" % (hp0 - target.hp))
	near_archer.set_physics_process(true)
	near_archer.command_attack(target)
	far_archer.command_stop()
	far_archer.set_physics_process(false)
	hp0 = target.hp
	await _secs(2.5)
	_check(target.hp < hp0 - 1.0, "a hazed archer at 2 m did not shoot")
	await _secs(3.5)
	_check(not near_archer.has_status(&"hazed"), "haze lasts 6 s (+0.5 s linger)")
	await _cleanup([bs, target, far_archer, near_archer])


func _check_seedcloak() -> void:
	var at := _spot + _side * 20.0
	var bs := await _caster("bramblesage", at)
	var ab := CasterKit.ability_of(bs)
	var archer := _spawn("ember_archer", ENEMY, at + _dir * 1.5, true)
	archer.set_physics_process(false)
	await _frames(10)
	bs.take_damage(20.0, null)
	_check(int(ab.casts.get(&"seedcloak", 0)) == 0, "Seedcloak above 50 %")
	bs.take_damage(30.0, null)
	await _secs(0.4)
	_check(int(ab.casts.get(&"seedcloak", 0)) == 1, "Seedcloak under 50 %")
	_check(archer.has_status(&"hazed"), "Seedcloak hazes an archer at 1.5 m")
	bs.heal(999.0)
	bs.take_damage(60.0, null)
	await _frames(5)
	_check(int(ab.casts.get(&"seedcloak", 0)) == 1, "Seedcloak once per 45 s")
	await _cleanup([bs, archer])


# ---------------------------------------------------------------- Gloom Deacon

func _check_tithe() -> void:
	var at := _spot - _side * 20.0
	var dc := await _caster("gloom_deacon", at)
	var ab := CasterKit.ability_of(dc)
	var ally := _dummy(at + _dir * 4.0, 400.0, PLAYER)
	ally.take_damage(300.0, null)
	var foe := _dummy(ally.global_position + _side * 3.0, 1000.0)
	await _frames(30)
	var a0 := ally.hp
	var f0 := foe.hp
	var m0 := ab.mana
	_check(await _cast(dc, &"blood_tithe", ally, 0.0) == "", "Tithe refused: %s" % ab.can_cast(&"blood_tithe", ally))
	await _secs(2.0)
	_check(ab.is_channelling(), "Tithe channelling")
	_check(_near(ally.hp - a0, 20.0, 3.0), "Tithe heals 10 / s (%.1f in 2 s)" % (ally.hp - a0))
	_check(_near(f0 - foe.hp, 10.0, 1.5), "Tithe drains 5 / s (%.1f in 2 s)" % (f0 - foe.hp))
	_check(_near(m0 - ab.mana, 5.0 - 1.6, 0.6), "Tithe 2.5 mana / s, regen 0.8 (%.1f net in 2 s)" % (m0 - ab.mana))
	_check(dc.attacks_blocked, "a channelling Deacon does not attack")
	# Max 2 tethers on one ally.
	var d2 := await _caster("gloom_deacon", at + _side * 2.0)
	var d3 := await _caster("gloom_deacon", at - _side * 2.0)
	_check(CasterKit.ability_of(d2).cast(&"blood_tithe", ally) == "", "second tether")
	await _frames(5)
	_check(CasterKit.ability_of(d3).can_cast(&"blood_tithe", ally) == CasterKit.REASON_INVALID, "third tether refused: '%s'"
			% CasterKit.ability_of(d3).can_cast(&"blood_tithe", ally))
	CasterKit.ability_of(d2).stop_channel()
	# Breaks at 9 m.
	dc.global_position = ally.global_position + _dir * 10.0
	await _secs(0.5)
	_check(not ab.is_channelling() and not dc.attacks_blocked, "Tithe did not break at 9 m")
	# Stops at full HP.
	dc.global_position = ally.global_position - _dir * 3.0
	ally.heal(ally.max_hp - ally.hp - 5.0)
	await _secs(1.2)
	_check(ab.cast(&"blood_tithe", ally) == "", "Tithe on a nearly full ally")
	await _secs(1.5)
	_check(not ab.is_channelling() and _near(ally.hp, ally.max_hp, 0.01), "Tithe stops at full HP")
	await _cleanup([dc, d2, d3, ally, foe])


func _check_passage() -> void:
	var at := _spot - _side * 20.0
	var dc := await _caster("gloom_deacon", at)
	var ab := CasterKit.ability_of(dc)
	var point := at + _dir * 20.0
	var soldiers: Array[Unit] = []
	for i in 7:
		soldiers.append(_spawn("shade", PLAYER, point + Vector3(cos(i * 0.9), 0, sin(i * 0.9)) * 1.6, true))
	soldiers.append(_spawn("shadow_knight", PLAYER, point + _side * 0.5, true))   # pop 3: 7 + 3 = 10
	soldiers.append(_spawn("shade", PLAYER, point - _side * 2.5, true))           # the 11th pop: stays
	var far := _spawn("shade", PLAYER, point + _dir * 6.0, true)                  # outside 4 m
	await _frames(30)
	var m0 := ab.mana
	_check(await _cast(dc, &"umbral_passage", point, 1.0) == "", "Passage refused: %s" % ab.can_cast(&"umbral_passage", point))
	_check(ab.is_channelling() and _near(ab.mana, m0, 0.5), "Passage channelling, mana not spent yet")
	await _secs(1.7)
	var carried := 0
	var pop := 0
	for s in soldiers:
		if _flat(s.global_position, dc.global_position) <= 6.0:
			carried += 1
			pop += s.unit_type.pop
	_check(pop <= 10 and pop >= 9, "Passage carried %d units, %d pop (max 10)" % [carried, pop])
	_check(_flat(far.global_position, dc.global_position) > 10.0, "a soldier outside 4 m was carried")
	_check(_near(m0 - ab.mana, 100.0, 1.5), "Passage costs 100 (%.1f)" % (m0 - ab.mana))
	_check(_near(ab.cooldown_left(&"umbral_passage"), 45.0, 1.5), "cooldown 45 s (%.1f)" % ab.cooldown_left(&"umbral_passage"))
	_check(ab.can_cast(&"umbral_passage", point) == CasterKit.REASON_RECHARGING, "Recharging refusal")
	# Cancelled by a move: mana kept, cooldown 5 s.
	var d2 := await _caster("gloom_deacon", at + _side * 4.0)
	var ab2 := CasterKit.ability_of(d2)
	_check(ab2.cast(&"umbral_passage", point) == "", "second Passage")
	await _secs(1.0)
	d2.command_move(d2.global_position + _dir * 5.0)
	await _frames(5)
	_check(not ab2.is_channelling() and _near(ab2.mana, 200.0, 2.0) and _near(ab2.cooldown_left(&"umbral_passage"), 5.0, 0.3),
			"Passage cancel: channel %s mana %.1f cd %.1f" % [ab2.is_channelling(), ab2.mana, ab2.cooldown_left(&"umbral_passage")])
	await _secs(0.5)
	_check(_flat(d2.global_position, at + _side * 4.0) > 0.5, "the Deacon did not walk after the cancel")
	soldiers.append(far)
	soldiers.append(dc)
	soldiers.append(d2)
	await _cleanup(soldiers)


func _check_vigil() -> void:
	var at := _spot - _side * 20.0
	var dc := await _caster("gloom_deacon", at, PLAYER, 100.0)
	var ab := CasterKit.ability_of(dc)
	var s1 := _spawn("shade", PLAYER, at + _dir * 3.0, true)
	var s2 := _spawn("shade", PLAYER, at + _dir * 12.0, true)
	await _frames(5)
	s1.take_damage(9999.0, null)
	await _frames(2)
	_check(_near(ab.mana, 105.0, 0.3), "Vigil +5 (%.1f)" % ab.mana)
	var m1 := ab.mana
	await _secs(0.6)
	m1 = ab.mana
	s2.take_damage(9999.0, null)
	await _frames(2)
	_check(_near(ab.mana, m1, 0.1), "Vigil ignores a death at 12 m")
	await _cleanup([dc, s1, s2])


# ---------------------------------------------------------------- autocast / smart-cast / levels

func _check_autocast() -> void:
	var defaults := {&"slag_rain": true, &"mana_scald": true, &"rime_bulwark": false, &"scrying_rune": false,
			&"snagroot": true, &"pollen_haze": true, &"blood_tithe": true, &"umbral_passage": false}
	var made: Array = []
	for cid: StringName in CasterKit.IDS:
		var u := _spawn(String(cid), PLAYER, _spot + _side * 30.0 + _dir * float(made.size() * 2))
		made.append(u)
	await _frames(3)
	for u: Unit in made:
		var ab := CasterKit.ability_of(u)
		for s in ab.spell_ids():
			_check(ab.autocast(s) == defaults[s], "%s autocast default %s" % [s, ab.autocast(s)])
		ab.toggle_autocast(ab.spell_ids()[0])
		_check(ab.autocast(ab.spell_ids()[0]) != defaults[ab.spell_ids()[0]], "toggle autocast")
	await _cleanup(made)
	# A real autocast: a Deacon heals a hurt soldier by itself.
	var dc := _spawn("gloom_deacon", PLAYER, _spot - _side * 30.0)
	dc.add_modifier(&"test_harmless", {&"attack_damage_pct": -1.0})
	var hurt := _spawn("shade", PLAYER, dc.global_position + _dir * 4.0, true)
	hurt.take_damage(60.0, null)
	await _secs(1.5)
	_check(CasterKit.ability_of(dc).tithe_target() == hurt, "the Deacon did not autocast Blood Tithe on a hurt Shade")
	# Autocast waits while the caster walks on a move order.
	var kw := _spawn("kilnwarden", PLAYER, _spot + _side * 30.0)
	kw.add_modifier(&"test_harmless", {&"attack_damage_pct": -1.0})
	var clump: Array = []
	for i in 4:
		clump.append(_dummy(kw.global_position + _dir * 7.0 + _side * (float(i) - 1.5) * 0.8))
	await _frames(2)
	CasterKit.ability_of(kw).mana = 200.0
	kw.command_move(kw.global_position - _dir * 30.0)
	await _secs(1.2)
	_check(int(CasterKit.ability_of(kw).casts.get(&"slag_rain", 0)) == 0, "autocast while walking on a move order")
	kw.command_stop()
	CasterKit.ability_of(kw).mana = 200.0
	kw.global_position = clump[0].global_position - _dir * 7.0
	await _secs(2.0)
	_check(int(CasterKit.ability_of(kw).casts.get(&"slag_rain", 0)) == 1, "Slag Rain did not autocast on 4 enemies")
	clump.append_array([dc, hurt, kw])
	await _cleanup(clump)


func _check_smart_cast() -> void:
	var at := _spot + _side * 30.0
	var a := await _caster("kilnwarden", at, PLAYER, 120.0)
	var b := await _caster("kilnwarden", at + _side * 2.0, PLAYER, 180.0)
	var c := await _caster("kilnwarden", at - _dir * 14.0, PLAYER, 200.0)   # out of range
	var point := at + _dir * 8.0
	var foe := _dummy(point)
	await _frames(30)
	var picked := CasterKit.pick_caster([a, b, c], &"slag_rain", point)
	_check(picked == b, "smart-cast: the in-range caster with the most mana (%s)" % (picked.name if picked else "none"))
	var picked2 := CasterKit.pick_caster([c], &"slag_rain", point)
	_check(picked2 == c, "smart-cast: the nearest out of range when none is in range")
	_check(CasterKit.ability_of(c).order_cast(&"slag_rain", point) == "", "order_cast out of range")
	await _secs(4.0)
	_check(int(CasterKit.ability_of(c).casts.get(&"slag_rain", 0)) == 1, "the caster walked into range and cast")
	await _cleanup([a, b, c, foe])


# ---------------------------------------------------------------- code review fixes (M2, L1, M4, L5)

## M2: two casters of one team on autocast never cast the same spell on the same target / clump in the cast + flight
## window (team claims in CasterKit): one Slag Rain on a clump, one Mana Scald on an enemy caster, one Snagroot.
func _check_double_cast() -> void:
	var at := _spot + _side * 30.0
	# Slag Rain: 2 Kilnwardens, a clump of 5 in front of both.
	var k1 := await _caster("kilnwarden", at)
	var k2 := await _caster("kilnwarden", at + _side * 2.0)
	var clump: Array = []
	for i in 5:
		clump.append(_dummy(at + _side * 1.0 + _dir * 7.0 + _side * (float(i) - 2.0) * 0.7))
	await _frames(20)
	for k in [k1, k2]:
		CasterKit.ability_of(k).set_autocast(&"slag_rain", true)
	await _secs(2.5)
	var slags := int(CasterKit.ability_of(k1).casts.get(&"slag_rain", 0)) + int(CasterKit.ability_of(k2).casts.get(&"slag_rain", 0))
	_check(slags == 1, "two Kilnwardens autocast %d Slag Rains on one clump (want 1)" % slags)
	for k in [k1, k2]:
		CasterKit.ability_of(k).set_autocast(&"slag_rain", false)
	await _cleanup(clump)
	# Mana Scald: the same 2 Kilnwardens, an enemy Deacon with 150 mana in range of both.
	var foe := await _caster("gloom_deacon", at + _side * 1.0 + _dir * 6.0, ENEMY, 150.0)
	for k in [k1, k2]:
		CasterKit.ability_of(k).mana = 200.0
	await _frames(20)
	for k in [k1, k2]:
		CasterKit.ability_of(k).set_autocast(&"mana_scald", true)
	await _secs(1.5)
	var scalds := int(CasterKit.ability_of(k1).casts.get(&"mana_scald", 0)) + int(CasterKit.ability_of(k2).casts.get(&"mana_scald", 0))
	_check(scalds == 1, "two Kilnwardens autocast %d Mana Scalds on one caster (want 1)" % scalds)
	await _cleanup([k1, k2, foe])
	# Snagroot: 2 Bramblesages, an enemy caster 7 m away.
	var b1 := await _caster("bramblesage", at)
	var b2 := await _caster("bramblesage", at + _side * 2.0)
	var mark := await _caster("kilnwarden", at + _side * 1.0 + _dir * 7.0, ENEMY, 0.0)
	mark.add_modifier(&"test_sturdy", {&"max_hp_pct": 100.0})
	await _frames(20)
	for b in [b1, b2]:
		CasterKit.ability_of(b).set_autocast(&"snagroot", true)
	await _secs(2.0)
	var snags := int(CasterKit.ability_of(b1).casts.get(&"snagroot", 0)) + int(CasterKit.ability_of(b2).casts.get(&"snagroot", 0))
	_check(snags == 1, "two Bramblesages autocast %d Snagroots on one caster (want 1)" % snags)
	await _cleanup([b1, b2, mark])
	# A cancelled cast drops its claim at once.
	var k3 := await _caster("kilnwarden", at)
	var p := at + _dir * 6.0
	_check(await _cast(k3, &"slag_rain", p) == "", "slag for the claim check")
	_check(CasterKit.is_claimed(PLAYER, &"slag_rain", p, null, 3.0), "a Slag Rain being cast is not claimed")
	k3.apply_status(&"dazed", 0.5)
	await _frames(3)
	_check(not CasterKit.is_claimed(PLAYER, &"slag_rain", p, null, 3.0), "an interrupted Slag Rain keeps its claim")
	await _cleanup([k3])


## L1: a caster on its 1 s global cooldown that is out of range is still smart-cast's walk-in pick (it walks, then
## casts once the cooldown is over) instead of answering "Recharging".
func _check_walk_while_recharging() -> void:
	var at := _spot + _side * 30.0
	var c := await _caster("kilnwarden", at)
	var ab := CasterKit.ability_of(c)
	var near := at + _dir * 5.0
	var far := at + _dir * 15.0
	var foe := _spawn("shade", PLAYER, far + _side * 1.5, true)   # own sight on the far point (no fog refusal)
	await _frames(20)
	_check(await _cast(c, &"slag_rain", near) == "", "first slag (starts the global cooldown)")
	await _frames(30)   # released; the 1 s global cooldown runs
	_check(ab.gcd_left() > 0.0, "global cooldown running")
	_check(ab.can_cast(&"slag_rain", far) == CasterKit.REASON_RANGE, "recharging + out of range: '%s' (want Out of range)"
			% ab.can_cast(&"slag_rain", far))
	_check(ab.can_cast(&"slag_rain", near) == CasterKit.REASON_RECHARGING, "recharging in range still says Recharging")
	_check(CasterKit.pick_caster([c], &"slag_rain", far) == c, "smart-cast does not send the recharging caster")
	_check(ab.order_cast(&"slag_rain", far) == "" and ab.is_approaching(), "order_cast does not walk it in")
	await _secs(4.0)
	_check(int(ab.casts.get(&"slag_rain", 0)) == 2, "it walked in and cast after the cooldown (%d casts)" % int(ab.casts.get(&"slag_rain", 0)))
	await _cleanup([c, foe])


## M4 / L5: an expired rune leaves no empty team key (revealed_for's early-out), casters get spawn-order serials.
func _check_registries() -> void:
	CasterKit.register_rune(ENEMY, _spot, 10.0, CasterKit.now_s() - 1.0, null, null)
	_check(CasterKit.runes_of(-1).is_empty() and CasterKit._runes.is_empty(), "an expired rune leaves an empty team key")
	var a := UnitType.find("kilnwarden").create_unit()
	var b := UnitType.find("kilnwarden").create_unit()
	main.add_child(a)
	main.add_child(b)
	var sa := CasterKit.ability_of(a).serial
	var sb := CasterKit.ability_of(b).serial
	_check(sa > 0 and sb == sa + 1, "caster serials follow the spawn order (%d, %d)" % [sa, sb])
	a.queue_free()
	b.queue_free()


func _check_levels() -> void:
	var u := await _caster("kilnwarden", _spot + _side * 30.0)
	var ab := CasterKit.ability_of(u)
	var hp0 := u.max_hp
	u.add_xp(Unit.VETERANCY_XP[1])
	await _frames(2)
	_check(u.level == 2, "level 2")
	_check(_near(ab.max_mana(), 220.0, 0.01) and _near(u.get_stat(&"mana_regen"), 0.85, 0.001), "level 2: +20 mana, +0.05 / s")
	_check(_near(u.max_hp, hp0 * 1.1, 0.6), "level 2: +10 %% HP (%.1f)" % u.max_hp)
	_check(_near(u.get_stat(&"attack_damage"), 0.0, 0.01), "level 2: no damage gain")   # the test modifier zeroes it
	u.remove_modifier(&"test_harmless")
	_check(_near(u.get_stat(&"attack_damage"), 5.0, 0.01), "caster damage stays 5 at level 2 (%.1f)" % u.get_stat(&"attack_damage"))
	await _cleanup([u])
