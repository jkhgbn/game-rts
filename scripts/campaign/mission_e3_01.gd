class_name MissionE3_01
extends MissionBase
## Episode 3, mission 1 "Take the Ford" (docs/design/mission-e3-01.md): the first Shadow mission. A 2v2 on Evenmead:
## PLAYER Malrik (Shadow, north-west) + ALLY Torvald (Ice bot, north-east) vs ENEMY Ysolde (Nature, Lark Hill west) +
## ENEMY_2 Vessa (Fire, Lark Hill east). Take the Stone Ford (60 s of side-0 presence), then the three standards at the
## foot of Lark Hill, then hold all three for 2:00. Mother Hush walks with Malrik (story unit); the Keystone Shard
## whispers (Heartbeat mana). Spotlight: the Gloom Deacon (Umbral Passage carries a squad over the river).
##
## Built deviations (2026-10-07, recorded in the spec's "Built" note):
## - The map is built in code on a 150 x 120 MapInfo (no World Forge `evenmead.map` yet): the spec's river polyline
##   (RiverSystem, half width 3, three fords, the ford slow on), the bases / nodes / standards / spires / tree at the
##   spec's positions; flat ground (no hills), no flank woods (the play bounds are the map edge).
## - The ford zone and the standards are `MissionZone`s (side-based capture, scripts/campaign/mission_zone.gd), not
##   CapturePoint kinds; the standard's owner effect (sight 14) is a fog reveal on capture.
## - Hush is a bonded story Helper (helper_hush at Malrik's level, Escort), back at the keep 45 s after a fall.
## - Heartbeat is mission-side (Events.unit_died within 10 m of Malrik: +3 mana, 0.5 s gate).
## - Hovels keep the kingdom cap (no per-mission max_count). No cine timelines (fallback end states).
## - Wizard AoE tuning (2026-10-07, this mission only, `aoe_tuning`): Ysolde's and Vessa's mana regen x 0.5
##   (WIZARD_MANA_REGEN_PCT): their Thornburst / Fireball every few seconds took most of the scripted army's losses
##   at the ford and on the standards; each AoE also takes extra mana (AOE_SURCHARGE: Fireball +30, Thornburst +25), so a
##   full pool pays two or three, then one every ~25 s.
## - Enemy bot defence radius 16 m (2026-10-15, ENEMY_DEFEND_RADIUS): the default 28 m reached the ford from the crest
##   spires, so both rally armies joined W3 there (scripted runs lost 25-30 soldiers in 10 s at ford 70 %).

const MISSION_ID := &"e3m1"
const MISSION_TITLE := "Take the Ford"
const MAP_W := 150.0
const MAP_D := 120.0
const PLAYER_SEAT := Unit.Team.PLAYER
const ALLY_SEAT := Unit.Team.ALLY
const NATURE_SEAT := Unit.Team.ENEMY
const FIRE_SEAT := Unit.Team.ENEMY_2

const MALRIK_START := Vector3(0.0, 0.0, -36.0)
const HUSH_START := Vector3(2.8, 0.0, -37.5)
const DUSK_KEEP := Vector3(-12.0, 0.0, -48.0)
const GLOOM_HALL := Vector3(1.0, 0.0, -48.0)
const HOVEL := Vector3(-14.0, 0.0, -38.0)
const SHADOW_RALLY := Vector3(-4.0, 0.0, -28.0)
const RIME_KEEP := Vector3(28.0, 0.0, -48.0)
const RIME_HALL := Vector3(16.0, 0.0, -45.0)
const ICE_RALLY := Vector3(35.0, 0.0, -28.0)
const TORVALD_START := Vector3(30.0, 0.0, -36.0)
const HEARTWOOD := Vector3(-32.0, 0.0, 48.0)
const GROVE_HALL := Vector3(-44.0, 0.0, 40.0)
const SEED_HOLLOWS: Array[Vector3] = [Vector3(-22.0, 0.0, 56.0), Vector3(-48.0, 0.0, 53.0)]
const NATURE_RALLY := Vector3(-18.0, 0.0, 26.0)
const YSOLDE_ANCHOR := Vector3(-5.0, 0.0, 34.0)
const FIRE_KEEP := Vector3(20.0, 0.0, 50.0)
const EMBER_HALL := Vector3(34.0, 0.0, 40.0)
const HEARTHS: Array[Vector3] = [Vector3(8.0, 0.0, 53.0), Vector3(31.0, 0.0, 55.0)]
const FIRE_RALLY := Vector3(12.0, 0.0, 26.0)
const VESSA_ANCHOR := Vector3(-1.6, 0.0, 35.0)
const CREST_SPIRES := {NATURE_SEAT: [Vector3(-24.0, 0.0, 32.0), Vector3(-10.0, 0.0, 30.0)],
		FIRE_SEAT: [Vector3(6.0, 0.0, 31.0), Vector3(20.0, 0.0, 34.0)]}
const GOLDEN_TREE := Vector3(-16.0, 0.0, 48.5)
## Spec 1 500 / 1 500 / 2 000 / 2 500 ("the home nodes run dry around 18:00"); 2026-10-07: 14 Thralls mined the home
## pair dry by 5:30 and the west expansion by 12:00 (~550 crystals a minute), so the amounts are doubled-ish for the
## spec's rhythm.
const NODES := [
	[&"e3_dusk_a", Vector3(-21.0, 0.0, -45.0), 3000], [&"e3_dusk_b", Vector3(-6.0, 0.0, -56.0), 3000],
	[&"e3_ridge_w", Vector3(-48.0, 0.0, -32.0), 3500], [&"e3_reedfield", Vector3(-24.0, 0.0, -14.0), 3500],
	[&"e3_rime_a", Vector3(37.0, 0.0, -46.0), 1500], [&"e3_rime_b", Vector3(27.0, 0.0, -57.0), 1500],
	[&"e3_ridge_e", Vector3(52.0, 0.0, -34.0), 2000],
	[&"e3_grove_a", Vector3(-41.0, 0.0, 46.0), 1500], [&"e3_grove_b", Vector3(-36.0, 0.0, 57.0), 1500],
	[&"e3_grove_x", Vector3(-56.0, 0.0, 26.0), 2000],
	[&"e3_ember_a", Vector3(27.0, 0.0, 46.0), 1500], [&"e3_ember_b", Vector3(16.0, 0.0, 58.0), 1500],
	[&"e3_ember_x", Vector3(52.0, 0.0, 30.0), 2000],
]
## The river (centre polyline, x / z) and its three fords (the only crossings).
const RIVER_LINE := [Vector2(-75, 6), Vector2(-44, -3), Vector2(-18, 4), Vector2(4, 0), Vector2(26, -7), Vector2(50, -2), Vector2(75, 5)]
const RIVER_HALF := 3.0
const FORD_STONE := Vector3(4.0, 0.0, 0.0)
const FORD_REED := Vector3(-44.0, 0.0, -3.0)
const FORD_BIRCH := Vector3(50.0, 0.0, -2.0)
const FORD_ZONE := Vector3(4.0, 0.0, 2.0)
const FORD_ZONE_R := 7.0
const FORD_LANDING := Vector3(6.0, 0.0, 8.0)
const FORD_STONES := Vector3(12.0, 0.0, 9.0)
const STANDARDS := {&"std_clover": ["Clover Stone", Vector3(-28.0, 0.0, 20.0)],
		&"std_ysolde": ["Ysolde's Standard", Vector3(1.5, 0.0, 21.5)], &"std_well": ["Lark Well", Vector3(24.0, 0.0, 18.0)]}
const STANDARD_R := 6.0
const STANDARD_TIME := 12.0
const FAR_BANK := 1.25
const STANDARD_SIGHT := 14.0
const HORNS := {&"horn_w": Vector3(-40.0, 0.0, 10.0), &"horn_e": Vector3(48.0, 0.0, 10.0)}
const HORN_HP := 540.0
const GUARD_LEASH := 10.0   ## The guards' 2x leash: twice a ~5 m guard post.

const W1_AT := 300.0
const W2_AT := 450.0
const RELIEF_EVERY := 120.0
const RELIEF_MAX := 8        ## Living horn-relief units at most (a cap the spec does not have).
const FINAL_SECOND := 45.0
const FINAL_REFRESH := 4.0
const FORD_TIME: Array[float] = [45.0, 60.0, 75.0]
const HOLD_TIME: Array[float] = [90.0, 120.0, 150.0]
## Spec 50 % ("watch in the first playtest: if W3 at 50 % wipes the player, move its trigger to 70 %"): the 2026-10-07
## scripted runs lost the whole army to W3 at 50 % (it lands on the army in the water).
const W3_AT_PROGRESS := 0.7
const VESSA_RETREAT := 0.35
const HUSH_BACK := 45.0
const HEARTBEAT_R := 10.0
const HEARTBEAT_MANA := 3.0
const HEARTBEAT_GATE := 0.5
const DEFEAT_DELAY := 3.0
const LEVEL_CAP := 6
const START_ESSENCE := 400
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [450, 300, 250]
const MALRIK_SPELLS := [&"shadow_lance", &"shadow_lance", &"soul_siphon"]
const TORVALD_SPELLS := [&"rime_bolt", &"rime_bolt", &"flash_freeze", &"rime_aegis"]
## Thornburst r1 (2026-10-07 scripted runs: at r2 she killed ~10 soldiers per W3 fight; the spec gives no ranks).
const YSOLDE_SPELLS := [&"thornburst", &"wild_bloom", &"wild_bloom", &"call_the_thicket"]
const VESSA_SPELLS := [&"fireball", &"fireball", &"ember_step", &"kindle"]
const WIZARD_MANA_REGEN_PCT := -0.5   ## mission-only wizard AoE tuning (header): Ysolde's and Vessa's cast rate
const AOE_SURCHARGE := {&"fireball": 30.0, &"thornburst": 25.0}   ## mission-only: extra mana per AoE cast (header)
const ESSENCE_CAP := 1500
## The enemy bots defend their buildings only this close (default 28-32): at 28 m the crest spires (z 30-34) pulled
## both rally armies (10 + 10) down onto the Stone Ford (z ~2-9) at the W3 fight; the spec's ford is G1 + W3 and "the
## bots' own armies stand at their rallies". 16 m still covers the Clover Stone and Ysolde's Standard (the crest edge).
const ENEMY_DEFEND_RADIUS := 16.0

const GUARDS := {
	&"G1": [[NATURE_SEAT, [["thornling", 4], ["burr_slinger", 2]]], [FIRE_SEAT, [["flame_guard", 2]]]],
	&"G2": [[NATURE_SEAT, [["thornling", 3]]]],
	&"G3": [[NATURE_SEAT, [["burr_slinger", 2], ["bramblehorn", 1]]]],
	&"G4": [[NATURE_SEAT, [["thornling", 4], ["bloomtender", 1]]]],
	&"G5": [[NATURE_SEAT, [["greenheart_oathkeeper", 2], ["wildwood_archer", 3]]]],
	&"G6": [[FIRE_SEAT, [["flame_guard", 3], ["ember_archer", 2], ["pyre_adept", 1]]]],
}
const GUARD_SPOTS := {&"G1": FORD_LANDING, &"G2": Vector3(-40.0, 0.0, 13.0), &"G3": Vector3(48.0, 0.0, 13.0),
		&"G4": Vector3(-28.0, 0.0, 20.0), &"G5": Vector3(1.5, 0.0, 21.5), &"G6": Vector3(24.0, 0.0, 18.0)}
const WAVES := {
	&"W1": [["thornling", 4], ["thistle_darter", 2]],
	&"W2": [["blaze_rider", 3]],
	&"W3": [["thornling", 6], ["burr_slinger", 3], ["bloomtender", 2], ["bramblehorn", 1]],
	&"RELIEF": [["thornling", 3], ["burr_slinger", 1]],
	&"W4": [["flame_guard", 4], ["ember_archer", 3], ["pyre_adept", 2], ["cinder_arbalest", 1]],
	&"FINAL_N": [["thornling", 8], ["wildwood_archer", 4], ["vinelasher", 2], ["bloomtender", 2]],
	&"FINAL_F": [["flame_guard", 4], ["blaze_rider", 2], ["pyre_adept", 2]],
}

const SPEAKER_COLORS := {&"malrik": Color(0.7, 0.3, 1.0), &"hush": Color(0.60, 0.50, 0.75),
		&"torvald": Color(0.55, 0.80, 1.00), &"obren": Color(1.0, 0.80, 0.25), &"ysolde": Color(0.55, 0.90, 0.35),
		&"vessa": Color(1.0, 0.45, 0.1), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"malrik": "Malrik", &"hush": "Mother Hush", &"torvald": "Torvald", &"obren": "Obren",
		&"ysolde": "Ysolde", &"vessa": "Vessa", &"narrator": "Narrator"}
## L1-L25 (index n - 1).
const DIALOGUE := [
	[&"narrator", "Evenmead. The last green country. By sundown, someone will own the ford."],
	[&"malrik", "Torvald, the east bank is yours. I will take the water. Hush, take whatever moves."],
	[&"hush", "Whatever moves, Bishop. And a few things that don't."],
	[&"torvald", "Quickly, then. Before that stone in your pocket finishes its sentence."],
	[&"obren", "So much green, Bishop. Let it grow red. I can help."],
	[&"malrik", "You can help by being quiet. Stones are usually good at that."],
	[&"vessa", "Malrik! You brought a whole winter to a picnic."],
	[&"malrik", "And you brought fire to a meadow. We all have our gifts, Vessa."],
	[&"ysolde", "That water is older than all four of us. Get out of it."],
	[&"malrik", "The ford is mine. Write it down, Ysolde. You like things that last."],
	[&"narrator", "Across the river, the Lark horns call the whole valley to arms."],
	[&"hush", "One horn fewer. The valley will have to shout."],
	[&"vessa", "He's on our hill. I'm not waiting for him to plant a flag."],
	[&"ysolde", "Vessa, hold the crest. Please. Just once, wait."],
	[&"obren", "The flag falls. The tree is right there. Take it. TAKE it."],
	[&"torvald", "Malrik. Your hand is shaking. Is that you, or the stone?"],
	[&"malrik", "It is me, Torvald. It has always been me."],
	[&"ysolde", "Every root on this hill knows your name now. That is not a kindness."],
	[&"hush", "There is always another night."],
	[&"vessa", "This isn't over, candle-man!"],
	[&"malrik", "It never is. That is what I like about you."],
	[&"malrik", "The ford is mine. The tree is not. Not today."],
	[&"malrik", "Tell me to stop again tomorrow, Ysolde. I will not stop."],
	[&"narrator", "The ford fell at dusk. The golden tree still stood. Both hills called it a victory."],
	[&"malrik", "Not like this. Not... stopped."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"This spring the Master's door held, and the war came up out of the deep looking for open ground. It found Evenmead: knee-high flowers, one slow river, two hills, and the Master's golden tree on the far one.",
	"Malrik holds the north ridge with Torvald's winter at his side. On Lark Hill wait Ysolde, who has nothing left but this valley, and Vessa, who never waits for anything. Between them runs the river, and one stone ford.",
	"Take the ford. Then take the foot of their hill, and let them watch from the top. In Malrik's pocket, Obren's heart-stone beats, and whispers to him.",
]
const HINT_START := "Take the Stone Ford, due south. Fords slow every unit inside: win the fight on the bank, then cross."
const HINT_STRONGHOLD := "Your Dusk Keep can become a Stronghold: select it and press X (200 crystals). It opens Hexweaver, Hollow Oathsworn (Gloom Hall) · Gloom Deacon (Keep)."
const HINT_DEACON := "Gloom Deacon: Z Blood Tithe heals an ally and drains the enemy beside it. V Umbral Passage pulls up to 10 soldiers to the Deacon, even across the river."
const HINT_FORD_TAKEN := "Umbral Passage can bring your army over the water. The standards fall faster with more soldiers."
const HINT_PASSAGE := "Umbral Passage: bring the army over the water."
const MSG_TORVALD_FELL := "Torvald falls back to the ridge"
const MSG_KEEP_BURNS := "Lark Hill burns, but its people hold the crest"
const MSG_HUSH_BACK := "Mother Hush is back at the Dusk Keep"

## Read only.
var aoe_tuning := true                 ## the mission-only wizard AoE tuning (header); false = the raw kit (tests)
var ford_zone: MissionZone
var standards := {}                    ## id -> MissionZone
var horns := {}                        ## id -> Building (Horn Spires)
var torvald: Wizard = null
var ysolde: Wizard = null
var vessa: Wizard = null
var hush: Helper = null
var guard_groups := {}
var waves_fired: Array[StringName] = []
var hold_left := -1.0                  ## Seconds of obj_hold left (-1 before it starts).
var hold_paused := false
var horns_down := 0
var said: Array[int] = []
var heartbeats := 0                    ## Heartbeat mana gains (tests).
var vessa_driven := false
var standard_toppled := false
var ford_taken_at := -1.0
var victory_time := -1.0

var _said := {}
var _tick := 0.0
var _zone_tick := 0.0
var _relief_left := -1.0
var _final_refresh := 0.0
var _final_units: Array = []
var _relief_units: Array = []
var _heartbeat_gate := 0.0
var _wizard_wave := {}                 ## wizard -> true while a wave carries it
var _horn_type: BuildingType
var _river: RiverSystem
var _torvald_order := &""
var _last_obj_text := ""


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"shadow"
	enemy_kingdom = &"nature"
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	tavern_enabled = false
	trade_enabled = false
	river_enabled = false
	points_enabled = false
	camps_enabled = false
	beasts_enabled = false
	define_objectives([[&"obj_ford", "primary"], [&"obj_foot", "primary"], [&"obj_hold", "primary"],
			[&"obj_malrik", "primary"], [&"sec_horns", "secondary"], [&"sec_vessa", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"bramblehorn", &"cinder_arbalest"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Dusk Keep has fallen"
	c.tiers_enabled = true
	c.max_tier = 2
	c.bots_upgrade = false
	c.start_tiers = {ALLY_SEAT: 2, NATURE_SEAT: 2, FIRE_SEAT: 2}
	c.casters_enabled = true
	c.start_level = 3
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = START_ESSENCE
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe ford is Malrik's"
	c.defeat_banner = "DEFEAT"
	c.seat_sides = {PLAYER_SEAT: 0, ALLY_SEAT: 0, NATURE_SEAT: 1, FIRE_SEAT: 1}
	c.seat_opponents = {NATURE_SEAT: PLAYER_SEAT, FIRE_SEAT: ALLY_SEAT, ALLY_SEAT: FIRE_SEAT, PLAYER_SEAT: NATURE_SEAT}
	c.seat_kingdoms = {PLAYER_SEAT: &"shadow", ALLY_SEAT: &"ice", NATURE_SEAT: &"nature", FIRE_SEAT: &"fire"}
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"gloom_deacon", "trigger": &"unlock", "key_hint": "Dusk Keep: B",
			"card": "Gloom Deacon. Heals your soldiers with their enemies' blood, and opens a road through the dark."}
	return c


func _map_size() -> Vector2:
	return Vector2(MAP_W, MAP_D)


func _player_start() -> Vector3:
	return MALRIK_START


func _use_map_dressing() -> bool:
	return false


func _title_line() -> String:
	return "Episode 3, Mission 1: %s" % MISSION_TITLE


func _ready() -> void:
	_horn_type = _make_horn_type()
	register_local_building_type(_horn_type)
	super()
	if camera_rig:
		camera_rig.focus_on(MALRIK_START)
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)


func _make_horn_type() -> BuildingType:
	var base := BuildingType.find("nature_tower")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.id = &"horn_spire"
	t.display_name = "Horn Spire"
	t.max_hp = HORN_HP
	t.counts_for_defeat = false
	t.cost = 0
	return t


# ---------------------------------------------------------------- seats

func start_position(team: int) -> Vector3:
	match team:
		ALLY_SEAT:
			return TORVALD_START
		NATURE_SEAT:
			return YSOLDE_ANCHOR
		FIRE_SEAT:
			return VESSA_ANCHOR
	return MALRIK_START


func base_center(team: int) -> Vector3:
	if seat_bases.has(team):
		return seat_bases[team]
	match team:
		ALLY_SEAT:
			return RIME_KEEP
		NATURE_SEAT:
			return HEARTWOOD
		FIRE_SEAT:
			return FIRE_KEEP
	return DUSK_KEEP


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	if k:
		return k.spawn_point()
	return base_center(team) + Vector3(4.0, 0.0, 4.0)


func node_of(team: int, suffix: String) -> CrystalNode:
	var prefix := {PLAYER_SEAT: "e3_dusk_", ALLY_SEAT: "e3_rime_", NATURE_SEAT: "e3_grove_", FIRE_SEAT: "e3_ember_"}
	var id := StringName("%s%s" % [prefix.get(team, "e3_dusk_"), suffix])
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


## Commander (MT2 contract): the Crown Hollow Shadow-side point `p` for this seat (a rough mirror into its base).
func bot_point(team: int, p: Vector3) -> Vector3:
	var c := base_center(team)
	var s := 1.0 if c.z > 0.0 else -1.0
	return c + Vector3(-p.x * 0.25, 0.0, -s * absf(p.z) * 0.25)


func bot_vector(team: int, v: Vector3) -> Vector3:
	var s := 1.0 if base_center(team).z > 0.0 else -1.0
	return Vector3(-v.x, 0.0, s * v.z)


func natural_hall_spot(team: int) -> Vector3:
	match team:
		PLAYER_SEAT:
			return Vector3(-41.0, 0.0, -36.0)
		ALLY_SEAT:
			return Vector3(46.0, 0.0, -38.0)
	return Vector3.INF


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	_build_river()
	keep = build_grid.spawn_complete(BuildingType.find("shadow_keep"), DUSK_KEEP, PLAYER_SEAT) as Keep
	build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL, PLAYER_SEAT)
	build_grid.spawn_complete(BuildingType.find("shadow_hovel"), HOVEL, PLAYER_SEAT)
	seat_bases[PLAYER_SEAT] = DUSK_KEEP
	var rk := build_grid.spawn_complete(BuildingType.find("ice_keep"), RIME_KEEP, ALLY_SEAT) as Keep
	build_grid.spawn_complete(BuildingType.find("ice_barracks"), RIME_HALL, ALLY_SEAT)
	_seat_keep(ALLY_SEAT, rk, RIME_KEEP)
	var hw := build_grid.spawn_complete(BuildingType.find("nature_keep"), HEARTWOOD, NATURE_SEAT) as Keep
	var gh := build_grid.spawn_complete(BuildingType.find("nature_barracks"), GROVE_HALL, NATURE_SEAT)
	if gh:
		gh.set_meta(&"e3m1_hall", true)
	for p in SEED_HOLLOWS:
		build_grid.spawn_complete(BuildingType.find("nature_hollow"), p, NATURE_SEAT)
	shadow_keep = hw
	_seat_keep(NATURE_SEAT, hw, HEARTWOOD)
	var fk := build_grid.spawn_complete(BuildingType.find("fire_keep"), FIRE_KEEP, FIRE_SEAT) as Keep
	var eh := build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL, FIRE_SEAT)
	if eh:
		eh.set_meta(&"e3m1_hall", true)
	for p in HEARTHS:
		build_grid.spawn_complete(BuildingType.find("fire_hearth"), p, FIRE_SEAT)
	_seat_keep(FIRE_SEAT, fk, FIRE_KEEP)
	for seat: int in CREST_SPIRES:
		for p: Vector3 in CREST_SPIRES[seat]:
			build_grid.spawn_complete(BuildingType.find("nature_tower" if seat == NATURE_SEAT else "fire_tower"), p, seat)
	for id: StringName in HORNS:
		var h := build_grid.spawn_complete(_horn_type, HORNS[id], NATURE_SEAT) if _horn_type else null
		if h:
			h.name = "HornSpire_%s" % String(id)
			mark_scripted(h)
			horns[id] = h
			h.destroyed.connect(_on_horn_destroyed.bind(id))
	add_golden_tree(self)


func _seat_keep(seat: int, k: Keep, at: Vector3) -> void:
	if k:
		seat_keeps[seat] = k
	seat_bases[seat] = k.global_position if k else at
	seat_starts[seat] = start_position(seat)


## The river with its three fords (RiverSystem under the NavigationRegion3D, before the bake), the ground cut.
func _build_river() -> void:
	_river = make_river(nav_region, MALRIK_START)
	var mat := _ground_material()
	if mat:
		EnvProps.set_river(mat, _river.shader_params())


## Evenmead's river (the spec's polyline, half width 3, the three fords; e3m2 / e3m4 reuse it), added under `nav`.
static func make_river(nav: Node, bank_point: Vector3) -> RiverSystem:
	var river := RiverSystem.new()
	river.name = "River"
	river.player_bank_point = bank_point
	nav.add_child(river)
	var line := PackedVector2Array()
	for p: Vector2 in RIVER_LINE:
		line.append(p)
	var lines: Array[PackedVector2Array] = [line]
	var crossings: Array[Dictionary] = [
		{"id": &"ford_stone", "name": "Stone Ford", "kind": RiverSystem.KIND_FORD, "center": FORD_STONE, "width": 9.0},
		{"id": &"ford_reed", "name": "Reed Ford", "kind": RiverSystem.KIND_FORD, "center": FORD_REED, "width": 6.0},
		{"id": &"ford_birch", "name": "Birch Ford", "kind": RiverSystem.KIND_FORD, "center": FORD_BIRCH, "width": 6.0},
	]
	river.setup(lines, RIVER_HALF, Vector4.ZERO, crossings)
	return river


## The Master's golden tree: decor only (no collider, not a target, outside every zone).
static func add_golden_tree(parent: Node) -> void:
	if _SIM.enabled:
		return
	var root := Node3D.new()
	root.name = "GoldenTree"
	parent.add_child(root)
	root.position = GOLDEN_TREE
	var trunk := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.9
	c.height = 6.0
	trunk.mesh = c
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.45, 0.34, 0.2)
	trunk.material_override = bark
	trunk.position.y = 3.0
	root.add_child(trunk)
	var crown := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 4.2
	s.height = 6.5
	crown.mesh = s
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.82, 0.3)
	gold.emission_enabled = true
	gold.emission = Color(0.9, 0.7, 0.25) * 0.4
	crown.material_override = gold
	crown.position.y = 8.0
	root.add_child(crown)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for team: int in [PLAYER_SEAT, ALLY_SEAT, NATURE_SEAT, FIRE_SEAT]:
		for p: Vector3 in [FORD_STONE, FORD_REED, FORD_BIRCH, YSOLDE_ANCHOR, MALRIK_START]:
			fog.reveal(team, p, 6.0)
		for id: StringName in STANDARDS:
			fog.reveal(team, STANDARDS[id][1], 6.0)
	_setup_champions()
	# --- Malrik (the player), Hush, the start army.
	hero = _make_wizard(PLAYER_SEAT)
	_spawn(hero, PLAYER_SEAT, MALRIK_START)
	_claim_wizard(hero, PLAYER_SEAT)
	ItemDrops.ensure_inventory(hero)
	raise_wizard(hero, 3, MALRIK_SPELLS)
	set_meta(&"campaign_flags", {})
	force_artifacts(hero, ["keystone_shard", ""])
	for i in 5:
		var w := _spawn(make_unit("gloom_thrall"), PLAYER_SEAT, DUSK_KEEP + Vector3(-4.0 + i * 1.5, 0.0, 6.0))
		w.call(&"command_gather", node_of(PLAYER_SEAT, "a" if i < 3 else "b"))
	var army := [["shade", 4 + (2 if diff == 0 else 0)], ["nightbolt", 2], ["grave_hound", 0 if diff == 2 else 2]]
	var k := 0
	for row: Array in army:
		for j in int(row[1]):
			_spawn(make_unit(String(row[0])), PLAYER_SEAT, SHADOW_RALLY + Vector3((k % 4) * 1.6 - 2.4, 0.0, (k / 4) * 1.7))
			k += 1
	hush = _story_hush()
	# --- Torvald (ALLY, Ice).
	var ice := activate_seat(ALLY_SEAT, &"ice", {"crystals": 300,
			"workers": [["rime_hauler", 2, node_of(ALLY_SEAT, "a")], ["rime_hauler", 2, node_of(ALLY_SEAT, "b")]],
			"units": [["rimeshield", 4, ICE_RALLY], ["shardcaster", 2, ICE_RALLY], ["frost_mortar", 1, ICE_RALLY],
					["rimecarver", 1, ICE_RALLY]],
			"wizard": {"level": 4, "spells": TORVALD_SPELLS, "pos": TORVALD_START}})
	torvald = ice.get("wizard") as Wizard
	if torvald:
		torvald.died.connect(_on_bot_wizard_died.bind(ALLY_SEAT))
	_add_seat_commander(ALLY_SEAT)
	# --- Ysolde (ENEMY, Nature) and Vessa (ENEMY_2, Fire) on Lark Hill.
	var nat := activate_seat(NATURE_SEAT, &"nature", {"crystals": 300,
			"workers": [["sprigling", 3, node_of(NATURE_SEAT, "a")], ["sprigling", 2, node_of(NATURE_SEAT, "b")]],
			"units": [["thornling", 6, NATURE_RALLY], ["wildwood_archer", 3, NATURE_RALLY]],
			"wizard": {"level": 4, "spells": YSOLDE_SPELLS, "pos": YSOLDE_ANCHOR}})
	ysolde = nat.get("wizard") as Wizard
	shadow_hero = ysolde
	var fire := activate_seat(FIRE_SEAT, &"fire", {"crystals": 300,
			"workers": [["cinder_hand", 3, node_of(FIRE_SEAT, "a")], ["cinder_hand", 2, node_of(FIRE_SEAT, "b")]],
			"units": [["flame_guard", 4, FIRE_RALLY], ["ember_archer", 2, FIRE_RALLY]],
			"wizard": {"level": 4, "spells": VESSA_SPELLS, "pos": VESSA_ANCHOR}})
	vessa = fire.get("wizard") as Wizard
	for w: Variant in [ysolde, vessa]:
		if w != null:
			mark_scripted(w as Node)
			(w as Wizard).set_meta(META_HOME, (w as Wizard).global_position)
			(w as Wizard).level_cap = 4   # the Final raises them (L5, hard L6)
			if aoe_tuning:
				var wz := w as Wizard
				wz.add_modifier(&"mission:aoe_tuning", {"mana_regen_pct": WIZARD_MANA_REGEN_PCT})
				wz.spell_cast.connect(func(id: StringName) -> void:
					if AOE_SURCHARGE.has(id):   # the AoE surcharge: Fireball 40 + 30, Thornburst 35 + 25 mana here
						wz.mana = maxf(0.0, wz.mana - float(AOE_SURCHARGE[id])))
			(w as Wizard).died.connect(_on_bot_wizard_died.bind(int((w as Wizard).team)))
	_add_seat_commander(NATURE_SEAT)
	_add_seat_commander(FIRE_SEAT)
	wizard_respawned.connect(_on_e3_wizard_respawned)
	# --- Zones and guards.
	_add_zones()
	for gid: StringName in GUARDS:
		var units: Array = []
		for part: Array in GUARDS[gid]:
			units.append_array(spawn_group(part[1], GUARD_SPOTS[gid], 3.0, int(part[0]) as Unit.Team, true))
		guard_groups[gid] = units
	var ch := AllyChannel.instance(get_tree(), self)
	if ch:
		ch.time_source = mission_time
	_add_events()
	begin_mission([&"obj_ford", &"obj_malrik", &"sec_horns"])


## Mother Hush (story unit, D5): the helper kit at Malrik's level, Escort, back at the keep 45 s after a fall.
func _story_hush() -> Helper:
	var ht := HelperType.find(&"helper_hush")
	if ht == null or hero == null:
		return null
	var hp := Helper.new()
	hp.apply_helper_type(ht, hero.level)
	hp.name = "HushStory"
	_spawn(hp, PLAYER_SEAT, HUSH_START)
	hp.bond_to(hero)
	hp.set_stance(&"escort")
	mark_scripted(hp)
	hp.died.connect(_on_hush_died)
	return hp


## Named methods (not lambdas): a save while Hush is down keeps her return timer (bound timers are saved).
func _on_hush_died(_u: Unit) -> void:
	if fire_once(&"E13"):
		say_l(19)
	after(HUSH_BACK, _hush_back)


func _hush_back() -> void:
	if hush and is_instance_valid(hush) and not hush.is_alive() and not is_ending():
		hush.respawn(respawn_point(PLAYER_SEAT))
		if hud:
			hud.show_message(MSG_HUSH_BACK, 3.0)


## The seat's Commander: the kingdom's knobs, never attacks (scripted waves are the attacks), few workers, no
## expansion; Torvald (ALLY) up to 14 army pop, the enemies 10 soldiers at their rallies.
func seat_profile(seat: int) -> AIProfile:
	var diff := clampi(mission_difficulty, 0, 2)
	var p: AIProfile
	match seat_kingdoms.get(seat, &"shadow"):
		&"ice":
			p = MissionBase.frozen_ice_profile(diff)
		&"nature":
			p = MissionBase.frozen_nature_profile(diff)
		_:
			p = AIProfile.for_difficulty(diff)
	p.id = StringName("mission_e3_01_%s" % ("ally" if seat == ALLY_SEAT else "enemy"))
	p.profile_id = p.id
	p.min_attack_pop = 99
	p.launch_attacks = false
	p.attack_full_pop = 0
	p.first_attack_by = 0.0
	p.worker_target_home = 5
	p.worker_target_expanded = 5
	p.worker_target_x2 = 5
	p.second_expansion = false
	p.expand_time = 1.0e6
	p.max_soldiers = int(by_difficulty([9, 7, 5])) if seat == ALLY_SEAT else 10
	p.build_rows = PackedStringArray(["H1"])   # spec: no new towers (V1 put Fire towers on the ford's banks)
	p.rebuild = false
	p.hero_stays_home = true
	p.malrik_joins = AIProfile.MalrikJoins.NEVER
	p.champion_max = 0
	p.trade = false
	p.map_fill = false
	if seat != ALLY_SEAT:
		p.defend_radius = ENEMY_DEFEND_RADIUS
		p.item_build = PackedStringArray()   # the spec's wizards: levels and spells only (no bot items)
	return p


func _add_seat_commander(seat: int) -> Node:
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return null
	var bot: Node = script.new()
	bot.name = "ShadowBot" if seat == NATURE_SEAT else "Bot%d" % seat
	bot.set(&"team", seat)
	bot.set(&"profile", seat_profile(seat))
	add_child(bot)
	commanders.append(bot)
	return bot


func _add_zones() -> void:
	ford_zone = MissionZone.new()
	ford_zone.zone_id = &"zone_ford"
	ford_zone.display_name = "Stone Ford"
	ford_zone.radius = FORD_ZONE_R
	ford_zone.capture_time = float(by_difficulty(FORD_TIME))
	ford_zone.fixed_rate = true
	ford_zone.lock_on_capture = true
	ford_zone.sides_allowed = [0]
	add_child(ford_zone)
	ford_zone.global_position = FORD_ZONE
	ford_zone.captured.connect(_on_ford_captured)
	register_actor("zone_ford", ford_zone)   # C4-6: owner / progress / lock rows
	for id: StringName in STANDARDS:
		var z := MissionZone.new()
		z.zone_id = id
		z.display_name = String(STANDARDS[id][0])
		z.radius = STANDARD_R
		z.capture_time = STANDARD_TIME
		z.has_pole = true
		z.time_factor = {0: FAR_BANK, 1: 1.0}
		add_child(z)
		z.global_position = STANDARDS[id][1]
		z.set_owner_side(1)
		z.captured.connect(_on_standard_captured)
		standards[id] = z
		register_actor("zone_%s" % String(id), z)


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_ford", false), objective_text(&"obj_foot", false),
				objective_text(&"obj_hold", false), objective_text(&"obj_malrik", false)],
		"rule": Loc.sink(objective_text(&"obj_malrik")),
	}


func standards_owned(side := 0) -> int:
	var n := 0
	for id: StringName in standards:
		if (standards[id] as MissionZone).owner_side == side:
			n += 1
	return n


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_ford":
			if with_counter and ford_zone and not ford_zone.locked:
				return "Take the Stone Ford (%d %%)" % int(100.0 * ford_zone.progress)
			return "Take the Stone Ford"
		&"obj_foot":
			if with_counter:
				return "Take the foot of Lark Hill (%d / 3)" % standards_owned()
			return "Take the foot of Lark Hill"
		&"obj_hold":
			if with_counter and hold_left >= 0.0:
				var s := int(ceil(hold_left))
				if hold_paused:
					return "Hold the foot of Lark Hill (%d:%02d, paused)" % [s / 60, s % 60]
				return "Hold the foot of Lark Hill (%d:%02d)" % [s / 60, s % 60]
			return "Hold the foot of Lark Hill"
		&"obj_malrik":
			return "Malrik must survive"
		&"sec_horns":
			if with_counter:
				return "Silence the Lark horns (%d / 2)" % horns_down
			return "Silence the Lark horns"
		&"sec_vessa":
			return "Drive Vessa off the field"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_ford":
			if ford_zone:
				return {"progress": int(100.0 * ford_zone.progress), "goal": 100, "position": FORD_ZONE}
		&"obj_foot":
			return {"counter": standards_owned(), "goal": 3}
		&"obj_hold":
			if hold_left >= 0.0:
				return {"time_left": hold_left, "position": STANDARDS[&"std_ysolde"][1]}
		&"sec_horns":
			return {"counter": horns_down, "goal": 2}
	return {}


func say_l(n: int) -> void:
	if _said.has(n):
		return
	_said[n] = true
	said.append(n)
	say_line(n)


# ---------------------------------------------------------------- events

func _intro() -> void:
	fire_once(&"E1")
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)
	for n in [1, 2, 3, 4]:
		say_l(n)
	if hud:
		hud.show_message(HINT_START, 10.0)


func _add_events() -> void:
	add_event(&"E2", func() -> bool: return hero_alive() and _river != null and _river.distance_to_water(hero.global_position) <= 15.0,
			func() -> void:
				say_l(5)
				say_l(6))
	after(210.0, func() -> void:
		if is_ending():
			return
		fire_once(&"E3")
		if hud:
			hud.show_message(HINT_STRONGHOLD, 12.0)
		show_spotlight())
	spotlight_first_unit.connect(func(_u: Unit) -> void:
		if fire_once(&"E4") and hud:
			hud.show_message(HINT_DEACON, 12.0))
	after(W1_AT, _fire_wave.bind(&"W1"))
	after(W2_AT, _fire_wave.bind(&"W2"))


func _fire_wave(id: StringName) -> void:
	if is_ending() or waves_fired.has(id):
		return
	waves_fired.append(id)
	match id:
		&"W1":
			for u in spawn_wave_at(WAVES[&"W1"], _hall_spawn(NATURE_SEAT), NATURE_SEAT):
				order_wave(u as Unit, &"workers", _nearest_worker_pos(FORD_REED))
		&"W2":
			fire_once(&"E5")
			say_l(7)
			say_l(8)
			set_objective(&"sec_vessa", "active")
			var units := spawn_wave_at(WAVES[&"W2"], _hall_spawn(FIRE_SEAT), FIRE_SEAT)
			_carry_wizard(vessa, units, &"raid", _ally_workers_pos())
			for u in units:
				order_wave(u as Unit, &"raid", _ally_workers_pos())
			_relief_left = 0.0   # horn relief from E5
		&"W3":
			fire_once(&"E6")
			say_l(9)
			var units := spawn_wave_at(WAVES[&"W3"], _hall_spawn(NATURE_SEAT), NATURE_SEAT)
			_carry_wizard(ysolde, units, &"point_hold", FORD_ZONE)   # holds the ford with W3 (&"point" = on to the keep)
			for u in units:
				order_wave(u as Unit, &"point_hold", FORD_ZONE)
			_torvald_push(&"diversion")
		&"W4":
			var at := _first_owned_standard()
			var units := spawn_wave_at(WAVES[&"W4"], _hall_spawn(FIRE_SEAT), FIRE_SEAT)
			_carry_wizard(vessa, units, &"standard", at)
			for u in units:
				order_wave(u as Unit, &"standard", at)
		&"FINAL":
			var cut := _final_cut
			var nat := spawn_wave_at(WAVES[&"FINAL_N"], _hall_spawn(NATURE_SEAT), NATURE_SEAT, cut)
			for w: Variant in [ysolde, vessa]:
				if w != null and is_instance_valid(w):
					(w as Wizard).level_cap = int(by_difficulty([5, 5, 6]))
					raise_wizard(w as Wizard, (w as Wizard).level_cap, [])
			_carry_wizard(ysolde, nat, &"standard", _nearest_owned_standard(_hall_spawn(NATURE_SEAT)))
			_carry_wizard(vessa, nat, &"standard", _nearest_owned_standard(_hall_spawn(FIRE_SEAT)))
			for u in nat:
				order_wave(u as Unit, &"standard", _nearest_owned_standard((u as Unit).global_position))
			_final_units.append_array(nat)
			after(FINAL_SECOND, _final_second)


## The Final's sizes: a quarter fewer once sec_horns is done.
func _final_cut(n: int) -> int:
	return n - int(floor(n * 0.25)) if objective_state("sec_horns") == "done" else n


## The Final's Fire half (FINAL_SECOND after the Nature half; a named method so a save keeps it).
func _final_second() -> void:
	if is_ending():
		return
	var fu := spawn_wave_at(WAVES[&"FINAL_F"], _hall_spawn(FIRE_SEAT), FIRE_SEAT, _final_cut)
	for u in fu:
		order_wave(u as Unit, &"standard", _nearest_owned_standard((u as Unit).global_position))
	_final_units.append_array(fu)


## The horn relief: per living Horn Spire, 3 Thornlings + 1 Burr Slinger at it, to the ford then the nearest standard
## side 0 owns (every 120 s from E5; stops for a spire when it falls, for good when sec_horns is done).
func _horn_relief() -> void:
	_relief_units = _relief_units.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if _relief_units.size() >= RELIEF_MAX:
		return   # 2026-10-07: uncapped, 8 units / 2 min piled up on the ford (24 by 11:00) before the ford fight began
	for id: StringName in horns:
		var hv: Variant = horns[id]
		var h: Building = hv as Building if hv != null and is_instance_valid(hv) else null
		if h == null or not is_instance_valid(h) or not h.is_alive():
			continue
		for u in spawn_wave_at(WAVES[&"RELIEF"], h.global_position + Vector3(0.0, 0.0, 4.0), NATURE_SEAT):
			order_wave(u as Unit, &"relief", FORD_ZONE)
			_relief_units.append(u)


func _hall_spawn(seat: int) -> Vector3:
	for b in Building.for_team(seat):
		if b.is_alive() and b.has_meta(&"e3m1_hall") and b is TrainingBuilding:
			return (b as TrainingBuilding).spawn_point()
	var k := keep_of(seat)
	return k.spawn_point() if k else base_center(seat)


func _nearest_worker_pos(from: Vector3) -> Vector3:
	var best := DUSK_KEEP
	var d := INF
	for u in workers_of(PLAYER_SEAT):
		var dd := _flat(u.global_position, from)
		if dd < d:
			d = dd
			best = u.global_position
	return best


func _ally_workers_pos() -> Vector3:
	var ws := workers_of(ALLY_SEAT)
	return ws[0].global_position if not ws.is_empty() else RIME_KEEP


func _first_owned_standard() -> Vector3:
	for id: StringName in standards:
		if (standards[id] as MissionZone).owner_side == 0:
			return (standards[id] as MissionZone).global_position
	return STANDARDS[&"std_ysolde"][1]


func _nearest_owned_standard(from: Vector3) -> Vector3:
	var best: Vector3 = STANDARDS[&"std_ysolde"][1]
	var d := INF
	for id: StringName in standards:
		var z := standards[id] as MissionZone
		if z.owner_side != 0:
			continue
		var dd := _flat(z.global_position, from)
		if dd < d:
			d = dd
			best = z.global_position
	return best


## A wave carries an enemy wizard (W2, W3, W4, Final): it leaves its crest anchor with the wave.
func _carry_wizard(w: Wizard, _units: Array, mode: StringName, at: Vector3) -> void:
	if w == null or not is_instance_valid(w) or not w.is_alive():
		return
	_wizard_wave[w] = true
	order_wave(w, mode, at)


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	if u is Wizard and u == vessa and u.hp < u.max_hp * VESSA_RETREAT:
		u.set_meta(META_MODE, &"anchor")
		u.command_move(VESSA_ANCHOR)   # bot rule 8: Vessa goes home under 35 %
		_wizard_wave.erase(u)
		return true
	match mode:
		&"workers":
			if u.attack_target == null and not u.is_attack_moving():
				u.command_attack_move(_nearest_worker_pos(u.global_position))
			return true
		&"raid":
			if u.attack_target == null and not u.is_attack_moving():
				u.set_meta(META_MODE, &"workers")
				u.command_attack_move(_nearest_worker_pos(u.global_position))
			return true
		&"point_hold":
			if u.attack_target == null and _flat(u.global_position, FORD_ZONE) > 4.0:
				u.command_attack_move(FORD_ZONE)
			return true
		&"relief":
			if u.attack_target == null and not u.is_attack_moving():
				u.set_meta(META_MODE, &"standard")
				u.command_attack_move(_nearest_owned_standard(u.global_position))
			return true
		&"standard":
			if u.attack_target == null:
				var to := _nearest_owned_standard(u.global_position)
				if _flat(u.global_position, to) > 3.0:
					u.command_attack_move(to)
			return true
		&"anchor":
			return true
	return false


# ---------------------------------------------------------------- the ford and the standards

func _tick_zones(dt: float) -> void:
	if ford_zone and not ford_zone.locked:
		ford_zone.tick(dt)
		if ford_zone.progress >= W3_AT_PROGRESS and not waves_fired.has(&"W3"):
			_fire_wave(&"W3")
	if objective_state("obj_foot") == "active" or objective_state("obj_hold") != "":
		for id: StringName in standards:
			(standards[id] as MissionZone).tick(dt)


func _on_ford_captured(_z: MissionZone, _side: int) -> void:
	if is_ending():
		return
	fire_once(&"E7")
	ford_taken_at = mission_time()
	if not waves_fired.has(&"W3"):
		_fire_wave(&"W3")
	set_objective(&"obj_ford", "done")
	play_cutscene(&"e3m1_ford", func() -> void:
		say_l(10)
		if _horns_alive() > 0:
			say_l(11))
	set_objective(&"obj_foot", "active")
	if hud:
		hud.show_message(HINT_FORD_TAKEN, 10.0)
	flash_ring(FORD_LANDING + Vector3(0.0, 0.0, 4.0), 4.0)   # the spotlight moment: a road behind the pickets


func _on_standard_captured(z: MissionZone, side: int) -> void:
	if is_ending():
		return
	if side == 0:
		fog.reveal(PLAYER_SEAT, z.global_position, STANDARD_SIGHT)
		fog.reveal(ALLY_SEAT, z.global_position, STANDARD_SIGHT)
		if fire_once(&"E9"):
			say_l(13)
			say_l(14)
			_fire_wave(&"W4")
		if z.zone_id == &"std_ysolde" and fire_once(&"E10"):
			standard_toppled = true
			z.topple()
			play_cutscene(&"e3m1_standard", func() -> void:
				say_l(15)
				say_l(16)
				say_l(17))
		if standards_owned(0) >= 3 and objective_state("obj_foot") == "active":
			_foot_taken()
	else:
		z.topple(true)
	if objective_state("obj_foot") == "active":
		set_objective(&"obj_foot", "active")   # the counter changed


## E11: all three standards: obj_hold (2:00, pauses, never resets), the Final wave, Torvald to Lark Well.
func _foot_taken() -> void:
	fire_once(&"E11")
	set_objective(&"obj_foot", "done")
	say_l(18)
	hold_left = float(by_difficulty(HOLD_TIME))
	set_objective(&"obj_hold", "active")
	_fire_wave(&"FINAL")
	_torvald_push(&"well")


func _tick_hold(dt: float) -> void:
	if hold_left < 0.0 or objective_state("obj_hold") != "active":
		return
	hold_paused = standards_owned(0) < 3
	if hold_paused:
		return
	hold_left = maxf(0.0, hold_left - dt)
	if hold_left <= 0.0:
		_hold_done()


## E14: the hold is done: e3m1_dusk, the Nature / Fire units walk back to the crest, victory at its end.
func _hold_done() -> void:
	fire_once(&"E14")
	victory_time = mission_time()
	set_objective(&"obj_hold", "done")
	_record_flags()
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and (int(u.team) == NATURE_SEAT or int(u.team) == FIRE_SEAT) and not u.is_worker():
			set_truce([u], true, Unit.TRUCE_ALL)
			u.command_move(YSOLDE_ANCHOR if int(u.team) == NATURE_SEAT else VESSA_ANCHOR)
	play_cutscene(&"e3m1_dusk", func() -> void:
		say_l(22)
		say_l(23)
		say_l(24)
		set_objective(&"obj_malrik", "done")
		if objective_state("sec_horns") == "active":
			set_objective(&"sec_horns", "failed")
		if objective_state("sec_vessa") == "active":
			set_objective(&"sec_vessa", "failed")
		win(1.0))


## Malrik's track (D7 / campaign-outline D8, flags only): time, the standard, his essence (bonuses, 50 %, cap 1 500).
func _record_flags() -> void:
	set_mission_flag("e3m1_time", int(victory_time))
	set_mission_flag("e3m1_standard_toppled", true)
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	var essence := bank.essence if bank else 0
	if objective_state("sec_horns") == "done":
		essence += 300
	if vessa_driven:
		essence += 200
	set_mission_flag(CampaignState.MALRIK_ESSENCE_FLAG, mini(ESSENCE_CAP, essence / 2))


# ---------------------------------------------------------------- horns, wizards, Torvald

func _horns_alive() -> int:
	var n := 0
	for id: StringName in horns:
		var hv: Variant = horns[id]
		var h: Building = hv as Building if hv != null and is_instance_valid(hv) else null
		if h and is_instance_valid(h) and h.is_alive():
			n += 1
	return n


func _on_horn_destroyed(_b: Building, _id: StringName) -> void:
	if is_ending():
		return
	horns_down += 1
	if fire_once(&"E8"):
		say_l(12)
	if horns_down >= 2:
		set_objective(&"sec_horns", "done")
		_relief_left = -1.0
	else:
		set_objective(&"sec_horns", "active")


func _on_bot_wizard_died(_u: Unit, seat: int) -> void:
	if is_ending():
		return
	_wizard_wave.erase(_u)
	_respawn_left[seat] = next_respawn_delay(seat)
	_deaths[seat] = int(_deaths.get(seat, 0)) + 1
	if seat == ALLY_SEAT and hud:
		hud.show_message(MSG_TORVALD_FELL, 4.0)
	if seat == FIRE_SEAT and has_fired(&"E5") and not vessa_driven:
		vessa_driven = true
		fire_once(&"E12")
		say_l(20)
		say_l(21)
		if objective_state("sec_vessa") == "active":
			set_objective(&"sec_vessa", "done")


func _on_e3_wizard_respawned(wiz: Wizard) -> void:
	if is_ending():
		return
	if wiz == ysolde or wiz == vessa:
		wiz.set_meta(META_MODE, &"anchor")
		wiz.command_move(YSOLDE_ANCHOR if wiz == ysolde else VESSA_ANCHOR)


## Torvald's scripted pushes on top of his Commander: at W3 Birch Ford -> Horn Spire East (a diversion), at obj_foot
## Lark Well (held through the hold).
func _torvald_push(kind: StringName) -> void:
	_torvald_order = kind
	var at: Vector3 = HORNS[&"horn_e"] if kind == &"diversion" else STANDARDS[&"std_well"][1]
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ALLY_SEAT and not u.is_worker():
			mark_scripted(u)
			u.set_meta(META_HOME, at + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
			if not _guards.has(u):
				_guards.append(u)
			u.command_attack_move(u.get_meta(META_HOME))


## The guards' 2x leash (spec "Guards"): a guard more than GUARD_LEASH from its spot walks back (and drops its chase).
func _tick_leash() -> void:
	for gid: StringName in guard_groups:
		for g: Variant in guard_groups[gid]:
			if not is_instance_valid(g) or not (g as Unit).is_alive() or not (g as Unit).has_meta(META_HOME):
				continue
			var u := g as Unit
			var home: Vector3 = u.get_meta(META_HOME)
			if _flat(u.global_position, home) > GUARD_LEASH:
				u.command_move(home)


func _tick_wizards() -> void:
	for w: Variant in [ysolde, vessa]:
		if w == null or not is_instance_valid(w) or not (w as Wizard).is_alive() or _wizard_wave.has(w):
			continue
		var wiz := w as Wizard
		var home: Vector3 = YSOLDE_ANCHOR if wiz == ysolde else VESSA_ANCHOR
		if wiz.attack_target == null and _flat(wiz.global_position, home) > 4.0 and not wiz.has_move_order():
			wiz.command_move(home)


## Heartbeat (the Keystone Shard): +3 mana to Malrik when any unit dies within 10 m of him, at most once per 0.5 s.
func _on_any_unit_died(u: Node) -> void:
	if not hero_alive() or u == hero or not u is Node3D or not is_instance_valid(u):
		return
	if _flat((u as Node3D).global_position, hero.global_position) > HEARTBEAT_R:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _heartbeat_gate < HEARTBEAT_GATE:
		return
	_heartbeat_gate = now
	heartbeats += 1
	hero.mana = minf(hero.max_mana, hero.mana + HEARTBEAT_MANA)


func _on_player_hero_fell() -> void:
	fire_once(&"E15")
	say_l(25)
	set_objective(&"obj_malrik", "failed")
	super()


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_zone_tick -= delta
	if _zone_tick <= 0.0:
		_zone_tick = 0.25
		_tick_zones(0.25)
	_tick_hold(delta)
	if _relief_left >= 0.0 and objective_state("sec_horns") != "done":
		_relief_left -= delta
		if _relief_left <= 0.0:
			_relief_left = RELIEF_EVERY
			_horn_relief()
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_wizards()
		_tick_leash()
		var t := "%s|%s|%s|%s" % [objective_text(&"obj_ford"), objective_text(&"obj_foot"), objective_text(&"obj_hold"),
				objective_text(&"sec_horns")]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
