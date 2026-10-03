extends SceneTree
## Task M9.S3, the other branch (docs/design/mission-02.md): no mission 1 victory in the save (the debug start: Ember
## Crown in slot 1, essence 150 + 400, both flags false): the empty cart (L4b, the cart cache opens at once),
## 8:00 = L6a + the reinforcements from the Shadow road, the W2 wait rule (held while 3+ reinforcement units
## live, fires once they fall), then the dig reaches 100 % = L14, obj_dig failed, defeat.
## Run:  godot --headless --path . -s tests/test_m9_s3_defeat.gd --fixed-fps 60 --quit-after 20000

const TASK_ID := "m9.s3.defeat"
const SCENE := "res://missions/mission_02.tscn"

var h := MissionHarness.new()
var main: Node
var _wait := 0


func _initialize() -> void:
	h.task_id = TASK_ID
	main = h.open(self, SCENE, {"difficulty": 1, "set": {"campaign_save_path": "user://test_m9_none.json"}})
	h.steps.add("bake settles", func() -> bool:
		_wait += 1
		return _wait > 30, 100)
	h.steps.add("debug start", _start, 10)
	h.steps.add("E3 the empty cart", _e3, 10)
	h.steps.add("E3 fired", func() -> bool: return main.call(&"has_fired", &"E3"), 120)
	h.steps.add("8:00 reinforcements", _e6, 10)
	h.steps.add("E6 fired", func() -> bool: return main.call(&"has_fired", &"E6"), 120)
	h.steps.add("9:00 W2 waits", _w2_due, 10)
	h.steps.add("W2 held", _w2_held, 200)
	h.steps.add("W2 fires once they fall", func() -> bool: return (main.get(&"waves_fired") as Array).has(&"W2"), 200)
	h.steps.add("dig to 100 %", _dig_full, 10)
	h.steps.add("defeat", func() -> bool: return h.ended == 0, 600)
	h.steps.add("lines", _lines, 10)


func _process(_d: float) -> bool:
	return h.tick()


func _skip_to(t: float) -> void:
	MissionHarness.skip_time(main, maxf(0.0, t - float(main.call(&"mission_time"))))


func _start() -> bool:
	h.check(bool(main.get(&"no_save_fallback")), "no m01 victory = the debug start")
	var hero: Wizard = main.get(&"hero")
	var inv := ItemDrops.inventory_of(hero) as Inventory
	h.check(inv.find_slot(&"ember_crown") == Inventory.ARTIFACT_SLOT, "Ember Crown in slot 1 anyway")
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	h.check(bank.essence >= 550 and bank.essence < 560, "essence 150 + 400 (got %d)" % bank.essence)
	h.check(main.get(&"pell") == null and main.get(&"cart_cache") != null, "the empty cart is a cache")
	var cart: LostCache = main.get(&"cart_cache")
	h.check(cart.is_available(), "the cart cache opens at once")
	return true


func _e3() -> bool:
	MissionHarness.put(main.get(&"hero"), Mission02.PELL_POS + Vector3(8.0, 0.0, 4.0))
	return true


func _e6() -> bool:
	_skip_to(480.5)
	return true


func _w2_due() -> bool:
	var r: Array = main.get(&"reinforcements")
	h.check(r.size() == 6, "reinforcements: 3 Shades + 2 Nightbolts + 1 Grave Hound (got %d)" % r.size())
	for u: Unit in r:
		h.check(Vector2(u.global_position.x + 56.0, u.global_position.z + 30.0).length() < 25.0, "from the Shadow road")
		MissionHarness.immortal(u)
		u.command_stop()
	_skip_to(541.0)
	_wait = 0
	return true


func _w2_held() -> bool:
	_wait += 1
	if _wait < 120:
		return false
	h.check(not (main.get(&"waves_fired") as Array).has(&"W2"), "W2 waits while 3+ reinforcements live")
	for u: Unit in main.get(&"reinforcements"):
		u.death_guard = Callable()
	MissionHarness.kill(main.get(&"reinforcements"))
	return true


func _dig_full() -> bool:
	main.set(&"dig", 99.999)
	return true


func _lines() -> bool:
	var said: Array = main.get(&"said_ids")
	for id: StringName in [&"L1", &"L2", &"L3", &"L4b", &"L6a", &"L14"]:
		h.check(said.count(id) == 1, "%s once" % id)
	for id: StringName in [&"L4a", &"L6b", &"L13"]:
		h.check(not said.has(id), "%s not said" % id)
	h.check(h.saw("obj_dig", "failed"), "obj_dig failed")
	h.check(h.saw("sec_dig", "failed"), "sec_dig failed at 50 %")
	return true
