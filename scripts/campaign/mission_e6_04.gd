class_name MissionE6_04
extends MissionE6Base
## Episode 6, mission 4 "The First Crack" (docs/design/mission-e6-04.md): twelve years ago the lock under Crown Hollow
## fails for the first time. The Master kneels on the Throne stone and holds the crack shut while Ysolde (the player,
## south-west) and Torvald (ALLY bot, north-east) hold the isle against the Hollow Host. Every soldier who dies near
## the isle weakens the seal ("the Hollow counts"). At 100 % he says it cannot be held from up here, and goes down.
## Spotlight: the Wildwood Archer (the First Crack).
##
## Built deviations (2026-10-09, from the spec):
## - Crown Hollow twelve years ago is the main.gd generator look (120 x 120) with the spec table's positions; no
##   crown_hollow.map layout, no river / moat / crossings (the Host walks straight at the stone; the moat rises come up at
##   the NW / SE Steps marks), no Lost Caches. The isle is 8 pillar obstacles on a ring r 8 and a flagstone disc.
## - The seal is an E6Target at (0, 0) (4 000 HP, mends 3 / s with no enemy within 12 m), the Master a placeholder
##   figure; the hold pauses while an ENEMY unit is within 6 m of (0, 0).
## - The Stronghold opens at 3:30 by raising TierSystem.max_tier from 1 to 2 (the keep's card shows no tier step before).
## - Torvald is the ALLY seat (activate_seat + a Commander on an Ice profile, 9 / 9 / 7 soldiers, never attacks); the
##   spec's pushes are mission orders on his army (40 % wg_e, 50 % half to the isle 60 s, 70 % wg_s, 90 % all on the isle).

const MISSION_ID := &"e6m4"
const MISSION_TITLE := "The First Crack"
const MAP_SEED := 1604

const PLAYER_SEAT := Unit.Team.PLAYER
const ALLY_SEAT := Teams.ALLY
const YSOLDE_START := Vector3(-36.0, 0.0, 36.0)
const KEEP_POS := Vector3(-43.0, 0.0, 43.0)
const HALL_POS := Vector3(-27.0, 0.0, 45.0)
const SPIRE_POS := Vector3(-37.0, 0.0, 29.0)
const HOLLOWS: Array[Vector3] = [Vector3(-50.0, 0.0, 46.0), Vector3(-50.0, 0.0, 52.0)]
const ARMY_START := Vector3(-30.0, 0.0, 30.0)
const NODES := [[&"e6c_a", Vector3(-46.0, 0.0, 34.0), 1500], [&"e6c_b", Vector3(-34.0, 0.0, 46.0), 1500],
		[&"e6c_mid", Vector3(-16.0, 0.0, 6.0), 2000], [&"e6c_rich", Vector3(-40.0, 0.0, -40.0), 2000]]
const ALLY_NODES := [[&"e6t_a", Vector3(46.0, 0.0, -34.0), 1500], [&"e6t_b", Vector3(34.0, 0.0, -46.0), 1500],
		[&"e6t_mid", Vector3(16.0, 0.0, -6.0), 2000], [&"e6t_rich", Vector3(40.0, 0.0, 40.0), 2000]]
const MID_HALL_SPOT := Vector3(-23.0, 0.0, 9.0)
const TORVALD_KEEP := Vector3(43.0, 0.0, -43.0)
const TORVALD_HALL := Vector3(27.0, 0.0, -45.0)
const TORVALD_SPIRE := Vector3(37.0, 0.0, -29.0)
const TORVALD_LODGES: Array[Vector3] = [Vector3(50.0, 0.0, -46.0), Vector3(50.0, 0.0, -52.0)]
const TORVALD_START := Vector3(36.0, 0.0, -36.0)
const TORVALD_RALLY := Vector3(30.0, 0.0, -30.0)
const STONE := Vector3.ZERO
const ISLE_R := 8.0
const STEPS := {&"nw": Vector3(-9.02, 0.0, -9.02), &"se": Vector3(9.02, 0.0, 9.02)}
const BRIDGES := {&"w": Vector3(-9.02, 0.0, 9.02), &"e": Vector3(9.02, 0.0, -9.02)}
## Warden Gates [position, bank, first column (s)].
const WGATES := {&"wg_n": [Vector3(-26.0, 0.0, -54.0), &"west", 120.0], &"wg_w": [Vector3(-53.0, 0.0, 13.0), &"west", 165.0],
		&"wg_s": [Vector3(26.0, 0.0, 54.0), &"east", 120.0], &"wg_e": [Vector3(53.0, 0.0, -13.0), &"east", 165.0]}

const HOLD_FROM := 60.0
const HOLD_LEN: Array[float] = [720.0, 960.0, 1080.0]
const PAUSE_R := 6.0
const COUNT_R := 25.0
const COUNT_COST: Array[float] = [10.0, 15.0, 20.0]
const SEAL_HP: Array[float] = [5000.0, 4000.0, 3200.0]
const SEAL_MEND: Array[float] = [5.0, 3.0, 2.0]
const MEND_CLEAR_R := 12.0
const COLUMN_EVERY := 90.0
const RISE_FIRST := 240.0
const RISE_EVERY := 180.0
const STRONGHOLD_AT := 210.0
const TORVALD_SOLDIERS: Array[int] = [11, 9, 7]
const TORVALD_PUSH_ISLE := 60.0
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [500, 400, 300]
const LEVEL_CAP := 7
const DEFEAT_DELAY := 3.0
const TORVALD_SPELLS: Array[StringName] = [&"rime_bolt", &"flash_freeze", &"rime_bolt", &"flash_freeze", &"rime_aegis"]

const SPEAKER_COLORS := {&"ysolde": Color(0.55, 0.90, 0.35), &"torvald": Color(0.55, 0.80, 1.00),
		&"master": Color(0.95, 0.93, 0.85), &"obren": Color(1.0, 0.80, 0.25), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"ysolde": "Ysolde", &"torvald": "Torvald", &"master": "The Master", &"obren": "Obren",
		&"narrator": "Narrator"}
## The spec's 27 lines (data/voice/lines/e6m4.json): LINE_IDS[n - 1] = id of line n.
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13", "L14", "L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25", "L26", "L27"]
const DIALOGUE := [
	[&"narrator", "Twelve years ago. The Master sent for two of his four. Only two."],
	[&"master", "Ysolde. Torvald. Hold the isle. Whatever climbs out of the water must not touch this stone."],
	[&"torvald", "What is under it?"],
	[&"master", "My first mistake. His name was Obren."],
	[&"ysolde", "Should we send for Vessa and Malrik?"],
	[&"master", "Vessa would burn it open to see inside. Malrik would ask what it pays. No."],
	[&"torvald", "Something under the isle is counting. Every one that falls, it counts."],
	[&"obren", "Master. You came yourself. I am honoured. Kneel a little longer."],
	[&"narrator", "Then the isle split, and the amber came up through the stones."],
	[&"ysolde", "Torvald! It's breaking on our side!"],
	[&"torvald", "Then I am on your side. Hold."],
	[&"master", "It will not hold from up here. Not for long."],
	[&"obren", "Come down, old man. Hold my door yourself. Learn how long a year is in the dark."],
	[&"ysolde", "Master. You can't go down there."],
	[&"master", "Someone must. I have always been the one who must."],
	[&"obren", "A wood-girl, a snowman and a tired old man. I can wait. Stone is patient."],
	[&"master", "Listen, both of you. Tell no one what sleeps here. If the world knows, the world will dig."],
	[&"master", "My regalia are its keys. When I go, they will scatter. Never let them sit in one hand."],
	[&"master", "Ysolde, my heart: keep growing things. Torvald, my patience: wait for me."],
	[&"torvald", "How long?"],
	[&"master", "Not too long."],
	[&"narrator", "He went down that same night, to hold the door from below. He never said for how long."],
	[&"master", "The seal! Keep them off the stone!"],
	[&"ysolde", "Master... forgive me..."],
	[&"obren", "Open. At last, open."],
	[&"ysolde", "That gate is closed. Roots don't forget."],
	[&"torvald", "One fewer door. Keep yours shut, Ysolde."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Twelve years ago. For eighty-eight years nothing under Crown Hollow had stirred. Then, on the first warm night of spring, the isle cracked, and amber light came up through the stones like water through ice.",
	"The Master sent for two of his four apprentices, and only two: Ysolde from the west, Torvald from the north. When they arrived he was already on his knees at the old throne-stone, both hands pressed to the crack.",
	"Something is climbing out of the moat. Hold the isle, both banks and both bridges, until the crack is shut. Do not let anything touch the stone.",
]
const HINT_START := "Keep every enemy out of the white circle around the Master: the crack only closes while it is clear. Your bank is the west."
const HINT_COUNTS := "The Hollow counts the dead: every soldier who falls near the isle weakens the seal."
const HINT_STRONGHOLD := "Your Heartwood can become a Stronghold: select it and press X (200 crystals). It opens Vinelasher, Greenheart Oathkeeper (Grove Hall) and the Bramblesage (Keep)."
const HINT_SAGE := "Bramblesage: Z Snagroot drags one enemy 7 m toward it: pull Wardens out of the Master's circle. The Host is all melee: Pollen Haze has nothing to blind here."
const MSG_TORVALD_FELL := "Torvald falls back to the north shore"

## Read only.
var seal: E6Target
var torvald: Wizard
var wgates := {}                         ## id -> WardenGate
var hold := 0.0                          ## 0-1
var hold_paused := false
var counted := 0                         ## deaths the Hollow counted
var seal_min := 1.0
var west_broken := 0
var east_broken := 0
var waves_fired: Array[String] = []
var crack_units: Array = []
var victory_time := -1.0
var pause_time := 0.0                    ## seconds the hold spent paused (after HOLD_FROM)

var _tick := 0.0
var _fast := 0.0
var _next_column := {}
var _next_rise := RISE_FIRST
var _push := {}                          # {"target": Node3D or Vector3, "until": time, "units": Array}
var _ally_cmd: Node


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"nature"
	enemy_kingdom = &"shadow"
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_hold", "primary"], [&"obj_seal", "primary"], [&"obj_ysolde", "primary"],
			[&"obj_keep", "primary"], [&"sec_gates", "secondary"], [&"sec_unbroken", "secondary"]])
	make_breakers("", "", 0.0)


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE6Base.e6_config(c, 2)
	c.casters_enabled = true
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Heartwood has fallen."
	c.start_tiers = {ALLY_SEAT: 2}
	c.start_level = 4
	c.start_spells = [&"thornburst", &"wild_bloom", &"thornburst"]
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe crack is shut"
	c.defeat_banner = "DEFEAT"
	c.seat_sides = {PLAYER_SEAT: 0, ALLY_SEAT: 0, Unit.Team.ENEMY: 1}
	c.seat_opponents = {PLAYER_SEAT: Unit.Team.ENEMY, ALLY_SEAT: Unit.Team.ENEMY}
	c.seat_kingdoms = {PLAYER_SEAT: &"nature", ALLY_SEAT: &"ice"}
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"wildwood_archer", "trigger": &"manual", "key_hint": "Grove Hall: B",
			"card": "Wildwood Archer. The long bow of the wood: behind a wall of shields, nothing slow comes through."}
	return c


func _map_size() -> Vector2:
	return Vector2(120.0, 120.0)


func _player_start() -> Vector3:
	return YSOLDE_START


func _lighting_preset() -> StringName:
	return &"warm"


func _title_line() -> String:
	return "Episode 6, Mission 4: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(KEEP_POS.x, KEEP_POS.z, 12.0, 0.0), Vector4(TORVALD_KEEP.x, TORVALD_KEEP.z, 12.0, 0.0),
			Vector4(0.0, 0.0, ISLE_R + 2.0, 1.0)]


func _ready() -> void:
	super()
	tint_light(Color(1.0, 0.78, 0.55), 0.85, -14.0, Color(0.66, 0.56, 0.58), Color(0.30, 0.28, 0.46), Color(0.96, 0.62, 0.42))
	if tier_system:
		tier_system.max_tier = 1   # the Stronghold opens at 3:30
	if camera_rig:
		camera_rig.focus_on(YSOLDE_START)
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)


# ---------------------------------------------------------------- seats

func start_position(team: int) -> Vector3:
	return TORVALD_START if team == ALLY_SEAT else YSOLDE_START


func base_center(team: int) -> Vector3:
	return TORVALD_KEEP if team == ALLY_SEAT else KEEP_POS


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	if k:
		return k.spawn_point()
	return base_center(team) + Vector3(4.0, 0.0, 4.0)


func node_of(team: int, suffix: String) -> CrystalNode:
	var prefix := "e6t_" if team == ALLY_SEAT else "e6c_"
	var v: Variant = crystal_nodes.get(StringName(prefix + suffix))
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


## Commander (MT2 contract): a Crown Hollow point mirrored into this seat's base.
func bot_point(team: int, p: Vector3) -> Vector3:
	return p if team == Unit.Team.ENEMY else -p


func bot_vector(team: int, v: Vector3) -> Vector3:
	return v if team == Unit.Team.ENEMY else -v


func natural_hall_spot(team: int) -> Vector3:
	return -MID_HALL_SPOT if team == ALLY_SEAT else MID_HALL_SPOT


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


func seat_profile(seat: int) -> AIProfile:
	var diff := clampi(mission_difficulty, 0, 2)
	var p := MissionBase.frozen_ice_profile(diff)
	p.id = &"mission_e6_04_ally"
	p.profile_id = p.id
	p.min_attack_pop = 99
	p.launch_attacks = false
	p.attack_full_pop = 0
	p.first_attack_by = 0.0
	p.worker_target_home = 6
	p.worker_target_expanded = 6
	p.worker_target_x2 = 6
	p.second_expansion = false
	p.expand_time = 1.0e6
	p.max_soldiers = int(TORVALD_SOLDIERS[diff])
	p.rebuild = false
	p.hero_stays_home = true
	p.malrik_joins = AIProfile.MalrikJoins.NEVER
	p.champion_max = 0
	p.trade = false
	p.map_fill = false
	if seat != ALLY_SEAT:
		p.item_build = PackedStringArray()
	return p


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	var clearings: Array = [[YSOLDE_START, 8.0], [KEEP_POS, 18.0], [TORVALD_KEEP, 18.0], [STONE, 14.0],
			[MID_HALL_SPOT, 5.0], [-MID_HALL_SPOT, 5.0], [ARMY_START, 6.0], [TORVALD_RALLY, 6.0]]
	for row: Array in NODES + ALLY_NODES:
		clearings.append([row[1], 7.0])
	for id: StringName in WGATES:
		clearings.append([WGATES[id][0], 7.0])
	var lanes: Array = []
	for id: StringName in WGATES:
		lanes.append([WGATES[id][0], STONE, 4.0])
	lanes.append([KEEP_POS, STONE, 5.0])
	lanes.append([TORVALD_KEEP, STONE, 5.0])
	scatter_props(MAP_SEED, clearings, lanes, 10, 18)
	for i in 8:   # the 8 whole pillars of Crown Isle
		var a := TAU * float(i) / 8.0 + TAU / 16.0
		var shape := CylinderShape3D.new()
		shape.radius = 0.7
		shape.height = 4.0
		var body := _static_obstacle(Vector3(cos(a) * ISLE_R, 0.0, sin(a) * ISLE_R), shape, 2.0)
		body.add_to_group(&"navigation_geometry")
		if not _SIM.enabled:
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.55
			cyl.bottom_radius = 0.7
			cyl.height = 4.0
			_mesh(body, cyl, Color(0.72, 0.70, 0.66), 2.0)
	ground_disc(STONE, ISLE_R + 1.5, Color(0.62, 0.60, 0.56, 0.85))
	ground_disc(STONE, PAUSE_R, Color(1.0, 0.95, 0.75, 0.35), 0.05)
	box_prop(STONE + Vector3(0.0, 0.0, 1.6), Vector3(0.9, 1.5, 0.9), Color(0.95, 0.93, 0.85))   # the Master, kneeling
	for row: Array in NODES + ALLY_NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_grid.spawn_complete(BuildingType.find("nature_keep"), KEEP_POS, PLAYER_SEAT) as Keep
	if keep:
		keep.name = "Heartwood"
		seat_keeps[PLAYER_SEAT] = keep
	seat_bases[PLAYER_SEAT] = KEEP_POS
	seat_starts[PLAYER_SEAT] = YSOLDE_START
	build_grid.spawn_complete(BuildingType.find("nature_barracks"), HALL_POS, PLAYER_SEAT)
	build_grid.spawn_complete(BuildingType.find("nature_tower"), SPIRE_POS, PLAYER_SEAT)
	for p in HOLLOWS:
		build_grid.spawn_complete(BuildingType.find("nature_hollow"), p, PLAYER_SEAT)
	var rk := build_grid.spawn_complete(BuildingType.find("ice_keep"), TORVALD_KEEP, ALLY_SEAT) as Keep
	if rk:
		rk.name = "RimeKeep"
		seat_keeps[ALLY_SEAT] = rk
	seat_bases[ALLY_SEAT] = TORVALD_KEEP
	seat_starts[ALLY_SEAT] = TORVALD_START
	build_grid.spawn_complete(BuildingType.find("ice_barracks"), TORVALD_HALL, ALLY_SEAT)
	build_grid.spawn_complete(BuildingType.find("ice_tower"), TORVALD_SPIRE, ALLY_SEAT)
	for p in TORVALD_LODGES:
		build_grid.spawn_complete(BuildingType.find("ice_lodge"), p, ALLY_SEAT)
	var diff := clampi(mission_difficulty, 0, 2)
	seal = add_target(STONE, float(SEAL_HP[diff]), float(SEAL_MEND[diff]), _seal_mends, "The seal", false)
	if not _SIM.enabled:
		box_prop(STONE, Vector3(3.2, 0.8, 3.2), Color(0.48, 0.46, 0.44))   # the Throne stone
	for id: StringName in WGATES:
		var g := add_warden_gate(id, WGATES[id][0], STONE, 1800.0, 0.0, Callable())
		g.gate_down.connect(_on_wgate_down)
		wgates[id] = g


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for team: int in [PLAYER_SEAT, ALLY_SEAT]:
		for p: Vector3 in [STONE, STEPS[&"nw"], STEPS[&"se"], BRIDGES[&"w"], BRIDGES[&"e"]]:
			fog.reveal(team, p, 8.0)
	_setup_champions()
	hero = _make_wizard(PLAYER_SEAT)
	_spawn(hero, PLAYER_SEAT, YSOLDE_START)
	_claim_wizard(hero, PLAYER_SEAT)
	ItemDrops.ensure_inventory(hero)
	for i in 6:
		var w := _spawn(make_unit("sprigling"), PLAYER_SEAT, KEEP_POS + Vector3(4.0 + i * 1.2, 0.0, -4.0))
		w.call(&"command_gather", node_of(PLAYER_SEAT, "a" if i < 3 else "b"))
	var army := [["thornling", 8 + (2 if diff == 0 else 0)], ["burr_slinger", 4], ["bloomtender", 2],
			["bramblehorn", 0 if diff == 2 else 1]]
	var k := 0
	for row: Array in army:
		for j in int(row[1]):
			_spawn(make_unit(String(row[0])), PLAYER_SEAT, ARMY_START + Vector3((k % 5) * 1.6 - 3.2, 0.0, (k / 5) * 1.7))
			k += 1
	var ice := activate_seat(ALLY_SEAT, &"ice", {"crystals": 400,
			"workers": [["rime_hauler", 3, node_of(ALLY_SEAT, "a")], ["rime_hauler", 3, node_of(ALLY_SEAT, "b")]],
			"units": [["rimeshield", 6, TORVALD_RALLY], ["shardcaster", 3, TORVALD_RALLY], ["frostbow", 2, TORVALD_RALLY],
					["rime_colossus", 1, TORVALD_RALLY], ["rimecarver", 1, TORVALD_RALLY]],
			"wizard": {"level": 5, "spells": TORVALD_SPELLS, "pos": TORVALD_START}})
	torvald = ice.get("wizard") as Wizard
	if torvald:
		torvald.died.connect(_on_torvald_died)
	_ally_cmd = _add_seat_commander(ALLY_SEAT)
	seal.melted.connect(_on_seal_broken)
	for id: StringName in WGATES:
		_next_column[id] = float(WGATES[id][2])
	begin_mission([&"obj_hold", &"obj_seal", &"obj_ysolde", &"obj_keep", &"sec_gates", &"sec_unbroken"])
	selection.select_units([hero])


func _add_seat_commander(seat: int) -> Node:
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return null
	var bot: Node = script.new()
	bot.name = "Bot%d" % seat
	bot.set(&"team", seat)
	bot.set(&"profile", seat_profile(seat))
	add_child(bot)
	commanders.append(bot)
	return bot


func _intro() -> void:
	fire_once(&"E1")
	_place_pair(Vector3(-14.0, 0.0, 14.0), Vector3(14.0, 0.0, -14.0))
	play_cutscene(&"e6m4_crack", _crack_end)


func _place_pair(y_at: Vector3, t_at: Vector3) -> void:
	if hero_alive():
		hero.global_position = y_at
		hero.command_stop()
	if torvald and is_instance_valid(torvald) and torvald.is_alive():
		torvald.global_position = t_at
		torvald.command_stop()


## e6m4_crack end state: Ysolde (-30, 30), Torvald (30, -30), L1-L6 once, the first hint.
func _crack_end() -> void:
	_place_pair(Vector3(-30.0, 0.0, 30.0), Vector3(30.0, 0.0, -30.0))
	for id in ["L1", "L2", "L3", "L4", "L5", "L6"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 10.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_hold", false), objective_text(&"obj_seal", false)],
		"rule": Loc.sink(objective_text(&"obj_ysolde")),
	}


func hold_length() -> float:
	return float(by_difficulty(HOLD_LEN))


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_hold":
			if not with_counter:
				return "The Master holds the crack"
			if hold_paused:
				return "The Master holds the crack: %d %% (paused)" % int(floor(hold * 100.0))
			return "The Master holds the crack: %d %%" % int(floor(hold * 100.0))
		&"obj_seal":
			if with_counter and seal:
				return "Nothing may break the seal (%d %%)" % int(round(seal.ratio() * 100.0))
			return "Nothing may break the seal"
		&"obj_ysolde":
			return "Ysolde must survive"
		&"obj_keep":
			return "The Heartwood must stand"
		&"sec_gates":
			if with_counter:
				return "Break the Warden Gates on your bank (%d / 2)" % west_broken
			return "Break the Warden Gates on your bank"
		&"sec_unbroken":
			return "Keep the seal above half"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_hold":
			return {"counter": int(floor(hold * 100.0)), "goal": 100}
		&"obj_seal":
			if seal:
				return {"counter": int(seal.hp), "goal": int(seal.max_hp)}
		&"sec_gates":
			var pos: Array = []
			for gid: StringName in [&"wg_n", &"wg_w"]:
				if (wgates[gid] as WardenGate).is_alive():
					pos.append((wgates[gid] as Node3D).global_position)
			return {"counter": west_broken, "goal": 2, "positions": pos}
	return {}


# ---------------------------------------------------------------- the seal, the hold, the Hollow counts

func _seal_mends() -> bool:
	return enemies_near(STONE, MEND_CLEAR_R) == 0


func _on_seal_broken(_h: Heartfrost) -> void:
	if is_ending():
		return
	fire_once(&"E15")
	say_l("L25")
	set_objective(&"obj_seal", "failed")
	lose(DEFEAT_DELAY)


## The Hollow counts: a death in "units" within 25 m of the stone costs the seal (not the Host, not Saplings, not
## while a scene holds the world).
func _on_any_unit_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or seal == null or is_ending() or world_is_held or not match_started:
		return
	if int(unit.team) == Unit.Team.ENEMY or unit.unit_type == null or unit.unit_type.id == &"sapling":
		return
	if _flat(unit.global_position, STONE) > COUNT_R:
		return
	counted += 1
	seal.drain(float(by_difficulty(COUNT_COST)))
	if fire_once(&"E2"):
		say_l("L7")
		if hud:
			hud.show_message(HINT_COUNTS, 8.0)


func _tick_hold(dt: float) -> void:
	if mission_time() < HOLD_FROM or hold >= 1.0:
		return
	hold_paused = enemies_near(STONE, PAUSE_R) > 0
	if hold_paused:
		pause_time += dt
		return
	var before := hold
	hold = minf(1.0, hold + dt / hold_length())
	if before < 0.25 and hold >= 0.25 and fire_once(&"E4"):
		say_l("L8")
	if before < 0.4 and hold >= 0.4:
		_torvald_push(wgates[&"wg_e"], 120.0)
	if before < 0.5 and hold >= 0.5:
		_first_crack()
	if before < 0.7 and hold >= 0.7:
		_torvald_push(wgates[&"wg_s"], 120.0)
	if before < 0.75 and hold >= 0.75:
		_deep_calls()
	if before < 0.9 and hold >= 0.9:
		_last_rise()
	if hold >= 1.0:
		_hold_done()


func _tick_seal() -> void:
	if seal == null:
		return
	seal_min = minf(seal_min, seal.ratio())
	if seal_min < 0.5 and objective_state("sec_unbroken") == "active":
		set_objective(&"sec_unbroken", "failed")
	if seal.ratio() < 0.25 and fire_once(&"E12"):
		say_l("L23")


# ---------------------------------------------------------------- the Host

func _column(gid: StringName, extra_breaker := false) -> void:
	var g := wgates[gid] as WardenGate
	if not g.is_alive():
		return
	var rows: Array = [[WARDEN_ID, 3]]
	if extra_breaker:
		rows.append([BREAKER_ID, 1])
	wave(rows, g.front_point(), &"stone", STONE)


func _tick_host() -> void:
	var t := mission_time()
	for gid: StringName in _next_column:
		if t >= float(_next_column[gid]):
			_next_column[gid] = t + COLUMN_EVERY
			_column(gid)
	if t >= _next_rise:
		_next_rise = t + RISE_EVERY
		waves_fired.append("rise")
		for s: StringName in STEPS:
			wave([[WARDEN_ID, 4]], STEPS[s], &"stone", STONE)
	if t >= STRONGHOLD_AT and fire_once(&"E3"):
		if tier_system:
			tier_system.max_tier = 2
		if hud:
			hud.show_message(HINT_STRONGHOLD, 12.0)


## E6: 50 %: e6m4_first_crack, then 2 Breakers + 6 Wardens inside the pillar ring; Torvald's half-army to the isle.
func _first_crack() -> void:
	if not fire_once(&"E6"):
		return
	waves_fired.append("first_crack")
	play_cutscene(&"e6m4_first_crack", _first_crack_end)


func _first_crack_end() -> void:
	for id in ["L9", "L10", "L11"]:
		say_l(id)
	var rows: Array = [[BREAKER_ID, 2], [WARDEN_ID, 6]]
	var types: Array[String] = []
	for row: Array in rows:
		for i in scaled(int(row[1]), String(row[0])):
			types.append(String(row[0]))
	crack_units.clear()
	for i in types.size():
		var a := TAU * float(i) / float(types.size())
		var u := make_unit(types[i])
		_spawn(u, Unit.Team.ENEMY, STONE + Vector3(cos(a) * PAUSE_R, 0.0, sin(a) * PAUSE_R))
		arm_enemy(u)
		order_wave(u, &"stone", STONE)
		crack_units.append(u)
	show_spotlight()
	_torvald_push(STONE + Vector3(5.0, 0.0, -5.0), TORVALD_PUSH_ISLE, 0.5)


## E10: 75 %: each living gate sends one more column with a Breaker.
func _deep_calls() -> void:
	if not fire_once(&"E10"):
		return
	waves_fired.append("deep_calls")
	for id in ["L13", "L14", "L15"]:
		say_l(id)
	for gid: StringName in wgates:
		_column(gid, true)


## E11: 90 %: a Breaker + 5 Wardens at each Steps; Torvald's whole army holds the isle's east half.
func _last_rise() -> void:
	if not fire_once(&"E11"):
		return
	waves_fired.append("last_rise")
	say_l("L16")
	for s: StringName in STEPS:
		wave([[BREAKER_ID, 1], [WARDEN_ID, 5]], STEPS[s], &"stone", STONE)
	_torvald_push(STONE + Vector3(5.0, 0.0, -5.0), 9999.0)


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	if mode != &"stone":
		return false
	if seal == null or not seal.is_alive():
		return false
	if u.attack_target == null:
		if _flat(u.global_position, STONE) < 7.0:
			u.command_attack(seal)
		elif not u.is_attack_moving():
			u.command_attack_move(STONE)
	return true


func _on_wgate_down(g: WardenGate) -> void:
	if WGATES[g.gate_id][1] == &"west":
		west_broken += 1
		if not is_ending():
			if fire_once(&"E8"):
				say_l("L26")
			set_objective(&"sec_gates", "done" if west_broken >= 2 else "active")
	else:
		east_broken += 1
		if not is_ending() and fire_once(&"E9"):
			say_l("L27")


# ---------------------------------------------------------------- Torvald, the ally

func ally_army() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ALLY_SEAT and not u.is_worker() and not u is Wizard:
			out.append(u)
	return out


## Orders `share` of Torvald's army (by count) onto `target` (a WardenGate or a point) for `seconds`.
func _torvald_push(target: Variant, seconds: float, share := 1.0) -> void:
	var army := ally_army()
	var n := int(ceil(float(army.size()) * share))
	_push = {"target": target, "until": mission_time() + seconds, "units": army.slice(0, n)}
	_refresh_push()


func _refresh_push() -> void:
	if _push.is_empty():
		return
	var units: Array = (_push["units"] as Array).filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	var target: Variant = _push["target"]
	var done := mission_time() >= float(_push["until"]) or units.size() < 3
	if target is WardenGate and not (target as WardenGate).is_alive():
		done = true
	if done:
		for v: Variant in units:
			(v as Unit).command_move(TORVALD_RALLY)
		_push = {}
		return
	_push["units"] = units
	for v: Variant in units:
		var u := v as Unit
		if u.attack_target != null and u.attack_target is Unit:
			continue
		if target is WardenGate:
			var g := target as WardenGate
			if _flat(u.global_position, g.global_position) < 10.0:
				u.command_attack(g)
			elif not u.is_attack_moving():
				u.command_attack_move(g.global_position)
		elif not u.is_attack_moving() and _flat(u.global_position, target as Vector3) > 5.0:
			u.command_attack_move(target as Vector3)


## C5-1: Torvald is a 2v2 wizard: he comes back at his keep (Skirmish's respawn timer, never a loss).
func _on_torvald_died(_u: Unit) -> void:
	if is_ending():
		return
	_respawn_left[ALLY_SEAT] = next_respawn_delay(ALLY_SEAT)
	_deaths[ALLY_SEAT] = int(_deaths.get(ALLY_SEAT, 0)) + 1
	if hud:
		hud.show_message(MSG_TORVALD_FELL, 4.0)


# ---------------------------------------------------------------- the end

## E13: 100 %: e6m4_down, every Host unit crumbles, victory; StoryFlow plays ep6_ending.
func _hold_done() -> void:
	if is_ending() or not fire_once(&"E13"):
		return
	victory_time = mission_time()
	set_objective(&"obj_hold", "done")
	if objective_state("sec_unbroken") == "active":
		set_objective(&"sec_unbroken", "done")
	if objective_state("sec_gates") == "active":
		set_objective(&"sec_gates", "failed")
	set_mission_flag("e6m4_time", int(victory_time))
	set_mission_flag("e6m4_counted", counted)
	crumble_enemies()
	_place_pair(Vector3(-4.0, 0.0, 5.0), Vector3(4.0, 0.0, -5.0))
	play_cutscene(&"e6m4_down", _down_end)


func _down_end() -> void:
	for id in ["L17", "L18", "L19", "L20", "L21", "L22"]:
		say_l(id)
	set_objective(&"obj_seal", "done")
	set_objective(&"obj_ysolde", "done")
	set_objective(&"obj_keep", "done")
	win(1.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E14")
	say_l("L24")
	set_objective(&"obj_ysolde", "failed")
	super()


func _tick_events() -> void:
	if fire_once_sage():
		if hud:
			hud.show_message(HINT_SAGE, 12.0)


## E5: the first Bramblesage.
func fire_once_sage() -> bool:
	if has_fired(&"E5"):
		return false
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == PLAYER_SEAT and u.unit_type and u.unit_type.id == &"bramblesage":
			return fire_once(&"E5")
	return false


# ---------------------------------------------------------------- save / load

func save_state(ids: Dictionary = {}) -> Dictionary:
	var d := super(ids)
	if seal:
		d["seal_hp"] = seal.hp
	if not _push.is_empty():
		var target: Variant = _push["target"]
		var units: Variant = SaveCodec.encode(_push["units"], ids)
		d["e6m4_push"] = {"gate": String((target as WardenGate).gate_id) if target is WardenGate else "",
				"pos": target if target is Vector3 else Vector3.ZERO, "until": float(_push["until"]),
				"units": units if not SaveCodec.is_skip(units) else []}
	return d


## The rebuilt mission gets back the seal's HP, the tier cap and the ally's death hook.
func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	if seal and d.has("seal_hp"):
		seal.hp = float(d["seal_hp"])
	if tier_system:
		tier_system.max_tier = 2 if has_fired(&"E3") else 1
	_push = _load_push(d.get("e6m4_push", {}), nodes)


## C5-10: Torvald's push / hold order back from its save row (a gate by id, a point; {} = none).
func _load_push(row: Dictionary, nodes: Dictionary) -> Dictionary:
	if row.is_empty():
		return {}
	var target: Variant = row.get("pos", Vector3.ZERO)
	var gate_id := String(row.get("gate", ""))
	if gate_id != "":
		target = wgates.get(StringName(gate_id))
		if not target is WardenGate:
			return {}
	var units: Array = []
	for v: Variant in SaveCodec.decode(row.get("units", []), nodes) as Array:
		if v is Unit and is_instance_valid(v):
			units.append(v)
	return {"target": target, "until": float(row.get("until", 0.0)), "units": units}


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held or save_restoring:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_fast -= delta
	if _fast <= 0.0:
		_fast = 0.25
		_tick_hold(0.25)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_host()
		_tick_seal()
		_tick_events()
		_refresh_push()
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())
