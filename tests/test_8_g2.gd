extends SceneTree
## Task 8.G2: Ysolde's spells (kingdom-nature.md 3.1-3.3). Builds its own SpellCaster on spawned wizards.
## - Rank tables 3.2 exact (SpellType data), mana never changes with rank, slot order F / Q / E.
## - Thornburst ranks 1-3: 40 / 50 / 62 damage, rooted 1.5 / 2 / 2.5 s (Vessa 0.75 s at rank 1), cooldown
##   5 / 5 / 4; outside the circle untouched; a rooted unit can't move but still attacks.
## - Wild Bloom: rank 1 heals 60 over 5 s (30 at 2.75 s), rank 2 90 over 6 s, rank 3 120 over 6 s; only
##   friends inside at cast (workers yes, enemies / summons / outside no).
## - Call the Thicket: 3 Saplings (rank 2: 5) of the caster's team, pop 0, lifetime 25 s (rank 2: 30),
##   alive at 24.8 s, withered at 25.2 s; after the 0.5 s grow they attack-move to an enemy within 10 m;
##   a Sapling killed by an enemy wizard gives it 0 XP and its team 0 essence.
## - suggest_cast follows 3.3 (Bloom: hurt group / self < 45 % / retreat < 35 %; Thicket with 4 enemies
##   within 12 m at 3 m from the nearest; Thornburst on a 2+ cluster, else the enemy wizard).
## Run:  godot --headless --path . -s tests/test_8_g2.gd --fixed-fps 60 --quit-after 5000

const TASK_ID := "8.G2"
const TIMEOUT_FRAMES := 3600
const NATURE: Array[StringName] = [&"thornburst", &"wild_bloom", &"call_the_thicket"]
const T0 := Vector3(-20.0, 0.0, 20.0)
const A0 := Vector3(20.0, 0.0, 20.0)

var main: Node
var frame := 0
var _wait := 0
var errors: Array[String] = []
var notes: Array[String] = []
var done := false
var step := 0
var step_frame := 0

var ys      # Wizard (Ysolde's spells)
var yc      # SpellCaster
var vessa   # enemy Wizard
var hp0: Dictionary = {}
var tb_in: Array = []
var tb_out
var biter    # rooted shade that keeps attacking
var bitten   # the guard it attacks
var wb: Array = []          # [guard, worker, enemy, outside, sapling]
var wb23: Array = []        # [guard rank 2, guard rank 3]
var saplings: Array = []
var saplings_r2: Array = []
var thicket_point := Vector3.ZERO
var thicket_frame := 0
var bloom23_frame := 0
var effects: Dictionary = {}


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
	_step()
	if not errors.is_empty():
		print("FAIL %s: %s (step %d)" % [TASK_ID, " | ".join(errors), step])
		return true
	if done:
		for s in notes:
			print("NOTE %s" % s)
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out in step %d" % [TASK_ID, step])
		return true
	return false


func _check(ok: bool, msg: String) -> void:
	if not ok:
		errors.append(msg)


func _near(a: float, b: float, msg: String, tol: float = 0.01) -> void:
	_check(absf(a - b) <= tol, "%s: got %.3f, want %.3f" % [msg, a, b])


func _spawn(type_id: String, team: int, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team
	u.attack_damage = 0.0
	u.aggro_range = 0.0
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	return u


func _make_wizard(team: int, pos: Vector3, ids: Array[StringName]) -> Array:
	var w := Wizard.new()
	w.team = team
	w.attack_damage = 0.0
	w.aggro_range = 0.0
	main.add_child(w)
	w.global_position = pos
	w.command_stop()
	var c = w.get_node_or_null(^"SpellCaster")
	if c == null:
		c = load("res://scripts/spells/spell_caster.gd").new()
		c.name = "SpellCaster"
		w.add_child(c)
	c.setup(w, ids)
	return [w, c]


func _next() -> void:
	step += 1
	step_frame = frame


func _elapsed() -> int:
	return frame - step_frame


func _ready_caster(id: StringName, rank: int) -> void:
	yc.reset()
	yc.set_rank(id, rank)
	ys.mana = 100.0


func _step() -> void:
	match step:
		0:
			_setup()
			_next()
		1:   # 0.5 s: everything rooted, the rooted shade can't move but still acts
			if _elapsed() < 30:
				return
			for u in tb_in:
				_check(u.has_status(&"rooted"), "shade rooted at 0.5 s")
				_check(not u.can_move(), "rooted shade can move")
				_check(u.can_act(), "rooted shade can't act")
			_check(vessa.has_status(&"rooted"), "Vessa rooted at 0.5 s")
			_next()
		2:   # 1.0 s: Vessa free (0.75 s), shades still rooted, the rooted biter hurt the guard
			if _elapsed() < 30:
				return
			_check(not vessa.has_status(&"rooted"), "Vessa still rooted at 1.0 s (want 0.75 s)")
			for u in tb_in:
				_check(u.has_status(&"rooted"), "shade freed before 1.5 s")
			_check(biter.has_status(&"rooted"), "biter still rooted")
			_check(bitten.hp < hp0[bitten], "a rooted unit must still attack (guard hp %.1f)" % bitten.hp)
			_next()
		3:   # 1.75 s: the root is over; ranks 2 / 3; the bloom's half-way point comes at 2.75 s
			if _elapsed() < 45:
				return
			for u in tb_in:
				_check(not u.has_status(&"rooted"), "shade rooted past 1.5 s")
			biter.die()
			_thornburst_rank(2, T0 + Vector3(4.0, 0.0, 8.0))
			_thornburst_rank(3, T0 + Vector3(-4.0, 0.0, 8.0))
			_next()
		4:   # 2.75 s after the bloom: 5 ticks = 30
			if frame < 1 + 165:
				return
			_near(wb[0].hp - hp0[wb[0]], 30.0, "wild bloom rank 1 at 2.75 s")
			_next()
		5:   # 5.25 s: 60, and no more after
			if frame < 1 + 315:
				return
			_near(wb[0].hp - hp0[wb[0]], 60.0, "wild bloom rank 1 heals 60 over 5 s")
			_near(wb[1].hp - hp0[wb[1]], minf(60.0, wb[1].max_hp - hp0[wb[1]]), "worker healed")
			_near(wb[2].hp - hp0[wb[2]], 0.0, "enemy not healed")
			_near(wb[3].hp - hp0[wb[3]], 0.0, "friend outside not healed")
			_check(int(effects.get(&"wild_bloom_heal", 0)) >= 20, "wild_bloom_heal effects: %d" % int(effects.get(&"wild_bloom_heal", 0)))
			_bloom_ranks_2_3()
			_thicket()
			_next()
		6:   # 0.6 s after the thicket: the grow is over, they go for the enemy within 10 m
			if frame - thicket_frame < 36:
				return
			for s in saplings:
				_check(s.is_attack_moving() or s.attack_target != null, "sapling should attack-move after growing")
			_kill_one_sapling()
			_next()
		7:   # 3.25 s after bloom ranks 2 / 3: 6 ticks = 45 / 60
			if frame - bloom23_frame < 195:
				return
			_near(wb23[0].hp - hp0[wb23[0]], 45.0, "wild bloom rank 2 at 3.25 s")
			_near(wb23[1].hp - hp0[wb23[1]], 60.0, "wild bloom rank 3 at 3.25 s")
			_next()
		8:
			if frame - bloom23_frame < 375:
				return
			_near(wb23[0].hp - hp0[wb23[0]], 90.0, "wild bloom rank 2 heals 90 over 6 s")
			_near(wb23[1].hp - hp0[wb23[1]], 120.0, "wild bloom rank 3 heals 120 over 6 s")
			_next()
		9:   # 24.8 s: the survivors still stand
			if frame - thicket_frame < 1488:
				return
			var alive := 0
			for s in saplings:
				if is_instance_valid(s) and s.is_alive():
					alive += 1
			_check(alive == 2, "2 saplings alive at 24.8 s, got %d" % alive)
			_next()
		10:  # 25.2 s: withered
			if frame - thicket_frame < 1512:
				return
			for s in saplings:
				_check(not (is_instance_valid(s) and s.is_alive()), "sapling alive past 25 s")
			_ai_checks()
			done = true


func _setup() -> void:
	var tb := SpellType.find(&"thornburst")
	var bl := SpellType.find(&"wild_bloom")
	var th := SpellType.find(&"call_the_thicket")
	_check(tb != null and bl != null and th != null, "missing Nature SpellType")
	if not errors.is_empty():
		return
	for r in [1, 2, 3]:
		_near(tb.damage_at(r), [40.0, 50.0, 62.0][r - 1], "tb damage r%d" % r)
		_near(tb.radius_at(r), [3.0, 3.25, 3.5][r - 1], "tb radius r%d" % r)
		_near(tb.duration_at(r), [1.5, 2.0, 2.5][r - 1], "tb root r%d" % r)
		_near(tb.cooldown_at(r), [5.0, 5.0, 4.0][r - 1], "tb cd r%d" % r)
		_near(tb.range_at(r), 14.0, "tb range r%d" % r)
		_near(bl.heal_at(r), [60.0, 90.0, 120.0][r - 1], "wb heal r%d" % r)
		_near(bl.duration_at(r), [5.0, 6.0, 6.0][r - 1], "wb duration r%d" % r)
		_near(bl.radius_at(r), [5.0, 5.5, 6.0][r - 1], "wb radius r%d" % r)
		_near(bl.cooldown_at(r), [16.0, 16.0, 14.0][r - 1], "wb cd r%d" % r)
		_near(bl.range_at(r), 12.0, "wb range r%d" % r)
	for r in [1, 2]:
		_check(th.summon_count_at(r) == [3, 5][r - 1], "ct count r%d" % r)
		_near(th.duration_at(r), [25.0, 30.0][r - 1], "ct lifetime r%d" % r)
		_near(th.cooldown_at(r), [45.0, 40.0][r - 1], "ct cd r%d" % r)
		_near(th.range_at(r), 10.0, "ct range r%d" % r)
		_near(th.radius_at(r), 1.2, "ct ring r%d" % r)
	_near(tb.mana_cost, 35.0, "tb mana"); _near(bl.mana_cost, 50.0, "wb mana"); _near(th.mana_cost, 60.0, "ct mana")
	_near(bl.tick_interval, 0.5, "wb tick 0.5 s")
	_check(tb.status_id == &"rooted", "thornburst roots")
	_check(tb.max_rank == 3 and bl.max_rank == 3 and th.max_rank == 2, "max ranks 3 / 3 / 2")
	_check(tb.level_required == [1, 3, 5] and bl.level_required == [2, 4, 6] and th.level_required == [4, 7],
			"level requirements F 1/3/5, Q 2/4/6, E 4/7")
	_check(tb.target_type == SpellType.TargetType.POINT and bl.target_type == SpellType.TargetType.AREA
			and th.target_type == SpellType.TargetType.POINT, "target types")
	_check(tb.icon_abbrev == "TB" and bl.icon_abbrev == "WB" and th.icon_abbrev == "CT", "icons")

	var r: Array = _make_wizard(Unit.Team.PLAYER, T0, NATURE)
	ys = r[0]
	yc = r[1]
	yc.spell_effect.connect(_on_effect)
	_check(yc.spell_ids() == NATURE, "slot order F / Q / E")
	_check(yc.rank_of(&"thornburst") == 1 and yc.rank_of(&"wild_bloom") == 0 and yc.rank_of(&"call_the_thicket") == 0,
			"start ranks")
	_check(yc.cast(&"wild_bloom", T0) == "Not learned", "wild bloom not learned")
	ys.mana = 10.0
	_check(yc.cast(&"thornburst", T0 + Vector3(4.0, 0.0, 0.0)) == "Not enough mana", "not enough mana")

	# Thornburst rank 1 at C: 2 shades + Vessa inside, one shade outside, a rooted biter next to a guard.
	var c := T0 + Vector3(6.0, 0.0, 0.0)
	tb_in = [_spawn("shade", Unit.Team.ENEMY, c), _spawn("shade", Unit.Team.ENEMY, c + Vector3(1.2, 0.0, 0.0))]
	var e := SpellCaster.edge_radius(tb_in[0])
	tb_in.append(_spawn("shade", Unit.Team.ENEMY, c + Vector3(0.0, 0.0, -(3.0 + e - 0.1))))
	tb_out = _spawn("shade", Unit.Team.ENEMY, c + Vector3(0.0, 0.0, -(3.0 + e + 0.4)))
	vessa = _make_wizard(Unit.Team.ENEMY, c + Vector3(-1.2, 0.0, 0.0), [] as Array[StringName])[0]
	biter = _spawn("shade", Unit.Team.ENEMY, c + Vector3(0.0, 0.0, 1.5))
	biter.attack_damage = 10.0
	bitten = _spawn("flame_guard", Unit.Team.PLAYER, c + Vector3(0.0, 0.0, 2.5))
	biter.command_attack(bitten)
	for u in tb_in + [tb_out, vessa, biter, bitten]:
		hp0[u] = u.hp
	_ready_caster(&"thornburst", 1)
	_check(yc.cast(&"thornburst", c) == "", "thornburst refused")
	_check(not yc.has_pending(), "thornburst in range should cast at once")
	_near(ys.mana, 65.0, "thornburst mana 35")
	_near(yc.cooldown_left(&"thornburst"), 5.0, "thornburst cooldown r1")
	_check(yc.cast(&"thornburst", c) == "On cooldown", "thornburst on cooldown")
	for u in tb_in + [vessa, biter]:
		_near(hp0[u] - u.hp, 40.0, "thornburst r1 damage")
	for u in tb_in:
		_near(u.status_time_left(&"rooted"), 1.5, "thornburst r1 root")
	_near(vessa.status_time_left(&"rooted"), 0.75, "Vessa rooted half (0.75 s)")
	_near(hp0[tb_out] - tb_out.hp, 0.0, "thornburst outside untouched")
	_check(not tb_out.has_status(&"rooted"), "outside shade rooted")
	_near(hp0[bitten] - bitten.hp, 0.0, "thornburst hurts no friend")
	hp0[bitten] = bitten.hp

	# Wild Bloom rank 1 at B (8 m from Ysolde, so she is outside).
	var b := T0 + Vector3(0.0, 0.0, -8.0)
	var guard := _spawn("flame_guard", Unit.Team.PLAYER, b)
	var worker := _spawn("cinder_hand", Unit.Team.PLAYER, b + Vector3(1.5, 0.0, 0.0))
	var foe := _spawn("shade", Unit.Team.ENEMY, b + Vector3(0.0, 0.0, 1.5))
	var eg := SpellCaster.edge_radius(guard)
	var outside := _spawn("flame_guard", Unit.Team.PLAYER, b + Vector3(0.0, 0.0, -(5.0 + eg + 0.5)))
	var sap: Unit = SpellCaster.summon_type(&"sapling").create_unit()
	sap.team = Unit.Team.PLAYER
	main.add_child(sap)
	sap.global_position = b + Vector3(-1.5, 0.0, 0.0)
	sap.command_hold()
	guard.hp = guard.max_hp - 80.0
	worker.hp = 1.0
	foe.hp = 50.0
	outside.hp = 50.0
	wb = [guard, worker, foe, outside, sap]
	for u in wb:
		hp0[u] = u.hp
	_ready_caster(&"wild_bloom", 1)
	_check(yc.cast(&"wild_bloom", b) == "", "wild bloom refused")
	_near(ys.mana, 50.0, "wild bloom mana 50")
	_near(yc.cooldown_left(&"wild_bloom"), 16.0, "wild bloom cooldown r1")
	var hot = main.get_node_or_null(^"WildBloom")
	_check(hot != null, "no WildBloom heal node")
	if hot:
		_check(hot.targets.has(guard) and hot.targets.has(worker), "bloom targets the guard and the worker")
		_check(not hot.targets.has(sap), "bloom must skip Saplings")
		_check(not hot.targets.has(foe) and not hot.targets.has(outside) and not hot.targets.has(ys),
				"bloom targets only friends inside")
		_near(hot.per_tick, 6.0, "6 every 0.5 s")
	sap.queue_free()


func _thornburst_rank(rank: int, c: Vector3) -> void:
	var u := _spawn("shade", Unit.Team.ENEMY, c)
	hp0[u] = u.hp
	_ready_caster(&"thornburst", rank)
	_check(yc.cast(&"thornburst", c) == "", "thornburst rank %d refused" % rank)
	_near(yc.cooldown_left(&"thornburst"), [5.0, 5.0, 4.0][rank - 1], "thornburst cooldown r%d" % rank)
	_near(hp0[u] - u.hp, [40.0, 50.0, 62.0][rank - 1], "thornburst damage r%d" % rank)
	_near(u.status_time_left(&"rooted"), [1.5, 2.0, 2.5][rank - 1], "thornburst root r%d" % rank)


func _bloom_ranks_2_3() -> void:
	bloom23_frame = frame
	wb23 = []
	for rank in [2, 3]:
		var p := T0 + Vector3(-8.0 + (rank - 2) * 16.0, 0.0, -4.0)
		var g := _spawn("flame_guard", Unit.Team.PLAYER, p)
		g.max_hp = 200.0   # room for the 120 heal (Flame Guard max_hp is 120 since the 2026-10-06 balance pass)
		g.hp = 1.0
		hp0[g] = g.hp
		wb23.append(g)
		_ready_caster(&"wild_bloom", rank)
		_check(yc.cast(&"wild_bloom", p) == "", "wild bloom rank %d refused" % rank)
		_near(yc.cooldown_left(&"wild_bloom"), [16.0, 16.0, 14.0][rank - 1], "wild bloom cooldown r%d" % rank)


func _thicket() -> void:
	var eco = Economy.for_team(Unit.Team.PLAYER)
	var pop_before: int = eco.pop_used if eco else 0
	thicket_point = T0 + Vector3(0.0, 0.0, 9.0)
	var target := _spawn("shade", Unit.Team.ENEMY, thicket_point + Vector3(6.0, 0.0, 0.0))
	target.max_hp = 100000.0
	target.hp = 100000.0
	var got: Array = []
	var grab := func(_id: StringName, units: Array) -> void: got.append_array(units)
	yc.summoned.connect(grab)
	_ready_caster(&"call_the_thicket", 1)
	_check(yc.cast(&"call_the_thicket", thicket_point) == "", "call the thicket refused")
	thicket_frame = frame
	_near(ys.mana, 40.0, "call the thicket mana 60")
	_near(yc.cooldown_left(&"call_the_thicket"), 45.0, "call the thicket cooldown r1")
	saplings = got.duplicate()
	_check(saplings.size() == 3, "3 saplings, got %d" % saplings.size())
	for s in saplings:
		_check(s is Unit and s.team == Unit.Team.PLAYER, "sapling of the caster's team")
		_check(s.unit_type != null and s.unit_type.pop == 0, "sapling pop 0")
		_near(s.lifetime_total(), 25.0, "sapling lifetime r1")
		_check(s.is_holding(), "sapling holds while growing")
		_check(Vector2(s.global_position.x - thicket_point.x, s.global_position.z - thicket_point.z).length() < 1.6,
				"sapling on the ring")
		_check(Unit.kill_xp_value(s) == 0, "sapling worth 0 XP")
	if eco:
		_check(eco.pop_used == pop_before, "saplings cost pop: %d -> %d" % [pop_before, eco.pop_used])
	else:
		notes.append("no Economy in main.tscn: pop not checked")
	_check(int(effects.get(&"call_the_thicket_sprout", 0)) == 3, "3 sprout effects")
	# Rank 2: 5 Saplings for 30 s, then cleared so they don't disturb the rest.
	got.clear()
	_ready_caster(&"call_the_thicket", 2)
	_check(yc.cast(&"call_the_thicket", T0 + Vector3(-9.0, 0.0, 0.0)) == "", "call the thicket r2 refused")
	_near(yc.cooldown_left(&"call_the_thicket"), 40.0, "call the thicket cooldown r2")
	saplings_r2 = got.duplicate()
	_check(saplings_r2.size() == 5, "5 saplings at rank 2, got %d" % saplings_r2.size())
	for s in saplings_r2:
		_near(s.lifetime_total(), 30.0, "sapling lifetime r2")
		s.die()
	yc.summoned.disconnect(grab)


func _kill_one_sapling() -> void:
	var s: Unit = saplings[0]
	var bank = EssenceBank.for_team(Unit.Team.ENEMY)
	var ess0: int = int(bank.essence) if bank else 0
	var xp0: int = vessa.xp
	var lvl0: int = vessa.level
	s.take_damage(100000.0, vessa)
	_check(not s.is_alive(), "sapling should die")
	_check(vessa.xp == xp0 and vessa.level == lvl0, "sapling kill gave XP: %d -> %d" % [xp0, vessa.xp])
	if bank:
		_check(int(bank.essence) == ess0, "sapling kill gave essence: %d -> %d" % [ess0, int(bank.essence)])
	else:
		notes.append("no EssenceBank in main.tscn: essence checked through kill_xp 0 only")


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _on_effect(id: StringName, _pos: Vector3) -> void:
	effects[id] = int(effects.get(id, 0)) + 1


func _ai_checks() -> void:
	var r: Array = _make_wizard(Unit.Team.PLAYER, A0, NATURE)
	var w = r[0]
	var c = r[1]
	for id in NATURE:
		c.set_rank(id, 1)
	w.mana = 100.0
	_check(c.suggest_cast().is_empty(), "nothing to do with no one around: %s" % [c.suggest_cast()])
	# Rule 1: self under 45 %, retreat under 35 %.
	w.hp = w.max_hp * 0.4
	var s: Dictionary = c.suggest_cast()
	_check(s.get("spell_id") == &"wild_bloom" and s.get("target") is Vector3
			and (s["target"] as Vector3).distance_to(w.global_position) < 0.01 and not s.get("retreat"),
			"bloom on herself under 45 %%: %s" % [s])
	w.hp = w.max_hp * 0.3
	s = c.suggest_cast()
	_check(s.get("spell_id") == &"wild_bloom" and s.get("retreat"), "bloom + retreat under 35 %%: %s" % [s])
	w.hp = w.max_hp
	# Rule 1: 3 hurt soldiers within 5 m of one of them.
	var guards: Array = []
	for i in 3:
		var g := _spawn("flame_guard", Unit.Team.PLAYER, A0 + Vector3(-6.0, 0.0, -1.5 + i * 1.5))
		g.hp = g.max_hp * 0.5
		guards.append(g)
	s = c.suggest_cast()
	_check(s.get("spell_id") == &"wild_bloom" and s.get("target") is Vector3
			and (s["target"] as Vector3).distance_to(guards[1].global_position) < 3.1, "bloom on the hurt group: %s" % [s])
	guards[0].hp = guards[0].max_hp
	s = c.suggest_cast()
	_check(s.is_empty(), "2 hurt soldiers are not enough: %s" % [s])
	for g in guards:
		g.die()
	# Rule 2: 4 enemies within 12 m -> 3 m from the nearest toward her.
	var foes: Array = []
	for i in 4:
		foes.append(_spawn("shade", Unit.Team.ENEMY, A0 + Vector3(7.0 + i * 1.0, 0.0, 0.0)))
	s = c.suggest_cast()
	_check(s.get("spell_id") == &"call_the_thicket" and s.get("target") is Vector3
			and _flat_dist(s["target"], foes[0].global_position + Vector3(-3.0, 0.0, 0.0)) < 0.2,
			"thicket 3 m before the nearest: %s" % [s])
	# Rule 3: 3 enemies -> no thicket; Thornburst on the cluster.
	foes[3].die()
	s = c.suggest_cast()
	_check(s.get("spell_id") == &"thornburst" and s.get("target") is Vector3
			and (s["target"] as Vector3).distance_to(foes[1].global_position) < 1.1, "thornburst on the cluster: %s" % [s])
	# Rule 3 fallback: lone enemies -> the enemy wizard in range.
	for i in 3:
		foes[i].die()
	var lone := _spawn("shade", Unit.Team.ENEMY, A0 + Vector3(5.0, 0.0, 0.0))
	var foe_wiz = _make_wizard(Unit.Team.ENEMY, A0 + Vector3(-5.0, 0.0, 8.0), [] as Array[StringName])[0]
	s = c.suggest_cast()
	_check(s.get("spell_id") == &"thornburst" and s.get("target") is Vector3
			and (s["target"] as Vector3).distance_to(foe_wiz.global_position) < 0.01, "thornburst on the enemy wizard: %s" % [s])
	foe_wiz.global_position = A0 + Vector3(-5.0, 0.0, 16.0)
	s = c.suggest_cast()
	_check(s.is_empty(), "no cluster, wizard out of range -> nothing: %s" % [s])
	lone.die()
	w.mana = 10.0
	w.hp = w.max_hp * 0.3
	_check(c.suggest_cast().is_empty(), "no suggestion without mana")
