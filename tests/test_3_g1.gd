extends SceneTree
## Task 3.G1: SpellType data + SpellCaster (mana, cooldowns, targets, ranks) + the 6 spells.
## Builds its own SpellCaster on two freshly spawned wizards (does not rely on wizard.gd wiring).
## - Refusals: Dead, Unknown spell, Not learned (rank 0), On cooldown, Not enough mana, Invalid target.
## - Fireball 60 in radius 3.5 (not outside), mana 40 paid at cast; Ember Step blinks 12 m (clamped),
##   scorch deals 40 over 4 s; Kindle hastes a nearby soldier (cooldown x0.7, +1.5 speed) and
##   Vessa, not a worker nor a far soldier, for 8 s; Shadow Lance 50 + heals 25, cooldown 8;
##   Soul Siphon 40 per unit over 5 s, heals 50 % (60 for 3 units); Umbral Shroud halves a hit and
##   ends after 5 s; suggest_cast picks the shroud under 35 % HP; out of range = walks then casts.
## - Rank tables (levels.md) read per rank; mana never changes with rank.
## Run:  godot --headless --path . -s tests/test_3_g1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "3.G1"
const TIMEOUT_FRAMES := 2400
const P0 := Vector3(-20.0, 0.0, 20.0)
const M0 := Vector3(-20.0, 0.0, 4.0)

var main: Node
var frame := 0
var _wait := 0
var errors: Array[String] = []
var done := false

var vessa   # untyped Wizard
var malrik  # untyped Wizard
var vc   # SpellCaster
var mc   # SpellCaster
var step := 0
var step_frame := 0
var fb_in: Array = []
var fb_out: Unit
var scorch_victim: Unit
var near_guard: Unit
var far_guard: Unit
var worker: Unit
var lance_target: Unit
var cluster: Array = []
var hp0: Dictionary = {}
var base: Dictionary = {}
var origin := Vector3.ZERO
var mal_hp_before := 0.0
var walk_target := Vector3.ZERO


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


func _make_wizard(team: int, pos: Vector3, ids: Array[StringName]):
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


func _stat(u: Node, stat: StringName) -> float:
	if u.has_method(&"get_stat"):
		return float(u.call(&"get_stat", stat))
	return float(u.get(stat))


func _next() -> void:
	step += 1
	step_frame = frame


func _elapsed() -> int:
	return frame - step_frame


func _step() -> void:
	match step:
		0:
			_setup_and_sync_checks()
			_next()
		1:   # fireball landed (~1 s)
			if _elapsed() < 90:
				return
			for u in fb_in:
				_near(hp0[u] - u.hp, 60.0, "fireball damage inside radius")
			_near(hp0[fb_out] - fb_out.hp, 0.0, "fireball damage outside radius")
			# Ember Step: 20 m away -> clamped to 12 m; scorch on the old spot.
			vc.set_rank(&"ember_step", 1)
			vessa.mana = 100.0
			origin = vessa.global_position
			scorch_victim = _spawn("shade", Unit.Team.ENEMY, origin + Vector3(0.0, 0.0, 1.0))
			hp0[scorch_victim] = scorch_victim.hp
			_check(vc.cast(&"ember_step", origin + Vector3(-20.0, 0.0, 0.0)) == "", "ember step refused")
			var moved := Vector2(vessa.global_position.x - origin.x, vessa.global_position.z - origin.z).length()
			_near(moved, 12.0, "ember step distance", 0.6)
			_near(vessa.mana, 70.0, "ember step mana")
			vessa.mana = 0.0
			_check(vc.cast(&"ember_step", origin) == "On cooldown", "cooldown before mana")
			_near(vc.cooldown_left(&"ember_step"), 12.0, "ember step cooldown", 0.1)
			_next()
		2:   # scorch: 4 s, 8 ticks of 5
			if _elapsed() < 4 * 60 + 20:
				return
			_near(hp0[scorch_victim] - scorch_victim.hp, 40.0, "scorch total damage")
			# Kindle
			vc.set_rank(&"kindle", 1)
			vessa.mana = 100.0
			var p: Vector3 = vessa.global_position
			near_guard = _spawn("flame_guard", Unit.Team.PLAYER, p + Vector3(3.0, 0.0, 0.0))
			far_guard = _spawn("flame_guard", Unit.Team.PLAYER, p + Vector3(0.0, 0.0, 10.0))
			worker = _spawn("cinder_hand", Unit.Team.PLAYER, p + Vector3(0.0, 0.0, -3.0))
			_next()
		3:
			if _elapsed() < 2:
				return
			for u in [near_guard, far_guard, worker, vessa]:
				base[u] = [_stat(u, &"attack_cooldown"), _stat(u, &"move_speed")]
			_check(vc.cast(&"kindle", null) == "", "kindle refused")
			_next()
		4:
			if _elapsed() < 2:
				return
			_near(_stat(near_guard, &"attack_cooldown"), base[near_guard][0] * 0.7, "haste cooldown")
			_near(_stat(near_guard, &"move_speed"), base[near_guard][1] + 1.5, "haste speed")
			_near(_stat(vessa, &"move_speed"), base[vessa][1] + 1.5, "Vessa hasted")
			_near(_stat(far_guard, &"move_speed"), base[far_guard][1], "far guard not hasted")
			_near(_stat(worker, &"move_speed"), base[worker][1], "worker not hasted")
			_next()
		5:
			if _elapsed() < 8 * 60 + 10:
				return
			_near(_stat(near_guard, &"attack_cooldown"), base[near_guard][0], "haste expired (cooldown)")
			_near(_stat(near_guard, &"move_speed"), base[near_guard][1], "haste expired (speed)")
			# Shadow Lance
			malrik.hp = 200.0
			_check(mc.cast(&"shadow_lance", lance_target) == "", "lance refused")
			_near(mc.cooldown_left(&"shadow_lance"), 8.0, "lance cooldown", 0.05)
			_check(mc.cast(&"shadow_lance", lance_target) == "On cooldown", "lance second cast not on cooldown")
			_next()
		6:
			if _elapsed() < 60:
				return
			_near(hp0[lance_target] - lance_target.hp, 50.0, "lance damage")
			_near(malrik.hp, 225.0, "lance heal")
			# Soul Siphon on 3 player shades
			mc.set_rank(&"soul_siphon", 1)
			malrik.mana = 100.0
			malrik.hp = 200.0
			var center: Vector3 = M0 + Vector3(0.0, 0.0, 7.0)
			for i in 3:
				var s := _spawn("shade", Unit.Team.PLAYER, center + Vector3(-1.2 + i * 1.2, 0.0, 0.0))
				cluster.append(s)
			_next()
		7:
			if _elapsed() < 2:
				return
			for s in cluster:
				hp0[s] = s.hp
			var sug: Dictionary = mc.suggest_cast()
			_check(not sug.is_empty() and sug["spell_id"] == &"soul_siphon", "suggest_cast should pick Soul Siphon: %s" % [sug])
			_check(mc.cast(&"soul_siphon", M0 + Vector3(0.0, 0.0, 7.0)) == "", "siphon refused")
			_next()
		8:
			if _elapsed() < 5 * 60 + 20:
				return
			for s in cluster:
				_near(hp0[s] - s.hp, 40.0, "siphon damage per unit")
			_near(malrik.hp, 260.0, "siphon heal (50 % of 120)")
			# Umbral Shroud
			mc.set_rank(&"umbral_shroud", 1)
			malrik.mana = 100.0
			malrik.hp = 80.0
			var sug: Dictionary = mc.suggest_cast()
			_check(not sug.is_empty() and sug["spell_id"] == &"umbral_shroud" and sug["retreat"],
					"suggest_cast should pick Umbral Shroud under 35 %%: %s" % [sug])
			base[malrik] = _stat(malrik, &"move_speed")
			_check(mc.cast(&"umbral_shroud", null) == "", "shroud refused")
			_next()
		9:
			if _elapsed() < 2:
				return
			_near(_stat(malrik, &"move_speed"), base[malrik] + 2.0, "shroud speed")
			mal_hp_before = malrik.hp
			malrik.take_damage(40.0, null)
			_next()
		10:
			if _elapsed() < 2:
				return
			_near(mal_hp_before - malrik.hp, 20.0, "shroud halves damage")
			_next()
		11:
			if _elapsed() < 5 * 60:
				return
			_near(_stat(malrik, &"move_speed"), base[malrik], "shroud expired")
			# Out of range: walks, then casts (mana paid at the cast).
			vessa.mana = 100.0
			walk_target = vessa.global_position + Vector3(0.0, 0.0, -22.0)
			_check(vc.cast(&"fireball", walk_target) == "", "far fireball refused")
			_check(vc.has_pending(), "far fireball should walk first")
			_near(vessa.mana, 100.0, "no mana paid before the cast")
			_next()
		12:
			if vc.has_pending():
				if _elapsed() > 600:
					errors.append("never reached fireball range")
				return
			_near(vessa.mana, 60.0, "far fireball paid at cast", 1.0)
			var d := Vector2(vessa.global_position.x - walk_target.x, vessa.global_position.z - walk_target.z).length()
			_check(d <= 16.3, "cast from out of range (%.2f m)" % d)
			done = true


func _setup_and_sync_checks() -> void:
	var r: Array = _make_wizard(Unit.Team.PLAYER, P0, [&"fireball", &"ember_step", &"kindle"])
	vessa = r[0]
	vc = r[1]
	r = _make_wizard(Unit.Team.ENEMY, M0, [&"shadow_lance", &"soul_siphon", &"umbral_shroud"])
	malrik = r[0]
	mc = r[1]

	# Data: rank tables, mana constant.
	var fb := SpellType.find(&"fireball")
	var es := SpellType.find(&"ember_step")
	var ki := SpellType.find(&"kindle")
	var sl := SpellType.find(&"shadow_lance")
	var ss := SpellType.find(&"soul_siphon")
	var us := SpellType.find(&"umbral_shroud")
	for t in [fb, es, ki, sl, ss, us]:
		_check(t != null, "missing SpellType")
	if not errors.is_empty():
		return
	_near(fb.damage_at(1), 60.0, "fb r1"); _near(fb.radius_at(1), 3.5, "fb r1 radius")
	_near(fb.damage_at(3), 85.0, "fb r3"); _near(fb.radius_at(3), 4.0, "fb r3 radius")
	_near(es.total_damage_at(1), 40.0, "es r1 total"); _near(es.total_damage_at(2), 50.0, "es r2 total")
	_near(es.total_damage_at(3), 72.0, "es r3 total"); _near(es.range_at(3), 16.0, "es r3 range")
	_near(es.cooldown_at(2), 10.0, "es r2 cd")
	_near(ki.duration_at(2), 12.0, "ki r2 dur"); _near(ki.radius_at(2), 10.0, "ki r2 radius")
	_near(sl.damage_at(3), 80.0, "sl r3"); _near(sl.cooldown_at(3), 6.0, "sl r3 cd")
	_near(ss.total_damage_at(1), 40.0, "ss r1 total"); _near(ss.total_damage_at(2), 48.0, "ss r2 total")
	_near(ss.total_damage_at(3), 70.0, "ss r3 total")
	_near(us.duration_at(2), 7.0, "us r2 dur"); _near(us.cooldown_at(2), 20.0, "us r2 cd")
	_near(fb.mana_cost, 40.0, "fb mana"); _near(es.mana_cost, 30.0, "es mana"); _near(ki.mana_cost, 50.0, "ki mana")
	_near(sl.mana_cost, 35.0, "sl mana"); _near(ss.mana_cost, 45.0, "ss mana"); _near(us.mana_cost, 40.0, "us mana")
	_check(vc.spell_ids() == [&"fireball", &"ember_step", &"kindle"], "slot order")
	_check(vc.rank_of(&"fireball") == 1 and vc.rank_of(&"ember_step") == 0, "start ranks")

	# Refusals in order.
	_check(vc.cast(&"shadow_lance", P0) == "Unknown spell", "unknown spell (Malrik's spell on Vessa)")
	_check(vc.cast(&"ember_step", P0) == "Not learned", "ember step not learned")
	_check(vc.cast(&"kindle", null) == "Not learned", "kindle not learned")
	vessa.mana = 0.0
	_check(vc.cast(&"kindle", null) == "Not learned", "not learned before mana")
	_check(vc.cast(&"fireball", P0) == "Not enough mana", "not enough mana")
	vessa.mana = 100.0
	_check(vc.cast(&"fireball", null) == "Invalid target", "fireball needs a point")
	var friend := _spawn("shade", Unit.Team.ENEMY, M0 + Vector3(3.0, 0.0, 0.0))
	_check(mc.cast(&"shadow_lance", friend) == "Invalid target", "lance on a friend")
	_check(mc.cast(&"shadow_lance", M0) == "Invalid target", "lance on a point")
	var ghost := Wizard.new()
	ghost.team = Unit.Team.PLAYER
	main.add_child(ghost)
	ghost.global_position = P0 + Vector3(0.0, 0.0, -8.0)
	var gc = load("res://scripts/spells/spell_caster.gd").new()
	ghost.add_child(gc)
	gc.setup(ghost, [&"fireball", &"ember_step", &"kindle"] as Array[StringName])
	ghost.die()
	_check(gc.cast(&"nope", P0) == "Dead", "dead first")

	# Fireball: 3 enemies in the circle, 1 outside.
	var c: Vector3 = P0 + Vector3(7.0, 0.0, 0.0)
	fb_in = [_spawn("shade", Unit.Team.ENEMY, c), _spawn("shade", Unit.Team.ENEMY, c + Vector3(2.5, 0.0, 0.0)),
			_spawn("ruin_warden", Unit.Team.NEUTRAL, c + Vector3(0.0, 0.0, -2.5))]
	fb_out = _spawn("shade", Unit.Team.ENEMY, c + Vector3(0.0, 0.0, 5.5))
	for u in fb_in + [fb_out]:
		hp0[u] = u.hp
	_check(vc.cast(&"fireball", c) == "", "fireball refused")
	_near(vessa.mana, 60.0, "fireball mana")
	_check(not vc.has_pending(), "fireball in range should cast at once")

	lance_target = _spawn("shade", Unit.Team.PLAYER, M0 + Vector3(5.0, 0.0, 0.0))
	hp0[lance_target] = lance_target.hp
