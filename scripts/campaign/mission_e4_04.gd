class_name MissionE4_04
extends MissionBase
## Episode 4, mission 4 "Winter's End" (docs/design/mission-e4-04.md): the episode's last battle. On Torvald's frontier
## Ysolde (player) and Vessa (ALLY Fire bot) break the Wall of a Hundred Winters: its three Winter Gates, its two
## Wallwardens and the Winterheart that makes it regrow; then Ysolde walks to Aldra's Glass Spire, where Torvald stops
## Aldra (`e4m4_enough`, the seed of his turn). Maelis is called from 0:00. Spotlight: the Elder Treant (the Wall's
## breaker: soldiers do x0.35 to it, the Treant x1.0).
##
## Built deviations (2026-10-08, from the spec):
## - The map is built in code on a 160 x 140 MapInfo (no World Forge `hundred_winters.map`): flat ground, no cliffs;
##   the Wall runs the full map width (x -79..79) so the gates and breaches are the only ways north.
## - The Wall is a row of WinterWall buildings (scripts/campaign/winter_wall.gd: the walls.md 8 L3 factors, regrowth
##   while the Winterheart stands); the Winter Gates are closed for both sides (no real doors): enemy waves step out
##   on the gate's south side, a woken Wallwarden steps out through its gate.
## - No Elder Circle (no titan building / UnitType in the data yet): the Elder Treant is a mission UnitType (the
##   elder_treant model on Rime Colossus-like stats); one wakes from the Sleeping Elder (sec_elder) and the Citadel
##   brings one more (the "Let the elders come" of E7). No rooted form.
## - Wallwarden = a Rime Colossus copy at the spec's numbers (no 1.6 scale); its Avalanche Stomp is mission-side.
## - Aldra is the helper_aldra Helper on the enemy team escorting an invisible anchor (e4m3's rule); Torvald waits behind
##   the Heart Gate (truce) until I2.
## - Balance (JS 2026-10-08, after the scripted run won at 14:33): a sturdier Wall (PIECE_HP / GATE_HP / WARDEN_HP
##   raised, a Rime Colossus in each garrison G1-G3), the Winterheart 20 000 HP with the Wall's damage factors
##   (soldiers x0.35: the Treants and spells break it) and frost-bound until HEART_OPEN_AT
##   (19:00, a minute after I3) even once both wardens are down (MSG_HEART_BOUND / MSG_HEART_OPEN), a bigger spire guard, and
##   fuller home nodes (9 000 / 9 000 / west 6 000) so a player waiting for 19:00 is not starved.

const MISSION_ID := &"e4m4"
const MISSION_TITLE := "Winter's End"
const MAP_W := 160.0
const MAP_D := 140.0
const PLAYER_SEAT := Unit.Team.PLAYER
const ALLY_SEAT := Unit.Team.ALLY      ## Vessa (Fire bot)
const ICE_SEAT := Unit.Team.ENEMY      ## Torvald (Ice bot)
const TITHE_SEAT := Unit.Team.ENEMY_2  ## Malrik's tithe detachments (scripted only)

const YSOLDE_START := Vector3(-38.0, 0.0, 38.0)
const HEARTWOOD := Vector3(-46.0, 0.0, 48.0)
const GROVE_HALL := Vector3(-32.0, 0.0, 50.0)
const SEED_HOLLOWS: Array[Vector3] = [Vector3(-58.0, 0.0, 56.0), Vector3(-44.0, 0.0, 62.0)]
const ARMY_POS := Vector3(-36.0, 0.0, 32.0)
const PLAYER_RALLY := Vector3(-30.0, 0.0, 28.0)
const FIRE_KEEP := Vector3(46.0, 0.0, 48.0)
const EMBER_HALL := Vector3(32.0, 0.0, 50.0)
const HEARTHS: Array[Vector3] = [Vector3(58.0, 0.0, 56.0), Vector3(44.0, 0.0, 62.0)]
const VESSA_RALLY := Vector3(30.0, 0.0, 28.0)
const NODES := [[&"e4m4_home_a", Vector3(-55.0, 0.0, 42.0), 9000], [&"e4m4_home_b", Vector3(-40.0, 0.0, 57.0), 9000],
		[&"e4m4_west", Vector3(-60.0, 0.0, 14.0), 6000], [&"e4m4_fire_a", Vector3(55.0, 0.0, 42.0), 2500],
		[&"e4m4_fire_b", Vector3(40.0, 0.0, 57.0), 2500], [&"e4m4_east", Vector3(60.0, 0.0, 14.0), 2000],
		[&"e4m4_rime_a", Vector3(-8.0, 0.0, -62.0), 2000], [&"e4m4_rime_b", Vector3(10.0, 0.0, -62.0), 2000]]
const ELDER := Vector3(-24.0, 0.0, 18.0)
const ELDER_TOTEMS: Array[Vector3] = [Vector3(-30.0, 0.0, 14.0), Vector3(-18.0, 0.0, 14.0)]
const WALL_Z := -8.0
const WALL_X := 79.0
const GATES := {&"west": Vector3(-44.0, 0.0, -8.0), &"heart": Vector3(0.0, 0.0, -8.0), &"east": Vector3(44.0, 0.0, -8.0)}
const WALL_SPIRES: Array[float] = [-60.0, -24.0, 24.0, 60.0]
const WINTERHEART := Vector3(0.0, 0.0, -16.0)
const ALCOVES := {&"west": Vector3(-44.0, 0.0, -16.0), &"east": Vector3(44.0, 0.0, -16.0)}
const GARRISONS := {
	&"G1": [Vector3(-44.0, 0.0, -14.0), [["shardcaster", 3], ["frostbow", 2], ["rime_colossus", 1]]],
	&"G2": [Vector3(0.0, 0.0, -22.0), [["shardcaster", 2], ["frostbow", 2], ["frost_mortar", 1], ["rime_colossus", 1]]],
	&"G3": [Vector3(44.0, 0.0, -14.0), [["shardcaster", 3], ["rime_seer", 1], ["frostbow", 1], ["rime_colossus", 1]]],
}
const RIME_KEEP := Vector3(0.0, 0.0, -54.0)
const FROST_HALLS: Array[Vector3] = [Vector3(-16.0, 0.0, -48.0), Vector3(16.0, 0.0, -48.0)]
const SNOW_LODGES: Array[Vector3] = [Vector3(-28.0, 0.0, -58.0), Vector3(28.0, 0.0, -58.0)]
const ICE_RALLY := Vector3(0.0, 0.0, -34.0)
const TORVALD_PARAPET := Vector3(0.0, 0.0, -12.0)
const GLASS_SPIRE := Vector3(30.0, 0.0, -36.0)
const SPIRE_GOAL_R := 8.0
const TITHE_SPAWN := Vector3(60.0, 0.0, -2.0)   ## south of the Wall by the East Gate (they come through it)
const WARDEN_LEASH_Z := WALL_Z + 30.0
const STOMP_EVERY: Array[float] = [12.0, 12.0, 10.0]
const STOMP_R := 4.0
const STOMP_DMG := 60.0
const PLANT_R := 4.0
const PLANT_TIME := 4.0
const PLANT_CLEAR := 10.0
const I1_AT := 240.0
const S1_AT := 420.0
const VESSA_PUSH_AT := 540.0
const I2_AT := 600.0
const WARDEN_WAKE: Array[float] = [960.0, 840.0, 720.0]
const S2_AT := 900.0
const I3_AT := 1080.0
const HEART_OPEN_AT := 1140.0   ## the Winterheart stays frost-bound until 19:00 (a minute after I3) even with both wardens down
const HALLS_CUT := 0.4
const ALDRA_FLEE := 0.27
const ALDRA_BACK := 90.0
const TORVALD_BACK := 60.0
const WIZARD_RETREAT := 0.35
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 2.0
const LEVEL_CAP := 8
const ESSENCE_CAP := 1500
const NO_SAVE_ESSENCE := 700
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [550, 450, 350]
const PIECE_HP: Array[float] = [1100.0, 1500.0, 1800.0]
const GATE_HP: Array[float] = [2600.0, 3600.0, 4200.0]
const HEART_HP: Array[float] = [14000.0, 20000.0, 24000.0]
const WARDEN_HP: Array[float] = [2400.0, 3300.0, 4000.0]
const REGROW: Array[float] = [0.5, 1.0, 1.5]
const WIZARD_LEVEL: Array[int] = [6, 7, 8]
const VESSA_SOLDIERS: Array[int] = [11, 9, 7]
const TORVALD_SPELLS := [&"rime_bolt", &"rime_bolt", &"rime_bolt", &"flash_freeze", &"flash_freeze", &"rime_aegis", &"rime_aegis"]
const VESSA_SPELLS := [&"fireball", &"fireball", &"fireball", &"ember_step", &"ember_step", &"kindle"]

const WAVES := {
	&"I1": [["rimeshield", 4], ["shardcaster", 2], ["rimeling", 2]],
	&"S1": [["shade", 4], ["nightbolt", 2], ["hexweaver", 1], ["gloom_deacon", 1]],
	&"I2": [["rimeshield", 4], ["shardcaster", 2], ["frost_mortar", 1], ["shardguard", 1]],
	&"S2": [["shade", 6], ["nightbolt", 3], ["shadow_knight", 1], ["gloom_deacon", 1]],
	&"I3": [["rimeshield", 4], ["shardguard", 2], ["hoarlight_magebow", 2], ["frost_mortar", 1]],
	&"SPIRE": [["rimeshield", 8], ["shardcaster", 4], ["shardguard", 2], ["rime_colossus", 2]],
	&"G0": [["rimeshield", 3], ["rime_seer", 1]],
}

const SPEAKER_COLORS := {&"ysolde": Color(0.55, 0.90, 0.35), &"vessa": Color(1.0, 0.45, 0.1),
		&"maelis": Color(0.60, 0.85, 0.50), &"torvald": Color(0.55, 0.80, 1.00), &"aldra": Color(0.62, 0.95, 0.88),
		&"shade": Color(0.55, 0.40, 0.70), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"ysolde": "Ysolde", &"vessa": "Vessa", &"maelis": "Maelis", &"torvald": "Torvald",
		&"aldra": "Aldra", &"shade": "Shadow Captain", &"narrator": "Narrator"}
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13", "L14",
		"L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L22b", "L23", "L24", "L25", "L26", "L27", "L28", "L29",
		"L30", "L31", "L32", "L33", "L34", "L35", "L36"]
const DIALOGUE := [
	[&"narrator", "Torvald's frontier, a week before the snows. A wall older than any of the four."],
	[&"ysolde", "The Wall of a Hundred Winters. While it stands, this war never has to stop for weather."],
	[&"vessa", "So we knock it down. I brought fire. You brought... a tree?"],
	[&"ysolde", "Several. They're very patient, and they hit like a landslide."],
	[&"maelis", "Under the ice by the west gate, something old is sleeping. Wake it, and it will owe you."],
	[&"maelis", "Good morning, grandfather. There's a wall that needs leaning on."],
	[&"torvald", "Ysolde. I warned you about the cold. Turn back while the passes are open."],
	[&"shade", "The Bishop sends his tithe, Lord Torvald. He asks for nothing in return. Yet."],
	[&"torvald", "Nothing is what Malrik always asks for. At first."],
	[&"ysolde", "The Heartwood stands tall again. Let the elders come."],
	[&"maelis", "Now that is a tree with opinions."],
	[&"vessa", "I'm taking the east gate. Don't wait for me. I definitely won't wait for you."],
	[&"torvald", "I built this wall so nobody would ever have to choose. You are making me choose."],
	[&"ysolde", "No, Torvald. Malrik made you choose. I'm only here to hear the answer."],
	[&"vessa", "A gate's down! Your trees punch harder than my fire, Ysolde. I hate it. Keep going."],
	[&"aldra", "Wake, old guards. Somebody is knocking."],
	[&"ysolde", "Colossi. Tall, slow, and stubborn. So are we."],
	[&"vessa", "Shadow at my hearths, Ysolde! If your trees can walk, now's the time."],
	[&"maelis", "One mountain fewer. Mountains are overrated."],
	[&"shade", "The second tithe, Lord Torvald. The Bishop says: no more excuses."],
	[&"narrator", "The wardens are rubble. The Winterheart stands alone, and it is cracking."],
	[&"aldra", "You thawed his wood, Ysolde. You will not thaw his wall."],
	[&"aldra", "You broke my glass once, Ysolde. Once was enough."],
	[&"narrator", "A hundred winters, broken in one afternoon. The Wall begins to weep."],
	[&"vessa", "Look at it melt! Fire always wins in the end."],
	[&"ysolde", "That was the tree, Vessa."],
	[&"maelis", "The glass spire. Aldra will be waiting. She always is."],
	[&"vessa", "Both halls! Torvald's soldiers will have to train in the snow. Good."],
	[&"aldra", "One strike, Torvald, and the green war is over. Let me finish it."],
	[&"torvald", "Enough, Aldra."],
	[&"aldra", "She broke your wall!"],
	[&"torvald", "It was only ever ice. Let her up."],
	[&"ysolde", "Why?"],
	[&"torvald", "Because a hundred winters is long enough. Go home, Ysolde. Spring will keep."],
	[&"narrator", "That night the first blizzard closed the passes. Both sides sat down to wait for spring."],
	[&"ysolde", "Plant me... somewhere warm..."],
	[&"maelis", "The Heartwood's fallen. Winter wins this one."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"On Torvald's frontier stands a wall older than any of the four: the Wall of a Hundred Winters. When the snows come it closes the passes, and behind it the north can feed Malrik's war all winter long.",
	"The first blizzard is a week away. Vessa has brought fire and siege. Ysolde has brought something slower and much heavier: the elders of the wood, if she can wake them.",
	"Break the Wall's two wardens and the Winterheart that feeds it. Then go to Aldra's Glass Spire and end this before the snow does.",
]
const BRIEFING_LINE := "Soldiers barely scratch the Wall. Siege, titans and spells break it."
const HINT_START := "The Wall shrugs off soldiers. Ash Hurlers, Elder Treants and spells break it. The Winterheart behind the middle gate makes it heal."
const HINT_SAGE := "Bramblesage: Pollen Haze over a gate's garrison stops their archers shooting over the Wall."
const HINT_CITADEL := "Your Stronghold can become a Citadel: select the Heartwood and press X (300 crystals, 90 s). It calls an Elder Treant: Elder Treants break walls."
const HINT_TREANT := "Elder Treant: it hits the Wall far harder than soldiers. Send it at a gate."
const MSG_TORVALD_FELL := "Torvald has fallen, the frost will bring him back"
const MSG_VESSA_FELL := "Vessa falls back to the Heartwood"
const MSG_HEART_BOUND := "The Winterheart is still frost-bound. Its frost breaks after the glass host comes (19:00)."
const MSG_HEART_OPEN := "The Winterheart's frost cracks: break it now"
const MSG_CLEAR := "Clear the glade first: the roots won't open while the enemy stands in it"

## Read only.
var flag_override: Dictionary = {}
var no_save_fallback := false
var wall: Array = []                 ## every WinterWall piece and gate
var gates := {}                      ## id -> WinterWall
var wall_spires: Array = []
var winterheart: Building
var wallwardens := {}                    ## id -> Unit (dormant until woken)
var wardens_down := 0
var heart_open := false
var heart_opens_at := HEART_OPEN_AT   ## tests may lower it
var garrisons := {}
var elder_totems: Array = []
var elder_progress := 0.0
var elder_woken := false
var treants: Array = []
var frost_halls: Array = []
var glass_spire: Building
var torvald: Wizard = null
var vessa: Wizard = null
var aldra: Helper = null
var maelis: Unit = null
var waves_fired: Array[StringName] = []
var said: Array[String] = []
var thawed := false
var victory_time := -1.0
var vessa_target := &""

var _said := {}
var _tick := 0.0
var _wall_type: BuildingType
var _wall_small_type: BuildingType
var _gate_type: BuildingType
var _spire_type: BuildingType
var _heart_type: BuildingType
var _glass_type: BuildingType
var _totem_type: BuildingType
var _treant_type: UnitType
var _warden_type: UnitType
var _aldra_anchor: Unit = null
var _aldra_goal := GLASS_SPIRE
var _aldra_back_left := -1.0
var _stomp_left := {}
var _last_obj_text := ""


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"nature"
	enemy_kingdom = &"ice"
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
	define_objectives([[&"obj_wall", "primary"], [&"obj_spire", "primary"], [&"obj_ysolde", "primary"],
			[&"sec_elder", "secondary"], [&"sec_halls", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"shardguard", &"frost_mortar", &"rime_colossus"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Heartwood has fallen"
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {PLAYER_SEAT: 2, ALLY_SEAT: 2, ICE_SEAT: 3}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.helper_start_called = true
	c.titans_enabled = true
	c.lair_max = 1
	c.titan_max_trained = 2
	c.start_level = 6
	c.start_spells = [&"thornburst"]
	c.start_spell_points = 5
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 150
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nWinter's End"
	c.defeat_banner = "DEFEAT"
	c.seat_sides = {PLAYER_SEAT: 0, ALLY_SEAT: 0, ICE_SEAT: 1, TITHE_SEAT: 1}
	c.seat_opponents = {ICE_SEAT: PLAYER_SEAT, TITHE_SEAT: ALLY_SEAT, ALLY_SEAT: ICE_SEAT, PLAYER_SEAT: ICE_SEAT}
	c.seat_kingdoms = {PLAYER_SEAT: &"nature", ALLY_SEAT: &"fire", ICE_SEAT: &"ice", TITHE_SEAT: &"shadow"}
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"elder_treant", "trigger": &"manual",
			"card": "Elder Treant. A walking forest: root it, and it breaks walls that armies can't scratch."}
	return c


func _map_size() -> Vector2:
	return Vector2(MAP_W, MAP_D)


func _player_start() -> Vector3:
	return YSOLDE_START


func _use_map_dressing() -> bool:
	return false


func _title_line() -> String:
	return "Episode 4, Mission 4: %s" % MISSION_TITLE


func _ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	_wall_type = WinterWall.make_type(&"winter_wall", "Wall of a Hundred Winters", PIECE_HP[diff], 2, REGROW[diff])
	_wall_small_type = WinterWall.make_type(&"winter_wall", "Wall of a Hundred Winters", PIECE_HP[diff] * 0.5, 1, REGROW[diff])
	_gate_type = WinterWall.make_type(&"winter_gate", "Winter Gate", GATE_HP[diff], 3, REGROW[diff])
	var tower := BuildingType.find("ice_tower")
	if tower:
		_spire_type = tower.duplicate() as BuildingType
		_spire_type.id = &"wall_rime_spire"
		_spire_type.display_name = "Wall Rime Spire"
		_spire_type.max_hp = 720.0
		_spire_type.attack_range = 10.0
		_spire_type.on_hit_status = &"chill"
		_spire_type.on_hit_duration = 2.0
		_spire_type.counts_for_defeat = false
		_spire_type.cost = 0
		_glass_type = tower.duplicate() as BuildingType
		_glass_type.id = &"glass_spire"
		_glass_type.display_name = "Glass Spire"
		_glass_type.max_hp = 2500.0
		_glass_type.attack_damage = 14.0
		_glass_type.attack_range = 11.0
		_glass_type.attack_cooldown = 1.4
		_glass_type.counts_for_defeat = false
		_glass_type.cost = 0
	_heart_type = BuildingType.new()
	_heart_type.id = &"winterheart"
	_heart_type.display_name = "Winterheart"
	_heart_type.faction = &"ice"
	_heart_type.kind = &"winterheart"
	_heart_type.max_hp = HEART_HP[diff]
	_heart_type.footprint = Vector2i(2, 2)
	_heart_type.height = 4.0
	_heart_type.sight_radius = 8.0
	_heart_type.counts_for_defeat = false
	_heart_type.color = Color(0.6, 0.85, 1.0)
	_heart_type.body_color = Color(0.8, 0.92, 1.0)
	_totem_type = BuildingType.new()
	_totem_type.id = &"rime_totem"
	_totem_type.display_name = "Rime Totem"
	_totem_type.faction = &"ice"
	_totem_type.kind = &"totem"
	_totem_type.max_hp = 400.0
	_totem_type.footprint = Vector2i(1, 1)
	_totem_type.height = 2.6
	_totem_type.sight_radius = 6.0
	_totem_type.counts_for_defeat = false
	_totem_type.color = Color(0.55, 0.80, 1.00)
	var col := UnitType.find("rime_colossus")
	if col:
		_treant_type = col.duplicate() as UnitType
		_treant_type.id = &"elder_treant"
		_treant_type.display_name = "Elder Treant"
		_treant_type.faction = &"nature"
		_treant_type.cost = 600
		_treant_type.pop = 6
		_treant_type.max_hp = 1800.0
		_treant_type.attack_damage = 60.0
		_treant_type.attack_range = 2.4
		_treant_type.attack_cooldown = 2.2
		_treant_type.move_speed = 3.0
		_treant_type.armor = 15.0
		_treant_type.on_hit_status = &"rooted"
		_treant_type.on_hit_duration = 0.6
		_treant_type.kill_xp = 300
		var tp := "res://art/units/titans/elder_treant/elder_treant.tscn"
		if ResourceLoader.exists(tp):
			_treant_type.model_scene = load(tp) as PackedScene
			_treant_type.model_path = tp
		_warden_type = col.duplicate() as UnitType
		_warden_type.id = &"wallwarden"
		_warden_type.display_name = "Wallwarden"
		_warden_type.cost = 700
		_warden_type.pop = 0
		_warden_type.max_hp = WARDEN_HP[diff]
		_warden_type.armor = 25.0
		_warden_type.attack_damage = 45.0
		_warden_type.attack_range = 2.2
		_warden_type.attack_cooldown = 2.0
		_warden_type.move_speed = 3.0
		_warden_type.kill_xp = 300
		_warden_type.commandable = false
	for t: BuildingType in [_wall_type, _gate_type, _spire_type, _glass_type, _heart_type, _totem_type]:
		register_local_building_type(t)   # winter_wall: the 2-cell type (a lost small piece is not rebuilt)
	register_local_unit_type(_treant_type)   # C4-5: a saved Elder Treant comes back from it
	register_local_unit_type(_warden_type)
	super()
	if camera_rig:
		camera_rig.focus_on(YSOLDE_START)


# ---------------------------------------------------------------- seats

func start_position(team: int) -> Vector3:
	match team:
		ALLY_SEAT:
			return VESSA_RALLY
		ICE_SEAT:
			return TORVALD_PARAPET
	return YSOLDE_START


func base_center(team: int) -> Vector3:
	if seat_bases.has(team):
		return seat_bases[team]
	match team:
		ALLY_SEAT:
			return FIRE_KEEP
		ICE_SEAT, TITHE_SEAT:
			return RIME_KEEP
	return HEARTWOOD


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	if k:
		return k.spawn_point()
	if team == ALLY_SEAT:
		var hw := keep_of(PLAYER_SEAT)
		if hw:
			return hw.spawn_point()
	if team == ICE_SEAT:
		for h: Variant in frost_halls:
			if h != null and is_instance_valid(h) and (h as Building).is_alive() and h is TrainingBuilding:
				return (h as TrainingBuilding).spawn_point()
		return Vector3(0.0, 0.0, -60.0)
	return base_center(team) + Vector3(4.0, 0.0, 4.0)


func node_of(team: int, suffix: String) -> CrystalNode:
	var prefix := {PLAYER_SEAT: {"a": &"e4m4_home_a", "b": &"e4m4_home_b", "x": &"e4m4_west"},
			ALLY_SEAT: {"a": &"e4m4_fire_a", "b": &"e4m4_fire_b", "x": &"e4m4_east"},
			ICE_SEAT: {"a": &"e4m4_rime_a", "b": &"e4m4_rime_b"}}
	var table: Dictionary = prefix.get(team, {})
	var v: Variant = crystal_nodes.get(table.get(suffix, &""))
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


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
			return Vector3(-52.0, 0.0, 18.0)
		ALLY_SEAT:
			return Vector3(52.0, 0.0, 18.0)
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
	keep = build_grid.spawn_complete(BuildingType.find("nature_keep"), HEARTWOOD, PLAYER_SEAT) as Keep
	if keep:
		keep.destroyed.connect(func(_b: Building) -> void: say_l("L36"))
	build_grid.spawn_complete(BuildingType.find("nature_barracks"), GROVE_HALL, PLAYER_SEAT)
	for p in SEED_HOLLOWS:
		build_grid.spawn_complete(BuildingType.find("nature_hollow"), p, PLAYER_SEAT)
	seat_bases[PLAYER_SEAT] = HEARTWOOD
	var fk := build_grid.spawn_complete(BuildingType.find("fire_keep"), FIRE_KEEP, ALLY_SEAT) as Keep
	build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL, ALLY_SEAT)
	for p in HEARTHS:
		build_grid.spawn_complete(BuildingType.find("fire_hearth"), p, ALLY_SEAT)
	if fk:
		seat_keeps[ALLY_SEAT] = fk
		fk.destroyed.connect(_on_fire_keep_destroyed)
	seat_bases[ALLY_SEAT] = FIRE_KEEP
	seat_starts[ALLY_SEAT] = VESSA_RALLY
	var rk := build_grid.spawn_complete(BuildingType.find("ice_keep"), RIME_KEEP, ICE_SEAT) as Keep
	shadow_keep = rk
	if rk:
		seat_keeps[ICE_SEAT] = rk
		rk.max_hp = 4200.0
		rk.hp = 4200.0
	seat_bases[ICE_SEAT] = RIME_KEEP
	seat_starts[ICE_SEAT] = ICE_RALLY
	for p in FROST_HALLS:
		var fh := build_grid.spawn_complete(BuildingType.find("ice_barracks"), p, ICE_SEAT)
		if fh:
			fh.set_meta(&"e4m4_hall", true)
			fh.destroyed.connect(_on_frost_hall_destroyed)
			frost_halls.append(fh)
	for p in SNOW_LODGES:
		build_grid.spawn_complete(BuildingType.find("ice_lodge"), p, ICE_SEAT)
	if _glass_type:
		glass_spire = build_grid.spawn_complete(_glass_type, GLASS_SPIRE, ICE_SEAT)
		if glass_spire:
			mark_scripted(glass_spire)
	_build_wall()
	for p in ELDER_TOTEMS:
		var t := build_grid.spawn_complete(_totem_type, p, ICE_SEAT)
		if t:
			mark_scripted(t)
			elder_totems.append(t)


## The Wall of a Hundred Winters: 2-cell pieces from x -79 to 79 on z -8, 3-cell gates at -44 / 0 / 44, Wall Rime
## Spires on the line at -60 / -24 / 24 / 60, the Winterheart 8 m behind the Heart Gate.
func _build_wall() -> void:
	# 2 m cells along z = WALL_Z from x -80 to 80: the gates and the spires first, every free run then filled with
	# 2-cell pieces (a 1-cell piece for an odd leftover), so the line has no gap.
	var taken := {}
	for id: StringName in GATES:
		var g := _wall_piece(_gate_type, GATES[id])
		if g == null:
			continue
		g.is_gate = true
		g.name = "WinterGate_%s" % String(id)
		g.destroyed.connect(_on_gate_destroyed.bind(id))
		g.damaged.connect(_on_gate_damaged.bind(id))
		gates[id] = g
		_take_cells(taken, g.position.x, _gate_type.footprint.x)
	for sx: float in WALL_SPIRES:
		if _spire_type == null:
			break
		var s := build_grid.spawn_complete(_spire_type, Vector3(sx, 0.0, WALL_Z), ICE_SEAT)
		if s:
			mark_scripted(s)
			wall_spires.append(s)
			_take_cells(taken, s.position.x, _spire_type.footprint.x)
	var last := int(floor(WALL_X / 2.0))
	var i := -last - 1
	while i <= last:
		if taken.has(i):
			i += 1
			continue
		if not taken.has(i + 1) and i + 1 <= last:
			_wall_piece(_wall_type, Vector3(2.0 * i + 2.0, 0.0, WALL_Z))   # cells i, i + 1
			i += 2
		else:
			_wall_piece(_wall_small_type, Vector3(2.0 * i + 1.0, 0.0, WALL_Z))
			i += 1
	# The Winterheart takes the Wall's damage factors (soldiers x0.35, titans x1.0, siege x1.5, spells x1.0), JS
	# 2026-10-08: it is a WinterWall node outside the `wall` list (the thaw does not touch it); no regrowth.
	var wh := WinterWall.new()
	wh.building_type = _heart_type
	wh.team = ICE_SEAT
	wh.position = build_grid.snap(WINTERHEART, _heart_type.footprint)
	nav_region.add_child(wh, true)
	winterheart = wh
	if winterheart:
		mark_scripted(winterheart)
		winterheart.destroyed.connect(_on_winterheart_destroyed)
		set_truce([winterheart], true, Unit.TRUCE_ALL)   # frost-bound while a Wallwarden lives (D4)


## Marks the 2 m cells a building of `cells` width centred on `x` covers.
static func _take_cells(taken: Dictionary, x: float, cells: int) -> void:
	var left := int(round((x - float(cells)) / 2.0))
	for c in cells:
		taken[left + c] = true


func _wall_piece(type: BuildingType, at: Vector3) -> WinterWall:
	if type == null:
		return null
	var w := WinterWall.new()
	w.building_type = type
	w.team = ICE_SEAT
	w.position = build_grid.snap(at, type.footprint)
	nav_region.add_child(w, true)
	mark_scripted(w)
	wall.append(w)
	return w


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for team: int in [PLAYER_SEAT, ALLY_SEAT]:
		for x in range(-72, 73, 12):
			fog.reveal(team, Vector3(float(x), 0.0, WALL_Z + 3.0), 7.0)
		fog.reveal(team, ELDER, 10.0)
	_setup_champions()
	hero = _make_wizard(PLAYER_SEAT)
	_spawn(hero, PLAYER_SEAT, YSOLDE_START)
	_claim_wizard(hero, PLAYER_SEAT)
	ItemDrops.ensure_inventory(hero)
	var f := _flags()
	set_meta(&"campaign_flags", f.duplicate())
	_carry_essence()
	for i in 7:
		var w := _spawn(make_unit("sprigling"), PLAYER_SEAT, HEARTWOOD + Vector3(-5.0 + i * 1.5, 0.0, -6.0))
		w.call(&"command_gather", node_of(PLAYER_SEAT, "a" if i < 4 else "b"))
	var rows := [["thornling", 8], ["burr_slinger", 4], ["bloomtender", 2], ["vinelasher", 3], ["greenheart_oathkeeper", 2],
			["bramblehorn", 2 + (2 if diff == 0 else 0)], ["bramblesage", 1], ["briar_roc", 0 if diff == 2 else 1]]
	var k := 0
	for row: Array in rows:
		for j in int(row[1]):
			_spawn(make_unit(String(row[0])), PLAYER_SEAT, ARMY_POS + Vector3((k % 7) * 1.6 - 5.0, 0.0, (k / 7) * 1.7))
			k += 1
	if bool(f.get("e4m3_groves_unbroken", false)):
		for j in 2:
			var b := _spawn(make_unit("bramblehorn"), PLAYER_SEAT, ARMY_POS + Vector3(j * 2.0, 0.0, -3.0))
			b.add_xp(400)
	if bool(f.get("heartwood_seed_owned", false)) and ItemType.find("heartwood_seed") != null:
		force_artifacts(hero, ["heartwood_seed", ""])
	# --- Vessa (ALLY, Fire).
	var fire := activate_seat(ALLY_SEAT, &"fire", {"crystals": 400,
			"workers": [["cinder_hand", 3, node_of(ALLY_SEAT, "a")], ["cinder_hand", 3, node_of(ALLY_SEAT, "b")]],
			"units": [["flame_guard", 6, VESSA_RALLY], ["ember_archer", 3, VESSA_RALLY], ["ash_hurler", 2, VESSA_RALLY],
					["pyre_adept", 2, VESSA_RALLY], ["kilnwarden", 1, VESSA_RALLY]],
			"wizard": {"level": 6, "spells": VESSA_SPELLS, "pos": VESSA_RALLY}})
	vessa = fire.get("wizard") as Wizard
	if vessa:
		vessa.died.connect(_on_bot_wizard_died.bind(ALLY_SEAT))
	_add_seat_commander(ALLY_SEAT)
	# --- Torvald (ENEMY, Ice) behind the Heart Gate until I2; his camp; the garrisons, G0, the wallwardens; Aldra.
	var ice := activate_seat(ICE_SEAT, &"ice", {"crystals": 400,
			"workers": [["rime_hauler", 3, node_of(ICE_SEAT, "a")], ["rime_hauler", 2, node_of(ICE_SEAT, "b")]],
			"units": [["rimeshield", 4, ICE_RALLY], ["shardcaster", 2, ICE_RALLY], ["shardguard", 1, ICE_RALLY]],
			"wizard": {"level": int(by_difficulty(WIZARD_LEVEL)), "spells": TORVALD_SPELLS, "pos": TORVALD_PARAPET}})
	torvald = ice.get("wizard") as Wizard
	shadow_hero = torvald
	if torvald:
		mark_scripted(torvald)
		torvald.level_cap = int(by_difficulty(WIZARD_LEVEL))
		torvald.set_meta(META_HOME, TORVALD_PARAPET)
		set_truce([torvald], true, Unit.TRUCE_ALL)
		torvald.died.connect(_on_torvald_died)
	_add_seat_commander(ICE_SEAT)
	activate_seat(TITHE_SEAT, &"shadow", {})
	for gid: StringName in GARRISONS:
		garrisons[gid] = spawn_group(GARRISONS[gid][1], GARRISONS[gid][0], 2.5, ICE_SEAT, true)
	spawn_group(WAVES[&"G0"], ELDER + Vector3(0.0, 0.0, -6.0), 3.0, ICE_SEAT, true)
	if _warden_type:
		for id: StringName in ALCOVES:
			var w := _spawn(Worker.make_unit(_warden_type), ICE_SEAT, ALCOVES[id])
			mark_scripted(w)
			set_dormant(w, true)
			w.set_meta(META_HOME, ALCOVES[id])
			w.died.connect(_on_wallwarden_died.bind(id))
			wallwardens[id] = w
	_spawn_aldra()
	_add_events()
	begin_mission([&"obj_wall", &"obj_ysolde", &"sec_halls"])
	maelis = _find_maelis()


func _find_maelis() -> Unit:
	for n in get_tree().get_nodes_in_group(&"units"):
		if n is Helper and int((n as Helper).team) == PLAYER_SEAT:
			return n as Unit
	return null


func _flags() -> Dictionary:
	if not flag_override.is_empty():
		return flag_override
	return CampaignState.open(campaign_save_path).flags


## Ysolde's essence (her track); the no-save fallback: 150 + 700.
func _carry_essence() -> void:
	var cs := CampaignState.open(campaign_save_path)
	no_save_fallback = not cs.is_completed(&"e4m3") and flag_override.is_empty()
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	if bank:
		bank.add(NO_SAVE_ESSENCE if no_save_fallback else int(_flags().get(CampaignState.YSOLDE_ESSENCE_FLAG, 0)))


func seat_profile(seat: int) -> AIProfile:
	var diff := clampi(mission_difficulty, 0, 2)
	var p: AIProfile = MissionBase.frozen_ice_profile(diff) if seat == ICE_SEAT else AIProfile.for_difficulty(diff)
	p.id = StringName("mission_e4_04_%s" % ("ally" if seat == ALLY_SEAT else "enemy"))
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
	p.max_soldiers = int(by_difficulty(VESSA_SOLDIERS)) if seat == ALLY_SEAT else 12
	if seat == ICE_SEAT:
		p.defend_radius = 15.0
	p.build_rows = PackedStringArray(["H1"])
	p.rebuild = false
	p.hero_stays_home = true
	p.malrik_joins = AIProfile.MalrikJoins.NEVER
	p.champion_max = 0
	p.trade = false
	p.map_fill = false
	p.item_build = PackedStringArray()
	return p


func _add_seat_commander(seat: int) -> Node:
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return null
	var bot: Node = script.new()
	bot.name = "ShadowBot" if seat == ICE_SEAT else "Bot%d" % seat
	bot.set(&"team", seat)
	bot.set(&"profile", seat_profile(seat))
	add_child(bot)
	commanders.append(bot)
	return bot


func _spawn_aldra() -> void:
	var ht := HelperType.find(&"helper_aldra")
	if ht == null:
		return
	_aldra_anchor = make_unit("rimeling")
	_spawn(_aldra_anchor, ICE_SEAT, GLASS_SPIRE + Vector3(0.0, 0.0, 6.0))
	set_dormant(_aldra_anchor, true)
	_aldra_anchor.visible = false
	_aldra_anchor.collision_layer = 0
	_aldra_anchor.collision_mask = 0
	_aldra_anchor.process_mode = Node.PROCESS_MODE_DISABLED
	mark_scripted(_aldra_anchor)
	aldra = Helper.new()
	var lvl := torvald.level if torvald else 7
	aldra.apply_helper_type(ht, lvl)
	aldra.name = "Aldra"
	_spawn(aldra, ICE_SEAT, GLASS_SPIRE + Vector3(0.0, 0.0, 5.0))
	aldra.set_level(lvl)
	aldra.bond_to(_aldra_anchor)
	aldra.set_stance(&"escort")
	mark_scripted(aldra)
	if bool(_flags().get("e4m3_spire_shattered", false)):
		aldra.add_modifier(&"mission:glass_never_healed", {"max_hp_pct": -0.15})
	aldra.death_guard = func(_a: Variant) -> bool:
		_aldra_flee()
		return true
	_aldra_goal = GLASS_SPIRE + Vector3(0.0, 0.0, 6.0)


func _aldra_flee() -> void:
	if aldra == null or is_dormant(aldra):
		return
	aldra.hp = aldra.max_hp
	set_dormant(aldra, true)
	aldra.visible = false
	aldra.global_position = GLASS_SPIRE + Vector3(0.0, 0.0, 6.0)
	_aldra_goal = GLASS_SPIRE + Vector3(0.0, 0.0, 6.0)
	_aldra_back_left = ALDRA_BACK


func _aldra_return() -> void:
	if aldra == null or not is_instance_valid(aldra):
		return
	if is_dormant(aldra):
		set_dormant(aldra, false)
	aldra.visible = true
	aldra.hp = aldra.max_hp
	_aldra_back_left = -1.0


func _tick_aldra(dt: float) -> void:
	if aldra == null or not is_instance_valid(aldra):
		return
	if not is_dormant(aldra) and aldra.hp < aldra.max_hp * ALDRA_FLEE and not has_fired(&"E19"):
		_aldra_flee()
	if _aldra_back_left > 0.0:
		_aldra_back_left -= dt
		if _aldra_back_left <= 0.0:
			_aldra_return()
	if _aldra_anchor and is_instance_valid(_aldra_anchor):
		_aldra_anchor.global_position = _aldra_goal


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_wall", false), objective_text(&"obj_ysolde", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_ysolde")),
	}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_wall":
			if with_counter:
				if heart_open:
					return "Break the Wall of a Hundred Winters (Wallwardens %d / 2 · Winterheart open)" % wardens_down
				return "Break the Wall of a Hundred Winters (Wallwardens %d / 2 · Winterheart frost-bound)" % wardens_down
			return "Break the Wall of a Hundred Winters"
		&"obj_spire":
			return "Bring Ysolde to Aldra's Glass Spire"
		&"obj_ysolde":
			return "Ysolde must survive"
		&"sec_elder":
			return "Wake the Sleeping Elder"
		&"sec_halls":
			if with_counter:
				return "Break both Frost Halls (%d / 2)" % (2 - _halls_alive())
			return "Break both Frost Halls"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_wall":
			return {"counter": wardens_down, "goal": 2, "position": WINTERHEART}
		&"obj_spire":
			return {"position": GLASS_SPIRE}
		&"sec_elder":
			return {"position": ELDER}
		&"sec_halls":
			return {"counter": 2 - _halls_alive(), "goal": 2}
	return {}


func say_l(id: String) -> void:
	if _said.has(id):
		return
	var n := LINE_IDS.find(id)
	if n < 0:
		return
	_said[id] = true
	said.append(id)
	say_line(n + 1)


# ---------------------------------------------------------------- events

func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e4m4_arrival", func() -> void:
		say_l("L1")
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position))
	for id in ["L2", "L3", "L4", "L5"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 12.0)


func _add_events() -> void:
	after(45.0, func() -> void:
		if fire_once(&"E4") and hud and not is_ending():
			hud.show_message(HINT_SAGE, 10.0))
	after(345.0, func() -> void:
		if not is_ending() and hud and keep and keep.tier < 3:
			hud.show_message(HINT_CITADEL, 12.0))
	after(I1_AT, _fire_wave.bind(&"I1"))
	after(S1_AT, _fire_wave.bind(&"S1"))
	after(VESSA_PUSH_AT, _vessa_push)
	after(I2_AT, _fire_wave.bind(&"I2"))
	after(S2_AT, _fire_wave.bind(&"S2"))
	after(I3_AT, _fire_wave.bind(&"I3"))
	after(float(by_difficulty(WARDEN_WAKE)), func() -> void:
		for id: StringName in wallwardens:
			_wake_warden(id))
	add_event(&"E2", func() -> bool: return fog != null and fog.is_explored(PLAYER_SEAT, ELDER), func() -> void:
		set_objective(&"sec_elder", "active"))
	add_event(&"E7", func() -> bool: return keep != null and is_instance_valid(keep) and keep.tier >= 3, func() -> void:
		say_l("L10")
		_grant_treant(keep.spawn_point() if keep else HEARTWOOD)
		if hud:
			hud.show_message(HINT_TREANT, 10.0))
	add_event(&"E19", func() -> bool: return thawed and hero_alive() and _flat(hero.global_position, GLASS_SPIRE) <= SPIRE_GOAL_R,
			_enough)


func _hall_spawn() -> Vector3:
	for h: Variant in frost_halls:
		if h != null and is_instance_valid(h) and (h as Building).is_alive() and h is TrainingBuilding:
			return (h as TrainingBuilding).spawn_point()
	var k := keep_of(ICE_SEAT)
	return k.spawn_point() if k else RIME_KEEP


## The gate's south side: enemy waves step out of the Wall there (no real doors in this build).
func _out_of(gate: StringName) -> Vector3:
	return (GATES[gate] as Vector3) + Vector3(0.0, 0.0, 5.0)


func _halls_alive() -> int:
	return frost_halls.filter(func(h: Variant) -> bool: return h != null and is_instance_valid(h) and (h as Building).is_alive()).size()


func _fire_wave(id: StringName) -> void:
	if is_ending() or waves_fired.has(id) or thawed and id in [&"I1", &"I2", &"I3"]:
		return
	waves_fired.append(id)
	var cut := func(n: int) -> int: return n - int(floor(n * HALLS_CUT)) if objective_state("sec_halls") == "done" else n
	match id:
		&"I1":
			fire_once(&"E5")
			say_l("L7")
			for u in spawn_wave_at(WAVES[&"I1"], _out_of(&"west"), ICE_SEAT, cut):
				order_wave(u as Unit, &"west_exp", Vector3(-60.0, 0.0, 14.0))
		&"S1":
			fire_once(&"E6")
			say_l("L8")
			say_l("L9")
			for u in spawn_wave_at(WAVES[&"S1"], TITHE_SPAWN, TITHE_SEAT):
				order_wave(u as Unit, &"fire_base", EMBER_HALL)
		&"I2":
			fire_once(&"E10")
			say_l("L13")
			say_l("L14")
			var units := spawn_wave_at(WAVES[&"I2"], _out_of(&"heart"), ICE_SEAT, cut)
			if torvald and is_instance_valid(torvald) and torvald.is_alive():
				set_truce([torvald], false, Unit.TRUCE_ALL)
				torvald.global_position = _out_of(&"heart")
				units.append(torvald)
			for u in units:
				order_wave(u as Unit, &"treant", _out_of(&"heart"))
		&"S2":
			fire_once(&"E14")
			say_l("L20")
			say_l("L18")
			for u in spawn_wave_at(WAVES[&"S2"], TITHE_SPAWN, TITHE_SEAT):
				order_wave(u as Unit, &"fire_base", FIRE_KEEP)
		&"I3":
			fire_once(&"E16")
			say_l("L22b" if bool(_flags().get("e4m3_spire_shattered", false)) else "L22")
			var at := _out_of(&"heart") if _alive(gates.get(&"heart")) else GLASS_SPIRE + Vector3(0.0, 0.0, 6.0)
			var units := spawn_wave_at(WAVES[&"I3"].filter(func(r: Array) -> bool:
					return not (r[0] == "frost_mortar" and objective_state("sec_halls") == "done")), at, ICE_SEAT, cut)
			_aldra_return()
			if aldra and is_instance_valid(aldra):
				aldra.global_position = at + Vector3(1.5, 0.0, 0.0)
				_aldra_goal = WINTERHEART + Vector3(0.0, 0.0, 10.0)
			for u in units:
				order_wave(u as Unit, &"near_heart", WINTERHEART + Vector3(0.0, 0.0, 10.0))


func _alive(b: Variant) -> bool:
	return b != null and is_instance_valid(b) and (b as Building).is_alive()


## E9 (9:00): Vessa's army goes for the East Gate (Hurlers in range), then the Heart Gate once the East Warden is dead.
func _vessa_push() -> void:
	if is_ending():
		return
	fire_once(&"E9")
	say_l("L12")
	vessa_target = &"east"
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ALLY_SEAT and not u.is_worker():
			mark_scripted(u)
			order_wave(u, &"vessa_gate", _out_of(&"east"))


func _push(u: Unit, at: Vector3, near := 4.0) -> void:
	if u.attack_target == null and _flat(u.global_position, at) > near and not u.is_attack_moving():
		u.command_attack_move(at)


func _largest_side0_group() -> Vector3:
	var best := Vector3.INF
	var n := 0
	for v: Variant in treants:
		if v != null and is_instance_valid(v) and (v as Unit).is_alive() and (v as Unit).global_position.z < WALL_Z + 30.0:
			return (v as Unit).global_position
	for x in range(-70, 71, 14):
		var at := Vector3(float(x), 0.0, WALL_Z + 12.0)
		var c := 0
		for m in get_tree().get_nodes_in_group(&"units"):
			var u := m as Unit
			if u and u.is_alive() and Teams.side_of(int(u.team)) == 0 and not u.is_worker() and _flat(u.global_position, at) <= 14.0:
				c += 1
		if c > n:
			n = c
			best = at
	return best


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	if u == torvald and u.hp < u.max_hp * WIZARD_RETREAT and mode != &"withdraw":
		u.set_meta(META_MODE, &"anchor")
		_wave_units.erase(u)
		set_truce([u], true, Unit.TRUCE_ALL)
		u.global_position = TORVALD_PARAPET   # back up on the parapet (behind the Wall)
		u.command_stop()
		return true
	match mode:
		&"west_exp":
			var spot := Vector3(-60.0, 0.0, 14.0)
			var hall := Building.for_team(PLAYER_SEAT).filter(func(b: Building) -> bool:
					return b.is_alive() and _flat(b.global_position, spot) < 12.0)
			_push(u, hall[0].global_position if not hall.is_empty() else GROVE_HALL, 4.0)
			return true
		&"fire_base":
			var target: Vector3 = u.get_meta(META_TARGET, FIRE_KEEP)
			var fk := keep_of(ALLY_SEAT)
			if target == EMBER_HALL and not _alive_near(EMBER_HALL, ALLY_SEAT):
				target = fk.global_position if fk else HEARTWOOD
			_push(u, target, 5.0)
			return true
		&"treant":
			var to := _largest_side0_group()
			_push(u, to if to != Vector3.INF else _out_of(&"heart") + Vector3(0.0, 0.0, 10.0), 4.0)
			return true
		&"near_heart":
			_push(u, WINTERHEART + Vector3(0.0, 0.0, 10.0), 6.0)
			return true
		&"vessa_gate":
			var gate: StringName = vessa_target
			if gate == &"east" and (not _alive(gates.get(&"east")) and _warden_dead(&"east")):
				vessa_target = &"heart"
				gate = &"heart"
			var g: Variant = gates.get(gate)
			if _alive(g):
				if u.attack_target == null or not is_instance_valid(u.attack_target):
					var foe := _enemy_near(u.global_position, 9.0)
					u.command_attack(foe if foe != null else g as Building)
			elif gate == &"east" and not _warden_dead(&"east"):
				_push(u, (GATES[gate] as Vector3) + Vector3(0.0, 0.0, -10.0), 5.0)
			elif thawed:
				_push(u, GLASS_SPIRE + Vector3(0.0, 0.0, 10.0), 6.0)
			elif _alive(winterheart) and heart_open:
				if u.attack_target == null:
					u.command_attack(winterheart)
			else:
				_push(u, (GATES[gate] as Vector3) + Vector3(0.0, 0.0, 8.0), 5.0)
			return true
		&"withdraw", &"anchor", &"warden":
			return true
	return false


func _alive_near(at: Vector3, team: int) -> bool:
	for b in Building.for_team(team):
		if b.is_alive() and _flat(b.global_position, at) < 3.0:
			return true
	return false


func _enemy_near(at: Vector3, r: float) -> Unit:
	var best: Unit = null
	var d := r
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or Teams.side_of(int(u.team)) != 1 or is_dormant(u) or u.has_meta(Unit.TRUCE_META):
			continue
		var dd := _flat(u.global_position, at)
		if dd < d:
			d = dd
			best = u
	return best


# ---------------------------------------------------------------- the Sleeping Elder, the Treants

func _tick_elder(dt: float) -> void:
	if elder_woken or not hero_alive():
		return
	if not elder_totems.filter(func(t: Variant) -> bool: return is_instance_valid(t) and (t as Building).is_alive()).is_empty():
		return
	if _flat(hero.global_position, ELDER) > PLANT_R:
		elder_progress = 0.0
		return
	if _enemy_near(ELDER, PLANT_CLEAR) != null:
		elder_progress = 0.0
		if hud and fire_once(&"elder_clear"):
			hud.show_message(MSG_CLEAR, 4.0)
		return
	elder_progress += dt / PLANT_TIME
	if elder_progress >= 1.0:
		elder_woken = true
		fire_once(&"E3")
		flash_ring(ELDER, 5.0)
		_grant_treant(ELDER)
		say_l("L6")
		set_objective(&"sec_elder", "done")


func _grant_treant(at: Vector3) -> void:
	if _treant_type == null:
		return
	var t := _spawn(Worker.make_unit(_treant_type), PLAYER_SEAT, at + Vector3(0.0, 0.0, 3.0))
	treants.append(t)
	if fire_once(&"E8"):
		say_l("L11")
		show_spotlight()


# ---------------------------------------------------------------- the Wall

func _on_gate_damaged(_amount: float, _attacker: Variant, id: StringName) -> void:
	var g: Variant = gates.get(id)
	if _alive(g) and (g as Building).hp < (g as Building).max_hp * 0.5 and wallwardens.has(id):
		_wake_warden(id)


func _on_gate_destroyed(_b: Building, id: StringName) -> void:
	if is_ending() or thawed:
		return
	if fire_once(&"E11"):
		say_l("L15")
	if wallwardens.has(id):
		_wake_warden(id)


func _wake_warden(id: StringName) -> void:
	var w: Variant = wallwardens.get(id)
	if w == null or not is_instance_valid(w) or not (w as Unit).is_alive() or not is_dormant(w):
		return
	set_dormant(w as Unit, false)
	(w as Unit).global_position = _out_of(id)   # it steps out through its gate (no real doors in this build)
	order_wave(w as Unit, &"warden", _out_of(id))
	_stomp_left[w] = float(by_difficulty(STOMP_EVERY))
	if fire_once(&"E12"):
		play_cutscene(&"e4m4_wardens", func() -> void:
			say_l("L16")
			say_l("L17"))


func _warden_dead(id: StringName) -> bool:
	var w: Variant = wallwardens.get(id)
	return w == null or not is_instance_valid(w) or not (w as Unit).is_alive()


func _on_wallwarden_died(_u: Unit, id: StringName) -> void:
	if is_ending():
		return
	wardens_down += 1
	_stomp_left.erase(_u)
	if fire_once(&"E13"):
		say_l("L19")
	if wardens_down >= 2:
		fire_once(&"E15")
		say_l("L21")
		if not _try_open_heart() and hud:
			hud.show_message(MSG_HEART_BOUND, 8.0)
	set_objective(&"obj_wall", "active")
	if id == &"east" and vessa_target == &"east":
		vessa_target = &"heart"


## The Winterheart opens once both wardens are down AND at heart_opens_at (19:00): true once open.
func _try_open_heart() -> bool:
	if heart_open:
		return true
	if wardens_down < 2 or mission_time() < heart_opens_at or not _alive(winterheart):
		return false
	heart_open = true
	set_truce([winterheart], false, Unit.TRUCE_ALL)
	flash_ring(WINTERHEART, 3.0)
	if hud and mission_time() > 1.0 and not is_ending():
		hud.show_message(MSG_HEART_OPEN, 6.0)
	return true


## The Wallwardens' brain: the nearest Elder Treant, else the largest side-0 group within 30 m of the Wall; never more
## than 30 m south of it; Avalanche Stomp every 12 s (60 + chill 2 s, r 4).
func _tick_wardens(dt: float) -> void:
	for id: StringName in wallwardens:
		var w: Variant = wallwardens[id]
		if w == null or not is_instance_valid(w) or not (w as Unit).is_alive() or is_dormant(w):
			continue
		var u := w as Unit
		if u.global_position.z > WARDEN_LEASH_Z:
			u.command_move(Vector3(u.global_position.x, 0.0, WALL_Z + 10.0))
		elif u.attack_target == null:
			var to := _largest_side0_group()
			if to != Vector3.INF:
				u.command_attack_move(to)
		_stomp_left[u] = float(_stomp_left.get(u, 12.0)) - dt
		if float(_stomp_left[u]) <= 0.0:
			_stomp_left[u] = float(by_difficulty(STOMP_EVERY))
			for n in get_tree().get_nodes_in_group(&"units"):
				var v := n as Unit
				if v and v.is_alive() and Teams.side_of(int(v.team)) == 0 and _flat(v.global_position, u.global_position) <= STOMP_R:
					v.take_damage(STOMP_DMG, u)
					if v.has_method(&"apply_status"):
						v.call(&"apply_status", &"chill", 2.0)


## E17: the Winterheart shatters: e4m4_thaw, the thaw (pieces -50 %, gates open, spires dark, no regrowth), the spire
## guard, Torvald to his keep door, obj_spire.
func _on_winterheart_destroyed(_b: Building) -> void:
	if is_ending():
		return
	fire_once(&"E17")
	thawed = true
	set_objective(&"obj_wall", "done")
	_apply_thaw_types()
	for v: Variant in wall:
		if _alive(v):
			var b := v as Building
			if (b as WinterWall).is_gate:
				b.take_damage(1.0e7, null)
			else:
				b.hp = b.hp * 0.5
	for s: Variant in wall_spires:
		if _alive(s):
			(s as Building).hp = (s as Building).hp * 0.5
	if torvald and is_instance_valid(torvald) and torvald.is_alive():
		_wave_units.erase(torvald)
		torvald.set_meta(META_MODE, &"anchor")
		torvald.set_meta(META_HOME, RIME_KEEP + Vector3(0.0, 0.0, 8.0))
		set_truce([torvald], false, Unit.TRUCE_ALL)
		torvald.command_move(RIME_KEEP + Vector3(0.0, 0.0, 8.0))
	var cut := func(n: int) -> int: return n - int(floor(n * HALLS_CUT)) if objective_state("sec_halls") == "done" else n
	for u in spawn_group(WAVES[&"SPIRE"], GLASS_SPIRE + Vector3(0.0, 0.0, 7.0), 6.0, ICE_SEAT, true):
		if objective_state("sec_halls") == "done" and randf() < HALLS_CUT and not (u as Unit) is Wizard:
			(u as Unit).queue_free()
	_aldra_return()
	if aldra and is_instance_valid(aldra):
		aldra.hp = aldra.max_hp
		_aldra_goal = GLASS_SPIRE + Vector3(0.0, 0.0, 6.0)
	play_cutscene(&"e4m4_thaw", func() -> void:
		say_l("L23")
		say_l("L24")
		say_l("L25")
		say_l("L26")
		set_objective(&"obj_spire", "active"))


func _on_frost_hall_destroyed(_b: Building) -> void:
	if is_ending():
		return
	if _halls_alive() == 0:
		fire_once(&"E18")
		say_l("L27")
		set_objective(&"sec_halls", "done")
	else:
		set_objective(&"sec_halls", "active")


## The thaw on the code-made types (idempotent): no regrowth, the Wall's spires dark.
func _apply_thaw_types() -> void:
	if _wall_type:
		_wall_type.idle_regen_pct = 0.0
	if _gate_type:
		_gate_type.idle_regen_pct = 0.0
	if _wall_small_type:
		_wall_small_type.idle_regen_pct = 0.0
	if _spire_type:
		_spire_type.attack_damage = 0.0


# ---------------------------------------------------------------- save / load (mission-save-hardening C4-3, C4-5)

## The types the thaw changed, the open Winterheart out of its truce (the framework reconciles the meta; this also
## covers a heart opened by _try_open_heart), Wallwardens' died hooks.
func _after_load(_nodes: Dictionary) -> void:
	if thawed:
		_apply_thaw_types()
	if heart_open and _alive(winterheart):
		set_truce([winterheart], false, Unit.TRUCE_ALL)
	for id: StringName in wallwardens:
		var w: Variant = wallwardens[id]
		if w is Unit and is_instance_valid(w) and not MissionBase.is_hooked((w as Unit).died, &"_on_wallwarden_died"):
			(w as Unit).died.connect(_on_wallwarden_died.bind(id))


## E19: Ysolde reaches the spire: e4m4_enough (Torvald stops Aldra), the Withdraw, victory.
func _enough() -> void:
	if is_ending():
		return
	victory_time = mission_time()
	set_objective(&"obj_spire", "done")
	if objective_state("sec_elder") != "done":
		set_objective(&"sec_elder", "failed")
	if objective_state("sec_halls") == "active":
		set_objective(&"sec_halls", "failed")
	_record_flags()
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.side_of(int(u.team)) == 1 and not u.is_worker():
			set_truce([u], true, Unit.TRUCE_ALL)
			u.set_meta(META_MODE, &"withdraw")
			u.command_move(RIME_KEEP + Vector3(randf_range(-6.0, 6.0), 0.0, 10.0))
	if hero_alive():
		hero.hp = hero.max_hp
	play_cutscene(&"e4m4_enough", func() -> void:
		for id in ["L28", "L29", "L30", "L31", "L32", "L33", "L34"]:
			say_l(id)
		set_objective(&"obj_ysolde", "done")
		win(VICTORY_DELAY))


func _record_flags() -> void:
	set_mission_flag("e4m4_time", int(victory_time))
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	var essence := bank.essence if bank else 0
	if elder_woken:
		essence += 300
	if objective_state("sec_halls") == "done":
		essence += 300
	set_mission_flag(CampaignState.YSOLDE_ESSENCE_FLAG, mini(ESSENCE_CAP, essence / 2))


# ---------------------------------------------------------------- wizards

func _on_torvald_died(_u: Unit) -> void:
	if is_ending():
		return
	_wave_units.erase(torvald)
	if hud:
		hud.show_message(MSG_TORVALD_FELL, 4.0)
	after(TORVALD_BACK, _torvald_back)


func _torvald_back() -> void:
	if torvald and is_instance_valid(torvald) and not torvald.is_alive() and not is_ending():
		torvald.respawn(respawn_point(ICE_SEAT))
		if not thawed:
			set_truce([torvald], true, Unit.TRUCE_ALL)
			torvald.global_position = TORVALD_PARAPET
		torvald.set_meta(META_MODE, &"anchor")


func _on_bot_wizard_died(_u: Unit, seat: int) -> void:
	if is_ending():
		return
	_respawn_left[seat] = next_respawn_delay(seat)
	_deaths[seat] = int(_deaths.get(seat, 0)) + 1
	if seat == ALLY_SEAT and hud:
		hud.show_message(MSG_VESSA_FELL, 4.0)


func _on_fire_keep_destroyed(_b: Building) -> void:
	if is_ending():
		return
	fire_once(&"E22")
	if hud:
		hud.show_message(MSG_VESSA_FELL, 4.0)
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ALLY_SEAT and not u.is_worker():
			u.command_move(PLAYER_RALLY)


func _on_player_hero_fell() -> void:
	fire_once(&"E20")
	say_l("L35")
	set_objective(&"obj_ysolde", "failed")
	super()


func _tick_torvald() -> void:
	if torvald == null or not is_instance_valid(torvald) or not torvald.is_alive() or _wave_units.has(torvald):
		return
	var home: Vector3 = torvald.get_meta(META_HOME, TORVALD_PARAPET)
	if torvald.attack_target == null and _flat(torvald.global_position, home) > 4.0 and not torvald.has_move_order():
		torvald.command_move(home)


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_aldra(delta)
	_tick_wardens(delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick_elder(0.5 - _tick)
		_tick = 0.5
		_try_open_heart()
		_tick_torvald()
		if maelis == null or not is_instance_valid(maelis):
			maelis = _find_maelis()
		var t := "%s|%s" % [objective_text(&"obj_wall"), objective_text(&"sec_halls")]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
