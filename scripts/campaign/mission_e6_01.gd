class_name MissionE6_01
extends MissionE6Base
## Episode 6, mission 1 "A Hundred Winters" (docs/design/mission-e6-01.md): a hundred winters ago the Master leaves the
## Heartfrost with Torvald on Glasswater Mere; Torvald and the fisher girl Aldra keep it through three winters while the
## Hollow's Ruin Wardens climb out of three amber cracks. The ice holds under his army and cracks under theirs.
## Spotlight: the Rimeshield (W1b at the south-west gap).
##
## Built deviations (2026-10-09, from the spec):
## - Glasswater Mere is M2's lake (GlasswaterLake, r 22, Old Ice r 7, floes F0-F7) and M2's 28-snowbank ring with its 4
##   gaps; the rest of the ground is the main.gd generator look with seed 1202 (snow theme), no Lost Caches.
## - Floes: E6Lake = GlasswaterLake with only ENEMY weight (Ruin Warden 2, Breaker 4; 8+ on a floe = the base's weight
##   crack, one every 5 s instead of 4); a break sinks every Warden / Breaker on it (killed, credit Torvald), the
##   Stair-Breaker takes 600; PLAYER units are moved off unhurt. Rime Bolt hits (rime_bolt_hit) and Flash Freeze on a
##   floe with an enemy add a crack; Flash Freeze on open water refreezes it at once.
## - Young Aldra is the helper_aldra Helper (t3-helpers.md numbers at Torvald's level, escort stance, its own abilities)
##   with the young look when the model has it; she carves a Sentinel stone (25 s) while Torvald stands within 8 m and no
##   enemy is within 12 m of it. A fall hides her for 40 s, then she is back at the keep door.
## - Winters: MissionBlizzard (PLAYER sight x 0.6) + ENEMY speed -0.4 (`season:drift`); the light tint stands in for
##   the season ramps. The Frost Hall's Colossus / Frostbow lock is not built (Frost Hall trains its full tier-1 card).
## - Wardens are the `hollow_warden` copy (pop 2 for the floe weight, aggro 9).

const MISSION_ID := &"e6m1"
const MISSION_TITLE := "A Hundred Winters"
const MAP_SEED := 1202

const TORVALD_START := Vector3(-36.0, 0.0, 36.0)
const ALDRA_START := Vector3(-34.0, 0.0, 38.0)
const ARMY_START := Vector3(-32.0, 0.0, 32.0)
const KEEP_POS := Vector3(-43.0, 0.0, 43.0)
const HALL_POS := Vector3(-27.0, 0.0, 45.0)
const HEART_POS := Vector3.ZERO
const LONGHOUSE_POS := Vector3(24.0, 0.0, 44.0)
const SENTINEL_STONES: Array[Vector3] = [Vector3(-26.0, 0.0, 22.0), Vector3(-22.0, 0.0, 26.0)]
const RIDGE_POS := Vector3(-34.0, 0.0, -26.0)
const NODES := [[&"e6_ice_a", Vector3(-46.0, 0.0, 34.0), 1500], [&"e6_ice_b", Vector3(-34.0, 0.0, 46.0), 1500],
		[&"e6_west", Vector3(-50.0, 0.0, 10.0), 2000], [&"e6_south", Vector3(4.0, 0.0, 50.0), 1500]]
const WEST_HALL_SPOT := Vector3(-43.0, 0.0, 12.0)
const SOUTH_HALL_SPOT := Vector3(-3.0, 0.0, 51.0)
const CRACKS := {&"stair_ne": Vector3(43.0, 0.0, -43.0), &"road_w": Vector3(-56.0, 0.0, -30.0),
		&"barrow_n": Vector3(-14.0, 0.0, -46.0), &"shore_e": Vector3(58.0, 0.0, 20.0)}
const RALLY := Vector3(-20.0, 0.0, 20.0)

const BANK_RING := 25.5
const BANK_SIZE := Vector3(5.0, 1.8, 2.5)
const BANK_COLOR := Color(0.92, 0.94, 0.98)
const GAPS := {&"se": 45.0, &"sw": 135.0, &"nw": 225.0, &"ne": 315.0}

## Seasons [start (s), kind]: autumn 0:00, winter 1 2:30, thaw 6:00, winter 2 8:30, thaw 13:00, winter 3 15:00.
const SEASONS := [[0.0, &"autumn"], [150.0, &"winter"], [360.0, &"thaw"], [510.0, &"winter"], [780.0, &"thaw"],
		[900.0, &"winter"]]
const WINTER3_MAX := 1200.0
const COLD_SIGHT := 0.6
const COLD_DRIFT := -0.4
## Waves [id, time, rows, crack, mode].
const WAVES := [
	[&"w1a", 180.0, [["hollow_warden", 3]], &"stair_ne", &"heart"],
	[&"w1b", 270.0, [["hollow_warden", 4]], &"stair_ne", &"heart"],
	[&"raid1", 420.0, [["hollow_warden", 2]], &"shore_e", &"raid"],
	[&"w2a", 540.0, [["hollow_warden", 5]], &"stair_ne", &"heart"],
	[&"w2b", 630.0, [["hollow_warden", 4]], &"road_w", &"heart"],
	[&"w2c", 720.0, [["hollow_warden", 5], ["warden_breaker", 1]], &"stair_ne", &"heart"],
	[&"raid2", 825.0, [["hollow_warden", 3]], &"shore_e", &"raid"],
	[&"w3a", 930.0, [["hollow_warden", 5]], &"stair_ne", &"heart"],
	[&"w3a2", 930.0, [["hollow_warden", 4]], &"road_w", &"heart"],
	[&"w3b", 1020.0, [["hollow_warden", 6], ["warden_breaker", 2]], &"barrow_n", &"heart"],
	[&"w3c", 1095.0, [["stair_breaker", 1], ["hollow_warden", 5]], &"stair_ne", &"heart"],
]
const HEART_HP: Array[float] = [2600.0, 2000.0, 1600.0]
const HEART_REGEN: Array[float] = [15.0, 10.0, 8.0]
const HEART_REGEN_R := 8.0
const ELITE_HP: Array[float] = [1800.0, 2400.0, 3200.0]
const FLOE_WEIGHT: Array[int] = [6, 8, 10]
const ELITE_SINK := 600.0
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [400, 300, 250]
const LEVEL_CAP := 5
const DEFEAT_DELAY := 3.0
const ATTACK_HEART_R := 10.0
const ATTACK_HOUSE_R := 9.0
const CARVE_TIME := 25.0
const CARVE_HERO_R := 8.0
const CARVE_CLEAR_R := 12.0
const ALDRA_BACK := 40.0
const FLASH_FREEZE_R := 4.5
const YOUNG_SCALE := 0.9

const SPEAKER_COLORS := {&"torvald": Color(0.55, 0.80, 1.00), &"aldra": Color(0.62, 0.95, 0.88),
		&"master": Color(0.95, 0.93, 0.85), &"obren": Color(1.0, 0.80, 0.25), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"torvald": "Torvald", &"aldra": "Aldra", &"master": "The Master", &"obren": "Obren",
		&"narrator": "Narrator"}
## The spec's 31 lines (data/voice/lines/e6m1.json): LINE_IDS[n - 1] = id of line n.
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13", "L14", "L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25", "L26", "L27", "L28", "L28b", "L29", "L30"]
const DIALOGUE := [
	[&"narrator", "A hundred winters ago, the lake had no name, and the north had one keeper."],
	[&"master", "Keep this cold, Torvald. Keep it until I come back for it."],
	[&"torvald", "What is it?"],
	[&"master", "A promise I made to a stone. Something will come for it. Every winter."],
	[&"aldra", "My lord? The ice is singing. Can you hear it?"],
	[&"torvald", "Go home, girl. Winter is coming, and it is bringing guests."],
	[&"aldra", "This is my home. I'll stay, if it's all the same to you."],
	[&"narrator", "The first winter came down from the north, and it did not come alone."],
	[&"obren", "That is my key, frost-man. I made the lock. Give it back."],
	[&"torvald", "A talking stone. Wonderful. I was hoping for a quiet century."],
	[&"torvald", "The ice holds for us, and not for them. Remember that, girl."],
	[&"aldra", "Aldra. My name is Aldra. And I will remember."],
	[&"narrator", "Spring came late to the lake, and stayed only a little while."],
	[&"aldra", "Wake. We have guests."],
	[&"torvald", "You carved a giant out of my lake."],
	[&"aldra", "You weren't using it."],
	[&"obren", "Every winter, frost-man. I have nothing left but winters."],
	[&"torvald", "Bigger ones. Of course there are bigger ones."],
	[&"narrator", "The third winter was the longest. The Hollow sent everything it had left."],
	[&"obren", "Step aside, little king of snow. I built stairs before your mountains had names."],
	[&"torvald", "Stone is patient. Ice is older."],
	[&"master", "Three winters, and not one stone stood on your ice."],
	[&"torvald", "They will come back."],
	[&"master", "Then so will you. Every winter. You are my patience, Torvald."],
	[&"master", "Aldra Stillwater. Stay with it. The ice keeps its wardens."],
	[&"aldra", "Then I will keep it right back."],
	[&"narrator", "The lake froze around the Heartfrost that night. It did not thaw for a hundred winters."],
	[&"torvald", "Too slow... forgive me. Too slow."],
	[&"aldra", "Cracked. Not broken."],
	[&"aldra", "The longhouse... my mother's nets were in there."],
	[&"obren", "Mine. At last, mine."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"A hundred winters ago. The Master has just sealed something under Crown Hollow, and the four kingdoms are new. The north belongs to his eldest apprentice, Torvald, who has a keep, a lake, and no great love of visitors.",
	"Tonight the Master walks out onto the lake with a block of blue ice in his arms. Something inside it shines. He asks Torvald to keep it cold until he comes back for it, and warns him that something will come for it every winter.",
	"A fisher girl from the Stillwater huts has followed him onto the ice and will not go home. Her name is Aldra. Three winters are coming. Keep the Heartfrost.",
]
const HINT_START := "Keep the Heartfrost alive through three winters. Wardens come from the cracks in the north-east. Ice Walls (V) can close a gap."
const HINT_FLOE := "The ice is cracking under the Wardens. Rime Bolt and Flash Freeze crack it further: stone does not swim."
const HINT_CARVE := "Walk Torvald to a Sentinel stone (south-west shore): Aldra will carve it while no enemy is near."
const MSG_WINTER := "Winter comes."
const MSG_THAW := "The thaw."
const MSG_ONE_LODGE := "The shore has room for three lodges"
const MSG_WALLS := "No more ice for walls this winter"
const MSG_ALDRA_BACK := "Aldra is back at the keep"

## Read only.
var heartfrost: E6Target
var lake: GlasswaterLake
var longhouse: Building
var aldra: Helper
var sentinels: Array = []                 ## the carved Sentinels (Unit)
var carve := [0.0, 0.0]                   ## carving seconds per stone (CARVE_TIME = carved)
var carved := 0
var season := 0                           ## index in SEASONS
var waves_fired: Array[String] = []
var winter3_units: Array = []             ## W3c's units (the last stand)
var victory_time := -1.0
var aldra_falls := 0
var floes_broken := 0

var _tick := 0.0
var _aldra_back_left := -1.0
var _heart_hint := false
var _rime_keep_type: BuildingType
var _lodge_type: BuildingType
var _stone_props: Array = []


# ---------------------------------------------------------------- the frozen lake (Torvald's floe rules)

## GlasswaterLake turned around (spec "the floes in Torvald's hands"): only ENEMY weight counts, a break sinks the
## Wardens and Breakers on it and spares PLAYER units.
class E6Lake:
	extends GlasswaterLake
	var threshold := 8
	var credit_hero: Node3D
	const SINK_ELITE := 600.0          ## the named elite takes this instead of sinking
	var elite_id := "stair_breaker"
	var sunk := 0

	func floe_pops() -> Array[int]:
		var out: Array[int] = []
		out.resize(FLOES)
		out.fill(0)
		if not is_inside_tree():
			return out
		var w: Array[int] = []
		w.resize(FLOES)
		w.fill(0)
		for node in get_tree().get_nodes_in_group(&"units"):
			var u := node as Unit
			if u == null or not u.is_alive() or int(u.team) != Unit.Team.ENEMY or u.unit_type == null:
				continue
			var i := floe_at(u.global_position)
			if i >= 0:
				w[i] += int(u.unit_type.pop)
		for i in FLOES:
			out[i] = WEIGHT_POP if w[i] >= threshold else 0
		return out

	func break_floe(index: int) -> void:
		if index < 0 or index >= FLOES or is_open(index):
			return
		if is_inside_tree():
			var hero := credit_hero if credit_hero != null and is_instance_valid(credit_hero) else null
			for node in get_tree().get_nodes_in_group(&"units"):
				var u := node as Unit
				if u == null or not u.is_alive() or floe_at(u.global_position) != index:
					continue
				if int(u.team) == Unit.Team.PLAYER:
					u.global_position = outside_point(u.global_position, index)
					u.command_stop()
				elif int(u.team) == Unit.Team.ENEMY and u.unit_type != null and int(u.unit_type.pop) >= 2:
					if String(u.unit_type.id) == elite_id:
						u.take_damage(SINK_ELITE, hero)
					else:
						sunk += 1
						u.take_damage(1.0e6, hero)
		super(index)

	func refreeze_now(index: int) -> void:
		if is_open(index):
			_refreeze(index)


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"ice"
	enemy_kingdom = &"shadow"
	snow_theme = true
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_winters", "primary"], [&"obj_heartfrost", "primary"], [&"obj_torvald", "primary"],
			[&"sec_sentinels", "secondary"], [&"sec_longhouse", "secondary"]])
	make_breakers("stair_breaker", "The Stair-Breaker", 2400.0)
	local_unit("rime_colossus", "sentinel", "Sentinel", {"pop": 0, "cost": 0})
	_rime_keep_type = MissionE5Base.local_building("ice_keep", "ice_keep", "Rime Keep", 3000.0, true)
	if _rime_keep_type:
		_rime_keep_type.pop_bonus = 20
	_lodge_type = MissionE5Base.local_building("ice_lodge", "stillwater_lodge", "Stillwater Longhouse", 800.0)
	if _lodge_type:
		_lodge_type.pop_bonus = 20


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE6Base.e6_config(c)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Rime Keep has fallen"
	c.start_level = 2
	c.start_spells = [&"rime_bolt"]
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe lake froze around the Heartfrost"
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"rimeshield", "trigger": &"manual", "key_hint": "Frost Hall: Z",
			"card": "Rimeshield. Armour and patience: put it in a gap and the gap is closed."}
	return c


func _map_size() -> Vector2:
	return Vector2(120.0, 120.0)


func _player_start() -> Vector3:
	return TORVALD_START


func _lighting_preset() -> StringName:
	return &"ice"


func _title_line() -> String:
	return "Episode 6, Mission 1: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(KEEP_POS.x, KEEP_POS.z, 13.0, 0.0), Vector4(LONGHOUSE_POS.x, LONGHOUSE_POS.z, 6.0, 0.0)]


func _ready() -> void:
	super()
	if camera_rig:
		camera_rig.focus_on(TORVALD_START)


# ---------------------------------------------------------------- the map

func start_position(_team: int) -> Vector3:
	return TORVALD_START


func base_center(_team: int) -> Vector3:
	return KEEP_POS


func node_of(_team: int, suffix: String) -> CrystalNode:
	var id: StringName = {"a": &"e6_ice_a", "b": &"e6_ice_b", "mid": &"e6_south", "rich": &"e6_west"}.get(suffix, &"")
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(_team: int) -> Vector3:
	return SOUTH_HALL_SPOT


func rich_hall_spot(_team: int) -> Vector3:
	return WEST_HALL_SPOT


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


func _build_map() -> void:
	var clearings: Array = [[TORVALD_START, 10.0], [KEEP_POS, 18.0], [HALL_POS, 5.0], [LONGHOUSE_POS, 9.0],
			[RIDGE_POS, 4.0], [WEST_HALL_SPOT, 5.0], [SOUTH_HALL_SPOT, 5.0], [HEART_POS, 31.0]]
	for row: Array in NODES:
		clearings.append([row[1], 7.0])
	for id: StringName in CRACKS:
		clearings.append([CRACKS[id], 8.0 if id != &"stair_ne" else 18.0])
	for p in SENTINEL_STONES:
		clearings.append([p, 3.5])
	var lanes: Array = [[CRACKS[&"stair_ne"], Vector3(18.0, 0.0, -18.0), 4.0],
			[CRACKS[&"road_w"], Vector3(-18.0, 0.0, -18.0), 4.0], [CRACKS[&"barrow_n"], Vector3(-18.0, 0.0, -18.0), 4.0],
			[CRACKS[&"shore_e"], LONGHOUSE_POS, 4.0], [LONGHOUSE_POS, Vector3(18.0, 0.0, 18.0), 4.0],
			[KEEP_POS, Vector3(-18.0, 0.0, 18.0), 5.0], [KEEP_POS, NODES[2][1], 4.0], [KEEP_POS, NODES[3][1], 4.0]]
	scatter_props(MAP_SEED, clearings, lanes, 10, 18)
	for k in 36:   # M2's 28 snowbanks: every 10 degrees, skipping the 8 next to the 4 gaps
		var deg := float(k * 10)
		if not _near_gap(deg):
			_add_snowbank(deg)
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_grid.spawn_complete(_rime_keep_type, KEEP_POS, Unit.Team.PLAYER) as Keep
	if keep:
		keep.name = "RimeKeep"
		seat_keeps[Unit.Team.PLAYER] = keep
	seat_bases[Unit.Team.PLAYER] = KEEP_POS
	build_grid.spawn_complete(BuildingType.find("ice_barracks"), HALL_POS, Unit.Team.PLAYER)
	longhouse = build_grid.spawn_complete(_lodge_type, LONGHOUSE_POS, Unit.Team.PLAYER) if _lodge_type else null
	if longhouse:
		mark_scripted(longhouse)
		longhouse.destroyed.connect(_on_longhouse_destroyed)
	var diff := clampi(mission_difficulty, 0, 2)
	heartfrost = add_target(HEART_POS, float(HEART_HP[diff]), float(HEART_REGEN[diff]), _heart_regens, "The Heartfrost")
	var l := E6Lake.new()
	l.name = "GlasswaterMere"
	l.build_grid = build_grid
	l.nav_region = nav_region
	l.threshold = int(FLOE_WEIGHT[diff])
	add_child(l)
	lake = l
	if not _SIM.enabled:
		for p in SENTINEL_STONES:
			_stone_props.append(box_prop(p, Vector3(2.2, 3.0, 2.2), Color(0.70, 0.88, 0.95), p.x))
		for i in 4:   # the Stillwater fisher huts (decor)
			var a := TAU * float(i) / 4.0 + 0.4
			box_prop(LONGHOUSE_POS + Vector3(cos(a) * 6.5, 0.0, sin(a) * 6.5), Vector3(2.0, 1.8, 2.0), Color(0.45, 0.36, 0.28), a)
		ground_disc(CRACKS[&"stair_ne"], 3.0, Color(1.0, 0.62, 0.18, 0.55))
		ground_disc(CRACKS[&"shore_e"], 2.0, Color(1.0, 0.62, 0.18, 0.35))


static func _near_gap(deg: float) -> bool:
	for g: StringName in GAPS:
		if absf(fposmod(deg - float(GAPS[g]) + 180.0, 360.0) - 180.0) <= 5.5:
			return true
	return false


func _add_snowbank(deg: float) -> void:
	var a := deg_to_rad(deg)
	var shape := BoxShape3D.new()
	shape.size = BANK_SIZE
	var body := _static_obstacle(Vector3(cos(a) * BANK_RING, 0.0, sin(a) * BANK_RING), shape, BANK_SIZE.y * 0.5)
	body.name = "Snowbank%d" % int(deg)
	body.rotation.y = -(a + PI * 0.5)
	body.add_to_group(&"navigation_geometry")
	body.add_to_group(&"snowbanks")
	if _SIM.enabled:
		return
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	var m := StandardMaterial3D.new()
	m.albedo_color = BANK_COLOR
	m.roughness = 0.85
	var mi := MeshInstance3D.new()
	mi.mesh = sphere
	mi.material_override = m
	mi.scale = Vector3(BANK_SIZE.x * 1.05, BANK_SIZE.y * 1.6, BANK_SIZE.z * 1.1)
	mi.position.y = BANK_SIZE.y * 0.25
	body.add_child(mi)


## Gap centre (on the ring) of gap `id`.
static func gap_center(id: StringName) -> Vector3:
	var a := deg_to_rad(float(GAPS[id]))
	return Vector3(cos(a) * BANK_RING, 0.0, sin(a) * BANK_RING)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	local_type("stair_breaker").max_hp = float(ELITE_HP[diff])
	fog.reveal(Unit.Team.PLAYER, HEART_POS, 27.0)
	for g: StringName in GAPS:
		fog.reveal(Unit.Team.PLAYER, gap_center(g), 6.0)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, TORVALD_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	(lake as E6Lake).credit_hero = hero
	var caster := hero.get_node_or_null(^"SpellCaster")
	if caster and caster.has_signal(&"spell_effect"):
		caster.connect(&"spell_effect", _on_torvald_spell)
	for i in 5:
		var w := _spawn(make_unit("rime_hauler"), Unit.Team.PLAYER, KEEP_POS + Vector3(4.0 + i * 1.2, 0.0, -4.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 3 else "b"))
	var army: Array[String] = ["rimeshield", "rimeshield", "rimeshield", "rimeshield", "shardcaster", "shardcaster"]
	if diff == 0:
		army.append_array(["rimeshield", "rimeshield"])
	elif diff == 2:
		army.erase("shardcaster")
	for i in army.size():
		_spawn(make_unit(army[i]), Unit.Team.PLAYER, ARMY_START + Vector3(-3.0 + (i % 4) * 1.5, 0.0, (i / 4) * 1.8))
	_spawn_aldra(ALDRA_START)
	lake.floe_broken.connect(_on_floe_broken)
	lake.cracks_changed.connect(_on_cracks_changed)
	heartfrost.melted.connect(_on_heart_melted)
	begin_mission([&"obj_winters", &"obj_heartfrost", &"obj_torvald", &"sec_longhouse"])
	selection.select_units([hero])


func _spawn_aldra(at: Vector3) -> void:
	aldra = story_helper(&"helper_aldra", "Aldra", at, hero.level if hero else 2, hero, &"escort")
	if aldra == null:
		return
	MissionE6Base.set_story_look(aldra, &"young", YOUNG_SCALE)
	aldra.death_guard = _aldra_guard


func _intro() -> void:
	fire_once(&"E1")
	_place_pair(Vector3(-6.0, 0.0, 6.0), Vector3(-10.0, 0.0, 10.0))
	play_cutscene(&"e6m1_heartfrost", _heartfrost_end)


## The spec's teleports at a film's at == 0: Torvald and Aldra at their marks, no orders.
func _place_pair(t_at: Vector3, a_at: Vector3) -> void:
	if hero_alive():
		hero.global_position = t_at
		hero.command_stop()
	if aldra_ready():
		aldra.global_position = a_at
		aldra.command_stop()


## e6m1_heartfrost end state (also the skip / no-film fallback): Torvald (-30, 30), Aldra (-32, 33), L1-L7 once.
func _heartfrost_end() -> void:
	_place_pair(Vector3(-30.0, 0.0, 30.0), Vector3(-32.0, 0.0, 33.0))
	for id in ["L1", "L2", "L3", "L4", "L5", "L6", "L7"]:
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
		"objectives": [objective_text(&"obj_winters", false), objective_text(&"obj_heartfrost", false)],
		"rule": Loc.sink(objective_text(&"obj_torvald")),
	}


## The winter number (1-3) of the current or next winter.
func winter_number() -> int:
	var n := 0
	for i in mini(season, SEASONS.size() - 1) + 1:
		if SEASONS[i][1] == &"winter":
			n += 1
	return clampi(n if is_winter() else n + 1, 1, 3)


func is_winter() -> bool:
	return SEASONS[season][1] == &"winter"


## Seconds to the next winter (0 in winter).
func winter_in() -> float:
	for i in range(season + 1, SEASONS.size()):
		if SEASONS[i][1] == &"winter":
			return maxf(0.0, float(SEASONS[i][0]) - mission_time())
	return 0.0


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_winters":
			if not with_counter:
				return "Keep the Heartfrost through three winters"
			if is_winter():
				return "Keep the Heartfrost through three winters (Winter %d of 3)" % winter_number()
			return "Keep the Heartfrost through three winters (thaw: winter in %s)" % MissionE5Base.mmss(winter_in())
		&"obj_heartfrost":
			if with_counter and heartfrost:
				return "The Heartfrost must not fall (%d %%)" % int(round(heartfrost.ratio() * 100.0))
			return "The Heartfrost must not fall"
		&"obj_torvald":
			return "Torvald must survive"
		&"sec_sentinels":
			if with_counter:
				return "Help Aldra carve the Sentinels (%d / 2)" % carved
			return "Help Aldra carve the Sentinels"
		&"sec_longhouse":
			return "Keep the Stillwater longhouse standing"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_heartfrost":
			if heartfrost:
				return {"counter": int(heartfrost.hp), "goal": int(heartfrost.max_hp)}
		&"obj_winters":
			if not is_winter():
				return {"time_left": winter_in()}
		&"sec_sentinels":
			return {"counter": carved, "goal": 2, "positions": SENTINEL_STONES.duplicate()}
	return {}


# ---------------------------------------------------------------- the Heartfrost

## Regen 10 HP / s while Torvald stands within 8 m and no enemy is within 8 m.
func _heart_regens() -> bool:
	return hero_alive() and _flat(hero.global_position, HEART_POS) <= HEART_REGEN_R \
			and enemies_near(HEART_POS, HEART_REGEN_R) == 0


func _on_heart_melted(_h: Heartfrost) -> void:
	if is_ending():
		return
	fire_once(&"E15")
	say_l("L30")
	set_objective(&"obj_heartfrost", "failed")
	lose(DEFEAT_DELAY)


# ---------------------------------------------------------------- the floes

func _on_torvald_spell(id: StringName, pos: Vector3) -> void:
	if lake == null:
		return
	var i := GlasswaterLake.floe_at(pos)
	if i < 0:
		return
	match id:
		&"rime_bolt_hit":
			if _enemy_on_floe_near(pos, 2.0, i):
				lake.crack(i, 1.0, hero)
		&"flash_freeze":
			if lake.is_open(i):
				(lake as E6Lake).refreeze_now(i)
			elif _enemy_on_floe_near(pos, FLASH_FREEZE_R, i):
				lake.crack(i, 1.0, hero)


func _enemy_on_floe_near(pos: Vector3, r: float, floe: int) -> bool:
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and _flat(u.global_position, pos) <= r \
				and GlasswaterLake.floe_at(u.global_position) == floe:
			return true
	return false


func _on_cracks_changed(_i: int, c: float) -> void:
	if c >= 2.0 and fire_once(&"E_floe_hint") and hud:
		hud.show_message(HINT_FLOE, 8.0)


func _on_floe_broken(_i: int, _credit: Node3D) -> void:
	floes_broken += 1
	if is_ending():
		return
	if fire_once(&"E4"):
		say_l("L11")
		say_l("L12")
		if not has_fired(&"E_floe_hint"):
			fire_once(&"E_floe_hint")
			if hud:
				hud.show_message(HINT_FLOE, 8.0)


# ---------------------------------------------------------------- seasons and waves

func _tick_seasons() -> void:
	var t := mission_time()
	var want := 0
	for i in SEASONS.size():
		if t >= float(SEASONS[i][0]):
			want = i
	if want == season:
		return
	season = want
	var winter := is_winter()
	set_cold(winter, COLD_SIGHT, COLD_DRIFT)
	if hud:
		hud.show_message(MSG_WINTER if winter else MSG_THAW, 4.0)
	_season_light()
	match season:
		1:
			fire_once(&"E2")
			say_l("L8")
		2:
			fire_once(&"E5")
			say_l("L13")
			set_objective(&"sec_sentinels", "active")
			if hud:
				hud.show_message(HINT_CARVE, 10.0)
		3:
			fire_once(&"E7")
			say_l("L17")
			ground_disc(CRACKS[&"road_w"], 2.5, Color(1.0, 0.62, 0.18, 0.55))
		4:
			fire_once(&"E9")
		5:
			fire_once(&"E10")
			say_l("L19")
			ground_disc(CRACKS[&"barrow_n"], 2.5, Color(1.0, 0.62, 0.18, 0.55))


## Season light (the ramps' stand-in): blizzard blue, thaw cold-clear, winter 3 night.
func _season_light() -> void:
	if season == 5:
		tint_light(Color(0.62, 0.70, 0.95), 0.55, -30.0, Color(0.32, 0.38, 0.55), Color(0.08, 0.10, 0.20), Color(0.25, 0.30, 0.45))
	elif is_winter():
		tint_light(Color(0.85, 0.90, 1.0), 0.8, -40.0, Color(0.62, 0.68, 0.80), Color(0.55, 0.62, 0.75), Color(0.82, 0.86, 0.92))
	else:
		tint_light(Color(0.96, 0.97, 1.0), 1.0, -42.0, Color(0.70, 0.74, 0.82), Color(0.40, 0.55, 0.80), Color(0.85, 0.90, 0.96))


func _tick_waves() -> void:
	var t := mission_time()
	for row: Array in WAVES:
		var id := String(row[0])
		if waves_fired.has(id) or t < float(row[1]):
			continue
		waves_fired.append(id)
		_fire_wave(row)


func _fire_wave(row: Array) -> void:
	if is_ending():
		return
	var id: StringName = row[0]
	var rows: Array = row[2]
	if id == &"w2c" and clampi(mission_difficulty, 0, 2) == 0:
		rows = [rows[0]]   # easy: no Breaker in W2c
	var mode: StringName = row[4]
	var to := LONGHOUSE_POS if mode == &"raid" else HEART_POS
	var units := wave(rows, CRACKS[row[3]], mode, to)
	match id:
		&"w1a":
			fire_once(&"E3")
			say_l("L9")
			say_l("L10")
		&"w1b":
			show_spotlight()
		&"w2c":
			fire_once(&"E8")
			say_l("L18")
		&"w3c":
			winter3_units = units.duplicate()
			fire_once(&"E11")
			say_l("L20")
			say_l("L21")


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	match mode:
		&"heart":
			if heartfrost == null or not heartfrost.is_alive():
				return false
			if u.attack_target == null:
				if _flat(u.global_position, HEART_POS) < ATTACK_HEART_R:
					u.command_attack(heartfrost)
				elif not u.is_attack_moving():
					u.command_attack_move(HEART_POS)
			return true
		&"raid":
			if longhouse == null or not is_instance_valid(longhouse) or not longhouse.is_alive():
				u.set_meta(META_MODE, &"heart")
				return true
			if u.attack_target == null:
				if _flat(u.global_position, LONGHOUSE_POS) < ATTACK_HOUSE_R:
					u.command_attack(longhouse)
				elif not u.is_attack_moving():
					u.command_attack_move(LONGHOUSE_POS)
			return true
	return false


## Winter 3 ends when W3c's last unit is dead, or at 20:00.
func _tick_winter3() -> void:
	if season != 5 or is_ending():
		return
	var done := mission_time() >= WINTER3_MAX
	if not done and waves_fired.has("w3c"):
		done = MissionBase._all_dead(winter3_units)
	if done:
		_winters_done()


# ---------------------------------------------------------------- Aldra and the Sentinels

func _aldra_guard(_attacker: Variant) -> bool:
	if aldra == null or not is_instance_valid(aldra):
		return false
	aldra.hp = aldra.max_hp
	set_dormant(aldra, true)
	aldra.visible = false
	aldra.global_position = KEEP_POS + Vector3(4.0, 0.0, -4.0)
	aldra_falls += 1
	_aldra_back_left = ALDRA_BACK
	if fire_once(&"E16"):
		say_l("L28b")
	return true


func _tick_aldra(dt: float) -> void:
	if _aldra_back_left < 0.0 or aldra == null or not is_instance_valid(aldra):
		return
	_aldra_back_left -= dt
	if _aldra_back_left > 0.0:
		return
	_aldra_back_left = -1.0
	set_dormant(aldra, false)
	aldra.visible = true
	aldra.hp = aldra.max_hp
	aldra.global_position = KEEP_POS + Vector3(4.0, 0.0, -4.0)
	aldra.death_guard = _aldra_guard
	if hud:
		hud.show_message(MSG_ALDRA_BACK, 4.0)


func aldra_ready() -> bool:
	return aldra != null and is_instance_valid(aldra) and aldra.is_alive() and not is_dormant(aldra)


## Carving: Torvald within 8 m of an uncarved stone, no enemy within 12 m, Aldra up: +1 s (25 s = a Sentinel).
func _tick_carving(dt: float) -> void:
	if objective_state("sec_sentinels") != "active" or not hero_alive() or not aldra_ready():
		return
	for i in SENTINEL_STONES.size():
		if float(carve[i]) >= CARVE_TIME:
			continue
		var p: Vector3 = SENTINEL_STONES[i]
		if _flat(hero.global_position, p) > CARVE_HERO_R or enemies_near(p, CARVE_CLEAR_R) > 0:
			continue
		if _flat(aldra.global_position, p) > 3.0 and not aldra.has_move_order():
			aldra.command_move(p + Vector3(1.5, 0.0, 0.0))
		carve[i] = float(carve[i]) + dt
		if float(carve[i]) >= CARVE_TIME:
			_carved(i)
		return


func _carved(i: int) -> void:
	carved += 1
	var p: Vector3 = SENTINEL_STONES[i]
	flash_ring(p, 3.0)
	if i < _stone_props.size() and _stone_props[i] != null and is_instance_valid(_stone_props[i]):
		(_stone_props[i] as Node3D).visible = false
	var s := _spawn(make_unit("sentinel"), Unit.Team.PLAYER, p + Vector3(0.0, 0.0, 2.0))
	if s:
		s.name = "Sentinel%d" % (i + 1)
		sentinels.append(s)
	if fire_once(&"E6"):
		say_l("L14")
		say_l("L15")
		say_l("L16")
	if carved >= SENTINEL_STONES.size():
		set_objective(&"sec_sentinels", "done")


# ---------------------------------------------------------------- the longhouse, the end

func _on_longhouse_destroyed(_b: Building) -> void:
	if is_ending():
		return
	fire_once(&"E13")
	say_l("L29")
	set_objective(&"sec_longhouse", "failed")


## E12: winter 3 is over: every Warden crumbles, e6m1_return, then the victory.
func _winters_done() -> void:
	if is_ending() or not fire_once(&"E12"):
		return
	victory_time = mission_time()
	set_objective(&"obj_winters", "done")
	if objective_state("sec_longhouse") == "active":
		set_objective(&"sec_longhouse", "done" if longhouse and is_instance_valid(longhouse) and longhouse.is_alive() else "failed")
	if objective_state("sec_sentinels") == "active":
		set_objective(&"sec_sentinels", "failed")
	set_mission_flag("e6m1_time", int(victory_time))
	set_mission_flag("e6m1_sunk", (lake as E6Lake).sunk if lake else 0)
	crumble_enemies()
	set_cold(false, 1.0, 0.0)
	_place_pair(Vector3(-4.0, 0.0, 4.0), Vector3(-7.0, 0.0, 6.0))
	play_cutscene(&"e6m1_return", _return_end)


## e6m1_return end state: L22-L27 once, the Sentinels asleep, victory.
func _return_end() -> void:
	for id in ["L22", "L23", "L24", "L25", "L26", "L27"]:
		say_l(id)
	for s: Variant in sentinels:
		if is_instance_valid(s) and (s as Unit).is_alive():
			set_dormant(s as Unit, true)
	set_objective(&"obj_heartfrost", "done")
	set_objective(&"obj_torvald", "done")
	win(1.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E14")
	say_l("L28")
	set_objective(&"obj_torvald", "failed")
	super()


# ---------------------------------------------------------------- save / load

## The rebuilt mission gets back the season's cold, the Heartfrost's HP, carved stones and Aldra's state.
func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	if heartfrost and d.has("heart_hp"):
		heartfrost.hp = float(d["heart_hp"])
	if is_winter():
		set_cold(true, COLD_SIGHT, COLD_DRIFT)
	_season_light()
	for i in SENTINEL_STONES.size():
		if float(carve[i]) >= CARVE_TIME and i < _stone_props.size() and _stone_props[i] != null:
			(_stone_props[i] as Node3D).visible = false
	if aldra and is_instance_valid(aldra):
		restore_guard(aldra, _aldra_guard)
		if _aldra_back_left > 0.0 and not is_dormant(aldra):
			set_dormant(aldra, true)
			aldra.visible = false


func save_state(ids: Dictionary = {}) -> Dictionary:
	var d := super(ids)
	if heartfrost:
		d["heart_hp"] = heartfrost.hp
	return d


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held or save_restoring:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_aldra(delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_seasons()
		_tick_waves()
		_tick_carving(0.5)
		_tick_winter3()
		enforce_max(&"ice_lodge", 2, MSG_ONE_LODGE)
		enforce_max(&"ice_wall", 16, MSG_WALLS)
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())
