extends SceneTree
## Task 2.S1: buildings (docs/design/buildings.md). The spec's check: place an Ember Hall
## (250 -> 100 crystals), 2 workers build it in 30 s +-1, it trains a Flame Guard; a Hearth raises
## the cap to 40; a 10th Hearth is refused (pop-200 rule); cancelling a 120 site refunds 90. Also: the 8 types,
## every placement rule's message, 10 % -> 100 % hp, 1 / 1.5 / 2.0 build speed, workers go back
## to gathering, the keep trains only workers, the navmesh gets a hole under a new building,
## a destroyed Hearth frees its pop, a tower shoots, the Shadow team can place and build.
## Run:  godot --headless --path . -s tests/test_2_s1.gd --fixed-fps 60 --quit-after 7000

const TASK_ID := "2.S1"
const TIMEOUT_FRAMES := 4200
const SETUP_FRAME := 5   # the navigation map is synced a couple of frames after the bake

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _log: Array[String] = []

var grid: Node
var eco: Economy
var hall: Building
var hearth: Building
var workers: Array = []           # the 3 starting workers
var start_nodes: Array = []       # their gather nodes at the start
var tower: Building
var enemy_site: Building
var thrall: Unit

var _both_frame := -1
var _hall_done_frame := -1
var _hall_done := false
var _guard_spawned := false
var _hearth_checks := false
var _cancel_done := false
var _nav_ok := false
var _workers_back := false
var _tower_shot := false
var _enemy_building := false
var _walkable_done := false
var _hearth_placed := false
var _known: Dictionary = {}
var _enemy_hp_start := 0.0


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
	if frame == SETUP_FRAME:
		_setup()
	elif frame == SETUP_FRAME + 1:
		_check_walkable_rule()
	elif frame > SETUP_FRAME:
		_tick()
	if not _errors.is_empty():
		return _finish()
	if _hall_done and _guard_spawned and _hearth_checks and _cancel_done and _nav_ok and _workers_back \
			and _tower_shot and _enemy_building and _walkable_done:
		return _finish()
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out: hall %s guard %s hearth %s cancel %s nav %s back %s tower %s shadow %s" % [
				_hall_done, _guard_spawned, _hearth_checks, _cancel_done, _nav_ok, _workers_back,
				_tower_shot, _enemy_building])
		return _finish()
	return false


# ---------------------------------------------------------------- frame 1

func _setup() -> void:
	grid = main.build_grid
	eco = main.economy
	if grid == null:
		_errors.append("main.build_grid missing")
		return
	_check_types()
	var keep: Keep = main.keep
	if not keep is Building or keep.building_type == null or keep.building_type.id != &"fire_keep":
		_errors.append("the keep is not a Building with type fire_keep")
	var ids: Array[String] = []
	for t in keep.trainable_types():
		ids.append(String(t.id))
	if ids != ["cinder_hand"]:
		_errors.append("keep trains %s, want only cinder_hand" % [ids])
	if keep.can_queue(UnitType.find("flame_guard")) == "":
		_errors.append("the keep can still train a Flame Guard")
	if keep.target_radius() <= 0.0 or not keep.is_constructed():
		_errors.append("keep target_radius / is_constructed")
	if eco.crystals != 250 or eco.pop_cap != 20:
		_errors.append("start: %d crystals, cap %d; want 250, 20" % [eco.crystals, eco.pop_cap])

	var barracks := BuildingType.find("fire_barracks")
	var hearth_t := BuildingType.find("fire_hearth")
	var tower_t := BuildingType.find("fire_tower")

	# Snap: 3 x 3 / 1 x 1 on odd coordinates, 2 x 2 on even ones.
	if grid.snap(Vector3(-28.4, 0, 41.7), Vector2i(3, 3)) != Vector3(-29, 0, 41) \
			or grid.snap(Vector3(-28.4, 0, 41.7), Vector2i(2, 2)) != Vector3(-28, 0, 42) \
			or grid.snap(Vector3(-28.4, 0, 41.7), Vector2i(1, 1)) != Vector3(-29, 0, 41):
		_errors.append("snap: %s %s %s" % [grid.snap(Vector3(-28.4, 0, 41.7), Vector2i(3, 3)),
				grid.snap(Vector3(-28.4, 0, 41.7), Vector2i(2, 2)), grid.snap(Vector3(-28.4, 0, 41.7), Vector2i(1, 1))])

	# Placement rules (walkable: next frame).
	_expect_rule(barracks, Vector3(-59, 0, -59), "Outside the map")
	_expect_rule(barracks, Vector3(58, 0, 0), "Outside the map")
	_expect_rule(barracks, keep.global_position + Vector3(2, 0, 0), "Blocked")
	var node_a: Node3D = main.crystal_nodes[&"node_home_a"]
	_expect_rule(tower_t, node_a.global_position + Vector3(2.5, 0, 0), "Too close to a crystal node")
	var hound := _first_unit(Unit.Team.ENEMY, "Grave Hound")
	if hound:
		_expect_rule(tower_t, hound.global_position, "Blocked")
	else:
		_errors.append("no Grave Hound to test the enemy-unit rule")

	# Workers, and the gather nodes they will go back to.
	for u in get_nodes_in_group("units"):
		if u.team == Unit.Team.PLAYER and u.has_method("command_build"):
			workers.append(u)
			start_nodes.append(u.gather_node)
	if workers.size() != 3:
		_errors.append("%d starting workers" % workers.size())
		return

	# The Ember Hall: 250 -> 100, a site at 10 % hp.
	var spot := _find_spot(barracks, Vector3(-28, 0, 42), Unit.Team.PLAYER)
	hall = grid.place(barracks, spot, Unit.Team.PLAYER, [workers[0], workers[1]])
	if hall == null:
		_errors.append("Ember Hall refused at %s: %s" % [spot, grid.last_reason])
		return
	_log.append("hall at %s" % hall.global_position)
	if eco.crystals != 100:
		_errors.append("after the hall: %d crystals, want 100" % eco.crystals)
	if not hall is TrainingBuilding or hall.is_constructed() or hall.construction_progress() != 0.0 \
			or not is_equal_approx(hall.hp, 130.0) or not hall.is_in_group("buildings") \
			or (hall.collision_layer & 3) != 3 or not hall.is_alive():
		_errors.append("hall site: constructed %s progress %.2f hp %.1f" % [
				hall.is_constructed(), hall.construction_progress(), hall.hp])
	if hall.can_queue(UnitType.find("flame_guard")) != "Under construction":
		_errors.append("a site can train: '%s'" % hall.can_queue(UnitType.find("flame_guard")))
	if workers[0].build_site != hall or workers[1].build_site != hall:
		_errors.append("the 2 workers did not get command_build")
	_expect_rule(barracks, hall.global_position, "Blocked")   # a site blocks too

	# A Hearth (80): 100 -> 20. Then a tower is too expensive.
	var hspot := _find_spot(hearth_t, Vector3(-28, 0, 32), Unit.Team.PLAYER)
	hearth = grid.place(hearth_t, hspot, Unit.Team.PLAYER, [workers[2]])
	if hearth == null or eco.crystals != 20:
		_errors.append("hearth placement: %s, %d crystals" % [grid.last_reason, eco.crystals])
		return
	_hearth_placed = true
	if eco.pop_cap != 20:
		_errors.append("a hearth site already raised the cap")
	_expect_rule(tower_t, _find_spot_ignoring_cost(tower_t, Vector3(-24, 0, 40)), "Not enough crystals")

	# A finished Ember Spire (spawn_complete) near the mid camp must shoot the Shades.
	tower = grid.spawn_complete(tower_t, main.MID_CAMP + Vector3(-9, 0, 9), Unit.Team.PLAYER)
	grid.request_rebake()
	if not tower is Tower or not tower.is_constructed() or tower.hp != 750.0:
		_errors.append("spawn_complete tower")
	for u in get_nodes_in_group("units"):
		if u.team == Unit.Team.ENEMY:
			_enemy_hp_start += u.hp

	# The Shadow team: a Gloom Hall far from the player, and a Gloom Thrall to build it.
	var enemy_eco := Economy.for_team(Unit.Team.ENEMY)
	var gloom := BuildingType.find("shadow_barracks")
	var espot := _find_spot(gloom, Vector3(16, 0, -44), Unit.Team.ENEMY)
	thrall = main.make_unit("gloom_thrall")
	thrall.team = Unit.Team.ENEMY
	main.add_child(thrall)
	thrall.global_position = espot + Vector3(6, 0, 0)
	thrall.command_stop()
	enemy_site = grid.place(gloom, espot, Unit.Team.ENEMY, [thrall])
	if enemy_site == null or enemy_site.team != Unit.Team.ENEMY or enemy_eco.crystals != 100:
		_errors.append("Shadow Gloom Hall: %s, enemy crystals %d" % [grid.last_reason, enemy_eco.crystals])


func _check_types() -> void:
	# id: [cost, build_time, max_hp, footprint, pop_bonus, max_count, trains, damage, range, faction]
	var want := {
		"fire_keep": [0, 2500.0, Vector2i(3, 3), 20, 0, ["cinder_hand"], 12.0, "fire"],
		"shadow_keep": [0, 2500.0, Vector2i(3, 3), 20, 0, ["gloom_thrall"], 12.0, "shadow"],
		"fire_barracks": [150, 1300.0, Vector2i(3, 3), 0, 0,
				["flame_guard", "ember_archer", "blaze_rider", "ash_hurler"], 0.0, "fire"],
		"shadow_barracks": [150, 1300.0, Vector2i(3, 3), 0, 0,
				["shade", "nightbolt", "grave_hound", "shadow_knight"], 0.0, "shadow"],
		# Houses: +20 pop, max 9 per team (pop-200 rule, economy.md 2026-09-27; was +10, max 2).
		"fire_hearth": [80, 500.0, Vector2i(2, 2), 20, 9, [], 0.0, "fire"],
		"shadow_hovel": [80, 500.0, Vector2i(2, 2), 20, 9, [], 0.0, "shadow"],
		"fire_tower": [120, 750.0, Vector2i(1, 1), 0, 4, [], 15.0, "fire"],
		"shadow_tower": [120, 750.0, Vector2i(1, 1), 0, 4, [], 15.0, "shadow"],
	}
	var times := {"barracks": 45.0, "house": 25.0, "tower": 35.0}
	for id in want:
		var t := BuildingType.find(id)
		if t == null:
			_errors.append("missing data/buildings/%s.tres" % id)
			continue
		var w: Array = want[id]
		var trains: Array[String] = []
		for u in t.trains:
			trains.append(String(u.id))
		if t.cost != w[0] or t.max_hp != w[1] or t.footprint != w[2] or t.pop_bonus != w[3] \
				or t.max_count != w[4] or trains != Array(w[5], TYPE_STRING, "", null) \
				or t.attack_damage != w[6] or String(t.faction) != w[7]:
			_errors.append("%s numbers" % id)
		if times.has(String(t.kind)) and t.build_time != times[String(t.kind)]:
			_errors.append("%s build_time %.0f" % [id, t.build_time])
		if t.kind == &"tower" and (t.attack_range != 11.0 or t.attack_cooldown != 1.5):
			_errors.append("%s range / cooldown" % id)
		if t.kind == &"keep" and (t.attack_range != 10.0 or t.attack_cooldown != 1.5):   # balance-1 2b
			_errors.append("%s range / cooldown" % id)
	var fire_ids: Array[String] = []
	for t in BuildingType.buildable_for(&"fire"):
		fire_ids.append(String(t.id))
	if fire_ids != ["fire_hearth", "fire_barracks", "fire_tower"]:
		_errors.append("buildable_for(fire) = %s" % [fire_ids])
	if BuildingType.buildable_for(&"shadow").size() != 3 or BuildingType.find("Ember Hall") == null:
		_errors.append("buildable_for(shadow) / find by display name")


## Next frame: some cell of the map (a tree, rock or pillar) is refused as not walkable.
func _check_walkable_rule() -> void:
	var tower_t := BuildingType.find("fire_tower")
	var saved := eco.crystals
	eco.crystals = 1000
	var found := Vector3.INF
	for i in range(-29, 29):
		for j in range(-29, 29):
			var p: Vector3 = grid.cell_center(Vector2i(i, j))
			if grid.check(tower_t, p, Unit.Team.PLAYER) == "Not on walkable ground":
				found = p
				break
		if found != Vector3.INF:
			break
	eco.crystals = saved
	if found == Vector3.INF:
		_errors.append("no cell was refused as 'Not on walkable ground'")
	else:
		_log.append("not walkable at %s" % found)
	_walkable_done = true


# ---------------------------------------------------------------- every frame

func _tick() -> void:
	if hall == null or not _hearth_placed:
		return
	# Build speed: both workers on site -> 1.5, done 30 s later.
	if _both_frame < 0 and hall.builder_count() >= 2:
		_both_frame = frame
		if not is_equal_approx(hall.build_speed(), 1.5):
			_errors.append("2 builders: speed %.2f" % hall.build_speed())
		_log.append("both builders at frame %d, progress %.3f" % [frame, hall.construction_progress()])
	if not _hall_done and hall.is_constructed():
		_hall_done = true
		_hall_done_frame = frame
		var secs := (frame - _both_frame) / 60.0
		_log.append("hall built in %.2f s with 2 workers" % secs)
		if _both_frame < 0 or absf(secs - 30.0) > 1.0:
			_errors.append("hall built in %.2f s with 2 workers, want 30 +-1" % secs)
		if not is_equal_approx(hall.hp, 1300.0):
			_errors.append("finished hall hp %.1f, want 1300" % hall.hp)
		eco.crystals += 1000
		var r: String = hall.queue_unit(UnitType.find("flame_guard"))
		if r != "":
			_errors.append("the hall refused a Flame Guard: %s" % r)
		if hall.can_queue(UnitType.find("cinder_hand")) == "":
			_errors.append("the hall can train workers")
		for u in get_nodes_in_group("units"):
			_known[u] = true
		_cancel_test()
	if _hall_done and not _workers_back and frame - _hall_done_frame == 90:
		for i in 2:
			var w: Node = workers[i]
			if w.is_building() or not w.is_gathering() or w.gather_node != start_nodes[i]:
				_errors.append("worker %d did not go back to its node (gathering %s)" % [i, w.is_gathering()])
		_workers_back = true
	if _hall_done and not _guard_spawned:
		for u in get_nodes_in_group("units"):
			if _known.has(u):
				continue
			_known[u] = true
			if u.unit_name == "Flame Guard" and _flat(u.global_position, hall.spawn_point()) < 1.5:
				_guard_spawned = true
				_log.append("Flame Guard trained at frame %d" % frame)
	if not _hearth_checks and is_instance_valid(hearth) and hearth.is_constructed():
		_hearth_test()
	if not _nav_ok and frame > 10 and not grid.is_rebaking():
		# A path straight across the hall (9 m) must now go around it.
		var map: RID = main.nav_region.get_navigation_map()
		var a: Vector3 = hall.global_position + Vector3(-4.5, 0, 0)
		var b: Vector3 = hall.global_position + Vector3(4.5, 0, 0)
		var path := NavigationServer3D.map_get_path(map, a, b, true)
		var length := 0.0
		for i in range(1, path.size()):
			length += _flat(path[i - 1], path[i])
		if path.size() >= 2 and _flat(path[path.size() - 1], b) < 0.5 and length > 10.5:
			_nav_ok = true
			_log.append("path around the hall %.1f m (straight 9 m) at frame %d" % [length, frame])
	if not _tower_shot and is_instance_valid(tower) and tower.get("attack_target") != null:
		var now := 0.0
		for u in get_nodes_in_group("units"):
			if u.team == Unit.Team.ENEMY:
				now += u.hp
		if now < _enemy_hp_start - 1.0:
			_tower_shot = true
			_log.append("tower hit at frame %d" % frame)
	if not _enemy_building and is_instance_valid(enemy_site) and enemy_site.builder_count() == 1 \
			and enemy_site.construction_progress() > 0.0:
		_enemy_building = true


## After the hall: a Tower site (120) with the 1 / 1.5 / 2.0 / 2.0 speed table, then cancel -> +90.
func _cancel_test() -> void:
	eco.crystals = 500
	var tower_t := BuildingType.find("fire_tower")
	var site: Building = grid.place(tower_t, _find_spot(tower_t, Vector3(-24, 0, 40), Unit.Team.PLAYER),
			Unit.Team.PLAYER, [])
	if site == null or eco.crystals != 380:
		_errors.append("tower site: %s, %d crystals" % [grid.last_reason, eco.crystals])
		return
	var speeds: Array[float] = [site.build_speed()]
	for n in [workers[0], workers[1], workers[2], main.hero]:
		site.add_builder(n)
		speeds.append(site.build_speed())
	if speeds != [0.0, 1.0, 1.5, 2.0, 2.0]:
		_errors.append("build speeds %s, want 0 1 1.5 2 2" % [speeds])
	var gone := [false]
	site.destroyed.connect(func(_b: Building) -> void: gone[0] = true)
	site.cancel_construction()
	if eco.crystals != 470 or site.is_alive() or site.is_in_group("buildings") or not gone[0] \
			or not site.cancelled:
		_errors.append("cancel: %d crystals (want 470), alive %s, signal %s" % [eco.crystals, site.is_alive(), gone[0]])
	_cancel_done = true


## Hearth finished: cap 40; more hearth sites are fine up to 9 hearths (built or not), the 10th is refused;
## destroying one frees its 20 (pop-200 rule, economy.md 2026-09-27; was cap 30 / 3rd refused / frees 10).
func _hearth_test() -> void:
	_hearth_checks = true
	if eco.pop_cap != 40:
		_errors.append("cap %d after a hearth, want 40" % eco.pop_cap)
	var hearth_t := BuildingType.find("fire_hearth")
	eco.crystals = maxi(eco.crystals, 80 * (hearth_t.max_count - 1) + 100)
	for i in hearth_t.max_count - 1:
		var more: Building = grid.place(hearth_t,
				_find_spot(hearth_t, Vector3(-44 + (i % 4) * 5, 0, 26 + floori(i / 4.0) * 5), Unit.Team.PLAYER),
				Unit.Team.PLAYER, [])
		if more == null:
			_errors.append("hearth %d refused: %s" % [i + 2, grid.last_reason])
			return
	if eco.pop_cap != 40:
		_errors.append("unbuilt hearth sites changed the cap: %d" % eco.pop_cap)
	var extra_spot := _find_spot_ignoring_cost(hearth_t, Vector3(-20, 0, 30))
	var reason: String = grid.check(hearth_t, extra_spot, Unit.Team.PLAYER)
	var extra: Building = grid.place(hearth_t, extra_spot, Unit.Team.PLAYER, [])
	if reason != "Population limit reached" or extra != null or grid.last_reason != reason:
		_errors.append("hearth %d: '%s'" % [hearth_t.max_count + 1, reason])
	var gone := [false]
	hearth.destroyed.connect(func(_b: Building) -> void: gone[0] = true)
	hearth.take_damage(9999.0, null)
	if eco.pop_cap != 20 or hearth.is_alive() or not gone[0] or hearth.cancelled:
		_errors.append("destroyed hearth: cap %d, alive %s, signal %s" % [eco.pop_cap, hearth.is_alive(), gone[0]])
	_log.append("hearth checks at frame %d" % frame)


# ---------------------------------------------------------------- helpers

func _expect_rule(type: BuildingType, pos: Vector3, want: String) -> void:
	var got: String = grid.check(type, pos, Unit.Team.PLAYER)
	if got != want:
		_errors.append("%s at %s: '%s', want '%s'" % [type.id, pos, got, want])


## The nearest valid spot (check() == "") to `around`, scanning outward cell by cell.
func _find_spot(type: BuildingType, around: Vector3, team: int) -> Vector3:
	for r in 14:
		for i in range(-r, r + 1):
			for j in range(-r, r + 1):
				if maxi(absi(i), absi(j)) != r:
					continue
				var p: Vector3 = grid.snap(around + Vector3(i * 2.0, 0, j * 2.0), type.footprint)
				if grid.check(type, p, team) == "":
					return p
	_errors.append("no valid spot for %s near %s" % [type.id, around])
	return around


func _find_spot_ignoring_cost(type: BuildingType, around: Vector3) -> Vector3:
	var saved := eco.crystals
	eco.crystals = 100000
	var hearth_limit := type.max_count
	type.max_count = 0
	var p := _find_spot(type, around, Unit.Team.PLAYER)
	type.max_count = hearth_limit
	eco.crystals = saved
	return p


func _first_unit(team: int, unit_name: String) -> Unit:
	for u in get_nodes_in_group("units"):
		if u.team == team and u.unit_name == unit_name:
			return u
	return null


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _finish() -> bool:
	for line in _log:
		print("  ", line)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	return true
