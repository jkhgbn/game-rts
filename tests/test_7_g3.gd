extends SceneTree
## Task 7.G3: Torvald's spells (kingdom-ice.md 4.1-4.3). Builds its own SpellCaster on spawned wizards.
## - Rank tables 4.2 exact (SpellType data), mana never changes with rank, slot order F / Q / E.
## - Refusals: Dead, Unknown spell, Not learned, On cooldown, Not enough mana, Invalid target.
## - Rime Bolt ranks 1-3: 45 / 58 / 72 damage, chill 3 / 4 / 5 s, cooldown 6 / 5.5 / 5.
## - Flash Freeze ranks 1-3: 20 / 30 / 40 damage in r 3 / 3.25 / 3.5, frozen 1.5 / 2 / 2.5 s (half on a
##   wizard: Malrik 0.75 s), then chill 3 s once thawed; cooldown 20 / 18 / 16; outside the circle untouched.
## - Rime Aegis ranks 1-2: shield 80 / 120 for 8 s within 8 / 10 m (Torvald + soldiers, no workers).
## - suggest_cast follows 4.3 (Aegis on HP < 50 % or 4 soldiers + 3 enemies; Freeze cluster with the
##   wizard tie-break; Bolt: wizard not chilled, then highest cost, then nearest).
## chill / frozen checks run only when unit.gd knows those statuses (7.G1); else they print SKIP.
## Run:  godot --headless --path . -s tests/test_7_g3.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "7.G3"
const TIMEOUT_FRAMES := 2400
const ICE: Array[StringName] = [&"rime_bolt", &"flash_freeze", &"rime_aegis"]
const T0 := Vector3(-20.0, 0.0, 20.0)
const A0 := Vector3(20.0, 0.0, 20.0)

var main: Node
var frame := 0
var _wait := 0
var errors: Array[String] = []
var skips: Array[String] = []
var done := false
var step := 0
var step_frame := 0

var torv   # Wizard
var tc     # SpellCaster
var chill_known := false
var frozen_known := false
var bolt_targets: Array = []
var chill_at_hit: Dictionary = {}
var hp0: Dictionary = {}
var ff: Array = []          # [rank, inside units, outside unit, malrik or null]
var ff_rank := 1
var malrik


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
		for s in skips:
			print("SKIP %s" % s)
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


func _probe_status(id: StringName) -> bool:
	var p := _spawn("shade", Unit.Team.ENEMY, Vector3(-40.0, 0.0, -10.0))
	p.apply_status(id, 1.0)
	var ok := p.has_status(id)
	p.queue_free()
	return ok


func _ready_caster(rank_id: StringName, rank: int) -> void:
	tc.reset()
	tc.set_rank(rank_id, rank)
	torv.mana = 100.0


func _step() -> void:
	match step:
		0:
			_setup()
			_next()
		1:   # the three bolts landed
			if _elapsed() < 45:
				return
			var want_dmg := [45.0, 58.0, 72.0]
			var want_chill := [3.0, 4.0, 5.0]
			for i in 3:
				var u: Unit = bolt_targets[i]
				_near(hp0[u] - u.hp, want_dmg[i], "rime bolt rank %d damage" % (i + 1))
				_check(chill_at_hit.has(u), "rime bolt rank %d never hit" % (i + 1))
				if chill_known:
					_near(float(chill_at_hit.get(u, 0.0)), want_chill[i], "rime bolt rank %d chill" % (i + 1))
			_start_freeze(1, T0 + Vector3(0.0, 0.0, -8.0), true)
			_next()
		2:   # rank 1: after 0.5 s Malrik (0.75 s) and the shades (1.5 s) are still frozen, no chill yet
			if _elapsed() < 30:
				return
			if frozen_known:
				for u in ff[1]:
					_check(u.has_status(&"frozen"), "shade frozen at 0.5 s")
					_check(not u.has_status(&"chill"), "no chill while frozen")
					_check(not u.can_act() if u.has_method(&"can_act") else true, "frozen shade can act")
				_check(malrik.has_status(&"frozen"), "Malrik frozen at 0.5 s")
			_next()
		3:   # 1.0 s: Malrik thawed (0.75 s) and chilled
			if _elapsed() < 30:
				return
			if frozen_known:
				_check(not malrik.has_status(&"frozen"), "Malrik still frozen at 1.0 s (want 0.75 s)")
				for u in ff[1]:
					_check(u.has_status(&"frozen"), "shade thawed before 1.5 s")
			if chill_known and frozen_known:
				_check(malrik.has_status(&"chill"), "Malrik chilled after thawing")
			_next()
		4:   # 1.75 s: shades thawed at 1.5 s, chill ~2.75 s left
			if _elapsed() < 45:
				return
			if frozen_known:
				for u in ff[1]:
					_check(not u.has_status(&"frozen"), "shade frozen past 1.5 s")
			if chill_known:
				for u in ff[1]:
					_near(u.status_time_left(&"chill"), 2.75, "chill 3 s after the freeze", 0.1)
			_start_freeze(2, T0 + Vector3(8.0, 0.0, -6.0), false)
			_next()
		5:
			if _elapsed() < 2:
				return
			_start_freeze(3, T0 + Vector3(-8.0, 0.0, 6.0), false)
			_next()
		6:
			if _elapsed() < 2:
				return
			_aegis_checks()
			_ai_checks()
			done = true


func _setup() -> void:
	chill_known = _probe_status(&"chill")
	frozen_known = _probe_status(&"frozen")
	if not chill_known:
		skips.append("chill checks: unit.gd has no chill status yet (7.G1)")
	if not frozen_known:
		skips.append("frozen checks: unit.gd has no frozen status yet (7.G1)")

	# Data (kingdom-ice.md 4.1 / 4.2).
	var rb := SpellType.find(&"rime_bolt")
	var fz := SpellType.find(&"flash_freeze")
	var ra := SpellType.find(&"rime_aegis")
	_check(rb != null and fz != null and ra != null, "missing Ice SpellType")
	if not errors.is_empty():
		return
	for r in [1, 2, 3]:
		_near(rb.damage_at(r), [45.0, 58.0, 72.0][r - 1], "rb damage r%d" % r)
		_near(rb.duration_at(r), [3.0, 4.0, 5.0][r - 1], "rb chill r%d" % r)
		_near(rb.cooldown_at(r), [6.0, 5.5, 5.0][r - 1], "rb cd r%d" % r)
		_near(rb.range_at(r), 13.0, "rb range r%d" % r)
		_near(fz.radius_at(r), [3.0, 3.25, 3.5][r - 1], "ff radius r%d" % r)
		_near(fz.damage_at(r), [20.0, 30.0, 40.0][r - 1], "ff damage r%d" % r)
		_near(fz.duration_at(r), [1.5, 2.0, 2.5][r - 1], "ff frozen r%d" % r)
		_near(fz.cooldown_at(r), [20.0, 18.0, 16.0][r - 1], "ff cd r%d" % r)
		_near(fz.range_at(r), 12.0, "ff range r%d" % r)
	for r in [1, 2]:
		_near(ra.shield_at(r), [80.0, 120.0][r - 1], "ra shield r%d" % r)
		_near(ra.duration_at(r), 8.0, "ra duration r%d" % r)
		_near(ra.radius_at(r), [8.0, 10.0][r - 1], "ra radius r%d" % r)
		_near(ra.cooldown_at(r), [40.0, 35.0][r - 1], "ra cd r%d" % r)
	_near(rb.mana_cost, 35.0, "rb mana"); _near(fz.mana_cost, 50.0, "ff mana"); _near(ra.mana_cost, 60.0, "ra mana")
	_check(rb.max_rank == 3 and fz.max_rank == 3 and ra.max_rank == 2, "max ranks 3 / 3 / 2")
	_check(rb.level_required == [1, 3, 5] and fz.level_required == [2, 4, 6] and ra.level_required == [4, 7],
			"level requirements F 1/3/5, Q 2/4/6, E 4/7")
	_check(fz.secondary_status_id == &"chill" and is_equal_approx(fz.secondary_duration, 3.0), "ff chill 3 s after")
	_check(rb.target_type == SpellType.TargetType.UNIT and fz.target_type == SpellType.TargetType.AREA
			and ra.target_type == SpellType.TargetType.SELF, "target types")

	var r: Array = _make_wizard(Unit.Team.PLAYER, T0, ICE)
	torv = r[0]
	tc = r[1]
	_check(tc.spell_ids() == ICE, "slot order F / Q / E")
	_check(tc.rank_of(&"rime_bolt") == 1 and tc.rank_of(&"flash_freeze") == 0 and tc.rank_of(&"rime_aegis") == 0,
			"start ranks")
	tc.spell_effect.connect(_on_effect)

	# Refusals, in order.
	var foe := _spawn("shade", Unit.Team.ENEMY, T0 + Vector3(6.0, 0.0, 0.0))
	var friend := _spawn("flame_guard", Unit.Team.PLAYER, T0 + Vector3(-3.0, 0.0, 0.0))
	_check(tc.cast(&"fireball", T0) == "Unknown spell", "unknown spell (Vessa's on Torvald)")
	_check(tc.cast(&"flash_freeze", T0) == "Not learned", "flash freeze not learned")
	torv.mana = 0.0
	_check(tc.cast(&"rime_aegis", null) == "Not learned", "not learned before mana")
	_check(tc.cast(&"rime_bolt", foe) == "Not enough mana", "not enough mana")
	torv.mana = 100.0
	_check(tc.cast(&"rime_bolt", T0 + Vector3(3.0, 0.0, 0.0)) == "Invalid target", "bolt on a point")
	_check(tc.cast(&"rime_bolt", friend) == "Invalid target", "bolt on a friend")
	var ghost_r: Array = _make_wizard(Unit.Team.PLAYER, T0 + Vector3(0.0, 0.0, 6.0), ICE)
	ghost_r[0].die()
	_check(ghost_r[1].cast(&"rime_bolt", foe) == "Dead", "dead first")

	# Rime Bolt rank 1 / 2 / 3 on three shades.
	bolt_targets = [foe, _spawn("shade", Unit.Team.ENEMY, T0 + Vector3(6.0, 0.0, 3.0)),
			_spawn("shade", Unit.Team.ENEMY, T0 + Vector3(6.0, 0.0, -3.0))]
	for u in bolt_targets:
		hp0[u] = u.hp
	var want_cd := [6.0, 5.5, 5.0]
	for i in 3:
		_ready_caster(&"rime_bolt", i + 1)
		_check(tc.cast(&"rime_bolt", bolt_targets[i]) == "", "rime bolt rank %d refused" % (i + 1))
		_near(torv.mana, 65.0, "rime bolt mana 35 at rank %d" % (i + 1))
		_near(tc.cooldown_left(&"rime_bolt"), want_cd[i], "rime bolt cooldown rank %d" % (i + 1))
	_check(tc.cast(&"rime_bolt", foe) == "On cooldown", "rime bolt on cooldown")


func _on_effect(id: StringName, _pos: Vector3) -> void:
	if id != &"rime_bolt_hit":
		return
	for u in bolt_targets:
		if is_instance_valid(u) and not chill_at_hit.has(u) and u.global_position.distance_to(_pos) < 0.01:
			chill_at_hit[u] = u.status_time_left(&"chill")


# Casts Flash Freeze at `rank` on 3 shades (+ Malrik at rank 1) around `c`, checks the instant part.
func _start_freeze(rank: int, c: Vector3, with_malrik: bool) -> void:
	var t := SpellType.find(&"flash_freeze")
	var rad: float = t.radius_at(rank)
	var inside: Array = [_spawn("shade", Unit.Team.ENEMY, c), _spawn("shade", Unit.Team.ENEMY, c + Vector3(1.2, 0.0, 0.0))]
	var edge_probe := _spawn("shade", Unit.Team.ENEMY, c)
	var e := SpellCaster.edge_radius(edge_probe)
	edge_probe.queue_free()
	# The third one sits just inside this rank's radius (outside rank 1's at rank 3).
	var d_in := rad + e - 0.1 if rank < 3 else 3.3 + e
	inside.append(_spawn("shade", Unit.Team.ENEMY, c + Vector3(0.0, 0.0, -d_in)))
	var outside := _spawn("shade", Unit.Team.ENEMY, c + Vector3(0.0, 0.0, rad + e + 0.4))
	malrik = null
	if with_malrik:
		malrik = _make_wizard(Unit.Team.ENEMY, c + Vector3(-1.2, 0.0, 0.0), [] as Array[StringName])[0]
	var all: Array = inside + [outside] + ([malrik] if malrik else [])
	for u in all:
		hp0[u] = u.hp
	_ready_caster(&"flash_freeze", rank)
	_check(tc.cast(&"flash_freeze", c) == "", "flash freeze rank %d refused" % rank)
	_check(not tc.has_pending(), "flash freeze rank %d should cast at once" % rank)
	_near(torv.mana, 50.0, "flash freeze mana rank %d" % rank)
	_near(tc.cooldown_left(&"flash_freeze"), [20.0, 18.0, 16.0][rank - 1], "flash freeze cooldown rank %d" % rank)
	var dmg: float = [20.0, 30.0, 40.0][rank - 1]
	var frz: float = [1.5, 2.0, 2.5][rank - 1]
	for u in inside:
		_near(hp0[u] - u.hp, dmg, "flash freeze rank %d damage" % rank)
		if frozen_known:
			_near(u.status_time_left(&"frozen"), frz, "flash freeze rank %d frozen" % rank)
	_near(hp0[outside] - outside.hp, 0.0, "flash freeze rank %d outside untouched" % rank)
	_check(not outside.has_status(&"frozen"), "outside unit frozen")
	if malrik:
		_near(hp0[malrik] - malrik.hp, dmg, "flash freeze damage on Malrik")
		if frozen_known:
			_near(malrik.status_time_left(&"frozen"), frz * 0.5, "Malrik frozen half (0.75 s)")
	ff = [rank, inside, outside, malrik]


func _aegis_checks() -> void:
	var p: Vector3 = torv.global_position
	var near_g := _spawn("flame_guard", Unit.Team.PLAYER, p + Vector3(-5.0, 0.0, 0.0))
	var mid_g := _spawn("flame_guard", Unit.Team.PLAYER, p + Vector3(0.0, 0.0, 9.5))
	var worker := _spawn("cinder_hand", Unit.Team.PLAYER, p + Vector3(-2.0, 0.0, 2.0))
	var foe := _spawn("shade", Unit.Team.ENEMY, p + Vector3(-3.0, 0.0, -2.0))
	_ready_caster(&"rime_aegis", 1)
	_check(tc.cast(&"rime_aegis", null) == "", "rime aegis refused")
	_near(torv.mana, 40.0, "rime aegis mana")
	_near(tc.cooldown_left(&"rime_aegis"), 40.0, "rime aegis cooldown r1")
	_near(torv.shield, 80.0, "Torvald shield r1")
	_near(torv.shield_time_left(), 8.0, "shield lasts 8 s")
	_near(near_g.shield, 80.0, "soldier within 8 m shielded")
	_near(mid_g.shield, 0.0, "soldier at 9.5 m not shielded at r1")
	_near(worker.shield, 0.0, "worker not shielded")
	_near(foe.shield, 0.0, "enemy not shielded")
	_ready_caster(&"rime_aegis", 2)
	_check(tc.cast(&"rime_aegis", null) == "", "rime aegis r2 refused")
	_near(tc.cooldown_left(&"rime_aegis"), 35.0, "rime aegis cooldown r2")
	_near(torv.shield, 120.0, "Torvald shield r2")
	_near(mid_g.shield, 120.0, "soldier at 9.5 m shielded at r2 (radius 10)")
	for u in [near_g, mid_g, worker, foe]:
		u.queue_free()


func _ai_checks() -> void:
	var r: Array = _make_wizard(Unit.Team.PLAYER, A0, ICE)
	var w = r[0]
	var c = r[1]
	for id in ICE:
		c.set_rank(id, 1)
	w.mana = 100.0
	_check(c.suggest_cast().is_empty(), "nothing to do with no enemy around: %s" % [c.suggest_cast()])
	# Rule 1: HP under 50 %.
	w.hp = w.max_hp * 0.45
	var s: Dictionary = c.suggest_cast()
	_check(s.get("spell_id") == &"rime_aegis" and not s.get("retreat"), "aegis under 50 %% HP: %s" % [s])
	w.hp = w.max_hp * 0.3
	s = c.suggest_cast()
	_check(s.get("spell_id") == &"rime_aegis" and s.get("retreat"), "aegis + retreat under 35 %%: %s" % [s])
	w.hp = w.max_hp
	# Rule 2: two groups of 3, same size; the one holding the enemy wizard wins though farther.
	var g1 := A0 + Vector3(7.0, 0.0, -3.0)
	var g2 := A0 + Vector3(8.5, 0.0, 5.0)
	var foes: Array = []
	for i in 3:
		foes.append(_spawn("shade", Unit.Team.ENEMY, g1 + Vector3(i * 1.0, 0.0, 0.0)))
	foes.append(_spawn("shade", Unit.Team.ENEMY, g2))
	foes.append(_spawn("shade", Unit.Team.ENEMY, g2 + Vector3(1.0, 0.0, 0.0)))
	var enemy_wiz = _make_wizard(Unit.Team.ENEMY, g2 + Vector3(0.5, 0.0, 0.8), [] as Array[StringName])[0]
	s = c.suggest_cast()
	var ok: bool = s.get("spell_id") == &"flash_freeze" and s.get("target") is Vector3 \
			and (s["target"] as Vector3).distance_to(enemy_wiz.global_position) <= 3.0
	_check(ok, "flash freeze on the group with the enemy wizard: %s" % [s])
	# Rule 1 again: 4 own soldiers within 8 m and >= 3 enemies within 10 m (g1 is ~9 m away).
	var guards: Array = []
	for i in 4:
		guards.append(_spawn("flame_guard", Unit.Team.PLAYER, A0 + Vector3(-3.0, 0.0, -2.0 + i * 1.2)))
	s = c.suggest_cast()
	_check(s.get("spell_id") == &"rime_aegis", "aegis with 4 soldiers and 3 enemies near: %s" % [s])
	guards[0].die()
	s = c.suggest_cast()
	_check(s.get("spell_id") == &"flash_freeze", "3 soldiers are not enough for aegis: %s" % [s])
	# Rule 3: only Rime Bolt learned.
	c.set_rank(&"flash_freeze", 0)
	c.set_rank(&"rime_aegis", 0)
	var knight := _spawn("shadow_knight", Unit.Team.ENEMY, A0 + Vector3(5.0, 0.0, 0.0))
	s = c.suggest_cast()
	_check(s.get("spell_id") == &"rime_bolt" and s.get("target") == enemy_wiz, "bolt the enemy wizard first: %s" % [s])
	if chill_known:
		enemy_wiz.apply_status(&"chill", 5.0)
		s = c.suggest_cast()
		_check(s.get("target") == knight, "chilled wizard -> highest cost (knight): %s" % [s])
		knight.apply_status(&"chill", 5.0)
		for u in foes:
			u.apply_status(&"chill", 5.0)
		s = c.suggest_cast()
		_check(s.get("target") == knight, "all chilled -> nearest (knight at 5 m): %s" % [s])
	else:
		enemy_wiz.die()
		s = c.suggest_cast()
		_check(s.get("target") == knight, "no wizard -> highest cost (knight): %s" % [s])
	w.mana = 10.0
	_check(c.suggest_cast().is_empty(), "no suggestion without mana")
