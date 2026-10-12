extends SceneTree
## Review 2026-10-12 R4-2: BuildGrid.place pushes own units out of a new footprint without breaking their work.
## In a skirmish, a gathering worker, a trading caravan, a champion and an idle soldier stand inside the footprint
## of a Hearth the player places: all leave the footprint, the worker still gathers, the caravan still trades, the
## champion got no order (order_serial unchanged), the idle soldier walks out (ordered, as before).
## Run:  godot --headless --path . -s tests/test_botfix_buildpush.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "botfix_buildpush"
const PLAYER := 0

var main: Node
var _wait := 0
var _frame := 0
var _worker: Unit
var _caravan: Unit
var _champion: Unit
var _soldier: Unit
var _champ_serial := 0
var _soldier_serial := 0
var _worker_serial := 0
var _caravan_serial := 0
var _rect := Rect2()
var _hearth: BuildingType


func _initialize() -> void:
	main = load("res://scenes/skirmish.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			return _fail("navigation never finished baking")
		return false
	_frame += 1
	if _frame == 1:
		return _setup()
	if _frame == 90:
		return _place()
	if _frame == 91:
		return _check_out("right after the place")
	if _frame == 300:
		if _check_out("4 s later"):
			return true
		if _soldier.global_position.distance_to(_soldier_start) < 0.5:
			return _fail("the idle soldier was not walked out")
		print("PASS %s" % TASK_ID)
		return true
	return false


var _soldier_start := Vector3.ZERO


func _setup() -> bool:
	Economy.for_team(PLAYER).add(2000)
	var mtype := BuildingType.find("fire_market")
	if mtype == null:
		return _fail("no fire_market")
	main.build_grid.spawn_complete(mtype, main.call(&"market_slot", PLAYER), PLAYER)
	var keep: Node3D = main.keep
	var node: CrystalNode = null
	for n in get_nodes_in_group("crystal_nodes"):
		var c := n as CrystalNode
		if c and (node == null or c.global_position.distance_to(keep.global_position) \
				< node.global_position.distance_to(keep.global_position)):
			node = c
	if node == null:
		return _fail("no crystal node")
	_worker = _spawn("cinder_hand", keep.global_position + Vector3(6.0, 0.0, 6.0))
	_worker.call(&"command_gather", node)
	_caravan = _spawn("caravan", main.call(&"market_slot", PLAYER) + Vector3(4.0, 0.0, 0.0))
	_soldier = _spawn("flame_guard", keep.global_position + Vector3(-6.0, 0.0, 6.0))
	var cs: Variant = load("res://scripts/units/champion.gd")
	var ts: Variant = load("res://scripts/units/champion_type.gd")
	if not (cs is GDScript) or not (ts is GDScript):
		return _fail("no champion scripts")
	_champion = (cs as GDScript).new() as Unit
	var types: Variant = (ts as GDScript).call(&"all")
	if not (types is Array) or (types as Array).is_empty():
		return _fail("no champion types")
	_champion.call(&"apply_champion_type", types[0])
	_champion.team = Unit.Team.PLAYER
	main.add_child(_champion)
	_champion.global_position = keep.global_position + Vector3(0.0, 0.0, 8.0)
	_hearth = BuildingType.find("fire_hearth")
	return false


func _spawn(id: String, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(id)
	u.team = Unit.Team.PLAYER
	main.add_child(u)
	u.global_position = pos
	return u


func _place() -> bool:
	if not bool(_worker.call(&"is_gathering")):
		return _fail("the worker is not gathering before the place")
	if StringName(_caravan.get(&"trade_state")) == &"idle":
		return _fail("the caravan is not trading before the place")
	var grid: BuildGrid = main.build_grid
	var spot: Vector3 = grid.find_spot(_hearth, main.keep.global_position + Vector3(14.0, 0.0, 10.0), PLAYER)
	if spot == Vector3.INF:
		return _fail("no hearth spot")
	spot = grid.snap(spot, _hearth.footprint)
	_rect = Rect2(Vector2(spot.x, spot.z) - Vector2(_hearth.footprint) * BuildGrid.CELL * 0.5,
			Vector2(_hearth.footprint) * BuildGrid.CELL)
	var offs := [Vector3(0.4, 0.0, 0.3), Vector3(-0.4, 0.0, -0.3), Vector3(0.3, 0.0, -0.4), Vector3(-0.3, 0.0, 0.4)]
	var units: Array[Unit] = [_worker, _caravan, _champion, _soldier]
	for i in units.size():
		units[i].global_position = Vector3(spot.x, units[i].global_position.y, spot.z) + offs[i]
	_soldier_start = _soldier.global_position
	_champ_serial = _champion.order_serial
	_soldier_serial = _soldier.order_serial
	_worker_serial = _worker.order_serial
	_caravan_serial = _caravan.order_serial
	var why := grid.check(_hearth, spot, PLAYER)
	if why != "":
		return _fail("check refused: '%s'" % why)
	if grid.place(_hearth, spot, PLAYER, []) == null:
		return _fail("place failed: '%s'" % grid.last_reason)
	if _champion.order_serial != _champ_serial:
		return _fail("the champion got an order from the push")
	if _worker.order_serial != _worker_serial:
		return _fail("the gathering worker got an order from the push")
	if _caravan.order_serial != _caravan_serial:
		return _fail("the trading caravan got an order from the push")
	if _soldier.order_serial <= _soldier_serial:
		return _fail("the idle soldier was not ordered out")
	return _check_out("in the place frame")


func _check_out(when: String) -> bool:
	for u: Unit in [_worker, _caravan, _champion]:
		var p := Vector2(u.global_position.x, u.global_position.z)
		if _rect.grow(u.radius * 0.5).has_point(p):
			return _fail("%s still in the footprint %s" % [u.name, when])
	if not bool(_worker.call(&"is_gathering")):
		return _fail("the worker stopped gathering %s" % when)
	if StringName(_caravan.get(&"trade_state")) == &"idle":
		return _fail("the caravan stopped trading %s" % when)
	return false


func _fail(why: String) -> bool:
	print("FAIL %s: %s" % [TASK_ID, why])
	return true
