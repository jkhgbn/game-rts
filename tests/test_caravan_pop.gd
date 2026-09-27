extends SceneTree
## Caravans cost no supply (user 2026-09-27: "make caravan no supply"): caravan.tres pop = 0, a Bazaar queues one,
## and a trained caravan leaves pop_used unchanged.
## Run:  godot --headless --path . -s tests/test_caravan_pop.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "caravan_pop"
const PLAYER := 0

var main: Node
var _wait := 0
var _frame := 0
var _market: Node = null
var _type: UnitType
var _pop_before := 0


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
		_type = UnitType.find("caravan")
		if _type == null:
			return _fail("no caravan UnitType")
		if _type.pop != 0:
			return _fail("caravan pop is %d (want 0)" % _type.pop)
		var mtype: BuildingType = null
		for t in BuildingType.buildable_for(&"fire"):
			if t.kind == &"market":
				mtype = t
		if mtype == null:
			return _fail("no Fire market BuildingType")
		_market = main.build_grid.spawn_complete(mtype, main.call(&"market_slot", PLAYER), PLAYER)
		var eco := Economy.for_team(PLAYER)
		eco.add(1000)
		return false
	if _frame == 2:
		_pop_before = Economy.for_team(PLAYER).pop_used   # pop_used is recounted from the living units
		return false
	if _frame == 3:
		var why := String(_market.call(&"can_queue", _type))
		if why != "":
			return _fail("Bazaar refuses a caravan at the pop cap: '%s'" % why)
		var err := String(_market.call(&"queue_unit", _type))
		if err != "":
			return _fail("queue_unit refused: '%s'" % err)
		return false
	if _frame > 3 and _frame % 30 == 0:
		var eco := Economy.for_team(PLAYER)
		if eco.pop_used != _pop_before:
			return _fail("pop_used %d -> %d after a caravan" % [_pop_before, eco.pop_used])
		if Market.caravan_count(PLAYER) >= 1 and _caravan_alive():
			print("PASS %s (caravan trained at pop %d / %d)" % [TASK_ID, eco.pop_used, eco.pop_cap])
			return true
	if _frame > 3000:
		return _fail("no caravan trained in 50 s")
	return false


func _caravan_alive() -> bool:
	for n in get_nodes_in_group("caravans"):
		if int(n.get(&"team")) == PLAYER:
			return true
	return false


func _fail(why: String) -> bool:
	print("FAIL %s: %s" % [TASK_ID, why])
	return true
