extends SceneTree
## 3.G2a: stats pipeline (modifiers, pct, armor, HP gain / clamp) + soldier veterancy (levels.md).
## Run: godot --headless --path . -s tests/test_3_g2a.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "3.g2a"
const FAR := Vector3(300.0, 2.0, 300.0)   # away from everything on the map

var main: Node
var _wait := 0
var _errors: Array[String] = []
var _level_events := 0
var _stats_events := 0


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
	_run()
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.01


func _spawn(type_id: String, team: int, offset: Vector3) -> Unit:
	var u := UnitType.find(type_id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = FAR + offset
	return u


func _run() -> void:
	# ---- modifiers: flat, pct, remove
	var g := _spawn("flame_guard", 0, Vector3.ZERO)
	g.stats_changed.connect(func() -> void: _stats_events += 1)
	var dmg := g.attack_damage
	var cd := g.attack_cooldown
	_check(_near(g.max_hp, 130.0) and _near(g.hp, 130.0), "flame guard base hp %s" % g.max_hp)
	g.add_modifier(&"flat", {"attack_damage": 5})
	_check(_near(g.attack_damage, dmg + 5.0) and _near(g.get_stat(&"attack_damage"), dmg + 5.0), "flat dmg")
	g.add_modifier(&"pct", {"attack_damage_pct": 0.5})
	_check(_near(g.attack_damage, (dmg + 5.0) * 1.5), "pct dmg %s" % g.attack_damage)
	g.remove_modifier(&"flat")
	g.remove_modifier(&"pct")
	_check(_near(g.attack_damage, dmg), "dmg back to base")
	_check(_stats_events >= 4, "stats_changed emitted")
	# ---- max HP: gain heals the gain, loss clamps
	g.add_modifier(&"hp", {"max_hp": 50})
	_check(_near(g.max_hp, 180.0) and _near(g.hp, 180.0), "hp gain heals (%s/%s)" % [g.hp, g.max_hp])
	g.take_damage(100.0, null)
	_check(_near(g.hp, 80.0), "damage after gain")
	g.remove_modifier(&"hp")
	_check(_near(g.max_hp, 130.0) and _near(g.hp, 80.0), "hp loss keeps hp below max")
	g.add_modifier(&"hp", {"max_hp": 50})
	g.heal(1000.0)
	g.remove_modifier(&"hp")
	_check(_near(g.hp, 130.0), "hp loss clamps")
	# ---- attack cooldown floor (40 % of base)
	g.add_modifier(&"fast", {"attack_cooldown_pct": -0.9})
	_check(_near(g.attack_cooldown, cd * 0.4), "cooldown floor")
	g.remove_modifier(&"fast")
	# ---- armor
	g.add_modifier(&"armor", {"armor": 100})
	var before := g.hp
	g.take_damage(20.0, null)
	_check(_near(before - g.hp, 10.0), "armor 100 halves damage (%s)" % (before - g.hp))
	g.remove_modifier(&"armor")
	# ---- statuses: shroud halves damage before the HP check, haste = cooldown x0.7, +1.5 m/s
	var sh := _spawn("flame_guard", 0, Vector3(0.0, 0.0, 15.0))
	var sh_speed := sh.move_speed
	sh.apply_status(&"shroud", 5.0)
	sh.take_damage(200.0, null)   # 100 after shroud: a 130 HP guard survives
	_check(sh.is_alive() and _near(sh.hp, 30.0) and sh.has_status(&"shroud"), "shroud halves (%s)" % sh.hp)
	_check(_near(sh.move_speed, sh_speed + 2.0), "shroud speed")
	sh.apply_status(&"haste", 8.0)
	_check(_near(sh.attack_cooldown, cd * 0.7) and _near(sh.move_speed, sh_speed + 3.5), "haste")
	sh.apply_status(&"haste", 2.0)
	_check(_near(sh.status_time_left(&"haste"), 2.0) and _near(sh.attack_cooldown, cd * 0.7), "refresh, no stack")
	sh.die()
	_check(not sh.has_status(&"haste") and _near(sh.move_speed, sh_speed), "statuses end on death")
	# ---- legacy writes still work
	g.move_speed = 7.0
	_check(_near(g.get_stat(&"move_speed"), 7.0), "legacy move_speed write")

	# ---- veterancy: 120 XP = Veteran, x1.1 HP and damage, healed by the gain
	var v := _spawn("flame_guard", 0, Vector3(0.0, 0.0, 30.0))
	v.level_changed.connect(func(_u: Unit, _l: int) -> void: _level_events += 1)
	var v_dmg := v.attack_damage
	v.add_xp(120)
	_check(v.level == 2 and v.veterancy_name() == "Veteran", "veteran at 120 xp")
	_check(_near(v.max_hp, 143.0) and _near(v.hp, 143.0), "veteran hp %s/%s" % [v.hp, v.max_hp])
	_check(_near(v.attack_damage, v_dmg * 1.1), "veteran dmg")
	_check(_near(v.attack_cooldown, cd), "cooldown unchanged")
	var chev := v.get_node_or_null(^"Chevrons") as Label3D
	_check(chev != null and chev.visible and chev.text == "^", "chevron ^")
	v.add_xp(680)   # 800 total: Elite and Champion, one signal per level
	_check(v.level == 4 and _level_events == 3, "champion, 3 level signals (%d, %d)" % [v.level, _level_events])
	_check(_near(v.max_hp, 169.0), "champion hp %s" % v.max_hp)
	var w := _spawn("cinder_hand", 0, Vector3(0.0, 0.0, 34.0))
	w.add_xp(500)
	_check(w.level == 1 and w.xp == 0, "workers never level")
	var s := _spawn("shade", 1, Vector3(0.0, 0.0, 60.0))
	var shade_ch := s.max_hp
	s.add_xp(800)
	s.add_xp(0)
	_check(_near(s.max_hp, roundf(110.0 * 1.3)) and shade_ch == 110.0, "shade champion 143 hp")

	# ---- kill XP: killer 100 %, soldiers within 8 m 25 %, worker 0, 9 m away 0
	var victim := _spawn("shade", 1, Vector3(0.0, 0.0, 90.0))
	var killer := _spawn("flame_guard", 0, Vector3(1.0, 0.0, 90.0))
	var near := _spawn("flame_guard", 0, Vector3(0.0, 0.0, 95.0))
	var far := _spawn("flame_guard", 0, Vector3(0.0, 0.0, 99.0))
	var worker := _spawn("cinder_hand", 0, Vector3(0.0, 0.0, 92.0))
	victim.take_damage(1000.0, killer)
	_check(killer.xp == 40, "killer xp %d" % killer.xp)
	_check(near.xp == 10, "near xp %d" % near.xp)
	_check(far.xp == 0, "far xp %d" % far.xp)
	_check(worker.xp == 0, "worker xp %d" % worker.xp)
	_check(victim.killer == killer and Unit.kill_xp_value(victim) == 40, "killer / kill_xp_value")
	# A kill by the wizard gives only the 25 % shares.
	var victim2 := _spawn("shade", 1, Vector3(0.0, 0.0, 120.0))
	var guard2 := _spawn("flame_guard", 0, Vector3(3.0, 0.0, 120.0))
	var hero_xp: int = main.hero.xp
	victim2.take_damage(1000.0, main.hero)
	_check(guard2.xp == 10, "wizard kill share %d" % guard2.xp)
	_check(main.hero.level >= 1 and (main.hero.xp == hero_xp or main.hero.has_method(&"xp_to_next")),
			"soldier path never gives the wizard unit xp")
