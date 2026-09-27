extends SceneTree
## Task 8.S1 (docs/design/kingdom-nature.md section 4 + 1): the 4 Nature BuildingTypes with the spec
## numbers and build menu (Z X C), a Nature team's pop cap reaches 50 (Fire stays 40) and a 4th Seed
## Hollow is refused, a damaged Grove Hall regains 1 % / s only after 10 s without damage, friendly
## non-worker units within 8 m of a Bramble Spire get +2 hp_regen (`aura:bramble`), and a frozen worker
## pauses its mining timer and the site it builds (rooted workers keep working).
## Run:  godot --headless --path . -s tests/test_8_s1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "8.S1"
const TIMEOUT_FRAMES := 2400
const SETUP := 5
const NATURE_BASE := Vector3(30.0, 0.0, 30.0)   # ENEMY team (no buildings on the mission 1 map)
const HALL_DAMAGE := 400.0
const MINING := 3                                # Worker.GatherState.MINING

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _done := {}

var _hall: Building
var _hall_hp := 0.0
var _spire: Building
var _near: Unit        # Thornling 5 m from the spire
var _far: Unit         # Thornling 12 m away
var _worker_near: Unit # Sprigling 5 m away (workers get no aura)
var _base_regen := 0.0
var _site: Building
var _builder: Unit
var _site_progress := 0.0
var _miner: Unit
var _mine_frame := -1
var _mine_left := 0.0


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
	if frame == SETUP:
		_check_types()
		_check_pop_cap()
		_setup_regen()
		_setup_aura()
		_setup_site()
	elif frame > SETUP:
		_tick_regen()
		_tick_aura()
		_tick_site()
		_tick_mining()
	if not _errors.is_empty():
		return _finish()
	if _done.size() >= 4:
		return _finish()
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out (done: %s)" % str(_done.keys()))
		return _finish()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


# ---------------------------------------------------------------- data

func _check_types() -> void:
	# id: [cost, build_time, max_hp, footprint, height, pop_bonus, max_count, hotkey, kind]
	var spec := {
		&"nature_keep": [0, 0.0, 2250.0, Vector2i(3, 3), 6.0, 20, 0, "", &"keep"],
		&"nature_barracks": [130, 38.0, 1170.0, Vector2i(3, 3), 4.0, 0, 0, "X", &"barracks"],
		&"nature_hollow": [60, 20.0, 450.0, Vector2i(2, 2), 3.0, 10, 3, "Z", &"house"],
		&"nature_tower": [100, 30.0, 675.0, Vector2i(1, 1), 5.0, 0, 4, "C", &"tower"],
	}
	for id: StringName in spec:
		var t := BuildingType.find(String(id))
		if t == null:
			_errors.append("no BuildingType %s" % id)
			continue
		var s: Array = spec[id]
		var got := [t.cost, t.build_time, t.max_hp, t.footprint, t.height, t.pop_bonus, t.max_count,
				t.hotkey_label, t.kind]
		if str(got) != str(s):
			_errors.append("%s is %s, spec %s" % [id, str(got), str(s)])
		if t.faction != &"nature" or not is_equal_approx(t.idle_regen_pct, 1.0) or not t.counts_for_defeat:
			_errors.append("%s faction %s / idle_regen_pct %.1f" % [id, t.faction, t.idle_regen_pct])
	var names := [BuildingType.find("nature_keep"), BuildingType.find("nature_barracks"),
			BuildingType.find("nature_hollow"), BuildingType.find("nature_tower")]
	if names.has(null):
		return
	var dn := []
	for t: BuildingType in names:
		dn.append(t.display_name)
	if dn != ["Heartwood", "Grove Hall", "Seed Hollow", "Bramble Spire"]:
		_errors.append("display names %s" % str(dn))
	var spire := BuildingType.find("nature_tower")
	if spire.attack_damage != 10.0 or spire.attack_range != 10.0 or not is_equal_approx(spire.attack_cooldown, 1.2) \
			or spire.sight_radius != 15.0 or spire.aura_radius != 8.0 \
			or not is_equal_approx(float(spire.aura_stats.get(&"hp_regen", 0.0)), 2.0) or spire.aura_id != &"bramble":
		_errors.append("Bramble Spire attack / aura numbers differ from the spec")
	if not spire.projectile_color.is_equal_approx(Color(0.55, 0.40, 0.20)):
		_errors.append("Bramble Spire bolt colour %s" % str(spire.projectile_color))
	var ids: Array[StringName] = []
	for t in BuildingType.buildable_for(&"nature"):
		ids.append(t.id)
	if ids != [&"nature_hollow", &"nature_barracks", &"nature_tower"]:
		_errors.append("Nature build menu is %s" % str(ids))
	var keep := BuildingType.find("nature_keep")
	if keep.trains.size() != 1 or keep.trains[0].id != &"sprigling":
		_errors.append("Heartwood trains %s" % str(keep.trains))
	var hall := BuildingType.find("nature_barracks")
	var hall_ids := []
	for u in hall.trains:
		hall_ids.append(u.id)
	if hall_ids != [&"thornling", &"burr_slinger", &"bloomtender", &"bramblehorn"]:
		_errors.append("Grove Hall trains %s" % str(hall_ids))


# ---------------------------------------------------------------- pop cap 50, 3 hollows

func _check_pop_cap() -> void:
	var grid: BuildGrid = main.build_grid
	var eco := Economy.for_team(Unit.Team.ENEMY)
	var fire_eco := Economy.for_team(Unit.Team.PLAYER)
	if Economy.pop_cap_limit_for(&"nature") != 50 or Economy.pop_cap_limit_for(&"fire") != 40:
		_errors.append("pop_cap_limit_for nature / fire = %d / %d" % [Economy.pop_cap_limit_for(&"nature"),
				Economy.pop_cap_limit_for(&"fire")])
	var hollow := BuildingType.find("nature_hollow")
	var keep_t := BuildingType.find("nature_keep")
	# Keeps are never "buildable": look for a spot with the Grove Hall (same 3 x 3 footprint).
	var kp := grid.find_spot(BuildingType.find("nature_barracks"), NATURE_BASE, Unit.Team.ENEMY)
	if kp == Vector3.INF:
		_errors.append("no spot for the Heartwood")
		return
	grid.spawn_complete(keep_t, kp, Unit.Team.ENEMY)
	if eco.kingdom != &"nature" or eco.max_pop_cap != 50 or eco.pop_cap != 20:
		_errors.append("after the Heartwood: kingdom %s, max %d, cap %d" % [eco.kingdom, eco.max_pop_cap, eco.pop_cap])
	# The 4th hollow's spot, found while hollows are still allowed (find_spot skips refused spots).
	var p4 := grid.find_spot(hollow, NATURE_BASE + Vector3(0.0, 0.0, -16.0), Unit.Team.ENEMY)
	for i in 3:
		var p := grid.find_spot(hollow, NATURE_BASE + Vector3(-8.0, 0.0, -6.0 + i * 5.0), Unit.Team.ENEMY)
		if p == Vector3.INF or grid.check(hollow, p, Unit.Team.ENEMY) != "":
			_errors.append("hollow %d refused: %s" % [i + 1, grid.check(hollow, p, Unit.Team.ENEMY)])
			return
		grid.spawn_complete(hollow, p, Unit.Team.ENEMY)
	if eco.pop_cap != 50:
		_errors.append("Heartwood + 3 hollows: pop cap %d, not 50" % eco.pop_cap)
	var r4 := grid.check(hollow, p4, Unit.Team.ENEMY)
	if r4 != BuildGrid.MSG_LIMIT:
		_errors.append("4th hollow: '%s'" % r4)
	# Even a 4th pop source (bypassing the rules) can't lift the cap above 50.
	var extra := grid.spawn_complete(hollow, p4, Unit.Team.ENEMY)
	if eco.pop_cap != 50:
		_errors.append("pop cap above the Nature cap: %d" % eco.pop_cap)
	extra.take_damage(1.0e7, null)
	if eco.pop_cap != 50:
		_errors.append("pop cap after losing the extra hollow: %d" % eco.pop_cap)
	if fire_eco.max_pop_cap != 40 or fire_eco.pop_cap > 40:
		_errors.append("Fire cap changed: max %d, cap %d" % [fire_eco.max_pop_cap, fire_eco.pop_cap])


# ---------------------------------------------------------------- Grove Hall regen

func _setup_regen() -> void:
	var t := BuildingType.find("nature_barracks")
	var p: Vector3 = main.build_grid.find_spot(t, NATURE_BASE + Vector3(4.0, 0.0, 6.0), Unit.Team.ENEMY)
	if p == Vector3.INF:
		_errors.append("no spot for the Grove Hall")
		return
	_hall = main.build_grid.spawn_complete(t, p, Unit.Team.ENEMY)
	_hall.take_damage(HALL_DAMAGE, null)
	_hall_hp = _hall.hp


func _tick_regen() -> void:
	if _hall == null or _done.has("regen"):
		return
	var t := frame - SETUP   # frames since the hit (60 per second)
	if t == 590 and not is_equal_approx(_hall.hp, _hall_hp):
		_errors.append("Grove Hall regenerated before 10 s (%.1f -> %.1f)" % [_hall_hp, _hall.hp])
	if t == 900:
		# 1 % of 1170 per second from 10 s: +58.5 at 15 s (ticks of 0.5 s, 5.85 each).
		var gained := _hall.hp - _hall_hp
		if gained < 46.0 or gained > 71.0:
			_errors.append("Grove Hall gained %.1f HP in 5 s of regen, not ~58.5" % gained)
		_done["regen"] = true


# ---------------------------------------------------------------- Bramble Spire aura

func _setup_aura() -> void:
	var t := BuildingType.find("nature_tower")
	var home: Vector3 = main.keep.global_position + Vector3(8.0, 0.0, -10.0)
	var p: Vector3 = main.build_grid.find_spot(t, home, Unit.Team.PLAYER)
	if p == Vector3.INF:
		_errors.append("no spot for the Bramble Spire")
		return
	_spire = main.build_grid.spawn_complete(t, p, Unit.Team.PLAYER)
	_near = _spawn("thornling", _spire.global_position + Vector3(5.0, 0.0, 0.0))
	_far = _spawn("thornling", _spire.global_position + Vector3(0.0, 0.0, 12.0))
	_worker_near = _spawn("sprigling", _spire.global_position + Vector3(0.0, 0.0, -4.0))
	_base_regen = _near.get_stat(&"hp_regen")


func _tick_aura() -> void:
	if _spire == null or _done.has("aura") or frame != SETUP + 40:
		return
	var got := _near.get_stat(&"hp_regen") - _base_regen
	if not is_equal_approx(got, 2.0):
		_errors.append("Thornling 5 m from the spire: hp_regen +%.2f" % got)
	if not is_equal_approx(_far.get_stat(&"hp_regen"), _base_regen):
		_errors.append("Thornling 12 m away got the aura")
	if _worker_near.get_stat(&"hp_regen") > 0.0:
		_errors.append("a worker got the aura")
	_done["aura"] = true


func _spawn(type_id: String, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = Unit.Team.PLAYER
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


# ---------------------------------------------------------------- frozen builder / miner

func _setup_site() -> void:
	# A Bramble Spire site (the hollow limit is already reached for this team).
	var t := BuildingType.find("nature_tower")
	var p: Vector3 = main.build_grid.find_spot(t, NATURE_BASE + Vector3(8.0, 0.0, -8.0), Unit.Team.ENEMY)
	if p == Vector3.INF:
		_errors.append("no spot for the test site")
		return
	_site = BuildGrid.create_building(t)
	_site.team = Unit.Team.ENEMY
	_site.make_site()
	main.add_child(_site)
	_site.global_position = p
	_builder = main.make_unit("sprigling")
	_builder.team = Unit.Team.ENEMY
	main.add_child(_builder)
	_builder.global_position = p + Vector3(2.5, 0.0, 0.0)
	_builder.command_stop()
	_site.add_builder(_builder)


func _tick_site() -> void:
	if _site == null or _done.has("site"):
		return
	var t := frame - SETUP
	if t == 30:
		if _site.construction_progress() <= 0.0:
			_errors.append("the site does not progress with its builder")
		_builder.apply_status(&"frozen", 2.0)
		_site_progress = _site.construction_progress()
	elif t == 100:
		if _site.builder_count() != 1 or _site.build_speed() != 0.0:
			_errors.append("frozen builder: %d builders, speed %.2f" % [_site.builder_count(), _site.build_speed()])
		if not is_equal_approx(_site.construction_progress(), _site_progress):
			_errors.append("the site progressed while its builder was frozen")
	elif t == 200:
		if _site.construction_progress() <= _site_progress:
			_errors.append("the site did not resume after the thaw")
		# Rooted builders keep building (rooted stops movement only).
		_site_progress = _site.construction_progress()
		_builder.apply_status(&"rooted", 1.0)
	elif t == 230:
		if _site.construction_progress() <= _site_progress:
			_errors.append("the site paused for a rooted builder")
		_done["site"] = true


func _tick_mining() -> void:
	if _done.has("mining"):
		return
	if _miner == null:
		for node in get_nodes_in_group(&"units"):
			var w := node as Unit
			if w and w.team == Unit.Team.PLAYER and w.has_method(&"command_gather") and w.is_alive() \
					and int(w.get(&"gather_state")) == MINING and float(w.get(&"_mine_left")) > 2.0:
				_miner = w
				_miner.apply_status(&"frozen", 2.0)
				_mine_frame = frame
				_mine_left = float(w.get(&"_mine_left"))
				break
		return
	if frame == _mine_frame + 90:
		var left := float(_miner.get(&"_mine_left"))
		if not is_equal_approx(left, _mine_left) or int(_miner.get(&"gather_state")) != MINING:
			_errors.append("frozen worker's mining timer moved %.2f -> %.2f" % [_mine_left, left])
	elif frame == _mine_frame + 150:
		if float(_miner.get(&"_mine_left")) >= _mine_left:
			_errors.append("the mining timer did not resume after the thaw")
		_done["mining"] = true
