extends SceneTree
## Campaign review 2026-10-16 fixes, Episode 8 missions 2 and 3.
## e8m2 (static): the march floors are halved (A2 / B1 / B2 at most 7:00 / 9:00 / 12:00 on normal), the bars fill
## faster, every floor is well under its bar's own time (help kills / answered calls really bring a march forward),
## and every kingdom has a march beat (a line + a set piece).
## e8m3 (live): no fixed phase floors (a phase changes on the King's HP once PHASE_LOCKOUT has run since the previous
## one), the hero's Ward Mend (+25 %, cooldown, relights a broken ward), the ward warnings at 50 % / 25 %, the ward HP
## and Mend state in the objective line, and the load-guarded Hollow King dress hook.
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_cr_e8.gd --fixed-fps 60 --quit-after 20000
## Prints "PASS cr_e8" or "FAIL cr_e8: <reasons>".

var h := MissionHarness.new()
var m: MissionE8_03
var _settle := 0
var _wait := 0
var _before := 0.0


func _initialize() -> void:
	h.task_id = "cr_e8"
	h.timeout_frames = 9000
	_check_e8m2()
	m = h.open(self, "res://missions/mission_e8_03.tscn", {"difficulty": 1}) as MissionE8_03
	h.steps.add("intro done", func() -> bool:
		_settle += 1
		return _settle > 60, 600)
	h.steps.add("static e8m3 rules", _static_e8m3, 10)
	h.steps.add("mend set up", _mend_setup, 10)
	h.steps.add("mend +25 %", _mend_done, 600)
	h.steps.add("mend on cooldown", _cooldown_setup, 10)
	h.steps.add("no mend while cooling down", _cooldown_check, 400)
	h.steps.add("relight set up", _relight_setup, 10)
	h.steps.add("broken ally ward relit", _relight_done, 600)
	h.steps.add("ward warnings", _warnings, 120)
	h.steps.add("phase lock-out", _phases, 10)


func _process(_d: float) -> bool:
	return h.tick()


func _check_e8m2() -> void:
	var old_floor := {Teams.ALLY: 840.0, Unit.Team.ENEMY: 1080.0, Teams.ENEMY_2: 1440.0}
	for s: int in [Teams.ALLY, Unit.Team.ENEMY, Teams.ENEMY_2]:
		var fl: Array = MissionE8_02.MARCH_FLOOR[s]
		var bar: Array = MissionE8_02.MUSTER_TIME[s]
		h.check(float(fl[1]) <= float(old_floor[s]) * 0.5 + 0.1, "e8m2 seat %d floor %.0f is not halved" % [s, float(fl[1])])
		for d in 3:
			h.check(float(fl[d]) <= float(bar[d]) * 0.75, "e8m2 seat %d diff %d: floor %.0f too close to the bar %.0f" % [s, d,
					float(fl[d]), float(bar[d])])
	h.check(float(MissionE8_02.MUSTER_TIME[Teams.ENEMY_2][1]) <= 1080.0, "e8m2 last bar still too slow for ~20 min (was 1440)")
	for k: StringName in [&"fire", &"shadow", &"ice", &"nature"]:
		var b: Variant = MissionE8_02.MARCH_BEAT.get(k)
		h.check(b is Array and String((b as Array)[0]) != "" and (float((b as Array)[3]) > 0.0 or StringName((b as Array)[1]) != &""),
				"e8m2 no march beat for %s" % k)


func _clear_host(at: Vector3) -> void:
	for u: Unit in m.host_near(at, 14.0):
		u.leave_map()


func _static_e8m3() -> bool:
	var consts := (m.get_script() as Script).get_script_constant_map()
	h.check(not consts.has("PHASE2_FLOOR") and not consts.has("PHASE3_FLOOR"), "e8m3 still has fixed phase floors")
	h.check(float(consts.get("PHASE_LOCKOUT", 0.0)) >= 180.0 and float(consts.get("PHASE_LOCKOUT", 0.0)) <= 240.0,
			"e8m3 PHASE_LOCKOUT not 3-4 min")
	h.check(m.king != null and is_instance_valid(m.king), "no King")
	if ResourceLoader.exists(MissionE8_03.KING_ART):
		h.check(m.king.has_meta(&"_king_dressed"), "the Hollow King art exists but dress() was not called")
		var art := load(MissionE8_03.KING_ART) as Script
		h.check(bool(art.call(&"is_dressed", m.king)), "HollowKingArt.is_dressed is false on the King")
	var txt := m.objective_text(&"obj_keys")
	h.check(txt.contains("Ward Mend") and txt.contains("%"), "obj_keys line without ward HP / Mend: %s" % txt)
	return true


func _mend_setup() -> bool:
	var at := MissionE8Muster.keyhole_of(Unit.Team.PLAYER)
	_clear_host(at)
	m.mend_ready_at = 0.0
	m.ward[Unit.Team.PLAYER] = m.ward_max * 0.4
	_before = float(m.ward[Unit.Team.PLAYER])
	m.hero.set_down(at + Vector3(-2.0, 0.0, 2.0))
	m.hero.command_stop()
	return true


func _mend_done() -> bool:
	_clear_host(MissionE8Muster.keyhole_of(Unit.Team.PLAYER))
	return float(m.ward[Unit.Team.PLAYER]) >= _before + m.ward_max * 0.24 and m.mend_ready_at > m.mission_time()


func _cooldown_setup() -> bool:
	m.ward[Unit.Team.PLAYER] = m.ward_max * 0.4
	_before = float(m.ward[Unit.Team.PLAYER])
	_wait = 0
	h.check(m.objective_text(&"obj_keys").contains("Ward Mend 0:"), "the Mend cooldown is not shown: %s" % m.objective_text(&"obj_keys"))
	return true


func _cooldown_check() -> bool:
	_clear_host(MissionE8Muster.keyhole_of(Unit.Team.PLAYER))
	_wait += 1
	if _wait < 300:
		return false
	h.check(float(m.ward[Unit.Team.PLAYER]) < _before + m.ward_max * 0.1, "Ward Mend fired again during its cooldown")
	return true


func _relight_setup() -> bool:
	var s := Teams.ALLY
	var at := MissionE8Muster.keyhole_of(s)
	_wait = 0
	_clear_host(at)
	m.mend_ready_at = 0.0
	m.ward[s] = 0.0
	m.broken[s] = m.mission_time() - MissionE8_03.RELIGHT_WAIT - 1.0
	var w: Wizard = m.seat_wizard.get(s)
	if w and is_instance_valid(w):
		w.set_down(MissionE8Muster.keep_pos(s))   # its own relight must not do the job
		w.command_stop()
	m.hero.set_down(at + (MissionE8Muster.keep_pos(s) - at).normalized() * 4.0)
	m.hero.command_stop()
	return true


func _relight_done() -> bool:
	_clear_host(MissionE8Muster.keyhole_of(Teams.ALLY))
	var w: Wizard = m.seat_wizard.get(Teams.ALLY)
	if w and is_instance_valid(w) and MissionBase._flat(w.global_position, MissionE8Muster.keyhole_of(Teams.ALLY)) < 8.0:
		w.set_down(MissionE8Muster.keep_pos(Teams.ALLY))
	if m.broken.has(Teams.ALLY):
		return false
	h.check(float(m.ward[Teams.ALLY]) >= m.ward_max * 0.45, "relit ward not at half")
	return true


func _warnings() -> bool:
	var s := Unit.Team.ENEMY
	_wait += 1
	if _wait == 1:
		m.ward_warned.erase(s)
		m.ward[s] = m.ward_max * 0.45
	elif _wait == 50:
		h.check(int(m.ward_warned.get(s, -1)) == 0, "no 50 %% warning (%s)" % str(m.ward_warned))
		m.ward[s] = m.ward_max * 0.2
	elif _wait == 100:
		h.check(int(m.ward_warned.get(s, -1)) == 1, "no 25 %% warning (%s)" % str(m.ward_warned))
		m.ward[s] = m.ward_max
		return true
	return false


func _phases() -> bool:
	var k := m.king
	var t := m.mission_time()
	m.phase = 1
	m.phase_at = t
	m.king_max = k.max_hp
	k.hp = k.max_hp * 0.61
	m.chain_hit(0.05)
	h.check(m.phase == 1, "phase 2 opened inside the lock-out")
	h.check(k.hp >= k.max_hp * 0.6 - 1.0, "the King went under 60 % in phase 1")
	m.phase_at = t - MissionE8_03.PHASE_LOCKOUT - 1.0
	m.chain_hit(0.01)
	h.check(m.phase == 2, "phase 2 did not open on damage after the lock-out (t %.0f, old floor was 1020)" % t)
	k.hp = k.max_hp * 0.26
	m.chain_hit(0.05)
	h.check(m.phase == 2, "phase 3 opened inside the lock-out")
	m.phase_at = m.mission_time() - MissionE8_03.PHASE_LOCKOUT - 1.0
	m.chain_hit(0.01)
	h.check(m.phase == 3, "phase 3 did not open on damage after the lock-out")
	return true
