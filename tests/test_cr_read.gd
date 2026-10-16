extends SceneTree
## Campaign review 2026-10-16 fixes (docs/playtests/campaign_review_2026-10-16/summary.md, fixes 5 and 6), scripted
## through MissionHarness. Parts:
##   e6m4   the Host has a ranged Ruin Slinger in its columns; a Warden at 3 m makes "The Master is interrupted" (objective
##          text + interruptions); a Thornling dying 20 m from the stone shows in the seal objective's tally and the ring.
##   e7m3   an Aurivane raider alone at Saltpan Court's bell fills its take ring (row_take_ratio) and announces it once;
##          the 9:00 tithe line says "every pit held = gold, every row left = lives"; masked units are told apart.
##   e6m1   two Wardens standing still on a floe crack it ("stone that stops on the ice sinks it"); the winter 2 Lake
##          Rise climbs out on a floe as Deep Wardens (armor 60) with Aldra's teaching line and the hint.
##   e8m1   the fire road's Host waves hold Ruin Slingers (ranged) and one spawns as a Host unit.
## Run: godot --headless --path . -s tests/test_cr_read.gd --fixed-fps 60 --quit-after 30000 [-- --only=e6m4|...]

const TASK_ID := "cr_read"
const GAP_FRAMES := 3
const SCENES := {"e6m4": "res://missions/mission_e6_04.tscn", "e7m3": "res://missions/mission_e7_03.tscn",
		"e6m1": "res://missions/mission_e6_01.tscn", "e8m1": "res://missions/mission_e8_01_fire.tscn"}

var _parts: Array[String] = ["e6m4", "e7m3", "e6m1", "e8m1"]
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
		MissionE8Base.forced_road = &""
		print("PASS %s" % TASK_ID if _errors.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return
	_part = _parts.pop_front()
	_v = {}
	h = MissionHarness.new()
	h.task_id = "%s/%s" % [TASK_ID, _part]
	h.timeout_frames = 9000
	if _part == "e8m1":
		MissionE8Base.forced_road = &"fire"
	main = h.open(self, SCENES[_part], {"difficulty": 1, "set": {"campaign_save_path": "user://test_cr_read_none.json"}})
	match _part:
		"e6m4":
			h.steps.add("slinger, interrupted, the tally", _e6m4, 3000)
		"e7m3":
			h.steps.add("the take ring, the tithe line, masks", _e7m3, 3000)
		"e6m1":
			h.steps.add("held ice cracks, the Lake Rise", _e6m1, 3000)
		"e8m1":
			h.steps.add("Ruin Slingers in the Host", _e8m1, 600)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


static func _of_type(tree: SceneTree, id: String, team: int) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == id:
			out.append(u)
	return out


# ---------------------------------------------------------------- e6m4

func _e6m4() -> bool:
	if not h.is_ready():
		return false
	var m := main as MissionE6_04
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(m.hero)
		var st := m.local_unit_type(MissionE6_04.SLINGER_ID)
		_ok(st != null and st.attack_range >= 8.0 and not st.commandable, "the Ruin Slinger is a ranged Host type")
		m._column(&"wg_n")
		_ok(not _of_type(self, MissionE6_04.SLINGER_ID, Unit.Team.ENEMY).is_empty(), "a column holds a Ruin Slinger")
		MissionHarness.kill(_of_type(self, MissionE6_04.SLINGER_ID, Unit.Team.ENEMY) + _of_type(self, MissionE6Base.WARDEN_ID, Unit.Team.ENEMY))
		MissionHarness.skip_time(m, MissionE6_04.HOLD_FROM + 2.0 - m.mission_time())
		return false
	if not _v.has("warden"):
		if m.mission_time() < MissionE6_04.HOLD_FROM + 1.0:
			return false
		var w := m.make_unit(MissionE6Base.WARDEN_ID)
		m._spawn(w, Unit.Team.ENEMY, MissionE6_04.STONE + Vector3(3.0, 0.0, 0.0))
		w.aggro_range = 0.0
		w.command_stop()
		_v["warden"] = w
		_v["at"] = m.mission_time()
		return false
	if not _v.has("paused"):
		if not m.hold_paused:
			if m.mission_time() - float(_v["at"]) > 3.0:
				_ok(false, "no pause with a Warden at 3 m")
				return true
			return false
		_v["paused"] = true
		_ok(m.interruptions >= 1, "the interruption is counted (%d)" % m.interruptions)
		_ok(m.objective_text(&"obj_hold").begins_with("The Master is interrupted"), "obj_hold: %s" % m.objective_text(&"obj_hold"))
		MissionHarness.kill([_v["warden"]])
		var th := m.make_unit("thornling")
		m._spawn(th, Unit.Team.PLAYER, MissionE6_04.STONE + Vector3(-20.0, 0.0, 0.0))
		_v["before"] = m.counted
		_v["thorn"] = th
		return false
	if not _v.has("killed"):
		_v["killed"] = true
		MissionHarness.kill([_v["thorn"]])
		return false
	_ok(m.counted == int(_v["before"]) + 1, "the Thornling was counted (%d)" % m.counted)
	var seal_txt := m.objective_text(&"obj_seal")
	_ok(seal_txt.contains("counted %d" % m.counted), "the seal objective shows the tally: %s" % seal_txt)
	_ok(m.count_ring_ratio() > 0.0, "the tally ring darkened (%.3f)" % m.count_ring_ratio())
	_ok(not MissionE6_04.HINT_SAGE.contains("all melee"), "the Bramblesage hint no longer says the Host is all melee")
	return true


# ---------------------------------------------------------------- e7m3

func _e7m3() -> bool:
	if not h.is_ready():
		return false
	var m := main as MissionE7_03
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(m.hero)
		var raider := m.make_unit("flame_guard")
		m._spawn(raider, Unit.Team.ENEMY, MissionE7_03.ROWS[&"R3"] + Vector3(2.0, 0.0, 0.0))
		raider.aggro_range = 0.0
		m.set_dormant(raider, false)
		_v["raider"] = raider
		_v["at"] = m.mission_time()
		var mk := m.make_unit("masked_shade")
		_ok(MissionE7_03.is_mask(mk) and mk.unit_type.display_name.begins_with("Masked"), "masks are named apart")
		mk.free()
		_ok(MissionE7_03.MSG_TITHE.contains("Every pit you hold pays gold") and MissionE7_03.MSG_TITHE.contains("Every row you leave costs lives"),
				"the 9:00 line is plain: %s" % MissionE7_03.MSG_TITHE)
		return false
	var raider := _v["raider"] as Unit
	if is_instance_valid(raider) and raider.is_alive():
		MissionHarness.put(raider, MissionE7_03.ROWS[&"R3"] + Vector3(2.0, 0.0, 0.0))
	if m.mission_time() - float(_v["at"]) < 4.0:
		return false
	var r := m.row_take_ratio(&"R3")
	_ok(r > 0.05 and r < 1.0, "Saltpan Court's take ring fills (%.2f)" % r)
	_ok(m._taking_said.has(&"R3"), "the take was announced")
	_ok(m.row_take_ratio(&"R1") == 0.0, "Rope Row is not being taken")
	return true


# ---------------------------------------------------------------- e6m1

func _e6m1() -> bool:
	if not h.is_ready():
		return false
	var m := main as MissionE6_01
	var floe_at := Vector3(cos(deg_to_rad(225.0)) * 14.0, 0.0, sin(deg_to_rad(225.0)) * 14.0)
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(m.hero)
		m.heartfrost.setup(1.0e6, 0.0)
		_v["wardens"] = m.spawn_rows([["hollow_warden", 2]], floe_at, 1.0, Unit.Team.ENEMY, false)
		for u: Variant in _v["wardens"]:
			(u as Unit).aggro_range = 0.0
		_v["at"] = m.mission_time()
		return false
	if not _v.has("held"):
		for u: Variant in _v["wardens"]:
			if is_instance_valid(u) and (u as Unit).is_alive():
				(u as Unit).command_stop()
		if m.lake.cracks[5] < 1.0:
			if m.mission_time() - float(_v["at"]) > 6.0:
				_ok(false, "two standing Wardens (weight 4) never cracked F5 (%.1f)" % m.lake.cracks[5])
				return true
			return false
		_v["held"] = true
		_ok(m.held_cracks >= 1, "the crack came from the held-ice rule (%d)" % m.held_cracks)
		MissionHarness.kill(_v["wardens"])
		MissionHarness.skip_time(m, 600.5 - m.mission_time())
		return false
	if not m.waves_fired.has("lake1"):
		return false
	var deep: Array = m.lake_rise_units.filter(func(u: Variant) -> bool: return is_instance_valid(u) \
			and String((u as Unit).unit_type.id) == MissionE6_01.DEEP_ID)
	_ok(not deep.is_empty(), "the Lake Rise spawned Deep Wardens (%d)" % deep.size())
	if not deep.is_empty():
		var d := deep[0] as Unit
		_ok(GlasswaterLake.floe_at(d.global_position) >= 0, "a Deep Warden climbs out on a floe")
		_ok(d.get_stat(&"armor") >= 60.0, "Deep Wardens are armoured (%.0f)" % d.get_stat(&"armor"))
	_ok(m.dialogue_log.any(func(l: String) -> bool: return l.contains("Stone that stands still on the ice goes under")),
			"Aldra teaches the floes")
	return true


# ---------------------------------------------------------------- e8m1

func _e8m1() -> bool:
	if not h.is_ready():
		return false
	var m := main as MissionE8_01Fire
	var st := m.local_unit_type(MissionE8_01.SLINGER)
	_ok(st != null and st.attack_range >= 8.0, "the road knows the Ruin Slinger")
	var n := 0
	for row: Array in MissionE8_01Fire.WAVES:
		for part: Array in row[2]:
			for r: Array in part[1]:
				if String(r[0]) == MissionE8_01.SLINGER:
					n += int(r[1])
	_ok(n >= 4, "the fire road's Host waves hold Ruin Slingers (%d)" % n)
	var out := m.host_wave([[MissionE8_01.SLINGER, 1]], Vector3(30.0, 0.0, -30.0), [], MissionE8_01.KEEP_POS)
	_ok(out.size() == 1 and int((out[0] as Unit).team) == m.host_team, "a Ruin Slinger spawns as a Host unit")
	return true
