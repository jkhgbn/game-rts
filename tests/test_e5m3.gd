extends SceneTree
## Mission e5m3 "Tombstones by Candlelight" (docs/design/mission-e5-03.md, scripted through MissionHarness; the
## real-fight timing run is tests/test_e5m3_sim.gd). Parts:
##   start   Malrik L1 (Shadow Lance, cap 3), Soot and Bramble, the candle lit, 10 lit lamps, 11 gravewardens (4 patrols of 2,
##           the porch, the vault), 3 Magpies, the Reeve asleep inside the Lantern House, no resources, a Dusk Vial.
##   hidden  a hound in the yew Y1 is hidden; under a lamp it is not; that lamp snuffed by Malrik (pinched, 2 s) turns
##           its ring to shadow and the hound there is hidden again.
##   read    the candle lit at S1: read in ~4 s (1 / 3, L13); pinched at a tombstone: no reading.
##   grave   pinched by an old grave 3 s: 2 Shades rise (E4, the spotlight); a Shade under a lamp burns.
##   win     3 secrets, midnight, the bell (L18), the Reeve out cold = victory (cinematics off) and the flags.
## Run: godot --headless --path . -s tests/test_e5m3.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|...]

const TASK_ID := "e5m3"
const MISSION := "res://missions/mission_e5_03.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "hidden", "read", "grave", "win"]
var _part := ""
var h: MissionHarness
var main: MissionE5_03
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e5m3_none.json"}}) as MissionE5_03
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"hidden":
			h.steps.add("shadow, lamps, snuffing", _hidden, 1200)
		"read":
			h.steps.add("reading by candlelight", _read, 1500)
		"grave":
			h.steps.add("calling the dark", _grave, 1500)
		"win":
			h.steps.add("the bell at midnight, the Reeve, victory", _win, 6000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


## Keeps every enemy asleep (the parts test rules, not fights).
func _calm() -> void:
	for v: Variant in main.gravewardens + main.magpies:
		if is_instance_valid(v) and not main.is_dormant(v):
			main.set_dormant(v as Unit, true)


func _start() -> bool:
	var hero := main.hero
	_ok(hero.level == 1 and hero.level_cap == 3 and hero.spell_rank(&"shadow_lance") >= 1, "Malrik L1, Shadow Lance, cap 3")
	_ok(main.hounds.size() == 2 and main.candle_lit, "Soot and Bramble, the candle lit")
	_ok(main.dark_lamps.is_empty() and MissionE5_03.LAMPS.size() == 10, "10 lit lamps")
	_ok(main.gravewardens.size() == 11 and main.magpies.size() == 3, "11 gravewardens (%d), 3 Magpies" % main.gravewardens.size())
	_ok(main.reeve != null and main.is_dormant(main.reeve) and not main.reeve.visible, "the Reeve inside")
	_ok(Economy.for_team(0).crystals == 0, "no crystals")
	var inv: Variant = hero.get(&"inventory")
	_ok(inv != null and JSON.stringify(inv.get(&"slots")).contains("dusk_vial") or inv != null and str(inv.get(&"slots")).length() > 2, "an inventory with the Dusk Vial")
	_ok(main.objective_state("obj_secrets") == "active" and main.objective_state("obj_bell") == "", "objectives")
	return true


func _hidden() -> bool:
	var hd: Unit = main.hounds[0]
	if not _v.has("t"):
		_v["t"] = true
		_calm()
		MissionHarness.immortal(main.hero)
		MissionHarness.put(hd, Vector3(-34.0, 0.0, -4.0))
		hd.command_stop()
		_ok(main.is_hidden(hd), "a hound in the yew Y1 is hidden")
		MissionHarness.put(hd, MissionE5_03.LAMPS[6] + Vector3(1.0, 0.0, 0.0))
		hd.command_stop()
		_ok(not main.is_hidden(hd), "under a lamp it is not")
		main.toggle_candle()
		_ok(not main.candle_lit, "J pinches the candle")
		MissionHarness.put(main.hero, MissionE5_03.LAMPS[6] + Vector3(-1.5, 0.0, 0.0))
		main.hero.command_stop()
		return false
	if not main.dark_lamps.has(6):
		return false
	_ok(main.is_hidden(hd) and main.has_fired(&"E3") and main.said.has("L5"), "the snuffed ring is shadow (E3, L5)")
	return true


func _read() -> bool:
	if not _v.has("t"):
		_v["t"] = main.mission_time()
		_calm()
		MissionHarness.immortal(main.hero)
		MissionHarness.put(main.hero, MissionE5_03.CRYPTS[&"C1"][4] + Vector3(0.8, 0.0, 0.0))
		main.hero.command_stop()
		return false
	if not _v.has("s1"):
		if main.secrets_read.is_empty():
			if main.mission_time() - float(_v["t"]) > 8.0:
				_ok(false, "S1 never read")
				return true
			return false
		_v["s1"] = true
		_ok(main.mission_time() - float(_v["t"]) < 5.5, "read in ~4 s")
		_ok(main.said.has("L13") and main.objective_text(&"obj_secrets").contains("1 / 3"), "1 / 3, L13")
		main.toggle_candle()
		MissionHarness.put(main.hero, MissionE5_03.TOMBSTONES[0] + Vector3(0.8, 0.0, 0.0))
		main.hero.command_stop()
		_v["t2"] = main.mission_time()
		return false
	if main.mission_time() - float(_v["t2"]) < 4.0:
		return false
	_ok(main.stones_read.is_empty(), "no reading with the candle pinched")
	return true


func _grave() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		_calm()
		MissionHarness.immortal(main.hero)
		main.toggle_candle()
		MissionHarness.put(main.hero, MissionE5_03.GRAVES[0] + Vector3(1.0, 0.0, 0.0))
		main.hero.command_stop()
		return false
	if not _v.has("shades"):
		if main.shades.size() < 2:
			return false
		_v["shades"] = true
		_ok(main.has_fired(&"E4") and main.said.has("L6") and h.spotlight_log.has("shade_wild"), "E4, L6, the spotlight")
		var s: Unit = main.shades[0]
		MissionHarness.put(s, MissionE5_03.LAMPS[2] + Vector3(0.5, 0.0, 0.0))
		s.command_stop()
		_v["hp"] = s.hp
		_v["t2"] = main.mission_time()
		return false
	if main.mission_time() - float(_v["t2"]) < 1.5:
		return false
	var s2: Unit = main.shades[0]
	_ok(float(_v["hp"]) - s2.hp >= 6.0, "a Shade burns in lamplight (%.1f)" % (float(_v["hp"]) - s2.hp))
	return true


func _win() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		_calm()
		MissionHarness.immortal(main.hero)
		for k in ["C1", "C2", "C3"]:
			main._read(k)
		_ok(main.objective_state("obj_bell") == "active" and main.said.has("L17"), "3 / 3: obj_bell (L17)")
		MissionHarness.put(main.hero, MissionE5_03.BELL + Vector3(1.0, 0.0, 0.0))
		main.hero.command_stop()
		return false
	if not _v.has("early"):
		if main.mission_time() < 6.0:
			return false
		_v["early"] = true
		_ok(main.objective_state("obj_bell") == "active", "no bell before midnight")
		MissionHarness.skip_time(main, main.bell_at() - main.mission_time() + 0.5)
		return false
	if not _v.has("rung"):
		if main.objective_state("obj_reeve") != "active":
			return false
		_v["rung"] = true
		_ok(main.said.has("L18") and not main.is_dormant(main.reeve), "the bell (L18), the Reeve comes out")
		main.reeve.take_damage(1.0e6, main.hero)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	_ok(main.said.has("L23"), "the finding (L23)")
	var flags := main.mission_flags()
	_ok(flags.has("e5m3_pocketed") and flags.has("e5m3_tombstones"), "flags (%s)" % str(flags))
	var cs := CampaignState.open("user://test_e5m3.json")
	cs.reset()
	cs.on_mission_victory(&"e5m3", main)
	_ok(cs.flag("e5m3_hands_clean") and cs.unlocked.has(&"e5m4"), "e5m3_hands_clean, e5m4 unlocked")
	cs.reset()
	return true
