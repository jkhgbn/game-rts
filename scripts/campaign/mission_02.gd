class_name Mission02
extends MissionBase
## Campaign mission 2, "The Orb Beneath the Ice" (docs/design/mission-02.md = source of truth; M9.S1-S3).
## Fire against Shadow on Torvald's neutral lake: map "Glasswater Mere" (the main.gd generator, seed 1202, not
## mirrored, frozen theme), the lake's 8 floes (GlasswaterLake: cracks, weight, breaks, open water), the NEUTRAL
## Heartfrost over the Stillwater Orb (Heartfrost: Vessa and Ash Hurlers only, regen after 5 s), Malrik's dig
## expedition (Dusk Keep 1 800 HP, Gloom Hall, Night Spire, Hovel, 4 dig Thralls, the 0.02 % / s dig with relief),
## Torvald's things that hit both armies (blizzards on both teams' sight, the Sentinels, the shore walls at E11),
## Aldra on the Glass Ridge (story actor), the 3 Frozen Emberguard blocks, Pell or his cart (campaign flag), waves
## W1 / reinforcements / W2 (wait rule) / relief / W3 / Pursuit, events E1-E14 + E11b and the 19 lines.
## Built on MissionBase (objectives, timers, E-list, guards / waves, the level cap, the Commander, the end + save).
## Placeholder art is built in code (M9.V1 replaces it): snowbanks, the ridge, the lake, the Heartfrost, the blocks,
## the Sentinel shells, Aldra, the blizzard.

signal orb_claimed(wizard: Wizard)

const MISSION_ID := &"m02"
const MISSION_TITLE := "The Orb Beneath the Ice"
const MAP_SEED := 1202

const EMBER_HALL_POS := Vector3(-27.0, 0.0, 45.0)
const GLOOM_HALL_POS := Vector3(27.0, 0.0, -45.0)
const NIGHT_SPIRE_POS := Vector3(37.0, 0.0, -29.0)
const HOVEL_POS := Vector3(50.0, 0.0, -46.0)
const NORTH_SPIRE_POS := Vector3(-10.0, 0.0, -41.0)
const SPIRE_HP := 750.0
const DUSK_KEEP_HP := 1800.0
const MALRIK_POS := Vector3(4.0, 0.0, -4.0)
const MALRIK_LEASH := 12.0
const MALRIK_RESPAWN := 60.0
const SHADOW_RALLY := Vector3(30.0, 0.0, -30.0)
const SHADOW_ROAD := Vector3(-56.0, 0.0, -30.0)
const FALLBACK_SPAWN := Vector3(56.0, 0.0, -56.0)
const ARMY_POS := Vector3(-32.0, 0.0, 32.0)
## id -> [position, crystals]
const M2_NODES := {
	&"m2_fire_a": [Vector3(-46.0, 0.0, 34.0), 1500],
	&"m2_fire_b": [Vector3(-34.0, 0.0, 46.0), 1500],
	&"m2_west": [Vector3(-50.0, 0.0, 10.0), 2000],
	&"m2_south": [Vector3(4.0, 0.0, 50.0), 1500],
	&"node_shadow_a": [Vector3(46.0, 0.0, -34.0), 1500],
	&"node_shadow_b": [Vector3(34.0, 0.0, -46.0), 1500],
}
const M2_FIRE_SUFFIXES := {&"a": &"m2_fire_a", &"b": &"m2_fire_b", &"mid": &"m2_south", &"rich": &"m2_west"}
const M2_SHADOW_SUFFIXES := {&"a": &"node_shadow_a", &"b": &"node_shadow_b"}
const WEST_HALL_SPOT := Vector3(-43.0, 0.0, 12.0)
const SOUTH_HALL_SPOT := Vector3(-3.0, 0.0, 51.0)

## The lake and its shore.
const HEARTFROST_POS := Vector3.ZERO
const BANK_RING := 25.5
const BANK_SIZE := Vector3(5.0, 1.8, 2.5)   ## long (tangent) x tall x deep (radial)
const BANK_STEP_DEG := 10
const BANK_COLOR := Color(0.92, 0.94, 0.98)
## Shore gaps (angle in degrees; a = (cos a, sin a), +z south).
const GAPS := {&"se": 45.0, &"sw": 135.0, &"nw": 225.0, &"ne": 315.0}
const SEALED_GAPS: Array[StringName] = [&"sw", &"nw", &"se"]
const WALL_ROWS: Array[float] = [24.0, 27.0]
const WALL_HALF_SPAN := 5.0
const RIDGE_POS := Vector3(-34.0, 0.0, -26.0)
const RIDGE_HEIGHT := 3.0
const RIDGE_RADIUS := 2.5
const DIG_RING := 3.0
const DIG_WORK_RADIUS := 5.0
const DIG_THRALLS := 4
const RELIEF_INTERVAL := 40.0
const ORB_CLAIM_RADIUS := 2.2
const ORB_POS := Vector3(0.0, 1.0, 0.0)
const ESCAPE_RADIUS := 10.0
const E3_RADIUS := 12.0
const E9_RADIUS := 16.0
const FLASH_RADIUS := 12.0
const FLASH_COLOR := Color(0.75, 0.92, 1.0)

## [id, name, position, clearing radius]
const EMBERGUARD_TABLE := [
	[&"eg1", "West", Vector3(-46.0, 0.0, -14.0), 8.0],
	[&"eg2", "South", Vector3(24.0, 0.0, 44.0), 8.0],
	[&"eg3", "North", Vector3(-14.0, 0.0, -46.0), 8.0],
]
const PELL_POS := Vector3(-32.0, 0.0, 0.0)
const PELL_GIFT := &"frostglass_shard"
const OATH_ITEM := &"oath_of_embers"
const M2_CACHE_SPOTS: Array[Vector3] = [Vector3(-12.0, 0.0, 32.0), Vector3(32.0, 0.0, 10.0)]
const SENTINEL_SPOTS: Array[Vector3] = [Vector3(-26.0, 0.0, 22.0), Vector3(-22.0, 0.0, 26.0)]

const W1_TIME := 300.0
const HINT_SPOTLIGHT := "Ash Hurlers crack the ice: shell the floe under them."
const E6_TIME := 480.0
const W2_TIME := 540.0
const W2_MAX_WAIT := 45.0
const W2_WAIT_ALIVE := 3
const B1_WARN := 650.0
const B1_TIME := 660.0
const B1_LENGTH := 45.0
const W3_TIME := 900.0
## Rush floor (campaign notes 2026-10-11: the Orb fell at 7:48 for a 18-24 min mission): the Heartfrost's core is
## Torvald's own winter and holds at HEARTFROST_CORE of its HP until his storm (B1) has blown over the lake.
const HEARTFROST_CORE := 0.4
const CORE_THAW_AT := B1_TIME + B1_LENGTH
const PURSUIT_SECOND := 40.0
const ALDRA_STAY := 45.0
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 4.0
const LEVEL_CAP := 6
const FIREBALL_TRAVEL := 0.3      ## The Fireball's crack / Heartfrost hit lands this long after the cast.

## [easy, normal, hard] (difficulty notes).
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS_BY_DIFF: Array[int] = [400, 300, 250]
const DIG_RATE: Array[float] = [0.015, 0.02, 0.025]          ## % per second per working Thrall
const HEARTFROST_HP: Array[float] = [1200.0, 1500.0, 1800.0]
const HEARTFROST_REGEN: Array[float] = [10.0, 15.0, 20.0]
const REFREEZE: Array[float] = [60.0, 45.0, 30.0]
const BLIZZARD_SIGHT: Array[float] = [0.6, 0.5, 0.4]
const MALRIK_START_LEVEL: Array[int] = [3, 4, 5]
const MALRIK_E11_LEVEL: Array[int] = [4, 5, 6]
const MALRIK_START_SPELLS := [
	[&"shadow_lance", &"shadow_lance", &"soul_siphon"],
	[&"shadow_lance", &"shadow_lance", &"soul_siphon", &"umbral_shroud"],
	[&"shadow_lance", &"shadow_lance", &"soul_siphon", &"umbral_shroud", &"soul_siphon"],
]
const MALRIK_E11_SPELLS := [[&"umbral_shroud"], [&"soul_siphon"], [&"shadow_lance"]]
const NO_SAVE_ESSENCE := 400

## Keep tiers (mission-02.md "Tiers"): the Stronghold only, as mission 1.
const MAX_TIER := 2
const HALL_UNITS: Array[StringName] = [&"flame_guard", &"ember_archer", &"blaze_rider", &"ash_hurler"]
const TIER2_HALL_UNITS: Array[StringName] = [&"pyre_adept", &"cinder_arbalest"]
const HINT_STRONGHOLD := "Your Keep can become a Stronghold: select the Keep and press %s (%d crystals). It opens %s."
const HINT_STRONGHOLD_SECONDS := 12.0

const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1),
	&"malrik": Color(0.7, 0.3, 1.0),
	&"torvald": Color(0.55, 0.80, 1.00),
	&"narrator": Color(0.9, 0.85, 0.7),
	&"pell": Color(0.85, 0.75, 0.5),
	&"whisper": Color(1.0, 0.80, 0.25),
	&"aldra": Color(0.62, 0.95, 0.88),
}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"malrik": "Malrik", &"torvald": "Torvald", &"narrator": "Narrator",
		&"pell": "Pell", &"whisper": "???", &"aldra": "Aldra"}
## The 19 lines; LINE_IDS[i] is the spec id of DIALOGUE[i] (say_id(&"L4a") says it once).
const LINE_IDS: Array[StringName] = [&"L1", &"L2", &"L3", &"L4a", &"L4b", &"L5", &"L6a", &"L6b", &"L7", &"L8", &"L9",
		&"L10", &"L15", &"L16", &"L17", &"L11", &"L12", &"L13", &"L14"]
const DIALOGUE := [
	[&"narrator", "Glasswater Mere has not thawed in a hundred winters. Something at the bottom still shines."],
	[&"vessa", "Malrik's diggers on Torvald's lake. Torvald must be thrilled."],
	[&"torvald", "Two children, fighting on my lake. Finish it quickly, and leave my ice alone."],
	[&"pell", "You again! My wheels froze to the road, so I suppose I'm open. Take this, it's on the house. The house is frozen too."],
	[&"vessa", "Pell's cart, and no Pell. Maybe I should have opened that cage. Well. Finders keepers."],
	[&"vessa", "Emberguard, on your feet! Stamp your boots until you can feel your toes."],
	[&"malrik", "More diggers, more knives. You should have burned my hall when you had the chance."],
	[&"malrik", "Someone burned my barracks, so I brought fewer friends. Petty, little ember. I approve."],
	[&"vessa", "Thin ice! Ha! I am absolutely doing that again."],
	[&"torvald", "That ice has kept a secret for a hundred winters, ember. Think before you melt it."],
	[&"vessa", "A hundred winters of ice, and it took me one afternoon. Somebody write that down."],
	[&"torvald", "So be it. My lake will see you out. Slowly."],
	[&"whisper", "Two. You're doing so well."],
	[&"aldra", "Wake. We have guests."],
	[&"aldra", "Through my glass already? Go, then. The mere remembers every footstep."],
	[&"torvald", "Run, little ember. Every relic you carry makes the Hollow hungrier. You will see."],
	[&"narrator", "Two relics answer to fire. In the north, Ice watches, and says nothing."],
	[&"vessa", "Too... cold... should have... brought a coat..."],
	[&"malrik", "Patience was never my virtue. Luckily, I brought shovels."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The Ember Crown sits on Vessa's head and will not stop humming. It hums loudest toward the north, where the roads turn white and the rivers stop moving.",
	"The Master's second relic, the Stillwater Orb, lies at the bottom of Glasswater Mere, sealed in Torvald's ice for a hundred winters. Torvald has closed his lake to both armies. Malrik came anyway: his diggers are cutting down through the ice, one patient block at a time.",
	"Torvald will not fight for either side, but his lake fights everyone. Fire melts ice. Fire also cracks it.",
]
const BRIEFING_DIG_LINE := "Malrik's diggers are cutting toward the orb. Do not let them reach it."
const HINT_START := "Ash Hurlers (V at the Ember Hall) melt ice. Fireballs crack it."
const HINT_E11 := "Torvald's walls and Sentinels attack both armies. Break through and bring the orb home."
const MSG_STORM := "Torvald's storm is coming"
const MSG_CORE_HOLDS := "The Heartfrost's core is Torvald's own winter: it will not give until his storm has passed"
const MSG_CORE_THAWS := "Torvald's storm is spent. The Heartfrost's core can melt now"
const MSG_ONLY_FIRE := "Only fire melts the Heartfrost (Vessa, Ash Hurlers)"
const MSG_OATH := "The Emberguard captain swears the Oath of Embers"
const MSG_MALRIK_FELL := "Malrik has fallen back into the shadows"
const MSG_DIG := "Malrik's dig: %d %%"
const DIG_MESSAGES: Array[int] = [50, 75, 90]

## Test / menu switch (before the tree): campaign flags to use instead of the save ({} = read the save).
var flag_override: Dictionary = {}

var stronghold_hint_shown := false        ## Read only.
var ember_hall: TrainingBuilding          ## Read only.
var gloom_hall: Building                  ## Read only.
var night_spire: Building                 ## Read only: the base's Night Spire (S1).
var north_spire: Building                 ## Read only: G5's Night Spire at EG3.
var heartfrost: Heartfrost                ## Read only.
var lake: GlasswaterLake                  ## Read only.
var blizzard: MissionBlizzard             ## Read only.
var aldra: MissionRidgeActor              ## Read only.
var blocks: Array[MissionFrozenEmberguard] = []   ## Read only, EMBERGUARD_TABLE order.
var pell: RuinPeddler                     ## Read only: Pell when m1_peddler_freed, else null.
var cart_cache: LostCache                 ## Read only: the cart cache when Pell is not here.
var guard_groups := {}                    ## Read only: &"G1".."G5" -> Array of units.
var sentinels: Array = []                 ## Read only: the Rime Colossi (NEUTRAL).
var dig_thralls: Array = []               ## Read only: living + dead dig Thralls (scripted).
var reinforcements: Array = []            ## Read only.
var shore_walls: Array = []               ## Read only: every NEUTRAL Ice Wall raised at E11.
var wall_rows := {}                       ## Read only: gap id -> [row r24 walls, row r27 walls].
var waves_fired: Array[StringName] = []   ## Read only: &"W1", &"reinforcements", &"W2", &"W3", &"pursuit", &"pursuit_2".
var said_ids: Array[StringName] = []      ## Read only: the line ids said, in order.
var thawed := 0                           ## Read only: Emberguard blocks thawed.
var dig := 0.0                            ## Read only: Malrik's dig in percent (0-100).
var dig_active := false                   ## Read only: from E2 until E10.
var relief_sent := 0                      ## Read only.
var heartfrost_freed := false             ## Read only: E10's end state ran.
var orb_taken := false                    ## Read only.
var peddler_freed := false                ## Read only: the m1 flag this run uses.
var outpost_burned := false               ## Read only.
var no_save_fallback := false             ## Read only: no mission 1 victory in the save (debug start).

var _flags_read := false
var _hall_type: BuildingType
var _malrik_joined := false
var _relief_left := RELIEF_INTERVAL
var _w2_due := false
var _dig_msgs: Dictionary = {}
var _said: Dictionary = {}
var _heartfrost_msg_shown := false
var _core_msg_shown := false
var _last_dig_pct := -1
var _last_melt_pct := -1
var _tick := 0.0
var _orb_mesh: Node3D
var _gap_opened: Array[StringName] = []


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_dig", "primary"], [&"obj_heartfrost", "primary"], [&"obj_orb", "primary"],
			[&"obj_escape", "primary"], [&"obj_vessa", "primary"], [&"sec_emberguard", "secondary"],
			[&"sec_dig", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"shadow_knight"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Fire keep has fallen"
	c.tiers_enabled = true
	c.max_tier = MAX_TIER
	c.bots_upgrade = false
	c.casters_enabled = true
	c.start_crystals = START_CRYSTALS_BY_DIFF.duplicate()
	c.start_level = 2
	c.start_spell_points = 1
	c.level_cap = LEVEL_CAP
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.bot_profile_id = bot_profile()
	c.bot_team = Unit.Team.ENEMY
	c.victory_banner = "VICTORY\nThe Stillwater Orb is yours"
	c.defeat_banner = "DEFEAT"
	c.rewards = {"artifact": "stillwater_orb", "flags": {"m2_emberguard_sworn": "sec_emberguard",
			"m2_dig_under_half": "sec_dig"}, "bonus_essence": {"sec_dig": 300}, "next": &"m03"}
	c.spotlight = {"id": &"ash_hurler", "trigger": &"start", "key_hint": "Ember Hall: V",
			"card": "Ash Hurler. Slow, far, and it melts what swords can't: ice, towers, camps."}
	return c


## The Commander profile: AIProfile.mission_02() when the ai-coder added it (M9.A1), else mission 1's (the same
## Shadow bot: never attacks, 4 workers, 8 soldiers at the rally, no rebuild).
static func bot_profile() -> StringName:
	var script := load("res://scripts/ai/ai_profile.gd") as Script
	if script:
		for m in script.get_script_method_list():
			if StringName(m["name"]) == &"mission_02":
				return &"mission_02"
	return &"mission_01"


func _ready() -> void:
	_hall_type = _make_hall_type()
	get_tree().node_added.connect(_on_m2_node_added)
	super()


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_m2_node_added):
		get_tree().node_added.disconnect(_on_m2_node_added)


func _lighting_preset() -> StringName:
	return &"ice"


func _use_map_dressing() -> bool:
	return false   # the green edge dressing does not fit a frozen map (M9.V1: a snow border later)


func _lane_end() -> Vector3:
	return SHADOW_START


func _title_line() -> String:
	return "Mission 2: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(PLAYER_START.x, PLAYER_START.z, 13.0, 0.0), Vector4(SHADOW_START.x, SHADOW_START.z, 13.0, 0.0),
			Vector4(PELL_POS.x, PELL_POS.z, 5.0, 0.0), Vector4(RIDGE_POS.x, RIDGE_POS.z, 4.5, 0.0)]


## The painted ground in snow colours (M9.V1 placeholder: the grass ramp becomes snow, dirt = packed snow).
func _build_ground() -> void:
	super()
	for body in nav_region.get_children():
		for c in body.get_children():
			var mi := c as MeshInstance3D
			if mi == null:
				continue
			var mat := mi.material_override as ShaderMaterial
			if mat:
				var snow := {
					&"grass_dark": Color(0.80, 0.84, 0.90), &"grass_light": Color(0.93, 0.95, 0.98),
					&"grass_warm": Color(0.88, 0.89, 0.92), &"grass_cool": Color(0.78, 0.83, 0.92),
					&"grass_dry": Color(0.86, 0.87, 0.90), &"clover_color": Color(0.84, 0.87, 0.93),
					&"dirt_color": Color(0.70, 0.72, 0.76), &"dirt_dark": Color(0.58, 0.60, 0.66),
					&"pebble_color": Color(0.62, 0.64, 0.70), &"paving_color": Color(0.74, 0.76, 0.80),
					&"canopy_dark": Color(0.16, 0.22, 0.24), &"canopy_light": Color(0.62, 0.68, 0.74),
					&"rock_color": Color(0.52, 0.55, 0.60), &"haze_color": Color(0.80, 0.86, 0.94),
					&"tuft_density": 0.0, &"flower_amount": 0.0, &"groove_energy": 0.0,
				}
				for k: StringName in snow:
					mat.set_shader_parameter(k, snow[k])
			elif mi.material_override is StandardMaterial3D:
				(mi.material_override as StandardMaterial3D).albedo_texture = null
				(mi.material_override as StandardMaterial3D).albedo_color = Color(0.88, 0.91, 0.96)


func node_of(team: int, suffix: String) -> CrystalNode:
	var table: Dictionary = M2_SHADOW_SUFFIXES if team == Unit.Team.ENEMY else M2_FIRE_SUFFIXES
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


## Malrik comes back at the Dusk Keep, or at the fallback corner once it is gone.
func respawn_point(team: int) -> Vector3:
	if team == Unit.Team.ENEMY:
		var k := keep_of(team)
		return k.spawn_point() if k else FALLBACK_SPAWN
	return super(team)


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	_read_flags()
	var rng := RandomNumberGenerator.new()
	rng.seed = MAP_SEED
	var clearings := [[PLAYER_START, 18.0], [SHADOW_START, 18.0], [EMBER_HALL_POS, 4.0], [GLOOM_HALL_POS, 4.0],
			[NIGHT_SPIRE_POS, 3.0], [HOVEL_POS, 4.0], [NORTH_SPIRE_POS, 3.0], [WEST_HALL_SPOT, 4.0],
			[SOUTH_HALL_SPOT, 4.0], [M2_NODES[&"m2_west"][0], 7.0], [M2_NODES[&"m2_south"][0], 7.0],
			[PELL_POS, 6.0], [RIDGE_POS, 4.0], [SHADOW_ROAD, 6.0], [FALLBACK_SPAWN, 4.0]]
	for row in EMBERGUARD_TABLE:
		clearings.append([row[2], row[3]])
	for p: Vector3 in M2_CACHE_SPOTS:
		clearings.append([p, CACHE_CLEARING])
	for p: Vector3 in SENTINEL_SPOTS:
		clearings.append([p, 3.0])
	var keep_out := func(p: Vector3) -> bool:
		return Vector2(p.x, p.z).length() < 30.0 or _in_clearing(p, clearings) or _in_path_lane(p)

	for cluster in 10:   # fir and pine only (no broadleaf)
		var center := Vector3(rng.randf_range(-52, 52), 0.0, rng.randf_range(-52, 52))
		for i in rng.randi_range(5, 9):
			var p := center + Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6))
			var s := rng.randf_range(0.8, 1.3)
			var kind := "tree_fir" if rng.randf() < 0.55 else "tree_pine"
			if absf(p.x) > 57.0 or absf(p.z) > 57.0 or keep_out.call(p):
				continue
			_add_snow_tree(p, s, kind)
	for i in 22:
		var p := Vector3(rng.randf_range(-54, 54), 0.0, rng.randf_range(-54, 54))
		var s := rng.randf_range(0.8, 2.2)
		var rot := rng.randf() * TAU
		if keep_out.call(p):
			continue
		_add_rock(p, s, rot)
		_add_snow_cap(p + Vector3(0.0, 1.0 * s, 0.0), Vector3(1.5, 0.35, 1.25) * s * 0.55)

	for k in 36:   # 28 snowbanks: every 10 degrees, skipping the 8 centres next to the 4 gaps
		var deg := k * BANK_STEP_DEG
		if _near_gap(float(deg)):
			continue
		_add_snowbank(float(deg))
	_add_ridge()

	# Bases (finished buildings, navmesh obstacles before the bake).
	keep = build_grid.spawn_complete(BuildingType.find("fire_keep"), PLAYER_START + KEEP_OFFSET,
			Unit.Team.PLAYER) as Keep
	ember_hall = build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL_POS,
			Unit.Team.PLAYER) as TrainingBuilding
	shadow_keep = build_grid.spawn_complete(BuildingType.find("shadow_keep"), SHADOW_START - KEEP_OFFSET,
			Unit.Team.ENEMY) as Keep
	shadow_keep.max_hp = DUSK_KEEP_HP
	shadow_keep.hp = DUSK_KEEP_HP
	gloom_hall = build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL_POS, Unit.Team.ENEMY)
	night_spire = build_grid.spawn_complete(BuildingType.find("shadow_tower"), NIGHT_SPIRE_POS, Unit.Team.ENEMY)
	night_spire.max_hp = SPIRE_HP
	night_spire.hp = SPIRE_HP
	build_grid.spawn_complete(BuildingType.find("shadow_hovel"), HOVEL_POS, Unit.Team.ENEMY)
	north_spire = build_grid.spawn_complete(BuildingType.find("shadow_tower"), NORTH_SPIRE_POS, Unit.Team.ENEMY)
	north_spire.max_hp = SPIRE_HP
	north_spire.hp = SPIRE_HP
	mark_scripted(north_spire)
	for id: StringName in M2_NODES:
		_add_crystal_node(id, M2_NODES[id][0], int(M2_NODES[id][1]))

	for row in EMBERGUARD_TABLE:
		var b := MissionFrozenEmberguard.new()
		b.brazier_id = row[0]
		b.display_name = row[1]
		b.name = "Emberguard%s" % String(row[1])
		b.flame_target = HEARTFROST_POS
		nav_region.add_child(b)
		b.position = row[2]
		b.lit_up.connect(_on_block_thawed)
		blocks.append(b)

	var diff := clampi(mission_difficulty, 0, 2)
	heartfrost = Heartfrost.new()
	heartfrost.name = "Heartfrost"
	heartfrost.setup(HEARTFROST_HP[diff], HEARTFROST_REGEN[diff])
	heartfrost.hp_floor = HEARTFROST_HP[diff] * HEARTFROST_CORE   # the rush floor (header): lifted at CORE_THAW_AT
	nav_region.add_child(heartfrost)
	heartfrost.position = HEARTFROST_POS

	lake = GlasswaterLake.new()
	lake.name = "GlasswaterMere"
	lake.build_grid = build_grid
	lake.nav_region = nav_region
	lake.refreeze_time = REFREEZE[diff]
	add_child(lake)

	if peddler_freed:
		pell = RuinPeddler.new()
		pell.name = "Pell"
		nav_region.add_child(pell)
		pell.display_name = "Pell, Ruin Peddler"
		pell.position = PELL_POS
		pell.rotation.y = atan2(-PELL_POS.x, -PELL_POS.z)
		peddlers.append(pell)
	else:
		_add_frozen_cart()


## The campaign flags this run uses (flag_override first; no m01 victory in the save = both false).
func _read_flags() -> void:
	if _flags_read:
		return
	_flags_read = true
	var flags := {}
	if not flag_override.is_empty():
		flags = flag_override
	else:
		var cs := CampaignState.open(campaign_save_path)
		no_save_fallback = not cs.is_completed(&"m01")
		if not no_save_fallback:
			flags = cs.flags
	peddler_freed = bool(flags.get("m1_peddler_freed", false))
	outpost_burned = bool(flags.get("m1_outpost_burned", false))


static func _near_gap(deg: float) -> bool:
	for g: StringName in GAPS:
		var d := absf(fposmod(deg - float(GAPS[g]) + 180.0, 360.0) - 180.0)
		if d <= 5.5:
			return true
	return false


## Gap centre (on the ring) of gap `id`.
static func gap_center(id: StringName) -> Vector3:
	var a := deg_to_rad(float(GAPS[id]))
	return Vector3(cos(a) * BANK_RING, 0.0, sin(a) * BANK_RING)


func _add_snow_tree(p: Vector3, s: float, kind: String) -> void:
	if env_props == null:
		_add_tree(p, s)
		return
	var shape := CylinderShape3D.new()
	shape.radius = 0.45 * s
	shape.height = 2.0
	_static_obstacle(p, shape, 1.0)
	env_props.add_tree_kind(kind, p, s)


func _add_snow_cap(at: Vector3, size: Vector3) -> void:
	if _SIM.enabled:
		return
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 6
	var m := StandardMaterial3D.new()
	m.albedo_color = BANK_COLOR
	m.roughness = 0.9
	var mi := MeshInstance3D.new()
	mi.mesh = sphere
	mi.material_override = m
	mi.scale = size
	add_child(mi)
	mi.position = at


func _add_snowbank(deg: float) -> void:
	var a := deg_to_rad(deg)
	var shape := BoxShape3D.new()
	shape.size = BANK_SIZE
	var body := _static_obstacle(Vector3(cos(a) * BANK_RING, 0.0, sin(a) * BANK_RING), shape, BANK_SIZE.y * 0.5)
	body.name = "Snowbank%d" % int(deg)
	body.rotation.y = -(a + PI * 0.5)   # local x along the tangent
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


func _add_ridge() -> void:
	var shape := CylinderShape3D.new()
	shape.radius = RIDGE_RADIUS
	shape.height = RIDGE_HEIGHT
	var body := _static_obstacle(RIDGE_POS, shape, RIDGE_HEIGHT * 0.5)
	body.name = "GlassRidge"
	body.add_to_group(&"navigation_geometry")
	if _SIM.enabled:
		return
	var rock := CylinderMesh.new()
	rock.top_radius = RIDGE_RADIUS * 0.7
	rock.bottom_radius = RIDGE_RADIUS * 1.05
	rock.height = RIDGE_HEIGHT
	rock.radial_segments = 7
	_mesh(body, rock, Color(0.42, 0.47, 0.55), RIDGE_HEIGHT * 0.5)
	var cap := CylinderMesh.new()
	cap.top_radius = RIDGE_RADIUS * 0.6
	cap.bottom_radius = RIDGE_RADIUS * 0.75
	cap.height = 0.35
	cap.radial_segments = 7
	_mesh(body, cap, BANK_COLOR, RIDGE_HEIGHT + 0.1)
	for i in 3:   # glass shards on the ridge
		var shard := CylinderMesh.new()
		shard.top_radius = 0.0
		shard.bottom_radius = 0.25
		shard.height = 1.2 + i * 0.3
		shard.radial_segments = 5
		var mi := _mesh(body, shard, Color(0.62, 0.95, 0.88), RIDGE_HEIGHT + 0.5)
		mi.position += Vector3(cos(i * 2.1) * 1.1, 0.0, sin(i * 2.1) * 1.1)
		mi.rotation.z = 0.25 * (i - 1)


## The empty frozen cart (Pell not freed): a cart obstacle with the cache in front of it (opens at once).
func _add_frozen_cart() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.0, 1.6, 1.6)
	var body := _static_obstacle(PELL_POS + Vector3(0.0, 0.0, -1.2), shape, 0.8)
	body.name = "FrozenCart"
	if not _SIM.enabled:
		var box := BoxMesh.new()
		box.size = Vector3(2.0, 1.0, 1.5)
		_mesh(body, box, Color(0.35, 0.25, 0.15), 0.5)
		var cap := BoxMesh.new()
		cap.size = Vector3(2.2, 0.25, 1.7)
		_mesh(body, cap, BANK_COLOR, 1.1)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	fog.reveal(Unit.Team.ENEMY, SHADOW_START, FogOfWar.START_REVEAL)
	var diff := clampi(mission_difficulty, 0, 2)

	# --- Fire (player): Vessa, then the campaign save, then the branch content.
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	_apply_campaign_start()
	for i in 5:
		var cinder := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER,
				PLAYER_START + Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2))
		cinder.call(&"command_gather", crystal_nodes[&"m2_fire_a" if i < 3 else &"m2_fire_b"])
	var soldiers: Array[String] = ["flame_guard", "flame_guard", "flame_guard", "flame_guard", "ember_archer",
			"ember_archer", "blaze_rider", "blaze_rider"]
	for i in soldiers.size():
		_spawn(make_unit(soldiers[i]), Unit.Team.PLAYER,
				ARMY_POS + Vector3(-3.0 + (i % 4) * 1.5, 0.0, -1.0 + (i / 4) * 1.8))

	# --- Malrik's expedition (the bot's base + the scripted dig)
	shadow_hero = _make_wizard(Unit.Team.ENEMY)
	_spawn(shadow_hero, Unit.Team.ENEMY, MALRIK_POS)
	_claim_wizard(shadow_hero, Unit.Team.ENEMY)
	raise_wizard(shadow_hero, MALRIK_START_LEVEL[diff], MALRIK_START_SPELLS[diff])
	mark_scripted(shadow_hero)   # the mission anchors him at (4, -4); he casts by himself
	if &"ai_auto_cast" in shadow_hero:
		shadow_hero.set(&"ai_auto_cast", true)
	ItemDrops.ensure_inventory(shadow_hero)
	shadow_hero.died.connect(_on_malrik_died)
	wizard_respawned.connect(_on_m2_wizard_respawned)
	for i in 4:
		var thrall := _spawn(make_unit("gloom_thrall"), Unit.Team.ENEMY,
				SHADOW_START + Vector3(4.0 - i * 1.2, 0.0, -4.0 + i * 1.2))
		thrall.call(&"command_gather", crystal_nodes[&"node_shadow_a" if i < 2 else &"node_shadow_b"])
	for i in 4:
		_spawn(make_unit("shade"), Unit.Team.ENEMY, SHADOW_RALLY + Vector3(cos(i * 1.57) * 1.5, 0.0, sin(i * 1.57) * 1.5))
	for i in DIG_THRALLS:
		_add_dig_thrall(dig_spot(i), i)

	_spawn_guards()
	_spawn_sentinels(diff)
	_spawn_m2_caches()

	heartfrost.melter_hero = hero
	heartfrost.melted.connect(_on_heartfrost_melted)
	for b in blocks:
		b.lighter = hero
	lake.floe_broken.connect(_on_floe_broken)
	var caster := hero.get_node_or_null(^"SpellCaster")
	if caster and caster.has_signal(&"spell_effect"):
		caster.connect(&"spell_effect", _on_hero_spell_effect)
	blizzard = MissionBlizzard.new()
	blizzard.name = "Blizzard"
	blizzard.sight_mult = BLIZZARD_SIGHT[diff]
	blizzard.follow = camera_rig
	add_child(blizzard)
	aldra = MissionRidgeActor.new()
	aldra.name = "Aldra"
	add_child(aldra)
	aldra.global_position = RIDGE_POS + Vector3(0.0, RIDGE_HEIGHT, 0.0)
	aldra.rotation.y = atan2(RIDGE_POS.x, RIDGE_POS.z)   # facing the lake

	_add_events()
	begin_mission([&"obj_heartfrost", &"obj_vessa", &"sec_emberguard"])


## CampaignState.apply_to_start (items, carried essence, flags meta); with no mission 1 victory in the save (menu
## debug, tests): the Ember Crown in slot 1 anyway, empty slots, essence 150 + 400, both flags false.
func _apply_campaign_start() -> void:
	_read_flags()
	if no_save_fallback or not flag_override.is_empty():
		set_meta(&"campaign_flags", {"m1_peddler_freed": peddler_freed, "m1_outpost_burned": outpost_burned})
		force_artifacts(hero, ["ember_crown", ""])
		if no_save_fallback:
			var bank := EssenceBank.for_team(Unit.Team.PLAYER)
			if bank:
				bank.add(NO_SAVE_ESSENCE)
		return
	CampaignState.open(campaign_save_path).apply_to_start(self)


func _add_events() -> void:
	after(120.0, _e2_dig_starts)
	add_event(&"E3", func() -> bool: return hero_alive() and _flat(hero.global_position, PELL_POS) <= E3_RADIUS,
			_e3_pell)
	after(W1_TIME, _fire_w1)
	after(E6_TIME, _e6)
	after(W2_TIME, func() -> void: _w2_due = true)
	after(B1_WARN, func() -> void:
		if not is_ending():
			hud.show_message(MSG_STORM, 4.0))
	after(B1_TIME, func() -> void:
		fire_once(&"E8")
		if not is_ending():
			blizzard.set_blowing(true))
	after(B1_TIME + B1_LENGTH, func() -> void:
		if not orb_taken:
			blizzard.set_blowing(false))
	after(W3_TIME, _fire_w3)
	add_event(&"E9", func() -> bool: return hero_alive() and _flat(hero.global_position, HEARTFROST_POS) <= E9_RADIUS,
			func() -> void: say_id(&"L8"))
	add_event(&"E11b", func() -> bool: return orb_taken and not opened_gaps().is_empty(), _e11b)
	add_event(&"E12", func() -> bool:
		return orb_taken and hero_alive() and keep_of(Unit.Team.PLAYER) != null \
				and _flat(hero.global_position, keep.global_position) <= ESCAPE_RADIUS, _e12_escape)


func _spawn_guards() -> void:
	guard_groups[&"G1"] = spawn_group([["shade", 2], ["nightbolt", 1]], Vector3(-19.0, 0.0, 19.0), 1.5,
			Unit.Team.ENEMY, true)
	guard_groups[&"G2"] = spawn_group([["shade", 2], ["nightbolt", 2]], Vector3(-44.0, 0.0, -16.0), 2.5,
			Unit.Team.ENEMY, true)
	guard_groups[&"G3"] = spawn_group([["shade", 3], ["nightbolt", 2], ["shadow_knight", 1]], HEARTFROST_POS, 6.0,
			Unit.Team.ENEMY, true, true)
	guard_groups[&"G4"] = spawn_group([["ruin_warden", 3]], EMBERGUARD_TABLE[1][2], 3.0, Unit.Team.NEUTRAL, true, true)
	guard_groups[&"G5"] = spawn_group([["shade", 2]], EMBERGUARD_TABLE[2][2] + Vector3(2.0, 0.0, 3.0), 1.5,
			Unit.Team.ENEMY, true)


## Torvald's Sentinels: Rime Colossi in ice shells, NEUTRAL, dormant until E11 (easy: 1).
func _spawn_sentinels(diff: int) -> void:
	var n := 1 if diff == 0 else SENTINEL_SPOTS.size()
	for i in n:
		if UnitType.find("rime_colossus") == null:
			break
		var s := _spawn(make_unit("rime_colossus"), Unit.Team.NEUTRAL, SENTINEL_SPOTS[i])
		s.name = "Sentinel%d" % (i + 1)
		mark_scripted(s)
		set_dormant(s, true)
		_add_shell(s)
		sentinels.append(s)


func _add_shell(u: Unit) -> void:
	if _SIM.enabled:
		return
	var box := BoxMesh.new()
	box.size = Vector3(2.6, 3.6, 2.6)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.70, 0.90, 1.0, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.rim_enabled = true
	var mi := MeshInstance3D.new()
	mi.name = "IceShell"
	mi.mesh = box
	mi.material_override = m
	mi.position.y = 1.8
	u.add_child(mi)


func _shatter_shell(u: Unit) -> void:
	var shell := u.get_node_or_null(^"IceShell") as MeshInstance3D
	if shell == null:
		return
	var at := shell.global_position
	shell.queue_free()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.75, 0.93, 1.0, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(0.62, 0.95, 0.88)   # glass-teal rune glints
	m.emission_energy_multiplier = 0.6
	for i in 12:
		var b := BoxMesh.new()
		b.size = Vector3(0.5, 0.7, 0.2)
		var mi := MeshInstance3D.new()
		mi.mesh = b
		mi.material_override = m
		add_child(mi)
		mi.global_position = at
		var a := i * TAU / 12.0
		var tw := mi.create_tween()
		tw.tween_property(mi, "global_position", at + Vector3(cos(a) * 3.0, -1.6, sin(a) * 3.0), 0.6)
		tw.tween_interval(1.5)
		tw.tween_property(mi, "scale", Vector3.ONE * 0.01, 0.6)
		tw.tween_callback(mi.queue_free)


func _spawn_m2_caches() -> void:
	for i in M2_CACHE_SPOTS.size():
		var cache := LostCache.new()
		cache.name = "LostCache%d" % i
		cache.rng.seed = MAP_SEED + i
		cache.match_time_source = match_time
		add_child(cache)
		cache.global_position = M2_CACHE_SPOTS[i]
		cache.opened.connect(_on_cache_opened)
		caches.append(cache)
	if pell == null:   # the empty cart is a Lost Cache that opens at once
		cart_cache = LostCache.new()
		cart_cache.name = "PellsCart"
		cart_cache.first_delay = 0.0
		cart_cache.rng.seed = MAP_SEED + 7
		cart_cache.match_time_source = match_time
		add_child(cart_cache)
		cart_cache.global_position = PELL_POS + Vector3(0.0, 0.0, 1.4)
		cart_cache.opened.connect(_on_cache_opened)
		caches.append(cart_cache)


## Dig spot i on the ring r 3 (the diagonals: 45, 135, 225, 315 degrees).
static func dig_spot(i: int) -> Vector3:
	var a := deg_to_rad(45.0 + 90.0 * i)
	return HEARTFROST_POS + Vector3(cos(a) * DIG_RING, 0.0, sin(a) * DIG_RING)


func _add_dig_thrall(spot: Vector3, slot: int, from: Vector3 = Vector3.INF) -> Unit:
	var t := _spawn(make_unit("gloom_thrall"), Unit.Team.ENEMY, spot if from == Vector3.INF else from)
	t.name = "DigThrall%d" % dig_thralls.size()
	mark_scripted(t)
	t.set_meta(&"dig_slot", slot)
	if from != Vector3.INF:
		t.command_move(spot)
	dig_thralls.append(t)
	return t


func _make_hall_type() -> BuildingType:
	var base := BuildingType.find("fire_barracks")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	var trains: Array[UnitType] = []
	for id in HALL_UNITS:   # Z X C V
		var ut := UnitType.find(String(id))
		if ut:
			trains.append(ut)
	if tiers_enabled and TierSystem.ENABLED:   # B N, greyed "Requires Stronghold" until then
		for id in TIER2_HALL_UNITS:
			var ut := UnitType.find(String(id))
			if ut:
				trains.append(ut)
	t.trains = trains
	return t


func _on_m2_node_added(node: Node) -> void:
	var b := node as TrainingBuilding
	if b != null and _hall_type != null and b.building_type != null and b.building_type != _hall_type \
			and b.building_type.id == &"fire_barracks":
		b.building_type = _hall_type
	var u := node as Unit
	if u != null:
		_watch_hurler.call_deferred(u)


## Ash Hurler shots crack the floe under the unit they hit (+0.25, credit the Hurler = the Fire team).
func _watch_hurler(u: Unit) -> void:
	if not is_instance_valid(u) or u.unit_type == null or u.unit_type.id != &"ash_hurler" \
			or int(u.team) != Unit.Team.PLAYER or u.attack_landed.is_connected(_on_hurler_hit):
		return
	u.attack_landed.connect(_on_hurler_hit.bind(u))


func _on_hurler_hit(target: Node3D, _amount: float, hurler: Unit) -> void:
	if lake and target is Unit and is_instance_valid(target):
		lake.crack_at(target.global_position, 0.25, hurler)


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_heartfrost", false), objective_text(&"obj_orb"),
				objective_text(&"obj_escape"), BRIEFING_DIG_LINE],
		"rule": objective_text(&"obj_vessa"),
	}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_dig":
			return "Stop Malrik's dig (%d %%)" % int(dig) if with_counter else "Stop Malrik's dig"
		&"obj_heartfrost":
			return "Melt the Heartfrost (%d %%)" % melt_percent() if with_counter else "Melt the Heartfrost"
		&"obj_orb":
			return "Claim the Stillwater Orb"
		&"obj_escape":
			return "Bring the orb home"
		&"obj_vessa":
			return "Vessa must survive"
		&"sec_emberguard":
			return "Thaw the lost Emberguard (%d / 3)" % thawed if with_counter else "Thaw the lost Emberguard"
		&"sec_dig":
			return "Melt the Heartfrost before the dig reaches 50 %"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_dig":
			return {"progress": int(dig), "goal": 100, "counter": "%d %%" % int(dig)}
		&"obj_heartfrost":
			return {"progress": melt_percent(), "goal": 100, "counter": "%d %%" % melt_percent(),
					"position": HEARTFROST_POS}
		&"obj_orb":
			return {"position": HEARTFROST_POS}
		&"obj_escape":
			return {"position": _alive_pos(keep, PLAYER_START)}
		&"sec_emberguard":
			return {"progress": thawed, "goal": 3, "counter": "%d / 3" % thawed}
	return {}


func melt_percent() -> int:
	return int(round(heartfrost.melted_ratio() * 100.0)) if heartfrost else 0


## Says the spec line `id` (L1..L17, L4a...) once per run.
func say_id(id: StringName) -> void:
	if _said.has(id):
		return
	var i := LINE_IDS.find(id)
	if i < 0:
		push_error("Mission02: unknown line %s" % id)
		return
	_said[id] = true
	said_ids.append(id)
	say_line(i + 1)


# ---------------------------------------------------------------- the intro and the timed events

## E1, once the briefing is closed: camera on Vessa, L1-L2 and the hint.
func _intro() -> void:
	fire_once(&"E1")
	camera_rig.focus_on(hero.global_position)
	say_id(&"L1")
	say_id(&"L2")
	hud.show_message(HINT_START, 10.0)


## E2 (2:00): the dig starts.
func _e2_dig_starts() -> void:
	if is_ending() or has_fired(&"E10"):
		return
	fire_once(&"E2")
	dig_active = true
	say_id(&"L3")
	set_objective(&"obj_dig", "active")
	set_objective(&"sec_dig", "active")


func _e3_pell() -> void:
	if pell != null:
		say_id(&"L4a")
		ItemDrops.spawn_pickup(self, PELL_GIFT, PELL_POS + Vector3(-1.0, 0.0, 1.8))
	else:
		say_id(&"L4b")


func _e6() -> void:
	if is_ending():
		return
	fire_once(&"E6")
	if outpost_burned:
		say_id(&"L6b")
		return
	say_id(&"L6a")
	_fire_reinforcements()


# ---------------------------------------------------------------- the Emberguard

func _on_block_thawed(b: MissionBrazier) -> void:
	if game_over:
		return
	thawed += 1
	var rows: Array[String] = ["flame_guard", "flame_guard", "ember_archer"]
	for i in rows.size():
		var u := _spawn(make_unit(rows[i]), Unit.Team.PLAYER, b.global_position + Vector3(-1.5 + i * 1.5, 0.0, 2.0))
		if u:
			u.add_xp(u.veterancy_next_xp())   # veterancy level 2 (levels.md)
	set_objective(&"sec_emberguard", "active" if thawed < 3 else "done")
	if thawed == 1:
		fire_once(&"E4")
		say_id(&"L5")
	if thawed == 3:
		fire_once(&"E5")
		hud.show_message(MSG_OATH, 5.0)
		ItemDrops.give_item(hero, OATH_ITEM, b.global_position + Vector3(0.0, 0.0, 1.8), self)


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)   # MissionBase: the Skirmish tick, the timers, the E-list
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_dig(delta)
	_tick_relief(delta)
	if heartfrost_freed and not orb_taken and hero_alive() \
			and _flat(hero.global_position, HEARTFROST_POS) <= ORB_CLAIM_RADIUS:
		claim_orb()
	_tick -= delta
	if _tick <= 0.0:
		_tick = 1.0
		_tick_w2()
		_return_dig_thralls()
		_tick_malrik()
		_check_stronghold_hint()
		_refresh_counters()
		_tick_core()
		if not waves_fired.has(&"W3") and heartfrost and heartfrost.is_alive() and heartfrost.hp < heartfrost.max_hp * 0.5:
			_fire_w3()
	if _orb_mesh and is_instance_valid(_orb_mesh) and not orb_taken:
		_orb_mesh.position.y = ORB_POS.y + sin(mission_time() * 2.0) * 0.12


## The rush floor (header): the core holds at HEARTFROST_CORE until CORE_THAW_AT; one message when the player first
## reaches it, one when it gives (only if it held someone back).
func _tick_core() -> void:
	if heartfrost == null or not heartfrost.is_alive():
		return
	var holding := mission_time() < CORE_THAW_AT
	if holding:
		heartfrost.hp_floor = heartfrost.max_hp * HEARTFROST_CORE
		if not _core_msg_shown and heartfrost.hp <= heartfrost.hp_floor + 1.0 and heartfrost.since_fire_damage < 2.0:
			_core_msg_shown = true
			hud.show_message(MSG_CORE_HOLDS, 5.0)
	elif heartfrost.hp_floor > 0.0:
		heartfrost.hp_floor = 0.0
		if _core_msg_shown:
			hud.show_message(MSG_CORE_THAWS, 4.0)


## Working dig Thralls: alive, within 5 m of the Heartfrost (max 4).
func working_thralls() -> int:
	var n := 0
	for t in dig_thralls:
		if is_instance_valid(t) and (t as Unit).is_alive() \
				and _flat((t as Unit).global_position, HEARTFROST_POS) <= DIG_WORK_RADIUS:
			n += 1
	return mini(n, DIG_THRALLS)


func living_dig_thralls() -> int:
	var n := 0
	for t in dig_thralls:
		if is_instance_valid(t) and (t as Unit).is_alive():
			n += 1
	return n


## Dig Thralls pushed off the ring (a wave walking through the dig, a fight) walk back to their spot when idle, so
## the dig keeps its 22:50 pace with no player input (measured 2026-10-04: W3 crossing the ring cost ~1:50).
func _return_dig_thralls() -> void:
	if not dig_active or heartfrost_freed:
		return
	for t: Variant in dig_thralls:
		if not is_instance_valid(t):
			continue
		var u := t as Unit
		if u == null or not u.is_alive() or u.has_move_order() or u.attack_target != null:
			continue
		var spot := dig_spot(int(u.get_meta(&"dig_slot", 0)))
		if _flat(u.global_position, spot) > 1.5:
			u.command_move(spot)


## Percent per second with `working` Thralls (difficulty rate).
func dig_rate(working: int) -> float:
	return DIG_RATE[clampi(mission_difficulty, 0, 2)] * float(mini(working, DIG_THRALLS))


func _tick_dig(delta: float) -> void:
	if not dig_active or heartfrost_freed:
		return
	dig = minf(100.0, dig + dig_rate(working_thralls()) * delta)
	for pct in DIG_MESSAGES:
		if dig >= pct and not _dig_msgs.has(pct):
			_dig_msgs[pct] = true
			hud.show_message(MSG_DIG % pct, 4.0)
	if dig >= 50.0 and objective_state("sec_dig") == "active":
		set_objective(&"sec_dig", "failed")
	if dig >= 100.0:
		_e14_dig_done()


## Relief: while fewer than 4 dig Thralls live, the Dusk Keep sends 1 every 40 s (until E10 or the keep falls).
func _tick_relief(delta: float) -> void:
	if not dig_active or heartfrost_freed or keep_of(Unit.Team.ENEMY) == null:
		return
	if living_dig_thralls() >= DIG_THRALLS:
		_relief_left = RELIEF_INTERVAL
		return
	_relief_left -= delta
	if _relief_left > 0.0:
		return
	_relief_left = RELIEF_INTERVAL
	var used := {}
	for t in dig_thralls:
		if is_instance_valid(t) and (t as Unit).is_alive():
			used[int((t as Node).get_meta(&"dig_slot", -1))] = true
	for i in DIG_THRALLS:
		if not used.has(i):
			relief_sent += 1
			_add_dig_thrall(dig_spot(i), i, shadow_keep.spawn_point())
			return


func _refresh_counters() -> void:
	if objective_state("obj_dig") == "active" and int(dig) != _last_dig_pct:
		_last_dig_pct = int(dig)
		_counter_text_changed()
	if objective_state("obj_heartfrost") == "active" and melt_percent() != _last_melt_pct:
		_last_melt_pct = melt_percent()
		_counter_text_changed()


## A percent counter moved: the panel re-reads the texts. No Events.objective_changed (the state did not change; it
## used to re-send "active" every percent).
func _counter_text_changed() -> void:
	objectives_changed.emit()
	if hud and mission_hud == null:
		hud.set_objective(_objective_text())


func _check_stronghold_hint() -> void:
	if stronghold_hint_shown or tier_system == null or hud == null:
		return
	var st := TierSystem.status(Unit.Team.PLAYER)
	if st.is_empty() or int(st["tier"]) != 1 or bool(st["upgrading"]) or int(st["next"]) != 2 or String(st["reason"]) != "":
		return
	stronghold_hint_shown = true
	var opens := TierSystem.unlock_text(Unit.Team.PLAYER, 2)
	hud.show_message(HINT_STRONGHOLD % [KeyLabels.of(KEY_X), int(st["crystals"]), opens if opens != "" else "new units"],
			HINT_STRONGHOLD_SECONDS)


## Malrik holds (4, -4) until E11: he walks back once idle, and drops a chase past his 12 m leash.
func _tick_malrik() -> void:
	if _malrik_joined or shadow_hero == null or not is_instance_valid(shadow_hero) or not shadow_hero.is_alive():
		return
	var d := _flat(shadow_hero.global_position, MALRIK_POS)
	if d > MALRIK_LEASH:
		shadow_hero.command_move(MALRIK_POS)
	elif d > 2.0 and shadow_hero.attack_target == null and not shadow_hero.is_attack_moving():
		shadow_hero.command_attack_move(MALRIK_POS)


# ---------------------------------------------------------------- the Heartfrost (right-click, Fireball)

func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_RIGHT or selection == null \
			or heartfrost == null or not heartfrost.is_alive() or selection.selected_building != null \
			or selection.get_pending_order() != &"" or selection.pending_spell() != &"":
		return
	if not _ray_hits_heartfrost(mb.position):
		return
	var units := selection.orderable_units()
	if units.is_empty():
		return
	order_on_heartfrost(units)
	get_viewport().set_input_as_handled()


func _ray_hits_heartfrost(screen: Vector2) -> bool:
	var cam := camera_rig.camera if camera_rig else null
	if cam == null:
		return false
	var from := cam.project_ray_origin(screen)
	var dir := cam.project_ray_normal(screen)
	if absf(dir.y) < 0.001:
		return false
	for k in 11:   # the monolith: a vertical cylinder r 1.5, 0-5 m tall
		var y := 5.0 * k / 10.0
		var t := (y - from.y) / dir.y
		if t <= 0.0:
			continue
		var p := from + dir * t
		if _flat(p, HEARTFROST_POS) <= Heartfrost.RADIUS + 0.4:
			return true
	return false


## A right-click on the Heartfrost: Vessa and the Ash Hurlers attack it, the others move next to it (the first
## time, the message says why). Returns true when something was ordered.
func order_on_heartfrost(units: Array) -> bool:
	var others := false
	var any := false
	for v: Variant in units:
		var u := v as Unit
		if u == null or not u.is_alive():
			continue
		any = true
		if heartfrost.accepts_damage_from(u):
			u.command_attack(heartfrost)
		else:
			others = true
			var dir := (u.global_position - HEARTFROST_POS)
			dir.y = 0.0
			u.command_move(HEARTFROST_POS + (dir.normalized() if dir.length() > 0.1 else Vector3.BACK) * 2.6)
	if others and not _heartfrost_msg_shown:
		_heartfrost_msg_shown = true
		hud.show_message(MSG_ONLY_FIRE, 4.0)
	return any


## Vessa's spells on the ice: a Fireball cracks the floe it lands on (+1) and burns the Heartfrost when its blast
## reaches it; Ember Step's landing cracks its floe (+1).
func _on_hero_spell_effect(id: StringName, pos: Vector3) -> void:
	match id:
		&"fireball":
			get_tree().create_timer(FIREBALL_TRAVEL, false, true).timeout.connect(_fireball_lands.bind(pos))
		&"ember_step_arrive":
			if lake:
				lake.crack_at(pos, 1.0, hero)


func _fireball_lands(pos: Vector3) -> void:
	if game_over or not is_instance_valid(hero):
		return
	if lake:
		lake.crack_at(pos, 1.0, hero)
	if heartfrost == null or not heartfrost.is_alive():
		return
	var caster := hero.get_node_or_null(^"SpellCaster") as SpellCaster
	var t := SpellType.find(&"fireball")
	if caster == null or t == null:
		return
	var rank := maxi(1, caster.rank_of(&"fireball"))
	if _flat(pos, HEARTFROST_POS) <= t.radius_at(rank) + Heartfrost.RADIUS:
		heartfrost.take_damage(caster.spell_damage(t, rank), hero)


func _on_floe_broken(_index: int, _credit: Node3D) -> void:
	if fire_once(&"E7"):
		say_id(&"L7")


# ---------------------------------------------------------------- E10: the Heartfrost melts

func _on_heartfrost_melted(_h: Heartfrost) -> void:
	if is_ending() or not fire_once(&"E10"):   # no Heartfrost film over a pending defeat
		return
	play_cutscene(&"m2_heartfrost", _e10_end_state)


## E10's end state (played, skipped or missing = the same): L9 once, the burst flash, the orb floating at (0, 1, 0),
## the objectives, the dig stops and the living dig Thralls walk to the Dusk Keep.
func _e10_end_state() -> void:
	if heartfrost_freed:
		return
	heartfrost_freed = true
	dig_active = false
	say_id(&"L9")
	heartfrost.burst()
	_orb_mesh = heartfrost.orb_node()
	if _orb_mesh:
		_orb_mesh.position = ORB_POS
	_ice_flash()
	build_grid.request_rebake()
	set_objective(&"obj_heartfrost", "done")
	set_objective(&"obj_dig", "done")
	if objective_state("sec_dig") == "active" and dig < 50.0:
		set_objective(&"sec_dig", "done")
	set_objective(&"obj_orb", "active")
	var home := _alive_pos(shadow_keep, FALLBACK_SPAWN)
	for t in dig_thralls:
		if is_instance_valid(t) and (t as Unit).is_alive():
			(t as Unit).command_move(home + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))


func _ice_flash() -> void:
	flash_ring(HEARTFROST_POS, FLASH_RADIUS)
	# The seal flash, tinted ice blue (flash_ring is white): a second, coloured disc.
	var disc := CylinderMesh.new()
	disc.top_radius = FLASH_RADIUS
	disc.bottom_radius = FLASH_RADIUS
	disc.height = 0.05
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(FLASH_COLOR, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.mesh = disc
	mi.material_override = mat
	add_child(mi)
	mi.global_position = HEARTFROST_POS + Vector3(0.0, 0.15, 0.0)
	var tw := mi.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 1.2)
	tw.tween_callback(mi.queue_free)


# ---------------------------------------------------------------- E11: the orb

## E11 (Vessa within 2.2 m of the orb, or a script): the orb to the free artifact slot (slot 2 when both are full),
## L10 / L15 / L16, B2, Aldra, the shore walls, the Sentinels wake, the Pursuit.
func claim_orb() -> void:
	if orb_taken or not heartfrost_freed or is_ending():
		return
	orb_taken = true
	fire_once(&"E11")
	say_id(&"L10")
	say_id(&"L15")
	say_id(&"L16")
	_give_orb()
	if _orb_mesh and is_instance_valid(_orb_mesh):
		_orb_mesh.visible = false
	set_objective(&"obj_orb", "done")
	set_objective(&"obj_escape", "active")
	orb_claimed.emit(hero)
	blizzard.set_blowing(true)   # B2: until the end
	aldra.appear()
	aldra.raise_weapon()
	raise_shore_walls()
	var rune_targets: Array = []
	for g in SEALED_GAPS:
		rune_targets.append(gap_center(g))
	for s in sentinels:
		if is_instance_valid(s):
			rune_targets.append((s as Node3D).global_position)
	aldra.rune_lines(rune_targets, 1.5)
	for s in sentinels:
		if is_instance_valid(s) and (s as Unit).is_alive():
			set_dormant(s as Unit, false)
			_shatter_shell(s as Unit)
	after(ALDRA_STAY, func() -> void:
		if aldra.shown:
			aldra.fade(1.0))
	_fire_pursuit()
	hud.show_message(HINT_E11, 8.0)


func _give_orb() -> void:
	var inv := ItemDrops.inventory_of(hero) as Inventory
	var slot := 1
	if inv:
		for i in inv.artifacts.size():
			if inv.artifacts[i] == null:
				slot = i
				break
	var ids := ["", ""]
	ids[slot] = "stillwater_orb"
	force_artifacts(hero, ids)


## The NEUTRAL shore walls at SW, NW and SE: 2 rows (r 24 and r 27) of Ice Walls across each gap, snapped to the
## BuildGrid as a 4-connected chain of cells (no diagonal leak); a cell already blocked is skipped. NE stays open.
func raise_shore_walls() -> void:
	var type := BuildingType.find("ice_wall")
	if type == null:
		return
	for g in SEALED_GAPS:
		var rows: Array = []
		for r in WALL_ROWS:
			var row: Array = []
			for c: Vector3 in wall_cells(g, r):
				if _cell_blocked(c):
					continue
				var w := build_grid.spawn_complete(type, c, Unit.Team.NEUTRAL)
				w.name = "ShoreWall_%s_%d" % [g, shore_walls.size()]
				mark_scripted(w)
				shore_walls.append(w)
				row.append(w)
			rows.append(row)
		wall_rows[g] = rows
	build_grid.request_rebake()


## The grid cells of one wall row across gap `g` at radius `r` (centres, 4-connected).
func wall_cells(g: StringName, r: float) -> Array[Vector3]:
	var a := deg_to_rad(float(GAPS[g]))
	var center := Vector3(cos(a) * r, 0.0, sin(a) * r)
	var tangent := Vector3(-sin(a), 0.0, cos(a))
	var out: Array[Vector3] = []
	var s := -WALL_HALF_SPAN
	while s <= WALL_HALF_SPAN + 0.01:
		var c := build_grid.snap(center + tangent * s, Vector2i(1, 1))
		if out.is_empty() or not out[-1].is_equal_approx(c):
			if not out.is_empty():
				var prev: Vector3 = out[-1]
				if absf(prev.x - c.x) > 0.5 and absf(prev.z - c.z) > 0.5:
					out.append(Vector3(c.x, 0.0, prev.z))   # close the diagonal step
			if not out.has(c):
				out.append(c)
		s += 0.25
	return out


func _cell_blocked(c: Vector3) -> bool:
	for node in get_tree().get_nodes_in_group("buildings"):
		var b := node as Building
		if b and b.is_alive() and b.footprint_rect().has_point(Vector2(c.x, c.z)):
			return true
	return false


## Gaps where a wall is down in both rows (E11b).
func opened_gaps() -> Array[StringName]:
	var out: Array[StringName] = []
	for g: StringName in wall_rows:
		var rows: Array = wall_rows[g]
		var both := true
		for row: Array in rows:
			var broken := row.any(func(w: Variant) -> bool: return not is_instance_valid(w) or not (w as Building).is_alive())
			both = both and broken
		if both and rows.size() == 2:
			out.append(g)
	return out


func _e11b() -> void:
	say_id(&"L17")
	if aldra.shown:
		aldra.fade(1.0)


# ---------------------------------------------------------------- waves

func _wave_spawn_point() -> Vector3:
	if gloom_hall and is_instance_valid(gloom_hall) and gloom_hall.is_alive() and gloom_hall is TrainingBuilding:
		return (gloom_hall as TrainingBuilding).spawn_point()
	if shadow_keep and is_instance_valid(shadow_keep) and shadow_keep.is_alive():
		return shadow_keep.spawn_point()
	return FALLBACK_SPAWN


func _fire_w1() -> void:
	if is_ending() or waves_fired.has(&"W1"):
		return
	waves_fired.append(&"W1")
	var target := _alive_pos(ember_hall, _alive_pos(keep, PLAYER_START))
	for u in spawn_wave_at([["shade", 3], ["nightbolt", 2]], _wave_spawn_point()):
		order_wave(u, &"point", target)
	hud.show_message(HINT_SPOTLIGHT, 8.0)   # the spotlight moment (unit-spotlights.md 2.1)


func _fire_reinforcements() -> void:
	if waves_fired.has(&"reinforcements"):
		return
	waves_fired.append(&"reinforcements")
	var target := _nearest_fire_worker_pos(SHADOW_ROAD)
	reinforcements = spawn_wave_at([["shade", 3], ["nightbolt", 2], ["grave_hound", 1]], SHADOW_ROAD)
	for u in reinforcements:
		order_wave(u, &"point", target)


func living_reinforcements() -> int:
	var n := 0
	for u in reinforcements:
		if is_instance_valid(u) and (u as Unit).is_alive():
			n += 1
	return n


## W2 (9:00): waits up to 45 s while 3+ reinforcement units still live.
func _tick_w2() -> void:
	if not _w2_due or waves_fired.has(&"W2"):
		return
	if living_reinforcements() >= W2_WAIT_ALIVE and mission_time() < W2_TIME + W2_MAX_WAIT:
		return
	waves_fired.append(&"W2")
	var target := _alive_pos(keep, PLAYER_START)
	for u in spawn_wave_at([["shade", 4], ["nightbolt", 2], ["grave_hound", 2]], _wave_spawn_point()):
		order_wave(u, &"point", target)


func _fire_w3() -> void:
	if is_ending() or waves_fired.has(&"W3") or orb_taken:
		return
	waves_fired.append(&"W3")
	for u in spawn_wave_at([["shade", 3], ["nightbolt", 2], ["shadow_knight", 1]], _wave_spawn_point()):
		order_wave(u, &"heartfrost_then_vessa", HEARTFROST_POS)


func _fire_pursuit() -> void:
	if waves_fired.has(&"pursuit"):
		return
	waves_fired.append(&"pursuit")
	for u in spawn_wave_at([["shade", 4], ["nightbolt", 3], ["shadow_knight", 1]], _wave_spawn_point()):
		order_wave(u, &"hero", hero_pos())
	_malrik_joins()
	after(PURSUIT_SECOND, func() -> void:
		if is_ending():
			return
		waves_fired.append(&"pursuit_2")
		for u in spawn_wave_at([["shade", 2], ["grave_hound", 2]], _wave_spawn_point()):
			order_wave(u, &"hero", hero_pos()))


func _malrik_joins() -> void:
	if shadow_hero == null or not is_instance_valid(shadow_hero):
		return
	if not _malrik_joined:
		_malrik_joined = true
		var diff := clampi(mission_difficulty, 0, 2)
		raise_wizard(shadow_hero, MALRIK_E11_LEVEL[diff], MALRIK_E11_SPELLS[diff])
	if shadow_hero.is_alive():
		order_wave(shadow_hero, &"hero", hero_pos())


## W3 walks to the Heartfrost, then turns on Vessa (once there or idle).
func _refresh_wave_unit(u: Unit, mode: StringName, vessa: Vector3) -> bool:
	if mode != &"heartfrost_then_vessa":
		return false
	if _flat(u.global_position, HEARTFROST_POS) <= 8.0 or not u.is_attack_moving() and u.attack_target == null:
		u.set_meta(META_MODE, &"hero")
		u.command_attack_move(vessa)
	return true


func _nearest_fire_worker_pos(from: Vector3) -> Vector3:
	var best := _alive_pos(keep, PLAYER_START)
	var best_d := INF
	for u in workers_of(Unit.Team.PLAYER):
		var d := _flat(u.global_position, from)
		if d < best_d:
			best_d = d
			best = u.global_position
	return best


# ---------------------------------------------------------------- Malrik

func _on_malrik_died(_unit: Unit) -> void:
	if game_over or is_ending():
		return
	hud.show_message(MSG_MALRIK_FELL, 4.0)
	_respawn_left[Unit.Team.ENEMY] = MALRIK_RESPAWN


func _on_m2_wizard_respawned(wiz: Wizard) -> void:
	if wiz != shadow_hero or is_ending():
		return
	if _malrik_joined:
		order_wave(wiz, &"hero", hero_pos())
	else:
		wiz.command_move(MALRIK_POS)


# ---------------------------------------------------------------- the end

## E12: Vessa home with the orb.
func _e12_escape() -> void:
	if is_ending():
		return
	say_id(&"L11")
	say_id(&"L12")
	set_objective(&"obj_escape", "done")
	set_objective(&"obj_vessa", "done")
	var home := _alive_pos(shadow_keep, FALLBACK_SPAWN)
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY:
			u.set_meta(META_MODE, &"home")
			u.command_move(home + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0)))
	clear_waves()
	for s in sentinels:
		if is_instance_valid(s) and (s as Unit).is_alive():
			set_dormant(s as Unit, true)
	win(VICTORY_DELAY)


## E13: Vessa falls.
func _on_player_hero_fell() -> void:
	fire_once(&"E13")
	say_id(&"L13")
	set_objective(&"obj_vessa", "failed")
	lose(DEFEAT_DELAY)


## E14: the dig reaches 100 %.
func _e14_dig_done() -> void:
	if is_ending() or not fire_once(&"E14"):
		return
	say_id(&"L14")
	set_objective(&"obj_dig", "failed")
	lose(DEFEAT_DELAY)
