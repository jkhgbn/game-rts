extends SceneTree
## WS2.G2 (wave-strike.md 14.2 P1): UnitGrid. 300 random units (3 teams, mixed types, some stacked on one spot for
## exact ties, some prefer_casters / hidden) wander for 120 frames; every frame, every unit's grid query
## (_find_nearest_enemy with a UnitGrid in the level) must return the same target as the old full scan, at its
## aggro range and at a random 4-30 m radius. Mid-run: kills, new spawns and set_down teleports in the same frame.
## Also: no grid = the old scan; cost per query printed (grid vs scan, 14.2 target <= 15 us at 400).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_unit_grid.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "unit_grid"
const COUNT := 300
const FRAMES := 120
const IDS := [&"flame_guard", &"ember_archer", &"shade", &"nightbolt", &"blaze_rider", &"gloam_rider"]

var main: Node
var frame := 0
var _wait := 0
var _rng := RandomNumberGenerator.new()
var _units: Array[Unit] = []
var _grid: UnitGrid
var _queries := 0
var _found := 0
var _ties := 0
var _errors: Array[String] = []


func _initialize() -> void:
	_rng.seed = 20261013
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
		_setup()
		return false
	if frame == 2:
		# No grid: _find_nearest_enemy is the old scan.
		for u in _units:
			if u._find_nearest_enemy(u.aggro_range) != u._find_nearest_enemy_scan(u.aggro_range):
				_errors.append("no-grid path differs from the scan")
				break
		_grid = UnitGrid.ensure(main)
		return false
	_churn()
	_compare()
	if frame >= FRAMES + 2:
		_timing()
		_finish()
		return true
	return false


func _setup() -> void:
	for i in COUNT:
		_spawn(_random_pos())
	# 12 stacks of 3 units on one exact spot: equal distances, the tie-break must match.
	for s in 12:
		var p := _random_pos()
		for k in 3:
			_spawn(p)


func _spawn(p: Vector3) -> Unit:
	var u: Unit = main.make_unit(str(IDS[_rng.randi() % IDS.size()]))
	u.set(&"team", [Unit.Team.PLAYER, Unit.Team.ENEMY, Unit.Team.NEUTRAL][_rng.randi() % 3])
	main.add_child(u)
	u.global_position = p
	u.prefer_casters = _rng.randf() < 0.2
	if _rng.randf() < 0.05:
		u.hide_from_auto_target(0.5)
	if _rng.randf() < 0.5:
		u.command_move(_random_pos())
	_units.append(u)
	return u


func _random_pos() -> Vector3:
	return Vector3(_rng.randf_range(-50.0, 50.0), 0.0, _rng.randf_range(-50.0, 50.0))


## Same-frame changes the grid must notice: deaths, new units, teleports, new move orders.
func _churn() -> void:
	if frame % 10 == 0:
		for k in 3:
			var u := _pick()
			if u != null:
				u.take_damage(99999.0, null)
		_spawn(_random_pos())
	if frame % 7 == 0:
		var u := _pick()
		if u != null:
			u.set_down(_random_pos())
	for k in 5:
		var u := _pick()
		if u != null:
			u.command_move(_random_pos())


## A random living unit of the test, or null.
func _pick() -> Unit:
	var v: Variant = _units[_rng.randi() % _units.size()]
	if not is_instance_valid(v):
		return null
	var u := v as Unit
	return u if u.is_alive() else null


func _compare() -> void:
	for u in _units:
		if not is_instance_valid(u) or not u.is_alive():
			continue
		for r: float in [u.aggro_range, _rng.randf_range(4.0, 30.0)]:
			var a := u._find_nearest_enemy(r)
			var b := u._find_nearest_enemy_scan(r)
			_queries += 1
			if b != null:
				_found += 1
				if a != null and a != b and is_equal_approx(_d(u, a), _d(u, b)):
					_ties += 1
			if a != b and _errors.size() < 8:
				_errors.append("frame %d: %s r=%.1f grid %s scan %s" % [frame, u.name, r, _n(a), _n(b)])


## Cost per query at 400 units (14.2 target: <= 15 us), best of 5 rounds; grid vs the old scan, and the re-bin.
func _timing() -> void:
	while _live().size() < 400:
		_spawn(_random_pos())
	var live := _live()
	var best_grid := 1 << 30
	var best_scan := 1 << 30
	var best_bin := 1 << 30
	for round_i in 5:
		UnitGrid.mark_dirty()
		var t := Time.get_ticks_usec()
		_grid.prepare()
		best_bin = mini(best_bin, Time.get_ticks_usec() - t)
		t = Time.get_ticks_usec()
		for u in live:
			u._find_nearest_enemy_grid(_grid, u.aggro_range)
		best_grid = mini(best_grid, Time.get_ticks_usec() - t)
		t = Time.get_ticks_usec()
		for u in live:
			u._find_nearest_enemy_scan(u.aggro_range)
		best_scan = mini(best_scan, Time.get_ticks_usec() - t)
	var n := float(live.size())
	print("unit_grid: %d units, per query grid %.1f us / old scan %.1f us, re-bin %d us (once per physics frame)" % [
			live.size(), best_grid / n, best_scan / n, best_bin])


func _live() -> Array[Unit]:
	var out: Array[Unit] = []
	for v: Variant in _units:
		if is_instance_valid(v) and (v as Unit).is_alive():
			out.append(v as Unit)
	return out


func _finish() -> void:
	print("unit_grid: %d queries, %d with a target, %d mismatches listed" % [_queries, _found, _errors.size()])
	if _ties > 0:
		_errors.append("%d equal-distance picks differed" % _ties)
	if _found < _queries / 4:
		_errors.append("too few queries found a target (%d / %d): the test is not exercising anything" % [_found, _queries])
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])


static func _d(a: Unit, b: Unit) -> float:
	return Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()


static func _n(u: Unit) -> String:
	return "null" if u == null else str(u.name)
