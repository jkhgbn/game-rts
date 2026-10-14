extends SceneTree
## Balance 2026-10-13 (docs/design/balance-2026-10-13-shadow-ice.md):
## H1: Mother Hush's Smoke Cloak dazes the enemies it makes drop her (2.0 s, a wizard 1.0 s), only those attacking
##     her, never changes their orders (attack-move and order_serial kept, they move on after); helpers off = no daze.
## I1: flash_freeze.tres damage 40 / 55 / 70, cooldown 18 / 16 / 14.
## Run:  godot --headless --path . -s tests/test_bal_1013.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "bal_1013"
const TIMEOUT_FRAMES := 600

var main: Node
var frame := 0
var _wait := 0
var _fails: Array[String] = []
var _base := Vector3.ZERO

var hush: Helper
var hush_off: Helper
var foe: Unit
var bystander: Unit
var foe_off: Unit
var hero: Unit
var foe_serial := 0
var foe_pos := Vector3.ZERO


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	match frame:
		1:
			_check_flash_freeze_data()
			_setup()
		5:
			_cast_smoke()
		65:   # 1 s later: the wizard's daze is over, the soldier's not
			if hero.has_status(&"dazed"):
				_fail("wizard still dazed after 1 s")
			if not foe.has_status(&"dazed"):
				_fail("foe daze ended before 2 s")
			foe_pos = foe.global_position
		140:   # 2.25 s later: the soldier walks on with its attack-move
			if foe.has_status(&"dazed"):
				_fail("foe still dazed after 2.25 s")
			if not foe.is_attack_moving() or foe.order_serial != foe_serial:
				_fail("foe lost its attack-move after the daze")
		200:
			if foe.global_position.distance_to(foe_pos) < 0.5:
				_fail("foe did not move on after the daze")
			_check_helpers_off()
			_finish()
			return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _fail(msg: String) -> void:
	_fails.append(msg)


func _finish() -> void:
	T3Kit.force_enabled = false
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])


func _near(a: float, b: float, what: String) -> void:
	if absf(a - b) > 0.05:
		_fail("%s: %.2f, expected %.2f" % [what, a, b])


func _check_flash_freeze_data() -> void:
	var fz := SpellType.find(&"flash_freeze")
	if fz == null:
		_fail("flash_freeze missing")
		return
	for r in [1, 2, 3]:
		_near(fz.damage_at(r), [40.0, 55.0, 70.0][r - 1], "ff damage r%d" % r)
		_near(fz.cooldown_at(r), [18.0, 16.0, 14.0][r - 1], "ff cooldown r%d" % r)
	_near(fz.damage, 40.0, "ff damage")
	_near(fz.cooldown, 18.0, "ff cooldown")


func _plain_type(id: String) -> UnitType:
	var t := UnitType.new()
	t.id = StringName(id)
	t.display_name = id
	t.max_hp = 5000.0
	t.move_speed = 4.0
	t.attack_damage = 1.0
	t.attack_range = 1.5
	t.attack_cooldown = 1.0
	t.aggro_range = 0.5
	return t


func _spawn(id: String, team: int, at: Vector3) -> Unit:
	var u := Unit.new()
	u.apply_type(_plain_type(id))
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = at
	u.command_stop()
	return u


func _make_hush(at: Vector3) -> Helper:
	var h := Helper.new()
	h.apply_helper_type(HelperType.find(&"helper_hush"), 1)
	h.team = Unit.Team.ENEMY
	main.add_child(h)
	h.global_position = at
	h.command_stop()
	return h


func _setup() -> void:
	hero = main.hero as Unit
	_base = hero.global_position + Vector3(6.0, 0.0, 6.0)
	hush = _make_hush(_base + Vector3(8.0, 0.0, 0.0))
	foe = _spawn("bal_foe", Unit.Team.PLAYER, _base + Vector3(5.0, 0.0, 0.0))
	bystander = _spawn("bal_bystander", Unit.Team.PLAYER, _base + Vector3(5.0, 0.0, 3.0))
	hero.global_position = _base + Vector3(5.0, 0.0, -3.0)
	hero.command_stop()


func _cast_smoke() -> void:
	T3Kit.force_enabled = true
	if not HelperAbilities.smoke_daze_here():
		_fail("smoke_daze_here false with helpers forced on")
	foe.command_attack_move(_base + Vector3(40.0, 0.0, 0.0))
	foe.set_auto_target(hush)
	hero.set_auto_target(hush)
	foe_serial = foe.order_serial
	var hero_serial := hero.order_serial
	if foe.attack_target != hush or hero.attack_target != hush:
		_fail("set_auto_target did not point the attackers at Hush")
		return
	hush.helper_abilities.reset_cooldowns()
	var reason := hush.helper_abilities.cast(&"hush_smoke", hush)
	if reason != "":
		_fail("hush_smoke refused: %s" % reason)
		return
	if foe.attack_target == hush or hero.attack_target == hush:
		_fail("Smoke did not drop the target")
	_near(foe.status_time_left(&"dazed"), HelperAbilities.SMOKE["daze"], "foe daze")
	_near(hero.status_time_left(&"dazed"), 1.0, "wizard daze")
	if bystander.has_status(&"dazed"):
		_fail("a unit not attacking Hush was dazed")
	if not foe.is_attack_moving():
		_fail("Smoke wiped the attack-move order")
	if foe.order_serial != foe_serial or hero.order_serial != hero_serial:
		_fail("Smoke changed an order_serial")


func _check_helpers_off() -> void:
	T3Kit.force_enabled = false
	if HelperAbilities.smoke_daze_here():
		_fail("smoke_daze_here true on a level without helpers")
	hush_off = _make_hush(_base + Vector3(-12.0, 0.0, 0.0))
	foe_off = _spawn("bal_foe_off", Unit.Team.PLAYER, _base + Vector3(-9.0, 0.0, 0.0))
	foe_off.command_attack_move(_base + Vector3(-40.0, 0.0, 0.0))
	foe_off.set_auto_target(hush_off)
	if foe_off.attack_target != hush_off:
		_fail("set_auto_target (off) did not point the attacker at Hush")
		return
	hush_off.helper_abilities.reset_cooldowns()
	var reason := hush_off.helper_abilities.cast(&"hush_smoke", hush_off)
	if reason != "":
		_fail("hush_smoke (off) refused: %s" % reason)
		return
	if foe_off.attack_target == hush_off:
		_fail("Smoke (off) did not drop the target")
	if foe_off.has_status(&"dazed"):
		_fail("helpers off: the attacker was dazed")
	if not foe_off.is_attack_moving():
		_fail("Smoke (off) wiped the attack-move order")
