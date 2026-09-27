extends SceneTree
## Pop 200 (JS playtest request 2026-09-27, docs/design/economy.md "Population"): every kingdom's hard cap is 200;
## keep +20 and every house +20, max 9 houses: for each kingdom (Fire, Shadow, Ice, Nature) a keep + 9 houses give
## pop cap 200 (180 with 8), a 10th house is refused with the limit message, an extra pop source can't lift the cap
## above 200; units then train up to 200 (the last one fits, the next is refused "Population cap reached").
## The bot has 9 house rows (V1-V9).
## Run:  godot --headless --path . -s tests/test_pop_200.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "pop_200"
const TIMEOUT_FRAMES := 3000
const SETUP := 5
const BASE := Vector3(30.0, 0.0, 30.0)   # ENEMY team, empty ground on the mission 1 map (test_8_s1)
const KINGDOMS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
const HOUSES := {&"fire": "fire_hearth", &"shadow": "shadow_hovel", &"ice": "ice_lodge", &"nature": "nature_hollow"}

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _k := 0                     # index in KINGDOMS
var _next_at := SETUP           # frame of the next kingdom round
var _placed: Array[Building] = []
var _keep: TrainingBuilding
var _train_type: UnitType
var _training := false
var _results: Array[String] = []


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
		_check_static()
	if _k < KINGDOMS.size() and frame == _next_at:
		_round(KINGDOMS[_k])
		_k += 1
		_next_at = frame + 10
		if _k == KINGDOMS.size() and _errors.is_empty():
			_start_training()
	elif _training:
		if _tick_training():
			return _finish()
	if not _errors.is_empty():
		return _finish()
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out (training %s)" % _training)
		return _finish()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s: %s" % [TASK_ID, "; ".join(_results)])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


func _check_static() -> void:
	for k: StringName in KINGDOMS:
		if Economy.pop_cap_limit_for(k) != 200:
			_errors.append("pop_cap_limit_for(%s) = %d" % [k, Economy.pop_cap_limit_for(k)])
		var h := BuildingType.find(HOUSES[k])
		if h == null or h.pop_bonus != 20 or h.max_count != 9:
			_errors.append("%s: pop_bonus / max_count %s" % [HOUSES[k], "missing" if h == null else "%d / %d" % [h.pop_bonus, h.max_count]])
	var rows := 0
	for row: Dictionary in Commander.ROWS:
		if row["kind"] == &"house":
			rows += 1
	if rows != 9:
		_errors.append("bot house rows %d, not 9" % rows)


## Keep + 9 houses of kingdom `k` on the ENEMY team: 180 with 8, 200 with 9, the 10th refused, cap never above 200.
func _round(k: StringName) -> void:
	var grid: BuildGrid = main.build_grid
	var eco := Economy.for_team(Unit.Team.ENEMY)
	# Clear the previous kingdom's buildings (their pop bonus leaves with them).
	for b in _placed:
		if is_instance_valid(b):
			if b.is_alive():
				b.take_damage(1.0e8, null)
			b.queue_free()
	_placed.clear()
	var base_cap := eco.pop_cap   # 0 once the previous round's buildings are gone
	if base_cap != 0:
		_errors.append("%s: cap %d before the keep (previous round not cleared)" % [k, base_cap])
		return
	var house := BuildingType.find(HOUSES[k])
	var keep_t := BuildingType.find("%s_keep" % k)
	var kp := grid.find_spot(BuildingType.find("%s_barracks" % k), BASE, Unit.Team.ENEMY)
	if kp == Vector3.INF or keep_t == null or house == null:
		_errors.append("%s: no keep spot / type" % k)
		return
	_keep = grid.spawn_complete(keep_t, kp, Unit.Team.ENEMY) as TrainingBuilding
	_placed.append(_keep)
	if eco.kingdom != k or eco.max_pop_cap != 200 or eco.pop_cap != 20:
		_errors.append("%s keep: kingdom %s, max %d, cap %d" % [k, eco.kingdom, eco.max_pop_cap, eco.pop_cap])
		return
	var p10 := Vector3.INF
	for i in 9:
		if i == 8:
			p10 = grid.find_spot(house, BASE + Vector3(14.0, 0.0, -16.0), Unit.Team.ENEMY)   # still allowed: 8 < 9
			if eco.pop_cap != 180:
				_errors.append("%s: keep + 8 houses = %d, not 180" % [k, eco.pop_cap])
		var p := grid.find_spot(house, BASE + Vector3(-9.0 + (i % 3) * 5.0, 0.0, -8.0 - (i / 3) * 5.0), Unit.Team.ENEMY)
		var why := grid.check(house, p, Unit.Team.ENEMY) if p != Vector3.INF else "no spot"
		if why != "":
			_errors.append("%s house %d refused: %s" % [k, i + 1, why])
			return
		_placed.append(grid.spawn_complete(house, p, Unit.Team.ENEMY))
	if eco.pop_cap != 200:
		_errors.append("%s: keep + 9 houses = %d, not 200" % [k, eco.pop_cap])
	var r10 := grid.check(house, p10, Unit.Team.ENEMY) if p10 != Vector3.INF else "no spot"
	if r10 != BuildGrid.limit_message(house):
		_errors.append("%s 10th house: '%s'" % [k, r10])
	# A pop source past the rules still can't lift the cap above 200.
	eco.add_pop_bonus(40)
	if eco.pop_cap != 200:
		_errors.append("%s: cap above 200: %d" % [k, eco.pop_cap])
	eco.add_pop_bonus(-40)
	_results.append("%s 1+9 houses -> %d" % [k, eco.pop_cap])


## The last kingdom's keep trains up to 200: pop_used filled to 199, one worker fits, the next is refused.
func _start_training() -> void:
	var eco := Economy.for_team(Unit.Team.ENEMY)
	var types: Array[UnitType] = _keep.trainable_types()
	if types.is_empty():
		_errors.append("keep trains nothing")
		return
	_train_type = types[0]
	eco.add(100000)
	var fill := 200 - eco.pop_used - _train_type.pop
	if fill < 0:
		_errors.append("pop_used %d already over 199" % eco.pop_used)
		return
	eco.reserve_pop(fill)   # stands in for 180-odd living units (perf: the smoke / perf tests cover big armies)
	var r1 := _keep.queue_unit(_train_type)
	if r1 != "":
		_errors.append("unit %d / 200 refused: %s" % [eco.pop_used + _train_type.pop, r1])
		return
	var r2 := _keep.can_queue(_train_type)
	if r2 != TrainingBuilding.REASON_POP_CAP:
		_errors.append("over 200 not refused: '%s' (pop %d / %d)" % [r2, eco.pop_used, eco.pop_cap])
		return
	_training = true


func _tick_training() -> bool:
	var eco := Economy.for_team(Unit.Team.ENEMY)
	if not _keep.queue.is_empty():
		return false
	if eco.pop_used != 200 or eco.pop_cap != 200:
		_errors.append("after the spawn: pop %d / %d" % [eco.pop_used, eco.pop_cap])
	else:
		_results.append("trained to %d / %d" % [eco.pop_used, eco.pop_cap])
	return true
