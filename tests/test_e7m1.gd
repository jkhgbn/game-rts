extends SceneTree
## Mission e7m1 "The Dragon Auction" (docs/design/mission-e7-01.md, scripted through MissionHarness; the real-fight run
## is tests/test_e7m1_sim.gd). Parts:
##   start    Torvald L4 (cap 7, the Splinter), Malrik the ALLY seat at L5, Ysolde + Vessa (ENEMY), 350 crystals,
##            0 gold, the Diamond Harbour 2 500, the Tollrock held by Aurivane, the Stronghold closed until 3:30.
##   auction  no Bazaar = "No Bazaar"; a lead refuses a second bid; the top bid wins and pays; the rock's word wins
##            within 10 %; short coffers lose ("check 3").
##   lose     Aurivane's second auction win = defeat.
##   final    A3 won with 2 wins: obj_hold, the hold runs out = victory (cinematics off), flags only, next c_e7_ledger.
## Run: godot --headless --path . -s tests/test_e7m1.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|...]

const TASK_ID := "e7m1"
const MISSION := "res://missions/mission_e7_01.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "auction", "lose", "final"]
var _part := ""
var h: MissionHarness
var main: MissionE7_01
var _errors: Array[String] = []
var _v := {}
var _gap := 0
var _finished := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_parts.assign(a.trim_prefix("--only=").split(","))
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
	h.timeout_frames = 12000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e7m1_none.json"}}) as MissionE7_01
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"auction":
			h.steps.add("bids, the rock's word, short coffers", _auction, 3000)
		"lose":
			h.steps.add("two Aurivane wins = defeat", _lose, 2000)
		"final":
			h.steps.add("A3, the hold, victory, flags", _final, 6000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _start() -> bool:
	var hero := main.hero
	_ok(hero.level == 4 and hero.level_cap == 7, "Torvald L4, cap 7")
	_ok(hero.spell_rank(&"rime_bolt") >= 1 and hero.spell_points == 3, "Rime Bolt, 3 points (%d)" % hero.spell_points)
	_ok(hero.get_stat(&"armor") >= 10.0, "the Splinter's armor")
	_ok(main.malrik != null and main.malrik.level == 5 and int(main.malrik.team) == Teams.ALLY, "Malrik, ALLY, L5")
	_ok(main.vessa != null and main.ysolde != null and int(main.vessa.team) == Unit.Team.ENEMY, "Vessa and Ysolde")
	_ok(_units(0, "rimeshield").size() == 6 and _units(0, "rime_hauler").size() == 5, "6 Rimeshields, 5 Haulers")
	_ok(Economy.for_team(0).crystals == 350, "350 crystals (%d)" % Economy.for_team(0).crystals)
	_ok(main.gold() == 0, "0 gold")
	_ok(main.harbour != null and is_equal_approx(main.harbour.max_hp, 2500.0), "the harbour 2 500")
	_ok(main.rock != null and main.rock_owner() == 1, "Aurivane holds the rock")
	_ok(main.tier_system != null and main.tier_system.max_tier == 1, "the Stronghold closed before 3:30")
	_ok(Teams.is_ally(0, Teams.ALLY) and Teams.is_hostile(0, 1), "ally / hostile teams")
	_ok(main.dragons.size() == 3, "three dragons waiting")
	return true


func _auction() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		m.rock.set_owner_side(-1)
		m.open_auction("gilt_dragon", "Kesh", 300)
		_ok(m.player_bid(50) == MissionE7Base.MSG_NO_BAZAAR, "no Bazaar refused")
		m.build_grid.spawn_complete(BuildingType.find("ice_market"), MissionE7Base.BAZAAR_SPOT, 0)
		_ok(m.player_bid(50) == MissionE7Base.MSG_NO_GOLD, "no gold refused")
		m.add_gold(1000)
		_ok(m.player_bid(100) == "", "bid 100")
		_ok(m.player_bid(50) == MissionE7Base.MSG_LEAD, "a lead refuses")
		m.rock.set_owner_side(-1)
		m.auction["ends"] = m.mission_time() + 12.0
		return false
	if not _v.has("b"):
		if m.auction_open():
			var bids: Array = m.auction["bids"]
			if int(bids[1]) > int(bids[0]):
				m.player_bid(50)
			return false
		_v["b"] = true
		_ok(m.auction_log.size() == 1 and m.auction_log[0].begins_with("gilt_dragon:0:"), "the top bid wins (%s)" % str(m.auction_log))
		_ok(m.gold() < 1000 and m.gold() >= 600, "the winner pays (%d)" % m.gold())
		# the rock's word: Aurivane leads 500 vs 470 and side 0 holds the rock -> side 0
		m.rock.set_owner_side(0)
		m.open_auction("prism_dragon", "Morrow", 500)
		m.auction["bids"] = [470, 500]
		m.auction["next_ai"] = 1.0e9
		m.auction["ends"] = m.mission_time()
		return false
	if not _v.has("c"):
		if m.auction_open():
			return false
		_v["c"] = true
		_ok(m.auction_log.size() == 2 and m.auction_log[1].begins_with("prism_dragon:0:470"), "the rock's word (%s)" % str(m.auction_log))
		# short coffers: side 0 leads with more than it holds
		m.rock.set_owner_side(-1)
		m.open_auction("ossavar_story", "Ossavar", 100)
		m.auction["bids"] = [m.gold() + 500, 100]
		m.auction["next_ai"] = 1.0e9
		m.auction["ends"] = m.mission_time()
		return false
	if m.auction_open():
		return false
	_ok(m.auction_log.size() == 3 and m.auction_log[2].begins_with("ossavar_story:1:100"), "short coffers lose (%s)" % str(m.auction_log))
	_ok(m.dragon("gilt_dragon") != null and int(m.dragon("gilt_dragon").team) == 0, "Kesh fights for side 0")
	_ok(not m.dragon("gilt_dragon").is_commandable(), "a dragon is never commandable")
	return true


func _lose() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		m._on_hammer(&"gilt_dragon", 1, 300)
		_ok(h.ended < 0, "one loss is not a defeat")
		m._on_hammer(&"prism_dragon", 1, 300)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0, "two Aurivane wins = defeat")
	_ok(m.said.has("L33"), "L33")
	return true


func _final() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		m.harbour.setup(1.0e6, 0.0)
		for id: StringName in [&"E10", &"E11", &"guard", &"A0", &"A1", &"A2"]:
			m.fire_once(id)
		m._on_hammer(&"gilt_dragon", 0, 300)
		m._on_hammer(&"prism_dragon", 1, 300)
		MissionHarness.skip_time(m, 1240.0 - m.mission_time())
		return false
	if not _v.has("b"):
		if m.mission_time() < 1241.0:
			return false
		_v["b"] = true
		m.rock.set_owner_side(0)
		m._on_hammer(&"ossavar_story", 0, 900)
		_ok(m.objective_state("obj_hold") == "active" and m.hold_started > 0.0, "obj_hold active after A3")
		_ok(m.objective_state("obj_auction") == "done", "2 of 3 won")
		_ok(m.said.has("L28") and m.said.has("L30"), "L28, L30")
		MissionHarness.skip_time(m, 118.0)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory (said %s, objectives %s)" % [str(m.said), str(h.objective_log)])
	_ok(m.said.has("L34"), "L34 (dusk)")
	var cs := CampaignState.open("user://test_e7m1.json")
	cs.reset()
	var items_before := JSON.stringify(cs.items)
	cs.on_mission_victory(&"e7m1", m)
	_ok(cs.flag("ep7_started") and JSON.stringify(cs.items) == items_before, "flags only")
	_ok(int(cs.flag_value(CampaignState.TORVALD_ESSENCE_FLAG, 0)) > 0, "Torvald's essence carried")
	_ok(bool(cs.flag("e7m1_ossavar_won")), "e7m1_ossavar_won")
	_ok(StringName(m.mission_rewards().get("next", &"")) == &"c_e7_ledger", "next: c_e7_ledger")
	cs.reset()
	return true
