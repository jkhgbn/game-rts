class_name MissionE2_02
extends MissionBase
## Episode 2, mission 2 "Roots and Embers" (docs/design/mission-e2-02.md): the first 2v2 of the story, on the real seat
## API (scripts/core/teams.gd): PLAYER Fire (Vessa) + ALLY Nature (Ysolde, scripted column, no base until E14) against
## ENEMY Shadow (Malrik's bot) + ENEMY_2 Ice (Torvald's bot, and his forward fort Rimehold on Fire's bank).
## Ysolde's seed-carriers plant three groves (GroveSite / MissionGrove); the third raises her Heartwood
## (`activate_seat(ALLY, &"nature", ...)`) and the war becomes two against two; break Rimehold, then hold the Vice.
##
## Built deviations from the spec (2026-10-06, recorded in the spec's "Built" note):
## - Map: the 120 m Crown Hollow terrain with one base per corner (Fire south-west, Nature north-west, Shadow
##   north-east, Ice south-east) instead of the 168 m Fourfold Hollow (MissionBase extends Skirmish, not LayoutLevel);
##   every spec position is scaled into the quadrants below. No river (the 1v1 river runs corner to corner).
## - The grove card's "Send Ysolde here" is a 3-button panel ("Send Ysolde: <grove>") + Alt+click on a site
##   (AllyChannel first cut); after E14 the ally plays a Commander (never attacks) plus this mission's L1 / L2 rules.
## - `obj_groves` stays done once done; a destroyed grove pauses the Vice countdown `(paused: replant)` until 3 stand.
## - Emberwatch reserve (campaign notes 2026-10-11, safety net): an army wiped at Rimehold left 0-5 soldiers and ~50
##   crystals for 4 minutes (a near soft-lock). From RESERVE_FROM, when Fire has RESERVE_BELOW soldiers or fewer and under
##   RESERVE_BROKE crystals, Captain Ashby marches the Emberwatch reserve in (RESERVE_ROWS + RESERVE_CRYSTALS) at most
##   RESERVE_MAX times, RESERVE_GAP s apart.

const MISSION_ID := &"e2m2"
const MISSION_TITLE := "Roots and Embers"
const MAP_SEED := 2202

const PLAYER_SEAT := Unit.Team.PLAYER
const ALLY_SEAT := Unit.Team.ALLY
const SHADOW_SEAT := Unit.Team.ENEMY
const ICE_SEAT := Unit.Team.ENEMY_2
const SEAT_NAMES := {0: "fire", 3: "ally", 1: "shadow", 4: "ice"}

# ---- Fire's quadrant (x < 0, z > 0); the other seats are its mirror images (seat_xf).
const EMBER_HALL_POS := Vector3(-27.0, 0.0, 45.0)
const EMBER_SPIRE_POS := Vector3(-37.0, 0.0, 29.0)
const HEARTH_SPOTS: Array[Vector3] = [Vector3(-50.0, 0.0, 46.0), Vector3(-50.0, 0.0, 52.0)]
const ARMY_POS := Vector3(-31.0, 0.0, 33.0)
const NODES := {&"a": [Vector3(-46.0, 0.0, 34.0), 2000], &"b": [Vector3(-34.0, 0.0, 46.0), 2000],
		&"mid": [Vector3(-24.0, 0.0, 22.0), 2500], &"rich": [Vector3(-3.0, 0.0, 56.0), 2500]}
const X1_SPOT := Vector3(-30.0, 0.0, 17.0)
const X2_SPOT := Vector3(-14.0, 0.0, 52.0)
const MARKET_SPOT := Vector3(-50.0, 0.0, 30.0)
const S3_SPOT := Vector3(-28.0, 0.0, 10.0)
const RALLY_SPOT := Vector3(-30.0, 0.0, 30.0)     ## Fire canonical rally (the bots' rallies are its images).

# ---- The groves.
const GROVES := {&"A": ["Stumpwood", Vector3(-44.0, 0.0, 14.0), 6.0], &"B": ["Wayshrine Hollow", Vector3(-12.0, 0.0, -12.0), 6.0],
		&"C": ["Heartseed", Vector3(-33.0, 0.0, -33.0), 7.0]}
const PAUSE_RADIUS := 8.0
const CARRIER_FLEE := 12.0
const SAP_RADIUS := 8.0
const SAP_STATS := {"hp_regen": 3.0}
const SPROUT_EVERY := 60.0
const SPROUT_MAX := 4
const SEED_MAX_WAITING := 2
const SEED_RESUPPLY := 60.0   ## fewer than 2 carriers and a grove left to plant: 1 new carrier every 60 s (no soft-lock)
const PLANT_TICK := 0.25
const COLUMN_MAX := 8

# ---- Rimehold (Ice, on Fire's bank).
const RIMEHOLD_HALL := Vector3(-8.0, 0.0, 49.0)
const RIME_SPIRES: Array[Vector3] = [Vector3(5.0, 0.0, 47.0), Vector3(-12.0, 0.0, 57.0), Vector3(-2.0, 0.0, 40.0)]
const RIME_SPIRE_HP := 720.0
const G1_POS := Vector3(-2.0, 0.0, 50.0)
const RIMEHOLD_NEAR := 20.0

# ---- Enemy bases (images of the Fire base).
const SHADOW_KEEP_POS := Vector3(43.0, 0.0, -43.0)
const GLOOM_HALL_POS := Vector3(27.0, 0.0, -45.0)
const NIGHT_SPIRE_POS := Vector3(37.0, 0.0, -29.0)
const HOVEL_POS := Vector3(50.0, 0.0, -46.0)
const SHADOW_RALLY := Vector3(30.0, 0.0, -30.0)
const SHADOW_CORNER := Vector3(56.0, 0.0, -56.0)
const ICE_KEEP_POS := Vector3(43.0, 0.0, 43.0)
const ICE_HALL_POS := Vector3(27.0, 0.0, 45.0)
const ICE_SPIRE_POS := Vector3(37.0, 0.0, 29.0)
const SNOW_LODGE_POS := Vector3(50.0, 0.0, 46.0)
const ICE_RALLY := Vector3(30.0, 0.0, 30.0)
const ICE_CORNER := Vector3(56.0, 0.0, 56.0)
const ALLY_KEEP_POS := Vector3(-43.0, 0.0, -43.0)
const ALLY_START := Vector3(-36.0, 0.0, -36.0)
const ALLY_HALL_POS := Vector3(-27.0, 0.0, -45.0)
const ALLY_HOLLOWS: Array[Vector3] = [Vector3(-50.0, 0.0, -46.0), Vector3(-50.0, 0.0, -52.0)]
const BRIDGE_SPOT := Vector3(0.0, 0.0, 52.0)       ## "Millstone Bridge": the Ice Vice aims at Fire's south flank.
const G2_POS := Vector3(-4.0, 0.0, -32.0)
const G3_POS := Vector3(-10.0, 0.0, 26.0)
const SHARED_RALLY := Vector3(-40.0, 0.0, 0.0)

# ---- Map fill (Fire half; the east is mirrored in x).
const POINT_SPOTS_E2M2: Array[Dictionary] = [
	{"id": &"millwatch", "name": "Millwatch", "kind": &"watchtower", "pos": Vector3(-20.0, 0.0, 32.0)},
	{"id": &"copperwatch", "name": "Copperwatch", "kind": &"watchtower", "pos": Vector3(-20.0, 0.0, -32.0)},
	{"id": &"saltwatch", "name": "Saltwatch", "kind": &"watchtower", "pos": Vector3(20.0, 0.0, -32.0)},
	{"id": &"gullwatch", "name": "Gullwatch", "kind": &"watchtower", "pos": Vector3(20.0, 0.0, 32.0)},
	{"id": &"mossmere", "name": "Mossmere Well", "kind": &"well", "pos": Vector3(-34.0, 0.0, 0.0)},
	{"id": &"stonemere", "name": "Stonemere Well", "kind": &"well", "pos": Vector3(34.0, 0.0, 0.0)},
	{"id": &"shrine_w", "name": "West Wayshrine", "kind": &"shrine", "pos": Vector3(-12.0, 0.0, 0.0)},
	{"id": &"shrine_e", "name": "East Wayshrine", "kind": &"shrine", "pos": Vector3(12.0, 0.0, 0.0)},
]
const CAMP_SPOTS_E2M2: Array[Dictionary] = [
	{"id": &"wallow_sw", "name": "Bristleback Wallow", "kind": &"bristleback", "tier": 1, "pos": Vector3(-58.0, 0.0, 26.0), "first_spawn": 0.0},
	{"id": &"wallow_nw", "name": "Bristleback Wallow", "kind": &"bristleback", "tier": 1, "pos": Vector3(-58.0, 0.0, -26.0), "first_spawn": 0.0},
	{"id": &"wallow_ne", "name": "Bristleback Wallow", "kind": &"bristleback", "tier": 1, "pos": Vector3(58.0, 0.0, -26.0), "first_spawn": 0.0},
	{"id": &"wallow_se", "name": "Bristleback Wallow", "kind": &"bristleback", "tier": 1, "pos": Vector3(58.0, 0.0, 26.0), "first_spawn": 0.0},
	{"id": &"nest_s", "name": "Willow Ford Nest", "kind": &"mirefang", "tier": 2, "pos": Vector3(0.0, 0.0, 18.0), "first_spawn": 0.0},
	{"id": &"nest_n", "name": "Reed Ford Nest", "kind": &"mirefang", "tier": 2, "pos": Vector3(0.0, 0.0, -18.0), "first_spawn": 0.0},
	{"id": &"hollow_w", "name": "Gloomcap Hollow", "kind": &"gloomcap", "tier": 2, "pos": Vector3(-54.0, 0.0, 0.0), "first_spawn": 150.0},
	{"id": &"hollow_e", "name": "Gloomcap Hollow", "kind": &"gloomcap", "tier": 2, "pos": Vector3(54.0, 0.0, 0.0), "first_spawn": 150.0},
]
const CACHE_SPOTS_E2M2: Array[Vector3] = [Vector3(-26.0, 0.0, 8.0), Vector3(-26.0, 0.0, -8.0), Vector3(26.0, 0.0, -8.0),
		Vector3(26.0, 0.0, 8.0)]

# ---- Timeline (mission time, s) and tables.
const INTRO_LINES_END := 20.0
const W1_AT := 150.0
const W2_AT := 300.0
const RAID_FIRST := 360.0
const RAID_EVERY := 150.0
const W3_AT := 450.0
const W4_AT := 600.0
const W5_AT := 750.0
const W6_AFTER := 45.0
const VICE_KNIGHTS_AFTER := 75.0
const VICE_DELAY := 8.0
const WIZARD_RESPAWN := 60.0
const YSOLDE_KNEEL := 10.0
const WREN_KNEEL := 8.0
const PING_EVERY := 30.0
const EAVESDROP_RADIUS := 12.0
const EAVESDROP_LEAD := 30.0
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 2.0
const LEVEL_CAP := 8
const NO_SAVE_ESSENCE := 600
const ALLY_DEFEND_RADIUS := 28.0
const ALLY_HELP_TIME := 60.0
const ALLY_CALM_TIME := 15.0
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [500, 400, 300]
const PLANT_TIME: Array[float] = [30.0, 40.0, 50.0]
const CARRIERS_START: Array[int] = [8, 6, 6]
const SEED_EVERY: Array[float] = [90.0, 90.0, 120.0]
const GROVE_HP: Array[float] = [1100.0, 900.0, 750.0]
const VICE_SECONDS: Array[float] = [120.0, 150.0, 195.0]
const WIZARD_LEVEL: Array[int] = [4, 5, 6]
const WIZARD_VICE_LEVEL: Array[int] = [5, 6, 7]
const MALRIK_SPELLS := [&"shadow_lance", &"shadow_lance", &"soul_siphon", &"soul_siphon", &"umbral_shroud"]
const TORVALD_SPELLS := [&"rime_bolt", &"rime_bolt", &"flash_freeze", &"flash_freeze", &"rime_aegis"]
const YSOLDE_SPELLS := [&"thornburst", &"thornburst", &"wild_bloom", &"call_the_thicket"]
const VEY_PRICE := {"crystals": [250, 300, 350], "essence": [100, 150, 200], "time": [45.0, 45.0, 60.0]}
const EASY_SKIP: Array[StringName] = [&"rime_colossus", &"frost_mortar"]

## Waves: id -> {side, rows}. Ice rows lose 40 % once Rimehold is broken (and the Colossus).
const WAVES := {
	&"W1": {"side": &"ice", "rows": [["rimeshield", 3], ["shardcaster", 2]]},
	&"W2": {"side": &"shadow", "rows": [["shade", 4], ["nightbolt", 2], ["grave_hound", 2]]},
	&"W3": {"side": &"ice", "rows": [["rimeshield", 4], ["shardcaster", 2], ["rime_seer", 1]]},
	&"W4": {"side": &"shadow", "rows": [["shade", 5], ["nightbolt", 3], ["shadow_knight", 1], ["gloom_deacon", 1]]},
	&"W5": {"side": &"ice", "rows": [["rimeshield", 4], ["shardcaster", 2], ["frost_mortar", 1], ["rime_colossus", 1]]},
	&"W6": {"side": &"shadow", "rows": [["shade", 4], ["nightbolt", 2], ["grave_hound", 2]]},
	&"VS": {"side": &"shadow", "rows": [["shade", 6], ["nightbolt", 3], ["shadow_knight", 1], ["gloom_deacon", 1]]},
	&"VI": {"side": &"ice", "rows": [["rimeshield", 5], ["shardcaster", 3], ["frost_mortar", 1], ["rime_colossus", 1]]},
	&"VK": {"side": &"shadow", "rows": [["shadow_knight", 2]]},
	&"VH": {"side": &"shadow", "rows": [["shade", 4], ["nightbolt", 2]]},
	&"RELIEF": {"side": &"ice", "rows": [["rimeshield", 4], ["shardcaster", 2]]},
	&"RAID": {"side": &"shadow", "rows": [["grave_hound", 2]]},
}
const WAVE_TIMES := {&"W1": W1_AT, &"W2": W2_AT, &"W3": W3_AT, &"W4": W4_AT, &"W5": W5_AT}

const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1), &"ysolde": Color(0.55, 0.90, 0.35), &"maelis": Color(0.60, 0.85, 0.50),
	&"messenger": Color(0.80, 0.92, 0.60), &"vey": Color(0.95, 0.95, 0.55), &"ashby": Color(0.95, 0.60, 0.35),
	&"malrik": Color(0.7, 0.3, 1.0), &"torvald": Color(0.55, 0.80, 1.00), &"narrator": Color(0.9, 0.85, 0.7),
}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"ysolde": "Ysolde", &"maelis": "Maelis", &"messenger": "Wren",
		&"vey": "Old Vey", &"ashby": "Captain Ashby", &"malrik": "Malrik", &"torvald": "Torvald", &"narrator": "Narrator"}
## L1-L33 (index n - 1), then L11b as line 34.
const DIALOGUE := [
	[&"narrator", "Nature had no kingdom left, only seed. Fire had a border, and a frost fort sitting on it."],
	[&"ysolde", "Three groves along your line, Vessa. Give me those, and I can give you a kingdom back."],
	[&"vessa", "Three trees? I can do three trees. Torvald brought a whole fort. That one's mine."],
	[&"ysolde", "This one I can do alone. Keep them off me, and do not set it on fire."],
	[&"vessa", "One time. I set ONE tree on fire, one time."],
	[&"maelis", "Stumpwood breathes again. The forest remembers who froze it."],
	[&"ysolde", "Point, and I will go. I am done waiting for wars to pass my wood by."],
	[&"ashby", "Watchtower's ours, my queen. We can see clear across the Hollowmere."],
	[&"malrik", "A gardener and a matchstick. Torvald, they are planting trees at us."],
	[&"vessa", "The Citadel's up. Vey, the storm can come any time now. Now would be good."],
	[&"vey", "You called twice in two days. I'll start to think you missed me."],
	[&"torvald", "This bank is mine until the thaw, child. The thaw is a long way off."],
	[&"vessa", "I AM the thaw, Torvald. I've been told I'm very warm."],
	[&"malrik", "The shrine glade. How fitting. Do pray, Ysolde. Nobody answered last time."],
	[&"torvald", "I gave the wood one winter. I can give it another."],
	[&"ysolde", "Malrik. You burned my people. You will not have their seed."],
	[&"messenger", "Frost on the road! They're going for the Heartseed!"],
	[&"ysolde", "Three groves. Enough roots to stand on. Rise."],
	[&"vessa", "Huh. You grow a castle out of a seed. I have to build mine out of rocks."],
	[&"ysolde", "Then we each keep the other's. Fire and Nature, one front."],
	[&"vessa", "Rimehold's down. Torvald, you left your fort on my bank. I put it back."],
	[&"narrator", "Two kingdoms on one bank, two across the water. Now it is a real war."],
	[&"torvald", "Now, Bishop. Before her roots take hold."],
	[&"malrik", "Knights, to the shrine glade. Burn whatever grew there twice."],
	[&"ysolde", "Three stones in our hands. The land listens to whoever stands on it."],
	[&"ysolde", "They cut it. Then we plant it again. That is the whole of my strength."],
	[&"messenger", "We've lost too many carriers. The seed's running out."],
	[&"torvald", "Two banners on one bank. Malrik, I begin to see why you feared her."],
	[&"ysolde", "You came when I called, Vessa. Next time, I come when you do."],
	[&"vessa", "Deal. And next time, I'll leave your trees alone."],
	[&"vessa", "Ysolde... keep... planting..."],
	[&"ashby", "The Emberwatch is burning! Fall back, fall back!"],
	[&"ysolde", "The roots are cut. All of them. I am sorry, Vessa."],
	[&"vey", "First time you've called me in twelve years, girl. I came running."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Ysolde walked out of her last Heartwood with a pouch of seed, one warden and a girl who never stops running. Her army is ash. Her kingdom is whatever she can plant before winter notices.",
	"Fire's border runs along the Hollowmere now, and Torvald has already crossed it: a frost fort on Vessa's own bank, squatting on the richest crystal seam she owns, and Malrik's knives in the reeds behind it.",
	"Plant three groves along Fire's line and Nature grows back beside it. Then break the frost fort. Two against two, at last. Ysolde says it will be slow. Vessa says that is what the fire is for.",
]
const BRIEFING_PING_LINE := "Ping a grove site to send Ysolde's column there (Alt+click the site, or the \"Send Ysolde\" buttons)."
## The Emberwatch reserve (header).
const RESERVE_FROM := 360.0
const RESERVE_BELOW := 5
const RESERVE_BROKE := 200
const RESERVE_MAX := 2
const RESERVE_GAP := 150.0
const RESERVE_ROWS := [["flame_guard", 4], ["ember_archer", 3]]
const RESERVE_CRYSTALS := 150
const MSG_RESERVE := "Captain Ashby brings up the Emberwatch reserve. Rebuild before you strike again."
const HINT_GROVE_A := "Ysolde plants, you guard. Keep the enemy out of the grove ring."
const HINT_NEXT_GROVE := "Send Ysolde to the next grove: Alt+click its site, or press \"Send Ysolde\" for it (top right)."
const HINT_POINTS := "Capture points: stand in the ring with no enemy inside. Watchtowers see far, wells pay essence, the shrine blesses your army."
const HINT_CITADEL := "Your Stronghold can become a Citadel: select the Keep and press X (300 crystals, 90 s). It opens the Ashveil Saboteur (C) and lets you call Old Vey (V)."
const HINT_CALL := "Call Old Vey: select the Keep and press V. He fights on his own; his card sets where (Escort / Vanguard / Hold home)."
const HINT_SABOTEUR := "A Saboteur looks like a Rime Hauler. Walk it past the spires and charge the Frost Hall."
const MSG_PLANTING := "Ysolde is planting {grove}. Keep the enemy out of the grove."
const MSG_PAUSED := "The planting stops while the enemy stands in the grove"
const MSG_GROWING := "{grove} is growing again ({n} / 3)"
const MSG_TWO_V_TWO := "The war is two against two."
const MSG_MALRIK_FELL := "Malrik has fallen back into the shadows"
const MSG_TORVALD_FELL := "Torvald has fallen, the frost will bring him back"
const MSG_YSOLDE_FELL := "Ysolde has fallen, the forest will regrow her"
const MSG_EAVESDROP_ICE := "Eavesdrop: Ice wave in 0:30 · {units}"
const MSG_EAVESDROP_SHADOW := "Eavesdrop: Shadow wave in 0:30 · {units}"
const BUTTON_SEND := "Send Ysolde: {grove}"

## Test / menu switch (before the tree): campaign flags to use instead of the save ({} = read the save).
var flag_override: Dictionary = {}

## Read only.
var sites := {}                        ## &"A" / &"B" / &"C" -> GroveSite
var ysolde: Wizard
var maelis: Helper
var wren: Unit
var torvald: Wizard
var carriers: Array = []               ## Living seed-carriers.
var carriers_lost := 0
var column: Array = []                 ## Ysolde's fighters (Thornlings, Bloomtenders) walking with her.
var column_target: StringName = &""    ## The site the column heads for (&"" = hold at the last grove).
var column_hold := Vector3.INF         ## A ping spot that is not a grove: hold there.
var heartwood: Keep                    ## The ALLY keep after E14.
var ally_active := false               ## E14 happened.
var ally_commander: Node
var rimehold: Array[Building] = []     ## Frost Hall + spires.
var rimehold_hall: Building
var rime_haulers: Array = []
var ember_hall: TrainingBuilding
var gloom_hall: Building
var ice_hall: Building
var ice_keep: Keep
var guard_groups := {}
var waves_fired: Array[StringName] = []
var wave_units := {}
var vice_left := -1.0                  ## Seconds of the Vice left (-1 before / after).
var vice_paused := false
var vice_done := false
var vey_arrived := false
var no_save_fallback := false
var said: Array[int] = []
var e14_time := -1.0
var points_peak := 0

var _flags_read := false
var _said := {}
var _tick := 0.0
var _carrier_type: UnitType
var _wren_type: UnitType
var _warden_types := {}
var _ysolde_kneel_left := 0.0
var _wren_kneel_left := 0.0
var _ysolde_deaths := 0
var _malrik_home := true
var _torvald_home := true
var _ping_left := PING_EVERY
var _eaves_said := {}
var _last_obj_text := ""
var _paused_msg := {}
var _plant_announced := {}
var _send_panel: Control
var _plant_acc := 0.0                  ## planting runs every PLANT_TICK s on the summed delta (unit scans, not per frame)
var _resupply_at := -1.0               ## mission time of the next resupply carrier (-1 = none needed)
var _ally_order := {}                  ## {pos, until, calm} of the ally's current L1 / L2 answer
var _relief_sent := false
var reserves_sent := 0                 ## Read only: Emberwatch reserves marched in (header)
var _reserve_at := 0.0                 ## mission time of the last reserve
var _grove_types := {}
var _hall_type: BuildingType


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	tavern_enabled = true   # no tavern here (closed decor): the guild only carries the companion
	points_enabled = true
	camps_enabled = true
	beasts_enabled = false
	trade_enabled = false
	river_enabled = false
	define_objectives([[&"obj_groves", "primary"], [&"obj_rimehold", "primary"], [&"obj_vice", "primary"],
			[&"obj_vessa", "primary"], [&"obj_keep", "primary"], [&"obj_ally", "primary"],
			[&"sec_carriers", "secondary"], [&"sec_points", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = false   # E23 is the mission's own (L32, 3 s)
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {PLAYER_SEAT: 2, SHADOW_SEAT: 2, ICE_SEAT: 2}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.helper_call_price = VEY_PRICE.duplicate(true)
	c.start_level = 4
	c.start_spell_points = 3
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.seat_sides = {PLAYER_SEAT: 0, ALLY_SEAT: 0, SHADOW_SEAT: 1, ICE_SEAT: 1}
	c.seat_opponents = {SHADOW_SEAT: PLAYER_SEAT, ICE_SEAT: PLAYER_SEAT, ALLY_SEAT: SHADOW_SEAT, PLAYER_SEAT: ICE_SEAT}
	c.seat_kingdoms = {ALLY_SEAT: &"nature", ICE_SEAT: &"ice"}
	c.victory_banner = "VICTORY\nTwo banners on one bank"
	c.defeat_banner = "DEFEAT"
	c.rewards = {"flags": {"e2m2_carriers_kept": "sec_carriers", "e2m2_points_held": "sec_points"},
			"bonus_essence": {"sec_carriers": 300, "sec_points": 150}, "set_flags": {"ep2_nature_allied": true},
			"next": &"e2m3"}
	c.spotlight = {"id": &"ashveil_saboteur", "trigger": &"unlock", "key_hint": "Keep: C",
			"card": "Ashveil Saboteur. Looks like their worker, works for you: blow the hall, stop the army before it's born."}
	return c


func _ready() -> void:
	_hall_type = _make_hall_type()
	get_tree().node_added.connect(_on_e2_node_added)
	_carrier_type = _make_carrier_type()
	_wren_type = _make_story_type("wildwood_archer", &"wren", "Wren", 260.0, 5.2)
	for id in ["thornling", "bloomtender"]:
		var base := UnitType.find(id)
		if base:
			var t := base.duplicate() as UnitType
			t.pop = 0   # Ysolde's column: no seat pop before her kingdom exists
			_warden_types[id] = t
	super()


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_e2_node_added):
		get_tree().node_added.disconnect(_on_e2_node_added)


## The mission 2 Ember Hall card (spec "Unlocks"): Z Flame Guard, X Ember Archer, C Blaze Rider, V Ash Hurler,
## B Pyre Adept, N Cinder Arbalest.
func _make_hall_type() -> BuildingType:
	var base := BuildingType.find("fire_barracks")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	var trains: Array[UnitType] = []
	for id in ["flame_guard", "ember_archer", "blaze_rider", "ash_hurler", "pyre_adept", "cinder_arbalest"]:
		var ut := UnitType.find(id)
		if ut:
			trains.append(ut)
	t.trains = trains
	return t


func _on_e2_node_added(node: Node) -> void:
	var b := node as TrainingBuilding
	if b != null and _hall_type != null and b.building_type != null and b.building_type != _hall_type \
			and b.building_type.id == &"fire_barracks" and int(b.team) == PLAYER_SEAT:
		b.building_type = _hall_type


func _lighting_preset() -> StringName:
	return &"warm"


func _lane_end() -> Vector3:
	return (GROVES[&"B"] as Array)[1]


func _title_line() -> String:
	return "Episode 2, Mission 2: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	var out: Array[Vector4] = []
	for seat: int in [PLAYER_SEAT, ALLY_SEAT, SHADOW_SEAT, ICE_SEAT]:
		var s := seat_xf(seat, PLAYER_START)
		out.append(Vector4(s.x, s.z, 13.0, 0.0))
	return out


# ---------------------------------------------------------------- seats: the four quadrants

## Fire's canonical point `p` placed in `seat`'s quadrant (PLAYER as is, ALLY mirror in z, ENEMY point mirror,
## ENEMY_2 mirror in x). Also turns vectors (no translation).
static func seat_xf(seat: int, p: Vector3) -> Vector3:
	match seat:
		Unit.Team.ALLY:
			return Vector3(p.x, p.y, -p.z)
		Unit.Team.ENEMY:
			return Vector3(-p.x, p.y, -p.z)
		Unit.Team.ENEMY_2:
			return Vector3(-p.x, p.y, p.z)
	return p


## Commander (MT2 contract): a Crown Hollow Shadow-side point for this seat (Fire's canonical point is its mirror).
func bot_point(team: int, p: Vector3) -> Vector3:
	return seat_xf(team, -p)


func bot_vector(team: int, v: Vector3) -> Vector3:
	return seat_xf(team, -v)


func node_of(team: int, suffix: String) -> CrystalNode:
	var id := StringName("node_%s_%s" % [SEAT_NAMES.get(team, "fire"), suffix])
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		crystal_nodes.erase(id)
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(team: int) -> Vector3:
	return seat_xf(team, X1_SPOT)


func rich_hall_spot(team: int) -> Vector3:
	return seat_xf(team, X2_SPOT)


func market_slot(team: int) -> Vector3:
	return seat_xf(team, MARKET_SPOT)


func tower_slot(team: int, which: StringName) -> Vector3:
	if which == &"natural" or which == &"S3":
		return seat_xf(team, S3_SPOT)
	return Vector3.INF


func start_position(team: int) -> Vector3:
	if team == ALLY_SEAT or team == ICE_SEAT:
		return seat_xf(team, PLAYER_START)
	return super(team)


func base_center(team: int) -> Vector3:
	if seat_bases.has(team):
		return seat_bases[team]
	return seat_xf(team, PLAYER_START + KEEP_OFFSET)


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	if k:
		return k.spawn_point()
	if team == SHADOW_SEAT:
		return SHADOW_CORNER
	if team == ICE_SEAT:
		return ICE_CORNER
	return super(team)


func cache_spots() -> Array[Vector3]:
	return CACHE_SPOTS_E2M2


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	_read_flags()
	var rng := RandomNumberGenerator.new()
	rng.seed = MAP_SEED
	var clearings := map_clearings()
	var keep_out := func(p: Vector3) -> bool:
		return _in_clearing(p, clearings) or _in_corridor(p)
	for cluster in 14:   # winter woods: the Crown Hollow broadleaf clusters, frosted (E2M2.V1)
		var center := Vector3(rng.randf_range(-54, 54), 0.0, rng.randf_range(-54, 54))
		for i in rng.randi_range(5, 9):
			var p := center + Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6))
			var s := rng.randf_range(0.9, 1.5)
			if absf(p.x) > 57.0 or absf(p.z) > 57.0 or keep_out.call(p):
				continue
			_add_tree(p, s)
	for i in 16:
		var p := Vector3(rng.randf_range(-54, 54), 0.0, rng.randf_range(-54, 54))
		if keep_out.call(p):
			continue
		_add_rock(p, rng.randf_range(0.8, 1.8), rng.randf() * TAU)

	# Crystal nodes for all four seats (the Fire table and its images).
	for seat: int in [PLAYER_SEAT, ALLY_SEAT, SHADOW_SEAT, ICE_SEAT]:
		for suffix: StringName in NODES:
			if suffix == &"rich" and seat != PLAYER_SEAT:
				continue   # the Mouth is Fire's (held by Rimehold); no rich twins on this map
			var row: Array = NODES[suffix]
			_add_crystal_node(StringName("node_%s_%s" % [SEAT_NAMES[seat], suffix]), seat_xf(seat, row[0]), int(row[1]))

	# Fire: the Emberwatch Ford (Stronghold through config.start_tiers), Ember Hall, Ember Spire, 2 Hearths.
	keep = build_grid.spawn_complete(BuildingType.find("fire_keep"), PLAYER_START + KEEP_OFFSET, PLAYER_SEAT) as Keep
	ember_hall = build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL_POS, PLAYER_SEAT) as TrainingBuilding
	build_grid.spawn_complete(BuildingType.find("fire_tower"), EMBER_SPIRE_POS, PLAYER_SEAT)
	for p in HEARTH_SPOTS:
		build_grid.spawn_complete(BuildingType.find("fire_hearth"), p, PLAYER_SEAT)
	# Shadow: Malrik's base (the bot).
	shadow_keep = build_grid.spawn_complete(BuildingType.find("shadow_keep"), SHADOW_KEEP_POS, SHADOW_SEAT) as Keep
	gloom_hall = build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL_POS, SHADOW_SEAT)
	build_grid.spawn_complete(BuildingType.find("shadow_tower"), NIGHT_SPIRE_POS, SHADOW_SEAT)
	build_grid.spawn_complete(BuildingType.find("shadow_hovel"), HOVEL_POS, SHADOW_SEAT)
	# Ice: Torvald's base (the second bot).
	ice_keep = build_grid.spawn_complete(BuildingType.find("ice_keep"), ICE_KEEP_POS, ICE_SEAT) as Keep
	if ice_keep:
		seat_keeps[ICE_SEAT] = ice_keep
		seat_bases[ICE_SEAT] = ice_keep.global_position
	ice_hall = build_grid.spawn_complete(BuildingType.find("ice_barracks"), ICE_HALL_POS, ICE_SEAT)
	build_grid.spawn_complete(BuildingType.find("ice_tower"), ICE_SPIRE_POS, ICE_SEAT)
	build_grid.spawn_complete(BuildingType.find("ice_lodge"), SNOW_LODGE_POS, ICE_SEAT)
	seat_bases[ALLY_SEAT] = ALLY_KEEP_POS
	seat_starts[ALLY_SEAT] = ALLY_START
	seat_starts[ICE_SEAT] = seat_xf(ICE_SEAT, PLAYER_START)
	_build_rimehold()
	_build_groves()
	if points_enabled:
		capture_points = _add_mapfill_service(CAPTURE_POINTS_PATH, "CapturePoints", &"capture_points_service")
		if capture_points and capture_points.has_method(&"setup"):
			capture_points.call(&"setup", POINT_SPOTS_E2M2)


## Rimehold (Ice, on Fire's bank): the Frost Hall (scripted, locked: the bot never trains there) and 3 Rime Spires
## (2 if e2m1_frosthall_shattered), every building scripted.
func _build_rimehold() -> void:
	rimehold.clear()
	rimehold_hall = build_grid.spawn_complete(BuildingType.find("ice_barracks"), RIMEHOLD_HALL, ICE_SEAT)
	if rimehold_hall:
		mark_scripted(rimehold_hall)
		rimehold_hall.set_meta(TrainingBuilding.META_LOCKED, true)
		rimehold.append(rimehold_hall)
	var n := 2 if _flag(&"e2m1_frosthall_shattered") else 3
	for i in n:
		var spire := build_grid.spawn_complete(BuildingType.find("ice_tower"), RIME_SPIRES[i], ICE_SEAT)
		if spire:
			spire.max_hp = RIME_SPIRE_HP
			spire.hp = RIME_SPIRE_HP
			mark_scripted(spire)
			rimehold.append(spire)
	for b in rimehold:
		b.destroyed.connect(_on_rimehold_destroyed)


func _build_groves() -> void:
	for id: StringName in GROVES:
		var g: Array = GROVES[id]
		var s := GroveSite.new()
		s.name = "GroveSite%s" % id
		s.site_id = id
		s.grove_name = String(g[0])
		s.radius = float(g[2])
		s.seed_left = float(by_difficulty(SEED_EVERY))
		add_child(s)
		s.global_position = g[1]
		sites[id] = s


## Every clearing of the generator: [position, radius].
func map_clearings() -> Array:
	var out := []
	for seat: int in [PLAYER_SEAT, ALLY_SEAT, SHADOW_SEAT, ICE_SEAT]:
		out.append([seat_xf(seat, PLAYER_START), 18.0])
		out.append([seat_xf(seat, EMBER_HALL_POS), 4.5])
		out.append([seat_xf(seat, EMBER_SPIRE_POS), 3.5])
		out.append([seat_xf(seat, X1_SPOT), 4.5])
		out.append([seat_xf(seat, RALLY_SPOT), 6.0])
		for p in HEARTH_SPOTS:
			out.append([seat_xf(seat, p), 3.5])
		for suffix: StringName in NODES:
			out.append([seat_xf(seat, (NODES[suffix] as Array)[0]), 7.0])
	for id: StringName in GROVES:
		out.append([(GROVES[id] as Array)[1], float((GROVES[id] as Array)[2]) + 3.0])
	out.append([RIMEHOLD_HALL, 6.0])
	for p in RIME_SPIRES:
		out.append([p, 4.0])
	for spot: Dictionary in POINT_SPOTS_E2M2:
		out.append([spot["pos"], 5.0])
	for spot: Dictionary in CAMP_SPOTS_E2M2:
		out.append([spot["pos"], 5.0])
	for p in CACHE_SPOTS_E2M2:
		out.append([p, 3.0])
	out.append([G1_POS, 6.0])
	out.append([G2_POS, 4.0])
	out.append([G3_POS, 4.0])
	out.append([SHARED_RALLY, 5.0])
	out.append([SHADOW_CORNER, 4.0])
	out.append([ICE_CORNER, 4.0])
	return out


## The open roads: Fire hub -> each grove, -> Rimehold, -> the ally hub; each enemy hub -> the map centre and their
## waves' lanes to the groves.
func _in_corridor(p: Vector3) -> bool:
	var a := PLAYER_START
	var segs: Array = [[a, (GROVES[&"A"] as Array)[1]], [(GROVES[&"A"] as Array)[1], (GROVES[&"B"] as Array)[1]],
			[(GROVES[&"A"] as Array)[1], ALLY_START], [a, RIMEHOLD_HALL], [a, Vector3.ZERO], [ALLY_START, Vector3.ZERO],
			[SHADOW_RALLY, Vector3.ZERO], [ICE_RALLY, Vector3.ZERO], [ICE_RALLY, RIMEHOLD_HALL],
			[SHADOW_RALLY, (GROVES[&"B"] as Array)[1]], [ICE_RALLY, Vector3(0.0, 0.0, -40.0)],
			[Vector3(0.0, 0.0, -40.0), (GROVES[&"C"] as Array)[1]]]
	for s: Array in segs:
		if _seg_dist(p, s[0], s[1]) < 3.5:
			return true
	return false


static func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var t := clampf(ap.dot(ab) / maxf(0.001, ab.length_squared()), 0.0, 1.0)
	return (ap - ab * t).length()


func _read_flags() -> void:
	if _flags_read:
		return
	_flags_read = true
	if not flag_override.is_empty():
		return
	var cs := CampaignState.open(campaign_save_path)
	no_save_fallback = not cs.is_completed(&"e2m1")


## A campaign flag of this run (flag_override, else the save; the no-save fallback = false).
func _flag(name: StringName) -> bool:
	_read_flags()
	if not flag_override.is_empty():
		return bool(flag_override.get(String(name), flag_override.get(name, false)))
	if no_save_fallback:
		return false
	return CampaignState.open(campaign_save_path).flag_value(String(name), false) == true \
			or int(CampaignState.open(campaign_save_path).flag_value(String(name), 0)) != 0


# ---------------------------------------------------------------- unit types

func _make_carrier_type() -> UnitType:
	var t := _make_story_type("sprigling", &"seed_carrier", "Seed-carrier", 120.0, 4.2)
	t.armor = 5.0
	t.kill_xp = 20
	return t


## A story unit type: not commandable, no attack, pop 0, from `base_id`'s look.
func _make_story_type(base_id: String, id: StringName, display: String, hp: float, speed: float) -> UnitType:
	var base := UnitType.find(base_id)
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.id = id
	t.display_name = display
	t.is_worker = false
	t.cost = 0
	t.pop = 0
	t.max_hp = hp
	t.move_speed = speed
	t.attack_damage = 0.0
	t.aggro_range = 0.0
	t.armor = 0.0
	t.commandable = false
	t.kill_xp = 15
	t.support_kind = &""
	return t


## The seat's Commander profile: the kingdom's normal knobs, never attacks (the scripted waves are the attacks), 6
## workers, no expansion, at most 12 soldiers at the rally, no towers past S1, no champions / trade / map fill.
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
	p.id = StringName("mission_e2_02_%s" % SEAT_NAMES.get(seat, "bot"))
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
	p.max_soldiers = 12
	p.build_rows = PackedStringArray(["H1", "V1", "S1", "V2"])
	p.rebuild = false
	p.hero_stays_home = true
	p.malrik_joins = AIProfile.MalrikJoins.NEVER
	p.champion_max = 0
	p.trade = false
	p.map_fill = false
	return p


func _add_seat_commander(seat: int) -> Node:
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return null
	var bot: Node = script.new()
	bot.name = "ShadowBot" if seat == SHADOW_SEAT else "Bot%d" % seat
	bot.set(&"team", seat)
	bot.set(&"profile", seat_profile(seat))
	add_child(bot)
	commanders.append(bot)
	return bot


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for seat: int in [SHADOW_SEAT, ICE_SEAT, ALLY_SEAT]:
		fog.reveal(seat, seat_xf(seat, PLAYER_START), FogOfWar.START_REVEAL)
	_setup_champions()   # the companion's guild (apply_to_start adds it); taverns closed

	# --- Fire: Vessa, the save, workers, the army.
	hero = _make_wizard(PLAYER_SEAT)
	_spawn(hero, PLAYER_SEAT, PLAYER_START)
	_claim_wizard(hero, PLAYER_SEAT)
	ItemDrops.ensure_inventory(hero)
	_apply_campaign_start()
	for i in 6:
		var cinder := _spawn(make_unit("cinder_hand"), PLAYER_SEAT, PLAYER_START + Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2))
		cinder.call(&"command_gather", node_of(PLAYER_SEAT, "a" if i < 3 else "b"))
	var rows := [["flame_guard", 6 + (2 if diff == 0 else 0)], ["ember_archer", 4], ["blaze_rider", 2],
			["pyre_adept", 0 if diff == 2 else 2], ["kilnwarden", 1]]
	var army: Array[String] = []
	for row in rows:
		for k in int(row[1]):
			army.append(String(row[0]))
	for i in army.size():
		_spawn(make_unit(army[i]), PLAYER_SEAT, ARMY_POS + Vector3(-4.5 + (i % 6) * 1.6, 0.0, -2.0 + (i / 6) * 1.7))

	# --- Nature: Ysolde's column at Grove A (seat ALLY, scripted, no buildings).
	_spawn_column()

	# --- Shadow: Malrik (the bot) and his start army.
	shadow_hero = _make_wizard(SHADOW_SEAT)
	_spawn(shadow_hero, SHADOW_SEAT, SHADOW_RALLY)
	_claim_wizard(shadow_hero, SHADOW_SEAT)
	raise_wizard(shadow_hero, WIZARD_LEVEL[diff], MALRIK_SPELLS)
	ItemDrops.ensure_inventory(shadow_hero)
	mark_scripted(shadow_hero)
	shadow_hero.died.connect(_on_malrik_died)
	wizard_respawned.connect(_on_e2_wizard_respawned)
	for i in 6:
		var thrall := _spawn(make_unit("gloom_thrall"), SHADOW_SEAT, SHADOW_START + Vector3(4.0 - i * 1.2, 0.0, -4.0 + i * 1.2))
		thrall.call(&"command_gather", node_of(SHADOW_SEAT, "a" if i < 3 else "b"))
	for i in 9:
		var a := float(i) * TAU / 9.0
		_spawn(make_unit("shade" if i < 6 else "nightbolt"), SHADOW_SEAT, SHADOW_RALLY + Vector3(cos(a) * 2.5, 0.0, sin(a) * 2.5))

	# --- Ice: Torvald (the second bot) and his start army.
	torvald = _make_wizard(ICE_SEAT)
	_spawn(torvald, ICE_SEAT, ICE_RALLY)
	_claim_wizard(torvald, ICE_SEAT)
	raise_wizard(torvald, WIZARD_LEVEL[diff], TORVALD_SPELLS)
	ItemDrops.ensure_inventory(torvald)
	mark_scripted(torvald)
	seat_heroes[ICE_SEAT] = torvald
	torvald.died.connect(_on_torvald_died)
	var ice_start := seat_xf(ICE_SEAT, PLAYER_START)
	for i in 6:
		var hauler := _spawn(make_unit("rime_hauler"), ICE_SEAT, ice_start + Vector3(4.0 - i * 1.2, 0.0, 4.0 - i * 1.2))
		hauler.call(&"command_gather", node_of(ICE_SEAT, "a" if i < 3 else "b"))
	for i in 6:
		var a := float(i) * TAU / 6.0
		_spawn(make_unit("rimeshield" if i < 4 else "shardcaster"), ICE_SEAT, ICE_RALLY + Vector3(cos(a) * 2.5, 0.0, sin(a) * 2.5))

	# --- Rimehold: haulers on the Mouth, the garrison.
	var mouth := node_of(PLAYER_SEAT, "rich")
	for i in 3:
		var h := _spawn(make_unit("rime_hauler"), ICE_SEAT, RIMEHOLD_HALL + Vector3(2.0 + i, 0.0, 3.0))
		mark_scripted(h)
		if mouth:
			h.call(&"command_gather", mouth)
		rime_haulers.append(h)
	_spawn_guards()
	_spawn_caches_e2m2()
	_setup_map_fill_e2m2()
	if not _SIM.enabled:
		pass
	var roster := HelperRoster.for_team(PLAYER_SEAT)
	if roster:
		roster.helper_ready.connect(_on_vey_ready)
	if keep:
		keep.destroyed.connect(_on_keep_destroyed)
	_add_seat_commander(SHADOW_SEAT)
	_add_seat_commander(ICE_SEAT)
	var channel := AllyChannel.instance(get_tree(), self)
	channel.time_source = mission_time
	channel.pinged.connect(_on_ally_ping)
	_add_events()
	begin_mission([&"obj_groves", &"obj_rimehold", &"obj_vessa", &"obj_keep", &"sec_carriers", &"sec_points"])
	_build_send_panel()


func _apply_campaign_start() -> void:
	_read_flags()
	if no_save_fallback or not flag_override.is_empty():
		set_meta(&"campaign_flags", flag_override.duplicate())
		force_artifacts(hero, ["ember_crown", "masters_signet"])
		if no_save_fallback:
			var bank := EssenceBank.for_team(PLAYER_SEAT)
			if bank:
				bank.add(NO_SAVE_ESSENCE)
		return
	CampaignState.open(campaign_save_path).apply_to_start(self)


func _spawn_column() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	var a_pos: Vector3 = (GROVES[&"A"] as Array)[1]
	ysolde = _make_wizard(ALLY_SEAT)
	_spawn(ysolde, ALLY_SEAT, a_pos + Vector3(2.0, 0.0, 3.0))
	_claim_wizard(ysolde, ALLY_SEAT)
	raise_wizard(ysolde, 4, YSOLDE_SPELLS)
	ItemDrops.ensure_inventory(ysolde)
	seat_heroes[ALLY_SEAT] = ysolde
	ysolde.death_guard = _ysolde_guard
	var ht := HelperType.find(&"helper_maelis")
	if ht:
		maelis = Helper.new()
		maelis.apply_helper_type(ht, ysolde.level)
		maelis.name = "MaelisStory"
		_spawn(maelis, ALLY_SEAT, a_pos + Vector3(-2.0, 0.0, 3.0))
		maelis.bond_to(ysolde)
		maelis.set_stance(&"escort")
		maelis.died.connect(_on_maelis_died)
	if _wren_type:
		wren = _spawn(Worker.make_unit(_wren_type), ALLY_SEAT, a_pos + Vector3(0.0, 0.0, 5.0))
		wren.death_guard = _wren_guard
	var n := int(CARRIERS_START[diff]) + (4 if _flag(&"e2m1_folk_saved") else 0)
	for i in n:
		_add_carrier(a_pos + Vector3(cos(i * 0.9) * 3.0, 0.0, 4.0 + sin(i * 0.9) * 2.0))
	var i := 0
	for row: Array in [["thornling", 4], ["bloomtender", 2]]:
		for k in int(row[1]):
			var t: UnitType = _warden_types.get(String(row[0]))
			if t == null:
				continue
			var ang := float(i) * TAU / 6.0
			var u := _spawn(Worker.make_unit(t), ALLY_SEAT, a_pos + Vector3(cos(ang) * 4.0, 0.0, sin(ang) * 4.0))
			var guard := 0
			while u.level < 2 and guard < 10:
				guard += 1
				u.add_xp(50)
			column.append(u)
			i += 1
	column_target = &""


func _add_carrier(at: Vector3) -> Unit:
	if _carrier_type == null:
		return null
	var c := _spawn(Worker.make_unit(_carrier_type), ALLY_SEAT, at)
	c.add_to_group(&"seed_carriers")
	mark_scripted(c)
	c.died.connect(_on_carrier_died)
	carriers.append(c)
	return c


func _spawn_guards() -> void:
	var g1 := spawn_group([["rimeshield", 5], ["shardcaster", 3], ["rime_seer", 1], ["frost_mortar", 1], ["rimecarver", 1]],
			G1_POS, 6.0, ICE_SEAT, true, true)
	for u in g1:
		var ab := (u as Node).get_node_or_null(^"CasterAbility")
		if ab and ab.has_method(&"set_autocast"):
			for sid: Variant in CasterKit.SPELLS.keys():
				ab.call(&"set_autocast", sid, true)
	guard_groups[&"G1"] = g1
	guard_groups[&"G2"] = spawn_group([["shade", 3], ["nightbolt", 2]], G2_POS, 2.5, SHADOW_SEAT, true)
	guard_groups[&"G3"] = spawn_group([["rimeshield", 2], ["shardcaster", 1]], G3_POS, 2.0, ICE_SEAT, true)


func _spawn_caches_e2m2() -> void:
	for i in CACHE_SPOTS_E2M2.size():
		var cache := LostCache.new()
		cache.name = "LostCache%d" % i
		cache.rng.seed = MAP_SEED + 11 + i
		cache.match_time_source = match_time
		add_child(cache)
		cache.global_position = CACHE_SPOTS_E2M2[i]
		cache.opened.connect(_on_cache_opened)
		caches.append(cache)


func _setup_map_fill_e2m2() -> void:
	if camps_enabled:
		camp_manager = _add_mapfill_service(CAMP_MANAGER_PATH, "CampManager", &"camp_manager")
		if camp_manager and camp_manager.has_method(&"setup"):
			camp_manager.call(&"setup", CAMP_SPOTS_E2M2)
	for spot: Dictionary in POINT_SPOTS_E2M2:
		for seat: int in [PLAYER_SEAT, SHADOW_SEAT]:
			fog.reveal(seat, spot["pos"], MAPFILL_REVEAL)
	for s: Node in [_service(capture_points), _service(camp_manager)]:
		if s and s.has_signal(&"message") and not s.is_connected(&"message", _on_guild_message):
			s.connect(&"message", _on_guild_message)


## The "Send Ysolde: <grove>" buttons (first cut of the grove card's button; top right, until E14).
func _build_send_panel() -> void:
	var rows: Array = []
	for id: StringName in [&"A", &"B", &"C"]:
		rows.append([Loc.t(BUTTON_SEND, {"grove": Loc.t((GROVES[id] as Array)[0])}), send_ysolde.bind(id)])
	_send_panel = mission_button_panel("SendYsoldePanel", rows)


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_groves", false), objective_text(&"obj_rimehold", false), BRIEFING_PING_LINE],
		"rule": "%s · %s" % [Loc.sink(objective_text(&"obj_vessa")), Loc.sink(objective_text(&"obj_keep"))],
	}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_groves":
			if with_counter:
				return "Plant Ysolde's groves along Fire's line (%d / 3)" % groves_standing()
			return "Plant Ysolde's groves along Fire's line"
		&"obj_rimehold":
			return "Break Torvald's forward fort (Rimehold)"
		&"obj_vice":
			if with_counter and vice_left >= 0.0:
				var s := int(ceil(vice_left))
				if vice_paused:
					return "Hold together against both kingdoms (%d:%02d) (paused: replant)" % [s / 60, s % 60]
				return "Hold together against both kingdoms (%d:%02d)" % [s / 60, s % 60]
			return "Hold together against both kingdoms"
		&"obj_vessa":
			return "Vessa must survive"
		&"obj_keep":
			return "The Emberwatch must stand"
		&"obj_ally":
			return "Nature must not fall again"
		&"sec_carriers":
			if with_counter:
				return "Lose no more than 2 seed-carriers (%d lost)" % carriers_lost
			return "Lose no more than 2 seed-carriers"
		&"sec_points":
			if with_counter:
				return "Hold 3 capture points at once (%d / 3)" % mini(3, points_held())
			return "Hold 3 capture points at once"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_groves":
			var spots: Array = []
			for sid: StringName in sites:
				if not (sites[sid] as GroveSite).is_planted():
					spots.append((sites[sid] as GroveSite).global_position)
			return {"progress": groves_standing(), "goal": 3, "counter": "%d / 3" % groves_standing(), "positions": spots}
		&"obj_rimehold":
			return {"position": RIMEHOLD_HALL}
		&"obj_vice":
			return {"countdown": vice_left, "time_left": vice_left}
		&"sec_carriers":
			return {"progress": carriers_lost, "goal": 2, "counter": "%d" % carriers_lost}
		&"sec_points":
			return {"progress": mini(3, points_held()), "goal": 3, "counter": "%d / 3" % mini(3, points_held())}
	return {}


## Says line `n` (L<n>; 34 = L11b) once per run.
func say_l(n: int) -> void:
	if _said.has(n):
		return
	_said[n] = true
	said.append(n)
	say_line(n)


func groves_standing() -> int:
	var n := 0
	for id: StringName in sites:
		if (sites[id] as GroveSite).is_planted():
			n += 1
	return n


## Capture points owned by side 0 (Fire + Nature) right now.
func points_held() -> int:
	var cp := _service(capture_points)
	if cp == null or not cp.has_method(&"points"):
		return 0
	var n := 0
	for p: Node in cp.call(&"points"):
		if p.get(&"owner_team") != null and int(p.get(&"owner_team")) == PLAYER_SEAT:
			n += 1
	return n


# ---------------------------------------------------------------- events

## E1: e2m2_muster (HOLD 0:18; fallback = the camera on Vessa + L1-L3).
func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e2m2_muster", func() -> void:
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position)
		say_l(1)
		say_l(2)
		say_l(3))


func _add_events() -> void:
	after(INTRO_LINES_END, _e2_ysolde_plants)
	after(W1_AT, _fire_wave.bind(&"W1"))
	after(W2_AT, _fire_wave.bind(&"W2"))
	after(W3_AT, _fire_wave.bind(&"W3"))
	after(W4_AT, _fire_wave.bind(&"W4"))
	after(W5_AT, _fire_wave.bind(&"W5"))
	after(RAID_FIRST, _raid)
	add_event(&"E6", func() -> bool: return points_held() >= 1, func() -> void:
		say_l(8)
		hud.show_message(HINT_POINTS, 8.0))
	add_event(&"E8", func() -> bool:
		return keep != null and is_instance_valid(keep) and keep.is_alive() and keep.can_upgrade() == "" \
				and int(keep.tier) == 2, func() -> void: hud.show_message(HINT_CITADEL, 12.0))
	add_event(&"E9", func() -> bool: return keep != null and is_instance_valid(keep) and int(keep.tier) >= 3, _e9_citadel)
	add_event(&"E11", func() -> bool: return hero_alive() and _near_rimehold(hero.global_position, RIMEHOLD_NEAR),
			func() -> void:
				say_l(12)
				say_l(13))
	add_event(&"E18", func() -> bool: return points_held() >= 3, func() -> void:
		say_l(25)
		if objective_state("sec_points") == "active":
			set_objective(&"sec_points", "done"))
	add_event(&"relief", func() -> bool:
		for b in rimehold:
			if is_instance_valid(b) and b.is_alive() and b.hp < b.max_hp * 0.6:
				return true
		return false, _send_relief)


## E2 (0:20): Ysolde plants Grove A on her own: L4-L5, the hint.
func _e2_ysolde_plants() -> void:
	if is_ending():
		return
	fire_once(&"E2")
	column_target = &"A"
	say_l(4)
	say_l(5)
	hud.show_message(HINT_GROVE_A, 8.0)


func _near_rimehold(p: Vector3, r: float) -> bool:
	for b in rimehold:
		if is_instance_valid(b) and b.is_alive() and _flat(b.global_position, p) <= r:
			return true
	return false


## E9: the Citadel stands: L10, the call hint, the spotlight (the Saboteur) and its moment hint.
func _e9_citadel() -> void:
	say_l(10)
	hud.show_message(HINT_CALL, 10.0)
	show_spotlight()
	if objective_state("obj_rimehold") == "active":
		after(12.0, func() -> void:
			if not is_ending() and objective_state("obj_rimehold") == "active":
				hud.show_message(HINT_SABOTEUR, 8.0))


## E10: Old Vey arrives: L11 (L11b when he was not called in e2m1).
func _on_vey_ready(_helper: Helper) -> void:
	if is_ending() or vey_arrived:
		return
	vey_arrived = true
	fire_once(&"E10")
	if _flag(&"e2m1_vey_called"):
		say_l(11)
	else:
		say_l(34)


# ---------------------------------------------------------------- pings and Ysolde's column

## The player's ping on the ALLY channel (AllyChannel.pinged): a grove site -> the column goes there; retreat -> the
## nearest planted grove; anything else -> before E14 the column holds there, after E14 the ally's L2 answer.
func _on_ally_ping(p: Dictionary) -> void:
	if is_ending() or int(p["from_seat"]) != PLAYER_SEAT:
		return
	var ch := AllyChannel.instance(get_tree())
	var kind: StringName = p["kind"]
	var pos: Vector3 = p["pos"]
	var site := site_near(pos, 4.0)
	if kind == &"retreat":
		var g := _nearest_planted(ysolde.global_position if ysolde else pos)
		column_target = g
		column_hold = Vector3.INF
		_ally_order.clear()
		if ch:
			ch.answer(int(p["id"]), ALLY_SEAT, &"on_my_way", AllyChannel.ANSWER_FALLING_BACK)
		say(&"ysolde", AllyChannel.ANSWER_FALLING_BACK)
		return
	var text := AllyChannel.ANSWER_ON_MY_WAY if kind == &"attack" else AllyChannel.ANSWER_BEHIND
	if site != &"" and not ally_active:
		column_target = site
		column_hold = Vector3.INF
	elif not ally_active:
		column_target = &""
		column_hold = pos
	else:
		_ally_order = {"pos": pos, "until": mission_time() + ALLY_HELP_TIME, "calm": 0.0}
		if site != &"":
			column_target = site
	if ch:
		ch.answer(int(p["id"]), ALLY_SEAT, &"on_my_way", text)
	say(&"ysolde", text)
	if site != &"" and fire_once(&"E4"):
		after(2.0, func() -> void: say_l(7))


## Sends Ysolde's column to grove `id` (the panel buttons; tests): an AllyChannel `defend` ping on the site.
func send_ysolde(id: StringName) -> String:
	if not sites.has(id):
		return "Unknown grove"
	var ch := AllyChannel.instance(get_tree(), self)
	return ch.ping(&"defend", (sites[id] as GroveSite).global_position, PLAYER_SEAT)


## A level hook of AllyChannel's Alt+click: a grove site under the cursor means `defend`.
func ping_context(pos: Vector3) -> StringName:
	return &"defend" if site_near(pos, 4.0) != &"" else &""


## The grove site whose ring (+ margin) holds `pos`, else &"".
func site_near(pos: Vector3, margin: float) -> StringName:
	for id: StringName in sites:
		var s: GroveSite = sites[id]
		if _flat(s.global_position, pos) <= s.radius + margin:
			return id
	return &""


func _nearest_planted(from: Vector3) -> StringName:
	var best := &""
	var best_d := INF
	for id: StringName in sites:
		var s: GroveSite = sites[id]
		if s.is_planted():
			var d := _flat(s.global_position, from)
			if d < best_d:
				best_d = d
				best = id
	return best


func _ysolde_up() -> bool:
	return ysolde != null and is_instance_valid(ysolde) and ysolde.is_alive() and _ysolde_kneel_left <= 0.0


## Where the column stands: the target site, a ping spot, the last planted grove.
func column_goal() -> Vector3:
	if column_target != &"" and sites.has(column_target):
		return (sites[column_target] as GroveSite).global_position
	if column_hold != Vector3.INF:
		return column_hold
	var g := _nearest_planted(ysolde.global_position if ysolde else PLAYER_START)
	if g != &"":
		return (sites[g] as GroveSite).global_position
	return (GROVES[&"A"] as Array)[1]


## Ysolde, her fighters and the carriers (every 0.5 s before E14; the carriers' replanting after it).
func _tick_column() -> void:
	carriers = carriers.filter(func(c: Variant) -> bool: return is_instance_valid(c) and (c as Unit).is_alive())
	column = column.filter(func(c: Variant) -> bool: return is_instance_valid(c) and (c as Unit).is_alive())
	_tick_seed_supply()
	if ally_active:
		_tick_carriers_after_e14()
		return
	if not _ysolde_up():
		return
	var goal := column_goal()
	var yp := ysolde.global_position
	# Ysolde: to the goal (2 m south of a ring's centre: she holds the ring), fighting what comes on the way.
	var stand := goal + Vector3(0.0, 0.0, 2.0)
	if _flat(yp, stand) > 3.0 and ysolde.attack_target == null:
		if not ysolde.is_attack_moving() or _flat(ysolde.get_meta(&"e2m2_goal", Vector3.INF), stand) > 1.0:
			ysolde.command_attack_move(stand)
			ysolde.set_meta(&"e2m2_goal", stand)
	# Her fighters (max COLUMN_MAX) stay with her.
	for u in column:
		var cu := u as Unit
		if cu.attack_target == null and _flat(cu.global_position, yp) > 6.0:
			cu.command_attack_move(yp + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0)))
	_tick_carrier_orders(yp)


func _tick_carrier_orders(yp: Vector3) -> void:
	var site: GroveSite = sites.get(column_target) if column_target != &"" else null
	var planting := site != null and not site.is_planted() and _flat(yp, site.global_position) <= site.radius + 6.0
	var chosen: Array = []
	if planting:
		var by_d := carriers.duplicate()
		by_d.sort_custom(func(a: Variant, b: Variant) -> bool:
			return _flat((a as Unit).global_position, site.global_position) < _flat((b as Unit).global_position, site.global_position))
		chosen = by_d.slice(0, 2)
	for c: Variant in carriers:
		var cu := c as Unit
		if chosen.has(c):
			var i := chosen.find(c)
			var spot := site.global_position + Vector3(-1.5 if i == 0 else 1.5, 0.0, 0.0)
			if _flat(cu.global_position, spot) > 1.0 and not cu.has_move_order():
				cu.command_move(spot)
			cu.set_meta(&"e2m2_walking", _flat(cu.global_position, spot) > site.radius)
			continue
		# Under attack with Ysolde far: the nearest planted grove or the Fire keep.
		var threatened := cu.hp < cu.max_hp and _hostile_near(cu.global_position, 6.0)
		if threatened and _flat(cu.global_position, yp) > CARRIER_FLEE:
			var safe := _alive_pos(keep, PLAYER_START)
			var g := _nearest_planted(cu.global_position)
			if g != &"" and _flat((sites[g] as GroveSite).global_position, cu.global_position) < _flat(safe, cu.global_position):
				safe = (sites[g] as GroveSite).global_position
			cu.command_move(safe)
			cu.set_meta(&"e2m2_walking", true)
			continue
		var d := _flat(cu.global_position, yp)
		if d > 5.0:
			var dir := cu.global_position - yp
			dir.y = 0.0
			dir = dir.normalized() if dir.length() > 0.1 else Vector3(0.0, 0.0, 1.0)
			cu.command_move(yp + dir * 3.5)
		cu.set_meta(&"e2m2_walking", d > 6.0)


## The seed never runs out for good: fewer than 2 carriers while a grove is left to plant (obj_groves, or a Vice replant)
## = one new carrier every SEED_RESUPPLY s, at Ysolde before E14, at the Heartwood after it.
func _tick_seed_supply() -> void:
	if vice_done or carriers.size() >= 2 or groves_standing() >= sites.size():
		_resupply_at = -1.0
		return
	var now := mission_time()
	if _resupply_at < 0.0:
		_resupply_at = now + SEED_RESUPPLY
		return
	if now < _resupply_at:
		return
	_resupply_at = now + SEED_RESUPPLY
	var at := ALLY_START
	if ally_active:
		at = _alive_pos(heartwood, ALLY_START)
	elif ysolde and is_instance_valid(ysolde) and ysolde.is_alive():
		at = ysolde.global_position
	_add_carrier(at + Vector3(randf_range(-2.0, 2.0), 0.0, 3.0))


## After E14 the carriers (no longer led) replant a fallen grove on their own: the 2 nearest walk to the site.
func _tick_carriers_after_e14() -> void:
	var todo: StringName = &""
	for id: StringName in [&"A", &"B", &"C"]:
		if not (sites[id] as GroveSite).is_planted():
			todo = id
			break
	var home := _alive_pos(heartwood, ALLY_START)
	if todo == &"" or carriers.size() < 2:
		for c: Variant in carriers:
			var cu := c as Unit
			if _flat(cu.global_position, home) > 8.0 and not cu.has_move_order():
				cu.command_move(home + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0)))
			cu.set_meta(&"e2m2_walking", _flat(cu.global_position, home) > 10.0)
		return
	column_target = todo
	var site: GroveSite = sites[todo]
	var by_d := carriers.duplicate()
	by_d.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _flat((a as Unit).global_position, site.global_position) < _flat((b as Unit).global_position, site.global_position))
	for i in by_d.size():
		var cu := by_d[i] as Unit
		if i < 2:
			var spot := site.global_position + Vector3(-1.5 if i == 0 else 1.5, 0.0, 0.0)
			if _flat(cu.global_position, spot) > 1.0 and not cu.has_move_order():
				cu.command_move(spot)
			cu.set_meta(&"e2m2_walking", _flat(cu.global_position, spot) > site.radius)
		elif _flat(cu.global_position, home) > 8.0 and not cu.has_move_order():
			cu.command_move(home)


## The planting channel of every unplanted site (every frame): 2 carriers inside the ring, no enemy within 8 m.
func _tick_planting(delta: float) -> void:
	var t := float(by_difficulty(PLANT_TIME))
	for id: StringName in sites:
		var s: GroveSite = sites[id]
		if s.is_planted() or id != column_target:   # only the site Ysolde (or, after E14, the carriers) plants
			continue
		var inside: Array = []
		for c: Variant in carriers:
			if is_instance_valid(c) and (c as Unit).is_alive() and _flat((c as Unit).global_position, s.global_position) <= s.radius:
				inside.append(c)
		if inside.is_empty() and s.progress <= 0.0:
			continue
		var enemy := _hostile_near(s.global_position, PAUSE_RADIUS)
		var paused := inside.size() < 2 or enemy
		if not paused and not _plant_announced.has(id):
			_plant_announced[id] = true
			hud.show_message(Loc.t(MSG_PLANTING, {"grove": Loc.t(s.grove_name)}), 4.0)
			if id == &"B" and fire_once(&"E12"):
				say_l(14)
		if paused:
			if enemy and s.progress > 0.0 and not _paused_msg.has(id):
				_paused_msg[id] = true
				hud.show_message(MSG_PAUSED, 4.0)
			s.set_progress(s.progress, true)
			continue
		s.set_progress(s.progress + delta / t, false)
		if s.progress >= 1.0:
			_plant(id, inside.slice(0, 2))


## Diagnostics (sims): carriers inside the site's ring and the nearest hostile within the pause radius.
func site_debug(id: StringName) -> String:
	var s: GroveSite = sites.get(id)
	if s == null:
		return "-"
	var inside := 0
	for c: Variant in carriers:
		if is_instance_valid(c) and (c as Unit).is_alive() and _flat((c as Unit).global_position, s.global_position) <= s.radius:
			inside += 1
	var who := ""
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), PLAYER_SEAT) and int(u.team) != Unit.Team.NEUTRAL \
				and not is_dormant(u) and _flat(u.global_position, s.global_position) <= PAUSE_RADIUS:
			who = "%s(t%d, %.1f m)" % [u.unit_type.id if u.unit_type else u.name, int(u.team), _flat(u.global_position, s.global_position)]
	return "inside %d carriers %d lost %d ysolde %s %s" % [inside, carriers.size(), carriers_lost,
			"up" if _ysolde_up() else "down", who]


## True when a living hostile (to Fire's side) non-dormant unit stands within r of `at`.
func _hostile_near(at: Vector3, r: float) -> bool:
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), PLAYER_SEAT) and int(u.team) != Unit.Team.NEUTRAL \
				and not is_dormant(u) and _flat(u.global_position, at) <= r:
			return true
	return false


## The planting completes: the 2 carriers become the grove (spent, not lost), the grove building rises.
func _plant(id: StringName, spent: Array) -> void:
	var s: GroveSite = sites[id]
	for c: Variant in spent:
		var cu := c as Unit
		cu.set_meta(&"e2m2_spent", true)
		carriers.erase(cu)
		cu.leave_map()
	var t := MissionGrove.make_type(float(by_difficulty(GROVE_HP)), SAP_RADIUS, SAP_STATS, ally_active)
	_grove_types[id] = t
	var g := MissionGrove.new()
	g.building_type = t
	g.name = "Grove%s" % id
	g.team = ALLY_SEAT
	g.site = s
	g.position = build_grid.snap(s.global_position, t.footprint)
	nav_region.add_child(g, true)
	g.destroyed.connect(_on_grove_destroyed.bind(id))
	s.set_planted(g)
	s.sprout_left = SPROUT_EVERY
	s.seed_left = float(by_difficulty(SEED_EVERY))
	flash_ring(s.global_position, s.radius)
	_plant_announced.erase(id)
	_paused_msg.erase(id)
	var n := groves_standing()
	hud.show_message(Loc.t(MSG_GROWING, {"grove": Loc.t(s.grove_name), "n": n}), 4.0)
	set_objective(&"obj_groves", objective_state("obj_groves") if objective_state("obj_groves") == "done" else "active")
	if column_target == id:
		column_target = &""
	if id == &"A" and fire_once(&"E3"):
		play_cutscene(&"e2m2_first_grove", func() -> void:
			say_l(6)
			hud.show_message(HINT_NEXT_GROVE, 10.0))
	if n >= 3 and not ally_active:
		_e14_heartwood()
	_update_vice_pause()


func _on_grove_destroyed(_b: Building, id: StringName) -> void:
	var s: GroveSite = sites.get(id)
	if s == null:
		return
	after(2.0, func() -> void:
		if is_instance_valid(s):
			s.set_planted(null))
	if is_ending():
		return
	if fire_once(&"E19"):
		say_l(26)
	set_objective(&"obj_groves", objective_state("obj_groves") if objective_state("obj_groves") == "done" else "active")
	_update_vice_pause()


## Sprouts (2 Thornlings / 60 s, max 4 alive per grove) and Seedbed (1 carrier / 90 s, max 2 waiting) of planted groves.
func _tick_groves(delta: float) -> void:
	for id: StringName in sites:
		var s: GroveSite = sites[id]
		if not s.is_planted():
			continue
		s.sprouts = s.sprouts.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
		s.sprout_left -= delta
		if s.sprout_left <= 0.0:
			s.sprout_left = SPROUT_EVERY
			for i in 2:
				if s.sprouts.size() >= SPROUT_MAX:
					break
				var t: UnitType = _warden_types.get("thornling") if not ally_active else UnitType.find("thornling")
				if t == null:
					continue
				var u := _spawn(Worker.make_unit(t), ALLY_SEAT, s.global_position + Vector3(2.5 - 5.0 * i, 0.0, 3.0))
				s.sprouts.append(u)
				if not ally_active and column.size() < COLUMN_MAX:
					column.append(u)
		s.seed_left -= delta
		if s.seed_left <= 0.0:
			s.seed_left = float(by_difficulty(SEED_EVERY))
			var waiting := 0
			for c: Variant in carriers:
				if is_instance_valid(c) and _flat((c as Unit).global_position, s.global_position) <= s.radius + 4.0:
					waiting += 1
			if waiting < SEED_MAX_WAITING:
				_add_carrier(s.global_position + Vector3(0.0, 0.0, 2.0))


func _on_carrier_died(u: Unit) -> void:
	if u.has_meta(&"e2m2_spent") or is_ending():
		return
	carriers_lost += 1
	if objective_state("sec_carriers") == "active":
		set_objective(&"sec_carriers", "active")
		if carriers_lost >= 3:
			set_objective(&"sec_carriers", "failed")
			if fire_once(&"E20"):
				say_l(27)


## D8: before E14 Ysolde kneels at 1 HP for 10 s (untargetable) and stands at 50 %. After E14: the 2v2 respawn.
func _ysolde_guard(_attacker: Variant) -> bool:
	if ysolde == null or not is_instance_valid(ysolde):
		return false
	if ally_active:
		return false
	ysolde.hp = 1.0
	if _ysolde_kneel_left <= 0.0:
		_ysolde_kneel_left = YSOLDE_KNEEL
		set_dormant(ysolde, true)
	return true


func _wren_guard(_attacker: Variant) -> bool:
	if wren == null or not is_instance_valid(wren):
		return false
	wren.hp = 1.0
	if _wren_kneel_left <= 0.0:
		_wren_kneel_left = WREN_KNEEL
		set_dormant(wren, true)
	return true


func _tick_kneels(delta: float) -> void:
	if _ysolde_kneel_left > 0.0:
		_ysolde_kneel_left -= delta
		if _ysolde_kneel_left <= 0.0 and ysolde and is_instance_valid(ysolde):
			set_dormant(ysolde, false)
			ysolde.death_guard = _ysolde_guard
			ysolde.hp = ysolde.max_hp * 0.5
	if _wren_kneel_left > 0.0:
		_wren_kneel_left -= delta
		if _wren_kneel_left <= 0.0 and wren and is_instance_valid(wren):
			set_dormant(wren, false)
			wren.death_guard = _wren_guard
			wren.hp = wren.max_hp * 0.5


## Wren walks with Ysolde; after E3 she pings the nearest unplanted site on the minimap every 30 s.
func _tick_wren(delta: float) -> void:
	if wren == null or not is_instance_valid(wren) or _wren_kneel_left > 0.0:
		return
	var lead: Vector3 = ysolde.global_position if ysolde and is_instance_valid(ysolde) and ysolde.is_alive() \
			else _alive_pos(heartwood, (GROVES[&"A"] as Array)[1])
	if _flat(wren.global_position, lead) > 6.0:
		var dir := wren.global_position - lead
		dir.y = 0.0
		dir = dir.normalized() if dir.length() > 0.1 else Vector3(-1.0, 0.0, 1.0).normalized()
		wren.command_move(lead + dir * 4.5)
	if not has_fired(&"E3"):
		return
	_ping_left -= delta
	if _ping_left <= 0.0:
		_ping_left = PING_EVERY
		var best := Vector3.INF
		var best_d := INF
		for id: StringName in sites:
			var s: GroveSite = sites[id]
			if not s.is_planted() and _flat(s.global_position, lead) < best_d:
				best_d = _flat(s.global_position, lead)
				best = s.global_position
		if best != Vector3.INF and hud and hud.minimap:
			hud.minimap.ping(best)


## Maelis falls: back at Ysolde's side 45 s later (D5: never lost).
func _on_maelis_died(_u: Unit) -> void:
	after(45.0, func() -> void:
		if is_ending() or maelis == null or not is_instance_valid(maelis) or maelis.is_alive():
			return
		var at: Vector3 = ysolde.global_position if ysolde and is_instance_valid(ysolde) else ALLY_START
		maelis.respawn(at + Vector3(2.0, 0.0, 2.0)))


# ---------------------------------------------------------------- E14: the Heartwood, the ally seat

func _e14_heartwood() -> void:
	if ally_active or is_ending():
		return
	fire_once(&"E14")
	e14_time = mission_time()
	set_objective(&"obj_groves", "done")
	play_cutscene(&"e2m2_heartwood", func() -> void:
		say_l(18)
		say_l(19)
		say_l(20))
	_activate_ally()
	set_objective(&"obj_ally", "active")
	hud.show_message(MSG_TWO_V_TWO, 4.0)
	after(W6_AFTER, _fire_wave.bind(&"W6"))
	if _send_panel and is_instance_valid(_send_panel):
		_send_panel.queue_free()
	_check_vice_start()


func _activate_ally() -> void:
	ally_active = true
	var rows := [["sprigling", 5]]
	var nodes := [node_of(ALLY_SEAT, "a"), node_of(ALLY_SEAT, "b")]
	var out := activate_seat(ALLY_SEAT, &"nature", {
		"keep": {"type": "nature_keep", "pos": ALLY_KEEP_POS, "tier": 2},
		"buildings": [["nature_barracks", ALLY_HALL_POS], ["nature_hollow", ALLY_HOLLOWS[0]], ["nature_hollow", ALLY_HOLLOWS[1]]],
		"workers": [["sprigling", 3, nodes[0]], ["sprigling", 2, nodes[1]]],
		"start": ALLY_START,
		"crystals": 300,
	})
	heartwood = out["keep"] as Keep
	if heartwood:
		flash_ring(heartwood.global_position, 6.0)
		heartwood.destroyed.connect(func(_b: Building) -> void: _ally_falls())   # the Vice needs it: no soft-lock
	var _unused := rows
	# The column joins the kingdom: no more guest pop, the grove units and Ysolde's fighters go to her Commander.
	for u: Variant in column:
		if is_instance_valid(u):
			(u as Unit).command_stop()
	column.clear()
	for id: StringName in _grove_types:
		(_grove_types[id] as BuildingType).counts_for_defeat = true
	if ysolde and is_instance_valid(ysolde):
		ysolde.death_guard = Callable()
		if _ysolde_kneel_left > 0.0:
			_ysolde_kneel_left = 0.0
			set_dormant(ysolde, false)
			ysolde.hp = ysolde.max_hp * 0.5
		ysolde.died.connect(_on_ysolde_died)
	ally_commander = _add_seat_commander(ALLY_SEAT)


## After E14: Ysolde comes back at the Heartwood after 30 + 15 s per death (the 2v2 rule).
func _on_ysolde_died(_u: Unit) -> void:
	if is_ending():
		return
	_ysolde_deaths += 1
	hud.show_message(MSG_YSOLDE_FELL, 4.0)
	_respawn_left[ALLY_SEAT] = minf(90.0, 30.0 + 15.0 * float(_ysolde_deaths))


## The ally's L1 (an enemy fighter within 28 m of a Fire building) and L2 (help / defend ping) answers after E14:
## its soldiers and Ysolde attack-move there; over when the spot is calm for 15 s, or after 60 s.
func _tick_ally_brain(delta: float) -> void:
	if not ally_active:
		return
	var now := mission_time()
	if _ally_order.is_empty():
		var intruder := _fire_base_intruder()
		if intruder != Vector3.INF:
			_ally_order = {"pos": intruder, "until": now + ALLY_HELP_TIME, "calm": 0.0, "l1": true}
			var ch := AllyChannel.instance(get_tree())
			if ch and fire_once(&"ally_l1_line"):
				ch.answer(0, ALLY_SEAT, &"on_my_way", AllyChannel.ANSWER_BASE)
	if _ally_order.is_empty():
		return
	var pos: Vector3 = _ally_order["pos"]
	if _hostile_near(pos, 20.0):
		_ally_order["calm"] = 0.0
	else:
		_ally_order["calm"] = float(_ally_order["calm"]) + delta
	if float(_ally_order["calm"]) >= ALLY_CALM_TIME or now >= float(_ally_order["until"]):
		for u in _ally_fighters(true):
			u.remove_from_group(SCRIPTED_GROUP)
			u.remove_meta(SCRIPTED_GROUP)
			u.remove_meta(&"e2m2_ally_order")
		_ally_order.clear()
		return
	for u in _ally_fighters(false):
		if not u.has_meta(&"e2m2_ally_order"):
			u.set_meta(&"e2m2_ally_order", true)
			mark_scripted(u)
		if u.attack_target == null and (not u.is_attack_moving() or _flat(u.global_position, pos) > 30.0) \
				and _flat(u.global_position, pos) > 6.0:
			u.command_attack_move(pos)


## The ALLY seat's soldiers and Ysolde (not workers, carriers, Wren, Maelis); `ordered_only` = those under an order.
func _ally_fighters(ordered_only: bool) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != ALLY_SEAT or u.is_worker() or u == wren or u == maelis \
				or u.is_in_group(&"seed_carriers"):
			continue
		if ordered_only and not u.has_meta(&"e2m2_ally_order"):
			continue
		out.append(u)
	return out


func _fire_base_intruder() -> Vector3:
	var base := Building.for_team(PLAYER_SEAT)
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or not Teams.is_hostile(int(u.team), PLAYER_SEAT) or int(u.team) == Unit.Team.NEUTRAL \
				or u.is_worker() or is_dormant(u):
			continue
		for b in base:
			if b.is_alive() and _flat(b.global_position, u.global_position) <= ALLY_DEFEND_RADIUS:
				return u.global_position
	return Vector3.INF


# ---------------------------------------------------------------- Rimehold

func _on_rimehold_destroyed(_b: Building) -> void:
	if is_ending():
		return
	for b in rimehold:
		if is_instance_valid(b) and b.is_alive() and b != _b:
			return
	fire_once(&"E15")
	say_l(21)
	set_objective(&"obj_rimehold", "done")
	for h: Variant in rime_haulers:
		if is_instance_valid(h) and (h as Unit).is_alive():
			(h as Unit).command_move(_alive_pos(ice_keep, ICE_RALLY))
			var hu := h as Unit
			after(30.0, func() -> void:
				if is_instance_valid(hu) and hu.is_alive():
					hu.leave_map())
	_check_vice_start()


## Once, the first time a Rimehold building drops below 60 %: 4 Rimeshields + 2 Shardcasters from Torvald's hall.
func _send_relief() -> void:
	if _relief_sent or is_ending() or objective_state("obj_rimehold") != "active":
		return
	_relief_sent = true
	var units := spawn_wave_at(_wave_rows(&"RELIEF"), _side_spawn(&"ice_home"), ICE_SEAT, _ice_filter)
	wave_units[&"RELIEF"] = units
	for u in units:
		order_wave(u as Unit, &"relief", RIMEHOLD_HALL)


## The Emberwatch reserve (header): the safety net after a wiped army.
func _tick_reserve() -> void:
	if reserves_sent >= RESERVE_MAX or mission_time() < RESERVE_FROM or mission_time() - _reserve_at < RESERVE_GAP 			or not hero_alive():
		return
	var eco := Economy.for_team(PLAYER_SEAT)
	if eco == null or eco.crystals >= RESERVE_BROKE:
		return
	var soldiers := 0
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == PLAYER_SEAT and u.is_alive() and u != hero and not u.has_method(&"command_gather") 				and u.is_commandable():
			soldiers += 1
			if soldiers > RESERVE_BELOW:
				return
	reserves_sent += 1
	_reserve_at = mission_time()
	var at := RALLY_SPOT
	if keep != null and is_instance_valid(keep) and keep.is_alive():
		at = keep.global_position + (RALLY_SPOT - keep.global_position).normalized() * 6.0
	var i := 0
	for row: Array in RESERVE_ROWS:
		for k in int(row[1]):
			var a := float(i) * 2.39996
			var r := 1.0 + 0.45 * sqrt(float(i))
			_spawn(make_unit(String(row[0])), PLAYER_SEAT, at + Vector3(cos(a) * r, 0.0, sin(a) * r))
			i += 1
	eco.add(RESERVE_CRYSTALS)
	hud.show_message(MSG_RESERVE, 6.0)


# ---------------------------------------------------------------- waves

func _side_spawn(side: StringName) -> Vector3:
	match side:
		&"ice":
			if rimehold_hall and is_instance_valid(rimehold_hall) and rimehold_hall.is_alive() and rimehold_hall is TrainingBuilding:
				return (rimehold_hall as TrainingBuilding).spawn_point()
			return _side_spawn(&"ice_home")
		&"ice_home":
			if ice_hall and is_instance_valid(ice_hall) and ice_hall.is_alive() and ice_hall is TrainingBuilding:
				return (ice_hall as TrainingBuilding).spawn_point()
			var k := keep_of(ICE_SEAT)
			return k.spawn_point() if k else ICE_CORNER
	if gloom_hall and is_instance_valid(gloom_hall) and gloom_hall.is_alive() and gloom_hall is TrainingBuilding:
		return (gloom_hall as TrainingBuilding).spawn_point()
	var sk := keep_of(SHADOW_SEAT)
	return sk.spawn_point() if sk else SHADOW_CORNER


## The Ice rule: 40 % fewer units (rounded down) once Rimehold is broken.
func _ice_filter(n: int) -> int:
	return n - int(floor(float(n) * 0.4)) if objective_state("obj_rimehold") == "done" else n


func _wave_rows(id: StringName) -> Array:
	var w: Dictionary = WAVES[id]
	var out: Array = []
	var diff := clampi(mission_difficulty, 0, 2)
	for row: Array in w["rows"]:
		var tid := StringName(row[0])
		if diff == 0 and (EASY_SKIP.has(tid) or (tid == &"shadow_knight" and id == &"W4")):
			continue
		if tid == &"rime_colossus" and objective_state("obj_rimehold") == "done":
			continue
		out.append(row)
	return out


func _fire_wave(id: StringName) -> void:
	if is_ending() or vice_done or waves_fired.has(id):
		return
	waves_fired.append(id)
	var w: Dictionary = WAVES[id]
	var ice: bool = w["side"] == &"ice"
	var from := _side_spawn(&"ice" if id == &"W1" else (&"ice_home" if ice else &"shadow"))
	var units := spawn_wave_at(_wave_rows(id), from, ICE_SEAT if ice else SHADOW_SEAT, _ice_filter if ice else Callable())
	var diff := clampi(mission_difficulty, 0, 2)
	match id:
		&"W1":
			for u in units:
				order_wave(u as Unit, &"point", _w1_target())
		&"W2":
			for u in units:
				order_wave(u as Unit, &"ysolde", column_goal())
			say_l(9)
		&"W3":
			_torvald_home = false
			if torvald and is_instance_valid(torvald) and torvald.is_alive():
				units.append(torvald)
			for u in units:
				order_wave(u as Unit, &"grove_then_hero", PLAYER_START)
			say_l(15)
		&"W4":
			_malrik_home = false
			if shadow_hero and is_instance_valid(shadow_hero) and shadow_hero.is_alive():
				units.append(shadow_hero)
			for u in units:
				order_wave(u as Unit, &"grove_b", (GROVES[&"B"] as Array)[1])
			say_l(16)
		&"W5":
			for u in units:
				order_wave(u as Unit, &"grove_c_keep", (GROVES[&"C"] as Array)[1])
			say_l(17)
		&"W6":
			for u in units:
				order_wave(u as Unit, &"heartwood", ALLY_KEEP_POS)
		&"VS", &"VK", &"VH":
			if id == &"VS":
				raise_wizard(shadow_hero, WIZARD_VICE_LEVEL[diff], [&"shadow_lance"])
				_malrik_home = false
				if shadow_hero.is_alive():
					units.append(shadow_hero)
			for u in units:
				order_wave(u as Unit, &"vice_shadow", (GROVES[&"B"] as Array)[1])
		&"VI":
			raise_wizard(torvald, WIZARD_VICE_LEVEL[diff], [&"rime_bolt"])
			_torvald_home = false
			if torvald.is_alive():
				units.append(torvald)
			for u in units:
				order_wave(u as Unit, &"vice_ice", BRIDGE_SPOT)
	wave_units[id] = units


func _w1_target() -> Vector3:
	for id: StringName in [&"A", &"B", &"C"]:
		var s: GroveSite = sites[id]
		if not s.is_planted() and s.progress > 0.0:
			return s.global_position
	if (sites[&"A"] as GroveSite).is_planted():
		return (sites[&"A"] as GroveSite).global_position
	return _alive_pos(ember_hall, _alive_pos(keep, PLAYER_START))


## Raids: 2 Grave Hounds every 150 s from 6:00 until E14, for the nearest walking carrier, else a Fire worker.
func _raid() -> void:
	if is_ending() or ally_active or vice_done:
		return
	after(RAID_EVERY, _raid)
	var units := spawn_wave_at(_wave_rows(&"RAID"), _side_spawn(&"shadow"), SHADOW_SEAT)
	for u in units:
		order_wave(u as Unit, &"raid", _raid_target((u as Unit).global_position))


func _raid_target(from: Vector3) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for c: Variant in carriers:
		if is_instance_valid(c) and (c as Unit).is_alive() and bool((c as Unit).get_meta(&"e2m2_walking", false)):
			var d := _flat((c as Unit).global_position, from)
			if d < best_d:
				best_d = d
				best = (c as Unit).global_position
	if best != Vector3.INF:
		return best
	for w in workers_of(PLAYER_SEAT):
		var d := _flat(w.global_position, from)
		if d < best_d:
			best_d = d
			best = w.global_position
	return best if best != Vector3.INF else _alive_pos(keep, PLAYER_START)


## The nearest planted grove to `from` (null = none).
func _nearest_grove_node(from: Vector3) -> MissionGrove:
	var g := _nearest_planted(from)
	return (sites[g] as GroveSite).grove if g != &"" else null


func _go_for(u: Unit, b: Node3D) -> void:
	if b == null or not is_instance_valid(b):
		return
	if u.attack_target != null or u.is_attack_moving() and _flat(u.global_position, b.global_position) > 9.0:
		if u.attack_target == null and not u.is_attack_moving():
			u.command_attack_move(b.global_position)
		return
	if _flat(u.global_position, b.global_position) <= 9.0:
		if u.attack_target == null and b.has_method(&"is_alive"):
			u.command_attack(b)
	else:
		u.command_attack_move(b.global_position)


func _refresh_wave_unit(u: Unit, mode: StringName, hero_at: Vector3) -> bool:
	match mode:
		&"ysolde":
			if _ysolde_up():
				if u.attack_target == null and not u.is_attack_moving():
					u.command_attack_move(ysolde.global_position)
				elif u.attack_target == null and _flat(u.get_meta(META_TARGET, Vector3.ZERO), ysolde.global_position) > 10.0:
					u.set_meta(META_TARGET, ysolde.global_position)
					u.command_attack_move(ysolde.global_position)
				return true
			var g := _nearest_grove_node(u.global_position)
			if g:
				_go_for(u, g)
				return true
			u.set_meta(META_MODE, &"hero")
			return false
		&"grove_then_hero":
			var g := _nearest_grove_node(u.global_position)
			if g:
				_go_for(u, g)
				return true
			u.set_meta(META_MODE, &"hero")
			return false
		&"grove_b":
			var sb: GroveSite = sites[&"B"]
			if sb.is_planted():
				_go_for(u, sb.grove)
				return true
			if sb.progress > 0.0:
				if u.attack_target == null and not u.is_attack_moving():
					u.command_attack_move(sb.global_position)
				return true
			var g := _nearest_grove_node(u.global_position)
			if g:
				_go_for(u, g)
				return true
			u.set_meta(META_MODE, &"ysolde")
			return true
		&"grove_c_keep":
			var sc: GroveSite = sites[&"C"]
			if sc.is_planted():
				_go_for(u, sc.grove)
				return true
			if sc.progress > 0.0:
				if u.attack_target == null and not u.is_attack_moving():
					u.command_attack_move(sc.global_position)
				return true
			var g := _nearest_grove_node(u.global_position)
			if g:
				_go_for(u, g)
				return true
			if keep and is_instance_valid(keep) and keep.is_alive():
				_go_for(u, keep)
				return true
			return false
		&"heartwood":
			if heartwood and is_instance_valid(heartwood) and heartwood.is_alive():
				_go_for(u, heartwood)
				return true
			u.set_meta(META_MODE, &"hero")
			return false
		&"vice_shadow":
			var sb: GroveSite = sites[&"B"]
			if sb.is_planted():
				_go_for(u, sb.grove)
				return true
			if heartwood and is_instance_valid(heartwood) and heartwood.is_alive():
				_go_for(u, heartwood)
				return true
			u.set_meta(META_MODE, &"hero")
			return false
		&"vice_ice":
			var b := _fire_building_near(BRIDGE_SPOT)
			if b:
				_go_for(u, b)
				return true
			u.set_meta(META_MODE, &"hero")
			return false
		&"raid":
			if u.attack_target == null and not u.is_attack_moving():
				u.command_attack_move(_raid_target(u.global_position))
			return true
		&"relief":
			if u.attack_target == null and not u.is_attack_moving():
				var t := RIMEHOLD_HALL
				var best_d := 20.0
				for n in get_tree().get_nodes_in_group("units"):
					var o := n as Unit
					if o and o.is_alive() and int(o.team) == PLAYER_SEAT and _near_rimehold(o.global_position, 20.0):
						var d := _flat(o.global_position, RIMEHOLD_HALL)
						if d < best_d:
							best_d = d
							t = o.global_position
				u.command_attack_move(t)
			return true
		&"withdraw":
			return true
	var _h := hero_at
	return false


## The living Fire building nearest to `at` (the keep last resort), or null.
func _fire_building_near(at: Vector3) -> Building:
	var best: Building = null
	var best_d := INF
	for b in Building.for_team(PLAYER_SEAT):
		if not b.is_alive() or not b.counts_for_defeat():
			continue
		var d := _flat(b.global_position, at)
		if d < best_d:
			best_d = d
			best = b
	return best


# ---------------------------------------------------------------- the Vice

func _check_vice_start() -> void:
	if is_ending() or has_fired(&"E16"):
		return
	if objective_state("obj_groves") != "done" or objective_state("obj_rimehold") != "done":
		return
	fire_once(&"E16")
	after(VICE_DELAY, _start_vice)


func _start_vice() -> void:
	if is_ending():
		return
	say_l(22)
	say_l(23)
	vice_left = float(by_difficulty(VICE_SECONDS))
	set_objective(&"obj_vice", "active")
	_fire_wave(&"VS")
	_fire_wave(&"VI")
	after(VICE_KNIGHTS_AFTER, func() -> void:
		if not is_ending() and not vice_done:
			fire_once(&"E17")
			say_l(24)
			_fire_wave(&"VK"))
	if clampi(mission_difficulty, 0, 2) == 2:
		after(150.0, _fire_wave.bind(&"VH"))
	_update_vice_pause()


func _update_vice_pause() -> void:
	vice_paused = vice_left >= 0.0 and not vice_done and groves_standing() < 3


func _tick_vice(delta: float) -> void:
	if vice_left < 0.0 or vice_done:
		return
	_update_vice_pause()
	if not vice_paused:
		vice_left = maxf(0.0, vice_left - delta)
	if vice_left <= 0.0 and _alive_pos(keep, Vector3.INF) != Vector3.INF \
			and heartwood != null and is_instance_valid(heartwood) and heartwood.is_alive():
		_e21_vice_done()


## E21: the Vice is held. Withdraw, L28, then e2m2_two_banners (L29-L30), victory 2 s after it.
func _e21_vice_done() -> void:
	if vice_done or is_ending():
		return
	vice_done = true
	vice_left = 0.0
	fire_once(&"E21")
	set_objective(&"obj_vice", "done")
	if objective_state("sec_carriers") == "active":
		set_objective(&"sec_carriers", "done" if carriers_lost <= 2 else "failed")
	_withdraw()
	say_l(28)
	after(4.0, func() -> void:
		if is_ending():   # a defeat pending in the 4 s: no Two Banners film over it
			return
		play_cutscene(&"e2m2_two_banners", func() -> void:
			say_l(29)
			say_l(30)
			set_objective(&"obj_vessa", "done")
			set_objective(&"obj_keep", "done")
			if objective_state("obj_ally") == "active":
				set_objective(&"obj_ally", "done")
			win(VICTORY_DELAY)))


## Every scripted Shadow / Ice unit and both wizards walk to their own keep and leave there; the bots stop.
func _withdraw() -> void:
	clear_waves()
	for bot in [commanders[0] if commanders.size() > 0 else null, commanders[1] if commanders.size() > 1 else null]:
		if bot and is_instance_valid(bot):
			bot.set(&"enabled", false)
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or not Teams.is_hostile(int(u.team), PLAYER_SEAT) or int(u.team) == Unit.Team.NEUTRAL \
				or u.is_worker():
			continue
		var home := ICE_RALLY if int(u.team) == ICE_SEAT else SHADOW_RALLY
		set_truce([u], true, Unit.TRUCE_ALL)
		u.set_meta(META_MODE, &"withdraw")
		u.command_move(home)
		var unit := u
		after(25.0, func() -> void:
			if is_instance_valid(unit) and unit.is_alive() and unit != shadow_hero and unit != torvald:
				unit.leave_map())


# ---------------------------------------------------------------- wizards

func _on_malrik_died(_u: Unit) -> void:
	if is_ending():
		return
	hud.show_message(MSG_MALRIK_FELL, 4.0)
	_respawn_left[SHADOW_SEAT] = WIZARD_RESPAWN


func _on_torvald_died(_u: Unit) -> void:
	if is_ending():
		return
	hud.show_message(MSG_TORVALD_FELL, 4.0)
	_respawn_left[ICE_SEAT] = WIZARD_RESPAWN


func _on_e2_wizard_respawned(wiz: Wizard) -> void:
	if is_ending() or vice_done:
		return
	# Back into the current wave of his side while it still has living units, else home to his rally.
	if wiz == shadow_hero and not _malrik_home:
		if vice_left >= 0.0 or _side_wave_alive(SHADOW_SEAT, wiz):
			order_wave(wiz, &"vice_shadow" if vice_left >= 0.0 else &"grove_b", (GROVES[&"B"] as Array)[1])
		else:
			_malrik_home = true
	elif wiz == torvald and not _torvald_home:
		if vice_left >= 0.0 or _side_wave_alive(ICE_SEAT, wiz):
			order_wave(wiz, &"vice_ice" if vice_left >= 0.0 else &"grove_then_hero", BRIDGE_SPOT)
		else:
			_torvald_home = true


func _side_wave_alive(seat: int, except: Unit) -> bool:
	for u in _wave_units:
		if is_instance_valid(u) and u != except and (u as Unit).is_alive() and int((u as Unit).team) == seat:
			return true
	return false


## Before W3 Torvald stays at his rally; before W4 Malrik stays at his.
func _tick_wizards_home() -> void:
	for pair: Array in [[shadow_hero, _malrik_home, SHADOW_RALLY], [torvald, _torvald_home, ICE_RALLY]]:
		var w := pair[0] as Wizard
		if not bool(pair[1]) or w == null or not is_instance_valid(w) or not w.is_alive():
			continue
		if w.attack_target == null and _flat(w.global_position, pair[2]) > 4.0 and not w.is_attack_moving():
			w.command_attack_move(pair[2])


## Eavesdrop (e2m1 rule): a disguised Saboteur within 12 m of Malrik's Gloom Hall, Torvald's Frost Hall or Rimehold
## hears that side's next scripted wave 30 s early.
func _tick_eavesdrop() -> void:
	var now := mission_time()
	for id: StringName in WAVE_TIMES:
		if waves_fired.has(id) or _eaves_said.has(id):
			continue
		var left := float(WAVE_TIMES[id]) - now
		if left > EAVESDROP_LEAD or left < 0.0:
			continue
		var ice: bool = (WAVES[id] as Dictionary)["side"] == &"ice"
		var halls: Array = [rimehold_hall, ice_hall] if ice else [gloom_hall]
		var heard := false
		for n in get_tree().get_nodes_in_group("units"):
			var u := n as Unit
			if u == null or not u.is_alive() or int(u.team) != PLAYER_SEAT or u.unit_type == null \
					or u.unit_type.id != &"ashveil_saboteur":
				continue
			for h: Variant in halls:
				if is_instance_valid(h) and _flat(u.global_position, (h as Node3D).global_position) <= EAVESDROP_RADIUS:
					heard = true
		if not heard:
			continue
		_eaves_said[id] = true
		var parts: Array[String] = []
		for row: Array in _wave_rows(id):
			var t := UnitType.find(String(row[0]))
			parts.append("%d %s" % [scaled(int(row[1]), String(row[0])), t.display_name if t else String(row[0])])
		hud.show_message(Loc.t(MSG_EAVESDROP_ICE if ice else MSG_EAVESDROP_SHADOW, {"units": ", ".join(parts)}), 6.0)


# ---------------------------------------------------------------- defeat

func _on_keep_destroyed(_b: Building) -> void:
	if is_ending() or vice_done:
		return
	fire_once(&"E23")
	say_l(32)
	set_objective(&"obj_keep", "failed")
	lose(DEFEAT_DELAY)


## E22: Vessa falls: L31, then the instant-loss defeat.
func _on_player_hero_fell() -> void:
	fire_once(&"E22")
	say_l(31)
	set_objective(&"obj_vessa", "failed")
	super()


func _check_ally_out() -> void:
	if not ally_active or is_ending() or vice_done:
		return
	if seat_out(ALLY_SEAT):
		_ally_falls()


## E24: Nature falls a second time (the seat out, or the Heartwood keep lost: the Vice can never end without it).
func _ally_falls() -> void:
	if not ally_active or is_ending() or vice_done:
		return
	if fire_once(&"E24"):
		say_l(33)
		set_objective(&"obj_ally", "failed")
		lose(DEFEAT_DELAY)


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)   # MissionBase: the Skirmish tick, the timers, the E-list
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_plant_acc += delta
	if _plant_acc >= PLANT_TICK:
		_tick_planting(_plant_acc)
		_plant_acc = 0.0
	_tick_groves(delta)
	_tick_kneels(delta)
	_tick_wren(delta)
	_tick_vice(delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_ally_brain(0.5)
		_tick_column()
		_tick_wizards_home()
		_tick_eavesdrop()
		_check_ally_out()
		_tick_reserve()
		points_peak = maxi(points_peak, points_held())
		var t := "%s|%s|%s|%s" % [objective_text(&"obj_groves"), objective_text(&"obj_vice"), objective_text(&"sec_points"),
				objective_text(&"sec_carriers")]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
