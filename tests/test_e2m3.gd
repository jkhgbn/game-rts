extends SceneTree
## Mission e2m3 "The Salt Road" (docs/design/mission-e2-03.md, acceptance checks 1-7 scripted through MissionHarness;
## the real-fight timing run is tests/test_e2m3_sim.gd). Parts:
##   start    the trade map (river, 4 posts, 2 Lodges, 2 Dens), Fire Stronghold + 13 soldiers, Malrik's base with a
##            Gloom Bazaar and 2 caravans, Bettany, gold 0, posts open at 1:30 (shifted clock), the Stables card puts
##            the Emberdart Harrier on V, the Ember Hall has no Blaze Rider, Malrik L5.
##   tribute  refusals in order (No Bazaar, Not enough gold, No caravan, Tribute already on the road); with a Bazaar,
##            a caravan and 250 gold: spends 250, walks the route, pays in 2 s (1 / 6), E10; a tribute caravan killed
##            drops 250 gold in sacks; the Tollgate rises at 6:00 (E8, sec_toll).
##   end      6 tributes -> obj_guides (1:30), W4; the hold ends -> victory, rewards e2m3 (next e2m4).
##   keep     the Fire keep destroyed = defeat (L32).
## Run: godot --headless --path . -s tests/test_e2m3.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e2m3"
const MISSION := "res://missions/mission_e2_03.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "tribute", "end", "keep"]
var _part := ""
var h: MissionHarness
var main: MissionE2_03
var _errors: Array[String] = []
var _v := {}
var _t0 := 0
var _gap := 0
var _finished := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_parts = [a.trim_prefix("--only=")]
	_open_next()


func _process(_delta: float) -> bool:
	if _finished:
		return true
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_open_next()
		return _finished
	if h == null or main == null:
		return _finished
	if h.tick():
		for e in h.errors:
			_errors.append("%s: %s" % [_part, e])
		main.queue_free()
		main = null
		h = null
		_gap = GAP_FRAMES
	return _finished


func _open_next() -> void:
	if _parts.is_empty():
		_finished = true
		print("PASS %s" % TASK_ID if _errors.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return
	_part = _parts.pop_front()
	_v = {}
	h = MissionHarness.new()
	h.task_id = "%s/%s" % [TASK_ID, _part]
	h.timeout_frames = 40000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e2m3_none.json"}}) as MissionE2_03
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
			h.steps.add("posts open at 1:30", _posts, 6000)
		"tribute":
			h.steps.add("refusals", _refusals, 120)
			h.steps.add("tribute walks and pays", _tribute, 6000)
			h.steps.add("a lost tribute drops its gold", _lost, 3000)
			h.steps.add("the Tollgate at 6:00", _tollgate, 1200)
		"end":
			h.steps.add("6 tributes: the guides hold", _paid, 600)
			h.steps.add("victory", _victory, 9000)
		"keep":
			h.steps.add("Fire keep destroyed = defeat", _keep_loss, 600)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _start() -> bool:
	_ok(not Teams.multi, "1v1 seats")
	_ok(main.trade_network != null and main.trade_posts.size() == 4 and main.guild_houses.size() == 4, "trade map")
	_ok(main.river != null, "river on")
	_ok(main.keep.tier == 2, "Stronghold")
	var army := _units(0, "flame_guard").size() + _units(0, "ember_archer").size() + _units(0, "blaze_rider").size() \
			+ _units(0, "kilnwarden").size()
	_ok(army == 13, "13 start soldiers (%d)" % army)
	_ok(main.gloom_bazaar != null and _units(1, "caravan").size() == 2, "Malrik's Bazaar + 2 caravans")
	_ok(main.bettany != null and main.is_dormant(main.bettany), "Bettany at the Lodge door")
	_ok(GoldBank.for_team(0).gold == 0, "gold 0")
	_ok(main.shadow_hero.level == 5, "Malrik L5")
	var hall: Array[UnitType] = main.ember_hall.trainable_types()
	_ok(not hall.any(func(t: UnitType) -> bool: return t.id == &"blaze_rider"), "no Blaze Rider at the Ember Hall")
	var sb := StablesBuilding.new()
	sb.building_type = BuildingType.find("fire_stables")
	var card := sb.trainable_types()
	_ok(card.size() >= 4 and card[3].id == &"emberdart_harrier" and card[0].id == &"blaze_rider", "Stables: Harrier on V")
	sb.free()
	_ok(Stables16.enabled_here(), "Stables on in this mission (cavalry_enabled)")
	_ok(not ForgeKit.enabled_for(main), "no Forge here (forge_enabled false)")
	main.forge_enabled = true
	_ok(ForgeKit.enabled_for(main), "forge_enabled turns the Forge on in a mission (e2m4 knob)")
	main.forge_enabled = false
	_ok(not main.trade_network.is_open(), "posts closed at 0:00")
	_ok(h.saw("obj_bazaar", "active") and h.saw("obj_tribute", "active"), "objectives")
	return true


func _posts() -> bool:
	if not _v.has("skip"):
		_v["skip"] = true
		MissionHarness.skip_time(main, 88.0)
		return false
	if main.trade_network.is_open():
		_ok(main.mission_time() >= 89.0 and main.mission_time() <= 92.0, "open at %.0f s" % main.mission_time())
		return true
	return false


func _bazaar() -> Building:
	var m := main.build_grid.spawn_complete(BuildingType.find("fire_market"), Vector3(-45.0, 0.0, 27.0), Unit.Team.PLAYER)
	return m


func _refusals() -> bool:
	_ok(main.send_tribute() == "No Bazaar", "No Bazaar")
	var m := _bazaar()
	_v["m"] = m
	_ok(main.send_tribute() == "Not enough gold", "Not enough gold")
	GoldBank.for_team(0).add(1000)
	_ok(main.send_tribute() == "No caravan", "No caravan")
	var c := main._spawn(main.make_unit("caravan"), Unit.Team.PLAYER, m.global_position + Vector3(7.0, 0.0, 7.0))
	MissionHarness.immortal(c)
	_v["c"] = c
	return true


func _tribute() -> bool:
	if not _v.has("sent"):
		if h.frame % 30 != 0:
			return false
		var r := main.send_tribute()
		if r != "":
			if not _v.has("why"):
				_v["why"] = r
				print("  tribute refused: %s (caravans %d)" % [r, Market.of_team(0).caravans().size()])
			return false
		_v["sent"] = true
		_ok(GoldBank.for_team(0).gold == 1000 - main.tribute_gold(), "the tribute spent (%d)" % GoldBank.for_team(0).gold)
		_ok(main.send_tribute() == "Tribute already on the road", "one at a time")
		return false
	if h.frame % 600 == 0 and main.tribute_caravan:
		print("  tribute at %s wp %d cargo %d state %s" % [main.tribute_caravan.global_position, main._wp,
				int(main.tribute_caravan.get(&"cargo")), main.tribute_caravan.get(&"trade_state")])
	if main.tributes_paid == 1:
		_ok(main.has_fired(&"E10") and main.said.has(13), "E10: L13")
		return true
	return false


func _lost() -> bool:
	if not _v.has("l"):
		_v["l"] = true
		(_v["c"] as Unit).death_guard = Callable()
		_ok(main.send_tribute() == "", "second tribute ordered (queued until the caravan is home)")
		return false
	if main.tribute_caravan != null and not _v.has("k"):
		var c: Unit = main.tribute_caravan
		if int(c.get(&"cargo")) > 0:
			_v["k"] = true
			c.set_meta(&"e2m3_cargo", int(c.get(&"cargo")))
			c.take_damage(1.0e7, null)
			_t0 = h.frame
		return false
	if _v.has("k") and h.frame - _t0 > 30:
		var total := 0
		for s in main.get_tree().current_scene.find_children("*", "", true, false):
			if s is LootSack:
				total += int((s as LootSack).amount)
		_ok(total >= main.tribute_gold(), "sacks hold the whole tribute (%d)" % total)
		_ok(main.said.has(15), "E11: L15")
		return true
	return false


func _tollgate() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.skip_time(main, maxf(0.0, MissionE2_03.TOLLGATE_AT - main.mission_time() + 1.0))
		return false
	if main.tollgate != null:
		_ok(main.has_fired(&"E8") and h.saw("sec_toll", "active") and main.said.has(10), "E8 / sec_toll / L10")
		return true
	return false


func _paid() -> bool:
	if not _v.has("p"):
		_v["p"] = true
		main.tributes_paid = 5
		main._tribute_amount = main.tribute_gold()
		main.tribute_caravan = main._spawn(main.make_unit("caravan"), Unit.Team.PLAYER, MissionE2_03.LODGE_DOOR)
		main._pay_tribute()
		return false
	_ok(h.saw("obj_tribute", "done") and main.guides_left > 0.0, "obj_guides counting (%.0f)" % main.guides_left)
	_ok(main.wave_units.has(&"W4"), "W4 Reprisal")
	return true


func _victory() -> bool:
	if not _v.has("e"):
		_v["e"] = true
		main.guides_left = 0.5
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory (%d)" % h.ended)
	var r: Dictionary = CampaignState.reward_of(&"e2m3")
	_ok(r.get("next") == &"e2m4" and (r.get("set_flags", {}) as Dictionary).get("e2m3_lodge_paid") == true, "rewards %s" % str(r))
	return true


func _keep_loss() -> bool:
	if not _v.has("k"):
		_v["k"] = true
		main.keep.take_damage(1.0e7, null)
		return false
	if h.ended == 0:
		_ok(main.said.has(32), "E23: L32")
		return true
	return false
