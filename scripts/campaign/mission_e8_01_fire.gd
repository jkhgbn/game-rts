class_name MissionE8_01Fire
extends MissionE8_01
## e8m1_fire "The Spark Waits" (docs/design/mission-e8-01.md A): Vessa holds the west bank while the three other keys
## are still on the road. Crossing the line feeds the Hollow Hunger (a Surge at 100 %); waiting fills Old Vey's
## Gathering Storm. Ashby's scouts must come home by themselves. Spotlight: the Pyre Adept.
##
## Built deviations (2026-10-09): no river on the generator map: "the west bank" is the half-plane z - x > 10 (the line
## the six Storm Stakes mark, drawn on the diagonal toward the isle); the Throne Crack sits beyond it at (6, -6), WG-N at
## (20, -34), WG-S at (40, 8), the Dusk Keep ruin at (44, -44), the wagon road at (30, -8). Story floor: the hold is
## 17:30 on normal (spec 14:00; with the cutscenes the scripted run lands in the 18-22 min target).

const LINE := 10.0
const CRACK := Vector3(6.0, 0.0, -6.0)
const WG_N := Vector3(20.0, 0.0, -34.0)
const WG_S := Vector3(40.0, 0.0, 8.0)
const RUIN := Vector3(44.0, 0.0, -44.0)
const WAGON := Vector3(30.0, 0.0, -8.0)
const FORD := Vector3(4.0, 0.0, 22.0)          ## the scouts' way home (Willow Ford)
const PIT_EDGE := Vector3(-6.0, 0.0, 6.0)
const ASHBY_POS := Vector3(-24.0, 0.0, 38.0)
const STAKES: Array[Vector3] = [Vector3(-52.0, 0.0, -38.0), Vector3(-35.0, 0.0, -21.0), Vector3(-17.0, 0.0, -3.0),
		Vector3(1.0, 0.0, 15.0), Vector3(19.0, 0.0, 33.0), Vector3(37.0, 0.0, 51.0)]
const HOLD: Array[float] = [900.0, 1050.0, 1140.0]
const HUNGER_MULT: Array[float] = [0.75, 1.0, 1.25]
const STORM_FILL: Array[float] = [100.0, 120.0, 150.0]
const SURGE_LEN := 60.0
const STORM_REACH := 25.0
## [T + seconds, id, [[spawn, rows], ...]]; spawn: crack / wgn / wgs / ruin.
const WAVES := [
	[60.0, "H1", [["wgs", [["warden", 6]]]]],
	[150.0, "H2", [["crack", [["warden", 6], ["ruin_slinger", 2]]]]],
	[240.0, "H3", [["wgn", [["warden", 6], ["sentinel", 1]]]]],
	[330.0, "H4", [["crack", [["warden", 6]]], ["wgs", [["warden", 4], ["sentinel", 1]]]]],
	[420.0, "H5", [["wgn", [["warden", 4]]], ["ruin", [["shade", 4], ["nightbolt", 2], ["gloom_deacon", 1]]]]],
	[540.0, "H6", [["crack", [["warden", 4], ["sentinel", 1]]], ["wgn", [["warden", 4], ["sentinel", 1]]], ["wgs", [["warden", 3], ["ruin_slinger", 1]]]]],
	[660.0, "H7", [["crack", [["warden", 8]]], ["wgn", [["sentinel", 2]]], ["ruin", [["shade", 4], ["nightbolt", 2], ["shadow_knight", 1]]]]],
	[750.0, "H8", [["crack", [["warden", 4], ["ruin_slinger", 1], ["sentinel", 1]]], ["wgn", [["warden", 5], ["sentinel", 1]]], ["wgs", [["warden", 4], ["sentinel", 1]]]]],
	[840.0, "H9", [["crack", [["warden", 4], ["sentinel", 1]]], ["wgn", [["warden", 4], ["sentinel", 1]]], ["wgs", [["warden", 3], ["ruin_slinger", 1]]]]],
]

const MSG_WARM := "The water is warm under your feet."
const MSG_FLICKER := "The stakes are flickering."
const MSG_SURGE := "The Hollow surges! The stakes go dark."
const MSG_STORM := "Vey's storm strikes!"
const HINT_START := "The Hollow can't feed on the west bank. Hold the line at the water: crossing feeds it."

## Read only.
var hold_start := -1.0
var hold_left := 0.0
var hunger := 0.0
var hunger_peak := 0.0
var storm := 0.0
var surge_until := 0.0
var storm_strikes := 0
var scouts_home := 0
var gates_broken: Array[String] = []
var vey: Unit
var ashby: Unit
var scouts: Array = []
var wgs := {}


func _road() -> StringName:
	return &"fire"


func _road_title() -> String:
	return "The Spark Waits"


func _road_army() -> Array:
	var diff := clampi(mission_difficulty, 0, 2)
	return [["flame_guard", 8 + (2 if diff == 0 else 0)], ["ember_archer", 4], ["blaze_rider", 2], ["pyre_adept", 2],
			["ash_hurler", 0 if diff == 2 else 2], ["kilnwarden", 1]]


func _workers() -> int:
	return 6


func _map_seed() -> int:
	return 1811


func _clearings() -> Array:
	var out: Array = [[CRACK, 8.0], [WG_N, 6.0], [WG_S, 6.0], [RUIN, 6.0], [WAGON, 5.0], [FORD, 5.0], [ASHBY_POS, 4.0]]
	for p: Vector3 in STAKES:
		out.append([p, 3.0])
	return out


func _lanes() -> Array:
	return [[CRACK, KEEP_POS, 5.0], [WG_N, KEEP_POS, 4.0], [WG_S, KEEP_POS, 4.0], [WAGON, FORD, 4.0], [RUIN, CRACK, 4.0]]


func _init() -> void:
	super()
	define_objectives([[&"obj_line", "primary"], [&"obj_vessa", "primary"], [&"obj_keep", "primary"],
			[&"sec_waited", "secondary"], [&"sec_scouts", "secondary"], [&"sec_storm", "secondary"]])
	local_unit("flame_guard", "ashby_story", "Captain Ashby", {"max_hp": 600.0, "commandable": false, "pop": 0, "kill_xp": 0})
	local_unit("blaze_rider", "ashby_scout", "Ashby's Scout", {"commandable": false, "pop": 0, "move_speed": 6.0})
	local_unit("rime_seer", "vey_npc", "Old Vey", {"attack_damage": 0.0, "aggro_range": 0.0, "pop": 0, "kill_xp": 0,
			"commandable": false})


func _mission_config() -> MissionConfig:
	var c := super()
	c.keep_lost_message = "The Fire keep has fallen."
	c.spotlight = {"id": &"pyre_adept", "trigger": &"manual", "key_hint": "Ember Hall",
			"card": "Pyre Adept. A battle mage for crowds: let them bunch up in the water, then burn the bunch."}
	return c


func _ready() -> void:
	super()
	tint_light(Color(0.95, 0.88, 0.80), 1.0, -24.0, Color(0.62, 0.60, 0.62), Color(0.42, 0.46, 0.56), Color(0.92, 0.80, 0.66))
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)


func _variant_map() -> void:
	ground_disc(CRACK, 4.0, Color(1.0, 0.70, 0.25, 0.45), 0.05)
	for p: Vector3 in STAKES:
		box_prop(p, Vector3(0.3, 2.5, 0.3), Color(0.15, 0.13, 0.12))
		ground_disc(p, 1.2, Color(1.0, 0.95, 0.70, 0.35), 0.05)
	box_prop(RUIN, Vector3(5.0, 1.2, 4.0), Color(0.30, 0.26, 0.34), 0.4)
	box_prop(WAGON, Vector3(2.4, 1.2, 1.4), Color(0.45, 0.32, 0.20), 0.8)
	for id: String in ["wgn", "wgs"]:
		var g := add_warden_gate(StringName(id), WG_N if id == "wgn" else WG_S, KEEP_POS, 1800.0, 0.0, Callable())
		g.gate_down.connect(_on_gate_down)
		wgs[id] = g


func _variant_start() -> void:
	vey = story_npc("vey_npc", START + Vector3(2.0, 0.0, -2.0))
	ashby = make_unit("ashby_story")
	_spawn(ashby, Unit.Team.PLAYER, ASHBY_POS)
	mark_scripted(ashby)
	ashby.set_meta(META_HOME, ASHBY_POS)
	_guards.append(ashby)
	kneel_guard(ashby, 8.0)
	for p: Vector3 in [CRACK, WG_N, WG_S, WAGON]:
		fog.reveal(Unit.Team.PLAYER, p, 8.0)


func _initial_objectives() -> Array:
	return [&"obj_line", &"obj_vessa", &"obj_keep", &"sec_waited"]


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e8m1_fire_stakes", _stakes_end)


## e8m1_fire_stakes end state: the stakes stand, Vey walks into the crack and is gone, the hold starts (E2).
func _stakes_end() -> void:
	for id in ["L1", "L2", "L3", "L4", "L5"]:
		say_l(id)
	if vey and is_instance_valid(vey):
		vey.queue_free()
	vey = null
	if hud:
		hud.show_message(HINT_START, 10.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)
	if fire_once(&"E2"):
		hold_start = mission_time()
		hold_left = float(by_difficulty(HOLD))
		for p: Vector3 in STAKES:
			flash_ring(p, 3.0)


# ---------------------------------------------------------------- objectives

func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_line":
			if with_counter and hold_start >= 0.0:
				if surge_until > mission_time():
					return Loc.t("Hold the west bank until the keys arrive ({time}) (paused)", {"time": mmss(hold_left)})
				return Loc.t("Hold the west bank until the keys arrive ({time})", {"time": mmss(hold_left)})
			return "Hold the west bank until the keys arrive"
		&"obj_vessa":
			return "Vessa must survive"
		&"obj_keep":
			return "The Fire keep must stand"
		&"sec_waited":
			if with_counter:
				return Loc.t("The spark waits: keep the Hollow under 50 % (now {pct} %, storm {storm} %)",
						{"pct": int(hunger), "storm": int(storm * 100.0)})
			return "The spark waits: keep the Hollow under 50 %"
		&"sec_scouts":
			if with_counter:
				return Loc.t("Bring Ashby's scouts home ({n} / 4)", {"n": scouts_home})
			return "Bring Ashby's scouts home"
		&"sec_storm":
			return "Raise a Citadel and call Old Vey"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_line":
			return {"countdown": hold_left if hold_start >= 0.0 else -1.0}
		&"sec_scouts":
			return {"counter": scouts_home, "goal": 4}
	return {}


# ---------------------------------------------------------------- the line, the Hunger, the storm (A.4)

static func west_bank(p: Vector3) -> bool:
	return p.z - p.x > LINE


func _beyond_pop() -> float:
	var pop := 0.0
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Unit.Team.PLAYER or u == hero or is_dormant(u):
			continue
		if not west_bank(u.global_position):
			pop += maxf(1.0, float(u.unit_type.pop) if u.unit_type else 1.0)
	return pop


func _tick_hunger(dt: float) -> void:
	if hold_start < 0.0:
		return
	var mult := float(by_difficulty(HUNGER_MULT))
	var rate := _beyond_pop() * 0.04
	if hero_alive() and not west_bank(hero.global_position):
		rate += 0.4
		if fire_once(&"E4"):
			say_l("L10")
	_add_hunger(rate * mult * dt)


func _add_hunger(n: float) -> void:
	if n <= 0.0 or is_ending():
		return
	var before := hunger
	hunger = minf(100.0, hunger + n)
	hunger_peak = maxf(hunger_peak, hunger)
	if before < 25.0 and hunger >= 25.0 and hud:
		hud.show_message(MSG_WARM, 4.0)
	if before < 50.0 and hunger >= 50.0 and fire_once(&"E7"):
		say_l("L11")
		set_objective(&"sec_waited", "failed")
	if before < 75.0 and hunger >= 75.0 and hud:
		hud.show_message(MSG_FLICKER, 4.0)
	if hunger >= 100.0:
		_surge()


func _on_any_unit_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or is_ending() or hold_start < 0.0 or int(unit.team) != Unit.Team.PLAYER:
		return
	if not west_bank(unit.global_position):
		_add_hunger(2.0 * float(by_difficulty(HUNGER_MULT)))
	elif surge_until > mission_time():
		_add_hunger(1.0)


## The Surge (meter at 100 %): the stakes go dark 60 s, the hold pauses, an Overrun at all three spawns on Vessa.
func _surge() -> void:
	fire_once(&"E14")
	say_l("L19")
	hunger = 40.0
	surge_until = mission_time() + SURGE_LEN
	if hud:
		hud.show_message(MSG_SURGE, 5.0)
	waves_fired.append("Overrun")
	for spawn: String in ["crack", "wgn", "wgs"]:
		for v: Variant in host_wave([["warden", 4], ["sentinel", 1]], _spawn_at(spawn), [], hero_pos()):
			order_wave(v as Unit, &"hero", hero_pos())


func _tick_storm(dt: float) -> void:
	if hold_start < 0.0 or not hero_alive():
		return
	if not west_bank(hero.global_position):
		storm = 0.0
		return
	storm = minf(1.0, storm + dt / float(by_difficulty(STORM_FILL)))
	if storm < 1.0:
		return
	var best: Array[Unit] = []
	for p: Vector3 in STAKES:
		for u: Unit in host_near(p, STORM_REACH):
			var clump := host_near(u.global_position, 6.0)
			if clump.size() >= 3 and clump.size() > best.size():
				best = clump
	if best.is_empty():
		return
	storm = 0.0
	storm_strikes += 1
	if fire_once(&"E12"):
		say_l("L18")
	if hud:
		hud.show_message(MSG_STORM, 3.0)
	flash_ring(best[0].global_position, 6.0)
	for i in mini(8, best.size()):
		var u := best[i]
		var dmg := 120.0 if u.unit_type and (String(u.unit_type.id) in [HOST_WARDEN, SENTINEL, SLINGER]) else 60.0
		u.take_damage(dmg, null)


# ---------------------------------------------------------------- waves (A.6)

func _spawn_at(id: String) -> Vector3:
	match id:
		"wgn":
			return wgs["wgn"].front_point() if wgs.has("wgn") and is_instance_valid(wgs["wgn"]) else WG_N
		"wgs":
			return wgs["wgs"].front_point() if wgs.has("wgs") and is_instance_valid(wgs["wgs"]) else WG_S
		"ruin":
			return RUIN
	return CRACK


func _fire_wave(row: Array) -> void:
	var id := String(row[1])
	waves_fired.append(id)
	for part: Array in row[2]:
		var spawn := String(part[0])
		var rows: Array = part[1]
		if gates_broken.has(spawn):
			var half: Array = []
			for r: Array in rows:
				half.append([r[0], int(r[1]) / 2])
			rows = half
			spawn = "crack"
		var goal := KEEP_POS
		if spawn == "ruin" and id == "H7":
			goal = Vector3(NODES[3][1])
		var out := host_wave(rows, _spawn_at(spawn), [], goal)
		if id == "H1" and not out.is_empty():
			fire_once(&"E3")
			say_l("L6")
			say_l("L7")
	if id == "H3" and fire_once(&"E6"):
		var g: WardenGate = wgs.get("wgn")
		if g and g.is_alive():
			g.hp = g.max_hp * 0.5
			g.take_damage(0.01)
			flash_ring(g.global_position, 4.0)
		say_l("L8")
		say_l("L9")
	if id == "H8":
		say_l("L20")


func _tick_waves() -> void:
	if hold_start < 0.0:
		return
	var t := mission_time() - hold_start
	var diff := clampi(mission_difficulty, 0, 2)
	for row: Array in WAVES:
		if t >= float(row[0]) and (String(row[1]) != "H9" or diff == 2) and fire_once(StringName("wave_" + String(row[1]))):
			_fire_wave(row)
	if t >= 480.0 and fire_once(&"E8"):
		_stranded()
	if t >= 210.0 and fire_once(&"E5"):
		set_objective(&"sec_storm", "active")


func _on_gate_down(g: WardenGate) -> void:
	gates_broken.append(String(g.gate_id))


# ---------------------------------------------------------------- Ashby's scouts (E8 / E9)

func _stranded() -> void:
	say_l("L12")
	say_l("L13")
	say_l("L14")
	set_objective(&"sec_scouts", "active")
	for i in 4:
		var s := make_unit("ashby_scout")
		_spawn(s, Unit.Team.PLAYER, WAGON + Vector3(i * 1.4 - 2.0, 0.0, 1.0))
		mark_scripted(s)
		set_dormant(s, true)
		scouts.append(s)
	host_wave([["warden", 6]], WAGON + Vector3(8.0, 0.0, -6.0), [], WAGON)
	fog.reveal(Unit.Team.PLAYER, WAGON, 10.0)


func _tick_scouts() -> void:
	if scouts.is_empty():
		return
	var t := mission_time() - hold_start
	for v: Variant in scouts:
		if not is_instance_valid(v):
			continue
		var s := v as Unit
		if s == null or not s.is_alive() or s.has_meta(&"home"):
			continue
		if t >= 510.0 and is_dormant(s):
			set_dormant(s, false)
			s.command_move(FORD)
			s.set_meta(&"leg", 1)
		if is_dormant(s):
			continue
		if west_bank(s.global_position) and int(s.get_meta(&"leg", 0)) >= 1:
			s.set_meta(&"home", true)
			s.command_move(ASHBY_POS + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
			s.set_meta(META_HOME, ASHBY_POS)
			_guards.append(s)
			scouts_home += 1
			if scouts_home >= 3 and fire_once(&"E9"):
				say_l("L15")
				set_objective(&"sec_scouts", "done")
		elif not s.has_move_order():
			s.command_move(FORD if int(s.get_meta(&"leg", 0)) == 1 else KEEP_POS)
			if _flat(s.global_position, FORD) < 4.0:
				s.set_meta(&"leg", 2)
	if objective_state("sec_scouts") == "active" and _scouts_lost() > 1:
		set_objective(&"sec_scouts", "failed")


func _scouts_lost() -> int:
	var n := 0
	for v: Variant in scouts:
		if not is_instance_valid(v) or not (v as Unit).is_alive():
			n += 1
	return n


# ---------------------------------------------------------------- helper, keep, the end

func _on_helper_arrived() -> void:
	fire_once(&"E11")
	say_l("L16")
	say_l("L17")
	set_objective(&"sec_storm", "done")


func _tick_hold(dt: float) -> void:
	if hold_start < 0.0 or is_ending():
		return
	if surge_until <= mission_time():
		hold_left = maxf(0.0, hold_left - dt)
	if hold_left <= 0.0:
		_great_storm()


func _great_storm() -> void:
	if not fire_once(&"E13"):
		return
	set_objective(&"obj_line", "done")
	set_objective(&"obj_vessa", "done")
	set_objective(&"obj_keep", "done")
	if objective_state("sec_waited") == "active":
		set_objective(&"sec_waited", "done")
	for id: StringName in [&"sec_scouts", &"sec_storm"]:
		if objective_state(id) == "active":
			set_objective(id, "failed")
	set_mission_flag("e8m1_fire_hunger_peak", int(hunger_peak))
	finish_road()
	for id: String in wgs:
		var g: WardenGate = wgs[id]
		if g and g.is_alive():
			g.take_damage(1.0e6)
	play_cutscene(&"e8m1_fire_storm", _storm_end)


func _storm_end() -> void:
	for id in ["L20", "L21", "L22", "L23", "L24"]:
		say_l(id)
	win(1.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E16")
	say_l("L25")
	super()


func _variant_tick(dt: float) -> void:
	_tick_hold(dt)
	_tick_hunger(dt)
	_tick_storm(dt)
	_tick_waves()
	_tick_scouts()
	tick_kneelers([ashby])
	if keep and keep.is_alive() and keep.hp < keep.max_hp * 0.3 and fire_once(&"E15"):
		say_l("L26")


func save_block_reason() -> String:
	if has_fired(&"E13"):
		return SAVE_REASON_SCRIPTED
	return super()
