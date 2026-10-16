extends SceneTree
## Campaign review 2026-10-16 fixes for e7m2 / e7m4 (docs/playtests/campaign_review_2026-10-16/part3.md). Parts:
##   e7m2_duel      no 17:00 floor: Dacian comes DUEL_BREATHE s after the third clue, the strongbox window opens with
##                  the third clue and carries the boxes off when it ends; the Sun Cleave is telegraphed (a marker for
##                  SWING_WINDUP s), stepping out = dodged, standing in it = hit.
##   e7m2_causeway  the barricade still up at BARRICADE_LIMIT = "The causeway holds" = defeat.
##   e7m4_still     the keep mends at the Turn; Still the Sea opens once the great assault (M5) is broken (18:00 at the
##                  earliest, not 22:00) and the keep mends again; the hold objective / HUD say the hunger's effects.
## Run: godot --headless --path . -s tests/test_cr_e7.gd --fixed-fps 60 --quit-after 30000 [-- --only=e7m2_duel|...]

const TASK_ID := "cr_e7"
const E7M2 := "res://missions/mission_e7_02.tscn"
const E7M4 := "res://missions/mission_e7_04.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["e7m2_duel", "e7m2_causeway", "e7m4_still"]
var _part := ""
var h: MissionHarness
var main: Node
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
	var path := E7M4 if _part.begins_with("e7m4") else E7M2
	main = h.open(self, path, {"difficulty": 1, "set": {"campaign_save_path": "user://test_cr_e7_none.json"}})
	match _part:
		"e7m2_duel":
			h.protect_hero = false
			h.steps.add("duel timing, strongbox window, Sun Cleave", _e7m2_duel, 9000)
		"e7m2_causeway":
			h.steps.add("the causeway holds = defeat", _e7m2_causeway, 2000)
		"e7m4_still":
			h.steps.add("mends, goal-based Still the Sea, hunger words", _e7m4_still, 6000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


# ---------------------------------------------------------------- e7m2

func _clear_isle(m: MissionE7_02) -> void:
	for n in m.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == Unit.Team.ENEMY and not u is Wizard and MissionBase._flat(u.global_position, Vector3.ZERO) < 30.0:
			u.take_damage(1.0e6, null)


func _e7m2_duel() -> bool:
	var m := main as MissionE7_02
	if m.hero_alive():
		if m.duel_state != "on" or not _v.has("swing_hit_wait"):
			m.hero.heal(1.0e6)
	if m.dacian and is_instance_valid(m.dacian) and m.dacian.is_alive():
		m.dacian.heal(1.0e6)   # Torvald must not win the duel before the swings are checked
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		_ok(m.duel_floor() > 1.0e8, "no duel time before the truth")
		for b: Variant in m.barricades:
			(b as Building).take_damage(1.0e6, null)
		for c: StringName in [&"knives", &"ledger", &"herald"]:
			m._clue_found(c)
		_clear_isle(m)
		var t := m.mission_time()
		_v["t"] = t
		_ok(absf(m.truth_time - t) < 0.01, "truth time recorded")
		_ok(absf(m.duel_floor() - (t + MissionE7_02.DUEL_BREATHE)) < 0.01, "Dacian comes 45 s after the third clue (not at 17:00)")
		_ok(t + MissionE7_02.DUEL_BREATHE < 1020.0, "the duel is well before the old 17:00 floor")
		_ok(absf(m.box_until - (t + float(MissionE7_02.BOX_WINDOW[1]))) < 0.01, "strongbox window opens with the third clue")
		_ok(m.objective_text(&"sec_boxes").contains("left"), "the strongbox objective shows the time left")
		return false
	if not _v.has("b"):
		if m.mission_time() < float(_v["t"]) + MissionE7_02.DUEL_BREATHE - 1.0:
			if m.dacian_arrived:
				_v["b"] = true
				_ok(false, "Dacian came before the breather")
			return false
		if not m.dacian_arrived:
			return false
		_v["b"] = true
		MissionHarness.put(m.hero, MissionE7_02.DUEL_T)
		MissionHarness.put(m.dacian, MissionE7_02.DUEL_D)
		return false
	if not _v.has("c"):
		if m.duel_state != "on":
			return false
		_v["c"] = true
		return false
	if not _v.has("dodge"):
		if m.swing_target() == Vector3.INF:
			return false
		_v["dodge"] = true
		_ok(MissionBase._flat(m.swing_target(), m.hero.global_position) < 0.5, "the cleave marks Torvald's ground")
		MissionHarness.put(m.hero, m.swing_target() + Vector3(4.5, 0.0, 0.0))
		return false
	if not _v.has("dodged"):
		if m.swings_dodged + m.swings_hit == 0:
			return false
		_v["dodged"] = true
		_ok(m.swings_dodged == 1 and m.swings_hit == 0, "stepping out dodges the cleave")
		MissionHarness.put(m.hero, MissionE7_02.DUEL_T)
		return false
	if not _v.has("swing_hit_wait"):
		if m.swing_target() == Vector3.INF:
			return false
		_v["swing_hit_wait"] = true
		m.hero.heal(1.0e6)
		m.hero.command_stop()
		return false
	if _v.has("boxes"):
		return _boxes_after(m)
	if m.swings_hit == 0:
		m.hero.command_stop()
		if m.duel_state != "on":
			_ok(false, "duel ended before the second cleave (%s)" % m.duel_state)
			return true
		return false
	_ok(m.swings_hit == 1, "standing in the marker takes the cleave")
	_ok(m.hero.hp <= m.hero.max_hp * (1.0 - MissionE7_02.SWING_PCT * 0.5), "the cleave hurts (%.0f / %.0f)" % [m.hero.hp, m.hero.max_hp])
	# the strongbox window: skip past it, the boxes left are gone
	MissionHarness.skip_time(m, maxf(0.0, m.box_until - m.mission_time()) + 1.0)
	_v["boxes"] = true
	return false


func _boxes_after(m: MissionE7_02) -> bool:
	if m.boxes_open < MissionE7_02.BOXES.size():
		# the tick runs every 0.5 s; one more check later is enough
		return m.objective_state("sec_boxes") == "failed" or _wait_boxes(m)
	return true


func _wait_boxes(m: MissionE7_02) -> bool:
	var n := int(_v.get("bw", 0)) + 1
	_v["bw"] = n
	if n < 60:
		return false
	_ok(m.objective_state("sec_boxes") == "failed", "the strongbox window closed: boxes carried off")
	return true


func _e7m2_causeway() -> bool:
	var m := main as MissionE7_02
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		var limit := float(MissionE7_02.BARRICADE_LIMIT[1])
		_ok(limit <= 1320.0, "the causeway limit is within 22:00")
		MissionHarness.skip_time(m, limit + 1.0 - m.mission_time())
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0, "defeat when the causeway holds")
	_ok(m.objective_state("obj_barricade") == "failed", "obj_barricade failed")
	_ok(m.barricades_left() > 0, "the barricade still stood")
	return true


# ---------------------------------------------------------------- e7m4

func _e7m4_still() -> bool:
	var m := main as MissionE7_04
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		m.keep.take_damage(m.keep.max_hp * 0.6, null)
		var hp0 := m.keep.hp
		m.fire_once(&"E7")
		m.fire_once(&"E8")
		m.fire_once(&"E9")
		m._turn_end()
		_ok(m.keep.hp >= hp0 + m.keep.max_hp * MissionE7_04.KEEP_MEND - 1.0, "the keep mends at the Turn (%.0f -> %.0f)" % [hp0, m.keep.hp])
		var latest := maxf(MissionE7_04.STILL_LATEST, m.turn_time + MissionE7_04.STILL_AFTER_TURN)
		_ok(absf(m.still_at() - latest) < 0.01, "before the goal Still the Sea waits for the old floor")
		_ok(m.objective_text(&"obj_hold").contains("at 50 %"), "hold objective says the 50 %% effect: %s" % m.objective_text(&"obj_hold"))
		m.meter = 60.0
		_ok(m.objective_text(&"obj_hold").contains("at 100 %"), "hold objective says the 100 %% effect: %s" % m.objective_text(&"obj_hold"))
		m.meter = 74.5
		var probe: Array = m.spawn_rows([["shade", 1]], MissionE7Base.ROCK, 1.0, Teams.ENEMY_2, true)
		MissionHarness.kill(probe)
		# every assault but the great one is spent; the great one (M5) is sent for real
		for row: Array in MissionE7_04.ASSAULTS:
			m.fire_once(StringName(row[1]))
		m._assault(&"M5", "rock", "", 1.0)
		m.rock.set_owner_side(0)
		m.rock.locked = true
		_v["t"] = m.mission_time()
		return false
	if not _v.has("b"):
		if m.mission_time() - float(_v["t"]) < 2.0:
			return false
		_v["b"] = true
		_ok(m.has_fired(&"hunger_75"), "the 75 %% hunger warning (meter %.1f)" % m.meter)
		_ok(m.p4_done_at < 0.0, "the great assault is still up: P4 not done")
		var great := 0
		for n in m.get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and u.is_alive() and u.has_meta(MissionE7_04.GREAT_META):
				great += 1
				u.take_damage(1.0e7, null)
		_ok(great > MissionE7_04.P4_LEFT, "the great assault is tagged (%d)" % great)
		_v["t"] = m.mission_time()
		return false
	if not _v.has("c"):
		if m.p4_done_at < 0.0:
			return false
		_v["c"] = true
		_ok(absf(m.still_at() - maxf(MissionE7_04.STILL_AT, m.p4_done_at)) < 0.01, "goal met: Still the Sea at max(18:00, now)")
		_ok(m.still_at() < 1320.0, "earlier than the old 22:00 floor")
		m.keep.take_damage(m.keep.max_hp * 0.5, null)
		_v["hp1"] = m.keep.hp
		MissionHarness.skip_time(m, m.still_at() + 1.0 - m.mission_time())
		return false
	if m.objective_state("obj_still") != "active":
		return false
	_ok(m.mission_time() >= MissionE7_04.STILL_AT and m.mission_time() < 1320.0, "Still the Sea opened at %s" % MissionE5Base.mmss(m.mission_time()))
	_ok(m.keep.hp >= float(_v["hp1"]) + m.keep.max_hp * MissionE7_04.KEEP_MEND - 50.0, "the keep mends when the sea starts to still")
	return true
