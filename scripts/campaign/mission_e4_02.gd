class_name MissionE4_02
extends MissionBase
## Episode 4, mission 2 "The Green Road" (docs/design/mission-e4-02.md): an escort with a base. Ysolde keeps Larkrest
## camp running while 4 convoys of the people saved on Lark Hill walk the road west to Vessa's fort Cinderwatch. They
## cower while an enemy is near: the player clears the road ahead. Shadow hunters (Mother Hush, no Malrik) ambush the
## road from Gallow Hollow, an Ice watch holds the frozen brook. The Citadel opens, Maelis is called for the first time
## (the spotlight), the first Briar Rocs fly.
##
## Built deviations (2026-10-08, from the spec):
## - The map is built in code on a 160 x 100 MapInfo (no World Forge `green_road.map`): flat ground, no Old Wood trees,
##   the road / Lantern / Hollow Oak / Crowstone / brook as placeholder props; the brook banks are not walls (only the
##   crossing's ice slow, -30 % speed while a Rime Totem stands).
## - Gallow Hollow and Rimebrook are scripted camps of the ENEMY team with no Commander (the spec's no-wizard Commander
##   is not built): the hunters' rally group are guards, every attack is a scripted wave.
## - Cinderwatch is a scripted Fire fort building of the player's team (invulnerable, not a keep, no shop); Captain
##   Ashby is a Flame Guard story unit (not commandable) with 6 Flame Guards on a 6 m leash.
## - Hush is the mother_hush unit: she flees at 25 % HP (smoke) and is back 90 s later with the next wave that carries
##   her; Maelis's 0:00 scene is a story Helper that walks off the map (E2), the call is the real helper roster.
## - No Citadel delay to 5:45 (its hint comes at 5:45), no Briar Roc cap.
## Campaign review fixes (2026-10-16, docs/playtests/campaign_review_2026-10-16/part2.md "e4m2"):
## - Hush's knives: when convoy 2 or 3 reaches the frozen brook crossing (its lead past ROAD[4]), a small fast squad
##   comes down the brook from the north and goes for that convoy's tail walkers (not the army): the crossing is the
##   chokepoint the player must hold. A burned Gloom Hall cuts the squad like the other Shadow waves.
## - Convoy auto times one row shorter (normal 3:00 / 7:00 / 11:00 / 15:00), the Lantern re-rings after 2:30.
## - Determinism: a walker's road jitter comes from its place in its convoy's list, never its instance id.

const MISSION_ID := &"e4m2"
const MISSION_TITLE := "The Green Road"
const MAP_W := 160.0
const MAP_D := 100.0
const ENEMY := Unit.Team.ENEMY

const YSOLDE_START := Vector3(60.0, 0.0, -12.0)
const HEARTWOOD := Vector3(62.0, 0.0, -26.0)
const GROVE_HALL := Vector3(48.0, 0.0, -32.0)
const SEED_HOLLOWS: Array[Vector3] = [Vector3(70.0, 0.0, -38.0), Vector3(54.0, 0.0, -42.0)]
const ARMY_POS := Vector3(58.0, 0.0, -8.0)
const NODES := [[&"e4m2_rest_a", Vector3(71.0, 0.0, -20.0), 2500], [&"e4m2_rest_b", Vector3(60.0, 0.0, -36.0), 2500],
		[&"e4m2_glen", Vector3(32.0, 0.0, -22.0), 2500], [&"e4m2_gallow_a", Vector3(-2.0, 0.0, -44.0), 1500],
		[&"e4m2_gallow_b", Vector3(15.0, 0.0, -30.0), 1500]]
const LANTERN := Vector3(60.0, 0.0, 2.0)
const LANTERN_GREEN := Vector3(64.0, 0.0, 4.0)
const ROAD: Array[Vector3] = [Vector3(60.0, 0.0, 2.0), Vector3(50.0, 0.0, 4.0), Vector3(38.0, 0.0, 10.0),
		Vector3(22.0, 0.0, 6.0), Vector3(8.0, 0.0, -2.0), Vector3(-8.0, 0.0, -6.0), Vector3(-24.0, 0.0, 0.0),
		Vector3(-40.0, 0.0, 8.0), Vector3(-56.0, 0.0, 6.0), Vector3(-66.0, 0.0, 3.0)]
const CINDERWATCH := Vector3(-72.0, 0.0, -10.0)
const GATE := Vector3(-66.0, 0.0, 3.0)
const GATE_R := 8.0
const ASHBY_SPOT := Vector3(-60.0, 0.0, 12.0)
const HOLLOW_OAK := Vector3(36.0, 0.0, 18.0)
const CROWSTONE := Vector3(-40.0, 0.0, 16.0)
const BROOK_ICE := Vector3(-6.0, 0.0, -5.0)
const BROOK_ICE_R := 6.0
const BROOK_LINE: Array[Vector3] = [Vector3(-16.0, 0.0, -47.0), Vector3(-10.0, 0.0, -28.0), Vector3(-6.0, 0.0, -6.0),
		Vector3(-2.0, 0.0, 16.0), Vector3(-6.0, 0.0, 47.0)]
const TOTEMS: Array[Vector3] = [Vector3(-12.0, 0.0, -14.0), Vector3(2.0, 0.0, -14.0)]
const TOTEM_HP := 400.0
const DUSK_KEEP := Vector3(6.0, 0.0, -36.0)
const GLOOM_HALL := Vector3(-8.0, 0.0, -40.0)
const NIGHT_SPIRE := Vector3(6.0, 0.0, -22.0)
const HOVEL := Vector3(18.0, 0.0, -42.0)
const HUNTER_RALLY := Vector3(-2.0, 0.0, -22.0)
const FROST_HALL := Vector3(-40.0, 0.0, -34.0)
const RIME_SPIRE := Vector3(-28.0, 0.0, -20.0)
const SNOW_LODGE := Vector3(-50.0, 0.0, -40.0)
const MAELIS_EXIT := Vector3(20.0, 0.0, 46.0)
const A1_AT := Vector3(40.0, 0.0, 20.0)
const A2_AT := Vector3(-6.0, 0.0, -16.0)
const A3_AT := Vector3(-38.0, 0.0, 20.0)
const AMBUSH_R := 16.0
const LANTERN_R := 3.0
const RING_TIME := 3.0
const RING_GAP := 150.0
const WALK_SPEED := 3.6
const COWER_RESUME := 2.0
const CONVOYS := 4
const COWER_R: Array[float] = [12.0, 10.0, 8.0]
const NEEDED_PCT: Array[float] = [0.6, 0.75, 0.85]
const AUTO_TIMES := [[180.0, 450.0, 720.0, 990.0], [180.0, 420.0, 660.0, 900.0], [180.0, 390.0, 600.0, 810.0]]
const KNIFE_CONVOYS: Array[int] = [1, 2]          ## convoys 2 and 3 meet Hush's knives at the brook crossing
const KNIFE_WP := 5                                ## the lead walker heading for ROAD[5] (past ROAD[4]) springs them
const KNIFE_FROM := Vector3(-6.0, 0.0, 30.0)       ## down the brook from the north thicket
const H1_AT := 240.0
const RELIEF_FROM := 300.0
const RELIEF_EVERY := 180.0
const B1_AT := 360.0
const H2_AT := 540.0
const H3_AT := 780.0
const CITADEL_HINT_AT := 345.0
const HUSH_FLEE: Array[float] = [0.35, 0.25, 0.20]
const HUSH_BACK: Array[float] = [90.0, 90.0, 60.0]
const HOLLOW_CUT := 0.4
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 2.0
const LEVEL_CAP := 7
const ESSENCE_CAP := 1500
const NO_SAVE_ESSENCE := 500
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [500, 400, 300]
const MAELIS_PRICE := {"crystals": [200, 250, 300], "essence": [50, 100, 150], "time": [30.0, 30.0, 45.0]}

const GROUPS := {
	&"A1": [A1_AT, [["shade", 4], ["grave_hound", 2]]],
	&"A2": [A2_AT, [["rimeling", 3], ["shardcaster", 2]]],
	&"A3": [A3_AT, [["shade", 3], ["hexweaver", 1]]],
}
const WAVES := {
	&"H1": [["shade", 3], ["grave_hound", 2]],
	&"RELIEF": [["rimeling", 3], ["shardcaster", 1]],
	&"B1": [["rimeshield", 4], ["shardcaster", 2]],
	&"H2": [["shade", 4], ["nightbolt", 2], ["hexweaver", 1]],
	&"H3": [["shade", 4], ["grave_hound", 2], ["hollow_oathsworn", 1]],
	&"H4_S": [["shade", 5], ["nightbolt", 3], ["shadow_knight", 1], ["gloom_deacon", 1]],
	&"H4_I": [["rimeshield", 3], ["shardcaster", 2], ["frost_mortar", 1]],
	&"KNIVES": [["grave_hound", 2], ["shade", 1]],
}

const SPEAKER_COLORS := {&"ysolde": Color(0.55, 0.90, 0.35), &"maelis": Color(0.60, 0.85, 0.50),
		&"messenger": Color(0.80, 0.92, 0.60), &"hush": Color(0.60, 0.50, 0.75), &"ashby": Color(0.95, 0.60, 0.35),
		&"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"ysolde": "Ysolde", &"maelis": "Maelis", &"messenger": "Wren", &"hush": "Mother Hush",
		&"ashby": "Captain Ashby", &"narrator": "Narrator"}
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L10", "L11", "L12", "L13", "L14",
		"L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25", "L26", "L27", "L28", "L29", "L30",
		"L31", "L32", "L33"]
const DIALOGUE := [
	[&"narrator", "The morning after Lark Hill. The wagons burned in the night. The people will have to walk."],
	[&"ysolde", "One road, the Fire border at the end of it, and everyone we kept alive. We walk them there."],
	[&"maelis", "The western woods are old and full of ears. Some of those ears are Malrik's."],
	[&"messenger", "The first ones are... they're ready, my lady. Ring the lantern and... they'll go."],
	[&"maelis", "I'll run ahead and smell the road. Call me when your tree grows tall enough to shout."],
	[&"ysolde", "Don't fight them all on your own. Leave me a few."],
	[&"ysolde", "Torvald froze the brook. The old folk will slip, and his archers know it."],
	[&"ysolde", "Stay on the road. If anything moves in the trees, stop, and let the thorns go first."],
	[&"ysolde", "Knives in the oak! Down, everyone down! Thornlings, into the ferns!"],
	[&"hush", "Little lambs on a little road. The Bishop sends his regards."],
	[&"ysolde", "You burned their wagons. You don't get their children."],
	[&"ysolde", "Maelis! The Heartwood stands tall enough. Come home."],
	[&"maelis", "I went to see the brook. It is cold, it is guarded, and it is very rude."],
	[&"ashby", "Nature folk at the gate! Open up, lads. Blankets, bread, and no questions."],
	[&"hush", "Another night, then. There is always another night."],
	[&"ysolde", "They're through. Ring it again, Wren."],
	[&"ysolde", "No... Keep moving. We grieve at the border. Not here."],
	[&"maelis", "Listen. The brook's talking again. It says thank you, roughly."],
	[&"maelis", "Their nest is ash. Malrik will need new hunters, and new excuses."],
	[&"hush", "The knife never misses, Ysolde. It only waits for the right neck."],
	[&"ysolde", "Then it can wait forever. Maelis, stay with the people."],
	[&"maelis", "Make way for the old herd!"],
	[&"narrator", "The last of them leave Larkrest. Behind them, the green road goes quiet."],
	[&"maelis", "Everything they have left is coming. Good. It means we're nearly there."],
	[&"ashby", "That's the lot, my lady. The border's yours whenever you want it. The queen said so."],
	[&"ysolde", "Thank her for me. And tell her I'm not staying."],
	[&"maelis", "The Sighing Wood, then? Burnt, frozen, and still ours."],
	[&"ysolde", "A seed doesn't wait for the war to end, Maelis. Neither do I."],
	[&"ysolde", "Keep... walking..."],
	[&"messenger", "We... we lost too many on the road. My lady, we can't... we can't go on."],
	[&"maelis", "Larkrest is burning. There's nothing left to walk away from."],
	[&"hush", "The slow ones at the back, my knives. Always the slow ones."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Lark Hill held. The ford did not. By morning the people under the golden tree have nothing left in the valley but their names, and the supply wagons burned in the night.",
	"West of Evenmead the old woods run all the way to the Fire border. Vessa's fort, Cinderwatch, has opened its gate. Between here and there is one road, and Malrik's hunters know it as well as Ysolde does.",
	"Walk them home, a lantern at a time. Somewhere in the trees, Mother Hush is counting.",
]
const BRIEFING_LINE := "The villagers stop when the enemy is near them. Clear the road ahead, and they walk on."
const HINT_START := "The people walk the road on their own and stop when the enemy is near. Clear the road ahead of them. Ring the Lantern to send a convoy early."
const HINT_SAGE := "Bramblesage: Snagroot pulls a hunter out of the trees. Pollen Haze silences archers across the brook."
const HINT_CITADEL := "Your Stronghold can become a Citadel: select the Heartwood and press X (300 crystals, 90 s). It opens the Briar Roc (C) and lets you call Maelis (V)."
const HINT_CALL := "Call Maelis: select the Heartwood and press V. She fights on her own; her card sets where (Escort / Vanguard / Hold home)."
const MSG_RING_REFUSED := "The road isn't clear of the last convoy yet"
const MSG_CONVOY := "Convoy {n} sets out"
const MSG_KNIVES := "Hush's knives at the brook crossing! They are going for the stragglers of convoy {n}"

## Read only.
var flag_override: Dictionary = {}       ## tests: stands in for the save's flags
var no_save_fallback := false
var folk_total := 40
var folk_needed := 30
var convoys: Array = []                  ## [{walkers: Array, state: &"waiting" / &"road" / &"done", left_at}]
var next_convoy := 0
var auto_times: Array = []
var arrived := 0
var lost := 0
var ring_progress := 0.0
var totems: Array = []                   ## the Rime Totems (freed some seconds after they fall)
var brook_thawed := false
var gloom_hall: Building
var frost_hall: Building
var hush: Unit = null
var maelis: Unit = null                  ## the 0:00 story Maelis, then the called helper
var ashby: Unit = null
var wren: Unit = null
var groups := {}
var waves_fired: Array[StringName] = []
var said: Array[String] = []
var victory_time := -1.0
var maelis_called := false
var knives_sent := 0                     ## knife squads sent (convoys 2 and 3 at the brook crossing)

var _said := {}
var _tick := 0.0
var _relief_left := -1.0
var _folk_type: UnitType
var _wren_type: UnitType
var _ashby_type: UnitType
var _guard_type: UnitType
var _fort_type: BuildingType
var _totem_type: BuildingType
var _cower := {}                         ## walker -> seconds before it walks on (-1 = cowering now)
var _gate_out: Array = []                ## [walker, seconds left] going through the gate
var _hush_back_left := -1.0
var _maelis_story_leaving := false
var _last_obj_text := ""


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
	define_objectives([[&"obj_convoys", "primary"], [&"obj_ysolde", "primary"], [&"sec_maelis", "secondary"],
			[&"sec_brook", "secondary"], [&"sec_hollow", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"shadow_knight", &"frost_mortar", &"hollow_oathsworn"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "Larkrest has fallen"
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {Unit.Team.PLAYER: 2}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.helper_call_price = MAELIS_PRICE.duplicate(true)
	c.start_level = 4
	c.start_spells = [&"thornburst"]
	c.start_spell_points = 3
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 150
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe people are across the border"
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"helper_maelis", "trigger": &"manual", "key_hint": "Heartwood: V",
			"card": "Maelis. The Wildcaller of the wood: roots, wolves, and an ambush that ambushes back."}
	return c


func _map_size() -> Vector2:
	return Vector2(MAP_W, MAP_D)


func _player_start() -> Vector3:
	return YSOLDE_START


func _use_map_dressing() -> bool:
	return false


func _lighting_preset() -> StringName:
	return &"warm"


func _title_line() -> String:
	return "Episode 4, Mission 2: %s" % MISSION_TITLE


func _ready() -> void:
	_folk_type = _story_type("thornling", &"meadow_folk", "Meadow folk", 45.0, WALK_SPEED, true)
	_wren_type = _story_type("wildwood_archer", &"wren", "Wren", 260.0, 5.2, true)
	_ashby_type = _story_type("flame_guard", &"captain_ashby", "Captain Ashby", 900.0, 4.5, false)
	var fg := UnitType.find("flame_guard")
	if fg:
		_guard_type = fg.duplicate() as UnitType
		_guard_type.commandable = false
		_guard_type.pop = 0
	_totem_type = _make_totem_type()
	_fort_type = _make_fort_type()
	register_local_unit_type(_folk_type)
	register_local_unit_type(_wren_type)
	register_local_unit_type(_ashby_type)
	register_local_building_type(_totem_type)
	register_local_building_type(_fort_type)
	super()
	if camera_rig:
		camera_rig.focus_on(YSOLDE_START)


func _story_type(base_id: String, id: StringName, display: String, hp: float, speed: float, harmless: bool) -> UnitType:
	var base := UnitType.find(base_id)
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.id = id
	t.display_name = display
	t.is_worker = false
	t.cost = 0
	t.pop = 0
	t.max_hp = hp
	t.move_speed = speed
	t.commandable = false
	t.kill_xp = 10
	t.support_kind = &""
	if harmless:
		t.attack_damage = 0.0
		t.aggro_range = 0.0
		t.armor = 0.0
	return t


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


## Cinderwatch (D8): the Fire keep's look as a plain fort building (no queue, not a keep), counts for nothing.
func _make_fort_type() -> BuildingType:
	var base := BuildingType.find("fire_keep")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.id = &"cinderwatch"
	t.display_name = "Cinderwatch"
	t.kind = &"fort"
	t.trains = []
	t.train_ids = []
	t.pop_bonus = 0
	t.attack_damage = 0.0
	t.counts_for_defeat = false
	return t


# ---------------------------------------------------------------- the map

func start_position(_team: int) -> Vector3:
	return YSOLDE_START


func base_center(team: int) -> Vector3:
	return HEARTWOOD if team == Unit.Team.PLAYER else DUSK_KEEP


func node_of(team: int, suffix: String) -> CrystalNode:
	var ids := {"a": &"e4m2_rest_a", "b": &"e4m2_rest_b", "x": &"e4m2_glen"} if team == Unit.Team.PLAYER \
			else {"a": &"e4m2_gallow_a", "b": &"e4m2_gallow_b"}
	var v: Variant = crystal_nodes.get(ids.get(suffix, &""))
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(team: int) -> Vector3:
	return Vector3(38.0, 0.0, -16.0) if team == Unit.Team.PLAYER else Vector3.INF


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


func _build_map() -> void:
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_grid.spawn_complete(BuildingType.find("nature_keep"), HEARTWOOD, Unit.Team.PLAYER) as Keep
	if keep:
		keep.destroyed.connect(func(_b: Building) -> void: say_l("L32"))   # E22 (the keep-lost rule ends it)
	build_grid.spawn_complete(BuildingType.find("nature_barracks"), GROVE_HALL, Unit.Team.PLAYER)
	for p in SEED_HOLLOWS:
		build_grid.spawn_complete(BuildingType.find("nature_hollow"), p, Unit.Team.PLAYER)
	shadow_keep = build_grid.spawn_complete(BuildingType.find("shadow_keep"), DUSK_KEEP, ENEMY) as Keep
	gloom_hall = build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL, ENEMY)
	build_grid.spawn_complete(BuildingType.find("shadow_tower"), NIGHT_SPIRE, ENEMY)
	build_grid.spawn_complete(BuildingType.find("shadow_hovel"), HOVEL, ENEMY)
	frost_hall = build_grid.spawn_complete(BuildingType.find("ice_barracks"), FROST_HALL, ENEMY)
	build_grid.spawn_complete(BuildingType.find("ice_tower"), RIME_SPIRE, ENEMY)
	var lodge := build_grid.spawn_complete(BuildingType.find("ice_lodge"), SNOW_LODGE, ENEMY) \
			if BuildingType.find("ice_lodge") else null
	for b: Variant in [shadow_keep, gloom_hall, frost_hall, lodge]:
		if b != null:
			mark_scripted(b as Node)
	if gloom_hall:
		gloom_hall.destroyed.connect(_on_gloom_hall_destroyed)
	if frost_hall:
		frost_hall.destroyed.connect(_on_frost_hall_destroyed)
	if _fort_type:
		var fort := build_grid.spawn_complete(_fort_type, CINDERWATCH, Unit.Team.PLAYER)
		if fort:
			mark_scripted(fort)
			set_truce([fort], true, Unit.TRUCE_ALL)
	for p in TOTEMS:
		var t := build_grid.spawn_complete(_totem_type, p, ENEMY)
		if t:
			mark_scripted(t)
			t.destroyed.connect(_on_totem_destroyed)
			totems.append(t)
	_add_props()


## Placeholder road / Lantern / landmarks / brook (E4M2.V1 replaces them); draw-only, never in sims or headless.
func _add_props() -> void:
	if _SIM.enabled or DisplayServer.get_name() == "headless":
		return
	var road := StandardMaterial3D.new()
	road.albedo_color = Color(0.55, 0.40, 0.22)
	for i in ROAD.size() - 1:
		var a: Vector3 = ROAD[i]
		var b: Vector3 = ROAD[i + 1]
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(5.0, 0.04, a.distance_to(b) + 2.0)
		seg.mesh = bm
		seg.material_override = road
		add_child(seg)
		seg.global_position = (a + b) * 0.5 + Vector3(0.0, 0.03, 0.0)
		seg.look_at(b + Vector3(0.0, 0.03, 0.0), Vector3.UP)
	var ice := StandardMaterial3D.new()
	ice.albedo_color = Color(0.85, 0.93, 1.0)
	for i in BROOK_LINE.size() - 1:
		var a: Vector3 = BROOK_LINE[i]
		var b: Vector3 = BROOK_LINE[i + 1]
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3.0, 0.05, a.distance_to(b) + 1.0)
		seg.mesh = bm
		seg.material_override = ice
		add_child(seg)
		seg.global_position = (a + b) * 0.5 + Vector3(0.0, 0.04, 0.0)
		seg.look_at(b + Vector3(0.0, 0.04, 0.0), Vector3.UP)
	var post := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.1
	pc.bottom_radius = 0.12
	pc.height = 3.0
	post.mesh = pc
	add_child(post)
	post.global_position = LANTERN + Vector3(0.0, 1.5, 0.0)
	var lamp := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.35
	lm.height = 0.6
	lamp.mesh = lm
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.4, 0.95, 0.5)
	glass.emission_enabled = true
	glass.emission = Color(0.3, 0.9, 0.4)
	lamp.material_override = glass
	add_child(lamp)
	lamp.global_position = LANTERN + Vector3(0.0, 3.1, 0.0)
	for spot: Array in [[HOLLOW_OAK, Color(0.38, 0.28, 0.17), 2.0, 7.0], [CROWSTONE, Color(0.55, 0.55, 0.52), 1.5, 4.0]]:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = float(spot[2]) * 0.6
		cm.bottom_radius = float(spot[2])
		cm.height = float(spot[3])
		mi.mesh = cm
		var mm := StandardMaterial3D.new()
		mm.albedo_color = spot[1]
		mi.material_override = mm
		add_child(mi)
		mi.global_position = (spot[0] as Vector3) + Vector3(0.0, float(spot[3]) * 0.5, 0.0)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for p: Vector3 in ROAD + [LANTERN_GREEN, HOLLOW_OAK, BROOK_ICE, CROWSTONE, CINDERWATCH]:
		fog.reveal(Unit.Team.PLAYER, p, 9.0)
	_read_save()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, YSOLDE_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	set_meta(&"campaign_flags", _flags().duplicate())
	_carry_essence()
	for i in 6:
		var w := _spawn(make_unit("sprigling"), Unit.Team.PLAYER, HEARTWOOD + Vector3(-4.0 + i * 1.5, 0.0, 6.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 3 else "b"))
	var rows := [["thornling", 6 + (2 if diff == 0 else 0)], ["burr_slinger", 4], ["bloomtender", 2], ["vinelasher", 2],
			["greenheart_oathkeeper", 0 if diff == 2 else 1], ["bramblesage", 1]]
	var k := 0
	for row: Array in rows:
		for j in int(row[1]):
			var u := _spawn(make_unit(String(row[0])), Unit.Team.PLAYER, ARMY_POS + Vector3((k % 6) * 1.6 - 4.0, 0.0, (k / 6) * 1.7))
			var ca := u.get_node_or_null(^"CasterAbility")
			if ca and &"mana" in ca and ca.has_method(&"max_mana"):
				ca.set(&"mana", ca.call(&"max_mana"))
			k += 1
	# --- story units: Maelis at the Lantern (leaves at E2), Wren at the green, Ashby and the gate guard.
	var ht := HelperType.find(&"helper_maelis")
	if ht:
		var hp := Helper.new()
		hp.apply_helper_type(ht, 4)
		hp.name = "MaelisStory"
		_spawn(hp, Unit.Team.PLAYER, LANTERN + Vector3(-2.0, 0.0, 1.0))
		hp.set_stance(&"home")
		mark_scripted(hp)
		set_truce([hp], true, Unit.TRUCE_ALL)
		maelis = hp
	if _wren_type:
		wren = _spawn(Worker.make_unit(_wren_type), Unit.Team.PLAYER, LANTERN_GREEN + Vector3(-3.0, 0.0, -3.0))
		mark_scripted(wren)
		_immortal(wren)
	if _ashby_type:
		ashby = _spawn(Worker.make_unit(_ashby_type), Unit.Team.PLAYER, ASHBY_SPOT)
		ashby.set_meta(META_HOME, ASHBY_SPOT)
		mark_scripted(ashby)
		_immortal(ashby)
		_guards.append(ashby)
	if _guard_type:
		for i in 6:
			var a := TAU * float(i) / 6.0
			var g := _spawn(Worker.make_unit(_guard_type), Unit.Team.PLAYER, ASHBY_SPOT + Vector3(cos(a) * 3.0, 0.0, sin(a) * 3.0))
			mark_scripted(g)
			g.set_meta(META_HOME, g.global_position)
			_guards.append(g)
	# --- the people at the Lantern Green, in 4 convoys.
	_make_convoys()
	# --- the enemy: the hunters' rally guard, A1-A3, Hush.
	spawn_group([["shade", 4], ["nightbolt", 2]], HUNTER_RALLY, 2.5, ENEMY, true)
	for gid: StringName in GROUPS:
		var units := spawn_group(GROUPS[gid][1], GROUPS[gid][0], 3.0, ENEMY, true)
		groups[gid] = units
		if gid != &"A2":
			for u in units:
				set_dormant(u as Unit, true)
				(u as Unit).visible = false
	if UnitType.find("mother_hush"):
		hush = _spawn(make_unit("mother_hush"), ENEMY, A3_AT + Vector3(1.5, 0.0, 0.0))
		mark_scripted(hush)
		hush.set_meta(META_HOME, A3_AT)
		hush.death_guard = func(_a: Variant) -> bool:
			_hush_flee()
			return true
		set_dormant(hush, true)
		hush.visible = false
		(groups[&"A3"] as Array).append(hush)
	var roster := HelperRoster.for_team(Unit.Team.PLAYER)
	if roster:
		roster.helper_ready.connect(_on_maelis_ready)
	_add_events()
	begin_mission([&"obj_convoys", &"obj_ysolde", &"sec_hollow"])


static func _immortal(u: Unit) -> void:
	u.death_guard = func(_a: Variant) -> bool:
		u.hp = u.max_hp
		return true


func _flags() -> Dictionary:
	if not flag_override.is_empty():
		return flag_override
	return CampaignState.open(campaign_save_path).flags


func _read_save() -> void:
	var cs := CampaignState.open(campaign_save_path)
	no_save_fallback = not cs.is_completed(&"e4m1") and flag_override.is_empty()
	var f := _flags()
	var saved := 30 if no_save_fallback else int(f.get("e4m1_folk_saved", 30))
	folk_total = maxi(30, 40 - (30 - saved))
	folk_needed = int(ceil(folk_total * float(by_difficulty(NEEDED_PCT)) - 0.001))
	auto_times = (by_difficulty(AUTO_TIMES) as Array).duplicate()


## Ysolde's essence (her track, CampaignState.YSOLDE_ESSENCE_FLAG); the no-save fallback: 150 + 500.
func _carry_essence() -> void:
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	if bank == null:
		return
	bank.add(NO_SAVE_ESSENCE if no_save_fallback else int(_flags().get(CampaignState.YSOLDE_ESSENCE_FLAG, 0)))


func _make_convoys() -> void:
	var per := int(ceil(folk_total / float(CONVOYS)))
	var left := folk_total
	for c in CONVOYS:
		var n := per if c < CONVOYS - 1 else left
		left -= n
		var walkers: Array = []
		var centre := LANTERN_GREEN + Vector3(-4.0 + 3.0 * (c % 2), 0.0, -3.0 + 4.0 * (c / 2))
		for i in n:
			var a := TAU * float(i) / maxf(1.0, float(n))
			var f := _spawn(Worker.make_unit(_folk_type), Unit.Team.PLAYER, centre + Vector3(cos(a) * 1.8, 0.0, sin(a) * 1.8))
			_arm_walker(f)
			f.set_meta(&"convoy", c)
			f.set_meta(&"wp", 0)
			walkers.append(f)
		convoys.append({"walkers": walkers, "state": &"waiting", "left_at": -1.0})


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_convoys", false), objective_text(&"obj_ysolde", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_ysolde")),
	}


func on_road() -> int:
	var n := 0
	for c: Dictionary in convoys:
		if c["state"] == &"road":
			for w: Variant in c["walkers"]:
				if is_instance_valid(w) and (w as Unit).is_alive() and not (w as Unit).has_meta(&"arrived"):
					n += 1
	return n


func next_auto_time() -> float:
	return float(auto_times[next_convoy]) if next_convoy < auto_times.size() else -1.0


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_convoys":
			if with_counter:
				return "Walk the people to Cinderwatch (%d / %d · at least %d)" % [arrived, folk_total, folk_needed]
			return "Walk the people to Cinderwatch"
		&"obj_ysolde":
			return "Ysolde must survive"
		&"sec_maelis":
			return "Raise a Citadel and call Maelis"
		&"sec_brook":
			if with_counter:
				return "Thaw the Frozen Brook (%d / 2)" % (2 - _totems_alive())
			return "Thaw the Frozen Brook"
		&"sec_hollow":
			return "Burn the hunters' Gloom Hall"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_convoys":
			var detail := ""
			var t := next_auto_time()
			if t >= 0.0:
				var s := maxi(0, int(t))
				detail = Loc.t("Next convoy at {time} (ring the Lantern to send it now)",
						{"time": "%d:%02d" % [s / 60, s % 60]})
			return {"counter": arrived, "goal": folk_needed, "position": GATE,
					"detail": "%s · %s" % [Loc.t("{arrived} arrived · {lost} lost · {road} on the road",
							{"arrived": arrived, "lost": lost, "road": on_road()}), detail]}
		&"sec_brook":
			return {"counter": 2 - _totems_alive(), "goal": 2, "position": BROOK_ICE}
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
	play_cutscene(&"e4m2_lantern", func() -> void:
		say_l("L1")
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position))
	for id in ["L2", "L3", "L4"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 12.0)


func _add_events() -> void:
	after(20.0, _maelis_leaves)
	after(45.0, func() -> void:
		if fire_once(&"E3") and hud and not is_ending():
			hud.show_message(HINT_SAGE, 10.0))
	after(CITADEL_HINT_AT, func() -> void:
		if not is_ending() and hud and keep and keep.tier < 3:
			hud.show_message(HINT_CITADEL, 12.0))
	after(H1_AT, _fire_wave.bind(&"H1"))
	after(B1_AT, _fire_wave.bind(&"B1"))
	after(H2_AT, _fire_wave.bind(&"H2"))
	after(H3_AT, _fire_wave.bind(&"H3"))
	_relief_left = 0.0   # C4-8: the first brook relief at RELIEF_FROM (5:00), then every RELIEF_EVERY
	add_event(&"E4", func() -> bool: return fog != null and fog.is_explored(Unit.Team.PLAYER, BROOK_ICE + Vector3(0.0, 0.0, -6.0)) \
			and hero_alive() and _flat(hero.global_position, BROOK_ICE) < 30.0,
			func() -> void:
				say_l("L7")
				set_objective(&"sec_brook", "active"))
	add_event(&"E8", func() -> bool: return keep != null and is_instance_valid(keep) and keep.tier >= 3,
			func() -> void:
				say_l("L13")
				if hud:
					hud.show_message(HINT_CALL, 10.0)
				show_spotlight())


## E2: Maelis runs ahead (untargetable) and leaves the map at the south edge; sec_maelis appears.
func _maelis_leaves() -> void:
	if is_ending():
		return
	fire_once(&"E2")
	say_l("L5")
	say_l("L6")
	set_objective(&"sec_maelis", "active")
	if maelis and is_instance_valid(maelis):
		_maelis_story_leaving = true
		maelis.command_move(MAELIS_EXIT)


func _on_maelis_ready(helper: Helper) -> void:
	if is_ending() or maelis_called:
		return
	maelis_called = true
	maelis = helper
	fire_once(&"E9")
	say_l("L14")
	set_objective(&"sec_maelis", "done")
	_hook_maelis_abilities(helper)


func _hook_maelis_abilities(helper: Unit) -> void:
	for c in helper.get_children():
		if c.has_signal(&"ability_cast") and not c.is_connected(&"ability_cast", _on_maelis_ability):
			c.connect(&"ability_cast", _on_maelis_ability)


func _on_maelis_ability(id: StringName) -> void:
	if String(id).contains("stampede") and fire_once(&"E16"):
		say_l("L23")


## A walker's group, scripted mark and died hook (idempotent: the convoys and a load run it).
func _arm_walker(f: Unit) -> void:
	f.add_to_group(&"meadow_folk")
	mark_scripted(f)
	if not f.died.is_connected(_on_walker_died):
		f.died.connect(_on_walker_died)


# ---------------------------------------------------------------- save / load (mission-save-hardening C4-3, C4-8)

func save_spawned(u: Unit, row: Dictionary) -> void:
	super(u, row)
	if _folk_type and String(row.get("type", "")) == String(_folk_type.id):
		_arm_walker(u)


## Walkers' hooks, the called Maelis' line hook; sleeping ambushes / a fled Hush stay hidden, woken ones are seen.
func _after_load(_nodes: Dictionary) -> void:
	for c: Dictionary in convoys:
		for w: Variant in c.get("walkers", []):
			if is_instance_valid(w) and w is Unit:
				_arm_walker(w as Unit)
	if maelis_called and maelis and is_instance_valid(maelis):
		_hook_maelis_abilities(maelis)
	for gid: Variant in groups:
		for v: Variant in groups[gid]:
			if is_instance_valid(v) and v is Unit:
				(v as Unit).visible = not is_dormant(v as Unit)
	if hush and is_instance_valid(hush):
		hush.visible = not is_dormant(hush)


func _fire_wave(id: StringName) -> void:
	if is_ending() or waves_fired.has(id):
		return
	waves_fired.append(id)
	var shadow_cut := func(n: int) -> int: return n - int(floor(n * HOLLOW_CUT)) if objective_state("sec_hollow") == "done" else n
	var ice_cut := func(n: int) -> int: return n - int(floor(n * HOLLOW_CUT)) if not _alive(frost_hall) else n
	match id:
		&"H1":
			for u in spawn_wave_at(WAVES[&"H1"], _shadow_spawn(), ENEMY, shadow_cut):
				order_wave(u as Unit, &"walkers", LANTERN_GREEN)
		&"B1":
			for u in spawn_wave_at(WAVES[&"B1"], _ice_spawn(), ENEMY, ice_cut):
				order_wave(u as Unit, &"base", GROVE_HALL)
		&"H2":
			for u in spawn_wave_at(WAVES[&"H2"], _shadow_spawn(), ENEMY, shadow_cut):
				order_wave(u as Unit, &"walkers_hero", LANTERN_GREEN)
		&"H3":
			fire_once(&"E14")
			say_l("L21")
			say_l("L22")
			var units := spawn_wave_at(WAVES[&"H3"], _shadow_spawn(), ENEMY, shadow_cut)
			_bring_hush(_shadow_spawn())
			if hush and not is_dormant(hush):
				units.append(hush)
			for u in units:
				order_wave(u as Unit, &"walkers_hero", LANTERN_GREEN)
		&"H4":
			fire_once(&"E18")
			say_l("L25")
			var su := spawn_wave_at(WAVES[&"H4_S"].filter(func(r: Array) -> bool:
					return not (r[0] == "shadow_knight" and objective_state("sec_hollow") == "done")), _shadow_spawn(), ENEMY, shadow_cut)
			_bring_hush(_shadow_spawn())
			if hush and not is_dormant(hush):
				su.append(hush)
			for u in su:
				order_wave(u as Unit, &"convoy4", ROAD[4])
			var iu := spawn_wave_at(WAVES[&"H4_I"].filter(func(r: Array) -> bool:
					return not (r[0] == "frost_mortar" and not _alive(frost_hall))), _ice_spawn(), ENEMY, ice_cut)
			for u in iu:
				order_wave(u as Unit, &"convoy4", ROAD[6])
		&"RELIEF":
			for u in spawn_wave_at(WAVES[&"RELIEF"], _ice_spawn(), ENEMY):
				order_wave(u as Unit, &"crossing", BROOK_ICE + Vector3(0.0, 0.0, -5.0))


func _alive(b: Variant) -> bool:
	return b != null and is_instance_valid(b) and (b as Building).is_alive()


func _shadow_spawn() -> Vector3:
	if _alive(gloom_hall) and gloom_hall is TrainingBuilding:
		return (gloom_hall as TrainingBuilding).spawn_point()
	if _alive(shadow_keep):
		return shadow_keep.spawn_point()
	return Vector3(0.0, 0.0, -47.0)


func _ice_spawn() -> Vector3:
	if _alive(frost_hall) and frost_hall is TrainingBuilding:
		return (frost_hall as TrainingBuilding).spawn_point()
	return Vector3(-40.0, 0.0, -47.0)


# ---------------------------------------------------------------- Hush

func _bring_hush(at: Vector3) -> void:
	if hush == null or not is_instance_valid(hush) or _hush_back_left > 0.0:
		return
	if is_dormant(hush):
		set_dormant(hush, false)
	hush.visible = true
	hush.hp = hush.max_hp
	hush.global_position = at + Vector3(1.5, 0.0, 1.0)


func _hush_flee() -> void:
	if hush == null or is_dormant(hush):
		return
	hush.hp = hush.max_hp
	set_dormant(hush, true)
	hush.visible = false
	_wave_units.erase(hush)
	_guards.erase(hush)
	hush.global_position = DUSK_KEEP + Vector3(4.0, 0.0, 6.0)
	_hush_back_left = float(by_difficulty(HUSH_BACK))
	if fire_once(&"E15"):
		say_l("L16")


func _tick_hush(dt: float) -> void:
	if hush == null or not is_instance_valid(hush):
		return
	if not is_dormant(hush) and hush.hp < hush.max_hp * float(by_difficulty(HUSH_FLEE)):
		_hush_flee()
	if _hush_back_left > 0.0:
		_hush_back_left -= dt   # back at the Dusk Keep: the next wave that carries her brings her


# ---------------------------------------------------------------- targets

func _road_walkers() -> Array[Unit]:
	var out: Array[Unit] = []
	for c: Dictionary in convoys:
		if c["state"] != &"road":
			continue
		for w: Variant in c["walkers"]:
			if is_instance_valid(w) and (w as Unit).is_alive() and not (w as Unit).has_meta(&"arrived"):
				out.append(w as Unit)
	return out


func _nearest_walker(from: Vector3, convoy := -1) -> Unit:
	var best: Unit = null
	var d := INF
	for u in _road_walkers():
		if convoy >= 0 and int(u.get_meta(&"convoy", -1)) != convoy:
			continue
		var dd := _flat(u.global_position, from)
		if dd < d:
			d = dd
			best = u
	return best


func _push(u: Unit, at: Vector3, near := 4.0) -> void:
	if u.attack_target == null and _flat(u.global_position, at) > near and not u.is_attack_moving():
		u.command_attack_move(at)


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	match mode:
		&"walkers", &"walkers_hero", &"convoy4":
			var w := _nearest_walker(u.global_position, 3 if mode == &"convoy4" else -1)
			if w == null and mode == &"convoy4":
				w = _nearest_walker(u.global_position)
			if w != null:
				if u.attack_target == null or not u.attack_target is Unit:
					u.command_attack_move(w.global_position)
			elif mode == &"walkers_hero" and hero_alive():
				_push(u, hero.global_position, 3.0)
			else:
				_push(u, u.get_meta(META_TARGET, LANTERN_GREEN))
			return true
		&"base":
			var to := GROVE_HALL
			var gh := Building.for_team(Unit.Team.PLAYER).filter(func(b: Building) -> bool:
					return b.is_alive() and b.building_type and b.building_type.id == &"nature_barracks")
			if gh.is_empty():
				to = HEARTWOOD
			_push(u, to, 5.0)
			return true
		&"crossing":
			_push(u, u.get_meta(META_TARGET, BROOK_ICE), 4.0)
			return true
		&"knives":
			var tail := _tail_walker(int(u.get_meta(&"_knife_convoy", -1)))
			if tail == null:
				u.set_meta(META_MODE, &"walkers_hero")
			elif u.attack_target != tail:
				u.command_attack(tail)
			return true
		&"withdraw":
			return true
	return false


# ---------------------------------------------------------------- convoys

## Rings the Lantern (Ysolde within 3 m for 3 s): the next convoy leaves now; refused while the last one walks or
## less than 3:00 after it left. "" = sent.
func ring() -> String:
	if next_convoy >= CONVOYS:
		return MSG_RING_REFUSED
	if next_convoy > 0:
		var prev: Dictionary = convoys[next_convoy - 1]
		if prev["state"] == &"road" or mission_time() - float(prev["left_at"]) < RING_GAP:
			return MSG_RING_REFUSED
	var saved := float(auto_times[next_convoy]) - mission_time()
	if saved > 0.0:
		for i in range(next_convoy + 1, auto_times.size()):
			auto_times[i] = float(auto_times[i]) - saved
	_depart()
	return ""


func _depart() -> void:
	if next_convoy >= CONVOYS or is_ending():
		return
	var c: Dictionary = convoys[next_convoy]
	c["state"] = &"road"
	c["left_at"] = mission_time()
	fire_once(&"E5")
	if next_convoy == 0:
		say_l("L8")
	if next_convoy == CONVOYS - 1:
		fire_once(&"E17")
		say_l("L24")
		_fire_wave(&"H4")
	if hud:
		hud.show_message(Loc.t(MSG_CONVOY, {"n": next_convoy + 1}), 3.0)
	for w: Variant in c["walkers"]:
		if is_instance_valid(w) and (w as Unit).is_alive():
			(w as Unit).set_meta(&"wp", 1)
			(w as Unit).command_move(ROAD[1] + _jitter(w as Unit))
	next_convoy += 1


## A walker's place in its convoy's list (deterministic, survives a load: `convoys` is saved). -1 = not a walker.
func walker_index(u: Unit) -> int:
	var c := int(u.get_meta(&"convoy", -1))
	if c < 0 or c >= convoys.size():
		return -1
	return (convoys[c]["walkers"] as Array).find(u)


func _jitter(u: Unit) -> Vector3:
	var i := float(maxi(0, walker_index(u)) % 7) - 3.0
	return Vector3(i * 0.35, 0.0, i * 0.25)


func _tick_lantern(dt: float) -> void:
	if next_convoy < CONVOYS and mission_time() >= float(auto_times[next_convoy]):
		var prev_ok: bool = next_convoy == 0 or (convoys[next_convoy - 1] as Dictionary)["state"] != &"waiting"
		if prev_ok:
			_depart()
	if not hero_alive() or _flat(hero.global_position, LANTERN) > LANTERN_R:
		ring_progress = 0.0
		return
	ring_progress += dt / RING_TIME
	if ring_progress >= 1.0:
		ring_progress = 0.0
		var why := ring()
		if why != "" and hud:
			hud.show_message(why, 3.0)


func _tick_walkers(dt: float) -> void:
	var cower_r := float(by_difficulty(COWER_R))
	var foes: Array[Vector3] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var e := n as Unit
		if e and e.is_alive() and int(e.team) == ENEMY and not is_dormant(e):
			foes.append(e.global_position)
	for c: Dictionary in convoys:
		if c["state"] != &"road":
			continue
		var still := 0
		for v: Variant in c["walkers"]:
			if not is_instance_valid(v) or not (v as Unit).is_alive() or (v as Unit).has_meta(&"arrived"):
				continue
			still += 1
			var w := v as Unit
			if _flat(w.global_position, GATE) <= GATE_R:
				_arrive(w)
				continue
			var near := false
			for p in foes:
				if _flat(p, w.global_position) <= cower_r:
					near = true
					break
			if near:
				if float(_cower.get(w, 0.0)) >= 0.0:
					w.command_stop()
				_cower[w] = -1.0
				continue
			if _cower.has(w):
				var left := float(_cower[w])
				left = COWER_RESUME if left < 0.0 else left - dt
				if left > 0.0:
					_cower[w] = left
					continue
				_cower.erase(w)
				w.command_move(ROAD[int(w.get_meta(&"wp", 1))] + _jitter(w))
			var wp := int(w.get_meta(&"wp", 1))
			if _flat(w.global_position, ROAD[wp]) < 2.5 and wp < ROAD.size() - 1:
				wp += 1
				w.set_meta(&"wp", wp)
				w.command_move(ROAD[wp] + _jitter(w))
			elif not w.has_move_order():
				w.command_move(ROAD[wp] + _jitter(w))
		if still == 0:
			c["state"] = &"done"
	var keep_out: Array = []
	for row: Array in _gate_out:
		row[1] = float(row[1]) - dt
		if float(row[1]) <= 0.0:
			if is_instance_valid(row[0]):
				(row[0] as Node).queue_free()
		else:
			keep_out.append(row)
	_gate_out = keep_out
	_check_convoys()


## Hush's knives (review fix): convoy `c`'s lead walker past ROAD[4] (the brook crossing) springs a squad that hunts
## that convoy's tail.
func _tick_knives() -> void:
	for c: int in KNIFE_CONVOYS:
		if c >= convoys.size() or has_fired(StringName("knives_%d" % c)):
			continue
		var conv: Dictionary = convoys[c]
		if conv["state"] != &"road":
			continue
		var lead := 0
		for v: Variant in conv["walkers"]:
			if is_instance_valid(v) and (v as Unit).is_alive():
				lead = maxi(lead, int((v as Unit).get_meta(&"wp", 0)))
		if lead >= KNIFE_WP:
			send_knives(c)


## Sends the knife squad on convoy `c` (tests call it). Returns the squad.
func send_knives(c: int) -> Array:
	if is_ending() or not fire_once(StringName("knives_%d" % c)):
		return []
	knives_sent += 1
	var cut := func(n: int) -> int: return n - int(floor(n * HOLLOW_CUT)) if objective_state("sec_hollow") == "done" else n
	var units := spawn_wave_at(WAVES[&"KNIVES"], KNIFE_FROM, ENEMY, cut)
	for u in units:
		(u as Unit).set_meta(&"_knife_convoy", c)   # transient: after a load the knives go back to walkers_hero
		order_wave(u as Unit, &"knives", BROOK_ICE)
	flash_ring(BROOK_ICE, BROOK_ICE_R)
	if hud:
		hud.show_message(Loc.t(MSG_KNIVES, {"n": c + 1}), 5.0)
	if c == KNIFE_CONVOYS[0]:
		say_l("L33")
	return units


## The walker of convoy `c` furthest back on the road (lowest waypoint, then furthest from it); null = none.
func _tail_walker(c: int) -> Unit:
	var best: Unit = null
	var best_wp := 1 << 20
	var best_d := -1.0
	for u in _road_walkers():
		if int(u.get_meta(&"convoy", -1)) != c:
			continue
		var wp := int(u.get_meta(&"wp", 1))
		var d := _flat(u.global_position, ROAD[wp])
		if wp < best_wp or (wp == best_wp and d > best_d):
			best = u
			best_wp = wp
			best_d = d
	return best


## A walker inside the gate zone: safe (truce, invulnerable), counted, gone through the gate 2 s later.
func _arrive(w: Unit) -> void:
	w.set_meta(&"arrived", true)
	set_truce([w], true, Unit.TRUCE_ALL)
	_immortal(w)
	arrived += 1
	_gate_out.append([w, 2.0])
	if fire_once(&"E10"):
		say_l("L15")
		say_l("L17")


func _on_walker_died(u: Unit) -> void:
	if is_ending() or u.has_meta(&"arrived"):
		return
	lost += 1
	if fire_once(&"E11"):
		say_l("L18")
	_check_convoys()


func _check_convoys() -> void:
	if objective_state("obj_convoys") != "active" or is_ending():
		return
	if lost > folk_total - folk_needed:
		fire_once(&"E21")
		say_l("L31")
		set_objective(&"obj_convoys", "failed")
		lose(DEFEAT_DELAY)
		return
	for c: Dictionary in convoys:
		if c["state"] != &"done":
			return
	if arrived >= folk_needed:
		_convoys_done()


## E19: every convoy resolved with enough people through the gate: Withdraw, e4m2_border, victory.
func _convoys_done() -> void:
	fire_once(&"E19")
	victory_time = mission_time()
	set_objective(&"obj_convoys", "done")
	for id: StringName in [&"sec_maelis", &"sec_brook", &"sec_hollow"]:
		if objective_state(String(id)) == "active":
			set_objective(id, "failed")
	_record_flags()
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ENEMY:
			set_truce([u], true, Unit.TRUCE_ALL)
			u.set_meta(META_MODE, &"withdraw")
			u.command_move(DUSK_KEEP + Vector3(randf_range(-5.0, 5.0), 0.0, 8.0))
	play_cutscene(&"e4m2_border", func() -> void:
		for id in ["L26", "L27", "L28", "L29"]:
			say_l(id)
		set_objective(&"obj_ysolde", "done")
		win(VICTORY_DELAY))


func _record_flags() -> void:
	set_mission_flag("e4m2_folk_arrived", arrived)
	set_mission_flag("e4m2_volunteers", arrived >= folk_needed + 5)   # e4m3: 4 veteran Thornling volunteers
	set_mission_flag("e4m2_time", int(victory_time))
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	var essence := bank.essence if bank else 0
	if objective_state("sec_brook") == "done":
		essence += 300
	if objective_state("sec_hollow") == "done":
		essence += 200
	essence += mini(100, 10 * maxi(0, arrived - folk_needed))
	set_mission_flag(CampaignState.YSOLDE_ESSENCE_FLAG, mini(ESSENCE_CAP, essence / 2))


# ---------------------------------------------------------------- ambushes, the brook, the camps

func _tick_ambushes() -> void:
	for gid: StringName in [&"A1", &"A3"]:
		if has_fired(StringName("woke_%s" % gid)):
			continue
		var at: Vector3 = GROUPS[gid][0]
		var trigger := hero_alive() and _flat(hero.global_position, at) <= AMBUSH_R
		if not trigger:
			trigger = _nearest_walker(at) != null and _flat(_nearest_walker(at).global_position, at) <= AMBUSH_R
		if trigger:
			_wake_group(gid)


func _wake_group(gid: StringName) -> void:
	if not fire_once(StringName("woke_%s" % gid)):
		return
	for v: Variant in groups[gid]:
		if is_instance_valid(v) and (v as Unit).is_alive():
			set_dormant(v as Unit, false)
			(v as Unit).visible = true
			order_wave(v as Unit, &"walkers_hero", GROUPS[gid][0])
	if gid == &"A1":
		fire_once(&"E6")
		say_l("L10")
	else:
		fire_once(&"E7")
		play_cutscene(&"e4m2_hush", func() -> void:
			say_l("L11")
			say_l("L12"))


func _totems_alive() -> int:
	return totems.filter(func(t: Variant) -> bool: return is_instance_valid(t) and (t as Building).is_alive()).size()


func _on_totem_destroyed(_b: Building) -> void:
	if is_ending() or _totems_alive() > 0 or brook_thawed:
		return
	brook_thawed = true
	fire_once(&"E12")
	say_l("L19")
	if objective_state("sec_brook") != "done":
		set_objective(&"sec_brook", "done")
	for n in get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).has_meta(&"on_ice"):
			(n as Unit).remove_modifier(&"terrain:ice")
			(n as Unit).remove_meta(&"on_ice")


## The crossing's ice (-30 % speed on every unit inside) while a Rime Totem stands.
func _tick_ice() -> void:
	if brook_thawed:
		return
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive():
			continue
		var inside := _flat(u.global_position, BROOK_ICE) <= BROOK_ICE_R
		if inside and not u.has_meta(&"on_ice"):
			u.set_meta(&"on_ice", true)
			u.add_modifier(&"terrain:ice", {"move_speed_pct": -0.30})
		elif not inside and u.has_meta(&"on_ice"):
			u.remove_meta(&"on_ice")
			u.remove_modifier(&"terrain:ice")


func _on_gloom_hall_destroyed(_b: Building) -> void:
	if is_ending():
		return
	fire_once(&"E13")
	say_l("L20")
	set_objective(&"sec_hollow", "done")


func _on_frost_hall_destroyed(_b: Building) -> void:
	_relief_left = -1.0


func _on_player_hero_fell() -> void:
	fire_once(&"E20")
	say_l("L30")
	set_objective(&"obj_ysolde", "failed")
	super()


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_hush(delta)
	_tick_lantern(delta)
	if _relief_left >= 0.0 and mission_time() >= RELIEF_FROM:
		_relief_left -= delta
		if _relief_left <= 0.0:
			_relief_left = RELIEF_EVERY
			if _alive(frost_hall):
				waves_fired.erase(&"RELIEF")
				_fire_wave(&"RELIEF")
	if _maelis_story_leaving and maelis and is_instance_valid(maelis) and _flat(maelis.global_position, MAELIS_EXIT) < 4.0:
		_maelis_story_leaving = false
		maelis.queue_free()
		maelis = null
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_walkers(0.5)
		_tick_knives()
		_tick_ambushes()
		_tick_ice()
		var t := "%s|%s|%s" % [objective_text(&"obj_convoys"), on_road(), next_convoy]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
