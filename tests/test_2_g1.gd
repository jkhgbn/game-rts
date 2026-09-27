extends SceneTree
## Task 2.G1: units and wizards attack buildings.
## - A fireball's splash damages an enemy building in its radius.
## - Flame Guards and Ember Archers ordered to attack an enemy keep obey the order (even with an
##   enemy unit standing next to them), and melee hits + arrows lower its HP.
## - An idle guard between the keep (closer) and an enemy unit auto-aggroes the UNIT first,
##   then the keep once no enemy unit is near, and switches back to a unit that shows up.
## The enemy keep is spawned here (there is no enemy building on the map yet).
## Run:  godot --headless --path . -s tests/test_2_g1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "2.G1"
const TIMEOUT_FRAMES := 2400

const KEEP_POS := Vector3(-2.0, 0.0, 2.0)          # the mid camp clearing
const GROUP_START := Vector3(-14.0, 0.0, 14.0)     # on the road, 12 m from the keep's edge
const GUARD_B_POS := Vector3(2.5, 0.0, -2.5)       # keep edge 3.9 m away, shade 4.5 m away
const SHADE_B_POS := Vector3(7.0, 0.0, -2.5)
const FIREBALL_DAMAGE := 60.0

var main: Node
var frame := 0
var _wait := 0

var enemy_keep   # untyped: the Keep / Building class belongs to systems-coder and may change
var keep_hp_start := 0.0
var fireball_ok := false
var group: Array = []
var archer_hits := 0
var melee_seen := false
var guard_b: Unit
var shade_b: Unit
var shade_near_group: Unit
var shade_2: Unit
var b_first_target: Node3D = null
var b_took_keep := false
var b_switched := false
var shade_2_frame := -1
var errors: Array[String] = []


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
	if frame == 1:
		_clear_units()
	elif frame == 2:
		_spawn_keep_and_fireball()
		if not errors.is_empty():
			print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
			return true
	elif frame == 60:
		_check_fireball()
		_setup_fight()
	elif frame > 60:
		_watch()
	if not errors.is_empty():
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
		return true
	if _check_done():
		print("keep hp %.0f -> %.0f, archer hits %d, guard B: first=%s then keep=%s switched=%s" % [
				keep_hp_start, enemy_keep.hp, archer_hits, _name(b_first_target), b_took_keep, b_switched])
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out (fireball=%s melee=%s archer_hits=%d b_first=%s b_keep=%s b_switched=%s)" % [
				TASK_ID, fireball_ok, melee_seen, archer_hits, _name(b_first_target), b_took_keep, b_switched])
		return true
	return false


func _name(n: Variant) -> String:   # untyped: may be a freed node
	if n == null or not is_instance_valid(n):
		return "none"
	return String(n.name) if not n is Unit else (n as Unit).unit_name


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _clear_units() -> void:
	for u in get_nodes_in_group("units"):
		if u != main.hero:
			u.remove_from_group("units")
			u.queue_free()


func _spawn(type_id: String, team: Unit.Team, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _spawn_keep_and_fireball() -> void:
	var script: Script = load("res://scripts/buildings/keep.gd")
	if script == null:
		errors.append("can't load scripts/buildings/keep.gd")
		return
	enemy_keep = script.new()
	enemy_keep.set(&"team", Unit.Team.ENEMY)
	enemy_keep.set(&"max_hp", 20000.0)   # must survive the whole test
	# Balance-1 keeps shoot (test_6_b2): this test is about unit targeting, so its keep doesn't.
	var passive_type: BuildingType = BuildingType.find("shadow_keep").duplicate()
	passive_type.attack_damage = 0.0
	enemy_keep.set(&"building_type", passive_type)
	enemy_keep.name = "EnemyKeep"
	main.add_child(enemy_keep)
	enemy_keep.global_position = KEEP_POS
	keep_hp_start = enemy_keep.hp
	if not enemy_keep.is_in_group("buildings"):
		errors.append("the keep is not in group buildings")

	# A fireball (same call as Wizard._launch_fireball) landing 1 m from the keep's centre.
	var fireball := Projectile.new()
	main.add_child(fireball)
	fireball.launch_at_point(main.hero, KEEP_POS + Vector3(0.0, 6.0, 0.0), KEEP_POS + Vector3(1.0, 0.0, 1.0),
			FIREBALL_DAMAGE, 3.5, Color(1.0, 0.45, 0.1))


func _check_fireball() -> void:
	var lost: float = keep_hp_start - enemy_keep.hp
	if absf(lost - FIREBALL_DAMAGE) > 0.01:
		errors.append("fireball splash took %.1f HP from the keep (expected %.0f)" % [lost, FIREBALL_DAMAGE])
	else:
		fireball_ok = true
	keep_hp_start = enemy_keep.hp


func _setup_fight() -> void:
	# Group A: explicit attack order on the keep, with a passive enemy unit right next to them.
	for i in 3:
		group.append(_spawn("flame_guard", Unit.Team.PLAYER, GROUP_START + Vector3(i * 1.2 - 1.2, 0.0, 0.0)))
	for i in 2:
		group.append(_spawn("ember_archer", Unit.Team.PLAYER, GROUP_START + Vector3(i * 1.2 - 0.6, 0.0, 2.0)))
	shade_near_group = _spawn("shade", Unit.Team.ENEMY, GROUP_START + Vector3(0.0, 0.0, -2.5))
	shade_near_group.aggro_range = 0.0
	for u in group:
		u.command_attack(enemy_keep)
		if u.attack_target != enemy_keep:
			errors.append("command_attack(keep) was refused by %s" % u.unit_name)

	# Guard B: idle; the keep's edge is closer than the enemy shade, both inside aggro range.
	guard_b = _spawn("flame_guard", Unit.Team.PLAYER, GUARD_B_POS)
	shade_b = _spawn("shade", Unit.Team.ENEMY, SHADE_B_POS)
	shade_b.aggro_range = 0.0


func _watch() -> void:
	# Count arrows landing on the keep.
	for child in main.get_children():
		var p := child as Projectile
		if p and p.source is Unit and (p.source as Unit).attack_range > 3.0 and not p.has_meta(&"watched"):
			p.set_meta(&"watched", true)
			p.hit_unit.connect(func(target: Node3D, _dealt: float) -> void:
				if target == enemy_keep:
					archer_hits += 1)

	for u in group:
		if not is_instance_valid(u) or not u.is_alive():
			continue
		if u.attack_target != enemy_keep:
			errors.append("%s dropped its explicit attack order on the keep (target: %s)" % [
					u.unit_name, _name(u.attack_target)])
		elif u.attack_range <= 3.0 and enemy_keep.hp < keep_hp_start and _flat(u.global_position, KEEP_POS) <= u.attack_range + u.radius + Unit.radius_of(enemy_keep):
			melee_seen = true

	if not is_instance_valid(guard_b) or not guard_b.is_alive():
		errors.append("guard B died")
		return
	var t: Node3D = guard_b.attack_target
	if b_first_target == null and t != null:
		b_first_target = t
		if t != shade_b:
			errors.append("guard B auto-targeted %s before the enemy unit" % _name(t))
	var shade_b_dead: bool = not is_instance_valid(shade_b) or not shade_b.is_alive()
	if shade_b_dead and not b_took_keep and t == enemy_keep:
		b_took_keep = true
		shade_2 = _spawn("shade", Unit.Team.ENEMY, guard_b.global_position + Vector3(3.0, 0.0, -3.0))
		shade_2.aggro_range = 0.0
		shade_2_frame = frame
	if b_took_keep and not b_switched and is_instance_valid(shade_2) and t == shade_2:
		b_switched = true
	if shade_2_frame > 0 and not b_switched and frame - shade_2_frame > 60:
		errors.append("guard B kept hitting the keep with an enemy unit 4 m away")


func _check_done() -> bool:
	return fireball_ok and melee_seen and archer_hits >= 2 and b_took_keep and b_switched
