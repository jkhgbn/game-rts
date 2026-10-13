class_name MissionE4_01
extends MissionBase
## Episode 4, mission 1 "Hold Lark Hill" (docs/design/mission-e4-01.md): the other side of e3m1. A 2v2 on Evenmead:
## PLAYER Ysolde (Nature, Lark Hill west) + ALLY Vessa (Fire bot, Lark Hill east) vs ENEMY Malrik (Shadow bot, north
## ridge) + ENEMY_2 Torvald (Ice bot). Ring the five bells (3 hamlets, 2 farms over the river) so the 30 villagers walk
## to the golden tree, keep the tree standing and hold Lark Hill until nightfall (22:00). Maelis walks with Ysolde (story
## unit), Wren rings bells too, Mother Hush raids the refuge, Old Vey flashes onto the crest in the Final. Spotlight:
## the Bramblesage (the W3 ford fight).
##
## Built deviations (2026-10-08, from the spec):
## - The map is e3m1's Evenmead built in code (MissionE3_01's nodes, river, bases, standards, spires); the hamlets,
##   farms, bells and refuge are mission props at the spec positions (flat ground, no hills).
## - The ford zone and the standards are MissionZones (side 1 captures the ford in 60 s; side 0 owns the standards at
##   0:00, side 1 takes them in 12 s x 1.25 on its far bank).
## - Villagers are spawned when their bell rings (before that they do not exist: the "hidden, untargetable" rule);
##   inside the refuge (r 8) they get +100 % max HP instead of -50 % damage.
## - Maelis is a bonded story Helper (helper_maelis at Ysolde's level, Escort, back at the Heartwood 45 s after a fall);
##   Hush is the mother_hush unit on Malrik's seat (flees at 25 % HP, back 90 s later); Old Vey the torren_vey story
##   unit (not commandable, kneels 8 s at 1 HP).
## - Vessa's start army are scripted guards of her seat (ford pickets, Lark Well); her Commander trains a small army at
##   her rally; at the Final her guards and she move to the crest (6, 31). No ally pings.
## - Hard / easy shift every wave after W3 by +-1:30 and the Final by +-3:00 (nightfall 25:00 / 19:00).
## - No Stronghold delay to 3:30 (the hint comes at 3:30); Seed Hollows keep the kingdom cap.

const MISSION_ID := &"e4m1"
const MISSION_TITLE := "Hold Lark Hill"
const MAP_W := 150.0
const MAP_D := 120.0
const PLAYER_SEAT := Unit.Team.PLAYER
const ALLY_SEAT := Unit.Team.ALLY        ## Vessa (Fire bot)
const SHADOW_SEAT := Unit.Team.ENEMY     ## Malrik (Shadow bot)
const ICE_SEAT := Unit.Team.ENEMY_2      ## Torvald (Ice bot)

const YSOLDE_START := Vector3(-5.0, 0.0, 34.0)
const HEARTWOOD := Vector3(-32.0, 0.0, 48.0)
const GROVE_HALL := Vector3(-44.0, 0.0, 40.0)
const SEED_HOLLOWS: Array[Vector3] = [Vector3(-22.0, 0.0, 56.0), Vector3(-48.0, 0.0, 53.0)]
const NATURE_RALLY := Vector3(-18.0, 0.0, 26.0)
const FIRE_KEEP := Vector3(20.0, 0.0, 50.0)
const EMBER_HALL := Vector3(34.0, 0.0, 40.0)
const HEARTHS: Array[Vector3] = [Vector3(8.0, 0.0, 53.0), Vector3(31.0, 0.0, 55.0)]
const FIRE_RALLY := Vector3(12.0, 0.0, 26.0)
const VESSA_ANCHOR := Vector3(-1.6, 0.0, 35.0)
const VESSA_CREST := Vector3(6.0, 0.0, 31.0)
const DUSK_KEEP := Vector3(-12.0, 0.0, -48.0)
const GLOOM_HALL := Vector3(1.0, 0.0, -48.0)
const HOVEL := Vector3(-14.0, 0.0, -38.0)
const SHADOW_RALLY := Vector3(-4.0, 0.0, -28.0)
const MALRIK_ANCHOR := Vector3(0.0, 0.0, -36.0)
const HUSH_ANCHOR := Vector3(2.8, 0.0, -37.5)
const RIME_KEEP := Vector3(28.0, 0.0, -48.0)
const RIME_HALL := Vector3(16.0, 0.0, -45.0)
const ICE_RALLY := Vector3(35.0, 0.0, -28.0)
const TORVALD_ANCHOR := Vector3(30.0, 0.0, -36.0)
const CREST_SPIRES := {PLAYER_SEAT: [Vector3(-24.0, 0.0, 32.0), Vector3(-10.0, 0.0, 30.0)],
		ALLY_SEAT: [Vector3(6.0, 0.0, 31.0), Vector3(20.0, 0.0, 34.0)]}
const GOLDEN_TREE := Vector3(-16.0, 0.0, 48.5)
const REFUGE_R := 8.0
const FORD_ZONE := MissionE3_01.FORD_ZONE
const FORD_ZONE_R := 7.0
const FORD_STONES := MissionE3_01.FORD_STONES
const FORD_NORTH := Vector3(4.0, 0.0, -14.0)      ## W4 / Final Shadow spawn (the Stone Ford's north side)
const BIRCH_NORTH := Vector3(50.0, 0.0, -12.0)    ## W4 / Final Ice spawn (Birch Ford's north side)
const STANDARDS := MissionE3_01.STANDARDS
const STANDARD_R := 6.0
const STANDARD_TIME := 12.0
const FAR_BANK := 1.25
const STANDARD_SIGHT := 14.0
const HORNS := MissionE3_01.HORNS
const HORN_HP := 540.0
const HUSH_ENTRY := Vector3(-56.0, 0.0, 38.0)
## Bells: id -> [name, position, kind, picket group, burn time per difficulty (-1 = the evening horn)].
const BELLS := {
	&"millbrook": ["Millbrook", Vector3(-50.0, 0.0, 16.0), &"hamlet", &"", [-1.0, -1.0, -1.0]],
	&"larkford": ["Larkford", Vector3(-12.0, 0.0, 12.0), &"hamlet", &"", [-1.0, -1.0, -1.0]],
	&"birchend": ["Birchend", Vector3(38.0, 0.0, 24.0), &"hamlet", &"", [-1.0, -1.0, -1.0]],
	&"reedfield": ["Reedfield", Vector3(-34.0, 0.0, -18.0), &"farm", &"F1", [600.0, 480.0, 420.0]],
	&"birchwater": ["Birchwater", Vector3(52.0, 0.0, -16.0), &"farm", &"F2", [780.0, 660.0, 570.0]],
}
const BELL_R := 6.0
const FOLK_PER_BELL := 6
const FOLK_TOTAL := 30
const GUARD_LEASH := 10.0

const W1_AT := 270.0
const W2_AT := 420.0
const W3_AT := 570.0
const W4_AT := 720.0
const W5_AT := 930.0
const RAID_AT := 1020.0
const FINAL_AT := 1140.0
const NIGHTFALL_AT := 1320.0
const LATE_SHIFT: Array[float] = [-90.0, 0.0, 90.0]     ## W4, W5, Hush's raid by difficulty
const FINAL_SHIFT: Array[float] = [-180.0, 0.0, 180.0]  ## the Final and nightfall
const ICE_FINAL_DELAY := 20.0
const VEY_DELAY := 45.0
const HORN_CALL_AT := 360.0
const HORN_CALL_EVERY := 150.0
const GUESTS_MAX := 12
const HUSH_FLEE := 0.25
const HUSH_BACK := 90.0
const MAELIS_BACK := 45.0
const WIZARD_RETREAT := 0.35
const WREN_NEAR := 3.0
const WREN_FAR := 6.0
const WREN_KNEEL := 8.0
const VEY_KNEEL := 8.0
const DEFEAT_DELAY := 3.0
const LEVEL_CAP := 6
const START_ESSENCE := 400
const ESSENCE_CAP := 1500
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [450, 300, 250]
const FOLK_NEEDED: Array[int] = [15, 20, 24]
const FOLK_LOST_MAX: Array[int] = [15, 10, 6]
const TREE_HP: Array[float] = [4000.0, 3000.0, 2400.0]
const ALLY_SOLDIERS: Array[int] = [9, 7, 5]
const YSOLDE_SPELLS := [&"thornburst", &"thornburst", &"wild_bloom"]
const VESSA_SPELLS := [&"fireball", &"fireball", &"ember_step", &"kindle"]
const MALRIK_SPELLS := [&"shadow_lance", &"shadow_lance", &"soul_siphon", &"umbral_shroud"]
const TORVALD_SPELLS := [&"rime_bolt", &"rime_bolt", &"flash_freeze", &"rime_aegis"]

const PICKETS := {
	&"F1": [SHADOW_SEAT, Vector3(-34.0, 0.0, -18.0), [["shade", 3], ["nightbolt", 2]]],
	&"F2": [ICE_SEAT, Vector3(52.0, 0.0, -16.0), [["rimeshield", 3], ["shardcaster", 2]]],
}
const WAVES := {
	&"W1": [["shade", 4], ["grave_hound", 2]],
	&"W2": [["rimeshield", 4], ["shardcaster", 2], ["rime_seer", 1]],
	&"W3": [["shade", 6], ["nightbolt", 3], ["shadow_knight", 1], ["gloom_deacon", 1]],
	&"W4_S": [["shade", 6], ["nightbolt", 4], ["hexweaver", 2], ["hollow_oathsworn", 1]],
	&"W4_I": [["rimeshield", 4], ["shardcaster", 3], ["frost_mortar", 1]],
	&"W5": [["frost_mortar", 2], ["rime_colossus", 1], ["rimeshield", 4], ["rimecarver", 1]],
	&"RAID": [["shade", 4]],
	&"FINAL_S": [["shade", 6], ["nightbolt", 4], ["shadow_knight", 2], ["gloom_deacon", 1]],
	&"FINAL_I": [["rimeshield", 3], ["shardcaster", 2], ["rime_colossus", 1]],
	&"GUESTS": [["thornling", 2], ["burr_slinger", 1]],
}

const SPEAKER_COLORS := {&"ysolde": Color(0.55, 0.90, 0.35), &"maelis": Color(0.60, 0.85, 0.50),
		&"messenger": Color(0.80, 0.92, 0.60), &"vessa": Color(1.0, 0.45, 0.1), &"vey": Color(0.95, 0.95, 0.55),
		&"malrik": Color(0.7, 0.3, 1.0), &"hush": Color(0.60, 0.50, 0.75), &"torvald": Color(0.55, 0.80, 1.00),
		&"obren": Color(1.0, 0.80, 0.25), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"ysolde": "Ysolde", &"maelis": "Maelis", &"messenger": "Wren", &"vessa": "Vessa",
		&"vey": "Old Vey", &"malrik": "Malrik", &"hush": "Mother Hush", &"torvald": "Torvald", &"obren": "Obren",
		&"narrator": "Narrator"}
## The spec's lines in order (data/voice/lines/e4m1.json, French in data/i18n/fr/dialogue.po); LINE_IDS[n - 1] = id.
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13", "L14",
		"L15", "L15b", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25", "L26", "L27", "L28", "L29",
		"L30", "L31", "L32", "L33", "L34", "L35", "L36", "L37", "L38"]
const DIALOGUE := [
	[&"narrator", "The same afternoon, from the other hill. Here nobody counts fords. They count people."],
	[&"ysolde", "Maelis, the horns. Every farm in the valley comes up this hill before dark."],
	[&"maelis", "And the ford? Malrik will want his ford."],
	[&"ysolde", "Let him want it. A ford is water and stones. Those farms are families."],
	[&"vessa", "I'll take the east slope. If Torvald crosses, he can explain himself to a fire."],
	[&"messenger", "Up the hill! Leave the... leave the goats! Up to the golden tree!"],
	[&"malrik", "Ysolde. You are herding sheep while I take your river. That is very you."],
	[&"ysolde", "Sheep come back in spring, Malrik. So do I."],
	[&"maelis", "Through the ford, little ones. Slow is fine. Slow is alive."],
	[&"torvald", "Ysolde. Go home. I have no quarrel with your farms."],
	[&"ysolde", "Then why is your winter standing in them, Torvald?"],
	[&"obren", "The green one keeps a tree, Bishop. A golden tree. HIS tree. Take it."],
	[&"malrik", "One thing at a time. The ford first. Then we will talk about trees."],
	[&"narrator", "Smoke over the farms. Whoever was still there is not coming up the hill."],
	[&"narrator", "The evening horn. Malrik's whole host comes down to the water."],
	[&"ysolde", "The ford's gone. Fall back to the stones and the standards. Nobody runs."],
	[&"ysolde", "Let them have the water. Everyone to the foot of the hill. Nobody passes the tree."],
	[&"vessa", "The ford held till the horn! Ysolde, that was almost reckless. I'm proud of you."],
	[&"ysolde", "They have a standard. Let them carry it. Banners are light. Hills are not."],
	[&"vessa", "Ysolde! Torvald brought mortars to my well. I could use some thorns over here!"],
	[&"hush", "The Bishop wanted a look at the tree. I came to look first."],
	[&"maelis", "Behind us! The wood has a knife in it!"],
	[&"obren", "There it is. His tree. Burn it, and he feels it in the deep."],
	[&"malrik", "Ysolde! Step aside. I only want the tree."],
	[&"ysolde", "Everyone who ever wanted this tree said \"only\"."],
	[&"torvald", "I came for a ford, Bishop. Not for his tree. My host stops here."],
	[&"vey", "Lightning, Bishop. Since before you were born. Off the hill."],
	[&"ysolde", "A horn's down. The other one will have to sing for both."],
	[&"narrator", "Ten families under the tree. The goats, mostly, made it too."],
	[&"messenger", "That's... twenty, my lady. Twenty! The tree's getting... crowded."],
	[&"ysolde", "Everyone. Every last one. Now we only have to keep them."],
	[&"ysolde", "The ford is his. The hill is ours, and every family on it, and the tree."],
	[&"vessa", "He'll call it a victory, you know."],
	[&"ysolde", "Let him. Something always grows back. It will not stop."],
	[&"narrator", "Night fell. The golden tree still stood, and everyone who made it up the hill slept under it."],
	[&"ysolde", "Keep them... under the tree... Maelis..."],
	[&"maelis", "The Master's tree... It's gone dark."],
	[&"ysolde", "Too many. We were too slow, and the valley is empty."],
	[&"maelis", "The forest is not done with me. Neither am I."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The horns have sounded on both hills. Malrik and Torvald are coming down to the river, and between them and Lark Hill lie three hamlets, two farms, and the Master's golden tree.",
	"Ysolde cannot win the valley today. She can keep it: bring every family up the hill to the tree, and hold the hill until the sun goes down. Vessa holds the east slope, and has promised to be patient. Nobody believes her.",
	"Hold Lark Hill until nightfall. Let them have the water if they must. Nothing that lives on this hill is theirs.",
]
const BRIEFING_EP3 := "You have seen this afternoon from the other hill. This time, stand under the tree."
const HINT_START := "Ring the hamlet bells with Ysolde (or Maelis): the villagers walk to the golden tree by themselves. Two farms wait across the river."
const HINT_STRONGHOLD := "Your Heartwood can become a Stronghold: select it and press X (200 crystals). It opens Vinelasher, Greenheart Oathkeeper (Grove Hall) · Bramblesage (Keep)."
const HINT_SAGE := "Bramblesage: Z Snagroot drags an enemy to the Sage. V Pollen Haze makes archers inside it fire only at point-blank range."
const HINT_FARM := "Ring the farm bell. The farm folk must cross the ford: keep the bank clear while they wade."
const HINT_FORD := "Malrik wants the ford. Pollen Haze his archers, Snagroot his Deacon, and hold the south bank."
const MSG_FARM_LOCKED := "Clear the picket first: the farm folk won't open their doors"
const MSG_VESSA_FELL := "Vessa falls back to the Heartwood"
const MSG_RIDGE_BURNS := "The ridge burns, but the Bishop holds it"
const MSG_HORN_CALL := "The Lark horns call the hill: {count} of its folk answer"

## Read only.
var tree: MissionTree
var ford_zone: MissionZone
var standards := {}                     ## id -> MissionZone
var horns := {}                         ## id -> Building
var bells := {}                         ## id -> {roused, burned, picket}
var folk: Array = []                    ## every villager spawned (alive or not)
var folk_saved := 0                     ## alive inside the refuge
var folk_lost := 0                      ## killed or burned
var folk_rescued_peak := 0              ## the highest saved count (barks)
var malrik: Wizard = null
var torvald: Wizard = null
var vessa: Wizard = null
var maelis: Helper = null
var hush: Unit = null
var vey: Unit = null
var wren: Unit = null
var picket_groups := {}
var waves_fired: Array[StringName] = []
var horns_down := 0
var said: Array[String] = []
var victory_time := -1.0
var ford_lost_at := -1.0
var ice_final_units: Array = []
var hush_fled := 0

var _said := {}
var _tick := 0.0
var _zone_tick := 0.0
var _horn_call_left := -1.0
var _guests: Array = []
var _hush_back_left := -1.0
var _wren_kneel_left := 0.0
var _vey_kneel_left := 0.0
var _wizard_wave := {}
var _horn_type: BuildingType
var _folk_type: UnitType
var _wren_type: UnitType
var _vey_type: UnitType
var _guest_types := {}
var _river: RiverSystem
var _last_obj_text := ""
var _maelis_returned := false
var _props := {}                        ## bell id -> Node3D (cottages, bell post, smoke)


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"nature"
	enemy_kingdom = &"shadow"
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
	define_objectives([[&"obj_folk", "primary"], [&"obj_tree", "primary"], [&"obj_nightfall", "primary"],
			[&"obj_ysolde", "primary"], [&"sec_ford", "secondary"], [&"sec_horns", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"shadow_knight", &"rime_colossus"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Heartwood has fallen"
	c.tiers_enabled = true
	c.max_tier = 2
	c.bots_upgrade = false
	c.start_tiers = {ALLY_SEAT: 2, SHADOW_SEAT: 2, ICE_SEAT: 2}
	c.casters_enabled = true
	c.start_level = 3
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = START_ESSENCE
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nLark Hill holds"
	c.defeat_banner = "DEFEAT"
	c.seat_sides = {PLAYER_SEAT: 0, ALLY_SEAT: 0, SHADOW_SEAT: 1, ICE_SEAT: 1}
	c.seat_opponents = {SHADOW_SEAT: PLAYER_SEAT, ICE_SEAT: ALLY_SEAT, ALLY_SEAT: ICE_SEAT, PLAYER_SEAT: SHADOW_SEAT}
	c.seat_kingdoms = {PLAYER_SEAT: &"nature", ALLY_SEAT: &"fire", SHADOW_SEAT: &"shadow", ICE_SEAT: &"ice"}
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"bramblesage", "trigger": &"unlock", "key_hint": "Heartwood: B",
			"card": "Bramblesage. Pull the caster in, blind the archers: the forest reaches out."}
	return c


func _map_size() -> Vector2:
	return Vector2(MAP_W, MAP_D)


func _player_start() -> Vector3:
	return YSOLDE_START


func _use_map_dressing() -> bool:
	return false


func _title_line() -> String:
	return "Episode 4, Mission 1: %s" % MISSION_TITLE


func _ready() -> void:
	_horn_type = _make_horn_type()
	_folk_type = _make_story_type("thornling", &"meadow_folk", "Meadow folk", 45.0, 4.0)
	_wren_type = _make_story_type("wildwood_archer", &"wren", "Wren", 260.0, 5.2)
	var vb := UnitType.find("torren_vey")
	if vb:
		_vey_type = vb.duplicate() as UnitType
		_vey_type.commandable = false
	for id in ["thornling", "burr_slinger"]:
		var base := UnitType.find(id)
		if base:
			var t := base.duplicate() as UnitType
			t.id = StringName(id + "_guest")   # its own id: a load rebuilds a guest from it (pop 0), not the data type
			t.pop = 0   # the hill's folk answering the horn: guests, no pop
			_guest_types[id] = t
			register_local_unit_type(t)
	register_local_building_type(_horn_type)
	register_local_unit_type(_folk_type)
	register_local_unit_type(_wren_type)
	register_local_unit_type(_vey_type)   # torren_vey, not commandable (a load must not bring the data one back)
	super()
	if camera_rig:
		camera_rig.focus_on(YSOLDE_START)


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


## A story unit type (e2m1 D5): team PLAYER, not commandable, no attack, pop 0, from `base_id`'s look.
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
	t.kill_xp = 10
	t.support_kind = &""
	return t


# ---------------------------------------------------------------- seats

func start_position(team: int) -> Vector3:
	match team:
		ALLY_SEAT:
			return VESSA_ANCHOR
		SHADOW_SEAT:
			return MALRIK_ANCHOR
		ICE_SEAT:
			return TORVALD_ANCHOR
	return YSOLDE_START


func base_center(team: int) -> Vector3:
	if seat_bases.has(team):
		return seat_bases[team]
	match team:
		ALLY_SEAT:
			return FIRE_KEEP
		SHADOW_SEAT:
			return DUSK_KEEP
		ICE_SEAT:
			return RIME_KEEP
	return HEARTWOOD


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	if k:
		return k.spawn_point()
	if team == ALLY_SEAT:   # her keep fell: she comes back at the Heartwood (spec Win / lose)
		var hw := keep_of(PLAYER_SEAT)
		if hw:
			return hw.spawn_point()
	return base_center(team) + Vector3(4.0, 0.0, 4.0)


func node_of(team: int, suffix: String) -> CrystalNode:
	var prefix := {PLAYER_SEAT: "e3_grove_", ALLY_SEAT: "e3_ember_", SHADOW_SEAT: "e3_dusk_", ICE_SEAT: "e3_rime_"}
	var id := StringName("%s%s" % [prefix.get(team, "e3_grove_"), suffix])
	var v: Variant = crystal_nodes.get(id)
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
			return Vector3(-50.0, 0.0, 30.0)
		SHADOW_SEAT:
			return Vector3(-41.0, 0.0, -36.0)
		ICE_SEAT:
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
	for row: Array in MissionE3_01.NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	_river = MissionE3_01.make_river(nav_region, YSOLDE_START)
	var mat := _ground_material()
	if mat:
		EnvProps.set_river(mat, _river.shader_params())
	keep = build_grid.spawn_complete(BuildingType.find("nature_keep"), HEARTWOOD, PLAYER_SEAT) as Keep
	var gh := build_grid.spawn_complete(BuildingType.find("nature_barracks"), GROVE_HALL, PLAYER_SEAT)
	if gh:
		gh.set_meta(&"e4m1_hall", true)
	for p in SEED_HOLLOWS:
		build_grid.spawn_complete(BuildingType.find("nature_hollow"), p, PLAYER_SEAT)
	seat_bases[PLAYER_SEAT] = HEARTWOOD
	var fk := build_grid.spawn_complete(BuildingType.find("fire_keep"), FIRE_KEEP, ALLY_SEAT) as Keep
	var eh := build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL, ALLY_SEAT)
	if eh:
		eh.set_meta(&"e4m1_hall", true)
	for p in HEARTHS:
		build_grid.spawn_complete(BuildingType.find("fire_hearth"), p, ALLY_SEAT)
	_seat_keep(ALLY_SEAT, fk, FIRE_KEEP)
	var dk := build_grid.spawn_complete(BuildingType.find("shadow_keep"), DUSK_KEEP, SHADOW_SEAT) as Keep
	var gl := build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL, SHADOW_SEAT)
	if gl:
		gl.set_meta(&"e4m1_hall", true)
	build_grid.spawn_complete(BuildingType.find("shadow_hovel"), HOVEL, SHADOW_SEAT)
	shadow_keep = dk
	_seat_keep(SHADOW_SEAT, dk, DUSK_KEEP)
	var rk := build_grid.spawn_complete(BuildingType.find("ice_keep"), RIME_KEEP, ICE_SEAT) as Keep
	var rh := build_grid.spawn_complete(BuildingType.find("ice_barracks"), RIME_HALL, ICE_SEAT)
	if rh:
		rh.set_meta(&"e4m1_hall", true)
	_seat_keep(ICE_SEAT, rk, RIME_KEEP)
	for k: Keep in [dk, rk]:
		if k:
			k.destroyed.connect(_on_enemy_keep_destroyed)
	for seat: int in CREST_SPIRES:
		for p: Vector3 in CREST_SPIRES[seat]:
			build_grid.spawn_complete(BuildingType.find("nature_tower" if seat == PLAYER_SEAT else "fire_tower"), p, seat)
	for id: StringName in HORNS:
		var h := build_grid.spawn_complete(_horn_type, HORNS[id], PLAYER_SEAT) if _horn_type else null
		if h:
			h.name = "HornSpire_%s" % String(id)
			mark_scripted(h)
			horns[id] = h
			h.destroyed.connect(_on_horn_destroyed.bind(id))
	var diff := clampi(mission_difficulty, 0, 2)
	tree = MissionTree.new()
	tree.building_type = MissionTree.make_type(TREE_HP[diff])
	tree.name = "GoldenTree"
	tree.team = PLAYER_SEAT
	tree.refuge_radius = REFUGE_R
	tree.position = build_grid.snap(GOLDEN_TREE, tree.building_type.footprint)
	nav_region.add_child(tree, true)
	mark_scripted(tree)
	tree.destroyed.connect(_on_tree_destroyed)
	for id: StringName in BELLS:
		_add_place_props(id)


func _seat_keep(seat: int, k: Keep, at: Vector3) -> void:
	if k:
		seat_keeps[seat] = k
	seat_bases[seat] = k.global_position if k else at
	seat_starts[seat] = start_position(seat)


## Placeholder hamlet / farm props (E4M1.V1 replaces them): 3 cottages (or a barn and 2 ricks) and a bell post.
func _add_place_props(id: StringName) -> void:
	if _SIM.enabled or DisplayServer.get_name() == "headless":
		return
	var row: Array = BELLS[id]
	var root := Node3D.new()
	root.name = "Place_%s" % String(id)
	add_child(root)
	root.position = row[1]
	var wall := StandardMaterial3D.new()
	wall.albedo_color = Color(0.78, 0.70, 0.55) if row[2] == &"hamlet" else Color(0.55, 0.35, 0.22)
	var roof := StandardMaterial3D.new()
	roof.albedo_color = Color(0.55, 0.42, 0.25)
	var offs := [Vector3(-3.5, 0.0, -1.5), Vector3(3.0, 0.0, -2.0), Vector3(0.5, 0.0, 3.2)]
	for i in offs.size():
		var house := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(2.6, 1.8, 2.2) if row[2] == &"hamlet" or i == 0 else Vector3(1.6, 1.6, 1.6)
		house.mesh = b
		house.material_override = wall
		house.position = offs[i] + Vector3(0.0, b.size.y * 0.5, 0.0)
		root.add_child(house)
		var top := MeshInstance3D.new()
		var pr := PrismMesh.new()
		pr.size = Vector3(b.size.x + 0.3, 1.0, b.size.z + 0.3)
		top.mesh = pr
		top.material_override = roof
		top.position = offs[i] + Vector3(0.0, b.size.y + 0.5, 0.0)
		root.add_child(top)
	var post := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.08
	pc.bottom_radius = 0.1
	pc.height = 2.6
	post.mesh = pc
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.4, 0.3, 0.2)
	post.material_override = wood
	post.position = Vector3(0.0, 1.3, 0.0)
	root.add_child(post)
	var bell := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.28
	bm.height = 0.45
	bell.mesh = bm
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.85, 0.68, 0.3)
	bell.material_override = brass
	bell.position = Vector3(0.0, 2.6, 0.0)
	root.add_child(bell)
	_props[id] = root


func _smoke(id: StringName) -> void:
	var root := _props.get(id) as Node3D
	if root == null:
		return
	var col := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 1.6
	c.bottom_radius = 0.6
	c.height = 9.0
	col.mesh = c
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.2, 0.2, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	col.material_override = m
	col.position = Vector3(0.0, 5.0, 0.0)
	root.add_child(col)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for team: int in [PLAYER_SEAT, ALLY_SEAT]:
		for p: Vector3 in [MissionE3_01.FORD_STONE, MissionE3_01.FORD_REED, MissionE3_01.FORD_BIRCH, GOLDEN_TREE,
				YSOLDE_START, VESSA_ANCHOR]:
			fog.reveal(team, p, 8.0)
		for id: StringName in STANDARDS:
			fog.reveal(team, STANDARDS[id][1], STANDARD_SIGHT)
		for id: StringName in BELLS:
			fog.reveal(team, BELLS[id][1], 7.0)
	for team: int in [SHADOW_SEAT, ICE_SEAT]:
		for p: Vector3 in [MissionE3_01.FORD_STONE, MissionE3_01.FORD_REED, MissionE3_01.FORD_BIRCH, MALRIK_ANCHOR]:
			fog.reveal(team, p, 6.0)
	_setup_champions()
	# --- Ysolde (the player), Maelis, Wren, the start army.
	hero = _make_wizard(PLAYER_SEAT)
	_spawn(hero, PLAYER_SEAT, YSOLDE_START)
	_claim_wizard(hero, PLAYER_SEAT)
	ItemDrops.ensure_inventory(hero)
	raise_wizard(hero, 3, YSOLDE_SPELLS)
	set_meta(&"campaign_flags", _save_flags())
	for i in 6:
		var w := _spawn(make_unit("sprigling"), PLAYER_SEAT, HEARTWOOD + Vector3(-4.0 + i * 1.5, 0.0, -5.0))
		w.call(&"command_gather", node_of(PLAYER_SEAT, "a" if i < 3 else "b"))
	var posts := [
		[Vector3(6.0, 0.0, 8.0), [["thornling", 4], ["burr_slinger", 2]]],
		[Vector3(-40.0, 0.0, 13.0), [["thornling", 3]]],
		[Vector3(48.0, 0.0, 13.0), [["burr_slinger", 2], ["bramblehorn", 0 if diff == 2 else 1]]],
		[Vector3(-28.0, 0.0, 20.0), [["thornling", 4 + (3 if diff == 0 else 0)], ["bloomtender", 1]]],
		[Vector3(1.5, 0.0, 21.5), [["greenheart_oathkeeper", 2], ["wildwood_archer", 3]]],
	]
	for post: Array in posts:
		var k := 0
		for row: Array in post[1]:
			for j in int(row[1]):
				var a := float(k) * 1.1
				_spawn(make_unit(String(row[0])), PLAYER_SEAT, (post[0] as Vector3) + Vector3(cos(a) * 2.2, 0.0, sin(a) * 2.2))
				k += 1
	maelis = _story_maelis()
	if _wren_type:
		wren = _spawn(Worker.make_unit(_wren_type), PLAYER_SEAT, YSOLDE_START + Vector3(-2.0, 0.0, 3.0))
		wren.death_guard = _wren_guard
		mark_scripted(wren)
	# --- Vessa (ALLY, Fire): her Commander's camp, the scripted guards at the ford and Lark Well.
	var fire := activate_seat(ALLY_SEAT, &"fire", {"crystals": 300,
			"workers": [["cinder_hand", 3, node_of(ALLY_SEAT, "a")], ["cinder_hand", 2, node_of(ALLY_SEAT, "b")]],
			"units": [["flame_guard", 4, FIRE_RALLY], ["ember_archer", 2, FIRE_RALLY]],
			"wizard": {"level": 4, "spells": VESSA_SPELLS, "pos": VESSA_ANCHOR}})
	vessa = fire.get("wizard") as Wizard
	if vessa:
		mark_scripted(vessa)
		vessa.set_meta(META_HOME, VESSA_ANCHOR)
		vessa.died.connect(_on_bot_wizard_died.bind(ALLY_SEAT))
	for u in spawn_group([["flame_guard", 2]], Vector3(8.0, 0.0, 9.0), 1.6, ALLY_SEAT, true):
		(u as Unit).set_meta(&"vessa_guard", true)
	for u in spawn_group([["flame_guard", 3], ["ember_archer", 2], ["pyre_adept", 1]], STANDARDS[&"std_well"][1], 2.6,
			ALLY_SEAT, true):
		(u as Unit).set_meta(&"vessa_guard", true)
	_add_seat_commander(ALLY_SEAT)
	# --- Malrik (ENEMY, Shadow) with Hush, Torvald (ENEMY_2, Ice).
	var sh := activate_seat(SHADOW_SEAT, &"shadow", {"crystals": 300,
			"workers": [["gloom_thrall", 3, node_of(SHADOW_SEAT, "a")], ["gloom_thrall", 2, node_of(SHADOW_SEAT, "b")]],
			"units": [["shade", 4, SHADOW_RALLY], ["nightbolt", 2, SHADOW_RALLY], ["grave_hound", 2, SHADOW_RALLY]],
			"wizard": {"level": 4, "spells": MALRIK_SPELLS, "pos": MALRIK_ANCHOR}})
	malrik = sh.get("wizard") as Wizard
	shadow_hero = malrik
	var ice := activate_seat(ICE_SEAT, &"ice", {"crystals": 300,
			"workers": [["rime_hauler", 2, node_of(ICE_SEAT, "a")], ["rime_hauler", 2, node_of(ICE_SEAT, "b")]],
			"units": [["rimeshield", 4, ICE_RALLY], ["shardcaster", 2, ICE_RALLY], ["frost_mortar", 1, ICE_RALLY],
					["rimecarver", 1, ICE_RALLY]],
			"wizard": {"level": 4, "spells": TORVALD_SPELLS, "pos": TORVALD_ANCHOR}})
	torvald = ice.get("wizard") as Wizard
	for w: Variant in [malrik, torvald]:
		if w != null:
			var wz := w as Wizard
			mark_scripted(wz)
			wz.set_meta(META_HOME, wz.global_position)
			wz.level_cap = 4   # W4 raises them to L5, the Final to L6 (hard L7)
			wz.died.connect(_on_bot_wizard_died.bind(int(wz.team)))
	_add_seat_commander(SHADOW_SEAT)
	_add_seat_commander(ICE_SEAT)
	wizard_respawned.connect(_on_e4_wizard_respawned)
	_spawn_hush(HUSH_ANCHOR)
	# --- Zones, bells, pickets.
	_add_zones()
	for id: StringName in BELLS:
		bells[id] = {"roused": false, "burned": false, "picket": BELLS[id][3]}
	for gid: StringName in PICKETS:
		var row: Array = PICKETS[gid]
		picket_groups[gid] = spawn_group(row[2], row[1], 4.0, int(row[0]) as Unit.Team, true)
	_add_events()
	begin_mission([&"obj_folk", &"obj_tree", &"obj_nightfall", &"obj_ysolde", &"sec_ford", &"sec_horns"])


func _save_flags() -> Dictionary:
	var cs := CampaignState.open(campaign_save_path)
	return cs.flags.duplicate()


## Maelis (story unit, D6): helper_maelis at Ysolde's level, Escort, back at the Heartwood 45 s after a fall.
func _story_maelis() -> Helper:
	var ht := HelperType.find(&"helper_maelis")
	if ht == null or hero == null:
		return null
	var hp := Helper.new()
	hp.apply_helper_type(ht, hero.level)
	hp.name = "MaelisStory"
	_spawn(hp, PLAYER_SEAT, YSOLDE_START + Vector3(2.5, 0.0, 1.5))
	hp.bond_to(hero)
	hp.set_stance(&"escort")
	mark_scripted(hp)
	hp.died.connect(func(_u: Unit) -> void:
		after(MAELIS_BACK, func() -> void:
			if is_instance_valid(hp) and not hp.is_alive() and not is_ending():
				hp.respawn(respawn_point(PLAYER_SEAT))
				if not _maelis_returned:
					_maelis_returned = true
					say_l("L38")))
	return hp


## Mother Hush (D10): the mother_hush unit on Malrik's seat; flees at 25 % HP (back 90 s later, full HP).
func _spawn_hush(at: Vector3) -> void:
	if UnitType.find("mother_hush") == null:
		return
	hush = _spawn(make_unit("mother_hush"), SHADOW_SEAT, at)
	mark_scripted(hush)
	hush.set_meta(META_HOME, HUSH_ANCHOR)
	hush.death_guard = _hush_guard


func _hush_guard(_attacker: Variant) -> bool:
	if hush == null or not is_instance_valid(hush):
		return false
	_hush_flee()
	return true


func _hush_flee() -> void:
	if hush == null or is_dormant(hush):
		return
	hush_fled += 1
	hush.hp = hush.max_hp
	set_dormant(hush, true)
	hush.visible = false
	_wave_units.erase(hush)
	hush.global_position = DUSK_KEEP + Vector3(4.0, 0.0, 6.0)
	_hush_back_left = HUSH_BACK


func _tick_hush(dt: float) -> void:
	if hush == null or not is_instance_valid(hush):
		return
	if not is_dormant(hush) and hush.hp < hush.max_hp * HUSH_FLEE:
		_hush_flee()
		return
	if _hush_back_left > 0.0:
		_hush_back_left -= dt
		if _hush_back_left <= 0.0:
			set_dormant(hush, false)
			hush.visible = true
			hush.hp = hush.max_hp
			hush.global_position = HUSH_ANCHOR
			hush.command_move(HUSH_ANCHOR)


## The seat's Commander: the kingdom's knobs, never attacks (the scripted waves are the attacks), few workers, no
## expansion, no new towers; Vessa up to 14 army pop (7 soldiers), the enemies 10 soldiers at their rallies.
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
	p.id = StringName("mission_e4_01_%s" % ("ally" if seat == ALLY_SEAT else "enemy"))
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
	p.max_soldiers = int(by_difficulty(ALLY_SOLDIERS)) if seat == ALLY_SEAT else 10
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
	bot.name = "ShadowBot" if seat == SHADOW_SEAT else "Bot%d" % seat
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
	ford_zone.capture_time = 60.0
	ford_zone.fixed_rate = true
	ford_zone.lock_on_capture = true
	ford_zone.sides_allowed = [1]
	add_child(ford_zone)
	ford_zone.global_position = FORD_ZONE
	ford_zone.captured.connect(_on_ford_captured)
	register_actor("zone_ford", ford_zone)
	for id: StringName in STANDARDS:
		var z := MissionZone.new()
		z.zone_id = id
		z.display_name = String(STANDARDS[id][0])
		z.radius = STANDARD_R
		z.capture_time = STANDARD_TIME
		z.has_pole = true
		z.time_factor = {0: 1.0, 1: FAR_BANK}
		add_child(z)
		z.global_position = STANDARDS[id][1]
		z.set_owner_side(0)
		z.captured.connect(_on_standard_captured)
		register_actor("zone_%s" % String(id), z)
		standards[id] = z


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	var paras := BRIEFING_PARAGRAPHS.duplicate()
	if bool(_save_flags().get("e3m1_standard_toppled", false)):
		paras[2] = "%s %s" % [paras[2], BRIEFING_EP3]
	return {
		"title": _title_line(),
		"paragraphs": paras,
		"objectives": [objective_text(&"obj_folk", false), objective_text(&"obj_tree", false),
				objective_text(&"obj_nightfall", false)],
		"rule": Loc.sink(objective_text(&"obj_ysolde")),
	}


func folk_needed() -> int:
	return int(by_difficulty(FOLK_NEEDED))


func folk_lost_max() -> int:
	return int(by_difficulty(FOLK_LOST_MAX))


func nightfall_at() -> float:
	return NIGHTFALL_AT + float(by_difficulty(FINAL_SHIFT))


func nightfall_left() -> float:
	return maxf(0.0, nightfall_at() - mission_time())


func folk_out() -> int:
	return maxi(0, FOLK_TOTAL - folk_saved - folk_lost)


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_folk":
			if with_counter:
				return "Bring the villagers to the golden tree (%d / 30 · at least %d)" % [folk_saved, folk_needed()]
			return "Bring the villagers to the golden tree"
		&"obj_tree":
			return "The Master's tree must stand"
		&"obj_nightfall":
			if with_counter and objective_state("obj_nightfall") == "active":
				var s := int(ceil(nightfall_left()))
				return "Hold Lark Hill until nightfall (%d:%02d)" % [s / 60, s % 60]
			return "Hold Lark Hill until nightfall"
		&"obj_ysolde":
			return "Ysolde must survive"
		&"sec_ford":
			if with_counter and ford_zone and not ford_zone.locked and ford_zone.progress > 0.0:
				return "Hold the Stone Ford until the evening horn (%d %%)" % int(100.0 * ford_zone.progress)
			return "Hold the Stone Ford until the evening horn"
		&"sec_horns":
			if with_counter:
				return "Keep the Lark horns sounding (%d / 2)" % _horns_alive()
			return "Keep the Lark horns sounding"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_folk":
			return {"counter": folk_saved, "goal": folk_needed(),
					"detail": Loc.t("{saved} saved · {lost} lost · {out} still out",
							{"saved": folk_saved, "lost": folk_lost, "out": folk_out()}),
					"position": GOLDEN_TREE}
		&"obj_nightfall":
			if objective_state("obj_nightfall") == "active":
				return {"time_left": nightfall_left()}
		&"sec_ford":
			if ford_zone:
				return {"progress": int(100.0 * ford_zone.progress), "goal": 100, "position": FORD_ZONE}
		&"sec_horns":
			return {"counter": _horns_alive(), "goal": 2}
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
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)
	for id in ["L1", "L2", "L3", "L4", "L5"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 12.0)


func _add_events() -> void:
	var late := float(by_difficulty(LATE_SHIFT))
	var fin := float(by_difficulty(FINAL_SHIFT))
	after(210.0, func() -> void:
		if is_ending():
			return
		fire_once(&"E3")
		if hud:
			hud.show_message(HINT_STRONGHOLD, 12.0)
		show_spotlight())
	spotlight_first_unit.connect(func(_u: Unit) -> void:
		if fire_once(&"E4") and hud:
			hud.show_message(HINT_SAGE, 12.0))
	after(W1_AT, _fire_wave.bind(&"W1"))
	after(W2_AT, _fire_wave.bind(&"W2"))
	after(W3_AT, _fire_wave.bind(&"W3"))
	after(W4_AT + late, _evening_horn)
	after(W5_AT + late, _fire_wave.bind(&"W5"))
	after(RAID_AT + late, _fire_wave.bind(&"RAID"))
	after(FINAL_AT + fin, _fire_wave.bind(&"FINAL"))
	_horn_call_left = 0.0   # C4-7: the first call at HORN_CALL_AT (6:00), then every HORN_CALL_EVERY


func _fire_wave(id: StringName) -> void:
	if is_ending() or waves_fired.has(id):
		return
	waves_fired.append(id)
	match id:
		&"W1":
			fire_once(&"E5")
			say_l("L7")
			say_l("L8")
			for u in spawn_wave_at(WAVES[&"W1"], _hall_spawn(SHADOW_SEAT), SHADOW_SEAT):
				order_wave(u as Unit, &"forage", BELLS[&"reedfield"][1])
		&"W2":
			fire_once(&"E7")
			say_l("L10")
			say_l("L11")
			var units := spawn_wave_at(WAVES[&"W2"], _hall_spawn(ICE_SEAT), ICE_SEAT)
			_carry_wizard(torvald, &"probe", BELLS[&"birchend"][1])
			for u in units:
				order_wave(u as Unit, &"probe", BELLS[&"birchend"][1])
		&"W3":
			fire_once(&"E9")
			say_l("L12")
			say_l("L13")
			if hud:
				hud.show_message(HINT_FORD, 10.0)
			var units := spawn_wave_at(WAVES[&"W3"], _hall_spawn(SHADOW_SEAT), SHADOW_SEAT)
			_carry_wizard(malrik, &"ford", FORD_ZONE)
			_carry_hush(&"ford", FORD_ZONE)
			for u in units:
				order_wave(u as Unit, &"ford", FORD_ZONE)
		&"W4":
			_raise_enemy_wizards(5)
			var su := spawn_wave_at(WAVES[&"W4_S"], FORD_NORTH, SHADOW_SEAT)
			_carry_wizard(malrik, &"w4s", FORD_ZONE)
			for u in su:
				order_wave(u as Unit, &"w4s", FORD_ZONE)
			var iu := spawn_wave_at(WAVES[&"W4_I"], BIRCH_NORTH, ICE_SEAT)
			_carry_wizard(torvald, &"w4i", STANDARDS[&"std_well"][1])
			for u in iu:
				order_wave(u as Unit, &"w4i", STANDARDS[&"std_well"][1])
		&"W5":
			fire_once(&"E13")
			say_l("L19")
			for u in spawn_wave_at(WAVES[&"W5"], _hall_spawn(ICE_SEAT), ICE_SEAT):
				order_wave(u as Unit, &"siege", STANDARDS[&"std_well"][1])
		&"RAID":
			fire_once(&"E14")
			say_l("L20")
			say_l("L21")
			var units := spawn_wave_at(WAVES[&"RAID"], HUSH_ENTRY, SHADOW_SEAT)
			if hush and is_instance_valid(hush):
				if is_dormant(hush):
					set_dormant(hush, false)
					hush.visible = true
					_hush_back_left = -1.0
				hush.hp = hush.max_hp
				hush.global_position = HUSH_ENTRY + Vector3(1.5, 0.0, 0.0)
				order_wave(hush, &"raid", GOLDEN_TREE)
			for u in units:
				order_wave(u as Unit, &"raid", GOLDEN_TREE)
		&"FINAL":
			fire_once(&"E15")
			say_l("L22")
			say_l("L23")
			say_l("L24")
			_raise_enemy_wizards(int(by_difficulty([6, 6, 7])))
			var su := spawn_wave_at(WAVES[&"FINAL_S"], FORD_NORTH, SHADOW_SEAT)
			_carry_wizard(malrik, &"tree", GOLDEN_TREE)
			_carry_hush(&"tree", GOLDEN_TREE)
			for u in su:
				order_wave(u as Unit, &"tree", GOLDEN_TREE)
			_vessa_to_crest()
			after(ICE_FINAL_DELAY, _ice_final)   # a named method: a save in the Final stays allowed
			after(VEY_DELAY, _vey_arrives)


func _ice_final() -> void:
	if is_ending():
		return
	ice_final_units = spawn_wave_at(WAVES[&"FINAL_I"], BIRCH_NORTH, ICE_SEAT)
	_carry_wizard(torvald, &"ice_final", _nearest_owned_standard(BIRCH_NORTH))
	if torvald and is_instance_valid(torvald) and torvald.is_alive():
		ice_final_units.append(torvald)
	for u in ice_final_units:
		if u != torvald:
			order_wave(u as Unit, &"ice_final", _nearest_owned_standard(BIRCH_NORTH))


## E11 (12:00): the evening horn: e4m1_horn, W4 at both fords, the unroused south hamlets burn, sec_ford resolved.
func _evening_horn() -> void:
	if is_ending():
		return
	fire_once(&"E11")
	if objective_state("sec_ford") == "active":
		set_objective(&"sec_ford", "done")
	for id: StringName in BELLS:
		if BELLS[id][2] == &"hamlet":
			_burn(id)
	_fire_wave(&"W4")
	play_cutscene(&"e4m1_horn", func() -> void:
		say_l("L15")
		say_l("L16")
		if objective_state("sec_ford") == "done":
			say_l("L17")
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position))


func _raise_enemy_wizards(to_level: int) -> void:
	for w: Variant in [malrik, torvald]:
		if w != null and is_instance_valid(w):
			var wz := w as Wizard
			wz.level_cap = maxi(wz.level_cap, to_level)
			raise_wizard(wz, to_level, [])


## Old Vey (D9): a white-gold flash on the crest, he stands up out of it (Final + 45 s); story ally, kneels at 1 HP.
func _vey_arrives() -> void:
	if is_ending() or _vey_type == null:
		return
	fire_once(&"E16")
	flash_ring(VESSA_ANCHOR, 4.0)
	vey = _spawn(Worker.make_unit(_vey_type), PLAYER_SEAT, VESSA_ANCHOR)
	_arm_vey(vey)
	order_wave(vey, &"vey", GOLDEN_TREE)
	say_l("L26")


func _arm_vey(u: Unit) -> void:
	mark_scripted(u)
	u.death_guard = _vey_guard


func _vey_guard(_attacker: Variant) -> bool:
	if vey == null or not is_instance_valid(vey):
		return false
	vey.hp = 1.0
	if _vey_kneel_left <= 0.0:
		_vey_kneel_left = VEY_KNEEL
		set_dormant(vey, true)
	return true


func _vessa_to_crest() -> void:
	if vessa and is_instance_valid(vessa):
		vessa.set_meta(META_HOME, VESSA_CREST)
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ALLY_SEAT and u.has_meta(&"vessa_guard"):
			u.set_meta(META_HOME, VESSA_CREST + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
			u.command_attack_move(u.get_meta(META_HOME))


func _hall_spawn(seat: int) -> Vector3:
	for b in Building.for_team(seat):
		if b.is_alive() and b.has_meta(&"e4m1_hall") and b is TrainingBuilding:
			return (b as TrainingBuilding).spawn_point()
	var k := keep_of(seat)
	return k.spawn_point() if k else base_center(seat)


func _carry_wizard(w: Wizard, mode: StringName, at: Vector3) -> void:
	if w == null or not is_instance_valid(w) or not w.is_alive():
		return
	_wizard_wave[w] = true
	order_wave(w, mode, at)


func _carry_hush(mode: StringName, at: Vector3) -> void:
	if hush == null or not is_instance_valid(hush) or is_dormant(hush):
		return
	order_wave(hush, mode, at)


# ---------------------------------------------------------------- targets

func _walkers() -> Array[Unit]:
	var out: Array[Unit] = []
	for v: Variant in folk:
		if v != null and is_instance_valid(v) and (v as Unit).is_alive() and not (v as Unit).has_meta(&"saved"):
			out.append(v as Unit)
	return out


func _nearest_walker(from: Vector3, r: float) -> Unit:
	var best: Unit = null
	var d := r
	for u in _walkers():
		var dd := _flat(u.global_position, from)
		if dd < d:
			d = dd
			best = u
	return best


func _refuge_folk() -> Array[Unit]:
	var out: Array[Unit] = []
	for v: Variant in folk:
		if v != null and is_instance_valid(v) and (v as Unit).is_alive() and (v as Unit).has_meta(&"saved"):
			out.append(v as Unit)
	return out


func _nearest_owned_standard(from: Vector3) -> Vector3:
	var best := Vector3.INF
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


func _standard_owned(id: StringName, side := 0) -> bool:
	return standards.has(id) and (standards[id] as MissionZone).owner_side == side


func standards_owned(side := 0) -> int:
	var n := 0
	for id: StringName in standards:
		if (standards[id] as MissionZone).owner_side == side:
			n += 1
	return n


func _tree_alive() -> bool:
	return tree != null and is_instance_valid(tree) and tree.is_alive()


## `u` attack-moves to `at` unless it is busy or already there (within `near`).
func _push(u: Unit, at: Vector3, near := 4.0) -> void:
	if u.attack_target == null and _flat(u.global_position, at) > near and not u.is_attack_moving():
		u.command_attack_move(at)


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	if u is Wizard and (u == malrik or u == torvald) and u.hp < u.max_hp * WIZARD_RETREAT and mode != &"withdraw":
		u.set_meta(META_MODE, &"anchor")   # bot rule 8: under 35 % the wizard walks home
		u.command_move(u.get_meta(META_HOME, MALRIK_ANCHOR))
		_wizard_wave.erase(u)
		return true
	match mode:
		&"forage":
			var w := _nearest_walker(BELLS[&"millbrook"][1], 30.0)
			if w == null:
				w = _nearest_walker(BELLS[&"reedfield"][1], 30.0)
			if w != null:
				if u.attack_target == null:
					u.command_attack(w)
			elif not bool(bells[&"millbrook"]["roused"]) and not bool(bells[&"millbrook"]["burned"]):
				_push(u, BELLS[&"millbrook"][1])
			else:
				_push(u, GROVE_HALL)
			return true
		&"probe":
			if _flat(u.global_position, BELLS[&"birchend"][1]) < 6.0 or bool(bells[&"birchend"]["roused"]):
				u.set_meta(META_MODE, &"well")
			_push(u, BELLS[&"birchend"][1])
			return true
		&"well":
			_push(u, STANDARDS[&"std_well"][1])
			return true
		&"ford":
			if ford_zone.owner_side == 1:
				var to := _nearest_owned_standard(u.global_position)
				if to != Vector3.INF:
					u.set_meta(META_MODE, &"standard")
					_push(u, to)
					return true
			if u.attack_target == null and _flat(u.global_position, FORD_ZONE) > 4.0:
				u.command_attack_move(FORD_ZONE)
			return true
		&"standard":
			var to := _nearest_owned_standard(u.global_position)
			_push(u, to if to != Vector3.INF else STANDARDS[&"std_ysolde"][1], 3.0)
			return true
		&"w4s":
			var to := FORD_ZONE
			if ford_zone.owner_side == 1 or _flat(u.global_position, FORD_ZONE) < 3.0:
				to = STANDARDS[&"std_ysolde"][1]
				if not _standard_owned(&"std_ysolde"):
					to = STANDARDS[&"std_clover"][1]
			if ford_zone.owner_side == 1 and not _standard_owned(&"std_ysolde") and not _standard_owned(&"std_clover"):
				to = STANDARDS[&"std_clover"][1]
			_push(u, to, 3.0)
			return true
		&"w4i":
			var to: Vector3 = STANDARDS[&"std_well"][1]
			if not _standard_owned(&"std_well"):
				to = BELLS[&"birchend"][1]
			var w := _nearest_walker(u.global_position, 12.0)
			if w != null and u.attack_target == null:
				u.command_attack(w)
				return true
			_push(u, to, 3.0)
			return true
		&"siege":
			var fk := keep_of(ALLY_SEAT)
			var to: Vector3 = STANDARDS[&"std_well"][1]
			if not _standard_owned(&"std_well") and fk != null:
				to = fk.global_position
			_push(u, to, 4.0)
			return true
		&"raid":
			var inside := _refuge_folk()
			if not inside.is_empty():
				if u.attack_target == null:
					var best: Unit = inside[0]
					for f in inside:
						if _flat(f.global_position, u.global_position) < _flat(best.global_position, u.global_position):
							best = f
					u.command_attack(best)
			elif _tree_alive() and u.attack_target == null:
				u.command_attack(tree)
			return true
		&"tree":
			if not _tree_alive():
				return true
			if u.attack_target == null:
				if _flat(u.global_position, GOLDEN_TREE) < 14.0:
					u.command_attack(tree)
				elif not u.is_attack_moving():
					u.command_attack_move(GOLDEN_TREE)
			return true
		&"ice_final":
			var to := _nearest_owned_standard(u.global_position)
			if to == Vector3.INF:
				to = u.get_meta(META_TARGET, STANDARDS[&"std_well"][1])
			if _flat(u.global_position, to) < 7.0:
				_ice_reaches_standard(to)
				return true
			_push(u, to, 3.0)
			return true
		&"hold":
			var at: Vector3 = u.get_meta(META_TARGET, u.global_position)
			if u.attack_target == null and _flat(u.global_position, at) > 5.0:
				u.command_attack_move(at)
			return true
		&"vey":
			var foe := _enemy_near(GOLDEN_TREE, 24.0)
			if foe != null:
				if u.attack_target == null:
					u.command_attack(foe)
			else:
				_push(u, VESSA_CREST, 3.0)
			return true
		&"withdraw", &"anchor":
			return true
	return false


func _enemy_near(at: Vector3, r: float) -> Unit:
	var best: Unit = null
	var d := r
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or Teams.side_of(int(u.team)) != 1 or is_dormant(u):
			continue
		var dd := _flat(u.global_position, at)
		if dd < d:
			d = dd
			best = u
	return best


## E15 (part 2): the Ice Final group reaches its first standard: e4m1_foot (L25), it holds there until the Withdraw.
func _ice_reaches_standard(at: Vector3) -> void:
	if not fire_once(&"E15b"):
		return
	for v: Variant in ice_final_units:
		if v != null and is_instance_valid(v) and (v as Unit).is_alive():
			order_wave(v as Unit, &"hold", at)
	play_cutscene(&"e4m1_foot", func() -> void: say_l("L25"))


# ---------------------------------------------------------------- bells and villagers

func _tick_bells() -> void:
	var t := mission_time()
	for id: StringName in BELLS:
		var b: Dictionary = bells[id]
		if bool(b["roused"]) or bool(b["burned"]):
			continue
		var burn_at := float(by_difficulty(BELLS[id][4]))
		if burn_at > 0.0 and t >= burn_at:
			_burn(id)
			continue
		var at: Vector3 = BELLS[id][1]
		if not _rouser_near(at):
			continue
		var gid: StringName = b["picket"]
		if gid != &"" and not _all_dead(picket_groups.get(gid, [])):
			if hud and fire_once(StringName("locked_%s" % id)):
				hud.show_message(MSG_FARM_LOCKED, 4.0)
			continue
		_rouse(id)


func _rouser_near(at: Vector3) -> bool:
	for v: Variant in [hero, maelis, wren]:
		if v == null or not is_instance_valid(v) or not (v as Unit).is_alive() or is_dormant(v):
			continue
		if _flat((v as Node3D).global_position, at) <= BELL_R:
			return true
	return false


## A bell rings: its 6 villagers step out and walk to the refuge by themselves.
func rouse(id: StringName) -> void:
	_rouse(id)


func _rouse(id: StringName) -> void:
	var b: Dictionary = bells[id]
	if bool(b["roused"]) or bool(b["burned"]) or _folk_type == null:
		return
	b["roused"] = true
	if fire_once(&"E2"):
		say_l("L6")
	var at: Vector3 = BELLS[id][1]
	for i in FOLK_PER_BELL:
		var a := TAU * float(i) / float(FOLK_PER_BELL)
		var f := _spawn(Worker.make_unit(_folk_type), PLAYER_SEAT, at + Vector3(cos(a) * 2.0, 0.0, sin(a) * 2.0))
		_arm_folk(f)
		f.set_meta(&"bell", id)
		folk.append(f)
		f.command_move(_refuge_spot(i))
	flash_ring(at, 3.0)


## A villager's group, scripted mark and died hook (idempotent: the bell and a load run it).
func _arm_folk(f: Unit) -> void:
	f.add_to_group(&"meadow_folk")
	mark_scripted(f)
	if not f.died.is_connected(_on_folk_died):
		f.died.connect(_on_folk_died)


# ---------------------------------------------------------------- save / load (mission-save-hardening C4-2, C4-6)

## Units of the local types (villagers, Old Vey) rebuilt by a load get their hooks back.
func save_spawned(u: Unit, row: Dictionary) -> void:
	super(u, row)
	var id := String(row.get("type", ""))
	if _folk_type and id == String(_folk_type.id):
		_arm_folk(u)
	elif _vey_type and id == String(_vey_type.id):
		_arm_vey(u)


func _after_load(_nodes: Dictionary) -> void:
	for v: Variant in folk:
		if v is Unit and is_instance_valid(v):
			_arm_folk(v as Unit)
	if vey and is_instance_valid(vey):
		_arm_vey(vey)
	if hush and is_instance_valid(hush) and _hush_back_left > 0.0:
		hush.visible = false   # fled: hidden at the Dusk Keep until she comes back
	for id: StringName in bells:
		if bool((bells[id] as Dictionary).get("burned", false)):
			_smoke(id)


func _refuge_spot(i: int) -> Vector3:
	var a := float(i) * 2.39996 + randf() * 0.5
	var r := 3.0 + 4.0 * fmod(float(i) * 0.37, 1.0)
	return GOLDEN_TREE + Vector3(cos(a) * r, 0.0, sin(a) * r)


## A place nobody roused by its burn time burns: its villagers count as lost (E8).
func _burn(id: StringName) -> void:
	var b: Dictionary = bells[id]
	if bool(b["roused"]) or bool(b["burned"]):
		return
	b["burned"] = true
	folk_lost += FOLK_PER_BELL
	_smoke(id)
	if fire_once(StringName("E8_%s" % BELLS[id][2])):
		say_l("L14")
	_check_folk_lost()


func _on_folk_died(u: Unit) -> void:
	if is_ending():
		return
	folk_lost += 1
	if u.has_meta(&"saved"):
		folk_saved = maxi(0, folk_saved - 1)
	_check_folk_lost()


func _check_folk_lost() -> void:
	if folk_lost > folk_lost_max() and objective_state("obj_folk") == "active":
		_folk_failed()


func _folk_failed() -> void:
	if is_ending():
		return
	fire_once(&"E22")
	say_l("L37")
	set_objective(&"obj_folk", "failed")
	lose(DEFEAT_DELAY)


func _tick_folk() -> void:
	var saved := 0
	for v: Variant in folk:
		if v == null or not is_instance_valid(v) or not (v as Unit).is_alive():
			continue
		var f := v as Unit
		if f.has_meta(&"saved"):
			saved += 1
			continue
		if _flat(f.global_position, GOLDEN_TREE) <= REFUGE_R:
			f.set_meta(&"saved", true)
			f.add_modifier(&"mission:refuge", {"max_hp_pct": 1.0})   # "the tree shelters them" (-50 % damage)
			f.heal(f.max_hp)
			saved += 1
		elif not f.has_move_order():
			f.command_move(_refuge_spot(folk.find(f)))
	if saved != folk_saved:
		folk_saved = saved
	folk_rescued_peak = maxi(folk_rescued_peak, folk_saved)
	if folk_rescued_peak >= 10:
		say_l("L28")
	if folk_rescued_peak >= 20:
		say_l("L29")
	if folk_rescued_peak >= 30:
		say_l("L30")


# ---------------------------------------------------------------- Wren

func _wren_guard(_attacker: Variant) -> bool:
	if wren == null or not is_instance_valid(wren):
		return false
	wren.hp = 1.0
	if _wren_kneel_left <= 0.0:
		_wren_kneel_left = WREN_KNEEL
		set_dormant(wren, true)
	return true


func _tick_wren(dt: float) -> void:
	if wren == null or not is_instance_valid(wren) or not hero_alive():
		return
	if _wren_kneel_left > 0.0:
		_wren_kneel_left -= dt
		if _wren_kneel_left <= 0.0:
			set_dormant(wren, false)
			wren.death_guard = _wren_guard
			wren.hp = wren.max_hp * 0.5
		return
	var d := _flat(wren.global_position, hero.global_position)
	if d > WREN_FAR:
		var dir := wren.global_position - hero.global_position
		dir.y = 0.0
		dir = dir.normalized() if dir.length() > 0.1 else Vector3(0.0, 0.0, 1.0)
		wren.command_move(hero.global_position + dir * ((WREN_NEAR + WREN_FAR) * 0.5))


func _tick_vey(dt: float) -> void:
	if vey == null or not is_instance_valid(vey) or _vey_kneel_left <= 0.0:
		return
	_vey_kneel_left -= dt
	if _vey_kneel_left <= 0.0:
		set_dormant(vey, false)
		vey.death_guard = _vey_guard
		vey.hp = vey.max_hp * 0.5
		order_wave(vey, &"vey", GOLDEN_TREE)


# ---------------------------------------------------------------- the ford, standards, horns, the horn call

func _tick_zones(dt: float) -> void:
	if ford_zone and not ford_zone.locked:
		ford_zone.tick(dt)
	for id: StringName in standards:
		(standards[id] as MissionZone).tick(dt)


func _on_ford_captured(_z: MissionZone, side: int) -> void:
	if is_ending() or side != 1:
		return
	fire_once(&"E10")
	ford_lost_at = mission_time()
	if objective_state("sec_ford") == "active":
		set_objective(&"sec_ford", "failed")
		say_l("L15b")


func _on_standard_captured(z: MissionZone, side: int) -> void:
	if is_ending():
		return
	if side == 1:
		z.topple()
		if fire_once(&"E12"):
			say_l("L18")
	else:
		z.topple(true)
		fog.reveal(PLAYER_SEAT, z.global_position, STANDARD_SIGHT)
		fog.reveal(ALLY_SEAT, z.global_position, STANDARD_SIGHT)


func _horns_alive() -> int:
	var n := 0
	for id: StringName in horns:
		var hv: Variant = horns[id]
		if hv != null and is_instance_valid(hv) and (hv as Building).is_alive():
			n += 1
	return n


func _on_horn_destroyed(_b: Building, _id: StringName) -> void:
	if is_ending():
		return
	horns_down += 1
	if fire_once(&"E17"):
		say_l("L27")
	if _horns_alive() == 0 and objective_state("sec_horns") == "active":
		set_objective(&"sec_horns", "failed")
	elif objective_state("sec_horns") == "active":
		set_objective(&"sec_horns", "active")


## The horn call: per living Horn Spire, 2 Thornlings + 1 Burr Slinger (commandable, pop 0 guests, max 12 alive).
func _horn_call() -> void:
	_guests = _guests.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	var n := 0
	for id: StringName in horns:
		var hv: Variant = horns[id]
		if hv == null or not is_instance_valid(hv) or not (hv as Building).is_alive():
			continue
		for row: Array in WAVES[&"GUESTS"]:
			for i in int(row[1]):
				if _guests.size() >= GUESTS_MAX or not _guest_types.has(String(row[0])):
					continue
				var p := (hv as Building).global_position + Vector3(randf_range(-2.0, 2.0), 0.0, 4.0 + randf_range(0.0, 1.5))
				var g := _spawn(Worker.make_unit(_guest_types[String(row[0])]), PLAYER_SEAT, p)
				_guests.append(g)
				n += 1
	if n > 0 and hud:
		hud.show_message(Loc.t(MSG_HORN_CALL, {"count": n}), 4.0)


func _on_enemy_keep_destroyed(_b: Building) -> void:
	if not is_ending() and hud:
		hud.show_message(MSG_RIDGE_BURNS, 4.0)


# ---------------------------------------------------------------- wizards

func _on_bot_wizard_died(u: Unit, seat: int) -> void:
	if is_ending():
		return
	_wizard_wave.erase(u)
	_respawn_left[seat] = next_respawn_delay(seat)
	_deaths[seat] = int(_deaths.get(seat, 0)) + 1
	if seat == ALLY_SEAT and hud:
		hud.show_message(MSG_VESSA_FELL, 4.0)


func _on_e4_wizard_respawned(wiz: Wizard) -> void:
	if is_ending():
		return
	if wiz == malrik or wiz == torvald or wiz == vessa:
		wiz.set_meta(META_MODE, &"anchor")
		wiz.command_move(wiz.get_meta(META_HOME, wiz.global_position))
		if wiz != vessa and waves_fired.has(&"FINAL"):   # the Final carries them again
			_carry_wizard(wiz, &"tree" if wiz == malrik else &"ice_final", GOLDEN_TREE if wiz == malrik \
					else _nearest_owned_standard(BIRCH_NORTH))


func _tick_wizards() -> void:
	for w: Variant in [malrik, torvald, vessa]:
		if w == null or not is_instance_valid(w) or not (w as Wizard).is_alive() or _wizard_wave.has(w):
			continue
		var wiz := w as Wizard
		var home: Vector3 = wiz.get_meta(META_HOME, wiz.global_position)
		if wiz.attack_target == null and _flat(wiz.global_position, home) > 4.0 and not wiz.has_move_order():
			wiz.command_move(home)


func _tick_leash() -> void:
	for gid: StringName in picket_groups:
		for g: Variant in picket_groups[gid]:
			if not is_instance_valid(g) or not (g as Unit).is_alive() or not (g as Unit).has_meta(META_HOME):
				continue
			var u := g as Unit
			if _flat(u.global_position, u.get_meta(META_HOME)) > GUARD_LEASH:
				u.command_move(u.get_meta(META_HOME))


func _on_player_hero_fell() -> void:
	fire_once(&"E20")
	say_l("L35")
	set_objective(&"obj_ysolde", "failed")
	super()


func _on_tree_destroyed(_b: Building) -> void:
	if is_ending():
		return
	fire_once(&"E21")
	say_l("L36")
	set_objective(&"obj_tree", "failed")
	lose(DEFEAT_DELAY)


# ---------------------------------------------------------------- nightfall

## E19: nightfall: enough villagers under the tree = the Withdraw, e4m1_nightfall, victory; else defeat (E22).
func _nightfall() -> void:
	if is_ending() or has_fired(&"E19"):
		return
	if folk_saved < folk_needed():
		_folk_failed()
		return
	fire_once(&"E19")
	victory_time = mission_time()
	set_objective(&"obj_nightfall", "done")
	set_objective(&"obj_folk", "done")
	set_objective(&"obj_tree", "done")
	if objective_state("sec_horns") == "active":
		set_objective(&"sec_horns", "done" if _horns_alive() == 2 else "failed")
	_record_flags()
	clear_waves()
	_wave_units.clear()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.side_of(int(u.team)) == 1 and not u.is_worker():
			set_truce([u], true, Unit.TRUCE_ALL)
			u.set_meta(META_MODE, &"withdraw")
			u.command_move(FORD_STONES if u == malrik else FORD_ZONE + Vector3(randf_range(-4.0, 4.0), 0.0, -6.0))
	play_cutscene(&"e4m1_nightfall", func() -> void:
		for id in ["L31", "L32", "L33", "L34"]:
			say_l(id)
		set_objective(&"obj_ysolde", "done")
		win(1.0))


## Ysolde's track (D7 / campaign-outline D8, flags only like Malrik's in Ep3): folk saved, time, her essence (bonuses,
## 50 %, cap 1 500) in CampaignState.YSOLDE_ESSENCE_FLAG.
func _record_flags() -> void:
	set_mission_flag("e4m1_folk_saved", folk_saved)
	set_mission_flag("e4m1_time", int(victory_time))
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	var essence := bank.essence if bank else 0
	if objective_state("sec_ford") == "done":
		essence += 300
	if objective_state("sec_horns") == "done":
		essence += 200
	essence += mini(100, 10 * maxi(0, folk_saved - 20))
	set_mission_flag(CampaignState.YSOLDE_ESSENCE_FLAG, mini(ESSENCE_CAP, essence / 2))


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
	_tick_hush(delta)
	_tick_wren(delta)
	_tick_vey(delta)
	if _horn_call_left >= 0.0 and mission_time() >= HORN_CALL_AT:
		_horn_call_left -= delta
		if _horn_call_left <= 0.0:
			_horn_call_left = HORN_CALL_EVERY
			_horn_call()
	if objective_state("obj_nightfall") == "active" and mission_time() >= nightfall_at():
		_nightfall()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_bells()
		_tick_folk()
		_tick_wizards()
		_tick_leash()
		for gid: StringName in picket_groups:
			if not has_fired(&"E6") and _all_dead(picket_groups[gid]) and fire_once(&"E6"):
				say_l("L9")   # E6: the first farm picket is dead
				if hud:
					hud.show_message(HINT_FARM, 8.0)
		var t := "%s|%s|%s|%s" % [objective_text(&"obj_folk"), objective_text(&"obj_nightfall"),
				objective_text(&"sec_ford"), folk_lost]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
