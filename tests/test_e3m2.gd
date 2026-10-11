extends SceneTree
## Mission e3m2 "Another Night" (docs/design/mission-e3-02.md, scripted through MissionHarness; the playable core).
## Parts:
##   start   Hush the night's hero (900 HP) + the 8-unit squad, Malrik asleep on the crest, 4 wagons, 10 lit fires,
##           Vessa asleep, the base locked, the dawn countdown.
##   night   a Shade snuffs a fire in 2 s; WG4 sabotaged by Hush in 2 s, by a Shade in 4 s, never by a Hound; a lit squad
##           unit left in a spotter's sight raises Alarm 1 after the 3 s fuse (sec_unseen failed).
##   dawn    the 4th wagon -> phase 2: Malrik the hero, the Dusk Keep a Citadel, economy on; the hold -> victory and
##           the flags (e3m2_alarms, Malrik's essence).
##   death   Hush's death in the night = defeat.
## Run: godot --headless --path . -s tests/test_e3m2.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e3m2"
const MISSION := "res://missions/mission_e3_02.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "night", "camp", "dawn", "death"]
var _part := ""
var h: MissionHarness
var main: MissionE3_02
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
	h.timeout_frames = 30000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e3m2_none.json"}}) as MissionE3_02
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
		"night":
			h.steps.add("snuff in 2 s", _snuff, 600)
			h.steps.add("sabotage rules", _sabotage, 900)
			h.steps.add("spotted -> Alarm 1", _alarm, 900)
		"camp":
			h.steps.add("concealed status + Hush's kit", _kit, 600)
			h.steps.add("a tent hit fails sec_villagers", _tent, 900)
			h.steps.add("a destroyed wagon is spoiled, loud", _wagon_loud, 900)
			h.steps.add("Alarm 3: sight 12 m, concealment 8 m", _camp_up, 600)
		"dawn":
			h.steps.add("4 wagons -> phase 2", _phase2, 300)
			h.steps.add("the hold -> victory", _hold, 12000)
		"death":
			h.steps.add("Hush dies -> defeat", _death, 600)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _shade() -> Unit:
	for s: Variant in main.squad:
		if is_instance_valid(s) and (s as Unit).is_alive() and (s as Unit).unit_type.id == &"shade":
			return s as Unit
	return null


func _hound() -> Unit:
	for s: Variant in main.squad:
		if is_instance_valid(s) and (s as Unit).is_alive() and (s as Unit).unit_type.id == &"grave_hound":
			return s as Unit
	return null


## Keeps every enemy far away / asleep so a step only tests its own rule.
func _calm() -> void:
	main.alert_left = 0.0
	for n in main.get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), 0) and u != main.vey_vigil and not main.is_dormant(u):
			main.set_dormant(u, true)


func _start() -> bool:
	_ok(main.hero == main.hush_hero and main.hero.max_hp == 900.0, "Hush the hero (900 HP)")
	_ok(main.squad.size() == 8, "8 squad units")
	_ok(main.malrik != null and main.is_dormant(main.malrik), "Malrik asleep on the crest")
	_ok(main.wagons.size() == 4 and main.fires.size() == 10, "4 wagons, 10 fires")
	_ok(main.vessa != null and main.is_dormant(main.vessa), "Vessa asleep")
	_ok(absf(main.dawn_left - 660.0) < 2.0, "dawn in 11:00")
	_ok(main.keep != null and main.keep.tier == 1, "the base locked at tier 1 tonight")
	return true


func _snuff() -> bool:
	_calm()
	var f: Array = main.fires[7]   # F8 by WG4
	var s := _shade()
	MissionHarness.put(s, f[0] + Vector3(1.0, 0.0, 0.0))
	if not _v.has("t"):
		_v["t"] = main.mission_time()
		return false
	if f[1]:
		return false
	var took := main.mission_time() - float(_v["t"])
	_ok(took <= 2.8, "snuffed in ~2 s (%.1f)" % took)
	return true


func _sabotage() -> bool:
	_calm()
	var w: Building = main.wagons[&"WG4"]
	var at := w.global_position + Vector3(2.5, 0.0, 0.0)
	if not _v.has("hound"):
		_v["hound"] = main.mission_time()
		for s: Variant in main.squad:
			MissionHarness.put(s as Unit, Vector3(0.0, 0.0, 10.0))
		MissionHarness.put(main.hush_hero, Vector3(2.0, 0.0, 12.0))
	var hd := _hound()
	if main.mission_time() - float(_v["hound"]) < 5.0:
		MissionHarness.put(hd, at)
		return false
	if not _v.has("hound_ok"):
		_v["hound_ok"] = true
		_ok(not main.spoiled.has(&"WG4"), "a Hound cannot sabotage")
		MissionHarness.put(hd, Vector3(0.0, 0.0, 10.0))
		_v["hush"] = main.mission_time()
	MissionHarness.put(main.hush_hero, at)
	if not main.spoiled.has(&"WG4"):
		return false
	var took := main.mission_time() - float(_v["hush"])
	_ok(took <= 2.8, "Hush sabotages in ~2 s (%.1f)" % took)
	MissionHarness.put(main.hush_hero, Vector3(2.0, 0.0, 12.0))
	return true


func _alarm() -> bool:
	if not _v.has("a"):
		_v["a"] = true
		# a lit Shade beside a lit fire with an awake Flame Guard 5 m away: the fuse fills, Alarm 1
		var f: Array = main.fires[2]
		main._set_fire(f, true)
		var s := _shade()
		MissionHarness.immortal(s)
		MissionHarness.put(s, f[0] + Vector3(3.0, 0.0, 0.0))   # lit (9 m), out of the 2 m snuff
		var g := main.spawn_wave_at([["flame_guard", 1]], f[0] + Vector3(8.0, 0.0, 0.0), Unit.Team.ENEMY_2)
		(g[0] as Unit).set(&"aggro_range", 0.0)
		_v["s"] = s
		return false
	MissionHarness.put(_v["s"], (main.fires[2] as Array)[0] + Vector3(3.0, 0.0, 0.0))
	if main.alarms < 1:
		return false
	_ok(main.objective_state("sec_unseen") == "failed", "sec_unseen failed at Alarm 1")
	return true


func _kit() -> bool:
	_calm()
	var hush := main.hush_hero
	if not _v.has("k"):
		_v["k"] = main.mission_time()
		_ok(hush is HushCommando and hush.level == 5, "Hush a HushCommando at level 5")
		var before := hush.level
		hush.add_xp(5000)
		_ok(hush.level == before, "Hush gains no XP")
		for s: Variant in main.squad:
			MissionHarness.put(s as Unit, Vector3(-60.0, 0.0, 0.0) + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
		MissionHarness.put(hush, Vector3(-56.0, 0.0, -4.0))
		return false
	if main.mission_time() - float(_v["k"]) < 4.5:
		return false
	var s := _shade()
	_ok(s.is_concealed(), "a Shade in the dark has the concealed status")
	_ok(hush.is_veiled() and main.veiled, "Hush veiled after 4 s idle")
	_ok(hush.command_cast(&"hush_smoke", null) == "" and hush.cooldown_left(&"hush_smoke") > 20.0, "Smoke Cloak (Q) casts, no mana")
	_ok(hush.command_cast(&"hush_smoke", null) == HushCommando.REFUSE_RECHARGING, "Smoke Cloak recharging")
	return true


func _tent() -> bool:
	_calm()
	var t: Building = main._tents[2]   # VT3 (2, 52)
	var s := _shade()
	if not _v.has("t0"):
		_v["t0"] = true
		MissionHarness.immortal(s)
		MissionHarness.put(s, t.global_position + Vector3(3.5, 0.0, 0.0))
		_v["t1"] = main.mission_time()
		return false
	if not _v.has("auto"):
		MissionHarness.put(s, t.global_position + Vector3(3.5, 0.0, 0.0))
		if main.mission_time() - float(_v["t1"]) < 3.0:
			return false
		_v["auto"] = true
		_ok(t.hp >= t.max_hp and main.villagers_hit == 0, "a Shade beside a tent never auto-attacks it")
		s.command_attack(t)
		return false
	if main.villagers_hit == 0:
		return false
	_ok(main.objective_state("sec_villagers") == "failed", "sec_villagers failed")
	_ok(main.alarms >= 1, "an instant alarm")
	s.command_stop()
	return true


func _wagon_loud() -> bool:
	var w: Building = main.wagons[&"WG3"]
	if not _v.has("w"):
		_v["w"] = main.alarms
		w.take_damage(1.0e6, main.hush_hero)
		return false
	if not main.spoiled.has(&"WG3"):
		return false
	_ok(main.alarms > int(_v["w"]) or main.alert_left > 0.0, "a destroyed wagon raises an alarm")
	return true


func _camp_up() -> bool:
	var s := _shade()
	var before := main.seen_within(s)
	main.alarms = 2
	main.alert_left = 0.0
	main.raise_alarm(Vector3(30.0, 0.0, 40.0))
	_ok(main.vessa_awake, "the 3rd alarm wakes Vessa")
	var lit := not main.is_concealed(s)
	_ok(main.seen_within(s) == (12.0 if lit else 8.0) and before != main.seen_within(s), "sight after Alarm 3 (%.0f -> %.0f)" % [before, main.seen_within(s)])
	return true


func _phase2() -> bool:
	if main.phase == 1:
		for id: StringName in main.wagons:
			main._spoil(id, false)
		return false
	_ok(main.hero == main.malrik and not main.is_dormant(main.malrik), "Malrik the hero")
	_ok(main.keep.tier == 3, "the Dusk Keep a Citadel")
	_ok(Economy.for_team(0).crystals == 600, "600 crystals at dawn")
	_ok(main.objective_state("obj_light") == "active" and main.objective_state("obj_wagons") == "done", "objectives")
	return true


func _hold() -> bool:
	MissionHarness.immortal(main.hero)
	MissionHarness.immortal(main.keep)
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory at sunrise")
	var f := main.mission_flags()
	_ok(f.has("e3m2_alarms") and f.has(CampaignState.MALRIK_ESSENCE_FLAG), "flags %s" % str(f))
	return true


func _death() -> bool:
	if not _v.has("d"):
		_v["d"] = true
		h.protect_hero = false
		main.hero.take_damage(1.0e7, null)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0 and main.objective_state("obj_hush") == "failed", "Hush's death = defeat")
	return true
