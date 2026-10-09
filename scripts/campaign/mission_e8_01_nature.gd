class_name MissionE8_01Nature
extends MissionE8_01
## e8m1_nature "Take a Side" (docs/design/mission-e8-01.md D): Ysolde unweaves the three knots of her own root walls,
## answers the burning hamlets' messengers, and crosses the Thistlewater before the Host's gates close the bridges.
## The Heartwood regrows once. Spotlight: the Greenheart Oathkeeper.
##
## Built deviations (2026-10-09): the root walls (x = -24 / -4 / 12) and the Thistlewater (x = 22) are drawn, not
## navigation obstacles: the rules read the knots (unwoven in order) and the bridge gates (Warden Gates on x = 22 that
## rise on the clock and spawn 3 Wardens / 45 s). Story floor: the Crown Hollow road (the exit) opens at 18:00 ("the
## Signet wakes") and the second / third knots loosen at 5:30 / 11:00 (the older walls hold longer), so the scripted run lands in the 18-22 min target.

const KNOTS: Array[Vector3] = [Vector3(-24.0, 0.0, 14.0), Vector3(-4.0, 0.0, 6.0), Vector3(12.0, 0.0, -2.0)]
const WALL_X: Array[float] = [-24.0, -4.0, 12.0]
const KNOT_R := 4.0
const KNOT_CLEAR := 8.0
const UNWEAVE: Array[float] = [4.0, 5.0, 6.0]
const KNOT_AT: Array[float] = [0.0, 330.0, 660.0]   ## story floor: the older the wall, the longer its knot holds
const HAMLETS := [["Pipwell", Vector3(-14.0, 0.0, -30.0), Vector3(-14.0, 0.0, -56.0), [["shade", 4], ["grave_hound", 2]]],
		["Fernby", Vector3(4.0, 0.0, 36.0), Vector3(4.0, 0.0, 56.0), [["warden", 3], ["shade", 3], ["nightbolt", 1]]],
		["Hollins Cross", Vector3(18.0, 0.0, -34.0), Vector3(20.0, 0.0, -56.0), [["warden", 4], ["sentinel", 1]]]]
const HAMLET_R := 8.0
const BURN: Array[float] = [150.0, 120.0, 100.0]
const RIVER_X := 22.0
const BRIDGES := {&"north": Vector3(24.0, 0.0, -30.0), &"road": Vector3(24.0, 0.0, -2.0), &"south": Vector3(24.0, 0.0, 30.0)}
const BRIDGE_AT := {&"north": [780.0, 660.0, 600.0], &"south": [1020.0, 900.0, 780.0], &"road": [1260.0, 1140.0, 960.0]}
const BRIDGE_NAMES := {&"north": "North Bridge", &"road": "Road Bridge", &"south": "South Bridge"}
const HOST_E: Array[Vector3] = [Vector3(56.0, 0.0, -30.0), Vector3(56.0, 0.0, 30.0)]
const TIDES := [[360.0, "T1", [["warden", 6]]], [600.0, "T2", [["warden", 6], ["sentinel", 1]]],
		[840.0, "T3", [["warden", 8], ["shade", 2], ["nightbolt", 2]]], [1020.0, "T4", [["warden", 8], ["sentinel", 2]]]]
const BRIDGEHEAD := Vector3(36.0, 0.0, -4.0)
const EXIT := Vector3(54.0, 0.0, -4.0)
const EXIT_R := 8.0
const EXIT_FLOOR := 1080.0
const EXIT_ARMY_POP := 12
const REGROW := 90.0
const WREN_POS := Vector3(-34.0, 0.0, 30.0)
const HINT_START := "Unweave the knot on the road: Ysolde within 4 m for 5 s. Your old ward spires still guard it."
const MSG_GATE_SOON := "The Host is raising a gate on the {bridge} (1:00)."
const MSG_GATE_UP := "The {bridge} is closed: break its gate."
const MSG_REGROW := "The Heartwood will grow back."
const MSG_ROAD_SHUT := "The road to Crown Hollow opens at 18:00: the Signet is still waking"
const MSG_ARMY := "Bring your army: 12 population within 15 m of Ysolde"
const MSG_KNOT_SPIRES := "Your old ward spires still guard this knot"
const MSG_KNOT_TIGHT := "This knot is older and still holds fast: it loosens at {time}"

## Read only.
var knots_open := 0
var knot_progress := 0.0
var spires: Array = []                 ## [Array of 2 per knot]
var hamlet_state: Array[String] = ["", "", ""]   ## "" / "raid" / "saved" / "burned"
var hamlet_until: Array[float] = [0.0, 0.0, 0.0]
var hamlet_raiders: Array = [[], [], []]
var hamlets_saved := 0
var bridge_gates := {}
var crossed_at := -1.0
var heartwood_falls := 0
var regrow_at := -1.0
var wren: Unit

var _spire_type: BuildingType


func _road() -> StringName:
	return &"nature"


func _road_title() -> String:
	return "Take a Side"


func _road_army() -> Array:
	return [["thornling", 8], ["wildwood_archer", 4], ["bloomtender", 2], ["bramblehorn", 1], ["vinelasher", 2], ["bramblesage", 1]]


func _map_seed() -> int:
	return 1814


func _clearings() -> Array:
	var out: Array = [[BRIDGEHEAD, 7.0], [EXIT, 8.0], [WREN_POS, 3.0]]
	for p: Vector3 in KNOTS:
		out.append([p, 10.0])
	for h: Array in HAMLETS:
		out.append([h[1], 9.0])
	for id: StringName in BRIDGES:
		out.append([BRIDGES[id], 6.0])
	return out


func _lanes() -> Array:
	return [[KEEP_POS, KNOTS[0], 5.0], [KNOTS[0], KNOTS[1], 5.0], [KNOTS[1], KNOTS[2], 5.0], [KNOTS[2], BRIDGES[&"road"], 5.0],
			[BRIDGES[&"road"], EXIT, 5.0], [KNOTS[0], HAMLETS[0][1], 4.0], [KNOTS[1], HAMLETS[1][1], 4.0], [KNOTS[2], HAMLETS[2][1], 4.0]]


func _init() -> void:
	super()
	define_objectives([[&"obj_walls", "primary"], [&"obj_cross", "primary"], [&"obj_ysolde", "primary"],
			[&"sec_hamlets", "secondary"], [&"sec_bridge", "secondary"]])
	local_unit("wildwood_archer", "wren_story", "Wren", {"max_hp": 260.0, "commandable": false, "pop": 0, "kill_xp": 0,
			"move_speed": 5.2})
	local_unit("wildwood_archer", "militia_archer", "Hamlet Archer", {"pop": 0})
	local_unit("thornling", "militia_thornling", "Hamlet Militia", {"pop": 0})
	_spire_type = MissionE5Base.local_building("nature_tower", "briar_ward_spire", "Briar Ward Spire", 540.0)


func _mission_config() -> MissionConfig:
	var c := super()
	c.defeat_on_keep_lost = false   # the Heartwood regrows once (D.4)
	c.keep_lost_message = "The Heartwood has fallen."
	c.spotlight = {"id": &"greenheart_oathkeeper", "trigger": &"manual", "key_hint": "Grove Hall",
			"card": "Greenheart Oathkeeper. A sworn blade: it calls the divers to itself and doesn't let them pass."}
	return c


func _ready() -> void:
	super()
	tint_light(Color(1.0, 0.96, 0.85), 1.1, -32.0, Color(0.66, 0.72, 0.60), Color(0.46, 0.62, 0.82), Color(0.90, 0.92, 0.78))


func _variant_map() -> void:
	for x: float in WALL_X:   # the root walls (drawn)
		for i in 14:
			var z := -56.0 + i * 8.6
			if absf(z - KNOTS[WALL_X.find(x)].z) < 5.0:
				continue
			box_prop(Vector3(x, 0.0, z), Vector3(2.0, 3.5, 8.0), Color(0.26, 0.34, 0.18))
	for i in 14:   # the Thistlewater (drawn)
		ground_disc(Vector3(RIVER_X, 0.0, -56.0 + i * 8.6), 4.0, Color(0.30, 0.48, 0.62, 0.55), 0.04)
	for k: Vector3 in KNOTS:
		ground_disc(k, KNOT_R, Color(0.55, 0.85, 0.35, 0.35), 0.05)
		box_prop(k, Vector3(2.5, 2.5, 2.5), Color(0.32, 0.22, 0.12), 0.6)
	for h: Array in HAMLETS:
		for j in 3:
			box_prop(h[1] + Vector3(j * 3.5 - 3.5, 0.0, (j % 2) * 3.0), Vector3(2.6, 2.2, 2.6), Color(0.62, 0.52, 0.40), j)
	for i in KNOTS.size():
		var pair: Array = []
		for s: float in [7.0, -7.0]:
			var b := build_grid.spawn_complete(_spire_type, KNOTS[i] + Vector3(6.0, 0.0, s), Unit.Team.NEUTRAL) if _spire_type else null
			if b:
				pair.append(b)
		spires.append(pair)


func _variant_start() -> void:
	wren = make_unit("wren_story")
	_spawn(wren, Unit.Team.PLAYER, WREN_POS)
	mark_scripted(wren)
	wren.set_meta(META_HOME, WREN_POS)
	_guards.append(wren)
	kneel_guard(wren, 8.0)
	for p: Vector3 in KNOTS:
		fog.reveal(Unit.Team.PLAYER, p, 9.0)


func _initial_objectives() -> Array:
	return [&"obj_walls", &"obj_ysolde", &"sec_hamlets", &"sec_bridge"]


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e8m1_nature_road", _road_end)


func _road_end() -> void:
	for id in ["L1", "L2", "L3", "L4"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 10.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


# ---------------------------------------------------------------- objectives

func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_walls":
			if with_counter:
				return Loc.t("Unweave your own walls ({n} / 3)", {"n": knots_open})
			return "Unweave your own walls"
		&"obj_cross":
			return "Cross the Thistlewater and take the road to Crown Hollow"
		&"obj_ysolde":
			return "Ysolde must survive"
		&"sec_hamlets":
			if with_counter:
				return Loc.t("Answer the messengers ({n} / 3)", {"n": hamlets_saved})
			return "Answer the messengers"
		&"sec_bridge":
			return "Cross before the last bridge closes"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_walls":
			return {"counter": knots_open, "goal": 3, "positions": [KNOTS[mini(knots_open, 2)]]}
		&"obj_cross":
			return {"positions": [EXIT]}
		&"sec_hamlets":
			var pos: Array = []
			for i in 3:
				if hamlet_state[i] == "raid":
					pos.append(HAMLETS[i][1])
			return {"counter": hamlets_saved, "goal": 3, "positions": pos}
	return {}


# ---------------------------------------------------------------- knots (D.4)

func _spires_alive(i: int) -> bool:
	for b: Variant in spires[i]:
		if is_instance_valid(b) and (b as Building).is_alive():
			return true
	return false


func _tick_knots(dt: float) -> void:
	if knots_open >= 3:
		return
	var k: Vector3 = KNOTS[knots_open]
	if hero_alive() and _flat(hero.global_position, k) <= KNOT_R and mission_time() < KNOT_AT[knots_open]:
		if fire_once(StringName("tight_%d" % knots_open)) and hud:
			hud.show_message(Loc.t(MSG_KNOT_TIGHT, {"time": mmss(KNOT_AT[knots_open])}), 4.0)
		knot_progress = 0.0
		return
	if hero_alive() and _flat(hero.global_position, k) <= KNOT_R and _spires_alive(knots_open):
		if fire_once(StringName("spires_%d" % knots_open)) and hud:
			hud.show_message(MSG_KNOT_SPIRES, 3.0)
		knot_progress = 0.0
		return
	var before := knot_progress
	knot_progress = channel_step(before, k, KNOT_R, float(by_difficulty(UNWEAVE)), dt)
	if knot_progress >= float(by_difficulty(UNWEAVE)):
		knot_progress = 0.0
		_unweave()


func _unweave() -> void:
	var i := knots_open
	knots_open += 1
	flash_ring(KNOTS[i], 6.0)
	set_objective(&"obj_walls", "active")
	var hall := _hall()
	if hall:
		hall.set_rally_point(KNOTS[i] + Vector3(-4.0, 0.0, 0.0))
	match i:
		0:
			fire_once(&"E2")
			say_l("L5")
			say_l("L6")
		1:
			fire_once(&"E6")
			say_l("L9")
		2:
			fire_once(&"E9")
			say_l("L12")
			say_l("L13")
			set_objective(&"obj_walls", "done")
			set_objective(&"obj_cross", "active")
	hamlet_state[i] = "wait"
	hamlet_until[i] = mission_time() + 20.0
	if wren and is_instance_valid(wren):
		wren.set_meta(META_HOME, HAMLETS[i][1] + Vector3(-4.0, 0.0, 0.0))


func _hall() -> TrainingBuilding:
	for b in Building.for_team(Unit.Team.PLAYER):
		var t := b as TrainingBuilding
		if t and t.is_alive() and t.building_type and t.building_type.id == &"nature_barracks":
			return t
	return null


# ---------------------------------------------------------------- hamlets

func _tick_hamlets() -> void:
	var burn := float(by_difficulty(BURN))
	for i in 3:
		match hamlet_state[i]:
			"wait":
				if mission_time() >= hamlet_until[i]:
					hamlet_state[i] = "raid"
					hamlet_until[i] = mission_time() + burn
					waves_fired.append("Raid%d" % i)
					hamlet_raiders[i] = host_wave(HAMLETS[i][3], HAMLETS[i][2], [], HAMLETS[i][1])
					for v: Variant in hamlet_raiders[i]:
						(v as Unit).set_meta(META_HOME, HAMLETS[i][1])
			"raid":
				var alive := (hamlet_raiders[i] as Array).filter(func(u: Variant) -> bool:
						return is_instance_valid(u) and (u as Unit).is_alive())
				hamlet_raiders[i] = alive
				if alive.is_empty():
					_hamlet_saved(i)
				elif mission_time() >= hamlet_until[i]:
					hamlet_state[i] = "burned"
					if i == 0:
						fire_once(&"E4")
						say_l("L8")
					if objective_state("sec_hamlets") == "active":
						set_objective(&"sec_hamlets", "failed")


func _hamlet_saved(i: int) -> void:
	hamlet_state[i] = "saved"
	hamlets_saved += 1
	spawn_army([["militia_archer", 2], ["militia_thornling", 2]], HAMLETS[i][1])
	flash_ring(HAMLETS[i][1], 5.0)
	match i:
		0:
			fire_once(&"E4")
			say_l("L7")
		1:
			fire_once(&"E7")
			say_l("L10")
		2:
			fire_once(&"E10")
			say_l("L14")
	set_objective(&"sec_hamlets", "active")
	if hamlets_saved >= 3:
		set_objective(&"sec_hamlets", "done")


# ---------------------------------------------------------------- the bridges and the Host

func _tick_bridges() -> void:
	var t := mission_time()
	for id: StringName in BRIDGES:
		var at := float(by_difficulty(BRIDGE_AT[id]))
		if t >= at - 60.0 and fire_once(StringName("E5_%s" % id)) and hud:
			hud.show_message(Loc.t(MSG_GATE_SOON, {"bridge": Loc.t(BRIDGE_NAMES[id])}), 5.0)
		if t >= at and not bridge_gates.has(id):
			var g := add_warden_gate(id, BRIDGES[id], hero_pos(), 1800.0, 45.0, _bridge_spawn)
			bridge_gates[id] = g
			if hud:
				hud.show_message(Loc.t(MSG_GATE_UP, {"bridge": Loc.t(BRIDGE_NAMES[id])}), 5.0)
	for row: Array in TIDES:
		if t >= float(row[0]) and fire_once(StringName(row[1])):
			waves_fired.append(String(row[1]))
			var goal := _tide_goal()
			for p: Vector3 in HOST_E:
				host_guards(_half(row[2]), goal + Vector3(0.0, 0.0, 4.0 if p.z > 0.0 else -4.0), 3.0)
	if hero_alive() and absf(hero.global_position.x - RIVER_X) < 20.0 and fire_once(&"E11"):
		say_l("L15")
		waves_fired.append("Bridgehead")
		host_guards([["warden", 6], ["sentinel", 2]], BRIDGEHEAD, 4.0)
	if hero_alive() and hero.global_position.x > RIVER_X + 1.0 and crossed_at < 0.0:
		crossed_at = t
		fire_once(&"E12")
		say_l("L16")
		var road_at := float(by_difficulty(BRIDGE_AT[&"road"]))
		set_objective(&"sec_bridge", "done" if t < road_at else "failed")
	if crossed_at < 0.0 and t >= float(by_difficulty(BRIDGE_AT[&"road"])) and objective_state("sec_bridge") == "active":
		set_objective(&"sec_bridge", "failed")


static func _half(rows: Array) -> Array:
	var out: Array = []
	for r: Array in rows:
		out.append([r[0], maxi(1, int(r[1]) / 2)])
	return out


## The waiting spot of a tide: the east side of the first closed knot, else the bridgehead.
func _tide_goal() -> Vector3:
	if knots_open < 3:
		return KNOTS[knots_open] + Vector3(8.0, 0.0, 0.0)
	return BRIDGEHEAD


func _bridge_spawn(g: WardenGate) -> void:
	host_wave([["warden", 3]], g.front_point(), [], hero_pos())


# ---------------------------------------------------------------- the Heartwood, the exit

func _tick_heartwood() -> void:
	if regrow_at > 0.0 and mission_time() >= regrow_at:
		regrow_at = -1.0
		keep = build_grid.spawn_complete(BuildingType.find("nature_keep"), KEEP_POS, Unit.Team.PLAYER) as Keep
		if keep:
			keep.set_start_tier(2)
			keep.hp = keep.max_hp * 0.3
			seat_keeps[Unit.Team.PLAYER] = keep
		return
	if regrow_at < 0.0 and (keep == null or not is_instance_valid(keep) or not keep.is_alive()):
		heartwood_falls += 1
		if heartwood_falls == 1:
			fire_once(&"E14")
			say_l("L20")
			regrow_at = mission_time() + REGROW
			if hud:
				hud.show_message(MSG_REGROW, 5.0)
		elif fire_once(&"E15b"):
			lose(DEFEAT_DELAY)


func _army_pop_near(at: Vector3, r: float) -> int:
	var n := 0
	for u: Unit in units_of(Unit.Team.PLAYER, true):
		if u != hero and _flat(u.global_position, at) <= r and u.unit_type:
			n += int(u.unit_type.pop)
	return n


func _tick_exit() -> void:
	if objective_state("obj_cross") != "active" or not hero_alive() or _flat(hero.global_position, EXIT) > EXIT_R:
		return
	if mission_time() < EXIT_FLOOR:
		if fire_once(&"msg_road_shut") and hud:
			hud.show_message(MSG_ROAD_SHUT, 5.0)
		return
	var near := _army_pop_near(hero.global_position, 15.0)
	var total := _army_pop_near(hero.global_position, 1000.0)
	if near < mini(EXIT_ARMY_POP, total):
		if fire_once(&"msg_army") and hud:
			hud.show_message(MSG_ARMY, 4.0)
		return
	if not fire_once(&"E13"):
		return
	set_objective(&"obj_cross", "done")
	set_objective(&"obj_ysolde", "done")
	if objective_state("sec_hamlets") == "active":
		set_objective(&"sec_hamlets", "failed")
	set_mission_flag("e8m1_nature_saved", hamlets_saved)
	finish_road()
	play_cutscene(&"e8m1_nature_out", _out_end)


func _out_end() -> void:
	for id in ["L17", "L18", "L19"]:
		say_l(id)
	win(1.0)


func _on_helper_arrived() -> void:
	fire_once(&"E8")
	say_l("L11")


func _on_player_hero_fell() -> void:
	fire_once(&"E15")
	say_l("L21")
	super()


func _variant_tick(dt: float) -> void:
	_tick_knots(dt)
	_tick_hamlets()
	_tick_bridges()
	_tick_heartwood()
	_tick_exit()
	tick_kneelers([wren])


func save_block_reason() -> String:
	if has_fired(&"E13"):
		return SAVE_REASON_SCRIPTED
	return super()
