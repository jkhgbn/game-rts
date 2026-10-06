class_name MissionE2_01
extends MissionBase
## Campaign mission e2m1, "The Burning Grove" (docs/design/mission-e2-01.md = source of truth): Episode 2 mission 1, the
## first 2v1. Vessa (Fire, a Stronghold at 0:00) against Malrik (Shadow, the bot Commander) and Torvald (Ice, a
## scripted camp: no workers, no Commander, scripted waves only; both are team ENEMY, decision D1). Map: the M3 Sighing
## Wood (the main.gd generator, seed 1303, not mirrored) burnt and frozen. Torvald's frost creeps over the Last
## Heartwood (MissionHeartwood) from three Rime Totems; Vessa breaks the siege, kindles the tree (4 m / 3 s, never with
## an enemy or a totem within 10 m) and holds the glade for 12:00 against waves H1-H6 from both camps. Side jobs:
## Ysolde's people at three hideouts (Wren, the survivor walk home), Torvald's Frost Hall, the Citadel and Old Vey (the
## first call of the helper, this mission's price). Spotlight: Old Vey (unit-spotlights.md 2.2).
## Placeholder art in code (E2M1.V1 replaces it); the three cinematics play their fallbacks (lines + camera).

const MISSION_ID := &"e2m1"
const MISSION_TITLE := "The Burning Grove"
const MAP_SEED := 1303

const EMBER_HALL_POS := Vector3(-27.0, 0.0, 45.0)
const HEARTH_POS := Vector3(-36.0, 0.0, 50.0)
const EMBER_SPIRE_POS := Vector3(-32.0, 0.0, 30.0)
const ARMY_POS := Vector3(-32.0, 0.0, 32.0)
const VEY_START := Vector3(-34.0, 0.0, 34.0)
const VEY_EXIT := Vector3(-10.0, 0.0, -58.0)
## id -> [position, crystals]
const E2_NODES := {
	&"e2m1_fire_a": [Vector3(-46.0, 0.0, 34.0), 1500],
	&"e2m1_fire_b": [Vector3(-34.0, 0.0, 46.0), 1500],
	&"e2m1_west": [Vector3(-50.0, 0.0, 8.0), 2000],
	&"e2m1_south": [Vector3(4.0, 0.0, 50.0), 1500],
	&"node_shadow_a": [Vector3(46.0, 0.0, -34.0), 1500],
	&"node_shadow_b": [Vector3(34.0, 0.0, -46.0), 1500],
	&"e2m1_ice_a": [Vector3(-46.0, 0.0, -34.0), 1500],
	&"e2m1_ice_b": [Vector3(-34.0, 0.0, -46.0), 1500],
}
const FIRE_SUFFIXES := {&"a": &"e2m1_fire_a", &"b": &"e2m1_fire_b", &"mid": &"e2m1_south", &"rich": &"e2m1_west"}
const SHADOW_SUFFIXES := {&"a": &"node_shadow_a", &"b": &"node_shadow_b"}
const WEST_HALL_SPOT := Vector3(-43.0, 0.0, 9.0)
const SOUTH_HALL_SPOT := Vector3(-3.0, 0.0, 51.0)
const E2_CACHE_SPOTS: Array[Vector3] = [Vector3(-15.0, 0.0, -15.0), Vector3(30.0, 0.0, 0.0)]

## The glade.
const OLDROOT_POS := Vector3.ZERO
const OLDROOT_RADIUS := 3.0
const GLADE_CENTER := Vector3(0.0, 0.0, 4.0)
const GLADE_RADIUS := 14.0
const HEARTWOOD_POS := Vector3(0.0, 0.0, 9.0)
const TOTEM_SPOTS: Array[Vector3] = [Vector3(-7.0, 0.0, 9.0), Vector3(7.0, 0.0, 9.0), Vector3(0.0, 0.0, 16.0)]
const TOTEM_HP := 400.0
const ALDRA_SPOT := Vector3(-3.0, 0.0, 14.0)
const KINDLE_RANGE := 6.0          ## Vessa within 4 m of the Heartwood's edge (radius 2)...
const KINDLE_TIME := 3.0           ## ...for this long.
const KINDLE_CLEAR := 10.0         ## No enemy unit and no Rime Totem this close to the Heartwood.
const REGROW_PCT := 0.005          ## Of max HP per second while no enemy is within REGROW_CLEAR.
const REGROW_CLEAR := 12.0
const SAP_RADIUS := 8.0
const SAP_STATS := {"hp_regen": 3.0}
const E5_RADIUS := 18.0

## Hideouts: id -> [name, position, guard rows]
const HIDEOUTS := {
	&"S1": ["Fernhollow", Vector3(-30.0, 0.0, -4.0), [["grave_hound", 3], ["shade", 1]], 4.0],
	&"S2": ["Charred Glade", Vector3(26.0, 0.0, 28.0), [["rimeshield", 2], ["shardcaster", 2]], 4.0],
	&"S3": ["Greenhold ruins", Vector3(43.0, 0.0, 43.0), [["shade", 3], ["nightbolt", 2], ["rimeshield", 1],
			["rime_seer", 1]], 6.0],
}
const FREE_RADIUS := 6.0
const FOLK_PER_HIDEOUT := 4
const FOLK_HOME_RADIUS := 8.0
const FOLK_GOAL := 10
const FOLK_FAIL := 3
const PING_EVERY := 30.0

## Camps.
const DUSK_KEEP_POS := Vector3(43.0, 0.0, -43.0)
const GLOOM_HALL_POS := Vector3(27.0, 0.0, -45.0)
const NIGHT_SPIRE_POS := Vector3(37.0, 0.0, -29.0)
const HOVEL_POS := Vector3(50.0, 0.0, -46.0)
const SHADOW_RALLY := Vector3(30.0, 0.0, -30.0)
const SHADOW_CORNER := Vector3(56.0, 0.0, -56.0)
const RIME_KEEP_POS := Vector3(-43.0, 0.0, -43.0)
const RIME_KEEP_HP := 3000.0
const FROST_HALL_POS := Vector3(-27.0, 0.0, -45.0)
const RIME_SPIRE_POS := Vector3(-37.0, 0.0, -29.0)
const RIME_SPIRE_HP := 720.0
const SNOW_LODGE_POS := Vector3(-50.0, 0.0, -46.0)
const ICE_RALLY := Vector3(-30.0, 0.0, -30.0)
const ICE_CORNER := Vector3(-56.0, 0.0, -56.0)
const G1_POS := Vector3(-20.0, 0.0, 20.0)
## G2 stands in a ring around the Heartwood, between the totems (the spec's r 7 around (0, 9) touches the Oldroot's
## trunk at (0, 2): the ring is r 5.5 around (0, 10) instead).
const G2_CENTER := Vector3(0.0, 0.0, 10.0)
const G2_RING := 5.5
const E3_SIGHT := 14.0

## Timing (mission seconds).
const INTRO_LINES_END := 25.0      ## E2 after L3.
const P1_TIME := 180.0
const H_OFFSETS := {&"H1": 30.0, &"H2": 150.0, &"H3": 270.0, &"H4": 390.0, &"H5": 510.0, &"H6": 630.0, &"H7": 720.0}
const RAID_FIRST := 60.0
const RAID_EVERY := 150.0
const WIZARD_RESPAWN := 60.0
const EAVESDROP_RADIUS := 12.0
const EAVESDROP_LEAD := 30.0
const WREN_NEAR := 3.0
const WREN_FAR := 6.0
const WREN_KNEEL := 8.0
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 2.0
const LEVEL_CAP := 8
const NO_SAVE_ESSENCE := 600

## Difficulty tables [easy, normal, hard].
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [500, 400, 300]
const FROST_RATE: Array[float] = [0.238, 0.278, 0.333]   ## % / s with all three totems.
const HOLD_SECONDS: Array[float] = [600.0, 720.0, 810.0]
const HEARTWOOD_HP: Array[float] = [1800.0, 1500.0, 1300.0]
const WIZARD_LEVEL: Array[int] = [4, 5, 6]
const WIZARD_LATE_LEVEL: Array[int] = [5, 6, 7]
const MALRIK_SPELLS := [&"shadow_lance", &"shadow_lance", &"soul_siphon", &"soul_siphon", &"umbral_shroud"]
const TORVALD_SPELLS := [&"rime_bolt", &"rime_bolt", &"flash_freeze", &"flash_freeze", &"rime_aegis"]
const VEY_PRICE := {"crystals": [200, 250, 300], "essence": [50, 100, 150], "time": [30.0, 30.0, 45.0]}

## Waves: id -> {side, rows, torvald, malrik}. Ice rows lose 40 % once the Frost Hall burns (sec_frosthall).
const WAVES := {
	&"H1": {"side": &"shadow", "rows": [["shade", 4], ["nightbolt", 2], ["grave_hound", 2]]},
	&"H2": {"side": &"ice", "rows": [["rimeshield", 4], ["shardcaster", 3], ["rime_seer", 1]], "torvald": true},
	&"H3": {"side": &"shadow", "rows": [["shade", 5], ["nightbolt", 3], ["shadow_knight", 1], ["gloom_deacon", 1]]},
	&"H4": {"side": &"ice", "rows": [["rimeshield", 4], ["shardcaster", 2], ["rime_colossus", 1], ["frost_mortar", 1]],
			"torvald": true},
	&"H5": {"side": &"both", "rows": [["shade", 4], ["nightbolt", 2], ["shadow_knight", 1]],
			"ice_rows": [["rimeshield", 3], ["shardcaster", 2], ["rime_seer", 1]], "malrik": true},
	&"H6": {"side": &"both", "rows": [["shade", 6], ["nightbolt", 3], ["shadow_knight", 1]],
			"ice_rows": [["rimeshield", 4], ["shardcaster", 2], ["rime_colossus", 1]], "malrik": true, "torvald": true},
	&"H7": {"side": &"both", "rows": [["shade", 4], ["nightbolt", 2], ["grave_hound", 2]],
			"ice_rows": [["rimeshield", 4], ["shardcaster", 3], ["rime_seer", 1]], "malrik": true, "torvald": true},
}
const EASY_SKIP: Array[StringName] = [&"rime_colossus", &"frost_mortar"]

const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1),
	&"vey": Color(0.95, 0.95, 0.55),
	&"messenger": Color(0.80, 0.92, 0.60),
	&"ashby": Color(0.95, 0.60, 0.35),
	&"malrik": Color(0.7, 0.3, 1.0),
	&"torvald": Color(0.55, 0.80, 1.00),
	&"aldra": Color(0.62, 0.95, 0.88),
	&"ysolde": Color(0.55, 0.90, 0.35),
	&"narrator": Color(0.9, 0.85, 0.7),
}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"vey": "Old Vey", &"messenger": "Wren", &"ashby": "Captain Ashby",
		&"malrik": "Malrik", &"torvald": "Torvald", &"aldra": "Aldra", &"ysolde": "Ysolde", &"narrator": "Narrator"}
## The 31 lines (subtitle text where the spec gives a clean reading); line n = L<n>.
const DIALOGUE := [
	[&"narrator", "The Sighing Wood kept out of every quarrel for a century. Now it is ash, and the ash is frozen."],
	[&"vessa", "Fire AND frost. They didn't just burn it. They made sure it stayed dead."],
	[&"messenger", "The Heartwood is past the old tree. She's inside it."],
	[&"vey", "I'll ride the north road and see what Torvald brought. Light the beacon when you want the storm."],
	[&"vessa", "You just got back, and you're leaving again? You're lucky I'm busy."],
	[&"vessa", "Shades in the ashes. Malrik never could resist a funeral."],
	[&"ashby", "Shadow at the camp, my queen! We'll hold the hall. Go!"],
	[&"aldra", "Hold the rime. When the green stops beating, the wood is ours."],
	[&"torvald", "So the little ember comes to warm the wood. You are late, child. Winter got here first."],
	[&"aldra", "Cracked. Not broken. Torvald will hear of this."],
	[&"vessa", "You always said fire was the problem, Ysolde. Today it's the answer."],
	[&"messenger", "The roots are warm again!"],
	[&"malrik", "Vessa. Have you noticed whose side the winter is on now?"],
	[&"vessa", "Two of you, one of me. Sounds fair. For me."],
	[&"torvald", "I told Malrik no, once. Then I watched you carry three keys toward the Hollow."],
	[&"vessa", "So you picked the man who sends knives at night. Great judgement, Torvald."],
	[&"vessa", "The beacon's lit. Vey! You said call. I'm calling!"],
	[&"vessa", "Twelve years late, then twelve hours. You're improving."],
	[&"vey", "The spark first. Then the storm!"],
	[&"messenger", "You're alive! Go south, follow the red banners!"],
	[&"messenger", "That's everyone who could still walk."],
	[&"vessa", "That's one hall Torvald won't need to keep cold any more."],
	[&"narrator", "Shadow from the east, frost from the north. The two new friends close the vice."],
	[&"torvald", "Now, Bishop. Before the spring remembers itself."],
	[&"messenger", "The heart's slowing! Please don't let it stop!"],
	[&"torvald", "Spring is stubborn. So is winter. This is not over, child."],
	[&"ysolde", "You came. I told you to remember. I didn't think you'd listen."],
	[&"vessa", "I never listen. I just show up."],
	[&"aldra", "The green has stopped. Winter keeps this wood now."],
	[&"vessa", "Ysolde... I came. I really came..."],
	[&"messenger", "No. It's gone cold."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The feast ended at midnight. By first light the Emberguard was on the road north, and by noon it reached the Sighing Wood, or what is left of it: black trunks under white frost, ash that crunches like snow.",
	"Shadow burned the wood and Ice froze the ashes so nothing could grow back. Wren says one heart still beats: the Last Heartwood, beside the dead Oldroot, where Ysolde fell back with her final wardens. Torvald's frost is creeping over it.",
	"Malrik and Torvald hold the north of the wood, one camp each. Two wizards against one. Vessa has never been good at arithmetic, and she is not about to start.",
]
const BRIEFING_FROST_LINE := "Torvald's frost is creeping over the Heartwood. Reach it before it stops beating."
const HINT_START := "Reach the Heartwood past the dead oak. Clear the glade, then hold Vessa beside it to kindle it."
const HINT_FOLK := "Wren knows where the survivors hide (green pings). Free them and they walk to your keep."
const HINT_HOLD := "Hold the glade. Shadow comes from the north-east, Ice from the north-west."
const HINT_CITADEL := "Your Stronghold can become a Citadel: select the Keep and press X (300 crystals, 90 s). It opens the Ashveil Saboteur (C) and lets you call Old Vey (V)."
const HINT_CALL := "Call Old Vey: select the Keep and press V. He fights on his own; his card sets where (Escort / Vanguard / Hold home)."
const MSG_KINDLE_BLOCKED := "Clear the glade first: the roots won't open while the enemy stands in it"
const MSG_FROST_HALF := "The frost has taken half the Heartwood"
const MSG_FROST_80 := "The Heartwood is almost frozen"
const MSG_MALRIK_FELL := "Malrik has fallen back into the shadows"
const MSG_TORVALD_FELL := "Torvald has fallen, the frost will bring him back"
const MSG_EAVESDROP_ICE := "Eavesdrop: Ice wave in 0:30 · {units}"
const MSG_EAVESDROP_SHADOW := "Eavesdrop: Shadow wave in 0:30 · {units}"

## Test / menu switch (before the tree): campaign flags to use instead of the save ({} = read the save).
var flag_override: Dictionary = {}

## Read only.
var heartwood: MissionHeartwood
var totems: Array[Building] = []
var frost := 0.0                       ## 0-100 %.
var kindle_progress := 0.0             ## 0-1 while Vessa stands by the Heartwood.
var kindle_blocked := false
var kindled := false
var kindle_time := -1.0                ## Mission time of the kindle (T).
var hold_left := -1.0                  ## Seconds of the hold left (-1 before / after).
var hold_done := false
var ember_hall: TrainingBuilding
var gloom_hall: Building
var frost_hall: TrainingBuilding
var rime_keep: Building
var torvald: Wizard
var aldra: Unit
var wren: Unit
var vey_npc: Unit
var guard_groups := {}                 ## &"G1".."G6" -> Array of units.
var hideout_freed := {}                ## &"S1".. -> true once freed.
var folk: Array = []                   ## The freed survivors still walking.
var folk_home := 0
var folk_dead := 0
var waves_fired: Array[StringName] = []
var wave_units := {}                   ## wave id -> Array of units.
var said: Array[int] = []              ## Line numbers said, in order.
var vey_arrived := false
var no_save_fallback := false
var heart_wardens: Array = []                ## Ysolde's last wardens (kindle).

var _hall_type: BuildingType
var _folk_type: UnitType
var _wren_type: UnitType
var _story_vey_type: UnitType
var _warden_types := {}
var _flags_read := false
var _said: Dictionary = {}
var _tick := 0.0
var _frost_msgs := {}
var _ping_left := PING_EVERY
var _wren_kneel_left := 0.0
var _torvald_home := true
var _eaves_said := {}
var _last_obj_text := ""


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	tavern_enabled = true   # no tavern on this map (the Crooked Lantern is a ruin): the guild only carries the companion
	define_objectives([[&"obj_heartwood", "primary"], [&"obj_hold", "primary"], [&"obj_vessa", "primary"],
			[&"sec_folk", "secondary"], [&"sec_frosthall", "secondary"], [&"sec_storm", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = true   # E23
	c.keep_lost_message = "The Fire keep has fallen"
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {Unit.Team.PLAYER: 2}
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
	c.bot_profile_id = bot_profile()
	c.bot_team = Unit.Team.ENEMY
	c.victory_banner = "VICTORY\nThe Last Heartwood beats again"
	c.defeat_banner = "DEFEAT"
	c.rewards = {"flags": {"e2m1_folk_saved": "sec_folk", "e2m1_frosthall_shattered": "sec_frosthall",
			"e2m1_vey_called": "sec_storm"}, "bonus_essence": {"sec_folk": 300, "sec_frosthall": 150},
			"set_flags": {"helper_vey_unlocked": true}, "next": &"e2m2"}
	c.spotlight = {"id": &"helper_vey", "trigger": &"unlock", "key_hint": "Keep: V",
			"card": "Old Vey. Your old teacher, sword and storm: call him at the Citadel and point him at the crowd."}
	return c


## AIProfile.mission_e2_01() when the ai-coder added it (E2M1.A1), else mission 3's (Shadow normal knobs, never
## attacks, a small rally army): Malrik's camp gathers, trains and defends; the scripted waves do the attacking.
static func bot_profile() -> StringName:
	var script := load("res://scripts/ai/ai_profile.gd") as Script
	if script:
		var names: Array[StringName] = []
		for m in script.get_script_method_list():
			names.append(StringName(m["name"]))
		for id: StringName in [&"mission_e2_01", &"mission_03"]:
			if names.has(id):
				return id
	return &"mission_01"


func _ready() -> void:
	_hall_type = _make_hall_type()
	_folk_type = _make_story_type("thornling", &"wood_folk", "Wood-folk", 45.0, 4.5)
	_wren_type = _make_story_type("wildwood_archer", &"wren", "Wren", 260.0, 5.2)
	_story_vey_type = _make_vey_type()
	for id in ["thornling", "bloomtender"]:
		var base := UnitType.find(id)
		if base:
			var t := base.duplicate() as UnitType
			t.pop = 0   # Ysolde's guests: they never take Fire pop
			_warden_types[id] = t
	get_tree().node_added.connect(_on_e2_node_added)
	super()


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_e2_node_added):
		get_tree().node_added.disconnect(_on_e2_node_added)


func _lighting_preset() -> StringName:
	return &"warm"   # E2M1.V1: the grey-white "Look" preset when the lighting rig has it


func _lane_end() -> Vector3:
	return HEARTWOOD_POS


func _title_line() -> String:
	return "Episode 2, Mission 1: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(PLAYER_START.x, PLAYER_START.z, 13.0, 0.0), Vector4(SHADOW_START.x, SHADOW_START.z, 13.0, 0.0),
			Vector4(GLADE_CENTER.x, GLADE_CENTER.z, 12.0, 0.0), Vector4(RIME_KEEP_POS.x + 7.0, RIME_KEEP_POS.z + 7.0, 12.0, 0.0)]


func node_of(team: int, suffix: String) -> CrystalNode:
	var table: Dictionary = SHADOW_SUFFIXES if team == Unit.Team.ENEMY else FIRE_SUFFIXES
	var id: StringName = table.get(StringName(suffix), &"")
	if id == &"":
		return null
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		crystal_nodes.erase(id)
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(team: int) -> Vector3:
	return SOUTH_HALL_SPOT if team == Unit.Team.PLAYER else super(team)


func rich_hall_spot(team: int) -> Vector3:
	return WEST_HALL_SPOT if team == Unit.Team.PLAYER else super(team)


## Malrik comes back at the Dusk Keep (or its corner once it is gone).
func respawn_point(team: int) -> Vector3:
	if team == Unit.Team.ENEMY:
		var k := keep_of(team)
		return k.spawn_point() if k else SHADOW_CORNER
	return super(team)


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	_read_flags()
	var rng := RandomNumberGenerator.new()
	rng.seed = MAP_SEED
	var clearings := map_clearings()
	var keep_out := func(p: Vector3) -> bool:
		return _in_clearing(p, clearings) or _in_path_lane(p)
	for cluster in 16:   # the M3 broadleaf clusters, burnt (E2M1.V1: charred trunks, frosted tops)
		var center := Vector3(rng.randf_range(-52, 52), 0.0, rng.randf_range(-52, 52))
		for i in rng.randi_range(6, 10):
			var p := center + Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6))
			var s := rng.randf_range(0.9, 1.5)
			if absf(p.x) > 57.0 or absf(p.z) > 57.0 or keep_out.call(p):
				continue
			_add_burnt_tree(p, s)
	for i in 18:
		var p := Vector3(rng.randf_range(-54, 54), 0.0, rng.randf_range(-54, 54))
		var s := rng.randf_range(0.8, 2.0)
		var rot := rng.randf() * TAU
		if keep_out.call(p):
			continue
		_add_rock(p, s, rot)
	_add_dead_oldroot()

	# Fire: the Emberwatch (keep tier 2 through config.start_tiers), Ember Hall, Hearth, Ember Spire.
	keep = build_grid.spawn_complete(BuildingType.find("fire_keep"), PLAYER_START + KEEP_OFFSET, Unit.Team.PLAYER) as Keep
	ember_hall = build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL_POS,
			Unit.Team.PLAYER) as TrainingBuilding
	build_grid.spawn_complete(BuildingType.find("fire_hearth"), HEARTH_POS, Unit.Team.PLAYER)
	build_grid.spawn_complete(BuildingType.find("fire_tower"), EMBER_SPIRE_POS, Unit.Team.PLAYER)
	# Shadow: Malrik's camp (the bot's base).
	shadow_keep = build_grid.spawn_complete(BuildingType.find("shadow_keep"), DUSK_KEEP_POS, Unit.Team.ENEMY) as Keep
	gloom_hall = build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL_POS, Unit.Team.ENEMY)
	build_grid.spawn_complete(BuildingType.find("shadow_tower"), NIGHT_SPIRE_POS, Unit.Team.ENEMY)
	build_grid.spawn_complete(BuildingType.find("shadow_hovel"), HOVEL_POS, Unit.Team.ENEMY)
	# Ice: Torvald's camp, all scripted (D1: no workers, no Commander; the Shadow bot never trains at the Frost Hall).
	rime_keep = build_grid.spawn_complete(BuildingType.find("ice_keep"), RIME_KEEP_POS, Unit.Team.ENEMY)
	if rime_keep:
		rime_keep.max_hp = RIME_KEEP_HP
		rime_keep.hp = RIME_KEEP_HP
		mark_scripted(rime_keep)
	frost_hall = build_grid.spawn_complete(BuildingType.find("ice_barracks"), FROST_HALL_POS,
			Unit.Team.ENEMY) as TrainingBuilding
	if frost_hall:
		mark_scripted(frost_hall)
		frost_hall.set_meta(TrainingBuilding.META_LOCKED, true)
		frost_hall.destroyed.connect(_on_frost_hall_destroyed)
	var spire := build_grid.spawn_complete(BuildingType.find("ice_tower"), RIME_SPIRE_POS, Unit.Team.ENEMY)
	if spire:
		spire.max_hp = RIME_SPIRE_HP
		spire.hp = RIME_SPIRE_HP
		mark_scripted(spire)
	var lodge := build_grid.spawn_complete(BuildingType.find("ice_lodge"), SNOW_LODGE_POS, Unit.Team.ENEMY)
	if lodge:
		mark_scripted(lodge)
	for id: StringName in E2_NODES:
		_add_crystal_node(id, E2_NODES[id][0], int(E2_NODES[id][1]))

	# The Heartwood (truce &"all" and invulnerable until the kindle) and the three Rime Totems.
	var diff := clampi(mission_difficulty, 0, 2)
	heartwood = MissionHeartwood.new()
	heartwood.building_type = MissionHeartwood.make_type(HEARTWOOD_HP[diff], SAP_STATS)
	heartwood.name = "LastHeartwood"
	heartwood.team = Unit.Team.PLAYER
	heartwood.position = build_grid.snap(HEARTWOOD_POS, heartwood.building_type.footprint)
	nav_region.add_child(heartwood, true)
	heartwood.destroyed.connect(_on_heartwood_destroyed)
	var totem_type := _make_totem_type()
	for p in TOTEM_SPOTS:
		var t := build_grid.spawn_complete(totem_type, p, Unit.Team.ENEMY)
		if t:
			mark_scripted(t)
			t.destroyed.connect(_on_totem_destroyed)
			totems.append(t)


## Every clearing of the generator: [position, radius].
func map_clearings() -> Array:
	var out := [[PLAYER_START, 18.0], [DUSK_KEEP_POS + Vector3(-7.0, 0.0, 7.0), 18.0], [EMBER_HALL_POS, 4.0],
			[HEARTH_POS, 3.0], [EMBER_SPIRE_POS, 3.0], [GLOOM_HALL_POS, 4.0], [NIGHT_SPIRE_POS, 3.0], [HOVEL_POS, 4.0],
			[RIME_KEEP_POS + Vector3(7.0, 0.0, 7.0), 18.0], [FROST_HALL_POS, 4.0], [RIME_SPIRE_POS, 3.0],
			[SNOW_LODGE_POS, 4.0], [WEST_HALL_SPOT, 4.0], [SOUTH_HALL_SPOT, 4.0], [E2_NODES[&"e2m1_west"][0], 7.0],
			[E2_NODES[&"e2m1_south"][0], 7.0], [GLADE_CENTER, GLADE_RADIUS], [SHADOW_CORNER, 4.0], [ICE_CORNER, 4.0],
			[G1_POS, 5.0], [VEY_EXIT, 4.0]]
	for id: StringName in HIDEOUTS:
		var h: Array = HIDEOUTS[id]
		out.append([h[1], 5.0 if id == &"S1" else (6.0 if id == &"S2" else 12.0)])
	for p: Vector3 in E2_CACHE_SPOTS:
		out.append([p, CACHE_CLEARING])
	return out


## The campaign flags this run uses (flag_override first; no Episode 1 victory in the save = the fallback start).
func _read_flags() -> void:
	if _flags_read:
		return
	_flags_read = true
	if not flag_override.is_empty():
		return
	var cs := CampaignState.open(campaign_save_path)
	no_save_fallback = not cs.is_completed(&"m04")


func _add_burnt_tree(p: Vector3, s: float) -> void:
	if env_props == null:
		_add_tree(p, s)
		return
	var shape := CylinderShape3D.new()
	shape.radius = 0.45 * s
	shape.height = 2.0
	_static_obstacle(p, shape, 1.0)
	env_props.add_tree_kind("tree_broadleaf", p, s)


## The dead Oldroot: trunk collider r 3 (navigation geometry), a split black trunk (placeholder).
func _add_dead_oldroot() -> void:
	var shape := CylinderShape3D.new()
	shape.radius = OLDROOT_RADIUS
	shape.height = 6.0
	var body := _static_obstacle(OLDROOT_POS, shape, 3.0)
	body.name = "DeadOldroot"
	body.add_to_group(&"navigation_geometry")
	if _SIM.enabled:
		return
	var bark := Color(0.10, 0.09, 0.09)
	for side in [-1.0, 1.0]:
		var half := CylinderMesh.new()
		half.top_radius = 0.9
		half.bottom_radius = 1.5
		half.height = 8.0
		half.radial_segments = 9
		var mi := _mesh(body, half, bark, 4.0)
		mi.position.x = side * 0.9
		mi.rotation.z = -side * 0.12
	var rime := CylinderMesh.new()
	rime.top_radius = 0.95
	rime.bottom_radius = 1.0
	rime.height = 0.6
	_mesh(body, rime, Color(0.86, 0.89, 0.94), 8.2)


func _make_totem_type() -> BuildingType:
	var t := BuildingType.new()
	t.id = &"rime_totem"
	t.display_name = "Rime Totem"
	t.faction = &"ice"
	t.kind = &"totem"
	t.max_hp = TOTEM_HP
	t.footprint = Vector2i(1, 1)
	t.height = 2.6
	t.sight_radius = 6.0
	t.counts_for_defeat = false
	t.color = Color(0.55, 0.80, 1.00)
	t.body_color = Color(0.75, 0.88, 0.98)
	return t


## The mission 2 Ember Hall copy: Z X C V the tier-1 card, B N the Stronghold pair.
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


## A story unit type (D5): team PLAYER, not commandable, no attack, pop 0, from `base_id`'s look.
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


## Old Vey at 0:00 (D3): the story NPC (torren_vey, never selectable), before the helper call.
func _make_vey_type() -> UnitType:
	var base := UnitType.find("torren_vey")
	if base == null:
		return null
	var t := base.duplicate() as UnitType
	t.commandable = false
	t.aggro_range = 0.0
	return t


func _on_e2_node_added(node: Node) -> void:
	var b := node as TrainingBuilding
	if b != null and _hall_type != null and b.building_type != null and b.building_type != _hall_type \
			and b.building_type.id == &"fire_barracks":
		b.building_type = _hall_type


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	fog.reveal(Unit.Team.ENEMY, SHADOW_START, FogOfWar.START_REVEAL)
	fog.reveal(Unit.Team.ENEMY, ICE_RALLY, FogOfWar.START_REVEAL)
	var diff := clampi(mission_difficulty, 0, 2)
	_setup_champions()   # the companion's guild (apply_to_start adds it); no tavern on this map

	# --- Fire: Vessa, the save, the army, Wren, Old Vey (story).
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	_apply_campaign_start()
	for i in 6:
		var cinder := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER,
				PLAYER_START + Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2))
		cinder.call(&"command_gather", crystal_nodes[&"e2m1_fire_a" if i < 3 else &"e2m1_fire_b"])
	var rows := [["flame_guard", 6 + (2 if diff == 0 else 0)], ["ember_archer", 4], ["blaze_rider", 2],
			["pyre_adept", 0 if diff == 2 else 2]]
	var army: Array[String] = []
	for row in rows:
		for k in int(row[1]):
			army.append(String(row[0]))
	for i in army.size():
		_spawn(make_unit(army[i]), Unit.Team.PLAYER, ARMY_POS + Vector3(-4.5 + (i % 6) * 1.6, 0.0, -2.0 + (i / 6) * 1.7))
	if _wren_type:
		wren = _spawn(Worker.make_unit(_wren_type), Unit.Team.PLAYER, PLAYER_START + Vector3(-2.0, 0.0, 2.0))
		wren.death_guard = _wren_guard
	if _story_vey_type:
		vey_npc = _spawn(Worker.make_unit(_story_vey_type), Unit.Team.PLAYER, VEY_START)
		set_truce([vey_npc], true, Unit.TRUCE_ALL)
		_immortal(vey_npc)
	set_truce([heartwood], true, Unit.TRUCE_ALL)   # until the kindle nothing targets it (it is invulnerable too)

	# --- Shadow: Malrik's camp (the bot).
	shadow_hero = _make_wizard(Unit.Team.ENEMY)
	_spawn(shadow_hero, Unit.Team.ENEMY, SHADOW_RALLY)
	_claim_wizard(shadow_hero, Unit.Team.ENEMY)
	raise_wizard(shadow_hero, WIZARD_LEVEL[diff], MALRIK_SPELLS)
	ItemDrops.ensure_inventory(shadow_hero)
	shadow_hero.died.connect(_on_malrik_died)
	wizard_respawned.connect(_on_e2_wizard_respawned)
	for i in 5:
		var thrall := _spawn(make_unit("gloom_thrall"), Unit.Team.ENEMY,
				SHADOW_START + Vector3(4.0 - i * 1.2, 0.0, -4.0 + i * 1.2))
		thrall.call(&"command_gather", crystal_nodes[&"node_shadow_a" if i < 3 else &"node_shadow_b"])
	for i in 8:
		var a := float(i) * TAU / 8.0
		_spawn(make_unit("shade" if i < 6 else "nightbolt"), Unit.Team.ENEMY,
				SHADOW_RALLY + Vector3(cos(a) * 2.5, 0.0, sin(a) * 2.5))

	# --- Ice: Torvald, his camp guard, Aldra (story).
	torvald = IceWizard.new()
	_spawn(torvald, Unit.Team.ENEMY, ICE_RALLY + Vector3(-1.5, 0.0, 1.5))
	_claim_wizard(torvald, Unit.Team.ENEMY)
	mark_scripted(torvald)
	torvald.set_meta(META_HOME, ICE_RALLY)
	raise_wizard(torvald, WIZARD_LEVEL[diff], TORVALD_SPELLS)
	ItemDrops.ensure_inventory(torvald)
	torvald.died.connect(_on_torvald_died)
	_spawn_aldra()

	_spawn_guards()
	_spawn_caches()
	var roster := HelperRoster.for_team(Unit.Team.PLAYER)
	if roster:
		roster.helper_ready.connect(_on_vey_ready)
	_add_events()
	begin_mission([&"obj_heartwood", &"obj_vessa"])


## CampaignState.apply_to_start (items, carried essence, companion, flags meta); with no Episode 1 victory in the save
## (menu debug, tests): Crown + Signet equipped, the Orb owned, empty slots, essence 150 + 600, no companion.
func _apply_campaign_start() -> void:
	_read_flags()
	if no_save_fallback or not flag_override.is_empty():
		set_meta(&"campaign_flags", flag_override.duplicate())
		force_artifacts(hero, ["ember_crown", "masters_signet"])
		if no_save_fallback:
			var bank := EssenceBank.for_team(Unit.Team.PLAYER)
			if bank:
				bank.add(NO_SAVE_ESSENCE)
		return
	CampaignState.open(campaign_save_path).apply_to_start(self)


## A unit that never dies (story NPC): its death_guard keeps it at full HP.
static func _immortal(u: Unit) -> void:
	u.death_guard = func(_a: Variant) -> bool:
		u.hp = u.max_hp
		return true


func _spawn_aldra() -> void:
	var ht := HelperType.find(&"helper_aldra")
	if ht == null:
		return
	var a := Helper.new()
	a.apply_helper_type(ht, 5)
	a.name = "Aldra"
	_spawn(a, Unit.Team.ENEMY, ALDRA_SPOT)
	a.set_level(5)
	a.set_stance(&"home")
	mark_scripted(a)
	set_dormant(a, true)   # D7: a story unit, untargetable, channels the frost
	aldra = a


func _spawn_guards() -> void:
	guard_groups[&"G1"] = spawn_group([["shade", 3], ["nightbolt", 2]], G1_POS, 2.5, Unit.Team.ENEMY, true)
	var g2: Array = []
	var ring_rows := [["rimeshield", 3], ["shardcaster", 2], ["rime_seer", 1], ["shade", 3], ["nightbolt", 1]]
	g2.append_array(spawn_group(ring_rows, G2_CENTER, G2_RING, Unit.Team.ENEMY, true, true))
	guard_groups[&"G2"] = g2
	for id: StringName in HIDEOUTS:
		var h: Array = HIDEOUTS[id]
		guard_groups[StringName("G%d" % (3 + [&"S1", &"S2", &"S3"].find(id)))] = spawn_group(h[2], h[1], float(h[3]),
				Unit.Team.ENEMY, true, true)
	guard_groups[&"G6"] = spawn_group([["rimeshield", 4]], ICE_RALLY, 2.5, Unit.Team.ENEMY, true)


func _spawn_caches() -> void:
	for i in E2_CACHE_SPOTS.size():
		var cache := LostCache.new()
		cache.name = "LostCache%d" % i
		cache.rng.seed = MAP_SEED + 11 + i
		cache.match_time_source = match_time
		add_child(cache)
		cache.global_position = E2_CACHE_SPOTS[i]
		cache.opened.connect(_on_cache_opened)
		caches.append(cache)


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_heartwood", false), objective_text(&"obj_hold", false), BRIEFING_FROST_LINE],
		"rule": objective_text(&"obj_vessa"),
	}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_heartwood":
			if with_counter and not kindled:
				return "Reach the Heartwood before the frost takes it (%d %%)" % int(frost)
			return "Reach the Heartwood before the frost takes it"
		&"obj_hold":
			if with_counter and hold_left >= 0.0:
				var s := int(ceil(hold_left))
				return "Hold the Heartwood (%d:%02d)" % [s / 60, s % 60]
			return "Hold the Heartwood"
		&"obj_vessa":
			return "Vessa must survive"
		&"sec_folk":
			return "Bring Ysolde's people to the Emberwatch (%d / 12)" % folk_home if with_counter \
					else "Bring Ysolde's people to the Emberwatch"
		&"sec_frosthall":
			return "Shatter Torvald's Frost Hall"
		&"sec_storm":
			return "Raise a Citadel and call Old Vey"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_heartwood":
			return {"progress": int(frost), "goal": 100, "counter": "%d %%" % int(frost), "position": HEARTWOOD_POS}
		&"obj_hold":
			return {"countdown": hold_left, "time_left": hold_left, "position": HEARTWOOD_POS}
		&"sec_folk":
			var spots: Array = []
			for hid: StringName in HIDEOUTS:
				if not hideout_freed.has(hid):
					spots.append((HIDEOUTS[hid] as Array)[1])
			return {"progress": folk_home, "goal": 12, "counter": "%d / 12" % folk_home, "positions": spots}
		&"sec_frosthall":
			return {"position": FROST_HALL_POS}
	return {}


## Says line `n` (L<n>) once per run.
func say_l(n: int) -> void:
	if _said.has(n):
		return
	_said[n] = true
	said.append(n)
	say_line(n)


# ---------------------------------------------------------------- events

## E1: the arrival (e2m1_arrival, HOLD 0:20; fallback = the camera on Vessa + L1), L2-L3, the frost starts.
func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e2m1_arrival", func() -> void:
		camera_rig.focus_on(hero.global_position)
		say_l(1)
		say_l(2)
		say_l(3)
		hud.show_message(HINT_START, 10.0))


func _add_events() -> void:
	after(INTRO_LINES_END, _e2_vey_rides)
	after(P1_TIME, _e4_probe)
	add_event(&"E3", _g1_seen, func() -> void: say_l(6))
	add_event(&"E5", func() -> bool: return hero_alive() and _flat(hero.global_position, HEARTWOOD_POS) <= E5_RADIUS,
			_e5_frostwarden)
	add_event(&"citadel_hint", func() -> bool:
		var st := TierSystem.instance()
		return st != null and keep != null and is_instance_valid(keep) and keep.is_alive() and keep.can_upgrade() == "" \
				and int(keep.tier) == 2, func() -> void: hud.show_message(HINT_CITADEL, 12.0))
	add_event(&"E10", func() -> bool: return keep != null and is_instance_valid(keep) and int(keep.tier) >= 3,
			_e10_citadel)
	add_event(&"E19", func() -> bool: return kindled and heartwood.is_alive() and heartwood.hp < heartwood.max_hp * 0.5,
			func() -> void: say_l(25))


## E2 (0:25): L4-L5, Old Vey rides north and leaves, sec_storm and sec_folk appear, the survivors hint.
func _e2_vey_rides() -> void:
	if is_ending():
		return
	fire_once(&"E2")
	say_l(4)
	say_l(5)
	if vey_npc and is_instance_valid(vey_npc):
		vey_npc.command_move(VEY_EXIT)
		var v := vey_npc
		after(40.0, func() -> void:
			if is_instance_valid(v) and v.is_alive():
				v.leave_map())
	set_objective(&"sec_storm", "active")
	set_objective(&"sec_folk", "active")
	set_objective(&"sec_frosthall", "active")
	hud.show_message(HINT_FOLK, 10.0)


func _g1_seen() -> bool:
	for u in guard_groups.get(&"G1", []):
		if is_instance_valid(u) and (u as Unit).is_alive() and fog.is_visible(Unit.Team.PLAYER, (u as Unit).global_position):
			return true
	return false


## E4 (3:00): P1, the Shadow probe on the Ember Hall; Ashby (L7).
func _e4_probe() -> void:
	if is_ending():
		return
	fire_once(&"E4")
	var target := _alive_pos(ember_hall, _alive_pos(keep, PLAYER_START))
	var units := spawn_wave_at([["shade", 3], ["grave_hound", 2]], _side_spawn(&"shadow"))
	wave_units[&"P1"] = units
	for u in units:
		order_wave(u, &"point", target)
	waves_fired.append(&"P1")
	say_l(7)


## E5: Vessa nears the glade: e2m1_frostwarden (PAUSE 0:12; fallback = L8-L9 and a 2 s look at the Heartwood).
func _e5_frostwarden() -> void:
	play_cutscene(&"e2m1_frostwarden", func() -> void:
		say_l(8)
		say_l(9)
		if camera_rig:
			camera_rig.focus_on(HEARTWOOD_POS)
			after(2.0, func() -> void:
				if hero_alive():
					camera_rig.focus_on(hero.global_position)))


## A Rime Totem fell: one third of the frost rate gone; the third one: L10, Aldra walks home (E6).
func _on_totem_destroyed(_b: Building) -> void:
	if is_ending():
		return
	flash_ring(_b.global_position, 3.0)
	if totems_alive() == 0 and fire_once(&"E6"):
		say_l(10)
		if aldra and is_instance_valid(aldra):
			aldra.command_move(RIME_KEEP_POS + Vector3(6.0, 0.0, 6.0))
			var a := aldra
			after(30.0, func() -> void:
				if is_instance_valid(a):
					a.leave_map())


func totems_alive() -> int:
	var n := 0
	for t in totems:
		if is_instance_valid(t) and t.is_alive():
			n += 1
	return n


## True while the kindle is refused: an enemy unit (not a wizard, not Aldra) or a Rime Totem within 10 m.
func kindle_is_blocked() -> bool:
	if totems_alive() > 0:
		for t in totems:
			if is_instance_valid(t) and t.is_alive() and _flat(t.global_position, HEARTWOOD_POS) <= KINDLE_CLEAR:
				return true
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not u is Wizard and u != aldra \
				and not is_dormant(u) and _flat(u.global_position, HEARTWOOD_POS) <= KINDLE_CLEAR:
			return true
	return false


func _tick_kindle(delta: float) -> void:
	if kindled or not hero_alive() or heartwood == null:
		return
	if _flat(hero.global_position, HEARTWOOD_POS) > KINDLE_RANGE:
		kindle_progress = 0.0
		kindle_blocked = false
		return
	kindle_blocked = kindle_is_blocked()
	if kindle_blocked:
		kindle_progress = 0.0
		if fire_once(&"kindle_blocked_msg"):
			hud.show_message(MSG_KINDLE_BLOCKED, 4.0)
		return
	kindle_progress = minf(1.0, kindle_progress + delta / KINDLE_TIME)
	if kindle_progress >= 1.0:
		kindle()


## E7: the kindle. The Heartwood turns, its wardens climb out, the hold starts, the waves are armed.
func kindle() -> void:
	if kindled or is_ending():
		return
	kindled = true
	kindle_time = mission_time()
	fire_once(&"E7")
	set_truce([heartwood], false, Unit.TRUCE_ALL)
	heartwood.kindle(SAP_RADIUS)
	flash_ring(HEARTWOOD_POS, 6.0)
	say_l(11)
	say_l(12)
	set_objective(&"obj_heartwood", "done")
	hold_left = float(by_difficulty(HOLD_SECONDS))
	set_objective(&"obj_hold", "active")
	hud.show_message(HINT_HOLD, 8.0)
	_spawn_heart_wardens()
	_arm_waves()


func _spawn_heart_wardens() -> void:
	var rows := [["thornling", 3], ["bloomtender", 2]]
	var i := 0
	for row in rows:
		for k in int(row[1]):
			var t: UnitType = _warden_types.get(String(row[0]))
			if t == null:
				continue
			var a := float(i) * TAU / 5.0
			var u := _spawn(Worker.make_unit(t), Unit.Team.PLAYER, HEARTWOOD_POS + Vector3(cos(a) * 3.0, 0.0, sin(a) * 3.0))
			var guard := 0
			while u.level < 2 and guard < 10:
				guard += 1
				u.add_xp(50)
			heart_wardens.append(u)
			i += 1


func _arm_waves() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	var plan: Array = [[&"H1", H_OFFSETS[&"H1"]], [&"H2", H_OFFSETS[&"H2"]], [&"H3", H_OFFSETS[&"H3"]],
			[&"H4", H_OFFSETS[&"H4"]]]
	if diff == 0:
		plan.append([&"H6", H_OFFSETS[&"H5"]])   # easy: no H5, H6 at T + 8:30
	else:
		plan.append([&"H5", H_OFFSETS[&"H5"]])
		plan.append([&"H6", H_OFFSETS[&"H6"]])
	if diff == 2:
		plan.append([&"H7", H_OFFSETS[&"H7"]])
	for p: Array in plan:
		after(float(p[1]), _fire_wave.bind(StringName(p[0])))
	after(RAID_FIRST, _raid)


## Seconds until the next wave of `side` leaves (INF = none planned): the Eavesdrop bonus reads it.
func next_wave_in(side: StringName) -> Dictionary:
	if not kindled:
		return {}
	var diff := clampi(mission_difficulty, 0, 2)
	var t := mission_time() - kindle_time
	var best := {}
	for id: StringName in [&"H1", &"H2", &"H3", &"H4", &"H5", &"H6", &"H7"]:
		if waves_fired.has(id) or (id == &"H5" and diff == 0) or (id == &"H7" and diff != 2):
			continue
		var at: float = H_OFFSETS[&"H5"] if (id == &"H6" and diff == 0) else float(H_OFFSETS[id])
		var w: Dictionary = WAVES[id]
		var wside: StringName = w["side"]
		if wside != side and wside != &"both":
			continue
		if best.is_empty() or at < float(best["at"]):
			best = {"id": id, "at": at, "in": at - t}
	return best


func _side_spawn(side: StringName) -> Vector3:
	if side == &"ice":
		if frost_hall and is_instance_valid(frost_hall) and frost_hall.is_alive():
			return frost_hall.spawn_point()
		if rime_keep and is_instance_valid(rime_keep) and rime_keep.is_alive():
			return rime_keep.global_position + Vector3(7.0, 0.0, 7.0)
		return ICE_CORNER
	if gloom_hall and is_instance_valid(gloom_hall) and gloom_hall.is_alive() and gloom_hall is TrainingBuilding:
		return (gloom_hall as TrainingBuilding).spawn_point()
	var k := keep_of(Unit.Team.ENEMY)
	return k.spawn_point() if k else SHADOW_CORNER


## The Ice rule: 40 % fewer units (rounded down) once the Frost Hall burns.
func _ice_filter(n: int) -> int:
	return n - int(floor(float(n) * 0.4)) if objective_state("sec_frosthall") == "done" else n


func _wave_rows(rows: Array, ice: bool) -> Array:
	var out: Array = []
	var diff := clampi(mission_difficulty, 0, 2)
	for row: Array in rows:
		var id := StringName(row[0])
		if diff == 0 and (EASY_SKIP.has(id) or id == &"shadow_knight" and rows.size() == 4):
			continue
		if ice and id == &"rime_colossus" and objective_state("sec_frosthall") == "done":
			continue
		out.append(row)
	return out


func _fire_wave(id: StringName) -> void:
	if is_ending() or hold_done or waves_fired.has(id):
		return
	waves_fired.append(id)
	var w: Dictionary = WAVES[id]
	var side: StringName = w["side"]
	var units: Array = []
	if side == &"shadow" or side == &"both":
		units.append_array(spawn_wave_at(_wave_rows(w["rows"], false), _side_spawn(&"shadow")))
	if side == &"ice":
		units.append_array(spawn_wave_at(_wave_rows(w["rows"], true), _side_spawn(&"ice"), Unit.Team.ENEMY, _ice_filter))
	elif side == &"both":
		units.append_array(spawn_wave_at(_wave_rows(w["ice_rows"], true), _side_spawn(&"ice"), Unit.Team.ENEMY,
				_ice_filter))
	var diff := clampi(mission_difficulty, 0, 2)
	if bool(w.get("torvald", false)) and torvald and is_instance_valid(torvald):
		if id == &"H6" or id == &"H7":
			raise_wizard(torvald, WIZARD_LATE_LEVEL[diff], [&"rime_bolt"])
		_torvald_home = false
		if torvald.is_alive():
			units.append(torvald)
	if bool(w.get("malrik", false)) and shadow_hero and is_instance_valid(shadow_hero):
		raise_wizard(shadow_hero, WIZARD_LATE_LEVEL[diff], [&"shadow_lance"])
		mark_scripted(shadow_hero)   # the Commander lets go of him from H5 on
		if shadow_hero.is_alive():
			units.append(shadow_hero)
	wave_units[id] = units
	for u in units:
		order_wave(u as Unit, &"heartwood", HEARTWOOD_POS)
	match id:
		&"H1":
			say_l(13)
			say_l(14)
		&"H2":
			say_l(15)
			say_l(16)
		&"H5":
			say_l(23)
		&"H6":
			say_l(24)


## Raids: 2 Grave Hounds every 150 s for the nearest walking survivor, else the nearest Fire worker.
func _raid() -> void:
	if is_ending() or hold_done:
		return
	after(RAID_EVERY, _raid)
	var units := spawn_wave_at([["grave_hound", 2]], _side_spawn(&"shadow"))
	for u in units:
		var t := _raid_target((u as Unit).global_position)
		order_wave(u as Unit, &"raid", t)


func _raid_target(from: Vector3) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for f in folk:
		if is_instance_valid(f) and (f as Unit).is_alive():
			var d := _flat((f as Unit).global_position, from)
			if d < best_d:
				best_d = d
				best = (f as Unit).global_position
	if best != Vector3.INF:
		return best
	for w in workers_of(Unit.Team.PLAYER):
		var d := _flat(w.global_position, from)
		if d < best_d:
			best_d = d
			best = w.global_position
	return best if best != Vector3.INF else _alive_pos(keep, PLAYER_START)


func _refresh_wave_unit(u: Unit, mode: StringName, hero_at: Vector3) -> bool:
	match mode:
		&"heartwood":
			if heartwood == null or not is_instance_valid(heartwood) or not heartwood.is_alive():
				u.set_meta(META_MODE, &"hero")
				return false
			if u.attack_target == null and not u.is_attack_moving():
				if _flat(u.global_position, HEARTWOOD_POS) <= 8.0:
					u.command_attack(heartwood)
				else:
					u.command_attack_move(HEARTWOOD_POS)
			return true
		&"raid":
			if u.attack_target == null and not u.is_attack_moving():
				u.command_attack_move(_raid_target(u.global_position))
			return true
		&"withdraw":
			return true
	return false


# ---------------------------------------------------------------- the Citadel, Old Vey

## E10: the Citadel stands: L17, the call hint, the spotlight card (Old Vey).
func _e10_citadel() -> void:
	say_l(17)
	hud.show_message(HINT_CALL, 10.0)
	show_spotlight()


## E11: Old Vey arrives (the helper's arrival at the keep door): L18, sec_storm done; his first Stormcall = L19.
func _on_vey_ready(helper: Helper) -> void:
	if is_ending() or vey_arrived:
		return
	vey_arrived = true
	fire_once(&"E11")
	say_l(18)
	set_objective(&"sec_storm", "done")
	for c in helper.get_children():
		if c.has_signal(&"ability_cast"):
			c.connect(&"ability_cast", func(id: StringName) -> void:
				if id == &"vey_stormcall" and fire_once(&"E12"):
					say_l(19))


# ---------------------------------------------------------------- survivors, Wren

func _tick_hideouts() -> void:
	for id: StringName in HIDEOUTS:
		if hideout_freed.has(id):
			continue
		var h: Array = HIDEOUTS[id]
		var g: Array = guard_groups.get(StringName("G%d" % (3 + [&"S1", &"S2", &"S3"].find(id))), [])
		if not _all_dead(g):
			continue
		var at: Vector3 = h[1]
		var near := (hero_alive() and _flat(hero.global_position, at) <= FREE_RADIUS) \
				or (wren != null and is_instance_valid(wren) and wren.is_alive() and _flat(wren.global_position, at) <= FREE_RADIUS)
		if near:
			_free_hideout(id)


## E13: the 4 survivors of hideout `id` rise and walk to the Fire keep; the first time, L20.
func _free_hideout(id: StringName) -> void:
	hideout_freed[id] = true
	fire_once(&"E13")
	say_l(20)
	var at: Vector3 = (HIDEOUTS[id] as Array)[1]
	if _folk_type == null:
		return
	for i in FOLK_PER_HIDEOUT:
		var a := float(i) * TAU / FOLK_PER_HIDEOUT
		var f := _spawn(Worker.make_unit(_folk_type), Unit.Team.PLAYER, at + Vector3(cos(a) * 1.5, 0.0, sin(a) * 1.5))
		f.add_to_group(&"wood_folk")
		f.died.connect(_on_folk_died)
		f.command_move(_alive_pos(keep, PLAYER_START))
		folk.append(f)
	set_objective(&"sec_folk", "active")


func _tick_folk() -> void:
	var home := _alive_pos(keep, PLAYER_START)
	var walking: Array = []
	for f in folk:
		if not is_instance_valid(f) or not (f as Unit).is_alive():
			continue
		var u := f as Unit
		if _flat(u.global_position, home) <= FOLK_HOME_RADIUS:
			folk_home += 1
			u.set_meta(&"e2m1_home", true)
			u.leave_map()
			set_objective(&"sec_folk", "active")
			if folk_home >= FOLK_GOAL and objective_state("sec_folk") == "active":
				set_objective(&"sec_folk", "done")
			if folk_home >= 12 and fire_once(&"E14"):
				say_l(21)
			continue
		if not u.has_move_order():
			u.command_move(home)
		walking.append(u)
	folk = walking


func _on_folk_died(u: Unit) -> void:
	if u.has_meta(&"e2m1_home") or is_ending():
		return
	folk_dead += 1
	if folk_dead >= FOLK_FAIL and objective_state("sec_folk") == "active":
		set_objective(&"sec_folk", "failed")


## D6: Wren never dies: at 1 HP she kneels 8 s (untargetable), then stands at 50 %.
func _wren_guard(_attacker: Variant) -> bool:
	if wren == null or not is_instance_valid(wren):
		return false
	wren.hp = 1.0
	if _wren_kneel_left <= 0.0:
		_wren_kneel_left = WREN_KNEEL
		set_dormant(wren, true)
	return true


func _tick_wren(delta: float) -> void:
	if wren == null or not is_instance_valid(wren):
		return
	if _wren_kneel_left > 0.0:
		_wren_kneel_left -= delta
		if _wren_kneel_left <= 0.0:
			set_dormant(wren, false)
			wren.death_guard = _wren_guard
			wren.hp = wren.max_hp * 0.5
		return
	if not hero_alive():
		return
	var d := _flat(wren.global_position, hero.global_position)
	if d > WREN_FAR:
		var dir := wren.global_position - hero.global_position
		dir.y = 0.0
		dir = dir.normalized() if dir.length() > 0.1 else Vector3(-1.0, 0.0, 1.0).normalized()
		wren.command_move(hero.global_position + dir * ((WREN_NEAR + WREN_FAR) * 0.5))
	_ping_left -= delta
	if _ping_left <= 0.0:
		_ping_left = PING_EVERY
		for id: StringName in HIDEOUTS:
			if not hideout_freed.has(id) and hud and hud.minimap:
				hud.minimap.ping((HIDEOUTS[id] as Array)[1])


# ---------------------------------------------------------------- wizards, the Frost Hall

func _on_malrik_died(_u: Unit) -> void:
	if is_ending():
		return
	hud.show_message(MSG_MALRIK_FELL, 4.0)
	_respawn_left[Unit.Team.ENEMY] = WIZARD_RESPAWN


func _on_e2_wizard_respawned(wiz: Wizard) -> void:
	if wiz != shadow_hero or is_ending():
		return
	if is_scripted_wizard(wiz) and not hold_done:
		order_wave(wiz, &"heartwood", HEARTWOOD_POS)


static func is_scripted_wizard(w: Node) -> bool:
	return w != null and w.has_meta(SCRIPTED_GROUP)


func _on_torvald_died(_u: Unit) -> void:
	if is_ending():
		return
	hud.show_message(MSG_TORVALD_FELL, 4.0)
	after(WIZARD_RESPAWN, func() -> void:
		if is_ending() or torvald == null or not is_instance_valid(torvald) or torvald.is_alive():
			return
		var at := ICE_RALLY
		if rime_keep and is_instance_valid(rime_keep) and rime_keep.is_alive():
			at = rime_keep.global_position + Vector3(7.0, 0.0, 7.0)
		torvald.respawn(at)
		if not _torvald_home and not hold_done:
			order_wave(torvald, &"heartwood", HEARTWOOD_POS)
		else:
			torvald.command_move(ICE_RALLY))


## Torvald holds his rally until H2 (and between his waves once his wave is gone).
func _tick_torvald() -> void:
	if torvald == null or not is_instance_valid(torvald) or not torvald.is_alive():
		return
	if _torvald_home:
		if torvald.attack_target == null and _flat(torvald.global_position, ICE_RALLY) > 4.0 and not torvald.is_attack_moving():
			torvald.command_attack_move(ICE_RALLY)


func _on_frost_hall_destroyed(_b: Building) -> void:
	if is_ending():
		return
	fire_once(&"E16")
	say_l(22)
	set_objective(&"sec_frosthall", "done")


## Eavesdrop (mission bonus): a disguised Saboteur within 12 m of a camp's hall hears that camp's next wave 30 s early.
func _tick_eavesdrop() -> void:
	for side: StringName in [&"ice", &"shadow"]:
		var hall: Node3D = frost_hall if side == &"ice" else gloom_hall
		if hall == null or not is_instance_valid(hall):
			continue
		var next := next_wave_in(side)
		if next.is_empty() or float(next["in"]) > EAVESDROP_LEAD or float(next["in"]) < 0.0 \
				or _eaves_said.has(next["id"]):
			continue
		var heard := false
		for n in get_tree().get_nodes_in_group("units"):
			var u := n as Unit
			if u and u.is_alive() and int(u.team) == Unit.Team.PLAYER and u.unit_type \
					and u.unit_type.id == &"ashveil_saboteur" and _flat(u.global_position, hall.global_position) <= EAVESDROP_RADIUS:
				heard = true
				break
		if heard:
			_eaves_said[next["id"]] = true
			var w: Dictionary = WAVES[next["id"]]
			var rows: Array = w["ice_rows"] if side == &"ice" and w["side"] == &"both" else w["rows"]
			var parts: Array[String] = []
			for row: Array in rows:
				var t := UnitType.find(String(row[0]))
				parts.append("%d %s" % [scaled(int(row[1]), String(row[0])), t.display_name if t else String(row[0])])
			var text := ", ".join(parts)
			hud.show_message(Loc.t(MSG_EAVESDROP_ICE if side == &"ice" else MSG_EAVESDROP_SHADOW, {"units": text}), 6.0)


# ---------------------------------------------------------------- the frost, the hold, the end

func _tick_frost(delta: float) -> void:
	if kindled:
		return
	var rate := float(by_difficulty(FROST_RATE)) * float(totems_alive()) / 3.0
	if rate <= 0.0:
		return
	var before := int(frost)
	frost = minf(100.0, frost + rate * delta)
	heartwood.set_frost(frost / 100.0)
	if int(frost) != before:
		set_objective(&"obj_heartwood", "active")
		if frost >= 50.0 and not _frost_msgs.has(50):
			_frost_msgs[50] = true
			hud.show_message(MSG_FROST_HALF, 4.0)
		if frost >= 80.0 and not _frost_msgs.has(80):
			_frost_msgs[80] = true
			hud.show_message(MSG_FROST_80, 4.0)
	if frost >= 100.0 and fire_once(&"E15"):
		say_l(29)
		set_objective(&"obj_heartwood", "failed")
		lose(DEFEAT_DELAY)


func _tick_hold(delta: float) -> void:
	if not kindled or hold_done:
		return
	hold_left = maxf(0.0, hold_left - delta)
	if heartwood and heartwood.is_alive() and heartwood.hp < heartwood.max_hp and not _enemy_near(HEARTWOOD_POS, REGROW_CLEAR):
		heartwood.heal(heartwood.max_hp * REGROW_PCT * delta)
	if hold_left <= 0.0:
		_e20_hold_done()


func _enemy_near(at: Vector3, r: float) -> bool:
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not is_dormant(u) and _flat(u.global_position, at) <= r:
			return true
	return false


## E20: the hold is over. Everyone of Shadow and Ice walks home, L26, then e2m1_ysolde (fallback: Ysolde beside the
## Heartwood + L27-L28), victory 2 s after it.
func _e20_hold_done() -> void:
	if hold_done or is_ending():
		return
	hold_done = true
	hold_left = 0.0
	fire_once(&"E20")
	set_objective(&"obj_hold", "done")
	if objective_state("sec_folk") == "active":
		set_objective(&"sec_folk", "done" if folk_home >= FOLK_GOAL else "failed")
	_withdraw()
	say_l(26)
	after(4.0, func() -> void:
		if game_over:
			return
		play_cutscene(&"e2m1_ysolde", func() -> void:
			_show_ysolde()
			say_l(27)
			say_l(28)
			set_objective(&"obj_vessa", "done")
			win(VICTORY_DELAY)))


## Every scripted Shadow / Ice unit and both wizards walk to their own camp and leave there; the bot stops.
func _withdraw() -> void:
	clear_waves()
	for bot in _all_commanders():
		bot.set(&"enabled", false)
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Unit.Team.ENEMY or u == aldra or u.is_worker():
			continue
		var ice := u == torvald or (u.unit_type != null and u.unit_type.faction == &"ice")
		var home := ICE_RALLY if ice else SHADOW_RALLY
		set_truce([u], true, Unit.TRUCE_ALL)
		u.set_meta(META_MODE, &"withdraw")
		u.command_move(home)
		var unit := u
		after(25.0, func() -> void:
			if is_instance_valid(unit) and unit.is_alive() and unit != shadow_hero and unit != torvald:
				unit.leave_map())


func _show_ysolde() -> void:
	if _SIM.enabled:
		return
	var y := Node3D.new()
	y.name = "Ysolde"
	add_child(y)
	var body := CapsuleMesh.new()
	body.radius = 0.35
	body.height = 1.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.40, 0.62, 0.30)
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.90, 0.35)
	mat.emission_energy_multiplier = 0.4
	var mi := MeshInstance3D.new()
	mi.mesh = body
	mi.material_override = mat
	mi.position.y = 0.95
	y.add_child(mi)
	y.global_position = HEARTWOOD_POS + Vector3(0.0, 0.0, 3.0)


func _on_heartwood_destroyed(_b: Building) -> void:
	if is_ending() or hold_done:
		return
	fire_once(&"E22")
	say_l(31)
	lose(DEFEAT_DELAY)


## E21: Vessa falls: L30, then the instant-loss defeat.
func _on_player_hero_fell() -> void:
	fire_once(&"E21")
	say_l(30)
	set_objective(&"obj_vessa", "failed")
	super()


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)   # MissionBase: the Skirmish tick, the timers, the E-list
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_frost(delta)
	_tick_kindle(delta)
	_tick_hold(delta)
	_tick_wren(delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_hideouts()
		_tick_folk()
		_tick_torvald()
		_tick_eavesdrop()
		var t := objective_text(&"obj_hold") if kindled else objective_text(&"obj_heartwood")
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
