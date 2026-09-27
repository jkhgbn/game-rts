extends SceneTree
## Task 7.G1 (kingdom-ice.md 2.1-2.3): statuses chill / frozen / rooted (+ haste stacking, speed floor,
## 2 s frozen immunity, half duration on wizards, orders kept), armor from UnitType (100 hit -> 87 at
## armor 15), on-hit status (melee and ranged), idle regen after 4 s, lifetime, support autocast
## (shield: lowest ratio < 0.8 within range, every interval, skips units with its shield; heal).
## Run: godot --headless --path . -s tests/test_7_g1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "7.G1"
const TIMEOUT_FRAMES := 1200

var main: Node
var frame := 0
var _wait := 0
var _settle := 0
var _errors: Array[String] = []

var h   # untyped: test scripts compile before autoloads
var base := Vector3.ZERO
var u := {}          # name -> Unit
var start_pos := {}  # name -> Vector3
var lt_died := false
var casts: Array = []   # [frame, target, kind]
var heal_casts: Array = []


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
	if _settle < 60:   # let the navigation map sync first (paths asked too early come back empty)
		_settle += 1
		return false
	frame += 1
	match frame:
		5:
			_setup()
		35:
			_check_during()
		75:
			_check_after_thaw_early()
		125:
			_check_after_thaw()
		200:
			_expect(_unit("fz").has_status(&"frozen") == false, "fz still frozen before re-freeze")
			_unit("fz").apply_status(&"frozen", 0.2)
			_expect(_unit("fz").has_status(&"frozen"), "frozen refused after the 2 s immunity")
		215:
			_expect(is_equal_approx(_unit("rg").hp, 50.0), "idle regen started before 4 s (hp %.2f)" % _unit("rg").hp)
		335:
			var hp: float = _unit("rg").hp
			_expect(hp > 51.0 and hp < 54.5, "idle regen 1.5 %%/s after 4 s wrong (hp %.2f)" % hp)
		500:
			_check_support()
		# second shield cast: FIRST_TRY 1 s + 12 s interval
		850:
			_check_support_interval()
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


func _unit(n: String) -> Unit:
	return u[n] as Unit


func _type(tid: String, hp: float = 150.0, speed: float = 4.2, cd: float = 1.1, rng: float = 1.6) -> UnitType:
	var t := UnitType.new()
	t.id = StringName(tid)
	t.display_name = tid
	t.faction = &"ice"
	t.max_hp = hp
	t.move_speed = speed
	t.attack_cooldown = cd
	t.attack_range = rng
	t.attack_damage = 10.0
	t.aggro_range = 0.0
	return t


func _spawn(n: String, t: UnitType, team: int, offset: Vector3) -> Unit:
	var unit := t.create_unit()
	unit.team = team
	main.add_child(unit)
	unit.global_position = base + offset
	unit.command_stop()
	u[n] = unit
	start_pos[n] = unit.global_position
	return unit


func _dummy(n: String, offset: Vector3) -> Unit:
	var t := _type("dummy_" + n, 1000.0)
	t.attack_damage = 0.0
	return _spawn(n, t, 1, offset)


func _moved(n: String) -> float:
	var p: Vector3 = _unit(n).global_position
	var s: Vector3 = start_pos[n]
	return Vector2(p.x - s.x, p.z - s.z).length()


func _setup() -> void:
	h = main.hero
	base = h.global_position + Vector3(12.0, 0.0, -10.0)

	# --- chill: x1.25 cooldown, -1.5 m/s, floor 1.0, multiplicative with haste.
	var ca := _spawn("ca", _type("ca"), 0, Vector3(-9, 0, -6))
	ca.apply_status(&"chill", 5.0)
	_expect(is_equal_approx(ca.get_stat(&"attack_cooldown"), 1.375), "chill cooldown %.4f != 1.375" % ca.get_stat(&"attack_cooldown"))
	_expect(is_equal_approx(ca.move_speed, 2.7), "chill speed %.3f != 2.7" % ca.move_speed)
	var ch := _spawn("ch", _type("ch"), 0, Vector3(-9, 0, -8))
	ch.apply_status(&"haste", 5.0)
	ch.apply_status(&"chill", 5.0)
	_expect(is_equal_approx(ch.attack_cooldown, 1.1 * 0.875), "haste+chill cooldown %.4f != 0.9625" % ch.attack_cooldown)
	_expect(is_equal_approx(ch.move_speed, 4.2), "haste+chill speed %.3f != 4.2" % ch.move_speed)
	var cf := _spawn("cf", _type("cf", 150.0, 2.0), 0, Vector3(-9, 0, -10))
	cf.apply_status(&"chill", 5.0)
	_expect(is_equal_approx(cf.move_speed, 1.0), "chill floor %.3f != 1.0" % cf.move_speed)
	var ca2 := _spawn("ca2", _type("ca2"), 0, Vector3(-12, 0, -6))
	ca2.apply_status(&"chill", 0.5)
	_expect(ca2.can_move() and ca2.can_act(), "chill must not stop move / act")

	# --- frozen: no move, no attack; orders kept and resume.
	var fz := _spawn("fz", _type("fz"), 0, Vector3(-6, 0, 0))
	fz.command_move(fz.global_position + Vector3(0, 0, -8))
	fz.apply_status(&"frozen", 1.0)
	var mv := _spawn("mv", _type("mv"), 0, Vector3(-4.5, 0, -2))   # control: same order, no status
	mv.command_move(mv.global_position + Vector3(0, 0, -8))
	var fa := _spawn("fa", _type("fa"), 0, Vector3(-3, 0, 0))
	_dummy("fd", Vector3(-3, 0, 1.2))
	fa.command_attack(_unit("fd"))
	fa.apply_status(&"frozen", 1.0)

	# --- wizards: frozen / rooted half, chill full.
	h.apply_status(&"frozen", 0.4)
	_expect(absf(h.status_time_left(&"frozen") - 0.2) < 0.001, "wizard frozen not halved (%.3f)" % h.status_time_left(&"frozen"))
	_expect(not h.can_act() and not h.can_move(), "frozen wizard can still act / move")
	h.apply_status(&"chill", 1.0)
	_expect(is_equal_approx(h.status_time_left(&"chill"), 1.0), "wizard chill must be full duration")

	# --- rooted: no move, still attacks.
	var rt := _spawn("rt", _type("rt"), 0, Vector3(0, 0, 0))
	_dummy("rd", Vector3(0, 0, -5))
	rt.command_attack(_unit("rd"))
	rt.apply_status(&"rooted", 1.0)
	_expect(not rt.can_move() and rt.can_act(), "rooted: can_move false, can_act true expected")
	var rt2 := _spawn("rt2", _type("rt2"), 0, Vector3(3, 0, 0))
	_dummy("rd2", Vector3(3, 0, 1.2))
	rt2.command_attack(_unit("rd2"))
	rt2.apply_status(&"rooted", 1.0)

	# --- on-hit status: melee and ranged.
	var oht := _type("oh")
	oht.on_hit_status = &"chill"
	oht.on_hit_duration = 2.0
	var oh := _spawn("oh", oht, 0, Vector3(6, 0, 0))
	_dummy("ohd", Vector3(6, 0, 1.2))
	oh.command_attack(_unit("ohd"))
	var ort := _type("or", 80.0, 4.4, 1.4, 9.0)
	ort.on_hit_status = &"chill"
	ort.on_hit_duration = 1.5
	var orr := _spawn("or", ort, 0, Vector3(9, 0, 0))
	_dummy("ord", Vector3(9, 0, -6))
	orr.command_attack(_unit("ord"))

	# --- armor 15: a 100 hit costs 87.
	var art := _type("ar")
	art.armor = 15.0
	var ar := _spawn("ar", art, 0, Vector3(12, 0, 0))
	_expect(is_equal_approx(ar.get_stat(&"armor"), 15.0), "armor stat %.2f != 15" % ar.get_stat(&"armor"))
	ar.take_damage(100.0)
	var lost := 150.0 - ar.hp
	_expect(roundi(lost) == 87, "armor 15: lost %.2f instead of 87" % lost)

	# --- idle regen 1.5 %/s after 4 s.
	var rgt := _type("rg", 100.0)
	rgt.idle_regen_pct = 1.5
	var rg := _spawn("rg", rgt, 0, Vector3(15, 0, 0))
	rg.take_damage(50.0)

	# --- lifetime 1 s.
	var ltt := _type("lt")
	ltt.lifetime = 1.0
	var lt := _spawn("lt", ltt, 0, Vector3(18, 0, 0))
	lt.died.connect(func(_x: Unit) -> void: lt_died = true)
	_expect(is_equal_approx(lt.lifetime_left(), 1.0), "lifetime_left %.2f != 1" % lt.lifetime_left())

	# --- support: Rime Seer shield 60 / 6 s / every 12 s / range 8.
	var sb := Vector3(0, 0, -16)
	var seer_t := _type("seer", 70.0, 4.2, 1.5, 8.0)
	seer_t.support_kind = &"shield"
	seer_t.support_amount = 60.0
	seer_t.support_duration = 6.0
	seer_t.support_interval = 12.0
	seer_t.support_range = 8.0
	var seer := _spawn("seer", seer_t, 0, sb)
	_expect(seer.support_caster != null and seer.get_node_or_null(^"SupportCaster") != null, "no SupportCaster on the seer")
	if seer.support_caster:
		seer.support_caster.support_cast.connect(func(_c: Unit, t: Unit, k: StringName) -> void: casts.append([frame, t, k]))
	var s1 := _spawn("s1", _type("s1", 100.0), 0, sb + Vector3(5, 0, 0))
	s1.hp = 50.0
	var s5 := _spawn("s5", _type("s5", 100.0), 0, sb + Vector3(-5, 0, 0))
	s5.hp = 60.0
	var s2 := _spawn("s2", _type("s2", 100.0), 0, sb + Vector3(0, 0, 9))   # out of range
	s2.hp = 30.0
	var wt := _type("wk", 100.0)
	wt.is_worker = true
	var s3 := _spawn("s3", wt, 0, sb + Vector3(3, 0, 3))   # worker: never
	s3.hp = 10.0
	var s4 := _spawn("s4", _type("s4", 100.0), 0, sb + Vector3(-3, 0, 3))   # 90 %: above 0.8
	s4.hp = 90.0
	var foe := _spawn("foe", _type("foe", 100.0), 1, sb + Vector3(2, 0, -2))   # enemy: never
	foe.hp = 5.0

	# --- heal support (Bloomtender): 12 every 3 s, range 7.
	var bt := _type("bloom", 60.0, 4.8, 1.5, 7.0)
	bt.support_kind = &"heal"
	bt.support_amount = 12.0
	bt.support_interval = 3.0
	bt.support_range = 7.0
	var bloom := _spawn("bloom", bt, 0, Vector3(-14, 0, -16))
	var hb := _spawn("hb", _type("hb", 100.0), 0, Vector3(-11, 0, -16))
	hb.hp = 40.0
	if bloom.support_caster:
		bloom.support_caster.support_cast.connect(func(_c: Unit, t: Unit, k: StringName) -> void: heal_casts.append([frame, t, k]))


func _check_during() -> void:   # 0.5 s in
	_expect(_moved("mv") > 1.0, "control unit did not move (navigation not ready?)")
	_expect(_moved("fz") < 0.05, "frozen unit moved %.2f" % _moved("fz"))
	_expect(not _unit("fz").can_move() and not _unit("fz").can_act(), "frozen: can_move / can_act should be false")
	_expect(is_equal_approx(_unit("fd").hp, 1000.0), "frozen unit attacked")
	_expect(_moved("rt") < 0.05, "rooted unit moved %.2f" % _moved("rt"))
	_expect(_unit("rd2").hp < 1000.0, "rooted unit did not attack in range")
	_expect(_unit("ohd").has_status(&"chill"), "melee on-hit chill missing")
	_expect(not h.has_status(&"frozen") and h.can_act(), "wizard frozen 0.2 s still frozen at 0.5 s")
	_expect(not lt_died, "summon died too early")


func _check_after_thaw_early() -> void:   # 1.17 s in: fz thawed at 1.0 s -> immune
	_expect(not _unit("fz").has_status(&"frozen"), "frozen did not end after 1 s")
	_expect(_unit("fz").frozen_immunity_left() > 0.0, "no frozen immunity after the freeze")
	_unit("fz").apply_status(&"frozen", 0.5)
	_expect(not _unit("fz").has_status(&"frozen"), "frozen accepted during the 2 s immunity")
	_expect(_unit("ord").has_status(&"chill"), "ranged on-hit chill missing")
	_expect(lt_died, "summon did not wither after its lifetime")
	var ca2 := _unit("ca2")
	_expect(is_equal_approx(ca2.attack_cooldown, 1.1) and is_equal_approx(ca2.move_speed, 4.2), "chill stats not restored")


func _check_after_thaw() -> void:   # 2 s in
	_expect(_moved("fz") > 1.0, "frozen unit did not resume its move order (moved %.2f)" % _moved("fz"))
	_expect(_unit("fd").hp < 1000.0, "frozen unit did not resume its attack")
	_expect(_moved("rt") > 0.5, "rooted unit did not resume its attack order walk")


func _check_support() -> void:   # ~8.3 s in: first cast at 1 s
	_expect(casts.size() == 1, "seer cast %d times in 8 s (expected 1)" % casts.size())
	if casts.size() >= 1:
		_expect(casts[0][1] == _unit("s1"), "seer shielded the wrong unit")
		_expect(casts[0][2] == &"shield", "wrong support kind")
	# s1's shield expired at ~7 s.
	_expect(_unit("s1").shield <= 0.0, "shield did not expire after 6 s")
	# Skip rule: a fresh shield on s1 -> the next pick is s5.
	var sc: SupportCaster = _unit("seer").support_caster
	_unit("s1").add_shield(60.0, 6.0)
	_unit("s1").shield_source = sc.source_id
	var pick: Unit = sc.find_target()
	_expect(pick == _unit("s5"), "shield skip rule: expected s5, got %s" % (pick.unit_name if pick else "none"))
	_unit("s1").add_shield(0.0, 0.0)
	# Heal: every 3 s -> casts at 1, 4, 7 s.
	_expect(heal_casts.size() == 3, "bloom healed %d times in 8 s (expected 3)" % heal_casts.size())
	_expect(is_equal_approx(_unit("hb").hp, 40.0 + 36.0), "heal amount wrong (hp %.1f)" % _unit("hb").hp)


func _check_support_interval() -> void:   # ~14 s in: second cast at 13 s
	_expect(casts.size() == 2, "seer cast %d times in 14 s (expected 2)" % casts.size())
	if casts.size() == 2:
		var gap: int = int(casts[1][0]) - int(casts[0][0])
		_expect(absi(gap - 720) <= 2, "seer interval %d frames (expected 720)" % gap)
		_expect(casts[1][1] == _unit("s1"), "second shield went to the wrong unit")
		_expect(is_equal_approx(_unit("s1").shield, 60.0), "shield amount %.1f != 60" % _unit("s1").shield)
