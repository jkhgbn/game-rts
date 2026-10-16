extends SceneTree
## Campaign review fixes 2026-10-16 (docs/playtests/campaign_review_2026-10-16/summary.md, the weakest missions):
##   e2m3   the 6th tribute is the Grand Tribute (+150 % HP wagon, line 37), past the west road Malrik's ambush comes
##          out and hunts the wagon (mode tribute_hunt, an ambusher attacks it); the guides' hold is 1:00 on normal.
##   e4m2   the road jitter reads a walker's place in its convoy list (walker_index), not the instance id; convoy 2's lead
##          past ROAD[4] springs Hush's knives (knives_1, L33), which go for convoy 2's walkers; convoy 1 never does;
##          the auto times are one row shorter (normal 3:00 / 7:00 / 11:00 / 15:00).
##   e2m5   B3: Vessa on a lit Sunstone takes a sunshard (-20 % speed), at the Door it strikes: 600 + Exposed 10 s,
##          with Old Vey far away (the new verb, not the old stand-with-Vey lance).
##   e5m1   W1 from 2:30; the Millrace raid comes 20 s after its beacon; the Old Bridge starts Vey's Wall (30 s,
##          modifier, L27, W3 charging the bridge, free Fireballs near him), its end gives L30 and sends W3 on to the keep.
## Run: godot --headless --path . -s tests/test_cr_weak.gd --fixed-fps 60 --quit-after 40000 [-- --only=e2m3|e4m2|e2m5|e5m1]

const TASK_ID := "cr_weak"
const GAP_FRAMES := 3
const MISSIONS := {
	"e2m3": "res://missions/mission_e2_03.tscn",
	"e4m2": "res://missions/mission_e4_02.tscn",
	"e2m5": "res://missions/mission_e2_05.tscn",
	"e5m1": "res://missions/mission_e5_01.tscn",
}

var _parts: Array[String] = ["e2m3", "e4m2", "e2m5", "e5m1"]
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
	h.timeout_frames = 20000
	main = h.open(self, MISSIONS[_part], {"difficulty": 1, "set": {"campaign_save_path": "user://test_cr_weak_none.json"}})
	match _part:
		"e2m3":
			h.steps.add("the Grand Tribute and its ambush", _e2m3, 3000)
		"e4m2":
			h.steps.add("walker index, Hush's knives", _e4m2, 4000)
		"e2m5":
			h.steps.add("B3 sunshard", _e2m5, 4000)
		"e5m1":
			h.steps.add("dead start, farm warning, Vey's Wall", _e5m1, 6000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


# ---------------------------------------------------------------- e2m3

func _e2m3() -> bool:
	var m := main as MissionE2_03
	if not _v.has("c"):
		MissionHarness.immortal(m.hero)
		_ok(is_equal_approx(float(m.by_difficulty(MissionE2_03.GUIDES_SECONDS)), 60.0), "guides 1:00 on normal")
		m.tributes_paid = 5
		m._tribute_amount = m.tribute_gold()
		var c := m._spawn(m.make_unit("caravan"), Unit.Team.PLAYER, MissionE2_03.TRIBUTE_ROUTE[0] + Vector3(0.0, 0.0, 1.0))
		MissionHarness.immortal(c)
		var hp0 := c.max_hp
		m._load_tribute(c)
		_ok(m.is_grand(c) and c.max_hp >= hp0 * 2.4, "the Grand Tribute wagon (%.0f -> %.0f HP)" % [hp0, c.max_hp])
		_ok(m.said.has(37), "line 37")
		_v["c"] = c
		_v["f"] = 0
		return false
	var c: Unit = _v["c"]
	_v["f"] = int(_v["f"]) + 1
	if not m.grand_ambushed:
		if int(_v["f"]) > 1500:
			_ok(false, "the ambush never came (wp %d)" % m._wp)
			return true
		return false
	if not _v.has("units"):
		var units: Array = m.wave_units.get(&"GRAND", [])
		_ok(units.size() >= 6, "the ambush (%d)" % units.size())
		_ok(units.all(func(u: Variant) -> bool: return (u as Unit).get_meta(MissionBase.META_MODE, &"") == &"tribute_hunt"),
				"every ambusher hunts the wagon")
		_v["units"] = units
		_v["f"] = 0
		c.command_stop()
		# The hunt is checked without paths (an ambusher put 5 m from the wagon): the order, not the walk.
		for u: Variant in units:
			if u != m.shadow_hero:
				MissionHarness.put(u as Unit, c.global_position + Vector3(5.0, 0.0, 0.0))
				break
		return false
	for u: Variant in _v["units"]:
		if is_instance_valid(u) and (u as Unit).attack_target == c:
			_ok(true, "an ambusher attacks the wagon")
			return true
	if int(_v["f"]) > 1400:
		var info := ""
		for u: Variant in _v["units"]:
			if is_instance_valid(u) and (u as Unit).is_alive():
				var t: Variant = (u as Unit).attack_target
				info += " %.0f m/%s" % [(u as Unit).global_position.distance_to(c.global_position), str(t.name) if t is Node else "-"]
		_ok(false, "no ambusher went for the wagon (%s)" % info)
		return true
	return false


# ---------------------------------------------------------------- e4m2

func _e4m2() -> bool:
	var m := main as MissionE4_02
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(m.hero)
		for gid: StringName in m.groups:
			MissionHarness.kill(m.groups[gid])
		var bad := 0
		for c: Dictionary in m.convoys:
			var ws: Array = c["walkers"]
			for i in ws.size():
				if m.walker_index(ws[i] as Unit) != i or (ws[i] as Unit).has_meta(&"walker_ix"):
					bad += 1
		_ok(bad == 0, "walker index = place in the convoy list (%d wrong)" % bad)
		var w0: Unit = (m.convoys[0] as Dictionary)["walkers"][3]
		_ok(m._jitter(w0) == Vector3.ZERO, "jitter from the walker index (3 -> 0)")
		_ok(m.auto_times == [180.0, 420.0, 660.0, 900.0], "auto times %s" % str(m.auto_times))
		m._depart()   # convoy 1
		m._depart()   # convoy 2
		_v["f"] = 0
		return false
	_v["f"] = int(_v["f"]) + 1
	if not _v.has("put"):
		_v["put"] = true
		for i in 2:
			for w: Variant in (m.convoys[i] as Dictionary)["walkers"]:
				MissionHarness.immortal(w as Unit)
		var lead: Unit = (m.convoys[1] as Dictionary)["walkers"][0]
		MissionHarness.put(lead, MissionE4_02.ROAD[4])
		lead.set_meta(&"wp", MissionE4_02.KNIFE_WP)
		var other: Unit = (m.convoys[0] as Dictionary)["walkers"][0]
		MissionHarness.put(other, MissionE4_02.ROAD[4] + Vector3(0.0, 0.0, 2.0))
		other.set_meta(&"wp", MissionE4_02.KNIFE_WP)
		return false
	if not m.has_fired(&"knives_1"):
		if int(_v["f"]) > 120:
			_ok(false, "the knives never came for convoy 2")
			return true
		return false
	if not _v.has("checked"):
		_v["checked"] = true
		_ok(not m.has_fired(&"knives_0"), "convoy 1 meets no knives")
		_ok(m.said.has("L33") and m.knives_sent == 1, "L33, one squad")
		_v["f"] = 0
		return false
	for n in m.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and u.has_meta(&"_knife_convoy") and u.attack_target is Unit \
				and int((u.attack_target as Unit).get_meta(&"convoy", -1)) == 1:
			_ok(true, "a knife goes for convoy 2")
			return true
	if int(_v["f"]) > 1200:
		_ok(false, "no knife went for convoy 2's walkers")
		return true
	return false


# ---------------------------------------------------------------- e2m5

func _e2m5() -> bool:
	var m := main as MissionE2_05
	if not _v.has("t"):
		_v["t"] = true
		m.wake_up()
		MissionHarness.immortal(m.hero)
		m.boss.global_position = MissionE2_05.DOOR_RIM_N
		m.boss.command_stop()
		MissionHarness.immortal(m.boss)
		m.boss.hp = m.boss.max_hp * 0.34
		if m.vey and is_instance_valid(m.vey):
			MissionHarness.immortal(m.vey)
			MissionHarness.put(m.vey, MissionE2_05.KEEP_POS)
		var b: MissionBrazier = m.sunstones[1]
		b.light()
		_v["spd"] = m.hero.get_stat(&"move_speed")
		MissionHarness.put(m.hero, b.global_position)
		m.hero.command_stop()
		_v["f"] = 0
		return false
	_v["f"] = int(_v["f"]) + 1
	if m.vey and is_instance_valid(m.vey) and MissionBase._flat(m.vey.global_position, MissionE2_05.KEEP_POS) > 4.0:
		MissionHarness.put(m.vey, MissionE2_05.KEEP_POS)
	if m.boss_phase != 3:
		if int(_v["f"]) > 300:
			_ok(false, "B3 never started (%d)" % m.boss_phase)
			return true
		return false
	if not _v.has("took"):
		if not m.shard_carried:
			MissionHarness.put(m.hero, (m.sunstones[1] as Node3D).global_position)
			if int(_v["f"]) > 900:
				_ok(false, "no sunshard taken")
				return true
			return false
		_v["took"] = true
		_ok(m.hero.get_stat(&"move_speed") < float(_v["spd"]) * 0.9, "the carrier is slowed")
		_ok(m.hero.get_node_or_null(^"Sunshard") != null, "the shard glows over Vessa")
		_v["lances"] = m.lances
		_v["hp"] = m.boss.hp
		MissionHarness.put(m.hero, MissionE2_05.SOUTH_RIM)
		m.hero.command_stop()
		return false
	if m.shards_delivered < 1:
		if int(_v["f"]) > 1800:
			_ok(false, "the shard never reached the Door")
			return true
		return false
	_ok(m.lances == int(_v["lances"]) + 1 and m.exposed_left > 8.0, "the Door strikes, Exposed 10 s (%.1f)" % m.exposed_left)
	_ok(not m.shard_carried and m.hero.get_stat(&"move_speed") >= float(_v["spd"]) * 0.95, "the slow is gone")
	_ok(m.said.has(39) and m.said.has(30), "lines 39 and 30")
	return true


# ---------------------------------------------------------------- e5m1

func _e5m1() -> bool:
	var m := main as MissionE5_01
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(m.hero)
		MissionHarness.immortal(m.vey)
		_v["armor"] = m.vey.get_stat(&"armor")
		_ok(is_equal_approx(MissionE5_01.W1_EARLIEST, 150.0), "W1 from 2:30")
		(m.beacons[&"millrace"] as MissionBrazier).light()
		_v["mill_at"] = m.mission_time()
		return false
	if not _v.has("w2"):
		if m.waves_fired.has("W2"):
			var dt := m.mission_time() - float(_v["mill_at"])
			_ok(dt >= 19.0 and dt <= 22.0, "the Millrace raid 20 s after its beacon (%.1f)" % dt)
			_v["w2"] = true
			MissionHarness.put(m.hero, (m.beacons[&"bridge"] as Node3D).global_position + Vector3(-4.0, 0.0, -4.0))
			MissionHarness.put(m.vey, (m.beacons[&"bridge"] as Node3D).global_position + Vector3(-2.0, 0.0, -2.0))
			(m.beacons[&"bridge"] as MissionBrazier).light()
		return false
	if not _v.has("wall"):
		_v["wall"] = true
		_ok(m.wall_left > 25.0 and m.said.has("L27"), "Vey's Wall (%.1f s, L27)" % m.wall_left)
		_ok(m.vey.get_stat(&"armor") >= float(_v["armor"]) + 9.0, "the Wall's armor")
		var charge := m.get_tree().get_nodes_in_group(&"units").filter(func(n: Node) -> bool:
				return n is Unit and (n as Unit).is_alive() and (n as Unit).get_meta(MissionBase.META_MODE, &"") == &"charge")
		_ok(charge.size() >= 4, "W3 charges the bridge (%d)" % charge.size())
		_v["charge"] = charge
		MissionHarness.put(m.hero, m.vey.global_position + Vector3(-2.0, 0.0, 0.0))
		m.hero.mana = m.hero.get_stat(&"max_mana") - 45.0
		_v["mana"] = m.hero.mana
		_v["cast"] = m.hero.command_cast(&"fireball", m.hero.global_position + Vector3(-6.0, 0.0, 0.0))
		_v["cast_at"] = m.mission_time()
		return false
	if not _v.has("free"):
		if m.mission_time() - float(_v["cast_at"]) < 1.5:
			return false
		_v["free"] = true
		_ok(String(_v["cast"]) != "" or m.hero.mana >= float(_v["mana"]) - 6.0,
				"a free Fireball behind Vey (%.1f -> %.1f, %s)" % [float(_v["mana"]), m.hero.mana, _v["cast"]])
		m.wall_left = 0.2
		return false
	if not m.wall_done:
		return false
	if not _v.has("ended"):
		_v["ended"] = m.mission_time()
		_ok(m.said.has("L30") and m.vey.get_stat(&"armor") < float(_v["armor"]) + 1.0, "the Wall ends (L30, modifier off)")
		return false
	if m.mission_time() - float(_v["ended"]) < 2.0:
		return false
	var left: Array = (_v["charge"] as Array).filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	_ok(left.all(func(u: Variant) -> bool: return (u as Unit).get_meta(MissionBase.META_MODE, &"") != &"charge"),
			"the charge goes on to Valewatch")
	return true
