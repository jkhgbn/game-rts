extends SceneTree
## Bot review 2026-10-12, section C (scripts/ai/ai_casters.gd, ai_mapfill.gd): regression checks.
## - C1 hard dive: a fast soldier on a plain move order never dives; a non-army unit (Commander.is_army_unit false)
##   never dives; a diver gets an auto-target (its order kept, order_serial unchanged), never command_attack.
## - C2 _shrine_due skips a shrine the bot gave up on (GIVE_UP_COOLDOWN).
## - C4 _with_creeps keeps a neutral only if it fights the bot, or belongs to the current creep while stage is CREEP.
## - C5 Rimecarver retreat cover walls the rearmost chased member whose wall spot is in range; none in range = no cast.
## - C6 Snagroot never pulls an enemy no own fighter is engaged with; an engaged one still is.
## A bare world (no map), a fake Commander; AICasters is not processed (the test calls its checks directly).
## Run:  godot --headless --path . -s tests/test_botfix_casters.gd --fixed-fps 60 --quit-after 1200

const TASK_ID := "botfix_casters"
const PLAYER := 0
const ENEMY := 1

const FAKE_CMD := """extends Node
var team := 1
var difficulty := 2
var stage := 0
var mapfill_ai: Variant = null
var soldiers: Array = []
var not_army := {}
var retreating := false
var rally := Vector3.ZERO
func is_retreating() -> bool:
	return retreating
func rally_point() -> Vector3:
	return rally
func group_out() -> bool:
	return false
func own_soldiers() -> Array:
	return soldiers
func is_army_unit(u: Node) -> bool:
	return not not_army.has(u.get_instance_id())
"""

const FAKE_SHRINE := """extends Node3D
var kind := &"shrine"
var bank := 1
func is_awake() -> bool:
	return true
"""

var world: Node3D
var _errors: Array[String] = []
var _cases := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	_cases += 1
	if not ok:
		_errors.append(what)
		print("  x %s" % what)


func _script(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s


func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	var t := UnitType.find(id)
	var u: Unit = t.create_unit()
	u.team = team as Unit.Team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	await process_frame
	var cmd: Node = _script(FAKE_CMD).new()
	world.add_child(cmd)
	var ai := AICasters.new(cmd)
	ai.process_mode = Node.PROCESS_MODE_DISABLED
	world.add_child(ai)
	_c1(cmd, ai)
	_c4(cmd, ai)
	_c5(cmd, ai)
	_c6(cmd, ai)
	_c2()
	world.queue_free()
	await process_frame
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _cases])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	quit(0 if _errors.is_empty() else 1)


# ---------------------------------------------------------------- C1

func _c1(cmd: Node, ai: AICasters) -> void:
	var base := Vector3(30, 0, 30)
	var c1 := _spawn("kilnwarden", PLAYER, base)
	var c2 := _spawn("kilnwarden", PLAYER, base + Vector3(1.5, 0, 0))
	_check(CasterKit.is_caster_unit(c1), "C1 setup: the kilnwarden has no CasterAbility")
	var fast := UnitType.find("blaze_rider")
	_check(AICasters.is_fast(fast), "C1 setup: blaze_rider is not a fast type")
	var near := minf(fast.aggro_range + 1.0, 2.0 * fast.aggro_range - 1.0)
	# a) a fast soldier on a plain move order (a retreat)
	var walker := _spawn("blaze_rider", ENEMY, base + Vector3(-near, 0, 0))
	walker.command_move(base + Vector3(-60, 0, 0))
	# b) an idle fast soldier the Commander does not count as army (scout, capture squad)
	var scout := _spawn("blaze_rider", ENEMY, base + Vector3(0, 0, -near))
	# c) an idle fast army soldier: dives with an auto-target
	var diver := _spawn("blaze_rider", ENEMY, base + Vector3(0, 0, near))
	cmd.set(&"soldiers", [walker, scout, diver])
	(cmd.get(&"not_army") as Dictionary)[scout.get_instance_id()] = true
	ai.difficulty = 2
	var serial := diver.order_serial
	var casters: Array[Unit] = [c1, c2]
	ai._prefer_casters(casters)
	_check(walker.attack_target == null and walker.has_move_order(),
			"C1: a fast soldier on a plain move order dived (target %s)" % str(walker.attack_target))
	_check(scout.attack_target == null, "C1: a non-army unit dived")
	_check(diver.attack_target == c1 or diver.attack_target == c2, "C1: the idle army soldier did not dive")
	_check(diver.order_serial == serial, "C1: the dive used a player order (order_serial changed), not set_auto_target")
	_check(bool(diver.get(&"_auto_target")), "C1: the dive target is not an auto-target")
	for u: Unit in [c1, c2, walker, scout, diver]:
		u.queue_free()
	cmd.set(&"soldiers", [])


# ---------------------------------------------------------------- C4

func _c4(cmd: Node, ai: AICasters) -> void:
	var base := Vector3(-30, 0, -30)
	var caster := _spawn("kilnwarden", ENEMY, base)
	var own := _spawn("flame_guard", ENEMY, base + Vector3(3, 0, 0))
	var passer := _spawn("bristleback", Unit.Team.NEUTRAL, base + Vector3(10, 0, 0))
	var fighter := _spawn("bristleback", Unit.Team.NEUTRAL, base + Vector3(0, 0, 10))
	var target := _spawn("bristleback", Unit.Team.NEUTRAL, base + Vector3(-10, 0, 0))
	fighter.set_auto_target(own)
	_check(fighter.attack_target == own, "C4 setup: the neutral does not target the bot's unit")
	var mf := AIMapFill.new(ENEMY, PLAYER, AIProfile.new())
	mf.current_creep = {"kind": &"beast", "node": target}
	cmd.set(&"mapfill_ai", mf)
	var none: Array[Unit] = []
	cmd.set(&"stage", int(Commander.Stage.NONE))
	var out := ai._with_creeps(caster, none)
	_check(not out.has(passer), "C4: an idle camp creature the army walks past is a cast target")
	_check(out.has(fighter), "C4: a neutral fighting the bot is not a cast target")
	_check(not out.has(target), "C4: the creep target counts while the stage is not CREEP")
	cmd.set(&"stage", int(Commander.Stage.CREEP))
	out = ai._with_creeps(caster, none)
	_check(out.has(target), "C4: the current creep's creature is not a cast target in stage CREEP")
	_check(not out.has(passer), "C4: an idle neutral outside the creep is a cast target in stage CREEP")
	for u: Unit in [caster, own, passer, fighter, target]:
		u.queue_free()


# ---------------------------------------------------------------- C5

# Retreat cover: the rearmost chased member's wall spot is out of the Bulwark's 10 m range, a nearer member's is in
# range -> the wall goes behind the nearer one (the old code only tried the rearmost and failed "Out of range").
func _c5(cmd: Node, ai: AICasters) -> void:
	var base := Vector3(0, 0, 60)
	cmd.set(&"rally", base + Vector3(-30, 0, 0))
	cmd.set(&"retreating", true)
	ai.difficulty = 2
	var carver := _spawn("rimecarver", ENEMY, base)
	var ab := CasterKit.ability_of(carver)
	_check(ab != null, "C5 setup: the Rimecarver has no CasterAbility")
	if ab == null:
		return
	ab.mana = 500.0
	var far := _spawn("flame_guard", ENEMY, base + Vector3(16, 0, 0))      # rearmost: wall spot 18 m away
	var mid := _spawn("flame_guard", ENEMY, base + Vector3(13, 0, 0))      # first: also out of range
	var e_far := _spawn("flame_guard", PLAYER, far.global_position + Vector3(3, 0, 0))
	var e_mid := _spawn("flame_guard", PLAYER, mid.global_position + Vector3(0, 0, 3))
	var group: Array[Unit] = [mid, far]
	var enemies: Array[Unit] = [e_far, e_mid]
	var key := ab.get_instance_id()
	var cast := ai._rimecarver(carver, ab, group, base, enemies, 1000.0)
	_check(not cast and ab._pending.is_empty(), "C5: a Bulwark was cast with no chased member's wall spot in range")
	# The nearer member steps within range: its wall spot is 5.4 m from the Rimecarver.
	mid.global_position = base + Vector3(5, 0, 0)
	e_mid.global_position = mid.global_position + Vector3(0, 0, 3)
	cast = ai._rimecarver(carver, ab, group, base, enemies, 2000.0)
	var rule: Array = ai._rule_of.get(key, [])
	_check(cast and not rule.is_empty() and str(rule[0]) == "retreat_cover",
			"C5: no retreat-cover Bulwark on the nearer chased member (cast %s, rule %s)" % [cast, str(rule)])
	var tgt: Variant = ab._pending.get("target")
	var at: Vector3 = (tgt as Dictionary).get("at", Vector3.INF) if tgt is Dictionary else Vector3.INF
	_check(at.distance_to(Vector3(5, 0, 62)) < 0.5,
			"C5: the wall is not between the nearer member and its chaser (at %s)" % str(at))
	cmd.set(&"retreating", false)
	for u: Unit in [carver, far, mid, e_far, e_mid]:
		u.queue_free()


# ---------------------------------------------------------------- C6

# Snagroot: a ranged enemy 9 m away that no own fighter is within FIGHT_RADIUS of is never pulled (the old code
# pulled it); once an own soldier fights near it, it is.
func _c6(cmd: Node, ai: AICasters) -> void:
	var base := Vector3(60, 0, -60)
	var sage := _spawn("bramblesage", ENEMY, base)
	var ab := CasterKit.ability_of(sage)
	_check(ab != null, "C6 setup: the Bramblesage has no CasterAbility")
	if ab == null:
		return
	ab.mana = 500.0
	var s1 := _spawn("flame_guard", ENEMY, base + Vector3(-5.5, 0, 0.8))
	var s2 := _spawn("flame_guard", ENEMY, base + Vector3(-5.5, 0, -0.8))
	var archer := _spawn("ember_archer", PLAYER, base + Vector3(9, 0, 0))
	cmd.set(&"soldiers", [s1, s2])
	var enemies: Array[Unit] = [archer]
	var cast := ai._bramblesage_fight(sage, ab, enemies)
	_check(not cast and ab._pending.is_empty(), "C6: Snagroot pulled an enemy no own soldier fights")
	var s3 := _spawn("flame_guard", ENEMY, base + Vector3(6, 0, 0))   # now fighting 3 m from the archer
	cmd.set(&"soldiers", [s1, s2, s3])
	cast = ai._bramblesage_fight(sage, ab, enemies)
	_check(cast and StringName(ab._pending.get("id", &"")) == &"snagroot" and ab._pending.get("target") == archer,
			"C6: Snagroot no longer pulls an engaged ranged enemy (cast %s, pending %s)" % [cast, str(ab._pending)])
	cmd.set(&"soldiers", [])
	for u: Unit in [sage, s1, s2, s3, archer]:
		u.queue_free()


# ---------------------------------------------------------------- C2

func _c2() -> void:
	var mf := AIMapFill.new(ENEMY, PLAYER, AIProfile.new())
	var shrine: Node3D = _script(FAKE_SHRINE).new()
	world.add_child(shrine)
	mf._points = [shrine]
	mf._now = 100.0
	_check(mf._shrine_due(Vector3.ZERO) == shrine, "C2 setup: an awake own-bank shrine is not due")
	mf._gave_up[shrine.get_instance_id()] = 90.0
	mf._shrine_check_at = -INF
	_check(mf._shrine_due(Vector3.ZERO) == null, "C2: a shrine given up 10 s ago is due again")
	mf._now = 90.0 + AIMapFill.GIVE_UP_COOLDOWN + 1.0
	mf._shrine_check_at = -INF
	_check(mf._shrine_due(Vector3.ZERO) == shrine, "C2: the shrine stays skipped after GIVE_UP_COOLDOWN")
	shrine.queue_free()
