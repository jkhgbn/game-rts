extends SceneTree
## New units 12 (docs/design/new-units-12.md): the 12 .tres; each skirmish Hall lists its 3 new units as slots 6-8;
## tier-2 units (requires_tier 2) are refused "Requires Stronghold" at tier 1, then all 12 train at tier 2; each ability fires once in a staged fight; the bot never picks a gated unit.
## Run:  godot --headless --path . -s tests/test_new_units_12.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "new_units_12"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const TIMEOUT_FRAMES := 7000

var main: Node
var frame := 0
var _wait := 0
var _started := false
var _done := false
var _errors: Array[String] = []
var _halls := {}
var _spot := Vector3.ZERO
var _dir := Vector3.ZERO
var _side := Vector3.ZERO


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
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out; %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	_check_data()
	await _check_gate_and_training()
	await _check_abilities()
	await _check_bot()
	_done = true


# ---------------------------------------------------------------- data

func _check_data() -> void:
	_check(NewUnits12.ENABLED, "NewUnits12.ENABLED is off")
	_check(NewUnits12.enabled_here(), "new units not enabled in scenes/skirmish.tscn")
	var per_kingdom := {}
	for id: StringName in NewUnits12.UNITS:
		var t := UnitType.find(String(id))
		if t == null:
			_check(false, "missing data/units/%s.tres" % id)
			continue
		var d: Dictionary = NewUnits12.UNITS[id]
		_check(t.faction == d["faction"] and t.card_key == d["key"] and t.model_scene != null and t.cost > 0
				and not t.is_worker, "%s data" % id)
		var m := t.model_scene.instantiate()
		_check(m is Node3D, "%s model does not instance" % id)
		if m:
			m.free()
		per_kingdom[d["faction"]] = int(per_kingdom.get(d["faction"], 0)) + 1
	for f: StringName in [&"fire", &"shadow", &"ice", &"nature"]:
		_check(int(per_kingdom.get(f, 0)) == 3, "%s has %d new units" % [f, int(per_kingdom.get(f, 0))])
	_check(NewUnits12.hall_units(BuildingType.find("fire_keep")).is_empty(), "a keep lists new units")


# ---------------------------------------------------------------- gate + training

func _hall(f: StringName, i: int) -> TrainingBuilding:
	var keep: Node3D = main.keep
	var pos := keep.global_position - _dir * 2.0 + _side * (-15.0 + 10.0 * i)
	return main.build_grid.spawn_complete(BuildingType.find("%s_barracks" % f), pos, PLAYER) as TrainingBuilding


func _count(id: StringName) -> int:
	var n := 0
	for u in get_nodes_in_group(&"units"):
		if u is Unit and int(u.team) == PLAYER and u.unit_type and u.unit_type.id == id and u.is_alive():
			n += 1
	return n


## The tier system of the game (tiers-wave.md); the test adds one if the skirmish has none yet.
func _tiers() -> TierSystem:
	var ts := TierSystem.instance()
	if ts == null:
		ts = TierSystem.new()
		main.add_child(ts)
	return ts


func _check_gate_and_training() -> void:
	var keep: Node3D = main.keep
	_dir = -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	_side = _dir.cross(Vector3.UP)
	_spot = keep.global_position + _dir * 20.0
	main.economy.add(30000)
	main.economy.add_pop_bonus(150)
	var ts := _tiers()
	await _frames(1)
	ts.set_tier(PLAYER, 1)
	for id: StringName in NewUnits12.UNITS:
		var want := 2 if NewUnits12.tier_of(id) == 2 else 1
		_check(UnitType.find(String(id)).requires_tier == want, "%s requires_tier %d (want %d)"
				% [id, UnitType.find(String(id)).requires_tier, want])
	var i := 0
	for f: StringName in [&"fire", &"shadow", &"ice", &"nature"]:
		_halls[f] = _hall(f, i)
		i += 1
	await _frames(2)
	var fire: TrainingBuilding = _halls[&"fire"]
	var types := fire.trainable_types()
	var ids := types.map(func(t: UnitType) -> StringName: return t.id)
	_check(types.size() == 8 and ids.slice(5) == [&"scorchling", &"pyre_adept", &"cinder_arbalest"],
			"Ember Hall slots %s" % str(ids))
	# Tier 1: every T1 new unit trains, every T2 one is refused "Requires Stronghold".
	for id: StringName in NewUnits12.UNITS:
		var hall: TrainingBuilding = _halls[NewUnits12.UNITS[id]["faction"]]
		var r := hall.can_queue(UnitType.find(String(id)))
		if NewUnits12.tier_of(id) == 2:
			_check(r == TierSystem.MSG_T2, "%s at tier 1: '%s' (want %s)" % [id, r, TierSystem.MSG_T2])
		else:
			_check(r == "", "%s (T1) refused at tier 1: %s" % [id, r])
	# Stronghold reached: all 12 train at their kingdom's Hall.
	ts.set_tier(PLAYER, 2)
	var before := {}
	for id: StringName in NewUnits12.UNITS:
		before[id] = _count(id)
		var quick := UnitType.find(String(id)).duplicate() as UnitType
		quick.train_time = 0.2
		var hall: TrainingBuilding = _halls[NewUnits12.UNITS[id]["faction"]]
		var r := hall.queue_unit(quick)
		_check(r == "", "queue %s at tier 2: %s" % [id, r])
	await _frames(90)
	for id: StringName in NewUnits12.UNITS:
		_check(_count(id) == int(before[id]) + 1, "%s did not train" % id)
		for u in get_nodes_in_group(&"units"):
			if u is Unit and u.unit_type and u.unit_type.id == id:
				_check(NewUnits12.ability_of(u) != null, "%s has no ability node" % id)
				break
	for u in get_nodes_in_group(&"units"):
		if u is Unit and u.unit_type and NewUnits12.is_new_unit(u.unit_type.id):
			u.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- abilities

func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	var u := UnitType.find(id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	return u


## A punching bag: armor 0, no damage, not auto-targeted by anything else.
func _dummy(pos: Vector3, hp: float = 5000.0) -> Unit:
	var u := Unit.new()
	u.team = ENEMY as Unit.Team
	u.max_hp = hp
	u.aggro_range = 0.0
	u.attack_damage = 0.0
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	u.hide_from_auto_target(9999.0)
	return u


func _cleanup(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	await _frames(2)


func _wait_for(cond: Callable, max_frames: int) -> bool:
	for f in max_frames:
		if cond.call():
			return true
		await physics_frame
	return bool(cond.call())


func _check_abilities() -> void:
	var p := _spot
	# Scorchling: Flashpoint on death.
	var d := _dummy(p + Vector3(1.2, 0, 0))
	var s := _spawn("scorchling", PLAYER, p)
	await _frames(2)
	s.take_damage(9999.0, null)
	await _frames(2)
	_check(is_equal_approx(d.max_hp - d.hp, 15.0), "Flashpoint dealt %.1f (want 15)" % (d.max_hp - d.hp))
	await _cleanup([d, s])

	# Pyre Adept: Flame Burst on a clump of 3.
	var clump: Array = []
	for k in 3:
		clump.append(_dummy(p + Vector3(5.0, 0, -0.8 + 0.8 * k)))
	var a := _spawn("pyre_adept", PLAYER, p)
	var ok := await _wait_for(func() -> bool: return NewUnits12.ability_of(a).casts > 0, 120)
	_check(ok, "Flame Burst never fired")
	for c: Unit in clump:
		_check(c.max_hp - c.hp >= 30.0 - 0.01, "Flame Burst: a clumped unit lost %.1f" % (c.max_hp - c.hp))
	await _cleanup(clump + [a])

	# Cinder Arbalest: the bolt goes on to the enemy behind (half damage).
	var front := _dummy(p + Vector3(8.0, 0, 0))
	var back := _dummy(p + Vector3(9.8, 0, 0))
	var arb := _spawn("cinder_arbalest", PLAYER, p)
	arb.command_attack(front)
	ok = await _wait_for(func() -> bool: return back.hp < back.max_hp, 300)
	_check(ok and is_equal_approx(back.max_hp - back.hp, 10.0), "Piercing bolt: the unit behind lost %.1f (want 10)"
			% (back.max_hp - back.hp))
	await _cleanup([front, back, arb])

	# Barrow Ghoul: Grave Feast heals 30 % on a kill.
	var prey := _dummy(p + Vector3(1.5, 0, 0), 5.0)
	var g := _spawn("barrow_ghoul", PLAYER, p)
	await _frames(2)
	g.hp = 20.0
	g.command_attack(prey)
	ok = await _wait_for(func() -> bool: return not prey.is_alive(), 240)
	await _frames(2)
	_check(ok and g.hp >= 20.0 + g.max_hp * 0.3 - 0.01, "Grave Feast: ghoul hp %.1f after the kill" % g.hp)
	await _cleanup([prey, g])

	# Hexweaver: Wither Hex on the costliest enemy soldier.
	var knight := _spawn("shadow_knight", ENEMY, p + Vector3(6.0, 0, 0))
	knight.aggro_range = 0.0
	knight.command_hold()
	var cheap := _spawn("shade", ENEMY, p + Vector3(6.0, 0, 3.0))
	cheap.aggro_range = 0.0
	cheap.command_hold()
	var dmg0 := knight.attack_damage
	var hx := _spawn("hexweaver", PLAYER, p)
	hx.command_hold()
	ok = await _wait_for(func() -> bool: return knight.has_modifier(NewUnits12.WITHER_MOD), 120)
	_check(ok, "Wither Hex never landed on the Shadow Knight")
	_check(is_equal_approx(knight.attack_damage, dmg0 * 0.8), "withered damage %.1f (want %.1f)"
			% [knight.attack_damage, dmg0 * 0.8])
	_check(not cheap.has_modifier(NewUnits12.WITHER_MOD), "Wither Hex picked the cheaper unit")
	await _cleanup([knight, cheap, hx])

	# Hollow Oathsworn: Unbroken Vow under 35 % HP.
	var o := _spawn("hollow_oathsworn", PLAYER, p)
	await _frames(2)
	o.take_damage(o.max_hp * 0.8, null)   # armor 10: ~190 lands, HP 70 < 35 %
	await _frames(1)
	_check(o.shield > 0.0 and o.has_modifier(NewUnits12.VOW_MOD), "Unbroken Vow did not fire (shield %.0f)" % o.shield)
	await _cleanup([o])

	# Rimeling: every hit chills.
	d = _dummy(p + Vector3(1.4, 0, 0))
	var r := _spawn("rimeling", PLAYER, p)
	r.command_attack(d)
	ok = await _wait_for(func() -> bool: return d.has_status(&"chill"), 180)
	_check(ok, "Rimeling hit did not chill")
	await _cleanup([d, r])

	# Hoarlight Magebow: Frost Needle.
	d = _dummy(p + Vector3(8.0, 0, 0))
	var mb := _spawn("hoarlight_magebow", PLAYER, p)
	mb.command_attack(d)
	ok = await _wait_for(func() -> bool: return NewUnits12.ability_of(mb).casts > 0, 120)
	_check(ok and d.max_hp - d.hp >= 20.0 - 0.01 and d.has_status(&"chill"), "Frost Needle: lost %.1f, chill %s"
			% [d.max_hp - d.hp, d.has_status(&"chill")])
	await _cleanup([d, mb])

	# Frost Mortar: the shell splashes and chills.
	var main_t := _dummy(p + Vector3(10.0, 0, 0))
	var near := _dummy(p + Vector3(10.0, 0, 1.2))
	var fm := _spawn("frost_mortar", PLAYER, p)
	fm.command_attack(main_t)
	ok = await _wait_for(func() -> bool: return near.hp < near.max_hp, 400)
	_check(ok and is_equal_approx(near.max_hp - near.hp, 26.0) and near.has_status(&"chill")
			and main_t.has_status(&"chill"), "Frost Shell: splash %.1f chill %s/%s" % [near.max_hp - near.hp,
			near.has_status(&"chill"), main_t.has_status(&"chill")])
	await _cleanup([main_t, near, fm])

	# Thistle Darter: Skitter after a dart.
	d = _dummy(p + Vector3(7.0, 0, 0))
	var td := _spawn("thistle_darter", PLAYER, p)
	var sp0 := td.get_stat(&"move_speed")
	td.command_attack(d)
	ok = await _wait_for(func() -> bool: return td.has_modifier(NewUnits12.SKITTER_MOD), 200)
	_check(ok and td.get_stat(&"move_speed") > sp0, "Skitter never sped the darter up")
	await _cleanup([d, td])

	# Vinelasher: Snare Lash roots.
	d = _dummy(p + Vector3(4.0, 0, 0))
	var vl := _spawn("vinelasher", PLAYER, p)
	vl.command_hold()
	ok = await _wait_for(func() -> bool: return d.has_status(&"rooted"), 150)
	if not ok:
		var ab := NewUnits12.ability_of(vl)
		print("  vinelasher casts %d act %s dist %.2f dummy alive %s hp %.0f" % [ab.casts if ab else -1, vl.can_act(),
				Vector2(vl.global_position.x - d.global_position.x, vl.global_position.z - d.global_position.z).length(),
				d.is_alive(), d.hp])
	_check(ok and d.hp <= d.max_hp - 10.0 + 0.01, "Snare Lash did not root (hp lost %.1f)" % (d.max_hp - d.hp))
	await _cleanup([d, vl])

	# Greenheart Oathkeeper: Grove Oath taunts and braces.
	var foe := _spawn("shade", ENEMY, p + Vector3(3.0, 0, 0))
	foe.aggro_range = 0.0
	foe.command_hold()
	var gk := _spawn("greenheart_oathkeeper", PLAYER, p)
	gk.command_hold()
	ok = await _wait_for(func() -> bool: return foe.has_status(&"taunted"), 120)
	_check(ok and foe.taunt_source() == gk and gk.has_status(&"braced"), "Grove Oath: taunted %s braced %s"
			% [foe.has_status(&"taunted"), gk.has_status(&"braced")])
	await _cleanup([foe, gk])


# ---------------------------------------------------------------- bot

func _check_bot() -> void:
	var bot: Node = null
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == ENEMY:
			bot = child
			break
	if bot == null:
		bot = COMMANDER.new()
		bot.team = ENEMY
		main.add_child(bot)
		await _frames(2)
	# The enemy gets a Fire Hall at tier 1 (T2 closed), then tier 2.
	var ek: Node3D = null
	for n in get_nodes_in_group(&"buildings"):
		if n is Keep and int(n.team) == ENEMY:
			ek = n
	var at: Vector3 = (ek.global_position if ek else -main.keep.global_position) + Vector3(0, 0, 0)
	var edir := -Vector3(at.x, 0.0, at.z).normalized()
	var hall: TrainingBuilding = main.build_grid.spawn_complete(BuildingType.find("fire_barracks"), at + edir * 14.0, ENEMY) as TrainingBuilding
	await _frames(2)

	var types := hall.trainable_types()
	var old_mix: PackedFloat32Array = bot.ai.mix_default
	var old_r: PackedFloat32Array = bot.ai.mix_vs_ranged
	var old_m: PackedFloat32Array = bot.ai.mix_vs_melee
	var zero := PackedFloat32Array()
	zero.resize(old_mix.size())
	bot.ai.mix_default = zero
	bot.ai.mix_vs_ranged = zero
	bot.ai.mix_vs_melee = zero
	# The bowman and the T1 unit are over their share: only the gated T2 units sit below theirs.
	var fake: Array[Unit] = []
	for id in ["scorchbow", "scorchling"]:
		for k in 5:
			fake.append(UnitType.find(id).create_unit())
	var old_soldiers: Array[Unit] = bot._soldiers
	var old_barracks: Array[TrainingBuilding] = bot._barracks
	bot._soldiers = fake
	var one: Array[TrainingBuilding] = [hall]
	bot._barracks = one
	var ts := _tiers()
	ts.set_tier(ENEMY, 1)
	var pick_closed: UnitType = bot._pick_soldier(hall)
	# Stronghold reached: now a T2 unit is the pick.
	ts.set_tier(ENEMY, 2)
	var pick_open: UnitType = bot._pick_soldier(hall)
	bot._soldiers = old_soldiers
	bot._barracks = old_barracks
	bot.ai.mix_default = old_mix
	bot.ai.mix_vs_ranged = old_r
	bot.ai.mix_vs_melee = old_m
	for u in fake:
		u.free()
	print("  bot pick closed %s open %s (types %d)" % [pick_closed.id if pick_closed else &"-",
			pick_open.id if pick_open else &"-", types.size()])
	_check(pick_closed != null and NewUnits12.tier_of(pick_closed.id) < 2, "bot picked a gated T2 unit")
	_check(pick_open != null and NewUnits12.tier_of(pick_open.id) == 2, "bot never picks T2 once open")
	_check(NewUnits12.bot_share(&"scorchling") > 0.0 and NewUnits12.bot_share(&"flame_guard") == 0.0, "bot shares")
