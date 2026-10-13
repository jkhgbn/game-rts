extends SceneTree
## Fix batch F2 (code review 2026-10-12, gameplay): shield keep-larger (R3-2), Glasswater Ward after a killing hit
## (R2-1), Mother Hush's Smoke keeps the enemies' orders (R2-3 / drop_target_if), a max_hp modifier that only moves
## does not heal (R1-1 heal_gain), a re-applied status is never shortened (R1-5), Unit.set_down keeps orders,
## Champion.restore_fallen is quiet (W2-6), an "ally_heroes"-only wizard is worth wizard XP (R1-2), the shared clock.
## Run:  godot --headless --path . -s tests/test_f2_gameplay.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "f2_gameplay"
const TIMEOUT_FRAMES := 600

var main: Node
var frame := 0
var _wait := 0
var _fails: Array[String] = []
var _base := Vector3.ZERO

var soldier: Unit
var seer: Unit
var aldra: Helper
var hush: Helper
var victim: Unit
var foe: Unit
var died_count := 0
var events_died := 0
var melee_seen := false
var ability_hit_flagged := false

# Stage B: a skirmish save round trip (R3-3 rank3 / bowman modifiers, R1-4 summon lifetime, clock metas).
var stage := "main"
var sk: Node
var sk_frames := 0
var sk_total := 0
var expect: Dictionary = {}
var restorer_done := false


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if stage != "main":
		return _process_skirmish()
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	match frame:
		1:
			_setup()
		3:
			_check_shield()
			_check_heal_gain()
			_check_status()
			_check_set_down()
			_check_xp()
			_check_clock_start()
		40:
			_check_ward()
			_check_hush_smoke()
		45:
			_check_roster()
			_check_restore_fallen()
			_check_clock_end()
			_check_melee_flag()
			_start_skirmish()
			return false
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _fail(msg: String) -> void:
	_fails.append(msg)


func _plain_type(id: String, hp: float, reach: float) -> UnitType:
	var t := UnitType.new()
	t.id = StringName(id)
	t.display_name = id
	t.max_hp = hp
	t.move_speed = 4.0
	t.attack_damage = 5.0
	t.attack_range = reach
	t.attack_cooldown = 1.0
	t.aggro_range = 0.5
	t.armor = 0.0
	return t


func _spawn(t: UnitType, team: int, at: Vector3) -> Unit:
	var u := Unit.new()
	u.apply_type(t)
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = at
	u.command_stop()
	return u


func _setup() -> void:
	var hero := main.hero as Unit
	_base = hero.global_position + Vector3(6.0, 0.0, 6.0)
	soldier = _spawn(_plain_type("f2_soldier", 100.0, 1.5), Unit.Team.PLAYER, _base)
	soldier.hp = 40.0
	soldier.add_shield(500.0, 30.0)   # a big shield (Snow Shield, Vow...) the Rime Seer must not replace
	var seer_type := UnitType.find("rime_seer")
	if seer_type == null:
		_fail("rime_seer type missing")
	else:
		seer = _spawn(seer_type, Unit.Team.PLAYER, _base + Vector3(2.0, 0.0, 0.0))
	aldra = Helper.new()
	aldra.apply_helper_type(HelperType.find(&"helper_aldra"), 1)
	aldra.team = Unit.Team.PLAYER
	main.add_child(aldra)
	aldra.global_position = _base + Vector3(-3.0, 0.0, 3.0)
	aldra.command_stop()
	victim = _spawn(_plain_type("f2_victim", 100.0, 1.5), Unit.Team.PLAYER, _base + Vector3(-2.0, 0.0, 3.0))
	hush = Helper.new()
	hush.apply_helper_type(HelperType.find(&"helper_hush"), 1)
	hush.team = Unit.Team.ENEMY
	main.add_child(hush)
	hush.global_position = _base + Vector3(30.0, 0.0, -10.0)
	hush.command_stop()
	foe = _spawn(_plain_type("f2_foe", 100.0, 1.5), Unit.Team.PLAYER, _base + Vector3(27.0, 0.0, -10.0))
	# R2-6: a real melee auto-attack (Unit._perform_attack) raises melee_strike_active during its take_damage; a
	# direct take_damage from the same unit (an ability / DoT) does not.
	var dummy := _spawn(_plain_type("f2_dummy", 5000.0, 1.5), Unit.Team.PLAYER, _base + Vector3(-12.0, 0.0, -12.0))
	var brute := _spawn(_plain_type("f2_brute", 100.0, 1.5), Unit.Team.ENEMY, _base + Vector3(-12.0, 0.0, -10.9))
	dummy.damage_taken.connect(func(_amount: float, attacker: Node3D) -> void:
		if attacker is Unit and (attacker as Unit).melee_strike_active:
			melee_seen = true)
	brute.command_attack(dummy)
	dummy.take_damage(1.0, brute)   # not an auto-attack
	ability_hit_flagged = melee_seen


# R3-2: the Seer skips a unit whose shield is as large or larger; a smaller shield is topped up.
func _check_shield() -> void:
	if seer == null or seer.support_caster == null:
		_fail("no Rime Seer support caster")
		return
	var got := seer.support_caster.try_cast()
	if got == soldier or not is_equal_approx(soldier.shield, 500.0):
		_fail("seer replaced a larger shield (shield %.1f)" % soldier.shield)
	soldier.add_shield(1.0, 30.0)
	got = seer.support_caster.try_cast()
	if got != soldier or soldier.shield <= 1.0:
		_fail("seer did not shield a unit with a tiny shield (shield %.1f)" % soldier.shield)


# R1-1: a max_hp modifier moved to another source with heal_gain false does not heal.
func _check_heal_gain() -> void:
	var u := victim
	u.add_modifier(&"item:0", {"max_hp": 100.0})
	u.hp = 50.0
	u.remove_modifier(&"item:0")
	u.add_modifier(&"item:1", {"max_hp": 100.0}, false)
	if not is_equal_approx(u.hp, 50.0) or not is_equal_approx(u.max_hp, 200.0):
		_fail("heal_gain false healed (hp %.1f / %.1f)" % [u.hp, u.max_hp])
	u.remove_modifier(&"item:1")
	u.add_modifier(&"item:2", {"max_hp": 100.0})
	if not is_equal_approx(u.hp, 150.0):
		_fail("heal_gain default no longer heals the gain (hp %.1f)" % u.hp)
	u.remove_modifier(&"item:2")
	u.hp = u.max_hp


# R1-5: re-applying a shorter status keeps the longer timer.
func _check_status() -> void:
	victim.apply_status(&"chill", 3.0)
	victim.apply_status(&"chill", 1.0)
	if victim.status_time_left(&"chill") < 2.9:
		_fail("status shortened to %.2f" % victim.status_time_left(&"chill"))
	victim.apply_status(&"chill", 5.0)
	if victim.status_time_left(&"chill") < 4.9:
		_fail("status not refreshed to the longer time")


# set_down: moved (navmesh-snapped), same order, same order_serial, still walking to the same point.
func _check_set_down() -> void:
	var u := soldier
	var dest := _base + Vector3(0.0, 0.0, -12.0)
	u.command_move(dest)
	var serial := u.order_serial
	var to := _base + Vector3(1.5, 0.0, 1.0)
	u.set_down(to)
	if Vector2(u.global_position.x - to.x, u.global_position.z - to.z).length() > 1.0:
		_fail("set_down put the unit at %s (asked %s)" % [u.global_position, to])
	if not u.has_move_order() or u.order_serial != serial:
		_fail("set_down dropped the move order")
	u.command_stop()


# R1-2: a wizard in no hero group but "ally_heroes" is still worth wizard XP.
func _check_xp() -> void:
	var hero := main.hero as Unit
	var groups: Array[StringName] = []
	for g: StringName in [&"heroes", &"enemy_heroes"]:
		if hero.is_in_group(g):
			groups.append(g)
			hero.remove_from_group(g)
	var v := Unit.kill_xp_value(hero)
	for g in groups:
		hero.add_to_group(g)
	if v < Unit.WIZARD_KILL_XP:
		_fail("ally wizard worth %d XP" % v)


var _clock0 := 0.0


func _check_clock_start() -> void:
	_clock0 = CasterKit.now_s()


func _check_clock_end() -> void:
	if CasterKit.now_s() <= _clock0:
		_fail("CasterKit.now_s() does not advance")


# R2-1: a killing hit is not survived through Glasswater Ward's heal.
func _check_ward() -> void:
	var shooter := _spawn(_plain_type("f2_shooter", 100.0, 8.0), Unit.Team.ENEMY, _base + Vector3(-30.0, 0.0, 20.0))
	victim.set_down(aldra.global_position + Vector3(1.0, 0.0, 0.0))
	victim.hp = 100.0
	victim.take_damage(20.0, shooter)   # sanity: the ward gives 12 % of a ranged hit back
	if victim.hp < 82.0:
		_fail("Glasswater Ward not wired (hp %.2f after a 20 hit)" % victim.hp)
	victim.hp = 10.0
	victim.take_damage(11.0, shooter)
	if victim.is_alive():
		_fail("Glasswater Ward saved a unit from a killing hit (hp %.2f)" % victim.hp)
	shooter.queue_free()


# R2-3: Mother Hush's Smoke drops the enemy's target on her but keeps its attack-move.
func _check_hush_smoke() -> void:
	foe.command_attack_move(_base + Vector3(40.0, 0.0, -10.0))
	foe.set_auto_target(hush)
	if foe.attack_target != hush:
		_fail("set_auto_target did not point the foe at Hush")
		return
	var reason := hush.helper_abilities.cast(&"hush_smoke", hush)
	if reason != "":
		_fail("hush_smoke refused: %s" % reason)
		return
	if foe.attack_target == hush:
		_fail("Smoke did not drop the target")
	if not foe.is_attack_moving():
		_fail("Smoke wiped the attack-move order")


# W2-6: restore_fallen = fallen, hidden, no died / Events.unit_died.
func _check_restore_fallen() -> void:
	aldra.died.connect(func(_u: Unit) -> void: died_count += 1)
	var ev := root.get_node_or_null(^"Events")
	if ev:
		ev.connect(&"unit_died", func(u: Node) -> void:
			if u == aldra:
				events_died += 1)
	aldra.restore_fallen()
	if aldra.is_alive() or aldra.visible or aldra.is_in_group(&"units"):
		_fail("restore_fallen did not leave the champion fallen and hidden")
	if not aldra.is_in_group(&"champions"):
		_fail("restore_fallen took the champion out of 'champions'")
	if died_count != 0 or events_died != 0:
		_fail("restore_fallen fired died (%d) / unit_died (%d)" % [died_count, events_died])
	if aldra.intent != Champion.INTENT_FALLEN:
		_fail("restore_fallen intent %s" % aldra.intent)
	aldra.respawn(_base)
	if not aldra.is_alive():
		_fail("a restored fallen champion cannot be revived")


# R2-2: the roster saves / restores its helper (adopt: stance, state), create_for_save reuses the existing node, a
# "queued" state with no Call stub in any queue comes back as "none" (no "Already called" with nothing queued).
func _check_roster() -> void:
	var r := HelperRoster.for_team(int(Unit.Team.ENEMY))
	r.adopt(hush, &"home")
	if r.state() != &"alive" or hush.stance != &"home":
		_fail("adopt: state %s stance %s" % [r.state(), hush.stance])
	var d := r.save_state()
	if d.get("helper") != hush or String(d.get("state", "")) != "alive":
		_fail("roster save_state %s" % d)
	if HelperRoster.create_for_save(main, r.save_key()) != r:
		_fail("create_for_save made a second roster")
	d["state"] = "queued"
	d["helper"] = null
	r.load_state(d, {})
	if r.state() != &"none" or r.can_call() == HelperRoster.REASON_ALREADY:
		_fail("queued without a stub stays %s" % r.state())
	if r.stub_for_save(HelperRoster.CALL_ID) == null:
		_fail("stub_for_save(call) null")


func _check_melee_flag() -> void:
	if ability_hit_flagged:
		_fail("a direct take_damage counted as a melee strike")
	if not melee_seen:
		_fail("Unit._perform_attack never raised melee_strike_active")


# ---------------------------------------------------------------- stage B: skirmish save round trip

func _start_skirmish() -> void:
	stage = "sk_start"
	root.remove_child(main)
	main.queue_free()
	sk = load("res://scenes/skirmish.tscn").instantiate()
	sk.set(&"time_limit_s", 0.0)
	root.add_child(sk)
	current_scene = sk


func _process_skirmish() -> bool:
	sk_total += 1
	sk_frames += 1
	if sk_total > 20000:
		_fail("skirmish stage timed out at %s" % stage)
		return _finish()
	match stage:
		"sk_start":
			if sk.get(&"hero") != null and bool(sk.get(&"match_started")):
				_bots_off()
				_sk_setup()
				stage = "sk_settle"
				sk_frames = 0
		"sk_settle":
			if sk_frames >= 30:
				_sk_capture_and_reload()
				stage = "sk_wait"
				sk_frames = 0
		"sk_wait":
			if restorer_done and sk_frames >= 5:
				_bots_off()
				_sk_compare()
				return _finish()
	return false


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _bots_off() -> void:
	for n in sk.find_children("*", "Commander", true, false):
		n.set(&"enabled", false)


func _sk_spawn(type_id: String, at: Vector3) -> Unit:
	var t := UnitType.find(type_id)
	if t == null:
		_fail("unit type %s missing" % type_id)
		return null
	var u := Worker.make_unit(t)
	u.team = Unit.Team.PLAYER
	sk.add_child(u)
	u.global_position = at
	u.command_stop()
	return u


func _sk_setup() -> void:
	var keep: Keep = sk.call(&"keep_of", 0)
	var at := keep.global_position + Vector3(9.0, 0.0, 9.0)
	var rider := _sk_spawn("blaze_rider", at)
	var bow := _sk_spawn("scorchbow", at + Vector3(2.0, 0.0, 0.0))
	var summon := _sk_spawn("flame_guard", at + Vector3(0.0, 0.0, 2.0))
	if rider == null or bow == null or summon == null:
		return
	Stables16.force_enabled = true
	Stables16.for_team(0).grant(&"blaze_rider")
	BowmanUpgrades.for_team(0).grant(&"scorchbow_heavy_draw")
	rider.hp = rider.max_hp * 0.5
	summon.set_lifetime(40.0)
	bow.set_meta(BowmanKit.HAMSTRING_META, CasterKit.now_s() + 20.0)
	ClockMetaLedger.ensure()
	T3Kit.pause_building(keep, 30.0)


func _sk_capture_and_reload() -> void:
	var rider := _find_unit(&"blaze_rider", false)
	var bow := _find_unit(&"scorchbow", false)
	var summon := _find_unit(&"flame_guard", true)
	var keep: Keep = sk.call(&"keep_of", 0)
	if rider == null or bow == null or summon == null:
		_fail("stage B units missing before the save")
		return
	var now := CasterKit.now_s()
	expect = {"rider_max": rider.max_hp, "rider_hp": rider.hp, "rider_rank": rider.has_modifier(Stables16.RANK_MODIFIER),
			"bow_dmg": bow.attack_damage, "life": summon.lifetime_left(),
			"ham": float(bow.get_meta(BowmanKit.HAMSTRING_META)) - now,
			"pause": float(keep.get_meta(T3Kit.META_PAUSED)) - now}
	if not expect["rider_rank"] or expect["rider_max"] <= UnitType.find("blaze_rider").max_hp + 1.0:
		_fail("rank 3 not applied before the save (max %.1f)" % expect["rider_max"])
	var data := SaveGame.capture(sk)
	root.remove_child(sk)
	sk.queue_free()
	sk = SaveGame.instantiate_level(data)
	if sk == null:
		_fail("instantiate_level returned null")
		return
	restorer_done = false
	var r := sk.get_node(NodePath(SaveGame.RESTORER_NAME))
	r.connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		if not ok:
			_fail("the restorer reported a failure"))
	root.add_child(sk)
	current_scene = sk


func _sk_compare() -> void:
	var rider := _find_unit(&"blaze_rider", false)
	var bow := _find_unit(&"scorchbow", false)
	var summon := _find_unit(&"flame_guard", true)
	var keep: Keep = sk.call(&"keep_of", 0)
	if rider == null or bow == null or summon == null or keep == null:
		_fail("stage B units missing after the load")
		return
	var now := CasterKit.now_s()
	if not rider.has_modifier(Stables16.RANK_MODIFIER) or absf(rider.max_hp - float(expect["rider_max"])) > 0.5:
		_fail("rank3 lost on load (max %.1f, want %.1f)" % [rider.max_hp, expect["rider_max"]])
	if absf(rider.hp - float(expect["rider_hp"])) > 1.0:
		_fail("ranked rider HP %.1f, want %.1f" % [rider.hp, expect["rider_hp"]])
	if not Stables16.team_has_rank(0, &"blaze_rider"):
		_fail("Stables rank research lost on load")
	if absf(bow.attack_damage - float(expect["bow_dmg"])) > 0.01 or not BowmanUpgrades.team_has(0, &"scorchbow_heavy_draw"):
		_fail("bowman upgrade lost on load (damage %.1f, want %.1f)" % [bow.attack_damage, expect["bow_dmg"]])
	if absf(summon.lifetime_left() - float(expect["life"])) > 1.5:
		_fail("summon lifetime left %.1f, want %.1f" % [summon.lifetime_left(), expect["life"]])
	var ham := float(bow.get_meta(BowmanKit.HAMSTRING_META, -1.0)) - now
	if absf(ham - float(expect["ham"])) > 1.5:
		_fail("Hamstring cooldown left %.1f, want %.1f" % [ham, expect["ham"]])
	var pause := float(keep.get_meta(T3Kit.META_PAUSED, -1.0)) - now
	if absf(pause - float(expect["pause"])) > 1.5 or not T3Kit.is_paused(keep):
		_fail("Powder Charge pause left %.1f, want %.1f" % [pause, expect["pause"]])


# The team-0 unit of `type_id` (with a lifetime when `summon`), else null.
func _find_unit(type_id: StringName, summon: bool) -> Unit:
	for n in sk.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == 0 and u.unit_type and u.unit_type.id == type_id and u.is_alive() \
				and (u.lifetime_total() > 0.0) == summon:
			return u
	return null
