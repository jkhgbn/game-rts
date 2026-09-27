extends SceneTree
## Task 8.G1 (kingdom-nature.md sections 2-3): the 6 Nature UnitTypes (incl. the Sapling summon) have the
## section 2 numbers; Ysolde (NatureWizard) has the section 3 stats, growth (L6 450 / 23 / 170 / 6.0,
## L8 494 / 27 / 194 / 6.6), her 3 spells and Verdant regen 1.5 %; a Thornling at 20 HP regains 0.7 HP / s
## (balance-2: 1.0 %) after the 4 s delay, full ~71.5 s after it, and none while hit; a Bramblehorn regains
## 7.6 HP / s (2.0 %); Wizard.level_cap stops XP / levels at the cap.
## Run: godot --headless --path . -s tests/test_8_g1.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "8.G1"
const TIMEOUT_FRAMES := 5000
const NATURE_WIZARD := "res://scripts/units/nature_wizard.gd"

## id -> [max_hp, dmg, range, cooldown, speed, aggro, radius, height, cost, pop, train, key, kill_xp,
##        is_worker, idle_regen_pct]
const UNITS := {
	&"sprigling": [45.0, 3.0, 1.4, 1.2, 4.6, 0.0, 0.35, 1.2, 40, 1, 10.0, "Z", 15, true, 1.0],
	&"thornling": [70.0, 8.0, 1.5, 0.9, 5.4, 8.0, 0.4, 1.4, 60, 1, 12.0, "Z", 30, false, 1.0],
	&"burr_slinger": [50.0, 7.0, 8.5, 1.2, 5.0, 10.0, 0.4, 1.5, 70, 1, 14.0, "X", 35, false, 1.0],
	&"bloomtender": [60.0, 5.0, 7.0, 1.5, 4.8, 9.0, 0.45, 1.6, 90, 1, 18.0, "C", 45, false, 1.0],
	&"bramblehorn": [380.0, 18.0, 1.8, 1.2, 4.6, 9.0, 0.7, 2.2, 200, 2, 34.0, "V", 100, false, 2.0],
	&"sapling": [90.0, 9.0, 1.5, 1.0, 4.8, 10.0, 0.4, 1.2, 0, 0, 0.0, "", 0, false, 1.0],
}

var main: Node
var frame := 0
var _wait := 0
var _settle := 0
var _errors: Array[String] = []

var regen_unit: Unit      # damaged once to 20 HP, then left alone
var regen_brute: Unit     # Bramblehorn damaged once to 100 HP, then left alone
var hit_unit: Unit        # damaged to 20 HP, then hit every 2 s
var hit_hp_expected := 20.0
var hit_regen_seen := false


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	if _settle < 60:
		_settle += 1
		return false
	frame += 1
	if frame == 5:
		_check_types()
		_check_ysolde()
		_check_level_cap()
		_setup_regen()
	elif frame > 5:
		_tick_hit_unit()
	# Damage at frame 5; regen starts 4 s later and needs 50 / (70 x 1.0 % x 0.5 s) = 143 ticks = 71.5 s.
	# The 0.5 s tick phase is free, so a check at T s after the damage sees (T - 4) / 0.5 +- 1 ticks.
	if frame == 5 + 60 * 24:   # 20 s of regen: 0.7 HP / s (Thornling), 7.6 HP / s (Bramblehorn)
		_expect(regen_unit.hp > 33.2 and regen_unit.hp < 34.8,
				"thornling at 24 s should be ~34 HP (0.7 HP / s) (hp %.2f)" % regen_unit.hp)
		_expect(regen_brute.is_alive() and regen_brute.hp > 247.0 and regen_brute.hp < 257.0,
				"bramblehorn at 24 s should be ~252 HP (7.6 HP / s) (hp %.2f)" % regen_brute.hp)
	if frame == 5 + 60 * 74:   # 74 s after the damage: still regenerating
		_expect(regen_unit.is_alive(), "regen thornling died (attacked?)")
		_expect(regen_unit.hp > 60.0 and regen_unit.hp < 70.0,
				"thornling at 74 s should be ~69 HP, not full (hp %.2f)" % regen_unit.hp)
	if frame == 5 + 60 * 77:   # 77 s: full
		_expect(is_equal_approx(regen_unit.hp, 70.0), "thornling not full after 4 + 71.5 s (hp %.2f)" % regen_unit.hp)
		_expect(not hit_regen_seen, "thornling regenerated while being hit")
		_expect(is_equal_approx(hit_unit.hp, hit_hp_expected),
				"hit thornling hp %.2f != %.2f (regen while hit?)" % [hit_unit.hp, hit_hp_expected])
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _expect(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)


func _check_types() -> void:
	for id: StringName in UNITS:
		var t := UnitType.find(String(id))
		if t == null:
			_errors.append("UnitType.find(%s) returned null" % id)
			continue
		var v: Array = UNITS[id]
		var got := [t.max_hp, t.attack_damage, t.attack_range, t.attack_cooldown, t.move_speed, t.aggro_range,
				t.radius, t.body_height, t.cost, t.pop, t.train_time, t.card_key, t.kill_xp, t.is_worker,
				t.idle_regen_pct]
		for i in v.size():
			var ok: bool = is_equal_approx(float(got[i]), float(v[i])) if (v[i] is float or v[i] is int) \
					else got[i] == v[i]
			_expect(ok, "%s field %d: %s != %s" % [id, i, str(got[i]), str(v[i])])
		_expect(t.id == id and t.faction == &"nature", "%s: id / faction wrong" % id)
		_expect(t.armor == 0.0, "%s: armor should be 0" % id)
	var bloom := UnitType.find("bloomtender")
	if bloom:
		_expect(bloom.support_kind == &"heal" and is_equal_approx(bloom.support_amount, 12.0)
				and is_equal_approx(bloom.support_interval, 3.0) and is_equal_approx(bloom.support_range, 7.0),
				"bloomtender heal support wrong")
	var sap := UnitType.find("sapling")
	if sap:
		_expect(is_equal_approx(sap.lifetime, 25.0), "sapling lifetime %.1f != 25" % sap.lifetime)
		var s := sap.create_unit()
		_expect(Unit.kill_xp_value(s) == 0, "sapling kill XP != 0")
		s.free()
	for id: StringName in [&"thornling", &"sprigling", &"burr_slinger", &"bloomtender", &"bramblehorn",
			&"sapling"]:
		var t := UnitType.find(String(id))
		if t and t.lifetime > 0.0 and id != &"sapling":
			_errors.append("%s must not have a lifetime" % id)
	var slinger := UnitType.find("burr_slinger")
	if slinger:
		_expect(slinger.projectile_color.is_equal_approx(Color(0.55, 0.40, 0.20)), "burr slinger bolt colour")


func _spawn_ysolde(offset: Vector3) -> Node:
	var script := load(NATURE_WIZARD) as Script
	var y: Node = script.new()
	y.set(&"team", 1)   # ENEMY
	y.set(&"ai_auto_cast", false)
	main.add_child(y)
	y.global_position = main.hero.global_position + offset
	y.call(&"command_stop")
	return y


func _check_ysolde() -> void:
	var y: Node = _spawn_ysolde(Vector3(0, 0, -60))
	_expect(y is Wizard, "NatureWizard is not a Wizard")
	var w := y as Wizard
	_expect(w.unit_name == "Ysolde, Nature Wizard", "name %s" % w.unit_name)
	_expect(w.kingdom == &"nature", "kingdom %s" % w.kingdom)
	_expect(w.is_in_group(&"enemy_heroes") and not w.is_in_group(&"heroes"), "enemy Ysolde groups wrong")
	var want_ids: Array[StringName] = [&"thornburst", &"wild_bloom", &"call_the_thicket"]
	_expect(w.default_spell_ids == want_ids,
			"spell ids %s" % str(w.default_spell_ids))
	_expect(is_equal_approx(w.get_idle_regen_pct(), 1.5), "Verdant regen %.2f != 1.5" % w.get_idle_regen_pct())
	_expect(w.command_fireball(Vector3.ZERO) != "", "Ysolde cast Fireball")
	_expect_stats(w, 1, 340.0, 13.0, 110.0, 4.5)
	_expect(is_equal_approx(w.attack_range, 7.5) and is_equal_approx(w.attack_cooldown, 1.2)
			and is_equal_approx(w.move_speed, 4.8) and is_equal_approx(w.aggro_range, 9.0)
			and is_equal_approx(w.radius, 0.5) and is_equal_approx(w.body_height, 2.0),
			"Ysolde range / cooldown / speed / aggro / size wrong")
	_expect(is_equal_approx(w.mana, 110.0), "starting mana %.1f" % w.mana)
	w.add_xp(Wizard.LEVEL_TOTAL_XP[5])   # -> level 6
	_expect_stats(w, 6, 450.0, 23.0, 170.0, 6.0)
	w.add_xp(Wizard.LEVEL_TOTAL_XP[7] - Wizard.LEVEL_TOTAL_XP[5])   # -> level 8
	_expect_stats(w, 8, 494.0, 27.0, 194.0, 6.6)
	w.queue_free()


func _expect_stats(w: Wizard, lvl: int, hp: float, dmg: float, mana: float, regen: float) -> void:
	_expect(w.level == lvl, "Ysolde level %d != %d" % [w.level, lvl])
	var got := "%.1f / %.1f / %.1f / %.2f" % [w.max_hp, w.get_stat(&"attack_damage"), w.max_mana, w.mana_regen]
	_expect(is_equal_approx(w.max_hp, hp) and is_equal_approx(w.get_stat(&"attack_damage"), dmg)
			and is_equal_approx(w.max_mana, mana) and is_equal_approx(w.mana_regen, regen),
			"Ysolde L%d stats %s (expected %.0f / %.0f / %.0f / %.1f)" % [lvl, got, hp, dmg, mana, regen])


func _check_level_cap() -> void:
	var w := _spawn_ysolde(Vector3(0, 0, -64)) as Wizard
	_expect(w.level_cap == 0 and w.max_level() == Wizard.MAX_LEVEL, "default level_cap must be 0 (none)")
	w.level_cap = 5
	var emitted: Array = []
	w.xp_changed.connect(func(x: int, n: int) -> void: emitted.append([x, n]))
	w.add_xp(100)
	_expect(w.level == 1 and w.xp == 100 and w.xp_to_next() == 150, "cap 5: XP below the cap not normal")
	w.add_xp(10000)
	_expect(w.level == 5, "cap 5: level %d after 10 000 XP" % w.level)
	_expect(w.xp == 0 and w.xp_to_next() == 0, "cap 5: xp %d / %d at the cap (expected 0 / 0)" % [w.xp, w.xp_to_next()])
	_expect(w.spell_points == 4, "cap 5: %d spell points (expected 4)" % w.spell_points)
	var n := emitted.size()
	w.add_xp(500)
	_expect(w.level == 5 and w.xp == 0 and emitted.size() == n, "cap 5: XP still gained at the cap")
	w.level_cap = 0   # lifted: levels resume
	w.add_xp(Wizard.LEVEL_TOTAL_XP[7])
	_expect(w.level == 8 and w.xp_to_next() == 0, "cap lifted: level %d (expected 8)" % w.level)
	# Setting a cap below the current XP bar zeroes it.
	var w2 := _spawn_ysolde(Vector3(0, 0, -68)) as Wizard
	w2.add_xp(Wizard.LEVEL_TOTAL_XP[2] + 50)   # level 3 + 50
	w2.level_cap = 3
	_expect(w2.level == 3 and w2.xp == 0 and w2.xp_to_next() == 0, "cap set at the current level: xp %d" % w2.xp)
	w.queue_free()
	w2.queue_free()


func _setup_regen() -> void:
	var t := UnitType.find("thornling")
	regen_unit = t.create_unit()
	regen_unit.team = 0
	main.add_child(regen_unit)
	regen_unit.global_position = main.hero.global_position + Vector3(3, 0, 2)
	regen_unit.command_hold()
	regen_unit.take_damage(50.0)
	_expect(is_equal_approx(regen_unit.hp, 20.0), "thornling hp %.2f after 50 damage" % regen_unit.hp)
	hit_unit = t.create_unit()
	hit_unit.team = 0
	main.add_child(hit_unit)
	hit_unit.global_position = main.hero.global_position + Vector3(-3, 0, 2)
	hit_unit.command_hold()
	hit_unit.take_damage(50.0)
	regen_brute = UnitType.find("bramblehorn").create_unit()
	regen_brute.team = 0
	main.add_child(regen_brute)
	regen_brute.global_position = main.hero.global_position + Vector3(0, 0, 6)
	regen_brute.command_hold()
	regen_brute.take_damage(280.0)
	_expect(is_equal_approx(regen_brute.hp, 100.0), "bramblehorn hp %.2f after 280 damage" % regen_brute.hp)


func _tick_hit_unit() -> void:
	if hit_unit == null or not hit_unit.is_alive():
		return
	if hit_unit.hp > hit_hp_expected + 0.001:
		hit_regen_seen = true
	if (frame - 5) % 120 == 0:   # every 2 s: below the 4 s delay
		hit_unit.take_damage(0.25)
		hit_hp_expected = hit_unit.hp
