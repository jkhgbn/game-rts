extends SceneTree
## Mission e2m4 "Sunrise Road" (docs/design/mission-e2-04.md, acceptance checks 2-8 scripted through MissionHarness;
## the real-fight timing run is tests/test_e2m4_sim.gd). Parts:
##   start   the 80 x 160 cave (halls walkable, rock between), no keep, Vessa L5 + 4 points, 13 soldiers, Old Vey on the
##           field, 6 sunstones, 12 sleepers, sight x 0.7, Forge on (forge_enabled), Vey kneels instead of falling.
##   dark    a Shade 8 m from a Flame Guard in the dark is hidden from auto-targets; inside a lit sunstone it is not.
##   wake    Vessa at 4 m + Vey at 8 m wakes a Sunwarden in 3 s; Vey at 14 m does not; an acolyte wakes one as ENEMY,
##           20 damage resets it; a Sunwarden gets +4 damage near Vey.
##   claim   the claim refuses with a Shade within 12 m; once clear: the Warden Forge is the PLAYER keep (tier 2), 4
##           Cinder Hands, obj_research / obj_gate, the spotlight; 2 researches = obj_research done; Vey can fall now.
##   hush    Vessa in Hall 3: Hush (1 400 HP) appears; at 25 % she flees and sec_hush is done.
##   gate    the channel needs obj_research; pauses with an enemy within 10 m (never resets); 45 s opens it -> victory,
##           rewards e2m4 (next e2m5).
##   forge   the Warden Forge destroyed after the claim = defeat (L33).
## Run: godot --headless --path . -s tests/test_e2m4.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e2m4"
const MISSION := "res://missions/mission_e2_04.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "dark", "wake", "claim", "hush", "gate", "forge"]
var _part := ""
var h: MissionHarness
var main: MissionE2_04
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e2m4_none.json"}}) as MissionE2_04
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
			h.steps.add("Vey kneels before the claim", _vey_kneels, 120)
		"dark":
			h.steps.add("the dark hides, the light shows", _dark, 120)
		"wake":
			h.steps.add("no wake without Vey", _wake_no_vey, 400)
			h.steps.add("storm wake", _wake_storm, 400)
			h.steps.add("acolyte wake + interrupt", _wake_amber, 900)
		"claim":
			h.steps.add("claim refused with a Shade near", _claim_blocked, 600)
			h.steps.add("claim completes", _claim_done, 900)
			h.steps.add("research x2", _research, 60)
		"hush":
			h.steps.add("Hush in Hall 3", _hush_meet, 600)
			h.steps.add("Hush flees at 25 %", _hush_flee, 1200)
		"gate":
			h.steps.add("gate needs research", _gate_locked, 300)
			h.steps.add("gate pauses with an enemy", _gate_pause, 1800)
			h.steps.add("gate opens -> victory", _gate_open, 9000)
		"forge":
			h.steps.add("forge lost = defeat", _forge_loss, 900)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


## Clears every enemy within `r` of `at` (scripted guards) so a channel test is not blocked.
func _clear(at: Vector3, r: float) -> void:
	for n in main.get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and MissionBase._flat(u.global_position, at) <= r:
			u.take_damage(1.0e7, null)


func _start() -> bool:
	_ok(MapInfo.size_x == 80.0 and MapInfo.size_z == 160.0, "80 x 160 map")
	_ok(MissionE2_04.is_walkable(Vector3(0, 0, 48)) and MissionE2_04.is_walkable(Vector3(0, 0, 0)) \
			and MissionE2_04.is_walkable(Vector3(0, 0, -54)), "halls walkable")
	_ok(not MissionE2_04.is_walkable(Vector3(-35, 0, 40)) and not MissionE2_04.is_walkable(Vector3(30, 0, 25)), "rock between")
	_ok(main.keep == null and not main.forge_claimed, "no keep before the claim")
	_ok(main.hero.level == 5 and main.hero.spell_points == 4, "Vessa L5 + 4 points (L%d, %d)" % [main.hero.level, main.hero.spell_points])
	var army := _units(0, "flame_guard").size() + _units(0, "ember_archer").size() + _units(0, "pyre_adept").size() \
			+ _units(0, "kilnwarden").size()
	_ok(army == 13, "13 start soldiers (%d)" % army)
	_ok(main.vey != null and main.vey.is_alive(), "Old Vey on the field")
	_ok(main.sunstones.size() == 6 and main.sleepers.size() == 12, "6 stones, 12 sleepers")
	_ok(main.guides.size() == 2, "2 guides (no e2m3_magpies_hunted)")
	_ok(absf(float(main.fog.get(&"sight_scale")[0]) - 0.7) < 0.01, "sight x 0.7")
	_ok(ForgeKit.enabled_for(main), "Forge on (forge_enabled)")
	_ok(h.saw("obj_forge", "active") and h.saw("sec_wardens", "active"), "objectives")
	_ok(Economy.for_team(0).crystals == 300, "300 crystals")
	return true


func _vey_kneels() -> bool:
	if not _v.has("k"):
		_v["k"] = true
		main.vey.take_damage(1.0e7, null)
		return false
	_ok(main.vey.is_alive() and main._vey_kneel_left > 0.0, "Vey kneels, never falls before the claim")
	return true


func _dark() -> bool:
	if not _v.has("s"):
		var g := _units(0, "flame_guard")[0] as Unit
		var shade := main._spawn(main.make_unit("shade"), Unit.Team.ENEMY, Vector3(-30, 0, 0))
		main.set_dormant(shade, false)
		MissionHarness.put(g, Vector3(-10, 0, 8))
		MissionHarness.put(shade, Vector3(-10, 0, 0))
		MissionHarness.put(main.hero, Vector3(0, 0, 60))
		_v["s"] = shade
		_v["g"] = g
		_t0 = h.frame
		return false
	var shade: Unit = _v["s"]
	if h.frame - _t0 < 30:
		return false
	if not _v.has("lit"):
		_ok(shade.is_hidden_from_auto_target(), "a Shade 8 m from a Guard in the dark is hidden")
		_v["lit"] = true
		var s3: MissionBrazier = main.sunstones[2]
		s3.light()
		MissionHarness.put(shade, s3.global_position + Vector3(2, 0, 2))
		MissionHarness.put(_v["g"], s3.global_position + Vector3(2, 0, 10))
		_t0 = h.frame
		return false
	if h.frame - _t0 < 30:
		return false
	_ok(not shade.is_hidden_from_auto_target(), "inside a lit sunstone it is not hidden")
	return true


func _wake_no_vey() -> bool:
	var s: Unit = main.sleepers[&"H1a"]
	if not _v.has("p"):
		_v["p"] = true
		MissionHarness.put(main.hero, s.global_position + Vector3(2.5, 0, 0))
		MissionHarness.put(main.vey, s.global_position + Vector3(2.5, 0, 16))
		main.vey.set(&"stance", &"home")
		_t0 = h.frame
		return false
	if main.vey.global_position.distance_to(main.hero.global_position) < 10.0:
		MissionHarness.put(main.vey, s.global_position + Vector3(2.5, 0, 16))
	if h.frame - _t0 < 240:
		return false
	_ok(main.sleepers.has(&"H1a"), "no wake with Vey 14 m away")
	return true


func _wake_storm() -> bool:
	var s: Variant = main.sleepers.get(&"H1a")
	if not _v.has("w"):
		_v["w"] = true
		MissionHarness.put(main.vey, (s as Unit).global_position + Vector3(3.0, 0, 3.0))
		_t0 = h.frame
		return false
	if main.sleepers.has(&"H1a"):
		if main.vey.global_position.distance_to(main.hero.global_position) > 6.0:
			MissionHarness.put(main.vey, main.hero.global_position + Vector3(2.0, 0, 2.0))
		return false
	var secs := float(h.frame - _t0) / 60.0
	_ok(secs >= 2.8 and secs <= 4.0, "woken in ~3 s (%.1f)" % secs)
	_ok(main.wardens_woken == 1 and main.sunwardens.size() == 1 and int((main.sunwardens[0] as Unit).team) == 0,
			"a PLAYER Sunwarden")
	var w := main.sunwardens[0] as Unit
	main._tick_storm_aura()
	_ok(w.has_meta(&"e2m4_storm"), "aura:storm near Vey")
	return true


func _wake_amber() -> bool:
	if not _v.has("a"):
		var target := (main.sleepers[&"H2a"] as Unit).global_position
		var only: Array[StringName] = [&"H2a"]
		var a := main._spawn_acolyte(target + Vector3(1.5, 0, 0), only)
		MissionHarness.immortal(a)
		_v["a"] = a
		_t0 = h.frame
		return false
	var a: Unit = _v["a"]
	if not _v.has("hit") and h.frame - _t0 == 120:   # 2 s into the 3 s channel: 20 damage resets it
		_v["hit"] = true
		var row: Array = main._amber_wake.get(a.get_instance_id(), [&"", 0.0])
		_ok(float(row[1]) > 0.4, "acolyte channelling (%.2f)" % float(row[1]))
		a.take_damage(20.0, null)
		row = main._amber_wake.get(a.get_instance_id(), [&"", 0.0])
		_ok(float(row[1]) < 0.05, "20 damage resets the channel")
		return false
	if main.sleepers.has(&"H2a"):
		return false
	_ok(main.amber_wardens.size() >= 3 and int((main.amber_wardens.back() as Unit).team) == Unit.Team.ENEMY, "an ENEMY amber Warden")
	_ok(main.has_fired(&"E12") and main.said.has(16), "E12: L16")
	return true


func _claim_blocked() -> bool:
	if not _v.has("c"):
		_v["c"] = true
		MissionHarness.put(main.hero, MissionE2_04.FORGE_POS + Vector3(0, 0, 4))
		_t0 = h.frame
		return false
	if h.frame - _t0 < 420:
		return false
	_ok(not main.forge_claimed, "claim refused while G2 stands")
	_clear(MissionE2_04.FORGE_POS, 16.0)
	return true


func _claim_done() -> bool:
	if not main.forge_claimed:
		MissionHarness.put(main.hero, MissionE2_04.FORGE_POS + Vector3(0, 0, 4))
		return false
	_ok(main.keep != null and main.keep.is_alive() and int(main.keep.team) == 0 and main.keep.tier == 2, "the Warden Forge = PLAYER keep, tier 2")
	_ok(main.keep.max_hp == MissionE2_04.FORGE_HP, "2 800 HP")
	_ok(_units(0, "cinder_hand").size() == 4, "4 Cinder Hands")
	_ok(h.saw("obj_forge", "done") and h.saw("obj_research", "active") and h.saw("obj_gate", "active"), "objectives at E9")
	_ok(h.saw_spotlight("fire_forge"), "Ember Forge spotlight")
	main.vey.take_damage(1.0e7, null)
	_ok(not main.vey.is_alive(), "Vey can fall after the claim")
	return true


func _research() -> bool:
	var fk := ForgeKit.for_team(0)
	fk.complete(&"weapons")
	fk.complete(&"armor")
	_ok(main.researches == 2 and h.saw("obj_research", "done") and main.said.has(19), "2 researches: obj_research done, L19")
	return true


func _hush_meet() -> bool:
	if not _v.has("m"):
		_v["m"] = true
		MissionHarness.put(main.hero, Vector3(0, 0, -40))
		return false
	if main.hush_state != &"fight":
		return false
	var hu: Unit = main.hush_cast.hush
	_ok(hu.max_hp == 1400.0, "Hush 1 400 HP (%.0f)" % hu.max_hp)
	_ok(h.saw("sec_hush", "active"), "sec_hush active")
	return true


func _hush_flee() -> bool:
	var hu: Unit = main.hush_cast.hush
	if not _v.has("f"):
		_v["f"] = true
		hu.take_damage(hu.max_hp * 0.6, null)
		return false
	if not _v.has("f2"):
		_v["f2"] = true
		hu.take_damage(hu.max_hp * 0.2, null)
		return false
	if main.hush_state == &"fled":
		_ok(h.saw("sec_hush", "done") and main.said.has(23), "sec_hush done, L23")
		return true
	return false


func _gate_locked() -> bool:
	if not _v.has("g"):
		_v["g"] = true
		main.claim_forge()
		_clear(MissionE2_04.GATE_SPOT, 30.0)
		MissionHarness.put(main.hero, MissionE2_04.GATE_SPOT)
		MissionHarness.put(main.vey, MissionE2_04.GATE_SPOT + Vector3(2, 0, 2))
		_t0 = h.frame
		return false
	if h.frame - _t0 < 120:
		return false
	_ok(main.gate_progress == 0.0, "no channel before obj_research")
	var fk := ForgeKit.for_team(0)
	fk.complete(&"weapons")
	fk.complete(&"armor")
	return true


func _gate_pause() -> bool:
	MissionHarness.immortal(main.vey)
	if main.vey.global_position.distance_to(main.hero.global_position) > 5.0:
		MissionHarness.put(main.vey, main.hero.global_position + Vector3(2, 0, 2))
	if not _v.has("p"):
		if main.gate_progress < 0.2:
			_clear(MissionE2_04.GATE_SPOT, 14.0)
			return false
		_v["p"] = main.gate_progress
		var s := main._spawn(main.make_unit("shade"), Unit.Team.ENEMY, MissionE2_04.GATE_SPOT + Vector3(5, 0, 0))
		MissionHarness.immortal(s)
		s.aggro_range = 0.0
		s.attack_damage = 0.0
		_v["s"] = s
		_t0 = h.frame
		return false
	if h.frame - _t0 < 120:
		return false
	_ok(absf(main.gate_progress - float(_v["p"])) < 0.03 and main.gate_paused, "paused, not reset (%.2f)" % main.gate_progress)
	(_v["s"] as Unit).death_guard = Callable()
	(_v["s"] as Unit).take_damage(1.0e7, null)
	return true


func _gate_open() -> bool:
	if main.vey.is_alive() and main.vey.global_position.distance_to(main.hero.global_position) > 5.0:
		MissionHarness.put(main.vey, main.hero.global_position + Vector3(2, 0, 2))
	if not main.gate_open:
		_clear(MissionE2_04.GATE_SPOT, 14.0)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	var r: Dictionary = CampaignState.reward_of(&"e2m4")
	_ok(r.get("next") == &"e2m5" and (r.get("set_flags", {}) as Dictionary).get("e2m4_gate_open") == true, "rewards %s" % str(r))
	return true


func _forge_loss() -> bool:
	if not _v.has("k"):
		_v["k"] = true
		main.claim_forge()
		return false
	if not _v.has("d"):
		_v["d"] = true
		main.keep.take_damage(1.0e7, null)
		return false
	if h.ended == 0:
		_ok(main.said.has(33), "E23: L33")
		return true
	return false
