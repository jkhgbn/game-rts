extends SceneTree
## Task 3.G2b: wizard XP, levels, stat growth, spell points and the learn API (docs/design/levels.md).
## Run: godot --headless --path . -s tests/test_3_g2b.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "3.G2b"
const TIMEOUT_FRAMES := 600

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []


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
	frame += 1
	if frame == 5:
		_run()
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


func _stat(h: Node, stat: StringName) -> float:
	if h.has_method(&"get_stat"):
		return float(h.call(&"get_stat", stat))
	return float(h.get(stat))


func _run() -> void:
	var h = main.hero
	_expect(h.level == 1 and h.xp == 0 and h.spell_points == 0, "starts level 1, 0 XP, 0 points")
	_expect(h.spell_rank(&"fireball") == 1, "Fireball rank 1 at level 1 (got %d)" % h.spell_rank(&"fireball"))
	_expect(h.spell_rank(&"ember_step") == 0, "Ember Step not learned at level 1")
	_expect(h.xp_to_next() == 150, "level 1 bar is 150 (got %d)" % h.xp_to_next())
	_expect(h.can_learn(&"ember_step") == "Needs level 2", "L1 Q1: %s" % h.can_learn(&"ember_step"))
	_expect(h.can_learn(&"fireball") == "Needs level 3", "L1 F2: %s" % h.can_learn(&"fireball"))
	_expect(h.can_learn(&"nope") == "Unknown spell", "unknown spell")
	if h.spell_caster != null:
		_expect(h.command_cast(&"ember_step", h.global_position) == "Not learned",
				"command_cast refuses Not learned: %s" % h.command_cast(&"ember_step", h.global_position))

	# Share rule: a Shade killed by the player's team 10 m away = 40 XP, 30 m away = 10.
	var shade = main.make_unit("shade")
	shade.team = 1
	main.add_child(shade)
	shade.global_position = h.global_position + Vector3(10.0, 0.0, 0.0)
	_expect(h.credit_kill(shade, 0) == 40, "Shade at 10 m gives 40")
	shade.global_position = h.global_position + Vector3(30.0, 0.0, 0.0)
	_expect(h.credit_kill(shade, 0) == 10, "Shade at 30 m gives 10")
	_expect(h.credit_kill(shade, 2) == 0, "a neutral killing blow credits nobody")
	shade.queue_free()
	_expect(h.xp == 50 and h.level == 1, "50 XP after two kills (got %d)" % h.xp)

	# Level 2 exactly at 150 total XP.
	var max_hp_1: float = _stat(h, &"max_hp")
	var dmg_1: float = _stat(h, &"attack_damage")
	var mana_1: float = h.max_mana
	var hp_1: float = h.hp
	var levels_seen: Array = []
	h.level_changed.connect(func(a = null, b = null) -> void: levels_seen.append(b if b != null else a))
	h.add_xp(99)
	_expect(h.level == 1 and h.xp == 149, "149 XP is still level 1")
	h.add_xp(1)
	_expect(h.level == 2 and h.xp == 0, "level 2 at 150 XP (level %d, xp %d)" % [h.level, h.xp])
	_expect(h.spell_points == 1, "1 spell point at level 2")
	_expect(levels_seen == [2], "level_changed(2) once (got %s)" % str(levels_seen))
	_expect(is_equal_approx(_stat(h, &"max_hp"), max_hp_1 + 25.0), "max HP +25 (%s)" % _stat(h, &"max_hp"))
	_expect(is_equal_approx(_stat(h, &"attack_damage"), dmg_1 + 2.0), "damage +2")
	_expect(is_equal_approx(h.max_mana, mana_1 + 10.0), "max mana +10")
	_expect(is_equal_approx(h.hp, minf(hp_1 + 25.0, h.max_hp)), "healed by the gain (%s)" % h.hp)

	# Learning: order of reasons, points.
	_expect(h.can_learn(&"kindle") == "Needs level 4", "L2 E1: %s" % h.can_learn(&"kindle"))
	_expect(h.learn_spell(&"ember_step") == "", "learn Q1 at level 2")
	_expect(h.spell_rank(&"ember_step") == 1 and h.spell_points == 0, "Q rank 1, 0 points")
	h.add_xp(250 + 350)   # level 4
	_expect(h.level == 4 and h.spell_points == 2, "level 4 with 2 points (L%d, %d)" % [h.level, h.spell_points])
	_expect(h.learn_spell(&"fireball") == "", "learn F2 at level 4")
	_expect(h.learn_spell(&"kindle") == "", "learn E1 at level 4")
	_expect(h.learn_spell(&"ember_step") == "No spell points", "Q2 with 0 points: No spell points")

	# Max level: 3 350 total, MAX, per-level rows (Vessa L8 = 525 HP / 28 damage / 170 mana / 5.75 regen).
	h.add_xp(10000)
	_expect(h.level == 8 and h.xp_to_next() == 0, "level 8 and MAX")
	_expect(h.total_xp == 50 + 100 + 600 + 10000, "total XP kept")
	_expect(is_equal_approx(_stat(h, &"max_hp"), max_hp_1 + 175.0), "L8 max HP (%s)" % _stat(h, &"max_hp"))
	_expect(is_equal_approx(h.max_mana, mana_1 + 70.0), "L8 max mana")
	_expect(is_equal_approx(h.mana_regen, 4.0 + 1.75), "L8 regen (%s)" % h.mana_regen)
	_expect(h.spell_points == 4, "7 points total by level 8 (%d left)" % h.spell_points)
	_expect(h.learn_spell(&"kindle") == "", "E2 at level 8")
	_expect(h.can_learn(&"kindle") == "Max rank", "E max rank: %s" % h.can_learn(&"kindle"))

	# Dead: 25 %, and everything survives respawn.
	var home: Vector3 = h.global_position
	h.die()
	var shade2 = main.make_unit("shade")
	shade2.team = 1
	main.add_child(shade2)
	shade2.global_position = home + Vector3(2.0, 0.0, 0.0)
	var before: int = h.total_xp
	h.credit_kill(shade2, 0)
	_expect(h.total_xp == before, "no XP at max level")
	# A dead (fresh, level 1) wizard next to the kill still gets only 25 %.
	var w = load("res://scripts/units/wizard.gd").new()
	w.team = 0
	main.add_child(w)
	w.global_position = home + Vector3(3.0, 0.0, 0.0)
	w.die()
	_expect(w.credit_kill(shade2, 0) == 10 and w.xp == 10, "dead wizard gets 10 for a Shade")
	shade2.queue_free()
	h.respawn(home)
	_expect(h.level == 8 and h.spell_rank(&"kindle") == 2 and h.spell_points == 3, "level, ranks, points survive respawn")
	_expect(is_equal_approx(h.hp, h.max_hp), "respawned at full HP")
	_expect(Engine.get_main_loop() != null, "")
