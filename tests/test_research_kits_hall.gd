extends SceneTree
## UR.G3 (docs/design/unit-upgrades.md 9-10, 14): K reads of the Hall's 12 new units (NewUnits12) and S reads of the
## support casters (Rime Seer, Bloomtender) through UnitResearch.param. The PLAYER team gets every K / S row of those
## units; each ability is staged twice: once for PLAYER (the researched number) and once for ENEMY (no row: today's
## number). A bare world (no map), UnitResearch.force_enabled.
## Run:  tools/godot_run.ps1 --headless --path . -s tests/test_research_kits_hall.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "research_kits_hall"
const PLAYER := 0
const ENEMY := 1
const ROW_IDS: Array[StringName] = [&"scorchling_volatile_core", &"pyre_adept_kindling_lore",
		&"cinder_arbalest_barbed_bolts", &"barrow_ghoul_gorge", &"hexweaver_deepening_hex",
		&"hollow_oathsworn_oath_unending", &"hoarlight_magebow_needle_volley", &"frost_mortar_wide_shells",
		&"thistle_darter_quickfoot", &"vinelasher_strangling_vines", &"greenheart_oathkeeper_heartwood_oath",
		&"rime_seer_thick_rime", &"rime_seer_quick_ward", &"bloomtender_deep_roots", &"bloomtender_wide_bloom"]

var world: Node3D
var _errors: Array[String] = []
var _checks := 0
var _base := Vector3.ZERO


func _initialize() -> void:
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _wait_for(cond: Callable, max_frames: int) -> bool:
	for f in max_frames:
		if cond.call():
			return true
		await physics_frame
	return bool(cond.call())


func _near(a: float, b: float, tol: float = 0.01) -> bool:
	return absf(a - b) <= tol


func _other(team: int) -> int:
	return ENEMY if team == PLAYER else PLAYER


func _tag(team: int) -> String:
	return "researched" if team == PLAYER else "no row"


func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	var u: Unit = UnitType.find(id).create_unit()
	u.team = team as Unit.Team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


## A punching bag: armor 0, no damage, never auto-targeted.
func _dummy(team: int, pos: Vector3, hp: float = 5000.0) -> Unit:
	var u := Unit.new()
	u.team = team as Unit.Team
	u.max_hp = hp
	u.aggro_range = 0.0
	u.attack_damage = 0.0
	world.add_child(u)
	u.global_position = pos
	u.command_hold()
	u.hide_from_auto_target(9999.0)
	return u


## Each case gets a fresh spot far from the previous ones.
func _spot() -> Vector3:
	_base += Vector3(60.0, 0.0, 0.0)
	return _base


func _cleanup(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n):
			(n as Node).queue_free()
	await _frames(2)


func _run() -> void:
	world = Node3D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	UnitResearch.force_enabled = true
	NewUnits12.force_enabled = true
	await _frames(2)
	var ur := UnitResearch.for_team(PLAYER)
	_ok(ur != null, "no UnitResearch node for the player")
	if ur == null:
		_finish()
		return
	# Living before the rows are done: they must pick the numbers up mid-life.
	var old_vow := _spawn("hollow_oathsworn", PLAYER, _spot())
	var old_seer := _spawn("rime_seer", PLAYER, _spot())
	await _frames(2)
	_ok(_near(old_seer.support_caster.current_amount(), 60.0), "Rime Seer before the row: %.0f" % old_seer.support_caster.current_amount())
	for id in ROW_IDS:
		_ok(UnitResearch.ROWS.has(id), "row %s missing" % id)
		ur.grant(id)
	await _frames(80)   # > one 0.5 s ability tick and the seer's first 1 s try
	old_vow.take_damage(old_vow.max_hp * 0.8, null)
	await _frames(1)
	_ok(_near(old_vow.shield, 80.0), "mid-life row: Unbroken Vow shield %.0f (want 80)" % old_vow.shield)
	_ok(_near(old_seer.support_caster.current_amount(), 85.0), "mid-life row: Rime Seer %.0f (want 85)"
			% old_seer.support_caster.current_amount())
	await _cleanup([old_vow, old_seer])
	_ok(not UnitResearch.team_has(ENEMY, ROW_IDS[0]), "the enemy team has a row")
	await _check_params()
	for team: int in [PLAYER, ENEMY]:
		await _flashpoint(team)
		await _flame_burst(team)
		await _pierce(team)
		await _grave_feast(team)
		await _wither(team)
		await _vow(team)
		await _frost_needle(team)
		await _frost_shell(team)
		await _skitter(team)
		await _snare(team)
		await _grove_oath(team)
		await _seer(team)
		await _bloomtender(team)
	UnitResearch.lab_off = true
	var u := _spawn("scorchling", PLAYER, _spot())
	_ok(_near(UnitResearch.param(u, &"flashpoint_damage", 15.0), 15.0), "lab_off: param still gives the row")
	UnitResearch.lab_off = false
	await _cleanup([u])
	_finish()


func _finish() -> void:
	UnitResearch.force_enabled = false
	NewUnits12.force_enabled = false
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _checks])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit()


# ---------------------------------------------------------------- param table: every key, both teams

func _check_params() -> void:
	var made: Array = []
	for id in ROW_IDS:
		var row: Dictionary = UnitResearch.ROWS.get(id, {})
		if row.is_empty():
			continue
		var uid: StringName = (row["units"] as Array)[0]
		var p := _spawn(String(uid), PLAYER, _spot())
		var e := _spawn(String(uid), ENEMY, _spot())
		made.append_array([p, e])
		var kit: Dictionary = row["kit"]
		_ok(not kit.is_empty(), "%s has no kit numbers" % id)
		for key: StringName in kit:
			_ok(_near(UnitResearch.param(p, key, -999.0), float(kit[key])), "%s: player %s" % [id, key])
			_ok(_near(UnitResearch.param(e, key, -999.0), -999.0), "%s: enemy %s changed" % [id, key])
	await _cleanup(made)


# ---------------------------------------------------------------- Fire

func _flashpoint(team: int) -> void:
	var p := _spot()
	var d1 := _dummy(_other(team), p + Vector3(1.0, 0, 0))
	var d2 := _dummy(_other(team), p + Vector3(0, 0, 2.25 + d1.radius))   # inside 2.5 m, outside 2 m
	var s := _spawn("scorchling", team, p)
	s.attacks_blocked = true
	await _frames(2)
	s.take_damage(99999.0, null)
	await _frames(2)
	var want := 25.0 if team == PLAYER else 15.0
	_ok(_near(d1.max_hp - d1.hp, want), "Flashpoint %s: %.1f (want %.1f)" % [_tag(team), d1.max_hp - d1.hp, want])
	var far_hit := d2.hp < d2.max_hp
	_ok(far_hit == (team == PLAYER), "Flashpoint %s: unit at 2.25 m hit = %s" % [_tag(team), far_hit])
	await _cleanup([d1, d2, s])


func _flame_burst(team: int) -> void:
	var p := _spot()
	var o := _other(team)
	var dummies: Array = []
	var gap := 2.75 + 0.45   # dummy radius: only a 3 m burst groups two of them
	if team == PLAYER:
		# a wide pair: needs radius 3 AND a min count of 2
		dummies.append(_dummy(o, p + Vector3(5.0, 0, 0)))
		dummies.append(_dummy(o, p + Vector3(5.0, 0, gap)))
	else:
		# a close pair (min count 3 kept) + a wide line of three (radius 2.5 kept): never fires
		dummies.append(_dummy(o, p + Vector3(5.0, 0, -6.0)))
		dummies.append(_dummy(o, p + Vector3(5.0, 0, -5.2)))
		for k in 3:
			dummies.append(_dummy(o, p + Vector3(5.0, 0, 1.0 + gap * k)))
	var a := _spawn("pyre_adept", team, p)
	a.attacks_blocked = true
	var ab := NewUnits12.ability_of(a)
	var fired := await _wait_for(func() -> bool: return ab.casts > 0, 90)
	_ok(fired == (team == PLAYER), "Flame Burst %s: fired = %s" % [_tag(team), fired])
	await _cleanup(dummies + [a])


func _pierce(team: int) -> void:
	var p := _spot()
	var front := _dummy(_other(team), p + Vector3(8.0, 0, 0))
	var back := _dummy(_other(team), p + Vector3(9.8, 0, 0))
	var arb := _spawn("cinder_arbalest", team, p)
	arb.command_attack(front)
	var ok := await _wait_for(func() -> bool: return back.hp < back.max_hp, 400)
	var want := arb.attack_damage * (0.8 if team == PLAYER else 0.5)
	_ok(ok and _near(back.max_hp - back.hp, want), "Pierce %s: %.1f (want %.1f)" % [_tag(team), back.max_hp - back.hp, want])
	await _cleanup([front, back, arb])


# ---------------------------------------------------------------- Shadow

func _grave_feast(team: int) -> void:
	var p := _spot()
	var prey := _dummy(_other(team), p + Vector3(1.4, 0, 0), 5.0)
	var g := _spawn("barrow_ghoul", team, p)
	g.attacks_blocked = true   # no kill before its HP is set
	await _frames(2)
	g.hp = 20.0
	g.attacks_blocked = false
	g.command_attack(prey)
	var ok := await _wait_for(func() -> bool: return not prey.is_alive(), 300)
	await _frames(1)
	var pct := 0.5 if team == PLAYER else 0.3
	var got := (g.hp - 20.0) / g.max_hp
	_ok(ok and got >= pct - 0.005 and got < pct + 0.05, "Grave Feast %s: healed %.3f of max (want %.2f; killed %s, prey hp %.1f)"
			% [_tag(team), got, pct, ok, prey.hp])
	await _cleanup([prey, g])


func _wither(team: int) -> void:
	var p := _spot()
	var k := _spawn("shadow_knight", _other(team), p + Vector3(6.0, 0, 0))
	k.aggro_range = 0.0
	k.command_hold()
	k.hide_from_auto_target(9999.0)
	var sp0 := k.get_stat(&"move_speed")
	var hx := _spawn("hexweaver", team, p)
	hx.attacks_blocked = true
	var ok := await _wait_for(func() -> bool: return k.has_modifier(NewUnits12.WITHER_MOD), 90)
	var left := float(k.get_meta(NewUnits12.WITHER_META, 0.0)) - CasterKit.now_s()
	var want_t := 8.0 if team == PLAYER else 6.0
	_ok(ok and _near(left, want_t, 0.1), "Wither Hex %s: %.2f s (want %.1f)" % [_tag(team), left, want_t])
	var want_sp := sp0 - (1.0 if team == PLAYER else 0.0)
	_ok(_near(k.get_stat(&"move_speed"), want_sp), "Wither Hex %s: speed %.2f (want %.2f)" % [_tag(team), k.get_stat(&"move_speed"), want_sp])
	await _cleanup([k, hx])


func _vow(team: int) -> void:
	var o := _spawn("hollow_oathsworn", team, _spot())
	await _frames(2)
	o.take_damage(o.max_hp * 0.8, null)
	await _frames(1)
	var want := 80.0 if team == PLAYER else 50.0
	_ok(_near(o.shield, want), "Unbroken Vow %s: shield %.0f (want %.0f)" % [_tag(team), o.shield, want])
	var cd := NewUnits12.ability_of(o).cooldown_left()
	var want_cd := 30.0 if team == PLAYER else 45.0
	_ok(_near(cd, want_cd, 0.1), "Unbroken Vow %s: cooldown %.2f (want %.0f)" % [_tag(team), cd, want_cd])
	await _cleanup([o])


# ---------------------------------------------------------------- Ice

func _frost_needle(team: int) -> void:
	var p := _spot()
	var d := _dummy(_other(team), p + Vector3(8.0, 0, 0))
	var hits: Array[float] = []
	d.damage_taken.connect(func(amount: float, _by: Node3D) -> void: hits.append(amount))
	var mb := _spawn("hoarlight_magebow", team, p)
	mb.attacks_blocked = true
	var ab := NewUnits12.ability_of(mb)
	var ok := await _wait_for(func() -> bool: return ab.casts > 0, 90)
	var want := 26.0 if team == PLAYER else 20.0
	_ok(ok and hits.size() == 1 and _near(hits[0], want), "Frost Needle %s: hits %s (want %.0f)" % [_tag(team), hits, want])
	var want_cd := 6.0 if team == PLAYER else 8.0
	_ok(_near(ab.cooldown_left(), want_cd, 0.1), "Frost Needle %s: cooldown %.2f (want %.0f)" % [_tag(team), ab.cooldown_left(), want_cd])
	await _cleanup([d, mb])


func _frost_shell(team: int) -> void:
	var p := _spot()
	var target := _dummy(_other(team), p + Vector3(10.0, 0, 0))
	var side := _dummy(_other(team), p + Vector3(10.0, 0, 2.4 + 0.45))   # inside 2.75 m, outside 2 m
	var fm := _spawn("frost_mortar", team, p)
	fm.command_attack(target)
	var ok := await _wait_for(func() -> bool: return target.hp < target.max_hp, 400)
	await _frames(1)
	_ok(ok, "Frost Shell %s: the mortar never hit" % _tag(team))
	var hit := side.hp < side.max_hp
	_ok(hit == (team == PLAYER), "Frost Shell %s: unit at 2.4 m hit = %s" % [_tag(team), hit])
	await _cleanup([target, side, fm])


# ---------------------------------------------------------------- Nature

func _skitter(team: int) -> void:
	var p := _spot()
	var d := _dummy(_other(team), p + Vector3(7.0, 0, 0))
	var td := _spawn("thistle_darter", team, p)
	var sp0 := td.get_stat(&"move_speed")
	td.command_attack(d)
	var ok := await _wait_for(func() -> bool: return td.has_modifier(NewUnits12.SKITTER_MOD), 300)
	var gain := td.get_stat(&"move_speed") - sp0
	var want := 1.5 if team == PLAYER else 1.0
	_ok(ok and _near(gain, want), "Skitter %s: +%.2f speed (want %.1f)" % [_tag(team), gain, want])
	var left := NewUnits12.ability_of(td).self_modifier_left()
	var want_t := 2.5 if team == PLAYER else 1.5
	_ok(_near(left, want_t, 0.05), "Skitter %s: %.2f s (want %.1f)" % [_tag(team), left, want_t])
	await _cleanup([d, td])


func _snare(team: int) -> void:
	var p := _spot()
	var d := _dummy(_other(team), p + Vector3(3.0, 0, 0))
	var hits: Array[float] = []
	d.damage_taken.connect(func(amount: float, _by: Node3D) -> void: hits.append(amount))
	var v := _spawn("vinelasher", team, p)
	v.attacks_blocked = true
	var ab := NewUnits12.ability_of(v)
	var ok := await _wait_for(func() -> bool: return ab.casts > 0, 90)
	var want := 18.0 if team == PLAYER else 10.0
	_ok(ok and hits.size() == 1 and _near(hits[0], want), "Snare Lash %s: hits %s (want %.0f)" % [_tag(team), hits, want])
	var want_r := 2.0 if team == PLAYER else 1.5
	var root := d.status_time_left(&"rooted")
	_ok(_near(root, want_r, 0.05), "Snare Lash %s: root %.2f (want %.1f)" % [_tag(team), root, want_r])
	await _cleanup([d, v])


func _grove_oath(team: int) -> void:
	var p := _spot()
	var close := _dummy(_other(team), p + Vector3(3.0, 0, 0))
	var far := _dummy(_other(team), p + Vector3(0, 0, 5.75))   # inside 6.5 m, outside 5 m (+ radius)
	var g := _spawn("greenheart_oathkeeper", team, p)
	g.attacks_blocked = true
	var ab := NewUnits12.ability_of(g)
	var ok := await _wait_for(func() -> bool: return ab.casts > 0, 90)
	_ok(ok and close.has_status(&"taunted"), "Grove Oath %s: never fired" % _tag(team))
	_ok(far.has_status(&"taunted") == (team == PLAYER), "Grove Oath %s: unit at 5.75 m taunted = %s"
			% [_tag(team), far.has_status(&"taunted")])
	var brace := g.status_time_left(&"braced")
	var want := 5.0 if team == PLAYER else 4.0
	_ok(_near(brace, want, 0.05), "Grove Oath %s: brace %.2f (want %.0f)" % [_tag(team), brace, want])
	await _cleanup([close, far, g])


# ---------------------------------------------------------------- support casters (S rows)

func _seer(team: int) -> void:
	var p := _spot()
	var ally := _spawn("shade", team, p + Vector3(3.0, 0, 0))
	ally.aggro_range = 0.0
	await _frames(1)
	ally.hp = ally.max_hp * 0.3
	var seer := _spawn("rime_seer", team, p)
	var sc := seer.support_caster
	var ok := await _wait_for(func() -> bool: return ally.shield > 0.0, 120)
	var want := 85.0 if team == PLAYER else 60.0
	_ok(ok and _near(ally.shield, want), "Rime Seer %s: shield %.0f (want %.0f)" % [_tag(team), ally.shield, want])
	var want_i := 9.0 if team == PLAYER else 12.0
	_ok(sc != null and _near(sc.time_left(), want_i, 0.05), "Rime Seer %s: next ward in %.2f (want %.0f)"
			% [_tag(team), sc.time_left() if sc else -1.0, want_i])
	await _cleanup([ally, seer])


func _bloomtender(team: int) -> void:
	var p := _spot()
	var far := _spawn("shade", team, p + Vector3(8.0, 0, 0))     # inside 9 m, outside 7 m
	var close := _spawn("shade", team, p + Vector3(0, 0, 3.0))
	for a: Unit in [far, close]:
		a.aggro_range = 0.0
	await _frames(1)
	far.hp = far.max_hp * 0.2       # the lowest ratio: picked when in range
	close.hp = close.max_hp * 0.5
	var far0 := far.hp
	var close0 := close.hp
	var bt := _spawn("bloomtender", team, p)
	var ok := await _wait_for(func() -> bool: return far.hp > far0 + 0.5 or close.hp > close0 + 0.5, 120)
	if team == PLAYER:
		_ok(ok and _near(far.hp - far0, 16.0, 0.1) and _near(close.hp, close0, 0.1),
				"Bloomtender researched: far +%.1f, close +%.1f (want far +16)" % [far.hp - far0, close.hp - close0])
	else:
		_ok(ok and _near(close.hp - close0, 12.0, 0.1) and _near(far.hp, far0, 0.1),
				"Bloomtender no row: far +%.1f, close +%.1f (want close +12)" % [far.hp - far0, close.hp - close0])
	await _cleanup([far, close, bt])
