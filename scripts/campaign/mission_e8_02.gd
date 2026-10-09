class_name MissionE8_02
extends MissionE8Muster
## Episode 8, mission 2 "The Last Muster" (docs/design/mission-e8-02.md): the four kingdoms on one field for the first
## time. Each wizard walks a key to their keyhole (break its Keystone Pylon, then 5 s within 3 m, no Host within 8 m);
## the three allies march when their Muster bar is full (time, the player's kills in their quarter, answered Help
## calls). Every death of the four seats feeds the Hollow meter (the Early Rise at 100 %). Four lit keyholes = the
## turn and e8m3. Spotlight: the kingdom's T2 heavy rider.
##
## Built deviations (2026-10-09, besides MissionE8Muster's): the pylons are Warden-Gate structures (1 400 HP, 2 Wardens
## / 35 s while they stand); a lit keyhole is a pillar of the kingdom's colour (no Key-Ward HP in e8m2: it stays lit);
## pings are HUD messages with the ally's line (no ping wheel). Story floor: an ally marches no earlier than 14:00 /
## 18:00 / 24:00 (A2 / B1 / B2, normal; "the muster horns") however full its bar, so the scripted run lands in the
## 25-30 min target.

const MISSION_ID := &"e8m2"
const MISSION_TITLE := "The Last Muster"
const PYLON_HP: Array[float] = [1100.0, 1400.0, 1700.0]
const PYLON_EVERY := 35.0
const PYLON_GUARDS := 6
const CHANNEL := 5.0
const RING := 3.0
const RING_CLEAR := 8.0
const ALLY_RING := 6.0   ## a bot's ring (tuning: its wizard is blocked by its own army around the keyhole)
const MUSTER_TIME := {Teams.ALLY: [780.0, 960.0, 1080.0], Unit.Team.ENEMY: [960.0, 1200.0, 1380.0],
		Teams.ENEMY_2: [1140.0, 1440.0, 1680.0]}
const MARCH_FLOOR := {Teams.ALLY: [720.0, 840.0, 960.0], Unit.Team.ENEMY: [900.0, 1080.0, 1200.0],
		Teams.ENEMY_2: [1200.0, 1440.0, 1620.0]}
const HELP_KILL: Array[float] = [3.0, 2.0, 1.5]
const HELP_PING: Array[float] = [15.0, 10.0, 8.0]
const HELP_KILL_MAX := 40.0
const HELP_PING_MAX := 3
const HELP_R := 30.0
const PING_HOST := 6
const PING_EVERY := 90.0
const PING_ANSWER := 60.0
const PING_POP := 8
const HOLLOW_DEATH: Array[float] = [0.35, 0.5, 0.6]
const CRACK_EVERY := 90.0
const CRACK_FIRST := 90.0
const GATE_EVERY := 180.0   ## spec 120 s (tuning)
const GATE_FIRST := 180.0
const COLUMN_AT := 720.0
const LINES_HELP := {&"fire": "L10", &"shadow": "L11", &"ice": "L12", &"nature": "L13"}
const LINES_THANKS := {&"fire": "L14", &"shadow": "L15", &"ice": "L16", &"nature": "L17"}
const LINES_MARCH := {&"fire": "L20", &"shadow": "L21", &"ice": "L22", &"nature": "L23"}
const LINES_KEY := {&"fire": "L24", &"shadow": "L25", &"ice": "L26", &"nature": "L27"}
const KINGDOM_COLOR := {&"fire": Color(1.0, 0.35, 0.15), &"shadow": Color(0.62, 0.30, 0.95), &"ice": Color(0.45, 0.75, 1.0),
		&"nature": Color(0.40, 0.90, 0.35)}
const BRIEFING_PARAGRAPHS: Array[String] = [
	"They came by four roads, and for one evening they stood on the same hill: fire, shadow, ice and green. Nobody drew a blade. Old Vey said it was the first miracle he had seen in thirty years.",
	"Below them, Crown Hollow is splitting open. Four keyholes have pushed up out of the earth, one on each bank, and the Hollow's pylons stand on every one of them. The Host is climbing out of the isle by the thousand.",
	"Each of you carries a key. Walk it to your keyhole. Help the others walk theirs. Every soldier who falls here falls into the Hollow, and something under the isle is counting.",
]
const BRIEFING_LINE := "Every death feeds the Hollow."
const HINT_START := "Break the pylon on your keyhole, then stand on it with your wizard for 5 s. Fight in an ally's quarter to make them muster faster."
const MSG_KEYHOLE_OPEN := "The {kingdom} keyhole is open."
const MSG_HELP := "{wizard} calls for help!"
const MSG_BREATH := "The isle is breathing."

## Read only.
var pylons := {}                 ## seat -> WardenGate
var lit := {}                    ## seat -> true
var key_progress := 0.0
var ally_channel := {}           ## seat -> progress
var muster := {}                 ## seat -> 0-100
var help_kills := {}             ## seat -> % from kills
var help_pings := {}             ## seat -> answered pings
var ping := {}                   ## seat -> [pos, until] (a Help call waiting for an answer)
var ping_next := {}              ## seat -> mission time of the next allowed call
var march_start := {}            ## seat -> soldiers at the march start
var march_at := {}               ## seat -> mission time its march started
var hollow := 0.0
var hollow_peak := 0.0
var early_rise := false
var victory_time := -1.0
var waves_fired: Array[String] = []
var gates := {}                  ## seat -> WardenGate (the Hollow Gates)

var _tick := 0.0
var _crack_i := 0
var _crack_next := CRACK_FIRST
var _gate_next := GATE_FIRST
var _sentinel_next := 0.0


func _init() -> void:
	super()
	use_lines(MISSION_ID)
	define_objectives([[&"obj_key", "primary"], [&"obj_four", "primary"], [&"obj_wizard", "primary"], [&"obj_keep", "primary"],
			[&"sec_help", "secondary"], [&"sec_hollow", "secondary"], [&"sec_gate", "secondary"]])
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	muster_config(c)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.start_level = 6
	c.start_spell_points = 5
	c.start_crystals.assign([800, 600, 450])
	c.start_essence = 150
	c.victory_banner = "VICTORY\nFour keys turned"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	var rider := {&"fire": &"pyrehoof_lancer", &"shadow": &"barrow_knight", &"ice": &"rimehorn_rider", &"nature": &"thornback_charger"}
	c.spotlight = {"id": rider.get(road, &"barrow_knight"), "trigger": &"manual", "key_hint": "Stables",
			"card": "Heavy riders: break the Rush before it reaches the keyhole."}
	return c


func _title_line() -> String:
	return "Episode 8, Mission 2: %s" % MISSION_TITLE


func _ready() -> void:
	super()
	tint_light(Color(1.0, 0.78, 0.55), 0.85, -14.0, Color(0.62, 0.54, 0.58), Color(0.32, 0.28, 0.44), Color(0.96, 0.62, 0.42))
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)


func _build_map() -> void:
	var extra: Array = []
	for s: int in SEATS:
		extra.append([_gate_pos(s), 6.0])
	build_field(1821, extra)
	var diff := clampi(mission_difficulty, 0, 2)
	for s: int in SEATS:
		var g := add_warden_gate(StringName("pylon_%s" % SEAT_NAMES[s]), keyhole_of(s), CRACK, float(PYLON_HP[diff]),
				PYLON_EVERY, _pylon_spawn)
		g.display_name = "Keystone Pylon"
		g.team = Unit.Team.NEUTRAL
		g.gate_down.connect(_on_pylon_down.bind(s))
		pylons[s] = g
		var hg := add_warden_gate(StringName("gate_%s" % SEAT_NAMES[s]), _gate_pos(s), rally_of(s), 1800.0, 0.0, Callable())
		hg.display_name = "Hollow Gate"
		hg.team = Unit.Team.NEUTRAL
		hg.gate_down.connect(_on_gate_down.bind(s))
		gates[s] = hg
		ground_disc(keyhole_of(s), RING, Color(1.0, 0.85, 0.45, 0.35), 0.05)


func _gate_pos(s: int) -> Vector3:
	return at_seat(s, Vector3(-48.0, 0.0, 12.0))


func _on_navigation_ready() -> void:
	start_seats(ALLY_LEVEL, 1.0, &"e8m1_" + String(road))
	for s: int in allies():
		muster[s] = 0.0
		help_kills[s] = 0.0
		help_pings[s] = 0
		ping_next[s] = 0.0
		ally_channel[s] = 0.0
	_road_bonuses()
	if flag_on("e8m1_ice_shut"):
		var g: WardenGate = gates[Unit.Team.PLAYER]
		g.hp = g.max_hp * 0.5
		g.take_damage(0.01)
	for p: Vector3 in [CRACK, keyhole_of(0), keyhole_of(Teams.ALLY), keyhole_of(Unit.Team.ENEMY), keyhole_of(Teams.ENEMY_2)]:
		fog.reveal(Unit.Team.PLAYER, p, 8.0)
	begin_mission([&"obj_key", &"obj_four", &"obj_wizard", &"obj_keep", &"sec_help", &"sec_hollow", &"sec_gate"])
	empty_slot_bonus()
	selection.select_units([hero])


## mission-e8-02.md 3.2: what the road brings to the player's seat.
func _road_bonuses() -> void:
	var rally := rally_of(Unit.Team.PLAYER)
	if flag_on("e8m1_fire_scouts"):
		spawn_army([["blaze_rider", 4]], rally + Vector3(0.0, 0.0, -4.0))
	if flag_int("e8m1_ice_saved") >= 30:
		spawn_army([["rimeshield", 4]], rally + Vector3(4.0, 0.0, 0.0))
	for i in clampi(flag_int("e8m1_nature_saved"), 0, 3):
		spawn_army([["wildwood_archer", 2], ["thornling", 2]], rally + Vector3(-4.0, 0.0, 2.0 * i))
	if not flag_on("e8m1_shadow_shovel"):
		hollow = clampf(2.0 * float(flag_int("e8_stone_uses")), 0.0, 50.0)


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e8m2_seats", _seats_end)


func _seats_end() -> void:
	for id in ["L1", "L2", "L3", "L4", "L5", "L5b"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 10.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {"title": _title_line(), "paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
			"objectives": [objective_text(&"obj_key", false), objective_text(&"obj_four", false), BRIEFING_LINE],
			"rule": Loc.sink(objective_text(&"obj_wizard"))}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_key":
			return "Turn your key: break the pylon, then stand at your keyhole"
		&"obj_four":
			if with_counter:
				return Loc.t("Light all four keyholes ({n} / 4) · the Hollow stirs: {pct} %", {"n": lit.size(), "pct": int(hollow)})
			return "Light all four keyholes"
		&"obj_wizard":
			return Loc.t("{wizard} must survive", {"wizard": Loc.t(wizard_name())})
		&"obj_keep":
			return "Your keep must stand"
		&"sec_help":
			if with_counter:
				var parts: Array[String] = []
				for s: int in allies():
					if lit.has(s):
						parts.append(Loc.t("{wizard}: key turned", {"wizard": Loc.t(String(WIZARD_NAME[seat_kind[s]]))}))
					else:
						parts.append(Loc.t("{wizard} musters {pct} %", {"wizard": Loc.t(String(WIZARD_NAME[seat_kind[s]])),
								"pct": int(muster.get(s, 0.0))}))
				return Loc.t("Muster together: help every ally ({n} / 3) · {list}", {"n": _helped(), "list": " · ".join(parts)})
			return "Muster together: help every ally"
		&"sec_hollow":
			return "Keep the Hollow under 75 %"
		&"sec_gate":
			return "Break your Hollow Gate"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_key":
			return {"positions": [keyhole_of(Unit.Team.PLAYER)]}
		&"obj_four":
			return {"counter": lit.size(), "goal": 4}
		&"sec_help":
			return {"counter": _helped(), "goal": 3}
		&"sec_gate":
			return {"positions": [_gate_pos(Unit.Team.PLAYER)]}
	return {}


func _helped() -> int:
	var n := 0
	for s: int in allies():
		if float(help_kills.get(s, 0.0)) + float(help_pings.get(s, 0)) * float(by_difficulty(HELP_PING)) >= 15.0:
			n += 1
	return n


# ---------------------------------------------------------------- the Host (4.2)

func _pylon_spawn(g: WardenGate) -> void:
	if host_near(g.global_position, 12.0).size() >= PYLON_GUARDS:
		return
	host_guards([["warden", 2]], g.front_point(), 2.0)


func _crack_size(t: float) -> Array:
	var w := mini(10, 6 + int(t / 240.0))   # spec +1 / 3:00, max 12 (tuning: four armies of scripted allies feed the meter)
	var rows: Array = [["warden", w]]
	if t >= 360.0:
		rows.append(["sentinel", 2 if t >= 900.0 else 1])
	return rows


func _rise_rows(rows: Array) -> Array:
	if not early_rise:
		return rows
	var out: Array = []
	for r: Array in rows:
		out.append([r[0], int(ceil(float(r[1]) * 1.25))])   # spec + 50 % (tuning)
	return out


func _tick_host() -> void:
	var t := mission_time()
	if t >= _crack_next:
		_crack_next += CRACK_EVERY
		var s: int = SEATS[_crack_i % 4]
		_crack_i += 1
		if lit.size() < 4 and not lit.has(s):   # a lit keyhole's seat is left alone (tuning)
			waves_fired.append("crack%s" % SEAT_NAMES[s])
			crack_toward(s, _rise_rows(_crack_size(t)))
		if fire_once(&"E2"):
			say_l("L6")
	if t >= _gate_next:
		_gate_next += GATE_EVERY
		if fire_once(&"E4"):
			say_l("L7")
		for s: int in SEATS:
			var g: WardenGate = gates[s]
			if g and g.is_alive():
				var rows: Array = [["warden", mini(8, 4 + int(t / 240.0))]]
				if t >= 600.0:
					rows.append(["sentinel", 1])
				host_wave(_rise_rows(rows), g.front_point(), [_node_pos(s, "a")], rally_of(s))
	if early_rise and t >= _sentinel_next:
		_sentinel_next = t + 90.0
		crack_toward(SEATS[randi() % 4], [["sentinel", 1]])
	if t >= COLUMN_AT and fire_once(&"E12"):
		var sh := seat_of_kingdom(&"shadow")
		say_l("L29")
		say_l("L30")
		waves_fired.append("Column")
		var rows: Array = [["shade", 4], ["nightbolt", 2], ["shadow_knight", 2], ["gloom_deacon", 1]]   # spec 6 / 3 (tuning)
		if not flag_on("e8m1_shadow_raids"):
			rows.append(["barrow_knight", 2])
		host_wave(rows, at_seat(sh, Vector3(-50.0, 0.0, 50.0)), [], keep_pos(sh))


func _on_pylon_down(_g: WardenGate, s: int) -> void:
	if is_ending():
		return
	flash_ring(keyhole_of(s), 4.0)
	if hud:
		hud.show_message(Loc.t(MSG_KEYHOLE_OPEN, {"kingdom": Loc.t(String(seat_kind[s]).capitalize())}), 4.0)
	if s == Unit.Team.PLAYER and fire_once(&"E5"):
		say_l("L8")
		waves_fired.append("Rush")
		crack_toward(Unit.Team.PLAYER, _rise_rows([["warden", 8], ["sentinel", 2]]))


func _on_gate_down(_g: WardenGate, s: int) -> void:
	if s == Unit.Team.PLAYER and not is_ending():
		fire_once(&"E15")
		say_l("L32")
		set_objective(&"sec_gate", "done")


# ---------------------------------------------------------------- keyholes

func _tick_keyholes(dt: float) -> void:
	var s := Unit.Team.PLAYER
	if not lit.has(s) and not (pylons[s] as WardenGate).is_alive():
		key_progress = ring_step(hero, key_progress, keyhole_of(s), RING, CHANNEL, RING_CLEAR, dt)
		if key_progress >= CHANNEL:
			_light(s)
	for a: int in allies():
		if lit.has(a) or ally_busy.get(a, &"") != &"march":
			continue
		var pg := pylons[a] as WardenGate
		if pg.is_alive():   # the marching army breaks it (scripted: 4 HP / s per soldier within 12 m)
			var n := 0
			for v: Variant in ally_soldiers(a):
				if _flat((v as Unit).global_position, keyhole_of(a)) <= 16.0:
					n += 1
			var aw: Wizard = seat_wizard.get(a)
			if aw and aw.is_alive() and _flat(aw.global_position, keyhole_of(a)) <= 16.0:
				n += 3
			if n > 0:
				pg.take_damage(4.0 * n * dt / Unit.armor_multiplier(pg.armor), seat_wizard.get(a))
			continue
		var w: Wizard = seat_wizard.get(a)
		if w == null or not w.is_alive() or w.has_meta(&"kneeling"):
			continue
		if _flat(w.global_position, keyhole_of(a)) > ALLY_RING - 1.0:
			if not w.has_move_order():
				w.command_move(keyhole_of(a))
		ally_channel[a] = ring_step(w, float(ally_channel[a]), keyhole_of(a), ALLY_RING, CHANNEL, 0.0, dt)   # its army holds the ring
		if float(ally_channel[a]) >= CHANNEL:
			_light(a)


func _light(s: int) -> void:
	if lit.has(s):
		return
	lit[s] = true
	flash_ring(keyhole_of(s), 6.0)
	pillar(keyhole_of(s), KINGDOM_COLOR[seat_kind[s]], 10.0)
	if s == Unit.Team.PLAYER:
		fire_once(&"E6")
		say_w("L9")
		set_objective(&"obj_key", "done")
	else:
		say_ally(s, LINES_KEY)
		ally_home(s)
	set_objective(&"obj_four", "active")
	if lit.size() >= 4:
		_turn()


# ---------------------------------------------------------------- muster bars (4.3), pings (6.4)

func _tick_muster(dt: float) -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	var t := mission_time()
	for s: int in allies():
		if lit.has(s):
			continue
		var busy: StringName = ally_busy.get(s, &"")
		if busy != &"march":
			muster[s] = minf(100.0, float(muster[s]) + 100.0 * dt / float(MUSTER_TIME[s][diff]))
		if float(muster[s]) >= 50.0 and fire_once(StringName("push_%d" % s)):
			var g: WardenGate = gates[s]
			if g and g.is_alive():
				ally_order(s, g.global_position, &"push")
				after(60.0, _push_home.bind(s))
		if float(muster[s]) >= 100.0 and busy != &"march" and t >= float(MARCH_FLOOR[s][diff]):
			_march(s)
		elif busy == &"march":
			# a bot's march never stalls the story (tuning, 2026-10-09): its pylon falls 90 s in, its key turns 150 s in
			var since := t - float(march_at.get(s, t))
			var pg := pylons[s] as WardenGate
			if since >= 90.0 and pg.is_alive():
				pg.take_damage(1.0e6, seat_wizard.get(s))
			if since >= 150.0:
				_light(s)
				continue
			# (spec 4.3's failed march, back to 60 %, is not used: a scripted march that fails loops for minutes)
		_tick_ping(s)


func _push_home(s: int) -> void:
	if ally_busy.get(s, &"") == &"push":
		ally_home(s)


func _march(s: int) -> void:
	march_start[s] = ally_soldiers(s).size()
	march_at[s] = mission_time()
	ally_order(s, keyhole_of(s), &"march")
	if fire_once(StringName("E9_%d" % s)):
		say_ally(s, LINES_MARCH)
	waves_fired.append("pressure%s" % SEAT_NAMES[s])
	crack_toward(s, _rise_rows([["warden", 6], ["sentinel", 1]]))
	_call_help(s, keyhole_of(s))


func _tick_ping(s: int) -> void:
	var t := mission_time()
	var p: Array = ping.get(s, [])
	if not p.is_empty():
		if t > float(p[1]):
			ping.erase(s)
		elif _player_pop_near(p[0], HELP_R) >= PING_POP:
			ping.erase(s)
			if int(help_pings[s]) < HELP_PING_MAX:
				help_pings[s] = int(help_pings[s]) + 1
				muster[s] = minf(100.0, float(muster[s]) + float(by_difficulty(HELP_PING)))
			if fire_once(StringName("E8_%d" % s)):
				say_ally(s, LINES_THANKS)
		return
	if t < float(ping_next[s]):
		return
	for at: Vector3 in [keyhole_of(s), rally_of(s), keep_pos(s)]:
		if host_near(at, 20.0).size() >= PING_HOST:
			_call_help(s, at)
			return


func _call_help(s: int, at: Vector3) -> void:
	ping_next[s] = mission_time() + PING_EVERY
	ping[s] = [at, mission_time() + PING_ANSWER]
	if fire_once(StringName("E7_%d" % s)):
		say_ally(s, LINES_HELP)
	if hud:
		hud.show_message(Loc.t(MSG_HELP, {"wizard": Loc.t(String(WIZARD_NAME[seat_kind[s]]))}), 4.0)
	flash_ring(at, 6.0)


func _player_pop_near(at: Vector3, r: float) -> int:
	var n := 0
	for u: Unit in units_of(Unit.Team.PLAYER, true):
		if u != hero and _flat(u.global_position, at) <= r and u.unit_type:
			n += int(u.unit_type.pop)
	return n


# ---------------------------------------------------------------- the Hollow meter (4.4)

func _on_any_unit_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or is_ending() or not match_started:
		return
	var team := int(unit.team)
	if team == Unit.Team.NEUTRAL:
		_count_help_kill(unit)
		return
	if not FRAME.has(team) or unit.is_in_group(&"helpers"):
		return
	# the allies' scripted armies are reinforced, so their dead count 15 % (tuning: the meter stays in the spec's 45-60 %)
	_feed(float(by_difficulty(HOLLOW_DEATH)) * (1.0 if team == Unit.Team.PLAYER else 0.15))


func _count_help_kill(unit: Unit) -> void:
	var k: Variant = unit.killer
	if k == null or not is_instance_valid(k) or k.get(&"team") == null or int(k.get(&"team")) != Unit.Team.PLAYER:
		return
	for s: int in allies():
		if lit.has(s) or float(help_kills[s]) >= HELP_KILL_MAX:
			continue
		if _flat(unit.global_position, keep_pos(s)) <= HELP_R or _flat(unit.global_position, keyhole_of(s)) <= HELP_R:
			var add := minf(float(by_difficulty(HELP_KILL)), HELP_KILL_MAX - float(help_kills[s]))
			help_kills[s] = float(help_kills[s]) + add
			muster[s] = minf(100.0, float(muster[s]) + add)
			return


func _on_ally_kneel(u: Unit) -> void:
	# spec +3 % per kneel; tuning: +1 %, once per 2:00 per wizard (a scripted ally kneels again and again in a long fight)
	if mission_time() >= float(u.get_meta(&"kneel_fed", -1.0e9)) + 120.0:
		u.set_meta(&"kneel_fed", mission_time())
		_feed(1.0)


func _feed(n: float) -> void:
	if early_rise:
		return
	var before := hollow
	hollow = minf(100.0, hollow + n)
	hollow_peak = maxf(hollow_peak, hollow)
	if before < 25.0 and hollow >= 25.0 and hud:
		hud.show_message(MSG_BREATH, 4.0)
	if before < 50.0 and hollow >= 50.0 and fire_once(&"E13a"):
		say_l("L18")
	if before < 75.0 and hollow >= 75.0 and fire_once(&"E13b"):
		say_l("L19")
		set_objective(&"sec_hollow", "failed")
	if hollow >= 100.0 and fire_once(&"E14"):
		early_rise = true
		set_mission_flag("e8m2_early_rise", true)
		play_cutscene(&"e8m2_hand", _hand_end)


func _hand_end() -> void:
	say_l("L31")
	box_prop(CRACK, Vector3(2.5, 9.0, 2.5), Color(0.55, 0.48, 0.40), 0.5)
	flash_ring(CRACK, 8.0)


# ---------------------------------------------------------------- the end

func _turn() -> void:
	if not fire_once(&"E17"):
		return
	victory_time = mission_time()
	set_objective(&"obj_four", "done")
	set_objective(&"obj_wizard", "done")
	set_objective(&"obj_keep", "done")
	set_objective(&"sec_help", "done" if _helped() >= 3 else "failed")
	if objective_state("sec_hollow") == "active":
		set_objective(&"sec_hollow", "done")
	if objective_state("sec_gate") == "active":
		set_objective(&"sec_gate", "failed")
	set_mission_flag("e8m2_hollow_peak", int(hollow_peak))
	set_mission_flag("e8m2_time", int(victory_time))
	set_mission_flag("e8m2_early_rise", early_rise)
	clear_host()
	play_cutscene(&"e8m2_turn", _turn_end)


func _turn_end() -> void:
	for id in ["L33", "L34", "L35", "L36", "L37", "L38", "L38b"]:
		say_l(id)
	win(1.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E18")
	say_w("L39")
	set_objective(&"obj_wizard", "failed")
	super()


func save_block_reason() -> String:
	if has_fired(&"E17"):
		return SAVE_REASON_SCRIPTED
	return super()


func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held or save_restoring:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.5
	_tick_host()
	_tick_keyholes(0.5)
	_tick_muster(0.5)
	tick_allies(0.5)
	keep_key_relic()
	if keep and keep.is_alive() and keep.hp < keep.max_hp * 0.3 and fire_once(&"E20"):
		say_l("L40")
	objectives_changed.emit()
	if hud and mission_hud == null:
		hud.set_objective(_objective_text())
