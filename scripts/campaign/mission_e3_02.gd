class_name MissionE3_02
extends MissionBase
## Episode 3, mission 2 "Another Night" (docs/design/mission-e3-02.md): the mirror of M0. Phase 1 "The Night": the
## player is Mother Hush with a 9-unit squad in the Fire-Nature camp behind Lark Hill; spoil four supply wagons before
## dawn. The dark is Shadow's: squad units outside fire-light are concealed; enemies who see one raise an alarm after a
## 3 s fuse; 3 alarms wake Vessa. Watch-fires can be snuffed. Old Vey keeps an invulnerable vigil by the golden tree.
## Phase 2 "First Light": Malrik on the ridge, the Dusk Keep a Citadel, Mother Hush callable (V, free); hold 2:30
## against Vessa's reprisal. Spotlight: Mother Hush.
##
## Built deviations (2026-10-07, recorded in the spec's "Built" note) - the playable core:
## - The Evenmead map of e3m1 in code (river, fords, bases, the tree); the night layer at the spec's positions with
##   placeholder looks (fire rings, wagon boxes, tents); flat ground; no sight scale (FogOfWar.sight_scale is not built):
##   concealment is mission-side (`Unit.hide_from_auto_target` + the spotting rule below).
## - Hush in phase 1 is a plain Wizard set up as Hush (900 HP, 34 damage, the helper_hush model, no spells); her three
##   abilities are mission-side (buttons + F / Q / E caught by the mission): Blink Strike (nearest enemy within 14 m),
##   Smoke Cloak, Night of Knives; the veil = 4 s without attacking or being hit.
## - Villager tents and wagons are under a full truce (nothing can hit them: sec_villagers cannot fail, a wagon is spoiled
##   by sabotage only, never destroyed);
##   army-tent sleepers are dormant units; posts and patrols are mission-driven guards; Vey's vigil = an invulnerable
##   Ruin Warden stand-in in Vey's colours (no Helper brain), detection = instant alarm + an 80 hit.
## - No cine timelines (fallback end states); the e3m2_embers end state is applied at once.

const MISSION_ID := &"e3m2"
const MISSION_TITLE := "Another Night"
const PLAYER_SEAT := Unit.Team.PLAYER
const ALLY_SEAT := Unit.Team.ALLY
const NATURE_SEAT := Unit.Team.ENEMY
const FIRE_SEAT := Unit.Team.ENEMY_2

const SQUAD_START := Vector3(2.0, 0.0, 19.0)
const MALRIK_CREST := Vector3(0.0, 0.0, -36.0)
const MALRIK_DAWN := Vector3(-6.0, 0.0, -40.0)
const SHADOW_RALLY := Vector3(-4.0, 0.0, -28.0)
const DUSK_KEEP := Vector3(-12.0, 0.0, -48.0)
const GLOOM_HALL := Vector3(1.0, 0.0, -48.0)
const HOVELS: Array[Vector3] = [Vector3(-14.0, 0.0, -38.0), Vector3(-24.0, 0.0, -52.0)]
const RIME_KEEP := Vector3(28.0, 0.0, -48.0)
const RIME_HALL := Vector3(16.0, 0.0, -45.0)
const ICE_RALLY := Vector3(35.0, 0.0, -28.0)
const TORVALD_FLANK := Vector3(4.0, 0.0, -6.0)
const HEARTWOOD := Vector3(-32.0, 0.0, 48.0)
const GROVE_HALL := Vector3(-44.0, 0.0, 40.0)
const FIRE_KEEP := Vector3(20.0, 0.0, 50.0)
const EMBER_HALL := Vector3(34.0, 0.0, 40.0)
const CREST_SPIRES: Array = [[NATURE_SEAT, Vector3(-24.0, 0.0, 32.0)], [NATURE_SEAT, Vector3(-10.0, 0.0, 30.0)],
		[FIRE_SEAT, Vector3(6.0, 0.0, 31.0)], [FIRE_SEAT, Vector3(20.0, 0.0, 34.0)]]
const NODES := [[&"e3_dusk_a", Vector3(-21.0, 0.0, -45.0), 1500], [&"e3_dusk_b", Vector3(-6.0, 0.0, -56.0), 1500],
		[&"e3_rime_a", Vector3(37.0, 0.0, -46.0), 1500], [&"e3_rime_b", Vector3(27.0, 0.0, -57.0), 1500]]
const WAGONS := {&"WG1": ["Grain", Vector3(-52.0, 0.0, 46.0), NATURE_SEAT], &"WG2": ["Arrows", Vector3(-12.0, 0.0, 56.0), FIRE_SEAT],
		&"WG3": ["Lamp oil", Vector3(36.0, 0.0, 56.0), FIRE_SEAT], &"WG4": ["Fodder", Vector3(46.0, 0.0, 24.0), FIRE_SEAT]}
const FIRES: Array[Vector3] = [Vector3(-18, 0, 30), Vector3(0, 0, 30), Vector3(14, 0, 33), Vector3(-40, 0, 34), Vector3(-48, 0, 50),
		Vector3(-10, 0, 52), Vector3(34, 0, 52), Vector3(44, 0, 28), Vector3(8, 0, 44), Vector3(-24, 0, 54)]
const VILLAGER_TENTS: Array[Vector3] = [Vector3(-22, 0, 42), Vector3(-40, 0, 54), Vector3(2, 0, 52), Vector3(24, 0, 38)]
const ARMY_TENTS := {&"ST1": [Vector3(-34, 0, 30), NATURE_SEAT, [["thornling", 5], ["wildwood_archer", 2]]],
		&"ST2": [Vector3(12, 0, 46), FIRE_SEAT, [["flame_guard", 4], ["ember_archer", 2]]],
		&"ST3": [Vector3(40, 0, 48), FIRE_SEAT, [["flame_guard", 3], ["ember_archer", 2], ["pyre_adept", 1]]]}
const VESSA_TENT := Vector3(16.0, 0.0, 54.0)
const VEY_PATH: Array[Vector3] = [Vector3(-17.0, 0.0, 47.0), Vector3(-11.0, 0.0, 51.0)]
const POSTS := [[Vector3(-24, 0, 28), NATURE_SEAT, [["thornling", 2]]], [Vector3(-6, 0, 27), NATURE_SEAT, [["thornling", 1], ["wildwood_archer", 1]]],
		[Vector3(10, 0, 28), FIRE_SEAT, [["flame_guard", 1], ["ember_archer", 1]]], [Vector3(22, 0, 30), FIRE_SEAT, [["flame_guard", 2]]],
		[Vector3(-46, 0, 30), NATURE_SEAT, [["thornling", 1], ["burr_slinger", 1]]], [Vector3(40, 0, 20), FIRE_SEAT, [["flame_guard", 1], ["ember_archer", 1]]]]
const PATROLS := [
	[NATURE_SEAT, [["thornling", 2], ["wildwood_archer", 1], ["burr_slinger", 1]], [Vector3(-44, 0, 30), Vector3(-42, 0, 44), Vector3(-30, 0, 54), Vector3(-20, 0, 40)]],
	[FIRE_SEAT, [["flame_guard", 3], ["ember_archer", 1], ["blaze_rider", 1]], [Vector3(8, 0, 32), Vector3(18, 0, 44), Vector3(36, 0, 48), Vector3(42, 0, 30)]],
	[FIRE_SEAT, [["flame_guard", 2], ["thornling", 1]], [Vector3(-26, 0, 31), Vector3(22, 0, 33)]],
]
const WAGON_GUARDS := {&"WG1": [["thornling", 2], ["wildwood_archer", 1], ["bloomtender", 1]], &"WG2": [],
		&"WG3": [["flame_guard", 2], ["ember_archer", 1]], &"WG4": [["flame_guard", 2], ["ember_archer", 1], ["blaze_rider", 1]]}
const FIRE_LIGHT := 9.0
const CONCEAL_NEAR := 6.0
const VEIL_NEAR := 3.0
const SPOT_RANGE := 9.0
const SNUFF_R := 2.0
const SNUFF_TIME := 2.0
const RELIGHT_R := 4.0
const SABOTAGE_R := 2.0
const SABOTAGE_TIME := 4.0
const SABOTAGE_HUSH := 2.0
const WAGON_HP := 500.0
const SAFE_Z := 22.0
const ALERT_R := 30.0
const ALERT_TIME := 45.0
const FUSE: Array[float] = [4.0, 3.0, 2.0]
const ALARMS_TO_WAKE: Array[int] = [4, 3, 2]
const DAWN: Array[float] = [780.0, 660.0, 600.0]
const HOLD_LIGHT: Array[float] = [120.0, 150.0, 180.0]
const PHASE2_CRYSTALS: Array[int] = [800, 600, 500]
const HUSH_HP: Array[float] = [1100.0, 900.0, 750.0]
const BLINK_DAMAGE: Array[float] = [75.0, 65.0, 60.0]
const VEIL_BONUS := 1.6
const VEIL_IDLE := 4.0
const BLINK_COOLDOWN := 10.0
const SMOKE_COOLDOWN := 22.0
const KNIVES_COOLDOWN := 75.0
const VEY_DETECT: Array = [[7.0, 4.0, 2.0], [9.0, 5.0, 3.0], [11.0, 6.0, 3.0]]
const R1_AT := 40.0
const R2_AT := 100.0
const DEFEAT_DELAY := 3.0
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const MALRIK_SPELLS := [&"shadow_lance", &"shadow_lance", &"soul_siphon", &"soul_siphon", &"umbral_shroud"]
const ESSENCE_CAP := 1500
const NO_SAVE_ESSENCE := 500

const SPEAKER_COLORS := {&"hush": Color(0.60, 0.50, 0.75), &"malrik": Color(0.7, 0.3, 1.0), &"torvald": Color(0.55, 0.80, 1.00),
		&"vessa": Color(1.0, 0.45, 0.1), &"vey": Color(0.95, 0.95, 0.55), &"ashby": Color(0.95, 0.60, 0.35),
		&"messenger": Color(0.80, 0.92, 0.60), &"ysolde": Color(0.55, 0.90, 0.35), &"obren": Color(1.0, 0.80, 0.25),
		&"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"hush": "Mother Hush", &"malrik": "Malrik", &"torvald": "Torvald", &"vessa": "Vessa", &"vey": "Old Vey",
		&"ashby": "Captain Ashby", &"messenger": "Wren", &"ysolde": "Ysolde", &"obren": "Obren", &"narrator": "Narrator"}
const DIALOGUE := [
	[&"narrator", "Night on Lark Hill. Two armies asleep in their armour, and one woman who never sleeps."],
	[&"malrik", "Four wagons, Hush. Grain, arrows, oil, fodder. Hungry armies march slowly."],
	[&"hush", "And the people in the tents, Bishop?"],
	[&"malrik", "Wagons. Not tents. I grew up burying people who starved in tents."],
	[&"hush", "Hush now. The dark only wants to be listened to."],
	[&"hush", "One wagon. Its wheels will not turn again."],
	[&"hush", "The old man. Awake, of course. He was awake that night too."],
	[&"malrik", "Then do not wake him further. Be the quiet thing in the dark."],
	[&"hush", "There she sleeps. The little queen. One step, Bishop. Just one."],
	[&"malrik", "Not tonight. Tonight we starve them. Knives are for another night."],
	[&"ashby", "Up! Up! Shadow in the camp! Torches, all of you!"],
	[&"messenger", "The Shadow's in the camp! Wake up!"],
	[&"vessa", "Hush! I know that smoke. Come out and finish what you started!"],
	[&"hush", "Another night, little queen. There is always another night."],
	[&"vey", "I know those knives. Not in my girl's camp. Not twice."],
	[&"malrik", "Two. Ysolde will count her sacks at dawn and come up short."],
	[&"torvald", "Your shadows are thorough, Malrik. I am not certain that is a compliment."],
	[&"hush", "Four. The camp will wake hungry, Bishop."],
	[&"malrik", "Good. Come home. Bring the night with you."],
	[&"narrator", "First light. On Lark Hill, Vessa found her wagons. She did not wait."],
	[&"vessa", "MALRIK! You sent the knife-woman into my camp AGAIN?"],
	[&"malrik", "I sent her to the wagons. You should be flattered she skipped your tent."],
	[&"malrik", "Stand with me, Hush. In daylight, for once."],
	[&"obren", "Let me do more than beat, Bishop. Let me help."],
	[&"malrik", "Not today. Today I have a knife."],
	[&"ysolde", "Then the people go south today. All of them. The road is safer than this hill."],
	[&"hush", "There is always another night, Bishop."],
	[&"malrik", "And every one of them is mine."],
	[&"hush", "The knife bends... Not tonight. Not..."],
	[&"narrator", "Dawn came up over Lark Hill, and the wagons rolled on."],
	[&"malrik", "Struck down at sunrise. How very Vessa."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The ford fell at dusk. Ysolde held her hill until the light was gone, and now both armies sleep in their armour, a river apart, while the villagers of Evenmead huddle in tents behind Lark Hill.",
	"Hungry armies march slowly. Four supply wagons came up the south road today: the villagers' winter grain, the Fire army's arrows, its lamp oil, its riders' fodder. Malrik wants all four spoiled before the sun is up.",
	"He is sending the knife that never misses. She missed once, at Emberfall. Tonight is another night.",
]
const BRIEFING_LINE := "Enemies see poorly in the dark, and clearly near a fire. Stay out of the light."
const HINT_START := "Stay out of fire-light. A snuffed fire hides you: stand by it 2 s. Enemies who see you raise an alarm after 3 s; kill them first."
const HINT_VEIL := "Hush is veiled after 4 s without fighting: only enemies within 3 m see her."
const HINT_VEY := "Old Vey cannot be hurt tonight. Slip past him veiled, or raise an alarm far away to draw him off."
const HINT_DAWN := "Your keep is a Citadel now. Select it: V calls Mother Hush, C trains the Nightblood Reaver."
const MSG_DAWN_LIGHT := "First light. The Citadel stands."
const MSG_VESSA_FELL := "Vessa falls back to Lark Hill"
const BUTTON_BLINK := "Blink Strike (F)"
const BUTTON_SMOKE := "Smoke Cloak (Q)"
const BUTTON_KNIVES := "Night of Knives (E)"
const REFUSE_RECHARGING := "Recharging"
const REFUSE_NO_TARGET := "No enemy within 14 m"
const REFUSE_NOT_NOW := "Not now"

var flag_override: Dictionary = {}

## Read only.
var phase := 1                         ## 1 the night, 2 first light
var hush_hero: Wizard = null
var malrik: Wizard = null
var torvald: Wizard = null
var vessa: Wizard = null
var vey_vigil: Unit = null
var squad: Array = []
var wagons := {}                       ## id -> Building
var spoiled := {}                      ## id -> true
var sabotage := {}                     ## id -> [unit, progress]
var fires: Array = []                  ## [pos, lit, snuff progress, relight progress, mesh material]
var alarms := 0
var alert_left := 0.0
var alert_at := Vector3.INF
var vessa_awake := false
var dawn_left := -1.0
var light_left := -1.0
var veiled := false
var blink_left := 0.0
var smoke_left := 0.0
var knives_left := 0.0
var smoke_at := Vector3.INF
var smoke_time := 0.0
var said: Array[int] = []
var victory_time := -1.0

var _said := {}
var _tick := 0.0
var _idle := 0.0
var _exposed := {}                     ## unit -> seconds left exposed
var _fuses := {}                       ## spotter -> seconds watching
var _sleepers := {}                    ## tent id -> Array of dormant units
var _patrols: Array = []               ## [units, waypoints, index]
var _vey_i := 0
var _vey_pause := 0.0
var _vessa_hunt := 0.0
var _tents: Array = []
var _wagon_type: BuildingType
var _tent_type: BuildingType
var _vey_type: UnitType
var _river: RiverSystem
var _panel: Control
var _last_obj_text := ""


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
	define_objectives([[&"obj_wagons", "primary"], [&"obj_hush", "primary"], [&"obj_light", "primary"], [&"obj_malrik", "primary"],
			[&"sec_unseen", "secondary"], [&"sec_villagers", "secondary"], [&"sec_call", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"blaze_rider"]
	c.defeat_on_keep_lost = false   # phase 2's own rule (E20)
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {ALLY_SEAT: 2, NATURE_SEAT: 2, FIRE_SEAT: 2}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.helper_call_price = {"crystals": 0, "essence": 0, "time": 10.0}
	c.start_level = 1
	c.start_crystals = [0, 0, 0]
	c.start_essence = 150
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe camp wakes hungry"
	c.defeat_banner = "DEFEAT"
	c.seat_sides = {PLAYER_SEAT: 0, ALLY_SEAT: 0, NATURE_SEAT: 1, FIRE_SEAT: 1}
	c.seat_opponents = {NATURE_SEAT: PLAYER_SEAT, FIRE_SEAT: ALLY_SEAT, ALLY_SEAT: FIRE_SEAT, PLAYER_SEAT: NATURE_SEAT}
	c.seat_kingdoms = {PLAYER_SEAT: &"shadow", ALLY_SEAT: &"ice", NATURE_SEAT: &"nature", FIRE_SEAT: &"fire"}
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"helper_hush", "trigger": &"start", "key_hint": "F / Q / E",
			"card": "Mother Hush. The knife in the dark: call her, and the enemy's archers and casters stop sleeping well."}
	return c


func _map_size() -> Vector2:
	return Vector2(MissionE3_01.MAP_W, MissionE3_01.MAP_D)


func _player_start() -> Vector3:
	return SQUAD_START


func _use_map_dressing() -> bool:
	return false


func _title_line() -> String:
	return "Episode 3, Mission 2: %s" % MISSION_TITLE


func _ready() -> void:
	_wagon_type = _make_prop_type("fire_hearth", &"supply_wagon", "Supply Wagon", WAGON_HP)
	_tent_type = _make_prop_type("shadow_hovel", &"villager_tents", "Villager Tents", 300.0)
	_vey_type = _make_vey_type()
	super()
	if camera_rig:
		camera_rig.focus_on(SQUAD_START)
	EmberfallNight.apply_to(self, EmberfallNight.night())


func _make_prop_type(base_id: String, id: StringName, title: String, hp: float) -> BuildingType:
	var base := BuildingType.find(base_id)
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.id = id
	t.display_name = title
	t.kind = id
	t.cost = 0
	t.max_hp = hp
	t.counts_for_defeat = false
	t.trains = []
	if &"pop_bonus" in t:
		t.set(&"pop_bonus", 0)
	return t


func _make_vey_type() -> UnitType:
	var base := UnitType.find("ruin_warden")
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.id = &"vey_vigil"
	t.display_name = "Old Vey"
	t.max_hp = 2000.0
	t.attack_damage = 40.0
	t.move_speed = 2.0
	t.aggro_range = 0.0
	t.kill_xp = 0
	t.commandable = false
	t.body_color = Color(0.85, 0.82, 0.6)
	t.eye_color = Color(1.0, 0.95, 0.7)
	return t


# ---------------------------------------------------------------- seats and the map

func start_position(team: int) -> Vector3:
	match team:
		ALLY_SEAT:
			return ICE_RALLY
		NATURE_SEAT:
			return HEARTWOOD
		FIRE_SEAT:
			return FIRE_KEEP
	return MALRIK_DAWN


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
	return k.spawn_point() if k else base_center(team) + Vector3(4.0, 0.0, 4.0)


func node_of(team: int, suffix: String) -> CrystalNode:
	var prefix := {PLAYER_SEAT: "e3_dusk_", ALLY_SEAT: "e3_rime_"}
	var v: Variant = crystal_nodes.get(StringName("%s%s" % [prefix.get(team, "e3_dusk_"), suffix]))
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


func natural_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


func _build_map() -> void:
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	_river = MissionE3_01.make_river(nav_region, MALRIK_CREST)
	var mat := _ground_material()
	if mat:
		EnvProps.set_river(mat, _river.shader_params())
	keep = build_grid.spawn_complete(BuildingType.find("shadow_keep"), DUSK_KEEP, PLAYER_SEAT) as Keep
	build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL, PLAYER_SEAT)
	for p in HOVELS:
		build_grid.spawn_complete(BuildingType.find("shadow_hovel"), p, PLAYER_SEAT)
	seat_bases[PLAYER_SEAT] = DUSK_KEEP
	var rk := build_grid.spawn_complete(BuildingType.find("ice_keep"), RIME_KEEP, ALLY_SEAT) as Keep
	build_grid.spawn_complete(BuildingType.find("ice_barracks"), RIME_HALL, ALLY_SEAT)
	if rk:
		seat_keeps[ALLY_SEAT] = rk
	var hw := build_grid.spawn_complete(BuildingType.find("nature_keep"), HEARTWOOD, NATURE_SEAT) as Keep
	build_grid.spawn_complete(BuildingType.find("nature_barracks"), GROVE_HALL, NATURE_SEAT)
	shadow_keep = hw
	if hw:
		seat_keeps[NATURE_SEAT] = hw
	var fk := build_grid.spawn_complete(BuildingType.find("fire_keep"), FIRE_KEEP, FIRE_SEAT) as Keep
	var eh := build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL, FIRE_SEAT)
	if eh:
		eh.set_meta(&"e3m2_hall", true)
	if fk:
		seat_keeps[FIRE_SEAT] = fk
	for row: Array in CREST_SPIRES:
		build_grid.spawn_complete(BuildingType.find("nature_tower" if int(row[0]) == NATURE_SEAT else "fire_tower"), row[1], int(row[0]))
	for id: StringName in WAGONS:
		var w := build_grid.spawn_complete(_wagon_type, WAGONS[id][1], int(WAGONS[id][2])) if _wagon_type else null
		if w:
			w.name = "Wagon_%s" % String(id)
			mark_scripted(w)
			w.add_to_group(&"wagons")
			w.destroyed.connect(_on_wagon_destroyed.bind(id))
			wagons[id] = w
	set_truce(wagons.values(), true, Unit.TRUCE_ALL)   # spoiled by sabotage only (deviation: no loud destroy)
	for p in VILLAGER_TENTS:
		var t := build_grid.spawn_complete(_tent_type, p, NATURE_SEAT) if _tent_type else null
		if t:
			mark_scripted(t)
			t.add_to_group(&"noncombatant")
			_tents.append(t)
	set_truce(_tents, true, Unit.TRUCE_ALL)   # noncombatant: no auto-target (deviation: no explicit attack either)
	for p in FIRES:
		fires.append([p, true, 0.0, 0.0, _fire_look(p)])
	MissionE3_01.add_golden_tree(self)


func _fire_look(p: Vector3) -> StandardMaterial3D:
	if _SIM.enabled:
		return null
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.7
	c.bottom_radius = 0.9
	c.height = 0.5
	mi.mesh = c
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.1)
	mat.emission_energy_multiplier = 2.0
	mi.material_override = mat
	add_child(mi)
	mi.position = p + Vector3(0.0, 0.25, 0.0)
	return mat


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for id: StringName in WAGONS:
		fog.reveal(PLAYER_SEAT, WAGONS[id][1], 6.0)
	for p: Vector3 in [MissionE3_01.FORD_STONE, MissionE3_01.FORD_REED, MissionE3_01.FORD_BIRCH, SQUAD_START]:
		fog.reveal(PLAYER_SEAT, p, 8.0)
	_setup_champions()
	# --- Hush, the night's hero (a Wizard set up as her: the helper model, no spells; abilities mission-side).
	hush_hero = Wizard.new()
	hush_hero.unit_name = "Mother Hush"
	hush_hero.kingdom = &"shadow"
	var empty: Array[StringName] = []
	hush_hero.default_spell_ids = empty
	hush_hero.default_model_path = "res://art/units/helpers/helper_hush/helper_hush.tscn"
	hush_hero.max_hp = float(by_difficulty(HUSH_HP))
	hush_hero.attack_damage = 34.0
	hush_hero.attack_range = 1.6
	hush_hero.attack_cooldown = 1.0
	hush_hero.move_speed = 5.4
	hero = hush_hero
	_spawn(hush_hero, PLAYER_SEAT, SQUAD_START)
	hush_hero.set_base_stat(&"armor", 10.0)
	_claim_wizard(hush_hero, PLAYER_SEAT)
	hush_hero.level_cap = 1
	hush_hero.damage_taken.connect(_on_squad_hurt.bind(hush_hero))
	hush_hero.attack_landed.connect(func(_t: Node3D, _a: float) -> void:
		_idle = 0.0
		_exposed[hush_hero] = 3.0)
	var rows := [["shade", 4], ["grave_hound", 2], ["nightblood_reaver", 2]]
	var k := 0
	for row: Array in rows:
		for j in int(row[1]):
			var a := TAU * float(k) / 8.0
			var u := _spawn(make_unit(String(row[0])), PLAYER_SEAT, SQUAD_START + Vector3(cos(a) * 3.0, 0.0, sin(a) * 3.0))
			u.set_meta(&"veterancy", 2)
			u.attack_landed.connect(func(_t: Node3D, _a: float) -> void: _exposed[u] = 3.0)
			u.damage_taken.connect(_on_squad_hurt.bind(u))
			squad.append(u)
			k += 1
	# --- Malrik on the crest (a story unit until dawn: invulnerable, not selectable).
	malrik = _make_wizard(PLAYER_SEAT)
	_spawn(malrik, PLAYER_SEAT, MALRIK_CREST)
	ItemDrops.ensure_inventory(malrik)
	raise_wizard(malrik, 5, MALRIK_SPELLS)
	malrik.remove_from_group(&"heroes")
	set_dormant(malrik, true)
	mark_scripted(malrik)
	# --- The bots: Torvald idle until dawn; the camp's seats run no economy tonight.
	var ice := activate_seat(ALLY_SEAT, &"ice", {"crystals": 300,
			"workers": [["rime_hauler", 2, node_of(ALLY_SEAT, "a")], ["rime_hauler", 2, node_of(ALLY_SEAT, "b")]],
			"units": [["rimeshield", 4, ICE_RALLY], ["shardcaster", 2, ICE_RALLY], ["frost_mortar", 1, ICE_RALLY]],
			"wizard": {"level": 5, "pos": ICE_RALLY + Vector3(0.0, 0.0, -3.0)}})
	torvald = ice.get("wizard") as Wizard
	activate_seat(NATURE_SEAT, &"nature", {"crystals": 0})
	var fire := activate_seat(FIRE_SEAT, &"fire", {"crystals": 0,
			"wizard": {"level": 6, "spells": [&"fireball", &"fireball", &"ember_step", &"ember_step", &"kindle"], "pos": VESSA_TENT}})
	vessa = fire.get("wizard") as Wizard
	if vessa:
		vessa.level_cap = 6
		mark_scripted(vessa)
		set_dormant(vessa, true)   # asleep in her tent
		vessa.died.connect(_on_vessa_died)
	_spawn_night()
	lock_base(true)
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	if bank:
		bank.trickle_enabled = false
		bank.kill_income_enabled = false
	dawn_left = float(by_difficulty(DAWN))
	begin_mission([&"obj_wagons", &"obj_hush", &"sec_unseen", &"sec_villagers"])
	set_resources_hidden(true)
	_build_panel()


func _spawn_night() -> void:
	for row: Array in POSTS:
		var units := spawn_group(row[2], row[0], 1.5, int(row[1]) as Unit.Team, true)
		for u: Variant in units:
			_night_unit(u as Unit)
	for row: Array in PATROLS:
		var pts: Array = row[2]
		var units := spawn_group(row[1], pts[0], 1.5, int(row[0]) as Unit.Team, false)
		for u: Variant in units:
			_night_unit(u as Unit)
		_patrols.append([units, pts, 1])
	for id: StringName in WAGON_GUARDS:
		var units := spawn_group(WAGON_GUARDS[id], WAGONS[id][1], 3.0, int(WAGONS[id][2]) as Unit.Team, true)
		for u: Variant in units:
			_night_unit(u as Unit)
	for id: StringName in ARMY_TENTS:
		var row: Array = ARMY_TENTS[id]
		var units := spawn_group(row[2], row[0], 2.0, int(row[1]) as Unit.Team, true)
		for u: Variant in units:
			_night_unit(u as Unit)
			set_dormant(u as Unit, true)
		_sleepers[id] = units
	vey_vigil = _spawn(Worker.make_unit(_vey_type), FIRE_SEAT as Unit.Team, VEY_PATH[0])
	vey_vigil.name = "VeyVigil"
	mark_scripted(vey_vigil)
	_make_immortal(vey_vigil)


## The night's enemy units: sight trimmed (night x 0.6), aggro only through the spotting rule.
func _night_unit(u: Unit) -> void:
	u.set_meta(&"night", true)


## Old Vey cannot be hurt tonight (D5): hp back to full on any killing blow.
static func _make_immortal(u: Unit) -> void:
	u.death_guard = func(_a: Variant) -> bool:
		u.hp = u.max_hp
		return true


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_wagons", false), objective_text(&"obj_hush", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_hush")),
	}


func wagons_spoiled() -> int:
	return spoiled.size()


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_wagons":
			if with_counter and dawn_left >= 0.0:
				var s := int(ceil(dawn_left))
				return "%s\n%s" % ["Spoil the supply wagons before dawn (%d / 4)" % wagons_spoiled(), "Dawn in %d:%02d" % [s / 60, s % 60]]
			return "Spoil the supply wagons before dawn"
		&"obj_hush":
			return "Mother Hush must survive"
		&"obj_light":
			if with_counter and light_left >= 0.0:
				var s := int(ceil(light_left))
				return "Hold the ridge until the sun is up (%d:%02d)" % [s / 60, s % 60]
			return "Hold the ridge until the sun is up"
		&"obj_malrik":
			return "Malrik must survive"
		&"sec_unseen":
			if with_counter:
				return "%s (%s)" % ["Never wake the camp", "Alarm %d / %d" % [alarms, int(by_difficulty(ALARMS_TO_WAKE))]]
			return "Never wake the camp"
		&"sec_villagers":
			return "Spare the villagers' tents"
		&"sec_call":
			return "Call Mother Hush from the Citadel (V)"
	return String(id)


func say_l(n: int) -> void:
	if _said.has(n):
		return
	_said[n] = true
	said.append(n)
	say_line(n)


## E1: the slip (e3m2_slip, HOLD 0:15 played as PAUSE; fallback = the camera on Hush + L1), L2-L4, the start hint.
func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e3m2_slip", func() -> void:
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position)
		for n in [1, 2, 3, 4]:
			say_l(n)
		if hud:
			hud.show_message(HINT_START, 10.0))


# ---------------------------------------------------------------- Hush's abilities (phase 1, mission-side)

func _build_panel() -> void:
	_panel = mission_button_panel("HushPanel", [
		[Loc.t(BUTTON_BLINK), func() -> void: _report(blink_strike())],
		[Loc.t(BUTTON_SMOKE), func() -> void: _report(smoke_cloak())],
		[Loc.t(BUTTON_KNIVES), func() -> void: _report(night_of_knives())]])


func _report(r: String) -> void:
	if r != "" and hud:
		hud.show_message(r, 3.0)


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if phase == 1 and k and k.pressed and not k.echo and match_started and not game_over:
		var r := "-"
		match k.physical_keycode:
			KEY_F:
				r = blink_strike()
			KEY_Q:
				r = smoke_cloak()
			KEY_E:
				r = night_of_knives()
		if r != "-":
			_report(r)
			get_viewport().set_input_as_handled()
			return
	super(event)


func _foes_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), PLAYER_SEAT) and int(u.team) != Unit.Team.NEUTRAL \
				and u != vey_vigil and not is_dormant(u) and _flat(u.global_position, at) <= r:
			out.append(u)
	return out


## Blink Strike (F, 10 s): behind the weakest enemy within 14 m, 65 (out of the veil x 1.6: 104).
func blink_strike(target: Unit = null) -> String:
	if phase != 1 or not hero_alive():
		return REFUSE_NOT_NOW
	if blink_left > 0.0:
		return REFUSE_RECHARGING
	if target == null:
		var foes := _foes_near(hero.global_position, 14.0)
		for u in foes:
			if target == null or u.hp < target.hp:
				target = u
	if target == null:
		return REFUSE_NO_TARGET
	blink_left = BLINK_COOLDOWN
	var back := (target.global_position - hero.global_position)
	back.y = 0.0
	hero.global_position = target.global_position + back.normalized() * 1.2
	var dmg := float(by_difficulty(BLINK_DAMAGE)) * (VEIL_BONUS if veiled else 1.0)
	target.take_damage(dmg, hero)
	hero.command_attack(target)
	_idle = 0.0
	return ""


## Smoke Cloak (Q, 22 s): smoke r 4 for 5 s at her spot: squad units inside are concealed even in fire-light; spotters
## lose their fuse; she is shrouded 3 s.
func smoke_cloak() -> String:
	if phase != 1 or not hero_alive():
		return REFUSE_NOT_NOW
	if smoke_left > 0.0:
		return REFUSE_RECHARGING
	smoke_left = SMOKE_COOLDOWN
	smoke_at = hero.global_position
	smoke_time = 5.0
	hero.apply_status(&"shroud", 3.0, true)
	_fuses.clear()
	flash_ring(smoke_at, 4.0)
	return ""


## Night of Knives (E, 75 s): 6 strikes of 46 on up to 6 enemies within 10 m (heroes x 1.5); exposes her 3 s.
func night_of_knives() -> String:
	if phase != 1 or not hero_alive():
		return REFUSE_NOT_NOW
	if knives_left > 0.0:
		return REFUSE_RECHARGING
	var foes := _foes_near(hero.global_position, 10.0)
	if foes.is_empty():
		return REFUSE_NO_TARGET
	knives_left = KNIVES_COOLDOWN
	for i in mini(6, foes.size()):
		var u := foes[i]
		u.take_damage(46.0 * (1.5 if u is Wizard else 1.0), hero)
	_exposed[hero] = 3.0
	_idle = 0.0
	return ""


# ---------------------------------------------------------------- the night: light, concealment, spotting

func lit_at(p: Vector3) -> bool:
	for f: Array in fires:
		if f[1] and _flat(f[0], p) <= FIRE_LIGHT:
			return true
	return false


func is_concealed(u: Unit) -> bool:
	if u == null or not u.is_alive():
		return false
	if smoke_time > 0.0 and _flat(u.global_position, smoke_at) <= 4.0:
		return true
	if float(_exposed.get(u, 0.0)) > 0.0 or lit_at(u.global_position):
		return false
	return true


## The radius an enemy sees `u` at: concealed 6 m (veiled Hush 3 m), else the night sight.
func seen_within(u: Unit) -> float:
	if is_concealed(u):
		return VEIL_NEAR if (u == hush_hero and veiled) else CONCEAL_NEAR
	return SPOT_RANGE


func _squad_alive() -> Array[Unit]:
	var out: Array[Unit] = []
	if hush_hero and is_instance_valid(hush_hero) and hush_hero.is_alive():
		out.append(hush_hero)
	for s: Variant in squad:
		if is_instance_valid(s) and (s as Unit).is_alive():
			out.append(s as Unit)
	return out


## Each tick: squad units unseen by an awake enemy are hidden from auto-targets; a spotter who sees one fills its
## fuse (3 s), then raises an alarm there.
func _tick_night(dt: float) -> void:
	var mine := _squad_alive()
	var spotters: Dictionary = {}
	for n in get_tree().get_nodes_in_group(&"units"):
		var e := n as Unit
		if e == null or not e.is_alive() or not Teams.is_hostile(int(e.team), PLAYER_SEAT) or is_dormant(e) \
				or e == vey_vigil or e.is_worker():
			continue
		for u in mine:
			if _flat(e.global_position, u.global_position) <= seen_within(u):
				spotters[e] = u
				break
	for u in mine:
		var seen := false
		for e: Variant in spotters:
			if spotters[e] == u:
				seen = true
				break
		if not seen:
			u.hide_from_auto_target(0.6)
	for e: Variant in _fuses.keys():
		if not spotters.has(e) or not is_instance_valid(e) or not (e as Unit).is_alive():
			_fuses.erase(e)
	var fuse := float(by_difficulty(FUSE))
	for e: Variant in spotters:
		_fuses[e] = float(_fuses.get(e, 0.0)) + dt
		if _fuses[e] >= fuse and alert_left <= 0.0:
			_fuses.clear()
			raise_alarm((spotters[e] as Unit).global_position)
			break
	for u: Variant in _exposed.keys():
		_exposed[u] = float(_exposed[u]) - dt
		if _exposed[u] <= 0.0:
			_exposed.erase(u)


## An alarm: the horn, a 45 s camp alert (awake enemies within 30 m attack-move there, the nearest army tent wakes,
## fires within 30 m relight); Alarm 2 adds guards; the last alarm wakes Vessa.
func raise_alarm(at: Vector3) -> void:
	if phase != 1 or is_ending():
		return
	alarms += 1
	alert_at = at
	alert_left = ALERT_TIME
	fire_once(&"E6")
	if alarms == 1:
		say_l(11)
		if objective_state("sec_unseen") == "active":
			set_objective(&"sec_unseen", "failed")
	elif alarms == 2:
		say_l(12)
		for id: StringName in WAGONS:
			if not spoiled.has(id):
				var team := int(WAGONS[id][2])
				var rows := [["thornling", 1], ["burr_slinger", 1]] if team == NATURE_SEAT else [["flame_guard", 1], ["ember_archer", 1]]
				for u in spawn_group(rows, WAGONS[id][1], 3.0, team as Unit.Team, true):
					_night_unit(u as Unit)
	set_objective(&"sec_unseen", objective_state("sec_unseen") if objective_state("sec_unseen") != "" else "active")
	for f: Array in fires:
		if _flat(f[0], at) <= ALERT_R:
			_set_fire(f, true)
	for id: StringName in _sleepers:
		if _flat(ARMY_TENTS[id][0], at) <= ALERT_R:
			for u: Variant in _sleepers[id]:
				if is_instance_valid(u) and (u as Unit).is_alive() and is_dormant(u):
					set_dormant(u as Unit, false)
	for n in get_tree().get_nodes_in_group(&"units"):
		var e := n as Unit
		if e and e.is_alive() and Teams.is_hostile(int(e.team), PLAYER_SEAT) and not is_dormant(e) and e != vey_vigil \
				and _flat(e.global_position, at) <= ALERT_R and e.has_meta(&"night"):
			order_wave(e, &"alert", at)
	if vey_vigil and _flat(at, MissionE3_01.GOLDEN_TREE) >= 25.0:
		vey_vigil.set_meta(&"lured", ALERT_TIME)
	if alarms >= int(by_difficulty(ALARMS_TO_WAKE)) and not vessa_awake:
		_wake_vessa()
	if hud:
		hud.set_objective(_objective_text())


func _wake_vessa() -> void:
	vessa_awake = true
	fire_once(&"E7")
	say_l(13)
	say_l(14)
	if vessa and is_instance_valid(vessa):
		set_dormant(vessa, false)
		_vessa_hunt = 90.0
		order_wave(vessa, &"hunt", hero_pos())
	for u in spawn_wave_at([["blaze_rider", 4]], FIRE_KEEP + Vector3(-6.0, 0.0, -6.0), FIRE_SEAT):
		order_wave(u as Unit, &"hunt", hero_pos())
	for f: Array in fires:
		_set_fire(f, true)


func _set_fire(f: Array, lit: bool) -> void:
	f[1] = lit
	f[2] = 0.0
	f[3] = 0.0
	var mat := f[4] as StandardMaterial3D
	if mat:
		mat.emission_energy_multiplier = 2.0 if lit else 0.0
		mat.albedo_color = Color(1.0, 0.55, 0.15) if lit else Color(0.2, 0.18, 0.16)


## Snuff: a squad unit (not a Hound) within 2 m for 2 s; relight: an awake enemy within 4 m for 3 s.
func _tick_fires(dt: float) -> void:
	var mine := _squad_alive()
	for f: Array in fires:
		if f[1]:
			var near := false
			for u in mine:
				if u.unit_type and u.unit_type.id == &"grave_hound":
					continue
				if _flat(u.global_position, f[0]) <= SNUFF_R:
					near = true
					break
			f[2] = float(f[2]) + dt if near else 0.0
			if f[2] >= SNUFF_TIME:
				_set_fire(f, false)
				if fire_once(&"E2"):
					say_l(5)
					if hud:
						hud.show_message(HINT_VEIL, 6.0)
		else:
			var enemy := false
			for e in _foes_near(f[0], RELIGHT_R):
				enemy = true
				break
			f[3] = float(f[3]) + dt if enemy else 0.0
			if f[3] >= 3.0:
				_set_fire(f, true)


# ---------------------------------------------------------------- the wagons

## Sabotage: a squad unit (not a Hound) within 2 m for 4 s (Hush 2 s); leaving or taking damage resets it.
func _tick_wagons(dt: float) -> void:
	var mine := _squad_alive()
	for id: StringName in wagons:
		if spoiled.has(id):
			continue
		var w: Building = wagons[id]
		if w == null or not is_instance_valid(w):
			continue
		var row: Array = sabotage.get(id, [null, 0.0])
		var who: Unit = row[0] if row[0] != null and is_instance_valid(row[0]) else null
		if who == null or not who.is_alive() or _flat(who.global_position, w.global_position) > SABOTAGE_R + 2.0:
			who = null
			row[1] = 0.0
			for u in mine:
				if u.unit_type and u.unit_type.id == &"grave_hound":
					continue
				if _flat(u.global_position, w.global_position) <= SABOTAGE_R + 2.0:
					who = u
					break
		row[0] = who
		if who != null:
			row[1] = float(row[1]) + dt / (SABOTAGE_HUSH if who == hush_hero else SABOTAGE_TIME)
			if float(row[1]) >= 1.0:
				_spoil(id, false)
				continue
		sabotage[id] = row


## A saboteur that takes damage starts over (its channel resets).
func _on_squad_hurt(_amount: float, _attacker: Node3D, u: Unit) -> void:
	_idle = 0.0 if u == hush_hero else _idle
	for id: StringName in sabotage:
		var row: Array = sabotage[id]
		if row[0] == u:
			row[1] = 0.0


func _on_wagon_destroyed(_b: Building, id: StringName) -> void:
	if spoiled.has(id) or phase != 1:
		return
	_spoil(id, true)


func _spoil(id: StringName, loud: bool) -> void:
	if spoiled.has(id):
		return
	spoiled[id] = true
	var w: Building = wagons.get(id)
	if w and is_instance_valid(w):
		flash_ring(w.global_position, 3.0)
		if loud:
			raise_alarm(w.global_position)
	set_objective(&"obj_wagons", "active")
	match wagons_spoiled():
		1:
			fire_once(&"E3")
			say_l(6)
		2:
			fire_once(&"E9")
			say_l(16)
		3:
			fire_once(&"E10")
			say_l(17)
		4:
			fire_once(&"E11")
			say_l(18)
			say_l(19)
			set_objective(&"obj_wagons", "done")
			_end_night()


# ---------------------------------------------------------------- the camp: patrols, Vey, alerts

func _tick_camp(dt: float) -> void:
	if alert_left > 0.0:
		alert_left -= dt
		if alert_left <= 0.0:
			for n in get_tree().get_nodes_in_group(&"units"):
				var e := n as Unit
				if e and e.is_alive() and e.get_meta(META_MODE, &"") == &"alert":
					e.set_meta(META_MODE, &"posted")
					if e.has_meta(META_HOME):
						e.command_move(e.get_meta(META_HOME))
	for row: Array in _patrols:
		var units: Array = (row[0] as Array).filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
		row[0] = units
		if units.is_empty():
			continue
		var lead := units[0] as Unit
		if lead.get_meta(META_MODE, &"") == &"alert":
			continue
		var pts: Array = row[1]
		var goal: Vector3 = pts[int(row[2])]
		if _flat(lead.global_position, goal) <= 2.5:
			row[2] = (int(row[2]) + 1) % pts.size()
			goal = pts[int(row[2])]
		for u: Variant in units:
			var uu := u as Unit
			if uu.attack_target == null and not uu.has_move_order():
				uu.command_move(goal)
	_tick_vey(dt)
	if _vessa_hunt > 0.0:
		_vessa_hunt -= dt
		if _vessa_hunt <= 0.0 and vessa and is_instance_valid(vessa) and vessa.is_alive():
			vessa.set_meta(META_MODE, &"home")
			vessa.command_move(VESSA_TENT)


## Old Vey's vigil: the path with 15 s pauses; detection (lit 9 m, concealed 5 m, veiled Hush 3 m) = an instant alarm
## and an 80 hit; lured 45 s toward an alarm 25+ m from the tree.
func _tick_vey(dt: float) -> void:
	if vey_vigil == null or not is_instance_valid(vey_vigil):
		return
	var lured := float(vey_vigil.get_meta(&"lured", 0.0))
	if lured > 0.0:
		vey_vigil.set_meta(&"lured", lured - dt)
		if not vey_vigil.has_move_order() and alert_at != Vector3.INF:
			vey_vigil.command_move(alert_at)
		return
	var goal: Vector3 = VEY_PATH[_vey_i]
	if _flat(vey_vigil.global_position, goal) <= 1.0:
		_vey_pause -= dt
		if _vey_pause <= 0.0:
			_vey_i = (_vey_i + 1) % VEY_PATH.size()
			_vey_pause = 15.0
	elif not vey_vigil.has_move_order():
		vey_vigil.command_move(goal)
	var det: Array = VEY_DETECT[clampi(mission_difficulty, 0, 2)]
	for u in _squad_alive():
		var r := float(det[0])
		if is_concealed(u):
			r = float(det[2]) if (u == hush_hero and veiled) else float(det[1])
		if _flat(u.global_position, vey_vigil.global_position) <= r:
			if fire_once(&"E8"):
				say_l(15)
			u.take_damage(80.0, vey_vigil)
			u.apply_status(&"dazed", 0.5)
			if alert_left <= 0.0:
				raise_alarm(u.global_position)
			break
	if hush_hero and hush_hero.is_alive() and _flat(hush_hero.global_position, vey_vigil.global_position) <= 14.0 and fire_once(&"E4"):
		say_l(7)
		say_l(8)
		if hud:
			hud.show_message(HINT_VEY, 8.0)


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	match mode:
		&"alert":
			if u.attack_target == null and not u.is_attack_moving() and alert_at != Vector3.INF:
				u.command_attack_move(alert_at)
			return true
		&"hunt":
			if hero_alive() and hero.global_position.z <= SAFE_Z:
				u.set_meta(META_MODE, &"home")   # the safe line: hunters drop the chase
				u.command_move(FIRE_KEEP + Vector3(-4.0, 0.0, -6.0))
			elif u.attack_target == null and hero_alive():
				u.command_attack_move(hero.global_position)
			return true
		&"reprisal":
			if u.attack_target == null and not u.is_attack_moving():
				u.command_attack_move(_alive_pos(keep, MALRIK_DAWN) if keep and keep.is_alive() else hero_pos())
			return true
		&"home", &"posted":
			return true
	return false


# ---------------------------------------------------------------- dawn: phase 2

## E11 -> e3m2_embers end state -> E12: squad survivors at the Shadow rally, Hush the hero's story ends (she is the
## callable helper now), Malrik the hero at the keep door, the Dusk Keep a Citadel, economy on, the camp cleared.
func _end_night() -> void:
	set_mission_flag("e3m2_alarms", alarms)
	if objective_state("sec_unseen") == "active":
		set_objective(&"sec_unseen", "done")
	if objective_state("sec_villagers") == "active":
		set_objective(&"sec_villagers", "done")
	set_objective(&"obj_hush", "done")
	play_cutscene(&"e3m2_embers", _dawn)


func _dawn() -> void:
	phase = 2
	dawn_left = -1.0
	if hud:
		hud.show_message(MSG_DAWN_LIGHT, 4.0)
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var e := n as Unit
		if e and e.is_alive() and e.has_meta(&"night"):
			e.leave_map()
	for id: StringName in _sleepers:
		for u: Variant in _sleepers[id]:
			if is_instance_valid(u):
				(u as Unit).leave_map()
	if vey_vigil and is_instance_valid(vey_vigil):
		vey_vigil.leave_map()
	for f: Array in fires:
		_set_fire(f, false)
	for i in squad.size():
		var s: Variant = squad[i]
		if is_instance_valid(s) and (s as Unit).is_alive():
			(s as Unit).global_position = SHADOW_RALLY + Vector3((i % 4) * 1.6 - 2.4, 0.0, (i / 4) * 1.7)
			(s as Unit).heal(1.0e6)
			(s as Unit).command_stop()
	# Malrik takes over: the hero swap (F1 / Space / spells / instant loss follow set_player_hero).
	set_dormant(malrik, false)
	malrik.remove_meta(SCRIPTED_GROUP)
	malrik.remove_from_group(SCRIPTED_GROUP)
	malrik.global_position = MALRIK_DAWN
	_claim_wizard(malrik, PLAYER_SEAT)
	malrik.level_cap = 6
	force_artifacts(malrik, ["keystone_shard", ""])
	set_player_hero(malrik)
	if hush_hero and is_instance_valid(hush_hero):
		hush_hero.death_guard = func(_a: Variant) -> bool: return true
		hush_hero.leave_map()
	if keep:
		keep.set_start_tier(3)
	lock_base(false)
	set_resources_hidden(false)
	var eco := Economy.for_team(PLAYER_SEAT)
	if eco:
		eco.crystals = int(by_difficulty(PHASE2_CRYSTALS))
		eco.changed.emit()
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	if bank:
		bank.trickle_enabled = true
		bank.kill_income_enabled = true
		bank.add(_carried_essence())
	for i in 6:
		var w := _spawn(make_unit("gloom_thrall"), PLAYER_SEAT, DUSK_KEEP + Vector3(-4.0 + i * 1.5, 0.0, 6.0))
		w.call(&"command_gather", node_of(PLAYER_SEAT, "a" if i < 3 else "b"))
	if vessa and is_instance_valid(vessa):
		set_dormant(vessa, false)
		vessa.global_position = FIRE_KEEP + Vector3(-4.0, 0.0, -6.0)
		vessa.command_stop()
	_add_seat_commander(ALLY_SEAT)
	var roster := HelperRoster.for_team(PLAYER_SEAT)
	if roster and roster.has_signal(&"helper_ready"):
		roster.connect(&"helper_ready", func(_h: Variant) -> void:
			if fire_once(&"E15"):
				say_l(23)
				if objective_state("sec_call") == "active":
					set_objective(&"sec_call", "done"))
	fire_once(&"E12")
	say_l(20)
	light_left = float(by_difficulty(HOLD_LIGHT))
	set_objective(&"obj_light", "active")
	set_objective(&"obj_malrik", "active")
	set_objective(&"sec_call", "active")
	if hud:
		hud.show_message(HINT_DAWN, 10.0)
	if _panel:
		_panel.visible = false
	after(R1_AT, _reprisal.bind(1))
	after(R2_AT, _reprisal.bind(2))


func _carried_essence() -> int:
	var cs := CampaignState.open(campaign_save_path)
	if flag_override.has(CampaignState.MALRIK_ESSENCE_FLAG):
		return int(flag_override[CampaignState.MALRIK_ESSENCE_FLAG])
	if not cs.is_completed(&"e3m1"):
		return NO_SAVE_ESSENCE
	return int(cs.flag_value(CampaignState.MALRIK_ESSENCE_FLAG, 0))


## R1 (+0:40): Vessa + 3 Blaze Riders + 6 Flame Guards + 3 Ember Archers (+1 Flame Guard per alarm); R2 (+1:40).
func _reprisal(n: int) -> void:
	if is_ending() or phase != 2:
		return
	var rows: Array = [["blaze_rider", 3], ["flame_guard", 6 + alarms], ["ember_archer", 3]] if n == 1 \
			else [["flame_guard", 4], ["pyre_adept", 2], ["blaze_rider", 2]]
	var units := spawn_wave_at(rows, EMBER_HALL + Vector3(-4.0, 0.0, -4.0), FIRE_SEAT)
	for u in units:
		order_wave(u as Unit, &"reprisal", MissionE3_01.FORD_STONE)
	if n == 1:
		fire_once(&"E13")
		say_l(21)
		say_l(22)
		if vessa and is_instance_valid(vessa) and vessa.is_alive():
			order_wave(vessa, &"reprisal", MissionE3_01.FORD_STONE)
		for nn in get_tree().get_nodes_in_group(&"units"):
			var a := nn as Unit
			if a and a.is_alive() and int(a.team) == ALLY_SEAT and not a.is_worker():
				mark_scripted(a)
				a.set_meta(META_HOME, TORVALD_FLANK + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-2.0, 2.0)))
				if not _guards.has(a):
					_guards.append(a)


func _tick_light(dt: float) -> void:
	if phase != 2 or light_left < 0.0:
		return
	if keep == null or not is_instance_valid(keep) or not keep.is_alive():
		if fire_once(&"E20"):
			lose(DEFEAT_DELAY)
		return
	light_left = maxf(0.0, light_left - dt)
	if light_left <= 0.0 and fire_once(&"E16"):
		victory_time = mission_time()
		set_objective(&"obj_light", "done")
		clear_waves()
		for n in get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and u.is_alive() and int(u.team) == FIRE_SEAT and not u.is_worker():
				set_truce([u], true, Unit.TRUCE_ALL)
				u.command_move(FIRE_KEEP)
		_record_flags()
		play_cutscene(&"e3m2_dawn", func() -> void:
			say_l(26)
			say_l(27)
			say_l(28)
			set_objective(&"obj_malrik", "done")
			if objective_state("sec_call") == "active":
				set_objective(&"sec_call", "failed")
			win(2.0))


func _record_flags() -> void:
	set_mission_flag("e3m2_alarms", alarms)
	set_mission_flag("e3m2_time", int(victory_time))
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	var essence := bank.essence if bank else 0
	if objective_state("sec_unseen") == "done":
		essence += 200
	if objective_state("sec_villagers") == "done":
		essence += 150
	set_mission_flag(CampaignState.MALRIK_ESSENCE_FLAG, mini(ESSENCE_CAP, essence / 2))


func _on_vessa_died(_u: Unit) -> void:
	if is_ending() or phase != 2:
		return
	_respawn_left[FIRE_SEAT] = 60.0
	if hud:
		hud.show_message(MSG_VESSA_FELL, 4.0)


func seat_profile(seat: int) -> AIProfile:
	var p: AIProfile = AIProfile.ice(clampi(mission_difficulty, 0, 2))
	p.id = &"mission_e3_02_ally"
	p.profile_id = p.id
	p.min_attack_pop = 99
	p.launch_attacks = false
	p.attack_full_pop = 0
	p.worker_target_home = 4
	p.worker_target_expanded = 4
	p.second_expansion = false
	p.expand_time = 1.0e6
	p.max_soldiers = 10
	p.rebuild = false
	p.hero_stays_home = true
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
	bot.name = "Bot%d" % seat
	bot.set(&"team", seat)
	bot.set(&"profile", seat_profile(seat))
	add_child(bot)
	commanders.append(bot)
	return bot


func _on_player_hero_fell() -> void:
	if phase == 1:
		fire_once(&"E17")
		say_l(29)
		set_objective(&"obj_hush", "failed")
	else:
		fire_once(&"E19")
		say_l(31)
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
	if phase == 1:
		blink_left = maxf(0.0, blink_left - delta)
		smoke_left = maxf(0.0, smoke_left - delta)
		knives_left = maxf(0.0, knives_left - delta)
		smoke_time = maxf(0.0, smoke_time - delta)
		_idle += delta
		veiled = _idle >= VEIL_IDLE
		dawn_left = maxf(0.0, dawn_left - delta)
		if dawn_left <= 0.0 and wagons_spoiled() < 4 and fire_once(&"E18"):
			say_l(30)
			set_objective(&"obj_wagons", "failed")
			lose(DEFEAT_DELAY)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.25
		if phase == 1:
			_tick_night(0.25)
			_tick_fires(0.25)
			_tick_wagons(0.25)
			_tick_camp(0.25)
		var t := "%s|%s|%s" % [objective_text(&"obj_wagons"), objective_text(&"obj_light"), objective_text(&"sec_unseen")]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
	_tick_light(delta)
