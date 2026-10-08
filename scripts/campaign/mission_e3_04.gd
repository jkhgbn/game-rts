class_name MissionE3_04
extends MissionBase
## Episode 3, mission 4 "The Storm on the Ridge" (docs/design/mission-e3-04.md): the Shadow finale. Evenmead after the
## battle: Malrik (PLAYER, Shadow) + Torvald (ALLY, Ice) hold three ridge watch points against Vessa (ENEMY, Fire) and
## Old Vey, the Master's storm-sword, a hero-boss who cannot die: break his storm three times (A1 5:30, A2 13:00, A3
## 20:00, or 75 s after the previous break) and he leaves the field. The ridge falls if side 1 holds all three points
## for 30 s. The stone's power and hold as e3m3; Torvald hears the stone say his name. Spotlight / titan: the Nightmare
## Knight (Dread Paddock from 4:00).
##
## Built deviations (2026-10-07, recorded in the spec's "Built" note):
## - The Evenmead map of e3m1 built in code (MissionE3_01.make_river, the same nodes / bases); no Nature base (D8).
## - Vey is a Helper (helper_vey kit: Lightning Lunge, Chain, Stormcall come from HelperAbilities) on team ENEMY, bonded
##   to Vessa (he walks with her column in every assault, A2's west column goes without him); 3 600 HP per storm, a
##   death guard turns 0 HP into a break (dormant 3 s, then he rests 75 s on Lark Hill's crest). Thunderhead (storms
##   2-3) is mission-side; no Charged Ground aura, no "spark first" bond.
## - The Dread Paddock is a mission building (button, from 4:00) training a code-built Nightmare Knight (shadow_knight
##   base, the titans/nightmare_knight model); its Charge = +90 and dazed 0.6 s on the first hit after a 6 m run.
## - Heart of the Hollow / the stone's hold: the e3m3 mission-side rules (J / button). No cine timelines; no ep3_ending
##   film (rewards next = e4m1, not built).

const MISSION_ID := &"e3m4"
const MISSION_TITLE := "The Storm on the Ridge"
const PLAYER_SEAT := Unit.Team.PLAYER
const ALLY_SEAT := Unit.Team.ALLY
const FIRE_SEAT := Unit.Team.ENEMY

const MALRIK_START := Vector3(-6.0, 0.0, -40.0)
const HUSH_START := Vector3(-4.0, 0.0, -41.0)
const DUSK_KEEP := Vector3(-12.0, 0.0, -48.0)
const GLOOM_HALL := Vector3(1.0, 0.0, -48.0)
const HOVELS: Array[Vector3] = [Vector3(-14.0, 0.0, -38.0), Vector3(-24.0, 0.0, -52.0)]
const NIGHT_SPIRE := Vector3(-8.0, 0.0, -32.0)
const PADDOCK_SPOT := Vector3(-28.0, 0.0, -44.0)
const SHADOW_RALLY := Vector3(-4.0, 0.0, -28.0)
const RIME_KEEP := Vector3(28.0, 0.0, -48.0)
const RIME_HALL := Vector3(16.0, 0.0, -45.0)
const TORVALD_POST := Vector3(40.0, 0.0, -24.0)
const FIRE_KEEP := Vector3(20.0, 0.0, 50.0)
const EMBER_HALL := Vector3(34.0, 0.0, 40.0)
const HEARTHS: Array[Vector3] = [Vector3(8.0, 0.0, 53.0), Vector3(31.0, 0.0, 55.0)]
const EMBER_SPIRES: Array[Vector3] = [Vector3(6.0, 0.0, 31.0), Vector3(20.0, 0.0, 34.0)]
const FIRE_RALLY := Vector3(12.0, 0.0, 26.0)
const VEY_REST := Vector3(-4.0, 0.0, 34.8)
const WATCH := {&"W1": ["Bishop's Crest", Vector3(0.0, 0.0, -36.0)], &"W2": ["Reed Watch", Vector3(-34.0, 0.0, -22.0)],
		&"W3": ["Birch Watch", Vector3(40.0, 0.0, -22.0)]}
const FORD_SOUTH := {&"west": Vector3(-44.0, 0.0, 8.0), &"centre": Vector3(6.0, 0.0, 8.0), &"east": Vector3(50.0, 0.0, 8.0)}
## e3m1's node amounts (doubled-ish from the spec: 14 Thralls mine ~550 crystals a minute).
const NODES := [
	[&"e3_dusk_a", Vector3(-21.0, 0.0, -45.0), 3000], [&"e3_dusk_b", Vector3(-6.0, 0.0, -56.0), 3000],
	[&"e3_ridge_w", Vector3(-48.0, 0.0, -32.0), 3500], [&"e3_reedfield", Vector3(-24.0, 0.0, -14.0), 3500],
	[&"e3_rime_a", Vector3(37.0, 0.0, -46.0), 1500], [&"e3_rime_b", Vector3(27.0, 0.0, -57.0), 1500],
	[&"e3_ember_a", Vector3(27.0, 0.0, 46.0), 1500], [&"e3_ember_b", Vector3(16.0, 0.0, 58.0), 1500],
]
const ASSAULT_AT: Array[float] = [330.0, 780.0, 1200.0]
const BREAK_GAP := 75.0
const PULL_BACK := 360.0
const RAID_FIRST := 180.0
const RAID_EVERY := 150.0
const PADDOCK_AT := 240.0
const PADDOCK_COST := 300
const VEY_HP := 3600.0
const VEY_ARMOR := 25.0
const VEY_LEVEL := 5   ## The helper kit scales with level: at 8 his Chain / Stormcall cut a 40-unit army to 4 in A1
const KNEEL := 3.0
const REST := 75.0
const BREAK_ESSENCE := 200
const BREAK_XP := 250
const THUNDER_EVERY := 30.0
const THUNDER_WARN := 3.0
const THUNDER_TIME := 10.0
const THUNDER_DPS := 25.0
const RIDGE_FALL := 30.0
const WATCH_R := 6.0
const WATCH_TIME := 12.0
const CHARGE_RUN := 6.0
const CHARGE_DAMAGE := 90.0
const TORVALD_NEAR := 30.0
const HEART_COOLDOWN := 45.0
const HEART_R := 14.0
const HEART_DAMAGE := 60.0
const HOLD_PER_USE := 20.0
const HOLD_PER_DEATH := 0.5
const HOLD_RESET := 60.0
const HELD_SECONDS := 5.0
const LEVEL_CAP := 8
const NO_SAVE_ESSENCE := 900
const ESSENCE_CAP := 1500
const DEFEAT_DELAY := 3.0
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [600, 450, 350]
const MALRIK_SPELLS := [&"shadow_lance", &"shadow_lance", &"soul_siphon", &"soul_siphon", &"umbral_shroud"]
const TORVALD_SPELLS := [&"rime_bolt", &"rime_bolt", &"flash_freeze", &"flash_freeze", &"rime_aegis"]
const VESSA_SPELLS := [&"fireball", &"fireball", &"ember_step", &"ember_step", &"kindle"]

const WAVES := {
	&"RAID": [["blaze_rider", 3]],
	&"A1": [["flame_guard", 5], ["ember_archer", 3], ["blaze_rider", 2]],
	&"A2W": [["flame_guard", 4], ["ember_archer", 2], ["pyre_adept", 2], ["kilnwarden", 1]],
	&"A2E": [["flame_guard", 3], ["ember_archer", 2], ["cinder_arbalest", 2]],
	&"A3C": [["flame_guard", 4], ["ash_hurler", 2], ["cinder_arbalest", 2], ["kilnwarden", 1]],
	&"A3W": [["flame_guard", 4], ["ember_archer", 2], ["pyre_adept", 1], ["blaze_rider", 2]],
	&"A3E": [["flame_guard", 3], ["ember_archer", 2], ["blaze_rider", 1]],
}

const SPEAKER_COLORS := {&"malrik": Color(0.7, 0.3, 1.0), &"hush": Color(0.60, 0.50, 0.75),
		&"torvald": Color(0.55, 0.80, 1.00), &"vey": Color(0.95, 0.95, 0.55), &"vessa": Color(1.0, 0.45, 0.1),
		&"obren": Color(1.0, 0.80, 0.25), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"malrik": "Malrik", &"hush": "Mother Hush", &"torvald": "Torvald", &"vey": "Old Vey",
		&"vessa": "Vessa", &"obren": "Obren", &"narrator": "Narrator"}
## L1-L32 (index n - 1), then L6b = 33.
const DIALOGUE := [
	[&"narrator", "Three days later. Malrik came back from Duskbarrow to a ridge that smelled of thunder."],
	[&"torvald", "Every dusk the old man walks down to the river and looks at us. Then he walks away."],
	[&"malrik", "Looks. Not crosses?"],
	[&"torvald", "Not yet. I think he was waiting for you. He is polite like that."],
	[&"hush", "Riders at the reeds. Quick little sparks."],
	[&"vey", "Bishop! You sent your knife into my girl's camp twice now. I've come to return the favour."],
	[&"malrik", "Old man. They told me you were dead. I was almost sad."],
	[&"vessa", "He's not dead, he's LATE. There's a difference!"],
	[&"hush", "Old man. You still owe me a night."],
	[&"vey", "And you still miss, knife-woman. Every single time."],
	[&"vey", "Hah! Good. Again!"],
	[&"malrik", "He is laughing. Why is he laughing?"],
	[&"vey", "Off my hill. Well. Your hill. For now."],
	[&"vessa", "Both fords, Vey! We pinch him!"],
	[&"vey", "The spark first. Then the storm!"],
	[&"torvald", "Malrik. That light in your hand. It moved before you did."],
	[&"obren", "Torvald. Old frost. You feel it too. Join us, and nothing will ever melt."],
	[&"torvald", "...It knows my name."],
	[&"malrik", "It knows everyone's name. It is a stone with nothing else to do."],
	[&"vey", "Last storm I've got, Bishop. Let's see what you've got."],
	[&"malrik", "Everything, old man. I took it all. That is the whole secret."],
	[&"torvald", "They have a watch. Take it back, or the ridge goes with it."],
	[&"vey", "That's enough. My storm is borrowed, and I've spent the loan."],
	[&"vessa", "Vey! Get up! We're not done!"],
	[&"vey", "We are today, girl. Today the ridge is his."],
	[&"malrik", "The ridge is mine. The valley next. I will not stop."],
	[&"torvald", "No. I don't think you can."],
	[&"narrator", "The ridge fell to Shadow. Torvald had heard the stone say his name. He did not forget it."],
	[&"malrik", "Struck down... by an old man's weather."],
	[&"narrator", "Fire and thunder took the ridge, and the Bishop's winter melted away."],
	[&"vessa", "Ow! Fine! Back in a minute!"],
	[&"malrik", "Even thunder falls off a horse, old man."],
	[&"vey", "Bishop! Not one alarm, that night. Your knife is getting better. So am I."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Three days Malrik spent laying his dead back down in Duskbarrow. Three evenings an old man with a burning sword walked down to the river and looked at Torvald's winter on the ridge, and walked away again.",
	"Ysolde has taken her people south, out of the war. Vessa has stayed, with every soldier she has left and the one ally who has never lost a duel: Old Vey, the Master's storm-sword. Today they cross.",
	"Hold the ridge. You cannot kill a storm, but you can wear one out. And Torvald is watching the stone in your pocket more closely than he watches the river.",
]
const BRIEFING_LINE := "Old Vey cannot die. Break his storm three times and he will leave the field."
const HINT_START := "Hold the three watch points. Old Vey cannot die: break his storm three times and he will leave."
const HINT_PADDOCK := "A Dread Paddock can now be raised (the \"Raise the Dread Paddock\" button): it trains the Nightmare Knight, a titan whose charge can break a storm."
const HINT_KNIGHT := "Nightmare Knight: it charges after a 6 m run. Lunge as he likes, the old man can't stop a horse."
const HINT_THUNDER := "A storm cloud over a watch point: get off it for 10 s, then take it back."
const MSG_BREAK := "Old Vey's storm breaks! He will be back."
const MSG_RIDGE := "The ridge is falling: retake a watch point! %d:%02d"
const MSG_TORVALD_FELL := "Torvald falls back to the ridge"
const BUTTON_PADDOCK := "Raise the Dread Paddock (300)"
const BUTTON_HEART := "Heart of the Hollow (J)"
const REFUSE_EARLY := "Not yet (4:00)"
const REFUSE_BUILT := "Already built"
const REFUSE_CRYSTALS := "Not enough crystals"
const REFUSE_WORKER := "No free Gloom Thrall"
const REFUSE_SPOT := "No room for the Paddock"
const REFUSE_DEAD := "Dead"
const REFUSE_HELD := "The stone holds you"
const REFUSE_RECHARGING := "Recharging"

var flag_override: Dictionary = {}

## Read only.
var watch := {}                        ## id -> MissionZone
var vey: Helper = null
var vessa: Wizard = null
var torvald: Wizard = null
var hush: Helper = null
var breaks := 0
var storm := 0                         ## 1-3 while Vey is on the field (the storm he fights with)
var vey_state := &"away"               ## away / fighting / kneeling / resting
var assault := 0                       ## assaults launched (a 4th+ repeats A3 after a pull-back)
var spent := 0                         ## assaults over (a break or a pull-back)
var assault_started := -1.0
var ridge_left := -1.0                 ## the 30 s countdown (-1 = off)
var paddock: Building = null
var knights := 0
var knight_charged := false
var stone_hold := 0.0
var shard_uses := 0
var seizures := 0
var heart_left := 0.0
var held_left := 0.0
var waves_fired: Array[StringName] = []
var said: Array[int] = []
var victory_time := -1.0

var _said := {}
var _tick := 0.0
var _zone_tick := 0.0
var _raid_i := 0
var _vey_timer := 0.0
var _last_break_at := -1.0
var _launch_pending := false
var _thunder_left := THUNDER_EVERY
var _thunder_at := Vector3.INF
var _thunder_time := 0.0
var _assault_units: Array = []
var _knight_type: UnitType
var _paddock_type: BuildingType
var _river: RiverSystem
var _run := {}                         ## knight -> [last position, metres run since its last hit]
var _panel: Control
var _last_obj_text := ""


func _init() -> void:
	super()
	player_kingdom = &"shadow"
	enemy_kingdom = &"fire"
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
	define_objectives([[&"obj_storm", "primary"], [&"obj_ridge", "primary"], [&"obj_malrik", "primary"],
			[&"sec_knight", "secondary"], [&"sec_refuse", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Dusk Keep has fallen"
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {PLAYER_SEAT: 3, ALLY_SEAT: 2, FIRE_SEAT: 2}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.titans_enabled = true
	c.lair_min_time = PADDOCK_AT
	c.start_level = 6
	c.start_spell_points = 1
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 150
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe ridge is Malrik's"
	c.defeat_banner = "DEFEAT"
	c.seat_sides = {PLAYER_SEAT: 0, ALLY_SEAT: 0, FIRE_SEAT: 1}
	c.seat_opponents = {FIRE_SEAT: PLAYER_SEAT, ALLY_SEAT: FIRE_SEAT, PLAYER_SEAT: FIRE_SEAT}
	c.seat_kingdoms = {PLAYER_SEAT: &"shadow", ALLY_SEAT: &"ice", FIRE_SEAT: &"fire"}
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"nightmare_knight", "trigger": &"unlock", "key_hint": "Dread Paddock: Z",
			"card": "Nightmare Knight. A titan at a gallop: its charge breaks a line, or a storm."}
	return c


func _map_size() -> Vector2:
	return Vector2(MissionE3_01.MAP_W, MissionE3_01.MAP_D)


func _player_start() -> Vector3:
	return MALRIK_START


func _use_map_dressing() -> bool:
	return false


func _title_line() -> String:
	return "Episode 3, Mission 4: %s" % MISSION_TITLE


func _ready() -> void:
	_knight_type = _make_knight_type()
	_paddock_type = _make_paddock_type()
	get_tree().node_added.connect(_on_e34_node_added)
	super()
	if camera_rig:
		camera_rig.focus_on(MALRIK_START)
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_e34_node_added):
		get_tree().node_added.disconnect(_on_e34_node_added)


## The Nightmare Knight (cavalry-mounts.md 3 / 5): 400, pop 4, 50 s; the shadow_knight base, scaled to a titan rider.
func _make_knight_type() -> UnitType:
	var base := UnitType.find("shadow_knight")
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.id = &"nightmare_knight"
	t.display_name = "Nightmare Knight"
	t.faction = &"shadow"
	t.cost = 400
	t.pop = 4
	t.train_time = 50.0
	t.max_hp = 1300.0
	t.armor = 20.0
	t.attack_damage = 34.0
	t.attack_cooldown = 1.6
	t.move_speed = 6.5
	t.kill_xp = 260
	t.requires_tier = 3
	t.card_key = "Z"
	t.radius = 1.0
	t.body_height = 3.0
	var model := "res://art/units/titans/nightmare_knight/nightmare_knight.tscn"
	if ResourceLoader.exists(model):
		t.model_scene = load(model) as PackedScene
		t.model_path = model
	return t


func _make_paddock_type() -> BuildingType:
	var base := BuildingType.find("shadow_barracks")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.id = &"shadow_lair"
	t.display_name = "Dread Paddock"
	t.cost = PADDOCK_COST
	t.build_time = 70.0
	t.max_hp = 1500.0
	t.max_count = 1
	var trains: Array[UnitType] = []
	if _knight_type:
		trains.append(_knight_type)
	t.trains = trains
	return t


func _on_e34_node_added(node: Node) -> void:
	var u := node as Unit
	if u != null and _knight_type != null and u.unit_type == _knight_type:
		_on_knight.call_deferred(u)


# ---------------------------------------------------------------- seats and the map

func start_position(team: int) -> Vector3:
	match team:
		ALLY_SEAT:
			return TORVALD_POST
		FIRE_SEAT:
			return FIRE_RALLY
	return MALRIK_START


func base_center(team: int) -> Vector3:
	if seat_bases.has(team):
		return seat_bases[team]
	match team:
		ALLY_SEAT:
			return RIME_KEEP
		FIRE_SEAT:
			return FIRE_KEEP
	return DUSK_KEEP


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	if k:
		return k.spawn_point()
	return base_center(team) + Vector3(4.0, 0.0, 4.0)


func node_of(team: int, suffix: String) -> CrystalNode:
	var prefix := {PLAYER_SEAT: "e3_dusk_", ALLY_SEAT: "e3_rime_", FIRE_SEAT: "e3_ember_"}
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
	_river = MissionE3_01.make_river(nav_region, MALRIK_START)
	var mat := _ground_material()
	if mat:
		EnvProps.set_river(mat, _river.shader_params())
	keep = build_grid.spawn_complete(BuildingType.find("shadow_keep"), DUSK_KEEP, PLAYER_SEAT) as Keep
	build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL, PLAYER_SEAT)
	for p in HOVELS:
		build_grid.spawn_complete(BuildingType.find("shadow_hovel"), p, PLAYER_SEAT)
	build_grid.spawn_complete(BuildingType.find("shadow_tower"), NIGHT_SPIRE, PLAYER_SEAT)
	seat_bases[PLAYER_SEAT] = DUSK_KEEP
	var rk := build_grid.spawn_complete(BuildingType.find("ice_keep"), RIME_KEEP, ALLY_SEAT) as Keep
	build_grid.spawn_complete(BuildingType.find("ice_barracks"), RIME_HALL, ALLY_SEAT)
	if rk:
		seat_keeps[ALLY_SEAT] = rk
	seat_bases[ALLY_SEAT] = RIME_KEEP
	seat_starts[ALLY_SEAT] = TORVALD_POST
	var fk := build_grid.spawn_complete(BuildingType.find("fire_keep"), FIRE_KEEP, FIRE_SEAT) as Keep
	var eh := build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL, FIRE_SEAT)
	if eh:
		eh.set_meta(&"e3m4_hall", true)
	for p in HEARTHS:
		build_grid.spawn_complete(BuildingType.find("fire_hearth"), p, FIRE_SEAT)
	for p in EMBER_SPIRES:
		build_grid.spawn_complete(BuildingType.find("fire_tower"), p, FIRE_SEAT)
	shadow_keep = fk
	seat_bases[FIRE_SEAT] = FIRE_KEEP
	seat_starts[FIRE_SEAT] = FIRE_RALLY
	MissionE3_01.add_golden_tree(self)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for team: int in [PLAYER_SEAT, ALLY_SEAT, FIRE_SEAT]:
		for p: Vector3 in [MissionE3_01.FORD_STONE, MissionE3_01.FORD_REED, MissionE3_01.FORD_BIRCH, VEY_REST]:
			fog.reveal(team, p, 6.0)
		for id: StringName in WATCH:
			fog.reveal(team, WATCH[id][1], 8.0)
	_setup_champions()
	hero = _make_wizard(PLAYER_SEAT)
	_spawn(hero, PLAYER_SEAT, MALRIK_START)
	_claim_wizard(hero, PLAYER_SEAT)
	ItemDrops.ensure_inventory(hero)
	raise_wizard(hero, 6, MALRIK_SPELLS)
	set_meta(&"campaign_flags", flag_override.duplicate())
	force_artifacts(hero, ["keystone_shard", ""])
	_carry_essence()
	for i in 7:
		var w := _spawn(make_unit("gloom_thrall"), PLAYER_SEAT, DUSK_KEEP + Vector3(-4.0 + i * 1.3, 0.0, 6.0))
		w.call(&"command_gather", node_of(PLAYER_SEAT, "a" if i < 4 else "b"))
	var rows := [["shade", 6], ["nightbolt", 3], ["shadow_knight", 2], ["hexweaver", 2], ["gloom_deacon", 1],
			["nightblood_reaver", 2]]
	var k := 0
	for row: Array in rows:
		for j in int(row[1]):
			_spawn(make_unit(String(row[0])), PLAYER_SEAT, SHADOW_RALLY + Vector3((k % 6) * 1.6 - 4.0, 0.0, (k / 6) * 1.7))
			k += 1
	hush = _story_hush()
	var ice := activate_seat(ALLY_SEAT, &"ice", {"crystals": 300,
			"workers": [["rime_hauler", 3, node_of(ALLY_SEAT, "a")], ["rime_hauler", 2, node_of(ALLY_SEAT, "b")]],
			"units": [["rimeshield", 5, TORVALD_POST], ["shardcaster", 3, TORVALD_POST], ["frost_mortar", 1, TORVALD_POST],
					["rimecarver", 1, TORVALD_POST]],
			"wizard": {"level": 6, "spells": TORVALD_SPELLS, "pos": TORVALD_POST + Vector3(0.0, 0.0, -3.0)}})
	torvald = ice.get("wizard") as Wizard
	if torvald:
		torvald.level_cap = 6
		torvald.died.connect(_on_bot_wizard_died.bind(ALLY_SEAT))
	for u: Variant in ice.get("units", []):
		_hold_birch(u as Unit)
	_add_seat_commander(ALLY_SEAT)
	var fire := activate_seat(FIRE_SEAT, &"fire", {"crystals": 300,
			"workers": [["cinder_hand", 3, node_of(FIRE_SEAT, "a")], ["cinder_hand", 3, node_of(FIRE_SEAT, "b")]],
			"units": [["flame_guard", 8, FIRE_RALLY], ["ember_archer", 4, FIRE_RALLY]],
			"wizard": {"level": 6, "spells": VESSA_SPELLS, "pos": FIRE_RALLY}})
	vessa = fire.get("wizard") as Wizard
	shadow_hero = vessa
	if vessa:
		vessa.level_cap = int(by_difficulty([6, 6, 7]))
		mark_scripted(vessa)
		vessa.died.connect(_on_bot_wizard_died.bind(FIRE_SEAT))
	_add_seat_commander(FIRE_SEAT)
	wizard_respawned.connect(_on_e34_wizard_respawned)
	for id: StringName in WATCH:
		var z := MissionZone.new()
		z.zone_id = id
		z.display_name = String(WATCH[id][0])
		z.radius = WATCH_R
		z.capture_time = WATCH_TIME
		z.has_pole = true
		z.time_factor = {0: 1.0, 1: 1.25}
		add_child(z)
		z.global_position = WATCH[id][1]
		z.set_owner_side(0)
		z.neutralised.connect(_on_watch_lost)
		watch[id] = z
	var ch := AllyChannel.instance(get_tree(), self)
	if ch:
		ch.time_source = mission_time
	_add_events()
	begin_mission([&"obj_storm", &"obj_ridge", &"obj_malrik", &"sec_refuse"])
	_build_panel()


func _carry_essence() -> void:
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	if bank == null:
		return
	var cs := CampaignState.open(campaign_save_path)
	var fallback := not cs.is_completed(&"e3m3") and flag_override.is_empty()
	var carried := int(flag_override.get(CampaignState.MALRIK_ESSENCE_FLAG, cs.flag_value(CampaignState.MALRIK_ESSENCE_FLAG, 0)))
	bank.add(NO_SAVE_ESSENCE if fallback else carried)


func _flag(name: String) -> Variant:
	if flag_override.has(name):
		return flag_override[name]
	return CampaignState.open(campaign_save_path).flag_value(name, null)


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
	hp.died.connect(func(_u: Unit) -> void:
		after(45.0, func() -> void:
			if is_instance_valid(hp) and not hp.is_alive() and not is_ending():
				hp.respawn(respawn_point(PLAYER_SEAT))))
	return hp


func _hold_birch(u: Unit) -> void:
	if u == null:
		return
	mark_scripted(u)
	u.set_meta(META_HOME, TORVALD_POST + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-3.0, 3.0)))
	if not _guards.has(u):
		_guards.append(u)


func seat_profile(seat: int) -> AIProfile:
	var diff := clampi(mission_difficulty, 0, 2)
	var p: AIProfile = AIProfile.ice(diff) if seat == ALLY_SEAT else AIProfile.for_difficulty(diff)
	p.id = StringName("mission_e3_04_%s" % ("ally" if seat == ALLY_SEAT else "enemy"))
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
	p.max_soldiers = 10 if seat == ALLY_SEAT else 12
	p.build_rows = PackedStringArray(["H1", "V1"])
	p.rebuild = false
	p.hero_stays_home = true
	p.malrik_joins = AIProfile.MalrikJoins.NEVER
	p.champion_max = 0
	p.trade = false
	p.map_fill = false
	if seat != ALLY_SEAT:
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
	bot.name = "ShadowBot" if seat == FIRE_SEAT else "Bot%d" % seat
	bot.set(&"team", seat)
	bot.set(&"profile", seat_profile(seat))
	add_child(bot)
	commanders.append(bot)
	return bot


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_storm", false), objective_text(&"obj_ridge", false),
				objective_text(&"obj_malrik", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_malrik")),
	}


func watch_owned(side := 0) -> int:
	var n := 0
	for id: StringName in watch:
		if (watch[id] as MissionZone).owner_side == side:
			n += 1
	return n


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_storm":
			if with_counter:
				return "%s\n%s" % ["Break Old Vey's storm (%d / 3)" % breaks, "The stone's hold: %d %%" % int(stone_hold)]
			return "Break Old Vey's storm"
		&"obj_ridge":
			if with_counter:
				if ridge_left >= 0.0:
					var s := int(ceil(ridge_left))
					return MSG_RIDGE % [s / 60, s % 60]
				return "Hold the ridge watch points (%d / 3)" % watch_owned()
			return "Hold the ridge watch points"
		&"obj_malrik":
			return "Malrik must survive"
		&"sec_knight":
			return "Ride down the storm: hit Old Vey with a Nightmare Knight's charge"
		&"sec_refuse":
			return "Refuse the stone again: win without its power"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_storm":
			return {"counter": breaks, "goal": 3}
		&"obj_ridge":
			if ridge_left >= 0.0:
				return {"countdown": ridge_left}
			return {"counter": watch_owned(), "goal": 3}
	return {}


func say_l(n: int) -> void:
	if _said.has(n):
		return
	_said[n] = true
	said.append(n)
	say_line(n)


# ---------------------------------------------------------------- events

## E1: the return (e3m4_return, HOLD 0:20 played as PAUSE; fallback = the camera on Malrik + L1-L4), the start hint.
func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e3m4_return", func() -> void:
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position)
		for n in [1, 2, 3, 4]:
			say_l(n)
		if hud:
			hud.show_message(HINT_START, 10.0))


func _add_events() -> void:
	after(RAID_FIRST, _raid)
	after(PADDOCK_AT, func() -> void:
		if is_ending():
			return
		fire_once(&"E3")
		set_objective(&"sec_knight", "active")
		show_spotlight()
		if hud:
			hud.show_message(HINT_PADDOCK, 12.0))
	after(ASSAULT_AT[0], _launch_assault)
	add_event(&"E5", func() -> bool: return vey != null and is_instance_valid(vey) and vey_state == &"fighting" \
			and hush != null and is_instance_valid(hush) and hush.is_alive() and _flat(vey.global_position, hush.global_position) <= 12.0,
			func() -> void:
				say_l(9)
				say_l(10))


func _raid() -> void:
	if is_ending() or has_fired(&"E15"):
		return
	after(RAID_EVERY, _raid)
	if fire_once(&"E2"):
		say_l(5)
	var ford: Vector3 = FORD_SOUTH[&"west"] if _raid_i % 2 == 0 else FORD_SOUTH[&"east"]
	_raid_i += 1
	for u in spawn_wave_at(WAVES[&"RAID"], _hall_spawn(), FIRE_SEAT):
		(u as Unit).set_meta(&"via", ford)
		order_wave(u as Unit, &"raid", ford)


func _hall_spawn() -> Vector3:
	for b in Building.for_team(FIRE_SEAT):
		if b.is_alive() and b.has_meta(&"e3m4_hall") and b is TrainingBuilding:
			return (b as TrainingBuilding).spawn_point()
	return FIRE_RALLY


## The next assault: A1 at 5:30; A2 / A3 at their clock or 75 s after the previous break, whichever is later.
func _launch_assault() -> void:
	if is_ending() or has_fired(&"E15") or _launch_pending:
		return
	if spent < assault:
		return   # Vey still fights the previous one: its break or its pull-back calls this again
	var next_at: float = ASSAULT_AT[mini(assault, 2)]
	if _last_break_at >= 0.0:
		next_at = maxf(next_at, _last_break_at + BREAK_GAP)
	if mission_time() < next_at - 0.5:
		_launch_pending = true
		after(next_at - mission_time(), func() -> void:
			_launch_pending = false
			_launch_assault())
		return
	assault += 1
	assault_started = mission_time()
	storm = mini(breaks + 1, 3)
	_assault_units.clear()
	match mini(assault, 3):
		1:
			fire_once(&"E4")
			_column(&"A1", &"centre", &"W1")
			say_l(33 if _flag("e3m2_alarms") != null and int(_flag("e3m2_alarms")) == 0 else 6)
			say_l(7)
			say_l(8)
		2:
			fire_once(&"E9")
			_column(&"A2W", &"west", &"W2")
			_column(&"A2E", &"east", &"W3")
			say_l(14)
			say_l(15)
		3:
			fire_once(&"E12")
			if vessa and is_instance_valid(vessa):
				vessa.level_cap = int(by_difficulty([6, 7, 7]))
				raise_wizard(vessa, vessa.level_cap, [])
			_column(&"A3C", &"centre", &"W1")
			_column(&"A3W", &"west", &"W2")
			_column(&"A3E", &"east", &"W3")
			say_l(20)
			say_l(21)
	_carry_vessa()
	_vey_arrives()
	var n := assault
	after(PULL_BACK, func() -> void: _pull_back(n))


func _column(id: StringName, ford: StringName, target: StringName) -> void:
	var units := spawn_wave_at(WAVES[id], _hall_spawn(), FIRE_SEAT)
	for u in units:
		(u as Unit).set_meta(&"via", FORD_SOUTH[ford])
		(u as Unit).set_meta(&"watch", target)
		order_wave(u as Unit, &"assault", FORD_SOUTH[ford])
	_assault_units.append_array(units)


func _carry_vessa() -> void:
	if vessa == null or not is_instance_valid(vessa) or not vessa.is_alive():
		return
	var target := &"W1" if assault != 2 else &"W3"
	vessa.set_meta(&"watch", target)
	vessa.set_meta(&"via", FORD_SOUTH[&"centre"] if target == &"W1" else FORD_SOUTH[&"east"])
	order_wave(vessa, &"assault", vessa.get_meta(&"via"))


## Old Vey takes the field (a white-gold bolt on the crest): the helper_vey kit at storm strength, bonded to Vessa.
func _vey_arrives() -> void:
	if vey == null:
		var ht := HelperType.find(&"helper_vey")
		if ht == null:
			return
		vey = Helper.new()
		vey.apply_helper_type(ht, VEY_LEVEL)
		vey.name = "VeyStorm"
		_spawn(vey, FIRE_SEAT, VEY_REST)
		vey.add_to_group(&"boss")
		vey.add_to_group(&"titans")
		mark_scripted(vey)
		vey.death_guard = _on_vey_lethal
	else:
		set_dormant(vey, false)
		vey.global_position = VEY_REST
	vey.set_base_stat(&"max_hp", VEY_HP)
	vey.set_base_stat(&"armor", VEY_ARMOR)
	vey.hp = vey.max_hp
	vey.remove_modifier(&"storm:power")
	if storm >= 2:
		vey.add_modifier(&"storm:power", {"attack_damage_pct": 0.1 * float(storm - 1)})
	if vessa and is_instance_valid(vessa) and vessa.is_alive():
		vey.bond_to(vessa)
		vey.set_stance(&"escort")
	vey_state = &"fighting"
	_thunder_left = THUNDER_EVERY
	flash_ring(VEY_REST, 4.0)


## Vey's death guard: 0 HP is a break, never a death.
func _on_vey_lethal(_attacker: Variant) -> bool:
	vey.hp = vey.max_hp
	if vey_state == &"fighting":
		_break_storm.call_deferred()
	return true


## A break: he kneels 3 s (dormant), a bolt carries him to the crest, he rests 75 s; +200 essence, +250 XP to Malrik.
func _break_storm() -> void:
	if vey_state != &"fighting" or is_ending():
		return
	breaks += 1
	_last_break_at = mission_time()
	vey_state = &"kneeling"
	set_dormant(vey, true)
	vey.command_stop()
	if hud:
		hud.show_message(MSG_BREAK, 4.0)
	flash_ring(vey.global_position, 3.0)
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	if bank:
		bank.add(BREAK_ESSENCE)
	if hero_alive():
		hero.add_xp(BREAK_XP)
	set_objective(&"obj_storm", "active")
	match breaks:
		1:
			fire_once(&"E6")
			say_l(11)
			say_l(12)
		2:
			fire_once(&"E11")
			play_cutscene(&"e3m4_whisper", func() -> void:
				say_l(17)
				say_l(18)
				say_l(19))
		3:
			_withdraw_all()
			return
	after(KNEEL, func() -> void:
		if vey and is_instance_valid(vey) and not is_ending():
			vey.global_position = VEY_REST
			vey_state = &"resting")
	spent += 1
	_launch_assault()


## An assault 6:00 old with Vey unbroken pulls back (no break counted); the next assault keeps its clock.
func _pull_back(n: int) -> void:
	if is_ending() or assault != n or spent >= n:
		return
	spent += 1
	for u: Variant in _assault_units:
		if is_instance_valid(u) and (u as Unit).is_alive():
			(u as Unit).set_meta(META_MODE, &"home")
			(u as Unit).command_move(FIRE_RALLY)
	if vey and is_instance_valid(vey) and vey_state == &"fighting":
		vey_state = &"resting"
		set_dormant(vey, true)
		vey.global_position = VEY_REST
	_launch_assault()


## E15: the third break: everyone of Fire walks home, e3m4_field, victory.
func _withdraw_all() -> void:
	fire_once(&"E15")
	victory_time = mission_time()
	set_objective(&"obj_storm", "done")
	_record_flags()
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == FIRE_SEAT and not u.is_worker():
			set_truce([u], true, Unit.TRUCE_ALL)
			u.command_move(FIRE_RALLY)
	play_cutscene(&"e3m4_field", func() -> void:
		for l in [23, 24, 25, 26, 27, 28]:
			say_l(l)
		set_objective(&"obj_ridge", "done")
		set_objective(&"obj_malrik", "done")
		if objective_state("sec_refuse") == "active":
			set_objective(&"sec_refuse", "done")
		if objective_state("sec_knight") == "active":
			set_objective(&"sec_knight", "failed")
		win(2.0))


func _record_flags() -> void:
	set_mission_flag("e3m4_shard_uses", shard_uses)
	set_mission_flag("e3m4_seizures", seizures)
	set_mission_flag("e3m4_time", int(victory_time))
	add_track_counter("shadow_stone_uses", shard_uses)
	var e3m3_refused: Variant = _flag("e3m3_refused")
	set_mission_flag("shadow_never_used", shard_uses == 0 and e3m3_refused == true)
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	var essence := bank.essence if bank else 0
	if shard_uses == 0:
		essence += 300
	if knight_charged:
		essence += 300
	set_mission_flag(CampaignState.MALRIK_ESSENCE_FLAG, mini(ESSENCE_CAP, essence / 2))


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	match mode:
		&"assault":
			if u.attack_target != null:
				return true
			var via: Vector3 = u.get_meta(&"via", FIRE_RALLY)
			if not u.has_meta(&"crossed"):
				if _flat(u.global_position, via) <= 5.0 or u.global_position.z < 0.0:
					u.set_meta(&"crossed", true)
				elif not u.is_attack_moving():
					u.command_attack_move(via)
				return true
			var z := watch.get(u.get_meta(&"watch", &"W1")) as MissionZone
			var to := z.global_position if z else WATCH[&"W1"][1]
			if z and z.owner_side == 1:
				to = _nearest_side0_watch(u.global_position)
			if _flat(u.global_position, to) > 3.0 and not u.is_attack_moving():
				u.command_attack_move(to)
			return true
		&"raid":
			if u.attack_target == null and not u.is_attack_moving():
				var ws := workers_of(PLAYER_SEAT) + workers_of(ALLY_SEAT)
				var best := _nearest_side0_watch(u.global_position)
				var d := INF
				for w in ws:
					var dd := _flat(w.global_position, u.global_position)
					if dd < d:
						d = dd
						best = w.global_position
				u.command_attack_move(best)
			return true
		&"home":
			return true
	return false


func _nearest_side0_watch(from: Vector3) -> Vector3:
	var best: Vector3 = WATCH[&"W1"][1]
	var d := INF
	for id: StringName in watch:
		var z := watch[id] as MissionZone
		if z.owner_side == 1:
			continue
		var dd := _flat(z.global_position, from)
		if dd < d:
			d = dd
			best = z.global_position
	return best


# ---------------------------------------------------------------- watch points and the ridge

func _on_watch_lost(_z: MissionZone, side: int) -> void:
	if side == 0 and fire_once(&"E13"):
		say_l(22)


func _tick_ridge(dt: float) -> void:
	if watch_owned(1) >= 3:
		if ridge_left < 0.0:
			ridge_left = RIDGE_FALL
			fire_once(&"E14")
		ridge_left -= dt
		if ridge_left <= 0.0 and fire_once(&"E18"):
			say_l(30)
			set_objective(&"obj_ridge", "failed")
			lose(DEFEAT_DELAY)
	else:
		ridge_left = -1.0


## The running Thunderhead's centre (its warning or its bolts), else Vector3.INF.
func thunder_ring() -> Vector3:
	return _thunder_at if _thunder_time > 0.0 else Vector3.INF


## Thunderhead (storms 2-3): every 30 s the side-0 watch point with the most side-0 units within 6 m (ties: W1): a 3 s
## warning ring, then 10 s of 25 damage per second to every side-0 unit inside.
func _tick_thunder(dt: float) -> void:
	if vey_state != &"fighting" or storm < 2:
		_thunder_time = 0.0
		return
	if _thunder_time > 0.0:
		_thunder_time -= dt
		if _thunder_time <= THUNDER_TIME:
			for n in get_tree().get_nodes_in_group(&"units"):
				var u := n as Unit
				if u and u.is_alive() and MissionZone.side_of_team(int(u.team)) == 0 and int(u.team) != Unit.Team.NEUTRAL \
						and _flat(u.global_position, _thunder_at) <= WATCH_R:
					u.take_damage(THUNDER_DPS * dt, vey)
		return
	_thunder_left -= dt
	if _thunder_left > 0.0:
		return
	_thunder_left = THUNDER_EVERY
	var best := &"W1"
	var best_n := -1
	for id: StringName in [&"W1", &"W2", &"W3"]:
		var z := watch[id] as MissionZone
		if z.owner_side != 0:
			continue
		var n: int = MissionZone.presence(get_tree(), z.global_position, WATCH_R)[0]
		if n > best_n:
			best_n = n
			best = id
	_thunder_at = (watch[best] as MissionZone).global_position
	_thunder_time = THUNDER_WARN + THUNDER_TIME
	flash_ring(_thunder_at, WATCH_R)
	if fire_once(&"E8"):
		say_l(13)
		if hud:
			hud.show_message(HINT_THUNDER, 8.0)


# ---------------------------------------------------------------- the Paddock, the Knights

func _build_panel() -> void:
	_panel = mission_button_panel("RidgePanel", [
		[Loc.t(BUTTON_PADDOCK), func() -> void:
			var r := raise_paddock()
			if r != "" and hud:
				hud.show_message(r, 3.0)],
		[Loc.t(BUTTON_HEART), func() -> void:
			var r := use_heart()
			if r != "" and hud:
				hud.show_message(r, 3.0)]])


func raise_paddock() -> String:
	if mission_time() < PADDOCK_AT:
		return REFUSE_EARLY
	if paddock != null and is_instance_valid(paddock) and paddock.is_alive():
		return REFUSE_BUILT
	var eco := Economy.for_team(PLAYER_SEAT)
	if eco == null or eco.crystals < PADDOCK_COST:
		return REFUSE_CRYSTALS
	var workers := workers_of(PLAYER_SEAT)
	if workers.is_empty():
		return REFUSE_WORKER
	var spot := build_grid.find_spot(_paddock_type, PADDOCK_SPOT, PLAYER_SEAT)
	if spot == Vector3.INF:
		return REFUSE_SPOT
	paddock = build_grid.place(_paddock_type, spot, PLAYER_SEAT, [workers[0]])
	return "" if paddock != null else REFUSE_SPOT


func _on_knight(u: Unit) -> void:
	if not is_instance_valid(u) or int(u.team) != PLAYER_SEAT:
		return
	knights += 1
	u.add_to_group(&"titans")
	_run[u] = [u.global_position, CHARGE_RUN]
	u.attack_landed.connect(_on_knight_hit.bind(u))
	if fire_once(&"E7") and hud:
		hud.show_message(HINT_KNIGHT, 8.0)


## Charge: the first hit after a 6 m run deals +90 and dazes 0.6 s (bosses 0.3 s).
func _on_knight_hit(target: Node3D, _amount: float, knight: Unit) -> void:
	var row: Array = _run.get(knight, [])
	if row.is_empty() or float(row[1]) < CHARGE_RUN or target == null or not is_instance_valid(target):
		if not row.is_empty():
			row[1] = 0.0
		return
	row[1] = 0.0
	var t := target as Unit
	if t == null:
		return
	t.take_damage(CHARGE_DAMAGE, knight)
	t.apply_status(&"dazed", 0.3 if t.is_in_group(&"boss") else 0.6, true)
	if t == vey and not knight_charged:
		knight_charged = true
		if objective_state("sec_knight") == "active":
			set_objective(&"sec_knight", "done")
		fire_once(&"E20")
		say_l(32)


func _tick_knights() -> void:
	for k: Variant in _run.keys():
		if not is_instance_valid(k) or not (k as Unit).is_alive():
			_run.erase(k)
			continue
		var row: Array = _run[k]
		var p := (k as Unit).global_position
		row[1] = minf(CHARGE_RUN * 2.0, float(row[1]) + _flat(p, row[0]))
		row[0] = p


# ---------------------------------------------------------------- the stone (e3m3 rules)

func use_heart() -> String:
	if not hero_alive():
		return REFUSE_DEAD
	if held_left > 0.0:
		return REFUSE_HELD
	if heart_left > 0.0:
		return REFUSE_RECHARGING
	heart_left = HEART_COOLDOWN
	shard_uses += 1
	flash_ring(hero.global_position, HEART_R)
	var dealt := 0.0
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or not Teams.is_hostile(int(u.team), PLAYER_SEAT) or u.team == Unit.Team.NEUTRAL:
			continue
		if _flat(u.global_position, hero.global_position) > HEART_R:
			continue
		var before := u.hp
		u.take_damage(HEART_DAMAGE, hero)
		dealt += maxf(0.0, before - u.hp)
		u.apply_status(&"dazed", 1.0)
	if dealt > 0.0:
		hero.heal(dealt * 0.5)
	hero.add_modifier(&"item:artifact_1:heart", {"spell_power": 30.0})
	get_tree().create_timer(8.0, false).timeout.connect(func() -> void:
		if is_instance_valid(hero):
			hero.remove_modifier(&"item:artifact_1:heart"))
	if objective_state("sec_refuse") == "active":
		set_objective(&"sec_refuse", "failed")
	if torvald and is_instance_valid(torvald) and torvald.is_alive() and _flat(torvald.global_position, hero.global_position) <= TORVALD_NEAR \
			and fire_once(&"E10"):
		say_l(16)
	add_hold(HOLD_PER_USE)
	return ""


func add_hold(amount: float) -> void:
	stone_hold = minf(100.0, stone_hold + amount)
	if stone_hold >= 100.0 and held_left <= 0.0:
		seizures += 1
		held_left = HELD_SECONDS
		if hero_alive():
			hero.apply_status(&"rooted", HELD_SECONDS, true)
			hero.set_cast_lock(HELD_SECONDS)


func _tick_stone(dt: float) -> void:
	if heart_left > 0.0:
		heart_left = maxf(0.0, heart_left - dt)
	if held_left > 0.0:
		held_left -= dt
		if held_left <= 0.0:
			stone_hold = HOLD_RESET


func _on_any_unit_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or is_ending():
		return
	if int(unit.team) == PLAYER_SEAT and unit != hero and not unit.is_worker() and not unit is Helper:
		add_hold(HOLD_PER_DEATH)


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.physical_keycode == KEY_J and match_started and not game_over:
		var r := use_heart()
		if r != "" and hud:
			hud.show_message(r, 3.0)
		get_viewport().set_input_as_handled()
		return
	super(event)


# ---------------------------------------------------------------- wizards

func _on_bot_wizard_died(_u: Unit, seat: int) -> void:
	if is_ending():
		return
	_respawn_left[seat] = 60.0
	if seat == ALLY_SEAT and hud:
		hud.show_message(MSG_TORVALD_FELL, 4.0)
	if seat == FIRE_SEAT and fire_once(&"E19"):
		say_l(31)


func _on_e34_wizard_respawned(wiz: Wizard) -> void:
	if is_ending():
		return
	if wiz == vessa:
		if vey_state == &"fighting":
			_carry_vessa()
			if vey and is_instance_valid(vey):
				vey.bond_to(vessa)
		else:
			wiz.command_move(FIRE_RALLY)
	elif wiz == torvald:
		wiz.command_attack_move(TORVALD_POST)


func _on_player_hero_fell() -> void:
	fire_once(&"E16")
	say_l(29)
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
	_tick_stone(delta)
	_tick_thunder(delta)
	_zone_tick -= delta
	if _zone_tick <= 0.0:
		_zone_tick = 0.25
		for id: StringName in watch:
			(watch[id] as MissionZone).tick(0.25)
		_tick_ridge(0.25)
		_tick_knights()
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		var t := "%s|%s" % [objective_text(&"obj_storm"), objective_text(&"obj_ridge")]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
