class_name MissionE8_03
extends MissionE8Muster
## Episode 8, mission 3 "The Hollow King" (docs/design/mission-e8-03.md): the final battle. Obren's last body rises from
## the pit (phase 0, 4:30), is hurt only during Chain Surges while all four Key-Wards stand at half or more (phase 1),
## walks on the weakest keep under a stone plate (phase 2, Cracked Limb staggers, Hollow Feeding), then kneels and is
## opened only when all four wizards hold their keyholes together (phase 3: Exposed + the Master's lance). His fall
## opens the closing film chain (ep8_ending_a -> throne -> choice -> b / dark -> bookend -> credits).
## Spotlight: the kingdom's T3 elite rider.
##
## Built deviations (2026-10-09, besides MissionE8Muster's): the King is a local unit on the Rime Colossus model (x 2.2)
## held in place by `rooted` outside phase 2; his damage gates are a heal-back of the blocked share on `damage_taken`.
## The Key-Wards are mission data (3 000 HP, a ring and a pillar): the Tear, the Hollow Pulse and Host units within 5 m
## (6 HP / s each) wear them down, they mend 0.5 % / s with no Host within 12 m. Allied helpers are not on the field:
## the Hollow Pulse checks the player's helper only. No titans (sec_titan dropped). Phases (campaign review 2026-10-16):
## the King's HP moves them (60 % -> phase 2, 25 % -> phase 3), with only a PHASE_LOCKOUT minimum after the previous
## phase began (no fixed clock floors); the King falls on the third turn at the earliest (normal). The wards: their HP
## is in the objective line and called on screen at 50 % / 25 %, and the hero has a Ward Mend (MEND_*: stand within
## 6 m of a Key-Ward, Host-free, for 3 s: +25 %, or a broken one relit at half; 60 s cooldown). The King's look:
## KING_ART's static dress(unit) when the file exists. Tuning: the chains themselves hit him (8 % per Surge and per turn,
## 5 % per lash every 60 s while he walks) and the Hurl hits 45 on at most 6 (a scripted army cannot dodge); his crush is 40 (spec 90).

const MISSION_ID := &"e8m3"
const MISSION_TITLE := "The Hollow King"
const KING_HP: Array[float] = [22000.0, 30000.0, 40000.0]
const WARD_HP: Array[float] = [3600.0, 3000.0, 2600.0]
const RISE: Array[float] = [210.0, 270.0, 270.0]
const SURGE_EVERY: Array[float] = [100.0, 110.0, 120.0]
const SURGE_LEN: Array[float] = [12.0, 10.0, 9.0]
const TEAR: Array[float] = [12.0, 16.0, 20.0]   ## spec 30 / 40 / 50 (tuning: the mend could never keep up)
const PULSE_EVERY: Array[float] = [9.0, 8.0, 7.0]
const TURNS_MIN: Array[int] = [2, 3, 4]
const PHASE_LOCKOUT := 240.0     ## a phase lasts at least this long, whatever the damage (4:00)
const WALK_MULT := 0.45          ## phase 2 damage share outside the staggers (was 0.3: the walk lasted for the clock)
const MEND_R := 6.0
const MEND_CHANNEL := 3.0
const MEND_GAIN := 0.25
const MEND_COOLDOWN := 60.0
const WARD_WARN: Array[float] = [0.5, 0.25]
const KING_ART := "res://art/units/titans/hollow_king/hollow_king_art.gd"
const KING_LIMB := {Unit.Team.PLAYER: &"arm_r", Teams.ALLY: &"arm_l", Unit.Team.ENEMY: &"leg_l", Teams.ENEMY_2: &"leg_r"}
const RING := 3.0
const RING_CLEAR := 8.0
const RELIGHT_WAIT := 30.0
const RELIGHT := 5.0
const DRAIN_R := 5.0
const DRAIN := 6.0
const MEND := 0.005
const HURL_R := 4.0
const HURL_DMG := 45.0          ## spec 90 (tuning: a scripted army cannot dodge the telegraph)
const HURL_MAX := 6
const CHAIN_SURGE_HIT := 0.08     ## each Chain Surge / turn: the four chains crush him (share of max HP)
const CHAIN_LASH_HIT := 0.05     ## phase 2: a chain lashes him every 60 s while he walks
const CHAIN_LASH_EVERY := 60.0
const STOMP_R := 9.0
const STOMP_DMG := 70.0
const FEED_R := 20.0
const FEED_HP := 75.0
const FED_LIMIT := 1500.0
const EXPOSED := 10.0
const LANCE := 300.0
const TURN_FILL := 5.0
const TURN_GAP := 20.0          ## spec 6 s (tuning: three turns, not three in a minute)
const REMNANT_AT := 540.0
const LIMB := {Unit.Team.PLAYER: "right arm", Teams.ALLY: "left arm", Unit.Team.ENEMY: "left leg", Teams.ENEMY_2: "right leg"}
const LINES_WEAK := {&"fire": "L11_vessa", &"shadow": "L11_malrik", &"ice": "L11_torvald", &"nature": "L11_ysolde"}
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The four keys turned, and Crown Hollow fell in on itself. Out of the dust climbed the last thing Obren ever built: a king of rubble eighteen metres tall, with the Hollow Throne for a heart and four chains of light dragging at his limbs.",
	"The chains hold only while the keyholes hold. Every time the four pull together, the King is bound and can be hurt. Let one keyhole weaken and the chains go slack; let two fall at once and he is free.",
	"Somewhere under the pit, a white-gold light is climbing toward the surface. The Master is coming up. Hold the King until he gets there, and then, all four of you, turn the keys together.",
]
const BRIEFING_LINE := "Every death near the King feeds him."
const HINT_START := "The King climbs for 4:30. Hold your keyhole. When the chains pull together, strike."
const HINT_TOGETHER := "All four stand at your keyholes. Keep your helper beside you: the Hollow Pulse breaks the turn unless every helper grounds it."
const MSG_SURGE := "The chains pull! Strike now!"
const MSG_WAITING := "The chains wait: the {kingdom} keyhole is below half"
const MSG_BROKEN := "The {kingdom} chain is broken! The King's {limb} is free!"
const MSG_STAGGER := "The King staggers!"
const MSG_OPEN := "The King is open!"
const MSG_WARD_LOW := "The {kingdom} Key-Ward is at {pct} %!"
const MSG_MENDED := "The {kingdom} Key-Ward is mended."
const HINT_MEND := "Ward Mend: stand beside a Key-Ward with your wizard, no Host near, for 3 s (+25 %, every 60 s). It relights a broken one."

## Read only.
var phase := 0
var king: Unit
var king_max := 30000.0
var ward := {}                   ## seat -> HP
var ward_max := 3000.0
var broken := {}                 ## seat -> mission time it broke
var relight := {}                ## seat -> channel progress
var ever_broken := false
var surge_next := 0.0
var surge_until := 0.0
var stagger_until := 0.0
var cracked: Array[int] = []
var exposed_until := 0.0
var turn_ready_at := 0.0
var turn_fill := 0.0
var turns := 0
var pulse_next := 0.0
var fed := 0.0
var walk_target: Node3D
var hush: Unit
var victory_time := -1.0
var waves_fired: Array[String] = []

var _tick := 0.0
var _hurl_next := 0.0
var _call_next := 0.0
var _sentinel_next := 0.0
var _stomp_next := 0.0
var _walk_next := 0.0
var _tide_next := 30.0
var _tide_i := 0
var _lash_next := 0.0
var phase_at := 0.0              ## mission time the current phase began
var mend_ready_at := 0.0         ## mission time the hero's Ward Mend is ready again
var mend_progress := 0.0
var ward_warned := {}            ## seat -> lowest WARD_WARN index announced (re-armed above +10 %)


func _init() -> void:
	super()
	use_lines(MISSION_ID)
	define_objectives([[&"obj_rise", "primary"], [&"obj_chains", "primary"], [&"obj_walk", "primary"],
			[&"obj_together", "primary"], [&"obj_keys", "primary"], [&"obj_wizard", "primary"], [&"obj_keep", "primary"],
			[&"sec_chains", "secondary"], [&"sec_fed", "secondary"]])
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	local_unit("rime_colossus", "hollow_king", "The Hollow King", {"max_hp": 30000.0, "armor": 25.0, "attack_damage": 40.0,
			"attack_range": 6.0, "attack_cooldown": 3.0, "move_speed": 1.6, "aggro_range": 12.0, "pop": 0, "kill_xp": 0,
			"cost": 5000, "commandable": false, "neutral_leash": false, "faction": &"shadow"})
	_scales["hollow_king"] = 2.2


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	muster_config(c)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.start_level = 7
	c.start_spell_points = 6
	c.start_crystals.assign([900, 700, 550])
	c.start_essence = 150
	c.victory_banner = "VICTORY\nThe King falls"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	var rider := {&"fire": &"sunforge_cataphract", &"shadow": &"veilborn_dreadrider", &"ice": &"frostcrown_juggernaut",
			&"nature": &"glade_outrider"}
	c.spotlight = {"id": rider.get(road, &"sunforge_cataphract"), "trigger": &"manual", "key_hint": "Stables",
			"card": "Your elite riders: the King's tearing at that chain. Ride."}
	return c


func _title_line() -> String:
	return "Episode 8, Mission 3: %s" % MISSION_TITLE


func _ready() -> void:
	super()
	tint_light(Color(0.85, 0.70, 0.55), 0.75, -18.0, Color(0.48, 0.42, 0.46), Color(0.20, 0.18, 0.28), Color(0.80, 0.52, 0.36))
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)


func _build_map() -> void:
	build_field(1831, [])
	ground_disc(CRACK, 14.5, Color(0.30, 0.24, 0.20, 0.60), 0.04)
	for s: int in SEATS:
		ground_disc(keyhole_of(s), RING, Color(1.0, 0.85, 0.45, 0.40), 0.05)


func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	start_seats(7, 1.25, &"e8m2")
	ward_max = float(WARD_HP[diff])
	var start_pct := 1.0 if flag_on("e8m2_helped_all") else 0.85
	for s: int in SEATS:
		ward[s] = ward_max * start_pct
		relight[s] = 0.0
		pillar(keyhole_of(s), MissionE8_02.KINGDOM_COLOR[seat_kind[s]], 10.0)
	_road_bonuses()
	king_max = float(KING_HP[diff]) * (1.0 + 0.05 * float(mini(flag_int("e8_stone_uses"), 5)))
	if flag_on("e8m2_early_rise"):
		king_max *= 1.10
	local_type("hollow_king").max_hp = king_max
	king = make_unit("hollow_king")
	_spawn(king, Unit.Team.NEUTRAL, CRACK)
	_dress_king()
	mark_scripted(king)
	arm_enemy(king)
	king.add_to_group(&"boss")
	king.damage_taken.connect(_on_king_hit)
	king.death_guard = _king_guard
	surge_next = float(RISE[diff]) + float(SURGE_EVERY[diff]) * 0.5
	for p: Vector3 in [CRACK, keyhole_of(Teams.ALLY), keyhole_of(Unit.Team.ENEMY), keyhole_of(Teams.ENEMY_2)]:
		fog.reveal(Unit.Team.PLAYER, p, 8.0)
	begin_mission([&"obj_rise", &"obj_keys", &"obj_wizard", &"obj_keep", &"sec_chains"])
	empty_slot_bonus()
	selection.select_units([hero])


func _road_bonuses() -> void:
	var rally := rally_of(Unit.Team.PLAYER)
	if flag_on("e8m1_fire_scouts"):
		spawn_army([["blaze_rider", 4]], rally + Vector3(0.0, 0.0, -4.0))
	if flag_int("e8m1_ice_saved") >= 30:
		spawn_army([["rimeshield", 4]], rally + Vector3(4.0, 0.0, 0.0))
	for i in clampi(flag_int("e8m1_nature_saved"), 0, 3):
		spawn_army([["wildwood_archer", 2], ["thornling", 2]], rally + Vector3(-4.0, 0.0, 2.0 * i))


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e8m3_king", _king_end)


func _king_end() -> void:
	for id in ["L1", "L2", "L3", "L4", "L5", "L6"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 10.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {"title": _title_line(), "paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
			"objectives": [objective_text(&"obj_rise", false), objective_text(&"obj_keys", false), BRIEFING_LINE],
			"rule": Loc.sink(objective_text(&"obj_wizard"))}


func _weakest_ward() -> int:
	var best := Unit.Team.PLAYER
	if ward.size() < SEATS.size():
		return best
	var bv := 2.0
	for s: int in SEATS:
		var v := float(ward[s]) / ward_max
		if v < bv - 0.0001:
			bv = v
			best = s
	return best


func _wards_text() -> String:
	var parts: Array[String] = []
	if ward.size() < SEATS.size():
		return ""
	for s: int in SEATS:
		var k := Loc.t(String(seat_kind[s]).capitalize())
		if broken.has(s):
			parts.append(Loc.t("{kingdom} broken", {"kingdom": k}))
		else:
			parts.append("%s %d %%" % [k, int(100.0 * float(ward[s]) / ward_max)])
	return " · ".join(parts)


func objective_text(id: StringName, with_counter := true) -> String:
	var t := mission_time()
	match id:
		&"obj_rise":
			if with_counter:
				return Loc.t("The King is climbing: hold the four keyholes ({time})", {"time": mmss(maxf(0.0, float(by_difficulty(RISE)) - t))})
			return "The King is climbing: hold the four keyholes"
		&"obj_chains":
			if with_counter:
				var why := ""
				if t < surge_until:
					why = Loc.t("Chain Surge: strike!")
				elif _surge_blocker() >= 0:
					why = Loc.t("waiting: the {kingdom} keyhole is below half", {"kingdom": Loc.t(String(seat_kind[_surge_blocker()]).capitalize())})
				else:
					why = Loc.t("Next Chain Surge {time}", {"time": mmss(maxf(0.0, surge_next - t))})
				return Loc.t("Strike when the chains pull together ({hp} %) · {why}", {"hp": _king_pct(), "why": why})
			return "Strike when the chains pull together"
		&"obj_walk":
			if with_counter:
				return Loc.t("Stop the King before he reaches a keep ({hp} %)", {"hp": _king_pct()})
			return "Stop the King before he reaches a keep"
		&"obj_together":
			if with_counter:
				return Loc.t("Hold together: all four at your keyholes ({hp} %, turn {fill} %)", {"hp": _king_pct(),
						"fill": int(100.0 * turn_fill / TURN_FILL)})
			return "Hold together: all four at your keyholes"
		&"obj_keys":
			if with_counter:
				return Loc.t("Never let two keyholes fall at once ({wards}) · {mend}", {"wards": _wards_text(), "mend": _mend_text()})
			return "Never let two keyholes fall at once"
		&"obj_wizard":
			return Loc.t("{wizard} must survive", {"wizard": Loc.t(wizard_name())})
		&"obj_keep":
			return "Your keep must stand"
		&"sec_chains":
			return "Keep every chain bound"
		&"sec_fed":
			if with_counter:
				return Loc.t("Feed him nothing: he heals less than 1 500 while he walks ({n})", {"n": int(fed)})
			return "Feed him nothing: he heals less than 1 500 while he walks"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_rise":
			return {"countdown": maxf(0.0, float(by_difficulty(RISE)) - mission_time())}
		&"obj_keys":
			return {"positions": [keyhole_of(_weakest_ward())]}
		&"obj_together":
			return {"positions": [keyhole_of(Unit.Team.PLAYER)]}
	return {}


func _mend_text() -> String:
	var left := mend_ready_at - mission_time()
	if left <= 0.0:
		return Loc.t("Ward Mend ready")
	return Loc.t("Ward Mend {time}", {"time": mmss(left)})


func _king_pct() -> int:
	return int(100.0 * king.hp / maxf(1.0, king.max_hp)) if king and is_instance_valid(king) else 0


# ---------------------------------------------------------------- the King's damage gates

func _king_mult() -> float:
	var t := mission_time()
	match phase:
		1:
			return 1.0 if t < surge_until else 0.0
		2:
			return 1.0 if t < stagger_until else WALK_MULT
		3:
			return 1.0 if t < exposed_until else 0.1
	return 0.0


## The King never dies by damage: he holds at 1 HP and falls through _check_fall.
func _king_guard(_a: Variant) -> bool:
	king.hp = 1.0
	_check_fall()
	return true


func _on_king_hit(amount: float, _attacker: Node3D) -> void:
	if is_ending():   # review 2026-10-10 #1: a pending defeat must not start the fall / a film
		return
	var m := _king_mult()
	if m < 1.0:
		king.hp = minf(king.max_hp, king.hp + amount * (1.0 - m))
	var t := mission_time()
	if phase == 1 and king.hp <= king.max_hp * 0.6:
		king.hp = king.max_hp * 0.6
		if t >= phase_at + PHASE_LOCKOUT:
			_phase2()
	elif phase == 2 and king.hp <= king.max_hp * 0.25:
		king.hp = king.max_hp * 0.25
		if t >= phase_at + PHASE_LOCKOUT:
			_phase3()
	elif phase == 3 and king.hp <= 1.0:
		_check_fall()


## The chains' own blow (Surge, lash, turn): a share of his max HP, through the phase floors.
func chain_hit(frac: float) -> void:
	if king == null or not is_instance_valid(king):
		return
	king.hp = maxf(1.0, king.hp - king.max_hp * frac)
	_on_king_hit(0.0, null)


func _check_fall() -> void:
	if is_ending():
		return
	if phase != 3:
		king.hp = maxf(king.hp, king.max_hp * (0.6 if phase <= 1 else 0.25))
		return
	if turns < int(by_difficulty(TURNS_MIN)):
		king.hp = maxf(king.hp, 1.0)
		return
	_fall()


# ---------------------------------------------------------------- phases

func _tick_phase0() -> void:
	var t := mission_time()
	var rise := float(by_difficulty(RISE))
	if king and is_instance_valid(king):
		var m := king.get_model()
		if m:
			m.scale = Vector3.ONE * 2.2 * lerpf(0.6, 1.0, clampf(t / rise, 0.0, 1.0))
	if t >= _tide_next:
		_tide_next += 60.0
		var s: int = SEATS[_tide_i % 4]
		_tide_i += 1
		waves_fired.append("pit%s" % SEAT_NAMES[s])
		crack_toward(s, [["warden", 8], ["sentinel", 1]])
		if fire_once(&"E2"):
			say_l("L7")
	if t >= rise:
		phase = 1
		phase_at = t
		fire_once(&"E3")
		set_objective(&"obj_rise", "done")
		set_objective(&"obj_chains", "active")
		say_l("L8")
		say_l("L9")
		if flag_int("e8_stone_uses") >= 3:
			say_l("L32")
		show_spotlight()
		if hud:
			hud.show_message(HINT_MEND, 8.0)


func _surge_blocker() -> int:
	for s: int in SEATS:
		if broken.has(s) or float(ward[s]) < ward_max * 0.5:
			return s
	return -1


func _tick_phase1(dt: float) -> void:
	var t := mission_time()
	var diff := clampi(mission_difficulty, 0, 2)
	if t >= surge_until and surge_until > 0.0:
		surge_until = 0.0
		for s: int in allies():
			if ally_busy.get(s, &"") == &"sortie":
				ally_home(s)
	if surge_until <= 0.0 and t >= surge_next:
		var b := _surge_blocker()
		if b >= 0:
			if fire_once(&"E5"):
				if b == Unit.Team.PLAYER:
					say_l("L11_vey")
				else:
					say_l(String(LINES_WEAK[seat_kind[b]]))
				if hud:
					hud.show_message(Loc.t(MSG_WAITING, {"kingdom": Loc.t(String(seat_kind[b]).capitalize())}), 4.0)
		else:
			surge_until = t + float(SURGE_LEN[diff])
			surge_next = t + float(SURGE_EVERY[diff])
			if fire_once(&"E4"):
				say_w("L10")
			if hud:
				hud.show_message(MSG_SURGE, 3.0)
			for s: int in SEATS:
				flash_ring(keyhole_of(s), 4.0)
			for s: int in allies():
				ally_order(s, CRACK, &"sortie")
			chain_hit(CHAIN_SURGE_HIT)
	# the Tear on the weakest ward
	var w := _weakest_ward()
	if not broken.has(w):
		_hurt_ward(w, float(TEAR[diff]) * dt)
	_hurl(dt, 10.0)
	if t >= _call_next:
		_call_next = t + 30.0
		_rubble_call(_weakest_ward(), 4)
	if t >= _sentinel_next:
		_sentinel_next = t + 90.0
		_rubble_call(_weakest_ward(), 0, 1)
	if t >= REMNANT_AT and fire_once(&"E7"):
		say_l("L14")
		var sh := seat_of_kingdom(&"shadow")
		waves_fired.append("Remnant")
		host_wave([["shade", 4], ["nightbolt", 2], ["shadow_knight", 1], ["gloom_deacon", 1]], at_seat(sh, Vector3(-50.0, 0.0, 50.0)),
				[], keyhole_of(sh))


func _phase2() -> void:
	if is_ending():
		return
	if phase != 1 or not fire_once(&"E8"):
		return
	phase = 2
	phase_at = mission_time()
	surge_until = 0.0
	set_objective(&"obj_chains", "done")
	set_objective(&"obj_walk", "active")
	set_objective(&"sec_fed", "active")
	play_cutscene(&"e8m3_walk", _walk_end)


func _walk_end() -> void:
	say_l("L15")
	say_l("L16")
	waves_fired.append("Last tide")
	for s: int in SEATS:
		crack_toward(s, [["warden", 3], ["sentinel", 1 if s % 2 == 0 else 0]])
	_walk_next = 0.0


## The lowest HP % keep (tuning: a tie goes to an ally, whose keep has the 20 % floor; spec: the player's).
func _weakest_keep() -> Keep:
	var best: Keep = null
	var bv := 2.0
	for s: int in allies() + [Unit.Team.PLAYER]:
		var k := keep_of(s)
		if k and k.is_alive() and k.hp / maxf(1.0, k.max_hp) < bv - 0.0001:
			bv = k.hp / maxf(1.0, k.max_hp)
			best = k
	return best


func _tick_phase2(dt: float) -> void:
	var t := mission_time()
	if t >= _walk_next:
		_walk_next = t + 60.0
		walk_target = _weakest_keep()
		if walk_target == keep and fire_once(&"E18"):
			say_l("L30")
	if t >= stagger_until and walk_target and is_instance_valid(walk_target):
		if king.attack_target == null or not is_instance_valid(king.attack_target):
			king.command_attack(walk_target)
	for pct: int in [50, 35]:
		if _king_pct() <= pct and not cracked.has(pct):
			cracked.append(pct)
			stagger_until = t + 8.0
			king.apply_status(&"dazed", 8.0)
			if hud:
				hud.show_message(MSG_STAGGER, 3.0)
			if pct == 50:
				fire_once(&"E9")
				say_l("L17")
			else:
				say_l("L31")
	if t >= _stomp_next and _seat_units_near(king.global_position, STOMP_R).size() >= 3:
		_stomp_next = t + 11.0
		flash_ring(king.global_position, STOMP_R)
		for u: Unit in _seat_units_near(king.global_position, STOMP_R):
			u.take_damage(STOMP_DMG, king)
			if not u is Wizard:
				u.apply_status(&"dazed", 1.0)
	_hurl(dt, 12.0)
	if t >= _lash_next:
		_lash_next = t + CHAIN_LASH_EVERY
		king.apply_status(&"dazed", 3.0)
		flash_ring(king.global_position, 5.0)
		chain_hit(CHAIN_LASH_HIT)
	if t >= _call_next:
		_call_next = t + 25.0
		host_guards([["warden", 4]], king.global_position + Vector3(3.0, 0.0, 3.0), 3.0)
	if t >= _sentinel_next:
		_sentinel_next = t + 75.0
		host_guards([["sentinel", 1]], king.global_position + Vector3(-3.0, 0.0, -3.0), 1.0)
	for s: int in allies():   # the armies near him engage
		if _flat(keep_pos(s), king.global_position) < 40.0 or keep_of(s) == walk_target:
			if ally_busy.get(s, &"") != &"sortie":
				ally_order(s, king.global_position, &"sortie")
		elif ally_busy.get(s, &"") == &"sortie":
			ally_home(s)


func _phase3() -> void:
	if is_ending():
		return
	if phase != 2 or not fire_once(&"E10"):
		return
	phase = 3
	phase_at = mission_time()
	set_objective(&"obj_walk", "done")
	set_objective(&"sec_fed", "done" if fed < FED_LIMIT else "failed")
	set_objective(&"obj_together", "active")
	play_cutscene(&"e8m3_chains", _chains_end)


## e8m3_chains end state (identical on skip): the King kneels at (0, 0), Host near the wards gone, every ward >= 50 %
## and relit, every wizard healed and at its ring, Hush at the Shadow keyhole, the bots on their rings.
func _chains_end() -> void:
	king.command_stop()
	king.global_position = CRACK
	for s: int in SEATS:
		broken.erase(s)
		_chain_look(s, false)
		ward[s] = maxf(float(ward[s]), ward_max * 0.5)
		for u: Unit in host_near(keyhole_of(s), 12.0):
			u.leave_map()
		var w: Wizard = seat_wizard.get(s)
		if w and is_instance_valid(w) and w.is_alive():
			w.heal(w.max_hp)   # review 2026-10-16: the phases come sooner (less essence for draughts); the last act starts whole
			var to := keyhole_of(s) + (keep_pos(s) - keyhole_of(s)).normalized() * 2.0
			w.global_position = to
			w.command_stop()
			w.set_meta(META_HOME, keyhole_of(s))
		if s != Unit.Team.PLAYER:
			ally_order(s, keyhole_of(s) + (keep_pos(s) - keyhole_of(s)).normalized() * 5.0, &"ring")
	var sh := seat_of_kingdom(&"shadow")
	hush = make_unit("hush_story")
	_spawn(hush, sh as Unit.Team, keyhole_of(sh) + Vector3(2.0, 0.0, 0.0))
	mark_scripted(hush)
	hush.set_meta(META_HOME, keyhole_of(sh))
	_guards.append(hush)
	guard_life(hush)
	for id in ["L18", "L19", "L20", "L21"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_TOGETHER, 10.0)
	pulse_next = mission_time() + float(by_difficulty(PULSE_EVERY))
	_call_next = mission_time() + 20.0


func _all_in_rings() -> bool:
	for s: int in SEATS:
		var w: Wizard = seat_wizard.get(s)
		if w == null or not is_instance_valid(w) or not w.is_alive() or w.has_meta(&"kneeling") \
				or _flat(w.global_position, keyhole_of(s)) > RING:
			return false
	return true


func _tick_phase3(dt: float) -> void:
	var t := mission_time()
	var diff := clampi(mission_difficulty, 0, 2)
	for s: int in allies():   # the bots keep to their rings
		var w: Wizard = seat_wizard.get(s)
		if w and w.is_alive() and not w.has_meta(&"kneeling") and _flat(w.global_position, keyhole_of(s)) > RING - 0.8 \
				and not w.has_move_order():
			w.command_move(keyhole_of(s))
	if t < exposed_until:
		return
	if exposed_until > 0.0:
		exposed_until = 0.0
		for s: int in allies():
			ally_order(s, keyhole_of(s) + (keep_pos(s) - keyhole_of(s)).normalized() * 5.0, &"ring")
	if t >= pulse_next:
		pulse_next = t + float(PULSE_EVERY[diff])
		for s: int in SEATS:
			_hurt_ward(s, 40.0)
			flash_ring(keyhole_of(s), 6.0)
		var h := player_helper()
		if turn_fill > 0.0 and (h == null or _flat(h.global_position, hero_pos()) > 8.0):
			turn_fill = 0.0
			if fire_once(&"E12"):
				say_l("L26")
	if t >= turn_ready_at and _all_in_rings():
		turn_fill = minf(TURN_FILL, turn_fill + dt)
		if turn_fill >= TURN_FILL:
			_exposed()
	else:
		turn_fill = 0.0
	_hurl(dt, 10.0, true)
	if t >= _call_next:
		_call_next = t + 30.0   # spec 20 s (tuning)
		_rubble_call(Unit.Team.PLAYER, 4)
		if fire_once(StringName("calls_%d" % int(t / 30.0))):
			for s: int in allies():
				_rubble_call(s, 2)


func _exposed() -> void:
	turns += 1
	turn_fill = 0.0
	var t := mission_time()
	exposed_until = t + EXPOSED
	turn_ready_at = exposed_until + TURN_GAP
	if hud:
		hud.show_message(MSG_OPEN, 3.0)
	flash_ring(CRACK, 8.0)
	pillar(CRACK, Color(1.0, 0.95, 0.75), 14.0, 0.8)
	match turns:
		1:
			fire_once(&"E11a")
			say_l("L22")
		2:
			fire_once(&"E11b")
			say_l("L23")
			say_l("L24")
		3:
			fire_once(&"E11c")
			say_l("L25")
	exposed_until = t + EXPOSED
	king.hp = maxf(1.0, king.hp - LANCE)
	chain_hit(CHAIN_SURGE_HIT)
	for s: int in allies():
		ally_order(s, CRACK, &"sortie")
	if king.hp <= 1.0:
		_check_fall()


func _fall() -> void:
	if is_ending():   # hold_world during a pending lose() would freeze its timer forever
		return
	if not fire_once(&"E14"):
		return
	victory_time = mission_time()
	set_objective(&"obj_together", "done")
	set_objective(&"obj_keys", "done")
	set_objective(&"obj_wizard", "done")
	set_objective(&"obj_keep", "done")
	if objective_state("sec_chains") == "active":
		set_objective(&"sec_chains", "done")
	set_mission_flag("e8m3_time", int(victory_time))
	set_mission_flag("e8m3_turns", turns)
	hold_world(true)
	clear_host()
	win(0.0)


# ---------------------------------------------------------------- wards, chains, the Host

func _hurt_ward(s: int, n: float) -> void:
	if broken.has(s) or n <= 0.0 or is_ending():
		return
	ward[s] = maxf(0.0, float(ward[s]) - n)
	if float(ward[s]) <= 0.0:
		broken[s] = mission_time()
		_chain_look(s, true)
		relight[s] = 0.0
		ever_broken = true
		if objective_state("sec_chains") == "active":
			set_objective(&"sec_chains", "failed")
		if fire_once(&"E6a"):
			say_l("L12")
		if hud:
			hud.show_message(Loc.t(MSG_BROKEN, {"kingdom": Loc.t(String(seat_kind[s]).capitalize()), "limb": Loc.t(String(LIMB[s]))}), 4.0)
		if broken.size() >= 2 and fire_once(&"E16"):
			say_l("L29")
			set_objective(&"obj_keys", "failed")
			lose(DEFEAT_DELAY)


const DEFEAT_DELAY := 3.0


func _tick_wards(dt: float) -> void:
	var t := mission_time()
	for s: int in SEATS:
		var at := keyhole_of(s)
		var near := host_near(at, DRAIN_R)
		if not near.is_empty():
			_hurt_ward(s, DRAIN * near.size() * dt)
		elif not broken.has(s) and host_near(at, 12.0).is_empty():
			var w2: Wizard = seat_wizard.get(s)
			var x2 := 2.0 if w2 and w2.is_alive() and _flat(w2.global_position, at) <= 6.0 else 1.0   # its wizard repairs it
			ward[s] = minf(ward_max, float(ward[s]) + ward_max * MEND * x2 * dt)
		if broken.has(s) and t >= float(broken[s]) + RELIGHT_WAIT:
			var w: Wizard = seat_wizard.get(s)
			if s != Unit.Team.PLAYER and w and w.is_alive() and not w.has_meta(&"kneeling") and not w.has_move_order() \
					and _flat(w.global_position, at) > RING - 0.8:
				w.command_move(at)
			relight[s] = ring_step(w, float(relight[s]), at, RING, RELIGHT, RING_CLEAR, dt)
			if float(relight[s]) >= RELIGHT:
				broken.erase(s)
				_chain_look(s, false)
				ward[s] = ward_max * 0.5
				flash_ring(at, 5.0)
				if s == Unit.Team.PLAYER and fire_once(&"E6b"):
					say_w("L13")
	_tick_mend(dt)
	_tick_ward_warn()


## Ward HP on screen (campaign review 2026-10-16): a ward crossing 50 % / 25 % is called out; re-armed 10 % above.
func _tick_ward_warn() -> void:
	for s: int in SEATS:
		if broken.has(s):
			continue
		var pct := float(ward[s]) / maxf(1.0, ward_max)
		var i := int(ward_warned.get(s, -1))
		if i >= 0 and pct > WARD_WARN[i] + 0.1:
			i -= 1
			ward_warned[s] = i
		var nxt := i + 1
		if nxt < WARD_WARN.size() and pct < WARD_WARN[nxt]:
			ward_warned[s] = nxt
			flash_ring(keyhole_of(s), 5.0)
			if hud:
				hud.show_message(Loc.t(MSG_WARD_LOW, {"kingdom": Loc.t(String(seat_kind[s]).capitalize()),
						"pct": int(100.0 * pct)}), 4.0)


## The ward within MEND_R of the hero (-1 = none).
func _mend_seat() -> int:
	if not hero_alive():
		return -1
	for s: int in SEATS:
		if _flat(hero.global_position, keyhole_of(s)) <= MEND_R:
			return s
	return -1


## Ward Mend: the hero within MEND_R of a Key-Ward, no Host within MEND_R of it, for MEND_CHANNEL s -> +MEND_GAIN of
## its HP (a broken ward past RELIGHT_WAIT: relit at half). Cooldown MEND_COOLDOWN.
func _tick_mend(dt: float) -> void:
	var t := mission_time()
	var s := _mend_seat()
	var useful := s >= 0 and t >= mend_ready_at and ((broken.has(s) and t >= float(broken[s]) + RELIGHT_WAIT) \
			or (not broken.has(s) and float(ward[s]) < ward_max * 0.9))
	if not useful:
		mend_progress = 0.0
		return
	mend_progress = ring_step(hero, mend_progress, keyhole_of(s), MEND_R, MEND_CHANNEL, MEND_R, dt)
	if mend_progress < MEND_CHANNEL:
		return
	mend_progress = 0.0
	mend_ready_at = t + MEND_COOLDOWN
	if broken.has(s):
		broken.erase(s)
		_chain_look(s, false)
		relight[s] = 0.0
		ward[s] = ward_max * 0.5
	else:
		ward[s] = minf(ward_max, float(ward[s]) + ward_max * MEND_GAIN)
	flash_ring(keyhole_of(s), 5.0)
	if hud:
		hud.show_message(Loc.t(MSG_MENDED, {"kingdom": Loc.t(String(seat_kind[s]).capitalize())}), 3.0)


## The Hollow King's own look (tech-artist, HollowKingArt): `KING_ART`'s statics when the file exists (load-guarded,
## never a class_name reference). dress(unit, chain colours) at spawn / load, then one chain per Key-Ward (KING_LIMB).
func _king_art() -> Script:
	if not ResourceLoader.exists(KING_ART):
		return null
	var art := load(KING_ART) as Script
	if art == null:
		return null
	for m: Dictionary in art.get_script_method_list():
		if String(m.get("name", "")) == "dress":
			return art
	return null


func _dress_king() -> void:
	if king == null or not is_instance_valid(king) or king.has_meta(&"_king_dressed"):
		return
	var art := _king_art()
	if art == null:
		return
	var colors := {}
	for st: int in SEATS:
		if seat_kind.has(st):
			colors[KING_LIMB[st]] = MissionE8_02.KINGDOM_COLOR.get(seat_kind[st], Color(1.0, 0.85, 0.45))
	king.set_meta(&"_king_dressed", true)
	art.call(&"dress", king, colors)
	for st: int in SEATS:
		if broken.has(st):
			_chain_look(st, true)


## The King's chain for seat `st`'s Key-Ward: dimmed while the ward is broken (HollowKingArt.set_chain_broken).
func _chain_look(st: int, is_broken: bool) -> void:
	if king == null or not is_instance_valid(king) or not king.has_meta(&"_king_dressed"):
		return
	var art := _king_art()
	if art and art.get_script_method_list().any(func(m: Dictionary) -> bool: return String(m.get("name", "")) == "set_chain_broken"):
		art.call(&"set_chain_broken", king, KING_LIMB[st], is_broken)


## Keystone Hurl: the biggest clump of seat units within 32 m of the King (`at_hero`: the player's wizard), 1.6 s later.
var _hurl_t := 0.0


func _hurl(dt: float, every: float, at_hero := false) -> void:
	_hurl_t -= dt
	if _hurl_t > 0.0:
		return
	_hurl_t = every
	var target := Vector3.INF
	if at_hero and hero_alive():
		target = hero.global_position
	else:
		var best := 0
		for u: Unit in _seat_units_near(king.global_position, 32.0):
			var n := _seat_units_near(u.global_position, HURL_R).size() + (1 if int(u.team) == Unit.Team.PLAYER else 0)
			if n > best:
				best = n
				target = u.global_position
	if target == Vector3.INF:
		return
	flash_ring(target, HURL_R)
	_hurl_at = target
	after(1.6, _hurl_land_pending)   # a named timer: saving stays allowed (review 2026-10-10 #8)


var _hurl_at := Vector3.INF


func _hurl_land_pending() -> void:
	var at := _hurl_at
	_hurl_at = Vector3.INF
	if at != Vector3.INF:
		_hurl_land(at)


func _hurl_land(at: Vector3) -> void:
	if is_ending() or king == null or not is_instance_valid(king):
		return
	var hit := 0
	for u: Unit in _seat_units_near(at, HURL_R):
		u.take_damage(HURL_DMG, king)
		hit += 1
		if hit >= HURL_MAX:
			break


func _seat_units_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and FRAME.has(int(u.team)) and not is_dormant(u) and _flat(u.global_position, at) <= r:
			out.append(u)
	return out


## Rubble Call: `n` Wardens (+ `sentinels`) at the ramp facing seat `s`, on its Key-Ward.
func _rubble_call(s: int, n: int, sentinels := 0) -> void:
	var rows: Array = []
	if n > 0:
		rows.append(["warden", n])
	if sentinels > 0:
		rows.append(["sentinel", sentinels])
	if rows.is_empty():
		return
	host_wave(rows, keyhole_of(s) * 0.55, [], keyhole_of(s))


func _on_any_unit_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or is_ending() or phase != 2 or not FRAME.has(int(unit.team)) or king == null:
		return
	if _flat(unit.global_position, king.global_position) <= FEED_R:
		king.hp = minf(king.max_hp, king.hp + FEED_HP)
		fed += FEED_HP


func _on_player_hero_fell() -> void:
	fire_once(&"E15")
	say_w("L28")
	set_objective(&"obj_wizard", "failed")
	super()


## Load (review 2026-10-10 #3): the King's gates and guard (kept by a matched King, re-made on a respawned one) and
## Hush's guard (set by _chains_end, mid-mission).
func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	if king and is_instance_valid(king):
		if not king.damage_taken.is_connected(_on_king_hit):
			king.damage_taken.connect(_on_king_hit)
		king.death_guard = _king_guard
		_dress_king()
	if hush and is_instance_valid(hush):
		guard_life(hush)


func save_block_reason() -> String:
	if has_fired(&"E14"):
		return SAVE_REASON_SCRIPTED
	return super()


## Boss music (music.md 4, MissionBase._boss_fight_active): from phase 1 (the King stands, boss bar) to his fall (E14).
func _boss_fight_active() -> bool:
	return phase >= 1 and not has_fired(&"E14") and king != null and is_instance_valid(king)


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
	if king and is_instance_valid(king) and phase != 2:
		king.apply_status(&"rooted", 1.0)
		if phase != 0 and _flat(king.global_position, CRACK) > 2.0 and phase == 3:
			king.global_position = CRACK
	match phase:
		0:
			_tick_phase0()
		1:
			_tick_phase1(0.5)
		2:
			_tick_phase2(0.5)
		3:
			_tick_phase3(0.5)
	_tick_wards(0.5)
	tick_allies(0.5)
	keep_key_relic()
	if phase == 3 and player_helper() == null and fire_once(&"E13"):
		say_l("L27")
	objectives_changed.emit()
	if hud and mission_hud == null:
		hud.set_objective(_objective_text())
