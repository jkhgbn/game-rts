extends SceneTree
## Task 2.G3: Team.NEUTRAL, the Ruin Warden, Wizard.respawn(at).
## - The Ruin Warden data: neutral, pop 0, cost 0, 300 HP, leash 14 m (2x aggro 7).
## - is_enemy_of: neutral vs both sides, the two sides, never the same team.
## - A warden attacks a player unit, then an enemy unit (and the enemy unit attacks it back).
## - Leash: a fast enemy runs away; the warden drops it at the leash edge, never goes further,
##   and walks back home.
## - A dead wizard stays in the tree (hidden, no group, no collision); respawn(at) brings her
##   back at `at` with full HP and mana and emits respawned. Bonus stats add / remove.
## Run:  godot --headless --path . -s tests/test_2_g3.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "2.G3"
const TIMEOUT_FRAMES := 3000
const PHASE_LIMIT := 600

var main: Node
var frame := 0
var _wait := 0

var hero   # untyped Wizard
var start := Vector3.ZERO
var home := Vector3.ZERO
var lane_dir := Vector3(1.0, 0.0, -1.0).normalized()
var warden: Unit
var guard: Unit
var shade: Unit
var runner: Unit
var phase := 0
var phase_start := 0
var max_leash_dist := 0.0
var base_hp := 0.0
var base_mana := 0.0
var respawned_by: Variant = null
var errors: Array[String] = []
var done := false


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
	hero = main.hero
	_step()
	if not errors.is_empty():
		print("FAIL %s: %s (phase %d)" % [TASK_ID, " | ".join(errors), phase])
		return true
	if done:
		print("warden max distance from home while pulled: %.2f m (leash %.1f)" % [max_leash_dist, warden.leash_radius()])
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out in phase %d" % [TASK_ID, phase])
		return true
	return false


func _spawn(type_id: String, team: Unit.Team, pos: Vector3, hp: float = -1.0, aggro: float = -1.0) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team
	if hp > 0.0:
		u.max_hp = hp
	if aggro >= 0.0:
		u.aggro_range = aggro
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _next(p: int) -> void:
	phase = p
	phase_start = frame


func _timed_out(what: String) -> bool:
	if frame - phase_start > PHASE_LIMIT:
		errors.append(what)
		return true
	return false


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _free(u: Unit) -> void:
	if u != null and is_instance_valid(u):
		u.remove_from_group("units")
		u.queue_free()


func _on_respawned(w: Variant) -> void:
	respawned_by = w


func _step() -> void:
	match phase:
		0:
			for u in get_nodes_in_group("units"):
				if u != hero:
					_free(u)
			start = hero.global_position
			home = start + lane_dir * 22.0   # on the road, away from every building
			hero.aggro_range = 0.0
			_next(1)
		1:
			_check_data()
			warden = _spawn("ruin_warden", Unit.Team.NEUTRAL, home)
			guard = _spawn("flame_guard", Unit.Team.PLAYER, home + Vector3(4.0, 0.0, 0.0), 1000.0, 0.0)
			_check_teams()
			_next(2)
		2:   # the warden attacks the player's unit
			if warden.attack_target == guard and guard.hp < guard.max_hp:
				_free(guard)
				shade = _spawn("shade", Unit.Team.ENEMY, home + Vector3(-4.0, 0.0, 0.0), 1000.0)
				_next(3)
			else:
				_timed_out("warden never attacked the player unit")
		3:   # ...then the enemy's unit, which attacks it too
			if not warden.is_alive():
				errors.append("warden died too early")
			elif warden.attack_target == shade and shade.hp < shade.max_hp and shade.attack_target == warden:
				_free(shade)
				_next(4)
			else:
				_timed_out("warden and enemy unit did not fight (warden->%s, shade->%s)" %
						[warden.attack_target, shade.attack_target])
		4:   # nothing left: back home
			if warden.attack_target == null and _flat(warden.global_position, home) <= 1.3:
				runner = _spawn("shade", Unit.Team.ENEMY, home + Vector3(0.0, 0.0, 3.0), 5000.0, 0.0)
				_next(5)
			else:
				_timed_out("warden did not walk home after the fight (%.1f m away)" % _flat(warden.global_position, home))
		5:   # the warden engages the runner, which then flees along the road
			if warden.attack_target == runner and runner.hp < runner.max_hp:
				runner.command_move(home + lane_dir * 40.0)
				_next(6)
			else:
				_timed_out("warden never attacked the runner")
		6:   # it must drop the runner at the leash edge and walk home
			var d := _flat(warden.global_position, home)
			max_leash_dist = maxf(max_leash_dist, d)
			var limit: float = warden.leash_radius() + warden.attack_range + warden.radius * 2.0 + 0.6
			if d > limit:
				errors.append("warden chased %.1f m from home (limit %.1f)" % [d, limit])
			elif _flat(runner.global_position, home) > warden.leash_radius() + 4.0 \
					and warden.attack_target == null and d <= 1.3:
				_free(runner)
				_next(7)
			else:
				_timed_out("warden did not drop the runner and walk home (%.1f m away, target %s)" %
						[d, warden.attack_target])
		7:
			_check_bonus()
			hero.respawned.connect(_on_respawned)
			hero.add_bonus_stats(100.0, 50.0)   # wearing the crown
			hero.take_damage(hero.hp + 10.0, null)
			_next(8)
		8:   # dead: still in the tree, hidden, out of the fight
			if frame - phase_start < 90:   # model deaths last ~1.0 s (art-units.md D1, task 4.G2)
				return
			if not is_instance_valid(hero) or not hero.is_inside_tree():
				errors.append("dead wizard was freed")
				return
			if hero.is_alive() or hero.visible or hero.is_in_group("units") or hero.collision_layer != 0:
				errors.append("dead wizard state wrong (alive %s, visible %s, in units %s, layer %d)" %
						[hero.is_alive(), hero.visible, hero.is_in_group("units"), hero.collision_layer])
				return
			hero.remove_bonus_stats(100.0, 50.0)   # the crown drops
			hero.heal(50.0)
			if hero.hp != 0.0 or hero.max_hp != base_hp or hero.max_mana != base_mana:
				errors.append("dead wizard hp %.1f / %.1f, mana max %.1f" % [hero.hp, hero.max_hp, hero.max_mana])
				return
			hero.respawn(start)
			if respawned_by != hero:
				errors.append("respawned signal not emitted")
			if not hero.is_alive() or hero.hp != hero.max_hp or hero.max_hp != base_hp \
					or hero.mana != hero.max_mana or not hero.visible or not hero.is_in_group("units") \
					or hero.collision_layer != 2 or not hero.is_physics_processing():
				errors.append("respawn state wrong (alive %s, hp %.1f/%.1f, mana %.1f/%.1f, visible %s, layer %d)" %
						[hero.is_alive(), hero.hp, hero.max_hp, hero.mana, hero.max_mana, hero.visible, hero.collision_layer])
			if _flat(hero.global_position, start) > 0.1:
				errors.append("respawned at %s, expected %s" % [hero.global_position, start])
			var visual: Node3D = hero.get(&"_visual")
			if visual.scale != Vector3.ONE:
				errors.append("visual still squashed")
			_next(9)
		9:   # a second later she is still standing there, alive and full
			if frame - phase_start < 60:
				return
			if not hero.is_alive() or hero.hp != hero.max_hp:
				errors.append("wizard not alive / full a second after respawn")
			elif _flat(hero.global_position, start) > 0.5:
				errors.append("wizard wandered %.2f m after respawn" % _flat(hero.global_position, start))
			else:
				done = true


func _check_data() -> void:
	var t: UnitType = UnitType.find("ruin_warden")
	if t == null:
		errors.append("no data/units/ruin_warden.tres")
		return
	if t.faction != &"neutral" or t.pop != 0 or t.cost != 0 or t.max_hp != 300.0 or t.aggro_range != 7.0:
		errors.append("ruin_warden stats wrong")
	if int(Unit.Team.PLAYER) != 0 or int(Unit.Team.ENEMY) != 1:
		errors.append("PLAYER / ENEMY values changed")


func _check_teams() -> void:
	var enemy := Unit.new()
	enemy.team = Unit.Team.ENEMY
	var neutral := Unit.new()
	neutral.team = Unit.Team.NEUTRAL
	var player := Unit.new()
	player.team = Unit.Team.PLAYER
	if not warden.is_enemy_of(guard) or not guard.is_enemy_of(warden) \
			or not warden.is_enemy_of(enemy) or not enemy.is_enemy_of(warden) \
			or not player.is_enemy_of(enemy) or not enemy.is_enemy_of(player):
		errors.append("is_enemy_of: missing hostility")
	if warden.is_enemy_of(neutral) or player.is_enemy_of(guard) or enemy.is_enemy_of(enemy):
		errors.append("is_enemy_of: same team hostile")
	if absf(warden.leash_radius() - 14.0) > 0.01:
		errors.append("leash radius %.1f, expected 14" % warden.leash_radius())
	enemy.free()
	neutral.free()
	player.free()


func _check_bonus() -> void:
	base_hp = hero.max_hp
	base_mana = hero.max_mana
	hero.hp = base_hp - 30.0
	hero.add_bonus_stats(100.0, 50.0)
	if hero.max_hp != base_hp + 100.0 or hero.max_mana != base_mana + 50.0 or hero.hp != base_hp + 70.0:
		errors.append("add_bonus_stats: hp %.1f / %.1f, mana max %.1f" % [hero.hp, hero.max_hp, hero.max_mana])
	hero.remove_bonus_stats(100.0, 50.0)
	if hero.max_hp != base_hp or hero.max_mana != base_mana or hero.hp != base_hp or hero.mana > base_mana:
		errors.append("remove_bonus_stats: hp %.1f / %.1f, mana %.1f / %.1f" % [hero.hp, hero.max_hp, hero.mana, hero.max_mana])
