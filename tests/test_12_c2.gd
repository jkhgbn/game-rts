extends SceneTree
## Task 12.C2 (docs/design/map-fill.md 4, contract 13, "Done when" 12.C2): CapturePoint + CapturePoints on a bare
## level (no skirmish: 12.C1 creates the service there). Units are frozen (process disabled) so only the capture
## rules move; the match clock is a fake (real time + an offset) so the 2:30 / 3:00 / 6:00 / 9:00 events can be reached
## quickly. Checks: capture times 12 / 15 / 8 s, x1.25 on the far bank, rate cap 1.75, wizard counts 2, workers /
## caravans / trackers / creatures do not count, contest freezes, decay 10 %/s, neutralise then capture, tower sight 22
## follows the owner, well income 2 every 5 s from 2:30 + 3 mana / s to the owner's wizard within 8 m, shrines wake
## both at 3:00 then alternate from the slower side's bank, blessing +12 % speed / +1.5 HP/s for 60 s to soldiers,
## wizards (and units spawned meanwhile) but not workers, refresh without stacking, messages throttled.
## Run:  godot --headless --path . -s tests/test_12_c2.gd --fixed-fps 60 --quit-after 9500

const TASK_ID := "12.C2"
const TIMEOUT_FRAMES := 9000
const SERVICE_PATH := "res://scripts/world/capture_points.gd"
const P := 0
const E := 1
const N := 2
const TOL := 0.4
const SPOTS := [
	{"id": &"tower_a", "name": "Tower A", "kind": &"watchtower", "pos": Vector3(-40, 0, -40), "bank": 0},
	{"id": &"tower_b", "name": "Tower B", "kind": &"watchtower", "pos": Vector3(40, 0, 40), "bank": 1},
	{"id": &"tower_c", "name": "Tower C", "kind": &"watchtower", "pos": Vector3(-40, 0, 0), "bank": 0},
	{"id": &"tower_d", "name": "Tower D", "kind": &"watchtower", "pos": Vector3(-40, 0, 40), "bank": 0},
	{"id": &"tower_e", "name": "Tower E", "kind": &"watchtower", "pos": Vector3(-80, 0, -40), "bank": 0},
	{"id": &"tower_f", "name": "Tower F", "kind": &"watchtower", "pos": Vector3(-80, 0, 0), "bank": 0},
	{"id": &"tower_g", "name": "Tower G", "kind": &"watchtower", "pos": Vector3(-80, 0, 40), "bank": 0},
	{"id": &"well_w", "name": "Test Well", "kind": &"well", "pos": Vector3(0, 0, -80), "bank": 0},
	{"id": &"shrine_w", "name": "West Shrine", "kind": &"shrine", "pos": Vector3(-40, 0, 80), "bank": 0},
	{"id": &"shrine_e", "name": "East Shrine", "kind": &"shrine", "pos": Vector3(40, 0, 80), "bank": 1},
]

var level: Node3D
var svc: Node
var total := 0
var real := 0.0
var offset := 0.0
var _done := false
var _errors: Array[String] = []
var _messages: Array[String] = []
var _captured: Array = []       # [id, team, real]
var _neutralised: Array = []    # [id, old_team, real]
var _awakened: Array = []       # [id, clock]
var _bless_started := {P: 0, E: 0}
var _bless_ended := {P: 0, E: 0}
var _far := 0.0


func _initialize() -> void:
	_run()


func _process(delta: float) -> bool:
	total += 1
	real += delta
	if total > TIMEOUT_FRAMES and not _done:
		_errors.append("timed out at frame %d" % total)
		return _finish()
	return _done


func clock() -> float:
	return real + offset


func _set_clock(t: float) -> void:
	offset = t - real


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	_done = true
	return true


func _check(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)
		print("  x ", what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait_until(t_real: float) -> void:
	while real < t_real and total < TIMEOUT_FRAMES:
		await process_frame


func _until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if bool(cond.call()):
			return true
		await process_frame
	return bool(cond.call())


func _spawn(unit: Unit, team: int, pos: Vector3, group: StringName = &"") -> Unit:
	unit.team = team
	unit.process_mode = Node.PROCESS_MODE_DISABLED   # frozen: no fights, no gravity, no regen
	if group != &"":
		unit.add_to_group(group)
	unit.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE   # the body stays in the physics space
	level.add_child(unit)
	unit.global_position = pos
	for c in unit.get_children():
		if c is NavigationAgent3D:
			(c as NavigationAgent3D).avoidance_enabled = false
	return unit


func _make(type_id: String) -> Unit:
	return Worker.make_unit(UnitType.find(type_id))


func _pt(id: StringName) -> Node3D:
	return svc.call(&"point_by_id", id)


func _count_msg(text: String) -> int:
	return _messages.count(text)


func _move(u: Node3D, pos: Vector3) -> void:
	u.global_position = pos


func _away() -> Vector3:
	_far += 3.0
	return Vector3(300.0 + _far, 0.0, 300.0)


# ---------------------------------------------------------------- the run

func _run() -> void:
	await process_frame
	level = Node3D.new()
	level.name = "Level"
	root.add_child(level)
	current_scene = level
	if not ResourceLoader.exists(SERVICE_PATH):
		_errors.append("capture_points.gd missing")
		_finish()
		return
	for t: int in [P, E]:
		var bank := EssenceBank.for_team(t)
		bank.trickle_enabled = false
	svc = (load(SERVICE_PATH) as GDScript).new()
	svc.name = "CapturePoints"
	svc.set(&"match_time_source", clock)
	level.add_child(svc)
	svc.connect(&"message", func(text: String, _s: float) -> void: _messages.append(text))
	svc.connect(&"point_captured", func(p: Node3D, team: int) -> void:
		_captured.append([StringName(p.get(&"point_id")), team, real]))
	svc.connect(&"point_neutralised", func(p: Node3D, old: int) -> void:
		_neutralised.append([StringName(p.get(&"point_id")), old, real]))
	svc.connect(&"shrine_awakened", func(p: Node3D) -> void:
		_awakened.append([StringName(p.get(&"point_id")), clock()]))
	svc.connect(&"blessing_started", func(team: int, _s: float) -> void: _bless_started[team] += 1)
	svc.connect(&"blessing_ended", func(team: int) -> void: _bless_ended[team] += 1)
	svc.call(&"setup", SPOTS)
	await _frames(2)
	_check_basics()
	await _phase_captures()
	await _phase_neutralise_and_wells()
	await _phase_shrines()
	_finish()


func _check_basics() -> void:
	_check((svc.call(&"points") as Array).size() == 10, "10 points registered")
	_check((svc.call(&"points", &"shrine") as Array).size() == 2, "2 shrines")
	var a := _pt(&"tower_a")
	_check(a != null and a.is_in_group(&"capture_points"), "group capture_points")
	_check(a != null and not a.is_in_group(&"units") and not a.is_in_group(&"buildings"), "not a unit / building")
	_check(a != null and not bool(a.call(&"is_targetable")) and bool(a.call(&"is_invulnerable"))
			and bool(a.call(&"is_alive")), "invulnerable, never a target")
	if a:
		a.call(&"take_damage", 500.0, null)
		_check(int(a.get(&"team")) == N and int(a.get(&"owner_team")) == -1, "neutral, unowned")
		var r: Rect2 = a.call(&"footprint_rect")
		_check(is_equal_approx(r.size.x, 4.0), "tower footprint 4 x 4")
	_check(get_first_node_in_group(&"capture_points_service") == svc, "service group")
	var sw := _pt(&"shrine_w")
	_check(sw != null and StringName(sw.get(&"state")) == &"asleep", "shrine asleep at 0:00")
	_check(sw != null and absf(float(sw.call(&"time_until_awake")) - 180.0) < 1.0, "shrine wakes in 3:00")
	var nw: Dictionary = svc.call(&"next_waking")
	_check(is_equal_approx(float(nw.get("time", -1.0)), 180.0) and (nw.get("points", []) as Array).size() == 2,
			"next_waking = both at 3:00")
	var w := _pt(&"well_w")
	_check(w != null and is_equal_approx(float(w.get(&"capture_radius")), 6.0)
			and is_equal_approx(float(w.get(&"capture_time")), 15.0), "well radius 6, 15 s")
	_check(sw != null and is_equal_approx(float(sw.get(&"capture_time")), 8.0), "shrine 8 s")


func _capture_time(id: StringName, team: int) -> float:
	for c in _captured:
		if c[0] == id and c[1] == team:
			return float(c[2])
	return -1.0


var _pa_soldier: Unit
var _wiz: Unit
var _g_soldier: Unit


func _phase_captures() -> void:
	var t0 := real
	_pa_soldier = _spawn(_make("flame_guard"), P, Vector3(-40, 0, -35))
	_spawn(_make("flame_guard"), P, Vector3(40, 0, 35))                   # far bank: 15 s
	for i in 3:
		_spawn(_make("flame_guard"), P, Vector3(-40 + i, 0, 5))            # 3 soldiers: rate 1.5 -> 8 s
	_wiz = _spawn(Wizard.new(), P, Vector3(-40, 0, 45))                    # wizard counts 2 -> 9.6 s
	for i in 5:
		_spawn(_make("flame_guard"), P, Vector3(-80 + i, 0, -35))          # 5 soldiers: cap 1.75 -> 6.86 s
	_spawn(_make("cinder_hand"), P, Vector3(-80, 0, 3))                    # worker
	_spawn(_make("caravan"), P, Vector3(-78, 0, 3))                        # caravan
	_spawn(_make("greywater_tracker"), P, Vector3(-82, 0, 3), &"trackers")  # tracker
	_spawn(_make("flame_guard"), N, Vector3(-80, 0, -3), &"creatures")     # a creature (neutral)
	_spawn(_make("flame_guard"), P, Vector3(0, 0, -76))                    # well: 15 s
	_g_soldier = _spawn(_make("flame_guard"), P, Vector3(-80, 0, 44))      # tower G: contest / decay
	svc.call(&"refresh")
	_check(int(svc.call(&"presence", P, _pt(&"tower_d"))) == 2, "the wizard counts 2")
	_check(int(svc.call(&"presence", P, _pt(&"tower_c"))) == 3, "3 soldiers count 3")
	_check(int(svc.call(&"presence", P, _pt(&"tower_f"))) == 0 and int(svc.call(&"presence", N, _pt(&"tower_f"))) == 0,
			"workers / caravans / trackers / creatures do not count")
	# Tower G: 4 s alone, then contested 3 s, then abandoned.
	await _wait_until(t0 + 4.0)
	var g := _pt(&"tower_g")
	var g_before := float(g.get(&"progress"))
	_check(absf(g_before - 4.0 / 12.0) < 0.04, "tower G at 1/3 after 4 s (%.3f)" % g_before)
	var g_enemy := _spawn(_make("shade"), E, Vector3(-80, 0, 36))
	svc.call(&"refresh")
	await _frames(20)
	g_before = float(g.get(&"progress"))
	await _wait_until(t0 + 7.0)
	_check(StringName(g.get(&"state")) == &"contested" and bool(g.call(&"is_contested")), "contested state")
	_check(absf(float(g.get(&"progress")) - g_before) < 0.001, "contest freezes the progress")
	_move(_g_soldier, _away())
	_move(g_enemy, _away())
	svc.call(&"refresh")
	var decay_from := float(g.get(&"progress"))
	var decay_t := real
	await _wait_until(t0 + 9.5)
	var expect := decay_from - 0.1 * (real - decay_t)
	_check(absf(float(g.get(&"progress")) - expect) < 0.04, "decay 10 %%/s (%.3f vs %.3f)" % [float(g.get(&"progress")), expect])
	await _wait_until(t0 + 11.5)
	_check(float(g.get(&"progress")) <= 0.0 and int(g.get(&"capture_team")) == -1, "half capture reverted")
	_move(_g_soldier, Vector3(-80, 0, 44))
	svc.call(&"refresh")
	await _wait_until(t0 + 16.5)
	var expect_times := {&"tower_a": 12.0, &"tower_b": 15.0, &"tower_c": 8.0, &"tower_d": 9.6, &"tower_e": 12.0 / 1.75,
			&"well_w": 15.0}
	for id: StringName in expect_times:
		var at := _capture_time(id, P)
		_check(at >= 0.0 and absf(at - t0 - float(expect_times[id])) < TOL,
				"%s captured in %.2f s (expected %.2f)" % [id, at - t0, expect_times[id]])
	_check(float(_pt(&"tower_f").get(&"progress")) == 0.0 and int(_pt(&"tower_f").get(&"owner_team")) == -1,
			"tower F untouched by non-counting units")
	_check(_count_msg("Your forces captured Tower A") == 1, "capture message")
	_check(_count_msg("Your forces are capturing Tower G") == 1, "capturing message throttled (60 s)")
	var marker: Variant = _pt(&"tower_a").call(&"sight_marker")
	_check(marker is Node3D and int((marker as Node3D).get(&"team")) == P
			and is_equal_approx(float((marker as Node3D).get(&"sight_radius")), 22.0)
			and (marker as Node3D).is_in_group(&"fog_sources"), "tower sight 22 for the owner")
	_check((svc.call(&"held_by", P, &"watchtower") as Array).size() == 5, "held_by: 5 towers")


func _phase_neutralise_and_wells() -> void:
	var t0 := real
	_move(_pa_soldier, _away())
	var taker := _spawn(_make("shade"), E, Vector3(-40, 0, -35))
	svc.call(&"refresh")
	# Well test on the fake clock: 2:28 now.
	_set_clock(148.0)
	var w := _pt(&"well_w")
	_move(_wiz, w.global_position + Vector3(3, 0, 0))
	var e_wiz := _spawn(Wizard.new(), E, w.global_position + Vector3(0, 0, 7.5))   # outside the 6 m circle
	svc.call(&"refresh")
	var pbank := EssenceBank.for_team(P)
	var ebank := EssenceBank.for_team(E)
	await _until(func() -> bool: return clock() >= 150.3, 400)
	_check(_count_msg("The essence wells are brimming") == 1, "wells brimming message at 2:30")
	var e0 := pbank.essence
	var ee0 := ebank.essence
	_wiz.set(&"mana", 0.0)
	e_wiz.set(&"mana", 0.0)
	await _until(func() -> bool: return clock() >= 152.3, 400)
	_check(absf(float(_wiz.get(&"mana")) - 6.0) < 0.8, "+3 mana/s to the owner's wizard (%.2f)" % float(_wiz.get(&"mana")))
	_check(float(e_wiz.get(&"mana")) == 0.0, "no mana to the other wizard")
	await _until(func() -> bool: return clock() >= 155.4, 400)
	_check(pbank.essence == e0 + 2, "well pays 2 at 2:35 (%d)" % (pbank.essence - e0))
	await _until(func() -> bool: return clock() >= 160.4, 400)
	_check(pbank.essence == e0 + 4, "well pays 2 every 5 s (%d)" % (pbank.essence - e0))
	_check(ebank.essence == ee0, "no income for the non-owner")
	# Neutralise then capture (the enemy on the player bank: x1.25 -> 15 s each).
	var a := _pt(&"tower_a")
	await _until(func() -> bool: return int(a.get(&"owner_team")) == -1, 1200)
	var n_at := real - t0
	_check(absf(n_at - 15.0) < TOL, "neutralised in %.2f s (expected 15)" % n_at)
	_check(_neutralised.size() == 1 and _neutralised[0][1] == P, "point_neutralised(old = player)")
	_check(_count_msg("Tower A was neutralised") == 1, "neutralised message")
	_check(a.call(&"sight_marker") == null, "no sight once neutral")
	await _until(func() -> bool: return int(a.get(&"owner_team")) == E, 1200)
	_check(absf(real - t0 - 30.0) < TOL * 2.0, "then captured in %.2f s (expected 30)" % (real - t0))
	var marker: Variant = a.call(&"sight_marker")
	_check(marker is Node3D and int((marker as Node3D).get(&"team")) == E, "tower sight follows the owner")
	_check(_count_msg("The enemy is taking Tower A!") == 1, "taking message once per 20 s")
	_check(_count_msg("The enemy captured Tower A") == 1, "enemy capture message")
	_move(taker, _away())
	_move(_wiz, _away())
	_move(e_wiz, _away())
	svc.call(&"refresh")


func _phase_shrines() -> void:
	var sw := _pt(&"shrine_w")
	var se := _pt(&"shrine_e")
	var e_worker := _spawn(_make("cinder_hand"), E, Vector3(100, 0, 100))
	var e_soldier := _spawn(_make("shade"), E, Vector3(110, 0, 100))
	var e_wiz := _spawn(Wizard.new(), E, Vector3(120, 0, 100))
	var p_shrine := _spawn(_make("flame_guard"), P, sw.global_position + Vector3(0, 0, 2))
	svc.call(&"refresh")
	_set_clock(178.0)
	await _frames(60)
	_check(float(sw.get(&"progress")) == 0.0 and StringName(sw.get(&"state")) == &"asleep", "asleep shrine can't be taken")
	_move(p_shrine, _away())   # the player comes later (slower at 3:00)
	var e_shrine := _spawn(_make("shade"), E, se.global_position + Vector3(0, 0, 2))
	svc.call(&"refresh")
	await _until(func() -> bool: return clock() >= 180.3, 200)
	_check(bool(sw.call(&"is_awake")) and bool(se.call(&"is_awake")), "both shrines wake at 3:00")
	_check(_count_msg("The Wayshrines awaken") == 1, "3:00 message")
	_check(float(sw.call(&"time_until_awake")) == INF, "awake: time_until_awake INF")
	await _until(func() -> bool: return clock() >= 183.0, 400)
	_move(p_shrine, sw.global_position + Vector3(0, 0, 2))
	svc.call(&"refresh")
	var t_e := clock()
	await _until(func() -> bool: return int(se.get(&"owner_team")) == E, 900)
	_check(absf(clock() - 180.0 - 8.0) < TOL, "shrine captured in 8 s (%.2f)" % (clock() - 180.0))
	_check(not bool(se.call(&"is_awake")), "captured shrine sleeps")
	_move(e_shrine, _away())   # so the 9:00 waking does not refresh the enemy blessing
	await _frames(2)
	_check(absf(float(svc.call(&"blessing_time_left", E)) - 60.0) < 0.5, "enemy blessed 60 s")
	var base_speed := e_soldier.get_base_stat(&"move_speed")
	_check(e_soldier.has_modifier(&"blessing:wayshrine") and absf(e_soldier.get_stat(&"move_speed") / base_speed - 1.12) < 0.001,
			"blessing +12 % speed on soldiers")
	_check(absf(e_soldier.get_stat(&"hp_regen") - e_soldier.get_base_stat(&"hp_regen") - 1.5) < 0.001, "blessing +1.5 HP/s")
	_check(e_wiz.has_modifier(&"blessing:wayshrine"), "blessing on the wizard")
	_check(not e_worker.has_modifier(&"blessing:wayshrine"), "no blessing on workers")
	_check(not p_shrine.has_modifier(&"blessing:wayshrine"), "no blessing on the other team")
	_check(_count_msg("The enemy received the Wayshrine's blessing") == 1, "enemy blessing message")
	var late := _spawn(_make("shade"), E, Vector3(130, 0, 100))
	await _frames(2)
	_check(late.has_modifier(&"blessing:wayshrine"), "a unit spawned during the blessing gets it")
	await _until(func() -> bool: return int(sw.get(&"owner_team")) == P, 900)
	_check(absf(clock() - t_e - 8.0) < TOL, "player shrine in 8 s")
	_check(_count_msg("Blessing of the Wayshrine: +12 % speed, +1.5 HP / s for 60 s") == 1, "own blessing message")
	var nw: Dictionary = svc.call(&"next_waking")
	_check(nw.get("point") == sw and is_equal_approx(float(nw.get("time", 0.0)), 360.0),
			"6:00 shrine on the slower side's bank (player)")
	_check(absf(float(sw.call(&"time_until_awake")) - (360.0 - clock())) < 0.5, "time_until_awake counts to 6:00")
	# 6:00: the west shrine wakes, the player's soldier still stands there -> refresh, no stack.
	_set_clock(359.0)
	await _until(func() -> bool: return bool(sw.call(&"is_awake")), 200)
	_check(not bool(se.call(&"is_awake")), "only one shrine wakes at 6:00")
	_check(_count_msg("The West Shrine awakens") == 1, "6:00 message")
	_check(int(sw.get(&"owner_team")) == -1, "a waking shrine turns neutral")
	await _frames(240)
	var left_before := float(svc.call(&"blessing_time_left", P))
	await _until(func() -> bool: return int(sw.get(&"owner_team")) == P, 900)
	await _frames(1)
	_check(left_before < 59.0 and float(svc.call(&"blessing_time_left", P)) > 59.5, "a second shrine resets to 60 s")
	_check(_bless_started[P] == 2 and p_shrine.has_modifier(&"blessing:wayshrine"), "refresh, one modifier")
	nw = svc.call(&"next_waking")
	_check(nw.get("point") == se and is_equal_approx(float(nw.get("time", 0.0)), 540.0), "9:00 alternates to the east bank")
	_set_clock(539.0)
	await _until(func() -> bool: return bool(se.call(&"is_awake")), 200)
	_check(bool(se.call(&"is_awake")) and not bool(sw.call(&"is_awake")), "9:00: the east shrine wakes")
	# The enemy blessing runs out 60 s after it started.
	await _until(func() -> bool: return float(svc.call(&"blessing_time_left", E)) <= 0.0, 4000)
	await _frames(1)
	_check(_bless_ended[E] == 1, "blessing_ended(enemy)")
	_check(not e_soldier.has_modifier(&"blessing:wayshrine") and not late.has_modifier(&"blessing:wayshrine")
			and not e_wiz.has_modifier(&"blessing:wayshrine"), "blessing removed after 60 s")
	_check(absf(e_soldier.get_stat(&"move_speed") - base_speed) < 0.001, "speed back to base")
	_check(_awakened.size() == 4, "4 wakings (2 + 1 + 1): %d" % _awakened.size())
