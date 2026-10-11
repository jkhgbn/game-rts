extends SceneTree
## Mission e3m2 timing check (docs/design/mission-e3-02.md acceptance E3M2.S2 + phase 2; total 14-18 min on normal with
## the cutscene fallbacks): a scripted stealth run on normal with real fights, no hero protection, no kills or time
## skips by the test. Cinematics off; the spec lengths of e3m2_slip 0:15, e3m2_embers 0:25 and e3m2_dawn 0:30 (+2 s)
## are added to the reported play time.
## The stealth player (what a careful human does): the squad waits in the dark at the foot (the safe line); Mother Hush
## works alone, veiled (seen within 3 m only), walking dark roads through the crest gaps and waiting for patrols to pass
## (`_sneak`), looking at each wagon 15 s from a dark staging spot first. WG2 first: F6 snuffed under Smoke Cloak while
## Old Vey rests at the tree end of his vigil, then the veiled sabotage under a second smoke. The guarded wagons (WG4,
## WG3, WG1: 3-4 guards in a 3 m ring, closer than a veiled Hush can pass) are emptied by a lure: a Nightblood Reaver
## shows itself 7 m from the wagon, stands the 3 s fuse and runs home; the camp alert keeps the guards on that spot
## while Hush spoils the wagon from the other side (3 alarms: Vessa wakes on the last). Hit or hunted, Hush drops Smoke
## Cloak and runs for the dark, away from everyone. Dawn: Malrik calls Hush (V, free), trains 2 Nightblood Reavers, the
## squad holds a loose line south of the keep (SimTactics), Vessa first.
## `-- --seed N`, `-- --verbose`. Slow-ish. Run: godot --headless --path . -s tests/test_e3m2_sim.gd --fixed-fps 60 --quit-after 80000

const TASK_ID := "e3m2_sim"
const MISSION := "res://missions/mission_e3_02.tscn"
const CUTSCENE_SECONDS := {&"slip": 15.0, &"embers": 25.0, &"dawn": 32.0}
const SQUAD_WAIT := Vector3(-4.0, 0.0, 9.0)   ## the foot, out of the crest fires' light (F2 is 20 m away)
const FOOT := Vector3(6.0, 0.0, 14.0)          ## where Hush starts and ends every trip
## Per wagon: [wagon id, the way from the foot (dark points), the staging spot in the dark near the wagon, mode (veil /
## lure / assault), where the lure shows itself (offset from the wagon, away from Hush's side), optional way home].
## A guarded wagon (lure = true) is emptied by a Hound lure first; WG2 (Old Vey only) goes first, before Alarm 2 adds
## guards to every wagon left. The sabotage spot is picked live: the side farthest from the guards.
const PLAN := [
	[&"WG2", [Vector3(24.0, 0.0, 12.0), Vector3(29.0, 0.0, 22.0), Vector3(29.0, 0.0, 38.0), Vector3(12.0, 0.0, 58.0)], Vector3(0.0, 0.0, 55.0), &"veil", Vector3.ZERO,
		[Vector3(-5.0, 0.0, 44.0), Vector3(-25.0, 0.0, 39.5), Vector3(-29.5, 0.0, 34.0), Vector3(-29.5, 0.0, 20.0)]],
	[&"WG4", [Vector3(24.0, 0.0, 12.0), Vector3(40.0, 0.0, 10.0)], Vector3(56.0, 0.0, 16.0), &"lure", Vector3(-7.0, 0.0, 0.0)],
	[&"WG3", [Vector3(24.0, 0.0, 12.0), Vector3(40.0, 0.0, 10.0), Vector3(64.0, 0.0, 14.0), Vector3(66.0, 0.0, 30.0), Vector3(62.0, 0.0, 44.0)], Vector3(50.0, 0.0, 58.0), &"lure", Vector3(0.0, 0.0, -7.0)],
	[&"WG1", [Vector3(-30.0, 0.0, 14.0), Vector3(-58.0, 0.0, 22.0), Vector3(-68.0, 0.0, 34.0), Vector3(-69.0, 0.0, 47.0)], Vector3(-66.0, 0.0, 53.0), &"assault", Vector3(0.0, 0.0, -7.0)],
]
const VEY_CLEAR := 10.5   ## WG2: Old Vey at least this far from the sabotage spot (his far pause: ~12 m; sees veiled at 3)
const WG2_FIRE := 5        ## F6, the fire that lights WG2 (MissionE3_02.FIRES)
const SCOUT_TIME := 35.0   ## a human watches the guards and a patrol loop from the staging spot before going in
const PATROL_CLEAR := 13.0   ## a patrol this close to a fire or a sabotage spot: wait in the dark
const KEEP_LINE := Vector3(-6.0, 0.0, -34.0)

var verbose := false
var h := MissionHarness.new()
var main: MissionE3_02
var phase := &"night"
var _tick := 0.0
var _last_print := -1
var _phase_log: Array[String] = []
var _wi := 0
var _step := &"stage"
var _step_since := 0.0
var _night_end := -1.0
var _wounded := {}
var _reavers := 0
var _last_go := Vector3.INF
var _alarms_seen := 0
var _via_i := 0
var _spot := Vector3.INF
var _cloak_at := Vector3.INF
var _fire_i := 5
var _after_snuff := &"back"
var _flee_to := Vector3.INF
var _sneak_pos := Vector3.INF
var _sneak_to := Vector3.INF
var _sneak_since := 0.0
var _hurt_hooked := false
var _hurt_print := -10.0
var _lure: Unit = null
var _lure_point := Vector3.INF
var _lure_wagon: Node3D = null
var _squad_mode := &"foot"     ## foot / march / wait / strike / home
var _squad_road: Array = []
var _squad_i := 0
var _lure_last_pos := Vector3.INF
var _lure_last_t := 0.0
var _lure_road: Array = []
var _lure_route: Array = []
var _lure_back: Array = []
var _lure_to := Vector3.INF
var _lure_guards: Array = []
var _lure_alarms := 0
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID
	h.protect_hero = false
	h.timeout_frames = 75000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e3m2_sim_none.json"}}) as MissionE3_02
	h.steps.add("play", _play, 74000)
	var ev := root.get_node_or_null("Events")
	if ev:
		ev.unit_died.connect(_on_died)


func _on_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or int(unit.team) != Unit.Team.PLAYER or main == null:
		return
	var k: Variant = unit.killer
	var who := "?"
	if k != null and is_instance_valid(k):
		var kt: Variant = k.get(&"unit_type")
		who = String((kt as UnitType).id) if kt != null else String((k as Node).name)
		if k is Wizard:
			who = "wizard:%s" % (k as Wizard).unit_name
	var key := "%s:%s" % [phase, who]
	killers[key] = int(killers.get(key, 0)) + 1


func _process(_delta: float) -> bool:
	return h.tick()


static func _mmss(t: float) -> String:
	if t < 0.0:
		return "-"
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _set_phase(p: StringName) -> void:
	if phase != p:
		phase = p
		_phase_log.append("%s@%s" % [p, _mmss(main.mission_time())])


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"slip"] + (CUTSCENE_SECONDS[&"embers"] if m.phase == 2 else 0.0) \
				+ (CUTSCENE_SECONDS[&"dawn"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); night %s; wagons %d / 4; alarms %d; villagers hit %d" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), _mmss(_night_end), m.wagons_spoiled(),
				m.alarms, m.villagers_hit])
		print("  phases %s" % ", ".join(_phase_log))
		print("  objectives %s" % str(h.objective_log))
		print("  Shadow losses by killer: %s" % str(killers))
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, phase])
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.25
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 15.0) != _last_print:
		_last_print = int(m.mission_time() / 15.0)
		var vey := m.vey_vigil
		print("    t=%s %s/%s hero %s %3.0f/%3.0f at (%.0f, %.0f) veiled %s | wagons %d alarms %d | vey (%.0f, %.0f) | squad %d" % [
				_mmss(m.mission_time()), phase, _step, m.hero.unit_name, m.hero.hp, m.hero.max_hp, m.hero.global_position.x,
				m.hero.global_position.z, m.veiled, m.wagons_spoiled(), m.alarms,
				vey.global_position.x if vey and is_instance_valid(vey) else 0.0, vey.global_position.z if vey and is_instance_valid(vey) else 0.0,
				_squad().size()])
		if not killers.is_empty():
			print("      losses so far: %s" % str(killers))
		if _lure and is_instance_valid(_lure):
			print("      lure %s at (%.0f, %.0f) to (%.0f, %.0f) target %s alert %.0f" % [_lure.unit_type.id, _lure.global_position.x, _lure.global_position.z,
					_lure_point.x, _lure_point.z, _lure.attack_target, m.alert_left])
	if verbose and not _hurt_hooked and m.hush_hero:
		_hurt_hooked = true
		m.hush_hero.damage_taken.connect(func(a: float, by: Node3D) -> void:
			if m.mission_time() - _hurt_print > 2.0:
				_hurt_print = m.mission_time()
				var who := "?"
				if by and is_instance_valid(by):
					who = "%s(%.0f,%.0f)" % [(by as Unit).unit_type.id if by is Unit and (by as Unit).unit_type else by.name,
							by.global_position.x, by.global_position.z]
				print("      %s Hush hit %.0f by %s at (%.0f, %.0f) step %s veiled %s lit %s" % [_mmss(m.mission_time()), a, who,
						m.hush_hero.global_position.x, m.hush_hero.global_position.z, _step, m.hush_hero.is_veiled(), m.lit_at(m.hush_hero.global_position)])
				var near := []
				for n in m.get_tree().get_nodes_in_group(&"units"):
					var e := n as Unit
					if e and e.is_alive() and Teams.is_hostile(int(e.team), 0) and _flat(e.global_position, m.hush_hero.global_position) <= 7.0:
						near.append("%s%s(%.1f)" % [e.unit_type.id if e.unit_type else e.name, "[z]" if m.is_dormant(e) else "", _flat(e.global_position, m.hush_hero.global_position)])
				print("        concealed m=%s status=%s hidden=%s seen_within=%.1f near %s" % [m.is_concealed(m.hush_hero), m.hush_hero.is_concealed(), m.hush_hero.is_hidden_from_auto_target(), m.seen_within(m.hush_hero), near]))
	if verbose and m.alarms != _alarms_seen:
		_alarms_seen = m.alarms
		var near := _movers_near(m.alert_at, 12.0)
		var all := []
		for n in m.get_tree().get_nodes_in_group(&"units"):
			var e := n as Unit
			if e and e.is_alive() and Teams.is_hostile(int(e.team), 0) and not m.is_dormant(e) and _flat(e.global_position, m.alert_at) <= 10.0:
				all.append("%s(%.0f,%.0f)" % [e.unit_type.id if e.unit_type else e.name, e.global_position.x, e.global_position.z])
		print("      ALARM %d at (%.0f, %.0f) step %s wagon %d; enemies near: %s" % [m.alarms, m.alert_at.x, m.alert_at.z, _step, _wi, ", ".join(all)])
	if m.phase == 1:
		_night()
	else:
		if _night_end < 0.0:
			_night_end = m.mission_time()
		_dawn()
	return false


# ---------------------------------------------------------------- helpers

func _squad() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable() and not u is Helper and u != main.hush_hero:
			out.append(u)
	return out


func _flat(a: Vector3, b: Vector3) -> float:
	return MissionBase._flat(a, b)


## Awake enemies that move (patrols, alerts, hunters): no home spot.
func _movers_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), 0) and not main.is_dormant(u) and u != main.vey_vigil \
				and int(u.team) != Unit.Team.NEUTRAL and not u.has_meta(MissionBase.META_HOME) and _flat(u.global_position, at) <= r:
			out.append(u)
	return out


func _hush_go(at: Vector3, near := 0.8) -> bool:
	var hu := main.hush_hero
	if _flat(hu.global_position, at) <= near:
		if hu.has_move_order():
			hu.command_stop()
		return true
	if not hu.has_move_order() or _flat(_last_go, at) > 0.5:
		hu.command_move(at)
		_last_go = at
	return false


## Walking in the dark: a patrol (or any moving enemy) near her or on the next few metres of her way = she waits,
## or steps back from it when it comes within 5 m (veiled she is seen within 3 m only). True once at `to`.
func _sneak(to: Vector3, near := 2.0) -> bool:
	var hu := main.hush_hero
	var dir := to - hu.global_position
	dir.y = 0.0
	var ahead := hu.global_position + (dir.normalized() * minf(5.0, dir.length()) if dir.length() > 0.1 else Vector3.ZERO)
	var threat: Unit = null
	var movers := _movers_near(hu.global_position, 14.0)
	var vey := main.vey_vigil
	if vey and is_instance_valid(vey) and _flat(vey.global_position, hu.global_position) <= 14.0:
		movers.append(vey)   # Old Vey: 9 m in the light, 5 m concealed, 3 m veiled
	# Patience: 15 s without getting closer, she only gives a mover 5 m (a stuck patrol member held her 9 minutes).
	if _flat(hu.global_position, _sneak_pos) > 2.0 or _flat(_sneak_to, to) > 0.5:
		_sneak_pos = hu.global_position
		_sneak_to = to
		_sneak_since = main.mission_time()
	var bold := main.mission_time() - _sneak_since > 15.0
	for u in movers:
		var r := 5.0 if bold else 9.0   # a patrol is 4-5 units walking 2.5 m/s: give it room
		if u == vey:
			r = 9.5 if main.lit_at(ahead) or main.lit_at(hu.global_position) else 5.0
		if _flat(u.global_position, hu.global_position) <= r or _flat(u.global_position, ahead) <= r + 0.5:
			threat = u
			break
	if threat == null:
		return _hush_go(to, near)
	if _flat(threat.global_position, hu.global_position) < 7.0 or main.lit_at(hu.global_position):
		# Step 7 m to the dark side that is farthest from every mover.
		var best := Vector3.INF
		var best_d := -1.0
		for i in 8:
			var a := TAU * float(i) / 8.0
			var p := hu.global_position + Vector3(cos(a) * 7.0, 0.0, sin(a) * 7.0)
			if main.lit_at(p) or not MapInfo.contains(p, 0.8):
				continue
			var d := INF
			for u in _movers_near(p, 18.0):
				d = minf(d, _flat(u.global_position, p))
			for u in _enemies_near(p, 8.0):   # never step onto a post (veiled she is seen within 3 m)
				d = minf(d, _flat(u.global_position, p) * 0.8)
			if d > best_d:
				best_d = d
				best = p
		if best != Vector3.INF:
			hu.command_move(best)
			_last_go = best
			return false
	hu.command_stop()
	return false


func _next(step: StringName) -> void:
	_step = step
	_step_since = main.mission_time()
	if verbose:
		var hu := main.hush_hero
		print("      %s step %s (wagon %d) at (%.1f, %.1f) hp %.0f veiled %s smoke %.1f" % [_mmss(main.mission_time()), step, _wi,
				hu.global_position.x, hu.global_position.z, hu.hp, hu.is_veiled(), hu.smoke_left])


# ---------------------------------------------------------------- the night

func _night() -> void:
	var m := main
	var hu := m.hush_hero
	# The squad: in the dark at the foot, holding (never chases into the camp); the lure Hound is the exception.
	# (Loose, 3 m apart and never on Hold: a held ring boxed the lure Reaver in.)
	var sq := _squad()
	_tick_squad(sq)
	for i in sq.size():
		var u := sq[i]
		if u == _lure or _squad_mode != &"foot":
			continue
		var slot := SQUAD_WAIT + Vector3(float(i % 3) * 3.0 - 3.0, 0.0, float(i / 3) * 3.0 - 3.0)
		if _flat(u.global_position, slot) > 2.5 and not u.has_move_order() and u.attack_target == null:
			u.command_move(slot)
	_tick_lure()
	# Hurt, or a hunt / an alert on top of her: back to the foot (the safe line), then start the wagon over.
	# The last wagon ends the night the moment it is spoiled: no running from a hunt for it, only from real harm.
	var last := m.wagons_spoiled() == 3 and _step in [&"to_spot", &"spot_in", &"sabotage"]
	var hurt := hu.hp < hu.max_hp * (0.25 if last else 0.45) and not hu.smoke_covers(hu.global_position)
	var chased := _chasers()
	var hidden := hu.smoke_covers(hu.global_position) or _step in [&"spot_in", &"sabotage"] and hu.smoke_left > 0.0
	if not hidden and _step == &"to_spot" and not _chasers().is_empty() and hu.cooldown_left(&"hush_smoke") <= 0.0 \
			and _wi < PLAN.size() and _flat(hu.global_position, (m.wagons[PLAN[_wi][0]] as Node3D).global_position) <= 8.0:
		# Seen on her way in, close to the wagon: the smoke now, and the nearest side of the wagon (inside the smoke).
		hu.command_cast(&"hush_smoke", null)
		var wpos: Vector3 = (m.wagons[PLAN[_wi][0]] as Node3D).global_position
		_spot = wpos + (hu.global_position - wpos).normalized() * 3.3
		_cloak_at = _spot
		_next(&"spot_in")
		hidden = true
	if (hurt or not chased.is_empty() and _step != &"strike" and not hidden and not last) and _step != &"flee":
		_set_phase(&"flee")
		_next(&"flee")
		hu.command_cast(&"hush_smoke", null)   # the escape: whoever targets her drops her, nobody sees her for 5 s
		_flee_to = _refuge(chased)
	if _step == &"flee":
		var arrived := _hush_go(_flee_to, 1.5)
		if arrived and not chased.is_empty():
			_flee_to = _refuge(chased)
		if hu.hp >= hu.max_hp * 0.85 and chased.is_empty() and (arrived or m.alert_left <= 0.0):
			_set_phase(&"night")
			_via_i = 0
			# back to the foot first (the roads start there): a road picked up from the middle of the camp crossed the crest
			_next(&"go" if hu.global_position.z <= 22.0 else &"to_foot")
		return
	if _wi < PLAN.size() and m.spoiled.has(PLAN[_wi][0]) and _step in [&"sabotage", &"spot_in", &"to_spot", &"lured", &"strike", &"muster"]:
		_next(&"leave")   # out to the dark staging spot first, then home
		if _squad_mode != &"foot":
			_squad_mode = &"home"
			_squad_i = 0
	if _step == &"leave":
		if m.lit_at(hu.global_position):
			var d := _dark_near(hu.global_position)
			if d != Vector3.INF:
				_hush_go(d, 0.5)
				return
		if _sneak(PLAN[_wi][2], 1.5):
			_next(&"home")
		else:
			return
	while _wi < PLAN.size() and m.spoiled.has(PLAN[_wi][0]):
		_wi += 1
		_via_i = 0
		_next(&"home")
	if _wi >= PLAN.size():
		return
	var row: Array = PLAN[_wi]
	var wid: StringName = row[0]
	var wagon: Building = m.wagons[wid]
	var via: Array = row[1]
	var stage: Vector3 = row[2]
	var mode: StringName = row[3]
	var lure := mode == &"lure"
	match _step:
		&"home":
			# Back to the foot the way she came (the previous wagon's road), then the next road.
			# (A wagon with its own way home, WG2's west crest gap: the east one crosses the Fire patrol's loop twice.)
			var prev: Array = []
			if _wi > 0:
				var pr: Array = PLAN[_wi - 1]
				if pr.size() > 5 and not (pr[5] as Array).is_empty():
					prev = (pr[5] as Array).duplicate()
					prev.reverse()   # walked from the end: the list is written foot-ward, reverse it back
				else:
					prev = pr[1]
			if _via_i < prev.size():
				if _sneak(prev[prev.size() - 1 - _via_i], 2.0):
					_via_i += 1
			elif _sneak(FOOT, 4.0):
				_via_i = 0
				_next(&"go")
		&"to_foot":
			if _sneak(Vector3(clampf(hu.global_position.x, -60.0, 60.0), 0.0, 12.0), 3.0):
				_via_i = 0
				_next(&"go")
		&"stage", &"go":
			if _via_i < via.size():
				if _sneak(via[_via_i], 2.0):
					_via_i += 1
			elif _sneak(stage, 1.5):
				_next(&"wait")
		&"wait":
			# In the dark and veiled, the patrols away; a guarded wagon: no alert running (the lure needs a fresh one);
			# WG2: Old Vey at the far end of his vigil.
			var target := _sabotage_spot(wagon)
			# A minute of waiting: a human goes once the patrol is merely nearby (veiled in the dark: seen within 3 m).
			var patrol_r := PATROL_CLEAR if m.mission_time() - _step_since < 60.0 else 8.0
			var clear := hu.is_veiled() and (mode == &"assault" or _movers_near(wagon.global_position, patrol_r).is_empty()) \
					and m.mission_time() - _step_since >= SCOUT_TIME
			if mode != &"veil" and m.alert_left > 0.0:
				clear = false
			if verbose and m.mission_time() - _step_since > 20.0 and fmod(m.mission_time() - _step_since, 30.0) < 0.26:
				var ms := []
				for u in _movers_near(wagon.global_position, PATROL_CLEAR):
					ms.append("%s(%.0f,%.0f)%s d%.1f" % [u.unit_type.id, u.global_position.x, u.global_position.z,
							u.get_meta(MissionBase.META_MODE, &""), _flat(u.global_position, wagon.global_position)])
				print("      waiting at %s: clear %s veiled %s alert %.0f vey %.1f smoke %.0f fire %s movers %s" % [wid, clear,
						hu.is_veiled(), m.alert_left, _flat(m.vey_vigil.global_position, target) if m.vey_vigil else -1.0,
						hu.cooldown_left(&"hush_smoke"), m.fires[WG2_FIRE][1], ms])
			# WG2: F6 is snuffed first (smoke; Old Vey resting at the far end of his vigil, by the tree), so the sabotage
			# is done in the dark (veiled: he sees her within 3 m).
			var fire: Array = m.fires[WG2_FIRE] if wid == &"WG2" else []
			if wid == &"WG2":
				if m.vey_vigil == null or hu.cooldown_left(&"hush_smoke") > 0.0:
					clear = false
				elif not fire.is_empty() and fire[1]:
					target = fire[0] + (stage - (fire[0] as Vector3)).normalized() * 1.0   # straight in from the stage side
					if _flat(m.vey_vigil.global_position, MissionE3_02.VEY_PATH[0]) > 1.5:
						clear = false
				elif _flat(m.vey_vigil.global_position, target) < VEY_CLEAR:
					clear = false
			if clear:
				_spot = target
				_cloak_at = target + (stage - target).normalized() * 3.0
				if not fire.is_empty() and fire[1]:
					_fire_i = WG2_FIRE
					_after_snuff = &"back"
					_next(&"to_fire")
				elif mode == &"assault":
					_squad_road = via + [stage]
					_squad_i = 0
					_squad_mode = &"march"
					_next(&"muster")
				elif lure:
					_lure_guards = _guards_of(wagon)
					_lure_alarms = m.alarms
					_start_lure(wagon, row[4], via + [stage])
					_next(&"lured")
				else:
					_next(&"to_spot")
		&"lured":
			# The Hound has been seen far from the wagon: the camp alert pulls the guards to it.
			var south := wagon.global_position - (row[4] as Vector3).normalized() * 3.3   # Hush's side
			var gone := m.alarms > _lure_alarms and m.alert_left < MissionE3_02.ALERT_TIME - 6.0 and _lure_guards.all(func(g: Variant) -> bool: return not is_instance_valid(g) \
					or not (g as Unit).is_alive() or _flat((g as Unit).global_position, south) > 10.0)
			if (gone or (m.alarms > _lure_alarms and m.mission_time() - _step_since > 25.0)) and row.size() > 6 and int(row[6]) >= 0 \
					and (m.fires[int(row[6])] as Array)[1] and hu.cooldown_left(&"hush_smoke") <= 0.0:
				# The guards are at the alarm: F5 first, under smoke, then the wagon in the dark (veiled: 3 m).
				_fire_i = int(row[6])
				var fpos: Vector3 = (m.fires[_fire_i] as Array)[0]
				_spot = fpos + (stage - fpos).normalized() * 1.0
				_cloak_at = fpos + (stage - fpos).normalized() * 3.5
				_after_snuff = &"to_spot"
				_next(&"to_fire")
			elif gone or (m.alarms > _lure_alarms and m.mission_time() - _step_since > 25.0):
				_spot = _sabotage_spot(wagon)
				_cloak_at = _spot + (stage - _spot).normalized() * 3.0   # walk in under the smoke (it lasts the 2 s channel)
				_next(&"to_spot")
			elif m.mission_time() - _step_since > 75.0 or (_lure == null and m.alarms == _lure_alarms and m.mission_time() - _step_since > 3.0):
				_next(&"wait")   # the lure failed (or died unseen): try again
		&"muster":
			# The squad walks Hush's dark road to her staging spot; she waits for it (a minute at most).
			var c := SimTactics.centroid(_squad())
			if c == Vector3.INF or (_flat(c, stage) <= 7.0 and _squad_mode == &"wait") or m.mission_time() - _step_since > 75.0:
				_squad_mode = &"strike"
				_next(&"strike")
		&"strike":
			_strike(wagon, stage)
		&"to_fire":
			if _hush_go(_cloak_at, 0.8):
				hu.command_cast(&"hush_smoke", null)
				_next(&"fire_in")
		&"fire_in":
			var f: Array = m.fires[_fire_i]
			if _hush_go(_spot, 0.4) or _flat(hu.global_position, f[0]) <= 1.8:
				hu.command_stop()
				_next(&"snuff")
			elif m.mission_time() - _step_since > 5.0:
				_next(&"back")
		&"snuff":
			hu.command_stop()
			if not (m.fires[_fire_i] as Array)[1] or m.mission_time() - _step_since > 5.0:
				if _after_snuff == &"to_spot":
					_spot = _sabotage_spot(wagon)
					_cloak_at = _spot + (stage - _spot).normalized() * 3.0
				_next(_after_snuff)
		&"back":
			if _sneak(stage, 1.5):
				_next(&"wait")
		&"to_spot":
			if wid == &"WG2" and m.vey_vigil and _flat(m.vey_vigil.global_position, _spot) < VEY_CLEAR - 3.0:
				_next(&"back")
			elif m.mission_time() - _step_since > 10.0:
				_next(&"spot_in")   # held up on the way: straight to the wagon
			elif _hush_go(_cloak_at, 0.8):
				if m.lit_at(_spot) or wid == &"WG2":
					hu.command_cast(&"hush_smoke", null)
				_next(&"spot_in")
		&"spot_in":
			if _hush_go(_spot, 0.5) or _flat(hu.global_position, wagon.global_position) <= MissionE3_02.SABOTAGE_REACH - 0.2:
				hu.command_stop()
				_next(&"sabotage")
			elif m.mission_time() - _step_since > 6.0:
				_next(&"back")
		&"sabotage":
			if not hu.is_holding():
				hu.command_hold()   # a channel: never walk off after a target once the veil is broken
			if m.spoiled.has(wid):
				_next(&"back")
			elif m.mission_time() - _step_since > 8.0:
				_next(&"back")


## The squad as a group (assault wagons, mission-e3-02.md "the guard fight"): march along Hush's dark road in a loose
## file, wait at her staging spot, strike the guards with her, then walk the road back to the foot.
func _tick_squad(sq: Array[Unit]) -> void:
	match _squad_mode:
		&"march", &"home":
			var road: Array = _squad_road.duplicate()
			if _squad_mode == &"home":
				road.reverse()
				road.append(SQUAD_WAIT)
			if road.is_empty():
				_squad_mode = &"foot"
				return
			var c := SimTactics.centroid(sq)
			if c == Vector3.INF:
				return
			while _squad_i < road.size() - 1 and _flat(c, road[_squad_i]) <= 5.0:
				_squad_i += 1
			var to: Vector3 = road[_squad_i]
			if _squad_i == road.size() - 1 and _flat(c, to) <= 5.0:
				_squad_mode = &"wait" if _squad_mode == &"march" else &"foot"
				return
			for i in sq.size():
				var u := sq[i]
				var slot := to + Vector3(float(i % 3) * 2.5 - 2.5, 0.0, float(i / 3) * 2.5 - 2.5)
				if u.attack_target == null and (not u.has_move_order() or _flat(u.global_position, slot) > 12.0):
					u.command_move(slot)
		&"wait":
			for u in sq:
				if not u.has_move_order() and u.attack_target == null:
					u.command_stop()


## The guard fight (the last wagon): the squad on the nearest guard each while Hush waits in the dark; 4 s in (or with
## the guards down) she spoils the wagon from the far side under Smoke Cloak while the squad keeps whoever comes busy.
func _strike(wagon: Building, stage: Vector3) -> void:
	var m := main
	var hu := m.hush_hero
	var guards: Array[Unit] = []
	for u in _enemies_near(wagon.global_position, 9.0):
		if u != m.vey_vigil:
			guards.append(u)
	# The squad holds the guards: after 4 s of fighting she spoils the wagon under Smoke Cloak (it ends the night if it is
	# the last one), else once the guards are down.
	var engaged := m.mission_time() - _step_since > 4.0 and hu.cooldown_left(&"hush_smoke") <= 0.0
	if guards.is_empty() or engaged or m.mission_time() - _step_since > 25.0 and guards.size() <= 1:
		_spot = _sabotage_spot(wagon)
		_cloak_at = _spot + (stage - _spot).normalized() * 3.0
		_next(&"to_spot")
		return
	for u in _squad():
		if u.attack_target == null or not is_instance_valid(u.attack_target):
			var best: Unit = guards[0]
			for g in guards:
				if _flat(g.global_position, u.global_position) < _flat(best.global_position, u.global_position):
					best = g
			u.command_attack(best)
	# Hush stays veiled in the dark at her staging spot while the squad draws the guards (a Blink into the pack left her
	# surrounded with the channel reset by every hit); she goes in under the smoke once they are busy.
	hu.command_stop()


## The nearest dark point (rings of 3-15 m, 16 directions), away from Old Vey and the movers.
func _dark_near(from: Vector3) -> Vector3:
	for r: float in [3.0, 5.0, 7.0, 9.0, 12.0, 15.0]:
		var best := Vector3.INF
		var best_d := -1.0
		for i in 16:
			var a := TAU * float(i) / 16.0
			var p := from + Vector3(cos(a) * r, 0.0, sin(a) * r)
			if main.lit_at(p) or not MapInfo.contains(p, 0.8):
				continue
			var d := _flat(p, main.vey_vigil.global_position) if main.vey_vigil else 50.0
			for u in _movers_near(p, 12.0):
				d = minf(d, _flat(u.global_position, p))
			if d > best_d:
				best_d = d
				best = p
		if best != Vector3.INF:
			return best
	return Vector3.INF


## Enemies after her: targeting her, or a mover within 7 m while an alert / a hunt runs.
func _chasers() -> Array[Unit]:
	var out: Array[Unit] = []
	var hu := main.hush_hero
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or not Teams.is_hostile(int(u.team), 0) or main.is_dormant(u) or u == main.vey_vigil:
			continue
		if u.attack_target == hu or (main.alert_left > 0.0 or main.vessa_awake) and not u.has_meta(MissionBase.META_HOME) \
				and _flat(u.global_position, hu.global_position) <= (3.5 if hu.is_veiled() else 7.0):
			out.append(u)
	return out


## A dark point 14 m away from the chasers, leaning north (the safe line), never on the squad.
func _refuge(chasers: Array[Unit]) -> Vector3:
	var hu := main.hush_hero
	# South of the crest the only real refuge is the safe line (z <= 22: hunters and camp units turn back there):
	# straight north to the foot, sideways only if a chaser stands in the way.
	if hu.global_position.z > 22.0:
		var north := Vector3(clampf(hu.global_position.x, -60.0, 60.0), 0.0, 12.0)
		var blocked := false
		for e in chasers:
			if (e.global_position - hu.global_position).normalized().dot((north - hu.global_position).normalized()) > 0.7 \
					and _flat(e.global_position, hu.global_position) < 8.0:
				blocked = true
		if not blocked:
			return north
	var c := SimTactics.centroid(chasers)
	var away := Vector3(0.0, 0.0, -1.0)
	if c != Vector3.INF:
		away += (hu.global_position - c).normalized()
	away.y = 0.0
	var foes: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var e := n as Unit
		if e and e.is_alive() and Teams.is_hostile(int(e.team), 0) and not main.is_dormant(e) and int(e.team) != Unit.Team.NEUTRAL \
				and _flat(e.global_position, hu.global_position) <= 30.0:
			foes.append(e)
	var best := FOOT
	var best_s := -INF
	for i in 16:
		var a := TAU * float(i) / 16.0
		var p := hu.global_position + Vector3(cos(a) * 14.0, 0.0, sin(a) * 14.0)
		if not MapInfo.contains(p, 2.0):
			continue
		var room := 30.0
		for e in foes:
			room = minf(room, _flat(e.global_position, p))
		# Away from every awake enemy around (not only the chasers), leaning north, dark, never onto the squad.
		var s := room * 0.15 + (p - hu.global_position).normalized().dot(away.normalized()) \
				- (2.0 if main.lit_at(p) else 0.0) - (0.5 if _flat(p, SQUAD_WAIT) < 8.0 else 0.0)
		if s > best_s:
			best_s = s
			best = p
	return best


## The lure (mission-e3-02.md "Hounds": "a Hound seen deliberately is the cheapest alarm, used to pull an alert away"):
## the toughest squad unit walks Hush's dark road, shows itself to the wagon's guards 7 m from the wagon (PLAN's lure side),
## stands the 3 s fuse, then runs back to the foot; the camp alert keeps the guards on that spot for 45 s while Hush,
## waiting on the other side, spoils the wagon.
func _start_lure(wagon: Node3D, offset: Vector3, road: Array) -> void:
	_lure_point = wagon.global_position + offset
	_lure_wagon = wagon
	_lure_road = road.duplicate()   # Hush's dark road, then the lure spot: a lure seen on the way pulls the wrong alert
	_lure_route = road.duplicate()
	_lure_back.clear()
	_lure_road.append(_lure_point)
	# A Nightblood Reaver (480 HP, drinks its damage back) stands the fuse where a 70-HP Hound died first; then a
	# Hound, then anyone.
	_lure = null
	for u in _squad():   # the toughest unit left (a Nightblood Reaver while one is healthy)
		if _lure == null or u.hp > _lure.hp:
			_lure = u
	if _lure:
		_lure.command_move(_lure_road[0])


func _tick_lure() -> void:
	if _lure == null or not is_instance_valid(_lure) or not _lure.is_alive():
		_lure = null
		return
	if main.alarms > _lure_alarms or _step != &"lured":
		# Home the way it came (the dark road reversed), not straight through the camp.
		if _lure_back.is_empty():
			_lure_back = _lure_route.duplicate()
			_lure_back.reverse()
			_lure_back.append(SQUAD_WAIT)
		while _lure_back.size() > 1 and _flat(_lure.global_position, _lure_back[0]) <= 3.0:
			_lure_back.pop_front()
		if _flat(_lure.global_position, SQUAD_WAIT) > 4.0:
			if not _lure.has_move_order() or _flat(_lure_to, _lure_back[0]) > 0.5:
				_lure.command_move(_lure_back[0])
				_lure_to = _lure_back[0]
		else:
			_lure = null
			_lure_back.clear()
		return
	while _lure_road.size() > 1 and _flat(_lure.global_position, _lure_road[0]) <= 2.5:
		_lure_road.pop_front()
	var to: Vector3 = _lure_road[0] if not _lure_road.is_empty() else _lure_point
	if _flat(_lure.global_position, _lure_point) > 1.5 and _lure.attack_target == null:
		# Stuck (boxed in, no progress for 4 s): order it again.
		if _flat(_lure.global_position, _lure_last_pos) > 1.0:
			_lure_last_pos = _lure.global_position
			_lure_last_t = main.mission_time()
		if not _lure.has_move_order() or main.mission_time() - _lure_last_t > 4.0 or _flat(to, _lure_to) > 0.5:
			_lure.command_stop()
			_lure.command_move(to)
			_lure_to = to
			_lure_last_t = main.mission_time()
	elif _lure.attack_target == null:
		_lure.command_hold()   # in the guards' sight (concealed 6 m): it stands the 3 s fuse, fighting what comes


## The wagon's guards: awake posted enemies within 7 m of it.
func _guards_of(wagon: Node3D) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), 0) and not main.is_dormant(u) and u.has_meta(MissionBase.META_HOME) \
				and _flat(u.global_position, wagon.global_position) <= 7.0:
			out.append(u)
	return out


## The point of `ring` (radius r around `center`, 24 directions) farthest from the wagon's guards (and the wagon).
func _far_point(center: Vector3, r: float, wagon: Node3D, avoid_wagon: bool) -> Vector3:
	var avoid: Array[Vector3] = []
	for g in _guards_of(wagon):
		avoid.append(g.global_position)
	if _flat(MissionE3_02.VEY_PATH[0], wagon.global_position) <= 15.0:
		avoid.append_array(MissionE3_02.VEY_PATH)   # WG2: away from both ends of Old Vey's vigil
	var best := center
	var best_d := -1.0
	for i in 24:
		var a := TAU * float(i) / 24.0
		var p := center + Vector3(cos(a) * r, 0.0, sin(a) * r)
		var d := INF
		for g in avoid:
			d = minf(d, _flat(g, p))
		if avoid_wagon:
			d = minf(d, _flat(wagon.global_position, p) - 1.0)
		if d > best_d:
			best_d = d
			best = p
	return best


func _fire_spot(fire_at: Vector3, wagon: Node3D) -> Vector3:
	return _far_point(fire_at, 1.4, wagon, true)


func _sabotage_spot(wagon: Node3D) -> Vector3:
	return _far_point(wagon.global_position, 3.0, wagon, false)


# ---------------------------------------------------------------- dawn

func _dawn() -> void:
	var m := main
	_set_phase(&"dawn")
	var roster := HelperRoster.for_team(0)
	if roster:
		if roster.state() == &"fallen" and roster.can_revive() == "":
			roster.revive()
		elif roster.can_call() == "":
			roster.call_helper()
	var k := m.keep
	var eco := Economy.for_team(0)
	if k and k.is_alive() and _reavers < 2 and k.queue.size() < 2 and eco.crystals >= 260:
		if k.queue_unit(UnitType.find("nightblood_reaver")) == "":
			_reavers += 1
			k.set_rally_point(KEEP_LINE)
	var army: Array = SimTactics.pull_back_wounded(_squad(), KEEP_LINE + Vector3(0.0, 0.0, -8.0), _wounded, 0.25)
	var vs := m.vessa
	var foes := _enemies_near(KEEP_LINE, 18.0)
	if SimTactics.focus_wizards(army, [vs], 14.0, func(w: Unit) -> bool: return not m.is_dormant(w)) == null:
		if foes.is_empty():
			SimTactics.spread_to(army, KEEP_LINE, Vector3(0.0, 0.0, 1.0), 3.5)
		else:
			for u: Unit in army:
				if u.attack_target == null and not u.is_attack_moving():
					u.command_attack_move(foes[0].global_position)
	var hero := m.hero
	var back := KEEP_LINE + Vector3(0.0, 0.0, -5.0)
	if hero.hp < hero.max_hp * 0.4:
		back = MissionE3_02.DUSK_KEEP + Vector3(4.0, 0.0, 6.0)
	if _flat(hero.global_position, back) > 3.0 and not hero.has_move_order():
		hero.command_move(back)
	var near := _enemies_near(hero.global_position, 11.0)
	if not near.is_empty() and hero.mana > 45.0:
		var best: Unit = near[0]
		for u in near:
			if u is Wizard:
				best = u
				break
		hero.command_cast(&"shadow_lance", best)
	var w := hero as Wizard
	for id: StringName in [&"shadow_lance", &"soul_siphon", &"umbral_shroud"]:
		if w.spell_points <= 0:
			break
		w.learn_spell(id)


func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), 0) and int(u.team) != Unit.Team.NEUTRAL \
				and not main.is_dormant(u) and not u.has_meta(Unit.TRUCE_META) and _flat(u.global_position, at) <= r:
			out.append(u)
	return out
