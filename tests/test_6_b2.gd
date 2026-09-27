extends SceneTree
## Task 6.B2: balance-1 (docs/design/balance-1.md 2a / 2b / 2d kill essence / 2e crown seal) on the 1v1 map.
## - 8 crystal nodes: 2000 / 2000 / 2500 / 2500 per side, rich nodes at (-40, -40) / (40, 40) with clearings
##   (no tree / rock near them, the rich hall spot passes build_grid.check);
## - building data: keeps 2500 HP and 12 dmg / range 10 / 1.5 s, halls 1300, hearths 500, spires 750 / 15 / max 4;
## - the Fire keep shoots an enemy unit in range, units first (an enemy hovel in range is ignored while the
##   unit lives), then the building once the unit is dead;
## - the Ember Crown can't be claimed before 6:00 (stays visible, seal_refused for a wizard on it),
##   stirs at 5:30, unseals at 6:00 and can then be claimed; Skirmish.crown_unseal_time_left() follows the clock;
## - kill essence = 60 % of the victim's XP value (a Shade, 40 XP, gives 24).
## Run:  godot --headless --path . -s tests/test_6_b2.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "6.B2"
const TIMEOUT_FRAMES := 1500
const SCENE := "res://scenes/skirmish.tscn"
const SETUP := 5

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []

var _fake_time := 0.0
var _refused := 0
var _stirred := 0
var _unsealed := 0
var _crown_ok := false

var _shade: Node3D
var _hovel: Node3D
var _keep_hit := false
var _shade_killed_frame := -1
var _keep_ok := false


func _initialize() -> void:
	main = load(SCENE).instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")   # map rules only: no bot
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 3000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == SETUP:
		_check_map()
		_check_data()
		_check_kill_essence()
		_start_keep()
		_start_crown()
	elif frame > SETUP:
		_watch_keep()
		_watch_crown()
	if not _errors.is_empty():
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if _crown_ok and _keep_ok:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out (crown %s, keep hit %s, keep ok %s)" % [TASK_ID, _crown_ok, _keep_hit, _keep_ok])
		return true
	return false


# ---------------------------------------------------------------- map and data

func _check_map() -> void:
	var want := {
		&"node_fire_a": [Vector3(-46, 0, 34), 2000], &"node_fire_b": [Vector3(-34, 0, 46), 2000],
		&"node_fire_mid": [Vector3(-16, 0, 6), 2500], &"node_fire_rich": [Vector3(-40, 0, -40), 2500],
		&"node_shadow_a": [Vector3(46, 0, -34), 2000], &"node_shadow_b": [Vector3(34, 0, -46), 2000],
		&"node_shadow_mid": [Vector3(16, 0, -6), 2500], &"node_shadow_rich": [Vector3(40, 0, 40), 2500],
	}
	if main.crystal_nodes.size() != 8:
		_errors.append("%d crystal nodes, want 8" % main.crystal_nodes.size())
	for id in want:
		var n: Node3D = main.crystal_nodes.get(id)
		if n == null or _flat(n.global_position, want[id][0]) > 0.01 or int(n.get("crystals_left")) != int(want[id][1]):
			_errors.append("node %s: %s" % [id, [n.global_position, n.get("crystals_left")] if n else "missing"])
	if main.rich_node(0) != main.crystal_nodes.get(&"node_fire_rich") \
			or main.rich_node(1) != main.crystal_nodes.get(&"node_shadow_rich") \
			or main.rich_hall_spot(0) != Vector3(-33, 0, -33) or main.rich_hall_spot(1) != Vector3(33, 0, 33):
		_errors.append("rich_node / rich_hall_spot helpers")
	# Clearings: no tree or rock within 6 m of a rich node or 4 m of its hall spot.
	for child in main.nav_region.get_children():
		if not child is StaticBody3D or child is Building or child is CrystalNode:
			continue
		var p: Vector3 = child.global_position
		for s in [1.0, -1.0]:
			if _flat(p, Vector3(-40, 0, -40) * s) < 6.0 or _flat(p, Vector3(-33, 0, -33) * s) < 4.0:
				_errors.append("obstacle %s at %s inside a rich clearing" % [child.name, p])
	# A forward hall fits at the rich hall spot, both sides.
	for team in [0, 1]:
		var t := BuildingType.find("fire_barracks" if team == 0 else "shadow_barracks")
		var spot: Vector3 = main.build_grid.snap(main.rich_hall_spot(team), t.footprint)
		var reason: String = main.build_grid.check(t, spot, team)
		if reason != "":
			_errors.append("team %d hall at the rich spot %s: '%s'" % [team, spot, reason])


func _check_data() -> void:
	# id: [max_hp, attack_damage, attack_range, attack_cooldown, max_count]
	var want := {
		"fire_keep": [2500.0, 12.0, 10.0, 1.5, 0], "shadow_keep": [2500.0, 12.0, 10.0, 1.5, 0],
		"fire_barracks": [1300.0, 0.0, 0.0, 1.5, 0], "shadow_barracks": [1300.0, 0.0, 0.0, 1.5, 0],
		"fire_hearth": [500.0, 0.0, 0.0, 1.5, 2], "shadow_hovel": [500.0, 0.0, 0.0, 1.5, 2],
		"fire_tower": [750.0, 15.0, 11.0, 1.5, 4], "shadow_tower": [750.0, 15.0, 11.0, 1.5, 4],
	}
	for id in want:
		var t := BuildingType.find(id)
		var w: Array = want[id]
		if t == null or t.max_hp != w[0] or t.attack_damage != w[1] or t.attack_range != w[2] \
				or t.attack_cooldown != w[3] or t.max_count != w[4]:
			_errors.append("%s data" % id)
	if main.keep.hp != 2500.0 or main.shadow_keep.hp != 2500.0:
		_errors.append("keeps start at %.0f / %.0f HP" % [main.keep.hp, main.shadow_keep.hp])


func _check_kill_essence() -> void:
	var bank_script: Script = load("res://scripts/items/essence_bank.gd")
	if int(bank_script.call("kill_essence", 40)) != 24 or int(bank_script.call("kill_essence", 90)) != 54 \
			or int(bank_script.call("kill_essence", 45)) != 27:
		_errors.append("kill_essence formula")
	# A live kill: Vessa kills an enemy Shade far from everything.
	var bank: Node = bank_script.call("for_team", 0)
	var shade: Unit = main.make_unit("shade")
	_spawn_unit(shade, Unit.Team.ENEMY, Vector3(-20, 0, 30))
	var xp: int = load("res://scripts/units/wizard.gd").call("xp_value_of", shade)
	var before := int(bank.get("essence"))
	shade.take_damage(99999.0, main.hero)
	var got := int(bank.get("essence")) - before
	if xp <= 0:
		_errors.append("shade xp value %d" % xp)
	if got != roundi(xp * 0.6):
		_errors.append("kill essence %d for %d XP, want %d" % [got, xp, roundi(xp * 0.6)])


# ---------------------------------------------------------------- the keep shoots

func _start_keep() -> void:
	var k: Node3D = main.keep
	# An enemy hovel 8 m in front (in range) and an enemy Shade on hold 7 m behind: units first.
	_hovel = main.build_grid.spawn_complete(BuildingType.find("shadow_hovel"), k.global_position + Vector3(0, 0, 8),
			Unit.Team.ENEMY)
	_shade = main.make_unit("shade")
	_spawn_unit(_shade, Unit.Team.ENEMY, k.global_position + Vector3(-7, 0, 0))
	_shade.command_hold()
	_shade.damage_taken.connect(func(_amount: float, attacker: Node3D) -> void:
		if attacker == main.keep:
			_keep_hit = true)


func _watch_keep() -> void:
	var k: Node = main.keep
	if _shade_killed_frame < 0:
		if not is_instance_valid(_shade) or not _shade.is_alive():
			if not _keep_hit:
				_errors.append("the shade died before the keep hit it")
			return
		var t: Variant = k.get("attack_target")
		if t != null and t == _hovel:
			_errors.append("the keep shot the hovel while a unit was in range")
		if _keep_hit and t == _shade:
			_shade.take_damage(99999.0, main.hero)
			_shade_killed_frame = frame
	elif not _keep_ok:
		if k.get("attack_target") == _hovel:
			_keep_ok = true
		elif frame - _shade_killed_frame > 120:
			_errors.append("the keep did not turn to the hovel after the shade died")


# ---------------------------------------------------------------- the crown seal

func _start_crown() -> void:
	var crown: Node3D = main.crown
	var left: float = main.crown_unseal_time_left()
	if absf(left - (360.0 - main.match_time())) > 0.1 or left < 300.0:
		_errors.append("crown_unseal_time_left %.2f at match time %.2f" % [left, main.match_time()])
	crown.seal_refused.connect(func(_c: Node, w: Node) -> void:
		if w == main.hero:
			_refused += 1)
	crown.stirring.connect(func(_c: Node) -> void: _stirred += 1)
	crown.unsealed.connect(func(_c: Node) -> void: _unsealed += 1)
	for w in main.wardens.duplicate():
		w.take_damage(99999.0, main.hero)
	main.hero.global_position = crown.global_position + Vector3(0, 0, 1)
	main.hero.command_stop()


func _watch_crown() -> void:
	var crown: Node3D = main.crown
	if frame == 60:
		if crown.wearer != null or not crown.is_sealed() or crown.can_be_claimed() or not crown.is_available() \
				or not crown.visible or _refused < 1 or _stirred != 0 or _unsealed != 0:
			_errors.append("before 6:00: wearer %s sealed %s available %s visible %s refused %d" % [
					crown.wearer, crown.is_sealed(), crown.is_available(), crown.visible, _refused])
		crown.match_time_source = _fake_clock
		_fake_time = 100.0
	elif frame == 62:
		if absf(main.crown_unseal_time_left() - 260.0) > 0.01 or crown.wearer != null:
			_errors.append("at 1:40: left %.2f wearer %s" % [main.crown_unseal_time_left(), crown.wearer])
		_fake_time = 335.0   # 5:35
	elif frame == 66:
		if _stirred != 1 or _unsealed != 0 or crown.wearer != null or not crown.is_sealed():
			_errors.append("at 5:35: stirred %d unsealed %d wearer %s" % [_stirred, _unsealed, crown.wearer])
		_fake_time = 359.5
	elif frame == 70:
		if crown.wearer != null:
			_errors.append("claimed at 5:59.5")
		_fake_time = 360.0
	elif frame == 74:
		if _unsealed != 1 or crown.is_sealed() or main.crown_unseal_time_left() != 0.0 or crown.wearer != main.hero:
			_errors.append("at 6:00: unsealed %d sealed %s left %.2f wearer %s" % [_unsealed, crown.is_sealed(),
					main.crown_unseal_time_left(), crown.wearer])
		else:
			_crown_ok = true


func _spawn_unit(u: Node3D, team: int, pos: Vector3) -> void:
	u.set(&"team", team)
	main.add_child(u)
	u.global_position = pos


func _fake_clock() -> float:
	return _fake_time


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
