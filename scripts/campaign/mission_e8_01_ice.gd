class_name MissionE8_01Ice
extends MissionE8_01
## e8m1_ice "The Gate Opens" (docs/design/mission-e8-01.md C): Torvald opens the Hundredwinter Gate (the lever, 3 s) to
## a column of 40 refugees and escorts them south past the Hearth Camp while the Stone-sworn hunt them. Kettlewick's
## militia joins when e6m2 opened its gate. Defeat when fewer than 20 can still arrive. Spotlight: the Frost Mortar.
##
## Built deviations (2026-10-09): the Wall of a Hundred Winters is drawn (ice blocks along z = -18) but not a navigation
## obstacle: the gate rule is the column's (it stops at a closed gate, the hunters behind it are real). The route winds
## through the player's side to the exit at the south-east; story floor: the column leaves the Northway at 5:30 (spec
## 3:30) and rests 9:30 at the Hearth Camp (spec 4:00), sheltered there (at peace: the hunters fight the army) so the scripted run lands in the 18-22 min target.

const GATE := Vector3(0.0, 0.0, -18.0)
const LEVER := Vector3(0.0, 0.0, -12.0)
const LEVER_R := 4.0
const LEVER_TIME := 3.0
const LEVER_LOCK := 10.0
const NORTHWAY := Vector3(0.0, 0.0, -56.0)
const KETTLEWICK := Vector3(0.0, 0.0, -40.0)
const CAMP := Vector3(-14.0, 0.0, 14.0)
const CRACK := Vector3(22.0, 0.0, 18.0)   ## the Southway Crack, off the road (its Wardens hold it)
const STAIR := Vector3(30.0, 0.0, 46.0)
const EXIT := Vector3(40.0, 0.0, 50.0)
const EXIT_R := 6.0
const RIDER_POS := Vector3(0.0, 0.0, -22.0)
const HUNT_N := Vector3(0.0, 0.0, -54.0)
const HUNT_W := Vector3(-56.0, 0.0, -30.0)
const HUNT_E := Vector3(56.0, 0.0, -30.0)
const ROUTE: Array[Vector3] = [Vector3(0.0, 0.0, -40.0), Vector3(0.0, 0.0, -24.0), Vector3(0.0, 0.0, -6.0),
		Vector3(-14.0, 0.0, 14.0), Vector3(6.0, 0.0, 26.0), Vector3(24.0, 0.0, 36.0), Vector3(30.0, 0.0, 46.0),
		Vector3(40.0, 0.0, 50.0)]
const WP_KETTLE := 0
const WP_GATE := 1
const WP_CAMP := 3
const WP_STAIR := 6
const COLUMN_AT := 330.0
const COLUMN_N := 40
const NEEDED: Array[int] = [16, 20, 24]
const CAMP_REST: Array[float] = [480.0, 570.0, 600.0]
const KETTLE_REST := 30.0
const REFUGEE_HP: Array[float] = [100.0, 80.0, 60.0]   ## spec 80 / 60 / 50: the carts shield them a little (tuning)
const STOP_R := 14.0
const LAST_WAIT := 180.0
const HINT_START := "Open the gate: Torvald at the lever for 3 s. The column arrives at 5:30, hunters close behind."
const MSG_DYING := "They're dying at the gate."
const MSG_OPEN := "The Hundredwinter Gate opens"
const MSG_SHUT := "The Hundredwinter Gate closes"

## Read only.
var gate_open := false
var gate_opened_at := -1.0
var lever_progress := 0.0
var lever_lock_until := 0.0
var refugees: Array = []
var spawned := 0
var saved := 0
var lost := 0
var col_wp := 0
var rest_until := 0.0
var camp_left := false
var dying_t := 0.0
var camp_shelter := false
var column_stopped := false            ## Read only (tests)
var enough_at := -1.0
var aldra_npc: Unit
var rider: Unit
var gate_look: Node3D


func _road() -> StringName:
	return &"ice"


func _road_title() -> String:
	return "The Gate Opens"


func _road_army() -> Array:
	return [["rimeshield", 6], ["shardcaster", 4], ["frostbow", 2], ["rime_seer", 1], ["frost_mortar", 1], ["rimecarver", 1]]


func _map_seed() -> int:
	return 1813


func _clearings() -> Array:
	var out: Array = [[GATE, 6.0], [LEVER, 4.0], [KETTLEWICK, 10.0], [NORTHWAY, 5.0], [CAMP, 8.0], [CRACK, 6.0],
			[EXIT, 7.0], [HUNT_W, 5.0], [HUNT_E, 5.0]]
	for p: Vector3 in ROUTE:
		out.append([p, 5.0])
	return out


func _lanes() -> Array:
	var out: Array = [[NORTHWAY, KETTLEWICK, 5.0], [HUNT_W, Vector3(-52.0, 0.0, -18.0), 4.0], [HUNT_E, Vector3(52.0, 0.0, -18.0), 4.0]]
	var prev := KETTLEWICK
	for p: Vector3 in ROUTE:
		out.append([prev, p, 5.0])
		prev = p
	return out


func _init() -> void:
	super()
	define_objectives([[&"obj_gate", "primary"], [&"obj_column", "primary"], [&"obj_torvald", "primary"],
			[&"obj_keep", "primary"], [&"sec_early", "secondary"], [&"sec_thirty", "secondary"], [&"sec_shut", "secondary"]])
	local_unit("rime_hauler", "refugee", "Refugee", {"is_worker": false, "max_hp": 60.0, "armor": 0.0, "attack_damage": 0.0,
			"aggro_range": 0.0, "move_speed": 1.4, "pop": 0, "kill_xp": 15, "cost": 20, "commandable": false})
	local_unit("rime_seer", "aldra_story", "Aldra", {"attack_damage": 0.0, "aggro_range": 0.0, "pop": 0, "kill_xp": 0,
			"commandable": false})
	local_unit("blaze_rider", "gate_rider", "Rider", {"attack_damage": 0.0, "aggro_range": 0.0, "pop": 0, "kill_xp": 0,
			"commandable": false, "faction": &"ice"})
	local_unit("rimeshield", "kettlewick_militia", "Kettlewick Militia", {"pop": 0})


func _mission_config() -> MissionConfig:
	var c := super()
	c.keep_lost_message = "The Rime Keep has fallen."
	c.spotlight = {"id": &"frost_mortar", "trigger": &"manual", "key_hint": "Frost Hall",
			"card": "Frost Mortar. Far and heavy: when they bunch up, one shell freezes the lot."}
	return c


func _ready() -> void:
	super()
	tint_light(Color(0.95, 0.97, 1.0), 1.1, -28.0, Color(0.70, 0.74, 0.82), Color(0.48, 0.62, 0.86), Color(0.86, 0.90, 0.98))


func _variant_map() -> void:
	for i in 12:   # the Wall of a Hundred Winters (drawn), the gate gap at x 0
		var x := -54.0 + i * 9.8
		if absf(x) < 6.0:
			continue
		box_prop(Vector3(x, 0.0, GATE.z), Vector3(9.0, 4.5, 3.0), Color(0.78, 0.86, 0.95))
	gate_look = box_prop(GATE, Vector3(7.5, 4.0, 1.2), Color(0.55, 0.70, 0.88))
	ground_disc(LEVER, LEVER_R, Color(0.70, 0.90, 1.0, 0.30), 0.05)
	ground_disc(CAMP, 7.0, Color(1.0, 0.75, 0.45, 0.25), 0.05)
	ground_disc(EXIT, EXIT_R, Color(1.0, 0.95, 0.75, 0.30), 0.05)
	for i in 6:   # Kettlewick
		var a := TAU * i / 6.0
		box_prop(KETTLEWICK + Vector3(cos(a) * 9.0, 0.0, sin(a) * 9.0), Vector3(3.0, 2.4, 3.0),
				Color(0.55, 0.45, 0.38) if flag_on("e6m2_gate_opened") else Color(0.20, 0.18, 0.18), a)


func _variant_start() -> void:
	aldra_npc = story_npc("aldra_story", START + Vector3(2.0, 0.0, -2.0))
	rider = story_npc("gate_rider", RIDER_POS, Unit.Team.NEUTRAL)
	for p: Vector3 in [GATE, KETTLEWICK, CAMP, EXIT]:
		fog.reveal(Unit.Team.PLAYER, p, 8.0)


func _initial_objectives() -> Array:
	return [&"obj_gate", &"obj_torvald", &"obj_keep", &"sec_early", &"sec_thirty"]


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e8m1_ice_gate", _gate_end)


func _gate_end() -> void:
	for id in ["L1", "L2", "L3", "L4"]:
		say_l(id)
	if aldra_npc and is_instance_valid(aldra_npc):
		aldra_npc.queue_free()
	aldra_npc = null
	if hud:
		hud.show_message(HINT_START, 10.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


func needed() -> int:
	return int(by_difficulty(NEEDED))


func alive_refugees() -> Array:
	return refugees.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())


# ---------------------------------------------------------------- objectives

func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_gate":
			return "Open the Hundredwinter Gate"
		&"obj_column":
			if with_counter:
				return Loc.t("Bring the column south ({saved} / {needed}, lost {lost})", {"saved": saved, "needed": needed(), "lost": lost})
			return "Bring the column south"
		&"obj_torvald":
			return "Torvald must survive"
		&"obj_keep":
			return "The Rime Keep must stand"
		&"sec_early":
			return "The gate opens: open it before the column reaches it"
		&"sec_thirty":
			return "Bring 30 of the 40 south"
		&"sec_shut":
			return "Close the gate behind them"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_gate", &"sec_shut":
			return {"positions": [LEVER]}
		&"obj_column":
			return {"counter": saved, "goal": needed(), "positions": [EXIT]}
		&"sec_thirty":
			return {"counter": saved, "goal": 30}
	return {}


# ---------------------------------------------------------------- the gate and the lever

func _tick_lever(dt: float) -> void:
	if mission_time() < lever_lock_until or (hero_alive() and hero.has_move_order()):
		lever_progress = 0.0   # Torvald must stand at the lever (walking past it does nothing)
		return
	lever_progress = channel_step(lever_progress, LEVER, LEVER_R, LEVER_TIME, dt)
	if lever_progress >= LEVER_TIME:
		lever_progress = 0.0
		lever_lock_until = mission_time() + LEVER_LOCK
		set_gate(not gate_open)


func set_gate(open: bool) -> void:
	gate_open = open
	if gate_look:
		gate_look.visible = not open
	flash_ring(GATE, 5.0)
	if hud:
		hud.show_message(MSG_OPEN if open else MSG_SHUT, 3.0)
	if open and fire_once(&"E2"):
		gate_opened_at = mission_time()
		set_objective(&"obj_gate", "done")
		say_l("L5")
		if rider and is_instance_valid(rider):
			rider.team = Unit.Team.PLAYER
			rider.command_move(CAMP)
		var head := _head()
		if head == null or _flat(head.global_position, GATE) > 10.0:
			set_objective(&"sec_early", "done")
		else:
			set_objective(&"sec_early", "failed")
	if not open and objective_state("sec_shut") == "active" and _all_south():
		set_objective(&"sec_shut", "done")


func _all_south() -> bool:
	for v: Variant in alive_refugees():
		if (v as Unit).global_position.z < GATE.z + 1.0:
			return false
	return spawned >= COLUMN_N


# ---------------------------------------------------------------- the column (C.4)

## The column's head: the living refugee nearest the next waypoint (a straggler never holds the column).
func _head() -> Unit:
	var wp: Vector3 = ROUTE[mini(col_wp, ROUTE.size() - 1)]
	var best: Unit = null
	var bd := INF
	for v: Variant in alive_refugees():
		var d := _flat((v as Unit).global_position, wp)
		if d < bd:
			bd = d
			best = v as Unit
	return best


func _spawn_column() -> void:
	fire_once(&"E3")
	say_l("L6")
	set_objective(&"obj_column", "active")
	local_type("refugee").max_hp = float(by_difficulty(REFUGEE_HP))
	for i in COLUMN_N:
		var r := make_unit("refugee")
		_spawn(r, Unit.Team.PLAYER, Vector3((i % 8) * 1.3 - 4.5, 0.0, -44.0 - (i / 8) * 1.4))   # inside the map edge
		mark_scripted(r)
		r.set_meta(&"slot", i)
		r.died.connect(_on_refugee_died)
		refugees.append(r)
	spawned = COLUMN_N
	after(75.0, _wave_h0)


## H0: the pursuers come down the Northway 75 s behind the column (they reach it near the gate).
func _wave_h0() -> void:
	waves_fired.append("H0")
	host_wave([["shade", 4], ["grave_hound", 2]], Vector3(0.0, 0.0, -58.0), [], KETTLEWICK)


## An enemy within 14 m of the head that stands ahead of it (nearer the next waypoint): the column stops. Pursuers
## behind it never stop it (they catch the tail instead).
func _foe_ahead(head: Unit) -> bool:
	var wp: Vector3 = ROUTE[mini(col_wp, ROUTE.size() - 1)]
	var hd := _flat(head.global_position, wp)
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == host_team and not is_dormant(u) \
				and _flat(u.global_position, head.global_position) <= STOP_R and _flat(u.global_position, wp) < hd:
			return true
	return false


func _on_refugee_died(_u: Unit) -> void:
	lost += 1
	_check_doom()


func _check_doom() -> void:
	if is_ending() or spawned < COLUMN_N:
		return
	if saved + alive_refugees().size() < needed() and fire_once(&"E15"):
		say_l("L21")
		set_objective(&"obj_column", "failed")
		lose(DEFEAT_DELAY)


func _tick_column(dt: float) -> void:
	if spawned < COLUMN_N:
		return
	var head := _head()
	if head == null:
		return
	var t := mission_time()
	var stop := t < rest_until or _foe_ahead(head)
	if col_wp <= WP_GATE and not gate_open and head.global_position.z >= ROUTE[WP_GATE].z - 3.0:
		stop = true
		if fire_once(&"E5"):
			say_l("L9")
		dying_t -= dt
		if dying_t <= 0.0:
			dying_t = 10.0
			if hud:
				hud.show_message(MSG_DYING, 3.0)
	column_stopped = stop
	if camp_shelter and t >= rest_until:
		camp_shelter = false
		set_truce(alive_refugees(), false, Unit.TRUCE_ALL)
	var wp: Vector3 = ROUTE[mini(col_wp, ROUTE.size() - 1)]
	for v: Variant in alive_refugees():
		var r := v as Unit
		if r.global_position.y < -5.0:   # off the ground (never expected): counted lost
			refugees.erase(r)
			lost += 1
			r.queue_free()
			continue
		var slot := int(r.get_meta(&"slot", 0))
		if _flat(r.global_position, EXIT) <= (12.0 if col_wp >= ROUTE.size() - 1 else EXIT_R) and col_wp >= WP_STAIR:
			saved += 1
			refugees.erase(r)
			r.leave_map()
			continue
		if stop:
			if r.has_move_order():
				r.command_stop()
			continue
		var off := Vector3((slot % 4) * 1.2 - 1.8, 0.0, (slot / 4) * 1.1)
		var to := wp + off if col_wp < ROUTE.size() - 1 else EXIT   # the last leg: straight into the exit
		if not r.has_move_order() or _flat(r.get_meta(&"to", Vector3.INF), to) > 3.0:
			r.command_move(to)
			r.set_meta(&"to", to)
	if not stop and col_wp < ROUTE.size() and _flat(head.global_position, wp) < 4.0:
		_reach(col_wp)
		col_wp += 1
	if saved >= needed() and fire_once(&"E12"):
		say_l("L16")
	if saved >= 30 and objective_state("sec_thirty") == "active":
		set_objective(&"sec_thirty", "done")
	if spawned >= COLUMN_N and _all_south() and fire_once(&"E6"):
		say_l("L10")
		set_objective(&"sec_shut", "active")
		if not gate_open:
			set_objective(&"sec_shut", "done")
	if saved >= needed() and enough_at < 0.0:
		enough_at = t
	if spawned >= COLUMN_N and saved >= needed() and (alive_refugees().is_empty() or t >= enough_at + LAST_WAIT):
		lost += alive_refugees().size()   # spec C.5: 3:00 after the 20th, the rest count as lost
		_done()
	_check_doom()


func _reach(wp: int) -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	match wp:
		WP_KETTLE:
			rest_until = mission_time() + KETTLE_REST
			if flag_on("e6m2_gate_opened"):
				fire_once(&"E4")
				say_l("L7")
				say_l("L8")
				spawn_army([["kettlewick_militia", 8]], KETTLEWICK + Vector3(4.0, 0.0, 4.0))
			else:
				fire_once(&"E4")
				say_l("L9b")
		WP_GATE:
			if gate_opened_at >= 0.0 and fire_once(&"H1"):
				waves_fired.append("H1")
				host_wave([["shade", 4], ["nightbolt", 2]], HUNT_N, [GATE], CAMP)
		WP_CAMP:
			rest_until = mission_time() + float(CAMP_REST[diff])
			camp_shelter = true
			set_truce(alive_refugees(), true, Unit.TRUCE_ALL)   # the braziers and blankets hide them while they rest
			fire_once(&"E7")
			say_l("L11")
			waves_fired.append("H2")
			host_wave([["shade", 4], ["nightbolt", 2], ["hexweaver", 1]], HUNT_W, [Vector3(-52.0, 0.0, -14.0)], CAMP)
			after(90.0, _wave_h3)
			after(180.0, _wave_h4)
		WP_CAMP + 1:
			fire_once(&"E9")
			say_l("L13")
			waves_fired.append("W5")
			host_guards([["warden", 8], ["sentinel", 1]], CRACK, 5.0)
		WP_STAIR:
			fire_once(&"E11")
			say_l("L15")
			waves_fired.append("H6")
			host_wave([["shade", 4], ["nightbolt", 2], ["shadow_knight", 1], ["barrow_ghoul", 2]], HUNT_W, [], STAIR)
			host_wave([["shade", 4], ["nightbolt", 1], ["shadow_knight", 1], ["barrow_ghoul", 2]], Vector3(56.0, 0.0, 30.0), [], STAIR)


func _wave_h3() -> void:
	waves_fired.append("H3")
	host_wave([["grave_hound", 3], ["shade", 3], ["shadow_knight", 1]], HUNT_E, [Vector3(52.0, 0.0, -14.0)], CAMP)


func _wave_h4() -> void:
	waves_fired.append("H4")
	var shut := objective_state("sec_shut") == "done"
	var rows: Array = [["shade", 4 if shut else 6], ["nightbolt", 2], ["gloom_deacon", 1]]
	if gate_open and not shut:
		host_wave(rows, HUNT_N, [GATE], CAMP)
	else:
		host_wave(rows, HUNT_W, [Vector3(-52.0, 0.0, -14.0)], CAMP)


## Hunters go for the nearest refugee.
func _refresh_e7_mode(_u: Unit, _mode: StringName, _hero_at: Vector3) -> bool:
	return false


func _refresh_wave_unit(u: Unit, mode: StringName, hero_at: Vector3) -> bool:
	if String(u.unit_type.id).begins_with("sworn_") and u.attack_target == null and _player_near(u.global_position, 6.0) == null:
		var best: Unit = null
		var bd := 18.0
		for v: Variant in alive_refugees():
			var d := _flat((v as Unit).global_position, u.global_position)
			if d < bd:
				bd = d
				best = v as Unit
		if best:
			u.command_attack(best)
			return true
	return super(u, mode, hero_at)


func _tick_crack() -> void:
	if has_fired(&"E9") and host_near(CRACK, 12.0).is_empty() and fire_once(&"E10"):
		say_l("L14")


func _on_helper_arrived() -> void:
	fire_once(&"E8")
	say_l("L12")


# ---------------------------------------------------------------- the end

func _done() -> void:
	if not fire_once(&"E13"):
		return
	set_objective(&"obj_column", "done")
	set_objective(&"obj_torvald", "done")
	set_objective(&"obj_keep", "done")
	if objective_state("sec_thirty") == "active":
		set_objective(&"sec_thirty", "failed")
	if objective_state("sec_shut") == "active":
		set_objective(&"sec_shut", "done" if not gate_open else "failed")
	set_mission_flag("e8m1_ice_saved", saved)
	finish_road()
	play_cutscene(&"e8m1_ice_south", _south_end)


func _south_end() -> void:
	for id in ["L17", "L18", "L19"]:
		say_l(id)
	win(1.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E14")
	say_l("L20")
	super()


func _variant_tick(dt: float) -> void:
	if mission_time() >= COLUMN_AT and spawned == 0:
		_spawn_column()
	_tick_lever(dt)
	_tick_column(dt)
	_tick_crack()


func save_block_reason() -> String:
	if has_fired(&"E13"):
		return SAVE_REASON_SCRIPTED
	return super()
